# The interface style board

The look of every interface surface that is not live text or the 3D world:
the materials, the type treatments, the studio light, the outline and glint
rules, four hero icons and each material's high-contrast form. It is step 2 of section 3.3 of
[`report.md`](../../../docs/art/ui-quality/report.md). The owner approves it
at O2 with K1's kit contract; it is not judged by the gate.

| File | What it is |
|---|---|
| [`board.html`](board.html) | The board. One CSS pixel is one point. Add `?hc=1` to the address for the high-contrast mode. |
| [`tokens.css`](tokens.css) | Generated from `client/ui/tokens.json`. Do not edit. |
| [`build_tokens.mjs`](build_tokens.mjs) | Writes `tokens.css`; `--check` fails if it is out of date. |
| [`check_board.mjs`](check_board.mjs) | The board's scripted checks; `--self-test` plants faults and expects each to fail. |
| [`studio.html`](studio.html) | The studio: one light, the four hero icons modelled in three.js, and the 2D finish that holds the outline and glint rules. Every colour is a token name. |
| [`bake_art.mjs`](bake_art.mjs) | Renders `studio.html` into `art/`: each icon at 256 pixels in the normal and the high-contrast form, the finish step by step, and the studio's spheres. |
| [`art/`](art) | The baked pictures the board shows. Rebake after changing `studio.html` or the colour tokens. |
| [`shoot_board.mjs`](shoot_board.mjs) | Photographs the board at phone size into `board.png` and `board_hc.png`. |
| [`board.png`](board.png), [`board_hc.png`](board_hc.png) | The board at 390 points wide, 2 pixels a point, normal and high contrast: what the owner reviews at O2. |

```bash
node art/ui/board/build_tokens.mjs            # after tokens.json changes
node art/ui/board/check_board.mjs             # colours and contrast, both modes
node art/ui/board/check_board.mjs --self-test
(cd tools/ui_research && npm ci)              # three.js, once, for the bake
node art/ui/board/bake_art.mjs                # after studio.html or tokens change
node art/ui/board/shoot_board.mjs             # after the board changes
```

The checks need only Node and the container's Playwright with its
Chromium; the bake also needs three.js 0.184 from `tools/ui_research/`. The board opens straight from disk: its fonts are the client's own,
under `client/ui/fonts/`.

## The idea: treasure toys under one light

Every surface is a crafted object a thief would pocket: fired enamel, struck
gold, oiled oak, saddle leather, smoked glass and old parchment. One warm key
light falls from the top left on all of them. The materials dress §21.8's own
surfaces in §21.2's and §21.8's own colours. They add grain, bevel, gloss and
light, and never a hue: light is the paper white at an alpha, shade is the
drop black at an alpha, and grain is noise that sets how much of one token
colour shows, never which colour.

| Material | Dresses (§21.8) | Fill (tokens) | What it adds |
|---|---|---|---|
| Enamel | the violet card | `card` | a glaze over the top 42%, a hot spot where the key lands, a lit lip and a dark foot, faint speckle |
| Gold | gold for main actions | `gold` | brushed hairlines, the material's 0.32 gloss, a lip split from the face by a lit seam, a glint |
| Wood and leather | leather for buttons; oak frames from §21.2's wood | `frame_oak`, `leather` | grain along the plank; pebbled leather, cream stitching inside the Motion-shadow rim |
| Glass | dark glass at 78% over the world | `glass` | a 6-point blur of the world behind, the gold rim, a catch-light and a raked sheen |
| Parchment | parchment with brown ink | `parchment` | long soil-coloured fibres, edges browned with handling |

Type keeps §21.8 as written (the owner kept it: D4 (b)): Marcellus for
titles and law names, Manrope for labels, body text and every number that
changes, with tabular figures, and Lilita One for large numbers that do not
change, outlined in ink all round. The board shows each role of
`tokens.json`'s `type` at its size.

## The studio light

One studio lights every rendered piece, so a set of sixty icons stays one
family by construction (section 9.2 of `report.md`). `studio.html` holds it
as `STUDIO`:

| Light | Colour | Where |
|---|---|---|
| Key | `cream` | from the top left and in front; the strongest (2.6) |
| Rim | the piece's own light (`gold_top`, `life_light`, `time_light`) | from behind on the right (3.0) |
| Fill | a sky of `paper` over a ground of `night_bottom` | soft, from below (0.6) |
| Room | three.js's `RoomEnvironment` | reflections for metal and gloss; neutral tone mapping |

On flat surfaces the same key becomes a lit top lip, a hot spot and the
gloss on the upper left, and a shaded foot. Drops fall straight down, as the
tokens have them.

## The outline and glint rules

`studio.html` holds them as `RULES`, and every icon's finish runs them in one
order: the render; a soft glow of its own colour and a soft drop; the ink
outline; a painted inner light kept to the shape, and the glints.

- **Outline:** `ink_line` all round, never a colour of its own. Surfaces: 2
  points, 3 in high contrast. Icons: 2 points at the smallest size the icon
  is shown, so a hero icon (48 points and up) is outlined at 1/24 of its box.
  Display words: 2 to 4 points, never under 1.5.
- **Glint:** a `cream` four-pointed star where the key catches, on the upper
  left of the form. One per object; two on a hero icon, the second half the
  first. Never on words or a control's label, and none in high contrast.

