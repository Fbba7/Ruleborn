# The response layer — proposed specification, and a failed proposal

**Status: proposed, and it starts by reporting a proposal that did not work.**
This addresses F15: measured as §13.4 specifies, Guards and Response contribute
*identically* — 34.5% each, 69% together, against §13.2's own ceiling of 25% for
any one layer.

F15's recommendation was to give Response an effect that works without a guard,
using the two things §13.2 names and never defines: **the Spire's reach** and
**the guardian Sage's single power**. Both are specified below. Both were built
into the harness and measured. **They do not fix it**, and finding out why is
what this file is actually for.

Reports: `python3 -m tools.heist_harness ablation 120` and
`python3 -m tools.heist_harness haul 120`.

---

## What was measured

§13.4 specifies the test precisely — all 32 combinations of the five layers,
credit divided "the way cooperative game theory does", which is the Shapley
value. At 120 raids a combination, 3,840 runs a column:

| layer | §13.2's target | as published | with the two effects below |
| --- | ---: | ---: | ---: |
| geometry | 25% | 4.4% | 6.4% |
| guards | 20% | **34.5%** | **34.2%** |
| wards | 20% | 20.9% | 19.6% |
| laws | 20% | 5.7% | 5.7% |
| response | 15% | **34.5%** | **34.2%** |
| | hold rate | 41.7% | 47.5% |

Guards and Response are equal to the decimal in both columns. That is a theorem,
not a coincidence: in **every one of the eight coalitions**, guards without
response turn back 0% of raids and response without guards turns back 0%. Two
players who are interchangeable in every coalition are symmetric, and the Shapley
value must give symmetric players identical shares.

The proposed effects moved the hold rate from 41.7% to 47.5% — **out of §13.2's
own 30–45% band** — and moved the symmetry not at all.

---

## Why the fix failed, measured rather than argued

Two reasons, and neither is about the effects being too weak.

### A crew already leaves half the loot behind

On a bare island a competent crew banks **53% of its capacity** and walks out.
The exposed share is 560; they take about 297 and leave 263 on the floor. The
Spire's reach re-sealed 102 units on a typical run — all of it out of the 263
they were never going to carry.

**Taking loot off the floor costs a crew nothing until it has taken 47% of it
first.** Tuning the rate up until it does bite is what produced the 47.5% hold:
the re-seal goes from costing nothing to costing everything with almost no
range in between, because the two quantities it sits between — what the crew
wants and what is there — are nearly equal.

### The clock has four times more slack than any delay needs

A run ends at about 40 seconds of §5.4's 165-second clock. The Sage's Weight —
loaded crew at 70% speed for 20 seconds — costs a crew about four seconds of a
clock with two minutes spare. It is invisible for the same reason every other
delay is.

This is not new. `test_the_clock_is_not_a_pressure_device` has pinned it since
the first harness: runs finish well inside the clock, and §19.27's target of a
quarter of runs decided in the last ten seconds is not met.

---

## The actual cause, which is more interesting than the symptom

**Guards + Response is the island's only detect-and-act chain.**

Every other layer works by *delay*. Geometry lengthens the route; wards freeze
and pull; laws slow the loaded. None of them ends a raid. Delay converts into an
outcome only through the clock — and the clock, per above, has four times the
slack a delay-based layer would need to matter.

So the island has exactly **one** way to turn back a raid, it requires both
halves of the pair, and §13.4's metric can see nothing else. The 69% is not two
layers being too strong. It is three layers having no path to the metric at all.

---

## What does move it: measuring what §9.6 actually pays

§13.4 measures the shares by **hold rate**. §12.9 grades a raid clean, loud,
partial or foiled, and §9.6 multiplies the haul by 1.0, 0.7, 0.4 and 0. A defence
that turns every clean run on an island into a partial one takes **60% of the
raider's income** and scores **zero** on the hold rate, because it turned back no
raids.

Re-run against grade × fill — the two terms of §9.6's haul formula a defence can
move — over the same 32 coalitions and 120 raids each:

| layer | by hold rate (§13.4) | by haul denied (§9.6) |
| --- | ---: | ---: |
| geometry | 4.4% | 1.6% |
| guards | **34.5%** | **38.7%** |
| wards | 20.9% | 20.8% |
| laws | 5.7% | 3.5% |
| response | **34.5%** | **35.4%** |
| | 41.7% of raids held | 82.0% of the haul denied |

**The identity breaks** — 38.7% against 35.4%. A guard slows a crew even with
nobody to tell, and the hold rate cannot see that; the haul metric can. So the
*exact* equality was an artefact of §13.4's metric, not a property of the design.

How firmly: the gap rests on guards alone denying 1.6% of the haul, which is
about two runs in 120. It is enough to show the two layers are not
mathematically interchangeable. It is not enough to claim they are meaningfully
different, and this file does not.

