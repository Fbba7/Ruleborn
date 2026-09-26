// Google's proofs (§24.8, §22.1): Play Billing purchases signed with the
// app's licence key, and "Sign in with Google" ID tokens signed with keys
// Google publishes — checked against keys this test makes for itself.

import assert from "node:assert/strict";
import { generateKeyPairSync, sign, verify } from "node:crypto";
import { test } from "node:test";

import { ANDROID_PUBLISHER, PlayPurchases, ServiceAccount } from "../src/googleapi.mjs";
import { GOOGLE_KEYS_COLD_RETRY_MS, GOOGLE_KEYS_RETRY_MS, GoogleSignIn, playPurchase, receipts, signIn } from "../src/stores.mjs";
import { server } from "./setup.mjs";

const PACKAGE = "com.example.ruleborn";
const CLIENT = "123-server.apps.googleusercontent.com";
const rsa = () => generateKeyPairSync("rsa", { modulusLength: 2048 });
const LICENCE = rsa();
const STRANGER = rsa();
const b64url = (b) => Buffer.from(b).toString("base64url");

/** A Play Billing purchase as Play returns it: its JSON and a signature. */
function purchase(extra = {}, key = LICENCE.privateKey) {
  const data = JSON.stringify({ orderId: "GPA.3300-1111-2222-33333", packageName: PACKAGE,
    productId: "premium.1", purchaseTime: 1790000000000, purchaseState: 0,
    purchaseToken: "token-abc", quantity: 1, acknowledged: false, ...extra });
  return { data, signature: sign("sha1", Buffer.from(data), key).toString("base64") };
}
const play = { licenceKey: LICENCE.publicKey, packageName: PACKAGE };

test("a Play purchase counts only as the app's licence key signed it, for this app, bought and paid (22.1)", () => {
  assert.deepEqual(playPurchase(purchase({ obfuscatedAccountId: "intent-1" }), play),
                   { transaction: "token-abc", product: "premium.1", intent: "intent-1" });
  assert.deepEqual(playPurchase(purchase(), play).intent, null);
  const signed = purchase();
  const forged = { data: signed.data.replace("premium.1", "premium.2"), signature: signed.signature };
  assert.equal(playPurchase(forged, play), null, "a changed product breaks the signature");
  assert.equal(playPurchase(purchase({}, STRANGER.privateKey), play), null, "another key");
  assert.equal(playPurchase(purchase({ packageName: "com.other" }), play), null, "another app's");
  assert.equal(playPurchase(purchase({ purchaseState: 4 }), play), null, "pending: not yet charged");
  assert.equal(playPurchase(purchase({ purchaseState: 1 }), play), null, "cancelled");
  assert.equal(playPurchase(purchase({ quantity: 2 }), play), null, "one item a purchase");
  assert.equal(playPurchase(purchase({ purchaseToken: "" }), play), null);
  assert.equal(playPurchase({ data: signed.data, signature: "not base64 at all" }, play), null);
  assert.equal(playPurchase({ data: 5, signature: signed.signature }, play), null);
  assert.equal(playPurchase(null, play), null);
  const ec = generateKeyPairSync("ec", { namedCurve: "prime256v1" });
  assert.equal(playPurchase(purchase(), { ...play, licenceKey: ec.publicKey }), null, "a licence key is RSA");
});

/**
 * Google's side of a service account and the Play Developer API, as a fetch:
 * each purchase token's state, and every call made.
 */
function playApi(state = {}) {
  const calls = [];
  const fetch = async (url, init = {}) => {
    calls.push({ url, method: init.method ?? "GET", auth: init.headers?.authorization });
    if (url === "https://oauth2.googleapis.com/token") {
      return Response.json({ access_token: `at-${calls.length}`, expires_in: 3600 });
    }
    if (url.includes("/purchases/voidedpurchases?")) {
      const page = new URL(url).searchParams.get("token");
      const voided = state.voided ?? [];
      return page ? Response.json({ voidedPurchases: voided.slice(1) })
        : Response.json({ voidedPurchases: voided.slice(0, 1), tokenPagination: voided.length > 1 ? { nextPageToken: "p2" } : {} });
    }
    const m = /tokens\/([^/:]+)(:consume|:acknowledge)?$/.exec(url);
    const p = m && state[decodeURIComponent(m[1])];
    if (p === "down") return new Response("", { status: 503 });
    if (!p) return new Response("", { status: 404 });
    if (m[2] === ":consume") {
      p.consumptionState = 1;
      return new Response("", { status: 200 });
    }
    if (m[2] === ":acknowledge") {
      p.acknowledgementState = 1;
      return new Response("", { status: 200 });
    }
    return Response.json(p);
  };
  return { fetch, calls, state };
}
const SA = generateKeyPairSync("rsa", { modulusLength: 2048 });
const serviceAccount = { client_email: "play@ruleborn.iam.gserviceaccount.com",
  private_key: SA.privateKey.export({ type: "pkcs8", format: "pem" }), token_uri: "https://oauth2.googleapis.com/token" };
