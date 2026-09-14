# Build readiness

An independent read on what can be built today, what is blocked, and whether the
plan in §26 is achievable.

---

## What is ready to build now

These are specified well enough to implement without inventing anything:

| System | Section | Why it's ready |
| --- | --- | --- |
| **The economy model** | §9, §10, §14 | Every formula and cost is given. This is a pure Python job needing no engine, no art, no device — and it regenerates the tables the document depends on (G7) |
| **Determinism harness** | §24.2, §24.7, §24.10 | Fixed-point rules, RNG choice (SplitMix64 → xoshiro256++), ordering rules and checksum cadence are all specified |
| **Law/terrain/creature data schemas** | §7, §6, §11 | The *shape* is clear even where values conflict; the schema can be authored before the values are resolved |
| **Rule-sheet parameter model** | §7.3 | The parameter list and the order of application (§7.3, §8.7) are complete and well-reasoned |
| **Modifier resolution order** | §8.7 | Four steps, deterministic tie-breaking, paradoxes resolve last. Buildable as written |
| **Detection model** | §12.17 | Complete and buildable — *once* C1 is resolved in its favour |
| **Backend data model** | §24.8 | Tables, hashing, idempotency and the no-passwords model are specified |
| **Offline/lease/mint flow** | §24.12 | One of the best-specified parts of the document |
| **Rules versioning** | §24.11 | Pin-don't-patch, with the grace state defined |

## What is blocked, and by what

| Blocked | Blocked by |
| --- | --- |
| Guard AI, HUD vision rendering, all stealth balance | C1 — two detection models |
| Economy tuning, the core loop's stated purpose | C2 + C4 — two payout models, undefined `L` |
| Law content authoring | C3 — two rarity taxonomies |
| Creature content authoring, crew and guard behaviour | C6 — two rosters |
| Island builder, defence balance | C5 — two budget systems |
| Golden replays (they encode the tick rate) | C7 — 20 Hz or 30 Hz |
| Heist prototype, felt-control validation | G1 — pathfinding and crew control unspecified |
| The Vault phase's core decision | G4 — loading time has no relationship to payout |

---

## The plan's own critical path is correct

§26.7 sequences the work well, and the ordering should be treated as binding:

```
paper heist ─┐
             ├─→ desktop determinism ─→ real-phone spike ─→ language decision
build-       ┘                                                      │
willingness test ─→ authorship vs curation decision                 │
                                                                    ▼
      simulation contract lock ─→ detection lock ─→ law schema lock ─→ save/bundle lock
                                                                    │
                                                                    ▼
                                                        gameplay and engine code
```

Two changes I would make:

1. **Run the build-willingness test first, in parallel with the paper heist.** It
   is ranked risk #1 (§30.8) and it decides "the single decision that changes the
   most" (§26.7). The paper heist decides whether the game is fun; the willingness
   test decides *what game it is*. Both cost nothing; neither should wait.

2. **Insert "resolve the contradiction register" before the schema locks.** The
   spec locks in §26.7 assume there is one spec to lock. Right now there are two
   of several things. Reconciliation is a few days of the designer's time and it
   is the cheapest work in the whole plan.

---

## The technical bet, assessed

**The determinism-first architecture is right, and the document is right that it
is load-bearing.** Anti-cheat, replay validation, free analytics, rehearsals,
balance bots and a ~$5–15/month infrastructure bill all fall out of one decision.
That is exceptional leverage and it is correctly sequenced first.

