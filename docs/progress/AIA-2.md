# AIA-2 icon maker: progress

- Status: Yellow (P3-AIA2-bake-1: the icon bake draws in Node by plain arithmetic, with no browser; two runs, a run with V8's vector units off and a `--jitless` run give the same bytes; checks next).
- Progress: 6 of 7 tasks merged (P1-AIA2-toon-route at 9b2bde70, P1-AIA2-icons-1a at 8ce107c9, P1-AIA2-icons-1b at 90f72fd7, P1-AIA2-icons-2a at 027379a2, P1-AIA2-icons-2b at d30530ee, P2-AIA2-busts at fb07a2ce); P3-AIA2-bake-1 is working.
- Done: the toon route, icon batches 1a, 1b, 2a and 2b, the two painted busts; the machine-independent bake and the rebaked `icons_48` and `icons_256`.
- Next: merge main, the setup line, `client/build.sh`, `check_all.sh`, `guard.sh`, the pre-check and `owners.py diff`. Batches 3 and 4 are deferred (D13 (c)).
- Blocked by: none. AIA2-R4 (non-blocking) asks AD about Pip's high-contrast ring; AIA2-R5 (non-blocking) asks the lead to correct two lines of `art/ui/icons/README.md`.
- Owner decision needed: none.

| Deliverable | Weight (h) | Status | Evidence |
|---|---:|---|---|
| P1-AIA2-toon-route: list, scene format, two icons end to end | 3 | Merged at 9b2bde70 | `bake.js --check`, `check_icons.py` and `run_checks.sh` PASS at 02e7ef0f |
| P1-AIA2-icons-1a: the eight heist controls in `icons_48` | 4 | Merged at 8ce107c9 | gate advisory at 5f759a03: Light behind UI pass; three qualities fail 3 of 3 |
| P1-AIA2-icons-1b: the currencies and resources in `icons_48` and `icons_256` | 3 | Merged at 90f72fd7 | gate pass on all four qualities (advisory) at bef6eac2; resync at 5ecb0202 |
| P1-AIA2-icons-2a: eight heist-status and HUD icons in `icons_48` | 4 | Merged at 027379a2 | gate 12 of 12 at 6a382d97 (advisory); pre-check PASS on ac4809ed |
| P1-AIA2-icons-2b: the six reward icons in `icons_48`, five of them in `icons_256` | 3 | Merged at d30530ee | gate advisory, four passes (lead cycle 48); check_all PASS on candidate 4058367a |
| P2-AIA2-busts: Bramble and Hollow painted flat at the source (board 1's note G, AD-R20) | 2 | Merged at fb07a2ce | `guard.sh` OK; heist draw calls within their records; AIA2-R3 done in fad94652 |
| P3-AIA2-bake-1: the icon bake gives the same bytes on every machine; `icons_48` and `icons_256` rebaked | 2 | Working | two runs, a vector-units-off run and a `--jitless` run byte-identical; `check_icons.py` all ok; contact sheets in `art/ui/icons/studio/proof_bake/` |

## Handoff

- **Last verified commit:** the commit carrying this file (the rebaked atlases equal the first proof run byte for byte; `python3 -B art/ui/icons/studio/check_icons.py icons_48 icons_256` all ok; `python3 -B tools/check_docs_consistency.py` clean).

### Done

**The bake no longer depends on the machine.** `art/ui/icons/studio/bake_icons.js` no longer opens Chromium. It renders each module in Node with `studio/raster.js` (a rasteriser written in plain arithmetic over the three.js scene) and finishes it with `studio/finish.js` on `studio/picture.js` (premultiplied pictures of doubles and the small canvas a badge's `draw(S, R)` uses). `studio/page.html` is deleted. Nothing under `tools/ui_bake/` changed: `bake.js` already calls `node art/ui/icons/studio/bake_icons.js <family> --out <dir>` for kind `"scene"`.

**Why it cannot depend on the machine** (also in `art/ui/icons/studio/README.md`): `guard.sh` rebakes and compares byte for byte in whichever container runs it. The old bake drew with WebGL on SwiftShader and a 2D canvas on Skia. Both pick their code by the CPU (SwiftShader's JIT, Skia's SSE, AVX2 or AVX-512 raster pipeline), and each path rounds differently. The new bake is JavaScript arithmetic on doubles only. V8 computes a double the same in every tier, with no fused multiply-add. `Math.pow`, `sin` and `cos` are V8's own software routines, and `sqrt` is exactly rounded. No step reads a GPU, a canvas, a font, the clock or the CPU's features. The bytes then depend on the code and on Node's major version (Node 22 in the containers), and a Node upgrade is checked by a rebake.

**How it draws:** 4 samples a pixel at the standard pattern; vertices snapped to 1/256 pixel, so the edge tests are exact integers; a depth test per sample; the toon shading once a pixel, perspective-correct. The finish works at R = 640: the frame (0.88), the SVG three-box blur for the drop and glow, path coverage at 8 by 8 samples, the exact distance-transform grow for the ink, an area average down to the family's px (256 and 128), and a stored (level 0) PNG into `pack.py`.

**Proofs** (this container: Intel Xeon @ 2.10GHz with AVX2, AVX-512, FMA; 4 cores; Node v22.23.5):

| Run | Command | Time | Result |
|---|---|---:|---|
| n1 | `node art/ui/icons/studio/bake_icons.js icons_48 icons_256 --out n1` | 48 s | the reference |
| n2 | the same, a second run | 48 s | all four `.webp` byte-identical to n1 |
| n3 | the same with V8's vector units off: `node --no-enable-sse3 --no-enable-ssse3 --no-enable-sse4-1 --no-enable-sse4-2 --no-enable-sahf --no-enable-avx --no-enable-avx2 --no-enable-fma3 --no-enable-bmi1 --no-enable-bmi2 --no-enable-lzcnt --no-enable-popcnt ...` | 48 s | all four `.webp` byte-identical to n1 |
| n4 | the same under `node --jitless` (the interpreter only) | 411 s | all four `.webp` byte-identical to n1 |
| commit | `node art/ui/icons/studio/bake_icons.js icons_48 icons_256` into `client/ui/art/` | 45 s | all four `.webp` byte-identical to n1 |

The `.json` manifests differ between runs only in `sources_hash` when a file under `art/ui/icons/` changed between them (the hash covers the whole folder); the committed manifests were baked after the last source edit. sha256 of the committed atlases: `icons_256.webp` e960e356…, `icons_256_hc.webp` 94078e2c…, `icons_48.webp` a0425819…, `icons_48_hc.webp` 3e93f95e…. The third proof, the lead's `guard.sh` in another container, is the lead's.

**Against the old atlas** (premultiplied colour and alpha, per piece, 0 to 255): the mean difference is 0.2 to 1.4 levels a piece, all on edges: antialiased outlines about 2 to 7 levels sharper, and the soft glow about 1.5 alpha fainter. No piece moves, grows or changes colour. The largest are icons_48 splitcrew (alpha mean 0.78), vaultprogress (colour mean 1.21), and in icons_256 clean, seasonreward and starlight (colour means 0.48 to 0.83).

**Contact sheets** (`python3 -B tools/ui_gate/sheet.py contact`, each old piece beside its new one, colour then grayscale):

| Family | Normal | High contrast |
|---|---|---|
| `icons_48` (at 48 pt) | `art/ui/icons/studio/proof_bake/icons_48_normal_old_new.png` | `art/ui/icons/studio/proof_bake/icons_48_hc_old_new.png` |
| `icons_256` (at 96 pt) | `art/ui/icons/studio/proof_bake/icons_256_normal_old_new.png` | `art/ui/icons/studio/proof_bake/icons_256_hc_old_new.png` |

**The one piece that changes beyond edge antialiasing:** `crew__pip__normal` in `icons_48_hc`. Its ink ring was an octagon in the committed atlas and is round now (alpha mean 8.4, 2814 pixels over 8 levels). The octagon was itself machine output: a Chromium rebake of the old route in this container also gives the round ring (new against that rebake: mean 0.46). The round ring is what the grow intends (Tried and failed, 9 November). Request AIA2-R4 asks AD, through the lead, to confirm; the default keeps it round.

**Not touched:** `art/ui/icons/README.md` is outside this task's files. Its line 37 ("Chromium only") and lines 76 to 82 (`studio/page.html`, SwiftShader, AIA2-R1) now describe the old route. Request AIA2-R5 asks the lead to point them at `studio/README.md`.

### Self-score

The task's measure is the guard: the same bytes from the same sources in any container. Two runs, the vector-units-off run and the `--jitless` run agree here; the run in another container is the lead's. The icons look the same at 48 and 96 pt in colour and grayscale; the risk a judge may see is outlines a touch crisper and the glow a touch fainter than before, and Pip's round high-contrast ring.

### Half done

None.

### Open hypotheses

- A CPU without AVX2 should give the same bytes: the n3 run turned off every vector extension V8 would use.
- An ARM machine should too, since V8 does not fuse multiply-adds on ARM either; not tested.

### Next step

1. Merge main; the setup line, `bash client/build.sh`, `bash tools/check_all.sh`, `bash tools/ui_bake/guard.sh`; the pre-check (`run_checks.sh start`, `wait`, `record`); `owners.py diff P3-AIA2-bake-1`.
2. `ready_sha`, then the lead's `guard.sh` in its own container.

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
- 2026-11-17 The drop and glow blur with sigma scaled by the frame (x 0.88): the glow came out further from the old atlas. Sigma x 1.136 was mixed. The blur keeps the SVG sigma unscaled, which fits the old atlas best.
- 2026-11-17 A [k, 1-2k, k] smoothing after the area average, to match Chromium's softer edges: the gain was marginal and it hid detail, so the plain area average stays.
- 2026-11-17 Timing the proof bakes with `/usr/bin/time`: it is not installed in the container, so the background runs never started. Bash's `$SECONDS` and `wait` time them.
- 2026-11-17 Editing `art/ui/icons/README.md` for the new route: it is outside P3-AIA2-bake-1's files (`owners.py diff`). The explanation went to `studio/README.md`, and AIA2-R5 asks the lead for the two stale lines.
