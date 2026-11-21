// The Island Workshop (§18.6, §18.7, §20.4, §20.7, §20.10, §20.12): publish,
// browse, play, rate, report, moderate and remix player-made islands.
//
// §18.6: "a free sandbox … where they build islands and publish them as heist
// puzzles for anyone to play." An item is structured data only — an island
// bundle, never a file or an image (§20.10) — and the simulation judges it the
// same way it judges a realm: `Island::check` for what may be built, and a
// re-simulated replay for whether it was cleared.
//
// What the Workshop pays is completions, not currency: nothing is staked on a
// play and nothing minted (§18.7's ladder, "no power").

import { readFileSync } from "node:fs";

import { banIdentity } from "./accounts.mjs";
import { transaction } from "./db.mjs";
import { readHeader } from "./sim.mjs";
import { Refused, clockTicks } from "./service.mjs";
import { Social } from "./social.mjs";
import { sha256 } from "./store.mjs";

export const WORDS = JSON.parse(readFileSync(new URL("./words.json", import.meta.url), "utf8"));
const facts = JSON.parse(readFileSync(new URL("./facts.json", import.meta.url), "utf8"));

/** Whether `player` and `creator` shared a constellation at any time since
 *  `published`, the two memberships overlapping each other and it: §18.7's
 *  "a creator's own constellation", which the Island Fund reads too
 *  (fund.mjs). */
export function kin(db, player, creator, published) {
  return Boolean(db.prepare(
    `SELECT 1 FROM constellation_members a JOIN constellation_members b
       ON a.constellation = b.constellation
      WHERE a.account = :player AND b.account = :creator
        AND (a.left_at IS NULL OR a.left_at > MAX(b.joined_at, :published))
        AND (b.left_at IS NULL OR b.left_at > MAX(a.joined_at, :published))`)
    .get({ player, creator, published }));
}

const HOUR_MS = 60 * 60 * 1000;
const DAY_MS = 24 * HOUR_MS;

/** §20.12: "Between five and ten published islands per account"; §18.7's
 *  Builder adds "3 extra island slots". Five is the floor the range allows,
 *  so a Builder holds eight, inside it. */
export const SLOTS = 5;
export const BUILDER_SLOTS = 3;

/** §20.12: "a storage quota per account … enforced at the point of upload".
 *  The size is not given; the owner decided 1 MiB (G26), a figure that does
 *  not bite — an island is under a kilobyte. Items are never deleted, so the
 *  quota counts everything ever published. */
export const QUOTA_BYTES = 1024 * 1024;

/** §18.7's ladder, by weighted completions across a creator's islands and
 *  islands featured. Builder is "publishing an island anyone completes". */
export const LADDER = [
  ["loremaker", { completions: 100_000, featured: 3 }],
  ["architect", { completions: 10_000, featured: 1 }],
  ["wright", { completions: 1_000, featured: Infinity }],
  ["builder", { completions: 1, featured: Infinity }],
];

/** §18.7: "sudden spikes are reviewed by a person". A spike is read as a day
 *  with at least this many completions and more than five times the item's
 *  daily mean over the week before (G26). */
export const SPIKE_MIN = 50;
export const SPIKE_FACTOR = 5;

/** SEC-26: one person's many accounts must not lift a creator. A completion,
 *  a rating or a play's time counts toward the ladder, the public numbers and
 *  the Island Fund only from an account at least this old and at this Keeper
 *  level when it is recorded; others are recorded and shown as uncounted. */
export const COUNTED_AGE_MS = 7 * DAY_MS;
export const COUNTED_KEEPER_LEVEL = 3;
/** SEC-26: of the accounts that have played only one creator's islands, at
 *  most this many completions (and ratings) a UTC day count for that creator. */
export const LONE_FANS_A_DAY = 3;

/** The most plays a player may hold unsubmitted from a day (SR-19). */
export const MOST_OPEN_PLAYS = 50;

/** §20.4: "reports reviewed by a person within 24 hours". */
export const REVIEW_MS = DAY_MS;

/** What a player may report an island for. §18.6 says every island can be
 *  reported and not for what (G26). */
export const REPORT_REASONS = ["unfair", "unplayable", "copied", "offensive", "other"];

