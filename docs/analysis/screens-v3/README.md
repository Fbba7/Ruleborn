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

## The owner's handoff

After this reading the owner handed over the design itself, `design_handoff_ruleborn`:
the prototype the artifact was bundled from, four documents of the owner's own (the
build instructions in `README.md`, the screen list in `SCREENS.md`, the character
notes in `CHARACTERS.md`, and `docs/ruleborn-screen-review.md`, the fix brief the
screens were redone from), six baked meshes and six world images. Six readers read
it against the repository, and a verifier tried every finding. The results are in
[`handoff/README.md`](handoff/README.md), with the readers' reports beside it and
the owner's four documents, unchanged, in `handoff/source/`.

What it added:

- **Proof that the screens read here are the handoff's screens**, apart from one
  notes row beside the phone frame (`handoff/diff.md`). Every finding below still
  holds for the handoff.
- **The owner's statements of intent**, recorded as context on open entries in the
  decision brief. None is an answer; §23.5 still decides where the document wins.
- **What the first reading could not see**: four new decisions (landscape at
  launch, the 390-point frame, D75's camera and gestures, and which raids open a
  Trace), new register items in the v3.6 layer, and amendments to stage SD,
  including a task for sound and haptics, which had none. Folding them in found
  two more decisions, each v3.6 against itself: C56, where §14.9 and §18.4 put
  the second epoch's extra slot in different places, and C57, where §12.6 draws
  every visible guard's cone and §21.12 one at a time.
- **Corrections to this folder**: the crack ring is no longer adoptable while
  F35's answer stands (`screens-heist-result.md` §1.5, `register-roadmap.md`'s F35
  row); the Friends note (`screens-season-shop-share-friends-stats.md` §4.3); the
  scout report's landing and matchups (`screens-observatory-scout-landing-planner.md`
  §3.3 and §3.5); the baked meshes (`3d-pipeline.md` and `data/census_table.md`);
  and the line map below.

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

## Sources and line map

The designs were read from the artifact the owner published, unpacked under the
artifact's own file names. The handoff's `prototype/` is the source the build works
from, and it is proven the same (`handoff/diff.md`). Every file the screens load is
byte-identical. The two screen files hold the same content, except one row of the
index's side-panel notes, the Friends entry (`Ruleborn Screens v3.dc.html:908`),
which is not drawn in the phone. The data module is one file in both,
`ruleborn-data.js` in the handoff, sha256
`a184ffa231821559b3f5c73151a592a8601dd15d18aa40e4a16d018a7b6bb70d`.

The reports here, the register and the brief cite the artifact's names; several
hundred citations do. To find a cited line in the handoff's `prototype/`:

| Cited as | In the handoff's `prototype/` |
| --- | --- |
| `screens_main.js:N` | `Ruleborn Screens v3.dc.html:N+840` |
| `screens_main.markup.html:N`, for N ≥ 311 | `Ruleborn Screens v3.dc.html:N−75`. The same content, not byte-equal: the bundler wrote `sc-camel-*` attributes, `</stop>` and `</path>` closing tags, comment anchors and UUID asset URLs. Lines 1–310 are the artifact's inlined fonts and have no counterpart |
| `screens_meta.js:N` | `RulebornMeta.dc.html:N+648` |
| `screens_meta.markup.html:N`, or "markup N" in the meta reports | `RulebornMeta.dc.html:N+8` |
| `realm_diorama.js` | `realm-diorama.js` |
| `data_v35.js` | `ruleborn-data.js` |
| `icons_rbi.js` | `ruleborn-icons.js` |
| `icons_schools.js` | `law-glyphs.js` |
| `art_loader.js` | `rb-art.js` |
| `creatures/<Name>_Rig.html`, `_Hero.html`, `_dc.html` | `<Name> Rig.html`, `<Name> Hero.html`, `<Name>.dc.html` |
| `creatures/creature_kit.js` and the other snake_case modules | the same names in kebab-case (`creature-kit.js`), at the top of `prototype/`; `react_production_min.js` becomes `react.production.min.js` |
| `images/world_<dir>_<name>.png` | `world/<dir>/<name>.png` |

The owner's four documents are cited by line, in `handoff/source/`. SCREENS.md's
must-show lists are compared with §23.2 row by row in `handoff/intent.md` (its
section "SCREENS.md 'Must show' against v3.6 §23.2"), each difference mapped to the
item that holds it.

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
| [`handoff/README.md`](handoff/README.md) | The owner's handoff against the plan, with its six reports, its sources and its data |

## The data

| File | What |
| --- | --- |
| `data/findings-confirmed.json`, `data/findings-confirmed-late.json` | Every finding that stood, with the verifier's reason and correction |
| `data/findings-dropped.json` | The ten that did not, and why |
| `data/tokens.proposed.json` | The design's tokens beside the document's values, each with its source |
| `data/contrast.md`, `data/pairs.md` | Contrast measured from rendered pixels, by screen and by colour pair |
| `data/census_table.md`, `data/measure_all.json`, `data/heights.json`, `data/kit.json`, `data/diorama_probe.json` | Triangles, draw calls, meshes and heights of every creature, kit piece and diorama view |
