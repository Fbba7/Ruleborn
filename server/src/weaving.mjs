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
// prices with too. What is in a slot counts, woven or still weaving.
// Breaking's "no new weaving, and no weave that would take strain to 125% or
// over" is kept here; upkeep and the tier rise in place are TD.37's. The
// first session's instant weaves are the tutorial's (§16).
//
// What is woven is what home.mjs reads: §9.3's "1 + 0.10 per realm law of a
// matching school + 0.05 per matching crown law", and §11.5's births "3 for
// each law woven in its realm, 2 for the realm's own school and 1 for each
// crown law". A law counts from when its weaving finishes.

import { readFileSync } from "node:fs";

import { transaction } from "./db.mjs";
import { faults } from "./observatory.mjs";
import { Refused } from "./refused.mjs";
import { HEART_LEVEL } from "./service.mjs";

const facts = JSON.parse(readFileSync(new URL("./facts.json", import.meta.url), "utf8"));
const LAWS = Object.fromEntries(JSON.parse(readFileSync(new URL("../../content/laws.json", import.meta.url), "utf8"))
  .map((l) => [l.id, l]));
const MINUTE = 60_000;
const NOTES = JSON.parse(readFileSync(new URL("../../content/notes.json", import.meta.url), "utf8"));
const RESONANCES = JSON.parse(readFileSync(new URL("../../content/resonances.json", import.meta.url), "utf8"));
const CHORDS = Object.fromEntries(JSON.parse(readFileSync(new URL("../../content/chords.json", import.meta.url), "utf8"))
  .map((c) => [c.id, c]));
/** §8.3's opposite pairs, each once, in notes.json's order. */
const OPPOSITES = NOTES.filter((n, i) => NOTES.findIndex((m) => m.name === n.opposite) > i)
  .map((n) => [n.name, n.opposite]);

/** The crown's slots, kept as a realm of their own. */
export const CROWN = "crown";

/** §5.5's last band, Breaking: no weave may reach it. */
const BREAKING = facts.STRAIN_BANDS.length;
/** §23.2: "Two or three recommended laws". */
const RECOMMENDED = 3;

/** The Anchor Stone, the building §5.5's capacity counts beside the Spire. */
const ANCHOR = "anchor_stone";

/** A realm's index in the simulation's universe: 0 the Heart, k outer realm
 *  k, the crown its own. */
const realmIndex = (realm) => (realm === CROWN ? "crown" : realm === "heart" ? 0 : Number(realm.split("-")[1]));

/** §23.2's recommended laws for a realm with a free slot: two or three of
 *  the offers it can weave, "ranked with one that harmonises first, one that
 *  clashes last, then the cheapest" — a law that clashes after every one
 *  that does not, among the rest one that harmonises before one that does
 *  not, and by price within each. */
