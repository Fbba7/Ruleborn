// Keeper levels (§14.2): the experience a heist earns and the levels it buys.

import assert from "node:assert/strict";
import { readFileSync } from "node:fs";
import { test } from "node:test";

import { defenceShare } from "../src/economy.mjs";
import { KEEPER_LEVEL_CAP, climb, counted, heistExperience } from "../src/keeper.mjs";
import { openPlan, play, twoPlayers } from "./setup.mjs";

const facts = JSON.parse(readFileSync(new URL("../src/facts.json", import.meta.url), "utf8"));

test("a heist earns §14.2's experience: 30 + 6 × level for a success, 10 + 2 × level foiled", () => {
  assert.equal(heistExperience(1, false), 36);
  assert.equal(heistExperience(1, true), 12);
  assert.equal(heistExperience(10, false), 90);
  assert.equal(heistExperience(10, true), 30);
});

test("experience climbs §14.2's table level by level, and stops counting at level 40", () => {
  assert.deepEqual(climb(1, 0, 139), { level: 1, have: 139 });
  assert.deepEqual(climb(1, 0, 140), { level: 2, have: 0 }, "140 to level 2");
  assert.deepEqual(climb(1, 0, 140 + 90 + 5), { level: 3, have: 5 }, "and 90 more to level 3");
  const total = facts.KEEPER_XP_TO_NEXT.reduce((a, b) => a + b, 0);
  assert.deepEqual(climb(1, 0, total - 1), { level: KEEPER_LEVEL_CAP - 1, have: facts.KEEPER_XP_TO_NEXT.at(-1) - 1 });
  assert.deepEqual(climb(1, 0, total + 10_000), { level: 40, have: 0 });
  assert.equal(KEEPER_LEVEL_CAP, 40);
});

test("a raid's experience is the raider's, settled with its haul, once, and it levels them up (14.2)", () => {
  const t = twoPlayers();
  const lease = t.service.lease(t.raider.account, t.bundle);
  const replay = play(t, lease, { plan: openPlan() });
  const out = t.service.submit(t.raider.account, lease.token, replay);
  assert.equal(out.verdict.grade, "clean");
  assert.deepEqual(out.keeper, { gained: 36, level: 1, xp: 36, toNext: 140, levelled: 0 });
  const again = t.service.submit(t.raider.account, lease.token, replay);
  assert.deepEqual(again.keeper, out.keeper);
  assert.deepEqual(t.service.keeper.view(t.raider.account), { level: 1, xp: 36, toNext: 140, cap: 40 },
                   "a retry pays nothing twice");
  assert.deepEqual(t.service.keeper.view(t.defender.account), { level: 1, xp: 0, toNext: 140, cap: 40 },
                   "the defender earns none");
  // Keeper 5, 20 short of 6: a clean heist at level 5 is 60, and the Beacon's
  // Keeper 6 (§17.1) opens.
  t.service.db.prepare("UPDATE accounts SET keeper_level = 5, keeper_xp = 440 WHERE id = ?").run(t.raider.account);
  t.clock.now += 60 * 60 * 1000;
  const next = t.service.lease(t.raider.account, t.bundle);
  const up = t.service.submit(t.raider.account, next.token, play(t, next, { plan: openPlan() }));
  assert.deepEqual(up.keeper, { gained: 60, level: 6, xp: 40, toNext: facts.KEEPER_XP_TO_NEXT[5], levelled: 1 });
  assert.ok(t.service.keeper.view(t.raider.account).level >= facts.CONSTELLATION_KEEPER_LEVEL);
});

test("a foiled raid earns a foiled heist's experience; a game among friends earns none (14.2, F48)", () => {
  const t = twoPlayers(false);
  t.service.db.prepare(
    "INSERT INTO ledger (account, starlight, reason, at) VALUES (?, 50000, \'grant\', 0)")
    .run(t.raider.account);
  const lease = t.service.lease(t.raider.account, t.bundle);
  const out = t.service.submit(t.raider.account, lease.token, play(t, lease, { crew: 4 }));
  assert.equal(out.verdict.grade, "foiled");
  assert.equal(out.keeper.gained, 12);
  const { invite } = t.service.friends.invite(t.defender.account);
  t.service.friends.accept(t.raider.account, invite);
  const friendly = t.service.lease(t.raider.account, t.bundle, null, { mode: "friendly" });
  const game = t.service.submit(t.raider.account, friendly.token, play(t, friendly, { plan: [] }));
  assert.equal(game.keeper, null);
  assert.equal(t.service.keeper.view(t.raider.account).xp, 12);
});

const greedy = () => openPlan().filter((c) => c.kind !== "Skiff" && c.tick < 62 * 30);

test("a foil that levels its raider up still prices the defender's share at the level it was played at", () => {
  const t = twoPlayers(true);
  // 12 short of Keeper 2: the foil's 12 levels the raider up.
  t.service.db.prepare("UPDATE accounts SET keeper_xp = 128 WHERE id = ?").run(t.raider.account);
  const lease = t.service.lease(t.raider.account, t.bundle);
  const out = t.service.submit(t.raider.account, lease.token, play(t, lease, { plan: greedy() }));
  assert.equal(out.verdict.grade, "foiled");
  assert.deepEqual([out.keeper.level, out.keeper.levelled], [2, 1]);
  const snap = t.service.db.prepare("SELECT vault_level, exposed FROM snapshots WHERE bundle = ?").get(t.bundle);
  const atPlay = defenceShare({ vaultLevel: snap.vault_level, raiderLevel: 1, targetLevel: 1, exposed: snap.exposed,
                                left: out.verdict.left, capacity: out.verdict.capacity, percent: 5 });
  assert.deepEqual(out.defence, { percent: 5, ...atPlay });
});

test("at Keeper 40 a raid's experience counts for nothing, and says so; a challenge earns none (14.2, 17.6)", () => {
  assert.equal(counted(40, 0, 270), 0);
  assert.equal(counted(39, facts.KEEPER_XP_TO_NEXT[38] - 10, 270), 10, "only what reaches the top");
  assert.equal(counted(1, 0, 36), 36);
  const t = twoPlayers();
  t.service.db.prepare("UPDATE accounts SET keeper_level = 40 WHERE id = ?").run(t.raider.account);
  const lease = t.service.lease(t.raider.account, t.bundle);
  const out = t.service.submit(t.raider.account, lease.token, play(t, lease, { plan: openPlan() }));
  assert.deepEqual(out.keeper, { gained: 0, level: 40, xp: 0, toNext: null, levelled: 0 });
  const other = twoPlayers();
  const { challenge, bundle } = other.service.friends.challenge(other.defender.account);
  const played = other.service.lease(other.raider.account, bundle, null, { mode: "challenge", challenge });
  const game = other.service.submit(other.raider.account, played.token, play(other, played, { plan: openPlan() }));
  assert.equal(game.keeper, null);
});
