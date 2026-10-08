# Screens v3: the design system, against v3.6 and the client

What this covers: the colour, type, shape, motion, component and icon system of Screens v3 (the owner's Claude Design artifact), compared item by item with the client's `client/ui/tokens.json`, `client/ui/tokens.gd`, `client/scripts/ui.gd` and `client/scripts/palette.gd`, checked against v3.6 §21 and §20.8, with measured contrast, and a plan to port it to Godot.

Rule applied throughout (v3.6 §23.5): the document wins wherever it states a rule, a number or a piece of text; where it is silent and a design breaks no rule, the design is adopted; a design never adds a mechanic. §23.5's own list of differences is not repeated as a finding here; where this report touches one of its rows (text size, the colour-blind panel's Life gem) it says so.

## 0. Sources and method

Read in full or in the parts cited: `screens_main.js` (677 lines), `screens_main.markup.html` (915), the style blocks and the components cited from `screens_meta.js` (1,292) and `screens_meta.markup.html` (639), `icons_rbi.js` (660), `icons_schools.js` (71), the top of `realm_diorama.js` (lines 1-52: `RBIcons`, `RBSfx`) and the lines of it cited, `art_loader.js` (head). All design files are under `scratchpad/art/named/`. Design document: `docs/design/ruleborn-game-design-v3.6.txt` §20.6 (10241), §20.8 (10286), §21.1-§21.3 (10390-10470), §21.6 (10648), §21.8 (10986), §21.9-§21.11 (11018-11080), §23.5 (11383). Client: the four files above, `client/ui/colour_check.gd`, `client/tests/a11y_tests.gd:60-140`, `client/project.godot`, `tools/roadmap.py` TC.1-TC.8, `tools/audit_register.py` D72 (6730) and its edit (8356).

Run, with scripts in `scratchpad/analysis/ds_scripts/` and output in `scratchpad/analysis/ds_out/`:

- `props.py`: every inline style value in the four screen sources, counted (`ds_out/props.txt`, `props.json`). Counts below such as "336 uses" come from it.
- `probe.mjs` / `probe2.mjs`: the artifact served locally and driven in Chromium (Playwright); for each of the 28 Gameplay screens every visible text run's computed family, size, weight, colour, opacity, text-shadow and text-stroke, a screenshot of the 390 × 844 phone, and a second screenshot with every glyph made transparent so the pixels under each run can be sampled. The first pass caught five screens mid-transition; those and the rest were probed again with a wait for the screen to be fully opaque (`ds_out/probe_b`, `probe_c`, `probe_d`); the figures here are from those second passes.
- `contrast.py`: for each run, WCAG 2's ratio and APCA 0.0.98G's Lc (the same formulas as `client/ui/colour_check.gd`) against the median background pixel and the worst decile (`ds_out/contrast.json`, `contrast.md`). `pairs.py`: the same for the design's recurring token pairs.
- `fonttest.mjs`: whether Lilita One, Manrope and Marcellus have tabular figures, and which weights load.
- `cvd.py`: the six school colours under the three colour-blindness simulations, for the base palette and the design's three colour-blind palettes (Machado 2009, as `colour_check.gd`).
- `icons_export.mjs`: loads the three icon modules with a stand-in `window`, counts every icon by group and writes each as a standalone SVG (`ds_out/icons/`, 444 files).

Not done: Godot is not installed in this environment, so nothing here was imported into Godot 4.7.2; statements about Godot's SVG import and StyleBoxFlat are from the engine's documentation as I know it and are marked as to be confirmed. I did not read the 43 character sheets (`creatures/`) for this part; they carry their own UI chrome, which is outside the screen system.

## 1. Summary

Screens v3 has a coherent, recognisable system, but it lives in inline styles, not in a library: 852 distinct hex colours, 1,191 distinct backgrounds, 402 distinct box-shadows and 55 corner radii across the four screen sources. Underneath that spread there are about ten materials (night backdrop, dark violet card, glass HUD pill, leather, parchment, gold, red, green, active-tab periwinkle, four rarity frames), one outline (2 px `#1A0C14`), one hard drop shadow (`0 4px 0 #0A0408`), three type families (Manrope for everything small, Lilita One for numbers and display, Marcellus for titles), and 86 keyframe animations. That reduces cleanly to a token file of about 150 entries and a dozen components; `ds_out/tokens.proposed.json` is that file.

Against v3.6 the system agrees on the school palette (all six main colours and all six shadow tints match §21.2 exactly) and on Marcellus for titles, and departs from it in six places the document states as rules and §23.5 does not list: the typefaces (Manrope and Lilita One, not Baloo 2), the surfaces (dark violet and leather panels with light text, not ink on 85% paper), interface motion (300-550 ms entrances with overshoot, not 150-250 ms easing out), the icons' finish (gradient volume and gloss, not flat colour), toasts that vanish in 1.6-2.2 s, and the absence of any reduced-motion behaviour; and §21.9 still counts 27 screens where §23.2 now has 28. It also adds two things the document does not have: a colour-blind palette switch (two of its three palettes are worse than the base palette for the form they target) and a single night sky.

On contrast: the design's main pairs are strong (primary text 13.9-16.4:1), but of the 1,049 text runs on its 28 screens, 19% are under 4.5:1 against what is behind them and 28% fail either that or the perceptual level for their size; most of it is white on light badge fills, muted violet secondary text, light browns on parchment and words drawn straight on the 3D world (§8). For D72: the design makes success green better (it puts green words on dark at 7.6:1 and a light green at 11.4:1) and leaves alarm red where D72 found it, or worse on its badges: white on `#E2536B` is 3.69:1, its red count badges measure 2.7-2.8:1 on screen, and red words on night reach 4.8-5.1:1 on a flat night colour (4.19:1 where measured on screen) and fail the perceptual model (Lc 35-37). Its red fills do end on a deeper `#C42040` that carries white at 5.79:1, which is the client's own D72 answer (`#B3203A`) reached independently.

The client is ready for this: tokens, accessors and the accessibility checks exist, and `ui.gd` says Claude Design's components replace its own. What is missing is what StyleBoxFlat cannot draw (gradients, inner rims, several shadows), the fonts themselves, the icons as files, a motion helper, and an accessibility check that knows about gradients and outlined text. §10 is the port.

## 2. Colour

### 2.1 Schools

`screens_main.js:2-8` (`S`) gives each school a main colour `c`, a shadow `d`, a light tint `l` and a clip-path shape.

| School | §21.2 main | §21.2 shadow | `S.c` | `S.d` | `S.l` (new) | `RBIcons` ramp (`realm_diorama.js:7`) | Law-icon ramp (`icons_schools.js:2`) | client `tokens.json` |
|---|---|---|---|---|---|---|---|---|
| Motion | #F2B43C | #B8741E | same | same | #FFDC8A | #FFF3C8 / #F2B43C / #A8641A / #5A3208 | #FFE6A0 / #F2B43C / #A8640E | main and shadow |
| Matter | #8C6CF0 | #5A3FB0 | same | same | #BFAEFF | #E4DBFF / … / #4E34A8 / #231650 | #D8CCFF / … / #4A2FA0 | main only |
| Time | #3CC6D8 | #1F8499 | same | same | #9BEAF3 | #E2FBFF / … / #16748A / #093844 | #C8F6FC / … / #167486 | main only |
| Energy | #F07A3C | #B04A1E | same | same | #FFB488 | #FFE3CC / … / #A8401A / #4E1A08 | #FFD0B0 / … / #A0401A | main only |
| Life | #5CC46A | #2F8A45 | same | same | #A6E8AE | #E6FBE8 / … / #257A3A / #0E3A18 | #CFF5C8 / … / #25763A | main only |
| Spirit | #E05CB4 | #9C3380 | same | same | #F7A6DA | #FFE0F3 / … / #982E78 / #46103A | #FFC8EC / … / #922A74 | main only |

Maps exactly: all twelve §21.2 values. New: the light tints (document silent: adopt), and two further ramps used only inside icons (keep them inside the icon export, not as tokens). Client gap: `tokens.json` carries only Motion's shadow; the other five shadows and all six tints are to be added.

### 2.2 Neutrals and surfaces

Counts are declarations across the four screen sources (`ds_out/props.txt`, hex counts from a grep of the same files).

