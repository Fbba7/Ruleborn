// The stores' proofs (§24.8, §22.1): Game Center identities and StoreKit 2
// transactions, checked against a stand-in for Apple's chain
// (fixtures/apple, made by its make.sh).

import assert from "node:assert/strict";
import { X509Certificate, createPrivateKey, createSign, sign } from "node:crypto";
import { readFileSync } from "node:fs";
import { test } from "node:test";

import { GAME_CENTER_CACHE, GameCenter, appStoreNotification, appStoreTransaction, verifyChain } from "../src/stores.mjs";
import { handler } from "../src/http.mjs";
import { server } from "./setup.mjs";

const fixture = (name) => readFileSync(new URL(`./fixtures/apple/${name}`, import.meta.url));
const cert = (name) => new X509Certificate(fixture(`${name}.pem`));
const ROOT = cert("root");
const INTERMEDIATE = cert("intermediate");
const STOREKIT = cert("storekit");
const GAMECENTER = cert("gamecenter");
const STRANGER = cert("stranger");
const STOREKIT_RSA = cert("storekit-rsa");
const DEVELOPER = cert("developer");
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

const purchase = (extra = {}) => ({ transactionId: "2000000123", productId: "premium.1", bundleId: BUNDLE,
                                    environment: "Production", appAccountToken: null, ...extra });

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
                   { transaction: "2000000123", product: "premium.1", intent: "abc" });
  const [h, , s] = jws(purchase()).split(".");
  const forged = `${h}.${b64url(JSON.stringify(purchase({ productId: "premium.2" })))}.${s}`;
  assert.equal(appStoreTransaction(forged, pinned), null, "a changed product breaks the signature");
  assert.equal(appStoreTransaction(jws(purchase({ bundleId: "com.other" })), pinned), null, "another app's");
  assert.equal(appStoreTransaction(jws(purchase({ revocationDate: NOW })), pinned), null, "refunded");
  assert.equal(appStoreTransaction(jws(purchase(), { chain: [STRANGER], key: "stranger.key" }), pinned), null);
  assert.equal(appStoreTransaction("not a jws", pinned), null);
});

test("a StoreKit 2 transaction is signed by Apple's StoreKit leaf, not by anything the root vouches for (22.1)", () => {
  const pinned = { roots: [ROOT], bundleId: BUNDLE, now: NOW };
  const forge = (name, chain = [cert(name), INTERMEDIATE, ROOT]) =>
    appStoreTransaction(jws(purchase({ transactionId: "999" }), { chain, key: `${name}.key` }), pinned);
  assert.equal(forge("gamecenter"), null, "an RSA leaf's signature under an ES256 header");
  assert.equal(forge("storekit-rsa"), null, "an RSA key, even with the StoreKit marker");
  assert.equal(forge("developer"), null, "an EC leaf the intermediate issued without the StoreKit marker");
  assert.equal(forge("storekit", [STOREKIT]), null, "the leaf alone");
  assert.equal(forge("storekit", [STOREKIT, INTERMEDIATE, ROOT, ROOT]), null, "more than leaf, intermediate, root");
  assert.equal(forge("storekit", [STOREKIT, INTERMEDIATE, INTERMEDIATE]), null, "a third that is not the root");
  assert.equal(appStoreTransaction(jws(purchase()), { ...pinned, oids: { leaf: "1.2.840.113635.100.6.11.1",
                                                                        intermediate: "1.2.3.4" } }),
               null, "an intermediate without the marker asked for");
  assert.equal(appStoreTransaction(`${b64url(JSON.stringify({ alg: "ES256", x5c: [1, 2] }))}.${b64url("{}")}.AA`,
                                   pinned), null, "a chain that is not certificates");
  assert.ok(forge("storekit"), "Apple's own chain still counts");
  assert.ok(forge("storekit", [STOREKIT, INTERMEDIATE]), "with the root left out");
});

test("a Sandbox transaction pays only where the operator allows Sandbox (22.1)", () => {
  const pinned = { roots: [ROOT], bundleId: BUNDLE, now: NOW };
  const sandbox = jws(purchase({ environment: "Sandbox" }));
  assert.equal(appStoreTransaction(sandbox, pinned), null, "a free test purchase is no purchase");
  assert.equal(appStoreTransaction(jws(purchase({ environment: undefined })), pinned), null, "nor one naming none");
  assert.equal(appStoreTransaction(jws(purchase({ environment: "Xcode" })), { ...pinned, sandbox: true }), null);
  assert.equal(appStoreTransaction(sandbox, { ...pinned, sandbox: true }).product, "premium.1");
});

