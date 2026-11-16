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

This table is the earlier round's. Board 5's round re-rendered these stills and removed `character-200-pt_BR-tabs.png`; its table is under "Board 5's objections" below.

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

### Board 5's objections (P2-S3-character-2)

AD's board 5 (`docs/art/ui-quality/gate/boards/board-5.md`) raised five objections on the character screen: A, B, C, D and G (AD-R31 to AD-R37 in `docs/progress/requests.md`). Each is answered in `client/scripts/character_screen.gd`. The kit's own forms for each change are asked of K1 through the lead, S3-R9 to S3-R14 in `docs/progress/status/S3.json`, each defaulting to the screen's code.

- **A: the Level up button fits its words at 200% text.**
  - As key frame 04, the label is "Level up" in the display face: mixed case, cream, stroked in ink, with its drop. The price is in the kit's white numerals (`KitNumerals`, `num_white`).
  - At body size the words sit left of the price chip. At large text the title takes the button's width, and the level line sits beside the chip under it, as the large-text key frame does.
  - The words break between words only, never inside one ("Aufsteigen" stays whole), and the button grows to hold them (`_fit_upgrade`). German "Stufe 3 → 4" stays inside the button, and the 200% shots in English, pt_BR and German all print `fit ok`.
  - The scripted fit check is `docs/art/shots/menu-screens/fit_character.sh`. It renders 100% and 200% text in en, pt_BR and de, and high contrast in en and pt_BR, with `FIT=1`, and fails unless each shot prints `fit ok`.
- **B: the first screen at 200% text.**
  - **The tabs.** All three stand on one line. The open tab shows its word, and the other two show their icons only, named for a screen reader (`_tabs`). This needs no icon-only form in the kit; S3-R9 asks for one.
  - **The subtitle and level line.** Each holds one line, growing smaller first, down to 24 and 22 points (`_wrap_in` with `least`).
  - **The stage** is 165 points tall plus the safe top at large text, against 170 at body size.
  - **The ability card.** Its icon heads the card beside its kicker, as the large-text key frame's header band does.
  - **What shows.** The tabs and the ability header (icon and kicker) stand above the tray in all three locales.
- **C: the first screen at 100% text.** All four facts now stand whole above the tray in every locale.
  - **The tabs.** Each icon is inline before its word, one line tall.
  - **The ability card.** The tag sits inline after the kicker, and the ability's sentence takes two lines (S3-R10).
  - **The facts.** They are compact, as key frame 04's: the disc beside the kicker, the words under both across the card at 13 points, and 6 points of padding (`_compact`, S3-R13).
  - **Kickers that run tight.** A kicker drops its tracking, as the kit's tags are set, when its longest word, or the kicker with its tag, is wider than its room (`_untrack_when_tight`, S3-R14). German "EIGENSCHAFTEN" stands whole, and Portuguese "HABILIDADE" keeps its tag on its line.
  - **The tray** keeps its 20 points off the column's foot. Moving it 6 points nearer the foot, as key frame 04's, put the way back inside the corner band (see below).
- **D: the display type.**
  - **The level tag.** The hexagon grows with the player's text, so its "LV", "NV" or "ST" kicker stays inside it at every size.
  - **Words on the backdrop.** The subtitle and level line wear the kit's ink outline at every size (`ScreenKit.inked`). At large text, as the large-text key frame, they wear a heavier one (12% of their size) and the display type's hard drop (`_over_stage`).
  - **The button.** The price and the Level up label wear the display treatment (as A).
