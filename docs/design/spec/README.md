# Specification

The reconciled, buildable half of the design document — one file per system,
carrying decisions. The reasoning behind those decisions stays in the document's
own §19, §28 and §30, which are the research archive (D10).

Every file here is **proposed** until signed off. Nothing is locked (§26.7).

**v3.0 adopted four of them.** `movement.md` became §12.18, `fights.md` became
§12.20 with §12.8 rewritten around it, `vault.md` became §12.19 with §9.6 gaining
its `fill` term, and `detection.md`'s reading became §12.8's own words. The three
still unadopted are `wards.md` (§10.3 is untouched), `economy.md`'s production peg
(§9.6 kept `B(V)`), and `first-build.md` (§13.3 removed the feature instead).

| File | Resolves | Status |
| --- | --- | --- |
| [`detection.md`](detection.md) | C1 — two detection models | Proposed: §12.17 authoritative |
| [`ruleborn.md`](ruleborn.md) | C6 — two rosters | Proposed: §11.11 authoritative |
| [`economy.md`](economy.md) | C2, C4 — what a raid pays | Proposed: peg the haul to the raider's own production |
| [`defence.md`](defence.md) | C5 — what an island may hold | Proposed: one table in §5.2, counting posts |
| [`movement.md`](movement.md) | G1 — crew movement and control | Proposed, and partly new design |
| [`first-build.md`](first-build.md) | G9 — the 60-second guided build | Proposed, and partly new design |
| [`fights.md`](fights.md) | G2 — what happens when a guard catches you | Proposed, and largely new design |
| [`vault.md`](vault.md) | G4 — cracking, loading, and what a full bag is worth | Proposed |
| [`wards.md`](wards.md) | G3, G5 — wards, their levels, and law pylons | Proposed |
| [`corrections.md`](corrections.md) | C7–C18, C20 — the clerical sweep | 13 single edits, one session |
| [`response.md`](response.md) | F15 — guards and response measure as one layer | Proposed, and it reports a proposal that failed |
| [`sinks.md`](sinks.md) | F17 — Aether and Essence have no sinks | Proposed: peg upkeep, then cut the faucets |
| [`loading.md`](loading.md) | F19, F20, F21 — when to stop loading | Proposed: the break-even is near 90%, and the answer is a rule rather than a number |

## How these were written

`movement.md`, `first-build.md`, `fights.md` and `vault.md` are the exceptions:
the document leaves G1, G2, G4 and G9 empty, so those files are partly new design
rather than reconciliations. Each says so at the top.

`response.md` is the one to read if you only read one. It specifies the two
things §13.2 names and never defines — the Spire's reach and the guardian Sage's
single power — and then reports that building them **did not fix F15**, with the
measurements that say why. The cause turned out to be two things neither the
finding nor its recommendation had reached: guards-and-response is the island's
only detect-and-act chain, and §13.4 measures the one quantity three of the five
layers cannot reach.

`sinks.md` does the same to F17. The finding said the prices were too small; the
spec says they are on the wrong kind of curve, withdraws the edit F17 first
proposed, and shows what that edit would have cost.

`loading.md` is the third, and it is the one that came closest to going out
wrong — twice. Two of the findings it started from were withdrawn after the
harness was corrected, and it reports both rather than quietly dropping them,
because the route from the wrong answer to the right one is what makes the
remaining numbers worth anything. It is the file to read on how these
measurements are checked, not just on what they say.

`wards.md` is the third of these, and the first: it begins by **correcting this
analysis**. Two things `04-specification-gaps.md`
recorded as missing — ward levels 2–5 and the pylon-to-law-slot relationship —
are in §10.2's building tables, which had not been read against §10.3. The gap
that survives is smaller and sharper than the one that was recorded.

`fights.md` and `vault.md` are a pair. Neither can be settled alone — what a
Vault costs to crack is a combat question, and what a fight costs is priced by
the grade multiplier a fight forfeits. Together they are also the one place where
the document's numbers *corroborate* each other: Vault health, role Power and the
Vault phase's stated length were written in three different sections and agree to
within a few seconds under a single reading of §12.8's wind-up.

The others each take a contradiction the register records, works out which reading is
authoritative, states that reading **once**, and then lists every other section
the choice forces a change to. That last part is the point: the document reached
v2.3 with four systems specified twice because the newer spec was added without
retiring the older one, and listing the collateral is what stops that recurring.

Where a decision is genuinely the owner's rather than clerical, these files price
the options instead of picking — `tools/decision_support.py` produces the numbers.

## What is not here yet

The blocking items still without a spec file:

- **C3** — three law ranks or five. `decision_support.py rarity` prices both;
  the split itself is a judgement about complexity and excitement, not arithmetic.
- **C19, F1, F2** — the roster, the building counts and the production tables
  cannot be reconciled without deciding whether character scarcity is a feature.
