# Documentation index

Every document in the repository, with one line on what it is and who owns
it. "Owner" is who changes it: **the owner** is the person the game belongs
to; **Integrator** is the agent on the main branch; **T1–T16** are the agent
tracks ([agent-program.md](guides/agent-program.md)); **generated** means a
tool writes it, so change the tool's source and regenerate, never the file.
Where a file's history is one imported commit, its owner is inferred from its
content.

If you are new, read in this order: the [README](../README.md),
[architecture.md](architecture.md), then the guide for the part you will work
on.

## Words

The game's own vocabulary (Keeper, ruleborn, Sage, law, note, resonance,
chord, realm, Vault …) is defined in the design document's glossary, §29.2;
it is not repeated here. The repository's own words:

| Word | Meaning |
|---|---|
| Register item | An entry in the audit register (`tools/audit_register.py`): C contradiction, G gap, F quantitative finding, D deviation (a change to the plan), Q decision |
| OPEN | A design-document check that fails while its register item is open: reported, but not a build failure |
| TD.n, T3.1 … | Task ids on the roadmap (`tools/roadmap.py`) |
| SR-n | A finding of the security review ([`security/review.md`](security/review.md)) |
| Lease | The server's permission to raid one target: seed, token, clock, rules version, expiry |
| Rules version | A digest of the law table and of what the build does with the golden heists (`sim::rules_version`); a replay names the one it was played under |
| Golden replay | A heist recorded once and committed (`sim/golden/`), re-simulated on every build |
| Track, wave, deploy | An agent's line of work on its own branch; a stretch of parallel work; a round of the integrator's merges ([agent-program.md](guides/agent-program.md)) |
| Integrator | The agent that owns the main branch and merges the tracks |
| Still | A PNG rendered from the client and compared with the design's |

## Start here

