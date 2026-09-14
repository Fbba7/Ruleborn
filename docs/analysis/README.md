# Design analysis — Ruleborn v2.3

A deep read of `docs/design/ruleborn-game-design-v2.3.html`: 30 sections,
~85,600 words, 330 headings, 123 graded references, 12 commissioned evidence
reviews.

Start with `01-executive-summary.md`.

| Document | What it covers |
| --- | --- |
| [01-executive-summary.md](01-executive-summary.md) | The verdict, what the design gets right, the five things that must change before code, and where I disagree with the document |
| [02-system-map.md](02-system-map.md) | Every system, the dependency graph, the six couplings carrying the design's weight, and what is safe to defer |
| [03-contradiction-register.md](03-contradiction-register.md) | 17 confirmed internal contradictions, with sections, cause and a recommended resolution for each |
| [04-specification-gaps.md](04-specification-gaps.md) | 11 things referenced but never specified — what a builder would have to invent |
| [05-quantitative-findings.md](05-quantitative-findings.md) | The arithmetic that checks out, the arithmetic that doesn't, and the note/chord/cost distribution analysis |
| [06-build-readiness.md](06-build-readiness.md) | What is buildable today, what's blocked, the technical bet assessed, and an independent scope and risk read |
| [07-recommended-next-steps.md](07-recommended-next-steps.md) | Ordered actions, free tests first |

## Reproducing the findings

```bash
# regenerate the greppable text from the HTML export
python3 tools/extract_design_doc.py \
    docs/design/ruleborn-game-design-v2.3.html \
    docs/design/ruleborn-game-design-v2.3.txt

# re-run every mechanical check behind this analysis
python3 tools/check_design_consistency.py docs/design/ruleborn-game-design-v2.3.txt
```

`check_design_consistency.py` currently confirms six findings and passes eight
other checks. Run it against any later version of the document to see which
findings still stand.

## Method and limits

Every section of the document was read. Numeric claims were re-derived where the
document gives a formula; content counts were parsed from the document itself
rather than taken from its summary tables — which is how the law-rarity,
ruleborn-roster and note-distribution findings surfaced.

What this analysis cannot tell you: whether the game is fun. The document is
clear-eyed about that too (§19.1, §30.8) and has designed the right tests for it.
Those tests are stage 0 of `07-recommended-next-steps.md`, and they cost nothing.
