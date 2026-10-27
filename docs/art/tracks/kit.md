# T3 Kit: the realm's ground, features, buildings and pieces

Branch `claude/3d-kit`. Everything that stands on the realm's grid: the painted ground, the 39 terrain features with realm variants, water and lava, the 17 buildings at §21.5's four looks, the Heart's citadel and walls, the Vault, the pylons and the wards at two levels.

## Before and after

| | Still |
|---|---|
| **Integrated (after merging all tracks), before round 21**: the grid a lighter square with seams on T2's meadow | `docs/art/shots/kit/21-integrated-before.png` |
| **Integrated, now**: one meadow, worn trails to the Vault | `21-integrated-meadow.png`, the heist screen `21-heist-screen.png`, a lived-in Heart and Skyfield `22-integrated-realms.png` |
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
| `client/world/kit_ground.gd` + `kit_ground.gdshader` | The grid's ground as one painted surface, **continuous with T2's island meadow**: since the second integration the meadow turns, over `IslandBuilder.GRID_BLEND` metres beside the grid, to the palette's `grass` and the shared brush (`look_brush.gdshaderinc`, the kit's own brush written out once for both), and the grid paints that same `grass` under that same brush, so the two meet as one ground. Worn earth trails join the buildings' doors and the Vault (a spanning tree of elbowed runs; ground paint only, distinct from the simulation's cobbled gravel, and deciding nothing). |
| `client/world/water.gdshader` | Water: the shore found per fragment from a side mask, so ponds and streams have rounded banks; deep in the middle, a thin broken foam line, drifting light streaks, ink ripples (§21.10) and a slow swell; marsh, spring and rapids tinted. Lava: a dark crust in plates over a melt that pulses through the cracks. |
| `client/world/kit_features.gd` | Every sim feature, ported from the design's `feat` switch at its proportions (its cell is one tile: units × 0.45 m) and pushed further: fences, ruin walls and hedges join their neighbours; ramps, stairs and vines find the higher neighbour and waterfalls the lower one; trees grow by realm (round with fruit, pine, willow with fireflies, birch); pillars, boulders, bushes, tall grass, fences, lantern posts, statues, ruin walls, hedges, arches and bounce mushrooms have realm variants (with the trees, about 85 distinct meshes across the 39 features, §21.9's "about 80") (glass columns, basalt columns, sea stacks, crystal-studded or glowing-veined boulders, dandelion puffs, frost moss, ember grass, wheat); a round arch with a gold keystone; a bell that swings; crystals that turn; fog that drifts; stepping stones that float. Hero features are inked; the rest are texture. |
| `client/world/kit_style.gd` | The design's own per-realm wall, roof, stone and accent colours (`REALMS` in realm-diorama.js), found from the palette, and the shared timber, iron, gold and window light. |
| `client/world/building_kit.gd`, `kit_buildings2.gd` | All 17 kinds of `content/buildings.json`, each with §21.5's silhouette, at four looks: 1–3 timber, thatch and rough stone; 4–6 plaster, dressed stone, the realm's roof and trims; 7–9 crystal-white walls, lilac roofs and gold frames with crystal finials; 10 a crown per kind (the Book of Laws, a star-map ring, a tree-house wing, a floating cargo hold, a lighthouse, a third sphere, a second telescope…). The design's parts: shingled gable roofs, shuttered windows with warm light, arched doors, timber frames with braces, stone courses, chimneys with smoke, the well's turning wheel and bobbing bucket, greenhouses and the Nursery's egg in see-through glass. The design's `dress`: a packed-earth pad, a lamp post, a flag from level 3, banner poles and a turning finial from level 6; and its `topper`, the realm's mark on every roof (crystals, a pinwheel, a shell dome, a brazier, moss, a lantern, flowers). Silhouettes are inked; fine parts go to an un-inked layer so a thin part never turns into a black line. 600–4,000 triangles each. |
| `client/world/kit_signature.gd` | Each realm's signature round its home, grown with the realm's level (inferred from the grid's side, 10 to 14 tiles for levels 1 to 5): one windmill then two, crystals that grow, a young tree then the great tree, four lanterns then eight and the floating festival, vents that grow into chimneys. |
| `client/world/kit_citadel.gd` | The Heart's walls: a low crenellated ring with towers and a bannered gate just past the grid, drawn where the Spire stands in a Heart realm. The citadel itself is the Keeper's Spire on its 3 × 3 footprint: terrace, curtain wall, four corner towers, gatehouse, and the Spire with turning rings and an orb. |
| `client/world/piece_kit.gd` | The Vault (domed strongbox with star rivets and a breathing dial, a fifth larger than its parts; open: the dome swung back over a glowing hoard), the pylon (obelisk with runes and its school's shape turning on top; broken: the top fallen in rubble), the six wards as §21.5's trap props in a worn stone ring with a faint rune circle (grate, crystal shards, clock-rune snare, copper coil, thorn roots, swinging lantern) at two levels (gold inlay at the second), and the spent ward. `ward(kind, level := 1)` and `pylon(school := "matter")` keep the old calls working. |
| `client/world/realm_kit.gd` | Orchestrates the above from `RulebornReplay`. A 3 × 3 footprint is the Keeper's Spire, a 2 × 2 a Hearth, unless the screen passes `buildings` (`RulebornIsland.buildings()`, optionally with a level each). |

## Layers and calls

`RealmKit` layers: `ground` (the painted terrain), `scatter` (tufts, cliff stones), `hero` (inked), `prop` (ambient features and buildings' fine parts), `clear` (fog, crystal, glass), `water`, `lava`. `instances()` returns them as MeshInstance3Ds with materials: 7 meshes, 8 draw calls (the hero layer's ink is a second pass). The example heist realm is about 10,500 triangles of kit; the lived-in Heart of `kit_realm.gd` with ten buildings at level 7, eight trees and its walls about 28,500 (faces turned down are never drawn: §21.1's cameras are always above).

## For T6 (and T4): the mid-detail level

**T6, switch to this:** set `kit_detail = BuildingKit.MID` on the `WorldView` (your `StageView`) before `show_replay`, and in `StageTown.build` call `BuildingKit.build(g, kind, mid, side, lvl, colours, null, null, 0.0, BuildingKit.MID)`. The universe map's near buildings (T4, `universe_island.gd:421`) can pass the same last argument.

- `BuildingKit.build(…, detail := BuildingKit.FULL)`: a new optional last argument; `BuildingKit.MID` draws the same silhouette at about a third of the triangles. Every existing call is unchanged.
- `RealmKit.detail` (set before `build()`), and `WorldView.kit_detail`, a two-line hook in T5's file that passes it on.
- What the mid level drops: window frames, shutters, mullions and sills (a lit pane stays), door surrounds, timber frames, stone courses, plinth rocks, banners, flower beads and other parts too small to see at the realm's zoom; roofs keep two rows of shingles; chains are bars; the well's wall is one course. `Geo.coarse` halves the sides of round shapes (never under six), and a chamfered box is a plain one. Small parts move off the inked layer, so the ink pass draws less.
- Parts under 3.5 cm (`BuildingKit.LEAST`, `Geo.least`) are left out at mid: about a pixel on the home camera. A flower meadow keeps 12 of its 22 flowers, with flat heads.
- Measured (`KitTests.lived_in`: the Spire and nine buildings at level 10 on a 14 × 14 grid, trees, water, lanterns, the Heart's walls; triangles as drawn, the inked layer counted twice): **49,682 at full, 23,666 at mid.** The 17 buildings at level 10 take 37 % of their full triangles in one layer. Stills: `docs/art/shots/kit/40-mid-detail.png` (full left, mid right).
- **The realm view with the switch** (measured by `screen_realm.gd`'s `ShotKit` with `StageView.kit_detail = BuildingKit.MID` and `StageTown` at `MID`, edited locally and not committed): **99,354 → 88,027 triangles**, 103 draw calls. A per-node count of that screen: the statics' kit toon layers about 16.5k at full, the Town 12.6k at full, the island's meadow and grass about 16k (T2), six character models about 36k (T1/T6). So the kit's share is now small; the characters are most of what is left.

## For T4: the map version of every building

`BuildingKit.build_map(geo, kind, mid, side, lvl, colours)` (`client/world/kit_map.gd`) draws the universe map's light version of any of the 17 kinds, as the design's `makeB` does for its map: 32–250 triangles each (the full `build` is 600–4,000), one layer, no fine parts, reading by kind (the cottage and chimney, the barn, the well under its roof, the domed Vault, the Spire in its ring, the obelisk, the fountain, the egg, the tower and lantern, the domed telescope, the mast, the pier and sail) and by §21.5's look (thatch and rough stone at 1–3, the realm's roof and a cap of its colour at 4–6, white walls, lilac roofs and a gold finial at 7–9, a glowing crown at 10, a flag from 3). Same arguments as `build`; set `geo.skip_down = true` to drop faces turned down. `universe_island.gd:337` can call it in place of `BuildingKit.build`. Still: `docs/art/shots/kit/23-map-buildings.png`. `KitTests` holds every kind and look to 250 triangles.

**Budget note:** the universe map draws its near buildings with the full `BuildingKit.build`, and seven realms sit just under §21.3's 40,000 triangles (39,697 at `universe_view_tests`). Anything added to a full building counts against that; measure the map after adding detail.

## Hooks in other tracks' files

- `client/world/world_view.gd` (T5): `RealmKit.by_hour(statics, look.hour)` in `set_sky_hour` and after the statics are built, so the kit's windows, lanterns and crystals shine brighter at dusk and night; `kit.island_seed = seed_from` (round 21, so the grid takes the meadow's colour); pylons pass their `school` to `PieceKit.pylon`; `_build_statics` adds `kit.instances()` instead of making a material per layer (the kit's materials carry the motion); the Vault, pylons and wards use `RealmKit.material("toon", true)`; a `buildings` var is passed to the kit, so a screen that knows the island's buildings (`RulebornIsland.buildings()`) draws each footprint as its kind. The static key does not include `buildings` yet; T5 may add it.
- `client/tests/world_tests.gd`: the material check accepts the kit's shaders and its moving ink.
- `client/tests/run.gd`: registers `KitTests`.
- **For T2:** the island's grass top (`IslandBuilder.rock`) covers the grid at y = −0.02, so anything of the grid below that (water beds, pits) is hidden. Water is kept 1.2 cm under its tile for now (`KitGround.WATER_DROP`), which reads as the design's flush ribbons. If the island leaves a hole for the grid (|x| < w/2, |z| < h/2; the kit's skirt reaches 0.45 m beyond), set `WATER_DROP` to about 0.08 and the beds show. The ground uses `palette["grass"]`, `["ground"]` (paths, worn earth), `["soil"]` and `["rock"]`, so a richer palette from T2 flows straight in; the Heart's walls sit at the grid's half-diagonal + 0.5 m, inside the island's rim (half-diagonal + 1.4).
- **For T5/integrator:** `kit_realm.gd` shows how a screen passes buildings and levels.

## Tests

`client/tests/kit_tests.gd` (in `run.gd`): every feature code builds its own piece inside a tile's budget and the route-changing ones are inked; every one of the 17 buildings builds at each of the four looks inside §21.3's 8,000 and each look differs from the one before; the Vault, pylons and six wards at two levels build; footprints map to the Spire or the named kind and level; the grid's ground runs out past its edge and ends in the island's own grass; a realm's kit is under 40,000 triangles in at most seven meshes.

## Still worse than the design

- The grid is hard to read as tiles at all with the overlay off (seams at 3.5 %), as the design's realm view; the builder's overlay (`RealmKit.show_grid`) draws the design's rounded tiles.
- Trails are drawn by the shader (crisp, 0.45 m wide, ragged edge, a rim of worn grass) and bend round their corners; they never cross water or avoid features, since they are paint.
- ~~Value structure~~: since the integrations, the grayscale test passes: mid-grey meadow under dark roofs, as the design's (`docs/art/shots/kit/33-grayscale.png`).
- Water beds and banks are flush (the island-top note above).
- Several buildings are under §21.3's 2,000-triangle floor (Aether Spring 900–1,200, Beacon about 900, Ward 360; the Vault is now 1,300–1,700 with its portico). They read, and the Spring and the Anchor Stone have been rebuilt; the Ward is a small trap by design.
- Doors face their nearest path (`RealmKit.facing`), a choice the simulation does not make; a screen-given facing would override it.
- Wards always draw at level 1 in a heist: the simulation's ward record has no level yet (`PieceKit.ward(kind, level)` takes one).

## Next

- Read the hour (T2's `WorldLook`) to strengthen window and lantern glow at dusk and night.
- Give the Aether Spring and the Anchor Stone stronger silhouettes; raise the small buildings toward 2,000 triangles where it buys shape.
- Workers by producers (T5's actors).

## Session two (resumed 14:31 UTC)

Lanes drawn crisp and bending; glow by the hour; doors spill lamplight; Lantern Vale's pale pads; banks that sit in the meadow; raised ground by value; ice as a frozen pool; fog as a drift; one-slab roofs; the Vault's portico; water by realm; realm signatures grow with level; lava that glows through and round scorch marks; realm variants for fences, lanterns, statues, ruins, hedges, arches and mushrooms; rising and falling motion (stars into the well, sparks, steam, smoke); a courtyard round the Spire with the Heart's cream flagstones; tunnel mouths that face each other. Stills `25-…` to `38-…`. The universe map's budget is watched (see the budget note).

## Stopped here (session one)

Stopped at the owner's request on 2026-10-20, 07:50 UTC.

- **Done:** everything above, with the second integration merged (commit `b0e88f5`) and the grid matched to its meadow (`506bd9d`). gdlint and all kit tests pass on that state. The last full `check_all` that finished ("All checks passed") ran on `2b639a3`, before the second merge.
- **In progress:** a full `check_all` on the merged state, stopped before it finished, so it is not confirmed there.
- **Next:** run `bash tools/check_all.sh` on this branch. Then T4 can switch `universe_island.gd:337` to `BuildingKit.build_map`, and the kit can go on with the items under "Still worse than the design" (crisper trails, the four plainest buildings, a stronger grid overlay for the builder).

## Stopped here (session two, 19:22 UTC)

Stopped at the owner's request.

- **Done:** everything above, through `e69e866` (round trees in three shapes). The last full `check_all` that finished passed on the merged third integration (`cdfddff`). Since then I have run the client tests (323 of 323) and the kit tests after each change, and measured the universe map at 39,695 triangles, under its 40,000 limit. No full `check_all` has run on the final commits; it takes about 25 minutes, so I skipped it at the stop.
- **Not started:** the integrator's request (16:19 UTC) for a mid-detail level for the realm-view and home cameras. T6 measures the realm view at about 93k triangles against §21.3's 40k. That note reached this session only at the stop, so no work was done on it.
- **Still worse than the design:** see "Still worse than the design" above. Water lies flush with the ground (it needs T2's meadow to leave the grid open); wards always draw at level 1 in a heist (the simulation's ward record has no level); trails are paint and ignore features.
- **Next:**
  1. The mid-detail level, added alongside the existing calls so T4 and T6 don't break. For example, an optional `detail` argument to `BuildingKit.build` and to `RealmKit`: buildings and hero features at about a third of their heist triangles, silhouettes kept, with fine parts, panes and dress dropped first.
  2. A test that a fully built realm at that level stays under 40,000 triangles, and a line here telling T6 the call to switch to.
  3. Then a full `check_all`.

## Session three (fourth wave, from 22:41 UTC)

The mid-detail level, crisper trails, the four plainest buildings, sunken water and the builder's grid were all pushed in the third wave (`a5f7c7e` to `3256e66`); the session-two "Next" list above is done. This session compares the kit with the design's Realm view (`04-realm-view`), terrain editor (`21-terrain-editor`) and land stills, round by round.

- **Round 1, the Heart against 04-realm-view.** Worst: (1) the design's salmon octagon pads under every building were lost under our buildings and read dull brown; (2) its paths are rose-cream pebbles, ours grey mosaic; (3) its Spire is a slim banded tower on a stepped octagon, ours a castle with curtain walls and four towers. Fixed: pads are the design's formula (the realm's soil halfway to cream) lifted to its rendered salmon (#C98879 drawn, against the still's #CC8C79), broader (0.8 of the footprint) and kept out of the kit's contact shade; the Heart's flagstones are rose-cream and each stone lit as a rounded top; the Spire stands alone on its terrace as the design's realm view draws it (`kit_buildings2.gd` `_citadel`), steps and a door south, lit slits between the buttresses. Still `46-heart-pads-spire.png` (design left).
- **Round 2, the builder's grid against 21-terrain-editor.** The dark ink net is now the design's soft tiles: each a pale rounded square inset from its neighbours, a lighter face and a darker gutter (`kit_ground.gdshader`, still `grid_show`). Still `47-builder-grid-tiles.png`.
- **Round 3, houses.** The design's cottages are plaster and dark timber on both storeys; ours had a grey stone ground floor that read dull at the realm's zoom. From the second look the Hearth's ground floor is plaster with the frame, the frame is dark timber with its braces by the corners (clear of the windows), and its posts and braces stay at the mid detail. The Heart's plaster is warmer (#FCE0D8), as the toon ramp's violet shade greyed the design's #F6DDE6.
- **Round 4, paths.** A gravel path tile no longer scatters six dark grit stones (they read as dirt on the painted cobbles, and cost about 120 triangles a tile); other realms' paths are their soil toward sand, as Skyfield's land still (`48-skyfield-paths.png`).
- **Round 5, the Star Well against 04-realm-view.** The design's well reads by a broad open gable along its beam (:713) over bright, glowing water; ours had a small hip roof over pale water. Now the gable (`roof(…, infill := false)`, no attic under it; the unused hip roof is gone) and water in the design's glowing yellow. The Heart's stone is warmer (#F2E0D6), so the Spire's terrace reads cream, not grey. Still `49-star-well.png` (design left), the turned Heart `50-heart-turned.png`.
- **Round 6, lanterns.** A lantern's pool of light was a 0.84 m flat yellow disc that read as a puddle at the realm's zoom; it is now a small 0.52 m glow at the post's foot.
- **check_all** on `a400fa5`: every check passes except one client test against the server, "Weaving offers the starting laws at the simulation's prices…": the server offers Slow rivers at 0 points and price 0 (the Heart's first recommended law), so `priced > 0` fails. It reproduces on a re-run; it is in the weaving and server code, not the kit (this branch changes only `client/world/` kit files and `kit_tests.gd`). The environment needed `rustup target add wasm32-unknown-unknown`, `pip install gdtoolkit playwright` and a `chrome-linux` link beside the image's `chrome-linux64` for the prototype check.
- **Round 7, the Guardian Post against 04-realm-view.** The design draws the post as a broad stone watchtower with a parapet of merlons round a drum and cone roof (:733–741); ours was a slim timber tower with a wooden gallery at every look. §21.5 asks for "a small watch platform with a lantern", wood, so the first look keeps that; from the second look it is the design's tower, with the lantern and school banner. Still `51-guardian-tower.png` (design left, our four looks).
- **Round 8, water.** The Heart's water drew bluer than the design's cyan (#4782BD against #39ACCA); the default deep colour is greener, now drawn #3794B8.
- **check_all** on `07847fe` (00:30 UTC): the same one weaving test against the server fails, as on `a400fa5`; every other check passes ("All checks passed" for everything after the client tests).
- **Round 9, the other realms against their land stills.** Pads are the Heart's salmon only in the Heart; elsewhere they are the realm's dirt halfway to cream, lifted (Verdant's tan, `52-verdant-pads.png`). Emberreach's plaster is a light warm ash (#D8BEB0), as its land still draws its houses, not the design table's dark #5A4448, which made the realm read as one dark mass (`53-emberreach-walls.png`).
- **Round 10, Lantern Vale against its land still.** The design draws its houses glowing warm in the dark; ours were near-black. Its plaster is a pale lilac (#C2B2D6) that holds a little lamplight (a faint glow, warmed toward #FFD8B0), so the town reads at night (`54-lanternvale-lit-walls.png`).
- **Round 11, the Vault on the realm screen.** Beside 2 × 2 houses the Vault (one tile in the simulation) read as a small dome; the design draws it near a house's size. `PieceKit.vault` is now drawn 1.4 times its parts (was 1.2).
- **A difference left for the owner:** the Heart's walls ring (`KitCitadel.walls`, the Heart's signature past the grid) is my reading of §21.4's "terraced citadel"; the design's realm view draws no walls (its `kingdom`, which places a castle and walls, is defined in realm-diorama.js but never called, and its Heart signature is empty). Removing the ring is one line in `KitSignature.build` if the owner prefers the stills.
- **Round 12, the Spire close up.** Without its curtain wall the Spire fell to about 1,800 triangles at full; its terrace now has a balustrade open at the steps and two urns of flowers by them (fine parts, left out at the mid detail). Measured by `kit_probe.gd`: the 17 buildings at their four looks take 33 % of their full triangles at mid; the lived-in realm draws 20,816 triangles at mid with its ink (43,948 at full).
- **Round 13, the Garden's greenhouse against 04-realm-view.** The design's greenhouse reads by a bold white grid of glazing bars; ours had thin bars on two walls only, over grey glass. Now posts round all four walls, a mid rail, rafters over the roof, bars half as thick again, and paler glass (`55-greenhouse.png`, design left).
- **Round 14, trails against 02-heist.** The design's lanes are broad ribbons of round pink pebbles, two abreast; ours were a single file of stepping stones, which read thin at the heist's zoom. Now two staggered rows of round stones on a 0.5 m strip of trodden earth (`kit_ground.gdshader`), crisp at every zoom since the shader draws them (`56-pebble-lanes.png`, design left).

## Stopped here (session three, 03:50 UTC)

- **Done:** rounds 1 to 14 above, last code commit `8c7dab0`. Earlier sessions' "Next" lists are complete (mid detail, trails, plain buildings, sunken water, builder grid). **For T6:** the call is unchanged: `kit_detail = BuildingKit.MID` on the view, and `BuildingKit.build(…, BuildingKit.MID)` in `StageTown`.
- **check_all on `8c7dab0`:** every check passes except "against the server: Weaving offers the starting laws at the simulation's prices…". The server offers Slow rivers at 0 points. That is weaving or server code, which this branch does not touch.
- **Still worse than the design:** the realm screens' camera and island framing (T5/T6), not the kit's; the Heart's wall ring, which the stills don't draw (owner's call); the Vault is §21.5's domed strongbox where the stills draw a roofed block; the Spire plaza's edge is vertex-painted, so it is soft and octagonal; workers are not shown at their jobs (T5).
- **Next:** the owner's call on the walls; a crisp round edge for the plaza in the ground shader; re-run check_all once the weaving test is fixed upstream.
