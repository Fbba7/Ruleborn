// The week's era (§18.3), against the real simulation build.

import assert from "node:assert/strict";
import { test } from "node:test";

import { ERAS } from "../src/eras.mjs";
import { Refused, clockTicks } from "../src/service.mjs";
import { readHeader } from "../src/sim.mjs";
import { Workshop } from "../src/workshop.mjs";
import { T0, openPlan, play, twoPlayers } from "./setup.mjs";

const refusal = (fn, reason) => assert.throws(fn, (e) => e instanceof Refused && e.reason === reason);
const WEEK = 7 * 24 * 60 * 60 * 1000;

test("each week has one era, the eight in turn from the first season's first day (18.3)", () => {
  const t = twoPlayers(true);
  assert.deepEqual(ERAS.map((e) => e.id), ["heavy_stars", "the_long_night", "high_tide", "wildgrowth",
                                           "echoing_skies", "static_storm", "glass_moon", "quiet_week"]);
  const at = (weeks) => t.service.era(T0 + weeks * WEEK + 1);
  assert.deepEqual([at(0).id, at(0).week, at(0).endsAt], ["heavy_stars", 1, T0 + WEEK]);
  assert.equal(at(1).id, "the_long_night");
  assert.equal(at(7).id, "quiet_week");
  assert.equal(at(8).id, "heavy_stars", "every era once in each eight-week season (18.1)");
});

test("every heist names the week's era, and Quiet Week's clock is 30 seconds longer (18.3)", () => {
  const t = twoPlayers(true);
  const first = t.service.lease(t.raider.account, t.bundle);
  assert.deepEqual([first.era, first.ticks], ["heavy_stars", clockTicks(0)]);
  t.clock.now = T0 + 7 * WEEK + 1;
  const quiet = t.service.lease(t.raider.account, t.bundle);
  assert.deepEqual([quiet.era, quiet.ticks], ["quiet_week", clockTicks(0) + 30 * 30]);
  const out = t.service.submit(t.raider.account, quiet.token, play(t, quiet, { plan: openPlan() }));
  assert.equal(out.validated, true, "a 180-second heist re-simulates");
});

test("a heist is re-simulated in its era, and a replay that claims another pays nothing (18.3)", () => {
  const t = twoPlayers(true);
  t.clock.now = T0 + WEEK + 1;                          // The Long Night
  const lease = t.service.lease(t.raider.account, t.bundle);
  const replay = play(t, lease, { plan: openPlan() });
  assert.equal(readHeader(replay).era, ERAS.find((e) => e.id === "the_long_night").wire);
  // The same heist, recorded as if in no era: not what the lease allowed.
  const island = t.service.bundle(lease.bundle);
  const kinder = t.build.record(island, { seed: BigInt(lease.seed), ticks: lease.ticks, crew: 3,
                                          commands: openPlan() });
  const refused = t.service.submit(t.raider.account, lease.token, kinder);
  assert.deepEqual([refused.validated, refused.reason], [false, "wrong_era"]);
  t.clock.now += 25 * 60 * 60 * 1000;
  const again = t.service.lease(t.raider.account, t.bundle);
  const ok = t.service.submit(t.raider.account, again.token, play(t, again, { plan: openPlan() }));
  assert.equal(ok.validated, true);
});

test("the Workshop stays out of the eras, so an island cleared once is solvable every week (18.6)", () => {
  const t = twoPlayers(true);
  const w = new Workshop(t.service);
  const glass = ERAS.find((e) => e.id === "glass_moon").wire;
  const inEra = t.build.record(t.island, { seed: 7n, ticks: clockTicks(0), crew: 3, commands: openPlan(), era: glass });
  refusal(() => w.publish(t.defender.account, t.island, inEra, { adjective: 0, noun: 0 }), "not_cleared");
  const plain = t.build.record(t.island, { seed: 7n, ticks: clockTicks(0), crew: 3, commands: openPlan() });
  assert.ok(w.publish(t.defender.account, t.island, plain, { adjective: 0, noun: 0 }).id);
});

test("the era over HTTP", async () => {
  const t = twoPlayers(true);
  t.clock.now = T0 + 6 * WEEK + 1;
  const { token } = t.service.session("gc:raider");        // a session of this week
  const res = await t.handle(new Request("https://edge.example/v1/era", {
    headers: { authorization: `Bearer ${token}` } }));
  const era = await res.json();
  assert.deepEqual([era.era, era.name, era.week], ["glass_moon", "Glass Moon", 7]);
  assert.equal(era.rule, "Walls everywhere are see-through");
});