const paid = (extra = {}) => ({ purchaseState: 0, consumptionState: 0, acknowledgementState: 0, orderId: "GPA.1", ...extra });
function settler(api, test = false) {
  const plays = new PlayPurchases({ account: new ServiceAccount({ serviceAccount, fetch: api.fetch }),
                                    packageName: PACKAGE, test });
  return async (store, proof) => (store === "google-play" ? plays.settle(proof) : { ok: true });
}

test("a Play purchase is granted once, to the account whose intent it carries (20.2, 22.1)", async () => {
  const api = playApi({ "token-abc": paid(), "token-2": paid() });
  const t = server({ verifyReceipt: receipts({ play }), settleReceipt: settler(api) });
  const me = t.service.session("gc:buyer");
  const other = t.service.session("gc:other");
  const call = (who, path, json) => t.handle(new Request(`https://edge.example${path}`, {
    method: "POST", headers: { authorization: `Bearer ${who.token}`, "content-type": "application/json" },
    body: JSON.stringify(json) }));
  const { intent } = await (await call(me, "/v1/shop/intents", { product: "premium.1" })).json();
  const receipt = purchase({ obfuscatedAccountId: intent });
  const granted = await call(me, "/v1/shop/receipts", { store: "google-play", receipt });
  assert.equal(granted.status, 201);
  assert.deepEqual(await granted.json(), { product: "premium.1", to: me.account,
                                           granted: { season: 1, premium: true, granted: [] } });
  assert.equal(t.service.track.premium(me.account, 1), true);
  assert.equal((await (await call(me, "/v1/shop/receipts", { store: "google-play", receipt })).json()).repeated, true);
  assert.equal(t.service.db.prepare("SELECT COUNT(*) AS n FROM purchases").get().n, 1, "once");
  const stolen = await call(other, "/v1/shop/receipts", { store: "google-play", receipt });
  assert.deepEqual([stolen.status, (await stolen.json()).error], [409, "receipt_belongs_to_another_account"]);
  // A new purchase carrying someone else's intent is not theirs to redeem.
  const theirs = purchase({ obfuscatedAccountId: intent, purchaseToken: "token-2" });
  const mismatch = await call(other, "/v1/shop/receipts", { store: "google-play", receipt: theirs });
  assert.deepEqual([mismatch.status, (await mismatch.json()).error], [409, "intent_mismatch"]);
  // A store not configured refuses every receipt.
  const apple = await call(me, "/v1/shop/receipts", { store: "app-store", receipt: "x.y.z" });
  assert.equal(apple.status, 402);
});

