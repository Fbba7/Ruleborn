# Ruleborn

> Your islands. Your rules. Their treasure.

A strategy game about floating islands that each follow a magic rule. You collect
these rules, build your islands around them, and send a small crew of odd little
creatures to rob other players' islands by outsmarting theirs.

Native mobile (iPhone and Android), Godot 4.7.2-stable with godot-rust v0.5.5 on its 4.7 API (§24, TD.1), rated 13+, cosmetic-only monetisation.

## Status

**Pre-production — design document at v3.7, every recorded decision written in, the screens and characters designed (Screens v3); the simulation core, the server and the client have started.**

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

**Ready means hand it over.** Until then the verdict says who is holding it: a
decision only you can make, evidence nobody here can produce, or drafting that is
still mine to do. v3.4 settled the screens' last gate (C37: the scout shows no
patrol positions), and handed the realms' one to this repository: §32.9's full
economy re-run. That run is done, so the realms now wait on the document taking
its tables.

**v3.7 writes every decision in.** The owner's 47 recorded answers are now in
the document (§32.8 lists them), and each of the 46 decisions still open takes
the option its brief recommended — settled by the document's own rule, not
answered by the owner, and the brief shows the two apart. Its balance pass
changes the game: wards 8, 8, 6, 2 and 0 by realm level on 1, 1, 2, 1 and 1
posts, with guards at realm levels 1 to 3 tuned by §12.17's realm's watch, now
built in the simulation and the harness (every level holds 30 to 45% in the
harness); one raider-success band of 55 to 70%; raw replays kept 90 days; and a
write budget per kind of player. Read item by item by six readers, v3.7 closes
87 of the 139 items open against v3.6, settles the document under 42 more whose
build remains, and partly settles ten; reading it against itself and the build
found 25 new items, almost all with their edit drafted (roadmap TD.75), and one,
C58, that the re-run figures it quotes match no single run (TD.72).

**v3.6 records the owner's designs.** Screens v3, made in Claude Design, holds
28 designed screens, 43 character and creature sheets with 3D models and 393
icons, and §23.5 makes it the visual reference with the document winning on every
rule. v3.5 moved the engine pin to Godot 4.7.2 (measured here: the client passes
all its tests on 4.7.2 after one change). Read screen by screen against v3.6 and
the build by twelve readers, each finding tried by an adversarial verifier, the
designs depart from a rule or the build in about 190 places §23.5 does not list
(the register's v3.6 layer, and
[`docs/analysis/screens-v3/`](docs/analysis/screens-v3/README.md)); the plan to
build them is the roadmap's stage SD. The owner then handed over the design
itself, and reading it against the repository added four register items, four
decisions and two tasks in stage SD; folding it in found two more items, v3.6
against itself, each a decision
([`docs/analysis/screens-v3/handoff/`](docs/analysis/screens-v3/handoff/README.md)).
v3.6 itself answers none of the 70 items open against v3.4, narrows G28 and F37,
and reopens C11.

Seven versions have now answered the audit. **199 of 328 register items are fixed**,
in the document itself or, for D71, by the build; the latest 87 by v3.7. 85 are
still open: 48 of the 139 open against v3.6 (38 waiting on the build, ten partly
done with their edits drafted) and 37 of the 38 found reading v3.7 or building
against it.

v3.4 answers the seventeen items open against v3.3, and fifteen close. Each was
checked by section and line, not taken from its own list. The two that do not
(C19, C35) wait on the same economy re-run. Its two rule changes are ported to
`sim/` and the harness: cracking calls only the guards within 5 m of the Vault
by the walking path, and a ward ignores the crew member disarming it.

Running the sweep v3.4 names for the crack's reach found **F35**: the rule cannot
choose a reach, because with no call at all the depth gate already fails from
two realms up and every realm level holds far above its band — and against the
no-call baseline, the 5 m shipped takes the optimal crew's lead over the
careless one from +42 points to +4 (n=200). The design hears every hit within
5 m anyway, so the question is really whether cracking is heard at all. Porting
also found **G18** (a ward ignores its disarmer on the tile, not on the walk
into a Well's or a Glare's reach), **C40** (a sentence §31.3's own change made
false) and **D59**, the harness's own: its optimal crew was disarming what v3.3
made a fifteen-second job and playing below the competent crew.

Still open from v3.3, and not in v3.4's list because they came after its
snapshot: **F33** (one Lantern Glare outweighs a realm of other wards), **F34**
(§13.2's hold table was measured at one guard post; at §5.2's posts realms 3 to
5 hold 91 to 99.5%) and **G17** (four settlement terms the server needs).

