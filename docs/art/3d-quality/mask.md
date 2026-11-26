# The mask tool

The mask tool measures a still. It draws the frame again as flat masks,
then computes the plan's qualities Q1 to Q6, Q11 and Q12 from them
([`plan.md`](plan.md), section 3). It was built by 3D0-M2-mask-tool and is
checked here against the plan's own measurements and, by hand, on ten
stills.

## One command

```
python3 tools/render/mask.py client/tests/shots/screen_heist.gd OUTDIR
```

This runs any shot script the way `tools/render/shoot.sh` does: Godot's
Compatibility renderer under Xvfb, at the phone's 1080 × 2340. The shot's
own settings go in the environment as for `shoot.sh` (`MOMENT`, `ZOOM`,
`HOUR`, `HIDE`, ...). The mask pass replaces the shot's `quit()`, so it
draws the same frame the shot drew. `measure.py` then writes
`OUTDIR/measure.json` and prints a summary.

- `TILES=11` puts the camera between the zoom levels, as many tiles across
  as given (the plan's 11-tile trial). `ZOOM=1` is 15 tiles, `ZOOM=2` is 7.
- `python3 tools/render/mask.py SHOT OUTDIR --no-render` measures masks
  already in `OUTDIR` again.
- `python3 tools/render/measure.py OUTDIR` does the same, and
  `python3 tools/render/measure.py --self-test` checks the measures on
  drawn test masks.
- `python3 tools/render/mask_matrix.py OUTDIR --jobs 3` renders the plan's
  eight-moment matrix (seven moments at 15, 11 and 7 tiles) and compares
  each still with the plan's table. It writes `OUTDIR/matrix.md`.

A still takes about two minutes on this machine; the matrix about
twenty-five with three jobs.

## The passes

`tools/render/mask_pass.gd` draws, into `OUTDIR`:

| File | What it holds |
|---|---|
| `beauty.png` | The frame as the shot left it |
| `ui_a.png`, `ui_b.png` | The frame with the 3D world swapped for flat red, then flat green. Where the two agree, the interface covers the world; where they differ, the world shows through, in proportion to the difference |
| `world.png` | The 3D world alone: no interface, no 2D markers |
| `behind.png` | The same without the figures: the ground behind them |
| `markers.png` | The 2D markers alone (speech bubbles, labels, icons) on a clear background |
| `marks3d.png` | The 3D markers alone (rings, sight edge, overlay, effects) on black |
| `id.png` | Every 3D thing in a flat colour that codes what it is |
| `solo_c<i>.png`, `solo_g<i>.png`, `solo_h<i>.png` | Each figure (crew, guard, character) alone, its whole outline even where something hides it |
| `mask.json` | The frame, each figure's projected bounds, feet, head and span, the vault, the exit, the camera and the shot's settings |

**The id code.** Red and green carry the class (red `class // 4`, green
`class % 4`, each step 64 from 32). Blue carries the index: a figure's
number, or the tile's kind on the ground (step 28 from 14). The colours are
written as they are, with no sRGB step, so each arrives within a few levels
of its code; `measure.py` reads each channel in its band of 64 or 28. A
pixel whose channels are all under 16 is the background.

**Nothing but class colours.** `measure.py` refuses an `id.png` that
holds any pixel more than 5 levels under or 2 over its code in some
channel (`ID_BELOW`, `ID_ABOVE`, `STRAY_MAX = 0`), with "pixels match no
class colour; something 2D was drawn over the id pass". The renderer
writes the lowest codes a little dark (14 as 9, 32 as 30, 42 as 41; 70
and up exact), hence the wider band below. Anything 2D left over the id
pass (a label, a pin, a wash, a screen's background) mixes colours that
fall outside the bands, so it stops the measure instead of decoding as
wrong classes. The self-test checks the bands and a still with a
universe pin drawn over its id pass.

| Class | Red, green | | Class | Red, green |
|---|---|---|---|---|
| 0 background (black) | all under 16 | | 8 path | 160, 32 |
| 1 crew | 32, 96 | | 9 other ground | 160, 96 |
| 2 guard | 32, 160 | | 10 cliff face | 160, 160 |
| 3 vault | 32, 224 | | 11 water | 160, 224 |
| 4 exit | 96, 32 | | 12 decoration | 224, 32 |
| 5 marker (3D) | 96, 96 | | 13 building | 224, 96 |
| 6 crew shadow | 96, 160 | | 14 piece (walls, furniture) | 224, 160 |
| 7 walkable ground | 96, 224 | | 15 guard shadow | 224, 224 |

Ground tiles carry their kind in blue: outside, open, water, building,
blocked, cover, vault, gravel (0 to 7). Cover (fog, tall grass, flowers,
scree) is drawn as decoration on walkable ground.

**The figures keep their ink.** A figure's outline is an inverted hull in
its material's next pass (`client/world/outline.gdshader`,
`creature_outline.gdshader`). The id pass keeps it, drawn in the figure's
own code, so the masks hold the outline the player sees. Without it the
crew read about 3 points short.

## The measures

Sizes are in points: a pixel times 360 over the frame's width (one point
is three pixels on the 1080-wide phone).

