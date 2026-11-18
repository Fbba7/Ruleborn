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

### The tab kept for the session (P3-S3-settings-3, AD-R52)

- **What changed.** Settings opened on the game tab every time, so a player who had just set larger text on the access tab came back to the game tab. It now reopens on the tab last chosen in this session (game, access or account). `SettingsScreen.last_tab` is a `static var` on the script, set when a tab is chosen. It lives in memory only and is never written to Settings' file, so a fresh start opens on game. The router and the app's store are untouched (S2's and the app's files), so this needed no request outside the task.
- **The tab columns are named** `TabGame`, `TabAccess` and `TabAccount`, so a test can tell which one is shown. No shot record names them, and the eleven records re-shot are byte-identical.
- **The mount test** is `client/tests/settings_tab_tests.gd`, called from `run.gd` in one line, because `run.gd` stands at gdlint's 1000 lines (S3-R42, as K1-R24 to K1-R26 did). Through the router it opens settings and finds game shown. It then chooses access with the tab's own button, goes home, opens settings again and finds access shown, and does the same for account. Settings' file holds no tab. Without the line that keeps the tab, the test fails ("opened on game, game, game"), so it tests the change.

Evidence: client tests 436 of 436. Every settings still was re-shot with the change, and it renders pixel-identical to main's `settings_screen.gd` in all four stills compared (100%, 200% German, high contrast, and the signed-in account tab at `SCROLL=1800`). Each shot sets its tab in a fresh process, so the stills cannot show the change. Five of the committed stills were already identical. Nine were stale against main, and are re-shot. Both of their changes are K1's P3-K1-polish-1 (`97ab424e`), not this task's:

| Still | What moved | Why |
|---|---|---|
| `settings-100`, `-pt_BR`, `-de`, `-hc`, `-hc-pt_BR` | the text size readout ("100%") a little softer | numerals mipmapped |
| `settings-200-pt_BR`, `-200-de` | the same, on "200%" | numerals mipmapped |
| `settings-200-de-account-signed-900`, `-1800` | the device cards keep their violet face when scrolled | a scrolled panel keeps its face |

The records and every other pixel are unchanged. `fit_settings.sh` prints `fit ok` for all 23 shots. `check_screens.py` and `guard.sh` pass.

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

### Board 5b's objection K (P2-S3-character-3)

- **K: the highest level at 200% text.** At its highest level the tray's dark pill (`CHARACTER_TOP_LEVEL`, "at the highest level") held its words on one line. At 200% that line is wider than the phone ("auf der höchsten Stufe", 987 px of words in 900), and the pill pushed the whole screen wider: the next arrow, the subtitle, the tabs and the info grid ran off it. The pill is now built by `_top_level` in `client/scripts/character_screen.gd`. At large text (`_large()`, as H's state pill) it takes the tray's width beside the way back, as Level up does, and its words wrap between words inside it, never inside one word, centred beside the star. At 100% it is the one-line pill as before. Its `accessibility_name` carries the words at every size.
- **Why wrap, not the star alone.** AD offered both. The state pill went icon-only for H because it stood on the character's face. This pill stands in the tray, where there is room: a reader who chose large text still reads "at the highest level" there, not a star whose meaning only a screen reader says.
- **The fit check** covers character 4 now. `fit_character.sh` takes an optional third field, the fixture's `ID`, and renders character 4 (Mossbear, level 10 of 10) at 200% in English, pt_BR and German. All eleven shots print `fit ok`. On the code before this fix, the German shot of character 4 at 200% printed `fit FAIL` (the info grid's labels past the screen's edge), so the check catches K.

#### Evidence

The stills and records are in `docs/art/shots/menu-screens/`, rendered with `FIT=1 RECORD=1 TEXT=200 LOCALE=<locale> ID=4 bash tools/render/shoot.sh client/tests/shots/screen_character.gd <still>`. Each printed `fit ok`.

| Still | Arrows | Tabs | Back |
|---|---:|---:|---:|
| `character-200-en-4.png` | 58 and 56 | 62 | 77 |
| `character-200-pt_BR-4.png` | 58 and 56 | 61 | 77 |
| `character-200-de-4.png` | 58 and 56 | 60 | 77 |

The table gives the ΔL* that `checks.py value-steps` measures. `checks.py all` passes on the three records, with no FAIL. In all three the next arrow, the subtitle ("Mossbear · Wächter" whole) and the tabs are on the first screen, the info grid below them is within the phone's width (the fit check), and the pill reads on two lines in English and pt_BR and three in German. The other character stills are unchanged. Their fixtures (character 5, and 1 to 3) are not at the highest level, and at 100% and in high contrast the pill is built as before.

### The gate's display-type check at a6d5f2fb (P2-S3-character-4)

The gate's advisory verdict on P2-S3-character-3 (`docs/art/ui-quality/gate/verdicts/P2-S3-character-3/a6d5f2fb.json`) failed "character at 200% text, pt_BR" on display type, five samples of six. The subtitle ("Skyskipper · Carregador") and the level line ("Nível 3 de 10") on the starry backdrop showed a dark edge down and right only, thin to nothing on the top and left. The flat gold HABILIDADE header also differed from the stroked "Subir de nível" header of the same rank.

