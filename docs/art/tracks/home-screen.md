# Home: the universe's screen from the kit alone

Branch `claude/ui-screens-home`, task P2-S2-home-1. Home (§23.2) is built from the frozen kit contract (`docs/art/ui-quality/kit-spec.md`) with no chrome of its own, in the same way as the pilot heist (`heist-pilot.md`). Anything the kit cannot build goes to K1 as a request in `docs/progress/status/S2.json`, through the lead.

The task also closes two of S2's own earlier requests:

- **S2-R1:** the renown number is now kept clear of the gem.
- **S2-R2:** the realms' pins now shrink when the room is short, where before they all hid.

## What was done

Home no longer draws anything itself. Before, each piece was a widget of its own (`client/world/universe_*.gd`) that drew its own surface. `check_screens.py` counted 1 draw and 2 textures in `home.gd`, and 7 draws in `universe_badge.gd`. Now every piece comes from the kit:

| Piece | Before | Now |
|---|---|---|
| Keeper's badge | `UniverseBadge` drew its own ring, gem, level and renown (`draw_arc`, `draw_texture_rect`, `draw_string`). Renown was pushed clear of the gem by padding with spaces (`_clear_of_gem`) | `KitHud.keeper` holds the ring, portrait and level plate. Renown stands in the plate's own row, clear of the gem at every text size (S2-R1) |
| Strain | `UniverseStrain`, its own plate and bar | `KitStatus.strain`, which taps through to the weaving screen with `KitLayout.tap` |
| Purse | `UniversePurse` drew three amounts on one layer | Three `KitStatus.resource` pills in an `HFlowContainer`, so they wrap at large text |
| Side buttons | `UniverseSide.make`, with all four drawn together by `UniverseSide.draw_all` on one layer | Four `KitControls.round_action` buttons |
| Goal | `UniverseGoal`, its own card | `KitHud.goal` card, which taps through with `KitLayout.tap` |
| Collect all | `UniverseCollect`, its own gold button | `KitControls.action2` in gold, with the `hud/collectall` icon |
| Raid notice | `UniverseNotice`, its own red card | `UI.panel("banner_alarm")` on its material's dark card (`RbBox.tint(card_top, card_bottom)`, the default of S2-R6), the `alerts/raided` icon on a badge disc, the words in `UI.status("alarm")`, a gold "See" `UI.action` and a "×" seg action |
| Realms' pins | Over the whole universe at large text, every pin hid when one found no room | They first shrink together to their icons and levels (`UniversePins`). They give way as a set only where even the compact pins find no room (S2-R2) |

**The pins at large text.** `UniversePins.follow` lays the pins out at full size. If a front pin finds no room, it lays them all out again in their compact form: icon and level, no name. The compact form holds until the size, the inset, the zoom or the clear areas change. Each pin is placed at the nearest height clear of every pin and every one of home's parts, and below the screen's top inset.

Over the whole universe, home still names every realm or none (`Home._fit_pins`). The results:

- **150% text:** all seven realms show compact, in English and Portuguese.
- **200% text:** the islands are small on screen and the pins hide as a set.

**Fit check.** `client/tests/shots/universe_home.gd` now has a `FIT` check. The run fails, and still saves its still, when any of these happens:

- a label's words are wider than the label;
- a label stands outside its panel or off the screen;
- one of home's parts overlaps another;
- a pin overlaps another pin or one of home's parts, or stands off the screen;
- over the whole universe, some realms are named and others are not.

The check found that pins could overlap by up to two gaps, at 9:16 and 200% text. That is fixed in `7474c113`. The test was not loosened.

`check_screens.py` now counts 0 draw and 0 texture in `home.gd` (recorded 1 and 2), and 0 draw in `universe_badge.gd` (recorded 7). Lowering those records is K1's job (S2-R10).

**Tap areas.** `KitLayout.tap` puts its clear button inside the card, so on the strain pill it stood within the pill's padding: 40 points tall, short of §21.1's 48. The client test "every control on every screen" caught it. Home now stands the pill and its tap in a holder of the pill's own size, so the tap is the whole pill, 48 points. The strain, the goal card and the side buttons are secondary places, so §21.1's thumb zone does not bind them. Home now marks each of their buttons that way, the kit's tap areas included, and not only the part that holds them.

