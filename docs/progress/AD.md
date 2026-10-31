# AD art director: progress

- Status: Green: pre-check PASS at 7d8c4ed (2026-10-31T02:25:32Z); the last push holds the golden set part 1 (`gate/golden/`), ready.
- Progress: 2 of 8 tasks merged (P0-AD-rubric, P0-AD-sheet); O2 ready (586cc5a); P0-AD-golden ready (7d8c4ed); 0 items passed by the gate (AD's tasks carry no gate items).
- Done: P0-AD-rubric and P0-AD-sheet (merged); O2 (ready); P0-AD-golden: 45 items, 27 expected to fail, 16 borderline, 9 of them planted fails, and the labelling form `labels.md` (238 rows).
- Next: O2-2 (waits for P0-AIA-board-3 and P0-K1-contract-2), then P0-AD-golden-2 (waits for P0-AIA-keyframes-3).
- Blocked by: none.
- Owner decision needed: none from AD. P0-K1-contract-2 may prepare decision brief entries for §21.2's menu backdrop and §21.8's red and green words on dark surfaces.

| Deliverable | Weight (h) | Status | Evidence |
|---|---:|---|---|
| P0-AD-rubric: rubric v1 and judge prompts | 3 | merged (167ccf6c) | `gate/rubric.md`, `gate/prompts/*.md`; pre-check PASS at 334224c, 2026-10-30T01:44:46Z (`All checks passed.`, `DONE exit=0`) |
| P0-AD-sheet: `tools/ui_gate/sheet.py` and image checks | 3 | merged | pre-check PASS at f5e9571, 2026-10-30T23:20:33Z (`All checks passed.`, `DONE exit=0`); `python3 tools/ui_gate/sheet.py --self-test` passes (planted fails for value steps, HUD share and hierarchy); `gate/shots.md` |
| O2: approve the board and kit contract | 0.5 | ready (586cc5a) | pre-check PASS at 586cc5a, 2026-10-31T01:04:30Z (`All checks passed.`, `DONE exit=0`); `gate/approvals/O2.md`; value steps measured with `tools/ui_gate/checks.py`; `check_docs_consistency.py` clean |
| P0-AD-golden: golden set part 1 | 2 | ready (7d8c4ed) | pre-check PASS at 7d8c4ed, 2026-10-31T02:25:32Z (`All checks passed.`, `DONE exit=0`); `gate/golden/items.json`, `images/`, `labels.md`, `README.md`; `python3 tools/ui_gate/golden.py check` ("45 items, 238 label rows"), run by `sheet.py --self-test` in `check_all.sh` |
| O2-2: re-approve the redirected points | 0.5 | open (waits for P0-AIA-board-3, P0-K1-contract-2) | |
| P0-AD-golden-2: golden set part 2 | 1 | open (waits for P0-AD-golden, P0-AIA-keyframes-3) | |
| O3: label the golden set | 2.5 | open (waits for P0-AD-golden-2) | |
| P0-AD-calibrate: calibration | 3 | open (waits for O3) | |

## Handoff
- Last verified commit: 7d8c4ed (pre-check green, 2026-10-31T02:25:32Z).
- Done: P0-AD-golden. `tools/ui_gate/golden.py` builds `gate/golden/images/` from `items.json` (sources cropped; planted fails made by flatten, low_value, hue_mirror and unstroked, each naming the quality it breaks), writes the empty form `labels.md` from `labels-head.md`, and checks items, images and form. Sources: the audit screenshots and "client today" icons (fail), the v3 stills (fail), the fourteen-quality proofs (pass), the O2 board plates (pass but light and icons; enamel and wood borderline after O2 B4 and B11), the AI artist icons (pass). Expectations and reasons are in items.json, not in the form, so O3's labels test them.
- Half done: nothing.
- Open hypotheses: the expected labels on the board items follow O2; when P0-AIA-board-3 rebakes board.png, the board items' crops (in pixels of board.png at 2x) may move and their images change, so P0-AD-golden-2 re-measures the plate rectangles and rebuilds (`golden.py build`; `golden.py check` catches a size change). The O2 hypotheses on quality 8's ring measure and rubric version 2 (quality 2's "gradient", quality 14's glass) still stand for P0-AD-calibrate.
- Next step: P0-AD-golden is ready at 7d8c4ed. Next session: O2-2 if P0-AIA-board-3 and P0-K1-contract-2 have merged, else P0-AD-golden-2 once P0-AIA-keyframes-3 has merged.

## Tried and failed
- 2026-10-30 first pre-check of f5e9571: failed at the wasm32 cargo build because this container lacked the wasm32-unknown-unknown target (setup step skipped); installed it and re-ran: PASS
- 2026-10-31 first two pre-checks of 7d8c4ed: failed at the wasm32 cargo build, then at `gdlint: command not found`, because this fresh container was not set up (agent-brief "Starting a session", step 2); ran `rustup target add wasm32-unknown-unknown aarch64-linux-android aarch64-apple-ios` and `pip install "gdtoolkit==4.*" "playwright==1.63.0"`, re-ran: PASS
