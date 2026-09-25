# Economy model

Rebuilds the day-by-day model §24 says generated the tables in §10.2, §14.2,
§14.3 and §5.5 of the design document, which is not itself in the document
(gap G7 in `docs/analysis/04-specification-gaps.md`).

```bash
python3 -m tools.economy_model                     # every report
python3 -m tools.economy_model positions           # one report
python3 -m tools.economy_model.test_economy_model  # tests
```

Reports: `production`, `positions`, `raiding`, `faucet`, `sinks`, `scaling`,
`raidworth` and `rerun`.

## The document's own run

`Config.document("low" | "high")` is the model as §14.1 and §14.2 say the
document's tables are generated: §5.8's three rules, §9.6's haul from
`design_facts` (the 0.1222–0.1698 band, keyed to the target's Vault level, and
the owner's base: 5,000 where the document ships 2,400, F36 and F53), §10.2 read from `content/buildings.json`, births bought in Essence at
§9.5's rate after the roster's keep, and §7.6's pages and Codex chapters.
The owner's other answers are in it too: the fee as 2% of B(V), returned after
a clean or loud heist and half after a partial one, and counted in the
raid-worth check (F39, C41); strays that join at a birth's price (F38); a
non-raider's daily goals and the tutorial's two ruins (F37); the season
track's free rewards (G28); free scouting (F46); and the Heart at realm level
3 (G19). Everything else in `config.py` keeps the model the findings were
measured on, so they still reproduce.

```bash
python3 -m tools.economy_model raidworth   # §9.6's raid-worth check (F36)
python3 -m tools.economy_model rerun       # §32.9's full re-run, as pacing.md prints it
```

`rerun.py` sets the base, then the birth rate (§9.5's order), and prints every
table at both edges of the band; `tools/generate_docs.py` writes it to
`docs/design/generated/pacing.md`. What it does not carry is listed at the foot
of that page.

## What it is for

Two jobs. First, to make the economy re-derivable: no number in §10.2 or §14
could be re-tuned without it. Second, to settle the contradictions in
`docs/analysis/03-contradiction-register.md` with numbers rather than argument —
C2 (which raid-payout model) and C4 (what `L` is in `B(L)`) are both questions
the model answers.

There is now a third job: to keep the *proposals* honest too. The payout peg
recommended in `docs/design/spec/economy.md` is implemented as
`Config(faucet="pegged")`, so the behaviour that page claims for it is asserted
by tests rather than by prose. `faucet` takes `"share"` (§9.4), `"minted"`
(§9.6) or `"pegged"` (the proposal), and the `faucet` report prints all three
against each other.

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

The historical model (the default `Config()`):

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

`Config.document()` spends Essence on births and levels, keeps pages by §7.6's
sources and chapters, and carries storage, the entry fee and strays. What it
still leaves out is `rerun.NOT_MODELLED`, printed at the foot of `pacing.md`;
what it chooses where the document is silent is `rerun.CHOICES`, printed with
what each alternative moves.

## Where the assumptions live

Every choice the document leaves open, and both halves of every contradiction,
are fields in `config.py` with the reasoning attached. `data.py` is transcription
only — nothing derived, so it can be checked against the document line by line.
