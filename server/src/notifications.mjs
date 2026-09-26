// Notifications (§13, §14.6, §18.8, §20.2).
//
// §14.6: "Notifications: only for things the player can act on (storage
// full, a character rested, an experiment finished, a heist against you).
// Players choose a daily reminder time, or none, and nothing is sent at
// night (see 20.2)." Storage, rest and experiments are the device's own
// timers; the server sends the one it alone knows of — §13's "The defender
// is notified afterwards and can watch the replay" — and the daily reminder
// a player chose. §20.2 keeps the night: never 21:00 to 08:00 at 13 to 15,
// never 22:00 to 08:00 at 16 and 17, and off 22:00 to 08:00 by default for
// adults, who may change it. §14's "No escalating notifications" and §18.8's
// "no notification when a season is ending" are why nothing else is here.
//
// A notification waits in an outbox until it is due, and is sent by
// `deliver` through an injected `push` (Firebase Cloud Messaging, §24.1),
// which needs the operator's credentials (D68).
//
// The owner's answer to G34: raids against a player gather across their
// local day into one message, sent at their reminder time with the
// reminder, or at the end of their night if they chose none; a reminder
// time inside the night is refused. And the clock the brief proposed with
// it: the device reports its IANA time zone (with its push token, and on
// every launch), the night is worked out in that zone — so a daylight-saving
// change moves nothing — and no push goes to an account that has not
// reported one.

import { readFileSync } from "node:fs";

import { transaction } from "./db.mjs";
import { Refused } from "./refused.mjs";

const facts = JSON.parse(readFileSync(new URL("./facts.json", import.meta.url), "utf8"));
const MINUTE = 60 * 1000;
const DAY = 24 * 60 * MINUTE;

const clocks = new Map();
/** A zone's clock. Kept by canonical IANA name only, so the cache is bounded
 *  by the zones there are, however a device spells one. */
function clock(zone) {
  if (!clocks.has(zone)) {
    clocks.set(zone, new Intl.DateTimeFormat("en-US", {
      timeZone: zone, hourCycle: "h23", year: "numeric", month: "numeric", day: "numeric",
      hour: "numeric", minute: "numeric", second: "numeric" }));
  }
  return clocks.get(zone);
}

/** A device's time zone as the IANA region it names ("america/sao_paulo" is
 *  America/Sao_Paulo), or null: not a zone, or a fixed offset such as
 *  "+05:30" or "Etc/GMT+5", which daylight saving would make wrong (G34). */
export function canonicalZone(zone) {
  if (typeof zone !== "string" || zone.length === 0 || zone.length > 64) return null;
  let canonical;
  try {
    canonical = new Intl.DateTimeFormat("en-US", { timeZone: zone }).resolvedOptions().timeZone;
  } catch {
    return null;
  }
  if (canonical === "UTC") return canonical;
  return /^[A-Za-z]+\/[A-Za-z0-9_+\-\/]+$/.test(canonical) && !canonical.startsWith("Etc/") ? canonical : null;
}

/** Minutes a zone is ahead of UTC at the instant `at` (UTC with no zone). */
export function offsetAt(zone, at) {
  if (!zone) return 0;
  const c = clock(zone);
  const p = Object.fromEntries(c.formatToParts(new Date(at)).map((x) => [x.type, x.value]));
  const wall = Date.UTC(Number(p.year), Number(p.month) - 1, Number(p.day), Number(p.hour), Number(p.minute),
                        Number(p.second));
  return Math.round((wall - (at - (((at % 1000) + 1000) % 1000))) / MINUTE);
}

/** The wall-clock time `at` reads in `zone`, as a UTC-based number. */
const wall = (zone, at) => at + offsetAt(zone, at) * MINUTE;
/** The instant a wall-clock time in `zone` names: the offset is looked up
 *  where the answer lands, twice, so a time beside a daylight-saving change
 *  comes out right. A wall time the change skips (02:30 on a spring-forward
 *  night) does not exist; it lands just after the gap. */
export function instant(zone, local) {
  const before = local - offsetAt(zone, local) * MINUTE;
  const at = local - offsetAt(zone, before) * MINUTE;
  if (wall(zone, at) === local) return at;
  // In a gap: of the two readings, the later is the one after it.
  return Math.max(at, before);
}

/** Whether minute `m` of a local day is inside a night from `from` to `to`
 *  o'clock (the night crosses midnight). */
const atNight = (m, [from, to]) => m >= from * 60 || m < to * 60;
/** How long a sent notification is kept: past the three days the reminder
 *  check reads back, and no longer (§20.5, G38). */
export const SENT_KEEP_DAYS = 7;
/** A notification the push service could not take is tried again after
 *  RETRY_MS times the tries so far, RETRY_ATTEMPTS times in all (D68). */
