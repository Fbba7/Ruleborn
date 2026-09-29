// The season track (§18.2, §18.8), purchases priced in money with no
// currency, gifts and refunds (§20.2, §22.1, F41, G32), and cosmetics owned
// and worn, against the real simulation build.

import assert from "node:assert/strict";
import { mkdtempSync, rmSync } from "node:fs";
import { tmpdir } from "node:os";
import { join } from "node:path";
import { DatabaseSync } from "node:sqlite";
import { test } from "node:test";

import { open } from "../src/db.mjs";
import { Refused } from "../src/service.mjs";
import { SEASON_MS } from "../src/seasons.mjs";
import { PREMIUM_PRICE, Shop } from "../src/shop.mjs";
import { TIER_STARS, Track, tierRewards } from "../src/track.mjs";
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
  { id: "realm-dawn", kind: "realm_skin", set: "dawn", price: 2000 },
  { id: "bridge-grand", kind: "bridge_style", set: "grand", price: 4900 },
  { id: "wave", kind: "emote", set: "dawn", price: 100 },
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

/** A product bought, both steps: intent, then the store's receipt. */
function buy(t, shop, account, product, { for: friend = null } = {}) {
  const { intent } = shop.intent(account, product, { for: friend });
  return shop.redeem(account, "app-store", `txn-${account}-${product}-${t.clock.now}:${product}:${intent}`);
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
  assert.equal(t.service.balance(me).essence, 4500, "tier 10 gives Essence: there is no Starglass (F41)");
  assert.deepEqual(track.view(me).tiers[49].free, { strayOffer: 1 },
                   "a stray offered for adoption at the top (F38)");
});

test("a player joining late climbs a track scaled to the time remaining (18.8)", () => {
  const t = twoPlayers(true);
  const track = new Track(t.service);
  assert.equal(track.view(t.raider.account).tierStars, TIER_STARS, "from the first day, the full price");
  t.clock.now = T0 + 5 * 7 * DAY;                     // week 6 begins
  const late = t.service.session("gc:late").account;
  assert.equal(track.view(late).tierStars, Math.round(TIER_STARS * 3 / 8));
});

test("an echo raid's stars fix the raider's tier price then, not at their first look late on (18.8)", () => {
  const t = twoPlayers(true);
  t.service.publish(t.defender.account, t.build.exampleIsland(false));   // t.bundle is an echo now
  const lease = t.service.lease(t.raider.account, t.bundle);
  assert.equal(lease.echo, true);
  const out = t.service.submit(t.raider.account, lease.token, play(t, lease, { plan: openPlan() }));
  assert.equal(out.stars.raider, 10);
  t.clock.now = T0 + 54 * DAY;                          // two days left of season 1
  assert.equal(t.service.track.view(t.raider.account).tierStars, TIER_STARS,
               "seen in the season from the day of the raid, at the full price");
});

test("stars reset each season, and an unclaimed tier stays claimable later at the same cost (18.8)", () => {
  const t = twoPlayers(true);
  const track = new Track(t.service);
  const me = t.raider.account;
  track.claim(me, 1);
  giveStars(t, me, TIER_STARS + 15);
  track.claim(me, 1);                                  // tier 2, a tier's stars
  t.clock.now = T0 + SEASON_MS + 1;
  t.service.seasons.rollover();
  assert.equal(track.stars(me), 0, "last season's 15 stars are gone");
  giveStars(t, me, TIER_STARS);
  const old = track.claim(me, 1);                      // season 1's tier 3, from season 2's stars
  assert.deepEqual([old.season, old.tier, old.cost], [1, 3, TIER_STARS]);
  assert.equal(track.view(me, 2).claimed, 0, "season 2's own track is untouched");
});