A pixel is **under the interface** when less than half of the world shows
through it (`COVERED = 0.5`, from `ui_a` and `ui_b`).

| Q | What the tool reports | How |
|---|---|---|
| Q1 | `band`: the longest run of rows where under a fifth of each row is covered (`BAND_ROW = 0.20`), as a share of the height. `strict_band`: the same with under a tenth covered (`STRICT_ROW = 0.10`), counting the 2D markers as interface. `panels_share`: the covered share of all pixels | The plan's 60% target is for `band` (below) |
| Q2 | Each figure's height in points; the least crew member and the least guard | Below |
| Q3 | Each figure's share of visible pixels within 18 gray levels (`GRAY`, Rec. 601 luma) of the ground behind it | `world.png` against `behind.png`, on the figure's visible pixels in `id.png` |
| Q4 | Each figure's head (the top 30% of its outline, `HEAD`) and each marker: the share not hidden by the interface or by another figure | Pass when all are at least 80% seen (`SEEN`). Below |
| Q5 | Decoration's share of the walkable ground; the paths, the buildings and how many buildings touch one path | `id.png` classes, uncovered pixels |
| Q6 | Markers near each figure, the vault and the exit; how much of each object its markers cover | 2D and 3D markers grouped and given to the nearest object |
| Q11 | The chosen crew member, the nearest guard (to the chosen one, in the world), every guard (`guards`) and the vault: clear, cut, under panel or off. Whether the island touches the frame's edges; the tallest figure's share of the height | Below |
| Q12 | Each figure's shadow pixels; the ground's brightness just below each building against the ground's mean; cliff faces against tops | `id.png` shadow classes and `world.png` |

**Q1: which band.** The plan names two ways to measure clear world: the band
between the panels (39%) and the strict stretch with under 10% of each row
covered by anything, markers included (16.6%). The tool reports both, and
**Q1's 60% target applies to `band`**, the band between the panels. The
strict reading depends on where the moment's speech bubbles and labels
fall, so it moves from still to still while the panels do not.

**Q2: the plan's way.** The plan measured the figures "by projecting each
figure's bounds". Its numbers match one reading only: the figure's bounds
height (feet to top in the world) stood along the camera's up direction at
its feet, and projected (`span` in `mask.json`). The other readings miss:

| Reading, sneak at 15 tiles | Crew (pt) | Guards (pt) | Plan |
|---|---|---|---|
| Bounds height along the camera's up (`points`) | 24.2–28.2 | 39.0–39.6 | crew 24–28, guard 38 |
| Drawn silhouette with the ink (`silhouette_points`) | 24.0–27.7 | 31.7–32.0 | |
| Projected bounds box (`bounds_points`) | 34.5–47.8 | 47.3–48.0 | |
| Feet to top straight up in the world | 15–18 | | |

The drawn silhouette is what the eye sees, and is kept beside `points`;
the box runs tall because its depth adds to its height under the camera's
pitch, and the world's vertical is shortened by the same pitch.

**Q4: pile-ups, not framing.** A marker that is wholly under a panel is
listed under `under_panel` and not counted: that is a framing matter (Q1,
Q11), not a pile-up. A full-width hairline (a panel's edge in the marker
pass) is not a marker.

**Q11: the ratings.** "Clear" is fully on the frame and less than half
under the interface; "cut" is partly off the frame (under 90% of the
whole outline on it); "under panel" is half or more of what is on the
frame under the interface; "off" is under 5% on the frame. A figure's
whole outline is its solo pass; the vault's is its own pixels in
`id.png`, with its projected bounds telling how much the frame cuts off.