export const RETRY_MS = 5 * 60 * 1000;
export const RETRY_ATTEMPTS = 6;

export class Notifications {
  constructor(service) {
    this.service = service;
  }

  get db() { return this.service.db; }

  settings(account) {
    const a = this.db.prepare(
      "SELECT age_band, time_zone, reminder_at, night_quiet, push_token FROM accounts WHERE id = ?").get(account);
    return { ageBand: a.age_band, timeZone: a.time_zone, reminder: a.reminder_at,
             nightQuiet: Boolean(a.night_quiet), push: Boolean(a.push_token) };
  }

  /** The night the player keeps: its hours, or null for an adult who
   *  opened it. */
  night(s) {
    return s.ageBand === "18+" && !s.nightQuiet ? null : facts.NIGHT_HOURS[s.ageBand];
  }

  /**
   * The player's choices: their device's IANA time zone, a daily reminder
   * time in minutes after local midnight or null for none, whether an
   * adult's nights are quiet, and the device's push token. §20.2's minors
   * cannot open the night, and a reminder cannot be set inside it (G34).
   */
  set(account, { timeZone, reminder, nightQuiet, pushToken } = {}) {
    const updates = {};
    if (timeZone !== undefined) {
      const canonical = canonicalZone(timeZone);
      if (!canonical) throw new Refused(400, "bad_time_zone");
      updates.time_zone = canonical;
    }
    if (reminder !== undefined) {
      if (reminder !== null && (!Number.isInteger(reminder) || reminder < 0 || reminder >= 24 * 60)) {
        throw new Refused(400, "bad_reminder_time");
      }
      updates.reminder_at = reminder;
    }
    if (nightQuiet !== undefined) {
      if (nightQuiet !== true && this.settings(account).ageBand !== "18+") {
        throw new Refused(403, "the_night_is_always_quiet_under_18");
      }
      updates.night_quiet = nightQuiet ? 1 : 0;
    }
    // G34: a reminder asked for inside the night is refused. One already
    // stored that the night now covers — an adult quietening the night
    // again, an age band that changed, a reminder set before the rule — is
    // cleared instead, and the answer says so, so the device can ask for a
    // new time; it never blocks the rest of the call.
    const was = this.settings(account);
    const after = { ...was, reminder: "reminder_at" in updates ? updates.reminder_at : was.reminder,
                    nightQuiet: "night_quiet" in updates ? Boolean(updates.night_quiet) : was.nightQuiet };
    const night = this.night(after);
    let cleared = false;
    if (after.reminder !== null && night && atNight(after.reminder, night)) {
      if ("reminder_at" in updates) throw new Refused(400, "reminder_at_night", { night });
      updates.reminder_at = null;
      cleared = true;
    }
    if (pushToken !== undefined) {
      if (pushToken !== null && (typeof pushToken !== "string" || pushToken.length > 4096)) {
        throw new Refused(400, "bad_push_token");
      }
      updates.push_token = pushToken;
    }
    transaction(this.db, () => {
      for (const [column, value] of Object.entries(updates)) {
        this.db.prepare(`UPDATE accounts SET ${column} = ? WHERE id = ?`).run(value, account);
      }
      // A day's raids waiting for their message move with the day's turn:
      // a changed reminder, zone or night moves when they are told (G34).
      if ("reminder_at" in updates || "time_zone" in updates || "night_quiet" in updates) {
        const due = this.digest(account, this.service.now());
        this.db.prepare(
          "UPDATE notifications SET due_at = ? WHERE account = ? AND kind = 'raided' AND sent_at IS NULL")
          .run(due, account);
      }
    });
    return { ...this.settings(account), ...(cleared ? { reminderCleared: true } : {}) };
  }

  /**
   * When a notification sent at `at` stops being worth showing: the start
   * of the player's next night, so a phone that is off or asleep never
   * shows it inside §20.2's night; a reminder also at the end of its local
   * day; and a day at most. FCM and Apple hold it until then and drop it
   * after (push.mjs).
   */
  expires(account, kind, at) {
    const s = this.settings(account);
    const zone = s.timeZone;
    const local = wall(zone, at);
    const midnight = local - (local % DAY);
    let until = at + DAY;
    if (kind === "reminder") until = Math.min(until, instant(zone, midnight + DAY));
    const night = this.night(s);
    if (night) {
      let start = midnight + night[0] * 60 * MINUTE;
      if (local >= start) start += DAY;
      until = Math.min(until, instant(zone, start));
    }
    return until;
  }

  /** The first moment at or after `at` outside the player's night. */
  due(account, at) {
    const s = this.settings(account);
    const night = this.night(s);
    if (!night) return at;
    const [from, to] = night;
    const local = wall(s.timeZone, at);
    const minute = Math.floor((local % DAY) / MINUTE);
    if (!atNight(minute, night)) return at;
    // Inside the night: its end, today's if before it, else tomorrow's.
    const midnight = local - (local % DAY);
    return instant(s.timeZone, midnight + to * 60 * MINUTE + (minute >= from * 60 ? DAY : 0));
  }

