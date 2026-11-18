# Blind audit 2 (phase 3's exit)

The second blind audit of the UI gate (report.md section 3.4, O6 at the
wave's end, and section 3.5, item 6; phase 3's exit, report.md section
6). The lead drew this sample on 18 November 2026, in lead cycle 141,
from the gate's verdicts on the screens, leaving out every item blind
audit 1 drew:

- the items it passed: every phase 3 screen item the gate passed on every
  quality (phase 2's passes were blind audit 1's pool);
- the items it failed: every screen item, of any phase, that it failed on
  at least one quality.

The draw used `audit()` of `tools/ui_gate/calibrate.py`, seed
`phase-3-exit`, 12 passes (all phase 3 has) and 4 fails, on the verdict
files under `gate/verdicts/` filtered as above. The sample holds 16
items, shuffled. Which is which is not written here.

## Rules for the labeller

- **Be a fresh AD session that has not seen the verdicts.** Do not open
  `gate/verdicts/`, the boards' verdict lines, the "Gate" paragraphs of
  `docs/progress/requests.md`, or the lead's progress notes until every
  row below is labelled and pushed.
- **Render each item at its commit.** Check the commit out in a separate
  worktree (`git worktree add /tmp/audit-<sha> <sha>`) and render the
  item's still with `bash tools/render/shoot.sh` and the screen's shot
  script in `client/tests/shots/` (`screen_heist.gd`, `screen_result.gd`,
  `universe_home.gd`, `screen_character.gd`, `screen_settings.gd`, or what
  that commit used), with `TEXT=200 LOCALE=<locale>` for a 200% item and
  `CONTRAST=1` for a high-contrast one. Judge the still
  at phone size and at 1x, then zoomed in, against the rubric
  (`gate/rubric.md`) and the key frames, on the golden set's form
  (`gate/golden/labels.md`, "How to fill it in").
- **Label:** `pass`, `fail` or `n/a`, with a one-line critique in the
  rubric's words.
- When every row is labelled, the lead scores the audit: every fail you
  give on an item the gate passed is a miss, and one miss on a judged
  quality pauses default merges for that quality (section 3.5, item 6).
  The labels then join the golden set.

## The form

| Task | Commit | Item | Quality | Label | Critique |
|---|---|---|---|---|---|
| P3-S2-home-7 | c58d49c0a07af5ebc5e2cc1c848ee1de626efce8 | home in high contrast | Hierarchy |  |  |
| P3-S3-nav-1 | 5ac311f77e8d174c0ddc5f48cadabfbad25e994f | character at 200% text, pt_BR | Hierarchy |  |  |
| P2-S2-home-1 | 71d51d7f | home at 100% text | Character presence |  |  |
| P2-S2-home-1 | 71d51d7f | home at 100% text | Display type |  |  |
| P2-S2-home-1 | 71d51d7f | home at 100% text | Hierarchy |  |  |
| P3-S2-home-7 | c58d49c0a07af5ebc5e2cc1c848ee1de626efce8 | home at 200% text, pt_BR | Hierarchy |  |  |
| P3-S1-hc-offline-1 | a4ed000edfcef3cde3ce3a926eb656efffcc2528 | result at 100% text | Character presence |  |  |
| P3-S1-result-7 | 55716273479b27992cdb57e8f5e5151921d31d6f | result at 200% text, pt_BR | Hierarchy |  |  |
| P3-S2-home-7 | c58d49c0a07af5ebc5e2cc1c848ee1de626efce8 | home at 100% text | Display type |  |  |
| P3-S2-home-7 | c58d49c0a07af5ebc5e2cc1c848ee1de626efce8 | home at 100% text | Hierarchy |  |  |
| P1-K1-numerals-on | 1d21bf4a | heist at 100% text | Display type |  |  |
| P3-S2-back-1 | 0bfa1d6a3e794bdae4d65b68e9fdb0a2da4331dd | home at 100% text | Hierarchy |  |  |
| P3-S2-home-states | 84b0ee7ca9435ea2a880c7453e1c9f25be3482d5 | home at 100% text | Display type |  |  |
| P3-S2-home-states | 84b0ee7ca9435ea2a880c7453e1c9f25be3482d5 | home at 100% text | Hierarchy |  |  |
| P2-S3-character | f1251e68 | character at 200% text, pt_BR | Display type |  |  |
| P2-S3-character | f1251e68 | character at 200% text, pt_BR | Hierarchy |  |  |
| P3-S1-hc-offline-2 | 788eaaf4d5a46f9cde43ab603446e40b23665715 | heist in high contrast | Colour roles and value |  |  |
| P3-S2-home-states | 84b0ee7ca9435ea2a880c7453e1c9f25be3482d5 | home in high contrast | Hierarchy |  |  |
| P3-S2-home-states | 84b0ee7ca9435ea2a880c7453e1c9f25be3482d5 | home at 200% text, pt_BR | Hierarchy |  |  |
| P2-S3-character | 6f6a3b15 | character at 200% text, pt_BR | Display type |  |  |
| P2-S3-character | 6f6a3b15 | character at 200% text, pt_BR | Hierarchy |  |  |
| P3-S3-settings-3 | 7972485a7738ac5cea3f4ac762935d9f2522c1d7 | settings at 100% text | Hierarchy |  |  |
