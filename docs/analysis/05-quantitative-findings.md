# Quantitative findings

Arithmetic and content-distribution analysis of design document v2.3. Everything
here is reproducible with `tools/check_design_consistency.py`.

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

Reading 2 is probably what the design now believes. But it has a consequence the
document has not absorbed: **if raiding supplies ~3% of resources, the "nothing is
wasted / raiding more means earning less at home" trade-off in §11.6 resolves
almost entirely in favour of staying home.** A character on a heist forgoes
production worth more than the heist returns. That is a live balance problem for
the game's central tension, and it is invisible until these two sections are read
against each other.

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