test("a premium track bought through the App Store is granted from its signed transaction, once (22.1, F41)", () => {
  const t = server({
    verifyReceipt: (store, receipt) => (store === "app-store"
      ? appStoreTransaction(receipt, { roots: [ROOT], bundleId: BUNDLE, now: NOW }) : null),
  });
  const me = t.service.session("gc:buyer").account;
  const { intent } = t.service.shop.intent(me, "premium.1");
  assert.match(intent, /^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$/, "a UUID");
  const receipt = jws(purchase({ appAccountToken: intent }));
  assert.equal(t.service.shop.redeem(me, "app-store", receipt).to, me);
  assert.equal(t.service.shop.redeem(me, "app-store", receipt).repeated, true);
  assert.equal(t.service.track.premium(me, 1), true);
});

/** An App Store Server Notification (v2), signed as Apple signs one, with
 *  the transaction it is about signed inside it. */
const notification = (type, { tx = purchase(), data = {}, ...extra } = {}) => jws({
  notificationType: type, notificationUUID: "n-1", ...extra,
  data: { bundleId: BUNDLE, environment: "Production", signedTransactionInfo: jws(tx), ...data } });

test("an App Store Server Notification counts only as Apple signed it, for this app, and names what it takes back (G32)", () => {
  const pinned = { roots: [ROOT], bundleId: BUNDLE, now: NOW };
  assert.deepEqual(appStoreNotification(notification("REFUND"), pinned),
                   { type: "REFUND", transaction: "2000000123", product: "premium.1" });
  assert.deepEqual(appStoreNotification(notification("REVOKE"), pinned).transaction, "2000000123");
  assert.deepEqual(appStoreNotification(notification("DID_RENEW"), pinned), { type: "DID_RENEW", transaction: null });
  assert.equal(appStoreNotification(notification("REFUND", { data: { bundleId: "com.other" } }), pinned), null);
  assert.equal(appStoreNotification(notification("REFUND", { data: { environment: "Sandbox" } }), pinned), null);
  assert.ok(appStoreNotification(notification("REFUND", { data: { environment: "Sandbox" } }), { ...pinned, sandbox: true }));
  assert.equal(appStoreNotification(notification("REFUND", { data: { signedTransactionInfo: "x.y.z" } }), pinned), null,
               "the transaction inside must be Apple's too");
  const [h, , sig] = notification("REFUND").split(".");
  const forged = `${h}.${b64url(JSON.stringify({ notificationType: "REFUND", data: { bundleId: BUNDLE } }))}.${sig}`;
  assert.equal(appStoreNotification(forged, pinned), null);
});

