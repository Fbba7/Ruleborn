// §24.8's platform proofs through the service, with the real verifiers:
// Game Center against the stand-in Apple chain (fixtures/apple), Google
// against keys this test makes. Every rejection path, and each proof
// good once.

import assert from "node:assert/strict";
import { generateKeyPairSync } from "node:crypto";
import { test } from "node:test";

import { platformProofs } from "../src/auth_proofs.mjs";
import { GAME_CENTER_FRESH_MS, GOOGLE_SKEW_MS } from "../src/stores.mjs";
import { NONCE_MS } from "../src/tokens.mjs";
import { CLIENT, DEVELOPER, GC_URL, NOW, b64url, gc, real } from "./auth_fixtures.mjs";

async function refused(r, credential) {
  await assert.rejects(r.signIn(credential), (e) => e.reason === "platform_identity_refused" && e.status === 401);
}

test("a Game Center proof signs in once: the same salt and timestamp again is a replay (24.8)", async () => {
  const r = real();
  const first = await r.signIn(gc());
  assert.ok(r.t.service.account(first.token));
  await refused(r, gc());
  // A new signature — a new salt — from the same player is a new sign-in.
  const again = await r.signIn(gc({ salt: "salt-0002" }));
  assert.equal(again.account, first.account);
  // The same salt at another moment is another proof.
  r.clock.now += 1000;
  assert.equal((await r.signIn(gc({ salt: "salt-0001", timestamp: r.clock.now }))).account, first.account);
});

test("a Game Center proof is refused: stale, from the future, another app, another key, not Apple's host or not HTTPS", async () => {
  const r = real();
  const cases = {
    "six minutes old": gc({ timestamp: NOW - GAME_CENTER_FRESH_MS - 60_000 }),
    "six minutes ahead": gc({ timestamp: NOW + GAME_CENTER_FRESH_MS + 60_000 }),
    "another app's": gc({ bundleId: "com.other.app" }),
    "signed by a key that is not the certificate's": gc({ key: "developer.key" }),
    "a key from elsewhere": gc({ url: "https://gc.example.com/public-key/gc-prod-6.cer" }),
    "a key over HTTP": gc({ url: "http://static.gc.apple.com/public-key/gc-prod-6.cer" }),
    "a key URL with a query": gc({ url: `${GC_URL}?x=1` }),
    "a key on another port": gc({ url: "https://static.gc.apple.com:8443/public-key/gc-prod-6.cer" }),
    "no player": gc({ playerId: "" }),
  };
  for (const [why, credential] of Object.entries(cases)) {
    await assert.rejects(r.signIn(credential), (e) => e.reason === "platform_identity_refused", why);
  }
  const altered = { ...gc({ salt: "salt-9" }), playerId: "T:_someone_else" };
  await refused(r, altered);
  assert.deepEqual([...new Set(r.fetched)], [GC_URL], "only Apple's host was ever asked");
  // Inside the five minutes, either side, is accepted.
  assert.ok(await r.signIn(gc({ timestamp: NOW - GAME_CENTER_FRESH_MS + 1000, salt: "edge-1" })));
  assert.ok(await r.signIn(gc({ timestamp: NOW + GAME_CENTER_FRESH_MS - 1000, salt: "edge-2" })));
});

test("a Game Center key that does not chain to the pinned root, or is not Apple's, proves nothing", async () => {
  const r = real({ fetchCertificate: async () => DEVELOPER.raw });
  await refused(r, gc({ key: "developer.key" }));
});

test("a Google ID token signs in once, with the server's nonce, for the app, in date with five minutes of skew (24.8)", async () => {
  const r = real();
  const nonce = () => r.t.service.auth.nonce().nonce;
  const n = nonce();
  const first = await r.signIn({ idToken: r.idToken({ nonce: n }) });
  assert.ok(r.t.service.account(first.token));
  await refused(r, { idToken: r.idToken({ nonce: n }) });
  const s = Math.floor(NOW / 1000);
  const cases = {
    "no nonce": r.idToken(),
    "a nonce the server never made": r.idToken({ nonce: "n1.k0.abcdef0123456789.9999999999999.AAAA" }),
    "a nonce of the right shape, forged": r.idToken({ nonce: nonce().replace(/.{4}$/, "AAAA") }),
    "another app's audience": r.idToken({ nonce: nonce(), aud: "someone-else.apps.googleusercontent.com" }),
    "another issuer": r.idToken({ nonce: nonce(), iss: "https://evil.example" }),
    "expired past the skew": r.idToken({ nonce: nonce(), exp: s - GOOGLE_SKEW_MS / 1000 - 1 }),
    "issued past the skew ahead": r.idToken({ nonce: nonce(), iat: s + GOOGLE_SKEW_MS / 1000 + 60 }),
    "another key": r.idToken({ nonce: nonce() }, { key: generateKeyPairSync("rsa", { modulusLength: 2048 }).privateKey }),
    "HS256": r.idToken({ nonce: nonce() }, { alg: "HS256" }),
    "alg none": (() => {
      const head = b64url(JSON.stringify({ alg: "none", kid: "g1" }));
      const body = b64url(JSON.stringify({ iss: "accounts.google.com", aud: CLIENT, sub: "1", iat: s, exp: s + 60, nonce: nonce() }));
      return `${head}.${body}.`;
    })(),
    "a subject that is not Google's": r.idToken({ nonce: nonce(), sub: "gc:T:_player1" }),
  };
  for (const [why, idToken] of Object.entries(cases)) {
    await assert.rejects(r.signIn({ idToken }), (e) => e.reason === "platform_identity_refused", why);
  }
  // Inside the skew: expired four minutes ago is still accepted.
  assert.ok(await r.signIn({ idToken: r.idToken({ nonce: nonce(), exp: s - 4 * 60 }) }));
  // A nonce past its five minutes.
  const old = nonce();
  r.clock.now += NONCE_MS + 1;
  await refused(r, { idToken: r.idToken({ nonce: old }) });
});

test("a nonce refused does not spend it, and a token refused for its audience does not spend its nonce", async () => {
  const r = real();
  const n = r.t.service.auth.nonce().nonce;
  await refused(r, { idToken: r.idToken({ nonce: n, aud: "nobody" }) });
  assert.ok(await r.signIn({ idToken: r.idToken({ nonce: n }) }), "the nonce is still good for the real token");
});

test("a real proof checked with nothing to spend it is refused: single use is never skipped by omission", async () => {
  const r = real();
  await r.t.service.preparePlatform(gc());
  assert.equal(r.proofs.verify(gc()), null);
  assert.equal(r.proofs.verify(gc(), {
    spend: () => true, spendNonce: () => true }), "gc:T:_player1");
  const stub = platformProofs({});
  assert.equal(stub.stubbed, true);
  assert.equal(stub.verify("gc:local"), "gc:local", "a local server's stub is as it was");
});

test("a Google token never proves a Game Center identity, nor the other way round (platform switch)", async () => {
  const r = real();
  const apple = await r.signIn(gc());
  const google = await r.signIn({ idToken: r.idToken({ nonce: r.t.service.auth.nonce().nonce }) });
  assert.notEqual(apple.account, google.account, "two identities, two accounts: no linking by sign-in");
  const row = (a) => r.t.service.db.prepare("SELECT platform_identity FROM accounts WHERE id = ?").get(a).platform_identity;
  assert.deepEqual([row(apple.account), row(google.account)], ["gc:T:_player1", "gp:1098765432101234567"]);
});
