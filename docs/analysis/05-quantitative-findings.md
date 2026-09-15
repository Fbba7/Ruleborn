# Quantitative findings

Arithmetic and content-distribution analysis of design document v2.3. Everything
here is reproducible with `tools/check_design_consistency.py`,
`tools/decision_support.py` and `tools/economy_model/` (see its README for how
the model was calibrated).

Findings F1–F3 came out of rebuilding the economy model the document references
but does not contain, and are the most consequential in this analysis. F4 and F5
came out of the opposite exercise — taking the document's combat and Vault
numbers at face value and multiplying them together, which nobody appears to
have done.

---

## 1. What checks out

The document's numbers are in better shape than its prose. These all reconcile:

| Claim | Section | Verification |
| --- | --- | --- |
| Stability capacity 516 at Spire 10 + seven Anchor Stones 10 | §5.5 | `(30 + 8×10) + 7 × (8 + 5×10) = 516` ✓ — and matches the per-level values in §10.2 |
| A finished universe weaves 22 laws | §5.5 | Heart 2 + (6 realms × 3 slots) + 2 crown = 22 ✓ |
| Vault capacity `8,000 × 1.85^(level−1)` | §9.4, §29.1 | L10 = 2,030,700 ✓ matches §10.2 exactly |
| Star Well output `base × 1.35^(level−1)` | §9.3 | L2 = 80 × 1.35 = 108 ✓ matches §10.2 |
| Keeper curve `day ≈ 0.13 × level^1.96` | §14.2 | L16 → day 30 ✓, L28 → day 90 ✓, L40 → day 181 ✓ |
| 48 laws, 8 per school | §7.4, §7.7 | Parsed all 48 law sheets: 8 in each of 6 schools ✓ |
| 39 terrain features in 7 families | §6.2, §6.3 | 8+7+8+5+4+3+4 = 39 ✓; unlock table 14+5+6+5+5+4 = 39 ✓ |
| 44 signature resonances, 12 chords | §8.4, §8.5 | Counted ✓ |
| 16 building types | §10.2, §26.1 | Counted ✓ (but see C8 — the Library is a 17th, unlisted) |
| 1,485 pages to restore the collection | §14.4 | `15×15 + 18×30 + 12×60 = 1,485` ✓ under the three-rank taxonomy |
| Mega-hit arithmetic | §2.7, §22.3 | $2B/yr ÷ 365 = $5.48M/day ✓; 18M × $0.30 = $5.4M ✓ |
| Business scenarios (low, base) | §22.2 | €2,720 ✓ and €25,500 ✓ at 15% commission |
| Island Fund at 10% of revenue | §18.9 | 10% of €25,500 = €2,550 ✓; of €168,000 = €16,800 ✓ |
| Infrastructure byte budget | §24.1, §24.4 | 250k DAU × 150 KB × 30 = 1.125 TB/month ✓ matches the quoted range |
| §9.6's own haul table | §9.6 | Recomputed: L2 287 / L6 1,450 / L10 7,343 vs quoted 284 / 1,437 / 7,278 ✓ (rounding) |

The simulated day-by-day tables in §10.2, §14.2 and §14.3 are self-consistent with
the formulas that produced them, which is strong evidence the economy model
described in §24 really exists and was really run.

---

## 2. The raid economy does not fund the loop it describes

**The most consequential quantitative finding in the document.**

§9.6's formula is internally sound and its own numbers check out. But when its
output is compared with §9.3's production curve for the same player:

| | Six raids/day (§9.6) | Daily production (§9.3) | Raids as share of income |
| --- | --- | --- | --- |
| Day 31 (realm ~6) | 1,450 | 17,300 | **7.7%** |
| Day 181 (realm ~10) | 7,343 | 152,800 | **4.6%** |
| Day 301 (realm ~10) | 7,343 | 256,100 | **2.8%** |

Against the document's own stated targets:

- §9.4: "a successful heist against an even match brings about a fifth of a day's
  production, so heists supply roughly **a third** of an active player's resources"
- §12.1: loot is "about **40%** of mid-game growth"

At day 31, one-fifth of a day's production is 3,460; §9.6 pays 349 per attempt and
759 for a clean raid. **The gap is roughly 5–10×, and it widens with time**,
because production compounds at `1.35^level` per building level while the haul
compounds at `1.5^realm level` across far fewer levels.