- **G: the stage's foot.** The stage's bottom fades to the menus' night at the point where the stage ends on the screen (`_blend_foot`), so its sky runs on into the backdrop with no edge (S3-R11).
- **H: the face stays clear at 200% text** (AD's preview, S3-R15, from board 5's full list: quality 9, character presence).
  - **The problem.** B's shorter stage put the status pill's words across the character: "trabalhando" in pt_BR hid the whole head, and "working" and "arbeitet" covered half the face.
  - **The fix.** At large text the pill keeps its top-right corner as the state's icon alone. Each state has its own icon, so the state never rests on colour. The pill's words, timer included, become its accessible name and tooltip (`_stand`). At body size the pill keeps its words, as before.
  - **What shows.** At 200% the whole head stands between the count pill, the state icon and the arrows, in en, pt_BR and de, on the Heist, Stats and Compare tabs. The 200% stills were re-rendered with this change; 100% and high contrast take the body-size branch, so their stills are unchanged.

#### Evidence

The stills and records are in `docs/art/shots/menu-screens/`. They were rendered on the board-5 code, with the tray at 20 points off the foot, with this command, the table's env set, and every still printed `fit ok`:

```
[env] FIT=1 bash tools/render/shoot.sh client/tests/shots/screen_character.gd <still>
```

The recorded stills were rendered with `RECORD=1` as well.

| Still | Env | Draw calls | Record |
|---|---|---:|---|
| `character-100.png` | – | 91 | `.shot.json`, 6 controls |
| `character-100-pt_BR.png`, `character-100-de.png` | `LOCALE=pt_BR`, `LOCALE=de` | 91, 91 | `.shot.json`, 6 controls |
| `character-200-pt_BR.png` | `TEXT=200 LOCALE=pt_BR` | 66 | `.shot.json`, 6 controls |
| `character-200-en.png`, `character-200-de.png` | `TEXT=200`, `TEXT=200 LOCALE=de` | 66, 66 | `.shot.json`, 7 controls |
| `character-hc.png`, `character-hc-pt_BR.png` | `HC=1`, `HC=1 LOCALE=pt_BR` | 91, 91 | `.shot.json`, 6 controls |
| `character-200-pt_BR-scrolled.png` | `TEXT=200 LOCALE=pt_BR SCROLL=2000` | 43 | `.shot.json`, 2 controls |
| `character-100-stats.png`, `character-100-compare.png` | `TAB=1`, `TAB=2` | 83, 73 | – |
| `character-200-pt_BR-stats.png`, `-compare.png` | `TEXT=200 LOCALE=pt_BR TAB=1`, `TAB=2` | 75, 64 | – |

Notes on the table:

- A record's "controls" are the ones `checks.py` reads: the two arrows, the name on the backdrop, the tabs' row (as one), the way back and Level up. In English and German at 200% the subtitle, "Skyskipper · Carrier", is display-sized words on the backdrop too, so it counts as a seventh.
- `character-200-pt_BR-tabs.png` is gone: the tabs now stand on the first screen at 200%.
- The draw calls are each frame's, as the shot prints them.

`python3 tools/ui_gate/checks.py all` passes on all nine records, with no FAIL: value-steps passes every control, hud-share passes, and hierarchy reads N/A, as on key frame 04's record.

The ΔL* that value-steps measures:

| Still | Arrows | Tabs | Way back | Level up |
|---|---|---:|---:|---:|
| 100% | 53 and 56 | 65 | 77 | 60 |
| 200%, pt_BR | 58 and 58 | 61 | 77 | 62 |
| 200%, en | 58 and 58 | 62 | 77 | 62 |
| 200%, de | 58 and 58 | 60 | 77 | 62 |
| High contrast | 65 and 67 | 83 | 95 | 78 |

`check_screens.py`, `guard.sh` and `gdlint` are OK.

#### What still differs from the key frame

