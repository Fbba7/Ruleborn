// The stores' proofs, checked on the server (§24.8, §22.1).
//
// §24.8: "Platform identity is exchanged for a short-lived signed token."
// Two Apple proofs can be checked without asking Apple anything, because
// Apple signs them with a certificate chain that ends at its own root:
//
//   - a Game Center identity: the device's identity-verification signature
//     over the player's ID, the app's bundle ID, a timestamp and a salt,
//     made with the key in the certificate Apple publishes at a URL on its
//     own domain;
//   - a StoreKit 2 transaction: a JWS whose header carries its chain (x5c),
//     signed ES256, naming the product, the transaction and the
//     appAccountToken the purchase was made with.
//
// The roots are configuration, not code, and each proof has its own: the
// operator pins Apple Root CA G3 for StoreKit and the CA that issues Game
// Center's key for Game Center, and the tests pin a stand-in. Fetching
// Game Center's certificate is the only network call, so it is injected and
// cached, and done before the synchronous check.
//
// Google's two proofs can be checked the same way, without asking Google
// about any one player:
//
//   - a Play Billing purchase: the purchase's JSON exactly as Play returned
//     it, signed RSA-SHA1 with the app's licence key, which the Play Console
//     gives the developer;
//   - a Google sign-in: the ID token "Sign in with Google" returns on
//     Android, a JWT Google signs RS256 with keys it publishes at a fixed
//     URL, fetched and cached before the synchronous check as Game Center's
//     are. It proves a Google account, not a Play Games player: Play Games
//     Services hands a server only a code to exchange with Google (D67).

import { X509Certificate, createPublicKey, createVerify, verify as verifySignature } from "node:crypto";

/** How old a Game Center signature may be (G32). */
export const GAME_CENTER_FRESH_MS = 5 * 60 * 1000;

const b64url = (s) => Buffer.from(String(s).replace(/-/g, "+").replace(/_/g, "/"), "base64");

/**
 * Check a chain — leaf first — at `now`: each certificate in date, each
 * signed by the next, every issuer a certificate authority, and the last
 * either one of `roots` or signed by one. Returns the leaf, or null.
 */
export function verifyChain(chain, roots, now) {
  let certs;
  try {
    certs = chain.map((c) => (c instanceof X509Certificate ? c : new X509Certificate(c)));
  } catch {
    return null;
  }
  if (certs.length === 0) return null;
  const inDate = (c) => Date.parse(c.validFrom) <= now && now <= Date.parse(c.validTo);
  if (!certs.every(inDate)) return null;
  for (let i = 0; i + 1 < certs.length; i++) {
    const issuer = certs[i + 1];
    if (!issuer.ca || !certs[i].checkIssued(issuer) || !certs[i].verify(issuer.publicKey)) return null;
  }
  const last = certs[certs.length - 1];
  const anchored = roots.some((root) => root.fingerprint256 === last.fingerprint256
    || (root.ca && inDate(root) && last.checkIssued(root) && last.verify(root.publicKey)));
  return anchored ? certs[0] : null;
}

/**
 * The extensions Apple marks its StoreKit signing chain with: the leaf that
 * signs transactions, and the intermediate that issues it. Configuration, as
 * the root is, so the tests' stand-in chain can carry its own.
 */
export const STOREKIT_OIDS = Object.freeze({ leaf: "1.2.840.113635.100.6.11.1",
                                             intermediate: "1.2.840.113635.100.6.2.1" });

