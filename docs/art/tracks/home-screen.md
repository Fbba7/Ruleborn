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

**AD's S2-R25 review (objection (f)).**

AD re-checked (a) to (e) at `823d2eac` (S2-R25): (a), (c), (d) and (e) stand as fixed. AD accepts (a)'s trade for this task: at 200% with the notice up, in pt_BR, fr and on a phone 900 points tall, the realms' chips give way together. Board 3b re-checks those cases once S2-R24 gives back the dock's height. AD made one new objection.

- **(f) At 200% in German, each realm pin holds its icon and its level, on a plate of their size.**
  - The cause: German at 200% is the one case where the pins step to their second form, icon and level (objection (b)). The plate took its new width at once. Its row moved the level's disc only on the next frame, so the pins drew the disc over the icon, and the plate's right half stayed empty. The shot's still is taken on that frame, which AD saw.
  - The fix: `UniversePins._draw` places the icon at the plate's start and the level's disc at its end, from the plate's own size, not from the row's children. The pin now draws right on the frame it changes form.
  - The form itself is kept. German at 200% has room for each realm's icon, so the pins show it (objection (b) on S2-R22: the most that fits, in one form). Where a realm has no room for it, every pin steps to the numbered chip, as English does at 200%.
  - The plate is 260 px wide at 200% (12 + 114 + 12 + 110 + 12: margin, icon, gap, disc, margin), against 134 px for a numbered chip.

**AD's S2-R27 review (objection (g)).**

AD re-checked (f) at `8ff5ee23` (S2-R27): it stands as fixed. AD made one new objection, found on the full-list check (M23). The board's text is in `docs/art/ui-quality/gate/boards/board-3.md`, "Re-check of objection (f) (S2-R27)".

