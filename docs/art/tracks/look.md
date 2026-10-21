# T2 Look: the island, the sky, the light

Branch `claude/3d-look`. Owns `client/world/world_look.gd`, `island_builder.gd`, `realm_palette.gd`, `sky.gdshader`, `toon.gdshader`, `toon_clear.gdshader`, `toon_light.gdshaderinc`, `outline.gdshader` and the new `client/world/look_*` files.

## What is built

- **The island** (`IslandBuilder`, after the diorama's `makeIsland` and `detail`, scaled from its radius 12.7 to the grid's):
  - a polar meadow (12 rings, closer toward the rim, × 100 spokes) with the diorama's five-sine edge, coloured per vertex from its two noise fields, lighter on a soft bank that rises between the grid and the rim, a touch of the realm's accent, darker at the edge. The grid sits in the flat middle just under the tiles, so the island holds it without a seam (tested);
  - a grass lip, three earth bands and an inverted, jittered rock cone in strata, a second cone hanging off-centre and a ring of hanging spikes;
  - roots under the rim, curtains of long roots off the cone, and vines with leaves that sway in the wind;
  - the scatter as `MultiMeshInstance3D`s, one draw call a kind: grass tufts, pebbles, flowers (crystal shards on Crystalline, ember cracks on Emberreach), the rim's soft grass fringe, the hanging fringe, rim rocks, stones round the pools;
  - waterfalls with pools and mist at their feet (lava falls on Emberreach), floating islets, puffy two-tone clouds, a soft cloud sea under the rock, and a flock of birds wheeling round the island by day (`look_bird.gdshader`, the diorama's `birds`).
- **Each realm's signature off the grid** (§21.4): Crystalline's glowing crystal spires round the rim, Skyfield's fence of posts, Lantern Vale's fireflies, glowing caps and pools of light, the Heart's golden motes, Emberreach's rising sparks and heat glows, Verdant's pollen; Tidehold's beach of sand round the rim and four waterfalls, the Heart three. Nothing is put on the grid: the grid is the simulation's.
- **Painted textures** (`LookPaint`), all drawn in code at start-up, as the diorama draws its canvases:
  - the meadow (soft blots, upward strokes, tufts, flower dots) and the strata (bands, seams, lumps, cracks), grey and tiled, painted by the vertex colour;
  - each realm's own marks in colour (the diorama's per-realm canvas): the Heart's petals, Crystalline's hexagons, Tidehold's sand and shells, Skyfield's strips of wheat, Verdant's flowers, Lantern Vale's glows (which light rather than paint).