- **The tray's height above the foot.** The tray stands about 65 points above the screen's foot, against about 40 in key frame 04. The layout check's corner band, the bottom 8% of the screen, holds the way back at least 62 points above the foot. This is board 5's note for K1 (`ui.gd`'s bottom margin). A try at 6 points off the column's foot, against 20, put the way back's lower edge at 2,166 of 2,340 pixels, inside that band. The client's layout tests failed at 9:16 and 9:19.5, and at 150% and 200% text, so the tray stays at 20.
- **The ability card at 200% text.** Its tag line and its sentence run under the tray as scroll content. The key frame's header band shows only the icon and kicker above the tray, as this build does.
- **Mixed tracking.** In German at 100%, the traits kicker drops its tracking while its neighbours keep theirs, until the kit's cards do the same (S3-R14).
- **English content.** The ability's sentence, "Two uses a heist" and "Hauls loot" are English in pt_BR and German. This is content localisation, not the screen's work, and the pt_BR key frame shows the same.
- **The earlier list.** Its first and third points, the level badge and the tabs at 200%, are answered above (D and B).

## Part 3: the settings screen (P2-S3-settings)

### What was done

`client/scripts/settings_screen.gd` is built from the kit, after key frame 05 (`art/ui/keyframes/05-settings.png`):

- **The head.** The settings mark and the title, on the kit's plate. The title wears the display stroke (kit-spec 2.2, T2): an ink outline and a hard drop. Unlike `KitNav.logo`'s, the drop has no outline of its own: an outlined drop costs each stroked label one more draw call, which took settings past its budget (55 against 52 at 100% and in high contrast). At large text the title keeps 1.5 times the body text's size (48 points at 200%), where `UI.text_px` alone would leave it the body's size.
- **The tabs.** Game, Access and Account are one strip of parchment, each with the design's icon. The open tab is on the kit's chosen segment for parchment (`seg_on_light`: dark leather, cream words), so gold stays the main actions' alone (§21.8). When an icon and its word do not fit a third of the strip (at large text, or with a long word), the closed tabs keep only their icon and the open tab only its word, at twice the width. The screen reader still hears every word.
- **The rows.** Each setting is a kit row or section (`KitPanels.row`, `KitPanels.section`). Each group heading is on its own dark plate that hugs its words (kit-spec 2.2, T0 with its drop on a dark ground), and keeps 1.1 times the body text's size at large text (35.2 points at 200%). A heading too long for one line takes the row and wraps:
  - Steppers have the setting's icon in a well, its words over the kit's bar (`KitBar`), and − and + on leather.
  - Switches are whole rows framed on parchment. A row's words say On or Off, so the state never rests on colour alone (§20.8).
- **The switch.** `client/scripts/screen_switch.gd` (`ScreenSwitch.make`) draws key frame 05's switch from the kit's materials alone:
  - a pill track, green when on and dark plate when off;
  - a parchment knob, at the right end when on and the left end when off.
  
  It takes no taps; the row is the control.
- **Text size.** §20.8's text size is key frame 05's card:
  - a small A and a large A on parchment, either side of the size in the kit's baked figures (`KitNumerals`, `num_gold`, in the `number_m` role: 22 points at 100%);
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

`tools/ui_bake/guard.sh`: OK. The budget shots (`screen_meta.gd`, `SCREEN=settings`, on the opening Game tab) read 48, 41 and 48 draw calls for settings at 100%, 200% and high contrast, against 52, 47 and 52 recorded (on the gate's fixes, below; 48, 40 and 48 on AD's S3-R7 fixes). Before the self-check fixes it read 46 at 100%; the fixes' strokes brought it to 52 (on 9242f955), and with an outlined drop it read 55. The headings' plates, which drop the headings' outlines, bring it to 48. The falls are for K1 or the lead to `--record`. No word is below 4.5:1; the worst word reads 9.37:1, and 5.94:1 in high contrast.

### The advisory self-check, and the fixes

Before the gate request, an advisory self-check against the gate's three items (one isolated judge per item, on the stills of 1b22adc4) passed 2 of 6 qualities. What it found, and what changed in `settings_screen.gd`:

- **Display type, at 100%.** The group headings had no ink outline, unlike the key frame's, and the "100%" read flat. The headings and the title now wear the T2 stroke; "100%" is gold_top with a 2.5-point outline and the gold drop.
- **Display type and hierarchy, at 200% in pt_BR.** The law sample filled most of the screen, and its last line was cut. Its words now stop at two lines with an ellipsis.
- **Colour roles and value, in high contrast.** The open tab, the two As and the current step's dot were gold, beside the main actions' gold (§21.8). The open tab is now the kit's chosen segment for parchment, and the current dot plate. The As went to leather first, but leather on the violet card reads ΔL* 8 (`checks.py value-steps` fails it in en and pt_BR), so they are on parchment, as the tabs and the switch rows: ΔL* 76, and 95 in high contrast.

### AD's preview (S3-R7), and the answers

AD previewed the stills of f5719f28 (`status/AD.json` on `claude/ui-ad`, S3-R7) and sent six objections in one round. They are listed here in AD's order of weight. AD let these stand: the cream As, the dark chosen tab, the sentence-case tabs, and the pt_BR coins three to a line.

1. **The title at 200% must grow with the text and stay the largest word.** Done in 917886c4: the title is 1.3 times the body text's size (1.5 since the gate on eed8b817, below).
2. **The headings need the display outline of at least 1.5 points, or the tag plate.** Done in 917886c4: each heading is on its own dark plate.
3. **The ground ramp is reversed: the foot should be the darkest, #0B0621 as in key frame 05.** Not changed here. The night gradient is §21.2's linear ramp (night_top #171046 to night_bottom #2C3AA8). The owner chose it over the designs' radial ground in C75 (closed 4 November, answer A). It is drawn by `UI.frame` in `ui.gd`, which is not this task's file. A change would be the owner's decision first, then K1's work. The headings no longer stand on the ground (point 2), so their legibility does not depend on it.
4. **At 200% in pt_BR, the Stillness card should hold the whole law, and the list should end on a row's edge or show a scroll cue.** The two-line ellipsis is gone, and the sample shows the whole law at every size. The sample's padding, line spacing and icon (32 points, was 40) are tighter to make room. The list's window now ends on a whole row's edge (`_snap_list`). The rows' own chevron (the kit's `hud/next`, turned down) stands in the gap below that edge while more rows lie below. Where no edge fits within 48 points (at 200%, the text card is taller than what is left), the window cuts through the row above the cue: the Stillness card shows whole, and its violet card runs on below it. There is no fade. A screen draws no chrome of its own: a `GradientTexture2D` fade raised `check_screens.py`'s texture count from 0 to 2. The kit has no scroll cue (S3-R8 asks K1 for one).
5. **At 100% and in high contrast, the Motion switch should clear the dock.** At 100%, Stillness's law now fits on two lines (the text card is trimmed). The window ends under the High contrast row, and the chevron says more lies below. Motion is the next row, a scroll away.
6. **The gold "100%" should be a step below the title.** It is 24 points, against the title's 28, and its outline is 2 points. (Since the gate on eed8b817 it is the kit's baked figures at 22 points, below.)

