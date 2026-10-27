// The session's routes, and the web deletion page's sign-in (docs/security/auth.md).
//
//   POST /v1/session          {"credential"}                 → {account, token, expiresIn, refreshToken}
//   POST /v1/session/nonce                                   → {nonce, expiresIn}: for a Google ID token to carry
//   POST /v1/session/refresh  {"refreshToken"}               → a new pair; the one sent is spent
//   POST /v1/session/end      {"everywhere"?, "refreshToken"?} → {ended}: this session, or every one
//   GET  /v1/session                                         → {account, devices}: sessions live
//   GET  /account/delete                                     → G39's page, with a nonce in a cookie
//   POST /v1/account/delete   {"idToken", "withdrawIslands"} → the account deleted (§20.5, §20.11)
//
// Everything a session route answers is `Cache-Control: no-store`: a token
// is never kept by a cache between the device and the server. No token is
// ever in a URL, and nothing here logs one.

import { readFileSync } from "node:fs";

import { deleteAccount } from "./accounts.mjs";
import { PAGE_HEADERS, hashOf } from "./pages.mjs";
import { Refused } from "./refused.mjs";
import { NONCE_MS, peekRefresh } from "./tokens.mjs";

/** G39's page, with the web OAuth client id and nonces put in (server/web/). */
const DELETE_PAGE = readFileSync(new URL("../web/delete.html", import.meta.url), "utf8");
/** The page's own script, by its hash: the one inline script its policy runs. */
const DELETE_SCRIPT = hashOf(/<script>([\s\S]*?)<\/script>/.exec(DELETE_PAGE)[1]);
/** The cookie the page's nonce rides in: `__Host-` so only this host, over
 *  HTTPS, at `/`, can have set it. */
export const DELETE_COOKIE = "__Host-rb_delete";

const answer = (body, status = 200) => new Response(JSON.stringify(body), {
  status, headers: { "content-type": "application/json", "cache-control": "no-store", pragma: "no-cache" },
});

const bearer = (request) => {
  const h = request.headers.get("authorization") ?? "";
  return h.startsWith("Bearer ") ? h.slice(7) : "";
};

/** A cookie's value from the request, or null. */
export function cookie(request, name) {
  for (const part of (request.headers.get("cookie") ?? "").split(";")) {
    const cut = part.indexOf("=");
    if (cut > 0 && part.slice(0, cut).trim() === name) return part.slice(cut + 1).trim();
  }
  return null;
}

/**
 * `/v1/session…`. `signIn(proceed)` is the edge's gate on sign-ins (an
 * address held back after failures, an account's sign-ins limited, a
 * failure counted), `limit(kind, key)` its buckets, `read(request)` a
 * JSON body and `optional(request)` one that may be absent.
 */
export async function sessionRoute(service, request, parts, { signIn, limit, read, optional }) {
  const m = request.method;
  const [, , verb] = parts;
  if (m === "POST" && !verb) {
    return signIn(async (admit) => {
      const { credential } = await read(request);
      await service.preparePlatform(credential);
      return answer(service.session(credential, { admit }));
    });
  }
  if (m === "POST" && verb === "nonce") {
    // Signed, not stored: asking for one writes nothing (tokens.mjs).
    return signIn(async () => answer(service.auth.nonce()));
  }
  if (m === "POST" && verb === "refresh") {
    return signIn(async (admit) => {
      const { refreshToken } = await read(request);
      const peek = peekRefresh(refreshToken);
      if (!peek) throw new Refused(401, "session_refused");
      // §24.1's sign-ins an account, held by the session the token names
      // before anything is read.
      admit(`session:${peek.session}`);
      return answer(service.auth.refresh(refreshToken));
    });
  }
  if (m === "POST" && verb === "end") {
    const { everywhere = false, refreshToken = null } = await optional(request);
    if (typeof everywhere !== "boolean") throw new Refused(400, "malformed_body");
    const token = bearer(request);
    if (token) {
      limit("calls", service.auth.holder(token).account);
      return answer({ ended: service.auth.signOut(token, { everywhere }) });
    }
    // An access token past its hour: the refresh token proves the session.
    return signIn(async () => answer({ ended: service.auth.signOutWith(refreshToken, { everywhere }) }));
  }
  if (m === "GET" && !verb) {
    const token = bearer(request);
    limit("calls", service.auth.holder(token).account);
    const account = service.account(token);
    return answer({ account, devices: service.auth.live(account) });
  }
  return answer({ error: "no_such_route" }, 404);
}

