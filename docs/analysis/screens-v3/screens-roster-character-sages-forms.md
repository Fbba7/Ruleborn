# Roster, Character, Sage hall and Forms album: Screens v3 against v3.6, and the Godot build

The four "Crew" screens of Screens v3, read against design document v3.6, and a plan for building them in the client on the architecture already in `client/` and `server/`. Sections are cited as §N.M (v3.6, `docs/design/ruleborn-game-design-v3.6.txt`), files as path:line. Nothing in the repository was edited.

## 0. What was read, and how

- **The document**: §23.2 (rows for the four screens, :11201-11320), §23.5 in full (:11383-11560), §11.1-§11.11 (:5922-6870), §9.1 (Insight, :4392), §9.2 (best workers, :4422-4500), §9.5's price list (:4600-4625), §10.2's Hearth, Nursery and producer rows (via `content/buildings.json`), §12.5 (:6938), §12.9 (:7072), §12.20 (:7389), §14.2/§14.3 (Keeper unlocks and the "Main Sage" rows, :8199-8215), §17.7 (:8949), §19.20 (:9922), §20.7 (:10249), §20.8 (:10286), §21.1 (:10390), §21.2 (:10413), §21.6 (:10648), §21.8 (:10986), §26.1 (:12241). v3.6 did not change any of these four §23.2 rows (`scratchpad/v36/diffs.txt`: §23.2 changed only the Result, Observatory, Rehearsal, Settings rows and added Profile).
- **The design**: `art/named/screens_meta.markup.html` blocks Roster 10-52, Character 53-123, Sage hall 124-166, Forms album 546-585; logic in `art/named/screens_meta.js` (shared helpers 168-189, Roster 190-236, Character 237-270, Sages 271-384, Forms 1179-1217, the Roster/Sages/Forms hub 1287). The supplied captures `shots/all/Gameplay_10_Roster`, `_11_Character`, `_12_Sage_hall`, `_26_Forms_album` (.png/.txt). One state each, so I rendered more states with the vendored React the sibling analyses set up: script `scratchpad/analysis/rcsf_scripts/shoot.mjs` and `shoot2.mjs`, captures in `scratchpad/analysis/rcsf_shots/` (Roster with Mo, Volt, Bramble, Hollow, Tock selected, after Wake, filtered to Resting, grid bottom; Character Heist/Stats/Compare and all 12 characters; Sage hall default, Guard chip, after "Guard Sage", Tinkerer, Gardener, Chronicler; Forms album top, Featherkin, Sparkwright, Outfits filter, bottom). In my local render the portrait PNGs and the 3D rig iframe did not load (path mapping of my server), so those captures show empty tiles; the supplied captures show them.
- **Character sheets**: `shots/chars/02_Skyskipper.txt` (the sheet page: card, level-1 numbers, 15 animations, three forms with quirks, "Download GLB for Godot ... or OBJ + MTL"), and `art/named/creatures/Skyskipper_Rig.html:52-110` (procedural clips).
- **The build**: `client/README.md`, `client/app/router.gd`, `client/app/services.gd`, `client/app/app_state.gd`, `client/core/store.gd`, `client/features/universe/*`, `client/data/repositories/universe_repository.gd`, `client/scripts/universe_screen.gd`, `client/scripts/ui.gd` (function list), `client/ui/tokens.json` (head), `client/project.godot`, `client/i18n/content.csv`, `tools/client_strings.py`; `server/src/http.mjs:1-102` (every route), `server/src/universe.mjs:1-80`, `server/src/shop.mjs:45-56`, `server/src/db.mjs:205-224`; `sim/src/lib.rs:235-300,353`, `sim/src/heist.rs:232-234`, `sim/src/replay.rs:45-90`; `content/{roles,ruleborn,traits,sages,forms,notes,laws,buildings}.json`; `tools/audit_register.py` (all 70 open items listed by title), `tools/roadmap.py:936-1165` (stage SC), `tools/economy_model/rerun.py:20-45`, `tools/design_facts.py:99-102,186-189`.

## 1. Cross-cutting facts that shape all four screens

1. **Nothing exists for these screens in the build.** No scene, script, feature, repository or route touches characters, Sages or forms. `server/src/universe.mjs:20-21`: "Staffing, production and the roster come in the home economy's later parts (G42)". `tools/roadmap.py` TC.12 (status "doing") lists "workers and production (§9.3, §5.8), the roster (§11.5), and the Codex's restorations" as next.
2. **The data is already extracted.** `content/ruleborn.json` holds all eighteen §11.11 cards (look, proportions, personality, at_home, ability, resists, best_at, sound, size, flies, role, school), checked against §11.2. `content/roles.json` holds §11.1's numbers, `content/traits.json` the 31 traits with family and effect, `content/sages.json` §11.7's four launch Sages, `content/forms.json` the 54 forms with look and quirk. The rule-sheet line of each card is in the document but I did not see a `rule_sheet` field in `ruleborn.json`'s first entry; the extractor needs to carry it (§23.5 asks that every card carry all of §11.11).
3. **None of it is in the client's word catalogue.** `client/i18n/content.csv` has laws, notes, resonances, chords, wards, ground, buildings and realms only; `tools/client_strings.py:41-55` writes those from `content/` and is the place to add ruleborn, roles, traits, Sages and forms.
4. **The simulation's crew is five fixed roles at level 1.** `sim/src/lib.rs:353` `CREW: [Role; 5] = [Scout, Breaker, Carrier, Warden, Mender]`, picked by a crew count (`World::new(_seed, crew: u8, …)`, :747); `sim/src/heist.rs:233-234` "the simulation has no traits yet"; `sim/src/replay.rs:53-90` has no ability, Sage or cast command. So the kind, level, traits and form these screens show do not yet exist in the heist the server re-simulates. That is a finding (H below), and the reason the Character screen's numbers must come from the same source the simulation will use.
5. **"Crew" names two things.** The heist crew of three to five ruleborn (§12.5) and the player group of four to eight (§17.7). The server already uses `crews` for the player groups (`server/src/db.mjs:389-400`, `/v1/crews` in `http.mjs`). The design's tab "CREW" opens the Roster. The build should name this area **roster** in code (`RosterState`, `/v1/roster`) and, unless the owner says otherwise, label the tab "Roster" (finding P).
6. **The navigation**: one tab ("CREW", `screens_meta.markup.html:41-48`) opens a hub with a three-way segmented control, Roster | Sages | Forms (`screens_meta.js:1287`, markup 12 on each block). The Character screen is pushed from the Roster (no tab bar; Back at markup 61). The sibling shell analysis (`screens-home-realm-shell.md` §1.6) plans a persistent shell with a `HubTabs` component and per-route metadata; these four routes slot into it as `tab: crew, chrome: hub` (Roster, Sages, Forms) and `tab: none, chrome: header` (Character).
7. **The common visual pattern** of three of the four screens: a hero "stage card" (portrait on a glowing pedestal, prev/next arrows, a state or tag pill, the name in Marcellus, a subline, a progress bar), a row of two big action buttons at y≈296, a chip row at y≈356, a count line, and a three-column portrait grid. Building that once as components gives three screens.
8. **Type and placement.** All four screens set most text at 8.5-12.5 px in Manrope (e.g. markup 36 "COLLECTION" 9 px; 83 "ONCE A HEIST" 8.5 px; 151 "SAGES" 9 px; 569 "FORMS" 9 px). §21.8: nothing under 13 pt, body 16, Baloo 2 for labels and numbers. Text size is listed in §23.5; the typeface is raised by sibling reports and not repeated here. Placement: the hero arrows are 28 px circles at y≈170 (Roster 18-19, Sages 132-133, Forms 554-555), Character's Back is 44 px at the top-left (61), chips are 30 px tall; §21.1 asks for 48 pt controls, frequent ones in the lower two-thirds and none in a corner. The sibling shell report's hit-rect rule covers this; I apply it in the plans below.
9. **Icons and art are ready to export.** `art/named/icons_rbi.js` (`window.RBI(group,name)`) has every icon these screens need: I checked `characterstates` (working, guarding, onaheist, resting, idle, wakeearly), `crewroles` (5), `traits` (all 31), `sagepowers` (all 12 launch powers), `lawnotes` (hush, spark, echo, flow, weight, bloom, glow; "veil" I did not check), `screens` (roster, character, sagehall, formsalbum). Portraits: `art/named/images/world_portraits_*.png` (18 kinds and 6 Sages). 3D: per-kind `<Name>_Rig.html` with procedural clips (`Skyskipper_Rig.html:52` imports `makeRig, EXPR, CLIPS`; :110 samples `CLIPS[CLIP].f(t)`), and the sheet page offers a GLB/OBJ download. I did not trace whether that GLB carries skinning or the animations.