Three possible readings, and they lead to different games:

1. **`B(L)`'s base or growth rate is wrong.** Raising the base ~5× would restore
   the stated share — but §9.6 explicitly warns the growth rate is "the master
   inflation lever… locked first and moved rarely", so this needs care, and it
   depends on resolving C4 (what `L` even is).
2. **Raiding is a *page* faucet, not a resource faucet.** This is consistent with
   §7.6 ("pages are the reason to raid"), §12.1's reward table (which lists pages
   first), and review 10's finding (§30.15). If so, §9.4 and §12.1's resource
   claims are simply stale and should be deleted.
3. **Both.** Raids fund pages primarily and resources secondarily, at a stated,
   smaller share — say 10–15%.

Reading 2 is probably what the design now believes.

**The economy model measures the gap exactly.** Running the same simulated
engaged player under each payout model:

| Day | Production/day | §9.4 "share" | §9.6 minted | §9.4 share of income | §9.6 share |
| --- | --- | --- | --- | --- | --- |
| 31 | 17,773 | 8,531 | 330 | **32%** | **2%** |
| 91 | 59,154 | 28,394 | 742 | 32% | 1% |
| 181 | 79,932 | 38,367 | 1,113 | 32% | 2% |
| 301 | 132,642 | 63,668 | 1,670 | 32% | 2% |

§9.4's model reproduces its own stated target exactly — "roughly a third" — which
is strong evidence it is what generated the published tables. §9.6's replaces it
with 1–2%, a **16- to 30-fold** reduction, and nothing else in the document was
updated to match.

See F3 below for the consequence: with raiding returning 1–2% and costing 2%,
the loop §11.6 describes does not exist in the numbers at all.

Reproduce with `python3 -m tools.economy_model faucet`.

---

## F1. The roster cannot staff the universe the rules permit

**The most structural finding in the analysis.** It is pure arithmetic from three
published tables and needs no simulation.

At a finished universe (7 realms, everything at maximum):

| Positions to fill | Count | Source |
| --- | --- | --- |
| Producer worker slots | **126** | 7 realms × 2 of each producer (§5.2) × 3 kinds × 3 slots at level 7+ (§10.2) |
| Guard posts | 21 | 3 per outer realm at realm level 5 (§5.2) |
| Heist crew | 5 | §12.5, from Keeper level 16 |
| **Total** | **152** | |
| **Roster ceiling** | **38** | 3 at the Spire + 7 Hearths × 5 homes (§11.5, §10.2) |
| **Coverage** | **25%** | the roster would have to be **4× larger** |

Even production alone, and even at *one* producer per realm, outruns the roster:
63 worker slots against 38 characters, **before a single guard is posted**.

§11.5 says the roster is "around 30 at the most at launch", so this is not an
oversight in one table — the two halves were simply sized independently.

**This is not automatically wrong.** §4 names "characters' time" as one of the
game's two scarce resources, so a roster that cannot fill every post may be the
intent. But three things follow that the document has not absorbed:

1. **§9.3's production figures are unstaffable.** They require ~63 fully staffed
   worker slots; the roster caps out at 38, and guards come out of the same pool.
   A player who defends at all produces materially less than §14 says they will.
2. **The choice is not interesting at this ratio.** A 25% coverage rate is not
   "an interesting allocation puzzle", it is "most of your buildings are idle
   most of the time" — which reads as broken rather than as scarce.
3. **Building more producers stops being a decision.** If you can only staff a
   quarter of them, the marginal Star Well is worthless, and a large part of the
   Starlight sink in §10.2 evaporates.

### Two things that make this sharper

**No second or third worker slot is ever worth filling.** §9.2's staffing curve
is 60% / 85% / 100% for one, two and three workers — marginal gains of +60, +25
and +15 points. Decreasing, so a player fills every building's *first* slot
before any second. Take the 21 guard posts §5.2 allows and a crew of five out of
a roster of 38, and **12 characters are left to work**. They cannot fill even the
first slot of 21 buildings, let alone reach a second. §10.2 grants a second slot
at building level 4 and a third at level 7: **both are dead content**, while
§14.3 lists "every Star Well at level 10" (day 316) and "everything built and at
its highest level" (day 378) as milestones.

