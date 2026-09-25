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
 *  An `RBH2` header carries §18.3's era in one more byte after the crew. */
export const HEADER = { magic: 0, seed: 4, island: 12, rules: 44, ticks: 76, crew: 80, era: 81, bytes: 85 };

/** `island::Problem`, in the order of its bits. */
export const PROBLEMS = [
  "too_many_wards", "too_many_guards", "too_many_laws", "unknown_law",
  "crowded", "post_blocked", "landing_blocked", "sealed", "edge_closed",
];

/** `ffi.rs`'s negative statuses. */
export const REFUSED = {
  [-1]: "replay_malformed", [-2]: "island_malformed", [-3]: "wrong_island",
  [-4]: "wrong_rules", [-5]: "crew", [-6]: "length", [-7]: "log",
  [-8]: "checksums", [-9]: "too_large", [-10]: "era", [-11]: "landing",
};

export const GRADES = ["clean", "loud", "partial", "foiled"];

/** `replay::Kind`, the command vocabulary on the wire. */
export const KIND = {
  MoveTo: 0, Gait: 1, Halt: 2, Crack: 3, Load: 4, Skiff: 5,
  Attack: 6, Break: 7, Drop: 8, Disarm: 9, Drag: 10, Land: 11,
};

const hex = (bytes) => Buffer.from(bytes).toString("hex");

/** A replay's header, or null if it is too short to have one. `era` is
 *  the era's wire value, 0 for none (an `RBH1` replay). */
export function readHeader(bytes) {
  const magic = bytes.length >= 4 ? Buffer.from(bytes.subarray(0, 4)).toString() : "";
  const withEra = magic === "RBH2";
  if (!(magic === "RBH1" || withEra) || bytes.length < HEADER.bytes + (withEra ? 1 : 0)) return null;
  const view = new DataView(bytes.buffer, bytes.byteOffset, bytes.byteLength);
  return {
    seed: view.getBigUint64(HEADER.seed, true),
    island: hex(bytes.subarray(HEADER.island, HEADER.island + 32)),
    rules: hex(bytes.subarray(HEADER.rules, HEADER.rules + 32)),
    ticks: view.getUint32(HEADER.ticks, true),
    crew: bytes[HEADER.crew],
    era: withEra ? bytes[HEADER.era] : 0,
  };
}

/** One compiled build of the simulation. */
export class Build {
  constructor(wasmBytes) {
    this.x = new WebAssembly.Instance(new WebAssembly.Module(wasmBytes), {}).exports;
    this.x.rb_rules_version();
    this.rulesVersion = hex(this.buffer().slice(0, 32));
  }

  static load(path) {
    return new Build(readFileSync(path));
  }

  buffer() {
    return new Uint8Array(this.x.memory.buffer, this.x.rb_buffer(), this.x.rb_buffer_bytes());
  }

  /** An island's hash and what stops it being published. */
  island(bytes) {
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
    const v = this.buffer().slice(0, 24);
    const view = new DataView(v.buffer);
    return {
      status: "verified",
      verdict: {
        grade: GRADES[v[0]], out: v[1], caught: v[2], crew: v[3],
        banked: view.getInt32(4, true), capacity: view.getInt32(8, true),
        pages: view.getUint32(12, true), cracked: view.getUint32(16, true),
        left: view.getInt32(20, true),
      },
    };
  }

  /**
   * The device's half: play `commands` — [second-or-tick, member, kind, x, y]
   * with `tick` in ticks — on an island and record the replay. The server
   * never calls this; its tests play the device with it.
   */
  record(island, { seed, ticks, crew, commands, era = 0 }) {
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
    const n = this.x.rb_record(Number(s >> 32n), Number(s & 0xffffffffn), ticks, crew,
                               island.length, commands.length, era);
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

  /** `Island::example()`, or `example_open()` with `open`. */
  exampleIsland(open = false) {
    const n = this.x.rb_example_island(open ? 1 : 0);
    return this.buffer().slice(0, n);
  }
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
