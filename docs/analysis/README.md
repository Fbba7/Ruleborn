# Design analysis — Ruleborn v2.3

A deep read of `docs/design/ruleborn-game-design-v2.3.html`: 30 sections,
~85,600 words, 330 headings, 123 graded references, 12 commissioned evidence
reviews.

Start with `01-executive-summary.md`.

| Document | What it covers |
| --- | --- |
| [01-executive-summary.md](01-executive-summary.md) | The verdict, what the design gets right, the six things that must change before code, and where I disagree with the document |
| [02-system-map.md](02-system-map.md) | Every system, the dependency graph, the six couplings carrying the design's weight, and what is safe to defer |
| [03-contradiction-register.md](03-contradiction-register.md) | Every confirmed internal contradiction, with sections, cause and a recommended resolution for each |
| [04-specification-gaps.md](04-specification-gaps.md) | 11 things referenced but never specified — what a builder would have to invent |
| [05-quantitative-findings.md](05-quantitative-findings.md) | The three economy-model findings (F1–F3), the arithmetic that checks out, the arithmetic that doesn't, and the note/chord/cost distribution analysis |
| [06-build-readiness.md](06-build-readiness.md) | What is buildable today, what's blocked, the technical bet assessed, and an independent scope and risk read |
| [07-recommended-next-steps.md](07-recommended-next-steps.md) | Ordered actions, the two decisive gates first |

## Reproducing the findings

```bash
# regenerate the greppable text from the HTML export
python3 tools/extract_design_doc.py \
    docs/design/ruleborn-game-design-v2.3.html \
    docs/design/ruleborn-game-design-v2.3.txt

# re-run the document consistency checks
python3 tools/check_design_consistency.py docs/design/ruleborn-game-design-v2.3.txt

# re-run the economy model's reports and its tests
python3 -m tools.economy_model
python3 -m tools.economy_model.test_economy_model
```

`check_design_consistency.py` confirms ten findings and passes seven other
checks. The economy model's twelve tests assert both that it still reproduces the
document where the document is self-consistent, that findings F1–F3 still hold,
and that the payout peg proposed in `spec/economy.md` behaves as that page
claims. Run both against any later version of the document to see what stands.

## Method and limits

Every section of the document was read. Numeric claims were re-derived where the
document gives a formula; content counts were parsed from the document itself
rather than taken from its summary tables — which is how the law-rarity,
ruleborn-roster and note-distribution findings surfaced.

The document's economy model (§24) is not in the document, so it was rebuilt from
the published formulas (`tools/economy_model/`). It reproduces the first month to
within 10% and the Keeper curve to within three days; findings F1–F3 came out of
the places where it could not be made to match at all.

What this analysis cannot tell you: whether the game is fun. The document is
clear-eyed about that too (§19.1, §30.8) and has designed the right tests for it.
Those tests are stage 0 of `07-recommended-next-steps.md`, re-planned there for a
solo developer without a test cohort.

## The audit register

The working view of this analysis — what changed about the plan, and what is
still to fix — is tracked at
**https://claude.ai/artifact/8m5MgpjWfFurnfwc6b76sN**, generated from
`tools/audit_register.py`. These documents carry the reasoning; the register
carries the state.
