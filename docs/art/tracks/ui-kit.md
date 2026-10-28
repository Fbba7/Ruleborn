# T9 UI kit

Branch `claude/ui-kit`. Screens v3's design system, carried into Godot so every screen inherits it: tokens, one shader box for every surface, the three faces, a theme, the design's icons, components and motion. `docs/analysis/screens-v3/design-system.md` was the measurement; §21.8 (v3.7) and §20.8 are the rules.

## How to use it (for T5, T6, T7, T10)

Merge this branch, then:

- **Nothing to do for the basics.** `UI.frame`, `UI.panel`, `UI.plate`, `UI.button`, `UI.title`, `UI.label`, `UI.status`, `UI.banner` and `UI.field` draw the new look: the night backdrop with stars, violet cards, leather and gold buttons that squash and sink when pressed, parchment banners and fields, Manrope words and Marcellus titles. Labels take their colour from the surface they sit on (light on dark, brown ink on parchment), through the theme, so a label needs no colour of its own.
- **Pick a material:** `UI.panel("parchment")`, `UI.plate(words, "glass")`, `UI.action(text, call, "red")`, or `UI.dress(any_control, "card_selected")`. Materials: `card`, `card_selected`, `glass` (over the world), `leather`, `parchment`, `gold`, `gold_round`, `red`, `green`, `ghost`, `tab`, `tab_active`, `track`, `badge`, `frame_oak`, `frame_silver`, `frame_gold`, `frame_prismatic`, and `night` (the backdrop). Each is data in `client/ui/tokens.json` → `material`.
- **Type roles:** set `label.theme_type_variation` to `Kicker`, `Caption`, `LabelText`, `ButtonText`, `Body`, `BodyBold`, `Heading`, `Title`, `Hero`, `Number` (tabular), `NumberM`, `DisplayS`, `Display`, `DisplayXl`, `Tab`, `Secondary`, or the statuses `StatusAlarm`, `StatusSuccess`, `StatusInfo`. Fonts directly: `Tokens.font("ui", 800, tnum)`, `Tokens.font("title")`, `Tokens.font("display")`.
- **Icons:** `Icons.texture("resources/starlight")`, `Icons.view("schools/matter", 24)` (a TextureRect). 370 icons in 33 groups; `Icons.names()` lists them. (`Icons.get` is not possible in GDScript: every Object has `get`.)
- **Motion:** `Motion.enter(node, delay_ms)`, `Motion.cascade(parent)`, `Motion.pop(node)`, `Motion.sheet_in(node)`, `Motion.press(button, down)`, `Motion.fill(bar, to)`, `Motion.bob(node)`. All 150-250 ms easing out with no overshoot, each with its reduced-motion form.
- **Components** (all at least 48 points, all writing their number or word beside any colour). The sheet's pages show each in use: `PAGE=n bash tools/render/shoot.sh client/tests/shots/ui_kit_sheet.gd out.png` (1 materials and type, 2 controls, 3 status, 4 the home arrangement, 5 the Codex, 6 the design's Settings rebuilt from the kit, 7 the design's Roster pieces).
  - `KitNav`: `top_bar(title, back, chip)` (the design's sub-screen header), `header(title, kicker)`, `rule()`, `back(call)`, `segmented(options, chosen, picked)` (options as words or `[words, icon]`), `tabs(chosen, badges)` → `KitTabs` (signal `picked(id)`, `choose(id)`): the design's bar, full width and flush to the foot, the chosen tile rising above it, the Heist pulsing gold.
  - `KitControls`: `chip(text, on, call, count, dot)`, `set_chip`, `action2(text, line, call, look)`, `icon_button(icon, spoken, call, look, points, icon_points)`, `round_action(icon, words, call, main, points, badge, tone)` (tone `leather`, `violet`, `sky`; main is gold), `school_button(school, on, call)`, `search(spoken)`, `toggle_row(icon, title, line, on, toggled_to)`.
  - `KitSwitch.make(on, on_words, off_words, spoken, toggled_to)`: a switch that says On or Off.
  - `KitStatus`: `badge(text)`, `pill(text, icon, look)`, `strain(words, band)`, `resource(icon, amount, fraction, tone)` + `set_resource`, `plate(text)`, `progress(done, of, words, tone)`, `island_label(icon, name, level)`.
  - `KitBar.make(fraction, tone, points)`: a `Range`, so `Motion.fill(bar, to)` moves it.
  - `KitHud`: `keeper(portrait, name, level, xp, renown)`, `goal(icon, words, done, of, count)`, `pips(left, of)`, `meter(level, of, words)`, `clock(text, warning)`, `dial(number, unit, fraction)`, `week(minutes, letters, today)`.
  - `KitPanels`: `section(title)`, `row(icon, title, line, trailing, pressed, look)`, `link(...)`, `locked(icon, title, value, why)`, `chapter(school, title, kicker, count)`, `sheet(title, look)`, `dialog(host, title, words, actions)`, `notice(kind, icon, title, line, action, acted)` (the raid banner).
  - `KitCards`: `law_card(icon, title, school, rarity, tier, points, number)`, `portrait(picture, name, level, school, state, role_icon, pressed, chosen)`, `school_chip(school)`.
  - `KitRing`: a round picture in an XP ring, a pip, or (`heavy`) a dial.
  - Sliders (`HSlider`) and scroll bars are themed.
  - `Motion.screen_in(screen)` is the design's 160 ms screen fade from 0.985; the router could call it on each screen it shows (`client/app/router.gd` is the integrator's; not hooked, because other tracks' shot scripts settle in a few frames and would catch screens mid-fade).
- **Your own skins:** a control a script dresses in its own `StyleBoxFlat` with a fill keeps that look (the kit's box steps aside), and a label on such a light panel turns to ink by itself. Since wave 5, `FxSkin.panel`/`style_button`, `StageHeroSkin.plate`/`button`, `OverlaySheet.dress`/`key` and `OverlayHud.badge` draw through the kit (`KitSkin.panel(p, kind)`, `KitSkin.button(b, kind)`, `KitStatus.badge(text, look, points)`), so those screens already share its look.
- **Wave 5 additions** (sheet pages 4-14 show each in use):
  - Controls: `KitControls.round_action(..., disc_points)` and `icon_button(..., disc_points)` (a 36-point disc in a 48-point hit area; `small_disc(b, points)`), `tile(title, line, school, call)` (Easy / Medium / Hard).
  - Tabs: the design's own five icons; `tabs.face(id, texture)` puts a screen's character on its chosen tab; names show whole or not at all at any text size (drop your own fitting code).
  - Heist: `KitHud.crew(picture, name, health, uses, call, school)`, `KitHud.sage(picture, name, words, call)`, `KitHud.loot(rows, carried, mark, words)`, `KitStatus.hint(text)`.
  - People: `KitSocial.avatar(picture, initials, name, status, tone, call)`, `tag(words, tone)` (filled for "success", "warn", "violet", "alarm"), `feed_row(...)`, `log_row(...)`, `text_link(words, call)`.
  - Cards and panels: `KitPanels.album(school, title, kicker, count, body)`, `KitCards.album_card(...)`, `KitCards.product(picture, tag, title, price, call, look, points, icon)`, `KitStatus.sash(text)`, `KitChart.make(values, rules, from, to, spoken)`.
  - Layout: `KitLayout.strip(separation)` (a row that scrolls sideways; add to its child "Row").
  - Skins: `KitSkin.panel(p, kind)` and `KitSkin.button(b, kind)` (FxSkin, StageHeroSkin and OverlaySheet already call them).
  - Lower level: `RbBox.inset`, `RbBox.foot_points`, `KitRing.band` / `ground` / `zoom` / `focus`, `KitTris` (discs, rings and bars in one draw call).
  - `AUDIT=1` on `client/tests/shots/ui_screen.gd` lists where a screen draws past the kit (`UiAudit`).

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

## Wave 4: the merged branches green (from 22:40 UTC)

Main (`claude/videogame-project-analysis-ewkkk2`, 1e8619b) merged in clean. To find what the kit breaks once the screens sit on it, a scratch tree merged this branch with `ui-screens`, `3d-screens`, `3d-screens-world`, `3d-character-screens` and `3d-universe` and ran the client's tests.

What was the kit's, and is fixed here:

- **The chosen tab's word** (4.49:1 on the periwinkle tile, on every screen whose tab is chosen: Laws on Codex, Lab and Harmony, Friends on Friends). It is now stroked 2 points in ink, past §21.8's 12% of its 15 points, so it is measured against its outline, as the design draws it.
- **Words a screen puts inside a kit material** took the material's *family* colour (cream on dark, ink on light), not the material's own words and outline. A label on the red, the badge or the green was cream without its outline (Lc 58-73); a label on the gold was regular weight where only bold reaches §21.8's level. `UI.dress` now gives each control `RbTheme.of_material(look)`: the family's theme with the material's own words, secondary words, ink outline round every label, and bold words where the material says `bold_words` (the gold, silver, chip and segment golds, the school windows, the muted green, the locked teal: no ink reaches Lc 75 on those for regular words). Every theme states "no outline" for plain labels, because Godot hands a lookup a theme lacks to the next theme out, and a red outline otherwise leaked into ink plates beneath it.
- `RbTheme.adapt` marks a label `bold` when its font really is bold (Manrope 700 and up, or Lilita One), so the contrast check uses §21.8's bold level for words that are bold and only for them.
- **Secondary ink**: on parchment `#6B5040` (Lc 70) → `#54392A` (Lc 78); on dark `#D8CCF2` (Lc 74.9 on glass over the day sky) → `#E2D9F7` (Lc 82).
- **The chapter band's title** is 24 points (Marcellus is not bold, and the gold's deep stop allows Lc 69 at best), and the title and kicker wrap.
- **Large text**: `KitNav.segmented`'s words wrap inside their segment, each segment 48 points wide at least; `KitStatus.pill(text, icon, look, widest)` ends its words in an ellipsis past `widest` points (240), the label keeping all of them for the screen reader (`KitStatus.set_pill` refits new words); the tabs not chosen show only their icon above 125% text (folded in from T10's `ScreenNav.bar`); the top bar's title, the hero's title and kicker, the header's kicker, the meter's and alarm's words, and the card kickers wrap.
- **The kit's own check is stricter**: each material's words are checked at the weight a label in it is drawn in (regular, unless the material makes its words bold), so whatever a screen puts there reads.
- **Failure messages** name the screen, the words, the control's type and path from the screen, the kit material it sits in, the colour behind it and what §21.8 needed (`codex: "Motion" (Label .../Chapter/.../Label in the kit's chapter) is 9.51:1 Lc 67 on #e9b65c, needs 4.5:1 Lc 75 at 22 points`); the layout messages name a control by its words or spoken name and path, and a frame that is too wide names its widest words that will not wrap. (Two small hooks in `client/tests/run.gd`, the integrator's: `_control_name` and the widest-words line; the thumb-zone line is left as it is, since another branch changes it.)

