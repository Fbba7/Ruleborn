// Friends (§12.11, §17.6).
//
// §12.11: "Friendly heists (at launch): rob a friend's island for fun. The
// friend loses nothing, both see the replay, and the friend earns a page for
// every raider their guards catch." §17.6: the Beacon's friends' feed shows
// "what friends just did … Visible to friends in the game", and challenge
// links "Send your island to a friend as a playable challenge".
//
// How two players become friends is the owner's answer to G35: one shares
// an invite and the other accepts it, and either can end it. A friendly heist
// and a challenge are leases of their own mode (service.lease), settled
// with nothing taken from the friend and no Renown moved (F48).
//
// §17.6's invite gift: "A personal invite gives both players a matching
// cosmetic when the friend plays their first heist." The friendship keeps
// who shared the invite, and the friend's first validated heist gives both
// of them `INVITE_GIFT`, an earned cosmetic like the first hatch's outfit,
// once. A friend who had played a heist before accepting brings no gift.

import { transaction } from "./db.mjs";
import { Refused } from "./refused.mjs";

const DAY = 24 * 60 * 60 * 1000;
/** How long an invite and a challenge link stay open, and how far back the
 *  feed reaches (G35). */
export const INVITE_DAYS = 7;
export const CHALLENGE_DAYS = 7;
export const FEED_DAYS = 7;
/** The most invites, and the most challenge links, a player holds open at
 *  once: each is a row until it closes, and without a ceiling a caller
 *  writes one every half second for a week (SR-19). */
export const MOST_OPEN = 50;

const pair = (a, b) => (a < b ? [a, b] : [b, a]);

/** §17.6's matching cosmetic, earned by an invite and the friend's first
 *  heist; worn like any outfit, and never sold. */
