// §12.5's crew manifest, against the real simulation build: the replay
// carries the crew, and the server's re-simulation plays each member by its
// kind and ability (12.5, 12.6).

import assert from "node:assert/strict";
import { readFileSync } from "node:fs";
import { test } from "node:test";

import { readHeader } from "../src/sim.mjs";
import { openPlan, play, twoPlayers } from "./setup.mjs";

const KINDS = JSON.parse(readFileSync(new URL("../../content/ruleborn.json", import.meta.url)))
  .map((k) => k.id);
const crew = (...ids) => ({ members: ids.map((id) => ({ kind: KINDS.indexOf(id) })), sage: 0, casts: [] });

test("a heist carrying its crew manifest is re-simulated with each member's ability (12.5, 12.6)", () => {
  const t = twoPlayers(true);
  const lease = t.service.lease(t.raider.account, t.bundle);
  const s = (seconds) => seconds * 30;
  const plan = [
    ...openPlan(),
    { tick: s(15), member: 1, kind: "Ability", x: 0, y: 0 },     // the Quarryback pounds
    { tick: s(50), member: 2, kind: "Ability", x: 0, y: 0 },     // the Skyskipper's satchel
  ].sort((a, b) => a.tick - b.tick);
  const manifest = crew("stormhound", "quarryback", "skyskipper");
  const replay = play(t, lease, { plan, manifest });
  assert.equal(readHeader(replay).manifest, true, "an RBH3 replay");
  const out = t.service.submit(t.raider.account, lease.token, replay);
  assert.equal(out.validated, true, "the server plays the same crew the device did");
  assert.equal(out.verdict.grade, "clean");
  assert.equal(out.verdict.banked, 508, "a Scout's, a Breaker's and a Carrier's bags: 104 + 104 + 300");
});

test("a manifest naming a kind past the eighteen does not record (12.5)", () => {
  const t = twoPlayers(true);
  const lease = t.service.lease(t.raider.account, t.bundle);
  const manifest = { members: [{ kind: 18 }, { kind: 0 }, { kind: 1 }], sage: 0, casts: [] };
  assert.throws(() => play(t, lease, { plan: openPlan(), manifest }), /manifest/);
});
