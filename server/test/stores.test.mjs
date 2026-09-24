// The stores' proofs (§24.8, §22.1): Game Center identities and StoreKit 2
// transactions, checked against a stand-in for Apple's chain
// (fixtures/apple, made by its make.sh).

import assert from "node:assert/strict";
import { X509Certificate, createPrivateKey, createSign, sign } from "node:crypto";
import { readFileSync } from "node:fs";
import { test } from "node:test";

import { GameCenter, appStoreTransaction, verifyChain } from "../src/stores.mjs";
import { server } from "./setup.mjs";

const fixture = (name) => readFileSync(new URL(`./fixtures/apple/${name}`, import.meta.url));
const cert = (name) => new X509Certificate(fixture(`${name}.pem`));
const ROOT = cert("root");
const INTERMEDIATE = cert("intermediate");
const STOREKIT = cert("storekit");
const GAMECENTER = cert("gamecenter");
const STRANGER = cert("stranger");
const BUNDLE = "com.example.ruleborn";
/** A moment inside the stand-in chain's validity: its certificates start
 *  the day make.sh ran. */
const NOW = Date.parse(ROOT.validFrom) + 24 * 60 * 60 * 1000;
const b64url = (b) => Buffer.from(b).toString("base64url");

/** A StoreKit 2 transaction, signed as Apple signs one. */
function jws(payload, { chain = [STOREKIT, INTERMEDIATE, ROOT], key = "storekit.key" } = {}) {
  const header = { alg: "ES256", x5c: chain.map((c) => c.raw.toString("base64")) };
  const body = `${b64url(JSON.stringify(header))}.${b64url(JSON.stringify(payload))}`;
  const signature = sign("sha256", Buffer.from(body),
                         { key: createPrivateKey(fixture(key)), dsaEncoding: "ieee-p1363" });
  return `${body}.${b64url(signature)}`;
}

const purchase = (extra = {}) => ({ transactionId: "2000000123", productId: "starglass-5", bundleId: BUNDLE,
                                    appAccountToken: null, ...extra });

test("a certificate chain is checked to a pinned root: in date, each signed by the next (24.8)", () => {
  assert.equal(verifyChain([STOREKIT, INTERMEDIATE, ROOT], [ROOT], NOW).subject, STOREKIT.subject);
  assert.ok(verifyChain([STOREKIT, INTERMEDIATE], [ROOT], NOW), "the root may be left out");
  assert.equal(verifyChain([STOREKIT, INTERMEDIATE, ROOT], [STRANGER], NOW), null, "a root nobody pinned");
  assert.equal(verifyChain([INTERMEDIATE, STOREKIT], [ROOT], NOW), null, "out of order");
  assert.equal(verifyChain([STOREKIT, GAMECENTER], [ROOT], NOW), null, "a leaf is no issuer");
  assert.equal(verifyChain([STOREKIT, INTERMEDIATE, ROOT], [ROOT], Date.UTC(2200, 0, 1)), null, "expired");
  assert.equal(verifyChain([], [ROOT], NOW), null);
});

test("a StoreKit 2 transaction counts only with its chain and signature intact, for this app (22.1)", () => {
  const pinned = { roots: [ROOT], bundleId: BUNDLE, now: NOW };
  assert.deepEqual(appStoreTransaction(jws(purchase({ appAccountToken: "abc" })), pinned),
                   { transaction: "2000000123", product: "starglass-5", intent: "abc" });
  const [h, , s] = jws(purchase()).split(".");
  const forged = `${h}.${b64url(JSON.stringify(purchase({ productId: "starglass-50" })))}.${s}`;
  assert.equal(appStoreTransaction(forged, pinned), null, "a changed product breaks the signature");
  assert.equal(appStoreTransaction(jws(purchase({ bundleId: "com.other" })), pinned), null, "another app's");
  assert.equal(appStoreTransaction(jws(purchase({ revocationDate: NOW })), pinned), null, "refunded");
  assert.equal(appStoreTransaction(jws(purchase(), { chain: [STRANGER], key: "stranger.key" }), pinned), null);
  assert.equal(appStoreTransaction("not a jws", pinned), null);
});

