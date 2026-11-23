// FX1-6: the proofs of docs/security/audit-2026-11/server-a.md, one test per
// finding, each failing on the code the audit read.

import assert from "node:assert/strict";
import { readFileSync } from "node:fs";
import { test } from "node:test";

import { deleteAccount } from "../src/accounts.mjs";
import { ratingFor } from "../src/glicko.mjs";
import { peerKey } from "../src/limits.mjs";
import { offer } from "../src/matchmaking.mjs";
import { clockTicks } from "../src/service.mjs";
import { Build, Builds } from "../src/sim.mjs";
import { SPIKE_MIN, Workshop } from "../src/workshop.mjs";
import { WASM, counting, established, openPlan, play, server, twoPlayers } from "./setup.mjs";

const DAY = 24 * 60 * 60 * 1000;
const t0facts = () => JSON.parse(readFileSync(new URL("../src/facts.json", import.meta.url), "utf8"));

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

test("FX1-A-06: the defence log offers no Trace on a banned raider, which the lease refuses (12.3)", () => {
  const t = twoPlayers(true);
  established(t, t.raider.account);
  t.service.db.prepare("UPDATE accounts SET keeper_level = 6 WHERE id = ?").run(t.raider.account);
  const i = t.build.exampleIsland(true); i[5] = 2;
  t.service.publish(t.raider.account, i);
  const lease = t.service.lease(t.raider.account, t.bundle);
  const out = t.service.submit(t.raider.account, lease.token, play(t, lease, { plan: openPlan() }));
  assert.notEqual(out.verdict.grade, "foiled");
  const before = t.service.defences.view(t.defender.account);
  assert.ok(before.raids[0].trace, "a Trace before the ban");
  new Workshop(t.service).ban(t.raider.account, "cheating");
  assert.equal(t.service.observatory.view(t.defender.account).trace, null, "the Observatory offers none");
  assert.throws(() => t.service.lease(t.defender.account, before.raids[0].trace.bundle, null, { trace: true }),
                "the lease refuses a Trace on a banned raider");
  assert.equal(t.service.defences.view(t.defender.account).raids[0].trace, null, "no Trace button the lease refuses");
});

test("FX1-A-07: a card swapped to a republished island shows only laws from the raider's open chapters (7.6)", () => {
  const t = twoPlayers(true);
  const mm = t.service.matchmaking;
  assert.equal(mm.raider(t.raider.account).chapter, 1, "the raider has chapter 1 alone");
  const before = t.service.observatory.view(t.raider.account);
  assert.ok(before.targets.find((c) => c.bundle === t.bundle), "the defender's chapter-1 island is offered");
  // Within the hour, the defender republishes the realm with Haste, chapter 2's.
  t.clock.now += 60 * 1000;
  const { bundle: haste } = t.service.publish(t.defender.account, t.build.exampleIsland(false));
  assert.equal(mm.fresh(t.service.now()).find((c) => c.bundle === haste)?.chapter, 2, "the new island is chapter 2's");
  const after = t.service.observatory.view(t.raider.account);
  assert.deepEqual(after.targets.filter((c) => c.bundle === haste).map((c) => c.bundle), [],
    "a chapter-2 island is not offered to a chapter-1 raider");
});

test("FX1-A-08: recentSuccess learns from the heists the rating learns from: a pair's later raids that day rate nothing (G30, G37)", () => {
  const t = twoPlayers(true);
  const mm = t.service.matchmaking;
  let lease = t.service.lease(t.raider.account, t.bundle);
  let out = t.service.submit(t.raider.account, lease.token, play(t, lease, { plan: [] }));
  assert.equal(out.verdict.grade, "foiled");
  assert.ok(out.rating, "the pair's first raid of the day is rated");
  for (let i = 0; i < 3; i++) {
    t.clock.now += 60 * 1000;
    lease = t.service.lease(t.raider.account, t.bundle);
    out = t.service.submit(t.raider.account, lease.token, play(t, lease, { plan: openPlan() }));
    assert.equal(out.verdict.grade, "clean");
    assert.equal(out.rating, null, "a pair's later raid that day is not rated");
  }
  assert.equal(mm.raiderRating(t.raider.account).games, 1, "one heist rated the raider");
  assert.equal(mm.recentSuccess(t.raider.account), 0, "the one rated heist was foiled");
  assert.equal(mm.raider(t.raider.account).recent, 0);
});