**The Rust-on-mobile bet is the thinnest part, and the document says so.** §24.7
and §30.14 both flag that Godot's Rust extensions on mobile are officially
experimental with no confirmed shipped commercial title, and §24.7 pre-commits a
fallback trigger (ten working sessions) and a fallback language (C#). That is
exactly the right way to carry an unproven dependency: named, time-boxed, with the
portable parts (the fixed-point module, the golden replays) written to survive the
switch.

One addition worth making: **the spike should also prove the WebAssembly server
path**, not just the phone path. The whole architecture rests on *the same code*
running in both places; a Rust extension that loads on iOS but whose Wasm build
diverges on the server fails just as completely.

**The store-compliance analysis is correct and often missed.** §24.7's
observation — that a native extension linked into the signed binary is fine, but a
runtime WebAssembly loader on the device would be downloaded code — is precisely
the distinction Apple enforces, and getting it wrong late is a launch-blocking
rejection.

**§24.9's agent-testing defence is the most sophisticated thing in the document.**
Hand-written golden fixtures, cross-architecture checksums, property tests,
fuzzing and schema validation — authored by a human *before* the code, so the
agent is never both author and judge of its own tests. This should be treated as a
hard rule, not a guideline.

---

## Scope: where I disagree with the plan

§26.2 budgets 48–56 weeks from pre-production to global launch for one designer,
one coding agent and three contractors. §26.8 budgets ~270 agent runs (≈810 focused
hours) for the build, and then states plainly that **iteration to find the fun is
unbudgeted**.

The launch content table (§26.1) asks for, at launch:

- 48 laws × 3 tiers, each with a movement signature, a world signature, a raider
  use, a defender use, a weakness and a sound
- 44 hand-designed resonances + 12 chords + 3 paradoxes
- 18 ruleborn × 8 forms = 144 visual variants (see `05-quantitative-findings.md` §7)
- 39 terrain features, ~80 meshes
- 16 building types, ~100 level definitions
- 27 screens, ~220 icons
- 12 languages over a coined vocabulary of ~130 proper nouns
- The Island Workshop, with moderation
- A season track, leagues, constellations, anomalies

**This is a studio's launch scope, not a solo-plus-agent one.** The document's own
best advice is §26.5 ("scope discipline is the main risk control… scope is the
lever, not headcount") and §30.8 risk #2 ("production and execution… a small team
cannot hire its way out"). That advice has not yet been applied to §26.1.

### What I would cut for launch, and why it is safe

The design is unusually well-suited to cutting, because §02's system map shows
the social and seasonal layers have few inbound dependencies.

| Cut | Saves | Why it's safe |
| --- | --- | --- |
| **Forms: ship 3 notes, not 8** (54 variants, not 144) | The largest art item | §11.10 says forms are "small sidegrades" that "never change the role". The collection chase is already carried by 48 laws and 18 creatures. Add notes per season |
| **Laws: ship 24, not 48** | ~half the content and balance work | §7.6 already gates the Codex in chapters — 24 laws is chapter 2, reached at Keeper level 6 (day 5–8 engaged). Ship chapters 3–5 as the first three seasons. §26.1 already plans +6 laws/season |
| **Resonances: ship ~20, not 44** | Hand-design time | They are discovery content, found over months. §30.8 already says "nobody memorises 56 interactions" |
| **Languages: ship 2–3, not 12** | Translation, QA, a 12-language device pass | §20.6 already says English + Portuguese at launch, contradicting §26.2. Follow §26.4's plan: translate *store pages* into more languages than the game, and let demand data choose |
| **Constellations → v1.1** | A social subsystem, chat moderation, anomalies | Gated at Keeper level 6 anyway; the loop is complete without it. Keeps the launch moderation surface near zero |
| **Wards: ship 6 types × 2 levels, not × 5** | 18 prop variants + balance | Only level 1 is specified anyway (G3) |

That is roughly a 40% content reduction with, I think, no loss to what makes
Ruleborn *Ruleborn* — the laws, the terrain, the heist, the island builder and the
Workshop all survive intact. It also matches the document's own §2.2 lesson from
Squad Busters: "prove the core loop with real players before scaling".

### The one thing not to cut

**The Island Workshop.** §30.8 is right that it is "the only credible answer to
the content treadmill" for a team this size. Cutting content to protect the
Workshop is the correct trade; cutting the Workshop to protect content is not.

---

## Risk assessment: where I agree and differ with §30.8

The document's ranked risk register is good. My differences:

| Risk | Doc rank | My rank | Comment |
| --- | --- | --- | --- |
| Nobody builds defences | 1 | 1 | Agreed, and testable for free. Run it now |
| Production and execution | 2 | **2, but larger than stated** | The unbudgeted iteration (§26.8) is the specific hole |
| Concept does not communicate | 3 | 3 | Agreed. §23.4's anchored-differentiation rule is the right answer |
| Cold start | 4 | 4 | Echo universes are a good mitigation |
| Content treadmill | 5 | 5 | Mitigated by cutting launch scope, not just by the Workshop |
| Trust and safety at scale | 6 | **8** | Lower: no free text for minors, no uploads, structured data only, preset chat. The design has already engineered most of this risk away |
| Complexity overwhelms new players | 7 | **6** | Higher: §19.4 names it "the biggest risk in the whole design", and the four-interacting-rules cap is untested |
| Device and performance | 8 | 7 | The reference-device choice (mid-range 4 GB Android) is right |
| Revenue insufficiency | 9 | 9 | Agreed, and knowingly accepted |
| **Delegated control feels like watching** | *unranked* | **new, ~4** | §30.7 premise 3 is only "conditionally supported", the failure mode is named ("my units are stupid"), and the system that decides it (pathfinding, G1) is the largest specification gap. §19.4 also concedes performative challenge is "almost absent by design" |

---

## Bottom line

Nothing in this design is unbuildable. The architecture is sound, the economy is
mostly consistent, and the technical plan is better reasoned than most.

What stands between this document and a first line of gameplay code is:

1. Two free playtests (paper heist, build-willingness) — **days**
2. Resolving seventeen contradictions — **days of designer time**
3. Rebuilding the economy model — **a small number of coding sessions**
4. The determinism spike, phone *and* server — **6–14 sessions, per §26.8**
5. A scope decision on §26.1 — **one conversation**

None of that is blocked by anything. All of it should happen before the vertical
slice begins.
