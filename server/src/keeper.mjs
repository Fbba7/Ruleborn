// Keeper levels (§14.2): the experience a player earns and the level it buys.
//
// §14.2: "Keeper experience comes from successful heists (30 + 6 × Keeper
// level), foiled heists (10 + 2 × level), spending (1 for every 40 Starlight)
// and restoring laws (60 + 10 × level)", and its table gives the experience
// from each level to the next, 1 to 40. The server settles heists, so it
// awards their experience here, in the heist's own transaction; spending
// (universe.mjs) and restoring laws (codex.mjs) award theirs in their own
// purchase's. A level is what every Keeper gate reads: the Beacon's Keeper 6
// (§17.1), matchmaking's window (§12.22).

import { readFileSync } from "node:fs";

const facts = JSON.parse(readFileSync(new URL("./facts.json", import.meta.url), "utf8"));

/** The highest level: the table gives the experience to each level after 1. */
export const KEEPER_LEVEL_CAP = facts.KEEPER_XP_TO_NEXT.length + 1;

/** A heist's experience for its raider at `level`: §14.2's sum for a
 *  successful heist, or for a foiled one. */
export function heistExperience(level, foiled) {
  const [base, perLevel] = foiled ? facts.XP_PER_FOILED_HEIST : facts.XP_PER_SUCCESSFUL_HEIST;
  return base + perLevel * level;
}

/** Experience `xp` added at `level` with `have` toward the next: the levels it
 *  climbs and what is left toward the one after. At the top, nothing more
 *  counts. */
export function climb(level, have, xp) {
  let next = { level, have: have + xp };
  while (next.level < KEEPER_LEVEL_CAP && next.have >= facts.KEEPER_XP_TO_NEXT[next.level - 1]) {
    next = { level: next.level + 1, have: next.have - facts.KEEPER_XP_TO_NEXT[next.level - 1] };
  }
  if (next.level === KEEPER_LEVEL_CAP) next.have = 0;
  return next;
}

/** How much of `xp`, added at `level` with `have`, counted: all of it below
 *  the top, and none past it — so a Keeper 40 is never told of experience
 *  that bought nothing. */
export function counted(level, have, xp) {
  let left = -have;
  for (let l = level; l < KEEPER_LEVEL_CAP; l++) left += facts.KEEPER_XP_TO_NEXT[l - 1];
  return Math.max(0, Math.min(xp, left));
}

export class Keeper {
  constructor(service) {
    this.service = service;
    this.db = service.db;
  }

  /** Add experience; called inside the transaction that earned it. Returns
   *  what it came to: the experience gained, the level and progress after,
   *  and how many levels it climbed. */
  award(account, xp) {
    const row = this.db.prepare("SELECT keeper_level, keeper_xp FROM accounts WHERE id = ?").get(account);
    const next = climb(row.keeper_level, row.keeper_xp, xp);
    this.db.prepare("UPDATE accounts SET keeper_level = ?, keeper_xp = ? WHERE id = ?")
      .run(next.level, next.have, account);
    return { gained: counted(row.keeper_level, row.keeper_xp, xp), level: next.level, xp: next.have,
             toNext: this.toNext(next.level), levelled: next.level - row.keeper_level };
  }

  /** The experience from `level` to the next, or null at the top. */
  toNext(level) {
    return level < KEEPER_LEVEL_CAP ? facts.KEEPER_XP_TO_NEXT[level - 1] : null;
  }

  /** A player's Keeper level and the bar toward the next. */
  view(account) {
    const row = this.db.prepare("SELECT keeper_level, keeper_xp FROM accounts WHERE id = ?").get(account);
    return { level: row.keeper_level, xp: row.keeper_xp, toNext: this.toNext(row.keeper_level),
             cap: KEEPER_LEVEL_CAP };
  }
}
