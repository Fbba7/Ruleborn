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
import { entryFee, haul } from "./economy.mjs";
import { readHeader } from "./sim.mjs";
import { sha256 } from "./store.mjs";
import { check, issue } from "./tokens.mjs";

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

/** A refusal with an HTTP status, so the edge layer need not guess one. */
export class Refused extends Error {
  constructor(status, reason, detail = {}) {
    super(reason);
    this.status = status;
    this.reason = reason;
    this.detail = detail;
  }
}

const day = (ms) => new Date(ms).toISOString().slice(0, 10);

export class Service {
  /**
   * `verifyPlatform(credential)` returns the platform identity a credential
   * proves, or null. It is the seam to Game Center and Play Games, which need
   * the stores' own services (see tokens.mjs).
   */
  constructor({ db, store, builds, secret, verifyPlatform, now = () => Date.now(),
                random = randomBytes }) {
    Object.assign(this, { db, store, builds, secret, verifyPlatform, now, random });
  }

  // -- identity ------------------------------------------------------------

  session(credential) {
    const identity = this.verifyPlatform(credential);
    if (!identity) throw new Refused(401, "platform_identity_refused");
    const now = this.now();
    let row = this.db.prepare("SELECT id FROM accounts WHERE platform_identity = ?").get(identity);
    if (!row) {
      const id = this.random(12).toString("hex");
      this.db.prepare("INSERT INTO accounts (id, platform_identity, created_at) VALUES (?, ?, ?)")
        .run(id, identity, now);
      row = { id };
    }
    return { account: row.id, token: issue(this.secret, row.id, now) };
  }

  account(token) {
    const id = check(this.secret, token, this.now());
    if (!id) throw new Refused(401, "session_refused");
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
    });
    return { bundle: key };
  }

  bundle(key) {
    return this.store.get(key);
  }

  // -- the lease -----------------------------------------------------------

  /**
   * §24.12's lease, and §24.13: "A second device asking for the same target
   * is handed the lease the first already holds, not a new one."
   */
  lease(attacker, bundle) {
    const now = this.now();
    const snapshot = this.db.prepare("SELECT owner FROM snapshots WHERE bundle = ?").get(bundle);
    if (!snapshot) throw new Refused(404, "no_such_snapshot");
    if (snapshot.owner === attacker) throw new Refused(409, "own_island");
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
        attacker, bundle,
        seed: this.random(8).readBigUInt64LE(0).toString(),
        ticks: clockTicks(0),
        rules: this.builds.current.rulesVersion,
        issued_at: now,
        expires_at: now + LEASE_MS,
      };
      this.db.prepare(
        `INSERT INTO leases (token, attacker, bundle, seed, ticks, rules, issued_at, expires_at)
         VALUES (:token, :attacker, :bundle, :seed, :ticks, :rules, :issued_at, :expires_at)`)
        .run(row);
      return this.leaseView(row);
    });
  }

  leaseView(row) {
    return { token: row.token, bundle: row.bundle, seed: row.seed, ticks: row.ticks,
             rules: row.rules, expiresAt: row.expires_at };
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

    const logHash = sha256(replay);
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

    const fee = entryFee(this.balance(attacker).starlight);
    book(attacker, "starlight", -fee, "entry fee (9.4)");
    const pay = haul({
      vaultLevel: snapshot.vault_level,
      gradeName: verdict.grade,
      raiderLevel: level(attacker),
      targetLevel: level(snapshot.owner),
      exposed: snapshot.exposed,
      raidsEarlierToday,
      banked: verdict.banked,
      capacity: verdict.capacity,
    });
    book(attacker, "starlight", pay.starlight, "haul (9.6)");
    book(attacker, "essence", pay.essence, "haul (9.6)");
    if (verdict.grade === "clean") {
      book(attacker, "starlight", fee, "entry fee returned after a clean heist (9.4)");
    } else if (verdict.grade === "foiled") {
      // §12.9: "A foiled heist gives the defender the raider's entry fee".
      book(snapshot.owner, "starlight", fee, "a foiled raider's entry fee (12.9)");
    }
    return { verdict, fee, haul: pay };
  }

  // -- balances --------------------------------------------------------------

  /** §24.12: currency is "a ledger of minting events", summed. */
  balance(account) {
    const rows = this.db.prepare(
      "SELECT currency, SUM(amount) AS total FROM ledger WHERE account = ? GROUP BY currency")
      .all(account);
    const out = { starlight: 0, essence: 0 };
    for (const r of rows) out[r.currency] = Number(r.total);
    return out;
  }
}