**A second, independent cap agrees with the first.** §9.5 prices a new ruleborn
at `100 × 1.15^owned` Essence:

| nth ruleborn | Essence |
| --- | --- |
| 30 | 6,621 |
| 38 | 20,254 |
| 50 | 108,366 |
| 89 | 25,241,072 |

The 89th — the roster one producer per realm would need — costs about **200 days
of an engaged player's entire Essence production**. So the Hearth homes and the
birth curve cap the roster in the same place, independently. Both halves of the
character economy say 30–40. The building rules ask for 152.

**Recommendation:** decide which lever moves — raise the roster (which means
changing *both* caps), cut the buildings, or keep the shortage and recompute
§9.3 at the staffing a player can actually reach. It is a design choice, not
arithmetic. What is not a choice is leaving all three tables as they are.

Reproduce with `python3 tools/decision_support.py staffing`.

---

## F2. The published progression tables assume one producer per realm, not two

§5.2 permits a second Star Well, Aether Spring and Garden per realm from realm
level 3. §9.3's production figures do not reflect that.

Solving backwards from §9.3's day-301 figure (256,100 Starlight/day = 10,671 per
hour), with the law and band bonuses the document assumes, implies **about seven
fully staffed Star Wells at level 9** — one per realm. Not the fourteen §5.2
allows. The same holds at days 91 and 181.

Running the model under all four readings confirms it:

| Reading | Day 301 as % of published | Keeper 40 |
| --- | --- | --- |
| 2 producers/realm, roster cap applied | 52% | day 249 |
| 2 producers/realm, no roster cap | 233% | day 107 |
| 1 producer/realm, roster cap applied | 59% | day 226 |
| **1 producer/realm, no roster cap** | **117%** | **day 171** (published: 181) |

Only the last reading tracks the document, and it is the one the build rules do
*not* describe.