- **(g) At 200% without the notice, the four side buttons keep their edges.** They are Defence (with its raid badge and timer), Season, Lab and Shop. AD-R24 asks for them as icon-only discs at 200%, in two edge columns with the realm chips between them, as both 200% key frames show. In German and German high contrast they were gone.
  - **The cause.** Home gave the side buttons' room to the realms (`Home._fit_pins`) as soon as one realm's pin found no place, before the numbered chips had tried every order. The pins are laid in order, and each takes the free place nearest its island. In German at 200%, as numbered chips, every realm found a place but one, Outer 6: the chips laid before it took the room near its island.
  - **The fix, part 1: each failing realm is laid first in turn.** Where a realm finds no place even as a numbered chip, `UniversePins.follow` lays the pins again with that realm first. It does this once for each realm that fails, until every realm has a place. In German, Outer 6 laid first leaves room for all seven chips between the two columns.
  - **The fix, part 2: the side buttons give way only on a real shortage.** Home gives their room away only when `UniversePins.short()` is true. That means the pins are at the numbered chip, every failing realm has been laid first, and a realm still has no place. Before, a pin that missed its place on the first frame was enough, before the camera and the sizes had settled. Once given, the room stays given until the notice changes, as before.
  - **German keeps the four side buttons at 200%,** in high contrast too. The realms take numbered chips there, as AD's default asks, since the icon-and-level pins of (f) leave no room for the side columns. With the notice up at 200%, the side buttons give way as before (AD's answer: until P2-K1-tabs-2).
  - **pt_BR, pt_PT and fr cannot keep them until K1's height work (S2-R24, P2-K1-tabs-2).** Their goal keeps three lines at 200% (pt_BR's "faltam 1.240 de experiência · Guardião 25"), so the realms' band between the purse and Collect is 399 px tall (886 to 1285 in the 1080 × 2340 frame). German's goal keeps two lines, and its band is about 100 px taller. In that band, with the two columns at its sides, seven chips of 134 × 122 px and the raid card do not fit with the 4-point gap that keeps chips from touching (S2-R20's fifth objection). The nearest miss: the free gap between the raid card and the right-hand column is 149 px, and a chip needs 152 with its gaps. A trial with a finer search, on a grid of half a chip, found no more places. So in pt_BR, pt_PT and fr the side buttons still give way at 200%, each place on the badge's menu, as AD's answer allows for pt_BR. The re-check request says so (S2-R28).

**What (a) costs.**

- **At 200% with the raid notice up, the realms' chips give way where the world is shortest.** The reserve lifts the foot about 36 points. In three cases the world then keeps about 100 points, and no chip finds a free place near its island:
  - Portuguese and French, whose goal keeps three lines;
  - English on a phone 900 points tall.

  Home's rule then hides every pin together rather than mark some realms only (`Home._fit_pins`). Each realm is still said aloud and still takes its tap. Before (a), these cases showed chips.
  - `FIT=1` fails in these three cases, on "no realm marked over the whole universe" (board 3's objection C). The check is not loosened.
  - A trial of smaller reserves showed that the chips need back almost all of it. No other part of the column can give that much: the goal's first half needs 74% of its size to fit one line, and the column's gaps are 4 points.
  - S2-R25 asks AD to rule on the trade. Once K1 keeps the picture within the tab's height (S2-R24), the cases pass again with no change to home.
- **At 200% in Portuguese, a darker band shows between the goal and the dock.** It is the edge of the galaxy's plane, which the higher foot now shows. The galaxy is `client/world/universe_view.gd`, which is not this task's file. It goes with S2-R24.

**Draw calls.**

| Shot | Calls | Recorded |
|---|---|---|
| home/100 | 144 | 145 |
| home/200 | 119 | 114 |
| home/hc | 144 | 145 |

Measured with `bash tools/ui_bake/guard.sh` on the merge of main (`a8f799c`), and the same on (f)'s merge of main (`8ff5ee23`) and (g)'s (`398a38cb`, and `c9a89e5a` after main's next merge).

- **home/200 is 5 over its record.** At `13ff046f` it drew 124; with (a) to (e) and main's merge it draws 119 (not bisected). The bisect of 124 at 200% English, each fix added alone onto `14fdcdfe`, puts the rise on three of AD's objections:
  - the pins' search (objection 1): +5;
  - the Full tag's plate (objection 3): +4;
  - the strain's two-line form (objection 4): +3.
- KitTabs' fix on main (P2-K1-tabs) takes 1 off every home shot. Each fix's parts are kit parts drawing the skin atlas, their icon and the font in turn, so they do not batch with their neighbours.
- **The raise is asked of the lead (S2-R21):** record home/200 at 119 in `budgets.json` when this task merges (approved at 124 in cycle 87). Textures and words below 4.5:1 are unchanged, and home/200 stays 31 under the cap of 150.
- **Other states (not budget shots):**
  - With the raid notice up at 100%, the frame draws 154 in English, Portuguese, German and French. The notice adds its balanced second line and the goal's own line.
  - At 150% in English it draws 126.
  - At 200% with the notice up it draws 115 to 117, and 125 with the tallest strings.

**Evidence.** On the merge of main (`a8f799c`), again with (f) on its merge of main (`8ff5ee23`), and with (g) (`b0ca06ce`, then merged with main as `398a38cb`), `FIT=1` with the new checks passes in 24 of 27 cases, with no script errors:

| Text size | Cases that pass |
|---|---|
| 100% | en, pt_BR, de, fr, high contrast, the tallest strings (`MOST`); with the notice in en, pt_BR, de and fr |
| 150% | en, and pt_BR with the notice |
| 200% | en, pt_BR, de, fr, pt_PT, high contrast, high contrast in pt_BR; with the notice in en and de, and with the tallest strings |
| 960 points tall | at 100%, and at large text |

It fails in three cases, all at 200% with the notice up: pt_BR, fr, and en 900 points tall. Each fails on "no realm marked" ("What (a) costs" above).


Checks run on the task's last commit are in `docs/progress/S2.md`.

**Still worse, or open:**

- **home/200 is over its record** until the lead records it (S2-R21).
- **At 200% with the raid notice up, the realms' chips give way** in pt_BR, fr and on a phone 900 points tall, where (a)'s reserve leaves no free place (S2-R24). AD accepts it for this task (S2-R25); board 3b re-checks it.
- **The Portuguese goal is not number-first.** It reads "faltam 1.240 de experiência · Guardião 25", while the key frame's English is number-first. The string is in `strings.csv`, which is not this task's file (S2-R19).
- **The strain band's word, "Humming", is not translated** in German or Portuguese. That is the strings file's, not this task's.
- **At 200% with the raid notice up, the side buttons give way** until P2-K1-tabs-2 (AD's answer to S2-R27). **At 200% in pt_BR, pt_PT and fr without the notice they give way too:** their three-line goal leaves no room for seven chips between the columns ((g) above). Their places stay on the badge's menu. German and English keep them.
- **Collect's words shrink at 200% in German**, below the kit's button size. Collect drops its picture first: "3,4 Tsd. einsammeln".
- **At 200% in German with the raid notice up, the notice drops its red disc.** The alarm glyph on the tag stays.

## Part 4: board 3b's H (P2-S2-home-4)

AD's board 3b (`docs/art/ui-quality/gate/boards/board-3.md`, "Round 2 (board 3b)") made one objection on home, H (AD-R39). At 200%, home held about 68 px over the tab bar for the chosen tab's raised picture (`HomeParts.reserve_lift`). Without that height, the realms' band was too short:

- the side buttons gave way in pt_BR, pt_PT and French;
- the side buttons gave way in every case with the raid notice up;
- the realms' chips gave way in four of the notice cases.

K1's half (P2-K1-tabs-3) keeps the chosen tab's picture inside the bar at large text. This part is home's half.

**The reserve is gone.** `HomeParts.reserve_lift` and its hook on the tabs are removed. After tabs-3, `KitTabs.lifts()` is true only at 100% and below, and the tab bar's declared height already holds the picture there. The goal card now sits right over the bar's gold edge, as the key frame has it.

**Giving the height back was not enough on its own.** At 200% with the notice up, the band stays 296 px tall in French and 300 px in Portuguese, and 327 px in English on a phone 900 points tall: the notice, Collect and a three-line goal stand over its foot. Two edge columns of two discs each, plus the realms' chips between them, need about 400 px. So home also gives the band more of its width and height:

- **The right edge stands beside the keeper's plate at large text (150% and more).** At large text, strain moves into the purse's second row (Part 3, C). That leaves the top row's right side empty, and the right edge's two discs (Season and Shop) now stand there. They are on the top row's right, level with the keeper's plate. Only the left edge (Defence and Lab) takes the band. The realms' chips then have the band's full width beside one column.
- **The large-text gaps close a little,** so the left edge's two discs (294 px tall) fit the band in French and Portuguese:
  - the column's gap: 2 points, was 4;
  - the gap between two discs down an edge: 2 points, was 14 (`SIDE_GAP_LARGE`);
  - the discs: the kit's control size, 48 points (`UI.CONTROL_POINTS`), was 52 (`SIDE_POINTS`);
  - the goal card's padding: 2 points, was 4 (`GOAL_PAD_LARGE`);
  - the raid notice's padding: 2 points, was 3.
- **The side buttons still give way in stages where a band is too short.** First their columns stand side by side, then they give way. `Home._edges_yield` counts only the edges in the band. At 100% nothing changes: both edges stand in the band, at their 52 points and 14-point gap.

**The scripted check.** `FIT=1` (`must_show` in `client/tests/shots/universe_home.gd`) now also fails when any of the four side buttons is hidden or reaches outside the viewport. It still fails on "no realm marked". The shot's header lists the cases from AD-R39 it must pass. Nothing in the check is loosened.

**What this closes in Part 3's open list.** The realms' chips at 200% with the notice up (S2-R24, S2-R25), and the side buttons at 200% in pt_BR, pt_PT and fr and with the notice up (S2-R28) now show.

**Evidence.** On this task's code (`d5e99d28`, merged with main as `00b9a23e`, docs only), `FIT=1` passes in all 39 cases below, with no script errors. It failed in three of them before (Part 3, "What (a) costs").

| Text size | Cases that pass |
|---|---|
| 100% | en, de, pt_BR, pt_PT, fr, each with and without the notice; en 900 points tall, with and without the notice; en 960 points tall; high contrast in en and pt_BR; the tallest strings (`MOST`) |
| 150% | en; en 960 points tall; pt_BR and fr with the notice; pt_PT with the notice and `MOST`, 960 points tall |
| 200% | en, de, pt_BR, pt_PT, fr, each with and without the notice; en 900 points tall, with and without the notice; high contrast in en, pt_BR and de; `MOST` in en, and with the notice in pt_BR and de |

The 200% rows hold every case H names.

**Every state home draws (M26).** Board 5b's K went unseen because a screen's fit check covered one fixture, so home's check now also runs at the states home can be in, at 200% text in en, pt_BR and de. The shot's new `EMPTY` fixture (`start` in `universe_home.gd`) is a new Keeper's home: level 1, every amount 0, nothing waiting so no Collect, strain 0 ("Quiet"), the season track untouched. With `OUTER=0` only the Heart is on the map. `FIT=1` passes in all 20 of these runs, with no script errors:

| State | Cases that pass |
|---|---|
| Widest amounts (`MOST`: seven figures, level 99, every producer full) | en, pt_BR, de at 200%, each with and without the notice |
| Most raids (`MOST=1 RAIDS=99 NOTICE=1`: the badge's and the notice's widest count) | en, pt_BR, de at 200% |
| New Keeper, Heart only, no raids (`EMPTY=1 OUTER=0 RAIDS=0`) | en, pt_BR, de at 200%; en at 100% |
| New Keeper, Heart only, raided (`EMPTY=1 OUTER=0 NOTICE=1`) | en, pt_BR, de at 200%; pt_BR at 150% |
| New Keeper, seven realms (`EMPTY=1`) | en, pt_BR, de at 200% |

The rest of M26's list, for home:

- **The key frame's state, with and without the notice.** Covered in the table above.
- **Signed in and signed out.** Home draws the same either way. It shows no name, account or sign-in mark, and a player the age check bars from an account never reaches home (`_ready` sends them to `age`).
- **Every tab.** Home is the bar's Home tab, so the bar on home always has Home chosen. The other tabs are other screens, each with its own fit check.
- **The longest names.** These are the locales' strings. pt_BR and de are the longest, fr and pt_PT are in the cases above, and all seven realms' names are on the map in every case except `OUTER=0`.

Each case is one run of the shot:

```
FIT=1 TEXT=200 LOCALE=pt_BR NOTICE=1 bash tools/render/shoot.sh client/tests/shots/universe_home.gd out.png
```

In every 200% case the four side buttons show as discs and the seven realms show as numbered chips (German without the notice: icon and level, objection (f)). In pt_BR at 200% without the notice, the goal card now ends at about y 948 and the bar's gold edge is at 960 (540 × 1170 render), against 920 and 991 on board 3b.

**Draw calls.** `bash tools/ui_bake/guard.sh` on the merge 00b9a23e:

| Shot | Draw calls | Recorded | Textures | Words below 4.5:1 |
|---|---:|---:|---|---:|
| home/100 | 144 | 145 | 4.7 MiB | 0 of 28 |
| home/200 | 121 | 119 | 4.9 MiB | 0 of 14 |
| home/hc | 144 | 145 | 4.7 MiB | 0 of 28 |

Guard fails on home/200 alone, 2 over its record and 29 under the cap of 150; that rise is S2-R30 to the lead. Main's home files on the same tree read 119, and so does this branch with the right edge left in the band. So the two come from where the right edge's two discs draw: between the keeper plate and the purse, where in the band they drew after the left edge's. The still is the same either way except for those two discs. Other orders tried: the edge first in the top row (which also puts the keeper plate on the right, so not kept), 120; the edge drawn over the rest (`z_index` 1), 121; both edges drawn over the rest, 121; the keeper plate drawn over the rest, 121. The textures and the words below 4.5:1 are unchanged.

**Still worse, or open.**

- **The goal keeps three lines at 200% in pt_BR, pt_PT and fr.** Even its first half cannot fit one line at 85% (Part 3, (d)); the Portuguese string is S2-R19's.
- **At 200% in German with the raid notice up, the notice still drops its red disc** (Part 3). The alarm glyph on the tag stays.
- **At large text the right edge's discs are in the top row, not in a column beside the band**, where both 200% key frames draw them. The key frames keep one row of the purse where strain sits beside it; home's purse takes two rows in every language at large text (Part 3, C). Both edges in the band leave the realms no room with the notice up, so AD may weigh the place on the board.

## Part 5: the purse's counts in the kit's display type (P2-S2-home-5)

The gate's last verdict on home at 100% (`verdicts/P2-S2-home-1/977edd5b.json`) failed Display type: the purse's counts read as flat cream. This task first asked the gate to re-run 'home at 100% text' and 'home in high contrast' on current main (`f083c96c`), to learn whether that fail still stands.

**Does the fail still stand?** No verdict on main had come back when this part was written: the lead's branch at `2ab3a985` has no `verdicts/P2-S2-home-5/`. S2's own still of main at 100% (`FIT=1 bash tools/render/shoot.sh client/tests/shots/universe_home.gd out.png` on `f083c96c`) still shows the counts as flat cream type, for the reason below, so S2 took the fail to stand and built the fix. The gate request at the ready commit covers the fixed home.

**Why the counts read flat.** The counts and the keeper's name were drawn in the kit's small display role (`display_s`) through the theme, which draws the role's 2-point ink outline and its 1.5-point drop with no outline of its own. The outline covers the drop, so no drop shows. On the purse's near-black plates, the ink outline does not show either, so the counts read as plain cream type.

**What changed.**

- **The counts are in the kit's baked numerals** (kit-spec.md section 2.2, T3, as K23's Currency pill specifies): a gradient fill, a thick ink stroke and a hard drop, from `num_white` on `kit_3.webp`. `HomeParts.figures` builds them with `KitNumerals.make` in a row that takes the amount label's place. The words after the figures ("k", " mil", " Tsd.") stay live type beside them. The hidden label keeps its words, so a screen reader and the purse's fit still read them. The renown ("1,460", K23) and, at large text, the strain card's share ("82%") take the same figures, through `Home.home_figure`. The share used to be handed to `figures` before it stood in its card, so it stayed live; it is now placed first.
  - **They are baked only where the purse's row fits them at full size** (`Home._fit_amounts`, `HomeParts.amounts_over`). The baked figures have fixed advances and run about a fifth wider than the live face. Where the row does not fit them at full size, the amounts stay live type, which may shrink to 85% as before. In M26's fit stills they are baked in English and French at 100% and 200%, and in every language at 150%, where the purse takes two rows of wider pills. They stay live in German and Portuguese at 100% and 200% ("142,0 Tsd.", "142,0 mil"). Baking them there broke the purse into three rows at 200% in pt_BR and hid two side buttons. The renown's single count is baked in every case.
  - **Their size** is 90% of the role's line (`FIGURE_LINE`), foot on the line's foot. At the full line the figures stood taller and higher than the live "k" beside them. At this share their bodies match the live face and stand on its baseline.
- **The keeper's name and every live word in home's figures take a heavier T2** (`HomeParts.inked`): the ink outline is half again as thick as the role's, and the drop is the glyph's own shadow, set down by that outline and by the role's drop half again, so a hard drop shows under the stroke. `character_screen.gd`'s upgrade title gives its shadow an outline as thick as the stroke instead. Here that cost one more draw call per label and took home/100 to 151, over §21.3's limit of 150.
- **The baked rows stand one layer above the words** (`UI.WORDS_Z` + 1). In the art's layer, a row from the numerals' page between the pills' faces split their batch, and home/200 went from 121 to 123 draw calls. Above the words, every row draws in one call: home/100 and home/hc 142, home/200 117, against the recorded 145, 145 and 121. Nothing on home is drawn over the counts but its full-screen layers, which stand `UI.OVERLAY_Z` higher.
- **Full hangs a little higher at 100%** (`HomeParts.FULL_LIFT`, 8 points beyond half its plate). The baked figures' tops stand higher than the live type's did, and the tag covered the top of the third pill's "0".

**Evidence.**

- **Fit (M26).** `FIT=1` prints "fit ok" in all 56 cases: the five languages at 100%, with and without the notice; 900 and 960 tall; high contrast in en and pt_BR; the widest amounts (`MOST=1`); 150% in four languages, with the notice, the widest amounts and 960 tall; 200% in all five languages with and without the notice, at 900 tall, in high contrast (en, pt_BR, de), with the widest amounts and 99 raids, and the new Keeper (`EMPTY=1`). Each case is `FIT=1 <flags> bash tools/render/shoot.sh client/tests/shots/universe_home.gd out.png`.
- **Draw calls (§21.3).** `python3 tools/ui_bake/budget_shots.py --only home/100,home/200,home/hc`:

  | Shot | Recorded | Main `f083c96c` | This task |
  |---|---:|---:|---:|
  | home/100 | 145 | 144 | 142 |
  | home/200 | 121 | 121 | 117 |
  | home/hc | 145 | 144 | 142 |

  The live share at large text drew in a call of its own; baked, it joins the rows' call. Contrast is unchanged: 0 words below 4.5:1 in each shot.
- **Stills.** The three budget stills (home at 100%, 200% and high contrast) show "Keeper 24" with a hard drop below its stroke, and "142.0k", "31.4k", "61.0k", "1,460" and, at 200%, "82%" in the baked figures.

## Part 6: one big-number treatment (P2-S2-home-6)

The gate's advisory verdict on home-5 (`verdicts/P2-S2-home-5/eb40e8f4.json`) failed Display type on 'home at 100% text' and 'home at 200% text, pt_BR', 0 of 3 samples each. Hierarchy and Character presence passed. The judge saw two faults:

- **"Keeper 24" had a drop but no outline that showed.** Its ink outline merged into the dark starfield behind it, so only the drop read. The rubric fails a drop standing in for the outline.
- **The headline counts did not share one heavy treatment.** The `num_white` baked figures read as a flat, pale fill on the near-black plates. In German and Portuguese the purse's counts stayed live type. At 100%, "82%" was live type in the strain pill.

**What changed.**

- **Every headline count is in the kit's gold baked numerals** (`num_gold`, T3), not `num_white` (`HomeParts.FIGURE_FINISH`). That covers the purse's three counts, the renown ("1,460", "1.460") and the strain share ("82%"). At the still's scale the white finish's pale white-to-lavender gradient and thinner stroke read as a flat light fill. The gold's cream-to-amber gradient, thick ink stroke and hard drop read as what they are, as the counts on the pass anchor do (`proof-heist-hud.png`, "After"). The gold glyphs are also narrower for their height (advance 120 on a 210 px glyph, against 96 on 162), so they fit better.
- **The baked figures shrink before they go live** (`HomeParts.amounts_fit`). Before, the purse's amounts were baked only where their row fit them at full size, and otherwise stayed live type: German and Portuguese at 100% and 200%. Now they are baked first and shrink where the row needs it, to no less than 78% (`Home.BAKED_LEAST`). Only where even that does not fit do they fall back to live type, which keeps its own floor of 85% (`AMOUNT_LEAST`). The baked floor is lower because the figures' heavy stroke and drop read at a smaller size than the live face. German's "142,0 Tsd." needs 80% at 100% and at 200%, and pt_BR's "142,0 mil" 88% at 100%. English and French fit at full size.
- **The strain share is baked at every text size** (`HomeParts.large_strain`, now used at 100% too). Its card stacks the baked share over the band's name ("82%" over "Humming"), as it already did at large text.
- **The keeper's name over the starfield gets a band of the plates' leather rim round its ink** (`HomeParts.inked(l, over_art = true)`). The label's shadow is drawn in `leather_rim` with an outline as thick as the ink's plus 2.5 points, and set down by a third of that band. The ink outline then stands out all round against the rim, and the rim's heavier foot reads as the drop. Its outline stays at least 13% of the name's size (`OUTLINE_SHARE`, over the rubric's 12%) and never under 1.5 times the role's 2 points. The live words beside the figures on the plates ("k", " mil", " Tsd.") keep home-5's ink outline with a hard ink drop below it. A name with no figures to bake is the one that stands over the art (`Home.home_figure`).

**Tried and dropped.** A rim of 2 px with a 3 px drop: the drop set the band lower than its width, so no rim showed over the tops of the letters. The rim is now at least 3 px and set down by a third of itself.

**Evidence.**

- **Fit (M26).** `FIT=1` prints "fit ok" in all 57 cases on 4c242628, and every headline count in them is baked. The cases are Part 5's, plus the new Keeper at 100% and at 150% with the notice. That means the five languages at 100% and 200%, each with and without the notice; 900 and 960 points tall; high contrast in en and pt_BR at 100%, and in en, pt_BR and de at 200%; the widest amounts (`MOST=1`), with and without the notice, and with 99 raids; 150% in four languages; the new Keeper (`EMPTY=1`) with and without the Heart's neighbours and the notice. Each case is `FIT=1 <flags> bash tools/render/shoot.sh client/tests/shots/universe_home.gd out.png`.
- **Draw calls (§21.3).** `python3 tools/ui_bake/budget_shots.py --only home/100,home/200,home/hc`:

  | Shot | Recorded | home-5 (`eb40e8f4`) | This task |
  |---|---:|---:|---:|
  | home/100 | 145 | 142 | 143 |
  | home/200 | 121 | 117 | 118 |
  | home/hc | 145 | 142 | 143 |

  The one call more is the name's rim, its shadow's own outline. The baked share joins the rows' call. Contrast is unchanged: 0 words below 4.5:1 in each shot (worst 6.40, 8.94 in high contrast).
- **Stills.** At 100% in en, pt_BR and de, at 200% in pt_BR and in high contrast: "Keeper 24" (and "Guardião 24", "Hüter 24") cream in its ink outline, ringed by the leather rim. "142.0k", "142,0 mil", "142,0 Tsd.", "1,460", "1.460" and "82%" in the gold figures, each with its ink stroke and hard drop.

**Still worse, or open.**

- **The purse's counts shrink to fit in German and Portuguese.** They stand at 80% (German) and 88% (pt_BR at 100%) of the English counts' size. They keep the one treatment, only smaller.
- **A count that falls back to live type no longer takes the name's leather rim.** The purse's labels start as "–", which has no figures, so `home_figure` took them for words over the art. They are now marked as counts on a plate (`plated`). No fit case below falls back to live type, so no still shows this.
- **Part 4's and Part 3's open items stand.**

### The gate at e674b614: Display type at 100%

The gate's advisory verdict on home-6 (`verdicts/P2-S2-home-6/e674b614.json`) passed five of its six item-qualities, 3 of 3 samples each. Display type passed at 200% pt_BR and failed at 100%, 0 of 3. The judge's reason: at 100% the headline counts ("1,460" and the purse's "142.0k", "31.4k", "61.0k") were "flat gold fills on dark plates, with no ink outline, no hard drop and no gradient", while "Keeper 24" carried the stroked treatment. It named AD-R45 (a) as still open.

**Why the counts went flat at 100%.** The kit's gold glyphs are 210 px tall, and at 100% text they draw about 18 px tall. The kit's atlas pages are imported without mipmaps, so a glyph drawn at under a tenth of its size is sampled, not averaged. Its thin baked stroke and drop fall between the samples, and its gradient flattens to one gold. At 200% the glyphs draw twice as large and keep their own treatment, which is why that still passed.

**What changed.**

- **The baked figures carry an ink stroke and a hard drop drawn from the kit's own rows** (`HomeParts.InkedRow`, a `KitNumerals.Row` that `figures` builds in place of the kit's). Behind the figures sit eleven kit rows of the same glyphs (`InkedRow.Under`), tinted `ink_line`, one layer below them:
  - eight set off all round by 8% of the figures' size, at least 1 px: an ink stroke that adds to the glyphs' own;
  - three set off down and to the sides by the stroke plus 10% of the size: the hard drop.

  The fill on top is the kit glyph's own cream-to-gold gradient, which still shows at 18 px (a test with a white foot matched the still). Home draws nothing of its own: every layer is the kit's row drawing the kit's glyphs, tinted and moved (`draw_set_transform`), so `check_screens.py` still counts 0 draws in `home_parts.gd`. A first build drew the layers itself with `draw_texture_rect_region`, which `check_screens.py` refused as screen chrome.

  The drop and the stroke share one tint: a tint change between layers splits the batch, two calls a row (home 152), and `drop` (`#0A0408`) and `ink_line` (`#1A0C14`) read the same. The figures stand two layers above the words and their ink one above, so every row's fill and every row's ink draw in one call each. The figures' cells and widths are unchanged, so the fit is the same.
- **AD-R45 (a): the live words on the plates** ("k", " mil", " Tsd."). They take the figures' `gold`, not cream, keep their ink stroke, and have no shadow. Before, their shadow was the bare glyphs set down by the outline and the drop, which showed as a second copy of the letters below them. AD's fix, a shadow as wide as the stroke and set down by the drop, cost a draw call a label (home 148, 123 and 148 at 100%, 200% and in high contrast, over the records of 145, 121 and 145), so S2 took AD's own fallback: drop the shadow on those words and keep the stroke. The figures' drop beside them carries the hard drop. A plated count that falls to live type (none in the fit cases) keeps the old drop.

**The plates.** The plates' fill (`#180D1C` in the still) is within a step of `ink_line` (`#1A0C14`). An ink stroke alone cannot show on it, which is the judges' close call at 200%. On the figures, the stroke and drop layers take the glyphs' own tones under their tint, so they draw darker than the plate, and the figures stand in a dark halo with a heavier foot. The live words' ink outline still matches the plate; their gold reads against it.

**A kit fix is better.** Mipmaps on the kit's pages (`kit_*.webp.import`) and a mipmap filter in `KitNumerals.Row` would keep every screen's baked numerals sharp at small sizes. That is K1's file, so S2 asked the lead for it (S2-R35). Until then, home layers the kit's rows.

**Evidence.** Stills at 100% in en and de and at 200% in en. Every count shows the cream-to-gold gradient, the ink stroke all round and the hard drop, and the words after it are gold. Draw calls on home (`budget_shots.py`): 143 at 100%, 118 at 200% and 143 in high contrast (records 145, 121, 145; the same as before the task). `check_screens.py` OK. FIT=1 in M26's 57 cases on bac22476: all "fit ok".

## Part 7: the states the fixture lacked (P3-S2-home-states)

Board 3 carried a note through every round: the shot's fixture (`keyframe()` in `client/tests/shots/universe_home.gd`) had no notifications, no shield and no locked realm. So the dock's count badges, the Defence timer "5 h 12 min" and Lantern Vale's "Opens at Keeper 28" were never seen. This part adds what the design allows of them, and checks them.

**What changed.**

- **Lantern Vale is locked in the key frame's state.** `keyframe()` loads the sample universe with five outer realms open (`UniverseSample.view(5)`), so the sixth, Lantern Vale, is the next to open, blocked until Keeper 28. The map then draws its locked plate left of the Heart, where the key frame has it. When `OUTER` is given, the fixture keeps that count, so the cases that set it are unchanged.
- **The locked plate names its realm, and has a short form** (`client/world/universe_pins.gd`, granted to this task in cycle 119 under S2-R38 and S2-R40). It reads "Lantern Vale" over the lock and "Opens at Keeper 28" ("Abre no Guardião 28", "Öffnet bei Hüter 28"), as key frame 02 has it, on the map's dark pill (the done_when keeps it dark). Where that finds no place within reach of the island's rim, it takes the lock and "28" on the same pill before it hides, as the realm pins shrink to their level chips (`_shape`). That happens at 200% text, where the full plate is about as wide as the free band beside the left side buttons. So the locked realm reads in words at every size, never as a dark island alone. A Spire-locked realm takes the same two forms with the Spire's level. The plate's spoken name is the realm's name and its words. In both forms it keeps the side buttons' gutter (`safe_side_points`, 16 pt) from the screen's edges, after AD's preview of 4797b5c3 (S2-R36, note 1) found it about 4 pt from the left edge.
- **The Crew tab counts the idle crew** (`HomeParts.tab_badges`, from the roster's slice). The design's tutorial gives home "an idle-worker badge" once every producer is staffed (minutes 5 to 7). `keyframe()` adds two idle characters to the sample's four (two working, two idle), so four of the six are idle and the Crew tab shows "4", as in the key frame. The count is the kit's badge (`KitTabs.make`), a number on red, so it is not carried by colour alone, and its name is spoken (`KIT_TAB_BADGE`).
- **The Defence badge** still counts the raids not yet seen ("2"), as before.

**What is not built, and why.**

- **No shield timer on home.** The key frame shows "5 h 12 min" under the Defence button. The design document overrules that frame: its table of key-frame changes names "Home shield" and says "No timers on home; 12.3's protection said in words on the defence screen while it lasts; shields are never sold" (12.3, 18.8, 22.1), and the home's rules say "no timers on the home screen". The design outranks the task and the key frame, so home shows no timer. The lead confirmed it in cycle 119 (S2-R37), and the task's done_when now says so.
- **No counts on Laws, Heist, Friends or Shop, and Season keeps its "!".** The key frame shows Laws 1, Heist 2, Friends 1, Shop 1 and Season 3. The store holds no count for any of them: no unread laws, no ready heists, no friend requests, no shop offer counted, and the season track says only whether a reward can be claimed, which the Season button shows as "!". Making up a count would show the player a number that means nothing. The lead kept that in cycle 119 (S2-R39): home shows only the counts the store holds, and each other count comes with the task that puts its source in the store.

**AD's preview** (S2-R36, at 5d25f9cb, the state of 4797b5c3; board-3.md, "Preview of home-states"): no objection, three notes. (1) The plate sat inside the 16 pt gutter: fixed, as above. (2) At 200% the Defence badge's top touches the foot of the 61.0k plate, clear of the gauge's fill; AD asked for a drop of 2 to 4 pt only if the badge moves. It does not move in this task: the badge is the side button's, laid by `home.gd`, which is at gdlint's 1000 lines, and AD's default lets the stills stand. (3) The plate hid at 200%: fixed by the short form. AD previews the plate's new forms (S2-R42) before ready.

**Evidence.**

- **Fit.** All 57 of M26's cases print "fit ok" with `FIT=1` on e9285afd, at 100%, 150% and 200% text, in en, pt_BR, pt_PT, fr and de, with and without the raid notice, in high contrast, at 900 and 960 tall, with the widest amounts, 99 raids, an empty home, and no or six outer realms. (On 4797b5c3, before the plate's name and short form, and on ad6c25e7, before the gutter, all 57 passed too.)
- **Clear of the pins and the side buttons** (board 3's objection B), seen in the stills at 100% and 200% (en, pt_BR, de) and in high contrast. The Crew tab's "4" sits on the tab's top right, inside the bar, under no pin. The Defence badge "2" keeps its place beside the Defence button, and the pins give it room as before. At 100% the locked plate, now two lines, sits left of the Heart, 24 pt from the left edge, below the Lab button and clear of it, and over the Heart's island but clear of the Heart's pin (en, pt_BR and de, whose "Öffnet bei Hüter 28" is the widest). At 200% the short form "28" sits beside the Lab button, clear of it and of the realms' chips (en, pt_BR, de and high contrast).
- **Not by colour alone.** Every count is a number on its disc, with a dark outline in high contrast, and the tab's spoken name carries it (`KIT_TAB_BADGE`). The locked plate says its lock with the lock mark and words at every size: the realm's name and its opening level at 100% and 150%, the lock and "28" at 200%.
- **Draw calls** (`budget_shots.py --only home/100,home/200,home/hc` on e9285afd):

  | Shot | Before | Now | Record |
  |---|---:|---:|---:|
  | home/100 | 143 | 148 | 145 |
  | home/200 | 118 | 124 | 121 |
  | home/hc | 143 | 148 | 145 |

  The Crew tab's badge costs 3: KitTabs' own badge, measured as 146 with six outer realms against 143 with the badge taken out. The locked plate, in place of a sixth realm's pin, costs 2 at 100% (148 against 146); its name batches with its words and costs nothing. At 200% the plate used to hide and now shows its short form, which costs 3 (124 against 121 on 4797b5c3). Textures and words below 4.5:1 (none) pass their records in all three shots, and home stays under §21.3's cap of 150 (2 under at 100%). S2 asked the lead to record 148, 124 and 148 (S2-R41).

### AD's preview, second look (S2-R42)

AD previewed e9285afd and had no objection: all 8 cases fit, board 3's objection B holds in each, nothing by colour alone (`docs/art/ui-quality/gate/boards/board-3.md`, "Preview of home-states, second look (S2-R42)"). Two notes did not hold the task; neither is acted on:

- **At 200% the Defence badge's top overlapped the 61.0k plate's foot by 1 to 3 px.** Left as it is, AD's default. The drop AD suggested was tried: at large text the left edge's disc, when it carries a badge, stood in a holder taller than itself (`home.gd`, `_side`). With 8 pt, the extra height makes `_fit_edges` hide the whole left edge at 200% with the notice in pt_BR, pt_PT and fr (`fit FAIL side button defences hidden`, the same for lab). With 6 pt and 4 pt, pt_BR and pt_PT fit again but fr still loses the edge. A 1 to 3 px touch on a plate's foot costs less than losing Defence and Lab, so the drop was reverted (09f0f119). If the band gains height later, a 4 pt drop that applies only when the band has room is the way back.
- **At 200% in pt_BR and de the short form sits about 7 px from the Heart's "6" pin.** Left as it is: it is clear, and the pin is the Heart's own. AD's advice, should the map lose more height, is to anchor the pill under the island instead of beside the Heart.

## Left for other tasks

These widgets are no longer used by home, but they are outside this task's files:

- `client/world/universe_strain.gd`
- `client/world/universe_side.gd`
- `client/world/universe_notice.gd`
- `client/world/universe_collect.gd`

`UniverseGoal` is still used by `client/tests/universe_view_tests.gd`. `UniversePurse` keeps its `ORDER` and `FULL` for home; the coin flight no longer needs it (S2-R5, part 2). Retiring them is for a follow-up task.
