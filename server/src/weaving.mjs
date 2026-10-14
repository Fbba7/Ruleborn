// What is woven, kept on the server (§5.1, §5.5, §5.6): a home economy slice
// of TC.12.
//
// §5.6: "Laws are woven into slots at the Keeper's Spire: 10 minutes at tier
// I, 40 minutes at tier II and 2 hours at tier III. Weaving costs 40 Aether
// per point of the law's stability cost. While a slot is being woven it is
// empty. Removing a law is instant, but the slot then rests for an hour
// before it can be woven again." §5.1: "A crown law works in every realm of
// its universe, including the Heart, and costs double stability. The Spire
// opens 1 crown slot at Spire level 2 and a second at Spire level 5. … The
// same law can't be both a crown law and a realm law in one universe."
//
// A realm has §5.2's law slots for its level, the Heart those of realm level
// 3 (G19); the crown's slots are kept as the realm "crown". A law is woven at
// the tier the Codex has restored it to (codex.mjs), and only once it is
// restored; a realm weaves a law once, as the island does (island.rs).
//
// The price is §5.5's cost of the law where it would be woven, at §5.6's 40
// Aether a point: base × tier × 2 if crowned × 0.8 in a realm of its school,
// and the terms that depend on the realm's other laws — harmonies,
// resonances, chords, dissonances — and the week's era, all priced by the
// simulation's one function (TD.14, sim/src/stability.rs), which the client
// prices with too. What is in a slot counts, woven or still weaving. Upkeep,
// Breaking's "no new weaving" and the tier rise in place are TD.37's. The
// first session's instant weaves are the tutorial's (§16).
//
// What is woven is what home.mjs reads: §9.3's "1 + 0.10 per realm law of a
// matching school + 0.05 per matching crown law", and §11.5's births "3 for
// each law woven in its realm, 2 for the realm's own school and 1 for each
// crown law". A law counts from when its weaving finishes.

import { readFileSync } from "node:fs";

import { transaction } from "./db.mjs";
import { Refused } from "./refused.mjs";
import { HEART_LEVEL } from "./service.mjs";

const facts = JSON.parse(readFileSync(new URL("./facts.json", import.meta.url), "utf8"));
const LAWS = Object.fromEntries(JSON.parse(readFileSync(new URL("../../content/laws.json", import.meta.url), "utf8"))
  .map((l) => [l.id, l]));
const MINUTE = 60_000;

/** The crown's slots, kept as a realm of their own. */
export const CROWN = "crown";

/** The Anchor Stone, the building §5.5's capacity counts beside the Spire. */
const ANCHOR = "anchor_stone";

/** A realm's index in the simulation's universe: 0 the Heart, k outer realm
 *  k, the crown its own. */
const realmIndex = (realm) => (realm === CROWN ? "crown" : realm === "heart" ? 0 : Number(realm.split("-")[1]));

/** §5.2's realm types' schools: the Heart has none. */
const schoolOfType = (type) => facts.SCHOOLS[facts.REALM_TYPES.indexOf(type)];

export class Weaving {
  constructor(service) {
    this.service = service;
  }

  get db() { return this.service.db; }
  get universe() { return this.service.universe; }

  /** How many law slots `realm` has: §5.2's for its level, the Heart's at
   *  realm level 3, and the crown's by the Spire (§5.1). */
  slots(account, realm) {
    if (realm === CROWN) return facts.CROWN_SLOT_SPIRE.filter((s) => this.universe.spire(account) >= s).length;
    const r = this.universe.realms(account).find((x) => x.realm === realm);
    if (!r) return 0;
    return facts.LAW_SLOTS[(realm === "heart" ? HEART_LEVEL : r.level) - 1];
  }

  /** Every slot kept, woven, weaving or resting: {realm, slot, law, tier,
   *  ready_at, rests_until}. */
  rows(account) {
    return this.db.prepare(
      "SELECT realm, slot, law, tier, ready_at, rests_until FROM law_slots WHERE owner = ? ORDER BY realm, slot")
      .all(account);
  }

