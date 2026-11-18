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

  The school's hue stays in the disc, and the ring and the cream mat of part 3 are kept. The studio halo of the old bust is gone, so Bramble's grain at the disc's edge is gone too. The portrait is still one textured polygon, so the draw calls do not change. The portrait now holds only its composite, about 57 KB at 100% text, in place of the 192 px bust (147 KB). The figure stays in `CreatureBust`'s cache and is read only to compose.

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

| Crew plan | Moment | Text | Language | Contrast | Draw calls (shot's count) |
|---|---|---|---|---|---|
| yes | sneak, alarm | 100% | en, pt_BR | normal | 142, 145 |
| yes | sneak, alarm | 200% | en, pt_BR | normal | 138, 141 |
| yes | sneak | 100%, 200% | en | high | 142, 138 |
| yes | alarm | 200% | pt_BR | high | 141 |
| none | sneak, alarm | 200% | pt_BR | normal | 121, 124 |
| none | sneak | 100%, 200% | en | normal | 124, 120 |

Each of these 15 runs exits 0 and prints "fit ok". The draw calls are the same as before this part.

| Budget still | Draw calls (record) | Texture bytes (record) | Worst word contrast |
|---|---|---|---|
| heist/100 | 118 (118) | 2,226,828 (2,499,264) | 6.17 |
| heist/200 | 114 (114) | 2,309,772 (2,333,376) | 6.43 |
| heist/hc | 118 (118) | 2,226,828 (2,499,264) | 5.55 |

These are from `budget_shots.py --only heist/100,heist/200,heist/hc`. No record moves. `check_screens.py` passes with the same counts (226 draw, 29 fill, 27 texture), because composing is image work and adds no draw site.

### What is still worse

- **At large text, Cast says "Lançar" / "Cast" even when no cast is left.** Only the faded wand shows that nothing is left, as §21.10 asks (it greys the wand and never the words). The tooltip, a screen reader and the wheel still say "Sem lançamentos" / "No casts". At 100% text the button still says it in words.
- **Pip's disc is nearly white** (L* 96), so its step is 25.6, the shortest of the five. A darker disc would muddy the school's hue (an olive at L* 40).
- **Bramble and Hollow share one pale violet**, their school's colour. They part by figure and outline, not by disc.
- **The composite is made in the game, at the size drawn**, once per creature and size, by pixel work in GDScript, the first time a portrait shows at that size (it is not timed here). A baked set would need AIA-2 (the portrait art itself, which is not S1's file).

### Left for other tasks

- Objection A (numerals switched on) is P1-K1-numerals-on. The header's ink outline (AD-R14) is in the same task.
- P1-AD-board-1c re-checks A, B, D and the header.

## Part 5: board 1's objections D and F (P1-S1-pilot-5)

Board 1's third round (`board-1.md`, Round 3) left two objections. For D (AD-R17), Bramble's grain and Hollow's glints still mottle the portraits at 119 px, so both should be painted flat, and Hollow should be framed head and shoulders like Mo, with its disc showing round its head. For F (AD-R18), the gold "Laws here" / "Leis aqui" header with its ink outline is lost on the night sky, because ink and sky are only a few L* apart.

### What was done

- **D, Bramble and Hollow painted flat.** `fx_portrait.gd` has a list of the kinds it paints flat (`TOON`: the quarryback and the glass golem). For those kinds, `FxPortrait.compose` now passes the cropped figure through `_toon` before it measures the figure and paints the disc:
  1. **The solid figure.** It keeps the pixels more than 55% opaque, then drops any part thinner than a line: what a 1.6 px blur leaves under half. That removes Hollow's see-through spikes and rods.
  2. **Three tones.** Each solid pixel takes one of three tones of the figure's median colour: 20% darker, the colour itself, or 26% towards white. Two lights choose the tone, weighed `form` to 1 − `form`:
     - a light from the upper left on the silhouette's swell (the solid mask blurred at 7 px);
     - the model's own lightness, blurred at 3 px.

     The lowest 22% of the figure takes the dark tone and the top 15% the light one. Bramble's grain and Hollow's facet glints are gone.
  3. **Marks.** A pixel that stands more than 22 L* off the figure's broad lightness (blurred at 5 px) keeps its own colour: eyes, Hollow's gem, Bramble's emblem.

  Hollow's `form` is 0.85, because its own light is all facets; Bramble's is 0.65. Hollow is framed head and shoulders: its crop is centred at (0.5, 0.32) of the bust with radius 0.32, against (0.5, 0.44, 0.42) for the others. Its violet disc now shows round its head and shoulders, where before the figure filled the round. The disc, its value step and the ink silhouette of part 4 are unchanged. They are measured on the flat figure, so the steps stay near 30 L*. The portrait art itself (`CreatureBust`) is not changed.

- **F, the header on the kit's tag plate.** `heist_hud.gd` seats "Laws here" / "Leis aqui" on `KitStatus.tag`: dark capitals (`text_on_gold`) on the gold plate, inside the kit's ink line. That replaces the gold words with an ink outline over the sky. The plate is 47 to 58 L* off the sky, where the old words' ink outline was a few L* off it. The plate's own ink line stays dark against the night sky, but the words no longer depend on it.
  - **German.** On one line, "GESETZE HIER" (315 px) set the laws column at 357 px, and the top row asked 1,116 px of the 1,080 px frame on the heist and 1,098 on the replay: the §21.1 layout test failed. At normal text a header wider than 80 points, as the bold face measures it before the kicker's spacing, now breaks between its words ("GESETZE" over "HIER"). "LAWS HERE" (73 points) and "LEIS AQUI" (62) stay on one line, so the English and Portuguese stills and figures are unchanged. Large text already stacks the row and is not broken.
  - **High contrast.** The kit thickens the tag's ink line (`line_hc`) and paints the plate white. The thick line crowded the capitals, and the guard read the words at 4.47:1 over the median of their box. In high contrast the words now carry a 2-point outline in the plate's own white (high contrast's `paper`), which keeps them off the line. §21.8 counts an outline of 1.5 points or more, and the words read 17.7:1 against it.

- **FIT reads a broken label by its lines.** With no crew plan at 100% text in pt_BR, Cast says "Sem lançamentos" on two lines (part 3). FIT measured the whole text as one line, 360 px in a 316 px button, and failed a label that fits. `screen_heist.gd` now measures each line and takes the widest. Neither case was in part 4's FIT table. Both pass now, at sneak and at alarm.

### Measured L*

**Portraits.** Measured on the composites at 100% text (a 119 px disc), as `screen_heist.gd` prints them with `SIZES=1 PORTRAITS=dir`:

| Portrait | Figure L* | Disc L* | Step | Least step (disc's dark edge) |
|---|---|---|---|---|
| Pip | 70.0 | 95.6 | 25.6 | 23.4 |
| Mo | 61.8 | 91.4 | 29.6 | 27.6 |
| Bramble | 56.1 | 85.3 | 29.3 | 27.7 |
| Hollow | 57.4 | 87.3 | 29.8 | 27.7 |
| Ash | 44.0 | 73.5 | 29.5 | 28.0 |

Pip, Mo and Ash are unchanged from part 4. Bramble and Hollow keep their step, now over a flat figure. `part5-portraits-119.png` shows the five at 1:1 in colour, and `part5-portraits-119-gray.png` in grayscale. `part5-portraits-4x.png` and `part5-portraits-4x-gray.png` show them at 4×.

**The header.** Read off the 100% en still:

| Part | L* |
|---|---|
| sky behind the header | 13.3 to 16.1 |
| plate's ink line | 4.8 |
| gold plate | 62.6 to 71.6 |
| plate's light rim | 96.6 |
| capitals | 8.5 |

On the 200% pt_BR still the rim reads 92 to 97 and the capitals 8.5. Ink and sky differ by about 9 L*, but the words no longer depend on that edge. The plate parts from the sky by 47 L* or more, and the capitals sit 54 L* or more below the plate. `part5-header-100-4x.png` and `part5-header-200-pt-4x.png` show the header at 4× on the 100% en and 200% pt_BR stills.

### Evidence

Stills are in `docs/art/shots/heist-pilot/`:

- `part5-sneak-100`: crew plan, 100% text, en; the gate still for "heist at 100% text";
- `part5-noplan-200-pt`: no crew plan, 200% text, pt_BR; the gate still for "heist at 200% text, pt_BR";
- `part5-hc-100`: high contrast, 100% text;
- `part5-portraits-*` and `part5-header-*`, listed above.

The commands are part 4's. `FIT=1` passes in each of these cases:

| Crew plan | Moment | Text | Language | Contrast | Draw calls (shot's count) |
|---|---|---|---|---|---|
| yes | sneak, alarm | 100% | en | normal | 133, 135 |
| yes | sneak, alarm | 100% | pt_BR | normal | 137, 139 |
| yes | sneak, alarm | 200% | en | normal | 133, 134 |
| yes | sneak, alarm | 200% | pt_BR | normal | 133, 134 |
| yes | alarm | 200% | pt_BR | high | 135 |
| none | sneak, alarm | 100% | en | normal | 119, 121 |
| none | sneak, alarm | 100% | pt_BR | normal | 125, 127 |
| none | sneak, alarm | 200% | en | normal | 115, 117 |
| none | sneak, alarm | 200% | pt_BR | normal | 116, 117 |
| none | sneak | 100% | en | high | 120 |

Each of these 18 runs exits 0 and prints "fit ok". The no-plan runs at 100% text in pt_BR failed before FIT read a broken label by its lines (see above). The no-plan gate still (part 4's command) also passes, at 122 draw calls.

| Budget still | Draw calls (record) | Texture bytes (record) | Worst word contrast |
|---|---|---|---|
| heist/100 | 119 (120) | 2,226,828 (2,499,264) | 6.17 |
| heist/200 | 115 (116) | 2,309,772 (2,333,376) | 6.43 |
| heist/hc | 120 (120) | 2,226,828 (2,499,264) | 5.55 |

The tag plate costs one draw call more than part 4's outlined words (118, 114 and 118). The paper outline in high contrast costs one more, so heist/hc sits at its record. No word is below 4.5:1 in any of the three.

These are from `budget_shots.py --only heist/100,heist/200,heist/hc`. No record moves. `check_screens.py` passes with the same counts (226 draw, 29 fill, 27 texture).

### What is still worse

- **Bramble reads as a flat grey-violet mass with small eyes.** Its shell, its legs and its face are one tone apart at most. The grain is gone, but so is most of what made it a Bramble. A cleaner flat figure needs the portrait art itself (AIA-2).
- **Hollow's facets are gone with its glints.** It reads as a violet toon figure with its eyes and gem, not as glass.
- **The flat pass is computed in the game**, in GDScript, once per creature and size, the first time a portrait shows at that size, with several blurs on a 119 px image (not timed). A baked set would need AIA-2.
- **The header's plate is a kit tag**, the same shape as a card's corner ribbon (FEATURED SET), so the header reads as a label, not as a heading.

### Left for other tasks

- Objection A (numerals switched on) is P1-K1-numerals-on.
- The portrait art at its source (a flat-painted Bramble and Hollow) would be AIA-2's. A request to the lead is in S1.json.
- P1-AD-board-1d re-checks D and F.

## Part 6: the gate's heist items on current main (P2-S1-heist-1)

The phase 2 exit (M25) asks for the three heist items again, this time on current main. The latest verdicts were P1-S1-pilot-1 at 5470c4d3, P1-S1-pilot-2 at a4d87d18 and P1-S1-pilot-4 at e846c531. Before changing anything, the gate's judges were re-run on stills of main (run `main1`, three samples per quality):

| Item | Quality | main1 |
|---|---|---|
| heist at 100% text | Colour roles and value | pass 3/3 |
| heist at 100% text | One art-direction idea | pass |
| heist at 200% text | Colour roles and value | pass 3/3 |
| heist at 200% text | Character presence | pass 3/3 |
| heist at 200% text | Layered materials | **fail 3/3**: the crew tray was a translucent scrim with a hairline rim, with no frame, well or lip |
| heist at 200% text | Painted or rendered icons | **fail 3/3**: the law icons were tiny flat glyphs with no school-shaped frame |
| heist at 200% text | Display type | **fail 3/3**: the crew names had no outline over the see-through scrim; 946 and ~2,600 were flat gold; Alarm and the figures ran into their card frames |
| heist at 200% text, pt_BR, no crew plan | Hierarchy | pass 3/3 (Lançar leads) |

So Get out and Alarm share the danger role, Cast has the gold fill and the rings differ by shape (the five trailing shapes of part 4), as before. What was missing at 200% was the materials, the icons and the display figures.

### What was done

- **Layered materials: a leather tray with a well.** The crew and the hand now sit on one opaque tray in the kit's leather, the plum and gold frame that the loot and alarm plates wear. This replaces the see-through scrim. The crew sit in the tray's inner well (`ScreenKit.panel('well')`), so each portrait sits in a pocket, not on the plate's face. The load bar, the crew bars and the hint pill keep the kit's chunky inked material from part 4.
- **Painted icons: law badges.** Each "Laws here" chip shows its icon as a rendered badge (`FxLawBadge`): the school's shape as a frame, a cream disc, and the icon at its painted size, drawn through `Icons.view`. This replaces the kit's small glyph. The badge is 26 points at large text and 22 points at 100% text, with 1 point to its name; at 100% text a larger badge widens the laws column past §21.1's frame (see "After the pre-check"). Bloom, Cast and Get out keep their painted icons at their painted size.
- **Display type: baked figures, inked names, room off the frame.**
  - With large text, the alarm count, Room and Left figures use the kit's baked numerals (`KitNumerals`), the finish the clock wears: a stroke and a hard drop baked in. The kit's label stays the source, hidden. A "~" the numerals do not bake stays live text in front of them.
  - The crew names carry the words-over-art treatment: a hard ink drop, an ink outline, then the fill. The drop and the outline share one glyph cache, so they go as one draw.
  - With large text, the words keep 8 points off the leather's thick frame, so "Alarm" and the figures stand inside their plates.
- **M26: fit at 200% for every state.** Five fixes:
  - **Crew names.** Names wrap to two lines on a tight line step, and shrink to fit their third of the row. The large-text crew rows sit closer (v_separation of 3 points), so the longest names fit.
  - **Law names.** A law name that would wrap at more than 130% text steps its size down to keep one line, to 80% at most. It is measured afresh at each width. This is for pt_BR's longer law names.
  - **The bubble with no room in the world.** A guard's speech bubble that has no room in the world now rests on the tray's content above the panels, not over the loot's words. In `fx_anchors`, the tray band is a soft keep-off counted at a quarter of its area, and the bubble is drawn on the layer above the panels.
  - **The bubble beside a panel.** The crew buttons, which hold the names and the count badges, are hard keep-offs. The bubble also tries places beside a hard panel, not only above or below one. This came from the gate re-run below.
  - **The bubble off the words and the tags.** The panels' words, and the portraits with their names and tags, count twice in the bubble's cover: a bubble with no clear place covers a panel's frame before them. Words count as their lines stand (`FxAnchors.words_rect`), not as the label's whole rect, and a portrait counts as it draws, its ability tag above its rect included (`FxPortrait.drawn_rect`). The `FIT` check measures the same way, and it also fails a bubble over a portrait or its tag. This came from the sweep after the pre-check.
  - **The bubble with no clean place near its guard.** Where every place within six lines of the guard covers a word or a portrait, the bubble goes to the nearest place on screen that covers none of them (`keep_clear` in `fx_anchors`, the panels' words and the portraits). It may still rest on a panel's frame. This came from the second sweep after the pre-check.
  - **Fixture states.** `screen_heist.gd` has new fixture states: `CREW=n` (one to four crew), `LONG=1` (the longest names), `END=1` (the end of the timer) and `LONGEST` (each language's longest crew and law names).

### The gate re-run on the fixes

The judges ran on the part 6 stills, with the same anchors as `main1`:

| Item | Quality | heist2 (6e8af315) | heist3 (ed766fe9) |
|---|---|---|---|
| heist at 100% text | Colour roles and value | pass | (no change) |
| heist at 100% text | One art-direction idea | pass | (no change) |
| heist at 200% text | Layered materials | pass 3/3 | (no change) |
| heist at 200% text | Painted or rendered icons | pass 3/3 | (no change) |
| heist at 200% text | Display type | 2/3: sample 2 failed on the "Who's there?" bubble over the top of Bramble's count badge | **pass 3/3** |
| heist at 200% text | Colour roles and value | pass | (no change) |
| heist at 200% text | Character presence | pass | pass |
| heist at 200% text, pt_BR, no crew plan | Hierarchy | pass | (no change) |

The heist3 fix (ed766fe9) moves only the speech bubble. On the 200% en still the bubble now sits at the top right of the tray, clear of every badge and name. The 100% and pt_BR stills were re-shot on ed766fe9, and their bubble stays in the world. These samples are this task's own runs. The lead's gate run (gate: Screen) gives the verdict.

### After the pre-check

- **The pre-check at f49852ed failed on §21.1.** At 100% text the heist screen asked 1110 of 1080 px in en, en_US, pt_BR, pt_PT, de and fr, and the replay screen (the same HUD) asked 1092 to 1110 px in pt_BR, pt_PT, de and fr. The cause was the law badge at 32 points (96 px) beside "Glowing dark": the laws column reached 351 px.
  - Tried: one badge size of 26 points at every text size. The widest was still 1092 to 1094 px.
  - Kept: 22 points at 100% text, with 1 point to the name (as the kit's chip at large text). The widest is now 1071 to 1073 px on the heist screen and 1039 to 1071 px on the replay screen, in every locale. Large text keeps 26 points and 4 points, so the 200% stills do not change for it.
- **The sweep on the final tree found en, longest names, a bubble 2 px over the loot's last line** ("Load to 80%"), with the "Who's there?" bubble in the 29 px gap between the loot and the tray. Weighting the words and the tags (above) moves it into the loot panel's empty lower right, beside the words and clear of Bramble's tag.
- **The second sweep found pt_BR, longest names, a bubble 25 px into the line of "Carregar até 80%"** (the caption runs wider in pt_BR, so the loot panel's lower right has no room, and the gap to the tray is narrower than the bubble). No place within six lines was off every word and tag. The bubble now takes the nearest clear place on screen: in the gap between the laws and the loot, on the loot panel's top edge.

### Evidence

Stills are in `docs/art/shots/heist-pilot/`, all re-shot on the tree after the pre-check fixes:

- `part6-h100.png`: crew plan, 100% text, en; the gate still for "heist at 100% text";
- `part6-h200.png`: crew plan, 200% text, en; the gate still for "heist at 200% text";
- `part6-hpt.png`: no crew plan, 200% text, pt_BR; the gate still for "heist at 200% text, pt_BR, no crew plan".

Each still was shot with:

`env FIT=1 ESTIMATE=2600 LAWS=bloom,glowing_dark MOMENT=sneak [MANIFEST=1] TEXT=100|200 [LOCALE=pt_BR] bash tools/render/shoot.sh client/tests/shots/screen_heist.gd OUT.png`

**M26 sweep at 200% text.** Each state was shot with `FIT=1`, in en, pt_BR and de:

- with a crew plan and with none;
- each crew size from one to four;
- the longest names, with a plan and with none;
- the alarm;
- the end of the timer, and the end of the timer with the longest names at the alarm.

The result table is in the handoff (`docs/progress/S1.md`).

**Budgets.** `budget_shots.py --only heist/100,heist/200,heist/hc` reads 120, 118 and 121 draw calls, against records of 120, 116 and 120. The two calls are the law badges at large text and high contrast (+1, where at 100% the badge replaces the icon disc) and the crew's well (+1 at each size). A raise was asked through the lead (S1-R33), and the lead approved it in cycle 106 under M33: the lead writes 118 and 121 in this task's merge. Tried first, with no gain:

- dropping the names' drop fill;
- the figures as outlined live words (+11);
- drawing the portraits' names before their shapes.

Textures and word contrast are unchanged. No word is below 4.5:1. `check_screens.py` passes (212 draw, 25 fill, 25 texture).

### What is still worse

- **The tray costs two draw calls over the old records** (heist/200 116 to 118, heist/hc 120 to 121), approved as S1-R33. Until the lead writes the new records in the merge, `guard.sh` fails on those two stills only.
- **The bubble can rest on a panel** when the world has no room for it (200% text): on the tray's empty right side, on the loot panel's empty lower right, or (pt_BR, longest names) on the loot panel's top edge, further from its guard. It stays off every word, portrait and tag, but it covers the frame.
- **The law badge is smaller at 100% text** (22 points, from 32) so the laws column fits §21.1's frame. The icon inside is about 10 points.
- **Long names at 200% text shrink** to fit their third of the row, on two lines. They fit, but they read smaller than the short names beside them.

## Part 7: the heist's plates in high contrast (P3-S1-hc-offline-1, AD-R56)

**AD-R56.** In high contrast the kit's leather plates rendered as a flat mauve at about the world's own value: Walk's face read L* 36.7 on a ground of 48.2. Key frame high contrast puts the heist's plates on the near-black card (#140C2A) with a light line, Get out on the red danger plate.

**What changed** (`client/scripts/heist_hand.gd`, `HC_LEATHER` and `hc_plates`). In high contrast, at the end of each refresh, the hand walks the HUD's controls (never the world's own view) and re-dresses them through the kit's `UI.dress`:

- every `leather`, `plate_leather`, `glass` and `tag_dark` plate takes the kit's `card` look, the near-black card;
- Get out takes `red`, the kit's danger plate;
- Pause takes `parchment`, the clock's light plate (white in high contrast), with its icon inked (`FxSkin.INK_LINE`) so it reads on the light face;
- every other look (Cast's gold, the crew's well) stays as the kit dresses it.

**The line is lavender, not cream.** The card's high-contrast line is drawn by the kit's atlas face, in lavender #B8A8D8 (L* about 72), and the shader's line colour cannot change a line the atlas draws. A cream line needs a high-contrast card face in the kit: request S1-R38 to K1 through the lead. Its default keeps the lavender line, which stands 52 to 56 L* off the sky.

### The controls' value steps (AD-R56)

Each control's face against the ground right around it, measured as L* on the high-contrast still at 100% text (`heist_hc.png` below), point samples on the face and on the ground beside it:

| Control | Face L* | Ground | Ground L* | dL* |
|---|---:|---|---:|---:|
| Pause (light plate) | 100 | night sky | 23.3 | 76.7 |
| Walk (card) | 5.2 | sky and world, left | 34.9 | 29.7 |
| Walk (card) | 5.2 | grass | 51 to 56 | 46 or more |
| The hint's plate (card) | 5.2 | grass | 51.1 | 45.9 |
| Cast (gold) | 80.5 | the tray (card) | 5.2 | 75.3 |
| Cast (gold) | 80.5 | the crew's well | 0 | 80.5 |
| Get out (red) | 30.4 | the tray (card) | 5.2 | 25.2 |
| Get out (red) | 30.4 | the crew's well | 0 | 30.4 |

Every control is 20 or more off its ground; the lowest is Get out on the tray, 25.2. The crew's portraits sit in the black well (L* 0), lit by their own discs. At 200% text in pt_BR the order changes: Pause sits in the crew's well (100 on 0), and Get out ("Fugir", red) and Cast ("Lançar", gold) stand on the tray as above.

**Display plates, not controls.** Bloom's law chip, the alarm and the loot are card faces (5.2) on a sky of 15.8 to 19.0: by their faces only 11 to 14 apart. They are read by their lavender line (L* about 72, 52 to 56 off the sky) and by their light words, and none of them is pressed. They are named here so AD can judge them; the cream line of S1-R38 would raise the line further.

### Evidence

Each still was shot with `FIT=1`, all exit 0, "fit ok":

    env FIT=1 CONTRAST=1 bash tools/render/shoot.sh client/tests/shots/screen_heist.gd heist_hc.png
    env FIT=1 CONTRAST=1 TEXT=200 LOCALE=pt_BR bash tools/render/shoot.sh client/tests/shots/screen_heist.gd heist_hc_200_pt_BR.png
    env FIT=1 TEXT=200 [LOCALE=pt_BR|de] bash tools/render/shoot.sh client/tests/shots/screen_heist.gd heist_200_<locale>.png

`heist_hc.png` is the still for the gate's "heist in high contrast" (Colour roles and value). The stills are not committed (this task's files hold no stills); the commands above render them from the ready commit.

**The guard's draw calls.** guard.sh at `a4dcb52e` measures heist/hc at 123 against its record of 121; heist/100 and heist/200 keep their records. The two calls are the re-dressed plates: the card face differs from the leather face it replaces, and Pause's light plate with its inked icon breaks the batch that the dark plates share. Pause on the card would save one call but stand only 18 off the sky, under AD-R56's 20. The raise, 121 -> 123, is requested of the lead under M33 (S1-R39). It closes AD-R56's objection.

## Part 8: one role per colour in high contrast (P3-S1-hc-offline-2, AD-R60 to AD-R62)

AD's preview of part 7 (`docs/art/ui-quality/gate/boards/preview-1.md`, R-a to R-c) kept three faults: "No casts" in gold, Get out in the alarm's red, and the loot figures in gold. Gold says "act here", red is the alarm's alone, and figures are information.

**What changed:**

- **AD-R60, Cast with no casts left** (`client/scripts/heist_hand.gd`, `show_state` and `_dress_cast`). With every cast used, the cast control takes the kit's leather secondary plate through `UI.dress`. The wand stays at 0.4, the words take the plate's `text_on_leather`, and the control stays tappable. Its own look (gold, from `_dress_hand`) is kept on the control as meta `look` and comes back when a cast is left. In high contrast `hc_plates` leaves it on leather, never the card.
- **AD-R61, Get out** (`hc_plates`). In high contrast Get out takes "leather", not "red". No fifth button style is added.
- **AD-R62, the loot figures** (`client/scripts/heist_hud.gd`, `_build_loot`). Under `Tokens.high_contrast`, Room, Vault and "?" take `Tokens.color("cream")` (#FFF3CC) before they are baked. `KitHud.loot_fit` and the heist at 100% are unchanged.

**The leather is the kit's high-contrast face, #7A4660, not #6A3E52.** The kit's atlas draws the leather plate in high contrast as a flat mauve, #7A4660 (L* 36.7), inside a black ink line. The amber rim is not drawn, and the shader cannot change a face the atlas draws (as with the card's line in part 7). AD's #6A3E52 (L* 32.1) was the token's first stop. The kit's face stands 4.6 further off the tray than that. An exact #6A3E52 with the amber rim needs a high-contrast leather face in the kit, K1's. S1-R41 offers it to AD, and its default keeps the kit's face.

**At 200% the figures are baked, so the cream is a tint.** At 200% text the loot figures are drawn by the kit's baked numerals (`KitNumerals`), which ignore `font_color`. In high contrast they are baked in the white finish (`num_white`), and `_sync` tints the baked row with the cream it finds in the label's meta `tint`. Only the white glyphs take it, and their ink line stays dark. Measured on the 200% pt_BR still, "508" reads #FCEFCC (L* 94.6), cream, where before the tint it read #FCFBFF.

### The controls' value steps (AD-R56, AD-R60, AD-R61)

The table measures each control's face against the ground right around it, in L*, on the high-contrast still at 100% text (`heist_hc.png`). Faces are the crop's most common colour.

| Control | Face | Face L* | Ground | Ground L* | dL* |
|---|---|---:|---|---:|---:|
| Pause (light plate) | #FFFFFF | 100 | night sky | 23.1 | 76.9 |
| Walk (card) | #140C2A | 5.2 | sky and world, left | 34.2 | 29.0 |
| The hint's plate (card) | #140C2A | 5.2 | grass | 51.1 | 45.9 |
| Cast, no casts left (leather, AD-R60) | #7A4660 | 36.7 | the tray (card) | 5.2 | 31.5 |
| Cast, no casts left (leather) | #7A4660 | 36.7 | the crew's well | 0 | 36.7 |
| Get out (leather, AD-R61) | #7A4660 | 36.7 | the tray (card) | 5.2 | 31.5 |
| Get out (leather) | #7A4660 | 36.7 | the crew's well | 0 | 36.7 |
| Cast, a cast left (gold, `MANIFEST=1`) | gold | 80.5 | the tray (card) | 5.2 | 75.3 |

Every control is 20 or more off its ground. The lowest is Walk, 29.0. Get out and the spent Cast now share the tray's lowest step, 31.5, where Get out's red gave 25.2. The words on the leather are `text_on_leather` #F6E6C8. At 200% text in pt_BR, "Lançar" and "Fugir" stand on the tray at the same 31.5.

**The figures.** Room 508, Vault 0% and "?" are cream, #FFF3CC (L* 95.9) at 100% text and #FCEFCC (L* 94.6) at 200%, on the card (5.2): 90.7 and 89.4 off it. They are no longer the gold of a live action.

### Evidence

Each still was shot with `FIT=1`. Every run exited 0 and printed "fit ok":

    env FIT=1 bash tools/render/shoot.sh client/tests/shots/screen_heist.gd heist_100.png
    env FIT=1 TEXT=200 LOCALE=en bash tools/render/shoot.sh client/tests/shots/screen_heist.gd heist_200_en.png
    env FIT=1 TEXT=200 LOCALE=pt_BR bash tools/render/shoot.sh client/tests/shots/screen_heist.gd heist_200_pt_BR.png
    env FIT=1 TEXT=200 LOCALE=de bash tools/render/shoot.sh client/tests/shots/screen_heist.gd heist_200_de.png
    env FIT=1 CONTRAST=1 bash tools/render/shoot.sh client/tests/shots/screen_heist.gd heist_hc.png
    env FIT=1 CONTRAST=1 TEXT=200 LOCALE=en bash tools/render/shoot.sh client/tests/shots/screen_heist.gd heist_hc_200_en.png
    env FIT=1 CONTRAST=1 TEXT=200 LOCALE=pt_BR bash tools/render/shoot.sh client/tests/shots/screen_heist.gd heist_hc_200_pt_BR.png
    env FIT=1 CONTRAST=1 TEXT=200 LOCALE=de bash tools/render/shoot.sh client/tests/shots/screen_heist.gd heist_hc_200_de.png
    env FIT=1 MANIFEST=1 bash tools/render/shoot.sh client/tests/shots/screen_heist.gd heist_man_100.png
    env FIT=1 MANIFEST=1 CONTRAST=1 bash tools/render/shoot.sh client/tests/shots/screen_heist.gd heist_man_hc.png

`heist_hc.png` is the still for the gate's "heist in high contrast" (Colour roles and value). The `MANIFEST=1` stills show the gold coming back with a cast left. At 100% text, "No casts" and Get out are on the leather with its amber rim, and the loot keeps its gold (`KitHud.loot_fit`), as the key frame has it. The stills are not committed, because this task's files hold no stills. The commands above render them from the ready commit.

## Part 9: the HUD above the world's markers (P3-S1-marker-1, AD-R55)

Flow board 2's F9 (`docs/art/ui-quality/gate/boards/flow-2.md`): at 200% text in pt_BR, with the heist opened from Home's Heist tab, a pylon's school disc (the hourglass) drew over the "E" of the loot panel's "Espaço".

**The cause.** The kit stacks its layers once `UI.root_theme()` is installed (kit-spec.md section 5). A full-screen child placed after another is lifted one overlay (`UI.OVERLAY_Z`, 16) above it. The world view's children are its picture (the SubViewportContainer) and then FxAnchors, the full-screen layer where the world's markers and marks are drawn: the pylons' school icons, the vault, the guards' marks and the pops. FxAnchors therefore stood at z 16. The HUD's columns (FxSkin.frame's two margins) stood at z 0, their words at 1 and their faces at −1, so every marker drew above the whole HUD. At 100% text the loot panel stays clear of the map's markers, so the fault showed only at 200%, where the panel grows down over the map. The heist's still (`screen_heist.gd`) and the tests built the heist before the kit's layers were on, so FxAnchors stood at 0 there and neither showed it. The app's router always has the kit's layers on by the time it opens the heist.

**What changed.**

- **The order is set once, in the screen's layer order** (`client/scripts/heist_screen.gd`, `_build`, through `HeistHud.layer` in `client/scripts/heist_hud.gd`). The HUD's two columns stand at `HeistHud.HUD_Z`, two overlays (32), one overlay above the world's marker layer. The world's markers are not moved, and no world file changes.
- **The guards' words stay above the HUD**, as before. Speech, the full-screen layer for bubbles that lie over a panel, is added after the columns, so the kit lifts it to 48. The entry card and the gait menu are added after it and stack above it.
- **The loot's flying coins** (`fly_coins`) stand at the top of the HUD's layer (47): over the panels and their words as they fly into the loot, under the guards' words.
- **The still shows what the player sees.** `client/tests/shots/screen_heist.gd` installs the kit's layers before it builds the screen, as the app does.

**The test** (`client/tests/heist_fx_tests.gd`, `_layers`). It mounts the heist the way the app mounts it, with the kit's layers on, at 200% text and with the clock played 60 ticks. It then measures the z range of every visible canvas item on the screen's canvas under the world view, and the same under the HUD's columns. It passes when the world's highest z is under the HUD's lowest and a flying coin stands above the HUD's highest. On main's order it fails with "world z 0..16, HUD z 0..2". With this change it passes: the HUD stands one overlay higher, above all of the world.

### Evidence

- `part9-before-flow-200-pt.png` and `part9-after-flow-200-pt.png`: the top of the gate's flow walk (`tools/ui_gate/flow_walk.gd`, `FLOW=result TEXT=200 LOCALE=pt_BR`), step 03 "heist-played", before and after. In the before still the hourglass covers the "E" of "Espaço". In the after still, "Espaço" reads whole.
- `part9-heist-200-pt.png`: the heist's still at 200% text in pt_BR, with the kit's layers on. The vault's label, the guards' marks and the pylons draw under the loot panel and the hand.

Each still was shot with `FIT=1`. Every run exited 0 and printed "fit ok":

    env FIT=1 bash tools/render/shoot.sh client/tests/shots/screen_heist.gd heist_100.png
    env FIT=1 TEXT=200 LOCALE=en bash tools/render/shoot.sh client/tests/shots/screen_heist.gd heist_200_en.png
    env FIT=1 TEXT=200 LOCALE=pt_BR bash tools/render/shoot.sh client/tests/shots/screen_heist.gd heist_200_pt_BR.png
    env FIT=1 TEXT=200 LOCALE=de bash tools/render/shoot.sh client/tests/shots/screen_heist.gd heist_200_de.png
    env FIT=1 CONTRAST=1 bash tools/render/shoot.sh client/tests/shots/screen_heist.gd heist_hc.png
    env FIT=1 CONTRAST=1 TEXT=200 LOCALE=pt_BR bash tools/render/shoot.sh client/tests/shots/screen_heist.gd heist_hc_200_pt_BR.png

These cover the gate's "heist at 100% text", "heist at 200% text, pt_BR" and "heist in high contrast". The HUD, the loot panel, the hand and every control draw above the world's markers in each of them.

### The vault kept in the map band (AD-R65)

AD's preview (`docs/art/ui-quality/gate/boards/preview-2.md`, AD-R65): at 200% text the loot panel grows down and the crew tray grows up, and the map band between them narrows. On the opening frame the vault and its label landed under the tray. In pt_BR the tray's edge cut 'COFRE' through its middle; in de only the tops of 'TRESOR' showed. The HUD's order stays as the change above sets it.

**The cause.** The heist's follow camera (`WorldView._frame_camera`) centres on the crew and drops the scene by `camera.v_offset = cam_size * 0.07`. That framing was set for 100% text, where the band is wide. Nothing on the screen moved it when the HUD grew.

**What changed** (S1-R43, granted by M60):

- **`client/world/world_view.gd`: one public var, `lift`.** It holds the pixels by which the follow frame stands the island higher; 0 keeps §21.1's framing. `_frame_camera` applies it while following, as `camera.v_offset -= lift * cam_size / size.y`. FxAnchors projects its labels after `_frame_camera` in the same `_process`, so the labels stay on the island. Nothing else in the file changes.
- **`HeistHud._lift_vault` (`client/scripts/heist_hud.gd`) computes the lift.** The screen hands it the world view and the crew tray (`HeistHud.frame_vault`, one line in `heist_screen.gd`, which is at 999 of gdlint's 1000 lines). It waits for the opening frame: the crew landed, the landing's zoom settled and the vault's plate drawn. Then it reads the band, from the loot panel's foot to the tray's top edge, each with a pad of 6 points at the text's scale. It also reads the vault's plate and its projected dome. The lift is the least that brings the dome and the plate above the tray's edge, capped so the plate's top stays below the loot panel's foot. So the label stays whole when the band is too narrow for both. It is set once per replay and then held, so the camera does not hunt as the crew walks.
- **The lift is 0 when the vault already fits.** At 100% text the band runs from 557 to 1658 px and the frame does not move. At 200% it comes to 101 px in en and de and 90 px in pt_BR on the heist shot's island.

A constant lift was tried first and thrown away. At 140 px 'COFRE' sat just under the loot panel's foot; at 170 px it went partly under it. In de, 'TRESOR' went under the loot panel at both 140 and 170 px. The lift has to be measured for each frame.

**The test** (`client/tests/heist_fx_tests.gd`, `_vault_band`). It mounts the heist the way the app does, with the kit's layers on. It uses the heist shot's island (`WorldTests.island()`) and the shot's "sneak" moment: the crew spread by the same three orders, played in steps to tick 150, with the landing's zoom played out. It measures, in the world view's own pixels, the loot panel's foot, the tray's top, the vault's plate and its dome. The test passes when, at 200% in en, pt_BR and de, the plate's top is at or below the loot panel's foot and the plate and dome are at or above the tray's top, and when the lift is 0 at 100% in en. Its detail line reads:

    200% en tag 1216..1249, vault 1325, band 1147..1338, lift 101
    200% pt_BR tag 1228..1260, vault 1336, band 1147..1349, lift 90
    200% de tag 1216..1249, vault 1325, band 1147..1338, lift 101
    100% en tag 1321..1353, vault 1427, band 557..1658, lift 0

With the lift held at 0 it fails. Then the plate stands at 1321..1353 and the dome at 1427, below the tray's top in each locale.

### Evidence (AD-R65)

- `part9-vault-200-en.png`, `part9-vault-200-pt.png` and `part9-vault-200-de.png`: the heist still at 200% text in each locale. 'VAULT', 'COFRE' and 'TRESOR' read whole, and each sits with the vault's dome between the loot panel's foot and the tray's top edge. `part9-heist-200-pt.png`, above, is the same still before the lift. There the vault and its label are under the tray.
- The six FIT runs above were run again on the lift. Every run exited 0 and printed "fit ok". At 100% text and in high contrast at 100% the lift is 0, so those frames are as they were.
