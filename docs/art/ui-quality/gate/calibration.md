# The judge's calibration

Section 3.5 of `../report.md` ("Calibration") sets the method; this page holds
the split, the run plan, the results per quality, the judge model chosen and
the rubric version they hold for. `tools/ui_gate/calibrate.py` does the
counting (P0-AD-calibrate).

## Where it stands

- **Rubric version 3** (`rubric.md` and `prompts/`, P0-AD-calibrate-2, 3
  November 2026; step 5's second and last revision) is the version being
  calibrated, with **golden set version
  1** (`golden/items.json` version 1, 60 items; the labels in
  `golden/labels.md` and `golden/labels-blind.md` as O3 merged them at
  316ff98c). Version 1 (as merged at 167ccf6c) missed the target on all eight
  qualities with both models on the development third (Results below); step
  5's first revision (version 2) added each quality's "Rulings from
  calibration"; version 2 then met the target on 1, 2, 8 and 14, and the
  second revision (version 3) added rulings for 6, 9 and 13. Both are logged
  in `rubric.md`'s "Versions". The labels did not change.
- **The judge is Opus 5.5** (step 4): on the development third it caught 33 of
  the 48 fails, against Fable 5.1's 23, and caught at least as many on every
  quality; and the owner's order of 4 November 2026 (root `CLAUDE.md`) bans
  Fable 5.1 for good, so no other model is tried. So the blind audit doubles (section 3.5 of `../report.md`).
- **No quality is calibrated.** `held-opus` (Opus 5.5, rubric version 3,
  measured once on 4 November 2026) missed the target on all eight judged
  qualities (Results, "Held-out third"). The gate keeps running in **shadow
  mode**: its verdicts block nothing, and every item goes on AD's board
  before it merges (section 3.5 of `../report.md`; `agent-protocol.md`,
  "Before calibration").
- **Owner-checked qualities: all eight, 1, 2, 3, 6, 8, 9, 13 and 14.** Step
  5's two revisions are spent and no other model may be tried (Fable 5.1 is
  banned), so each quality that misses on the held-out third is
  owner-checked: AD checks it on every board, and the judge's verdict on it
  is advice only. A quality leaves this list only through a later rubric or
  golden set version that meets the target on a fresh held-out
  measurement.

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
| `dev-fable` | Fable 5.1 | 2 | 122 | 366 | run by the lead on rubric version 1 (78 extra calls for splits); scored below |
| `dev-opus` | Opus 5.5 | 2 | 122 | 366 | run by the lead on rubric version 1 (48 extra calls for splits); scored below |
| `dev-opus-v2` | Opus 5.5 | 2 | 122 | 366 | rubric version 2 (step 5's first re-run), run in a launcher session (72 extra calls); scored below |
| `dev-opus-v3` | Opus 5.5 | 2 | 122 | 366 | rubric version 3 (step 5's second and last re-run); stopped with the program on 3 November at 193 calls, resumed on 4 November (60 extra calls); scored below |
| `dev-fable-v3` | Fable 5.1 | 2 | 122 | 366 | rubric version 3 (step 5's other-model try); abandoned at 120 calls by the owner's order of 4 November 2026 (Fable 5.1 banned); not scored, its results kept as written |
| `held-opus` | Opus 5.5 | 3 | 123 | 369 | rubric version 3, the held-out run, measured once; stopped with the program on 3 November at 103 calls, resumed on 4 November (45 extra calls); scored below |

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
4. **The judge model:** Opus 5.5, and the blind audit doubles. (The plan
   named Fable 5.1 unless Opus 5.5 caught more; Opus 5.5 caught more, and the
   owner's order of 4 November 2026 in the root `CLAUDE.md` bans Fable 5.1
   for good.)
5. **A quality that misses** on the development third: AD revises its prompt
   against the training and development critiques (a rubric version bump),
   at most twice, re-running the development third; if it still misses
   with Opus 5.5, it becomes owner-checked (no other model is tried, since
   Fable 5.1 is banned).
6. **The held-out third** is then run once on the chosen model and the
   current rubric version. Its figures are the ones that decide whether a
   quality leaves shadow mode. Any later rubric edit re-runs it.
7. **The blind audit (O6)** draws its sample with `calibrate.py audit` from
   the verdict files: 10–20 items the gate passed, spread over the classes,
   mixed with 3–5 it failed, as a form without the verdicts.

## What to expect

O3's agreement between AD and the blind labeller on the held-out third was 94
of 123 rows. It was weakest on 13 (12 of 20) and 14 (6 of 11), then 9 (7 of
10) and 3 (10 of 14). These are the first candidates for step 5, with what O3
found the rubric leaves open:

- **13. Light behind UI:** whether high contrast may drop the reward glow or
  the panels' light.
- **14. One art-direction idea:** how much plain chrome a screen may carry
  before it fails.
- **2. Display type:** "word over art" reads a backdrop gradient as art, which
  fails the plain-backdrop key frames in normal mode.
- **3. Painted or rendered icons:** rubric version 1 names ai-essence as a
  clear pass in words, though O3 failed it (its refraction reads as
  physically based). The words are examples only since O3; the anchors above
  are the golden set's, so this needs no edit before the first run.

A plant is scored on every row AD labelled, not only on the quality it was
built to break: O3 found plants that break more than one (the flattened icons
also fail 13).

## Results

Each run's `score --markdown` table goes here, with the date, the rubric
version and the run's commit.

### Development third, rubric version 1 (3 November 2026)

The lead's runs, merged at 720e309e
(`verdicts/P0-AD-calibrate/dev-fable.jsonl` and `dev-opus.jsonl`), scored by
AD with `calibrate.py score`.

| Quality | Fable 5.1: fails caught | False blocks | To exceptions | Opus 5.5: fails caught | False blocks | To exceptions |
|---|---|---|---|---|---|---|
| 1. Layered materials | 5 of 9 | 3 of 11 | 0 of 20 | 8 of 9 | 5 of 11 | 0 of 20 |
| 2. Display type | 5 of 7 | 3 of 9 | 1 of 16 | 6 of 7 | 4 of 9 | 0 of 16 |
| 3. Painted or rendered icons | 3 of 6 | 4 of 9 | 2 of 15 | 5 of 6 | 7 of 9 | 0 of 15 |
| 6. Hierarchy | 2 of 7 | 0 of 4 | 0 of 11 | 4 of 7 | 1 of 4 | 0 of 11 |
| 8. Colour roles and value | 2 of 6 | 1 of 14 | 0 of 20 | 3 of 6 | 1 of 14 | 0 of 20 |
| 9. Character presence | 3 of 7 | 1 of 2 | 0 of 9 | 3 of 7 | 0 of 2 | 0 of 9 |
| 13. Light behind UI | 2 of 4 | 0 of 16 | 0 of 20 | 2 of 4 | 0 of 16 | 0 of 20 |
| 14. One art-direction idea | 1 of 2 | 1 of 9 | 0 of 11 | 2 of 2 | 4 of 9 | 0 of 11 |

Both models missed on every quality. What the misses had in common, which
rubric version 2's rulings answer:

- the high-contrast mode's opaque cards failed as "web overlay" (1) or "app
  chrome" (14), though they are the game's own form;
- display type on a card's own gloss was read as "over art" and asked for an
  outline (2), while headline figures on plates went unchecked;
- abstract marks (pips, toggles) were judged as icons (3), and screens with
  no currency were sent to UNKNOWN;
- the primary action was not named, so a rival panel or a gold second passed
  (6), and gold fills on non-actions passed (8);
- one physically based portrait among game models passed (9), and faint stars
  on a dark backdrop passed as a lit scene (13).

### Development third, rubric version 2 (3 November 2026)

`dev-opus-v2`, run in a launcher session and pushed at b5141ba9
(`calibration/runs/dev-opus-v2/results.jsonl`, 438 calls with the splits'
samples 4-6), scored by AD with `calibrate.py score`. No call went to
exceptions.

| Quality | Opus 5.5: fails caught | False blocks | To exceptions | Target |
|---|---|---|---|---|
| 1. Layered materials | 8 of 9 | 2 of 11 | 0 of 20 | met |
| 2. Display type | 7 of 7 | 1 of 9 | 0 of 16 | met |
| 3. Painted or rendered icons | 5 of 6 | 7 of 9 | 0 of 15 | missed |
| 6. Hierarchy | 7 of 7 | 2 of 4 | 0 of 11 | missed |
| 8. Colour roles and value | 6 of 6 | 2 of 14 | 0 of 20 | met |
| 9. Character presence | 4 of 7 | 0 of 2 | 0 of 9 | missed |
| 13. Light behind UI | 3 of 4 | 1 of 16 | 0 of 20 | missed |
| 14. One art-direction idea | 2 of 2 | 1 of 9 | 0 of 11 | met |

Rubric version 3 answers the misses on 6, 9 and 13 (`rubric.md`,
"Versions"). Quality 3 is not revised: its false blocks are law and
currency glyphs that the golden labels pass and that read as flat both to
the judge and to AD on review, so the question is the golden set's labels,
not the rubric's wording.

### Development third, rubric version 3 (4 November 2026)

`dev-opus-v3` (`calibration/runs/dev-opus-v3/results.jsonl`, 426 calls with
the splits' samples 4-6, pushed at 38ebfb5f), scored by AD with
`calibrate.py score`. The rulings fixed what they aimed at (6 and 9 now meet
the target, 13 lost its false block), but 1, 8 and 14 slipped back by one or
two false blocks each, and 13 is still one catch short. With two to four
passes in some rows of a third, one picture moves a quality across the line.
`dev-fable-v3` is not scored (abandoned; Fable 5.1 banned).

| Quality | Opus 5.5: fails caught | False blocks | To exceptions | Target |
|---|---|---|---|---|
| 1. Layered materials | 8 of 9 | 4 of 11 | 0 of 20 | missed |
| 2. Display type | 7 of 7 | 1 of 9 | 0 of 16 | met |
| 3. Painted or rendered icons | 5 of 6 | 7 of 9 | 0 of 15 | missed |
| 6. Hierarchy | 6 of 7 | 0 of 4 | 0 of 11 | met |
| 8. Colour roles and value | 6 of 6 | 3 of 14 | 0 of 20 | missed |
| 9. Character presence | 7 of 7 | 0 of 2 | 0 of 9 | met |
| 13. Light behind UI | 3 of 4 | 0 of 16 | 0 of 20 | missed |
| 14. One art-direction idea | 2 of 2 | 2 of 9 | 0 of 11 | missed |

### Held-out third

`held-opus` (`calibration/runs/held-opus/results.jsonl`, 414 calls with the
splits' samples 4-6, pushed at 1c886ca4), measured once on rubric version 3
and scored by AD with `calibrate.py score`.

| Quality | Judge | Rubric | Third 3: fails caught | False blocks | To exceptions | State |
|---|---|---|---|---|---|---|
| 1. Layered materials | Opus 5.5 | 3 | 15 of 16 | 2 of 4 | 0 of 20 | owner-checked |
| 2. Display type | Opus 5.5 | 3 | 9 of 11 | 2 of 6 | 1 of 17 | owner-checked |
| 3. Painted or rendered icons | Opus 5.5 | 3 | 11 of 11 | 2 of 3 | 0 of 14 | owner-checked |
| 6. Hierarchy | Opus 5.5 | 3 | 7 of 9 | 0 of 2 | 0 of 11 | owner-checked |
| 8. Colour roles and value | Opus 5.5 | 3 | 3 of 7 | 3 of 13 | 0 of 20 | owner-checked |
| 9. Character presence | Opus 5.5 | 3 | 7 of 7 | 1 of 3 | 0 of 10 | owner-checked |
| 13. Light behind UI | Opus 5.5 | 3 | 5 of 12 | 1 of 8 | 0 of 20 | owner-checked |
| 14. One art-direction idea | Opus 5.5 | 3 | 4 of 8 | 3 of 3 | 0 of 11 | owner-checked |

Every quality missed. What the misses show, for the next rubric or golden
set version (each needs a fresh held-out measurement):

- **Too few passes to measure false blocks.** Five qualities have two to
  four passes in the held-out third (6: 2; 3, 9 and 14: 3; 1: 4), so a
  single false block there is 25% to 50%. Qualities 1, 3, 6 and 9 caught at
  least 7 of 9 and missed on one or two pictures. A golden set version 2
  with more passing items per quality would make the target measurable.
- **Real catch gaps on 8, 13 and 14:** 3 of 7, 5 of 12 and 4 of 8. The same
  failing screens pass all three (`today-home`, `v3-result`,
  `today-character`, `today-hud-bottom`), with reasons that the rulings
  invite: gold "only on the main action" (8), "a visible light source" and
  glow on the scene behind the UI (13), "the same toy-box idiom" as the pass
  anchor (14). The labels fail these screens on details the judge does not
  weigh, so the next version should name those details per item, from the
  owner's notes in `golden/labels-blind.md`.
- **Quality 3** catches 11 of 11, but its false blocks are again the flat
  law and currency glyphs the golden labels pass; AD proposes relabelling
  them in golden set version 2 rather than bending the rubric.