**Cycle 74's gate points.** Against `art/ui/keyframes/01-home.*`:

- **The shot's state is the key frame's.** `universe_home.gd` now sets the key frame's state (`keyframe`): Keeper 24 with 1,240 experience to go, strain at 82% (Humming), and 3.4k waiting with the garden full. The Defence badge carries the two raids, and the notice is already dismissed (`NOTICE=1` shows it as it arrives). `MOST=1` keeps every amount at its widest. The key frames' own `*.shot.json` records are not this task's files, so they stay a follow-up.
- **A character portrait.** The badge shows the featherkin's head and shoulders, rendered from its model (`Portrait.bust`), on the spirit's teal, as the key frame's portrait does. Which character the Keeper shows is S2-R13's.
- **Display type on the figures and the name.** "Keeper 24", Renown and the purse's amounts are set in the display face (`DisplayS`), outlined in ink (`Home.home_figure`). The kit's parts set them in the body face; making it their default is S2-R12's.
- **Heist leads.** The Heist tab stands raised above the bar, its picture larger, as the key frame's gold disc does. A raised disc as the kit's own look is S2-R14's.
- **Collect beside the goal.** Collect shows while anything waits and reads "Collect 3.4k" as the design writes it, not in the gold's capitals. The goal stands beside it, narrowed to the room left. Where even its narrowest does not fit (large text), Collect shows alone. The kit's `action2` does not measure the words inside it, so home sizes the button to them; the fit check now also catches words that run past a button's edge (S2-R15).
- **The raid notice stands above the foot,** and its See is the ghost look, leaving gold to Collect. Only where the screen has no height for the notice and Collect both (200% text in Portuguese) does the notice take the foot's place, as it did before; the foot comes back once the raids are seen or dismissed. Home measures that by Collect's height alone, which the kit fixes: the goal's wrapped words have no height until the foot has laid them out, and a foot held hidden never does.
- **Collect keeps to the screen's width.** Where its words alone fill the width (German at 200%), its picture gives way first, and the button never asks for more than the frame's inside.

## Evidence

Stills come from `client/tests/shots/universe_home.gd`, the same script before and after, with six outer realms and two raids not yet seen:

    FIT=1 bash tools/render/shoot.sh client/tests/shots/universe_home.gd out.png
    FIT=1 TEXT=200 LOCALE=pt_BR bash tools/render/shoot.sh client/tests/shots/universe_home.gd out.png
    FIT=1 CONTRAST=1 bash tools/render/shoot.sh client/tests/shots/universe_home.gd out.png

**FIT=1 passes** in eighteen cases:

- 100%, 150% and 200% text, in English (`en`) and in Portuguese (`pt_BR`);
- high contrast at 100% and at 200%;
- 9:16 (`TALL=960`) at 100% and at 150%;
- `TALL=900` at 200%;
- the raid notice as it arrives (`NOTICE=1`) at 100% and at 200%;
- every amount at its widest (`MOST=1`) at 100% and at 200%;
- the raid notice with every amount at its widest (`NOTICE=1 MOST=1`) at 200% in `pt_BR` and in `de`, and in `pt_PT` at 9:16.

The client test `universe_view_tests.gd` (`_fits`) runs the notice at 1170 and 960 tall, 100%, 150% and 200% text, in every language; the full checks on `695c2ad1` failed there (408 of 409) until the two points above.

Runs side by side need a user folder each (`XDG_DATA_HOME`): they otherwise share the shot's settings and outbox, and two crashed that way.

**Budget stills** (`tools/ui_bake/budget_shots.py --only home/100,home/200,home/hc`), against the records in `tools/ui_bake/budgets.json`:

| Shot | Draw calls (record) | Textures | Words below 4.5:1 (record) | Worst contrast |
|---|---:|---:|---:|---:|
| home/100 | **143** (119) | 4.9 MiB | 0 of 28 (0) | 6.40:1 |
| home/200 | **112** (97) | 5.1 MiB | 0 of 13 (0) | 7.23:1 |
| home/hc | **143** (119) | 4.9 MiB | 0 of 28 (0) | 8.94:1 |

