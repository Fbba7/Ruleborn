# Handoff part: CHARACTERS.md and the assets the earlier reading never saw

Part: `assets`. Read in full: the handoff's `CHARACTERS.md` (100 lines); the six baked meshes `prototype/*.bin`, decoded with the format in `prototype/creature-kit.js:57–61`; the six top-level `prototype/world/*.png`, viewed; the local three.js files `three.module.js`, `three.core.js`, `three-global.js` and `three-shim.js`. Compared with v3.6, the document when this was written (`docs/design/ruleborn-game-design-v3.6.txt`, cited as v36:line), `docs/analysis/screens-v3/characters.md`, `3d-pipeline.md` and `data/census_table.md` (the folder above), the register (`tools/audit_register.py`, dumped fresh at commit 6cc1d1e), `docs/decisions/brief.json` and `answers.json`, and `tools/roadmap.py`.

Paths: `HO/` is the handoff, `design_handoff_ruleborn`. Its four documents are copied unchanged to `source/`, so `HO/README.md` and CHARACTERS.md are `source/README.md` and `source/CHARACTERS.md`. `P/` is `HO/prototype/`, which is not kept in the repository. The measurements kept are in `data/`: the six meshes decoded (`bins.jsonl`), the screen index's dependencies (`deps.txt`) and the prototype's file hashes (`prototype.md5`); the script that decoded the meshes (`scratch/assets_work/binmeasure.py`) is not kept. Every Python run that read handoff files used `python3 -I`. Read against the repository at commit 6cc1d1e; the line numbers it cites in the register (AR), the brief and the roadmap (RM) are that commit's. What it proposes was checked and folded into the register's v3.6 layer, the brief and stage SD afterwards ([README.md](README.md)). The earlier reading's reports, cited by file name, are in the folder above.

## 1. Summary

- **CHARACTERS.md's tables agree with v3.6 except one row.** All 18 kinds have v3.6's school and role (§11.2, v36:5972–6127). The Sages' unlocks match §11.7 (v36:6188–6217). The paradox-born, the visitors, the anomalies and the law creatures match §11.8 and §7.7. The exception is Verdant's wildlife, "Puffballs and bees" (CHARACTERS.md:78). v3.6 says Verdant's wildlife is "bees and butterflies" (v36:1102, 1136, 11634). The existing analysis and TD.32 already hold this. TD.32's wording needs a small fix (finding A8).
- **The export section adds one thing the roadmap lacks, and gets two details wrong.** Clip names should stay the `CLIPS` keys (CHARACTERS.md:98). TD.7 does not say that. But the handoff's example `play("caught")` names an expression, not a clip. Its "bone quaternions, positions and morphs" (CHARACTERS.md:96) would lose squash and blinks, which are scale tracks on nodes that are not bones. No module has morph targets (A3).
- **The material line is the owner's intent, and it matches none of D92's options.** "Soft lambert shading with a rim light, no black outline (it was removed at the user's request)" (CHARACTERS.md:99) goes against §21.3's "three-step toon ramp … and 1.5-pixel ink outlines" (v36:10462). All three D92 options keep some ink outline. The code shows the removal: Skyskipper builds an ink hull and hides it (`P/skyskipper-sculpt.js:184`, `ol.visible=false`), and its rig deletes it (`P/skyskipper-rig.js:44`). This is intent, not an answer (A1).
- **The scale line contradicts v3.6.** "A ruleborn is about 1.2 grid tiles tall" (CHARACTERS.md:100) gives every kind one height. §21.1 sets one tile to one metre and ruleborn at 0.5 to 1.4 m (v36:10408). §21.6 gives each kind its own height. TD.7's gate already follows the document (A2).
- **The baked meshes do not change TD.7's plan.** The six `.bin` files are bodies only: no eyes, no accessories, no clips and no bones. Four of them carry no skin weights at all. Each holds 65,054 to 164,298 triangles, 11 to 27 times §21.3's 6,000 ceiling (v36:10466). Three match the analysis's live builds exactly (80,828, 134,174 and 164,298 triangles), so they are caches of the sculpt-meshing step and add nothing an export from code cannot make. They are useful only as test fixtures. Skyskipper's game mesh differs from the live build (A4). They make G61's "No model file exists" and 3d-pipeline.md:109's "no .bin is in the bundle" out of date in wording, though not in conclusion (A5).
- **The baked meshes give two heights the analysis lacked.** At their Rig pages' game scales, Skyskipper stands about 0.96 m against §21.6's 0.8 m. The Archivist's body stands about 1.73 m against §21.1's "Sages about 1.5". Neither is in D94 (A6). The census's Skyskipper "hero" figure is for the Rig page's step, not the Hero page's (A7).
- **The six world PNGs are orphans.** No page loads them. The screen index's 223 declared dependencies, `source/README.md:209` and CHARACTERS.md never name them. They are screenshots of an earlier version of six screens, with UI labels baked into the image and the diorama's chibi stand-ins. The build cannot use them and has nothing to redo, because TD.10 draws those screens live. No task records what happens to any of the 2D renders except the portraits (A9).
- **The local three.js is the same release the analysis ran.** `three.core.js` and `three.module.js` are byte-identical to npm `three@0.184.0` (md5 `a07d251e…` and `3265e1a0…`, the same as `scratch/3dp/vendor/three/build/`). Nothing changes.

