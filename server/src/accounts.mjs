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
// still names its original. A banned identity stays in the bans table, apart
// from the account: §20.12's "The minimum identifiers needed to enforce the
// ban are kept", so deleting it is no way back in, and its records are
// severed like anyone's.
//
// An account deleted because its player is under 13 goes further: "immediate
// deletion of anything collected" is read as everything the records that
// are never edited do not hold — the replays they played, their islands'
// bytes, their ratings, their Workshop plays, ratings and completions, and
// their open leases. What stays is what F43 leaves to the owner: the
// ledger, Renown, season stars and purchases, which are append-only, and
// the snapshot and Workshop rows, which name an island by its hash.
//
// §20.12's "Erasure completes within thirty days, backups included, with a
// log kept": each deletion is written to a journal outside the database
// before it is made, so a database restored from before it has it made
// again when the server starts (`reapplyDeletions`). The journal holds the
// account id, the reason and the time, and nothing that names a person.

import { closeSync, existsSync, fsyncSync, openSync, readFileSync, writeSync } from "node:fs";

import { transaction } from "./db.mjs";
import { Refused } from "./refused.mjs";

export const REASONS = ["requested", "under-13"];

/** The deletion journal: one line a deletion, appended and synced before the
 *  deletion is made. In memory without a path. */
export class Journal {
  constructor(path = null) {
    this.path = path;
    this.memory = [];
  }

  append(entry) {
    if (!this.path) {
      this.memory.push({ ...entry });
      return;
    }
    const fd = openSync(this.path, "a", 0o600);
    try {
      writeSync(fd, `${JSON.stringify(entry)}\n`);
      fsyncSync(fd);
    } finally {
      closeSync(fd);
    }
  }

  /** Every entry, oldest first; a line cut short by a crash is skipped. */
  entries() {
    if (!this.path) return this.memory.map((e) => ({ ...e }));
    if (!existsSync(this.path)) return [];
    return readFileSync(this.path, "utf8").split("\n").flatMap((line) => {
      try {
        const e = JSON.parse(line);
        return typeof e?.account === "string" && REASONS.includes(e.reason) ? [e] : [];
      } catch {
        return [];
      }
    });
  }
}

/**
 * Delete an account, in one transaction: all of it or none of it, so a
 * deletion that fails can be asked for again. Idempotent. Returns what was
 * done. `journal: false` is a deletion made again from the journal.
 */
export function deleteAccount(service, account, reason = "requested", { journal = true } = {}) {
  if (!REASONS.includes(reason)) throw new Refused(400, "no_such_reason");
  const db = service.db;
  const now = service.now();
  const row = db.prepare("SELECT * FROM accounts WHERE id = ?").get(account);
  if (!row) throw new Refused(404, "no_such_account");
  // Written ahead: a deletion the database then loses to a crash or a
  // restore is still in the journal, and is made again.
  if (journal && !row.deleted_at) service.deletions.append({ account, reason, at: now });
  const who = service.telemetry.pseudonym(account);
  const files = { replays: [], bundles: [] };
  const done = transaction(db, () => {
    // A ban outlives the account on its identity alone.
    if (row.banned_at && !row.platform_identity.startsWith("deleted:")) {
      db.prepare("INSERT OR IGNORE INTO bans (identity, banned_at, reason) VALUES (?, ?, ?)")
        .run(row.platform_identity, row.banned_at, row.banned_reason);
    }
    db.prepare(
      `UPDATE accounts SET platform_identity = ?,
         deleted_at = COALESCE(deleted_at, ?),
         deleted_reason = COALESCE(deleted_reason, ?), equipped = '{}', push_token = NULL,
         reminder_at = NULL, utc_offset = 0, night_quiet = 1 WHERE id = ?`)
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
    // What was owed them and never sent, and what was: nobody to send it to.
    db.prepare("DELETE FROM notifications WHERE account = ?").run(account);
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
    const erased = reason === "under-13" ? erase(db, account, files) : undefined;
    return { islands: Number(islands), withdrawn: Number(withdrawn), events: Number(events), left,
             ...(erased ? { erased } : {}) };
  });
  // The files once the rows that name them are gone: a file deleted before a
  // transaction that then failed could not be put back.
  for (const hash of files.replays) service.replays.delete(hash);
  for (const hash of files.bundles) service.store.delete(hash);
  // Off every target list now, not at the next regeneration, and off the
  // list before it too.
  if (reason === "under-13") service.targetLists({ keepPrevious: false });
  return { deleted: true, reason: row.deleted_reason ?? reason, ...done };
}

/** §20.11's under-13 deletion, beyond what every deletion does: inside
 *  deleteAccount's transaction, with the files to delete after it. */
function erase(db, account, files) {
  // The replays they played. Two heists can carry the same bytes; the file
  // goes when no heist still keeps it.
  const played = db.prepare(
    "SELECT token, log_hash FROM heists WHERE attacker = ? AND replay_gone = 0").all(account);
  for (const h of played) db.prepare("UPDATE heists SET replay_gone = 1 WHERE token = ?").run(h.token);
  for (const hash of new Set(played.map((h) => h.log_hash))) {
    if (!db.prepare("SELECT 1 FROM heists WHERE log_hash = ? AND replay_gone = 0").get(hash)) {
      files.replays.push(hash);
    }
  }
  // Their islands' bytes, unless another player's island, Workshop island or
  // challenge link is the same bytes.
  const bundles = db.prepare(
    `SELECT bundle FROM snapshots WHERE owner = :a
      UNION SELECT bundle FROM workshop_items WHERE creator = :a`).all({ a: account }).map((r) => r.bundle);
  for (const bundle of bundles) {
    const shared = db.prepare(
      `SELECT 1 FROM islands WHERE bundle = :b AND owner != :a
        UNION ALL SELECT 1 FROM workshop_items WHERE bundle = :b AND creator != :a
        UNION ALL SELECT 1 FROM challenges WHERE bundle = :b AND account != :a LIMIT 1`)
      .get({ a: account, b: bundle });
    if (!shared) files.bundles.push(bundle);
  }
  const ratings = db.prepare(
    "DELETE FROM ratings WHERE (kind = 'raider' AND key = ?) OR (kind = 'island' AND substr(key, 1, ?) = ?)")
    .run(account, account.length + 1, `${account}/`).changes;
  // A lease they held and never played reserved nothing (§24.13).
  const leases = db.prepare(
    `DELETE FROM leases WHERE attacker = ? AND state = 'open'
        AND token NOT IN (SELECT token FROM heists)`).run(account).changes;
  const workshop = ["workshop_plays", "workshop_ratings", "workshop_completions", "workshop_remixes"]
    .reduce((n, table) => n + Number(db.prepare(`DELETE FROM ${table} WHERE player = ?`).run(account).changes), 0);
  // A report they made still stands for a moderator to act on, as nobody's.
  db.prepare("UPDATE workshop_reports SET reporter = NULL WHERE reporter = ?").run(account);
  return { replays: played.length, bundles: files.bundles.length, ratings: Number(ratings),
           leases: Number(leases), workshop };
}

/** Every journalled deletion the database does not hold — as after a
 *  restore from before it — made again. Run when the server starts. */
export function reapplyDeletions(service) {
  let made = 0;
  for (const e of service.deletions.entries()) {
    const row = service.db.prepare("SELECT deleted_at FROM accounts WHERE id = ?").get(e.account);
    if (row && !row.deleted_at) {
      deleteAccount(service, e.account, e.reason, { journal: false });
      made++;
    }
  }
  return made;
}
