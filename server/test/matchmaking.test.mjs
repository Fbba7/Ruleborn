// How a target is chosen (§12.3, §12.22), against the real simulation
// build.

import assert from "node:assert/strict";
import { test } from "node:test";

import { expected, fresh, ratingFor, update } from "../src/glicko.mjs";
import { offer, prior, successBand } from "../src/matchmaking.mjs";
import { Refused } from "../src/service.mjs";
import { established, openPlan, play, twoPlayers } from "./setup.mjs";

const refusal = (fn, reason) => assert.throws(fn, (e) => e instanceof Refused && e.reason === reason);
const HOUR = 60 * 60 * 1000;
const near = (a, b, within, what) => assert.ok(Math.abs(a - b) <= within, `${what}: ${a} is not ${b}`);

test("Glicko-2 reproduces Glickman's worked example, with §12.22's constants (12.22)", () => {
  const r = update({ rating: 1500, deviation: 200, volatility: 0.06 }, [
    { opponent: { rating: 1400, deviation: 30 }, score: 1 },
    { opponent: { rating: 1550, deviation: 100 }, score: 0 },
    { opponent: { rating: 1700, deviation: 300 }, score: 0 },
  ]);
  near(r.rating, 1464.06, 0.01, "rating");
  near(r.deviation, 151.52, 0.01, "deviation");
  near(r.volatility, 0.05999, 0.00001, "volatility");
  assert.deepEqual(fresh(), { rating: 1500, deviation: 350, volatility: 0.06 });
});

test("an island enters at the middle of its origin's band, 350 wide, and narrows with every raid (12.22)", () => {
  assert.deepEqual(successBand(1, "generated"), [0.55, 0.7], "v3.7: one band at every realm level");
  assert.deepEqual(successBand(3, "generated"), [0.55, 0.7]);
  assert.deepEqual(successBand(1, "authored"), [0.55, 0.7], "authored islands keep §13.2's authored band");
  near(expected({ rating: 1500, deviation: 0 }, { ...prior(1), deviation: 0 }), 0.625, 1e-9,
       "a raider at the centre succeeds at the band's middle");
  const t = twoPlayers(false);
  const before = t.service.matchmaking.islandRating(t.defender.account, "heart");
  assert.equal(before.deviation, 350);
  let deviation = before.deviation;
  for (let day = 0; day < 3; day++) {
    const lease = t.service.lease(t.raider.account, t.bundle);
    const out = t.service.submit(t.raider.account, lease.token, play(t, lease, { plan: [] }));
    assert.equal(out.verdict.grade, "foiled");
    const now = t.service.matchmaking.islandRating(t.defender.account, "heart");
    assert.ok(now.deviation < deviation, "narrower");
    assert.ok(now.rating > before.rating, "a defence that holds rates harder");
    deviation = now.deviation;
    t.clock.now += 25 * HOUR;
  }
  const raider = t.service.matchmaking.raiderRating(t.raider.account);
  assert.ok(raider.rating < 1500 && raider.games === 3);
});

/** The example island, made a different island by its Vault level: two
 *  players who publish the same bytes share one snapshot. */
function another(t, open, vaultLevel) {
  const island = t.build.exampleIsland(open);
  island[5] = vaultLevel;
  return island;
}

/** A candidate a raider at 1500 beats with probability `p`. */
function candidate(id, p, extra = {}) {
  return { bundle: id, owner: `owner-${id}`, realm: "heart", realmLevel: 1, keeperLevel: 5, renown: 100,
           rating: ratingFor(p), deviation: 0, origin: "authored", echo: false, ...extra };
}
const RAIDER = { account: "me", rating: 1500, deviation: 0, renown: 100, keeperLevel: 5, recent: 0.625 };

