// Starglass, purchases and cosmetics (§9.1, §20.2, §22.1).
//
// §22.1 sells "Starglass, in packs from about €1 to €50", "the season pass
// premium track (cosmetic), about €6 a season" and cosmetic sets, and never
// resources, power or chance. §19.12: "Every cosmetic shows its real-money
// price. Starglass exists only as a gift and season-pass wrapper, always at a
// visible 1:1 rate." §20.2 caps a month's purchases at €25 for 13 to 15 and
// €50 for 16 and 17, and gives adults a monthly spending summary.
//
// A purchase is two steps, so a minor's cap is kept before the store takes
// any money: an intent, checked against the month and held a quarter of an
// hour, and then the store's receipt, verified and granted once per store
// transaction. Verifying a receipt needs the stores' own services, so
// `verifyReceipt` is injected, as `verifyPlatform` is for sign-in.

import { readFileSync } from "node:fs";

import { transaction } from "./db.mjs";
import { Refused } from "./refused.mjs";
import { PREMIUM_KINDS } from "./track.mjs";

const facts = JSON.parse(readFileSync(new URL("./facts.json", import.meta.url), "utf8"));
const content = (name) => JSON.parse(readFileSync(new URL(`../../content/${name}`, import.meta.url), "utf8"));

/** The Starglass packs, in euros, from §22.1's "about €1 to €50" (G28). */
const [LEAST, MOST] = facts.STARGLASS_PACKS_EUR;
export const PACKS = Object.fromEntries([LEAST, 5, 10, 20, MOST].map((eur) => [`starglass-${eur}`, eur * 100]));

/** How long an intent holds its place under the month's cap. */
export const INTENT_MS = 15 * 60 * 1000;

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

/** Midnight UTC on the first of `ms`'s month. */
const monthStart = (ms) => { const d = new Date(ms); return Date.UTC(d.getUTCFullYear(), d.getUTCMonth(), 1); };
const month = (ms) => new Date(ms).toISOString().slice(0, 7);

export class Shop {
  /** `verifyReceipt(store, receipt)` returns `{transaction, product, intent?}`
   *  for a receipt the store vouches for, or null. */
  constructor(service, { verifyReceipt = () => null, catalogue = CATALOGUE } = {}) {
    this.service = service;
    this.verifyReceipt = verifyReceipt;
    this.items = new Map(catalogue.items.map((i) => [i.id, i]));
  }

  get db() { return this.service.db; }

  // -- the month's cap (§20.2) -----------------------------------------------

  ageBand(account) {
    return this.db.prepare("SELECT age_band FROM accounts WHERE id = ?").get(account).age_band;
  }

  /** What an account may still spend this month, in cents, or null for no
   *  cap. Open intents count until they lapse. */
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

  /** Step one: ask to buy a pack. Refused over a minor's cap, before the
   *  store is asked for anything. */
  intent(account, product) {
    const price = PACKS[product];
    if (!price) throw new Refused(404, "no_such_product");
    const now = this.service.now();
    return transaction(this.db, () => {
      const left = this.allowance(account, now);
      if (left !== null && price > left) {
        throw new Refused(403, "monthly_cap", { left, cap: facts.SPENDING_CAPS_EUR[this.ageBand(account)] * 100 });
      }
      const id = this.service.random(12).toString("hex");
      this.db.prepare(
        "INSERT INTO purchase_intents (id, account, product, price, created_at) VALUES (?, ?, ?, ?, ?)")
        .run(id, account, product, price, now);
      return { intent: id, product, price, expiresAt: now + INTENT_MS };
    });
  }

  /**
   * Step two: the store's receipt. Granted once per store transaction — a
   * retry is answered with the first grant. A receipt the store vouches for
   * is honoured even with no intent (a purchase restored on a new device, or
   * one approved later by a family): the money is already taken.
   */
  redeem(account, store, receipt) {
    const proof = this.verifyReceipt(store, receipt);
    if (!proof) throw new Refused(402, "receipt_refused");
    const now = this.service.now();
    return transaction(this.db, () => {
      const done = this.db.prepare("SELECT * FROM purchases WHERE store = ? AND txn = ?")
        .get(store, proof.transaction);
      if (done) {
        if (done.account !== account) throw new Refused(409, "receipt_belongs_to_another_account");
        return { product: done.product, starglass: done.price, repeated: true };
      }
      const price = PACKS[proof.product];
      if (!price) throw new Refused(404, "no_such_product");
      if (proof.intent) {
        const i = this.db.prepare("SELECT * FROM purchase_intents WHERE id = ?").get(proof.intent);
        if (!i || i.account !== account || i.product !== proof.product) {
          throw new Refused(409, "intent_mismatch");
        }
        this.db.prepare("UPDATE purchase_intents SET redeemed_at = ? WHERE id = ?").run(now, i.id);
      }
      this.db.prepare(
        "INSERT INTO purchases (store, txn, account, product, price, intent, at) VALUES (?, ?, ?, ?, ?, ?, ?)")
        .run(store, proof.transaction, account, proof.product, price, proof.intent ?? null, now);
      this.service.book(account, "starglass", price, `${proof.product} bought (22.1)`, now);
      return { product: proof.product, starglass: price };
    });
  }

  /** §20.2's "monthly spending summary": what was spent, month by month. */
  summary(account) {
    const by = new Map();
    for (const p of this.db.prepare("SELECT price, at FROM purchases WHERE account = ? ORDER BY at").all(account)) {
      by.set(month(p.at), (by.get(month(p.at)) ?? 0) + p.price);
    }
    return { currency: "EUR", months: [...by].map(([m, cents]) => ({ month: m, cents })),
             left: this.allowance(account) };
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
    return null;
  }

  catalogue(account) {
    const owned = new Set(this.owned(account));
    return { items: [...this.items.values()].map((i) => ({ ...i, owned: owned.has(i.id) })),
             owned: [...owned], equipped: this.equipped(account) };
  }

  /** Buy a cosmetic with Starglass at its euro price (§19.12's 1:1). */
  buy(account, id) {
    const item = this.items.get(id);
    if (!item) throw new Refused(404, "no_such_cosmetic");
    const now = this.service.now();
    return transaction(this.db, () => {
      if (this.owned(account).includes(id)) throw new Refused(409, "already_owned");
      this.service.spendStarglass(account, item.price, `${id} bought (22.1)`, now);
      this.service.seasons.grantCosmetic(account, id);
      return this.catalogue(account);
    });
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
