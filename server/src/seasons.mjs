// Renown, leagues and seasons (§12.9, §14.7, §17.5, §18.1).
//
// §12.9: "Renown for a clean heist = 20 × (1 + (defender's Renown − raider's
// Renown) ÷ 1,000), kept between 8 and 40, then multiplied by the outcome
// above. The defender gains or loses the mirror amount. A foiled heist costs
// the raider a flat 8." §18.1: "A season lasts eight weeks. Renown places
// players in six leagues … each with three divisions except Paradox. Nobody
// can drop out of Dust or Ember, so new players only climb. At the end of a
// season, rewards are given by league and Renown is pulled halfway back
// toward the floor of the player's league."
//
// Where each league starts is not in the document. `leagues.json` holds the
// boundaries tools/league_model.py fits to §14.7's season-end shares (G27),
// and what that fit costs §14.7's arrival times is F40.

import { readFileSync } from "node:fs";

import { transaction } from "./db.mjs";
import { Refused } from "./refused.mjs";
import { Track } from "./track.mjs";

const facts = JSON.parse(readFileSync(new URL("./facts.json", import.meta.url), "utf8"));
export const BOUNDS = JSON.parse(readFileSync(new URL("./leagues.json", import.meta.url), "utf8"));

const DAY_MS = 24 * 60 * 60 * 1000;
export const SEASON_MS = facts.SEASON_WEEKS * 7 * DAY_MS;
const LEAGUES = facts.LEAGUES;

/** §12.9's clean amount, before the outcome: kept between the floor and cap.
 *  Renown is whole points, so each amount is rounded to the nearest (G27). */
export function cleanRenown(raider, defender) {
  const [base, scale, low, high] = facts.RENOWN_CLEAN;
  return Math.min(high, Math.max(low, base * (1 + (defender - raider) / scale)));
}

/** A Renown's league and division (1 to 3; none in Paradox). */
export function place(renown) {
  let i = 0;
  while (i + 1 < LEAGUES.length && renown >= BOUNDS.leagues[LEAGUES[i + 1]]) i++;
  const league = LEAGUES[i];
  const cuts = BOUNDS.divisions[league];
  const division = cuts ? cuts.filter((c) => renown >= c).length : null;
  return { league, division, floor: BOUNDS.leagues[league] };
}

/** §18.1's season-end rewards. The document gives "Star, Nova and Paradox
 *  leagues with season-end cosmetics" (§18.5) and nothing for the other
 *  three, so those three earn a cosmetic of their league and the season, and
 *  the rest none (G27). */
export function reward(season, league) {
  return ["Star", "Nova", "Paradox"].includes(league)
    ? `season-${season}-${league.toLowerCase()}` : null;
}

export class Seasons {
  /** `first` is when season 1 starts: the day the game opens. */
  constructor(service, first = 0) {
    this.service = service;
    this.first = first;
  }

  get db() { return this.service.db; }

  /** The season `now` falls in, created when first reached; closing the one
   *  before is `rollover`'s. */
  current(now = this.service.now()) {
    const n = Math.max(1, Math.floor((now - this.first) / SEASON_MS) + 1);
    let row = this.db.prepare("SELECT * FROM seasons WHERE id = ?").get(n);
    if (!row) {
      const starts = this.first + (n - 1) * SEASON_MS;
      this.db.prepare("INSERT OR IGNORE INTO seasons (id, starts_at, ends_at) VALUES (?, ?, ?)")
        .run(n, starts, starts + SEASON_MS);
      row = this.db.prepare("SELECT * FROM seasons WHERE id = ?").get(n);
    }
    return row;
  }

  /** A player's standing in a season, opened at their pulled-back Renown
   *  the first time they appear in it — and with the season track's tier
   *  price for them, scaled to the time the season has left (§18.8). */
  standing(account, season) {
    let row = this.db.prepare("SELECT * FROM standings WHERE season = ? AND account = ?")
      .get(season, account);
    if (!row) {
      const last = this.db.prepare(
        "SELECT * FROM standings WHERE account = ? AND season < ? ORDER BY season DESC LIMIT 1")
        .get(account, season);
      // A player's first season starts at nothing, in Dust. A later one starts
      // where the last one's close pulled them back to.
      const start = last ? this.pulledBack(account, last) : { start: 0, ember: 0 };
      const { ends_at: ends } = this.db.prepare("SELECT ends_at FROM seasons WHERE id = ?").get(season);
      const tierStars = Track.scaled(ends - this.service.now(), SEASON_MS);
      this.db.prepare(
        "INSERT INTO standings (season, account, start, ember, tier_stars) VALUES (?, ?, ?, ?, ?)")
        .run(season, account, start.start, start.ember, tierStars);
      row = { season, account, ...start, tier_stars: tierStars };
    }
    return row;
  }

