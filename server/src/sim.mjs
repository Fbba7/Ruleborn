// The simulation, as the server runs it: sim/'s WebAssembly build.
//
// §24.7: "the heist simulation is written once … both the phone and the
// server run that same compiled logic." Nothing here re-implements a rule.
// The server reads four fixed fields of a replay's header to match it to its
// lease, and hands everything else to the module.
//
// §24.11: "Pin, do not patch. … Old replays stay valid forever against the
// rules they were played under." So the server holds builds, not a build:
// every module it is given is keyed by the rules version it reports, and a
// replay is re-simulated by the build its header names.

import { readFileSync } from "node:fs";

/** The replay header's fixed fields (sim/src/replay.rs, `Heist::encode`).
 *  An `RBH2` header carries §18.3's era in one more byte after the crew; an
 *  `RBH3` header always has that byte (0 for none) and §12.5's crew manifest
 *  after it, which the module reads. */
export const HEADER = { magic: 0, seed: 4, island: 12, rules: 44, ticks: 76, crew: 80, era: 81, bytes: 85 };

/** `island::Problem`, in the order of its bits. */
export const PROBLEMS = [
  "too_many_wards", "too_many_guards", "too_many_laws", "unknown_law",
  "crowded", "post_blocked", "landing_blocked", "sealed", "edge_closed",
  "entrance_blocked", "duplicate_law",
];

/** `ffi.rs`'s negative statuses. */
export const REFUSED = {
  [-1]: "replay_malformed", [-2]: "island_malformed", [-3]: "wrong_island",
  [-4]: "wrong_rules", [-5]: "crew", [-6]: "length", [-7]: "log",
  [-8]: "checksums", [-9]: "too_large", [-10]: "era", [-11]: "landing",
  [-12]: "manifest", [-13]: "universe_malformed", [-14]: "no_landing_realm",
};

export const GRADES = ["clean", "loud", "partial", "foiled"];

/** `replay::Kind`, the command vocabulary on the wire. */
export const KIND = {
  MoveTo: 0, Gait: 1, Halt: 2, Crack: 3, Load: 4, Skiff: 5,
  Attack: 6, Break: 7, Drop: 8, Disarm: 9, Drag: 10, Land: 11, Ability: 12, Sage: 13, Cast: 14,
};

const hex = (bytes) => Buffer.from(bytes).toString("hex");

/** A replay's header, or null if it is too short to have one. `era` is
 *  the era's wire value, 0 for none (an `RBH1` replay, or an `RBH3` played
 *  in none); `manifest` says whether it carries §12.5's crew manifest. */
export function readHeader(bytes) {
  const magic = bytes.length >= 4 ? Buffer.from(bytes.subarray(0, 4)).toString() : "";
  const withEra = magic === "RBH2" || magic === "RBH3";
  if (!(magic === "RBH1" || withEra) || bytes.length < HEADER.bytes + (withEra ? 1 : 0)) return null;
  const view = new DataView(bytes.buffer, bytes.byteOffset, bytes.byteLength);
  return {
    seed: view.getBigUint64(HEADER.seed, true),
    island: hex(bytes.subarray(HEADER.island, HEADER.island + 32)),
    rules: hex(bytes.subarray(HEADER.rules, HEADER.rules + 32)),
    ticks: view.getUint32(HEADER.ticks, true),
    crew: bytes[HEADER.crew],
    era: withEra ? bytes[HEADER.era] : 0,
    manifest: magic === "RBH3",
  };
}

/** §12.5's crew manifest an `RBH3` replay carries after its header: each
 *  member's kind, form, level and traits, the Sage, and the casts (each a
 *  law's row in content/laws.json's order). Null for a replay with none, or
 *  bytes that run out before it ends; the simulation refuses those anyway. */
