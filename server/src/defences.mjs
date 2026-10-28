// §23.2's defence log (TD.66): "raids on you, each with its report (the haul
// denied, how long the defence held, where the crew was seen, what fired;
// 13.2), Trace".
//
// Each report names its outcome as v3.7 writes G69's recommended option:
// held when the raid was Foiled, as §13.4's hold rate counts it, and leaked
// on Clean, Loud and Partial, with Partial its own count (§12.9). Two facts
// are written into the heist's outcome at settlement (service.mjs), so the
// log reads one record (TD.39): `denied`, the clean haul a full bag would
// make on this island less the clean haul of what the raider banked, both
// priced as §9.4 prices a crew's unbanked load (G31); `heldMs`, the seconds
// from the landing to the last crew member's escape or capture; and
// `report`, what the simulation's event log says at settlement (sim.mjs
// `report`, TD.39): where the crew landed, each place a guard reached
// Alerted, each ward that fired, the bells rung, the realm alarm's highest
// level and the posts whose guards caught anyone. A raid settled before
// these facts were kept shows them as not recorded.
//
// The log keeps the season's raids, newest first; it offers Watch replay
// while the replay is kept (§13, §24.3) and says when it is gone; it offers
// Trace on the one raid the server's traceable() names for its raider (not
// foiled, within 24 hours, not past the raider's twenty paid raids that
// week, G70); and reading it clears the raid badge.

import { readFileSync } from "node:fs";

const facts = JSON.parse(readFileSync(new URL("./facts.json", import.meta.url), "utf8"));

/** A raid on a player: a matchmade or Trace raid, not an echo, a game among
 *  friends or a challenge, which take nothing from the island's owner. */
const RAIDED = "l.mode = 'raid' AND l.echo = 0";

export class Defences {
  constructor(service) {
    this.service = service;
  }

  get db() { return this.service.db; }

  /** The raids on `account` this season, newest first, as their reports. */
  rows(account, now) {
    const season = this.service.seasons.current(now);
    return this.db.prepare(
      `SELECT h.token, h.bundle, h.attacker, h.submitted_at, h.outcome, h.replay_gone, a.keeper_level, s.realm_level
         FROM heists h JOIN leases l ON l.token = h.token JOIN accounts a ON a.id = h.attacker
         JOIN snapshots s ON s.bundle = h.bundle
        WHERE h.defender = ? AND h.submitted_at >= ? AND h.validated = 1 AND ${RAIDED}
        ORDER BY h.submitted_at DESC, h.token`).all(account, season.starts_at);
  }

  /** The defence log: each raid's report and its Trace, how many of the
   *  season's raids were held, leaked and partial, and how many are new. */
  view(account, now = this.service.now()) {
    const seen = this.db.prepare("SELECT defences_seen_at FROM accounts WHERE id = ?").get(account)?.defences_seen_at ?? 0;
    const mm = this.service.matchmaking;
    const traced = new Map();
    const raids = this.rows(account, now).map((r) => {
      const o = JSON.parse(r.outcome);
      const grade = o.verdict?.grade ?? "foiled";
      if (!traced.has(r.attacker)) traced.set(r.attacker, mm.traceable(account, r.attacker, now));
      const trace = traced.get(r.attacker) === r.token ? this.island(r.attacker) : null;
      return {
        heist: r.token, island: r.bundle, at: r.submitted_at, raider: { keeper_level: r.keeper_level },
        grade, held: grade === "foiled",
        denied: Number.isInteger(o.denied) ? o.denied : null,
        held_seconds: Number.isInteger(o.heldMs) ? Math.round(o.heldMs / 1000) : null,
        caught: o.verdict?.caught ?? 0, crew: o.verdict?.crew ?? null,
        defence: o.defence ? { total: o.defence.total } : null,
        // The island's side, so the landing is named by its edge (§5.4).
        report: o.report ? { side: 9 + r.realm_level, landing: o.report.landing, seen: o.report.seen,
                             fired: o.report.fired, bells: o.report.bells, alarm: o.report.alarm,
                             caught_by: o.report.caughtBy } : null,
        replay: r.replay_gone ? "gone" : "kept",
        trace: trace ? { bundle: trace } : null,
        new: r.submitted_at > seen,
      };
    });
    const count = (g) => raids.filter((x) => x.grade === g).length;
    return {
      raids,
      season: { held: count("foiled"), leaked: raids.length - count("foiled"), partial: count("partial") },
      unseen: raids.filter((x) => x.new).length,
      trace_hours: facts.TRACE_HOURS,
    };
  }

  /** The log read: shown, and its raids no longer new (the raid badge). */
  show(account) {
    const now = this.service.now();
    const v = this.view(account, now);
    // With no raid new since the last read, moving the mark would change no
    // count it makes: a write that says nothing (§24.1's writes).
    if (v.unseen) this.db.prepare("UPDATE accounts SET defences_seen_at = ? WHERE id = ?").run(now, account);
    return v;
  }

  /** The raid badge: how many raids on the player are new since the log
   *  was last read. */
  badge(account) {
    // The raids since the log was read, this season: the badge reads those,
    // not the season's every raid and report (§24.1's reads).
    const now = this.service.now();
    const seen = this.db.prepare("SELECT defences_seen_at FROM accounts WHERE id = ?").get(account)?.defences_seen_at ?? 0;
    const season = this.service.seasons.current(now);
    // One bound, the later of the two, so the index's range is it.
    return { unseen: this.db.prepare(
      `SELECT COUNT(*) AS n FROM heists h JOIN leases l ON l.token = h.token
        WHERE h.defender = ? AND h.submitted_at >= ? AND h.validated = 1 AND ${RAIDED}`)
      .get(account, Math.max(season.starts_at, seen + 1)).n };
  }

  /** The raider's island a Trace leases: their Heart, else any realm. */
  island(raider) {
    return this.db.prepare("SELECT bundle FROM islands WHERE owner = ? ORDER BY realm = 'heart' DESC, realm")
      .get(raider)?.bundle ?? null;
  }
}
