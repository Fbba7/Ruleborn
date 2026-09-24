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
// The root is configuration, not code: the operator pins Apple's root
// certificate (Apple Root CA G3), and the tests pin a stand-in. Fetching
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

/** A StoreKit 2 signed transaction, checked; null if it is not Apple's. */
export function appStoreTransaction(jws, { roots, bundleId, now }) {
  const parts = String(jws).split(".");
  if (parts.length !== 3) return null;
  let header;
  let payload;
  try {
    header = JSON.parse(b64url(parts[0]).toString("utf8"));
    payload = JSON.parse(b64url(parts[1]).toString("utf8"));
  } catch {
    return null;
  }
  if (header.alg !== "ES256" || !Array.isArray(header.x5c)) return null;
  const leaf = verifyChain(header.x5c.map((c) => Buffer.from(c, "base64")), roots, now);
  if (!leaf) return null;
  const signed = Buffer.from(`${parts[0]}.${parts[1]}`);
  const ok = verifySignature("sha256", signed, { key: leaf.publicKey, dsaEncoding: "ieee-p1363" },
                             b64url(parts[2]));
  if (!ok || payload.bundleId !== bundleId || payload.revocationDate) return null;
  return {
    transaction: String(payload.transactionId),
    product: payload.productId,
    intent: payload.appAccountToken ?? null,
  };
}

/**
 * Game Center's identity verification. `fetchCertificate(url)` is the one
 * network call; `prepare` makes it and caches the answer, so `verify` —
 * which the service calls synchronously — needs none.
 */
export class GameCenter {
  constructor({ roots, bundleId, fetchCertificate, now = () => Date.now() }) {
    Object.assign(this, { roots, bundleId, fetchCertificate, now });
    this.certificates = new Map();
  }

  /** Only Apple's own servers publish the key (G32). */
  static trustedUrl(url) {
    try {
      const u = new URL(url);
      return u.protocol === "https:" && (u.hostname === "apple.com" || u.hostname.endsWith(".apple.com"));
    } catch {
      return false;
    }
  }

  async prepare(credential) {
    const url = credential?.publicKeyUrl;
    if (!GameCenter.trustedUrl(url) || this.certificates.has(url)) return;
    try {
      this.certificates.set(url, new X509Certificate(await this.fetchCertificate(url)));
    } catch {
      // An unreachable or unreadable certificate proves nothing; verify refuses.
    }
  }

  /** The platform identity a credential proves, or null. */
  verify(credential) {
    const { playerId, bundleId, publicKeyUrl, signature, salt, timestamp } = credential ?? {};
    if (typeof playerId !== "string" || !playerId || bundleId !== this.bundleId) return null;
    if (!GameCenter.trustedUrl(publicKeyUrl) || !Number.isSafeInteger(timestamp)) return null;
    const now = this.now();
    if (Math.abs(now - timestamp) > GAME_CENTER_FRESH_MS) return null;
    const cert = this.certificates.get(publicKeyUrl);
    if (!cert || !verifyChain([cert], this.roots, now)) return null;
    const stamp = Buffer.alloc(8);
    stamp.writeBigUInt64BE(BigInt(timestamp));
    const payload = Buffer.concat([Buffer.from(playerId, "utf8"), Buffer.from(bundleId, "utf8"),
                                   stamp, Buffer.from(String(salt ?? ""), "base64")]);
    const check = createVerify("RSA-SHA256");
    check.update(payload);
    return check.verify(cert.publicKey, Buffer.from(String(signature ?? ""), "base64")) ? `gc:${playerId}` : null;
  }
}
