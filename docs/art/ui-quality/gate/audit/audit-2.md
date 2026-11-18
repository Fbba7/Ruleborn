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
| P3-S2-home-7 | c58d49c0a07af5ebc5e2cc1c848ee1de626efce8 | home in high contrast | Hierarchy | pass | Collect is the full-width gold bar and the first thing the eye lands on in the grayscale squint; the white panel rims are high contrast's design, and the XP card, side buttons and chips fall in behind it. |
| P3-S3-nav-1 | 5ac311f77e8d174c0ddc5f48cadabfbad25e994f | character at 200% text, pt_BR | Hierarchy | pass | Online and offline: "Subir de nível", the full-width gold card at the foot, is the largest, most saturated control and leads in grayscale; the cream tab strip, the Vida pill and the gold arrows are a step down, and the offline notice is an info panel smaller and lighter in weight than the primary. |
| P2-S2-home-1 | 71d51d7f | home at 100% text | Character presence | fail | No live toon character: the portrait ring holds a flask emblem, and the only characters are figures a few points tall on the islands, which do not read as a dark shape. |
| P2-S2-home-1 | 71d51d7f | home at 100% text | Display type | fail | "Keeper 14" is thin serif type over the sky with no ink outline, and the headline currency counts are flat white with no outline, hard drop or gradient fill. |
| P2-S2-home-1 | 71d51d7f | home at 100% text | Hierarchy | fail | No Collect and no leading Heist tab (Islands is the raised tab), and the small gold "See" in the raid notice is the only gold action: a field of equal-weight pills and badges with no single entry point. |
| P3-S2-home-7 | c58d49c0a07af5ebc5e2cc1c848ee1de626efce8 | home at 200% text, pt_BR | Hierarchy | pass | "Coletar 3,4 mil" is the full-width gold bar, the largest and lightest control in grayscale; the XP card below it is darker and smaller, and the pt_BR words at 200% fit without pushing a second control up to its weight. |
| P3-S1-hc-offline-1 | a4ed000edfcef3cde3ce3a926eb656efffcc2528 | result at 100% text | Character presence | pass | Offline and server: each crew portrait is a rendered toon model that reads as a dark shape in its gold ring (Scout: soft yellow feathers; Breaker: matte lava body with painted cracks, no specular sheen; Carrier: soft fur), and the loot card carries the Scout's portrait. |
| P3-S1-result-7 | 55716273479b27992cdb57e8f5e5151921d31d6f | result at 200% text, pt_BR | Hierarchy | pass | Offline and server: "ASSALTAR DE NOVO", the full-width gold button at the foot, leads by size and saturation; the reward cards are info panels neither larger nor heavier than it, and the green technical line sits below the reward's weight, though only just. |
| P3-S2-home-7 | c58d49c0a07af5ebc5e2cc1c848ee1de626efce8 | home at 100% text | Display type | pass | "Keeper 24" is the heavy display face with its ink outline over the sky, the headline currency counts have the gold gradient fill, ink outline and hard drop, and every other word sits on a plate, chip or button. |
| P3-S2-home-7 | c58d49c0a07af5ebc5e2cc1c848ee1de626efce8 | home at 100% text | Hierarchy | pass | Collect 3.4k is the largest and most saturated gold control and the brightest thing in grayscale; the XP card is darker, and the side buttons and chips are visibly a step down. |
| P1-K1-numerals-on | 1d21bf4a | heist at 100% text | Display type | pass | "Laws here" over the sky has its ink outline and drop, the 2:25 timer has a thick ink outline, hard drop and gradient fill, and the crew names and HUD words sit on the tray and plates. |
| P3-S2-back-1 | 0bfa1d6a3e794bdae4d65b68e9fdb0a2da4331dd | home at 100% text | Hierarchy | pass | Collect, the full-width gold bar, leads in colour and in grayscale; the back control and chips are a step down. |
| P3-S2-home-states | 84b0ee7ca9435ea2a880c7453e1c9f25be3482d5 | home at 100% text | Display type | pass | The keeper's name has its ink outline over the sky, the headline currency counts have gradient fill, outline and drop, and every other word sits on a plate or chip. |
| P3-S2-home-states | 84b0ee7ca9435ea2a880c7453e1c9f25be3482d5 | home at 100% text | Hierarchy | pass | Collect is the gold primary, larger, warmer and lighter than the XP card, with every other control visibly a step down. |
| P2-S3-character | f1251e68 | character at 200% text, pt_BR | Display type | fail | "Skyskipper · Carregador" and "Nível 3 de 10" are plain body type over the gradient background with no ink outline, and the "NV" overhangs the level badge's top edge and loses its glyphs. |
| P2-S3-character | f1251e68 | character at 200% text, pt_BR | Hierarchy | pass | "SUBIR DE NÍVEL", the gold card at the foot, is the largest control and the lightest in grayscale; the Vida pill, the arrows and the back button are a step down. |
| P3-S1-hc-offline-2 | 788eaaf4d5a46f9cde43ab603446e40b23665715 | heist in high contrast | Colour roles and value | pass | The roles hold in high contrast: the alarm red marks "Intruder!", the chosen crew keeps its gold ring and gold name, the school pips keep their shapes, and the leather buttons are lifted to step off the black card (the same leather as the 100% still, with Cast shown in its "No casts" state, so no role colour has drifted). |
| P3-S2-home-states | 84b0ee7ca9435ea2a880c7453e1c9f25be3482d5 | home in high contrast | Hierarchy | pass | Collect is the full-width gold bar and the first thing the eye lands on in grayscale; the white panel rims and the cream cards are light by the mode's design and do not compete. |
| P3-S2-home-states | 84b0ee7ca9435ea2a880c7453e1c9f25be3482d5 | home at 200% text, pt_BR | Hierarchy | pass | "Coletar" is the full-width gold bar, largest and lightest in grayscale; the XP card and chips fall in behind it at 200% text. |
| P2-S3-character | 6f6a3b15 | character at 200% text, pt_BR | Display type | fail | "Skyskipper · Carregador" and "Nível 3 de 10" are plain body type over the gradient background with no ink outline, and the "NV" overhangs the level badge's top edge and loses its glyphs. |
| P2-S3-character | 6f6a3b15 | character at 200% text, pt_BR | Hierarchy | pass | "SUBIR DE NÍVEL", the gold card at the foot, is the largest control and the lightest in grayscale; the Vida pill, the arrows and the back button are a step down. |
| P3-S3-settings-3 | 7972485a7738ac5cea3f4ac762935d9f2522c1d7 | settings at 100% text | Hierarchy | fail | No primary, and the "Settings" title is not the first thing the eye lands on in grayscale: the gold A / A text-size value buttons are louder, and the cream tab strip and cream toggle rows outweigh the thin title and the group headers, which do not outrank the rows. |

