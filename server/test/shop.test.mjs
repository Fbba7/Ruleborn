// The season track (§18.2, §18.8), Starglass and its purchases (§20.2,
// §22.1), and cosmetics owned and worn, against the real simulation build.

import assert from "node:assert/strict";
import { mkdtempSync, rmSync } from "node:fs";
import { tmpdir } from "node:os";
import { join } from "node:path";
import { DatabaseSync } from "node:sqlite";
import { test } from "node:test";

import { open } from "../src/db.mjs";
import { Refused } from "../src/service.mjs";
import { SEASON_MS } from "../src/seasons.mjs";
import { Shop } from "../src/shop.mjs";
import { PREMIUM_PRICE, TIER_STARS, Track, tierRewards } from "../src/track.mjs";
import { T0, openPlan, play, server, twoPlayers } from "./setup.mjs";

const refusal = (fn, reason) => assert.throws(fn, (e) => e instanceof Refused && e.reason === reason);
const DAY = 24 * 60 * 60 * 1000;

/** A store the tests vouch for: "txn:product[:intent]". */
const verifyReceipt = (store, receipt) => {
  if (store !== "app-store" || typeof receipt !== "string") return null;
  const [transaction, product, intent] = receipt.split(":");
  return { transaction, product, intent };
};

const CATALOGUE = { items: [
  { id: "sky-aurora", kind: "sky_theme", set: "aurora", price: 300 },
  { id: "robe-aurora", kind: "sage_robe", set: "aurora", price: 500 },
  { id: "scout-aurora", kind: "outfit", set: "aurora", price: 200 },
] };

function raid(t, clean = true) {
  const lease = t.service.lease(t.raider.account, t.bundle);
  return t.service.submit(t.raider.account, lease.token,
                          play(t, lease, { plan: clean ? openPlan() : [] }));
}

/** Stars set directly: a test's shortcut to a week of heists. */
function giveStars(t, account, n) {
  const season = t.service.seasons.current().id;
  t.service.db.prepare(
    "INSERT INTO season_stars (season, account, amount, reason, heist, at) VALUES (?, ?, ?, 'test', NULL, ?)")
    .run(season, account, n, t.clock.now);
}

function buyStarglass(t, shop, account, product, n = 1) {
  for (let i = 0; i < n; i++) {
    const { intent } = shop.intent(account, product);
    shop.redeem(account, "app-store", `txn-${account}-${product}-${i}-${t.clock.now}:${product}:${intent}`);
  }
}

test("a heist earns season stars: the raider by its grade, the defender by what it held (18.2)", () => {
  const t = twoPlayers(true);
  const track = new Track(t.service);
  assert.deepEqual(raid(t).stars, { raider: 10, defender: 0 });
  t.clock.now += DAY + 1;
  assert.deepEqual(raid(t, false).stars, { raider: 0, defender: 10 });
  assert.equal(track.stars(t.raider.account), 10);
  assert.equal(track.stars(t.defender.account), 10);
});

test("the track's first tier is free on day one, and each after costs a tier's stars, in order (18.2)", () => {
  const t = twoPlayers(true);
  const track = new Track(t.service);
  const me = t.raider.account;
  const first = track.claim(me, 1);
  assert.deepEqual([first.tier, first.cost], [1, 0]);
  assert.equal(t.service.balance(me).essence, tierRewards(1, 1).free.essence);
  refusal(() => track.claim(me, 1), "not_enough_stars");
  giveStars(t, me, TIER_STARS * 9);
  for (let tier = 2; tier <= 10; tier++) assert.equal(track.claim(me, 1).tier, tier);
  assert.equal(track.stars(me), 0);
  assert.equal(t.service.balance(me).starglass, 25, "tier 10's Starglass");
  assert.deepEqual(track.view(me).tiers[49].free, { stray: 1 }, "the stray at the top");
});

test("a player joining late climbs a track scaled to the time remaining (18.8)", () => {
  const t = twoPlayers(true);
  const track = new Track(t.service);
  assert.equal(track.view(t.raider.account).tierStars, TIER_STARS, "from the first day, the full price");
  t.clock.now = T0 + 5 * 7 * DAY;                     // week 6 begins
  const late = t.service.session("gc:late").account;
  assert.equal(track.view(late).tierStars, Math.round(TIER_STARS * 3 / 8));
});

test("stars reset each season, and an unclaimed tier stays claimable later at the same cost (18.8)", () => {
  const t = twoPlayers(true);
  const track = new Track(t.service);
  const me = t.raider.account;
  track.claim(me, 1);
  giveStars(t, me, 35);
  track.claim(me, 1);                                  // tier 2, 20 stars
  t.clock.now = T0 + SEASON_MS + 1;
  t.service.seasons.rollover();
  assert.equal(track.stars(me), 0, "last season's 15 stars are gone");
  giveStars(t, me, TIER_STARS);
  const old = track.claim(me, 1);                      // season 1's tier 3, from season 2's stars
  assert.deepEqual([old.season, old.tier, old.cost], [1, 3, TIER_STARS]);
  assert.equal(track.view(me, 2).claimed, 0, "season 2's own track is untouched");
});