  /** The tier the Codex has `law` restored to, 0 if it is not (codex.mjs). */
  tierOf(account, law) {
    this.service.codex.ensure(account, this.service.now());
    return this.db.prepare("SELECT tier FROM codex WHERE owner = ? AND law = ?").get(account, law)?.tier ?? 0;
  }

  /** Every law the Codex has restored, with its tier. */
  restored(account) {
    this.service.codex.ensure(account, this.service.now());
    return this.db.prepare("SELECT law, tier FROM codex WHERE owner = ? AND tier > 0 ORDER BY law").all(account);
  }

  /** The laws working now, by realm: woven, and their weaving finished. */
  working(account, now = this.service.now()) {
    const out = {};
    for (const r of this.rows(account)) {
      if (r.law && r.ready_at <= now) (out[r.realm] ??= []).push({ law: r.law, tier: r.tier });
    }
    return out;
  }

  /** When a weaving finishes between `from` and `to`, in order: where a
   *  producer's laws change (home.mjs). */
  finishing(account, from, to) {
    return this.db.prepare(
      `SELECT DISTINCT ready_at FROM law_slots
        WHERE owner = ? AND law IS NOT NULL AND ready_at > ? AND ready_at < ? ORDER BY ready_at`)
      .all(account, from, to).map((r) => r.ready_at);
  }

  /** The universe as §5.5 prices it (TD.14): what is in every slot, woven
   *  or weaving, each realm's school, the Spire's and the Anchor Stones'
   *  levels, and the week's era; `extra`, {law, tier, realm}, priced in its
   *  place as the last line. The simulation's answer: each law's cost, the
   *  chords that sound, capacity, strain and band. */
  stability(account, extra = null) {
    const realms = this.universe.realms(account);
    const schools = [];
    for (const r of realms) schools[realmIndex(r.realm)] = r.realm === "heart" ? null : schoolOfType(r.type);
    for (let i = 0; i < schools.length; i++) schools[i] ??= null;
    const laws = this.rows(account).filter((r) => r.law)
      .map((r) => ({ law: r.law, tier: r.tier, realm: realmIndex(r.realm) }));
    if (extra) laws.push({ ...extra, realm: realmIndex(extra.realm) });
    const anchors = this.universe.buildings(account).filter((b) => b.kind === ANCHOR).map((b) => b.level);
    return this.service.builds.current.stability({ spire: this.universe.spire(account), anchors,
      era: this.service.era().wire, schools, laws });
  }

  /** §5.5's cost of `law` at `tier` woven in `realm` beside what is already
   *  there, and §5.6's price in Aether: 40 a point. */
  price(account, law, tier, realm) {
    const priced = this.stability(account, { law, tier, realm });
    return Math.round((priced.lines.at(-1).micro * facts.WEAVE_AETHER_PER_POINT) / 1_000_000);
  }

