# T3 Kit: the realm's ground, features, buildings and pieces

Branch `claude/3d-kit`. Everything that stands on the realm's grid: the painted ground, the 39 terrain features with realm variants, water and lava, the 17 buildings at §21.5's four looks, the Heart's citadel and walls, the Vault, the pylons and the wards at two levels.

## Before and after

| | Still |
|---|---|
| Before (the flagstone chequer and box features) | `docs/art/shots/kit/00-before-world.png` |
| A lived-in Heart, home camera | `09-heart-citadel.png` (and `02-realm.png` from round 2) |
| The same, close | `03-realm-close.png` |
| Four realms side by side (Skyfield, Tidehold, Lantern Vale at night, Crystalline) | `04-realms.png`, `04-lanternvale-night.png` |
| Each realm's own ground pattern | `06-realm-grounds.png` |
| Every feature (sampler), close | `02-features-close.png`; realm variants `08-feature-variants.png` |
| Cliffs, ramp and stairs | `03-cliffs-ramp-stairs.png` |
| Buildings at levels 1, 4, 7, 10 | `01-buildings-a.png` (Spire, Vault, Anchor Stone, Star Well, Aether Spring, Garden), `01-buildings-b.png`, `03-buildings-glass.png` (Garden to Nursery), `07-buildings-library-to-dock.png` |
| The heist up close (Vault, pylon, wards) | `05-heist-close.png` |

Shots to re-render them: `client/tests/shots/kit_realm.gd` (REALM, LEVEL, HOUR, ZOOM, TURN), `kit_features.gd` (every feature on one island; REALM, ZOOM), `kit_buildings.gd` (ROWS of `BuildingKit.KINDS` at the four looks; REALM, W, H, FRAMES).

## What is built