## 2. Roster

### 2.1 The §23.2 row

> | Roster | Who does what. | Every character's state, rest timers, one-tap reassign

§23.5 rows that concern it: "Roster roles: Mo the Tidewalker is a Scout, Hollow the Echoplate a Mender → a Tidewalker is a Carrier and an Echoplate a Warden (11.2)"; "Role health in the prototype's data module: Breaker 260, Carrier 200, Mender 180 → 180, 160 and 130 (11.1)"; "Heist planner crew: takes two creatures the Roster shows resting (12.5)"; Text size; Landscape; "The designs' own notes".

### 2.2 What the design shows (top to bottom, markup 10-52, logic 190-236)

1. **Hub** (markup 12): Roster | Sages | Forms segmented control, active segment gold.
2. **Hero stage card** (markup 12-28; `ro.hero` at js:213-229): the selected ruleborn's portrait (`world/portraits/<kind>.png`) bobbing on a school-coloured pedestal with a glow; "LV 5" badge; prev/next arrows (28 px) cycling through the filtered list; on the right a state pill with icon ("Idle · Rested", "Resting · 38 min left", "On a heist · Kofi · 1:12 left", "Guarding · Heart post", "Working · Library"), the name (Marcellus 30 px), "Skyskipper · Motion", role icon + "CARRIER", a "♥ 200" chip (role health from the prototype's table, js:211), and a bar "Lv 6 costs 866 Essence" whose fill is Essence held ÷ price.
3. **Action row** (markup 29-33): a primary button whose words follow the state (js:196-200): **Assign** (idle → working at "Star Well", toast "starts at the Star Well in 5 min"), **Recall** (working or guarding → idle), **Wake · 304** (resting; price 2 × level × minutes left, refused with "Not enough Essence"), **Away** (on a heist, disabled). Then **Level up · 866 Essence** (glows green; js:228 spends and raises the level), and an "i" button (48 px) that opens the Character screen.
4. **Filter chips** (markup 34; js:230): All 12, Idle 3, Working 4, Guarding 2, On a heist 1, Resting 2, each with a coloured dot and count.
5. **Collection line and sort** (markup 35-38; js:231): "COLLECTION 12 / 18" (kinds owned out of eighteen) and a sort button cycling Level / State / School.
6. **Grid** (markup 40; js:232-236): three columns of portrait cards: level badge top-left, a state dot top-right (colour only), a role badge bottom-left, a cyan rest chip ("38m", "160m") for resting characters, a green ▲ "ready to level" badge (pseudo-random, js:232 `x2>=80`), name plate; resting and on-a-heist cards greyed. After the owned twelve, six "???" silhouettes of unowned kinds; tapping one toasts "Tidewalker · hatch one at a Nursery".
7. **Toast** (markup 41) and the five-tab bar with CREW raised (markup 41-48).

Motion: the hero portrait bobs (3 s), the glow pulses, the level-up button glows; cards lift 3 px when selected with a spring curve (js:233 `cubic-bezier(.3,1.5,.5,1)`).

### 2.3 Against the must-show list

| Must show | In the design? |
|---|---|
| Every character's state | Partly. The hero names it in words and an icon; the grid carries it as a coloured dot only (idle green, working gold, guarding violet, on a heist red, resting cyan), so idle, working and guarding tiles differ only by colour. §20.8: "no information carried by colour alone". |
| Rest timers | Yes: a minute count on resting tiles ("38m", "160m") and "38 min left" on the hero. |
| One-tap reassign | Partly. The grid has no action; a tap selects, then Assign/Recall in the hero acts, so it is two taps. Assign always sends to a Star Well (js:196); there is no way to choose which producer, and no way to put a character on a Guardian Post from here. |

### 2.4 Deviations from v3.6

