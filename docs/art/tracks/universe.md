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

## Worse than the design (to do next)

- Island tops are flatter and emptier than the design's dense dressing; scatter and paths next.
- Buildings come from `BuildingKit` and look as good as T3 makes them.
- The whole-universe zoom is small on a phone when a screen covers half of it with words.

## Hooks in other tracks' files

None.
