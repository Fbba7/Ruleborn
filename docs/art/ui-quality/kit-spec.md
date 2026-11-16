# The Ruleborn UI kit: specification (T16; owner and freeze rules by T17)

**Contract:** version 1. Sections 2–6 are frozen, version 1, as written by K1 on 30 October 2026 and revised on 31 October for AD's redirect at O2 (`gate/approvals/O2.md`, points K1–K3). At O2 (`report.md` section 3.4) AD approved sections 3, 4 (but K01's tertiary), 5 and 6, which are in effect; section 2 and K01's tertiary, as revised, take effect at AD's re-approval, O2-2 (`docs/guides/agent-protocol.md`, worked example D). Until then, O2.md's interim rulings hold. **Owner:** K1. **Consumers:** S1, S2, S3 (the screens), AIA and AIA-2 (the art the bake reads), AD and the gate (the catalogue and the names), and the lead (the hotspot files and `tools/check_all.sh`).

This is the kit the UI wave builds against: what the components are, the states each one has, the tokens they share, how they are named and laid out on disk, how a screen uses them, who may add one, and what happens to today's kit. The plan that builds it is `report.md` section 3. Where this page and the design document disagree, the design document wins (§23.5), and the disagreement is an owner decision in `report.md` section 12.

**This page is the kit contract.** Its owner is K1, the kit's one owner (`report.md` section 3.1). Sections 2–6 are frozen as version 1 at the end of the wave's phase 0, when AD approves them with the style board (O2, `report.md` section 3.4), and before any screen is built. After the freeze, screens consume the kit read-only, and a change to these sections goes through K1, needs the lead's approval, gets a dated line in section 9 with a new version, and counts as delivered only when every agent that uses the kit has acknowledged it (`docs/guides/agent-program.md`).

## 1. Principles

1. **One kit for every screen.** No screen draws its own chrome. Every panel, button, bar, badge and frame comes from the kit. A screen that needs something new asks for it (section 7).
2. **Art is baked, words are live.** Every surface is a baked picture from the kit's atlas: a 9-slice or a sprite. Every word is a live label from the strings tables, drawn in its own layer above the art (`report.md` section 10.4).
3. **Few parts.** At most 4 button styles, 3 frame families, 1 ribbon, 1 badge and 1 currency pill (rubric quality 11). Today's kit has 106 materials; this kit has 35 skins (section 8.2).
4. **Every state is drawn.** Each component has its states as baked faces, not as tints computed at run time, so pressed, disabled and locked look made, not dimmed.
5. **Every component has its high-contrast twin** and its reduced-motion form, or it does not ship.
6. **One API.** Screens keep calling the kit's functions they call today (`KitControls.action`, `KitStatus.resource` and the rest); the kit changes underneath. No screen names an atlas region.

## 2. Tokens

*Frozen, version 1; revised on 31 October for O2 (points K1 and K2), in effect at O2-2.*

