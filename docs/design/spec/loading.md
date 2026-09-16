# When to stop loading — proposed specification

**Status: proposed.** This resolves F18, F19 and F20, which are three readings of
one measurement: what a crew actually does in §12.19's Vault phase, and what the
document assumes it does.

All three became measurable only after **D24** — the harness had been ending the
Vault phase after two seconds instead of §12.19's ten, which pinned every crew
near 53% fill whatever it did. A constant where the truth is a distribution hides
every question this file asks.

Reports: `python3 -m tools.heist_harness breakeven` and
`python3 -m tools.heist_harness depth`.

---

## §12.19's claim, and how to check it

> *"What you carry is what you bank. The haul in 9.6 is multiplied by the share
> of the crew's bags actually filled, so loading longer earns more and the alarm
> clock is the price. Dropping loot to run faster costs exactly the fraction
> dropped.*
>
> *The break-even sits at about 70% full — at that point the extra load is worth
> exactly what a loud exit costs. **That single number is the dial for the game's
> emotional peak.**"*

This is the most falsifiable sentence in the document, because §9.6 says exactly
what a raid is worth: `B(V) × grade × difficulty × richness × fatigue × fill`. Of
those, a stopping rule moves two — **grade** and **fill** — so what a crew
maximises is `E[grade × fill]`, and a break-even is where that stops rising.

So: hold everything else about a competent crew fixed — it crouches, routes
around cones, flees when a guard reaches Alerted — and vary only the fill it
stops at.

---

## F20: the break-even is real, and it is not at 70%

Same islands, same seeds, 150 raids a row:

| stops at | E[grade × fill] | success | fill on success |
| ---: | ---: | ---: | ---: |
| 40% | 0.0837 | 56.7% | 24.6% |
| 50% | 0.0991 | 55.3% | 29.9% |
| 60% | 0.1090 | 50.7% | 36.0% |
| **70%** — §12.19's | **0.1227** | 53.3% | 40.5% |
| 80% | 0.1226 | 53.3% | 41.7% |
| 90% | 0.1607 | 54.7% | 50.5% |
| 95% | 0.1541 | 54.7% | 50.5% |
| **100%** | **0.1759** | 54.0% | 54.6% |

At this sample it rises all the way to 100%, which would mean there is no
break-even at all. **That reading does not survive a second measurement**, and
the second is the one to believe — a monotone claim over eight noisy thresholds
is exactly the shape small samples invent. At 400 raids a row:

| stops at | E[grade × fill] | success |
| ---: | ---: | ---: |
| **70%** — §12.19's | 0.1159 ± 0.0096 | 55.2% |
| **85%** | **0.1492 ± 0.0126** | 55.8% |
| 100% | 0.1531 ± 0.0137 | 53.5% |

So there *is* a break-even, and §12.19 is right that one exists. It sits at
**about 85%, not 70%**. Loading past 70% is worth **29% more per attempt** and
costs nothing in success rate; loading past 85% is worth nothing measurable and
starts costing success (55.8% → 53.5%).

The gap is not enormous, and it is not noise either: the rise from 70% to 85% is
about two standard errors on its own and is corroborated by every step of the
150-raid sweep below it. The flattening above 85% is what the smaller sample got
wrong.

### Why there is nothing to trade against

§12.19 names the price itself: *"the alarm clock is the price."* It is not one.

- **The clock does not bind.** A defended run ends at 63 seconds of §5.4's
  165-second clock. A crew can always afford more time, so time-priced costs are
  free.
- **The grade penalty is too small to matter.** Clean → loud is ×0.7. Going from
  70% fill to 100% is ×1.43. The load wins even if every extra second turned a
  clean run loud, and it does not: the grades barely move across the whole sweep
  (26 clean at 70%, 35 at 85%).

So the decision §12.19 builds the emotional peak on is real but badly placed: at
the number the document states, loading more is simply better, and a player only
begins trading anything at 85%. The peak exists about fifteen points above where
the design says it is, and the region the design calls the decision — 60% to 80%
— is a slope.

---

## F18: raids either sweep or come home empty

§13.2 is unusually explicit about the health signal to watch, and it is not the
mean:

> *"A game where raids either sweep or fail completely, with nothing in between,
> is a polarised one even if the mean looks right… We watch the spread of clean
> runs, partial hauls and foiled raids, and treat a **populated middle** as the
> goal."*

Fill on every successful run, 200 raids:

| fill | runs | |
| --- | ---: | --- |
| 0–24% | 46 | `###############` |
| 25–49% | 22 | `#######` |
| 50–69% | 13 | `####` |
| 70–89% | 47 | `###############` |
| 90–100% | 0 | |

**Two peaks, thin middle.** 36% of successful raids bank under a quarter; 37%
bank 70% or more; 27% land anywhere between. The mean, 40%, describes almost none
of them — which is exactly the failure mode §13.2 says to watch for, on §13.2's
own metric.