| Document | What it is | Owner |
|---|---|---|
| [`../README.md`](../README.md) | What the game is, the repository map, the quick start, the live pages | T15 (docs), Integrator |
| [`architecture.md`](architecture.md) | Client, simulation and server; a heist end to end; what is authoritative where | T15 (docs) |
| [`status.md`](status.md) | Where the project stands now, and its history version by version (formerly the README's body) | Integrator |
| [`DOCS-CHANGES.md`](DOCS-CHANGES.md) | What the documentation pass changed and why, and its questions for the owner | T15 (docs) |

## Guides

| Document | What it is | Owner |
|---|---|---|
| [`guides/checks.md`](guides/checks.md) | `tools/check_all.sh` step by step, what it needs, and the rules the documentation check enforces | T15 (docs) |
| [`guides/client.md`](guides/client.md) | Building and testing the client, rendering stills, strings and localisation, accessibility checks, budgets | T15 (docs) |
| [`guides/server.md`](guides/server.md) | Running, testing and load-testing the server; its configuration; its generated inputs | T15 (docs) |
| [`guides/simulation.md`](guides/simulation.md) | Building and testing `sim/`, changing a rule safely, the golden replays | T15 (docs) |
| [`guides/design-tools.md`](guides/design-tools.md) | The design document, the audit register, the decision brief, the roadmap, content tables, and their commands | T15 (docs) |
| [`guides/agent-program.md`](guides/agent-program.md) | The operating model for every wave: roles, the backlog and claims, files as the channel, the merge queue, the quality gate, the owner's cadence, usage, model routing, sessions, failure recovery, and the lessons of waves 4 and 5 | T15; rewritten by T17 |
| [`guides/agent-brief.md`](guides/agent-brief.md) | The brief every agent reads first: hard rules, reporting, claiming work, session hygiene and the stop protocol | T17 |
| [`research/agent-team-operating-model.md`](research/agent-team-operating-model.md) | Research: how to organise and run the agent team (coordination, token cost, quality gates, operations), with sources | Integrator |

## The code's own READMEs

| Document | What it is | Owner |
|---|---|---|
| [`../sim/README.md`](../sim/README.md) | The simulation core: what it proves, determinism, every system it models, its layout | Integrator |
| [`../server/README.md`](../server/README.md) | The server area by area: what it does, the readings it takes where the document is silent, its layout | Integrator; T11 (sign-in), T13 (cost) |
| [`../server/declarations.md`](../server/declarations.md) | The stores' privacy declarations | generated (`node server/src/privacy.mjs --write`, from `server/privacy.json`) |
| [`../server/web/terms.md`](../server/web/terms.md) | The terms of use the server serves | Integrator |
| [`../client/README.md`](../client/README.md) | The client: its layers, accessibility, tests, layout | Integrator |
| [`../client/ui/fonts/LEDGER.md`](../client/ui/fonts/LEDGER.md) | The typefaces the client ships, their licences and hashes | T9 |
| [`../content/README.md`](../content/README.md) | The content tables, their validator, what they found about the document | Integrator |
| [`../content/upstream/README.md`](../content/upstream/README.md) | The design's own data files, kept as shipped | Integrator |
| [`../art/design/README.md`](../art/design/README.md) | The Screens v3 design's 3D sources and target stills | Integrator |
| [`../prototypes/heist-gate/README.md`](../prototypes/heist-gate/README.md) | The superseded browser prototype of the two pre-code gates | Integrator |
| [`../tools/economy_model/README.md`](../tools/economy_model/README.md) | The day-by-day economy model | Integrator |
| [`../tools/heist_harness/README.md`](../tools/heist_harness/README.md) | §19.27's simulation harnesses | Integrator |
| [`../tools/vendor/README.md`](../tools/vendor/README.md) | The design document's own shipped checker, kept unmodified | the owner (vendored; not edited here) |

## The design

| Document | What it is | Owner |
|---|---|---|
| [`design/ruleborn-game-design-v3.7.html`](design/ruleborn-game-design-v3.7.html) | The design document, current version; [`.txt`](design/ruleborn-game-design-v3.7.txt) is its extracted text, which the checks read | the owner |
| `design/ruleborn-game-design-v*.html`, `.txt` | Earlier versions (v2.3, v3.0–v3.4, v3.6), kept for diffs and the archive | the owner |
| [`design/spec/README.md`](design/spec/README.md) | The drafted specification: one file per system the document left contradictory or open, each proposed until adopted | Integrator |
| `design/spec/*.md` | The sixteen spec files; each is listed with what it resolves in the spec index | Integrator |
| [`design/dependencies.md`](design/dependencies.md) | What has to be settled before what | generated (`tools/check_dependencies.py --write`) |
| [`design/generated/`](design/generated/v3-response.md) | Summary tables (`formulas`, `laws`, `roster`), the economy re-run (`pacing`), and v3.0's response (`v3-response`) | generated (`tools/generate_docs.py`) |
| `decisions/brief.json` | The owner's decision brief, as data | Integrator |
| `decisions/answers.json` | The owner's recorded answers | the owner |
| `decisions/index.html`, `audit/index.html`, `roadmap/index.html` | The published pages | generated (`tools/build_brief.py`, `build_audit.py`, `build_roadmap.py`) |
| [`roadmap/README.md`](roadmap/README.md) | How to read the roadmap and where its statuses come from | Integrator |

## The analysis

| Document | What it is | Owner |
|---|---|---|
| [`analysis/README.md`](analysis/README.md) | The first deep read of the design, at v2.3: an archive, using v2.3's numbering | Integrator |
| [`analysis/01-executive-summary.md`](analysis/01-executive-summary.md) … [`07-recommended-next-steps.md`](analysis/07-recommended-next-steps.md) | Its seven reports: verdict, system map, contradictions, gaps, quantitative findings, build readiness, next steps | Integrator |
| [`analysis/screens-v3/README.md`](analysis/screens-v3/README.md) | Screens v3 (the owner's screen and character designs), compared with v3.6 and the build | Integrator |
| `analysis/screens-v3/screens-*.md` | Screen by screen: the design against the document, the build, and the Godot plan (eight files) | Integrator |
| [`analysis/screens-v3/design-system.md`](analysis/screens-v3/design-system.md) | The design system measured: tokens, type, contrast | Integrator |
| [`analysis/screens-v3/characters.md`](analysis/screens-v3/characters.md) | The 43 character and creature sheets against the document | Integrator |
| [`analysis/screens-v3/3d-pipeline.md`](analysis/screens-v3/3d-pipeline.md) | The design's 3D, measured, and how each piece reaches Godot | Integrator |
| [`analysis/screens-v3/engine.md`](analysis/screens-v3/engine.md) | The engine move to Godot 4.7.2, measured | Integrator |
| [`analysis/screens-v3/v36-rules.md`](analysis/screens-v3/v36-rules.md) | v3.6's rule changes against the build and the register | Integrator |
| [`analysis/screens-v3/register-roadmap.md`](analysis/screens-v3/register-roadmap.md) | What Screens v3 means for the register, the roadmap and the completion figure | Integrator |
| [`analysis/screens-v3/handoff/README.md`](analysis/screens-v3/handoff/README.md) | The owner's design handoff against the plan, with its parts (`assets`, `diff`, `intent`, `module`, `review-1` to `-3`) | Integrator |
| `analysis/screens-v3/handoff/source/` | The handoff's own files, as received | the owner |
| `analysis/screens-v3/data/` | The measurements behind those reports | Integrator |

## The 3D and interface program

| Document | What it is | Owner |
|---|---|---|
| [`art/3d-program.md`](art/3d-program.md) | The program: the quality bar, the look every track works to, the rules, the track table | Integrator |
| [`art/tracks/README.md`](art/tracks/README.md) | Which track's notes are which file; the notes themselves say what was done, the stills, what is still worse than the design, and "Stopped here" | T15 (docs); each notes file its track |
| [`art/shots/README.md`](art/shots/README.md) | Which stills folder is whose; each folder holds the stills a track judged its work by | T15 (docs); each folder its track |
| [`art/ui-quality/report.md`](art/ui-quality/report.md) | Why the interface is not premium yet, a benchmark, an audit, and the next-wave plan (plan v3), with the kit spec, build or buy and the review log beside it | T14; plan by T16 and T17 |
| [`progress/`](progress/T5.md) | Each track's progress file: six-line header and deliverables table | each track |
| [`progress/backlog.example.json`](progress/backlog.example.json) | An example of the backlog and claim format the lead keeps as `progress/backlog.json` | T17 |

## Security, cost and privacy

| Document | What it is | Owner |
|---|---|---|
| [`security/review.md`](security/review.md) | The adversarial security review: every finding (SR-01 on), its test, its fix or the owner's decision, with patches | T12 |
| [`security/auth.md`](security/auth.md) | Sign-in and sign-out: threat model, design, abuse limits, native steps | T11 |
| [`server/db-cost.md`](server/db-cost.md) | What the database costs, how it is measured, the cuts, the owner's options | T13 |
| [`../server/declarations.md`](../server/declarations.md) | The stores' privacy declarations | generated |
