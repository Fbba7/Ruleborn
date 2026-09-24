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
// which needs the operator's credentials (D68). Raids that land while a
// player sleeps are gathered into one.

import { readFileSync } from "node:fs";

import { transaction } from "./db.mjs";
import { Refused } from "./refused.mjs";

const facts = JSON.parse(readFileSync(new URL("./facts.json", import.meta.url), "utf8"));
const MINUTE = 60 * 1000;
const DAY = 24 * 60 * MINUTE;

export class Notifications {
  constructor(service) {
    this.service = service;
  }

  get db() { return this.service.db; }

  settings(account) {
    const a = this.db.prepare(
      "SELECT age_band, utc_offset, reminder_at, night_quiet, push_token FROM accounts WHERE id = ?").get(account);
    return { ageBand: a.age_band, utcOffset: a.utc_offset, reminder: a.reminder_at,
             nightQuiet: Boolean(a.night_quiet), push: Boolean(a.push_token) };
  }

  /**
   * The player's choices: their clock's offset from UTC in minutes (the
   * device knows it), a daily reminder time in minutes after local
   * midnight or null for none, whether an adult's nights are quiet, and the
   * device's push token. §20.2's minors cannot open the night.
   */
  set(account, { utcOffset, reminder, nightQuiet, pushToken } = {}) {
    const updates = {};
    if (utcOffset !== undefined) {
      if (!Number.isInteger(utcOffset) || Math.abs(utcOffset) > 14 * 60) throw new Refused(400, "bad_utc_offset");
      updates.utc_offset = utcOffset;
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
    if (pushToken !== undefined) {
      if (pushToken !== null && (typeof pushToken !== "string" || pushToken.length > 4096)) {
        throw new Refused(400, "bad_push_token");
      }
      updates.push_token = pushToken;
    }
    for (const [column, value] of Object.entries(updates)) {
      this.db.prepare(`UPDATE accounts SET ${column} = ? WHERE id = ?`).run(value, account);
    }
    return this.settings(account);
  }

  /** The first moment at or after `at` outside the player's night. */
  due(account, at) {
    const s = this.settings(account);
    const [from, to] = facts.NIGHT_HOURS[s.ageBand];
    if (s.ageBand === "18+" && !s.nightQuiet) return at;
    const local = at + s.utcOffset * MINUTE;
    const hour = new Date(local).getUTCHours();
    if (hour >= to && hour < from) return at;
    // Inside the night: its end, today's if before it, else tomorrow's.
    const midnight = local - (local % DAY);
    const end = midnight + to * 60 * MINUTE + (hour >= from ? DAY : 0);
    return end - s.utcOffset * MINUTE;
  }

  /** §13: a heist against a player, in the grant's transaction. Several
   *  raids before one is sent are one notification. */
  raided(lease, verdict, now) {
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
      .run(lease.defender, JSON.stringify(data), this.due(lease.defender, now)).lastInsertRowid);
  }

  /** The day's reminder for every player who chose a time and has none
   *  queued for their local today. */
  remind(now) {
    const rows = this.db.prepare(
      `SELECT id, utc_offset, reminder_at FROM accounts
        WHERE reminder_at IS NOT NULL AND deleted_at IS NULL AND banned_at IS NULL`).all();
    let queued = 0;
    for (const a of rows) {
      const local = now + a.utc_offset * MINUTE;
      const midnight = local - (local % DAY);
      const at = midnight + a.reminder_at * MINUTE - a.utc_offset * MINUTE;
      if (now < at) continue;
      const day = new Date(midnight).toISOString().slice(0, 10);
      const had = this.db.prepare(
        "SELECT 1 FROM notifications WHERE account = ? AND kind = 'reminder' AND json_extract(data, '$.day') = ?")
        .get(a.id, day);
      if (had) continue;
      this.db.prepare("INSERT INTO notifications (account, kind, data, due_at) VALUES (?, 'reminder', ?, ?)")
        .run(a.id, JSON.stringify({ day }), this.due(a.id, at));
      queued++;
    }
    return queued;
  }

  /**
   * Send what is due. `push(token, message)` delivers one; a player with no
   * token gets nothing sent, and the notification is marked done so it
   * never piles up. Returns what was sent.
   */
  deliver(push, now = this.service.now()) {
    this.remind(now);
    const due = this.db.prepare(
      `SELECT n.*, a.push_token FROM notifications n JOIN accounts a ON a.id = n.account
        WHERE n.sent_at IS NULL AND n.due_at <= ? AND a.deleted_at IS NULL ORDER BY n.due_at, n.id`).all(now);
    const sent = [];
    for (const n of due) {
      const message = { kind: n.kind, ...JSON.parse(n.data) };
      if (n.push_token) {
        push(n.push_token, message);
        sent.push({ account: n.account, ...message });
      }
      this.db.prepare("UPDATE notifications SET sent_at = ? WHERE id = ?").run(now, n.id);
    }
    return sent;
  }
}