test("the premium track is a store product and adds only cosmetics, for tiers already claimed too (18.2, F41)", () => {
  const t = twoPlayers(true);
  const shop = new Shop(t.service, { verifyReceipt });
  const track = t.service.track;
  const me = t.raider.account;
  track.claim(me, 1);
  giveStars(t, me, TIER_STARS * 9);
  for (let i = 0; i < 9; i++) track.claim(me, 1);
  assert.equal(shop.intent(me, "premium.1").price, PREMIUM_PRICE);
  // The track names its premium product and price, for the shop to offer.
  assert.deepEqual([track.view(me, 1).premiumProduct, track.view(me, 1).premiumPrice], ["premium.1", PREMIUM_PRICE]);
  refusal(() => shop.intent(me, "premium.2"), "no_such_product", "not a season yet");
  const bought = buy(t, shop, me, "premium.1").granted;
  assert.deepEqual(bought.granted.map((g) => g.cosmetic), ["track-1-5", "track-1-10"]);
  giveStars(t, me, TIER_STARS * 5);
  for (let i = 0; i < 4; i++) assert.equal(track.claim(me, 1).premium, undefined);
  assert.equal(track.claim(me, 1).premium.cosmetic, "track-1-15");
  refusal(() => shop.intent(me, "premium.1"), "already_owned");
  assert.deepEqual(t.service.balance(me), { starlight: 0, essence: t.service.balance(me).essence }, "no balance of money");
});

test("a purchase is granted once per store transaction, from a verified receipt (22.1, F41)", () => {
  const t = server();
  const shop = new Shop(t.service, { verifyReceipt, catalogue: CATALOGUE });
  const me = t.service.session("gc:buyer").account;
  const { intent, price } = shop.intent(me, "robe-aurora");
  assert.equal(price, 500);
  refusal(() => shop.redeem(me, "app-store", 42), "receipt_refused");
  const first = shop.redeem(me, "app-store", `t1:robe-aurora:${intent}`);
  const again = shop.redeem(me, "app-store", `t1:robe-aurora:${intent}`);
  assert.deepEqual([first.granted, first.to, again.repeated], [{ cosmetic: "robe-aurora" }, me, true]);
  assert.deepEqual(shop.owned(me), ["robe-aurora"]);
  const other = t.service.session("gc:other").account;
  refusal(() => shop.redeem(other, "app-store", `t1:robe-aurora:${intent}`), "receipt_belongs_to_another_account");
  refusal(() => shop.intent(me, "starglass-5"), "no_such_product", "there are no packs");
  refusal(() => shop.intent(me, "robe-aurora"), "already_owned");
  // A purchase restored on a new device carries no intent, and is honoured.
  assert.equal(shop.redeem(me, "app-store", "t2:sky-aurora").to, me);
});

test("a gift is the same item bought for a friend, and goes to them (F41)", () => {
  const t = twoPlayers(true);
  const shop = new Shop(t.service, { verifyReceipt, catalogue: CATALOGUE });
  const [me, friend] = [t.raider.account, t.defender.account];
  refusal(() => shop.intent(me, "gift.sky-aurora", { for: friend }), "gifts_go_to_friends");
  t.service.friends.accept(friend, t.service.friends.invite(me).invite);
  refusal(() => shop.intent(me, "gift.sky-aurora"), "gift_needs_a_friend");
  refusal(() => shop.intent(me, "sky-aurora", { for: friend }), "not_a_gift");
  refusal(() => shop.intent(me, "gift.sky-aurora", { for: me }), "own_gift");
  const out = buy(t, shop, me, "gift.sky-aurora", { for: friend });
  assert.deepEqual([out.to, out.granted], [friend, { cosmetic: "sky-aurora" }]);
  assert.deepEqual([shop.owned(friend), shop.owned(me)], [["sky-aurora"], []]);
  refusal(() => shop.intent(me, "gift.sky-aurora", { for: friend }), "already_owned");
  // The buyer can still buy one for themselves: it is the gift's own product.
  assert.equal(buy(t, shop, me, "sky-aurora").to, me);
  // A season's premium track makes a gift too.
  assert.equal(buy(t, shop, me, "gift.premium.1", { for: friend }).granted.premium, true);
  assert.equal(t.service.track.premium(friend, 1), true);
  // It counts against the buyer's month, not the friend's.
  assert.deepEqual(shop.summary(friend).months, []);
});

