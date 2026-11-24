# SP-bt-04 the gate shot renderer: progress

- Status: Green pending; the last push holds BT-04a's renderer, its fixtures and its README line; the pre-check at f1df3f1e is running.
- Progress: 0 of 2 tasks merged; 0 items passed by the gate (BT-04a has no gate items).
- Done: `tools/gate/render.py` (shot list format, still rendering of a listed item at a given sha, 960 px grayscale, manifest) and its fixtures.
- Next: record the pre-check, mark BT-04a ready; then BT-04b (frame strips, 200% text and high-contrast variants, named crops) in a later session.
- Blocked by: none.
- Owner decision needed: none.

| Deliverable | Weight (h) | Status | Evidence |
|---|---:|---|---|
| BT-04a: shot list format and still renderer | 3 | working | `python3 tools/gate/render.py --self-test` at 548732a3: parser ok, fixture item ok (14 s warm); `render.py still "heist at 200% text, pt_BR"` and `"result in high contrast"` at 43deab02: all stills fit ok |
| BT-04b: strips, variants, crops | 2 | open | |

## Handoff

- Last verified commit: f1df3f1e (pre-check running, started 17:58 UTC)
- Done: `tools/gate/render.py still "<item>" --sha <sha> --out <dir> [--list <shots.json>]` checks the sha out in a temporary worktree under `~/.cache/ruleborn/gate`, builds the GDExtension there (cached by the git trees of `sim/` and `client/ext/`, cargo's target directory shared), copies the goldens and seeds Godot's import cache from this checkout's `client/.godot`, then runs `FIT=1 <settings> bash tools/render/shoot.sh <script> <png>` from the worktree for each still of the item, writes `<still>.gray.png` (960 px, `tools/ui_gate/sheet.py still --gray`) and `stills.json` (sha, list and its hash, each still's settings, fit ok / FAIL / not printed). Exit 1 when a still is missing or its fit is not ok. `list` and `plan` print what an item would run. The format is in the script's docstring; the example list is `tools/gate/fixtures/shots.json` (heist, result with its off and srv states, home, character, roster, settings), the test list `tools/gate/fixtures/test_shots.json`.
- Items read as "<screen> at <n>% text[, <locale>]" or "<screen> in high contrast" need no entry; anything else needs an explicit item. "heist at 200% text, pt_BR, no crew plan" is refused today (its setting is not documented): request SP-bt-04-R2 to AD.
- Timing: first render in a fresh container about 3 minutes (one cargo build), then about 15 s for the settings fixture, about 55 s for the heist.
- Requests: SP-bt-04-R1 (lead adds `python3 tools/gate/render.py --self-test` to `tools/check_all.sh` beside the sheet self-test; check_all is not in this task's files), SP-bt-04-R2 (AD adopts the list at `docs/art/ui-quality/gate/shots.json`, which the renderer reads first when it exists).
- Open hypotheses: two renders at once share cargo's lock and write the library cache through a per-process temporary file, so they should not clash; not tested under load.
- Next step: record the pre-check; if PASS, set `task_state: ready` and `ready_sha`, `agent_state: waiting`.

## Tried and failed

- 2026-11-24 the self-test first expected a 1080 × 2340 still: `screen_settings.gd` renders at 540 × 1170, so the test now checks only that the still is not tiny and that its grayscale is 960 px, gray and not blank.
