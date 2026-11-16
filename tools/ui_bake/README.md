# tools/ui_bake: the UI kit's bake

Owner: K1. The contract it serves is `docs/art/ui-quality/kit-spec.md`
(sections 5 and 6, frozen at version 1); the plan is section 3 of
`docs/art/ui-quality/report.md`.

```bash
node tools/ui_bake/bake.js kit              # bake one family (or several)
node tools/ui_bake/bake.js --check          # every family, in well under a second
node --test tools/ui_bake/test/bake.test.js # the bake's tests, on a fixture family
python3 tools/ui_bake/check_screens.py      # screens add no chrome of their own, in a second
bash tools/ui_bake/guard.sh                 # the UI guards before a merge, about 12 minutes
bash tools/ui_bake/guard.sh --self-test     # they refuse a planted extra draw call
bash tools/ui_bake/guard.sh --prereqs       # only what the guards need, in a second or two
bash tools/ui_bake/catalogue.sh             # the catalogue sheet, eight variants (or: en n 100)
```

`bake.js <family>` reads the family's sources in `art/ui/<dir>/` (the folders
are in `families.json`), draws every face twice in headless Chromium, normal
and high contrast, packs both sets into one layout and writes
`client/ui/art/<family>.webp`, `<family>_hc.webp` and `<family>.json`
(kit-spec.md section 6.6). `pack.py` composes and encodes the lossless WebP
files. The manifest has sorted keys and a final newline, and a rebake of the
same sources is byte for byte (a test checks it). A refused bake writes
nothing.

`--check` draws nothing. For every family it recomputes `sources_hash` and
compares it with the manifest's, and checks that the manifest is exactly as
the bake writes it, that both atlases exist at the manifest's size (powers of
two, 2048 at most) and that every piece lies inside them. A family with
sources but no manifest fails; a family with neither passes ("no sources
yet"). It prints the total bytes of the interface atlases (report.md section
10.1's install size).

The hash covers the family's sources as kit-spec.md section 6.6 says, then the
bake's own inputs the same way: `bake.js`, `pack.py`, the families file and
the fonts it lists. Changing any of them makes every manifest stale until the
families are rebaked.

Needs: Node 22, the container's Playwright 1.63.0 and its Chromium, Python 3
with Pillow. `--check` needs only Node.

## The source format (SVG families: `kit`, `motion`)

One file a skin's shape: `art/ui/<dir>/<skin>/<shape>.svg`, lower-case words
with underscores. Sizes are in points; the family's `px_per_point` (6 for the
kit: the size a piece shows at 200% text, kit-spec.md section 5) turns them
into pixels, and every size and margin must come out a whole number of pixels.

| On the root `<svg>` | Meaning |
|---|---|
| `width`, `height` | The face's size in points. Without a `viewBox`, the drawing's units are points |
| `data-slice="l t r b"` | 9-slice margins in points; absent for a sprite |
| `data-tint="true"` | A neutral school piece the kit tints by vertex colour (kit-spec.md section 5) |
| `data-hc="class"` | The high-contrast twin is the same drawing with class `hc` on the root (style it with `.hc ...` rules) |
| `data-advance` | A numeral's fixed advance in points; numerals only |

Faces are the root's direct children with `data-state`: `normal`, `pressed`,
`disabled` or `locked` (kit-spec.md section 5; selected and attention are
overlays, sources of their own). A state's twin is a second group with the
same `data-state` and `data-mode="hc"`, unless the root says `data-hc="class"`.
A group may carry its own `data-slice`. A file with no state groups is one
face, `normal`, and needs `data-hc="class"`. Keep `<defs>` outside the state
groups. The fonts in `families.json` are loaded by name (`'Lilita One'`,
`'Manrope'`, `'Marcellus'`).

Pieces are named as kit-spec.md section 6.1 says: `<skin>/<shape>.svg` gives
`<skin>__<shape>__<state>`, and a numeral, `num_<finish>/<glyph>.svg`, gives
`num_<finish>_<glyph>`, with one face and a `data-advance`.

The bake refuses: a face without its twin; a state outside the four; a size,
margin or advance that is not whole pixels; margins wider than the piece; a
name that is not lower-case words; two sources making one piece; and pieces
that do not fit a 2048 × 2048 atlas.

A family's entry in `families.json` may name a `curves` file in its source
folder (the motion family: `"curves": "curves.json"`, `art/ui/motion/curves.json`,
report.md step 8). The bake copies that file's JSON into the manifest's
top-level `curves`, so `client/ui/motion.gd` reads the timings beside the
sprites, and `--check` fails when the manifest's curves are not the file as it
stands. After an edit to `curves.json`, run `node tools/ui_bake/bake.js motion`.

The fixture in `test/fixture/` shows each form: a button with two states and
twin groups, a tinted disc with a class twin, and a numeral.

## The guards (`check_screens.py`, `guard.sh`, `budgets.json`)