/** Why a moderator may remove one — the reason §20.11's Digital Services Act
 *  gives "to anyone whose content is restricted". */
export const REMOVAL_REASONS = ["unfair", "unplayable", "copied", "offensive", "ban"];

/** A replay that clears an island: loot banked and out, so every grade but
 *  foiled. §18.6's "cleared" is read as solved (G26). */
const clears = (verdict) => verdict.grade !== "foiled" && verdict.banked > 0;

export class Workshop {
  constructor(service) {
    this.service = service;
  }

  get db() { return this.service.db; }
  now() { return this.service.now(); }

  /** The name an item carries, in each of the game's languages (§20.6, and
   *  the owner's six): in English the adjective first, its US spelling where
   *  it differs; in Portuguese and French the noun first and the adjective
   *  agreeing with its gender; in German the adjective first, in the strong
   *  ending for the noun's gender. words.json holds each language's forms
   *  (tools/english_us.py writes the US English). */
  static name(adjective, noun) {
    const a = WORDS.adjectives[adjective];
    const n = WORDS.nouns[noun];
    return {
      en: `${a.en} ${n.en}`,
      en_US: `${a.en_US ?? a.en} ${n.en_US ?? n.en}`,
      pt_BR: `${n.pt_BR} ${a.pt_BR[n.gender]}`,
      pt_PT: `${n.pt_PT} ${a.pt_PT[n.pt_PT_gender]}`,
      de: `${a.de[n.de_gender]} ${n.de}`,
      fr: `${n.fr} ${a.fr[n.fr_gender]}`,
    };
  }

  account(id) {
    return this.db.prepare("SELECT * FROM accounts WHERE id = ?").get(id);
  }

  /** §20.5's age band, declared at the neutral age gate (§20.11). §20.1:
   *  "After the first answer the band can only tighten from the device …
   *  the server refuses any other loosening": the first answer sets it,
   *  and after it a looser band is refused, the band held as it was. */
  setAgeBand(account, band) {
    const order = ["13-15", "16-17", "18+"];
    if (!order.includes(band)) throw new Refused(400, "no_such_age_band");
    const was = this.db.prepare("SELECT age_band, age_answered_at FROM accounts WHERE id = ?").get(account);
    if (was.age_answered_at !== null && order.indexOf(band) > order.indexOf(was.age_band)) {
      throw new Refused(403, "age_band_only_tightens", { ageBand: was.age_band });
    }
    this.db.prepare("UPDATE accounts SET age_band = ?, age_answered_at = COALESCE(age_answered_at, ?) WHERE id = ?")
      .run(band, this.now(), account);
    return { ageBand: band };
  }

  // -- publishing --------------------------------------------------------------

