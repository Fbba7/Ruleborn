# FX4 client fixer: progress

- Status: FX4-3-replay-shop-nav ready (RB-43, RB-20, RB-58, RB-59 fixed, each after a test that failed on main).
- Progress: 2 of 5 tasks merged (FX4-1, FX4-2); FX4-3 ready for the lead; no gate items (fix wave).
- Done: RB-43, RB-20, RB-58 and RB-59 fixed on claude/fix-client.
- Next: FX4-4-audit-client, in a fresh session once the lead merges FX4-3.
- Blocked by: none.
- Owner decision needed: none.

| Deliverable | Weight (h) | Status | Evidence |
|---|---:|---|---|
| FX4-1-transport: RB-27, RB-03, RB-04 | 3.5 | merged | lead cycle 155, `c28600bb` |
| FX4-2-trace-events: RB-31, RB-32, RB-41, RB-42 | 3.5 | merged | `8ed7538f` |
| FX4-3-replay-shop-nav: RB-43, RB-20, RB-58, RB-59 | 3.5 | ready | see Handoff |

## Handoff

- Last verified commit: the ready_sha in `status/FX4.json`: the merge of
  main `719c4ff3` into claude/fix-client plus the fixes (`8be82e6f`), plus
  this handoff.
- Commits, in order:
  - `5c2b7b1e` fail-first tests, committed on their own before any fix:
    `client/tests/fix_replay_shop_nav_tests.gd` (FixReplayShopNavTests),
    run from the aggregator `client/tests/fix_tests.gd`; `ae774848` adds
    its Godot `.uid`. (Both say WIP only because they were pushed before
    the run below; their content is unchanged since.)
  - `8433db74` RB-43: `client/ext/src/lib.rs`.
  - `ea49d46d` RB-20: `client/features/shop/shop_presenter.gd`.
  - `9309f5fb` RB-58: `client/app/router.gd`.
  - `041ec423` RB-59: `client/core/action_log.gd`.

### The tests, failing on main (before the fixes)

Run on `ae774848` (main's client plus the tests), Godot 4.7.2 headless, with
the server `client/status.py` starts: 450 of 454 passed, the four below
failed.

- **RB-43** (a heist played on an island other than the fixture realm, its
  replay handed to the result screen with no island, as a leased heist's
  is): `not ok 172 - RB-43: a leased heist's replay does not load on the
  fixture realm, so the result screen leaves the night empty; a fixture
  replay still loads with no island` with `started true, on its island
  true, on the fixture true, golden true, result night { "moments": 7,
  "ticks": 4500 }`.
- **RB-20** (`hatch-outfit` owned, not in the catalogue): `not ok 173 -
  RB-20: the free hatch outfit is an outfit, wearable from the shop as the
  server's kindOf reads it` with `kind_of '', shown { "id": "hatch-outfit",
  "kind": "", "name": " (hatch-outfit)", "wearable": false, "target": "",
  "worn_in": [] }`.
- **RB-58** (roster, a character opened with the roster's stage, filter
  and scroll, then the phone's back): `not ok 174 - RB-58: the phone's back
  from a character brings the roster back with its stage and filter` with
  `{ "name": &"roster", "params": {  } }`.
- **RB-59** (`router.go(&"shop")`): `not ok 175 - RB-59: a navigation in
  the action log names the screen` with `[{ "ms": 174893, "kind":
  "action", "what": "navigated", "fields": {  } }]`.

### The fixes

- **RB-43:** `RulebornReplay::load` checks the realm's digest against the
  replay's with no island too (the report's Fix line), so a replay played
  elsewhere is never shown on the fixture realm; the result screen then
  leaves the night empty, as its comment says. The golden replays, played
  on the fixture realm, still load with no island (the test checks
  `planned-clean.rbh`; every golden and stage test still passes). Not done:
  the report's "ideally keep the leased island in the HEIST state". The
  leased island's bytes are fetched in `client/scripts/heist_screen.gd`,
  which is not in this task's files, so a leased heist's result screen now
  shows no night rather than the right one. Request FX4-R1 in
  `status/FX4.json` asks for a follow-up task.
- **RB-20:** `ShopPresenter.kind_of` reads `hatch-outfit` as an outfit, as
  `server/src/shop.mjs` `kindOf` does; the shop shows it wearable, worn by
  a crew role.
- **RB-58:** `Router.go_back` carries the current route's `roster` param to
  the roster, as the character screen's own back button does.
- **RB-59:** `ActionLog.add` turns a StringName into a String before its
  type filter; a route's params (a Dictionary) are still left out (§20.5).

### Evidence

- On `041ec423`: `bash client/build.sh` exit 0; `python3 client/status.py`:
  454 of 454 passed; gdlint (with `client/gdlintrc`) on the changed files:
  no problems.
- The merge of main `719c4ff3` brought only docs/progress changes, no
  client file.
- Pre-check on the ready_sha: see `precheck` in `status/FX4.json`.
- `python3 tools/coord/owners.py diff FX4-3-replay-shop-nav
  origin/claude/videogame-project-analysis-ewkkk2 8be82e6f`: "every changed
  path is inside its files".

## Tried and failed

- `client/status.py` cannot start the server until the simulation's
  WebAssembly is built: `cd sim && cargo build --locked --release --target
  wasm32-unknown-unknown` first (the setup line adds the target but does not
  build it).
- The RB-03 overwrite passed on main by timing alone with the plain
  FakeTransport: the test's server delays the public route so the renewal
  lands while the public call is out.
- `client/tests/run.gd` is at gdlint's 1000-line limit: a later task adds its
  tests inside an aggregator such as FixTransportTests, not as new run.gd lines.
- A test that reads its FakeTransport after `Services.close()` hits a freed
  object (close queue_frees the transport) and aborts with no `ok`/`not ok`
  line: read what it recorded before close.