export const INVITE_GIFT = "invite-gift";

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
    const open = this.db.prepare(
      "SELECT COUNT(*) AS n FROM friend_invites WHERE account = ? AND used_at IS NULL AND created_at > ?")
      .get(account, this.now() - INVITE_DAYS * DAY).n;
    if (open >= MOST_OPEN) throw new Refused(409, "too_many_open_invites", { most: MOST_OPEN });
    const code = this.service.random(6).toString("hex");
    this.db.prepare("INSERT INTO friend_invites (code, account, created_at) VALUES (?, ?, ?)")
      .run(code, account, this.now());
    return { invite: code, expiresAt: this.now() + INVITE_DAYS * DAY };
  }

  accept(account, code) {
    return transaction(this.db, () => {
      const i = this.db.prepare("SELECT * FROM friend_invites WHERE code = ?").get(code);
      const from = i && this.db.prepare("SELECT deleted_at, banned_at FROM accounts WHERE id = ?").get(i.account);
      if (!i || i.used_at || this.now() - i.created_at > INVITE_DAYS * DAY || from.deleted_at || from.banned_at) {
        throw new Refused(404, "no_such_invite");
      }
      if (i.account === account) throw new Refused(409, "own_invite");
      if (this.areFriends(account, i.account)) throw new Refused(409, "already_friends");
      // A block either way: the invite is as good as gone (safety.mjs).
      if (this.service.safety.between(account, i.account)) throw new Refused(404, "no_such_invite");
      const [a, b] = pair(account, i.account);
      this.db.prepare("INSERT INTO friends (a, b, since, invited_by) VALUES (?, ?, ?, ?)")
        .run(a, b, this.now(), i.account);
      this.db.prepare("UPDATE friend_invites SET used_at = ? WHERE code = ?").run(this.now(), code);
      return { friend: i.account };
    });
  }

  /** §17.6: at `account`'s first validated heist, each friend whose invite
   *  they accepted and they themselves get the matching cosmetic, once.
   *  Called inside settlement's transaction, before the heist being settled
   *  is marked validated; answers the gift, or null. */
  firstHeist(account, now = this.now()) {
    // Whether there is one, not how many: the first row ends the read.
    const before = this.db.prepare("SELECT 1 FROM heists WHERE attacker = ? AND validated = 1 LIMIT 1").get(account);
    if (before) return null;
    const rows = this.db.prepare(
      `SELECT a, b, invited_by FROM friends
        WHERE (a = ? OR b = ?) AND invited_by IS NOT NULL AND invited_by != ? AND gift_at IS NULL`)
      .all(account, account, account);
    if (!rows.length) return null;
    const seasons = this.service.seasons;
    seasons.grantCosmetic(account, INVITE_GIFT);
    for (const r of rows) {
      seasons.grantCosmetic(r.invited_by, INVITE_GIFT);
      this.db.prepare("UPDATE friends SET gift_at = ? WHERE a = ? AND b = ?").run(now, r.a, r.b);
    }
    return { cosmetic: INVITE_GIFT, friends: rows.length };
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
   *
   * A 13-to-15's heists appear in no feed (G35, decided): not their
   * friends', and not the feed of anyone whose friend raided them or was
   * raided by them, whether or not they are the viewer's friend. The band
   * is read as it is now, so a heist from before a player's age check
   * answered is hidden too once it says 13 to 15.
   */
  feed(account, limit = 20) {
    const friends = this.list(account).map((f) => f.account);
    if (friends.length === 0) return [];
    const marks = friends.map(() => "?").join(", ");
    return this.db.prepare(
      `SELECT l.attacker, l.defender, l.mode, json_extract(h.outcome, '$.verdict.grade') AS grade, h.submitted_at AS at
         FROM heists h JOIN leases l ON l.token = h.token
         JOIN accounts r ON r.id = l.attacker
         JOIN accounts d ON d.id = l.defender
        WHERE h.validated = 1 AND h.submitted_at > ?
          AND (l.attacker IN (${marks}) OR l.defender IN (${marks}))
          AND r.age_band != '13-15' AND d.age_band != '13-15'
          AND NOT EXISTS (SELECT 1 FROM blocks b WHERE (b.blocker = ? AND b.blocked IN (l.attacker, l.defender))
                                                    OR (b.blocked = ? AND b.blocker IN (l.attacker, l.defender)))
        ORDER BY h.submitted_at DESC LIMIT ?`)
      .all(this.now() - FEED_DAYS * DAY, ...friends, ...friends, account, account, Math.min(100, Math.max(1, limit)))
      .map((r) => ({ raider: r.attacker, defender: r.defender, mode: r.mode, grade: r.grade, at: r.at }));
  }

  // -- challenge links (§17.6) -----------------------------------------------

  /** A link to the player's current island in a realm. */
  challenge(account, realm = "heart") {
    const island = this.db.prepare("SELECT bundle FROM islands WHERE owner = ? AND realm = ?").get(account, realm);
    if (!island) throw new Refused(404, "no_island_to_share");
    const open = this.db.prepare("SELECT COUNT(*) AS n FROM challenges WHERE account = ? AND created_at > ?")
      .get(account, this.now() - CHALLENGE_DAYS * DAY).n;
    if (open >= MOST_OPEN) throw new Refused(409, "too_many_open_challenges", { most: MOST_OPEN });
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

  /** Invites used or past INVITE_DAYS, and links past CHALLENGE_DAYS,
   *  deleted: each names a player and is no use once closed (§20.5). A link
   *  already played is still known as played by its lease. Idempotent. */
  expire(now = this.now()) {
    const invites = this.db.prepare("DELETE FROM friend_invites WHERE used_at IS NOT NULL OR created_at < ?")
      .run(now - INVITE_DAYS * DAY).changes;
    const links = this.db.prepare("DELETE FROM challenges WHERE created_at < ?")
      .run(now - CHALLENGE_DAYS * DAY).changes;
    return { invites: Number(invites), challenges: Number(links) };
  }
}
