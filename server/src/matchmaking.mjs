// How a target is chosen (§12.3, §12.22).
//
// §12.22's steps: the band (Renown within 150, Keeper level two below to three
// above as the owner decided (F44), an
// island difficulty rating within one band of the raider's recent success
// rate, and depth); the rating (Glicko-2, glicko.mjs, with the simulator's
// prior for a new island); the guarantee ("the middle of the list is drawn
// from the raider-success band for the target's realm level"); and a thin
// band (echoes, then generated fallbacks, then the filters widened in
// order). §12.3 adds the protections: a new player cannot be raided for 72
// hours or until they raid, and a robbed player may Trace the raider once
// within 24 hours with no entry fee.
//
// Ratings are kept here; the list a raider is offered is `offer`, a pure
// function of the raider and the candidates, so the device can run the same
// steps on a downloaded target list (§24.8's "a file, not a query").

import { readFileSync } from "node:fs";

import { chapterOf, openChapter } from "./codex.mjs";
import { expected, fresh, ratingFor, update } from "./glicko.mjs";
import { GENERATOR } from "./generator.mjs";
import { Refused } from "./refused.mjs";
import { lawsOf } from "./telemetry.mjs";

const facts = JSON.parse(readFileSync(new URL("./facts.json", import.meta.url), "utf8"));
const HOUR_MS = 60 * 60 * 1000;
const DAY_MS = 24 * HOUR_MS;

const [RENOWN_WINDOW, KEEPER_WINDOW] = facts.MATCH_WINDOW;

/** A heist that raided a player (§12.3), as SQL on its lease `l`: a raid on
 *  a current island, not an echo, which "takes nothing from its owner", nor
 *  §12.11's friendly heist or §17.6's challenge ("the friend loses
 *  nothing"), nor §13.1's seeded islands, "the game's own" (G30). */
const RAIDED = `l.mode = 'raid' AND l.echo = 0
  AND NOT EXISTS (SELECT 1 FROM accounts d WHERE d.id = l.defender AND d.seeded = 1)`;

/**
 * The raider-success band a target is judged against, as fractions.
 * §12.22: "Every island carries its origin, authored or generated, and is
 * judged against that origin's band". A generated island's is "55 to 70% at
 * every realm level" (v3.7), and an authored island's is what §13.2's authored
 * hold band leaves the raider.
 */
export function successBand(realmLevel, origin = "authored") {
  if (origin === "authored") {
    const [lo, hi] = facts.HOLD_BAND;
    return [(100 - hi) / 100, (100 - lo) / 100];
  }
  const [lo, hi] = facts.RAIDER_SUCCESS;
  return [lo / 100, hi / 100];
}

/** A band's width: how far "one band" reaches from the raider's recent
 *  success rate (G30). */
export const BAND_WIDTH = 0.15;

/** A raider's "recent success rate": their last twenty validated heists,
 *  and a new raider's is the middle of the authored band (G30). */
export const RECENT = 20;

/**
 * §12.22's prior: "its hold rate against the reference crews (13.4),
 * converted to the rating scale". The reference crews are the Python
 * harness's, not the simulation's (D66), so a new island's hold rate is read
 * as the middle of its band until they are: a raider at the centre of the
 * scale succeeds against it at the band's middle.
 */
export function prior(realmLevel, origin = "authored") {
  const [lo, hi] = successBand(realmLevel, origin);
  return fresh(ratingFor((lo + hi) / 2));
}

export class Matchmaking {
  constructor(service) {
    this.service = service;
    /** Each bundle's chapter, by its hash (§7.6). */
    this.chapters = new Map();
  }

  get db() { return this.service.db; }

  rating(kind, key) {
    const r = this.db.prepare("SELECT * FROM ratings WHERE kind = ? AND key = ?").get(kind, key);
    return r ? { rating: r.rating, deviation: r.deviation, volatility: r.volatility, games: r.games } : null;
  }

  raiderRating(account) {
    return this.rating("raider", account) ?? { ...fresh(), games: 0 };
  }

