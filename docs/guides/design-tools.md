# The design side: document, register, decisions, roadmap

Half of this repository is about the game's design document rather than the
game's code: checking it, tracking what is wrong with it, preparing the
owner's decisions, and planning the build. This guide is how those pieces fit
and how to change each one. The pages they produce are linked from the
[README](../../README.md#live-pages).

## The pieces

```
docs/design/ruleborn-game-design-v3.7.html   the design document (the owner's; never edited here)
        │ tools/extract_design_doc.py
        ▼
docs/design/ruleborn-game-design-v3.7.txt    greppable text every check reads
        │
        ├─ tools/check_document.py ─────────▶ contradictions found, each tied to a register item
        ├─ tools/extract_content.py ────────▶ content/*.json ─▶ tools/validate_content.py
        │                                                    └▶ tools/generate_docs.py ─▶ docs/design/generated/
        └─ tools/design_facts.py ───────────▶ the document's constants, for every tool and server/src/facts.json

tools/audit_register.py  (the register: every item, its status, its drafted edits)
        ├─ tools/build_audit.py ────────────▶ docs/audit/index.html      (the audit page)
        ├─ tools/check_dependencies.py ─────▶ docs/design/dependencies.md
        └─ tools/roadmap.py + build_roadmap.py ▶ docs/roadmap/index.html (the roadmap page)

docs/decisions/brief.json ─ tools/build_brief.py ▶ docs/decisions/index.html (the decision brief)
docs/decisions/answers.json  the owner's recorded answers (the owner's file)
```

## The design document

- `docs/design/ruleborn-game-design-v3.7.html` is the current version, and
  `.txt` its extracted text. Earlier versions (v2.3, v3.0 to v3.4, v3.6) sit
  beside it on purpose, for diffs and for the archive; there is no v3.5 file.
- **Which version the checks read is declared once**, in
  `tools/design_doc.py` (`VERSION`). Moving to a new version means adding its
  HTML, extracting its text, moving that one constant, and running
  `check_all.sh`; `check_docs_consistency.py` refuses a newer document that
  nothing reads, and any tool that names a versioned filename itself.
- `python3 tools/version_diff.py` shows what one version changed, section by
  section.
- **Citations.** In this repository, "§N.M" always means a section of the
  design document, and must name a section of the current version (see
  [checks.md](checks.md#what-the-documentation-check-holds-you-to)).

```bash
python3 tools/extract_design_doc.py \
    docs/design/ruleborn-game-design-v3.7.html \
    docs/design/ruleborn-game-design-v3.7.txt
python3 tools/check_document.py              # one verdict over the document
```

## The audit register

Every contradiction (C), gap (G) and quantitative finding (F) found in the
document, every deviation (D: a change to the plan) and the decisions (Q), with its section references,
status and **the edits to make**: the section, the sentence as it stands and
what to put there. It lives in `tools/audit_register.py` as Python data.

- **To change an item**, edit `tools/audit_register.py` and run
  `python3 tools/build_audit.py`. Never edit `docs/audit/index.html` by hand.
- **Drafted edits are checked**: `python3 tools/check_edits.py` fails if an
  edit quotes a sentence the document does not contain, or contains twice.
- **An item's effective status** (its own, or what v3.0 or v3.1 recorded) is
  worked out only by `audit_register.status`; no other tool may compute it.
- The ordering between items is `docs/design/dependencies.md`, written by
  `python3 tools/check_dependencies.py --write`.

## The decision brief

The register items only the owner can settle, each as a question with its
options, their numbers, what the build does today and a recommendation, in the
order to decide them.

- The brief is `docs/decisions/brief.json`; the page is written by
  `python3 tools/build_brief.py`, and `--check` fails if a quote stops
  matching the document or a recommendation names no option.
- The owner answers on the published page, which saves each answer;
  `docs/decisions/answers.json` is the record of answers and belongs to the
  owner. An answer is then turned into a register, document or build change.
- Smaller decisions that belong to one track (a refresh-token setting, a
  choice of look) are listed on that track's progress file under "Owner
  decision needed", not in the brief.

## The roadmap

Every stage of the build, what finishes it, and who it waits on.
`tools/roadmap.py` holds it as data; `python3 tools/build_roadmap.py` renders
`docs/roadmap/index.html` and refuses a roadmap that contradicts itself.
Progress is computed from the register and from passing tests, never typed:
`tools/completion.py` weighs each build phase by the document's own cost of it
(§26.8) and counts only phases whose proofs pass (`sim/status.json`,
`server/status.json`, `client/status.json`). How to read it:
[`docs/roadmap/README.md`](../roadmap/README.md).

## Content tables

`content/*.json` is the design's content as data (laws, notes, resonances,
chords, terrain, ruleborn, forms, roles, detection …). Extracted from the
document by `python3 tools/extract_content.py`, validated against it by
`python3 tools/validate_content.py`. The simulation's law table and the
client's content names are generated from it. See
[`content/README.md`](../../content/README.md).

## The specification

`docs/design/spec/` is the drafted, buildable resolution of each system the
document left contradictory or unspecified, one file per system, each
**proposed** until the document adopts it. Its index is
[`docs/design/spec/README.md`](../design/spec/README.md); the check keeps the
index and the directory in step, and keeps each file's "Still open" list to
items the register has open.

## The analysis and the models

- `docs/analysis/01–07` is the first deep read of the document, at v2.3. It is
  an archive: its section numbers are v2.3's. Its findings live on in the
  register. See [`docs/analysis/README.md`](../analysis/README.md).
- `docs/analysis/screens-v3/` reads the owner's screen and character designs
  (Screens v3) against the document and the build.
- `tools/economy_model/` is the day-by-day economy model the document
  references but omits; `tools/heist_harness/` is §19.27's simulation
  harnesses. Their READMEs say how to run them
  ([economy model](../../tools/economy_model/README.md),
  [heist harness](../../tools/heist_harness/README.md)).

## Commands

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

# what the latest version changed, and which register items sit on it
python3 tools/version_diff.py
python3 tools/version_diff.py --items

# economy model: reports and tests
python3 -m tools.economy_model
python3 -m tools.economy_model.test_economy_model

# run §19.27's harnesses: tension, depth, defence balance, attribution
python3 -m tools.heist_harness
python3 -m tools.heist_harness.test_harness

# price the open decisions
python3 tools/decision_support.py

# rebuild the pages after changing the register, the brief or the roadmap
python3 tools/build_audit.py
python3 tools/build_brief.py
python3 tools/build_roadmap.py

# content tables: extract from the document, then validate
python3 tools/extract_content.py
python3 tools/validate_content.py

# score the two pre-code gates from testers' result codes (superseded in v3.0)
python3 tools/parse_gate_results.py results.txt
# the prototype's data module against content/ (the module is not kept here)
python3 -I tools/compare_module.py PATH/TO/ruleborn-data.js
```