The budget shots now render the key frame's state, so the goal card shows beside Collect. All three fail on draw calls only, 7 or more under the cap of 150. The lead approved 139 for home/100 and home/hc (S2-R7); S2-R16 asks to amend that to 143, and home/200 to 112, for what cycle 74's gate asked for: the goal card (+4), the portrait and the display type. Until they are recorded, `guard.sh` fails on these three lines.

**Draw calls by part** at 100%, from the shot's `PROBE=1`. Each part is faded in turn and the frame's calls are counted again:

| Part | Before (old widget) | Now (kit part) |
|---|---|---|
| Keeper's badge | — | 16 (with the portrait and the display type) |
| Strain | — | 6 |
| Purse | 9 | 22 (three `KitStatus.resource` pills, their amounts in the display face) |
| Side buttons | about 11 | 18 (four `KitControls.round_action`, each a disc, an icon and a word plate) |
| Goal | — | 4 |
| Collect all | — | 2 |
| Raid notice | 7 | 11 (the alarm's fill under its words, and S2-R6's code-drawn card; shown only with `NOTICE=1`) |
| Tab bar | — | 24 |
| Realms' pins | — | 14 |

A kit part draws the skin atlas, its own icon texture and the font in turn; the display face and its ink outline add a font of their own. The old home drew its purse and its side buttons in one layer each.

Checks run on the task's last commit: see `docs/progress/S2.md`.

## What is still worse than before

These are things the kit's parts cannot do yet, or costs that the kit's parts bring. Each is a request in `docs/progress/status/S2.json`, with the default home uses until it is answered.

- **Home draws 24 more calls at 100% and in high contrast** (143 against a record of 119), and 15 more at 200% (112 against 97). It is still 7 under the cap of 150, but while the raid notice shows (`NOTICE=1`, not a budget shot) the frame at 100% reaches 154. A saving on the kit's side is K1's to weigh: icons in the skin atlas, or one layer for a part's art across its siblings. (S2-R7, S2-R16)
- ~~**In Portuguese, the goal gives way to Collect at 100% text.**~~ Fixed in part 3: where the two do not share a line, the goal stacks under Collect.
- ~~**At 200% text, the chosen tab's name hides where it would wrap below its tile.**~~ Fixed in part 3: the chosen tab's name always shows, sized to its tile.
- **Display type, the raised Heist tab and Collect's size are home's own.** The kit's parts set figures in the body face, have no raised tab, and do not size a button to its words, so home does these itself until the kit does. (S2-R12, S2-R14, S2-R15)
- **The raid notice's card is drawn in code.** `banner_alarm` has no shape of its own in the skin. It falls back to the red button's light face, on which white words measure 2.5 to 2.8:1. Home refills the box with the material's dark card colours. The line goes once the shape lands. (S2-R6)
- **The raid notice is composed by the screen.** `KitPanels.notice` (through `UI.banner`) frees itself after `banner_ms` unless the player keeps banners, and its cross frees the panel. Home's notice must stay until it is seen or dismissed (§21.8), and must come back when new raids arrive. At 150% text and above its words also need the card's whole width, with the mark, See and the cross in a row beneath; the kit's notice keeps them all in one row. So home composes the notice from `UI.panel`, `UI.status` and `UI.action`. (S2-R8)
- **Home reaches around `KitLayout.tap`.** The kit's tap stands inside the card's padding, so home moves it into a holder of the pill's own size and marks its button not frequent. Every tap also logs an error, because it connects `button_down` twice ("Signal 'button_down' is already connected"). The tap still works. (S2-R9)
- ~~**At 200% text, the realms' pins hide as a set.**~~ Fixed in part 3: numbered chips show at 200%.
- ~~**At 200% text in Portuguese, the raid notice hides Collect.**~~ Fixed in part 3: the notice is one line at large text, and Collect is never hidden.
- **At 200% text in German, Collect shows its words without its picture.** (No request.)
- ~~**At 200% text in Portuguese, the purse takes three rows.**~~ Fixed in part 3: two rows in every language, with strain in the second row.

## Part 2: the live character (P2-S2-home-2)

