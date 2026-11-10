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
| Loot | Own leather plate, two drawn bars, a drawn tick | `KitHud.loot(rows, fraction, aim, caption)`; the Vault's cracking is a `KitBar` beside the `heiststatus/vaultprogress` icon |
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
| Sneak, 100% text | 142 | AFTER_100 |
| Sneak, 200% text | 139 | AFTER_200 |
| Alarm, high contrast | 142 | AFTER_HC |

Checks run on the last commit of the task: see `docs/progress/S1.md`.

### What is still worse than before

These are what the kit's pieces cannot do yet. Each is a request to K1 in `docs/progress/status/S1.json`, with the default the HUD uses until it is answered.

- **The clock is smaller and has no gold rim.** `KitHud.clock` is a cream pill with 24-point figures; the old plate was larger with a gold rim, as the key frame `02-heist.png`. (S1-R5)
- **The loot panel is wider.** `KitHud.loot` is about 30 pixels wider at 100% text than the old panel, which leaves the law banner a narrower column: "Glowing dark" still takes two lines. (S1-R2)
- **The law chip is composed by the screen.** `KitCards.law_chip` keeps one line and ends a long name in an ellipsis at 300 points, which is wider than the banner's column at 100% text and pushes the clock off the screen at 200%. The HUD composes the chip from `UI.panel("leather")` so the name wraps. (S1-R3)
- **The alarm's count is moved by the screen at large text.** `KitHud.alarm` keeps "Alarm" and "N / 6" on one line, which runs off the phone's edge at 200% text. The HUD moves the count under the word. (S1-R4)
- **The alarm's count turns red through a colour override.** From level 4 the HUD sets the `alarm_text_on_night` token on the kit's number; the kit has no state for it. (S1-R4)
- **Pieces are rebuilt on change.** No update calls on `KitHud.clock`, `alarm` and `loot`. (S1-R1)
- **The coin in flight is the loot-bag icon**, not a coin sprite with the kit's motion. (S1-R6)

### Left for other tasks

- `HeistHud._gold_rim` stays: `client/scripts/result_screen.gd` calls it for the haul tile. It reaches into the kit's insides (`RbBox`) and goes when the result screen moves to the kit (step 9).
- `client/scripts/heist_screen.gd` still draws through `FxSkin` and `FxDraw` (the hint, the gait menu, the footer). That is part 2.

### Stopped here

STOPPED_HERE
