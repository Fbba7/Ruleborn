# Recommended next steps

Ordered. Everything in stage 0 and 1 costs essentially nothing and can start
immediately; nothing after stage 2 should start before it.

---

## Stage 0 — the two gates, re-planned for a solo developer

§26.7 puts two tests before any code, and both are right. But as written they
assume **about thirty people in a room**: eight to twelve for the paper heist
(§19.27), fifteen to twenty for the build-willingness test (§13.3). That cohort
does not exist for this project, so the *method* has to change even though the
*questions* do not.

### What each gate actually asks

| Gate | Question | Why it cannot be skipped |
| --- | --- | --- |
| Paper heist (§19.27) | Does a no-loss, delegated-control stealth heist feel tense? | The premise the whole game rests on. No published research covers it (§30.8) |
| Build willingness (§13.3) | Will players design a second island unprompted? | Ranked risk #1. §26.7 calls it "the single decision that changes the most" |

### The re-plan: a link is recruitable, a room is not

Replace the paper prototype with a **single-file browser prototype** — one
8×8 realm, two or three laws, a crew of three, a guard on a patrol, a vault and
a clock. No Godot, no Rust, no determinism work, no art. It exists only to be
sent to strangers as a URL.

This costs a handful of working sessions, which the paper test was designed to
avoid — but it buys three things the paper test cannot:

- **Recruitment becomes possible.** A link can go to a hobbyist community, a
  subreddit, a Discord, or a paid panel. §25.5 already budgets for panels
  ("a per-session fee; an indie tier exists for small studios"), so the document
  has costed this route.
- **It answers the harder question too.** §30.7 premise 3 — whether a delegated
  crew feels like *playing* or *watching* — cannot be tested on a board where a
  human moves the pieces. It is the failure mode most likely to sink the design
  (`06-build-readiness.md` adds it as an unranked risk ~4) and the system that
  decides it is the largest specification gap (G1).
- **It doubles as gate 2.** Add a build mode to the same page — place three
  terrain features, one guard, one law — and the build-willingness test runs
  asynchronously: build, watch a raid against what you built, then be told you
  may stop. Whether a second island gets built unprompted is logged, not asked.

### Sample sizes that are actually reachable

The document's own guidance already points here. §25.4 asks for "three rounds of
5 to 8 testers, not one round of five", and §25.5 notes in-app surveys average
~13% response. So:

| | Target | Source |
| --- | --- | --- |
| Usability and felt control | 3 rounds × 5–8 | §25.4 |
| Tension and play-again rate | 15–30 sessions via link | behavioural, not opinion |
| Build willingness | 15–20 completions | §13.3's own threshold needs this to separate 15% from 30% |

**Honest limit, stated in the document already (§19.27):** "a sample of ten to
twenty can show a large effect but not measure a small one". These gates are
looking for large effects — "does anyone come back", "does anyone build twice" —
so small samples are adequate. They are not adequate for tuning.

### Thresholds, unchanged

- **Paper/browser heist:** median tension ≥ 3/4, median enjoyment ≥ 6/10, and
  **≥60% choose to play again** — the only behavioural measure, and the one that
  matters.
- **Build willingness:** ≥30% build a second island → authorship as designed;
  15–30% → authorship with heavy scaffolding; <15% → pivot to generated islands
  the player curates (§13.3). The pivot is not a lesser game.

### Status: built

The prototype is written and published at
**https://claude.ai/artifact/3jW7Zg1rTrzR6CF3cEVp2E**
(`prototypes/heist-gate/`), with `tools/parse_gate_results.py` to score the
codes testers send back against the thresholds above. What remains is
recruitment: 15-30 sessions for gate 1, 15-20 completed builds for gate 2.

### What this changes about the order of work

The browser prototype moves onto the critical path, ahead of the determinism
spike. That is a deviation from §26.7 and worth stating plainly: it spends a few
sessions of engineering to answer the two questions that decide whether the
project continues at all. Given §26.5's own rule that scope is the lever, buying
those answers cheaply is the right trade.

