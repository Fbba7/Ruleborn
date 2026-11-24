// FX2-6's audit (docs/security/audit-2026-11/server-b.md), server/load.mjs:
// AUD-B-20.
import test from "node:test";
import assert from "node:assert/strict";
import { readFileSync } from "node:fs";
import { against, readsAMonth, READS } from "../load.mjs";

const facts = JSON.parse(readFileSync(new URL("../src/facts.json", import.meta.url), "utf8"));
const kept = JSON.parse(readFileSync(new URL("../load.json", import.meta.url), "utf8"));

test("AUD-B-20: the free plan's daily players read no more than the free plan's day, by readsAMonth's own model", () => {
  const runs = (Array.isArray(kept) ? kept : Object.values(kept)).filter((r) => r?.periodicReadsADayAnIsland);
  assert.ok(runs.length > 0, "load.json holds the archetypes' runs");
  const [dn, dd] = facts.DAILY_SHARE;
  for (const r of runs) {
    const players = against(r).freePlanReadsPlayersADay;
    // `players` daily players are players * dd / dn monthly ones.
    const aDay = readsAMonth(r, players * dd / dn) / 30;
    assert.ok(aDay <= READS.freeDay, `${r.archetype}: ${players} daily players read ${Math.round(aDay)} rows a day`);
  }
});
