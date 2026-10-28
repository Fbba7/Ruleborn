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

import { Refused } from "./refused.mjs";
import { WORDS } from "./workshop.mjs";

const facts = JSON.parse(readFileSync(new URL("./facts.json", import.meta.url), "utf8"));

/** §11.7's launch Sages and the Keeper level each unlocks at, read from the
 *  table's "Unlocks" column ("Start" is level 1). */
/** §12.5: the most crew a Keeper of `level` brings, and the cast slots. */
export const crewMost = (level) => facts.CREW_BY_KEEPER.filter(([, from]) => level >= from).at(-1)[0];
export const castSlots = (level) => facts.CAST_SLOTS.filter(([, from]) => level >= from).at(-1)[0];

/** §12.5's planning at Keeper level `level`: the most crew, the cast slots,
 *  whether a Sage may go, and the load targets (from, to, step), for the
 *  device's planner. */
export const planning = (level) => ({ crew: crewMost(level), casts: castSlots(level),
                                      sage: level >= facts.SAGE_FROM_KEEPER, load: facts.LOAD_TARGETS });

export const SAGES = JSON.parse(readFileSync(new URL("../../content/sages.json", import.meta.url), "utf8"))
  .map((s) => ({ id: s.id, unlocksAt: s.unlocks === "Start" ? 1 : Number(/Keeper level (\d+)/.exec(s.unlocks)[1]) }));

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
  /** `also`, from a heist: the raids played with it and the raider's
   *  rating, columns of the same row written in the same UPDATE
   *  (service.grant). */
  award(account, xp, also = {}) {
    const row = this.db.prepare("SELECT keeper_level, keeper_xp FROM accounts WHERE id = ?").get(account);
    const next = climb(row.keeper_level, row.keeper_xp, xp);
    this.db.prepare(`UPDATE accounts SET ${["keeper_level", "keeper_xp", ...Object.keys(also)].map((k) => `${k} = ?`)
      .join(", ")} WHERE id = ?`).run(next.level, next.have, ...Object.values(also), account);
    return { gained: counted(row.keeper_level, row.keeper_xp, xp), level: next.level, xp: next.have,
             toNext: this.toNext(next.level), levelled: next.level - row.keeper_level };
  }

  /** The experience from `level` to the next, or null at the top. */
  toNext(level) {
    return level < KEEPER_LEVEL_CAP ? facts.KEEPER_XP_TO_NEXT[level - 1] : null;
  }

  /** §11.7's Sages for one player: each with the Keeper level it unlocks
   *  at and whether it has, the Sages' level — the Keeper's — and the one
   *  stationed at the Heart as its guardian, if any. */
  sages(account) {
    const row = this.db.prepare("SELECT keeper_level, guardian_sage FROM accounts WHERE id = ?").get(account);
    return { level: row.keeper_level, guardian: row.guardian_sage ?? null,
             sages: SAGES.map((s) => ({ id: s.id, unlocks_at: s.unlocksAt, unlocked: row.keeper_level >= s.unlocksAt,
                                         guardian: row.guardian_sage === s.id })) };
  }

  /** §11.7: "can station another at the Heart as its guardian" — one Sage the
   *  Keeper has unlocked, or none (`sage` null). */
  setGuardian(account, sage) {
    if (sage !== null) {
      const s = SAGES.find((x) => x.id === sage);
      if (!s) throw new Refused(404, "no_such_sage");
      const level = this.db.prepare("SELECT keeper_level FROM accounts WHERE id = ?").get(account).keeper_level;
      if (level < s.unlocksAt) throw new Refused(409, "sage_locked", { unlocks_at: s.unlocksAt });
    }
    this.db.prepare("UPDATE accounts SET guardian_sage = ? WHERE id = ?").run(sage, account);
    return this.sages(account);
  }

  /** Why a replay's crew breaks §12.5's planning for the raider's Keeper
   *  level, or null: more crew than the level brings, more casts than its
   *  slots, or a Sage before level 2, not yet unlocked, or the one stationed
   *  at the Heart as its guardian (§11.7: "A player brings one Sage on each
   *  heist, and can station another at the Heart"). */
  planProblem(account, header, manifest) {
    const row = this.db.prepare("SELECT keeper_level, guardian_sage FROM accounts WHERE id = ?").get(account);
    if (header.crew > crewMost(row.keeper_level)) return "crew_too_large";
    if (!manifest) return null;
    if (manifest.casts.length > castSlots(row.keeper_level)) return "too_many_casts";
    if (manifest.sage) {
      const s = SAGES[manifest.sage - 1];
      if (!s || row.keeper_level < facts.SAGE_FROM_KEEPER || row.keeper_level < s.unlocksAt) return "sage_locked";
      if (row.guardian_sage === s.id) return "sage_on_guard";
    }
    return null;
  }

  /** G58: the Keeper's name, picked from the word lists at every age, as
   *  {adjective, noun} indexes; null before one is picked. */
  name(account) {
    const row = this.db.prepare("SELECT keeper_adjective, keeper_noun FROM accounts WHERE id = ?").get(account);
    return row?.keeper_adjective == null ? null : { adjective: row.keeper_adjective, noun: row.keeper_noun };
  }

  /** G58: the name the first launch picked, kept on the phone until the
   *  account was made, from the word lists only. */
  setName(account, { adjective, noun }) {
    if (!Number.isInteger(adjective) || !Number.isInteger(noun)
        || !WORDS.adjectives[adjective] || !WORDS.nouns[noun]) {
      throw new Refused(400, "name_not_from_the_word_lists");
    }
    this.db.prepare("UPDATE accounts SET keeper_adjective = ?, keeper_noun = ? WHERE id = ?").run(adjective, noun, account);
    return this.name(account);
  }

  /** A player's Keeper level and the bar toward the next. */
  view(account) {
    const row = this.db.prepare("SELECT keeper_level, keeper_xp FROM accounts WHERE id = ?").get(account);
    return { level: row.keeper_level, xp: row.keeper_xp, toNext: this.toNext(row.keeper_level),
             cap: KEEPER_LEVEL_CAP };
  }
}
