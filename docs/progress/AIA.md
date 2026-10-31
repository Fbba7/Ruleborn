# AIA AI UI artist: progress

- Status: Green: check_all passed at b760d6f1; its pre-check is running. P0-AIA-keyframes-1 is working.
- Progress: 2 of 6 tasks merged; 0 items passed by the gate (the board has no gate items).
- Done: P0-AIA-keyframes-1 built: home and heist at 1080 x 2340 in three forms each, in English and Brazilian Portuguese, with their scripted checks.
- Next: P0-AIA-keyframes-2 (open): result and character.
- Blocked by: none.
- Owner decision needed: none.

| Deliverable | Weight (h) | Status | Evidence |
|---|---:|---|---|
| P0-AIA-board-1: materials and type | 4 | Merged (b6d0a3de) | pre-check PASS at aa11f0e |
| P0-AIA-board-2: light, outline, glint, icons, high contrast, board.png | 2 | Merged (O2: approved in part) | `node art/ui/board/check_board.mjs` at 1a1afd2: 364 words pass in both modes, 8 icons keep the outline rule; `--self-test`: 13 planted faults each fail; `board.png`, `board_hc.png` |
| P0-AIA-board-3: O2's redirect of B3, B4, B5, B11 | 3 | Ready at e09807f (pre-check PASS) | `check_board.mjs`: 376 words pass in both modes, 8 icons keep the outline rule, 22 controls pass value-steps (ΔL* 22.1 or more); `--self-test`: 15 planted faults each fail; `board.png`, `board_hc.png` |
| P0-AIA-keyframes-1: home and heist | 4 | Working (pre-check running on b760d6f1) | `node art/ui/keyframes/check_keyframes.mjs`: 12 stills at 1080 x 2340 pass. Home: 18 controls, smallest touch area 48 points, 43 words (26 at 200%) all passing, worst 5.8:1 at 100%. Heist: 8 controls, 22 words, worst 5.7:1. All 12 shots pass value-steps. `--self-test`: 14 planted faults, each fails. `bash tools/check_all.sh`: all checks passed. |
| P0-AIA-keyframes-2: result and character | 4 | Open | |
| P0-AIA-keyframes-3: settings and the contact sheet | 2 | Open | |

## Handoff
- Last verified commit: b760d6f1 (check_all passed; pre-check running).
- Done:
  - `art/ui/keyframes/` holds `01-home` and `02-heist` as `.html` with `.png` and `.shot.json` in all twelve forms: as written, `_text200` and `_hc`, each also `_pt_BR`.
  - `check_keyframes.mjs` runs the scripted checks: token colours only, the game's words, type at least 13 x scale, 48-point touch areas, safe area, overlap, clipping, at most 8 heist controls, value steps and still size. Its `--self-test` has 14 cases.
  - `README.md` gives the steps: bake, build the words, shoot, check.
  - `check_board.mjs`'s checkMode now skips words the page does not draw (display: none), and the board still passes its own checks and self-test.
- Half done: none.
- Open hypotheses: the large-text adaptations (only the chosen tab keeps its word; side names, the chosen name and the Sage plate hide; pins fall back to their level) follow the game's SIDE_BY_SIDE_UP_TO rule and need the lead's agreement (request 4).
- Next step: P0-AIA-keyframes-2.

## Tried and failed
- 2026-10-30 SVG grain composited with an implicit second input: `feComposite` without `in2` masked the flood with the source shape, so the grain painted the whole surface solid. Named results fixed it.
- 2026-10-30 Measuring words against their whole line box: the box reaches below capitals into darker ground (gold's lower half), so it failed words whose letters pass. The check now measures under the letters, found by drawing each word in black and in white.
- 2026-10-30 A planted "icon without its outline" from the finish's glow-and-drop step: the drop, grown like the outline and near ink in colour, rings the silhouette, so the check rightly passed it. The planted fault is now the bare render.
- 2026-10-31 The enamel gloss band at paper 24%: the card's kicker, "LAW 9 OF 24 · TIME", fell to 4.41:1 at its worst point. 20% passes and the band still reads at phone size.
- 2026-10-31 Measuring tab badges at 200% with 1 point of padding: the probe ring around the figure reached the badge's rim and caught the island behind it, so a badge that reads well failed. A 3-point vertical pad at large text fixed it.
- 2026-10-31 Gold faces that darken from the middle down: the words on Cast fell to Lc 47-55. The key frames now keep `--c-gold` down to the lip.