export function readManifest(bytes, header) {
  if (!header?.manifest) return null;
  let at = HEADER.era + 1;
  const members = [];
  for (let i = 0; i < header.crew; i++) {
    if (at + 4 > bytes.length) return null;
    const [kind, form, level, n] = bytes.subarray(at, at + 4);
    members.push({ kind, form, level, traits: [...bytes.subarray(at + 4, at + 4 + n)] });
    at += 4 + n;
  }
  if (at + 2 > bytes.length) return null;
  const sage = bytes[at];
  const n = bytes[at + 1];
  if (at + 2 + n > bytes.length) return null;
  return { members, sage, casts: [...bytes.subarray(at + 2, at + 2 + n)] };
}

/** One compiled build of the simulation. */
/** §7.4's schools in the order `stability`'s wire names them (stability.rs
 *  `SCHOOLS`). */
const SCHOOL_WIRE = ["Motion", "Matter", "Time", "Energy", "Life", "Spirit"];
/** §8.1's notes, one bit each in this order (laws_table.rs `note`). */
const NOTE_WIRE = JSON.parse(readFileSync(new URL("../../content/notes.json", import.meta.url), "utf8"))
  .map((n) => n.id);
/** The simulation's millionths of a point. */
const MICRO = 1_000_000;

export class Build {
  constructor(wasmBytes) {
    this.module = new WebAssembly.Module(wasmBytes);
    this.instantiate();
    this.rulesVersion = hex(this.buffer().slice(0, 32));
    // A trap (a panic, built to abort) leaves the instance's memory as it
    // stopped — its buffer's lock held — and every later call traps too: one
    // bad input would stop every heist on this rules version until a restart
    // (SR-07). So a trap costs only its own call: the instance is made again,
    // fresh, before the error goes on to the caller.
    for (const name of Object.getOwnPropertyNames(Build.prototype)) {
      const f = this[name];
      if (name === "constructor" || name === "instantiate" || typeof f !== "function") continue;
      this[name] = (...args) => {
        try {
          return f.apply(this, args);
        } catch (err) {
          if (err instanceof WebAssembly.RuntimeError) this.instantiate();
          throw err;
        }
      };
    }
  }

  /** A fresh instance, its buffer made once so that `buffer()`'s view is
   *  never of memory the first call grows away. */
  instantiate() {
    this.x = new WebAssembly.Instance(this.module, {}).exports;
    this.x.rb_rules_version();
  }

  static load(path) {
    return new Build(readFileSync(path));
  }

  buffer() {
    return new Uint8Array(this.x.memory.buffer, this.x.rb_buffer(), this.x.rb_buffer_bytes());
  }

  /** §10.1's buildings that stand on the grid, by id: each one's code in
   *  the bundle and the side of its square footprint, from the simulation's
   *  own table (island.rs `BUILDING_CODES`). The Vault, the pylons, the
   *  posts and the wards are not in it: the island places them by their own
   *  lists. */
  get buildingKinds() {
    if (!this._kinds) {
      const n = this.x.rb_building_kinds();
      const b = this.buffer().slice(0, n);
      this._kinds = {};
      for (let at = 0; at < n; at += 3 + b[at + 2]) {
        this._kinds[Buffer.from(b.subarray(at + 3, at + 3 + b[at + 2])).toString()] = { code: b[at], side: b[at + 1] };
      }
    }
    return this._kinds;
  }

  /** The side of each grid building's footprint, by id. */
  get footprints() {
    return Object.fromEntries(Object.entries(this.buildingKinds).map(([id, k]) => [id, k.side]));
  }

  /** An island's buildings: [{ kind, x, y }], x and y the footprint's
   *  north-west tile; none for an island that does not decode. */
  buildings(bytes) {
    const kinds = Object.entries(this.buildingKinds);
    this.buffer().set(bytes);
    if (this.x.rb_island_buildings(bytes.length) < 0) return [];
    const b = this.buffer();
    return Array.from({ length: b[0] }, (_, i) => ({
      kind: kinds.find(([, k]) => k.code === b[1 + 3 * i])[0], x: b[2 + 3 * i], y: b[3 + 3 * i] }));
  }

