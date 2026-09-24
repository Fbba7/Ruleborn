// The server's one job, and everything around it (§24.1, §24.8, §24.12, §24.13).
//
// §24.1: "A heist is a seed and an input log of a few kilobytes, the device
// renders the replay itself, and the server only re-simulates to check."
// §24.12 gives the stages, and this file is them:
//
//   Lease     "The server hands out a target snapshot, a seed, a single-use
//             token and an expiry a day away. Nothing is created yet."
//   Play      on the device, offline — not here
//   Queue     on the device — not here
//   Validate  "The server re-simulates, compares, and checks the token, the
//             expiry and the caps."
//   Grant     "Only then is the haul minted, into an append-only ledger."
//
// and §24.13's two edges: one lease per target per player at a time, and the
// entry fee "debited at validation, not at lease … The fee and the reward
// settle in the same transaction".
//
// The server clock is the only clock (§24.12). `now` is injected so the tests
// can move it; nothing here reads the time any other way.

import { randomBytes } from "node:crypto";
import { readFileSync } from "node:fs";

import { transaction } from "./db.mjs";
import { Refused } from "./refused.mjs";
import { capHaul, defenceShare, entryFee, haul } from "./economy.mjs";
import { Friends } from "./friends.mjs";
import { Matchmaking } from "./matchmaking.mjs";
import { Notifications } from "./notifications.mjs";
import { Seasons } from "./seasons.mjs";
import { Shop } from "./shop.mjs";
import { readHeader } from "./sim.mjs";
import { Store } from "./store.mjs";
import { check, issue } from "./tokens.mjs";
import { Telemetry, lawsOf } from "./telemetry.mjs";
import { Track } from "./track.mjs";

const facts = JSON.parse(readFileSync(new URL("./facts.json", import.meta.url), "utf8"));

/** §24.12: "an expiry a day away". */
export const LEASE_MS = 24 * 60 * 60 * 1000;

/** §24.10: "Tick rate — 30 a second, fixed." */
export const TICKS_PER_SECOND = 30;

/**
 * §5.4's clock for a heist that crosses `links` realms. The simulation plays
 * the Heart alone for now — crossing realms is not built — so every lease is
 * `links = 0`: 150 seconds.
 */
export function clockTicks(links = 0) {
  const [base, perLink, cap] = facts.HEIST_CLOCK;
  return Math.min(cap, base + perLink * links) * TICKS_PER_SECOND;
}

// A refusal with an HTTP status: its own module so the services that import
// each other can all throw it, re-exported here where the edge and the tests
// have always found it.
export { Refused };

const day = (ms) => new Date(ms).toISOString().slice(0, 10);
const DAY_MS = 24 * 60 * 60 * 1000;
/** Midnight UTC at the start of `ms`'s day, and of its week (Monday, G20). */
const dayStart = (ms) => ms - (ms % DAY_MS);
const weekStart = (ms) => dayStart(ms) - ((new Date(ms).getUTCDay() + 6) % 7) * DAY_MS;

export class Service {
  /**
   * `verifyPlatform(credential)` returns the platform identity a credential
   * proves, or null. It is the seam to Game Center and Play Games, which need
   * the stores' own services (see tokens.mjs).
   */
  /**
   * `replays` is the private store the submitted replays are kept in (§24.3)
   * — apart from `store`, whose objects anyone may fetch by hash.
   */
  /**
   * `preparePlatform(credential)` is the asynchronous half of sign-in — Game
   * Center's certificate fetched and cached (stores.mjs) — run by the edge
   * before the synchronous `session`.
   */
  /**
   * `seasonStart` is when season 1 began (§18.1): seasons run back to back,
   * eight weeks each, from it. `verifyReceipt(store, receipt)` is the same
   * seam to the stores for purchases (shop.mjs); without one, every receipt
   * is refused.
   */
  constructor({ db, store, builds, secret, verifyPlatform, now = () => Date.now(),
                random = randomBytes, seasonStart = 0, verifyReceipt = () => null,
                cosmetics = undefined, preparePlatform = async () => {}, replays = new Store() }) {
    Object.assign(this, { db, store, builds, secret, verifyPlatform, now, random, verifyReceipt,
                          preparePlatform, replays });
    this.seasons = new Seasons(this, seasonStart);
    this.track = new Track(this);
    this.telemetry = new Telemetry(this);
    this.matchmaking = new Matchmaking(this);
    this.notifications = new Notifications(this);
    this.friends = new Friends(this);
    this.shop = new Shop(this, { verifyReceipt: (s, r) => this.verifyReceipt(s, r), catalogue: cosmetics });
  }

