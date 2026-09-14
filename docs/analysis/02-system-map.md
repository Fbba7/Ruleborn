# System map

What Ruleborn is made of, what depends on what, and which couplings carry the
design's weight. Section numbers refer to the design document.

## The four nested loops (§4)

| Loop | Length | Produces | Feeds |
| --- | --- | --- | --- |
| Heist | 2.5–4 min | Loot, pages, Renown, Insight, strays | Session |
| Session | 5–9 min | Production collected, workers reassigned, a law woven, a Lab experiment queued | Discovery |
| Discovery | 2–5 days | A law restored, a realm opened, a resonance found, a map redesigned | Season |
| Season | 8 weeks | League placement, anomaly progress, an optional epoch | Long-term goals |

The document states the two scarce things are **stability** (how much law a
universe holds) and **character time** (work / guard / raid, never two at once).
That is accurate and it is the spine: almost every decision in the game resolves
to one of those two.

## Dependency graph

```
                         ┌──────────────────────────────────────────┐
                         │  DETERMINISTIC SIMULATION CORE (§24.7)   │
                         │  fixed-point, 20 or 30 Hz, seeded RNG    │
                         └──────────────────────────────────────────┘
                                         │
      ┌──────────────┬───────────────────┼───────────────────┬──────────────┐
      ▼              ▼                   ▼                   ▼              ▼
  heists (§12)   rehearsals (§13)   balance bots (§24)   replays/clips   co-op (v1.1)
      │                                   │                (§17.6)
      │                                   └─→ analytics & heatmaps (§24.3)
      ▼
  server re-simulation (§24) ─→ anti-cheat ─→ loot minting ledger (§24.12)

  ┌─ LAWS (§7) ──────────────────────────────────────────────────────────┐
  │  48 laws × {school, rank, cost, 1–2 notes, 3 tiers}                  │
  │    ├─→ notes (§8.1) ─→ harmonies / dissonances / resonances / chords │
  │    ├─→ realm rule sheet (§7.3) ─→ movement, sight, noise, damage     │
  │    ├─→ stability cost (§5.5) ─→ strain band ─→ production + faults   │
  │    ├─→ school resource bonus (§9.2) ─→ economy                       │
  │    ├─→ Nursery weights (§11.9) ─→ which ruleborn hatch               │
  │    └─→ form notes (§11.10) ─→ 144 collectable forms                  │
  └──────────────────────────────────────────────────────────────────────┘
                 │                                    │
                 ▼                                    ▼
      TERRAIN (§6, 39 features)            CHARACTERS (§11, 18 ruleborn)
      budget-limited, free to move          roles, traits, levels, forms
                 │                                    │
                 └──────────────┬─────────────────────┘
                                ▼
                     DEFENCE (§13, five layers)
            geometry 25% · guards 20% · wards 20% · laws 20% · response 15%
                                │
                                ▼
                     ISLAND WORKSHOP (§18.6) ─→ Drifting ruins ─→ new players
```

## The couplings that carry the design's weight

**1. Laws are parameters, not special cases (§7.3).**
The single best architectural decision in the document. Every law edits a realm's
rule sheet; nothing in a law names a particular creature or building. This is what
makes 48 laws × 39 terrain features produce genuine combinatorics rather than
48 × 39 hand-authored interactions. It is also what makes server-side re-simulation
and balance bots cheap. *If this is ever violated for one "special" law, the
combinatorial promise and the determinism guarantee degrade together.*

**2. Determinism is load-bearing for six unrelated features (§24.2).**
Anti-cheat, replay validation, free analytics, rehearsals, balance bots and the
near-zero infrastructure cost all rest on bit-identical simulation. The document
correctly flags this and correctly puts the spike first. *Every one of those
advantages fails at once if the spike fails* — which is why the C#/C++ fallback
ladder in 24.7 matters as much as the Rust preference.

**3. Notes are the highest-centrality object in the content graph (§24).**
Eight notes touch all 48 laws, all 44 resonances and all 12 chords. The document
already draws the right conclusion — freeze the note count at eight, expand via
laws. *This also means the note distribution across laws is a balance parameter
of the first order, and it is currently unbalanced (see `05-quantitative-findings.md`).*

**4. Character time is the only link between the two halves of the game (§11.6, §13).**
A ruleborn is working, guarding, resting, raiding or idle — never two. This one
rule is what stops the builder half and the raider half from being separate games.
It is elegant and it is doing a lot of work. *It is also the mechanism that will
be most tempting to soften if playtests show that raiding feels punished.*

**5. Stability couples law choice to economy and to defence (§5.5).**
Capacity comes from buildings; strain bands grant production bonuses up to +15%
and then impose faults. Overloading is a legitimate, visible choice. This makes
"which laws do I run" an economic decision and not just a flavour one. *The
seven-band curve is the main tuning dial for the whole mid-game and deserves an
explicit sensitivity analysis before launch.*

**6. The Workshop is the answer to the content treadmill, and it depends on premise 7 (§18.6, §30.7).**
A one-person team cannot out-author its players' consumption; the document knows
this and correctly makes the Workshop core infrastructure rather than a feature.
*The Workshop, the target pool and the "absent human" emotional charge (premise 1)
all fail together if players do not build. This is the single highest-value thing
to test, and it is testable on paper.*

## Systems that are self-contained (safe to defer)

These have few inbound dependencies and can be cut or postponed without
destabilising anything else:

- **Constellations, Grand Law, anomalies** (§17) — social layer over a complete
  single-player-shaped loop. Gated at Keeper level 6 anyway.
- **Seasons, eras, epochs** (§18.1–18.5) — eras are "pure data"; epochs are
  explicitly v1.1.
- **The Island Fund** (§18.9) — explicitly a live experiment with a stated
  failure condition, and the one decision taken *against* the evidence.
- **Visitors, paradox-born** (§11.8) — flavour layers on top of the roster.
- **Co-op heists, watching live, Law Clash, PC** (§26.2) — already scheduled post-launch.
- **Cosmetics, season track** (§22.1, §18.2) — the revenue layer, but architecturally
  isolated from the simulation.

## Systems that cannot be deferred

Cut any of these and the game stops being Ruleborn:

- The deterministic simulation core (§24.7)
- The law engine and the rule sheet (§7.3)
- The detection model (§12.17) — *currently specified twice, incompatibly*
- Terrain, and the route rule that guarantees a way in (§6.1)
- The island builder and the snapshot model (§13)
- Crew control in a heist (§12.7) — eight controls, thumb-reachable

## Where the document's own dependency analysis is right

§26.7 ("The order of work") sequences: paper heist → determinism on desktop →
spike on real phones → build-willingness test → lock the simulation contract →
lock detection numbers → lock the law schema → lock saves/bundles/versions →
*only then* gameplay code. That ordering is correct and should be treated as
binding. The only change I would make is to move the **build-willingness test to
run in parallel with the paper heist**, since it is the higher-ranked risk
(§30.8 risk register) and costs the same nothing.
