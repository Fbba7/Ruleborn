// §24.12's stages and §24.13's two edges, end to end, against the real
// simulation build.

import assert from "node:assert/strict";
import { test } from "node:test";

import { dayCeiling } from "../src/economy.mjs";
import { LEASE_MS, Refused } from "../src/service.mjs";
import { readHeader } from "../src/sim.mjs";
import { sha256 } from "../src/store.mjs";
import { established, openPlan, play, server, simulation, twoPlayers } from "./setup.mjs";

const refusal = (fn, reason) => assert.throws(fn, (e) => e instanceof Refused && e.reason === reason);

test("the simulation and the store agree on every island's hash", () => {
  const build = simulation();
  for (const open of [false, true]) {
    const island = build.exampleIsland(open);
    const read = build.island(island);
    assert.deepEqual(read.problems, [], "both examples may be published");
    assert.equal(read.digest, sha256(island), "sim/'s SHA-256 against Node's");
  }
});

test("an island §5.2 or §6.1 forbids is refused, with the rule named", () => {
  const t = server();
  const me = t.service.session("gc:keeper");
  const island = t.build.exampleIsland(false);
  // Rock pillars on the four tiles beside the Vault at (6, 9): no edge the
  // crew could land on walks to it.
  for (const [x, y] of [[6, 8], [5, 9], [7, 9], [6, 10]]) {
    const i = 14 + 3 * (y * 12 + x);
    island[i] = (island[i] & 0xf0) | 1;
  }
  assert.throws(() => t.service.publish(me.account, island),
    (e) => e.status === 422 && e.detail.problems.includes("sealed"));
});

test("the Heart is realm level 3, and an island of another level is published only as an outer realm (5.2, G19)", () => {
  const t = server();
  const me = t.service.session("gc:keeper").account;
  // A bare realm-level-1 island: 10 by 10, the Vault at (5, 7), nothing on it.
  const side = 10;
  const bytes = new Uint8Array(14 + side * side * 3 + 3);
  bytes.set(new TextEncoder().encode("RBI1"));
  bytes[4] = 1;                                        // realm level
  bytes[5] = 1;                                        // Vault level
  new DataView(bytes.buffer).setUint32(6, 750, true);  // exposed
  bytes.set([5, 7, 9, 9], 10);                         // the Vault, the entrance
  assert.deepEqual(t.build.island(bytes).problems, []);
  assert.throws(() => t.service.publish(me, bytes),
    (e) => e.status === 422 && e.detail.problems.includes("heart_level"));
  assert.ok(t.service.publish(me, bytes, "outer-1").bundle);
  // Above 3 as well as below: a level-4 Heart, 13 by 13.
  const big = new Uint8Array(14 + 13 * 13 * 3 + 3);
  big.set(bytes.subarray(0, 14));
  big[4] = 4;
  assert.deepEqual(t.build.island(big).problems, []);
  assert.throws(() => t.service.publish(me, big),
    (e) => e.status === 422 && e.detail.problems.includes("heart_level"));
});

test("publishing is content-addressed and idempotent", () => {
  const t = twoPlayers(false);
  assert.equal(t.bundle, sha256(t.island));
  assert.deepEqual(t.service.bundle(t.bundle), t.island);
  assert.equal(t.service.publish(t.defender.account, t.island).bundle, t.bundle,
               "republishing the same bytes is the same snapshot");
});

test("snapshots and the ledger cannot be edited", () => {
  const t = twoPlayers();
  assert.throws(() => t.service.db.prepare("UPDATE snapshots SET exposed = 0").run(), /never edited/);
  t.service.db.prepare(
    "INSERT INTO ledger (account, starlight, reason, at) VALUES (?, 5, 'test', 0)")
    .run(t.raider.account);
  assert.throws(() => t.service.db.prepare("UPDATE ledger SET starlight = 500").run(), /append-only/);
  assert.throws(() => t.service.db.prepare("DELETE FROM ledger").run(), /append-only/);
});