- **One painted ground for the grid** (`WorldLook.ground_material()`): T3's flagstones take the meadow's texture lightly (laid from above, or from the side a wall faces) and the realm's marks at 40%, so the grid and the island read as one painted ground.
- **Palettes and light** (`RealmPalette`): all seven realms with the diorama's grass, dirt, rock, accent and three-colour sky, and its `lights` table (sun strength, hemisphere sky and ground, sun position), crossed with §21.2's day, dusk and night by the player's hour. Each realm takes only part of the hour's sky (Lantern Vale 12%, the Heart 30%, Skyfield 45%), so it keeps its own value range. The sun is lower at dusk and a cool moon at night.
- **Ambient as a hemisphere** (`look_hemi.gdshader`): the realm's sky colour from above, its ground colour from below, so undersides fall into cool violet shade (§21.1).
- **Sky** (`sky.gdshader`): the realm's three colours down the screen, a glow behind the island and stars when the sky is dark.
- **Atmosphere**: height fog sinking the rock into the sky; a vignette as one screen-space quad (`look_vignette.gdshader`, the diorama's CSS vignette); shadows fitted to the island with a soft edge.
- **Toon ramp** (`toon_light.gdshaderinc`): read as three.js's toon material reads the diorama's gradient map (N·L remapped to [0, 1]), so a face side-on to the sun stands in the third step as in the design; the sun's shadow takes a lit face to the second step with a soft edge. Uniforms unchanged, so every track's materials keep working.
- **Ink outline** (`outline.gdshader`): the same 1.5 pixels, now pushed in view space (see the traps).
- **Tests** (`client/tests/look_tests.gd`, in `run.gd`): the seven palettes, the hours, the seam between the island and the grid, and the island's budget.
- **Shot** (`client/tests/shots/look_realms.gd`): every realm at day 12, dusk 19 and night 23 in one grid; `REALMS`, `HOURS`, `CELL`, `ZOOM`, `PITCH`, `SPAN`, `FEATURES` choose what it shows.

## Character outlines

This track owns `outline.gdshader` but not the creature material (T1). The outline stays at §21.3's 1.5 pixels (`width_px`), as the program asks; T1 decides whether character bodies draw it.

## Traps found

- **The sky.** Godot's sky shader under an orthographic camera sees one direction, so the whole sky was one colour. The environment's canvas background fixes that, but in the Compatibility renderer the background is lost as soon as a material with `cull_front` (the ink outline's inverted hull) is drawn. The sky is now a quad over the whole screen, placed at `sky_depth` (180 m) through the camera's own projection. An earlier fixed clip depth (`far_z` 0.00001) assumed a reversed depth buffer; the Compatibility renderer's is not, and under T5's perspective heist camera the sky covered the island (found and fixed in the second integration; never use a fixed clip depth here).
- **MultiMesh instances**: the instance's transform is in `MODELVIEW_MATRIX` (and `MODEL_MATRIX`), so a camera-facing puff is rebuilt round `MODELVIEW_MATRIX * (0, 0, 0, 1)` (`look_mist.gdshader`); its size comes in the custom data.
- **`QuadMesh`** has no `surface_get_array_index_len`, which the budget test calls on every mesh; the look's quads are `ArrayMesh`es.
- A `Color` times a number scales its alpha too, and alpha under 1 means "glow" in the toon kit: darken with `IslandBuilder._dim`.
- The sky ambient barely answered `ambient_light_energy` here (0.4 to 0.24 changed little); its strength is set by the hemisphere shader's `strength`.

## After the integration merge (da71550)

- The grid's ground is T3's (`kit_ground.gdshader`); `WorldLook.ground_material()` is no longer used for it and stays only as an option.
- **One meadow across the grid's edge:** within 2.5 m of the grid (`IslandBuilder.GRID_BLEND`), the meadow's vertex colour turns to the palette's `grass` (what KitGround paints the grid with), and its painted texture and realm marks fade out. Everywhere it carries the same brush as the grid's ground: `look_brush.gdshaderinc` writes out T3's patches, dabs and flecks with the same constants. T3 can `#include` it in place of its own copy.
- Palette `grass` deepened for the Heart, Skyfield and Verdant. Both the island and the grid read it, so their noon greens are near the design's scout stills: Heart 126,143,94 against the design's 111,122,88; Skyfield 152,185,89 against 142,165,89.
- The waterfall pools give T3's new water shader its shore distance (UV.x), so they have a foam ring and ripples instead of shore everywhere.
- Night: a soft crescent moon in the sky at night and over Lantern Vale; the fog is lighter so more of the rock shows under the island.
- Known on the merged base, not from this track: `StageHeroTests._stage` raises a script error (`material_override` on a Nil) in a headless run.
- Stills: `merged-world.png`, `merged-realms-sheet.png`.

## Rounds 9–11 (after the merge)

- Night: fireflies and warm pools of light off the grid, shown by the hour; moonlit blue shade from above so the meadow keeps its hue.
- Under the island: the cone is 13 deep (the diorama stretches it 1.45× when looking down on a whole island) and darker than the sky; the fog sits lower; roots and curtains are thicker.
- Dusk: a softer, golden sun, so dusk islands glow rather than go olive.
- §21.4's particles: Verdant's butterflies (the bird shader in their own colours, fluttering), Skyfield's wind streaks (`look_streak.gdshader`), Crystalline's crystals twinkle.
- Sky depth: placed through the camera's projection (see the traps); `look_realms.gd` takes `FOV` to check a perspective camera (`r11-perspective.png`, FOV 22°).
- Stills: `r9-realms-sheet.png`, `r9-night-close.png`, `r10-underside.png`, `r11-realms-sheet.png`, `r11-perspective.png`.

## Hooks outside the track

- `client/world/world_view.gd` (T5), one line: the grid's ground layer uses `look.ground_material()` instead of the plain toon material.
- `client/tests/world_tests.gd`: the material check accepts the look's shaders and reads the sky from `WorldLook.sky_material`; the budget check counts the scatter's `MultiMeshInstance3D`s (every instance's triangles, one draw call a kind).
- `client/tests/run.gd`: runs `LookTests`.

## Budget (§21.3: 25,000–40,000 triangles a realm on the home camera, under 150 draw calls)

- Island, scatter, sky dressing, mist and sky on a 14 × 14 grid (`LookTests`, held at ≤ 18,000 triangles and ≤ 24 draw calls): heart 17,082 / 18; skyfield 17,388 / 18; crystalline 15,546 / 15; tidehold 17,012 / 17; emberreach 10,828 / 18; verdant 16,708 / 18; lanternvale 17,968 / 20.
- The whole realm of `WorldTests.island()` (12 × 12, with T3's kit, the Vault, pylons, wards and today's figures): 21,736 triangles in 41 draw calls (heart), 22,710 in 43 (Lantern Vale), before shadow passes.
- The rendered grid of 21 views (`look_realms.gd`) reports its frame's totals through `RenderingServer.get_rendering_info`.
- That leaves the kit, the buildings and the figures about 22,000 triangles and 120 draw calls on the home camera.

## Stills (`docs/art/shots/look/`)

- Before: `r0-before-world.png`, `r0-before-realms.png`.
- Rounds: `r1-world.png`, `r1-realms.png`, `r3-world.png`, `r3-realms-sheet.png`, `r5-realms-sheet.png`, `r6-scout-vs-design.png`.
- Final:
  - `final-realms-grid.png`: rows heart, skyfield, crystalline, tidehold, emberreach, verdant, lanternvale; columns 12, 19, 23;
  - `final-realms-sheet.png`: the same, a column a realm, with the grayscale thumbnails beneath (§21.10);
  - `final-world.png`, `final-heist.png`: the heist camera;
  - `final-scout-vs-design.png`: the design's scout stills on the left, ours on the right;
  - `final-side.png`: the rock, the roots, the waterfalls and the cloud sea from the side;
  - `final-dusk-close.png`: Tidehold and Verdant at dusk under the heist camera.

## Rounds

1. Ported the island, scatter, falls, clouds, palettes and lights; found and worked round the sky trap.
2. Lights calibrated against the design's scout stills (meadow 1.6× too bright); clouds made two-tone.
3. Grayscale test: realms given their own value ranges; painted flagstones; hemisphere ambient.
4. Realm signatures: crystal spires, fence, fireflies, motes, sand beach.
5. Lava falls, lantern and ember glows; the mist as one MultiMesh; the budget test and the cuts it forced.
6. The design's per-realm marks over the meadow, compared side by side with the scout stills.
7. Harsh pass: marks lighter on the grid so the tiles still read; petals smaller.
8. Harsh pass: dusk under the heist camera; final stills.

## Still worse than the design

- **The grid still reads as a square of flagstones** in every realm, where the design's buildings stand in one meadow with paths. The flagstones now share the meadow's paint and marks, but their colour and shape are T3's.
- Skyfield at noon is a little brighter and paler than the design's; Lantern Vale at noon is brighter than the design's (kept so it reads on a phone).
- Clouds are low-poly puffs, not the design's soft sprites at the island's level; the cloud sea is subtle.
- Waterfalls are ribbons with streaks; the design's have a bright core and mist that pulses.
- Birds are dark Vs wheeling in the shader; no butterflies or wind streaks yet (§21.4's particles for Skyfield and Verdant).
- The rock cone is barely seen from the home camera's 35°; it shows from the side and at zoom 0.

## Next

- With T3: decide whether the flagstones become paths over the meadow (the design's way), using `ground_material()`.
- Butterflies for Verdant (as the birds: a MultiMesh flapping in the shader); wind streaks for Skyfield.
- Pulsing mist and a brighter core for the falls.
- A swoop-proof check: the look rebuilt on every realm change (`island()` already resets the mists and clouds).

## Stopped here (at the owner's request, 2026-10-20)

- **Done and checked:** everything above, up to `bdbcb96` (check_all passed on that commit: client 293/293, server 393/393, simulation 326/326).
- **In progress:** nothing; no uncommitted work.
- **Next step:** merge the second integration when it lands (it carries the same sky-depth fix); then soften Heart at dusk, give clouds the design's soft sprite look, add a bright pulsing core to the waterfalls, and make the small particles readable at the home zoom.

## Resumed (2026-10-20, 14:34 UTC)

- Merged the second integration (d694b73), keeping its sky-depth version.
- **The sky drew over the see-through pieces.** Drawn without depth, the sky quad was sorted among the clouds, mist and the cloud sea and could cover them, so the cloud sea and the falls' mist had rarely shown. Its material now has the lowest render priority, so it is always drawn first.
- **Clouds** are painted sprites, as the design's are: rounded lobes on a flat base, white on top and the sky's violet beneath, two triangles each, one MultiMesh (`look_cloud.gdshader`).
- **Waterfalls** have a bright core that swells and ebbs.
- **Dusk**: the hour's tint is blended into the sun rather than multiplied, so a meadow under the low sun glows gold instead of going olive.
- MultiMesh trap: in the Compatibility renderer a quad's size read from the custom data's x and y did not arrive; sizes come from the instance's scale (`MODELVIEW_MATRIX`'s columns).
- `world_tests.gd`'s budget count no longer stops on another track's primitive mesh or non-shader material (it counts `get_faces()` and asks each surface's material). This happened on the merged base too.
- Still: `r12-integrated.png` (Heart noon and dusk, Lantern Vale, and the heist screen, on the integrated build).
- Round 13: against the design's land stills (`r13-land-vs-design.png`, design above, ours below), Emberreach and Lantern Vale had too many pools of light and read as polka dots; they now have fewer, smaller and fainter ones, and Tidehold, Emberreach and Lantern Vale take deeper grass.
- Round 14: at dusk and night the hour's sky now weighs at least 45% and 70% against the realm's own, so no horizon stays bright after dark. `r13-integrated-sheet.png` shows every realm with T3's buildings at 12, 19 and 23, with grayscale thumbnails.
- Heist screen checked at noon and night under the perspective camera (vault, alarm, sneak moments): the sky stays behind, and the night meadow keeps its fireflies and glows.
- Round 15, value ladder at noon (§21.10): on the integrated build the islands of Heart, Crystalline, Tidehold and Verdant all measured about 139 grey. The sun and grass now give each its own step: Skyfield 165, Crystalline 153, Heart 139, Verdant 125, Tidehold 115 (after round 17), Emberreach 86, Lantern Vale 60 (`r15-noon-values.png`).
- Merged the third integration (282e149); `r16-third-integration.png` shows Heart, Tidehold, Lantern Vale and the heist screen on it.
- Round 16: the floating islets carry a small round tree and two dangling roots and are larger; birds are larger, so they read as Vs at the home zoom.
- Round 17: Tidehold's sun is lower, so it sits ten grey steps under Verdant at noon.
- Skyfield's high clouds (§21.4), placed beyond the rim so none hides the realm.

## State at the end of the resumed run

- Final stills on the integrated build (third integration plus this track): `final2-integrated-sheet.png` (every realm with T3's buildings at 12, 19 and 23, grayscale thumbnails beneath), `final2-world.png` (the heist camera on world_shot), `r16-third-integration.png`, `r15-noon-values.png`, `r13-land-vs-design.png`.
- Still worse than the design: Lantern Vale stays brighter than its land still (kept so it reads on a phone); the grid's tile seams are T3's and still show the grid faintly; wind streaks and fireflies are small at the home zoom; the cloud sea under the Heart is a strong pink band at the foot of a tall frame.
- Next: tune the cloud sea's strength per realm; give Emberreach's meadow a few glowing lava runnels like its land still; check every screen T5 draws (builder, planner, replay) in both cameras.

## Stopped here (second stop, at the owner's request, 2026-10-20 19:22 UTC)

- **Done:** everything above through Lantern Vale's darker twilight (`0c8d449`). The last full check_all passed on `60f0383` (client 323/323); `8566d4a` and `0c8d449` change only palette values and islet dressing and were rendered and linted but not run through check_all (skipped: it takes about 25 minutes).
- **Still worse than the design:** the grid's tile seams (T3's) still show faintly; wind streaks and fireflies are small at the home zoom; Lantern Vale stays a little brighter than its land still; Verdant and Tidehold read close in hue at dusk.
- **Next step:** run check_all on the last commit; then tune the cloud sea per realm and check the remaining T5 screens (curation, defences, observatory) in both cameras.

## Third session (2026-10-21, from 00:00 UTC)

### Budget headroom: the lighter level (pushed first, for T4 and T6)

**The call:** set `look.detail = WorldLook.Detail.LIGHT` before `look.island(...)`. On a `WorldView`, after it is in the tree and before `show_replay`:

```gdscript
add_child(view)
view.look.detail = WorldLook.Detail.LIGHT
view.show_replay(replay)
```

`WorldLook.Detail.FULL` stays the default (the heist and home). The lighter level keeps every piece and every draw call but draws fewer, larger ones: a third of the grass tufts at 1.5 times the size, 40% of the flowers, pebbles and fireflies, half the rim rocks, roots, curtains and vines, a wider-spaced rim fringe, and a coarser meadow (8 rings × 64 spokes) and rim (the lip follows the meadow's spokes, so the two still meet). Side by side at the realm zoom it reads the same (`docs/art/shots/look/s3-detail-full-vs-light.png`, full left).

Measured (`client/tests/shots/look_budget.gd`, headless; `PARTS=1` lists every piece), 12 × 12 grid:

| Realm | Full | Light |
|---|---|---|
| Heart | 16,222 tris / 21 calls | 8,698 / 21 |
| Skyfield | 16,432 / 22 | 9,276 / 22 |

On a 14 × 14 grid the worst realm is 16,976 at full and 9,448 at light (`LookTests`, which holds the light level to 10,000). That gives T6's realm view and curation about 7,500 triangles back, and T4 room for the meadow in the Heart's close-up.

Where the full level's triangles go (Heart, 12 × 12): meadow 2,400; cliffs 1,558; roots 1,206; vines 864; tufts 2,430; rim fringe 2,000; flowers 1,170; rim rocks 1,080; hanging fringe 550; pebbles 560; motes 480; fireflies 512; pool stones 540; islets 496; falls, pools, clouds and mist under 400 together.

### Round 1: values, dusk and night, small particles

- **Noon values matched to the design's stills.** Median grey of the island at the realm zoom against the median of the design's scout and land stills, before → after (design): Heart 143 → 115 (108); Skyfield 178 → 145 (146); Crystalline 176 → 124 (111, and its saturation 0.81 → 0.23 against 0.2); Tidehold 98 (93); Emberreach 83 → 60 (61); Verdant 112 (108); Lantern Vale 41 → 25 (25). Done with the sun's strength and a new per-realm `fill` on the hemisphere ambient (`RealmPalette.LIGHTS`). Measured with a small script over `look_realms.gd` sheets.
- **Dusk and night keep each realm's hue.** `LIGHTS` now carries each realm's `dusk` (the low sun's tint) and `night` (the moon's): Tidehold a rose dusk and a cyan moon, Verdant a gold dusk and a lavender moon, Skyfield amber and silver, and so on, laid on at 70% (day 45%). Dusk meadow hues: Tidehold 182°, Verdant 101°, where both had read green-teal before. Night is darker (hour sun 0.5 → 0.4).
- **Lantern Vale**: darker at noon (25, the design's 25), and it now takes only 40% of the hour's dimming (`dark`), so its night is not black (14).
- **Fireflies, flies, motes and sparks** are glowing specks (`look_spark.gdshader`): a camera-facing quad with a core and a halo, added to the frame, pulsing, and never under 12 pixels (7 for daytime motes) however far the camera, so they read at the home camera's whole-realm zoom. Rising sparks fade in and out. Same draw calls.
- **Wind streaks** (Skyfield) are never thinner than 4 pixels and a little stronger.
- **Clouds never stand over the meadow** on any of the camera's four turns: a cloud near the rim floats no higher than the line from the rim to the eye at 35° (`IslandBuilder._clear_of_rim`); Skyfield's high clouds stand far enough out for their height.
- Stills: `s3-r1-before-sheet.png`, `s3-r1-after-sheet.png` (columns heart, skyfield, crystalline, tidehold, emberreach, verdant, lanternvale; rows 12, 19, 23), `s3-r1-fireflies-whole-zoom.png`.

### Round 2: the world behind the 2D screens

- **`LookBackdrop`** (`client/world/look_backdrop.gd`, `look_backdrop.gdshader`): the backdrop menus stand on (§21.2's night, #171046 to #2C3AA8), painted as the realms' own sky so the world and the interface read as one picture: the gradient, a glow where the world would float, twinkling stars, three far islets with roots bobbing, a two-layer cloud sea at the foot and the vignette as a tint. One quad, one draw call; still under reduced motion.
  - **The call for T9 (UI kit):** in place of `UI.frame`'s gradient `TextureRect`, add `LookBackdrop.new()` as the screen's first child (it is named "Sky"), or call `LookBackdrop.dress(screen)` after `UI.frame` to swap it. A sheet or hub over a realm calls `backdrop.for_world(hour, realm)` to take that realm's sky. Not hooked into `ui.gd` here (T9 is rewriting it).
  - Before and after, the Codex on its frame: `s3-r2-backdrop-before-after.png` (left today's day gradient, right the backdrop). The title's dark ink does not read on the night: that is the UI kit's to restyle.
- **`WorldLook.haze_under(from, strength)`**: a haze in the sky's low colour rising over the lower frame (in the vignette's quad), so a screen whose sheet covers the lower screen fades the world into it instead of cutting it. `s3-r2-haze-under.png` (from 0.55, strength 0.85). For T6's realm view, curation and defence log: `view.look.haze_under(0.6, 0.8)`.
- **T6's screens checked** at noon (`s3-r2-t6-screens-noon.png`: realm view, curation, defence log, observatory): nothing of the look breaks; the Heart's daytime motes show as small gold specks round the buildings. Budgets as T6 measured them (realm view 98,610 triangles / 103 calls; curation 67,313 / 91; defence log 66,557 / 87; observatory 20,761 / 29); each can take about 7,500 back with `Detail.LIGHT`.

### Round 3: the heist camera and the falls

- Under the heist's close perspective camera the fireflies were big blurry orbs crowding the crew. A speck's halo is now 3 times its size and at most 0.32 m across, unless the 16-pixel floor needs more (so they still read at the whole-realm zoom); the night pools of light are fainter (0.45 → 0.3). `s3-r3-heist-night-and-whole.png`: the heist screen at 23 and the whole-realm zoom.
- Waterfalls: soft rounded strands wavering as they fall instead of hard 9-column dashes, white water at the lip, and a foot that thins into spray, the strands lasting longest. `s3-r3-whole-zoom-sheet.png` (every realm at 12, 19 and 23, the home camera's whole-realm zoom).
- The menu backdrop has the design's universe sky in it: soft nebula clouds and a diagonal band of star dust (`s3-r3-backdrop-nebula.png`).
- Trap: in the spark shader a speck's pixel floor must itself be capped (here 0.6 m): some instances reach the vertex stage with a pixels-per-metre near zero (seen at noon on the Heart's motes), and an uncapped floor whites out the whole frame through the additive blend.
- check_all on `6045177`: client 334/334, server 393/393, simulation 326/326; it stopped at the prototype-conformance step for want of the `playwright` module on this machine (installed since; rerun before the final push).

### Round 4: the backdrop beside the design's screens and the UI kit

- The design's 28 screen stills landed (`art/design/stills/screens/`) and T9's kit is on `origin/claude/ui-kit`. The design's menus do not stand on §21.2's blue (#171046 to #2C3AA8) but on a dark violet radial, "#2E1F5E at the top centre through #140C30 to #0A0620", which T9's `night` material already paints. `LookBackdrop.night()` now uses the same radial and the same three colours, so the two agree, and adds only what the kit's box does not: a faint nebula, three far islets, a dark two-layer cloud sea at the foot, and the vignette. Words on it keep the kit's `text_bg` (the top two stops). `for_world(hour, realm)` keeps the realm's own straight gradient.
- Judged in a worktree with `origin/claude/ui-kit` merged: `s3-r4-settings-design-kit-backdrop.png` — the design's Settings, the kit's Settings on its `night`, and the same on `LookBackdrop`.
- **For T9:** in `UI.frame`, `LookBackdrop.dress(screen)` after the frame is built swaps the "Sky" for the backdrop (the kit's `text_bg` meta on the screen stays right). Whether every menu should take it, or only the hubs (home's menus, the Laws and Crew hubs), is T9's call; the backdrop costs one draw call and one full-screen fragment pass (four noise octaves).
