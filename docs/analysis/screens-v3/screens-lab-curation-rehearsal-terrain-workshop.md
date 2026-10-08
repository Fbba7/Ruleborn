# Resonance Lab, Defence curation, Rehearsal and defence log, Terrain editor, Island Workshop: Screens v3 against v3.6, and the Godot build

Written for the owner. Every claim names where it was read. "Doc" is `docs/design/ruleborn-game-design-v3.6.txt`, cited as §N.M with its line where the words matter. "js" is `art/named/screens_meta.js`, "markup" is `art/named/screens_meta.markup.html`, "diorama" is `art/named/realm_diorama.js`, "icons" is `art/named/icons_schools.js` (all under the scratchpad's `art/named/`). Repository files are cited from the repository root. Register ids (G19, G26, D62, D66, F29, F37 …) are `tools/audit_register.py`'s. My own findings are numbered **LD1–LD24** (section 7) so they do not collide with the other screen reports' F, H, N series.

---

## 0. What was read, and how

- **Doc.** §23.2's five rows (lines 11259, 11263, 11267, 11287, 11299) and §23.5 in full (11383–11600), then every section the rows point at or the designs touch: §5.2 (realm table, 709–770), §5.6 (weaving, 963–967), §6.1–6.2 (terrain, 1150–1550), §7.5 (paradoxes, 2179–2201), §7.6 (page sources, 2221), §7.7 (Slow rivers 2761, Glowing dark 2978, Sleepwalk 3598), §7.10 (launch 24 and the choice-law rule, 3801–3870), §8.4–8.6 (resonances, chords, discovery, 3988–4320), §9.1/§9.5 (Insight, Lab price, 4355–4600), §10.2's Resonance Lab table (5666–5712), §11.7 (Archivist, 6188–6219), §12.3 (Trace, 6932), §12.9 (outcomes, 7072–7110), §12.11 (friendly heists, 7121), §12.17 (guard states, 7255–7275), §13 (defence, rehearsals, 13.1–13.4, 7440–7700), §14.1 (Lab experiments a day, 7702), §14.4 (pages, 8249–8300), §15.2–15.3 (learning map, teaching tools, 8625–8800), §16 (first session, 8855–8875), §18.6–18.7 (Workshop, creators, 9060–9105), §20.2–20.12 (protections, moderation, age bands, publishing limits, 10170–10388), §21.1, §21.5 (Lab's look, 10624), §21.8 (interface, 10986), §21.12 (guard sight, 11082–11094), §25.1 and §27.5 (remix gate, 12131, 13085). The v3.4→v3.6 diff (`scratchpad/v36/diffs.txt`): of my rows only Rehearsal changed, gaining "each with its report (the haul denied, how long the defence held, where the crew was seen, what fired; 13.2)".
- **Design.** Markup blocks: Lab 181–216, curation 217–221, rehearsal and log 222–244, terrain 471–488, Workshop 509–545. Logic: resonance table `rz()` js:9; `lbFinish` js:10–17; curation constants and model js:20–26, 105–151; terrain table `teFT` js:27–67, `teEval` 68–88, `teTap` 89–104; Lab view js:432–505; curation view js:506–588; rehearsal and log js:590–597; terrain view js:1023–1066; Workshop view js:1136–1180. The 3D overlay in `realm_diorama.js:360–480` (defence mode: grid, cones, routes, landing flags, ghost probes, BEST marker) and its tap event (`dcell`, diorama:479). The resonance icon set, icons:39–50.
- **Screenshots** from the shared set (`shots/all/Gameplay_14/15/16/22/25`) and **33 captures of my own** of the states the defaults do not show, made by driving the prototype in headless Chromium (script `analysis/lcrtw_scripts/shoot.mjs`, server `serve.mjs` on port 8877; images and page text in `analysis/lcrtw_shots/`). They are listed in section 10.
- **Build.** `client/` (README, router, app_state, builder, workshop feature, realm view, ui, the extension `client/ext/src/island.rs` and `lib.rs`), `server/src/` (http.mjs's route list, workshop.mjs, universe.mjs, notifications.mjs, service.mjs, db.mjs), `sim/src/` (grid.rs, island.rs, heist.rs, lib.rs, combos.rs), `content/` (terrain.json, resonances.json, buildings.json, laws.json, notes.json), `tools/heist_harness/` (island.py's generator, policy.py's crews), `tools/roadmap.py` (stage SC) and `tools/audit_register.py`.

What I did not do: run the Godot client, or read every one of the 393 icons. The rehearsal map's SVG path and the Workshop's cover images did not render in the headless browser (missing `world/land/*.png`); neither changes the analysis.

---

## 1. What these five screens share, and what is missing under all of them

These five are the defence-and-creation half of the game. Four of them (curation, rehearsal, terrain, Workshop) are views of **one island being edited and judged**, and the Lab is the discovery end of the law system. Most of the cost is below the screens, in the simulation, and it is shared.

| Shared need | Today | What to build |
|---|---|---|
| **The 39 terrain features in the simulation** | `sim/src/grid.rs:116–136` models RockPillar, RuinWall, Fence, FogBank, TallGrass (plus Vault, Pylon, CrystalWall); surfaces Plain, Gravel, Water, Moss (grid.rs:90–96); heights. The extension maps five feature ids plus gravel and stream surfaces and one level of raised ground (`client/ext/src/island.rs:32–41, 130–151`). The README says the builder offers "the eight of §6.2's thirty-nine features the simulation models" (`client/README.md:169`). | The other 31 features with their movement, sight, noise, hide, climb, light and one-way rules (§6.2, `content/terrain.json`), heights 0–3, directions for ramps, stairs, rapids and waterfalls, and a tunnel's two ends (LD16). Each is a rules-version change (§24.11). |
| **Moss as the default ground** | `Island::empty` lays "open, plain, lit ground" (`sim/src/island.rs:248–264`); moss appears only where a fixture puts it (island.rs:750–762, 825). | §6.1 (line 1164): "every realm is raised with moss on each tile that carries no feature, and a Keeper clears it for 1 terrain point a tile". F29 was closed on that decision. LD13. |
| **Terrain points** | Counted nowhere: `Island::check`'s problems are wards, guards, laws, crowding, posts, landing, sealed, edge (island.rs:144–169); the extension's `budget()` has wards, guards and laws only (ext island.rs:207–223); the server checks realm level, not terrain (`server/src/universe.mjs:287`). | `Island::terrain_points()` and a `TooMuchTerrain` problem, with the budget from §6.1 (outer 30 + 15 × realm level; the Heart 40 + 10 × Spire level). The Heart's budget needs the Spire level, which the bundle does not carry (LD15). |
| **The generator, in shipping code** | Only in the Python harness, `tools/heist_harness/island.py:247` (`generate`). D66 already records "Port the reference crews and the generator into the simulation". | A Rust `sim/src/generator.rs`, deterministic by seed, exposed to the client (GDExtension) and the server (WASM): layouts for a realm, re-generation with laws or posts held fixed (§23.2's "re-generating fast"), and §7.10's placement rule for the eight choice laws. Without it §13.3's "every player has a defence from the first minute" has nothing to run on. |
| **Simulated crews** | None in `sim/`. The harness's crews are Careless, Competent, Optimal and Clearing (`tools/heist_harness/policy.py:460–534`). | §13's three rehearsal crews, "cautious, greedy or fast" (line 7479), as command generators in Rust that drive the same `Heist` as a player (LD24). D66 asks for the reference crews too; one module serves both. |
| **A record of what happened** | `Outcome` is grade, banked, capacity, caught, out, pages, cracked, left (`sim/src/heist.rs:146–167`). | Sightings (tick, guard, tile), triggers (ward, bell, law; tick, tile), and when the crew landed and left, so a rehearsal and a raid report can say "where the crew was seen" and "what fired" (§13.2 line 7581). LD22. |
| **Stealth paths** | Nothing. | §13.3 (line 7629): "A layout is validated by counting its feasible stealth paths: fewer is harder." A fast Rust count with the paths themselves. This is exactly the design's "SNEAK ROUTES" (js:124, markup 219), so the design's headline number is the document's own difficulty measure. |
| **A hold figure** | The design invents one with a formula (js:123). The document measures hold over 800 raids or more (§13.2, §13.3). D62: the Workshop publishes without the band check. | A measurement queue on the server keyed by island digest, shared by curation and the Workshop, and the live stealth-path count on the phone. LD10. |
| **Overlays on the realm** | `RealmView` draws flat and top-down from a replay, with one guard's sight (`client/scripts/realm_view.gd:1–40`, `select_guard_near` 278). | An overlay API: routes (unseen in pink, seen in white), the selected post's tiles with hard edges (§21.12), landing flags labelled realm · link (§23.5 "Heart arrivals"), a tile cursor with a refusal flash, ghost probes, a placement hint. The same API on the 3D diorama later (the shell report's `scenes/world/diorama.tscn`). |
| **Words from content, not from the prototype** | `tools/client_strings.py` writes names only (`GROUND_*`, `RES_*`, `LAW_*`). | Feature texts (movement, sight, law line), law rules, resonance effects and the ladder's rewards from `content/`, because the designs restate several of them differently (LD12). |

---

## 2. Resonance Lab

### 2.1 The §23.2 row (line 11259)

> | Resonance Lab | Run experiments. | Two law slots, timer, result, hints, paradox warning

What the rest of the document asks of it:

- **Price and time.** §9.5 (line 4596): "Lab experiment | 400 Aether × Lab level". §10.2 (5666–5712): level 1 "1 slot(s); 8 h per experiment", 2 "1 slot(s); 6.5 h", 3 "2 slot(s); 5 h" (Spire 5, day 42), 4 "2 slot(s); 4 h", 5 "3 slot(s); 3 h". §11.7 (≈6200): the Archivist at home makes "Lab experiments 20% faster".
- **What it finds.** §8.4 (3990): resonances are "hidden until discovered in the Lab, or hinted at after crossing them in someone else's universe"; twelve of the 44 join two launch laws. §8.5 (4219): "The Lab names chords — from level 3 it identifies one the player has woven or crossed — and is a teaching surface, not a lock." §7.5 (2181): paradoxes "found only in the Lab, by combining two tier III laws with opposite notes. Each such experiment has a 10% chance … and the Lab warns when a pairing is 'unstable'. A universe can hold one paradox at a time".
- **What it pays.** §7.6 (2221) and §14.4 (8266): an experiment that finds nothing gives "3 pages of a law from those schools". §9.1 (≈4392): Insight comes from "Lab discoveries"; no amount is stated anywhere.
- **First session.** §16 (8864, 8872): the Archivist suggests Slow rivers and Bloom; "The first experiment takes 5 minutes"; it "names Mangrove banks … with insight pages".
- **Teaching.** §15.2 (8737–8739, 8753): "The first Lab experiment; then Lab hints and crossing one in a heist"; "Lab hints and 'unstable' warnings". §15.3 (8635): "Hints appear only after repeated failure, and every hint is tested before release." §14.1 (7702): an engaged player runs 3 experiments a day.
- **Look.** §21.5 (10624): "A workshop with two glass spheres … Sparks and note-coloured threads between the spheres … A third sphere for chords".

### 2.2 What the design shows (Gameplay_14; captures lab_*)

Top to bottom (markup 181–216, js 432–505):

1. **Laws hub tabs**: All laws | Harmony | Lab (the Laws bottom tab's three screens). A title "Resonance Lab" and a pill with a resonance icon and "2 / 12".
2. **The test chamber**, one card: a "TEST REALM" tag; two round law pedestals on plinths (each the law's glyph in its school colour, its frame by rank, its name), dashed note-coloured links to a central core over a floating mini island with a tree, a house and a sleeping guard ("z"), and two faint sight wedges; a status line; a full-width gold button. States:
   - empty: "Tap two laws below to place them.", button "Place two laws";
   - ready: "Ready. Lab level 3 runs each test in 5 h 30 min.", button "Run the test";
   - running (6 seconds in the prototype, js:436 `lbDUR = 6000`): tag CHARGING → WEAVING → SETTLING, a countdown pill "SETTLES IN 3h 13m", the pedestals bob, particles flow along the links, the core shakes then flashes, the status line narrates three beats of the pair ("A crew member freezes beside him"), the button fills with violet light and reads "Settling…";
   - **NEW**: a burst, the resonance card pops from the core, flips, grows and flies to its shelf slot; the status line gives its effect ("Anyone standing still near a sleeping guard is fully silent."); button "Clear the chamber" (lab_result_known_or_new, lab_result3);
   - **KNOWN**: same without the flight;
   - **NO RESONANCE**: fizz particles; "No resonance. You get 3 pages of a law from these schools, and the pair is marked as tried." (js:464);
   - **A STIR**: "Glass stirred something. No. 04 now shows one of its two laws." with a "Clue found" caption; that locked card now shows half its ring in the law's colour and the law's badge (lab_result2, lab_result4; js:15–16);
   - an "unstable" warning text, "Unstable pairing: two tier III laws with opposite notes. A 10% chance of a paradox." (js:464), which no state of the prototype can reach (2.4).
3. **The tray**: a horizontal strip of every law the player has met (`known = ALL.filter(l => l.pg >= 0)`, js:389; 18 tiles in the capture), each a framed glyph with its name; a "1"/"2" badge on the placed laws, and a "✓" on laws already tried with the law on the first pedestal (js:495–500).
4. **RESONANCES** heading with "Lab level 3 · each test takes 5 h 30 min" (markup 201).
5. **The shelf**: twelve numbered cards in a 4 × 3 grid. Found: parchment, the resonance art, its name. Locked: dark, number, an hourglass "⌛ 5.5h", and the law badges a stir has revealed; while a test runs, cards whose time matches the test's glow ("settle time as the clue", js:453–454). Tapping a found card loads its pair; tapping a locked one says "No. 05 · one named pair, the same for every Keeper" (js:501).
6. **Bottom tab bar** with Laws raised.

Motion: bob, breathe, spin, ping, flash, wave, spark, flip and fly; sounds `collect`, `open`, `tap`.

### 2.3 Numbers and content against the document

- **Time**: 5 h 30 min at level 3 (js:437) against §10.2's 5 h. Listed in §23.5 (line 11540).
- **The twelve resonances** (js:9; icons:39–50). Two are the document's: Drifting echoes (same text) and Mangrove banks (text differs: "slow anyone crossing" against §8.4's "slow crews by a further 20%"). **Ten are not in §8.4 or `content/resonances.json` at all**: Held vigil (Stillness + Sleepwalk), Glass tide (Glass + Slow rivers), Static bloom (Static + Thorns), Frozen fall (Half gravity + Stillness), Whisper chain (Whispers + Echoes), Slipstream (Frictionless + Haste), Ember dark (Glowing dark + Static), Rooted kin (Kinship + Bloom), Hollow stone (Brittle stone + Inward pull), Soul tide (Soul swap + Echoes; §8.4's pair for those two laws is Soul tether, with another effect). The launch twelve, by §7.10's rule ("hold 12 of the 44", line 3854) and recomputed from content, are: Drifting echoes, Mangrove banks, Night runners, Cracked gardens, Pinball, Storm grid, Briar maze, Twin souls, Shattered glass, Soul tether, Honey trap, Northern lights. The icon set draws exactly the design's twelve, so ten real resonances have no icon. Not in §23.5. **LD1.**
- **Pages for nothing found**: 3 (js:464) — matches §7.6 and §14.4.
- **The unstable condition** names the right rule (two tier III laws, opposite notes, 10%).
- **Price**: none shown. §9.5 gives 1,200 Aether at level 3.
- **Slots**: one chamber. §10.2 gives two at level 3.

### 2.4 Must-show

Of §23.2's five: two law slots (the pedestals), the timer (countdown pill) and the result (four outcomes) are drawn. **Hints** are drawn as the design's own mechanic (LD2). **The paradox warning is written but unreachable**: its condition (js:464) only fires when both laws are among Stillness, Half gravity and Bloom with opposite notes, and none of those three carries an opposite of another (`content/laws.json`: Stillness Hush; Half gravity Flow; Bloom Bloom and Hush; opposites in `content/notes.json`: Flow–Weight, Glow–Hush, Bloom–Spark, Echo–Veil). It also never checks tier III. So no state of the prototype shows it; the build computes it from tiers and notes.

Rules the design omits (not §23.2 must-shows, but the document's rules for this screen): the price (§9.5), the second slot (§10.2), the Archivist's 20% (§11.7), chord naming from level 3 (§8.5), the paradox found and the one-paradox limit (§7.5), what a discovery pays in Insight (§9.1; amount unstated), the first experiment's 5 minutes (§16).

### 2.5 Deviations

| What | Design shows | Document says | Section | In §23.5? |
|---|---|---|---|---|
| Experiment time | 5 h 30 min at Lab 3 | 5 h | §10.2 | Yes |
| The shelf's resonances | 10 of 12 invented (js:9), with icons (icons:39–50) | The twelve of §8.4 whose laws both ship at launch | §8.4, §7.10 | No — LD1 |
| Hints | A failed pair reveals one law of an undiscovered resonance on the first failure; matching settle times highlight candidates | "Lab hints" named, not defined; hints only after repeated failure | §15.2, §15.3, §8.6 | No — LD2 |
| Settle time per resonance | Each card has its own time (all 5.5 h here), used as a clue | One duration per Lab level | §10.2 | No — part of LD2 |
| Slots | One chamber | 2 slots at level 3, 3 at level 5 | §10.2 | No — LD3 |
| Price | None | 400 Aether × Lab level | §9.5 | No — LD3 |
| Archivist at home | Not applied | Experiments 20% faster | §11.7 | No — LD3 |
| Chords | Absent | Named from Lab level 3; §21.5's third sphere | §8.5, §8.6, §21.5 | No — LD4 |
| Paradox found | No state | 10% from unstable pairs; one per universe | §7.5 | No — LD5 |
| Which laws may be placed | Every law met (`pg >= 0`), restored or not | Silent; paradoxes need tier III, so tiers matter | §7.5 | No — LD5 |
| Mangrove banks text | "slow anyone crossing" | "slow crews by a further 20%" | §8.4 | No (the Codex report notes it) — LD12 |
| Text size | 8–11 px labels | 13 pt floor, 16 pt body | §21.8 | Yes |
| "Coming in a later turn" | TRY note | §23.2 is the must-show list | §23.2 | Yes |

### 2.6 Adoptable as it stands (document silent, no rule broken)

The Laws hub tabs; the found counter; the chamber as the screen's hero (it is §21.5's "two glass spheres … note-coloured threads", seen from inside); the three-phase run animation and the status line that narrates the pair; the NEW / KNOWN / NO RESONANCE tags and "Clear the chamber"; the tray with placement badges and the ✓ for pairs already tried (the player's own history, nothing new revealed); the shelf as a numbered grid of found and locked cards; loading a found pair by tapping its card; the line "one named pair, the same for every Keeper"; the flip-and-fly to the shelf (§21.8: "rewards fly into their counter"), shortened under reduced motion.

### 2.7 Does it add a mechanic?

Yes: the stir hint (what a player can see about an undiscovered resonance, and when), the settle-time clue, and ten resonance effects. None is built until the document writes it (§23.5's rule).

### 2.8 What the build has today

- **Client**: nothing. No route in `client/app/router.gd:7–21`. The builder names an island's resonances and chords to its owner whatever has been discovered (`client/scripts/builder_screen.gd:209–221`, from `RulebornIsland.combos()`, `client/ext/src/island.rs:232–252`); once a Lab exists that line must hide what is undiscovered, or the builder becomes the free Lab.
- **Server**: the Lab can be built and raised as a building (`server/src/universe.mjs:30` reads `content/buildings.json`, whose `resonance_lab` row carries §10.2's five levels). No Lab routes, no Aether, no Insight, no pages ledger, no discovery table (`server/src/http.mjs:5–99`).
- **Sim**: `sim/src/combos.rs` knows which resonances and chords sound in one realm; `content/resonances.json` holds all 44.

### 2.9 Server needs

1. **A Lab service** (`server/src/lab.mjs`), tables `lab_experiments(id, account, slot, law_a, law_b, started_at, ends_at, outcome, collected_at)` and `lab_tried(account, pair)`, sharing the Codex report's `discovery(account, kind, id, state, at, via)`:
   - `GET /v1/lab` → `{level, slots: [{slot, a, b, startedAt, endsAt, state}], price, seconds, tried, found, hinted, paradox: {held}}` with `seconds` = §10.2's hours × (0.8 if the Archivist is at home).
   - `POST /v1/lab/experiments {a, b}` → refuses `lab_not_built`, `slot_busy`, `law_not_owned` (LD5's rule), `same_law`, `not_enough_aether`; charges 400 × level from the Aether ledger; draws the outcome at start from a stored seed (so a reinstall cannot re-roll it).
   - `POST /v1/lab/experiments/:id/collect` → after `endsAt`: new resonance (discovery row, Insight per LD5), known, nothing (3 pages to the law LD5's rule picks), paradox (10% when both laws are tier III with opposite notes and the universe holds none).
   - Chord naming at level 3 (LD4's rule, once written).
2. **Ledgers** this rests on: Aether (the Weaving report's need too), Insight, pages per law (the Codex service).
3. **A notification kind** `lab` ("an experiment finished"), held by §20.2's night hours and G34's one message a day (`server/src/notifications.mjs` has `raided` and `reminder`).
4. **Telemetry**: an `experiment` event (pair, outcome, level).

### 2.10 Plan for the Godot build

Engine: Godot 4.7.2 and gdext `api-4-7` per §24's engine row, moved before the new screens (the shell report's step 9).

1. **Data**: `client/data/repositories/lab_repository.gd` (`state()`, `start(a, b)`, `collect(id)`), each a `Result` with the server's refusal code; codes get words in `core/errors.gd` and `i18n/strings.csv` (the contract check, `tools/client_contract.py`, enforces both).
2. **Store**: a `lab` slice (`features/lab/lab_state.gd`): level, slots, price, seconds, tried, found, hinted, paradox, the server-clock offset, busy, error. Reducers `lab_loaded`, `lab_started`, `lab_collected`, `lab_failed`.
3. **Controller** (`features/lab/lab_controller.gd`, on Services so a run in flight survives leaving the screen): load on entry; start; collect when a slot's `endsAt` passes while the screen is open; otherwise on next entry. No polling loop.
4. **Presenter** (`features/lab/lab_presenter.gd`, no nodes, tested headless): from the `lab`, `codex` and law-table slices it produces the pedestals (law, glyph, school, frame), the slot strip (one chamber per slot; a locked one says the level that opens it), the tray (laws the rule allows, each marked placed or tried-with-the-anchor), the shelf (the twelve launch resonances from `content/resonances.json` via the extension's law table, found / hinted / hidden, and per school how many remain, §8.6), the status line (ready; settling with the time left; the four results; the unstable warning computed from tiers and notes), and the button ("Run the test · 1,200 Aether", "Need 340 more Aether", "Both slots busy"). Words from content (`RESFX_*`), never from the prototype.
5. **Screen**: `scenes/lab.tscn` + `scripts/lab_screen.gd`, mounted under the Laws hub tabs (`HubTabs`, shell report). Components: `LawGem` (the pedestal; also used by the Codex and Weaving), `CountdownPill`, `ResonanceCard` (found / hinted / hidden; 87 × 76 pt at the design's ratio, text at 13 pt minimum, §21.8), `ChamberView` (2D: two gems, a core, `Line2D` links in note colours, `GPUParticles2D` or `CPUParticles2D` sparks). The chamber is 2D; no 3D is needed. A third sphere appears at level 3 for chords (§21.5).
6. **Motion**: one `Tween` sequence for charge, weave and settle (only while the screen is open; a real run lasts hours, so the chamber shows "settles in" and the phases play when a result is collected); discovery is pop, flip and fly to the shelf slot (`Tween` on a ghost `Control` at the slot's global rect); reduced motion fades instead (§21.8). Haptics: the success pattern on a discovery (`app/haptics.gd`).
7. **Fix in the builder**: `BuilderScreen.together()` names only discovered resonances and chords.
8. **Tests**: presenter (price by level, time with the Archivist, slots by level, unstable only for two tier III laws with opposite notes, shelf counts per school, tray rule), controller against `FakeTransport` (start, refusal, collect), the layout and pseudo-locale checks (`tests/a11y_tests.gd`).

### 2.11 Effort

L. Depends on the Codex service (law ownership, tiers, discovery), the Aether and Insight ledgers, `HubTabs`, and the owner's answers to LD2–LD5.

---

## 3. Defence curation

### 3.1 The §23.2 row (line 11263)

> | Defence curation | Make the generated defence your own. | The generated layout and its alternatives; swap a law, move a post, pick another layout, name it (13.3); change this one law: swap or re-place any single law the generator chose, with the preview re-generating fast enough not to break the flow

What the rest of the document asks: §13.3 (7605–7640): every player has a generated defence "built to hold within its realm level's generated band"; "Curation is the default creative act. Swap a law, move a post, pick a different generated layout, name it"; the generator weaves "only the ones that help the defender"; cover never on the shortest route; guards and wards by visibility decomposition; "Never seal the route"; "Difficulty is counted, not guessed … counting its feasible stealth paths". §7.10 (3869): "an owner can change any one law's choice on the curation screen (23.2)". §7.7's Slow rivers sheet (2761): "The owner can draw streams on the realm's grid". §13.2: bands by origin; "Every island is tagged with its origin, so the matchmaker holds it to the right band (12.22)". §5.6 (963–967): weaving takes 10 minutes at tier I and costs 40 Aether per stability point; a removed law's slot rests an hour. §21.12 (11082–11094): one guard's vision at a time, sharp edges, no gradients.

### 3.2 What the design shows (Gameplay_15; captures cu_*)

Full-screen 3D island (`realm-diorama mode="scout" realm="heart"` with a `defence` JSON, markup 219), with over it:

1. **Header**: back; a name plate "YOUR DEFENCE · THE HEART / Quiet Garden" with an edit mark; **SAVE** (gold when the defence is savable, "✓ SAVED" after).
2. **Hold strip**: a Warden medallion, "HOLDS 38%" with a delta ("+6"), a band bar with the fair band in green, a gold diamond marker and a faint marker at the previous value, "In the fair band · 30–45%" (red text when outside); "3 SNEAK ROUTES".
3. **The island**: a 9 × 9 grid (eight corner tiles void), houses, the Spire, trees, a river; **pink tubes with chevrons** for routes a crew can take unseen and white dotted ones for routes that are seen (with "✦ REACHED THE VAULT" pins); four landing flags labelled "⇢ Sky", "⇢ Tide", "⇢ Rift", "⇢ Rope"; "VAULT" with a light beam; "POST 1", "2" pins with facing chevrons; the selected post's cone bright, the other faint (diorama 384–409).
4. **Message line**: narrates every edit ("Tight vault layout · holds 38% → 32%", "Post 1 turned · hold unchanged", "Swapped Stillness for Glowing dark · sneak routes 3 → 2 · holds 38% → 54%"; js:126–131).
5. **TEST RUN** round button: raiders land at every edge; ghost probes run each route at once; the first seen probe flashes its post's cone red; result "Seen by Post 1 3 tiles from landing Sky. The defence holds." or "Reached the Vault unseen from landing Rope. Cover that route." (js:140–151).
6. **Bottom sheet, three tabs**:
   - **Layout**: three cards with an 81-tile mini map each, a name, hold % and routes ("Generated 38% · 3 routes", "Tight vault 32%", "Maze 31% · 4 routes"), "IN USE" on the current one (js:22–25, cu_default, cu_tight).
   - **Laws**: one card per woven law with its rule and "+N% hold", **SWAP** (opens "Replace Stillness with": the other laws with their hold delta, "Sleepwalk −3% hold", "Glowing dark +16% hold"), and for Slow rivers an **Across / Along** choice with its delta (cu_laws, cu_swap, cu_river_across; js:540–546, 579–583).
   - **Posts**: "Post 1 · Watches 3 tiles", "Post 2 · Watches 6 tiles", "Reset posts"; a four-way **facing dial**; "Tap open ground on the island to move Post 1"; a green **"★ BEST"** marker on the tile where moving the selected post most reduces sneak routes while staying in the band (a heat map over every tile, js:513–516; cu_posts, cu_post_turned).
7. **Name sheet**: "NAME YOUR DEFENCE · Raiders see this name when they scout you." Two rows of five words (Quiet, Sunken, Lantern, Drowsy, Mossy × Garden, Vigil, Maze, Keep, Wells; js:523), DONE (cu_name).
8. **Save** refuses with "Every landing needs a way to the Heart" or "Bring the hold inside 30–45% to save" (js:558).

The model under it (js:105–125) is a sight-line toy: posts see a widening cone of 4 tiles (2 under Sleepwalk, plus the 8 tiles around), hedges block, Slow rivers adds a row or column of water that doubles a step's cost, and **hold = the layout's base + 2 × min(3, tiles seen on each landing's cheapest route) + a fixed bonus per law (+3 for a river across)**.

### 3.3 Against the must-show list

All of §23.2's verbs are drawn: the generated layout and two alternatives, swap a law, move a post, pick another layout, name it, and re-place a choice law (Slow rivers across/along). The preview "re-generates" instantly because nothing is generated: the alternatives are three fixed layouts (js:22–25), and a swap re-scores the same layout. So what §23.2 asks for most — a preview that re-generates — is drawn but not demonstrated.

### 3.4 Deviations

| What | Design shows | Document says | Section | In §23.5? |
|---|---|---|---|---|
| Heart arrivals | Sky, Tide, Rift, Rope | The realm and the link: "Skyfield · rope bridge" | §5.3 | Yes |
| Law swap | Instant and free; only a hold delta | A law change is a weave: 10 min at tier I, 40 Aether a point, the slot rests an hour after a removal | §5.6, §13.3 | No — LD7 |
| Post facing | Four-way dial; cones fixed to the chosen side | "Patrols or holds its post"; nothing says the owner sets a facing or a patrol | §12.17 | No — LD8 |
| Saving | Refused outside 30–45% | Generated islands are held to their realm level's band (25–40% at realm level 1); whether a curated defence is generated or authored, and whether it must be in band to save, is unstated | §13.2, §13.3, §12.22 | No — LD9 |
| The hold figure | Instant for every option, from a formula | Hold is measured over 800+ raids; the preview must re-generate fast; nothing gives a fast hold | §13.2–13.4, §23.2 | No — LD10 |
| Cones | Every post's cone, the unselected at 14% opacity; fans with a colour gradient and soft tile textures (diorama 384–409) | One shape at a time, others only their facing; sharp edges, no gradients | §21.12 | No — LD11 |
| Law texts | Sleepwalk "Guards see less but hear the tiles beside them"; Glowing dark "Lantern wards light the tiles around them" (js:26), and the model plays them that way | Sleepwalk: guards "can't see, but hear anyone moving faster than a walk within 4 tiles"; Glowing dark: "The realm is dark; beyond 3 tiles only glowing things can be seen" | §7.7 | No — LD12 |
| Heart grid | 9 × 9 with void corners | A realm is 10 to 14 tiles across (§21.1 line 10408); the Heart's size is unstated, and the owner counts the Heart as realm level 3 (G19), whose grid is 12 × 12 | §21.1, §5.2, G19 | No; the build uses the island's own grid |
| Test-run verdict | "The defence holds" after a sight-line check | Holding is a measured rate | §13.2 | No (minor; reword, see 3.5) |
| Only the Heart | The screen edits the Heart | Every realm has a generated defence | §13.3 | No; a build choice (a realm picker) |
| Text size | 8.5–12 px | 13 pt | §21.8 | Yes |
| "Coming in a later turn" | TRY note | — | §23.2 | Yes |

### 3.5 Adoptable as it stands

The full-screen island with the edit sheet over it; the name plate that opens the name sheet; SAVE in the header; the hold strip as a band gauge with a previous-value marker and a delta (once the number has a source, LD10); **SNEAK ROUTES** as the headline number (it is §13.3's stealth-path count) with unseen routes drawn in pink and seen ones in white; landing flags (relabelled realm · link); the message line that says what each edit did; the Layout, Laws and Posts tabs; layout cards with mini maps; the Across/Along presets as a quick way to "draw streams" (§7.7's owner choice; §7.10's generated default is across); "Reset posts"; moving a post by tapping open ground; the TEST RUN as an animated **route check** over the stealth paths (its verdict reworded to "unseen from Rope" / "every route is seen", with a link to Rehearse for a real run); the BEST hint, retired by a competence trigger (§15.3); naming from two word lists (§13.3 "name it"; §18.6's safety rule), shown to raiders on the scout card.

### 3.6 Does it add a mechanic?

Yes, one for certain: the facing dial changes what a guard can see. The save gate, if adopted, changes what a player can do. The swap's price is a conflict with §5.6 rather than an addition.

### 3.7 What the build has today

- `client/scripts/builder_screen.gd` (the island builder: ground, wards, guards, laws with pylons, the Vault, erase; `Island::check`'s problems shown as sentences; "Raid" plays one's own island, lines 14, 136–206). No layouts, no generator, no names, no hold, no stealth paths.
- `client/scripts/realm_view.gd`: one guard's sight drawn with sharp tiles from the simulation's own rule; tap a guard to select (278).
- `client/data/draft.gd` keeps one island on the phone.
- Server: `PUT /v1/islands/:realm` publishes a realm's bundle (`server/src/http.mjs:7`); islands held to the realm level built (`server/src/universe.mjs:287`); word lists in `server/src/words.json` (`GET /v1/workshop/words`).
- The generator exists only in `tools/heist_harness/island.py:247` (D66).

### 3.8 Server needs

1. **Generated defences on the server** (D66's port): a defence generated for every realm at first sight (§13.3), stored as the realm's island with origin `generated`.
2. **Layouts**: `GET /v1/defences/:realm/layouts?count=3` → bundles with their stealth-path counts (or generated on the phone from the same Rust code and a server-given seed; either way deterministic).
3. **Saving**: `PUT /v1/islands/:realm` gains `{name: {adjective, noun}, origin}` (origin per LD9), and the name is shown in the scout's free facts.
4. **Measurement queue** (LD10, shared with the Workshop, D62): `POST /v1/measure {bundle}` → `{digest, state}`; `GET /v1/measure/:digest` → `{hold, se, raids}`; cached by digest; run in a queue, not the request; held by G44's simulation bucket.
5. **Law changes** go through the Weaving routes (the Weaving report's `POST /v1/universe/realms/:realm/weave`), unless LD7 is answered otherwise.

### 3.9 Plan for the Godot build

1. **Sim and extension first** (section 1): generator, stealth paths, terrain features and moss, post facing only if LD8 says so. New extension class `RulebornGenerator`: `layouts(context: Dictionary, count: int, seed: String) -> Array[PackedByteArray]`, `regenerate(bundle, held: Dictionary) -> PackedByteArray`. On `RulebornIsland`: `stealth_paths() -> Array[Dictionary]` (landing, tiles, seen), `sight(post: int) -> PackedInt32Array`, `landings_named() -> Array` (realm and link for the Heart's arrivals).
2. **Store**: a `defence` slice (`features/defence/defence_state.gd`): realm; layouts (bundle, stealth count, measured hold or "measuring"); the chosen one; edits; name; saved digest; busy; error.
3. **Controller** (`features/defence/defence_controller.gd`): load the realm's island; generate alternatives in a `WorkerThreadPool` task so the frame never waits (§24's 25 ms touch-to-picture); apply an edit through `RulebornIsland` (move post, choice preset, swap via Weaving), recompute stealth paths synchronously (a 14 × 14 search is microseconds), and ask the measurement queue for the new digest after a pause in editing; save through `PUT /v1/islands/:realm`.
4. **Presenter** (`features/defence/curation_presenter.gd`): header (name, savable or why not), hold strip (measured value with its error, or "measuring…"; the band for this island's origin and realm level; previous value), sneak count, message line in words, tab contents, the posts' "watches N tiles", and every label spoken (§20.8).
5. **Screen**: `scenes/curation.tscn` + `scripts/curation_screen.gd`, opened from the Realm view's Defence tray for any realm. Components: `HoldGauge` (band bar, marker, previous marker; shared with the Workshop), `StatChip`, `SegmentedTabs`, `BottomSheet`, `LayoutCard` with `MiniGrid` (a `Control` drawing the island's tiles from the bundle), `LawSwapCard`, `PostRow`, `WordPicker` (shared with the Workshop's name sheet), `RoundAction` (TEST RUN).
6. **World**: until the art pass, `RealmView` in an edit mode with the overlay API (section 1): routes, the selected post's tiles with hard edges, landing flags labelled realm · link, cursor, BEST hint, ghost probes along stealth paths. After the shell's diorama exists, the same overlays in 3D (the prototype's defence mode, diorama 360–480, is the reference: chevrons on unseen routes, flags with rings, Vault beam), labels as 2D `Control`s placed by `Camera3D.unproject_position`, tiles picked by a ray against the island's ground plane.
7. **Tests**: presenter (band by origin and realm level; savable rules; hold shown only when measured), controller (an edit changes the bundle and the stealth count; save sends name and origin), the layout checks, and a still.

### 3.10 Effort

XL. It needs the generator port (D66), stealth paths, the measurement queue, the Weaving pricing (the Weaving report's `sim/src/stability.rs`), the realm overlays, and answers to LD7–LD10.

---

## 4. Rehearsal and defence log

### 4.1 The §23.2 row (line 11267)

> | Rehearsal and defence log | Test and learn defence. | Simulated crew choice, route replay, raids on you, each with its report (the haul denied, how long the defence held, where the crew was seen, what fired; 13.2), Trace

What the rest of the document asks: §13 "Rehearsals" (7477–7479): "A rehearsal sends one of three simulated crews (cautious, greedy or fast) against the universe as it stands and shows the route it took, where it was seen and what it carried out. Rehearsals are free and unlimited, give no rewards, and run on the same simulation as real heists." §13.2 (7581): "After every raid the defender's report shows how much of the haul the defence denied, how long it held the crew up, where the crew was seen and which wards fired". §13 logic: "The defender is notified afterwards and can watch the replay"; watching live is version 1.1 (7480–7482). §12.3 (6932): "Trace: within 24 hours of being robbed, a player can target the raider once, with a free scout and no entry fee." §12.9: Clean, Loud, Partial, Foiled. §12.11 (7121): friendly heists — "the friend earns a page for every raider their guards catch". §13.4: "The hold rate is its special case, where grade × fill is zero." §15.2 (8716–8719): "The first raid on you, its replay, and a suggested rehearsal … Three heavy losses: a defence check-up". §20.8 (10300): "the heist can be paused at any time in ruins and rehearsals". §23.5 (line 11418) says the defence log "already follow[s] this document".

### 4.2 What the design shows (Gameplay_16; captures rh_*)

Back button; segmented **REHEARSE | DEFENCE LOG** (markup 222–244, js:590–597).

**Rehearse tab**:
1. A replay map (flat SVG, not the 3D island): the realm as a green oval with buildings, guard dots with sight circles, the Vault star, the crew's route as a coloured path, red "!" where it was seen; caption "REPLAY · CAUTIOUS CREW"; legend "! seen · ◯ guard sight · ★ Vault".
2. Three crew cards: **Cautious** "Waits for gaps, never runs", **Greedy** "Loads until the bag is full", **Fast** "Runs the shortest route".
3. A result card: "RESULT · ESCAPED QUIETLY" (Greedy: "CAUGHT AT THE GATE"; Fast: "ESCAPED LOUD"), TIME 2:48, TIMES SEEN 1, CARRIED OUT 640, and a line ("Guard sight near the Library caught it once. Nothing else saw it.").
4. **RUN REHEARSAL · Free · unlimited · no rewards** (it only shows a toast; js:596).

**Defence log tab** (rh_log):
1. Three chips: "5 Raids this week", "4 Held", "2 Trace ready" (js:597).
2. A red live banner: "A crew is in Tidehold now · The raider's name shows when the raid ends" (markup 232).
3. Five rows: portrait in the raider's school colour, name, a tag (HELD / GOT OUT / FRIENDLY), a line ("2 h ago · held them 2:31", "Yesterday · out via Lantern Vale", "2 days ago · caught twice"), and on the right "Denied 3,300", "You lost nothing", "+2 pages"; "Report ›" (js:592).
4. **Report sheet** (rh_report0): "Raid report · 2 h ago · Marta", tag and summary ("Three of four crew caught at the gate"), **Haul denied 3,300**, **Held the crew 2:31**, the 3D island with the route, a "LAND HERE" flag and "Seen 2 times: west hedges, Spire steps", **What fired** ("Bell post at the gate rang", "Bramble caught three crew", "Stillness hid your Warden"), **Watch replay**, **Trace Marta · Free scout · 22 h left**.

### 4.3 Against the must-show list

Simulated crew choice — drawn. Route replay — a static path; nothing replays (the run button only toasts). Raids on you with their report's four measures — drawn. Trace — drawn, with the 24-hour window. So everything is shown, and the route replay needs the real simulation to be what the row asks.

### 4.4 Deviations

| What | Design shows | Document says | Section | In §23.5? |
|---|---|---|---|---|
| Outcome words | Rehearsal: "Escaped quietly", "Caught at the gate", "Escaped loud"; log: HELD / GOT OUT / FRIENDLY, and Marta's raid ("three of four caught", "Denied 3,300") is HELD | Clean, Loud, Partial, Foiled; holding is the case where grade × fill is zero, so only Foiled is held | §12.9, §13.4 | No — LD21 (§23.5 says the log already follows) |
| "4 of 5 held" | A week that held 80% | Holds inside 30–45%; one record per raid | §13.2 | Yes ("Demo numbers") |
| Live raid banner | "A crew is in Tidehold now" | The defender is notified afterwards; watching live is 1.1 | §13 | No — LD23 |
| The report's map | The scout component with a "LAND HERE" flag on the Heart | Skiffs cannot land on the Heart | §5.4 | Yes, as the Scout report's row; the same component, so the same fix |
| Report measures | Haul denied, held, seen places, what fired | Named, not defined for one raid; the simulation does not record them | §13.2, §13.4 | No — LD22 |
| Pause and slow play | No controls on the replay | Pause at any time in rehearsals; Settings' 75% pace | §20.8 | No (build follows §20.8) |
| One realm | The map is one realm | "against the universe as it stands" | §13 | No (the build follows §13 once crossing realms exists) |
| Teaching | No suggested rehearsal, no check-up | §15.2's two prompts | §15.2 | No (build adds them) |
| Text size | 9–11 px | 13 pt | §21.8 | Yes |

### 4.5 Adoptable as it stands

The two tabs on one screen; the crew cards and their one-line behaviours (they describe §13's three names; LD24 asks the document to own the policies); the result card's TIME / TIMES SEEN / CARRIED OUT; "Free · unlimited · no rewards"; the log's three weekly chips (with "held" = Foiled); raid rows with the raider's name only after the raid (§17.8 line 8979: "raids are anonymous while they happen"); the report sheet's four measures and its "What fired" list widened to bells, guards and laws (a superset of §13.2's "which wards fired"); Watch replay; Trace with its time left; friendly heists in the log with their pages (§12.11).

### 4.6 Does it add a mechanic?

The live banner does (a raid in progress becomes visible). The rest is the document's.

### 4.7 What the build has today

- **A different "rehearsal".** The client calls raiding one's own island from the builder a rehearsal: `builder_screen.gd:173–183` (`raid`), `heist_screen.gd:30–32`, `app_state.gd:45–51` (`testing`), Settings' `slow_rehearsals` at 75% (`client/scripts/settings.gd:33`). That is the Workshop's playtest (§18.6's "cleared by its creator"), not §13's simulated crews. The name should move to "playtest" before the real rehearsal arrives.
- **Replays**: `GET /v1/heists/:token/replay` serves the defender (`http.mjs:11`), the client fetches it (`client/data/repositories/heist_repository.gd:88–89`) and `scenes/replay_screen.tscn` re-simulates one tick at a time.
- **Notifications**: the day's raids in one `raided` push with each heist's grade (`server/src/notifications.mjs:233–252`).
- **Trace**: leases accept `"trace"` (`http.mjs:9`).
- **Friends feed** lists heists between friends (`server/src/friends.mjs:95–106`).
- No list of raids on the player; no report fields in `Outcome` (`sim/src/heist.rs:146–167`); no simulated crews in `sim/`.

### 4.8 Server needs

1. `GET /v1/defences?since=` → raids on the caller, newest first: token, realm, mode (raid, friendly, trace), outcome (§12.9 grade), raider (only once settled), when, haul denied, held, pages earned (friendly), Trace open until (24 h from the raid, once, §12.3), seen-by-player flag; plus the week's counts (raids, foiled, Trace ready). The shell report's banner and badge use the same route.
2. `GET /v1/defences/:token` → the report: haul denied, held, sightings named by place (nearest building or feature), what fired. Computed by re-simulating the stored replay against the snapshot the first time it is opened and cached in a `defence_reports` table, because §24's validation is sampled and most raids are never re-simulated at settlement (LD22).
3. `POST /v1/defences/seen {upTo}` for the badge.
4. Nothing for rehearsals: they are local, free and unrewarded; telemetry records them (`rehearsal` event: crew, outcome) for §15.4's "time to the first rehearsal".

### 4.9 Plan for the Godot build

1. **Sim**: `sim/src/crews.rs` with the three rehearsal crews and D66's reference crews as command generators over `Heist` (deterministic, no randomness beyond the heist's seed); a `Report` recorder (sightings, triggers, landed and ended ticks). Extension: `RulebornRehearsal.run(universe: Array[PackedByteArray], crew: String, seed: String) -> Dictionary` returning the replay bytes, the outcome and the report. One run takes well under a second; run it on a `WorkerThreadPool` task with a "rehearsing…" state.
2. **Store**: a `defence_log` slice (raids, counts, reports by token, busy, error) and a `rehearsal` slice (crew, replay, outcome, report, playing, paused, speed).
3. **Repository**: `client/data/repositories/defence_repository.gd` (`raids(since)`, `report(token)`, `seen(up_to)`); Trace through `HeistRepository.lease(bundle, owner)` with `trace`.
4. **Controller** (`features/defence/rehearsal_controller.gd`, `defence_log_controller.gd`).
5. **Presenters**: rows (outcome words from §12.9, the raider's name only after settlement, the right-hand figure: denied, "you lost nothing" for an escape, pages for a friendly raid), the report (four measures in words, places by name), the rehearsal result (outcome, time, times seen, carried out, one generated sentence from the report: "Seen once, near the Library").
6. **Screen**: `scenes/rehearsal.tscn` + `scripts/rehearsal_screen.gd`. Rehearse tab: `RealmView` replaying the rehearsal's replay tick by tick (the replay screen's own loop), with seen marks and the legend, play / pause / 75% (Settings' `slow_rehearsals`, renamed), the three `CrewCard`s, the result card, RUN REHEARSAL. Log tab: `StatChip`s, `RaidRow`s, the `ReportSheet` (`BottomSheet`) with a small `RealmView` of the route and seen tiles, Watch replay (`router.go(&"replay", {token})` in defender mode), Trace (to the planner with the trace lease). §15.2's prompts: after the first raid, a banner suggesting a rehearsal; after three heavy losses, a check-up card pointing at curation.
7. **No live banner** until LD23 is answered.
8. **Tests**: presenters (outcome words; held counts Foiled only; names hidden before settlement; Trace window), the crew runs are deterministic (same seed, same replay; a golden for each crew), controller against `FakeTransport`, layout checks.

### 4.10 Effort

L for the screen and server; the crews and the report recorder in `sim/` add an L of their own (shared with D66 and curation).

---

## 5. Terrain editor

### 5.1 The §23.2 row (line 11287)

> | Terrain editor | Shape a realm. | 39 features by family, terrain points left, the route check, and a live preview of guard sight

What the rest of the document asks: §6 (1150): "39 features in seven families". §6.1 (1152–1165): the budget (outer 30 + 15 a realm level, 45 to 105; the Heart 40 + 10 a Spire level); "Reshaping is free and instant"; snapshots; "The route rule: terrain can lengthen routes but never close the last route from the edges to the Heart"; four heights, dropping free and one-way; noise from stairs, gravel, scree, bells and bounce mushrooms; moss as the default ground, cleared at 1 point a tile. §6.2 (1166ff, `content/terrain.json`): each feature's movement, sight, points, where found, law interaction and Keeper level. §6.3: unlocks. §12.17: higher ground sees further. §21.12: one guard's vision at a time.

### 5.2 What the design shows (Gameplay_22; captures te_*)

Full-screen 3D island with a tile grid (markup 471–488, js:1023–1066):

1. **Points bar**: a terrain icon, "**94** left of 100 points · THE HEART", a green fill (red under 6).
2. **Three stat chips** with delta badges after each edit: **ROUTES 4 / 4** (landings with a way to the Vault), **FASTEST 14 s** (the cheapest route's time), **SEEN 3 tiles** (tiles of that route inside a cone); a "♪ N noisy tiles on the fastest route" chip when noise lies on it.
3. **The island**: landing flags (Sky, Tide, …), routes (the fastest pink), the Vault, posts with numbers; a pop animation and a ring where a feature lands; a red cursor and a reason on a refused tap.
4. **Right rail**: UNDO (30 steps), CLEAR (erase mode, refunds points), SIGHT (draws every post's cone and the seen tiles).
5. **Hint pill**: "Tap a tile to place Hedge" / "Locked until Keeper level 10".
6. **Bottom sheet**:
   - the selected feature's card: family kicker with how many are placed ("PLANTS · 2 PLACED"), name, flag chips (BLOCKS, BLOCKS SIGHT, HIDES, NOISY, CLIMB, LIGHTS, ONE-WAY), a points gem ("1 POINT", "PER LEVEL", "FREE", or the Keeper level when locked), **MOVEMENT**, **GUARD SIGHT**, and a violet **LAW** line ("Bloom regrows it; Thorns makes it hurt");
   - seven family tabs (Ground, Water, Plants, Rock, Light, Heat, Built) with placed counts;
   - a carousel of the family's features: art, points, up to two flag chips, "×2" placed, "LV 10" when locked (te_fam_*).
7. **Rules enforced** (js:89–104): nothing on the Vault, a landing or a post; not off the island or on a building; raised ground up to level 3 at 2 points a level; cliff edges are made by height, not placed; "Not enough terrain points"; "That would close the last route to the Heart"; Keeper-level locks; every edit toasts its effect ("Hedge · fastest +2 s · seen −1").

### 5.3 Content against the document

The design's table of 39 (js:27–66) has every feature, family, Keeper level and point cost of §6.2 (compared mechanically against `content/terrain.json`; script `analysis/lcrtw_scripts/teft.mjs`). Text differences, in the order they matter:

- **Bell post**: design "Rings when passed / Guards within 4 tiles hear it / Held breath silences it"; §6.2 "Rings if bumped / Raises the realm's alarm one level (12.17) / Delay makes the ring come late". A different rule.
- **Ruin wall**'s law line: design "Echoes bounce off it"; §6.2 "Shifting stones moves ruin walls too". An invented interaction.
- **Raised ground** drops "or a leap"; **Pond** drops "Frictionless freezes nothing"; **Stream** drops the Spores clause; **Hot spring** drops "while standing in it"; **Thicket** "linger" for "linger longer"; **Climbing vines** rephrased.
- **Stairs** sight "Noisy underfoot" where §6.2 has "—": consistent with §6.1's noise list, so not a deviation.
- **Family names** shortened: Ground (Ground shape), Rock (Rock and crystal), Light (Air and light), Heat (Heat and energy).
- **Budget**: shows 100 (js:1024, consistent with §6.1 at Spire 6) and enforces 80 (js:90, `BUD = 80`). A prototype bug, not a document question.
- **Keeper level**: the editor assumes Keeper 6 (js:90, 1024) while the prototype's data module says 24 (`data_v35.js`, `player.keeper`). Internal to the prototype.

### 5.4 Against the must-show list

All four are drawn: 39 features by family, points left, the route check (ROUTES and the refusal), and the guard-sight preview (SIGHT).

Rules the design omits: **clearing moss** (§6.1) — the one terrain action a Keeper takes to deny an ambush, decided under F29 — has no tool (LD13); directions for ramps, stairs, rapids and waterfalls, and a tunnel's two ends, have no gesture (LD16).

### 5.5 Deviations

| What | Design shows | Document says | Section | In §23.5? |
|---|---|---|---|---|
| Heart arrivals | Sky, Tide, Rift, Rope | Realm · link | §5.3 | Yes |
| Feature texts | Bell post, Ruin wall and five others differ (5.3) | §6.2's table | §6.2 | No — LD12 |
| Moss | No moss and no clearing | Moss on every featureless tile; cleared at 1 point a tile | §6.1 | No — LD13 |
| SIGHT | Every post's cone at once (js:1031) with gradient fans | One guard's vision at a time, sharp edges | §21.12 | No — LD11 |
| Directional features | One tap, no direction | Silent | §6.2 | No — LD16 |
| Heart grid | 9 × 9 | 10–14 tiles; G19 counts the Heart as realm level 3 | §21.1, G19 | No |
| Budget wording | "THE HEART" with 100 points | §6.1's Heart budget by Spire level; §13 and §13.4 also call geometry "free, unlimited" | §6.1, §13, §13.4 | No — LD14 (a v3.6 self-contradiction) |
| Text size | 7.5–11 px | 13 pt | §21.8 | Yes |
| "Coming in a later turn" | TRY note | — | §23.2 | Yes |

### 5.6 Adoptable as it stands

The points bar; ROUTES / FASTEST / SEEN with delta badges after each edit (FASTEST and SEEN computed by the simulation's pathfinder and sight, not the prototype's formula); the noise chip; the Undo / Clear / Sight rail (Sight cycling one post at a time); the hint pill; the feature card with flag chips, points gem, movement, sight and law lines (texts from content); family tabs with counts; the carousel with locks; refusals as a red cursor and a sentence; a toast that says what each edit did; cliff edges formed by height; the pop on placement.

### 5.7 Does it add a mechanic?

Only through the changed texts if they were built as written (Bell post, Ruin wall). The build takes rules from content.

### 5.8 What the build has today

- `client/scripts/builder_screen.gd`: a GROUND tool cycling through `RulebornIsland.palette()["ground"]` (eight ids), tap to lay, ERASE; no points, no families, no stats, no undo, no sight toggle.
- `client/ext/src/island.rs:32–41, 130–151`: five features plus gravel and stream surfaces and one level of raised ground.
- `sim/`: five route-changing features, four surfaces, heights, climbable flags; `Island::check` refuses a sealed realm (`Problem::Sealed`, island.rs:161–164) and `reaching()` gives the edge tiles that reach the Vault (island.rs:505); no terrain points.
- `client/scripts/realm_view.gd`: the selected guard's tiles from the simulation (§21.12).
- Server: no terrain rule (section 1).

### 5.9 Server needs

1. `PUT /v1/islands/:realm` refuses an island over its terrain budget (outer by realm level; the Heart by the account's Spire level, which only the server knows) and features above the player's Keeper level (§6.3).
2. Nothing else: editing is local until saved; "reshaping is free and instant".

### 5.10 Plan for the Godot build

1. **Sim first**: the 31 features in batches by family, each with tests from §6.2's cells (movement, sight, noise, hide, light, one-way, timers for ember vents and static stones); moss as the default with `clear_moss`; heights 0–3; directions; tunnel pairs; `terrain_points(budget)`; the rules version moves once for the batch (§24.11).
2. **Extension**: `RulebornIsland.place(x, y, id, dir)`, `raise(x, y)`, `lower(x, y)`, `clear_moss(x, y)`, `points() -> {used}`, `routes() -> Array[{landing, tiles, seconds, seen, noisy}]` (seconds from §12.18's walk speed and each tile's movement factor), `sight(post) -> PackedInt32Array`, and a static `features() -> Array[{id, family, points, keeper_level, flags}]` read from the content the simulation was built with.
3. **Merge with the builder**: the terrain editor is the builder's terrain mode, styled as designed; the builder's other tools (posts, wards, laws, Vault) become the Workshop sandbox's extra tabs (section 6). One island model, one undo stack (bytes, 30 deep), one save path (`Draft` for Workshop drafts; `PUT /v1/islands/:realm` for home realms).
4. **Store/presenter**: an `editor` slice (realm, mode home|sandbox, bytes, undo stack, family, selected feature, tool paint|erase|moss, sight post, last delta); `TerrainPresenter.view()` gives the points bar (left of budget, low under 6), stats with deltas, the selected card (from content words: `FEATMOVE_*`, `FEATSIGHT_*`, `FEATLAW_*` emitted by `client_strings.py`), family tabs with counts, carousel cards (locked by Keeper level, or open for a Wright in the sandbox), the hint, and a refusal sentence per `Island::check` problem.
5. **Screen**: `scenes/terrain.tscn` + `scripts/terrain_screen.gd`; components `PointsBar`, `StatChip` (shared), `RailButton`, `FeatureCard`, `FamilyTab`, `FeatureTile`, `BottomSheet`; the world is `RealmView` with the cursor, routes and one post's sight, later the diorama. A tap edits on release (§20.8: taps only, no drag needed); a long-press shows the feature card for the tile.
6. **Tests**: presenter (points by realm and Spire level, locks, refusal sentences), the extension (each feature's movement and sight from §6.2, moss clearing charges a point, the route rule refuses the last seal), layout checks.

### 5.11 Effort

XL, nearly all of it in `sim/` (31 features and the format). The screen itself is M.

---

## 6. Island Workshop

### 6.1 The §23.2 row (line 11299)

> | Island Workshop | Build, test and publish islands. | Sandbox tools, playtest button, publishing checks, ratings and spotlights

What the rest of the document asks: §18.6 (9060–9074): a free sandbox "with every law and terrain feature the player has unlocked and no stability limit"; "an island must be cleared by its creator before it can be published"; ratings for fun, cleverness and fairness; the best join the Drifting ruins and a weekly spotlight with the creator's name; structured data only; names from word lists; every island can be reported; "featured islands are reviewed by a person"; 13 to 15 browse curated lists only. §18.7 (9076–9105): the four ranks and what each gives ("Loremaker … a say in one season's theme"); "Completions, not ratings"; anti-gaming; "A published island is checked against the authored hold band before the Workshop lets it out". §20.7 (10249): 13 to 15 publish with word-list names and browse curated lists only. §20.12 (10386): "Between five and ten published islands per account". §24's Workshop row: "validated by the same simulation, scanned automatically, and served through curated and rated lists". §25.1 (12131) and §27.5 (13085): 10% remix within 30 days, with a one-tap "remix this island".

### 6.2 What the design shows (Gameplay_25; captures ws_*)

Back; title; a rank chip "Builder" (markup 509–545, js:1136–1180).

1. **Tabs**: "My islands" | "Discover" with a red "4" badge.
2. **Creator card**: medal, "Builder creator", "640 / 1,000", "360 more completions to Wright: every law and terrain feature unlocked in the workshop", and a four-step ladder (Builder, Wright, Architect, Loremaker). Tapping opens the **ladder sheet**: "Ranks count completions, not ratings. None of them make you stronger in a heist." with each rank's condition and reward and "YOU", "360 TO GO", "LOCKED" chips (ws_ladder).
3. **Draft card**: cover image, DRAFT, "SLOT 2 OF 5", "Untitled island", law chips (Slow rivers, Stillness) and "2 realms"; **DEFENCE BUDGET** "38% held · fair" on a bar marked Too easy / Fair: 30–45% held / Too hard; **READY TO PUBLISH? 3 of 4 ready**: "Cleared by you · 2:31 · Scout crew", "Vault reachable · 3 routes open", "Fair budget · 62% · Lv 6 band", "Name & cover · Tap to add a name" (red); **Edit** (opens the Terrain editor, js:1166), **Playtest** (opens the heist), **Publish** (grey until all four pass).
4. **Name sheet**: "Name your island", Shuffle, "Names are built from word lists, so every name is safe to show.", three names per shuffle.
5. **Publish celebration**: cover with an "IN REVIEW" stamp, "Published!", the name, "A person reviews it within an hour. Then anyone can raid it, and every completion counts toward Wright." (markup 542; ws_published). The draft's tag becomes "IN REVIEW · 1 H" (js:1161).
6. **Published · 1 · Counted by completions**: "LIVE Glass Maze · Matter · Glass · 1 realm · 1,240 COMPLETIONS · 38% ESCAPE · Fun 4.6 Clever 4.8 Fair 4.3"; its sheet (ws_pubsheet): DONE 1,240, ESCAPE 38%, BEST 1:47, PLAYERS 312; rating bars; "COMPLETIONS · LAST 7 DAYS +18% this week" bar chart; "HOW RAIDS END" (Escaped with loot 38%, Caught in the glass corridor 34%, Caught at the Vault door 21%, Lost on the landing ridge 7%); LAWS IN PLAY; Edit, Share; "Most crews are caught in the glass corridor. If the escape rate falls under 20%, players start rating it unfair." (js:1153).
7. **New island** "3 free slots · every law you own, no stability limit" (markup 522).
8. **Discover** (ws_discover): "SPOTLIGHT OF THE WEEK · Tower of Held Breath · by Ines · Architect · Time laws only" with FUN 4.9, CLEVER 4.9, FAIR 4.7, DONE 18k and Play; chips **Top this week / New / Friends**; ranked rows (rank medal, cover, name, "by Kofi · Spirit", "9.2k done · 29% escape · ★ 4.8", Play); "Every island here was cleared by its creator before it went live." (markup 528). An island's sheet: stats (DONE, ESCAPE, BEST, YOURS), rating bars, laws in play, **Report** ("Reported. A person will look at it") and **Play / Play again**, "Ines cleared it before it went live, so it can be solved." (ws_spotlight).

### 6.3 Against the must-show list

Playtest button, publishing checks, ratings and spotlights are drawn. **Sandbox tools are not**: Edit leads only to the Terrain editor (js:1166), so the sandbox's laws without a stability limit, guards, wards and the Vault have no designed tool. The builder that exists has them; the design has to reach them.

### 6.4 Deviations

| What | Design shows | Document says | Section | In §23.5? |
|---|---|---|---|---|
| The band check | "Fair budget · 62% · Lv 6 band" | 30–45% at every realm level for an authored island | §13.2, §18.7 | Yes |
| Review before going live | "A person reviews it within an hour", "IN REVIEW · 1 H" | Featured islands are reviewed by a person; reports within 24 h; islands scanned automatically | §18.6, §20.4, §24 | No — LD17 |
| Remix and Withdraw | Absent | One-tap remix carries §25.1's 10% gate; withdraw at the player's request | §25.1, §27.5, §20.12 | No — LD18 |
| Realms per island | "2 realms", "1 realm" | Silent on whether a Workshop island is one realm | §18.6 | No — LD19 |
| Escape rates | 18%–61% escape on published islands; "If the escape rate falls under 20%, players start rating it unfair" | Published islands hold 30–45% (escape about 55–70% against the reference crew); no 20% figure | §13.2, §18.7 | Partly ("Workshop checklist", "Demo numbers") — LD20 for the claim |
| Slots | "SLOT 2 OF 5" for a Builder; "3 free slots" | 5 to 10 per account; a Builder has 3 extra (the server reads 8) | §20.12, §18.7, G26 | No; G26 already open |
| Loremaker's reward | Omits "a say in one season's theme" (js:1146) | Includes it | §18.7 | No — LD12 |
| 13–15 | Top, New and Friends lists for everyone | Curated lists only | §20.7 | No; the build already holds it (`server/src/workshop.mjs:214`) |
| "Time laws only" spotlight | Lists Sleepwalk, a Spirit law | — | §7.10 | No; prototype data |
| Text size | 9.5–12 px | 13 pt | §21.8 | Yes |

### 6.5 Adoptable as it stands

The two tabs with a new-items badge; the creator card with progress and the four-step ladder; the ladder sheet and its line "None of them make you stronger in a heist" (§18.7's "No power"); the draft card (cover, slot count, law chips); the hold gauge with Too easy / Fair / Too hard (with a measured number, LD10); the four-check list (cleared by you with time and crew; Vault reachable with routes open — §6.1's route rule; fair band; name) whose red item opens its fix; Edit / Playtest / Publish; the name sheet with Shuffle and its safety line; a publish celebration (without the review promise); published cards with completions, escape and ratings; an island's sheet with stats, rating bars, laws in play, 7-day completions and how raids end (from data, once the server has it); "Counted by completions"; the spotlight card; Top / New lists; Report with a person looking at it (§20.4); "X cleared it before it went live, so it can be solved" (§18.6). A **cover** is adoptable only as a render of the island's own data (§18.6: never an uploaded image). A **Friends** list is adoptable for 16 and over (a list of islands, nothing new revealed), never for 13 to 15.

### 6.6 Does it add a mechanic?

The one-hour human review would change when an island becomes playable. Otherwise no.

### 6.7 What the build has today

The most of any of the five:
- `client/features/workshop/workshop_state.gd` (slice: list, items, curated, words, ladder, played, terms), `workshop_controller.gd` (browse, publish, play, rate, report, remix, withdraw, terms, block; lines 20–254), `workshop_presenter.gd` (cards, tabs by age band, ladder line, publishing from a cleared self-raid, rating; lines 1–141), `client/data/repositories/workshop_repository.gd:17–71`, `client/scripts/workshop_screen.gd` (296 lines), `scenes/workshop.tscn`, `tests/workshop_tests.gd`. Remix makes the island the builder's draft (`client/data/draft.gd`).
- `server/src/workshop.mjs`: publish with a re-simulated clear (`clears`, line 67), word-list names, slots 5 + 3 for a Builder (lines 30–31, 156), quota, browse top/new/featured with 13–15 held to featured (214), play and submit, ratings, reports with five reasons, remix, withdraw, the ladder, spike review, moderation and featuring. No band check (D62). Tables in `server/src/db.mjs:236–300` (items never edited or deleted, plays with seed and outcome, completions by player with weight, ratings, reports).

### 6.8 Server needs

1. **Item statistics** in `view()`: plays, distinct players, clears (escape rate = clearing plays ÷ plays), the best clear's time, the caller's own best, completions per day for 7 days, and how plays end. "How raids end" with places ("caught in the glass corridor") needs each play's report (LD22's recorder) — computed when a play is submitted, since every Workshop play is re-simulated (`submitPlay`).
2. **A friends list**: `GET /v1/workshop?list=friends` for 16 and over.
3. **Slots** in `GET /v1/workshop/mine`: `{slots, used}`.
4. **The band check** before release (D62) through the measurement queue (LD10).
5. **The spotlight**: the week's featured island (`featured_at` exists; a weekly pick is a moderator action).

### 6.9 Plan for the Godot build

1. Keep the data layer; extend `WorkshopPresenter` with `draft_card(draft, island, measured, words)` (name, law chips, realm count, the four checks: cleared from the last playtest's verdict and time, Vault reachable from `routes()`, fair band from the queue with "measuring…", named), `creator_card(ladder)` (progress to the next rank from §18.7's table in content, not from the prototype), `published(items)` with stats, `discover(lists, age band)`, `sheet(item, mine)`.
2. **Screen**: rebuild `scripts/workshop_screen.gd` on the design's layout with components `SegmentedTabs`, `CreatorCard`, `RankLadder` (sheet), `DraftCard`, `HoldGauge` (shared with curation), `Checklist`, `IslandCard`, `SpotlightCard`, `IslandSheet` (stats, `RatingBars`, a small bar chart, ends), `WordPicker` (shared), and keep the controls the design dropped: **Remix**, **Withdraw**, **Block creator**, report reasons, rating after a play, the terms gate.
3. **Cover**: a `SubViewport` rendering the island from its bundle (top-down now, the diorama later), cached as a texture on the phone; never uploaded.
4. **Sandbox**: Edit opens the editor in sandbox mode: terrain (section 5) plus Laws (any unlocked, no stability limit; all for a Wright), Posts, Wards, Vault — the existing builder's tools in the new skin. Playtest stays the heist screen with `testing` (renamed playtest).
5. **13–15**: featured only (the presenter already filters tabs); no Friends chip.
6. **Tests**: presenter (checks, slots, age-band lists, ladder progress), controller flows already in `tests/workshop_tests.gd`, layout checks.

### 6.10 Effort

M. The data layer and server exist; the new server statistics and the shared hold measurement are the larger parts.

---

## 7. Findings for the register

Not already in §23.5, each checked against `tools/audit_register.py` for an existing item.

**LD1. Ten of the twelve resonances the Lab shows are not the document's** (deviation, significant). Design: `rz()` (js:9) — Held vigil, Glass tide, Static bloom, Frozen fall, Whisper chain, Slipstream, Ember dark, Rooted kin, Hollow stone, Soul tide — each with an effect, and icons for exactly these (icons:39–50). Doc: §8.4 (3990–4216) and `content/resonances.json` hold 44, of which the launch twelve (§7.10, 3854) are Drifting echoes, Mangrove banks, Night runners, Cracked gardens, Pinball, Storm grid, Briar maze, Twin souls, Shattered glass, Soul tether, Honey trap and Northern lights. Ten invented effects are ten added mechanics; ten real resonances have no art. Rec: add the row to §23.5 ("Resonance Lab and Codex | Ten invented resonances | The twelve of §8.4 whose laws both ship | 8.4, 7.10"); draw ten icons; the build reads `content/resonances.json`.

**LD2. "Lab hints" are named and never defined; the design invents a rule** (gap, significant). Doc: §23.2 (11261) "hints"; §15.2 (8739, 8753) "Lab hints"; §8.4/§8.6 only define the crossing hint; §15.3 (8635) "Hints appear only after repeated failure". Design: a failed pair that shares a law with an undiscovered resonance reveals that law on the card at the first failure ("A STIR … No. 04 now shows one of its two laws", js:15–16, 464), and matching settle times highlight candidates (js:437, 453–454) although §10.2 sets one duration per Lab level. Rec: write the Lab hint in §8.6 — what it reveals, after how many failures, and whether it shares the Codex's "hinted" state with crossing hints; until then the build gives no Lab hint beyond the crossing hint.

**LD3. One test chamber, no price, no Archivist** (deviation, significant). Design: one chamber (markup 184–199); the button never shows a price; "5 h 30 min" for everyone. Doc: §10.2 (5690–5700) "2 slot(s); 5 h per experiment" at level 3, 3 at level 5; §9.5 (4596) "400 Aether × Lab level"; §11.7 the Archivist at home "Lab experiments 20% faster". Rec: add to §23.5's Lab row ("one chamber, no price"); the build shows one chamber per slot, the price on the button, the effective time.

**LD4. The Lab names chords from level 3, with no trigger** (gap, minor). Doc: §8.5 (4219) "The Lab names chords — from level 3 it identifies one the player has woven or crossed"; §8.6 (4308) the same; §21.5 (10624) "A third sphere for chords". Design: no chord in the Lab. Undefined: whether naming takes a slot, time or Aether, which chord when several qualify, and how the player asks. Rec: one sentence in §8.5 (for example, "at level 3 the Lab's third sphere names, once a day and free, the cheapest chord the player has woven or crossed and not yet named").

**LD5. What an experiment may take and what it pays** (gap, minor). Doc: Insight from "Lab discoveries" (§9.1) and "with insight pages" (§16, 8872), no amount anywhere; "3 pages of a law from those schools" (§7.6, 2221) without saying which law; paradoxes need tier III laws and a universe holds one at a time (§7.5, 2181) with no state for "already holding one"; nothing says whether an unrestored law may go on a pedestal (the design allows any law met, js:389). F37 already asks whether an empty pairing can be re-run. Rec: state Insight per discovery, the pages' law (the lower-ranked of the pair, say), the pedestal rule (restored laws), and the paradox-held case; the design adds a paradox-found result.

**LD6. "The Lab costs nothing to fail", and the first experiment's five minutes** (contradiction, minor). §15.3 (8627): "Ruins, rehearsals and the Lab cost nothing to fail"; §9.5 (4596): every experiment costs 400 Aether × level, found or not. §16 (8864): "The first experiment takes 5 minutes"; §10.2: level 1 takes 8 hours, with no exception stated. Rec: "the Lab costs only its Aether to fail, and pays 3 pages back"; §10.2 (or §16) states the first experiment's time and price as an exception.

**LD7. A curation swap is a weave, and neither section says so** (deviation, significant). Design: swap and river choice are instant and free, priced only in hold (js:540–546, 579–583). Doc: §5.6 (963–967) every weave takes 10 minutes at tier I, costs 40 Aether a point, and a removed law's slot rests an hour; §13.3 (7608) "Swap a law" is curation's first verb; §13.3 (7605) the generated defence weaves "only those of their laws that help the defender", which leaves open whether the defence's laws are the realm's woven laws (economy and defence at once) or a separate set the generator may change. Rec: §13.3 says a curation swap is a weave at §5.6's price and time (and the screen shows both), or that it is exempt; and whether generating a defence can unweave a law the player wove for production.

**LD8. Who sets a guard post's facing** (gap, significant). Design: a four-way facing dial and "faces north" (js:552, 565–570; markup 219 `cu.dial`); every cone follows it. Doc: §12.17 (7263) "Patrols or holds its post"; nothing says whether the owner sets a facing or a patrol; the simulation posts every guard facing a constant 270° (`sim/src/lib.rs:547`, 1748–1752) and the bundle has no facing. It changes what a guard can see, so §23.5's rule bars it until written. Rec: state whether the owner chooses a post's facing (or patrol), carry it in the bundle, and say what the generator chooses.

**LD9. Is a curated defence generated or authored, and must it be in band to save** (gap, significant). Design: SAVE refuses outside 30–45% (js:558) and shows the authored band for the Heart. Doc: generated islands are held to their realm level's band (25–40% at realm level 1, §13.2's table), authored to 30–45%; "Every island is tagged with its origin, so the matchmaker holds it to the right band (12.22)"; nothing says what an edited generated defence becomes, or whether saving needs the band. Rec: define the origin of a curated defence (for example "curated counts as generated while only §13.3's verbs were used, authored once terrain is edited") and whether a defence outside its band may be saved (with a warning, or not at all).

**LD10. The hold figure on curation and the Workshop has no fast source** (gap, significant). Design: a hold % recomputed instantly for every layout, swap, river choice, post move and every tile of the BEST heat map, by a formula (js:105–125, 513–516); the Workshop's "38% held" gauge (markup 517). Doc: a hold is a rate over 800 raids or more (§13.2, §13.3, §13.4); §23.2 asks the preview to "re-generate fast enough not to break the flow" but not where a fast hold comes from; D62 records that the Workshop cannot measure per publish. Rec: decide the source — the stealth-path count live (§13.3's own measure, exact and instant) plus a measured hold from a server queue cached by island digest, shown as "measuring…" until it lands; or an on-device small batch with its error printed. Either way the document should say a curation preview shows the counted measure and the measured hold, never an estimate dressed as a measurement.

**LD11. Every guard's cone at once, with gradients** (deviation, minor). Design: curation and the terrain editor's SIGHT pass every post's cone (js:520, 1031); the 3D view draws the unselected at 14% opacity, the fans with a colour gradient and the tiles with a soft texture (diorama 384–409). Doc: §21.12 (11086–11088) "One shape at a time. The selected guard's vision is drawn; the others show only their facing" and "Sharp edges, no gradients". Rec: add the row to §23.5; the build draws one post's tiles with hard edges (as `RealmView` does) and cycles posts.

**LD12. Rule texts the editing screens restate differently** (deviation, minor). Bell post ("Rings when passed / Guards within 4 tiles hear it / Held breath silences it" against §6.2's "Rings if bumped / Raises the realm's alarm one level / Delay makes the ring come late"), Ruin wall's law line ("Echoes bounce off it" against "Shifting stones moves ruin walls too"), five shortened feature texts and four family names (js:27–66 against `content/terrain.json`); Sleepwalk and Glowing dark on the curation cards (js:26 against §7.7, 3598 and 2978); Mangrove banks (js:9 against §8.4); Loremaker's rewards without "a say in one season's theme" (js:1146 against §18.7). Rec: one §23.5 row, "feature, law, resonance and ladder texts on the editing screens"; the build reads all of them from content.

**LD13. Moss: neither designed nor built** (finding, significant). Doc: §6.1 (1164) moss covers every featureless tile and the Keeper clears it at 1 point a tile, decided under F29 as the defender's answer to ambushes. Design: no moss and no clearing tool (js:27–104). Build: `Island::empty` lays plain ground (`sim/src/island.rs:248–264`); only fixtures place moss (750–762); the extension's bare ground is plain (`client/ext/src/island.rs:130–151`). Rec: the design adds a "Clear moss" tool and draws moss as ground (§21.12); the simulation makes moss the default and charges its clearing; add the row to §23.5 for the design.

**LD14. "Free, unlimited" geometry against §6.1's budget** (contradiction, minor). §13's layer table (7450): Geometry "Free, unlimited"; §13.4 (7675): "Geometry costs nothing and is unlimited". §6.1 (1154): terrain points 45–105 an outer realm, 40 + 10 a Spire level the Heart, "it's the budget that limits it"; §5.2's table has a terrain points column. The terrain editor's points bar is the budget's whole point. Rec: "Geometry costs nothing to change and is limited only by terrain points (6.1)".

**LD15. The Heart's terrain budget and the sandbox's** (gap, minor). The Heart's budget depends on the Spire level, which no island bundle carries, so `Island::check` cannot hold it alone; nothing in `sim/`, the extension or the server counts terrain points today (island.rs:144–169; ext island.rs:207–223; universe.mjs:287). §18.6 lifts the stability limit in the sandbox and says nothing of terrain points. Rec: the document says whether the Workshop sandbox keeps §6.1's budget (at which realm level); the build adds `TooMuchTerrain` with the budget passed in by the server.

**LD16. Directional and two-ended features have no placement rule** (gap, minor). Ramp and stairs (which way up), rapids ("pushes anyone 1 tile a second downstream"), waterfall (which side the ledge is), tunnel ("joining two points up to 6 tiles apart"). Design: a single tap places any feature with no direction (js:98). Doc: §6.2 gives the effects and no owner choice; §7.10's placement rule covers laws, not terrain. Rec: state that the owner sets a direction and the tunnel's two ends, and the generator's rule for each; the bundle carries them (a rules-version change, §24.11).

**LD17. "A person reviews it within an hour"** (deviation, significant). Design: markup 542 and "IN REVIEW · 1 H" (js:1161). Doc: §18.6 (9070) "featured islands are reviewed by a person"; §24's Workshop row "scanned automatically"; §20.4 reports reviewed within 24 hours by a part-time moderator; the server publishes at once (`server/src/workshop.mjs`, `publish`). A one-hour human review of every island is a staffing promise the document does not make and changes when an island becomes playable. Rec: add the row to §23.5 (live on passing the checks; "in review" only for the spotlight).

**LD18. Remix and Withdraw are missing from the design** (gap, significant). Doc: §25.1 (12131) "10% have remixed one", §27.5 (13085) "one-tap 'remix this island'"; §20.12 withdrawing at the player's request. Design: island sheets offer Report and Play, or Edit and Share for one's own (js:1153–1154). The build has both (`client/features/workshop/workshop_controller.gd:153, 166`; `server/src/workshop.mjs:160, 381`). A launch gate rests on a button the design does not draw. Rec: the design adds Remix to every island sheet and Withdraw to the player's own; the build keeps them.

**LD19. One realm or several** (gap, minor). Design: a draft of "2 realms", Glass Maze "1 realm" (js:1163, 1172). Doc: §18.6 "an island is a set of laws, terrain, guards and a layout", silent on realms; the server stores one bundle with one realm level (`server/src/workshop.mjs:146–149`). Rec: state whether a Workshop island is one realm or a small universe; a universe needs crossing realms in the simulation.

**LD20. The Workshop's escape claim** (deviation, minor). Design: "If the escape rate falls under 20%, players start rating it unfair" (js:1153), on islands escaping 18–61%. Doc: no such figure; published islands are checked to hold 30–45% (§18.7, §13.2). Rec: drop the sentence or give it a source (§19.22's citing rules); show the island's measured escape.

**LD21. Outcome words in the log and the rehearsal; a Partial called held** (deviation, minor). Design: "Escaped quietly / Caught at the gate / Escaped loud" (js:590); HELD / GOT OUT / FRIENDLY, with "three of four crew caught … Denied 3,300" tagged HELD (js:592). Doc: §12.9's Clean, Loud, Partial, Foiled; §13.4 "The hold rate is its special case, where grade × fill is zero", so only a Foiled raid held. §23.5 (11418) says the defence log already follows the document. Rec: correct §23.5's sentence and add the row; the build labels raids by §12.9 and counts "held" as Foiled.

**LD22. The defender's report: four measures without definitions or a record** (gap, significant). Doc: §13.2 (7581) and §23.2 (11269): "the haul denied, how long the defence held, where the crew was seen, what fired". §13.4 defines haul denied over many raids against a no-defence baseline, not for one raid; "held the crew up" has no measure; the simulation records none of the four (`sim/src/heist.rs:146–167`); §24's validation is sampled, so most raids are never re-simulated on the server. Rec: define each for one raid (for example: denied = what the crew could carry from the exposed Vault less what it banked; held = seconds from landing to escape or capture; seen = tiles where a guard reached Alerted, named by the nearest building; fired = wards triggered, bells rung, guardian Sage power); the build records them in `sim/` and computes a report by re-simulating when the defender opens it.

**LD23. A raid shown while it happens** (deviation, minor). Design: "A crew is in Tidehold now · The raider's name shows when the raid ends" (markup 232). Doc: §13 "The defender is notified afterwards and can watch the replay"; watching live is version 1.1 (7480–7482); §17.8 "raids are anonymous while they happen". Rec: drop it at launch, or §13 adds "a defender sees that a raid is under way in a realm, never who or how".

**LD24. Three rehearsal crews with no behaviour** (gap, minor). Doc: §13 (7479) names "cautious, greedy or fast" and no policy; the harness has other crews (`tools/heist_harness/policy.py:460–534`); D66 asks for the reference crews in the simulation. Design: one line each (js:590). Rec: §13 gives each crew its rule in a sentence (when it moves, when it stops loading, how it picks a route); the build writes them in `sim/` beside D66's port.

Existing items these screens touch: **G19** (the Heart counts as realm level 3), **G26** (Workshop figures: slots read as 5 and 8), **D62** (no band check before publishing), **D66** (generator and crews only in the harness), **F29** (moss as the defender's choice), **F37** (re-running an empty pairing).

Build notes that are not register items: the client's "rehearsal" is the Workshop playtest and should be renamed before §13's rehearsal arrives; the builder names undiscovered resonances and chords (`builder_screen.gd:209–221`); the prototype's terrain editor enforces 80 points while showing 100 (js:90, 1024); the prototype's paradox warning can never appear (2.4).

---

## 8. Order of work

Provisional ids, to be merged with the other screen reports' TC.15 series.

| Id | Task | Needs | Effort |
|---|---|---|---|
| TC.20a | Terrain in the simulation: moss default and clearing, heights 0–3, the 31 missing features by family, directions and tunnels, terrain points with the budget passed in; one rules-version move | LD13, LD15, LD16 answers for directions | XL |
| TC.20b | The generator and crews in `sim/` (D66): `generator.rs`, three rehearsal crews and the reference crews, the report recorder | LD8 (facing), LD22, LD24 | XL |
| TC.20c | Stealth paths, routes with seconds, one post's sight, named landings, in the extension | TC.20a | M |
| TC.20d | The measurement queue on the server, keyed by digest, shared by curation and the Workshop; the Workshop's band check (D62) | TC.20b | M |
| TC.20e | `RealmView` edit overlays (routes, one cone, flags, cursor, ghost, hint), then the diorama's defence mode after the shell's 3D world | the shell report | M, then L |
| TC.20f | Terrain editor screen, merged with the builder; sandbox mode | TC.20a, TC.20c, TC.20e | M |
| TC.20g | Defence curation screen | TC.20b–e, Weaving pricing, LD7–LD10 | L |
| TC.20h | Rehearsal and defence log: `GET /v1/defences`, reports by re-simulation, the screen; rename the playtest | TC.20b, LD21–LD23 | L |
| TC.20i | Lab service and screen | Codex service, Aether and Insight ledgers, LD1–LD6 | L |
| TC.20j | Workshop rebuilt on the design: statistics, friends list, slots, covers, Remix and Withdraw kept | TC.20d, TC.20f | M |

The roadmap's stage SC (`tools/roadmap.py:938–1163`) has no task for any of these five screens except the Workshop's data side (TC.6, done). §26.8 counts the Workshop among the screens safe to hand over; the other four depend on simulation work first.

---

## 9. Questions only the owner can answer

1. LD2: what a Lab hint reveals, and after how many failures.
2. LD4: how the Lab names a chord at level 3 (free once a day, or an experiment).
3. LD5: Insight per discovery; which law gets the 3 pages; may an unrestored law go on a pedestal.
4. LD7: is a curation swap a weave (price, 10 minutes, the hour's rest), and may the generator change the laws a player wove for production.
5. LD8: does the owner set a guard post's facing or patrol.
6. LD9: what a curated defence's origin is, and whether it must be in band to save.
7. LD10: where the hold number comes from (server queue, on-device batch, or only the stealth-path count).
8. LD16: who sets a ramp's or rapids' direction and a tunnel's ends.
9. LD17: is there a human review before an island goes live.
10. LD19: is a Workshop island one realm or a universe.
11. LD22: the four report measures, defined for one raid.
12. LD23: may the defender see that a raid is in progress.
13. LD24: the three rehearsal crews' rules.
14. LD15: does the Workshop sandbox keep a terrain budget.

---

## 10. Captures I made

All under `scratchpad/analysis/lcrtw_shots/` (a `.png` of the phone and a `.txt` of its page text each), made with `scratchpad/analysis/lcrtw_scripts/shoot.mjs` against the prototype served by `serve.mjs`:

- **Lab**: lab_default, lab_running, lab_result_known_or_new (NEW: Held vigil), lab_after_fly, lab_cleared, lab_two_picked, lab_result2 (A STIR on No. 04), lab_paradox_warning (Stillness + Half gravity: no warning), lab_result3 (NEW: Frozen fall), lab_result4 (A STIR), lab_locked_tap.
- **Curation**: cu_default, cu_tight, cu_laws, cu_swap, cu_river_across, cu_posts (BEST marker and facing dial), cu_post_turned, cu_testrun_mid, cu_testrun_done, cu_name, cu_saved.
- **Rehearsal and log**: rh_default, rh_greedy, rh_fast, rh_log, rh_log_bottom, rh_report0 (Marta), rh_report0_bottom, rh_report1, rh_report3.
- **Terrain**: te_default, te_sight, te_fam_Ground, te_fam_Water, te_fam_Rock, te_fam_Light, te_fam_Heat, te_fam_Built, te_locked_sel (Tunnel, Keeper 10), te_erase.
- **Workshop**: ws_top, ws_bottom, ws_ladder, ws_name, ws_published, ws_pubsheet, ws_pubsheet_bottom, ws_discover, ws_discover_bottom, ws_spotlight, ws_disc_new, ws_disc_friends.
- The terrain-table comparison: `scratchpad/analysis/lcrtw_scripts/teft.mjs` (design's 39 against `content/terrain.json`).
