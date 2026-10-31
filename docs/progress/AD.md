# AD art director: progress

- Status: Green: pre-check PASS at a392bcb (2026-10-31T06:36:42Z); the last push holds O2-2's decision, `gate/approvals/O2-2.md`, ready.
- Progress: 4 of 8 tasks merged (P0-AD-rubric, P0-AD-sheet, O2, P0-AD-golden); O2-2 ready (a392bcb); 0 items passed by the gate (AD's tasks carry no gate items).
- Done: P0-AD-rubric, P0-AD-sheet, O2 and P0-AD-golden (merged); O2-2: every redirected point approved (board B3, B4, B5, B11; contract K1-K3); the board and sections 2-6 of kit-spec.md are in effect.
- Next: P0-AD-golden-2 (waits for P0-AIA-keyframes-3), then O3 and P0-AD-calibrate.
- Blocked by: none.
- Owner decision needed: none from AD. Two rows of kit-spec.md section 2.1 (success words on dark; the menus' backdrop shape) stay pending the brief entries K1-R4 asked the lead for.

| Deliverable | Weight (h) | Status | Evidence |
|---|---:|---|---|
| P0-AD-rubric: rubric v1 and judge prompts | 3 | merged (167ccf6c) | `gate/rubric.md`, `gate/prompts/*.md`; pre-check PASS at 334224c, 2026-10-30T01:44:46Z (`All checks passed.`, `DONE exit=0`) |
| P0-AD-sheet: `tools/ui_gate/sheet.py` and image checks | 3 | merged | pre-check PASS at f5e9571, 2026-10-30T23:20:33Z (`All checks passed.`, `DONE exit=0`); `python3 tools/ui_gate/sheet.py --self-test` passes (planted fails for value steps, HUD share and hierarchy); `gate/shots.md` |
| O2: approve the board and kit contract | 0.5 | merged (fdd82b7c) | pre-check PASS at 586cc5a, 2026-10-31T01:04:30Z (`All checks passed.`, `DONE exit=0`); `gate/approvals/O2.md`; value steps measured with `tools/ui_gate/checks.py`; `check_docs_consistency.py` clean |
| P0-AD-golden: golden set part 1 | 2 | merged (a38a3790) | pre-check PASS at 7d8c4ed, 2026-10-31T02:25:32Z (`All checks passed.`, `DONE exit=0`); `gate/golden/items.json`, `images/`, `labels.md`, `README.md`; `python3 tools/ui_gate/golden.py check` ("45 items, 238 label rows"), run by `sheet.py --self-test` in `check_all.sh` |
| O2-2: re-approve the redirected points | 0.5 | ready (a392bcb) | pre-check PASS at a392bcb, 2026-10-31T06:36:42Z (`All checks passed.`, `DONE exit=0`); `gate/approvals/O2-2.md`; `checks.py value-steps` passes on all 11 controls of `board.png` and `board_hc.png` (BUILD ΔL* 26.6, was 6.2); every contrast figure in kit-spec.md's revised rows recomputed and matching; `check_docs_consistency.py` clean |
| P0-AD-golden-2: golden set part 2 | 1 | open (waits for P0-AD-golden, P0-AIA-keyframes-3) | |
| O3: label the golden set | 2.5 | open (waits for P0-AD-golden-2) | |
| P0-AD-calibrate: calibration | 3 | open (waits for O3) | |

## Handoff
- Last verified commit: a392bcb (pre-check green, 2026-10-31T06:36:42Z).
- Done: O2-2. Approved all seven redirected points: B3 (leather off a lit oak well, ΔL* 26.6), B4 (enamel gloss band over the top 38%, 3-pt rim, 6-pt foot), B5 (gold rim and foot, no glow), B11 (studio.html: one toon shader, four-step ramp, violet shade, no metalness or reflections); K1 (section 2.1 takes §21.2's and §21.8's values; success words on dark and the backdrop's radial stay pending owner decisions with O2's rulings 1 and 2), K2 (T2 over art, T0 with drop on calm surfaces), K3 (tertiary an inked plate). O2's interim rulings 3 and 4 end; 1 and 2 are now the contract's rows.
- Half done: nothing.
- Open hypotheses: the brief entries for the two pending rows are not in `brief.json` yet (the lead waits for SV-B11-B12's register items). The O2 hypotheses on quality 8's ring measure and rubric version 2 (quality 2's "gradient", quality 14's glass) still stand for P0-AD-calibrate.
- Next step: P0-AD-golden-2 once P0-AIA-keyframes-3 merges: re-measure the board plates on the rebaked `board.png` (`golden.py build`, then `check`) and re-read the expected labels of the light, icon, enamel and wood items against O2-2.md.

## Tried and failed
- 2026-10-30 first pre-check of f5e9571: failed at the wasm32 cargo build because this container lacked the wasm32-unknown-unknown target (setup step skipped); installed it and re-ran: PASS
- 2026-10-31 first two pre-checks of 7d8c4ed: failed at the wasm32 cargo build, then at `gdlint: command not found`, because this fresh container was not set up (agent-brief "Starting a session", step 2); ran `rustup target add wasm32-unknown-unknown aarch64-linux-android aarch64-apple-ios` and `pip install "gdtoolkit==4.*" "playwright==1.63.0"`, re-ran: PASS
