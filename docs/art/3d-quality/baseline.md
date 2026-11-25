# The 3D baseline

Every 3D screen shot in `client/tests/shots/` (the list below), rendered at 1080 × 2340 on the
Compatibility renderer (llvmpipe) and measured with the mask tool ([`mask.md`](mask.md)). Written by
3D0-M1-baseline.

## Reproduce

```
python3 docs/art/3d-quality/baseline/run.py --jobs 2
```

It renders each shot (about two minutes each) into `/tmp/ruleborn_baseline/<shot>/` (or
`$BASELINE_WORK/<shot>/`), keeps each shot's budget line and `measure.json` in `baseline/data/`, and
rewrites this file. `--no-render` rebuilds the table from `baseline/data/`; `--only a,b` runs some
shots. `screen_defences` is shot with `TAB=0`; `universe_map` and `universe_screen` are
`universe_screens.gd` with `SCREEN=map` and `SCREEN=universe`. `screen_laws`, `universe_map` and
`universe_screen` print no budget line of their own: `run.py` adds one to a copy of the script
(`BudgetSplit.line` for the laws heist, the universe view's count for the other two), and leaves
the script in `client/` as it is. It exits 1 if a shot fails (no still, no budget line, a script
error in the shot, a timeout); the mask tool's known limit (below) is reported, not a failure.

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
triangles, other views' triangles and the world views' draw calls (shadow passes included); the frame
total is their sum. A `*` marks a shot that prints the renderer's frame totals only (no split;
`universe_*` print their universe view's triangles in the first column); a `-` in a budget column is a
figure that shot does not print.

**`n/m` means not measured** (request M1-R2): the mask tool measures only the heist's
`WorldView` with its crew and guards. It finds no `WorldView` on the character stages and the universe
view, and stops on `screen_defences` and the realm screens. Some of these qualities do not apply
there (Q2 to Q6 need crew and guards), but Q11 and Q12 do apply on realm, builder, defences and
character (`plan.md`, section 4), and are not yet measured. A `-` in a measured row means the
shot has nothing to measure for that quality (Q3 with no figure in the clear).

| Shot | Mesh tri | Outline tri | Shadow tri | Other-view tri | Draw calls | Frame tri | Q1 band | Q2 crew / guard pt | Q3 worst | Q4 least seen | Q5 deco | Q6 most | Q11 chosen; guard; tallest | Q12 shadowed |
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
| `screen_builder` | 27,770 | 7,991 | 4,230 | 1,846 | 74 | 41,837 | n/m | n/m | n/m | n/m | n/m | n/m | n/m | n/m |
| `screen_character` | - | - | - | - | 93* | 13,752* | n/m | n/m | n/m | n/m | n/m | n/m | n/m | n/m |
| `screen_curation` | 28,576 | 7,905 | 4,056 | 1,634 | 76 | 42,171 | n/m | n/m | n/m | n/m | n/m | n/m | n/m | n/m |
| `screen_defences` | 27,971 | 8,040 | 4,892 | 13,144 | 86 | 54,047 | n/m | n/m | n/m | n/m | n/m | n/m | n/m | n/m |
| `screen_first` | - | - | - | - | 50* | 72,080* | n/m | n/m | n/m | n/m | n/m | n/m | n/m | n/m |
| `screen_forms` | - | - | - | - | 120* | 21,428* | n/m | n/m | n/m | n/m | n/m | n/m | n/m | n/m |
| `screen_hatch` | - | - | - | - | 56* | 16,418* | n/m | n/m | n/m | n/m | n/m | n/m | n/m | n/m |
| `screen_heist` | 56,480 | 28,966 | 0 | 7,287 | 70 | 92,733 | 39% | 24.2 / 38.9 | 32% | 8% | 4.1% | 13 | clear; clear; 6% | 4/5 |
| `screen_landing` | 21,562 | 1,162 | 0 | 1,244 | 29 | 23,968 | n/m | n/m | n/m | n/m | n/m | n/m | n/m | n/m |
| `screen_laws` | 55,854 | 28,358 | 0 | 6,714 | 68 | 90,926 | 39% | 24.2 / 38.8 | 27% | 10% | 4.0% | 17 | clear; clear; 7% | 4/5 |
| `screen_observatory` | 0 | 0 | 0 | 1,478 | 0 | 1,478 | n/m | n/m | n/m | n/m | n/m | n/m | n/m | n/m |
| `screen_planner` | 37,732 | 216 | 7,306 | 1,304 | 90 | 46,558 | n/m | n/m | n/m | n/m | n/m | n/m | n/m | n/m |
| `screen_realm` | 25,015 | 4,775 | 3,459 | 1,578 | 76 | 34,827 | n/m | n/m | n/m | n/m | n/m | n/m | n/m | n/m |
| `screen_replay` (a) | 75,726 | 43,642 | 0 | 4,186 | 77 | 123,554 | 0% | 25.0 / 22.7 | 40% | 0% | 3.8% | 15 | clear; clear; 7% | 6/6 |
| `screen_result` (b) | 61,010 | 33,094 | 0 | 4,394 | 56 | 98,498 | 0% | 14.5 / 21.9 | - | 0% | 0.0% | 1 | under panel; under panel; 8% | 0/9 |
| `screen_roster` | - | - | - | - | 133* | 19,602* | n/m | n/m | n/m | n/m | n/m | n/m | n/m | n/m |
| `screen_sage_hall` | - | - | - | - | 99* | 16,646* | n/m | n/m | n/m | n/m | n/m | n/m | n/m | n/m |
| `screen_scout` | 17,677 | 1,693 | 5,278 | 970 | 63 | 25,618 | n/m | n/m | n/m | n/m | n/m | n/m | n/m | n/m |
| `universe_home` | 33,085* | - | - | - | 33* | 68,770* | n/m | n/m | n/m | n/m | n/m | n/m | n/m | n/m |
| `universe_map` | 34,065* | - | - | - | 33* | 56,073* | n/m | n/m | n/m | n/m | n/m | n/m | n/m | n/m |
| `universe_screen` | 34,065* | - | - | - | 77* | 67,265* | n/m | n/m | n/m | n/m | n/m | n/m | n/m | n/m |
| `universe_zoom` | 34,065* | - | - | - | 33* | 55,273* | n/m | n/m | n/m | n/m | n/m | n/m | n/m | n/m |

(a) `screen_replay`: the replay's edge vignette is counted as cover. It covers more than a fifth of
every row (62% of the pixels in all), so Q1's band reads 0%; crew member `c1`'s head lies under it,
so Q4's least seen reads 0%. Neither is the replay's world.

(b) `screen_result`: the result screen draws a full-screen backdrop over the world, so the mask tool
reads every pixel as cover (`panels_share` 1.0). Q1 0%, Q4 0%, Q11's "under panel", Q3's `-`
and Q12's 0/9 all come from that backdrop.

Q1 band is the clear band of the screen; Q2 is the least crew member / guard in points;
Q3 the worst share of a figure's pixels within 18 gray levels of the ground; Q4 the least visible
share of a head or marker; Q5 decoration's share of walkable ground; Q6 the most markers on one
object; Q11 the chosen crew member's and nearest guard's framing and the tallest figure's share of
the height; Q12 figures with a shadow. The targets are in `plan.md`, section 4.
