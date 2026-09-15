# The eighteen ruleborn — reconciled specification

**Status: proposed.** This resolves contradiction C6 by making §11.11 authoritative
and retiring §11.2 as a spec. It needs sign-off before content is authored (§26.7).

Data: [`content/ruleborn.json`](../../../content/ruleborn.json) — which deliberately
still carries **both** readings, marked, until this is signed off.

---

## The problem is larger than the register said

C6 was recorded as "three role conflicts, fifteen ability wordings". Extracting
both versions and comparing them field by field shows that is too generous.

**Eleven of the eighteen creatures have entirely different passive properties in
the two sections** — not different wordings of one property, different properties:

| Ruleborn | §11.11 resists | §11.2 passive |
| --- | --- | --- |
| Featherkin | Ignores Half gravity's overshoot | **Flies**; grounded by Heavy ground |
| Skyskipper | Unbothered by Leapfrog's noise | Leaps one extra obstacle under Half gravity |
| Glass Golem | Takes half damage from Spark laws | **Sees through walls** |
| Prism Mite | Sees through Glass and Mirror images | Tiny and quick |
| Emberling | Immune to Heat bloom and ember vents | **Glows**: seen in the dark, and lights its surroundings |
| Sparkwright | Unaffected by Overcharge's surges | Heals more near fire |
| Bloomling | Immune to Spores | Hedges part for it |
| Rootrunner | Ignores Heavy ground | Ignores Spores |
| Echoplate | Returns automatically under Echoes | Comes back once at 50% after being knocked out |
| Lantern Wisp | Cannot be hidden by Glowing dark | Carries its own light under Soul lanterns |
| Soulmender | Unaffected by Haunting's trails | Unaffected by Soul swap's cost to its partner |

A creature that flies and a creature that ignores a gravity overshoot are not the
same creature described twice. **These are two rosters sharing eighteen names.**

Plus the three role conflicts, which change the role spread:

| Ruleborn | §11.11 | §11.2 |
| --- | --- | --- |
| Prism Mite | Scout | Carrier |
| Stormhound | Carrier | Scout |
| Rootrunner | Scout | Carrier |

§11.11 gives 4 Scout / 3 Carrier / 3 Breaker / 4 Warden / 4 Mender.
§11.2 gives 3 / 4 / 3 / 4 / 4. Role drives crew composition, guard behaviour
(§12.8) and the Nursery's fewest-roles-first rule (§11.5), so this is not
cosmetic.

---

## The resolution

**Adopt §11.11 in full.** It is the later spec, it is the richer one — look,
proportions, personality, an idle habit, ability, resistance, best work and a
sound for each — and, unlike §11.2, it follows a stated design rule:

> Each has one habit you can watch at home. Each **resists exactly one law
> family**, so crew choice against a scouted island is a real decision. No
> ruleborn is strictly better than another. Each has a sound so a player can tell
> who acted without looking. — §11.11

§11.2's passives do not follow that rule: "Flies", "Sees through walls", "Tiny and
quick" and "Glows" are properties, not resistances. Keeping them would mean
abandoning the rule, and the rule is what makes scouting worth paying for.

**Then §11.2 becomes a generated index** — name, school, role, one-line ability —
emitted from the same data table, never hand-maintained. That is what stopped this
from being caught: two hand-maintained tables of the same eighteen things.

---

## What adopting §11.11 breaks, and must be fixed with it

Three §11.2 passives are load-bearing elsewhere. Dropping them without
replacement leaves law text pointing at nothing.

### Heavy ground's first clause stops meaning anything

> **Heavy ground** (Motion, rare, 16): *Flyers are grounded; carried loot weighs
> double, slowing carriers by 30%.* — §7.4

**Flying exists only in §11.2's Featherkin passive.** Under §11.11 no creature
flies, so half of a rare law's tier-1 effect is inert, and its listed weakness —
"Featherkin and Half gravity shrug it off" — is false.

Pick one:
- give Featherkin flight back as its §11.11 resistance (it breaks the
  one-law-family rule, but Heavy ground *is* the law family it interacts with); or
- rewrite Heavy ground's first clause; or
- introduce flight as a property some creatures have, and say which.

### Glass Golem seeing through walls is referenced by its own kit

§11.11 gives Glass Golem "takes half damage from Spark laws" and an ability that
raises a crystal wall. §11.2 gives it "sees through walls", which is the more
characterful property and the one its name implies. Neither is wrong; the point
is that the choice is currently unmade.

### Emberling glowing is a genuine trade-off that disappears

§11.2's Emberling "glows: seen in the dark, and lights its surroundings" — a
real cost-and-benefit against Glowing dark and Soul lanterns, both of which key
off light. §11.11 replaces it with immunity to Heat bloom, which is flatter.

**Recommendation:** adopt §11.11's resistances as the rule, and recover these
three as *traits* rather than species passives (§11.3 already has Lantern-born,
Night-eyed and Floaty doing exactly this kind of work). That keeps the
one-resistance rule intact and stops the law text pointing at nothing.

---

## A separate fault this surfaced

**Three laws key off creature attributes that no creature has.** Filed as G12.

| Law | Keys off | Does it exist? |
| --- | --- | --- |
| Heavy ground | "Flyers" | Only in §11.2 — see above |
| **Density** | "Big characters" / "small ones" | **Nowhere at all** |
| Swarm birth | "two small guards with 30% of its strength" | Weaker case — see below |

Density (Matter, rare, 20) reads: *"Big characters get +30% health and −20% speed;
small ones get +25% speed and −20% health."* There is no size or mass attribute on
any creature. §11.1's role table carries Health, Speed, Power and Carry — nothing
else. §11.11's "proportions" are in heads, which is art direction for the
character artist, not a simulation value. §11.10's forms add quirks like "+10%
carrying", never a size.

So Density's entire tier-1 effect has nothing to resolve against. The likely
intent is that Warden (420 health) is big and Mender or Scout (130, 120) is small,
but that is never stated, and a law that silently means "by role" should say so.

Swarm birth is the mildest of the three: *"Each knocked-out guard splits into two
small guards with 30% of its strength."* Here "small" describes what the law
*creates* rather than an attribute it reads, so it does not strictly need a size
system. But "30% of its strength" is undefined too — 30% of health, of power, of
both? — and whether the split guards are a distinct entity with their own
perception profile (§12.17 defines cones per role, and these have no role) is not
stated either.

**This matters beyond one law.** §7.3's best architectural decision is that laws
change a realm's rule sheet and never contain special cases. A law keying off an
undefined attribute is the same failure in a different direction: the parameter it
reads does not exist. Every law's tier values should be expressible against a
named creature or realm attribute — that is G10's point too, and the law data
table is where it gets enforced.

---

## Still open

- **C6 itself** until this is signed off.
- **G12** — the missing size attribute, and whether flight exists.
- **G10** — several tier II/III values are qualitative ("also reveals hidden
  wards") rather than parameter changes, so the same class of problem is present
  in the tier table.
