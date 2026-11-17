# Blind audit 1 (O6, end of phase 2)

The first blind audit of the UI gate (report.md section 3.4, O6, and
section 3.5, item 6). The lead drew this sample on 17 November 2026, in
lead cycle 118, from the gate's verdicts on the screens (the pilot heist
and every phase 2 screen task), with:

    cd docs/art/ui-quality/gate/verdicts
    python3 ../../../../../tools/ui_gate/calibrate.py audit \
        P1-S1-pilot-*/*.json P2-*/*.json --seed phase-2-exit --passes 15 --fails 4

The sample holds 15 items the gate passed on every quality and 4 it
failed on at least one, shuffled. Which is which is not written here.

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
| P1-S1-pilot-2 | a4d87d18 | heist in high contrast | Colour roles and value |  |  |
| P1-S1-pilot-2 | a4d87d18 | heist in high contrast | Hierarchy |  |  |
| P2-S2-home-1 | 977edd5b | home at 200% text, pt_BR | Display type |  |  |
| P2-S2-home-1 | 977edd5b | home at 200% text, pt_BR | Hierarchy |  |  |
| P2-S3-settings-2 | 9e602fccafac7ffbb855e2049d8ad9db411805d2 | settings at 200% text, pt_BR | Display type |  |  |
| P2-S3-settings-2 | 9e602fccafac7ffbb855e2049d8ad9db411805d2 | settings at 200% text, pt_BR | Hierarchy |  |  |
| P2-S1-result-6 | b5843368999f64b956c2c1dd8db1e2a0ccbad049 | result at 100% text | Character presence |  |  |
| P2-S1-result-6 | b5843368999f64b956c2c1dd8db1e2a0ccbad049 | result at 100% text | Display type |  |  |
| P2-S2-home-6 | e674b614a15302227eb9ee9d5d8ba7e9cac8ce14 | home in high contrast | Hierarchy |  |  |
| P2-S2-home-3 | c9a89e5a4841f8f66fc9986560fbe455e61d2c58 | home at 100% text | Character presence |  |  |
| P2-S2-home-3 | c9a89e5a4841f8f66fc9986560fbe455e61d2c58 | home at 100% text | Hierarchy |  |  |
| P2-S3-character | f1251e68 | character in high contrast | Colour roles and value |  |  |
| P2-S3-character | f1251e68 | character in high contrast | Hierarchy |  |  |
| P2-S3-character-2 | 6b7e6b42 | character at 200% text, pt_BR | Display type |  |  |
| P2-S3-character-2 | 6b7e6b42 | character at 200% text, pt_BR | Hierarchy |  |  |
| P2-S2-home-4 | 1697a6c6675c22865eb28732ee50b410333a48de | home at 200% text, pt_BR | Display type |  |  |
| P2-S2-home-4 | 1697a6c6675c22865eb28732ee50b410333a48de | home at 200% text, pt_BR | Hierarchy |  |  |
| P2-S2-home-1 | 977edd5b | home in high contrast | Colour roles and value |  |  |
| P2-S2-home-1 | 977edd5b | home in high contrast | Hierarchy |  |  |
| P2-S3-settings | f0a36a41b6427d2f238c0d93679f11c7d9228f54 | settings at 100% text | Display type |  |  |
| P2-S3-settings | f0a36a41b6427d2f238c0d93679f11c7d9228f54 | settings at 100% text | Hierarchy |  |  |
| P2-S2-home-6 | e674b614a15302227eb9ee9d5d8ba7e9cac8ce14 | home at 100% text | Character presence |  |  |
| P2-S2-home-6 | e674b614a15302227eb9ee9d5d8ba7e9cac8ce14 | home at 100% text | Display type |  |  |
| P2-S2-home-6 | e674b614a15302227eb9ee9d5d8ba7e9cac8ce14 | home at 100% text | Hierarchy |  |  |
| P1-S1-pilot-1 | 5470c4d3 | heist at 200% text | Character presence |  |  |
| P1-S1-pilot-1 | 5470c4d3 | heist at 200% text | Colour roles and value |  |  |
| P1-S1-pilot-1 | 5470c4d3 | heist at 200% text | Display type |  |  |
| P1-S1-pilot-1 | 5470c4d3 | heist at 200% text | Hierarchy |  |  |
| P1-S1-pilot-1 | 5470c4d3 | heist at 200% text | Layered materials |  |  |
| P1-S1-pilot-1 | 5470c4d3 | heist at 200% text | Light behind UI |  |  |
| P1-S1-pilot-1 | 5470c4d3 | heist at 200% text | One art-direction idea |  |  |
| P1-S1-pilot-1 | 5470c4d3 | heist at 200% text | Painted or rendered icons |  |  |
| P2-S1-result-2 | aed28321c02e67edf889d45075675bd1343335cd | result at 100% text | Character presence |  |  |
| P2-S1-result-2 | aed28321c02e67edf889d45075675bd1343335cd | result at 100% text | Hierarchy |  |  |
| P2-S3-settings | f5719f28cbf8c9d751eae45a887de86bab5c2b32 | settings in high contrast | Colour roles and value |  |  |
| P2-S3-settings | f5719f28cbf8c9d751eae45a887de86bab5c2b32 | settings in high contrast | Hierarchy |  |  |
| P2-S2-home-2 | 3612e26564859e8df7c3ce1cd48dba118580d9da | home at 100% text | Character presence |  |  |
| P2-S2-home-2 | 3612e26564859e8df7c3ce1cd48dba118580d9da | home at 100% text | Hierarchy |  |  |
| P2-S3-settings-2 | 5fc97aacdb6a3fe479887d74bc9adae67e420b3b | settings at 100% text | Display type |  |  |
| P2-S3-settings-2 | 5fc97aacdb6a3fe479887d74bc9adae67e420b3b | settings at 100% text | Hierarchy |  |  |
| P2-S2-home-6 | a4090ec77bd7536c10db03e06efcd459d69c4b55 | home at 100% text | Display type |  |  |
| P2-S3-settings | eed8b817fe6c01705c8e4eb5e2ee527e0229ef9f | settings in high contrast | Colour roles and value |  |  |
| P2-S3-settings | eed8b817fe6c01705c8e4eb5e2ee527e0229ef9f | settings in high contrast | Hierarchy |  |  |