  /** Law `law` woven into slot `slot` of `realm` (the crown's as "crown"),
   *  at the tier the Codex has it, paid in Aether, working once §5.6's
   *  weaving time has passed. A repeat of one already woven there is
   *  answered as woven. */
  weave(account, { realm, slot, law }) {
    if (typeof law !== "string" || !Object.hasOwn(LAWS, law)) throw new Refused(400, "no_such_law");
    if (!Number.isInteger(slot) || slot < 1) throw new Refused(400, "malformed_body");
    const now = this.service.now();
    return transaction(this.db, () => {
      this.universe.ensure(account, now);
      if (realm !== CROWN && !this.universe.realms(account).some((x) => x.realm === realm)) {
        throw new Refused(404, "no_such_realm");
      }
      if (slot > this.slots(account, realm)) throw new Refused(409, "no_such_slot", { slots: this.slots(account, realm) });
      const rows = this.rows(account);
      const here = rows.find((r) => r.realm === realm && r.slot === slot);
      if (here?.law === law) return this.done(account, true);
      if (here?.law) throw new Refused(409, "slot_taken");
      if (here?.rests_until > now) throw new Refused(409, "slot_resting", { until: here.rests_until });
      const tier = this.tierOf(account, law);
      if (!tier) throw new Refused(409, "law_not_restored");
      if (rows.some((r) => r.law === law && r.realm === realm)) throw new Refused(409, "already_woven_here");
      // §5.1: "The same law can't be both a crown law and a realm law in
      // one universe."
      if (rows.some((r) => r.law === law && (r.realm === CROWN) !== (realm === CROWN))) {
        throw new Refused(409, realm === CROWN ? "woven_in_a_realm" : "crowned");
      }
      const cost = this.price(account, law, tier, realm);
      if (this.service.aether(account) < cost) throw new Refused(409, "not_enough_aether", { cost });
      // What a producer made under the laws that held is paid before they
      // change (home.mjs).
      this.service.home?.settleAll(account, now);
      this.db.prepare(
        `INSERT INTO law_slots (owner, realm, slot, law, tier, ready_at, rests_until) VALUES (?, ?, ?, ?, ?, ?, 0)
         ON CONFLICT (owner, realm, slot) DO UPDATE SET law = excluded.law, tier = excluded.tier,
           ready_at = excluded.ready_at, rests_until = 0`)
        .run(account, realm, slot, law, tier, now + facts.WEAVE_MINUTES[tier - 1] * MINUTE);
      this.service.book(account, "aether", -cost,
        `${LAWS[law].name} woven in ${realm === CROWN ? "the crown" : realm} (5.6)`, now);
      return this.done(account);
    });
  }

  /** The law in slot `slot` of `realm` taken out, at once; the slot rests
   *  an hour (§5.6). An empty slot is answered as emptied. */
  unweave(account, { realm, slot }) {
    if (!Number.isInteger(slot) || slot < 1) throw new Refused(400, "malformed_body");
    const now = this.service.now();
    return transaction(this.db, () => {
      const here = this.rows(account).find((r) => r.realm === realm && r.slot === slot);
      if (!here?.law) return this.done(account, true);
      this.service.home?.settleAll(account, now);
      this.db.prepare(
        "UPDATE law_slots SET law = NULL, tier = NULL, ready_at = NULL, rests_until = ? WHERE owner = ? AND realm = ? AND slot = ?")
        .run(now + facts.SLOT_REST_MINUTES * MINUTE, account, realm, slot);
      return this.done(account);
    });
  }

  /** The view, the universe and the Codex written first if this is the
   *  first time. */
  show(account) {
    return transaction(this.db, () => {
      this.universe.ensure(account, this.service.now());
      return this.view(account);
    });
  }

  done(account, repeated = false) {
    return { weaving: this.view(account), ...(repeated ? { repeated: true } : {}) };
  }

  /** Each realm's slots, the crown's first, each with what is in it: a law
   *  weaving until `ready_at` or working, or a slot resting until
   *  `rests_until`, or empty; and the price of each restored law in each. */
  view(account) {
    const now = this.service.now();
    const rows = this.rows(account);
    const restored = this.restored(account);
    const realms = [CROWN, ...this.universe.realms(account).map((r) => r.realm)].map((realm) => ({
      realm,
      slots: Array.from({ length: this.slots(account, realm) }, (_, i) => {
        const r = rows.find((x) => x.realm === realm && x.slot === i + 1);
        if (r?.law) return { slot: i + 1, law: r.law, tier: r.tier, ready_at: r.ready_at, weaving: r.ready_at > now };
        return { slot: i + 1, law: null, rests_until: r?.rests_until > now ? r.rests_until : null };
      }),
      prices: Object.fromEntries(restored.map(({ law, tier }) => [law, this.price(account, law, tier, realm)])),
    }));
    const p = this.stability(account);
    return { realms, aether: this.service.aether(account),
             // §5.5: the universe's capacity, what is woven costs, the
             // chords' draw, strain and its band, 0 Quiet to 6 Breaking.
             stability: { capacity: p.capacity, total: p.total, draw: p.draw, strain: p.strain, band: p.band,
                          chords: p.chords } };
  }
}
