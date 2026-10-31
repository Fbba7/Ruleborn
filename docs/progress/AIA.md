# AIA AI UI artist: progress

- Status: Working on P0-AIA-board-3: built; checks pass; the pre-check comes next.
- Progress: 2 of 6 tasks merged; 0 items passed by the gate (the board has no gate items).
- Done: P0-AIA-board-3 built: the studio and the four hero icons in §21.3's toon look, the enamel card's gloss band, rim and foot, the chosen card's gold rim, the lit oak well.
- Next: the pre-check, then P0-AIA-board-3 is ready for O2-2.
- Blocked by: none.
- Owner decision needed: none (O2-2 is AD's).

| Deliverable | Weight (h) | Status | Evidence |
|---|---:|---|---|
| P0-AIA-board-1: materials and type | 4 | Merged (b6d0a3de) | pre-check PASS at aa11f0e |
| P0-AIA-board-2: light, outline, glint, icons, high contrast, board.png | 2 | Merged (O2: approved in part) | `node art/ui/board/check_board.mjs` at 1a1afd2: 364 words pass in both modes, 8 icons keep the outline rule; `--self-test`: 13 planted faults each fail; `board.png`, `board_hc.png` |
| P0-AIA-board-3: O2's redirect of B3, B4, B5, B11 | 3 | Built | `check_board.mjs`: 376 words pass in both modes, 8 icons keep the outline rule, 22 controls pass value-steps (ΔL* 22.1 or more) |
| P0-AIA-keyframes-1: home and heist | 4 | Open (waits for O2) | |
| P0-AIA-keyframes-2: result and character | 4 | Open | |
| P0-AIA-keyframes-3: settings and the contact sheet | 2 | Open | |

## Handoff
- Last verified commit: 1a1afd2 (pre-check green, 2026-10-30T22:40:23Z); this task's pre-check not yet run.
- Done: `studio.html` lights every piece with one toon shader that mirrors `client/world/toon_light.gdshaderinc` (four-step ramp, violet shade, saturation 1.1, rim in the piece's light); no physically based material is left. `board.html`: the enamel card has a gloss band, a 3-point `card_bottom` rim and a 6-point foot; the chosen card a 4-point gold rim and 8-point gold foot, no glow; the oak well is a lit floor. `shoot_board.mjs` writes shot files with every control's rectangle. `check_board.mjs` gains a toon-look check (in check 5) and check 7 (value steps through `tools/ui_gate/checks.py`), each with a planted fault.
- Half done: none.
- Open hypotheses: the icons' rim strength (0.42, the world's 0.28 and a half) is AIA's choice for icons without a world around them; O2-2 may ask for the world's own.
- Next step: run the pre-check, mark P0-AIA-board-3 ready; then P0-AIA-keyframes-1 in a new session.

## Tried and failed
- 2026-10-30 SVG grain composited with an implicit second input: `feComposite` without `in2` masked the flood with the source shape, so the grain painted the whole surface solid. Named results fixed it.
- 2026-10-30 Measuring words against their whole line box: the box reaches below capitals into darker ground (gold's lower half), so it failed words whose letters pass. The check now measures under the letters, found by drawing each word in black and in white.
- 2026-10-30 A planted "icon without its outline" from the finish's glow-and-drop step: the drop, grown like the outline and near ink in colour, rings the silhouette, so the check rightly passed it. The planted fault is now the bare render.
- 2026-10-31 The enamel gloss band at paper 24%: the card's kicker, "LAW 9 OF 24 · TIME", fell to 4.41:1 at its worst point. 20% passes and the band still reads at phone size.
