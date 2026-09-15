# What an island may hold — reconciled specification

**Status: proposed.** This resolves C5. It needs sign-off before the island
builder or any defence balance work (§26.7).

---

## The root of it is a missing conversion, not a disagreement about numbers

§5.2 and §13.4 both say what a realm may hold, and they do not agree. The usual
reading is that someone wrote two tables. The actual problem is narrower and
easier to fix:

**§5.2 counts guard *posts*. §13.4 counts *guards*. How many ruleborn stand at
one Guardian Post is never stated anywhere in the document.**

| Realm level | §5.2 guard posts | §13.4 guards | Implied per post |
| --- | --- | --- | --- |
| 1 | 1 | 3 | 3.0 |
| 5 | 3 | 6 | 2.0 |

No constant converts one table into the other, and §10.2's Guardian Post entry
gives capability per level ("guard +10% health and sight") but never a capacity.
So the two tables cannot be reconciled until that number exists.

Notice what this also means for F1: the roster arithmetic assumed **one guard per
post**, giving 21 guard posts. If a post holds two or three, defence consumes
42–63 characters out of a roster of 38, and the shortage stops being severe and
becomes absolute.

---

## The second problem: the pool inverts

§13.4 is explicit about its own mechanism:

> The limits matter more than the pool: they are what makes it impossible to pour
> everything into one layer, which is how the "no layer above a quarter" rule is
> enforced rather than merely hoped for. — §13.4

Checking that against its own numbers — the cost of filling every slot at each
level, against the pool available:

| Realm level | Pool | Cost to fill every slot | Pool ÷ cost | Does the pool bind? |
| --- | --- | --- | --- | --- |
| 1 | 100 | 140 | **71%** | Yes — it is the real limit |
| 5 | 336 | 374 | 90% | Barely |
| 10 | 1,504 | 778 | **193%** | **No — it does nothing** |

The constraint inverts across the curve. Early, a defender can afford 71% of
their slots and the pool decides everything. Late, they can afford 193% of them
and only the slot limits matter. That is not wrong — §13.4 says the limits are
the mechanism — but it means the pool is live scaffolding for the first few
realm levels and dead weight thereafter, and the numbers should say which job it
is doing.

---

## The third problem: three ward limits, and a level that does not exist

| Source | Wards per realm |
| --- | --- |
| §5.2 and §10.2 (`3 + realm level`) | 4 at L1 → 8 at L5 |
| §13 introduction | "three to seven per realm" |
| §13.4 | 2 at L1 → 5 at L5 → 9 at L10 |

Three answers, no two the same. §5.2 and §10.2 at least agree with each other,
which makes them the majority reading.

And §13.4's table runs to **realm level 10**, while §5.2 caps outer realms at
level 5. That is C4 again — the same conflation that undermined the haul formula.
Roughly half of §13.4's table describes realms that cannot exist.

**What already agrees:** law slots. §5.2 gives 1 at realm level 1 and 3 at level
5; §13.4 gives 1 and 3. The one column both tables share is the one they got
right, which suggests the divergence is drift rather than disagreement.

---

## The resolution

**1. State the Guardian Post's capacity.** One ruleborn per post is the reading
that matches §9.2 ("Guarding — Guardian Posts — Scouts for sight, Wardens for
chokepoints") and keeps §5.2's numbers intact. It also keeps defence affordable
against the roster. If a post should hold more, F1's arithmetic has to be redone
first, because defence would then consume more characters than production.

**2. One table, in §5.2, counting posts.** §13.4's parallel table goes. §5.2
already carries grid size, law slots, terrain points, ward limit, guard posts and
producer counts per realm level — the budget belongs beside them, not in a second
place that drifts.

**3. Keep §13.4's mechanism, drop its currency.** The insight worth preserving is
that *slot limits*, not cost, are what stop one layer dominating — cost alone
lets a rich player buy their way past the quarter ceiling. Keep the limits. Drop
the second pool called "stability", which is not §5.5's stability and collides
with it by name.

If a per-realm budget is still wanted on top of the limits, name it something
else — **defence points**, parallel to the terrain points §6.1 already has — and
set it so it binds consistently across the curve rather than only at the start.

**4. Take §5.2 and §10.2's ward numbers.** `3 + realm level`, giving 4 to 8.
They already agree, §10.2 prices the Ward building against them, and §13's
"three to seven" is prose that should follow the table rather than lead it.

**5. Truncate at realm level 5** until C4 decides whether realms go to 10.

### The resulting table

| Realm level | Law slots | Ward limit | Guard posts | Terrain points | Producers of each |
| --- | --- | --- | --- | --- | --- |
| 1 | 1 | 4 | 1 | 45 | 1 |
| 2 | 1 | 5 | 2 | 60 | 1 |
| 3 | 2 | 6 | 2 | 75 | 2 |
| 4 | 2 | 7 | 3 | 90 | 2 |
| 5 | 3 | 8 | 3 | 105 | 2 |

This is §5.2's own table, unchanged. The reconciliation is mostly a matter of
deleting the second one — which is the same shape as C1 and C6, and the same
cause.

---

## What this does not settle

**Whether the five layers actually land on their target shares.** §13.2 wants
geometry 25%, guards 20%, wards 20%, laws 20%, response 15%, with no layer above
a quarter. §13.4 gives the right method for measuring it — switch a layer off,
re-run a thousand raids, divide the credit across all 32 combinations — but that
is a measurement, not a guarantee. The slot limits make one-layer dominance
*possible to prevent*; only the simulation shows whether these particular limits
do prevent it.

That measurement needs the simulation core, so it belongs after the determinism
spike, not here. What belongs here is making sure there is one set of limits to
measure.

**Ward levels 2–5.** §10.3 specifies level 1 only, while §10.2 gives the Ward
building five levels and §21.9 budgets 6 types × 5 levels of props. That is G3,
and it blocks any real defence balance.

**Response.** The fifth layer is 15% of the design target and is described only
as "bells, alarms, the Spire's reach, and the guardian Sage's single power". It
has no budget, no slots and no price — it is "earned rather than bought", which
is a fine principle and not a specification.