It does **not** change the rule that gameplay code waits for the determinism
spike — the prototype is throwaway, and should be written as such.

---

## Stage 1 — reconcile the document (days of designer time)

Work `03-contradiction-register.md` top to bottom. The five blocking decisions,
each of which is a choice rather than new design work:

| Decide | Between | Recommendation |
| --- | --- | --- |
| **C1** Detection model | §12.8 vs §12.17 | §12.17. Regenerate §29.1 from it; rewrite §5.4's landing noise in suspicion units |
| **C2** Raid payout | §9.4/§12.9 vs §9.6 | §9.6 — then rewrite §9.4's and §12.1's resource-share claims to match reality, and decide what Carrier capacity now means |
| **C3** Law rarity | three ranks vs five | Either, but regenerate §7.4, §7.7, §7.6, §9.5, §14.4 and the glossary from one table |
| **C4** What `L` is in `B(L)` | realm level (caps at 5) vs Vault level (caps at 10) | Almost certainly Vault level or a composite target-strength score. This is the master inflation dial and it currently references a level range that does not exist |
| **C6** Ruleborn roster | §11.2 vs §11.11 | §11.11, reduced to one data table; §11.2 becomes a generated index |
| **C19 / F1** Roster vs buildings | 152 positions vs a roster of 38 | Decide which moves: more Hearth homes, fewer permitted producers, or partial staffing made worthwhile |
| **F2** Producers per realm | 1 (what §9.3 assumes) vs 2 (what §5.2 permits) | Decide, then regenerate §9.3, §10.2, §14.2 and §14.3 from the model |
| **F3** The core trade-off | Raiding costs 2% of production | Make crew membership exclude work, the way guarding does — or accept that the trade-off is cosmetic and stop building the design on it |

Then C5 (defence budgets), C7 (tick rate), C8 (the Library) and C18 (the Aether
cap), then the minor ones.

F1 and F3 deserve the most thought: they are not clerical. F1 asks whether
character scarcity is a feature (as §4 claims) or an accident, and F3 asks
whether the design's stated central tension should be made real or dropped.
Both change how the game plays, not just what a table says.

**While doing this, split the document.** It is currently a specification and a
research archive in one file, and §19, §28 and §30 are roughly 40% of the text.
Both halves are valuable; keeping them together means the spec cannot be read,
diffed or implemented without the archive.

```
docs/design/spec/        the buildable specification, one file per system
docs/design/research/    §19, §28, §30 — the evidence, the reviews, the reasoning
```

The spec should carry decisions; the archive should carry why. Cross-reference,
don't duplicate.

**Also do the two content-balance passes** from `05-quantitative-findings.md`:

- Rebalance notes toward ~8–9 laws each (currently Glow 12, Hush 6) before the
  law data table is authored, since notes are frozen at eight and every future
  season must stay balanced too.
- Decide whether chords require three *laws* or three *notes* — as written, all
  twelve are reachable with two laws, several with two commons.

---

## Stage 2 — rebuild the economy model — **done**

`tools/economy_model/` is built, calibrated and tested. It reproduces the
document's first month to within 10% and its Keeper curve to within three days,
which is the evidence the reconstruction is sound.

It has already paid for itself by settling three things argument could not:

- **C2 measured.** §9.4's payout model delivers 32% of a player's income —
  reproducing its own stated "roughly a third" — against §9.6's 1–2%.
- **F1.** A finished universe has 152 character positions against a roster
  ceiling of 38. §9.3's production figures are unstaffable as written.
- **F2.** The published tables fit one producer per realm, not the two §5.2
  permits. A player who builds the second earns roughly double what §14 predicts.

What remains on the model:

1. Model Aether and Essence spending — weaving upkeep, births, character levels.
   Starlight currently drives all growth, which is why law-restoration dates are
   indicative only.
