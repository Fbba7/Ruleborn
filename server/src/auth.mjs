// Sessions: how a signed-in device stays signed in, and how it stops
// (docs/security/auth.md).
//
// §24.8 exchanges a platform identity for "a short-lived signed token" and
// says nothing of signing out, refreshing or revoking; the market's answer,
// taken here:
//
//   - a sign-in makes a session, a row, with an id the server gives and a
//     salt it draws, never one the device names (no fixation);
//   - the device holds an access token for an hour and a refresh token;
//     every request's access token is checked against its session's row,
//     read together with the account's (the read the server already made
//     for deletion and bans), so signing out ends it at once;
//   - a refresh token is rotated on every use, and one used a second time —
//     two holders of it, one a thief — ends the whole session (the family);
//   - a session lapses 30 days after its last use and 180 after it was made,
//     and ends with the account's deletion, a ban, a change of platform
//     identity, or "sign out everywhere";
//   - every refusal of a token is the same `session_refused`, so a caller
//     learns nothing of why: forged, stale, revoked or reused;
//   - a player sees each signed-in device — its kind and model as the
//     device names them, the country the edge last saw it in, when it was
//     last used — and can end any one, every other, or all;
//   - an account may also sign in with one identity of the other platform
//     (one account across iPhone, iPad and Android), linked only with a
//     fresh proof of both: the one it has and the one it adds.
//
// A session ended or lapsed names a player and serves no purpose: it is
// deleted seven days after (§20.5), by `expire`, which main.mjs runs daily.

import { createHash, randomBytes } from "node:crypto";

import { transaction } from "./db.mjs";
import { banIdentity } from "./accounts.mjs";
import { Refused } from "./refused.mjs";
import { SESSION_MS, issueAccess, issueNonce, issueRefresh, peekRefresh, readAccess, readNonce,
         refreshSigned } from "./tokens.mjs";

const DAY_MS = 24 * 60 * 60 * 1000;
/** A session unused this long lapses: a month away from the game. */
export const IDLE_MS = 30 * DAY_MS;
/** And this long after it was made, whatever: the platform proves it again. */
export const ABSOLUTE_MS = 180 * DAY_MS;
/** §20.5: closed, then deleted within seven days. */
export const ENDED_KEEP_MS = 7 * DAY_MS;

/** Why a session ended. `device`: from another device's list; `others`:
 *  "sign out every other device". */
export const ENDINGS = Object.freeze(["signed_out", "everywhere", "reused", "deleted", "banned", "identity",
                                      "device", "others"]);

/** The kinds of device the list words; anything else is "other". */
export const DEVICES = Object.freeze(["iphone", "ipad", "android_phone", "android_tablet", "pc", "other"]);
/** The platforms an identity is of, by its prefix (stores.mjs). */
export const PLATFORMS = Object.freeze(["gc", "gp"]);

const HOUR_MS = 60 * 60 * 1000;

/** What a device says it is, held to the list's words: a kind from
 *  DEVICES and a model of plain letters, at most 32 characters. Nothing a
 *  device sends here can name its player, and nothing is required. */
export function deviceOf(d) {
  const kind = DEVICES.includes(d?.kind) ? d.kind : "other";
  const model = typeof d?.model === "string"
    ? d.model.replace(/[^A-Za-z0-9 ,.+()_-]/g, "").replace(/\s+/g, " ").trim().slice(0, 32) : "";
  return { device: kind, model: model || null };
}

/** The country an edge header names (ISO 3166-1 alpha-2), or null: never
 *  the address, and not Cloudflare's "XX" (unknown) or "T1" (Tor). */
export function placeOf(code) {
  const c = String(code ?? "").trim().toUpperCase();
  return /^[A-Z]{2}$/.test(c) && c !== "XX" ? c : null;
}

/** The platform an identity is of: "gc" or "gp", or null. */
export const platformOf = (identity) => {
  const p = String(identity ?? "").split(":")[0];
  return PLATFORMS.includes(p) ? p : null;
};