test("a lease is a seed, a token, the clock and an expiry a day away (§24.12)", () => {
  const t = twoPlayers();
  const lease = t.service.lease(t.raider.account, t.bundle);
  assert.equal(lease.ticks, 150 * 30, "§5.4: a Heart heist with no links is 150 s");
  assert.equal(lease.expiresAt, t.clock.now + LEASE_MS);
  assert.match(lease.token, /^[0-9a-f]{32}$/);
  refusal(() => t.service.lease(t.defender.account, t.bundle), "own_island");
});

test("a second device asking for the same target is handed the same lease (§24.13)", () => {
  const t = twoPlayers();
  const first = t.service.lease(t.raider.account, t.bundle);
  t.clock.now += 60_000;
  assert.deepEqual(t.service.lease(t.raider.account, t.bundle), first);
});

test("a planned clean heist is re-simulated, and its haul minted with the fee returned", () => {
  const t = twoPlayers();
  const lease = t.service.lease(t.raider.account, t.bundle);
  const replay = play(t, lease, { plan: openPlan() });
  assert.equal(readHeader(replay).island, t.bundle);
  const out = t.service.submit(t.raider.account, lease.token, replay);
  assert.equal(out.validated, true);
  assert.equal(out.verdict.grade, "clean");
  assert.equal(out.verdict.banked, 508, "three bags full: 104 + 104 + 300");
  // Vault level 3: 11,250 × 1 × 1 × 1 × 1 × 508/508.
  assert.equal(out.haul.total, 11_250);
  assert.deepEqual(t.service.balance(t.raider.account), { starlight: 5625, essence: 5625 });
});

test("a retry is answered from the first decision and pays nothing twice (§24.12)", () => {
  const t = twoPlayers();
  const lease = t.service.lease(t.raider.account, t.bundle);
  const replay = play(t, lease, { plan: openPlan() });
  const first = t.service.submit(t.raider.account, lease.token, replay);
  const again = t.service.submit(t.raider.account, lease.token, replay);
  assert.equal(again.repeated, true);
  assert.equal(again.haul.total, first.haul.total);
  assert.deepEqual(t.service.balance(t.raider.account), { starlight: 5625, essence: 5625 });
  const rows = t.service.db.prepare("SELECT COUNT(*) AS n FROM ledger WHERE account = ?")
    .get(t.raider.account).n;
  assert.equal(rows, 1, "one row for the heist, both currencies in it");
});

test("the second raid of the day pays 0.85 of the first, and the fee is 2% (§9.4, §9.6)", () => {
  const t = twoPlayers();
  const first = t.service.lease(t.raider.account, t.bundle);
  t.service.submit(t.raider.account, first.token, play(t, first, { plan: openPlan() }));
  t.clock.now += 60 * 60 * 1000;
  const second = t.service.lease(t.raider.account, t.bundle);
  assert.notEqual(second.token, first.token, "the first lease was used");
  const out = t.service.submit(t.raider.account, second.token, play(t, second, { plan: openPlan() }));
  assert.equal(out.haul.total, Math.floor(11_250 * 0.85));
  assert.equal(out.fee, 225, "2% of B(3), 11,250 (F39)");
  // Clean, so the fee came back: 5,625 and then 4,781 on each side of the split.
  assert.deepEqual(t.service.balance(t.raider.account),
                   { starlight: 5625 + 4781, essence: 5625 + 4781 });
});

