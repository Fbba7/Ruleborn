# Contradiction register

Seventeen confirmed internal contradictions in design document v2.3, ordered by
how much they block work. Each names the conflicting sections, what the conflict
actually is, and a recommended resolution.

The six that can be checked mechanically are asserted in
`tools/check_design_consistency.py`, so they can be re-verified against a later
version of the document.

**The pattern behind most of these:** a system was specified early, then
re-specified later and better by a commissioned review (§30), and the later spec
was added without retiring the earlier one. The document reads consistently
front-to-back because the newer sections don't contradict their neighbours — only
their ancestors.

---

## Blocking — these prevent content authoring or core code

### C1. Two incompatible detection models
**§12.8 vs §12.17** (and §5.4, §29.1 carry the older one)

| | §12.8 (older) | §12.17 (newer, from review 11) |
| --- | --- | --- |
| Vision | one 120° cone, 6 tiles (8 Scout) | 30–45° cone, three range zones, plus 60–110° peripheral |
| Notice | awareness fills 50%/s in sight, 75%/s within 3 tiles | suspicion 0–1000; near zone ≈0.5 s, mid ≈1 s, far ≈3 s |
| Threshold | investigate 50%, alarm 100% | Suspicious 200, Investigating 600, Alerted 1000 |
| States | 2 | 6 (+ Searching, Returning) |
| Noise | "noise raises awareness of guards nearby" | travels along the walkable path, per-action distances |