**The full economy re-run is done** (T2.6), at
[`docs/design/generated/pacing.md`](docs/design/generated/pacing.md): §9.3,
§10.2's day columns, all 40 Keeper levels, §14.3's milestones, §5.2's realm
levels and §5.5's capacities, each at both edges of §9.6's band. The model was
first ported to v3.3's raid pay (D58, done), and then **reviewed
adversarially**: each claim attacked by one agent and re-checked by an
independent judge. Every number reproduced, but several rested on choices the
document never makes, so the run was rebuilt on what the review found — the
document's storage caps, entry fee, strays, school-only bonuses and Codex
chapters are in it now — and every open choice is printed beside the tables
with what the alternative moves.

The curve is much slower than the tables it replaces: an engaged player reaches
Keeper 40 on day 349–357 (the target curve says 179) and has everything built
on day 699–719 (§14.3 says 378). The findings:

- **G22** — §14.1 names no staffing order, no realm order and no rule on
  staffing posts, and each moves the tables by months (Keeper 40 anywhere from
  day 337 to 385 on realm order alone).
- **F38** — strays fill the roster as fast as homes are built, so §9.5's rule
  has no birth rate to set.
- **F39** — the entry fee is 2% of what a player holds, so a player saving for
  the Spire, as §14.1 says, pays about eight times more in fees than raids
  bring.
- **F36** — run on the model's roster the raid-worth check fails 2,400, but the
  base it needs depends on those same open choices.
- **F37** — a player who never raids stops levelling below Keeper 12, so never
  reaches the full Codex §14.4 prices for them.
- **C41**, **C42** — the fee's return and the stray rate are each stated two
  ways; **G19** — the Heart has no ward or post count.

The backend has started (T3.3). An island is now a content-addressed bundle
that the simulation loads and checks against §5.2 and §6.1. A replay pins the
island's hash and a rules version the build computes from its own behaviour.
[`server/`](server/README.md) is §24.12's lease, validate and grant as edge
functions over §24.8's tables: it re-simulates each heist in the same
WebAssembly build, settles the entry fee and §9.6's haul in one transaction,
and never pays a retry twice. It enforces §9.6's three caps (a raid, a day and a
week), and building them found **G20**: the caps do not say which unit they are
in, and under the server's reading no player type §14.1 models ever reaches one.
The review also found **D60**: a bundle's Vault level and exposed loot are the
client's word until the economy is server-side. Target lists are §24.8's static files, one a band (**G21**:
neither the band nor how often a list is rebuilt is defined). And the 54
law-shaped forms of §11.10 are now validated content.

The frontend has started (T3.4). [`client/`](client/README.md) is a Godot 4.7.2
project with `sim/` linked in as a Rust GDExtension, as §24.7 plans. A heist
can be played on it — every tap becomes a command stamped with its tick,
recorded as the replay a device queues and checked as the server checks it —
and watched: the replay screen re-simulates a heist a tick at a time and every
second checks its own checksum against the replay's. All five golden replays
agree at every second, so the client runs the server's rules, not a copy of
them. Against `server/` the loop is whole: the client leases a target from the
lists, plays it, submits, and the server re-simulates the replay and pays. It is
a desktop build for now; the phone builds are §24.7's spike. The look is a
stand-in: the diorama of §21 is the art pass.

v3.0 also changed the
plan: both pre-code player tests are gone, replaced by the simulation harnesses
in §19.27, and the build-willingness risk is designed out rather than measured
(§13.3).

v3.1 changed the plan less than its size suggests and changed how much of the
document can be trusted more. It adds §31 — a build checker, constants pinned
in data, generated blocks hashed — and closes four numbering holes v3.0 left.
It is the first version whose fixes were checked here rather than taken from
its own list, and the checking is what found F24 and F25, neither of which
that list mentions.

What v3.0 did not finish is the same shape as what it fixed: four of those six
fixes left a stale copy standing, and §29.1 — the formulas appendix — still
tabulates the detection model §12.8 deleted, citing §12.8 as its source. See
[`docs/design/generated/v3-response.md`](docs/design/generated/v3-response.md),
which is generated from the register so it cannot drift.

Live progress: **https://claude.ai/artifact/Yb1WxZ2eJCCbByitnd7fJf** — every
stage, what finishes it, and who it is waiting on, generated from
[`tools/roadmap.py`](tools/roadmap.py) with progress computed from the audit
register rather than claimed. At its top are two numbers, to two decimals: how
close the app is to built on the **backend** and on the **frontend**, weighed by
§26.8's own cost of each build phase and counted only through passing tests
([`tools/completion.py`](tools/completion.py)).

The game is fully designed in `docs/design/`. The first step was a deep analysis
of that design, which is in `docs/analysis/`.