**A count over nothing is not a measure.** Where Q3, Q4, Q5 or Q12 would
count over no figures, heads, markers or buildings, `measure.json` holds
`null` for the count (and for Q4's `pass`) and a reason (`figures_why`,
`buildings_why`, Q4's `why`: "no figure in frame", "no building in
frame", "no building with ground at its foot in frame", "no head or
marker in frame"), and the summary prints the reason, never "0 of 0" or
a pass over nothing. Q12's `cliffs_darker` is `null` where the frame
holds no cliff face or no top. The self-test's realm still (no building)
and a heist still with no figure (as `screen_landing`) check it.

## Tolerances

| Check | Plan | Tolerance |
|---|---|---|
| Q1 band | 39% (rows 572 to 1487 of 2340) | ±1 point of percentage |
| Q1 panels | 37.5% of the pixels | ±1 point of percentage |
| Q2 crew at 15 tiles | 23 to 28 points | each end within 8% of the plan's range |
| Q2 heights in the matrix | the table's ranges | each end within 8% of the plan's range |
| Q11 ratings in the matrix | the table's words | the same word |
| A screen shot's figure heights, run against run | the same shot | each within 8% |

8% is two points at 28 points: the plan's ranges come from bounds that
include a figure's idle pose and outline, which move by about that much
between frames. A screen shot is not pinned to one frame of the idle
either: two runs of `screen_defences` (`TAB=0`) read its guard at 22.1
and 20.4 points, so the results table below is good to 8% per height,
and a rating near a threshold (the island's edges, `THIRD`) can change
word between runs.

## Against the plan

Rendered with `python3 tools/render/mask_matrix.py OUTDIR --jobs 3` on
25 November 2026 from main at the branch's base (21 stills, about 25
minutes).

**Q1.** Every still of start, sneak, vault, alarm and escape reads `band`
39.1% (rows 572 to 1486; the plan: 39%, rows 572 to 1487) and
`panels_share` 37.24% (the plan: 37.5%). Both within ±1 point. Entry and
hold add a panel the others lack ("In the Heart" at entry, the Crouch,
Walk, Run bar at hold), so they read 22.7% and 21.2% band, 41.8% and
44.5% panels. `strict_band` at sneak, 15 tiles, is 19.1% (the plan:
16.6%), see "Q1: which band".

**Q2 at 15 tiles.** The crew read 24.2 to 28.6 points across the seven
moments (the plan: 23 to 28; within 8%), the guards 38.4 to 39.7 (the
plan: 38).

**The matrix.** Crew heights use `points`, except a crew member lying
down (bounds under 60% of the tallest crew member's: the knocked-down
Scout at alarm), which is measured by its silhouette, since that is what
the plan's low end at alarm matches (22.7, 30.3, 46.3 against 23, 31,
49).