  /**
   * §18.6: "an island must be cleared by its creator before it can be
   * published, so every island can be solved." `replay` is the creator's own
   * heist on `bundle`, which the server re-simulates; the island must also be
   * one the simulation allows (§5.2, §6.1), its name from the word lists, and
   * the creator inside their slots and quota (§20.12).
   */
  publish(creator, bundle, replay, { adjective, noun, remixOf = null } = {}) {
    const me = this.account(creator);
    if (me.banned_at) throw new Refused(403, "banned");
    this.service.safety.requireTerms(creator);
    if (!Number.isInteger(adjective) || !Number.isInteger(noun)
        || !WORDS.adjectives[adjective] || !WORDS.nouns[noun]) {
      throw new Refused(400, "name_not_from_the_word_lists");
    }
    // Before the island is checked and the replay re-simulated, so a remix
    // of nothing costs no simulation (SEC-44).
    if (remixOf !== null) {
      const parent = this.db.prepare("SELECT removed_at FROM workshop_items WHERE id = ?").get(remixOf);
      if (!parent || parent.removed_at) throw new Refused(404, "no_such_island");
    }
    const build = this.service.builds.current;
    const read = build.island(bundle);
    if (read.error) throw new Refused(400, read.error);
    if (read.problems.length) throw new Refused(422, "island_not_publishable", { problems: read.problems });
    // An island another creator lists, or one taken down, is not listed
    // again unchanged as someone else's (SEC-41). Before the replay is
    // re-simulated, so a copy costs no simulation. One its creator withdrew
    // is theirs no longer to show, and the same bytes may be listed again.
    const listedElsewhere = this.db.prepare(
      `SELECT 1 FROM workshop_items WHERE bundle = ? AND creator != ?
          AND (withdrawn_at IS NULL OR removed_at IS NOT NULL) LIMIT 1`).get(read.digest, creator);
    if (listedElsewhere) throw new Refused(409, remixOf !== null ? "remix_unchanged" : "already_published");
    // Nor by its own creator once a moderator took it down: the removal
    // takes the island out of the Workshop (§18.7, RB-30). The reason is
    // one the client already has words for in every language.
    const takenDown = this.db.prepare(
      `SELECT 1 FROM workshop_items WHERE bundle = ? AND creator = ? AND removed_at IS NOT NULL LIMIT 1`)
      .get(read.digest, creator);
    if (takenDown) throw new Refused(409, "island_withdrawn");

    const header = readHeader(replay);
    if (!header || header.island !== read.digest) throw new Refused(422, "not_cleared", { why: "wrong_island" });
    if (header.ticks !== clockTicks(0)) throw new Refused(422, "not_cleared", { why: "wrong_clock" });
    // The Workshop is out of the weeks' eras (G36): an island cleared in
    // one week stays solvable in every other.
    if (header.era !== 0) throw new Refused(422, "not_cleared", { why: "an_era" });
    const player = this.service.builds.get(header.rules);
    if (!player) throw new Refused(422, "not_cleared", { why: "rules_not_held" });
    const result = player.verify(replay, bundle);
    if (result.status !== "verified" || !clears(result.verdict)) {
      throw new Refused(422, "not_cleared", { why: result.reason ?? result.status,
                                             grade: result.verdict?.grade });
    }

    const stored = Number(this.db.prepare(
      "SELECT COALESCE(SUM(bytes), 0) AS n FROM workshop_items WHERE creator = ?").get(creator).n);
    const live = this.db.prepare(
      `SELECT COUNT(*) AS n FROM workshop_items
        WHERE creator = ? AND withdrawn_at IS NULL AND removed_at IS NULL`).get(creator).n;
    if (live >= this.slots(creator)) throw new Refused(409, "no_free_slot", { slots: this.slots(creator) });
    if (stored + bundle.length > QUOTA_BYTES) throw new Refused(413, "quota_full");

    const key = this.service.store.put(bundle, read.digest);
    const id = this.service.random(8).toString("hex");
    this.db.prepare(
      `INSERT INTO workshop_items (id, creator, bundle, realm_level, name_adjective, name_noun,
                                   remix_of, cleared_by, bytes, published_at)
       VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)`)
      .run(id, creator, key, bundle[4], adjective, noun, remixOf, sha256(replay), bundle.length,
           this.now());
    return this.view(this.row(id));
  }

  /** A creator's standing slots: §20.12's floor, and §18.7's Builder three. */
  slots(creator) {
    return SLOTS + (this.ladder(creator).level !== null ? BUILDER_SLOTS : 0);
  }

  /** §18.6: withdrawn, never deleted: it leaves the lists and its slot frees. */
  withdraw(creator, id) {
    const item = this.row(id);
    if (!item || item.creator !== creator) throw new Refused(404, "no_such_island");
    if (!item.withdrawn_at) {
      this.db.prepare("UPDATE workshop_items SET withdrawn_at = ? WHERE id = ?").run(this.now(), id);
    }
    return this.view(this.row(id));
  }

  row(id) {
    return this.db.prepare("SELECT * FROM workshop_items WHERE id = ?").get(id);
  }

  /** Listed: not withdrawn, not removed, and its creator not banned. */
  listed(item) {
    return item && !item.withdrawn_at && !item.removed_at && !this.account(item.creator).banned_at;
  }