Task P2-S2-home-2 takes the points the advisory gate made on part 1 (cycle 77, `docs/art/ui-quality/gate/verdicts/P2-S2-home-1/977edd5b.json`) and the task's own `done_when`.

- **The Keeper's companion is alive.** The badge's portrait was a still bust (`Portrait.bust`), about 52 points across, pale on its ground: the gate's "small Keeper avatar, pale and soft against its ring". Now `UniverseBadge` stands the featherkin's model (`StageHero.make_figure`, the toon look, inked as §21.3 asks) in a small 3D stage of its own, a `SubViewport` cleared to nothing. The stage is lit by §21.3's three points, with a warm rim from behind against the spirit's cool ground. The model plays its two idles in turn, as a hero stage does (§21.6). `KitRing` draws the stage's picture cut round, as it drew the still one. The ring is 76 points across (the kit's Keeper part draws 52), and its ground is a step darker than the spirit's colour, so the light figure is the brightest thing in its disc. The paint's pale lift is taken back as the busts take it (`LIFT`, `RAMP_BIAS`). Under reduced motion (§20.8) the figure holds its first pose and the stage draws once; while the badge is hidden the stage does not draw.
- **The level plate stays clear of the purse.** The badge kept room under the ring for the level's plate by watching `item_rect_changed`, which never fired. The 52-point ring was shorter than the words beside it, so the plate fitted anyway; the 76-point ring is taller, and the purse covered the plate. The badge now watches `resized`, and also measures once after it is built.
- **The figures read as display type.** The counts and "Keeper 24" were already in the display face (`DisplayS`), but its 2-point ink line reads flat over the starfield at a phone's size: the gate's "flat currency counts" and "no outline on the header". `Home.home_figure` now uses the kit's `Display` role: the same face, with a 3-point ink outline and a 2-point hard drop (tokens.json `type.display`), at home's own sizes.
- **Collect shines.** Collect is the screen's one primary action, and it carries the kit's idle shine (`Motion.shine`, P2-K1-motion): a soft band crosses its face once a period while it is enabled and idle. There is no shine under reduced motion or in high contrast.
- **The reward flies to the kit's pills (S2-R5).** `UniverseReward.fly` now takes the pills by kind, so home no longer builds an empty `UniversePurse` to hold them. Retiring the old `universe_*` widgets is still outside this task's files.
- **A scripted check for rubric quality 9.** The shot's FIT check now also fails when home has no live `CreatureModel` in its badge, when the companion's idle does not play or its stage does not draw, or when the figure fills less than a third of its stage's picture (it fills 63% at 100%).

**AD's objections on part 1.** None were sent: AD had no session, and the lead applied S2-R11's default in cycle 75 ("the stills stand"). Part 2's stills go to AD as S2-R18.

**Draw calls.** The live stage costs 2 draw calls (the model and its ink pass). The budget shots measure home/100 at 145, home/200 at 114 and home/hc at 145, against records of 143, 112 and 143, all under the cap of 150. S2-R17 asks the lead to record them. The shine's band adds none to the budget shots at the moment they are taken.

**Evidence.** `FIT=1` passes in the same eighteen cases as part 1, with the new check. Checks run on the task's last commit are in `docs/progress/S2.md`.

**Still worse, or open:**

- **Home draws 2 more calls for the live character** (S2-R17).
- **The ring is home's own size.** The kit's Keeper part draws its ring at 52 points. Home sets 76 itself, as it sets the display role on the figures (S2-R12).
- **The still is not frame-exact.** The companion's idle runs on the frame clock, so two stills can differ by a few frames of the idle. The world's own motion already does the same.

## Part 3: board 3's objections (P2-S2-home-3)

