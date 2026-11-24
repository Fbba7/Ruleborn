# FX4 client fixer: progress

- Status: Green. FX4-7-curation-swap-weave: the fail-first test and the
  client fix for CLI-1; ready at 62240757 (main merged).
- Progress: 6 of 8 tasks merged (FX4-1 to FX4-6); FX4-7 in this session; no
  gate items (fix wave).
- Done: while a swapped slot weaves, the island is published without the
  swapped law's pylon and the slot is shown weaving with its ready time;
  once woven, the next curation publishes the new law's pylon.
- Next: the lead merges FX4-7; then FX4-8-rehearsal-rerun.
- Blocked by: none.
- Owner decision needed: none.

| Deliverable | Weight (h) | Status | Evidence |
|---|---:|---|---|
| FX4-1-transport: RB-27, RB-03, RB-04 | 3.5 | merged | lead cycle 155, `c28600bb` |
| FX4-2-trace-events: RB-31, RB-32, RB-41, RB-42 | 3.5 | merged | `8ed7538f` |
| FX4-3-replay-shop-nav: RB-43, RB-20, RB-58, RB-59 | 3.5 | merged | `8be82e6f` on main |
| FX4-4-audit-client: the client audit | 4 | merged | `d5c16216` on main |
| FX4-5-problem-strings: FX3-R1's two problem rows | 0.75 | merged | `d3183782` on main |
| FX4-6-device-replay-cap: SIM-2 and FX3-R3 on the device, CLI-23 | 1.0 | merged | `ee4d64aa` on main |
| FX4-7-curation-swap-weave: CLI-1 | 2.0 | ready | `62240757`, pre-check below |

## Handoff

- Last verified commit: 62240757, the ready_sha in `status/FX4.json`.
- Commits, in order:
  - `a97ae895`: the test, on its own (`client/tests/fix_audit_client_tests.gd`).
  - `c1064608`: the fix (CLI-1), in `client/features/curation/` and
    `client/i18n/strings.csv`.
  - `77192ea2`: the test's unreachable server answers `unreachable`, a code
    the client words (`tools/client_contract.py` flagged `unavailable`,
    which has no `ERR_` row). No expectation changed.
  - `62240757`: main merged (lead cycles 173 and 174); clean, no conflict.
- **The corrected test** (done_when f): `_swap_publish_is_refused_while_weaving`
  in `client/tests/fix_audit_client_tests.gd`. On main it was a
  `_still_open("CLI-1", ...)` that passed while the defect held (woven,
  published with the new law's pylon, refused as `island_not_publishable`).
  It now checks the behaviour in four checks, against an `IslandServer` fake
  that answers as SR-16 does: `law_not_woven` or `woven_law_missing` as
  422 `island_not_publishable`, and 503 when it is down.
- SR-16 stays: no server change. The fix is client-side, in
  `curation_controller.gd`:
  - `apply_swap` weaves first. A refused weave goes to `curation_failed`
    and publishes nothing, so nothing is charged for it. A woven swap
    whose slot has a ready time is saved as a record
    `{realm, slot, law, old, at, ready_at}` in
    `user://curation-weaving.json` (`at` is the tile of the old law's
    pylon). Then the draft is published.
  - `_publish` first settles the draft (`_settled`): while a record is not
    ready, its tile is cleared of the old and the new law's pylon. Once it
    is ready, the new law's pylon is placed on that tile, if the tile is
    empty and the law has no pylon elsewhere. The island then passes
    SR-16 at every step.
  - The screen: `curation_weaving` puts `{slot: ready_at}` in the slice.
    `CurationPresenter.laws` shows that slot as `CUR_SLOT_WEAVING` ("Slot
    %d: %s, weaving, ready in %s", via `WeavingPresenter.duration`) and
    refuses another swap on it with `CUR_WEAVING_WHY`. A post cannot be
    moved onto a weaving tile (`post_cannot_move`).
- **How the new pylon is published once woven** (done_when b): when
  curation next opens after `ready_at`. `load_curation` ends with
  `_settle`, which drops records whose slot no longer holds their law,
  places the woven pylons and publishes, said `CUR_SAID_WOVEN` ("The swap
  is woven and its pylon is on your defence"). A save or a swap made after
  `ready_at` with the screen still open does the same, because `_publish`
  settles first. There is no timer on an open screen:
  `client/scripts/curation_screen.gd` is not this task's.
- **A failed publish after the weave** (done_when c) is said as
  `swap_unsaved` ("the swap is weaving but your defence could not be saved;
  it is saved when you next open curation"), never as done. The record is
  kept, so the next curation retries it. A record is dropped only after a
  publish succeeds once its `ready_at` has passed.
- Strings: `ERR_SWAP_UNSAVED`, `CUR_SLOT_WEAVING`, `CUR_WEAVING_WHY`,
  `CUR_SAID_WOVEN`, in all six locales. `node
  art/ui/keyframes/build_words.mjs` was run again; `words.js` did not
  change, because none of these strings is in the keyframes.
- **Request FX4-R3 to the lead** (default: the lead does it when it merges):
  mark CLI-1 `fixed` in `docs/security/audit-2026-11/client.md` line 43,
  which FX4-7 does not own.

### The test, failing on main

Run on `a97ae895` (main's curation plus the test), `python3 client/status.py`:

```text
489 of 492 passed — written to client/status.json
  FAILED: CLI-1: a swap woven publishes the island without the swapped law's pylon while its slot weaves, and the slot is shown weaving with its ready time (13.3, 5.6)
  FAILED: CLI-1: once the swapped slot is woven, curation opened publishes the new law's pylon where the old one stood (13.3, 5.6)
  FAILED: CLI-1: a publish that fails after the swap is woven is said on the screen, never said done, and retried when curation next opens (13.3)
```

The fourth check ("a swap the server refuses to weave publishes nothing and
says why") already held on main; it guards the fix. After `c1064608`, all
four pass.

### Evidence

- `bash client/build.sh` on `c1064608`: passes.
- `python3 client/status.py` on `77192ea2`: 492 of 492 passed.
- `python3 tools/client_contract.py`: passes after `77192ea2`.
- `python3 tools/coord/owners.py diff FX4-7-curation-swap-weave
  origin/claude/videogame-project-analysis-ewkkk2 62240757`: every changed
  path is inside its files.
- The pre-check (`bash tools/run_checks.sh`, the full checks, which run
  `tools/check_all.sh`) on `62240757`: running; its result goes in
  `status/FX4.json` (`precheck`).
- `client/status.py` rewrites `client/status.json`; it was put back and
  not committed.

### Follow-ups still standing (from FX4-4, in the backlog)

- CLI-1 is fixed in FX4-7 (above); CLI-18 is FX4-8-rehearsal-rerun;
  CLI-23 is fixed in FX4-6 (merged, `ee4d64aa`).
- CLI-3 (High, unproven), CLI-8 and CLI-9 (server contract notes) and
  FX4-R1 stand as written in
  [`client.md`](../security/audit-2026-11/client.md) and the status file.

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