- **What changed on those labels between 6b7e6b42 and a6d5f2fb: nothing.** The committed still `character-200-pt_BR.png` is the same file at both shas (no pixel differs). Between the two, `character_screen.gd` changed only in `_top_level` (board 5b's K), which builds the tray's pill on character 4, not character 5. The pass at 6b7e6b42 and the fail at a6d5f2fb are two judgments of the same pixels. The treatment was marginal, and this fix makes it unambiguous.
- **Why it read as a drop.** At large text `_over_stage` set `outline_size` to the greater of 3 points or 12% of the words' size. Godot's `outline_size` spans both sides of a glyph's edge, so that was about 6% a side, half of §21.8's 12%. The 2-point drop below then outweighed it at the foot of the letters, and the top and left edges were a pixel wide in the half-size still.
- **The fix.** `_ink_large` in `client/scripts/character_screen.gd` sets the outline at §21.8's least a side: 1.5 points or 12% of the words' size, whichever is more (`OUTLINE_POINTS`, `OUTLINE_SHARE`), so `outline_size` is twice that. For the 16-point subtitle at 200% (88 px), that is 21 px against 11 before. For the 14-point level line (77 px), it is 19 against 9. When `_wrap_in` shrinks the words to fit, it sets the outline again from the size shown. The drop stays as it was: 2 points, in ink. At 100% text the backdrop's words keep `ScreenKit.inked`, as before.
- **HABILIDADE.** At large text, the ability card's kicker is stroked and dropped in ink as Level up's title is (`_stroke`, display_s's outline × 1.5 and its drop), keeping the top gold that S3-R4 gave it. Level up's title now uses the same `_stroke`, with the same values as before. At 100% the kicker is as before, so "character at 100% text" sees the same pixels.
- **The dock and the last card.** At 200% text, scrolled to the end, every tab's last card stands clear above the Level up dock in English, pt_BR and German (nine renders, `TEXT=200 LOCALE=<locale> TAB=<0..2> SCROLL=99999`). The scroll's foot already leaves the dock's height under the column. The hierarchy samples that saw the ability card clipped by the dock looked at the first screen, where it runs on under the dock as scroll content (key frame 04's header band does the same).
- **A kit defect found on the way (S3-R32).** On the Stats tab at 200% in English and pt_BR, scrolled to the end, the parchment behind the tiles and their note is not drawn once its top has scrolled off the screen. The note's dark-brown words then stand on the night backdrop. It shows at SCROLL=1600 and after, and not at 1400. It shows on main without this task's change too, and German's shorter page is not affected. The parchment is the kit's box (`client/ui/rb_box.gd`, K1's), so it goes to K1 through the lead. No committed still shows it.

#### Evidence

Rendered on this task's code with `FIT=1` (and `RECORD=1` for the recorded ones) and the env in Part 2's tables. Every still printed `fit ok`.

- **Changed:** `character-200-pt_BR.png`, `character-200-en.png`, `character-200-de.png`, `character-200-{en,pt_BR,de}-4.png`, and `character-200-pt_BR-stats.png` and `-compare.png`. Only the subtitle, the level line and (on the Heist tab) the ability's kicker differ. Their records are unchanged, and `checks.py all` passes on the six, with no FAIL and the same ΔL* as before. The draw calls at 200% are 69, against 66.
- **The same pixels as before:** `character-100.png`, `-100-pt_BR`, `-100-de`, `-100-stats`, `-100-compare`, `character-hc.png`, `-hc-pt_BR` and `character-200-pt_BR-scrolled.png`.
- **Fit check:** `fit_character.sh` (lesson M26, every fixture state): 50 shots of 50 `fit ok` (exit 0).

### The kit's calls, the cream notice and the outline measured (P3-S3-character-5)

K1's polish tasks gave the kit the forms the character screen had built for itself (K1's handoff, `docs/progress/K1.md` on `claude/ui-bake`). This task replaces each local fix in `client/scripts/character_screen.gd` with the kit's call, gives the offline notice the roster's cream plate (AD-R53), and sets the large-text outline at §21.8's least a side, measured in the stills (AD-R58, audit 1's row 14).

- **`_tabs` → `KitNav.segmented(options, tab, _pick_tab, true, true)`** (S3-R9). The last argument asks for the kit's two forms: at 100% each option's icon beside its words on one line, at large text the chosen option's words and the others' icons. `_tabs`, which rebuilt the kit's buttons after the fact, is gone.
- **The ability's measures → `KitCards.ability(…, "", true)`** (S3-R10, S3-R14). The kit's card now has key frame 04's measures: the tag on the kicker's line, the icon's square and the card's padding, and the kicker dropping its tracking when it and the tag do not fit. The screen's separation overrides, its `_untrack_when_tight` on the header and its `_pad` of the card and the square are gone.
- **`_blend_foot` → `stage.blend_foot = true`** (S3-R11). `StageHero` fades its foot into the menus' night where the stage ends on the screen. The screen's `_blend_foot` and its two connections (the stage's rect, the scroll) are gone.
- **The hex's scaled size → `KitHex.make(kicker, number)`** (S3-R12). The kit's hexagon grows with the text size itself, so the screen no longer passes a size scaled by the text's growth.
- **`_compact` and `_untrack_when_tight` → `KitCards.fact(icon, kicker, words, "", true)`** (S3-R13, S3-R14). The kit's compact fact card is key frame 04's: the disc beside the kicker, the words under both at 13 points in the body face, 6 points of padding, and the kicker untracked when its longest word is wider than the room. Both helpers are gone. The screen loses 146 lines and gains 61.
- **AD-R53, the cream notice.** The status line (the offline notice, among others) stands on `StageHeroSkin.plate`, the roster's cream parchment plate, with its words as `UI.status` sets them (red for the offline alarm), as flow board 2's F7 shows the roster's notice. It stood on a glass plate before. The shot takes `OFFLINE=1` to fail the roster's load as "no server is set" does and show it.
- **AD-R58, the outline measured.** Measured in the renderer the stills use, at 540 and 1080 pixels wide, Godot draws a quarter of a label's `outline_size` outward on each side, not half. So character-4's outline, which set `outline_size` at twice §21.8's least a side, drew about 6% a side, and audit 1 measured about 5% (2 to 3 still pixels on words 38 to 48 still pixels tall). `_outline_px` now sets `outline_size` at four times the least a side (`OUTLINE_PER_SIDE`), with a pixel of the half-size still added for the outline's soft edge (`OUTLINE_EDGE_PX`), so the solid ink measures the least too. The least is 1.5 points or 12% of the size the words render at, read from the label when it is set, after the text scale and after `_wrap_in`'s shrink (which sets it again from the size it shrank to). It applies at large text to the backdrop's words (the subtitle and the level line), to the headline on the stage's art (which wore the plate's ink alone before), and through `_stroke` to the HABILIDADE kicker and Level up's title. Words that are set before they are in the tree set it again when they enter it.
- **A kit-wide finding (S3-R35).** The kit sets some outlines from §21.8's least a side as if `outline_size` were that side: `KitHud._ink` (`client/ui/kit_hud.gd`) returns 1.5 points or 12% of the size, plus half a point, and the HUD passes it to `outline_size`, so those words draw about a quarter of it, near 3% a side; the inventory count in `client/ui/kit_panels.gd` sets 20% of its size, about 5% a side. The contrast check reads it the same way: `_outline` in `client/tests/a11y_tests.gd` (and `_counts` in `client/tests/shots/ui_kit_heist.gd`) counts an outline as all round once `outline_size` reaches the least a side, so it credits outlines a quarter as wide as §21.8 asks. These are K1's and the lead's to weigh; this task changes only the character screen, and its outlines pass that check with room.

