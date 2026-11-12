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

`ScreenBox`, `ScreenKit`'s own code-drawn box, is still drawn in one place: `ScreenMeter.bar`, the thin bars of settings, law, profile, social, codex and track. `screen_meter.gd` is not in this task's files, so its move to the kit's `KitBar` is request S3-R1 to the lead. `ScreenBox` cannot route through the kit inside `screen_box.gd`, for two reasons. Any new draw call or `StyleBoxTexture` there raises its record in `tools/ui_bake/budgets.json`. And a 10-point bar is thinner than the `bar_track` slice's 14 points, so the 9-slice would be scaled down whole (`RbBox._draw_piece`). `KitBar` already draws a thin bar from the kit.

`check_screens.py` counts are unchanged: 226 draw, 29 fill, 27 texture, OK. `screen_kit.gd` keeps its one texture, the empty `TextureRect` that `ScreenKit.icon` returns for an empty icon name, because `Icons.texture("")` asserts.

### Evidence

Stills at 100% text, 1080 × 2340 rendered and saved at half size, in `docs/art/shots/menu-screens/`:

| Screen | Before | After | What changed |
|---|---|---|---|
| Settings | `before-settings-100.png` | `after-settings-100.png` | The row icons sit in rounded dark wells, not gold-rimmed pills |
| Character | `before-character-100.png` | `after-character-100.png` | Nothing: the character screen uses no `well` |
| Codex | `before-codex-100.png` | `after-codex-100.png` | The lead tile is a rounded well |
| Lab | `before-lab-100.png` | `after-lab-100.png` | The tiles are rounded wells |
| Profile | `before-profile-100.png` | `after-profile-100.png` | The grade and season pills are rounded dark insets, not squared plates |
| Shop | `before-shop-100.png` | `after-shop-100.png` | The kind pills and the currency chips are rounded dark insets |
| Workshop | `before-workshop-100.png` | `after-workshop-100.png` | The level, cleared and remix pills are rounded dark insets |
| Law | `before-law-100.png` | `after-law-100.png` | The note pills are rounded; the preview lost its dark frame (below) |

Friends, which uses a `well` pill only for a "partial" grade the fixture does not show, renders the same.

Commands: `SCREEN=<route> TEXT=100 bash tools/render/shoot.sh client/tests/shots/screen_meta.gd out.png` for the menu screens, and `TEXT=100 bash tools/render/shoot.sh client/tests/shots/screen_character.gd out.png` for the character screen (`SCREEN=character` on `screen_meta.gd` renders an empty screen).

The checks run on the task's last commit are in `docs/progress/S3.md`.

### What is still worse than before

- **The law card's preview has no frame.** `law_screen.gd` seats the preview in `ScreenKit.panel("well", preview, 16.0, 3.0)`. The track skin drew a dark rim round it; the well skin's rim is soft and 3 points of padding leave it under the picture, so the picture's edges fade into the green card. `law_screen.gd` is not this task's; it is in S3-R2 for AD to judge, and a fix (more padding, or the kit's `frame_*` look) is a request to the lead.

### Left for other tasks

- `ScreenMeter.bar` onto `KitBar`, and `ScreenBox` dropped: S3-R1. The default is P2-S3-settings, with `screen_meter.gd` added to its files.
