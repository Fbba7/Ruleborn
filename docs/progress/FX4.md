# FX4 client fixer: progress

- Status: Green. FX4-6-device-replay-cap: the fail-first ext tests, the fix,
  and CLI-23 proven and fixed; the pre-check on 9c66e15c is in `status/FX4.json`.
- Progress: 5 of 8 tasks merged (FX4-1 to FX4-5); FX4-6 in this session; no
  gate items (fix wave).
- Done: the ext refuses a replay over `MAX_HEIST_BYTES`, both recorders,
  and `give` stops taking commands before the replay reaches it.
- Next: the lead merges FX4-6; then FX4-7-curation-swap-weave.
- Blocked by: none.
- Owner decision needed: none.

| Deliverable | Weight (h) | Status | Evidence |
|---|---:|---|---|
| FX4-1-transport: RB-27, RB-03, RB-04 | 3.5 | merged | lead cycle 155, `c28600bb` |
| FX4-2-trace-events: RB-31, RB-32, RB-41, RB-42 | 3.5 | merged | `8ed7538f` |
| FX4-3-replay-shop-nav: RB-43, RB-20, RB-58, RB-59 | 3.5 | merged | `8be82e6f` on main |
| FX4-4-audit-client: the client audit | 4 | merged | `d5c16216` on main |
| FX4-5-problem-strings: FX3-R1's two problem rows | 0.75 | merged | `d3183782` on main |
| FX4-6-device-replay-cap: SIM-2 and FX3-R3 on the device, CLI-23 | 1.0 | ready | `9c66e15c`, pre-check in the status file |

## Handoff

- Last verified commit: 9c66e15c, the ready_sha in `status/FX4.json` once
  its pre-check passed.
