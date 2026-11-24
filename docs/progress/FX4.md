# FX4 client fixer: progress

- Status: Green. FX4-5-problem-strings: the fail-first test and the two
  PROBLEM_ rows are pushed; the pre-check of 3231f78b is in the status file.
- Progress: 4 of 8 tasks merged (FX4-1 to FX4-4); FX4-5 in this session; no
  gate items (fix wave).
- Done: PROBLEM_ENTRANCEBLOCKED and PROBLEM_DUPLICATELAW in
  `client/i18n/strings.csv`, every locale column.
- Next: the lead merges FX4-5; then FX4-6-device-replay-cap.
- Blocked by: none.
- Owner decision needed: none.

| Deliverable | Weight (h) | Status | Evidence |
|---|---:|---|---|
| FX4-1-transport: RB-27, RB-03, RB-04 | 3.5 | merged | lead cycle 155, `c28600bb` |
| FX4-2-trace-events: RB-31, RB-32, RB-41, RB-42 | 3.5 | merged | `8ed7538f` |
| FX4-3-replay-shop-nav: RB-43, RB-20, RB-58, RB-59 | 3.5 | merged | `8be82e6f` on main |
| FX4-4-audit-client: the client audit | 4 | merged | `d5c16216` on main |
| FX4-5-problem-strings: FX3-R1's two problem rows | 0.75 | see status | see Handoff |

## Handoff

- Last verified commit: the ready_sha in `status/FX4.json` (3231f78b once
  its pre-check is recorded).
- Commits, in order:
  - `6293dc4c`: main merged (`7e95009c`, with FX3-2-island's
    `island::Problem` and FX4-4).
  - `c4cb11d0`: the test, on its own:
    `client/tests/fix_problem_strings_tests.gd` (FixProblemStringsTests)
    and its `.uid`, one line in `client/tests/fix_tests.gd`.
  - `3231f78b`: the two rows in `client/i18n/strings.csv`, after
    PROBLEM_EDGECLOSED.
- The names, checked against `sim/src/island.rs` on main: `Problem::ALL`
  ends with `EntranceBlocked` and `DuplicateLaw`; `RulebornIsland.problems()`
  gives each by its `{:?}` name, and the builder (`builder_screen.gd:515`) and
  curation (`curation_presenter.gd:235`) look up `"PROBLEM_" + name.to_upper()`.
- The words, worded like PROBLEM_LANDINGBLOCKED and PROBLEM_TOOMANYLAWS and
  using the terms of the neighbouring rows (Vault/Cofre/Tresor/Coffre;
  pylon/pilar/Pylon/pylône; woven/tecida/gewebt/tissée, as ERR_SLOT_TAKEN):
  - PROBLEM_ENTRANCEBLOCKED: "the entrance is on the Vault or blocked";
  - PROBLEM_DUPLICATELAW: "a law is woven on two pylons".
- `node art/ui/keyframes/build_words.mjs` rerun after the rows (M34): it
  wrote `words.js` with no change, so `words.js` is not committed.

### The test, failing on main

Run on `c4cb11d0` (main's strings), the scratch runner
`FixProblemStringsTests` alone:

```text
not ok 1 - FX4-5: the publish problem EntranceBlocked is shown in words, not as its key
  # Strings.t("PROBLEM_ENTRANCEBLOCKED") gave "PROBLEM_ENTRANCEBLOCKED"
not ok 2 - FX4-5: the publish problem DuplicateLaw is shown in words, not as its key
  # Strings.t("PROBLEM_DUPLICATELAW") gave "PROBLEM_DUPLICATELAW"
not ok 3 - FX4-5: an island with its entrance under a pillar names EntranceBlocked, in words
  # problems ["EntranceBlocked"], shown as their key ["EntranceBlocked"]
3 checks, 3 failed
```

The third check builds a real island (a blank realm 1 with a rock pillar
on its entrance, the south-east corner) and shows every problem the
extension names has its words. DuplicateLaw cannot be made through the
extension's verbs (`weave` lifts a law from its old pylon, RB-50), only by
decoded bytes, so checks 1 and 2 test both keys directly. After `3231f78b`:
3 checks, all `ok`.

### Evidence

- `python3 client/status.py` on `3231f78b`: 471 of 471 passed.
- `bash client/build.sh`: passes.
- `gdlint` on the two test files: no problems.
- `python3 tools/check_docs_consistency.py`: passes.
- `python3 tools/coord/owners.py diff FX4-5-problem-strings
  origin/claude/videogame-project-analysis-ewkkk2 3231f78b`: every changed
  path is inside its files.
- The pre-check (`bash tools/run_checks.sh`, the full checks on the merge of
  current main) is recorded in `status/FX4.json` (`precheck`).
- Fresh container: the setup line, then `npm ci` in `tools/ui_research`, then
  `bash client/build.sh`. `client/status.py` also needed the simulation's
  WebAssembly build (`cargo build --release --target
  wasm32-unknown-unknown` in `sim/`) before the server would start; see
  Tried and failed.

### Follow-ups still standing (from FX4-4, in the backlog)

- CLI-1 is FX4-7-curation-swap-weave; CLI-18 is FX4-8-rehearsal-rerun;
  CLI-23 rides FX4-6-device-replay-cap.
- CLI-3 (High, unproven), CLI-8 and CLI-9 (server contract notes) and
  FX4-R1 stand as written in
  [`client.md`](../security/audit-2026-11/client.md) and the status file.

## Tried and failed

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
