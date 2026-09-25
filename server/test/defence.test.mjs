// Defending pays (§9.4, §13.1), against the real simulation build.

import assert from "node:assert/strict";
import { test } from "node:test";

import { defenceShare } from "../src/economy.mjs";
import { SEASON_MS } from "../src/seasons.mjs";
import { T0, openPlan, play, twoPlayers } from "./setup.mjs";

const DAY = 24 * 60 * 60 * 1000;

/** The planned heist, stopped once the bags are full: the crew never calls
 *  the skiff, and the clock catches it holding everything it loaded. */
const greedy = () => openPlan().filter((c) => c.kind !== "Skiff" && c.tick < 62 * 30);

test("a foiled heist pays the defender the fee and 5% of what the crew was carrying (9.4)", () => {
  const t = twoPlayers(true);
  const lease = t.service.lease(t.raider.account, t.bundle);
  const out = t.service.submit(t.raider.account, lease.token, play(t, lease, { plan: greedy() }));
  assert.equal(out.verdict.grade, "foiled");
  assert.ok(out.verdict.left > 0, "the crew was caught holding what it loaded");
  const snap = t.service.db.prepare("SELECT vault_level, exposed FROM snapshots WHERE bundle = ?").get(t.bundle);
  const expected = defenceShare({ vaultLevel: snap.vault_level, raiderLevel: 1, targetLevel: 1, exposed: snap.exposed,
                                  left: out.verdict.left, capacity: out.verdict.capacity, percent: 5 });
  assert.ok(expected.total > 0);
  assert.deepEqual(out.defence, { percent: 5, ...expected });
  assert.deepEqual(t.service.balance(t.defender.account),
                   { starlight: out.fee + expected.starlight, essence: expected.essence, starglass: 0 });
  // A crew that loaded nothing leaves nothing: the fee alone.
  t.clock.now += DAY + 1;
  const empty = t.service.lease(t.raider.account, t.bundle);
  const none = t.service.submit(t.raider.account, empty.token, play(t, empty, { plan: [] }));
  assert.deepEqual([none.verdict.left, none.defence.total], [0, 0]);
});

test("while fewer than 15% change their defence, the share rises 5 points a season, to 20% at most (13.1)", () => {
  const t = twoPlayers(true);
  const seasons = t.service.seasons;
  assert.equal(seasons.defenceShare(), 5);
  const close = (n) => {
    t.clock.now = T0 + n * SEASON_MS - DAY;
    // Nine players active in the season's last week, and nobody republishing.
    for (let i = 0; i < 9; i++) t.service.session(`gc:active-${i}`);
    t.clock.now = T0 + n * SEASON_MS + 1;
    seasons.rollover();
    return seasons.defenceShare();
  };
  assert.deepEqual([close(1), close(2), close(3), close(4)], [10, 15, 20, 20], "three rises, then nothing further");
  const measured = t.service.db.prepare("SELECT measured FROM defence_shares WHERE season = 2").get().measured;
  assert.equal(measured, 0);
});

test("a week in which enough players change their defence holds the share where it is (13.1)", () => {
  const t = twoPlayers(true);
  t.service.seasons.current();                         // season 1 is open
  t.clock.now = T0 + SEASON_MS - DAY;
  for (let i = 0; i < 4; i++) t.service.session(`gc:quiet-${i}`);
  // The defender republishes: one of the five active this week, 20%.
  t.service.session("gc:defender");
  const island = t.build.exampleIsland(true);
  island[5] = 2;
  t.service.publish(t.defender.account, island);
  t.clock.now = T0 + SEASON_MS + 1;
  t.service.seasons.rollover();
  assert.equal(t.service.seasons.defenceShare(), 5);
  assert.equal(t.service.db.prepare("SELECT measured FROM defence_shares WHERE season = 2").get().measured, 20);
});

test("going back to an island published before is a change of defence too (13.1)", () => {
  const t = twoPlayers(true);
  t.service.seasons.current();                         // season 1 is open
  const island = t.build.exampleIsland(true);
  island[5] = 2;
  t.service.publish(t.defender.account, island);       // on to another, at the start
  t.clock.now = T0 + SEASON_MS - DAY;
  for (let i = 0; i < 4; i++) t.service.session(`gc:quiet-${i}`);
  // The defender goes back to the first: no new snapshot, but a change.
  t.service.session("gc:defender");
  t.service.publish(t.defender.account, t.island);
  t.clock.now = T0 + SEASON_MS + 1;
  t.service.seasons.rollover();
  assert.equal(t.service.db.prepare("SELECT measured FROM defence_shares WHERE season = 2").get().measured, 20);
  assert.equal(t.service.seasons.defenceShare(), 5);
});
