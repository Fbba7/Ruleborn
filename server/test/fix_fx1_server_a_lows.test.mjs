// FX1-8-server-a-lows: the proofs docs/security/audit-2026-11/server-a.md's
// low findings needed beyond fix_fx1_audit_server_a.test.mjs's, each failing
// on the code before its fix.

import assert from "node:assert/strict";
import { test } from "node:test";

import { BOUNDS, SEASON_MS } from "../src/seasons.mjs";
import { T0, established, openPlan, play, twoPlayers } from "./setup.mjs";

test("FX1-A-13: a raid on an island its owner republished before it settled is rated in the realm it was leased in (12.22)", () => {
  const t = twoPlayers(true);
  const b = t.service.session("gc:second").account;
  established(t, b);
  assert.equal(t.service.publish(b, t.island, "outer-1").bundle, t.bundle, "one snapshot, the first publisher's (heart)");
  const lease = t.service.lease(t.raider.account, t.bundle, b);
  // B republishes outer-1 while the lease is out: no island of B's is on
  // these bytes when the raid settles.
  assert.notEqual(t.service.publish(b, t.build.exampleIsland(false), "outer-1").bundle, t.bundle);
  const before = t.service.matchmaking.islandRating(b, "outer-1");
  const out = t.service.submit(t.raider.account, lease.token, play(t, lease, { plan: openPlan() }));
  assert.equal(out.validated, true);
  assert.equal(t.service.matchmaking.islandRating(b, "outer-1")?.games, (before?.games ?? 0) + 1,
    "B's outer-1 island, the one leased, played a rated game");
  assert.equal(t.service.matchmaking.islandRating(b, "heart"), null, "no rating for a B/heart island B never published");
});

test("FX1-R10: each season that ended pulls Renown halfway back once, in order (18.1)", () => {
  const t = twoPlayers(true);
  const me = t.raider.account;
  const star = BOUNDS.leagues.Star;
  const seasons = t.service.seasons;
  seasons.standing(me, seasons.current().id);
  t.service.db.prepare("UPDATE standings SET start = ?, ember = 1 WHERE season = 1 AND account = ?").run(star + 100, me);
  // Absent through seasons 2 and 3: seasons 1, 2 and 3 end before season 4.
  t.clock.now = T0 + 3 * SEASON_MS + 1;
  seasons.rollover();
  const now = seasons.league(me);
  assert.equal(now.season, 4);
  // 354 to 304, to 279, to 266.5, rounded each time: Star's floor is 254.
  assert.equal(now.renown, star + 13, "pulled back three times, never once to Star+50");
  assert.equal(seasons.standing(me, 4).ember, 1, "Ember, once reached, stays reached");
});