/** Whether a certificate carries the extension `oid` (RFC 5280 §4.1: tbsCertificate [3] extensions). */
function hasExtension(cert, oid) {
  const der = cert.raw;
  const node = (at) => {
    let length = der[at + 1];
    let start = at + 2;
    if (length & 0x80) {
      const bytes = length & 0x7f;
      length = 0;
      for (let i = 0; i < bytes; i++) length = length * 256 + der[start + i];
      start += bytes;
    }
    return { tag: der[at], start, end: start + length };
  };
  const children = ({ start, end }) => {
    const out = [];
    for (let at = start; at < end; at = out[out.length - 1].end) out.push(node(at));
    return out;
  };
  const dotted = ({ start, end }) => {
    const arcs = [];
    for (let at = start, arc = 0; at < end; at++) {
      arc = arc * 128 + (der[at] & 0x7f);
      if (!(der[at] & 0x80)) { arcs.push(arc); arc = 0; }
    }
    const first = Math.min(Math.floor(arcs[0] / 40), 2);
    return [first, arcs[0] - 40 * first, ...arcs.slice(1)].join(".");
  };
  try {
    const extensions = children(children(node(0))[0]).find((n) => n.tag === 0xa3);
    return !!extensions && children(children(extensions)[0]).some((ext) => dotted(children(ext)[0]) === oid);
  } catch {
    return false;
  }
}

/**
 * A StoreKit 2 signed transaction, checked; null if it is not Apple's. The
 * chain is Apple's StoreKit leaf, its intermediate and at most the pinned
 * root, each marked as Apple marks them, and the leaf's key is ES256's
 * (P-256): a certificate that merely chains to the root signs nothing. A
 * Sandbox purchase costs nothing, so it pays only where `sandbox` is set.
 */
export function appStoreTransaction(jws, { roots, bundleId, now, oids = STOREKIT_OIDS, sandbox = false }) {
  const payload = appleSigned(jws, { roots, now, oids });
  if (!payload || payload.bundleId !== bundleId || payload.revocationDate) return null;
  if (payload.environment !== "Production" && !(sandbox && payload.environment === "Sandbox")) return null;
  // One transaction is one grant, so one item, as Play's is (RB-11).
  if (payload.quantity !== undefined && payload.quantity !== 1) return null;
  return {
    transaction: String(payload.transactionId),
    product: payload.productId,
    intent: payload.appAccountToken ?? null,
  };
}

/** The payload of a JWS Apple's App Store signed, as `appStoreTransaction`
 *  checks one, or null. */
function appleSigned(jws, { roots, now, oids = STOREKIT_OIDS }) {
  const parts = String(jws).split(".");
  if (parts.length !== 3) return null;
  let header;
  let payload;
  let certs;
  try {
    header = JSON.parse(b64url(parts[0]).toString("utf8"));
    payload = JSON.parse(b64url(parts[1]).toString("utf8"));
    if (header.alg !== "ES256" || !Array.isArray(header.x5c)) return null;
    certs = header.x5c.map((c) => new X509Certificate(Buffer.from(c, "base64")));
  } catch {
    return null;
  }
  if (certs.length < 2 || certs.length > 3) return null;
  if (certs.length === 3 && !roots.some((root) => root.fingerprint256 === certs[2].fingerprint256)) return null;
  const leaf = verifyChain(certs, roots, now);
  if (!leaf || !hasExtension(leaf, oids.leaf) || !hasExtension(certs[1], oids.intermediate)) return null;
  const key = leaf.publicKey;
  if (key.asymmetricKeyType !== "ec" || key.asymmetricKeyDetails?.namedCurve !== "prime256v1") return null;
  const signed = Buffer.from(`${parts[0]}.${parts[1]}`);
  const ok = verifySignature("sha256", signed, { key, dsaEncoding: "ieee-p1363" }, b64url(parts[2]));
  return ok && payload && typeof payload === "object" ? payload : null;
}

/** The App Store Server Notifications (v2) that take a purchase back, or
 *  give one back when its refund is reversed (G32). */
export const APPLE_REFUNDS = Object.freeze(["REFUND", "REVOKE", "REFUND_REVERSED"]);

/**
 * An App Store Server Notification (v2), checked as a transaction is: its
 * signedPayload signed under the pinned root, for this app and environment,
 * and the transaction inside it signed too. Returns `{type, transaction,
 * product}` — `transaction` null for a type that takes nothing back — or
 * null for one that does not check.
 */
