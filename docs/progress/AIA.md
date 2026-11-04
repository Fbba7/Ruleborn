# AIA AI UI artist: progress

- Status: Green: pre-check PASS at c8915bc3 (2026-11-04T13:51:41Z); P1-AIA-kit-1 is ready.
- Progress: 5 tasks merged, P0-AIA-keyframes-3 and P0-AIA-board-4 ready, P1-AIA-kit-1 ready; 0 items passed by the gate.
- Done: P1-AIA-kit-1: kit batch 1a, five button skins (primary, secondary, tertiary, danger, success) plus the round gold action and a parchment tertiary face, each in normal, pressed, disabled and locked with high-contrast twins, baked into `client/ui/art/kit.webp`, `kit_hc.webp` and `kit.json`.
- Next: wait for the lead (gate on the kit atlas contact sheet).
- Blocked by: none.
- Owner decision needed: none. Requests AIA-R9 to AIA-R12 to K1 are in the status file, each with a default.

| Deliverable | Weight (h) | Status | Evidence |
|---|---:|---|---|
| P0-AIA-board-1: materials and type | 4 | Merged (b6d0a3de) | pre-check PASS at aa11f0e |
| P0-AIA-board-2: light, outline, glint, icons, high contrast, board.png | 2 | Merged (O2: approved in part) | `node art/ui/board/check_board.mjs` at 1a1afd2: 364 words pass in both modes, 8 icons keep the outline rule; `--self-test`: 13 planted faults each fail; `board.png`, `board_hc.png` |
| P0-AIA-board-3: O2's redirect of B3, B4, B5, B11 | 3 | Merged (a38a3790) | `check_board.mjs`: 376 words pass in both modes, 8 icons keep the outline rule, 22 controls pass value-steps (ΔL* 22.1 or more); `--self-test`: 15 planted faults each fail; `board.png`, `board_hc.png` |
| P0-AIA-keyframes-1: home and heist | 4 | Merged (fafc1a13) | `node art/ui/keyframes/check_keyframes.mjs`: 12 stills at 1080 x 2340 pass. Home: 18 controls, smallest touch area 48 points, 43 words (26 at 200%) all passing, worst 5.8:1 at 100%. Heist: 8 controls, 22 words, worst 5.7:1. All 12 shots pass value-steps. `--self-test`: 14 planted faults, each fails. `bash tools/check_all.sh`: all checks passed. |
| P0-AIA-keyframes-2: result and character | 4 | Merged (b8308788) | `node art/ui/keyframes/check_keyframes.mjs`: all 24 stills pass. Result: 5 controls, smallest touch area 56 points, 23 words (13 at 200%), worst 5.4:1. Character: 4 controls and the tab strip, smallest touch area 52 points, 28 words (15 at 200%), worst 6.87:1. All 24 shots pass value-steps. `--self-test`: each planted fault fails. `bash tools/check_all.sh`: all checks passed. |
| P0-AIA-keyframes-3: settings and the contact sheet | 2 | Ready at 5eec1b60 (pre-check PASS) | `node art/ui/keyframes/check_keyframes.mjs`: all 30 stills pass. Settings: 5 controls (3 at 200%), smallest touch area 52 points, 20 words (8 at 200%), worst 8.59:1. All 30 shots pass value-steps. `contact_sheet.png` is 1882 x 3085. `--self-test`: each planted fault fails, including a contact sheet of the wrong size. `bash tools/run_checks.sh`: all checks passed. |
| P0-AIA-board-4: the board's words for the revised tokens (K1-R6) | 1 | Ready at b83a0b4d (pre-check PASS) | `node art/ui/board/check_board.mjs` and `--revised` (section 2.1's backdrop #171046 to #2C3AA8, #FF9AAA, #3FBF7F tried over `tokens.css`): 378 words pass in both modes, 8 icons keep the outline rule, 16 controls pass value-steps; `--self-test`: each planted fault fails, including a regular-weight caption on the revised backdrop; `board.png`, `board_hc.png` |

| P1-AIA-kit-1: kit art batch 1a | 4 | Ready at c8915bc3 (pre-check PASS) | `node tools/ui_bake/bake.js --check`: kit 28 pieces, 2048 x 2048, 446350 bytes for both atlases. `python3 art/ui/kit_build/proof_kit.py --check`: 280 results, 0 fail: 152 value-steps (76 a mode; worst ΔL* 21.9 normal, 23.8 high contrast, both `button_danger__box__pressed` on the backdrop) and 128 label contrasts (worst 4.78:1 normal, tertiary on the backdrop; 5.81:1 high contrast). Contact sheets `art/ui/kit_build/proof/contact_normal.png`, `contact_hc.png` (sheet.py contact, 60 and 120 points). |

