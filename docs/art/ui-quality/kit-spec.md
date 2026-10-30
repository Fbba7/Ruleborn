# The Ruleborn UI kit: specification (T16; owner and freeze rules by T17)

**Contract:** version 1. Sections 2–6 are frozen, version 1, as written by K1 on 30 October 2026; they take effect when the lead merges this page after the owner's approval at O2 (`docs/guides/agent-protocol.md`, worked example D). **Owner:** K1. **Consumers:** S1, S2, S3 (the screens), AIA and AIA-2 (the art the bake reads), AD and the gate (the catalogue and the names), and the lead (the hotspot files and `tools/check_all.sh`).

This is the kit the UI wave builds against: what the components are, the states each one has, the tokens they share, how they are named and laid out on disk, how a screen uses them, who may add one, and what happens to today's kit. The plan that builds it is `report.md` section 3. Where this page and the design document disagree, the design document wins (§23.5), and the disagreement is an owner decision in `report.md` section 12.

**This page is the kit contract.** Its owner is K1, the kit's one owner (`report.md` section 3.1). Sections 2–6 are frozen as version 1 at the end of the wave's phase 0, when the owner approves them with the style board (O2), and before any screen is built. After the freeze, screens consume the kit read-only, and a change to these sections goes through K1, needs the lead's approval, gets a dated line in section 9 with a new version, and counts as delivered only when every agent that uses the kit has acknowledged it (`docs/guides/agent-program.md`).

## 1. Principles

1. **One kit for every screen.** No screen draws its own chrome. Every panel, button, bar, badge and frame comes from the kit. A screen that needs something new asks for it (section 7).
2. **Art is baked, words are live.** Every surface is a baked picture from the kit's atlas: a 9-slice or a sprite. Every word is a live label from the strings tables, drawn in its own layer above the art (`report.md` section 10.4).
3. **Few parts.** At most 4 button styles, 3 frame families, 1 ribbon, 1 badge and 1 currency pill (rubric quality 11). Today's kit has 106 materials; this kit has 35 skins (section 8.2).
4. **Every state is drawn.** Each component has its states as baked faces, not as tints computed at run time, so pressed, disabled and locked look made, not dimmed.
5. **Every component has its high-contrast twin** and its reduced-motion form, or it does not ship.
6. **One API.** Screens keep calling the kit's functions they call today (`KitControls.action`, `KitStatus.resource` and the rest); the kit changes underneath. No screen names an atlas region.

## 2. Tokens

*Frozen, version 1.*

