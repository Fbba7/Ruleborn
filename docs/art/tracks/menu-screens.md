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

### The gate's advisory verdict at f1251e68, and the fixes

The judge passed 4 of the 7 checks (`docs/art/ui-quality/gate/verdicts/P2-S3-character/f1251e68.json`, shadow mode). The three fails, and what this task changed after them (lead cycle 76: the cheap fixes before ready, the rest as follow-ups):

- **Display type, at 100% and at 200% pt_BR.** The subtitle (kind · role) and the "Level 3 of 10" label sat on the starfield with no ink outline. Both now wear the kit's ink outline all round (`ScreenKit.inked`, 1.5 points), as the world's words do. It adds 2 draw calls a still.
- **Hierarchy at 100%.** The open ability card outweighed Level up: its sentence was the kit's 20-point serif heading, about as large as the button's label. The sentence is now in the body face at 16 points, as on key frame 04's card, so it no longer counts as display words: the 100% and high-contrast records drop from 7 controls to 6. The high-contrast hierarchy check passed already; its failing samples named the same card.

Follow-ups, not taken here:

- **The ability card is still open, with its sentence.** Key frame 04 shows the sentence too, so collapsing the card to its header would drop words the anchor keeps. If the judge still fails hierarchy, the next step is the kit's: a smaller ability card (request to K1).
- **Level up's label and value.** The button is the kit's (`KitControls.upgrade`), and its growth is S3-R3's request.

### The gate's advisory verdict at 6f6a3b15

5 of the 7 checks pass (`docs/art/ui-quality/gate/verdicts/P2-S3-character/6f6a3b15.json`). Hierarchy at 100% now passes 3 of 3: Level up leads. Still failing, listed as follow-ups (the gate is advisory; lead cycle 76):

- **Display type, at 100% and at 200% pt_BR (3 fails of 3 each).** The judge still reads the subtitle and the level label as words over art with no outline. The 1.5-point outline is in the render, but it is the kit's ink (`#120C2A`) on a starfield near the same value, so it does not show at the still's scale. Next step, for AD or K1: put the two lines on a dark plate, or give words over the stage a light or gold edge the ink outline cannot give on this ground. The judge also names two kit parts: the level hexagon's "LV"/"NV" kicker runs over the badge's edge (`KitHex`), and the price on Level up is a flat white figure, not display type (`KitControls.upgrade`). Both are K1's.
- **Hierarchy in high contrast passes 4 of 6.** Two samples found Level up mid-grey and lower than the anchor's. The button's height at large text is S3-R3's.

### The gate on f5719f28, and the fixes

The lead's gate on f5719f28 (`docs/art/ui-quality/gate/verdicts/P2-S3-settings/f5719f28.json`) passed four of six: Hierarchy at 100%, and both high-contrast qualities. It failed:

- **Display type, at 100% and at 200% in pt_BR, three fails of three each.** The group headings sat on the starfield, and their ink outline does not show against the dark night: the judge saw "only a soft drop shadow". Each heading is now on its own dark plate (T0 with its drop), so no display word stands on the starfield.
- **Hierarchy, at 200% in pt_BR, three fails of three.** At large text the title, the headings and the rows were all one size (`UI.text_px` grows larger text only until the body text reaches it), so the thin "Ajustes" was outranked by the cream tab bar, the sample card and Voltar, and "Acesso" by its rows. The title now keeps 1.3 times the body text's size and the headings 1.1 times (41.6 and 35.2 points at 200%; nothing changes at 100%).