| What | Design shows | Document says | Section | In §23.5? |
|---|---|---|---|---|
| Mo's and Hollow's roles | Tidewalker Scout, Echoplate Mender | Carrier, Warden | §11.2 | Yes |
| Role health | ♥ 200 for a Carrier, 260 Breaker, 180 Mender (js:211) | 160, 180, 130 | §11.1 | Yes |
| Tock's role | "Tock, Hourkeeper · Time, WARDEN, ♥ 420" (js:191; capture `roster_sel_Tock.txt`) | Hourkeeper is a Mender | §11.2 | **No**: §23.5 names only Mo and Hollow |
| Locked-kind table | `ALL18` lists Tidewalker as a Scout and Sparkwright as a Breaker (js:205) | Carrier; Mender | §11.2 | No (not visible on screen: locked tiles show "???") |
| Where characters work | "Working · Library" (Hollow), "Working · Storehouse" (Pebble) (js:191) | Working is producing in one building; worker slots exist only on Star Wells, Aether Springs and Gardens | §11.6, §9.2, §10.2 | No |
| Traits per character | Mo, Facet, Wick, Pebble, Fern, Volt, Shard have one trait; Tock none (js:191) | Every ruleborn is born with two (strays three) | §11.3, §11.5 | No |
| Health and level | Health is the role's level-1 figure at every level; Level up offered with no ceiling | +8% health and power, +5% carry a level; highest level = 2 × the level of the Hearth the character lives in, up to 10 | §11.4, §9.5 | No |
| Assign destination | Always "Star Well" | The decision is which producer goes short (§9.2); guarding is a separate assignment (§11.6) | §9.2, §11.6 | No |
| State on tiles | Colour dot only | No information by colour alone | §20.8 | No (text size and landscape are listed, colour-only is not) |
| TRY note | "Level up glows green when XP is full" | Levels bought with Essence | §11.4 | Yes (the Character row's XP bar) |

What the design gets right and the build keeps: the level price (js:210 `150 × 1.55^(lv−1)` for the next level = §11.4's `150 × 1.55^(n−2)`: 866 for level 6, 559 for level 5); the wake price (js:199 `2 × lv × minutes`, = §9.5: Mo at level 4 with 38 minutes left, 304); the five states of §11.6 with their names; production starting 5 minutes after assignment (§11.6); "Away" while on a heist.

### 2.5 Silent adoptions (document silent, no rule broken)

- The Roster | Sages | Forms hub under one tab.
- The hero stage card with arrows, the state-led primary action (Assign / Recall / Wake · price / Away), Level up beside it, "i" for detail.
- Filter chips by state with counts; sort by level, state, school.
- Collection count of kinds owned, with silhouettes of unowned kinds and a hint to hatch (the denominator must come from content, since §26.1 adds three kinds a season).
- A "can level now" badge on tiles, if it means "Essence enough and under the Hearth ceiling" rather than the prototype's random flag.
- Toasts confirming each change.

### 2.6 What the build has today

Nothing on the client. No roster on the server: no table of characters, no states, no rest, no assignment, no waking, no levels, no births (`server/src/http.mjs:1-102` lists no such route). The ledger books Starlight and Essence only (`server/src/db.mjs:212-224`), which is enough for waking and levels. `GET /v1/universe` (universe.mjs) knows buildings and their levels, so Hearth levels, worker slots and Guardian Posts can be read from it. `tools/design_facts.py:189` has the roster's keep (0.25) and :102 the starting Heart (with a Hearth, F56).

### 2.7 What the server needs

A roster slice, `server/src/roster.mjs`, behind these routes (names are proposals):

- `GET /v1/roster` → `{now, essence, places: {used, total, spire: {used, of: 3}, hearths: [{realm, level, homes, used, top, restCut}]}, characters: [...] , kinds: {owned, total}}`, each character `{id, kind, name, level, top, home, traits[], form, origin, state, where: {realm, kind, n}|null, since, producingFrom, restUntil, wake: {price}|null, next: {level, price, blocked: "essence"|"hearth"|"top", needs}, numbers: {health, speed, power, carry}, nextNumbers, work: [{kind, bonus}]}`. The server computes every number and every "why not", as `universe.mjs` does for buildings, so the device never re-derives a rule.
- `POST /v1/roster/:id/assign {realm, kind, n}` for a producer slot (slots by building level, §10.2: 1 at levels 1-3, 2 at 4-6, 3 at 7-10) or a Guardian Post (one ruleborn a post, §13.4). Refuses `resting`, `on_heist`, `slot_taken`. `producingFrom = now + 5 min` (§11.6).
- `POST /v1/roster/:id/recall`.
- `POST /v1/roster/:id/wake {restUntil}` (names the rest it ends, so a retry is answered as made, never charged twice; price §9.5).
- `POST /v1/roster/:id/level {to}` (price §9.5/§11.4; refused above `2 × Hearth level` or 10).
- The starting five (§11.5: three wake in the first minute, two strays after the first heist) created with the account; F56's starting Heart already has a Hearth.
- Heist integration, owned by the planner but needed for "rest timers" to be true: `POST /v1/leases` takes the chosen crew and Sage, refuses resting members (§12.5) and crews above the Keeper level's size, marks them on a heist; settlement sets each member's `restUntil` from §12.9's outcome (45/60/180, 180 for a caught member), shortened by the home Hearth (§11.6) and moved by Loyal and Sleepy (§11.3), which needs the rules in finding N.
- Births at a Nursery, so the roster grows: a separate route and screen (finding G).
- `GET /v1/balance` adding Aether and Insight is the shell's need too.

### 2.8 The plan (Godot 4.7, on the existing architecture)

Layers as `client/README.md` lays them out, modelled on the universe feature (`features/universe/*`, `data/repositories/universe_repository.gd`, `scripts/universe_screen.gd`):

1. **Repository**: `data/repositories/roster_repository.gd` (`view()`, `assign(id, realm, kind, n)`, `recall(id)`, `wake(id, rest_until)`, `level(id, to)`), each a `Result`; online only, like every spend (G41). Register in `app/services.gd` beside `universe`.
2. **State**: `features/roster/roster_state.gd`, slice `ROSTER` = `{view, busy, error, detail, last, changes, selected, filter, sort, clock_offset}`; reducers `roster_asked`, `roster_loaded`, `roster_failed`, `roster_change_asked`, `roster_changed`, `roster_selected`, `roster_filtered`, `roster_sorted`. Same race rule as `UniverseState.loaded` (a fetch answered after a change keeps the newer view).
3. **Controller**: `features/roster/roster_controller.gd` on `Services` (so leaving mid-change loses nothing): `load_roster()`, `assign`, `recall`, `wake`, `level`, one change at a time. After a level-up it dispatches nothing to the Keeper bar (§14.2 pays experience for Starlight spent only).
4. **Presenter**: `features/roster/roster_presenter.gd`, pure: `screen(slice, now_ms)` → `hero` (name, kind, school mark via `UI.school_mark`, role words, state words with glyph, where, rest left as "38 min", health, level, `action` {words, key, can, why}, `level_up` {words, price, can, why}), `chips` (state, words, count), `grid` (id, name, level, role, state icon id, rest words, school shape, dimmed, can_level, spoken), `locked` (kinds not owned), `collection` ("12 of 18"), `places` ("12 of 14 homes"). Every disabled control says why in words (`UniversePresenter.offer` is the pattern). Rest left is computed from the server's `restUntil` and `now` with the clock offset, so a countdown never needs a fetch; a `Timer` in the screen refreshes only the labels once a second.
5. **One-tap reassign**: the tile itself carries the action. A tap on a tile's action plate does the obvious thing for its state: idle → assign to the default slot, working/guarding → recall, resting → wake (asks once, since Essence is spent, as the universe screen asks twice before buying). The default slot is the open producer slot with the largest §9.2 bonus for that character (school +15%, trait +25%), then the least-staffed producer; named on the button ("Work · Skyfield Star Well +15%"). A long press or "Other…" opens a sheet listing every open slot and post with its bonus. The default rule should be the one the economy model uses (finding M, G22).
6. **Screen**: `scenes/roster.tscn` + `scripts/roster_screen.gd`, mounted in the shell (`tab: crew, chrome: hub`). Draws only the presenter's output; holds no state beyond focus. Route `&"roster"` in `app/router.gd:8-22`.
7. **Components** (new, built from Screens v3 and named so Claude Design's tokens land in one place): `StageCard` (portrait or 3D slot, pedestal, glow, arrows with 48 pt hit rects even where the circle is 28 px, a tag pill, title, subline, bar), `StatePill` (icon + words), `ActionRow` (two big buttons + square "i"), `FilterChips` (scrolling, 48 pt hit rects), `PortraitTile` (portrait texture, level badge, role badge, **state icon instead of a dot**, rest chip, can-level badge, school shape, a silhouette shader for locked kinds, a spoken name such as "Mo, Tidewalker, level 4, resting, 38 minutes left"), `PortraitGrid` (three columns in a `ScrollContainer`; at most 38 tiles, so no virtualisation), `Toast` (reuse `UI.banner`). Text at §21.8's sizes (13 pt floor), so the grid is three columns at 390 pt and two at 200% text.
8. **Assets**: `tools/export_icons.mjs` (Node, `window` shim) writes `client/ui/icons/<group>/<name>.svg` from `icons_rbi.js`; check that Godot renders the SVG `<text>` the library uses in places (the sibling report flags this). Copy the 24 portrait PNGs to `client/art/portraits/`.
9. **Words**: `ROSTER_*` keys in `i18n/strings.csv` (states, actions, reasons); kind, role and trait names from `content.csv` via `tools/client_strings.py`.
10. **Tests**: `tests/roster_tests.gd` (reducers; presenter for every state, the wake price from `restUntil`, each blocked reason, filters, sorts, locked kinds, spoken names; flows against `FakeTransport`), the end-to-end loop in `client/status.py` (assign, recall, wake, level against the real server), `server/test/roster.test.mjs`. `tests/a11y_tests.gd` and `tools/client_contract.py` cover the rest by themselves once the new refusal codes have words.

Effort: **XL** with the server's roster slice; the client screen alone is L.

## 3. Character

### 3.1 The §23.2 row

> | Character | One ruleborn in detail. | School, role, ability, traits, level, best work

§23.5: "Character screen: an XP bar, 'once a heist', resists no-jump zones, a power score → levels bought with Essence; two uses; Skyskipper resists Leapfrog's noise; no power score (11.2, 11.4, 11.11)"; the role-health row; and the character-sheet rows (per-kind level-1 stats on fifteen sheets → by role; eight cards drop the rule sheet and sound; eleven kinds carry a kind-specific accessory; six specs lack the school marking; Matter's shape is a cube) which govern the model shown on this screen.

### 3.2 What the design shows (markup 53-123, logic 237-270)

1. **Full-bleed stage** (55-60): a radial school-coloured glow, conic rays, a pedestal, and the kind's 3D model playing its idle clip (an iframe of `<Kind> Rig.html?embed=1&clip=idle`, 59; portrait fallback `rigImg`). Swipe left/right over it (60) or the 38 px arrows (64-65) to move through the roster; "1 / 12" counter (62); state pill top-right "Idle · Rested" (63); Back top-left (61).
2. **Name plate** (66-69): "Pip" in Marcellus 28 px on a gold-rimmed plate; "MOTION" school pill and "Skyskipper · Carrier".
3. **Level row** (70-74): a gold hexagon "LV 5", an XP bar "588 / 600 XP", a "★ HEALTH 200" chip.
4. **Tabs** (75-77): Heist | Stats | Compare.
   - **Heist** (79-94): an ability card ("ABILITY" + "ONCE A HEIST" tag, ability name in Marcellus, description), then four cards: role ("CARRIER · Carries the loot"), RESISTS, TRAITS (names joined), AT HOME (a work bonus).
   - **Stats** (95-101): four cards SPEED, STEALTH, CARRY, GRIT, each a 1-10 value with ten pips and a green "+1" for what the next level adds; "NEXT LEVEL: +5% carry and a shorter rest".
   - **Compare** (102-110): the other eleven ruleborn as round portraits; the chosen pair's four stats as mirrored bars, the larger in green.
5. **Bottom** (112-118): a 70 px "HEIST" button to the planner; a big green **UPGRADE** button "Lv 5 → 6 · +539 power" with the Essence price "866" (locked state with a padlock when not ready).

### 3.3 Against the must-show list

| Must show | In the design? |
|---|---|
| School | Yes, written ("MOTION") in a school-coloured pill. The school's shape (§21.2) is not shown. |
| Role | Yes. |
| Ability | **No, for 17 of 18 kinds.** The text comes from a five-entry table keyed by role (js:240 `RA`), so every Scout shows "Keen eyes: reveals every guard and ward within 6 tiles for 6 s" (Lantern Wisp's ability, also shown for Mo, Wick and Volt), every Warden "Hold the line: blocks one guard for 4 s" (no kind has it), every Breaker "Shoulder charge: smashes one door, wall or pylon in a single hit" (no kind has it), every Mender "Patch up: restores one heart to every crew member within 3 tiles" (there are no hearts), every Carrier "Stuff the satchel" (right for Skyskipper only; shown for Prism Mite too). Captures `rcsf_shots/char_n01`-`n11`. |
| Traits | Names only ("Swift · Lucky"); no effects. |
| Level | Yes, with the XP bar §23.5 lists. No ceiling or reason. |
| Best work | **No.** The "AT HOME" card shows a role-keyed bonus ("Star Well · +12%", "Quarry · +12%", "Lantern post · +10% sight", "Guard post · +1 hearing", "Garden · +10%", js:240) instead of §11.11's "Best at" and §9.2's bonus. |

### 3.4 Deviations from v3.6

| What | Design shows | Document says | Section | In §23.5? |
|---|---|---|---|---|
| XP bar, "once a heist", no-jump zones, power score | as listed | as listed | §11.2, §11.4, §11.11 | Yes |
| Health chip | role table's 200/260/180/420/120 (js:268), never level-scaled | §11.1 by role, +8% a level | §11.1, §11.4 | Partly (the role-health row; level scaling no) |
| **Ability** | five role-keyed abilities (js:240) | eighteen, one per kind, on §11.11's cards, "the one home for every ability" | §11.11, §11.2 | **No** (only "once a heist" is listed) |
| **Resists** | keyed by school (js:260 `RZS`): Time "Slow rivers, Stillness", Motion "No-jump zones", Matter "Crumbling ground", Energy "Static shocks", Life "Spores", Spirit "Lantern glare" | one law family per kind: e.g. Hourkeeper Delay, Mossbear Thorns, Echoplate Echoes, Lantern Wisp Glowing dark, Glass Golem half damage from Spark laws, Emberling Heat bloom and ember vents | §11.2, §11.11 | **No** (only Skyskipper's is listed) |
| **Stats tab** | SPEED, STEALTH, CARRY, GRIT on a 1-10 scale, base by role plus `floor(level/3)` plus a +1 from the parity of the name's length (js:211, 242-243) | Health, speed, power, carry (§11.1); +8% health and power and +5% carry a level; abilities 20% stronger at 4, 7, 10 | §11.1, §11.4 | **No** |
| **Next-level perk** | per role: "+5% carry and a shorter rest", "+1 tile of sight and quieter steps", "+10% damage to doors and pylons", "+1 s on Hold the line", "+10% healing" (js:241) | the same growth for every role (above) | §11.4 | **No** |
| **"AT HOME" / best work** | role-keyed bonus; "Quarry" and "Lantern post" are not buildings; sight and hearing bonuses | §9.2: +15% for ruleborn of the building's schools (Motion and Matter at Star Wells, Time and Energy at Aether Springs, Life and Spirit at Gardens), +25% for Well-digger, Spring-finder, Green thumb; §11.11's "Best at" (e.g. "Carrying, Star Wells"); §11.11's "At home" is the habit ("Practises hops over a fence until it trips") | §9.2, §11.11, §10.2 | **No** |
| Trait data | `TR` (js:239) gives Quiet "footsteps heard 1 tile closer", Sturdy "+1 heart on a heist", Loyal "never wanders off a post", Tinker "repairs wards 20% faster", Brave "keeps moving when spotted", Hoarder "+10% bag space", Greedy "+15% loot, louder footsteps", Clumsy "sometimes drops a coin", Shadow "hidden in shade from 2 tiles", and assigns each a rarity | §11.3's effects (Quiet: guards notice it 25% later; Sturdy +15% health; Loyal rests 25% less after a success; …) | §11.3 | No; not rendered today (the screen shows names only), but it is the text a builder would copy |
| A seventh school | `RZ`/`RZS` carry "Mind: Illusory guards" (js:240, 260) | six schools | §5.2 | No; not rendered |
| Tock | "Hourkeeper · Warden", HEALTH 420, "Hold the line" (capture `char_n10.txt`) | Mender | §11.2 | No |
| Form | not shown | every ruleborn has a form that changes its look and one quirk | §11.10, §11.11 | — (omission) |
| Paradox-born | the screen assumes a role (`RA[role]`) | paradox-born have no role; their numbers and gift are in §11.8 | §11.8 | — (the build must handle it) |

### 3.5 Silent adoptions

- The full-bleed stage with the 3D model idling on a pedestal, swipe and arrows through the roster, the "n / N" counter.
- The name plate, school pill, kind · role line, level hexagon.
- The Heist | Stats | Compare tabs, **if** Stats shows §11.1's four numbers at the character's level and the next level's, and Compare compares those plus resistances.
- The HEIST shortcut to the planner (it should say why when the character is resting or on a heist, since resting characters cannot go, §12.5).
- The big UPGRADE button with its Essence price, keeping the price and changing the subline to the next level's numbers.
- The guard form (sash and lantern, §21.6) on the pedestal when the character is guarding, and the nap clip when resting, are the document's own art and fit here.

### 3.6 What the build has today

Nothing on the client. The text is in `content/ruleborn.json` (card), `content/roles.json` (numbers), `content/traits.json`, `content/forms.json`. No 3D creature in the client (`client/project.godot:27-28` uses `gl_compatibility`, which draws 3D; no `Node3D` in any script). The client is on Godot 4.5 (`project.godot:12`; `client/ext` built for `api-4-5`); v3.6's engine row pins 4.7.2 and godot-rust 0.5.5 with `api-4-7`.

### 3.7 What the server needs

Nothing beyond the roster view, if `GET /v1/roster` carries for each character its numbers at its level with its traits applied, the next level's, its form, its work bonuses by producer kind, its ceiling and the reason, and its origin (realm and laws it was born under, since law-linked traits come from there, §11.3). The ability's level steps (4, 7, 10) need finding K's rule before the numbers can be shown.

### 3.8 The plan

1. **Presenter**: `features/roster/character_presenter.gd`: `detail(slice, id, tab)` → `header` (name, kind, school mark with its shape glyph, role, level, state), `ability` (name from §11.11 if the card names one, else the kind; the card's ability sentence, "Two uses a heist, 10 s lockout", its rule-sheet line; the next ability step "Stronger at level 7"), `cards` (Role and its job from §11.1; Resists from the card; Traits with effects from §11.3; **Best at** from the card plus the server's §9.2 bonuses, e.g. "Carrying, Star Wells · +15% at Star Wells"), `form` (note, symbol, quirk from `content/forms.json`), `stats` (Health, Speed, Power, Carry now and next level, from the server), `compare` (two characters' four numbers and resists), `upgrade` (price, can, why). The card text comes from the catalogue (`content.csv` rows written by `tools/client_strings.py` as `RULEBORN_<ID>_ABILITY` etc.), the numbers from the server, so one fact has one home.
2. **Screen**: `scenes/character.tscn` + `scripts/character_screen.gd`, route `&"character"` with `{"id": …}`; `chrome: header` (Back in the lower band per the sibling report's placement rule), swipe and 48 pt arrows. Components: `NamePlate`, `LevelHex`, `NumberChip`, `Segmented`, `AbilityCard`, `InfoCard` (2 × 2), `StatCard` (value, next value, pips), `CompareRow`, `PriceButton`.
3. **The 3D stage** (`scenes/components/creature_stage.tscn`): `SubViewportContainer` (stretch) → `SubViewport` (transparent background, `own_world_3d`, MSAA 2×) → `Node3D` with a `Camera3D` framing the pedestal, a key and a fill `DirectionalLight3D`, the pedestal mesh, and a model slot. The model is `res://art/creatures/<kind>.glb` with an `AnimationPlayer`: idle and idle 2 alternating, nap when resting, the guard form when guarding, celebrate after a level-up; the form is a material override (pattern, glow) and one accessory node per note (§21.6: "54 forms need 18 models"). Reduced motion holds a still pose (§20.8). The portrait PNG is the fallback while the GLB loads, on low-end devices, and in tests. Only this screen holds a 3D viewport; grids use PNGs.
4. **Getting the models**: the rigs' clips are procedural (`CLIPS[name].f(t)`, `Skyskipper_Rig.html:52, 110`), so a GLB without baked tracks would stand still. `tools/bake_creatures.mjs`: open each `<Name>_Rig.html` in headless Chromium (Playwright is installed, as the captures show), sample the fifteen clips at 30 fps into `AnimationClip`s on the rig's named parts, and call three.js's `GLTFExporter` with `{binary: true, animations}`. Check each against the §23.5 sheet rows (role accessory, school marking, Matter's cube) before import. I did not run this; whether the rig modules expose the parts as bones or as transformed meshes decides whether the tracks are skeletal or node tracks.
5. **Tests**: `tests/character_tests.gd`: the ability, resist and best-at text for all eighteen kinds equal the content (a generated assertion, so the screen can never drift back to role-keyed text), the paradox-born layout (no role), stats from the server, every blocked reason, a11y names.

Effort: **L** (the 3D pipeline is most of it).

## 4. Sage hall

### 4.1 The §23.2 row

> | Sage hall | Heroes. | Powers, levels, guardian choice

§23.5: no row for this screen beyond Text size, Landscape and the designs' notes. §11.7 (v3.6) adds that the post-launch Sages' power names on their sheets are placeholders; the hall shows none for them, which agrees.

### 4.2 What the design shows (markup 124-166, logic 271-384)

1. **Hub** (126).
2. **Hero stage card** (126-140): the Sage's portrait on a school-coloured pedestal with slowly turning rays; "LV 4" badge (or "LOCKED"); arrows; a tag "HEIST SAGE" / "GUARD SAGE" / "KEEPER LEVEL 13" / "LATER SEASON" / "RESTING" (js:359); "The Archivist", "Spirit Sage · 3 powers"; a role line ("Joins every heist with your crew." / "Defends your realms while you are away." / for a locked Sage its on-guard text); a bar "Level 4 / 40 · levels with Insight" (or "Keeper level 9 / 13" when locked, js:364-365).
3. **Two role buttons** (141-144): HEIST SAGE and GUARD SAGE. Choosing one for the Sage who holds the other swaps them (js:306); a locked Sage's buttons toast "Unlocks at Keeper level 13".
4. **Chips** (145): one per power (Suspend, Reveal, Recall) and "Guard".
5. **Detail card** (146-149): the chosen power's icon, name, description and a tag ("1 USE", "PREVIEW · 1 USE" when locked); for Guard, "On guard: When an alarm sounds, the crew is shown to every guard for 5 s. At home: lab experiments run 20% faster" (js:349).
6. **"SAGES 2 / 6"** and a three-column grid (150-153) of the six Sages: level badge, a heist or guard badge, silhouettes with padlocks for the locked four.
7. Tab bar (155-165).

The data (js:272-278) gives the four launch Sages §11.7's unlocks (start, Keeper 7, 13, 20), powers with uses, at-home and on-guard effects nearly word for word; the Chronicler and the Lamplighter are "A later season" with no powers.

### 4.3 Against the must-show list

| Must show | In the design? |
|---|---|
| Powers | Yes, all three per Sage with uses, and on-guard and at-home effects. The "20 s" cooldown appears only in an unused tag (js:330). Powers are shown at their base values whatever the Sage's level. |
| Levels | **Partly.** A level number and a bar, but no Insight balance, no price for the next level (§9.5: 15 × 1.13^(level−1)), no way to level, and nothing about what the next fifth level improves. The bar is also drawn at level × 10% of a 40-level scale (js:364), so level 4 fills 40% of it. |
| Guardian choice | Yes: the two role buttons with swapping, and badges on the grid. |

### 4.4 Deviations from v3.6

| What | Design shows | Document says | Section | In §23.5? |
|---|---|---|---|---|
| Levelling | display only | "Sages level from 1 to 40 with Insight", priced in §9.5; "every fifth level improves one power" | §11.7, §9.5 | No |
| An unassigned Sage | tag "RESTING", "Resting. Pick a role below." (js:359, 361) | Resting is a ruleborn state with a timer after a heist; Sages have no rest | §11.6, §11.7 | No |
| Heist Sage at Keeper 1 | the Archivist offered as heist Sage from the start | "Sage: One, from Keeper level 2" (§12.5); §14.2's level-2 row "Sages join heists" | §12.5, §14.2 | No |
| Count | "2 / 6" including two post-launch Sages | four at launch, two more in the first year | §26.1, §11.7 | No (minor) |
| Bar fill | level × 10% | 4 of 40 is 10% | — | prototype bug |

### 4.5 Silent adoptions

- The hero stage, the two role buttons with swap, the per-power chips with a detail card, the grid with role badges and silhouettes, locked Sages' powers shown as a preview with the Keeper level they open at and the player's progress toward it.
- A school per launch Sage (Archivist Spirit, Tinkerer Matter, Gardener Life, Wanderer Motion), used for colour only. §11.7 gives schools only to the Chronicler (Time) and the Lamplighter (Energy); a school on a launch Sage is adoptable as long as no rule reads it. Note that §21.6 describes the Archivist in a deep violet robe and the Wanderer in indigo and silver, which the portraits carry; the frame colour is the school's.
- "HEIST SAGE · Joins every heist you launch" as the planner's default Sage, if the planner can still change it per heist (§12.5 makes the Sage a per-heist choice).

### 4.6 What the build has today

Nothing. `content/sages.json` has the four launch Sages as §11.7's prose (`heist_powers` and `at_home` are sentences, not fields), so the extractor should split each power into name, sentence and uses. There is no Insight anywhere: not in the ledger (`server/src/db.mjs:212-224`), not in `GET /v1/balance`, not in the economy model (`tools/economy_model/rerun.py:39` lists "the main Sage's levels (Insight, 11.7)" as not modelled). The simulation has no Sage power (`sim/src/replay.rs:53-90`), and the guardian Sage's on-guard power is part of §13.2's detection-and-response layer that the hold measurements assume.

### 4.7 What the server needs

- `GET /v1/sages` → `{insight, keeperLevel, heist, guardian, sages: [{id, unlocked, unlocksAt, level, top: 40, next: {price, blocked}, powers: [{id, uses, seconds, …} at this level], atHome, onGuard}]}`.
- `PUT /v1/sages/roles {heist, guardian}`: refused when locked, when both are the same Sage ("another", §11.7), or a heist Sage below Keeper level 2.
- `POST /v1/sages/:id/level {to}`: price §9.5, paid in Insight.
- An Insight column in the ledger (db.mjs's added-columns mechanism at :636) and Insight paid at settlement for a successful heist and for Lab discoveries, which needs finding I's amounts.
- The guardian Sage's on-guard power in the defender's island when a heist starts, and the heist Sage's three powers in the simulation and the replay (heist analysis's scope; listed so it is not lost).

### 4.8 The plan

`features/sages/{sage_state,sage_presenter,sage_controller}.gd`, `data/repositories/sage_repository.gd`, `scenes/sages.tscn` + `scripts/sage_screen.gd` (route `&"sages"`, `tab: crew, chrome: hub`). It reuses `StageCard`, the role buttons as two `PriceButton`-style toggles that say what will change ("Make guard Sage · swaps out the Tinkerer"), `FilterChips` for powers, `DetailCard`, `PortraitGrid`. Add an Insight line on the stage ("Level 4 of 40 · next level 23 Insight · you have 14") and a level-up button once finding I is answered; until then the hall ships with levels shown and the level-up absent, and says so. Powers' numbers come from the server at the Sage's level. Tests: `tests/sage_tests.gd` (swap rules, Keeper gates, locked previews, the post-launch Sages hidden or teased per the owner's answer). Effort: **M** (plus the Insight currency on the server).

## 5. Forms album

### 5.1 The §23.2 row

> | Forms album | The creature collection. | 54 forms by kind and note, how to hatch each, trades

§23.5: no row for this screen beyond Text size, Landscape and the designs' notes. The character-sheet row about forms ("each has … its three forms") agrees with §11.10.

### 5.2 What the design shows (markup 546-585, logic 1179-1217)

1. **Hub** (548).
2. **Hero stage card** (548-562): the selected kind in the selected note, coloured by the note (Hush violet, Spark gold, Echo cyan), as a silhouette when not hatched; a note badge with its symbol ("ECHO"); a tag "HATCHED" / "NOT YET HATCHED"; "Echo Skyskipper", "Motion · Echo form"; three round form buttons with the note symbols and a ✓ on hatched ones; a bar "2 / 3 forms of Skyskipper" (or "All 3 forms · outfit unlocked").
3. **Two buttons** (563-566): **USE THIS LOOK** when hatched (toast "Echo Skyskipper is now its look") or **FIND A NURSERY** when not (toast "Hatch it in a realm with Stillness"); and **OUTFIT** "2 / 3 forms" or "✓ OUTFIT · Worn on heists".
4. **Chips** (567): All 18, Outfits 3, Missing 15.
5. **Count line** (568-571): "FORMS 28 / 54" and per-note counts with symbols (12 Hush, 7 Spark, 9 Echo).
6. **Grid** (572): eighteen kind tiles, each with three note pips top-left (coloured dots), an "OUTFIT" ribbon when all three are hatched, the portrait (silhouette when none hatched), the name.
7. Tab bar.

### 5.3 Against the must-show list

| Must show | In the design? |
|---|---|
| 54 forms by kind and note | Yes: eighteen tiles × three pips, per-note totals, the hero for any one form. The quirk each form carries (§11.10: Hush noticed 10% later, Spark +5% power, Echo returns once at 20%) is not shown anywhere. |
| How to hatch each | **Partly.** One toast naming one law; the hint table is wrong in two places (below); and §11.10's rule is a majority, not a presence: "whichever of the three notes is carried by the most laws in the Nursery's realm, crown laws included, sets the form", with the odds shown before hatching on a tie. |
| Trades | **No.** Nothing on the screen. §11.10 starts trading in version 1.1 (finding F). |

### 5.4 Deviations from v3.6

| What | Design shows | Document says | Section | In §23.5? |
|---|---|---|---|---|
| **USE THIS LOOK** | a hatched form becomes the kind's look (js:1204-1205) | a ruleborn hatches in the form its Nursery's laws decide, and the form changes the look and one quirk; nothing re-skins a ruleborn afterwards | §11.10, §11.11, §21.6 | **No**: it adds a mechanic, and a look apart from its quirk would mislead a raider reading a guard |
| Hatch hints | `NEX` (js:1181): Spark "Frictionless, Static or **Thorns**"; Echo "Whispers, Echoes or **Day and night**" | Thorns carries Bloom and Weight; Day and night is not a launch law (`content/laws.json`: launch Spark = Frictionless, Brittle stone, Haste, Chain lightning, Static; launch Echo = Bounce, Regrowth, Whispers, Echoes, Sleepwalk) | §7.7, §7.10, §11.10 | No |
| Skiff sail | not shown | "completing one note across every kind unlocks a skiff sail" | §11.10 | No |
| Note pips | coloured dots, no symbol (js:1212) | "every note a symbol"; no information by colour alone | §20.8, §21.2 | No |
| Denominators | fixed 18 and 54 | +3 kinds a season; +18 forms with each note added | §26.1, §11.10 | — (build reads content) |

### 5.5 Silent adoptions

- The hero stage per kind and note, form buttons with ✓, kind progress, the outfit button with progress, filter chips (All, Outfits, Missing), per-note totals with symbols, the grid with an OUTFIT ribbon.
- "Worn on heists" for the album outfit (where a cosmetic shows is not a rule).
- Silhouettes for unhatched forms.

### 5.6 What the build has today

`content/forms.json` (54, with look and quirk, notes recomputed from the launch laws). Nothing else: no record of forms hatched, no births, no outfits or sails. `server/src/shop.mjs:51-56` lets an outfit be worn by a crew **role** only (G28's reading), while the album's outfit belongs to a **kind**; `server/src/cosmetics.json` has no items (D64).

### 5.7 What the server needs

- `GET /v1/forms` → `{total, kinds: [{kind, hush, spark, echo, outfit}], notes: {hush: {count, of, sail}, …}, nurseries: [{realm, notes: {hush, spark, echo}, decides: note|null, odds}]}`. "Hatched" is a record kept when a ruleborn is born or joins, so the album does not shrink when a ruleborn leaves (trading, 1.1).
- The Nursery hatch route (finding G) writes that record and decides the form from the realm's woven laws and crown laws (§11.10), which the server knows from the published island bundles.
- Outfits and sails as earned cosmetics: `shop.mjs`'s `TARGETS.outfit` extended to kinds (or a separate `kind_outfit` kind that is never sold), a `skiff_sail` kind, and `POST /v1/cosmetics/equip` (exists) to wear them.

### 5.8 The plan

`features/forms/{forms_state,forms_presenter,forms_controller}.gd`, `data/repositories/forms_repository.gd`, `scenes/forms.tscn` + `scripts/forms_screen.gd` (route `&"forms"`, `tab: crew, chrome: hub`). Reuses `StageCard`, `FilterChips`, `PortraitGrid` and adds `NotePips` (symbol plus colour) and `FormButton`. The presenter's "how to hatch" is computed, not typed: for the selected note, the player's Nurseries and which note each decides now ("Your Tidehold Nursery hatches Hush now: Stillness, Delay; one more Echo law there than Hush laws hatches Echo"), and the launch laws that carry the note, from `content/laws.json`. Replace USE THIS LOOK with "Show mine" (the ruleborn of this kind and form the player owns, opening the Character screen). Show the quirk under the form buttons and the three sails' progress in the count line. The hero can use the 3D stage of the Character screen with the form's material override, or the portrait tinted, for a lighter first version. Tests: `tests/forms_tests.gd` (counts from content, outfit and sail rules, hatch guidance for a tie and for no note, symbols spoken). Effort: **M**.

## 6. Findings for the register

Each is new: not in §23.5 and not an open register item (I listed all 70 open items and searched the closed ones for Insight, Sage levels, trait rarity, trades, sails, Hearth ceilings, reassign, "+8%", "20% stronger").

- **A. The Character screen's ability and resistance are keyed by role and school, not by kind** (deviation, significant). §11.11 is "the one home for every ability", one per kind, and each kind "resists exactly one law family". The design's tables `RA` (screens_meta.js:240) and `RZS` (:260) give five abilities and six resistances; 17 of 18 abilities and most resistances on screen are wrong (captures `rcsf_shots/char_n01`-`n11`: Mo the Tidewalker "Keen eyes … Slow rivers, Stillness"; Bramble the Mossbear "Hold the line … Spores"; Hollow the Echoplate "Patch up … Lantern glare"). §23.5 lists only "once a heist" and Skyskipper's "no-jump zones". Rec: the build reads ability, rule sheet and resists from `content/ruleborn.json`; add a §23.5 row; a test asserts all eighteen against the content.
- **B. The Character screen's Stats tab and next-level perk invent numbers** (deviation, significant). SPEED/STEALTH/CARRY/GRIT on a 1-10 scale with a +1 from the name's length (js:211, 242-243) and five role-keyed perks (js:241) against §11.1's four numbers and §11.4's one growth rule. §23.5 lists only "a power score". Rec: Health, Speed, Power, Carry at the level and the next; a §23.5 row.
- **C. "AT HOME" shows a role-keyed work bonus, in buildings that do not exist** (deviation, significant: it shows an earning rule the document does not have). js:240's "Star Well · +12%", "Quarry · +12%", "Lantern post · +10% sight", "Guard post · +1 hearing", "Garden · +10%" against §9.2's +15% by school and +25% by trait and §10.2's seventeen buildings; and the label collides with §11.11's "At home" habit. Rec: "Best at" from §11.11 plus the server's §9.2 bonuses; a §23.5 row.
- **D. More roster-data errors than §23.5 lists** (deviation, minor). Tock the Hourkeeper a Warden with 420 health (js:191; capture `roster_sel_Tock`, `char_n10`), Sparkwright a Breaker and Tidewalker a Scout in `ALL18` (js:205), characters "Working" at the Library and a Storehouse (no worker slots, §9.2, §10.2), seven characters with one trait and one with none (§11.3: two, strays three). Rec: extend the §23.5 "Roster roles" row; the build takes kinds, roles and traits from content and the server.
- **E. The Forms album's USE THIS LOOK re-skins a ruleborn** (deviation, significant: a design adding a mechanic). js:1204-1205 against §11.10 (the form is set at hatching by the Nursery's laws and carries a quirk). Rec: drop it, or write a rule; the build ships "Show mine".
- **F. §23.2 asks the launch Forms album for trades that ship in 1.1** (contradiction, minor). §23.2's row is in the launch list ("Version 1.1 adds two screens … Neither belongs to the launch list above"); §11.10: "Trading: from version 1.1"; §26.1 puts constellations, inside which §20.7 allows trading, in 1.1. Rec: "trades (from 1.1)" in the row, or move it.
- **G. Births have no screen** (gap, significant). §11.5 and §11.10 hatch at a Nursery, paid in Essence (§9.5), "the odds are shown before hatching" on a tie, and §19.20 offers naming and a free outfit at the first hatch; §10.2's Nursery holds three births. §23.2 has no Nursery or hatch row (Realm view's must-show is grid, terrain, budget, buildings, workers, pylons, wards, posts) and Screens v3 draws none: the album's FIND A NURSERY ends in a toast. Rec: add a hatch row to §23.2 (ready births, price, kind odds by §11.9's weights, form odds, traits rolled, naming).
- **H. The simulation's crew is five fixed roles at level 1** (finding, significant). `sim/src/lib.rs:353`, `heist.rs:233-234`, `replay.rs:53-90`: no kind, ability, level, trait, form or Sage. So what the Roster and Character screens show does not reach the heist the server re-simulates. Rec: carry the chosen crew (kind, level, traits, form) and Sage in the lease and replay, and model them in the simulation, before these screens' numbers are presented as the heist's.
- **I. Sage levels have a price and no income, and no improvement schedule** (gap, significant). §9.5 prices a level at 15 × 1.13^(level−1) Insight; §9.1 names Insight's sources (successful heists, Lab discoveries, anomalies) with no amounts, and §14.1 points to §7.6 and §11.7, which give none; §11.7's "every fifth level improves one power" names no power or size for any Sage; the economy model does not carry Sages (`tools/economy_model/rerun.py:39`) though §14.3 prints "Main Sage at level 10 … 40" days (:8199-8215). Rec: state Insight per source and each launch Sage's eight improvements, then model them or drop the §14.3 rows.
- **J. A Sage level may shorten "the one 20-second cooldown"** (contradiction, minor). §11.7: "Every fifth level improves one power (an extra use, a longer effect or a shorter cooldown)" and, a sentence later, every Sage follows "the one 20-second cooldown". Rec: say whether a level can shorten it.
- **K. How a level grows a character is not fully stated** (gap, significant for the simulation). §11.4: "+8% health and power, +5% carry" a level does not say whether it compounds (level 10: ×1.999 or ×1.72), and "abilities improve at levels 4, 7 and 10 (20% stronger effect each time)" does not say which parameter grows for the many abilities with two (Lantern Wisp: 6 tiles and 6 s; Featherkin: 3 tiles and one height level; Echoplate: 8 s and 40%). Rec: state compounding and name the parameter on each §11.11 card.
- **L. Where a ruleborn lives decides its ceiling and rest, and nothing says how it is housed** (gap, significant). §11.4: "Highest level = 2 × the level of the Hearth the character lives in"; §11.6: "Hearths shorten rest 5% per level"; §11.5: "3 characters for the Spire plus the places in every Hearth". The Spire's three have no Hearth level, and nothing says how a character is given or moved to a home. Related: F56 (the starting universe). Rec: state the Spire places' ceiling and rest, and the housing rule.
- **M. One-tap reassign needs a default slot, and the model's staffing order is unstated** (gap, minor; extends G22). §23.2 asks for one-tap reassign; §9.2 makes "which producer goes short" the decision; G22 found §14.1 names no staffing order though the tables move by months with it. Rec: one rule for both, so the default tap is the order the published pacing assumes.
- **N. Rest modifiers combine by no stated rule** (gap, minor). §11.6's Hearth −5% a level, §11.3's Loyal "rests 25% less after a success" (success is undefined: Clean only, or Loud too?) and Sleepy "rests 50% longer", on §12.9's 45/60/180. Rec: state the order (multiplicative?) and what a success is.
- **O. Naming a ruleborn is offered and unspecified** (gap, minor). §19.20 offers naming at the first hatch; nothing says typed or word-list for 13 to 15 (§20.7 keeps what others see to word lists), whether a name can change, or who sees it. The design shows names (Pip, Mo…) and no naming. Rec: state it with §20.7.
- **P. "Crew" names two things** (finding, minor). The heist crew (§12.5) and the 4-8-player group (§17.7); the design's tab "CREW" opens the Roster while the server's `/v1/crews` are player groups. Rec: label the tab "Roster", or rename one in the document.
- **Q. The Sage hall: no levelling, a "resting" Sage, a heist Sage before Keeper 2** (deviation, minor). No Insight, price or level-up (must-show "levels"); unassigned Sage tagged "RESTING" (js:359, 361); the Archivist offered as heist Sage at Keeper 1 against §12.5 and §14.2; "2 / 6" counting two post-launch Sages (§26.1: four at launch). Rec: build per section 4.8.
- **R. The guardian with one Sage, and where "at home" applies** (gap, minor). §11.7: "brings one Sage on each heist, and can station another at the Heart" — whether the only Sage (Keeper 2 to 6) may guard instead; and whether a Sage's at-home effect (Lab 20% faster, buildings 10% cheaper, Gardens 15% more, one more Observatory target) applies always, only while it is home, or only as the guardian. The design files "at home" under "On guard" (js:349). Rec: state both.
- **S. Album omissions: the skiff sail, the quirks, colour-only pips; and a stray's form** (deviation and gap, minor). §11.10's sail for a note across every kind is not drawn; quirks are not shown; note pips and roster state dots are colour only (§20.8); and §11.9's strays are "born under one of the laws the crew crossed" without saying which form they take when that law carries none of Hush, Spark, Echo. Rec: draw the sail and quirks, add symbols; state a stray's form.
- **T. Wrong hatch hints** (deviation, minor). js:1181: Thorns under Spark, Day and night under Echo. Rec: generate from content.

## 7. Order of work

1. The roster slice on the server (characters, homes, states, assign/recall, wake, level, the starting five), after or with TC.12's workers and production, so "working" produces. Findings L and N decide parts of it; build with the reading stated in a constant and registered, as the server has done before.
2. Shared components from Screens v3 (`StageCard`, `PortraitTile`, `PortraitGrid`, `FilterChips`, `StatePill`, `PriceButton`, `NotePips`), icon export, portraits, the content strings. They serve three screens.
3. The Roster screen.
4. The Character screen with portraits first, then the 3D stage once `tools/bake_creatures.mjs` produces GLBs.
5. The Sage hall with the role choice first; levels after finding I.
6. The Forms album with the hatched record; hatch guidance after the Nursery route (finding G).
7. The lease and the simulation carrying crew and Sage (finding H), with the planner.

All of it on Godot 4.7.2 (§24's engine row in v3.6), so the client moves from 4.5 and `api-4-5` first.

## 8. Questions only the owner can answer

1. Births: a hatch screen in §23.2, or part of the Realm view? (G)
2. Insight amounts and the Sage improvement schedule, or drop Sage levels from launch and the §14.3 rows? (I, J)
3. Compounding levels and which parameter an ability's 20% grows. (K)
4. The Spire's three places and housing. (L)
5. The default slot for one-tap reassign, and the model's staffing order. (M, G22)
6. Keep USE THIS LOOK as a written rule, or drop it? (E)
7. Show the Chronicler and Lamplighter as "later season" silhouettes at launch, or hide them? (Q)
8. Tab label: "Crew" or "Roster"? (P)
