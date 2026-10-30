# AD art director: progress

- Status: Green on the quick checks and the gate's self-tests; the last push holds `tools/ui_gate/` and `gate/shots.md` (P0-AD-sheet). The full checks need README.md's tools listing, which is the lead's (AD-R2).
- Progress: 1 of 5 tasks merged (P0-AD-rubric); 0 items passed by the gate (AD's tasks carry no gate items).
- Done: P0-AD-rubric (merged); P0-AD-sheet's scripts, tests and documentation.
- Next: when AD-R2 is answered, re-run the pre-check and mark P0-AD-sheet ready; then O2 and P0-AD-golden as their deps merge.
- Blocked by: AD-R2 (the lead adds `tools/ui_gate/` to README.md's tools listing).
- Owner decision needed: none.

| Deliverable | Weight (h) | Status | Evidence |
|---|---:|---|---|
| P0-AD-rubric: rubric v1 and judge prompts | 3 | merged (167ccf6c) | `gate/rubric.md`, `gate/prompts/*.md`; pre-check PASS at 334224c, 2026-10-30T01:44:46Z (`All checks passed.`, `DONE exit=0`) |
| P0-AD-sheet: `tools/ui_gate/sheet.py` and image checks | 3 | blocked on AD-R2 | `python3 tools/ui_gate/sheet.py --self-test` passes (planted fails for value steps, HUD share and hierarchy); `gate/shots.md` |
| P0-AD-golden: golden set part 1 | 2 | open (waits for P0-AD-sheet, P0-AIA-board-2) | |
| O2: approve the board and kit contract | 0.5 | open (waits for P0-AIA-board-2) | |
| O3: label the golden set | 2.5 | open (waits for P0-AD-golden-2) | |
| P0-AD-golden-2: golden set part 2 | 1 | open (waits for P0-AD-golden, P0-AIA-keyframes-3) | |
| P0-AD-calibrate: calibration | 3 | open (waits for O3) | |

## Handoff
- Last verified commit: 9281bc3 on `claude/ui-ad` (the gate's self-tests and the docs check, except the README listing). SCRATCH_RESULT
- Done: `tools/ui_gate/colour.py` (L*, grayscale of equal L*, Machado 2009 colour-blindness matrices); `checks.py` (value steps with a 4 pt ring that leaves out other controls and fails when it cannot measure; HUD share as an exact union of rectangles; hierarchy ratio and second-level count); `sheet.py` (still, contact at 48 and 96 pt at 1080/390 px a point with grayscale rows, strip, full-resolution crops, colour-blindness sheet; `--self-test` runs all three files' tests); `gate/shots.md` (the shot format, the checks and sheets); `gate/README.md` row.
- Half done: nothing in my files. The task is blocked on AD-R2 (README.md listing, the lead's) and asks AD-R3 (check_all wiring).
- Open hypotheses: hierarchy reads the rubric literally, so a primary over 2 times the next control fails; and "about five" second-level things is taken as six pass, seven fail. Calibration (P0-AD-calibrate) is where either would loosen, as rubric version 2.
- Next step: when AD-R2 lands on main, merge main, `bash tools/run_checks.sh start`, wait, record, mark P0-AD-sheet ready.

## Tried and failed
- (none yet)