`check_screens.py` counts, per file in `client/scripts/` and `client/world/`,
the chrome drawn outside the kit (kit-spec.md sections 6.3 and 7): `draw_*`
calls that put something on the canvas, `canvas_item_add_*` and `FxPen`
calls; `StyleBoxFlat`s that draw a fill (not those whose `draw_center` is set
false in the same function); and textures made for chrome (`TextureRect`,
`NinePatchRect`, `StyleBoxTexture`, `GradientTexture2D`, image files loaded by
path). Comments and strings are not counted. No file's count may rise above
`budgets.json`'s `screens.counts`; when screens move onto the kit and a count
falls, `--record` lowers it (it never raises one). The two files in
`screens.data_files` draw data, not chrome (kit-spec.md section 4.5), and are
reported but not limited. The counts recorded on 31 October 2026, at main's
7bd1c60: 232 draw calls, 31 fills and 27 textures in 49 files, and 49 draw
calls of data drawing. (Section 7's 383 counts the whole client, `client/ui/`
included; the kit's own drawing is not limited here.)

`guard.sh` checks its prerequisites first, in every mode (lessons M19 and
M32: a fresh worktree without them stalled a candidate's guard for 30
minutes). It looks for the native library `client/bin/libruleborn_godot.so`
and the Godot binary pinned in `client/build.sh` (`$RULEBORN_GODOT`, else
`~/.cache/ruleborn/`), both made by `bash client/build.sh`; three.js in
`tools/ui_research/node_modules` (`(cd tools/ui_research && npm ci)`, or in a
worktree a link to the main checkout's); Node with the Playwright module and
its Chromium; Python 3 with Pillow and WebP; and `xvfb-run`, `timeout` and
`cmp`. For each one missing it prints a `missing:` line and an `install:`
line with the command that installs it, and exits 1 within a second or two,
before any guard runs. `--prereqs` runs this check alone; `--self-test` shows
it passes a scratch worktree with the library and `node_modules` linked in
and refuses one without each.

Then `guard.sh` runs, in order: the full rebake byte for byte (each family with a
manifest in `client/ui/art/` is baked into a scratch folder and compared file
by file; with none baked yet, the fixture is baked twice and compared);
`bake.js --check`; `check_screens.py`; and `budget_shots.py`, the five key
screens (home, heist, result, character, settings; their shot scripts and
settings are in `budgets.json`'s `shots.screens`) at 100% and 200% text and in
high contrast. Each shot is the screen's own shot script, extended in a
scratch folder by a wrapper that snapshots every frame with `measure.gd`, so
the measure is of the frame the shot saves. A shot passes when:

- its draw calls (`RENDERING_INFO_TOTAL_DRAW_CALLS_IN_FRAME`, the world's
  included) are under 150 and no higher than recorded (§21.3; report.md
  section 10.1);
- its interface textures, the textures its canvas items hold counted at
  4 bytes a pixel (report.md section 10.1's way of counting an atlas), are at
  most 24 MiB. The fonts' glyph caches are reported beside it, not counted
  in it (request K1-R3 to the lead);
- no more of its words are below 4.5:1 than recorded. A word (a label's or
  an enabled button's, on screen and not scrolled out of its list) is
  measured against its ink outline where §21.8 lets that count, else against
  the pixels of its box in the rendered frame: their contrasts with the
  words' colour, at the median, since the glyphs cover well under half of a
  box and sort lowest. This reads what is drawn, so it covers what
  a11y_tests.gd's colour model cannot (baked art, the world behind glass);
  any words below the floor are listed in the shot's log.

The run takes about 12 minutes and writes its logs and stills to
`$UI_GUARD_LOGS`. `budget_shots.py --only home/100,heist/hc` runs some shots;
`--record` lowers the recorded figures (it writes them only when none is
recorded yet). A recorded figure rises only by request to K1 with the lead's
approval, logged in `budgets.json`'s `raises`. `guard.sh --self-test` also plants
a `draw_rect` in a copy of a screen's source, an extra draw call (a square
with a material of its own) on the result screen's shot, and grey words on a
grey square there, and passes only if each is refused for that reason.

The guard does not go into `check_all.sh`: by D9 (b) the lead runs it in the
pre-check of every change that touches the client or the art, and on every
candidate. `check_screens.py` and its `--self-test` do (K1-R1).

## Pages, scenes and the palette

- A family whose pieces outgrow one 2048x2048 atlas is baked into pages,
  shelf by shelf, tallest first: `<family>.webp` and `<family>_hc.webp` are
  page 1, `<family>_2.webp` and `<family>_2_hc.webp` page 2, and so on. The
  manifest lists them in `atlas.pages` and gives each piece past page 1 its
  `page` (kit-spec.md section 6.6). A rebake that needs fewer pages removes
  the extra ones; `--check` fails on a page the manifest does not list.
- A family of kind `scene` (`icons_48`, `icons_256`) is baked by AIA-2's
  `bake_icons.js`, which `bake.js` runs as its own process; its manifest's
  `px_per_point` is `null`. `guard.sh`'s rebake covers it byte for byte.
- `node tools/ui_bake/bake.js --palette` writes `art/ui/palette.json` from
  `client/ui/tokens.json` (`--tokens FILE` for another), keeping the file's
  `kit` section. `--check` compares it with the tokens.

The Godot kit tests' fixture, `client/tests/fixtures/ui_kit/` (a
`.gdignore` keeps Godot from importing it), is baked from its own sources:

```sh
d=client/tests/fixtures/ui_kit
node tools/ui_bake/bake.js kit --config $d/families.json --art $d/art --out $d
```

The bake's tests fail when it is stale.

## The catalogue sheet (`catalogue.sh`)

`client/tests/shots/ui_kit_catalogue.gd` lays every component of
kit-spec.md section 4 out in every state on pages of the phone's size, with
every skin that has art switched on, and `catalogue.sh` renders it in eight
variants: English and Brazilian Portuguese, normal and high contrast, 100%
and 200% text, as `docs/art/shots/ui-bake/catalogue-<locale>-<n|hc>-<text>-NN.png`.
Each cell's caption names its face and state; a disabled cell says why, a
locked one what unlocks it. A page over 400 KB is quantized to a palette, and
one that stays over fails the script. `ui_kit_tests.gd` holds the sheet to
section 4: every (component, state) pair has a place, no part is taller than
a page, and each baked state of a skin with art is a piece inside both
atlases, none drawn from the code-drawn box.
