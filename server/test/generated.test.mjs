// §12.22's generated targets: the game's own islands, made by the simulation
// from each day's seed, offered after echoes and before any filter is widened
// (generator.mjs, D66, TD.16). Against the real simulation build.

import assert from "node:assert/strict";
import { test } from "node:test";

import { GENERATOR, REALM_OF_LEVEL, seedFor } from "../src/generator.mjs";
import { ratingFor } from "../src/glicko.mjs";
import { offer, prior } from "../src/matchmaking.mjs";
import { play, server } from "./setup.mjs";

const DAY = 24 * 60 * 60 * 1000;

test("each day the generator publishes one island a realm level from that day's seed, the same on every server (12.22)", () => {
  const t = server();
  const first = t.service.generator.stock();
  assert.deepEqual(Object.keys(first), ["1", "2", "3", "4", "5"]);
  const day = Math.floor(t.clock.now / DAY);
  for (const [level, realm] of Object.entries(REALM_OF_LEVEL)) {
    const island = t.service.db.prepare("SELECT bundle FROM islands WHERE owner = ? AND realm = ?").get(GENERATOR, realm);
    assert.equal(island.bundle, first[level]);
    const bytes = t.build.generate(seedFor(day, Number(level)), Number(level));
    assert.equal(bytes[4], Number(level), "its realm level");
    assert.deepEqual(t.build.island(bytes).problems, [], "every one publishable");
  }
  assert.equal(t.service.db.prepare("SELECT seeded FROM accounts WHERE id = ?").get(GENERATOR).seeded, 1,
               "the game's own, as §13.1's designed islands are");
  assert.deepEqual(t.service.generator.stock(), first, "the same day: the same five");
  // Another server makes the same five.
  assert.deepEqual(server().service.generator.stock(), first);
  t.clock.now += DAY;
  const next = t.service.generator.stock();
  assert.ok(Object.keys(next).every((l) => next[l] !== first[l]), "a new day, five new islands");
  const candidates = t.service.matchmaking.candidates();
  const generated = candidates.filter((c) => c.owner === GENERATOR);
  assert.equal(generated.length, 5);
  assert.ok(generated.every((c) => c.origin === "generated" && !c.echo), "yesterday's are no echoes");
  // Each realm's rating starts at the generated band's prior.
  const r = t.service.matchmaking.islandRating(GENERATOR, "outer-1");
  assert.equal(Math.round(r.rating), Math.round(prior(1, "generated").rating));
});

/** A candidate a raider at 1500 beats with probability `p`. */
function candidate(id, p, extra = {}) {
  return { bundle: id, owner: `owner-${id}`, realm: "heart", realmLevel: 1, keeperLevel: 5, renown: 100,
           rating: ratingFor(p), deviation: 0, origin: "authored", echo: false, ...extra };
}
const RAIDER = { account: "me", rating: 1500, deviation: 0, renown: 100, keeperLevel: 5, recent: 0.625 };

test("a thin list reaches for the game's generated islands after echoes and before widening any filter (12.22)", () => {
  const generated = [candidate("g1", 0.62, { origin: "generated", owner: GENERATOR, realm: "outer-1" }),
                     candidate("g2", 0.6, { origin: "generated", owner: GENERATOR, realm: "outer-2" }),
                     candidate("g3", 0.66, { origin: "generated", owner: GENERATOR, realm: "heart" })];
  const thin = offer(RAIDER, [candidate("a", 0.63), ...generated]);
  assert.equal(thin.echoes, true, "echoes first");
  assert.equal(thin.generated, true, "then the generated");
  assert.deepEqual(thin.widened, [], "and no filter widened");
  assert.ok(thin.targets.some((c) => c.origin === "generated") && thin.guaranteed);
  const plenty = offer(RAIDER, [candidate("a", 0.63), candidate("b", 0.6), candidate("c", 0.66), ...generated]);
  assert.equal(plenty.generated, false, "a full band of players' islands needs none");
  assert.ok(plenty.targets.every((c) => c.origin === "authored"));
});

test("a generated island is raided like any target, and its defence moves no player's Renown (12.22, G30)", () => {
  const t = server();
  const raider = t.service.session("gc:raider");
  const bundles = t.service.generator.stock();
  const lease = t.service.lease(raider.account, bundles[1]);
  assert.equal(lease.defender ?? GENERATOR, GENERATOR);
  const out = t.service.submit(raider.account, lease.token, play(t, lease, { plan: [] }));
  assert.equal(out.validated, true);
  assert.equal(out.verdict.grade, "foiled");
  const offered = t.service.matchmaking.candidates().filter((c) => c.origin === "generated");
  assert.equal(offered.length, 5);
});
