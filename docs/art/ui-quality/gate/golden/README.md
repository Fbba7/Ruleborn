# The golden set

These are the items the gate's judge is calibrated on (section 3.6 of
`../../report.md`). Each item is one image with the qualities its class is
judged on (`../rubric.md`, "The method at a glance"), the label AD expects, and
whether it is borderline. P0-AD-golden built part 1 from the art that already
existed, and added planted fails to it. P0-AD-golden-2 adds part 2.

| File | What it is |
|---|---|
| `items.json` | The items: id, class, source, crop, qualities, origin, plant, expected label, borderline flag and the reason for that label |
| `images/<id>.png` | Each item's image, built from its source by `golden.py build` |
| [labels.md](labels.md) | The labelling form, one row per item and quality, filled in at O3 |
| `labels-head.md` | The heading of the form; `golden.py labels` writes it at the top of `labels.md` |

## Part 1 at a glance

There are 45 items: 12 screens, 19 kit art and 14 icons. Of these, 27 are
expected to fail and 16 are borderline. The done_when asks for at least 15
and 12.

- **Today's client** (`today-*`): the audit screenshots and the "client today"
  icon row and HUD halves. All are expected to fail. The heist and character
  screens are borderline because parts of them already hold up.
- **The v3 design stills** (`v3-*`): the screens from
  `art/design/stills/screens/`. All are expected to fail: they are flat web
  layouts with no materials, display type or light (report section 5.1).
  Result and character are borderline.
- **The fourteen-quality proofs** (`t14-*`): the After panels of the heist HUD
  and high-contrast proofs, and the HUD halves. These are the bar, and they
  are expected to pass. The two screens are borderline, because a hard judge
  can fault them on quality 9 or 13.
- **The O2 style board** (`board-*`): the plates of `art/ui/board/board.png`
  and `board_hc.png`. They pass, except two:
  - The light plate fails, borderline: it is a demo of the light rather than
    light behind real UI.
  - The icons plate fails, borderline: O2 B3 found a PBR look against §21.3.

  Enamel and wood are borderline: O2 found the enamel card reads as a web card
  at 1x (B4), and the leather button sits 0.6 value steps off its well (B11).
- **The AI UI artist row** (`ai-*`): the painted icons and the Pip portrait
  from `ai-artist-icons.png`. They pass. The chest is borderline.
- **Planted fails** (`plant-*`): a passing item with one quality broken by
  `golden.py`. Each plant names the quality it `breaks`. The item keeps its
  source's qualities, so the judge must find the broken one and pass the
  rest.

| Plant | What it does | Breaks |
|---|---|---|
| `flatten` | Cuts the image to a few flat colours (median cut, k-means kept so the hues stay), removing gradients, gloss, grain and soft drops | 1 on kit art, 3 on icons |
| `low_value` | Squeezes the value range toward the median colour; `keep` 0.35 leaves about one value step of three | 8 |
| `hue_mirror` | Mirrors hue about yellow, so red and green swap and the colour roles break | 8 |
| `unstroked` | Lays labels in thin white body type, with no outline or drop, over the art | 2 |

`plant-hud-top-flat`, with 16 colours, and `plant-heist-dim`, with keep 0.6,
are the borderline plants: they are only half broken.

## Rebuilding and checking

    python3 tools/ui_gate/golden.py build      # every image, from items.json
    python3 tools/ui_gate/golden.py labels     # the empty form (--force to overwrite)
    python3 tools/ui_gate/golden.py check      # items, images and form agree

`sheet.py --self-test`, which `tools/check_all.sh` runs, also runs the plants'
tests and `golden.py check`. The same sources give the same images. An item's
`crop` is in pixels of its source, and a planted item's `source` is the id of
the item it plants into.
