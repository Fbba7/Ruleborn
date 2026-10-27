// Security review findings in sign-in and session code, which the auth work
// (T11) owns: each test pins the behaviour as it stands, so it passes, and
// the fix turns its assertion round (docs/security/review.md, "Sent to T11").

import assert from "node:assert/strict";
import { X509Certificate, createPrivateKey, createSign, generateKeyPairSync, sign } from "node:crypto";
import { readFileSync } from "node:fs";
import { test } from "node:test";

import { handler } from "../src/http.mjs";
import { GAME_CENTER_CACHE, GameCenter, GoogleSignIn, signIn } from "../src/stores.mjs";
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

// SR-20: Game Center's keys are fetched at most one new URL a second, the
// server's whole, into a cache of GAME_CENTER_CACHE. The names are Apple's
// own (gc-prod-N), so every one a caller names that Apple serves is kept and
// pushes out the key in use; the next real sign-in then waits for the one
// fetch a second the same caller keeps taking.
test("SR-20 (sent to T11): a caller cycling through Apple's key names pushes out the key in use, and holds the one fetch a second", async () => {
  const fixture = (name) => readFileSync(new URL(`./fixtures/apple/${name}`, import.meta.url));
  const cert = (name) => new X509Certificate(fixture(`${name}.pem`));
  const [ROOT, INTERMEDIATE, GAMECENTER] = [cert("root"), cert("intermediate"), cert("gamecenter")];
  const BUNDLE = "com.example.ruleborn";
  const URL_ = "https://static.gc.apple.com/public-key/gc-prod-6.cer";
  const clock = { now: Date.parse(ROOT.validFrom) + 24 * 60 * 60 * 1000 };
  // Apple serving a certificate at each of its names, as it does for the keys it has used.
  const gc = new GameCenter({ roots: [INTERMEDIATE, ROOT], bundleId: BUNDLE, now: () => clock.now,
                              fetchCertificate: async () => GAMECENTER.raw });
  const identity = () => {
    const salt = Buffer.from("0123456789abcdef");
    const stamp = Buffer.alloc(8);
    stamp.writeBigUInt64BE(BigInt(clock.now));
    const signer = createSign("RSA-SHA256");
    signer.update(Buffer.concat([Buffer.from("T:_player1"), Buffer.from(BUNDLE), stamp, salt]));
    return { playerId: "T:_player1", bundleId: BUNDLE, timestamp: clock.now, publicKeyUrl: URL_,
             salt: salt.toString("base64"), signature: signer.sign(createPrivateKey(fixture("gamecenter.key"))).toString("base64") };
  };
  await gc.prepare(identity());
  assert.equal(gc.verify(identity()), "gc:T:_player1");
  for (let i = 1; i <= GAME_CENTER_CACHE; i++) {
    clock.now += 1000;
    await gc.prepare({ publicKeyUrl: `https://static.gc.apple.com/public-key/gc-prod-${10 + i}.cer` });
  }
  clock.now += 1000;
  await gc.prepare({ publicKeyUrl: "https://static.gc.apple.com/public-key/gc-prod-99.cer" });
  await gc.prepare(identity());
  assert.equal(gc.verify(identity()), null, "the player's sign-in fails while the caller keeps it up");
});
