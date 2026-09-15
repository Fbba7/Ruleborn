# Economy model

Rebuilds the day-by-day model §24 says generated the tables in §10.2, §14.2,
§14.3 and §5.5 of the design document, which is not itself in the document
(gap G7 in `docs/analysis/04-specification-gaps.md`).

```bash
python3 -m tools.economy_model                     # every report
python3 -m tools.economy_model positions           # one report
python3 -m tools.economy_model.test_economy_model  # tests
```

Reports: `production`, `positions`, `raiding`, `faucet`.

## What it is for

Two jobs. First, to make the economy re-derivable: no number in §10.2 or §14
could be re-tuned without it. Second, to settle the contradictions in
`docs/analysis/03-contradiction-register.md` with numbers rather than argument —
C2 (which raid-payout model) and C4 (what `L` is in `B(L)`) are both questions
the model answers.

## Calibration

The model reproduces the document's first month closely and its Keeper curve
within a few days, which is the evidence that the reconstruction is broadly
right:

| | Model | Published |
| --- | --- | --- |
| Starlight/day, day 31 | 17,773 | 17,300 (§9.3) |
| Keeper level 5 | day 4 | day 4 (§14.2) |
| Keeper level 10 | day 11 | day 12 |
| Keeper level 16 | day 29 | day 31 |

Late game it only matches under one particular reading of the build rules —
**one producer of each kind per realm, with no binding roster cap.** That
variant reaches Keeper 40 on day 171 against a published 181. Every other
reading is out by 2-4x in either direction. Since neither of those conditions
is what §5.2 and §11.5 actually say, that mismatch is itself a finding, recorded
as F1 and F2 in `docs/analysis/05-quantitative-findings.md`.

Run `python3 -m tools.economy_model production` to see all four readings side by
side.

## Known limits

- One-day granularity: within-day ordering of collection, spending and heists is
  approximated.
- The page economy is coarse — a flat rate per heist rather than per-law tracking
  — so law-restoration dates are indicative only.
- Strain uses mean stability costs by rank rather than each law's own cost, since
  the model does not track which laws are woven.
- Aether and Essence are produced and reported but not spent; weaving upkeep,
  births and character levels are not modelled. Starlight drives all growth here.

None of these affect the four findings, which turn on building counts, worker
slots and the payout formulas rather than on timing detail.

## Where the assumptions live

Every choice the document leaves open, and both halves of every contradiction,
are fields in `config.py` with the reasoning attached. `data.py` is transcription
only — nothing derived, so it can be checked against the document line by line.
