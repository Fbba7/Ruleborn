# AIA AI UI artist: progress

- Status: Green on the board's own checks; the full pre-check of the last push is running.
- Progress: 0 of 5 tasks merged; 0 items passed by the gate (the board has no gate items).
- Done: P0-AIA-board-1, the style board's material set and type treatments, with its scripted checks.
- Next: P0-AIA-board-2 (outline and glint rules, the studio light, four hero icons, each material's high-contrast form, board.png) once board-1 merges.
- Blocked by: none.
- Owner decision needed: none now; the board goes to the owner at O2 after part 2.

| Deliverable | Weight (h) | Status | Evidence |
|---|---:|---|---|
| P0-AIA-board-1: materials and type | 4 | Built; pre-check running | `node art/ui/board/check_board.mjs`: 234 words pass in both modes; `--self-test`: 9 planted faults each fail |
| P0-AIA-board-2: light, outline, glint, icons, high contrast, board.png | 2 | Open | |
| P0-AIA-keyframes-1: home and heist | 4 | Open (waits for O2) | |
| P0-AIA-keyframes-2: result and character | 4 | Open | |
| P0-AIA-keyframes-3: settings and the contact sheet | 2 | Open | |

## Handoff
- Last verified commit: the board's checks pass at the head of `claude/ui-artist`; the full pre-check is recorded in `docs/progress/status/AIA.json` when it ends.
- Done: `art/ui/board/` holds `board.html` (five materials and the type plate, normal and `?hc=1`), `tokens.css` generated from `client/ui/tokens.json` by `build_tokens.mjs`, and `check_board.mjs` (token provenance, then §21.8's floors and contrast against the pixels under each word's letters, in both modes). Its README lists what the board found for O2.
- Half done: the high-contrast mode follows §21.8's rules (opaque cards, 3-point outlines, secondary raised, no glass) but each material's designed high-contrast form is part 2.
- Open hypotheses: part 2's studio-light plate should state the key, rim and fill as the icon pipeline of section 9.2 of `report.md` uses them, so icons and panels share one light.
- Next step: when board-1 is merged, take P0-AIA-board-2 in a new session.

## Tried and failed
- 2026-10-30 SVG grain composited with an implicit second input: `feComposite` without `in2` masked the flood with the source shape, so the grain painted the whole surface solid. Named results fixed it.
- 2026-10-30 Measuring words against their whole line box: the box reaches below capitals into darker ground (gold's lower half), so it failed words whose letters pass. The check now measures under the letters, found by drawing each word in black and in white.
