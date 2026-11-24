// FX2-10-curated-woven-law, FX2-9's follow-up: the Observatory's echoes
// flag. offer()'s echoes means an echo is among the targets (FX1-R9), and
// the client shows it as OBS_ECHOES_NOTE ("echoes of recent ones are among
// these"). The view filters offer()'s list with current(), which drops an
// island whose owner is banned or deleted within the hour; the flag must
// follow the targets the view shows, not the list before it.

import assert from "node:assert/strict";
import { test } from "node:test";

import { twoPlayers } from "./setup.mjs";

test("FX2-9 follow-up: an echo dropped from the view because its owner was banned within the hour is not said (12.3)", () => {
  const t = twoPlayers(false);
  t.service.db.prepare("UPDATE accounts SET keeper_level = 6 WHERE id = ?").run(t.raider.account);
  const d = t.defender.account;
  const old = t.bundle;
  assert.notEqual(t.service.publish(d, t.build.exampleIsland(true)).bundle, old);
  t.clock.now += 2 * 60 * 60 * 1000; // a new hourly list, in which the old Heart is an echo
  const before = t.service.observatory.view(t.raider.account);
  assert.ok(before.targets.some((c) => c.bundle === old && c.kind === "echo"), "the echo is offered");
  assert.equal(before.echoes, true, "a list with an echo says so");
  // Banned within the hour: the hourly list still holds the owner's islands,
  // and current() drops them from the view.
  t.service.db.prepare("UPDATE accounts SET banned_at = ? WHERE id = ?").run(t.clock.now, d);
  const after = t.service.observatory.view(t.raider.account);
  assert.ok(after.targets.every((c) => c.kind !== "echo"), "the banned owner's echo is not shown");
  assert.equal(after.echoes, false, "the view says no echo is among its targets");
});
