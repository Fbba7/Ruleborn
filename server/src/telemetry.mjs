// First-party telemetry (§20.5, §24, §24.3, §25.3).
//
// §24's analytics row: "Events for sessions, heists (outcome, laws crossed, crew), weaving,
// births and purchases, plus the "worth your time" rating and the monthly
// survey in 25", kept as "First-party events in our own database". §20.5:
// "analytics are pseudonymous". §24.3: "The client never sends coordinates",
// and "Raw replays and logs are kept 30 to 90 days, long enough for
// validation and analysis, then aggregated and discarded". Telemetry "is
// batched rather than written per event" (§24.1): a batch is one row.
//
// The server writes what it decides — a sign-in, a heist's outcome, a
// purchase — and the device sends the rest in batches.
//
// The owner's answer to G29: a session is the device's, from the app coming
// to the foreground (`session_start`) to its `session_end`, which carries its
// length in seconds; a sign-in only proves who the player is. Raw events are
// kept 90 days. The monthly survey is a rotating sample — each month the
// device asks a player not asked in the last 90 days — of the eleven
// inventory items on seven points and one yes-or-no "does the game feel like
// a chore?", which chapter 25's targets read. Cohorts record day-60 returns. Every row is keyed by
// a pseudonym, an HMAC of the account under the server's secret, so the
// events table alone names nobody.

import { createHmac } from "node:crypto";
import { readFileSync } from "node:fs";

import { transaction } from "./db.mjs";
import { Refused } from "./refused.mjs";

const facts = JSON.parse(readFileSync(new URL("./facts.json", import.meta.url), "utf8"));

const DAY_MS = 24 * 60 * 60 * 1000;

/** §24.3's "30 to 90 days": the longest, so analysis has the most (G29). */
export const RAW_DAYS = facts.RAW_KEEP_DAYS;

/** §25.4: surveys "never more than once a quarter per player". The monthly
 *  survey §24 names is a monthly rotating sample, each player at most once a
 *  quarter (G29, decided). */
export const SURVEY_GAP_MS = 90 * DAY_MS;          // within the raw window, so the last survey is always still there

/** A batch's largest size, and how far back a queued event may be dated —
 *  a heist queues offline, but not for longer than its lease (G29). */
export const BATCH = 100;
/** The most events one row of a player's day holds: a heavy day — every
 *  session, rating and heist a day allows — fits in one or two. */
export const ROW_EVENTS = 200;
/** The most events one player's device sends in a day, every kind
 *  together: the heavy day above, twice over. Past it a batch is refused,
 *  so no caller writes the store full (SR-19). */
export const DEVICE_EVENTS_A_DAY = 2 * ROW_EVENTS;
export const LATE_MS = 7 * DAY_MS;

/** What a player's day counts (§20.3's one tap, §25.3's gates): no more
 *  sessions than one an hour, started or ended, and a "worth your time" rating for each —
 *  §20.3 asks it after every session. The report weighs each player once
 *  (their own average), so no one device sets the launch gates' figures (G29). */
export const SESSION_ENDS_A_DAY = 24;
export const WORTH_A_DAY = SESSION_ENDS_A_DAY;

/**
 * What the device may send, field by field: each field's type, and nothing
 * else. No field is a position (§24.3). `session_start` and `session_end`
 * are a session, the app in the foreground (G29); `weave` and `birth` are
 * §24's; `worth` is §20.3's one-tap "Was this worth your time?"; `survey` is
 * §25.4's eleven-item inventory, each answer on a seven-point scale, and
 * whether the game feels like a chore (G29).
 */
export const DEVICE_EVENTS = {
  session_start: {},
  session_end: { seconds: "count", crashed: "flag" },
  weave: { law: "id", realm: "id" },
  birth: { form: "id" },
  worth: { rating: "rating" },
  survey: { answers: "survey", chore: "flag" },
};

/** What the server writes itself: a sign-in, which proves who the player
 *  is and is not a session (G29). */
export const SERVER_EVENTS = ["sign_in", "heist", "purchase"];

const FORBIDDEN = /^(x|y|z|position|pos|lat|lon|latitude|longitude|coords?)$/i;

