// The home economy's second part (§5.8, §9.2, §9.3, §9.5, §10.2, §11.3 to
// §11.6, §15.6): the roster, its homes and births, the work each character is
// given, and what the producers make with it.
//
// §11.5: "Every player starts with five ruleborn and the starting universe:
// three wake in the first minute, and two strays follow the crew home after
// the first heist, where the starting Hearth waits for them". The three are
// §15.6's Featherkin, Emberling and Tidewalker; the two strays are born under
// the laws the first heist crossed. More come from births at a Nursery, paid
// in Essence at §9.5's price, which rises with every character owned.
//
// §5.8: "A producer runs at the share of its worker slots that are filled";
// §11.6: "Production starts 5 minutes after assignment". §9.3's output an
// hour is the building's table rate (§10.2, which is base × 1.35^(level − 1)),
// times the staffing, times 1.1 in a realm of the resource's school, times
// one plus the worker's bonuses (§9.2: +15% for a ruleborn of the resource's
// schools, and §11.3's work traits). The terms the server has no state for
// yet — the laws woven in the realm, the stability band, faults — are 1
// until weaving is kept here (TC.12's later parts), and say so in `view`.
//
// The server works out what has been made, by integrating each worker's
// share over the time it counted, whenever the staffing or the level of a
// producer changes and when it is collected. Nothing is read from the device.

import { createHash } from "node:crypto";
import { readFileSync } from "node:fs";

import { transaction } from "./db.mjs";
import { Refused } from "./refused.mjs";
import { HEADER } from "./sim.mjs";

const facts = JSON.parse(readFileSync(new URL("./facts.json", import.meta.url), "utf8"));
const content = (name) => JSON.parse(readFileSync(new URL(`../../content/${name}.json`, import.meta.url), "utf8"));

const MINUTE = 60_000;
const HOUR = 60 * MINUTE;

/** §11.2's kinds: each one's school and role. */
export const RULEBORN = Object.fromEntries(content("ruleborn").map((k) => [k.id, { school: k.school, role: k.role }]));
const TRAITS = content("traits").map((t) => t.id);
const LAW_SCHOOL = Object.fromEntries(content("laws").map((l) => [l.id, l.school]));
/** §11.3's law-linked traits, each with the laws its effect names ("an extra
 *  leap under Half gravity"): "three times as likely when a character is born
 *  in a realm running that law". */
export const LAW_TRAITS = Object.fromEntries(content("traits").filter((t) => t.family === "Law-linked")
  .map((t) => [t.id, content("laws").filter((l) => t.effect.includes(l.name)).map((l) => l.id)]));
const BUILDINGS = Object.fromEntries(content("buildings").map((b) => [b.id, b]));

/** The resource each producer makes (§9.3). */
const RESOURCE = { star_well: "starlight", aether_spring: "aether", garden: "essence" };

/** Each producer's levels as §10.2 states them: what it makes an hour and its
 *  worker slots. */
export const PRODUCERS = Object.fromEntries(Object.keys(RESOURCE).map((id) => [id,
  BUILDINGS[id].levels.map((l) => {
    const m = /([\d,]+) (?:Starlight|Aether|Essence) an hour; (\d+) worker slot/.exec(l.gives);
    return { hourly: Number(m[1].replace(/,/g, "")), slots: Number(m[2]) };
  })]));

/** §10.2's Hearth: homes at each level, and the highest level a character
 *  living there may reach. */
const HEARTH = BUILDINGS.hearth.levels.map((l) => ({
  homes: Number(/homes (\d+)/.exec(l.gives)[1]),
  top: Number(/up to level (\d+)/.exec(l.gives)[1]),
}));

/** §10.2's Nursery: one birth every so many hours, and how many it holds. */
const NURSERY = BUILDINGS.nursery.levels.map((l) => {
  const m = /one birth every (\d+) h; holds (\d+)/.exec(l.gives);
  return { period: Number(m[1]) * HOUR, holds: Number(m[2]) };
});

const POST = "guardian_post";

/** The schools whose realms boost a resource and whose ruleborn work it best
 *  (§5.2's boosted resource, §9.2's best workers). */
