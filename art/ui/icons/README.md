# art/ui/icons: the icons in the one toon look

Owner: AIA-2. The rules are in rubric.md quality 3 (`docs/art/ui-quality/gate/rubric.md`)
and §21.8's icon row. The plan is in report.md section 3 (`docs/art/ui-quality/report.md`).
The look is the style board's (`art/ui/board/studio.html`), which in turn mirrors the
world's toon light (`client/world/toon_light.gdshaderinc`).

```bash
node art/ui/icons/studio/bake_icons.js           # bake icons_48 and icons_256 into client/ui/art/
python3 art/ui/icons/studio/check_icons.py       # the 2 pt outline and the 32 pt dark shape
node tools/ui_bake/bake.js --check               # the manifests match these sources
SHOT_TIMEOUT=200 bash tools/render/shoot.sh client/tests/shots/icon_portraits.gd /tmp/x.png 640 640
                                                 # re-render the character renders (Godot)
```

Every file under this folder counts in the families' `sources_hash`, this one
included. After any change here, rebake.

## The two routes

- **Objects** (currencies, controls, rewards) are three.js scenes lit by
  `studio/toon.js`. This light is the world's toon light, number for number:
  - a ramp of four steps;
  - shade that falls toward violet;
  - a rim on the lit side;
  - no metalness and no reflections (§21.3, D5 (b)).
- **Characters** are rendered by T7's portrait studio
  (`client/world/portrait_studio.gd`, read only) from their imported models:
  - `client/tests/shots/icon_portraits.gd` writes `renders/<name>.png`;
  - a badge's module draws its toon frame in three.js and lays the render
    over it.

  The Godot step runs only when a model changes. The bake reads the committed
  PNG, so the bake stays Chromium only and byte for byte.

Both routes then go through one finish, `studio/finish.js`, which follows
the board's rules rule for rule:

| Mode | What the finish draws |
|---|---|
| Normal | a glow in the icon's light colour; a soft drop in `drop`; the ink outline in `ink_line`, 2 points at the size shown; a radial inner light; at most two `cream` glints |
| High contrast | a 3-point ink outline; a 1.5-point keyline in `text_on_night` outside it; the inner light; no glow, no drop and no glints |

Each family has the size it is shown at, in `SHOWN_PT`: 48 pt for
`icons_48` (128 px) and 96 pt for `icons_256` (256 px).

## The scene format

An icon is `<group>/<name>.js`, an ES module:

- `group/name` is the icon's name in `client/ui/icons/manifest.json`, or
  `crew/<name>` for a character badge;
- `studio/` and `renders/` are not groups.

The module's default export has these keys:

| Key | Meaning |
|---|---|
| `families` | `['icons_48']`, or `['icons_48', 'icons_256']` for a reward |
| `light` | the colour token of the glow |
| `inner` | `[x, y, radius, token, alpha]`, the inner light, as fractions of the side |
| `glints` | `[[x, y, size], ...]`, at most two |
| `build(S)` | returns a `THREE.Scene`, built only with `S.toon(face, rim)` materials. `S` is `studio/toon.js`: `THREE`, `tok`, `rgba`, `toon`, `starShape`, `puffed`, `renderTo`. The shared parts in `studio/shapes.js` (`box`, `ball`, `rod`, `pip`, `arrowShape`, `boltShape`, `slab`) take `S` first and use only `S.toon` |
| `draw(S, R)` | optional: returns a canvas of side R, in place of rendering `build` (a badge uses it to lay in its render) |

The bake turns each module into the piece `<group>__<name>__normal`. The piece
is px by px, with `slice` null and `tint` false. Its high-contrast twin is in
`<family>_hc.webp` at the same place. Every colour is a token name in
`client/ui/tokens.json`, and `tok()` refuses an unknown name.

## The bake

`studio/bake_icons.js` uses `tools/ui_bake/bake.js`'s own parts: `layout`,
`manifestText`, `sourcesHash` and `pack.py`. So what it writes is what
bake.js writes for an SVG family, and `bake.js --check` accepts it. It loads
`studio/page.html` in the container's Chromium, renders with SwiftShader, and
calls `window.finish(name, family, px, mode)`.

The manifest's `px_per_point` is null, because a scene family has a pixel
size, not points. Request AIA2-R1 asks K1 to take this route into
`bake.js` (kind `"scene"`), so that `guard.sh`'s rebake covers the icons.