The tokens live in `client/ui/tokens.json` (K1's file), which already holds most of them. This section is the contract; the file is the one home of each value. Values here are quoted from it on 30 October (checked by K1 at the freeze); where the plan changes one, the change is marked. If a value here and the file ever differ, the file is right and this table is corrected by a dated line in section 9.

### 2.1 Colour roles

| Role | Token(s) today | Value | Rule |
|---|---|---|---|
| Ink (every outline) | `ink_line`; `ink` and `ink_deep` for ink-coloured fills and icon strokes | #1A0C14; #221C3A; #120C2A | §21.8: each surface family outlined in ink |
| Backdrop (menus) | `night_top`, `night_mid`, `night_bottom` | #2E1F5E, #140C30, #0A0620 | §21.2: menus stand on a night backdrop |
| Dark surface | `card_top`, `card_bottom` | #261A4C to #120A28 | §21.8 |
| Glass over the world | `glass` | #140A16 at 78% | §21.8; none in high contrast |
| Leather (secondary buttons) | `leather_light`, `leather_mid`, `leather_dark`, `leather_rim`; words `text_on_leather` | #6A3E52, #3A2030, #1E1018, rim #B8741E; words #F6E6C8 | §21.8 |
| Parchment surface | `parchment_top`, `parchment_bottom` | #FFFBF0 to #F1E3C4 | §21.8 |
| Text on dark: primary, secondary, tertiary | `text_on_night`, `text_on_night_2`, `text_on_night_3` | #F3EEFF, #E2D9F7, #B8A8D8 (no darker than #B8A8D8; tertiary bold) | §21.8 |
| Text on parchment: primary, secondary, tertiary | `parchment_ink`, `parchment_text_2`, `parchment_text_3` | #2A1A10, #54392A, #8A5A1C | §21.8 |
| Main action | `gold_top`, `gold`, `gold_bottom`, `gold_rim`; words `text_on_gold` | #F9DE9C, #E9B65C, #C88A35; words #1B1430 | §21.8: gold for main actions |
| Alarm | `alarm`, `alarm_fill`, `alarm_text`, `alarm_text_on_night`, `on_alarm` | colour #E2536B; fill under words #B3203A with paper words (`on_alarm`, #FCFBFF); words #9A1B32 bold on parchment; words #FFB0BC bold on dark (`alarm_text_on_night`: lighter than §21.8's #FF9AAA, which falls under APCA Lc 60 on glass over the day sky) | §21.8 |
| Success | `success`, `success_text`, `success_text_on_night` | fill #3FBF7F; words #8FF0A8 on dark, #155A38 bold on parchment | §21.8 |
| School colours and shadows | `motion` … `spirit`, `*_shadow`, `*_light` | §21.2's six | One set, no palette switch (§20.8) |
| Rank frames | gradients `frame_oak`, `frame_silver`, `frame_gold`, `frame_prismatic` | gradients | The only rank ladder the kit draws |
| Scrim | gradient `scrim` | #0A0620 at 70% to 85% | Modals dim the scene |
| High contrast | `color_high_contrast.*` | 15 overrides | §21.8: opaque cards, 3-point outlines, secondary raised to primary, no glass |

No word carries opacity (§21.8). No information is carried by colour alone (§20.8): every alarm, success, school and rank also has a shape or a word.

### 2.2 Type scale

| Role | Face | Weight | Points | Treatment |
|---|---|---|---|---|
| `kicker` | Manrope | 800 | 13, capitals, tracked | T1 on art |
| `caption` | Manrope | 600 | 13 | T0 or T1 |
| `tab` | Manrope | 800 | 13 | T1 when chosen |
| `label` | Manrope | 800 | 16 | T1 on art |
| `button` | Manrope | 800 | 16, capitals | T1 |
| `body`, `body_bold` | Manrope | 600, 800 | 16 | T0 |
| `number` | Manrope, tabular | 800 | 16 | T1 |
| `number_m` | Manrope, tabular | 800 | 22 | T1 |
| `heading` | Marcellus | 400 | 20 | T2 |
| `title` | Marcellus | 400 | 28 | T2 |
| `hero` | Marcellus | 400 | 34 | T2 |
| `display_s`, `display`, `display_xl` | Lilita One | 400 | 18, 28, 44 | T2; numbers that do not change |
| Baked numerals | pictures drawn with Lilita One | – | sized to their slot, at every text size | T3 |

Floors: 13 points everywhere, 16 for body text, at 100% to 200% text (§21.8, §20.8). A weight of 900 is drawn at 800. Which face carries labels and changing numbers on art is decision D4 (`report.md` section 12); this table is §21.8 as written.

**Treatments.**
- **T0 plain:** live text on a calm surface, measured against what is behind it at its worst point.
- **T1 outlined:** an ink outline all round, at least 1.5 points or 12% of the size (§21.8). Measured against the outline. Every word over art is T1 or T2.
- **T2 display:** T1 plus a hard drop (`drop` in the role). The drop does not count for contrast.
- **T3 baked numerals:** a gradient fill, a thick ink stroke and a hard drop, baked per glyph in four finishes (gold, white, timer, timer red, as the proof bakes them). The set is 0–9 and , . : / + − % × ? and a space, with a fixed advance for numbers that change. The proof's set lacks the full stop, the minus sign and the question mark; K1 adds them (`report.md` section 10.4). Each baked number keeps its spoken value.

### 2.3 Spacing, sizes and radii

| Token | Value (points) | Use |
|---|---|---|
| Base unit | 4 | Every gap and margin is a multiple |
| `gap_points`, `row_gap_points` | 8, 12 | Between controls; between rows |
| `safe_side_points`, `safe_top_points` | 16, 44 | Screen margins |
| `control_points` | 48 | Every hit area (§21.8, §21.1) |
| `action_round`, `back_round` | 60, 48 | Big round actions; back |
| `pill_points`, `badge_points`, `bar_points` | 36, 22, 12 | Heights |
| `tab_height`, `header_points` | 64, 56 | Tab bar; header |
| `icon_s`, `icon_m`, `icon_l`, `icon_tab` | 16, 24, 36, 45 | Icon sizes on the 24-point grid (§21.8) |
| `radius_xs` … `radius_xl` | 4, 8, 12, 16, 22 | Bars and pips; tags; pills; buttons; big cards |
| `widest_control_points` | 240 | Words wrap past this, so 200% text fits |

A baked 9-slice keeps its corner radius in its margins, so radii are fixed per skin, not per call. A skin is baked at the largest radius it is used at.

### 2.4 Elevation, stroke and outline

| Level | What it is | Tokens |
|---|---|---|
| E0 | Flat: wells, tracks | none |
| E1 | Small parts: chips, tags, pills | `drop_s` 2 |
| E2 | Buttons and cards: a solid lip | `drop_m` 4, `press_travel` 3 |
| E3 | Popups and sheets: lip plus a soft shadow, over the scrim | `drop_l` 5 |

Strokes: `line` 2 (the ink outline), `line_thin` 1.5, `line_heavy` 2.5, `line_hc` 3 in high contrast, never more than a fifth of a part's smaller side (T9's rule for thin bars). One light direction for every skin: from the top left, as the style board sets it.

### 2.5 Motion

| Token | Value | Use |
|---|---|---|
| `shortest_ms` … `longest_ms` | 150–250 | Every interface movement (§21.8) |
| `press_ms`, `press_squash` | 180, 0.96 | The press |
| `screen_out_ms`, `screen_fade_ms` | 160, 180 | Screen changes |
| `sheet_ms`, `pop_ms`, `rise_ms` | 250, 250, 220 | Sheets, popups, entrances |
| `stagger_ms` | 30 | Lists coming in |
| `bar_fill_ms` | 450 | A value changing, not a transition |
| `bob_ms`, `glow_ms` | 2400, 3200 | Idle loops |
| `fade_ms` | 150 | Every reduced form |
| `flash_hz_most`, `shake_px_most` | 3, 4 | §20.8, §21.8 |