const schoolsOf = (resource) => facts.SCHOOLS.filter((_, i) => facts.REALM_BOOSTS[i] === resource);

/** A realm type's school, from §5.2's table, in the schools' order. */
const schoolOfType = (type) => facts.SCHOOLS[facts.REALM_TYPES.indexOf(type)];

/** §11.3's traits that raise work: Well-digger's "+25% in Star Wells", and
 *  Homebody's and Sleepy's "+20% work", "+30% work" everywhere. */
const WORK = Object.fromEntries(content("traits").flatMap((t) => {
  const m = /^\+(\d+)% (?:in (Star Wells|Aether Springs|Gardens)|work)/.exec(t.effect);
  if (!m) return [];
  const at = { "Star Wells": "star_well", "Aether Springs": "aether_spring", Gardens: "garden" }[m[2]] ?? null;
  return [[t.id, { share: Number(m[1]) / 100, at }]];
}));

/** Draws from a seed, the same every time it is asked again: an integer
 *  below `n`, then the next. The server's own dice, never the device's. */
function dice(seed) {
  let i = 0;
  return (n) => createHash("sha256").update(`${seed}:${i++}`).digest().readUInt32BE(0) % n;
}

/** Whether character `c` is away at `at`: on a heist or resting after it. */
const away = (c, at) => c.away_from != null && c.away_from <= at && at < c.away_until;

/** The traits' indexes in content/traits.json, as a crew manifest carries
 *  them (sim/src/replay.rs `Member`). */
const TRAIT_INDEX = Object.fromEntries(content("traits").map((t, i) => [t.id, i]));
const KIND_INDEX = Object.fromEntries(content("ruleborn").map((k, i) => [k.id, i]));

/** §11.6's rest for one member, in minutes: "45 minutes after a clean
 *  escape, 60 after a loud one, 180 if caught" — in a Partial, 60 for one who
 *  got out and 180 for one who did not, and 180 for a foiled crew (§12.9) —
 *  × (1 − 0.05 × its Hearth's level) × each trait's factor, Loyal's "after a
 *  success, which counts a member who got out of a Partial", Sleepy's
 *  always. */
export function restMinutes(grade, out, traits, hearth) {
  const [clean, loud, caught] = facts.REST_MINUTES;
  const base = grade === "clean" ? clean : grade === "loud" ? loud
    : grade === "partial" ? (out ? loud : caught) : caught;
  const [loyal, sleepy] = facts.REST_TRAIT_FACTORS;
  let m = base * (1 - facts.HEARTH_REST_CUT * hearth);
  if (traits.includes("loyal") && grade !== "foiled" && out) m *= loyal;
  if (traits.includes("sleepy")) m *= sleepy;
  return m;
}

/** §11.5: the schools a birth is drawn from, by weight — "3 for each law
 *  woven in its realm, 2 for the realm's own school and 1 for each crown
 *  law" — as [school, weight] pairs. */
export function birthSchools(realmSchool, realmLaws, crownLaws) {
  const [perLaw, own, perCrown] = facts.BIRTH_WEIGHTS;
  const schools = {};
  const add = (school, w) => { if (school) schools[school] = (schools[school] ?? 0) + w; };
  add(realmSchool, own);
  for (const law of realmLaws) add(LAW_SCHOOL[law], perLaw);
  for (const law of crownLaws) add(LAW_SCHOOL[law], perCrown);
  return Object.entries(schools);
}

/** One of `items` by integer weight, none if every weight is 0. */
function weighted(roll, items) {
  const total = items.reduce((s, [, w]) => s + w, 0);
  if (total === 0) return null;
  let r = roll(total);
  for (const [item, w] of items) {
    if (r < w) return item;
    r -= w;
  }
  return null;
}

/** §9.5: "100 × 1.3455^ruleborn owned Essence". */
export const birthPrice = (owned) => Math.round(facts.BIRTH_PRICE[0] * facts.BIRTH_PRICE[1] ** owned);

/** §9.5: "150 × 1.55^(level − 2) Essence per level". */
export const levelPrice = (to) => Math.round(facts.LEVEL_PRICE[0] * facts.LEVEL_PRICE[1] ** (to - 2));

export class Home {
  constructor(service) {
    this.service = service;
    this.db = service.db;
  }