- Commits, in order:
  - `e43b0b73`: the tests, on their own. `client/ext/src/tests.rs` (six
    cargo tests, `#[cfg(test)] mod tests;` in `lib.rs`), and `record()`'s
    body moved, unchanged, into a plain `recorded() -> Vec<u8>` that
    `record()` wraps, so a cargo test can read the bytes without Godot's
    types.
  - `d72bfb59`: the fix (SIM-2, FX3-R3, CLI-23).
  - `710ed402`: main merged (lead cycle 171's two commits).
  - `9c66e15c`: `start_planned`'s `ticks as u32` (CLI-23, below).
- The fix, in `client/ext/src/lib.rs`:
  - `recorded()` gives no bytes when either recorder's replay is over
    `sim::replay::MAX_HEIST_BYTES` (the sim's own constant, not a copy),
    as `rb_record*` now does (-9).
  - **The device stops accepting commands**: `give` returns false for a
    command that would put the replay over the limit. `room_for` projects
    the replay as the recorder would keep it: the log so far and this
    command, actor < 16 only, the header, and a 4-byte checksum a second
    (`ticks / TICKS_PER_SECOND`), and compares its encoded length with
    `MAX_HEIST_BYTES`. No re-simulation is needed, because a replay's
    length does not depend on the checksums' values. The screen
    (`heist_screen.gd` lines 510, 518 and 831) ignores `give`'s result, so
    such a tap is dropped silently, as a tap after the clock already is.
    FX4-R2 asks the lead about a hint on screen.
- CLI-23: **proven** with a cargo test, then fixed.
  - On main, `give` took an actor of 256, -1 or 16 (the replay cannot carry
    16, so the recorder dropped it), a kind of 256 or -256, and an x or y
    past i16, each wrapped onto a valid value.
  - The universe landing took kind 267 as Land, and x past i16.
  - `preview` took a clock of 2^32 + 4950 as 4950.
  - Now each is refused with `try_from`. The actor must also be below 16,
    the replay's four bits (RB-55).
  - `start_planned`'s `ticks as u32` is the same defect (client.md, line
    220). It is fixed the same way in `9c66e15c`, but it has no cargo test:
    its seed and island arguments are `GString` and `PackedByteArray`,
    which need the engine to build. `crew as u8` is safe (checked to be
    3..=5 first). For client.md: CLI-23 is proven and fixed.

### The tests, failing on main

Run on `e43b0b73` (main's `lib.rs` plus the `recorded()` move), `cargo test`
in `client/ext`, `RUST_BACKTRACE=0`:

```text
thread 'tests::cli_23_give_refuses_what_its_casts_would_wrap' panicked at src/tests.rs:138:5:
give took ["actor 256", "actor -1", "actor 16, which the replay cannot carry", "kind 256", "kind -256", "x past i16", "y past i16"]
thread 'tests::cli_23_preview_refuses_a_clock_past_u32' panicked at src/tests.rs:160:5:
a clock past u32
thread 'tests::cli_23_the_landing_refuses_what_its_casts_would_wrap' panicked at src/tests.rs:148:5:
kind 267 is no landing
thread 'tests::sim_2_the_single_island_recorder_refuses_a_log_over_2_kb' panicked at src/tests.rs:84:5:
the device recorded a 3451-byte replay (limit 2048)
thread 'tests::sim_2_the_universe_recorder_never_returns_a_replay_over_2_kb' panicked at src/tests.rs:109:5:
the device recorded a 2131-byte replay (limit 2048)
thread 'tests::sim_2_the_single_island_recorder_never_returns_a_replay_over_2_kb' panicked at src/tests.rs:62:5:
the device recorded a 2131-byte replay (limit 2048)
test result: FAILED. 0 passed; 6 failed
```

The tests:

- **Single-island recorder.** This is sim.md's SIM-2 Input given as a
  player's taps: `example_open`, seed 7, MAX_TICKS, crew 3, the Land, then
  180 walks one every 37 ticks. After the fix, the replay is at most 2 KB,
  some taps are refused, and `verify_on` accepts it.
- **Single-island refusal.** 400 walks pushed straight into the world, past
  `give`: no bytes are recorded.
- **Universe recorder.** The sim's `two_realms` fixture (stone link),
  landed on the outer realm on the one-link clock, then 230 walks one every
  20 ticks. After the fix, the replay is at most 2 KB and
  `verify_universe` accepts it.
- **CLI-23.** Three tests, as above.

After `d72bfb59`, all six pass.

### Evidence

- `cargo test` in `client/ext` on `9c66e15c`: 6 passed.
- `bash client/build.sh` on `d72bfb59`: passes.
- `python3 client/status.py` on `d72bfb59`: 471 of 471 passed.
- `python3 tools/coord/owners.py diff FX4-6-device-replay-cap
  origin/claude/videogame-project-analysis-ewkkk2 710ed402`: every changed
  path is inside its files. It was run again on `9c66e15c`; the result is
  in the status file.
- The pre-check (`bash tools/run_checks.sh`, the full checks on the merge
  of current main) is recorded in `status/FX4.json` (`precheck`).
- `client/status.py` rewrites `client/status.json`, and main's copy is
  stale (it lacks AD-R52 and the CLI rows). That file is not FX4-6's, so
  it was put back and not committed.

### Follow-ups still standing (from FX4-4, in the backlog)

- CLI-1 is FX4-7-curation-swap-weave; CLI-18 is FX4-8-rehearsal-rerun;
  CLI-23 is proven and fixed in FX4-6 (above).
- CLI-3 (High, unproven), CLI-8 and CLI-9 (server contract notes) and
  FX4-R1 stand as written in
  [`client.md`](../security/audit-2026-11/client.md) and the status file.

## Tried and failed

- FX4-6: a first edit put `recorded()` after a closing brace inside the
  `#[godot_api]` block, which would have moved the remaining `#[func]`s out
  of it. It was reverted before any commit. Plain helpers go in the
  `impl RulebornReplay` block above `#[godot_api]`.
- The ext's cargo tests cannot build a `GString` or `PackedByteArray`
  (engine calls). Build `RulebornReplay` from its fields, as `tests.rs`
  `played()` and `across()` do.

- CLI-11's first fix made every player's generated island equal to an
  authored one. Three server-backed tests then failed (the leased heist
  Foiled, the Keeper XP check and the workshop creator test). Under
  `--example`, the server publishes the `example:universe` account's islands
  as generated, and those tests want the authored `example:defender`
  Heart. Keeping authored islands first fixed it.
- CLI-14's first test freed an `AppLifetime` after putting `App.services`
  back. Its teardown then ended and closed the suite's services and set
  `App.services` to null, so home showed no controls in the layout checks
  (464 of 466). Free the node while `App.services` is null.
- A freed Object reads as null in GDScript: compute a check's flags before
  `queue_free`.
- CLI-21's race (roster `collect_all`) needs a slow transport.
  `FakeTransport` answers at once; the `SessionServer` class in the audit
  tests shows how to slow one route.
- `client/status.py` needs the simulation's WebAssembly built first (`cd
  sim && cargo build --locked --release --target wasm32-unknown-unknown`).
- `client/tests/run.gd` is at gdlint's 1000-line limit: new tests go in an
  aggregator such as `fix_tests.gd`.