## 2. CHARACTERS.md, row by row

### 2.1 The 18 kinds (CHARACTERS.md:15–34) against §11.2 (v36:5972–6127)

All 18 rows match v3.6 on school and role, checked one by one:

| Kind | Handoff school / role | v3.6 §11.2 | Status |
|---|---|---|---|
| Featherkin | Motion / Scout | Motion / Scout | agrees |
| Skyskipper | Motion / Carrier | Motion / Carrier | agrees |
| Rambler | Motion / Breaker | Motion / Breaker | agrees |
| Glass Golem | Matter / Warden | Matter / Warden | agrees |
| Quarryback | Matter / Breaker | Matter / Breaker | agrees |
| Prism Mite | Matter / Carrier | Matter / Carrier | agrees |
| Tidewalker | Time / Carrier | Time / Carrier | agrees |
| Hourkeeper | Time / Mender | Time / Mender | agrees |
| Stillwatch | Time / Warden | Time / Warden | agrees |
| Emberling | Energy / Breaker | Energy / Breaker | agrees |
| Stormhound | Energy / Scout | Energy / Scout | agrees |
| Sparkwright | Energy / Mender | Energy / Mender | agrees (the goggles are C54) |
| Mossbear | Life / Warden | Life / Warden | agrees |
| Bloomling | Life / Mender | Life / Mender | agrees |
| Rootrunner | Life / Carrier | Life / Carrier | agrees |
| Echoplate | Spirit / Warden | Spirit / Warden | agrees |
| Lantern Wisp | Spirit / Scout | Spirit / Scout | agrees |
| Soulmender | Spirit / Mender | Spirit / Mender | agrees |

Every module named in CHARACTERS.md exists in `P/`. All 43 Rig pages map `GLTFExporter` in their import maps, and none calls it.

### 2.2 Sages (CHARACTERS.md:39–48) against §11.7 (v36:6188–6217)

Start, Keeper level 7, 13 and 20 all match. "The Chronicler (Time) and the Lamplighter (Energy) follow after launch" also matches. Their looks are adopted under G65.

### 2.3 Paradox-born, visitors, anomalies, law creatures (CHARACTERS.md:50–68)

- The paradox-born come from Reversal, Twin suns and Unmaking, matching §11.8.
- The visitors' offers match §11.8. The Stray has its own `stray.js`, a kitten. v3.6 says it is "one of the eighteen kinds … there is no nineteenth kind" (v36:6235), and §23.5 overrules the design (v36:11612–11615). Covered by characters.md (lines 60, 151), G63 and G64.
- The anomalies arrive with version 1.1, matching §11.8 and §17.3.
- The law creatures: Flock and Mirror images are "Follows after launch" (v36:3324, 3696), and so is Swarm birth (v36:3448). Their sheets' variants are D95, their behaviour D94, and §23.5 has rows for them (v36:11617–11630).

### 2.4 Wildlife (CHARACTERS.md:71–79) against §5.7 (v36:986–1136) and §23.5 (v36:11632–11634)

Six of the seven rows agree. Verdant does not: the handoff has "Puffballs and bees | puffbee.js, puffball-base.js", while v3.6 has "Bees and butterflies" (v36:1102) and "puffballs belong to the Flock law (7.7), so Verdant's wildlife is bees and butterflies" (v36:1136). This is covered by characters.md:176 and :297–302, by §23.5's own row and by TD.32. TD.32's wording is slightly wrong; see A8.

### 2.5 Module exports (CHARACTERS.md:81–86)

- **`build(opts)`, `opts.res`.** The handoff gives 0.011–0.019. The diorama builds at `max(RES, .014 or .019)` (`P/realm-diorama.js:586`) and Skyskipper at .015, so the range agrees with the census.
- **`makeRig(src)` returns `{ root, apply(clipName, t) }`.** That is wrong. The kit's rig exposes `play(pose, clip)` and `set(pose)` (`P/creature-kit.js:117–118`), a clip's `f(t)` returns a pose, and `set` reads `performance.now()` for its springs. This matters to the export harness (A3).
- **`CLIPS`.** "Tidewalker has idle, ability, wade, nap, work, calm, focus, startled and caught" is wrong. In `P/tidewalker.js`, `CLIPS` at :63 overrides five of the kit's 15 clips (idle, ability, wade, nap, work). `calm`, `focus`, `startled` and `caught` are `EXPR` keys at :69–72 (A3).
- **`BIN`, `RES`.** 40 modules declare a `BIN`, and only `featherkin.bin` and `mossbear.bin` among those exist. Skyskipper and the Archivist load their meshes through their own loaders. The other 38 pages fail the fetch silently and mesh live.

### 2.6 How the characters appear in the screens (CHARACTERS.md:88–91)