  // -- identity ------------------------------------------------------------

  session(credential) {
    const identity = this.verifyPlatform(credential);
    if (!identity) throw new Refused(401, "platform_identity_refused");
    const now = this.now();
    let row = this.db.prepare("SELECT id, banned_at FROM accounts WHERE platform_identity = ?")
      .get(identity);
    // §20.4: "Repeat offenders are muted, then banned." The identity is kept
    // so the ban holds (§20.12).
    if (row?.banned_at) throw new Refused(403, "banned");
    if (!row) {
      const id = this.random(12).toString("hex");
      this.db.prepare("INSERT INTO accounts (id, platform_identity, created_at) VALUES (?, ?, ?)")
        .run(id, identity, now);
      row = { id };
    }
    // §24's analytics: a sign-in is a session.
    this.telemetry.record(row.id, "session", {}, now);
    return { account: row.id, token: issue(this.secret, row.id, now) };
  }

  account(token) {
    const id = check(this.secret, token, this.now());
    if (!id) throw new Refused(401, "session_refused");
    // A token outlives nothing it was issued to: a deleted account's is
    // refused at once (§20.5).
    if (this.db.prepare("SELECT deleted_at FROM accounts WHERE id = ?").get(id)?.deleted_at) {
      throw new Refused(401, "account_deleted");
    }
    return id;
  }

  // -- publishing ----------------------------------------------------------

  /**
   * §24.8: "Publishing writes an immutable bundle to storage under its own
   * hash." Checked by the simulation first: an island §5.2 or §6.1 forbids is
   * refused, with every rule it breaks named.
   */
  publish(owner, bundle, realm = "heart") {
    const build = this.builds.current;
    const read = build.island(bundle);
    if (read.error) throw new Refused(400, read.error);
    if (read.problems.length) throw new Refused(422, "island_not_publishable", { problems: read.problems });
    const key = this.store.put(bundle, read.digest);      // the two SHA-256s must agree
    const now = this.now();
    const view = new DataView(bundle.buffer, bundle.byteOffset, bundle.byteLength);
    transaction(this.db, () => {
      this.db.prepare(
        `INSERT OR IGNORE INTO snapshots
           (bundle, owner, realm, realm_level, vault_level, exposed, rules, published_at)
         VALUES (?, ?, ?, ?, ?, ?, ?, ?)`)
        .run(key, owner, realm, bundle[4], bundle[5], view.getUint32(6, true),
             build.rulesVersion, now);
      this.db.prepare(
        `INSERT INTO islands (owner, realm, bundle, changed_at) VALUES (?, ?, ?, ?)
         ON CONFLICT (owner, realm) DO UPDATE SET bundle = excluded.bundle,
           changed_at = excluded.changed_at`)
        .run(owner, realm, key, now);
      // §12.22: a new island enters with the simulator's prior.
      this.matchmaking.published(owner, realm, bundle[4], now);
    });
    return { bundle: key };
  }

  bundle(key) {
    return this.store.get(key);
  }

  // -- target lists -----------------------------------------------------------

