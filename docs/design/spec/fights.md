# Fights, ambushes and knockouts — proposed specification

**Status: proposed, and largely new design.** This fills G2. The document gives
five numbers about combat and one rule that its own numbers contradict; what is
below is a resolution, not a reconciliation, because there is no second version
to reconcile against.

Report: `python3 tools/decision_support.py combat`.

---

## What exists today

| Where | What it gives |
| --- | --- |
| §11.1 | Power 6–40 and Health 120–420 per role, at level 1 |
| §11.4 | +8% health and power per character level |
| §12.8 | An ambush rule, a 0.8-second wind-up, a level cap, a knockout rule |
| §12.17 | Alerted guards converge; "never lethal — the crew is knocked out and sent home" |
| §13 | "Knocked-out raiders leave behind whatever they were carrying" |

What is missing is the thing that turns those into a fight: **no attack rate, no
damage formula, no range.** A builder handed this document cannot resolve a
single exchange of blows.

---

## The finding: §12.8's knockout rule is true for at most five of twenty-five pairings

§12.8 states:

> Two ambush hits knock out a guard of equal level.

There is only one cadence anywhere in the document — §12.8's own 0.8-second
wind-up — so the natural reading is one hit per 0.8 s for damage equal to Power.
Under that reading, with an ambush at triple damage, the number of hits needed to
drop an equal-level guard is:

| raider ↓ / guard → | Scout | Breaker | Carrier | Warden | Mender |
| --- | --- | --- | --- | --- | --- |
| **Scout** | 8 | 13 | 12 | 33 | 9 |
| **Breaker** | 1 | 3 | 2 | 9 | 2 |
| **Carrier** | 13 | 21 | 18 | 51 | 15 |
| **Warden** | 4 | 7 | 6 | 19 | 5 |
| **Mender** | 18 | 28 | 25 | 68 | 20 |

A Mender attacking a Warden needs 68 hits — **54 seconds**, against a guard that
the ambush stunned for two. The rule holds for three pairings read as
ambush-then-strike, and for five read as two simultaneous ambushes, four of which
need a Breaker.

The reason is a ratio. For two hits to drop a target, the rule needs
`Power = Health ÷ 4`. What the roles actually carry:

| Role | Power / Health | Short by |
| --- | --- | --- |
| Scout | 12 / 120 = 0.100 | 2.5× |
| Breaker | 40 / 180 = 0.222 | 1.1× |
| Carrier | 8 / 160 = 0.050 | 5.0× |
| Warden | 20 / 420 = 0.048 | 5.2× |
| Mender | 6 / 130 = 0.046 | 5.4× |

No role reaches it. This is the same pattern as C2 and F1: Power and Health were
set for one purpose — standing fights and home defence, where a Warden *should*
take a long time to kill — and a rule was written against them later without
anyone multiplying the numbers together.

---

## Proposal

### 1. The cadence, damage and range

| | Value | Where it comes from |
| --- | --- | --- |
| Attack interval | **0.8 s**, shown as a wind-up | §12.8, made universal rather than guards-only |
| Damage per hit | **Power**, scaled `1.08^(level−1)` | §11.1 and §11.4 |
| Range | **1 tile** | New. Every stated ability range in §11.1 is short (Mender 4, Warden 3) and no role has a ranged attack |
| Interrupt | A stun or freeze during the wind-up cancels the attack and dazes for 1 s | §12.8, unchanged |

One hit per 0.8 s for Power damage is not an arbitrary choice: it is the reading
under which the Vault's 1,500-health-per-level curve takes 10–25 seconds to crack
across the whole game, against the "about 30 s" §12.6 budgets for that phase
independently (see `vault.md`). Three numbers written in three sections agree
under this model and under no other obvious one.

### 2. Ambush: triple Power **or** half the target's maximum health

```
ambush damage = max(3 × Power, 0.5 × target maximum health)
```

Everything else in §12.8's ambush rule is unchanged: it applies only to the first
hit on a guard that has not noticed the crew, and it stuns for 2 seconds.

This makes §12.8's own sentence true by construction — **two ambushers drop any
equal-level guard, in all twenty-five pairings** — while leaving the Breaker's
one-shot on a Scout intact, because the triple-Power term still wins there. What
changes is that a Mender or a Carrier can now contribute to an ambush instead of
being a bystander with a Power of 6.

Seconds for a *lone* ambusher to finish the job, before → after:

