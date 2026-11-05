# AIA-2 icon maker: progress

- Status: Green (P1-AIA2-icons-2a ready at 6a382d97: pre-check PASS 00:42 UTC, 5 November; gate request set).
- Progress: 3 of 5 tasks merged (P1-AIA2-toon-route at 9b2bde70, P1-AIA2-icons-1a at 8ce107c9, P1-AIA2-icons-1b at 90f72fd7); P1-AIA2-icons-2a waiting for its pre-check and the Icons gate.
- Done: the toon route, with Starlight and Pip; the eight heist controls; batch 1b's currencies and resources; batch 2a's eight heist-status and HUD icons.
- Next: the Icons gate on "icon sheet at 48 and 96 points and in grayscale", then the lead's merge.
- Blocked by: none.
- Owner decision needed: none.

| Deliverable | Weight (h) | Status | Evidence |
|---|---:|---|---|
| P1-AIA2-toon-route: list, scene format, two icons end to end | 3 | Merged at 9b2bde70 | `bake.js --check`, `check_icons.py` and `run_checks.sh` PASS at 02e7ef0f |
| P1-AIA2-icons-1a: the eight heist controls in `icons_48` | 4 | Merged at 8ce107c9 | gate advisory at 5f759a03: Light behind UI pass; three qualities fail 3 of 3 |
| P1-AIA2-icons-1b: the currencies and resources in `icons_48` and `icons_256` | 3 | Merged at 90f72fd7 | gate pass on all four qualities (advisory) at bef6eac2; resync at 5ecb0202 |
| P1-AIA2-icons-2a: eight heist-status and HUD icons in `icons_48` | 4 | Ready at 6a382d97: pre-check PASS; gate pending | `python3 -B art/ui/icons/studio/check_icons.py`: all 46 faces pass (23 pieces, 2 modes). `node tools/ui_bake/bake.js --check`: icons_48 23 pieces, icons_256 6 pieces, both ok |

## Handoff

- **Last verified commit:** 6a382d97 (pre-check PASS, 2026-11-05T00:42:36Z; check_icons and bake.js --check green).

### Done

**Batch 2a in `art/ui/icons/`** (each in `icons_48`, normal and high contrast; none is in `icons_256`, as list.md says):

| Icon | What it shows | Light |
|---|---|---|
| `heiststatus/lootbag` | a turned leather sack, a ruffled neck tied with a gold cord, a gold star stamped on the front | `motion_light` |
| `heiststatus/clock` | a gold pocket clock: bezel, paper face, four ticks, ink hands, crown and loop, a red alarm pin | `time_light` |
| `heiststatus/bagcapacity` | a sack filled in the motion colour up to a green fill-line ring; empty parchment above, a dark opening | `motion_light` |
| `heiststatus/alarm` | a tilted red bell with a gold lip, knob and clapper; one thick sound arc on each side | `alarm_light` |
| `heiststatus/spotted` | an open eye (red lids, white, a time-blue iris, ink pupil) in front of a yellow eight-point flash | `alarm_light` |
| `heiststatus/vaultprogress` | a stone vault door with a gold wheel and two hinges, in a dark track ringed three-quarters with green progress and a bright head knob | `success_light` |
| `hud/shield` | a heater shield: gold rim, time-blue field, cream chevron, gold boss | `time_light` |
| `hud/strain` | a gold pressure gauge with six band colours from quiet to breaking, the needle near the top band, a crack across the face, a stem and nut, steam puffs | `alarm_light` |

**Check figures** (`icons_48`; outline target 5.3 px normal, 8.0 px high contrast):

| Icon | Median (n / hc) | p10 (n / hc) | 32 pt cover (n / hc) | Ellipse (n / hc) |
|---|---:|---:|---:|---:|
| alarm | 5.0 / 8.0 | 3.9 / 7.0 | 34% / 51% | 0.74 / 0.88 |
| bagcapacity | 5.0 / 7.5 | 4.0 / 7.0 | 37% / 51% | 0.85 / 0.89 |
| clock | 5.0 / 7.5 | 4.3 / 7.0 | 32% / 44% | 0.87 / 0.89 |
| lootbag | 5.3 / 8.0 | 4.4 / 7.0 | 34% / 46% | 0.84 / 0.87 |
| spotted | 5.3 / 10.5 | 3.9 / 9.0 | 41% / 57% | 0.81 / 0.85 |
| vaultprogress | 5.0 / 7.5 | 4.3 / 7.0 | 54% / 69% | 0.94 / 0.95 |
| shield | 5.0 / 7.5 | 4.0 / 7.0 | 40% / 52% | 0.89 / 0.91 |
| strain | 5.0 / 7.5 | 4.0 / 7.0 | 36% / 49% | 0.82 / 0.85 |

The ring edge is 100% for all of them in both modes. The earlier icons are unchanged; `icons_256.json` changes only in its `sources_hash` line, because the sources directory changed.

### Self-score

Against rubric.md quality 3 (Painted or rendered icons):

| Rule | Score | Why |
|---|---|---|
| 1. 3D form, top-left key, rim, specular, dark outline | Pass | Lathed sacks and bell, bevelled slabs, tori; keyed top left with the gloss band |
| 2. Outline 2 pt at the size shown | Pass, scripted | all 46 faces |
| 3. A dark shape at 32 pt | Pass, scripted | coverage 32–54% (normal), ellipse 0.74–0.94 |
| 4. §21.8 volume | Pass | the 1b finish: blended ramp, gloss band, body gradient, soft drop |
| 5. One toon look | Pass | one `S.toon` material throughout |
| 6. Law and school frames | Not applicable | |

Other qualities: **Layered materials**: leather (matt, glossy 0), gold (glossy), paper and stone (low gloss), enamel on the bell and shield. **Colour roles and value**: red only for alarm states (alarm, spotted, the clock's pin), green only for progress (the fill line, the vault ring), gold as metal trim; every icon steps from a dark outer part to a light focal point. **Light behind UI**: a glow in each icon's light token.

**Risks a judge may see:**
- Vaultprogress is the roundest icon (ellipse 0.94/0.95, near the 0.96 limit); the hinges and head knob are what break the disc.
- Strain's six band colours are small at 48 pt; it reads as a gauge with a crack before it reads as bands.
- Lootbag and bagcapacity are both sacks: different fill and colour, but similar outlines.
- The glints are still separate cream sparks (as in 1b).

### Half done

None.

### Open hypotheses

- The client may show `icons_256` at sizes other than 96 pt. If so, the outline is 2 pt only at 96.

### Next step

1. The Icons gate on the 2a sheet at 6a382d97 (pre-check recorded).
2. The Icons gate on the 2a sheet; then ready.

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