  /**
   * §24.8: "Candidate lists per difficulty band are generated periodically as
   * static objects, so choosing a target costs a cached download rather than
   * a database search."
   *
   * One list a band, holding every island's current snapshot — a republished
   * island's old one is no longer a target — in one canonical encoding, so an
   * unchanged band regenerates to the same file and the edge keeps its cache.
   * Until §12.22's ratings exist, a band is a realm level: §12.22 draws "the
   * middle of the list … from the raider-success band for the target's realm
   * level". The raider's own filters (Keeper level within 3, Renown within
   * 150, not their own island) run on the device against the list.
   */
  targetLists() {
    const now = this.now();
    // The owner is the island's, not the snapshot's: two players who publish
    // the same bytes share a snapshot, and each is a target of their own.
    const rows = this.db.prepare(
      `SELECT s.bundle, i.owner, i.realm, s.realm_level, s.vault_level, s.exposed,
              COALESCE(s.band, 'realm-level-' || s.realm_level) AS band, a.keeper_level
         FROM islands i
         JOIN snapshots s ON s.bundle = i.bundle
         JOIN accounts a ON a.id = i.owner
        WHERE a.banned_at IS NULL
        ORDER BY s.bundle, i.owner`).all();
    const bands = new Map();
    for (const r of rows) {
      // §12.3: a new player's island is nobody's target yet.
      if (this.matchmaking.shielded(r.owner, now)) continue;
      if (!bands.has(r.band)) bands.set(r.band, []);
      // What §12.22's steps read, so the device can run `offer` on the list.
      const rating = this.matchmaking.islandRating(r.owner, r.realm);
      bands.get(r.band).push({
        bundle: r.bundle, owner: r.owner, realm: r.realm, realmLevel: r.realm_level,
        vaultLevel: r.vault_level, exposed: r.exposed, keeperLevel: r.keeper_level,
        renown: this.seasons.league(r.owner, now).renown, origin: "authored",
        rating: rating ? Math.round(rating.rating) : null,
        deviation: rating ? Math.round(rating.deviation) : null,
      });
    }
    const index = {};
    transaction(this.db, () => {
      for (const [band, candidates] of [...bands].sort(([a], [b]) => (a < b ? -1 : 1))) {
        const bytes = new TextEncoder().encode(JSON.stringify({ band, candidates }));
        const list = this.store.put(bytes);
        this.db.prepare(
          `INSERT INTO target_lists (band, list, candidates, generated_at) VALUES (?, ?, ?, ?)
           ON CONFLICT (band) DO UPDATE SET list = excluded.list,
             candidates = excluded.candidates, generated_at = excluded.generated_at`)
          .run(band, list, candidates.length, now);
        index[band] = list;
      }
      // A band every island has left keeps no list: its last one would name
      // only superseded snapshots.
      const current = Object.keys(index);
      this.db.prepare(
        `DELETE FROM target_lists WHERE band NOT IN (${current.map(() => "?").join(", ") || "''"})`)
        .run(...current);
    });
    return index;
  }

  /** The current list for each band: a small index, then one cached file each. */
  targets() {
    const out = {};
    for (const r of this.db.prepare("SELECT band, list FROM target_lists ORDER BY band").all()) {
      out[r.band] = r.list;
    }
    return out;
  }

  // -- the lease -----------------------------------------------------------

