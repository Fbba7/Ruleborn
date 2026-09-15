# Ruleborn — design analysis, executive summary

Analysis of `docs/design/ruleborn-game-design-v2.3.html` (30 sections, ~85,600 words,
330 headings, 123 graded references, 12 commissioned evidence reviews).

## The verdict in one paragraph

This is an unusually strong design document — better specified than most shipped
games' internal wikis, and almost uniquely honest about its own weak points. It
already contains its own risk register, its own kill criteria, and a list of the
assumptions its evidence contradicts. The work that remains is not "design more";
it is **reconciliation and reduction**. Four systems were specified twice, at
different times, and the later spec never replaced the earlier one — so the
document contains two incompatible detection models, two raid-payout models, two
law-rarity taxonomies and two character rosters. None of that is visible when you
read the document front to back, which is exactly why it has survived to v2.3.
Those contradictions are now enumerated in `03-contradiction-register.md`, and
they block content authoring, not just polish.

## What the document gets right

**The core fantasy is genuinely novel and genuinely coherent.** "Collect the laws
of physics, build islands that run on them, rob islands that run on someone
else's" is one idea, not four, and every system traces back to it. The
laws-as-parameters model (7.3) — where laws change a realm's rule sheet rather
than containing special cases — is the right architecture, and it is what makes
39 terrain features × 48 laws produce real combinatorial depth instead of a
content treadmill.

**The technical architecture is the best-reasoned part of the document.** A
deterministic, fixed-point simulation written once and compiled twice (24.7)
buys, from a single decision: server-authoritative anti-cheat, free replays, free
analytics (24.3), rehearsals, balance bots, co-op, and an infrastructure bill of
roughly $5–15/month at a million monthly players (24.1). Very few designs get
that much leverage out of one constraint. The document correctly identifies this
as load-bearing and correctly orders the determinism spike before everything else
(24.2, 26.7).

**The economic and progression arithmetic is largely sound.** Spot-checks of the
stability formula, the Vault curve, the production curve, the Keeper XP curve and
two of three business scenarios all reconcile to within rounding
(`tools/check_design_consistency.py`). The simulated day-by-day tables in 10.2
and 14 are internally consistent with the formulas that generated them.

**The wellbeing and monetisation posture is a competitive asset, not a tax.**
Cosmetic-only, no paid randomness, no login rewards, no engagement-tuned
matchmaking, no obligation — with the refusals written down in 19.12 precisely so
they cannot creep back. This narrows the revenue ceiling and the document says so
plainly (22.2, 30.8 risk 9). It is a coherent trade, honestly stated.

## What has to change before a line of gameplay code

Ordered by how much they block. **All six now have a drafted resolution or a
priced set of options** in `docs/design/spec/` — what remains is sign-off, and in
three cases a decision only the owner can make.

1. **Pick one detection model.** 12.17 (three vision zones, 0–1000 suspicion, six
   states, path-following noise) is a complete, buildable spec. 12.8 (120° cone,
   6 tiles, awareness in %/second) is the older one, and it is still what 5.4,
   13.x and the formulas appendix in 29.1 reference. Everything downstream —
   balance, the guard AI, the vision-cone rendering in 21.12 — is blocked on this.
   → Drafted: `spec/detection.md`.

2. **Pick one raid-payout model, then re-derive the loop's purpose.** Rebuilding
   the economy model measured the gap exactly: §9.4's model delivers **32%** of a
   player's income — reproducing its own stated "roughly a third" — while §9.6's
   minted haul delivers **1–2%**. A 16- to 30-fold reduction, with nothing else in
   the document updated to match. §9.6 is the better-argued model, but adopting it
   means raiding is a *page* faucet, not a resource faucet, and §9.4 and §12.1 need
   rewriting to say so. → Drafted: `spec/economy.md`, which finds that **no growth
   rate fixes it** and proposes pegging the haul to the raider's own production.

3. **Pick one law-rarity taxonomy.** 7.10 and 27.2 describe five ranks
   (18/14/10/6 + 3 paradoxes, 10/20/35/60/120 pages). The 48 laws actually
   authored in 7.4 and 7.7 use three (18 Common / 18 Rare / 12 Deep, 15/30/60
   pages), and **no law in the document is tagged Uncommon**. 9.5, 14.4 and the
   glossary all use the three-rank version. The five-rank system exists only as
   prose. → Priced: `tools/decision_support.py rarity`. This one is a judgement.

4. **Pick one ruleborn roster.** 11.2 and 11.11 specify the same 18 creatures
   with different roles for three of them (Prism Mite, Stormhound, Rootrunner).
   Worse than first recorded: **eleven of the eighteen have an entirely different
   passive property**, not a different wording of one. → Drafted: `spec/ruleborn.md`.

5. **Reconcile the defence budget.** 13.4 introduces a per-realm "stability pool"
   with laws priced at 30–40 and 2–9 wards per realm. 5.2 and 5.5 give realms
   1–3 law slots drawn from a *universe-wide* stability pool, laws costing 10–26,
   and a ward limit of 4–8. The root turns out to be one missing number: §5.2
   counts guard *posts*, §13.4 counts *guards*, and **how many ruleborn stand at a
   post is never stated**. → Drafted: `spec/defence.md`.

