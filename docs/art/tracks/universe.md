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

Budget (`universe_zoom.gd` prints it; first rounds, before the merge): about 27,000 triangles and 25 draw calls for the full seven-realm
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

- Round 8: each link carries the design's icon for its kind at its middle (stone bridge, rope bridge,
  chute, rift), seen at the realm zooms.
  Still: `round8_zoom1_links.png`.

- Round 9: over the whole universe a twist turns the camera half way round, so the column stays upright
  on a portrait phone (a quarter turn laid it across the screen as a thin strip); the realm zooms keep
  quarter turns.
  Still: `round9_half_turn.png`.

- Round 10: a realm asked for before the universe has arrived (home opening on the Heart on a first
  launch, before the server answers) is remembered and shown once it is drawn, instead of dropped.

- Round 11, on the merged state (T1, T2, T3 in): the realms' buildings are T3's kit at their levels, and
  the Heart's citadel is T3's Keeper's Spire (on a five-tile footprint, drawn 1.35×) with the map's orb
  light. T3's buildings cost 1,000–3,900 triangles each, so the map now has two levels of detail: the
  kit's buildings only on the realm the camera is on, and a block in each building's level colours
  elsewhere (`UniverseIsland.near` / `far`); the meadow is a few triangles a tuft. The player's own
  characters (from the home view) appear as T1's sculpts on the realm seen close (zoom 2): at the
  building they work, napping when resting, strolling when idle; two at most, drawn 2.1× as the design's
  diorama draws its figures (`UniverseCrowd`). The flying things moved to `UniverseFlight`.
  Budget: 31,600 triangles and about 70 draw calls (two characters add about 11,800 in a close-up).
  Stills: `round11_merged_home.png`, `round11_merged_zoom0..2.png`, `round11_merged_map.png`,
  `round11_compare_marta.png`.

- Round 12 (the integrator's notes): the triangle count no longer drops the scatter, the far buildings and
  the rope bridges (it was assigned after they were added); counted honestly the map was 54,600, now
  39,700 for seven realms: lighter tops and rims, flat path stones, fewer peaks' crystals and debris,
  three-blade tufts and three-petal flowers, a lighter chute, and the kit's fine parts (windows, frames,
  flags) only while the close realm's buildings are under 4,500 triangles. The home menu's two "Your
  universe" tiles are now "Your universe" (the map) and "Buildings and realms" (`HOME_UNIVERSE`, every
  locale; the screen's own title is unchanged).
  Still: `round12_budget_home_zoom1_zoom2.png`.

- Round 13 (resumed): in the map and universe screens' word lists each realm's heading carries its
  realm's icon, and a tap on it swoops the map to that realm (`UniverseHeading`).
  Still: `round13_screens_headings.png`.