  /**
   * §24.12's lease, and §24.13: "A second device asking for the same target
   * is handed the lease the first already holds, not a new one." §12.3's
   * protections hold here: a new player's island is refused, a past
   * snapshot is leased as an echo, and `trace` answers a robbery. `mode`
   * is §12.11's friendly heist on a friend's island, or a play of §17.6's
   * challenge link named by `challenge`.
   */
  lease(attacker, bundle, owner = null, { trace = false, mode = "raid", challenge = null } = {}) {
    const now = this.now();
    if (!["raid", "friendly", "challenge"].includes(mode)) throw new Refused(400, "no_such_mode");
    if (mode === "challenge") return this.challengeLease(attacker, bundle, challenge, now);
    const snapshot = this.db.prepare("SELECT owner, published_at FROM snapshots WHERE bundle = ?").get(bundle);
    if (!snapshot) throw new Refused(404, "no_such_snapshot");
    // Whose island this is: the one named, if they hold it, else the first
    // player (by account) whose current island it is.
    // A banned player's islands have left matchmaking (§20.12).
    const holders = this.db.prepare(
      `SELECT i.owner FROM islands i JOIN accounts a ON a.id = i.owner
        WHERE i.bundle = ? AND a.banned_at IS NULL ORDER BY i.owner`).all(bundle).map((r) => r.owner);
    if (holders.includes(attacker)) throw new Refused(409, "own_island");
    let defender;
    let echo = false;
    if (holders.length === 0) {
      // A snapshot no island is on any more is an echo for 14 days (§12.3:
      // "Robbing an echo takes nothing from its owner"), and after that not
      // a target at all.
      const by = this.db.prepare("SELECT banned_at, deleted_at FROM accounts WHERE id = ?").get(snapshot.owner);
      const days = facts.ECHO_DAYS * 24 * 60 * 60 * 1000;
      if (trace || snapshot.owner === attacker || by.banned_at || by.deleted_at
          || now - snapshot.published_at > days) {
        throw new Refused(410, "superseded");
      }
      defender = snapshot.owner;
      echo = true;
    } else {
      defender = owner && holders.includes(owner) ? owner : holders[0];
    }
    let traceOf = null;
    if (mode === "friendly") {
      // A friend's island, and only a current one: an echo is nobody's.
      if (echo || trace) throw new Refused(410, "superseded");
      if (!this.friends.areFriends(attacker, defender)) throw new Refused(403, "not_friends");
    } else if (trace) {
      traceOf = this.matchmaking.traceable(attacker, defender, now);
      if (!traceOf) throw new Refused(403, "nothing_to_trace");
    } else if (this.matchmaking.shielded(defender, now)) {
      throw new Refused(403, "new_player_protected", { hours: facts.NEW_PLAYER_SHIELD_HOURS });
    }
    return this.issue(attacker, bundle, defender, now, { echo, traceOf, mode });
  }

  /** §17.6's challenge link: anyone holding it may play its island once,
   *  even after its owner has moved on. */
  challengeLease(attacker, bundle, code, now) {
    const c = this.friends.opened(code);
    if (c.bundle !== bundle) throw new Refused(409, "not_this_challenge");
    if (c.account === attacker) throw new Refused(409, "own_island");
    const played = this.db.prepare(
      "SELECT 1 FROM leases l JOIN heists h ON h.token = l.token WHERE l.attacker = ? AND l.challenge = ?")
      .get(attacker, code);
    if (played) throw new Refused(409, "challenge_already_played");
    return this.issue(attacker, bundle, c.account, now, { mode: "challenge", challenge: code });
  }

  /** The lease itself, or the one this attacker already holds on the bundle. */
  issue(attacker, bundle, defender, now, { echo = false, traceOf = null, mode = "raid", challenge = null }) {
    return transaction(this.db, () => {
      const held = this.db.prepare(
        "SELECT * FROM leases WHERE attacker = ? AND bundle = ? AND state = 'open'")
        .get(attacker, bundle);
      if (held && held.expires_at > now) return this.leaseView(held);
      if (held) {
        // Expired and never submitted: it reserved nothing (§24.13), so it
        // simply closes and a fresh one is issued.
        this.db.prepare("UPDATE leases SET state = 'settled' WHERE token = ?").run(held.token);
      }
      const row = {
        token: this.random(16).toString("hex"),
        attacker, bundle, defender,
        seed: this.random(8).readBigUInt64LE(0).toString(),
        ticks: clockTicks(0),
        rules: this.builds.current.rulesVersion,
        issued_at: now,
        expires_at: now + LEASE_MS,
        echo: echo ? 1 : 0,
        trace_of: traceOf,
        mode,
        challenge,
      };
      this.db.prepare(
        `INSERT INTO leases (token, attacker, bundle, defender, seed, ticks, rules, issued_at, expires_at,
                             echo, trace_of, mode, challenge)
         VALUES (:token, :attacker, :bundle, :defender, :seed, :ticks, :rules, :issued_at, :expires_at,
                 :echo, :trace_of, :mode, :challenge)`)
        .run(row);
      return this.leaseView(row);
    });
  }

  /** The lease, and what the defender wears, so the raider sees their
   *  island as they dressed it. */
  leaseView(row) {
    return { token: row.token, bundle: row.bundle, seed: row.seed, ticks: row.ticks,
             rules: row.rules, expiresAt: row.expires_at, look: this.shop.equipped(row.defender),
             echo: Boolean(row.echo), trace: Boolean(row.trace_of), mode: row.mode ?? "raid" };
  }