#### Evidence

Rendered on this task's code with `FIT=1 RECORD=1` and the env below, against the same renders on 0528ea61 (main 70f7f90c merged, before this task's change). Every still printed `fit ok`.

The outline a side, measured in the half-size stills (540 wide) above the letters' tops: in each column where a letter's light face begins, the run of ink pixels above it (luminance under 32 over the starry backdrop), median and least of the columns. At 200% the subtitle renders at 16 points × 2 = 96 window pixels (48 in the still) unless `_wrap_in` shrinks it, and the level line at 14 × 2 = 84 (42); the outline is read from the size shown, so a shrunk subtitle's share is higher, not lower.

| Still (200%) | Subtitle before | Subtitle now | Level line before | Level line now |
|---|---|---|---|---|
| `c200-pt_BR` | 3 (least 2): 6% | 6 (least 6): 12.5% | 3 (least 2): 7% | 6 (least 6): 14% |
| `c200-en` | 3 (least 2) | 7 (least 6) | 2 (least 2) | 6 (least 6) |
| `c200-de` | 3 (least 2) | 7 (least 6) | 2 (least 2) | 6 (least 6) |

In window pixels, `outline_size` is now 55 on the unshrunk subtitle (12% of 96 is 11.5, plus 2 for the soft edge, times 4) and 49 on the level line, against 23 and 20 before.