| File | What it does |
|---|---|
| `client/world/geo.gd` | The shape kit, extended: `rbox` (chamfered box: every edge catches the light and reads soft), `rock` (a faceted seeded icosahedron, the design's dodecahedron stones), `gem`, `torus`, `cyl`, `gable`, `blade` (a three-triangle grass blade), `ball(upper)` for domes, and per-vertex paint (UV/UV2) for the ground. Every vertex carries an idle motion in CUSTOM0 (`Geo.Anim`: sway, spin about Y/X/Z, bob, flag, swing, shiver) with its pivot, so one merged mesh moves with no node or script per piece. |
| `client/world/kit_anim.gdshaderinc` | That motion, read by every kit shader. |
| `kit_toon.gdshader`, `kit_outline.gdshader`, `kit_clear.gdshader` | The toon look (T2's `toon_light.gdshaderinc`, included, so the ramp stays one) plus the motion; the ink hull moves with its piece; lanterns and windows breathe. |
| `client/world/kit_ground.gd` + `kit_ground.gdshader` | The grid's ground as one painted surface. Tiles are flat at their heights; the paint is in the vertices (grass and its patches, lush moss and tall grass, worn earth under buildings, scorch round lava, sandy banks by water, grit by scree, a contact shade round whatever stands up). The shader adds broad light-and-shade patches, soft painterly dabs, blade flecks, the realm's petals and pebbles, cobbled path ribbons with a kerb (a distance field to the path network, so paths turn and branch), strata on cliffs, faint seams where tiles meet, and each realm's own ground: field strips (Skyfield), hexagon flags (Crystalline), sand ovals (Tidehold), glowing cracks (Emberreach), glowing moss (Lantern Vale), dense flowers (Verdant). Steps between levels are soft earthy cliffs with a rounded grass lip, fallen stones at the foot and grass hanging over; the grid's edge runs out onto the island as a grass skirt in the island's own colour. |
| `client/world/water.gdshader` | Water: the shore found per fragment from a side mask, so ponds and streams have rounded banks; deep in the middle, a thin broken foam line, drifting light streaks, ink ripples (§21.10) and a slow swell; marsh, spring and rapids tinted. Lava: a dark crust in plates over a melt that pulses through the cracks. |
| `client/world/kit_features.gd` | Every sim feature, ported from the design's `feat` switch at its proportions (its cell is one tile: units × 0.45 m) and pushed further: fences, ruin walls and hedges join their neighbours; ramps, stairs and vines find the higher neighbour and waterfalls the lower one; trees grow by realm (round with fruit, pine, willow with fireflies, birch); pillars, boulders, bushes and tall grass have realm variants (glass columns, basalt columns, sea stacks, crystal-studded or glowing-veined boulders, dandelion puffs, frost moss, ember grass, wheat); a round arch with a gold keystone; a bell that swings; crystals that turn; fog that drifts; stepping stones that float. Hero features are inked; the rest are texture. |
| `client/world/kit_style.gd` | The design's own per-realm wall, roof, stone and accent colours (`REALMS` in realm-diorama.js), found from the palette, and the shared timber, iron, gold and window light. |
| `client/world/building_kit.gd`, `kit_buildings2.gd` | All 17 kinds of `content/buildings.json`, each with §21.5's silhouette, at four looks: 1–3 timber, thatch and rough stone; 4–6 plaster, dressed stone, the realm's roof and trims; 7–9 crystal-white walls, lilac roofs and gold frames with crystal finials; 10 a crown per kind (the Book of Laws, a star-map ring, a tree-house wing, a floating cargo hold, a lighthouse, a third sphere, a second telescope…). The design's parts: shingled gable roofs, shuttered windows with warm light, arched doors, timber frames with braces, stone courses, chimneys with smoke, the well's turning wheel and bobbing bucket, greenhouses and the Nursery's egg in see-through glass. The design's `dress`: a packed-earth pad, a lamp post, a flag from level 3, banner poles and a turning finial from level 6; and its `topper`, the realm's mark on every roof (crystals, a pinwheel, a shell dome, a brazier, moss, a lantern, flowers). Silhouettes are inked; fine parts go to an un-inked layer so a thin part never turns into a black line. 600–4,000 triangles each. |
| `client/world/kit_citadel.gd` | The Heart's walls: a low crenellated ring with towers and a bannered gate just past the grid, drawn where the Spire stands in a Heart realm. The citadel itself is the Keeper's Spire on its 3 × 3 footprint: terrace, curtain wall, four corner towers, gatehouse, and the Spire with turning rings and an orb. |
| `client/world/piece_kit.gd` | The Vault (domed strongbox with star rivets and a breathing dial, a fifth larger than its parts; open: the dome swung back over a glowing hoard), the pylon (obelisk with runes and its school's shape turning on top; broken: the top fallen in rubble), the six wards as §21.5's trap props in a worn stone ring with a faint rune circle (grate, crystal shards, clock-rune snare, copper coil, thorn roots, swinging lantern) at two levels (gold inlay at the second), and the spent ward. `ward(kind, level := 1)` and `pylon(school := "matter")` keep the old calls working. |
| `client/world/realm_kit.gd` | Orchestrates the above from `RulebornReplay`. A 3 × 3 footprint is the Keeper's Spire, a 2 × 2 a Hearth, unless the screen passes `buildings` (`RulebornIsland.buildings()`, optionally with a level each). |

## Layers and calls

`RealmKit` layers: `ground` (the painted terrain), `scatter` (tufts, cliff stones), `hero` (inked), `prop` (ambient features and buildings' fine parts), `clear` (fog, crystal, glass), `water`, `lava`. `instances()` returns them as MeshInstance3Ds with materials: 7 meshes, 8 draw calls (the hero layer's ink is a second pass). The example heist realm is about 10,500 triangles of kit; the lived-in Heart of `kit_realm.gd` with ten buildings at level 7, eight trees and its walls about 28,500 (faces turned down are never drawn: §21.1's cameras are always above).

## Hooks in other tracks' files

- `client/world/world_view.gd` (T5): `_build_statics` adds `kit.instances()` instead of making a material per layer (the kit's materials carry the motion); the Vault, pylons and wards use `RealmKit.material("toon", true)`; a `buildings` var is passed to the kit, so a screen that knows the island's buildings (`RulebornIsland.buildings()`) draws each footprint as its kind. The static key does not include `buildings` yet; T5 may add it.
- `client/tests/world_tests.gd`: the material check accepts the kit's shaders and its moving ink.
- `client/tests/run.gd`: registers `KitTests`.
- **For T2:** the island's grass top (`IslandBuilder.rock`) covers the grid at y = −0.02, so anything of the grid below that (water beds, pits) is hidden. Water is kept 1.2 cm under its tile for now (`KitGround.WATER_DROP`), which reads as the design's flush ribbons. If the island leaves a hole for the grid (|x| < w/2, |z| < h/2; the kit's skirt reaches 0.45 m beyond), set `WATER_DROP` to about 0.08 and the beds show. The ground uses `palette["grass"]`, `["ground"]` (paths, worn earth), `["soil"]` and `["rock"]`, so a richer palette from T2 flows straight in; the Heart's walls sit at the grid's half-diagonal + 0.5 m, inside the island's rim (half-diagonal + 1.4).
- **For T5/integrator:** `kit_realm.gd` shows how a screen passes buildings and levels.

## Tests

`client/tests/kit_tests.gd` (in `run.gd`): every feature code builds its own piece inside a tile's budget and the route-changing ones are inked; every one of the 17 buildings builds at each of the four looks inside §21.3's 8,000 and each look differs from the one before; the Vault, pylons and six wards at two levels build; footprints map to the Spire or the named kind and level; the grid's ground runs out past its edge and ends in the island's own grass; a realm's kit is under 40,000 triangles in at most seven meshes.

## Still worse than the design

- **Value structure** (§21.10's grayscale test): T2's palettes and light make the ground near-white in grayscale; the design's ground is mid-grey under darker roofs. The kit follows the palette so the grid and island stay seamless; a deeper grass from T2 fixes it for both.
- Water beds and banks are flush (the island-top note above).
- Several buildings are under §21.3's 2,000-triangle floor (Vault 800, Aether Spring 900, Beacon 900, Ward 360); they read, but the Aether Spring and the Anchor Stone are the plainest silhouettes left.
- Doors face their nearest path (`RealmKit.facing`), a choice the simulation does not make; a screen-given facing would override it.
- The level-10 crowns are small at the home camera's distance.
- Lantern Vale's glowing moss glows by day too; it could follow the hour.

## Next

- Read the hour (T2's `WorldLook`) to strengthen window and lantern glow at dusk and night.
- Give the Aether Spring and the Anchor Stone stronger silhouettes; raise the small buildings toward 2,000 triangles where it buys shape.
- Workers by producers (T5's actors).