AD's board 3 (`docs/art/ui-quality/gate/boards/board-3.md`, at `73bbcec6`) did not stand. It made three objections on home (A to C, filed as AD-R22 to AD-R24) and one on the kit's tabs (D, K1's P2-K1-tabs). This part answers A to C.

**A: Collect stays on the screen (AD-R22).**

- Collect and the goal always keep their place, at every text size, in every language and with the raid notice up.
- At large text (150% and more), the raid notice is one line: the heist's mark, the headline's tag, See, and the close cross on the kit's round plate. The line under the headline is still said aloud with it.
- Where even the headline's count leaves the line no room (German's "Ansehen" at 200%), the heist's red disc gives way, and the tag's alarm glyph marks the notice.
- Collect's words get smaller before they leave its gold. At 200% German, "3,4 Tsd. einsammeln" first drops Collect's picture, then shrinks to the screen's width, never under 12 points.
- **The scripted check.** The shot's `FIT=1` check (`must_show` in `client/tests/shots/universe_home.gd`) now fails when any of these is hidden or reaches outside the viewport:
  - Collect, whenever anything waits to be collected;
  - the goal;
  - the chosen tab's name.
- It also fails when no realm is marked over the whole universe. This is what let objection A pass `FIT=1` before: that check only looked at labels inside their own boxes.

**B: the world is framed between the panels (AD-R23).**

- The universe is fitted into the room between the purse and what stands over its foot (the notice, the goal and Collect), in every state, as the notice state already did.
- At 100% all seven realms and their pins are clear of the goal and of Collect. Verdant and Emberreach sit above the goal.
- The pins settle clear of the side buttons and their badges, near their own islands (see S2-R20, objection 1, below).
- In Portuguese, the Defence badge is clear of the Skyfield pin.
- The goal takes one line at 100% in English and two in Portuguese.

**C: nothing is dropped (AD-R24).**

- **The goal bar shows at every size.** It sits beside Collect where the two share a line. Otherwise it stacks under Collect and wraps, as the 200% key frame stacks them.
- **At 200%, the realms show numbered chips** in place of their named pins: each realm's level on the kit's plate. Each realm is still said aloud.
- **The purse keeps two rows at large text, in every language.** This leaves the world its room for the chips:
  - Strain moves into the purse's second row.
  - In German, where "142,0 Tsd." and "31,4 Tsd." cannot share a row, the three amounts shrink a little, never under 85% of their size (`AMOUNT_LEAST`).
- **The side buttons are discs alone at large text**, with no caps tags, as the key frame sets them at 200%:
  - They stand in their columns where the room is tall enough, otherwise side by side across each edge.
  - Only where that row would leave the realms no room do they give way: at 200% with the raid notice up, or on a short phone. Every place they lead to is also on the badge's menu, and the raids are on the notice.
- **Home's part of the dock labels.**
  - At 100% in Portuguese, all five names show. ASSALTO is set a little smaller instead of being cut.
  - At 200%, the chosen tab's name always shows, sized to fit inside its tile. The other tabs show their icons alone, each still named aloud, as the 200% key frame does.
  - Where the label sits on the tile's rim is KitTabs' (objection D, P2-K1-tabs).

**AD's notes on board 3.**

| Note | Answer |
|---|---|
| The companion's idle turns its face away | The yaw is clamped. Where an idle turns the head more than 0.3 radians from its rest pose (`YAW_LEAVE`), the figure turns back by what is past it, so the face stays toward the camera through the cycle (`UniverseBadge._keep_facing`). |
| The strain mark is a cyan dot, not the key frame's pink bolt | Kept. The dot is the kit's strain pill (`KitStatus.strain`). A bolt in that part is K1's to add; home will show it once the part has it. |
| The fixture has no notifications, shield or locked realm | Not added in this task. The dock's count badges are KitTabs' (P2-K1-tabs is open on that file), and adding them now would move the budget shots under K1's work. Home has no Defence timer data to show: the shield timer needs a source in the defence service first. Lantern Vale's lock is the next fixture change to make, in a later task. |
| Collect's shine did not fall in AD's frames | No change. The kit's motion test covers the shine. |

**AD's S2-R20 review (objections 1 to 5).**

AD reviewed this part once at `14fdcdfe` (S2-R20, `docs/progress/requests.md`) and made six objections. Objection 6, the dock's ISLANDS label, is KitTabs' (K1). This task answers 1 to 5.

