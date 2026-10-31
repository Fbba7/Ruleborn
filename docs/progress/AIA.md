# AIA AI UI artist: progress

- Status: Green: pre-check PASS at 5eec1b60 (2026-10-31T13:33:57Z); P0-AIA-keyframes-3 is ready.
- Progress: 5 tasks merged, P0-AIA-keyframes-3 ready, P0-AIA-board-4 open; 0 items passed by the gate (the board has no gate items).
- Done: P0-AIA-keyframes-3 built: settings at 1080 x 2340 in three forms, in English and Brazilian Portuguese, under the same scripted checks, and one contact sheet of all thirty stills.
- Next: P0-AIA-board-4 (open): the style board's words for the revised kit tokens (K1-R6).
- Blocked by: none.
- Owner decision needed: none.

| Deliverable | Weight (h) | Status | Evidence |
|---|---:|---|---|
| P0-AIA-board-1: materials and type | 4 | Merged (b6d0a3de) | pre-check PASS at aa11f0e |
| P0-AIA-board-2: light, outline, glint, icons, high contrast, board.png | 2 | Merged (O2: approved in part) | `node art/ui/board/check_board.mjs` at 1a1afd2: 364 words pass in both modes, 8 icons keep the outline rule; `--self-test`: 13 planted faults each fail; `board.png`, `board_hc.png` |
| P0-AIA-board-3: O2's redirect of B3, B4, B5, B11 | 3 | Merged (a38a3790) | `check_board.mjs`: 376 words pass in both modes, 8 icons keep the outline rule, 22 controls pass value-steps (ΔL* 22.1 or more); `--self-test`: 15 planted faults each fail; `board.png`, `board_hc.png` |
| P0-AIA-keyframes-1: home and heist | 4 | Merged (fafc1a13) | `node art/ui/keyframes/check_keyframes.mjs`: 12 stills at 1080 x 2340 pass. Home: 18 controls, smallest touch area 48 points, 43 words (26 at 200%) all passing, worst 5.8:1 at 100%. Heist: 8 controls, 22 words, worst 5.7:1. All 12 shots pass value-steps. `--self-test`: 14 planted faults, each fails. `bash tools/check_all.sh`: all checks passed. |
| P0-AIA-keyframes-2: result and character | 4 | Merged (b8308788) | `node art/ui/keyframes/check_keyframes.mjs`: all 24 stills pass. Result: 5 controls, smallest touch area 56 points, 23 words (13 at 200%), worst 5.4:1. Character: 4 controls and the tab strip, smallest touch area 52 points, 28 words (15 at 200%), worst 6.87:1. All 24 shots pass value-steps. `--self-test`: each planted fault fails. `bash tools/check_all.sh`: all checks passed. |
| P0-AIA-keyframes-3: settings and the contact sheet | 2 | Ready at 5eec1b60 (pre-check PASS) | `node art/ui/keyframes/check_keyframes.mjs`: all 30 stills pass. Settings: 5 controls (3 at 200%), smallest touch area 52 points, 20 words (8 at 200%), worst 8.59:1. All 30 shots pass value-steps. `contact_sheet.png` is 1882 x 3085. `--self-test`: each planted fault fails, including a contact sheet of the wrong size. `bash tools/run_checks.sh`: all checks passed. |
| P0-AIA-board-4: the board's words for the revised tokens (K1-R6) | 1 | Built; pre-check pending | `node art/ui/board/check_board.mjs` and `--revised` (section 2.1's backdrop #171046 to #2C3AA8, #FF9AAA, #3FBF7F tried over `tokens.css`): 378 words pass in both modes, 8 icons keep the outline rule, 16 controls pass value-steps; `--self-test`: each planted fault fails, including a regular-weight caption on the revised backdrop; `board.png`, `board_hc.png` |


## Handoff
- Last verified commit: 5eec1b60 (pre-check green, 2026-10-31T13:33:57Z). Requests AIA-R3 to AIA-R7 in the status file, each with a default.
- Done:
  - `art/ui/keyframes/` holds `01-home`, `02-heist`, `03-result`, `04-character` and `05-settings` as `.html` with `.png` and `.shot.json` in all six forms each: as written, `_text200` and `_hc`, each also `_pt_BR`.
  - Settings: the Access tab with the text-size card (gold A buttons, the figure, the steps, a law read at that size), the six school shapes, and the switches in framed parchment rows; the dock holds only the back button. At 200% only the text card is drawn; in Portuguese one switch is drawn.
  - `contact_sheet.py` lays the thirty stills on `contact_sheet.png` (a row for each page, a column for each form and language); `check_keyframes.mjs` checks its size.
  - `kit.js` takes `k:KEY:arg` for a key with its own argument.
  - `README.md` gives the steps, now with the contact sheet, and the settings page's choices.
- Half done: none.
- Open hypotheses: the large-text adaptations follow the game's SIDE_BY_SIDE_UP_TO rule and need the lead's agreement (request 4); the gold text-size buttons differ from the game's leather (value steps) and the game may want the same change.
- Next step: P0-AIA-board-4.

## Tried and failed
- 2026-10-30 SVG grain composited with an implicit second input: `feComposite` without `in2` masked the flood with the source shape, so the grain painted the whole surface solid. Named results fixed it.
- 2026-10-30 Measuring words against their whole line box: the box reaches below capitals into darker ground (gold's lower half), so it failed words whose letters pass. The check now measures under the letters, found by drawing each word in black and in white.
- 2026-10-30 A planted "icon without its outline" from the finish's glow-and-drop step: the drop, grown like the outline and near ink in colour, rings the silhouette, so the check rightly passed it. The planted fault is now the bare render.
- 2026-10-31 The enamel gloss band at paper 24%: the card's kicker, "LAW 9 OF 24 · TIME", fell to 4.41:1 at its worst point. 20% passes and the band still reads at phone size.
- 2026-10-31 Measuring tab badges at 200% with 1 point of padding: the probe ring around the figure reached the badge's rim and caught the island behind it, so a badge that reads well failed. A 3-point vertical pad at large text fixed it.
- 2026-10-31 Gold faces that darken from the middle down: the words on Cast fell to Lc 47-55. The key frames now keep `--c-gold` down to the lip.
- 2026-10-31 Kit class names on a new page: the character page's `.tabs` and `.head` took the kit's tab bar and heist head, so the strip went dark and the ability's uses stood in a column. Page-own names (`.char-tabs`, `.ability-head`) fixed it.
- 2026-10-31 Home in leather on the result's glass tray: ΔL* 13 against its ground. Parchment passes.
- 2026-10-31 Leather text-size buttons on the enamel card: ΔL* 1 to 11 against it, so value-steps failed. Gold passes.
- 2026-10-31 A 64-point button for the large A at 200%: the 52-point letter overflowed onto the dark rim (1.03:1). 76 x 76 at large text fits it.
