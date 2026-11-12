// The deep security run's fixes for the shop (SEC-21, SEC-33): a minor's
// monthly cap is checked again when a purchase is granted, so intents left
// to lapse before they are paid cannot take the month past it, and a claim
// whose account is deleted while the store is being asked grants nothing.

import assert from "node:assert/strict";
import { test } from "node:test";

import { deleteAccount } from "../src/accounts.mjs";
import { Refused } from "../src/refused.mjs";
import { INTENT_MS, Shop } from "../src/shop.mjs";
import { server } from "./setup.mjs";

/** A store the tests vouch for: "txn:product[:intent]". */
const verifyReceipt = (store, receipt) => {
  if (store !== "app-store" || typeof receipt !== "string") return null;
  const [transaction, product, intent] = receipt.split(":");
  return { transaction, product, intent };
};

const CATALOGUE = { items: [
  { id: "realm-dawn", kind: "realm_skin", set: "dawn", price: 2000 },
  { id: "bridge-grand", kind: "bridge_style", set: "grand", price: 4900 },
  { id: "robe-aurora", kind: "sage_robe", set: "aurora", price: 500 },
  { id: "sky-aurora", kind: "sky_theme", set: "aurora", price: 300 },
] };

const minor = (t, who) => {
  const account = t.service.session(who).account;
  t.service.db.prepare("UPDATE accounts SET age_band = '13-15' WHERE id = ?").run(account);
  return account;
};

test("SEC-21: intents left to lapse before they are paid cannot take a minor past the month's cap", () => {
  const t = server();
  const shop = new Shop(t.service, { verifyReceipt, catalogue: CATALOGUE });
  const young = minor(t, "gc:young");
  const cap = shop.allowance(young);
  assert.equal(cap, 2500);
  // Each intent passes: the one before has lapsed from what is held.
  const intents = [];
  for (const product of ["realm-dawn", "robe-aurora", "sky-aurora"]) {
    intents.push(shop.intent(young, product));
    t.clock.now += INTENT_MS + 60_000;
  }
  // Then every one is paid in the store, and the receipts arrive.
  const receipt = (n) => `txn-${n}:${intents[n].product}:${intents[n].intent}`;
  shop.redeem(young, "app-store", receipt(0));                  // 2000 of 2500
  shop.redeem(young, "app-store", receipt(1));                  // 2500 of 2500: at the cap, not past it
  assert.throws(() => shop.redeem(young, "app-store", receipt(2)), (e) => {
    assert.ok(e instanceof Refused);
    assert.equal(e.status, 403);
    assert.equal(e.reason, "monthly_cap");
    assert.equal(e.detail.left, 0);
    assert.equal(e.detail.cap, 2500);
    return true;
  });
  const spent = t.service.db.prepare("SELECT SUM(price) AS n FROM purchases WHERE account = ?").get(young).n;
  assert.equal(spent, 2500, "the month never goes past the cap");
});

test("SEC-21: an intent still live is counted once at its grant, and an adult is never capped", () => {
  const t = server();
  const shop = new Shop(t.service, { verifyReceipt, catalogue: CATALOGUE });
  const young = minor(t, "gc:young");
  // A live intent for the whole of what is left is granted: it is not
  // counted both as held and as the price being paid.
  const r = shop.intent(young, "realm-dawn");
  shop.redeem(young, "app-store", `txn-1:realm-dawn:${r.intent}`);
  const s = shop.intent(young, "robe-aurora");
  shop.redeem(young, "app-store", `txn-2:robe-aurora:${s.intent}`);
  assert.equal(shop.allowance(young), 0);
  const adult = t.service.session("gc:adult").account;
  const a = shop.intent(adult, "bridge-grand");
  t.clock.now += INTENT_MS + 60_000;
  shop.redeem(adult, "app-store", `txn-3:bridge-grand:${a.intent}`);
});

test("SEC-21: a claim over the cap is refused before the store is asked to settle it", async () => {
  const t = server();
  let settled = 0;
  const shop = new Shop(t.service, {
    verifyReceipt, catalogue: CATALOGUE, settleReceipt: async () => { settled++; return { ok: true }; },
  });
  const young = minor(t, "gc:young");
  const first = shop.intent(young, "realm-dawn");
  t.clock.now += INTENT_MS + 60_000;
  const second = shop.intent(young, "robe-aurora");
  t.clock.now += INTENT_MS + 60_000;
  const third = shop.intent(young, "sky-aurora");
  t.clock.now += INTENT_MS + 60_000;
  await shop.claim(young, "app-store", `txn-1:realm-dawn:${first.intent}`);
  await shop.claim(young, "app-store", `txn-2:robe-aurora:${second.intent}`);
  assert.equal(settled, 2);
  await assert.rejects(shop.claim(young, "app-store", `txn-3:sky-aurora:${third.intent}`),
                       (e) => e instanceof Refused && e.reason === "monthly_cap");
  assert.equal(settled, 2, "the store was never told, so it refunds the purchase by itself");
});

test("SEC-33: an account deleted while its claim is with the store is granted nothing", async (ctx) => {
  const t = server();
  let release;
  const waiting = new Promise((resolve) => { release = resolve; });
  let asked;
  const askedPromise = new Promise((resolve) => { asked = resolve; });
  const shop = new Shop(t.service, {
    verifyReceipt, catalogue: CATALOGUE,
    settleReceipt: async () => { asked(); await waiting; return { ok: true }; },
  });
  const me = t.service.session("gc:me").account;
  const { intent } = shop.intent(me, "robe-aurora");
  const recorded = [];
  const record = t.service.telemetry.record.bind(t.service.telemetry);
  ctx.mock.method(t.service.telemetry, "record", (account, kind, ...rest) => {
    recorded.push({ account, kind });
    return record(account, kind, ...rest);
  });
  const claim = shop.claim(me, "app-store", `txn-1:robe-aurora:${intent}`);
  await askedPromise;
  deleteAccount(t.service, me);
  release();
  await assert.rejects(claim, (e) => e instanceof Refused && e.status === 410 && e.reason === "account_deleted");
  assert.equal(t.service.db.prepare("SELECT COUNT(*) AS n FROM purchases WHERE account = ?").get(me).n, 0);
  assert.ok(!recorded.some((r) => r.account === me && r.kind === "purchase"), "no purchase telemetry");
});
