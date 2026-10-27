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

## Fourth session (wave 4)

### The ink at the game's resolution

The heist draws its 3D at project.godot's 1080 × 2340 and the phone shows it
at half that, so every width in pixels came out half as thick as in the
creature shots (540 wide): in `heist_shot.gd` the crew had almost no ink and
read as washed shapes on the grass. The outline's width and the "small on
screen" measure (`creature_far`) now count in a 540 × 1170 phone's pixels,
whatever the drawing's resolution (`dpi` in `creature_outline.gdshader` and
`creature_look.gdshaderinc`). This was the largest single readability step.

### Readability at the heist camera

- **One clear shape.** Small on screen the darkest light step rises to
  `far_floor` (0.45), so a character is one value of its own colour, not a
  lit and a shaded half; the paint is read `far_blur` (1.5) mip levels
  softer, so scales, fleece and cracks do not speckle at 40 px; the relief
  goes entirely. The value step from the ground is larger (`far_value` 0.18,
  saturation ×1.4 on it) and the ink a little thicker (`far_width` 2.4).
- **A night switch** (`CreatureModel.set_night`): the stronger, warmer rim
  and paler sheen T5 sets by hand today, keeping each kind's own sheen and a
  guard's red rim (see For T5).

### The guard form at 40 px

- **Crimson ink.** A guard's outline is a dark crimson (`GUARD_INK`,
  #4A0A14) instead of §21.3's #1A0C14: as dark a line in grayscale, but the
  whole silhouette says "guard" on every kind, from any side, even where
  the sash is hidden. Small on screen its rim stays red too.