test("a haul is capped by what the raider was already paid today (§9.6, §24.12)", () => {
  const t = twoPlayers();
  // 46,000 of the day's 50,000 already paid (the raider stands at Vault level 1).
  t.service.db.prepare(
    "INSERT INTO ledger (account, starlight, paid, reason, at) VALUES (?, 46000, 46000, 'haul (9.6)', ?)")
    .run(t.raider.account, t.clock.now - 60_000);
  const lease = t.service.lease(t.raider.account, t.bundle);
  const out = t.service.submit(t.raider.account, lease.token, play(t, lease, { plan: openPlan() }));
  assert.equal(out.haul.total, 4000, "11,250 cut to the 4,000 left of 50,000");
  assert.equal(out.haul.cappedBy, "day");
  // The day turns over at midnight UTC, and yesterday's pay counts only to the week.
  t.clock.now += 24 * 60 * 60 * 1000;
  const next = t.service.lease(t.raider.account, t.bundle);
  const fresh = t.service.submit(t.raider.account, next.token, play(t, next, { plan: openPlan() }));
  assert.equal(fresh.haul.total, 11_250);
  assert.equal(fresh.haul.cappedBy, null);
});

test("target lists are files, one a band, holding every island's current snapshot (§24.8)", () => {
  const t = twoPlayers(false);
  const other = t.service.session("gc:another");
  established(t, other.account);
  t.service.publish(other.account, t.build.exampleIsland(true));
  const index = t.service.targetLists();
  assert.deepEqual(Object.keys(index), ["realm-level-3"]);
  const list = JSON.parse(new TextDecoder().decode(t.service.bundle(index["realm-level-3"])));
  assert.equal(list.candidates.length, 2);
  assert.ok(list.candidates.every((c) => c.keeperLevel === 1 && c.realmLevel === 3));
  // The defender republishes: the old snapshot is kept (never edited) but is
  // no longer anybody's target.
  t.service.publish(t.defender.account, t.build.exampleIsland(true));
  const after = JSON.parse(new TextDecoder().decode(
    t.service.bundle(t.service.targetLists()["realm-level-3"])));
  assert.ok(!after.candidates.some((c) => c.bundle === t.bundle), "the old snapshot is gone");
  assert.equal(after.candidates.length, 2);
  assert.deepEqual(t.service.targets(), t.service.targetLists());
});

test("two players with the same island are two targets, and a foiled fee goes to the one raided", () => {
  const t = twoPlayers(false);
  const twin = t.service.session("gc:twin");
  established(t, twin.account);
  t.service.publish(twin.account, t.build.exampleIsland(false));   // the defender's bytes
  const list = JSON.parse(new TextDecoder().decode(
    t.service.bundle(t.service.targetLists()["realm-level-3"])));
  assert.deepEqual(list.candidates.map((c) => c.owner).sort(),
                   [t.defender.account, twin.account].sort());
  refusal(() => t.service.lease(twin.account, t.bundle), "own_island");
  t.service.db.prepare(
    "INSERT INTO ledger (account, starlight, reason, at) VALUES (?, 50000, \'grant\', 0)")
    .run(t.raider.account);
  const lease = t.service.lease(t.raider.account, t.bundle, twin.account);
  const out = t.service.submit(t.raider.account, lease.token, play(t, lease, { crew: 3 }));
  assert.equal(out.verdict.grade, "foiled");
  assert.equal(t.service.balance(twin.account).starlight, 225, "the twin was raided");
  assert.equal(t.service.balance(t.defender.account).starlight, 0);
});

test("a snapshot no island is on any more is an echo for 14 days, and then cannot be leased (12.3)", () => {
  const t = twoPlayers(false);
  t.service.publish(t.defender.account, t.build.exampleIsland(true));   // moves on
  assert.equal(t.service.lease(t.raider.account, t.bundle).echo, true);
  const u = twoPlayers(false);
  u.service.publish(u.defender.account, u.build.exampleIsland(true));
  u.clock.now += 15 * 24 * 60 * 60 * 1000;
  refusal(() => u.service.lease(u.raider.account, u.bundle), "superseded");
});

test("a band every island has left keeps no list", () => {
  const t = twoPlayers();
  assert.ok("realm-level-3" in t.service.targetLists());
  t.service.db.prepare("DELETE FROM islands").run();
  assert.deepEqual(t.service.targetLists(), {});
  assert.deepEqual(t.service.targets(), {});
});

test("an unchanged band regenerates to the same file, so the edge keeps its cache", () => {
  const t = twoPlayers();
  const first = t.service.targetLists();
  t.clock.now += 15 * 60 * 1000;
  assert.deepEqual(t.service.targetLists(), first);
});

