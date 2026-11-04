# AIA-2 icon maker: progress

- Status: Green, and the last push (bef6eac2) has P1-AIA2-icons-1b: five new icons (aether, essence, renown, starglass, season stars) and Starlight in `icons_48` and `icons_256`, and a finish that answers 1a's critiques (a blended toon ramp, a gloss band, a three-stop body gradient, a soft drop). Every icon was rebaked.
- Progress: 2 of 5 tasks merged (P1-AIA2-toon-route at 9b2bde70, P1-AIA2-icons-1a at 8ce107c9); 0 items passed by the gate. P1-AIA2-icons-1b waits for its pre-check and the gate.
- Done: the toon route, with Starlight and Pip; the eight heist controls; batch 1b's currencies and resources (Insight dropped: the design has none, §11.7).
- Next: the gate on "icon sheet at 48 and 96 points and in grayscale" at bef6eac2, then ready.
- Blocked by: none.
- Owner decision needed: none.

| Deliverable | Weight (h) | Status | Evidence |
|---|---:|---|---|
| P1-AIA2-toon-route: list, scene format, two icons end to end | 3 | Merged at 9b2bde70 | `bake.js --check`, `check_icons.py` and `run_checks.sh` PASS at 02e7ef0f |
| P1-AIA2-icons-1a: the eight heist controls in `icons_48` | 4 | Merged at 8ce107c9 | gate advisory at 5f759a03: Light behind UI pass; three qualities fail 3 of 3 |
| P1-AIA2-icons-1b: the currencies and resources in `icons_48` and `icons_256` | 3 | Pre-check and gate pending at bef6eac2 | `python3 -B art/ui/icons/studio/check_icons.py`: all 42 faces pass (21 pieces, 2 modes). `node tools/ui_bake/bake.js --check`: icons_48 15 pieces, icons_256 6 pieces, both ok |

## Handoff

- **Last verified commit:** bef6eac2 (`check_icons.py` and `bake.js --check` green; pre-check started).

### Done

**The finish, for 1a's critiques** (every icon changes, a full rebake):
- `studio/toon.js`: the four ramp steps blend over a narrow band (`rampSoft` 0.05), so faces shade without posterised edges; a hard-edged `cream` gloss band sits on the key side (Blinn term over 0.955); `toon(face, rim, glossy)` scales it per material (0 for none).
- `studio/finish.js`: the drop is soft (blur 0.022R, alpha 0.55, offset down and a little right), not a hard ink offset; after the inner light, a three-stop body gradient lays a `cream` lift on the top, nothing in the middle, `drop` at the foot.
- `studio/shapes.js`: `star5Shape` (five-point star with rounded tips), `lathe` and `profile` (turned solids from a spline).

**Batch 1b in `art/ui/icons/`** (each in `icons_48` and `icons_256`):

| Icon | What it shows | Light |
|---|---|---|
| `resources/aether` | a teal flask on a time-shadow sea, a gold collar, a wooden cork, a cloud puff above | `time_light` |
| `resources/essence` | a turned drop of the essence green with a bubble in it, a small darker sister drop | `life_light` |
| `resources/renown` | a gold medal with a cream star, four laurel leaves a side, two violet ribbon tails | `motion_light` |
| `currencies/starglass` | a cut five-point star gem, flat facets in the spirit colour | `spirit_light` |
| `currencies/seasonstars` | three stars large to small: time, matter, cream | `time_light` |
| `resources/starlight` | unchanged design, set 8% larger to keep its 32 pt coverage with the soft drop | `motion_light` |

`currencies/insight` is dropped from `list.md`: §11.7 says there is no Insight, and no client code uses the icon. A request to the lead (AIA2-R2) has the default.

**Check figures** (normal mode; high contrast passes for all, median 8.0–9.0 px against 8.0 px):

| Icon | Family | Median | p10 | 32 pt cover | Ellipse |
|---|---|---:|---:|---:|---:|
| aether | 48 / 256 | 5.0 / 5.0 | 4.2 / 4.1 | 30% / 26% | 0.78 / 0.74 |
| essence | 48 / 256 | 5.0 / 5.0 | 4.2 / 4.3 | 32% / 28% | 0.73 / 0.71 |
| renown | 48 / 256 | 5.0 / 5.0 | 4.2 / 4.3 | 38% / 33% | 0.93 / 0.92 |
| starglass | 48 / 256 | 5.0 / 5.1 | 4.2 / 4.3 | 44% / 38% | 0.83 / 0.82 |
| seasonstars | 48 / 256 | 5.0 / 5.0 | 3.6 / 4.0 | 36% / 30% | 0.75 / 0.70 |
| starlight | 48 / 256 | 5.3 / 5.4 | 3.9 / 4.1 | 33% / 27% | 0.69 / 0.63 |

Medians fell from about 6 to 5.0 px: the old hard drop was counted as ink. They pass the 0.85 threshold (4.5 px).

### Self-score

Against rubric.md quality 3 (Painted or rendered icons):

| Rule | Score | Why |
|---|---|---|
| 1. 3D form, top-left key, rim, specular, dark outline | Pass | Lathed and bevelled solids, keyed top left, rim on the lit side, a gloss band as the specular, the ink ring |
| 2. Outline 2 pt at the size shown | Pass, scripted | all 42 faces |
| 3. A dark shape at 32 pt | Pass, scripted | coverage 26–44%, ellipse 0.63–0.93 |
| 4. §21.8 volume | Pass | blended ramp, gloss band, three-stop body gradient, soft drop |
| 5. One toon look | Pass | no PBR; one material for all |
| 6. Law and school frames | Not applicable | |

Other qualities: **Layered materials**: glass, gold, wood, cloud and leaf differ by hue, ramp and gloss (`glossy` 0.6 on the medal face, full on glass). **Colour roles and value**: gold is a material (collar, medal) and never a fill for an action; each icon's parts step in value (renown's dark ribbons, light star; seasonstars dark to light). **Light behind UI**: a glow in the light token, one top-left light.

**Risks a judge may see:**
- Starglass's facets are subtle at 48 pt; it may read as a plain star.
- Renown's ellipse overlap (0.93) is close to the 0.96 limit: a round medal.
- Glints are still separate cream sparks; the gloss band now carries the real highlight.
- No wood grain yet (aether's cork is small); 1a's sagewheel grayscale and gold-as-fill notes are not addressed here (1a is merged; a later pass).

### Half done

None.

### Open hypotheses

- The client may show `icons_256` at sizes other than 96 pt. If so, the outline is 2 pt only at 96.

### Next step

1. The lead runs the gate at bef6eac2; on a pass with the pre-check green, mark ready.
2. A later pass on 1a for the sagewheel's values and gold roles, if the lead opens one.

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
