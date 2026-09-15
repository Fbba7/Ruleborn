# Wards and law pylons — proposed specification

**Status: proposed.** This fills G3 and G5, and starts by shrinking both: the
analysis recorded more missing than is actually missing, because §10.2's building
tables had not been read against §10.3 and §12.6.

Report: `python3 tools/decision_support.py wards`.

---

## First, a correction to the analysis

Two claims in `04-specification-gaps.md` were wrong, and both were wrong the same
way — a table was described as absent when it exists in a different section.

| Claim | What §10.2 actually says |
| --- | --- |
| "§10.3 only gives level 1 effects" for wards | Right about §10.3. §10.2's Ward row gives all five levels: **effect +0/15/30/45/60%, resets 10/9/8/7/6 s** |
| "pylons have no health, no count per realm, no relationship to law slots" | §10.2's Law Pylon row gives ten levels at **600 health per level**, and states the relationship directly: **"One per law slot; per slot"** |

G5's original text flagged this itself — "its level table was not examined in
detail". It has been now, and most of G5 closes. What survives of G5 is one
sentence in this spec's *Pylons* section below.

That leaves G3 smaller and much sharper than recorded.

---

## G3, restated: "effect +15%" has no key

Each of the six wards states its effect in its own units, and for three of them
there is more than one number the percentage could be scaling:

| Ward | §10.3 effect at level 1 | Candidates |
| --- | --- | --- |
| Gravity Well | Pulls anyone within **3 tiles** to its centre and holds them **2 s** | radius, or hold |
| Crystal Wall | A breakable wall (**800 health**) | health |
| Time Snare | Freezes the first character to step on it for **2.5 s** | duration |
| Static Coil | Shocks anyone within **2 tiles** every **3 s** | radius, rate, or **damage, which is never stated** |
| Thorn Hedge | Hurts anyone pushing through (**5% health a second**) | damage |
| Lantern Glare | Shows the crew to every guard for **5 s** and blinds them **2 s** | reveal, or blind |

### The rule that picks them: never scale a distance

A ward whose radius grows when it is upgraded covers tiles it did not cover when
it was placed. Three things break at once: the island the defender designed is
not the island they get; the editor cannot draw a ward's footprint without
knowing its future level; and §13.4's "no layer above a quarter" budget is
computed against a coverage that changes underneath it.

So the scaled quantity is always a **duration or a damage**, never a distance and
never a rate. Applied:

| Ward | Scales | L1 | L2 | L3 | L4 | L5 |
| --- | --- | --- | --- | --- | --- | --- |
| Gravity Well | hold | 2.0 s | 2.3 s | 2.6 s | 2.9 s | 3.2 s |
| Crystal Wall | health | 800 | 920 | 1,040 | 1,160 | 1,280 |
| Time Snare | freeze | 2.5 s | 2.9 s | 3.3 s | 3.6 s | 4.0 s |
| Static Coil | damage per shock | **8%** | 9.2% | 10.4% | 11.6% | 12.8% |
| Thorn Hedge | damage per second | 5% | 5.8% | 6.5% | 7.3% | 8.0% |
| Lantern Glare | reveal | 5.0 s | 5.8 s | 6.5 s | 7.3 s | 8.0 s |

Damage is a percentage of the target's maximum health, following Thorn Hedge,
which is the only ward that states its damage and states it that way. That also
keeps wards from scaling against character level, which they otherwise would.

**Static Coil's 8% is new.** The document gives it no damage at all. 8% of
maximum health every 3 seconds is 2.7%/s against Thorn Hedge's 5%/s, which is
right: the Coil is an area denial that cannot be walked around at 2 tiles, the
Hedge is a wall you choose to push through.

Everything the percentage does *not* scale is fixed at its level-1 value,
including every radius and Lantern Glare's 2-second blind. Reset timers come from
§10.2's own column, unchanged.

---

## What triggers a ward

