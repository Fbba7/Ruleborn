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

### The settings shot record (Lead-R1)

The gate's first samples on "settings at 100% text" were cut from the rectangles of `art/ui/keyframes/05-settings.shot.json`, the key frame's record. That record and its still, `05-settings.png`, both show the Access tab, the key frame's design. The candidate still, rendered by `screen_meta.gd`, shows the Game tab, the tab the settings screen opens on. `screen_meta.gd` writes no record, so the gate had none of its own for the candidate.

`docs/art/shots/menu-screens/shot_record.gd` renders the settings screen and writes its record from the same frame: the title and every button on screen, in points of the 390 × 845 frame. The two pairs:

| Tab | Still | Record | Used for |
|---|---|---|---|
| Game | `after-settings-100-game.png` | `after-settings-100-game.shot.json` | P2-S3-screenkit's "settings at 100% text": the tab with the volume bars and the row wells this task changed. The still is pixel for pixel `after-settings-100.png` |
| Access | `after-settings-100-access.png` | `after-settings-100-access.shot.json` | P2-S3-settings, whose items follow key frame 05 (the Access tab) |

`python3 tools/ui_gate/checks.py all` on them: hud-share PASS and hierarchy N/A (no primary) on both. value-steps passes the open tab and the language pill on Game, the open tab on Access, and fails the rest: the dark plum steppers, switches and back button sit 0 to 1.1 value steps off the plum cards and the night ground, where the rule asks 2. On the key frame's record every control passes, its cream steppers and switches 44 to 88 L* off their ground. That is P2-S3-settings' work (the screen built on the key frame), not ScreenKit's materials.

### What is still worse than before

- **The law card's preview has no frame.** `law_screen.gd` seats the preview in `ScreenKit.panel("well", preview, 16.0, 3.0)`. The track skin drew a dark rim round it; the well skin's rim is soft and 3 points of padding leave it under the picture, so the picture's edges fade into the green card. `law_screen.gd` is not this task's; it is in S3-R2 for AD to judge, and a fix (more padding, or the kit's `frame_*` look) is a request to the lead.
- **The 8-point volume bars on settings read thinner.** `KitBar` sets its fill 1 point inside the track's rim, so an 8-point bar has a 6-point fill. The old code-drawn fill ran the bar's full height. The heist's 8-point bars are the same. A fuller fill would be a `KitBar` change, so a request to K1; it is in S3-R2.

### Left for other tasks

- `budgets.json`'s record for `screen_box.gd` falls from 1 draw to 0 with `check_screens.py --record` (K1's file).
- `ScreenBox.outline` could move into `ScreenBands` and `ScreenSwitch`, its only users, so that `screen_box.gd` can go.

## Part 2: the character screen (P2-S3-character)

### What was done

`client/scripts/character_screen.gd` is built from the kit, after key frame 04 (`art/ui/keyframes/04-character.png`):

- **The stage.** The hero stands full-bleed on its stage, with the state and the roster count on the kit's dark pills (`KitStatus.pill`), the kit's round gold arrows through the roster, and its name on the name-plate.
- **The tabs.** Heist, Stats and Compare are the kit's light segmented row (`KitNav.segmented`), each segment with the design's icon. At large text the three segments go two to a line, so each word stays whole.
- **The forms.** The forms and the guard form are portraits on the kit's grid (`KitLayout.grid`), with fewer columns at large text.
- **The ability and the facts.** The ability sits on the kit's ability card (`KitCards.ability`), and the facts on its info cards. The Compare tab's heads wrap in their halves.
- **The tray.** The fixed spends sit beneath the scroll: the round way back to the roster and the level-up button (`KitControls.upgrade`). At large text, `_fit_upgrade` lets the button grow to hold its words (S3-R3).
- **Contrast.** The subtitle wears the primary ink: the secondary ink is Lc 73 on the plum, against the 75 asked. The ability card's kicker wears `gold_top` and not the kit's gold, which is Lc 55 on the plum (S3-R4).
- **Wrapping at 200% text.** The ability's tag and the subtitle wrap against the screen's side, less the safe margin, each time their room moves as well as grows (`_wrap_in`). Before this, at 200% in pt_BR, the column ran 1256 pixels wide on a 1080-pixel screen. The ability tag also wears the Kicker variation, so it is now wrapped before the kicker's colour is set. Before, the colour branch caught it and the tag was never wrapped.
- **The shot.** `client/tests/shots/screen_character.gd` takes `LOCALE`, `TAB` and `SCROLL`. `FIT=1` fails the run when any label's words overflow it, leave its panel or run off the screen's sides. `RECORD=1` writes the still's shot record from the same frame, named as key frame 04's record names its controls: the arrows, the name-plate's words, the tabs as one row, the way back, and the level-up button as `up`. Words inside buttons, empty names and what the scroll hides under the tray are left out.

### Evidence

The stills are in `docs/art/shots/menu-screens/`. Each was rendered with this command, with the table's env in the environment (and `FIT=1 RECORD=1` on the recorded ones):

```
[env] bash tools/render/shoot.sh client/tests/shots/screen_character.gd <still>
```
 Every still printed `fit ok`.

| Still | Env | Draw calls | Record |
|---|---|---:|---|
| `character-100.png` | – | 79 | `.shot.json`, 7 controls |
| `character-200-pt_BR.png` | `TEXT=200 LOCALE=pt_BR` | 55 | `.shot.json`, 6 controls |
| `character-hc.png` | `HC=1` | 79 | `.shot.json`, 7 controls |
| `character-200-pt_BR-scrolled.png` | `TEXT=200 LOCALE=pt_BR SCROLL=2000` | 34 | `.shot.json`, 3 controls |
| `character-100-stats.png`, `character-100-compare.png` | `TAB=1`, `TAB=2` | 80, 69 | – |
| `character-200-en.png` | `TEXT=200` | 55 | – |
| `character-200-pt_BR-stats.png`, `-compare.png` | `TEXT=200 LOCALE=pt_BR TAB=1`, `TAB=2` | 58, 54 | – |

The before still is `before-character-100.png`, from Part 1.

`python3 tools/ui_gate/checks.py all` on the four records:

- **value-steps** passes every control. At 100% text, ΔL* is 50 and 52 on the arrows, 64 on the tabs, 77 on the way back and 61 on the level-up button. In high contrast it is 62 to 95. Key frame 04's own record reads 40 to 89.
- **hud-share** passes, at 0.
- **hierarchy** reads N/A (no primary), as on the key frame's record. It names no primary either. The tabs' row (366 × 56 points) is larger than the level-up button (276 × 64), so naming the button primary would fail the 1.5× rule on the key frame as well.

`tools/ui_bake/check_screens.py` reports two falls (K1's file, for `--record`):

- `character_screen.gd`: 3 fill → 0;
- `screen_box.gd`: 1 draw → 0.

The budget shots' recorded draw calls for the character screen are 103, 80 and 103 (100%, 200% and high contrast). They now read 79, 55 and 79, also for K1 or the lead to `--record`.

### What is still worse than before

- **The level badge at 200% text.** The level badge's "NV" kicker touches the top of the XP bar beside it. Both are the kit's (`KitStatus`); the words fit.
- **English words in pt_BR.** Some of the character's content strings are still English under pt_BR: "Two uses a heist", the ability's sentence and the carrier's "Hauls loot; 15% slower when loaded". They come from the content (`content/ruleborn.json`), not from `Strings`. This is not this task's work.
- **The tabs at 200% text.** They are under the tray in the opening frame, so the 200% record has no tabs row. The scrolled still shows them.