  get universe() {
    return this.service.universe;
  }

  /** The roster, written the first time it is asked for: §15.6's three, each
   *  with the two traits every ruleborn is born with (§11.3). */
  ensure(account, now) {
    this.universe.ensure(account, now);
    if (this.db.prepare("SELECT 1 FROM characters WHERE owner = ? LIMIT 1").get(account)) return;
    facts.STARTING_CREW.forEach((kind, i) => {
      this.add(account, kind, this.traits(dice(`${account}:woke:${i}`), 2), "woke", now);
    });
  }

  characters(account) {
    return this.db.prepare("SELECT * FROM characters WHERE owner = ? ORDER BY id").all(account)
      .map((c) => ({ ...c, traits: JSON.parse(c.traits) }));
  }

  /** `n` distinct traits, every one as likely as another: §11.3 gives each
   *  rarity's odds and no trait a rarity, and no law is woven here yet to
   *  make a law-linked trait likelier (G82). */
  traits(roll, n, running = []) {
    const left = [...TRAITS];
    const out = [];
    const weight = (t) => ((LAW_TRAITS[t] ?? []).some((l) => running.includes(l)) ? facts.LAW_TRAIT_WEIGHT : 1);
    while (out.length < n && left.length) {
      const t = weighted(roll, left.map((x) => [x, weight(x)]));
      out.push(t);
      left.splice(left.indexOf(t), 1);
    }
    return out;
  }

  /** §11.5: a kind drawn from a school's three, "roles the player has
   *  fewest of are twice as likely". */
  kindOf(account, school, roll) {
    const have = {};
    for (const c of this.characters(account)) have[RULEBORN[c.kind].role] = (have[RULEBORN[c.kind].role] ?? 0) + 1;
    const kinds = Object.keys(RULEBORN).filter((k) => RULEBORN[k].school === school);
    const fewest = Math.min(...kinds.map((k) => have[RULEBORN[k].role] ?? 0));
    return weighted(roll, kinds.map((k) => [k, (have[RULEBORN[k].role] ?? 0) === fewest ? 2 : 1]));
  }

  /** Every place a character can live: the Spire's three, and each Hearth's
   *  homes at its level (§11.4, §11.5), each with the highest level a
   *  character living there reaches, and who lives there. */
  places(account) {
    const built = this.universe.buildings(account);
    const spire = this.universe.spire(account);
    const out = [{ home: "spire", room: facts.ROSTER_PLACES[0], top: Math.min(2 * spire, facts.LEVEL_PRICE[2]) }];
    for (const r of this.universe.realms(account)) {
      const hearth = built.find((b) => b.realm === r.realm && b.kind === "hearth");
      if (hearth) out.push({ home: r.realm, room: HEARTH[hearth.level - 1].homes, top: HEARTH[hearth.level - 1].top });
    }
    const living = this.characters(account);
    return out.map((p) => ({ ...p, living: living.filter((c) => c.home === p.home).length }));
  }

  /** A new character, in the first place with room — `prefer` first — or
   *  refused when there is none. */
  add(account, kind, traits, via, now, prefer = null) {
    const places = this.places(account);
    const free = [...places.filter((p) => p.home === prefer), ...places].find((p) => p.living < p.room);
    if (!free || places.reduce((s, p) => s + p.living, 0) >= facts.ROSTER_PLACES[1]) {
      throw new Refused(409, "no_place");
    }
    return Number(this.db.prepare(
      "INSERT INTO characters (owner, kind, traits, home, via, joined_at) VALUES (?, ?, ?, ?, ?, ?)")
      .run(account, kind, JSON.stringify(traits), free.home, via, now).lastInsertRowid);
  }