  /**
   * When a raid landing at `at` is told (G34): at the player's next
   * reminder time, or with none chosen at the next end of their night —
   * the §20.2 hour their night ends, which an adult who opened the night
   * still has as the day's turn — so a local day's raids are one message.
   */
  digest(account, at) {
    const s = this.settings(account);
    const minute = s.reminder ?? facts.NIGHT_HOURS[s.ageBand][1] * 60;
    const local = wall(s.timeZone, at);
    const midnight = local - (local % DAY);
    let next = instant(s.timeZone, midnight + minute * MINUTE);
    if (next < at) next = instant(s.timeZone, midnight + DAY + minute * MINUTE);
    return this.due(account, next);
  }

  /** §13: a heist against a player, in the grant's transaction. The day's
   *  raids before one is sent are one notification (G34). */
  raided(lease, verdict, now) {
    // A raid leased before its defender's account was deleted or banned
    // still settles, and owes nobody a notification.
    const defender = this.db.prepare("SELECT deleted_at, banned_at FROM accounts WHERE id = ?").get(lease.defender);
    if (defender.deleted_at || defender.banned_at) return null;
    const waiting = this.db.prepare(
      "SELECT * FROM notifications WHERE account = ? AND kind = 'raided' AND sent_at IS NULL")
      .get(lease.defender);
    if (waiting) {
      const data = JSON.parse(waiting.data);
      data.heists.push({ heist: lease.token, grade: verdict.grade });
      this.db.prepare("UPDATE notifications SET data = ? WHERE id = ?").run(JSON.stringify(data), waiting.id);
      return waiting.id;
    }
    const data = { heists: [{ heist: lease.token, grade: verdict.grade }] };
    return Number(this.db.prepare(
      "INSERT INTO notifications (account, kind, data, due_at) VALUES (?, 'raided', ?, ?)")
      .run(lease.defender, JSON.stringify(data), this.digest(lease.defender, now)).lastInsertRowid);
  }

  /** The day's reminder for every player who chose a time and has none
   *  queued for their local today. One still held by the night becomes
   *  today's, so the night's end brings one reminder, not two. */
  remind(now) {
    const rows = this.db.prepare(
      `SELECT id, time_zone, reminder_at FROM accounts
        WHERE reminder_at IS NOT NULL AND time_zone IS NOT NULL
          AND deleted_at IS NULL AND banned_at IS NULL`).all();
    // The outbox is read once, through notifications_due: a reminder for a
    // local today was sent at or after its time, within three days of now
    // whatever the offsets (±14 hours).
    const had = new Set();
    const waiting = new Map();
    for (const r of this.db.prepare(
      `SELECT id, account, json_extract(data, '$.day') AS day, sent_at FROM notifications
        WHERE kind = 'reminder' AND (sent_at IS NULL OR sent_at >= ?)`).all(now - 3 * DAY)) {
      had.add(`${r.account} ${r.day}`);
      if (r.sent_at === null) waiting.set(r.account, r.id);
    }
    let queued = 0;
    for (const a of rows) {
      const local = wall(a.time_zone, now);
      const midnight = local - (local % DAY);
      const at = instant(a.time_zone, midnight + a.reminder_at * MINUTE);
      if (now < at) continue;
      const day = new Date(midnight).toISOString().slice(0, 10);
      if (had.has(`${a.id} ${day}`)) continue;
      if (waiting.has(a.id)) {
        // Only its day: raids already gathered into it stay in it.
        this.db.prepare("UPDATE notifications SET data = json_set(data, '$.day', ?) WHERE id = ?")
          .run(day, waiting.get(a.id));
        continue;
      }
      // §20.2: a time already passed is sent now, and now may be night.
      this.db.prepare("INSERT INTO notifications (account, kind, data, due_at) VALUES (?, 'reminder', ?, ?)")
        .run(a.id, JSON.stringify({ day }), this.due(a.id, Math.max(at, now)));
      queued++;
    }
    return queued;
  }

  /**
   * Send what is due. `push(token, message)` delivers one and may be
   * asynchronous (push.mjs); it resolves nothing, or what became of it:
   * `{gone: true}` — the device's token is no longer valid, so it is
   * cleared; `{retry: true}` — the push service could not take it now, so
   * it waits RETRY_MS a try, and after RETRY_ATTEMPTS is given up; or
   * `{dropped: true}` — refused for good, and not tried again. A player
   * with no token gets nothing sent, and the notification is marked done so
   * it never piles up; so does a player whose device has not reported its
   * time zone. A reminder carries the raids waiting with it (G34). Each is
   * claimed before it is sent, so a raid that
   * lands meanwhile starts a notification of its own rather than joining
   * one already on its way; and a tick still sending makes the next one
   * wait. Returns what was sent.
   */
  async deliver(push, now = this.service.now()) {
    if (this.delivering) return [];
    this.delivering = true;
    try {
      return await this.send(push, now);
    } finally {
      this.delivering = false;
    }
  }

