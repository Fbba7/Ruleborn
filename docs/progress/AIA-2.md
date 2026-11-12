# AIA-2 icon maker: progress

- Status: Yellow (P2-AIA2-busts: Bramble and Hollow painted flat at the source in `creature_bust.gd`, cb52e5da; `guard.sh` OK with every heist screen at its draw-call record; pre-check running on 354a9b1b).
- Progress: 5 of 6 tasks merged (P1-AIA2-toon-route at 9b2bde70, P1-AIA2-icons-1a at 8ce107c9, P1-AIA2-icons-1b at 90f72fd7, P1-AIA2-icons-2a at 027379a2, P1-AIA2-icons-2b at d30530ee); P2-AIA2-busts is in its checks.
- Done: the toon route and icon batches 1a, 1b, 2a and 2b; the two painted busts.
- Next: the pre-check, then the gate on "heist at 100% text" (Character presence) and the lead's merge. Batches 3 and 4 are deferred (D13 (c)).
- Blocked by: none. AIA2-R3 (non-blocking) asks the lead to drop the two kinds from `FxPortrait.TOON` after this lands.
- Owner decision needed: none.

| Deliverable | Weight (h) | Status | Evidence |
|---|---:|---|---|
| P1-AIA2-toon-route: list, scene format, two icons end to end | 3 | Merged at 9b2bde70 | `bake.js --check`, `check_icons.py` and `run_checks.sh` PASS at 02e7ef0f |
| P1-AIA2-icons-1a: the eight heist controls in `icons_48` | 4 | Merged at 8ce107c9 | gate advisory at 5f759a03: Light behind UI pass; three qualities fail 3 of 3 |
| P1-AIA2-icons-1b: the currencies and resources in `icons_48` and `icons_256` | 3 | Merged at 90f72fd7 | gate pass on all four qualities (advisory) at bef6eac2; resync at 5ecb0202 |
| P1-AIA2-icons-2a: eight heist-status and HUD icons in `icons_48` | 4 | Merged at 027379a2 | gate 12 of 12 at 6a382d97 (advisory); pre-check PASS on ac4809ed |
| P1-AIA2-icons-2b: the six reward icons in `icons_48`, five of them in `icons_256` | 3 | Merged at d30530ee | gate advisory, four passes (lead cycle 48); check_all PASS on candidate 4058367a |
| P2-AIA2-busts: Bramble and Hollow painted flat at the source (board 1's note G, AD-R20) | 2 | Working at 354a9b1b: pre-check running | `bash tools/ui_bake/guard.sh`: OK; heist/100, heist/200 and heist/hc within their draw-call records; gdlint clean |

## Handoff

- **Last verified commit:** 354a9b1b (`bash tools/ui_bake/guard.sh` OK; `python3 -B tools/check_docs_consistency.py` clean; pre-check started, result below when recorded).

### Done

**`client/world/creature_bust.gd`** now draws two busts by hand instead of rendering them. `PAINTED` holds one SVG for each, keyed by the exported kind (`quarryback`, `glassgolem`), SIZE across. `of()` takes that path when the bust has no look and drawing is possible: it rasterises the SVG with `Image.load_svg_from_string` and cuts it round with the studio's own `round_cut`, so the result has the same disc and alpha as a rendered bust. It is drawn at once, with no studio and no wait. Every other kind, and any look, goes through the studio as before. The headless tests do not draw, so `creature_tests.gd` is unchanged and still covers the studio path and `round_cut`.

| Bust | Tones (light, mid, dark) | Shapes kept |
|---|---|---|
| Bramble (quarryback) | fur #C9B7C3 / #A08E9E / #75647A; shell #9C95B8 / #7B7298 / #575073 | a long snout with a dark nose, dark eyes with a catch light and brows, pink inner ears, a lamp gem on the brow, the banded shell behind, a pale belly with four band strokes, two outlined arms with cream claws |
| Hollow (glass_golem) | glass #AE9AFB / #7E63E6 / #4A30B4, a highlight #D2C6FF | a few large hard-edged facets on the chest, shoulders and two crystal spikes; iron bracers; a dark visor with white slit eyes; the hexagonal gem in a dark rim on the chest |

**The five heist portraits at 119 px** (`MANIFEST=1 ESTIMATE=400 SIZES=1 PORTRAITS=<dir> bash tools/render/shoot.sh client/tests/shots/screen_heist.gd <dir>/heist.png`, with Pip, Mo, Bramble, Hollow and Ash), looked at in colour and in grayscale, both with `FxPortrait.TOON` as committed and with it emptied for the render only:

- **Colour and grayscale, toon pass off:** all five read as framed toon figures. Bramble reads as an armadillo-like digger: snout, eyes, ears, lamp, belly bands, arms and claws, with the shell behind. Hollow reads as a faceted glass guardian: visor and slit eyes, spikes, shoulders and the white gem, each facet a flat step. In grayscale both keep three steps of value and a figure distinct from its disc.
- **Colour and grayscale, toon pass on (as main stands):** both still read. Bramble's arms and bands thin out and its lamp is lost to the re-quantising. The TOON crop takes Hollow to its head, visor, spikes and gem; the gem was raised so that it stays inside that crop.

| Measure (shot's own print) | Bramble | Hollow |
|---|---|---|
| Figure / disc L*, toon on | 54.6 / 84.4 (step 29.8) | 51.0 / 81.2 (step 30.2) |
| Figure / disc L*, toon off | 56.0 / 85.8 (step 29.8) | 51.3 / 81.4 (step 30.1) |
| Before (rendered bust) | 56.1 / 85.3 | 57.4 / 87.3 |

**Draw calls:** the five-member heist shot gives 137 draw calls before and after the change. The budget shots in `guard.sh` give heist/100, heist/200 (115, recorded 116) and heist/hc (120, recorded 120) within their records. The painted busts are one texture each, as the rendered ones were.

**Not touched:** `client/world/fx_portrait.gd` (S1's file). Its flat pass stays until this lands. Request AIA2-R3 asks the lead to drop the two kinds from `FxPortrait.TOON` afterwards.

### Self-score

Against Character presence on "heist at 100% text": Bramble and Hollow now read as characters with faces, at the same toon finish as the rendered three, instead of a furred mottle and a glass blur. The risk a judge may see is the toon pass on main still blotching them a little (above), and the two painted busts being flatter than the three rendered ones beside them.

### Half done

None.

### Open hypotheses

- Another screen that shows a quarryback or glass golem bust with a look (a skin) still gets the rendered bust: `PAINTED` only stands in for the plain one.
- Dropping both kinds from `FxPortrait.TOON` (AIA2-R3) should give the toon-off column above in the game.

### Next step

1. The pre-check records on 354a9b1b (or the later sha with this file), then `gate_request` for "heist at 100% text", Character presence.
2. If the gate fails Character presence: change what its notes name in `PAINTED`, re-render the five portraits in colour and grayscale, and run `guard.sh` and the pre-check again.
3. After the merge: AIA2-R3. Batches 3 and 4 stay deferred until the lead opens them.

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
- 2026-11-12 The painted busts through `FxPortrait`'s toon pass: it re-quantises the flat painting into blotches (Bramble's arms and bands thin, its lamp lost). The busts are framed to read through it until AIA2-R3 drops them from the list.
- 2026-11-12 Hollow's head drawn at its natural size: under the default crop it was a small cap over a big chest, and the face did not lead. The head is now 1.2 times larger.
- 2026-11-12 Hollow scaled up 1.3 to 1.4 times as a whole: the TOON crop (centre y 61, radius 61 of 192) and the default crop cut the gem off the bottom. The whole figure is back at scale 1, lowered 6 px, with the head enlarged and the gem raised 10 px.