test("a refund takes the item back from whoever received it, off wherever it was worn, once (G32)", () => {
  const t = twoPlayers(true);
  const shop = new Shop(t.service, { verifyReceipt, catalogue: CATALOGUE });
  const [me, friend] = [t.raider.account, t.defender.account];
  t.service.friends.accept(friend, t.service.friends.invite(me).invite);
  const { intent } = shop.intent(me, "gift.sky-aurora", { for: friend });
  shop.redeem(me, "app-store", `g1:gift.sky-aurora:${intent}`);
  shop.equip(friend, { kind: "sky_theme", item: "sky-aurora" });
  assert.deepEqual(shop.refund("app-store", "g1"), { revoked: { cosmetic: "sky-aurora" }, from: friend });
  assert.deepEqual([shop.owned(friend), shop.equipped(friend)], [[], {}]);
  assert.deepEqual(shop.refund("app-store", "g1"), { repeated: true });
  assert.deepEqual(shop.summary(me).months.map((m) => [m.cents, m.refunded]), [[300, 300]]);
  // A premium track refunded goes with the cosmetics its tiers gave.
  t.service.track.claim(me, 1);
  giveStars(t, me, TIER_STARS * 4);
  for (let i = 0; i < 4; i++) t.service.track.claim(me, 1);
  const { intent: p } = shop.intent(me, "premium.1");
  shop.redeem(me, "app-store", `p1:premium.1:${p}`);
  assert.ok(shop.owned(me).includes("track-1-5"));
  assert.deepEqual(shop.refund("app-store", "p1").revoked, { season: 1, premium: false, revoked: ["track-1-5"] });
  assert.equal(shop.owned(me).includes("track-1-5"), false);
  // Bought again, it grants again.
  assert.deepEqual(buy(t, shop, me, "premium.1").granted.granted.map((g) => g.cosmetic), ["track-1-5"]);
  // A refund for something never granted here is kept, and its receipt refused.
  assert.deepEqual(shop.refund("app-store", "never"), { revoked: null });
  refusal(() => shop.redeem(me, "app-store", "never:robe-aurora"), "receipt_refunded");
});

test("a refund takes back only what no other purchase still gives, and a reversed one gives it back (G32)", () => {
  const t = twoPlayers(true);
  const shop = new Shop(t.service, { verifyReceipt, catalogue: CATALOGUE });
  const [me, friend] = [t.raider.account, t.defender.account];
  t.service.friends.accept(friend, t.service.friends.invite(me).invite);
  // The friend is given the sky, then buys a robe; I give them the robe too
  // before I learn it — the gift's intent was made first.
  const robeGift = shop.intent(me, "gift.robe-aurora", { for: friend }).intent;
  shop.redeem(friend, "app-store", "own-robe:robe-aurora");
  shop.redeem(me, "app-store", `gift-robe:gift.robe-aurora:${robeGift}`);
  // My gift refunded: the robe they paid for themselves stays.
  assert.deepEqual(shop.refund("app-store", "gift-robe"),
                   { revoked: null, from: friend, kept: "another purchase gives it" });
  assert.ok(shop.owned(friend).includes("robe-aurora"));
  // Their own refunded too: now nothing gives it, and it goes.
  assert.deepEqual(shop.refund("app-store", "own-robe"), { revoked: { cosmetic: "robe-aurora" }, from: friend });
  assert.equal(shop.owned(friend).includes("robe-aurora"), false);
  // The store reverses the refund of their own: it is theirs again, once.
  assert.deepEqual(shop.reverseRefund("app-store", "own-robe"), { granted: { cosmetic: "robe-aurora" }, to: friend });
  assert.ok(shop.owned(friend).includes("robe-aurora"));
  assert.deepEqual(shop.reverseRefund("app-store", "own-robe"), { repeated: true });
  assert.equal(shop.refunded("app-store", "own-robe"), false);
  // Refunded again after the reversal, it is taken back again.
  assert.equal(shop.refund("app-store", "own-robe").revoked.cosmetic, "robe-aurora");
  // The same holds for a premium track given and bought.
  const trackGift = shop.intent(me, "gift.premium.1", { for: friend }).intent;
  shop.redeem(friend, "app-store", "own-p1:premium.1");
  shop.redeem(me, "app-store", `gift-p1:gift.premium.1:${trackGift}`);
  assert.equal(shop.refund("app-store", "gift-p1").revoked, null);
  assert.equal(t.service.track.premium(friend, 1), true);
});

