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
| `solo_c<i>.png`, `solo_g<i>.png` | Each figure alone, its whole outline even where something hides it |
| `mask.json` | The frame, each figure's projected bounds, feet, head and span, the vault, the exit, the camera and the shot's settings |

**The id code.** Red and green carry the class (red `class // 4`, green
`class % 4`, each step 64 from 32). Blue carries the index: a figure's
number, or the tile's kind on the ground (step 28 from 14). The colours are
written as they are, with no sRGB step, so each arrives within a few levels
of its code; `measure.py` reads each channel in its band of 64 or 28. A
pixel whose channels are all under 16 is the background.

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

## Tolerances

| Check | Plan | Tolerance |
|---|---|---|
| Q1 band | 39% (rows 572 to 1487 of 2340) | ±1 point of percentage |
| Q1 panels | 37.5% of the pixels | ±1 point of percentage |
| Q2 crew at 15 tiles | 23 to 28 points | each end within 8% of the plan's range |
| Q2 heights in the matrix | the table's ranges | each end within 8% of the plan's range |
| Q11 ratings in the matrix | the table's words | the same word |

8% is two points at 28 points: the plan's ranges come from bounds that
include a figure's idle pose and outline, which move by about that much
between frames.

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
- **`measure.py --self-test`** is not run by `tools/check_all.sh` (not
  this task's file); the lead may add it.
