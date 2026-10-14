// Purchases, gifts, refunds and cosmetics (§19.12, §20.2, §22.1).
//
// §22.1 sells "the season pass premium track (cosmetic), about €6 a season"
// and cosmetic sets, and never resources, power or chance. §19.12: "Every
// cosmetic shows its real-money price. Starglass exists only as a gift and
// season-pass wrapper". The owner's answer to F41: there is no currency.
// Every cosmetic and each season's premium track is its own store product at
// the store's price; there is no balance and there are no packs. A gift is
// the same product bought for a friend — its own consumable product, since a
// store sells an item its buyer already owns only once — and Starglass
// survives only as the wrapper a gift arrives in, which is the device's.
// §20.2 caps a month's purchases at €25 for 13 to 15 and €50 for 16 and 17,
// and gives adults a monthly spending summary.
//
// A purchase is two steps, so a minor's cap is kept before the store takes
// any money: an intent, checked against the month and held a quarter of an
// hour, and then the store's receipt, verified and granted once per store
// transaction. Verifying a receipt needs the stores' own services, so
// `verifyReceipt` is injected, as `verifyPlatform` is for sign-in.
//
// G32, answered through F41's: when a store reports a refund, the product's
// entitlement is taken back — the cosmetic, or the season's premium track
// and what it granted — once per transaction, from whoever received it,
// unless another purchase not refunded still gives them the same (a gift of
// what they also bought). A refund the store reverses gives it back.

import { readFileSync } from "node:fs";

import { transaction } from "./db.mjs";
import { Refused } from "./refused.mjs";
import { PREMIUM_KINDS } from "./track.mjs";

const facts = JSON.parse(readFileSync(new URL("./facts.json", import.meta.url), "utf8"));
const content = (name) => JSON.parse(readFileSync(new URL(`../../content/${name}`, import.meta.url), "utf8"));

/** How long an intent holds its place under the month's cap. */
export const INTENT_MS = 15 * 60 * 1000;

/** How long a gift's lapsed intent is kept: it alone names the friend, and
 *  a store can send its receipt late (G38, F41). */
export const GIFT_KEEP_DAYS = 30;

/** A season's premium track, in euro cents: §22.1's "about €6 a season". */
export const PREMIUM_PRICE = facts.PREMIUM_TRACK_EUR * 100;

/** Store product ids: a season's premium track, and a gift of a product. */
const PREMIUM = /^premium\.([1-9]\d{0,3})$/;
export const GIFT = "gift.";

/** The cosmetic kinds: §22.1's list. Emotes are used, not worn, so they have
 *  no slot; outfits are worn by a crew role and law visuals by a law (G28). */
export const KINDS = [...PREMIUM_KINDS, "emote"];
const TARGETS = {
  outfit: new Set(content("roles.json").map((r) => r.id)),
  law_visual: new Set(content("laws.json").map((l) => l.id)),
};

/** The catalogue: no cosmetic set is authored yet (D64), so it ships empty
 *  and the tests bring their own. */
export const CATALOGUE = JSON.parse(readFileSync(new URL("./cosmetics.json", import.meta.url), "utf8"));

/** Sixteen random bytes as a version-4 UUID: StoreKit's appAccountToken is
 *  one, so an intent's id can ride the purchase and come back signed. */
export function uuid(bytes) {
  const b = Buffer.from(bytes);
  b[6] = (b[6] & 0x0f) | 0x40;
  b[8] = (b[8] & 0x3f) | 0x80;
  const h = b.toString("hex");
  return `${h.slice(0, 8)}-${h.slice(8, 12)}-${h.slice(12, 16)}-${h.slice(16, 20)}-${h.slice(20, 32)}`;
}

/** Midnight UTC on the first of `ms`'s month. */
const monthStart = (ms) => { const d = new Date(ms); return Date.UTC(d.getUTCFullYear(), d.getUTCMonth(), 1); };
const month = (ms) => new Date(ms).toISOString().slice(0, 7);

