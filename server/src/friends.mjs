// Friends (§12.11, §17.6).
//
// §12.11: "Friendly heists (at launch): rob a friend's island for fun. The
// friend loses nothing, both see the replay, and the friend earns a page for
// every raider their guards catch." §17.6: the Beacon's friends' feed shows
// "what friends just did … Visible to friends in the game", and challenge
// links "Send your island to a friend as a playable challenge".
//
// How two players become friends is not said (G35): here, one shares an
// invite and the other accepts it, and either can end it. A friendly heist
// and a challenge are leases of their own mode (service.lease), settled
// with nothing taken from the friend and no Renown moved (F48).

import { transaction } from "./db.mjs";
import { Refused } from "./refused.mjs";

const DAY = 24 * 60 * 60 * 1000;
/** How long an invite and a challenge link stay open, and how far back the
 *  feed reaches (G35). */
export const INVITE_DAYS = 7;
export const CHALLENGE_DAYS = 7;
export const FEED_DAYS = 7;

const pair = (a, b) => (a < b ? [a, b] : [b, a]);

export class Friends {
  constructor(service) {
    this.service = service;
  }

  get db() { return this.service.db; }
  now() { return this.service.now(); }

  areFriends(a, b) {
    const [x, y] = pair(a, b);
    return Boolean(this.db.prepare("SELECT 1 FROM friends WHERE a = ? AND b = ?").get(x, y));
  }

  list(account) {
    return this.db.prepare(
      `SELECT CASE WHEN a = ? THEN b ELSE a END AS friend, since FROM friends
        WHERE a = ? OR b = ? ORDER BY since`).all(account, account, account)
      .map((r) => ({ account: r.friend, since: r.since }));
  }

  invite(account) {
    const code = this.service.random(6).toString("hex");
    this.db.prepare("INSERT INTO friend_invites (code, account, created_at) VALUES (?, ?, ?)")
      .run(code, account, this.now());
    return { invite: code, expiresAt: this.now() + INVITE_DAYS * DAY };
  }

  accept(account, code) {
    return transaction(this.db, () => {
      const i = this.db.prepare("SELECT * FROM friend_invites WHERE code = ?").get(code);
      if (!i || i.used_at || this.now() - i.created_at > INVITE_DAYS * DAY) {
        throw new Refused(404, "no_such_invite");
      }
      if (i.account === account) throw new Refused(409, "own_invite");
      if (this.areFriends(account, i.account)) throw new Refused(409, "already_friends");
      const [a, b] = pair(account, i.account);
      this.db.prepare("INSERT INTO friends (a, b, since) VALUES (?, ?, ?)").run(a, b, this.now());
      this.db.prepare("UPDATE friend_invites SET used_at = ? WHERE code = ?").run(this.now(), code);
      return { friend: i.account };
    });
  }

  remove(account, friend) {
    const [a, b] = pair(account, friend);
    const gone = this.db.prepare("DELETE FROM friends WHERE a = ? AND b = ?").run(a, b).changes;
    if (!gone) throw new Refused(404, "not_friends");
    return { removed: friend };
  }

  /**
   * §17.6's feed: what the player's friends did in the last week — their
   * heists, raiding or raided, newest first. Derived from the heists
   * already written, so it costs no write. Names are the device's: it knows
   * its player's friends by their platform names.
   */
  feed(account, limit = 20) {
    const friends = this.list(account).map((f) => f.account);
    if (friends.length === 0) return [];
    const marks = friends.map(() => "?").join(", ");
    return this.db.prepare(
      `SELECT l.attacker, l.defender, l.mode, json_extract(h.outcome, '$.verdict.grade') AS grade, h.submitted_at AS at
         FROM heists h JOIN leases l ON l.token = h.token
        WHERE h.validated = 1 AND h.submitted_at > ?
          AND (l.attacker IN (${marks}) OR l.defender IN (${marks}))
        ORDER BY h.submitted_at DESC LIMIT ?`)
      .all(this.now() - FEED_DAYS * DAY, ...friends, ...friends, Math.min(100, Math.max(1, limit)))
      .map((r) => ({ raider: r.attacker, defender: r.defender, mode: r.mode, grade: r.grade, at: r.at }));
  }

  // -- challenge links (§17.6) -----------------------------------------------

  /** A link to the player's current island in a realm. */
  challenge(account, realm = "heart") {
    const island = this.db.prepare("SELECT bundle FROM islands WHERE owner = ? AND realm = ?").get(account, realm);
    if (!island) throw new Refused(404, "no_island_to_share");
    const code = this.service.random(6).toString("hex");
    this.db.prepare("INSERT INTO challenges (code, account, bundle, created_at) VALUES (?, ?, ?, ?)")
      .run(code, account, island.bundle, this.now());
    return { challenge: code, bundle: island.bundle, expiresAt: this.now() + CHALLENGE_DAYS * DAY };
  }

  /** The link's island, if it is still open. */
  opened(code) {
    const c = this.db.prepare("SELECT * FROM challenges WHERE code = ?").get(code);
    if (!c || this.now() - c.created_at > CHALLENGE_DAYS * DAY) throw new Refused(404, "no_such_challenge");
    return c;
  }
}