**Consequence:** a player who builds the second producer — which is a pure
production gain, so everyone will — earns roughly **twice** what §14 predicts.
Every "engaged player reaches this on day X" milestone in §14.2 and §14.3 would
be optimistic by a wide margin, and the pacing gate in §14.3 ("each Spire level
arrives within a few days of the Keeper level that allows it") would not hold.

**Recommendation:** re-run the economy model against the rules as written and
republish §10.2, §14.2 and §14.3 from it. Then decide whether the second
producer should exist at all — given F1, it may be exactly the wrong thing to
add.

---

## F3. Raiding barely costs any production, so the core trade-off does not bind

§11.6 calls this "the core trade-off" and §4 builds the whole design on it:

> A character on a heist isn't working or guarding. Raiding more means earning
> less at home and defending worse.

In the document's own numbers, it does not. A heist is 3 minutes (§12.6) and a
clean escape rests the crew 45 minutes (§11.6, §12.9), so each raider is away
~0.8 hours per heist:

| Archetype | Roster | Crew | Heists/day | Characters withheld | % of roster |
| --- | --- | --- | --- | --- | --- |
| Engaged | 31 | 5 | 4 | 0.67 | **2.2%** |
| Regular | 31 | 5 | 2 | 0.33 | 1.1% |
| Casual | 27 | 5 | 1 | 0.17 | 0.6% |

A crew of five raiding four times a day is unavailable for 16 character-hours out
of 744. The stated trade-off is worth about **2% of production**.

Taken together with §2 above, the loop the design describes — raid hard, earn
less at home, raid harder — is not present in the numbers at all: raiding costs
2% of production and (under §9.6) returns 1–2%.

**Note the interaction with F1.** The trade-off could be made real without
touching rest times, by making it about *allocation* rather than *time*: if
there are 152 posts and 38 characters, then a crew of five is 13% of the roster
permanently committed, and that is a genuine decision. The document has the
right intuition and the wrong mechanism — the scarcity it needs is already
there in F1, it is just not connected to raiding.

**Recommendation:** either lengthen rest substantially (which §12.14's
"temporary failure" principle argues against), or make crew membership an
assignment that excludes work, the way guarding does. The second is closer to
what §11.6 already claims.

Reproduce with `python3 -m tools.economy_model raiding`.

---

## F4. §12.8's knockout rule is true for three of twenty-five role pairings

One sentence in §12.8 is the only statement anywhere about how a fight ends:

> Two ambush hits knock out a guard of equal level.

There is exactly one cadence in the document — §12.8's own 0.8-second wind-up —
so the reading is one hit per 0.8 s for damage equal to Power (§11.1). Hits to
drop an equal-level guard, the first an ambush at triple damage:

| raider ↓ / guard → | Scout | Breaker | Carrier | Warden | Mender |
| --- | --- | --- | --- | --- | --- |
| **Scout** | 8 | 13 | 12 | 33 | 9 |
| **Breaker** | 1 | 3 | 2 | 9 | 2 |
| **Carrier** | 13 | 21 | 18 | 51 | 15 |
| **Warden** | 4 | 7 | 6 | 19 | 5 |
| **Mender** | 18 | 28 | 25 | 68 | 20 |

A Mender attacking a Warden needs 68 hits — **54 seconds**, against a guard the
ambush stunned for two, and 30% of a three-minute heist (§11.6). The rule holds
for three pairings read as ambush-then-strike and five read as two simultaneous
ambushes; four of those five need a Breaker.

The cause is a ratio. Two hits drop a target only if `Power = Health ÷ 4`:

| Role | Power / Health | Short by |
| --- | --- | --- |
| Scout | 12 / 120 = 0.100 | 2.5× |
| Breaker | 40 / 180 = 0.222 | 1.1× |
| Carrier | 8 / 160 = 0.050 | 5.0× |
| Warden | 20 / 420 = 0.048 | 5.2× |
| Mender | 6 / 130 = 0.046 | 5.4× |

**This is the same shape as C2 and F1.** Power and Health were set for standing
fights and home defence, where a Warden *should* take a long time to drop, and
the ambush rule was written against them later without anyone multiplying the
numbers together.

**Recommendation:** give the ambush a floor — triple Power *or* half the target's
maximum health, whichever is greater. Two ambushers then drop any equal-level
guard in all 25 pairings, which is the stated rule made true by construction,
while the Breaker's one-shot on a Scout survives because the triple-Power term
still wins there. Re-tuning Power or Health instead would move home defence and
every guard duel with it. Drafted in `docs/design/spec/fights.md`.

Reproduce with `python3 tools/decision_support.py combat`.

---

## F5. The Vault's loading phase lasts two seconds, and 46% of crew capacity is unreachable

§12.6 budgets the Vault phase at "about 30 s" and names its decisions as "who
cracks, who loads, **when to stop loading**". Its own numbers:

| | As written |
| --- | --- |
| Crew carry capacity (§11.1, one of each role) | 560 loot |
| Reachable capacity | **300** — only Carriers load, and only into themselves |
| Time to fill a Carrier at 150/s | **2.0 s** |
| Decisions available in those 2 seconds | none |

So 260 of 560 units cannot be filled by any means the document describes, and the
sub-phase it calls its central decision has one option. The thirty seconds is
cracking, and cracking is a progress bar.

### The one place the document's numbers corroborate each other

The same arithmetic produced the opposite result for cracking. Vault health is
1,500 per level (§12.6); the crew deals 126 damage per volley at level 1 (§11.1,
Breaker doubled) at one volley per 0.8 s (§12.8):

| Crew level | Vault level | Health | Time | Awareness added |
| --- | --- | --- | --- | --- |
| 1 | 1 | 1,500 | 9.5 s | 19% |
| 8 | 4 | 6,000 | 22.2 s | 44% |
| 12 | 6 | 9,000 | 24.5 s | **49%** |
| 25 | 10 | 15,000 | 15.0 s | 30% |

Ten to twenty-five seconds across the whole game, against a phase length written
in a different section from Vault health, which was written in a different
section again from role Power. **They agree.** That is the strongest available
evidence that one hit per 0.8 s for Power damage is the combat model §12.8's
wind-up was written for — and it is why `spec/fights.md` adopts it rather than
inventing one.

**Recommendation:** let every role load, at a rate scaling with Carry, so the
crew fills in ten seconds — one decision by §12.6's own 8–12 second cadence — and
restore §9.4's `capped by the crew's carrying capacity` as a fill fraction on the
payout formula. Drafted in `docs/design/spec/vault.md`, which also finds that the
stop-or-continue breakeven sits at exactly 70% full: §12.9's Loud multiplier,
with everything else cancelling.

Reproduce with `python3 tools/decision_support.py vault`.

---

## 3. The note economy is imbalanced on its most important axis

Parsed from all 48 law sheets:

| Note | Laws carrying it | Opposite | Opposite's count | Ratio |
| --- | --- | --- | --- | --- |
| **Glow** | **12** | Hush | **6** | **2.0 : 1** |
| Flow | 11 | Weight | 9 | 1.2 : 1 |
| Echo | 10 | Veil | 7 | 1.4 : 1 |
| Spark | 8 | Bloom | 8 | 1.0 : 1 |

Total note-slots: 71 across 48 laws (23 laws carry two notes, 25 carry one).

**Why the Glow/Hush imbalance matters more than the others.** Hush is the *hiding*
note — the raider-favouring one. Glow is the *revealing* note. Laws are woven by
the defender and apply symmetrically (§7.1), so:

- Defenders have every incentive to weave Glow and none to weave Hush.
- Hush is also the scarcest note, so a defender who *wants* the Hush harmony
  (hiding works 1 tile closer to guards — a raider benefit) has only six laws to
  choose from, four of which are Rare or Deep.
- **Five of the twelve chords require Hush** (Deep sleep, Ghost tide, Wild hunt,
  Hidden garden, Quicksand), so the chord that a player can most easily build is
  systematically the wrong half of the wheel.

The six Hush laws, for reference:

| Law | School | Rank | Notes |
| --- | --- | --- | --- |
| Stillness | Time | Common | Hush |
| Glowing dark | Energy | Common | Hush |
| Held breath | Time | Deep | Hush, Weight |
| Spores | Life | Rare | Hush, Weight |
| Sleepwalk | Spirit | Rare | Hush, Echo |
| Borrowed Face | Spirit | Deep | Veil, Hush |

**Recommendation:** rebalance toward roughly 8–9 laws per note before the law data
table is authored. Since notes are frozen at eight and laws are the expansion axis
(§24), this is a one-time cost now and a recurring constraint later — every future
season's six laws must be note-balanced too.

---

## 4. All twelve chords are reachable with two laws, not three

§8.5 describes a chord as "three different notes, none of them opposites, carried
by laws in the same realm" and calls it "the late-game discovery: they need three
laws in play and a Lab of level 3 to identify".

Because 23 of the 48 laws carry two notes, **every chord is reachable with two
laws**, and several with two commons:

| Chord | Notes | Cheapest two-law combination | Total stability |
| --- | --- | --- | --- |
| Rebound | Flow + Echo + Spark | Bounce + Brittle stone | 24 |
| Tempest | Flow + Spark + Glow | Leapfrog + Brittle stone | 25 |
| Iron bell | Weight + Echo + Glow | Slow rivers + Whispers | 26 |
| Ghost tide | Flow + Echo + Hush | Bounce + Glowing dark | 27 |
| Mirage | Flow + Veil + Glow | Tilt + Afterimage | 27 |
| Fair lights | Glow + Bloom + Veil | Afterimage + Bloom | 27 |
| Lantern festival | Glow + Bloom + Echo | Bloom + Whispers | 27 |
| Deep sleep | Weight + Hush + Bloom | Glowing dark + Thorns | 28 |
| Clockwork | Weight + Spark + Echo | Brittle stone + Lodestones | 28 |
| Wild hunt | Flow + Spark + Hush | Haste + Glowing dark | 31 |
| Quicksand | Weight + Veil + Hush | Slow rivers + Borrowed Face | 31 |
| Hidden garden | Bloom + Hush + Veil | Bloom + Borrowed Face | 32 |

Slow rivers + Whispers at 26 stability is inside a *day-2* player's capacity
(51, §5.5). Realms get their second law slot at realm level 3, so chords become
mechanically available far earlier than the design intends — and with two crown
laws plus a constellation Grand Law in play, a level-3 realm can hold four laws
and will trip chords more or less by accident.

**Recommendation:** pick one.
- Require three *distinct laws* rather than three notes (clean, matches the prose,
  a one-line rule change); or
- Keep two-law chords and reposition them as a mid-game discovery, dropping the
  Lab level 3 gate; or
- Reduce two-note laws, which also helps the note imbalance in §3 above.

The first is the smallest change and preserves the stated design intent.

---

## 5. Law cost does not separate cleanly by rank

| Rank | Count | Stability cost range | Mean |
| --- | --- | --- | --- |
| Common | 18 | 10 – 19 | 13.6 |
| Rare | 18 | 14 – 20 | 17.0 |
| Deep | 12 | 16 – 26 | 21.9 |

The ranges overlap substantially. Haunting is a *common* law at cost 19, more
expensive than **15 of the 18 rares** and than the cheapest deep (Regrowth, 16).
Nine of the eighteen commons cost 14 or more — at or above the cheapest rare
(Delay, 14).

This is not necessarily wrong — §7.10 argues explicitly that rarity should set
*acquisition time* while stability cost sets *strength*, so decoupling is the
intent. But it means **stability cost is doing all the balancing work, and the
overlap should be deliberate rather than incidental.** Worth a pass once the
rank taxonomy is settled (C3): check that each law's cost reflects its measured
effect on defence hold rate, using the layer-attribution method in §13.4.

---

## 6. Build-effort estimate vs calendar

§26.8 estimates the build at 210–360 Claude Code runs, point estimate ~270, at
"two to four hours of focused human work" per run:

- 270 runs × 3 h ≈ **810 hours** ≈ 20 weeks of full-time solo work
- §26.2's phases 2–5 (vertical slice through soft launch) total **42–48 weeks**

So the coding estimate fits inside the calendar with room — *until* you add what
§26.8 explicitly excludes: "**finding the fun.** The roadmap costs building the
stealth model and the law system, not iterating until they are enjoyable. That
iteration is unbudgeted and could be large."

For a novel genre-blend with no reference implementation, iteration is normally
the *majority* of the work, not a remainder. The document's own §19.17 lists nine
A/B experiments in the fun backlog, each requiring a playable build, a cohort and
a tuning pass.

**Recommendation:** budget iteration explicitly at 1–1.5× the build estimate
(another 200–400 runs), and treat the resulting total as the reference-class
figure §26.5 asks for. Then apply §26.5's own advice — "scope is the lever" — to
§26.1's launch content table. See `06-build-readiness.md`.

---

## 7. Launch content scope, counted

| Content | Launch count | Notes |
| --- | --- | --- |
| Laws | 48 | × 3 tiers = 144 parameter sets |
| Signature resonances | 44 | hand-designed pairs |
| Chords | 12 | |
| Paradoxes | 3 | |
| Terrain features | 39 | ~80 meshes with realm variants (§21.9) |
| Ruleborn | 18 | × 8 forms = **144 visual variants** |
| Traits | 30–31 | see C10 |
| Sages | 4 | × 3 powers each |
| Buildings | 16 types | 10 levels for several = ~100 level definitions |
| Wards | 6 types × 5 levels | only level 1 specified (G3) |
| Realm kits | 7 | |
| Eras | 8 | |
| Screens | 23 or 27 | see C11 |
| Languages | 12 | vs §20.6's "English and Portuguese at launch" |
| Interface icons | ~220 | |
| Audio | 7 ambiences + 6 stingers + ~150 effects + 8 tracks | |

**The 144 forms are the hidden art multiplier.** §21.9's asset list counts
"Characters: ruleborn 18" — but §11.10 specifies eight visual forms per kind
("streaming fins and swept feathers" vs "stone plates and a stocky stance" vs
"leaves, petals and moss"). Whether that is 18 models with 8 material/accessory
sets or 144 distinct models is the difference between a few weeks of contractor
time and a year of it, and the document does not say which.

---

## 8. Balance targets that are consistent with each other

Worth recording, because they form a coherent set and can be used as acceptance
criteria directly:

- Defences hold 30–45%, raids succeed 55–70% (§13.2) — §9.6's payout model assumes
  37.5% hold, dead centre ✓
- Successful raids split ~35% clean / 40% loud / 25% partial, giving an attempt
  worth 46% of a clean haul (§9.6) ✓ arithmetic confirmed
- No single defence layer above 25%, ~60% of strength from design rather than
  level (§13.2) — with a real measurement method in §13.4 (32 layer combinations,
  400 raids each ≈ 12,800 runs) ✓
- Heist success ~80% falling to 55–65% after a month (§14.5) ✓ consistent with
  §13.2's band
- ~1,600 raids per version to detect a five-point hold-rate shift (§13.4) ✓ the
  right order of magnitude for that effect size

This cluster is the most rigorous balance specification in the document and
should be preserved intact through any reconciliation.