2. Once C3 is decided, replace the coarse page economy with per-law tracking, so
   §14.4's 1,485-page figure can be re-derived rather than assumed.
3. Once C4 is decided, re-run the faucet comparison with the chosen `L`, and set
   `B(L)`'s growth rate against the production curve rather than in isolation.
4. Regenerate §9.3, §10.2, §14.2 and §14.3 from the model under whatever building
   and roster rules are chosen, and replace the published tables wholesale. Hand-
   editing them is what produced C19.

---

## Stage 3 — the determinism spike (6–14 sessions, per §26.8)

Exactly as §24.2 and §26.7 specify, with one addition:

Prove that **one function returns the same checksum on four targets** — desktop,
server (WebAssembly), a cheap Android, an iPhone. The document specifies desktop,
server, Android and iPhone; make sure the *server Wasm build* is in the first
round and not deferred, because the entire architecture rests on the same code
running in both places.

Time-box it to ten working sessions as §24.7 already commits. If Rust extensions
will not build and load on real devices in that window, take the C# fallback
without renegotiating. Write the fixed-point module and the golden replays to be
portable from day one, so the switch costs the spike and nothing else.

**Do not write gameplay code before this passes.** Anti-cheat, replay validation,
free analytics, rehearsals, balance bots and the whole cost model all fail
together if it doesn't.

---

## Stage 4 — the scope conversation (one decision)

Before the vertical slice, decide §26.1's launch content against §26.5's own rule
that "scope is the lever, not headcount".

`06-build-readiness.md` proposes a ~40% cut that preserves everything
distinctively Ruleborn: 24 laws instead of 48, 3 form-notes instead of 8, ~20
resonances instead of 44, 2–3 languages instead of 12, constellations moved to
v1.1, wards at 2 levels instead of 5.

The Island Workshop is the one thing not to cut.

---

## Stage 5 — specification locks, then the vertical slice

Then §26.7's remaining sequence, unchanged:

1. Lock the simulation contract (§24.10)
2. Lock the detection numbers (§12.17) — unblocked by C1
3. Lock the law schema (§7, §8.7) — unblocked by C3 and the note rebalance
4. Lock saves, bundles and versions (§24.11)
5. Vertical slice (§26.2 phase 2), with §19.5's fun gate as the exit test

**Specify pathfinding and crew control before the slice** (G1). It is the largest
gap, and it is the system most likely to fail §30.7's premise 3. Write it down
before building it, and make felt control (§30.8's 70% threshold) a gate on the
slice rather than a polish item.

---

## What this repository should become

Suggested shape as work proceeds:

```
docs/
  design/
    ruleborn-game-design-v2.3.html   the source of truth as delivered (preserved)
    ruleborn-game-design-v2.3.txt    greppable extract, regenerated by tools/
    spec/                            the reconciled, buildable specification
    research/                        §19, §28, §30 — evidence and reviews
  analysis/                          this analysis
  decisions/                         one file per resolved contradiction, dated
tools/
  extract_design_doc.py              HTML → text
  check_design_consistency.py        the machine checks behind this analysis
  economy_model/                     stage 2
sim/                                 the deterministic core (stage 3 onward)
```

Two conventions worth adopting now:

- **Every contradiction resolved gets a dated decision record** in
  `docs/decisions/`, naming the sections it supersedes. The document reached v2.3
  with four systems specified twice precisely because superseded text was never
  retired; a decision log is the cheapest way to stop that recurring.
- **`tools/check_design_consistency.py` runs in CI once there is CI.** Every
  finding in this analysis that could be mechanised is asserted there, so the
  same class of drift is caught automatically next time.

---

## What not to do yet

- Don't write gameplay code (stage 3 gates it).
- Don't commission character art (the forms decision in stage 4 changes the
  quantity by 3×).
- Don't design screens in detail (C1, C5 and C6 change what several of them show).
- Don't start localisation.
- Don't claim the game's name publicly — §26.9 makes clearance a gate, and it has
  not been done.