- **"realm-diorama.js loads each character with `heroLoad(kind)`" (line 89).** That is not what the prototype does. `upHero` returns unless `window.RB_HEROES` is set (`P/realm-diorama.js:600`), and nothing sets it in the handoff either. `heroLoad` knows only six kinds: Skyskipper, Tidewalker, Mossbear, Echoplate, Emberling and Glass Golem (:581, :585). So the screens draw the 24-mesh chibi stand-ins. 3d-pipeline.md:69 already states this. Covered; nothing to change.
- **Character screen from the Rig page.** Covered by D93's close-up question.
- **Portraits from `world/portraits/`.** These are renders of the physically based look, and TD.11 re-renders them. Covered by D92 and TD.11, and intent.md:304 treats README:209 the same way.

### 2.7 Moving to Godot (CHARACTERS.md:93–100)

| Step | Handoff | Against | Status |
|---|---|---|---|
| 1 Export | GLTFExporter mapped but not wired; build and makeRig; sample at 30 fps (bone quaternions, positions, morphs); binary .glb | TD.7, 3d-pipeline.md §4.1 | route covered by TD.7 and G61; channel and naming details are finding A3 |
| 2 Import | AnimationPlayer clip names = CLIPS keys; `play("caught")` | TD.7, TD.10 | finding A3 |
| 3 Materials | "soft lambert shading with a rim light, no black outline (it was removed at the user's request), and the school colours from the README" | §21.3 v36:10462, D92, TD.8 | finding A1; the README's school colours are the intent part's (D89, D91) |
| 4 Scale | "about 1.2 grid tiles tall" | §21.1 v36:10408, §21.6, TD.7 gate, D94 | finding A2 |
| Title | "Godot 4.7.2" | §23.5 v36:11643 | covered by D76 |

## 3. The baked meshes

### 3.1 Format

From `P/creature-kit.js:57–61` (`loadBaked`, `serialize`; the same layout in `P/skyskipper-sculpt.js:176` and `P/archivist-sculpt.js:205`):

- a little-endian uint32 header length;
- a JSON header `{attrs:[{name,type,item,off,len}]}`;
- padding to 4 bytes;
- the raw typed arrays: `position`, `normal`, `color` (vertex paint with baked occlusion), `furMask`, optional `skinIndex` and `skinWeight` (four per vertex), and `index`.

There are no bones, joint positions, accessories, eyes, clips or materials. The cache key is `'g'+res`, so a bin is used only when `build()` is called at exactly that step. Every file parsed to its exact size.

### 3.2 Measured

| File | Bytes | Vertices | Triangles | Skin | Bones referenced | Morphs | Step it is loaded at (page) | Census, same character |
|---|---|---|---|---|---|---|---|---|
| featherkin.bin | 2,091,796 | 40,161 | 80,828 | none | — | none | .0078 (`featherkin.js:120`, Hero and Rig) | hero body 80,828 at .0078: **identical** |
| mossbear.bin | 4,251,476 | 66,025 | 134,174 | none | — | none | .009 (`mossbear.js:88`) | hero body 134,174 at .009: **identical** |
| archivist-hero.bin | 5,265,884 | 82,348 | 164,298 | none | — | none | .0072 (`Archivist Hero.html:69`) | hero body 164,298 at .0072: **identical** |
| archivist-game.bin | 4,824,672 | 63,502 | 126,666 | 4 per vertex | 18 used, index ≤ 21 (22 bones) | none | .0082 (`Archivist Rig.html:82`) | not measured at .0082; 23,446 at .019 |
| skyskipper-hero.bin | 2,175,068 | 41,821 | 83,640 | none | — | none | .0072 (`Skyskipper Hero.html:54, 69`) | not measured at .0072 |
| skyskipper-game.bin | 2,473,044 | 32,534 | 65,054 | 4 per vertex | 20 used, index ≤ 20 (21 bones) | none | .0081 (`Skyskipper Rig.html:81`. `realm-diorama.js:585` names it too, but only `upHero` calls that loader, and it is gated by `RB_HEROES`, which nothing sets; the diorama never loads a `.bin`) | live at .0081: 66,668, **1,614 more** |

Total: 21.1 MB for four characters. Against §21.3's "characters 3,000 to 6,000 triangles" (v36:10466), the bodies alone are 10.8 to 27.4 times the ceiling, before any accessory. Covered by D93 as a budget matter. These are the sheets' steps, not game steps.

### 3.3 Heights read from the meshes

The body bounding box gives the height in sculpt units. The game scale comes from the module or the Rig page.

- **Featherkin.** 0.986 × `GAME_SCALE` 0.62 = 0.61 m, against §21.6's 0.6 m. Agrees, as in the census.
- **Mossbear.** 1.134 × 1.2 = 1.36 m body, 1.40 m with moss (census), against 1.4 m. Agrees.
- **Skyskipper.** It has no `GAME_SCALE`. The Rig page's game view scales it by 0.8 (`Skyskipper Rig.html:85`). The body is 1.152 units, so 0.92 m. The whole model in idle is 1.2 units (`scratch/3dp/out/measure_all.json`), so 0.96 m. §21.6 says 0.8 m (v36:10675). That is 15–20% tall, and D94 does not list it (A6).
- **Archivist.** The Rig page's game view scales it by 1.25 (`Archivist Rig.html:85`). The body is 1.387 units, so 1.73 m. The whole model with staff and book is 1.784 units, so 2.23 m. §21.1 says "Sages about 1.5" (v36:10408). With the census's other Sages at 0.97 to 1.45 m, the six Sages span 0.97 to 1.73 m (A6).

