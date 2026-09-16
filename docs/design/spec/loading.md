# When to stop loading — proposed specification

**Status: proposed.** This resolves F19, F20 and F21 — three readings of one
measurement: what a crew actually does in §12.19's Vault phase, and what the
document assumes it does.

It also records two findings that **did not survive**, F18 and the first version
of F19, because the route from the wrong answer to the right one is the useful
part of this file. Both were measured through a harness that did not implement
§12.19's own stated price.

Reports: `python3 -m tools.heist_harness breakeven` and
`python3 -m tools.heist_harness depth`.

---

## Two harness faults had to be fixed before any of this was measurable

**D24 — the Vault phase was two seconds long.** The crew policy ended it the
moment *any* member's bag filled. A Scout holds 60 and fills in two seconds, so
the whole crew left after two, with the Carrier — 300 of the crew's 560 — walking
out on 60. Every crew banked 53% whatever the island did.

Fixed, §12.19's own claim reproduces exactly: **a crew told to take everything
spends 10.0 seconds loading and ends full**, from the role Carry values and the
stated rate, unasserted.

**D25 — no crew could see the clock.** §12.19's break-even rests on one clause:
*"loading longer earns more and **the alarm clock is the price**."* No policy in
the harness read `heist.clock`. The first clock experiment — shorten §5.4's clock
and watch the stopping decision move — showed nothing move, and that looked like
a finding. It was a fact about the harness.

Crews now leave when the time left no longer covers the walk home, estimated the
way a player would: the way out is the way in, so what it cost to reach the Vault
is what it will cost to leave, plus 15%. The estimate is deliberately
conservative — the way in is crouched, the way out is a run — so crews leave a
little earlier than they need to, which biases every number below downward.

---

## §12.19's claim, and how to check it

> *"The break-even sits at about 70% full — at that point the extra load is worth
> exactly what a loud exit costs. **That single number is the dial for the game's
> emotional peak.**"*

§9.6 says exactly what a raid is worth: `B(V) × grade × difficulty × richness ×
fatigue × fill`. A stopping rule moves two of those — **grade** and **fill** — so
what a crew maximises is `E[grade × fill]`, and a break-even is where it stops
rising.

---

## F20: the best fixed rule is about 90% full

Same islands, same seeds, 300 raids a row. Only the stopping threshold varies:

| stops at | E[grade × fill] | success |
| ---: | ---: | ---: |
| 50% | 0.1022 ± 0.0089 | 56.7% |
| 60% | 0.1113 ± 0.0103 | 53.3% |
| **70%** — §12.19's | 0.1271 ± 0.0116 | 56.7% |
| 80% | 0.1315 ± 0.0128 | 55.3% |
| **90%** | **0.1646 ± 0.0157** | 54.7% |
| 100% | 0.1589 ± 0.0161 | 53.3% |

**Loading past 70% is worth about 30% more per attempt and costs nothing
measurable in success rate.** A break-even exists, as §12.19 says. It sits about
twenty points above where §12.19 puts it, which makes the region the document
calls the decision a slope.

### Settled at §13.4's own sample size

The table above reads a peak off an argmax, which is a noisy statistic — and at
these sample sizes the 70%-vs-90% comparison is only about t = 2.3, run several
times. Marginal evidence, repeated, is how the two withdrawn findings below
happened. So it was re-run paired over the same seeds at **700 raids a
threshold**:

| stops at | E[grade × fill] | vs 70% | success |
| ---: | ---: | ---: | ---: |
| 70% | 0.1231 | — | 53.3% |
| 80% | 0.1370 | +0.0139 ± 0.0077 (t = 1.8) | 53.0% |
| **90%** | **0.1595** | **+0.0364 ± 0.0080 (t = 4.5)** | 52.0% |

That settles it. +30% an attempt for 1.3 points of success rate.

It also sizes the test: `test_the_break_even_is_not_at_12_19s_seventy_per_cent`
now runs 300 raids a threshold, because the per-seed standard deviation of 0.212
makes a 120-raid version fail about one build in twelve for no reason.

### But no fixed rule is the best rule

A crew that reads §12.17's visible suspicion — push to 95% when nothing has
noticed, leave at 35% when something has — scores **0.187**, beating the best
fixed threshold by 13%.

So the decision §12.6 asks for is real. It is just not the decision §12.19
describes. §12.19 specifies a number; the measurement says the answer is a
*rule that varies with what the guards are doing*, and §12.17 already gives the
player everything needed to run it. The document does not connect them.

### The clock is not the price, and cannot be made into it

§12.19 names the price itself. Tested directly: cutting §5.4's clock to 55% of
its published length moves E[grade × fill] by under 4% at every threshold and
leaves the peak where it is. It raises the hold rate by five points instead.