- **Folded in from T10's `ScreenParts`**: `KitLayout.flow(separation)` (a row of chips or pills that wraps), `KitLayout.columns(children)` (side by side up to 125% text, stacked above), `KitLayout.grid(most)` and `grid_columns(most)` (a column fewer above 110%, two fewer above 150%), `KitLayout.tap(card, pressed, spoken)` (a whole card one control), and `KitStatus.stat(number, words, icon, look)` (the stat tile). `ScreenParts.recolour` is no longer needed: a label inside a material takes its words from it.

**Main itself is red in this container**: "against the server: Weaving offers the starting laws at the simulation's prices..." fails on `claude/videogame-project-analysis-ewkkk2` (checked in a clean worktree, 337 of 338). Weaving prices in the week's era (`service.era`, §18.3, counted from the first season's first day), and in this week's era the first recommended law, Slow rivers, costs 0 points, while the test asks for a price above 0. It turned red with the calendar, not with a commit; every branch inherits it. The fix belongs to the server's owner (pin the test server's clock, or let the test pick a law with a price); the kit does not touch it. Every stage of `check_all` after the client's passes on this branch (run by hand past that stop: "All checks passed."). This container also lacked the `wasm32-unknown-unknown` Rust target and Python's Playwright (1.63.0, to match the installed Chromium); both were installed, no code changed for them.

Still failing in the scratch merge, and not the kit's (for their owners):

- T6: `scout`'s "Under" line on the gold (its own regular-weight font; words on gold must be bold); `OverlayHud.badge` words now read; observatory's deck of cards is an `HBoxContainer` 4 × 900 px wide (it needs a horizontal `ScrollContainer`); Back and the main action sit in the bottom corners on observatory, scout and planner; curation's tab row `[Layout, Posts, Laws, Name]` does not wrap; defences' rows `[Control 138, VBox, VBox 144]` do not wrap.
- T10: codex's row `[Control 192 px, VBoxContainer 877 px]`; three unnamed buttons on weaving, six on codex, one on harmony.
- The scratch merge's own artifacts (strings, `role_numbers` in the native library) come from merging with `-X theirs` and an old native build, not from any branch.

### Wave 4 rounds against the design stills (after the green push)

Each round put a kit page beside its still at phone size; the three worst differences, then the fix.

1. **19 Settings, the feature card** (`vs-design-settings-w4r2.png`): the card was a flat violet with a heavy double gold rim; the design's is lit violet from its top left (`radial-gradient(ellipse 80% 110% at 0% 0%, #5A3CA8, #2A1A56, #170E32)`), an ink edge and one 1.5-pixel gold line inside. `card_gold` is now that, with a 1-pixel top light; its secondary words take the primary ink, since the lit corner leaves `#E2D9F7` at Lc 70. The week sits in a plain `well` (`rgba(6,3,16,.4)`, no edge), not a gold-framed strip. Scroll bars are not drawn (`scrollbar-width:none` in the design).
2. **19 Settings, the dial and the week**: `KitHud.dial` is the design's ring: a conic gold from `#F9DE9C` to `#F2B43C` over a dark track, ink edges, a gold halo and soft glow, a violet disc lit from above, a cream marker where the fill ends. The gradient arc is one coloured polyline and the disc one triangle fan (the first try with arcs per step cost 241 draw calls; now 85 for the page). Day bars are the design's flat violet (`week_day`) and today's gold glows (`week_today`), 24 points wide at most; day letters secondary, today's gold.
3. **01 Universe map, the tab bar**: it read as a rounded card with gold sides; the design's runs off the screen with only its gold top edge showing. `RbBox.bleed` runs a box past its host's sides and foot; the tab bar bleeds 32 points.
4. **10 Roster** (`vs-design-roster-w4r4.png`): the sheet's portrait cards carried role icons; they now show the characters' portraits (`Portrait.of`, the sheet waits for them), at the design's 3:4 (100 × 140 points).
5. **200% text and high contrast** (Settings): the box's gloss ended in a crisp edge capped at 66 pixels, which cut across words at 200%; it now fades out by half height.
6. **13 Codex** (`vs-design-codex-w4r6.png`): every chapter band was gold; the design colours each in its school (`linear-gradient(100deg, colour, shadow)`). `chapter_<school>` materials, cream words stroked 3 points in ink (no one ink reads on both the colour and its shadow), the count on a dark pill. Law cards three to a row (under 130 points) set the name from 15 down to 13 points so its longest word fits, and stack the school's mark over the rank.
7. **02 Heist**: my own regression from the large-text pass: the alarm's title wrapped and collapsed to "Alar / m" in its shrink-to-fit header (a wrapping label in a shrinking container has no width); it is one line again. Pills ellipsise only past 300 points, so the hint reads as the design's. The sheet's crew show their portraits.
8. **07 Heist result**: reward figures were the Lilita display face stroked in ink; the design's are Manrope 800 in plain ink. On light surfaces the theme no longer strokes ink words in ink (it only fattened them).

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

## Judged against the design's stills

`art/design/stills/screens/` landed at 01:00 and was merged in. Each round put a kit page beside the matching screen, at phone size and in grayscale:

| Still | What it shows |
|---|---|
| `vs-design-settings-r8.png` | 19 Settings beside the kit's page 6, built from kit pieces alone: the top bar, the icon strip, the gold-edged play-time card with its dial and week bars, the section heading, rows with option strips. Colours sampled from the design (backdrop exact, card edge #332753, foot #100924, track #0E0822, gold rim #B9945F). |
| `vs-design-roster-r9.png` | 10 Roster beside page 7: the hub strip, Assign and the two-line Level up, filters with dots and counts, portrait cards, the tab bar. |
| `vs-design-hud-r6.png` | 01's top HUD beside the kit's home arrangement: Keeper ring and gold level plate, Renown, the strain pill's band dot, resource pills with discs, FULL in gold and the glowing storage line. |
| `sheet-p2-r7.png`, `sheet-p3-r7.png` | 04's round actions (violet WEAVE with its "1 free", gold BUILD, sky MAP, plates over their feet) and 01's raid banner (a dark card glowing in its status's colour, icon disc, gold action, bare cross). |
| `sheet-codex-r6.png` | 13's Codex pieces: the strip, school filters ringed in their colours, the search field, the gold chapter band, law tiles with their number discs, rank words and frames. |

## Still worse than the design

- **Type is larger than the design's** everywhere, by rule: §21.8's 13-point floor and 16-point body text against the design's 9-11 px. Rows wrap where the design's fit on one line (a 4-segment strip with icons drops the design's capitals for plain case to fit at 13 points).
- **The tab bar sits higher** than the design's: on the client's 360-point frame five tabs cannot fit the middle 70% at 48 points with the chosen one widened, so §21.1's corner rule (and `run.gd`'s check) lifts the whole row 64 points above the foot, leaving a taller strip of bar under it than the design's home-bar gap.
- **The sub-screen back button** in `KitNav.top_bar` is at the top as the design draws it, which §21.1's thumb-zone rule and `run.gd`'s layout check forbid for a fixed control; a screen adopting it fails that check until the owner decides (finding H). `KitNav.back` in the lowest row is the compliant form.
- **Chosen tab art**: the design's chosen tab shows the screen's own character large (Pip's face on Crew); the kit shows the tab's icon at 46 points. A screen can put any texture in `KitTabs.buttons[id]`'s icon.
- **Dense pages cost draw calls**: about two per dressed control. The Roster page with six portrait cards and the tab bar is 142, the home arrangement 129; a real screen adds its 3D. Lists of more than about 40 dressed rows need paging.
- **Icons are 144-pixel rasters**: crisp up to 48 points; the chosen tab (46) and round actions (up to 42) are inside that, a hero icon larger than 48 points softens.
- **No wood-grain fidelity**: the oak frame's grain is a procedural streak, not the design's repeating board pattern.
- **Screens still mix skins**: T5's `FxSkin`, T6's `OverlaySheet` and T7's `StageHeroSkin` draw their own parchment titles and boxes beside the kit's; the table above says what each should switch to.

## Next

Components (tab bar, header with back, segmented hub, resource pills, chips, badges, progress bars, sheets, dialogs, list rows), the component sheet's pages 2 and 3, and the screens judged beside `art/design/stills/screens/`.

## Stopped here (wave 4, 04:45 UTC)

**Pushed**: the merge of main, the kit's share of the five failures fixed (contrast, large text, messages), KitLayout, KitStatus.stat, KitRail, KitCards.ability, and twelve rounds against the design stills (listed above). Every check is green on this branch except main's own week-dependent Weaving test (red on main too; see "Main itself is red" above).

**One hook outside the kit**: `tools/completion.py` cites the contrast test by its name, which the kit's first wave changed (it now also covers every material's words). Its proof line names the test as it is now; the old name passed only against a stale `client/status.json`.

**Still worse than the design**:
- Type is larger than the design's everywhere (§21.8's 13-point floor), so rows wrap where the design's fit one line, and law cards go three to a row where the design's go four.
- The design's slim Claim bar (28 pixels) and 36-point school filters are under §21.1's 48 points; the kit keeps 48.
- The tab bar still sits 20 points above the foot (§21.1's corner rule); the chosen tab shows the screen's icon, not the character's face, unless the screen sets it.
- The heist rail, the hero stage and the Codex's cream album panel are the screens' (T5, T7, T10); the kit gives pieces, not those arrangements.
- Dense pages run close to the draw-call budget: the Roster page is 142 and 134 at 200% text; KitRail alone is 26 draw calls.
- Not folded in yet: T5's `FxSkin`, T6's `OverlayHud.badge` and `OverlaySheet`, T7's `StageHeroSkin`.

**Next**: fold those in (OverlayHud.badge as KitStatus.badge with a look, StageHeroSkin's card as the `ability`/`card_gold` materials); a cream album panel under the chapter band (`KitPanels.album`); the chosen tab's face hook; draw KitRail's discs as one fan per disc to cut its draw calls; judge the remaining stills (05 Weaving, 08 Observatory, 14 Lab, 18 Shop, 27 Friends) beside kit pages.

## Wave 5 (from 17:50 UTC, 27 October)

Main (d2343591) merged clean.

**Done**
- **Tab names never cut** (T4's report). `KitTabs._fit` measures every name against its tab: where any tab not chosen would cut its word, they all show their icons alone (still named aloud); the chosen tab widens, up to three times a tab while the others keep their 54 points, to hold its whole word, and where even that cannot (200% in English, "FRIENDS") its word takes the largest size that fits, never under its 100% size. At 100% all five names show (the old 125% switch is gone). The chosen word's stroke is 13% of its drawn size at any text size. Icons not chosen are 36 points (from 30), nearer the design's. Test: "the tab bar shows every name whole at 100% text...".
- **Small disc** (T4's hook): `round_action(icon, words, call, false, 48, badge, tone, 36)` draws the designs' 36-point ball centred in a 48-point hit area, the plate and badge following the disc. Test: "a round action can draw its disc smaller than its hit area...".
- **The chosen tab's face**: `tabs.face("crew", Portrait.of("skyskipper"))`: 62 points, its head above the tile (sheet page 7).
- **Folded in**: `KitSkin` maps the other tracks' surface names (glass, card, parchment, leather, gold, alarm, night) to the kit's materials; `FxSkin.panel` and `style_button` (T5), `StageHeroSkin.plate` and `button` (T7), `OverlaySheet.dress`'s panels and `key` (T6) call it, and `OverlayHud.badge` is `KitStatus.badge(text, look, points)`. A few lines in each of those files, marked "Drawn by T9's kit".
- **`KitPanels.album`** (13 Codex): the band square at its foot on a cream album with an ink edge (sheet page 5).
- **KitRail** draws its rail and discs as one triangle array (`RenderingServer.canvas_item_add_triangle_array`), feathered a pixel: page 11 went from 63 to 41 draw calls, the picture unchanged.
- **Heist pieces for T5** (the integrator's verdict: plain-face crew, no Sage, "Left ?" with no load bar): `KitHud.loot`, `KitHud.sage`, and `KitHud.crew` on the school's ground (sheet page 9 beside 02-heist). `KitRing` draws its discs and rings through `KitTris` (one triangle array under the picture, one over): the heist page went from 145 to 85 draw calls.
- **People and shop pieces** (27 Friends, 18 Shop): `KitSocial.avatar` (portrait or initials in a ring, name, a status tag with a dot of its tone), `KitSocial.tag`, `KitSocial.feed_row` (parchment row: who, tag, when, what happened, a picture over Watch or Play, which goes under the words at large text); `KitLayout.strip` (a row that scrolls sideways, the designs' filter chips and decks); `KitCards.album_card` (13 Codex: the cream foot with name, rank in words and "In Skyfield"). Sheet pages 5 and 12.
- Stills: `vs-design-heist-w5r3.png`, `vs-design-codex-w5r4.png`, `vs-design-friends-w5r5.png`, `tabs-text-and-rail-w5r2.png` (the design's bar, then the kit's at 100, 150 and 200% text, then the rail before and after).

- **Rounds 6-9** (judged at 200% text and in high contrast): high contrast's 3-point outline swallowed every bar under 15 points tall (the load bar, health bars and storage lines drew as solid ink): an outline is now never more than a fifth of its box's smaller side. At 200% the kit's own Settings page cut its segments ("Wellb", "Acces"), spilled the dial's "MIN TODAY" past its ring and ran the top bar off the phone: segments now go two to a line with their words whole above 125%, the dial grows up to a third and wraps its unit, the top bar's pill goes under its title, and `KitPanels.row` puts a wide end control under its words (`settings-100-200-w5r8.png`). The chosen tab's word keeps 12 points inside its rim, the others give it room down to 48 points, and counts on badges grow to 150% text, no further, so at 200% they no longer cover the icons they count for. `KitCards.product` (18 Shop's picture cards). `KitStatus.sash(text)` (08 Observatory's gold band across a card's corner, the corner as large as its words need). The resource pill takes 6 points at its end (T4's measure). Test: "the loot panel, Sage, crew key, friend, feed row, album card, product and album meet 48 points and 13 points and stay on the screen at 200% text".

- **Round 10** (16 Defence log, after main's merge at 23:30): filled state tags (`tag_success`, `tag_warn`, `tag_violet`, `tag_alarm`, deepened until their words pass the kit's contrast check: the design's green and gold fail it), `KitSocial.tag(words, tone)` fills for those tones; `KitSocial.log_row` (who, tag, line; the result led by its glyph over a "Report ›" link); `KitSocial.text_link` (bold words on parchment, no box, 48-point hit area). Sheet page 13 beside the design (`vs-design-defence-log-w5r10.png`). Round 11: `KitControls.tile(title, line, school, call)` (the Observatory's Easy / Medium / Hard tiles, edged in a school's colour, the level in words) and `KitCards.product(..., icon)` with the currency's icon in the price pill. Round 12 (19b Player stats): `KitChart.make(values, rules, from, to, spoken)`, a line over time with its area fading from gold, rules with the screen's own number words, today's point on a dashed rule, spoken in words (sheet page 14, `vs-design-stats-w5r12.png`).

- **Round 13** (the tab bar against 01, 10 and 13): the tabs now use the design's own five icons (island with its house, the book, the loot bag, Pip, the two friends), taken from `art/design/screens/RulebornMeta.dc.html`'s tab bar by `tools/ui/export_icons.mjs` (new `--groups tabs`, which writes those groups and keeps every other icon), where the kit had stand-ins from the screens set. The chosen tab's picture stands large above its tile on every tab, not only where a screen gives a face. `tabs-w5r13.png`.
- **Round 16** (04's build tray): the light family for segments and chips on parchment (`KitNav.segmented(..., light)`, `KitControls.chip(..., light)`: a deeper parchment track, cream chips, the chosen one dark leather with cream words; materials `seg_track_light`, `seg_light`, `seg_on_light`, `chip_light`, `chip_on_light`); `KitCards.build_card` (the building's mark on a leather disc, name, line, price with its icon, "3 / 4"; three to a tray at 92 points). Segments are as wide as their longest word and wrap only between words ("Defenc / e" before). Sheet page 15, `vs-design-build-tray-w5r16.png`.
- **Round 15**: `KitStatus.hint(text)`, the heist's hint over the world, its words whole and wrapping where `KitStatus.pill` would end them in an ellipsis ("hold to sneak ..."). Every screen at 200% with the width probe (`WIDE=1`): none runs past the phone; the track's wide row sits in its own sideways container.
- **Round 14** (every sheet page at 200% for anything wider than the phone): a log row's result and a feed row's time pushed rows 1028 points wide; both now go under the words. The pieces test measures each piece's least width against the phone inside its margins (it fails on the old feed row).

**Consistency pass: where screens pass the kit by or differ from the design system**

`AUDIT=1` over all 33 screens on their samples found own fills only on the heist and replay (three `#FFFBF0` panels in the laws column); every other screen's boxes and faces are the kit's. What remains is arrangement, which is each screen's:

| Owner | Screen | Item |
|---|---|---|
| T5 | result | The design adds the entry fee returned, the Archivist's "try this" under the moment, and "Study one law you crossed" (three law tiles, +2 pages each); the world's particles run over the title. |
| T5 | heist, replay | Since main's 01:30 merge the heist draws the design's crew keys (school grounds, diamonds), the Sage over Cast and the load bar itself (`docs/art/shots/t5/w5_r8_heist_vs_design.png`): close to 02. The kit's `KitHud.crew`, `sage` and `loot` match them, so either can give way to the other later; the audit still finds three parchment panels of its own in the laws column. Heist is at 141 draw calls on `ui_screen.gd`: little room under 150. |
| T6 | realm | Round actions' plates in capitals (`round_action` does it; the realm's own keys say "Map"); the design's MAP and BUILD are 72-point discs low in the corners and WEAVE above MAP. |
| T6 | realm | The build tray as `KitPanels.sheet("", "sheet_parchment")` holding `KitNav.segmented([...], i, call, true)`, `KitControls.chip(..., true)` and `KitCards.build_card`s in a `KitLayout.strip` (sheet page 15). |
| T6 | defences | Three raw `Button.new()`s in `defences_screen.gd:231` draw Godot's own grey box (the audit's only new find after main's merge); the log as `KitSocial.log_row`s under three `KitStatus.stat` tiles and a `KitPanels.notice`, as the design (sheet page 13). |
| T6 | builder | The design's terrain editor heads with a budget bar ("94 left of 100 points") over three stat tiles (routes, fastest, seen), shows the picked tile on a card with its movement and guard-sight facts (`KitCards.fact`) and its law line, and a tray of tile cards (`KitLayout.strip`); the screen has the tray's tiles and a "Ready to raid" line. |
| T6 | scout | On the sample the screen shows only "Choose a target"; the design's report is a realm strip (`KitLayout.strip` of `KitControls.chip`s), three tabs (Land, Threats, Crew) and the land card with its vault dial (`KitHud.dial`) and PLAN THE HEIST (`KitControls.action2`). |
| T6 | observatory | The design keeps the tab bar (Heist chosen), puts the trace on a corner sash (`KitStatus.sash("Trace · 24 h")`), the target's Keeper on a portrait ring over the card's edge, and "Drifting ruins" as three tinted tiles (Easy, Medium, Hard) under the deck. |
| T7 | roster | Filters as `KitControls.chip(words, on, call, count, dot)` (the design's dot and count pill), not "○ free · 8" in the words; give the Crew tab Pip's face (`tabs.face`). |
| T10 | codex | Chapters as `KitPanels.album(...)` around `KitCards.album_card`s; the school filters as one `KitLayout.strip` row (they wrap to two lines now). |
| T10 | share | **Broken at 100% text since main's 23:00 merge**: `_poster` puts `ScreenParts.pill(..., true)` (its words wrapping) in `SIZE_SHRINK_CENTER`, so the kicker "Your island as a challenge" shrinks to one letter a line and pushes the card down the screen. Give the pill's label a least width, or drop the wrap and let `KitStatus.pill`'s ellipsis take over. |
| T10 | law | The design's law card is the frame with its stability on a number disc and its rank in the corner, a large mark in the window, "Mastered · Tier III" and where it is woven (`KitCards.law_card` and `album_card` carry each piece); FLIP CARD under it. |
| T10 | profile | Renown over time as `KitChart` (the design's 7D / 30D / Season over it as `KitNav.segmented`). |
| T10 | lab | The design's Lab is one "test realm" card (two large law discs linked across a small island, the result line, a gold RUN THE TEST), a strip of law tiles, and the resonances as a four-column grid of numbered tiles with their timers; the screen shows chambers instead. |
| T10 | shop | Category chips as a `KitLayout.strip` (the design's one sideways row); the design's featured set and daily picks are tall picture cards with a ribbon tag. |
| T10 | friends | The friends row as `KitSocial.avatar`s in a strip, the feed as `KitSocial.feed_row`s; the design leads with a "Friendly raid" card and Feed / Friends / Invite segments. |
| T10 | weaving | Cost, strain and ready-in as `KitStatus.stat` tiles; the deck as a `KitLayout.strip` of law cards; the call as `KitControls.action2` (its two lines). |
| T10 | settings | The design has four segments (Wellbeing, Game, Access, Account); the screen has two. At 200% text "Language" stands a letter a line beside "English (UK)" (`ScreenParts.item` keeps a wide control beside the title): `KitPanels.row` puts it under the words above 125%. |
| T4 | home | Side balls through `disc_points` 36 at 48-point hit areas; drop `_fit_tab_words` and the purse's own padding (the kit does both). |
| all | screens with a title | The design's sub-screen header (`KitNav.top_bar`) puts back at the top; §21.1's thumb rule keeps it at the foot (finding H, the owner's). |

## Stopped here (wave 5, 23:00 UTC)

**Pushed**: everything above through the sash and these notes; check_all passed on af7911c, 8027efc and this commit. The session's worker restarted three times between 20:20 and 22:50 UTC and the work in that gap was lost to waiting, not to code.

**Hooks outside the kit** (a few lines each, marked "Drawn by T9's kit"): `client/world/fx_skin.gd` (`panel`, `style_button`, T5), `client/world/stage_hero_skin.gd` (`plate`, `button`, T7), `client/world/overlay_sheet.gd` (`dress`, `key`, T6), `client/world/overlay_hud.gd` (`badge`, T6).

**Still worse than the design**:
- Type is larger than the design's (§21.8's 13-point floor): law cards three to a row where the design's go four, chips and tags wider.
- The tab bar still sits 20 points above the foot (§21.1's corner rule).
- At 200% text the round actions' plates ("DEFENCE") grow over the realm labels on home; the kit does not cap them, since they are words a player reads.
- The screens have not yet taken up this wave's pieces: the table above says which piece goes where (T5's crew, Sage and loot; T10's albums, strips and feed rows; T4's small discs).

**Next**: when screens adopt the pieces, re-run `AUDIT=1` and the design comparisons; a tinted difficulty tile (the Observatory's Easy / Medium / Hard); the gem icon inside a price pill.