test("a Starglass pack bought through the App Store is granted from its signed transaction, once (22.1)", () => {
  const t = server({
    verifyReceipt: (store, receipt) => (store === "app-store"
      ? appStoreTransaction(receipt, { roots: [ROOT], bundleId: BUNDLE, now: NOW }) : null),
  });
  const me = t.service.session("gc:buyer").account;
  const { intent } = t.service.shop.intent(me, "starglass-5");
  assert.match(intent, /^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$/, "a UUID");
  const receipt = jws(purchase({ appAccountToken: intent }));
  assert.equal(t.service.shop.redeem(me, "app-store", receipt).starglass, 500);
  assert.equal(t.service.shop.redeem(me, "app-store", receipt).repeated, true);
  assert.equal(t.service.balance(me).starglass, 500);
});

/** A Game Center identity-verification signature, as the device gets one. */
function identity({ playerId = "T:_player1", bundleId = BUNDLE, timestamp = NOW, url = GC_URL } = {}) {
  const salt = Buffer.from("0123456789abcdef");
  const stamp = Buffer.alloc(8);
  stamp.writeBigUInt64BE(BigInt(timestamp));
  const signer = createSign("RSA-SHA256");
  signer.update(Buffer.concat([Buffer.from(playerId), Buffer.from(bundleId), stamp, salt]));
  return { playerId, bundleId, timestamp, publicKeyUrl: url, salt: salt.toString("base64"),
           signature: signer.sign(createPrivateKey(fixture("gamecenter.key"))).toString("base64") };
}
const GC_URL = "https://static.gc.apple.com/public-key/gc-prod-6.cer";

function gameCenter(now = NOW) {
  const fetched = [];
  const gc = new GameCenter({
    roots: [INTERMEDIATE, ROOT], bundleId: BUNDLE, now: () => now,
    fetchCertificate: async (url) => { fetched.push(url); return GAMECENTER.raw; },
  });
  return { gc, fetched };
}

test("a Game Center identity is Apple's: its key from apple.com, this app, a fresh timestamp, a true signature (24.8)", async () => {
  const { gc, fetched } = gameCenter();
  const good = identity();
  assert.equal(gc.verify(good), null, "nothing fetched yet, nothing proved");
  await gc.prepare(good);
  await gc.prepare(good);
  assert.deepEqual(fetched, [GC_URL], "fetched once, then cached");
  assert.equal(gc.verify(good), "gc:T:_player1");
  assert.equal(gc.verify({ ...good, playerId: "T:_someone_else" }), null, "a signature for another player");
  const other = identity({ bundleId: "com.other" });
  assert.equal(gc.verify(other), null, "another app's");
  const stale = identity({ timestamp: NOW - 6 * 60 * 1000 });
  assert.equal(gc.verify(stale), null, "more than five minutes old");
  const elsewhere = identity({ url: "https://gc.example.com/key.cer" });
  await gc.prepare(elsewhere);
  assert.equal(gc.verify(elsewhere), null, "a key from anywhere but Apple");
  assert.equal(fetched.length, 1, "and never fetched");
  const unpinned = new GameCenter({ roots: [STRANGER], bundleId: BUNDLE, now: () => NOW,
                                    fetchCertificate: async () => GAMECENTER.raw });
  await unpinned.prepare(good);
  assert.equal(unpinned.verify(good), null, "a certificate no pinned root issued");
});

test("sign-in over HTTP with a Game Center credential", async () => {
  const { gc } = gameCenter();
  const t = server({ verifyPlatform: (c) => gc.verify(c), preparePlatform: (c) => gc.prepare(c) });
  const call = (credential) => t.handle(new Request("https://edge.example/v1/session", {
    method: "POST", headers: { "content-type": "application/json" }, body: JSON.stringify({ credential }) }));
  const ok = await call(identity());
  assert.equal(ok.status, 200);
  const again = await (await call(identity())).json();
  assert.equal(again.account, (await ok.json()).account, "the same player, the same account");
  assert.equal((await call({ ...identity(), signature: "AAAA" })).status, 401);
});