const valid = {
  count: (v) => Number.isInteger(v) && v >= 0 && v < 1e7,
  flag: (v) => typeof v === "boolean",
  id: (v) => typeof v === "string" && /^[a-z0-9_-]{1,40}$/.test(v),
  rating: (v) => Number.isInteger(v) && v >= 1 && v <= 5,
  survey: (v) => Array.isArray(v) && v.length === 11 && v.every((a) => Number.isInteger(a) && a >= 1 && a <= 7),
};

const day = (ms) => new Date(ms).toISOString().slice(0, 10);
const plus = (d, n) => day(Date.parse(d) + n * DAY_MS);

/** The laws an island weaves, read from its bundle (sim/src/island.rs's
 *  encoding: a 14-byte head, three bytes a tile, then guards, wards and
 *  laws). The bundle was checked by the simulation when it was published. */
export function lawsOf(bundle) {
  const side = 9 + bundle[4];
  let at = 14 + side * side * 3;
  at += 1 + bundle[at] * 3;                                  // guards
  at += 1 + bundle[at] * 3;                                  // wards
  const laws = [];
  for (let n = bundle[at++]; n > 0; n--) {
    const len = bundle[at++];
    laws.push(new TextDecoder().decode(bundle.subarray(at, at + len)));
    at += len + 2;
  }
  return [...new Set(laws)].sort();
}

export class Telemetry {
  constructor(service) {
    this.service = service;
  }

  get db() { return this.service.db; }

  pseudonym(account) {
    return createHmac("sha256", this.service.secret).update(`telemetry:${account}`).digest("hex").slice(0, 32);
  }

  /** One event, as the server decides it. A player's first session day is
   *  kept apart and for good, so retention outlives the raw events. */
  record(account, kind, data = {}, at = this.service.now()) {
    this.write(account, [{ kind, data, at }]);
  }

  /** An event the server records once a player a day, if not yet today. */
  once(account, kind, at = this.service.now()) {
    const seen = this.db.prepare("SELECT 1 FROM events WHERE who = ? AND kind = ? AND day = ? LIMIT 1")
      .get(this.pseudonym(account), kind, day(at));
    if (!seen) this.record(account, kind, {}, at);
  }

  /**
   * A player's events of a day go in one row (§24.1: "batched rather than
   * written per event"): the day's first write makes the row, and each later
   * one — a device batch, a sign-in, a heist — appends to it in one UPDATE
   * that changes no indexed column but the day, so it costs one written row
   * where a new row costs three, with its two index entries (F47). The
   * append is one statement, so two at once cannot lose either. A row holds
   * ROW_EVENTS at most; past that the next write starts another. A row's day
   * stays its earliest event's, which compaction goes by.
   */
  write(account, events) {
    const who = this.pseudonym(account);
    const now = this.service.now();
    const first = day(Math.min(...events.map((e) => e.at)));
    const json = JSON.stringify(events);
    // The day is set only when an event older than the row's arrives, so
    // an ordinary append leaves the day's index entry alone.
    const append = (setDay) => this.db.prepare(
      `UPDATE event_batches
          SET events = substr(events, 1, length(events) - 1) || ',' || substr(?1, 2)${setDay ? ", day = ?2" : ""}
        WHERE id = (SELECT id FROM event_batches WHERE who = ?3 AND at >= ?4 ORDER BY id DESC LIMIT 1)
          AND day ${setDay ? ">" : "<="} ?2 AND json_array_length(events) + ?5 <= ?6`)
      .run(json, first, who, now - (now % DAY_MS), events.length, ROW_EVENTS).changes;
    const appended = append(false) || append(true);
    if (!appended) {
      this.db.prepare("INSERT INTO event_batches (who, at, day, events) VALUES (?, ?, ?, ?)")
        .run(who, now, first, json);
    }
    // The first day is the earliest session, whenever it arrives: a device
    // sends its queue late, and in any order, up to LATE_MS back. A day
    // whose cohort is written is not moved out of or into.
    const starts = events.filter((e) => e.kind === "session_start");
    if (starts.length) {
      this.db.prepare(
        `INSERT INTO first_seen (who, day) VALUES (?1, ?2)
           ON CONFLICT (who) DO UPDATE SET day = excluded.day
            WHERE excluded.day < first_seen.day
              AND NOT EXISTS (SELECT 1 FROM cohorts WHERE cohorts.day IN (first_seen.day, excluded.day))`)
        .run(who, day(Math.min(...starts.map((e) => e.at))));
    }
  }