6. **Resize the roster against the buildings.** Rebuilding the economy model
   surfaced a structural problem that is not in the register as a contradiction
   between two texts, but between three tables: a finished universe has **152
   character positions** to fill (126 producer worker slots, 21 guard posts, a
   crew of 5) against a **roster ceiling of 38**. Even at one producer per realm,
   production alone needs 63 workers before a single guard is posted. §9.3's
   published production figures are therefore unstaffable as written.
   → Priced: `tools/decision_support.py staffing`. This one is a design choice.

## The two risks that decide whether this game exists

The document already names both, and ranks them correctly.

**Will players build islands?** (13.1, 13.3, 30.7 premise 7.) The whole design —
the Workshop, the target pool, the human presence that makes a heist matter —
rests on players designing defences, and every comparable game says they will
not. The document's response is the strongest part of its planning: a
forced-then-free test with a stated pivot at <15%, and a pivot that keeps every
other system intact. **This test costs nothing and should run first.**

**Does a no-loss heist generate tension?** (19.27 gate 1.) One-way theft is a
well-reasoned change (27.5) that removes the sharpest edge of the fantasy, and
the document knows it. The paper-prototype gate is the right test and also costs
nothing.

Both are answerable in a fortnight. The document's method — a paper prototype and
about thirty people in a room — assumes a cohort this project does not have, so
the method changed while the questions did not: a throwaway browser prototype is
built and published, because a link is recruitable and a room is not. See
`07-recommended-next-steps.md` stage 0.

## Where I disagree with the document

- **Scope is still too large for the plan.** 26.8 estimates ~270 agent runs at
  2–4 focused hours each (≈540–1,080 hours) and then says the iteration needed to
  *find the fun* is unbudgeted. For a one-person team, launch content of 48 laws +
  44 resonances + 12 chords + 18 ruleborn × 8 forms + 39 terrain features + 16
  buildings + 27 screens + 12 languages is a multi-year scope, not a 48-week one.
  The document's own best advice (26.5: "scope is the lever") is not yet applied
  to its own content table. See `06-build-readiness.md`.

- **Chords are not the late-game discovery the design thinks they are.** 8.5 says
  a chord "needs three laws in play". Because 23 of the 48 laws carry two notes,
  **all 12 chords are reachable with two laws**, several of them with two commons
  costing ~25 stability. A realm at level 3 with two crown laws will trip chords
  constantly. Either the gating premise or the two-note distribution has to change.

- **The note economy has a 2:1 imbalance on the axis that matters most.** Glow is
  carried by 12 laws, its opposite Hush by 6. Hush is the *hiding* note — the one
  that helps raiders — and it is the scarcest, while the revealing note is the
  most abundant. Five of the twelve chords require Hush. Since laws are woven by
  the defender and apply symmetrically, defenders have both the least reason and
  the fewest options to weave Hush.

- **Two systems are specified in numbers that were never multiplied together.**
  §12.8 states that "two ambush hits knock out a guard of equal level"; under its
  own Power, Health and 0.8-second wind-up that is true for **three of
  twenty-five** role pairings, and a Mender attacking a Warden needs 68 hits.
  §12.6 budgets the Vault phase at 30 seconds and calls "when to stop loading"
  its core decision; at the stated 150 loot a second, loading takes **two
  seconds**, and because only Carriers load, 260 of a crew's 560 units of
  capacity cannot be filled at all. Both are drafted in `docs/design/spec/`
  (`fights.md`, `vault.md`). The same exercise turned up the one place the
  document's numbers *corroborate* each other: Vault health, role Power and the
  Vault phase's stated length were written in three different sections and agree
  to within a few seconds under a single reading of the wind-up.

- **The core trade-off the design is built on does not bind.** §4 and §11.6 say
  the game turns on characters' time — "raiding more means earning less at home
  and defending worse". In the document's own numbers a crew of five raiding four
  times a day is withheld from work for 16 character-hours out of 744: **about 2%
  of production**. Combined with §9.6's 1–2% return, the raid-versus-build tension
  is absent from the arithmetic entirely. The scarcity the design needs already
  exists (see point 6 above) — it is just not connected to raiding.

- **The document is a specification and a research archive at the same time, and
  the archive is winning.** Sections 19, 28 and 30 are ~40% of the text and
  contain the reasoning behind decisions recorded elsewhere. That is valuable and
  should be kept — but it should be a separate document, so the spec can be read,
  diffed and implemented without it. See `07-recommended-next-steps.md`.

## Where to go next

`07-recommended-next-steps.md` proposes the concrete first moves. In short: run
the two zero-cost gates now, split the document into a spec and a research
archive, resolve the five reconciliations above, and do not write gameplay code
until the determinism spike has passed.

## Contents

| Document | What it covers |
| --- | --- |
| `02-system-map.md` | Every system, what it depends on, and where the load-bearing couplings are |
| `03-contradiction-register.md` | Every confirmed internal contradiction, with section references and a recommended resolution for each |
| `04-specification-gaps.md` | What is referenced but never specified, and what a builder would have to invent |
| `05-quantitative-findings.md` | The arithmetic that checks out, the arithmetic that does not, and the note/chord analysis |
| `06-build-readiness.md` | What is buildable today, the critical path, and an independent read on scope |
| `07-recommended-next-steps.md` | Ordered actions, with the zero-cost tests first |