| Moment | Tiles | Crew (pt) | Plan | Guards (pt) | Guard 0 / plan | Nearest (world) | Vault / plan |
|---|---|---|---|---|---|---|---|
| start | 15 | 24.2–28.6 | 24–28 | 39.7, 39.7 | clear / clear | g1: clear | under panel / clear ✗ |
| start | 11 | 33.0–39.2 | 33–38 | 54.2, 54.2 | cut / cut | g1: clear | under panel / under panel |
| start | 7 | 51.8–62.1 | 53–60 | 85.1 | off / off | g1: clear | under panel / under panel |
| sneak | 15 | 24.2–28.2 | 24–28 | 39.0, 39.6 | clear / clear | g1: clear | clear / clear |
| sneak | 11 | 33.0–38.4 | 33–38 | 52.8, 54.0 | clear / cut ✗ | g1: clear | clear / clear |
| sneak | 7 | 51.8–60.3 | 53–60 | 84.6 | off / off | g1: clear | under panel / clear ✗ |
| vault | 15 | 24.2–28.1 | 24–27 | 38.4, 38.4 | clear / clear | g1: clear | clear / clear |
| vault | 11 | 33.0–38.1 | 33–38 | 51.7, 51.7 | clear / clear | g1: clear | clear / clear |
| vault | 7 | 51.8–59.6 | 53–59 | 79.1, 79.1 | cut / cut | g1: clear | clear / clear |
| alarm | 15 | 22.7–28.5 (c0 lying) | 23–28 | 39.4, 39.4 | clear / clear | g0: clear | under panel / clear ✗ |
| alarm | 11 | 30.3–39.0 (c0 lying) | 31–38 | 53.6, 53.6 | clear / clear | g0: clear | under panel / clear ✗ |
| alarm | 7 | 46.3–46.3 (c0 lying) | 49–61 | 83.6, 83.6 | clear / clear | g0: clear | under panel / under panel |
| escape | 15 | 24.4–28.5 | 25–28 | 39.4, 39.4 | cut / cut | g1: clear | under panel / clear ✗ |
| escape | 11 | 33.3–39.0 | 34–38 | 53.5 | off / off | g1: clear | under panel / clear ✗ |
| escape | 7 | 52.4–61.6 | 53–60 | 83.6 | off / off | g1: cut | cut / off ✗ |
| entry | 15 | 24.2–28.2 | 24–27 | 39.4, 39.4 | cut / cut | g1: clear | under panel / clear ✗ |
| entry | 11 | 33.0–38.4 | 33–37 | 53.6 | off / off | g1: clear | under panel / clear ✗ |
| entry | 7 | 51.8–60.3 | 52–59 | 83.6 | off / off | g1: cut | cut / off ✗ |
| hold | 15 | 24.2–28.2 | 24–28 | 39.0, 39.6 | under panel / clear ✗ | g1: clear | clear / clear |
| hold | 11 | 33.0–38.4 | 33–38 | 52.8, 54.0 | under panel / cut ✗ | g1: clear | clear / clear |
| hold | 7 | 51.8–60.3 | 53–60 | 84.6 | off / off | g1: clear | under panel / clear ✗ |

Crew heights within tolerance: 21 of 21; guard 0 as the plan's nearest guard: 18 of 21; vault as the plan: 10 of 21.

- **Crew heights: 21 of 21** within tolerance. The smallest standing
  crew member at 11 tiles reads 33.0 points in every moment (the plan:
  33, 33, 33, 31, 34, 33, 33; its 31 at alarm is the lying Scout, 30.3
  here).
- **The plan's "nearest guard" is guard 0: 18 of 21.** The plan's column
  follows guard 0 in every moment, and its "second guard, in view at 15
  and 11 tiles in every moment" is guard 1. The guard nearest the chosen
  crew member in the world is guard 1 in 18 stills, and it is clear in 19
  of 21 (column "Nearest (world)"), so that reading would not give the
  plan's numbers. The matrix compares the plan's word with guard 0, and
  Q11 reports every guard (`Q11.guards`). The three misses: at hold, 15
  and 11 tiles, guard 0 stands under the Crouch, Walk, Run bar, which
  the plan's hold apparently lacked (its hold row and primitive count
  equal its sneak row); at sneak, 11 tiles, guard 0 is wholly on the
  frame by 2 pixels where the plan reads it cut.
- **The vault: 10 of 21.** Every miss but two is "under panel" where the
  plan says clear. The vault's own pixels sit 67% to 100% under the
  "Walk / Tap crew, then ground" bar in those stills. The plan's own
  stills show the same: in `stills/m-start-15.jpg` and
  `stills/m-escape-15.jpg` the vault's dome is under the bar and only its
  "VAULT" tag and the top of the dome show above it. So the plan's
  "clear" for the vault is not borne out by its stills, and the tool's
  word is kept. It looks as if the plan judged the vault by a point at
  its top (its tag) rather than by its pixels. At escape and entry, 7
  tiles, the vault's edge is on the frame (cut) where the plan reads off:
  a few hundred pixels in the frame's right edge.

## Ten stills by hand

Ten stills were checked by eye on contact sheets: the beauty pass with
the band's rows drawn across it, each figure's `span` drawn as two lines
at its feet and head, and a crop of each figure.

