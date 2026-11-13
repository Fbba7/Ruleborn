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
- **In Portuguese, the goal gives way to Collect at 100% text.** "Coletar 3,4 mil" leaves less than the goal's narrowest (150 points) beside it, so Collect shows alone, as at large text in English. (No request: the goal's own screen still shows it.)
- **At 200% text, the chosen tab's name hides where it would wrap below its tile** ("Ilhas" in Portuguese); the other tabs show their icons alone there already. Each stays named aloud. (S2-R15)
- **Display type, the raised Heist tab and Collect's size are home's own.** The kit's parts set figures in the body face, have no raised tab, and do not size a button to its words, so home does these itself until the kit does. (S2-R12, S2-R14, S2-R15)
- **The raid notice's card is drawn in code.** `banner_alarm` has no shape of its own in the skin. It falls back to the red button's light face, on which white words measure 2.5 to 2.8:1. Home refills the box with the material's dark card colours. The line goes once the shape lands. (S2-R6)
- **The raid notice is composed by the screen.** `KitPanels.notice` (through `UI.banner`) frees itself after `banner_ms` unless the player keeps banners, and its cross frees the panel. Home's notice must stay until it is seen or dismissed (§21.8), and must come back when new raids arrive. At 150% text and above its words also need the card's whole width, with the mark, See and the cross in a row beneath; the kit's notice keeps them all in one row. So home composes the notice from `UI.panel`, `UI.status` and `UI.action`. (S2-R8)
- **Home reaches around `KitLayout.tap`.** The kit's tap stands inside the card's padding, so home moves it into a holder of the pill's own size and marks its button not frequent. Every tap also logs an error, because it connects `button_down` twice ("Signal 'button_down' is already connected"). The tap still works. (S2-R9)
- **At 200% text, the realms' pins hide as a set.** Even compact, the seven pins do not all find room there, so home shows the islands unnamed. (No request: the room is the screen's, and the islands are a few points wide at that size.)
- **At 200% text in Portuguese, the raid notice hides Collect** until the raids are seen or dismissed: the screen has no height for both. The goal and Collect come back with the foot. (No request: the room is the screen's.)
- **At 200% text in German, Collect shows its words without its picture.** (No request.)
- **At 200% text in Portuguese, the purse takes three rows.** "Pedras" and the widest amounts do not fit two pills to a row beside the badge, and the world shows only between the top and the tab bar. Nothing overlaps (FIT passes), but the universe is barely seen. (No request yet: a narrower pill is a kit question, to raise if AD objects.)

## Left for other tasks

These widgets are no longer used by home, but they are outside this task's files:

- `client/world/universe_strain.gd`
- `client/world/universe_side.gd`
- `client/world/universe_notice.gd`
- `client/world/universe_collect.gd`

`UniverseGoal` is still used by `client/tests/universe_view_tests.gd`. `UniversePurse` is still used by `client/world/universe_reward.gd`, the coin flight. Retiring them is for a follow-up task. The signature of `UniverseReward.fly` is S2-R5's.
