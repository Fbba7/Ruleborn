# The judge's prompts

Rubric version 2 (`../rubric.md`). One prompt per judged quality (section 3.5 of
`report.md`). Qualities 4, 5, 7, 10, 11 and 12 have no prompt: they are
scripted or the owner's, because a still cannot show them or a script measures
them better.

| # | Quality | Prompt | Asset classes judged |
|---|---|---|---|
| 1 | Layered materials | [01-layered-materials.md](01-layered-materials.md) | kit art, icon, screen |
| 2 | Display type | [02-display-type.md](02-display-type.md) | kit art, screen |
| 3 | Painted or rendered icons | [03-icons.md](03-icons.md) | icon, screen |
| 6 | Hierarchy | [06-hierarchy.md](06-hierarchy.md) | screen |
| 8 | Colour roles and value | [08-colour-value.md](08-colour-value.md) | kit art, icon, screen |
| 9 | Character presence | [09-character.md](09-character.md) | screen |
| 13 | Light behind UI | [13-light.md](13-light.md) | kit art, icon, screen |
| 14 | One art-direction idea | [14-one-idea.md](14-one-idea.md) | screen |

## How the launcher uses them

1. Each call is one isolated session on the judge's model, on read-only tools
   (`.claude/agents/ui-judge.md`), with no access to the maker's notes,
   progress files or reasoning.
2. The launcher fills the fields: `{{item}}` (the item's name),
   `{{class}}` (its asset class) and `{{pictures}}` (one line per picture:
   its path in the repository and its role, CANDIDATE, PASS ANCHOR or FAIL
   ANCHOR, followed by its crops). The anchors are the golden set's items for
   that quality and asset class (`../golden/`, from P0-AD-golden).
3. It makes the call three times, shuffling the order of the pictures each
   time, and records the three answers as the verdict's `samples`. Three
   passes pass, three fails fail, a split takes three more samples (4 or more
   fails out of 6 is a fail), and an UNKNOWN goes to the exceptions queue
   (section 3.5 of `report.md`).
4. Before a quality is calibrated (`../calibration.md`), its verdicts are
   recorded in shadow mode and block nothing.

Every edit to a prompt is an edit to the rubric: it bumps the rubric's
version and is re-measured on the held-out third.
