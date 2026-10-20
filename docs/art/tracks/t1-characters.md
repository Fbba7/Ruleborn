# T1 Characters

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

## Decisions and conflicts

- **Character outline.** §21.3 asks for 1.5 px ink outlines; the design's
  handoff says the owner had the character outline removed. Default: on, per
  §21.3, 1.5 px on the body and 0.45 px on accessories so eyes and straps are
  not ringed. One switch: `CreatureModel.OUTLINE`.
- **Shade tint.** The world's violet shade turns saturated warm paint crimson
  on a character, so characters use a lighter violet (0.68, 0.6, 0.9).
- **Vertex colours** come through Godot's glTF import in linear space; the
  atlas is sRGB.
- **Heights.** Prism Mite (0.5 m) and Glass Golem (1.2 m) are scaled to §21.6
  by their body height (`fix` in `tools/art/kinds.mjs`); the rest keep their
  module's `GAME_SCALE`.

## Stills

Before (the placeholder chibi actors in the heist):
`docs/art/shots/t1-characters/before_world_shot.png`.

Featherkin, design portrait beside ours, and the turntable:
`docs/art/shots/t1-characters/featherkin_portrait_r6.png`,
`docs/art/shots/t1-characters/featherkin_turntable_r6.png`.

## Still worse than the design

- The design's hero renders are softer (sheen, image-based light, ACES); ours
  are crisper and a shade more saturated.
- The cape's 59 feathers are flat slabs without bevel at this budget.

## Next

The other 17 ruleborn, the Sages, visitors and paradox-born, then the rest.
