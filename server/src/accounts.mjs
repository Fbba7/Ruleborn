// Account and data deletion (§20.5, §20.11).
//
// §20.5: "Account and data deletion from inside the game." §20.11: the
// stores require "account deletion inside the app", and the law requires
// "no accounts below 13, and immediate deletion of anything collected from
// someone who turns out to be younger".
//
// Against that, the document keeps records that are never edited: the
// ledger is append-only (§24.12), a snapshot is "Never edited" (§24.8), and
// "player creations are never deleted or overwritten" (§19.11). F43 is that
// tension. The reading here: what identifies a person goes — the platform
// identity, the telemetry under their pseudonym, their place in every list,
// group and matchmaking pool — and the records that are about heists,
// money and islands stay, keyed by an account id that no longer leads to
// anyone. Their Workshop islands are withdrawn, not deleted, so a remix
// still names its original. A banned account keeps its platform identity:
// §20.12's "The minimum identifiers needed to enforce the ban are kept", so
// deleting it is no way back in.

import { transaction } from "./db.mjs";
import { Refused } from "./refused.mjs";

export const REASONS = ["requested", "under-13"];

/**
 * Delete an account, in one transaction: all of it or none of it, so a
 * deletion that fails can be asked for again. Idempotent. Returns what was
 * done.
 */
export function deleteAccount(service, account, reason = "requested") {
  if (!REASONS.includes(reason)) throw new Refused(400, "no_such_reason");
  const db = service.db;
  const now = service.now();
  const row = db.prepare("SELECT * FROM accounts WHERE id = ?").get(account);
  if (!row) throw new Refused(404, "no_such_account");
  const who = service.telemetry.pseudonym(account);
  const done = transaction(db, () => {
    db.prepare(
      `UPDATE accounts SET platform_identity = CASE WHEN banned_at IS NULL THEN ? ELSE platform_identity END,
         deleted_at = COALESCE(deleted_at, ?),
         deleted_reason = COALESCE(deleted_reason, ?), equipped = '{}', push_token = NULL,
         reminder_at = NULL WHERE id = ?`)
      .run(`deleted:${account}`, now, reason, account);
    // Out of matchmaking and the target lists: an island row is what makes a
    // snapshot a target (service.lease).
    const islands = db.prepare("DELETE FROM islands WHERE owner = ?").run(account).changes;
    // A raid already leased on one of them still settles: the raider played
    // it honestly, and what it books is keyed by the opaque id.
    const withdrawn = db.prepare(
      "UPDATE workshop_items SET withdrawn_at = ? WHERE creator = ? AND withdrawn_at IS NULL")
      .run(now, account).changes;
    const events = db.prepare("SELECT COUNT(*) AS n FROM events WHERE who = ?").get(who).n;
    db.prepare("DELETE FROM event_batches WHERE who = ?").run(who);
    db.prepare("DELETE FROM first_seen WHERE who = ?").run(who);
    // Friendships are between people: they end, with the invites and links.
    db.prepare("DELETE FROM friends WHERE a = ? OR b = ?").run(account, account);
    db.prepare("DELETE FROM friend_invites WHERE account = ?").run(account);
    db.prepare("DELETE FROM challenges WHERE account = ?").run(account);
    // Their groups, as Social.leave and leaveCrew do, but inside this
    // transaction: a founder hands the constellation on — to the
    // longest-standing elder, else the longest-standing member (§17.7).
    const left = [];
    const m = db.prepare(
      "SELECT * FROM constellation_members WHERE account = ? AND left_at IS NULL").get(account);
    if (m) {
      db.prepare("UPDATE constellation_members SET left_at = ? WHERE account = ? AND left_at IS NULL")
        .run(now, account);
      if (m.role === "founder") {
        db.prepare(
          `UPDATE constellation_members SET role = 'founder' WHERE rowid = (
             SELECT rowid FROM constellation_members WHERE constellation = ? AND left_at IS NULL
              ORDER BY role = 'elder' DESC, joined_at, rowid LIMIT 1)`).run(m.constellation);
      }
      left.push(m.constellation);
    }
    const crew = db.prepare(
      "SELECT crew FROM crew_members WHERE account = ? AND left_at IS NULL").get(account)?.crew;
    if (crew) {
      db.prepare("UPDATE crew_members SET left_at = ? WHERE account = ? AND left_at IS NULL")
        .run(now, account);
      left.push(crew);
    }
    return { islands: Number(islands), withdrawn: Number(withdrawn), events: Number(events), left };
  });
  return { deleted: true, reason: row.deleted_reason ?? reason, ...done };
}
