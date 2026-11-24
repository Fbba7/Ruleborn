# FX4 client fixer: progress

- Status: Green. FX4-8-rehearsal-rerun: the fail-first check and the fix for CLI-18 at 57732c8f, pre-check passed (11:32Z).
- Progress: 7 of 8 tasks merged (FX4-1 to FX4-7); FX4-8 in this session; no gate items (fix wave).
- Done: a style card tapped while another crew plays stops that run and starts its own crew's; the card shows its own result.
- Next: the lead corrects FX4-8's `files` (request FX4-R4), then FX4-8 is ready at 57732c8f.
- Blocked by: FX4-R4: FX4-8's `files` names `client/scripts/stage_rehearsal.gd`, which does not exist; the code is `client/world/stage_rehearsal.gd`, so the M48 guard refuses the change.
- Owner decision needed: none.

| Deliverable | Weight (h) | Status | Evidence |
|---|---:|---|---|
| FX4-1-transport: RB-27, RB-03, RB-04 | 3.5 | merged | lead cycle 155, `c28600bb` |
| FX4-2-trace-events: RB-31, RB-32, RB-41, RB-42 | 3.5 | merged | `8ed7538f` |
| FX4-3-replay-shop-nav: RB-43, RB-20, RB-58, RB-59 | 3.5 | merged | `8be82e6f` on main |
| FX4-4-audit-client: the client audit | 4 | merged | `d5c16216` on main |
| FX4-5-problem-strings: FX3-R1's two problem rows | 0.75 | merged | `d3183782` on main |
| FX4-6-device-replay-cap: SIM-2 and FX3-R3 on the device, CLI-23 | 1.0 | merged | `ee4d64aa` on main |
| FX4-7-curation-swap-weave: CLI-1 | 2.0 | merged | lead, `62240757` |
| FX4-8-rehearsal-rerun: CLI-18 | 0.75 | blocked (files path, FX4-R4) | `57732c8f` |

## Handoff

- Last verified commit: 57732c8f (pre-check green, 2026-11-24T11:32:03Z, "All checks passed."; client run 492 of 492).
- Commits, in order (on main merged at `b1913643`, lead cycle 176):
  - `c5eacd74`: the check, on its own (`client/tests/fix_audit_client_tests.gd`).
  - `5720ba99`: the same check compares the greedy crew's report at the
    tick the stage reached (a report read at tick 0 never equals one at
    the end). It still fails on main the same way (runs 1).
  - `57732c8f`: the fix (CLI-18) in `client/world/stage_rehearsal.gd`
    `run()`: a run asked for while one plays sets `playing = false` and
    starts the chosen crew's run, instead of finishing the one playing.
- **The corrected test** (done_when c): `_rehearsal_card_runs_its_own_crew`.
  On main it was a `_still_open("CLI-18", ...)` that passed while the
  defect held. It now checks: the cautious crew playing, the greedy card
  tapped, style `greedy`, `runs == 2`, and the stage's replay equal to
  `RulebornReplay.rehearse(island, greedy, "2", ...)`, commands and report.
  Note: on the `reset(1..8)` islands the cautious and greedy crews play the
  same replay for one seed (probed); the check tells the new run from the
  old by its run count and its own seed ("2", not "1").
- `_still_open` is now unused in that file; kept for the next open finding.

### The test, failing on main

`c5eacd74`, `python3 client/status.py`:

```text
  # playing true, card found true, style greedy, runs 1, greedy's own replay false
  tests: 491 of 492 passed — written to client/status.json
  FAILED: CLI-18: a style card tapped while another crew plays runs its own crew and shows its result (13)
```

And `5720ba99` with main's `stage_rehearsal.gd` (run.gd directly):
`not ok 187 - CLI-18 ... # playing true, card found true, style greedy, runs 1, greedy's own replay true`
(the same seed-1 replay, see the note above). After `57732c8f`: `ok 187`.

### Evidence

- `bash client/build.sh` on `57732c8f`: passes.
- `python3 client/status.py` on `57732c8f`: 492 of 492 (run.gd: `ok 187`).
- `python3 tools/coord/owners.py diff FX4-8-rehearsal-rerun
  origin/claude/videogame-project-analysis-ewkkk2 57732c8f`: fails,
  `not owned by FX4-8-rehearsal-rerun: client/world/stage_rehearsal.gd`.
  The task's `files` names `client/scripts/stage_rehearsal.gd` (as does
  `client.md` line 390), a path that does not exist. Request FX4-R4.
- The pre-check (`bash tools/run_checks.sh`, the full checks) on `57732c8f` (main merged at `b1913643`, after the fresh-container setup line): PASS, 11:32:03Z, "All checks passed.", recorded in `status/FX4.json`.
- `client/status.json` rewritten by the run was put back, not committed.

### Next step

When the lead corrects FX4-8's `files` to `client/world/stage_rehearsal.gd`
(FX4-R4), re-run the owners diff on 57732c8f (or on a fresh merge of main
with a fresh pre-check) and mark ready. Also for the lead (FX4-R4): mark
CLI-18 `fixed` in `docs/security/audit-2026-11/client.md` and correct its
"Where" path.

## Tried and failed

- FX4-7: a multi-line lambda inside `filter()` is a parse error in this
  GDScript; use a static func (`_whole`).
- FX4-7: a test fake's error body must be a code with an `ERR_` row in
  every language, or `tools/client_contract.py` fails (`unavailable` has
  none; `unreachable` does).

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
