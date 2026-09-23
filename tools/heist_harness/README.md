# The heist harness

§19.27 in v3.0 removed both pre-code player tests and replaced them with
simulation. This is that simulation.

```bash
python3 -m tools.heist_harness                  # every report
python3 -m tools.heist_harness depth            # one report
python3 -m tools.heist_harness depth 500        # more runs a cell
python3 -m tools.heist_harness depth --sweep crack_reach   # brief 37 (§32.9, F35)
python3 -m tools.heist_harness.test_harness     # tests
```

Reports: `depth`, `defence`, `ablation`, `control`. A run takes about 80 ms, so §19.27's
"thousands of heists" is a couple of minutes.

## What it is for

§19.27 asks six questions and says how each is answered without players. Three of
them are this harness; the economy model answers a fourth, and the device spike
answers a fifth. Each report prints the section's own threshold beside the
measurement, and nothing here was tuned to meet one.

The sixth — *does delegated control feel like playing?* — is the one §19.27 says
cannot be simulated, and this harness does not pretend otherwise. What it checks
is the weaker, structural thing §19.27 actually asks for: that §12.18's rule
holds, and every state change traces to a command.

## What it models, and what it leaves out

| Modelled | Where from |
| --- | --- |
| Three vision zones, peripheral arc, suspicion, six guard states | §12.17, read from `content/detection.json` |
| Tile terrain with continuous position, breadth-first paths, fixed neighbour order | §12.18 |
| Cracking at one hit per 0.8 s for Power damage; loading at 30 units a second; the fill fraction banked | §12.19, §12.20 |
| Ten seconds down, revived in 3 s or 1.5 s by a Mender, loot dropped on the tile | §12.20 |
| Triggered wards, at §10.2's level scaling, with disarm timings | §10.3 and `docs/design/spec/wards.md` |
| A clock of 150 s plus 15 s a link, capped at 240 | §5.4 |
| Grades, and what each pays | §12.9, §9.6 |

Left out: laws, abilities, pylons, Sages, fights the crew starts, and the
Storehouses on the route. Every one of them **widens** the gap between skill
levels rather than narrowing it, so leaving them out makes the depth result
conservative. The decision count is the number they would move most, and the
report says so.

## Determinism

A run is a function of `(island seed, crew, policy)` and nothing else. No random
source is consulted inside the loop — §12.17's own requirement, since "a player
who scouts an island can predict exactly what will happen", and the property that
makes a replay checkable on the server (§24.10).

All arithmetic is integer: positions in 1/256 of a tile, angles in 1/1024 of a
turn, time in ticks at 30 Hz. `fixed.py` is the whole of it, in one file, so the
claim can be read rather than trusted. The seeded generator is SplitMix64, with a
reference stream in the tests so a port can be checked against it.

## Counting decisions

The most definition-sensitive number here, so the definition is in
`policy.py`'s header and repeated in the report:

> A decision is a point where the crew's commitment changed and more than one
> option was open.

An earlier version counted re-plans and scored 130 a run, every one of them the
pathfinder reacting to a guard turning its head. §12.5 has the player plan a
route *before* the heist; §12.6 lists what is decided *during* it, and every item
is a discrete event at a place. So a crew here holds a planned route and decides
at checkpoints — which is the model the document describes.

Per-member counts are printed alongside, because a number that moves by four
times with the definition should never be quoted alone.

## What it found

Run `python3 -m tools.heist_harness` for the current figures. As of the first
full run against v3.0:

- **§12.6's 15–25 decisions implies crossing two to three realms.** One realm
  gives 10 for an optimal crew, four gives 31. The band is a statement about how
  deep the target is, and §12.22's matchmaking does not mention depth.
- **The clock is not a pressure device.** Runs finish in 45–150 seconds against a
  clock of 150–195, so §19.27's "the last ten seconds decide the outcome in a
  quarter of them" is met in 0% of runs.
- **Generated defences do not reach §13.2's band until realm level 5.** A level-1
  generated island holds 2% of the time against a competent crew, against a
  target of 30–45%. v3.0's §13.3 makes generated defences every player's default
  and requires them to be "legal, coherent, and never empty" — which they are.
  Effective is a different requirement and is not stated.
- **Skill separates outcomes comfortably**: 64 to 70 points between careless and
  optimal, against §19.27's threshold of 35.
- **Guards and Response are the same layer.** §13.4's ablation, run in full with
  Shapley values, gives them identical shares — because neither turns back a
  single raid without the other, in any of the eight coalitions. §13.2 defines
  Response as "what turns being seen into being caught", which makes it
  multiplicative with Guards rather than additive. Together they are 69% of the
  defence, against a ceiling of 25% for any one layer.
- **Geometry is 4% of a generated defence**, against §13.2's 25% target — the
  layer it calls "the layer a thoughtful designer beats a richer player with".
- **The careful crew is never the best crew.** `optimal` matches or trails
  `competent` on success at every depth, because disarming wards and holding for
  cones costs more clock than it saves. Either those tools are underpriced or
  `optimal` is not optimal — and the harness is how to settle it. For
  disarming it is settled (D59): at fifteen seconds on the tile, going round
  beats disarming by some forty points at realm 3, and on a v3.4 island the
  optimal crew goes round every ward it can.
