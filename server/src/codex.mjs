// The Codex (§7.6, §14.2): the laws a player has met, their pages, and what
// restoring each and raising its tier costs.
//
// §7.6: "After each heist the player picks one law the crew crossed to study
// and receives 2 of its pages, 3 if the heist was clean. The first time a
// player meets a law it joins the Codex with 1 page. … Breaking a pylon gives
// a page of its law; a foiled heist gives one." "A floor for bad luck. Every
// eighth heist guarantees a page of a law you are actually working on."
// "Restoring a law: 10, 20, 35 or 60 pages by rank"; "tier II costs 20 more
// pages and 2,000 Aether (Spire level 4); tier III costs 40 more pages and
// 8,000 Aether (Spire level 7)". "Starting laws: Half gravity, Slow rivers and
// Bloom, all at tier I." The Codex "opens in chapters": chapter 1's twelve
// from the start, the launch 24 from Keeper level 6. §14.2 pays "restoring
// laws (60 + 10 × level)" in Keeper experience.
//
// The heist's pages are the server's: it settles the heist, it reads which
// pylons broke from the re-simulation (the verdict's `broken`), and it keeps
// the one study a heist allows. A friendly heist or a challenge pays the
// raider nothing (§12.11, §17.6), so neither studies, breaks a pylon for a
// page, nor counts to the floor; a friendly heist pays its owner "a page for
// every raider their guards catch".

import { readFileSync } from "node:fs";

import { transaction } from "./db.mjs";
import { Refused } from "./refused.mjs";
import { lawsOf } from "./telemetry.mjs";

const facts = JSON.parse(readFileSync(new URL("./facts.json", import.meta.url), "utf8"));
const LAWS = JSON.parse(readFileSync(new URL("../../content/laws.json", import.meta.url), "utf8"));
const BY_ID = Object.fromEntries(LAWS.map((l) => [l.id, l]));
const RANKS = ["Common", "Uncommon", "Rare", "Deep"];

/** §7.6's restoration price for a law, by its rank. */
export const restorePrice = (law) => facts.PAGE_COSTS[RANKS.indexOf(BY_ID[law].rank)];

/** §12.5's casts: the law a manifest's cast row names (content/laws.json's
 *  order, the simulation's table's), or null; and what using it costs —
 *  "30 Aether per point of the law's base cost", its stability cost. */
export const castLaw = (row) => LAWS[row]?.id ?? null;
export const castPrice = (law) => Math.round(BY_ID[law].stability_cost * facts.CAST_AETHER_PER_POINT);

/** The laws whose pylons a heist broke: bit n of the verdict's `broken` is
 *  §7.7's nth law, content/laws.json's order (sim/src/heist.rs). */
export function brokenLaws(broken) {
  return LAWS.filter((_, i) => Math.floor(broken / 2 ** i) % 2 === 1).map((l) => l.id);
}

/** §7.6's last chapter open to a Keeper of `level`: 1 from the start, 2
 *  from Keeper level 6. */
export const openChapter = (level) => (level >= facts.CHAPTER_TWO_KEEPER ? 2 : 1);

/** The highest chapter among `laws`, which a raider must have open to be
 *  offered an island running them (§7.6). A law after launch has no chapter
 *  until its season names one, and no player can restore or weave it (G49):
 *  only the game's own fixtures run one, and it closes nothing. */
export const chapterOf = (laws) => Math.max(1, ...laws.map((l) => BY_ID[l]?.chapter ?? 1));

/** §18.5's laws "the school has in play": its launch laws, in the order
 *  the Codex opens them, chapter by chapter. */
const inPlay = (school) => LAWS.filter((l) => l.school === school && l.launch)
  .sort((a, b) => a.chapter - b.chapter);

/** §18.5's mastery track for each school, from the Codex's rows by law:
 *  three steps a law in play — woven, crossed in a successful heist, raised
 *  to tier III — and the marks: a title at a third of them, the school's new
 *  style at two thirds, a title at all of them. */
