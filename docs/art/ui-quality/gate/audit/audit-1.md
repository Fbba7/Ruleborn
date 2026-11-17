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
| P1-S1-pilot-2 | a4d87d18 | heist in high contrast | Colour roles and value | fail | Colour roles: the mauve Get out and Walk faces sit only 5-6 L* off the grass and sky behind them (under the 20 an interactive control needs); only the ink outline separates them, and the high-contrast cards stay mauve rather than light on dark. |
| P1-S1-pilot-2 | a4d87d18 | heist in high contrast | Hierarchy | pass | Hierarchy: the gold Cast is the lightest control in the squint and the only main-action fill; the Room panel is larger but darker, so it does not compete. |
| P2-S2-home-1 | 977edd5b | home at 200% text, pt_BR | Display type | fail | Display type: 'Guardião 24' sits over the sky with no ink outline, and the currency counts are flat cream headline figures with no outline, hard drop or gradient fill. |
| P2-S2-home-1 | 977edd5b | home at 200% text, pt_BR | Hierarchy | pass | Hierarchy: Coletar is the full-width gold bar at the foot and leads in grayscale by size, place and weight. |
| P2-S3-settings-2 | 9e602fccafac7ffbb855e2049d8ad9db411805d2 | settings at 200% text, pt_BR | Display type | pass | Display type: every word sits on a plate or card; the 200% figure is a headline figure with an ink outline, a hard drop and a gradient fill; nothing clipped or under 13 pt. |
| P2-S3-settings-2 | 9e602fccafac7ffbb855e2049d8ad9db411805d2 | settings at 200% text, pt_BR | Hierarchy | pass | Hierarchy (borderline): no primary on settings; the Ajustes title plate leads by place and size, and the selected tab is dark brown with a gold rim, not a gold fill louder than the title. |
| P2-S1-result-6 | b5843368999f64b956c2c1dd8db1e2a0ccbad049 | result at 100% text | Character presence | fail | Character presence: the reward card (+508 Loot) shows no character and no crew portrait is on screen; a reward with no character fails. |
| P2-S1-result-6 | b5843368999f64b956c2c1dd8db1e2a0ccbad049 | result at 100% text | Display type | pass | Display type: words over the sunburst carry an ink outline of about 3 pt, and +508 is a headline figure with outline, hard drop and gradient fill. |
| P2-S2-home-6 | e674b614a15302227eb9ee9d5d8ba7e9cac8ce14 | home in high contrast | Hierarchy | pass | Hierarchy: the gold Collect at the foot is the lightest control and leads; the XP panel is larger but dark, so it does not compete (v3). |
| P2-S2-home-3 | c9a89e5a4841f8f66fc9986560fbe455e61d2c58 | home at 100% text | Character presence | pass | Character presence: the keeper portrait is soft orange fur with a cream belly and dark eyes, a clear dark shape inside its gold ring, in the toon look. |
| P2-S2-home-3 | c9a89e5a4841f8f66fc9986560fbe455e61d2c58 | home at 100% text | Hierarchy | pass | Hierarchy: the gold Collect at the foot leads in grayscale by size, place and weight; the tabs and info panel sit below it. |
| P2-S3-character | f1251e68 | character in high contrast | Colour roles and value | pass | Colour roles: gold only on Level up (main-action fill), the arrows and as frame material; controls clear ΔL* 20 (arrows 44, Level up 75, tabs 80); dark pills carry light outlines. |
| P2-S3-character | f1251e68 | character in high contrast | Hierarchy | pass | Hierarchy: Level up is the full-width foot control carrying the primary's label and leads; the white tabs are high-contrast cream cards that do not compete for lightness alone (v3). |
| P2-S3-character-2 | 6b7e6b42 | character at 200% text, pt_BR | Display type | fail | Display type: at 200% 'Skyskipper · Carregador' and 'Nível 3 de 10' sit over the sky with a 1-2 pt outline on about 32 pt words, under the 12% stroke words over art need. |
| P2-S3-character-2 | 6b7e6b42 | character at 200% text, pt_BR | Hierarchy | pass | Hierarchy: Subir de nível is the full-width gold foot control and leads in grayscale. |
| P2-S2-home-4 | 1697a6c6675c22865eb28732ee50b410333a48de | home at 200% text, pt_BR | Display type | fail | Display type: 'Guardião 24' sits over the sky with no ink outline, and the currency counts are flat headline figures with no outline, hard drop or gradient fill. |
| P2-S2-home-4 | 1697a6c6675c22865eb28732ee50b410333a48de | home at 200% text, pt_BR | Hierarchy | pass | Hierarchy: Coletar is the full-width gold foot control and leads in grayscale. |
| P2-S2-home-1 | 977edd5b | home in high contrast | Colour roles and value | fail | Colour roles: the XP bar is filled in the main-action gold (the key frame uses green), so gold takes a second role on a non-action. |
| P2-S2-home-1 | 977edd5b | home in high contrast | Hierarchy | pass | Hierarchy: Collect leads at the foot; the XP panel is dark and does not compete. |
| P2-S3-settings | f0a36a41b6427d2f238c0d93679f11c7d9228f54 | settings at 100% text | Display type | pass | Display type: every word sits on a plate or card; the 100% figure has an ink outline, a hard drop and a gradient fill; nothing clipped or under 13 pt. |
| P2-S3-settings | f0a36a41b6427d2f238c0d93679f11c7d9228f54 | settings at 100% text | Hierarchy | pass | Hierarchy (borderline): no primary on settings; the title plate leads by place and size, the selected tab is dark with a gold rim, and the A steppers are cream, not gold. |
| P2-S2-home-6 | e674b614a15302227eb9ee9d5d8ba7e9cac8ce14 | home at 100% text | Character presence | pass | Character presence: the keeper portrait is cream-orange soft fur with dark eyes, a clear face in its gold ring, in the toon look. |
| P2-S2-home-6 | e674b614a15302227eb9ee9d5d8ba7e9cac8ce14 | home at 100% text | Display type | pass | Display type: 'Keeper 24' over the sky carries an ink outline of about 13% plus a rim band and drop; the currency counts are gradient-filled numerals with ink outline and drop (the outline reads weakly on the near-black plates, and the 'k' is cream, a minor inconsistency). |
| P2-S2-home-6 | e674b614a15302227eb9ee9d5d8ba7e9cac8ce14 | home at 100% text | Hierarchy | pass | Hierarchy: the gold Collect at the foot leads in grayscale by size, place and weight. |
| P1-S1-pilot-1 | 5470c4d3 | heist at 200% text | Character presence | pass | Character presence (borderline): crew portraits read as toon bodies: Scout cream fur (light on its yellow ring, read by its face), Breaker charcoal with orange glow cracks in soft shading, Carrier brown fur with a cream chest. |
| P1-S1-pilot-1 | 5470c4d3 | heist at 200% text | Colour roles and value | fail | Colour roles: No casts (ΔL* 9), Get out (17) and pause (17) sit under 20 against the island and sky; the Cast slot is mauve, not the main-action gold. |
| P1-S1-pilot-1 | 5470c4d3 | heist at 200% text | Display type | fail | Display type: 'Laws here' over the night sky has an outline of about 1 pt that merges into the dark, crew names carry outlines far under 12%, and the 2:25 timer is a flat headline figure with no outline, drop or gradient. |
| P1-S1-pilot-1 | 5470c4d3 | heist at 200% text | Hierarchy | fail | Hierarchy: the Cast slot ('No casts') is dim mauve, and the red Get out beside it, the same size and lighter, draws the eye first in grayscale; a red control before the primary fails. |
| P1-S1-pilot-1 | 5470c4d3 | heist at 200% text | Layered materials | fail | Layered materials: the large hint plate is one translucent dark fill with a hairline gold rim, no gloss band or lip, beside four-layer buttons and panels. |
| P1-S1-pilot-1 | 5470c4d3 | heist at 200% text | Light behind UI | pass | Light behind UI: the island scene is a lit ground; tops carry gloss and lips sit below, one light direction throughout. |
| P1-S1-pilot-1 | 5470c4d3 | heist at 200% text | One art-direction idea | pass | One art-direction idea (borderline): toy leather panels and buttons throughout; the hint plate is plain but drawn without blur or web chrome. |
| P1-S1-pilot-1 | 5470c4d3 | heist at 200% text | Painted or rendered icons | fail | Painted icons: the Bloom law icon is a flat green two-tone glyph with no key light, rim light or specular and no school frame. |
| P2-S1-result-2 | aed28321c02e67edf889d45075675bd1343335cd | result at 100% text | Character presence | fail | Character presence: the +508 Loot reward card shows a sparkle and no character, and no crew is on screen; a reward with no character fails. |
| P2-S1-result-2 | aed28321c02e67edf889d45075675bd1343335cd | result at 100% text | Hierarchy | pass | Hierarchy (borderline): Raid again is the large gold foot bar, about 2.3x Home, and leads by size, place and saturation (v3); the cream Loot card and Home are lighter, and the small 3 s replay button is also gold. |
| P2-S3-settings | f5719f28cbf8c9d751eae45a887de86bab5c2b32 | settings in high contrast | Colour roles and value | pass | Colour roles: the selected tab is dark with a gold rim (material); green marks the on toggle; school icons carry shapes, not hue alone; light controls on dark clear ΔL* 20 by far. |
| P2-S3-settings | f5719f28cbf8c9d751eae45a887de86bab5c2b32 | settings in high contrast | Hierarchy | pass | Hierarchy (borderline): no primary on settings; the title plate leads by place and size; the white cards are the high-contrast design (v3); the group headers are thin; the gold 100% is a figure, not a button. |
| P2-S2-home-2 | 3612e26564859e8df7c3ce1cd48dba118580d9da | home at 100% text | Character presence | pass | Character presence: the same soft-fur toon portrait, a clear dark face shape inside its gold ring. |
| P2-S2-home-2 | 3612e26564859e8df7c3ce1cd48dba118580d9da | home at 100% text | Hierarchy | pass | Hierarchy: the gold Collect leads in grayscale over the Islands and Heist tabs. |
| P2-S3-settings-2 | 5fc97aacdb6a3fe479887d74bc9adae67e420b3b | settings at 100% text | Display type | pass | Display type: words sit on plates and cards (the group headers on dark pills); the 100% figure has a gold gradient, a thick ink outline and a drop; nothing clipped or under 13 pt. |
| P2-S3-settings-2 | 5fc97aacdb6a3fe479887d74bc9adae67e420b3b | settings at 100% text | Hierarchy | fail | Hierarchy (borderline): settings has no primary, and the gold-filled A value steppers are the most saturated marks on screen and, with the cream tab strip, outweigh the dark title plate; a gold value button louder than the title fails. |
| P2-S2-home-6 | a4090ec77bd7536c10db03e06efcd459d69c4b55 | home at 100% text | Display type | pass | Display type: 'Keeper 24' over the sky carries a warm ink outline and drop; the currency counts are gold-gradient headline figures with ink outline and drop, the 'k' now matching; labels sit on plates. |
| P2-S3-settings | eed8b817fe6c01705c8e4eb5e2ee527e0229ef9f | settings in high contrast | Colour roles and value | pass | Colour roles: gold only as the selected tab's rim and the 100% figure; green marks the on toggle; school icons keep their shapes; white controls on dark clear ΔL* 20 by far. |
| P2-S3-settings | eed8b817fe6c01705c8e4eb5e2ee527e0229ef9f | settings in high contrast | Hierarchy | pass | Hierarchy (borderline): no primary on settings; the Settings title plate leads by place and size; the white tab strip and A steppers are high-contrast cream cards (v3), not gold; group headers are smaller than the title but no louder than the rows. |