- **The same pixels as before (the kit's calls change nothing there):** `c100` (English), `c100-pt_BR`, `c100-de`, `c100-stats`, `c100-compare`, `hc` (English) and `hc-pt_BR`: no pixel differs.
- **Changed, and only in the outlined words:** `c200-pt_BR`, `c200-en`, `c200-de`, `c200-pt_BR-4`, `c200-pt_BR-stats`, `c200-pt_BR-compare` and the three scrolled to 2000 points (`c200-{pt_BR,en,de}-scrolled`, where only Level up's title differs). In each, the pixels that differ are the outline round the headline, the subtitle, the level line, the HABILIDADE kicker and Level up's title; the tabs, the hexagon, the ability card, the facts and the stage's foot are where and as they were. Board 5 still stands: the next arrow, the subtitle, the tabs and the info grid are on the first screen and within the phone's width.
- **New:** the offline notice at 100% in English and at 200% in pt_BR, on the cream plate with its words in alarm red, committed as `character-offline.png` (`OFFLINE=1`) and `character-offline-200-pt_BR.png` (`TEXT=200 LOCALE=pt_BR OFFLINE=1`), each with its `.shot.json`. Before, the same state showed the glass plate with a red fill.
- **Committed (M52, S3-R36).** The nine committed character-200 stills are re-shot on this task's code with the env of Part 2's tables (`RECORD=1` where a record exists): `character-200-{pt_BR,en,de}`, `-{en,pt_BR,de}-4`, `-pt_BR-scrolled`, `-pt_BR-stats` and `-pt_BR-compare`. On main 53e18516 (P3-K1-tabs-1 merged) the 200% and offline stills render byte for byte as committed here. The 100% and high-contrast stills (`character-100`, `-de`, `-pt_BR`, `-stats`, `-compare`, `character-hc`, `-hc-pt_BR`) are re-shot too: they differ from the committed files (last shot on 16 November) only in Level up's cost, "200" (a box of 68 by 36 px), whose outline is thinner. Rendered with main's own `character_screen.gd` and shot script, the same still is pixel for pixel the new one, so the change is main's kit since those files were shot, not this task's; their records are unchanged. Every shot printed `fit ok`, the records of the seven recorded ones are unchanged, and `checks.py all` passes on them and on the two offline records, with no FAIL. Against the committed files, only the outlined words differ, except in `character-200-pt_BR-scrolled.png`: the committed one was older than main's code before this task, which already showed the ability card on the kit's dark plate and the column's parchment drawn behind the facts once its top has scrolled off (K1's kit work on main; S3-R32's defect no longer shows). This task's own change there is Level up's title alone. The Part 2 table's draw calls are the older ones; at 200% they are now 69 to 70 (44 scrolled), offline 87 at 100% and 71 at 200%.
- **The offline notice at 200%** takes four lines in pt_BR on its plate and pushes the screen down, so the tabs are below the first screen in that state. Board 5's claim (the next arrow, the subtitle, the tabs and the info grid on the first screen) is about the screen as it opens, without the notice, and still stands there.
- **Draw calls** at 200% in pt_BR are 70, against 69; at 100% and in high contrast 91, as before; the offline still at 200% in pt_BR, 71.
- **Fit check:** `fit_character.sh` (lesson M26, every fixture state): 50 shots of 50 `fit ok` (exit 0).

### ScreenNav's back, the roster kept, and the offline notice as information (P3-S3-nav-1)

AD's navigation audit found the character screen's back was its own parchment chevron, the roster forgot where it stood when the player came back to it, and "no server is set" read as an alarm. This task gives the character screen `ScreenNav.back_button`, keeps the roster's state across the visit, and sets the offline notice as information.

- **AD-R50, one back.** The character screen's bottom row ends in `ScreenNav.back_button(&"roster")`, the back of every screen on `ScreenNav`'s dock (law, profile, share, shop, social, track, weaving and workshop; `after-profile-100.png` shows it): the kit's icon button (`KitNav.back`), maroon leather with its gold rim, 52 points, named "Back" ("Voltar", "Zurück"), in place of the cream parchment chevron of 56 points named after the roster. The screen wraps it so the button goes to the roster with the roster's kept state (below); its look and its name are the kit's. Level up, beside it, takes the 8.67 points the narrower back leaves (in the records, x 97.5 → 88.83, width 264.33 → 273).
- **The mount test (AD-R50).** `client/tests/run.gd` opens every route of `Router.ROUTES` that is not a tab through the router, finds the buttons that carry `ScreenNav`'s "back" meta, asks for exactly one on each, presses it and checks the router lands on the route's back route. Fourteen routes have no back yet (`NO_BACK` in `run.gd`, S3-R38): heist, result, age and first keep none by design; the other ten are their owners' screens and move onto `ScreenNav` in their owners' tasks. The test covers the ten routes that have one.
- **AD-R51, the roster kept.** The roster hands the character screen what it showed (`RosterScreen.kept()`: the chosen character on the stage, the filter and the scroll), the character screen carries it through its prev and next arrows, and its back hands it back. The roster restores the chosen character and the filter at once, and the scroll once the list has its height (up to four frames). A mount test in `run.gd` scrolls the roster, chooses a character, opens one, goes back and asks for the same scroll and the same chosen character.
- **AD-R63, information, not alarm.** `ERR_OFFLINE` ("no server is set") is set with `UI.set_status(status_label, "info", …)` on the roster and the character screen (`RosterScreen.plain`), so it shows in the info ink with the ⓘ glyph on the cream plate. Red with "!" stays for real refusals (`RosterScreen.failed` keeps `"error"` for any other code).
- **AD-R64, one line at large text.** At large text the offline notice is one line: `RosterScreen._one_line` shrinks its words until they fit the plate's width, no smaller than the body's 100% size, and sets the full sentence as the label's `accessibility_name`. In pt_BR at 200% that is about 122% (S3-R39: the shrink stays unless the words are shortened in `client/i18n/strings.csv`, which this task does not own). *Superseded by P3-S3-offline-1 (below): the words are shortened and the shrink is gone.*
- **The record.** `screen_character.gd`'s record names the back by `ScreenNav`'s "back" meta, so it reads "back 5: Back" ("back 5: Roster" before), rather than "button 5".
- **Settings is not on `ScreenNav`'s back.** Flow board 2's F4 says settings uses `ScreenNav.back_button`, the dock's "« Back". It does not: `settings_screen.gd` builds its own labelled parchment "« Back" (with the "back" meta, so AD-R50's test counts it). The character screen now wears what the other `ScreenNav` screens wear, the icon button, not settings' labelled one (S3-R40 asks AD which it wants).

#### Evidence

Rendered on this task's code with `FIT=1` (and `RECORD=1` for the recorded ones) and the env of Part 2's tables, against the committed stills. Every still printed `fit ok`.

- **Changed, only in the bottom row:** every character still not offline (`character-100`, `-100-de`, `-100-pt_BR`, `-100-stats`, `-100-compare`, `character-hc`, `-hc-pt_BR`, `character-200-{en,pt_BR,de}`, `-200-{en,pt_BR,de}-4`, `-200-pt_BR-scrolled`, `-200-pt_BR-stats`, `-200-pt_BR-compare`). The parchment chevron becomes `ScreenNav`'s back and Level up widens by its difference; the stage, the tabs, the hexagon, the cards and the facts are where and as they were. Board 5 stands: the next arrow, the subtitle, the tabs and the info grid are on the first screen and within the phone's width.
- **Changed, the notice:** `character-offline.png` (100%, English) shows the notice in the info ink with ⓘ, not red with "!". `character-offline-200-pt_BR.png` shows it on one line, not four, so the tabs are back on the first screen in that state; the ability card's header is still under the dock there (AD's O2 met in part). Shrunk below 20 points, the notice drops out of that still's record, which lists words from 20 points up.
- **New:** `character-offline-200-de.png` (with its `.shot.json`), `roster-offline.png`, `roster-offline-200-pt_BR.png` and `roster-offline-200-de.png` (`screen_roster.gd` now takes `LOCALE` and `OFFLINE`). The roster's cards at 200% predate this task and are not changed by it.
- **The back's value step (S3-R41).** `checks.py value-steps` fails the new back on every recorded still in standard contrast: its leather face reads L* 23.7 on a ground of 13.6 at 100% English (ΔL* 10.1, one value step; it needs two). The cream chevron it replaces passed. In high contrast it passes. It is the kit's button, the same on the eight other `ScreenNav` screens, none of which has a record, so the check had not met it before. Its gold rim is what parts it from the night. The check is not loosened; S3-R41 asks the lead for a K1 task on `KitControls.icon_button`'s face, and the back stays the kit's meanwhile (AD-R50). The other controls in each record pass as before.
- **Not this task's:** the notice's cream plate draws in the status bar's band, as it did before this task (P3-S3-character-5).
- **Tests:** in `client/tests/run.gd`, AD-R50's mount test passes on the ten routes with a back, and AD-R51's passes. AD-R51's was proved by mutation: with the character screen's back going to the roster without the kept state, it fails ("left as chosen 6, scroll 240, came back as chosen -1, scroll 0").
- **Fit check:** `fit_character.sh` (lesson M26, every fixture state, now with the offline notice at 100% in English and at 200% in pt_BR and de): 53 shots of 53 `fit ok` (exit 0).