| Still | Crew height | Band | Guards | Vault | What the eye found |
|---|---|---|---|---|---|
| start, 15 | 24.2–28.6 | 572–1486 | g0 clear, g1 clear | under panel | Span lines meet each crew member's feet and the top of the head, ink included. Band lines sit on the top panels' lower edge and the order bar's top edge. Vault dome under the order bar, tag above it |
| start, 11 | 33.0–39.2 | 572–1486 | g0 cut, g1 clear | under panel | g0 at the right edge, partly off. Only the vault's tag shows above the bar |
| start, 7 | 51.8–62.1 | 572–1486 | g0 off, g1 clear | under panel | g0 not in the frame; the vault behind the order bar |
| sneak, 15 | 24.2–28.2 | 572–1486 | g0 clear, g1 clear | clear | All five figures in the open; the vault fully above the bar |
| vault, 11 | 33.0–38.1 | 572–1486 | g0 clear, g1 clear | clear | The crew at the vault, all above the bar; g1 at the house, g0 by the hedge |
| alarm, 15 | 22.7–28.5 | 572–1486 | g0 clear, g1 clear | under panel | The Scout lies knocked down (stars over it): its standing span (13.9) is short, its silhouette (22.7) right. The vault's dome under the bar |
| alarm, 7 | 46.3 | 572–1486 | g0 clear, g1 clear | under panel | Only the lying Scout is in the frame; the Breaker and the Carrier are off it, as the plan says. Both guards fully in view |
| escape, 15 | 24.4–28.5 | 572–1486 | g0 cut, g1 clear | under panel | The same frame as the plan's `m-escape-15.jpg`: the crew by the boat, g0 at the right edge, the vault's dome under the bar |
| entry, 11 | 33.0–38.4 | 572–1101* | g0 off, g1 clear | under panel | The three crew stand on one tile (the Scout in front hides the others). The "In the Heart" banner ends the band at row 1101 |
| hold, 15 | 24.2–28.2 | 572–1066* | g0 under panel, g1 clear | clear | The Crouch, Walk, Run bar ends the band at row 1066 and covers g0; the vault is clear between that bar and the order bar |

\* The band ends early at entry and hold, at the extra panel's top
edge; the other eight read the same rows.

In all ten, the tool's rating of each guard and of the vault agreed with
the eye. The span lines matched each standing figure's feet and head
within about a point; `bounds_points` was visibly too tall, and
`silhouette_points` matched a standing guard's body but left out its
raised head under the camera's pitch, as the Q2 readings table says.

## Each kind of screen

The pass finds the screen's 3D view by what is drawn, not by the shot's
name: the largest visible `WorldView` (a heist, or a realm screen's
`StageView`), else the largest visible `StageHero` (a character stage),
else the largest visible `UniverseView`. A view that is built but hidden
does not count. `mask.json` says which it found in `"screen"`, and
`measure.py` answers each quality that the kind of screen can show,
and says why for the others (`WHY` in `measure.py`; `measure.json` holds
`"applies": false` and the reason).