  // -- validate and grant ----------------------------------------------------

  /**
   * §24.12's Validate and Grant, for one submission. Idempotent: the token is
   * single-use and keys the result, so a retry after a dropped connection is
   * answered with what was decided the first time and pays nothing twice.
   */
  submit(attacker, token, replay) {
    const now = this.now();
    const lease = this.db.prepare("SELECT * FROM leases WHERE token = ?").get(token);
    // §24.8: "each carries a server-issued nonce bound to attacker and target".
    if (!lease || lease.attacker !== attacker) throw new Refused(403, "lease_refused");

    const done = this.db.prepare("SELECT outcome FROM heists WHERE token = ?").get(token);
    if (done) return { ...JSON.parse(done.outcome), repeated: true };

    // §24.3: kept for validation and analysis, and for the two players to
    // watch (§13), in the private store.
    const logHash = this.replays.put(replay);
    const header = readHeader(replay);
    const refuse = (reason, extra = {}) => this.settle(lease, replay, logHash, now,
                                                       { validated: false, reason, ...extra });

    // The replay must be the heist this lease allowed: its snapshot, its
    // seed, its clock.
    if (!header) return refuse("replay_malformed");
    if (header.island !== lease.bundle) return refuse("wrong_island");
    if (header.seed.toString() !== lease.seed) return refuse("wrong_seed");
    if (header.ticks !== lease.ticks) return refuse("wrong_clock");

    // §24.12: "The lease expired — No reward, with one grace submission
    // allowed." Read as one expired submission a day honoured (G17).
    let grace = false;
    if (now > lease.expires_at) {
      const used = this.db.prepare(
        "SELECT COUNT(*) AS n FROM heists WHERE attacker = ? AND day = ? AND grace = 1")
        .get(attacker, day(now)).n;
      if (used > 0) return refuse("lease_expired");
      grace = true;
    }

    // §24.11: re-simulated by the build it was played under, however old.
    const build = this.builds.get(header.rules);
    if (!build) return refuse("rules_not_held");
    const island = this.store.get(lease.bundle);
    const result = build.verify(replay, island);
    if (result.status === "refused") return refuse(result.reason);
    if (result.status === "diverged") {
      // "No reward for that heist, nothing taken away from before, and a note
      // for review. One mismatch is never a ban."
      return refuse("diverged", { second: result.second, review: true });
    }
    return this.settle(lease, replay, logHash, now,
                       { validated: true, verdict: result.verdict, grace });
  }

  /**
   * The heist row, and for a validated heist the ledger, in one transaction:
   * §24.13 "The fee and the reward settle in the same transaction, which is
   * also the only way the ledger can stay a single append-only record."
   */
  settle(lease, replay, logHash, now, decision) {
    return transaction(this.db, () => {
      const outcome = { validated: decision.validated };
      if (!decision.validated) {
        Object.assign(outcome, { reason: decision.reason },
                      decision.second ? { second: decision.second } : {});
      } else {
        Object.assign(outcome, this.grant(lease, decision.verdict, now), { grace: decision.grace });
      }
      const n = replay.length;
      const stateHash = decision.validated
        ? Buffer.from(replay.subarray(n - 4, n)).toString("hex") : null;
      this.db.prepare(
        `INSERT INTO heists (token, attacker, bundle, seed, log_hash, state_hash, validated,
                             outcome, review, grace, submitted_at, day)
         VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)`)
        .run(lease.token, lease.attacker, lease.bundle, lease.seed, logHash, stateHash,
             decision.validated ? 1 : 0, JSON.stringify(outcome), decision.review ? 1 : 0,
             decision.grace ? 1 : 0, now, day(now));
      this.db.prepare("UPDATE leases SET state = 'settled' WHERE token = ?").run(lease.token);
      // §24's analytics: a heist's "outcome, laws crossed, crew".
      this.telemetry.record(lease.attacker, "heist", decision.validated
        ? { validated: true, grade: decision.verdict.grade, crew: decision.verdict.crew,
            laws: lawsOf(this.store.get(lease.bundle)) }
        : { validated: false, reason: decision.reason }, now);
      return outcome;
    });
  }

