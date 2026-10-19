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
// anyone. Their Workshop islands stay listed and playable with no creator
// shown, unless the player asks for them to be withdrawn too (F43, decided:
// "withdraw my islands too"); withdrawn, not deleted, so a remix still names
// its original. An under-13 player's are always withdrawn. A banned identity stays in the bans table, apart
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
// account id, the reason, the time and whether the player withdrew their
// Workshop islands, and nothing that names a person.
//
// The owner's answer to F50: the journal is in object storage, one object an
// entry, written before the deletion; at every start — the node server's and
// the edge handler's — the entries of the last REAPPLY_DAYS are made again,
// the restore window and a day, since a restore cannot bring back anything
// older. It is kept for good as §20.12's log.

import { transaction } from "./db.mjs";
import { purgeEdge, queuePurge } from "./edge.mjs";
import { Refused } from "./refused.mjs";
import { Store } from "./store.mjs";

export const REASONS = ["requested", "under-13"];

/** How far back a start makes deletions again: a restore reaches back 30
 *  days (§20.12's "within thirty days"), and one more covers the day it was
 *  taken (F50). */
export const RESTORE_DAYS = 30;
export const REAPPLY_DAYS = RESTORE_DAYS + 1;

/** The deletion journal: an object a deletion, in an object store (store.mjs,
 *  content-addressed, so an entry written twice is one object), put before
 *  the deletion is made. In memory without a store. */
export class Journal {
  constructor(store = new Store()) {
    this.store = store;
  }

  /** Put on the disk itself before it returns: the deletion it announces
   *  is made only after (F50). */
  append(entry) {
    this.store.put(new TextEncoder().encode(JSON.stringify(entry)), null, { durable: true });
  }

  /** Every entry, oldest first; an object that is not one is skipped. */
  entries() {
    return this.store.keys().flatMap((key) => {
      try {
        const e = JSON.parse(new TextDecoder().decode(this.store.get(key)));
        return typeof e?.account === "string" && REASONS.includes(e.reason) && Number.isInteger(e.at) ? [e] : [];
      } catch {
        return [];
      }
    }).sort((a, b) => a.at - b.at || (a.account < b.account ? -1 : 1));
  }
}

/**
 * Delete an account, in one transaction: all of it or none of it, so a
 * deletion that fails can be asked for again. Idempotent. Returns what was
 * done. `withdraw` takes the player's Workshop islands out of the Workshop
 * too (F43); an under-13 deletion always does. `journal: false` is a
 * deletion made again from the journal.
 */