test("a foiled raider pays the fee to the defender (§12.9)", () => {
  const t = twoPlayers(false);                 // the defended example
  // A raider with Starlight, so there is a fee to pay.
  t.service.db.prepare(
    "INSERT INTO ledger (account, starlight, reason, at) VALUES (?, 50000, \'grant\', 0)")
    .run(t.raider.account);
  const lease = t.service.lease(t.raider.account, t.bundle);
  const out = t.service.submit(t.raider.account, lease.token, play(t, lease, { crew: 3 }));
  assert.equal(out.validated, true);
  assert.equal(out.verdict.grade, "foiled");
  assert.equal(out.fee, 225, "2% of B(3), 11,250 (F39)");
  assert.equal(out.haul.total, 0);
  assert.equal(t.service.balance(t.raider.account).starlight, 50_000 - 225);
  assert.equal(t.service.balance(t.defender.account).starlight, 225);
});

test("a replay that does not reproduce pays nothing, takes nothing, and is flagged (§24.12)", () => {
  const t = twoPlayers();
  const lease = t.service.lease(t.raider.account, t.bundle);
  const replay = play(t, lease, { plan: openPlan() });
  replay[replay.length - 40] ^= 1;               // one kept checksum, changed
  const out = t.service.submit(t.raider.account, lease.token, replay);
  assert.equal(out.validated, false);
  assert.equal(out.reason, "diverged");
  assert.ok(out.second > 0);
  assert.deepEqual(t.service.balance(t.raider.account), { starlight: 0, essence: 0 });
  const row = t.service.db.prepare("SELECT review FROM heists WHERE token = ?").get(lease.token);
  assert.equal(row.review, 1, "a note for review — one mismatch is never a ban");
});

/** `n` validated heists by `attacker` this week, written straight to the
 *  tables, each with the given mode and outcome. */
function pastHeists(t, attacker, n, { mode = "raid", outcome = {} } = {}) {
  // Against someone else, so G37's once-a-day pair rule is not what is tested.
  const other = t.service.session("gc:someone-else").account;
  for (let i = 0; i < n; i++) {
    const token = `past-${attacker}-${mode}-${i}-${JSON.stringify(outcome).length}`;
    t.service.db.prepare(
      `INSERT INTO leases (token, attacker, bundle, defender, seed, ticks, rules, issued_at, expires_at,
                           echo, trace_of, mode, challenge, era)
       VALUES (?, ?, ?, ?, '1', 4500, 'r', ?, ?, 0, NULL, ?, NULL, 0)`)
      .run(token, attacker, t.bundle, other, t.clock.now - 1000, t.clock.now, mode);
    t.service.db.prepare(
      `INSERT INTO heists (token, attacker, bundle, seed, log_hash, state_hash, validated, outcome,
                           review, grace, submitted_at, day)
       VALUES (?, ?, ?, '1', 'h', 's', 1, ?, 0, 0, ?, ?)`)
      .run(token, attacker, t.bundle, JSON.stringify(outcome), t.clock.now - 1000,
           new Date(t.clock.now).toISOString().slice(0, 10));
  }
}

test("a pair's second foil of the day keeps the fee with the game (9.4, G37)", () => {
  const t = twoPlayers(false);
  t.service.db.prepare(
    "INSERT INTO ledger (account, starlight, reason, at) VALUES (?, 50000, \'grant\', 0)")
    .run(t.raider.account);
  for (const hour of [0, 1]) {
    t.clock.now += hour * 60 * 60 * 1000;
    const lease = t.service.lease(t.raider.account, t.bundle);
    const out = t.service.submit(t.raider.account, lease.token, play(t, lease, { crew: 3 }));
    assert.deepEqual([out.verdict.grade, out.fee, out.feeReturned], ["foiled", 225, 0]);
  }
  assert.equal(t.service.balance(t.raider.account).starlight, 50_000 - 2 * 225);
  assert.equal(t.service.balance(t.defender.account).starlight, 225, "the first fee only");
});