| Role | Design value | Uses | Document | Verdict |
|---|---|---|---|---|
| Outline on everything | `#1A0C14`, as `2px solid` (336 borders), 1.5 px (77), 2.5 px (17) | 892 | §21.3 "1.5-pixel ink outlines" (3D); §21.8 icons "a 2-point outline"; no colour named | adopt as `ink_line` |
| Deep ink (icon ink, tab label stroke) | `#120C2A` | 345 | silent | adopt |
| Hard drop under dark controls | `#0A0408` | 199 | silent | adopt |
| Text on light surfaces | `#2A1A10` (warm brown-black) | 167 as `color` | §21.2/§21.8 ink `#221C3A` | conflict (DS-1): document's value stays |
| Light surface | parchment `#FFFBF0 → #F1E3C4` (28), `#FFFDF6 → #F6EAD0 → #EAD7AE` (12) | — | §21.8 "paper panels at 85% opacity", paper `#FCFBFF` | conflict (DS-1) |
| Dark surface | card `#261A4C → #1A1134` (26), `#2A1E52 → #1A1238` (12), `#3A2A6A → #22164A` (7) | — | not described | new; conflicts with "paper panels" (DS-1) |
| Backdrop | sub-screens `radial(#2E1F5E, #140C30 55%, #0A0620)` (15); phone `#171046 → #2A1A86 → #3A2AA6 → #2C3AA8` with star dots (`screens_main.markup.html:363`) | — | §21.2 sky follows local time: day `#9FB9F0 → #F6D9C8`, dusk, night `#1A1433 → #3A2B6B` | conflict/gap (DS-9) |
| Text on dark | `#F3EEFF` (primary, 50), `#B8A8D8` (secondary, 32), `#8A7AA8` (tertiary, 23), `#ADA3CF`, `#CDBFE8`, `#C9B8F0` | — | silent | adopt primary and secondary; tertiary fails (§8) |
| Leather | `radial(circle at 50% 28%, #6A3E52, #3A2030 55%, #1E1018)` with rim `#B8741E` | 37 | silent | adopt |
| Cream highlight and plate text | `#FFF3CC` (242), `#F6E6C8` (55), `#FFF6DA` (93) | — | silent | adopt |
| Gold | `#F9DE9C → #E9B65C 46% → #C88A35` (buttons), `#E9B65C` (153), rim `#6B4420` (127), drop `#4A2A10` (149) | — | §21.8 "gold for main actions" | maps |
| Body text default | `#FCFBFF` on `#120d29` (`screens_main.markup.html:308`) | — | §21.2 paper `#FCFBFF` | the same value, used as text, not as panel |

Neutrals §21.2 names for the world (stone `#D8CFC2`, soil `#8A6A4E`, wood `#B07A4F`) do not appear in the screen sources; the dioramas use per-realm colours (`realm_diorama.js:67` and neighbours). They stay as the client has them, for 3D.

### 2.3 Status and state colours

| Role | Design | Where | Document | Verdict |
|---|---|---|---|---|
| Alarm | `#E2536B` (67 uses): badges, alarm bells 4-6, the clock under 30 s, warnings; red fills `#FF8A9A → #C42040` ("Get out", `screens_main.js:472`), badges `#FF8A9A → #E2364E` (`screens_main.js:665`) | many | §21.8 red `#E2536B` for alarms | maps; words need the deep end (§8, D72) |
| Success | `#3FBF7F` (42), green fills `#A8F0B8 → #3FBF7F` (`realm_diorama.js:273`), light green words `#8FF0A8`, `#8CEAB4` | many | §21.8 green `#3FBF7F` | maps |
| Warning (amber) | `#F2A03C`: alarm bells 1-3, "LISTENING" (`screens_main.js:453, 465`) | heist | silent | adopt; it is never the only sign (bells are numbered "0 / 6") |
| Stability bands | Quiet `#7A6E86`, Steady `#5CC46A`, Humming `#3CC6D8`, Brimming `#E9B65C`, Strained `#F07A3C`, Cracking `#E2536B`, Breaking `#9C2A4A` (`screens_main.js:90`) | strain pill, harmony | §5.5 names the bands, no colours | adopt; the band name is always written beside it |
| Resources | Starlight `#F2B43C`, Aether `#3CC6D8`, Essence `#5CC46A` (`screens_main.js:127`) | resource bars | silent | adopt (they reuse school colours; each has its own icon, so never colour alone) |
| Active tab | `#8FA2FF → #6A5AF0 → #4532B8`, gold rim (`screens_main.js:661`) | tab bar | silent | adopt |

### 2.4 Materials

Every panel and control in the design is one of these. Each becomes a `material` token (fill, outline, rim, highlight, hard drop, soft shadow, text colour, and the stop its words sit on for contrast checks): see `tokens.proposed.json` → `material`.

| Material | Fill | Outline | Rim and highlight | Shadow | Words | Source |
|---|---|---|---|---|---|---|
| Night backdrop | radial `#2E1F5E → #140C30 → #0A0620` | — | faint star dots | — | `#F3EEFF` | 15 uses |
| Dark card | linear `#261A4C → #1A1134` | none | inset 1.5 px gold at 35-50% alpha; inset top 2 px white 8% | `0 3px 0 #0A0618` | `#F3EEFF`, `#B8A8D8` | 26 + 9 uses |
| Glass HUD pill | `rgba(20,10,22,.78)` | none | inset 1.5 px gold 45% | `0 3px 8px rgba(0,0,0,.35)` | `#F3EEFF` | `screens_main.markup.html:393` |
| Resource bar | linear `#140A16 → #24142A`, 30 tall, radius 15 | none | inset 1.5 px gold 45%; a 3-4 px fill line in the resource colour along the bottom | soft | `#fff` | `screens_main.js:169` |
| Leather | radial `#6A3E52 → #3A2030 → #1E1018` | 2 px `#1A0C14` | inset 2 px `#B8741E`; inset top 3 px `rgba(255,220,180,.2)` | `0 4-5px 0 #0A0408, 0 8-10px 14-18px rgba(0,0,0,.45-.5)` | `#F6E6C8`, `#FFF3CC` | `screens_main.js:145`, `:459` |
| Parchment | linear `#FFFBF0 → #F1E3C4` | 2 px `#1A0C14` or `#6B4420` | — | `0 3px 0 #4A2A10` | `#2A1A10`, `#6B5040`, `#8A5A1C` | 28 uses |
| Gold (main action) | linear `#F9DE9C → #E9B65C 46% → #C88A35` | 1 px `rgba(255,238,196,.85)` | inset top 1 px white 55%, inset bottom 2 px brown 30% | `0 8px 20px rgba(233,182,92,.3)` | `#1B1430`, 14 px 700 uppercase, tracking .08em | `screens_main.js:136, 165` |
| Gold round | radial `#FFF3CC → #F2C45C → #B8741E` | 2 px `#1A0C14` | inset 2.5 px `#6B4420` | `0 5px 0 #4A2A10`, glow 20 px gold 50% | `#FFF3CC` on plate | `screens_main.js:146` |
| Red | linear `#FF8A9A → #C42040` | 2 px `#1A0C14` | inset 2 px `#B8741E` | `0 4px 0 #0A0408` | `#fff` | `screens_main.js:459, 472` |
| Green | linear `#A8F0B8 → #3FBF7F` | 2 px `#1A0C14` | — | hard drop | `#0A3A20` or white with ink stroke | `realm_diorama.js:273`; Season's CLAIM |
| Active tab | linear `#8FA2FF → #6A5AF0 → #4532B8` | inset 2 px `#120C2A` | inset 4 px `#F2C45C`, 5 px `#8A5A1C`; inset top 7 px white 30% | glow 24 px `rgba(170,150,255,.55)` | `#FFF6DC` with a 4.5 px `#120C2A` stroke | `screens_main.js:661-663` |
| Rarity frames | Oak (wood grain over `#C89058 → #6A3E1E`), Silver, Gold, Prismatic (conic) | — | — | — | per-frame ink | `icons_schools.js:66` |

### 2.5 The colour-blind palettes