  /** §11.5: "two strays follow the crew home after the first heist, where the
   *  starting Hearth waits for them; these two join free". Each is born, as
   *  a stray is, "under one of the laws the crew crossed, drawn evenly", with
   *  three traits; on an island with no laws, under any school. Once: inside
   *  the first validated heist's settlement. */
  firstStrays(account, laws, now) {
    this.ensure(account, now);
    if (this.db.prepare("SELECT 1 FROM characters WHERE owner = ? AND via = 'stray' LIMIT 1").get(account)) return [];
    const known = laws.filter((l) => LAW_SCHOOL[l]);
    return [0, 1].map((i) => {
      const roll = dice(`${account}:first-stray:${i}`);
      const school = known.length ? LAW_SCHOOL[known[roll(known.length)]] : facts.SCHOOLS[roll(facts.SCHOOLS.length)];
      return this.add(account, this.kindOf(account, school, roll), this.traits(roll, 3), "stray", now, "heart");
    });
  }

  /** The building `n` of `kind` in `realm`, if it is built. */
  building(account, realm, kind, n = 1) {
    return this.universe.buildings(account).find((b) => b.realm === realm && b.kind === kind && b.n === n);
  }

  /** What a producer makes an hour at `at`, by each worker counting: its
   *  level's rate, a slot's share for each worker from five minutes after it
   *  started, §9.3's laws working at `at` — "1 + 0.10 per realm law of a
   *  matching school + 0.05 per matching crown law" — the realm's school
   *  (§5.2) and the worker's bonuses (§9.2). */
  rate(account, realm, kind, at) {
    const b = this.building(account, realm, kind);
    if (!b) return { level: null, workers: [], perHour: 0 };
    const lv = PRODUCERS[kind][b.level - 1];
    const resource = RESOURCE[kind];
    const type = this.universe.realms(account).find((r) => r.realm === realm)?.type;
    const working = this.service.weaving.working(account, at);
    const matches = (w) => schoolsOf(resource).includes(LAW_SCHOOL[w.law]);
    const [perRealmLaw, perCrownLaw] = facts.PRODUCTION_LAW_BONUS;
    const laws = 1 + perRealmLaw * (working[realm] ?? []).filter(matches).length
      + perCrownLaw * (working.crown ?? []).filter(matches).length;
    const boost = (type && schoolsOf(resource).includes(schoolOfType(type)) ? facts.OWN_SCHOOL_PRODUCTION : 1) * laws;
    // §11.6: "A character on a heist isn't working or guarding", nor while
    // it rests after one.
    const workers = this.characters(account)
      .filter((c) => c.work_realm === realm && c.work_kind === kind && !away(c, at))
      .map((c) => {
        let bonus = schoolsOf(resource).includes(RULEBORN[c.kind].school) ? facts.WORKER_SCHOOL_BONUS : 0;
        for (const t of c.traits) if (WORK[t] && (WORK[t].at === null || WORK[t].at === kind)) bonus += WORK[t].share;
        return { id: c.id, from: c.work_since + facts.PRODUCTION_START_MINUTES * MINUTE,
                 perHour: (lv.hourly * boost * (1 + bonus)) / lv.slots };
      });
    const perHour = workers.filter((w) => w.from <= at).reduce((s, w) => s + w.perHour, 0);
    return { level: b.level, lv, workers, perHour, boost, resource, built: b.changed_at };
  }

  /** A producer's store brought up to `now`, in thousandths, and written:
   *  called before anything changes its staffing or its level, so the time
   *  before is paid at the rate that held. It holds §9.3's 12 hours of its
   *  level's output (G82). */
  settle(account, realm, kind, now) {
    if (!PRODUCERS[kind]) return 0;
    const r = this.rate(account, realm, kind, now);
    if (r.level === null) return 0;
    const row = this.db.prepare("SELECT * FROM producers WHERE owner = ? AND realm = ? AND kind = ?")
      .get(account, realm, kind) ?? { stored: 0, settled_at: r.built };
    const made = this.made(account, realm, kind, row.settled_at, now);
    const holds = facts.PRODUCER_HOLD_HOURS * r.lv.hourly * 1000;
    const stored = Math.min(holds, row.stored + Math.floor(made));
    this.db.prepare(
      `INSERT INTO producers (owner, realm, kind, stored, settled_at) VALUES (?, ?, ?, ?, ?)
       ON CONFLICT (owner, realm, kind) DO UPDATE SET stored = excluded.stored, settled_at = excluded.settled_at`)
      .run(account, realm, kind, stored, now);
    return stored;
  }