test("past 20 paid raids a week, a raid costs nothing and pays nothing, and the lease says so (9.6, G20)", () => {
  const t = twoPlayers();
  t.service.db.prepare(
    "INSERT INTO ledger (account, starlight, reason, at) VALUES (?, 50000, \'grant\', 0)")
    .run(t.raider.account);
  // Games among friends are not raids, and do not count.
  pastHeists(t, t.raider.account, 5, { mode: "friendly" });
  pastHeists(t, t.raider.account, 19);
  const twentieth = t.service.lease(t.raider.account, t.bundle);
  assert.deepEqual([twentieth.fee, twentieth.capped, twentieth.week.raids], [225, [], 19]);
  const paid = t.service.submit(t.raider.account, twentieth.token, play(t, twentieth, { plan: openPlan() }));
  assert.ok(paid.haul.total > 0);
  const after = t.service.balance(t.raider.account);
  t.clock.now += 60 * 60 * 1000;
  const lease = t.service.lease(t.raider.account, t.bundle);
  assert.deepEqual([lease.fee, lease.capped], [0, ["week_raids"]]);
  const out = t.service.submit(t.raider.account, lease.token, play(t, lease, { plan: openPlan() }));
  assert.deepEqual([out.fee, out.haul.total, out.haul.cappedBy], [0, 0, "week"]);
  assert.deepEqual(t.service.balance(t.raider.account), after, "no ledger line moved");
  assert.ok(paid.keeper.gained > 0);
  assert.equal(out.keeper, null, "and no Keeper experience (14.2)");
  // Monday 00:00 UTC starts a new week.
  t.clock.now += 7 * 24 * 60 * 60 * 1000;
  assert.deepEqual(t.service.lease(t.raider.account, t.bundle).capped, []);
});

test("the week turns at Monday 00:00 UTC, not seven days after a raid (G20)", () => {
  const t = twoPlayers();
  const d = new Date(t.clock.now);
  t.clock.now = Date.UTC(d.getUTCFullYear(), d.getUTCMonth(), d.getUTCDate() + (7 - d.getUTCDay()) % 7, 23, 59);
  pastHeists(t, t.raider.account, 20);                 // on Sunday evening
  assert.deepEqual(t.service.lease(t.raider.account, t.bundle).capped, ["week_raids"]);
  t.clock.now += 60 * 1000;                            // Monday, 00:00 UTC
  assert.deepEqual(t.service.lease(t.raider.account, t.bundle).capped, [], "a minute later, a new week");
});

test("a Trace counts to the week, and past the 20th pays nothing and opens nothing (G20)", () => {
  const t = twoPlayers(true);
  established(t, t.raider.account);
  const island = t.build.exampleIsland(true);
  island[5] = 2;
  const home = t.service.publish(t.raider.account, island).bundle;
  const lease = t.service.lease(t.raider.account, t.bundle);
  t.service.submit(t.raider.account, lease.token, play(t, lease, { plan: openPlan() }));   // robbed
  pastHeists(t, t.defender.account, 20);
  const trace = t.service.lease(t.defender.account, home, null, { trace: true });
  const out = t.service.submit(t.defender.account, trace.token, play(t, trace, { plan: openPlan() }));
  assert.equal(out.validated, true);
  assert.deepEqual([out.fee, out.haul.total, out.haul.cappedBy], [0, 0, "week"]);
  // The defender, past the week, raids the raider back: nothing paid, and
  // no Trace opened for the raider by a raid that took nothing.
  pastHeists(t, t.raider.account, 20);
  const back = t.service.lease(t.defender.account, home);
  t.service.submit(t.defender.account, back.token, play(t, back, { plan: openPlan() }));
  refusal(() => t.service.lease(t.raider.account, t.bundle, null, { trace: true }), "nothing_to_trace");
});

