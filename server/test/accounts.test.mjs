// Account and data deletion (§20.5, §20.11), against the real simulation
// build.

import assert from "node:assert/strict";
import { test } from "node:test";

import { deleteAccount } from "../src/accounts.mjs";
import { Refused, clockTicks } from "../src/service.mjs";
import { Social } from "../src/social.mjs";
import { Workshop } from "../src/workshop.mjs";
import { openPlan, play, twoPlayers } from "./setup.mjs";

const refusal = (fn, reason) => assert.throws(fn, (e) => e instanceof Refused && e.reason === reason);

const call = (t, method, path, { token, json } = {}) => t.handle(new Request(`https://edge.example${path}`, {
  method,
  headers: { ...(token ? { authorization: `Bearer ${token}` } : {}),
             ...(json ? { "content-type": "application/json" } : {}) },
  body: json ? JSON.stringify(json) : undefined,
}));

test("deleting an account takes the person out of everything, and keeps the records nobody edits (20.5)", () => {
  const t = twoPlayers(true);
  const gone = t.defender.account;
  const other = t.raider.account;
  // A raid, so there is a ledger and Renown to keep.
  const lease = t.service.lease(other, t.bundle);
  t.service.submit(other, lease.token, play(t, lease, { plan: openPlan() }));
  // A Workshop island, a constellation it founded and a crew.
  const w = new Workshop(t.service);
  const cleared = t.build.record(t.island, { seed: 7n, ticks: clockTicks(0), crew: 3, commands: openPlan() });
  const { id: item } = w.publish(gone, t.island, cleared, { adjective: 0, noun: 0 });
  t.service.db.prepare("UPDATE accounts SET keeper_level = 6").run();
  const social = new Social(t.service);
  const c = social.found(gone, { adjective: 1, noun: 1 });
  social.join(other, c.id);
  social.startCrew(gone);
  t.service.friends.accept(other, t.service.friends.invite(gone).invite);
  const ledger = t.service.db.prepare("SELECT COUNT(*) AS n FROM ledger").get().n;

  const out = deleteAccount(t.service, gone);
  assert.deepEqual([out.deleted, out.islands, out.withdrawn, out.left.length], [true, 1, 1, 2]);
  refusal(() => t.service.account(t.defender.token), "account_deleted");
  assert.notEqual(t.service.session("gc:defender").account, gone, "signing in again starts afresh");
  assert.deepEqual(t.service.targetLists(), {}, "its island left the target lists");
  refusal(() => t.service.lease(other, t.bundle), "superseded");
  assert.equal(w.view(w.row(item)).withdrawn, true, "withdrawn, not deleted: a remix still names it");
  assert.equal(social.constellation(c.id).members[0].account, other, "the constellation was handed on");
  assert.deepEqual(t.service.friends.list(other), [], "and friendships end");
  const who = t.service.telemetry.pseudonym(gone);
  assert.equal(t.service.db.prepare("SELECT COUNT(*) AS n FROM events WHERE who = ?").get(who).n, 0);
  assert.equal(t.service.db.prepare("SELECT COUNT(*) AS n FROM ledger").get().n, ledger,
               "the ledger is append-only, and names only an id that leads nowhere");
  assert.deepEqual(deleteAccount(t.service, gone).islands, 0, "asking again finishes, and changes nothing");
});

test("a player who turns out to be under 13 is deleted at once (20.11)", async () => {
  const t = twoPlayers(true);
  const res = await call(t, "PUT", "/v1/age", { token: t.defender.token, json: { band: "under-13" } });
  assert.deepEqual(await res.json(), { deleted: true, reason: "under-13" });
  assert.equal((await call(t, "GET", "/v1/balance", { token: t.defender.token })).status, 401);
  assert.deepEqual(t.service.targetLists(), {});
});

test("account deletion from inside the game, over HTTP (20.5)", async () => {
  const t = twoPlayers(true);
  const res = await call(t, "DELETE", "/v1/account", { token: t.raider.token });
  assert.equal(res.status, 200);
  assert.equal((await res.json()).reason, "requested");
  const after = await call(t, "GET", "/v1/league", { token: t.raider.token });
  assert.deepEqual([after.status, (await after.json()).error], [401, "account_deleted"]);
});
