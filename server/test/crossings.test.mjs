// §5.4's heist across a universe (crossings.mjs, sim/src/universe.rs).

import assert from "node:assert/strict";
import { test } from "node:test";

import { decodeUniverse, encodeUniverse } from "../src/crossings.mjs";
import { ERAS } from "../src/eras.mjs";
import { clockTicks } from "../src/service.mjs";
import { established, server } from "./setup.mjs";

const refused = (fn, reason) => assert.throws(fn, (e) => e.reason === reason, reason);

/** A defender with the example island on the Heart and generated islands on
 *  outer realms 1 and 2, the second joined only to the first. */
function universeOfTwo() {
  const t = server();
  const defender = t.service.session("gc:defender").account;
  established(t, defender);
  const heart = t.build.exampleIsland(false);
  const { bundle } = t.service.publish(defender, heart);
  const outer1 = t.build.generate(2, 1);
  const outer2 = t.build.generate(3, 1);
  t.service.publish(defender, outer1, "outer-1");
  t.service.publish(defender, outer2, "outer-2");
  // Outer realm 2 hangs off outer realm 1, two links from the Heart.
  t.service.links.ensure(defender, t.clock.now);
  t.service.db.prepare("UPDATE links SET b = 'outer-1' WHERE owner = ? AND a = 'outer-2'").run(defender);
  let raiders = 0;
  const raider = () => t.service.session(`gc:raider${++raiders}`).account;
  return { t, defender, heart, outer1, outer2, bundle, raider };
}

/** A device's heist across the lease's universe: the reference crew,
 *  landing where asked, in the lease's era. */
function across(t, lease, opts = {}) {
  const u = lease.universe;
  const bytes = t.service.store.get(u.digest);
  const islands = u.realms.map((r) => t.service.store.get(r.bundle));
  const era = ERAS.find((e) => e.id === lease.era)?.wire ?? 0;
  return t.build.competentUniverse(bytes, islands, { seed: BigInt(lease.seed), era, ...opts });
}

test("a universe bundle is its realms by code and island and its links, as the simulation reads it (5.3, D71)", () => {
  const realms = [{ realm: "heart", bundle: "aa".repeat(32) }, { realm: "outer-3", bundle: "bb".repeat(32) }];
  const bytes = encodeUniverse(realms, [{ kind: "chute", a: 1, b: 0 }], { flicker: 2, faults: [1] });
  assert.equal(Buffer.from(bytes.subarray(0, 4)).toString(), "RBU1");
  assert.deepEqual(decodeUniverse(bytes),
                   { realms, links: [{ kind: "chute", a: "outer-3", b: "heart" }], flicker: 2, faults: ["outer-3"] });
  assert.equal(decodeUniverse(bytes.subarray(0, bytes.length - 1)), null);
});