**The 69% does not break.** Together they are 74% of the haul denied, and
geometry and laws get *worse* — 1.6% and 3.5% — because on this metric guards and
response are destroying 82% of the haul and there is even less left to divide.

So the metric is a real fault and fixing it is worth doing, but it is not this
fault's fix.

---

## The two effects, specified

They are worth specifying regardless: §13.2 names both and defines neither, and a
layer with two named components that have no rules is not a layer. What changes
is the claim made for them — they shape the haul and they give the defender a
choice, and they do **not** make Response independent of Guards.

### The Spire's reach

| | Rule |
| --- | --- |
| What it is | The Vault answers to the Spire. §9.6 already distinguishes exposed wealth from sealed and prices a fully sealed island at 0.7, so the quantity exists |
| Trigger | The first hit on the Vault. Cracking is loud (§12.17); the Spire is what hears it |
| Grace | 25 seconds, minus the realm level — 22 s at realm 3, 20 s at realm 5 |
| Then | The exposed share falls at 8 a second, whether or not the Vault is open yet |
| Scaling | By Spire level, which is earned rather than bought — §13.4's own rule for this layer |
| What it costs a crew | Nothing until they have taken 47% of the exposed share. See above; this is the dial that has no middle |

### The guardian Sage's single power

Spent once, the moment the Vault opens. The defender chooses which when they
design the island, which is what makes this the layer's one *design* decision
rather than a level tax.

| Power | Effect |
| --- | --- |
| **Weight** | Loaded crew move at 70% for 20 seconds |
| **Bar** | The link the crew entered by is sealed for 15 seconds |
| **Dark** | The crew cannot see guard cones for 20 seconds |

Only Weight is modelled; Bar and Dark are specified for the document's sake and
would need the harness extended. All three are deliberately small: a
once-per-heist effect that decides a raid would be the same fault as the one this
file is about, one layer deciding outcomes.

---

## Recommended, in order

1. **§13.4: measure against what §9.6 pays, not against the hold rate.** One
   sentence, and it is the difference between a measurement that can see four of
   the five layers and one that cannot. It is also strictly more information: the
   hold rate is the special case where grade × fill is zero.
2. **§5.4: the clock is the reason three layers are decoration.** Four times the
   slack means no amount of delay reaches the metric. Either tighten the clock
   until delay converts to outcomes — which is also what §19.27's "a quarter of
   runs decided in the last ten seconds" asks for, and it is currently not met —
   or accept that geometry, wards and laws shape the haul rather than the
   outcome, and rewrite §13.2's shares to say which layers do which.
3. **§13.2: specify the Spire's reach and the Sage's power** as above, and stop
   claiming Response is independent of Guards. Measured, it is not, and
   **that is fine if the shares are written to admit it** — "detection and
   response, 35%" is a layer. "Guards 20%, Response 15%" is the same layer
   counted twice, and it is what breaks the 25% ceiling on paper as well as in
   the harness.
4. **Do not adopt the Spire's reach at the numbers above without re-checking the
   band.** They push the hold rate to 47.5%, outside §13.2's 30–45%.

---

## What this forces elsewhere

| Section | Change |
| --- | --- |
| **§13.2** | Five shares become four layers and a modifier, or Guards and Response merge. Either way the table changes; as written it cannot be satisfied |
| **§13.4** | The metric. Also: "400 simulated raids each — about 12,800 runs" is right, and 120 is enough to see a 3-point difference, which is what this file used |
| **§5.4** | The clock, per above. This is the same finding as the harness's existing one, reached from a different direction |
| **§12.19** | The exposed share equals a full crew's capacity, which is why a crew leaves 47% behind and why the re-seal has no middle range. Whether that equality is intended is a `vault.md` question |
| **§9.6** | Nothing changes, but the grade multiplier becomes load-bearing for the defence budget as well as for the economy |

---

## Still open

- **Whether Guards and Response should be one layer.** The measurement says they
  behave as one. The argument for keeping them apart is that a defender spends on
  them separately — guards are characters withheld from production, response is
  earned. That is a real distinction and it is about *cost*, not about
  contribution. §13.2's table is about contribution.
- **25 seconds and 8 a second are fitted**, and fitted badly: the range between
  "costs nothing" and "costs everything" is about four units a second wide. If
  the Spire's reach is adopted at all it wants a mechanic with a middle, which
  probably means re-sealing what is *in the bags* rather than what is on the
  floor.
- **Bar and Dark are unmodelled.** Bar in particular interacts with §6.1's route
  rule — sealing the entry link for 15 seconds is close to sealing a route, which
  §6.1 forbids the designer from doing permanently.
- **The haul metric has its own blind spot**: it cannot see a defence that costs
  the raider *time* without costing them loot, and §12.1's session length is a
  design target too.
