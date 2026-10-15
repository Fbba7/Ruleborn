// §23.2's defence log (defences.mjs, TD.66).

import assert from "node:assert/strict";
import { test } from "node:test";

import { haul } from "../src/economy.mjs";
import { SEASON_MS } from "../src/seasons.mjs";
import { TICKS_PER_SECOND } from "../src/service.mjs";
import { established, openPlan, play, twoPlayers } from "./setup.mjs";

const HOUR = 60 * 60 * 1000;

/** A raid on the defender settled with `verdict`, as a submission settles it,
 *  lasting `heistMs`. */
function raid(t, verdict, heistMs = 95_000) {
  t.clock.now += HOUR;
  const lease = t.service.lease(t.raider.account, t.bundle);
  const row = t.service.db.prepare("SELECT * FROM leases WHERE token = ?").get(lease.token);
  t.service.settle(row, new Uint8Array(8), `dl-${t.clock.now}`, t.clock.now,
                   { validated: true, verdict, heistMs });
  return lease.token;
}

const verdict = (grade, banked, extra = {}) =>
  ({ grade, out: 3, caught: grade === "foiled" ? 3 : 0, crew: 3, banked, capacity: 800, pages: 0, cracked: 1,
     left: grade === "foiled" ? 400 : 0, ...extra });

test("the defence log lists the season's raids on a player, newest first, held when foiled and leaked otherwise with Partial counted apart, each with the haul denied and how long the defence held (13.2, 12.9, G69)", () => {
  const t = twoPlayers();
  const clean = raid(t, verdict("clean", 800));
  const partial = raid(t, verdict("partial", 300), 61_400);
  const foiled = raid(t, verdict("foiled", 0));
  const v = t.service.defences.show(t.defender.account);
  assert.deepEqual(v.raids.map((r) => r.heist), [foiled, partial, clean], "newest first");
  assert.deepEqual(v.raids.map((r) => [r.grade, r.held]), [["foiled", true], ["partial", false], ["clean", false]]);
  assert.deepEqual(v.season, { held: 1, leaked: 2, partial: 1 });
  // Denied: the clean haul of a full bag on this island, less the clean haul
  // of what the raider banked, as §9.4 prices a crew's unbanked load (G31).
  const snap = t.service.db.prepare("SELECT vault_level, exposed FROM snapshots WHERE bundle = ?").get(t.bundle);
  const level = (a) => t.service.db.prepare("SELECT keeper_level FROM accounts WHERE id = ?").get(a).keeper_level;
  const worth = (banked) => haul({ vaultLevel: snap.vault_level, gradeName: "clean", raiderLevel: level(t.raider.account),
    targetLevel: level(t.defender.account), exposed: snap.exposed, raidsEarlierToday: 0, banked, capacity: 800 }).total;
  assert.ok(worth(800) > 0);
  assert.deepEqual(v.raids.map((r) => r.denied), [worth(800), worth(800) - worth(300), 0]);
  assert.deepEqual(v.raids.map((r) => r.held_seconds), [95, 61, 95], "landing to the last escape or capture");
  assert.equal(v.raids[0].caught, 3);
  assert.equal(v.raids[0].defence.total, 0, "a foiled raid records the defender's share, none on a pair's later raid that day (9.4, G37)");
  // A new season keeps none of the last one's rows.
  t.clock.now += SEASON_MS;
  assert.deepEqual(t.service.defences.show(t.defender.account).raids, []);
});

test("a raid settled from a real replay records its haul denied and how long it held (13.2, TD.39)", () => {
  const t = twoPlayers();
  const lease = t.service.lease(t.raider.account, t.bundle);
  const out = t.service.submit(t.raider.account, lease.token, play(t, lease, { plan: openPlan() }));
  assert.equal(out.validated, true);
  const [r] = t.service.defences.show(t.defender.account).raids;
  assert.ok(Number.isInteger(r.denied) && r.denied >= 0);
  assert.equal(r.held_seconds, Math.round(lease.ticks / TICKS_PER_SECOND), "the heist's length, landed at tick 0");
});

test("the log offers Watch replay while the replay is kept and says when it is gone, and Trace only on the raid the server can trace, never a foiled one (12.3, 13, 24.3, G70)", () => {
  const t = twoPlayers();
  established(t, t.raider.account);
  const island = t.build.exampleIsland(true);
  island[5] = 2;
  const home = t.service.publish(t.raider.account, island).bundle;
  const robbed = raid(t, verdict("loud", 600));
  const foiled = raid(t, verdict("foiled", 0));
  t.service.db.prepare("UPDATE heists SET replay_gone = 1 WHERE token = ?").run(foiled);
  const v = t.service.defences.show(t.defender.account);
  const by = Object.fromEntries(v.raids.map((r) => [r.heist, r]));
  assert.deepEqual(by[robbed].trace, { bundle: home }, "the raider's island, with no fee");
  assert.equal(by[foiled].trace, null, "a foiled raid opens nothing");
  assert.deepEqual([by[robbed].replay, by[foiled].replay], ["kept", "gone"]);
  assert.equal(by[robbed].island, t.bundle, "the island the replay was played on");
  // Traced once, the raid offers no Trace again.
  const trace = t.service.lease(t.defender.account, home, null, { trace: true });
  assert.ok(trace.token);
  assert.equal(t.service.defences.show(t.defender.account).raids.find((r) => r.heist === robbed).trace, null);
});

test("reading the defence log clears the raid badge, and a new raid sets it again (TD.66)", () => {
  const t = twoPlayers();
  raid(t, verdict("clean", 800));
  raid(t, verdict("foiled", 0));
  assert.deepEqual(t.service.defences.badge(t.defender.account), { unseen: 2 });
  assert.equal(t.service.defences.show(t.defender.account).unseen, 2, "the read shows which were new");
  assert.deepEqual(t.service.defences.badge(t.defender.account), { unseen: 0 });
  raid(t, verdict("partial", 200));
  assert.deepEqual(t.service.defences.badge(t.defender.account), { unseen: 1 });
  assert.deepEqual(t.service.defences.show(t.defender.account).raids.map((r) => r.new), [true, false, false]);
});

test("the defence log and its badge are served over HTTP (13.2)", async () => {
  const t = twoPlayers();
  raid(t, verdict("clean", 800));
  const { token } = t.service.session("gc:defender");
  const get = (path) => t.handle(new Request(`https://edge.example${path}`, { headers: { authorization: `Bearer ${token}` } }));
  assert.deepEqual(await (await get("/v1/defences/badge")).json(), { unseen: 1 });
  const v = await (await get("/v1/defences")).json();
  assert.equal(v.raids.length, 1);
  assert.deepEqual(await (await get("/v1/defences/badge")).json(), { unseen: 0 });
});
