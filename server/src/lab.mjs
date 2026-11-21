// §8.6's Resonance Lab: experiments that name what the laws do together.
//
// §10.2's Resonance Lab: "1 slot(s); 8 h per experiment (the first, in the
// first session, takes 5 minutes and is free, 16)" at level 1, down to 3
// slots and 3 h at level 5; §9.5: "Lab experiment | 400 Aether × Lab level".
// §23.2: "One chamber per Lab slot (10.2), each with two law slots for
// restored laws, its price on the button and its time after the Archivist's
// cut, the result, the hint after three empty experiments with one law
// (8.6), the third sphere's chord naming from Lab level 3 (8.5), paradox
// warning."
//
// §8.6: a signature resonance is found by "The Lab, or crossing it in a
// heist (gives a hint)"; a chord "the Lab names it from level 3, and
// crossing one gives a hint". §8.5: "from level 3 its third sphere names,
// once a day and free, the first chord in the table below that the player
// has woven or crossed and not yet named". "After
// three empty experiments that included the same law, the Lab hints one
// undiscovered resonance of that law, in the Codex's one 'hinted' state."
// "A discovery pays pages and nothing else." §7.6: "Lab experiments that
// find nothing give 3 pages of the law the player marked as working on
// (14.6) if it is in either placed law's school, or else of the first law
// placed (only restored laws can be placed on the Lab's pedestals)".
//
// A discovery's pages: the document says it pays pages, not how many; the
// empty experiment's 3, of the first law placed, are paid, and the roadmap
// says so (TD.22). Paradoxes, found from two tier III laws with opposite
// notes, wait for the paradox laws (TD.22): such a pairing is warned
// unstable and runs as an ordinary experiment, as §8.6 says it does while a
// universe holds one.
//
// A chord woven is one sounding in the player's universe when the sphere
// names (the simulation's own pricing, §8.5's draw paid); a chord crossed is
// one whose three laws stood on an island a heist crossed, which hints it.
// The Archivist's at-home cut applies "whenever it is not on a heist, at home
// or on guard" (§11.7), and the Archivist is every Keeper's from the start:
// an experiment is started from the Lab, never mid-heist, so it always cuts.

import { readFileSync } from "node:fs";

import { transaction } from "./db.mjs";
import { Refused } from "./refused.mjs";

const facts = JSON.parse(readFileSync(new URL("./facts.json", import.meta.url), "utf8"));
const read = (name) => JSON.parse(readFileSync(new URL(`../../content/${name}.json`, import.meta.url), "utf8"));
const LAB = read("buildings").find((b) => b.id === "resonance_lab");
const LAWS = Object.fromEntries(read("laws").map((l) => [l.id, l]));
const RESONANCES = read("resonances");
const CHORDS = read("chords");
/** §8.6: "44 (12 at launch)" — the signature resonances both of whose laws
 *  ship at launch. */
export const LAUNCH_RESONANCES = RESONANCES.filter((r) => r.laws.every((l) => LAWS[l]?.launch));
const NOTES = read("notes");
const ARCHIVIST = read("sages").find((s) => s.id === "the_archivist");
/** The Archivist's at-home cut: "Lab experiments 20% faster". */
const ARCHIVIST_CUT = Number(/Lab experiments (\d+)% faster/.exec(ARCHIVIST.at_home)[1]);
const MINUTE = 60_000;
const DAY = 24 * 60 * MINUTE;

/** §10.2's row for Lab level `level`: its slots and its hours an experiment. */
export function labLevel(level) {
  const row = LAB.levels.find((l) => l.level === level);
  if (!row) return null;
  const [, slots, hours] = /(\d+) slot\(s\); ([\d.]+) h per experiment/.exec(row.gives);
  return { slots: Number(slots), minutes: Math.round(Number(hours) * 60) };
}

/** The signature resonance two laws make, if any. */
export const resonanceOf = (a, b) => RESONANCES.find((r) => r.laws.includes(a) && r.laws.includes(b) && a !== b) ?? null;

/** §8.8: every chord three distinct laws make, each carrying a different
 *  one of its notes; the simulation sounds each of them (combos.rs). */