export function appStoreNotification(signedPayload, { roots, bundleId, now, oids = STOREKIT_OIDS, sandbox = false }) {
  const n = appleSigned(signedPayload, { roots, now, oids });
  const data = n?.data;
  if (!n || typeof n.notificationType !== "string" || !data || data.bundleId !== bundleId) return null;
  if (data.environment !== "Production" && !(sandbox && data.environment === "Sandbox")) return null;
  if (!APPLE_REFUNDS.includes(n.notificationType)) return { type: n.notificationType, transaction: null };
  const t = appleSigned(data.signedTransactionInfo, { roots, now, oids });
  if (!t || t.bundleId !== bundleId) return null;
  return { type: n.notificationType, transaction: String(t.transactionId), product: t.productId };
}

/** How many of Game Center's certificates are kept: Apple publishes a few. */
export const GAME_CENTER_CACHE = 8;

/** How long a certificate that could not be fetched is not asked for again. */
export const GAME_CENTER_RETRY_MS = 60 * 1000;

/** How often a key URL never fetched before may be tried: anyone may ask
 *  before any identity is proved, so an unseen name costs a fetch at most
 *  this often from one address (G32). Where the deployment cannot tell the
 *  address (no RULEBORN_PEER_HEADER, which production requires), whoever
 *  asks (SEC-36). */
export const GAME_CENTER_NEW_MS = 1000;

/** Apple numbers its keys upwards: a key name more than this far past the
 *  highest of its kind fetched so far is a probe, never fetched, so a caller
 *  naming made-up keys spends no fetch at all (SEC-36). */
export const GAME_CENTER_KEY_AHEAD = 3;

/** How many addresses' last unseen-name fetch are remembered. */
const GAME_CENTER_ADDRESSES = 4096;

/** Game Center's key hosts and names: its production and sandbox keys,
 *  gc-prod-N and gc-sb-N (G32). */
const KEY_HOSTS = new Set(["static.gc.apple.com", "sandbox.gc.apple.com"]);
const KEY_NAME = /^\/public-key\/gc-(prod|sb)-(\d{1,4})\.cer$/;

/**
 * Game Center's identity verification. `fetchCertificate(url)` is the one
 * network call; `prepare` makes it and caches the answer, so `verify` —
 * which the service calls synchronously — needs none. The cache is small and
 * the URL plain, since anyone may ask before any identity is proved.
 */
export class GameCenter {
  constructor({ roots, bundleId, fetchCertificate, now = () => Date.now(), organization = "Apple Inc." }) {
    Object.assign(this, { roots, bundleId, fetchCertificate, now, organization });
    // Keys fetched and read, newest last; failures apart, so a stream of
    // bad names never pushes a good key out.
    this.certificates = new Map();
    this.failures = new Map();
    // When each address (or, unknown, everyone: "") last had an unseen name
    // fetched, least recent first; and the highest key number of each kind
    // fetched and found to be Apple's (SEC-36).
    this.lastNew = new Map();
    this.highest = new Map();
  }

  /** A key URL's kind ("prod", "sb") and number. */
  static keyOf(url) {
    const m = KEY_NAME.exec(new URL(url).pathname);
    return { kind: m[1], n: Number(m[2]) };
  }

  /**
   * Only Game Center's own servers publish the key (G32), at one of its key
   * names, written plainly: no query, fragment, port or user, so one key is
   * one URL.
   */
  static trustedUrl(url) {
    try {
      const u = new URL(url);
      return url === `https://${u.hostname}${u.pathname}` && KEY_HOSTS.has(u.hostname)
        && KEY_NAME.test(u.pathname);
    } catch {
      return false;
    }
  }