  islandKey(owner, realm) { return `${owner}/${realm}`; }

  islandRating(owner, realm) {
    return this.rating("island", this.islandKey(owner, realm));
  }

  store(kind, key, r, now) {
    this.db.prepare(
      `INSERT INTO ratings (kind, key, rating, deviation, volatility, games, updated_at)
       VALUES (?, ?, ?, ?, ?, ?, ?)
       ON CONFLICT (kind, key) DO UPDATE SET rating = excluded.rating, deviation = excluded.deviation,
         volatility = excluded.volatility, games = excluded.games, updated_at = excluded.updated_at`)
      .run(kind, key, r.rating, r.deviation, r.volatility, r.games ?? 0, now);
  }

  /** A published island's rating: the prior for a new one; a republished
   *  one keeps its mean and widens back to the prior's deviation, since the
   *  defence it measured has changed (G30). */
  published(owner, realm, realmLevel, now, origin = "authored") {
    const had = this.islandRating(owner, realm);
    const start = prior(realmLevel, origin);
    const r = had ? { ...had, deviation: Math.max(had.deviation, start.deviation) } : { ...start, games: 0 };
    this.store("island", this.islandKey(owner, realm), r, now);
  }

  /** One validated heist, its own rating period for both sides: the raider
   *  scores 1 unless foiled (G30). An echo rates the raider only, against
   *  the island's rating as it stands. */
  settle(lease, realm, verdict, now, { raiderOnly = false } = {}) {
    // An island published before there were ratings enters at its prior.
    const island = this.islandRating(lease.defender, realm) ?? { ...prior(this.db.prepare(
      "SELECT realm_level FROM snapshots WHERE bundle = ?").get(lease.bundle).realm_level), games: 0 };
    const raider = this.raiderRating(lease.attacker);
    const score = verdict.grade === "foiled" ? 0 : 1;
    const r = update(raider, [{ opponent: island, score }]);
    const i = update(island, [{ opponent: raider, score: 1 - score }]);
    this.store("raider", lease.attacker, { ...r, games: raider.games + 1 }, now);
    if (raiderOnly) return { raider: Math.round(r.rating), island: Math.round(island.rating) };
    this.store("island", this.islandKey(lease.defender, realm), { ...i, games: island.games + 1 }, now);
    return { raider: Math.round(r.rating), island: Math.round(i.rating) };
  }

  /** The raider's recent success rate, over the heists that rate them: raids,
   *  not games among friends, so the rating and "recent" learn from the same
   *  heists (G30). */
  recentSuccess(account) {
    const rows = this.db.prepare(
      `SELECT h.outcome FROM heists h JOIN leases l ON l.token = h.token
        WHERE h.attacker = ? AND h.validated = 1 AND l.mode = 'raid'
        ORDER BY h.submitted_at DESC, h.rowid DESC LIMIT ?`).all(account, RECENT);
    if (rows.length === 0) {
      const [lo, hi] = successBand(1, "authored");
      return (lo + hi) / 2;
    }
    return rows.filter((r) => JSON.parse(r.outcome).verdict.grade !== "foiled").length / rows.length;
  }

  // -- the protections (§12.3) -------------------------------------------------

  /** "New players can't be raided by other players for their first 72
   *  hours, or until they raid a player themselves." */
  shielded(account, now = this.service.now()) {
    const a = this.db.prepare("SELECT created_at, seeded FROM accounts WHERE id = ?").get(account);
    if (!a || a.seeded || now - a.created_at >= facts.NEW_PLAYER_SHIELD_HOURS * HOUR_MS) return false;
    const raided = this.db.prepare(
      `SELECT 1 FROM heists h JOIN leases l ON l.token = h.token
        WHERE h.attacker = ? AND h.validated = 1 AND ${RAIDED} LIMIT 1`).get(account);
    return !raided;
  }