export function chordsOf(laws) {
  if (laws.length !== 3 || new Set(laws).size !== 3) return [];
  const carries = (l, n) => LAWS[l].notes.includes(n);
  const orders = [[0, 1, 2], [0, 2, 1], [1, 0, 2], [1, 2, 0], [2, 0, 1], [2, 1, 0]];
  return CHORDS.filter((c) => orders.some((o) => c.notes.every((n, k) => carries(laws[o[k]], n))));
}

/** The first chord in §8.8's table three distinct laws make, if any. */
export const chordOf = (laws) => chordsOf(laws)[0] ?? null;

/** §8.6's unstable pairing: two tier III laws with opposite notes. */
function unstable(laws, tierOf) {
  if (laws.length < 2 || laws.some((l) => tierOf(l) < 3)) return false;
  const opp = Object.fromEntries(NOTES.map((n) => [n.name, n.opposite]));
  return LAWS[laws[0]].notes.some((n) => LAWS[laws[1]].notes.includes(opp[n]));
}

export class Lab {
  constructor(service) {
    this.service = service;
  }

  get db() { return this.service.db; }

  level(account) {
    return this.db.prepare("SELECT MAX(level) AS l FROM buildings WHERE owner = ? AND kind = 'resonance_lab'")
      .get(account)?.l ?? 0;
  }

  /** An experiment's minutes and price now: the first ever is §16's five
   *  free minutes; any other is the level's hours, the Archivist's cut off
   *  them, for 400 Aether × the Lab's level. */
  terms(account) {
    const level = this.level(account);
    const row = labLevel(level);
    if (!row) return null;
    const first = !this.db.prepare("SELECT 1 FROM lab_experiments WHERE owner = ? LIMIT 1").get(account);
    if (first) return { minutes: facts.LAB_FIRST_MINUTES, aether: 0, first: true };
    const minutes = Math.round((row.minutes * (100 - ARCHIVIST_CUT)) / 100);
    return { minutes, aether: facts.LAB_AETHER_PER_LEVEL * level, first: false };
  }

  discovered(account) {
    return this.db.prepare("SELECT kind, id FROM lab_discoveries WHERE owner = ? ORDER BY found_at, id").all(account);
  }

  /** The names the Lab has found, by kind: what the Harmony view names. */
  names(account) {
    const found = this.discovered(account);
    return { resonances: new Set(found.filter((f) => f.kind === "resonance").map((f) => f.id)),
             chords: new Set(found.filter((f) => f.kind === "chord").map((f) => f.id)),
             hinted: new Set(found.filter((f) => f.kind === "hint").map((f) => f.id)) };
  }

  /** §8.6: an experiment's two restored laws placed in chamber `chamber`,
   *  paid now. */
  start(account, { chamber, laws }) {
    const now = this.service.now();
    if (!Array.isArray(laws) || laws.some((l) => typeof l !== "string" || !Object.hasOwn(LAWS, l))) {
      throw new Refused(400, "malformed_body");
    }
    return transaction(this.db, () => {
      this.settle(account, now);
      const level = this.level(account);
      const row = labLevel(level);
      if (!row) throw new Refused(409, "no_lab");
      if (!Number.isInteger(chamber) || chamber < 1 || chamber > row.slots) {
        throw new Refused(409, "no_such_chamber", { chambers: row.slots });
      }
      if (laws.length !== 2 || laws[0] === laws[1]) throw new Refused(400, "malformed_body", { laws: 2 });
      const busy = this.db.prepare(
        "SELECT ready_at FROM lab_experiments WHERE owner = ? AND chamber = ? AND settled_at IS NULL").get(account, chamber);
      if (busy) throw new Refused(409, "chamber_busy", { until: busy.ready_at });
      for (const l of laws) {
        if (this.service.weaving.tierOf(account, l) < 1) throw new Refused(409, "law_not_restored");
      }
      const t = this.terms(account);
      if (this.service.aether(account) < t.aether) throw new Refused(409, "not_enough_aether", { cost: t.aether });
      if (t.aether) this.service.book(account, "aether", -t.aether, "a Lab experiment (8.6)", now);
      this.db.prepare(
        `INSERT INTO lab_experiments (owner, chamber, laws, started_at, ready_at, unstable)
         VALUES (?, ?, ?, ?, ?, ?)`)
        .run(account, chamber, JSON.stringify(laws), now, now + t.minutes * MINUTE,
             unstable(laws, (l) => this.service.weaving.tierOf(account, l)) ? 1 : 0);
      return this.view(account, now);
    });
  }