The mechanism is the stop rule itself. A crew that reaches the break-even stops
*there*, which places the upper peak at 70–89% by construction. A crew
interrupted before it leaves with whatever is in the bags, and that is very
little, because the Carrier — 300 of a crew's 560 — fills last. **There is no
mechanism that produces a middling haul**, so there are almost none.

Note what this means together with F20: moving the break-even to where it
actually is moves the upper peak with it, to 85–100%. **The middle gets
emptier, not fuller.** The two findings pull the same direction, and neither is
fixed by moving a threshold.

---

## F19: the faucet is skill-dependent and §9.6 prices it as a constant

The same formula, the same islands, two crews:

| | fill | value of an attempt | §9.6's "25 clean raids" |
| --- | ---: | ---: | ---: |
| stops at §12.19's break-even | 0.40 | 0.46 × 0.40 = **0.18** | **136 attempts** |
| reads the guards, then decides | 0.89 | 0.46 × 0.89 = **0.41** | **61 attempts** |
| §9.6 as published | — | 0.46 | 55 attempts |

The second crew is not braver. It uses what §12.17 already shows the player — a
guard's suspicion and the path of its cone — to push to 95% when nothing has
noticed and leave at 35% when something has. **That is the design working exactly
as intended, and it doubles the faucet.**

§9.6 calls 0.46 *"the number the progression curve is built on"*, and the term
beside it moves that number by 2.2× — more than the grade multiplier moves it
across all four of its steps. §14.2's archetype curves are computed with one
value of it.

---

## What to change

### 1. Make staying cost something that is not the clock

This is the load-bearing change, and F20 is the reason. Three candidates, in
order of how little new machinery they need:

| | Change | What it costs a crew |
| --- | --- | --- |
| **a** | **The Spire's reach** (`response.md`) — the Vault re-seals while it is being robbed | Loot, at a rate, starting at a moment the defender's level sets |
| **b** | **Deepen the grade penalty** — loud 0.7 → 0.5, partial 0.4 → 0.25 | Multiplies the whole haul, so it scales with what is at stake |
| **c** | **Tighten §5.4's clock** | Everything time-priced at once — see `response.md`, where the same dial is the common cause of three other findings |

(a) is the cleanest because it costs loot rather than time, so it does not depend
on the clock binding. It is also, on this reading, the *reason* the response layer
should exist — a much better argument than the one `response.md` originally made
for it.

### 2. Then re-derive the break-even rather than asserting it

Whatever the price becomes, 70% is a number to measure and not to state.
`python3 -m tools.heist_harness breakeven` prints the curve; the break-even is
where it turns over. If it does not turn over, there is no decision there yet.

### 3. Decide whether §9.6 wants a skill term

Either accept that what a raid pays varies 2.2× with how it is played — in which
case §14.2 needs a band rather than a curve — or narrow the spread, which is F18:
a populated middle is a narrower spread as well as a better game.

---

## What this forces elsewhere

| Section | Change |
| --- | --- |
| **§12.19** | The break-even sentence. As written it asserts a fact that is not true of the numbers around it. Either give staying a price and re-derive it, or drop the claim that stopping is a decision |
| **§9.6** | `fill` is the term with the most spread in the formula and the only one with no stated range. Either give the 0.46 a band or say which fill it assumes |
| **§13.2** | The polarisation warning is already there and is already being tripped. It is a target the harness can report on every build, not a thing to watch for after launch |
| **§14.2** | The archetype curves assume one fill. Under F19 they are a band 2.2× wide |
| **§5.4** | The clock, which is the common cause here and in `response.md` |
| **§11.1** | The Carry spread — Carrier 300 against everyone else's 60–80 — is what makes fill nearly binary. A flatter spread turns one big threshold into five small ones |

---

## Still open

- **85% is measured, not derived, and it is measured at about two sigma.** It is
  enough to say 70% is in the wrong place and not enough to lock 85% in its
  place. A number this load-bearing wants §13.4's own sample size — 1,600 raids
  a version — before anything is locked. What is already solid is the direction
  and the reason: nothing charges a crew for the seconds between 70% and 85%.
- **Whether the decision should be at the Vault at all.** §12.6 lists "when to
  stop loading" among the phase's decisions and §12.19 builds the emotional peak
  on it, so the document clearly wants one. But a design where you take
  everything and the tension is purely *getting out* is coherent too. That is a
  call, not a finding.
- **The Optimal policy is now slower than Competent and succeeds less often** at
  three and four realms, while banking twice as much. That is the correct shape
  — greed should cost something — but it means "optimal" is the wrong name for
  it, and the depth report's skill-separation figures now measure two different
  things depending on which column you read.