**A tighter clock kills crews on the way *in*** — where geometry and wards
already act. It does not make staying longer cost more. Whatever prices staying
has to be priced in **loot**, not in time. `response.md`'s Spire's reach is
exactly that, and this is a better argument for it than the one that file
originally made.

---

## F21: outcomes polarise with skill

§13.2 watches for one shape in particular:

> *"A game where raids either sweep or fail completely, with nothing in between,
> is a polarised one even if the mean looks right… We watch the spread of clean
> runs, partial hauls and foiled raids, and treat a **populated middle** as the
> goal."*

Fill on every successful raid, 300 raids a crew, same islands and seeds. The only
difference is how well the crew plays:

| fill | competent | optimal |
| --- | ---: | ---: |
| 0–19% | 30.0% | **58.0%** |
| 20–39% | 16.5% | 0.6% |
| 40–59% | 23.5% | 2.4% |
| 60–79% | 30.0% | 13.0% |
| 80–100% | 0.0% | **26.0%** |
| **middle (20–79%)** | **70.0%** | **16.0%** |

A competent crew has exactly the populated middle §13.2 asks for. **A crew that
reads the guards has 16%.**

The mechanism is the information, not the greed. Knowing a guard's suspicion
turns every raid into an early yes-or-no: commit and take everything, or abandon
at 35% and walk away. Once you can tell which run you are in, there is no reason
left to take a middling haul.

So §13.2's warning is tripped — and tripped **specifically for the players who
read the game best**: the ones most likely to be visible, to post replays, and to
set what everyone else copies.

---

## F19: what a raid pays varies 1.5× with how it is played

| | E[grade × fill] per attempt |
| --- | ---: |
| stops at §12.19's break-even | 0.127 |
| reads the guards, then decides | 0.187 |
| **§9.6 as published** | **0.46** |

**1.47×** between the two crews, and both are far below §9.6's figure — which is
E[grade] alone and takes no account of the `fill` term v3.0 added beside it
(F14).

Note which statistic this is. Measured as *fill on a successful run* the effect
reverses sign: the informed crew averages 35% against the simpler crew's 39%. It
wins by converting more attempts into clean, full ones and abandoning the rest
early — not by carrying more when it succeeds. **Conditioning on success hides
exactly the thing the skill is changing**, and an earlier version of this finding
was withdrawn on that statistic before being reinstated on the right one.

---

## The two findings that did not survive

Recorded because they are the reason to trust the rest.

**F18 — "raids either sweep or come home empty."** Measured before D25 as two
peaks with 27% in the middle, and written up as §13.2's polarisation warning
being tripped. With a clock-aware crew the middle holds **70%**. The metric
passes for an ordinary crew. What was real in it moved to F21, where it belongs.

**F19 v1 — "the faucet varies 2.2× with skill."** The informed crew was banking
89% of capacity by loading to 95% with no regard for whether it could get home.
Once crews watch the clock, it banks 33% — *below* the simpler crew. The finding
came back at 1.47× on a different statistic, but the original number was an
artefact.

Both were caught by asking the same question that found D24 and D25: *what would
the model have to be doing for this result to mean what it appears to mean?*

---

## What to change

### 1. Give staying a price that is not the clock

The load-bearing change, and F20 is the reason. In order of how little new
machinery they need:

| | Change | What it costs a crew |
| --- | --- | --- |
| **a** | **The Spire's reach with §9.6's floor** (`response.md`) — the Vault re-seals while it is being robbed, down to a share and no further | Loot, at a rate, from a moment the defender's level sets — **measured, and the only candidate that works** |
| **b** | **Deepen the grade penalty** — loud 0.7 → 0.5, partial 0.4 → 0.25 | Multiplies the whole haul, so it scales with what is at stake |
| ~~c~~ | ~~Tighten §5.4's clock~~ | **Measured and ruled out** — it kills crews on the way in |

(a) is the cleanest: it costs loot rather than time, so it does not depend on the
clock binding, and it is the one mechanism that also addresses F21 by setting the
fill from outside the crew's own rule.

**And it is the only one measured to work.** The same stopping-rule sweep, with
the Spire's reach re-sealing 8 units a second from 22 seconds after the first hit
on the Vault:

| stops at | 50% | 60% | 70% | 80% | 90% | 100% | peak |
| --- | ---: | ---: | ---: | ---: | ---: | ---: | ---: |
| published (no re-seal) | 0.096 | 0.106 | 0.122 | 0.120 | 0.160 | **0.164** | 100% |
| re-seal at 8/s | 0.076 | 0.100 | 0.099 | 0.114 | **0.117** | 0.117 | **90%** |

The peak moves down a step and the curve flattens above it, where cutting §5.4's
clock by 45% moved neither. It also costs the raider about 29% of the haul, which
is a large effect for a modest rate — so the rate is a dial to tune rather than a
switch to throw.

