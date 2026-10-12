// An under-13 player's bundles, purged from the edge's cache (§20.11, D70).

import assert from "node:assert/strict";
import { test } from "node:test";

import { deleteAccount } from "../src/accounts.mjs";
import {
  CloudflarePurge, PURGE_BATCH, PURGE_RETRY_MS, bundlePath, purgeEdge, queuePurge,
} from "../src/edge.mjs";
import { twoPlayers } from "./setup.mjs";

/** An edge that answers from `answers` in turn, then confirms, and keeps
 *  every batch it was asked to purge. */
function fakeEdge(...answers) {
  const asked = [];
  return { asked, purge: async (paths) => { asked.push(paths); return answers.shift() ?? { ok: true }; } };
}

const queued = (t) => t.service.db.prepare("SELECT path, attempts FROM edge_purges ORDER BY path").all()
  .map((r) => ({ ...r }));

test("an under-13 deletion asks the edge to purge every bundle it erased, until the edge confirms (20.11, D70)", async () => {
  const t = twoPlayers(true);
  deleteAccount(t.service, t.defender.account, "under-13");
  assert.deepEqual(queued(t), [{ path: bundlePath(t.bundle), attempts: 0 }],
                   "queued in the deletion's transaction, though no edge is configured yet");
  assert.deepEqual(await purgeEdge(t.service), { purged: 0, waiting: 1, reasons: {} }, "with no edge, it waits");
  t.service.edge = fakeEdge({ ok: false, reason: "503" });
  assert.deepEqual(await purgeEdge(t.service), { purged: 0, waiting: 1, reasons: { 503: 1 } });
  assert.deepEqual(queued(t), [{ path: bundlePath(t.bundle), attempts: 1 }]);
  await purgeEdge(t.service);
  assert.equal(t.service.edge.asked.length, 1, "not asked again before it is due");
  t.clock.now += PURGE_RETRY_MS;
  assert.deepEqual(await purgeEdge(t.service), { purged: 1, waiting: 0, reasons: {} });
  assert.deepEqual(t.service.edge.asked, [[bundlePath(t.bundle)], [bundlePath(t.bundle)]]);
  assert.deepEqual(queued(t), [], "nothing kept once the edge has it");
});

test("with an edge that answers, the purge is asked as the deletion is made, and a deletion asked for keeps the edge's copy (20.5, 20.11)", async () => {
  const young = twoPlayers(true);
  young.service.edge = fakeEdge();
  deleteAccount(young.service, young.defender.account, "under-13");
  await new Promise(setImmediate);
  assert.deepEqual(young.service.edge.asked, [[bundlePath(young.bundle)]]);
  assert.deepEqual(queued(young), []);
  // A player who asks to be deleted keeps no person in the records, and
  // their islands' bytes stay, so the edge keeps them too (F43).
  const adult = twoPlayers(true);
  adult.service.edge = fakeEdge();
  deleteAccount(adult.service, adult.defender.account, "requested");
  await new Promise(setImmediate);
  assert.deepEqual(adult.service.edge.asked, []);
  assert.deepEqual(queued(adult), []);
});

test("purges go to the edge a batch at a time, each refused batch waiting longer, and none given up (D70)", async () => {
  const t = twoPlayers(true);
  const n = PURGE_BATCH + 1;
  for (let i = 0; i < n; i++) queuePurge(t.service.db, i.toString(16).padStart(64, "0"), t.clock.now);
  t.service.edge = fakeEdge({ ok: true }, { ok: false, reason: "429" });
  const first = await purgeEdge(t.service);
  assert.deepEqual(t.service.edge.asked.map((b) => b.length), [PURGE_BATCH, 1]);
  assert.deepEqual(first, { purged: PURGE_BATCH, waiting: 1, reasons: { 429: 1 } });
  // Refused again and again: each wait doubles up to six hours, and the
  // purge is still there to ask.
  for (let i = 0; i < 12; i++) {
    t.service.edge = fakeEdge({ ok: false, reason: "500" });
    t.clock.now += 6 * 60 * 60 * 1000;
    await purgeEdge(t.service);
  }
  assert.equal(queued(t)[0].attempts, 13);
  const due = t.service.db.prepare("SELECT due_at FROM edge_purges").get().due_at;
  assert.equal(due - t.clock.now, 6 * 60 * 60 * 1000, "the wait stops growing at six hours");
});

test("Cloudflare's purge by URL is asked with the zone's token for each URL, and its refusals are named (D70)", async () => {
  const sent = [];
  const reply = (status, body) => async (url, init) => {
    sent.push({ url, init });
    return new Response(JSON.stringify(body), { status });
  };
  const zone = "0123456789abcdef0123456789abcdef";
  const edge = (fetch) => new CloudflarePurge({ zone, token: "purge-token", origin: "https://play.example", fetch });
  assert.deepEqual(await edge(reply(200, { success: true })).purge(["/v1/bundles/ab"]), { ok: true });
  assert.equal(sent[0].url, `https://api.cloudflare.com/client/v4/zones/${zone}/purge_cache`);
  assert.equal(sent[0].init.method, "POST");
  assert.equal(sent[0].init.headers.authorization, "Bearer purge-token");
  assert.deepEqual(JSON.parse(sent[0].init.body), { files: ["https://play.example/v1/bundles/ab"] });
  assert.deepEqual(await edge(reply(403, { success: false, errors: [{ code: 10000 }] })).purge(["/x"]),
                   { ok: false, reason: "403 10000" });
  assert.deepEqual(await edge(reply(200, { success: false })).purge(["/x"]), { ok: false, reason: "200" },
                   "an answer that is not a success is not taken as one");
  assert.deepEqual(await edge(async () => { throw new TypeError("fetch failed"); }).purge(["/x"]),
                   { ok: false, reason: "unreachable" });
  assert.throws(() => new CloudflarePurge({ zone: "nope", token: "t", origin: "https://play.example" }));
  assert.throws(() => new CloudflarePurge({ zone, token: "", origin: "https://play.example" }));
  assert.throws(() => new CloudflarePurge({ zone, token: "t", origin: "https://play.example/v1" }));
});
