# The pilot heist: the heist's screen from the kit alone

Branch `claude/ui-screens-heist`. Step 7 of `docs/art/ui-quality/report.md`: the heist built from the frozen kit contract (`docs/art/ui-quality/kit-spec.md`, sections 6.3 and 6.5) with no chrome of its own, as the test of that contract. What the kit cannot build is a component request to K1, in `docs/progress/status/S1.json`.

The work is in two tasks. Part 1 (P1-S1-pilot-1) is the HUD, `client/scripts/heist_hud.gd`. Part 2 (P1-S1-pilot-2) is the rest of the screen, `client/scripts/heist_screen.gd`.

## Part 1: the HUD

### What was done

`HeistHud` no longer draws anything itself. Before, it built its own surfaces (`RbBox` and `KitSkin` directly, a `StyleBoxFlat` disc, two drawn bars, drawn bells, drawn coins: 3 `draw_*` calls and 2 fills on `check_screens.py`'s count). Now every piece comes from the kit:

| Piece | Before | Now |
|---|---|---|
| Clock | Own cream plate with a gold rim, own red plate | `KitHud.clock(text, alarmed)` |
| Alarm | Own leather plate, drawn bells | `KitHud.alarm(level, 6, title)` |
| Loot | Own leather plate, two drawn bars, a drawn tick | `KitHud.loot(rows, fraction, aim, caption)`; the Vault's cracking is a third row, "Vault N%", at normal text, and a thin `KitBar` beside the `heiststatus/vaultprogress` icon at large text |
| Law chips | Own leather plate, own light disc | `UI.panel("leather")` with `Icons.view` and a `UI.label`; a dark icon on `UI.dress(disc, "icon_disc")` |
| "Laws here" | `FxSkin` label and colour | `UI.label` with `UI.bold_font()` and the `gold` token |
| Realm line | `FxSkin` panel | `KitStatus.hint` |
| Coins flying to the loot | Drawn discs | `Icons.view("heiststatus/lootbag")` moved by the HUD |
| Alarm rising | Own scale tween | `Motion.pop` |
| Bars filling | Set each frame | `Motion.fill` |

The kit's HUD pieces are built whole and have no update call, so the HUD builds a piece again in its place when its state changes (the clock when it turns red, the alarm when its level changes, the loot when a number changes) and only sets the clock's text and the bars' fill between changes.

`check_screens.py` now counts 0 draw and 0 fill in `heist_hud.gd` (recorded 3 and 2; lowering the record in `tools/ui_bake/budgets.json` is K1's).

### Evidence

Stills come from `client/tests/shots/screen_heist.gd`, the same script before and after, with two laws running, a load target and an estimate:

    MANIFEST=1 ESTIMATE=2600 LAWS=bloom,glowing_dark MOMENT=sneak bash tools/render/shoot.sh client/tests/shots/screen_heist.gd out.png
    MANIFEST=1 ESTIMATE=2600 LAWS=bloom,glowing_dark MOMENT=sneak TEXT=200 bash tools/render/shoot.sh client/tests/shots/screen_heist.gd out.png
    MANIFEST=1 ESTIMATE=2600 LAWS=bloom,glowing_dark MOMENT=alarm CONTRAST=1 bash tools/render/shoot.sh client/tests/shots/screen_heist.gd out.png

"Before" is main at `98b199ba`; "after" is this branch. Draw calls the shot script reports for the whole frame:

| Still | Before | After |
|---|---|---|
| Sneak, 100% text | 142 | 145 |
| Sneak, 200% text | 139 | 139 |
| Alarm, high contrast | 142 | 145 |

The HUD's pieces cost three calls more at normal text: the kit's clock, alarm and loot are each a panel with its own labels, where the old HUD drew its bars and bells inside one. The heist's own budget stills (`tools/ui_bake/budget_shots.py`, no load target and no estimate) stay inside their records:

| Budget still | Record | After |
|---|---|---|
| heist/100 | 122 | 121 |
| heist/200 | 116 | 116 |
| heist/hc | 122 | 121 |

A fourth still, the same as the first with `LOCALE=pt_BR`, checks the longest words: the top row fits the phone (the test "every control on every screen" measures it in every language).

Checks run on the last commit of the task: see `docs/progress/S1.md`.

### What is still worse than before

These are what the kit's pieces cannot do yet. Each is a request to K1 in `docs/progress/status/S1.json`, with the default the HUD uses until it is answered.

- **The clock is smaller and has no gold rim.** `KitHud.clock` is a cream pill with 24-point figures; the old plate was larger with a gold rim, as the key frame `02-heist.png`. (S1-R5)
- **The loot panel is wider.** `KitHud.loot` is about 30 pixels wider at 100% text than the old panel, which leaves the law banner a narrower column: "Glowing dark" still takes two lines. (S1-R2)
- **The law chip is composed by the screen.** `KitCards.law_chip` keeps one line and ends a long name in an ellipsis at 300 points, which is wider than the banner's column at 100% text and pushes the clock off the screen at 200%. The HUD composes the chip from `UI.panel("leather")` so the name wraps. (S1-R3)
- **The alarm's count is moved by the screen at large text.** `KitHud.alarm` keeps "Alarm" and "N / 6" on one line, which runs off the phone's edge at 200% text. The HUD moves the count under the word. (S1-R4)
- **The alarm's count turns red through a colour override.** From level 4 the HUD sets the `alarm_text_on_night` token on the kit's number; the kit has no state for it. (S1-R4)
- **Pieces are rebuilt on change.** No update calls on `KitHud.clock`, `alarm` and `loot`. (S1-R1)
- **The loot's rows are moved by the screen.** A label a row is a draw call a row, which took the heist past its record. The HUD moves the kit's rows into two columns, the words and the numbers, and where a row is longer than 90 points ("Restam ~2.600") stands its number closer to its word and then under it. This reaches into the piece's children. (S1-R2)
- **The Vault's cracking is written, not a bar, at normal text.** A second bar with its icon is two draw calls more than the record has. "Vault" borrows the string `REHEARSE_LEGEND_VAULT`. At large text it is a thin bar beside its icon, because a third row stands the panel on the hint. (S1-R2)
- **The caption wraps by the screen's hand**, at 88 points; "Aim" is hidden by the screen when there is no load target. (S1-R2)
- **At 200% text the law chip is tighter than at 100%** (1 point of spacing, a 15-point disc), so "Glowing dark" keeps one line beside the alarm and the loot clears the hint. In English the loot's bottom edge meets the hint's top edge with no gap. (S1-R3)
- **Portuguese at 200% text with two laws and an estimate still runs the loot under the hint.** "Alarme" is wider, the chip wraps, "Restam" stacks and the hint takes three lines. This was not compared with main. The room is the screen's to give (the hint and the lower column are part 2's).
- **"Laws here" is outlined by the HUD**, through the label's own outline settings; the kit has no look for words that lie on the world. (S1-R6)
- **The coin in flight is the loot-bag icon**, not a coin sprite with the kit's motion. (S1-R6)

### Left for other tasks

- `HeistHud._gold_rim` stays: `client/scripts/result_screen.gd` calls it for the haul tile. It reaches into the kit's insides (`RbBox`) and goes when the result screen moves to the kit (step 9).
- `client/scripts/heist_screen.gd` still drew through `FxSkin` and `FxDraw` (the hint, the gait menu, the footer). Part 2 moved them to the kit.

## Part 2: the rest of the screen

The brief is part 1's gate notes (`docs/art/ui-quality/gate/verdicts/P1-S1-pilot-1/5470c4d3.json`): Cast did not lead in grayscale and had no gold, Get out was red while red is the alarm's, the hint was a flat card, the action icons were gone at 200% text, Ash's portrait covered "Pip" at 200%, and the crew rings were told apart by hue alone.

### What was done

| Piece | Before | Now |
|---|---|---|
| Cast | Leather action, as large as Get out | `UI.action(..., "gold")` dressed as the kit's `big_action` (92 × 76 points), the largest control and first in grayscale |
| Get out | Red action | Leather `big_action` (66 × 54 points); red is left to the alarm alone |
| Action icons | Dropped at 200% text | Kept at every text size |
| Hint | `FxSkin` panel, words set directly | `KitStatus.hint` (the kit's dark glass), every message through one setter |
| Entry card's title | `FxSkin` label | `UI.label` heading |
| Gait menu | `FxSkin` panel | `UI.panel("parchment")` |
| Gait pill's word | `FxSkin` label | `UI.label`, 13 points, bold |
| Crew portraits | One ring colour a school; fixed height | A school mark drawn on the rim (a shape, not a hue), the disc in one loop, the height growing with the text (`client/world/fx_portrait.gd`, 19 draw calls, recorded 20) |

**The hint gives room.** At large text, or in a long language, the lower column (hint, crew, hand) can climb into the HUD. The hint now gives way, one step each layout: first it keeps only its first clause ("Tap crew, then ground"), then it hides. The HUD, the crew and the hand never do. A new hint, such as a message or the result hand-off's "Checking…", starts whole again. The room is measured once both columns' boxes are their content's height, after each layout, and not inside the refresh: the shot scripts and the first frame refresh before the containers settle, and a box measured mid-layout reads as no room.

**Messages and the result hand-off.** The errors, the asking line, the offline lines and the two "Checking…" lines of `finish()` all go through the hint's setter. Before, a message could stay cut to an earlier hint's first clause, or stay hidden.

**Ash's portrait no longer covers "Pip" at 200% text.** The taller portraits stand the fifth crew member on a row of their own, with the pause beside it.

### Evidence

Stills: `docs/art/shots/heist-pilot/before-*.png` (this branch at part 1's end) and `after-*.png` (this task's last commit). They use the same script and settings as part 1, in five cases: `sneak-100`, `sneak-200`, `alarm-hc` (high contrast), `alarm-hc-200` (high contrast at 200% text) and `sneak-200-pt` (`LOCALE=pt_BR`).

- **100% text:** the whole hint shows under the hand. Cast is gold and the largest control. Get out is leather.
- **200% text, English:** the hint hides; the HUD's loot ends above the crew row with a gap.
- **High contrast, 100% and 200%:** the kit's flat high-contrast skins: Cast in solid gold, the panels in solid plum, inked rims.

The heist's budget stills (`tools/ui_bake/budget_shots.py`), against the records as K1 re-recorded them after part 1:

| Budget still | Record | Part 2 |
|---|---|---|
| heist/100 | 121 | 117 |
| heist/200 | 115 | 115 |
| heist/hc | 121 | 117 |

Every word reaches 4.5:1. The worst ratios are 6.17, 7.63 and 5.55. `check_screens.py` notes two falls below their records: `heist_hud.gd` (0 and 0, recorded 3 and 2) and `fx_portrait.gd` (19 draw, recorded 20). Lowering the records is K1's (S1-R10).

### What is still worse

- **Portuguese at 200% text still stands the loot's caption on the crew row.** The hint hides, but "Carregar até 80%" still lies over Pip's and Mo's portraits and names, by about 270 pixels on the still. Before part 2 the hint lay over the loot too, so this is better but not clean. The room has to come from the HUD (a narrower loot, K1's S1-R2) or from the lower column (Ash, the pause and the hand in one flow, or one crew row at large text). That is left for the next heist task.
- **At large text the hint hides entirely in English,** so "hold to sneak or run" is not said. The gait pill is not shown at large text either, so holding the ground is the only gait control, with nothing on screen saying so.
- **The gait's feet and the pause are still drawn** (`FxIcons` through `FxDraw`). The kit has no gait or pause icon. (S1-R9)
- **Cast and Get out are dressed by `heist_screen.gd`.** `client/scripts/heist_hand.gd` builds them, but it is not one of this task's files, so the screen dresses them after it builds them. (S1-R8)
- **The clock is still the kit's small flat pill**, with no outline or drop (S1-R5). Crew names and "Laws here" are not outlined by a kit look (S1-R6).
- **Hollow still blends into its purple ring.** The school mark helps colour-vision deficiency but not the portrait's own contrast. The portrait art is not this task's.

### Left for other tasks

- The Portuguese 200% overlap (above).
- `FxSkin.frame`, `camera_row` and `corner_clear` stay. They are the screen's layout, not chrome, and the kit has no frame.

### Stopped here

Part 2 is done and waits on the pre-check and the gate. The checks run on the last commit are in `docs/progress/S1.md`.