AD said it will re-check only what changed: items 4 to 6, and 1 and 2 from 917886c4.

### The gate on eed8b817, and the fixes

The lead's gate on eed8b817 (`docs/art/ui-quality/gate/verdicts/P2-S3-settings/`) failed Display type, at 100% and at 200% in pt_BR, on one word: the text-size readout. It was a flat gold label with a thin outline, where key frame 05's figures are the kit's baked numerals. Hierarchy passed at 200% in pt_BR, but narrowly: the title stood only a little above the groups' headings. The fixes, in `settings_screen.gd`:

- **The readout is the kit's figures.** `KitNumerals.make` with the `num_gold` finish (kit-spec section 3, T3): a cream-to-gold fill, an ink outline that scales with the figure, and a hard drop. It sits in the `number_m` role: 22 points at 100%, a step below the 28-point title, and the body's size at large text. The shot's record names the control by its figures ("100%", "200%").
- **The title leads further at large text.** `TITLE_LEAD` is 1.5, was 1.3: at 200% the title is 48 points against a heading's 35.2. At 100% nothing changes, since 16 × 1.5 = 24 is under the title's 28.

The four stills were re-rendered with `FIT=1 RECORD=1`, and each printed `fit ok` (the 200% en still too). `checks.py all`: no FAIL, and value-steps passes every control. `gdlint`, `check_screens.py` and `guard.sh`: OK. The client tests read 382 ok; the not ok all need the server. The budget shots read 48, 41 and 48, against 52, 47 and 52; the worst word is 9.37:1, and 5.94:1 in high contrast.