test("Apple's refund, posted to the server, takes the purchase back once, and a later receipt for it is refused (G32)", async () => {
  const pinned = { roots: [ROOT], bundleId: BUNDLE, now: NOW };
  const t = server({ verifyReceipt: (store, receipt) => (store === "app-store"
    ? appStoreTransaction(receipt, pinned) : null) });
  const me = t.service.session("gc:buyer").account;
  t.service.shop.redeem(me, "app-store", jws(purchase()));
  const handle = handler(t.service, { appleNotifications: (sp) => appStoreNotification(sp, pinned) });
  const post = (signedPayload) => handle(new Request("https://edge.example/v1/stores/apple/notifications", {
    method: "POST", headers: { "content-type": "application/json" }, body: JSON.stringify({ signedPayload }) }));
  const res = await post(notification("REFUND"));
  assert.equal(res.status, 200);
  assert.deepEqual(await res.json(), { type: "REFUND", revoked: { season: 1, premium: false, revoked: [] }, from: me });
  assert.equal(t.service.track.premium(me, 1), false);
  assert.deepEqual(await (await post(notification("REFUND"))).json(), { type: "REFUND", repeated: true });
  // Apple reverses the refund: the track is given back, once.
  const reversed = await (await post(notification("REFUND_REVERSED"))).json();
  assert.deepEqual([reversed.type, reversed.to, reversed.granted.premium], ["REFUND_REVERSED", me, true]);
  assert.equal(t.service.track.premium(me, 1), true);
  assert.deepEqual(await (await post(notification("REFUND_REVERSED"))).json(), { type: "REFUND_REVERSED", repeated: true });
  assert.equal((await post("not a jws")).status, 400);
  assert.equal((await t.handle(new Request("https://edge.example/v1/stores/apple/notifications", {
    method: "POST", headers: { "content-type": "application/json" }, body: "{\"signedPayload\":\"x\"}" }))).status, 503,
    "not configured, not believed");
  // Refunded before its receipt came: the receipt is refused.
  await post(notification("REFUND", { tx: purchase({ transactionId: "2000000999" }) }));
  const other = t.service.session("gc:other").account;
  assert.throws(() => t.service.shop.redeem(other, "app-store", jws(purchase({ transactionId: "2000000999" }))),
                (e) => e.reason === "receipt_refunded");
  assert.deepEqual(t.service.shop.summary(me).months.map((m) => [m.cents, m.refunded]), [[600, 0]], "reversed");
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

test("a Game Center key is Apple's by name, not any the pinned CA issued (24.8)", async () => {
  const key = fixture("storekit-rsa.key");
  const signer = createSign("RSA-SHA256");
  const stamp = Buffer.alloc(8);
  stamp.writeBigUInt64BE(BigInt(NOW));
  signer.update(Buffer.concat([Buffer.from("T:_player1"), Buffer.from(BUNDLE), stamp]));
  const credential = { playerId: "T:_player1", bundleId: BUNDLE, timestamp: NOW, publicKeyUrl: GC_URL, salt: "",
                       signature: signer.sign(createPrivateKey(key)).toString("base64") };
  const gc = new GameCenter({ roots: [INTERMEDIATE, ROOT], bundleId: BUNDLE, now: () => NOW,
                              fetchCertificate: async () => STOREKIT_RSA.raw });
  await gc.prepare(credential);
  assert.equal(gc.verify(credential), null, "a certificate not issued to Apple Inc.");
});

test("Game Center's key is fetched only from a plain apple.com key URL, and few are kept (24.8)", async () => {
  const { gc, fetched } = gameCenter();
  for (const url of [`${GC_URL}?n=1`, `${GC_URL}#1`, "https://user@static.gc.apple.com/public-key/gc-prod-6.cer",
                     "https://static.gc.apple.com:8443/public-key/gc-prod-6.cer",
                     "https://STATIC.gc.apple.com/public-key/gc-prod-6.cer",
                     "https://static.gc.apple.com/public-key/../gc-prod-6.cer",
                     "https://static.gc.apple.com/elsewhere/gc-prod-6.cer",
                     "http://static.gc.apple.com/public-key/gc-prod-6.cer",
                     "https://www.apple.com/public-key/gc-prod-6.cer",
                     "https://static.gc.apple.com/public-key/anything.cer"]) {
    await gc.prepare({ publicKeyUrl: url });
    assert.equal(gc.verify(identity({ url })), null, url);
  }
  assert.deepEqual(fetched, [], "none of them fetched");
  await gc.prepare(identity());
  assert.equal(gc.verify(identity()), "gc:T:_player1");
  // A stream of unseen names, asked at once: one fetch a second at most, and
  // a good key is never pushed out by names that fail.
  for (let i = 0; i < 100; i++) await gc.prepare({ publicKeyUrl: `https://static.gc.apple.com/public-key/gc-prod-${100 + i}.cer` });
  assert.equal(fetched.length, 1, "the first unseen name only, within the second");
  assert.ok(gc.certificates.size <= GAME_CENTER_CACHE, "the cache is bounded");
  assert.equal(gc.verify(identity()), "gc:T:_player1", "the key in use is kept");

  let tries = 0;
  const down = new GameCenter({ roots: [INTERMEDIATE, ROOT], bundleId: BUNDLE, now: () => NOW,
                                fetchCertificate: async () => { tries++; throw new Error("unreachable"); } });
  await down.prepare(identity());
  await down.prepare(identity());
  assert.equal(tries, 1, "a failure is remembered for a while");
  assert.equal(down.verify(identity()), null);
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
