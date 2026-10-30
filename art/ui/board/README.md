# The interface style board

The look of every interface surface that is not live text or the 3D world:
the materials, the type treatments and, in part 2, the outline and glint
rules, the studio light, four hero icons and each material's high-contrast
form. It is step 2 of section 3.3 of
[`report.md`](../../../docs/art/ui-quality/report.md). The owner approves it
at O2 with K1's kit contract; it is not judged by the gate.

| File | What it is |
|---|---|
| [`board.html`](board.html) | The board. One CSS pixel is one point. Add `?hc=1` to the address for the high-contrast mode. |
| [`tokens.css`](tokens.css) | Generated from `client/ui/tokens.json`. Do not edit. |
| [`build_tokens.mjs`](build_tokens.mjs) | Writes `tokens.css`; `--check` fails if it is out of date. |
| [`check_board.mjs`](check_board.mjs) | The board's scripted checks; `--self-test` plants faults and expects each to fail. |

```bash
node art/ui/board/build_tokens.mjs            # after tokens.json changes
node art/ui/board/check_board.mjs             # colours and contrast, both modes
node art/ui/board/check_board.mjs --self-test
```

Both scripts need only Node and the container's Playwright with its
Chromium. The board opens straight from disk: its fonts are the client's own,
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

Last run: 234 words, all passing in both modes; the self-test's nine planted
faults each fail.

## Found while making it, for O2

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