### The gate on f0a36a41, and ready

The lead's advisory gate on f0a36a41 (`docs/art/ui-quality/gate/verdicts/P2-S3-settings/f0a36a41.json`) passed all six rows: Hierarchy and Display type at 100%, Display type and Hierarchy at 200% in pt_BR, Colour roles and value and Hierarchy in high contrast. Hierarchy at 100% passed narrowly, three fails of six: the fails held that the dark group-heading plates weigh less in grayscale than the bright cream rows. That is listed below as still worse.

Main was merged into the branch at eb692c67, with no change to the settings screen's files or the kit it uses. On that merge the setup line and `bash client/build.sh` exit 0, `check_all.sh` passed ("All checks passed.", 18:49:12Z on 15 November), and `guard.sh` is OK, the settings budget shots reading 48, 41 and 48 against 52, 47 and 52 recorded.

### Board 5's objections (P2-S3-settings-2)

AD's board 5 (`docs/art/ui-quality/gate/boards/board-5.md`) raised three objections on the settings screen: C (the fold at 100% text), E (German at 200% text) and F (hierarchy at 100%), AD-R33, AD-R35 and AD-R36 in `docs/progress/requests.md`. Each is answered in `client/scripts/settings_screen.gd`, with no change to the kit.

- **C: the first screen at 100% text.**
  - **English** shows both switch rows, High contrast and Motion, above the dock, as key frame 05.
  - **Portuguese and German** show the second section's heading and its first switch row, High contrast, above the dock. The pt_BR key frame (`05-settings_pt_BR.png`) shows the same one row; the board's "both switch rows" reads more than it holds. Motion is the next row, below the chevron.
  - **How.** The vertical padding is tighter: the title plate (4 points, was 7), the group heading pills (2, was 4), the switch rows (48 points tall, the kit's control size, was 52, with 5 points of padding, was 7), the text card and the law's card, and the shapes card (6, was 10, with 4 points between its rows, was 8). Where the shapes stand three to a line (pt_BR, de), a coin's rim is 3 points, not 4, and its name sits right under it; where a coin and its name fit side by side in a column, they stand so.
  - **The dock.** The back button, not its glass bar, keeps the corners' lift (`ScreenNav.CORNER_LIFT_POINTS`, 20 points), as a ScreenNav dock's buttons do: the bar's own 10-point foot counts toward it. The button is the kit's 48 points tall (was 56). The back button's lower edge stays above the layout check's corner band.
- **E: German at 200% text.**
  - **The title** wraps between words only. A word too long for the title's row ("Einstellungen") shrinks the title until it fits, rather than breaking it. It stays well above a group heading.
  - **The gear** grows with the title at large text, 1.4 times, as key frame 05's does at 200% (the board's note on item 8).
  - **The Stillness card** shows the whole law at 200% in German, as in English and pt_BR.
  - **A switch row** keeps its icon where its longest word, on or off, fits beside it. Where one does not ("verschwinden"), the row drops the icon rather than break the word; the words and the switch still say it all.
  - **The steppers' wells** hug their icons at large text (4 points, was 7), so "Hinweise" on the game tab keeps whole beside its icon.
  - **The scripted fit check** is `docs/art/shots/menu-screens/fit_settings.sh`. It renders the access tab at 100% and 200% text in en, pt_BR and de, and in high contrast in en and pt_BR, and the game and account tabs at 200% in German, with `FIT=1`. It fails unless every shot prints `fit ok`. `FIT=1` in `client/tests/shots/screen_settings.gd` now also fails a word broken in two, and checks a wrapped button by its widest word. All twelve shots print `fit ok` (ten before I).
