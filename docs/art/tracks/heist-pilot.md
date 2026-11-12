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
| heist/200 | 115 | 114 |
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

## Part 3: board 1's objections (P1-S1-pilot-3)

Board 1 (`docs/art/ui-quality/gate/boards/board-1.md`) raised five objections, A to E (AD-R7 to AD-R11). This part answers them.

### What was done

- **A, the timer in the kit's figures.** The clock is built by `heist_hud.gd`'s `_build_clock`. With the numerals' switch on it uses `KitHud.clock_large` with `KitNumerals`' baked timer figures. The plate's own words are kept for layout and for a screen reader, but `RenderingServer.canvas_item_set_visible` takes them out of the frame, so they cost no draw calls. While the switch is off (`client/ui/kit_families.json` has no `"numerals"` key, on main too), `KitNumerals.make` would hand back live words. On the large plate those words are inked, outlined and shadowed at display size, which costs about five draw calls at 200% text and puts heist/200 over its record. So until the switch is on, the clock keeps `KitHud.clock`, the kit's plain plate. **Objection A is closed only once the switch is on** (S1-R11 to the lead; turning it on is K1's file, not this task's).
- **B, large text in Portuguese.** At large text, the loot spans the full row under the laws and the alarm. The leather is thinner. The clock and the loot plates are tighter (`_tight`: 5 px at the sides and 3 px at the top and bottom above 130% text). Together these end the HUD column above the crew's tray in English and in Portuguese, and "Glowing dark" stays on one line. A guard's bubble that would fall behind the HUD or the tray moves to the nearest clear place, or to the middle of a gap narrower than itself. It is drawn on a layer above the panels, with no tail into a panel. **The scripted check:** `screen_heist.gd` with `FIT=1` fails the run when a label's words leave their panel, a HUD panel lies over another panel or over the tray, or a bubble covers words. Every one of the eight shots below passes it, with the switch off and on:

      FIT=1 MANIFEST=1 ESTIMATE=2600 LAWS=bloom,glowing_dark MOMENT=sneak TEXT=200 LOCALE=pt_BR bash tools/render/shoot.sh client/tests/shots/screen_heist.gd out.png

- **C, the crew's tray.**
  - The crew, the Sage, Cast and Get out sit on one tray of the kit's glass.
  - The crew stands in two rows, three and two, so Ash shares a row with Hollow.
  - The Sage stands beside Cast.
  - The hint is `KitHud.tip`, and it says only its first clause ("Tap crew, then ground").
  - The load bar is `KitHud`'s `loot_fit` bar.
  - Before landing, Cast reads "No casts". In Portuguese ("Sem lançamentos") that word on one line, beside the crew's longer kind names, made the tray ask 1,129 px of the 1,080 px frame, and the layout test (§21.1, at 9:19.5) failed. In the narrow text's single row, a phrase wider than one and a half times the order's square now stands on two lines (`HeistHand.two_lines`). The tray then asks 933 px.
- **D, Hollow and Bramble against their rings.** A cream mat (#F6E6C8, L* 92) lies between the ring (L* 43) and the portrait, inked on both sides. Hollow (L* 66 / 58) and Bramble (L* 71 / 56) now part from it by 21 points or more of L*.
- **E, the alarm moment.** `MOMENT=alarm` raises the alarm to 3 of 6 on its own, with a guard looking and the crew unhurt. The still shows the bar a third lit, the guard's "Who's there?" and the red edge.
- **Budgets (S1-R7).** `heist_hud.gd` now draws nothing outside the kit, so its record is gone from `tools/ui_bake/budgets.json`. `fx_portrait.gd` has 17 draw sites (it had 20). The speech layer's pen and the portrait's rings are each one draw site.

### Evidence

Stills are in `docs/art/shots/heist-pilot/`. Each one is the script above with `MOMENT`, `TEXT`, `LOCALE` and `CONTRAST` set to match its name.

- **As main stands (numerals switched off):** `part3-sneak-100`, `part3-sneak-200`, `part3-sneak-200-pt`, `part3-alarm-100`, `part3-alarm-hc` and `part3-alarm-hc-200`. These are the gate's stills.
- **With the numerals switched on**, for objection A, shot with `"numerals": true` set locally in `kit_families.json` and then restored: `numerals-sneak-100`, `numerals-sneak-200-pt` and `numerals-alarm-hc-200`.
- **Part 2's end:** the `after-*` stills.

| Budget still | Record before | Part 3, switch off | Part 3, switch on |
|---|---|---|---|
| heist/100 | 121 | 118 | 118 |
| heist/200 | 115 | 114 | 114 |
| heist/hc | 121 | 118 | 118 |

`budget_shots.py --record` lowered the three records to 118, 114 and 118. `check_screens.py --record` lowered the totals for chrome outside the kit from 232 draw and 31 fill to 226 draw and 29 fill. The worst word contrasts are 6.17, 6.43 and 5.55. `bash tools/ui_bake/guard.sh` passes.

### What is still worse

- **The timer shows the kit's figures only with the switch on.** As main stands, the gate sees the plain plate (objection A open, S1-R11).
- **At 200% text in Portuguese, the guard's bubble sits on the tray's top edge**, in the one clear gap between the HUD and the tray. It covers no words and is not clipped, but it leaves no air above the crew.
- **At large text the hint hides**, as in part 2, and the gait pill is not shown.
- **The gait's feet and the pause are still drawn** (S1-R9), and the large clock's words are hidden, not removed. They hold its size until the kit's numerals plate sizes itself.

### Left for other tasks

- Turning the numerals' switch on (K1's `kit_families.json`, S1-R11).
- A gait and a pause icon in the kit (S1-R9).

