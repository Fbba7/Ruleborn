# The judge's calibration

Section 3.5 of `../report.md` ("Calibration") sets the method; this page holds
the split, the run plan, the results per quality, the judge model chosen and
the rubric version they hold for. `tools/ui_gate/calibrate.py` does the
counting (P0-AD-calibrate).

## Where it stands

- **Rubric version 1** (`rubric.md` and `prompts/`, as merged at 167ccf6c) and
  **golden set version 1** (`golden/items.json` version 1, 60 items; the labels
  in `golden/labels.md` and `golden/labels-blind.md` as O3 merged them at
  316ff98c) are the versions calibrated. Neither changes during calibration
  except through step 5 below, which bumps the rubric's version and is logged
  in `rubric.md`'s "Versions".
- **No quality is calibrated yet.** The gate runs are the lead's to launch
  (P0-AD-calibrate's title; section 3.3 of `../report.md`, "The gate's runs
  through the wave"), and none has run. Until a quality meets the target
  below, the gate runs in **shadow mode** on it: its verdicts block nothing,
  and every item of that quality goes on AD's board before it merges
  (section 3.5 of `../report.md`; `agent-protocol.md`, "Before calibration").
  Today that is all eight judged qualities: 1, 2, 3, 6, 8, 9, 13 and 14.
- **Owner-checked qualities:** none yet. A quality becomes owner-checked only
  after both models miss it (step 5); AD then checks it on every board.

## The split

`golden.py split` dealt the thirds before O3 (stratified by class, expected
label, borderline flag and origin), so that the held-out third was labelled
blind (`golden/labels-blind.md`). `calibrate.py split` prints this table.

| Third | Use | Items | Screens | Kit art | Icons | Expected fails | Borderline | Plants |
|---|---|---:|---:|---:|---:|---:|---:|---:|
| 1 | training: the anchors, and AD reads it to write the prompts | 20 | 10 | 6 | 4 | 11 | 6 | 5 |
| 2 | development: both models run here; prompts are tuned here | 20 | 11 | 5 | 4 | 10 | 6 | 4 |
| 3 | held out: measured once per rubric version | 20 | 11 | 6 | 3 | 11 | 6 | 4 |

AD's labels at O3, per quality and third, as fails / passes (`n/a` rows are not
measured):

| Quality | Third 1 | Third 2 | Third 3 |
|---|---|---|---|
| 1. Layered materials | 10 / 10 | 9 / 11 | 16 / 4 |
| 2. Display type | 9 / 7 | 7 / 9 | 11 / 6 |
| 3. Painted or rendered icons | 7 / 7 | 6 / 9 | 11 / 3 |
| 6. Hierarchy | 2 / 8 | 7 / 4 | 9 / 2 |
| 8. Colour roles and value | 5 / 15 | 6 / 14 | 7 / 13 |
| 9. Character presence | 4 / 4 | 7 / 2 | 7 / 3 |
| 13. Light behind UI | 6 / 14 | 4 / 16 | 12 / 8 |
| 14. One art-direction idea | 3 / 7 | 2 / 9 | 8 / 3 |

The held-out third is heavy in fails because O3 labelled every row where AD
and the blind labeller disagreed as fail (29 rows). Its false-block figures
rest on few passes (2 to 13 per quality), so they are rough; section 3.5's
step 3 expects that, and the weekly audit's labels are the real test.

## The anchors

Each call shows the judge a PASS ANCHOR and a FAIL ANCHOR of the candidate's
class, drawn from the training third only, so no measured item is ever an
anchor. The PASS ANCHOR is the weakest pass: a borderline natural item first,
then a borderline plant, then any pass. The FAIL ANCHOR is the strongest fail:
a borderline natural item first, then a plant (one quality away from a pass),
then any fail. Ties go to the first in `items.json`. `calibrate.py anchors`
prints them:

