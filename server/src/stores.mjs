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
// cached, and done before the synchronous check. Google Play's proofs need
// Google's API for both, and are seams only (D67).

import { X509Certificate, createVerify, verify as verifySignature } from "node:crypto";

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
  if (!ok || payload.bundleId !== bundleId || payload.revocationDate) return null;
  if (payload.environment !== "Production" && !(sandbox && payload.environment === "Sandbox")) return null;
  return {
    transaction: String(payload.transactionId),
    product: payload.productId,
    intent: payload.appAccountToken ?? null,
  };
}

/** How many of Game Center's certificates are kept: Apple publishes a few. */
export const GAME_CENTER_CACHE = 8;

/** How long a certificate that could not be fetched is not asked for again. */
export const GAME_CENTER_RETRY_MS = 60 * 1000;

/** How often a key URL never fetched before may be tried: anyone may ask
 *  before any identity is proved, so an unseen name costs a fetch at most
 *  this often, whoever asks (G32). */
export const GAME_CENTER_NEW_MS = 1000;

/** Game Center's key hosts and names: its production and sandbox keys,
 *  gc-prod-N and gc-sb-N (G32). */
const KEY_HOSTS = new Set(["static.gc.apple.com", "sandbox.gc.apple.com"]);
const KEY_NAME = /^\/public-key\/gc-(prod|sb)-\d{1,4}\.cer$/;

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
    this.lastNew = -Infinity;
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

  async prepare(credential) {
    const url = credential?.publicKeyUrl;
    if (!GameCenter.trustedUrl(url)) return;
    const now = this.now();
    const known = this.certificates.get(url);
    if (known) {
      // Recently used: to the back of the queue.
      this.certificates.delete(url);
      this.certificates.set(url, known);
      return;
    }
    const failed = this.failures.get(url);
    if (failed !== undefined && now - failed < GAME_CENTER_RETRY_MS) return;
    if (now - this.lastNew < GAME_CENTER_NEW_MS) return;
    this.lastNew = now;
    let cert = null;
    try {
      cert = new X509Certificate(await this.fetchCertificate(url));
    } catch {
      // An unreachable or unreadable certificate proves nothing; verify refuses.
    }
    const keep = (map, key, value, most) => {
      map.delete(key);
      map.set(key, value);
      while (map.size > most) map.delete(map.keys().next().value);
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
    const cert = this.certificates.get(publicKeyUrl)?.cert;
    if (!cert || !verifyChain([cert], this.roots, now)) return null;
    // The pinned CA sells certificates to anyone; the key must be Apple's.
    if (!cert.subject.split("\n").includes(`O=${this.organization}`)) return null;
    const stamp = Buffer.alloc(8);
    stamp.writeBigUInt64BE(BigInt(timestamp));
    const payload = Buffer.concat([Buffer.from(playerId, "utf8"), Buffer.from(bundleId, "utf8"),
                                   stamp, Buffer.from(String(salt ?? ""), "base64")]);
    const check = createVerify("RSA-SHA256");
    check.update(payload);
    return check.verify(cert.publicKey, Buffer.from(String(signature ?? ""), "base64")) ? `gc:${playerId}` : null;
  }
}