test("a Play purchase is looked up and acknowledged with Google — a gift consumed — before it is granted, and a test or unpaid one is not (22.1, D67, F41)", async () => {
  const api = playApi({ "t-paid": paid(), "t-acked": paid({ acknowledgementState: 1 }), "t-pending": paid({ purchaseState: 2 }),
                        "t-test": paid({ purchaseType: 0 }), "t-down": "down", "t-gift": paid() });
  const t = server({ verifyReceipt: receipts({ play }), settleReceipt: settler(api) });
  const me = t.service.session("gc:buyer");
  const post = (token, product = "premium.1", intent = undefined) => t.handle(new Request("https://edge.example/v1/shop/receipts", {
    method: "POST", headers: { authorization: `Bearer ${me.token}`, "content-type": "application/json" },
    body: JSON.stringify({ store: "google-play", receipt: purchase({ purchaseToken: token, productId: product,
                                                                     ...(intent ? { obfuscatedAccountId: intent } : {}) }) }) }));
  const res = await post("t-paid");
  assert.equal(res.status, 201);
  assert.equal(api.state["t-paid"].acknowledgementState, 1, "acknowledged by the server, so Play does not refund it");
  assert.equal(api.state["t-paid"].consumptionState, 0, "an item is kept, not consumed (F41)");
  const acks = () => api.calls.filter((c) => c.url.endsWith(":acknowledge")).length;
  const consumes = () => api.calls.filter((c) => c.url.endsWith(":consume")).length;
  assert.equal(acks(), 1);
  // A gift can be bought again, so it is consumed.
  const friend = t.service.session("gc:friend").account;
  t.service.friends.accept(friend, t.service.friends.invite(me.account).invite);
  const gift = t.service.shop.intent(me.account, "gift.premium.1", { for: friend }).intent;
  assert.equal((await post("t-gift", "gift.premium.1", gift)).status, 201);
  assert.equal(consumes(), 1);
  assert.ok(api.calls.every((c) => c.url.includes("oauth2") || c.auth?.startsWith("Bearer at-")));
  // Granted once; a retry is answered from the grant without asking Google.
  const before = api.calls.length;
  assert.equal((await (await post("t-paid")).json()).repeated, true);
  assert.equal(api.calls.length, before);
  // Acknowledged already (a grant stopped after its acknowledgement): still
  // paid, granted now.
  assert.equal((await post("t-acked")).status, 201);
  assert.equal(acks(), 1, "nothing to acknowledge twice");
  const refusal = async (token) => { const r = await post(token); return [r.status, (await r.json()).why]; };
  assert.deepEqual(await refusal("t-pending"), [402, "not_paid"]);
  assert.deepEqual(await refusal("t-test"), [402, "test_purchase"]);
  assert.deepEqual(await refusal("t-unknown"), [402, "no_such_purchase"]);
  assert.deepEqual(await refusal("t-down"), [503, "store_unavailable"]);
  assert.equal(t.service.db.prepare("SELECT COUNT(*) AS n FROM purchases").get().n, 3, "three purchases, no more");
  // A test deployment lets a licence tester's purchase pay.
  const tester = server({ verifyReceipt: receipts({ play }), settleReceipt: settler(api, true) });
  const who = tester.service.session("gc:tester");
  const granted = await tester.service.shop.claim(who.account, "google-play", purchase({ purchaseToken: "t-test" }));
  assert.equal(granted.to, who.account);
});

test("what Google voided is taken back once a day, across its pages, and never twice (G32)", async () => {
  const api = playApi({ "t-1": paid(), voided: [{ purchaseToken: "t-1" }, { purchaseToken: "t-never-granted" }] });
  const t = server({ verifyReceipt: receipts({ play }), settleReceipt: settler(api) });
  const me = t.service.session("gc:buyer");
  await t.service.shop.claim(me.account, "google-play", purchase({ purchaseToken: "t-1" }));
  assert.equal(t.service.track.premium(me.account, 1), true);
  const plays = new PlayPurchases({ account: new ServiceAccount({ serviceAccount, fetch: api.fetch }), packageName: PACKAGE });
  assert.equal(await t.service.shop.voided(plays), 2);
  assert.equal(t.service.track.premium(me.account, 1), false, "the refunded premium track is taken back");
  assert.equal(await t.service.shop.voided(plays), 0, "once");
  const asked = api.calls.find((c) => c.url.includes("voidedpurchases"));
  assert.match(asked.url, /startTime=\d+/);
  assert.ok(api.calls.some((c) => c.url.includes("token=p2")), "the second page is read");
});

test("a service account's token is a JWT it signs, exchanged once and kept until near its expiry (D67)", async () => {
  const api = playApi();
  const clock = { now: T };
  const account = new ServiceAccount({ serviceAccount, fetch: api.fetch, now: () => clock.now });
  const [a, b] = await Promise.all([account.token(ANDROID_PUBLISHER), account.token(ANDROID_PUBLISHER)]);
  assert.equal(a, b, "callers at once share one exchange");
  assert.equal(api.calls.length, 1);
  clock.now += 3600 * 1000 - 30 * 1000;
  await account.token(ANDROID_PUBLISHER);
  assert.equal(api.calls.length, 2, "replaced a minute before it expires");
  // What was sent: a JWT the service account's key signed, for Google's token URL and the scope.
  let sent;
  await new ServiceAccount({ serviceAccount, now: () => T, fetch: async (url, init) => {
    sent = new URLSearchParams(init.body);
    return Response.json({ access_token: "x", expires_in: 3600 });
  } }).token(ANDROID_PUBLISHER);
  const [h, p, sig] = sent.get("assertion").split(".");
  assert.ok(verify("sha256", Buffer.from(`${h}.${p}`), SA.publicKey, Buffer.from(sig, "base64url")));
  const claims = JSON.parse(Buffer.from(p, "base64url"));
  assert.deepEqual([claims.iss, claims.scope, claims.aud, claims.exp - claims.iat],
                   [serviceAccount.client_email, ANDROID_PUBLISHER, serviceAccount.token_uri, 3600]);
  assert.throws(() => new ServiceAccount({ serviceAccount: { ...serviceAccount, token_uri: "https://evil.example/token" }, fetch }));
});