### The offline notice at full size (P3-S3-offline-1)

S3-R39 left the offline notice shrunk at large text: "nenhum servidor configurado" did not fit the plate's one line at 200%, so `RosterScreen._one_line` set it at about 122% in pt_BR (and shrank de's "kein Server eingestellt" too). This task shortens the reason and drops the shrink.

- **The words (`client/i18n/strings.csv`, `ERR_OFFLINE`).** en and en_US keep "no server is set". Each language that missed one line at 200% changes to a shorter plain phrase with the en meaning:
  - pt_BR: "nenhum servidor configurado" → "sem servidor";
  - pt_PT: "nenhum servidor definido" → "sem servidor";
  - de: "kein Server eingestellt" → "kein Server";
  - fr: "aucun serveur n'est défini" → "aucun serveur".
  At 100% the whole sentence still shows and wraps as before ("O plantel não mudou: sem servidor"). No other file used the old strings. `node art/ui/keyframes/build_words.mjs` was rerun: `art/ui/keyframes/words.js` comes out byte for byte the same, because the key frames do not use `ERR_OFFLINE`. `check_keyframes.mjs` prints "key frame checks passed" (M34).
- **The shrink is gone (`client/scripts/roster_screen.gd`).** `_one_line` and its `resized` hook are removed. At large text, `RosterScreen.failed` sets the reason alone in the info ink with ⓘ at the player's text size, on one line, with no autowrap. The whole sentence stays the label's `accessibility_name` (AD-R64). The label keeps word trimming so the plate takes the screen's width, not the words' width. `screen_character.gd`'s fit check fails any words that would be trimmed. `character_screen.gd` calls the same `RosterScreen.plain` and `failed`, so it needs no change.
- **The widths at 200% text, full size,** measured in the shot at the render's pixel scale. The plate's label is 924 px wide (333.67 points):

  | language | notice | width |
  |---|---|---|
  | en, en_US | ⓘ no server is set | 829 px |
  | fr | ⓘ aucun serveur | 791 px |
  | pt_BR, pt_PT | ⓘ sem servidor | 725 px |
  | de | ⓘ kein Server | 647 px |

  Before this task, at full size, pt_BR was 1513 px and de was 1182 px. Every language now fits, so the track names none that misses.

#### Evidence

Rendered on this task's code with `FIT=1` (and `RECORD=1` for the recorded stills), using the env of Part 2's tables and of P3-S3-nav-1's evidence. Every character still printed `fit ok`. The roster shot has no fit mode; its three offline stills were checked by eye against main's.

- **Changed by this task, the notice (four stills):**
  - `character-offline-200-pt_BR.png` and `character-offline-200-de.png`: the notice is on one line at full size ("ⓘ sem servidor", "ⓘ kein Server"), no longer shrunk. The plate is 47.67 points tall, and everything under it moves down 10.47 points (the arrows from y 178.39 to 188.86, for example). The tabs and Level up stay on the first screen. At full size the notice is back in both records, as "words 1", so the later entries are numbered one higher.
  - `roster-offline-200-pt_BR.png` and `roster-offline-200-de.png`: the same notice at full size, with the tabs and the card about 13 points lower.
  - Hierarchy in pt_BR at 200% is unchanged: the name, the stage and Level up lead as before, and the notice is one information line in ink on cream.
- **Changed by main, not by this task:** every character still that is not offline (`character-100`, `-100-de`, `-100-pt_BR`, `-100-stats`, `-100-compare`, `character-hc`, `-hc-pt_BR`, `character-200-{en,pt_BR,de}`, `-200-{en,pt_BR,de}-4`, `-200-pt_BR-scrolled`, `-200-pt_BR-stats`, `-200-pt_BR-compare`), plus `character-offline.png` and `roster-offline.png` at 100%. They render pixel for pixel the same on main 14dee6ce's code as on this branch. Their difference from the committed stills comes from main's work since P3-S3-nav-1 shot them: the kit's outline rule and back face (P3-K1-outline-1). Their records are unchanged. The notice at 100% was never shrunk and is the same sentence in en.
- **Fit check:** `fit_character.sh` (lesson M26, every fixture state, including the offline notice at 100% in English and at 200% in pt_BR and de): 53 shots of 53 ok (exit 0). `check_screens.py`: OK. gdlint on `roster_screen.gd`: the same 18 long lines as before the task, none new.

#### AD-R66: the stage gives the notice its height

AD's preview of this task (M59) found that, offline at 200%, the notice at full size pushed the ability header ("HABILIDADE", "FÄHIGKEIT") under the fixed foot with Level up. `client/scripts/character_screen.gd` now makes room for it:

