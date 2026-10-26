# The 3D sources of Screens v3

These are the owner's design files, unpacked unchanged from the Screens v3 bundle (the "Mobile game design screens" artifact). They are the source the client's 3D is built from, not shipped code: the export harness runs them headless and writes Godot assets, and the screens are judged against the stills.

| Folder | What it holds |
|---|---|
| `creatures/` | The 43 character modules and their shared kits: `creature-kit.js` (SDF clay sculpt → surface nets → painted, occlusion-baked vertex colour → fur shells → skinned rig and the standard clips), `creature-parts.js` (eyes, paws, ears), `sage-kit.js`, `moth-base.js`, `puffball-base.js`, and the separate sculpt and rig files of Skyskipper and the Archivist. File names are the ones the modules import (`./creature-kit.js`); they import `three` (r184). |
| `pages/` | Each character's sheet (`*_dc.html`), hero view (`*_Hero.html`) and rig page (`*_Rig.html`, where the forms are drawn). Data only: they load their scripts from the bundle runtime, which is not kept. |
| `diorama/realm-diorama.js` | The `<realm-diorama>` element: island, terrain features, buildings, links, skiffs, sky and law effects for every 3D screen (home, realm, scout, curation, rehearsal, terrain editor, planner, landing, heist). |
| `diorama/` (the rest) | The icon set (`icons.js`), school marks (`school-marks.js`), the design data the screens read (`ruleborn-data.js`) and the art loader (`rb-art.js`). |
| `stills/` | The design's rendered targets: `scout/` and `land/` realms, `obs/` other players' islands, `portraits/` 24 characters. |
| `screens/` | The two screen files: `Ruleborn.dc.html` (screens 01–09 and 22, unpacked from the bundle's `_template.json`) and `RulebornMeta.dc.html` (10–27, which the first mounts in its phone), with `support.js` (the bundle runtime that renders them), `three-shim.js` and the fonts under their bundle ids. `node tools/art/render_screens.mjs` serves them with the rest of this folder and React/three from npm, and writes `stills/screens/`. |
| `stills/screens/` | Every screen's phone frame (390 × 844 at 2x), one PNG per screen plus a few tab or sheet states: the targets the Godot screens are compared against. |

`docs/analysis/screens-v3/3d-pipeline.md` measures all of this and sets out how it reaches Godot; `docs/art/3d-program.md` is the plan being worked.

Not kept: three.js and React (fetched from npm: three 0.184.0, react and react-dom 18.3.1).