export function deleteAccount(service, account, reason = "requested", { journal = true, withdraw = false } = {}) {
  if (!REASONS.includes(reason)) throw new Refused(400, "no_such_reason");
  if (typeof withdraw !== "boolean") throw new Refused(400, "bad_withdraw");
  // F43: an under-13 player's islands always go; so do a banned player's,
  // whose islands the ban took out of play and no deletion puts back.
  withdraw ||= reason === "under-13";
  const db = service.db;
  const now = service.now();
  const row = db.prepare("SELECT * FROM accounts WHERE id = ?").get(account);
  if (!row) throw new Refused(404, "no_such_account");
  withdraw ||= Boolean(row.banned_at);
  // Written ahead: a deletion the database then loses to a crash or a
  // restore is still in the journal, and is made again.
  if (journal && !row.deleted_at) service.deletions.append({ account, reason, withdraw, at: now });
  const who = service.telemetry.pseudonym(account);
  const done = transaction(db, () => {
    // A ban outlives the account on its identity alone, and the account row
    // keeps nothing of it that could be matched back to the identity: the
    // ban's own time is in no other row (§20.12).
    if (row.banned_at && !row.platform_identity.startsWith("deleted:")) {
      banIdentity(db, row.platform_identity, row.banned_at, row.banned_reason);
    }
    db.prepare(
      `UPDATE accounts SET platform_identity = ?,
         deleted_at = COALESCE(deleted_at, ?),
         deleted_reason = COALESCE(deleted_reason, ?), equipped = '{}', working_on = NULL, guardian_sage = NULL, defences_seen_at = NULL, profile_public = 0,
         keeper_adjective = NULL, keeper_noun = NULL,
         push_token = NULL,
         reminder_at = NULL, time_zone = NULL, night_quiet = 1, terms_version = NULL,
         banned_at = NULL, banned_reason = NULL WHERE id = ?`)
      .run(`deleted:${account}`, now, reason, account);
    // Out of matchmaking and the target lists: an island row is what makes a
    // snapshot a target (service.lease).
    const islands = db.prepare("DELETE FROM islands WHERE owner = ?").run(account).changes;
    // A raid already leased on one of them still settles: the raider played
    // it honestly, and what it books is keyed by the opaque id.
    const withdrawn = withdraw ? db.prepare(
      "UPDATE workshop_items SET withdrawn_at = ? WHERE creator = ? AND withdrawn_at IS NULL")
      .run(now, account).changes : 0;
    const events = db.prepare("SELECT COUNT(*) AS n FROM events WHERE who = ?").get(who).n;
    db.prepare("DELETE FROM event_batches WHERE who = ?").run(who);
    db.prepare("DELETE FROM first_seen WHERE who = ?").run(who);
    // What was owed them and never sent, and what was: nobody to send it to.
    db.prepare("DELETE FROM notifications WHERE account = ?").run(account);
    // Friendships are between people: they end, with the invites and links.
    db.prepare("DELETE FROM friends WHERE a = ? OR b = ?").run(account, account);
    db.prepare("DELETE FROM friend_invites WHERE account = ?").run(account);
    db.prepare("DELETE FROM challenges WHERE account = ?").run(account);
    // Their blocks, and others' blocks of them: nobody left to keep apart.
    db.prepare("DELETE FROM blocks WHERE blocker = ? OR blocked = ?").run(account, account);
    // The universe they built: nobody's home now.
    db.prepare("DELETE FROM realms WHERE owner = ?").run(account);
    db.prepare("DELETE FROM links WHERE owner = ?").run(account);
    db.prepare("DELETE FROM buildings WHERE owner = ?").run(account);
    db.prepare("DELETE FROM characters WHERE owner = ?").run(account);
    db.prepare("DELETE FROM producers WHERE owner = ?").run(account);
    db.prepare("DELETE FROM nurseries WHERE owner = ?").run(account);
    db.prepare("DELETE FROM stray_offers WHERE owner = ?").run(account);
    db.prepare("DELETE FROM studies WHERE owner = ?").run(account);
    db.prepare("DELETE FROM codex WHERE owner = ?").run(account);
    db.prepare("DELETE FROM observatory_refreshes WHERE owner = ?").run(account);
    db.prepare("DELETE FROM lab_experiments WHERE owner = ?").run(account);
    db.prepare("DELETE FROM lab_discoveries WHERE owner = ?").run(account);
    db.prepare("DELETE FROM law_slots WHERE owner = ?").run(account);
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
    const erased = reason === "under-13" ? erase(db, account, now) : undefined;
    return { islands: Number(islands), withdrawn: Number(withdrawn), events: Number(events), left,
             ...(erased ? { erased } : {}) };
  });
  finishErasures(service);
  // The edge's copies, at once if it answers; if not, the server's minute
  // tick asks again (edge.mjs).
  if (done.erased) purgeEdge(service).catch((err) => console.error("edge purge:", err));
  return { deleted: true, reason: row.deleted_reason ?? reason, ...done };
}

/** A ban kept on the identity, to the day: enough to refuse its sign-in,
 *  and no exact time to match against a row the account left (§20.12). */
export function banIdentity(db, identity, at, reason) {
  db.prepare("INSERT OR IGNORE INTO bans (identity, banned_at, reason) VALUES (?, ?, ?)")
    .run(identity, at - (at % DAY_MS), reason);
}

const DAY_MS = 24 * 60 * 60 * 1000;

/**
 * The files an under-13 deletion erases, and the target lists it remakes,
 * done once the rows that name them are gone — a file deleted before a
 * transaction that then failed could not be put back. Each waits in
 * `erasures`, written in the deletion's transaction, until it is done, so a
 * crash between the commit and the files is finished at the next start.
 */