- **The stage gives the notice its height.** In `_refresh`, when the load failed at large text and the notice shows, the stage's height drops by the notice's own height plus the column's gap (`_give`). Everything under the stage then sits where it does online: in pt_BR the tabs are at y 474.5 points in both records, and the ability header is above the foot in en, pt_BR and de. With no notice, or at 100%, `_give` is 0 and nothing changes.
- **The pills give up the status bar's band.** Under the notice the stage is no longer under the status bar, so the count's and state's pills move from 44 points down to 8 points from the stage's top.
- **The arrows centre under the count's pill**, in their own margin below it, not on top of it as they would on the shorter stage.
- **The character is framed a little higher** (the stage's `headroom` is -0.08 there, 0.08 elsewhere), so its face and ears stay clear between the notice and the name's plate.
- **The roster keeps its notice as is** (M59). OFFLINE=1 TEXT=200 in pt_BR and de stays in the stills.

Evidence, rendered with `FIT=1 RECORD=1` on this code:

- **Changed:** `character-offline-200-pt_BR.png` and `character-offline-200-de.png`, with their records. The stage is shorter, the arrows move up from y 188.86 to 157.81 points, and the name's plate moves up from y 232.92 to 154.92, where it is online. In de the tabs are at y 479.92 and the sub-line at 294.31, as online too. The tabs and the ability header come back into view above Level up, which stays where it was. An en render with the same env (not a committed still) shows the same layout with "ⓘ no server is set".
- **Unchanged, pixel for pixel and record for record:** the other 20 character and roster stills, including every online still at 200% (`character-200-{en,pt_BR,de}` and their `-4`, `-scrolled`, `-stats` and `-compare`). So the gate item 'character at 200% text, pt_BR' (Hierarchy) shows the same still as before.

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

- **AD's objection J (S3-R20's preview).** The taller title plate (+9 points) and headings (+3 each) pushed the second group down about 15 points, so at 100% in pt_BR, German and high contrast pt_BR the High contrast row left the first screen and "Visão e conforto" stood alone above the chevron. The title and heading plates now have no top or bottom padding (`PLATE_TOP`, was 4 and 2 points): the display face's own line height leaves room over and under the words. That gives back 16 points, and the row is on the first screen again in all three (`switch-row 11` in their records), with the Hierarchy fixes kept.

Evidence: the nine stills and records are re-shot (`settings-100`, `-pt_BR`, `-de`, `-200-pt_BR`, `-200-de`, `-hc`, `-hc-pt_BR`, `-account-100`, `-account-de`). `checks.py all` has no new FAIL on them; the only FAIL was the account profile row, `screen_account.gd`'s (S3-R18), fixed for board 5b's L below. `fit_settings.sh` prints `fit ok` for all twelve shots. In grayscale the title on its lit plate, the gold headings and the gold As lead; the cream switch rows stay bright, which the notes did not ask to change.

### Board 5b's objection L (P2-S3-character-3)

- **L: the profile row's value step (S3-R18).** `checks.py value-steps` failed the Account tab's "Profile and stats" row at 3 ΔL* off its ground. There were two causes. The row stood on the dark violet card, about the night's value. And the row's tap target, `ScreenParts.tap`'s clear button, sat inside the card's margins. The record takes the control's rectangle from that button, so the ring of ground that value-steps reads fell on the row's own card. A first try put the row on parchment and still failed, at 0 ΔL*, parchment against parchment.
- **The fix**, in `ScreenAccount.profile_row` (`client/scripts/screen_account.gd`). The row is on parchment, the plate the Access tab's switch rows stand on, with the words and the › in parchment's dark ink. A clear wrapper with no margins holds the plate and the tap target, so the target covers the plate edge to edge, as a switch row's button does. The whole plate answers a tap, its rim too, and the record's rectangle is the plate. `screen_parts.gd` is unchanged, so the other screens' items keep theirs.