### Stopped here

Part 3 is done and waits on the pre-check and the gate. The checks run on the last commit are in `docs/progress/S1.md`.

## Part 4: board 1's round 2 (P1-S1-pilot-4)

Board 1's second round (`board-1.md`, Round 2) left two objections open. D needs Hollow and Bramble to part from their discs (AD-R13). B needs the tray to stay below the loot with no crew plan, at 200% text in Portuguese (AD-R15).

### What was done

- **D, a value step and an ink silhouette.** Each portrait in `fx_portrait.gd` is now composed once per creature and size, and cached (`FxPortrait.compose`):
  1. It takes the creature's figure on a clear ground (`CreatureBust.of(kind, "", clear)`), which replaces the bust baked on its role's ground.
  2. It measures the figure's mean L* (the pixels more than half opaque, inside the circle).
  3. It paints the disc in the creature's school hue (its role's hue for a creature with no school), with the lightness moved 30 L* away from the figure. The disc is lighter when that stays at or below L* 96, and darker otherwise. A soft gradient lights the disc's top.
  4. It inks the figure's silhouette with a line of the kit's ink (`FxSkin.INK_LINE`), about 2.5 px wide at 100% text, before laying the figure over it. The soft drop shadow under the figure gets no line.

  The school's hue stays in the disc, and the ring and the cream mat of part 3 are kept. The studio halo of the old bust is gone, so Bramble's grain at the disc's edge is gone too. The portrait is still one textured polygon, so the draw calls do not change. Each composite is about 57 KB of texture at 100% text, far inside the 24 MiB limit.

- **B, the Portuguese tray with no plan.** With no crew plan, the hand's order read "Sem lançamentos", which grew the tray to two rows of buttons and pushed its top over the loot panel. FIT reported "Loot over the tray".
  - At large text (above 130%), the order now keeps its short verb ("Lançar" / "Cast"), and its greyed wand says that no cast is left. A screen reader, the tooltip and the wheel still say "Sem lançamentos" / "No casts" (`heist_hand.gd`).
  - As a guard, a label too wide to keep its row beside Get out now stands on two lines at large text too (`heist_screen.gd`, `_hand_order`).

  The tray's top moves from y 960 (over the loot, which ends at y 1131) to y 1190.

### Measured L*

These are measured on the composites at 100% text (a 119 px disc), as `screen_heist.gd` prints them with `SIZES=1`:

| Portrait | Figure L* | Disc L* | Step | Least step (disc's dark edge) |
|---|---|---|---|---|
| Pip | 70.0 | 95.6 | 25.6 | 23.4 |
| Mo | 61.8 | 91.4 | 29.6 | 27.6 |
| Bramble | 56.7 | 86.1 | 29.4 | 27.7 |
| Hollow | 56.7 | 86.4 | 29.6 | 27.7 |
| Ash | 44.0 | 73.5 | 29.5 | 28.0 |

Bramble and Hollow share the school hue #8C6CF0, on a pale violet disc. Before this part, Bramble's figure sat about 12 L* below its orange disc, and Hollow's figure and disc were one tone in grayscale (board 1, round 2). Pip's step is shorter because the disc stops at L* 96, so the figure stays off white. Every figure also carries the ink outline. `PORTRAITS=dir` saves each composite and its figure as PNG files, to look at them at 1:1.

### Evidence

Stills are in `docs/art/shots/heist-pilot/`:

- `part4-sneak-100` (crew plan, 100% text) and `part4-before-sneak-100` (before this part);
- `part4-noplan-200-pt` (no crew plan, 200% text, pt_BR: the new gate still) and `part4-before-noplan-200-pt` (before this part, with the tray over the loot; shot without FIT, which would stop before the still);
- `part4-bramble` (Bramble at 1:1, before on the left and after on the right).

The no-plan gate still is:

      FIT=1 ESTIMATE=2600 LAWS=bloom,glowing_dark MOMENT=sneak TEXT=200 LOCALE=pt_BR bash tools/render/shoot.sh client/tests/shots/screen_heist.gd out.png

The other stills are part 3's command with `MOMENT`, `TEXT`, `LOCALE` and `CONTRAST` set to match their names. `FIT=1` passes in each of these cases:

FITTABLE

BUDGETS