test("FX1-A-09 (contested): the list says it reached for echoes when there was no echo to reach for (12.22)", () => {
  // FX1-A-09: this asserts today's behaviour, which generated.test.mjs
  // asserts too ("echoes first"); server-a.md lists it as contested.
  const candidate = (id, p) => ({ bundle: id, owner: `owner-${id}`, realm: "heart", realmLevel: 1, keeperLevel: 5,
    renown: 100, rating: ratingFor(p), deviation: 0, origin: "authored", echo: false });
  const raider = { account: "me", rating: 1500, deviation: 0, renown: 100, keeperLevel: 5, recent: 0.625 };
  const out = offer(raider, [candidate("a", 0.62), candidate("b", 0.63)]);
  assert.ok(out.targets.every((c) => !c.echo), "no echo is offered");
  assert.equal(out.generated, false);
  assert.equal(out.echoes, true, "today echoes is claimed with no echo candidate");
});

test("FX1-A-10: an IPv4-mapped address written in hex or in full shares one /64 bucket (limits.mjs, not this task's)", () => {
  // FX1-A-10: this asserts today's behaviour; the fix is limits.mjs's
  // (server-a.md), which turns these into "198.51.100.7" and "203.0.113.1".
  assert.equal(peerKey("::ffff:198.51.100.7"), "198.51.100.7", "the dotted form Node gives is the IPv4 address");
  assert.deepEqual(["::ffff:c633:6407", "0:0:0:0:0:ffff:198.51.100.7", "::ffff:cb00:7101"].map(peerKey),
    ["0:0:0:0::/64", "0:0:0:0::/64", "0:0:0:0::/64"]);
});

test("FX1-A-11: a refused Trace upload does not use up the Trace (12.3, 24.13)", () => {
  const t = twoPlayers(true);
  established(t, t.raider.account);
  const island = t.build.exampleIsland(true); island[5] = 2;
  const home = t.service.publish(t.raider.account, island).bundle;
  const lease = t.service.lease(t.raider.account, t.bundle);
  const robbed = t.service.submit(t.raider.account, lease.token, play(t, lease, { plan: openPlan() }));
  assert.equal(robbed.validated, true);
  assert.notEqual(robbed.verdict.grade, "foiled");
  const first = t.service.lease(t.defender.account, home, null, { trace: true });
  assert.equal(first.trace, true);
  const junk = t.service.submit(t.defender.account, first.token, new Uint8Array(10));
  assert.deepEqual([junk.validated, junk.reason], [false, "replay_malformed"]);
  t.clock.now += 1_000;
  let again;
  assert.doesNotThrow(() => { again = t.service.lease(t.defender.account, home, null, { trace: true }); },
                      "a refused submission is not a play: the Trace is still owed");
  assert.equal(again.trace, true);
  const out = t.service.submit(t.defender.account, again.token, play(t, again, { plan: openPlan() }));
  assert.equal(out.validated, true);
  assert.throws(() => t.service.lease(t.defender.account, home, null, { trace: true }),
                (e) => e.reason === "nothing_to_trace", "played for real, it is used up");
});

test("FX1-A-12: a lease at exactly expires_at is run out for submit as it is for issue (24.12, G17)", () => {
  const t = twoPlayers(true);
  const first = t.service.lease(t.raider.account, t.bundle);
  const replay = play(t, first, { plan: openPlan() });
  t.clock.now = first.expiresAt;
  const second = t.service.lease(t.raider.account, t.bundle);
  assert.notEqual(second.token, first.token, "issue reads the first lease as run out and issues a new one");
  assert.equal(t.service.submit(t.raider.account, first.token, replay).validated, true);
  assert.equal(t.service.db.prepare("SELECT grace FROM heists WHERE token = ?").get(first.token).grace, 1,
    "a lease issue treated as run out is submitted on the day's grace");
});

