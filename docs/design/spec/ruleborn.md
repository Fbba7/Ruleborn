# The eighteen ruleborn — reconciled specification

**Status: proposed.** This resolves C6 by making §11.11 the home and retiring
§11.2 as a second spec. It needs sign-off before content is authored (§26.7).

Data: [`content/ruleborn.json`](../../../content/ruleborn.json) — which
deliberately still carries **both** readings, marked, until this is signed off.
Every count below is printed by `python3 tools/ability_text.py`, not typed here.

---

## What v3.1 already settled

This spec was written against v3.0 and two of its three arguments have since
been answered. They are kept, because a spec that silently drops a question
reads as if it never asked one.

- **The three role conflicts are gone.** Prism Mite, Stormhound and Rootrunner
  each had a different role in the two sections. v3.1 reconciled all three:
  both now give 3 Scout / 3 Breaker / 4 Carrier / 4 Warden / 4 Mender.
  Role drives crew composition, guard behaviour (§12.8) and the Nursery's
  fewest-roles-first rule (§11.5), and all three now read the same.
- **Size and flight exist.** This spec argued that flying existed only in
  §11.2's Featherkin passive, so Heavy ground's first clause pointed at
  nothing. v3.1 answered it on a different axis than the one proposed here:
  size and flies are now **stated columns on every ruleborn** in §11.2, not
  passives on some of them, and Density, Heavy ground and Swarm birth read
  them. That closes G12 and C26, and it means the third of the three
  recoveries proposed below — introducing flight as a property and saying who
  has it — is done.

---

## The problem that is left

### The passives are still two different columns

Seventeen of the eighteen differ; only Hourkeeper's agree word for word. The
difference is not phrasing, and it is measurable against §11.11's own stated
rule:

> Each has one habit you can watch at home. Each **resists exactly one law
> family**, so crew choice against a scouted island is a real decision. — §11.11

A resistance has to name a law. **6 of §11.2's passives name no law
at all** — Glass Golem, Prism Mite, Emberling, Sparkwright, Bloomling, Echoplate — so they are properties rather than
resistances, and adopting them means abandoning the rule that makes scouting
worth paying for. Only one of §11.11's names none, and that one names a *note*
instead (Glass Golem, "takes half damage from Spark laws"), which the check
reads as naming nothing.

**7 more name a law in both columns, and a different law in each:**

| Ruleborn | §11.11 resists | §11.2 passive |
| --- | --- | --- |
| Featherkin | Half gravity | Heavy ground |
| Skyskipper | Leapfrog | Half gravity |
| Rambler | Current, Tilt | Current, Inward pull |
| Stormhound | Chain lightning, Static | Static |
| Rootrunner | Heavy ground | Spores |
| Lantern Wisp | Glowing dark | Soul lanterns |
| Soulmender | Haunting | Soul swap |

The full pairs:

| Ruleborn | §11.11 resists | §11.2 passive |
| --- | --- | --- |
| Featherkin | Ignores Half gravity's overshoot | Flies; grounded by Heavy ground |
| Skyskipper | Unbothered by Leapfrog's noise | Leaps one extra obstacle under Half gravity |
| Rambler | Immune to being pushed by Current or Tilt | Pushed less by Current and Inward pull |
| Glass Golem | Takes half damage from Spark laws | Sees through walls |
| Quarryback | Ignores Brittle stone's crumbling ground | Takes less damage from Brittle stone |
| Prism Mite | Sees through Glass and Mirror images | Tiny and quick |
| Tidewalker | Ignores Slow rivers and Rapids | Ignores Slow rivers |
| Stillwatch | Hides perfectly under Stillness | Invisible while still, even without Stillness |
| Emberling | Immune to Heat bloom and ember vents | Glows: seen in the dark, and lights its surroundings |
| Stormhound | Immune to Static and Chain lightning | Immune to Static |
| Sparkwright | Unaffected by Overcharge's surges | Heals more near fire |
| Mossbear | Immune to Thorns | Unharmed by Thorns |
| Bloomling | Immune to Spores | Hedges part for it |
| Rootrunner | Ignores Heavy ground | Ignores Spores |
| Echoplate | Returns automatically under Echoes | Comes back once at 50% after being knocked out |
| Lantern Wisp | Cannot be hidden by Glowing dark | Carries its own light under Soul lanterns |
| Soulmender | Unaffected by Haunting's trails | Soul swap costs its partner less |

### The abilities are two designs, not two wordings

