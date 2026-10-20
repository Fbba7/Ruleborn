# T3 Kit: the realm's ground, features, buildings and pieces

Branch `claude/3d-kit`. Everything that stands on the realm's grid: the painted ground, the 39 terrain features, water and lava, the 17 buildings at §21.5's four looks, the Heart's citadel, the Vault, the pylons and the wards.

## What is built

| File | What it does |
|---|---|
| `client/world/geo.gd` | The shape kit, extended: `rbox` (a box with chamfered edges, so every edge catches the light and reads soft), `rock` (a faceted, seeded icosahedron: the design's dodecahedron stones), `gem`, `torus`, `cyl`, `gable`, `ball(upper)` for domes, and per-vertex paint (UV/UV2) for the ground. Every vertex carries an idle motion in CUSTOM0 (`Geo.Anim`: sway, spin about Y/X/Z, bob, flag, swing, shiver) with its pivot, so one merged mesh moves with no node or script per piece. |
| `client/world/kit_anim.gdshaderinc` | That motion, read by every kit shader. |
| `kit_toon.gdshader`, `kit_outline.gdshader`, `kit_clear.gdshader` | The toon look (T2's `toon_light.gdshaderinc`, included, so the ramp stays one) plus the motion; the ink hull moves with its piece; lanterns and windows breathe. |
| `client/world/kit_ground.gd` + `kit_ground.gdshader` | The grid's ground as one painted surface: tiles flat at their heights, the paint in the vertices (grass, lush moss, worn earth under buildings, scorched ground by lava, sandy banks by water, grit by scree), the shader's brush strokes and flecks, cobbles where the surface is gravel, strata on cliffs, and seams at tile edges faint enough to keep the grid readable without a chequer. A step between levels is a soft earthy cliff with a rounded grass lip, bulging and jittered; the grid's edge runs out onto the island as a grass skirt. Water carries its distance from the shore for foam and ripples. |
| `client/world/water.gdshader` | Water: deep in the middle, a broken foam line at the bank, drifting light streaks and ink ripples (§21.10), a slow swell; marsh, spring and rapids tinted by vertex colour. Lava: a dark crust in plates over a glowing melt that pulses through the cracks. |
| `client/world/kit_features.gd` | Every sim feature, ported from the design's `feat` switch at its proportions (its cell is one tile: units × 0.45 m) and pushed further: fences, ruin walls and hedges join their neighbours; trees grow by realm (round, pine, willow, birch); a round-arched stone arch with a gold keystone; a bell that swings; crystals that turn; fog that drifts; stepping stones that float. Hero features are inked; the rest are texture. |
| `client/world/kit_style.gd` | The design's own per-realm wall, roof, stone and accent colours (`REALMS` in realm-diorama.js), found from the palette. |
| `client/world/building_kit.gd`, `kit_buildings2.gd` | All 17 kinds of `content/buildings.json`, each with §21.5's silhouette, at four looks: 1–3 timber, thatch and rough stone; 4–6 plaster, dressed stone, the realm's roof and trims; 7–9 crystal-white walls, lilac roofs and gold frames with crystal finials; 10 a crown per kind (the Book of Laws, a star-map ring, a tree-house wing, a floating cargo hold, a lighthouse, …). The design's parts: shingled gable roofs, shuttered windows with warm light, arched doors, timber frames with braces, stone courses, chimneys with smoke, the well's wheel and bucket, a greenhouse; and its `dress`: a lamp post, a flag from level 3, banner poles and a turning finial from level 6. Silhouettes are inked; fine parts (windows, frames, rings, flags) go to an un-inked layer so they never turn into black lines. |
| `client/world/piece_kit.gd` | The Vault (domed strongbox, star rivets; open: the dome swung back over a glowing hoard), the pylon (obelisk with runes and its school's shape turning on top; broken: the top fallen in rubble), the six wards as §21.5's trap props (grate, crystal shards, clock-rune snare, copper coil, thorn roots, swinging lantern) at two levels (gold inlay at the second), and the spent ward. |
| `client/world/realm_kit.gd` | Orchestrates the above from `RulebornReplay`; footprints of 3 × 3 are the Keeper's Spire (the citadel), others a Hearth unless a screen passes `buildings` (`RulebornIsland.buildings()`). |

## Hooks in other tracks' files

- `client/world/world_view.gd` (T5): `_build_statics` adds `kit.instances()` instead of building materials per layer (the kit's materials carry the motion); the Vault, pylons and wards use `RealmKit.material("toon", true)`; a `buildings` var is passed to the kit so a screen that knows the island's buildings draws each footprint as its kind.
- `client/tests/world_tests.gd`: the material check accepts the kit's shaders and its moving ink.
- **For T2:** the island's grass top (`IslandBuilder.rock`) covers the grid at y = −0.02, so anything of the grid below that (water beds, pits) is hidden. Water is kept 1.2 cm under its tile for now (`KitGround.WATER_DROP`). If the island leaves a hole for the grid (|x| < w/2, |z| < h/2; the kit's skirt reaches 0.45 m beyond), set `WATER_DROP` back to about 0.08 and the beds show. The ground uses `palette["grass"]`, `["ground"]` (paths, worn earth), `["soil"]` and `["rock"]`, so a richer palette from T2 flows straight in.

## Layers

`RealmKit` layers: `ground` (now the painted terrain), `scatter` (grass tufts, new), `hero` (inked), `prop` (ambient features and buildings' fine parts, new), `clear`, `water`, `lava`. `instances()` returns them as MeshInstance3Ds with materials.

## Stills

- Before: `docs/art/shots/kit/00-before-world.png`.
- Round 1: `01-world.png`, `01-features-close.png`, `01-buildings-a.png`, `01-buildings-b.png`.

## Still worse than the design

- The heart palette's grass (`#B9C98A`, T2's) reads pale yellow beside the design's saturated green.
- Water is flush (see T2 note), so banks have no depth.

## Next

Rounds against the design stills; budgets test; the ground's brush; realm variants side by side.
