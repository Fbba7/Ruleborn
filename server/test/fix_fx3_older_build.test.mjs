// FX3-3-clock-report: the fail-first test for RB-19 of
// docs/security/bug-report-2026-11.md, reproducing the entry's Input.

import assert from "node:assert/strict";
import { readFileSync } from "node:fs";
import { test } from "node:test";

import { Build, Builds } from "../src/sim.mjs";
import { WASM } from "./setup.mjs";

/** This checkout's build with one export renamed, as an older rules version
 *  that never had it: the name keeps its length, so the module stays valid. */
function without(name) {
  const bytes = Buffer.from(readFileSync(WASM));
  const from = Buffer.from(name);
  const to = Buffer.from(name.slice(0, -1) + "_");
  let n = 0;
  for (let at = bytes.indexOf(from); at >= 0; at = bytes.indexOf(from, at + 1)) {
    to.copy(bytes, at);
    n++;
  }
  assert.ok(n > 0, `${name} is in the build`);
  return bytes;
}

test("RB-19: a pinned build without rb_building_kinds still loads", () => {
  const bytes = without("rb_building_kinds");
  const build = new Build(bytes);
  assert.equal(typeof build.x.rb_building_kinds, "undefined");
  assert.equal(build.rulesVersion, new Build(readFileSync(WASM)).rulesVersion);
  // Startup's Builds holds it beside the current build.
  assert.equal(new Builds([build]).get(build.rulesVersion), build);
});