  /** The simulation's rows: its laws' ids (`which` 0) or its chords' (1),
   *  the order `stability` names them by. */
  ids(which) {
    const key = which === 0 ? "_lawIds" : "_chordIds";
    if (!this[key]) {
      const n = this.x.rb_ids(which);
      this[key] = Buffer.from(this.buffer().slice(0, n)).toString().split("\0").slice(0, -1);
    }
    return this[key];
  }

  /**
   * §5.5's stability, priced by the simulation (TD.14), the one function the
   * client prices with too: the universe's capacity from the Spire's level,
   * each Anchor Stone's and the epoch; each woven law's cost and why; the
   * chords that sound and their draw; strain and its band (0 Quiet to 6
   * Breaking). `laws` are {law, tier, realm}, a realm its index — 0 the
   * Heart, k outer realm k — or "crown"; `schools[k]` is realm k's school,
   * null for the Heart; `era` the era's wire value.
   */
  stability({ spire, anchors = [], epoch = 1, era = 0, schools, laws }) {
    const rows = this.ids(0);
    const wire = [spire, epoch, era, anchors.length, ...anchors, schools.length,
      ...schools.map((s) => (s == null ? 255 : SCHOOL_WIRE.indexOf(s))), laws.length,
      ...laws.flatMap((l) => [rows.indexOf(l.law), l.tier, l.realm === "crown" ? 255 : l.realm])];
    if (wire.some((v) => v < 0)) throw new Error("stability: a law or school the simulation does not know");
    return this.priced(Uint8Array.from(wire));
  }

  /** `stability` from its wire form (`stability::decode`). Every amount is
   *  the simulation's integer millionths of a point (`micro`) and the same
   *  in points; strain is a share of capacity. */
  priced(wire) {
    this.buffer().set(wire);
    const n = this.x.rb_stability(wire.length);
    if (n < 0) throw new Error(`stability: ${REFUSED[n] ?? n}`);
    const b = this.buffer().slice(0, n);
    const view = new DataView(b.buffer, b.byteOffset, n);
    const chordIds = this.ids(1);
    const chords = Array.from({ length: b[1] }, (_, i) => ({ realm: b[2 + 2 * i], chord: chordIds[b[3 + 2 * i]] }));
    let at = 2 + 2 * b[1];
    const u64 = () => { const v = Number(view.getBigUint64(at, true)); at += 8; return v; };
    const [capacity, draw, total, strain] = [u64(), u64(), u64(), u64()];
    const notes = (mask) => NOTE_WIRE.filter((_, i) => mask & (1 << i));
    const lines = [];
    while (at < n) {
      const micro = u64();
      lines.push({ micro, cost: micro / MICRO, harmonies: b[at], resonances: b[at + 1], chords: b[at + 2],
                   dissonances: b[at + 3], harmonyNotes: notes(b[at + 4]), dissonanceNotes: notes(b[at + 5]) });
      at += 6;
    }
    return { band: b[0], chords, capacity: capacity / MICRO, draw: draw / MICRO, total: total / MICRO,
             strain: strain / MICRO, micro: { capacity, draw, total }, lines };
  }

  /** An island's hash and what stops it being published. */
  island(bytes) {
    // Bytes 6-9 are `exposed` (u32, little-endian) after "RBI1" and the realm
    // and vault levels; the simulation reads it as an i32, so a value above
    // i32::MAX is not an island the rules can hold (SEC-17).
    if (bytes.length >= 10 &&
        new DataView(bytes.buffer, bytes.byteOffset, bytes.byteLength).getUint32(6, true) > 0x7fffffff) {
      return { error: "island_malformed" };
    }
    this.buffer().set(bytes);
    const mask = this.x.rb_island(bytes.length);
    if (mask < 0) return { error: REFUSED[mask] };
    return {
      digest: hex(this.buffer().slice(0, 32)),
      problems: PROBLEMS.filter((_, i) => mask & (1 << i)),
    };
  }