test("a gift's receipt after its intent is gone is refused before the store settles it, never given to the buyer (F41, G38)", async () => {
  const t = twoPlayers(true);
  const settled = [];
  const shop = new Shop(t.service, { verifyReceipt, catalogue: CATALOGUE,
                                     settleReceipt: async (store, proof) => { settled.push(proof.transaction); return { ok: true }; } });
  const [me, friend] = [t.raider.account, t.defender.account];
  t.service.friends.accept(friend, t.service.friends.invite(me).invite);
  const kept = shop.intent(me, "gift.sky-aurora", { for: friend }).intent;
  // A gift's lapsed intent is kept a month, as its friend's only record.
  t.clock.now += 8 * DAY;
  t.service.expireLapsed();
  assert.ok(t.service.db.prepare("SELECT 1 FROM purchase_intents WHERE id = ?").get(kept));
  assert.equal((await shop.claim(me, "app-store", `late:gift.sky-aurora:${kept}`)).to, friend);
  const gone = shop.intent(me, "gift.wave", { for: friend }).intent;
  t.clock.now += 31 * DAY;
  t.service.expireLapsed();
  assert.equal(t.service.db.prepare("SELECT 1 FROM purchase_intents WHERE id = ?").get(gone), undefined);
  await assert.rejects(shop.claim(me, "app-store", `later:gift.wave:${gone}`), (e) => e.reason === "gift_intent_gone");
  assert.deepEqual(settled, ["late"], "not consumed");
  assert.equal(shop.owned(me).includes("wave"), false);
});

test("a minor's month is capped, €25 at 13 to 15 and €50 at 16 and 17, and an adult gets a summary (20.2)", () => {
  const t = server();
  const shop = new Shop(t.service, { verifyReceipt, catalogue: CATALOGUE });
  const setBand = (account, band) =>
    t.service.db.prepare("UPDATE accounts SET age_band = ? WHERE id = ?").run(band, account);
  const young = t.service.session("gc:young").account;
  setBand(young, "13-15");
  buy(t, shop, young, "realm-dawn");
  shop.intent(young, "robe-aurora");                  // held, not yet paid
  refusal(() => shop.intent(young, "wave"), "monthly_cap");
  t.clock.now += 16 * 60 * 1000;                     // the held intent lapses
  shop.intent(young, "robe-aurora");
  const teen = t.service.session("gc:teen").account;
  setBand(teen, "16-17");
  buy(t, shop, teen, "bridge-grand");
  refusal(() => shop.intent(teen, "sky-aurora"), "monthly_cap");
  t.clock.now = Date.UTC(2026, 9, 1);                 // a new month
  shop.intent(teen, "sky-aurora");
  const adult = t.service.session("gc:adult").account;
  for (const item of ["bridge-grand", "realm-dawn", "wave"]) buy(t, shop, adult, item);
  assert.deepEqual(shop.summary(adult), { currency: "EUR", months: [{ month: "2026-10", cents: 7000, refunded: 0 }],
                                          left: null });
});