  view(item) {
    const completions = Number(this.db.prepare(
      "SELECT COALESCE(SUM(weight), 0) AS n FROM workshop_completions WHERE item = ? AND counted = 1").get(item.id).n);
    const r = this.db.prepare(
      `SELECT COUNT(*) AS n, AVG(fun) AS fun, AVG(cleverness) AS cleverness,
              AVG(fairness) AS fairness FROM workshop_ratings WHERE item = ? AND counted = 1`).get(item.id);
    // SEC-26: recorded but not counted: from players too new or too low
    // when they played (`qualified`), or past a day's lone fans (`counts`).
    const uncounted = (table) => this.db.prepare(
      `SELECT COUNT(*) AS n FROM ${table} WHERE item = ? AND counted = 0`).get(item.id).n;
    const remixes = this.db.prepare(
      "SELECT COUNT(*) AS n FROM workshop_remixes WHERE item = ?").get(item.id).n;
    // A deleted creator's island stays listed with no creator shown (F43).
    const gone = Boolean(this.account(item.creator)?.deleted_at);
    const creator = gone ? null : this.ladder(item.creator).level;
    return {
      id: item.id, bundle: item.bundle, realmLevel: item.realm_level,
      name: Workshop.name(item.name_adjective, item.name_noun),
      // §18.7: a Builder's "name shown on the island". Accounts have no
      // display name yet, so the creator is shown by account and level.
      creator: gone ? null : item.creator, creatorLevel: creator,
      remixOf: item.remix_of, completions, remixes,
      ratings: { count: r.n, fun: r.fun, cleverness: r.cleverness, fairness: r.fairness },
      uncounted: { completions: uncounted("workshop_completions"), ratings: uncounted("workshop_ratings") },
      featured: item.featured_at !== null, publishedAt: item.published_at,
      withdrawn: item.withdrawn_at !== null,
      removed: item.removed_at !== null ? { at: item.removed_at, reason: item.removed_reason } : null,
    };
  }

  // -- browsing ----------------------------------------------------------------

  /**
   * The Workshop's lists. "featured" is the weekly spotlight a person chose;
   * "top" orders by completions (§18.7: "counting how many people finished
   * an island rewards islands that are fun to play"); "new" by publishing.
   * §20.7: a player aged 13 to 15 browses "curated lists only" — the
   * featured list.
   */
  browse(viewer, list = "top", limit = 20) {
    if (!["featured", "top", "new"].includes(list)) throw new Refused(400, "no_such_list");
    if (this.account(viewer).age_band === "13-15" && list !== "featured") {
      throw new Refused(403, "curated_lists_only");
    }
    const order = {
      featured: "i.featured_at DESC, i.id",
      top: "completions DESC, i.published_at DESC, i.id",
      new: "i.published_at DESC, i.id",
    }[list];
    const rows = this.db.prepare(
      `SELECT i.*, COALESCE((SELECT SUM(weight) FROM workshop_completions c WHERE c.item = i.id AND c.counted = 1), 0)
                AS completions
         FROM workshop_items i JOIN accounts a ON a.id = i.creator
        WHERE i.withdrawn_at IS NULL AND i.removed_at IS NULL AND a.banned_at IS NULL
          AND NOT EXISTS (SELECT 1 FROM blocks b WHERE (b.blocker = :viewer AND b.blocked = i.creator)
                                                    OR (b.blocker = i.creator AND b.blocked = :viewer))
          ${list === "featured" ? "AND i.featured_at IS NOT NULL" : ""}
        ORDER BY ${order} LIMIT :limit`).all({ viewer, limit: Math.max(1, Math.min(100, limit)) });
    return rows.map((r) => this.view(r));
  }

  /** §20.7: a player aged 13 to 15 has "curated lists only", so plays and
   *  remixes only an island a person featured, or their own — not one
   *  reached by its id from elsewhere, such as a featured remix's original
   *  (SR-18). Reporting is never held back. */
  curated(player, item) {
    if (item.creator !== player && item.featured_at === null && this.account(player).age_band === "13-15") {
      throw new Refused(403, "curated_lists_only");
    }
  }

  /** A creator's own islands, withdrawn and removed ones too, each removal
   *  with its reason (§20.11). */
  mine(creator) {
    return this.db.prepare("SELECT * FROM workshop_items WHERE creator = ? ORDER BY published_at")
      .all(creator).map((r) => this.view(r));
  }

  // -- playing -----------------------------------------------------------------