  /**
   * §24.12's "Validate". The verdict is the re-simulation's: a replay carries
   * commands and checksums, never an outcome.
   */
  verify(replay, island) {
    if (replay.length + island.length > this.x.rb_buffer_bytes()) {
      return { status: "refused", reason: "too_large" };
    }
    this.buffer().set(replay);
    this.buffer().set(island, replay.length);
    const status = this.x.rb_verify(replay.length, island.length);
    if (status < 0) return { status: "refused", reason: REFUSED[status] };
    if (status > 0) return { status: "diverged", second: status };
    // A build before the verdict carried who got out wrote 32 bytes.
    const length = this.x.rb_verdict_bytes ? this.x.rb_verdict_bytes() : 32;
    const v = this.buffer().slice(0, length);
    const view = new DataView(v.buffer);
    return {
      status: "verified",
      verdict: {
        grade: GRADES[v[0]], out: v[1], caught: v[2], crew: v[3],
        banked: view.getInt32(4, true), capacity: view.getInt32(8, true),
        pages: view.getUint32(12, true), cracked: view.getUint32(16, true),
        left: view.getInt32(20, true),
        // Whose pylons broke, bit n §7.7's nth law (content/laws.json's order).
        broken: Number(view.getBigUint64(24, true)),
        // Who got out, bit n the crew's nth member; null from an older build.
        outMask: length > 32 ? v[32] : null,
        castsUsed: length > 33 ? v[33] : null,
      },
      // TD.39: the event log's report, from a build that writes one.
      report: this.x.rb_report_bytes ? report(this.buffer().slice(64, 64 + this.x.rb_report_bytes())) : null,
    };
  }

  /**
   * The device's half: play `commands` — [second-or-tick, member, kind, x, y]
   * with `tick` in ticks — on an island and record the replay. The server
   * never calls this; its tests play the device with it. With `manifest`
   * — `{ members: [{ kind, form, level, traits }], sage, casts }`, each kind
   * its index in content/ruleborn.json — the replay carries §12.5's crew
   * manifest (`RBH3`).
   */
  record(island, { seed, ticks, crew, commands, era = 0, manifest = null }) {
    const records = new Uint8Array(commands.length * 10);
    const view = new DataView(records.buffer);
    commands.forEach(({ tick, member, kind, x, y }, i) => {
      view.setUint32(i * 10, tick, true);
      records[i * 10 + 4] = member;
      records[i * 10 + 5] = KIND[kind] ?? 255;
      view.setInt16(i * 10 + 6, x, true);
      view.setInt16(i * 10 + 8, y, true);
    });
    this.buffer().set(island);
    this.buffer().set(records, island.length);
    const s = BigInt.asUintN(64, BigInt(seed));
    let n;
    if (manifest) {
      const crewBytes = Uint8Array.from([
        ...manifest.members.flatMap(({ kind, form = 0, level = 1, traits = [] }) =>
          [kind, form, level, traits.length, ...traits]),
        manifest.sage ?? 0, (manifest.casts ?? []).length, ...(manifest.casts ?? []),
      ]);
      this.buffer().set(crewBytes, island.length + records.length);
      n = this.x.rb_record_crew(Number(s >> 32n), Number(s & 0xffffffffn), ticks, crew,
                                island.length, commands.length, era, crewBytes.length);
    } else {
      n = this.x.rb_record(Number(s >> 32n), Number(s & 0xffffffffn), ticks, crew,
                           island.length, commands.length, era);
    }
    if (n < 0) throw new Error(`record refused: ${REFUSED[n]}`);
    return this.buffer().slice(0, n);
  }

  /** `sim/`'s seeded test player (`draw`), recorded. */
  recordDrawn(island, { seed, ticks, crew, era = 0 }) {
    this.buffer().set(island);
    const s = BigInt.asUintN(64, BigInt(seed));
    const n = this.x.rb_record_drawn(Number(s >> 32n), Number(s & 0xffffffffn), ticks, crew,
                                     island.length, era);
    if (n < 0) throw new Error(`record refused: ${REFUSED[n]}`);
    return this.buffer().slice(0, n);
  }

