// §24.8: "No passwords. Platform identity is exchanged for a short-lived
// signed token."
//
// A token is `account.expiry.signature`, the signature an HMAC-SHA256 of the
// first two over a server secret. Checking one needs no database read.
//
// What is not here: checking the platform identity itself — a Game Center or
// Play Games credential — needs Apple's and Google's services and a real
// device, so the service takes a `verifyPlatform` function, and the tests
// give it a fake one. That is the one seam between this server and the
// stores.

import { createHmac, timingSafeEqual } from "node:crypto";

/** How long a session lasts. The document says "short-lived" and no more. */
export const SESSION_MS = 60 * 60 * 1000;

const sign = (secret, body) => createHmac("sha256", secret).update(body).digest("base64url");

export function issue(secret, account, now) {
  const body = `${account}.${now + SESSION_MS}`;
  return `${body}.${sign(secret, body)}`;
}

/** The account a token names, or null if it is forged, malformed or stale. */
export function check(secret, token, now) {
  if (typeof token !== "string") return null;
  const cut = token.lastIndexOf(".");
  if (cut < 0) return null;
  const body = token.slice(0, cut);
  const given = Buffer.from(token.slice(cut + 1));
  const expected = Buffer.from(sign(secret, body));
  if (given.length !== expected.length || !timingSafeEqual(given, expected)) return null;
  const [account, expiry] = body.split(".");
  if (!account || !(Number(expiry) > now)) return null;
  return account;
}