- Round 14: a gold level-up marker (the design's `levelup` icon) over each building the server's
  universe view says can be raised now (its `next` with nothing blocking), at the realm zooms.
  Still: `round14_levelup_markers.png`.

- Round 16, on the third integration (its far buildings are T3's `BuildingKit.build_map`, so there is
  one building path: the kit up close, its map version from afar). Each island is now its own node, and
  each link its own mesh, so a zoomed-in view draws only what is on the screen. An outer realm seen close
  (zoom 2) is T2's own island (`UniverseClose`: `WorldLook.island`, its painted meadow, strata cliffs,
  roots, falls and scatter, toned to the map's night through its `tint`); the Heart keeps the map's rock,
  as its citadel and buildings cover its ground. One character in a close-up. Wards are drawn with the
  buildings, so they stay in a close-up. The budget is now held to what is in view (`drawn_triangles`,
  counted per instance against the camera's frustum), at every zoom of every realm: 32,600 for the whole
  universe, at most 38,400 at a realm's zoom (the kit's fine parts only in a close-up) and 19,800–37,800
  for each realm seen close, all under 40,000; `universe_zoom.gd` prints both counts.
  Stills: `round16_home.png`, `round16_zoom0.png`, `round16_zoom1.png`, `round16_zoom2_heart.png`,
  `round16_zoom2_skyfield.png`, `round16_zoom2_crystalline.png`.

- Round 17: paths as the design's network (its scout stills), from the plaza to each first-ring
  building and round each ring between neighbours, in tan cobbles, drawn with the buildings so they stay
  on T2's island in a close-up; T2's ground tinted greener for the night.
  Stills: `round17_zoom2_skyfield_paths.png`, `round17_zoom2_verdant_paths.png`,
  `round17_compare_scout_skyfield.png` (ours at night beside the design's daytime scout still).

- Round 18: level-up markers only in a close-up, so the Heart at home's realm zoom is not crowded.
  (The design does not bob its islands in universe mode, so neither does the map.)
  Still: `round18_home.png`.

- Round 19 (cost on the phone): the kit's detailed buildings (about 5 ms each on a desktop CPU) are built
  for a realm only when the camera first comes to it (`UniverseIsland.build_near`), so the universe builds
  in 172 ms instead of 454 (desktop, seven realms); while the camera rests on a realm, its T2 island for
  the close-up is made ready, so the swoop in does not wait for it. The budget counting moved to
  `UniverseBudget`.

- Round 20: the close island's night tint by realm: the green realms kept green, Lantern Vale and
  Crystalline cool, Emberreach warm (Lantern Vale had come out teal).
  Stills: `round20_zoom2_lanternvale.png`, `round20_zoom2_emberreach.png`.

- Round 21: the Heart's meadow strewn with pink blossom petals, as the design's Heart scout still draws
  it (one more layer of instances, about 260 triangles).
  Still: `round21_zoom2_heart_petals.png`.

- Round 22: the winds round the Heart (§5.4: "ringed by strong winds, so skiffs can't land there") as
  the design's faint dome, a shell seen only at its edge with streaks of wind (`universe_dome.gdshader`).
  Still: `round22_zoom1_heart_dome.png`.

Tests: `client/tests/universe_view_tests.gd` (registered in `run.gd`): the layout, that every realm and
link is drawn and nothing else, the budget, the camera's framing and taps, the pins, and home's menu.

## Where it stands against the design

Judged beside `art/design/stills/obs/*.png` at phone size and in grayscale (`round3_compare_skyruin.png`,
`round7_compare_marta.png`):

- Better: every realm, link and fault the server names is drawn (the design draws a fixed sample); the
  four link kinds are built to their gap and carry their icons; skiffs fly the links with wakes; the sky
  has depth (three star layers, haze and debris that part on a tilt); the camera has the three zooms,
  quarter turns, the swoop and the cloud wipe; pins follow and declutter; and the whole seven-realm
  universe costs about 39,700 triangles in about 70 draw calls (`universe_zoom.gd` prints both), against
  the design's 676,192 in 1,207.
- As good: the night colours, the Heart's citadel, beam and rings, the lit rims and halos, the glowing
  crystals and falls beneath, the dust-armed galaxy.
- Still worse:
  - Away from the realm the camera is on, buildings are blocks in their level's colours (the price of
    §21.3's budget with T3's detailed kit).
  - No cast shadows: the shared toon light shows none under this renderer (see "For other tracks");
    the map's contact shade stands in.
  - Island tops at the far zoom are sparser than the design's, which packs props densely.

## Next

- Use T2's island (`IslandBuilder`) for the realm seen close; its meadow (4,800 triangles) is too heavy
  for all seven at once, so the far islands keep the map's light rock.
- Wildlife and skiff crews from T1 (each a full character's triangles, so a close-up only).
- Per-building window lights from the kit, and lantern props per realm type.
- A gentle bob and wind for the islands and their dressing (vertex animation in `universe_toon`).
- Measure frame time on a phone (the galaxy plane is one full-screen fragment pass).

## Hooks in other tracks' files

- `client/tests/run.gd`: one line registering `UniverseViewTests`.

## For other tracks

- T2: directional shadows do not show on anything drawn with `toon_light.gdshaderinc` under the
  Compatibility renderer here (tried orthogonal and two splits, the light at 30°, MSAA off). The map uses
  its own contact shade meanwhile.
- T2/T3: `toon.gdshader` reads vertex colours as linear, so every hex colour renders paler than the
  design (three.js converts hex from sRGB). `universe_toon.gdshader` converts; the realm view may want the
  same.

## Stopped here

Stopped at the integrator's request (2026-10-20).

- Done: the universe map in 3D (islands, the four link kinds, skiffs, galaxy sky, pins, the three zooms with
  turns, swoop and cloud wipe), home, the map and the universe screens over it; merged with the first
  integration (T3's buildings and citadel, T1's characters on a close-up); inside §21.3's budget, counted
  honestly (39,735 triangles, about 70 draw calls); `check_all` passed on `a196c75`.
- In progress: nothing; the second integration had not landed, so it is not merged.
- Next: merge the second integration and reconcile its `universe_island.gd` `_building()` with this
  branch's near/far buildings (keep one); then use T2's island for the realm seen close.

## Stopped here (second stop, 19:22 UTC)

- Done since the resume: merged the third integration (one building path: T3's kit up close,
  `BuildingKit.build_map` from afar); each island and link its own node, so a zoomed-in view draws only
  what is on screen; an outer realm seen close is T2's own island toned to the map's night per realm; the
  budget held to the triangles in view at every zoom of every realm (whole universe about 33,500; realm
  zooms up to about 39,100; close-ups 19,800 to 38,700); detailed buildings and close islands built only
  when needed (universe build 454 ms to 172 ms on a desktop CPU); paths as the design's network; level-up
  markers in a close-up; realm headings with icons that swoop the map; blossom petals on the Heart; the
  winds' dome over the Heart. 315 offline client tests pass; the last full `check_all` passed on
  `b841025` (later commits are visual and test-only; `check_all` was not rerun at the stop).
- Still worse than the design: no cast shadows under this renderer (soft painted shade stands in); far
  islands sparser than the design's dense props; the Heart's close-up keeps the map's rock rather than
  T2's meadow (no room in the budget); one character at most in a close-up; the Heart's realm zoom sits
  near the 40,000 ceiling.
- Next: run `check_all` on the last commit; a lighter T2 scatter for the close-up would make room for the
  Heart's T2 meadow and a second character.

## Third session (2026-10-21): the home screen as the design's 01 Universe map

The target is the design's home (`art/design/stills/screens/01-*.png` once the integrator lands it; until
then `docs/analysis/screens-v3/screens-home-realm-shell.md` §1.1 and §2.2) and §21.8's home layout.

- Round 30 (the starting point): home was a Keeper bar across the top, a scrolling grid of 21 menu tiles over
  the bottom half of the world, a large "Play a heist" button, and the camera on the Heart.
  Still: `r30_before_home.png`.
- Round 31: home rebuilt in the design's arrangement (§21.8), the world opening on the whole universe:
  - top left, the Keeper badge (`UniverseBadge`): an emblem in a ring whose gold arc is the way to the next
    level, the level on a gold disc, "Keeper 14" in Marcellus, Renown on a glass chip with the design's gem;
    it opens the menu of every screen (`UniverseMenu`, the design's portrait menu), so all 21 places stay one
    tap away;
  - top right, strain on a glass pill (`UniverseStrain`): the band's colour dot, "74% · Steady"; it opens the
    weaving;
  - a full-width row of the three resources (`UniversePurse`): the design's own icons, the amount held, a line
    along the foot that fills as that resource's producers fill, FULL in words when they are nearly full; an
    amount no slice holds is a dash (the server gives no Aether to the wallet yet; the codex's view has it);
  - side buttons down both edges (`UniverseSide`): leather balls with a bronze rim, the design's icons, a plate
    with the name, red count badges (Defence's unseen raids, Season's "!" when a tier can be claimed);
  - the nearest goal above the tabs (`UniverseGoal`, §14.8): whichever goal the store holds is nearest to done
    (the Keeper's next level, the season track's next tier), said as what is left;
  - five tabs (`UniverseTabs`, `UniverseTab`): Islands (raised on the design's periwinkle disc), Laws, the Heist
    as a larger gold ball in the centre, Crew, Friends; a count badge on Islands for full producers. Heist
    plays a heist as the old button did.
  - the world: the whole universe at once (§23.2), the column drawn tighter (rows at 28 and 54 m, not 33 and
    63), each island's pin its level and name; only a full producer is pinned at that zoom; the fault's pin a
    mark over its realm; pins kept between the side buttons and stepped clear of each other rather than
    dropped; strain is the HUD's, so the Heart carries no strain pin on home.
  Still: `r31_home.png`. Budget at the home camera: 32,162 triangles, 83 draw calls.
- Drawn in code (`UniverseHud`): §21.8's dark glass (#140A16 at 78%), leather, gold, ink outlines #1A0C14,
  light words #F3EEFF, secondary #B8A8D8, Manrope 800 for words and numbers, Lilita One for the level,
  Marcellus for the Keeper's name (the fonts T5 and T7 brought). High contrast makes the glass opaque with
  3-point outlines. Every control is 48 points or more; the badge and the strain pill are marked infrequent
  (`set_meta("frequent", false)`), which §21.1 allows in the top band, and the check in `tests/run.gd` now
  reads (a two-line hook, see below).
- Found: a texture first loaded inside `_draw` draws as a white square under the Compatibility renderer;
  load icons when the control is set up (`UniverseHud.icon`'s note).

### The tab bar, for T9 (UI kit) and T10 (app shell)

Update (round 34): home now uses T9's `KitTabs` (merged from `claude/ui-kit`), its resource pills and its round
actions; what follows is what home asks of whichever bar the shell settles on.

Home draws its own five tabs (`client/world/universe_tabs.gd`) until the app shell's tab bar lands. What home
needs from the shared one, so it can be swapped in with no change to the screen's look:

- five tabs in this order, keys `islands`, `laws`, `heist`, `crew`, `friends`, the Heist in the centre drawn
  larger (a gold ball above the bar), the active tab raised on the periwinkle disc with a larger name;
- `set_badge(key, text)` for a count or a glyph ("" for none), each badge said in words;
- a `chosen(key)` signal; home answers `islands` by showing the whole universe, `heist` by playing a heist
  (as the old "Play a heist" button did), and routes `laws` → `codex`, `crew` → `roster`,
  `friends` → `friends` (`Home.TAB_ROUTES`);
- the bar's height: 52 points plus a 13-point name; its background runs under the home indicator and its
  tabs sit inside the safe area and clear of the corners (84% of the width).

When the shell's bar exists, home stops adding its own (`Home.tabs`) and listens to the shell's.
- Round 32: a night tint (screen-space gradients, not a pass) behind the top HUD and the tabs so their words
  read over any island; the raid notice (`UniverseNotice`, the design's raid banner): "Raided 2 times while
  you were away", See (the defence log) and a dismiss; it stays until dismissed (§21.8) and returns only when
  more raids come. Still: `r32_home_notice.png`.
- Round 33: the cloud wipe (`UniverseWipe`, out of `universe_view.gd`): banks of four puffs each, violet
  underneath and cream on top, edged in ink only on the outside, rolling in row after row from the middle
  out, with a faint night veil; shut, they overlap so the jump is hidden. Reduced motion still cuts.
  Still: `r33_wipe_half_and_shut.png`; shot `tests/shots/universe_wipe.gd` (AMOUNT).
- Round 34, on T9's UI kit (merged): home's tabs are the kit's `KitTabs`, its resource row the kit's resource
  pills (`KitStatus.resource`, inside `UniversePurse`), its side buttons the kit's round actions with cream
  plates (`KitControls.round_action`; the design's own icons from the kit's set); my own drawn tabs and side
  buttons are gone. The Keeper badge, the strain pill and the goal stay home's, as the kit's are not tappable.
  The close-up: every realm, the Heart included, is T2's lighter island (`WorldLook.Detail.LIGHT`); the
  Heart's own tufts and the kit's fine parts give way to its buildings; an outer realm shows two of the
  player's characters, standing in front of the building they work or out on the meadow; the sky keeps its
  scale at every zoom (`sky_scale`), where its dust had swelled into blocks in a close-up.
  Budget (drawn in view, `universe_zoom.gd`): whole universe 32,162 triangles, 83 draw calls; realm zoom
  16,400–38,900; close-ups: the Heart 39,068 (one character), Tidehold 35,700 (two), others 25,000–26,000.
  Stills: `r34_home_on_kit.png`, `r34_zoom2_heart_meadow.png`, `r34_zoom2_tidehold_two.png`.
- Round 35, judged against the design's own home (`art/design/stills/screens/01-universe-map.png` and
  `01-universe-map-raid.png`, landed at 00:58). The three worst differences were: the world squeezed into the
  top half by the notice, Collect and the goal stacked over it; dark island labels where the design's are
  parchment; the goal a heavy two-line card. Fixed:
  - the universe in the design's 2-3-2 (`UniverseLayout.SLOTS`: two above the Heart, one either side, two
    below), framed to the islands' rims and down to the tabs, so it fills the screen's width as the design's
    does; the goal, Collect and the raid notice float over its foot, as the design's Collect and raid banner;
  - each realm's label the design's parchment plate edged in ink: its icon, its name in Marcellus in brown
    ink, its level on a dark disc, floating over the island's far rim at the whole-universe zoom;
  - pins keep clear of the side buttons' own rectangles and inside the screen's edges;
  - the goal one line on a glass pill beside Collect;
  - the side buttons high on each edge beside the top row, as the design places them (marked infrequent, so
    §21.1's thumb zone does not bind them; they keep 48 points and stay out of the corners);
  - the shot's sample universe a mid-game one in the design's order (Skyfield, Crystalline, Tidehold,
    Verdant, Emberreach, Lantern Vale), five or six buildings a realm, linked between neighbours as the
    design links them.
  Budget at the home camera: 35,895 triangles, 83 draw calls.
  Stills: `r35_compare_01_universe_map.png`, `r35_compare_01_raid.png` (ours left, the design right, grayscale
  thumbnails beneath).
- Round 36: the citadel drawn 1.85× over the whole universe (1.35× at the realm zooms), so the Heart reads
  first from afar as the design's home draws it; the Heart's label floats over its spire.

### Hooks in other tracks' files (third session)

- `client/tests/run.gd`: the thumb-zone check skips a control marked `set_meta("frequent", false)` (§21.1:
  the thumb zone binds frequently used controls); the 48-point, safe-area and corner rules still hold.
- `client/tests/keeper_tests.gd`: home's Keeper check reads the badge (`UniverseBadge`) instead of the old
  label.
- `client/data/repositories/home_repository.gd`: `collect(realm, kind)` (`POST /v1/home/collect`, 3 lines).
- `client/features/roster/roster_controller.gd`: `collect_all()`, every producer that holds something
  collected and the wallet asked afresh (about 20 lines; tested in `universe_view_tests.gd`).
- `client/i18n/strings.csv`: home's rows (`HOME_SIDE_*`, `HOME_STRAIN_SPOKEN`, `HOME_PURSE*`, `HOME_RES_*`,
  `HOME_BADGE_SPOKEN`, `HOME_MENU*`, `HOME_GOAL_*`, `HOME_RAIDED*`, `HOME_COLLECT*`, `HOME_UNKNOWN`).

### For T9 and T10

- `KitTabs`' chosen tab's name has a 1.5-pixel outline (`UI.px(1.5)`, 1.33 points), under §21.8's 1.5 points,
  so the contrast check measures it against the periwinkle and finds 4.49:1; home widens it after building
  the bar. A wider outline in `KitTabs.choose` would fix it everywhere.
- The design's tab bar runs edge to edge with the chosen tab a large raised tile; `KitTabs` is a boxed bar.

## Fourth session (2026-10-26, wave four): home fits every phone, then rounds against the design

Merged `claude/videogame-project-analysis-ewkkk2` (1e8619b) and `claude/ui-kit` (502b5a0). The only conflict
was `client/i18n/strings.csv` (both sides kept; the kit rows the two merges both brought, `KIT_TAB_*`,
`KIT_BACK`, `KIT_CLOSE`, `KIT_FULL`, `KIT_TAB_BADGE`, kept once).

### Why the merged home was cut off at the right, and why the tests missed it

Every container in home's column grows to its widest child's minimum, so one row too wide pushes the whole
column (and every row in it) past the screen's right edge. The resource row was that row: three kit pills,
each as wide as "FULL 142,050", needed 1,096 px of a 984-px column. The client's width checks mount home with
an empty store, where every amount is a dash, so nothing was ever wide.

Now (`universe_view_tests.gd`, "home fits the phone ..."): home is filled with the widest amounts (seven
figures, every producer full, Keeper 99, Renown 99,999; `UniverseSample.fill(store, ..., most = true)`) in its
own services, at 9:19.5 and 9:16, text at 100%, 150% and 200%, in all six catalogue columns; every visible
control must lie inside the screen and the frame must be portrait (a headless window needs a frame after
`root.size` before it takes; the first try measured a square window and passed for nothing).

What changed so it fits:
- the resource row (`UniversePurse`) is a flow: where the three pills will not sit on one line with Full in
  words, the word gives way first (the line still shows full; it is still said), then the row wraps;
- amounts past 10,000 are shown as the designs show them, "142.0k", "9.9M" (`UniverseHud.compact`, cut
  down, never rounded up; `HOME_AMOUNT_THOUSANDS`/`_MILLIONS`); said in full;
- the top row is a flow: strain stacks its number over the band where one line will not fit beside the
  badge, and takes a line of its own where even that will not (`UniverseStrain.fit`); it answers taps only
  on its pill (`_has_point`), not the row's spare width; its padding grows with the dot, which large text
  grows (it had drawn words past its own right edge);
- the Keeper badge moves its name and Renown chip clear of the level disc, which large text grows over them;
- the raid notice, at 150% and more, gives its words the card's width with the mark, See and close beneath;
- the side buttons give way when the column has no height for them (200% text on a 9:16 phone): every
  place they lead to is on the badge's menu, and the raids are on the notice;
- tab names that large text would cut short ("ISLA", "GESET") show as icons alone, the chosen tab keeping
  its name if it fits; each tab is still named aloud. A workaround for `KitTabs` in `home.gd` (see T9 below).

Shot `tests/shots/universe_home.gd` now takes LOCALE, CONTRAST, TALL (960 for 9:16) and MOST, and its
settings survive home's `Settings.restore()`.

### Hook in another track's file (fourth session)

- `client/tests/weaving_tests.gd` (4 lines): "Weaving offers the starting laws ..." failed on every branch,
  main included: today's era is High Tide, under which the simulation prices Slow rivers at nothing
  (`sim/src/stability.rs`), the server recommends it first, and the test demanded a price above 0. The test
  now accepts a free first law only when its points are 0 as well; the rest of the check is unchanged.

### For T9

- `KitTabs`: at 150% and 200% text the five names do not fit and are cut to fragments (`clip_text` with an
  ellipsis that rarely shows). Home hides the other tabs' names when any would be cut; the kit doing so
  (or a two-line name) would fix every screen with tabs.
- `KitStatus.resource`: the pill's padding is wide enough that "FULL 142.0k" does not fit a third of the
  phone at 100% text, where the design fits "FULL 61.0k"; home drops the word rather than run off.
- `tools/completion.py` (1 line, fourth session): the kit lengthened the contrast test's name ("... and every
  material's words on the stops they sit on included ..."); the proof still named the old one, so
  check_all failed on the kit's own branch and every branch carrying it. The proof now names the test as it is.
- Round 37 (after the green push at 00:12, f8e4918): the resource row in the designs' short amounts
  ("142.0k"), side buttons at the 48-point minimum (from 52), and the tab-name fit measured against each
  name's own width (it had hidden the other tabs' names at 100%: "FRIENDS" is 164 px in 174, and a margin of
  my own had called it cut). Still: `r37_fit_compare_01.png` (design, ours, design raid, ours raid, ours in
  German at 200% on a 9:16 phone).
- Round 38: the three worst were FULL dropped from the resource row at 100% (the kit pill's right padding: 995
  of 984 px), realm labels under the side buttons at 150% (in Portuguese "TEMPORADA" and "DEFESA" cover
  Skyfield and Crystalline), and the boxed tab bar (T9's). Fixed the first two: the purse's pills take 6
  points at the right, not 10, and 4 between, so "FULL 142.0k" sits in its third; a realm label keeps to the
  gap between the side buttons on its row, or steps below them, and hides where there is no free place
  (`UniversePins._place`); the side buttons' rectangles are re-read whenever they move (they had been read
  as the column sorted, before the buttons inside it had theirs).
- Round 39, motion (§21.8: easing out, no overshoot): the swoop eases out (cubic) where it had eased in and
  out; the cloud wipe is held fully shut for the middle 40% of a swoop between realms (it had been shut
  only at the instant of the jump, where a frame either side could show gaps between the banks and the
  world changing behind them). Reduced motion still cuts.

## Stopped here (fourth session, 03:50 UTC)

- Done: merged main (1e8619b) and the UI kit (502b5a0); home fits every phone shape, text size and language,
  with a test that fills home with the widest amounts and checks every control lies inside the screen
  (it would have caught the clipped right edge); rounds 37–39 against the design (compact amounts, FULL
  in the row, 48-point side buttons, realm labels clear of the side buttons, ease-out swoop, wipe held
  shut through the jump). Two one-line fixes outside my files that every branch needed (weaving test's
  High Tide date, completion's contrast proof name). Full `check_all` passed on cd3ac6e.
- Still worse than the design: the tab bar is boxed, not edge to edge (T9's `KitTabs`), and its names
  truncate at large text (home hides them); the side balls are 48 points where the design's are about 36
  (the kit draws the disc at the full hit area); Collect shows no amount; at 150–200% text some realm
  labels hide for want of room; the strain pill's high-contrast outline is not drawn.
- Next: re-measure triangles at every zoom after this wave's merge; a kit hook for a smaller disc over a
  48-point hit area; Collect with its compact amount; a still of the swoop's frames.
- Container restarts this session lost two check runs; the environment needed `rustup target add
  wasm32-unknown-unknown`, `pip install gdtoolkit==4.*` and `pip install playwright==1.63.0` (to match the
  pre-installed Chromium) before `check_all` could run.

## Fifth session (2026-10-27, wave five): home past the design

Merged `claude/videogame-project-analysis-ewkkk2` (d2343591) cleanly.

### Rounds

- Round 40, the foot and the edges. Three worst: Collect a big "Collect all" button beside a goal pill where
  the design has one gold "COLLECT 3.4k" pill; side balls at the kit's full 48-point disc with wide plates;
  the raid card a three-line box ("Raided 2 times while you were away", See, ×) where the design has one
  bold line over a rose line with a gold TRACE. Fixed: `UniverseCollect` (what every producer holds
  together, short from 1,000 on, `UniverseHud.compact(n, 1000)`; the goal shows only while nothing waits);
  `UniverseSide` (a 42-point leather ball drawn inside the 48-point hit area, the name on a small plate over
  its foot, the badge on its shoulder); `UniverseNotice` restyled (heist mark on a red disc, "Raided 2
  times" over "See how your defence held", gold SEE, a rose ×; one line each, cut with an ellipsis and
  said whole; wrapped at 150% text and more). New strings `HOME_COLLECT_AMOUNT`, `HOME_RAID_TITLE(_ONE)`,
  `HOME_RAID_LINE`.
- Round 41, the world's words. Three worst: realm labels a third larger than the design's; "+320" ready
  pins and the "! 2" raid pin over the whole universe, which the design leaves to Collect and the banner;
  Crystalline's label pushed under Skyfield's. Fixed the first two: labels a point smaller with tighter
  plates, and home passes `quiet` so ready amounts and raids are pinned only from zoom 1. The third is
  better (labels narrower) but not gone.
- Round 42, life (§21.8 motion, §20.8 reduced motion). Lights walk every open link (lanterns over bridges,
  glints down chutes) in the sparks layer the skiffs already use, no new draw call; the raid banner and
  Collect arrive by `Motion.pop` (grow from 92% and fade, easing out); under reduced motion the skiffs moor
  part way along their links with no wake, the links' lights stand still, the comets go and the debris
  stops (they had all kept moving).
- Round 43, the budget, measured honestly. The engine's own count of the home frame
  (`RENDERING_INFO_TOTAL_DRAW_CALLS_IN_FRAME`, every pass, 2D included) was 454: §21.3 says under 150 on
  screen. My own counter (meshes plus outline passes) had said 83, and the first side balls had made it
  worse (39 calls each: fourteen anti-aliased circles a ball). Cut to 142:
  - `UniverseHud.ball` bakes each ball (size, ramp, rim, ink, drop) into a texture once: one draw call;
    `baked_box`/`baked_plate`/`gold_pill` bake rounded plates and the gold pill into nine-slice boxes;
    the badge, strain pill, side buttons, Collect and raid card use them;
  - the realm labels' plates, discs, icons and levels are drawn by `UniversePins._draw` in one run of each
    kind across all seven labels (only the names stay `Label`s), 38 calls to 14;
  - over the whole universe `UniverseWhole` draws every island's rock, dressing, shades and far buildings
    and every fixed link as five merged meshes (one per material), the per-island meshes hidden: the 3D
    from 84 calls to 40, the same triangles and the same picture (pixel difference 0.8 of 255 on average);
  - no sun shadow at zoom 0, where the islands are too small to show one; it returns from zoom 1.

### Budgets (§21.3), measured 2026-10-27 on this build, 540 × 1170 window

Home, engine count of the whole frame: 142 draw calls (148 with the raid banner; 133 at 200% text; 137 in
German at 150%; 140 at 200% and high contrast on a 9:16 phone). Of those the 3D is 40 and the kit's tab
bar 28, the resource row 19.

The map alone (`tests/shots/universe_zoom.gd`, which now prints the engine's main and shadow passes, and
with PROBE=<file> every mesh on show):

| view | triangles drawn | engine main pass | note |
|---|---:|---:|---|
| whole universe (zoom 0) | 34,647 | merged: 40 calls with home | no shadow pass |
| the Heart, zoom 1 | 33,010 | 81 calls, 53,709 primitives | shadow 15,556 primitives |
| the Heart, close-up | 29,493 | 54 calls | |
| an outer realm, zoom 1 | 23,812 | 54 calls | |
| an outer realm, close-up | 18,024–25,229 | 50–54 calls | |

Primitives exceed triangles because the ink outline is a second pass over the outlined meshes; triangles
are counted once, as §21.3 counts them. Every zoom is inside 25,000–40,000 or under it.

### Hooks and asks

- For T9 (asked here; no channel reached them this session): a kit round action whose disc is drawn
  smaller than its 48-point hit area (`KitControls.round_action(..., disc_points)`), and the kit's own
  pills baked or batched: the tab bar is 28 draw calls of home's 150 and the three resource pills 19.
- Round 44: realm labels slipped under the side plates at 200% text (the last step that keeps labels off
  each other moved them back onto the buttons) and under Collect. Labels now never step onto the screen's
  own controls, and a control across the middle (Collect, the goal, the raid card) lifts a label above it.
- Round 45: the resource row as the design's: 30-point dark pills with a faint gold rim, the icon on a night
  disc, the amount at the right, FULL in gold just before it, a 3-point line in the resource's colour along
  the foot (easing to its share). Drawn by `UniversePurse._draw` in one run of each kind: 19 calls to 9.
- Round 46: the Keeper badge as the design's: the level on a gold pill across the ring's foot (it was a
  ball at the side, which large text pushed into the name), Renown on a night chip edged in rose.
  Stills: `docs/art/shots/universe/w5_r46_home_vs_design.png` (design, ours, design raid, ours raid) and
  `w5_r46_gray_thumbs.png`. Home now 132 draw calls (138 with the raid card).
- Round 47, the locked realm. The design hangs the next realm as a whole island, dimmed, under a dark pill
  with a lock, "Opens at Keeper 28"; ours was a faint ring of mist under "+ Lantern Vale". Now a realm
  still to open is drawn whole (rock, meadow, trees; no buildings), its palette greyed and dimmed toward
  the night, with its mist ring; its pin is the design's lock pill when the server says it is blocked by
  the Keeper level (`HOME_OPENS_KEEPER`) or the Spire (`UNIVERSE_NEEDS_SPIRE`), and "+ name" when it can
  be bought, placed over the island's far rim like the realm labels. The shot sample's next realm is now
  blocked at Keeper 28, as the design shows it.
- Round 48, the realm zooms' budget. Home at the Heart's zoom 1 was 180 draw calls. Only the realm the
  camera is on casts the sun's shadow; the skiffs are one instance layer (they share the first one's sail
  stripe); the links' kind marks and the four side buttons are drawn in batched runs (`UniversePins
  ._draw_links`, `UniverseSide.draw_all` on a layer over the column, redrawn when the buttons move).
  Home now: zoom 0 115 calls (raid card 120, 200% text on 9:16 99); the Heart 146 at zoom 1 and 136
  close; an outer realm 134–136.

## Stopped here (fifth session, 22:55 UTC)

- Done and pushed green (76628df, full `check_all` passed): the design's "COLLECT 3.4k" pill; 42-point
  side balls inside 48-point hit areas; the raid banner as the design's; realm labels as the design's and
  clear of every control at 100–200% text; the slim resource row; the badge's gold level pill; the locked
  realm; lights on the links and reduced-motion forms for everything that flies; home under 150 draw calls
  at every zoom, measured with the engine's own count (it had been 454).
- Still worse than the design: outer islands sparse (buildings clustered in the middle, small from afar;
  the far building look is T3's `KitMap`, the spots and scale mine: `RINGS`, `_far_building`); the tab
  bar boxed and 28 draw calls (T9's `KitTabs`); the defence ball shows its name where the design shows the
  shield's time (no client data for it); the raid card says "Raided 2 times" where the design names the
  raider, realm and what was kept (the badge route gives only a count; the log, which has it, marks raids
  seen when read).
- Next: spread outer buildings to the 0.5 and 0.72 rings and draw them larger from afar; the universe and
  map screens in the kit's style; a still of the banner's arrival (shots start too late to catch it).
- `universe_view.gd` is at 997 lines: move code out (to `UniverseWhole` or a new file) before adding any.
- The session paused for about three hours (20:15–22:50 UTC); nothing was lost.
