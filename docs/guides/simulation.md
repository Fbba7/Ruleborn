# Simulation developer guide

The Rust crate in `sim/`: how to build it, test it, change a rule safely, and
regenerate what it generates. What it models, system by system, and how
determinism is obtained is in [`sim/README.md`](../../sim/README.md); where it
sits between the client and the server is in
[`docs/architecture.md`](../architecture.md).

## Prerequisites

- **Rust, stable**, recent enough for `#[unsafe(no_mangle)]` (1.82 or later).
  The crate has no dependencies.
- **The WebAssembly target**: `rustup target add wasm32-unknown-unknown`.
- **Node 22.5 or later**, to run the WebAssembly build against the native one.
- **Python 3**, for the gates.

## Build and test

```bash
bash sim/run_spike.sh          # every gate; writes sim/status.json
```

`run_spike.sh` runs `sim/status.py`, which in turn runs, from `sim/`:

1. `python3 no_floats.py`: the float ban (no float type, decimal literal or
   float cast in the crate's sources);
2. the content gate: the simulation's constants against `content/` and
   `tools/design_facts.py`;
3. `cargo test --release -- --test-threads=1`: every test, by name;
4. the golden replays: each re-simulated, every second's checksum compared;
5. `cargo build --release` natively and for `wasm32-unknown-unknown`;
6. the spike: the same 240-second heist at five seeds, natively
   (`cargo run --release --bin spike -- SEED 7200`) and in WebAssembly
   (`node wasm_spike.mjs SEED 7200`), digests and validator verdicts compared.

It then checks `sim/systems.json` (which tests prove which system) against
the tests that exist, writes `sim/status.json`, and exits non-zero on any
failure. The audit page's "What is built" band reads `status.json`: a system
reads as built only if every test naming it passed on the last run.

For a quicker loop while working:

```bash
(cd sim && cargo test --release -- --test-threads=1)
(cd sim && cargo test --release some_test_name)
python3 sim/content_gate.py            # the constants against content/
python3 sim/content_gate.py --self-test
```

The WebAssembly build lands at
`sim/target/wasm32-unknown-unknown/release/ruleborn_sim.wasm`, which is
where `server/src/main.mjs` and `sim/wasm_spike.mjs` load it from.

## Changing a rule

1. **Find the rule's home.** A number the design document states lives in
   one place: `content/*.json` for content, `tools/design_facts.py` for the
   document's constants. The Rust constant must agree with it; the content
   gate fails if it does not.
2. **Keep it integer.** No floats anywhere. A ratio is two integers; an
   angle is a fraction of a turn (`Ang`); a position is `Fx` (64-bit, 32
   fractional bits).
3. **Run the goldens.** A change that moves any number moves a golden
   replay, and the test says at which second. That is the point: work out
   what moved and why first.
4. **Regenerate the goldens only on purpose:**

   ```bash
   (cd sim && cargo run --release --bin golden -- --write)
   ```

   Put the rewrite in the same commit as the change that needed it, and say
   in the message which second moved. The client copies the goldens on its
   next `client/build.sh`.
5. **A change in behaviour changes the rules version** the build computes
   for itself. The server holds one WebAssembly build per rules version, so
   replays recorded under the old rules stay valid (§24.11).
6. **Name the test in `sim/systems.json`** under the system it proves, or
   `status.py` fails.

## Generated files

| File | Written by | Checked by |
|---|---|---|
| `sim/src/laws_table.rs` | `python3 sim/build_laws.py`, from `content/law_effects.json` | `python3 sim/build_laws.py --check` (the content gate runs it) |
| `sim/src/sin_table.rs` | `python3 sim/build_table.py`, once; committed | the trig tests |
| `sim/golden/*.rbh` | `cargo run --release --bin golden -- --write` | `cargo test` and `status.py` |

## Looking inside a heist

```bash
(cd sim && cargo run --release --example planned)        # the planned heist, second by second
(cd sim && cargo run --release --example outcomes)       # what 200 seeded heists come to
(cd sim && cargo run --release --example where_diverge)  # which second each golden parts company at
```

## The surface other code calls

- **The client** uses the crate as a Rust library through `client/ext/`
  (`RulebornReplay`, `RulebornIsland`, `RulebornStability`).
- **The server** calls the WebAssembly exports in `sim/src/ffi.rs`
  (`rb_verify`, `rb_verify_universe`, `rb_record`, `rb_generate`,
  `rb_curated`, `rb_rules_version` and the rest); its JavaScript wrapper is
  `server/src/sim.mjs`. A new export needs both sides.