Overshoot is not used unless the owner decides D3. The reward sequence's own curves go in `art/ui/motion/curves.json` (`report.md` step 7) and are read through the kit's `Motion`.

## 3. States

*Frozen, version 1.*

Every state is defined once here; section 4 says which components have which.

| State | Code | How it looks | Rules |
|---|---|---|---|
| Normal | N | The baked face | |
| Pressed | P | The pressed face: sunk by `press_travel` onto its lip, darker, squashed to `press_squash`; a light haptic tap (§21.8) | Reduced motion: the pressed face, no squash |
| Disabled | D | A flat face: no gloss and no lip, in a muted material, with a short reason on or beside it | Words keep 4.5:1, since words carry no opacity (§21.8); never shown by colour alone |
| Selected | S | A gold rim overlay and the raised face | Said aloud ("selected") |
| Locked | L | The locked material with a lock mark; a tap opens an info popover saying why and how to unlock | Not the same as disabled: locked things can be learned about |
| New or attention | A | A badge dot or count at the top right, inside the hit area; one idle pulse | Reduced motion: no pulse. At most one attention mark per component |
| Loading | Ld | The face held; the label replaced by a spinner sprite of the same size; said aloud as loading | Never longer than the action needs; no layout shift |
| High contrast | HC | The twin from the high-contrast atlas: opaque, 3-point outlines, secondary text raised to primary, no glass (§21.8) | Every skin has one; the bake refuses a skin without it |
| Reduced motion | RM | The component's reduced form (`report.md` section 10.3) | Every moving component has one |

## 4. Component inventory

*Frozen, version 1.*

Every component the five key screens (home, heist, result, character, settings) and the menus need, from today's kit (`client/ui/kit_*.gd`, `client/scripts/ui.gd`), T10's local layer (`client/scripts/screen_*.gd`), the heist proof and §21.8. "Today" names what draws it now. States use section 3's codes; HC applies to all.

### 4.1 Actions