  /** §18.1: "pulled halfway back toward the floor of the player's league",
   *  from the last season they played; Ember, once reached, stays reached. */
  pulledBack(account, last) {
    const end = this.renownIn(account, last.season, last);
    const floor = place(end).floor;
    return { start: Math.round(floor + (end - floor) / 2), ember: last.ember };
  }

  renownIn(account, season, standing = null) {
    const s = standing ?? this.standing(account, season);
    const moved = this.db.prepare(
      "SELECT COALESCE(SUM(amount), 0) AS n FROM renown WHERE season = ? AND account = ?")
      .get(season, account).n;
    return s.start + Number(moved);
  }

  /** The lowest a player's Renown may go: Dust's floor, or Ember's once
   *  reached — "nobody can drop out of Dust or Ember". From Tide up a
   *  player can fall back, as far as Ember. */
  floorOf(standing) {
    return standing.ember ? BOUNDS.leagues.Ember : BOUNDS.leagues.Dust;
  }

  /**
   * §12.9's Renown for one settled heist, booked in the grant's transaction.
   * Renown moves between the two; it is minted only where a floor stops a
   * loss (F40): a defender at their floor loses nothing, and the raider still
   * gains. A foiled raider loses a flat 8, as far as their floor, and "the
   * defender gains … the mirror of the Renown the raider loses" — what was
   * actually lost.
   */
  settle(lease, verdict, now) {
    const season = this.current(now).id;
    const raider = this.standing(lease.attacker, season);
    const defender = this.standing(lease.defender, season);
    const r = this.renownIn(lease.attacker, season, raider);
    const d = this.renownIn(lease.defender, season, defender);
    let gain;
    let loss;
    if (verdict.grade === "foiled") {
      gain = -Math.min(facts.RENOWN_FOILED, Math.max(0, r - this.floorOf(raider)));
      loss = gain;                                  // the defender gains what the raider lost
    } else {
      gain = Math.round(cleanRenown(r, d) * facts.RENOWN_OUTCOME[verdict.grade]);
      loss = Math.min(gain, Math.max(0, d - this.floorOf(defender)));
    }
    const book = this.db.prepare(
      "INSERT INTO renown (season, account, amount, reason, heist, at) VALUES (?, ?, ?, ?, ?, ?)");
    if (gain !== 0) book.run(season, lease.attacker, gain, `heist, ${verdict.grade} (12.9)`, lease.token, now);
    if (loss !== 0) book.run(season, lease.defender, -loss, `defended, ${verdict.grade} (12.9)`, lease.token, now);
    for (const [account, s] of [[lease.attacker, raider], [lease.defender, defender]]) {
      if (!s.ember && this.renownIn(account, season, s) >= BOUNDS.leagues.Ember) {
        this.db.prepare("UPDATE standings SET ember = 1 WHERE season = ? AND account = ?")
          .run(season, account);
      }
    }
    // `|| 0`: a loss of nothing is 0, not JavaScript's −0.
    return { raider: gain || 0, defender: -loss || 0 };
  }

  /** Where a player stands this season: Renown, league, division, and the
   *  league's floor and the next league's start. */
  league(account, now = this.service.now()) {
    const season = this.current(now).id;
    const renown = this.renownIn(account, season);
    const p = place(renown);
    const i = LEAGUES.indexOf(p.league);
    return { season, renown, ...p,
             next: i + 1 < LEAGUES.length ? BOUNDS.leagues[LEAGUES[i + 1]] : null };
  }

  /**
   * Close every season that has ended and open the next: each player's final
   * Renown, league and reward written down, the reward's cosmetic granted,
   * and the constellation league ranked (§17.5). Idempotent, and safe to run
   * as often as the scheduler likes: a closed season is never closed again.
   */
  rollover(now = this.service.now()) {
    const closed = [];
    const due = this.db.prepare(
      "SELECT * FROM seasons WHERE closed_at IS NULL AND ends_at <= ? ORDER BY id").all(now);
    for (const season of due) {
      transaction(this.db, () => {
        const players = this.db.prepare("SELECT * FROM standings WHERE season = ? ORDER BY account")
          .all(season.id);
        for (const s of players) {
          const renown = this.renownIn(s.account, season.id, s);
          const p = place(renown);
          const prize = reward(season.id, p.league);
          this.db.prepare(
            `INSERT INTO season_results (season, account, renown, league, division, reward)
             VALUES (?, ?, ?, ?, ?, ?)`).run(season.id, s.account, renown, p.league, p.division, prize);
          if (prize) this.grantCosmetic(s.account, prize);
        }
        this.rankConstellations(season.id);
        this.setDefenceShare(season);
        this.db.prepare("UPDATE seasons SET closed_at = ? WHERE id = ?").run(now, season.id);
      });
      closed.push(season.id);
    }
    this.current(now);
    return closed;
  }

