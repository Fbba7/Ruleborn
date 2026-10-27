// Security review findings in sign-in and session code, which the auth work
// (T11) owns (docs/security/review.md, "Sent to T11"). T12 pinned each as it
// stood; the fixes turned the assertions round.

import assert from "node:assert/strict";
import { generateKeyPairSync, sign } from "node:crypto";
import { readFileSync } from "node:fs";
import { test } from "node:test";

import { DELETE_COOKIE } from "../src/auth_http.mjs";
import { platformProofs } from "../src/auth_proofs.mjs";
import { handler } from "../src/http.mjs";
import { GoogleSignIn } from "../src/stores.mjs";
import { T0, server } from "./setup.mjs";

const ANDROID = "android-game.apps.googleusercontent.com";
const WEB = "web-page.apps.googleusercontent.com";
const b64url = (b) => Buffer.from(b).toString("base64url");

// SR-11: G39's deletion took any Google ID token for any of the server's
// client ids — the one the game signs in with too — with no nonce from the
// page and no second step. Now: the game's token signs the game in and
// deletes nothing; only a token minted for the web client, minutes ago,
// carrying the nonce in this browser's cookie, deletes, and only once.
test("SR-11 (T11, fixed): the ID token the game signs in with deletes nothing from the web", async () => {
  const pair = generateKeyPairSync("rsa", { modulusLength: 2048 });
  const jwk = { ...pair.publicKey.export({ format: "jwk" }), kid: "k1", alg: "RS256", use: "sig" };
  const now = Math.floor(T0 / 1000);
  const token = (claims) => {
    const head = b64url(JSON.stringify({ alg: "RS256", kid: "k1", typ: "JWT" }));
    const body = b64url(JSON.stringify({ iss: "https://accounts.google.com", sub: "1234567890",
                                         iat: now - 60, exp: now + 3540, ...claims }));
    return `${head}.${body}.${b64url(sign("sha256", Buffer.from(`${head}.${body}`), pair.privateKey))}`;
  };
  const google = new GoogleSignIn({ clientIds: [ANDROID, WEB], now: () => T0,
                                    fetchKeys: async () => ({ keys: [jwk] }) });
  // The server's own wiring: each proof single-use (main.mjs).
  const platforms = platformProofs({ google });
  const t = server({ verifyPlatform: platforms.verify, preparePlatform: platforms.prepare });
  const web = handler(t.service, { webClientId: WEB });
  const post = (path, json, cookie = null) => web(new Request(`https://edge.example${path}`, {
    method: "POST", headers: { "content-type": "application/json", ...(cookie ? { cookie } : {}) },
    body: JSON.stringify(json) }));

  const game = token({ aud: ANDROID, nonce: t.service.auth.nonce().nonce });
  const signed = await post("/v1/session", { credential: { idToken: game } });
  assert.equal(signed.status, 200, "the game's own sign-in");
  const refused = await post("/v1/account/delete", { idToken: game });
  assert.equal(refused.status, 401, "the game's token deletes nothing");
  const page = await web(new Request("https://edge.example/account/delete"));
  const nonce = /data-nonce="([^"]+)"/.exec(await page.text())[1];
  const cookie = `${DELETE_COOKIE}=${nonce}`;
  assert.equal((await post("/v1/account/delete", { idToken: token({ aud: ANDROID, nonce }) }, cookie)).status, 401,
               "nor does a game token carrying the page's nonce");
  const deleted = await post("/v1/account/delete", { idToken: token({ aud: WEB, nonce }) }, cookie);
  assert.equal(deleted.status, 200, "the page's own token does");
  assert.equal((await deleted.json()).deleted, true);
  // And the server is wired with the proofs that make all this so.
  const main = readFileSync(new URL("../src/main.mjs", import.meta.url), "utf8");
  assert.match(main, /const platforms = platformProofs\(\{ gameCenter, google \}\);/);
  assert.match(main, /verifyPlatform: platforms\.verify,/);
});

// "What sign-out has to do": a session ended on the server before its hour.
test("Sign-out (T11, built): a session token is refused the moment its session is signed out", async () => {
  const t = server();
  const s = t.service.session("gc:leaving");
  const ask = (token) => t.handle(new Request("https://edge.example/v1/balance",
                                               { headers: { authorization: `Bearer ${token}` } }));
  assert.equal((await ask(s.token)).status, 200);
  const out = await t.handle(new Request("https://edge.example/v1/session/end", {
    method: "POST", headers: { authorization: `Bearer ${s.token}` } }));
  assert.equal(out.status, 200);
  assert.equal((await ask(s.token)).status, 401, "well inside its hour");
});