  /**
   * A batch from the device, validated whole before any of it is written: a
   * kind it may send, as an object holding that kind's fields and only
   * them, each of its type, dated no later than now and no earlier than a
   * queued heist could be; and no more of a kind than a player's day counts.
   */
  batch(account, events) {
    if (!Array.isArray(events) || events.length === 0) throw new Refused(400, "no_events");
    if (events.length > BATCH) throw new Refused(413, "batch_too_large", { most: BATCH });
    const now = this.service.now();
    const rows = events.map((e, i) => {
      // A string, and one of the kinds: an array ["worth"] would pass hasOwn's
      // own conversion to a key and slip past every cap.
      if (typeof e?.kind !== "string" || !Object.hasOwn(DEVICE_EVENTS, e.kind)) {
        throw new Refused(400, "no_such_event", { index: i });
      }
      const shape = DEVICE_EVENTS[e.kind];
      const data = e.data;
      if (data === null || typeof data !== "object" || Object.getPrototypeOf(data) !== Object.prototype) {
        throw new Refused(400, "bad_data", { index: i });
      }
      for (const key of Object.keys(data)) {
        if (FORBIDDEN.test(key)) throw new Refused(400, "positions_are_never_sent", { index: i });
        if (!Object.hasOwn(shape, key)) throw new Refused(400, "no_such_field", { index: i, field: key });
        if (!valid[shape[key]](data[key])) throw new Refused(400, "bad_field", { index: i, field: key });
      }
      for (const key of Object.keys(shape)) {
        if (!Object.hasOwn(data, key)) throw new Refused(400, "missing_field", { index: i, field: key });
      }
      const at = Number.isInteger(e.at) ? e.at : now;
      if (at > now || at < now - LATE_MS) throw new Refused(400, "bad_time", { index: i });
      // §25.4's quarter runs from when the server received the survey, so a
      // survey is kept as of then, and stays as long as the quarter does.
      return { kind: e.kind, data, at: e.kind === "survey" ? now : at };
    });
    const who = this.pseudonym(account);
    const surveys = rows.filter((r) => r.kind === "survey");
    if (surveys.length > 1 || (surveys.length && this.db.prepare(
      "SELECT 1 FROM events WHERE who = ? AND kind = 'survey' AND at > ?").get(who, now - SURVEY_GAP_MS))) {
      throw new Refused(429, "survey_once_a_quarter");
    }
    // Each event counts against its own day, as report() reads it.
    const sent = this.db.prepare("SELECT COUNT(*) AS n FROM events WHERE who = ? AND kind = ? AND day = ?");
    for (const [kind, most, reason] of [["worth", WORTH_A_DAY, "worth_too_often"],
                                        ["session_start", SESSION_ENDS_A_DAY, "too_many_session_starts"],
                                        ["session_end", SESSION_ENDS_A_DAY, "too_many_session_ends"]]) {
      const days = {};
      for (const r of rows) if (r.kind === kind) days[day(r.at)] = (days[day(r.at)] ?? 0) + 1;
      for (const [d, n] of Object.entries(days)) {
        if (n + Number(sent.get(who, kind, d).n) > most) throw new Refused(429, reason, { most });
      }
    }
    const kinds = Object.keys(DEVICE_EVENTS);
    const all = this.db.prepare(
      `SELECT COUNT(*) AS n FROM events WHERE who = ? AND day = ? AND kind IN (${kinds.map(() => "?").join(", ")})`);
    const days = {};
    for (const r of rows) days[day(r.at)] = (days[day(r.at)] ?? 0) + 1;
    for (const [d, n] of Object.entries(days)) {
      if (n + Number(all.get(who, d, ...kinds).n) > DEVICE_EVENTS_A_DAY) {
        throw new Refused(429, "too_many_events", { most: DEVICE_EVENTS_A_DAY });
      }
    }
    this.write(account, rows);
    return { recorded: rows.length };
  }