  /** §12.22's generated target for a seed and a realm level, 1 to 5:
   *  the island's bundle (`Island::generated`). */
  generate(seed, realmLevel) {
    const s = BigInt.asUintN(64, BigInt(seed));
    const n = this.x.rb_generate(Number(s >> 32n), Number(s & 0xffffffffn), realmLevel);
    return this.buffer().slice(0, n);
  }

  /** §13.3's curation: the generator's layout of a player's realm from a
   *  seed, with its buildings where the universe placed them, the Vault at
   *  `vaultLevel` and `laws`, the realm's woven ids, on the generator's
   *  pylon spots (`Island::curated`). */
  curated(seed, realmLevel, vaultLevel, buildings, laws) {
    const kinds = this.buildingKinds;
    const ids = laws.map((l) => Buffer.from(l));
    const wire = Uint8Array.from([buildings.length, ...buildings.flatMap((b) => [kinds[b.kind].code, b.x, b.y]),
      ids.length, ...ids.flatMap((id) => [id.length, ...id])]);
    this.buffer().set(wire);
    const s = BigInt.asUintN(64, BigInt(seed));
    const n = this.x.rb_curated(Number(s >> 32n), Number(s & 0xffffffffn), realmLevel, vaultLevel, wire.length);
    if (n < 0) throw new Error(`curated: ${REFUSED[n] ?? n}`);
    return this.buffer().slice(0, n);
  }

  /** An island's terrain digest, hex: its ground, Vault and tunnels without
   *  posts, wards, laws or buildings (`Island::terrain_digest`); null for
   *  one that does not decode. */
  terrain(bytes) {
    this.buffer().set(bytes);
    if (this.x.rb_terrain(bytes.length) < 0) return null;
    return hex(this.buffer().slice(0, 32));
  }

  /** §13.3's hold measurement, in part: of `raids` heists of the competent
   *  reference crew of `crew` on a clock of `ticks`, from `seed` on, how many
   *  it held (sim/src/reference.rs). */
  hold(island, { seed, raids, ticks, crew = 3 }) {
    this.buffer().set(island);
    const s = BigInt.asUintN(64, BigInt(seed));
    const n = this.x.rb_hold(Number(s >> 32n), Number(s & 0xffffffffn), raids, ticks, crew, island.length);
    if (n < 0) throw new Error(`hold refused: ${REFUSED[n] ?? n}`);
    return n;
  }

  /** A universe's bundle and its islands as the module reads them after
   *  `at`: the bundle, then each island its length (u16 LE) and its bytes.
   *  The length of what was written, or null when it does not fit. */
  putUniverse(at, universe, islands) {
    const framed = islands.flatMap((i) => [i.length & 0xff, i.length >> 8, ...i]);
    if (at + universe.length + framed.length > this.x.rb_buffer_bytes()) return null;
    this.buffer().set(universe, at);
    this.buffer().set(framed, at + universe.length);
    return framed.length;
  }

  /**
   * `verify` for a heist across a universe (§5.4, D71): `universe` its
   * `RBU1` bundle and `islands` its realms' islands in its order. The
   * verdict is `verify`'s, with the realm the crew landed on (`landing`, its
   * place in the universe's order), its links to the Heart and whether it
   * came in at its fault; `reports` is
   * each realm the crew went through, in order, with its report.
   */
  verifyUniverse(replay, universe, islands) {
    // A build from before universes were built cannot play one.
    if (!this.x.rb_verify_universe) return { status: "refused", reason: "rules_not_held" };
    this.buffer().set(replay);
    const framed = replay.length <= this.x.rb_buffer_bytes() ? this.putUniverse(replay.length, universe, islands) : null;
    if (framed === null) return { status: "refused", reason: "too_large" };
    const status = this.x.rb_verify_universe(replay.length, universe.length, framed);
    if (status < 0) return { status: "refused", reason: REFUSED[status] };
    if (status > 0) return { status: "diverged", second: status };
    const v = this.buffer().slice(0, 37);
    const view = new DataView(v.buffer);
    const wire = this.buffer().slice(64, 64 + this.x.rb_report_bytes());
    const reports = [];
    for (let at = 1, i = 0; i < wire[0]; i++) {
      const length = wire[at + 1] | (wire[at + 2] << 8);
      reports.push({ realm: wire[at], report: report(wire.slice(at + 3, at + 3 + length)) });
      at += 3 + length;
    }
    return {
      status: "verified",
      verdict: {
        grade: GRADES[v[0]], out: v[1], caught: v[2], crew: v[3],
        banked: view.getInt32(4, true), capacity: view.getInt32(8, true),
        pages: view.getUint32(12, true), cracked: view.getUint32(16, true),
        left: view.getInt32(20, true), broken: Number(view.getBigUint64(24, true)),
        outMask: v[32], castsUsed: v[33],
      },
      landing: v[34], links: v[35], fault: v[36] === 1, reports,
    };
  }

