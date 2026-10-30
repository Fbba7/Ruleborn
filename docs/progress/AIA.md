# AIA AI UI artist: progress

- Status: Green: pre-check PASS at 1a1afd2 (2026-10-30T22:40:23Z); P0-AIA-board-2 is ready.
- Progress: 1 of 5 tasks merged; 0 items passed by the gate (the board has no gate items).
- Done: P0-AIA-board-1 (merged); P0-AIA-board-2 built: the studio light, the outline and glint rules, four hero icons, each material's high-contrast form, board.png.
- Next: the lead merges P0-AIA-board-2; the key frames wait for the owner's O2.
- Blocked by: none.
- Owner decision needed: O2, the board's approval (the board's README lists what it found, for O2).

| Deliverable | Weight (h) | Status | Evidence |
|---|---:|---|---|
| P0-AIA-board-1: materials and type | 4 | Merged (b6d0a3de) | pre-check PASS at aa11f0e |
| P0-AIA-board-2: light, outline, glint, icons, high contrast, board.png | 2 | Ready at 1a1afd2 (pre-check PASS) | `node art/ui/board/check_board.mjs` at 1a1afd2: 364 words pass in both modes, 8 icons keep the outline rule; `--self-test`: 13 planted faults each fail; `board.png`, `board_hc.png` |
| P0-AIA-keyframes-1: home and heist | 4 | Open (waits for O2) | |
| P0-AIA-keyframes-2: result and character | 4 | Open | |
| P0-AIA-keyframes-3: settings and the contact sheet | 2 | Open | |

## Handoff
- Last verified commit: 1a1afd2 (pre-check green, 2026-10-30T22:40:23Z).
- Done: `art/ui/board/studio.html` (the studio light as `STUDIO`, the outline and glint rules as `RULES`, four hero icons in three.js, every colour a token name), `bake_art.mjs` (renders `art/`: icons in both forms, the finish in four steps, the studio's spheres), `shoot_board.mjs` (`board.png`, `board_hc.png` at 390 points, 2x), four new plates on `board.html`, and checks 5 and 6 in `check_board.mjs` (the studio's colours; the icons' outline from their pixels).
- Half done: none.
- Open hypotheses: the high-contrast light ring outside the ink is a reading of §21.8, put to O2; the other five schools' law frames follow the hourglass model.
- Next step: P0-AIA-keyframes-1 once O2 is answered, in a new session.

## Tried and failed
- 2026-10-30 SVG grain composited with an implicit second input: `feComposite` without `in2` masked the flood with the source shape, so the grain painted the whole surface solid. Named results fixed it.
- 2026-10-30 Measuring words against their whole line box: the box reaches below capitals into darker ground (gold's lower half), so it failed words whose letters pass. The check now measures under the letters, found by drawing each word in black and in white.
- 2026-10-30 A planted "icon without its outline" from the finish's glow-and-drop step: the drop, grown like the outline and near ink in colour, rings the silhouette, so the check rightly passed it. The planted fault is now the bare render.
