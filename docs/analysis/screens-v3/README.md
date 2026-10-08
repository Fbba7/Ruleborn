# Screens v3 against v3.6 and the build

The owner's designs — Screens v3, made in Claude Design: 28 screens, 43 character
and creature sheets with 3D models, 393 icons — read against design document
v3.6 and against what this repository has built, so the client can be built on
them. v3.6 §23.5 records the designs and sets the rule this reading applies:
the document wins wherever it states a rule, a number or a piece of text; where
it is silent and a design breaks no rule, the design is adopted; a design never
adds a mechanic.

The plan that came out of it is the roadmap's stage **SD**, and the findings are
the register's **v3.6 layer** (`tools/audit_register.py`). This folder keeps the
reading itself, so a task in stage SD can start from what was found rather than
read the designs again.

## How it was read

- **The designs**, unpacked from the artifact the owner shared (a bundled
  Claude Design page: two screen modules with their markup, a data module, an
  icon library, a three.js realm diorama, 43 character pages with their sculpt
  and rig modules, and world images), and rendered in headless Chromium: every
  screen at phone size with its text, and the character sheets with their 3D
  models.
- **Twelve readers**, each with one part: eight screen groups, the design
  system, the 3D and art, the character sheets, v3.6's rule changes, plus the
  register and roadmap mapping. Each wrote the report in this folder named for
  its part, and listed the findings it thought belonged in the register.
- **Every finding was then tried by an adversarial verifier** told to refute it
  from the document, the design source and the build, and to default to "not
  real" when it could not confirm it. 232 findings were proposed and 221
  stood (193 from the screen, design-system, 3D and character readers, 28 from
  the rules and plan readers), each with the verifier's reason and, where it
  mattered, its correction (`data/findings-confirmed*.json`; ten of the
  eleven dropped, and why, in `data/findings-dropped.json` — the eleventh, on
  two wildlife cues, is in `v36-rules.md`). The register's v3.6
  layer is drafted from these, grouped so that one entry holds one problem.
- **The engine move** was measured, not read: Godot 4.7.2 and godot-rust's 4.7
  API on a copy of the client (`engine.md`).

Paths in the reports that began with a scratch directory now read `scratch/`
(work files not kept) or `data/` (the few kept here).

## The reports

| File | Part |
| --- | --- |
| `screens-home-realm-shell.md` | Universe map, realm view, the navigation shell |
| `screens-weave-law-codex-harmony.md` | Weaving, law card, Codex, Harmony view |
| `screens-observatory-scout-landing-planner.md` | Observatory, scout report, landing picker, planner |
| `screens-heist-result.md` | Heist and result |
| `screens-roster-character-sages-forms.md` | Roster, Character, Sage hall, Forms album |
| `screens-lab-curation-rehearsal-terrain-workshop.md` | Resonance Lab, curation, rehearsal and defence log, terrain editor, Workshop |
| `screens-season-shop-share-friends-stats.md` | Season, Shop, Share sheet, Friends, Profile and stats |
| `screens-settings-first.md` | Settings and wellbeing, first launch |
| `design-system.md` | Tokens, typefaces, materials, motion, icons, contrast (1,049 text runs measured) |
| `3d-pipeline.md` | The diorama and the creature kit; an export pipeline proved on one creature |
| `characters.md` | The 43 sheets against §11 and §21.6 |
| `v36-rules.md` | v3.6's rule changes against the build and the register, and v3.6 against itself |
| `register-roadmap.md` | The register, the roadmap and completion against all of the above |
| `engine.md` | The engine move, measured |

## The data

| File | What |
| --- | --- |
| `data/findings-confirmed.json`, `data/findings-confirmed-late.json` | Every finding that stood, with the verifier's reason and correction |
| `data/findings-dropped.json` | The ten that did not, and why |
| `data/tokens.proposed.json` | The design's tokens beside the document's values, each with its source |
| `data/contrast.md`, `data/pairs.md` | Contrast measured from rendered pixels, by screen and by colour pair |
| `data/census_table.md`, `data/measure_all.json`, `data/heights.json`, `data/kit.json`, `data/diorama_probe.json` | Triangles, draw calls, meshes and heights of every creature, kit piece and diorama view |