| raider ↓ / guard → | Scout | Breaker | Carrier | Warden | Mender |
| --- | --- | --- | --- | --- | --- |
| **Scout** | 6.4 → 4.8 | 10.4 → 7.2 | 9.6 → 6.4 | 26.4 → 15.2 | 7.2 → 5.6 |
| **Breaker** | 0.8 → 0.8 | 2.4 → 2.4 | 1.6 → 1.6 | 7.2 → 5.6 | 1.6 → 1.6 |
| **Carrier** | 10.4 → 7.2 | 16.8 → 10.4 | 14.4 → 8.8 | 40.8 → 22.4 | 12.0 → 8.0 |
| **Warden** | 3.2 → 3.2 | 5.6 → 4.8 | 4.8 → 4.0 | 15.2 → 9.6 | 4.0 → 4.0 |
| **Mender** | 14.4 → 8.8 | 22.4 → 12.8 | 20.0 → 12.0 | 54.4 → 28.8 | 16.0 → 9.6 |

A lone Mender still should not pick a fight with a Warden. That is correct — it
is the difference between "clever beats strong", which §12.8 asks for, and
"anybody beats anybody", which it does not.

**Why half and not a third.** Half is the number that makes the stated rule
exactly true: two ambushers, two halves, one knockout. A third would need three
ambushers, which a crew of three (§12.5, before Keeper 8) cannot spare, and would
quietly delete the tactic for early players.

### 3. The level cap, stated as arithmetic

§12.8 says "a level advantage counts for at most 3 levels". As a formula:

```
effective level = clamp(attacker level, defender level − 3, defender level + 3)
```

applied before the `1.08^(level−1)` scaling, and symmetrically to both sides. So
the widest damage ratio any fight can show is `1.08^6 ≈ 1.59`, whatever the real
gap. That is what lets a level-12 crew rob a level-30 universe, which §12.15's
matchmaking band already assumes is possible.

### 4. Can the crew choose to fight?

**Yes, at any time — but attacking a guard that has noticed you is an alarm in
all but name.** Three rules, and the third is the one that keeps stealth worth
playing:

1. Any crew member may attack any guard. There is no separate "combat mode".
2. An attack is loud: heard within 5 m, the same as "breaking something" in
   §12.17's noise table.
3. **A guard that takes damage without being ambushed goes to suspicion 1000
   immediately** — Alerted, calling out, converging, raising the realm alarm.

So a fight the crew starts from concealment is a tool; a fight the crew starts in
the open is a decision to go Loud and take the 0.7 grade. That is a real choice
with a priced cost, which is what §12.8 means by rewarding cleverness, and it
needs no rule forbidding anything.

### 5. What happens when a crew member drops

§12.8 says "a crew member at zero health is caught unless revived" and never says
what reviving is. §13 and §12.6 disagree about loot: §13 says knocked-out raiders
leave behind what they were carrying; §12.6 says anyone caught at the clock's end
drops what it carries. Both are satisfied by one rule, so this is recorded as a
gap rather than a contradiction:

| | Rule |
| --- | --- |
| At zero health | **Downed**, not caught. Cannot move or act |
| Loot | Dropped on the tile, immediately, as a pile any crew member can pick up |
| Time on the ground | **10 seconds** |
| Revive | An ally adjacent for **3 s** (**1.5 s** for a Mender), restoring 30% health |
| Reviving is loud | Heard within 2.5 m — walking, not breaking |
| After 10 seconds | **Caught.** Removed from the heist, 180 minutes' rest (§12.9), loot stays on the ground |

Ten seconds is one decision by §12.6's cadence, which is the point: a downed
crew-mate is a bet — go back through the cone you just crossed, or take the
Partial grade and its 0.4 multiplier. Dropping the loot on the tile rather than
deleting it is what makes the bet interesting, since the pile is still there and
still worth the run.

**The Mender's existence depends on this rule.** With a Power of 6 and 130 health
it is the weakest role in the game; halving its revive time is most of what it is
for outside a standing fight.

---

## What this forces elsewhere

| Section | Change |
| --- | --- |
| **§11.1** | Add the attack interval and range to the role table. They are role stats, not a combat appendix |
| **§12.8** | Replace the ambush line with the `max(3 × Power, 50% of maximum health)` form. State the level cap as the clamp. Add the three fighting rules and the downed/revive rules |
| **§12.17** | Alerted is currently described as an end state ("the crew is knocked out and sent home"). Under these rules a crew can survive Alerted and escape Loud, which §12.9 already prices. §12.17's sentence should say what it means: converging guards, not an automatic loss |
| **§29.1** | The formulas appendix has no combat section. It needs one |

---

## Still open

- **Guard levels.** A guard's level is its character's level, and §12.15 matches
  within 3 Keeper levels — but a defender can post a level-2 stray or its best
  character, and nothing says which the matchmaker assumes. This decides whether
  the level clamp ever binds in practice.
- **Menders on both sides.** A guard Mender healing 8 health a second against a
  crew Mender doing the same is a stalemate that the 0.8-second cadence does not
  obviously break. Worth a pass once numbers can be simulated.
- **Whether guards ambush.** Nothing says a guard the crew has not seen gets the
  ambush bonus. It probably should not — the defender is not playing — but the
  rule as written is symmetrical and would.
