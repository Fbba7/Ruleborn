# AD art director: progress

- Status: Green: pre-check PASS at f5e9571 (2026-10-30T23:20:33Z); the last push holds P0-AD-sheet, ready, with AD-R2's README line.
- Progress: 1 of 5 tasks merged (P0-AD-rubric); P0-AD-sheet ready; 0 items passed by the gate (AD's tasks carry no gate items).
- Done: P0-AD-rubric (merged); P0-AD-sheet (ready at f5e9571).
- Next: O2 and P0-AD-golden when P0-AIA-board-2 and P0-K1-contract merge.
- Blocked by: none.
- Owner decision needed: none.

| Deliverable | Weight (h) | Status | Evidence |
|---|---:|---|---|
| P0-AD-rubric: rubric v1 and judge prompts | 3 | merged (167ccf6c) | `gate/rubric.md`, `gate/prompts/*.md`; pre-check PASS at 334224c, 2026-10-30T01:44:46Z (`All checks passed.`, `DONE exit=0`) |
| P0-AD-sheet: `tools/ui_gate/sheet.py` and image checks | 3 | ready (f5e9571) | pre-check PASS at f5e9571, 2026-10-30T23:20:33Z (`All checks passed.`, `DONE exit=0`); `python3 tools/ui_gate/sheet.py --self-test` passes (planted fails for value steps, HUD share and hierarchy); `gate/shots.md` |
| P0-AD-golden: golden set part 1 | 2 | open (waits for P0-AD-sheet, P0-AIA-board-2) | |
| O2: approve the board and kit contract | 0.5 | open (waits for P0-AIA-board-2) | |
| O3: label the golden set | 2.5 | open (waits for P0-AD-golden-2) | |
| P0-AD-golden-2: golden set part 2 | 1 | open (waits for P0-AD-golden, P0-AIA-keyframes-3) | |
| P0-AD-calibrate: calibration | 3 | open (waits for O3) | |

## Handoff
- Last verified commit: f5e9571 (pre-check green, 2026-10-30T23:20:33Z).
- Done: P0-AD-sheet: `tools/ui_gate/` (colour.py, checks.py, sheet.py with `--self-test`), `gate/shots.md`, the `gate/README.md` row, and the README.md tools line (AD-R2's exception). Main merged at f5e9571.
- Half done: nothing.
- Open hypotheses: hierarchy reads the rubric literally (a primary over 2 times the next control fails; six second-level things pass, seven fail); calibration (P0-AD-calibrate) may loosen either as rubric version 2.
- Next step: the lead adds `python3 tools/ui_gate/sheet.py --self-test` to check_all.sh and a numpy line to checks.md in the merging candidate (AD-R3). Then take O2 or P0-AD-golden as P0-AIA-board-2 and P0-K1-contract merge.

## Tried and failed
- 2026-10-30 first pre-check of f5e9571: failed at the wasm32 cargo build because this container lacked the wasm32-unknown-unknown target (setup step skipped); installed it and re-ran: PASS