## The labeller's notes

- **Labelled** by AD (P3-AD-audit-2) on 18 November 2026, blind: no
  verdict, board verdict line, "Gate" paragraph or lead note was opened
  before this form was pushed. Time spent: about 16 minutes, 01:24 to
  01:40 UTC, about half of it rendering the 12 commits' stills.
- **Renders.** Each commit in its own worktree under `/tmp/audit-<sha>`,
  with `FIT=1`; the result items in both states (offline and `SERVER=1`),
  the character items online and `OFFLINE=1` where the commit's script
  reads it, high contrast with `CONTRAST=1` (home, heist, result) or `HC=1`
  (character, settings). Every still was judged at phone size, at 1x and in
  zoomed crops, in colour and in grayscale, beside its key frame.
- **Row 17** was also rendered at 100% text at the same commit: Cast's
  "No casts" face and Get out are the same leather there, so high contrast
  lifts the leather and changes no role. The key frame shows Cast gold and
  Get out red. Leather on an empty Cast does not break quality 8. Get out
  is the exit, not an alarm.
- **Row 22.** The key frame `05-settings.png` has the same gold A / A
  buttons and cream rows, and this still has already lost its gold-filled
  tab. The rubric's settings ruling (quality 6, version 2: "a gold tab or
  gold value button louder than the title fails") is still what the label
  follows, so the key frame would fail it the same way. The fix: a heavier
  title (the display face with its outline) and group headers on their
  plates at more weight than the rows.
