// What the stores require of a game where players make things other players
// see (§20.11): a way to block another player, a terms-of-use gate before
// player-made content, and published terms, privacy policy and contact.
//
// §20.11: Apple's user-content rules ask for "a way to block another player"
// and "published contact details"; Google's for "in-app reporting and
// blocking, a terms-of-use gate". Reporting and moderation are the
// Workshop's (workshop.mjs); this is the rest.
//
// A block does what §17.8 says: "Blocking hides a person; it does not
// remove their island from the world. They disappear from chat, invitations
// and anything with their name on it, and you disappear from theirs." So a
// block either way hides each from the other in the Workshop's lists and the
// friends' feed, ends a friendship between them, and closes invites and
// challenge links between them. Their islands stay each other's targets: "a
// raid takes nothing … Letting blocking remove targets would create a way to
// shrink the pool, dodge strong defenders, and coordinate who faces whom."
//
// The terms are server/web/terms.md; its first line names the version. A
// player accepts a version, and every Workshop route that publishes, plays,
// rates or remixes asks for the current one first. Reporting never waits for
// it: a way to report is what the rules exist for.

import { readFileSync } from "node:fs";

import { transaction } from "./db.mjs";
import { Refused } from "./refused.mjs";

export const TERMS = readFileSync(new URL("../web/terms.md", import.meta.url), "utf8");

/** The terms' version, from their first line: "Version: …". */
export const TERMS_VERSION = /^Version: (\S+)/m.exec(TERMS)?.[1] ?? null;
if (!TERMS_VERSION) throw new Error("server/web/terms.md names no version on a 'Version:' line");

/** A player may block at most this many: a list, not a store of everyone. */
export const MOST_BLOCKS = 500;

export class Safety {
  constructor(service) {
    this.service = service;
  }

  get db() { return this.service.db; }

  // -- blocks ------------------------------------------------------------------

  block(blocker, blocked) {
    if (typeof blocked !== "string" || !blocked) throw new Refused(400, "malformed_body");
    if (blocked === blocker) throw new Refused(409, "own_account");
    const other = this.db.prepare("SELECT deleted_at FROM accounts WHERE id = ?").get(blocked);
    if (!other || other.deleted_at) throw new Refused(404, "no_such_account");
    return transaction(this.db, () => {
      const n = this.db.prepare("SELECT COUNT(*) AS n FROM blocks WHERE blocker = ?").get(blocker).n;
      const had = this.db.prepare("SELECT 1 FROM blocks WHERE blocker = ? AND blocked = ?").get(blocker, blocked);
      if (!had && n >= MOST_BLOCKS) throw new Refused(409, "too_many_blocks");
      this.db.prepare("INSERT OR IGNORE INTO blocks (blocker, blocked, at) VALUES (?, ?, ?)")
        .run(blocker, blocked, this.service.now());
      // A friendship between them ends, and the invites either sent go.
      const [a, b] = blocker < blocked ? [blocker, blocked] : [blocked, blocker];
      const unfriended = this.db.prepare("DELETE FROM friends WHERE a = ? AND b = ?").run(a, b).changes > 0;
      return { blocked, unfriended };
    });
  }

  unblock(blocker, blocked) {
    const gone = this.db.prepare("DELETE FROM blocks WHERE blocker = ? AND blocked = ?").run(blocker, blocked).changes;
    if (!gone) throw new Refused(404, "not_blocked");
    return { unblocked: blocked };
  }

  list(blocker) {
    return this.db.prepare("SELECT blocked, at FROM blocks WHERE blocker = ? ORDER BY at, blocked").all(blocker)
      .map((r) => ({ account: r.blocked, at: r.at }));
  }

  /** Whether either of the two has blocked the other. */
  between(a, b) {
    return Boolean(this.db.prepare(
      "SELECT 1 FROM blocks WHERE (blocker = ? AND blocked = ?) OR (blocker = ? AND blocked = ?)").get(a, b, b, a));
  }

  // -- the terms ---------------------------------------------------------------

  terms(account) {
    const row = this.db.prepare("SELECT terms_version FROM accounts WHERE id = ?").get(account);
    return { version: TERMS_VERSION, accepted: row?.terms_version === TERMS_VERSION, url: "/terms" };
  }

  /** The current version accepted; any other is refused, so a device showing
   *  old terms cannot accept new ones unseen. */
  accept(account, version) {
    if (version !== TERMS_VERSION) throw new Refused(409, "not_the_current_terms", { version: TERMS_VERSION });
    this.db.prepare("UPDATE accounts SET terms_version = ? WHERE id = ?").run(version, account);
    return this.terms(account);
  }

  /** Refused until the player has accepted the current terms (§20.11). */
  requireTerms(account) {
    if (!this.terms(account).accepted) throw new Refused(403, "terms_first", { version: TERMS_VERSION });
  }
}