  /** The fee, the haul and the defender's share, minted. */
  grant(lease, verdict, now) {
    const attacker = lease.attacker;
    const snapshot = this.db.prepare("SELECT * FROM snapshots WHERE bundle = ?").get(lease.bundle);
    const level = (id) => this.db.prepare("SELECT keeper_level FROM accounts WHERE id = ?").get(id).keeper_level;
    const raidsEarlierToday = this.db.prepare(
      "SELECT COUNT(*) AS n FROM heists WHERE attacker = ? AND day = ? AND validated = 1")
      .get(attacker, day(now)).n;
    const mint = this.db.prepare(
      "INSERT INTO ledger (account, currency, amount, reason, heist, at) VALUES (?, ?, ?, ?, ?, ?)");
    const book = (account, currency, amount, reason) => {
      if (amount !== 0) mint.run(account, currency, amount, reason, lease.token, now);
    };

    // §12.3's Trace comes "with a free scout and no entry fee"; a friendly
    // heist or a challenge is for fun, and costs none either (F48).
    const friendly = lease.mode === "friendly" || lease.mode === "challenge";
    const fee = lease.trace_of || friendly ? 0 : entryFee(this.balance(attacker).starlight);
    book(attacker, "starlight", -fee, "entry fee (9.4)");
    // §24.12's Validate "checks the token, the expiry and the caps": §9.6's
    // three, against what this raider was paid today and this week.
    const paidSince = (from) => Number(this.db.prepare(
      `SELECT COALESCE(SUM(amount), 0) AS n FROM ledger
        WHERE account = ? AND reason = 'haul (9.6)' AND at >= ?`).get(attacker, from).n);
    const pay = capHaul(haul({
      vaultLevel: snapshot.vault_level,
      gradeName: verdict.grade,
      raiderLevel: level(attacker),
      targetLevel: level(lease.defender),
      exposed: snapshot.exposed,
      raidsEarlierToday,
      banked: verdict.banked,
      capacity: verdict.capacity,
    }), {
      targetVaultLevel: snapshot.vault_level,
      raiderVaultLevel: this.vaultLevel(attacker),
      paidToday: paidSince(dayStart(now)),
      paidThisWeek: paidSince(weekStart(now)),
    });
    book(attacker, "starlight", pay.starlight, "haul (9.6)");
    book(attacker, "essence", pay.essence, "haul (9.6)");
    if (verdict.grade === "clean") {
      book(attacker, "starlight", fee, "entry fee returned after a clean heist (9.4)");
    }
    // §9.4: "a foiled heist gives the defender the entry fee plus 5% of what
    // the crew was carrying", the share §13.1's rule has set this season.
    let defence = null;
    if (verdict.grade === "foiled" && !lease.echo && !friendly) {
      book(lease.defender, "starlight", fee, "a foiled raider's entry fee (12.9)");
      const percent = this.seasons.defenceShare(this.seasons.current(now).id);
      const share = defenceShare({
        vaultLevel: snapshot.vault_level, raiderLevel: level(attacker), targetLevel: level(lease.defender),
        exposed: snapshot.exposed, left: verdict.left ?? 0, capacity: verdict.capacity, percent,
      });
      book(lease.defender, "starlight", share.starlight, `${percent}% of what a foiled crew carried (9.4)`);
      book(lease.defender, "essence", share.essence, `${percent}% of what a foiled crew carried (9.4)`);
      defence = { percent, ...share };
    }
    // §12.9's Renown, §18.2's season stars and §12.22's ratings, in the same
    // transaction as the haul. An echo is nobody's defence: it moves no
    // Renown, earns its owner nothing and rates no island (G30).
    const season = this.seasons.current(now).id;
    // §12.11: "The friend loses nothing", and a game among friends moves no
    // Renown, stars or ratings (F48).
    const none = { raider: 0, defender: 0 };
    const renown = lease.echo || friendly ? none : this.seasons.settle(lease, verdict, now);
    // §13: "The defender is notified afterwards and can watch the replay."
    if (!lease.echo) this.notifications.raided(lease, verdict, now);
    const stars = friendly ? none : this.track.settle(lease, verdict, season, now, { echo: Boolean(lease.echo) });
    const rating = lease.echo || friendly ? null : this.matchmaking.settle(lease, snapshot.realm, verdict, now);
    // "the friend earns a page for every raider their guards catch": pages
    // are the device's, so the outcome is their record (D64).
    const friendPages = friendly ? verdict.caught : undefined;
    return { verdict, fee, haul: pay, renown, stars, rating, defence, mode: lease.mode ?? "raid",
             ...(friendly ? { friendPages } : {}) };
  }

