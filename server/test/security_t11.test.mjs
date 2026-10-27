// Security review findings in sign-in and session code, which the auth work
// (T11) owns: each test pins the behaviour as it stands, so it passes, and
// the fix turns its assertion round (docs/security/review.md, "Sent to T11").

import assert from "node:assert/strict";
import { generateKeyPairSync, sign } from "node:crypto";
import { test } from "node:test";

import { handler } from "../src/http.mjs";
import { GoogleSignIn, signIn } from "../src/stores.mjs";
import { T0, server } from "./setup.mjs";

const ANDROID = "android-game.apps.googleusercontent.com";
const WEB = "web-page.apps.googleusercontent.com";
const b64url = (b) => Buffer.from(b).toString("base64url");

// SR-11: G39's deletion takes any Google ID token for any of the server's
// client ids — the one the game signs in with too — with no nonce from the
// page and no second step.
test("SR-11 (sent to T11): the ID token the game signs in with also deletes the account from the web", async () => {
  const pair = generateKeyPairSync("rsa", { modulusLength: 2048 });
  const jwk = { ...pair.publicKey.export({ format: "jwk" }), kid: "k1", alg: "RS256", use: "sig" };
  const now = Math.floor(T0 / 1000);
  const head = b64url(JSON.stringify({ alg: "RS256", kid: "k1", typ: "JWT" }));
  const body = b64url(JSON.stringify({ iss: "https://accounts.google.com", aud: ANDROID, sub: "1234567890",
                                       iat: now - 60, exp: now + 3540 }));
  const idToken = `${head}.${body}.${b64url(sign("sha256", Buffer.from(`${head}.${body}`), pair.privateKey))}`;
  const google = new GoogleSignIn({ clientIds: [ANDROID, WEB], now: () => T0,
                                    fetchKeys: async () => ({ keys: [jwk] }) });
  const platforms = signIn({ google });
  const t = server({ verifyPlatform: platforms.verify, preparePlatform: platforms.prepare });
  const web = handler(t.service, { webClientId: WEB });
  const post = (path, json) => web(new Request(`https://edge.example${path}`, {
    method: "POST", headers: { "content-type": "application/json" }, body: JSON.stringify(json) }));

  const signed = await post("/v1/session", { credential: { idToken } });
  assert.equal(signed.status, 200, "the game's own sign-in");
  const deleted = await post("/v1/account/delete", { idToken });
  assert.equal(deleted.status, 200, "the same token, an Android client's, deletes the account at once");
  assert.equal((await deleted.json()).deleted, true);
});