| Class | Quality | PASS ANCHOR | FAIL ANCHOR |
|---|---|---|---|
| screen | 1, 3, 6, 8, 13, 14 | kf-character-text200 | today-heist |
| screen | 2 | plant-heist-dim | today-heist |
| screen | 9 | today-heist | today-result |
| kit art | 1 | t14-hud-top | plant-hud-top-flat |
| kit art | 2, 8, 13 | plant-hud-top-flat | plant-kf-result-flat |
| icon | 1, 3, 13 | ai-chest | plant-starlight-flat |
| icon | 8 | ai-chest | none: the training third has no icon labelled fail on 8 |

Where a class has no FAIL ANCHOR, the call shows the PASS ANCHOR alone; the
prompt's rule still holds (at least as good as the bar passes).

## The runs

Each run is one model on one third, three samples per row, the pictures in a
new shuffled order on each call. The judge sees each picture under a blind
code (`g` and eight hex digits, salted by the run), copied to a folder outside
the repository, so neither a file name nor `items.json` beside it gives the
label away. The plans are committed in `calibration/runs/<run>/plan.jsonl`.

| Run | Model | Third | Rows | Calls (before splits) | Status |
|---|---|---:|---:|---:|---|
| `dev-fable` | Fable 5.1 | 2 | 122 | 366 | planned; waits for the lead |
| `dev-opus` | Opus 5.5 | 2 | 122 | 366 | planned; waits for the lead |
| `held-<model>` | the model chosen | 3 | 123 | 369 | planned once the model is chosen (step 4) |

What the launcher does for each run (request AD-R6):

    python3 tools/ui_gate/calibrate.py render --run dev-fable --out <dir outside the repo>
    # one fresh read-only ui-judge call per <dir>/calls/<call>.md, on the run's model;
    # each answer, as {"call", "answer", "region", "reason"}, one per line, into
    # docs/art/ui-quality/gate/verdicts/P0-AD-calibrate/dev-fable.jsonl
    python3 tools/ui_gate/calibrate.py extra --run dev-fable <that file>   # samples 4-6 for splits
    # render again and run the new calls the same way, appending to the same file

Then AD scores it:

    python3 tools/ui_gate/calibrate.py score --run dev-fable <that file> --markdown

## The steps and the target

1. Run `dev-fable` and `dev-opus` on the development third.
2. Score both. Per quality: the **catch rate** (AD's fails the judge fails
   under the D-06 rule), the **false-block rate** (AD's passes it fails) and
   the share **sent to exceptions** (any UNKNOWN). Counts, not percentages
   alone.
3. **The target:** catch at least 80%, false blocks at most 20%, exceptions
   at most 30%, on every judged quality.
4. **The judge model:** Fable 5.1, unless Opus 5.5 catches more on the
   development third; then Opus 5.5, and the blind audit doubles.
5. **A quality that misses** on the development third: AD revises its prompt
   against the training and development critiques (a rubric version bump),
   at most twice, re-running the development third; if it still misses, the
   other model is tried; if both miss, it becomes owner-checked.
6. **The held-out third** is then run once on the chosen model and the
   current rubric version. Its figures are the ones that decide whether a
   quality leaves shadow mode. Any later rubric edit re-runs it.
7. **The blind audit (O6)** draws its sample with `calibrate.py audit` from
   the verdict files: 10–20 items the gate passed, spread over the classes,
   mixed with 3–5 it failed, as a form without the verdicts.

## Results

None yet. Each run's `score --markdown` table goes here, with the date, the
rubric version and the run's commit.

| Quality | Judge | Rubric | Third 3: fails caught | False blocks | To exceptions | State |
|---|---|---|---|---|---|---|
| 1. Layered materials | – | 1 | – | – | – | shadow |
| 2. Display type | – | 1 | – | – | – | shadow |
| 3. Painted or rendered icons | – | 1 | – | – | – | shadow |
| 6. Hierarchy | – | 1 | – | – | – | shadow |
| 8. Colour roles and value | – | 1 | – | – | – | shadow |
| 9. Character presence | – | 1 | – | – | – | shadow |
| 13. Light behind UI | – | 1 | – | – | – | shadow |
| 14. One art-direction idea | – | 1 | – | – | – | shadow |