export function finishErasures(service) {
  const db = service.db;
  const pending = db.prepare("SELECT store, hash FROM erasures ORDER BY store, hash").all();
  for (const e of pending) {
    if (e.store === "replays") service.replays.delete(e.hash);
    else if (e.store === "bundles") service.store.delete(e.hash);
  }
  // Off every target list now, not at the next regeneration, and off the
  // list before it too.
  if (pending.some((e) => e.store === "lists")) service.targetLists({ keepPrevious: false });
  db.prepare("DELETE FROM erasures").run();
  return pending.length;
}

/** §20.11's under-13 deletion, beyond what every deletion does: inside
 *  deleteAccount's transaction, with the files to delete after it. */
function erase(db, account, now) {
  const pending = db.prepare("INSERT OR IGNORE INTO erasures (store, hash) VALUES (?, ?)");
  // The replays they played. Two heists can carry the same bytes; the file
  // goes when no heist still keeps it.
  const played = db.prepare(
    "SELECT token, log_hash FROM heists WHERE attacker = ? AND replay_gone = 0").all(account);
  for (const h of played) db.prepare("UPDATE heists SET replay_gone = 1 WHERE token = ?").run(h.token);
  for (const hash of new Set(played.map((h) => h.log_hash))) {
    if (!db.prepare("SELECT 1 FROM heists WHERE log_hash = ? AND replay_gone = 0").get(hash)) {
      pending.run("replays", hash);
    }
  }
  // Their islands' bytes, unless another player's island, Workshop island or
  // challenge link is the same bytes, or another player's island was, raided
  // or leased as theirs: that raid still settles, and its replay still plays.
  const bundles = db.prepare(
    `SELECT bundle FROM snapshots WHERE owner = :a
      UNION SELECT bundle FROM workshop_items WHERE creator = :a`).all({ a: account }).map((r) => r.bundle);
  for (const bundle of bundles) {
    const shared = db.prepare(
      `SELECT 1 FROM islands WHERE bundle = :b AND owner != :a
        UNION ALL SELECT 1 FROM workshop_items WHERE bundle = :b AND creator != :a
        UNION ALL SELECT 1 FROM challenges WHERE bundle = :b AND account != :a
        UNION ALL SELECT 1 FROM leases WHERE bundle = :b AND defender != :a LIMIT 1`)
      .get({ a: account, b: bundle });
    if (!shared) {
      pending.run("bundles", bundle);
      // The edge caches a bundle for a year by its hash (D70).
      queuePurge(db, bundle, now);
    }
  }
  pending.run("lists", "");
  const ratings = db.prepare(
    "DELETE FROM ratings WHERE (kind = 'raider' AND key = ?) OR (kind = 'island' AND substr(key, 1, ?) = ?)")
    .run(account, account.length + 1, `${account}/`).changes;
  // A lease they held and never played reserved nothing (§24.13).
  const leases = db.prepare(
    "DELETE FROM leases WHERE attacker = ? AND token NOT IN (SELECT token FROM heists)").run(account).changes;
  const workshop = ["workshop_plays", "workshop_ratings", "workshop_completions", "workshop_remixes"]
    .reduce((n, table) => n + Number(db.prepare(`DELETE FROM ${table} WHERE player = ?`).run(account).changes), 0);
  // A report they made still stands for a moderator to act on, as nobody's.
  db.prepare("UPDATE workshop_reports SET reporter = NULL WHERE reporter = ?").run(account);
  const bytes = db.prepare("SELECT COUNT(*) AS n FROM erasures WHERE store = 'bundles'").get().n;
  return { replays: played.length, bundles: Number(bytes), ratings: Number(ratings),
           leases: Number(leases), workshop };
}

/** Every journalled deletion of the last REAPPLY_DAYS the database does not
 *  hold — as after a restore from before it — made again, as it was asked
 *  for. Run when the server starts. */
export function reapplyDeletions(service, now = service.now()) {
  finishErasures(service);
  let made = 0;
  for (const e of service.deletions.entries()) {
    if (e.at < now - REAPPLY_DAYS * DAY_MS) continue;
    const row = service.db.prepare("SELECT deleted_at FROM accounts WHERE id = ?").get(e.account);
    if (row && !row.deleted_at) {
      deleteAccount(service, e.account, e.reason, { journal: false, withdraw: e.withdraw === true });
      made++;
    }
  }
  return made;
}
