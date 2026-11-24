// §13.3's hold, measured on the server: "A hold is a rate over many raids,
// so it is measured on the server — 800 raids of the competent reference
// crew, queued and cached by the island's digest — and shown as
// “measuring…” until it lands: a preview never shows an estimate as a
// measurement."
//
// Every island published is queued once by its bundle and the rules it was
// measured under; the same bundle published again is answered from the
// cache. The queue is worked a few raids at a time (main.mjs), each part the
// simulation's reference crew (sim/src/reference.rs) from a seed of the
// island's own digest moved on by the raids already played, so a measurement
// in parts is the one measurement in one call. When the last raid lands,
// §12.22's prior — "its hold rate against the reference crews (13.4),
// converted to the rating scale" — rates every island on that bundle that
// has not been raided yet. The crew is three, a new Keeper's (§12.5), on the
// Heart's clock of 150 seconds.

import { readFileSync } from "node:fs";

import { transaction } from "./db.mjs";
import { fresh, ratingFor } from "./glicko.mjs";
import { clockTicks } from "./service.mjs";

const facts = JSON.parse(readFileSync(new URL("./facts.json", import.meta.url), "utf8"));
export const HOLD_CREW = 3;

/** The measurement's first seed: the bundle digest's first eight bytes. */
export const seedOf = (bundle) => BigInt.asUintN(64, BigInt(`0x${bundle.slice(0, 16)}`));

export class Holds {
  constructor(service) {
    this.service = service;
    /** The bundle being measured, while it is (`work`). */
    this.running = null;
    /** The rules every live bundle is queued under (`queueLive`). */
    this.queued = null;
  }

  /** FX1-A-05: every bundle some island is now, queued under the current
   *  rules once they are new — after a new simulation build, an island
   *  published before it is measured again, and shown as measuring. */
  queueLive(now = this.service.now()) {
    const rules = this.service.builds.current.rulesVersion;
    if (this.queued === rules) return;
    this.db.prepare(
      `INSERT OR IGNORE INTO island_holds (bundle, rules, raids, played, held, queued_at)
       SELECT DISTINCT bundle, ?, ?, 0, 0, ? FROM islands`).run(rules, facts.HOLD_RAIDS, now);
    this.queued = rules;
  }

  get db() { return this.service.db; }

  /** `bundle` queued to be measured under the current rules, unless it is. */
  request(bundle, now = this.service.now()) {
    this.db.prepare(
      `INSERT OR IGNORE INTO island_holds (bundle, rules, raids, played, held, queued_at)
       VALUES (?, ?, ?, 0, 0, ?)`).run(bundle, this.service.builds.current.rulesVersion, facts.HOLD_RAIDS, now);
  }

  /** What a screen shows: "measuring" with how far it has come, or the
   *  measured hold as raids held of raids played; null for none queued. */
  status(bundle) {
    this.queueLive();
    const r = this.db.prepare("SELECT * FROM island_holds WHERE bundle = ? AND rules = ?")
      .get(bundle, this.service.builds.current.rulesVersion);
    // A measurement lost to a throw or to its bundle's bytes is no figure
    // (RB-15): `held` is -1, and the screen shows none.
    if (!r || r.held < 0) return null;
    return r.measured_at == null
      ? { status: "measuring", played: r.played, raids: r.raids }
      : { status: "measured", held: r.held, raids: r.raids, hold: r.held / r.raids };
  }

  /** Up to `raids` raids of the next measurement, owners in turn, written;
   *  the measurement that lands rates its islands. Returns the raids played. */
  work(raids = 40, now = this.service.now()) {
    const build = this.service.builds.current;
    this.queueLive(now);
    // The next measurement is of a bundle some player's island is now — a
    // superseded one waits, measured if it is published again — and owners
    // take turns: each owner's oldest first, then their next. A player who
    // publishes island after island has at most their seven realms in the
    // queue, and never puts everyone else's behind theirs (SR-17).
    // Chosen once a measurement, and kept while it runs and stands.
    const kept = this.running && this.db.prepare(
      `SELECT * FROM island_holds WHERE bundle = ? AND rules = ? AND measured_at IS NULL
          AND EXISTS (SELECT 1 FROM islands WHERE bundle = ?)`)
      .get(this.running, build.rulesVersion, this.running);
    const r = kept || this.db.prepare(
      `WITH live AS (
         SELECT h.*, ROW_NUMBER() OVER (PARTITION BY o.owner ORDER BY h.queued_at, h.bundle) AS turn
           FROM island_holds h
           JOIN (SELECT bundle, MIN(owner) AS owner FROM islands GROUP BY bundle) o ON o.bundle = h.bundle
          WHERE h.rules = ? AND h.measured_at IS NULL)
       SELECT * FROM live ORDER BY turn, queued_at, bundle LIMIT 1`)
      .get(build.rulesVersion);
    this.running = r?.bundle ?? null;
    if (!r) return 0;
    const island = this.service.store.get(r.bundle);
    const n = Math.min(raids, r.raids - r.played);
    // A measurement that throws is logged and set aside: marked measured,
    // with no prior, so it is never picked again, before or after a restart,
    // and its islands keep the default prior (SEC-20).
    let held = 0, failed = false;
    try {
      held = island ? build.hold(island, { seed: seedOf(r.bundle) + BigInt(r.played), raids: n,
                                           ticks: clockTicks(0), crew: HOLD_CREW }) : 0;
    } catch (err) {
      console.error(`hold ${r.bundle.slice(0, 12)}:`, err);
      held = 0;
      failed = true;
    }
    transaction(this.db, () => {
      const played = failed ? r.raids : r.played + n;
      const done = failed || played >= r.raids || !island;
      const lost = failed || !island;
      this.db.prepare(`UPDATE island_holds SET played = ?, held = CASE WHEN ? THEN -1 ELSE held + ? END,
                         measured_at = ? WHERE bundle = ? AND rules = ?`)
        .run(played, lost ? 1 : 0, held, done ? now : null, r.bundle, r.rules);
      if (done && island && !failed) this.rate(r.bundle, (r.held + held) / r.raids, now);
    });
    return n;
  }

  /** §12.22's prior from the measured hold, for each island on `bundle`
   *  that no raid has rated yet. A raider at the centre of the scale is
   *  expected to succeed as often as the reference crew did, kept off 0 and
   *  1 by half a raid. */
  rate(bundle, hold, now) {
    const half = 1 / (2 * facts.HOLD_RAIDS);
    const success = Math.min(1 - half, Math.max(half, 1 - hold));
    const mm = this.service.matchmaking;
    for (const { owner, realm } of this.db.prepare("SELECT owner, realm FROM islands WHERE bundle = ?").all(bundle)) {
      const had = mm.islandRating(owner, realm);
      if (had && had.games > 0) continue;
      mm.store("island", mm.islandKey(owner, realm), { ...fresh(ratingFor(success)), games: 0 }, now);
    }
  }
}
