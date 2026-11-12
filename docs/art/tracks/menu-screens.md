# The menu screens on the kit

Branch `claude/ui-screens-meta`. Step 10 of `docs/art/ui-quality/report.md`: the menu screens (settings, profile, shop, codex, lab, law, social and the rest) and the character screen drawn from the kit (`docs/art/ui-quality/kit-spec.md`), the way the pilot heist was (`docs/art/tracks/heist-pilot.md`). What the kit cannot build is a component request to K1, through the lead, in `docs/progress/status/S3.json`.

The work is in three tasks: P2-S3-screenkit (the menu screens' shared materials, `client/scripts/screen_kit.gd` and `client/scripts/screen_box.gd`), then P2-S3-character and P2-S3-settings.

## Part 1: ScreenKit through KitSkin (P2-S3-screenkit)

### What was done

`kit-spec.md` section 8.1 has `ScreenKit` "re-skinned through `KitSkin`". Most of it already was. `ScreenKit.panel`, `.button` and `.restyle` map each of its looks to a theme material (`LOOKS`) and dress the control with `UI.dress`, which hands the material to `RbBox.dress`. `RbBox` draws the material's kit skin from the atlas (`client/ui/art/kit.json`) through `KitSkin.SKINS` wherever the material's family switch is on (every family but `disc_school`, `client/ui/kit_families.json`), and draws the code-drawn box where it is off or a piece is missing. `KitSkin.piece` logs `kit: no piece …` on a miss. The stills of settings, character, codex and lab logged none.

One look was routed to the wrong skin:

| Look | Material before | Skin drawn before | Material now | Skin drawn now |
|---|---|---|---|---|
| `well` | `track` | `bar_track`: the resource bar's track, a pill with a gold rim | `well` | `well`: the design's inset inside a card, a dark rounded box (radius 14) |

`well` is the look of the icon tiles on the settings rows, the codex's lead tile, the lab's tiles, the law screen's preview, the auth panel's back, the nav's rows and the `well` pills (`ScreenParts.pill(…, "well")`) on profile, shop, law, workshop and friends. Every other look draws the skin it drew before.

The thin bars were the last place `ScreenBox`, `ScreenKit`'s own code-drawn box, was drawn: `ScreenMeter.bar`, on settings, law, profile, social, codex and track. The lead granted S3-R1 and added `screen_meter.gd` to this task. `ScreenMeter.bar` is now the kit's `KitBar`, the heist's bar: the `bar_track` skin, and the `bar` fill tinted in the meter's colour, drawn by `RbBox` through `KitSkin`. Gold, the law card's pages, is the kit's own untinted fill. The value still eases to a new amount, through `Motion.fill`, or moves at once under reduced motion. `ScreenMeter.ring` is unchanged: it is code-drawn, like the heist's rings.

`ScreenBox` no longer draws a box, as kit-spec.md section 8.1 asks ("dropped after S3's routing"). What is left is its `outline` function, the rounded outline that `ScreenBands` and `ScreenSwitch` build their data shapes from. Those files are not this task's.

`check_screens.py`: 225 draw, 29 fill, 27 texture, OK. `screen_box.gd` went from 1 draw to 0. The record in `tools/ui_bake/budgets.json` is K1's file and still reads 1; the lead or K1 lowers it with `--record`. `budget_shots.py` on settings counts 3 fewer draw calls: 49 at 100% (recorded 52), 44 at 200% (recorded 47) and 49 in high contrast (recorded 52). `screen_kit.gd` keeps its one texture, the empty `TextureRect` that `ScreenKit.icon` returns for an empty icon name, because `Icons.texture("")` asserts.

### Evidence

Stills at 100% text, 1080 × 2340 rendered and saved at half size, in `docs/art/shots/menu-screens/`:

| Screen | Before | After | What changed |
|---|---|---|---|
| Settings | `before-settings-100.png` | `after-settings-100.png` | The row icons sit in rounded dark wells, not gold-rimmed pills; the volume bars are the kit's bar |
| Character | `before-character-100.png` | `after-character-100.png` | Nothing: the character screen uses no `well` |
| Codex | `before-codex-100.png` | `after-codex-100.png` | The lead tile is a rounded well; the mastery bar is the kit's bar |
| Lab | `before-lab-100.png` | `after-lab-100.png` | The tiles are rounded wells |
| Profile | `before-profile-100.png` | `after-profile-100.png` | The grade and season pills are rounded dark insets, not squared plates; the renown bar is the kit's bar |
| Shop | `before-shop-100.png` | `after-shop-100.png` | The kind pills and the currency chips are rounded dark insets |
| Workshop | `before-workshop-100.png` | `after-workshop-100.png` | The level, cleared and remix pills are rounded dark insets |
| Law | `before-law-100.png` | `after-law-100.png` | The note pills are rounded; the preview lost its dark frame (below) |
| Track | `before-track-100.png` | `after-track-100.png` | The stars bar is the kit's bar |
| Social | `before-social-100.png` | `after-social-100.png` | The renown bar is the kit's bar |

Friends, which uses a `well` pill only for a "partial" grade the fixture does not show, renders the same.

Commands: `SCREEN=<route> TEXT=100 bash tools/render/shoot.sh client/tests/shots/screen_meta.gd out.png` for the menu screens, and `TEXT=100 bash tools/render/shoot.sh client/tests/shots/screen_character.gd out.png` for the character screen (`SCREEN=character` on `screen_meta.gd` renders an empty screen).

The checks run on the task's last commit are in `docs/progress/S3.md`.

### What is still worse than before

- **The law card's preview has no frame.** `law_screen.gd` seats the preview in `ScreenKit.panel("well", preview, 16.0, 3.0)`. The track skin drew a dark rim round it; the well skin's rim is soft and 3 points of padding leave it under the picture, so the picture's edges fade into the green card. `law_screen.gd` is not this task's; it is in S3-R2 for AD to judge, and a fix (more padding, or the kit's `frame_*` look) is a request to the lead.
- **The 8-point volume bars on settings read thinner.** `KitBar` sets its fill 1 point inside the track's rim, so an 8-point bar has a 6-point fill. The old code-drawn fill ran the bar's full height. The heist's 8-point bars are the same. A fuller fill would be a `KitBar` change, so a request to K1; it is in S3-R2.

### Left for other tasks

- `budgets.json`'s record for `screen_box.gd` falls from 1 draw to 0 with `check_screens.py --record` (K1's file).
- `ScreenBox.outline` could move into `ScreenBands` and `ScreenSwitch`, its only users, so that `screen_box.gd` can go.