  /** Every experiment finished by `now`, settled once: a resonance found,
   *  or nothing, its pages, and a hint after the third empty one with the
   *  same law. */
  settle(account, now = this.service.now()) {
    const due = this.db.prepare(
      `SELECT rowid, laws FROM lab_experiments WHERE owner = ? AND settled_at IS NULL AND ready_at <= ?
        ORDER BY ready_at, chamber`).all(account, now);
    const { resonances } = this.names(account);
    for (const e of due) {
      const laws = JSON.parse(e.laws);
      const resonance = resonanceOf(laws[0], laws[1]);
      let result;
      if (resonance && !resonances.has(resonance.id)) {
        result = { found: "resonance", id: resonance.id };
        resonances.add(resonance.id);
      } else {
        result = { found: null };
      }
      if (result.found) {
        this.db.prepare("INSERT OR IGNORE INTO lab_discoveries (owner, kind, id, found_at) VALUES (?, ?, ?, ?)")
          .run(account, result.found, result.id, now);
        this.service.codex.add(account, laws[0], facts.LAB_EMPTY_PAGES, now);
        result.pages = { law: laws[0], n: facts.LAB_EMPTY_PAGES };
      } else {
        // §7.6: "3 pages of the law the player marked as working on (14.6)
        // if it is in either placed law's school, or else of the first law
        // placed".
        const working = this.db.prepare("SELECT working_on FROM accounts WHERE id = ?").get(account).working_on;
        const schools = laws.map((l) => LAWS[l].school);
        const law = working && Object.hasOwn(LAWS, working) && schools.includes(LAWS[working].school) ? working : laws[0];
        this.service.codex.add(account, law, facts.LAB_EMPTY_PAGES, now);
        result.pages = { law, n: facts.LAB_EMPTY_PAGES };
        result.hint = this.hint(account, laws, now);
      }
      this.db.prepare("UPDATE lab_experiments SET settled_at = ?, result = ? WHERE rowid = ?")
        .run(now, JSON.stringify(result), e.rowid);
    }
  }

  /** §8.6: after three empty experiments that included the same law, one
   *  undiscovered resonance of that law that can be found at launch, hinted
   *  once. */
  hint(account, laws, now) {
    const empties = this.db.prepare(
      `SELECT laws FROM lab_experiments WHERE owner = ? AND settled_at IS NOT NULL
         AND json_extract(result, '$.found') IS NULL`).all(account).map((r) => JSON.parse(r.laws));
    const { resonances, hinted } = this.names(account);
    for (const law of laws) {
      const count = empties.filter((ls) => ls.includes(law)).length + 1;
      if (count < facts.LAB_HINT_AFTER) continue;
      const open = LAUNCH_RESONANCES.find((r) => r.laws.includes(law) && !resonances.has(r.id) && !hinted.has(r.id));
      if (!open) continue;
      this.db.prepare("INSERT OR IGNORE INTO lab_discoveries (owner, kind, id, found_at) VALUES (?, 'hint', ?, ?)")
        .run(account, open.id, now);
      const partner = open.laws.find((l) => l !== law);
      return { law, school: LAWS[partner].school };
    }
    return null;
  }

  /** §8.5's third sphere's candidates, in the table's order: each chord
   *  sounding in the universe or crossed in a heist (hinted), not yet
   *  named. */
  unnamed(account) {
    const { chords, hinted } = this.names(account);
    const woven = new Set(this.service.weaving.stability(account).chords.map((c) => c.chord));
    return CHORDS.filter((c) => !chords.has(c.id) && (woven.has(c.id) || hinted.has(c.id))).map((c) => c.id);
  }

  /** When the third sphere names its next chord: from Lab level 3, once a
   *  UTC day; null below level 3. */
  sphere(account, now = this.service.now()) {
    if (this.level(account) < facts.LAB_CHORD_LEVEL) return null;
    const today = Math.floor(now / DAY) * DAY;
    const named = this.db.prepare(
      "SELECT 1 FROM lab_discoveries WHERE owner = ? AND kind = 'chord' AND found_at >= ? LIMIT 1").get(account, today);
    return { today: Boolean(named), next_at: named ? today + DAY : null, can: this.unnamed(account).length > 0 };
  }

