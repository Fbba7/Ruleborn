# What a raid pays — reconciled specification

**Status: proposed.** This resolves C2 and C4 together, because neither can be
settled alone. It needs sign-off before any balance work (§26.7).

Reports: `python3 tools/decision_support.py haul`.
Model: [`tools/economy_model/`](../../../tools/economy_model/README.md).

---

## The problem

§9.4 pays a raider a percentage of what the **defender** holds. §9.6 replaces it
with a haul minted from the raider's own level:

```
Haul = B(L) × grade × difficulty × richness × fatigue
B(L) = 100 × 1.5^(L−1)
```

§9.6 states plainly that its grade term supersedes §12.9's, so the newer model is
meant to win. But §9.4's percentages and §12.9's multipliers were never removed,
and two things are wrong with the replacement as written.

**First, `L` names a level range that does not exist.** §9.6's table quotes realm
levels 2, 6 and 10; §5.2 caps outer realms at 5. §9.4 attributes the same
40%→71.5% sealed-share curve to the **Vault**, which does run 1–10 — so §9.6
appears to have conflated Vault level with realm level, then built what it calls
"the master inflation lever" on top of the conflation.

**Second, whatever `L` means, the payout is an order of magnitude below the
document's own target.** §9.4 says a successful heist brings about a fifth of a
day's production, so heists supply "roughly a third" of resources; §12.1 says 40%
of mid-game growth. Running each reading of `L` through the economy model:

| Reading of `L` | `L` at day 181 | `B(L)` | Six raids a day | Share of income |
| --- | --- | --- | --- | --- |
| Vault level (1–10) | 6 | 759 | 1,450 | **2.4%** |
| Realm level (1–5) | 4 | 338 | 645 | **1.1%** |
| Keeper level ÷ 4 | 7 | 1,139 | 2,176 | **3.5%** |

None comes close to a third. §9.4's model, by contrast, reproduces its own stated
target almost exactly — 32%. That is strong evidence §9.4 generated the published
progression tables in §10.2 and §14, and §9.6 was added afterwards without
re-running them (C19).

---

## The structural finding: no growth rate fixes this

The obvious repair is to raise `1.5` until the share is right. It does not work,
and why it does not work is the useful part.

Solving for the growth rate that would put raids at a third of income, with `L` as
Vault level:

| Day | Production/day | `B(L)` needed | `L` | Growth rate needed |
| --- | --- | --- | --- | --- |
| 31 | 17,773 | 4,652 | 4 | **3.60** |
| 91 | 59,154 | 15,485 | 6 | 2.74 |
| 181 | 79,932 | 20,924 | 7 | 2.44 |
| 301 | 132,642 | 34,722 | 8 | **2.31** |

The required rate is not constant, so no single value holds the ratio steady.
**Production compounds as 1.35 per building level across a growing number of
buildings; the haul compounds as g per Vault level across a handful of levels.**
They are different curves. Whichever `g` is chosen, the raid share drifts — and
the drift runs the wrong way, thinning the loop exactly as the player invests in
it.

---

## Recommendation: peg the haul to the raider's own production

```
Haul = P × 0.20 × grade × difficulty × richness × fatigue
```

where **P is the raider's own daily production**, and everything else is §9.6's,
unchanged.

### Why this is not a retreat to §9.4

§9.6's argument against a percentage is specific and correct:

> In those games the loot leaves the defender, so the money supply is unchanged;
> here it is created, so tying the payout to how much people hoard would tie the
> inflation rate to behaviour we neither see clearly nor control. — §9.6

That objection is to pegging against **the defender's hoard**. Pegging against
**the raider's own production** has none of it: production is not hoarding
behaviour, it is the quantity the designer already controls precisely, through
building costs and the 1.35 curve. It is also the quantity the whole progression
curve in §14 is built on, so the two stop being independent systems that must be
held in agreement by hand.

### What it does

| | Value |
| --- | --- |
| Six raids a day | 0.382 × daily production |
| Raids as a share of total income | **27.6%, at every stage of the game** |
| Engaged player, 4 heists a day (§14.1) | 22.7% |
| Regular player, 2 heists | 14.5% |
| Casual player, 1 heist | 8.4% |

The share is stable by construction, and it scales with how much a player
actually raids — so raiding more genuinely earns more, at every stage, which is
what §11.6 claims and what F3 shows is currently untrue.

### It is not a runaway loop

Haul is a fixed multiple of production, so income becomes `(1 + 0.38) × P`. That
is a constant factor on growth, not a divergence, because building costs compound
geometrically too. It is also precisely how the published tables were generated —
§14.1 states the assumption: *"a successful heist brings about a fifth of a day's
production."*

### What it preserves from §9.6

Everything except the level term. **Grade** (clean 1.0, loud 0.7, partial 0.4,
foiled 0), **difficulty** (punching up pays more, farming the weak pays almost
nothing), **richness** (the target's wealth nudges within a clamp, and a fully
sealed island still pays), **fatigue** (0.85 per successive raid), and all three
caps — per raid, per day, per week at five days rather than seven — carry over
untouched. So does the health signal: weekly growth in what players are holding.

### The one real cost

A player who neglects buildings earns smaller hauls, which could read as
punishing a raid-focused player. Two mitigations, both already in §9.6's
machinery: floor `P` at the level median before applying the formula, and let the
difficulty term keep rewarding punching up. Worth watching in soft launch as its
own metric — the spread of haul sizes within a Renown band.

---

## What this forces elsewhere

| Section | Change |
| --- | --- |
| **§9.4** | Delete the percentage-of-holdings rules. Keep the sealed share, the Vault and Storehouse exposure, and the entry fee — those describe what a raider *sees*, not what they are paid |
| **§9.6** | Replace `B(L)` with `P × 0.20`. Delete the `L` table. Keep every other term and every cap |
| **§12.9** | Delete the loot column; the grade term owns it. Fix the Renown column too, which mixes percentages with an absolute formula (C14) |
| **§12.1** | "About 40% of mid-game growth" becomes about a quarter, and should say it varies with how much the player raids |
| **§12.6** | Say what Carrier capacity and the 150/s load rate now mean. They no longer cap value, so they are a time-pressure device: how long the crew must stand exposed at the Vault. That is a good mechanic — it just has to be stated, because "when to stop loading" is named as the Vault phase's core decision and currently has nothing behind it (G4) |
| **§14** | Regenerate §10.2, §14.2 and §14.3 from the model once F1, F2 and C19 are settled — not by hand |

---

## Dependencies

This cannot be locked before three things are decided, because all of them change
`P`:

- **F1 / Q1** — the roster cannot staff the buildings the rules permit (152
  positions against 38 characters), so production as published is unreachable.
- **F2 / Q4** — one producer per realm or two. Two roughly doubles `P`, and
  therefore doubles every haul under this formula.
- **C19** — §9.3's published production figures assume a universe §5.2 and §11.5
  do not describe.

None of that argues against the formula. It argues that the formula makes the
dependency explicit, where `B(L)` hid it: under a production peg, fixing
production fixes raiding automatically, and the two can no longer drift apart.

---

## Still open

- **F3 / Q2** — this fixes the *return* side of the raid-versus-build trade-off
  but not the *cost* side. Raiding still withholds only about 2% of the roster
  from work. Making crew membership exclude work, the way guarding does, is the
  other half.
- **The 0.20 coefficient** is §9.4's own figure and has never been playtested.
  It is now the single dial, so it should be the one number soft launch watches
  hardest.
- Whether six raids a day (§9.6's cap table) or four (§14.1's engaged player) is
  the planning assumption. They differ by a third in total income.