  /**
   * §24.3: raw events older than 90 days become daily counts, and go. Before
   * they go, every cohort — the players first seen on a day — whose day 60
   * has passed, and the LATE_MS a device may send its sessions after, is
   * written down with its day-1, day-7, day-30 and day-60 returns (G29).
   * Run daily; idempotent.
   */
  compact(now = this.service.now()) {
    const today = day(now);
    const before = plus(today, -RAW_DAYS);
    return transaction(this.db, () => {
      const open = this.db.prepare(
        `SELECT DISTINCT f.day FROM first_seen f LEFT JOIN cohorts c ON c.day = f.day
          WHERE c.day IS NULL AND f.day <= ? ORDER BY f.day`).all(plus(today, -(61 + LATE_MS / DAY_MS)));
      for (const { day: d } of open) {
        const r = this.cohort(d);
        this.db.prepare(
          "INSERT INTO cohorts (day, players, day1, day7, day30, day60) VALUES (?, ?, ?, ?, ?, ?)")
          .run(d, r.players, r.day1, r.day7, r.day30, r.day60);
      }
      // Every event older than the window, counted by its own day, whichever
      // batch holds it: a day goes whole, all at once, and no later batch can
      // add to it (none is dated back past LATE_MS). Such an event's batch
      // is dated before the window too, which is what the index finds.
      const old = `FROM events e JOIN event_batches b ON b.id = e.batch WHERE b.day < ?1 AND e.day < ?1`;
      this.db.prepare(
        `INSERT INTO event_days (day, kind, events, players)
           SELECT e.day, e.kind, COUNT(*), COUNT(DISTINCT e.who) ${old}
            GROUP BY e.day, e.kind
         ON CONFLICT (day, kind) DO UPDATE SET events = events + excluded.events,
           players = MAX(players, excluded.players)`).run(before);
      const gone = this.db.prepare(`SELECT COUNT(*) AS n ${old}`).get(before).n;
      // A batch that spans the edge keeps its later days' events, and is
      // dated by the earliest of them.
      const keep = this.db.prepare("UPDATE event_batches SET events = ?, day = ? WHERE id = ?");
      for (const b of this.db.prepare("SELECT id, events FROM event_batches WHERE day < ?").all(before)) {
        const rest = JSON.parse(b.events).filter((e) => day(e.at) >= before);
        if (rest.length) keep.run(JSON.stringify(rest), day(Math.min(...rest.map((e) => e.at))), b.id);
      }
      this.db.prepare("DELETE FROM event_batches WHERE day < ?").run(before);
      return { cohorts: open.length, discarded: Number(gone), before };
    });
  }

  /** One day's cohort, from the raw events: how many were first seen, and
   *  how many of them had a session on their day 1, 7, 30 and 60. */
  cohort(d) {
    const who = this.db.prepare("SELECT who FROM first_seen WHERE day = ?").all(d).map((r) => r.who);
    const played = this.db.prepare("SELECT 1 FROM events WHERE who = ? AND kind = 'session_start' AND day = ?");
    const back = (n) => who.filter((w) => played.get(w, plus(d, n))).length;
    return { players: who.length, day1: back(1), day7: back(7), day30: back(30), day60: back(60) };
  }

  /** Whether the device should ask this player the month's survey: the
   *  rotating sample asks everyone not asked in the last 90 days (G29,
   *  §25.4's once a quarter). Answering due is the asking: it is recorded,
   *  so a player who declines is not asked again until the quarter is out. */
  surveyDue(account, now = this.service.now()) {
    const asked = this.db.prepare(
      "SELECT 1 FROM events WHERE who = ? AND kind IN ('survey', 'survey_offered') AND at > ?")
      .get(this.pseudonym(account), now - SURVEY_GAP_MS);
    if (asked) return false;
    this.record(account, "survey_offered", {}, now);
    return true;
  }

  // -- what the numbers are for (§22.2, §25.3) ---------------------------------