  /** §8.5: the third sphere names, free, the first chord the player has
   *  woven or crossed and not yet named, once a day. */
  name(account) {
    const now = this.service.now();
    return transaction(this.db, () => {
      this.settle(account, now);
      const level = this.level(account);
      if (!labLevel(level)) throw new Refused(409, "no_lab");
      if (level < facts.LAB_CHORD_LEVEL) throw new Refused(409, "lab_level_too_low", { level: facts.LAB_CHORD_LEVEL });
      const s = this.sphere(account, now);
      if (s.today) throw new Refused(409, "named_today", { next_at: s.next_at });
      const [chord] = this.unnamed(account);
      if (!chord) throw new Refused(409, "no_chord_to_name");
      this.db.prepare("INSERT INTO lab_discoveries (owner, kind, id, found_at) VALUES (?, 'chord', ?, ?)")
        .run(account, chord, now);
      return { ...this.view(account, now), named: chord };
    });
  }

  /** §8.6: a heist crossing an island hints each resonance and chord its
   *  laws make that the raider has not found. */
  crossed(account, laws, now) {
    const { resonances, chords } = this.names(account);
    const hint = this.db.prepare("INSERT OR IGNORE INTO lab_discoveries (owner, kind, id, found_at) VALUES (?, 'hint', ?, ?)");
    for (const r of RESONANCES) {
      if (!resonances.has(r.id) && r.laws.every((l) => laws.includes(l))) hint.run(account, r.id, now);
    }
    for (let i = 0; i < laws.length; i++) {
      for (let j = i + 1; j < laws.length; j++) {
        for (let k = j + 1; k < laws.length; k++) {
          for (const c of chordsOf([laws[i], laws[j], laws[k]])) {
            if (!chords.has(c.id)) hint.run(account, c.id, now);
          }
        }
      }
    }
  }

  /** The Lab as the device draws it: each chamber, empty or running until
   *  `ready_at`, with its last result; the price and time of the next
   *  experiment; what has been found and hinted, and what remains by school;
   *  and the restored laws that can be placed. */
  view(account, now = this.service.now()) {
    const level = this.level(account);
    const row = labLevel(level);
    const rows = this.db.prepare(
      `SELECT chamber, laws, ready_at, settled_at, result, unstable FROM lab_experiments
        WHERE owner = ? ORDER BY started_at DESC`).all(account);
    const chambers = row ? Array.from({ length: row.slots }, (_, i) => {
      const last = rows.find((r) => r.chamber === i + 1);
      if (!last) return { chamber: i + 1, running: null, result: null };
      const laws = JSON.parse(last.laws);
      return last.settled_at == null
        ? { chamber: i + 1, running: { laws, ready_at: last.ready_at, unstable: Boolean(last.unstable) }, result: null }
        : { chamber: i + 1, running: null, result: { laws, ...JSON.parse(last.result) } };
    }) : [];
    const found = this.discovered(account);
    const resonances = new Set(found.filter((f) => f.kind === "resonance").map((f) => f.id));
    // §8.6: "the Codex shows how many remain in each school", of the 12 at
    // launch — those both of whose laws ship — a resonance joining two
    // schools counted in each.
    const remaining = Object.fromEntries(facts.SCHOOLS.map((s) => [s, LAUNCH_RESONANCES.filter((r) => !resonances.has(r.id)
      && r.laws.some((l) => LAWS[l].school === s)).length]));
    return {
      level, chambers, terms: row ? this.terms(account) : null, sphere: this.sphere(account, now),
      found: found.filter((f) => f.kind !== "hint").map(({ kind, id }) => ({ kind, id })),
      hinted: found.filter((f) => f.kind === "hint" && !found.some((g) => g.kind !== "hint" && g.id === f.id))
        .map((f) => f.id),
      remaining, restored: this.service.weaving.restored(account).map((r) => r.law),
      aether: this.service.aether(account),
    };
  }

  /** §14.6's "an experiment finished": the experiments still running at
   *  `now`, soonest first, which the device sets its own timer from. */
  running(account, now = this.service.now()) {
    return this.db.prepare(
      `SELECT chamber, ready_at FROM lab_experiments WHERE owner = ? AND settled_at IS NULL AND ready_at > ?
        ORDER BY ready_at, chamber`).all(account, now).map(({ chamber, ready_at }) => ({ chamber, ready_at }));
  }

  show(account) {
    return transaction(this.db, () => {
      this.settle(account);
      return this.view(account);
    });
  }
}
