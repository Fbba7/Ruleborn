// FX2-10-curated-woven-law, SIM-12's "Left for the lead"
// (docs/security/audit-2026-11/sim.md): SR-16, "a realm plays what its owner
// wove". `Island::curated` can still answer a layout without a law the realm
// wove: given more laws than it has pylon spots, given a law id `weave` does
// not know, or when every one of its 64 draws fails and it answers the last,
// "problems and all, for the server to refuse by name". The server's
// problems() named a law on the island that was not woven (law_not_woven),
// never a woven law the island lacks, so such a layout was published as it
// was. It now names woven_law_missing, and publish refuses it by name.

import assert from "node:assert/strict";
import { test } from "node:test";

import { layoutSeed } from "../src/curation.mjs";
import { lawsOf } from "../src/telemetry.mjs";
import { server } from "./setup.mjs";

const MINUTE = 60_000;

/** A player with Slow rivers woven and working in the Heart, as
 *  curation.test.mjs's curator. */
function curator() {
  const t = server({ strictUniverse: true });
  const { account: me } = t.service.session("gc:curator");
  t.service.codex.show(me);
  t.service.book(me, "aether", 100_000, "a test's grant");
  t.service.weaving.weave(me, { realm: "heart", slot: 1, law: "slow_rivers" });
  t.clock.now += 10 * MINUTE;
  return { t, me };
}

/** A Heart slot woven and working, written as weaving.mjs writes one. */
const woven = (t, me, slot, law) => t.service.db.prepare(
  "INSERT INTO law_slots (owner, realm, slot, law, tier, ready_at, rests_until) VALUES (?, 'heart', ?, ?, 1, 0, 0)")
  .run(me, slot, law);

const island = (t, me) => t.service.db.prepare("SELECT bundle FROM islands WHERE owner = ? AND realm = 'heart'")
  .get(me)?.bundle ?? null;

const missing = (e) => e.reason === "island_not_publishable" && e.detail.problems.includes("woven_law_missing");

test("SIM-12: a curated layout given more woven laws than it has pylon spots is refused as woven_law_missing, not published without them (SR-16, 13.3)", () => {
  const { t, me } = curator();
  // The Heart has two law slots (§5.6); a realm whose rows hold four reach
  // the generator as four, and `zip` stops at the pylon spots it drew.
  woven(t, me, 2, "bloom");
  woven(t, me, 3, "bounce");
  woven(t, me, 4, "haste");
  assert.equal(t.service.weaving.working(me).heart.length, 4, "four laws woven and working");
  assert.throws(() => t.service.curation.layout(me, "heart", layoutSeed(me, "heart", 0)), missing);
  assert.equal(island(t, me), null, "nothing is published");
});

test("SIM-12: a curated layout given a woven law id the simulation does not know is refused as woven_law_missing, not published without it (SR-16, 13.3)", () => {
  const { t, me } = curator();
  woven(t, me, 2, "no_such_law");
  assert.throws(() => t.service.curation.layout(me, "heart", layoutSeed(me, "heart", 0)), missing);
  assert.equal(island(t, me), null, "nothing is published");
});

test("SIM-12: the generator's last draw, which keeps the realm's buildings and loses a woven law, is refused as woven_law_missing (SR-16, 13.3)", () => {
  const { t, me } = curator();
  // After 64 failed draws `curated` answers the last, "for the server to
  // refuse by name": the layout as drawn, the law lifted. The server cannot
  // place the realm's buildings so that every draw fails (no seed and
  // spire position among 19,200 tried does), so it is fed that answer.
  // The build is shared by the test servers, so the stub is taken off after.
  const build = t.service.builds.current;
  const curated = build.curated;
  build.curated = (seed, realmLevel, vaultLevel, buildings) =>
    curated.call(build, seed, realmLevel, vaultLevel, buildings, []);
  try {
    const seed = layoutSeed(me, "heart", 0);
    assert.deepEqual(lawsOf(build.curated(seed, 3, 1, [], ["slow_rivers"])), [], "the answer has no law");
    assert.throws(() => t.service.curation.layout(me, "heart", seed), missing);
    assert.equal(island(t, me), null, "nothing is published");
  } finally {
    build.curated = curated;
  }
});

test("SIM-12: a curated layout with every woven law is still published (SR-16, 13.3)", () => {
  const { t, me } = curator();
  const out = t.service.curation.layout(me, "heart", layoutSeed(me, "heart", 0));
  assert.deepEqual(lawsOf(t.service.bundle(out.bundle)), ["slow_rivers"]);
  assert.equal(island(t, me), out.bundle);
});

test("SR-16: a hand-built island without a law its realm wove is named woven_law_missing, and with every woven law it is not (24.8)", () => {
  const t = server({ strictUniverse: true });
  const owner = t.service.session("gc:owner").account;
  const bytes = t.build.exampleIsland(false);
  assert.deepEqual(lawsOf(bytes), ["brittle_stone", "haste"], "the example island runs two laws");
  ["brittle_stone", "haste", "bloom"].forEach((law, n) => woven(t, owner, n + 1, law));
  const problems = t.service.universe.problems(owner, "heart", bytes[4], bytes[5], t.build.buildings(bytes), lawsOf(bytes));
  assert.ok(problems.includes("woven_law_missing"), `Bloom is woven and not on the island: ${problems}`);
  assert.ok(!problems.includes("law_not_woven"), "every law on it is woven");
  t.service.db.prepare("DELETE FROM law_slots WHERE owner = ? AND law = 'bloom'").run(owner);
  assert.ok(!t.service.universe.problems(owner, "heart", bytes[4], bytes[5], t.build.buildings(bytes), lawsOf(bytes))
    .includes("woven_law_missing"), "with every woven law on it, none is missing");
});