export class Shop {
  /** `verifyReceipt(store, receipt)` returns `{transaction, product, intent?}`
   *  for a receipt the store vouches for, or null. */
  constructor(service, { verifyReceipt = () => null, settleReceipt = async () => ({ ok: true }),
                         catalogue = CATALOGUE } = {}) {
    this.service = service;
    this.verifyReceipt = verifyReceipt;
    this.settleReceipt = settleReceipt;
    this.items = new Map(catalogue.items.map((i) => [i.id, i]));
  }

  get db() { return this.service.db; }

  // -- products (F41) ----------------------------------------------------------

  /**
   * What a store product id sells: a catalogue cosmetic by its id, a
   * season's premium track as "premium.N" (this season or any before it:
   * "nothing expires forever", §18.8), and either as a gift, "gift." before
   * it. Null for none.
   */
  product(id) {
    if (typeof id !== "string") return null;
    const gift = id.startsWith(GIFT);
    const base = gift ? id.slice(GIFT.length) : id;
    const item = this.items.get(base);
    if (item) return { id, gift, kind: "cosmetic", item: base, price: item.price };
    const premium = PREMIUM.exec(base);
    if (premium && Number(premium[1]) <= this.service.seasons.current().id) {
      return { id, gift, kind: "premium", season: Number(premium[1]), price: PREMIUM_PRICE };
    }
    return null;
  }

  /** Whether `account` already has what a product grants. */
  has(account, p) {
    return p.kind === "cosmetic" ? this.owned(account).includes(p.item)
      : this.service.track.premium(account, p.season);
  }

  // -- the month's cap (§20.2) -----------------------------------------------

  ageBand(account) {
    return this.db.prepare("SELECT age_band FROM accounts WHERE id = ?").get(account).age_band;
  }

  /** What an account may still spend this month, in cents, or null for no
   *  cap. Open intents count until they lapse; a refunded purchase still
   *  counts, as it was spent that month. */
  allowance(account, now = this.service.now()) {
    const cap = facts.SPENDING_CAPS_EUR[this.ageBand(account)];
    if (cap === undefined) return null;
    const spent = Number(this.db.prepare(
      "SELECT COALESCE(SUM(price), 0) AS n FROM purchases WHERE account = ? AND at >= ?")
      .get(account, monthStart(now)).n);
    const held = Number(this.db.prepare(
      `SELECT COALESCE(SUM(price), 0) AS n FROM purchase_intents
        WHERE account = ? AND redeemed_at IS NULL AND created_at > ?`)
      .get(account, now - INTENT_MS).n);
    return Math.max(0, cap * 100 - spent - held);
  }

  /**
   * Step one: ask to buy a product, for oneself or, as a gift, for a friend
   * (`for`). Refused over a minor's cap, before the store is asked for
   * anything, and refused for what the one it is for already has.
   */
  intent(account, productId, { for: recipient = null } = {}) {
    const p = this.product(productId);
    if (!p) throw new Refused(404, "no_such_product");
    if (p.gift !== (recipient !== null)) throw new Refused(400, p.gift ? "gift_needs_a_friend" : "not_a_gift");
    if (p.gift) {
      if (recipient === account) throw new Refused(400, "own_gift");
      const to = this.db.prepare("SELECT deleted_at, banned_at FROM accounts WHERE id = ?").get(recipient);
      if (!to || to.deleted_at || to.banned_at || !this.service.friends.areFriends(account, recipient)) {
        throw new Refused(403, "gifts_go_to_friends");
      }
    }
    if (this.has(recipient ?? account, p)) throw new Refused(409, "already_owned");
    const now = this.service.now();
    return transaction(this.db, () => {
      const left = this.allowance(account, now);
      if (left !== null && p.price > left) {
        throw new Refused(403, "monthly_cap", { left, cap: facts.SPENDING_CAPS_EUR[this.ageBand(account)] * 100 });
      }
      const id = uuid(this.service.random(16));
      this.db.prepare(
        `INSERT INTO purchase_intents (id, account, product, price, created_at, recipient)
           VALUES (?, ?, ?, ?, ?, ?)`)
        .run(id, account, productId, p.price, now, recipient);
      return { intent: id, product: productId, price: p.price, expiresAt: now + INTENT_MS,
               ...(recipient ? { for: recipient } : {}) };
    });
  }