  /**
   * The figures the launch gates read, over the days [from, to]: players,
   * sessions and their crash-free share (§25.3's 99.9%), the median
   * session's length and sessions a day per active player (G29), heists by
   * outcome, the share of surveyed players for whom the game feels like a
   * chore,
   * the average "worth your time" (4 out of 5 to leave soft launch), the
   * share of players who bought something (2%), and the retention of the
   * players first seen in the window (8% still playing after 30 days).
   */
  report({ from, to }) {
    const q = (sql, ...args) => this.db.prepare(sql).all(...args);
    const one = (sql, ...args) => this.db.prepare(sql).get(...args);
    const players = one(
      "SELECT COUNT(DISTINCT who) AS n FROM events WHERE kind = 'session_start' AND day BETWEEN ? AND ?", from, to).n;
    const ends = q("SELECT data FROM events WHERE kind = 'session_end' AND day BETWEEN ? AND ?", from, to)
      .map((r) => JSON.parse(r.data));
    const heists = {};
    for (const r of q("SELECT data FROM events WHERE kind = 'heist' AND day BETWEEN ? AND ?", from, to)) {
      const g = JSON.parse(r.data).grade ?? "refused";
      heists[g] = (heists[g] ?? 0) + 1;
    }
    // Each player's own average first, then the average of those: a player
    // who rates every session weighs no more than one who rates once.
    const byPlayer = new Map();
    for (const r of q("SELECT who, data FROM events WHERE kind = 'worth' AND day BETWEEN ? AND ?", from, to)) {
      const list = byPlayer.get(r.who) ?? [];
      list.push(JSON.parse(r.data).rating);
      byPlayer.set(r.who, list);
    }
    const ratings = [...byPlayer.values()].map((l) => l.reduce((a, b) => a + b, 0) / l.length);
    const lengths = ends.map((e) => e.seconds).sort((a, b) => a - b);
    const median = lengths.length
      ? (lengths[(lengths.length - 1) >> 1] + lengths[lengths.length >> 1]) / 2 : null;
    const playerDays = one(
      `SELECT COUNT(*) AS n FROM (SELECT DISTINCT who, day FROM events
        WHERE kind = 'session_start' AND day BETWEEN ? AND ?)`, from, to).n;
    const surveys = q("SELECT data FROM events WHERE kind = 'survey' AND day BETWEEN ? AND ?", from, to)
      .map((r) => JSON.parse(r.data));
    const buyers = one(
      "SELECT COUNT(DISTINCT who) AS n FROM events WHERE kind = 'purchase' AND day BETWEEN ? AND ?", from, to).n;
    const sessions = one(
      "SELECT COUNT(*) AS n FROM events WHERE kind = 'session_start' AND day BETWEEN ? AND ?", from, to).n;
    return {
      from, to, players,
      sessions,
      crashFree: ends.length ? ends.filter((e) => !e.crashed).length / ends.length : null,
      medianSessionSeconds: median,
      sessionsPerPlayerDay: playerDays ? sessions / playerDays : null,
      chore: surveys.length ? surveys.filter((v) => v.chore).length / surveys.length : null,
      heists,
      worth: ratings.length ? ratings.reduce((a, b) => a + b, 0) / ratings.length : null,
      buyers: players ? buyers / players : null,
      retention: this.retention(from, to),
    };
  }

  /** Retention of the players first seen in [from, to]: the written-down
   *  cohorts, and the rest counted from the raw events. A return day that
   *  has not come yet counts neither way. */
  retention(from, to, now = this.service.now()) {
    const today = day(now);
    const sum = { players: 0, day1: [0, 0], day7: [0, 0], day30: [0, 0], day60: [0, 0] };
    const days = this.db.prepare(
      "SELECT DISTINCT day FROM first_seen WHERE day BETWEEN ? AND ? ORDER BY day").all(from, to);
    for (const { day: d } of days) {
      const c = this.db.prepare("SELECT * FROM cohorts WHERE day = ?").get(d) ?? this.cohort(d);
      sum.players += c.players;
      for (const n of [1, 7, 30, 60]) {
        if (plus(d, n) >= today || c[`day${n}`] == null) continue;
        sum[`day${n}`][0] += c[`day${n}`];
        sum[`day${n}`][1] += c.players;
      }
    }
    const share = ([back, of]) => (of ? back / of : null);
    return { players: sum.players, day1: share(sum.day1), day7: share(sum.day7), day30: share(sum.day30),
             day60: share(sum.day60) };
  }

  /** §25.3's churn early warning: "Recency of absence". Each player's days
   *  since their last session, counted into bands. */
  absence(now = this.service.now()) {
    const bands = { "0-1": 0, "2-3": 0, "4-7": 0, "8-14": 0, "15+": 0 };
    for (const r of this.db.prepare(
      "SELECT MAX(at) AS last FROM events WHERE kind = 'session_start' GROUP BY who").all()) {
      const d = Math.floor((now - r.last) / DAY_MS);
      bands[d <= 1 ? "0-1" : d <= 3 ? "2-3" : d <= 7 ? "4-7" : d <= 14 ? "8-14" : "15+"]++;
    }
    return bands;
  }
}
