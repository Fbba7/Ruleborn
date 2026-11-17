# The icon studio: the bake

The icon families' route is described in `art/ui/icons/README.md`. This page
covers how the studio draws it, and why the bake gives the same bytes on
every machine.

    node art/ui/icons/studio/bake_icons.js [icons_48] [icons_256] [--out DIR]
    python3 -B art/ui/icons/studio/check_icons.py icons_48 icons_256

The bake needs Node and `tools/ui_research`'s three.js (`npm ci` there), and
no browser. Each module is rendered once, at R = 640, by `raster.js`, and
finished for every family and mode by `finish.js` on `picture.js`'s
pictures. `bake_icons.js` then uses `tools/ui_bake/bake.js`'s own `layout`,
`manifestText`, `sourcesHash` and `pack.py`, so it writes what bake.js
writes for an SVG family. `bake.js` bakes a family of kind `"scene"` by
calling this script (`node bake_icons.js <family> --out <dir>`), so
`guard.sh`'s rebake covers the icons.

| File | What it does |
|---|---|
| `toon.js` | the studio `S` a module's `build(S)` gets: three.js, the tokens, the toon material (its GLSL stays as the specification of the shading) |
| `raster.js` | rasterises a three.js scene at R by plain arithmetic |
| `picture.js` | premultiplied pictures of doubles, and the small canvas a module's `draw(S, R)` uses: `drawImage` (translate and uniform scale only), paths of lines, arcs and quadratic curves, `clip`, `save` and `restore`, and `Image` from a PNG file |
| `finish.js` | the board's finish, rule for rule (`art/ui/icons/README.md`), then the area average to the family's size and the PNG |
| `bake_icons.js` | lists the modules, renders and finishes them, packs the atlases and writes the manifests |
| `check_icons.py` | the 2 pt outline and the 32 pt dark shape on the baked atlases |

## Why the bake is plain arithmetic

`guard.sh` rebakes every family and compares it byte for byte with what is
committed, in whichever container runs it. So the bake must give the same
bytes on every machine. The first bake (until P3-AIA2-bake-1) did not: it
drew in Chromium, with WebGL on SwiftShader and the finish on a 2D canvas.
SwiftShader compiles its shaders for the CPU it finds, and Skia's raster
pipeline picks SSE, AVX2 or AVX-512 code by the CPU. Each path rounds
differently, by a level here and there, so the atlas changed with the
machine and the guard failed in some containers.

Now every step is JavaScript arithmetic on numbers, which V8 computes the
same everywhere:

- a double is IEEE 754 in every JIT tier and in the interpreter, with no
  fused multiply-add; `Math.pow`, `sin` and `cos` are V8's own software
  routines, and `sqrt` is exactly rounded;
- no step reads the GPU, a canvas, a font, the clock or the CPU's features;
- the three.js scene only supplies the geometry and the matrices;
  `raster.js` rasterises it: 4 samples a pixel at the standard pattern,
  vertices snapped to 1/256 pixel so that the edge tests are exact
  integers, a depth test per sample, and the toon shading of `toon.js` once
  a pixel, perspective-correct;
- the finish draws on premultiplied pictures of doubles: bilinear
  `drawImage`, the SVG three-box blur, path coverage at 8 by 8 samples a
  pixel, gradients `source-atop`, the exact distance-transform grow, an
  area average to the family's size, and a PNG with no compression left to
  a library's choice before `pack.py`.

The bytes then depend only on the code and on Node's major version (the
containers run Node 22). A new V8 could in principle change a library
routine such as `Math.pow`, so a Node upgrade is checked by a rebake. The
proof runs are in `docs/progress/AIA-2.md` (P3-AIA2-bake-1): two runs, a run
with V8's vector units off and a run with `--jitless` (the interpreter only)
give the same bytes.

`proof_bake/` holds the contact sheets of the atlases before and after this
bake, colour and grayscale, each old piece beside its new one.
