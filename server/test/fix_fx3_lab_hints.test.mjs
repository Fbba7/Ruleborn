// FX3-4-lab-replay: the fail-first tests for RB-51 and RB-52 of
// docs/security/bug-report-2026-11.md, each reproducing the entry's Input.

import assert from "node:assert/strict";
import { test } from "node:test";

import { LAUNCH_RESONANCES } from "../src/lab.mjs";
import { server } from "./setup.mjs";

const MINUTE = 60_000;

function withLab() {
  const t = server({ strictUniverse: true });
  const me = t.service.session("gc:lab-hints").account;
  t.service.db.prepare("UPDATE accounts SET keeper_level = 40 WHERE id = ?").run(me);
  t.service.book(me, "starlight", 5_000_000, "a test's grant");
  t.service.book(me, "aether", 10_000, "a test's grant");
  t.service.codex.show(me);
  t.service.universe.build(me, { realm: "heart", kind: "resonance_lab", n: 1, to: 1 });
  return { t, me, lab: t.service.lab };
}

test("RB-51: crossing an island hints every chord its laws complete, not only the first of each three (8.6, 8.8)", () => {
  const { t, me, lab } = withLab();
  // Bounce (Flow, Echo), Frictionless (Flow, Spark) and Honeycomb (Weight,
  // Hush) complete Ghost tide, Clockwork and Wild hunt.
  lab.crossed(me, ["bounce", "frictionless", "honeycomb"], t.clock.now);
  const hinted = lab.show(me).hinted;
  for (const chord of ["ghost_tide", "clockwork", "wild_hunt"]) {
    assert.ok(hinted.includes(chord), `${chord} hinted: ${JSON.stringify(hinted)}`);
  }
});

test("RB-52: the Lab's hints after empty experiments name only resonances that can be found at launch (8.6)", () => {
  const { t, me, lab } = withLab();
  const launch = new Set(LAUNCH_RESONANCES.map((r) => r.id));
  for (let i = 0; i < 5; i++) {
    lab.start(me, { chamber: 1, laws: ["half_gravity", "slow_rivers"] });
    t.clock.now += 8 * 60 * MINUTE;
    assert.equal(lab.show(me).chambers[0].result.found, null, "an empty experiment");
  }
  const hinted = lab.show(me).hinted;
  assert.ok(hinted.length > 0, "the empties hinted");
  for (const id of hinted) assert.ok(launch.has(id), `${id} can be found at launch: ${JSON.stringify(hinted)}`);
});
