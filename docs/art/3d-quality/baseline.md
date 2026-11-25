# The 3D baseline

Every 3D screen shot in `client/tests/shots/`, rendered at 1080 × 2340 on the Compatibility renderer
(llvmpipe) and measured with the mask tool ([`mask.md`](mask.md)). Written by 3D0-M1-baseline.

## Reproduce

```
python3 docs/art/3d-quality/baseline/run.py --jobs 2
```

It renders each shot (about two minutes each) into `/tmp/ruleborn_baseline/<shot>/`, keeps each shot's
`budget:` line and `measure.json` in `baseline/data/`, and rewrites this file. `--no-render` rebuilds
the table from `baseline/data/`; `--only a,b` runs some shots. `screen_defences` is shot with `TAB=0`.

Budget columns are the shots' `budget:` line: mesh triangles, outline-pass triangles, shadow-map
triangles, other views' triangles and the world views' draw calls (shadow passes included); the frame
total is their sum. A `-` means the quality does not apply to that shot (no figures, or no world
view) or the shot printed no line. A `*` marks a shot that prints the renderer's frame totals only (no
split; `universe_*` print their world triangles in the first column). The mask tool needs the heist's
`WorldView`: on every other shot Q1 to Q6, Q11 and Q12 read `-` (request M1-R2).

| Shot | Mesh tri | Outline tri | Shadow tri | Other-view tri | Draw calls | Frame tri | Q1 band | Q2 crew / guard pt | Q3 worst | Q4 least seen | Q5 deco | Q6 most | Q11 chosen; guard; tallest | Q12 shadowed |
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
| `screen_builder` | 27,770 | 7,991 | 4,230 | 1,846 | 74 | 41,837 | - | - | - | - | - | - | - | - |
| `screen_character` | - | - | - | - | 93* | 13,752* | - | - | - | - | - | - | - | - |
| `screen_curation` | 28,576 | 7,905 | 4,056 | 1,634 | 76 | 42,171 | - | - | - | - | - | - | - | - |
| `screen_defences` | 27,971 | 8,040 | 4,892 | 13,144 | 86 | 54,047 | - | - | - | - | - | - | - | - |
| `screen_first` | - | - | - | - | 50* | 72,080* | - | - | - | - | - | - | - | - |
| `screen_forms` | - | - | - | - | 120* | 21,428* | - | - | - | - | - | - | - | - |
| `screen_hatch` | - | - | - | - | 56* | 16,418* | - | - | - | - | - | - | - | - |
| `screen_heist` | 56,480 | 28,966 | 0 | 7,287 | 70 | 92,733 | 39% | 24.2 / 38.9 | 32% | 8% | 4.1% | 13 | clear; clear; 6% | 4/5 |
| `screen_landing` | 21,562 | 1,162 | 0 | 1,244 | 29 | 23,968 | - | - | - | - | - | - | - | - |
| `screen_observatory` | 0 | 0 | 0 | 1,478 | 0 | 1,478 | - | - | - | - | - | - | - | - |
| `screen_planner` | 37,732 | 216 | 7,306 | 1,304 | 90 | 46,558 | - | - | - | - | - | - | - | - |
| `screen_realm` | 25,015 | 4,775 | 3,459 | 1,578 | 76 | 34,827 | - | - | - | - | - | - | - | - |
| `screen_replay` | 75,726 | 43,642 | 0 | 4,186 | 77 | 123,554 | 0% | 25.0 / 22.7 | 40% | 0% | 3.8% | 15 | clear; clear; 7% | 6/6 |
| `screen_result` | 61,010 | 33,094 | 0 | 4,394 | 56 | 98,498 | 0% | 14.5 / 21.9 | - | 0% | 0.0% | 1 | under panel; under panel; 8% | 0/9 |
| `screen_roster` | - | - | - | - | 133* | 19,602* | - | - | - | - | - | - | - | - |
| `screen_sage_hall` | - | - | - | - | 99* | 16,646* | - | - | - | - | - | - | - | - |
| `screen_scout` | 17,677 | 1,693 | 5,278 | 970 | 63 | 25,618 | - | - | - | - | - | - | - | - |
| `universe_home` | 33,085* | - | - | - | 33* | 68,770* | - | - | - | - | - | - | - | - |
| `universe_zoom` | 34,065* | - | - | - | 33* | 55,273* | - | - | - | - | - | - | - | - |

Q1 band is the clear band of the screen; Q2 is the least crew member / guard in points;
Q3 the worst share of a figure's pixels within 18 gray levels of the ground; Q4 the least visible
share of a head or marker; Q5 decoration's share of walkable ground; Q6 the most markers on one
object; Q11 the chosen crew member's and nearest guard's framing and the tallest figure's share of
the height; Q12 figures with a shadow. The targets are in `plan.md`, section 4.
