// §24.8: "No passwords. Platform identity is exchanged for a short-lived
// signed token."
//
// Three things the server signs, each with a key id so the key can be
// rotated without signing anyone out (docs/security/auth.md):
//
//   - an access token, `a1.kid.account.session.expiry.mac`: an hour, the
//     document's "keeps its session for its hour". Its signature alone says
//     who is asking, so the edge limits a caller before any read (G44); the
//     session it names is then read, so a session ended is refused at once
//     (auth.mjs).
//   - a refresh token, `r1.kid.session.generation.mac`: the MAC also over the
//     session's random salt, which only the database holds, so neither a
//     copy of the database nor the key alone can make one. Rotated on every
//     use (auth.mjs).
//   - a nonce, `n1.kid.random.expiry.mac`: five minutes, for a Google ID
//     token to carry (§24.8's single-use), checked without a read and made
//     single-use when it is spent.
//
// Every MAC is HMAC-SHA256 over the token's own kind and fields, compared in
// constant time. A key ring is `{current, keys: {kid: Buffer}}`: the current
// key signs, every key in the ring is accepted.
//
// What is not here: checking the platform identity itself — a Game Center or
// Google credential — needs Apple's and Google's keys, so the service takes a
// `verifyPlatform` function, and the tests give it a fake one. That is the
// one seam between this server and the stores (stores.mjs, auth_proofs.mjs).

import { createHmac, timingSafeEqual } from "node:crypto";

/** How long an access token lasts: §24.1's "keeps its session for its hour". */
export const SESSION_MS = 60 * 60 * 1000;
/** How long a nonce for a platform proof lasts: §24.8's five minutes. */
export const NONCE_MS = 5 * 60 * 1000;

const KID = /^[A-Za-z0-9]{1,16}$/;
const HEX = /^[0-9a-f]{8,64}$/;
const INT = /^[0-9]{1,15}$/;

/**
 * The ring from the server's secret and, optionally, a list of
 * `kid:secret` pairs (the first signs). Without a list, one key, `k0`,
 * derived from the secret apart from telemetry's pseudonyms, so the two
 * never move together.
 */
export function keyring(secret, list = "") {
  const keys = {};
  let current = null;
  for (const pair of String(list ?? "").split(",").map((s) => s.trim()).filter(Boolean)) {
    const cut = pair.indexOf(":");
    const kid = pair.slice(0, cut);
    const key = pair.slice(cut + 1);
    if (cut < 1 || !KID.test(kid)) throw new Error(`a token key needs an id of letters and digits: ${kid || "(none)"}`);
    if (key.length < 32) throw new Error(`token key ${kid} is shorter than 32 characters`);
    if (keys[kid]) throw new Error(`token key ${kid} is named twice`);
    keys[kid] = derive(key);
    current ??= kid;
  }
  if (!current) {
    if (typeof secret !== "string" || secret.length === 0) throw new Error("tokens need a secret");
    keys.k0 = derive(secret);
    current = "k0";
  }
  return Object.freeze({ current, keys: Object.freeze(keys) });
}

const derive = (secret) => createHmac("sha256", secret).update("ruleborn session tokens v1").digest();

const mac = (key, body) => createHmac("sha256", key).update(body).digest("base64url");

/** Equal in constant time; unequal lengths are unequal, at once. */
function same(a, b) {
  const x = Buffer.from(a);
  const y = Buffer.from(b);
  return x.length === y.length && timingSafeEqual(x, y);
}

/** The fields of `token` of `kind`, its MAC checked under the key it names,
 *  or null. `extra` is MACed after the fields and is not in the token. */
function open(ring, token, kind, n, extra = "") {
  if (typeof token !== "string" || token.length > 512) return null;
  const parts = token.split(".");
  if (parts.length !== n + 3 || parts[0] !== kind) return null;
  const kid = parts[1];
  const key = Object.hasOwn(ring.keys, kid) ? ring.keys[kid] : null;
  if (!key) return null;
  const body = parts.slice(0, -1).join(".");
  if (!same(parts.at(-1), mac(key, `${body}|${extra}`))) return null;
  return { kid, fields: parts.slice(2, -1) };
}

function seal(ring, kind, fields, extra = "") {
  const body = [kind, ring.current, ...fields].join(".");
  return `${body}.${mac(ring.keys[ring.current], `${body}|${extra}`)}`;
}

/** An access token, good until `until` (an hour from `now` at most). */
export function issueAccess(ring, { account, session }, now, until = now + SESSION_MS) {
  if (!HEX.test(account) || !INT.test(String(session))) throw new Error("an account is hex, a session a number");
  const expires = Math.min(until, now + SESSION_MS);
  return { token: seal(ring, "a1", [account, session, expires]), expires };
}

/** `{account, session, expires}`, or null if forged, malformed or stale. */
export function readAccess(ring, token, now) {
  const t = open(ring, token, "a1", 3);
  if (!t) return null;
  const [account, session, expires] = t.fields;
  if (!HEX.test(account) || !INT.test(session) || !INT.test(expires)) return null;
  if (!(Number(expires) > now)) return null;
  return { account, session: Number(session), expires: Number(expires) };
}

export function issueRefresh(ring, { session, generation, salt }) {
  return seal(ring, "r1", [session, generation], salt);
}

/** The session and generation a refresh token names, unchecked: its MAC
 *  needs the salt the session's row holds (`refreshSigned`). */
export function peekRefresh(token) {
  if (typeof token !== "string" || token.length > 512) return null;
  const parts = token.split(".");
  if (parts.length !== 5 || parts[0] !== "r1" || !INT.test(parts[2]) || !INT.test(parts[3])) return null;
  return { session: Number(parts[2]), generation: Number(parts[3]) };
}

/** Whether the server made this refresh token for a session with `salt`. */
export function refreshSigned(ring, token, salt) {
  return open(ring, token, "r1", 2, salt) !== null;
}

export function issueNonce(ring, random, now) {
  const expires = now + NONCE_MS;
  return { nonce: seal(ring, "n1", [random, expires]), expires };
}

/** Whether the server made this nonce and it is not yet stale. */
export function readNonce(ring, nonce, now) {
  const t = open(ring, nonce, "n1", 2);
  if (!t) return null;
  const [random, expires] = t.fields;
  if (!HEX.test(random) || !INT.test(expires) || !(Number(expires) > now)) return null;
  return { expires: Number(expires) };
}