test("the fee comes back in full after a loud heist and half after a partial one (9.4, C41)", () => {
  for (const [grade, back] of [["loud", 225], ["partial", 112]]) {
    const t = twoPlayers();
    t.service.db.prepare(
      "INSERT INTO ledger (account, starlight, reason, at) VALUES (?, 50000, \'grant\', 0)")
      .run(t.raider.account);
    const lease = t.service.lease(t.raider.account, t.bundle);
    const row = t.service.db.prepare("SELECT * FROM leases WHERE token = ?").get(lease.token);
    const verdict = { grade, out: 3, caught: 0, crew: 3, banked: 400, capacity: 800, pages: 0, cracked: 1, left: 0 };
    // Settled as a submission is, in the grant's own transaction.
    const out = t.service.settle(row, new Uint8Array(8), "c41", t.clock.now, { validated: true, verdict });
    assert.deepEqual([out.fee, out.feeReturned], [225, back], grade);
    assert.equal(t.service.balance(t.raider.account).starlight, 50_000 - 225 + back + out.haul.starlight, grade);
  }
});

test("a game among friends is not a raid for fatigue (9.6, F48)", () => {
  const t = twoPlayers();
  const { invite } = t.service.friends.invite(t.defender.account);
  t.service.friends.accept(t.raider.account, invite);
  const fun = t.service.lease(t.raider.account, t.bundle, null, { mode: "friendly" });
  t.service.submit(t.raider.account, fun.token, play(t, fun, { plan: openPlan() }));
  t.clock.now += 60 * 60 * 1000;
  const raid = t.service.lease(t.raider.account, t.bundle);
  const out = t.service.submit(t.raider.account, raid.token, play(t, raid, { plan: openPlan() }));
  assert.equal(out.haul.total, 11_250, "the day's first raid, at full pay");
});

test("a raider's first ten heists of the week move Renown, and later ones pay only the haul (12.9, F40)", () => {
  const t = twoPlayers();
  pastHeists(t, t.raider.account, 9, { outcome: { renownCounted: true } });
  pastHeists(t, t.raider.account, 3, { outcome: { renownCounted: false } });
  const tenth = t.service.lease(t.raider.account, t.bundle);
  assert.deepEqual(tenth.capped, []);
  const moved = t.service.submit(t.raider.account, tenth.token, play(t, tenth, { plan: openPlan() }));
  assert.equal(moved.renownCounted, true);
  assert.ok(moved.renown.raider > 0);
  const u = twoPlayers();
  pastHeists(u, u.raider.account, 10, { outcome: { renownCounted: true } });
  const lease = u.service.lease(u.raider.account, u.bundle);
  assert.deepEqual(lease.capped, ["week_renown"]);
  const out = u.service.submit(u.raider.account, lease.token, play(u, lease, { plan: openPlan() }));
  assert.deepEqual([out.renownCounted, out.renown], [false, { raider: 0, defender: 0 }]);
  assert.ok(out.haul.total > 0, "the haul is still paid");
});

test("a crew that never lands is refused and pays nothing (5.4)", () => {
  const t = twoPlayers();
  const lease = t.service.lease(t.raider.account, t.bundle);
  // Its one landing is inland, which is no landing at all.
  const inland = openPlan().map((c) => c.kind === "Land" ? { ...c, x: 6 * 256 + 128, y: 7 * 256 + 128 } : c);
  const unlanded = play(t, lease, { plan: inland });
  const out = t.service.submit(t.raider.account, lease.token, unlanded);
  assert.equal(out.validated, false);
  assert.equal(out.reason, "landing");
  assert.deepEqual(t.service.balance(t.raider.account), { starlight: 0, essence: 0 });
});