| Kind | Shots (the baseline's "mask limit" rows) | Q1 | Q2 | Q3 | Q4 | Q5 | Q6 | Q11 | Q12 |
|---|---|---|---|---|---|---|---|---|---|
| `heist` | `screen_heist`, `screen_laws`, `screen_replay`, `screen_result`, `screen_landing` (the heist before the crew land), the matrix | yes | yes | yes | yes | yes | yes | chosen crew, nearest guard, vault | figures, buildings, cliffs |
| `realm` | `screen_realm`, `screen_builder`, `screen_curation`, `screen_defences` (`TAB=0`), `screen_planner`, `screen_scout` | yes | when figures are drawn | when figures are drawn | when figures are drawn | yes | when figures are drawn | the island | buildings, cliffs; figures when drawn |
| `character` | `screen_character`, `screen_first`, `screen_forms`, `screen_hatch`, `screen_roster`, `screen_sage_hall` | yes | yes | yes | yes | no | no | each character | the character's shadow disc |
| `universe` | `universe_home`, `universe_zoom`, `universe_map`, `universe_screen` | yes | no | no | no | no | no | the focused island (the Heart where none is focused) | no |
| `none` | `screen_observatory` | yes | no | no | no | no | no | no | no |

Why each "no" and "when":

- **Realm, Q2 to Q4 and Q6.** A realm screen hides the heist's crew and
  guards (`RealmScreen` sets `actors.visible = false`), so there are no
  figures for heights, contrast, pile-ups or the markers on them. Where a
  realm screen does draw figures (the guards on their posts in
  `screen_builder` and `screen_curation`, the crew and guards of
  `screen_defences`), the pass lists them and these qualities are measured
  as on a heist. `screen_realm`, `screen_planner` and `screen_scout` draw
  none, and say so. A woven law's signature (`LawFx`, which a realm's
  `StageView` hangs under its world) is a 3D marker, as T5's effects are.
  The town's residents and workers are life in the realm, not figures the
  player steers: they are decoration. The town's houses and their trim
  (`StageTown.houses` and `trim`, under the screen's layers) are
  buildings, though they stand on open tiles round the grid. The mist
  sheets under the island (`look_mist`) are sky, and the falls
  (`look_fall`) water, not cliffs. Q5 and Q12's buildings and cliffs
  apply: the plan's realm goals (section 4) are paths, buildings and
  depth. Q11 rates the island: the plan's "the island not cut off on
  realm screens".
- **Character, Q5 and Q6.** A character stands on a plinth before a
  backdrop, not on ground with paths and buildings, and the stage draws
  no world markers. Q2 to Q4 measure each character (`h<i>`): height,
  contrast with the plinth behind it, and how much of its head the
  interface hides. A stage chooses none of its characters (`mask.json`
  holds `"chosen": -1`), so Q11 rates each of them (`characters`), names
  the first that is not clear (else the tallest), and passes when every
  one is clear and the tallest takes at least a third of the frame's
  height (the plan's "the character at least a third of the screen's
  height", `THIRD`). A screen with one character rates that one. A
  character pushed wholly off the frame is rated "off" and fails the
  screen; a screen with no character at all gives `null` and the reason
  "no character on the screen".
  Q12 counts the character's contact shadow: the stage's shadow disc under
  each plinth, drawn in the id pass as a thin disc of radius 0.4 in the
  figure's shadow code (the stage's own disc is a soft texture with no
  clear edge).
- **Universe, Q2 to Q6 and Q12.** The universe draws islands, not
  figures; the islands are too small at this distance for paths and
  buildings to read; and they float over the sky with nothing to cast a
  shadow on. The universe's pins (`UniversePins`) are counted as
  interface: they are the screen's labels, drawn in 2D over the world, not
  markers in the world. They stay over the cover in `ui_a` and `ui_b`,
  and are made see-through (alpha 0, not only hidden) for `world.png`
  and `id.png`: the universe screen sets the pins' `visible` again every
  frame (`home.gd`, `_fit_pins`), so hiding them by `visible` alone let
  them back into those passes. Q1 says how much of the universe the interface
  leaves clear. Q11 rates one island: the focused one, or the Heart (the
  player's own) where the camera focuses none; `mask.json` names it in
  `"island"`. The pass draws that island's meshes (its rock, its near and
  far looks, its close-up, and the Citadel for the Heart) with id index
  1 and every other island with index 0, and hides the galaxy behind
  them (`StarSky`, `universe_galaxy`), which otherwise fills the frame.
  At the widest zoom the universe draws one merged copy of all its
  islands (`UniverseWhole`); the pass draws the sources instead, so the
  rated island can be told from the rest.
- **None.** `screen_observatory` builds its card pictures in an offscreen
  `StageView` that is never drawn (`stage_thumbs.gd`), so the frame holds
  no 3D view. The pass saves the frame as `beauty.png` and as both `ui_`
  passes (all interface), black world and id passes, and `mask.json` with
  `"screen": "none"`; Q1 then reads the whole frame as interface.

**The shots on 26 November 2026** (`mask.py`, each with exit 0, no
script error, no unclassed mesh and no stray colour in `id.png`; the
second resync's run, after the pins, the vignette, the result screen's
fade and the clear colour round a small view were kept out of the id
pass):

| Shot | Kind | Figures | Buildings (Q5, Q12) | Q11 |
|---|---|---|---|---|
| `screen_heist`, `screen_laws` | heist | crew 24.2–28.4 pt, guards 38.9–39.6 pt | 1, on the path, unshadowed | all clear |
| `screen_landing` | heist | none yet ("no figure in frame") | none in frame | target under a panel |
| `screen_replay` | heist | crew 25–29 pt, guards 22.7–41.1 pt | none in frame | all clear |
| `screen_result` | heist | crew 14.5–33.8 pt | none in frame | chosen under a panel |
| `screen_realm` | realm | none | 6 (2 on one path), 0 of 4 shadowed | island cut left and right |
| `screen_builder`, `screen_curation` | realm | guards 38–40 pt | 4 (1 on one path), 0 of 4 shadowed | island cut left and right |
| `screen_defences` (`TAB=0`) | realm | crew 8–18.7 pt, guard 22.2 pt | 4 (2 on one path), 0 of 3 shadowed | island cut top and bottom |
| `screen_planner` | realm | none | none in frame | island clear |
| `screen_scout` | realm | none | none in frame | island cut left and right |
| `screen_character`, `screen_forms`, `screen_hatch`, `screen_roster`, `screen_sage_hall` | character | one, 99–125 pt | not measured | clear, 13.6–17.6% of the height (fail) |
| `screen_first` | character | three, 177–240 pt | not measured | h0 cut, h1 clear, h2 cut; 30.9% (fail) |
| `universe_home` | universe | not measured | not measured | the Heart clear (27.3% under the interface) |
| `universe_zoom` | universe | not measured | not measured | the Heart clear (46.6% under, near the 50% line) |
| `universe_screen` | universe | not measured | not measured | the Heart clear (22.1% under) |
| `universe_map` | universe | not measured | not measured | the Heart under a panel (56.9% under its chips) |
| `screen_observatory` | none | not measured | not measured | not measured |

The town's houses read unshadowed (foot luma about 1.0 of the tops'):
that is the look, not the pass. A law's screen tint (`law_fx_tint`, one
quad before the camera on `screen_replay` and `screen_result`) is hidden
with the sky: it is a wash over the frame, not a thing in the world.
So is the look's vignette and haze (`world_look.gd`, a 2D layer over the
3D world), which the id pass hides. The id pass also draws black behind
the world view (the project's sky-blue clear colour showed round
`screen_defences`' small view once its interface was see-through), and
lifts the world view's own tint and fade (`screen_result` draws its
island at 30% alpha, tinted violet), in `world.png` too. All three
decoded as classes before the stray check above caught them.