  /** §12.3's Trace: "within 24 hours of being robbed, a player can target
   *  the raider once, with a free scout and no entry fee". Robbed: a raid
   *  on their island that was not foiled. The heist it answers, or null. */
  traceable(account, raider, now = this.service.now()) {
    return this.db.prepare(
      `SELECT h.token FROM heists h JOIN leases l ON l.token = h.token
        WHERE h.attacker = ? AND l.defender = ? AND h.validated = 1 AND ${RAIDED}
          AND json_extract(h.outcome, '$.verdict.grade') != 'foiled'
          AND COALESCE(json_extract(h.outcome, '$.haul.cappedBy'), '') != 'week'
          AND h.submitted_at > ?
          AND NOT EXISTS (SELECT 1 FROM leases t WHERE t.trace_of = h.token)
        ORDER BY h.submitted_at DESC LIMIT 1`)
      .get(raider, account, now - facts.TRACE_HOURS * HOUR_MS)?.token ?? null;
  }

  // -- the candidates and the offer (§12.22) ------------------------------------

  /**
   * Every live candidate: each current island of a player who is not banned,
   * deleted or shielded, with what `offer` filters and orders by. And the
   * echoes (§12.3): "snapshots of real universes from the last 14 days"
   * that are no longer anyone's current island.
   */
  candidates(now = this.service.now()) {
    const live = this.db.prepare(
      `SELECT s.bundle, i.owner, i.realm, s.realm_level, a.keeper_level, i.origin
         FROM islands i JOIN snapshots s ON s.bundle = i.bundle JOIN accounts a ON a.id = i.owner
        WHERE a.banned_at IS NULL AND a.deleted_at IS NULL ORDER BY s.bundle, i.owner`).all();
    const echoes = this.db.prepare(
      `SELECT s.bundle, s.owner, s.realm, s.realm_level, a.keeper_level, s.origin
         FROM snapshots s JOIN accounts a ON a.id = s.owner
        WHERE s.published_at > ? AND a.banned_at IS NULL AND a.deleted_at IS NULL
          AND s.owner != ?
          AND NOT EXISTS (SELECT 1 FROM islands i WHERE i.bundle = s.bundle)
        ORDER BY s.bundle`).all(now - facts.ECHO_DAYS * DAY_MS, GENERATOR);
    // A bundle never changes (§24.8), so its chapter is worked out once.
    const chapter = (bundle) => {
      if (!this.chapters.has(bundle)) this.chapters.set(bundle, chapterOf(lawsOf(this.service.store.get(bundle))));
      return this.chapters.get(bundle);
    };
    const view = (r, echo) => {
      // §13.3: a player's curated layout is judged as generated too.
      const origin = r.origin ?? (r.owner === GENERATOR ? "generated" : "authored");
      const rating = this.islandRating(r.owner, r.realm) ?? prior(r.realm_level, origin);
      return {
        bundle: r.bundle, owner: r.owner, realm: r.realm, realmLevel: r.realm_level,
        keeperLevel: r.keeper_level, renown: this.service.seasons.league(r.owner, now).renown,
        rating: rating.rating, deviation: rating.deviation, echo, chapter: chapter(r.bundle),
        origin,
      };
    };
    return [
      ...live.filter((r) => !this.shielded(r.owner, now)).map((r) => view(r, false)),
      // The protection covers a new player's echoes too (G30).
      ...echoes.filter((r) => !this.shielded(r.owner, now)).map((r) => view(r, true)),
    ];
  }

  /** The raider as `offer` needs them. */
  raider(account, now = this.service.now()) {
    const r = this.raiderRating(account);
    const keeperLevel = this.db.prepare("SELECT keeper_level FROM accounts WHERE id = ?").get(account).keeper_level;
    return {
      account, rating: r.rating, deviation: r.deviation,
      renown: this.service.seasons.league(account, now).renown,
      keeperLevel, chapter: openChapter(keeperLevel),
      recent: this.recentSuccess(account),
      // A bundle is one snapshot however many players publish it: one they
      // hold is their own island.
      bundles: this.db.prepare("SELECT bundle FROM islands WHERE owner = ?").all(account).map((r) => r.bundle),
    };
  }
}

