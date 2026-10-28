# T1 Characters

> T1's first session. The track continued in
> [`t1b-characters.md`](t1b-characters.md) and then
> [`t1c-characters.md`](t1c-characters.md) (sessions 3 to 5), which is the latest;
> the "Next" steps below are as they stood when this session ended.

Every character is the design's own sculpt (`art/design/creatures/`), exported
by the design's own code into Godot, rigged, animated, within §21.3's budget,
and drawn in the game's toon look.

## How it works

`node tools/art/export.mjs [kind…]` (after `npm ci` in `tools/art/`) runs each
module in headless Chromium (Playwright's global install) with three.js r184,
through `tools/art/harness.js`:

1. **Sculpt and rig by the design's code.** `build({res, shells: 0})` meshes
   the signed-distance sculpt at a fine step; `makeRig` computes the design's
   skin weights, A-pose and floor. `Math.random` is seeded per kind and
   `performance.now` is a fake clock, so the export is deterministic.
2. **Clips baked as they play.** Every clip (the 14 standard ones, the
   ability, any extras) is run for a settling loop, then sampled at 30 fps:
   springs, blinks, squash, effect nodes and spinners all land in the keys.
   The four expressions become held clips `expr_<name>` with the Rig page's
   breathing. Keys are thinned where linear interpolation is within 0.0015
   (rotations) or 0.4 mm (positions).
3. **One skin, one draw call.** Every joint, every node that moves (eyes,
   effect nodes, spinners) and every socket become bones of one skeleton. All
   other accessories are merged into the skinned mesh, rigid on their anchor
   bone (§21.3: "accessories merged into the skin"). Glass, transmission and
   additive parts go into a second surface. Back-face outline hulls are
   dropped; sprites and points become sockets.
4. **The fine sculpt on a light mesh.** The body is decimated with
   meshoptimizer to the kind's budget, cut into charts by facing, packed, and
   the module's own `paint()` is run at every texel on the sculpt's true
   surface (the field pulled along its gradient): colour with baked occlusion.
   The field's gradient is baked as a tangent-space normal map, so the
   feather scallops, fur ridges and facets of the hero sculpt light correctly
   on 2,600 triangles. Accessories keep their material colour in the vertex
   colour; eye textures go into a strip of the same atlas.
5. **Budget enforced.** Primitive segments are capped by `tools/art/three-lod.js`
   (an import-map shim over three; big spheres such as eyes keep 14 × 8),
   then accessories are simplified with meshoptimizer to what the body leaves
   of 5,880 triangles. A kind over 6,000 fails the export.
6. **Manifest.** `client/art/creatures/manifest.json`: per kind its triangles,
   bones, clips with lengths, scale, heights, sockets (design glow points,
   ember points, and the standard `head_top`, `chest`, `back`, `hand_R`,
   `hand_L`, `feet`), rim colour, glow, fur shells, school.

In Godot, `CreatureModel` (`client/world/creature_model.gd`) is the drop-in:

```gdscript
var c := CreatureModel.make(&"featherkin")   # make
c.place(Vector3(2.5, 0, 4.5), Vector3.FORWARD) # place (metres, facing; front is −Z)
c.play(&"walk")                                # play (the design's clip names)
```

plus `set_expression`, `set_form(&"base"|&"hush"|&"spark"|&"echo")`,
`set_guard(bool)`, `face`, `socket(name)`, `set_fur(n)`, `height()`.

The material (`creature.gdshader`, `creature_look.gdshaderinc`): the atlas and
normal map, §21.3's four-step ramp [62, 140, 215, 255] with +10% saturation
and violet shade, the design kit's `rimize` (side-masked Fresnel rim in the
kind's rim colour and a warm wrap), the vertex-colour glow (`vcGlow`), a hard
highlight band for brass and clearcoat, and a "lift" that pales lit light paint
toward warm white (the design's sheen and tone curve; dark paint stays dark).
Fur shells are next passes (`creature_fur.gdshader`), off in the world and on
in the Character screen. The ink outline (`creature_outline.gdshader`) is one
constant, `CreatureModel.OUTLINE`.

## What is exported

All 43 characters, each 3,000–5,880 triangles (the export fails above 6,000),
one skinned mesh with one opaque and at most one glass surface, 13–22 clips,
the design's expressions, and sockets:

- the 18 ruleborn (§21.6), the 4 launch Sages (Archivist, Tinkerer, Gardener,
  Wanderer), the 3 visitors (Cartographer, Collector, Stray) and the 3
  paradox-born (Reverser, Twinned, Unmade);
- Chronicler and Lamplighter, the 3 anomalies (Devourer, Hourglass Storm,
  Wildfire Bloom), the law creatures (Illusory Guard, Swarmling; the third,
  Stray as a law's echo, has no module of its own) and the 7 wildlife modules
  (Sky Jelly, Lanternfish, Prism Beetle, Puffball Flock, Puffballs and Bees,
  and the three moths).

`client/tests/creature_tests.gd` checks the list, the budget, §21.6's heights,
the shared clips, the standard sockets, and that `CreatureModel` makes, places,
faces, plays, takes forms and the guard form.

## Per kind

| Kind | Group | Triangles (body) | Bones | Clips | Height m (body) | .glb KB |
|---|---|---|---|---|---|---|
| featherkin | ruleborn | 5880 (2600) | 31 | 19 | 0.60 (0.60) | 852 |
| skyskipper | ruleborn | 5875 (2795) | 26 | 19 | 0.77 (0.80) | 740 |
| rambler | ruleborn | 5880 (3200) | 27 | 19 | 0.92 (0.92) | 721 |
| glassgolem | ruleborn | 4104 (2400) | 31 | 19 | 1.33 (1.20) | 819 |
| quarryback | ruleborn | 4690 (3374) | 27 | 19 | 0.94 (0.94) | 618 |
| prismmite | ruleborn | 4576 (3000) | 27 | 19 | 0.51 (0.50) | 551 |
| tidewalker | ruleborn | 5876 (2800) | 27 | 19 | 0.81 (0.80) | 687 |
| hourkeeper | ruleborn | 5876 (3000) | 27 | 19 | 0.93 (0.92) | 587 |
| stillwatch | ruleborn | 5090 (3194) | 27 | 19 | 1.19 (1.19) | 539 |
| emberling | ruleborn | 5879 (2799) | 27 | 19 | 0.98 (0.68) | 652 |
| stormhound | ruleborn | 4794 (3386) | 27 | 19 | 0.98 (0.97) | 607 |
| sparkwright | ruleborn | 5880 (2799) | 27 | 19 | 0.86 (0.79) | 608 |
| mossbear | ruleborn | 5854 (2988) | 58 | 19 | 1.38 (1.35) | 1287 |
| bloomling | ruleborn | 4551 (2799) | 27 | 19 | 0.73 (0.59) | 505 |
| rootrunner | ruleborn | 5799 (2999) | 27 | 19 | 0.98 (0.85) | 554 |
| echoplate | ruleborn | 5395 (3197) | 27 | 19 | 1.36 (1.23) | 556 |
| lanternwisp | ruleborn | 5430 (3000) | 27 | 19 | 0.88 (0.60) | 515 |
| soulmender | ruleborn | 5880 (3000) | 27 | 19 | 0.94 (0.94) | 583 |
| archivist | sage | 5880 (3395) | 45 | 14 | 2.02 (1.60) | 711 |
| tinkerer | sage | 5875 (2800) | 35 | 22 | 1.23 (1.20) | 969 |
| gardener | sage | 5852 (2099) | 33 | 22 | 1.57 (1.55) | 870 |
| wanderer | sage | 5821 (2997) | 32 | 22 | 1.50 (1.50) | 675 |
| cartographer | visitor | 5879 (2799) | 28 | 19 | 1.66 (0.72) | 680 |
| collector | visitor | 5880 (2697) | 29 | 19 | 0.96 (0.81) | 754 |
| stray | visitor | 4855 (2999) | 28 | 19 | 0.56 (0.55) | 569 |
| reverser | paradox | 5420 (3192) | 27 | 19 | 0.88 (0.87) | 588 |
| twinned | paradox | 5887 (3599) | 56 | 19 | 0.78 (0.65) | 879 |
| unmade | paradox | 3568 (3400) | 26 | 19 | 0.84 (0.84) | 505 |
| chronicler | sage | 5427 (2999) | 32 | 22 | 1.70 (1.50) | 710 |
| lamplighter | sage | 5876 (2999) | 30 | 22 | 1.55 (1.45) | 761 |
| devourer | anomaly | 5879 (3399) | 42 | 14 | 3.02 (1.92) | 634 |
| hourglassstorm | anomaly | 5659 (3399) | 29 | 14 | 2.68 (1.93) | 457 |
| wildfirebloom | anomaly | 5880 (3200) | 39 | 19 | 2.10 (1.87) | 817 |
| illusoryguard | law | 5872 (2600) | 31 | 19 | 0.64 (0.60) | 862 |
| swarmling | law | 3329 (1999) | 36 | 19 | 0.35 (0.27) | 491 |
| skyjelly | wildlife | 4276 (2400) | 26 | 13 | 1.47 (0.65) | 363 |
| lanternfish | wildlife | 4056 (2000) | 16 | 13 | 0.89 (0.39) | 321 |
| prismbeetle | wildlife | 3063 (1999) | 26 | 19 | 0.37 (0.24) | 407 |
| puffballflock | wildlife | 3698 (2600) | 27 | 19 | 0.47 (0.46) | 519 |
| puffbee | wildlife | 5878 (2600) | 29 | 19 | 0.57 (0.46) | 672 |
| ashmoth | wildlife | 5440 (1600) | 36 | 13 | 1.66 (0.40) | 507 |
| lanternmoth | wildlife | 5440 (1600) | 30 | 13 | 1.32 (0.32) | 497 |
| valemoth | wildlife | 5880 (1600) | 37 | 13 | 1.41 (0.34) | 560 |

All 43: 27 MB of .glb (each also carries a 512² colour atlas and normal map, extracted on import).

## Decisions and conflicts

- **Character outline.** §21.3 asks for 1.5 px ink outlines; the design's
  handoff says the owner had the character outline removed. Default: on, per
  §21.3, 1.5 px on the body and 0.45 px on accessories so eyes and straps are
  not ringed. One switch: `CreatureModel.OUTLINE`.
- **Shade tint and ramp on characters.** The world's violet shade turns
  saturated warm paint crimson, so characters use a lighter violet
  (0.68, 0.6, 0.9). The world's sun is high (58°), which leaves faces, being
  vertical, in the lower steps; on characters the same four steps start 0.22
  earlier in N·L (`ramp_bias`), so faces read in the light.
- **Lift.** The design's sculpts are pale where lit (sheen, image-based light,
  ACES). The top two steps lift light paint toward warm white by its value;
  dark paint (pupils, ink) stays dark; metal does not lift; Hush barely.
- **Body surfaces from the design's `bodyMat`.** Echoplate (metalness 1) is
  toon chrome (sky-facing bright, ground-facing dark, a hard highlight band);
  clearcoat kinds get the band; iridescent kinds a rainbow edge; the Golem and
  Lantern Wisp their emissive glow.
- **Vertex colours** arrive linear through Godot's glTF import; the atlas is
  sRGB. Gear built in GDScript converts its sRGB palette colours.
- **Heights.** Kept at the module's `GAME_SCALE` where it matches §21.6. Scaled
  to §21.6 by body height (without hover, plumes or crests): Prism Mite
  0.76 → 0.5 m, Glass Golem 1.39 → 1.2 m, Lantern Wisp 0.72 → 0.6 m, Skyskipper
  0.8 m. Sages: §21.1's "about 1.5 m"; the Archivist "tall" at 1.6 m, the
  Tinkerer "small" at 1.2 m, Gardener 1.55, Wanderer and Chronicler 1.5,
  Lamplighter 1.45. Anomalies and wildlife to the heights measured from the
  design in `docs/analysis/screens-v3/3d-pipeline.md` (section 3.3) (their modules
  have no `GAME_SCALE`).
- **Forms.** Hush: the paint remapped by its own luminance into midnight (the
  pattern survives), a scatter of star freckles on the body, and a small
  glowing crescent turning over the head (the accessory change §21.6 asks for).
  Spark: the paint warmed toward embers, lit from within, a hot rim, embers
  rising from the design's ember sockets. Echo: a translucent magenta twin a
  little behind and to the side, 0.3 s late on the same clip.
- **Guard form (ours; the design has none).** A red sash with gold trim and a
  knot, over the chest bone a little outside the body so fleece does not hide
  it, and a small brass lantern with a glowing body at the right hand socket.
- **Wings and sheets.** Double-sided sheets get real back faces with a little
  self-light; alpha-tested sheets (moth wings) are cut into geometry from
  their texture's alpha.
- **Bakes.** Kit modules bake from the sculpt's own field and paint.
  Skyskipper and the Archivist keep theirs private, so their atlas is
  transferred from the fine mesh's painted vertices.
- **Files I touched outside the track:** `client/tests/run.gd` (one line
  registering `CreatureTests`), `README.md` (the `tools/art/` row).

## Stills

- Before: `docs/art/shots/t1-characters/before_world_shot.png` (the chibi
  placeholders in the heist).
- Design portrait above ours, with grayscale thumbnails:
  `portraits_a_r7.png`, `portraits_b_r7.png` (the ruleborn),
  `portraits_c.png` (Skyskipper, Sages, visitors, paradox-born).
- `portraits_d_r9.png`: after skyline packing and the Gardener's brim fix.
- `featherkin_portrait_r6.png`: Featherkin, design beside ours at portrait size.
- `lineup_ruleborn.png`: the eighteen to scale. `lineup_others.png`: Sages,
  visitors, paradox-born, anomalies, law creatures, wildlife.
- `lineup_guard.png`: every ruleborn in the guard form. `lineup_hush_squint.png`:
  every ruleborn in Hush, and in black for §21.6's squint test.
- `heist_scale.png`: crew walking, running, carrying, wading and knocked out,
  and three guards, from the heist's 50° orthographic camera 12 tiles across
  at phone size; characters stand 30–60 px tall there.
- `forms_featherkin_guard.png`: base, Hush, Spark, Echo, and the guard form
  on Rambler and Bloomling.

## Install size

The `.glb` names its two textures as files beside it (`<kind>_paint.jpg`, the
colour atlas, and `<kind>_relief.jpg`, the normal map) instead of embedding
them, so Godot imports each once; the exporter writes their import settings:
GPU-compressed with mipmaps (a 40 px character must not shimmer), the relief
map read as a normal map and held to 256². Per kind the imported textures
fell from about 614 KB (lossless, no mipmaps) to about 262 KB. The source
folder is 29 MB (was 32 MB). The imported scene (mesh and clips) is about
276 KB a kind and is the larger share now.

## For the look track

`sky.gdshader` draws its quad at clip depth 1e-5. Godot's Compatibility
renderer here uses reversed depth without clip control, where far is −1, so
under a perspective camera the quad sits mid-depth and covers the scene (the
orthographic world camera escapes it). My perspective shots set `far_z` to
−0.99999 for themselves; the heist's perspective camera will need the shader
fixed.

## Still worse than the design

- Softness: the hero renders have sheen, image-based light and ACES; ours are
  crisper and more saturated (Glass Golem reads deep violet, not lilac glass).
- Accessory detail is coarse at the budget: the Featherkin cape feathers are
  flat slabs, small brass parts are simplified. (The Gardener's woven brim
  needed a lighter body, 2,100 triangles, to keep its vines.)
- Atlas packing (skyline) still leaves gaps between charts; a 1,024 atlas for
  the Character screen would show the paint sharper.
- File sizes are 330–1,050 KB per kind (32 MB in all); the glTF JSON of the
  thinned animation tracks is a large share.
- The forms are shader and gear work, not the per-kind pattern and accessory
  §21.6 imagines for each of the 54.

## Next

- The integrator swaps `CreatureModel` into the heist's actors
  (`ActorBuilder` today): `make`, `place`, `play`.
- Tighter atlas packing (skyline packer) and 1,024 for the Character screen.
- Per-kind accessory budgets so faces and signature props keep their segments.
- Shared animation time accessors to shrink files.