test("a replay must be the heist its lease allowed: the snapshot, the seed, the clock", () => {
  const t = twoPlayers();
  const lease = t.service.lease(t.raider.account, t.bundle);
  const wrongSeed = play(t, { ...lease, seed: (BigInt(lease.seed) + 1n).toString() },
                         { plan: openPlan() });
  assert.equal(t.service.submit(t.raider.account, lease.token, wrongSeed).reason, "wrong_seed");

  const u = twoPlayers();
  const l2 = u.service.lease(u.raider.account, u.bundle);
  const longer = play(u, { ...l2, ticks: l2.ticks + 30 }, { plan: openPlan() });
  assert.equal(u.service.submit(u.raider.account, l2.token, longer).reason, "wrong_clock");
});

test("a lease is bound to its attacker (§24.8)", () => {
  const t = twoPlayers();
  const lease = t.service.lease(t.raider.account, t.bundle);
  const stranger = t.service.session("gc:stranger");
  refusal(() => t.service.submit(stranger.account, lease.token, play(t, lease, { plan: openPlan() })),
          "lease_refused");
});

test("an expired lease is honoured once a day, and then pays nothing (§24.12, G17)", () => {
  const t = twoPlayers();
  // A second target, so the raider can hold two leases at once (§24.13).
  const other = t.service.session("gc:another-defender");
  established(t, other.account);
  const { bundle: second } = t.service.publish(other.account, t.build.exampleIsland(false));
  const one = t.service.lease(t.raider.account, t.bundle);
  const two = t.service.lease(t.raider.account, second);
  const replayOne = play(t, one, { plan: openPlan() });
  const replayTwo = play(t, two, { crew: 4 });
  t.clock.now += LEASE_MS + 1;
  const late = t.service.submit(t.raider.account, one.token, replayOne);
  assert.equal(late.validated, true);
  assert.equal(late.grace, true);
  const later = t.service.submit(t.raider.account, two.token, replayTwo);
  assert.equal(later.validated, false);
  assert.equal(later.reason, "lease_expired");
});

/** The planned heist, stopped once the bags are full: the crew never calls
 *  the skiff, and the clock catches it holding everything it loaded. */
const greedy = () => openPlan().filter((c) => c.kind !== "Skiff" && c.tick < 62 * 30);
const DAY = 24 * 60 * 60 * 1000;

test("a pair's Renown and stars move on its first heist of the day, and later ones pay the haul only (G37)", () => {
  const t = twoPlayers(true);
  const heist = () => {
    const lease = t.service.lease(t.raider.account, t.bundle);
    return t.service.submit(t.raider.account, lease.token, play(t, lease, { plan: openPlan() }));
  };
  const first = heist();
  assert.deepEqual([first.renown.raider, first.stars.raider], [20, 10]);
  t.clock.now += 60_000;
  const again = heist();
  assert.equal(again.validated, true);
  assert.equal(again.haul.total, Math.floor(11_250 * 0.85), "the haul is still paid, within the raider's caps");
  assert.deepEqual([again.renown, again.stars], [{ raider: 0, defender: 0 }, { raider: 0, defender: 0 }]);
  assert.equal(t.service.seasons.league(t.raider.account).renown, 20);
  assert.equal(t.service.track.stars(t.raider.account), 10);
  t.clock.now += DAY;                                   // a new UTC day
  assert.equal(heist().stars.raider, 10);
});

test("a defence share counts to the defender's own day cap, and a pair's is paid once a day (9.4, 9.6, G37)", () => {
  const t = twoPlayers(true);
  const foil = () => {
    const lease = t.service.lease(t.raider.account, t.bundle);
    return t.service.submit(t.raider.account, lease.token, play(t, lease, { plan: greedy() }));
  };
  // The defender's Heart is Vault level 3: 100 left of their own day's ceiling.
  t.service.db.prepare(
    "INSERT INTO ledger (account, starlight, paid, reason, at) VALUES (?1, ?2, ?2, 'haul (9.6)', ?3)")
    .run(t.defender.account, Number(dayCeiling(3)) - 100, t.clock.now - 60_000);
  const first = foil();
  assert.equal(first.verdict.grade, "foiled");
  assert.deepEqual([first.fee, first.defence.total, first.stars.defender], [0, 100, 10]);
  t.clock.now += 60_000;
  const again = foil();
  assert.equal(again.verdict.grade, "foiled");
  assert.deepEqual([again.defence.total, again.stars, again.renown],
                   [0, { raider: 0, defender: 0 }, { raider: 0, defender: 0 }], "nothing minted a second time");
  assert.equal(t.service.balance(t.defender.account).essence, 50);
  t.clock.now += DAY;                                   // the defender's day, and the pair's, turn over
  assert.ok(foil().defence.total > 100);
});