  /** What a producer made from `from` to `to`, in thousandths: each worker
   *  from when its share counts, at the laws working in each stretch — a
   *  weaving that finishes between the two starts its term there (§5.6,
   *  §9.3). */
  made(account, realm, kind, from, to) {
    const ends = this.characters(account).flatMap((c) => [c.away_from, c.away_until])
      .filter((t) => t != null && t > from && t < to);
    const cuts = [...new Set([from, ...this.service.weaving.finishing(account, from, to), ...ends, to])]
      .sort((a, b) => a - b);
    let made = 0;
    for (let i = 0; i + 1 < cuts.length; i++) {
      const r = this.rate(account, realm, kind, cuts[i]);
      for (const w of r.workers) {
        const start = Math.max(cuts[i], w.from);
        if (start < cuts[i + 1]) made += (w.perHour * (cuts[i + 1] - start) * 1000) / HOUR;
      }
    }
    return made;
  }

  /** Every producer's store brought up to `now`: before what is woven
   *  changes, so the time before is paid at the laws that held. */
  settleAll(account, now) {
    for (const b of this.universe.buildings(account)) {
      if (PRODUCERS[b.kind]) this.settle(account, b.realm, b.kind, now);
    }
  }

  /** §9.3: what a producer holds, paid into the ledger; the fraction stays.
   *  A Garden's Essence pays the roster's keep as it is collected: "25% of
   *  Essence production, taken as it is collected and never from stock". */
  collect(account, { realm, kind }) {
    if (!Object.hasOwn(PRODUCERS, kind ?? "")) throw new Refused(400, "not_a_producer");
    const now = this.service.now();
    return transaction(this.db, () => {
      this.ensure(account, now);
      if (!this.building(account, realm, kind)) throw new Refused(404, "no_such_building");
      const stored = this.settle(account, realm, kind, now);
      const made = Math.floor(stored / 1000);
      const resource = RESOURCE[kind];
      const kept = resource === "essence" ? Math.ceil(made * facts.ROSTER_KEEP_SHARE) : 0;
      this.db.prepare("UPDATE producers SET stored = stored - ? WHERE owner = ? AND realm = ? AND kind = ?")
        .run(made * 1000, account, realm, kind);
      this.service.book(account, resource, made - kept,
                        `collected from the ${BUILDINGS[kind].name} in ${realm} (9.3)`, now);
      return { collected: { resource, made, kept, paid: made - kept }, home: this.view(account) };
    });
  }

  /** §5.8 and §11.6: character `id` set to work at building `n` of `kind` in
   *  `realm` — a producer's slot or a Guardian Post — or, with no kind,
   *  recalled to idle. The producers it leaves and joins are settled first. */
  work(account, id, { realm, kind, n = 1 } = {}) {
    const now = this.service.now();
    return transaction(this.db, () => {
      this.ensure(account, now);
      const c = this.characters(account).find((x) => x.id === Number(id));
      if (!c) throw new Refused(404, "no_such_character");
      if (kind == null) {
        if (c.work_kind == null) return this.done(account, true);
        this.settle(account, c.work_realm, c.work_kind, now);
        this.db.prepare("UPDATE characters SET work_realm = NULL, work_kind = NULL, work_n = NULL, work_since = NULL WHERE id = ?")
          .run(c.id);
        return this.done(account);
      }
      if (!Object.hasOwn(PRODUCERS, kind) && kind !== POST) throw new Refused(400, "not_a_workplace");
      if (!Number.isInteger(n) || n < 1) throw new Refused(400, "malformed_body");
      if (c.work_realm === realm && c.work_kind === kind && c.work_n === n) return this.done(account, true);
      const b = this.building(account, realm, kind, n);
      if (!b) throw new Refused(404, "no_such_building");
      const slots = kind === POST ? 1 : PRODUCERS[kind][b.level - 1].slots;
      const taken = this.characters(account)
        .filter((x) => x.work_realm === realm && x.work_kind === kind && x.work_n === n).length;
      if (taken >= slots) throw new Refused(409, "slots_full", { slots });
      if (c.work_kind) this.settle(account, c.work_realm, c.work_kind, now);
      this.settle(account, realm, kind, now);
      this.db.prepare("UPDATE characters SET work_realm = ?, work_kind = ?, work_n = ?, work_since = ? WHERE id = ?")
        .run(realm, kind, n, now, c.id);
      return this.done(account);
    });
  }

