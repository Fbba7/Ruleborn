# Specification

The reconciled, buildable half of the design document — one file per system,
carrying decisions. The reasoning behind those decisions stays in the document's
own §19, §28 and §30, which are the research archive (D10).

Every file here is **proposed** until signed off. Nothing is locked (§26.7).

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
| [`corrections.md`](corrections.md) | C7–C18, C20 — the clerical sweep | 13 single edits, one session |

## How these were written

`movement.md`, `first-build.md`, `fights.md` and `vault.md` are the exceptions:
the document leaves G1, G2, G4 and G9 empty, so those files are partly new design
rather than reconciliations. Each says so at the top.

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