/** Google's side: a key set and ID tokens signed with it. */
function issuer(kid = "k1") {
  const pair = rsa();
  const jwk = { ...pair.publicKey.export({ format: "jwk" }), kid, alg: "RS256", use: "sig" };
  const token = (claims = {}, { alg = "RS256", key = pair.privateKey, k = kid } = {}) => {
    const head = b64url(JSON.stringify({ alg, kid: k, typ: "JWT" }));
    const body = b64url(JSON.stringify({ iss: "https://accounts.google.com", aud: CLIENT, sub: "1098765432101234567",
      iat: 1790000000, exp: 1790003600, email: "player@example.com", ...claims }));
    return `${head}.${body}.${b64url(sign("sha256", Buffer.from(`${head}.${body}`), key))}`;
  };
  return { jwk, token, pair };
}
const T = 1790000100 * 1000;

test("a Google ID token proves its account only as Google signed it, for this app, in date (24.8)", async () => {
  const g = issuer();
  let fetches = 0;
  const clock = { now: T };
  const google = new GoogleSignIn({ clientIds: [CLIENT], now: () => clock.now,
    fetchKeys: async () => { fetches++; return { keys: [g.jwk], maxAgeMs: 6 * 3600 * 1000 }; } });
  const ok = { idToken: g.token() };
  assert.equal(google.verify(ok), null, "no keys yet: nothing is proved before prepare");
  await google.prepare(ok);
  assert.equal(google.verify(ok), "gp:1098765432101234567");
  await google.prepare(ok);
  assert.equal(fetches, 1, "the keys are cached");
  const refused = {
    "another app's": g.token({ aud: "someone-else.apps.googleusercontent.com" }),
    "another issuer": g.token({ iss: "https://evil.example" }),
    "expired": g.token({ exp: 1789990000 }),
    "issued in the future": g.token({ iat: 1790099999 }),
    "no subject": g.token({ sub: "" }),
    "another key": g.token({}, { key: rsa().privateKey }),
    "HS256": g.token({}, { alg: "HS256" }),
  };
  for (const [why, idToken] of Object.entries(refused)) assert.equal(google.verify({ idToken }), null, why);
  const [h, , s] = g.token().split(".");
  const forged = `${h}.${b64url(JSON.stringify({ iss: "accounts.google.com", aud: CLIENT, sub: "1", iat: 1790000000, exp: 1790003600 }))}.${s}`;
  assert.equal(google.verify({ idToken: forged }), null, "a changed subject breaks the signature");
  assert.equal(google.verify({ idToken: "a.b" }), null);
  assert.equal(google.verify(null), null);
});

