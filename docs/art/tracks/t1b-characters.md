# T1b Characters (second agent on the characters track)

Takes over T1's work (`docs/art/tracks/t1-characters.md`): the export
harness, `CreatureModel`, its material, forms and guard form.

## Done

- **Tree green.** The first full check run on this branch failed only because
  the machine lacked the `wasm32-unknown-unknown` Rust target and `gdlint`;
  with both installed the run passed every stage through the client's tests
  (322 of 322) on the readability commit.
- **Readability at the heist's size.** The creature shaders work out how many
  pixels a metre covers on screen (from the projection and depth, so it holds
  for the heist's 22° perspective and the orthographic views). Under 240 px a
  metre the ink outline thickens (up to 1.7×), the rim strengthens (up to
  1.8×) and wraps further round, and the shade opens a little. Guards take a
  red rim (`CreatureModel.GUARD_RIM`), a wider sash and a larger lantern with
  a brighter halo. `CreatureModel.readable_scale()` draws the ruleborn band
  0.5–1.4 m as 0.95–1.4 m, so small kinds grow most, the Golem and Mossbear
  barely, and the order of heights holds. Hook outside the track: one line in
  `client/world/world_view.gd` (T5's) uses `readable_scale()` when the model
  has it. Still: `docs/art/shots/t1b/heist_readability_before_after.png`.
- **Forms (§21.6: pattern, glow and one accessory in the note's colour;
  11.10's looks).** Each form now hangs its note's symbol (8.1) over the head:
  - Hush: midnight paint with star freckles, as before, plus soft violet ink
    (finer) and a broad moonlit rim all round instead of the hard side rim
    ("soft, silent edges"); a crescent charm.
  - Spark: lit from within, as before, plus ember flecks that flare and fade
    in the paint and arcs that crawl along the silhouette ("crackling tips and
    ember flecks"); embers rising; a rounded five-point star charm.
  - Echo: rings that run up the body in Echo cyan; two faint ghost outlines
    (cyan, bright only at the silhouette) that stand where the body was 0.3 s
    and 0.6 s ago on the same clip delayed, a little behind and aside when
    still; a ring charm. The first ghost is still the child named `echo`.
  Still: `docs/art/shots/t1b/forms_ruleborn.png` (rows: base, Hush, Spark,
  Echo, guard; Featherkin, Rambler, Hourkeeper, Emberling, Mossbear, Lantern
  Wisp), from the new shot `client/tests/shots/creature_forms.gd`.

## Stopped here

The owner asked every agent to stop at 19:19 UTC.

- **Not checked:** the forms commit was not run through `tools/check_all.sh`
  (it takes about 25 minutes); gdlint passes on every changed script, and the
  forms shot renders without shader errors. The last full run (client tests
  322 of 322) was on the readability commit before it.
- **Still worse than the design:** the hero renders' softness (sheen, image
  light, ACES); the Glass Golem reads deeper violet than its lilac portrait;
  the guard's sash still hides under big arms (Golem) at 40 px; forms are
  shader and gear work, not a per-kind pattern for each of the 54; the black
  squint render does not blacken the gear (charms still glow).
- **Install size (not started).** Measured: the imported scenes are 9.4 MB
  and the textures 11 MB for the 43 kinds; a .glb's binary is mostly mesh
  (tangents are float VEC4), and about half its 551 animation channels (276
  on Featherkin) are static. Next: in each `.glb.import` turn off
  `meshes/create_shadow_meshes` (characters cast no shadow) and measure
  `meshes/generate_lods`; enable per-animation compression; collapse static
  channels to one key (dropping those equal to the rest pose) in
  `tools/art/export.mjs`'s `slim`; try Basis Universal for the paint atlas;
  record per-kind triangles and sizes here.
- **Next step:** run `bash tools/check_all.sh` on this head, then the install
  size work above.