/**
 * G39's page. Each serving draws a nonce for Google to sign into the ID
 * token, kept in a cookie only this host can set and no script can read.
 * No script runs on it but its own, by hash, and Google's sign-in. Google's
 * script sets inline styles and draws its logo from a data: image, so
 * styles take 'unsafe-inline', and only styles (T12's SR-04, checked in
 * Chromium). Each value is put in by a function, so a `$` in it is never a
 * pattern.
 */
export function deletePage(service, webClientId) {
  const { nonce } = service.auth.nonce();
  const page = DELETE_PAGE.replaceAll("{{WEB_CLIENT_ID}}", () => webClientId)
    .replaceAll("{{NONCE}}", () => nonce);
  return new Response(page, { headers: {
    "content-type": "text/html; charset=utf-8",
    "cache-control": "no-store",
    ...PAGE_HEADERS,
    "x-frame-options": "DENY",
    "content-security-policy": [
      "default-src 'none'",
      `script-src ${DELETE_SCRIPT} https://accounts.google.com/gsi/client`,
      "style-src 'unsafe-inline' https://accounts.google.com/gsi/style",
      "frame-src https://accounts.google.com/gsi/",
      "connect-src 'self' https://accounts.google.com/gsi/",
      "img-src data: https://*.googleusercontent.com",
      "base-uri 'none'",
      "form-action 'none'",
      "frame-ancestors 'none'",
    ].join("; "),
    "set-cookie": `${DELETE_COOKIE}=${nonce}; Path=/; Max-Age=${Math.floor(NONCE_MS / 1000)}; Secure; HttpOnly; SameSite=Strict`,
  } });
}

/**
 * G39's deletion without the app, proven with Sign in with Google: the
 * Google ID token names the account as gp:<sub>, the Android game's own
 * identity, and must carry the nonce in this browser's cookie — the page
 * this server served it — once. A request another site's page made is
 * refused before anything is read: a foreign Origin, a cross-site fetch, or
 * a body that is not JSON (which no form can send without CORS's leave).
 */
export async function deleteByGoogle(service, request, { signIn, read, webClientId = null }) {
  const own = new URL(request.url).origin;
  const origin = request.headers.get("origin");
  const site = request.headers.get("sec-fetch-site");
  if ((origin !== null && origin !== own) || (site !== null && !["same-origin", "none"].includes(site))) {
    throw new Refused(403, "cross_site");
  }
  if (!(request.headers.get("content-type") ?? "").toLowerCase().startsWith("application/json")) {
    throw new Refused(415, "json_only");
  }
  return signIn(async (admit) => {
    const { idToken, withdrawIslands = false } = await read(request);
    if (typeof idToken !== "string") throw new Refused(400, "malformed_body");
    const credential = { idToken };
    await service.preparePlatform(credential);
    // T12's SR-11: a token the game signs in with deletes nothing here —
    // only one minted for the web client, minutes ago, carrying this
    // browser's nonce.
    const identity = service.auth.prove(credential, { expectNonce: cookie(request, DELETE_COOKIE) ?? "",
                                                      audience: webClientId, freshMs: NONCE_MS });
    if (typeof identity !== "string" || !identity.startsWith("gp:")) {
      throw new Refused(401, "google_identity_refused");
    }
    admit(identity);
    const row = service.db.prepare("SELECT id FROM accounts WHERE platform_identity = ?").get(identity);
    if (!row) throw new Refused(404, "no_such_account");
    const done = answer({ deleted: true, reason: deleteAccount(service, row.id, "requested",
                                                               { withdraw: withdrawIslands }).reason });
    done.headers.set("set-cookie", `${DELETE_COOKIE}=; Path=/; Max-Age=0; Secure; HttpOnly; SameSite=Strict`);
    return done;
  });
}
