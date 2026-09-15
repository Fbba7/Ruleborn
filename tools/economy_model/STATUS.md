# Economy model — work in progress

Rebuilds the day-by-day model §24 says generated the tables in §10.2, §14.2,
§14.3 and §5.5, which is not itself in the design document (gap G7 in
`docs/analysis/04-specification-gaps.md`).

**Status: incomplete and unvalidated. Do not rely on its outputs yet.**

## Where it got to

Reproduces the document's first ~30 days closely, then diverges:

| | Model | Published |
| --- | --- | --- |
| Starlight/day, day 31 | 17,773 | 17,300 (§9.3) |
| Starlight/day, day 301 | 98,187 | 256,100 (§9.3) |
| Keeper level 16 | day 29 | day 31 (§14.2) |
| Keeper level 40 | day 250 | day 181 (§14.2) |

## Two causes identified, not yet fixed

Both look like findings about the design rather than only model bugs, and both
need confirming before they go into the analysis.

**1. The heist crew is held out of the workforce for the whole day.**
Wrong: a heist is 3 minutes plus 45 minutes' rest (§11.6, §12.9). Correctly
modelled, 3 characters away for ~48 minutes × 4 heists is ~0.4 of a roster of 38.

*Possible finding:* "raiding more means earning less at home" (§11.6), which the
document calls the core trade-off linking the two halves of the game, is worth
under 1% of production. Taken with the §9.6 payout finding in
`docs/analysis/05-quantitative-findings.md` §2, the trade-off may not exist
numerically.

**2. Worker supply cannot fill the buildings the rules permit.**
At day 301 the model's universe has **118 producer worker slots against a roster
of 38** (3 at the Spire plus Hearth places, §11.5). Two thirds of production
capacity would be permanently unstaffable.

*Possible finding:* the Hearth/roster cap (§10.2, §11.5) and the per-realm
building counts (§5.2, §10.2) were tuned independently. This may also explain the
~40% production shortfall against §9.3 — or the published model may staff
buildings the roster cannot reach.

## Also logged, not yet in the contradiction register

**C18.** §9.1 gives Aether storage as `5,000 × Spire level + 3,000`; §10.2's Spire
table is a flat `5,000 × level` (5,000 at level 1, 50,000 at level 10).

## Next steps when work resumes

1. Fix the worker availability model; confirm or retire finding 1.
2. Confirm finding 2 against the published figures; decide whether the shortfall
   is a model artefact or a design gap.
3. Reconsider the purchase policy — "save for the next Spire level first" (§14.1)
   is currently implemented as reserving the Spire's full cost, which stalls all
   other spending from Spire 9 onward. Buying the Spire when affordable and the
   cheapest upgrade otherwise is the likelier reading.
4. Add `report.py`, `__main__.py` and tests asserting the published figures.