  /** The defence reward's share of a foiled crew's load this season, in
   *  per cent: §9.4's 5 until §13.1's rule has raised it. */
  defenceShare(season = this.current().id) {
    const row = this.db.prepare(
      "SELECT percent FROM defence_shares WHERE season <= ? ORDER BY season DESC LIMIT 1").get(season);
    return row ? row.percent : facts.DEFENCE_SHARE;
  }

  /**
   * §13.1's weekly measure, taken over a season's last seven days: the
   * "Share of active players who changed their defence in the last 7 days".
   * Active is a session in that week (the device's, G29); changing a defence is publishing an
   * island — a new snapshot, or an island moved to one already stored, as a
   * revert or a copy is. Seeded accounts are the game's, and not counted
   * (G31). Null when nobody was active.
   */
  defenceMeasure(end) {
    const since = end - 7 * DAY_MS;
    const active = new Set(this.db.prepare(
      "SELECT DISTINCT who FROM events WHERE kind = 'session_start' AND at > ? AND at <= ?").all(since, end)
      .map((r) => r.who));
    for (const r of this.db.prepare("SELECT id FROM accounts WHERE seeded = 1").all()) {
      active.delete(this.service.telemetry.pseudonym(r.id));
    }
    if (active.size === 0) return null;
    const changed = this.db.prepare(
      `SELECT owner FROM snapshots WHERE published_at > :since AND published_at <= :end
       UNION SELECT owner FROM islands WHERE changed_at > :since AND changed_at <= :end`).all({ since, end })
      .map((r) => this.service.telemetry.pseudonym(r.owner)).filter((w) => active.has(w));
    return (100 * changed.length) / active.size;
  }

  /** §13.1: "Below 15%, the defence reward's share … rises by 5 points a
   *  season, at most three times, from 5% to 20%; nothing further is tried".
   *  Set for the season after the one closing. */
  setDefenceShare(season) {
    const [below, step, most, from, to] = facts.DEFENCE_SHARE_RISE;
    const now = this.defenceShare(season.id);
    const measured = this.defenceMeasure(season.ends_at);
    const rises = Math.round((now - from) / step);
    const next = measured !== null && measured < below && rises < most ? Math.min(to, now + step) : now;
    this.db.prepare(
      "INSERT OR REPLACE INTO defence_shares (season, percent, measured, set_at) VALUES (?, ?, ?, ?)")
      .run(season.id + 1, next, measured, season.ends_at);
  }

  grantCosmetic(account, id) {
    const row = this.db.prepare("SELECT cosmetics FROM accounts WHERE id = ?").get(account);
    const owned = JSON.parse(row.cosmetics);
    if (!owned.includes(id)) {
      owned.push(id);
      this.db.prepare("UPDATE accounts SET cosmetics = ? WHERE id = ?")
        .run(JSON.stringify(owned), account);
    }
  }

  /** §17.5's constellation league: "ranked by members' combined Renown and
   *  anomaly scores". Anomalies are not built, so it is Renown alone (D63),
   *  over the members at the season's close — its end, not the rollover's
   *  run, so nobody moves their final Renown once it is known. */
  rankConstellations(season) {
    const { ends_at: ends } = this.db.prepare("SELECT ends_at FROM seasons WHERE id = ?").get(season);
    const rows = this.db.prepare(
      `SELECT m.constellation, COALESCE(SUM(r.renown), 0) AS renown
         FROM constellation_members m
         LEFT JOIN season_results r ON r.account = m.account AND r.season = :season
        WHERE m.joined_at <= :ends AND (m.left_at IS NULL OR m.left_at > :ends)
        GROUP BY m.constellation ORDER BY renown DESC, m.constellation`).all({ season, ends });
    rows.forEach((r, i) => this.db.prepare(
      "INSERT INTO constellation_results (season, constellation, renown, place) VALUES (?, ?, ?, ?)")
      .run(season, r.constellation, Number(r.renown), i + 1));
  }

  /** A closed season's result for a player, or refused while it is open. */
  result(account, season) {
    const s = this.db.prepare("SELECT closed_at FROM seasons WHERE id = ?").get(season);
    if (!s) throw new Refused(404, "no_such_season");
    if (!s.closed_at) throw new Refused(409, "season_still_open");
    return this.db.prepare("SELECT * FROM season_results WHERE season = ? AND account = ?")
      .get(season, account) ?? null;
  }

  /** The constellation league for a closed season, best first. */
  constellationTable(season) {
    return this.db.prepare(
      "SELECT constellation, renown, place FROM constellation_results WHERE season = ? ORDER BY place")
      .all(season);
  }
}
