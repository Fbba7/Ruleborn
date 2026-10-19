// §13.3's hold, measured on the server by the simulation's reference crew
// (holds.mjs).

import assert from "node:assert/strict";
import { readFileSync } from "node:fs";
import { test } from "node:test";

import { fresh, ratingFor } from "../src/glicko.mjs";
import { HOLD_CREW, seedOf } from "../src/holds.mjs";
import { prior } from "../src/matchmaking.mjs";
import { clockTicks } from "../src/service.mjs";
import { twoPlayers } from "./setup.mjs";

const facts = JSON.parse(readFileSync(new URL("../src/facts.json", import.meta.url), "utf8"));

test("a published island is queued for §13.3's 800 raids of the competent reference crew, measured in parts as in one call, and rated from the hold that lands (13.3, 12.22, TD.16)", () => {
  const t = twoPlayers(false);
  const h = t.service.holds;
  assert.deepEqual(h.status(t.bundle), { status: "measuring", played: 0, raids: facts.HOLD_RAIDS });
  assert.equal(facts.HOLD_RAIDS, 800);
  const before = t.service.matchmaking.islandRating(t.defender.account, "heart");
  assert.equal(before.rating, prior(3).rating, "the band's middle until it lands");
  // A short measurement, so the test runs in seconds: the same queue.
  t.service.db.prepare("UPDATE island_holds SET raids = 30").run();
  assert.equal(h.work(12), 12);
  assert.deepEqual(h.status(t.bundle), { status: "measuring", played: 12, raids: 30 });
  h.work(12);
  h.work(12);
  assert.equal(h.work(12), 0, "nothing left to measure");
  const s = h.status(t.bundle);
  const whole = t.build.hold(t.island, { seed: seedOf(t.bundle), raids: 30, ticks: clockTicks(0), crew: HOLD_CREW });
  assert.deepEqual([s.status, s.held, s.raids], ["measured", whole, 30], "in parts as in one call");
  assert.ok(s.held > 0 && s.held < 30, `the example island holds some raids and not others: ${s.held}`);
  const rated = t.service.matchmaking.islandRating(t.defender.account, "heart");
  assert.ok(Math.abs(rated.rating - fresh(ratingFor(1 - s.held / 30)).rating) < 1e-9,
            "§12.22's prior from the hold against the reference crew");
  // Cached by the digest: the same island published again is not measured
  // again, and another player's copy is rated from it at once.
  const other = t.service.session("gc:copy").account;
  t.service.publish(other, t.island);
  assert.equal(t.service.db.prepare("SELECT COUNT(*) AS n FROM island_holds").get().n, 1);
  assert.ok(Math.abs(t.service.matchmaking.islandRating(other, "heart").rating - rated.rating) < 1e-9);
});

test("curation shows the hold as measuring until it lands, then as measured, never as an estimate (13.3, G55)", () => {
  const t = twoPlayers(false);
  const view = () => t.service.curation.view(t.defender.account, "heart").hold;
  assert.equal(view().status, "measuring");
  assert.equal("held" in view(), false, "no figure before it lands");
  t.service.db.prepare("UPDATE island_holds SET raids = 6").run();
  t.service.holds.work(6);
  assert.equal(view().status, "measured");
  assert.equal(view().raids, 6);
});