test("a raid leased across the universe names it, its realms' islands and each landing realm's clock; the Heart alone unless asked (5.4, D71)", () => {
  const { t, bundle, raider } = universeOfTwo();
  const extra = ERAS.find((e) => e.id === t.service.lease(raider(), bundle).era)?.seconds * 30 || 0;
  const alone = t.service.lease(raider(), bundle);
  assert.equal(alone.universe, null);
  assert.equal(alone.ticks, clockTicks(0) + extra);
  const me = raider();
  const lease = t.service.lease(me, bundle, null, { universe: true });
  const u = lease.universe;
  assert.equal(lease.bundle, bundle, "the Heart's island is the target");
  assert.deepEqual(u.realms.map((r) => [r.realm, r.links, r.ticks]), [
    ["heart", 0, null],
    ["outer-1", 1, clockTicks(1) + extra],
    ["outer-2", 2, clockTicks(2) + extra],
  ], "150 seconds and 15 a link; no landing on the Heart");
  assert.equal(clockTicks(1), 165 * 30);
  assert.deepEqual(u.links.map((l) => [l.kind, l.a, l.b]).sort(),
                   [["stone_bridge", "outer-1", "heart"], ["stone_bridge", "outer-2", "outer-1"]]);
  assert.ok(t.service.store.get(u.digest), "fetched by its hash, as an island is");
  // §24.13: the same raid asked for again is the same lease, and the Heart
  // alone is not handed back for it.
  assert.equal(t.service.lease(me, bundle, null, { universe: true }).token, lease.token);
  refused(() => t.service.lease(me, bundle), "lease_held_in_another_mode");
  // An outer realm's island leased is raided alone: the universe is the
  // Heart's.
  const outer = t.service.db.prepare("SELECT bundle FROM islands WHERE realm = 'outer-1'").get().bundle;
  assert.equal(t.service.lease(raider(), outer, null, { universe: true }).universe, null);
  // A defender with no outer island has no universe to cross.
  const lone = server();
  const d = lone.service.session("gc:lone").account;
  established(lone, d);
  const b = lone.service.publish(d, lone.build.exampleIsland(false)).bundle;
  assert.equal(lone.service.lease(lone.service.session("gc:r").account, b, null, { universe: true }).universe, null);
});

test("a heist across the universe is verified on its realms' islands, on the landing realm's clock, and settles as a raid on the Heart (5.4, 24.12)", () => {
  const { t, bundle, raider } = universeOfTwo();
  const me = raider();
  const lease = t.service.lease(me, bundle, null, { universe: true });
  const out = t.service.submit(me, lease.token, across(t, lease, { realm: 1 }));
  assert.equal(out.validated, true, JSON.stringify(out));
  assert.deepEqual(out.crossing, { landed: "outer-1", fault: false, realms: ["outer-1", "heart"] });
  assert.ok(["clean", "loud", "partial", "foiled"].includes(out.verdict.grade));
  // Landed two links out, on that realm's clock.
  const far = raider();
  const second = t.service.lease(far, bundle, null, { universe: true });
  const deep = t.service.submit(far, second.token, across(t, second, { realm: 2 }));
  assert.equal(deep.validated, true, JSON.stringify(deep));
  assert.deepEqual(deep.crossing.realms.slice(0, 2), ["outer-2", "outer-1"]);
});

test("a heist across the universe is refused on another realm's clock, on the Heart's, or as the Heart alone (5.4)", () => {
  const { t, bundle, raider } = universeOfTwo();
  const tries = [
    // Landed one link out on the clock for two: a clock the lease allows,
    // but not the landing's, found once the simulation says where it landed.
    [(l) => across(t, l, { realm: 1, ticks: l.universe.realms[2].ticks }), "wrong_clock"],
    // The Heart's own clock is no landing realm's.
    [(l) => across(t, l, { realm: 1, ticks: l.ticks }), "wrong_clock"],
    // A one-island heist on the Heart names the island, not the universe.
    [(l) => t.build.recordDrawn(t.service.store.get(bundle), { seed: BigInt(l.seed), ticks: l.ticks, crew: 3,
                                                                era: ERAS.find((e) => e.id === l.era)?.wire ?? 0 }),
     "wrong_island"],
  ];
  for (const [replay, reason] of tries) {
    const me = raider();
    const lease = t.service.lease(me, bundle, null, { universe: true });
    const out = t.service.submit(me, lease.token, replay(lease));
    assert.deepEqual([out.validated, out.reason], [false, reason]);
  }
});

test("a universe is the defender's open links between realms with islands: a closed Rift crosses nothing (5.3)", () => {
  const { t, defender, bundle, raider } = universeOfTwo();
  // Outer realm 2's way is a Rift its owner cannot pay for.
  t.service.db.prepare("UPDATE links SET kind = 'rift', open = 0 WHERE owner = ? AND a = 'outer-2'").run(defender);
  const lease = t.service.lease(raider(), bundle, null, { universe: true });
  assert.deepEqual(lease.universe.realms.map((r) => [r.realm, r.ticks === null]),
                   [["heart", true], ["outer-1", false], ["outer-2", true]], "no route from outer realm 2");
  assert.equal(lease.universe.links.length, 1);
});