test("the middle target is drawn from the raider-success band, the list sorted by predicted success (12.22)", () => {
  const pool = [candidate("a", 0.9), candidate("b", 0.8), candidate("c", 0.66), candidate("d", 0.6),
                candidate("e", 0.58), candidate("f", 0.4), candidate("g", 0.2)];
  const out = offer(RAIDER, pool);
  assert.equal(out.guaranteed, true);
  // The rating filter keeps c, d and e (within 15 points of 62.5%); d is
  // nearest the band's middle, so it is the middle entry.
  assert.deepEqual(out.targets.map((c) => c.bundle), ["c", "d", "e"]);
  const [lo, hi] = successBand(1);
  assert.ok(out.targets[1].predicted >= lo && out.targets[1].predicted <= hi);
  assert.deepEqual(out.widened, [], "three sit in the band: nothing widened");
  const wide = offer({ ...RAIDER, recent: 0.7 }, pool, { size: 5 });
  // Up to five at Observatory level 5 (12.3): four pass the filters here.
  assert.deepEqual(wide.targets.map((c) => c.bundle), ["b", "c", "d", "e"]);
});

test("Renown within 150 and Keeper level within 3 filter first; a thin band widens rating, Keeper level, Renown (12.22)", () => {
  const far = [candidate("renown", 0.62, { renown: 400 }), candidate("keeper", 0.64, { keeperLevel: 9 }),
               candidate("near", 0.63)];
  const out = offer(RAIDER, far);
  assert.deepEqual(out.widened, ["rating", "keeper", "renown"], "in §12.22's order");
  assert.equal(out.targets.length, 3);
  const fits = [candidate("x", 0.62), candidate("y", 0.63), candidate("z", 0.64), candidate("far", 0.63, { renown: 900 })];
  const kept = offer(RAIDER, fits);
  assert.deepEqual(kept.widened, []);
  assert.ok(!kept.targets.some((c) => c.bundle === "far"), "outside the Renown window, and not needed");
});

test("the Keeper window runs from two levels below the raider to three above (12.22, F44)", () => {
  const levels = [2, 3, 4, 5, 8, 9];
  const pool = levels.map((k) => candidate(`k${k}`, 0.62 + k / 1000, { keeperLevel: k }));
  const out = offer(RAIDER, pool, { size: 6 });
  assert.deepEqual(out.widened, [], "enough in the band: nothing widened");
  assert.deepEqual(out.targets.map((c) => c.keeperLevel).sort((a, b) => a - b), [3, 4, 5, 8],
                   "three below and four above are out; two below and three above are in");
});

test("echoes count only when fewer than three live candidates sit in the band (12.3, 12.22)", () => {
  const live = [candidate("a", 0.62), candidate("b", 0.63)];
  const echo = candidate("old", 0.64, { echo: true });
  const thin = offer(RAIDER, [...live, echo]);
  assert.equal(thin.echoes, true);
  assert.ok(thin.targets.some((c) => c.bundle === "old"));
  const full = offer(RAIDER, [...live, candidate("c", 0.64), echo]);
  assert.equal(full.echoes, false);
  assert.ok(!full.targets.some((c) => c.bundle === "old"));
});

test("robbing an echo takes nothing from its owner: no fee, no Renown, no stars (12.3)", () => {
  const t = twoPlayers(false);
  t.service.publish(t.defender.account, t.build.exampleIsland(true));      // the old snapshot is an echo
  const lease = t.service.lease(t.raider.account, t.bundle);
  assert.equal(lease.echo, true);
  const out = t.service.submit(t.raider.account, lease.token, play(t, lease, { plan: [] }));
  assert.equal(out.verdict.grade, "foiled");
  assert.equal(t.service.balance(t.defender.account).starlight, 0, "the foiled fee went to nobody");
  assert.deepEqual([out.renown, out.stars.defender], [{ raider: 0, defender: 0 }, 0]);
  // The raider is rated against the echo's island, which does not move (G30).
  const island = t.service.matchmaking.islandRating(t.defender.account, "heart");
  assert.ok(out.rating.raider > 0);
  assert.equal(out.rating.island, Math.round(island.rating), "the island's rating is as it was");
  assert.equal(island.games, 0, "and counts no game");
});

