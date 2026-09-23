// §24.12's stages and §24.13's two edges, end to end, against the real
// simulation build.

import assert from "node:assert/strict";
import { test } from "node:test";

import { LEASE_MS, Refused } from "../src/service.mjs";
import { readHeader } from "../src/sim.mjs";
import { sha256 } from "../src/store.mjs";
import { openPlan, play, server, simulation, twoPlayers } from "./setup.mjs";

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
  // A rock pillar on the third landing tile: the crew could not land there.
  island[14 + 2 * 3] = (island[14 + 2 * 3] & 0xf0) | 1;
  assert.throws(() => t.service.publish(me.account, island),
    (e) => e.status === 422 && e.detail.problems.includes("landing_blocked"));
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
    "INSERT INTO ledger (account, currency, amount, reason, at) VALUES (?, 'starlight', 5, 'test', 0)")
    .run(t.raider.account);
  assert.throws(() => t.service.db.prepare("UPDATE ledger SET amount = 500").run(), /append-only/);
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
  // Vault level 3: 5,400 × 1 × 1 × 1 × 1 × 508/508.
  assert.equal(out.haul.total, 5400);
  assert.deepEqual(t.service.balance(t.raider.account), { starlight: 2700, essence: 2700 });
});

test("a retry is answered from the first decision and pays nothing twice (§24.12)", () => {
  const t = twoPlayers();
  const lease = t.service.lease(t.raider.account, t.bundle);
  const replay = play(t, lease, { plan: openPlan() });
  const first = t.service.submit(t.raider.account, lease.token, replay);
  const again = t.service.submit(t.raider.account, lease.token, replay);
  assert.equal(again.repeated, true);
  assert.equal(again.haul.total, first.haul.total);
  assert.deepEqual(t.service.balance(t.raider.account), { starlight: 2700, essence: 2700 });
  const rows = t.service.db.prepare("SELECT COUNT(*) AS n FROM ledger WHERE account = ?")
    .get(t.raider.account).n;
  assert.equal(rows, 2, "one haul, in two currencies");
});

test("the second raid of the day pays 0.85 of the first, and the fee is 2% (§9.4, §9.6)", () => {
  const t = twoPlayers();
  const first = t.service.lease(t.raider.account, t.bundle);
  t.service.submit(t.raider.account, first.token, play(t, first, { plan: openPlan() }));
  t.clock.now += 60 * 60 * 1000;
  const second = t.service.lease(t.raider.account, t.bundle);
  assert.notEqual(second.token, first.token, "the first lease was used");
  const out = t.service.submit(t.raider.account, second.token, play(t, second, { plan: openPlan() }));
  assert.equal(out.haul.total, Math.floor(5400 * 0.85));
  assert.equal(out.fee, 100, "2% of 2,700 is 54, and the floor is 100");
  // Clean, so the fee came back: 2,700 + 2,295 each side of the split.
  assert.deepEqual(t.service.balance(t.raider.account),
                   { starlight: 2700 + 2295, essence: 2700 + 2295 });
});

test("a foiled raider pays the fee to the defender (§12.9)", () => {
  const t = twoPlayers(false);                 // the defended example
  // A raider with Starlight, so there is a fee to pay.
  t.service.db.prepare(
    "INSERT INTO ledger (account, currency, amount, reason, at) VALUES (?, 'starlight', 50000, 'grant', 0)")
    .run(t.raider.account);
  const lease = t.service.lease(t.raider.account, t.bundle);
  const out = t.service.submit(t.raider.account, lease.token, play(t, lease, { crew: 4 }));
  assert.equal(out.validated, true);
  assert.equal(out.verdict.grade, "foiled");
  assert.equal(out.fee, 1000);
  assert.equal(out.haul.total, 0);
  assert.equal(t.service.balance(t.raider.account).starlight, 49_000);
  assert.equal(t.service.balance(t.defender.account).starlight, 1_000);
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

test("a session is a signed token, and a forged one is refused", () => {
  const t = server();
  const s = t.service.session("gc:someone");
  assert.equal(t.service.account(s.token), s.account);
  refusal(() => t.service.account(s.token.slice(0, -2) + "xx"), "session_refused");
  t.clock.now += 2 * 60 * 60 * 1000;
  refusal(() => t.service.account(s.token), "session_refused");
  refusal(() => t.service.session("not a platform credential"), "platform_identity_refused");
});