test("Google's keys are fetched once a minute at most, whoever asks, and a rotated key is picked up (24.8, G32)", async () => {
  const first = issuer("k1");
  const second = issuer("k2");
  let served = [first.jwk];
  let fetches = 0;
  let down = false;
  const clock = { now: T };
  const google = new GoogleSignIn({ clientIds: [CLIENT], now: () => clock.now,
    fetchKeys: async () => { fetches++; if (down) throw new Error("unreachable"); return { keys: served, maxAgeMs: 3600 * 1000 }; } });
  await google.prepare({ idToken: first.token() });
  // A token naming a key not held: one fetch, then none for a minute.
  const stray = { idToken: first.token({}, { k: "nobody" }) };
  for (let i = 0; i < 20; i++) await google.prepare(stray);
  assert.equal(fetches, 1);
  // Google rotates; the new key is fetched once the minute is up.
  served = [first.jwk, second.jwk];
  const rotated = { idToken: second.token() };
  await google.prepare(rotated);
  assert.equal(google.verify(rotated), null, "not within the minute");
  clock.now += GOOGLE_KEYS_RETRY_MS;
  await google.prepare(rotated);
  assert.equal(fetches, 2);
  assert.equal(google.verify(rotated), "gp:1098765432101234567");
  // Past the keys' age they are fetched again; an unreachable fetch keeps the old set.
  clock.now += 3600 * 1000;
  down = true;
  await google.prepare({ idToken: first.token({ iat: clock.now / 1000, exp: clock.now / 1000 + 3600 }) });
  assert.equal(fetches, 3);
  assert.equal(google.keys.size, 2);
  // A key set with nothing usable in it replaces nothing.
  down = false;
  served = [{ kty: "EC", kid: "k3" }, { ...second.jwk, alg: "HS256" }];
  clock.now += GOOGLE_KEYS_RETRY_MS;
  await google.prepare({ idToken: first.token({}, { k: "k3" }) });
  assert.equal(google.keys.size, 2);
});

test("sign-ins during Google's first key fetch wait for it, and a failed one is retried in seconds (24.8)", async () => {
  const g = issuer();
  let fetches = 0;
  let fail = true;
  let release;
  const clock = { now: T };
  const google = new GoogleSignIn({ clientIds: [CLIENT], now: () => clock.now, fetchKeys: async () => {
    fetches++;
    if (fail) throw new Error("unreachable");
    await new Promise((r) => { release = r; });
    return { keys: [g.jwk] };
  } });
  const c = { idToken: g.token() };
  await google.prepare(c);
  assert.equal(google.verify(c), null, "the first fetch failed");
  fail = false;
  clock.now += GOOGLE_KEYS_COLD_RETRY_MS;
  const both = [google.prepare(c), google.prepare(c)];
  await new Promise((r) => setImmediate(r));
  release();
  await Promise.all(both);
  assert.equal(fetches, 2, "one fetch, shared");
  assert.equal(google.verify(c), "gp:1098765432101234567");
});

test("each sign-in goes to its own platform, and sign-in is stubbed only with none configured (24.8, D67)", async () => {
  const g = issuer();
  const google = new GoogleSignIn({ clientIds: [CLIENT], now: () => T, fetchKeys: async () => ({ keys: [g.jwk] }) });
  const gameCenter = { prepare: async () => {}, verify: (c) => (c.playerId === "G:1" ? "gc:G:1" : null) };
  const both = signIn({ gameCenter, google });
  const idToken = g.token();
  await both.prepare({ idToken });
  assert.equal(both.verify({ idToken }), "gp:1098765432101234567");
  assert.equal(both.verify({ publicKeyUrl: "x", playerId: "G:1" }), "gc:G:1");
  assert.equal(both.verify({ publicKeyUrl: "x", playerId: "G:1", idToken }), "gp:1098765432101234567",
               "a token is Google's to check, whatever else rides with it");
  assert.equal(both.verify("gc:anyone"), null, "a bare name proves nothing once a platform is configured");
  assert.equal(both.stubbed, false);
  const googleOnly = signIn({ google });
  assert.equal(googleOnly.verify({ publicKeyUrl: "x", playerId: "G:1" }), null, "no Game Center to ask");
  const none = signIn({});
  assert.deepEqual([none.stubbed, none.verify("gc:anyone"), none.verify({ idToken })], [true, "gc:anyone", null]);
});

test("signing in with Google over HTTP makes an account, and the same token finds it again (24.8)", async () => {
  const g = issuer();
  const google = new GoogleSignIn({ clientIds: [CLIENT], now: () => T, fetchKeys: async () => ({ keys: [g.jwk] }) });
  const platforms = signIn({ google });
  const t = server({ verifyPlatform: platforms.verify, preparePlatform: platforms.prepare });
  const post = (credential) => t.handle(new Request("https://edge.example/v1/session", {
    method: "POST", headers: { "content-type": "application/json" }, body: JSON.stringify({ credential }) }));
  const first = await (await post({ idToken: g.token() })).json();
  assert.ok(first.account && first.token);
  assert.equal((await (await post({ idToken: g.token() })).json()).account, first.account);
  assert.equal((await post({ idToken: g.token({ aud: "other" }) })).status, 401);
});
