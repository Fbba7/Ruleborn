# T9 UI kit

Branch `claude/ui-kit`. Screens v3's design system, carried into Godot so every screen inherits it: tokens, one shader box for every surface, the three faces, a theme, the design's icons, components and motion. `docs/analysis/screens-v3/design-system.md` was the measurement; §21.8 (v3.7) and §20.8 are the rules.

## How to use it (for T5, T6, T7, T10)

Merge this branch, then:

- **Nothing to do for the basics.** `UI.frame`, `UI.panel`, `UI.plate`, `UI.button`, `UI.title`, `UI.label`, `UI.status`, `UI.banner` and `UI.field` draw the new look: the night backdrop with stars, violet cards, leather and gold buttons that squash and sink when pressed, parchment banners and fields, Manrope words and Marcellus titles. Labels take their colour from the surface they sit on (light on dark, brown ink on parchment), through the theme, so a label needs no colour of its own.
- **Pick a material:** `UI.panel("parchment")`, `UI.plate(words, "glass")`, `UI.action(text, call, "red")`, or `UI.dress(any_control, "card_selected")`. Materials: `card`, `card_selected`, `glass` (over the world), `leather`, `parchment`, `gold`, `gold_round`, `red`, `green`, `ghost`, `tab`, `tab_active`, `track`, `badge`, `frame_oak`, `frame_silver`, `frame_gold`, `frame_prismatic`, and `night` (the backdrop). Each is data in `client/ui/tokens.json` → `material`.
- **Type roles:** set `label.theme_type_variation` to `Kicker`, `Caption`, `LabelText`, `ButtonText`, `Body`, `BodyBold`, `Heading`, `Title`, `Hero`, `Number` (tabular), `NumberM`, `DisplayS`, `Display`, `DisplayXl`, `Tab`, `Secondary`, or the statuses `StatusAlarm`, `StatusSuccess`, `StatusInfo`. Fonts directly: `Tokens.font("ui", 800, tnum)`, `Tokens.font("title")`, `Tokens.font("display")`.
- **Icons:** `Icons.texture("resources/starlight")`, `Icons.view("schools/matter", 24)` (a TextureRect). 370 icons in 33 groups; `Icons.names()` lists them. (`Icons.get` is not possible in GDScript: every Object has `get`.)
- **Motion:** `Motion.enter(node, delay_ms)`, `Motion.cascade(parent)`, `Motion.pop(node)`, `Motion.sheet_in(node)`, `Motion.press(button, down)`, `Motion.fill(bar, to)`, `Motion.bob(node)`. All 150-250 ms easing out with no overshoot, each with its reduced-motion form.
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

## Stills

| | |
|---|---|
| Settings before | `docs/art/shots/ui-kit/settings-before.png` |
| Settings, round 1 | `docs/art/shots/ui-kit/settings-r1.png` |
| Materials and type | `docs/art/shots/ui-kit/sheet-materials-r1.png` |

Render any screen: `SCREEN=settings bash tools/render/shoot.sh client/tests/shots/ui_screen.gd out.png` (`HC=1` for high contrast, `TEXT=200`). The sheet: `PAGE=1 bash tools/render/shoot.sh client/tests/shots/ui_kit_sheet.gd out.png`.

## Where the document's own rules disagree (recorded, contrast wins)

- §21.8 says success words on a dark surface keep `#3FBF7F`; that is APCA Lc 54-55 on the card, under the Lc 60 bold words need by §21.8's own perceptual check. The kit uses the designs' light green `#8FF0A8` (Lc 82).
- §21.8 says red words on a dark surface are `#FF9AAA`; on 78% glass over a day sky that is Lc 55-58. The kit uses `#FFB0BC` (Lc 63-71 over every sky).
- Green buttons carry cream words with a 2-point ink outline (the designs' CLAIM and UPGRADE), measured against the outline.

## Still worse than the design

(To be filled per round once the design stills land.)

## Next

Components (tab bar, header with back, segmented hub, resource pills, chips, badges, progress bars, sheets, dialogs, list rows), the component sheet's pages 2 and 3, and the screens judged beside `art/design/stills/screens/`.