The document never says, and then implies three different answers. They are
consistent if read as three categories rather than one rule, and the categories
are already visible in the wording:

| Kind | Wards | Trigger |
| --- | --- | --- |
| **Passive** | Crystal Wall, Thorn Hedge | Nothing. They are obstacles; they act on anyone who tries to pass |
| **Aura** | Static Coil | Nothing — §10.3 says "always on". Everyone inside 2 tiles is shocked every 3 s |
| **Triggered** | Gravity Well, Time Snare, Lantern Glare | The first crew member to enter the trigger area. Then the reset timer runs |

The trigger area is the ward's own stated radius, except Time Snare, which §10.3
already specifies as a tile ("the first character to **step on it**"). A
triggered ward fires once and is inert until it resets — which is what the reset
column is for, and what makes §10.2's 10 → 6 second scaling a real purchase.

**This makes deliberate triggering a tactic**, and it should be. Sending the
Warden — 420 health, and the only role that can absorb a Gravity Well without the
crew stopping — through first, then walking everyone else past during the reset,
is exactly the kind of play §12.8 means by "clever beats strong". Upgrading the
ward shortens the window from 10 seconds to 6, which is the defender's answer.

Laws already interact with this correctly: **Delay** (§7.7, Rare, Veil) makes
"wards and abilities take effect 3 seconds after they are triggered", which a
raider uses so that "wards fire late, so you are already past". That law only
makes sense against a triggered model, which is further evidence this reading is
the intended one.

---

## Disarming, and the alternative

§12.5's Tinker trait "disarms wards 30% faster" is the only mention of disarming
anywhere. The action it implies:

| | Rule |
| --- | --- |
| Who | Any crew member, standing adjacent to the ward |
| How long | **3 s + 1 s per ward level** (4 s at level 1, 8 s at level 5) |
| Tinker | ×0.7, per §12.5 |
| Noise | **Silent.** Disarming is the quiet answer |
| Interrupted | Moving cancels it; progress is kept for 5 s |
| What it leaves | The ward is dead for the rest of the heist. It does not reset |
| What cannot be disarmed | Passive wards. A wall is not a mechanism |

### Smashing, and where the crossover sits

§11.1 gives the Breaker "double damage to wards", so wards must have health.
Only Crystal Wall has any. **Proposed: ward health = 500 × level**, with Crystal
Wall the exception whose health *is* its effect and scales from 800 as above.

At a crew level of 12, against a 4–8 second disarm:

| Ward level | Health | Breaker | Scout | Disarm | Disarm (Tinker) |
| --- | --- | --- | --- | --- | --- |
| 1 | 500 | **2.1 s** | 14.3 s | 4.0 s | 2.8 s |
| 2 | 1,000 | **4.3 s** | 28.6 s | 5.0 s | 3.5 s |
| 3 | 1,500 | 6.4 s | 42.9 s | **6.0 s** | 4.2 s |
| 4 | 2,000 | 8.6 s | 57.2 s | **7.0 s** | 4.9 s |
| 5 | 2,500 | 10.7 s | 71.5 s | **8.0 s** | 5.6 s |

Three properties worth having, and all three fall out of the numbers rather than
being asserted:

- **Smashing wins to level 2 and loses from level 3.** The defender's spending
  changes the raider's best answer, which is what a defence upgrade should buy.
- **A Tinker moves the crossover down by one**, so the trait decides something
  instead of shaving a number.