  /** How many births a Nursery has ready, and when the next comes: one a
   *  period from when it was last emptied or built, up to what it holds. */
  nursery(account, realm, now) {
    const b = this.building(account, realm, "nursery");
    if (!b) return null;
    const { period, holds } = NURSERY[b.level - 1];
    const since = this.db.prepare("SELECT since FROM nurseries WHERE owner = ? AND realm = ?").get(account, realm)?.since
      ?? b.changed_at;
    const ready = Math.min(holds, Math.floor((now - since) / period));
    return { realm, ready, holds, since, period, next_at: ready >= holds ? null : since + (ready + 1) * period };
  }

  /** §11.5: a birth at the Nursery in `realm`, paid in Essence at §9.5's
   *  price for the characters already owned. `n` is the size of the roster
   *  it leads to, so a retry of one already born is answered as born. The
   *  kind is drawn from the schools around the Nursery: the realm's own,
   *  weighted 2, and — when the server keeps weaving — 3 for each law woven
   *  there and 1 for each crown law; its two traits as every ruleborn's. */
  birth(account, { realm, n }) {
    const now = this.service.now();
    return transaction(this.db, () => {
      this.ensure(account, now);
      const owned = this.characters(account).length;
      if (!Number.isInteger(n)) throw new Refused(400, "malformed_body");
      if (owned >= n) return this.done(account, true);
      if (n !== owned + 1) throw new Refused(409, "not_the_next_birth");
      const r = this.universe.realms(account).find((x) => x.realm === realm);
      const nursery = r && this.nursery(account, realm, now);
      if (!nursery) throw new Refused(404, "no_nursery");
      if (nursery.ready < 1) throw new Refused(409, "no_birth_ready", { next_at: nursery.next_at });
      const price = birthPrice(owned);
      if (this.service.balance(account).essence < price) throw new Refused(409, "not_enough_essence", { cost: price });
      const roll = dice(`${account}:birth:${owned}`);
      // §11.5: "3 for each law woven in its realm, 2 for the realm's own
      // school and 1 for each crown law"; §11.3: a law-linked trait three
      // times as likely for a law the realm runs, its own or a crown law.
      const working = this.service.weaving.working(account, now);
      const here = (working[realm] ?? []).map((w) => w.law);
      const crown = (working.crown ?? []).map((w) => w.law);
      const school = weighted(roll, birthSchools(schoolOfType(r.type), here, crown));
      const running = [...here, ...crown];
      const id = this.add(account, this.kindOf(account, school, roll), this.traits(roll, 2, running), "birth", now);
      this.service.book(account, "essence", -price, `a birth at the Nursery in ${realm} (9.5)`, now);
      const since = nursery.ready >= nursery.holds
        ? now - (nursery.holds - 1) * nursery.period : nursery.since + nursery.period;
      this.db.prepare(`INSERT INTO nurseries (owner, realm, since) VALUES (?, ?, ?)
                       ON CONFLICT (owner, realm) DO UPDATE SET since = excluded.since`).run(account, realm, since);
      return { born: id, ...this.done(account) };
    });
  }

  /** Why `ids` cannot be the crew of the heist a replay records, or null:
   *  each a character the player holds, none twice, none away, as many as
   *  the replay's crew, and — when the replay carries §12.5's manifest —
   *  each member's kind, level and traits the character's (TD.34). */
  crewProblem(account, ids, replay, header, now) {
    if (!Array.isArray(ids) || ids.length !== header.crew || new Set(ids).size !== ids.length) return "crew_mismatch";
    const mine = this.characters(account);
    const crew = ids.map((id) => mine.find((c) => c.id === id));
    if (crew.some((c) => !c)) return "crew_not_held";
    if (crew.some((c) => away(c, now))) return "crew_resting";
    if (header.manifest) {
      let at = HEADER.era + 1;
      for (const c of crew) {
        const [kind, , level, n] = replay.subarray(at, at + 4);
        const traits = [...replay.subarray(at + 4, at + 4 + n)];
        at += 4 + n;
        const want = c.traits.map((t) => TRAIT_INDEX[t]);
        if (kind !== KIND_INDEX[c.kind] || level !== c.level || traits.length !== want.length
            || traits.some((t, i) => t !== want[i])) return "crew_mismatch";
      }
    }
    return null;
  }

