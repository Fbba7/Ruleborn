// FX2-3-shop: the November bug report's shop and store entries
// (docs/security/bug-report-2026-11.md): RB-08 (a Play purchase settled
// with Google before the server knew it would grant it), RB-09 (two claims
// racing past a minor's monthly cap), RB-10 (the Play receipt sent as the
// JSON string the client sends), RB-11 (a StoreKit transaction for more
// than one item) and RB-13 (a new Game Center key evicted as it is cached).
// Each test was written to fail on main before its fix.

import assert from "node:assert/strict";
import { X509Certificate, createPrivateKey, createSign, generateKeyPairSync, sign } from "node:crypto";
import { readFileSync } from "node:fs";
import { test } from "node:test";

import { deleteAccount } from "../src/accounts.mjs";
import { PlayPurchases, ServiceAccount } from "../src/googleapi.mjs";
import { Refused } from "../src/refused.mjs";
import { Shop } from "../src/shop.mjs";
import { GAME_CENTER_CACHE, GameCenter, appStoreTransaction, playPurchase, receipts } from "../src/stores.mjs";
import { server } from "./setup.mjs";

// -- Google Play, as google.test.mjs plays it --------------------------------

const PACKAGE = "com.example.ruleborn";
const LICENCE = generateKeyPairSync("rsa", { modulusLength: 2048 });
const play = { licenceKey: LICENCE.publicKey, packageName: PACKAGE };

/** A Play Billing purchase as Play returns it: its JSON and a signature. */
function purchase(extra = {}) {
  const data = JSON.stringify({ orderId: "GPA.3300-1111-2222-33333", packageName: PACKAGE,
    productId: "premium.1", purchaseTime: 1790000000000, purchaseState: 0,
    purchaseToken: "token-abc", quantity: 1, acknowledged: false, ...extra });
  return { data, signature: sign("sha1", Buffer.from(data), LICENCE.privateKey).toString("base64") };
}

/** The Play Developer API as a fetch: each token's state, and every call. */
function playApi(state = {}) {
  const calls = [];
  const fetch = async (url, init = {}) => {
    calls.push({ url, method: init.method ?? "GET" });
    if (url === "https://oauth2.googleapis.com/token") return Response.json({ access_token: "at", expires_in: 3600 });
    const m = /tokens\/([^/:]+)(:consume|:acknowledge)?$/.exec(url);
    const p = m && state[decodeURIComponent(m[1])];
    if (!p) return new Response("", { status: 404 });
    if (m[2] === ":consume") { p.consumptionState = 1; return new Response("", { status: 200 }); }
    if (m[2] === ":acknowledge") { p.acknowledgementState = 1; return new Response("", { status: 200 }); }
    return Response.json(p);
  };
  /** The tokens Google was asked to acknowledge or consume. */
  const settled = () => calls.filter((c) => /:(acknowledge|consume)$/.test(c.url))
    .map((c) => decodeURIComponent(/tokens\/([^/:]+):/.exec(c.url)[1]));
  /** Every call that named a purchase token: what the store was told. */
  const told = () => calls.filter((c) => c.url.includes("/tokens/"));
  return { fetch, calls, settled, told };
}
const SA = generateKeyPairSync("rsa", { modulusLength: 2048 });
const serviceAccount = { client_email: "play@ruleborn.iam.gserviceaccount.com",
  private_key: SA.privateKey.export({ type: "pkcs8", format: "pem" }), token_uri: "https://oauth2.googleapis.com/token" };
const paid = () => ({ purchaseState: 0, consumptionState: 0, acknowledgementState: 0, orderId: "GPA.1" });
function settler(api) {
  const plays = new PlayPurchases({ account: new ServiceAccount({ serviceAccount, fetch: api.fetch }),
                                    packageName: PACKAGE });
  return async (store, proof) => (store === "google-play" ? plays.settle(proof) : { ok: true });
}

const post = (t, who, path, json) => t.handle(new Request(`https://edge.example${path}`, {
  method: "POST", headers: { authorization: `Bearer ${who.token}`, "content-type": "application/json" },
  body: JSON.stringify(json) }));

// -- RB-08 -------------------------------------------------------------------