test("a lease held in one mode is not handed back as another: a Trace is never charged as a raid (12.3, 24.13)", () => {
  const t = server();
  const d = t.service.session("gc:d").account;
  const r = t.service.session("gc:r").account;
  established(t, d);
  established(t, r);
  const { bundle: home } = t.service.publish(d, t.build.exampleIsland(true));
  const other = t.build.exampleIsland(true);
  other[5] = 2;
  const { bundle: theirs } = t.service.publish(r, other);
  t.service.book(d, "starlight", 10_000, "test");
  const raid = t.service.lease(d, theirs);                 // held, not yet played
  const robbery = t.service.lease(r, home);
  t.service.submit(r, robbery.token, play(t, robbery, { plan: openPlan() }));
  assert.throws(() => t.service.lease(d, theirs, null, { trace: true }),
                (e) => e.reason === "lease_held_in_another_mode" && e.status === 409 && e.detail.mode === "raid");
  // Given up by a submission that is no heist: it settles, and costs nothing.
  assert.equal(t.service.submit(d, raid.token, new Uint8Array(0)).reason, "replay_malformed");
  const trace = t.service.lease(d, theirs, null, { trace: true });
  assert.equal(trace.trace, true);
  assert.equal(t.service.submit(d, trace.token, play(t, trace, { plan: [] })).fee, 0);
});

test("a 13-to-15's challenge link is played by their friends only (17.6, 20.7)", () => {
  const t = twoPlayers(true);
  const f = t.service.friends;
  t.service.db.prepare("UPDATE accounts SET age_band = '13-15' WHERE id = ?").run(t.defender.account);
  const { challenge, bundle } = f.challenge(t.defender.account);
  const ask = () => t.service.lease(t.raider.account, bundle, null, { mode: "challenge", challenge });
  refusal(ask, "no_such_challenge");
  refusal(() => t.service.challenge(t.raider.account, challenge), "no_such_challenge");
  f.accept(t.raider.account, f.invite(t.defender.account).invite);
  assert.equal(t.service.challenge(t.raider.account, challenge).account, t.defender.account);
  assert.equal(ask().mode, "challenge");
});

test("an island goes to the Heart or one of six outer realms, and nowhere else (5.2)", () => {
  const t = twoPlayers(true);
  refusal(() => t.service.publish(t.defender.account, t.island, "realm0"), "no_such_realm");
  assert.equal(t.service.publish(t.defender.account, t.island, "outer-6").bundle, t.bundle);
  refusal(() => t.service.publish(t.defender.account, t.island, "outer-7"), "no_such_realm");
  assert.equal(t.service.db.prepare("SELECT COUNT(*) AS n FROM islands").get().n, 2);
});

test("a banned player's session ends with the ban, not an hour later (20.12)", () => {
  const t = server();
  const s = t.service.session("gc:cheat");
  t.service.db.prepare("UPDATE accounts SET banned_at = ? WHERE id = ?").run(t.clock.now, s.account);
  refusal(() => t.service.account(s.token), "banned");
});

test("a session is a signed token, and a forged one is refused", () => {
  const t = server();
  const s = t.service.session("gc:someone");
  assert.equal(t.service.account(s.token), s.account);
  refusal(() => t.service.account(s.token.slice(0, -2) + "xx"), "session_refused");
  t.clock.now += 2 * 60 * 60 * 1000;
  refusal(() => t.service.account(s.token), "session_refused");
  refusal(() => t.service.session("not a platform credential"), "platform_identity_refused");
});
