# The UI wave's gate

The art director's gate for the UI wave (section 3.5 of `report.md`). AD owns
everything here except `verdicts/`, which the lead writes as the gate's
launcher.

| Path | What it is | Task |
|---|---|---|
| [rubric.md](rubric.md) | The 14 qualities as pass and fail criteria, with their anchors and the method per quality and asset class. Version 1 | P0-AD-rubric |
| [prompts/](prompts/README.md) | One judge prompt per judged quality (1, 2, 3, 6, 8, 9, 13, 14) | P0-AD-rubric |
| [shots.md](shots.md) | The shot format (a still and its control rectangles), the image checks and the sheets of `tools/ui_gate/` | P0-AD-sheet |
| [golden/](golden/README.md) | The golden set: `items.json`, its images, and `labels.md`, the owner's form for O3 | P0-AD-golden, P0-AD-golden-2 |
| [calibration.md](calibration.md) | The split into thirds, the anchors, the run plan, the catch rates per quality, the judge model chosen | P0-AD-calibrate |
| `calibration/runs/` | Each calibration run's plan, one judge call per line, written by `calibrate.py plan` | P0-AD-calibrate |
| [approvals/](approvals/O2.md) | AD's approvals in place of the owner (section 3.4 of `report.md`): `O2.md`, the style board and the kit contract | O2 |
| `verdicts/` | The gate's verdicts, `<task_id>/<sha>.json`, and the exceptions queue | the lead |

The scripts the gate uses (contact sheets, frame strips, crops, the image
checks, calibration) are in `tools/ui_gate/` (P0-AD-sheet, P0-AD-calibrate);
[shots.md](shots.md) says how to run them.
