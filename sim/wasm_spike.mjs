// The server half of the determinism spike (T3.1).
//
//     node sim/wasm_spike.mjs <seed> <ticks>
//
// §24.7: "Rust, compiled into the app as a native extension on iPhone and
// Android, and to WebAssembly for the server function." This runs the
// WebAssembly build of the same library the native binary runs, and prints
// the digest, so the two can be compared without either knowing about the
// other.
//
// Nothing is imported into the module: the simulation allocates nothing after
// set-up and calls nothing out, so the instance needs no imports at all. That
// is a property worth keeping — a core that needs a host function is a core
// whose result can depend on the host.

import { createHash } from "node:crypto";
import { readFileSync } from "node:fs";

const wasmPath = new URL(
  "./target/wasm32-unknown-unknown/release/ruleborn_sim.wasm",
  import.meta.url,
);

const seed = BigInt(process.argv[2] ?? "0x5EED0000_00000001".replace("_", ""));
const ticks = Number(process.argv[3] ?? 7200);

const { instance } = await WebAssembly.instantiate(readFileSync(wasmPath), {});
const { rb_digest, memory, rb_buffer, rb_buffer_bytes, rb_rules_version,
        rb_example_island, rb_island, rb_record_drawn, rb_verify } = instance.exports;

if (typeof rb_digest !== "function") {
  console.error("rb_digest is not exported — the cdylib build is wrong");
  process.exit(2);
}

const hi = Number((seed >> 32n) & 0xffffffffn);
const lo = Number(seed & 0xffffffffn);
const digest = BigInt.asUintN(64, rb_digest(hi, lo, ticks));

console.log(`seed ${seed} ticks ${ticks}`);
console.log(`digest ${digest.toString(16).padStart(16, "0")}`);

// The server's half (§24.12), as `spike.rs` prints it natively.
const buffer = () => new Uint8Array(memory.buffer, rb_buffer(), rb_buffer_bytes());
const hex = (bytes) => Buffer.from(bytes).toString("hex");
rb_rules_version();
const rules = hex(buffer().slice(0, 32));
const islandLen = rb_example_island(0);
const island = buffer().slice(0, islandLen);
rb_island(islandLen);
const islandHash = hex(buffer().slice(0, 32));
buffer().set(island);
const replayLen = rb_record_drawn(hi, lo, 4500, 4, islandLen);
const replay = buffer().slice(0, replayLen);
const replayHash = createHash("sha256").update(replay).digest("hex");
buffer().set(replay);
buffer().set(island, replayLen);
const status = rb_verify(replayLen, islandLen);
const GRADES = ["Clean", "Loud", "Partial", "Foiled"];
let verdict;
if (status === 0) {
  const v = buffer().slice(0, 16);
  const view = new DataView(v.buffer);
  verdict = `ok ${GRADES[v[0]]} ${v[1]} ${v[2]} ${view.getInt32(4, true)} ${view.getInt32(8, true)}`;
} else {
  verdict = `refused ${status}`;
}
console.log(`validator ${rules} ${islandHash} ${replayHash} ${verdict}`);