test("an overloaded universe's lease carries its faults and its laws' flicker, and a crew may enter at a fault straight to the Heart on that realm's clock (5.4, 5.5, G88)", () => {
  const { t, bundle, raider } = universeOfTwo();
  // Cracking, two faults (§5.5): from the deepest outer realms.
  t.service.weaving.stability = () => ({ strain: 1.12, band: 5 });
  const me = raider();
  const lease = t.service.lease(me, bundle, null, { universe: true });
  assert.equal(lease.universe.flicker, 1, "Cracking's flicker");
  assert.deepEqual(lease.universe.realms.map((r) => [r.realm, r.fault]),
                   [["heart", false], ["outer-1", true], ["outer-2", true]]);
  const out = t.service.submit(me, lease.token, across(t, lease, { realm: 8 | 2 }));
  assert.equal(out.validated, true, JSON.stringify(out));
  assert.deepEqual(out.crossing, { landed: "outer-2", fault: true, realms: ["heart"] },
                   "through the crack, on outer realm 2's clock of two links");
  // Breaking flickers twice as often; a universe under 100% has neither.
  t.service.weaving.stability = () => ({ strain: 1.3, band: 6 });
  assert.equal(t.service.lease(raider(), bundle, null, { universe: true }).universe.flicker, 2);
  t.service.weaving.stability = () => ({ strain: 0.5, band: 1 });
  const calm = t.service.lease(raider(), bundle, null, { universe: true }).universe;
  assert.deepEqual([calm.flicker, calm.realms.some((r) => r.fault)], [0, false]);
});

test("a universe with no realm a crew can land on is the Heart alone, and a held universe lease is handed back when asked for again whatever has changed (5.4, 24.13)", () => {
  const { t, defender, bundle, raider } = universeOfTwo();
  const me = raider();
  const lease = t.service.lease(me, bundle, null, { universe: true });
  // The defender republishes their Heart: the leased island is an echo now,
  // and the held lease is still the one handed back.
  t.service.publish(defender, t.build.exampleIsland(true));
  assert.equal(t.service.lease(me, bundle, null, { universe: true }).token, lease.token);
  refused(() => t.service.lease(me, bundle), "lease_held_in_another_mode");
  // Outer realm 2 reaches the Heart only through outer realm 1: with no
  // island on outer realm 1 there is nowhere to land, and no fault from it.
  const heart = t.service.db.prepare("SELECT bundle FROM islands WHERE owner = ? AND realm = 'heart'").get(defender).bundle;
  t.service.db.prepare("DELETE FROM islands WHERE owner = ? AND realm = 'outer-1'").run(defender);
  t.service.weaving.stability = () => ({ strain: 1.3, band: 6 });
  assert.equal(t.service.lease(raider(), heart, null, { universe: true }).universe, null);
});

test("an Observatory card says whether a raid would cross the target's universe and its clock, shortest and longest by the realm landed on (12.5, 5.4)", () => {
  const { t, bundle, raider } = universeOfTwo();
  const me = raider();
  t.service.db.prepare("UPDATE accounts SET keeper_level = 6 WHERE id = ?").run(me);
  const card = t.service.observatory.view(me).targets.find((c) => c.bundle === bundle);
  assert.deepEqual([card.across, card.clock, card.clock_longest], [true, 165, 180]);
  const outer = t.service.db.prepare("SELECT bundle FROM islands WHERE realm = 'outer-1'").get().bundle;
  const alone = t.service.observatory.view(me).targets.find((c) => c.bundle === outer);
  if (alone) assert.deepEqual([alone.across, alone.clock, alone.clock_longest], [false, 150, 150]);
});
