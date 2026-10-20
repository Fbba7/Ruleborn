# T4 Universe: the home and the universe map in 3D

Branch `claude/3d-universe`. Owns `client/world/universe_*`, `link_*`, `skiff_*`, `star*`,
`client/scripts/home.gd`, `universe_screen.gd`, `map_screen.gd` and `client/tests/shots/universe_*.gd`.

## What is built

- `UniverseView` (`client/world/universe_view.gd`): the universe in 3D for any screen. Islands hang in a
  vertical column (the Heart in the middle, outer realms filling rows above and below in the order they
  opened, `UniverseLayout`), each in its realm's night colours (the design's `REALMS`) with its buildings
  at their levels from `BuildingKit`, its type's dressing, and what the design hangs under every island:
  school-coloured crystals, a halo, falls and a bright rim. The Heart carries the design's citadel
  (`UniverseCitadel`, ported from `castle`) with the Spire growing with its level, the beam and the
  three turning rings (coloured by the strain band).
- Links from the server's `links` (`LinkBuilder`): stone bridge (arched blocks, parapets, lamps), rope
  bridge (planks, rope rails, sways on its own node), chute (half-pipe with water running the way it goes),
  rift (two portal rings in the far realm's school colour with a stream of light). Faults: a crack of
  light across the faulted realm and a broken streak to the Heart.
- Skiffs (`SkiffBuilder`): turned hull, rail, cabin, mast, bellied sail with the school stripe, fins,
  bow lantern; they fly the first links back and forth with a glowing wake.
- Sky (`StarSky`, `universe_galaxy.gdshader`): night gradient, school-coloured nebulae torn by noise, a
  turning spiral galaxy placed from the screen's middle (so it reads as far off), three star layers at
  depths for parallax, haze, two comets.
- Pins (`UniversePins`): realm name and level, ready producers, raids, faults, the next realm to open;
  projected every frame and decluttered by urgency. Tappable plates, not buttons (the screens' word lists
  are the screen-reader route).
- Camera: orthographic, 35° pitch, quarter turns, three zooms; pinch, twist, drag, wheel, tap; a tap on
  a realm swoops in one second; between two realms the swoop goes through a cloud wipe; tilt parallax
  from the accelerometer or a slow drift; reduced motion makes all of it instant and still.
- Screens: home (the universe behind, the Keeper bar, a menu of the design's icons that scrolls, the
  large Heist button), the map and the universe screens (the universe behind their word lists; a tap on
  a realm scrolls its words into view). Every existing button, string and description is kept.
- Icons: the design's own icon set (`art/design/diorama/icons.js`) run in node and written as SVG in
  `client/world/universe_icons/` with the CSS inlined for ThorVG.
- Light: the map uses `universe_toon.gdshader` (the shared toon light, but vertex colours read as sRGB,
  as three.js reads them), which is why it is not washed out like a vertex colour read as linear.

Budget (`universe_zoom.gd` prints it): about 27,000 triangles and 25 draw calls for the full seven-realm
universe, inside §21.3's 40,000 and 150.

## Stills

- `docs/art/shots/universe/round0_before_world_shot.png`: what the client had (a single realm; the home
  and map were lists of words).
- `round1_home.png`, `round1_zoom0.png`, `round1_zoom1.png`, `round1_zoom2.png`,
  `round1_map_and_universe_screens.png`.

- Round 2: the meadow (two noise fields shade the grass in patches; MultiMesh tufts and flowers, two
  draw calls for the whole universe), rose cobble paths from the plaza to each building, peaks only on the
  rugged realms, soft violet contact shade under buildings, trees and peaks (`universe_shade.gdshader`),
  the camera brought in to 140 m so the sun's shadow could reach.
  Stills: `round2_home.png`, `round2_zoom0.png`, `round2_zoom1.png`, `round2_zoom2.png`.

- Round 3: the islands tightened round their buildings (Heart grid 15, outer 11; buildings three tiles
  across), the citadel on its own node drawn 1.35× so the Heart reads from afar, the Heart's beam and
  three turning rings, the galaxy's arms drawn as dust. Fixed what hid every light over the sky: additive
  materials that write no `ALPHA` are drawn in the opaque pass, and the galaxy plane (drawn after them,
  without depth) painted over them; the light shaders now write `ALPHA` and the galaxy is opaque with a
  low render priority. The cloud wipe rolls in as shaded cloud banks from both sides.
  Stills: `round3_home.png`, `round3_zoom0..2.png`, `round3_wipe.png` (mid-swoop),
  `round3_compare_skyruin.png` (ours left, the design's right, grayscale below).

- Round 4: a lamp where each building's path leaves the plaza; denser realm dressing; the design's icons
  in the pins (each realm's own icon, raids, faults, a full producer); a strain pin behind the Heart
  (§5.5's band name and the strain); the design's debris, rocks with trees drifting round each island (one
  MultiMesh); the sky's cost trimmed for phones (three octaves of noise, fewer haze sprites).
  Stills: `round4_zoom0.png`, `round4_zoom1_skyfield.png`, `round4_zoom1_crystalline.png`.

- Round 5: the map's world given more of the screen, and its pins compact when the islands are small
  (each realm's icon and level, alarms kept; producers and strain only once an island is big enough);
  the universe screen opens on the Heart; on home a third tap on a realm seen close opens its realm view.
  Still: `round5_home_map_universe.png` (home, the map, the universe screen).

- Round 6: skiff hulls faced the right way and drawn larger; the realm still to open keeps its pin, which
  leads to the universe screen where it is bought; the galaxy's core no longer glares.
  Stills: `round6_young_universe.png` (the Heart and two realms, the next to open as mist),
  `round6_skiff_close.png`.

- Round 7: the galaxy redrawn as the design draws it, two thin spiral arms of dust sweeping across the
  whole sky behind the islands, its core small, fewer loose stars; pins keep their names unless islands
  are really small.
  Stills: `round7_home.png`, `round7_zoom0.png`, `round7_zoom1.png`, `round7_compare_marta.png`.

Tests: `client/tests/universe_view_tests.gd` (registered in `run.gd`): the layout, that every realm and
link is drawn and nothing else, the budget, the camera's framing and taps, the pins, and home's menu.

## Worse than the design (to do next)

- Island tops are flatter and emptier than the design's dense dressing; scatter and paths next.
- Buildings come from `BuildingKit` and look as good as T3 makes them.
- The whole-universe zoom is small on a phone when a screen covers half of it with words.

## Hooks in other tracks' files

- `client/tests/run.gd`: one line registering `UniverseViewTests`.

## For other tracks

- T2: directional shadows do not show on anything drawn with `toon_light.gdshaderinc` under the
  Compatibility renderer here (tried orthogonal and two splits, the light at 30°, MSAA off). The map uses
  its own contact shade meanwhile.
- T2/T3: `toon.gdshader` reads vertex colours as linear, so every hex colour renders paler than the
  design (three.js converts hex from sRGB). `universe_toon.gdshader` converts; the realm view may want the
  same.