export function mastery(by) {
  return facts.SCHOOLS.map((school) => {
    const laws = inPlay(school);
    const steps = laws.reduce((n, l) => {
      const r = by[l.id];
      return n + (r?.woven_at != null) + (r?.crossed_at != null) + (r?.tier === 3);
    }, 0);
    const total = facts.MASTERY_STEPS_PER_LAW * laws.length;
    return { school, steps, total,
             marks: { title: Math.ceil(total / 3), style: Math.ceil((2 * total) / 3), last_title: total } };
  });
}

/** Whether a mode pays its raider (§12.11, §17.6). */
const pays = (mode) => mode !== "friendly" && mode !== "challenge";

export class Codex {
  constructor(service) {
    this.service = service;
    this.db = service.db;
  }

  /** The Codex as it starts: §7.6's three starting laws, met and restored at
   *  tier I, written the first time it is asked for. */
  ensure(account, now) {
    if (this.db.prepare("SELECT 1 FROM codex WHERE owner = ? LIMIT 1").get(account)) return;
    for (const law of facts.STARTING_LAWS) {
      this.db.prepare("INSERT INTO codex (owner, law, pages, tier, met_at, restored_at) VALUES (?, ?, 0, 1, ?, ?)")
        .run(account, law, now, now);
    }
  }

  row(account, law) {
    return this.db.prepare("SELECT * FROM codex WHERE owner = ? AND law = ?").get(account, law);
  }

  /** `n` pages of `law`, the law met if it was not. */
  add(account, law, n, now) {
    if (!BY_ID[law] || n <= 0) return;
    this.db.prepare(`INSERT INTO codex (owner, law, pages, met_at) VALUES (?, ?, ?, ?)
                     ON CONFLICT (owner, law) DO UPDATE SET pages = pages + excluded.pages`)
      .run(account, law, n, now);
  }

  /** Inside a validated heist's settlement: each law of the island the
   *  raider has not met joins with its page; each pylon broken gives a page
   *  of its law; every eighth paying heist a page of the law worked on; and a
   *  friendly heist's owner a page for each raider caught. Returns the pages
   *  given, by law. */
  afterHeist(lease, verdict, now, cast = []) {
    const raider = lease.attacker;
    this.ensure(raider, now);
    const given = {};
    const give = (account, law, n) => {
      this.add(account, law, n, now);
      if (account === raider) given[law] = (given[law] ?? 0) + n;
    };
    const crossed = lawsOf(this.service.store.get(lease.bundle)).filter((law) => BY_ID[law]);
    for (const law of crossed) {
      if (!this.row(raider, law)) give(raider, law, facts.MEET_PAGES);
    }
    // §8.6: crossing a resonance or chord hints it.
    this.service.lab.crossed(raider, crossed, now);
    // §18.5: each law crossed in a successful heist is a step on its
    // school's mastery track — a heist that pays its raider and banks loot,
    // any grade but Foiled, as §18.6 counts a clear.
    if (pays(lease.mode) && verdict.grade !== "foiled") {
      for (const law of crossed) {
        this.db.prepare("UPDATE codex SET crossed_at = COALESCE(crossed_at, ?) WHERE owner = ? AND law = ?")
          .run(now, raider, law);
      }
    }
    if (pays(lease.mode)) {
      for (const law of brokenLaws(verdict.broken ?? 0)) give(raider, law, 1);
      const heists = this.db.prepare(
        `SELECT COUNT(*) AS n FROM heists h JOIN leases l ON l.token = h.token
          WHERE h.attacker = ? AND h.validated = 1 AND l.mode NOT IN ('friendly', 'challenge')`)
        .get(raider).n + 1;                       // this one is not marked validated yet
      const working = this.db.prepare("SELECT working_on FROM accounts WHERE id = ?").get(raider).working_on;
      if (heists % facts.FLOOR_HEISTS === 0 && working) give(raider, working, 1);
    }
    // §7.6: "If the raider cast a law during a foiled heist, the defender
    // gets one page of it" — a page of each law cast, to a defender who is
    // still someone (an echo's owner is not defending; G30, §20.12).
    if (verdict.grade === "foiled" && cast.length && !lease.echo) {
      const owner = this.db.prepare(
        "SELECT a.id FROM accounts a WHERE a.id = ? AND a.deleted_at IS NULL").get(lease.defender)?.id;
      if (owner) {
        this.ensure(owner, now);
        for (const law of cast) this.add(owner, law, 1, now);
      }
    }
    if (lease.mode === "friendly" && verdict.caught > 0) {
      const owner = this.db.prepare("SELECT owner FROM snapshots WHERE bundle = ?").get(lease.bundle)?.owner;
      const working = owner && this.db.prepare("SELECT working_on FROM accounts WHERE id = ?").get(owner)?.working_on;
      if (working) {
        this.ensure(owner, now);
        give(owner, working, verdict.caught);
      }
    }
    return given;
  }