That the peak moves at all is the point: **a cost priced in loot changes where a
crew stops, and a cost priced in time does not.** If the rate scales with the
defender's Spire level, as `response.md` proposes, then a defender's spending
sets the raider's break-even — which is a far better thing for a defence layer to
do than making raids uniformly harder.

### The trade-off it creates, and the rule in §9.6 that removes it

Raising the rate buys a lower break-even and costs hold rate: 45.0% with no
re-seal, 48.5% at 8 a second, 53.0% at 15, against §13.2's 30–45% band. The
mechanism is blunt — a fast re-seal empties the Vault before a slow crew loads
anything, so the raid banks zero and counts as foiled.

**§9.6 already forbids that outcome**, in a clause written for a different
purpose: *"A clean raid on a fully sealed island still pays 0.7 — nobody ever
leaves with nothing."* Applied to the re-seal, the Vault stops sealing at a share
of what was there and never goes past it:

| | 50% | 60% | 70% | 80% | 90% | 100% | peak | hold |
| --- | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: |
| no re-seal | 0.096 | 0.106 | 0.122 | 0.120 | 0.160 | **0.164** | 100% | 45.0% |
| 12/s, no floor | 0.075 | 0.096 | 0.094 | 0.083 | 0.083 | 0.083 | 60% | **53.0%** |
| 12/s, floor 30% | 0.078 | 0.100 | 0.100 | **0.120** | 0.110 | 0.110 | **80%** | 46.0% |
| 20/s, floor 30% | 0.075 | 0.091 | 0.086 | **0.096** | 0.096 | 0.096 | **80%** | 48.0% |
| 20/s, floor 45% | 0.079 | 0.097 | 0.096 | **0.098** | 0.098 | 0.098 | **80%** | **44.5%** |

With a floor in place the **floor** sets where the break-even lands and the
**rate** only sharpens the approach to it. At 20 a second with a 45% floor the
break-even moves from 100% to 80% and the hold rate is **44.5%** — inside
§13.2's band, and within noise of the 45.0% baseline.

So the mechanism costs the defender nothing in the metric §13.2 cares about, and
buys the decision §12.6 asks for. 80% against §12.19's stated 70% is closer than
these sweeps can distinguish.

**Two things the document names and never specifies — §13.2's "the Spire's reach"
and §9.6's floor — combine to make §12.19's sentence nearly true.** That is a
better outcome than any of the three findings that led here: the numbers were not
wrong, the mechanism that would have justified them was missing.

### 2. Say that the rule varies, and re-derive the number

§12.19 specifies one threshold. The measurement says a crew reading the guards
beats every fixed threshold by 13%. That is the decision §12.6 wants, §12.17
already supplies the information for, and the document never joins up. Whatever
the price becomes, `breakeven` prints the curve and the break-even is where it
turns over — 70% is not where it turns over.

### 3. Decide whether §9.6 wants a skill term

Either accept that what a raid pays varies 1.5× with how it is played — in which
case §14.2 needs a band rather than a curve, because the gap compounds over
hundreds of raids — or narrow it, which is F21.

---

## What this forces elsewhere

| Section | Change |
| --- | --- |
| **§12.19** | The break-even sentence. The number is wrong and, more importantly, a single number is the wrong *shape* of answer |
| **§9.6** | `fill` has the widest spread of any term in the formula and the only one with no stated range. Either band the 0.46 or say which fill it assumes |
| **§12.17** | It already provides everything a varying stop rule needs. Say so — it is currently a perception spec with no stated payoff |
| **§13.2** | The polarisation warning is being tripped, by the population it can least afford to trip for. It is a target the harness reports every build, not a thing to watch for after launch |
| **§14.2** | The archetype curves assume one fill. Under F19 they are a band 1.5× wide |
| **§11.1** | The Carry spread — Carrier 300 against everyone else's 60–80 — makes fill very nearly binary |
| **§12.9** | There is no grade between "partial" and nothing, which is what makes abandoning at 35% free |

---

## Still open

- **90% is measured at about two sigma**, and it is a fixed-threshold answer to a
  question whose real answer is a varying rule. It is enough to say 70% is in the
  wrong place; it is not a number to lock. §13.4's own sample size — 1,600 raids
  a version — is what locking it would need.
- **The 15% clock margin is chosen, not derived**, and it is the one number in
  this file that changes every other one.
- **Whether the decision belongs at the Vault at all.** §12.6 and §12.19 clearly
  want one. A design where you take everything and the tension is purely getting
  out is coherent too. That is a call, not a finding.
- **"Optimal" is now the wrong name** for the policy that reads the guards. It
  earns 47% more per attempt and succeeds no more often, banks less when it
  succeeds, and polarises its outcomes. It is not optimal; it is *informed*.
