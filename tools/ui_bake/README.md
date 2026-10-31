# tools/ui_bake: the UI kit's bake

Owner: K1. The contract it serves is `docs/art/ui-quality/kit-spec.md`
(sections 5 and 6, frozen at version 1); the plan is section 3 of
`docs/art/ui-quality/report.md`.

```bash
node tools/ui_bake/bake.js kit              # bake one family (or several)
node tools/ui_bake/bake.js --check          # every family, in well under a second
node --test tools/ui_bake/test/bake.test.js # the bake's tests, on a fixture family
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

The fixture in `test/fixture/` shows each form: a button with two states and
twin groups, a tinted disc with a class twin, and a numeral.

## Not yet

- The icon families (`icons_48`, `icons_256`) are three.js scenes
  (`art/ui/icons/<name>.js`); `--check` hashes them, but `bake.js` refuses them
  until their renderer is written, against AIA-2's scene format.
- `art/ui/palette.json` from `client/ui/tokens.json` (kit-spec.md section 6.2).
- `check_screens.py`, `guard.sh` and `budgets.json`: task P0-K1-bake-2.