## Four hero icons

Starlight (struck gold), Essence (a glassy drop), Tidemark, a law of Time in
its school's hourglass frame (§21.8: a law icon's frame is its school's
shape, §7.2), and the loot bag. Each is modelled from extruded and lathed
forms with deep rounded bevels, its base colours taken from the tokens, lit
in the studio and finished by the rules at 256 pixels. The board shows them
at 76 points on enamel, at 48 on glass over the day sky, and at 48 in grey
for value. §21.8 asks icons for "a three-stop gradient, a gloss and a soft
drop shadow"; these are rendered, which gives the same three things with real
form.

## Each material's high-contrast form

§21.8's high contrast: opaque cards, 3-point outlines, secondary text raised
to primary, no glass. On the board, with `?hc=1` or inside a `.hcf` block:

| Material | High-contrast form |
|---|---|
| Enamel | the opaque `card` of `color_high_contrast`, flat; 3-point ink, then a 1.5-point ring of `text_on_night` outside it, so the edge reads where ink meets night; the hard drop stays |
| Gold | the gold gradient without brushing or gloss; the lip stays as a flat band of `gold_bottom`, because it says "press me" |
| Wood and leather | no grain and no stitching; the oak frame and the leather take the light ring |
| Glass | opaque, no blur and no sheen; 3-point ink and the light ring |
| Parchment | no fibres and no browned edge; secondary ink raised to the primary brown |
| Icons | no glow and no glints; the ink outline 3 points at 48, inside a 1.5-point ring of `text_on_night` |

## What the checks hold

`check_board.mjs` runs in the normal and the high-contrast mode:

1. `tokens.css` matches `tokens.json`, and each colour the board takes from
   the design document instead (§21.2's dusk and night skies, behind the
   glass) is written in the section it cites.
2. `board.html` has no colour literal in its styles, and `color-mix` only
   fades one variable toward transparent.
3. Every colour the page computes, on every element and pseudo-element, is a
   colour of `tokens.json` or of that list, at some alpha.
4. Every word marked `data-check` (all of the board's words): one of the three
   faces, loaded; at least 13 points, and 16 for body text; weight 800 at
   most; no opacity; tabular figures on the number roles; and 4.5:1 and
   APCA's level for its size and weight, the thresholds of
   `client/ui/colour_check.gd`. A word with an ink outline of 1.5 points or
   more is measured against the outline; any other against the pixels under
   its letters (widened by 2 pixels) at their worst.
5. `studio.html` has no colour literal (no `#` hex, no `0x` number, no named
   colour), and every colour name it hands its light, materials and finish is
   a colour of `tokens.json`.
6. Each hero icon in `art/`, in both forms, is 256 × 256 with transparent
   corners; at least 90% of its opaque silhouette's edge is the outline's
   colour (`ink_line`, or `text_on_night` in high contrast), and the ink's
   area over that edge's length, its mean width, is at least three quarters
   of the rule (the measure runs short on the ring's inner side).

Last run: 364 words, all passing in both modes; 8 icons keeping the outline
rule (10.7-pixel rule: 11.9 to 12.8; high contrast's 16: 14.1 to 17.7); the
self-test's thirteen planted faults each fail.

## Found while making it, for O2

Part 2:

- **The hero icons are rendered, not painted flat.** §21.8 asks for "a
  three-stop gradient, a gloss and a soft drop shadow"; the studio gives
  those with real form. If the owner wants the flat finish, the same models
  and rules can be baked flat.
- **High contrast adds a light ring outside the ink.** §21.8 says 3-point
  outlines; ink on the night backdrop is near invisible, so dark surfaces and
  icons ring the ink with `text_on_night` (1.5 points). This is a reading of
  §21.8, not a new rule; O2 can drop it.
- **The loot bag and the law icon are two of many.** Loot is a heist object,
  not a currency; Tidemark stands for every law icon's frame rule. The other
  five schools' frames (chevron, cube, bolt, leaf, eye) follow the same
  model.

Part 1:

- **§21.8's darkest tertiary text misses the perceptual check at 13
  points.** `#B8A8D8`, bold, on the night backdrop reads 7–9:1 but APCA Lc
  57–59, under the Lc 60 that `colour_check.gd` asks of 13-point bold words.
  The board sets its small words in the secondary shade (`#E2D9F7`) instead,
  which §21.8 allows. Screens that use `text_on_night_3` at 13 points meet
  the same limit.
- **Gold carries words only on its upper face.** `text_on_gold` on the gold
  gradient's lower half falls to Lc 55–59. The board makes the lower band a
  lip, split from the face by a lit seam, and centres words on the face; a
  48-point button's lip is 12 points.
- **A word on a light school colour goes on a plate** (§21.8). The school
  band shows its school's shape (§21.2's chevron for Motion) rather than its
  name in ink: the name failed on the band's darker end.
- **The card's foot differs from §21.8.** `tokens.json`'s `card_bottom` is
  `#120A28`, sampled from the designs; §21.8 says the card runs to `#1A1134`.
  The board uses the token.
- **§21.2's dusk and night skies are not tokens.** The board names them from
  §21.2 and its check confirms they are written there.