- **F: hierarchy at 100% text.** The small A and the large A are gold, as key frame 05 has them, in high contrast too (`05-settings_hc.png`). The text size is the access tab's main action. On the access tab nothing else is gold, so the As lead in the squint. The ΔL* that value-steps measures on the As is 57 and 58 against the violet card at 100%, and 75 in high contrast.

- **I: the account tab's heading (AD's preview, S3-R17).** AD held C, E and F as fixed at 60560762, and on its full-list check (M23) raised I: the account group was headed by `AuthPanel`'s small gold caps label ("ACCOUNT", "KONTO"), where every other group on the screen has the header pill. The settings screen now heads the account group with its own header pill (`_section("AUTH_TITLE")`, the panel's own words), and hides the panel's caps label, its first child, each time the panel draws itself again (`_hide_kicker`). `auth_panel.gd` is not this task's file and is unchanged. The other screens that use `ScreenParts.section` keep the caps label. `fit_settings.sh` now also renders the account tab at 100% in English and German.

#### Evidence

The stills and records are in `docs/art/shots/menu-screens/`, rendered on the board-5 code with the command below and the table's env set. Every still printed `fit ok`.

```
[env] FIT=1 RECORD=1 bash tools/render/shoot.sh client/tests/shots/screen_settings.gd <still>
```

| Still | Env | Record |
|---|---|---|
| `settings-100.png` | – | `.shot.json`, 13 controls |
| `settings-pt_BR.png`, `settings-de.png` | `LOCALE=pt_BR`, `LOCALE=de` | `.shot.json`, 12 controls |
| `settings-200-pt_BR.png`, `settings-200-de.png` | `TEXT=200 LOCALE=pt_BR`, `TEXT=200 LOCALE=de` | `.shot.json`, 9 controls |
| `settings-hc.png` | `HC=1` | `.shot.json`, 13 controls |
| `settings-hc-pt_BR.png` | `HC=1 LOCALE=pt_BR` | `.shot.json`, 12 controls |
| `settings-account-100.png`, `settings-account-de.png` | `TAB=account`, `TAB=account LOCALE=de` | `.shot.json` |

`settings-de`, `settings-200-de`, `settings-hc-pt_BR` and the two account stills (for I) are new. The 100% records hold one control more than before: Motion's row in English, and High contrast's in pt_BR and German.

`python3 tools/ui_gate/checks.py all` passes on the seven access-tab records, with no FAIL. On the two account records, the tabs and the back button pass, and one control fails value-steps: the profile row ("Profile and stats"), whose dark violet card stands 3 ΔL* off the night (0.3 value steps of the 2 needed). It is `ScreenAccount.profile_row`, in `screen_account.gd`: not this task's file, and unchanged since before board 5. It is asked of the lead (S3-R18). Hud-share passes, and hierarchy reads N/A, as before (the record names no primary). The ΔL* that value-steps measures:

| Still | Tabs | As | Switch rows | Back |
|---|---:|---:|---:|---:|
| 100%, en | 78 | 58 and 57 | 69 and 68 | 84 |
| 100%, pt_BR and de | 80 | 58 and 57 | 67 | 84 |
| 200%, pt_BR | 55 | 59 and 59 | – | 79 |
| 200%, de | 58 | 59 and 59 | – | 79 |
| High contrast, en | 91 | 75 and 75 | 77 and 76 | 96 |
| High contrast, pt_BR | 91 | 75 and 75 | 75 | 96 |

`bash tools/check_screens.sh` passes, and `bash tools/render/build.sh` exits 0. `bash tools/check_all.sh` passed ("All checks passed."), and `bash tools/ui_bake/guard.sh` is OK: the settings budget shots read 48, 41 and 48 draw calls against 52, 47 and 52 recorded, and the worst word is 9.37:1, and 5.94:1 in high contrast.

#### What still differs from the key frame

