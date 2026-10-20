# T2 Look: the island, the sky, the light

Branch `claude/3d-look`. Owns `client/world/world_look.gd`, `island_builder.gd`, `realm_palette.gd`, `sky.gdshader`, `toon.gdshader`, `toon_clear.gdshader`, `toon_light.gdshaderinc`, `outline.gdshader` and the new `client/world/look_*` files.

## What is built

- **The island** (`IslandBuilder`, after the diorama's `makeIsland` and `detail`):
  - a polar meadow (14 rings, closer toward the rim, × 120 spokes) with the diorama's five-sine edge, coloured per vertex from its two noise fields, lighter on a soft bank that rises between the grid and the rim, a touch of the realm's accent, darker at the edge; the grid sits in the flat middle, so the tiles meet the grass without a seam;
  - a grass lip, three earth bands and an inverted, jittered rock cone in strata, a second cone hanging off-centre and a ring of hanging spikes;
  - roots under the rim, curtains of long roots off the cone, and vines with leaves that sway (`sway_by_uv`);
  - the scatter as `MultiMeshInstance3D`: grass tufts, pebbles, flowers (or crystal shards, or ember cracks), the rim's soft grass fringe, the hanging fringe and rim rocks;
  - waterfalls with pools, mist at their feet, floating islets, puffy clouds, and a soft cloud sea under the rock.
- **Each realm's signature off the grid** (§21.4): Crystalline's crystal spires round the rim, Skyfield's fence of posts, Lantern Vale's fireflies and glowing caps, the Heart's golden motes, Emberreach's sparks and ember cracks, Verdant's pollen; Tidehold's sand round the rim and four waterfalls, the Heart three.
- **Painted textures** (`LookPaint`): the meadow (soft blots, upward strokes, tufts, flower dots) and the strata (bands, seams, lumps, cracks), drawn into grey `Image`s at start-up as the diorama draws its canvases, tiled; the vertex colour paints them.
- **Palettes and light** (`RealmPalette`): all seven realms with the diorama's grass, dirt, rock, accent and three-colour sky, and its `lights` table (sun strength, hemisphere sky and ground, sun position), crossed with §21.2's day, dusk and night by the player's hour. Lantern Vale keeps its twilight at noon.
- **Sky** (`sky.gdshader`): the realm's three colours down the screen, a glow behind the island and stars when dark.
- **Atmosphere**: height fog sinking the rock into the sky; a vignette as one screen-space quad (`look_vignette.gdshader`, the diorama's CSS vignette); shadows fitted to the island with a soft edge.
- **Toon ramp** (`toon_light.gdshaderinc`): now read as three.js's toon material reads the diorama's gradient map (N·L remapped to [0, 1]), so a face side-on to the sun stands in the third step as in the design; the shadow takes a lit face to the second step with a soft edge. Uniforms unchanged.

## Traps found

- **The sky.** Godot's sky shader under an orthographic camera sees one direction, so the whole sky was one colour. The environment's canvas background fixes that, but in the Compatibility renderer it is lost as soon as a material with `cull_front` (the ink outline's inverted hull) is drawn: the background canvas is drawn with the outline's cull state. The sky is now a quad over the whole screen at the far plane (`far_z` 0.00001: the renderer's depth is reversed).
- **`QuadMesh`** has no `surface_get_array_index_len`, which the budget test calls on every mesh; the look's quads are `ArrayMesh`es.
- A `Color` times a number scales its alpha too, and alpha under 1 means "glow" in the toon kit: darken with `IslandBuilder._dim`.

## Hooks outside the track

- `client/tests/world_tests.gd`: the material check accepts the look's shaders and reads the sky from `WorldLook.sky_material`; the budget check counts the scatter's `MultiMeshInstance3D`s (every instance's triangles, one draw call a kind).

## Budget

Island and scatter on a 12 × 12 grid (heart): about 13,000 triangles in 18 draw calls (measured in round 1; to be re-measured at the end).

## Stills

- Round 0, before: `docs/art/shots/look/r0-before-world.png`, `r0-before-realms.png`.
- Round 1: `r1-world.png`, `r1-realms.png` (rows: heart, skyfield, crystalline, tidehold, emberreach, verdant, lanternvale; columns: 12, 19, 23).

## Still worse than the design

- Skyfield and Verdant read too saturated at noon.
- The grid's flagstones (T3's) are much lighter than the meadow, so the island reads as a pale square in a green ring; the design's ground is one painted meadow.
- No law/realm particles that move up (sparks rise, motes drift only sideways).

## Next

- Rounds 2+: value structure per realm against §21.10's grayscale test, rim thickness, clouds.
