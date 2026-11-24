// FX2-6's audit, the Observatory's cards (docs/security/audit-2026-11/server-b.md).

import assert from "node:assert/strict";
import { test } from "node:test";

import { stillOpen } from "./fix_fx2_open.mjs";
import { twoPlayers } from "./setup.mjs";

function keeper6(t) {
  t.service.db.prepare("UPDATE accounts SET keeper_level = 6 WHERE id = ?").run(t.raider.account);
}

// AUD-B-02: §17.8, a blocked player disappears from "anything with their
// name on it"; the island stays a target.
test("AUD-B-02: a target card across a block carries no Keeper name", () => {
  const t = twoPlayers(false);
  keeper6(t);
  t.service.keeper.setName(t.defender.account, { adjective: 0, noun: 0 });
  assert.deepEqual(t.service.observatory.view(t.raider.account).targets[0].keeper_name, { adjective: 0, noun: 0 });
  t.service.safety.block(t.raider.account, t.defender.account);
  const v = t.service.observatory.view(t.raider.account);
  assert.equal(v.targets.length, 1, "the island stays a target");
  assert.equal(v.targets[0].keeper_name, null, "the blocked Keeper's name is shown");
});

// AUD-B-07: an echo is one past island (service.issue: "never a universe"),
// so its card describes that island, not the owner's universe now.
test("AUD-B-07: an echo's card describes the one island the echo lease is", () => {
  const t = twoPlayers(false);
  keeper6(t);
  const d = t.defender.account;
  for (const [i, type] of [[1, "Skyfield"], [2, "Crystalline"]]) {
    t.service.db.prepare("INSERT INTO realms (owner, realm, type, level, opened_at) VALUES (?, ?, ?, 1, 0)")
      .run(d, `outer-${i}`, type);
  }
  t.service.book(d, "starlight", 10_000, "grant");
  t.service.links.build(d, { a: "outer-2", b: "outer-1", kind: "stone_bridge" });
  const old = t.bundle;
  assert.notEqual(t.service.publish(d, t.build.exampleIsland(true)).bundle, old);
  t.clock.now += 2 * 60 * 60 * 1000; // a new hourly list
  const echo = t.service.matchmaking.listed().find((c) => c.bundle === old);
  assert.ok(echo?.echo, "the old Heart is an echo");
  const card = t.service.observatory.card(t.raider.account, echo);
  assert.equal(card.kind, "echo");
  assert.equal(t.service.lease(t.raider.account, old).echo, true);
  assert.equal(card.realms, 1, "the echo lease is the one island");
  assert.equal(card.depth, 0);
  assert.deepEqual(card.fault_realms, []);
  assert.equal(card.strain, 0);
  assert.equal(card.across, false);
});

// AUD-B-06: open. §7.6, matchmaking shows only universes running laws from
// open chapters; matchmaking.mjs's current() swaps in a republished bundle
// and keeps the old bundle's chapter.
test("AUD-B-06: an island republished with a closed chapter's law within the hour is not shown", async () => {
  await stillOpen("AUD-B-06", () => {
    const t = twoPlayers(true); // Brittle stone: chapter 1
    assert.equal(t.service.matchmaking.raider(t.raider.account).chapter, 1);
    assert.deepEqual(t.service.observatory.view(t.raider.account).targets.map((c) => c.bundle), [t.bundle]);
    t.clock.now += 60 * 1000;
    const two = t.service.publish(t.defender.account, t.build.exampleIsland(false)).bundle; // Haste: chapter 2
    const v = t.service.observatory.view(t.raider.account);
    assert.ok(!v.targets.some((c) => c.bundle === two), "a chapter-2 island is shown to a chapter-1 raider");
  });
});
