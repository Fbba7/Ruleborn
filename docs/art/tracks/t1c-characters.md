# T1c Characters (third session on the characters track)

Takes over T1 and T1b (`t1-characters.md`, `t1b-characters.md`): the export
harness, `CreatureModel`, its material, forms and guard form.

## Done

### The light mesh's own normals (the "crumpled foil")

Every smooth body shaded as crumpled foil: bright and dark patches with
straight edges across the face and chest, on every kind, at every size. The
cause was in the export (`tools/art/harness.js`): the decimated body kept, at
each surviving vertex, the fine sculpt's normal at that point, which carries
the feather scallops and fleece lumps. Across the light mesh's large
triangles those normals interpolate into facets (on Featherkin the vertex
normal and the mesh's own surface disagreed by 35° on average, 64° at the
tenth percentile). The body now takes the light mesh's own area-weighted
normals, welded across chart seams, and the relief map is baked against
them, so the fine detail comes back through the relief where it belongs.
Faceted bodies (Glass Golem, Mossbear's stone) keep their flat faces. All 43
kinds were re-exported; triangles and heights are unchanged.

### Readability at the heist camera

Judged in `creature_heist.gd`, which now uses the heist's own camera (22°
perspective at 50°, turned 45°, 10.5 tiles across) over the Heart's painted
meadow, and in `heist_shot.gd` with `TICKS=200`. Small on screen
(`creature_far`, under 240 px a metre):

- **No ink speckles.** The outline hull sits 5 cm behind the body
  (`depth_push`), so the relief's bumps no longer poke ink through the paint
  as dark speckles; the inside of a shape is clean and the ink is only at the
  silhouette. The ink thickens to 2.1× (was 1.7×).
- **A value step from the ground.** The paint is drawn a step lighter (most
  where it is darkest, `far_value`) with its colour kept (+25% saturation on
  the lifted value), and the darkest light step opens, so a character is one
  clear value against the grass in grayscale.
- **A rim all round.** The rim wraps the whole silhouette (not only the lit
  side), widens, and leans toward warm white, a light line inside the dark
  ink: the double edge that separates a figure from painted grass.
- **Relief fades** to 30%, since its bumps are noise at 40 px.

### The guard form at 40 px

- **The lantern on a crook over the head.** The lantern used to hang from the
  hand, where at the heist's size it sat at the feet like a glow on the
  ground, or hid behind the body. It now hangs from a dark crook staff the
  guard holds on its lantern hand's side, its top over the head
  (`CreatureGear._crook_lantern`), with a larger halo. In the squint test a
  guard is the figure with a light over its shoulder and a staff in its
  silhouette, on every kind.
- The sash is unchanged (wide, red with gold trim); on the Glass Golem it
  reads across the chest from the heist's camera.
- **The Golem's outline is one closed line.** A faceted body pushed its ink
  hull apart along each face's normal, so the Golem was ringed in loose
  flakes; on faceted kinds the push leans toward the body's outward
  direction (`smooth_push`). Small on screen its iridescence and the
  highlight band fade, so it reads as a shape, not sparkle.

### Forms per kind (§21.6)

Each ruleborn's forms now draw a pattern of its own on the body
(`CreatureModel.FORM_PATTERN`, `creature_form_pattern` in the look): spots,
bands, chevrons, rings, scales, a swirl or a zigzag, at the kind's own scale,
read from the kind: Featherkin's feather chevrons, Quarryback's shell bands,
Tidewalker's ripples, Hourkeeper's clock swirl, Emberling's and Stormhound's
zigzags, Glass Golem's and Prism Mite's facets. Hush deepens the midnight
inside the pattern and edges it in starlight; Spark runs flickering embers
along its edges; Echo pulses it in the note's cyan. The 18 patterns are
distinct pairs (tested). The forms now reach the fur shells too (before, a
Hush Rambler in the Character screen wore its day fleece over a midnight
body).

### Colour fidelity

- **The character light.** Characters take the world's sun 20% softer
  (`exposure`; the Heart's noon clipped warm paint's red, so gold read
  salmon) and with its hue taken 60% toward grey (`light_neutral`), so a
  kind's paint reads as its portrait under every realm's light. The world
  keeps its own light.
- **A tone toward the portraits.** Light paint whitens a little by its own
  value (`tone`, 0.3), the shoulder of the design's sheen and tone curve.
- **Per kind** (`CreatureModel.LOOK`, judged beside each portrait):
  Featherkin butter (tone 0.5, less blue), Glass Golem lilac glass (a warm
  lift of its violet), Rambler's fleece gold (barely toned), Mossbear's stone
  grey rather than lilac.
- **Fur shells** took the shader's default sheen lift (0.5) instead of the
  body's, which turned Rambler's fleece pink-white; they now take the body's.

### Hero renders (for T7's stages)

`CreatureModel.set_hero(true)`: softer step edges, an image light (the paint
lit by a cool sky above and a warm bounce below by the normal's facing), a
sheen of the paint's own colour at grazing angles, the relief shading deeper
(the fleece's lumps, the feathers' scallops; the fur shells now take the
relief too), and the kind's fur shells. One switch on the same material, so
the Character screen's model is the world's (§21.3).

### Install size

`export.mjs` writes each scene's import settings: no LODs (a character is
3,000–6,000 triangles at every distance), no shadow mesh, and the
AnimationPlayer's clips optimised and compressed on import
(`IMPORT_ONLY=1 node tools/art/export.mjs` rewrites only these). Imported
scenes fell from 9.4 MB to 6.2 MB for the 43 kinds. Tried and dropped: Basis
Universal for the paint atlas (253 KB against 175 KB for the VRAM-compressed
512² with mipmaps).

## Stills (`docs/art/shots/t1c/`)

- `foil_before_after.png`: Featherkin's portrait, the design beside ours
  before and after the light mesh's own normals and the portrait colour.
- `heist_readability_r2.png`: the heist screen (`heist_shot.gd`, 200 ticks)
  at phone size, before and after this session, with grayscale thumbnails.
- `heist_crew_guards_r2.png`: the eighteen ruleborn at the heist's camera as
  crew (with `readable_scale`) and as guards (true size, lantern on a crook).
- `forms_ruleborn_r2.png`: base, Hush, Spark, Echo and guard rows; each
  kind's form pattern.
- `portraits_hero_h1.png`, `_h2`, `_h3`: the 24 design portraits, each beside
  ours in the hero view (`set_hero(true)`), with grayscale thumbnails.

## For T5 (the heist)

- Guards are drawn at true size while the crew take `readable_scale()`;
  beside a 1.33 m Glass Golem guard a 0.8 m Skyskipper still reads small.
  Call `readable_scale()` for guards too (it only grows kinds under 1.4 m),
  or at least for guards under 1 m (a Prism Mite guard is 15 px tall).
- The crew stand inside the guards' rings in `heist_shot.gd` at 200 ticks;
  overlapping figures merge in grayscale whatever their edges.

## Still worse than the design

(see the last round)

## Next

(see the last round)