## Labeller's note

Labelled by AD on 17 November 2026, 07:30 to 07:50 UTC, under
P3-AD-audit-1 (lead cycle 118), against rubric v3.

- **Blind.** Before every row was labelled and pushed, nothing under
  `gate/verdicts/`, no board verdict line, no "Gate" paragraph of
  `requests.md` and no lead progress note was opened. The only exposure
  was AD's own past handoff in `docs/progress/AD.md`, read at claim time.
  It records that verdicts exist for some of these tasks but not this
  audit's verdicts.
- **Rendered at each commit.** All 19 items were rendered in their own
  worktrees with `tools/render/shoot.sh` and the commit's shot script.
  Home and settings were shot at 540×1170 and heist and result at
  1080×2340, with `TEXT=200 LOCALE=pt_BR` or `CONTRAST=1`/`HC=1` as
  each row names. Each still was judged at phone size, in grayscale
  (`tools/ui_gate/colour.py`) and in zoomed crops. ΔL* readings come from
  CIELAB L* on sampled face and ground pixels.
- **Borderline rows** say "borderline" in the critique: 6, 21, 25, 31,
  34, 36, 40 and 43. Rows 6, 21, 36 and 43 depend on how the settings
  title is read against high-contrast cream cards (v3). Row 40 fails on
  the gold-filled A steppers. Row 34 passes on v3's size-and-weight rule.