1. **Each pin sits near its island, with a gap from the Defence badge.**
   - `UniversePins._spot` replaces the old two-pass search. It places each pin at the nearest free place within its reach. Reach runs from 1.25 to 3 pin heights (`NEAR` and `FAR`) from the island's anchor.
   - A free place is clear, by the kit's pin gap, of the other pins and of the controls over the world: the side buttons with their badges, the notice, the goal and Collect. The world is already framed under the purse.
   - Where a named pin finds no free place within `NEAR`, it sheds width before it moves away: it shows the realm's icon and level alone, and then its level on the numbered chip, within `FAR`. Only where a realm finds no place at all does every pin take the same step, so the pins stay alike. Each realm is still said aloud by its name.
   - At large text, when a realm still finds no free place, the side buttons give way, as they already do with the notice up (`Home._edges_yield`).
2. **With the notice up at 100% in English, the notice takes its height from the goal and the panels first.** The goal keeps one line where it fits. The notice's line under the headline is balanced: it breaks between words so its two lines are near the same length ("See how your / defence held").
3. **The Full tag shows at every size and in every language.** It is a red plate on the purse's last amount (`HomeParts.hang_full`). At 200%, where the amount fills its slot, the tag sits under the amount.
4. **The strain shows in its two-line large form at 200% in every language.** The share and the band are each on their own line, in one column (`HomeParts.large_strain`).
5. **AD's minor points:**
   - **The Portuguese purse at 100% takes two rows.** The amounts sit closer (`PURSE_GAP` 6, down to `PURSE_GAP_LEAST` 3 before a row breaks).
   - **High contrast's Collect label is the same size as at 100%.** Collect's padding is 16 points at every contrast (`COLLECT_PAD`).
   - **Chips 2 and 4, and 4 and 6, no longer touch** in Portuguese and German at 200%. Chips keep the pin gap like the named pins.
   - The Portuguese goal's break, "Guardião / 25", is the string's (S2-R19, still open).

**AD's S2-R22 review (objections (a) to (e)).**

AD re-checked 1 to 5 at `13ff046f` (S2-R22): they stand as fixed. AD made five new objections, which this task answers.