/**
 * §12.22's list for one raider, from any candidates — pure, so the device
 * can run it on a target list. Three targets unless asked for more (§12.3's
 * Observatory: "3 universes (5 at level 5)").
 *
 * Step 1 filters; step 3 sorts by predicted success and draws the middle
 * from the raider-success band of the target's realm level; step 4, when
 * fewer than three candidates sit in the band, counts echoes, then the
 * game's generated islands (generator.mjs), and only then widens the
 * filters in order: rating, then Keeper level, then Renown. The list says
 * when it reached for echoes, for generated islands, and what it widened.
 */
export function offer(raider, candidates, { size = 3 } = {}) {
  const own = new Set(raider.bundles ?? []);
  // §7.6: "Matchmaking only shows universes running laws from open
  // chapters" — a rule, never a filter step 4 widens.
  const others = candidates.filter((c) => c.owner !== raider.account && !own.has(c.bundle)
    && (c.chapter ?? 1) <= (raider.chapter ?? Infinity));
  const predicted = (c) => expected(raider, c);
  const inBand = (c) => {
    const [lo, hi] = successBand(c.realmLevel, c.origin);
    const p = predicted(c);
    return p >= lo && p <= hi;
  };
  const filters = {
    rating: (c) => Math.abs(predicted(c) - raider.recent) <= BAND_WIDTH,
    keeper: (c) => c.keeperLevel - raider.keeperLevel >= -KEEPER_WINDOW[0]
      && c.keeperLevel - raider.keeperLevel <= KEEPER_WINDOW[1],
    renown: (c) => Math.abs(c.renown - raider.renown) <= RENOWN_WINDOW,
  };
  const widened = [];
  const pass = (pool) => pool.filter((c) => Object.entries(filters)
    .every(([name, f]) => widened.includes(name) || f(c)));
  const enough = (pool) => pool.filter(inBand).length >= facts.THIN_BAND;
  const authored = others.filter((c) => c.origin !== "generated");
  const liveOnly = authored.filter((c) => !c.echo);
  let pool = pass(liveOnly);
  let echoes = false;
  let generated = false;
  if (!enough(pool)) {
    pool = pass(authored);
    echoes = true;
  }
  if (!enough(pool) && others.length > authored.length) {
    pool = pass(others);
    generated = true;
  }
  const reach = () => (generated ? others : echoes ? authored : liveOnly);
  for (const name of ["rating", "keeper", "renown"]) {
    if (enough(pool) || pool.length >= reach().length) break;
    widened.push(name);
    pool = pass(reach());
  }
  // Step 3: by predicted success, easiest first; the middle from the band.
  const sorted = pool.map((c) => ({ ...c, predicted: predicted(c) }))
    .sort((a, b) => b.predicted - a.predicted || (a.bundle < b.bundle ? -1 : a.bundle > b.bundle ? 1 : 0)
      || (a.owner < b.owner ? -1 : a.owner > b.owner ? 1 : 0));
  const banded = sorted.filter(inBand);
  const centre = (c) => {
    const [lo, hi] = successBand(c.realmLevel, c.origin);
    return Math.abs(c.predicted - (lo + hi) / 2);
  };
  const middle = [...banded].sort((a, b) => centre(a) - centre(b))[0] ?? null;
  let list = sorted;
  if (middle) {
    const i = sorted.indexOf(middle);
    const half = Math.floor(size / 2);
    const easier = sorted.slice(0, i).slice(-half);
    const harder = sorted.slice(i + 1).slice(0, size - 1 - easier.length);
    const more = sorted.slice(0, i - easier.length).reverse();
    list = [...easier, middle, ...harder];
    while (list.length < size && more.length) list.unshift(more.shift());
  }
  const targets = list.slice(0, size);
  // Guaranteed only when the list's middle entry sits in the band: when
  // `middle` is the easiest or hardest there is, a neighbour takes the
  // middle (§12.22 step 4: never "silently unfair").
  const median = targets[Math.floor(targets.length / 2)];
  return { targets, guaranteed: Boolean(median) && inBand(median), echoes, generated, widened };
}