- **Smashing is loud** (5 m, §12.17's "breaking something") and disarming is
  silent, so the fast answer is rarely the quiet one. Where they are close, the
  choice is about the alarm, not the clock.

Only the Breaker can realistically smash anything: a Scout needs 14 seconds on
the cheapest ward. That is correct for role identity and it is also a problem —
see below.

---

## Pylons

Everything G5 asked for is in §10.2 except one sentence, and it is the one that
matters for the route: **what a pylon looks like on the map and whether a raider
can tell which law it carries.** §12.6 says breaking one "switches its law off
for the rest of the heist and gives a page of it", and §5.7 makes the Spire's
light going out the Heart's signature moment — both of which assume the player
knows what they are breaking before they commit.

**Proposal: a pylon shows its law's school colour and its note glyphs, and the
law banner names it on approach** — the same banner §15.3 already uses when the
crew enters a realm. A paid scout (§12.3, 20 Aether per realm) already reveals
each realm's laws; this just puts the same information on the object.

What the detour costs, from §10.2's health and the combat model in `fights.md`:

| Pylon level | Health | Lone Breaker (L12) | Whole crew (L12) | Share of a 180 s heist |
| --- | --- | --- | --- | --- |
| 1 | 600 | 2.6 s | 1.6 s | 1% |
| 3 | 1,800 | 7.7 s | 4.9 s | 3% |
| 5 | 3,000 | 12.9 s | 8.2 s | 5% |
| 6 | 3,600 | 15.4 s | 9.8 s | 5% |
| 8 | 4,800 | 20.6 s | 13.1 s | 7% |
| 10 | 6,000 | 25.7 s | 16.3 s | 9% |

That is a well-shaped cost: cheap early, a real commitment late, and never
dominant. "Often worth a detour" holds.

---

## The finding this turned up: the Breaker is 63% of the crew

Look at the last two columns above. Adding four crew members to the Breaker cuts
the time by **37%**, because against wards, pylons and the Vault the Breaker's
doubled Power of 80 is 63% of the crew's 126.

§12.6 lists "who cracks, who loads" among the Vault phase's decisions. **"Who
cracks" has one answer**, in every situation, at every level. So does "who
smashes the ward" and "who breaks the pylon". Four roles stand and watch, which
is the same complaint `vault.md` makes about loading, arrived at from the other
end.

This is recorded as F6 rather than fixed here, because the fix is a balance
question with more than one defensible answer: narrow the Power spread, give
non-Breakers a reason to join (a stacking bonus for two characters on the same
object), or accept it and stop calling it a decision. What is not defensible is
listing it as a decision while one role is two thirds of the answer.

---

## What this forces elsewhere

| Section | Change |
| --- | --- |
| **§10.3** | Add the scaled-quantity column. Add Static Coil's damage. State the three trigger kinds |
| **§10.2** | Ward health per level. The Ward row gives effect and reset but not what a Breaker is hitting |
| **§12.5** | The Tinker trait now refers to a specified action; the disarm rules belong next to it |
| **§12.6** | Say that a pylon shows its law |
| **§11.1** | "Double damage to wards, pylons and the Vault" is 63% of the crew's output against all three. Either that is intended and should be stated, or it is F6 |
| **§21.9** | 30 ward props (6 × 5 levels) is already budgeted, and is correct: levels are visually distinct because reset windows and durations differ |

---

## Still open

- **Ward health of 500 × level** is chosen to put the smash/disarm crossover at
  level 3. It is a fitted number, not a measured one, and the crossover is the
  thing to playtest rather than the health.
- **Whether a disarmed ward should be visible as disarmed to the defender** in
  the replay. §24.3's free analytics make this possible and §13.5's "watch a
  raid on your island" makes it desirable, but it is a UI question.
- **Whether laws of the same school still strengthen wards by 25% (§10.3) on top
  of the level scaling.** They should, but 25% × 60% compounding is 100% at
  level 5, which may be more than intended.
- **Crystal Wall's "stays broken", and Thorn Hedge's "regrows only with Bloom",
  are in a column headed *Resets after*** — which is about the reset window
  during a heist. So they most likely mean "does not come back within this
  raid", not "is destroyed for good". Most likely is not good enough here: at
  level 5 a Crystal Wall costs 13,700 Starlight, and the two readings differ by
  whether a defender's spending survives contact. Say which one it is.