All eighteen differ, and **12 of them do a different thing** rather than
the same thing by a different amount: Mossbear mitigates or heals, Prism Mite
splits health or loot, Echoplate shields the crew and reflects or shields one
ally and does not. Of the 15 that state a cooldown on both sides,
§11.2's is shorter in 13, median four seconds — one direction in thirteen of
fifteen is two balance passes, not two phrasings.

---

## The resolution

**Adopt §11.11 as the home.** It is the later spec, the richer one — look,
proportions, personality, an idle habit, ability, resistance, best work and a
sound each — and the only one that follows a stated rule. **Then §11.2 becomes
a generated index**: name, school, role, size, flies, one-line ability, emitted
from the same table and never hand-maintained. Two hand-maintained tables of
the same eighteen things is what stopped this being caught.

Three of §11.2's passives are worth keeping and one is already kept:

- **Flight** — kept, as its own column on all eighteen (v3.1).
- **Glass Golem seeing through walls** is more characterful than "takes half
  damage from Spark laws" and is what its name implies.
- **Emberling glowing** — "seen in the dark, and lights its surroundings" — is
  a real cost-and-benefit against Glowing dark and Soul lanterns, where
  immunity to Heat bloom is flat.

**Recommendation:** keep §11.11's resistances as the rule and recover those two
as *traits* rather than species passives. §11.3 already has Lantern-born,
Night-eyed and Floaty doing this exact work, so the one-resistance rule stays
intact and no law text points at nothing.

---

## The eighteen abilities

Each pick is argued from the creature's role or from a system the document
already has, never from taste — eighteen picks argued from taste is a redesign
and needs a designer; eighteen argued from §12.6, §12.19 and §11.11 is a
reading that can be disagreed with line by line. The reasons are in
`tools/ability_text.py` and printed in full by running it.

`11.11` and `11.2` mean that section's own words. `merge` means each carries
something the other needs.

| Ruleborn | Role | From | Ability |
| --- | --- | --- | --- |
| Featherkin | Scout | 11.11 | Glide 3 tiles, ignoring one height level |
| Skyskipper | Carrier | merge | Bound 4 tiles while loaded; carries 40% more |
| Rambler | Breaker | 11.2 | Charge 5 tiles, breaking the first ward hit |
| Glass Golem | Warden | merge | Raise a crystal wall that blocks guards for 6 s |
| Quarryback | Breaker | 11.2 | Break walls and the Vault 50% faster for 6 s |
| Prism Mite | Carrier | 11.2 | Split into two mites, each carrying half, for 5 s |
| Tidewalker | Carrier | merge | Ignore all slowing for 6 s; wades at full speed and carries one ally through water |
| Hourkeeper | Mender | 11.2 | Return an ally to its health of 5 seconds ago |
| Stillwatch | Warden | 11.11 | Freezes one guard for 2.5 s |
| Emberling | Breaker | 11.2 | Burst a ward or pylon for heavy damage |
| Stormhound | Scout | 11.11 | Sprints 40% faster for 5 s |
| Sparkwright | Mender | 11.11 | Cuts one ally's cooldown by 5 s |
| Mossbear | Warden | 11.11 | Roots in place, taking 50% less damage for 6 s |
| Bloomling | Mender | merge | Heal all allies within 3 tiles by 15% over 5 s |
| Rootrunner | Carrier | 11.2 | Grow a root bridge over a gap for 8 s |
| Echoplate | Warden | 11.11 | Shield flare, blocking one hit for the crew |
| Lantern Wisp | Scout | merge | Reveals hidden wards and guards within 6 tiles, held for 6 s |
| Soulmender | Mender | 11.11 | Links the crew: damage is shared for 8 s |

**The cooldowns are deliberately not picked here.** Both tables are two to
three times over §12.6's own budget for the whole run — a crew of three on a
150-second clock gets 25 ability windows under
§11.11 and 31 under §11.2, and a crew of five on a
240-second clock gets 67 and
83, against the 15 to 25 decisions §12.6 budgets
and names "when to use abilities and casts" among. So a cooldown picked from
either column is picked from a table that does not fit the game around it.
That is **D32**: one decision rather than eighteen, and every cooldown here
follows from it.

---

## Still open

- **C6 itself** until this is signed off.
- **D32** — whether an ability is a decision or texture, which sets all
  eighteen cooldowns.
- **G10** — several tier II/III values are qualitative ("also reveals hidden
  wards") rather than parameter changes, so the same class of problem is
  present in the law tier table.