test("a new player cannot be raided for 72 hours, or until they raid a player themselves (12.3)", () => {
  const t = twoPlayers(true);
  const fresh = t.service.session("gc:newcomer").account;
  const { bundle } = t.service.publish(fresh, another(t, true, 2));
  refusal(() => t.service.lease(t.raider.account, bundle), "new_player_protected");
  assert.ok(!JSON.stringify(t.service.targetLists()).includes(fresh), "and on no target list");
  // Raiding lifts it.
  const lease = t.service.lease(fresh, t.bundle);
  t.service.submit(fresh, lease.token, play(t, lease, { plan: openPlan() }));
  assert.equal(t.service.lease(t.raider.account, bundle).bundle, bundle);
  // A seeded island is the game's own (§13.1), and no new player's.
  const seeded = t.service.session("gc:seeded").account;
  t.service.db.prepare("UPDATE accounts SET seeded = 1 WHERE id = ?").run(seeded);
  const stocked = t.service.publish(seeded, another(t, true, 4)).bundle;
  assert.equal(t.service.lease(t.raider.account, stocked).bundle, stocked);
  // So does time.
  const later = t.service.session("gc:patient").account;
  const own = t.service.publish(later, another(t, true, 3)).bundle;
  t.clock.now += 72 * HOUR;
  assert.equal(t.service.lease(t.raider.account, own).bundle, own);
});

test("only a raid on a player's current island lifts the protection: not a friend, a challenge, an echo or a seeded island (12.3)", () => {
  const t = twoPlayers(true);
  const f = t.service.friends;
  const fresh = t.service.session("gc:newcomer").account;
  const { bundle } = t.service.publish(fresh, another(t, true, 2));
  const heist = (lease, plan = openPlan()) => t.service.submit(fresh, lease.token, play(t, lease, { plan }));
  // A challenge link and a friendly heist are for fun (12.11, F48).
  const { challenge } = f.challenge(t.defender.account);
  heist(t.service.lease(fresh, t.bundle, null, { mode: "challenge", challenge }));
  f.accept(fresh, f.invite(t.defender.account).invite);
  heist(t.service.lease(fresh, t.bundle, null, { mode: "friendly" }));
  // An echo takes nothing from its owner.
  const moved = t.service.session("gc:moved").account;
  established(t, moved);
  const old = t.service.publish(moved, another(t, true, 5)).bundle;
  t.service.publish(moved, another(t, true, 6));
  heist(t.service.lease(fresh, old));
  // A seeded island is the game's own (13.1), foiled or not.
  const seeded = t.service.session("gc:seeded").account;
  t.service.db.prepare("UPDATE accounts SET seeded = 1 WHERE id = ?").run(seeded);
  heist(t.service.lease(fresh, t.service.publish(seeded, another(t, true, 4)).bundle), []);
  assert.equal(t.service.matchmaking.shielded(fresh), true);
  refusal(() => t.service.lease(t.raider.account, bundle), "new_player_protected");
});

test("a robbed player may Trace the raider once within 24 hours, with no entry fee (12.3)", () => {
  const t = twoPlayers(true);
  established(t, t.raider.account);
  const home = t.service.publish(t.raider.account, another(t, true, 2)).bundle;
  refusal(() => t.service.lease(t.defender.account, home, null, { trace: true }), "nothing_to_trace");
  const lease = t.service.lease(t.raider.account, t.bundle);
  t.service.submit(t.raider.account, lease.token, play(t, lease, { plan: openPlan() }));   // robbed
  const trace = t.service.lease(t.defender.account, home, null, { trace: true });
  assert.equal(trace.trace, true);
  const out = t.service.submit(t.defender.account, trace.token, play(t, trace, { plan: openPlan() }));
  assert.equal(out.fee, 0, "no entry fee");
  refusal(() => t.service.lease(t.defender.account, home, null, { trace: true }), "nothing_to_trace");
  // A later robbery opens one Trace more, for 24 hours only.
  t.clock.now += 25 * HOUR;
  const again = t.service.lease(t.raider.account, t.bundle);
  t.service.submit(t.raider.account, again.token, play(t, again, { plan: openPlan() }));
  t.clock.now += 25 * HOUR;
  refusal(() => t.service.lease(t.defender.account, home, null, { trace: true }), "nothing_to_trace");
});