| ID | Component | Variants | States | Built from | Today |
|---|---|---|---|---|---|
| K01 | Button | primary (gold), secondary (leather), tertiary (ghost), danger (red) | N P D S L A Ld RM | 9-slice face per state; live T1 label; optional icon | `UI.button`, `UI.action`, `KitControls.action`, `ScreenKit.button` |
| K02 | Big round action | Cast, Get out, the home's main action | N P D L A Ld RM | Round sprite per state; icon; label under | `KitControls.big_action`, `round_action`, proof's buttons |
| K03 | Icon button | round 48, square 48 | N P D S A RM | Small disc sprite; icon | `KitControls.icon_button`, `small_disc` |
| K04 | Close and back | close (×), back (round, lower band, §21.1) | N P RM | K03's skin; fixed icon | `KitNav.back`, `ScreenNav.back_button` |
| K05 | Toggle | on, off | N P D RM | Track and knob sprites | `KitSwitch`, `KitControls.toggle_row` |
| K06 | Slider | volume and similar (§20.8's separate volumes) | N P D RM | Track 9-slice, fill, knob | `RbTheme` slider styles |
| K07 | Segmented control | dark, light | N P D S RM | Track 9-slice, chosen face | `KitNav.segmented`, `ScreenParts.segmented` |
| K08 | Chip | filter, set, school | N P D S L RM | Pill 9-slice; school tint | `KitControls.chip`, `set_chip`, `ScreenParts.chip` |
| K09 | Tab bar | five tabs, Heist in the centre (§21.8) | N P S A RM | Bar 9-slice; tab faces; icons | `KitTabs`, `ScreenNav.bar` |
| K10 | Hub control | the Laws hub's gold control | N P S RM | Segmented skin in gold | `ScreenNav.hub` |
| K11 | Text field | search | N D S Ld | Glass well 9-slice | `KitControls.search` |

### 4.2 Containers

| ID | Component | Variants | States | Built from | Today |
|---|---|---|---|---|---|
| K12 | Panel | dark card, dark card lit, glass | N S L RM | 9-slice | `KitSkin.panel`, `UI.panel`, `ScreenKit.panel` |
| K13 | Parchment panel | plain, done | N S L | 9-slice | materials `parchment`, `parchment_done` |
| K14 | Rank frame | oak, silver, gold, prismatic | N S L | 9-slice frame around a panel | `frame_*` |
| K15 | Well | inset area inside a panel | N | 9-slice | `well` |
| K16 | Sheet | dark, parchment; from the bottom | N RM | 9-slice with a grab handle; over the scrim | `KitPanels.sheet` |
| K17 | Popup | dialog, confirm, info | N RM | E3 frame; a ribbon title (K19); one primary action | `KitPanels.dialog` |
| K18 | Header and top bar | title, title with resource pill | N | 9-slice band; T2 title | `KitNav.header`, `top_bar`, `ScreenNav.header` |
| K19 | Ribbon | section title, popup title | N | 9-slice ribbon; T2 words | `KitNav.hero`, `KitPanels.chapter` |
| K20 | List row | plain, with end control, tappable | N P D S L A | Row 9-slice; a wide end control goes under the words above 125% text (T9's rule) | `KitPanels.row`, `ScreenParts.item` |
| K21 | Section heading | plain | N | Live T0 or T1 words, a rule sprite | `KitPanels.section`, `ScreenParts.section` |
| K22 | Scrim and backdrop | night backdrop, scrim | N | A gradient texture (not 9-sliced) | `night`, `scrim`, `night_rays` |

### 4.3 Status and information

| ID | Component | Variants | States | Built from | Today |
|---|---|---|---|---|---|
| K23 | Currency pill | one per resource, with a storage bar | N P A RM | `pill` 9-slice; icon; T3 or `number` | `KitStatus.resource`, `ScreenParts.resource` |
| K24 | Counter | big number, rolling | N RM | T3 numerals | proof's loot count; `KitStatus.xp` |
| K25 | Progress bar | gold, green, red, school (tinted) | N L RM | Track 9-slice, fill 9-slice, target tick sprite | `KitBar`, `KitStatus.progress` |
| K26 | Ring and dial | cooldown dial, settings dial, lockout ring | N RM | Ring sprite; the sweep drawn as one triangle array (code, `KitTris`) | `KitHud.dial`, `KitRing` |
| K27 | Badge | count, dot | N A | One badge sprite; T1 count | `KitStatus.badge`, `ScreenParts.badge` |
| K28 | Tag and plate | status tag (success, warn, alarm, violet), name plate, price | N | Small 9-slice; T1 words | `KitStatus.tag`, `plate`, `sash`, `ScreenParts.status_plate` |
| K29 | Banner | info, success, alarm | N RM | 9-slice; icon; words; a close control | `UI.banner`, `KitPanels.notice` |
| K30 | Info popover | in place of a tooltip | N RM | Small E3 frame with a pointer; opened by a tap on an (i) control of 48 points, closed by a tap | none today |
| K31 | Heist clock and alarm meter | clock, six bells | N A RM | T3 timer numerals; bell sprites in three states | `KitHud.clock`, `alarm`, proof's HUD |
| K32 | Pips | ability uses with number (§21.8) | N RM | Pip sprites, hollow when spent; a number beside | `KitHud.pips`, `fx_portrait.gd`'s segments |
| K33 | Hint | the heist's hint over the world | N RM | Glass 9-slice; words that wrap | `KitStatus.hint` |
| K34 | Spinner | loading | RM | One sprite, rotated; reduced: a static mark with "Loading" | none today |
| K35 | Empty state | a list with nothing in it | N | Icon, words, one action | `ScreenParts.empty` |

**There is no toast.** §21.8: "A notice that carries information is a banner that stays until dismissed when the player chooses, never a toast that clears itself." K29 is the only notice. **There is no hover tooltip**: a phone has no hover, and §20.8 rules out anything that needs a long press without a two-tap form. K30 opens on a tap.

### 4.4 Identity and portraits

| ID | Component | Variants | States | Built from | Today |
|---|---|---|---|---|---|
| K36 | Avatar | player, friend | N P S A | Disc frame sprite; picture inside (its own canvas item) | `KitSocial.avatar` |
| K37 | Portrait disc | crew, Sage, guard; school ground | N P S D L A RM | Disc frame, school-tinted ground, the rendered portrait in its own canvas item | `KitHud.crew`, `KitCards.portrait`, `UiqMedal` |
| K38 | Level disc | keeper level, building level | N A | Disc sprite; T3 or T1 number | `level_disc`, `KitHud.keeper` |

### 4.5 Rewards and cards

| ID | Component | Variants | States | Built from | Today |
|---|---|---|---|---|---|
| K39 | Reward tile | per reward kind, on a sunburst when revealed | N S L A RM | Tile 9-slice; 256-pixel reward icon; T3 amount | `KitCards.reward`, `season_reward` |
| K40 | Reward sequence | anticipation, burst, reveal, coin flight, counter roll | RM | Motion sprites and curves (`report.md` step 7) | `KitNav.celebrate`, proof's coin flight |
| K41 | Stat tile | icon, kicker, value, gain | N A | Tile 9-slice; K25 pills | `KitCards.stat`, `ScreenParts.stat` |
| K42 | Streak and week tiles | done, today, later | N S | Tile sprites | `KitHud.streak`, `week` |
| K43 | Quest card | in progress, done, claim | N P A Ld | K13 parchment; K25 bar; K01 claim | `KitPanels.quest` |
| K44 | Law card and law disc | by school; known, unknown | N P S L A | School frame shape (§21.8); a plate under a light school title | `KitCards.law_card`, `law_disc`, `law_chip` |
| K45 | Product card | shop | N P D S L | Card 9-slice; icon; price tag (K28) | `KitCards.product` |
| K46 | Loot panel | Room, Left, load bar, target tick (§21.8) | N RM | K12 glass; K25; T3 | `KitHud.loot`, proof's loot panel |
| K47 | Album, build and fact cards | as today | N P S L | K12 or K13 | `KitCards.album_card`, `build_card`, `fact` |

**Code-drawn on purpose.** Charts (`KitChart`), the hex map (`KitHex`), the rail (`KitRail`), sweeps and ticks (`KitTris`, `KitTicks`) draw data, not chrome: their shapes change with the numbers. They stay code, with their colours from the tokens and their discs and frames from the atlas.

## 5. Anatomy: how a component is baked

*Frozen, version 1.*

- **Faces.** A component's face is a 9-slice (frames, panels, buttons, bars, pills) or a sprite (discs, pips, bells, icons). Each face is baked per state that changes its picture: normal, pressed, disabled, locked; selected and attention are overlays (a rim, a badge), so they combine with any face.
- **Layers, bottom to top:** the face; the icon; overlays (selected rim, lock, attention badge); then, in their own z layer, the live words (`report.md` section 7's rule 2). Portraits and other textured polygons are separate canvas items.
- **School variants** are one neutral face tinted by vertex colour, with the ink, gloss and outline in an untinted layer (`report.md` section 10.5).
- **Sizes.** 9-slices stretch with their words, so 200% text widens a button rather than shrinking its words. Sprites are baked at the size they show at 200% text and drawn smaller below it, never larger.
- **Budget per component:** one draw call for its faces, batched with every other component in the same atlas, plus its words' layer.

## 6. Inside the kit: names, files and use

*Frozen, version 1.*

### 6.1 Names

- **Components:** `K01`–`K47` in this page; in code, the existing classes and functions (section 8).
- **Skins** (the 35 baked looks, section 8.2): lower case, in words: `button_primary`, `panel_dark`, `frame_gold`.
- **Pieces in an atlas:** `<skin>__<shape>__<state>`, for example `button_primary__capsule__pressed`, `disc_portrait__48__normal`. The high-contrast twin has the same name in the `_hc` atlas.
- **Numerals:** `num_<finish>_<glyph>`, as the proof names them (`num_gold_7`, `num_timer_colon`).

### 6.2 Files

| What | Where | Owner |
|---|---|---|
| This specification | `docs/art/ui-quality/kit-spec.md` | K1 in the UI wave (`report.md` section 3.1) |
| Tokens | `client/ui/tokens.json` | K1 |
| Palette for the art | `art/ui/palette.json` (generated from the tokens by the bake) | AIA |
| Skin sources | `art/ui/kit/<skin>/<shape>.svg` | AIA |
| Baked atlases and manifests | `client/ui/art/<family>.webp`, `<family>_hc.webp`, `<family>.json`: `kit`, `icons_48`, `icons_256`, `motion` (written only by the bake, section 6.6) | AIA, through K1's bake |
| Kit code | `client/ui/kit_*.gd`, `client/scripts/ui.gd`, `client/ui/kit_skin.gd` | K1 |
| The switch per skin | `client/ui/kit_families.json` (section 6.7) | K1 |
| The bake, its guards and their baselines | `tools/ui_bake/**`, `tools/ui_bake/budgets.json` | K1 |
| Catalogue shot | `client/tests/shots/ui_kit_catalogue.gd` | K1 |
| Catalogue stills | `docs/art/shots/ui-bake/catalogue-*.png` | K1 |
| Gate verdicts | `docs/art/ui-quality/gate/verdicts/` | the gate |
| Component requests | raised in the requesting agent's own status file; answered in section 7's request log | K1 |

The palette is generated from `tokens.json`, so the colours have one home.

### 6.3 How a screen uses a component

- Through the kit's function (section 6.5), with words from the strings tables (`Strings.t(key)`, never a literal) and a spoken name where the function takes one: `KitControls.big_action("door", Strings.t("HEIST_GET_OUT"), on_press)`. The function picks the skin, the states, the words' layer and the reduced form.
- A screen may choose a variant ("primary", "danger") and a state ("disabled", with its reason key). It may not choose colours, radii, strokes or atlas regions.
- A screen never adds a `StyleBoxFlat` with a fill, a `draw_*` call for chrome, or a texture of its own for chrome. K1's check (section 7) counts them and refuses an increase.

### 6.4 The catalogue sheet

`client/tests/shots/ui_kit_catalogue.gd` renders every component in every state it has (section 4), in pages:
- normal and high contrast;
- 100% and 200% text;
- English and Brazilian Portuguese;
- motion components as frame strips, full and reduced.

Each page is one PNG in `docs/art/shots/ui-bake/` under 400 KB. The gate checks the catalogue as the "Kit art" class (`report.md` section 3.5), page by page at phone size. A test checks that the catalogue covers the inventory: every (component, state) pair in section 4 has a piece in the manifest and a place on a page, in both atlases.

### 6.5 The functions screens call

These are the kit's entry points, as they stand in the code on 30 October. A screen draws chrome only through them. Their names, parameter order and return types are frozen: within version 1 a function may gain a new optional parameter at the end, a new variant or look name, or a new function beside it (each a dated line in section 9), but nothing is renamed, reordered or removed. A parameter that is a look or a material name (`look`, `kind`, `tone`) takes the names of `tokens.json`'s materials or section 8.2's skins; the kit maps one onto the other (section 6.7).

| Class (file) | Functions |
|---|---|
| `UI` (`client/scripts/ui.gd`) | `px`, `text_px`, `motion_ms`, `frame`, `scroll`, `field`, `label`, `title`, `status`, `set_status`, `plate`, `panel`, `dress`, `clear_box`, `root_theme`, `button`, `action`, `set_look`, `bold_font`, `fit`, `relabel`, `fit_to`, `set_outline`, `narrow`, `row`, `grow`, `banner`, `school_mark` |
| `KitControls` | `chip`, `set_chip`, `action2`, `small_disc`, `tile`, `token`, `icon_button`, `round_action`, `toggle_row`, `school_button`, `search`, `big_action`, `upgrade` |
| `KitNav` | `header`, `rule`, `back`, `segmented`, `top_bar`, `hero`, `celebrate`, `logo`, `tabs` |
| `KitPanels` | `section`, `row`, `sheet`, `dialog`, `link`, `locked`, `chapter`, `album`, `quest`, `notice` |
| `KitStatus` | `badge`, `pill`, `set_pill`, `hint`, `resource`, `set_resource`, `plate`, `progress`, `strain`, `island_label`, `tag`, `xp`, `stat`, `sash` |
| `KitCards` | `school_chip`, `law_card`, `album_card`, `product`, `build_card`, `law_disc`, `stat`, `portrait`, `reward`, `law_chip`, `fact`, `season_reward`, `tone_ink`, `ability` |
| `KitSocial` | `avatar`, `tag`, `feed_row`, `log_row`, `text_link` |
| `KitHud` | `keeper`, `goal`, `pips`, `meter`, `clock`, `dial`, `streak`, `week`, `crew`, `alarm`, `figures`, `loot`, `sage` |
| `KitTabs`, `KitSwitch`, `KitBar` | `make` |
| `KitLayout` | `flow`, `strip`, `columns`, `grid_columns`, `grid`, `tap` (layout only: it draws nothing) |
| `KitSkin` | `material`, `clear`, `panel`, `button` (for other tracks' skins: `FxSkin`, `OverlaySheet`, `StageHeroSkin`) |
| `Motion` | `enter`, `cascade`, `pop`, `sheet_in`, `press`, `fill`, `bob`, `screen_in`, `glow` |
| `Tokens` | `color`, `number`, `list`, `shape`, `schools`, `paint`, `gradient`, `gradient_shape`, `material`, `materials`, `type_role`, `type_roles`, `font` (values for words, layout and data drawing; never for chrome of a screen's own, section 6.3) |
| `Icons` | `has`, `texture`, `names`, `view` |
| Data drawing (section 4.5) | `KitChart.make`, `KitHex.make`, `KitRail.make`, and the `KitTris`, `KitTicks`, `KitRing` nodes |

`RbTheme`, `RbBox` and `KitSkin`'s switch (section 6.7) are the kit's insides: screens do not call them, except `RbTheme.of` and `RbTheme.of_material`, which screens call today and keep until they move (section 8.1). The `Kit*` classes in `client/world/` (`KitStyle`, `KitGround`, `KitMap` and the rest) are the world's, not this kit's.

### 6.6 The manifest's format

Each bake family (`kit`, `icons_48`, `icons_256`, `motion`) is one atlas pair and one manifest in `client/ui/art/`: `<family>.webp`, `<family>_hc.webp` and `<family>.json`. The high-contrast atlas has the same size and the same layout as the normal one, so one manifest serves both and the kit swaps the texture, never the regions. The manifest is JSON, written only by `tools/ui_bake/bake.js`, with sorted keys and a final newline, so a rebake is byte for byte:

```json
{
  "format": 1,
  "family": "kit",
  "sources_hash": "sha256:<64 hex digits>",
  "atlas": {"normal": "kit.webp", "high_contrast": "kit_hc.webp", "width": 1024, "height": 1024},
  "px_per_point": 6,
  "pieces": {
    "button_primary__capsule__normal": {"x": 2, "y": 2, "w": 132, "h": 66, "slice": {"l": 30, "t": 24, "r": 30, "b": 30}, "tint": false},
    "disc_school__48__normal": {"x": 136, "y": 2, "w": 288, "h": 288, "slice": null, "tint": true},
    "num_gold_7": {"x": 426, "y": 2, "w": 64, "h": 84, "slice": null, "tint": false, "advance": 58}
  }
}
```

| Field | Rule |
|---|---|
| `format` | The manifest format's version: 1. A new field is optional and does not change it; a removed or renamed one does |
| `family` | The bake family; the file names follow it |
| `sources_hash` | SHA-256 over the family's sources in `art/ui/` (each source's path relative to `art/ui/`, a zero byte, its bytes, a zero byte, in sorted path order) and the bake's own scripts. `bake.js --check` recomputes it and compares, without rendering |
| `atlas` | The two textures, their size in pixels (each side a power of two, 2048 at most, section 10.1 of `report.md`) |
| `px_per_point` | The pixels per point the pieces are baked at: the size they show at 200% text (section 5). The kit draws a piece at `UI.px(1) / px_per_point` of its pixel size, scaled with the text |
| `pieces` | One entry per piece, named as section 6.1 says. `x`, `y`, `w`, `h` are its rectangle in pixels, the same in both atlases. `slice` is its 9-slice margins in pixels, or `null` for a sprite. `tint` is true for a neutral school piece the kit tints by vertex colour (section 5). `advance` is a numeral's fixed advance in pixels, on numerals only |

Every piece in a manifest has its twin in the `_hc` atlas, so the bake refuses a source without its high-contrast form (section 3). The kit reads only this file and the two atlases: no screen reads them.

### 6.7 The switch per skin

Each of section 8.2's 35 skins has one switch, in `client/ui/kit_families.json`: `{"<skin>": false, ...}`, every skin off until its art passes the gate (section 10.9 of `report.md`). Off, every material that maps onto the skin draws as today, through the code-drawn box (`RbBox`). On, it draws from the `kit` atlas. A piece the manifest lacks falls back to the code-drawn box and is logged, so a screen is never blank. The kit maps a material onto its skin by section 8.2's table; screens never name a skin's switch, and turning one on changes every screen that uses it together. A skin is switched on by K1's commit to that file, after the lead records the gate's pass.

### 6.8 The ownership map of the hotspot files

`report.md` section 3.1 names the files many agents touch. Each has one owner; anyone else asks the owner by a request in their own status file (section 7).

| Hotspot file | Owner | Note |
|---|---|---|
| `client/ui/tokens.json` | K1 | A value the design document sets changes only by owner decision first (section 7) |
| `client/ui/rb_theme.gd` (the theme) | K1 | |
| `client/ui/kit_skin.gd` (`KitSkin`) | K1 | |
| `client/ui/kit_families.json` (the switches) | K1 | |
| `client/scripts/ui.gd` and the rest of `client/ui/**` except `client/ui/art/**` | K1 | |
| `client/ui/art/**` (atlases and manifests) | AIA | Written only by K1's bake; neither edits them by hand |
| `art/ui/palette.json` | AIA | Generated from `tokens.json` by the bake; never edited by hand |
| `art/ui/**` except `art/ui/icons/**` | AIA | |
| `art/ui/icons/**` | AIA-2 | |
| `tools/ui_bake/**`, its baselines in `tools/ui_bake/budgets.json` included | K1 | A baseline rises only by request to K1 with the lead's approval, recorded beside it |
| `docs/art/ui-quality/gate/**` except `gate/verdicts/`, and `tools/ui_gate/**` | AD | |
| `docs/art/ui-quality/gate/verdicts/**` | Lead | Written as the gate's launcher |
| `client/project.godot`, the autoload registries, `client/export_presets.cfg` | Lead | |
| `tools/check_all.sh` | Lead | A new check is wired in by request to the lead |
| `client/i18n/strings.csv` | One owner at a time, named by the backlog's `strings_owner` (the lead on 30 October) | New keys are asked of that owner |
| `docs/progress/backlog.json`, `requests.md`, `owner-inbox.md` | Lead | |

## 7. Governance

- **Who adds a component.** Only K1 (its code) and AIA (its art), and only on a request. A screen agent that needs something writes a request in its own status file (never in another agent's file): what it needs, on which screen, and why no component in section 4 fits.
- **First, reuse.** K1 answers each request within the day, in the request log below: use an existing component or variant (most requests end here), add a variant, or add a component.
- **A new component passes the gate** like kit art (`report.md` section 3.5) and also: it uses only tokens; it has every state section 3 gives its kind, and its high-contrast twin; it keeps rubric quality 11's counts (4 button styles, 3 frame families, 1 ribbon, 1 badge, 1 currency pill), or the owner approves going over; it appears on the catalogue sheet; and this page lists it.
- **Changes to tokens** go through K1, and a change to a value the design document sets (a colour, a size floor, a timing) is an owner decision first.
- **The check.** K1 adds `tools/ui_bake/check_screens.py` to check_all: the number of fill `StyleBoxFlat`s, chrome `draw_*` calls and chrome textures in `client/scripts/` and `client/world/` may not rise above its recorded count, and falls as screens move. Today's 383 `draw_*` and `FxPen` calls (`report.md` section 2) are the starting count, less the data drawing of section 4.5.
- **This page changes** with a dated line in section 9, by K1. After the freeze, a change to sections 2–6 also needs the lead's approval and every consumer's acknowledgement (see the top of this page).

**Request log.** One row per request: the date, who asked, what for, and K1's answer (reuse, a new variant or a new component).

| Date | From | Request | Answer |
|---|---|---|---|

## 8. Mapping today's kit onto this one

### 8.1 Code

| Today | What it is | Fate | Into |
|---|---|---|---|
| `tokens.json` | Colours, sizes, motion, type, 106 materials | Kept | Section 2; materials consolidated into 35 skins (8.2) |
| `RbBox`, `rb_box.gdshader` | The code-drawn box | Kept as the fallback, then dropped | Each material family's switch (`report.md` section 10.9); dropped when every family is on |
| `RbTheme` | Godot themes per material | Re-skinned | Its styleboxes become texture-backed |
| `KitSkin` | Maps surface names to materials | Kept and extended | The switch per family; skin lookup |
| `UI.*` (`client/scripts/ui.gd`) | The old entry points | Kept (the API) | Calls the kit underneath |
| `KitControls`, `KitNav`, `KitPanels`, `KitStatus`, `KitCards`, `KitSocial`, `KitTabs`, `KitSwitch`, `KitLayout` | Components | Re-skinned | K01–K47; same functions |
| `KitHud` | Heist and home HUD parts | Re-skinned; heist parts replaced | The proof's HUD pieces (`UiqHud`) folded in |
| `KitNav.celebrate` | Today's reward moment | Replaced | K40, the reward sequence |
| `KitPanels.notice` | Notices | Re-skinned | K29, banner |
| `KitBar`, `KitRing` | Bars and rings | Re-skinned | K25, K26 |
| `KitTris`, `KitTicks`, `KitChart`, `KitHex`, `KitRail` | Data drawing | Kept as code | Section 4.5's code-drawn list |
| `Motion` | Motion with reduced forms | Kept | Reads `curves.json`; adds K40 |
| `Icons` and 375 icon PNGs | The design's icons | Kept as fallback | 60 replaced by AIA-2; the rest per decision D6 |
| `ScreenKit` (T10) | Its own materials and buttons | Re-skinned through `KitSkin` | S3's routing (`report.md` step 10) |
| `ScreenBox` (T10) | Its own box drawing | Dropped after S3's routing | – |
| `ScreenParts` (T10): pill, chip, badge, segmented, section, stat, item, resource, status plate, empty | Duplicates of kit parts | Replaced, one call at a time | The matching K-components; after this wave |
| `ScreenNav` (T10): header, dock, back, hub, bar | The shell | Re-skinned | K18, K04, K10, K09 |
| `FxSkin`, `StageHeroSkin`, `OverlaySheet`, `OverlayHud.badge` | Other tracks' skins | Kept | Already draw through `KitSkin` (T9's wave 5), so they inherit |
| `UiqArt`, `UiqHud`, `UiqMedal`, `UiqJuice` (the proof) | T14's prototype | Folded in, then deleted | `KitSkin`'s texture path, K31–K32, K37, `Motion` |

### 8.2 Materials into skins

Today's 106 materials become 35 baked skins. A material not listed is mapped by its family in the same way.

| Skin | Today's materials |
|---|---|
| `button_primary` | `gold`, `gold_round`, `plate_gold`, `reward_gold` |
| `button_secondary` | `leather`, `plate_leather` |
| `button_tertiary` | `ghost` |
| `button_danger` | `red`, `banner_alarm`, `tag_alarm` |
| `success` | `green`, `green_muted`, `banner_success`, `tag_success`, `reward_green` |
| `panel_dark` | `card`, `card_selected`, `card_gold`, `album`, `fact`, `ability`, `plate`, `plate_dark`, `banner_info` |
| `panel_glass` | `glass`, `field_glass`, `tag_dark` |
| `panel_parchment` | `parchment`, `parchment_done`, `sheet_parchment` |
| `well` | `well` |
| `sheet` | `sheet` |
| `popup` | (new: today's dialog uses `card`) |
| `frame_oak`, `frame_silver`, `frame_gold`, `frame_prismatic` | the same names |
| `header` | `tab_bar` (top use), `name_plate` |
| `ribbon` | `chapter`, `chapter_*` (tinted per school) |
| `tab_bar`, `tab`, `tab_active` | `tab_bar`, `tab`, `tab_active`, `tab_heist` |
| `segmented`, `segmented_on` | `seg`, `seg_light`, `seg_track`, `seg_track_light`, `seg_on`, `seg_on_light` |
| `chip`, `chip_on` | `chip`, `chip_light`, `chip_on`, `chip_on_light` |
| `bar_track`, `bar_fill` | `bar`, `bar_line`, `bar_track`, `bar_track_light`, `track`, `tier_band` |
| `disc` | `disc`, `icon_disc`, `level_disc`, `gem`, `round_sky`, `round_violet` |
| `disc_school` | `portrait_*`, `ring_*`, `window_*` (one neutral skin, tinted) |
| `badge` | `badge` |
| `tag` | `tag`, `tag_warn`, `tag_violet`, `tag_success`, `price_chip`, `island_label` |
| `tile` | `day_done`, `day_today`, `day_later`, `week_*`, `reward_sky`, `reward_pink` |
| `locked` | `locked` (an overlay and a face, section 3) |
| `pill` | `pill_gold_edge` and the resource pills (K23) |
| `toggle`, `slider` | (new: `KitSwitch` and `RbTheme`'s slider draw in code today) |
| backdrop (a gradient, not a skin) | `night`, `night_rays`, `scrim` |

That is 35 skins, counting each rank frame and each of the tab bar's three, against the rubric's limits: 4 button styles (primary, secondary, tertiary, danger), 3 frame families (dark, glass, parchment; the rank frames dress them), 1 ribbon, 1 badge, 1 currency pill. At 2–4 faces each and their twins, the kit is about 270 pieces: two 1024² atlases (8 MiB) with the numerals, inside `report.md` section 10.1's 24 MiB.

## 9. Changes to this page

- 28 October: written by T16 for the UI wave.
- 29 October: T17 (plan v3) made K1 the owner, added the freeze at the end of phase 0, and moved component requests into the requesters' own status files with this page's request log.
- 30 October: K1 checked sections 2–6 against `client/ui/tokens.json` and the kit's code and froze them as version 1. It corrected the colour rows to the file's values (ink, backdrop, dark surface, leather, text on dark and on parchment, gold, alarm, success, scrim), counted the materials (106, not 108; `banner_info` mapped to `panel_dark`), put section 6.3's example in `big_action`'s real order, and added sections 6.5 (the functions screens call), 6.6 (the manifest's format), 6.7 (the switch per skin) and 6.8 (the ownership map of the hotspot files).