test("FX1-A-13: a raid on the second publisher of shared bytes rates their island, in their realm (12.22)", () => {
  const t = twoPlayers(true);
  const b = t.service.session("gc:second").account;
  established(t, b);
  assert.equal(t.service.publish(b, t.island, "outer-1").bundle, t.bundle, "one snapshot, the first publisher's (heart)");
  const before = t.service.matchmaking.islandRating(b, "outer-1");
  assert.ok(before, "B's outer-1 island entered at its prior");
  const lease = t.service.lease(t.raider.account, t.bundle, b);
  const out = t.service.submit(t.raider.account, lease.token, play(t, lease, { plan: openPlan() }));
  assert.equal(out.validated, true);
  assert.equal(t.service.matchmaking.islandRating(b, "outer-1").games, before.games + 1, "B's outer-1 island played a rated game");
  assert.equal(t.service.matchmaking.islandRating(b, "heart"), null, "no rating for a B/heart island B never published");
});

test("FX1-A-14: a law cast in both slots of a foiled heist gives the defender one page of it (7.6)", () => {
  const t = twoPlayers(true);
  const d = t.service.codex;
  const pages = () => d.row(t.defender.account, "half_gravity")?.pages ?? 0;
  d.ensure(t.defender.account, t.clock.now);
  const before = pages();
  d.afterHeist({ attacker: t.raider.account, defender: t.defender.account, bundle: t.bundle, mode: "raid", token: "x" },
               { grade: "foiled", broken: 0, caught: 0 }, t.clock.now, ["half_gravity", "half_gravity"]);
  assert.equal(pages() - before, 1, "'the defender gets one page of it' (7.6)");
});

test("FX1-A-15: the constellation league answers [] for an open season and for no season (seasons.mjs, not this task's)", () => {
  // FX1-A-15: this asserts today's behaviour; the fix is seasons.mjs's
  // (server-a.md): 409 season_still_open and 404 no_such_season, as result().
  const t = server();
  t.service.seasons.current();
  assert.deepEqual(t.service.seasons.constellationTable(1), []);
  assert.deepEqual(t.service.seasons.constellationTable(99), []);
});

test("FX1-A-16: a link's number is given again, so a retried DELETE takes down the next link (links.mjs, not this task's)", () => {
  // FX1-A-16: this asserts today's behaviour; the fix is links.mjs's
  // (server-a.md): a link's number is never given again.
  const facts = t0facts();
  const t = server({ strictUniverse: true });
  const me = t.service.session("gc:links").account;
  t.service.db.prepare("UPDATE accounts SET keeper_level = 40 WHERE id = ?").run(me);
  t.service.book(me, "starlight", 1_000_000, "a test's grant");
  for (const type of facts.REALM_TYPES.slice(0, 3)) t.service.universe.open(me, type);
  const l = t.service.links;
  const n = l.build(me, { a: "outer-1", b: "outer-2", kind: "rope_bridge" }).universe.links.find((x) => x.kind === "rope_bridge").n;
  l.remove(me, n);
  const chute = l.build(me, { a: "outer-2", b: "outer-3", kind: "chute" }).universe.links.find((x) => x.kind === "chute");
  assert.equal(chute.n, n, "the new link took the number of the one taken down");
  l.remove(me, n); // the first DELETE's retry
  assert.equal(t.service.db.prepare("SELECT COUNT(*) AS n FROM links WHERE owner = ? AND kind = 'chute'").get(me).n, 0,
    "today the retry takes the Chute down");
});

test("FX1-A-17: a weave taken out before it finishes counts as a mastery step (weaving.mjs, not this task's)", () => {
  // FX1-A-17: this asserts today's behaviour; the fix is weaving.mjs's with
  // codex.woven (server-a.md): a law counts once its weaving finishes.
  const t = server({ strictUniverse: true });
  const me = t.service.session("gc:weaver").account;
  t.service.book(me, "aether", 10_000, "a test's grant");
  const steps = () => t.service.codex.show(me).mastery.find((m) => m.school === "Motion").steps;
  assert.equal(steps(), 0);
  t.service.weaving.weave(me, { realm: "heart", slot: 1, law: "half_gravity" });
  t.service.weaving.unweave(me, { realm: "heart", slot: 1 });
  t.clock.now += 2 * 60 * 60 * 1000;
  assert.equal(steps(), 1, "today the weave never finished, and still counts");
});