  async send(push, start) {
    this.remind(start);
    // G34: every raid still waiting goes inside the day's reminder when it
    // is sent, whenever the raid was due. Read and written in one
    // transaction, so a raid that lands meanwhile is in it or waits.
    for (const { id } of this.db.prepare(
      "SELECT id FROM notifications WHERE kind = 'reminder' AND sent_at IS NULL AND due_at <= ?").all(start)) {
      transaction(this.db, () => {
        const r = this.db.prepare("SELECT account, data FROM notifications WHERE id = ? AND sent_at IS NULL").get(id);
        if (!r) return;
        const waiting = this.db.prepare(
          "SELECT id, data FROM notifications WHERE account = ? AND kind = 'raided' AND sent_at IS NULL ORDER BY id")
          .all(r.account);
        if (!waiting.length) return;
        const data = JSON.parse(r.data);
        data.heists = [...(data.heists ?? []), ...waiting.flatMap((w) => JSON.parse(w.data).heists)];
        this.db.prepare("UPDATE notifications SET data = ? WHERE id = ?").run(JSON.stringify(data), id);
        for (const w of waiting) this.db.prepare("DELETE FROM notifications WHERE id = ?").run(w.id);
      });
    }
    const due = this.db.prepare(
      `SELECT n.* FROM notifications n JOIN accounts a ON a.id = n.account
        WHERE n.sent_at IS NULL AND n.due_at <= ? AND a.deleted_at IS NULL ORDER BY n.due_at, n.id`).all(start);
    const sent = [];
    // What became of the tick, by reason, for the operator's log: a broken
    // key or project shows as every push tried again, never silently.
    const tick = this.tick = { sent: 0, gone: 0, dropped: {}, retried: {}, gaveUp: {} };
    const count = (map, why) => { map[why] = (map[why] ?? 0) + 1; };
    for (const n of due) {
      // The clock as it is now, not when the tick began: each push is
      // awaited, and a slow FCM must not carry a send into the night.
      const now = this.service.now();
      // §20.2 holds when it is sent: a notification due by day may be sent
      // only after the night began (a late tick, downtime), and waits again.
      const open = this.due(n.account, now);
      if (open > now) {
        this.db.prepare("UPDATE notifications SET due_at = ? WHERE id = ? AND sent_at IS NULL").run(open, n.id);
        continue;
      }
      // Claimed: a second server sending the same outbox takes none twice.
      const claimed = this.db.prepare("UPDATE notifications SET sent_at = ? WHERE id = ? AND sent_at IS NULL")
        .run(now, n.id).changes;
      if (!claimed) continue;
      // The token as it is now: one turned off or replaced meanwhile is not used.
      const a = this.db.prepare("SELECT push_token, time_zone, deleted_at FROM accounts WHERE id = ?").get(n.account);
      if (!a?.push_token || !a.time_zone || a.deleted_at) continue;
      const message = { kind: n.kind, ...JSON.parse(n.data) };
      const outcome = await push(a.push_token, message, { expiresAt: this.expires(n.account, n.kind, now), now });
      const why = outcome?.status ? `${outcome.status}${outcome.code ? ` ${outcome.code}` : ""}` : (outcome?.reason ?? "unknown");
      if (outcome?.gone) {
        tick.gone++;
        this.db.prepare("UPDATE accounts SET push_token = NULL WHERE id = ? AND push_token = ?")
          .run(n.account, a.push_token);
      } else if (outcome?.retry) {
        const attempts = n.attempts + 1;
        if (attempts < RETRY_ATTEMPTS) {
          count(tick.retried, why);
          this.db.prepare("UPDATE notifications SET sent_at = NULL, attempts = ?, due_at = ? WHERE id = ?")
            .run(attempts, now + attempts * RETRY_MS, n.id);
        } else {
          count(tick.gaveUp, why);
          this.db.prepare("UPDATE notifications SET attempts = ? WHERE id = ?").run(attempts, n.id);
        }
      } else if (outcome?.dropped) {
        count(tick.dropped, why);
      } else {
        tick.sent++;
        sent.push({ account: n.account, ...message });
      }
    }
    return sent;
  }

  /** Sent notifications past SENT_KEEP_DAYS, deleted. Idempotent. */
  expire(now = this.service.now()) {
    return Number(this.db.prepare("DELETE FROM notifications WHERE sent_at IS NOT NULL AND sent_at < ?")
      .run(now - SENT_KEEP_DAYS * DAY).changes);
  }
}