## Handoff
- M1 (acked 2026-11-04): scored against `docs/art/ui-quality/gate/rubric.md` below, value-steps run, from reduced-size previews.
- Last verified commit: c8915bc3 (pre-check green, 2026-11-04T13:51:41Z).
- Done (P1-AIA-kit-1):
  - `art/ui/kit_build/build_kit.py` writes the sources from `client/ui/tokens.json`: `art/ui/kit/<skin>/box.svg` for button_primary, button_secondary, button_tertiary, button_danger and success; `button_primary/gold_round.svg` (the 60-point round action, a sprite); `button_tertiary/parchment.svg` (the tertiary face for paper grounds); and `art/ui/palette.json` (the tokens' colours and gradients resolved, plus a `kit` section of the colours this batch adds, each with where it comes from).
  - Every box is a 9-slice piece, 38 x (42 + lip) points, slices 18/20/18/(20 + lip). Normal: body gradient lit from the top, a gloss band over the top 36%, rim, highlight and shade strokes, the ink edge, a solid lip of `drop_m` (3 for the tertiary). Pressed: the face sinks `press_travel` onto the lip, darker, the gloss gone. Disabled: flat, no lip, muted, words above 4.5:1. Locked: the teal gradient lifted a step (`kit.locked_top`, `kit.locked_bottom`), hatching on the end caps only, white rim. High contrast: opaque flat fills, 3-point black edges, black lips, no gloss or grain.
  - Stretch-safe: the hatching is masked to the end caps and the leather seam is a solid groove with a lit line, so neither kinks or smears when the middle is stretched.
  - `art/ui/kit_build/proof_kit.py` renders every piece out of the baked atlases at phone density on the grounds it is meant for, runs value-steps (`tools/ui_gate/checks.py`) and the labels' contrast, and makes the contact sheets. `proof/tiles/` is regenerated and not committed.
- Self-score against the rubric (statements, not a rating):
  - 1 Layered materials: primary, danger and success have body gradient, gloss band, rim and lip; secondary is leather with grain-free radial body, rim, seam and lip; the tertiary is the quiet rank (body gradient, edge, lip, no gloss). Every state and twin is baked (`bake.js --check`). Risk: the tertiary's lack of gloss may read flat beside the others.
  - 2 Display type: the kit carries no words; the proof's labels are Manrope 800, with ink outlines on danger and success.
  - 8 Colour roles and value: gold only on the main action, red on danger, green on success; every face is two value steps or more off each ground it is used on (worst ΔL* 21.9), words 4.78:1 or more. All colours come from the tokens or the palette's `kit` section.
  - 13 Light behind UI: one top light throughout, highlights above, lips and shade below; pressed faces lose their top light.
- Known limits (where each face may go): gold on parchment is about ΔL* 15, so parchment grounds take leather or the tertiary parchment face; leather on the dark grounds fails, so leather goes on parchment and oak; the tertiary violet is for dark grounds only.
- Half done: none.
- Open hypotheses: the whole kit will not fit one 2048 atlas at 6 px/pt (batch 1a reaches y 1268); AIA-R12.
- Next step: none; wait for the lead.

## Tried and failed
- 2026-10-31 Pre-check in a fresh container: it failed three times on missing one-time setup (the WebAssembly Rust target, gdlint, Python Playwright), not on the change. Installing what the README's "Once" block lists, with Python Playwright pinned to the pre-installed 1.63.0 so it finds the browser in /opt/pw-browsers, passed it.
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
- 2026-11-04 Kit pieces at 64 x 54 points: batch 1a alone filled the 2048 atlas at 6 px/pt. 38 x (42 + lip) with 18-point caps fits it in 1268 rows.
- 2026-11-04 Diagonal hatching across a 9-slice face: it kinks where the middle stretches. Masked to the end caps it holds.
- 2026-11-04 A dashed stitch on the leather face: stretched, the dashes smear into long bars. A solid groove with a lit line stretches cleanly.
- 2026-11-04 The tokens' locked gradient as it is: on the lit foot of the night backdrop it is 1.8 value steps off (ΔL* 17.9). Lifted a step (#4A9AA0 to #30707A) it passes.