The Settings screen offers "Colour-blind mode: Off, Deutan, Protan, Tritan" and swaps the six school colours (`screens_meta.js:903` `CBP`, used at `:943`). The document has no such mode: §20.6 and §20.8 say the palette is "checked by simulation for the three common forms" and that schools are always paired with shapes. Measured (`cvd.py`; smallest CIE76 ΔE between any two schools, as each form sees them; the client's `ColourCheck.DISTINCT_DELTA_E` is 10):

| Palette | Protanopia | Deuteranopia | Tritanopia |
|---|---|---|---|
| Off (§21.2) | 16.1 (Energy/Life) | 12.2 (Time/Spirit) | 11.3 (Time/Life) |
| "Deutan" | 10.4 | **19.5** (its own form: better) | 17.4 |
| "Protan" | **9.1** (its own form: worse than Off, under 10) | 13.6 | 20.1 |
| "Tritan" | 4.9 | 14.2 | **9.0** (its own form: worse than Off, under 10) |

The base palette already passes for all three forms (D72 records the same 11.3). Two of the three alternatives make the schools harder to tell apart for the players they are for (finding DS-4). The same panel also draws school shapes from a third set of clip-paths (`screens_meta.js:902`), where Life is a gem; §23.5 already lists that.

## 3. Typography

### 3.1 Families

| Family | Loaded (`screens_main.markup.html:3-307`) | Where the design uses it | Document |
|---|---|---|---|
| Manrope | 400, 500, 600, 700, 800 (Google Fonts subsets, latin and latin-ext) | every label, body line, button, chip, kicker and most numbers: 924 `font:` shorthands plus `fontSize` styles. Weight 900 is asked for 343 times; no 900 face exists (Manrope's axis ends at 800), so it renders at 800 (measured: identical advance widths) | §21.8 "A rounded, friendly sans (Baloo 2) for labels and numbers"; §21.11 ledger: "Baloo 2 for interface text" |
| Lilita One | 400 | big numbers and counters (season tiers, terrain points, landing clock, rewards, level-up), Keeper name field, friend code, some sub-screen titles ("Held Breath", "Chronicler robe"): about 178 declarations, sizes 10-60, mostly 13-24 | not named |
| Marcellus | 400 | screen titles (26), section headings (16), island labels on the map (12-14, `realm_diorama.js:1233`), names of laws, characters and Sages (22-52): about 79 declarations | §21.8 "Marcellus for titles and law names" (maps) |
| ui-monospace, Georgia | — | the artifact's own index and one italic quote; not game UI | ignore |

Tabular numerals (§21.8 "with tabular numerals"): measured in Chromium with the design's own font files (`fonttest.mjs`), Manrope honours `tnum` (every digit 99.2 px at 40 px), Lilita One and Marcellus do not ("1111" 65 px against "0000" 102 px in Lilita One, with or without `font-variant-numeric: tabular-nums`). The design asks for tabular figures 29 times, including on Lilita One (the landing picker's clock, `screens_main.markup.html:778`), where it has no effect. The heist clock itself is Manrope 900 (800) 22 px tabular (`screens_main.js:453`): correct.

### 3.2 Sizes

From the probe (text runs actually on screen, all 28 screens, at the 390-px frame where 1 px is 1 iOS point): see §8's table for the per-screen counts. From the code (`font:` shorthands), Manrope sizes run 7 to 26 px with the mode at 10-11 px; 77% of Manrope declarations are below 13 px and 95% below 16 px. Marcellus is mostly 16 (headings) and 26 (titles). Lilita One is mostly 13-24.

§21.8: "Body text is at least 16 pixels … Nothing smaller than 13 points." §23.5 already lists this ("Most screens set most text below 13 pt; only the heist, planner and result meet the floor"), so it is not a new finding; the port's type scale (§10.2) raises every role to the floor rather than copying the design's sizes.

### 3.3 Other text treatments

- Letter-spacing on uppercase kickers and buttons: .04-.16em (362 declarations; .08em and .1em most common). Uppercase is used 36 times by `textTransform` plus in many inline strings.
- Text strokes (`-webkit-text-stroke`, painted under the fill with `paint-order: stroke fill`): tab labels 3-4.5 px `#120C2A` (`screens_main.js:663`), CLAIM buttons, Lilita numbers on coloured fills. Godot's label outline (`outline_size`, `font_outline_color`) is the same thing.
- Hard text shadows: `0 2px 0 #0A0408` (25), `0 2px 0 #1A0C14` (19), `0 1px 0 #1A0C14` (7): Godot's `font_shadow_color` with `shadow_offset_y` and no blur.
- `white-space: nowrap` on most labels and on toasts. At §20.8's 200% text this overflows; the design draws everything at 100% (its text-size setting resizes only its own preview line, `screens_meta.js:941`).

## 4. Shape, size and depth

### 4.1 Radii

55 distinct values over 1,193 declarations. Most used: 50% (319, circles and pills), 16 (92), 14 (77), 12 (74), 10 (62), 18 (61), 9 (56), 8 (46), 13 (41). A five-step scale covers them without visible change: 4 (bars, pips), 8 (tags, plates), 12 (pills, inputs), 16 (buttons, toasts, cards), 22 (stages, hero cards), plus "round" (half the height). The client's single `corner_points` 12 becomes this scale.

### 4.2 Lines, rims and shadows

- Outline: 2 px `#1A0C14` is the design's signature (336 borders); 1.5 px for small chips and plates; 2.5-3 px on hero items.
- Inner rims (drawn as inset box-shadows): 2 px `#B8741E` on leather, 2-2.5 px `#6B4420` on gold, 1.5 px gold at 30-50% on dark cards; often stacked (`inset 0 0 0 2px #1A0C14, inset 0 0 0 4px #C98B34`).
- Hard drop: `0 2px 0`, `0 3px 0`, `0 4px 0 #0A0408`, `0 5px 0 #4A2A10`: the "toy" depth. Pressing a control moves it down by the drop (`style-active="transform:translateY(2px)"` ×104, `(3px)` ×65; scale .92-.97 on 33 others).
- Soft shadow and glow: `0 8-10px 14-20px rgba(0,0,0,.4-.5)`; coloured glows `0 0 18-24px <colour>@35-55%` on selected or ready items.
- 402 distinct box-shadow strings in all; the proposed tokens reduce them to `line`, `line_thin`, `line_heavy`, `drop_s/m/l`, a soft shadow and a glow per material.

### 4.3 Sizes and spacing

Gaps: 6 and 8 px dominate (with 10, 5, 4, 12). Side margins 12-16 px. Control heights: main buttons 48 (Assign, Level up), round actions 60 and 72 (`screens_main.js:146`), heist buttons 64 × 58 (`:459`), back and hub buttons 44 (`screens_meta.markup.html:61`, `screens_main.markup.html:386-389`), chips and segmented controls 30 (`screens_meta.js:182-184`), tabs about 54 wide with a 68-px active icon. §21.1's 48-point minimum for primary controls is met by the main buttons and the round actions, not by the back button, hub buttons or chips (the sibling screen reports list these per screen).

### 4.4 School shapes

Three sets exist:

1. `RBIcons.school(s)` (`realm_diorama.js:9-16`): drawn SVG marks, chevron, cube in three-quarter view with its inner edges, hourglass, bolt, leaf, eye. These are what every screen shows (`icon()`, `screens_main.js:95`, draws them).
2. `S[s].clip` (`screens_main.js:3-8`): CSS clip-path polygons. Only `crest()` (`:97`) uses them and its one use is set to `display:none` (`:438`), so they are a dormant fallback. Matter's is `inset(14% round 18%)`, a rounded square, not a cube.
3. The colour-blind panel's clip-paths (`screens_meta.js:902`): Motion a right-pointing chevron, Matter a hexagon, Life a gem (in §23.5 already), Spirit an ellipse.

Port set 1 only: as SVG for icons and marks, and as polygons for masks (§10.5). Sets 2 and 3 are not sources.

## 5. Motion

### 5.1 Inventory

86 distinct keyframe names, 100 definitions, in five style blocks: `screens_main.markup.html:2` (rbNavSpin, rbNavPulse, rbNavBob), `:309-310` (24, from rbDrift to rbConf), `screens_meta.markup.html:2` (35, the rbHm* home-map set, rbBurst, rbFlash, rbSweep, rbPlus, rbTalk*, rbSay*, rbMote, rbBtnGlow, rbFill, rbCardIn, rbRayIn, rbStar, rbHeroIn, rbLogoIn, rbSheen and the three rbNav*), `:7` (9: rbClipRun, rbClipPop, rbWsUp, rbWsStamp, rbWsRise, rbDash, cuShim, rbPop, rbShareBar) and `:8` (29, from rbShopBob to rbWig).

Grouped by what they do, with the durations used (`ds_out/anim_uses.txt`):

| Kind | Keyframes | Durations and easing | Port |
|---|---|---|---|
| Ambient loops | rbBob (−4 or −6 px), rbNavBob (−3 px), rbHmBob (−7), rbShopBob, rbBreathe (scale 1.1), rbGlowP, rbHmGlow, rbBtnGlow (brightness 1.14-1.22), rbNavPulse, rbBlink, rbSpin, rbNavSpin, rbHmSpin, rbDash, rbHmTri, rbHmFlow, rbSlideR/L, rbRoadF, cuShim, rbSheen, rbGlint, rbSweep, rbWig, rbSocket | 0.5-90 s, ease-in-out or linear, infinite | Tween with `set_loops()` or a shader time uniform; all off under reduced motion |
| Entrances | rbPop (.3→1.15→1), rbHmPop/A/B, rbRise, rbWsRise, rbHmIn, rbCardIn, rbFlipIn, rbHeroIn, rbLogoIn, rbSlam (3→.9→1.06→1), rbStar, rbCPop, rbRayIn, rbSayA/B, rbTalkA/B, rbClipPop, rbWsStamp | 0.22-0.9 s; ease-out or overshooting cubic-beziers such as (.3,1.5,.5,1) | Tween, TRANS_BACK/EASE_OUT for overshoot; under reduced motion a 150 ms fade |
| Sheets and screens | rbSheet, rbWsUp (translateY 100%→0), screen fade (`screens_main.js:187`: opacity .18 s, transform .24 s) | .3-.32 s; screen 160-240 ms | Tween; under reduced motion a cut or a 150 ms fade |
| Rewards and particles | rbFly, rbBurst, rbSpark, rbFizz, rbPlus, rbConf (confetti), rbMote, rbHmMote, rbHmSp, rbTw, rbStreak, rbWave, rbPing, rbRingOut, rbFlowL/R, rbZ | 0.7-2.4 s | CPUParticles2D or Tweens; "most particles" off under reduced motion (§20.8), the reward still lands in its counter |
| Feedback | rbShake (±2 px, .16 s loop), rbFlash (white overlay) | — | shake within §21.8's 4 px; flash single |
| Illustrations | rbWalkX, rbWalkPause, rbHop, rbStep, rbGrow, rbDN, rbFadeHold, rbRebuild, rbSlide, rbDrift, rbClipRun, rbHmDrawA/B | 1-5 s loops | these are law previews and tutorial loops: they become the in-engine law signatures (§21.7), not UI motion |
| Fills | rbFill, rbShareBar, bar `width .45-.6s ease-out` | — | Tween on the bar's value |

### 5.2 Against the document

- §21.8: "150 to 250 milliseconds, easing out; buttons squash slightly when pressed; rewards fly into their counter. Screen shake never above 4 pixels. Reduced motion removes swoops and most particles." Screen changes (160-240 ms) and the press (180 ms) are inside the range; sheets (320 ms), toasts (300 ms), tab switches (`flex-grow .32s` and `all .3s cubic-bezier(.3,1.5,.5,1)`, `screens_main.js:660-664`) and entrances (300-550 ms, many overshooting) are outside it (finding DS-5). Rewards do fly to their counter (`screens_main.js:125`, rbFly). Shake is ±2 px: inside. Pressed controls move down by their drop rather than squash; adding a slight scale on press satisfies both.
- §20.8: "no flashing above three flashes a second": nothing in the design flashes faster; rbBlink is 0.4-0.7 Hz, rbFlash is single, and the fastest loops (rbShake 6 Hz, rbStep 4 Hz) move rather than flash.
- Reduced motion: the Settings screen has the switch ("No swoops, fewer particles", `screens_meta.js:944`), but nothing reads it: the setting is stored in `stg` (`:888`) and no animation consults it, and there is no `prefers-reduced-motion` anywhere. So the design does not say what any of its 86 animations becomes under reduced motion (finding DS-8); the table above proposes it, by kind.
- Name collisions: eight keyframe names are defined differently in different style blocks of the same page (rbBob −6 against −4 px; rbConf; rbFlash three ways; rbFly; rbMote; rbRise a 10 px fade-up against a pop from scale .2; rbSweep). In the prototype the last one loaded wins for every screen, so what some screens show is not what their own code meant. The port names them apart and checks each against the screenshots.

## 6. Components

The design has no component library; these are the recurring pieces, with one source each, and the `ui.gd` function each replaces or the new one it needs.

| Component | Anatomy and tokens | States | Source | Client today |
|---|---|---|---|---|
| Gold button (main action) | material gold, radius 16, 48 tall, label 14 px 700 uppercase .08em `#1B1430` | pressed: down 2 px; disabled: 45-50% opacity | `screens_main.js:136, 165`; "Weave into a realm", "Assign" | `UI.button(main=true)`: flat Motion gold, 1 px ink border, radius 12 |
| Leather button | material leather, radius 16-18 or round, label `#F6E6C8` | pressed: down 3 px | `screens_main.js:145, 459`; "Pair it in the Lab" | `UI.button()`: flat paper panel |
| Round action | 60 or 72 round, leather or gold-round, 30-36 px icon, name plate under it (10 px 800, `#2A1622` or `#6B4420`), count badge | disabled 50% | `screens_main.js:146` | none |
| Heist control | 64 × 58, radius 18, leather or gold when open, icon 24 and label | open/closed; red for Get out, cyan for Regroup | `screens_main.js:459, 472` | `heist_hud.gd` buttons |
| Hub / back button | 44 round leather with a label plate (8.5 px) under it | pressed down 2-3 px | `screens_main.markup.html:386-389`; `screens_meta.markup.html:61` | `UI.button("‹")` |
| Chip / filter pill | 30 tall, radius 15, 10.5 px 800, on: cream-gold, off: glass | on/off | `screens_meta.js:182-183` | none (rows of buttons) |
| Segmented control | flex segments, radius 10-17, gold gradient on the chosen one | chosen | `screens_main.js:667`; `screens_meta.js:184` | none |
| Tab bar (5) | bar of dark cells; active cell grows to 1.75×, periwinkle material, icon 45 → 68 px bobbing, label 10 → 13.5 px with a stroke; badges | active, badge | `screens_main.js:660-666`; markup `:434-438` | none (router has no tab bar) |
| Sub-tab strip | gold active tab inside a dark rounded track | active, badge | Settings, Season, Roster headers | none |
| Badge (count) | `min-width 18-20`, radius 9-10, `#E2536B` or radial red/violet/green, 2 px ink, 10 px 800-900 white | — | `screens_main.js:664`; markup `:457` | none |
| Level plate | small gold or ink plate on a portrait (`24`, `LV 5`) | — | markup `:373` | none |
| Resource bar | 30 tall, glass, icon disc, number 13 px 700 tabular, storage line along the bottom, FULL tag at 90% | pulse on collect: scale 1.05, coloured ring | `screens_main.js:169`; markup `:381-383` | `home.gd` labels |
| Strain pill | glass pill, band colour dot, "82% · Humming" | — | markup `:393` | `universe_screen.gd` |
| Keeper badge | 46 portrait with a conic XP ring `#F9DE9C`, level plate, name in Marcellus 18, Renown pill | — | markup `:370-376` | Keeper bar (TC.12) |
| Dark card / panel | material card, radius 14-18, padding 12-14 | selected: gold rim and glow | many | `UI.panel()`: paper at 85% |
| Parchment card | material parchment, radius 14-16 | — | Observatory target, law card body | `UI.panel()` |
| Law chip | 30 tall pill, school icon (school shape SVG) + law name 13 px 700 | — | markup (focus card) `:415` region | `UI.school_mark()` (glyph + name) |
| Law card | rarity frame (oak/silver/gold/prismatic), school-coloured art window, Marcellus name, rank chip, school, mastery | front/back (flip) | Law card screen; `icons_schools.js:66` | none |
| Progress bar | track glass or ink, radius 3-15, fill gradient in the resource or band colour, `width` tween .45-.6 s | — | `screens_main.js:134, 155, 169` | none |
| Alarm meter | six bells 12 tall, radius 3, ink outline; 1-3 amber, 4-6 red; "Alarm 0 / 6" written | partial fill | `screens_main.js:465` | `heist_hud.gd` |
| Timer / clock | heist: 100 × 42 pill, parchment-like radial, Manrope 800 22 tabular; red radial under 30 s; rest timers as small glass tags `5h 12m` | warning state | `screens_main.js:453, 464` | `heist_hud.gd` |
| Crew portrait | round portrait in its school colour ring, two ability pips above (filled/hollow) with the count, health bar under, name in school colour | ready, lockout ring, down | Heist screenshot; `screens_main.js:438-439` | `heist_hud.gd` portraits |
| Toast | gold pill `#FFE9A8 → #E9B65C`, 2 px `#6B4420`, 12-12.5 px 800 `#2A1A10`, nowrap, pops in .3 s, gone after 1.6-2.2 s | — | `screens_meta.markup.html:41, 486`; `screens_meta.js:166` | `UI.banner()` (6 s, stays if chosen) |
| Hint bar | glass pill at the bottom of the heist: "Tap crew, then ground · …" | — | Heist | none |
| Sheet / tray | bottom sheet sliding up (rbSheet .32 s), tabs inside (Build, Terrain, Defence), item cards with cost | open/closed | `screens_main.js:156-161`; Share sheet | none |
| Island label | cream pill `#FFFBEA`, 2 px ink, realm icon, name in Marcellus 12-14, level disc | hub larger | `realm_diorama.js:1233`, `:148` | `universe_screen.gd` |
| Text field | 46 tall, radius 12, parchment fill, 2 px `#B8741E`, Lilita One 17-22 | focus | `screens_meta.markup.html` (friend code, Keeper name) | `UI.field()` |
| Toggle row | icon 26, title 13 px 700, subtitle 10.5 px, switch | on/off | Settings (`screens_meta.js:944-945`) | `settings_screen.gd` buttons |

What the client's `ui.gd` has that the design lacks, and keeps: `frame()` (safe areas), `scroll()`, `row()` that wraps at large text, `narrow()` (corner clearance), `status()` with a glyph so colour is never the only sign, `fit()` for long words, and screen-reader names. The design gives 154 `aria-label`s that map to `accessibility_name`.

## 7. Icons

### 7.1 What exists

Four sources, all drawn in code (§21.11 "made, not licensed" holds):

| Source | API | Count | Grid and construction |
|---|---|---|---|
| `icons_rbi.js` | `window.RBI(group, name)` → data-URL SVG (`:658`) | 360 icons in 31 groups (`RBI.count()`): hud 14, currencies 4, buildings 9, wards 6, realms 7, links 4, stabilitybands 8, lawnotes 8, harmony 6, laws 48, paradoxes 3, lawranksandtiers 8, crewroles 5, characterstates 6, traits 31, sagepowers 13, heistcontrols 8, heiststatus 16, heistoutcomes 6, terrain 39, leagues 6, season 7, constellation 6, social 7, alerts 10, realmactions 12, planningactions 8, generalui 15, screens 14, shopcosmetics 10, settingsandwellbeing 16 | 24-unit grid (glyph vocabulary `G`, `:40`), shapes stroked 1.3 `#2A1A10` (`:4`); the wrapper `W0` (`:25`) draws the whole glyph again underneath at 3.1 px `#1A0C14` (so the visible edge is about 2.2 units: §21.8's "2-point outline" at 24 pt), replaces every flat fill with a three-stop "volume" gradient (`VOL`, `:20`), adds a gloss mask and a specular spot, and a 1-unit drop shadow filter; viewBox −1.2 … 26.4. Framed sets use disc, hex, tile, shield, leather and prism frames (`FR`, `:27-34`) |
| `icons_schools.js` | `window.RBLaw.url(id)`, `.res(id)`, `.frame(rank)` (`:68`); also wraps `RBI('laws', …)` | 27 law icons (with silhouettes), 12 resonance icons, 4 rarity frames | 48-unit grid; parts typed cream, school, ink, outline, thick stroke, highlight; ink `#120C2A` 2.2-2.4; school ramps (`:2`) |
| `realm_diorama.js:3-30` | `window.RBIcons.school/res/bld` | 6 school marks, 4 resources (Starlight, Aether, Essence, Renown), 8 buildings | 24 grid, gradients, 1 px ink |
| Inline | — | 7 in `screens_main.js:138-144` (info, move, up, workers, three resources); 5 tab icons inline in `screens_main.markup.html:434-438`; others as data URLs in the markup | 24 and ~45 grids |

The Icons page's catalogue is 393 cells in 31 sections, "393 of 393 drawn" (`shots/all/Icons_index.txt`), filled from these sources (`screens_main.js:298-333`); that is §23.5's "393 icons". §21.9 budgets "about 220" interface icons. 21 of the 48 law icons come from `icons_rbi.js` and 27 from `icons_schools.js` in a different style (48 grid, rarity framing), so the law set is not uniform yet.

### 7.2 Export (done here)

`icons_export.mjs` wrote all of them as standalone SVG files: 360 under `ds_out/icons/rbi/<group>/<name>.svg`, 27 laws plus 27 silhouettes, 12 resonances, 6 schools, 4 resources, 8 buildings: 444 files. What they use: 441 gradients, 360 `<mask>`, 360 `<filter>` (feDropShadow), 360 `<style>` blocks with class selectors and `!important`, 400 group opacities, 9 dash patterns, and 20 with `<text>` set in "Arial Black,Arial,sans-serif" (z, ?, ★, A, i, NEW, I/II/III, Aa, 7, 3, 1). The inline tab icons and the 7 inline ones are not exported yet (they are literal SVG in the markup and can be cut out the same way).

### 7.3 Into Godot

Godot imports SVG through ThorVG, rasterised at import time at a chosen scale. Whether ThorVG in 4.7.2 honours `<style>` class rules with `!important`, `<mask>` and `<filter>` I could not test here; `<text>` with a system font will not survive on phones in any case (Arial Black is not on Android). Two routes:

1. Rasterise in Chromium (the reference renderer; the repository already drives it through Playwright in `tools/check_prototype_conformance.py:56`) to PNG at 3 px per point at the largest size each icon is used (most at 24-36 pt, so 72-108 px; tab icons 68 pt, so 204 px), commit the PNGs as generated assets with a manifest, and let Godot mipmap them. Exact, deterministic, no engine risk. About 400 files of a few KB each.
2. Bake the SVGs (inline the `.o` class as attributes, convert `<text>` to paths, replace the drop-shadow filter with an offset ink copy) and import them as SVG (or as `DPITexture` if 4.7.2 has it, which re-rasterises with the UI scale). Smaller and sharper at any scale; needs a golden-image comparison against route 1 for every icon.

Recommendation: route 1 now, route 2 later if size or sharpness matters. Either way an icon test: every icon a screen asks for exists in the manifest, and none is drawn with text (localisation: "NEW" is English).

§21.8: "Rounded shapes with a 2-point outline, flat colour and the school shape where relevant; drawn on a 24-point grid." The grid and the outline match; "flat colour" does not: every RBI icon is re-filled with gradient volume, gloss and a specular spot by `VOL`/`W0` (finding DS-3).

## 8. Contrast, measured

### 8.1 What was measured

Every visible text run on the 28 Gameplay screens, in each screen's first state, at 390 × 844: 1,049 runs. Its colour (with its opacity) against the pixels under it in a render with all glyphs made transparent, by WCAG 2's ratio (§21.8's 4.5:1) and APCA's Lc at the level `colour_check.gd` sets for its size and weight (Lc 75 body, 60 for bold or 24 pt and up, 45 for 36 pt and up). Excluded: the phone's status bar, and words of another screen lying under an open one (the heist HUD under the law card). Data: `ds_out/contrast.json`, `contrast.md`; per run, the median and the worst-decile background. Caveats: words over the moving 3D world vary frame to frame; rotated words (the Observatory's "TRACE · 24 H" ribbon) are sampled over their bounding box and read worse than they are; a run's text shadow and stroke are recorded but not counted as background (that is DS-6's question).

### 8.2 Results

1,049 runs: 201 (19%) under 4.5:1 against the median background, 234 (22%) at the worst decile; 250 (24%) under their APCA level; 292 (28%) fail one or the other. By size: 16 px and up, 12 of 102 under 4.5:1; 13-15.9 px, 33 of 187; under 13 px, 156 of 760. 72% of runs are set under 13 px and 90% under 16 px (§23.5's text-size row; not counted again here).

| Screen | Runs | Under 4.5:1 | Under APCA level | Under 13 px | Smallest px |
|---|---|---|---|---|---|
| 01 Universe map | 40 | 8 | 6 | 32 | 8.5 |
| 02 Heist | 22 | 5 | 5 | 1 | 11 |
| 03 Law card | 15 | 1 | 1 | 7 | 9 |
| 04 Realm view | 13 | 2 | 2 | 12 | 9 |
| 05 Weaving | 39 | 4 | 13 | 32 | 8 |
| 06 Heist planner | 20 | 2 | 0 | 1 | 11 |
| 07 Heist result | 28 | 4 | 5 | 0 | 13 |
| 08 Observatory | 42 | 14 | 19 | 13 | 10 |
| 09 Scout report | 54 | 7 | 14 | 47 | 8 |
| 10 Roster | 58 | 5 | 7 | 53 | 9 |
| 11 Character | 31 | 3 | 2 | 25 | 8 |
| 12 Sage hall | 38 | 11 | 12 | 35 | 9 |
| 13 Law collection | 63 | 11 | 11 | 56 | 7.5 |
| 14 Resonance Lab | 56 | 20 | 22 | 52 | 8 |
| 15 Defence curation | 30 | 2 | 5 | 19 | 7.5 |
| 16 Rehearsal and defence log | 26 | 2 | 2 | 22 | 8.5 |
| 17 Season | 44 | 13 | 16 | 24 | 8 |
| 18 Shop | 38 | 8 | 10 | 30 | 8.5 |
| 19 Settings and wellbeing | 42 | 5 | 16 | 35 | 8.5 |
| 20 Profile and stats | 43 | 4 | 13 | 34 | 9 |
| 21 First launch | 7 | 1 | 2 | 2 | 10 |
| 22 Terrain editor | 54 | 13 | 17 | 37 | 7.5 |
| 23 Landing picker | 46 | 12 | 23 | 30 | 7.5 |
| 24 Harmony view | 36 | 7 | 6 | 32 | 7.5 |
| 25 Island Workshop | 47 | 13 | 5 | 34 | 8.5 |
| 26 Forms album | 42 | 8 | 6 | 40 | 8 |
| 27 Share sheet | 24 | 2 | 1 | 21 | 8.5 |
| 28 Friends | 51 | 14 | 9 | 34 | 7.5 |

The heist, planner and result, which §23.5 says meet the size floor, are also the cleanest on contrast: the heist HUD's words read at 7.8-14.5:1 on leather and parchment; its failures are the five crew names drawn in school colours straight over the 3D ground (Pip 3.07, Mo 2.41, Bramble 2.02, Hollow 1.43, Ash 1.78:1), each carrying a hard ink shadow that itself reads at 5.8-10.3:1 against the name.

### 8.3 The causes, by text colour

Five causes account for most failures, and each is a token or component fix rather than a screen-by-screen one:

1. **White on light fills** (115 failing runs, 113 under 4.5:1, median 2.77:1, on 22 screens). 85 of them are one-to-three-character badges and marks: tab and section count badges on the red radial (`#FF8A9A → #E2364E`, 44 runs, about 2.7-2.8:1), "▲"/"!" badges on green and violet (35 and 20 runs, 1.8-2.4:1), note marks "♪" on green tiles (2.1-2.5:1). The rest are labels: the law card's own title, "Stillness" in white Marcellus 25 on its cyan art (1.55:1, `03`), "CHAPTER I/II" at 8.5 px on gold and violet (2.0-2.3:1, `13`), "UPGRADE" in Lilita One 23 on green (1.9:1, with a passing hard shadow, `11`), Season's tier numbers on cream (`17`). Fix: badges use ink words on their fill, or white on the fill's deep end (`#C42040` 5.8:1, `#2F9A3A` 3.6:1 is still short, so green badges take ink); law titles sit on a parchment or dark plate.
2. **Muted violet text on night** (`#8A7AA8` 21 runs at about 4.5:1 and Lc 34 in Settings and Profile; `#B8A8E0`/`#B8A8D8`/`#B9AEDC` 35 runs at 7-9:1 but Lc 57-59). The second passes WCAG and fails APCA for regular-weight body text. Fix: tertiary lifted to secondary, and secondary used bold or at 24 pt and up, or lifted to Lc 75 (`#D8CCF2` reaches Lc 76-78 on the card, its top stop and night).
3. **Light browns and greens on parchment** (`#7A5A34` 3.04:1 on the Landing picker, `#8A6A4A` 4.22, `#8A5A1C` 4.43, `#2F7A45` 3.99, and `#2A1A10` at 72-75% opacity). Fix: no opacity on words; `parchment_text_2`/`_3` and the client's `success_text` as the only light-surface shades.
4. **Red words on night** (`#E2536B`, 4.19:1 and Lc 35 in the Observatory and Scout report). Fix: `#FF9AAA` (9.3:1, Lc 63) as `alarm_text_on_night`, bold.
5. **Dimmed "locked" items** at 50-72% opacity (`#8C7CA0` Sage names 3.18:1, `#E9D8B8` Lab law names 4.07:1). WCAG exempts inactive controls; §21.8 has no such exception. Part of DS-6's decision.

### 8.4 The design's recurring pairs

From `ds_out/pairs.md` (computed from the token values, not from pixels):

| Pair | Ratio | Lc | Reads as |
|---|---|---|---|
| `#F3EEFF` on card `#261A4C` / `#1A1134` / night `#140C30` | 13.9 / 15.8 / 16.4 | 96-98 | body text anywhere |
| `#B8A8D8` on card | 7.2-8.2 | 57-58 | bold or large only |
| `#8A7AA8` on card or night | 4.6-4.8 | 34-35 | fails APCA at every size used |
| `#FFF3CC` on leather | 7.8-13.3 | 86-96 | body text |
| `#2A1A10` on parchment top / bottom | 16.2 / 13.2 | 101 / 88 | body text |
| `#8A5A1C` on parchment bottom | 4.64 | 63 | bold only |
| `#1B1430` on gold top / mid / bottom | 13.4 / 9.5 / 6.0 | 86 / 67 / 47 | bold, and not on the bottom stop |
| white on `#E2536B` / `#E2364E` / `#C42040` | 3.69 / 4.31 / 5.79 | 69 / 74 / 83 | only the deep end carries words |
| white on `#3FBF7F` / `#5CC46A` | 2.34 / 2.20 | 51 / 48 | never |
| `#0A3A20` / `#1A0C14` on `#3FBF7F` | 5.47 / 8.11 | 51 / 58 | bold |
| `#E2536B` on card | 4.84 | 37 | fails APCA |
| `#3FBF7F` / `#8FF0A8` on card | 7.64 / 12.95 | 55 / 84 | the light green for body text |
| school colours as words on card | Matter 4.70, Spirit 5.42, Energy 6.44, others 8.1-9.7 | 35-67 | Matter and Spirit words take their light tints (`#BFAEFF` 9.1:1, `#F7A6DA` 9.7:1) |
| §21.8's own ink on paper, and over the night sky at 85% | 15.7 / 11.5 | 101 / 81 | body text |

### 8.5 D72

See "D72 under the design" in §11: better for success green (the design's dark surfaces and light green carry green words), unchanged or worse for alarm red (white on `#E2536B` 3.69:1 against D72's 3.59:1; its badges' light tops about 2.7-2.8:1; red words on night Lc 35-37), with the design's own deep red `#C42040` (5.79:1) agreeing with the client's `#B3203A`.

## 9. The client, item by item

`client/ui/tokens.json` (T), `client/ui/tokens.gd` (G), `client/scripts/palette.gd` (P), `client/scripts/ui.gd` (U).

| Item | Client | Design | Verdict |
|---|---|---|---|
| School main colours (T `color.motion` … `spirit`) | §21.2 | identical | maps |
| School shadows | Motion only (T `motion_shadow`) | all six (= §21.2) | new: add five |
| School light tints | — | six (`S.l`) | new |
| `ink` #221C3A | §21.2 | text `#2A1A10`, lines `#1A0C14`, deep `#120C2A` | conflict on text ink (DS-1); lines new |
| `paper` #FCFBFF | §21.2 | used as body text on night; light surfaces are parchment | conflict on role (DS-1) |
| `panel` #FCFBFFD9 (U `panel()`) | §21.8 paper at 85% | dark card, glass, leather, parchment | conflict (DS-1) |
| `sky_top`/`sky_bottom` (U `frame()`) | §21.2 day sky | one night backdrop | conflict/gap (DS-9) |
| `stone`, `soil`, `wood`, `water`, `gravel` | §21.2 / client's | not in the screen sources | keep for 3D |
| `alarm` #E2536B, `success` #3FBF7F | §21.8 | same values | maps |
| `alarm_fill` #B3203A, `on_alarm` | D72 | red fills end `#C42040` (5.79:1 for white) | maps in spirit; either value |
| `alarm_text` #9A1B32, `success_text` #155A38 | D72, for words on paper | red words `#FF8A9A`/`#FF9AAA` on night, `#C23A55` on parchment; green `#8FF0A8` on night, `#2F7A45`/`#1F8A55` on parchment (4.14/4.21:1, fail) | keep the client's for light surfaces; add the design's light shades for dark. (Register hygiene: D72's body and its §21.8 edit, `tools/audit_register.py:6730, 8356`, give the success shade as `#1D6B45`, while `tokens.json` uses `#155A38`; on the parchment's darker stop `#F1E3C4` the first is 5.1:1 and Lc 66, the second 6.5:1 and Lc 72, and the client's alarm shade `#9A1B32` 6.4:1 and Lc 71: all three pass 4.5:1 but fall under APCA's Lc 75 for body text there, so on parchment alarm and success words are bold (Lc 60) or a step deeper.) |
| `color_high_contrast` (black on white) | client's | "High contrast: stronger outlines and darker panels" (`screens_meta.js:944`), not drawn | conflict: the client's high-contrast set assumes paper; with dark surfaces it needs redoing (part of DS-1) |
| `px_per_point` 3, 360-pt frame | client's | 390-px frame | decision (§10.1) |
| `control_points` 48 | §21.1 | 48 main, 60/72 round, 44 back/hub, 30 chips | partial (siblings list per screen) |
| `body_points` 16, `smallest_points` 13 | §21.8 | body 11-13, smallest 7.5 | conflict already in §23.5 |
| `title_points` 32 | client's | Marcellus 26 | new value |
| `corner_points` 12 | client's | 4/8/12/16/22 + round | new scale |
| `gap_points` 8, `row_gap_points` 12, `safe_side_points` 16 | client's | 6-10 between items, 12-16 margins | maps |
| `safe_top_points` 44, `corner_clear_points` 56 | §21.1 | tab bar edge to edge | conflict covered by the shell report (S2) |
| `motion.shortest_ms`/`longest_ms` 150/250 | §21.8 | 160-550 | conflict (DS-5) |
| `motion.shake_px_most` 4 | §21.8 | ±2 | maps |
| `motion.banner_ms` 6000 + `banners_stay` | client's, §20.8 | toast 2,200 ms, no "stay" | conflict (DS-7) |
| `motion.rehearsal_pace` 0.75 | §20.8 | "Slower ruins 75%" | maps (§23.5 adopts it) |
| `shape` names | §21.2 | `RBIcons` marks match; clip-paths do not | maps |
| `text_scale` 100-200 by 25 | §20.8 | 100, 125, 150, 200 | client's is finer; keep |
| `haptics` | §21.8 | `RBSfx.buzz(8)` on every tap (`screens_main.js:105`) | maps (tap) |
| G `color()`, `number()`, `list()`, `shape()` | — | — | keep; add `gradient()`, `material()`, `font()`, `type()` accessors |
| P `ROLE` (a school colour per role, the client's) | client's | roles carry an icon each (`crewroles`), no colour of their own | keep the icon, drop the colour pairing if it clashes with school colours on portraits |
| U `button()` | flat StyleBoxFlat, ink border 1 pt, radius 12 | gold / leather / red / green / round materials | replace (§10.3) |
| U `label()`, `title()` | fallback font, ink | Manrope / Marcellus / Lilita, light on dark | replace fonts and colours |
| U `bold_font()` | fallback font emboldened | Manrope 700/800 | replace with FontVariation of the real font |
| U `banner()` | panel + glyph + dismiss | toast | keep behaviour, take the look |
| U `school_mark()` | glyph + name | school SVG mark + name | replace the glyph with the mark, keep the name |
| U `field()` | paper, ink | parchment, `#B8741E` border, Lilita | replace look |

## 10. Port plan

### 10.1 Units and frame

The design is drawn at 390 × 844 px, where 1 px is one iOS point, the iPhone 14/15 frame and §21.1's 9:19.5. The client's base frame is 1080 × 2340 for a 360-point phone (`project.godot:16-21`, `stretch canvas_items`, `aspect expand`), so a client point is never smaller than a real point on any phone at least 360 pt wide. Recommendation: keep the 360-point base and read the design's px as client points, laying screens out with containers and anchors that reflow 390 into 360 (the extra 30 pt are margins and flexible rows). Adopting a 390-point base instead would render the design's 13-pt floor at 12 real points on 360-dp Android phones. Either way the floors in §21.8 are checked in client points (finding DS-10).

### 10.2 Tokens

`ds_out/tokens.proposed.json` is the full proposal. Rules it follows:

- Every token carries `from`: a § where the document gives the value, else `Screens v3 <file>:<line>` with the use count. Where the two disagree, `value` holds the document's and `design` the design's, and the `from` names the finding; flipping after the owner decides is one edit per token.
- New groups: `gradient` (stops by token name), `material` (fill, outline, rim, highlight, drops, glow, text colour and the stop the text sits on), `font`, `type` (roles: kicker 13, caption 13, label 14, body 16, heading 18, title 26, hero 32, number_s/m/l/xl 15/22/28/40, each with the design's own sizes kept as `design`), radii (`radius_xs` … `radius_xl`), lines and drops, icon sizes, motion durations. `tokens.gd` gains `gradient(name) -> Gradient`, `material(name) -> Dictionary`, `font(role) -> Font`, and keeps `color()`, `number()`, `list()`, `shape()` unchanged so nothing that exists breaks.
- `color_high_contrast` is redone for the dark surfaces: opaque card fills, outlines 3 pt, secondary text lifted to primary, no glass.

### 10.3 Theme and boxes

StyleBoxFlat draws one solid fill, a border, corner radii and one shadow; it has no gradient fill, no inner rim and no second shadow, and I could not confirm here whether a zero-blur offset shadow draws on 4.7.2. The design needs all three on almost every control. Proposal:

- One CanvasItem shader, `ui/rb_box.gdshader`: a rounded-rectangle signed distance field with uniforms for the fill gradient (two or three stops, linear or radial centre), outline width and colour, inner rim width and colour, top highlight, and a hard drop (offset, colour) drawn in the same pass; soft shadows and glows as a second, blurred SDF term, with the quad drawn larger than the control by the shadow's reach so nothing is clipped. Used by an `RbBox` Control (or as the material of a Panel) and fed from `Tokens.material(name)`. Cheap on phones (one quad each), and every look is data.
- Godot `Theme` (`ui/theme.tres`, generated from the tokens at start or by a tool) for what Theme does well: fonts and sizes per type variation (`Label`, `Kicker`, `Title`, `Number`), font colours, outline sizes and colours (text strokes), shadow offsets (hard text shadows), separations, and plain StyleBoxFlats for flat cases (badges, plates, chips' off state, tracks).
- Ornate frames (law-card rarity frames, the tab bar's active cell) as 9-patch textures rendered from the design (`StyleBoxTexture`), since they are fixed art.
- Press feedback: on `button_down` tween `position.y` by `press_travel` (2-3 pt) and shrink the drop by the same, plus scale 0.97 (§21.8's squash), 180 ms.
- Contrast checks: `a11y_tests.gd` reads StyleBoxFlat `bg_color` only (`:60-81`). Each component sets `meta("text_bg", colour)` from its material's `text_bg` (the stop its words sit on) and, for outlined text, `meta("outline", [colour, points])`; the tests use them. How outlined text counts is finding DS-6.

### 10.4 Fonts

- Files from Google Fonts' own repositories (each SIL Open Font Licence 1.1): Manrope as the variable TTF (one file, weights through `FontVariation.variation_opentype = {"wght": 500…800}`), Lilita One, Marcellus; Baloo 2 too while DS-2 is open. Godot reads TTF and WOFF2. The artifact's own WOFF2 files are subsets (latin and latin-ext per face) and fine for English and Portuguese, but take the full families from upstream so a future locale is not cut short.
- `ui/fonts/<family>/` with each `OFL.txt`; a licence ledger (`client/ui/fonts/LEDGER.md` or the legal page's data) with source, licence and link per file, as §21.11 asks; the settings' legal page shows the licence texts. No ledger exists in the repository today.
- Numbers: `FontVariation.opentype_features = {"tnum": 1}` on Manrope for every number that changes (clock, counters, timers). Lilita One has no tabular figures (measured); where it shows a changing number, draw each digit in a fixed cell (a small `DigitLabel`), or use Manrope for those.
- Weight 900 maps to 800.
- Fallback chain: Manrope → the engine's default for any missing glyph.

### 10.5 School shapes

Use the `RBIcons.school` marks (exported in `ds_out/icons/schools/`) for every visible school mark. Where a shape is a mask (portrait rings, law-card windows, the colour-blind preview) use a `Polygon2D` or a `clip_children` parent with the polygon from the same SVG outline, not the dormant clip-paths. Matter keeps its cube edges (§23.5's row).

### 10.6 Motion

- One `Motion` autoload: `pop(node)`, `rise(node, delay)`, `sheet_in(node)`, `fly_to(node, target)`, `loop_bob(node, amp, period)`, `loop_glow(node, period)`, `burst(at, kind)`. Every call reads `Settings.reduced_motion`: entrances become a 150 ms fade, sheets and screen changes a cut or 150 ms fade, loops are not started, particles are not emitted except the one that carries information (the reward still lands; its counter still changes). `UI.motion_ms()` stays for the simple cases.
- Durations from the `motion` tokens; interface transitions clamp to `longest_ms` unless DS-5 is decided the other way.
- A lint rule in `tools/check_all.sh`: no `create_tween()` outside `ui/motion.gd` and the law-signature code, so reduced motion cannot be bypassed.
- Flashing guard: `Motion` refuses a loop that changes opacity or brightness faster than 3 Hz (§20.8).

### 10.7 Order of work (for the roadmap)

1. Tokens: `tokens.proposed.json` in, `tokens.gd` accessors, `palette.gd` reading the new names; the existing a11y tests pass unchanged (document values are the `value`s).
2. Fonts and the licence ledger; Theme generation; `UI.label/title/button` on the real fonts.
3. `rb_box.gdshader` + `RbBox`; materials; `UI.button` variants (gold, leather, red, green, round, heist control); press feedback; tests reading `text_bg`.
4. Icons: Chromium rasterisation script, manifest, `UI.icon(group, name, points)`, the icon-exists test.
5. Components in §6, each with a test that it meets §21.1's size and §21.8's contrast at 100% and 200% text.
6. `Motion` autoload, the reduced-motion table, the lint rule.
7. Screens move onto the components (the sibling screen reports' plans).
8. After the owner's answers to DS-1, DS-2, DS-5: flip the affected token `value`s and re-run the checks.

For `tools/roadmap.py`: TC.7 ("The design from Claude Design", owner you, ready) is now delivered as far as the owner's part goes; what remains is Claude's work. Suggested split: TC.7a tokens, fonts and ledger (steps 1-2); TC.7b materials, shader and components (3, 5); TC.7c icon pipeline (4); TC.7d motion and reduced motion (6); with DS-1, DS-2 and DS-5 as the owner's decisions that only change token values, so none of them blocks the work.

## 11. Findings

Only items that are real conflicts with v3.6 not already in §23.5, gaps the build must decide, or v3.6 contradicting itself. IDs are local to this report (DS-n); the register assigns its own. Per-screen layout items (tap sizes, corners, the tab bar) are in the sibling screen reports and not repeated.

**DS-1. The surfaces: dark panels and parchment, not ink on 85% paper** (contradiction, significant; §21.8, §21.2, §20.8). §21.8: "Ink #221C3A on paper panels at 85% opacity over the world". The design's panels are dark violet cards (`#261A4C → #1A1134`, 26 uses, and 28 more in three variants), glass (`rgba(20,10,22,.78)`) and leather (37), with light text (`#F3EEFF`, `#FFF3CC`, `#F6E6C8`); its light surfaces are warm parchment (`#FFFBF0 → #F1E3C4`, 40 uses) with `#2A1A10` text (167), not `#221C3A` on `#FCFBFF`; every outline is `#1A0C14` (892). The client's tokens, `UI.panel()` and its high-contrast set (black on white) are built on §21.8's paper. §23.5 lists neither. Recommendation: the owner amends §21.8 (and the neutrals of §21.2) to the design's two surface families, naming the outline, the two text inks and the high-contrast variant ("opaque cards, 3-pt outlines, secondary text raised to primary"), and keeps §21.8's measurable rules; until then the tokens keep the document's values with the design's beside them (`ds_out/tokens.proposed.json`).

**DS-2. Typefaces: Manrope and Lilita One for Baloo 2; Lilita One has no tabular figures** (contradiction, minor; §21.8, §21.11). §21.8: "A rounded, friendly sans (Baloo 2) for labels and numbers, with tabular numerals; Marcellus for titles and law names"; §21.11's ledger: "Baloo 2 for interface text and Marcellus for titles". The design sets labels, body and most numbers in Manrope (924 shorthands, `screens_main.markup.html:3-307` loads 400-800) and big numbers and some titles in Lilita One (about 178). Measured with the design's own font files: Manrope has tabular figures; Lilita One does not, with or without `tabular-nums` (the design asks for them on Lilita One for the landing picker's clock, `screens_main.markup.html:778`); Manrope has no 900, which the design requests 343 times. All three are SIL OFL. Recommendation: the owner picks; if the design's, §21.8 and §21.11 name Manrope, Lilita One and Marcellus, with "numbers that change are set in Manrope with tabular figures".

**DS-3. Icons are gradient-shaded and glossed, not flat colour** (deviation, minor; §21.8). §21.8: "Rounded shapes with a 2-point outline, flat colour and the school shape where relevant; drawn on a 24-point grid." Grid and outline match; but `icons_rbi.js:20-25` (`VOL`, `W0`) replaces every fill of all 360 icons with a three-stop gradient and adds a gloss mask, a specular spot and a drop shadow; the law, school, resource and building icons are gradient-filled too (`icons_schools.js:56`, `realm_diorama.js:4-29`). Recommendation: amend §21.8's icon row to the design's finish (it is the look the owner chose and §23.5 says the designs carry the icons), or export flat by skipping `VOL` (a one-line change in the export).

**DS-4. A colour-blind palette mode the document does not have, two of whose palettes are worse than the default** (finding, minor; §20.6, §20.8, §21.2). The Settings screen offers Off / Deutan / Protan / Tritan and swaps the six school colours (`screens_meta.js:903`, `:942-943`). Simulated (Machado 2009, the client's `colour_check.gd`), the smallest ΔE between two schools for the form each palette targets: Deutan 19.5 (default 12.2: better), Protan 9.1 (default 16.1: worse, under the client's 10), Tritan 9.0 (default 11.3: worse, under 10). The default already passes all three. Recommendation: do not build the mode as drawn; if the owner wants one, write it into §20.8 and derive its palettes with the client's check.

**DS-5. Interface motion runs 300-550 ms with overshoot** (deviation, minor; §21.8). §21.8: "150 to 250 milliseconds, easing out". Screen changes (160-240 ms, `screens_main.js:102, 187`) and the press (180 ms) comply; tab switches (`flex-grow .32s`, `all .3s cubic-bezier(.3,1.5,.5,1)`, `screens_main.js:660-664`), sheets (rbSheet .32 s, rbWsUp .3 s), toasts (rbPop .3 s, shown 1.6-2.2 s) and entrances (rbPop/rbCardIn/rbSlam/rbFlipIn .45-.65 s, overshooting curves) do not. Recommendation: clamp interface transitions to 250 ms ease-out and keep the longer, bouncier timings for celebrations (results, unlocks, rewards), or amend §21.8 to allow entrances up to about 350 ms with a slight overshoot.

**DS-6. Much of the design's text fails §21.8's contrast, and outlined text has no agreed measure** (gap, significant; §21.8, §20.8). Measured over the 1,049 text runs on the 28 screens (§8): 19% are under 4.5:1 against the median pixel behind them, 24% under the APCA level for their size and weight, 28% fail one or the other; §23.5 lists text size, not contrast. Systematic causes, each a token or component fix: white words and marks on light fills (113 runs, median 2.77:1; 85 of them the tab and section badges, red, green and violet, at 1.8-2.8:1; the law card's own title "Stillness" in white on its cyan art at 1.55:1); tertiary text `#8A7AA8` (about 4.5:1, Lc 34); secondary `#B8A8D8`/`#B8A8E0` (7-9:1 but Lc 57-59, under Lc 75 for body text); light browns and green on parchment (`#7A5A34` 3.04, `#2F7A45` 3.99, `#8A6A4A` 4.22:1); red words on night (`#E2536B`, 4.19:1, Lc 35); the heist's crew names in school colours over the 3D ground (1.4-3.1:1); dimmed locked items at 50-72% opacity. The design relies on 3-4.5-pt ink strokes and hard ink shadows to carry light words on saturated fills; the client's checker (`colour_check.gd`, `a11y_tests.gd:60-140`) measures fill against the panel colour only and knows neither gradients nor outlines. Recommendation: fix the tokens (§10.2: `text_on_night_3` lifted, badges with ink text or deep fills, `alarm_text_on_night` `#FF9AAA`, `success_text` on parchment); and state in §21.8 how outlined text is measured (proposal: an ink outline of at least 1.5 pt, or 12% of the size, counts as the background of the fill), so the tests can apply it.

**DS-7. Toasts vanish after 1.6-2.2 seconds and ignore "banners stay"** (deviation, minor; §20.8). §20.8: "no reading speed requirements on banners, which stay until dismissed if the player chooses". The design's toast (`screens_meta.markup.html:41, 486`) is hidden after 1.6-2.2 seconds (`say()` at 2,200 ms, `screens_meta.js:166`; direct timers of 1,600 and 1,800 ms elsewhere, such as `:259`), carries real information ("Not enough Essence to level Pip", `:259`), and its own Settings switch "Banners stay" (`:945`) is not read. Recommendation: toasts are banners: the client's `banner_ms` (6 s) and `banners_stay` apply.

**DS-8. Reduced motion is a switch with no behaviour** (gap, minor; §20.8, §21.8). The design's Settings has "Reduced motion: no swoops, fewer particles" (`screens_meta.js:944`), but nothing reads it and there is no `prefers-reduced-motion`; none of the 86 keyframe animations has a reduced form. §20.8 says reduced motion "removes swoops and most particles" without saying which particles stay. Recommendation: the per-kind table in §5.1 (entrances fade 150 ms, sheets and screens cut, loops off, particles off except the reward reaching its counter) becomes the client's rule, and §21.8 says which particles remain (those that carry information).

**DS-9. One night backdrop where §21.2's sky follows local time** (gap, minor; §21.2). §21.2 gives day, dusk and night skies and says "The sky follows the player's local time". The design draws only night: the phone's backdrop `#171046 → #2C3AA8` (`screens_main.markup.html:363`) and the sub-screens' `#2E1F5E → #140C30 → #0A0620` (15 uses); per-realm skies inside the dioramas are a separate matter (§21.4). Measured, the design's glass pills keep primary text at 9.8-16.8:1 over all six §21.2 sky stops, so the UI survives a day sky; its tertiary text does not (2.9-3.4:1 over day and dusk). Recommendation: the world's sky follows §21.2; menus keep the design's night backdrop; the owner confirms that reading.

**DS-10. The design's 390-pt frame against the client's 360-pt base** (gap, minor; §21.1, §21.8). The design is drawn at 390 × 844 (`screens_main.markup.html:363`); the client's base is 1080 × 2340 px for a 360-point phone with `canvas_items` stretch (`client/project.godot:16-21`, `tokens.json` `px_per_point`). Making 390 the base would draw §21.8's 13-pt floor at 12 real points on 360-dp Android phones. Recommendation: keep the 360 base, read design px as client points, and lay screens out to reflow the extra 30 points.

**DS-11. §21.9 still counts 27 screens after §23.2 grew to 28** (contradiction within v3.6, minor; §21.9, §23.2, §23.5). §23.5 adds Profile and stats as a §23.2 row, and §23.2 now lists 28 launch screens (Universe map … Profile and stats) plus Co-op heist and Constellation later; §21.9's asset row still reads "Interface icons and screens | About 220 and 27; two more with version 1.1 (23.2)" (line 11045), and §21.9 was not among v3.6's changed sections. Recommendation: §21.9 reads 28 (and, if the owner wants the icon budget to match Screens v3, 393 icons rather than about 220).

**D72 under the design** (update to an open item, minor; §21.8). The design makes the success-green case better and leaves the alarm-red case as D72 found it, worse on its badges: green words on its dark surfaces read at 7.6:1 (`#3FBF7F`) and 11.4:1 (`#8FF0A8`), and dark words on green fills at 5.5-8.1:1; but white on flat `#E2536B` badges is 3.69:1 (D72's paper on red: 3.59:1), white numbers on its radial red badges sit on the light top of the gradient and measure 2.7-2.8:1 on screen (44 runs), red words on night are 4.8-5.1:1 on flat night and 4.19:1 where measured on screen, with Lc 35-37 either way, and green words on its parchment fail (3.99-4.21:1). Its "Get out" fill ends on `#C42040`, which carries white at 5.79:1: the same answer as the client's `#B3203A`. D72's recommendation stands, extended to the design's two surfaces.

## 12. Limits

- Contrast is measured at each screen's first state as the probe found it, not every state; text over the moving 3D world varies frame to frame, so the worst-decile figure matters more than the median there.
- Godot import of SVG and StyleBoxFlat's zero-blur shadow are unverified here (no Godot binary).
- The character sheets' own chrome was not read.
