// FX1-6: the proofs of docs/security/audit-2026-11/server-a.md, one test per
// finding, each failing on the code the audit read.

import assert from "node:assert/strict";
import { test } from "node:test";

import { deleteAccount } from "../src/accounts.mjs";
import { clockTicks } from "../src/service.mjs";
import { Build, Builds } from "../src/sim.mjs";
import { SPIKE_MIN, Workshop } from "../src/workshop.mjs";
import { WASM, counting, established, openPlan, server, twoPlayers } from "./setup.mjs";

const DAY = 24 * 60 * 60 * 1000;

/** B's island X, then B's next: X is B's echo. A, under 13, lists the same
 *  bytes in the Workshop and is deleted. */
function erasedEcho() {
  const t = server();
  const a = t.service.session("gc:a").account;
  const b = t.service.session("gc:b").account;
  established(t, a);
  established(t, b);
  const x = t.build.exampleIsland(true);
  const xBundle = t.service.publish(b, x).bundle;
  const cleared = t.build.record(x, { seed: 7n, ticks: clockTicks(0), crew: 3, commands: openPlan() });
  new Workshop(t.service).publish(a, x, cleared, { adjective: 1, noun: 9 });
  t.service.publish(b, t.build.exampleIsland(false));
  deleteAccount(t.service, a, "under-13");
  return { t, a, b, xBundle };
}

test("FX1-A-01: an echo whose bytes are gone is no target, and the others are still drawn (12.22, 20.11)", () => {
  const { t, xBundle } = erasedEcho();
  const now = t.service.now();
  let list;
  assert.doesNotThrow(() => { list = t.service.matchmaking.fresh(now); }, "the candidates are still made");
  for (const c of list) assert.notEqual(t.service.bundle(c.bundle), null, `${c.bundle}: a target is bytes to play`);
  assert.ok(list.length > 0, "B's current island is still a target");
  assert.doesNotThrow(() => t.service.matchmaking.listed(now));
});

test("FX1-A-02: an under-13 deletion erases bytes another player's echo is (20.11)", () => {
  // FX1-A-02, not fixed here: accounts.mjs's erase() keeps bytes another
  // player's island, Workshop island, link or lease still needs, but not
  // their snapshot, so B's echo X loses its bytes. This asserts what happens
  // today; the fix (keep bytes whose snapshot is another player's) turns it.
  const { t, b, xBundle } = erasedEcho();
  const snap = t.service.db.prepare("SELECT owner FROM snapshots WHERE bundle = ?").get(xBundle);
  assert.equal(snap.owner, b, "X's snapshot is B's");
  assert.equal(t.service.bundle(xBundle), null, "FX1-A-02: and its bytes are gone");
});

/** A server with a Workshop and the open example Heart its creator cleared. */
function workshop() {
  const t = server();
  const w = new Workshop(t.service);
  const island = t.build.exampleIsland(true);
  const cleared = t.build.record(island, { seed: 7n, ticks: clockTicks(0), crew: 3, commands: openPlan() });
  return { ...t, w, island, cleared };
}
function clear(t, player, id) {
  const p = t.w.play(player, id);
  const replay = t.build.record(t.service.bundle(p.bundle),
    { seed: BigInt(p.seed), ticks: p.ticks, crew: 3, commands: openPlan() });
  return t.w.submitPlay(player, p.token, replay);
}
const moderator = (t, account) =>
  t.service.db.prepare("UPDATE accounts SET moderator = 1 WHERE id = ?").run(account);

test("FX1-A-03: resolving an already-resolved report again leaves the island's newer reports open (18.7, 20.4)", () => {
  const t = workshop();
  const me = t.service.session("gc:creator").account;
  const { id } = t.w.publish(me, t.island, t.cleared, { adjective: 1, noun: 9 });
  const person = t.service.session("gc:moderator").account;
  moderator(t, person);
  const { report: old } = t.w.report(t.service.session("gc:reporter").account, id, "unfair");
  t.w.resolve(person, old, "dismiss");
  assert.deepEqual(t.w.queue(person), []);
  // Later, a completion spike: the server's report waits for a person.
  t.clock.now += 2 * DAY;
  for (let i = 0; i < SPIKE_MIN; i++) clear(t, t.service.session(`gc:p${i}`).account, id);
  assert.deepEqual(t.w.queue(person).map((r) => r.reason), ["completion_spike"]);
  // A stale moderation tab re-sends the old dismissal.
  let refused = null;
  try { t.w.resolve(person, old, "dismiss"); } catch (e) { refused = e.code ?? e.message; }
  assert.deepEqual(t.w.queue(person).map((r) => r.reason), ["completion_spike"],
    `the spike no person has reviewed is still queued (resolve ${refused ? "refused " + refused : "accepted"})`);
  assert.equal(t.service.db.prepare("SELECT review FROM workshop_items WHERE id = ?").get(id).review, 1,
    "the island is still flagged for review");
});

test("FX1-A-04: lone fans re-rating on a later day do not use up that day's three lone-fan slots (SEC-26)", () => {
  const t = workshop();
  const me = t.service.session("gc:creator").account;
  const { id } = t.w.publish(me, t.island, t.cleared, { adjective: 1, noun: 9 });
  const score = { fun: 5, cleverness: 5, fairness: 5 };
  const fans = ["a", "b", "d"].map((n) => t.service.session(`gc:fan-${n}`).account);
  for (const f of fans) { counting(t, f); clear(t, f, id); t.w.rate(f, id, score); }
  const counted = (p) => t.service.db.prepare(
    "SELECT counted FROM workshop_ratings WHERE item = ? AND player = ?").get(id, p).counted;
  assert.deepEqual(fans.map(counted), [1, 1, 1], "day 1: three lone fans count");
  t.clock.now += DAY;
  for (const f of fans) t.w.rate(f, id, { fun: 4, cleverness: 4, fairness: 4 });
  const e = t.service.session("gc:fan-e").account;
  counting(t, e);
  clear(t, e, id);
  t.w.rate(e, id, score);
  assert.equal(counted(e), 1, "day 2: the first new lone fan of the day counts; re-rates add no counted fan");
});

test("FX1-A-05: after a rules upgrade a live island's hold is queued again and shown as measuring (13.3)", () => {
  const t = twoPlayers(false);
  const h = t.service.holds;
  t.service.db.prepare("UPDATE island_holds SET raids = 6").run();
  h.work(6);
  assert.equal(h.status(t.bundle).status, "measured");
  // The server restarts on a new simulation build: new rules.
  const newer = Build.load(WASM);
  newer.rulesVersion = "f".repeat(64);
  t.service.builds = new Builds([t.service.builds.current, newer]);
  const view = t.service.curation.view(t.defender.account, "heart").hold;
  assert.equal(view?.status, "measuring", `curation shows the hold as measuring, not ${JSON.stringify(view)}`);
  assert.ok(h.work(2) > 0, "the queue measures the live island under the new rules");
});
