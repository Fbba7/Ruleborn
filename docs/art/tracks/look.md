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
