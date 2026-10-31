# AIA AI UI artist: progress

- Status: Green: pre-check PASS at e09807f (2026-10-31T02:41:29Z); P0-AIA-board-3 is ready.
- Progress: 2 of 6 tasks merged; 0 items passed by the gate (the board has no gate items).
- Done: P0-AIA-board-3 built: the studio and the four hero icons in §21.3's toon look, the enamel card's gloss band, rim and foot, the chosen card's gold rim, the lit oak well.
- Next: P0-AIA-keyframes-1 (working): the pages over the baked worlds.
- Blocked by: none.
- Owner decision needed: none (O2-2 is AD's).

| Deliverable | Weight (h) | Status | Evidence |
|---|---:|---|---|
| P0-AIA-board-1: materials and type | 4 | Merged (b6d0a3de) | pre-check PASS at aa11f0e |
| P0-AIA-board-2: light, outline, glint, icons, high contrast, board.png | 2 | Merged (O2: approved in part) | `node art/ui/board/check_board.mjs` at 1a1afd2: 364 words pass in both modes, 8 icons keep the outline rule; `--self-test`: 13 planted faults each fail; `board.png`, `board_hc.png` |
| P0-AIA-board-3: O2's redirect of B3, B4, B5, B11 | 3 | Ready at e09807f (pre-check PASS) | `check_board.mjs`: 376 words pass in both modes, 8 icons keep the outline rule, 22 controls pass value-steps (ΔL* 22.1 or more); `--self-test`: 15 planted faults each fail; `board.png`, `board_hc.png` |
| P0-AIA-keyframes-1: home and heist | 4 | Working | worlds and portraits baked by `art/ui/keyframes/bake.sh`; `01-home.html` drafted over `kit.css`, `kit.js` and `words.js` |
| P0-AIA-keyframes-2: result and character | 4 | Open | |
| P0-AIA-keyframes-3: settings and the contact sheet | 2 | Open | |

## Handoff
- Last verified commit: e09807f (pre-check green, 2026-10-31T02:41:29Z).
- Done: `bake.sh` bakes the home and heist worlds and the portraits from the game. `kit.css` lifts the board's materials and type (scaled by `--ts`); `kit.js` reads `?lang=`, `?text=` and `?hc=`, fills the game's words from `words.js` (written by `build_words.mjs` from `client/i18n`) and settles the realm pins clear of the interface. `01-home.html` renders at 100% in English, Brazilian Portuguese and high contrast. `check_board.mjs` exports its checks for reuse.
- Half done: the home's 200% form: the realm pins have no room yet between the head and the bottom block.
- Open hypotheses: at large text the side buttons keep only their icons and the realm pins keep only their level, as the game's pin over a small island does (`client/world/universe_pins.gd`).
- Next step: fit the 200% home; write `02-heist.html`, `shoot_keyframes.mjs` and `check_keyframes.mjs`.

## Tried and failed
- 2026-10-30 SVG grain composited with an implicit second input: `feComposite` without `in2` masked the flood with the source shape, so the grain painted the whole surface solid. Named results fixed it.
- 2026-10-30 Measuring words against their whole line box: the box reaches below capitals into darker ground (gold's lower half), so it failed words whose letters pass. The check now measures under the letters, found by drawing each word in black and in white.
- 2026-10-30 A planted "icon without its outline" from the finish's glow-and-drop step: the drop, grown like the outline and near ink in colour, rings the silhouette, so the check rightly passed it. The planted fault is now the bare render.
- 2026-10-31 The enamel gloss band at paper 24%: the card's kicker, "LAW 9 OF 24 · TIME", fell to 4.41:1 at its worst point. 20% passes and the band still reads at phone size.
