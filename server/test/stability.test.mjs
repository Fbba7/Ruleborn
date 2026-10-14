// TD.14: §5.5's stability priced once, in the simulation, and the server's
// prices read from it through the WebAssembly.

import assert from "node:assert/strict";
import { readFileSync } from "node:fs";
import { test } from "node:test";

import { simulation } from "./setup.mjs";

const cases = JSON.parse(readFileSync(new URL("../../sim/stability_cases.json", import.meta.url), "utf8"));

test("the server's prices equal the simulation's, to the millionth of a point, for every launch law alone, crowned, in each era and in every pair (TD.14)", () => {
  const build = simulation();
  assert.deepEqual(build.ids(0), cases.laws, "the same laws in the same rows");
  assert.equal(cases.cases.length, 372);
  const wrong = [];
  for (const c of cases.cases) {
    const p = build.priced(Uint8Array.from(c.wire));
    const costs = p.lines.map((l) => l.micro);
    if (costs.length !== c.costs.length || costs.some((v, i) => v !== c.costs[i]) || p.micro.total !== c.total
        || p.band !== c.band) wrong.push(`${c.wire}: ${costs} ${p.micro.total} ${p.band}`);
  }
  assert.deepEqual(wrong, []);
});

test("§8.5's worked example, through the server's binding: 27.44 silent at 215, the chord sounding at 217 (5.5, 8.5)", () => {
  const build = simulation();
  const laws = [{ law: "slow_rivers", tier: 1, realm: 0 }, { law: "thorns", tier: 1, realm: 0 },
                { law: "bloom", tier: 1, realm: "crown" }];
  const silent = build.stability({ spire: 5, anchors: [5, 5, 4, 4, 3], schools: [null], laws });
  assert.equal(silent.capacity, 215);
  assert.deepEqual(silent.chords, []);
  assert.equal(silent.micro.total, 27_438_000);
  assert.deepEqual(silent.lines.map((l) => l.micro), [6_800_000, 8_670_000, 11_968_000]);
  assert.deepEqual(silent.lines[1].harmonyNotes, ["weight", "bloom"]);
  assert.deepEqual(silent.lines.map((l) => [l.harmonies, l.resonances]), [[1, 1], [2, 1], [1, 2]]);
  const sounding = build.stability({ spire: 5, anchors: [5, 5, 4, 4, 3, 0], schools: [null], laws });
  assert.equal(sounding.capacity, 223);
  assert.deepEqual(sounding.chords, [{ realm: 0, chord: "deep_sleep" }]);
  assert.equal(sounding.micro.draw, 192_000_000);
  assert.equal(sounding.micro.total, 216_694_200, "0.9 × 27.438 + 192");
  assert.equal(sounding.band, 3, "216.69 of 223, 97%: Brimming");
});