  /** A seed and a clock to play an item on, like a lease with nothing staked. */
  play(player, id) {
    const item = this.row(id);
    if (!this.listed(item)) throw new Refused(404, "no_such_island");
    if (this.account(player).banned_at) throw new Refused(403, "banned");
    this.curated(player, item);
    this.service.safety.requireTerms(player);
    // A play is a row kept for good (F43), so a day's unsubmitted ones are
    // held to MOST_OPEN_PLAYS, like the open invites (SR-19).
    const open = this.db.prepare(
      "SELECT COUNT(*) AS n FROM workshop_plays WHERE player = ? AND submitted_at IS NULL AND issued_at > ?")
      .get(player, this.now() - DAY_MS).n;
    if (open >= MOST_OPEN_PLAYS) throw new Refused(409, "too_many_open_plays", { most: MOST_OPEN_PLAYS });
    const row = {
      token: this.service.random(16).toString("hex"),
      player, item: id,
      seed: this.service.random(8).readBigUInt64LE(0).toString(),
      ticks: clockTicks(0),
      issued_at: this.now(),
    };
    this.db.prepare(
      `INSERT INTO workshop_plays (token, player, item, seed, ticks, issued_at)
       VALUES (:token, :player, :item, :seed, :ticks, :issued_at)`).run(row);
    return { token: row.token, bundle: item.bundle, seed: row.seed, ticks: row.ticks };
  }

  /**
   * A play, submitted and re-simulated. A clear by anyone but the creator is
   * a completion, counted once a player (§18.7), and at a quarter from the
   * creator's own constellation — one the two shared at any time since the
   * item was published, so leaving to complete it and coming back does not
   * escape the quarter. Idempotent, like a heist: the token keys the answer.
   */
  submitPlay(player, token, replay) {
    const play = this.db.prepare("SELECT * FROM workshop_plays WHERE token = ?").get(token);
    if (!play || play.player !== player) throw new Refused(403, "play_refused");
    if (play.outcome) return { ...JSON.parse(play.outcome), repeated: true };
    const item = this.row(play.item);
    const header = readHeader(replay);
    let outcome;
    if (!header) outcome = { validated: false, reason: "replay_malformed" };
    else if (header.island !== item.bundle) outcome = { validated: false, reason: "wrong_island" };
    else if (header.seed.toString() !== play.seed) outcome = { validated: false, reason: "wrong_seed" };
    else if (header.ticks !== play.ticks) outcome = { validated: false, reason: "wrong_clock" };
    else if (header.era !== 0) outcome = { validated: false, reason: "wrong_era" };
    // RB-35: a play is issued under the current rules (play() hands out no
    // other), so a replay naming an older build the server still holds is
    // refused, as a heist is against its lease (SEC-31).
    else if (header.rules !== this.service.builds.current.rulesVersion) {
      outcome = { validated: false, reason: "wrong_rules" };
    } else {
      const build = this.service.builds.get(header.rules);
      const island = this.service.store.get(item.bundle);
      const result = !build ? { status: "refused", reason: "rules_not_held" }
        : !island ? { status: "refused", reason: "island_withdrawn" }
        : build.verify(replay, island);
      // The event log's report rides along (TD.39): the Island Fund counts a
      // play's time from it (fund.mjs).
      outcome = result.status === "verified"
        ? { validated: true, verdict: result.verdict, cleared: clears(result.verdict),
            ...(result.report ? { report: { held: result.report.held } } : {}) }
        : { validated: false, reason: result.reason ?? result.status };
    }
    const now = this.now();
    // A play on an island withdrawn or taken down since it was issued is
    // answered as before, but earns its creator nothing (SEC-40).
    if (!this.listed(item) && outcome.validated) Object.assign(outcome, { counted: false, listed: false });
    return transaction(this.db, () => {
      if (outcome.cleared && player !== item.creator && outcome.listed !== false) {
        // §18.7: "completions from a creator's own constellation count at a
        // quarter" — any constellation both were in together in the item's
        // life, the two memberships overlapping each other and it.
        const mate = this.kin(player, item.creator, item.published_at);
        // SEC-26: recorded either way; on the ladder only from a player
        // who counts.
        const paid = this.counts("workshop_completions", player, item.creator, now);
        // RB-37: one completion per player, creator and island: the same
        // bytes listed again under another name are not a second completion.
        const copied = this.db.prepare(
          `SELECT 1 FROM workshop_completions c JOIN workshop_items i ON i.id = c.item
            WHERE c.player = ? AND i.creator = ? AND i.bundle = ? AND i.id <> ? AND i.removed_at IS NULL
            LIMIT 1`).get(player, item.creator, item.bundle, item.id);
        const fresh = copied ? 0 : this.db.prepare(
          `INSERT OR IGNORE INTO workshop_completions (item, player, weight, at, counted)
           VALUES (?, ?, ?, ?, ?)`).run(item.id, player, mate ? facts.KIN_COMPLETION_WEIGHT : 1, now, paid ? 1 : 0)
          .changes;
        outcome.counted = fresh === 1;
        if (fresh) {
          outcome.ladder = paid;            // false: recorded, not yet counted (SEC-26)
          this.spike(item.id, now);
        }
      }
      // SEC-26: the Island Fund counts a play's time only from a player who
      // counts (fund.mjs).
      const timed = outcome.validated && outcome.listed !== false && player !== item.creator
        && this.qualified(player, now);
      this.db.prepare("UPDATE workshop_plays SET submitted_at = ?, outcome = ?, counted = ? WHERE token = ?")
        .run(now, JSON.stringify(outcome), timed ? 1 : 0, token);
      return outcome;
    });
  }