test("a cosmetic is bought at its money price, owned once, and worn in its slot (22.1, F41)", () => {
  const t = server();
  const shop = new Shop(t.service, { verifyReceipt, catalogue: CATALOGUE });
  const me = t.service.session("gc:dresser").account;
  assert.deepEqual(shop.catalogue(me).items[0], { id: "sky-aurora", kind: "sky_theme", set: "aurora", price: 300,
                                                  product: "sky-aurora", gift: "gift.sky-aurora", owned: false });
  buy(t, shop, me, "sky-aurora");
  refusal(() => shop.intent(me, "sky-aurora"), "already_owned");
  buy(t, shop, me, "scout-aurora");
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
  buy(t, shop, t.defender.account, "sky-aurora");
  shop.equip(t.defender.account, { kind: "sky_theme", item: "sky-aurora" });
  assert.deepEqual(t.service.lease(t.raider.account, t.bundle).look, { sky_theme: "sky-aurora" });
});

test("a database made while there was Starglass opens without it: its Starglass rows go, the rest stay (F41)", () => {
  const dir = mkdtempSync(join(tmpdir(), "ruleborn-"));
  const path = join(dir, "starglass.db");
  try {
    const old = new DatabaseSync(path);
    old.exec(`CREATE TABLE accounts (id TEXT PRIMARY KEY, platform_identity TEXT NOT NULL UNIQUE,
                league TEXT NOT NULL DEFAULT 'dust', cosmetics TEXT NOT NULL DEFAULT '[]',
                pass_expires_at INTEGER, keeper_level INTEGER NOT NULL DEFAULT 1, created_at INTEGER NOT NULL);
              CREATE TABLE ledger (id INTEGER PRIMARY KEY AUTOINCREMENT, account TEXT NOT NULL REFERENCES accounts(id),
                currency TEXT NOT NULL CHECK (currency IN ('starlight', 'essence', 'starglass')), amount INTEGER NOT NULL,
                reason TEXT NOT NULL, heist TEXT, at INTEGER NOT NULL);
              INSERT INTO accounts (id, platform_identity, created_at) VALUES ('a', 'gc:a', 0);
              INSERT INTO ledger (account, currency, amount, reason, at) VALUES ('a', 'starlight', 500, 'old', 0);
              INSERT INTO ledger (account, currency, amount, reason, at) VALUES ('a', 'starglass', 1000, 'pack', 0);
              INSERT INTO ledger (account, currency, amount, reason, at) VALUES ('a', 'essence', 7, 'old', 0);`);
    old.close();
    const db = open(path);
    assert.deepEqual(db.prepare("SELECT id, starlight, essence FROM ledger ORDER BY id").all().map((r) => ({ ...r })),
                     [{ id: 1, starlight: 500, essence: 0 }, { id: 3, starlight: 0, essence: 7 }]);
    assert.throws(() => db.prepare(
      "INSERT INTO ledger (account, starglass, reason, at) VALUES ('a', 1, 'new', 1)").run(), /no column/);
    assert.throws(() => db.prepare("DELETE FROM ledger").run(), /append-only/);
    db.close();
  } finally {
    rmSync(dir, { recursive: true, force: true });
  }
});

