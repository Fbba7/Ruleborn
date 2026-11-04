# AIA-2 icon maker: progress

- Status: Green, waiting for the gate. The last push has P1-AIA2-icons-1a's eight heist controls baked into `icons_48`, and a finish fix (a solid outline ring at thin points). The pre-check at c1d14d38 failed on stale icon manifests (a `__pycache__` under `art/ui` was hashed at bake time); 5f759a03 rebakes them clean, and the pre-check at cd30ce21 passed (exit 0).
- Progress: 1 of 5 tasks merged (P1-AIA2-toon-route at 9b2bde70); 0 items passed by the gate. P1-AIA2-icons-1a is waiting for its gate.
- Done: the toon route, with Starlight and Pip; the eight heist-control icons (ability, aim, call skiff, cast, get out, regroup, Sage's wheel, split crew) in `icons_48`, normal and high contrast.
- Next: the gate on P1-AIA2-icons-1a's icon sheet, then P1-AIA2-icons-1b (four resources and three currencies).
- Blocked by: none.
- Owner decision needed: none.

| Deliverable | Weight (h) | Status | Evidence |
|---|---:|---|---|
| P1-AIA2-toon-route: list, scene format, two icons end to end | 3 | Merged at 9b2bde70 | `bake.js --check`, `check_icons.py` and `run_checks.sh` PASS at 02e7ef0f |
| P1-AIA2-icons-1a: the eight heist controls in `icons_48` | 4 | Waiting for its gate | `python3 art/ui/icons/studio/check_icons.py`: all 24 faces pass (12 pieces across 2 families, in 2 modes). `node tools/ui_bake/bake.js --check`: icons_48 10 pieces, icons_256 1 piece, both ok |

## Handoff

- **Last verified commit:** 5f759a03 (scripted checks green, `bake.js --check` green in a clean worktree; pre-check green at cd30ce21).

### Done

**Eight scenes in `art/ui/icons/heistcontrols/`.** Each one is a toy-like solid in the one toon light. They share the parts in `studio/shapes.js`: `box`, `ball`, `rod`, `pip`, `arrowShape`, `boltShape` and `slab`. Colours are token names only.

| Icon | What it shows | Light |
|---|---|---|
| `ability` | a motion-amber lightning bolt with a cream star flare | `energy_light` |
| `aim` | a stone ring with four cream ticks around an alarm-red eye | `alarm_light` |
| `callskiff` | a wooden hull with a gold trim, a mast and a cream sail, inside a time-teal arc | `time_light` |
| `cast` | a stubby wooden wand with a leather grip, a gold collar, a matter-violet orb and a cream spark | `matter_light` |
| `getout` | a wooden door frame, the door swung open on the dark, and a success-green arrow out | `success_light` |
| `regroup` | three crew pips (time, energy, matter) on a gold pad round an alarm pennant | `time_light` |
| `sagewheel` | a ship's helm whose six segments are the six school colours, with spokes, a gold rim and hub, and a cream star | `motion_light` |
| `splitcrew` | a gold three-way fork, with a pip at the end of each prong | `motion_light` |

`list.md`'s batch 1a now describes these designs.

**A fix in the finish (`studio/finish.js`).** `grow()` stamped the silhouette at 48 angles, as on the style board. At R = 640 that is 3.9 px apart round a 2 pt ring. Around a thin point (a star's tip) the gaps between stamps left see-through holes in the ink. The stamps now sit at most a pixel apart (`max(48, ceil(2πr))`). Every icon was rebaked; Starlight and Pip changed only at the edges (both still pass). The board (`art/ui/board/studio.html`) still has 48; its owner may want the same fix.

**Check figures** (`check_icons.py` on the baked atlas). Each row gives the outline median and tenth percentile against 5.3 px, then 32 pt coverage and ellipse overlap. In high contrast every heist control passes, with median 7.5–9.5 px and p10 7.0–7.5 px against 8.0 px.

| Icon (normal) | Median | p10 | 32 pt cover | Ellipse |
|---|---:|---:|---:|---:|
| ability | 6.0 | 4.0 | 34% | 0.79 |
| aim | 7.0 | 4.3 | 38% | 0.76 |
| callskiff | 5.9 | 4.5 | 47% | 0.88 |
| cast | 5.9 | 4.0 | 33% | 0.76 |
| getout | 6.2 | 4.9 | 41% | 0.80 |
| regroup | 6.0 | 4.4 | 39% | 0.79 |
| sagewheel | 6.3 | 4.2 | 41% | 0.77 |
| splitcrew | 7.3 | 4.4 | 42% | 0.76 |

### Self-score

Against rubric.md quality 3 (Painted or rendered icons):

| Rule | Score | Why |
|---|---|---|
| 1. 3D form, top-left key, rim, specular, dark outline | Pass | Every icon is a lit solid, keyed from (-3, 4, 5) with the rim on the lit side. Glints act as the specular and the ink ring as the outline. |
| 2. Outline 2 pt at the size shown | Pass, scripted | `check_icons.py`, all faces |
| 3. A dark shape at 32 pt | Pass, scripted | Coverage 33–47% and ellipse overlap 0.76–0.88: none is a blob |
| 4. §21.8 volume | Pass | The toon ramp and the inner light carry the gradient, the glints are the gloss, and the drop is soft |
| 5. One toon look | Pass | No PBR. The pips are toy figures in school colours, not characters, so no model render is needed |
| 6. Law and school frames | Not applicable | No law icon. The Sage's wheel carries all six school colours, in §21.2's order round the helm |

Against the gate item's other qualities:
- **Layered materials.** Wood, leather, gold, stone and enamel stay distinct by hue and ramp step, each with its own rim.
- **Colour roles and value.** Each control takes its role's colour: alarm for aim, success for get out, a school colour for cast and ability. In grayscale the silhouettes and the ink ring carry every icon.
- **Light behind UI.** Each icon has a glow in its light token behind it, and an inner light toward the top left.

**Risks a judge may see:**
- In grayscale the Sage's wheel's six segments fall into close greys. The spokes and rim still read, but the six colours do not.
- In grayscale, regroup's three pips are close in value. They read by their shape.
- At 45 px, the split crew's pips and the regroup pips become dots. The fork and the flag keep the shape.
- `regroup` and `callskiff` share `time_light`, and `sagewheel` and `splitcrew` share `motion_light`. Side by side on the HUD, their glows match.

### Half done

None.

### Open hypotheses

- The client may show `icons_256` at sizes other than 96 pt. If so, the outline is 2 pt only at 96.
- The outline check counts the soft drop as ink where it is darker than 0.2 and over alpha 200. Below an icon, the drop adds to the measured ring. That is why medians run above 2 pt.

### Next step

1. Set the gate request on the icon sheet at the verified commit.
2. When it passes and the pre-check is green, mark the task ready.
3. Then start P1-AIA2-icons-1b.

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
