# The UI wave's gate

The art director's gate for the UI wave (section 3.5 of `report.md`). AD owns
everything here except `verdicts/`, which the lead writes as the gate's
launcher.

| Path | What it is | Task |
|---|---|---|
| [rubric.md](rubric.md) | The 14 qualities as pass and fail criteria, with their anchors and the method per quality and asset class. Version 1 | P0-AD-rubric |
| [prompts/](prompts/README.md) | One judge prompt per judged quality (1, 2, 3, 6, 8, 9, 13, 14) | P0-AD-rubric |
| `golden/` | The golden set: `items.json`, its images, and `labels.md`, the owner's form for O3 | P0-AD-golden, P0-AD-golden-2 |
| `calibration.md` | The split into thirds, the catch rates per quality, the judge model chosen | P0-AD-calibrate |
| `verdicts/` | The gate's verdicts, `<task_id>/<sha>.json`, and the exceptions queue | the lead |

The scripts the gate uses (contact sheets, frame strips, crops, the image
checks, calibration) are in `tools/ui_gate/` (P0-AD-sheet, P0-AD-calibrate).