  /**
   * Step two: the store's receipt. Granted once per store transaction — a
   * retry is answered with the first grant. A receipt the store vouches for
   * is honoured even with no intent (a purchase restored on a new device, or
   * one approved later by a family): the money is already taken, and it is
   * the buyer's own. A gift goes to the friend its intent names. A
   * transaction the store has already refunded is refused.
   */
  redeem(account, store, receipt, checked = null) {
    const proof = checked ?? this.verifyReceipt(store, receipt);
    if (!proof) throw new Refused(402, "receipt_refused");
    const now = this.service.now();
    return transaction(this.db, () => {
      const done = this.db.prepare("SELECT * FROM purchases WHERE store = ? AND txn = ?")
        .get(store, proof.transaction);
      if (done) {
        if (done.account !== account) throw new Refused(409, "receipt_belongs_to_another_account");
        return { product: done.product, to: done.recipient ?? done.account, repeated: true };
      }
      if (this.refunded(store, proof.transaction)) throw new Refused(402, "receipt_refunded");
      const p = this.product(proof.product);
      if (!p) throw new Refused(404, "no_such_product");
      const i = this.intentOf(proof);
      if (i) {
        if (i.account !== account || i.product !== proof.product) throw new Refused(409, "intent_mismatch");
        this.db.prepare("UPDATE purchase_intents SET redeemed_at = ? WHERE id = ?").run(now, i.id);
      }
      // A friend deleted since is owed nothing: the gift is the buyer's.
      const friend = i?.recipient && !this.db.prepare("SELECT deleted_at FROM accounts WHERE id = ?")
        .get(i.recipient).deleted_at ? i.recipient : null;
      const to = friend ?? account;
      this.db.prepare(
        `INSERT INTO purchases (store, txn, account, product, price, intent, at, recipient)
           VALUES (?, ?, ?, ?, ?, ?, ?, ?)`)
        .run(store, proof.transaction, account, proof.product, p.price, i ? i.id : null, now, friend);
      const granted = this.grant(to, p, now);
      this.service.telemetry.record(account, "purchase", { product: proof.product, cents: p.price }, now);
      return { product: proof.product, to, granted };
    });
  }

  /**
   * A receipt's intent. An intent that lapsed a week ago is deleted (G38):
   * its receipt, arriving later still, is honoured as one with none, as a
   * restore is — except a gift's, kept GIFT_KEEP_DAYS, whose friend only its
   * intent names: after that it is refused unsettled, so Play refunds it by
   * itself and an App Store one is left unfinished for the player to ask
   * Apple for their money, rather than given to the buyer who meant it for
   * someone else.
   */
  intentOf(proof) {
    const i = proof.intent
      ? this.db.prepare("SELECT * FROM purchase_intents WHERE id = ?").get(proof.intent) : null;
    if (!i && typeof proof.product === "string" && proof.product.startsWith(GIFT)) {
      throw new Refused(409, "gift_intent_gone");
    }
    return i ?? null;
  }

  /** What a product gives, to whom it goes: a cosmetic owned, or a season's
   *  premium track and its rewards for tiers already claimed. One already
   *  had — a gift of what the friend has bought since — gives nothing more. */
  grant(account, p, now) {
    if (p.kind === "cosmetic") {
      this.service.seasons.grantCosmetic(account, p.item);
      return { cosmetic: p.item };
    }
    return this.service.track.grantPremium(account, p.season, now);
  }

