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
| [`corrections.md`](corrections.md) | C7–C18, C20 — the clerical sweep | 13 single edits, one session |

## How these were written

`movement.md` is the exception: the document leaves G1 empty, so that file is
partly new design rather than a reconciliation. It says so at the top.

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