test("an upgrade stopped part-way leaves the old ledger and events whole, and the next one finishes (24.12)", () => {
  const dir = mkdtempSync(join(tmpdir(), "ruleborn-"));
  const path = join(dir, "old.db");
  try {
    const old = new DatabaseSync(path);
    old.exec(`CREATE TABLE accounts (id TEXT PRIMARY KEY, platform_identity TEXT NOT NULL UNIQUE,
                league TEXT NOT NULL DEFAULT 'dust', cosmetics TEXT NOT NULL DEFAULT '[]',
                pass_expires_at INTEGER, keeper_level INTEGER NOT NULL DEFAULT 1, created_at INTEGER NOT NULL);
              CREATE TABLE ledger (id INTEGER PRIMARY KEY AUTOINCREMENT, account TEXT NOT NULL REFERENCES accounts(id),
                currency TEXT NOT NULL CHECK (currency IN ('starlight', 'essence', 'starglass')), amount INTEGER NOT NULL,
                reason TEXT NOT NULL, heist TEXT, at INTEGER NOT NULL);
              CREATE INDEX ledger_by_account ON ledger (account, currency);
              INSERT INTO accounts (id, platform_identity, created_at) VALUES ('a', 'gc:a', 0);
              INSERT INTO ledger (account, currency, amount, reason, at) VALUES ('a', 'starlight', 500, 'old', 0);
              CREATE TABLE events (id INTEGER PRIMARY KEY AUTOINCREMENT, who TEXT NOT NULL, kind TEXT NOT NULL,
                data TEXT NOT NULL, at INTEGER NOT NULL, day TEXT NOT NULL);
              INSERT INTO events (who, kind, data, at, day) VALUES ('p', 'session', '{}', 0, '1970-01-01');
              PRAGMA foreign_keys = OFF;
              INSERT INTO ledger (account, currency, amount, reason, at) VALUES ('b', 'essence', 7, 'old', 0);`);
    old.close();
    // An upgrade stopped part-way — here the copy throws, on a row whose
    // account is missing — leaves the old shape whole, not an empty ledger.
    assert.throws(() => open(path), /FOREIGN KEY/);
    const kept = new DatabaseSync(path);
    const tables = kept.prepare("SELECT name FROM sqlite_master WHERE type = 'table'").all().map((r) => r.name);
    assert.deepEqual([tables.includes("ledger_by_currency"), tables.includes("events_before_batches"),
                      kept.prepare("SELECT COUNT(*) AS n FROM ledger").get().n,
                      kept.prepare("SELECT COUNT(*) AS n FROM events").get().n], [false, false, 2, 1]);
    kept.exec("INSERT INTO accounts (id, platform_identity, created_at) VALUES ('b', 'gc:b', 0)");
    kept.close();
    const db = open(path);
    assert.deepEqual(db.prepare("SELECT starlight, essence FROM ledger ORDER BY id").all().map((r) => ({ ...r })),
                     [{ starlight: 500, essence: 0 }, { starlight: 0, essence: 7 }]);
    assert.equal(db.prepare("SELECT COUNT(*) AS n FROM events WHERE who = 'p'").get().n, 1);
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
  const intent = await (await call("POST", "/v1/shop/intents", { token, json: { product: "premium.1" } })).json();
  const paid = await call("POST", "/v1/shop/receipts",
                          { token, json: { store: "app-store", receipt: `h1:premium.1:${intent.intent}` } });
  assert.equal(paid.status, 201);
  assert.equal((await paid.json()).granted.premium, true);
  assert.equal((await call("POST", "/v1/track/premium", { token, json: { season: 1 } })).status, 404,
               "no buying with a currency: there is none");
  const wallet = await (await call("GET", "/v1/balance", { token })).json();
  assert.deepEqual(Object.keys(wallet), ["starlight", "essence"]);
  const summary = await (await call("GET", "/v1/shop/summary", { token })).json();
  assert.equal(summary.months[0].cents, PREMIUM_PRICE);
  const gift = await call("POST", "/v1/shop/intents", { token, json: { product: "gift.premium.1", for: t.defender.account } });
  assert.deepEqual([gift.status, (await gift.json()).error], [403, "gifts_go_to_friends"]);
  const wardrobe = await (await call("GET", "/v1/cosmetics", { token })).json();
  assert.deepEqual(wardrobe.equipped, {});
  const wrong = await call("POST", "/v1/cosmetics/equip", { token, json: { kind: "sky_theme", item: "nope" } });
  assert.equal(wrong.status, 403);
});