test("the premium track is bought with Starglass and adds only cosmetics, for tiers already claimed too (18.2)", () => {
  const t = twoPlayers(true);
  const shop = new Shop(t.service, { verifyReceipt });
  const track = new Track(t.service);
  const me = t.raider.account;
  track.claim(me, 1);
  giveStars(t, me, TIER_STARS * 9);
  for (let i = 0; i < 9; i++) track.claim(me, 1);
  refusal(() => track.buyPremium(me, 1), "not_enough_starglass");
  buyStarglass(t, shop, me, "starglass-5");
  buyStarglass(t, shop, me, "starglass-1");
  const bought = track.buyPremium(me, 1);
  assert.deepEqual(bought.granted.map((g) => g.cosmetic), ["track-1-5", "track-1-10"]);
  assert.equal(t.service.balance(me).starglass, 600 + 25 - PREMIUM_PRICE);
  giveStars(t, me, TIER_STARS * 5);
  for (let i = 0; i < 4; i++) assert.equal(track.claim(me, 1).premium, undefined);
  assert.equal(track.claim(me, 1).premium.cosmetic, "track-1-15");
  refusal(() => track.buyPremium(me, 1), "premium_already_owned");
});

test("a Starglass purchase is granted once per store transaction, from a verified receipt (22.1)", () => {
  const t = server();
  const shop = new Shop(t.service, { verifyReceipt });
  const me = t.service.session("gc:buyer").account;
  const { intent, price } = shop.intent(me, "starglass-10");
  assert.equal(price, 1000);
  refusal(() => shop.redeem(me, "app-store", 42), "receipt_refused");
  const first = shop.redeem(me, "app-store", `t1:starglass-10:${intent}`);
  const again = shop.redeem(me, "app-store", `t1:starglass-10:${intent}`);
  assert.deepEqual([first.starglass, again.repeated], [1000, true]);
  assert.equal(t.service.balance(me).starglass, 1000, "paid once");
  const other = t.service.session("gc:other").account;
  refusal(() => shop.redeem(other, "app-store", `t1:starglass-10:${intent}`), "receipt_belongs_to_another_account");
  refusal(() => shop.intent(me, "starglass-7"), "no_such_product");
  // A purchase restored on a new device carries no intent, and is honoured.
  assert.equal(shop.redeem(me, "app-store", "t2:starglass-1").starglass, 100);
});

test("a minor's month is capped, €25 at 13 to 15 and €50 at 16 and 17, and an adult gets a summary (20.2)", () => {
  const t = server();
  const shop = new Shop(t.service, { verifyReceipt });
  const setBand = (account, band) =>
    t.service.db.prepare("UPDATE accounts SET age_band = ? WHERE id = ?").run(band, account);
  const young = t.service.session("gc:young").account;
  setBand(young, "13-15");
  buyStarglass(t, shop, young, "starglass-20");
  shop.intent(young, "starglass-5");                  // held, not yet paid
  refusal(() => shop.intent(young, "starglass-1"), "monthly_cap");
  t.clock.now += 16 * 60 * 1000;                     // the held intent lapses
  shop.intent(young, "starglass-5");
  const teen = t.service.session("gc:teen").account;
  setBand(teen, "16-17");
  buyStarglass(t, shop, teen, "starglass-50");
  refusal(() => shop.intent(teen, "starglass-1"), "monthly_cap");
  t.clock.now = Date.UTC(2026, 9, 1);                 // a new month
  shop.intent(teen, "starglass-1");
  const adult = t.service.session("gc:adult").account;
  buyStarglass(t, shop, adult, "starglass-50", 3);
  assert.deepEqual(shop.summary(adult), { currency: "EUR", months: [{ month: "2026-10", cents: 15000 }], left: null });
});

test("a cosmetic is bought with Starglass at its euro price, owned once, and worn in its slot (22.1)", () => {
  const t = server();
  const shop = new Shop(t.service, { verifyReceipt, catalogue: CATALOGUE });
  const me = t.service.session("gc:dresser").account;
  refusal(() => shop.buy(me, "sky-aurora"), "not_enough_starglass");
  buyStarglass(t, shop, me, "starglass-5");
  shop.buy(me, "sky-aurora");
  refusal(() => shop.buy(me, "sky-aurora"), "already_owned");
  assert.equal(t.service.balance(me).starglass, 200);
  shop.buy(me, "scout-aurora");
  refusal(() => shop.equip(me, { kind: "sage_robe", item: "robe-aurora" }), "not_owned");
  refusal(() => shop.equip(me, { kind: "realm_skin", item: "sky-aurora" }), "wrong_slot");
  refusal(() => shop.equip(me, { kind: "outfit", item: "scout-aurora", target: "nobody" }), "no_such_target");
  shop.equip(me, { kind: "sky_theme", item: "sky-aurora" });
  assert.deepEqual(shop.equip(me, { kind: "outfit", item: "scout-aurora", target: "scout" }),
                   { sky_theme: "sky-aurora", "outfit:scout": "scout-aurora" });
  assert.deepEqual(shop.equip(me, { kind: "sky_theme", item: null }), { "outfit:scout": "scout-aurora" });
});