  /**
   * A receipt as the edge takes it: checked, then settled with its store
   * where the store must be asked — a Play purchase is looked up and
   * acknowledged, or consumed if it is a gift, before it is granted
   * (googleapi.mjs) — then granted once. One already granted is answered
   * from its grant without asking again.
   */
  async claim(account, store, receipt) {
    const proof = this.verifyReceipt(store, receipt);
    if (!proof) throw new Refused(402, "receipt_refused");
    const done = this.db.prepare("SELECT 1 FROM purchases WHERE store = ? AND txn = ?").get(store, proof.transaction);
    if (!done) {
      // Refused before the store is told anything, so nothing is consumed.
      if (this.refunded(store, proof.transaction)) throw new Refused(402, "receipt_refunded");
      this.intentOf(proof);
      const settled = await this.settleReceipt(store, proof);
      if (!settled?.ok) {
        const reason = settled?.reason ?? "receipt_refused";
        throw new Refused(reason === "store_unavailable" ? 503 : 402, "receipt_refused", { why: reason });
      }
    }
    return this.redeem(account, store, receipt, proof);
  }

  // -- refunds (G32) -----------------------------------------------------------

  /** Whether a transaction is refunded now: its latest refund event is a
   *  refund, not a reversal of one. */
  refunded(store, txn) {
    return this.db.prepare("SELECT kind FROM refunds WHERE store = ? AND txn = ? ORDER BY id DESC LIMIT 1")
      .get(store, txn)?.kind === "refund";
  }

  /** Who a purchase went to: the friend of a gift, else its buyer. */
  receiver(bought) {
    return bought.recipient ?? bought.account;
  }

  /** Whether a purchase other than `bought`, not refunded, gives its
   *  receiver the same thing: their own, or another friend's gift. */
  backedElsewhere(bought) {
    const who = this.receiver(bought);
    const base = (id) => (id.startsWith(GIFT) ? id.slice(GIFT.length) : id);
    return this.db.prepare(
      "SELECT store, txn, product, account, recipient FROM purchases WHERE account = ?1 OR recipient = ?1").all(who)
      .some((o) => (o.store !== bought.store || o.txn !== bought.txn) && this.receiver(o) === who
        && base(o.product) === base(bought.product) && !this.refunded(o.store, o.txn));
  }

  /**
   * A refund or revocation a store reported: the purchase's entitlement
   * taken back from whoever received it, once per refund — unless another
   * purchase not refunded still gives them the same. A refund for a
   * transaction not granted here is recorded, so its receipt arriving later
   * is refused. Returns what was done.
   */
  refund(store, txn, now = this.service.now()) {
    return transaction(this.db, () => {
      if (this.refunded(store, txn)) return { repeated: true };
      this.db.prepare("INSERT INTO refunds (store, txn, kind, at) VALUES (?, ?, 'refund', ?)").run(store, txn, now);
      const bought = this.db.prepare("SELECT * FROM purchases WHERE store = ? AND txn = ?").get(store, txn);
      const p = bought && this.product(bought.product);
      if (!p) return { revoked: null };
      const from = this.receiver(bought);
      if (this.backedElsewhere(bought)) return { revoked: null, from, kept: "another purchase gives it" };
      if (p.kind === "cosmetic") {
        this.revokeCosmetic(from, p.item);
        return { revoked: { cosmetic: p.item }, from };
      }
      return { revoked: this.service.track.revokePremium(from, p.season), from };
    });
  }

  /** A refund the store reversed (Apple's REFUND_REVERSED): the purchase
   *  stands again, and what it gives is given back. Once per refund. */
  reverseRefund(store, txn, now = this.service.now()) {
    return transaction(this.db, () => {
      if (!this.refunded(store, txn)) return { repeated: true };
      this.db.prepare("INSERT INTO refunds (store, txn, kind, at) VALUES (?, ?, 'reversal', ?)").run(store, txn, now);
      const bought = this.db.prepare("SELECT * FROM purchases WHERE store = ? AND txn = ?").get(store, txn);
      const p = bought && this.product(bought.product);
      if (!p) return { granted: null };
      const to = this.receiver(bought);
      const gone = this.db.prepare("SELECT deleted_at FROM accounts WHERE id = ?").get(to)?.deleted_at;
      return { granted: gone ? null : this.grant(to, p, now), to };
    });
  }

  /** G32's daily check of Play: every purchase Google has voided in the
   *  30 days its API keeps, taken back; one already taken back is not
   *  twice. `play` is googleapi.mjs's PlayPurchases. */
  async voided(play, now = this.service.now()) {
    const tokens = await play.voided(now - 30 * 24 * 60 * 60 * 1000);
    return tokens.map((txn) => this.refund("google-play", txn, now)).filter((r) => !r.repeated).length;
  }