  async prepare(credential, peer = null) {
    const url = credential?.publicKeyUrl;
    if (!GameCenter.trustedUrl(url)) return;
    const { kind, n } = GameCenter.keyOf(url);
    const now = this.now();
    const known = this.certificates.get(url);
    // Past its validTo a cached key is fetched again: Apple renews it at the
    // same URL, and the expired one would refuse every sign-in (RB-02).
    if (known && now <= Date.parse(known.cert.validTo)) {
      // Recently used: to the back of the queue.
      this.certificates.delete(url);
      this.certificates.set(url, known);
      return;
    }
    const failed = this.failures.get(url);
    if (failed !== undefined && now - failed < GAME_CENTER_RETRY_MS) return;
    // Too far past the newest key of its kind: a probe, refused at once.
    // Before any key of the kind is fetched there is nothing to be past.
    const top = this.highest.get(kind);
    if (top !== undefined && n > top + GAME_CENTER_KEY_AHEAD) return;
    const from = peer ?? "";
    if (now - (this.lastNew.get(from) ?? -Infinity) < GAME_CENTER_NEW_MS) return;
    this.lastNew.delete(from);
    this.lastNew.set(from, now);
    while (this.lastNew.size > GAME_CENTER_ADDRESSES) this.lastNew.delete(this.lastNew.keys().next().value);
    let cert = null;
    try {
      cert = new X509Certificate(await this.fetchCertificate(url));
    } catch {
      // An unreachable or unreadable certificate proves nothing; verify refuses.
    }
    // Apple's own key, under the pinned roots: the newest of its kind moves up.
    if (cert && verifyChain([cert], this.roots, now) && cert.subject.split("\n").includes(`O=${this.organization}`)
        && n > (this.highest.get(kind) ?? -1)) {
      this.highest.set(kind, n);
    }
    // Past `most`, the oldest goes — but a key that has verified a real
    // signature only once every key not yet proven is gone: a caller naming
    // Apple's key URLs one after another cannot push out the key players
    // sign in with (T12's SR-20).
    const keep = (map, key, value, most) => {
      map.delete(key);
      map.set(key, value);
      while (map.size > most) {
        const unproven = [...map].find(([, v]) => !v?.proven);
        map.delete(unproven ? unproven[0] : map.keys().next().value);
      }
    };
    if (cert) {
      this.failures.delete(url);
      keep(this.certificates, url, { cert, at: now }, GAME_CENTER_CACHE);
    } else {
      keep(this.failures, url, now, 4 * GAME_CENTER_CACHE);
    }
  }

  /** The platform identity a credential proves, or null. */
  verify(credential) {
    const { playerId, bundleId, publicKeyUrl, signature, salt, timestamp } = credential ?? {};
    if (typeof playerId !== "string" || !playerId || bundleId !== this.bundleId) return null;
    if (!GameCenter.trustedUrl(publicKeyUrl) || !Number.isSafeInteger(timestamp)) return null;
    const now = this.now();
    if (Math.abs(now - timestamp) > GAME_CENTER_FRESH_MS) return null;
    const held = this.certificates.get(publicKeyUrl);
    const cert = held?.cert;
    if (!cert || !verifyChain([cert], this.roots, now)) return null;
    // The pinned CA sells certificates to anyone; the key must be Apple's.
    if (!cert.subject.split("\n").includes(`O=${this.organization}`)) return null;
    const stamp = Buffer.alloc(8);
    stamp.writeBigUInt64BE(BigInt(timestamp));
    const payload = Buffer.concat([Buffer.from(playerId, "utf8"), Buffer.from(bundleId, "utf8"),
                                   stamp, Buffer.from(String(salt ?? ""), "base64")]);
    const check = createVerify("RSA-SHA256");
    check.update(payload);
    if (!check.verify(cert.publicKey, Buffer.from(String(signature ?? ""), "base64"))) return null;
    held.proven = true;
    return `gc:${playerId}`;
  }
}

// -- Google -----------------------------------------------------------------

/** The longest purchase JSON or ID token read: both are a few hundred bytes. */
const GOOGLE_MOST = 8192;

/**
 * A Play Billing purchase, checked; null if the app's licence key did not
 * sign it, or it is not a completed purchase of one item for this app. The
 * purchase token is the transaction. The intent rides the purchase as its
 * obfuscatedAccountId, as it rides Apple's as the appAccountToken. What a
 * signature cannot say — still paid for, a licence tester's, consumed — the
 * Play Developer API says before the grant (googleapi.mjs, D67).
 */