test("a defender's worn cosmetics travel with the lease, so the raider sees them", () => {
  const t = twoPlayers(true);
  const shop = new Shop(t.service, { verifyReceipt, catalogue: CATALOGUE });
  buyStarglass(t, shop, t.defender.account, "starglass-5");
  shop.buy(t.defender.account, "sky-aurora");
  shop.equip(t.defender.account, { kind: "sky_theme", item: "sky-aurora" });
  assert.deepEqual(t.service.lease(t.raider.account, t.bundle).look, { sky_theme: "sky-aurora" });
});

test("a database made before Starglass keeps its ledger when opened (24.12)", () => {
  const dir = mkdtempSync(join(tmpdir(), "ruleborn-"));
  const path = join(dir, "old.db");
  try {
    const old = new DatabaseSync(path);
    old.exec(`CREATE TABLE accounts (id TEXT PRIMARY KEY, platform_identity TEXT NOT NULL UNIQUE,
                league TEXT NOT NULL DEFAULT 'dust', cosmetics TEXT NOT NULL DEFAULT '[]',
                pass_expires_at INTEGER, keeper_level INTEGER NOT NULL DEFAULT 1, created_at INTEGER NOT NULL);
              CREATE TABLE ledger (id INTEGER PRIMARY KEY AUTOINCREMENT, account TEXT NOT NULL REFERENCES accounts(id),
                currency TEXT NOT NULL CHECK (currency IN ('starlight', 'essence')), amount INTEGER NOT NULL,
                reason TEXT NOT NULL, heist TEXT, at INTEGER NOT NULL);
              CREATE INDEX ledger_by_account ON ledger (account, currency);
              INSERT INTO accounts (id, platform_identity, created_at) VALUES ('a', 'gc:a', 0);
              INSERT INTO ledger (account, currency, amount, reason, at) VALUES ('a', 'starlight', 500, 'old', 0);`);
    old.close();
    const db = open(path);
    db.prepare("INSERT INTO ledger (account, currency, amount, reason, at) VALUES ('a', 'starglass', 100, 'new', 1)").run();
    assert.deepEqual(db.prepare("SELECT currency, amount FROM ledger ORDER BY id").all().map((r) => ({ ...r })),
                     [{ currency: "starlight", amount: 500 }, { currency: "starglass", amount: 100 }]);
    assert.throws(() => db.prepare("DELETE FROM ledger").run(), /append-only/);
    db.close();
  } finally {
    rmSync(dir, { recursive: true, force: true });
  }
});

test("the track, the shop and the wardrobe over HTTP", async () => {
  const t = twoPlayers(true);
  t.service.verifyReceipt = verifyReceipt;
  const call = (method, path, { token, json } = {}) => t.handle(new Request(`https://edge.example${path}`, {
    method,
    headers: { ...(token ? { authorization: `Bearer ${token}` } : {}),
               ...(json ? { "content-type": "application/json" } : {}) },
    body: json ? JSON.stringify(json) : undefined,
  }));
  const token = t.raider.token;
  const view = await (await call("GET", "/v1/track", { token })).json();
  assert.deepEqual([view.season, view.claimed, view.next.cost], [1, 0, 0]);
  const claimed = await (await call("POST", "/v1/track/claim", { token, json: { season: 1 } })).json();
  assert.equal(claimed.tier, 1);
  const intent = await (await call("POST", "/v1/shop/intents", { token, json: { product: "starglass-10" } })).json();
  const paid = await call("POST", "/v1/shop/receipts",
                          { token, json: { store: "app-store", receipt: `h1:starglass-10:${intent.intent}` } });
  assert.equal(paid.status, 201);
  const premium = await (await call("POST", "/v1/track/premium", { token, json: { season: 1 } })).json();
  assert.equal(premium.premium, true);
  const wallet = await (await call("GET", "/v1/balance", { token })).json();
  assert.equal(wallet.starglass, 1000 - PREMIUM_PRICE + 0);
  const summary = await (await call("GET", "/v1/shop/summary", { token })).json();
  assert.equal(summary.months[0].cents, 1000);
  const wardrobe = await (await call("GET", "/v1/cosmetics", { token })).json();
  assert.deepEqual(wardrobe.equipped, {});
  const wrong = await call("POST", "/v1/cosmetics/equip", { token, json: { kind: "sky_theme", item: "nope" } });
  assert.equal(wrong.status, 403);
});
