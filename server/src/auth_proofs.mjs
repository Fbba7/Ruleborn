// §24.8's platform proofs, made single-use.
//
// stores.mjs checks that Apple or Google signed a proof: Game Center's
// signature with Apple's key over the player, the app, a timestamp and a
// salt, at most five minutes old; Google's ID token against Google's keys,
// for this app, in date with five minutes of skew. A signature alone can be
// sent twice, by whoever saw it go by. So here, around those checks:
//
//   - a Game Center proof is accepted once: its player, salt and timestamp
//     are spent until the five minutes it could be accepted in are over;
//   - a Google ID token must carry a nonce this server made (POST
//     /v1/session/nonce, or the web deletion page), at most five minutes
//     old, and the nonce is spent with it.
//
// `verify(credential, once)` takes `once` from the service: `spend(key,
// until)` and `spendNonce(nonce)` (auth.mjs), and `expectNonce`, the one
// nonce a web page's cookie holds (CSRF: the token must be the one the page
// asked for), with `audience` and `freshMs` (that page's client id alone,
// issued minutes ago, T12's SR-11). With no `once` a real proof is
// refused: the check that makes it single-use is never skipped by
// omission. The stubbed sign-in of a local server (stores.mjs signIn) is
// passed through as it was.

import { timingSafeEqual } from "node:crypto";

import { GAME_CENTER_FRESH_MS, signIn } from "./stores.mjs";

const b64url = (s) => Buffer.from(String(s).replace(/-/g, "+").replace(/_/g, "/"), "base64");

/** Equal in constant time. */
function same(a, b) {
  const x = Buffer.from(String(a));
  const y = Buffer.from(String(b));
  return x.length === y.length && timingSafeEqual(x, y);
}

/** The claims of an ID token whose signature stores.mjs has checked. */
function claims(idToken) {
  try {
    return JSON.parse(b64url(String(idToken).split(".")[1]).toString("utf8"));
  } catch {
    return null;
  }
}

export function platformProofs({ gameCenter = null, google = null } = {}) {
  const inner = signIn({ gameCenter, google });
  return {
    stubbed: inner.stubbed,
    prepare: inner.prepare,
    verify(credential, once = null) {
      const identity = inner.verify(credential);
      if (!identity || inner.stubbed) return identity;
      if (!once) return null;
      if (identity.startsWith("gc:")) {
        const { playerId, salt, timestamp } = credential;
        // By the salt's bytes, as Apple signed them: base64 has many
        // spellings of one salt (T12's SR-25).
        const key = `gc|${playerId}|${Buffer.from(String(salt ?? ""), "base64").toString("base64")}|${timestamp}`;
        return once.spend(key, timestamp + GAME_CENTER_FRESH_MS) ? identity : null;
      }
      if (identity.startsWith("gp:")) {
        const c = claims(credential.idToken) ?? {};
        const nonce = c.nonce;
        if (typeof nonce !== "string" || (once.expectNonce != null && !same(nonce, once.expectNonce))) return null;
        if (once.audience != null && c.aud !== once.audience) return null;
        if (once.freshMs != null && !(Number(c.iat) * 1000 >= once.now - once.freshMs)) return null;
        return once.spendNonce(nonce) ? identity : null;
      }
      return null;
    },
  };
}