export function playPurchase(receipt, { licenceKey, packageName }) {
  // The client sends the purchase as the JSON string Play's billing plugin
  // gives it (RB-10): read it as an object, within the length both parts
  // could have.
  if (typeof receipt === "string") {
    if (receipt.length > 4 * GOOGLE_MOST) return null;
    try {
      receipt = JSON.parse(receipt);
    } catch {
      return null;
    }
    if (typeof receipt !== "object" || receipt === null || Array.isArray(receipt)) return null;
  }
  const { data, signature } = receipt ?? {};
  if (typeof data !== "string" || typeof signature !== "string") return null;
  if (data.length > GOOGLE_MOST || signature.length > GOOGLE_MOST) return null;
  if (licenceKey?.asymmetricKeyType !== "rsa") return null;
  let ok = false;
  try {
    ok = verifySignature("sha1", Buffer.from(data, "utf8"), licenceKey, Buffer.from(signature, "base64"));
  } catch {
    return null;
  }
  if (!ok) return null;
  let p;
  try {
    p = JSON.parse(data);
  } catch {
    return null;
  }
  if (p?.packageName !== packageName) return null;
  // 0 is purchased; 1 is cancelled and 4 pending, which Play has not charged.
  if (p.purchaseState !== 0) return null;
  if (typeof p.productId !== "string" || !p.productId) return null;
  if (typeof p.purchaseToken !== "string" || !p.purchaseToken) return null;
  if (p.quantity !== undefined && p.quantity !== 1) return null;
  return {
    transaction: p.purchaseToken,
    product: p.productId,
    intent: typeof p.obfuscatedAccountId === "string" && p.obfuscatedAccountId ? p.obfuscatedAccountId : null,
  };
}

/** Where Google publishes the keys it signs ID tokens with, and who it is. */
export const GOOGLE_KEYS_URL = "https://www.googleapis.com/oauth2/v3/certs";
export const GOOGLE_ISSUERS = Object.freeze(["accounts.google.com", "https://accounts.google.com"]);

/** How often the keys may be fetched again for a key id not held: anyone may
 *  ask before any identity is proved (G32). While none are held at all —
 *  a cold start, a first fetch that failed — sooner. */
export const GOOGLE_KEYS_RETRY_MS = 60 * 1000;
export const GOOGLE_KEYS_COLD_RETRY_MS = 5 * 1000;

/** How far a token's times may sit from the server's clock. */
export const GOOGLE_SKEW_MS = 5 * 60 * 1000;

/**
 * "Sign in with Google" on Android: the ID token, a JWT Google signs RS256.
 * `fetchKeys()` is the one network call — it resolves `{keys, maxAgeMs}`
 * from GOOGLE_KEYS_URL — and `prepare` makes it when a token names a key not
 * held, or the keys are past the age Google gave them, and caches the
 * answer, so `verify`, which the service calls synchronously, needs none.
 * `clientIds` are the audiences accepted: the server's own OAuth client.
 */
export class GoogleSignIn {
  constructor({ clientIds, fetchKeys, now = () => Date.now() }) {
    if (!Array.isArray(clientIds) || clientIds.length === 0) throw new Error("GoogleSignIn needs its client ids");
    Object.assign(this, { clientIds, fetchKeys, now });
    this.keys = new Map();
    this.expires = -Infinity;
    this.lastFetch = -Infinity;
    this.pending = null;
  }

  static header(token) {
    if (typeof token !== "string" || token.length > GOOGLE_MOST) return null;
    const parts = token.split(".");
    if (parts.length !== 3) return null;
    try {
      const h = JSON.parse(b64url(parts[0]).toString("utf8"));
      return h && h.alg === "RS256" && typeof h.kid === "string" ? { ...h, parts } : null;
    } catch {
      return null;
    }
  }