- **The sash** is never narrower than 8% of the height (on small kinds a
  chest-wide band was a pixel), brighter (#D63A40), and edged in ink outside
  its gold trim. On the Glass Golem it reads across the chest from the
  front, the side and behind.
- **The crook** is thicker and darker, so the staff shows in the silhouette.

### Colour fidelity

`CreatureModel.LOOK` is now a map of the body material's uniforms by name,
per kind (tested: every key is a kind and a real uniform). New uniforms:
`paint_contrast` and `paint_mid` (the paint's values drawn together),
`flatten` (a flatter light), `pastel` and `pastel_colour` (saturated paint
toward a pale colour by its saturation), `hot_core` (a glowing part's face
toward warm white), and `veil_see` in the glass shader (a glowing veil is
thinner face-on, so the core inside shows).

- **Glass Golem**: its baked facets ran from near black to lilac, under a
  warm sheen that turned them pink. Values drawn together, a flatter light,
  its own lilac sheen (#E0D0FF, the design's): median #8B6ED6 against the
  portrait's #8C6CCE (was a blue #7960BE and a pink #B892C8, half and half).
- **Bloomling**: the petals were crimson (#FF5369); pastel toward lilac-white
  gives #FF839E against the portrait's #EE86A2; the body a little greener.
- **Emberling**: the flame crown is three nested tongues, the outer one a
  translucent veil over a cream core; ours drew the veil nearly opaque, so
  the crown was all orange. Now the core shows through face-on. The belly
  no longer glares white (tone 0.1, glow 0.8, a duller clearcoat).

### Install size

Already in place: no LODs, no shadow meshes, the clips optimised and
compressed on import. Static channels: the harness already writes a still
channel as two keys (216 of 456 on Rambler), and Godot's importer drops
immutable tracks, so collapsing them further changes nothing installed.
What was large in each `.glb` was its JSON: every channel had its own time
and value accessors, mostly copies. `slim` now shares identical accessors
(about half of them), and `SLIM_ONLY=1 node tools/art/export.mjs` re-slims
the exported files without exporting again: 24.6 MB to 21.7 MB for the 43
`.glb`s, with the same clips (a checksum of the imported tracks matches).
Installed, nothing changes by this. What did: the relief map is held to
128² (was 256²; side by side in the hero view, Rambler's fleece and
Featherkin's feathers look the same) and the Glass Golem's flat one to 16²,
so the textures fell from 10.8 MB to 8.0 MB and the 43 kinds install in
about 14.1 MB (was 16.8 MB). Measured per kind (imported, s3tc):

| Kind | Triangles | .glb KB | Scene KB | Textures KB | Installed KB |
|---|---:|---:|---:|---:|---:|
| archivist | 5880 | 541 | 179 | 192 | 371 |
| ashmoth | 5440 | 409 | 113 | 192 | 305 |
| bloomling | 4551 | 394 | 134 | 192 | 326 |
| cartographer | 5879 | 540 | 142 | 192 | 334 |
| chronicler | 5427 | 521 | 155 | 192 | 347 |
| collector | 5880 | 606 | 149 | 192 | 341 |
| devourer | 5879 | 545 | 149 | 192 | 341 |
| echoplate | 5395 | 422 | 144 | 192 | 336 |
| emberling | 5879 | 477 | 150 | 192 | 342 |
| featherkin | 5880 | 621 | 169 | 192 | 361 |
| gardener | 5852 | 668 | 150 | 192 | 342 |
| glassgolem | 4104 | 695 | 173 | 171 | 344 |
| hourglassstorm | 5659 | 369 | 133 | 192 | 325 |
| hourkeeper | 5876 | 411 | 137 | 192 | 329 |
| illusoryguard | 5872 | 636 | 176 | 192 | 368 |
| lamplighter | 5876 | 574 | 144 | 192 | 336 |
| lanternfish | 4056 | 270 | 83 | 192 | 275 |
| lanternmoth | 5440 | 399 | 111 | 192 | 303 |
| lanternwisp | 5430 | 403 | 139 | 192 | 331 |
| mossbear | 5854 | 926 | 203 | 192 | 395 |
| prismbeetle | 3063 | 290 | 95 | 192 | 287 |
| prismmite | 4576 | 401 | 136 | 192 | 328 |
| puffballflock | 3698 | 307 | 108 | 192 | 300 |
| puffbee | 5878 | 459 | 136 | 192 | 329 |
| quarryback | 4690 | 414 | 146 | 192 | 338 |
| rambler | 5880 | 496 | 166 | 192 | 359 |
| reverser | 5420 | 445 | 147 | 192 | 339 |
| rootrunner | 5799 | 419 | 145 | 192 | 337 |
| skyjelly | 4276 | 284 | 97 | 192 | 289 |
| skyskipper | 5875 | 622 | 179 | 192 | 372 |
| soulmender | 5880 | 454 | 148 | 192 | 340 |
| sparkwright | 5880 | 465 | 148 | 192 | 341 |
| stillwatch | 5090 | 413 | 144 | 192 | 336 |
| stormhound | 4794 | 465 | 152 | 192 | 344 |
| stray | 4855 | 432 | 143 | 192 | 335 |
| swarmling | 3329 | 341 | 109 | 192 | 301 |
| tidewalker | 5876 | 555 | 145 | 192 | 338 |
| tinkerer | 5875 | 777 | 171 | 192 | 363 |
| twinned | 5887 | 692 | 191 | 192 | 384 |
| unmade | 3568 | 380 | 135 | 192 | 328 |
| valemoth | 5880 | 454 | 119 | 192 | 311 |
| wanderer | 5821 | 493 | 156 | 192 | 348 |
| wildfirebloom | 5880 | 645 | 165 | 192 | 357 |
| **All 43** | | 20.7 MB | 6.1 MB | 8.0 MB | 14.1 MB |

Each kind's 512² paint (175 KB) is now most of it; a scene is about 70%
mesh (a Rambler without its clips imports at 125 KB of 171 KB).

### More of the colour pass

- **Emberling's crown** burns cream at its core (`hot_core` 0.85, and the
  glass veil thinner face-on, `veil_see` 0.8 for every kind).
- **Metal parts** catch a pale sky where they face up (`metal_sky`): dark
  iron drew black where the design's sits pale in its bright room.
- **Prism Mite** lilac rather than saturated violet (`pastel` 0.35).
- The 24 portraits re-rendered after these global changes: no kind moved
  away from its portrait.

### Rounds (each judged at phone size and as a grayscale thumbnail)

1. Portraits of Golem, Bloomling, Emberling: worst were the Golem's pink
   sheen and near-black facets, Bloomling's crimson petals, the Emberling's
   all-orange crown. Fixed by the LOOK uniforms above.
2. Heist lineup: worst were muddy lit/shaded halves, noisy paint at 40 px,
   a pixel-wide sash on small kinds. Far floor, far blur, wider sash.
3. Heist screen: no ink at all on the crew. Cause: the 2× drawing
   resolution; ink and the far measure now in phone pixels.
4. Guards: red rim too faint to tell; crimson ink instead.
5. Golem as guard from four sides: the sash reads across the chest now.
6. Portraits again: Golem's dark bracers, Emberling's crown, the belly's
   glare. Metal sky and a hotter core (the belly still glows warm).
7. Install: relief 256 against 128 in the hero view, no visible change.
8. All 24 portraits: Prism Mite too saturated; pastel.
9. Each kind's sheen colour from its design module (`sheen` in the
   manifest; `FACTS_ONLY=1 node tools/art/export.mjs` reads the modules'
   facts again without an export). Scored against the 24 portraits by a
   colour histogram: neutral overall (Rambler and Prism Mite closer,
   Quarryback a little further; the Emberling keeps the warm white).
10. Paint at 256² for the smallest kinds: rejected, the hero view's irises
    lose their striations; the paint stays 512².
11. Bloomling's petals were flat pink: pastel now lifts light paint most
    (`pastel_by_value`), so a petal keeps its deep base under a pale tip.
12. Glass Golem's bracers: not metal parts (the design's dark stone), so
    the metal lift does nothing; left as they are.
13. The heist at 21h: the Glass Golem guards were dark blobs on dark grass
    (T5 brightens only the crew by night). A character's light now adapts
    to a dim sun (`night_eye` 0.5 toward the Heart's noon `day_sun`, at most
    ×1.7), so it keeps part of its daytime value at dusk and night; noon is
    unchanged. Still: `w4_heist_night.png` (noon and 21h, before and after).
14. Emberling's belly glare: the body glow (`glow_vc` 0.6 to 0.2) barely
    changes it, so it comes from a glowing accessory near the belly, not
    the paint. Not fixed; next to look at.

### Stills (`docs/art/shots/t1c/`, this session)

- `w4_heist_before_after.png`: the heist screen (`heist_shot.gd`, 200
  ticks) at phone size, wave 3 against wave 4, with grayscale thumbnails.
- `w4_crew_guards.png`: the eighteen ruleborn at the heist's camera as crew
  and as guards, wave 3 against wave 4.
- `w4_portrait_colour.png`: Glass Golem, Bloomling and Emberling: design,
  wave 3, wave 4.
- `w4_portraits_a.png`, `_b`, `_c`: the 24 design portraits, each beside
  ours in the hero view.

## For T5 (the heist)

- Call `CreatureModel.set_night(night)` instead of setting `rim_strength`,
  `lift` and `rim_colour` on the crew's material in
  `WorldView._light_figures`: those overwrite each kind's own sheen (Rambler's
  fleece takes 0.5 instead of its 0.2) and would wipe a guard's red rim.
- Guards are drawn at true size while the crew take `readable_scale()`; a
  Prism Mite guard is 15 px tall. Call `readable_scale()` for guards too.
- In `heist_shot.gd` at 200 ticks the two Glass Golem guards stand on the
  Rambler and the Skyskipper; overlapping figures merge whatever their ink.
- The "Weaving offers the starting laws" client test fails in this
  container on the base commit (1e8619b) too: the server recommends
  `slow_rivers` at price 0. Not from the characters; for the integrator.

## Still worse than the design

- **Size on the heist screen.** The design's heist shows its crew as small,
  bright, saturated toys; ours are 30–50 px and more earthen (Rambler,
  Rootrunner, Skyskipper are brown kinds by design). Their read now rests
  on the ink and the value step; crowding (crew inside the guards' rings)
  still merges figures.
- **Glass Golem**: our facets are larger than the design's (2,400 body
  triangles), and its bracers are darker than the design's pale stone.
- **Emberling**: the belly still glows warmer and brighter than the
  portrait's tan.
- Hero softness (image light, ACES) is still the shader's approximation.

## Next

- T5: `set_night`, `readable_scale` for guards, and keeping the crew out of
  the guards' rings in the heist shot.
- Paint atlas: 512² is now most of the install. Downscaling it on import
  costs the eyes; a smaller atlas would need the export to pack the eyes'
  charts larger (more texels for the face, fewer for the back).
- Emberling's belly: find the glowing part behind its glare (round 14).

## Stopped here (fourth session, 04:45 UTC)

- **Last pushed:** see the branch head; every change is inside T1's files.
- **Checked:** `tools/check_all.sh` on the final head: the simulation
  (326/326), the server (393/393) and the client (339 of 340) pass. The one
  client failure, the Weaving-against-the-server test, fails the same on
  the base commit 1e8619b in this container (the server recommends
  `slow_rivers` at price 0); `check_dependencies` after it fails on test
  names missing from the committed `client/status.json`. Neither is T1's.
- **Container setup this needed:** `rustup target add wasm32-unknown-unknown`,
  `pip install gdtoolkit==4.*`, and `pip install playwright==1.63.0` (the
  version whose browser is under /opt/pw-browsers).
- **Still worse and next:** the two sections above, and the Emberling's
  belly (round 14).

## Fifth session (wave 5)

### For T5 (the heist): one call for a portrait

- **`CreatureBust.of(kind, form := "", ground := Color(0, 0, 0, 0)) -> Texture2D`**
  (`client/world/creature_bust.gd`). `kind` as the content or the export
  writes it ("glass_golem" or "glassgolem"); `form` is "", "hush", "spark",
  "echo" or "guard". The bust is head and body to the hips for a ruleborn
  (02-heist.png's crew row), head and shoulders with the staff's lamp above
  for a Sage (its Sage disc), 192 px square, cut round. With `ground` it
  stands on a lit disc of that colour (lighter at the middle, deeper at the
  rim, as the design's discs); without one it is clear behind. Draw it at
  the disc's diameter. `CreatureBust.drawn(texture)` says when the picture
  has filled in; `settled()` when every bust asked for has.
- **Hooked in already (a few lines each, T5's files):** `FxPortrait` asks for
  the role's kind's bust on the role's colour and draws it at the disc's
  size; `WorldView._light_figures` calls `set_night(night, role colour)`
  instead of writing the crew's material, so each kind keeps its own sheen.
- **The Sage disc:** `CreatureBust.of("archivist", "", Color("#3A2A8C"))`
  (or the Sage the player brought) is ready for it.

### Rounds (wave 5)

1. Busts framed on `head_top` alone filled the disc with a face; the
   design's crew row shows head and body to the hips. Now at least 0.8 of
   the height from the head's top down, a Sage 0.66 with air above.
2. The ink outline read as a dark seam inside a 54-point disc; the design's
   portraits have none. Busts drop it (a guard keeps its crimson ink).
3. The owl, the Golem, Quarryback, Mossbear and Rambler are mostly head and
   back: their own framing (`FRAME`). Sages stand left with the staff's
   lamp at the right, as the design's Sage disc.
4. The heist's crew rim wrote `rim_strength`, `lift` and `rim_colour` over
   each kind's own: `set_night(night, side)` now takes the role colour.
5. Emberling's belly glare: the body glow (`glow_vc`) lit every paint whose
   red ran 0.3 over its blue, the tan belly (about 0.43) as much as the
   cracks. `glow_from`/`glow_to` (0.4–0.75 for Emberling) keep the cracks
   glowing and the belly paint.
6. Golem bracers: the granite read as dark iron. `gear_tint` lifts mid-valued
   accessory paint (stone, not the iron bands or the glowing hex).
7. Bloomling's petals read coral: `red_tint` takes red-over-green paint
   toward the design's pink (petal 248,128,156 against the portrait's
   241,154,178; was 255,105,120 at its deepest).
8. Heist ink: `far_width` 2.4 to 1.8. At 1080 px the thick line made ragged
   black blobs of the crew; at 1.8 they read as toys and still stand off the
   grass in grayscale (`w5_heist_ink_before_after.png`).

9. Every kind against its portrait, measured: the mean colour of each bust
   over its luminance, beside the design portrait's. The hero light's lilac
   fill made every kind bluer than the design's; the bust studio's fill is
   now part way to warm grey and its light 0.88 (the sum of the eighteen
   ruleborn's largest channel differences 1.03 to 0.81).
10. Soul Mender's wings read violet where the design's are pale pink: a
    pastel toward pink that spares dark paint (the eyes) and a warmer tint.
    Lantern Wisp warmer and paler; Glass Golem's tone 0.3 to 0.15 (its
    violet 0.94/0.77/1.31 against 0.94/0.74/1.31).

11. The heist's crew were three motion kinds (Featherkin, Rambler,
    Skyskipper): three cream-and-gold figures that merged on the grass and
    in their portraits. `Cast.KIND` (the integrator's, a few lines) now takes
    02-heist.png's own crew where it shows one (Skyskipper, Mossbear,
    Emberling) and Lantern Wisp and Bloomling for Scout and Mender: five
    colours, each read apart at a glance and in grayscale. Draw calls: heist
    128, long-crew5's result 149 (Hourkeeper's second surface would make it
    150).

### Stills (`docs/art/shots/t1d/`)

- `w5_busts.png`, `w5_busts_guard.png`: every ruleborn's and Sage's bust on
  its school's disc, own form and guard form.
- `w5_busts_vs_design.png`: 02-heist.png's five crew discs and Sage disc
  over ours, with grayscale thumbnails.
- `w5_heist_busts.png`: the heist (`screen_heist.gd`, MOMENT=sneak) with the
  busts in the crew row.
- `w5_colour_golem_ember_bloom.png`: Golem and Emberling, design beside ours;
  Bloomling beneath.
- `w5_heist_ink_before_after.png`: the crew at the heist camera, thick ink
  against 1.8.
- `w5_heist_crew_before_after.png`, `w5_heist_crew.png`: the crew at the
  Vault, three motion kinds against the new cast, with grayscale.
- `w5_portraits_vs_design.png`: the 24 design portraits, each over ours in
  the hero view.
