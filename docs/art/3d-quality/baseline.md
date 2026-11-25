# The 3D baseline

Every 3D screen shot in `client/tests/shots/` (the list below), rendered on the Compatibility
renderer (llvmpipe) and measured with the mask tool ([`mask.md`](mask.md)). Written by
3D0-M1-baseline. The project's frame is 1080 × 2340; `screen_heist`, `screen_replay`,
`screen_result` and `screen_laws` save their stills at that size, the others at the project
window's half size, 540 × 1170. Triangle and draw-call counts do not depend on the size.

## Reproduce

In a fresh container, first set up the tools (`docs/guides/agent-brief.md`, "Starting a session") and
build the client with `bash client/build.sh`; then:

```
python3 docs/art/3d-quality/baseline/run.py --jobs 2
```

It renders each shot (about two minutes each) into `/tmp/ruleborn_baseline/<shot>/` (or
`$BASELINE_WORK/<shot>/`), keeps each shot's budget line and `measure.json` in `baseline/data/`, and
rewrites this file. `--no-render` renders nothing and writes no data: it only rebuilds this file
from `baseline/data/` (it exits 1 if that folder has no data file). `--only a,b` runs some shots. `screen_defences` is shot with `TAB=0`; `universe_map` and `universe_screen` are
`universe_screens.gd` with `SCREEN=map` and `SCREEN=universe`. `screen_laws`, `universe_map` and
`universe_screen` print no budget line of their own: `run.py` adds one to a copy of the script
(`BudgetSplit.line` for the laws heist, the universe view's count for the other two), and leaves
the script in `client/` as it is. It exits 1 if a shot fails (no work folder, no still, no budget
line, a script error in the shot, a renderer shader that failed to start, a timeout, or the mask
tool measured nothing for no known reason), and then keeps that shot's old data file. The mask
tool's known limit (below) is reported, not a failure, except on `screen_heist`, `screen_replay`,
`screen_result` and `screen_laws`, which it measures today. Each data file keeps its shot's verdict
(`verdict`, `why`).
`run.py`'s own tests, with no render:

```
python3 -m unittest discover -s docs/art/3d-quality/baseline -p 'test_*.py'
```

Two full runs in the same container agree on every figure but a few: `screen_laws` and
`screen_replay` moved by a few dozen outline-pass triangles (48 and 32, under 0.1% of the frame),
`screen_laws`' Q3 by 2 points (27% and 29%), and `screen_heist`'s shadow pixels by a few (Q12 the
same). `screen_heist`'s cliff luma, in its data file only, moved from 110 to 115; its top luma is
115, so `cliffs_darker` there can read either way. Compare a rerun against this table at that
tolerance.

**The shader cache race.** Shots rendered side by side on a fresh shader cache (the first run in
a container) can race to make the cache's folders; Godot then leaves a shader unstarted
(`ShaderGLES3::initialize` errors in the log; the "never freed" notice at exit is not one)
and the shot draws wrong, its ground black:
a `screen_replay` rendered so read Q3 87%, against 40% alone. Which shot loses the race changes
from run to run. `run.py` fails such a shot and renders it again alone, once the cache is made; a
second failure fails the run.

## Which shots count as 3D

A row is a screen of the game that draws a 3D world: a `WorldView` (heist, replay, result, laws,
realm, builder, curation, planner, scout, observatory, landing, defences), a character stage
(character, roster, sage hall, forms, hatch, first) or the universe view (home, zoom, map,
universe). Left out:

- **Variants of `screen_heist`** (the same heist screen, island and camera): `heist_shot`,
  `heist_budget`, `law_heist`, `law_heist_screen`, `style_frame_heist`, `uiq_heist_hud`,
  `world_shot`. `screen_laws` is kept as a row: it weaves three laws into the island, so its
  world differs.
- **Sheets** (a model or a look on its own, not a screen): `creature_busts`, `creature_colour`,
  `creature_forms`, `creature_heist`, `creature_lineup`, `creature_turntable`, `kit_buildings`,
  `kit_features`, `kit_probe`, `kit_realm`, `look_backdrop`, `look_budget`, `look_realms`,
  `law_crowns`, `law_gaits`, `law_signatures`, `icon_portraits`, `screen_portraits`, `screen_stage`.
- **Motion and transitions** (clips or a wipe over another screen): `motion_*`, `uiq_motion`,
  `universe_wipe`.
- **Interface screens with a small 3D preview** (no world view): `law_card`, `law_weaving`.
- **No 3D at all**: `auth_panel`, `law_a11y_only`, `screen_meta`, `screen_settings`, `ui_*`.
- **Helpers and tests**, not shots: `budget_split`, `budget_split_tests`, `law_run_tests`,
  `motion_rig`, `screen_shots`, `shot_data`, `shot_kit`, `stage_fixtures`, `universe_sample`.

## The table

Budget columns are the shots' `budget:` line: mesh triangles, outline-pass triangles, shadow-map
triangles, other views' triangles and the world view's draw calls (shadow passes included); the frame
triangles are their sum, and the frame draw calls are the whole frame's, the panels' and other
views' included: plan Q14's figure (at most 120). A `*` marks a shot that prints the renderer's frame
totals only (no split; `universe_*` print their universe view's triangles, in the first column, and
its draw calls, in View draw calls); a `-` in a budget column is a figure that shot does not print.

**`n/m` means not measured** (request M1-R2): the mask tool measures only the heist's
`WorldView` with its crew and guards. It finds no `WorldView` on the character stages and the universe
view, and stops on `screen_defences`, the realm screens and `screen_observatory`. Some of these qualities do not apply
there (Q2 to Q6 need crew and guards), but Q11 and Q12 do apply on realm, builder, defences and
character (`plan.md`, section 4), and are not yet measured. A `-` in a measured row means the
shot has nothing to measure for that quality (Q3 with no figure in the clear).

| Shot | Mesh tri | Outline tri | Shadow tri | Other-view tri | View draw calls | Frame tri | Frame draw calls | Q1 band | Q2 crew / guard pt | Q3 worst | Q4 least seen | Q5 deco | Q6 most | Q11 chosen; guard; tallest | Q12 shadowed |
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
| `screen_builder` | 27,770 | 7,991 | 4,230 | 1,846 | 74 | 41,837 | 151 | n/m | n/m | n/m | n/m | n/m | n/m | n/m | n/m |
| `screen_character` | - | - | - | - | - | 13,752* | 93* | n/m | n/m | n/m | n/m | n/m | n/m | n/m | n/m |
| `screen_curation` | 28,576 | 7,905 | 4,056 | 1,634 | 76 | 42,171 | 129 | n/m | n/m | n/m | n/m | n/m | n/m | n/m | n/m |
| `screen_defences` | 27,971 | 8,040 | 4,892 | 13,144 | 86 | 54,047 | 213 | n/m | n/m | n/m | n/m | n/m | n/m | n/m | n/m |
| `screen_first` | - | - | - | - | - | 72,080* | 50* | n/m | n/m | n/m | n/m | n/m | n/m | n/m | n/m |
| `screen_forms` | - | - | - | - | - | 21,428* | 120* | n/m | n/m | n/m | n/m | n/m | n/m | n/m | n/m |
| `screen_hatch` | - | - | - | - | - | 16,418* | 56* | n/m | n/m | n/m | n/m | n/m | n/m | n/m | n/m |
| `screen_heist` | 56,480 | 28,966 | 0 | 7,287 | 70 | 92,733 | 120 | 39% | 24.2 / 38.9 | 32% | 8% | 4.1% | 13 | clear; clear; 6% | 4/5 |
| `screen_landing` | 21,562 | 1,162 | 0 | 1,244 | 29 | 23,968 | 91 | n/m | n/m | n/m | n/m | n/m | n/m | n/m | n/m |
| `screen_laws` | 55,854 | 28,406 | 0 | 6,714 | 68 | 90,974 | 117 | 39% | 24.2 / 38.8 | 29% | 10% | 4.0% | 17 | clear; clear; 7% | 4/5 |
| `screen_observatory` (c) | 0 | 0 | 0 | 1,478 | 0 | 1,478 | 64 | n/m | n/m | n/m | n/m | n/m | n/m | n/m | n/m |
| `screen_planner` | 37,732 | 216 | 7,306 | 1,304 | 90 | 46,558 | 147 | n/m | n/m | n/m | n/m | n/m | n/m | n/m | n/m |
| `screen_realm` | 25,015 | 4,775 | 3,459 | 1,578 | 76 | 34,827 | 147 | n/m | n/m | n/m | n/m | n/m | n/m | n/m | n/m |
| `screen_replay` (a) | 75,726 | 43,610 | 0 | 4,186 | 77 | 123,522 | 111 | 0% | 25.0 / 22.7 | 40% | 0% | 3.8% | 15 | clear; clear; 7% | 6/6 |
| `screen_result` (b) | 61,010 | 33,094 | 0 | 4,394 | 56 | 98,498 | 103 | 0% | 14.5 / 21.9 | - | 0% | 0.0% | 1 | under panel; under panel; 8% | 0/9 |
| `screen_roster` | - | - | - | - | - | 19,602* | 133* | n/m | n/m | n/m | n/m | n/m | n/m | n/m | n/m |
| `screen_sage_hall` | - | - | - | - | - | 16,646* | 99* | n/m | n/m | n/m | n/m | n/m | n/m | n/m | n/m |
| `screen_scout` | 17,677 | 1,693 | 5,278 | 970 | 63 | 25,618 | 116 | n/m | n/m | n/m | n/m | n/m | n/m | n/m | n/m |
| `universe_home` | 33,085* | - | - | - | 33* | 68,770* | 148* | n/m | n/m | n/m | n/m | n/m | n/m | n/m | n/m |
| `universe_map` | 34,065* | - | - | - | 33* | 56,073* | 79* | n/m | n/m | n/m | n/m | n/m | n/m | n/m | n/m |
| `universe_screen` | 34,065* | - | - | - | 77* | 67,265* | 118* | n/m | n/m | n/m | n/m | n/m | n/m | n/m | n/m |
| `universe_zoom` | 34,065* | - | - | - | 33* | 55,273* | 58* | n/m | n/m | n/m | n/m | n/m | n/m | n/m | n/m |

(a) `screen_replay`: the replay's edge vignette is counted as cover. Its dark left and right edges
(110 to 144 px each, of 1080) cover a fifth or more of every row, so Q1's band reads 0% (62% of the
pixels read as cover, panels and vignette together); Q1 measures the vignette, not the world. Q4's
0% is real: crew member `c1`'s head (rows 1463 to 1484) lies under the "Golden replay" panel.

(b) `screen_result`: the result screen draws a full-screen backdrop over the world, so the mask tool
reads every pixel as cover (`panels_share` 1.0). Q1 0%, Q3's `-`, Q4 0%, Q5 0.0%, Q11's
"under panel" and Q12's 0/9 all come from that backdrop (the still shows the world only faintly
through it).

(c) `screen_observatory`: the screen has no world view on show (0 triangles, 0 draw calls in it).
`StageThumbs` draws the cards' universes earlier, in a hidden offscreen `StageView`, and shows them
as pictures, so the measured frame is the panels only, all under other views.

Q1 band is the clear band of the screen; Q2 is the least crew member / guard in points;
Q3 the worst share of a figure's pixels within 18 gray levels of the ground; Q4 the least visible
share of a head or marker; Q5 decoration's share of walkable ground; Q6 the most markers on one
object; Q11 the chosen crew member's and nearest guard's framing and the tallest figure's share of
the height; Q12 figures with a shadow. The targets are in `plan.md`, section 4.
