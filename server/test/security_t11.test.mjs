// Security review findings in sign-in and session code, which the auth work
// (T11) owns (docs/security/review.md, "Sent to T11"). T12 pinned each as it
// stood; the fixes turned the assertions round.

import assert from "node:assert/strict";
import { X509Certificate, createPrivateKey, createSign, generateKeyPairSync, sign } from "node:crypto";
import { readFileSync } from "node:fs";
import { test } from "node:test";

import { DELETE_COOKIE } from "../src/auth_http.mjs";
import { platformProofs } from "../src/auth_proofs.mjs";
import { handler } from "../src/http.mjs";
import { GAME_CENTER_CACHE, GameCenter, GoogleSignIn } from "../src/stores.mjs";
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

// SR-20: Game Center's keys are fetched at most one new URL a second into a
// cache of GAME_CENTER_CACHE, and the names are Apple's own, so a caller
// naming one after another pushed out the key in use and the next real
// sign-in waited on the fetch the caller kept taking. Now a key that has
// verified a real signature goes only after every key not yet proven.
test("SR-20 (T11, fixed): a caller cycling through Apple's key names cannot push out the key players sign in with", async () => {
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
             salt: salt.toString("base64"),
             signature: signer.sign(createPrivateKey(fixture("gamecenter.key"))).toString("base64") };
  };
  await gc.prepare(identity());
  assert.equal(gc.verify(identity()), "gc:T:_player1");
  for (let i = 1; i <= 3 * GAME_CENTER_CACHE; i++) {
    clock.now += 1000;
    await gc.prepare({ publicKeyUrl: `https://static.gc.apple.com/public-key/gc-prod-${10 + i}.cer` });
  }
  assert.ok(gc.certificates.size <= GAME_CENTER_CACHE, "the cache keeps its size");
  await gc.prepare(identity());
  assert.equal(gc.verify(identity()), "gc:T:_player1", "the player still signs in, with no fetch to wait for");
});