  /** A cosmetic no longer owned, and taken off wherever it was worn. */
  revokeCosmetic(account, id) {
    const owned = this.owned(account).filter((c) => c !== id);
    const worn = Object.fromEntries(Object.entries(this.equipped(account)).filter(([, item]) => item !== id));
    this.db.prepare("UPDATE accounts SET cosmetics = ?, equipped = ? WHERE id = ?")
      .run(JSON.stringify(owned), JSON.stringify(worn), account);
  }

  /** §20.2's "monthly spending summary": what was spent, month by month,
   *  and how much of it the stores refunded. */
  summary(account) {
    const by = new Map();
    for (const p of this.db.prepare(
      `SELECT p.price, p.at, (SELECT kind FROM refunds r WHERE r.store = p.store AND r.txn = p.txn
                               ORDER BY r.id DESC LIMIT 1) = 'refund' AS refunded FROM purchases p
        WHERE p.account = ? ORDER BY p.at`).all(account)) {
      const m = month(p.at);
      if (!by.has(m)) by.set(m, { month: m, cents: 0, refunded: 0 });
      by.get(m).cents += p.price;
      if (p.refunded) by.get(m).refunded += p.price;
    }
    return { currency: "EUR", months: [...by.values()], left: this.allowance(account) };
  }

  // -- cosmetics ---------------------------------------------------------------

  owned(account) {
    return JSON.parse(this.db.prepare("SELECT cosmetics FROM accounts WHERE id = ?").get(account).cosmetics);
  }

  equipped(account) {
    return JSON.parse(this.db.prepare("SELECT equipped FROM accounts WHERE id = ?").get(account).equipped);
  }

  /** A cosmetic's kind: the catalogue's, or read from an earned one's id — a
   *  track tier's is its tier's kind, and a league's season-end cosmetic is
   *  a realm skin, the one raiders see (G28). */
  kindOf(id) {
    if (this.items.has(id)) return this.items.get(id).kind;
    const track = /^track-\d+-(\d+)$/.exec(id);
    if (track) return PREMIUM_KINDS[(Number(track[1]) / 5 - 1) % PREMIUM_KINDS.length];
    if (/^season-\d+-[a-z]+$/.test(id)) return "realm_skin";
    // §19.20's free outfit with the first hatch (home.mjs).
    if (id === "hatch-outfit") return "outfit";
    return null;
  }

  /** The catalogue, each item with its two store products and its
   *  real-money price (§19.12), what is owned and what is worn. */
  catalogue(account) {
    const owned = new Set(this.owned(account));
    return { items: [...this.items.values()].map((i) => ({ ...i, product: i.id, gift: `${GIFT}${i.id}`,
                                                           owned: owned.has(i.id) })),
             owned: [...owned], equipped: this.equipped(account) };
  }

  /**
   * Wear an owned cosmetic in its slot, or empty a slot with `item` null.
   * One of each kind, except an outfit a crew role wears and a law's visual,
   * one per role and per law. It is applied server-side so that a raider sees
   * the defender's choices with the lease (§22.1's "previews on your
   * universe" are the device's).
   */
  equip(account, { kind, item = null, target = null }) {
    if (!KINDS.includes(kind) || kind === "emote") throw new Refused(400, "no_such_slot");
    const targeted = TARGETS[kind];
    if (targeted ? !targeted.has(target) : target !== null) throw new Refused(400, "no_such_target");
    if (item !== null) {
      if (!this.owned(account).includes(item)) throw new Refused(403, "not_owned");
      if (this.kindOf(item) !== kind) throw new Refused(400, "wrong_slot");
    }
    const slot = targeted ? `${kind}:${target}` : kind;
    const now = this.equipped(account);
    if (item === null) delete now[slot];
    else now[slot] = item;
    this.db.prepare("UPDATE accounts SET equipped = ? WHERE id = ?").run(JSON.stringify(now), account);
    return now;
  }
}