test("RB-08: a Play purchase the server will not grant is refused before Google is told anything", async () => {
  const api = playApi({ "t-future": paid(), "t-theirs": paid(), "t-gone": paid() });
  const t = server({ verifyReceipt: receipts({ play }), settleReceipt: settler(api) });
  const me = t.service.session("gc:buyer");
  const other = t.service.session("gc:other");

  // A product the server does not sell (a future season's premium track).
  const future = await post(t, me, "/v1/shop/receipts",
                            { store: "google-play", receipt: purchase({ productId: "premium.99", purchaseToken: "t-future" }) });
  assert.equal(future.status, 404);
  assert.equal((await future.json()).error, "no_such_product");

  // A receipt carrying another account's intent.
  const { intent } = await (await post(t, other, "/v1/shop/intents", { product: "premium.1" })).json();
  const theirs = await post(t, me, "/v1/shop/receipts",
                            { store: "google-play", receipt: purchase({ purchaseToken: "t-theirs", obfuscatedAccountId: intent }) });
  assert.equal(theirs.status, 409);
  assert.equal((await theirs.json()).error, "intent_mismatch");

  // An account deleted before its claim is checked.
  const leaving = t.service.session("gc:leaving").account;
  deleteAccount(t.service, leaving);
  await assert.rejects(t.service.shop.claim(leaving, "google-play", purchase({ purchaseToken: "t-gone" })),
                       (e) => e instanceof Refused && e.status === 410 && e.reason === "account_deleted");

  assert.deepEqual(api.settled(), [], "nothing acknowledged or consumed, so Play refunds each by itself");
  assert.deepEqual(api.told(), [], "Google was not asked about any of them");
});

// -- RB-09 -------------------------------------------------------------------

const CATALOGUE = { items: [
  { id: "realm-dawn", kind: "realm_skin", set: "dawn", price: 2000 },
  { id: "bridge-grand", kind: "bridge_style", set: "grand", price: 2000 },
  { id: "robe-aurora", kind: "sage_robe", set: "aurora", price: 500 },
] };

test("RB-09: two claims racing for a minor's last €25 do not both reach Google", async () => {
  const api = playApi({ tokA: paid(), tokB: paid(), tokC: paid() });
  const t = server();
  const shop = new Shop(t.service, { verifyReceipt: receipts({ play }), settleReceipt: settler(api), catalogue: CATALOGUE });
  const young = t.service.session("gc:young").account;
  t.service.db.prepare("UPDATE accounts SET age_band = '13-15' WHERE id = ?").run(young);
  assert.equal(shop.allowance(young), 2500);

  // Two €20 receipts with no live intent (a restore, a retry, two devices), at once.
  const results = await Promise.allSettled([
    shop.claim(young, "google-play", purchase({ productId: "realm-dawn", purchaseToken: "tokA" })),
    shop.claim(young, "google-play", purchase({ productId: "bridge-grand", purchaseToken: "tokB" })),
  ]);
  const statuses = results.map((r) => (r.status === "fulfilled" ? 201 : r.reason?.status));
  assert.deepEqual(statuses, [201, 403], "the first is granted, the second refused");
  assert.equal(results[1].reason.reason, "monthly_cap");
  assert.deepEqual(api.settled(), ["tokA"], "only the granted one was acknowledged");

  // Once the first is granted the month's €5 left is still there, and a
  // refused claim holds no place in it.
  await shop.claim(young, "google-play", purchase({ productId: "robe-aurora", purchaseToken: "tokC" }));
  assert.equal(shop.allowance(young), 0);
  assert.deepEqual(api.settled(), ["tokA", "tokC"]);
});

test("RB-09: a claim the store refuses holds no place under the cap afterwards", async () => {
  const api = playApi({ tokB: paid() });                      // tokA: Google does not know it
  const t = server();
  const shop = new Shop(t.service, { verifyReceipt: receipts({ play }), settleReceipt: settler(api), catalogue: CATALOGUE });
  const young = t.service.session("gc:young").account;
  t.service.db.prepare("UPDATE accounts SET age_band = '13-15' WHERE id = ?").run(young);
  await assert.rejects(shop.claim(young, "google-play", purchase({ productId: "realm-dawn", purchaseToken: "tokA" })),
                       (e) => e instanceof Refused && e.reason === "receipt_refused");
  assert.equal(shop.allowance(young), 2500);
  await shop.claim(young, "google-play", purchase({ productId: "bridge-grand", purchaseToken: "tokB" }));
  assert.deepEqual(api.settled(), ["tokB"]);
});

// -- RB-10 -------------------------------------------------------------------

test("RB-10: the Play receipt as the JSON string the client sends is verified and granted", async () => {
  const api = playApi({ "token-abc": paid() });
  const t = server({ verifyReceipt: receipts({ play }), settleReceipt: settler(api) });
  const me = t.service.session("gc:buyer");
  const sent = JSON.stringify(purchase());                    // shop_controller.gd: str(paid.value["receipt"])
  const r = await post(t, me, "/v1/shop/receipts", { store: "google-play", receipt: sent });
  assert.equal(r.status, 201);
  assert.equal((await r.json()).product, "premium.1");
  assert.deepEqual(api.settled(), ["token-abc"]);
});