**`screen_realm`'s cut.** Its island touches the left and right edges
with its own meadow rim (other ground of tile kind "outside", rows 828
to 1405) and the cliff face at the rim's foot (rows 840 to 1407), not
with the underside rock below it: the beauty shows the meadow running
off both sides, so "cut" is what the eye sees.

**Root-window shots.** A screen shot draws on the root window, which
`project.godot` sizes at half the phone (540 × 1170, stretched). The pass
scales each saved pass back to the frame's own 1080 × 2340 with no blending,
so the id colours stay exact and every rectangle in `mask.json` matches the
images, as on a heist shot's SubViewport.

## Known limits

- **The plan's "nearest guard"** is matched by guard 0, not by the guard
  nearest the chosen crew member. If the plan meant something else (the
  guard nearest the vault, say), the matrix's comparison changes, not the
  measures: `Q11.guards` rates every guard.
- **The vault's rating** uses its pixels in `id.png`, and its projected
  bounds only for how much the frame cuts off. The bounds box is far
  larger than the dome (it holds the vault's tile and pieces), so a vault
  half off the frame may read "cut" where the eye says "off".
- **Q12's cliffs-darker check** is weak on this island: cliff faces read
  115.1 against tops at 114.8 at sneak, 15 tiles. The measure works, but
  the island has few cliff pixels in frame, so it says little here.
  `screen_replay` reads cliffs lighter than tops (47.2 against 39.1).
- **The strict band** moves with the moment's bubbles and labels (19.1%
  at sneak, 15 tiles; the plan's 16.6% was from another frame). Use
  `band` for Q1's target.
- **Lying figures.** `points` stands a figure's bounds up along the
  camera; a figure lying down reads short. The matrix measures such a
  figure by its silhouette; Q2's own `least_crew` does not, and reports
  it as it is.
- **Stacked figures.** Crew on one tile (entry) hide each other. Their
  heights come from their bounds and are right, but Q3 and Q4 count the
  hidden ones as hidden, which is what the player sees.
- **The universe's rated island** is the view's `focus_id` whenever that
  island exists, at any zoom. A shot that comes back to zoom 0 with an
  earlier focus left in `focus_id` rates that island, not the Heart;
  `"island"` in `mask.json` says which one was rated. Today's four
  universe shots all rate the Heart.
- **`measure.py --self-test`** is not run by `tools/check_all.sh` (not
  this task's file); the lead may add it.
- **`mask_pass.gd` is at gdlint's 1000-line limit**
  (`client/gdlintrc`). A further pass or class needs the file split (a
  stage pass and a world pass, say) before it can grow.
