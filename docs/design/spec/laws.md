# The rule sheet, and what a scope cut actually costs — proposed specification

**Status: proposed.** This resolves F10, the last blocking item without a draft,
and records **F23**, which came out of costing the cut.

Reports: `python3 tools/law_effects.py` and `python3 tools/scope_cut.py`.

---

## §7.3's claim, and the list it never gives

§7.3 is the architectural decision the whole design rests on — laws change a
realm's rule sheet rather than containing special cases — and v3.0's §12.21 turns
it into a rule:

> Every tier effect of every law must be expressible as a change to a named
> parameter. Anything that cannot be is a design smell to resolve while
> authoring, not at implementation.

**The document never names the parameters.** A rule that cannot be applied while
authoring — which is when it says it should be applied — is not yet a rule. So
the first half of this file is the list, twenty entries, emitted at
`content/law_effects.json`:

`alarm_range`, `carry_weight`, `climb_levels`, `clock_rate`, `cone_angle`,
`crew_speed`, `damage`, `guard_speed`, `health_drain`, `health_regen`,
`hide_behind_walls`, `leap_obstacles`, `loaded_speed`, `noise_radius`,
`regrow_seconds`, `sight_range`, `still_is_invisible`, `structure_damage`,
`suspicion_decay`, `suspicion_fill`.

A vocabulary that grows to fit each new law is not a vocabulary. `law_effects.py`
refuses to run if a law names a parameter outside this sheet, so a future
season's six laws cannot quietly extend it.

## What the 48 laws turn out to be

Classified against that sheet, counting each law by its **hardest** kind:

| kind | laws | what it needs |
|---|---|---|
| parameter | 16 | nothing — the rule sheet already has the number |
| event | 14 | a periodic or conditional rule inside the tick loop |
| entity | 7 | an object the simulation must spawn, track and render |
| authored | 8 | a choice from the realm's owner that is not a number |
| attribute | 3 | a property no character carries (C26) |

**Sixteen of forty-eight are parameter changes and thirty-two are engine
features.** §26.1 costed all 48 as content. That is F10, and it is unchanged.

The distribution by rank is the part that matters for a cut: of 18 Commons, 9 are
pure parameter changes; of 12 Deep laws, **one** is. Depth is bought with engine
work, which is a reasonable design and an unbudgeted one.

---

## What a cut to 24 costs, and what it does not

D6 proposes 24 laws at launch and Q5 is the owner's decision. Weighting each kind
by the engine work it needs — parameter 0, attribute 1, event 2, authored 2,
entity 3, **a judgement stated openly rather than a measurement** — the whole set
costs 84 points.

| cut | laws | engine cost | pure parameter | chords lost |
|---|---|---|---|---|
| all 48 | 48 | 84 | 16 | — |
| cost-aware 24 | 24 | **15** | 16 | none |
| by rank, ignoring cost | 24 | 39 | 9 | none |

**Choosing which 24 by engine cost rather than by rank saves 62% of the cut's
remaining engine work, for exactly the same amount of content.** The cost-aware
cut keeps all sixteen free laws and eight cheap ones, and still fills §7.7's six
schools evenly at four each.

The weights are arguable and the conclusion is not sensitive to them: the gap
between 15 and 39 is driven by *which kinds* land in the set, and every plausible
weighting orders the kinds the same way.

**What does not constrain the cut** is the thing that looks like it should.

---

## F23 — four laws reach all twelve chords

§8.5 calls chords "the late-game discovery". Owning **four** well-chosen laws
makes every one of the twelve reachable, and there are 42 different four-law sets
that do it. The cheapest:

| law | school | rank | notes | stability |
|---|---|---|---|---|
| Haste | Time | Rare | Flow + Spark | 18 |
| Thorns | Life | Rare | Bloom + Weight | 15 |
| Whispers | Spirit | Common | Glow + Echo | 16 |
| Borrowed Face | Spirit | Deep | Veil + Hush | 21 |

Four is not a search artefact, it is the floor: no law carries more than two
notes, the wheel has eight, so three laws can never cover it. **The chord table
is reachable from one twelfth of the launch set.**

This is D14 again and harder. D14 found that §8.8's fix — a chord needs three
*distinct laws*, not three notes — made §8.5's sentence true without making
chords late-game, because 23 of the 48 laws carry two notes. Costing the scope cut
puts a number on how little the law table gates chords at all: **nothing in the
collection is the gate.** What gates chords is the Lab at level 3 (Spire 5, about
day 42), which §8.5 mentions and §8.8 does not lean on, and the stability to weave
three at once — the cheapest triple from the set above costs 49 against a day-2
capacity of 51.

So a cut to 24 laws cannot break chords, and a cut to 24 laws cannot fix them
either. If chords are meant to be a late-game discovery, the gate has to be
stated somewhere other than the size of the law table.

---

## Sections this forces a change to

| Section | Change |
|---|---|
| §12.21 | List the twenty parameters. The rule cannot be applied while authoring without them |
| §7.3 | Say that 16 of 48 laws are parameter changes and 32 are engine features, or stop describing all of them as rule-sheet changes |
| §26.1 | The 48 laws are not one line of content budget; 32 of them are engine work |
| §8.5 | Name the gate that makes chords late-game — the Lab, and stability — since four laws reach all twelve |