test("RB-10: a string receipt is read only as a short JSON object of strings", () => {
  const signed = purchase();
  assert.deepEqual(playPurchase(JSON.stringify(signed), play),
                   { transaction: "token-abc", product: "premium.1", intent: null });
  assert.equal(playPurchase("not json", play), null);
  assert.equal(playPurchase(JSON.stringify("nested"), play), null);
  assert.equal(playPurchase("null", play), null);
  assert.equal(playPurchase(JSON.stringify([signed.data, signed.signature]), play), null);
  assert.equal(playPurchase(JSON.stringify({ ...signed, pad: "x".repeat(40_000) }), play), null, "past the length cap");
});

// -- RB-11 -------------------------------------------------------------------

const fixture = (name) => readFileSync(new URL(`./fixtures/apple/${name}`, import.meta.url));
const cert = (name) => new X509Certificate(fixture(`${name}.pem`));
const [ROOT, INTERMEDIATE, STOREKIT, GAMECENTER] = [cert("root"), cert("intermediate"), cert("storekit"), cert("gamecenter")];
const BUNDLE = "com.example.ruleborn";
const NOW = Date.parse(ROOT.validFrom) + 24 * 60 * 60 * 1000;
const b64url = (b) => Buffer.from(b).toString("base64url");

/** A StoreKit 2 transaction, signed as Apple signs one. */
function jws(payload) {
  const header = { alg: "ES256", x5c: [STOREKIT, INTERMEDIATE, ROOT].map((c) => c.raw.toString("base64")) };
  const body = `${b64url(JSON.stringify(header))}.${b64url(JSON.stringify(payload))}`;
  const signature = sign("sha256", Buffer.from(body),
                         { key: createPrivateKey(fixture("storekit.key")), dsaEncoding: "ieee-p1363" });
  return `${body}.${b64url(signature)}`;
}

test("RB-11: a StoreKit transaction for more than one item is refused, as Play's is", () => {
  const pinned = { roots: [ROOT], bundleId: BUNDLE, now: NOW };
  const txn = (extra) => jws({ transactionId: "2000000123", productId: "gift.robe-aurora", bundleId: BUNDLE,
                               environment: "Production", appAccountToken: null, ...extra });
  assert.equal(appStoreTransaction(txn({ quantity: 5 }), pinned), null, "five items, one grant");
  assert.equal(appStoreTransaction(txn({ quantity: 0 }), pinned), null);
  assert.equal(appStoreTransaction(txn({ quantity: "1" }), pinned), null);
  assert.deepEqual(appStoreTransaction(txn({ quantity: 1 }), pinned),
                   { transaction: "2000000123", product: "gift.robe-aurora", intent: null });
  assert.ok(appStoreTransaction(txn({}), pinned), "a transaction that names no quantity is one item");
});

// -- RB-13 -------------------------------------------------------------------

test("RB-13: a ninth Game Center key, after eight have each signed a player in, is cached and used", async () => {
  const clock = { now: NOW };
  let fetched = 0;
  const gc = new GameCenter({ roots: [INTERMEDIATE, ROOT], bundleId: BUNDLE, now: () => clock.now,
                              fetchCertificate: async () => { fetched++; return GAMECENTER.raw; } });
  const identity = (n) => {
    const salt = Buffer.from("0123456789abcdef");
    const stamp = Buffer.alloc(8);
    stamp.writeBigUInt64BE(BigInt(clock.now));
    const signer = createSign("RSA-SHA256");
    signer.update(Buffer.concat([Buffer.from("T:_p"), Buffer.from(BUNDLE), stamp, salt]));
    return { playerId: "T:_p", bundleId: BUNDLE, timestamp: clock.now,
             publicKeyUrl: `https://static.gc.apple.com/public-key/gc-prod-${n}.cer`,
             salt: salt.toString("base64"),
             signature: signer.sign(createPrivateKey(fixture("gamecenter.key"))).toString("base64") };
  };
  const signIn = async (n) => {
    clock.now += 1000;
    await gc.prepare(identity(n));
    return gc.verify(identity(n));
  };
  for (let n = 1; n <= GAME_CENTER_CACHE; n++) assert.equal(await signIn(n), "gc:T:_p", `gc-prod-${n} sign-in works`);
  assert.equal(await signIn(GAME_CENTER_CACHE + 1), "gc:T:_p", `gc-prod-${GAME_CENTER_CACHE + 1} sign-in works`);
  assert.equal(fetched, GAME_CENTER_CACHE + 1);
  assert.equal(await signIn(GAME_CENTER_CACHE + 1), "gc:T:_p", "and again, from the cache");
  assert.equal(fetched, GAME_CENTER_CACHE + 1, "with no fetch");
  assert.equal(gc.certificates.size, GAME_CENTER_CACHE);
});
