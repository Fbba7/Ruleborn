# AIA-2 icon maker: progress

- Status: P1-AIA2-toon-route ready at 02e7ef0f; pre-check PASS (13:32Z, all checks passed).
- Progress: 0 tasks merged; P1-AIA2-toon-route is up for merge.
- Done: the toon route for icons, from a scene or a character render through one finish into `icons_48` and `icons_256`, with two proof icons (Starlight in both families, Pip's crew badge in `icons_48`). Also the 60-icon list in four batches.
- Next: P1-AIA2-icons-1a (the eight heist controls), once this merges.
- Blocked by: none for the work. The merge waits on request AIA2-R1 to K1: `guard.sh`'s rebake runs `bake.js`, which refuses kind "scene".
- Owner decision needed: none.

| Deliverable | Weight (h) | Status | Evidence |
|---|---:|---|---|
| P1-AIA2-toon-route: list, scene format, two icons end to end | 3 | Ready at 02e7ef0f | `node tools/ui_bake/bake.js --check`: icons_48 2 pieces, icons_256 1 piece, both ok. `python3 art/ui/icons/studio/check_icons.py`: all 6 faces pass (2 pieces in 2 families, 2 modes). A rebake into a scratch folder is byte for byte on all four atlases. `bash tools/run_checks.sh`: PASS at 02e7ef0f |

## Handoff

- **Last verified commit:** 02e7ef0f, plus this handoff and the status file.

### Done

**`art/ui/icons/list.md`.** The 60 most-seen icons, in four batches of 15:
- 1a: the eight heist controls;
- 1b: the four resources and three currencies;
- 2a: the heist status;
- 2b: the rewards, Pip's badge among them;
- 3: navigation;
- 4: the rest.

Each reward is marked "256" where it also goes to `icons_256`. The order was checked against how often the client's scripts name each icon.

**`art/ui/icons/README.md`.** The two routes, the scene format and the commands.

**`studio/toon.js`.** The world's toon light (`client/world/toon_light.gdshaderinc`), mirrored number for number as on the style board. Colours come only from token names.

**`studio/finish.js`.** The board's finish (`studio.html` bakeIcon), rule for rule, with one change: outline and keyline widths are in points of the size shown (`SHOWN_PT`: 48 for `icons_48`, 96 for `icons_256`). The board's 1/24 of the side is 2 pt at 48 pt. At 96 pt it would have been 4 pt, which the rubric's "2 pt at the size shown" rules out.

**`studio/page.html` and `studio/bake_icons.js`.** The interim bake. It uses `bake.js`'s own `layout`, `manifestText` and `sourcesHash`, and its `pack.py`, so `bake.js --check` accepts what it writes. The manifest's `px_per_point` is null.

**The character route.** `client/tests/shots/icon_portraits.gd` renders each kind in T7's portrait studio and writes `art/ui/icons/renders/<name>.png`. It uses `portrait_studio.gd` read only, and the studio's bust cut, widened 1.3 so that the ears and shoulders are kept. A badge module draws its toon frame in three.js and lays the render in, with the head standing over the ring.

**The proof icons.**
- `resources/starlight.js`, in both families: the board's hero, unchanged.
- `crew/pip.js`, in `icons_48`: a night-enamel disc (`card_top`) in a ring of the motion school's amber, with Pip's render in it.

**`studio/check_icons.py`.** The rubric's two scripted rules:
- The outline is 2 pt at the size shown (3 pt in high contrast). From the centre of mass, 180 rays measure the outermost ink run across the edge. The median must be at least 0.85 of the target and the tenth percentile at least 0.6.
- A dark shape at 32 pt (90 px):
  - the silhouette covers 25 to 85% of its square;
  - it is not a blob: its overlap with the ellipse of its own moments is under 0.96;
  - at least 90% of its edge is dark (in high contrast, light: the keyline).

Results, as outline median against target, then 32 pt coverage and ellipse overlap:

| Icon, family and mode | Outline median | Target | 32 pt coverage | Ellipse overlap |
|---|---:|---:|---:|---:|
| Starlight, `icons_48` normal | 6.5 px | 5.3 px | 33% | 0.73 |
| Pip, `icons_48` normal | 5.7 px | 5.3 px | 49% | 0.93 |
| Starlight, `icons_256` normal | 7.9 px | 5.3 px | 26% | 0.67 |
| Starlight and Pip, high contrast | 7.5–9.0 px | 8.0 px | 31–60% | 0.71–0.94 |

The normal median runs above 2 pt where the soft drop joins the ink under the icon.

### Self-score against rubric.md quality 3 (Painted or rendered icons)

| Rule | Score | Why |
|---|---|---|
| 1. 3D form, top-left key, rim, specular, dark outline | Pass | Starlight is lit from (-3, 4, 5), with the rim on the lit side, two cream glints and the ink outline. Pip is the model's own toon render, in a toon disc and ring with a glint and the outline. |
| 2. Outline 2 pt at the size shown | Pass, scripted | `check_icons.py`, all six faces |
| 3. A dark shape at 32 pt | Pass, scripted | All six faces. Pip's ears clear the ring, so the badge is not a disc (overlap 0.93) |
| 4. §21.8 volume: three-stop gradient, gloss, soft drop | Pass | The toon ramp's steps and the inner light carry the gradient, the glints are the gloss, and the drop is blurred (not a hard ink drop) |
| 5. One toon look, characters from imported models | Pass | No PBR anywhere. Pip comes from `StageHero.make_figure("skyskipper")` in the hero stage's light |
| 6. Law and school frames | Not applicable | No law icon yet. Pip's ring is in the motion school's colour; the school's shape (§21.2) goes on the crew-role icons of batch 4 |

**Risks a judge may see:**
- At 48 pt, Pip's coins (the carrier's satchel, at the render's right edge) read as a row of dots inside the ring.
- In normal mode on the night backdrop, the ink outline is dark on dark. The glow and the amber ring carry the edge there, as on the board.

### Half done

None.

### Open hypotheses

- The client may show `icons_256` at other sizes than 96 pt. If so, the outline is 2 pt only at 96, and the kit should scale these icons only from 72 to 128 pt.
- `px_per_point` null may not suit the kit's loader (K1). The default is to keep null for scene families.

### Next step

P1-AIA2-icons-1a, once this merges: the eight heist controls as scenes in `art/ui/icons/heistcontrols/`, each checked by `check_icons.py`.

## Tried and failed

- 2026-11-04 Pip's bust at the studio's own crop: it cut the ears and the shoulders at the badge's square. Widening the crop 1.3 times, with a 2% top margin, keeps the whole head.
- 2026-11-04 Pip on a disc of the motion colour: Pip's gold fur on the motion amber (#F2B43C) is gold on gold, so at 48 pt the face is lost. A night-enamel disc with the amber in the ring separates them.
- 2026-11-04 The render placed at the badge's top edge: the ears were clipped by the square. Placing it at 0.82 of the side, 7% down, keeps them.
- 2026-11-04 The board's outline (1/24 of the side) for `icons_256`: it measured 13.8 px, 4 pt at 96 pt. The finish now sets outline widths in points of the size shown.
- 2026-11-04 The 32 pt edge check in high contrast against "dark": the edge there is the light keyline, by design, so it failed every face. In high contrast it now checks for light.
