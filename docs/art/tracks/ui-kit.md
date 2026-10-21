# T9 UI kit

Branch `claude/ui-kit`. Screens v3's design system, carried into Godot so every screen inherits it: tokens, one shader box for every surface, the three faces, a theme, the design's icons, components and motion. `docs/analysis/screens-v3/design-system.md` was the measurement; §21.8 (v3.7) and §20.8 are the rules.

## How to use it (for T5, T6, T7, T10)

Merge this branch, then:

- **Nothing to do for the basics.** `UI.frame`, `UI.panel`, `UI.plate`, `UI.button`, `UI.title`, `UI.label`, `UI.status`, `UI.banner` and `UI.field` draw the new look: the night backdrop with stars, violet cards, leather and gold buttons that squash and sink when pressed, parchment banners and fields, Manrope words and Marcellus titles. Labels take their colour from the surface they sit on (light on dark, brown ink on parchment), through the theme, so a label needs no colour of its own.
- **Pick a material:** `UI.panel("parchment")`, `UI.plate(words, "glass")`, `UI.action(text, call, "red")`, or `UI.dress(any_control, "card_selected")`. Materials: `card`, `card_selected`, `glass` (over the world), `leather`, `parchment`, `gold`, `gold_round`, `red`, `green`, `ghost`, `tab`, `tab_active`, `track`, `badge`, `frame_oak`, `frame_silver`, `frame_gold`, `frame_prismatic`, and `night` (the backdrop). Each is data in `client/ui/tokens.json` → `material`.
- **Type roles:** set `label.theme_type_variation` to `Kicker`, `Caption`, `LabelText`, `ButtonText`, `Body`, `BodyBold`, `Heading`, `Title`, `Hero`, `Number` (tabular), `NumberM`, `DisplayS`, `Display`, `DisplayXl`, `Tab`, `Secondary`, or the statuses `StatusAlarm`, `StatusSuccess`, `StatusInfo`. Fonts directly: `Tokens.font("ui", 800, tnum)`, `Tokens.font("title")`, `Tokens.font("display")`.
- **Icons:** `Icons.texture("resources/starlight")`, `Icons.view("schools/matter", 24)` (a TextureRect). 370 icons in 33 groups; `Icons.names()` lists them. (`Icons.get` is not possible in GDScript: every Object has `get`.)
- **Motion:** `Motion.enter(node, delay_ms)`, `Motion.cascade(parent)`, `Motion.pop(node)`, `Motion.sheet_in(node)`, `Motion.press(button, down)`, `Motion.fill(bar, to)`, `Motion.bob(node)`. All 150-250 ms easing out with no overshoot, each with its reduced-motion form.
- **Components** (all at least 48 points, all writing their number or word beside any colour):
  - `KitNav`: `header(title, kicker)`, `rule()`, `back(call)`, `segmented(options, chosen, picked)`, `tabs(chosen, badges)` → `KitTabs` (signal `picked(id)`, `choose(id)`; Islands, Laws, Heist in the centre, Crew, Friends; lifted clear of the corners).
  - `KitControls`: `chip(text, on, call)`, `set_chip`, `icon_button(icon, spoken, call, look, points)`, `round_action(icon, words, call, main, points, badge)` (MAP, WEAVE, BUILD with their name plates), `toggle_row(icon, title, line, on, toggled_to)`.
  - `KitSwitch.make(on, on_words, off_words, spoken, toggled_to)`: a switch that says On or Off.
  - `KitStatus`: `badge(text)`, `pill(text, icon, look)`, `resource(icon, amount, fraction, tone)` + `set_resource` (storage line, FULL at 90%), `plate(text)`, `progress(done, of, words, tone)`.
  - `KitBar.make(fraction, tone, points)`: a `Range`, so `Motion.fill(bar, to)` moves it.
  - `KitHud`: `keeper(portrait, name, level, xp, renown)`, `goal(icon, words, done, of, count)`, `pips(left, of)`, `meter(level, of, words)`, `clock(text, warning)`.
  - `KitPanels`: `section(title)`, `row(icon, title, line, trailing, pressed)`, `link(...)`, `locked(icon, title, value, why)`, `sheet(title)` (body under meta `body`), `dialog(host, title, words, actions)`.
  - `KitCards`: `law_card(icon, title, school, rarity, rank, points)` (oak, silver, gold, prismatic frames, a window in the school's colours), `school_chip(school)`.
  - Sliders (`HSlider`) and scroll bars are themed.
- **Your own skins:** a control a script dresses in its own `StyleBoxFlat` with a fill keeps that look (the kit's box steps aside), and a label on such a light panel turns to ink by itself. So nothing breaks, but `FxSkin`, `StageHeroSkin` and `OverlaySheet.key` can now be replaced by the kit's materials.

## Done

Round 1 (00:00-00:45 UTC):

- `tokens.json`: the design's measured values as v3.7's §21.8 adopted them. All six school shadows and light tints, the surfaces (night, card, glass, leather, parchment, gold, red, green, the active tab, the four rarity frames), text colours per surface, 21 gradients, 20 materials, 15 type roles, fonts, radii, lines, drops, icon sizes, motion, and a high-contrast set that makes cards opaque, outlines 3 points, secondary text primary and glass solid. Every existing accessor and value still works (`ink`, `panel`, the day sky stay for the 3D and for scripts that read them).
- `tokens.gd`: `paint`, `gradient`, `gradient_shape`, `material`, `materials`, `type_role`, `type_roles`, `font`.
- `rb_box.gdshader` + `RbBox`: one quad per surface, a rounded signed-distance box with a gradient fill (linear at any angle, radial, conic; any number of stops through a 1D texture), ink outline, two inner rims, a lit top band and a dark bottom band, a hard drop, a soft shadow, a glow, wood grain for the oak frame, and star dots for the backdrop. It is an internal child drawn behind its host, so the host keeps its type (`PanelContainer`, `Button`, `LineEdit`, `TextureRect`) and its `StyleBoxFlat` (now clear), and other tracks' code that rounds or edges it still works.
- Fonts: Manrope (variable, 200-800), Lilita One and Marcellus, the full upstream families from Google Fonts, with each OFL text and `client/ui/fonts/LEDGER.md` (§21.11).
- `RbTheme`: the two families' themes (dark, light), a variation per type role with the designs' hard drop shadows and ink outlines, status colours per family, and scroll bars. `UI.root_theme()` puts the dark theme on the window, so a screen's own `Label.new()` is Manrope too.
- Icons: `tools/ui/export_icons.mjs` runs the design's `icons.js`, `school-marks.js` and the RBIcons block of `realm-diorama.js` in Chromium and writes 370 icons as SVG (kept from Godot's importer by `.gdignore`) and as 144-pixel PNG (quantised to 256 colours by `pack_icons.py`, 1.5 MB in all, mipmapped), with `manifest.json`; `Icons` reads it.
- `Motion`: entrances, cascade, pop, sheet, press squash, bar fill, bob, each reading reduced motion; nodes on their way in carry `entering` so the contrast check judges them as they will stand.
- `UI.*` upgraded in place: `frame` (night backdrop and stars, dark theme), `panel(look)`, `plate(words, look)`, `button` (gold main, leather, red and green by fill), the new `action(text, call, look)`, `set_look`, `dress`, `clear_box`, `title` (Marcellus with its drop), `label` (theme colour, adapts on foreign light panels), `status` (bold, per-family shades), `banner` (parchment, pops in), `field` (parchment), `set_outline` (a chosen control gets a gold edge and glow), `bold_font` (Manrope 800).
- Checks: `a11y_tests.gd` reads `text_bg` (the stops a material's words sit on), lays glass over §21.8's day, dusk and night skies, measures outlined words against their outline by §21.8's 1.5-point-or-12% rule, and checks every material's words and every family's statuses. `ui_kit_tests.gd` checks tokens, fonts (tabular figures measured), boxes, press, icons. `tests/shots/ui_a11y.gd` runs the kit and accessibility tests alone in 30 seconds.

## Which component each screen should switch to

Screens change look already through `UI.*`. These are the next steps, by owner, to reach the design's arrangement; each is a few lines in the screen's own file.

| Screen (owner) | Switch to |
|---|---|
| Home, universe and map (T4) | `KitHud.keeper` top left, `KitStatus.pill` for strain top right, a row of `KitStatus.resource` pills beneath, `KitControls.round_action` side buttons down both edges, a gold `UI.action` "Collect", `KitHud.goal` above `KitNav.tabs("islands")`. Island labels: `KitStatus.pill(name, "realms/<realm>", "parchment")`. The sheet's page 4 (`docs/art/shots/ui-kit/sheet-home-r3.png`) is this arrangement built from the kit. |
| Realm view (T6) | No tabs (as the design): `round_action` MAP and WEAVE (leather, badge "1 free") and BUILD (`main`, gold round) in the thumb's corners clear of the corner zone; resources as on home; the realm's name on `KitStatus.pill(..., "parchment")` instead of the Lilita parchment title; details in `KitPanels.sheet`. Drop `OverlaySheet.key` for `UI.action`. |
| Scout, planner, landing, observatory (T6) | Targets as `KitPanels.row` (icon, name, line, fee on a `KitStatus.plate`); laws as `KitCards.law_card` or `school_chip`; filters as `KitControls.chip`; the fee and clock as `KitStatus.pill`. |
| Curation, defences, rehearsal, builder (T6) | The Build / Terrain / Defence tray as `KitPanels.sheet` with `KitNav.segmented` for its tabs and `KitPanels.row` items with their cost on a plate. |
| Heist, replay, result (T5) | `KitHud.clock` (red under 30 s), `KitHud.meter(alarm, 6, "Alarm n / 6")`, `KitHud.pips(uses, 2)` on each crew portrait, loot on `KitStatus.pill`, Get out as `UI.action(..., "red")`, the hint bar as `KitStatus.pill(text)`; result reward lines as `KitPanels.row`. `FxSkin`'s glass, card and parchment boxes map to the materials `glass`, `card`, `parchment`. |
| Roster, character, Sage hall, Forms, Hatch, first launch (T7) | Hub tabs Roster / Sages / Forms as `KitNav.segmented`; levels on `KitStatus.plate`; XP and rest as `KitStatus.progress`; states as `KitStatus.pill` with the state's icon (`characterstates/*`); `StageHeroSkin.box` maps to `card`, its pills to `KitStatus.pill`. |
| Codex, law card, weaving, harmony, lab | `KitCards.law_card` in the law's rarity, `KitCards.school_chip`, mastery as `KitStatus.progress`, the Laws hub as `KitNav.segmented`, `KitNav.tabs("laws")`. |
| Settings | Rows as `KitControls.toggle_row`, `KitPanels.locked` for what the age band fixes, `KitPanels.link` for Profile, Privacy and Licences, volumes as themed `HSlider`, the tabs Wellbeing / Game / Access / Account as `KitNav.segmented`. |
| Profile, shop, season track, friends, social, share, workshop | `KitPanels.row` and `link`, `KitStatus.progress` for tiers, `KitControls.chip` for filters, `KitPanels.dialog` to confirm a purchase or a removal, `KitNav.tabs("friends")`. |

The header's back button: §21.1 (and `run.gd`'s layout check) keep frequent controls out of the top third, so `KitNav.header` carries none and `KitNav.back` belongs in the screen's lowest row, beside its main action. Whether the back button may stand at the top left as the design draws it is the owner's call (`screens-home-realm-shell.md`, finding H).

## Budgets

The kit draws about two draw calls per dressed control (its box, then its words), as the flat look did: measured on the same screens before and after, settings 54 → 55, home 48 → 49, realm 18 → 23 (`RENDERING_INFO_TOTAL_DRAW_CALLS_IN_FRAME`, the kit's shots print it). The densest sheet page (the home arrangement with 46 boxes) is 118. A list longer than about 40 dressed rows should be paged or virtualised to stay under §21.3's 150 with a world behind it. No post-processing: every effect is in the box's one quad.

## Stills

| | |
|---|---|
| Settings before | `docs/art/shots/ui-kit/settings-before.png` |
| Settings, round 1 | `docs/art/shots/ui-kit/settings-r1.png` |
| Materials and type | `docs/art/shots/ui-kit/sheet-materials-r1.png` |
| Controls (header, segmented, chips, buttons, round actions, switches, slider, locked row, field, tabs) | `docs/art/shots/ui-kit/sheet-controls-r4.png` |
| Status pieces (resources, pills, badges, plates, progress, rows, banners, sheet) | `docs/art/shots/ui-kit/sheet-status-r2.png` |
| The home arrangement from kit pieces, and the heist's clock, meter and pips | `docs/art/shots/ui-kit/sheet-home-r3.png` |
| Law cards in the four rarity frames, school chips | `docs/art/shots/ui-kit/sheet-cards-r4.png` |
| Settings, round 4: normal, high contrast, 200% text | `settings-r4.png`, `settings-hc-r4.png`, `settings-text200-r4.png` |

Render any screen: `SCREEN=settings bash tools/render/shoot.sh client/tests/shots/ui_screen.gd out.png` (`HC=1` for high contrast, `TEXT=200`). The sheet: `PAGE=1 bash tools/render/shoot.sh client/tests/shots/ui_kit_sheet.gd out.png`.

## Where the document's own rules disagree (recorded, contrast wins)

- §21.8 says success words on a dark surface keep `#3FBF7F`; that is APCA Lc 54-55 on the card, under the Lc 60 bold words need by §21.8's own perceptual check. The kit uses the designs' light green `#8FF0A8` (Lc 82).
- §21.8 says red words on a dark surface are `#FF9AAA`; on 78% glass over a day sky that is Lc 55-58. The kit uses `#FFB0BC` (Lc 63-71 over every sky).
- Green buttons carry cream words with a 2-point ink outline (the designs' CLAIM and UPGRADE), measured against the outline.

## Still worse than the design

(To be filled per round once the design stills land.)

## Next

Components (tab bar, header with back, segmented hub, resource pills, chips, badges, progress bars, sheets, dialogs, list rows), the component sheet's pages 2 and 3, and the screens judged beside `art/design/stills/screens/`.