test("a challenge, a friendly heist or an echo robbed nobody, and opens no Trace (12.3, 12.11)", () => {
  const t = twoPlayers(true);
  const f = t.service.friends;
  established(t, t.raider.account);
  const home = t.service.publish(t.raider.account, another(t, true, 2)).bundle;
  const heist = (lease) => t.service.submit(t.raider.account, lease.token, play(t, lease, { plan: openPlan() }));
  const traced = () => refusal(() => t.service.lease(t.defender.account, home, null, { trace: true }), "nothing_to_trace");
  const { challenge } = f.challenge(t.defender.account);
  assert.equal(heist(t.service.lease(t.raider.account, t.bundle, null, { mode: "challenge", challenge })).verdict.grade, "clean");
  traced();
  f.accept(t.raider.account, f.invite(t.defender.account).invite);
  assert.equal(heist(t.service.lease(t.raider.account, t.bundle, null, { mode: "friendly" })).verdict.grade, "clean");
  traced();
  t.service.publish(t.defender.account, another(t, true, 5));             // t.bundle is an echo now
  const echo = t.service.lease(t.raider.account, t.bundle);
  assert.equal(echo.echo, true);
  assert.equal(heist(echo).verdict.grade, "clean");
  traced();
});

test("a shielded new player's echoes are offered to nobody (12.3, G30)", () => {
  const t = twoPlayers(true);
  const fresh = t.service.session("gc:newcomer").account;
  const old = t.service.publish(fresh, another(t, true, 2)).bundle;
  t.service.publish(fresh, another(t, true, 3));                          // `old` is an echo now
  refusal(() => t.service.lease(t.raider.account, old), "new_player_protected");
  assert.ok(!t.service.matchmaking.candidates().some((c) => c.owner === fresh));
  t.clock.now += 72 * HOUR;
  assert.ok(t.service.matchmaking.candidates().some((c) => c.bundle === old && c.echo));
});

test("an island with no rating yet is rated from its prior, and so is the raider (12.22)", () => {
  const t = twoPlayers(true);
  const mm = t.service.matchmaking;
  t.service.db.prepare("DELETE FROM ratings").run();                   // an island published before ratings
  const lease = t.service.lease(t.raider.account, t.bundle);
  const out = t.service.submit(t.raider.account, lease.token, play(t, lease, { plan: openPlan() }));
  assert.notEqual(out.rating, null);
  assert.equal(mm.islandRating(t.defender.account, "heart").games, 1);
  assert.equal(mm.raiderRating(t.raider.account).games, 1);
});

test("the list is guaranteed only when its middle entry sits in the band (12.22)", () => {
  const [lo, hi] = successBand(1);
  for (const ps of [[0.62, 0.45, 0.4], [0.9, 0.85, 0.6]]) {
    const out = offer(RAIDER, ps.map((p, i) => candidate(`c${i}`, p)));
    const mid = out.targets[Math.floor(out.targets.length / 2)].predicted;
    assert.ok(mid < lo || mid > hi, "the middle entry is out of band");
    assert.equal(out.guaranteed, false);
  }
  assert.equal(offer(RAIDER, [candidate("a", 0.62)]).guaranteed, true);
});