  async prepare(credential) {
    const h = GoogleSignIn.header(credential?.idToken);
    if (!h) return;
    const now = this.now();
    if (this.keys.has(h.kid) && now < this.expires) return;
    // A fetch under way is shared: a sign-in arriving meanwhile waits for it.
    if (this.pending) {
      await this.pending;
      return;
    }
    // A key not held, or keys past their age: fetched at most once a
    // GOOGLE_KEYS_RETRY_MS, whoever asks; with none held, once a
    // GOOGLE_KEYS_COLD_RETRY_MS.
    const wait = this.keys.size === 0 ? GOOGLE_KEYS_COLD_RETRY_MS : GOOGLE_KEYS_RETRY_MS;
    if (now - this.lastFetch < wait) return;
    this.lastFetch = now;
    this.pending = this.refresh(now).finally(() => { this.pending = null; });
    await this.pending;
  }

  async refresh(now) {
    let answer;
    try {
      answer = await this.fetchKeys();
    } catch {
      return;                              // an unreachable key set proves nothing; verify refuses
    }
    const keys = new Map();
    for (const jwk of answer?.keys ?? []) {
      if (jwk?.kty !== "RSA" || typeof jwk.kid !== "string") continue;
      if ((jwk.use ?? "sig") !== "sig" || (jwk.alg ?? "RS256") !== "RS256") continue;
      try {
        keys.set(jwk.kid, createPublicKey({ key: { kty: "RSA", n: jwk.n, e: jwk.e }, format: "jwk" }));
      } catch {
        // one unreadable key does not spoil the rest
      }
    }
    if (keys.size === 0) return;
    this.keys = keys;
    const age = Number(answer.maxAgeMs);
    this.expires = now + (Number.isFinite(age) && age > 0 ? Math.min(age, 24 * 60 * 60 * 1000) : 60 * 60 * 1000);
  }

  /** The platform identity a credential proves, or null. */
  verify(credential) {
    const h = GoogleSignIn.header(credential?.idToken);
    if (!h) return null;
    const key = this.keys.get(h.kid);
    if (!key) return null;
    const [head, body, sig] = h.parts;
    let ok = false;
    try {
      ok = verifySignature("sha256", Buffer.from(`${head}.${body}`), key, b64url(sig));
    } catch {
      return null;
    }
    if (!ok) return null;
    let p;
    try {
      p = JSON.parse(b64url(body).toString("utf8"));
    } catch {
      return null;
    }
    if (!GOOGLE_ISSUERS.includes(p?.iss)) return null;
    const audiences = Array.isArray(p.aud) ? p.aud : [p.aud];
    if (!audiences.some((a) => this.clientIds.includes(a))) return null;
    const now = this.now();
    if (!Number.isFinite(p.exp) || p.exp * 1000 + GOOGLE_SKEW_MS < now) return null;
    if (!Number.isFinite(p.iat) || p.iat * 1000 - GOOGLE_SKEW_MS > now) return null;
    if (typeof p.sub !== "string" || !/^[0-9]{1,64}$/.test(p.sub)) return null;
    return `gp:${p.sub}`;
  }
}

// -- which proof a credential or receipt is ------------------------------------

/**
 * Sign-in across the platforms configured: a Game Center credential names
 * its key's URL, a Google one carries an ID token, and each goes only to its
 * own verifier. With neither configured, sign-in is stubbed — a string is
 * taken as the identity it names — which main.mjs allows only where no
 * store pays out, or the operator says it is a test (D67).
 */
export function signIn({ gameCenter = null, google = null } = {}) {
  const which = (c) => {
    if (c && typeof c === "object" && typeof c.idToken === "string") return google;
    if (c && typeof c === "object" && "publicKeyUrl" in c) return gameCenter;
    return null;
  };
  const stubbed = !gameCenter && !google;
  return {
    stubbed,
    prepare: async (c, peer = null) => { await which(c)?.prepare(c, peer); },
    verify: (c) => {
      if (stubbed) return typeof c === "string" && c ? c : null;
      return which(c)?.verify(c) ?? null;
    },
  };
}

/** Receipts across the stores configured, each to its own check; a store
 *  not configured refuses every receipt. */
export function receipts({ appStore = null, play = null, now = () => Date.now() } = {}) {
  return (store, receipt) => {
    if (store === "app-store" && appStore) return appStoreTransaction(receipt, { ...appStore, now: now() });
    if (store === "google-play" && play) return playPurchase(receipt, play);
    return null;
  };
}