  /** The competent reference crew's heist across a universe, recorded: a
   *  device for the server's tests (`reference::competent_universe`). It
   *  lands on the realm at place `realm`, else the one its seed draws, on a
   *  clock of `ticks`, else §5.4's for it, in the era of wire value `era`. */
  competentUniverse(universe, islands, { seed, crew = 3, realm = 0, ticks = 0, era = 0 }) {
    const framed = this.putUniverse(0, universe, islands);
    if (framed === null) throw new Error("competentUniverse: too large");
    const s = BigInt.asUintN(64, BigInt(seed));
    const n = this.x.rb_competent_universe(Number(s >> 32n), Number(s & 0xffffffffn), crew, realm, ticks, era,
                                           universe.length, framed);
    if (n < 0) throw new Error(`competentUniverse refused: ${REFUSED[n] ?? n}`);
    return this.buffer().slice(0, n);
  }

  /** `Island::example()`, or `example_open()` with `open`. */
  exampleIsland(open = false) {
    const n = this.x.rb_example_island(open ? 1 : 0);
    return this.buffer().slice(0, n);
  }
}

/** The wards by their code in a bundle (island.rs `ward_from`). */
export const WARD_CODES = ["crystal_wall", "thorn_hedge", "static_coil", "gravity_well", "time_snare", "lantern_glare"];

/**
 * A verified heist's report (sim `Report::encode`, §13.2, TD.39): where the
 * crew landed, the seconds the defence held, the realm alarm's highest
 * level, the bells rung, the posts that never noticed anyone and those
 * Alerted; each place a guard reached Alerted on seeing a crew member, each
 * ward that fired with how often, and the posts whose guards caught anyone
 * (row null for alarm level 5's Warden).
 */
export function report(b) {
  const view = new DataView(b.buffer, b.byteOffset, b.byteLength);
  let at = 8;
  const list = (size, read) => Array.from({ length: b[at++] }, () => { const r = read(at); at += size; return r; });
  const seen = list(3, (i) => ({ crew: b[i], x: b[i + 1], y: b[i + 2] }));
  const fired = list(4, (i) => ({ ward: WARD_CODES[b[i]], x: b[i + 1], y: b[i + 2], times: b[i + 3] }));
  const caughtBy = list(3, (i) => ({ row: b[i] === 255 ? null : b[i], x: b[i + 1], y: b[i + 2] }));
  return { landing: b[0] === 255 ? null : { x: b[0], y: b[1] }, held: view.getUint16(2, true), alarm: b[4],
           bells: b[5], slept: b[6], alerted: b[7], seen, fired, caughtBy };
}

/**
 * Every build the server holds, by rules version. The newest is the one new
 * islands are checked with and new leases are played under; the rest stay so
 * that a replay recorded under them can still be re-simulated.
 */
export class Builds {
  constructor(builds) {
    this.byVersion = new Map(builds.map((b) => [b.rulesVersion, b]));
    this.current = builds[builds.length - 1];
  }

  static load(paths) {
    return new Builds(paths.map((p) => Build.load(p)));
  }

  get(rulesVersion) {
    return this.byVersion.get(rulesVersion) ?? null;
  }
}