test("a bundle the raider holds is not offered to them, and equal entries sort one way (12.22)", () => {
  const t = twoPlayers(true);
  const mm = t.service.matchmaking;
  established(t, t.raider.account);
  assert.equal(t.service.publish(t.raider.account, t.build.exampleIsland(true)).bundle, t.bundle);
  const out = offer(mm.raider(t.raider.account), mm.candidates());
  assert.ok(!out.targets.some((c) => c.bundle === t.bundle), "lease() refuses it as own_island");
  refusal(() => t.service.lease(t.raider.account, t.bundle, t.defender.account), "own_island");
  const p = candidate("x", 0.62, { owner: "p" });
  const q = candidate("x", 0.62, { owner: "q" });
  const order = (pool) => offer(RAIDER, pool).targets.map((c) => c.owner);
  assert.deepEqual(order([p, q]), order([q, p]));
});

test("the offer over HTTP: the caller's list, its middle in the band, and ratings on the target lists", async () => {
  const t = twoPlayers(false);
  const call = (method, path, token) => t.handle(new Request(`https://edge.example${path}`, {
    method, headers: { authorization: `Bearer ${token}` } }));
  // The example island runs Haste, a chapter 2 law: open from Keeper level 6
  // (§7.6).
  t.service.db.prepare("UPDATE accounts SET keeper_level = 6 WHERE id = ?").run(t.raider.account);
  const res = await call("GET", "/v1/offer", t.raider.token);
  assert.equal(res.status, 200);
  const body = await res.json();
  assert.deepEqual(body.targets.map((c) => c.bundle), [t.bundle]);
  const lists = t.service.targetLists();
  const list = JSON.parse(new TextDecoder().decode(t.service.bundle(Object.values(lists)[0])));
  assert.equal("rating" in list.candidates[0] || "deviation" in list.candidates[0], false, "12.15: no raw rating on a list (SR-09)");
  assert.equal(list.candidates[0].origin, "authored");
});

test("a Trace asked for twice is handed the Trace already held, however many robberies it could answer (24.13)", () => {
  const t = twoPlayers(true);
  established(t, t.raider.account);
  const home = t.service.publish(t.raider.account, another(t, true, 2)).bundle;
  for (let i = 0; i < 2; i++) {
    const lease = t.service.lease(t.raider.account, t.bundle);
    t.service.submit(t.raider.account, lease.token, play(t, lease, { plan: openPlan() }));   // robbed, twice
    t.clock.now += 60 * 60 * 1000;
  }
  const first = t.service.lease(t.defender.account, home, null, { trace: true });
  const again = t.service.lease(t.defender.account, home, null, { trace: true });
  assert.equal(again.token, first.token, "§24.13: the same heist asked for twice");
});

test("matchmaking shows only universes running laws from the raider's open chapters, whatever else it widens (7.6)", () => {
  const t = twoPlayers(false);
  const mm = t.service.matchmaking;
  const [island] = mm.candidates();
  assert.equal(island.chapter, 2, "Brittle stone is chapter 1's, Haste chapter 2's");
  assert.deepEqual(offer(mm.raider(t.raider.account), mm.candidates()).targets, [],
                   "a new Keeper has chapter 1 alone, and no widening reaches past it");
  t.service.db.prepare("UPDATE accounts SET keeper_level = 6 WHERE id = ?").run(t.raider.account);
  assert.equal(mm.raider(t.raider.account).chapter, 2);
  assert.deepEqual(offer(mm.raider(t.raider.account), mm.candidates()).targets.map((c) => c.bundle), [t.bundle]);
  // The pure list: no target from a closed chapter, on any band or pool.
  const raider = { account: "r", rating: 1500, deviation: 50, renown: 0, keeperLevel: 1, chapter: 1, recent: 0.6 };
  const candidates = Array.from({ length: 12 }, (_, i) => ({
    bundle: `b${i}`, owner: `o${i}`, realmLevel: 1, keeperLevel: 1, renown: 0, rating: 1400 + 20 * i,
    deviation: 50, echo: i % 3 === 0, origin: i % 4 === 0 ? "generated" : "authored", chapter: 1 + (i % 2) }));
  for (const size of [1, 3, 5]) {
    const { targets } = offer(raider, candidates, { size });
    assert.ok(targets.length > 0 && targets.every((c) => c.chapter === 1), JSON.stringify(targets));
  }
});