§12.17 explicitly presents itself as the fix ("the most important system in the
game, and until now the least specified"), but §12.8 is left intact, §5.4's
landing rule is written in the old percentage model, and **§29.1, the formulas
appendix, encodes the old model**.

**Recommendation:** §12.17 is authoritative. Rewrite §12.8 as behavioural
descriptions only (what each guard role *does*), restate §5.4's landing noise in
suspicion units, and regenerate §29.1 from §12.17. Nothing in the detection model
should have two homes.

---

### C2. Two incompatible raid-payout models
**§9.4 + §12.9 vs §9.6**

§9.4 pays a percentage of what the defender holds ("up to 25% of the Vault's
exposed amount and 50% of each Storehouse passed, capped by the crew's carrying
capacity, plus a 10% bonus"). §9.6 explicitly replaces this with a minted haul
driven by the raider's own level:

```
Haul = B(L) × grade × difficulty × richness × fatigue,   B(L) = 100 × 1.5^(L−1)
```

and states that its grade term "supersedes the older outcome multipliers in
12.9". But §9.4's percentages and §12.9's multipliers remain, and the two produce
different numbers. They also imply different *systems*: §9.4's loot is bounded by
Carrier capacity (300 each, loading 150/s), which is a moment-to-moment gameplay
constraint; §9.6's is a closed-form payout that carrying capacity never touches.

**Worse, the two disagree about how big the loop is.** See `05-quantitative-findings.md` §2:
under §9.6, six raids a day yield **3–8%** of an engaged player's daily income,
against the "about a fifth of a day's production" per heist in §9.4 and the "40%
of mid-game growth" in §12.1.

**Recommendation:** §9.6 is the better-reasoned model and should be
authoritative — minting from the raider's level is the right answer when loot is
created rather than transferred. But then:
- Delete §9.4's percentages and §12.9's loot column.
- Decide what Carrier capacity and the 150/s load rate now *mean* — probably a
  time-pressure device (how long you must stand at the Vault) rather than a cap
  on value. Say so.
- Rewrite §9.4's balance target and §12.1's "40% of mid-game growth" to match
  reality, or raise B(L)'s growth rate — and note §9.6's own warning that the
  growth rate "is locked first and moved rarely".
- Resolve which level `L` refers to (see C4).

---

### C3. Two law-rarity taxonomies; one of them has no laws in it
**§7.4 + §7.7 + §9.5 + §14.4 + glossary vs §7.10 + §27.2**

- **What is authored** (§7.4, §7.7): three ranks, three common / three rare / two
  deep per school = **18 Common, 18 Rare, 12 Deep**. Verified by parsing all 48
  law sheets. Pages to restore: 15 / 30 / 60 (§7.6, §9.5). §14.4's
  1,485-page total is computed from exactly this split. The glossary says
  "common, rare or deep".
- **What is described** (§7.10, §27.2 "Five ranks"): five ranks —
  **18 Common, 14 Uncommon, 10 Rare, 6 Deep, 3 Paradox** — with pages
  10 / 20 / 35 / 60 / 120.

**No law anywhere in the document is tagged Uncommon.** The five-rank system
exists only as prose, and the two totals differ (1,485 vs 1,140 pages to restore
the collection), which moves the whole late-game pacing curve.

**Recommendation:** §7.10's *reasoning* is the valuable part — rarity should buy
specificity, not strength, and collections read as completable at 7–12 items, not
48. Both survive under either taxonomy. Decide the split, then **regenerate §7.4,
§7.7, §7.6, §9.5, §14.4 and the glossary from one table.** If the five-rank split
is chosen, 14 laws need re-tagging and the page economy in §14.4 needs re-deriving.

---

### C4. Realm levels 1–5 or 1–10?
**§5.2 vs §9.6 + §13.4**

§5.2's outer-realm table stops at **level 5** (grid 14×14, 3 law slots, Spire 9).
§9.6's haul table quotes realm levels **2, 6 and 10**, and its sealed-share text
says "40% at realm level 1 and rises by 3.5 points a level to 71.5% at level 10".
§13.4's defence budget table also uses realm levels 1, 5 and 10.

§9.4 attributes the same 40%→71.5% sealed share to the **Vault**, which does have
ten levels (§10.2). So §9.6 appears to have conflated Vault level with realm
level — and then built the master inflation dial `B(L)` on top of the conflation.

**This is the most consequential single error in the document**, because `B(L)`
is described as "the master inflation lever" and `1.5^(L−1)` at L=10 is 25× its
value at L=5.

**Recommendation:** decide what `L` is. If realms cap at 5, `B(5) ≈ 506` and the
whole payout table is wrong by ~7×. If realms should go to 10, §5.2 needs five
more rows and the Spire-level gating chain re-derived. Most likely `L` should be
Vault level, or a composite "target strength" — but it has to be stated.

---

### C5. Two defence budget systems
**§5.2 + §5.5 vs §13.4**

| | §5.2 / §5.5 | §13.4 |
| --- | --- | --- |
| Stability | one universe-wide pool from Spire + Anchor Stones | a **per-realm** "pool" of 100 / 336 / 1,504 |
| Law cost | 10–26 base, modified | flat 30 / 34 / 40 |
| Law slots at realm level 1 | 1 | 1 ✓ |
| Wards at realm level 1 | limit 4 | 2 |
| Guard posts at realm level 1 | 1 | 3 guards |
| Wards per realm (§13 intro) | "three to seven" | 2–9 |

Three different ward budgets and two different guard budgets appear in the
document, and §13.4 introduces a second currency called "stability" that is not
the §5.5 one.

**Recommendation:** §13.4's *mechanism* is right — slot limits per layer are what
enforce the "no layer above a quarter" rule, and cost alone cannot. Keep the
limits, drop the second stability pool, and price the layers in Starlight/Aether
or in a clearly-named new budget ("defence points", parallel to terrain points).
Then reconcile the ward and guard numbers to one table in §5.2.

---

### C6. Two ruleborn rosters
**§11.2 vs §11.11**

The same 18 creatures are specified twice. Three have different **roles**:

| Ruleborn | §11.2 | §11.11 |
| --- | --- | --- |
| Prism Mite | Carrier | Scout |
| Stormhound | Scout | Carrier |
| Rootrunner | Carrier | Scout |

This changes the role distribution (§11.2: 3 Scout / 4 Carrier; §11.11: 4 Scout /
3 Carrier) and therefore crew composition, guard behaviour (§12.8 keys guard
behaviour off role) and the Nursery's "roles the player has fewest of are twice as
likely" rule (§11.5).

Most of the other fifteen also disagree on ability, cooldown or resistance. Examples:

| Ruleborn | §11.2 | §11.11 |
| --- | --- | --- |
| Featherkin | Glide over one gap or wall, 12 s | Glide 3 tiles ignoring one height level, 14 s |
| Rambler | Charge 5 tiles, 14 s | Charge 4 tiles, 16 s |
| Prism Mite | Split, each carries half, 5 s / 15 s | Split into half-health copies, 10 s / 22 s |
| Hourkeeper | Return ally to health of 5 s ago, 16 s | Rewind ally 3 s, 24 s |
| Stillwatch | Freeze guard 2 s, 12 s | Freeze guard 2.5 s, 18 s |
| Stormhound | Sprint +60% for 4 s, 12 s | Sprint +40% for 5 s, 18 s |
| Mossbear | Root, heal 20% over 4 s, 16 s | Root, take 50% less damage for 6 s, 20 s |
| Rootrunner | Root bridge; ignores **Spores** | Root bridge; ignores **Heavy ground** |
| Echoplate | Returns once at **50%** | Returns once at **40%** |

**Recommendation:** §11.11 is the richer spec (it adds proportions, personality,
idle habit, sound) and reads as the later one. Make it authoritative, reduce
§11.2 to a one-line index, and **generate both from a single creature data table** —
this is exactly the content that should live in the server-side data tables
described in §24.

---

## Significant — these will cause balance or build errors

### C7. Tick rate: 20 Hz or 30 Hz?
**§7.3 + §24 (engine table) say 20 · §24.10 says 30**

§24.10 is the later "simulation contract" from review 11 and is self-consistent
(it states a heist is 4,500–7,200 ticks, which is exactly 30 × 150–240 s). §7.3
and §24's summary table both say "fixed 20 steps a second". §24.10 also says
"if a cheap phone cannot hold it, drop to 20", so 20 may be a leftover or a
pre-emptive fallback.

**Recommendation:** 30 Hz per §24.10; fix §7.3 and §24. Note this changes every
duration expressed in ticks and must be settled *before* the golden replays are
written, since they encode it.

### C8. The Library is referenced four times and specified nowhere
**§7.6, §12.1, §27.2, §30.15 vs §10.2**

"A Library at the Heart produces about one page per realm every few hours" is
load-bearing — it is the mitigation for the "raiding is the only page source"
problem that review 10 identified as punishing the building half of the audience.
But the Library is **not among the 16 building types** in §10.2, has no cost, no
levels, and no placement rule. §26.1 confirms 16 building types at launch.

**Recommendation:** add it as a 17th building with a full level table, or fold
the trickle into an existing building (the Observatory or the Spire) and rewrite
the four references. Do not leave a load-bearing economic faucet unspecified.

### C9. Codex shows 36 laws or 48?
**§23.2 vs §7, §26.1**

The Law Codex screen spec says "36 laws by school and rank". The collection is 48.
36 is the size of Codex chapter 3 (§7.6), so this is probably a stale number.

### C10. Trait count
**§11.3 lists 31 · §26.1 says 30 at launch · §17.3 adds a 32nd**

§11.3 enumerates 31 traits (6 body, 5 heist, 11 law-linked, 9 home). §26.1's
launch content table says 30. §17.3 references "the rare Starborn trait", which
appears in no list.

### C11. Screen count
**§23.2 lists 27 · §21.9 says 23**

### C12. Business case commission rate
**§22.2 high scenario vs §22.5**

§22.5 says "every revenue figure in 22.2 assumes 15%". The low and base scenarios
do (verified: €2,720 and €25,500). The high scenario's €168,000 is computed at
**30%** — which is arguably *correct*, since €204,000/month crosses Apple's $1M
small-business threshold, but it contradicts the stated assumption and makes the
three scenarios non-comparable.

**Recommendation:** keep the 30% figure, and add a footnote explaining the
threshold crossing. Also note the discontinuity is a real business fact worth
surfacing: revenue between roughly €70k and €85k/month is partly a dead zone.

### C13. Matchmaking cannot reach its own worst difficulty tier
**§12.3 vs §9.6**

§12.3 offers targets "within 3 Keeper levels". §9.6's difficulty multiplier has a
tier for targets "three or more below" paying 0.25×. If the Observatory never
offers such targets, that tier is unreachable through normal play.

**Recommendation:** harmless but confusing — either widen the offered band, or
state that the 0.25 tier exists only for challenge links, friendly heists and
Trace targets.

### C14. Renown for a foiled heist
**§12.9**

The outcomes table gives Renown as a percentage (100% / 80% / 50% / −50%) while
the formula below it produces an absolute value (8–40). "−50%" of a gain the
raider did not make is undefined.

**Recommendation:** express all four outcomes as multipliers on the formula's
output, and state the sign convention explicitly.

---

## Minor — tidy before the spec is frozen

### C15. Guard vision numbers in two units
§12.8 uses tiles, §12.17 uses metres. §21.1 establishes 1 tile = 1 metre, so they
are reconcilable — but the document should pick one unit and use it everywhere.

### C16. "Three-minute heist" vs the clock
§12's opening calls a heist "a three-minute run"; the clock is 150–240 s (§5.4),
and §12.2 correctly says 2.5–4 minutes. §14.1's player model assumes 3 minutes.
Harmless, but the marketing line and the spec should not disagree.

### C17. Fallback names for the game
§27.2 says "Fallbacks are Lawkeep and Ruleborn" — but Ruleborn *is* the chosen
name. Almost certainly a leftover from the v2.2 rename.

---

## Summary table

| # | System | Sections | Blocks |
| --- | --- | --- | --- |
| C1 | Detection model | 12.8 / 12.17 / 5.4 / 29.1 | Guard AI, balance, HUD |
| C2 | Raid payout | 9.4 / 12.9 / 9.6 / 12.1 | Economy, the core loop's stated purpose |
| C3 | Law rarity | 7.4 / 7.7 / 7.10 / 9.5 / 14.4 / 27.2 | Content authoring, page economy |
| C4 | Realm level range | 5.2 / 9.6 / 13.4 | The master inflation dial |
| C5 | Defence budgets | 5.2 / 5.5 / 13 / 13.4 | Island builder, defence balance |
| C6 | Ruleborn roster | 11.2 / 11.11 | Content authoring, crew and guard behaviour |
| C7 | Tick rate | 7.3 / 24 / 24.10 | Golden replays, every duration |
| C8 | The Library | 7.6 / 10.2 / 26.1 | Page economy for non-raiders |
| C9 | Codex size | 23.2 | Screen spec |
| C10 | Trait count | 11.3 / 17.3 / 26.1 | Content table |
| C11 | Screen count | 21.9 / 23.2 | Art scope |
| C12 | Commission rate | 22.2 / 22.5 | Business model comparability |
| C13 | Difficulty tier reachability | 12.3 / 9.6 | Payout tuning |
| C14 | Foiled-heist Renown | 12.9 | League maths |
| C15 | Tiles vs metres | 12.8 / 12.17 / 21.1 | Spec clarity |
| C16 | Heist length | 12 / 12.2 / 5.4 | Copy |
| C17 | Name fallbacks | 27.2 | Copy |
