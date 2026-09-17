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

**Do not edit these files.** They are someone else's source of truth. When the
two checkers are merged (roadmap T1.11), the merge happens on our side.