  /** §7.6's study: one law the crew crossed, after the heist, once — 3 pages
   *  for a clean heist, 1 for a foiled one, 2 otherwise. */
  study(account, { heist, law }) {
    const now = this.service.now();
    return transaction(this.db, () => {
      this.ensure(account, now);
      const h = this.db.prepare(
        `SELECT h.outcome, h.validated, h.bundle, l.mode FROM heists h JOIN leases l ON l.token = h.token
          WHERE h.token = ? AND h.attacker = ?`).get(String(heist ?? ""), account);
      if (!h || !h.validated) throw new Refused(404, "no_such_heist");
      if (!pays(h.mode)) throw new Refused(409, "nothing_to_study");
      const done = this.db.prepare("SELECT law FROM studies WHERE token = ?").get(heist);
      if (done) {
        if (done.law !== law) throw new Refused(409, "already_studied");
        return { studied: law, repeated: true, codex: this.view(account) };
      }
      if (!lawsOf(this.service.store.get(h.bundle)).includes(law) || !BY_ID[law]) {
        throw new Refused(409, "law_not_crossed");
      }
      const grade = JSON.parse(h.outcome).verdict?.grade;
      const pages = grade === "foiled" ? facts.FOILED_PAGES
        : grade === "clean" ? facts.STUDY_PAGES[1] : facts.STUDY_PAGES[0];
      this.db.prepare("INSERT INTO studies (token, owner, law, pages, at) VALUES (?, ?, ?, ?, ?)")
        .run(heist, account, law, pages, now);
      this.add(account, law, pages, now);
      return { studied: law, pages, codex: this.view(account) };
    });
  }

  /** §18.5: `law` woven, a step on its school's mastery track, the first
   *  time it is (weaving.mjs). */
  woven(account, law, now) {
    this.db.prepare("UPDATE codex SET woven_at = COALESCE(woven_at, ?) WHERE owner = ? AND law = ?")
      .run(now, account, law);
  }

  /** §7.6: the law the floor's page goes to, and the Lab's. */
  workOn(account, law) {
    if (law !== null && !BY_ID[law]) throw new Refused(400, "no_such_law");
    return transaction(this.db, () => {
      this.ensure(account, this.service.now());
      this.db.prepare("UPDATE accounts SET working_on = ? WHERE id = ?").run(law, account);
      return this.view(account);
    });
  }

  /** Whether `law`'s chapter is open to a Keeper of `level`: chapter 1 from
   *  the start, chapter 2 from Keeper level 6; a law after launch has no
   *  chapter yet and cannot be restored (G49). */
  open(law, level) {
    const chapter = BY_ID[law]?.chapter;
    return chapter != null && chapter <= openChapter(level);
  }

  /** §7.6: `law` restored at tier I for its rank's pages, and §14.2's
   *  experience for it: 60 + 10 × the Keeper's level. */
  restore(account, law) {
    if (!BY_ID[law]) throw new Refused(400, "no_such_law");
    const now = this.service.now();
    return transaction(this.db, () => {
      this.ensure(account, now);
      const r = this.row(account, law);
      if (r?.tier >= 1) return { codex: this.view(account), keeper: null, repeated: true };
      const level = this.db.prepare("SELECT keeper_level FROM accounts WHERE id = ?").get(account).keeper_level;
      if (!this.open(law, level)) throw new Refused(409, "chapter_closed", { keeper: facts.CHAPTER_TWO_KEEPER });
      const cost = restorePrice(law);
      if (!r || r.pages < cost) throw new Refused(409, "not_enough_pages", { cost });
      this.db.prepare("UPDATE codex SET pages = pages - ?, tier = 1, restored_at = ? WHERE owner = ? AND law = ?")
        .run(cost, now, account, law);
      const [base, perLevel] = facts.XP_PER_LAW_RESTORED;
      const keeper = this.service.keeper.award(account, base + perLevel * level);
      return { codex: this.view(account), keeper };
    });
  }

