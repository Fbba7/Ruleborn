# Specification gaps

Things a builder would have to invent, listed because the design document is
otherwise specified to an unusually fine grain — which makes the gaps easy to
miss. These are distinct from the contradictions in `03-contradiction-register.md`:
here, nothing conflicts, there is simply nothing.

Graded by what they block.

---

## G1. Pathfinding and crew movement — the largest gap

**Blocks:** the heist prototype, the simulation core, every balance number.

The document specifies in detail what guards *perceive* (§12.17) and what laws do
to *movement parameters* (§7.3), but never how a crew actually moves. Unanswered:

- Is the world a tile grid or continuous with tile-sized features? §6 is written
  in tiles; §12.17's detection is in metres with sub-metre zones and 3–8°/tick
  turn rates, which implies continuous positions and headings.
- How does a player order movement? §12.7's controls cover *abilities* (tap a
  portrait to fire, drag to aim, drag onto a path at a fork to split) but the
  default locomotion is never stated. Does the crew auto-run the planned route
  from §12.5? Can it be redirected mid-heist, and how?
- What happens at a fork the planner did not anticipate?
- How do 3–5 crew members avoid each other, and what is the formation?
- Does the route planner in §12.5 produce a path the simulation then follows
  literally, or a sequence of waypoints re-pathed at runtime? (The two have very
  different determinism properties.)

This matters more than it looks. §30.7 premise 3 flags "delegated control still
feels like agency" as only *conditionally* supported, with the failure mode
"my units are stupid" and a 70% felt-control threshold. **The pathfinder is the
single system most likely to fail that premise**, and it is the least specified.

**Recommendation:** specify this before the vertical slice, and treat felt control
as a gate, not a polish item. Pikmin is cited as the model (§2.2) — that reference
should be made concrete: what, exactly, is the Ruleborn equivalent of throwing a
Pikmin?

---

## G2. What a guard does when it catches you

**Blocks:** heist outcomes, the fight model.

§12.8 gives ambush rules (first unseen hit: 2 s stun, triple damage; two ambush
hits knock out an equal-level guard) and a level cap. §12.17 says Alerted guards
"converge" and are "never lethal — the crew is knocked out and sent home". But:

- What is the actual combat resolution? Roles have Power (§11.1: 6–40) and
  Health (130–420), and §12.8 gives a 0.8 s wind-up, but no attack rate, no
  damage formula, no range.
- Can the crew choose to fight, or only ambush and flee?
- Do knocked-out crew members drop loot where they fall, or is it lost? (§13
  says "knocked-out raiders leave behind whatever they were carrying"; §12.6
  says anyone caught at the clock's end "drops what it carries" — but during the
  run is undefined.)

---

## G3. Ward placement, triggering and disarming

**Blocks:** the island builder, defence balance.

§10.3 lists six wards with effects and reset timers. §12.5 says a Tinker trait
"disarms wards 30% faster" — implying a disarm action that is never specified
(who can do it, how long, what it costs, whether it makes noise). Also missing:

- What triggers a ward — proximity, line of sight, stepping on a tile?
- Ward levels 1–5 exist in the asset list (§21.9: "6 types × 5 levels") and the
  building list, but §10.3 only gives level 1 effects.
- Can a ward be destroyed as well as disarmed? Breakers deal "double damage to
  wards" (§11.1), so presumably yes — but wards have no health values.

---

## G4. The Vault, Storehouses and the loading loop

**Blocks:** the heist's climax, which is the emotional peak of the game.

§12.6 gives: Vault health 1,500 per level, Breakers double damage, cracking adds
10% awareness per 5 s to Heart guards, Carriers load 150 loot/s. But if §9.6's
minted-haul formula is authoritative (see C2), **the relationship between loading
time and payout is undefined**. Does loading longer earn more? If not, why is
there a loading phase at all? If yes, what is the curve, and how does it interact
with the `grade` term?

This is the decision the document identifies as the Vault phase's core tension
("when to stop loading") and it currently has no mechanism behind it.

---

## G5. The Keeper's Spire's own defence