- **The dock's height above the foot.** The back button stands higher than key frame 05's. Its lift is the corners' 20 points over `ui.gd`'s bottom margin of 44 points (`safe_top_points`), which is K1's (board 5's note). The layout check's corner band holds the button at least 62 points above the screen's foot, so it can come down only a little.
- **Motion's row in pt_BR and German at 100%.** It is below the chevron, as on the pt_BR key frame. The German words are longer still.
- **The selected tab** is the kit's dark brown, where key frame 05 shows gold. It is the kit's, consistent across screens, and keeps one gold lead per screen (K1, board 5's note).
- **English content.** "Stillness" and its law are English in pt_BR and German. This is content localisation, for the lead, not the screen's work.

#### The gate at 5fc97aac: Hierarchy failed

The lead's gate at 5fc97aac (`docs/art/ui-quality/gate/verdicts/P2-S3-settings-2/5fc97aac.json`) passed Display type and failed Hierarchy, at 100% (4 fails of 6) and at 200% pt_BR (5 of 6). The screen has no main action, so its title must be where the eye lands first in the squint, and the judge saw the full cream tab strip and the cream Stillness card first, with the dark heading plates weighing less than the rows under them. Each of its notes, answered in `client/scripts/settings_screen.gd` with the kit's materials and type roles only:

- **"Lift the title plate's value or weight."** The title is in the kit's hero role (34 points, 48 at 200%), not the title role's 28, on the lit feature card (`card_gold`: the violet glow with the gold rim) where it had the dark plate.
- **"Give the headers more weight than the rows."** The group headings are 22 points, a step over the 16-point rows and the heading role's 20, in the gold top that `ScreenParts.section` gives its kickers, with the display type's ink stroke. Their plates stay dark.
- **"Quieten the tab strip."** The strip is the kit's segment track for light segments (`seg_track_light`, the build tray's deeper parchment, #EBDDBE to #E0CDA4) with the kit's clear light tabs (`seg_light`), a step under the cards' cream. The night's dark track (`seg_track`) was tried first: it failed value-steps (row 2 at 0.5 steps off the night, needs 2), and the leather plates are as dark, so the light track is the only kit strip that passes.
- **"Quieten the Stillness card; at 200% shrink or darken it."** The law's sample is on the dark plate (`plate_dark`), not parchment: it is prose, not an action, and a cream card larger than the title drew the eye first.
- **Tried and dropped:** the toggle rows on the dark card. The switch's off track is the dark plate and vanished on it, so they stay parchment.

Evidence: the nine stills and records are re-shot (`settings-100`, `-pt_BR`, `-de`, `-200-pt_BR`, `-200-de`, `-hc`, `-hc-pt_BR`, `-account-100`, `-account-de`). `checks.py all` has no new FAIL on them; the only FAIL is the account profile row, `screen_account.gd`'s (S3-R18). `fit_settings.sh` prints `fit ok` for all twelve shots. In grayscale the title on its lit plate, the gold headings and the gold As lead; the cream switch rows stay bright, which the notes did not ask to change.

### What is still worse than before

- **The switch rows.** In grayscale the cream switch rows still weigh about as much as the headings above them. The switch's off track vanishes on a dark card, so they stay parchment (above).
- **The tab and back words.** Key frame 05 sets them in capitals. The screen keeps the kit's sentence case (`Tokens.type_role`). Capitals would be a change to the kit's type roles, which is K1's work.
- **The shapes in pt_BR.** At 100% text, the longer Portuguese names (Movimento, Matéria) put the six coins three to a line, not the key frame's six in one row.
- **The fold at 200% text.** The whole law shows, but the text card runs past the window, the colour-blind card and the switches are below the fold (`SCROLL`), and the cue is a chevron with no fade, until the kit has a scroll cue (S3-R8).
- **The ground.** Key frame 05 darkens towards the foot. The screen keeps §21.2's ramp, which lightens towards the foot, as decided in C75 (point 3 above).
- **The law's words.** They are the content's, and they are English under pt_BR ("Stillness", from `content/ruleborn.json`), as on the character screen. This is not this task's work.
