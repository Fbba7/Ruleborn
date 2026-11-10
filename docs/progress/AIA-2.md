# AIA-2 icon maker: progress

- Status: Green (P1-AIA2-icons-2b: six new icons baked, three of batch 2a reworked on the gate's notes; `check_icons.py` passes all 80 faces, `bake.js --check` ok, a rebake of both families is byte for byte; pre-check running on 29e91db0).
- Progress: 4 of 5 tasks merged (P1-AIA2-toon-route at 9b2bde70, P1-AIA2-icons-1a at 8ce107c9, P1-AIA2-icons-1b at 90f72fd7, P1-AIA2-icons-2a at 027379a2); P1-AIA2-icons-2b is with the gate.
- Done: the toon route, with Starlight and Pip; the eight heist controls; batch 1b's currencies and resources; batch 2a's eight heist-status and HUD icons; batch 2b's six reward icons.
- Next: the gate's verdict on P1-AIA2-icons-2b and the lead's merge. Batches 3 and 4 are deferred (D13 (c)).
- Blocked by: none.
- Owner decision needed: none.

| Deliverable | Weight (h) | Status | Evidence |
|---|---:|---|---|
| P1-AIA2-toon-route: list, scene format, two icons end to end | 3 | Merged at 9b2bde70 | `bake.js --check`, `check_icons.py` and `run_checks.sh` PASS at 02e7ef0f |
| P1-AIA2-icons-1a: the eight heist controls in `icons_48` | 4 | Merged at 8ce107c9 | gate advisory at 5f759a03: Light behind UI pass; three qualities fail 3 of 3 |
| P1-AIA2-icons-1b: the currencies and resources in `icons_48` and `icons_256` | 3 | Merged at 90f72fd7 | gate pass on all four qualities (advisory) at bef6eac2; resync at 5ecb0202 |
| P1-AIA2-icons-2a: eight heist-status and HUD icons in `icons_48` | 4 | Merged at 027379a2 | gate 12 of 12 at 6a382d97 (advisory); pre-check PASS on ac4809ed |
| P1-AIA2-icons-2b: the six reward icons in `icons_48`, five of them in `icons_256` | 3 | Gate requested at 29e91db0 | `python3 -B art/ui/icons/studio/check_icons.py`: all 80 faces pass (29 and 11 pieces, 2 modes). `node tools/ui_bake/bake.js --check`: icons_48 29 pieces, icons_256 11 pieces, both ok |

## Handoff

- **Last verified commit:** 29e91db0 (pre-check running on 29e91db0; `check_icons.py` and `bake.js --check` green; `node art/ui/icons/studio/bake_icons.js icons_48 icons_256 --out <scratch>` gives the six committed files byte for byte, 10 November). `bash tools/ui_bake/guard.sh` was not run in full in this session; its rebake step is what the line above repeats.

### Done

**Batch 2b in `art/ui/icons/`** (list.md numbers 24 to 29; number 30, `crew/pip`, was baked with the route). Each is in `icons_48`; all but the star are also in `icons_256`.

| Icon | What it shows | Light |
|---|---|---|
| `currencies/pages` | three fanned codex sheets (a gold-edged one under two parchment ones), three ruled lines, a gold star seal, a ribbon marker in the matter colour | `motion_light` |
| `season/tierreward` | a closed wooden chest with a barrel lid, a gold lip and two gold straps, tied with a matter-colour ribbon and bow | `motion_light` |
| `alerts/seasonreward` | the same chest open, with its gold lock plate: a dark inside, a heap of gold, four coins, a four-point star rising | `starlight` |
| `hud/star` | one puffed gold star with rounded tips | `starlight` |
| `heistoutcomes/clean` | a scalloped seal in the success green, a gold ring, a dark green face, a cream tick, a spark at the upper right | `success_light` |
| `heistoutcomes/worthyourtime` | an open cloth sack, slumped, with a rolled lip, a tie cord with a knot and loose ends and a stitched patch; coins heaped in it and a gold star standing on the heap | `motion_light` |

**New shared parts** in `studio/shapes.js`: `chest(S, {open, ribbon, light})` (one chest for both reward icons: `open` swings the lid on its back edge, `ribbon` swaps the lock plate for a band and bow) and `coin(S, r)`. README.md's scene-format table names them.

**The gate's notes on batch 2a** (the verdict at ac4809ed), taken here as the last handoff said:

| Icon | Note | Change |
|---|---|---|
| `heiststatus/spotted` | the starburst is flat | two stacked bursts with a deeper bevel: the warn one behind, a smaller pale gold one turned between its points |
| `heiststatus/alarm` | the sound arcs are flat | each arc is a thicker glossy tube with a ball at each end |
| `heiststatus/lootbag` | the dark body sits close to the ground in grayscale | a paler rim light, the ruffle in the lighter leather, a hem in the rim leather round the foot |

The other icons' pixels are unchanged; both manifests change in their regions for the new pieces and in `sources_hash`.

**Check figures** (outline target 5.3 px normal, 8.0 px high contrast; normal / high contrast):

| Icon | Family | Median | p10 | 32 pt cover | Ellipse | Ring edge |
|---|---|---:|---:|---:|---:|---:|
| pages | 48 | 4.9 / 8.0 | 4.0 / 7.0 | 39% / 53% | 0.85 / 0.86 | 100% / 100% |
| pages | 256 | 4.8 / 8.0 | 3.9 / 7.0 | 34% / 40% | 0.84 / 0.85 | 100% / 100% |
| tierreward | 48 | 5.0 / 8.0 | 4.0 / 7.0 | 43% / 56% | 0.92 / 0.93 | 100% / 100% |
| tierreward | 256 | 5.0 / 8.0 | 4.0 / 7.0 | 38% / 44% | 0.91 / 0.92 | 100% / 100% |
| seasonreward | 48 | 5.0 / 8.0 | 4.1 / 7.0 | 44% / 59% | 0.85 / 0.88 | 100% / 100% |
| seasonreward | 256 | 5.0 / 8.0 | 4.0 / 7.0 | 39% / 45% | 0.83 / 0.85 | 100% / 100% |
| star | 48 | 4.9 / 9.0 | 4.0 / 7.5 | 30% / 42% | 0.79 / 0.84 | 98% / 100% |
| clean | 48 | 4.9 / 8.0 | 4.1 / 7.0 | 39% / 53% | 0.83 / 0.87 | 100% / 100% |
| clean | 256 | 5.0 / 8.0 | 4.1 / 7.0 | 34% / 40% | 0.82 / 0.84 | 100% / 100% |
| worthyourtime | 48 | 5.0 / 8.0 | 4.1 / 7.0 | 37% / 50% | 0.85 / 0.89 | 97% / 100% |
| worthyourtime | 256 | 5.0 / 8.0 | 4.0 / 7.0 | 32% / 38% | 0.83 / 0.85 | 96% / 100% |
| alarm (reworked) | 48 | 4.9 / 8.0 | 3.9 / 7.0 | 36% / 54% | 0.76 / 0.89 | 100% / 100% |
| lootbag (reworked) | 48 | 5.1 / 8.0 | 4.3 / 7.0 | 34% / 47% | 0.83 / 0.87 | 100% / 100% |
| spotted (reworked) | 48 | 5.0 / 10.5 | 3.9 / 8.0 | 40% / 56% | 0.82 / 0.85 | 100% / 100% |

### Self-score

Against rubric.md quality 3 (Painted or rendered icons), from the contact sheet at 256 px, 48 pt, 32 pt, grayscale and high contrast:

| Rule | Score | Why |
|---|---|---|
| 1. 3D form, top-left key, rim, specular, dark outline | Pass | boxes with a barrel lid, lathed sack, puffed slabs, tori and coins as solids; keyed top left with the gloss band on the metal |
| 2. Outline 2 pt at the size shown | Pass, scripted | all 80 faces |
| 3. A dark shape at 32 pt | Pass, scripted | coverage 30–44% (normal), ellipse 0.79–0.92 |
| 4. §21.8 volume | Pass | the 1b finish: blended ramp, gloss band, body gradient, soft drop |
| 5. One toon look | Pass | one `S.toon` material throughout |
| 6. Law and school frames | Not applicable | |

Other qualities: **Layered materials**: wood and cloth (matt), gold straps, coins and seals (glossy), parchment (low gloss), ribbon. **Colour roles and value**: gold is the reward in every icon; green only on the clean seal (success); the matter colour only as ribbon; each icon steps from a dark outer part (wood, cloth, the seal's rim) to a light focal point (the star, the tick, the seal). **Light behind UI**: a glow in each icon's light token.

**Risks a judge may see:**
- Tierreward is the boxiest icon (ellipse 0.92/0.93, limit 0.96); the bow is what breaks the block.
- Tierreward and seasonreward share one chest by design (closed with a ribbon, open with coins); at 32 pt the open lid and the star are what tell them apart.
- Worthyourtime and lootbag are both sacks: one open, brown and brimming, the other tied, in leather with a star on its front. The patch on worthyourtime is faint under 48 pt.
- Pages' three ruled lines merge into a tone at 32 pt; the fan, the seal and the ribbon carry it there.
- `hud/star` and `resources/starlight` are both gold stars (one star against two struck ones).
- The glints are still separate cream sparks (as in 1b).

### Half done

None.

### Open hypotheses

- The client may show `icons_256` at sizes other than 96 pt. If so, the outline is 2 pt only at 96.
- No client code names the six new icons yet; their callers will choose `icons_48` or `icons_256` by size.

### Next step

1. The lead runs the Icons gate on P1-AIA2-icons-2b at the requested commit and merges.
2. If the gate fails a quality: fix what its notes name, rebake, run `check_icons.py` and the pre-check again.
3. Batches 3 and 4 stay deferred until the lead opens them.

**For the lead.** Godot still writes `client/tests/a11y_motion_tests.gd.uid` on import in a fresh container; it is not tracked and not mine, so I deleted my copy again and did not commit it.

## Tried and failed

- 2026-11-04 Pip's bust at the studio's own crop: it cut the ears and the shoulders at the badge's square. Widening the crop 1.3 times, with a 2% top margin, keeps the whole head.
- 2026-11-04 Pip on a disc of the motion colour: Pip's gold fur on the motion amber (#F2B43C) is gold on gold, so at 48 pt the face is lost. A night-enamel disc with the amber in the ring separates them.
- 2026-11-04 The render placed at the badge's top edge: the ears were clipped by the square. Placing it at 0.82 of the side, 7% down, keeps them.
- 2026-11-04 The board's outline (1/24 of the side) for `icons_256`: it measured 13.8 px, 4 pt at 96 pt. The finish now sets outline widths in points of the size shown.
- 2026-11-04 The 32 pt edge check in high contrast against "dark": the edge there is the light keyline, by design, so it failed every face. In high contrast it now checks for light.
- 2026-11-04 Cast as a long thin wand on the diagonal, with a free-floating spark: outline p10 0.6 px. The spark's ring stood apart from the wand's.
- 2026-11-04 Cast with the spark joined to the orb, but still a long wand: p10 1.8 px on the atlas. The outline check's rays from the centre run along the wand's long sides, so each stopped on a one-pixel step. A stubby wand fixed it.
- 2026-11-04 Split crew's prongs short and close together: the fork read as a crown or a bundle at 48 pt. Longer prongs, wider angles and the pips further out made it a fork.
- 2026-11-04 The finish's 48 stamps round the outline (the board's count): holes in the ink ring at thin points. The stamps now sit a pixel apart.
- 2026-11-04 Running `check_icons.py` (or importing it) without `-B` before a bake: Python wrote `art/ui/icons/studio/__pycache__/`, the bake hashed it into `sources_hash`, and a clean checkout called both manifests stale. Run the Python checks with `python3 -B`, and run `git status --ignored art/ui` before a bake.
- 2026-11-04 The 1a finish (a four-step hard ramp, a hard ink drop at 0.006R blur, alpha 0.8): the gate saw flat fills and a pasted shadow. Now a blended ramp, a gloss band, a body gradient and a soft drop.
- 2026-11-04 The soft drop alone: essence 256 (22%) and starlight 256 (24%) fell under 25% coverage at 32 pt, since the hard drop had added to the shape. Scaling them up 14% and 8% fixed it.
- 2026-11-04 Season stars with sharp tips and thin waists: outline p10 3.1 px. Rounded tips and fatter waists give 3.6 px and over.
- 2026-11-04 Starglass with an octahedron core inside the star: it read as a second object. A faceted, flat-shaded star alone is cleaner.
- 2026-11-04 Renown at scale 1.2: the medal's top clipped the square. Scale 1.08, raised 0.08.
- 2026-11-04 committed icons_48_hc.webp baked on an idle machine: GPU-backed canvas dropped grow() stamps (Pip's hc ring an octagon), so the lead's loaded rebake differed; fixed with software canvases.
- 2026-11-04 Vaultprogress and strain as plain discs: ellipse overlap 0.99 (over 0.96). Hinges and a progress head knob on the vault, a stem, nut and steam on the gauge brought them to 0.94 and 0.82.
- 2026-11-04 Strain's crack as a polygon slab: the triangulation failed and the crack vanished. Rod segments along a zigzag work; a branch made it read as a stick figure, so it was removed.
- 2026-11-04 Bagcapacity as a straight-sided vessel with coin dots: it read as a polka-dot jar. A sack profile with a bunched neck and a green fill-line ring reads as a bag being filled.
- 2026-11-04 Two sound arcs on each side of the alarm: thin arcs broke the high-contrast ring edge (89%). One thicker arc per side gives 100%.
- 2026-11-04 Lootbag's star flush with the sack and a glossy dark leather: the star was buried and the gloss read as a smudge. The star now stands proud of the sack (z 1.12), the leather is matt and lighter.
- 2026-11-09 Software canvases as the cure for the grow's octagon: the lead's container still baked `crew/pip` differently in high contrast. Hundreds of `drawImage` stamps are not the same on every canvas backend; the grow is now computed on the pixels.
- 2026-11-09 The pixel grow on a canvas the size of the render: outlines were cut where a shape touches the render's edge (the stamps had spilled past it). The grown canvas is now wider by the radius.
- 2026-11-10 Worth your time as a smooth lathed sack with a plain lip: it read as a clay pot. A slumped profile, a tie cord with a knot and two loose ends, and a stitched patch make it cloth.
- 2026-11-10 Lootbag's body with a gloss of 0.25 to lift it in grayscale: the gloss band sat on the leather as a grey smudge above the star (the same fault as on 4 November). The body is matt again; a paler rim light, a lighter ruffle and a hem in the rim leather do the lifting.
- 2026-11-10 Baking while `client/build.sh` was importing in the same container: Godot read `icons_48_hc.webp` half written and rewrote its `.import` file with `valid=false`. Restore the `.import` files with `git checkout` after such a bake; `git diff --stat -- client/ui/art/*.import` must be empty before a commit.