An advisory self-check on the new stills (one isolated judge per failed item, with the calibration's anchors) passed all three: Display type at 100% and at 200% in pt_BR, and Hierarchy at 200% in pt_BR. Its Hierarchy note is that "Ajustes" leads by less than the golden set's `kf-settings-text200`.

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
| `character-100.png` | – | 81 | `.shot.json`, 6 controls |
| `character-200-pt_BR.png` | `TEXT=200 LOCALE=pt_BR` | 61 | `.shot.json`, 6 controls |
| `character-hc.png` | `HC=1` | 81 | `.shot.json`, 6 controls |
| `character-200-pt_BR-scrolled.png` | `TEXT=200 LOCALE=pt_BR SCROLL=2000` | 34 | `.shot.json`, 3 controls |
| `character-200-pt_BR-tabs.png` | `TEXT=200 LOCALE=pt_BR SCROLL=600` | 56 | `.shot.json`, 4 controls |
| `character-100-stats.png`, `character-100-compare.png` | `TAB=1`, `TAB=2` | 82, 71 | – |
| `character-200-en.png` | `TEXT=200` | 59 | – |
| `character-200-pt_BR-stats.png`, `-compare.png` | `TEXT=200 LOCALE=pt_BR TAB=1`, `TAB=2` | 64, 60 | – |

The before still is `before-character-100.png`, from Part 1.

`python3 tools/ui_gate/checks.py all` on the five records:

- **value-steps** passes every control. At 100% text, ΔL* is 50 and 52 on the arrows, 64 on the tabs, 77 on the way back and 61 on the level-up button. In high contrast it is 62 to 95. Key frame 04's own record reads 40 to 89.
- **hud-share** passes, at 0.
- **hierarchy** reads N/A (no primary), as on the key frame's record. It names no primary either. The tabs' row (366 × 56 points) is larger than the level-up button (276 × 64), so naming the button primary would fail the 1.5× rule on the key frame as well.

`tools/ui_bake/check_screens.py` reports two falls (K1's file, for `--record`):

- `character_screen.gd`: 3 fill → 0;
- `screen_box.gd`: 1 draw → 0.

The budget shots' recorded draw calls for the character screen are 103, 80 and 103 (100%, 200% and high contrast). They now read 81, 61 and 81, also for K1 or the lead to `--record`.

### What is still worse than before

- **The level badge at 200% text.** The level badge's "NV" kicker touches the top of the XP bar beside it. Both are the kit's (`KitStatus`); the words fit.
- **English words in pt_BR.** Some of the character's content strings are still English under pt_BR: "Two uses a heist", the ability's sentence and the carrier's "Hauls loot; 15% slower when loaded". They come from the content (`content/ruleborn.json`), not from `Strings`. This is not this task's work.
- **The tabs at 200% text.** They are under the tray in the opening frame, so the 200% record has no tabs row. `character-200-pt_BR-tabs.png` (scrolled 600) shows them: the three tabs wrap to two rows, Comparar on its own, and its record's row passes value-steps (ΔL* 63).

## Part 3: the settings screen (P2-S3-settings)

### What was done

`client/scripts/settings_screen.gd` is built from the kit, after key frame 05 (`art/ui/keyframes/05-settings.png`):

- **The head.** The settings mark and the title, on the kit's plate. The title wears the display stroke (kit-spec 2.2, T2): an ink outline and a hard drop. Unlike `KitNav.logo`'s, the drop has no outline of its own: an outlined drop costs each stroked label one more draw call, which took settings past its budget (55 against 52 at 100% and in high contrast). At large text the title keeps 1.3 times the body text's size (41.6 points at 200%), where `UI.text_px` alone would leave it the body's size.
- **The tabs.** Game, Access and Account are one strip of parchment, each with the design's icon. The open tab is on the kit's chosen segment for parchment (`seg_on_light`: dark leather, cream words), so gold stays the main actions' alone (§21.8). When an icon and its word do not fit a third of the strip (at large text, or with a long word), the closed tabs keep only their icon and the open tab only its word, at twice the width. The screen reader still hears every word.
- **The rows.** Each setting is a kit row or section (`KitPanels.row`, `KitPanels.section`). Each group heading is on its own dark plate that hugs its words (kit-spec 2.2, T0 with its drop on a dark ground), and keeps 1.1 times the body text's size at large text (35.2 points at 200%). A heading too long for one line takes the row and wraps:
  - Steppers have the setting's icon in a well, its words over the kit's bar (`KitBar`), and − and + on leather.
  - Switches are whole rows framed on parchment. A row's words say On or Off, so the state never rests on colour alone (§20.8).
- **The switch.** `client/scripts/screen_switch.gd` (`ScreenSwitch.make`) draws key frame 05's switch from the kit's materials alone:
  - a pill track, green when on and dark plate when off;
  - a parchment knob, at the right end when on and the left end when off.
  
  It takes no taps; the row is the control.
- **Text size.** §20.8's text size is key frame 05's card:
  - a small A and a large A on parchment, either side of the size in large figures (gold_top, with a 2.5-point outline and the gold drop);
  - a dot for each step, the current one on plate and the rest on dark plate;
  - a law's card in the chosen size, to read before leaving. At large text its words stop at two lines, with an ellipsis, so the card does not fill the screen.
- **Colour blindness.** The colour-blind card shows the six schools' marks on their coins with their names. There is no mode to choose, because each school keeps its own shape in every light (§20.8).
- **The way back.** Back home is on the glass bar at the foot of the screen, lifted off its corner (`ScreenNav.CORNER_LIFT_POINTS`).
- **The shot.** `client/tests/shots/screen_settings.gd` takes `TAB` (default `access`, the key frame's tab), `TEXT`, `LOCALE`, `HC` and `SCROLL`.
  - `FIT=1` fails the run if any label's words overflow it, leave its panel or run off the screen's sides. It also fails if a button's words are wider than the button, less its margins, its icon and the gap.
  - `RECORD=1` writes the still's shot record from the same frame. Controls are named as key frame 05's record names them: `set-head`, the tabs as one `row`, `size-a`, `size-mid`, `sample`, `shapes`, `switch-row`, `back` and `words`. The record leaves out words inside buttons, the inside of the cards, and whatever the scroll hides.

### Evidence

The stills are in `docs/art/shots/menu-screens/`. Each was rendered with the command below, with the table's env set and `FIT=1 RECORD=1`. Every still printed `fit ok`.

```
[env] FIT=1 RECORD=1 bash tools/render/shoot.sh client/tests/shots/screen_settings.gd <still>
```

| Still | Env | Record |
|---|---|---|
| `settings-100.png` | – | `.shot.json`, 12 controls |
| `settings-200-pt_BR.png` | `TEXT=200 LOCALE=pt_BR` | `.shot.json`, 9 controls |
| `settings-pt_BR.png` | `LOCALE=pt_BR` | `.shot.json`, 10 controls |
| `settings-hc.png` | `HC=1` | `.shot.json`, 12 controls |

The before still is `before-settings-100.png`, from Part 1.

`python3 tools/ui_gate/checks.py all` on the records:

- **value-steps** passes every control. At 100% text, ΔL* is 78 on the tabs, 76 on the two As, 66 on the high-contrast row and 84 on Back. At 200% in pt_BR it is 51 to 83. In high contrast it is 74 to 96.
- **hud-share** passes, at 0.
- **hierarchy** reads N/A: settings has no primary (`checks.py`). The second level passes.

`tools/ui_bake/check_screens.py`: OK. `settings_screen.gd` and `screen_switch.gd` draw nothing outside the kit.

`tools/ui_bake/guard.sh`: OK. The budget shots (`screen_meta.gd`, `SCREEN=settings`, on the opening Game tab) read 48, 41 and 48 draw calls for settings at 100%, 200% and high contrast, against 52, 47 and 52 recorded (after AD's S3-R7 fixes; 48, 40 and 48 after the gate's). Before the self-check fixes it read 46 at 100%; the fixes' strokes brought it to 52 (on 9242f955), and with an outlined drop it read 55. The headings' plates, which drop the headings' outlines, bring it to 48. The falls are for K1 or the lead to `--record`. No word is below 4.5:1; the worst word reads 9.37:1, and 5.94:1 in high contrast.

### The advisory self-check, and the fixes

Before the gate request, an advisory self-check against the gate's three items (one isolated judge per item, on the stills of 1b22adc4) passed 2 of 6 qualities. What it found, and what changed in `settings_screen.gd`:

- **Display type, at 100%.** The group headings had no ink outline, unlike the key frame's, and the "100%" read flat. The headings and the title now wear the T2 stroke; "100%" is gold_top with a 2.5-point outline and the gold drop.
- **Display type and hierarchy, at 200% in pt_BR.** The law sample filled most of the screen, and its last line was cut. Its words now stop at two lines with an ellipsis.
- **Colour roles and value, in high contrast.** The open tab, the two As and the current step's dot were gold, beside the main actions' gold (§21.8). The open tab is now the kit's chosen segment for parchment, and the current dot plate. The As went to leather first, but leather on the violet card reads ΔL* 8 (`checks.py value-steps` fails it in en and pt_BR), so they are on parchment, as the tabs and the switch rows: ΔL* 76, and 95 in high contrast.

### AD's preview (S3-R7), and the answers

AD previewed the stills of f5719f28 (`status/AD.json` on `claude/ui-ad`, S3-R7) and sent six objections in one round. They are listed here in AD's order of weight. AD let these stand: the cream As, the dark chosen tab, the sentence-case tabs, and the pt_BR coins three to a line.

1. **The title at 200% must grow with the text and stay the largest word.** Done in 917886c4: the title is 1.3 times the body text's size.
2. **The headings need the display outline of at least 1.5 points, or the tag plate.** Done in 917886c4: each heading is on its own dark plate.
3. **The ground ramp is reversed: the foot should be the darkest, #0B0621 as in key frame 05.** Not changed here. The night gradient is §21.2's linear ramp (night_top #171046 to night_bottom #2C3AA8). The owner chose it over the designs' radial ground in C75 (closed 4 November, answer A). It is drawn by `UI.frame` in `ui.gd`, which is not this task's file. A change would be the owner's decision first, then K1's work. The headings no longer stand on the ground (point 2), so their legibility does not depend on it.
4. **At 200% in pt_BR, the Stillness card should hold the whole law, and the list should end on a row's edge or show a scroll cue.** The two-line ellipsis is gone, and the sample shows the whole law at every size. The sample's padding, line spacing and icon (32 points, was 40) are tighter to make room. The list's window now ends on a whole row's edge (`_snap_list`). The rows' own chevron (the kit's `hud/next`, turned down) stands in the gap below that edge while more rows lie below. Where no edge fits within 48 points (at 200%, the text card is taller than what is left), the window cuts through the row above the cue: the Stillness card shows whole, and its violet card runs on below it. There is no fade. A screen draws no chrome of its own: a `GradientTexture2D` fade raised `check_screens.py`'s texture count from 0 to 2. The kit has no scroll cue (S3-R8 asks K1 for one).
5. **At 100% and in high contrast, the Motion switch should clear the dock.** At 100%, Stillness's law now fits on two lines (the text card is trimmed). The window ends under the High contrast row, and the chevron says more lies below. Motion is the next row, a scroll away.
6. **The gold "100%" should be a step below the title.** It is 24 points, against the title's 28, and its outline is 2 points.

AD said it will re-check only what changed: items 4 to 6, and 1 and 2 from 917886c4.

### What is still worse than before

- **The tab and back words.** Key frame 05 sets them in capitals. The screen keeps the kit's sentence case (`Tokens.type_role`). Capitals would be a change to the kit's type roles, which is K1's work.
- **The shapes in pt_BR.** At 100% text, the longer Portuguese names (Movimento, Matéria) put the six coins three to a line, not the key frame's six in one row.
- **The fold at 200% text.** The whole law shows, but the text card runs past the window, the colour-blind card and the switches are below the fold (`SCROLL`), and the cue is a chevron with no fade, until the kit has a scroll cue (S3-R8).
- **The ground.** Key frame 05 darkens towards the foot. The screen keeps §21.2's ramp, which lightens towards the foot, as decided in C75 (point 3 above).
- **The law's words.** They are the content's, and they are English under pt_BR ("Stillness", from `content/ruleborn.json`), as on the character screen. This is not this task's work.
