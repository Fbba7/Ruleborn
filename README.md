# Ruleborn

> Your islands. Your rules. Their treasure.

A strategy game about floating islands that each follow a magic rule. You collect
these rules, build your islands around them, and send a small crew of odd little
creatures to rob other players' islands by outsmarting theirs.

Native mobile (iPhone and Android), Godot 4.7.2-stable with godot-rust v0.5.5 on its 4.7 API (§24, TD.1), rated 13+, cosmetic-only monetisation.

**New here?** Read [The design in one page](#the-design-in-one-page), then
[`docs/architecture.md`](docs/architecture.md), then the
[documentation index](docs/README.md). The game's vocabulary is the design
document's glossary (§29.2); the repository's own words are in the index.

## Contents

- [Status](#status)
- [Repository map](#repository-map)
- [Quick start](#quick-start)
- [The checks](#the-checks)
- [Live pages](#live-pages)
- [Key documents](#key-documents)
- [The design in one page](#the-design-in-one-page)
- [Repository layout](#repository-layout)

## Status

**Pre-production — design document at v3.7, every recorded decision written in, the screens and characters designed (Screens v3); the simulation core, the server and the client are built far enough to play a heist end to end, and the 3D and interface program has run five waves.**

The full account, part by part and version by version, is
[`docs/status.md`](docs/status.md).

### Can the drawing start?

An area is ready to hand to whoever will draw it when nothing still open decides
something they would otherwise have to guess. The audit page computes this from
the gates themselves — it cannot read "Ready" while one is open — and shows it in
a band at the top.

| Area | Verdict | Waiting on |
| --- | --- | --- |
| **Realms** | Waiting on you | your decision: C19 |
| **Screens** | Ready | — |
| **Characters** | Ready | — |

This table is checked against the register by
`tools/check_docs_consistency.py`; what each verdict means is in
[`docs/status.md`](docs/status.md#history-as-written-at-each-version).

## Repository map

| Path | What it is | Start with |
|---|---|---|
| `sim/` | The heist simulation in Rust: deterministic fixed point, no dependencies, the same code on the phone and (as WebAssembly) on the server | [`sim/README.md`](sim/README.md) |
| `server/` | The backend on Node 22.5+: lease, re-simulate, grant, and the meta-game (accounts, seasons, shop, Workshop, friends …) | [`server/README.md`](server/README.md) |
| `client/` | The game in Godot 4.7.2 (GDScript), with `sim/` linked in as a Rust GDExtension (`client/ext/`) | [`client/README.md`](client/README.md) |
| `content/` | The design's content tables as JSON, extracted from the document and validated against it | [`content/README.md`](content/README.md) |
| `tools/` | Checks over the design document, the register and page generators, models, string generators, art export | [the tools listing](#repository-layout) |
| `docs/` | Design document, analysis, specification, art program, progress, security, cost | [`docs/README.md`](docs/README.md) |
| `art/design/` | The Screens v3 design's own 3D sources and its target stills | [`art/design/README.md`](art/design/README.md) |
| `prototypes/heist-gate/` | A superseded browser prototype of the two pre-code gates, still published | [`prototypes/heist-gate/README.md`](prototypes/heist-gate/README.md) |

How the three programs fit together, and how a heist flows through them:
[`docs/architecture.md`](docs/architecture.md).

## Quick start

You need Python 3.10+ (tested on 3.13), Rust stable (1.82 or later), Node 22.5+ and, for the client, Linux
x86-64 (Godot is fetched for you). Once:

```bash
rustup target add wasm32-unknown-unknown aarch64-linux-android aarch64-apple-ios
pip install "gdtoolkit==4.*"     # gdlint, for the client's lint
pip install playwright && python3 -m playwright install chromium   # the prototype check
```

**Simulation** — build natively and for WebAssembly, run every test and the
golden replays, compare the two builds:

```bash
bash sim/run_spike.sh
```

**Server** — needs the WebAssembly build above:

```bash
node --no-warnings --test server/test/*.test.mjs                  # the tests
RULEBORN_STUB_SIGNIN=1 node --no-warnings server/src/main.mjs 8787 --example   # run it on 127.0.0.1:8787
```

**Client** — fetches Godot 4.7.2 once into `~/.cache/ruleborn/`:

```bash
bash client/build.sh        # the extension, the golden replays, Godot's import cache
python3 client/status.py    # every client test, headless, against a fresh local server
bash tools/render/shoot.sh client/tests/shots/heist_shot.gd heist.png   # a still, with no screen
```

To look at it on a desktop, open `client/` in Godot 4.7.2 after building.

**Everything** — the gate every push is held to (about 25 minutes):

```bash
bash tools/check_all.sh
```

The per-part guides go further: [client](docs/guides/client.md),
[server](docs/guides/server.md), [simulation](docs/guides/simulation.md).

## The checks

`tools/check_all.sh` runs every check in the repository in dependency order,
stops at the first failure, and ends with `All checks passed.` It covers, in
order: the design document's own consistency; the simulation (tests, goldens,
native against WebAssembly); the server (tests, load budget, privacy
declarations); the client (string catalogues, the client–server contract,
gdlint, every headless test, the phone builds compiling); the content tables;
the models and analysis tools; this repository's own documents
(`tools/check_docs_consistency.py`); and finally the audit and roadmap pages,
which it regenerates.

A known contradiction in the design document is not a failure: it is work not
yet done, tracked as an open register item, and reported **OPEN**. A failure
with no open item behind it, or a regression of an item marked fixed, breaks
the build.

Every step, the command to run it alone, and the rules the documentation
check holds Markdown to: [`docs/guides/checks.md`](docs/guides/checks.md).

## Live pages

Four pages are published from this repository. Each is generated; never edit
the HTML by hand.

The **audit register**: every change to the plan and everything still to fix
in the design document, with the edits to make —
**https://claude.ai/artifact/8m5MgpjWfFurnfwc6b76sN**
(source `tools/audit_register.py`, built by `tools/build_audit.py` into
`docs/audit/index.html`).

The **decision brief**: every item only the owner can settle, in the order to
decide them — **https://claude.ai/artifact/YZcD1uH5xtpFznqncRpt8g**
(source `docs/decisions/brief.json`, built by `tools/build_brief.py` into
`docs/decisions/index.html`).

The **roadmap**: every stage of the build, what finishes it, who it waits on,
and progress computed from the register and passing tests —
**https://claude.ai/artifact/Yb1WxZ2eJCCbByitnd7fJf**
(source `tools/roadmap.py`, built by `tools/build_roadmap.py` into
`docs/roadmap/index.html`).

The **heist-gate prototype**, superseded but still published —
**https://claude.ai/artifact/3jW7Zg1rTrzR6CF3cEVp2E**
([`prototypes/heist-gate/README.md`](prototypes/heist-gate/README.md)).

How the register, the brief and the roadmap work and how to change them:
[`docs/guides/design-tools.md`](docs/guides/design-tools.md).

## Key documents

Four sources describe the design. **The design document wins**: Screens v3 is
its visual reference and loses on every rule (§23.5); the specification is a
proposal until the document adopts it; the analysis is an archive of the v2.3
reading.

| Document | What it is |
|---|---|
| [`docs/README.md`](docs/README.md) | Every document in the repository, one line each, with its owner |
| [`docs/architecture.md`](docs/architecture.md) | Client, simulation and server; a heist end to end; what is authoritative where |
| [`docs/status.md`](docs/status.md) | Where the project stands, and its history version by version |
| [`docs/design/ruleborn-game-design-v3.7.html`](docs/design/ruleborn-game-design-v3.7.html) | The design document (text: [`.txt`](docs/design/ruleborn-game-design-v3.7.txt)) |
| [`docs/design/spec/README.md`](docs/design/spec/README.md) | The drafted specification, one file per system, proposed until the document adopts it |
| [`docs/art/3d-program.md`](docs/art/3d-program.md) | The 3D and interface program: the bar, the look, the tracks |
| [`docs/guides/agent-program.md`](docs/guides/agent-program.md) | How the agent tracks work: branches, ownership, progress files, deploys |
| [`docs/security/review.md`](docs/security/review.md), [`docs/security/auth.md`](docs/security/auth.md) | The security review, and sign-in's threat model and design |
| [`docs/server/db-cost.md`](docs/server/db-cost.md) | What the database costs, and what was cut |
| [`docs/art/ui-quality/report.md`](docs/art/ui-quality/report.md) | Why the interface is not premium yet, and the plan |
| [`docs/DOCS-CHANGES.md`](docs/DOCS-CHANGES.md) | What the documentation pass changed, and its open questions |

## The design in one page

**Setting.** The Book of Laws burst open and its pages scattered across the sky.
Wherever a page landed, an island lifted into the air and began to follow what was
written on it. Keepers gather torn pages, restore them, and write the laws into
their own islands.

**Loops.** A heist is 2.5–4 minutes; a session is 5–9; a discovery takes 2–5 days;
a season is 8 weeks.

**The two scarce things.** *Stability* — how much law a universe can hold — and
*character time*, since a ruleborn can work, guard or raid but never two at once.
Almost every decision resolves to one of these.

**Content at launch (as designed).** 48 laws in 6 schools, carrying 8 notes that
produce harmonies, dissonances, 44 signature resonances and 12 chords; 39 terrain
features; 18 ruleborn in 144 law-shaped forms; 16 buildings; 7 realm types; 4
Sages.

**Architecture.** One deterministic, fixed-point simulation written without engine
types, compiled into the phone app and to WebAssembly on the server, so both run
the same code. A heist is a seed and an input log of under 2 KB. That single
decision buys server-authoritative anti-cheat, free replays and analytics,
rehearsals, balance bots, and an infrastructure bill of roughly $5–15 a month at a
million monthly players.

**Money.** Cosmetics and a season pass. No paid randomness, no power, no login
rewards, no engagement-tuned matchmaking — with the refusals written down so they
cannot creep back in.

Full detail: [`docs/design/ruleborn-game-design-v3.7.html`](docs/design/ruleborn-game-design-v3.7.html).

## Repository layout

```
sim/            the heist simulation core in Rust (see sim/README.md's Layout)
server/         the edge functions of §24.1 over §24.8's tables (see server/README.md's Layout)
client/         the Godot 4.7.2 client, with sim/ as a GDExtension (see client/README.md's Layout)
content/        the content tables as data, plus the reconciled detection spec
art/design/     the Screens v3 design's own 3D sources (sculpts, rigs, diorama) and its target stills
prototypes/
  heist-gate/   a superseded browser build that runs both pre-code gates
docs/
  README.md     the index of every document
  architecture.md, status.md, guides/   how it fits, where it stands, how to work on it
  design/       the design document at v3.7, every earlier version, extracts, spec/, generated/, dependencies.md
  analysis/     the deep analysis of the design (v2.3), and screens-v3/, the Screens v3 reading
  audit/        the generated audit register page
  decisions/    the owner's decision brief and answers, and its generated page
  roadmap/      the generated roadmap page
  art/          the 3D and interface program, each track's notes, its stills, the UI quality report
  progress/     each agent track's progress file
  security/     the security review and sign-in's design
  server/       the database's cost
tools/
  # the design document
  design_doc.py                   which design document every check reads, in one place
  design_facts.py                 the facts the document states, for the tools that read them
  extract_design_doc.py           HTML -> greppable text
  check_document.py               every check over the document, in one verdict
  check_design_consistency.py     the design half, which check_document.py runs
  vendor/                         v3.1's own checker, kept unmodified to diff against
  mutation_gate.py                §31.5's fifteen breakages, and the same defects said differently
  twice_stated.py                 facts the document states in more than one section
  inventory_homes.py              every section stating a launch-inventory count, and what checks it
  version_diff.py                 what one version of the document changed, section by section
  # content tables
  extract_content.py              design document -> content/*.json
  validate_content.py             schema and cross-reference checks on content/
  generate_docs.py                content/ -> the design document's summary tables
  compare_module.py               the prototype's data module against content/, by hash, read as text
  # the register, the brief, the roadmap and this repository's documents
  audit_register.py               the audit register, as data
  build_audit.py                  renders the register to docs/audit/index.html
  check_audit_ui.py               the audit page's tabs, bars and chips, against the register
  check_edits.py                  every drafted edit quotes the document correctly
  check_dependencies.py           the ordering between items; writes dependencies.md
  check_findings_fresh.py         which register numbers can be shown to be current
  decision_support.py             prices the decisions that are the owner's
  build_brief.py                  the owner's decision brief to docs/decisions/index.html; --check
  roadmap.py                      the roadmap, as data
  build_roadmap.py                renders it, computing progress from the register
  completion.py                   how close the app is to built, backend and frontend, from §26.8's costs and passing proofs
  build_stamp.py                  one build stamp for every published page
  check_docs_consistency.py       this repository's own documents, against each other
  # the agent program
  run_checks.sh                   the full checks on a separate worktree of one commit, detached; start, wait, result, record
  coord/                          the program's coordination tools: owners.py checks a change stays inside its task's files
  # models and analyses
  economy_model/                  the day-by-day model §24 references but omits
  heist_harness/                  §19.27's simulation harnesses, built in v3.0's plan
  check_unread_fields.py          every field the harness computes is read somewhere
  generator_settings.py           sweeps the generator against both bands the document sets
  post_ladder.py                  whether a steeper guard-post ladder closes F26's gap or moves it
  ward_budget.py                  whether F26's ward budget lands every realm in both bands
  law_ranks.py                    prices C3's three rank splits, and tests §7.9's rule against the sheets
  law_effects.py                  classifies all 48 laws against the rule sheet
  ability_text.py                 C6's 18 ability pairs: which differ by how much, and which by what they do
  note_rebalance.py               the note rebalance §8.8 says is already done
  scope_cut.py                    costs a launch-scope cut by engine work
  league_model.py                 fits the league boundaries to §14.7's shares; writes server/src/leagues.json
  # the client and server's generated inputs
  client_strings.py               writes client/i18n/content.csv, the content's names, from content/
  auth_countries.py               writes client/i18n/countries.csv, every country's name in the game's languages
  native_strings.py               writes the phones' notification tables, iOS and Android, from client/platform/notifications.csv
  english_us.py                   writes US English from British English by a spelling table, in the catalogues and the island words
  client_contract.py              the client's server routes and failure words, checked against server/src/http.mjs
  privacy_manifest.py             writes the iPhone preset's privacy options from server/privacy.json
  # art and rendering
  art/                            the design's creature modules -> client/art/creatures/*.glb (node tools/art/export.mjs)
  ui/                             the design's icons -> client/ui/icons/ (SVG and PNG with a manifest; node tools/ui/export_icons.mjs)
  ui_bake/                        the UI kit's bake (K1): node tools/ui_bake/bake.js <family> bakes art/ui/ into client/ui/art/ atlases and manifests; --check compares hashes; docs/art/ui-quality/kit-spec.md section 6.6
  ui_research/                    T14's UI quality research: authored HUD art baked in headless Chromium into one atlas (node tools/ui_research/bake_hud.js), the AI UI artist's icons rendered in three.js (bake_icons.js), side-by-sides (compare.py); docs/art/ui-quality/report.md
  render/                         renders a still from the Godot client on a machine with no screen
  # the superseded prototype
  parse_gate_results.py           scores the gates from testers' result codes
  build_prototype.py              renders the throwaway browser build of the two pre-code gates
  check_prototype_conformance.py  the prototype implements the rules it claims to
```

The commands for the design-side tools (extracting the document, the
economy model, the harness, the register) are in
[`docs/guides/design-tools.md`](docs/guides/design-tools.md).
