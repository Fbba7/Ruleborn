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
// still names its original.

import { transaction } from "./db.mjs";
import { Refused } from "./refused.mjs";
import { Social } from "./social.mjs";

export const REASONS = ["requested", "under-13"];

/**
 * Delete an account. Idempotent: a deletion interrupted part-way finishes
 * when asked again. Returns what was done.
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
      `UPDATE accounts SET platform_identity = ?, deleted_at = COALESCE(deleted_at, ?),
         deleted_reason = COALESCE(deleted_reason, ?), equipped = '{}' WHERE id = ?`)
      .run(`deleted:${account}`, now, reason, account);
    // Out of matchmaking and the target lists: an island row is what makes a
    // snapshot a target (service.lease).
    const islands = db.prepare("DELETE FROM islands WHERE owner = ?").run(account).changes;
    // A raid already leased on one of them still settles: the raider played
    // it honestly, and what it books is keyed by the opaque id.
    const withdrawn = db.prepare(
      "UPDATE workshop_items SET withdrawn_at = ? WHERE creator = ? AND withdrawn_at IS NULL")
      .run(now, account).changes;
    const events = db.prepare("DELETE FROM events WHERE who = ?").run(who).changes;
    db.prepare("DELETE FROM first_seen WHERE who = ?").run(who);
    return { islands: Number(islands), withdrawn: Number(withdrawn), events: Number(events) };
  });
  // Groups last, each in its own transaction: a founder hands the
  // constellation on as on any leaving (§17.7).
  const social = new Social(service);
  const left = [];
  if (social.membership(account)) left.push(social.leave(account).left);
  if (social.crewOf(account)) left.push(social.leaveCrew(account).left);
  return { deleted: true, reason: row.deleted_reason ?? reason, ...done, left };
}