  /** SEC-26: whether `player`'s account counts toward Workshop numbers that
   *  pay out: COUNTED_AGE_MS old and at COUNTED_KEEPER_LEVEL at `now`. */
  qualified(player, now) {
    const a = this.db.prepare("SELECT created_at, keeper_level FROM accounts WHERE id = ?").get(player);
    return Boolean(a) && now - a.created_at >= COUNTED_AGE_MS && a.keeper_level >= COUNTED_KEEPER_LEVEL;
  }

  /** SEC-26: whether a row of `table` (completions or ratings) `player`
   *  writes now for `creator` counts: a qualified player, and, for one who
   *  has played only this creator's islands, one of the creator's first
   *  LONE_FANS_A_DAY such rows of the UTC day. */
  counts(table, player, creator, now) {
    if (!this.qualified(player, now)) return false;
    const elsewhere = `EXISTS (SELECT 1 FROM workshop_plays p JOIN workshop_items j ON j.id = p.item
                                WHERE p.player = %s AND j.creator != :creator AND j.creator != %s
                                  AND json_extract(p.outcome, '$.validated') = 1)`;
    const others = this.db.prepare(`SELECT ${elsewhere.replaceAll("%s", ":player")} AS yes`).get({ player, creator });
    if (others.yes) return true;
    const from = Math.floor(now / DAY_MS) * DAY_MS;
    const lone = this.db.prepare(
      `SELECT COUNT(*) AS n FROM ${table} c JOIN workshop_items i ON i.id = c.item
        WHERE i.creator = :creator AND c.counted = 1 AND c.at >= :from AND c.at < :to AND c.player != :player
          AND NOT ${elsewhere.replaceAll("%s", "c.player")}`).get({ creator, from, to: from + DAY_MS, player }).n;
    return lone < LONE_FANS_A_DAY;
  }

  /** §18.7's constellation rule for this play's creator (`kin`). */
  kin(player, creator, published) {
    return kin(this.db, player, creator, published);
  }

  /** §18.7's "sudden spikes are reviewed by a person": the item is flagged
   *  and a report of the server's own joins the moderation queue. */
  spike(item, now) {
    const count = (from, to) => this.db.prepare(
      "SELECT COUNT(*) AS n FROM workshop_completions WHERE item = ? AND at >= ? AND at < ?")
      .get(item, from, to).n;
    const today = count(now - DAY_MS, now + 1);
    const week = count(now - 8 * DAY_MS, now - DAY_MS);
    const flagged = this.row(item).review;
    if (!flagged && today >= SPIKE_MIN && today > SPIKE_FACTOR * (week / 7)) {
      this.db.prepare("UPDATE workshop_items SET review = 1 WHERE id = ?").run(item);
      this.db.prepare(
        "INSERT INTO workshop_reports (item, reporter, reason, at) VALUES (?, NULL, ?, ?)")
        .run(item, "completion_spike", now);
    }
  }

