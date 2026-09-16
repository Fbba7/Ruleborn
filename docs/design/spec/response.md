# The response layer — proposed specification, and a failed proposal

**Status: proposed, and it starts by reporting a proposal that did not work.**
This addresses F15: measured as §13.4 specifies, Guards and Response contribute
*identically* — 34.2% each, 68% together, against §13.2's own ceiling of 25% for
any one layer.

Every number here was re-measured after D24, a harness bug that had been ending
the Vault phase after two seconds instead of §12.19's ten. The finding survived
the correction almost unchanged, which is worth more than the original
measurement was.

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
| geometry | 25% | 5.4% | 5.7% |
| guards | 20% | **34.2%** | **34.4%** |
| wards | 20% | 21.1% | 19.6% |
| laws | 20% | 5.2% | 5.9% |
| response | 15% | **34.2%** | **34.4%** |
| | hold rate | 43.3% | 46.7% |

Guards and Response are equal to the decimal in both columns. That is a theorem,
not a coincidence: in **every one of the eight coalitions**, guards without
response turn back 0% of raids and response without guards turns back 0%. Two
players who are interchangeable in every coalition are symmetric, and the Shapley
value must give symmetric players identical shares.

The proposed effects moved the hold rate from 43.3% to 46.7% — **out of §13.2's
own 30–45% band** — and moved the symmetry not at all.

---

## Why the fix failed, measured rather than argued

Two reasons, and neither is about the effects being too weak.

### A crew already leaves a third of the loot behind

A competent crew stops at §12.19's 70% break-even and walks out, leaving **30%
of the exposed share on a bare island and 37% on a defended one**. The Spire's
reach re-seals out of that remainder first, and the crew never notices.

**Taking loot off the floor costs a crew nothing until it has taken everything
it meant to take.** Tuning the rate up until it does bite is what produced the
46.7% hold: the re-seal goes from costing nothing to costing everything with
almost no range in between, because the two quantities it sits between — what
the crew wants and what is there — are close together.

F20 is the sharper version of this, and it arrived from the other direction:
there is no stopping rule a crew should prefer to "take everything", so the
remainder the re-seal eats is an artefact of a break-even that should not be
there.

### The clock has nearly three times more slack than any delay needs

A defended run ends at about 63 seconds of §5.4's 165-second clock, and a bare
one at 41. The Sage's Weight — loaded crew at 70% speed for 20 seconds — costs a
crew a few seconds of a clock with a minute and a half spare. It is invisible for
the same reason every other delay is.

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
halves of the pair, and §13.4's metric can see nothing else. The 68% is not two
layers being too strong. It is three layers having no path to the metric at all.

### And it is the same cause as three other findings

Once stated this way the clock stops being a detail of this file:

| finding | what it says | through the clock |
| --- | --- | --- |
| **F15** here | guards and response are 68% of the defence | the other three layers only delay, and delay is free |
| **F16** | geometry is 5% of a generated defence, 0.2% of the haul denied | geometry *is* delay |
| **F18** | raids either sweep or come home empty | nothing charges for the seconds between |
| **F20** | §12.19's break-even does not exist | it is priced against "the alarm clock", which does not bind |

§12.19 states the mechanism itself, in one clause: *"loading longer earns more
and **the alarm clock is the price**."* It is not a price. A defended run ends
at 63 seconds of a 165-second clock, so the crew can always afford more time,
and everything the design charges in time is therefore free.

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
| geometry | 5.4% | **0.2%** |
| guards | **34.2%** | **40.1%** |
| wards | 21.1% | 21.0% |
| laws | 5.2% | 3.1% |
| response | **34.2%** | **35.7%** |
| | 43.3% of raids held | 81.6% of the haul denied |

**The identity breaks** — 40.1% against 35.7%. A guard slows a crew and takes
part of its haul with nobody to tell: guards alone deny 2.2% where every other
layer alone denies zero. The hold rate cannot see that; the haul metric can. So
the *exact* equality was an artefact of §13.4's metric, not a property of the
design.

**The 68% does not break.** Together they are 76% of the haul denied, and
geometry and laws get much *worse* — **0.2%** and 3.1% — because on this metric
guards and response destroy 82% of the haul and there is even less left to
divide. Geometry, the layer §13.2 gives the largest share and calls "the layer a
thoughtful designer beats a richer player with", costs a raider two parts in a
thousand of their haul.

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
2. **§5.4: the clock is the reason three layers are decoration — but tightening
   it is not the fix.** The obvious move is to shorten the clock until delay
   converts to outcomes, which is also what §19.27's "a quarter of runs decided
   in the last ten seconds" asks for and does not get. Measured, it does not
   work: cutting §5.4's clock to 55% of its length raises the hold rate by five
   points and moves the stopping decision not at all. A tighter clock kills
   crews **on the way in**, where geometry and wards already act; it does not
   make staying longer cost more.

   So the honest recommendation is the other branch: accept that geometry, wards
   and laws shape the haul rather than the outcome, rewrite §13.2's shares to say
   which layers do which, and give the response layer a cost priced in **loot**
   rather than in time — which is what the Spire's reach already is. `loading.md`
   reaches the same place from the Vault's end.
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