  /** §11.6: the crew away for the heist's length and resting after it, each
   *  by its own outcome, its Hearth and its traits; the producers settled
   *  first, so what each made before it left is paid. Inside the heist's
   *  transaction. */
  rest(account, ids, verdict, heistMs, now) {
    this.settleAll(account, now);
    const built = this.universe.buildings(account);
    ids.forEach((id, i) => {
      const c = this.characters(account).find((x) => x.id === id);
      if (!c) return;
      const hearth = c.home === "spire" ? 0
        : built.find((b) => b.realm === c.home && b.kind === "hearth")?.level ?? 0;
      const out = verdict.outMask == null ? verdict.grade !== "foiled" : Boolean(verdict.outMask & (1 << i));
      const until = now + heistMs + Math.round(restMinutes(verdict.grade, out, c.traits, hearth) * MINUTE);
      this.db.prepare("UPDATE characters SET away_from = ?, away_until = ? WHERE id = ?").run(now, until, id);
    });
  }

  /** §11.6: "Waking early costs 2 Essence per level per minute left": a
   *  resting character back now, paid by the minute begun. One not resting
   *  is answered as awake. */
  wake(account, id) {
    const now = this.service.now();
    return transaction(this.db, () => {
      const c = this.characters(account).find((x) => x.id === Number(id));
      if (!c) throw new Refused(404, "no_such_character");
      if (!away(c, now)) return this.done(account, true);
      const price = facts.WAKE_ESSENCE * c.level * Math.ceil((c.away_until - now) / MINUTE);
      if (this.service.balance(account).essence < price) throw new Refused(409, "not_enough_essence", { cost: price });
      this.settleAll(account, now);
      this.db.prepare("UPDATE characters SET away_until = ? WHERE id = ?").run(now, c.id);
      this.service.book(account, "essence", -price, `a character woken early (11.6)`, now);
      return this.done(account);
    });
  }

  /** §11.4: character `id` raised to level `to`, the next, paid in Essence at
   *  §9.5's price, no higher than its home allows: "2 × the level of the
   *  Hearth the character lives in", the Spire's places at the Spire's. */
  level(account, id, to) {
    const now = this.service.now();
    return transaction(this.db, () => {
      this.ensure(account, now);
      const c = this.characters(account).find((x) => x.id === Number(id));
      if (!c) throw new Refused(404, "no_such_character");
      if (!Number.isInteger(to) || to < 2 || to > facts.LEVEL_PRICE[2]) throw new Refused(400, "malformed_body");
      if (c.level >= to) return this.done(account, true);
      if (to !== c.level + 1) throw new Refused(409, "not_the_next_level");
      const top = this.places(account).find((p) => p.home === c.home).top;
      if (to > top) throw new Refused(409, "home_too_low", { top });
      const price = levelPrice(to);
      if (this.service.balance(account).essence < price) throw new Refused(409, "not_enough_essence", { cost: price });
      this.service.book(account, "essence", -price, `a character to level ${to} (11.4)`, now);
      this.db.prepare("UPDATE characters SET level = ? WHERE id = ?").run(to, c.id);
      return this.done(account);
    });
  }

  /** §11.4: "a character moves between free places at no cost". */
  move(account, id, home) {
    const now = this.service.now();
    return transaction(this.db, () => {
      this.ensure(account, now);
      const c = this.characters(account).find((x) => x.id === Number(id));
      if (!c) throw new Refused(404, "no_such_character");
      if (c.home === home) return this.done(account, true);
      const p = this.places(account).find((x) => x.home === home);
      if (!p) throw new Refused(404, "no_such_home");
      if (p.living >= p.room) throw new Refused(409, "no_place");
      if (c.level > p.top) throw new Refused(409, "home_too_low", { top: p.top });
      this.db.prepare("UPDATE characters SET home = ? WHERE id = ?").run(home, c.id);
      return this.done(account);
    });
  }