  /** §7.6: a restored law raised to tier `to`, II or III, for its pages, its
   *  Aether and the Spire level it needs. */
  tier(account, law, to) {
    if (!BY_ID[law]) throw new Refused(400, "no_such_law");
    if (to !== 2 && to !== 3) throw new Refused(400, "malformed_body");
    const now = this.service.now();
    return transaction(this.db, () => {
      this.ensure(account, now);
      const r = this.row(account, law);
      if (r?.tier >= to) return { codex: this.view(account), repeated: true };
      if (!r || r.tier !== to - 1) throw new Refused(409, "not_the_next_tier");
      const [pages, aether, spire] = facts.TIER_COSTS[to - 2];
      if (this.service.universe.spire(account) < spire) throw new Refused(409, "needs_spire_level", { needs: spire });
      if (r.pages < pages) throw new Refused(409, "not_enough_pages", { cost: pages });
      if (this.service.aether(account) < aether) throw new Refused(409, "not_enough_aether", { cost: aether });
      this.service.book(account, "aether", -aether, `${BY_ID[law].name} to tier ${to === 2 ? "II" : "III"} (7.6)`, now);
      this.db.prepare("UPDATE codex SET pages = pages - ?, tier = ? WHERE owner = ? AND law = ?")
        .run(pages, to, account, law);
      return { codex: this.view(account) };
    });
  }

  /** The Codex as the device draws it: every law met, with its pages, its
   *  tier, its chapter and whether it is open, and what its next step costs;
   *  each school's album (§7.6), its laws in chapter order, one not yet met
   *  a "?" that names nothing (D79), with the milestones its restored laws
   *  have reached; each school's mastery track (§18.5); the Keeper level
   *  that opens the next chapter, and the Spire's, which a tier needs. */
  view(account) {
    const level = this.db.prepare("SELECT keeper_level, working_on FROM accounts WHERE id = ?").get(account);
    const rows = this.db.prepare("SELECT * FROM codex WHERE owner = ? ORDER BY law").all(account);
    const entry = (r) => {
      const l = BY_ID[r.law];
      const next = r.tier === 0 ? { pages: restorePrice(r.law) }
        : r.tier < 3 ? { pages: facts.TIER_COSTS[r.tier - 1][0], aether: facts.TIER_COSTS[r.tier - 1][1],
                         spire: facts.TIER_COSTS[r.tier - 1][2] }
        : null;
      return { law: r.law, name: l.name, school: l.school, rank: l.rank, notes: l.notes, chapter: l.chapter ?? null,
               open: this.open(r.law, level.keeper_level), pages: r.pages, tier: r.tier, next };
    };
    const by = Object.fromEntries(rows.map((r) => [r.law, r]));
    const albums = facts.SCHOOLS.map((school) => {
      const laws = inPlay(school).map((l) => (by[l.id] ? { known: true, ...entry(by[l.id]) }
        : { known: false, chapter: l.chapter, open: this.open(l.id, level.keeper_level) }));
      const restored = laws.filter((l) => l.tier >= 1).length;
      return { school, laws, restored,
               milestones: facts.ALBUM_MILESTONES.map((at) => ({ at, reached: restored >= at })) };
    });
    return { laws: rows.map(entry), albums, mastery: mastery(by), working_on: level.working_on,
             keeper_level: level.keeper_level, spire: this.service.universe.spire(account),
             aether: this.service.aether(account),
             next_chapter_at: openChapter(level.keeper_level) < 2 ? facts.CHAPTER_TWO_KEEPER : null };
  }

  /** The view, the Codex written first if this is the first time. */
  show(account) {
    return transaction(this.db, () => {
      this.ensure(account, this.service.now());
      return this.view(account);
    });
  }
}