The tokens live in `client/ui/tokens.json` (K1's file), which already holds most of them. This section is the contract; the file is the one home of each value. Values here are quoted from it on 30 October (checked by K1 at the freeze); where the plan changes one, the change is marked. **Marked "takes the design document's value"**: the row now quotes §21.2 or §21.8 instead of the file; `tokens.json` took these values in P0-K1-tokens (`card_bottom`, 31 October) and P0-K1-tokens-2 (the backdrop and red words on dark, 31 October: section 9). **Marked "pending owner decision"**: the row names its entry for the owner's decision brief (`docs/decisions/brief.json`, `docs/guides/design-tools.md`) and O2.md's interim ruling, which the kit follows until the owner answers. No row carries this mark since 4 November: the owner closed both, C74 (success words on dark) and C75 (the backdrop's shape), in `docs/decisions/owner-decisions.md` under "UI kit colours (C74, C75)". If a value here and the file ever differ, the file is right and this table is corrected by a dated line in section 9.

### 2.1 Colour roles

| Role | Token(s) today | Value | Rule |
|---|---|---|---|
| Ink (every outline) | `ink_line`; `ink` and `ink_deep` for ink-coloured fills and icon strokes | #1A0C14; #221C3A; #120C2A | §21.8: each surface family outlined in ink |
| Backdrop (menus) | `night_top`, `night_mid`, `night_bottom` | #171046 to #2C3AA8, a linear gradient read top to bottom in §21.2's order for the skies; `night_mid` is their midpoint, #222577. **Takes the design document's value**, in `tokens.json` since P0-K1-tokens-2 (it held the designs' #2E1F5E, #140C30, #0A0620). Words on the bare backdrop are measured at #2C3AA8, its lightest point: `text_on_night` for body text (Lc 85), `text_on_night_2` bold only (Lc 73); `text_on_night_3` (Lc 46) sits on a card, never on the bare backdrop. The shape is linear: the designs' sub-screens draw a radial (ellipse at the top centre, #2E1F5E, #140C30 at 55%, #0A0620), which §21.2's two values do not describe, and the owner's C75 (closed 4 November as A) keeps §21.2's linear values | §21.2: "Menus stand on a night backdrop (#171046 to #2C3AA8)" |
| Dark surface | `card_top`, `card_bottom` | #261A4C to #1A1134, §21.8's value, in `tokens.json` since P0-K1-tokens (it held the designs' #120A28; O2.md ruling 3) | §21.8: "a violet card from #261A4C to #1A1134" |
| Glass over the world | `glass` | #140A16 at 78% | §21.8; none in high contrast |
| Leather (secondary buttons) | `leather_light`, `leather_mid`, `leather_dark`, `leather_rim`; words `text_on_leather` | #6A3E52, #3A2030, #1E1018, rim #B8741E; words #F6E6C8 | §21.8 |
| Parchment surface | `parchment_top`, `parchment_bottom` | #FFFBF0 to #F1E3C4 | §21.8 |
| Text on dark: primary, secondary, tertiary | `text_on_night`, `text_on_night_2`, `text_on_night_3` | #F3EEFF, #E2D9F7, #B8A8D8 (no darker than #B8A8D8; tertiary bold) | §21.8 |
| Text on parchment: primary, secondary, tertiary | `parchment_ink`, `parchment_text_2`, `parchment_text_3` | #2A1A10, #54392A, #8A5A1C | §21.8 |
| Main action | `gold_top`, `gold`, `gold_bottom`, `gold_rim`; words `text_on_gold` | #F9DE9C, #E9B65C, #C88A35; words #1B1430 | §21.8: gold for main actions |
| Alarm | `alarm`, `alarm_fill`, `alarm_text`, `alarm_text_on_night`, `on_alarm` | colour #E2536B; fill under words #B3203A with paper words (`on_alarm`, #FCFBFF); words #9A1B32 bold on parchment; words #FF9AAA bold on dark (`alarm_text_on_night`). **Takes the design document's value**, in `tokens.json` since P0-K1-tokens-2 (it held #FFB0BC). Measured bold (4.5:1 and Lc 60, `client/ui/colour_check.gd`), #FF9AAA passes on the dark card (Lc 61–63 at its two stops) and fails on glass over the day sky (Lc 55–58), on the backdrop at #2C3AA8 (Lc 51) and on leather's light stop (Lc 50); there an alarm in words is carried on `alarm_fill`, paper on #B3203A (Lc 84), as §21.8 and O2.md ruling 1 say; the kit's `StatusAlarm` on a dark family draws that fill under its words, and none while it says nothing | §21.8: "on a dark surface red words are #FF9AAA, bold"; "text on an alarm fill is paper on #B3203A" |
| Success | `success`, `success_text`, `success_text_on_night` | fill #3FBF7F; words #155A38 bold on parchment; words on dark (`success_text_on_night`) #8FF0A8 at every size (Lc 72–84), by the owner's C74 (closed 4 November as A); #3FBF7F stays the green of fills, rings and marks, and is never words on dark. §21.8's #3FBF7F meets 4.5:1 on the dark card (6.7–7.6:1) but measures Lc 54–55 there, 48–51 on glass over the day sky and 43 on the backdrop at #2C3AA8, under the Lc 60 that bold words under 36 points need; ink on the #3FBF7F fill measures Lc 57.5 (on #3FBF7F even #000 ink reaches only Lc 58.2). O2.md's interim ruling 1, and AIA-R8's narrowing of it, fall away. §21.8's sentence "success words keep #3FBF7F" waits for the owner's next revision of the design document | §21.8: "success words keep #3FBF7F" |
| School colours and shadows | `motion` … `spirit`, `*_shadow`, `*_light` | §21.2's six | One set, no palette switch (§20.8) |
| Rank frames | gradients `frame_oak`, `frame_silver`, `frame_gold`, `frame_prismatic` | gradients | The only rank ladder the kit draws |
| Scrim | gradient `scrim` | #0A0620 at 70% to 85%; words on it are measured on #0A0620 (the material's own `text_bg`) | Modals dim the scene |
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
| `heading` | Marcellus | 400 | 20 | T2 over the world, gold, oak, leather or a school colour; T0 with its drop on the dark card and on parchment |
| `title` | Marcellus | 400 | 28 | The same as `heading` |
| `hero` | Marcellus | 400 | 34 | The same as `heading` |
| `display_s`, `display`, `display_xl` | Lilita One | 400 | 18, 28, 44 | T2; numbers that do not change |
| Baked numerals | pictures drawn with Lilita One | – | sized to their slot, at every text size | T3 |

Floors: 13 points everywhere, 16 for body text, at 100% to 200% text (§21.8, §20.8). A weight of 900 is drawn at 800. Which face carries labels and changing numbers on art is decision D4 (`report.md` section 12); this table is §21.8 as written.

**Treatments.**
- **T0 plain:** live text on a calm surface, measured against what is behind it at its worst point. The calm surfaces are the dark card and parchment. A Marcellus title (`heading`, `title`, `hero`) on one of them is T0 with its role's hard drop and no outline; the drop does not count for contrast.
- **T1 outlined:** an ink outline all round, at least 1.5 points or 12% of the size (§21.8). Measured against the outline. Every word over the world, gold, oak, leather or a school colour is T1 or T2.
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
| K01 | Button | primary (gold), secondary (leather), tertiary (an inked plate, below), danger (red) | N P D S L A Ld RM | 9-slice face per state; live T1 label; optional icon | `UI.button`, `UI.action`, `KitControls.action`, `ScreenKit.button` |
| K02 | Big round action | Cast, Get out, the home's main action | N P D L A Ld RM | Round sprite per state; icon; label under | `KitControls.big_action`, `round_action`, proof's buttons |
| K03 | Icon button | round 48, square 48 | N P D S A RM | Small disc sprite; icon | `KitControls.icon_button`, `small_disc` |
| K04 | Close and back | close (×), back (round, lower band, §21.1) | N P RM | K03's skin; fixed icon | `KitNav.back`, `ScreenNav.back_button` |
| K05 | Toggle | on, off | N P D RM | Track and knob sprites | `KitSwitch`, `KitControls.toggle_row` |
| K06 | Slider | volume and similar (§20.8's separate volumes) | N P D RM | Track 9-slice, fill, knob | `KitControls.slider` (on `RbTheme`'s slider styles) |
| K07 | Segmented control | dark, light | N P D S RM | Track 9-slice, chosen face | `KitNav.segmented`, `ScreenParts.segmented` |
| K08 | Chip | filter, set, school | N P D S L RM | Pill 9-slice; school tint | `KitControls.chip`, `set_chip`, `ScreenParts.chip` |
| K09 | Tab bar | five tabs, Heist in the centre (§21.8) | N P S A RM | Bar 9-slice; tab faces; icons | `KitTabs`, `ScreenNav.bar` |
| K10 | Hub control | the Laws hub's gold control | N P S RM | Segmented skin in gold | `ScreenNav.hub` |
| K11 | Text field | search | N D S Ld | Glass well 9-slice | `KitControls.search` |

**K01's tertiary** (revised on 31 October for O2, point K3; in effect at O2-2). The tertiary button is a made thing, not a ghost: an inked plate of the material it sits on. Its face is that material lifted, flat (one gradient lit from the top, no gloss band, no gold rim), at least two value steps off the surface under it (ΔL* ≥ 20, rubric quality 8, pass item 3) so that it reads as a control in greyscale; an ink edge all round of 2 points (3 in high contrast); a lip of 3 points. It has two face sets in its one skin, `button_tertiary`: violet, lifted from the dark card, on the dark card, glass and the backdrop; parchment, lifted from parchment, on parchment. Its label is T1 in the surface's primary words (`text_on_night`, or `parchment_ink`), in `button`. It never has a hairline border, a fill with opacity or a blur. The two faces' colours come from the board (AIA) and enter `tokens.json` with the skin; until then the skin's switch stays off (section 6.7) and today's `ghost` material draws. The kit keeps four button styles (rubric quality 11): the tertiary ranks below leather by having no gloss and no rim, not by being fainter.

### 4.2 Containers

| ID | Component | Variants | States | Built from | Today |
|---|---|---|---|---|---|
| K12 | Panel | dark card, dark card lit, glass | N S L RM | 9-slice | `KitSkin.panel`, `UI.panel`, `ScreenKit.panel` |
| K13 | Parchment panel | plain, done | N S L | 9-slice | materials `parchment`, `parchment_done` |
| K14 | Rank frame | oak, silver, gold, prismatic | N S L | 9-slice frame around a panel | `frame_*` |
| K15 | Well | inset area inside a panel | N | 9-slice | `well` |
| K16 | Sheet | dark, parchment; from the bottom | N RM | 9-slice with a grab handle; over the scrim | `KitPanels.sheet` |
| K17 | Popup | dialog, confirm, info | N RM | E3 frame; a ribbon title (K19); one primary action | `KitPanels.dialog` (`kind` confirm or info) |
| K18 | Header and top bar | title, title with resource pill | N | 9-slice band; T2 title | `KitNav.header`, `top_bar`, `ScreenNav.header` |
| K19 | Ribbon | section title, popup title | N | 9-slice ribbon; T2 words | `KitNav.hero`, `KitPanels.chapter`, `ribbon` |
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
| K30 | Info popover | in place of a tooltip | N RM | Small E3 frame with a pointer; opened by a tap on an (i) control of 48 points, closed by a tap | `KitPanels.info`, `popover` |
| K31 | Heist clock and alarm meter | clock, six bells | N A RM | T3 timer numerals; bell sprites in three states | `KitHud.clock`, `alarm`, `clock_large`, `alarm_fit`, proof's HUD |
| K32 | Pips | ability uses with number (§21.8) | N RM | Pip sprites, hollow when spent; a number beside | `KitHud.pips`, `fx_portrait.gd`'s segments |
| K33 | Hint | the heist's hint over the world | N RM | Glass 9-slice; words that wrap | `KitStatus.hint`, `KitHud.tip` |
| K34 | Spinner | loading | RM | One sprite, rotated; reduced: a static mark with "Loading" | `KitStatus.spinner`; the Ld state through `KitStatus.loading` |
| K35 | Empty state | a list with nothing in it | N | Icon, words, one action | `KitPanels.empty`, `ScreenParts.empty` |

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
| K40 | Reward sequence | anticipation, burst, reveal, coin flight, counter roll | RM | Motion sprites and curves (`report.md` step 7) | `KitNav.reward` (the one entry point; `KitNav.celebrate` stays as its alias), played by `Motion.reward` |
| K41 | Stat tile | icon, kicker, value, gain | N A | Tile 9-slice; K25 pills | `KitCards.stat`, `ScreenParts.stat` |
| K42 | Streak and week tiles | done, today, later | N S | Tile sprites | `KitHud.streak`, `week` |
| K43 | Quest card | in progress, done, claim | N P A Ld | K13 parchment; K25 bar; K01 claim | `KitPanels.quest` |
| K44 | Law card and law disc | by school; known, unknown | N P S L A | School frame shape (§21.8); a plate under a light school title | `KitCards.law_card`, `law_disc`, `law_chip`, `law_chip_fit` |
| K45 | Product card | shop | N P D S L | Card 9-slice; icon; price tag (K28) | `KitCards.product` |
| K46 | Loot panel | Room, Left, load bar, target tick (§21.8) | N RM | K12 glass; K25; T3 | `KitHud.loot`, `loot_fit`, proof's loot panel |
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
| `UI` (`client/scripts/ui.gd`) | `px`, `text_px`, `motion_ms`, `frame`, `scroll`, `field`, `label`, `title`, `status`, `set_status`, `plate`, `panel`, `dress`, `clear_box`, `root_theme`, `button`, `action`, `set_look`, `bold_font`, `fit`, `relabel`, `fit_to`, `set_outline`, `narrow`, `row`, `grow`, `banner`, `school_mark`, `world_words` |
| `KitControls` | `chip`, `set_chip`, `action2`, `small_disc`, `tile`, `token`, `icon_button`, `round_action`, `toggle_row`, `school_button`, `search`, `big_action`, `upgrade`, `slider` |
| `KitNav` | `header`, `rule`, `back`, `segmented`, `top_bar`, `hero`, `celebrate`, `logo`, `tabs`, `reward` |
| `KitPanels` | `section`, `row`, `sheet`, `dialog`, `link`, `locked`, `chapter`, `album`, `quest`, `notice`, `ribbon`, `popover`, `info`, `empty` |
| `KitStatus` | `badge`, `pill`, `set_pill`, `hint`, `resource`, `set_resource`, `plate`, `progress`, `strain`, `island_label`, `tag`, `xp`, `stat`, `sash`, `attention`, `spinner`, `loading`, `is_loading`, `locked`, `notice` |
| `KitCards` | `school_chip`, `law_card`, `album_card`, `product`, `build_card`, `law_disc`, `stat`, `portrait`, `reward`, `law_chip`, `fact`, `season_reward`, `tone_ink`, `ability`, `law_chip_fit`, `dark_icon` |
| `KitSocial` | `avatar`, `tag`, `feed_row`, `log_row`, `text_link` |
| `KitHud` | `keeper`, `goal`, `pips`, `meter`, `clock`, `dial`, `streak`, `week`, `crew`, `alarm`, `figures`, `loot`, `sage`, `clock_large`, `set_clock`, `alarm_fit`, `set_alarm`, `loot_fit`, `set_loot`, `tip` |
| `KitTabs`, `KitSwitch`, `KitBar` | `make`; `KitBar.aim` |
| `KitNumerals` (`client/ui/kit_numerals.gd`) | `number`, `make` (the baked numerals, sections 3 and 6.1) |
| `KitLayout` | `flow`, `strip`, `columns`, `grid_columns`, `grid`, `tap` (layout only: it draws nothing) |
| `KitSkin` | `material`, `clear`, `panel`, `button` (for other tracks' skins: `FxSkin`, `OverlaySheet`, `StageHeroSkin`) |
| `Motion` | `enter`, `cascade`, `pop`, `sheet_in`, `press`, `fill`, `bob`, `screen_in`, `glow`, `fly` |
| `Tokens` | `color`, `number`, `list`, `shape`, `schools`, `paint`, `gradient`, `gradient_shape`, `material`, `materials`, `type_role`, `type_roles`, `font` (values for words, layout and data drawing; never for chrome of a screen's own, section 6.3) |
| `Icons` | `has`, `texture`, `names`, `view` |
| Data drawing (section 4.5) | `KitChart.make`, `KitHex.make`, `KitRail.make`, and the `KitTris`, `KitTicks`, `KitRing` nodes |

`RbTheme`, `RbBox`, `UI.raise_words` and `KitSkin`'s switch (section 6.7) are the kit's insides: screens do not call them, except `RbTheme.of` and `RbTheme.of_material`, which screens call today and keep until they move (section 8.1). The `Kit*` classes in `client/world/` (`KitStyle`, `KitGround`, `KitMap` and the rest) are the world's, not this kit's.

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
| `atlas` | The two textures, their size in pixels (each side a power of two, 2048 at most, section 10.1 of `report.md`). A family that outgrows one 2048² page is baked into pages (AIA-R12): `atlas` names page 1, and `pages` lists every page in order, each `{"normal", "high_contrast", "width", "height"}`, its files `<family>_<n>.webp` and `<family>_<n>_hc.webp` from page 2. `pages` is written only when there is more than one |
| `px_per_point` | The pixels per point the pieces are baked at: the size they show at 200% text (section 5). The kit draws a piece at `UI.px(1) / px_per_point` of its pixel size, scaled with the text. `null` for a scene family (`icons_48`, `icons_256`), whose icons are baked at a fixed size in pixels by AIA-2's `bake_icons.js`, which `bake.js` runs for them |
| `pieces` | One entry per piece, named as section 6.1 says. `x`, `y`, `w`, `h` are its rectangle in pixels, the same in both atlases. `slice` is its 9-slice margins in pixels, or `null` for a sprite. `tint` is true for a neutral school piece the kit tints by vertex colour (section 5). `advance` is a numeral's fixed advance in pixels, on numerals only. `page` is the atlas page it is cut from, written only when it is 2 or more (absent means page 1) |

Every piece in a manifest has its twin in the `_hc` atlas, so the bake refuses a source without its high-contrast form (section 3). The kit reads only this file and its atlas pages: no screen reads them.

`bake.js --palette` writes `art/ui/palette.json` (section 6.2) from `client/ui/tokens.json`: its `color`, `color_high_contrast` and `gradient` groups, each gradient's stops as colours, and the file's `kit` section kept as it is (AIA-R10). `bake.js --check` fails when the file no longer matches the tokens (AIA-R11).

### 6.7 The switch per skin

Each of section 8.2's 35 skins has one switch, in `client/ui/kit_families.json`: `{"<skin>": false, ...}`, every skin off until its art passes the gate (section 10.9 of `report.md`). Off, every material that maps onto the skin draws as today, through the code-drawn box (`RbBox`). On, it draws from the `kit` atlas. On a parchment ground (the nearest surface around the control is drawn in `panel_parchment`), a skin's parchment face, `<skin>__parchment__<state>`, comes first; the tertiary (section 4.1) has only that face there, never its dark-ground one (AIA-R9). A piece the manifest lacks, in the control's state, falls back to the code-drawn box and is logged, so a screen is never blank; a disabled control is never drawn with its enabled face. Section 8.2 names the boxes that stay code-drawn unlogged. The kit maps a material onto its skin by section 8.2's table; screens never name a skin's switch, and turning one on changes every screen that uses it together. A skin is switched on by K1's commit to that file, after the lead records the gate's pass. A task that switches a skin on renders again every catalogue page that skin changes (section 6.4), in all eight variants, in the same task, and looks at each: a face that passed the gate on one host can be wrong on another. Beside the 35 skins' switches, one more, `numerals` (`KitSkin.BESIDE`), turns on the baked numerals (sections 3 and 6.1, `KitNumerals`); absent, it reads as off. It is on since 12 November (P1-K1-numerals-on), after P1-AIA-kit-3's numerals passed the gate (Display type, Colour roles and value): only the heist's timer draws `KitNumerals` today (`heist_hud.gd`, on `KitHud.clock_large`), so no catalogue page changes with it.

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
- **A new component passes the gate** like kit art (`report.md` section 3.5) and also: it uses only tokens; it has every state section 3 gives its kind, and its high-contrast twin; it keeps rubric quality 11's counts (4 button styles, 3 frame families, 1 ribbon, 1 badge, 1 currency pill), or AD approves going over; it appears on the catalogue sheet; and this page lists it.
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
| `KitNav.celebrate` | Today's reward moment | Replaced; kept as an alias | K40, the reward sequence: `KitNav.reward`, which `celebrate` calls with the screen alone |
| `KitPanels.notice` | Notices | Re-skinned | K29, banner |
| `KitBar`, `KitRing` | Bars and rings | Re-skinned | K25, K26 |
| `KitTris`, `KitTicks`, `KitChart`, `KitHex`, `KitRail` | Data drawing | Kept as code | Section 4.5's code-drawn list |
| `Motion` | Motion with reduced forms | Kept | Reads `curves.json`; adds K40 (`Motion.reward`, played through `KitNav.reward`) |
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
| `button_tertiary` | `ghost` (today's ghost is replaced by section 4.1's inked plate, not kept as a look) |
| `button_danger` | `red`, `banner_alarm`, `tag_alarm` |
| `success` | `green`, `green_muted`, `banner_success`, `reward_green` |
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

In code the table is `KitSkin.SKINS` (`client/ui/kit_skin.gd`), and `client/tests/ui_kit_tests.gd` fails if a material maps onto no skin. Where a material is named twice, it takes its first row: `card` is `panel_dark` (the new `popup` skin has no material yet), and `tag_success` is `tag` (since 9 November; AIA-R14: its own shape unbaked, it is drawn as the tag's box). `tab_bar` is the tab bar's skin, not the header's. Of the rows that name two or three skins, `tab_heist` is drawn as `tab`; `bar` and `bar_line` as `bar_fill`; `tier_band` as `bar_track`; and the `_on` materials as `segmented_on` and `chip_on`. `toggle`, `slider` and `popup` have their switches but no material: `KitSwitch` names the toggle's track (`toggle/track_on`, `toggle/track_off`) and draws its knob, `RbTheme`'s slider takes the slider's track, fill and knob, and a dialog's card names `popup/box`. A skin switched on looks for the piece `<skin>__<material>__<state>`, then `<skin>__box__<state>`. The state is `normal`, `pressed` or `disabled`, as the control's own. A shape the use names (`RbBox.skin_shape`: a bar's `alarm` fill) comes before both. A use may name a shape of another skin as `<skin>/<shape>` (`KitSkin.face`), which is drawn while that skin is on; a shape a use names is drawn even where the use refills the box.

Beside the 35, `KitSkin.SKINS` holds section 5's two overlay skins, `selected` and `spinner` (`KitSkin.OVERLAYS`): no material maps onto them, and they have their own switches. `KitSkin.PARTS` names the pieces no face draws itself: the selected rim (`selected__rim`), the spinner's ring (`spinner__ring`), the lock (`locked__lock`), the attention dot (`badge__dot`), a bar's tick (`bar_track__tick`) and the sheet's two grab handles (`sheet__handle`, `sheet__handle_parchment`); `KitSkin.part`, `mark` and `spinner` hand them out while their skin is on. The selected rim is drawn over a box whose material is `card_selected` or which is the chosen one of a set. A tinted piece (`bar_fill__box`, a school's `disc_school__box`) takes the use's colour, or its material's fill; the skin's untinted `frame` piece, if it has one, is drawn over it at the same rect (AIA-R13).

The `locked` skin has both its mark (`locked__lock`) and, since kit batch 2b, its own face (`locked__locked`, normal and pressed), which the locked material draws.

Three kinds of box stay code-drawn while their skin is on, none of them logged:

- **A material whose words do not hold on its skin's box** (`KitSkin.OWN_SHAPE_ONLY`): a light material, with dark words, whose skin's box is dark, or a dark one whose box is light. Since kit batch 2c (10 November, AIA-R19) these are `pill_gold_edge` and `green_muted`: `album`, `fact`, `plate`, `bar_track_light`, `tag`, `island_label` and `banner_success` have shapes of their own name in the atlas and draw them. Each draws only a shape baked for it (`<skin>__<material>__<state>`), and its code-drawn box until it has one. `client/tests/ui_kit_tests.gd` holds the list to the atlas: it is exactly the materials whose family (`light` or `dark` in `tokens.json`) is not their box's ground, in either atlas.
- **A box its use refills** (`RbBox.tint`: a card in a colour of the screen's own) when its piece is untinted, since the piece would lose the colour the use set its words against.
- **A sprite's material on a host that is not its shape** (`KitSkin.fits`): a sprite (a piece with no 9-slice: the `disc` skin's faces and the gold round) is drawn as wide as its host and keeps its proportions, so it is drawn only on a host about as wide as it is tall, within 15% of its shorter side (`KitSkin.ROUND_SLACK`). A bar, a pill, an oval button or a wide badge in one of those materials (`disc`, `icon_disc`, `level_disc`, `gem`, `round_sky`, `round_violet`, `gold_round`) keeps its code-drawn box. `client/tests/ui_kit_tests.gd` holds it on a storage bar, a product's price button in three states, the Observatory's ribbon, and each material on a wide, a tall and a round host.

A rank's frame (`KitSkin.RINGS`: `frame_oak`, `frame_silver`, `frame_gold`, `frame_prismatic`) is a hollow ring, not a face: its material keeps its code-drawn box, and the ring is drawn over it, 4 points past the portrait's rect on each side (`KitSkin.frame_ring`, `RING_REACH_POINTS`). The popup's box reaches 8 points past its card at the sides and top, and 12 points and its 5-point lip below (`KitSkin.MARGINS`, read with `KitSkin.margins`); every other piece keeps 1 point and its lip.

## 9. Changes to this page

- 28 October: written by T16 for the UI wave.
- 29 October: T17 (plan v3) made K1 the owner, added the freeze at the end of phase 0, and moved component requests into the requesters' own status files with this page's request log.
- 30 October: K1 checked sections 2–6 against `client/ui/tokens.json` and the kit's code and froze them as version 1. It corrected the colour rows to the file's values (ink, backdrop, dark surface, leather, text on dark and on parchment, gold, alarm, success, scrim), counted the materials (106, not 108; `banner_info` mapped to `panel_dark`), put section 6.3's example in `big_action`'s real order, and added sections 6.5 (the functions screens call), 6.6 (the manifest's format), 6.7 (the switch per skin) and 6.8 (the ownership map of the hotspot files).
- 31 October: K1 (P0-K1-contract-2) revised version 1 for AD's redirect at O2 (`gate/approvals/O2.md`, points K1–K3); still version 1, not yet in effect for the revised parts, which take effect at O2-2. Section 2.1: the menus' backdrop takes §21.2's #171046 to #2C3AA8, `card_bottom` §21.8's #1A1134 and red words on dark §21.8's #FF9AAA bold (carried on the alarm fill where they fail the perceptual check); success words on dark, and the shape of the backdrop (the designs' radial), are pending owner decisions with brief entries requested by K1-R4 and O2.md's interim rulings. Section 2.2: Marcellus titles are T2 over the world, gold, oak, leather and school colours, and T0 with their drop on the dark card and parchment. Section 4.1: K01's tertiary is an inked plate of its surface's material, not a ghost. `tokens.json` takes the new values in P0-K1-kitskin.
- 31 October: K1 (P0-K1-kitskin) put section 6.7's switch in code: `client/ui/kit_families.json`, every skin off, and `KitSkin`'s map of section 8.2, with how a piece is named and found, as the note under that table says. `tokens.json` has §21.2's dusk and night skies in a `sky` group, as AIA-R2 asked. It holds `card_bottom` at #120A28, with a note: §21.8's #1A1134 (section 2.1) is written when O2-2 lets the revised contract stand, so no still changes before the gate.
- 31 October: K1 (P0-K1-tokens) wrote section 2.1's `card_bottom`, §21.8's #1A1134, into `tokens.json` (the board's generated `art/ui/board/tokens.css` follows it); every contrast check and the style board's still pass. The other revised values were tried and are not written yet, because each fails a check in a file outside the task: the backdrop's §21.2 values (#171046 to #2C3AA8) leave the board's regular-weight secondary captions at Lc 73–74 on #2C3AA8 (75 needed) and the scrim's secondary words, measured on `night_bottom`, at Lc 73; red words on dark at #FF9AAA leave the screens' alarm notes on glass and on the bare backdrop at Lc 58 (result, Observatory, curation), which the kit must carry on `alarm_fill`; success words on dark at #3FBF7F (the interim) leave them at Lc 48–56 on the card and on glass. K1-R6 asks the lead to split them into a follow-up with those files' owners. The rows above keep their marks until then.
- 31 October: K1 (P0-K1-tokens-2) wrote the rest of section 2.1 into `tokens.json` (the board's generated `art/ui/board/tokens.css` follows it), each value checked against the section it cites: the menus' backdrop, §21.2's #171046 to #2C3AA8, linear top to bottom with `night_mid` #222577 at the midpoint, and words on it measured at #2C3AA8; red words on dark, §21.8's #FF9AAA bold, with the kit's dark `StatusAlarm` carried on `alarm_fill` (paper on #B3203A) wherever #FF9AAA misses Lc 60, and drawing no fill while empty; the scrim's words measured on its own #0A0620. On #2C3AA8, `gold` (#E9B65C) measures Lc 55, so the section kickers and the realm title take `gold_top` (#F9DE9C, Lc 75; K1-R7). Success words on dark stay as the success row says (AIA-R8; C74 pending). Still version 1: the values are the ones this section already named.
- 4 November: K1 (P0-K1-kitspec-3, K1-R9) recorded the owner's C74 and C75 (`docs/decisions/owner-decisions.md`, "UI kit colours (C74, C75)", both closed as A): in section 2.1 the success row's words on dark are #8FF0A8 at every size, and O2.md's interim ruling 1 with AIA-R8's narrowing falls away (#3FBF7F stays fills, rings and marks); the backdrop row loses its "pending owner decision" mark and keeps §21.2's linear #171046 to #2C3AA8. The `from` notes of `success_text_on_night`, `night_top` and `gradient.night` in `tokens.json` name C74 and C75. No value changes: `tokens.json` already held both. Still version 1.
- 4 November: K1 (P1-K1-atlas-draw) added to section 6.6 the atlas's pages (`atlas.pages` and a piece's `page`, both optional, so the format stays 1; AIA-R12), `px_per_point` `null` for the scene families (AIA2-R1) and `bake.js --palette` (AIA-R11); and to section 6.7 the parchment ground's face (AIA-R9). The kit (`KitSkin`, `RbBox`) draws a piece from its page, normal and high contrast. Still version 1.
- 4 November: K1 (P1-K1-words) put section 5's layers and sizes in code. **Words' layer:** a label's, an action's and a field's words stand at `UI.WORDS_Z` (1) above the art, their code-drawn box and a title's rule back at the art's level (`UI.raise_words`, the kit's insides). **Layers over a screen:** a full-rect child added over an earlier sibling of a control that is not a container (a veil, a side menu, a sheet, a wipe) stands `UI.OVERLAY_Z` (16) above that sibling, so the words under it never show through; a later sibling that is not full-rect stands in the layer of the one before it, so the tree's order still decides between them, and the parent's layers are stacked again when a screen reorders its children; a control a screen has given its own z keeps it. **Frames from their words:** a law card, an album card and a portrait take their minimum width from their name's widest word at the player's text size, so 200% text widens the frame rather than shrinking or cutting its words. **Baked numerals:** `KitNumerals.number` and `make` (section 6.5) draw `num_<finish>_<glyph>` in its fixed `advance` (section 6.6), grouped with the language's own marks (`NUMBER_GROUP`, so "1,234" and "1.234" from the same pieces), and keep the spoken value; while the `numerals` switch is off (section 6.7's one switch beside the 35 skins', `KitSkin.BESIDE`; absent from `kit_families.json` it is off), or a glyph's piece is missing (logged), the number is live text in its role. The shipped atlas's four finishes hold all twenty glyphs section 2.2's T3 names. Still version 1: each is a new function beside the frozen ones.
- 9 November: K1 (P1-K1-switch-heist) switched on the skins whose art passed the gate (P1-AIA-kit-1 to -4): `button_primary`, `button_secondary`, `button_tertiary`, `button_danger`, `success`, `panel_dark`, `panel_glass`, `well`, `bar_track`, `bar_fill`, `disc`, `badge`, `tag`, `pill`, `locked`, and the overlays `selected` and `spinner`. `disc_school` stays off: its pieces are not in the kit's atlas yet. **Section 6.7:** a missing state is never replaced by another. **Section 8.2:** `tag_success` moved from `success` to `tag`; the overlay skins, `KitSkin.PARTS`, the shape a use names, the frame over a tinted box, and the three kinds of box that stay code-drawn while their skin is on (AIA-R13, AIA-R14). **A piece's rect:** a piece keeps 1 point around its face for its ink line (`KitSkin.MARGIN_POINTS`) and its lip below it (a 9-slice's bottom margin less its top); `RbBox` draws both outside the host's rect, so a control's size does not change when its skin is switched on.
- 10 November: K1 (P1-K1-switch-heist), section 8.2: kit batch 2b (P1-AIA-kit-5) baked the locked face, so the locked material draws `locked__locked` and `KitSkin.MARKS` (a skin whose art is a mark alone) is gone; two kinds of box stay code-drawn, not three.
- 10 November: K1 (P1-K1-switch-rest) switched on every skin left but `disc_school`, whose pieces are not baked (AIA-R21): `panel_parchment`, `sheet`, `popup`, the four rank frames, `header`, `ribbon`, `tab_bar`, `tab`, `tab_active`, `segmented`, `segmented_on`, `chip`, `chip_on`, `tile`, `toggle` and `slider`. The gate's verdicts on kit batches 2a and 2b are recorded in `docs/art/ui-quality/gate/verdicts/` and are advisory: P1-AIA-kit-4 one pass and three fails, P1-AIA-kit-5 three passes and one fail ("Colour roles and value"). **Section 8.2:** a shape of another skin by name (`KitSkin.face`, `RbBox.skin_shape` as `<skin>/<shape>`), drawn also under a use's own colour; the rank frames as rings over their code-drawn boxes (`KitSkin.RINGS`, `frame_ring`); a piece's own reach past its host (`KitSkin.MARGINS`, `margins`: the popup's box); the sheet's handles among `KitSkin.PARTS`. **Section 6.5, new functions beside the frozen ones:** `KitSkin.cut` and `stylebox` (a piece as a texture or a 9-slice style box, for the theme's slider); `KitBar.aim` (the tick a bar is aimed at, the kit's `bar_track__tick` or a cream line); `KitStatus.attention` (the attention dot, the kit's `badge__dot` or drawn in code); `RbBox.held_only` (only a press held down is the pressed face, for a switch, whose on and off are two shapes). A bar in the alarm's colour draws `bar_fill__alarm`. **Kit batch 2c's shapes (AIA-R19)**, drawn on `claude/ui-artist`'s P1-AIA-kit-6 merged into the task's branch: `panel_dark__album`, `panel_dark__fact`, `panel_dark__plate`, `bar_track__bar_track_light`, `tag__tag`, `tag__island_label` and `success__banner_success` are looked up by their material's name before the skin's box, so `KitSkin.OWN_SHAPE_ONLY` is down to `pill_gold_edge` and `green_muted`. Still version 1.
- 11 November: K1 (P1-K1-disc-host), section 8.2: a sprite is drawn only on a host of its shape (`KitSkin.fits`), the third kind of box that stays code-drawn; before, the `disc` skin's sprites were drawn as wide as any host, over the storage bar (K23), a product's price button (K45), the Observatory's ribbon and the codex's number badges. Section 6.7: a task that switches a skin on renders again every catalogue page the skin changes, in the same task. Still version 1.
- 11 November: K1 (P1-K1-heist-kit), section 6.5, new functions and parameters beside the frozen ones, for the heist's screen (S1-R1 to S1-R6) and the gate's kit notes on P1-S1-pilot-1. **`KitHud.clock_large`** and **`set_clock`**: the heist's timer as a parchment plate at radius 14 with its gold edge, the time at 26 points in the display face with an ink outline that counts (section 2.4) and a 1.5-point drop, red with the alarm's words when late; `set_clock` changes the time, and the plate's colour only when `alarmed` changes. **`KitHud.alarm_fit`** and **`set_alarm`**: `alarm` whose count drops under its word at large text and takes the alarm's words on dark from more than half the bells, and whose spoken name is the meter's; `set_alarm` lights the bells and writes the count. **`KitHud.loot_fit`** and **`set_loot`**: `loot` inside a given width (90 points; 2.3 times as wide at large text), its figures stepping down from two columns to closer to the number under its word, a 10-point load bar, the tick hidden for a negative aim, a caption that wraps, and an optional vault (`[word, number, fraction]`) as a third row or, at large text, a bar beside the vault's icon; `set_loot` moves the bars with `Motion.fill`. **`KitHud.tip`**: a hint on leather at radius 14, its words at 15 points, bold, with an outline that counts, wrapping. **`KitHud.crew`** gains `inked` (default false): a thicker bar (11 points, not 8) and names with an outline that counts. **`KitCards.law_chip_fit`** and **`dark_icon`**: a law chip whose name wraps inside 100 points (scaled with the text), a dark icon set on a light disc. **`UI.world_words`**: words over the world ("Laws here"), bold, in a tone, with an outline that counts. **`Motion.fly`**: a mark flown on an arc into a target over section 2.5's longest time, freed at the end; under reduced motion it is not drawn. Each has a test in `client/tests/ui_kit_tests.gd` (`client/tests/shots/ui_kit_heist.gd`) and a state in the catalogue (K31, K33, K44, K46). No frozen function changes its look. Still version 1.
- 12 November: K1 (P1-K1-numerals-on), section 6.7: the `numerals` switch is on in `kit_families.json` (S1-R11, K1-R11; board 1's objection A), so the heist's timer draws the baked `num_timer` and `num_timer_red` figures on `KitHud.clock_large`, its live words kept for a screen reader only. No other screen and no catalogue page calls `KitNumerals`. Still version 1.
- 16 November: K1 (P2-K1-kit-gaps-1), sections 4 and 6.5, new functions and parameters beside the frozen ones, for the catalogue's gaps (S3-R22, S3-R24, S3-R26, S3-R27). **`KitControls.slider`** (K06): an `HSlider` on the slider skin's track, fill and knob (`RbTheme`'s styles), 48 points tall, named `spoken` for a screen reader and saying its value as it moves: in the caller's words (`said`, optional) or as a share of its range ("60%"); `changed` is called with each value. **`KitPanels.dialog`** gains `kind` (default `"dialog"`) and `primary` (default -1) at the end: a `"confirm"` or an `"info"` sets the title on a ribbon (K19, **`KitPanels.ribbon`**, the `chapter` material on the ribbon skin) and marks one action primary, gold, with every other gold action made leather: a confirm's last action or the one `primary` names, an info's first; an info given no action gets a Dismiss that closes it. A dialog called as before is unchanged. **`KitPanels.info`** and **`popover`** (K30): the (i) as a round 48-point icon button named for a screen reader; a tap opens its words in a small frame on the popup skin's box with a pointer on the (i), below it or, without room, above it, held inside the window, over a layer on the whole window; a tap anywhere, the (i) included, closes it. **`KitPanels.empty`** (K35): an icon, words and one gold action (none when its name is empty) on the dark card; `ScreenParts.empty` stays as it is and its callers are untouched. Each has a test in `client/tests/ui_kit_tests.gd` (`client/tests/shots/ui_kit_gaps.gd`), and the catalogue draws K06, K17 (its confirm and info on a page part of their own), K30 and K35 with them. Still version 1.
- 16 November: K1 (P2-K1-kit-gaps-2), sections 4, 6.5 and 8.1, new functions beside the frozen ones, for the catalogue's gaps (S3-R23, S3-R25). **`KitStatus.spinner`** (K34): the spinner skin's ring (the timer's icon while that skin is off) `points` tall, turned once every `KitSkin.SPIN_SECONDS`; under reduced motion it holds still and, with `words`, "Loading" follows it; said aloud as loading either way. **`KitStatus.loading`** and **`is_loading`** (the Ld state on K01, K02, K11 and K43): the face held, the words and icon hidden and a spinner of the words' size laid over them out of any layout, so the control keeps its size; taps and focus stop and a screen reader says it is loading; `on` false gives the control back as it was. **`KitStatus.locked`** (the L overlay): the locked material on the control's kit box and the lock mark at its top left, out of any layout; a tap opens a popover of `why` instead of acting. **`KitStatus.notice`** (the A overlay): a count badge or the attention dot at the top right inside the hit area, one per control, pulsing once on arrival (reduced motion: no pulse). **`KitNav.reward`** (K40): the one entry point of the reward sequence, the backdrop turned to the night with a still sunburst and, given a prize and a counter, `Motion.reward`'s anticipation, burst, reveal, coin flight and counter roll; under reduced motion the prize fades in, one coin lands and the counter shows its last value at once. `KitNav.celebrate` stays as its alias (the backdrop alone); K1-R23 asks S1 to call `KitNav.reward` from the result screen. The reward's layer is top-level, so its z does not add to a framed screen's: until S1-R21 is answered, the result screen and the catalogue lift it by the prize's whole z. Each has a test in `client/tests/ui_kit_tests.gd` (`client/tests/shots/ui_kit_gaps.gd`: the spinner's reduced form, the Ld state's unchanged size, the reward's reduced form), and the catalogue draws the L, A and Ld states, K34 and K40 through them. Still version 1.