Evidence: `settings-account-100` and `settings-account-de`, stills and records, are re-shot with `FIT=1 RECORD=1 TAB=account` (and `LOCALE=de`), and both printed `fit ok`. `checks.py value-steps` passes every control on both: the profile row at ΔL* 72.7 in English and 72.2 in German (it was 2.5 and 3.6 on AD's board), the tabs at 71.5 and the back button at 83.6. `checks.py all` has no FAIL, so the Account tab has no failing control left. `fit_settings.sh` prints `fit ok` for all twelve shots.

### Every fixture state in the fit checks (lesson M26, P2-S3-character-3)

Lesson M26 asks that a screen's fit check covers every state the screen shows, at 200% text in English, pt_BR and German. Both scripts now do.

- **`fit_character.sh`, 50 shots.** Character 5 on its Heist tab at 100% in the three languages and in high contrast in English and pt_BR, as before. At 200%, in the three languages, every character of ShotData's roster (1 the lowest level, 4 the highest, 10 of 10) on every tab (`TAB` 0 Heist, 1 Stats, 2 Compare): 45 shots.
- **`fit_settings.sh`, 20 shots.** The access tab at 100% in the three languages and in high contrast in English and pt_BR, and the account tab at 100% in English and German, as before. At 200%, in the three languages, every tab (game, access, account). And the account tab signed in, at 100% in English and at 200% in the three languages (`SIGNED=1`). `client/tests/shots/screen_settings.gd` signs the account in as `auth_panel.gd`'s own shot does: a token, the `signed_in` and `auth_status` actions before the screen builds, then the server's device list (this phone and a nameless Android phone, Game Center and Google Play linked).
- **Why the shot writes a `.fit.txt`.** `tools/render/shoot.sh` keeps only the last 20 lines of a run, and the leaks Godot reports at exit can push the `fit ok` line out of them. So `FIT=1` also writes what it found beside the still (`<still>.fit.txt`), and the scripts read that. Before this, tabs 1 and 2 of the character screen read as failures with no `fit` line at all.
- **The scripts render two shots at once** (`JOBS`, 2 by default) and keep the stills in `OUT` (a temporary folder by default).

**What the new states found.** Every character shot fits, and every settings shot fits but one state: the account tab signed in, at 200% in English and German. There are two causes, both in `client/scripts/auth_panel.gd`, a file no task owns. This task asks the lead for the file in S3-R30.

1. **The signed-in panel never shows its devices or ways to sign in on the settings screen.** `AuthPanel` listens to the store from `_ready` and stops in `_exit_tree`. The settings screen builds its list, then moves the list into a holder for the scroll cue (`_cue`, `settings_screen.gd`). The panel leaves the tree and enters again, but `_ready` does not run a second time, so it never hears the store again. Its Devices and Methods sections, drawn when the device list arrives, never appear. A debug run read the connection as false after the move, and drawing the panel again by hand gave 9 children where there had been 3. This is the app's behaviour too, not only the shot's. The fix: listen again in `_enter_tree` once the node is ready.
2. **The status card breaks its words in two at 200%.** `_status` builds the card with `ScreenParts.item`, the sign-out button beside the words. At 200% German that leaves 217 px for "Angemeldet" (542 px) and "Mit Game Center" (a 258 px word). In English, "Signed in" is a 310 px word in 297 px. The fix: at large text (past 125%), the actions go under the words, the column's width, as the devices' sign-out buttons already do.

`_hide_kicker` (board 5b's round 2, note 5) cannot be checked against the Devices and Methods sections until the first fix is in.

**The fixes (S3-R30 granted in lead cycle 99, `auth_panel.gd` added to the task's exceptions).**

1. **Listening again.** `AuthPanel._enter_tree` reconnects `store.changed` once the node is ready, and draws the panel again on the next frame, so a change that came while it was out of the tree is not lost. On the settings screen signed in, the Devices and Methods sections now show, in the app as in the shot.
2. **The end control under the words.** Past side by side (`KitLayout.SIDE_BY_SIDE_UP_TO`, 125%), every row the panel builds puts its end control under its words (`_item`, `_put_under`): the status card's sign-in, try-again or sign-out, each device's sign-out or its "This device" pill, and each way to sign in's link or unlink. A button is the card's width and wraps its words; the pill sits at the row's start. At 100% and 125% nothing moves.

Once the sections showed, they failed the fit check too, for the same reason as the status card: at 200% in German, "Android-Handy" (670 px) had 193 px beside its sign-out, and "Google" 198 px beside its unlink. The second fix answers them all.

Evidence: `fit_settings.sh` 20 of 20 `fit ok`; `fit_character.sh` 50 of 50. `settings-account-100` and `settings-account-de` (signed out, 100%) re-shot byte-identical. `settings-200-de-account-signed.png` is re-shot, with `-900` and `-1800` (`SCROLL`) showing the Devices and Methods sections; all three `fit ok`.

**Note 5 (`_hide_kicker`), now checkable.** It hides only the panel's first child, the AUTH_TITLE label, so the screen's header pill heads the group. The Devices and Methods sections keep `ScreenParts.section`'s gold caps label ("ANGEMELDETE GERÄTE 2", "ANMELDEWEGE"), not the screen's header pill. They read as subheadings within the account group, a step below its pill, so this task leaves them; making them pills would need `settings_screen.gd`'s `_section`, which this task does not hold. It goes to AD with the new stills (S3-R29's addition).

### Board 5c's objection M (P2-S3-account-4)

- **M: the sign-outs on the account card (AD-R43).** Signed in, at 100%, `checks.py value-steps` failed the leather "Sign out" buttons on the Account tab's cards at ΔL* 16.1 to 17.5, which is 1.6 to 1.8 steps (2 are needed), in English and German. The cause is the card, not the leather. Leather was chosen for the night, where it stands 2.4 steps off. On the dark violet card, whose median L* is about 13, its brown face (about 29) is only 1.7 steps lighter.
- **The fix**, in `client/scripts/auth_panel.gd`. A lesser action that sits on a card takes the kit's tertiary (`ON_CARD`, the `ghost` look, kit-spec K01): the card's own violet, lifted two value steps off it. That covers the status card's sign-out, a device's sign-out and a way to sign in's removal. "Sign out every other device" stays leather, and "Sign out everywhere" stays red. Both stand on the night, not on a card, and both pass (24.1 and 50.6). Board 5c offered two ways to fix it: a lighter face on the card, or the parchment plate. This takes the first, using the kit's own button for it. Parchment would have put a light plate under each device's row and made the sign-outs weigh as much as the profile row.

Evidence: every render printed `fit ok`. `checks.py value-steps`, ΔL* off the card:

| Render | Sign out (status card) | Sign out: Android phone | Remove (a way to sign in) |
|---|---:|---:|---:|
| 100% English (`settings-account-signed-100`) | 32.1 | 31.7 | below the fold |
| 100% German (`settings-account-signed-de`) | 32.5 | 32.1 | below the fold |
| high contrast, English | 32.3 | 32.3 | passes (`SCROLL=1800`) |
| 100% English, `SCROLL=1800` | – | 34.1 | 32.1 |

Every other control on these records passes too: the tabs at 71.5, the back button at 83.6, and the profile row at 69.2 when scrolled. `settings-account-signed-100` and `settings-account-signed-de` are new stills with their records. `settings-200-de-account-signed` and its `-900` and `-1800` are re-shot. `fit_settings.sh` now also covers the account tab at 100% signed out in pt_BR, and signed in at 100% in English, pt_BR and German. That makes 23 shots, all `fit ok` (at 100% and 200%, in English, pt_BR and German). `check_screens.py` and `guard.sh` pass.

### Audit 2's hierarchy at 100% text (P3-S3-settings-4, AD-R67)

Audit 2 failed the settings screen at 100% text on Hierarchy: in the grayscale squint the two cream switch rows, High contrast and Motion, were the heaviest slabs on the access tab, over the title and the gold As (the bullet "The switch rows" under "What is still worse than before" said as much). The fix, in `client/scripts/settings_screen.gd` (`_toggle`), with the kit's materials only:

- **The switch rows stand dark, with cream words.** As the law's sample has since the gate at 5fc97aac, the rows leave parchment. The gold A / A stay the access tab's one lead (key frame 05, board 5's F). The title keeps its lit plate; the tab strip and Back are unchanged.
- **The dark is the kit's lesser action, `ghost`, not `plate_dark`.** The task asked for the dark plate. Tried first, it failed `checks.py value-steps`: `plate_dark` (L* 17 to 6) sits at the night's value, 7.4 ΔL* off it, 0.7 of the 2 steps needed. `ghost` (the kit's tertiary, K01: the card's violet lifted two value steps, with the gold hairline) is the face `auth_panel.gd` already gives a lesser action on a card (AD-R43, board 5c's M). Its median L* is 44.7, 39.5 ΔL* off the night. In grayscale it reads as a mid-dark slab, well under the As (57 to 58) and the title's lit plate. Its words are the kit's ink on the night (`text_on_night`, #F3EEFF): `budget_shots.py` reads settings at 100% with 0 of 19 words below 4.5:1, the worst 4.78:1 (these rows; it was 9.37:1 with parchment), the same worst as the kit's ghost button on the result screen.
- **The switch's off track.** Off, `ScreenSwitch`'s own track is the dark plate, which vanished on a dark row (why the rows were left parchment at 5fc97aac). On a ghost row an off switch takes the kit switch's off track instead (`chip`, skin `toggle/track_off`, as `KitSwitch` draws it: the glass chip with its gold line), and the parchment knob stands out on it. On it is green, unchanged. `screen_switch.gd` is not changed.
- **High contrast keeps parchment rows.** In high contrast the ghost's face darkens (L* 37.5), and at 200% in German two ghost rows stood 1.7 steps off the night (Bewegung's row at 17.1 ΔL*) where they met. Parchment passes there by far (75 to 83), the high-contrast still's lead is the gold As as before, and high contrast is where bright plates are asked for. So `_toggle` uses `ghost` only when `Settings.high_contrast` is off.
- **The game tab too.** `_toggle` also builds the game tab's slow rehearsals row, so it is ghost now. It passes value-steps at 31.5 ΔL*; as a parchment row on the game tab's card it failed at 6.8. The steppers' six fails on the game tab (6.6 to 10.8, the card behind them) are as before.

Evidence: rendered with `FIT=1 RECORD=1` and the env below, every still printed `fit ok`, and every record is unchanged (the same controls in the same rectangles). `checks.py all` has no FAIL on any of them.

| Still | Env | What changed |
|---|---|---|
| `settings-100`, `-pt_BR`, `-de` | `TAB=access`, `LOCALE=pt_BR`, `LOCALE=de` | the switch rows ghost with cream words; an off switch on the chip track |
| `settings-hc`, `-hc-pt_BR` | `HC=1`, `HC=1 LOCALE=pt_BR` | none from this task (rows parchment); the title's and labels' ink outline (main) |
| `settings-200-pt_BR`, `-200-de` | `TEXT=200 LOCALE=pt_BR`, `TEXT=200 LOCALE=de` | none from this task (the rows are below the fold); the ink outline (main) |
| `settings-200-pt_BR-comfort`, `-200-de-comfort` (new) | `TEXT=200 LOCALE=pt_BR SCROLL=2400`, `TEXT=200 LOCALE=de SCROLL=2400` | the switch rows at 200%, ghost |
| `settings-200-hc-de-comfort` (new) | `TEXT=200 HC=1 LOCALE=de SCROLL=2400` | the switch rows at 200% in high contrast, parchment |

**Changed by main, not by this task:** the high-contrast and 200% stills differ from those committed at effddd03 (P3-S3-settings-3) only on the edges of display words (the title, the tab, the group headings), up to 1.6 thousand pixels in high contrast and 15 thousand at 200%, 51 levels at most at 200%. That is the kit's outline rule merged since (P3-K1-outline-1: the ink keeps its side at twice the points it is given).

`checks.py value-steps`, ΔL* off the ground:

| Still | Switch rows | Tabs | As | Back |
|---|---:|---:|---:|---:|
| 100%, en (`settings-100`) | 39.5 and 39.5 (were 69 and 68, cream) | 71.5 | 57.9 and 57.1 | 83.6 |
| High contrast, en | 77.0 and 75.5 | 90.5 | 75.3 | 96.2 |
| High contrast, pt_BR | 75.0 | 90.8 | 75.3 | 96.2 |
| 200%, pt_BR, scrolled | 28.3 and 24.1 | – | – | – |
| 200%, de, scrolled | 27.2 and 23.1 | – | – | – |
| 200%, de, high contrast, scrolled | 83.3, 79.5 and 76.5 | – | – | 96.2 |

### What is still worse than before

- **The switch rows** (superseded by P3-S3-settings-4, above: the rows are ghost, with cream words, outside high contrast). In grayscale the cream switch rows still weighed about as much as the headings above them.
- **The tab and back words.** Key frame 05 sets them in capitals. The screen keeps the kit's sentence case (`Tokens.type_role`). Capitals would be a change to the kit's type roles, which is K1's work.
- **The shapes in pt_BR.** At 100% text, the longer Portuguese names (Movimento, Matéria) put the six coins three to a line, not the key frame's six in one row.
- **The fold at 200% text.** The whole law shows, but the text card runs past the window, the colour-blind card and the switches are below the fold (`SCROLL`), and the cue is a chevron with no fade, until the kit has a scroll cue (S3-R8).
- **The ground.** Key frame 05 darkens towards the foot. The screen keeps §21.2's ramp, which lightens towards the foot, as decided in C75 (point 3 above).
- **The law's words.** They are the content's, and they are English under pt_BR ("Stillness", from `content/ruleborn.json`), as on the character screen. This is not this task's work.