export function recommend(offers, free) {
  if (!free) return [];
  const rank = (o) => (o.clashes.length ? 2 : o.harmonies.length || o.resonances ? 0 : 1);
  return offers.filter((o) => !o.refused)
    .sort((a, b) => rank(a) - rank(b) || a.price - b.price || a.law.localeCompare(b.law))
    .slice(0, RECOMMENDED).map((o) => o.law);
}

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
   *  chords that sound, capacity, strain and band. `without`, {realm,
   *  slot}, leaves that slot's law out, as a swap prices its successor;
   *  `at` names the week whose era it is priced in. */
  stability(account, extra = null, without = null, at = this.service.now()) {
    const realms = this.universe.realms(account);
    const schools = [];
    for (const r of realms) schools[realmIndex(r.realm)] = r.realm === "heart" ? null : schoolOfType(r.type);
    for (let i = 0; i < schools.length; i++) schools[i] ??= null;
    const laws = this.rows(account).filter((r) => r.law && !(without && r.realm === without.realm && r.slot === without.slot))
      .map((r) => ({ law: r.law, tier: r.tier, realm: realmIndex(r.realm) }));
    if (extra) laws.push({ ...extra, realm: realmIndex(extra.realm) });
    const anchors = this.universe.buildings(account).filter((b) => b.kind === ANCHOR).map((b) => b.level);
    return this.service.builds.current.stability({ spire: this.universe.spire(account), anchors,
      era: this.service.era(at).wire, schools, laws });
  }

  /** §5.5's cost of `law` at `tier` woven in `realm` beside what is already
   *  there, and §5.6's price in Aether: 40 a point. */
  price(account, law, tier, realm) {
    const priced = this.stability(account, { law, tier, realm });
    return Math.round((priced.lines.at(-1).micro * facts.WEAVE_AETHER_PER_POINT) / 1_000_000);
  }

  /** What each restored law would come to woven in `realm`, as §23.2's
   *  Weaving compares them: its points and price, §5.6's time, the notes it
   *  would harmonise and clash on, its resonances and chords, the band
   *  strain would reach, and why it cannot be woven there, if it cannot. */
  offers(account, realm, rows, restored) {
    const here = new Set(rows.filter((r) => r.realm === realm && r.law).map((r) => r.law));
    const now = this.stability(account);
    return restored.filter(({ law }) => !here.has(law)).map(({ law, tier }) => {
      const p = this.stability(account, { law, tier, realm });
      const line = p.lines.at(-1);
      const elsewhere = rows.some((r) => r.law === law && (r.realm === CROWN) !== (realm === CROWN));
      const why = elsewhere ? (realm === CROWN ? "woven_in_a_realm" : "crowned")
        : now.band >= BREAKING ? "breaking" : p.band >= BREAKING ? "would_break" : null;
      return { law, tier, points: line.cost, price: Math.round((line.micro * facts.WEAVE_AETHER_PER_POINT) / 1_000_000),
               minutes: facts.WEAVE_MINUTES[tier - 1], harmonies: line.harmonyNotes, clashes: line.dissonanceNotes,
               resonances: line.resonances, chords: line.chords, band: p.band, strain: p.strain, refused: why };
    });
  }

  /** Law `law` woven into slot `slot` of `realm` (the crown's as "crown"),
   *  at the tier the Codex has it, paid in Aether, working once §5.6's
   *  weaving time has passed. A repeat of one already woven there is
   *  answered as woven. */
  weave(account, { realm, slot, law, swap = false }, { view = true } = {}) {
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
      if (here?.law === law) return this.done(account, true, view);
      // G54: curation's swap weaves the new law in the old one's place, at
      // §5.6's price and time, with no hour's rest between.
      if (here?.law && swap !== true) throw new Refused(409, "slot_taken");
      if (swap === true && !here?.law) throw new Refused(409, "nothing_to_swap");
      if (here?.rests_until > now) throw new Refused(409, "slot_resting", { until: here.rests_until });
      const without = swap === true ? { realm, slot } : null;
      const others = rows.filter((r) => r !== here || !without);
      const tier = this.tierOf(account, law);
      if (!tier) throw new Refused(409, "law_not_restored");
      if (others.some((r) => r.law === law && r.realm === realm)) throw new Refused(409, "already_woven_here");
      // §5.1: "The same law can't be both a crown law and a realm law in
      // one universe."
      if (others.some((r) => r.law === law && (r.realm === CROWN) !== (realm === CROWN))) {
        throw new Refused(409, realm === CROWN ? "woven_in_a_realm" : "crowned");
      }
      // §5.5's Breaking: "No new weaving, and no weave that would take
      // strain to 125% or over".
      const now_ = this.stability(account, null, without);
      if (now_.band >= BREAKING) throw new Refused(409, "breaking", { strain: now_.strain });
      const after = this.stability(account, { law, tier, realm }, without);
      if (after.band >= BREAKING) throw new Refused(409, "would_break", { strain: after.strain });
      const cost = Math.round((after.lines.at(-1).micro * facts.WEAVE_AETHER_PER_POINT) / 1_000_000);
      if (this.service.aether(account) < cost) throw new Refused(409, "not_enough_aether", { cost });
      // What a producer made under the laws that held is paid before they
      // change (home.mjs).
      this.service.home?.settleAll(account, now);
      this.db.prepare(
        `INSERT INTO law_slots (owner, realm, slot, law, tier, ready_at, rests_until) VALUES (?, ?, ?, ?, ?, ?, 0)
         ON CONFLICT (owner, realm, slot) DO UPDATE SET law = excluded.law, tier = excluded.tier,
           ready_at = excluded.ready_at, rests_until = 0`)
        .run(account, realm, slot, law, tier, now + facts.WEAVE_MINUTES[tier - 1] * MINUTE);
      // §18.5: a law woven is a step on its school's mastery track, when its
      // weaving finishes (FX1-A-17); a law swapped out before its weaving
      // finished was never woven.
      this.service.codex.woven(account, law, now + facts.WEAVE_MINUTES[tier - 1] * MINUTE);
      this.unearned(account, law, now);
      if (here?.law) this.unearned(account, here.law, now);
      this.service.book(account, "aether", -cost,
        `${LAWS[law].name} woven in ${realm === CROWN ? "the crown" : realm} (5.6)`, now);
      return this.done(account, false, view);
    });
  }

  /** G54's swaps for curation: for each law woven in `realm`, what each
   *  other restored law would cost in its place, priced as a weave there
   *  with the old law gone (§5.5, §5.6), and why it could not be. */
  swaps(account, realm) {
    const rows = this.rows(account);
    const restored = this.restored(account);
    return rows.filter((r) => r.realm === realm && r.law).map((here) => {
      const without = { realm, slot: here.slot };
      const others = rows.filter((r) => r !== here);
      const now = this.stability(account, null, without);
      return {
        slot: here.slot, law: here.law,
        offers: restored.filter(({ law }) => !others.some((r) => r.law === law && r.realm === realm) && law !== here.law)
          .map(({ law, tier }) => {
            const p = this.stability(account, { law, tier, realm }, without);
            const line = p.lines.at(-1);
            const elsewhere = others.some((r) => r.law === law && (r.realm === CROWN) !== (realm === CROWN));
            return { law, tier, price: Math.round((line.micro * facts.WEAVE_AETHER_PER_POINT) / 1_000_000),
                     minutes: facts.WEAVE_MINUTES[tier - 1],
                     refused: elsewhere ? (realm === CROWN ? "woven_in_a_realm" : "crowned")
                       : now.band >= BREAKING ? "breaking" : p.band >= BREAKING ? "would_break" : null };
          }),
      };
    });
  }

  /** The law in slot `slot` of `realm` taken out, at once; the slot rests
   *  an hour (§5.6). An empty slot is answered as emptied. */
  unweave(account, { realm, slot }, { view = true } = {}) {
    if (!Number.isInteger(slot) || slot < 1) throw new Refused(400, "malformed_body");
    const now = this.service.now();
    return transaction(this.db, () => {
      const here = this.rows(account).find((r) => r.realm === realm && r.slot === slot);
      if (!here?.law) return this.done(account, true, view);
      this.service.home?.settleAll(account, now);
      this.db.prepare(
        "UPDATE law_slots SET law = NULL, tier = NULL, ready_at = NULL, rests_until = ? WHERE owner = ? AND realm = ? AND slot = ?")
        .run(now + facts.SLOT_REST_MINUTES * MINUTE, account, realm, slot);
      this.unearned(account, here.law, now);
      return this.done(account, false, view);
    });
  }

  /** FX1-A-17: a mastery step not yet earned, its weaving unfinished, moves
   *  to the soonest finish of `law`'s weaves still in a slot, or goes with
   *  the last of them taken out. A step earned stays earned. */
  unearned(account, law, now) {
    this.db.prepare(
      `UPDATE codex SET woven_at = (SELECT MIN(ready_at) FROM law_slots WHERE owner = :a AND law = :l)
        WHERE owner = :a AND law = :l AND woven_at > :now`)
      .run({ a: account, l: law, now });
  }

  /** §23.2's Harmony view: for each realm, the laws working there — its
   *  own, and the crown's, which work in every realm (§5.1) — with their
   *  notes (§8.1); the harmonies (a note two or more of them carry, §8.2)
   *  and clashes (opposite notes on two different laws, §8.3) they make;
   *  the signature resonances (§8.4) and the chords the simulation sounds
   *  within capacity (§8.6); each with what it does to its laws' cost
   *  (§5.5). A resonance or chord the Lab has not named (lab.mjs) is an
   *  unnamed line with its discount (§8.6). What is weaving counts, as it
   *  does for the price. */
  harmony(account) {
    return transaction(this.db, () => {
      this.universe.ensure(account, this.service.now());
      const rows = this.rows(account).filter((r) => r.law);
      const crowned = rows.filter((r) => r.realm === CROWN).map((r) => r.law);
      const priced = this.stability(account);
      const named = this.service.lab.names(account);
      const realms = this.universe.realms(account).map((r) => {
        const own = rows.filter((x) => x.realm === r.realm).map((x) => x.law);
        const laws = [...own, ...crowned.filter((l) => !own.includes(l))];
        const carry = (note) => laws.filter((l) => LAWS[l].notes.includes(note));
        const harmonies = NOTES.map((n) => ({ note: n.name, laws: carry(n.name) }))
          .filter((h) => h.laws.length >= 2)
          .map((h) => ({ ...h, factor: facts.HARMONY_COST_FACTOR }));
        const clashes = OPPOSITES.map(([a, b]) => ({ notes: [a, b], laws: [carry(a), carry(b)] }))
          .filter((c) => c.laws[0].length && c.laws[1].length
            && c.laws[0].some((x) => c.laws[1].some((y) => y !== x)))
          .map((c) => ({ notes: c.notes, laws: [...new Set(c.laws.flat())], factor: facts.DISSONANCE_COST_FACTOR }));
        const resonances = RESONANCES.filter((x) => x.laws.every((l) => laws.includes(l)))
          .map((x) => ({ name: named.resonances.has(x.id) ? x.name : null, laws: x.laws,
                         factor: facts.RESONANCE_COST_FACTOR }));
        const chords = priced.chords.filter((c) => c.realm === realmIndex(r.realm)).map((c) => {
          const notes = CHORDS[c.chord].notes;
          return { name: named.chords.has(c.chord) ? CHORDS[c.chord].name : null, notes, laws: laws.filter((l) => LAWS[l].notes.some((n) => notes.includes(n))),
                   factor: facts.CHORD_COST_FACTOR };
        });
        return { realm: r.realm, type: r.type,
                 laws: laws.map((l) => ({ law: l, notes: LAWS[l].notes, crowned: crowned.includes(l) })),
                 harmonies, clashes, resonances, chords };
      });
      return { realms, stability: { band: priced.band, strain: priced.strain } };
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

  /** An answer, with the weaving view unless `view` is false: a batch of
   *  offline weaves builds it once at its end, not once a weave (SEC-23). */
  done(account, repeated = false, view = true) {
    return { ...(view ? { weaving: this.view(account) } : {}), ...(repeated ? { repeated: true } : {}) };
  }

  /** Each realm's slots, the crown's first, each with what is in it: a law
   *  weaving until `ready_at` or working, or a slot resting until
   *  `rests_until`, or empty; and the price of each restored law in each. */
  view(account) {
    const now = this.service.now();
    const rows = this.rows(account);
    const restored = this.restored(account);
    const types = Object.fromEntries(this.universe.realms(account).map((r) => [r.realm, r.type]));
    const spire = this.universe.spire(account);
    const realms = [CROWN, ...Object.keys(types)].map((realm) => ({
      realm,
      type: types[realm] ?? null,
      // §5.1: the Spire level that opens the crown's next slot, none once
      // both are open.
      ...(realm === CROWN ? { opens_at: facts.CROWN_SLOT_SPIRE.find((s) => spire < s) ?? null } : {}),
      slots: Array.from({ length: this.slots(account, realm) }, (_, i) => {
        const r = rows.find((x) => x.realm === realm && x.slot === i + 1);
        if (r?.law) return { slot: i + 1, law: r.law, tier: r.tier, ready_at: r.ready_at, weaving: r.ready_at > now };
        return { slot: i + 1, law: null, rests_until: r?.rests_until > now ? r.rests_until : null };
      }),
      prices: Object.fromEntries(restored.map(({ law, tier }) => [law, this.price(account, law, tier, realm)])),
      offers: this.offers(account, realm, rows, restored),
    }));
    for (const r of realms) r.recommended = recommend(r.offers, r.slots.some((x) => !x.law && !x.rests_until));
    const p = this.stability(account);
    return { realms, aether: this.service.aether(account),
             // §5.5: the universe's capacity, what is woven costs, the
             // chords' draw, strain and its band, 0 Quiet to 6 Breaking.
             stability: { capacity: p.capacity, total: p.total, draw: p.draw, strain: p.strain, band: p.band,
                          chords: p.chords,
                          // §5.5's open faults at this strain, as a raider's
                          // card counts them (observatory.mjs); where each
                          // opens is TD.37's.
                          faults: faults(p.strain, this.universe.realms(account).length - 1) } };
  }
}
