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
| [labels.md](labels.md) | The labelling form, one row per item and quality, filled in by AD at O3 |
| [labels-blind.md](labels-blind.md) | The blind form: the rows of the held-out third only, filled in at O3 by a fresh subagent given only `../rubric.md` and the images |
| `labels-head.md`, `labels-blind-head.md` | The headings of the two forms; `golden.py labels` writes them at the top |

**Version 1.** The items as they stand and the labels O3 gave them are golden
set version 1, the one calibrated against rubric version 1
([../calibration.md](../calibration.md)). Adding, dropping or relabelling an
item makes a new version and re-runs the held-out third.

**Version 2** (17 November 2026, P3-AD-audit-1b) adds the 19 items and 43
labels of blind audit 1 (see "Version 2" below) and drops nothing. The
labels of version 1 did not change. `items.json`'s `version` is 2, and each
new item carries `golden_version` 2. The held-out re-run that version 2
calls for is due with the next prompt revision (02, 08 and 09), and is run
once on that revision.

## The set at a glance

There are 79 items: 51 screens, 17 kit art and 11 icons. Of these, 41 are
expected to fail and 25 are borderline; 66 are natural and 13 planted. Part 1
had 45 items; part 2 added 19 and dropped 4 to stay within 60 (see "Part 2"),
which made version 1; version 2 added the audit's 19.

## Part 1

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
  and `board_hc.png`, re-cropped in part 2 from the board as O2-2 rebaked it.
  They pass, except the light plate, which fails, borderline: it is a demo of
  the light rather than light behind real UI. The icons plate now passes,
  borderline: O2-2 repainted it in the toon look B3 asked for, and a hard
  judge can still find it soft at 1x. Enamel and wood pass and are no longer
  borderline, since O2-2 closed B4 and B11.
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
| `sink` | Pulls one control toward the median colour of a ring around it; `keep` 0.35 leaves about one value step between control and ground | 8 |

`plant-hud-top-flat`, with 16 colours, and `plant-heist-dim`, with keep 0.6,
are the borderline plants: they are only half broken.

## Part 2

- **The key frames** (`kf-<page>`, `-text200`, `-hc`): the five pages of
  `art/ui/keyframes/` (home, heist, result, character, settings), each as
  written, with text at 200% and in high contrast. The frames are 1080 x 2340;
  each item takes the whole frame (`crop` null) and halves it (`size`
  [540, 1170]), so the judge sees the phone at about 1x. Settings has no
  character, so its items leave out quality 9. They are the new bar and mostly
  pass. Where they fail, the reason is the large-text form: at 200%, home
  and character crowd or clip their labels and the heist's HUD buries the
  world, so these are the judgments
  of the large-text form and its choices that AIA left to AD. Each item's
  `why` says what decides it.
- **Four plants in the key frames:** unstroked island names over the home
  world, the result's reward plates and law papers flattened to four colours,
  the Heist tab's loot bag on the home frame flattened (its `source` is
  the frame file itself, since no item holds that crop), and the heist's cast button sunk into its ground.
- **Dropped:** `board-hc-enamel` and `board-hc-gold`, which repeated the
  normal plates; `ai-renown` and `today-icon-renown`, which repeated their
  rows' other icons. That kept the set at 60.

## Version 2: blind audit 1

- **The items** (`audit1-<screen>[-hc|-text200]-<commit>`): the 19 screens
  of blind audit 1 ([../audit/audit-1.md](../audit/audit-1.md)), drawn from
  the gate's verdicts on the pilot heist and the phase 2 screens. Each
  `source` is AD's audit still of the item at its commit, in
  `../audit/audit-1/renders/`, at 540 x 1170 (heist, result and character
  were shot at 1080 x 2340 and halved). Each item's `shot` gives the commit,
  the shot script and the environment it was rendered with.
- **Qualities and labels:** only the qualities the audit labelled, with
  AD's audit labels and critiques. An item is expected to fail when any
  label fails, and is borderline when the audit marked a row borderline.
  Nine of the 19 fail, and seven are borderline. Most rows are on Hierarchy
  (17) and Display type (10), which adds the passing screens the held-out
  run lacked.
- **Two states.** The result items use the offline still, which AD
  labelled (one Loot card, no crew); the gate shot the server state
  (`SERVER=1`). The heist at 200% uses the default three crew; the gate
  shot the named five (`MANIFEST=1`). The labels hold for the stills here.
  [../audit/audit-1-misses.md](../audit/audit-1-misses.md) has the
  misses re-rendered on main and what the judge and AD each saw.
- **Not held out.** The new items are in thirds 1 and 2 only. The held-out
  third keeps its 20 version 1 items and `labels-blind.md` is unchanged,
  so the held-out re-run on the next prompt revision compares with
  `held-opus`.

## The thirds

`golden.py split` deals the items into three thirds, stratified by class,
expected label, borderline flag and origin, and writes `third` into each item.
Third 3 is held out: at O3 a second labeller labels it blind in
`labels-blind.md`. `golden.py check` makes sure the held-out third has about a
third of the version 1 items, holds a fail, a borderline item and a plant,
and holds no item a later version added. Today it holds 20 items: 11
expected fails, 6 borderline and 4 plants. Thirds 1 and 2 hold 30 and 29.
`split` deals version 1 items into all three thirds and later items into
thirds 1 and 2 only. Rerunning it still reshuffles the thirds, so do it
only before the forms are filled in.

## Rebuilding and checking

    python3 tools/ui_gate/golden.py build      # every image, from items.json
    python3 tools/ui_gate/golden.py labels     # both empty forms (--force to overwrite)
    python3 tools/ui_gate/golden.py split      # deal the thirds
    python3 tools/ui_gate/golden.py check      # items, images and form agree

`sheet.py --self-test`, which `tools/check_all.sh` runs, also runs the plants'
tests and `golden.py check`. The same sources give the same images. An item's
`crop` is in pixels of its source, and `size`, when given, is the size the
crop is scaled to. A planted item's `source` is the id of the item it plants
into, or a file path when no item holds the art.