  /** The view, the roster written first if this is the first time. */
  show(account) {
    return transaction(this.db, () => {
      this.ensure(account, this.service.now());
      return this.view(account);
    });
  }

  done(account, repeated = false) {
    return { home: this.view(account), ...(repeated ? { repeated: true } : {}) };
  }

  /** The roster and the producers as the device draws them: each character
   *  with its kind, traits, level and the highest its home allows, where it
   *  lives and works; the places; the next birth's price and each Nursery's
   *  births; each producer's workers, rate, store and hold. */
  view(account) {
    const now = this.service.now();
    const places = this.places(account);
    const characters = this.characters(account).map((c) => ({
      id: c.id, kind: c.kind, school: RULEBORN[c.kind].school, role: RULEBORN[c.kind].role,
      traits: c.traits, level: c.level, top: places.find((p) => p.home === c.home)?.top ?? 1,
      home: c.home, via: c.via,
      state: away(c, now) ? "resting" : c.work_kind === POST ? "guarding" : c.work_kind ? "working" : "idle",
      ...(away(c, now) ? { resting_until: c.away_until } : {}),
      work: c.work_kind ? { realm: c.work_realm, kind: c.work_kind, n: c.work_n, since: c.work_since,
                            counts_from: c.work_since + facts.PRODUCTION_START_MINUTES * MINUTE } : null,
    }));
    const producers = [];
    const nurseries = [];
    for (const b of this.universe.buildings(account)) {
      if (PRODUCERS[b.kind]) {
        const r = this.rate(account, b.realm, b.kind, now);
        const row = this.db.prepare("SELECT * FROM producers WHERE owner = ? AND realm = ? AND kind = ?")
          .get(account, b.realm, b.kind) ?? { stored: 0, settled_at: b.changed_at };
        const made = this.made(account, b.realm, b.kind, row.settled_at, now);
        const holds = facts.PRODUCER_HOLD_HOURS * r.lv.hourly;
        producers.push({ realm: b.realm, kind: b.kind, level: b.level, resource: r.resource, slots: r.lv.slots,
                         workers: r.workers.map((w) => w.id), per_hour: Math.round(r.perHour),
                         stored: Math.min(holds, Math.floor((row.stored + made) / 1000)), holds,
                         full_at: fullAt(row.stored + made, holds * 1000, r.workers, now),
                         // The terms kept at 1 until the server keeps weaving
                         // and stability (G82): the realm's and crown laws of
                         // the resource's schools, the stability band, faults.
                         unkept: ["stability", "faults"] });
      }
      if (b.kind === "nursery") {
        const n = this.nursery(account, b.realm, now);
        nurseries.push({ realm: n.realm, ready: n.ready, holds: n.holds, next_at: n.next_at });
      }
    }
    const used = characters.length;
    return {
      characters,
      places: places.map(({ home, room, living, top }) => ({ home, room, living, top })),
      roster: { used, most: facts.ROSTER_PLACES[1] },
      next_birth: birthPrice(used),
      nurseries,
      producers,
      essence: this.service.balance(account).essence,
      aether: this.service.aether(account),
      // §14.6's storage-full notice is the device's own timer, and §20.2's
      // night is the server's: the hours the device moves it out of.
      night: this.service.notifications.night(this.service.notifications.settings(account)),
    };
  }
}

/** When a producer holding `stored` thousandths fills its `holds`, its
 *  workers each counting from their own start: null if it is full already
 *  or nobody works there (§14.6's storage-full notice). */
export function fullAt(stored, holds, workers, now) {
  if (stored >= holds) return null;
  const starts = [...new Set(workers.map((w) => Math.max(w.from, now)))].sort((a, b) => a - b);
  let at = now;
  let left = holds - stored;
  for (let i = 0; i < starts.length; i++) {
    const rate = workers.filter((w) => Math.max(w.from, now) <= starts[i]).reduce((s, w) => s + w.perHour, 0);
    const until = starts[i + 1] ?? Infinity;
    const perMs = (rate * 1000) / HOUR;
    at = starts[i];
    if (perMs > 0 && at + left / perMs <= until) return Math.ceil(at + left / perMs);
    left -= perMs * (until - at);
  }
  return null;
}
