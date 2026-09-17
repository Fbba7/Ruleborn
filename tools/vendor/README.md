# The document's own tooling, as shipped with v3.1

`check.py`, `generate.py` and `mutate.py` are **not this repository's work**.
They arrived with version 3.1 and are kept here unmodified so that what v3.1
claims about itself can be re-run rather than believed.

`../../content/upstream/` holds the data they read — `constants.json` and
`creatures.json` — for the same reason.

Run it against the built document:

    cd tools/vendor && mkdir -p data \
      && cp ../../content/upstream/*.json data/ \
      && python3 check.py ../../docs/design/ruleborn-game-design-v3.1.html

All of its checks pass on v3.1. Two findings in this register are about what
they do not cover rather than what they get wrong — F24 and F25 — and neither
is an argument against the tooling, which is better than what this repository
had for the same job.

**Do not edit these files.** They are someone else's source of truth.

## The merge happened, and this stayed

`tools/check_document.py` now runs every check in this directory alongside this
repository's own, against one artefact, under one verdict (T1.11). These files
are kept anyway, for two reasons.

**They are the control.** `check_document.py --coverage` names each of the 28
checks here and the merged check that subsumes it, and fails if any stops being
covered. That comparison needs something to compare against, and a description
of the checks would not do — only the checks themselves.

**Three of them were re-implemented as something stronger rather than copied**,
and keeping the originals is what makes the difference legible. The clearest is
the page costs: this checker bans the phrase `15, 30 or 60 pages` and reports
green on v3.1, while 7.6 still says *"15 pages for a common law, 30 for a rare
one, 60 for a deep one"*. `check_document.py --self-test` plants that sentence
in a clean document and shows the two verdicts side by side. **A banned phrase
can prove a phrasing absent; it can never prove a model absent, and it reports
the stronger claim** (F24).
