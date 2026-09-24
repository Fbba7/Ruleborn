// The week's era (§18.3).
//
// "Each week one rule changes for every universe, which refreshes which laws
// and crews are strong." The rules themselves are the simulation's
// (sim/src/era.rs); the server says which week has which, puts the era on
// every lease against a universe, lengthens Quiet Week's clock, and refuses a
// replay that names another era than its lease.
//
// Which era a week has is not stated (G36): here the eight take turns in the
// content file's order, a week each, from the first season's first day, so
// every era comes once in each eight-week season (§18.1).

import { readFileSync } from "node:fs";

const content = JSON.parse(readFileSync(new URL("../../content/eras.json", import.meta.url), "utf8"));
const WEEK = 7 * 24 * 60 * 60 * 1000;

/** The eras in wire order: the value a replay's header carries is the index
 *  plus one, and 0 is none — sim/src/era.rs's order, from the same file. */
export const ERAS = content.map((e, i) => ({
  id: e.id, name: e.name, rule: e.rule, wire: i + 1,
  // Quiet Week's "30 seconds", read from its rule as the simulation reads it.
  seconds: Number(/(\d+) seconds/.exec(e.rule)?.[1] ?? 0),
}));

/** The era of the week `now` falls in, and when that week ends. */
export function eraAt(now, first) {
  const week = Math.max(0, Math.floor((now - first) / WEEK));
  const era = ERAS[week % ERAS.length];
  return { ...era, week: week + 1, endsAt: first + (week + 1) * WEEK };
}

export const byWire = (wire) => ERAS[wire - 1] ?? null;