Nothing should be built until the stage 0–3 work in
[`docs/analysis/07-recommended-next-steps.md`](docs/analysis/07-recommended-next-steps.md)
is done. In short:

0. The §19.27 harnesses — **built** ([`tools/heist_harness/`](tools/heist_harness/README.md)).
   Three of §19.27's four thresholds pass; the fourth, and two other findings,
   are F7–F9. The browser prototype
   ([`prototypes/heist-gate/`](prototypes/heist-gate/README.md)) is superseded
   but stays published: it is the only artefact here that can answer the question
   §19.27 says simulation cannot
1. Finish the fixes v3.0 started — retiring the superseded copies is the work,
   not restating the decisions
2. ~~Rebuild the economy model~~ — **done**, `tools/economy_model/`
3. The determinism spike — **two of four targets done** ([`sim/`](sim/README.md)): native x86-64 and WebAssembly agree bit for bit over a 240-second heist at five seeds, and on the validator's verdict. A real iPhone and a real Android are the rest of the gate. The server that runs the WebAssembly half is started ([`server/`](server/README.md), T3.3)
4. A launch-scope decision

## Repository layout

```
docs/
  design/     the design document at v3.7, with every earlier version beside it, plus greppable extracts
  analysis/   the deep analysis of that document — start here
content/       the twelve content tables as data, plus the reconciled detection spec
docs/design/spec/   the reconciled specification, one file per system
docs/design/dependencies.md  what has to be settled before what, generated
docs/audit/    the generated audit register page
docs/roadmap/  the generated roadmap page
prototypes/
  heist-gate/  a throwaway browser build that runs both pre-code gates
sim/            the heist simulation core in Rust: determinism spike (T3.1), replays (T3.2), pathfinding, sight, noise, guard states, island bundles and the validator (T3.3)
server/         the edge functions of §24.1: lease, validate, grant, over §24.8's tables (T3.3)
client/         the Godot 4.7.2 client, with sim/ as a GDExtension: the replay screen (T3.4)
tools/
  extract_design_doc.py           HTML -> greppable text
  check_document.py               every check over the document, in one verdict
  check_design_consistency.py     the design half, which check_document.py runs
  vendor/                         v3.1's own checker, kept unmodified to diff against
  extract_content.py              design document -> content/*.json
  validate_content.py             schema and cross-reference checks on content/
  compare_module.py               the prototype's data module against content/, by hash, read as text
  generate_docs.py                content/ -> the design document's summary tables
  check_docs_consistency.py       this repository's own documents, against each other
  decision_support.py             prices the decisions that are the owner's
  audit_register.py               the audit register, as data
  build_audit.py                  renders the register to docs/audit/index.html
  check_audit_ui.py               the audit page's tabs, bars and chips, against the register
  build_brief.py                  the owner's decision brief to docs/decisions/index.html; --check
  check_edits.py                  every drafted edit quotes the document correctly
  check_dependencies.py           the ordering between items; writes dependencies.md
  check_findings_fresh.py         which register numbers can be shown to be current
  scope_cut.py                    costs a launch-scope cut by engine work
  build_stamp.py                  one build stamp for every published page
  law_effects.py                  classifies all 48 laws against the rule sheet
  note_rebalance.py               the note rebalance §8.8 says is already done
  roadmap.py                      the roadmap, as data
  build_roadmap.py                renders it, computing progress from the register
  client_strings.py               writes client/i18n/content.csv, the content's names, from content/
  native_strings.py               writes the phones' notification tables, iOS and Android, from client/platform/notifications.csv
  english_us.py                   writes US English from British English by a spelling table, in the catalogues and the island words
  client_contract.py              the client's server routes and failure words, checked against server/src/http.mjs
  privacy_manifest.py             writes the iPhone build's privacy manifest from server/privacy.json
  league_model.py                 fits the league boundaries to §14.7's shares; writes server/src/leagues.json
  completion.py                   how close the app is to built, backend and frontend, from §26.8's costs and passing proofs
  parse_gate_results.py           scores the gates from testers' result codes
  build_prototype.py              renders the throwaway browser build of the two pre-code gates
  check_prototype_conformance.py  the prototype implements the rules it claims to
  economy_model/                  the day-by-day model §24 references but omits
  heist_harness/                  §19.27's simulation harnesses, built in v3.0's plan
  generator_settings.py           sweeps the generator against both bands the document sets
  post_ladder.py                  whether a steeper guard-post ladder closes F26's gap or moves it
  ward_budget.py                  whether F26's ward budget lands every realm in both bands
  law_ranks.py                    prices C3's three rank splits, and tests §7.9's rule against the sheets
  ability_text.py                 C6's 18 ability pairs: which differ by how much, and which by what they do
  check_unread_fields.py          every field the harness computes is read somewhere
  design_doc.py                   which design document every check reads, in one place
  design_facts.py                 the facts the document states, for the tools that read them
  mutation_gate.py                §31.5's fifteen breakages, and the same defects said differently
  twice_stated.py                 facts the document states in more than one section
  inventory_homes.py              every section stating a launch-inventory count, and what checks it
  version_diff.py                 what one version of the document changed, section by section
```

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