The diorama ignores all of these and scales every kind to one height (3d-pipeline.md:69).

### 3.4 Does a baked mesh change TD.7's plan?

No:

- The bins carry no accessories, eyes, rig or clips. TD.7 needs all of those, and builds them from code anyway.
- They sit at the sheets' fine steps. TD.7 picks a coarser step per kind to meet the budget, and at another step `loadBaked` is never consulted.
- The three that match the live build show that the code reproduces them, so the code stays the source.
- Skyskipper's game mesh does not match. That is one more reason to export from code and not from the files.

They have one use: as fixtures that test the harness meshes the same way the designer's page does (A4).

## 4. The six world PNGs

Each image was viewed. All are 520 px wide 8-bit RGBA screenshots. None is referenced by any HTML or JS in `P/`, by the 223 `ext-resource-dependency` entries of `P/Ruleborn Screens v3.dc.html` (listed in `data/deps.txt`; the other 38 `world/` images are all there), by `source/README.md:209` (which lists only `land/`, `scout/`, `portraits/` and `obs/`), or by CHARACTERS.md.

| File | Size | What it shows | Screen it depicts | Use in the build |
|---|---|---|---|---|
| home.png | 520 × 648 | Universe map crop: Skyfield ("2 laws · lv 4") above, a gold chute down to the Heart ("Spire 7 · Vault 6"), the Spire, cottages, a chibi, galaxy sky; HTML pins baked in | 01 Universe map | None. An older render, with labels baked in. TD.10 draws the map live; nothing to redo |
| realm.png | 520 × 525 | The Heart's realm view: the Spire on a plaza, cottages, chibi workers, lanterns, law tags "Stillness · Hush · tier II" and "Slow rivers · Weight · tier II" | 04 Realm view | None, as above |
| heist.png | 520 × 595 | Heist mid-run: five chibi crew bottom left, three ward obelisks with glowing orbs and rune rings, lantern posts, the Vault as a lavender brick cube with a black top, a route line, the hint "guards patrol with their eyes closed" | 02 Heist | None, as above. It shows the chibi stand-ins, not the sculpts |
| landing.png | 520 × 665 | Landing picker: two islands joined by a chute, a lavender tower, chips "Nobody hears you" twice and "25% heard" (§5.4's 250 of 1,000 suspicion, v36:825) | 23 Landing picker | None, as above |
| result.png | 520 × 313 | Close-up of a lavender brick tower with a pink roof, trees, a lantern, a chibi in the corner; a backdrop strip | 07 Heist result (backdrop) | None, as above |
| workshop.png | 520 × 580 | Terrain editing: pink pillar blocks, blue trees, a ward obelisk, a chibi, and a tool rail "Terrain / Laws / Guards / Test" drawn with the school shapes (cube, eye, bolt, chevron) | 22 Terrain editor or 25 Island Workshop, an earlier version (today's editor has family tabs: `scratch/shots/all/Gameplay_22_Terrain_editor.png`) | None, as above. The rail is gone from the current screens, so its reuse of school shapes needs no item |

In short, the six are left over from an earlier iteration. They are not assets, and not renders the build must remake, because TD.10 draws each screen live in the look D92 decides. They should be left out of the client (A9).

## 5. The local three.js files

| File | What it is | Status |
|---|---|---|
| three.core.js | three.js r184 core (`REVISION = '184'`), md5 `a07d251e54747101583a45ebd4d9b4a3`, byte-identical to npm `three@0.184.0` | Same release and bytes the analysis ran (3d-pipeline.md:8). Nothing changes |
| three.module.js | r184 module entry, md5 `3265e1a099a28b1900faf27cfe0b8335`, byte-identical to npm 0.184.0 | The diorama imports it only as a fallback when `window.THREE` is missing after 2.5 s (`P/realm-diorama.js:34–35`). The 86 Hero and Rig pages still import three from unpkg with SRI hashes |
| three-global.js | r184 as a classic script setting `window.THREE` (2.07 MB) | Loaded by the screen index (`Ruleborn Screens v3.dc.html:233`) and `rb-art.js`. Prototype plumbing |
| three-shim.js | Re-exports `window.THREE` as ES module names; the import map's `three` | Prototype plumbing |

`GLTFExporter` is not shipped locally. TD.7 takes it from npm's `examples/jsm`, as the analysis did. Covered by TD.7.

## 6. Findings

### A1. The owner's material rule — smooth shading with a rim, no outline — is not among D92's options (intent, high)

**Claim.** CHARACTERS.md:99 asks the Godot port to "match the toon look. Use soft lambert shading with a rim light, no black outline (it was removed at the user's request)". v36:10462 states the shading as a rule: "a three-step toon ramp with coloured shadows tinted toward violet, a soft rim light, and 1.5-pixel ink outlines". D92 is open. Its options are §21.3 as written, the design's two looks, or one toon look on the design's four-step ramp, and every one of them keeps an ink outline somewhere. Option A and the recommended C put a 1.5-pixel line on every model; B keeps world-unit shells on the diorama. None has smooth shading with no outline.

**Evidence.**
- The code shows the outline was taken off the characters on purpose. Skyskipper builds a back-face ink hull in `#1A0C14` and hides it (`P/skyskipper-sculpt.js:184`, `ol.name='outline';ol.visible=false`), and its rig deletes it (`P/skyskipper-rig.js:44`).
- The removal stops at the characters. The diorama still outlines buildings and props (`P/realm-diorama.js:486, 520`).
- No file in `P/` uses `MeshLambertMaterial`. Characters are `MeshPhysicalMaterial` (`P/creature-kit.js`, `P/creature-parts.js`) and the world is `MeshToonMaterial` (26 uses in `realm-diorama.js`). So "lambert" describes neither, and "match the toon look" in the same sentence contradicts it.
- The Unmade draws its own "ink outline … a little inside the edge of every part" (`P/unmade.js:40`) as part of its paper look.

This is the owner's intent. It is not a recorded answer to D92, and §21.3's rule stands until the owner changes the document.

**Proposed action.** Brief-context D92. Quote CHARACTERS.md:99, and add an option D, "the handoff's look":
- Means: smooth diffuse shading with a rim light, school colours, no ink outline on characters (and say whether the world keeps its hulls).
- Doc edit: §21.3's Shading line becomes "smooth shading with a soft rim light and coloured shadows tinted toward violet; no ink outlines", and "The toon, outline … shaders already exist" is struck.
- Consequences: a model must pass §21.1's 32-point silhouette rule (v36:10399) and §21.10's grayscale test without a line; one draw call per character is saved; the Unmade keeps its own drawn ink.
- Build change: TD.8 gives the ramp step count and the outline (on, off, world, screen) as tokens.

D92's also_needed (which ink) becomes moot under D. Separately, roadmap-amend TD.8: list "outline off" and "smooth shading" among the variants one token away, alongside the design's four-step ramp.

**Relates to:** D92, TD.8, D89 (ink colour), §21.3.

### A2. The handoff's single game scale, "about 1.2 grid tiles tall", contradicts §21.1 and §21.6 (spec, medium)

**Claim.** CHARACTERS.md:100: "Scale: match game scale against the island grid. In the prototype a ruleborn is about 1.2 grid tiles tall." That gives every kind one height. v36:10408: "One tile is one metre. Ruleborn stand 0.5 to 1.4 metres, Sages about 1.5". §21.6 gives each kind its own height, from Prism Mite at 0.5 m to Mossbear at 1.4 m (v36:10670–10755). §23.5 makes the numbers win (v36:11387). TD.7's gate already follows the document: heights within 5% of §21.6 and §21.1. The handoff's guidance contradicts TD.7, and TD.7 is right.

**Evidence.**
- CHARACTERS.md:100.
- v36:10408 and v36:10670ff.
- The prototype's diorama "scales every kind to the same 0.64–0.76 units × 2.2 (:602), ignoring each module's GAME_SCALE" (3d-pipeline.md:69).
- TD.7 gate: "every asset with a stated height (§21.6's eighteen kinds …, §21.1's Sages at about 1.5) within 5% of it".

**Proposed action.** Roadmap-amend TD.7. Add to the detail: "The handoff's 'about 1.2 grid tiles' for every ruleborn (CHARACTERS.md:100) is the prototype's diorama, which ignores GAME_SCALE. The import scale is set per kind from §21.6's height column at one tile to the metre (§21.1), and the Rig pages' own scales (Skyskipper 0.8, Archivist 1.25) are not used." Brief-context D94: note that the owner's handoff describes the single-height diorama, which is not an answer to the heights row.

**Relates to:** D94, TD.7, TD.10, 3d-pipeline.md finding 5.

### A3. TD.7 does not fix the clip names, the sampled channels or the expressions, and the handoff's API and example are wrong (spec, medium)

**Claim.** The handoff gives three export rules TD.7 does not state: sample at 30 fps, keep the clip names identical to the `CLIPS` keys so gameplay can call `play(...)`, and export binary .glb (CHARACTERS.md:96–98). TD.7 says only "bakes the clips with springs off". The handoff's own details would break the export in three ways:

- **Morphs and scale.** It lists "bone quaternions, positions and morphs". No module has morph targets; the only `morphAttributes` are in three.js itself. Squash is a non-uniform scale on the `lean` group, blinks are eye-mesh scale, and effect nodes show and hide by scale (`P/creature-kit.js:126–128`). Sampling bones only would drop all three. The analysis's working export recorded every moving node's position, rotation and scale (3d-pipeline.md:186), and 45 of Featherkin's 435 tracks are scale (3d-pipeline.md:191).
- **`play("caught")` names an expression.** The handoff's Tidewalker list mixes the two. In `P/tidewalker.js`, `CLIPS` (:63) has idle, ability, wade, nap and work over the kit's standard 15. `calm`, `focus`, `startled` and `caught` are `EXPR` (:69–72), static face poses.
- **`apply(clipName, t)` does not exist.** The rig has `play(pose, clip)` and `set(pose)`; a clip's `f(t)` returns a pose, and `set` reads `performance.now()` for its springs (`P/creature-kit.js:117–118`). The harness must drive it with a fake clock (3d-pipeline.md:186).

The key vocabulary also differs by family. The kit's 15 keys are idle, idle2, walk, run, carry, climb, leap, slide, wade, ability, hit, ko, celebrate, nap and work; §21.6's "knocked out" is `ko`. The Archivist's 10 are idle, read, walk, suspend, reveal, recall, tip, guard, celebrate and catch (`scratch/3dp/out/measure_all.json`). Wildlife has 9 and anomalies 10.

**Proposed action.** Roadmap-amend TD.7. Add to the detail and the gate:
- AnimationPlayer names are the module's `CLIPS` keys, listed per kind in the manifest. The clip check maps §21.6's set onto the kit's keys (`ko` for knocked out) and fails a ruleborn missing any of them.
- Clips are sampled at 30 fps, the simulation's tick rate.
- Every moving node's position, rotation and scale is baked, not only bones.
- `EXPR` poses are exported as separate one-frame animations named `expr_<key>`.
- The harness drives `play(CLIPS[k].f(t), k)` under a fake clock.

Roadmap-amend TD.10: clip choice calls these keys.

**Relates to:** TD.7, TD.10, C54, TD.62.

### A4. The six baked meshes are body caches at the sheets' steps; TD.7 should treat them as test fixtures, never inputs (spec, low)

**Claim.** The handoff ships "a pre-baked mesh (.bin)" for four characters (CHARACTERS.md:8, :17, :18, :29, :41).

- Decoded (`data/bins.jsonl`), each is one body mesh with vertex paint and fur mask: 65,054 to 164,298 triangles, no accessories, eyes, bones or clips.
- Four have no skin weights at all (`featherkin.bin`, `mossbear.bin`, `archivist-hero.bin`, `skyskipper-hero.bin`).
- Three equal the analysis's live builds at the same step to the triangle:

| File | Live build (census) | Bin |
|---|---|---|
| featherkin.bin | 80,828 | 80,828 |
| mossbear.bin | 134,174 | 134,174 |
| archivist-hero.bin | 164,298 | 164,298 |

- `skyskipper-game.bin` does not: 65,054 against 66,668 at .0081. It may predate the current sculpt (`?v=ap2`); either way the page shows a body the code no longer makes.

Nothing in them changes TD.7's plan. TD.7 builds from code at a coarser step per kind, and `loadBaked` is keyed to an exact step (`'g'+res`, `P/creature-kit.js:57`).

**Proposed action.** Roadmap-amend TD.7. Add: "The handoff's six `.bin` files are body-only meshing caches at the sheets' steps (65,000 to 164,000 triangles). They are not imported. The harness never calls `loadBaked`. Its first check meshes Featherkin at .0078, Mossbear at .009 and the Archivist at .0072 and must reproduce the bins' triangle counts (80,828, 134,174, 164,298), proving it meshes as the designer's pages do. Skyskipper's game bin differs from the code (65,054 against 66,668 at .0081), so the code is the source."

**Relates to:** TD.7, G61, D93.

### A5. G61 and 3d-pipeline.md say no mesh file exists; the handoff has six (stale, medium)

**Claim.** G61's body: "No model file exists." 3d-pipeline.md:109: "The modules reference `.bin` files of pre-baked meshes (`BIN`), but no `.bin` is in the bundle, so every page meshes its creature live." That was true of the published artifact. The handoff ships `archivist-game.bin`, `archivist-hero.bin`, `featherkin.bin`, `mossbear.bin`, `skyskipper-game.bin` and `skyskipper-hero.bin` (`P/`, 21.1 MB). Featherkin's, Mossbear's and both Archivist pages load theirs, and both Skyskipper pages do too. 38 of the 40 `BIN` paths the modules declare are still missing.

The conclusion stands: none is an importable model (A4). Only the wording is out of date.

**Proposed action.** Register-amend G61: replace "No model file exists" with "No importable model exists. The handoff adds six baked body meshes for Featherkin, Mossbear, Skyskipper and the Archivist, in the kit's own binary layout (body, vertex paint, fur mask, and skin weights in two of them), with no accessories, rig or clips, at the sheets' steps." Analysis-correct 3d-pipeline.md:109 the same way.

**Relates to:** G61, TD.7, 3d-pipeline.md §3.2 item 9.

### A6. Skyskipper and the Archivist are taller than v3.6 says, and D94's heights row omits both (missed, medium)

**Claim.** The census left both heights blank ("-", census_table.md rows skyskipper and archivist) because neither module exports `GAME_SCALE`. Their Rig pages set the game scale by hand.

- **Skyskipper**, scaled 0.8 (`P/Skyskipper Rig.html:85`): body 1.152 units in `skyskipper-game.bin`, so 0.92 m; whole idle model 1.2 units (`scratch/3dp/out/measure_all.json`), so 0.96 m. §21.6: "Long-eared hopper with a big satchel, 0.8 m" (v36:10675). That is 15–20% tall, or more if the ears are left out.
- **Archivist**, scaled 1.25 (`P/Archivist Rig.html:85`): body 1.387 units in `archivist-game.bin`, so 1.73 m; with staff and book 1.784 units, so 2.23 m. §21.1: "Sages about 1.5" (v36:10408). Body 16% tall.

The Sages now run 0.97 m (Tinkerer) to 1.73 m (Archivist) against one stated height. These are bounding boxes in the sculpt pose, before the rig's A-pose straightening, so treat them as within a few percent.

**Proposed action.** Register-amend D94, Height row: add "Skyskipper 0.92–0.96 m at its Rig page's 0.8 against 0.8 m; the Archivist 1.73 m (body) at its Rig page's 1.25 against Sages 'about 1.5'". Analysis-correct census_table.md and 3d-pipeline.md §3.3: fill the two heights from the Rig pages' scales. TD.7's 5% gate already catches both.

**Relates to:** D94, TD.7, 3d-pipeline.md finding 5.

### A7. The census's Skyskipper "hero" row is the Rig page's step, not the Hero page's (stale, low)

**Claim.** census_table.md gives Skyskipper's hero build as 177,568 triangles (66,668 body) at step 0.0081. The Hero page meshes at .0072 (`P/Skyskipper Hero.html:54, 69`), and its baked body there is 83,640 triangles, 25% more. The Archivist's Rig page meshes at .0082 (`P/Archivist Rig.html:82`), which the census never measured; its baked body there is 126,666. Both are close-up figures for D93's option D.

**Proposed action.** Analysis-correct census_table.md and 3d-pipeline.md §3.3. Mark Skyskipper's row as measured at the Rig page's step and add the Hero page's body, 83,640 at .0072. Add the Archivist's Rig-page body, 126,666 at .0082. Brief D93's "today" may quote 83,640 as Skyskipper's close-up body.

**Relates to:** D93, census_table.md.

### A8. TD.32 says Verdant has "no bees"; the design has bees on a Flock puffball (stale, low)

**Claim.** TD.32's detail says "Verdant has no bees or butterflies (§5.7)" (`tools/roadmap.py:1516`). The handoff's Verdant row is "Puffballs and bees | puffbee.js, puffball-base.js" (CHARACTERS.md:78): the Flock law's puffball sculpt with two orbiting bees (characters.md:176). §5.7 gives puffballs to the Flock law alone and makes Verdant "bees and butterflies" (v36:1136, 11634). So the design has the bees, uses a creature it must not, and lacks the butterflies.

**Proposed action.** Roadmap-amend TD.32: "Verdant's sheet is the Flock's puffball with two bees (puffbee.js); §5.7 gives puffballs to the Flock alone, so Verdant keeps the bees, drops the puffball and gains butterflies."

**Relates to:** TD.32, G65, characters.md finding 13.

### A9. No task records the fate of the handoff's 2D renders; the six top-level world PNGs are orphans (spec, low)

**Claim.** `prototype/world/` holds 44 PNGs:
- 24 portraits, 6 `land/`, 4 `scout/` and 4 `obs/`, all used by the screens;
- six top-level pictures (`heist`, `home`, `landing`, `realm`, `result`, `workshop`) that nothing uses. They are absent from the screen index's 223 dependencies and from README:209's list.

The six are screenshots of earlier versions of screens 01, 02, 04, 07, 22/25 and 23, with UI labels and chibi stand-ins baked in (section 4). README:209 says the world renders "can be used as is". D92 notes the portraits, Observatory, scout and landing pictures are renders of the physically based look, but TD.11 re-renders only the portraits, and no task names the `land/`, `scout/` or `obs/` pictures or excludes the six orphans.

**Proposed action.** Roadmap-amend TD.7: the manifest lists every handoff image with its fate.
- Portraits, `land/`, `scout/` and `obs/` are re-rendered from imported models in the look D92 decides (TD.11 for portraits; the same step for the 14 others), or kept as they are only if D92's answer is B.
- The six top-level `world/*.png` are not imported.

**Relates to:** D92, TD.11, TD.7.

## 7. Coverage

| Item | Status |
|---|---|
| CHARACTERS.md:3 "43 characters, grouped as in the GDD" | agrees in count; §21.9 budgets 31 at launch: covered by characters.md finding 13 |
| :4–7 five files each, sheet modes | agrees (45 .dc.html = 43 + 2 index pages; 43 Hero; 43 Rig); prototype only |
| :8 "For four of them, a pre-baked mesh (.bin)" | agrees (4 characters, 6 files); new finding A4, A5 |
| :10 sheets open from the Characters tab | prototype only; nothing to do |
| :15–34 the 18 kinds' school and role | agree with §11.2, all 18 (table 2.1) |
| :17, 18, 29 bin modules for Featherkin, Skyskipper, Mossbear | new finding A4, A5, A6 |
| :36 creature-kit.js and creature-parts.js | covered by G61, 3d-pipeline.md §3.2 |
| :41 Archivist, start, with bins | agrees with §11.7; bins new finding A4, A6 |
| :42–44 Tinkerer 7, Gardener 13, Wanderer 20 | agree with §11.7 |
| :45–46 Chronicler (Time), Lamplighter (Energy), after launch | agree with §11.7; looks covered by G65 |
| :48 sage-kit.js | prototype only; covered by 3d-pipeline.md §3.2 |
| :51–53 paradox-born from Reversal, Twin suns, Unmaking | agree with §11.8; content gap covered by G63 |
| :56 Cartographer sells scouting maps | agrees with §11.8 |
| :57 Collector swaps pages | agrees with §11.8 |
| :58 The Stray joins after a favour, `stray.js` | favour agrees; its own model is covered by characters.md:60, :151, G63, G64, §23.5 row (v36:11612) |
| :61–63 anomalies, version 1.1 | agree with §11.8, §17.3; variants covered by D95 |
| :66 Puffball flock | agrees (after launch, v36:3324); covered by D94, D95, §23.5 row |
| :67 Swarmlings | agrees (after launch, v36:3448); covered by D94 (role), D95 |
| :68 Illusory guards | agrees (after launch, v36:3696); covered by D94, D95 |
| :73 Heart, lantern moths | agrees (v36:986–987) |
| :74 Skyfield, sky-drifting jellyfish | agrees (v36:1009–1010) |
| :75 Crystalline, prism beetles | agrees (v36:1032–1033) |
| :76 Tidehold, slow-swimming lanternfish | agrees (v36:1055–1056) |
| :77 Emberreach, ash moths | agrees (v36:1078–1079) |
| :78 Verdant, puffballs and bees | contradicts v36:1102, 1136, 11634: covered by characters.md:176, :297–302 and TD.32; TD.32 wording is new finding A8 |
| :79 Lantern Vale, fireflies and moths | agrees (v36:1124–1125); the eye-spot cue is covered by characters.md:301 |
| :82 `build(opts)`, res 0.011–0.019 | agrees with the diorama (:586) and census; covered by D93 |
| :83 `makeRig` returns `apply(clipName, t)` | wrong (the rig has `play` and `set`); new finding A3 |
| :84 `CLIPS`; Tidewalker's nine | mixes CLIPS and EXPR; new finding A3 |
| :85 `EXPR` | covered by 3d-pipeline.md §3.2; export detail in A3 |
| :86 `BIN`, `RES` | 38 of 40 declared bins absent; new finding A5 |
| :89 diorama loads characters with `heroLoad` | inaccurate (gated by `RB_HEROES`, six kinds only); already stated in 3d-pipeline.md:69; nothing new |
| :90 Character screen shows the Rig page | covered by D93 (close-up model) |
| :91 roster uses `world/portraits/` | covered by D92, TD.11 (re-render); fate of the other renders new finding A9 |
| :93 Godot 4.7.2 | covered by D76 |
| :94 GLTFExporter mapped, not wired | agrees (43 of 43 Rig pages map it, none calls it); covered by G61 |
| :95 build and makeRig | covered by TD.7 |
| :96 sample each clip at 30 fps (bone quaternions, positions, morphs) | new finding A3 |
| :97 export binary .glb | covered by TD.7 |
| :98 AnimationPlayer names = CLIPS keys, `play("caught")` | new finding A3 |
| :99 soft lambert, rim light, no black outline, school colours | new finding A1; school colours are the intent part's (D89, D91) |
| :100 about 1.2 grid tiles tall | new finding A2 |
| archivist-game.bin | measured (3.2); new findings A4, A6 |
| archivist-hero.bin | measured; identical to census; A4, A7 |
| featherkin.bin | measured; identical to census; height agrees; A4 |
| mossbear.bin | measured; identical to census; height agrees; A4 |
| skyskipper-game.bin | measured; differs from live build; A4, A6 |
| skyskipper-hero.bin | measured; A7 |
| bins against §21.3 budgets | covered by D93 |
| world/heist.png | viewed; orphan render of screen 02; A9 |
| world/home.png | viewed; orphan render of screen 01; A9 |
| world/landing.png | viewed; orphan render of screen 23; "25% heard" agrees with §5.4; A9 |
| world/realm.png | viewed; orphan render of screen 04; A9 |
| world/result.png | viewed; orphan render of screen 07's backdrop; A9 |
| world/workshop.png | viewed; orphan render of an earlier screen 22/25; A9 |
| three.core.js | byte-identical to npm three@0.184.0; covered (3d-pipeline.md:8, TD.7) |
| three.module.js | byte-identical to npm 0.184.0; diorama fallback only; covered |
| three-global.js | r184 classic bundle for the screen index; prototype only |
| three-shim.js | import-map shim; prototype only |