  // -- ratings and reports -------------------------------------------------------

  /** §18.6: fun, cleverness and fairness, each 1 to 5, from a player who has
   *  played it — a validated play — and never its creator. A second rating
   *  replaces the first. */
  rate(player, id, { fun, cleverness, fairness } = {}) {
    const item = this.row(id);
    if (!this.listed(item)) throw new Refused(404, "no_such_island");
    if (item.creator === player) throw new Refused(409, "own_island");
    this.service.safety.requireTerms(player);
    const played = this.db.prepare(
      `SELECT 1 FROM workshop_plays WHERE player = ? AND item = ?
         AND json_extract(outcome, '$.validated') = 1`).get(player, id);
    if (!played) throw new Refused(409, "not_played");
    const score = [fun, cleverness, fairness];
    if (!score.every((v) => Number.isInteger(v) && v >= 1 && v <= 5)) {
      throw new Refused(400, "ratings_are_one_to_five");
    }
    // SEC-26: recorded either way; in the island's numbers only from a
    // player who counts, and once counted, counted still.
    const now = this.now();
    const paid = this.counts("workshop_ratings", player, item.creator, now) ? 1 : 0;
    this.db.prepare(
      `INSERT INTO workshop_ratings (item, player, fun, cleverness, fairness, at, counted)
       VALUES (?, ?, ?, ?, ?, ?, ?)
       ON CONFLICT (item, player) DO UPDATE SET fun = excluded.fun,
         cleverness = excluded.cleverness, fairness = excluded.fairness, at = excluded.at,
         counted = MAX(counted, excluded.counted)`)
      .run(id, player, fun, cleverness, fairness, now, paid);
    return this.view(this.row(id)).ratings;
  }

  /** §18.6: "every island can be reported". One open report a player an
   *  island; it waits for a person (§20.4). */
  report(player, id, reason) {
    const item = this.row(id);
    if (!item) throw new Refused(404, "no_such_island");
    if (!REPORT_REASONS.includes(reason)) throw new Refused(400, "no_such_reason");
    const open = this.db.prepare(
      "SELECT id FROM workshop_reports WHERE item = ? AND reporter = ? AND resolved_at IS NULL")
      .get(id, player);
    if (open) return { report: open.id, repeated: true };
    const r = this.db.prepare(
      "INSERT INTO workshop_reports (item, reporter, reason, at) VALUES (?, ?, ?, ?)")
      .run(id, player, reason, this.now());
    return { report: Number(r.lastInsertRowid) };
  }

  // -- remixing ----------------------------------------------------------------

  /** §25.1's "one-tap 'remix this island'": the island's bundle, to open in a
   *  builder as the player's own draft. Publishing it names the original
   *  (`remixOf`); a remix is a new island, cleared by its new creator. */
  remix(player, id) {
    const item = this.row(id);
    if (!this.listed(item)) throw new Refused(404, "no_such_island");
    this.curated(player, item);
    this.service.safety.requireTerms(player);
    this.db.prepare(
      "INSERT OR IGNORE INTO workshop_remixes (item, player, at) VALUES (?, ?, ?)")
      .run(id, player, this.now());
    return this.service.store.get(item.bundle);
  }

  // -- the creator ladder ---------------------------------------------------------

  /** §18.7: a creator's level, from completions across their islands (by
   *  anyone but themselves) and islands featured. */
  ladder(creator) {
    const completions = Number(this.db.prepare(
      `SELECT COALESCE(SUM(c.weight), 0) AS n FROM workshop_completions c
         JOIN workshop_items i ON i.id = c.item
        WHERE i.creator = ? AND i.removed_at IS NULL AND c.counted = 1`).get(creator).n);
    const featured = this.db.prepare(
      // RB-38: a featured island later removed no longer counts.
      "SELECT COUNT(*) AS n FROM workshop_items WHERE creator = ? AND featured_at IS NOT NULL AND removed_at IS NULL")
      .get(creator).n;
    const level = LADDER.find(([, at]) => completions >= at.completions || featured >= at.featured);
    return { level: level ? level[0] : null, completions, featured };
  }