## Checks

```bash
./tools/check_all.sh
```

Runs every check in dependency order. Non-zero exit means something is wrong;
known contradictions in the design document are reported but do not fail, and
that list shrinks as the document is reconciled.

## Tools

```bash
# regenerate the greppable text extract from the HTML design document
python3 tools/extract_design_doc.py \
    docs/design/ruleborn-game-design-v3.7.html \
    docs/design/ruleborn-game-design-v3.7.txt

# machine-check the design document: v3.1's own checks and this repository's,
# in one verdict. Failures tracked by an open register item do not break the build.
python3 tools/check_document.py
python3 tools/check_document.py --coverage    # every v3.1 check is still covered
python3 tools/check_document.py --self-test   # the derived checks catch what a phrase ban cannot

# economy model: reports and tests
python3 -m tools.economy_model
python3 -m tools.economy_model.test_economy_model

# run §19.27's harnesses: tension, depth, defence balance, attribution
python3 -m tools.heist_harness
python3 -m tools.heist_harness.test_harness

# score the two pre-code gates from testers' result codes (superseded in v3.0)
python3 tools/parse_gate_results.py results.txt

# price the open decisions
python3 tools/decision_support.py

# rebuild the audit register page after changing an item's status
python3 tools/build_audit.py

# content tables: extract from the document, then validate
python3 tools/extract_content.py
python3 tools/validate_content.py
# the prototype's data module against content/ (the module is not kept here)
python3 -I tools/compare_module.py PATH/TO/ruleborn-data.js
```

## The audit register

Everything that changed about the plan and everything still to fix in the design
document, as 328 tracked items with section references and status:
**https://claude.ai/artifact/8m5MgpjWfFurnfwc6b76sN**

Each item carries **the edits to make in the document**: the section to open,
the sentence as it stands today, and what to put there. 243 are drafted across 110
items, and every quoted sentence is checked against v3.7 by
`python3 tools/check_edits.py`, which fails the build if one is not there or
appears twice — because an edit naming a sentence nobody wrote is worse than no
edit at all.

The register lives in `tools/audit_register.py`; the page is generated by
`python3 tools/build_audit.py`. Change an item's status in the register and
rebuild — never edit the generated HTML.

## Decisions

Every register item that only the owner could settle, as a question with its
options, their numbers, what the build does today and a recommendation, in
the order to decide them: **https://claude.ai/artifact/YZcD1uH5xtpFznqncRpt8g**

**47 are answered** (25–26 September 2026): eight picked on the page, one in
the owner's own words, the rest accepted as recommended; v3.7 writes all of them
in. **46 are settled by v3.7**, which takes the option each brief recommended:
the page shows them apart from the owner's answers, with where v3.7 wrote each,
and each can still be overruled there. **None is open.** The answers are on the page and in
`docs/decisions/answers.json`, with where each one's build change stands; the
audit shows a decided item as waiting on that build change, then on the
document. A new decision is picked on the page, where it is saved, and Claude
reads it back and turns it into a register, document or build change. The brief is
`docs/decisions/brief.json`, drafted, checked from two sides and merged by a
multi-agent pass; `python3 tools/build_brief.py` writes the page, and its
`--check` (run by `tools/check_all.sh`) fails if a quote stops matching the
document, a recommendation names no option, or an open decision has no entry.

## The roadmap

Every stage of the build, what finishes it, and who it is waiting on:
**https://claude.ai/artifact/Yb1WxZ2eJCCbByitnd7fJf**

It reads from the register, so the two pages cannot disagree. Two things on it
are deliberate: **drafted is not signed off** — the two bars are separate
colours for that reason, and the design document itself is still untouched — and
**"waiting on you" is at the top**, because the most useful thing a roadmap can
say is which items nobody else can move.

The roadmap lives in `tools/roadmap.py`; the page is generated by
`python3 tools/build_roadmap.py`, which refuses to build a roadmap that
contradicts itself. See [`docs/roadmap/README.md`](docs/roadmap/README.md).

## The prototype

A playable four-minute test of the two riskiest premises is published at
**https://claude.ai/artifact/3jW7Zg1rTrzR6CF3cEVp2E** — see
[`prototypes/heist-gate/README.md`](prototypes/heist-gate/README.md) for how to
run it, who to send it to, and how to read the results.