§12.6 says "breaking a pylon switches its law off for the rest of the heist and
gives a page of it". §5.7 lists "the Spire's light going out when a pylon breaks"
as the Heart's signature moment. But pylons have no health, no count per realm,
no placement rule, and no relationship to the law slots they presumably represent.
§10.2 lists "Law Pylon" as a building type but its level table was not examined in
detail — this should be verified against the law-slot model in §5.1.

---

## G6. Matchmaking and rating mechanics

§12.15 says skill and island difficulty use "a Bayesian rating with an explicit
uncertainty term" and that a new island "starts wide". §12.3 gives the filter
bands (±150 Renown, ±3 Keeper levels, ±20% strength). Missing: how Renown,
Keeper level and the internal difficulty rating combine, how the "median target is
winnable" guarantee is actually enforced, and what happens when the three filters
return nothing (echo universes fill the gap, but the ordering is unstated).

---

## G7. The economy model itself

§24 says a Python model "simulates engaged, regular and casual players day by day"
and "generated the tables in 10.2 and 14, and is re-run whenever a number changes".
**That model is not in the document, and it is the source of roughly a quarter of
the document's numbers.** Without it, no number in §10.2, §14.2 or §14.3 can be
re-derived or re-tuned.

**Recommendation:** this is the highest-value single artefact to rebuild. It is
also a natural first coding task — it needs no engine, no art and no phone, it
validates the economy independently of the simulation spike, and it is the tool
that will resolve C2 and C4.

---

## G8. Offline and multi-device edge cases that are named but not resolved

§24.12 is otherwise excellent. Two gaps:

- "Two devices cannot double-count, because currency is a ledger of minting
  events" — but the *lease* in §24.12 is per-target-snapshot. Two devices could
  hold two leases on the same target. What happens?
- Entry fees (§9.4: 2% of Starlight, returned on a clean heist) are debited when?
  At lease time, at submission, or at validation? An offline heist that is never
  submitted has an unclear fee state.

---

## G9. The 60-second guided build

§13.1 makes "a 60-second guided build before the first player heist" the primary
mitigation for the design's #1 risk, and §27.2 confirms it as a decision. It is
never specified: what three terrain features, which guard, which law, what the
player is told, and — critically — whether the island they build is then
*actually used* as their defence.

Given that this is the mitigation for the highest-ranked risk in the document, it
deserves the same treatment §16 gives to the first session.

---

## G10. Law tier effects are underspecified for ~20% of laws

§7.7's full sheets give tier II/III values, but several are terse in ways that do
not translate to data. Examples: Glass tier II is "Also reveals hidden wards" and
tier III "also shows guard vision cones" — these are qualitative additions, not
parameter changes, which means the "laws are parameters, not special cases"
principle (§7.3) is already bending. Density's "±40%/30%, ±50%/40%" needs a key.

**Recommendation:** when the law data table is authored, every tier value must be
expressible as a rule-sheet parameter change. Any that cannot be is a design
smell worth resolving then, not at implementation time.

---

## G11. Localisation of a vocabulary-dense game

§25.4 sets a comprehension gate ("70% can define chord, resonance and ruleborn
after the tutorial") and §26.9 says every new name is "said aloud in the twelve
launch languages". But twelve languages × a coined vocabulary (ruleborn, notes,
schools, 48 law names, 44 resonance names, 12 chord names, 18 creature names) is
a large translation problem with no owner in the team model (§26.3: one designer,
one coding agent, three contractors). §20.6 also says languages at launch are
"English and Portuguese", contradicting §26.2's twelve-language global launch —
though these are plausibly beta vs global.

---

## Gaps the document names but deliberately leaves open

These are not oversights. §27.3 lists them as decisions for the owner, and they
are correctly deferred:

- Casual pacing (1,019 days to finish) — a catch-up discount is decided in §27.5
  but not specified
- Whether the Island Fund survives its own six-month test
- Whether to strengthen performative and emotional challenge (§19.4)
- Law Clash rules (v1.2)
- Soft-launch countries
- Whether the interface says "universe" or "your sky"
