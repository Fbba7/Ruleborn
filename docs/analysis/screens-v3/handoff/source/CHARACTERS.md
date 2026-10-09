# Ruleborn characters

There are 43 characters, grouped as in the GDD. Each one has five files:
- `<Name>.dc.html`: the character sheet.
- `<Name> Hero.html`: the close-up 3D hero view.
- `<Name> Rig.html`: the in-game view, turnaround, expressions, forms and silhouette. The sheet picks which one with `?sheet=turn|expr|forms`, `?view=game` or `?sil=1`.
- A model module (`.js`).
- For four of them, a pre-baked mesh (`.bin`).

Everything is in `prototype/`. Open a sheet from the **Characters** tab of the screen index, or directly at `/<Name>.dc.html`.

## Ruleborn (18 kinds: the crew)
The table gives school, role and model module.

| Kind | School | Role | Module |
|---|---|---|---|
| Featherkin | Motion | Scout | featherkin.js (+ featherkin.bin) |
| Skyskipper | Motion | Carrier | skyskipper-sculpt.js, skyskipper-rig.js (+ skyskipper-hero.bin, skyskipper-game.bin) |
| Rambler | Motion | Breaker | rambler.js |
| Glass Golem | Matter | Warden | glassgolem.js |
| Quarryback | Matter | Breaker | quarryback.js |
| Prism Mite | Matter | Carrier | prismmite.js |
| Tidewalker | Time | Carrier | tidewalker.js |
| Hourkeeper | Time | Mender | hourkeeper.js |
| Stillwatch | Time | Warden | stillwatch.js |
| Emberling | Energy | Breaker | emberling.js |
| Stormhound | Energy | Scout | stormhound.js |
| Sparkwright | Energy | Mender | sparkwright.js |
| Mossbear | Life | Warden | mossbear.js (+ mossbear.bin) |
| Bloomling | Life | Mender | bloomling.js |
| Rootrunner | Life | Carrier | rootrunner.js |
| Echoplate | Spirit | Warden | echoplate.js |
| Lantern Wisp | Spirit | Scout | lanternwisp.js |
| Soulmender | Spirit | Mender | soulmender.js |

The shared building blocks are `creature-kit.js` (skinned body builder, bake loader and standard clips) and `creature-parts.js` (eyes, paws, ears and so on).

## Sages (6 heroes)
| Sage | Unlock | Module |
|---|---|---|
| The Archivist | From the start | archivist-sculpt.js, archivist-rig.js (+ archivist-hero.bin, archivist-game.bin) |
| The Tinkerer | Keeper level 7 | tinkerer.js |
| The Gardener | Keeper level 13 | gardener.js |
| The Wanderer | Keeper level 20 | wanderer.js |
| The Chronicler | Time school, after launch | chronicler.js |
| The Lamplighter | Energy school, after launch | lamplighter.js |

The Sages share `sage-kit.js`, which covers the humanoid body, robes, hands and faces.

## Paradox-born (3 legendaries)
- The Reverser, from Reversal: `reverser.js`.
- The Twinned, from Twin suns: `twinned.js`.
- The Unmade, from Unmaking: `unmade.js`.

## Visitors (3)
- The Cartographer, who sells scouting maps: `cartographer.js`.
- The Collector, who swaps pages: `collector.js`.
- The Stray, who joins after a favour: `stray.js`.

## Anomalies (3 bosses, version 1.1)
- The Devourer, a drifting black hole: `devourer.js`.
- The Hourglass Storm, which scrambles time: `hourglassstorm.js`.
- The Wildfire Bloom, where fire and growth run wild: `wildfirebloom.js`.

## Law creatures (3, after launch)
- Puffball flock (Flock): `puffballflock.js` and `puffball-base.js`.
- Swarmlings (Swarm birth): `swarmling.js`.
- Illusory guards (Mirror images): `illusoryguard.js`.

## Realm wildlife (7, ambient)
| Realm | Wildlife | Module |
|---|---|---|
| The Heart | Lantern moths | lanternmoth.js, moth-base.js |
| Skyfield | Sky-drifting jellyfish | skyjelly.js |
| Crystalline | Prism beetles | prismbeetle.js |
| Tidehold | Slow-swimming lanternfish | lanternfish.js |
| Emberreach | Ash moths | ashmoth.js |
| Verdant | Puffballs and bees | puffbee.js, puffball-base.js |
| Lantern Vale | Fireflies and moths | valemoth.js |

## What each module exports
- `build(opts)`: builds the mesh source. `opts.res` sets the detail; lower numbers mean more detail, and the in-game views use about 0.011–0.019.
- `makeRig(src)`: returns `{ root, apply(clipName, t), ... }`, which is a skinned rig.
- `CLIPS`: procedural animations; each one is `{ label, len, f(t) }` and returns a pose. Tidewalker has idle, ability, wade, nap, work, calm, focus, startled and caught.
- `EXPR`: expressions (face poses).
- Optionally `BIN` (the pre-baked mesh path) and `RES` (the default detail).

## How the characters appear in the screens
- **Realm view and Heist:** `realm-diorama.js` loads each character with `heroLoad(kind)` and adds it to the island at game scale. Characters load one at a time.
- **Character screen (11):** shows the character's Rig page in the in-game view with the idle clip.
- **Roster and other cards:** use the pre-rendered portraits in `world/portraits/`.

## Moving them to Godot 4.7.2
1. **Export:** `GLTFExporter` is already mapped in every Rig page but isn't wired up yet. For each character:
   - Build it with `build()` and `makeRig()`.
   - Sample each clip at 30 fps into `THREE.AnimationClip` tracks (bone quaternions, positions and morphs).
   - Export a binary `.glb`.
2. **Import:** import the `.glb` into Godot. Keep the `AnimationPlayer` clip names identical to the `CLIPS` keys so gameplay code can call `play("caught")` and so on.
3. **Materials:** match the toon look. Use soft lambert shading with a rim light, no black outline (it was removed at the user's request), and the school colours from the README.
4. **Scale:** match game scale against the island grid. In the prototype a ruleborn is about 1.2 grid tiles tall.