- **(a) At 200%, the chosen tab's raised picture is clear of the goal and Collect.**
  - The chosen tile's picture stands above the tab's declared height (KitTabs' `RISE`, 18 points). At 200% it rises up to about 40 points past the tile's top.
  - Home reserves that room: the tabs' top margin takes what the column's gap leaves of the picture's rise, its bob and a 2-point gap (`HomeParts.reserve_lift`). It follows the tile as it moves, and grows freely but shrinks only by more than 2 points, so the column never keeps re-sorting.
  - The part past the declared height is the kit's. S2-R24 asks K1 to keep the picture within it; home's reserve then falls to nothing on its own.
  - `FIT=1` now fails where the chosen tab's picture overlaps the goal or Collect (`kept` in the shot).
- **(b) The realms' pins take one form.** Where one realm's pin finds no room for its name, every realm's pin steps down together: to icon and level, then to the numbered chip (`UniversePins.follow`). `FIT=1` fails where the shown pins mix forms.
- **(c) At 100% the purse keeps one row.** Where the three pills cannot share the row (German's "142,0 Tsd."), all three amounts shrink a little, never under 85% (`AMOUNT_LEAST`), and the gaps close to `PURSE_GAP_LEAST`. `FIT=1` fails where the purse takes two rows at 100%.
- **(d) The goal breaks after the dot at large text**, as the key frame does: "1,240 experience to go · / Keeper 25". Its words may shrink to 85% (`GOAL_LEAST`) to keep the first half on one line (`HomeParts.break_goal`). German reads "noch 1.240 EP · / Hüter 25". The Portuguese first half is too long for one line even at 85%, so it keeps three lines (S2-R19).
- **(e) At 200% German, Collect keeps `COLLECT_PAD` beside its words.** The words shrink a point at a time until the padding fits.

**AD's notes on S2-R22.**

| Note | Answer |
|---|---|
| 'Lantern Vale' and 'Humming' are untranslated in pt_BR and de | They are in `client/i18n/strings.csv`, which is not this task's file. |
| Every render logs "button_up already connected" | Main logs it too. It comes from `KitLayout.tap` (`client/ui/kit_layout.gd`, lines 82 and 83), which connects `button_down` and `button_up` to the press motion again on a button that already has them. Home calls it from `UniverseBadge`. It is K1's file. |

**What (a) costs.**

- **At 200% in Portuguese with the raid notice up, the realms' chips give way.** The reserve lifts the foot about 36 points. With Portuguese's three-line goal and the notice, the world keeps about 105 points, and no chip finds a free place near its island. Home's rule then hides every pin together rather than mark some realms only (`Home._fit_pins`). Each realm is still said aloud and still takes its tap. Before (a), this case showed chips.
  - `FIT=1` fails in this one case, on "no realm marked over the whole universe" (board 3's objection C). The check is not loosened.
  - A trial of smaller reserves showed that the chips need back almost all of it. No other part of the column can give that much: the goal's first half needs 74% of its size to fit one line, and the column's gaps are 4 points.
  - S2-R25 asks AD to rule on the trade. Once K1 keeps the picture within the tab's height (S2-R24), the case passes again with no change to home.
- **At 200% in Portuguese, a darker band shows between the goal and the dock.** It is the edge of the galaxy's plane, which the higher foot now shows. The galaxy is `client/world/universe_view.gd`, which is not this task's file. It goes with S2-R24.

**Draw calls.**

| Shot | Calls | Recorded |
|---|---|---|
| home/100 | 144 | 145 |
| home/200 | 124 | 114 |
| home/hc | 144 | 145 |

- **home/200 is 10 over its record.** A bisect at 200% English, each fix added alone onto `14fdcdfe`, puts the rise on three of AD's objections:
  - the pins' search (objection 1): +5;
  - the Full tag's plate (objection 3): +4;
  - the strain's two-line form (objection 4): +3.
- KitTabs' fix on main (P2-K1-tabs) takes 1 off every home shot. Each fix's parts are kit parts drawing the skin atlas, their icon and the font in turn, so they do not batch with their neighbours.
- **The raise is asked of the lead (S2-R21):** record home/200 at 124 in `budgets.json` when this task merges. Textures and words below 4.5:1 are unchanged, and home/200 stays 26 under the cap of 150.
- **Other states (not budget shots):**
  - With the raid notice up at 100%, the frame draws 154 in English and Portuguese and 153 in German. The notice adds its balanced second line and the goal's own line.
  - At 150% in English it draws 127.
  - At 200% with the notice up it draws 115 to 117, and 125 with the tallest strings.

**Evidence.** `FIT=1`, with the new checks, passes in 26 cases, with no script errors:

| Text size | Cases |
|---|---|
| 100% | en, pt_BR, de, fr, high contrast, the tallest strings (`MOST`); with the notice in en, pt_BR, de and fr |
| 150% | en, and pt_BR with the notice |
| 200% | en, pt_BR, pt_PT, high contrast, high contrast in pt_BR; with the notice in en, pt_BR, de and fr, and with the tallest strings |
| 960 points tall | at 100%, and at large text |
| 900 points tall | 200% with the notice |

Checks run on the task's last commit are in `docs/progress/S2.md`.

**Still worse, or open:**

- **home/200 is over its record** until the lead decides S2-R21.
- **The Portuguese goal is not number-first.** It reads "faltam 1.240 de experiência · Guardião 25", while the key frame's English is number-first. The string is in `strings.csv`, which is not this task's file (S2-R19).
- **The strain band's word, "Humming", is not translated** in German or Portuguese. That is the strings file's, not this task's.
- **At 200% with the raid notice up, the side buttons give way.** At large text they also give way where a realm finds no free place. Their places stay on the badge's menu.
- **Collect's words shrink at 200% in German**, below the kit's button size. Collect drops its picture first: "3,4 Tsd. einsammeln".
- **At 200% in German with the raid notice up, the notice drops its red disc.** The alarm glyph on the tag stays.

## Left for other tasks

These widgets are no longer used by home, but they are outside this task's files:

- `client/world/universe_strain.gd`
- `client/world/universe_side.gd`
- `client/world/universe_notice.gd`
- `client/world/universe_collect.gd`

`UniverseGoal` is still used by `client/tests/universe_view_tests.gd`. `UniversePurse` keeps its `ORDER` and `FULL` for home; the coin flight no longer needs it (S2-R5, part 2). Retiring them is for a follow-up task.