  /**
   * §13: the defender "can watch the replay", and so can the raider: the
   * replay's bytes, to either of them, while §24.3 keeps them.
   */
  replay(account, token) {
    const h = this.db.prepare(
      `SELECT h.log_hash, h.replay_gone, l.attacker, l.defender FROM heists h JOIN leases l ON l.token = h.token
        WHERE h.token = ?`).get(token);
    if (!h || (h.attacker !== account && h.defender !== account)) throw new Refused(404, "no_such_heist");
    const bytes = h.replay_gone ? null : this.replays.get(h.log_hash);
    if (!bytes) throw new Refused(410, "replay_no_longer_kept", { days: facts.RAW_KEEP_DAYS[1] });
    return bytes;
  }

  /** §24.3: "Raw replays and logs are kept 30 to 90 days". Past the
   *  longest, a replay goes; its heist row and hashes stay. Idempotent. */
  expireReplays(now = this.now()) {
    const before = now - facts.RAW_KEEP_DAYS[1] * DAY_MS;
    return transaction(this.db, () => {
      const old = this.db.prepare(
        "SELECT token, log_hash FROM heists WHERE replay_gone = 0 AND submitted_at < ?").all(before);
      for (const h of old) {
        // Two heists can carry the same bytes; the replay stays while any is kept.
        const kept = this.db.prepare(
          "SELECT 1 FROM heists WHERE log_hash = ? AND replay_gone = 0 AND submitted_at >= ?").get(h.log_hash, before);
        if (!kept) this.replays.delete(h.log_hash);
        this.db.prepare("UPDATE heists SET replay_gone = 1 WHERE token = ?").run(h.token);
      }
      return old.length;
    });
  }

  /** The raider's own Vault level, from their Heart's current snapshot; a
   *  player with no island published stands at level 1. */
  vaultLevel(account) {
    const row = this.db.prepare(
      `SELECT s.vault_level FROM islands i JOIN snapshots s ON s.bundle = i.bundle
        WHERE i.owner = ? AND i.realm = 'heart'`).get(account);
    return row ? row.vault_level : 1;
  }

  // -- balances --------------------------------------------------------------

  /** §24.12: currency is "a ledger of minting events", summed. */
  balance(account) {
    const rows = this.db.prepare(
      "SELECT currency, SUM(amount) AS total FROM ledger WHERE account = ? GROUP BY currency")
      .all(account);
    const out = { starlight: 0, essence: 0, starglass: 0 };
    for (const r of rows) out[r.currency] = Number(r.total);
    return out;
  }

  /** One ledger row outside a heist: a track tier, a purchase, a price. */
  book(account, currency, amount, reason, now = this.now()) {
    if (amount === 0) return;
    this.db.prepare(
      "INSERT INTO ledger (account, currency, amount, reason, heist, at) VALUES (?, ?, ?, ?, NULL, ?)")
      .run(account, currency, amount, reason, now);
  }

  /** Spend Starglass, never below none. Called inside the caller's
   *  transaction, so the check and the debit are one. */
  spendStarglass(account, amount, reason, now = this.now()) {
    const have = this.balance(account).starglass;
    if (have < amount) throw new Refused(409, "not_enough_starglass", { have, cost: amount });
    this.book(account, "starglass", -amount, reason, now);
  }
}
