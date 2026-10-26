// Security review findings on the simulation as the server runs it
// (docs/security/review.md).

import assert from "node:assert/strict";
import { test } from "node:test";

import { Build } from "../src/sim.mjs";
import { WASM, openPlan, play, twoPlayers } from "./setup.mjs";

// SR-07: the simulation is built to abort on a panic, and a trap left the
// instance with its buffer's lock held: every later call trapped too, so
// one input that reached any panic, in this build or an old one a replay
// can name, stopped every heist and publish on its rules version until a
// restart. A crew of none is such an input to a call the server keeps for
// its tests (rng `below(0)`).
test("SR-07: a trap in the simulation costs only its own call", () => {
  const build = Build.load(WASM);
  const t = twoPlayers(true);
  const island = build.exampleIsland(true);
  assert.throws(() => build.recordDrawn(island, { seed: 1n, ticks: 4500, crew: 0 }), WebAssembly.RuntimeError);
  assert.equal(build.island(island).digest.length, 64, "an island still reads");
  const lease = t.service.lease(t.raider.account, t.bundle);
  const replay = play(t, lease, { plan: openPlan() });
  assert.equal(build.verify(replay, t.service.bundle(t.bundle)).status, "verified", "and a heist still verifies");
});
