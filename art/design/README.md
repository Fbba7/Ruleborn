# The 3D sources of Screens v3

These are the owner's design files, unpacked unchanged from the Screens v3 bundle (the "Mobile game design screens" artifact). They are the source the client's 3D is built from, not shipped code: the export harness runs them headless and writes Godot assets, and the screens are judged against the stills.

| Folder | What it holds |
|---|---|
| `creatures/` | The 43 character modules and their shared kits: `creature-kit.js` (SDF clay sculpt → surface nets → painted, occlusion-baked vertex colour → fur shells → skinned rig and the standard clips), `creature-parts.js` (eyes, paws, ears), `sage-kit.js`, `moth-base.js`, `puffball-base.js`, and the separate sculpt and rig files of Skyskipper and the Archivist. File names are the ones the modules import (`./creature-kit.js`); they import `three` (r184). |
| `pages/` | Each character's sheet (`*_dc.html`), hero view (`*_Hero.html`) and rig page (`*_Rig.html`, where the forms are drawn). Data only: they load their scripts from the bundle runtime, which is not kept. |
| `diorama/realm-diorama.js` | The `<realm-diorama>` element: island, terrain features, buildings, links, skiffs, sky and law effects for every 3D screen (home, realm, scout, curation, rehearsal, terrain editor, planner, landing, heist). |
| `diorama/` (the rest) | The icon set (`icons.js`), school marks (`school-marks.js`), the design data the screens read (`ruleborn-data.js`) and the art loader (`rb-art.js`). |
| `stills/` | The design's rendered targets: `scout/` and `land/` realms, `obs/` other players' islands, `portraits/` 24 characters. |

`docs/analysis/screens-v3/3d-pipeline.md` measures all of this and sets out how it reaches Godot; `docs/art/3d-program.md` is the plan being worked.

Not kept: three.js, React, the fonts and the bundle runtime (all fetched from npm or already in the client).