  // -- moderation ----------------------------------------------------------------

  moderator(account) {
    if (!this.account(account)?.moderator) throw new Refused(403, "not_a_moderator");
  }

  /** The queue, oldest first, each marked overdue past §20.4's 24 hours. */
  queue(moderator) {
    this.moderator(moderator);
    const now = this.now();
    return this.db.prepare(
      "SELECT * FROM workshop_reports WHERE resolved_at IS NULL ORDER BY at, id").all()
      .map((r) => ({ report: r.id, item: r.item, reason: r.reason, server: r.reporter === null,
                     at: r.at, overdue: now - r.at > REVIEW_MS }));
  }

  /**
   * A person's decision on a report: "dismiss", "remove" (the island leaves
   * the Workshop, with a reason its creator is shown), or "ban" (§20.12: the
   * account's islands "leave matchmaking and the Workshop immediately").
   * Every open report on the same island is closed with it.
   */
  resolve(moderator, reportId, action, reason = null) {
    this.moderator(moderator);
    const report = this.db.prepare("SELECT * FROM workshop_reports WHERE id = ?").get(reportId);
    if (!report) throw new Refused(404, "no_such_report");
    if (!["dismiss", "remove", "ban"].includes(action)) throw new Refused(400, "no_such_action");
    if (action !== "dismiss" && !REMOVAL_REASONS.includes(reason)) {
      throw new Refused(400, "a_reason_is_owed");
    }
    const now = this.now();
    const item = this.row(report.item);
    transaction(this.db, () => {
      if (action === "remove" || action === "ban") {
        this.db.prepare(
          "UPDATE workshop_items SET removed_at = ?, removed_reason = ? WHERE id = ? AND removed_at IS NULL")
          .run(now, reason, item.id);
      }
      if (action === "ban") this.ban(item.creator, reason, now);
      if (action === "dismiss" && report.reporter === null) {
        this.db.prepare("UPDATE workshop_items SET review = 0 WHERE id = ?").run(item.id);
      }
      this.db.prepare(
        "UPDATE workshop_reports SET resolved_at = ?, resolution = ? WHERE item = ? AND resolved_at IS NULL")
        .run(now, action, item.id);
    });
    return this.view(this.row(item.id));
  }

  /** A ban: the account can no longer sign in, and its islands leave the
   *  Workshop and the target lists at once (§20.12). The minimum to enforce
   *  it is kept: its platform identity, in the bans table, apart from the
   *  account. As on a deletion, its friendships, invites and challenge links
   *  end and it leaves its constellation — a founder handing it on (§17.7) —
   *  and its crew; in the caller's transaction. */
  ban(account, reason, now = this.now()) {
    this.db.prepare(
      "UPDATE accounts SET banned_at = ?, banned_reason = ? WHERE id = ? AND banned_at IS NULL")
      .run(now, reason, account);
    const a = this.db.prepare("SELECT platform_identity, banned_at, banned_reason FROM accounts WHERE id = ?").get(account);
    if (!a.platform_identity.startsWith("deleted:")) banIdentity(this.db, a.platform_identity, a.banned_at, a.banned_reason);
    this.db.prepare("DELETE FROM challenges WHERE account = ?").run(account);
    this.db.prepare("DELETE FROM friends WHERE a = ? OR b = ?").run(account, account);
    this.db.prepare("DELETE FROM friend_invites WHERE account = ?").run(account);
    // Every device signed in to it, signed out (auth.mjs).
    this.service.auth.endAll(account, "banned", now);
    const social = new Social(this.service);
    const m = social.membership(account);
    if (m) social.depart(m);
    if (social.crewOf(account)) social.leaveCrew(account);
  }

  /** §18.6: "featured islands are reviewed by a person" — a moderator puts an
   *  island in the weekly spotlight, which also counts toward §18.7's ladder. */
  feature(moderator, id) {
    this.moderator(moderator);
    const item = this.row(id);
    if (!this.listed(item)) throw new Refused(404, "no_such_island");
    if (!item.featured_at) {
      this.db.prepare("UPDATE workshop_items SET featured_at = ? WHERE id = ?").run(this.now(), id);
    }
    return this.view(this.row(id));
  }
}
