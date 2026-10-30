# AD art director: progress

- Status: Green on the quick checks; the last push holds gate rubric version 1 and the eight judge prompts (P0-AD-rubric), pre-check running.
- Progress: 0 of 5 tasks merged; 0 items passed by the gate (AD's tasks carry no gate items).
- Done: `docs/art/ui-quality/gate/rubric.md` version 1 (14 qualities, pass and fail criteria, design rules folded in, extreme anchors, method per quality and asset class); `gate/prompts/` for qualities 1, 2, 3, 6, 8, 9, 13 and 14; `gate/README.md`.
- Next: record the pre-check, mark P0-AD-rubric ready; then P0-AD-sheet once the rubric merges.
- Blocked by: none.
- Owner decision needed: none. The owner reviews the rubric's anchors beside the golden set at O3.

| Deliverable | Weight (h) | Status | Evidence |
|---|---:|---|---|
| P0-AD-rubric: rubric v1 and judge prompts | 3 | pre-check running | `gate/rubric.md`, `gate/prompts/*.md`; `python3 tools/check_docs_consistency.py` clean |
| P0-AD-sheet: `tools/ui_gate/sheet.py` and image checks | 3 | open (waits for the rubric to merge) | |
| P0-AD-golden: golden set part 1 | 2 | open (waits for P0-AD-sheet, P0-AIA-board-2) | |
| P0-AD-golden-2: golden set part 2 | 1 | open (waits for P0-AD-golden, P0-AIA-keyframes-3) | |
| P0-AD-calibrate: calibration | 3 | open (waits for O3) | |

## Handoff
- Last verified commit: pending the pre-check (see `docs/progress/status/AD.json`, `precheck`).
- Done: rubric version 1; prompts for every judged quality; the gate folder's index.
- Half done: nothing.
- Open hypotheses: the value step (ΔL* ≥ 20 on medians, with a 4 pt ring of ground) is AD's own definition for version 1; P0-AD-sheet implements it and the golden set will show whether it is too strict for leather on the violet card. The anchors are provisional stills from `docs/art/ui-quality/` until O3.
- Next step: when the pre-check passes, record it and mark ready; next session takes P0-AD-sheet (implement the value step, HUD share and colour-blindness sheet the rubric names).

## Tried and failed
- (none yet)
