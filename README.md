# Ruleborn

> Your islands. Your rules. Their treasure.

A strategy game about floating islands that each follow a magic rule. You collect
these rules, build your islands around them, and send a small crew of odd little
creatures to rob other players' islands by outsmarting theirs.

Native mobile (iPhone and Android), Godot 4.5, rated 13+, cosmetic-only
monetisation.

## Status

**Pre-production — design document at v3.2, no code yet.**

### Can the drawing start?

An area is ready to hand to whoever will draw it when nothing still open decides
something they would otherwise have to guess. The audit page computes this from
the gates themselves — it cannot read "Ready" while one is open — and shows it in
a band at the top.

| Area | Verdict | Waiting on |
| --- | --- | --- |
| **Realms** | Waiting on you | your decision: F26, F27, F22, F9, F11, F12, G3, G5, C19 |
| **Screens** | Waiting on you | your decision: C6 |
| **Characters** | Waiting on you | your decision: D6; needs outside evidence: Q5 |

**Ready means hand it over.** Until then the verdict says who is holding it: a
decision only you can make, evidence nobody here can produce, or drafting that is
still mine to do.

Two versions have now answered the audit. **42 of 140 register items are fixed
in the document itself** — 26 by v3.0 and 9 more by v3.1. v3.0 also changed the
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
register rather than claimed.

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
3. The determinism spike — **two of four targets done** ([`sim/`](sim/README.md)): native x86-64 and WebAssembly agree bit for bit over a 240-second heist at five seeds. A real iPhone and a real Android are the rest of the gate
4. A launch-scope decision

## Repository layout

```
docs/
  design/     the design document at v3.2, with v3.0 and v2.3 beside it, plus greppable extracts
  analysis/   the deep analysis of that document — start here
content/       the twelve content tables as data, plus the reconciled detection spec
docs/design/spec/   the reconciled specification, one file per system
docs/design/dependencies.md  what has to be settled before what, generated
docs/audit/    the generated audit register page
docs/roadmap/  the generated roadmap page
prototypes/
  heist-gate/  a throwaway browser build that runs both pre-code gates
sim/            the heist simulation core in Rust: determinism spike (T3.1), replays (T3.2), pathfinding, sight, noise, guard states
tools/
  extract_design_doc.py           HTML -> greppable text
  check_document.py               every check over the document, in one verdict
  check_design_consistency.py     the design half, which check_document.py runs
  vendor/                         v3.1's own checker, kept unmodified to diff against
  extract_content.py              design document -> content/*.json
  validate_content.py             schema and cross-reference checks on content/
  generate_docs.py                content/ -> the design document's summary tables
  check_docs_consistency.py       this repository's own documents, against each other
  decision_support.py             prices the decisions that are the owner's
  audit_register.py               the audit register, as data
  build_audit.py                  renders the register to docs/audit/index.html
  check_audit_ui.py               the audit page's tabs, bars and chips, against the register
  check_edits.py                  every drafted edit quotes the document correctly
  check_dependencies.py           the ordering between items; writes dependencies.md
  check_findings_fresh.py         which register numbers can be shown to be current
  scope_cut.py                    costs a launch-scope cut by engine work
  build_stamp.py                  one build stamp for every published page
  law_effects.py                  classifies all 48 laws against the rule sheet
  note_rebalance.py               the note rebalance §8.8 says is already done
  roadmap.py                      the roadmap, as data
  build_roadmap.py                renders it, computing progress from the register
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

Full detail: [`docs/design/ruleborn-game-design-v3.2.html`](docs/design/ruleborn-game-design-v3.2.html).

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
    docs/design/ruleborn-game-design-v3.2.html \
    docs/design/ruleborn-game-design-v3.2.txt

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
```

## The audit register

Everything that changed about the plan and everything still to fix in the design
document, as 140 tracked items with section references and status:
**https://claude.ai/artifact/8m5MgpjWfFurnfwc6b76sN**

Each item carries **the edits to make in the document**: the section to open,
the sentence as it stands today, and what to put there. 94 are drafted across 56
items, and every quoted sentence is checked against v3.2 by
`python3 tools/check_edits.py`, which fails the build if one is not there or
appears twice — because an edit naming a sentence nobody wrote is worse than no
edit at all.

The register lives in `tools/audit_register.py`; the page is generated by
`python3 tools/build_audit.py`. Change an item's status in the register and
rebuild — never edit the generated HTML.

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