const refused = () => new Refused(401, "session_refused");

export class Auth {
  /** `keys` is the token key ring (tokens.mjs keyring). */
  constructor(service, keys) {
    this.service = service;
    this.keys = keys;
  }

  get db() {
    return this.service.db;
  }

  /** A new session for `account`, and its two tokens. `via` is the
   *  identity that signed it in (only its platform is kept), `device` what
   *  the device says it is (deviceOf), `place` the edge's country code. */
  start(account, now = this.service.now(), { via = null, device = null, place = null } = {}) {
    // Secrets come from the system's generator, never the service's
    // `random`, which tests make a counter so seeds are the same each run.
    const salt = randomBytes(16).toString("hex");
    const d = deviceOf(device);
    const id = Number(this.db.prepare(
      `INSERT INTO sessions (account, salt, generation, created_at, used_at, via, device, model, place)
         VALUES (?, ?, 0, ?, ?, ?, ?, ?, ?)`)
      .run(account, salt, now, now, platformOf(via), d.device, d.model, placeOf(place)).lastInsertRowid);
    return this.#tokens({ id, account, salt, generation: 0, created_at: now }, now);
  }

  #tokens(s, now) {
    // Never past the session's absolute life: the platform proves it again.
    const until = Math.min(now + SESSION_MS, s.created_at + ABSOLUTE_MS);
    const access = issueAccess(this.keys, { account: s.account, session: s.id }, now, until);
    return {
      account: s.account,
      token: access.token,
      expiresIn: Math.floor((access.expires - now) / 1000),
      refreshToken: issueRefresh(this.keys, { session: s.id, generation: s.generation, salt: s.salt }),
    };
  }

  /** The account and session an access token names, from its signature
   *  alone: what the edge limits a caller by before it reads (G44). */
  holder(token) {
    const t = readAccess(this.keys, token, this.service.now());
    if (!t) throw refused();
    return t;
  }

  /**
   * The account an access token is good for now: signed, in date, and its
   * session neither ended nor someone else's. One read, two rows by their
   * keys: the account's — deleted, banned — and the session's. A deleted
   * account's token is refused at once (§20.5), a banned one's too (§20.12).
   */
  account(token) {
    const t = this.holder(token);
    const row = this.db.prepare(
      `SELECT a.deleted_at, a.banned_at, s.account AS owner, s.ended_at
         FROM accounts a LEFT JOIN sessions s ON s.id = ? WHERE a.id = ?`).get(t.session, t.account);
    if (!row) throw refused();
    if (row.deleted_at) throw new Refused(401, "account_deleted");
    if (row.banned_at) throw new Refused(403, "banned");
    if (row.owner !== t.account || row.ended_at !== null) throw refused();
    return t.account;
  }

  /**
   * New tokens for a refresh token, which is spent: a token of this
   * session's current generation rotates it; one of an earlier generation,
   * correctly signed, has been used before — by the player or by whoever
   * copied it — and ends the session for both. Anything else is refused and
   * changes nothing, so a guess cannot end someone's session.
   */
  refresh(token, now = this.service.now(), { place = null } = {}) {
    const peek = peekRefresh(token);
    if (!peek) throw refused();
    // A reuse ends the family in its own transaction, kept though the
    // refresh itself is refused.
    const out = transaction(this.db, () => {
      const s = this.db.prepare(
        `SELECT s.id, s.account, s.salt, s.generation, s.created_at, s.used_at, s.ended_at,
                a.deleted_at, a.banned_at
           FROM sessions s JOIN accounts a ON a.id = s.account WHERE s.id = ?`).get(peek.session);
      if (!s || !refreshSigned(this.keys, token, s.salt)) throw refused();
      if (s.deleted_at || s.banned_at || s.ended_at !== null) throw refused();
      if (peek.generation !== s.generation) {
        if (peek.generation < s.generation) this.#end("id", s.id, "reused", now);
        return null;
      }
      if (now - s.used_at > IDLE_MS || now - s.created_at >= ABSOLUTE_MS) return null;
      const next = s.generation + 1;
      // The same write records where it was last seen (the devices list):
      // a country, kept as it was when the edge names none.
      const moved = this.db.prepare(
        `UPDATE sessions SET generation = ?, used_at = ?, place = COALESCE(?, place)
          WHERE id = ? AND generation = ? AND ended_at IS NULL`)
        .run(next, now, placeOf(place), s.id, s.generation).changes;
      if (moved !== 1) return null;
      // A refresh is the day's sign-in as analytics count it (service.session).
      this.service.telemetry.once(s.account, "sign_in", now);
      return this.#tokens({ ...s, generation: next }, now);
    });
    if (!out) throw refused();
    return out;
  }

  /** The session an access token names, ended; with `everywhere`, every
   *  session of its account. Ending one already ended is no error, so a
   *  retried sign-out is harmless. Answers how many ended now. */
  signOut(token, { everywhere = false, others = false, device = null } = {}) {
    const t = this.holder(token);
    const now = this.service.now();
    if (everywhere) return this.endAll(t.account, "everywhere", now);
    if (others) {
      return Number(this.db.prepare(
        "UPDATE sessions SET ended_at = ?, ended = 'others' WHERE account = ? AND id != ? AND ended_at IS NULL")
        .run(now, t.account, t.session).changes);
    }
    // One device from the list: only a session of this account; any other
    // id ends nothing and answers the same, so ids cannot be probed.
    if (device !== null) return this.#end("id", device, device === t.session ? "signed_out" : "device", now, t.account);
    return this.#end("id", t.session, "signed_out", now, t.account);
  }

  /**
   * The account's devices signed in now, newest use first: each one's kind
   * and model as it named them, the platform that signed it in, the
   * country it was last seen in, and when — to the hour, as a refresh
   * records it, and to the day for when it signed in. `session` marks the
   * asking device. Nothing here is an address, and no id but the
   * session's, which only its own account can act on.
   */
  devices(account, session, now = this.service.now()) {
    return this.db.prepare(
      `SELECT id, via, device, model, place, created_at, used_at FROM sessions
        WHERE account = ? AND ended_at IS NULL AND used_at > ? AND created_at > ?
        ORDER BY id = ? DESC, used_at DESC, id DESC LIMIT 50`)
      .all(account, now - IDLE_MS, now - ABSOLUTE_MS, session)
      .map((s) => ({
        id: s.id, current: s.id === session, via: s.via ?? null, device: s.device ?? "other",
        model: s.model ?? null, place: s.place ?? null,
        signedInAt: s.created_at - (s.created_at % DAY_MS),
        lastSeenAt: s.id === session ? now - (now % HOUR_MS) : s.used_at - (s.used_at % HOUR_MS),
      }));
  }

  /** Every session of `account` ended, for `why` (ENDINGS). */
  endAll(account, why, now = this.service.now()) {
    // A ban holds on every identity the account could sign in with: the one
    // it was made with is banned by the caller (workshop.mjs), its links
    // here, so neither can make a fresh account (§20.12).
    if (why === "banned") {
      const a = this.db.prepare("SELECT banned_at, banned_reason FROM accounts WHERE id = ?").get(account);
      for (const l of this.linked(account)) banIdentity(this.db, l.identity, a?.banned_at ?? now, a?.banned_reason ?? null);
    }
    return this.#end("account", account, why, now);
  }

  /** A platform identity moved to or from `account`: whoever held its
   *  sessions proved the old one, so they end (docs/security/auth.md T11). */
  identityChanged(account, now = this.service.now()) {
    return this.endAll(account, "identity", now);
  }

  #end(by, key, why, now, account = null) {
    if (!ENDINGS.includes(why)) throw new Error(`no ending ${why}`);
    const where = by === "id" ? "id = ?" : "account = ?";
    const also = account ? " AND account = ?" : "";
    return Number(this.db.prepare(
      `UPDATE sessions SET ended_at = ?, ended = ? WHERE ${where}${also} AND ended_at IS NULL`)
      .run(now, why, key, ...(account ? [account] : [])).changes);
  }

  /** An account's sessions and linked identities, gone with its deletion
   *  (§20.12: erased). A banned account's links are already in `bans`. */
  forget(account) {
    this.db.prepare("DELETE FROM linked_identities WHERE account = ?").run(account);
    return Number(this.db.prepare("DELETE FROM sessions WHERE account = ?").run(account).changes);
  }

  // -- linked identities ----------------------------------------------------

  /** The identities linked to `account`, beyond the one it was made with. */
  linked(account) {
    return this.db.prepare(
      "SELECT identity, linked_at FROM linked_identities WHERE account = ? ORDER BY linked_at").all(account);
  }

  /** The account `identity` signs in to: the one made with it, or the one
   *  it is linked to. `{id, banned_at}` or undefined. */
  accountOf(identity) {
    return this.db.prepare("SELECT id, banned_at FROM accounts WHERE platform_identity = ?").get(identity)
      ?? this.db.prepare(
        `SELECT a.id, a.banned_at FROM linked_identities l JOIN accounts a ON a.id = l.account
          WHERE l.identity = ?`).get(identity);
  }

  /** Every platform an account signs in with: `[{platform, primary, linkedAt}]`. */
  identities(account) {
    const own = this.db.prepare("SELECT platform_identity, created_at FROM accounts WHERE id = ?").get(account);
    return [
      ...(own ? [{ platform: platformOf(own.platform_identity), primary: true, linkedAt: null }] : []),
      ...this.linked(account).map((l) => ({ platform: platformOf(l.identity), primary: false,
                                            linkedAt: l.linked_at - (l.linked_at % DAY_MS) })),
    ];
  }

  /** Whether `identity` is one `account` signs in with. */
  #owns(account, identity) {
    return this.accountOf(identity)?.id === account;
  }

  /**
   * `adding`, proven, linked to `account`, which `current` — a fresh proof
   * of an identity it already signs in with — proves is the player's: a
   * stolen access token alone cannot link a thief's identity and keep the
   * account. One identity of each platform; never one with an account or a
   * ban of its own (there is no merging: §20.12's ledger is per account).
   * Sessions are kept: nothing proven before is less true now.
   */
  link(account, current, adding, now = this.service.now()) {
    if (!current || !this.#owns(account, current)) throw new Refused(401, "platform_identity_refused");
    const platform = platformOf(adding);
    if (!platform) throw new Refused(401, "platform_identity_refused");
    if (this.db.prepare("SELECT 1 FROM bans WHERE identity = ?").get(adding)) throw new Refused(403, "banned");
    if (this.accountOf(adding)) throw new Refused(409, "identity_in_use");
    if (this.identities(account).some((i) => i.platform === platform)) throw new Refused(409, "platform_linked");
    this.db.prepare("INSERT INTO linked_identities (identity, account, linked_at) VALUES (?, ?, ?)")
      .run(adding, account, now);
    return this.identities(account);
  }

  /**
   * The linked identity of `platform` removed from `account`, proven by a
   * fresh proof of the identity that stays (`current`). Every session it
   * signed in ends (docs/security/auth.md T11); the asking one is kept,
   * as it proved the identity that stays.
   */
  unlink(account, session, current, platform, now = this.service.now()) {
    if (!current || !this.#owns(account, current)) throw new Refused(401, "platform_identity_refused");
    const l = this.linked(account).find((x) => platformOf(x.identity) === platform);
    if (!l || l.identity === current) throw new Refused(409, "not_linked");
    transaction(this.db, () => {
      this.db.prepare("DELETE FROM linked_identities WHERE identity = ?").run(l.identity);
      this.db.prepare(
        `UPDATE sessions SET ended_at = ?, ended = 'identity'
          WHERE account = ? AND via = ? AND id != ? AND ended_at IS NULL`).run(now, account, platform, session);
    });
    return this.identities(account);
  }

  /** How many sessions `account` has live: what "sign out everywhere" ends. */
  live(account, now = this.service.now()) {
    return this.db.prepare(
      `SELECT COUNT(*) AS n FROM sessions WHERE account = ? AND ended_at IS NULL
          AND used_at > ? AND created_at > ?`).get(account, now - IDLE_MS, now - ABSOLUTE_MS).n;
  }

  /** The session a refresh token names, ended, without rotating it: a
   *  device signing out with an access token past its hour. Refused as any
   *  refresh is if the token is not this server's for that session. */
  signOutWith(refreshToken, { everywhere = false } = {}) {
    const peek = peekRefresh(refreshToken);
    const s = peek && this.db.prepare("SELECT id, account, salt FROM sessions WHERE id = ?").get(peek.session);
    if (!s || !refreshSigned(this.keys, refreshToken, s.salt)) throw refused();
    const now = this.service.now();
    if (everywhere) return this.endAll(s.account, "everywhere", now);
    return this.#end("id", s.id, "signed_out", now);
  }

  // -- single use ------------------------------------------------------------

  /** The platform identity `credential` proves, once (auth_proofs.mjs):
   *  the service's `verifyPlatform` given what spends a proof. With
   *  `expectNonce`, a Google token must carry exactly that nonce — the web
   *  page's, bound to its cookie; with `audience`, be for that client id
   *  alone; with `freshMs`, have been issued no longer ago than that. */
  prove(credential, { expectNonce = null, audience = null, freshMs = null } = {}) {
    return this.service.verifyPlatform(credential, {
      expectNonce, audience, freshMs, now: this.service.now(),
      spend: (key, until) => this.spend(key, until),
      spendNonce: (nonce) => this.spendNonce(nonce),
    });
  }

  /** A nonce a platform proof must carry back (§24.8's single-use): signed,
   *  five minutes, written nowhere until it is spent. */
  nonce(now = this.service.now()) {
    const n = issueNonce(this.keys, randomBytes(16).toString("hex"), now);
    return { nonce: n.nonce, expiresIn: Math.floor((n.expires - now) / 1000) };
  }

  /** Whether `nonce` is one this server made, still in date and not yet
   *  spent; spending it if so. */
  spendNonce(nonce, now = this.service.now()) {
    const n = readNonce(this.keys, nonce, now);
    return n ? this.spend(`nonce:${nonce}`, n.expires, now) : false;
  }

  /** `key` spent until `until`: true the first time, false after. Kept by a
   *  hash, so what it names — a Game Center player, a nonce — is not. */
  spend(key, until, now = this.service.now()) {
    const hash = createHash("sha256").update(String(key)).digest("base64url");
    const done = this.db.prepare(
      "INSERT INTO auth_spent (key, expires_at) VALUES (?, ?) ON CONFLICT (key) DO NOTHING").run(hash, until);
    // A row kept past its life is no longer a reason to refuse.
    if (done.changes === 0) {
      const row = this.db.prepare("SELECT expires_at FROM auth_spent WHERE key = ?").get(hash);
      if (row && row.expires_at > now) return false;
      this.db.prepare("UPDATE auth_spent SET expires_at = ? WHERE key = ?").run(until, hash);
    }
    return true;
  }

  /** The daily job: sessions ended or lapsed more than ENDED_KEEP_MS ago,
   *  and spent proofs past their life, deleted (§20.5). Idempotent. */
  expire(now = this.service.now()) {
    return transaction(this.db, () => ({
      sessions: Number(this.db.prepare(
        `DELETE FROM sessions WHERE ended_at < ? OR used_at < ? OR created_at < ?`)
        .run(now - ENDED_KEEP_MS, now - IDLE_MS - ENDED_KEEP_MS, now - ABSOLUTE_MS - ENDED_KEEP_MS).changes),
      spent: Number(this.db.prepare("DELETE FROM auth_spent WHERE expires_at < ?").run(now).changes),
    }));
  }
}
