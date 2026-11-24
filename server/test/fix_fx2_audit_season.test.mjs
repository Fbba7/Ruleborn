// FX2-6's audit, the season's tier price (docs/security/audit-2026-11/server-b.md).

import assert from "node:assert/strict";
import { test } from "node:test";

import { SEASON_MS } from "../src/seasons.mjs";
import { stillOpen } from "./fix_fx2_open.mjs";
import { T0, twoPlayers } from "./setup.mjs";

const DAY = 24 * 60 * 60 * 1000;

// AUD-B-01: open. §18.8: "A player first seen in a season pays 10 × (days
// left ÷ 56) stars a tier … fixed when the player first appears that season."
// matchmaking.mjs's live() and fresh() call seasons.league() for every island
// owner, which opens the owner's standing at the price of that hour.
test("AUD-B-01: the hourly target lists do not fix an absent island owner's tier price", async () => {
  await stillOpen("AUD-B-01", () => {
    const t = twoPlayers(true);
    t.clock.now = T0 + SEASON_MS + 60 * 1000; // season 2, its first minute
    t.service.seasons.rollover();
    t.service.targetLists(); // the hourly job (main.mjs)
    assert.equal(t.service.seasons.current().id, 2);
    t.clock.now = T0 + SEASON_MS + 35 * DAY; // week 6: 21 days left
    assert.equal(t.service.track.view(t.defender.account).tierStars, 4, "10 × 21 ÷ 56, rounded");
  });
});

test("AUD-B-01: a raider's Observatory view does not open the target owner's standing", async () => {
  await stillOpen("AUD-B-01", () => {
    const t = twoPlayers(true);
    t.clock.now = T0 + SEASON_MS + 35 * DAY;
    t.service.seasons.rollover();
    t.service.observatory.view(t.raider.account);
    const row = t.service.db.prepare("SELECT 1 FROM standings WHERE season = 2 AND account = ?")
      .get(t.defender.account);
    assert.equal(row, undefined, "the defender has not appeared in season 2");
  });
});
