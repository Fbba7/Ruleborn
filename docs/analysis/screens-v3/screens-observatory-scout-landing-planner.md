# Observatory, Scout report, Landing picker, Heist planner: Screens v3 against v3.6, and how to build them

Scope: the four screens that sit between "I want to raid" and the heist itself, in the owner's Claude Design artifact (Screens v3), read against design document v3.6 and planned for the Godot client on the architecture `client/` already has. The four are one flow in the design: **Observatory → Scout report → Heist planner ⇄ Landing picker → Heist**, with two short-cuts (the Observatory's "Plan without scouting" and the drifting-ruin tiles both jump straight to the planner).

Citations: the document is `docs/design/ruleborn-game-design-v3.6.txt`, cited as §N.M with its line number where the words matter (for example §5.4, line 822). Design source is `scratchpad/art/named/`, cited as `screens_main.js:N`, `screens_main.markup.html:N`, `realm_diorama.js:N`, `data_v35.js:N`. Repository files are cited from the repository root.

The rule applied throughout is §23.5 (lines 11383-11393): where the document states a rule, a number or a piece of text, the document wins; where it is silent and the design breaks no rule, the design is adopted; a design never adds a mechanic ("Anything that changes what a crew, a guard or a player can do, see, hear or earn is built only once it is written here", line 11391); §23.2 is the must-show list and the designs' own "MUST SHOW" notes are not.

---

## 0. How this was read

- **Markup**: Observatory `screens_main.markup.html:625-672` (lines 661-671 are the shared tab bar), Scout report `:673-741`, Heist planner `:742-768`, Landing picker `:770-780`.
- **Logic**: prototype data `screens_main.js:71-85` (CREW, TARGETS, LANDINGS); Observatory `screens_main.js:483-526`; Scout report `screens_main.js:527-581`; planner `screens_main.js:584-605`; Landing picker `landVals`, `screens_main.js:265-284`; the 3D scout view `realm_diorama.js:255-276` (`buildScout`) and `:452-456` (`sLabels`, `sOverlay`); the plan-mode chart `realm_diorama.js:1073`, `:1152`, `:1268`; the shared data module `data_v35.js:15-18` (fee, refresh, scoutPerRealm, health).
- **Screenshots**: the supplied `shots/all/Gameplay_06_Heist_planner`, `_08_Observatory`, `_09_Scout_report`, `_23_Landing_picker` (.png and .txt). Those show one state each, so I rendered the design locally at phone size in more states, using the vendored React the Weaving/Codex analysis set up (`scratchpad/analysis/wlch_vendor`) and my own server and script (`scratchpad/analysis/oslp_scripts/serve.mjs`, `states.mjs`). Captures are in `scratchpad/analysis/oslp_shots/`:
  - Observatory: `obs_1` (Kofi), `obs_2` (Ines, echo), `obs_reroll` (after a refresh). `obs_0` caught the previous screen and is not used. The sky images for Kofi and Ines did not load through my server, so those two cards show the fallback gradient; the supplied Marta capture shows the real art.
  - Scout report: `scout_{heart,lantern,skyfield,crystal}_{land,threats,crew}` (all three tabs on all four realms).
  - Planner: `plan_land`, `plan_land_scrolled`, `plan_crew`, `plan_crew_pip_benched`, `plan_crew_no_carrier`.
  - Landing picker: `land_skyfield`, `land_crystal` (the supplied capture is Lantern Vale).
- **The document**: §5.1-5.4 (lines 588-838), §7.8 (3722-3753), §9.4-9.5 (4547-4630), §10.2 Observatory (5712-5760), §10.3 wards (5836-5897), §11.1 (5922-5970), §11.6-11.8 (6165-6240), §12.1-12.7 (6881-7032), §12.10-12.15 (7113-7183), §12.22 (7418-7438), §13 opening (7440-7490), §15.5 and §16's first session (8800-8880), §19.12, §20.2-20.7, §21.8 (10986-11016), §23.1-23.5 (11193-11600). The v3.4 → v3.6 diffs in `scratchpad/v36/diffs.txt`.
- **The build**: `client/README.md`; `client/core/store.gd`; `client/app/{app_state,router,services}.gd`; `client/scripts/{home,heist_screen,realm_view,ui}.gd`; `client/features/heist/heist_controller.gd`; `client/features/universe/*` (as the pattern to copy); `client/data/repositories/{heist,universe}_repository.gd`; `client/data/lease_stock.gd`; `client/ext/src/{lib,island}.rs`; `sim/src/{lib,replay,island}.rs` (landing, crew, command kinds); `server/src/http.mjs` (route list lines 5-99, offer at 513-520); `server/src/matchmaking.mjs`; `server/src/service.mjs` (lease 376-411, issue 446-512, stakes 519-537, balance 877-882); `server/src/economy.mjs:163-186` (fee, return, week).
- **Roadmap and register**: `tools/roadmap.py` (T3.3, T3.4, stage SC lines 938-1170, NOT_YET 1350-1380); `tools/audit_register.py` items C37, C13, D66, D71, F39, C41, F44, F46, F51, G20, G30, G40 and the FRONTEND/BOTH sets (7985-8005); `docs/decisions/answers.json` and `brief.json` for F39, C41, F44, F46, F51.
- **Not read**: the Universe map, Realm view, Heist and Result blocks beyond where these four link to them; the creature sheets; the Roster screen's markup (I relied on §23.5's statement that it shows Hollow and Ash resting).

---

## 1. What the four screens share

### 1.1 The flow, as the design wires it

| From | Tap | To | Where |
|---|---|---|---|
| Tab bar "Heist" | | Observatory | `screens_main.js:431` (menu group) |
| Observatory card | Scout / Free scout · Trace | Scout report, on that target | `screens_main.js:522` |
| Observatory card | Plan without scouting | Planner | `screens_main.js:522` |
| Observatory ruin tile | Easy / Medium / Hard | Planner | `screens_main.js:526` |
| Scout report | Plan the heist | Planner, landing set to the realm on show | `screens_main.js:581` |
| Planner | Entry or Route row | Landing picker | `screens_main.js:604` |
| Planner | Start heist | Heist | `screens_main.js:605` |
| Landing picker | Land at … | Heist (not back to the planner) | `screens_main.markup.html:778` |
| Planner 3D chart / Landing picker chart | tap an outer island | sets the landing to that realm | `realm_diorama.js:1268`, `screens_main.js:120` |

### 1.2 What the build has for any of it today

Nothing on screen. `client/scripts/home.gd:75-79` sends "Play" straight to the heist screen; `client/scripts/heist_screen.gd:57-75` then signs in, asks `HeistRepository.first_target()` for "the first island in the target lists that is not the player's own" (`client/data/repositories/heist_repository.gd:28-45`), leases it and plays it. The crew lands on a spot chosen by the heist's seed (`client/features/heist/heist_controller.gd:181-200`, `default_landing()`), "until there is a landing picker" (`client/README.md`, the heist screen paragraph; roadmap T3.4 "Not yet").

What the server and simulation already provide that these screens can stand on:

| Piece | Where | What it gives |
|---|---|---|
| §12.22's list | `GET /v1/offer?size=` (`server/src/http.mjs:513-520`), `offer()` (`server/src/matchmaking.mjs:219-290`) | Targets filtered, ordered by predicted success, middle drawn from the band, echoes when thin, filters widened in order; `{targets, guaranteed, echoes, widened}` |
| Trace | `traceable()` (`matchmaking.mjs:166-179`), `lease(..., {trace})` (`service.mjs:376-411`) | Whether the caller may Trace a raider within 24 h, and a Trace lease with no fee |
| New-player shield | `shielded()` (`matchmaking.mjs:150-161`) | §12.3's 72 hours, ended by the player's own first raid |
| Echoes | `candidates()` (`matchmaking.mjs:189-213`) | Snapshots up to 14 days old, flagged `echo` |
| The fee preview | `stakes()` (`service.mjs:519-537`) on every lease | The fee as it would be charged now (F39 answer B: 2% of B(V) at the target's Vault level), and the week's caps (G20, F40) |
| Landings | `RulebornReplay.landings()`, `reaching()` (`client/ext/src/lib.rs:311-334`); `Island::landings()` (`sim/src/island.rs:519-527`) | Every open edge tile; those that reach the Vault |
| The landing command and its noise | `Kind.LAND` in the replay; `World::land()` (`sim/src/lib.rs:1085-1119`) | §5.4's landing, heard unless the tile is fog bank, tall grass or unlit, read through the law sheet's noise radius |
| A heist's lease | `POST /v1/leases`, `issue()` (`service.mjs:446-512`), the stock (`client/data/lease_stock.gd`) | Seed, ticks (with the era's), fee, caps, expiry a day away |

What none of the four can be built without, and does not exist:

1. **Universes of several realms in a heist.** A heist is one island (D71, open: "The Heart is landed on, because a heist is still one island"; T3.3 "Not yet: crossing realms … and universes of several realms"). Matchmaking rates and offers islands (`owner/realm`), not universes (`matchmaking.mjs:88`, G30's "an island is rated by owner and realm"). Every screen here is drawn for universes with 3 to 5 realms, routes, links, depth and per-realm scouting.
2. **Aether.** The ledger holds Starlight and Essence only (`service.mjs:877-891` refuses any other currency). The Observatory's refresh (§12.3, line 6924), a paid scout (§12.4, line 6936) and casts (§12.5, line 6956) all cost Aether.
3. **A roster, rest and guard states on the server.** None yet (TC.12's "Next" list: "… the roster (§11.5)"). The planner's crew needs them, and §12.5's "Resting characters can't go" (line 6950) needs the rest timers.
4. **A crew of characters in the simulation.** The replay header carries `crew: u8`, a count (`sim/src/replay.rs:147`), and the crew is a fixture of roles in §11.1's order (`sim/src/lib.rs:352`). There are no abilities, no Sage powers and no casts among the twelve command kinds (`sim/src/replay.rs:53` onward; `client/features/heist/heist_controller.gd:18`). The planner's crew, Sage and casts rows have nothing to bind to until these exist, and each changes the replay format and the rules version.
5. **Law ownership** ("met", pages, unlocked): the "New to you" flag, the scout report's "!" mark and a cast's "your own unlocked laws" need the Codex service the Weaving/Codex analysis plans (`screens-weave-law-codex-harmony.md` §1).
6. **Ruins and generated targets.** Neither is built (D66: "Not built: … the generated fallback targets, whose generator is also the harness's; ruins (12.10)").

### 1.3 Problems that cut across all four

**A. The owner's answers that v3.6 does not carry.** `docs/decisions/answers.json` records F39 = B (the fee is 2% of B(V) at the target's Vault level), C41 = B (fee returned after clean or loud, half after partial), F44 = D (Keeper window two below to three above), F46 = B ("Make scouting free … the target card shows laws, guards and ward counts") and F51 = B (half of each side of a realm open to land). The server is built to these (`economy.mjs:163-178`, `facts.json` MATCH_WINDOW). v3.6 changed none of the sections they edit (`diffs.txt`: v3.6 changed §5.7, 11.7, 11.8, 14.4, 18.8, 23.1, 23.2, 23.4/24, 24.7, 26.6, 26.8, 28.3, 32.8 and added §23.5), and v3.6's new §23.2 Observatory row now says "showing only the free scouting facts (12.4)" (line 11237), which keeps the paid scout. Screens v3 draws the pre-answer rules on these screens: a 2,840 fee that is 2% of the player's 142,000 Starlight on every card (`data_v35.js:15`), "Keepers 21-27" (±3, `screens_main.js:524`), "Scout · 100 Aether" behind a locked "Laws, guards and wards show after a scout" panel (`screens_main.markup.html:649-652`). Until the owner says which stands, the Observatory, scout and planner cannot be finished: the scout button, the locked panel, the fee number and the window subtitle all change with the answer. Register item **N1** below.

**B. Positions before the heist.** §12.4 (line 6936): the scout shows "how many wards of each type it has, but not where they are"; §12.12 (line 7141): "A scout shows no positions (12.4); patrols are learned in the heist"; C37 closed on exactly this ("Decided by brief 38: the scout shows no positions", `tools/audit_register.py:7430-7434`), and the roadmap's NOT_YET says detailed screen design was unblocked by it (`tools/roadmap.py:1371-1378`). The design's scout report draws every guard post with a red reach disc and a "×2" pin, every ward with a ring and a "✦" pin, a route from a landing flag to the Vault, and patrol prose ("Two loops around the Spire; the Breaker holds the vault door", `screens_main.js:532`; "The Breaker guards the vault; Wardens loop the Spire", `:537`; rings and pins at `realm_diorama.js:267-276`). §23.5 lists only the Heart's "Land here" flag for this screen. Register item **N2**. At the same time, the landing picker must let the raider pick any edge tile and see whether it is "in fog, darkness or tall grass" (§5.4, line 825), which means some of a realm's layout is visible before the heist, and the document never says how much: terrain, the Vault, pylons, the always-seen wards (Crystal Wall and Thorn Hedge are "Seen: Always", §10.3, line 5854 onward). Register item **N3** (relates to F46, whose body already notes the bundle is public).

**C. Text size.** §21.8 (line 10992): "Nothing smaller than 13 points", body 16. §23.5 lists it ("only the heist, planner and result meet the floor", line 11515). Measured in the markup: Observatory subtitle 11 px (`:629`), scout report 7.5-12.5 px throughout (`:676-733`), landing picker 7.5-11.5 px on most labels (`:773-778`). §23.5's claim for the planner holds on its Plan tab (13-14 px) but not on its Crew tab: role 9 px, ability 10.5 px, warning 12 px, the Sage label 9 px, the cast pill 11 px (`:761-763`). Register item **N11** (minor).

**D. Typefaces.** §21.8 (line 10992): "A rounded, friendly sans (Baloo 2) for labels and numbers, with tabular numerals; Marcellus for titles and law names", and §21.11's licence ledger lists those two only. The four screens use Manrope for almost all text and Lilita One for the landing picker's titles and numbers (`screens_main.markup.html:773-778`). §23.5 does not list it. The document states a rule here, so Baloo 2 and Marcellus win; the client already ships its own bold font variation in `scripts/ui.gd:220` and will take Baloo 2 from the tokens. Register item **N12** (minor; it affects every screen, not only these four).

**E. The 3D charts draw seven realms.** The plan-mode chart is created with no `only` attribute on the planner and landing picker (`screens_main.markup.html:745`, `:772`), so it shows the Heart and six outer realms for a target the scout report says has three. Listed in §23.5 ("3D universe charts", line 11545). The component already supports `only` (`realm_diorama.js:1073`); the build passes the target's realms.

**F. Landscape** is not designed (listed, line 11560). §23.3's "Same information in both" (line 11354) is the only constraint: these four are lists and cards over a chart, so landscape puts the chart left and the panel right with the same rows.

### 1.4 Shared build pieces (one each, used by all four)

| Piece | Kind | What it is |
|---|---|---|
| `RaidState` (`features/raid/raid_state.gd`) | store slice `&"raid"` | The raid being prepared: the offer list and its meta (`guaranteed`, `echoes`, `widened`, the filter window), the chosen target, its lease, its scouting facts per realm, the landing (realm, tile), the route, the crew, the Sage, the casts, the stakes; `busy` and `error` as UniverseState does (`client/features/universe/universe_state.gd`) |
| `RaidController` (`features/raid/raid_controller.gd`) | flow on Services | Asks repositories, dispatches answers, owns the order: offer → choose target → lease → plan → land → `heist_started` with the lease and the plan. Lives on `Services` like `universe_flow` (`client/app/services.gd:32`), so leaving a screen mid-call loses nothing |
| `TargetRepository` (`data/repositories/target_repository.gd`) | repository | `offer()`, `refresh()`, `ruins()`, `scout()` (if paid), and the lease (moved from `HeistRepository.lease`) |
| Presenters | `features/raid/{observatory,scout,plan,landing}_presenter.gd` | Pure functions from the slice to what each screen draws, tested headless like `universe_presenter.gd` |
| Routes | `client/app/router.gd:8-22` | `&"observatory"`, `&"scout"`, `&"planner"`, `&"landing"` |
| `RulebornIsland.scouting()` | new `#[func]` in `client/ext/src/island.rs` | From a bundle: law ids, guards by role, wards by kind, realm level, Vault level, exposed. Counts only, never positions, so the screen cannot draw what it is not given |
| `RulebornReplay.landing_heard(x, y)` and `landing_reach()` | new `#[func]`s in `client/ext/src/lib.rs`, backed by a `World` method that `land()` itself calls | Whether a landing on that tile is heard, and the walked reach in tiles after the law sheet's noise radius. One rule, written once (§24.7), so the picker says exactly what the simulation does (G40's edit: "stated, the landing picker can show exactly what a guard would hear") |
| `CardDeck` component in `scripts/ui.gd` | component | A horizontal snap carousel with previous and next buttons and position dots; swipe on touch, buttons for one-finger and screen-reader use (§20.8); reduced motion turns the snap tween off |
| `Ribbon`, `Pill`, `StatTile`, `SummaryRow`, `Chip`, `Gauge` components | components | The corner ribbon (TRACE · 24 H, ECHO, GENERATED), the risk pill, the small number-over-label tile, the planner's label/value/chevron row, the law and role chips, the semicircle gauge. Each draws from the tokens; each puts its meaning in words as well as colour |
| `UniverseChart` (shared with the Universe map) | 3D scene in a `SubViewportContainer` | Islands and links in plan mode, with `only` = the target's realms, a route drawn as a tube and markers for the landing; tap an outer island emits `realm_picked`. Until the 3D art pass, a 2D node graph of the same realms and links |

---

## 2. Observatory

### 2.1 What the document asks

- §23.2 row (line 11235-11237): "Observatory | Choose a target. | Three to five universes showing only the free scouting facts (12.4), the depth and the reason each was offered (12.15, 12.22), echoes marked, Trace, the entry fee; drifting ruins apart, at three labelled difficulties (12.12)".
- §23.5: the Observatory "already follow[s] this document" except the Trace row: "Charged or refunded an entry fee on the Observatory card, the planner and every result | No entry fee on a Trace | 12.3" (lines 11418, 11430-11433). Also Text size (11515) and Landscape (11560).
- Rules the screen carries:
  - §12.3 (lines 6922-6932): 3 universes (5 at level 5); within 150 Renown, within 3 Keeper levels (F44's answer: 2 below to 3 above), within 20% of strength; refresh 50 Aether doubling in the hour; echoes; complexity budget; the 72-hour shield; Trace "once, with a free scout and no entry fee".
  - §10.2 Observatory (lines 5712-5760): 3, 3, 4, 4, 5 targets at levels 1-5; scouting 0-40% cheaper.
  - §11.7 Wanderer at home (line 6215): "The Observatory offers one more target".
  - §12.4 (line 6936): free information is "name, Keeper level, number of realms, Renown and a rough loot estimate".
  - §12.10 (line 7115): "Drifting ruins: three universes built by the game each day, for pages and Essence but no Renown".
  - §12.12 (line 7135): "Every ruin offers three openly labelled difficulties with their rewards shown, and a recommendation the player can ignore. Targets are chosen by the player from a list that spans easier and harder universes."
  - §12.15 (lines 7177-7181): "Harder targets are always in the list, clearly marked, never forced"; "the reason each was offered is printed on the card"; ratings internal, "the raw numbers are never shown".
  - §12.22 (lines 7424, 7433): "Every offered target shows its depth"; a generated fallback "is labelled as a generated target at the point of attack, because it is nobody's realm and must not pass as another player's"; an empty band's fallbacks are "labelled with the band they come from".
  - §9.4 (line 4560) as written: "Entry fee: 2% of the raider's Starlight, from 100 to 25,000"; as answered (F39 B): 2% of B(V) at the target's Vault level, never more than the raider holds.
  - §16, day 2 (line 8879): "Because raiding a player ends the newcomer's 72-hour protection early, the game says so before the first one."
  - §16 at 7:00: "Two more ruins appear. The player chooses one and runs it alone."
  - §15.5 (line 8811): every law returns, "by weighting matchmaking and ruins toward realms that run it".

### 2.2 What the design shows (Gameplay_08; obs_1, obs_2, obs_reroll)

Top to bottom, inside a 390 × 844 frame on a dark starfield (`screens_main.markup.html:626-628`):

1. **Header** (`:629`, `:660`): "Observatory" in Marcellus 24; under it "Keepers 21–27 · Renown within 150" (11 px). Top right, a refresh chip: a circular-arrow icon, a "!" and an Aether pill with the cost, "50" then "100" after one refresh (`obs.reroll`, `screens_main.js:524`, charging `RB.refresh(n)` = 50 × 2^n, `data_v35.js:16`).
2. **Pager** (`:630`): previous and next buttons and one dot per target; the current dot is a wide gold pill.
3. **Target deck** (`:631-658`): a horizontal, snap-scrolling row of 300-px paper cards, swipeable by touch, mouse drag or wheel (`screens_main.js:502-507`), with the neighbours peeking 45 px either side at 72% opacity. Each card:
   - a sky header 150 px high with a pre-rendered picture of the target's universe (`world/obs/<keeper>.png`, `screens_main.js:519`), and a diagonal ribbon top right: "TRACE · 24 H" (gold) or "ECHO" (violet) (`screens_main.js:525`);
   - a round avatar overlapping the header (the portrait of the Sage of the target's school, `screens_main.js:513`) with a Keeper-level badge ("23");
   - the Keeper's name (22 px) and "4 realms · Renown 1,420";
   - two tiles: "Rough loot ~3,300 / ~1,150 Essence" and "Depth / 1 realm to the Heart";
   - a "Why" row: "Trace · she raided Verdant yesterday", "Two realms deep · a longer run, a bigger haul", "Echo of a real universe · nothing is taken from her";
   - a dashed, padlocked row: "Laws, guards and wards show after a scout";
   - "Entry fee 2,840 Starlight" (the same on every card: `RB.fee(starlight)` = 2% of 142,000, `data_v35.js:15`);
   - a gold button: "Free scout · Trace" or "Scout · 100 Aether" (20 × realms, `screens_main.js:525`), and a text button "Plan without scouting".
4. **Drifting ruins** (`:659`): a heading "Drifting ruins" with "Pages, Essence, no Renown", and three tiles: "Easy / Slow rivers" (green rim), "Medium / Glass" (amber), "Hard / Haste" (red). Each goes to the planner (`screens_main.js:526`).
5. **Tab bar** (`:661-671`): Islands, Laws, Heist (raised, selected), Crew, Friends, with badges.

Interactions and motion: tap a side card to bring it to the centre; swipe; the centre card grows (588 vs 552 px in the earlier variant), glows in the target's school colour and the others fade (`screens_main.js:519`); a "whoosh" on refresh, "tap" on paging. States drawn: Trace target, a live target, an echo. Not drawn: generated target, an empty or short list, offline, the week's cap reached, a target shielded, the player's own shield, loading, an error, the refresh unaffordable (the code silently ignores the tap, `screens_main.js:524`).

Dead code worth knowing: the earlier list variant at `screens_main.js:483-499` (filters ALL / ECHOES / RICH LOOT / LOW TRACE, per-target law icons with "unknown" counts, a LOW/MEDIUM/HIGH risk from laws and guards, an "online" line) is computed but never drawn by the markup. It showed paid-scout facts (laws, guards) and an online status on a list that §12.4 limits to free facts; it should stay out.

A small layout fault: the card's "Plan without scouting" button sits below the visible part of the card in every capture (the card is 500 px in a 510-px deck whose bottom meets the ruins row at 644 px), so the short-cut is not reachable in the design as drawn.

### 2.3 Against the document

Matches: three universes; name, Keeper level, realm count, Renown and rough loot as the free facts; depth on every card; the reason on every card; echoes marked; Trace marked with its free scout; the refresh price and its doubling; ruins apart from player targets, with "no Renown".

Deviations already in §23.5:
- An entry fee on the Trace card (line 11430). The build shows "No entry fee: Trace" on that card (`stakes()` already returns 0 for a Trace, `service.mjs:532`).
- Text below 13 pt (the 11-px subtitle and the refresh "!"); landscape.

Deviations not in §23.5:
- **Ruins at one difficulty each** (N5). The design shows three ruins, each at one fixed difficulty, with no rewards per difficulty and no recommendation. §12.12 (line 7135) says every ruin offers three labelled difficulties with their rewards shown and a recommendation the player can ignore; §12.10 says three ruins a day. §23.2's "drifting ruins apart, at three labelled difficulties (12.12)" can be read either way, which is why it is a gap as well.
- **Generated targets have no label** (N4). §12.22 step 4 requires one; the design has no generated state, and its final tag code would call a generated target "ECHO" (`tag:tg.traceOn?'TRACE · 24 H':'ECHO'`, `screens_main.js:525`).
- **Rules the owner's answers replaced** (N1): the fee as 2% of holdings on every card; "Keepers 21-27"; the paid scout and the locked panel.
- **Harder targets are not marked** (§12.15, line 7177). Kofi's reason ("a longer run, a bigger haul") hints at it; nothing says "harder". The marking must come from the server's ordering (the list is sorted by predicted success, `matchmaking.mjs:262-264`), shown as a word, never as a number.
- **The player's own shield is not mentioned** (§16 day 2, line 8879). The first card that is a player target, while the player is shielded, must say that raiding it ends the protection.

Must-show missing (§23.2 and the sections it cites): each ruin's three difficulties with rewards and a recommendation (§12.12); a "harder" mark (§12.15); a generated-target label (§12.22). The rest of the row is drawn.

Silent adoptions (break no rule, adopt): the swipe deck with pager and dots; the per-target sky picture; the corner ribbons; the avatar with the level badge; the two stat tiles; the Why row; the dashed "after a scout" row (only if the paid scout stays); the refresh chip with its live price; the three coloured ruin tiles; the centre-card emphasis.

Adds a mechanic: nothing drawn. (The dead filter variant would have shown non-free facts on the list; it is not drawn.)

### 2.4 Build today

None on the client (see §1.2). Server: `GET /v1/offer` returns, per island, `bundle, owner, realm, realmLevel, keeperLevel, renown, rating, deviation, origin, echo, predicted` (`matchmaking.mjs:199-205`, `:262-290`). It is called by nothing in the client (`client/data/repositories/heist_repository.gd` uses `/v1/targets` and the first island it finds). `size` is taken from the query string, 1 to 5 (`http.mjs:517`), not from the player's Observatory level. The fee and caps exist only on a lease (`stakes()`).

### 2.5 How to build it

**Server first** (each a small slice in `server/src`, with tests beside the existing `matchmaking.test.mjs`):

1. `GET /v1/observatory` (or `/v1/offer` reshaped): the list a card draws, and nothing it must not.
   - Size from the player's Observatory level (`universe.mjs` buildings: 3, 3, 4, 4, 5) plus one with the Wanderer at home (§11.7); never from the query.
   - Per target: display name (age-band aware, see N9), Keeper level, realm count, Renown, rough loot (Starlight and Essence from the same `haul()` the grant mints, rounded to two significant figures, so the estimate cannot be read back to an exact exposure), depth (see N6), a reason code with parameters (`trace`, `echo` with age, `generated` with band, `harder`, `easier`, `middle`, `deeper`, `widened:<filter>`), flags (`trace`, `echo`, `generated`), the fee from `stakes()` for this raider and this target (F39 B makes it differ per target), and whether the week's caps apply (G20's "A later raid that week charges no fee and pays no haul").
   - List meta: the Renown window and Keeper window actually used (for the subtitle), `guaranteed`, `widened`, the refresh price now, and `shielded: {until}` for the caller.
   - Never: `rating`, `deviation`, `predicted` (§12.15, line 7181). Today they go to the device.
2. `POST /v1/observatory/refresh`: charges 50 × 2^n Aether, n the refreshes in the past hour (§12.3), and returns a new list. Needs the Aether ledger (G42's production slice).
3. A Trace card: `traceable()` already answers; the list carries it as an extra card (my recommendation for N7), pinned first with the TRACE ribbon.
4. `GET /v1/ruins`: three ruins for the day, each with three difficulties, rewards per difficulty and a recommended one (§12.10, §12.12). Needs the generator in the simulation (D66's recommendation: "Port the reference crews and the generator into the simulation"). Until then the tiles show "Ruins arrive with the generator" rather than fake ones.
5. Generated fallback targets (§12.22 step 4) come with the same port; the label is a flag in the list.

**Client:**

- `features/raid/observatory_presenter.gd`: card view models from the slice: name, level, "N realms · Renown R", loot lines, depth words, the reason in words from `i18n/strings.csv` (`OBS_WHY_TRACE`, `OBS_WHY_ECHO` …, both languages), ribbon kind, the fee line ("Entry fee 820 Starlight", "No entry fee: Trace", "No fee and no haul: this week's 20 paid raids are used"), the primary action ("Plan" under F46 B; "Scout · N Aether" or "Free scout · Trace" if the paid scout stands), the shield warning on the first player target while shielded.
- `scenes/observatory.tscn` + `scripts/observatory_screen.gd`: `UI.frame`, a header row (title, window subtitle at 13 pt or more, refresh chip with the Aether price and a disabled state that says why), `CardDeck` of `TargetCard`s, the ruins row (three `RuinTile`s; each opens a small sheet with its three difficulties, rewards and the recommended one marked "Suggested"), and the shared tab bar.
- `TargetCard` composition: a header `TextureRect` (the sky art), a `Ribbon`, an avatar with a level badge, labels, two `StatTile`s, a Why `PanelContainer`, the fee `Label`, the main `UI.button`, a text button. The sky art: until the 3D art pass, a gradient by the target's dominant school with its realm icons placed as the earlier variant did (`screens_main.js:509-519`); after it, a `SubViewport` render of `UniverseChart` with `only` = the target's realms, rendered once per bundle hash and cached.
- `RaidController.choose(target)`: on "Plan" (or "Scout"), takes the lease, because §12.12 fixes the heist's seed "when the target is chosen" (line 7141); the lease brings the seed, the fee and the caps. Browsing the deck takes no lease (F46's brief counted every look as a lease write).
- Home's "Play" (`client/scripts/home.gd:75-79`) goes to `&"observatory"`; the heist screen starts from the lease the raid slice holds instead of calling `first_target()`.
- Offline (G41): the Observatory shows the leases in stock as the only cards, marked "Kept for offline play", with the recommendation to go online; there is no refresh and no ruins.
- States: loading ("Asking the Observatory"), a short list (`guaranteed: false`: "Fewer targets fit your band today; the list is widened by rating" in words from `widened`), refused (the server's code through `core/errors.gd`), the player's own shield, a target shielded since the list was made (the lease's `new_player_protected`), caps.
- Tests: presenter tests for every card state (Trace, echo, generated, harder, capped week, shield warning); a flow test Observatory → planner with a fake transport; the a11y and size checks that already run on every screen (`client/tests/a11y_tests.gd`).

Effort: **L** (server reshaping S-M, refresh needs Aether, ruins and generated targets wait on the generator; client screen M).

---

## 3. Scout report

### 3.1 What the document asks

- §23.2 row (line 11239-11241): "Scout report | Read their laws. | Realm-by-realm law cards, guards by role, ward counts, matchups".
- §23.5 (line 11485): "Scout report | A Land here flag on the Heart in the 3D view | Skiffs cannot land on the Heart | 5.4". Also Text size, Landscape, 3D charts.
- Rules:
  - §12.4 (line 6936): a scout "shows each realm's laws, the number and roles of its guards, and how many wards of each type it has, but not where they are … A scout stays valid for 15 minutes."
  - §12.12 (line 7141): "A scout shows no positions (12.4); patrols are learned in the heist".
  - §5.4 (line 822): "The Heart is ringed by strong winds, so skiffs can't land there."
  - §15.5 (line 8812): "Recall before reveal | In the scout report, a law the player has met is shown by its icon and movement first, with a one-tap 'what does this do?' rather than an automatic explanation."
  - §7.8 (line 3749): "every law has … a card with a looping preview".
  - §17.2 (line 8899): "Raiders see the Grand Law when they scout" (version 1.1).
  - §10.3 (lines 5836-5897): the ward types are Gravity Well, Crystal Wall, Time Snare, Static Coil, Thorn Hedge, Lantern Glare.
  - §11.8 (line 6229): the Cartographer "Sells a full scouting map of one target, with ward positions" — the one pre-heist source of positions.

### 3.2 What the design shows (Gameplay_09; scout_* captures)

1. **Header** (`:675-676`): a back button to the Observatory; "◉ SCOUT REPORT · 1 / 4" (9.5 px, red); "Marta's universe" (Marcellus 22).
2. **Realm strip** (`:677`): four thumbnail buttons, one a realm (Heart, Lantern, Skyfield, Crystal), each with its realm picture, a coloured risk dot and "~3,300" / "~420" / "~260" / "~310" of loot.
3. **3D realm view** (`:678`, `realm_diorama.js` mode `scout`, 322 px): the realm in 3D with, on the Land tab, a green "⚑ LAND HERE" flag (including on the Heart), a glowing route tube from the flag to the Vault or the star wells, and a gold "VAULT ~3,300" tag; on the Threats tab, red discs of radius 4.4 around every guard post with "×2" pins, and rings with "✦" pins on wards (`realm_diorama.js:255-276`, `:452-456`). Over it, the realm's name and a verdict ("Big prize, tough door"), a "HIGH RISK" pill with five pips, and three chips at the bottom: "~3,300 VAULT", "4 guards", "5 wards".
4. **Tabs** (`:695`): 1 Land, 2 Threats, 3 Crew.
5. **Panel** (`:696-735`):
   - Land: "LAND AT" and a place ("No skiffs: strong winds ring the Heart", "West ledge, in the fog", "South bridge", "East edge, by the chute"), guard and ward chips, a loot ring "~3,300 VAULT 77% of total", and "LAST TIME 2,140 loot last time · Spotted once" or "Never raided · No history yet".
   - Threats: a gauge with a needle and "RISK HIGH", a patrol sentence ("The Breaker guards the vault; Wardens loop the Spire."), role chips ("1 Scout", "2 Wardens", "1 Breaker"), "5 wards · 3 hidden traps", and "LAWS" chips with a "!" on laws not yet met; a law chip opens the law card.
   - Crew: "BRING · 3 of your crew suit this realm", three portraits with one-line reasons ("Mo / Walks; guards sleep"), and a "LEAVE Pip" tile with "WHY LEAVE Pip / Glass shows him".
6. **Plan the heist** (`:739`): a gold button, "With Mo, Bramble, Hollow", setting the planner's landing to the realm on show (`screens_main.js:581`).

Interactions: tap a thumbnail or swipe the page sideways to change realm; tap a tab; tap a law chip. The 3D view dims the route on the Threats tab and dims the threats on the Land tab (`realm_diorama.js:454`).

### 3.3 Against the document

Matches: realm by realm; guards by role; the laws of each realm, marked new or met; matchups as a tab; the Heart's panel text says no skiff can land there.

Deviation in §23.5: the "LAND HERE" flag on the Heart (line 11485). In fact the flag is drawn on every realm, including the Heart, because the scout view always places it (`realm_diorama.js:258`, `:273`).

Deviations not in §23.5:
- **Positions and patrols** (N2): guard posts with reach discs and counts, ward rings, "+N hidden traps", and patrol prose. §12.4 and §12.12 rule all of it out, and brief 38 decided it (C37 fixed).
- **Ward counts not by type**: the Threats tab gives a total ("5 wards · 3 hidden traps", `screens_main.js:574` `wardTxt`); §12.4 says "how many wards of each type". The data has the types (`screens_main.js:532`: Grate, Rune circle, Vent, Lantern, Rope knot), but those are not §10.3's names; the icon mapping at `screens_main.js:577` maps them to Time Snare, Gravity Well, Static Coil, Lantern Glare and Thorn Hedge.
- **Loot by realm and the Vault's share** ("~3,300 VAULT · 77% of total", the strip's per-realm loot): §12.4's free facts give one "rough loot estimate"; its paid list does not include loot by realm. §9.4 says storehouses "are fully exposed, so where you place them decides what raiders pass on the way in", and that "scouting changes the decision", which suggests the scout shows exposure, but no section says what. Gap N8.
- **Law cards**: the panel shows law chips, each opening the law card; §23.2 says "law cards", §15.5 says a met law shows "its icon and movement first, with a one-tap 'what does this do?'". The chip shows the name, not the movement. The law card itself lacks its looping preview (§23.5 line 11495, the Law card row).
- **No scout validity**: §12.4's 15 minutes appear nowhere (N10).

Must-show missing: ward counts by type (§12.4); law cards showing the movement first (the chips are a fair summary, but the card behind them must carry the preview). Matchups exist, but as authored prose (see the plan).

Adds a mechanic: showing guard and ward positions and patrol routes (what a player can see before the heist); the per-realm loot split, until the document says a scout shows it.

Silent adoptions: the realm strip; one swipeable page a realm; the three tabs; the realm's verdict line (if generated from visible facts); the risk pill and gauge (if computed only from what the scout shows, see the plan); the "LAST TIME" line (the player's own history with this target, which is theirs to see); "Plan the heist" with a suggested crew; the "LEAVE" suggestion (advice from visible facts).

### 3.4 Build today

Nothing on the client. Server: nothing for a scout (no route in `http.mjs:5-99`; F46's brief: "No paid scout exists in server/src or client/"). The data a scout shows is inside each bundle: `Island` holds `laws`, `guards` (`Post { row, x, y }`), `wards` (`(WardKind, x, y)`), `realm_level`, `vault_level`, `exposed` (`sim/src/island.rs:87-110`). `RulebornIsland.budget()` and `laws()` (`client/ext/src/island.rs:201-222`) give counts and law ids for the builder; `combos()` gives harmonies.

### 3.5 How to build it

**Decide first** (N1/F46): free (the scout report is a detail view of facts the card already shows) or paid (a `POST /v1/scouts {owner}` that charges 20 Aether × realms, 10% cheaper per Observatory level above 1, free for a Trace, and opens the report for 15 minutes). Either way the client computes the facts from the bundles it already downloads; only the honest client's display is gated (F46's own finding).

**Data:**
- `RulebornIsland.scouting()` (new, `client/ext/src/island.rs`): `{laws: [ids], guards: {role: n}, wards: {kind: n}, realm_level, vault_level}`. Counts only. One call per realm bundle.
- Law state ("met", "new") from the Codex service the Weaving/Codex analysis plans; before it exists, "new" is unknown and the "!" mark is not drawn.
- `LAST TIME`: a server read of the raider's own validated heists against this owner and realm (the `heists` and `leases` tables already hold them): loot banked, outcome, and whether the crew was seen (the replay's outcome).
- Matchups, from rules, never prose: a small table-driven module (`features/raid/matchups.gd`, or in Rust beside `combos.rs` so the server can reuse it) that reads, for each crew member against each law in the realm: the kind's resistance (§11.2's Resists column), its size and flight (§12.21: Density reads size, Heavy ground reads flight), its school against the realm's school (§5.2), and role facts (§11.1: Scout sees 8 tiles, Breaker double damage to wards and pylons, Carrier 300 bag, Warden draws guards, Mender heals). Each hit yields GOOD / OK / RISKY with a templated line from `strings.csv` ("Resists Slow rivers", "Grounded by Heavy ground", "Sees 8 tiles in Glowing dark's dark"). Nothing may read a position.
- Risk (if kept): a function of the visible facts only (guard count and roles, ward counts by type, laws new to the player, realm level), never of the island's rating (§12.15). If that cannot be made honest, drop the pill: it is not on the must-show list.

**Screen** (`scenes/scout.tscn`, `scripts/scout_screen.gd`, `features/raid/scout_presenter.gd`):
- Header with back to the Observatory; the realm strip as a row of `UI.button`s with a thumbnail, the short realm name and its school shape (the risk dot gets a word too, §20.8).
- The realm view: until the 3D art pass, the realm drawn by `RealmView` in a new `planning` mode that draws ground and terrain only (no guards, posts, wards, pylons, no Vault marker until N3 is decided); after it, the `RealmDiorama` in scout mode with `buildScout()`'s guard discs, ward rings and pins removed and the landing flag drawn only on outer realms and only where the player chose to land.
- Tabs as `UI.row` of three buttons; panels:
  - Land: for the Heart, "No skiff can land: strong winds ring the Heart" (§5.4's words); for an outer realm, the landing the player picked, or "Choose a landing" linking to the picker; the guards and wards chips; LAST TIME.
  - Threats: role chips with role icons and counts; ward chips by §10.3 type with the type's school shape and count; law cards (a compact `LawCard` component from the Weaving/Codex plan, with its looping preview: for a met law, icon and movement first and "What does this do?"; for a new law, the card with its rule line); the Grand Law row when constellations arrive (v1.1).
  - Crew: the matchups for the player's available crew (rested, not on guard), best three and one to leave.
- "Plan the heist" → planner, landing realm preset when the page is an outer realm.
- Scout validity (if paid): a countdown chip "Scout valid 14 min"; when it lapses, the facts grey out with "Scout again".

Effort: **L** (the facts are cheap; the matchups module, the planning-mode realm view without positions, and the law cards are the work; the 3D view waits on the art pass).

---

## 4. Landing picker

### 4.1 What the document asks

- §23.2 row (line 11291-11293): "Landing picker | Choose where to land. | Every outer realm's edge, what guards would hear, and the heist clock for each choice".
- §23.5: "Landing noise | A percentage | Heard or not; heard means guards within 6 tiles start at 250 of 1,000 suspicion | 5.4" (line 11480); the 3D charts row (11545); Text size; Landscape.
- §23.1 (the old Godot render, line 11197): "Landing. Open edges. Green markers are silent landings, red ones are heard. The defender cannot choose where you arrive (5.4)."
- Rules:
  - §5.4 (lines 822-834): "The crew lands on any edge tile of any outer realm the raider chooses. The Heart is ringed by strong winds, so skiffs can't land there." "A landing skiff can be heard: guards within 6 tiles of the landing spot start at 250 of 1,000 suspicion (12.17), unless the spot is in fog, darkness or tall grass." Skiff 5 s to an outer realm, 20 s to the Heart. Clock "150 seconds plus 15 seconds for each link on the shortest route from the landing realm to the Heart, up to 240 seconds. Haste makes the clock run 25% faster while the crew is in its realm."
  - §12.5 (line 6944): "Entry | Any edge tile of any outer realm (see 5.4), or a fault if the target is overloaded."
  - G40's readings (the simulation's): the whole crew lands on one tile at tick 0; darkness is the unlit test; the six tiles are walked; a law's noise radius stretches them; a guard already above 250 keeps its value.
  - F51 answered B: each side keeps at least half its edge tiles open.

### 4.2 What the design shows (Gameplay_23; land_skyfield, land_crystal)

1. **Header** (`:773`): back to the planner; "Choose a landing" (Lilita One 23); "Marta's universe · tap an island or a card"; a "WAY HOME 5 s" chip with a clock icon.
2. **Universe chart** (`:772`, plan mode, 440 px): the Heart and six outer islands with links; the chosen route glows from the landing realm to the Heart; tapping an outer island picks its landing (`realm_diorama.js:1268`).
3. **Selection plate** (`:774`): the realm's emblem, its name (28 px), the edge name ("WEST EDGE"), a risk pill ("RISK LOW / MEDIUM"), and a panel with a coloured dot and the hearing line ("In fog · not heard"; "Open ground · heard: guards within 6 tiles start at 250 of 1,000"; "Tall grass · not heard") and "LAW Glowing dark".
4. **Landings** (`:776-777`): "LANDINGS · Badges compare with your pick" with a 1/3 pager; a snap row of 150-px cards, one per landing (`LANDINGS`, `screens_main.js:82-85`): a picture of the realm, a risk pill (LOW / MED), a check on the chosen one, a "BEST" sticker on the recommended one; three tiles NOISE ("Silent" or "50%"), CLOCK ("165s", "180s") and GUARDS ("2", "1"), each with a comparison badge against the pick ("+50%", "−15s", "+1"); and "1 hop · Rope", "2 hops · Rope + Bridge".
5. **Land button** (`:778`): "Land at Lantern Vale / 2 guards on the way · 1 hop to the Vault" with a dark "CLOCK 165s" block. It goes to the heist, not back to the planner.

The risk is `(heard ? 2 : 0) + guards + laws + (hops − 1)` and "best" is the lowest of it with the longer clock winning ties (`screens_main.js:265`).

### 4.3 Against the document

Matches: one choice per outer realm, the Heart not offered; heard or not with §5.4's own sentence for heard; the clock per choice from 150 + 15 per link (165, 165, 180); the skiff's 5 s home.

Deviations in §23.5: the percentage noise ("50%", "+50%", `screens_main.js:268`, `:276`); the chart's seven realms.

Deviations not in §23.5:
- **One fixed spot per realm** (N2's sibling, register N5b): the cards are three named spots ("west edge", "south bridge", "east edge"). §5.4 and §12.5 let the raider land on any edge tile of any outer realm, and §23.2 asks for "every outer realm's edge". Offering one curated spot changes what the player can do. §23.1's own render had per-tile markers.
- **No fault entry** (§12.5): when the target is overloaded, faults are an entry; the picker has no state for them (gap N13).
- **"Guards" is undefined**: the card's GUARDS and "2 guards on the way" do not match the scout report's counts (Crystalline 1 here, 2 in the scout), and the meaning is not said. If it counted guards within reach of the spot it would reveal positions. The build defines it as the scouted guard count of the realms on the shortest route.
- **Way home is one number**: 5 s is right for an outer realm; the chip should not suggest the skiff reaches the Heart in 5 s (it takes 20).

Must-show missing: every edge tile as a choice. Hearing and the clock are there.

Adds a mechanic: restricting landing to one named spot a realm; the percentage.

Silent adoptions: the chart with tap-to-pick; per-realm cards with a picture, the three metric tiles and the comparison badges; the recommendation sticker and the risk pill (both computed only from visible facts: heard or not, scouted guards on the route, laws new to the player, links); the realm emblem; the way-home chip; the land button with its clock.

### 4.4 Build today

`HeistController.land(t)` gives the landing command at tick 0 and `default_landing()` picks a reaching spot by seed (`client/features/heist/heist_controller.gd:181-200`); `RulebornReplay.landings()` and `reaching()` list open edge tiles (`client/ext/src/lib.rs:311-334`); `World::land()` applies the noise (`sim/src/lib.rs:1085-1119`). Everything is one island; there is no realm choice, no route and no clock by links (D71). The heist's ticks come from the lease (`service.mjs:483`), not from the landing.

### 4.5 How to build it

**Stage A, now, on the one-island heist** (this closes T3.4's "Not yet: §21's landing picker"):
- New `#[func]`s: `landing_heard(x, y) -> bool` and `landing_reach() -> int`, from a `World` method that `land()` calls (so the sentence on screen and the simulation cannot disagree).
- `scenes/landing.tscn`: the leased island drawn by `RealmView` in `planning` mode (terrain only), every open edge tile marked with a shape and colour: a filled leaf-green circle "Not heard" and a red ring "Heard" (shape plus colour, §20.8), tiles that do not reach the Vault marked "No way to the Vault from here" (from `reaching()`). Tap a tile → a plate with the tile's ground ("Fog bank · not heard" / "Open ground · heard: guards within 6 tiles start at 250 of 1,000 suspicion"; the 6 replaced by `landing_reach()` when a law stretches it), and "Land here".
- `RaidController.land(tile)` stores the tile; the heist screen calls `controller.land(tile)` before its first step, and `default_landing()` becomes the fallback for an offline stocked lease only.
- Test: a landing chosen on the picker appears as the replay's first command and its noise matches `landing_heard`.

**Stage B, with universes of several realms**:
- The realm level: the `UniverseChart` with `only` = the target's realms (no seventh island); a card per outer realm in a `CardDeck`: picture, name, the best spot's hearing ("Silent spots: 14 of 36"), CLOCK (150 + 15 × links of the shortest route from that realm, capped at 240; Haste noted on the card when a realm on the route runs it), GUARDS (scouted guards in the realms on that route), links ("1 hop · Rope bridge"), a risk pill and a "Suggested" sticker from visible facts only. Comparison badges against the pick, in words for screen readers.
- Tap a card or island → the realm's edge view (Stage A's screen for that realm).
- Faults (when the target is overloaded): an extra card "Through a fault", once the document says how it is shown (N13).
- "Land here" returns to the planner with the entry set (not straight into the heist, so the plan's crew and casts are seen once more; the design's direct start is a short-cut the planner's Start button already gives).

Effort: **L** overall; Stage A is **M** and buildable now.

---

## 5. Heist planner

### 5.1 What the document asks

- §23.2 row (line 11227-11229): "Heist planner | Plan the run. | Entry, route, crew, Sage, casts, clock, unfamiliar laws flagged".
- §23.5: "Heist planner crew | Takes two creatures the Roster shows resting | Resting characters cannot go | 12.5" (line 11440); the Trace fee (11430); 3D charts; Landscape. §23.5 says the planner otherwise follows the document and meets the text floor.
- Rules:
  - §12.5 (lines 6944-6958): Entry; "Route | A path of realms to the Heart and out again. The game proposes the shortest; the player can drag it through other realms."; "Crew | A crew of 3 to 5: 3 characters, 4 from Keeper level 8, 5 from level 16. Resting characters can't go."; "Sage | One, from Keeper level 2."; "Casts | 1 slot, 2 from Keeper level 12. A cast brings one of your own unlocked laws into their universe: it covers a circle of 4 tiles for 10 seconds and costs 30 Aether per point of the law's base cost."
  - §5.4 (line 834): the clock.
  - §7.8 (lines 3722-3753): laws on the route the player has never met: 1, 2, 3 at most by Keeper level band.
  - §11.1 (lines 5922-5970): every role carries (Scout 104, Breaker 104, Carrier 300, Warden 138, Mender 104), "so no one bag decides the haul" (line 5968); a Scout "Sees 8 tiles instead of 6".
  - §11.6 (lines 6165-6186): Working, Guarding, On a heist, Resting (45/60/180 minutes), Idle; "Waking early costs 2 Essence per level per minute left".
  - §11.7 (line 6190): "A player brings one Sage on each heist, and can station another at the Heart as its guardian."
  - §13 (line 7454): "Anyone guarding is someone not raiding".
  - §9.4 / F39 B / C41 B: the fee and its return. §12.3: no fee on a Trace. §12.11: friendly heists take nothing and pay no fee (the server's `grant()` charges none, `service.mjs:662-670`).
  - §23.5 adopted "Slower ruins" (line 11406): ruins at 75% speed as an accessibility option.

### 5.2 What the design shows (Gameplay_06; plan_* captures)

1. **Chart** (`:744-747`): the plan-mode `UniverseChart` with the route from the landing realm to the Heart; a back button to the scout report.
2. **Tabs** (`:753`): "Plan" and "Crew 5/5" with a red dot when the crew has a warning.
3. **Plan tab** (`:754-759`): a paper table of rows, label left, value right, chevron when tappable (`screens_main.js:604`):
   - Entry › "Lantern Vale · In fog · not heard" (→ landing picker)
   - Route › "Lantern Vale → Heart · 1 link" (→ landing picker)
   - Clock "165 s · 150 + 15 per link"
   - Crew › "5 of 5 · Pip, Mo, Bramble, Hollow, Ash" (→ Crew tab)
   - Sage "The Archivist · Suspend, Reveal, Recall" (not tappable)
   - Casts "Stillness · Half gravity" (not tappable)
   - Entry fee "2,840 Starlight · 2%"
   Under it: "Laws on the route" chips (Sleepwalk, Glowing dark) and a red "New to you: Sleepwalk" chip.
4. **Crew tab** (`:760-764`): a two-column grid of six crew cards (portrait, name, role in its colour, ability name, a green check when seated); a warning line ("No Scout: guards stay hidden until close" / "Empty seat: Keeper 24 takes a crew of 5" / "No Carrier: nobody can carry loot out", `screens_main.js:584`); a Sage strip ("SAGE The Archivist" and a "Haste × 1" pill).
5. **Start heist** (`:766`): "START HEIST / Land at Lantern Vale · 165 s on the clock". Blocked unless at least one seated member is a Carrier (`ctaOk`, `go`, `screens_main.js:605`).

Interactions: tap a crew card to seat or bench it, refused with an error sound when four are already seated (`full=!on&&pOn.length>=4`, `screens_main.js:600`), which contradicts the "5/5" the tab shows and the "Keeper 24 takes a crew of 5" warning (the counter also says "/ 4", `:604`). The casts row says Stillness and Half gravity while the Crew tab's Sage strip says "Haste × 1". The "New to you" chips come from a fixed list (`flags:['Sleepwalk','Glass']`, `screens_main.js:604`), not from the route.

### 5.3 Against the document

Matches: every row §23.2 names; the clock's formula and 165/180; the Sage's three powers named as §11.7 names them; unfamiliar laws flagged; the fee shown before the start.

Deviations in §23.5: resting creatures seated (line 11440); a fee on a Trace (11430).

Deviations not in §23.5:
- **No Carrier, no heist** (N14): "No Carrier: nobody can carry loot out" is false (§11.1: every role carries; "no one bag decides the haul"), and refusing to start without one is a rule the document does not have. It changes what the player can do.
- **Fewer than three**: the Start button accepts one seated member with a Carrier (`pOn.length>0`); §12.5's crew is 3 to 5.
- **"No Scout: guards stay hidden until close"** overstates §11.1: a Scout sees 8 tiles, the rest 6. As advice it is fine if it says that.
- **Sage and casts cannot be chosen**: both rows are read-only, with no picker, no slot count by Keeper level, no Aether cost for casts and no rule that the guardian Sage stays home.
- **Route cannot be dragged** (§12.5): the Route row opens the landing picker; nothing lets the player route through other realms, and nothing shows the way out.
- **Character states are not shown**: §11.6's resting timers, working and guarding are absent from the crew grid, so the player cannot see who is free or what a pick costs at home (a guard leaves its post, a worker its building).
- **Text below 13 pt on the Crew tab** (see §1.3 C), against §23.5's claim.

Must-show missing: choosing the Sage; choosing casts; dragging the route; rest state on the crew (§23.5's row makes it a rule, not only a look).

Adds a mechanic: the Carrier requirement; launching with fewer than three; the four-seat cap in the toggle (a prototype bug).

Silent adoptions: the chart over a summary table; Plan/Crew tabs with a warning dot; label/value/chevron rows; law chips and the "New to you" chip; the crew grid with role colour and ability name; truthful warnings ("No Scout: your crew sees 6 tiles, not 8"; "Empty seat: you can bring 5"); the Start button repeating the landing and the clock.

### 5.4 Build today

`HeistController` starts with a fixed crew of three (`CREW := 3`, `heist_controller.gd:22`) and the simulation's fixture roles. `heist_screen.gd` takes the first target and plays it. No planner, no roster, no Sage, no casts, no route. The lease brings the clock (`ticks`) and the fee preview (`stakes`).

### 5.5 How to build it

The planner is the screen where most unbuilt systems meet, so it is built in layers that each work on what exists.

**Layer 1, now (one island, fixture crew):** `scenes/planner.tscn`, `scripts/planner_screen.gd`, `features/raid/plan_presenter.gd`.
- Rows: Entry (the landing picker's tile, "Fog bank · not heard"), Route ("This realm" until crossing realms), Clock (from the lease's ticks: "150 s", "180 s in Quiet Week" from the era the lease names), Crew ("3 of 3"), Entry fee (from `stakes()`, with "No entry fee: Trace", "No fee: friendly heist", "No fee and no haul this week"), Laws on the route (the island's laws from `RulebornIsland.laws()`), and the start button. Sage and Casts rows say "From Keeper level 2" / "From your Codex" until they exist, rather than offering fakes.
- The heist screen starts from the raid slice's lease and plan.

**Layer 2, with the roster on the server (TC.12's next slices):**
- `GET /v1/roster` with each character's kind, role, level, state (working where, guarding which post, resting until, idle) and abilities' names.
- The Crew tab: a grid of `CrewCard`s (portrait, name, role word and colour, ability, state line: "Resting · 32 min", "Guarding Post 2", "Working · Star Well"); resting cards disabled with "Wake · 64 Essence" (§11.6's price; a mechanic the document already has); guarding and working cards selectable with the consequence said ("Leaves Post 2 empty for this heist"). Seats 3/4/5 by Keeper level; Start refuses fewer than 3 and says so.
- The simulation takes the crew as roles (and later kinds, levels and traits) in the replay header in place of a count (a replay-format change: new magic, the rules version moves, goldens re-recorded), and the lease names the crew so the server can check ownership and rest at validation.

**Layer 3, with law ownership and Aether:**
- Casts: a sheet listing the player's unlocked laws (Codex service), slots 1/2 by Keeper level 12, each with "30 × base cost" Aether; the simulation gains a cast command (a zone law, §5.1's Zone scope: a circle of 4 tiles for 10 s). When the Aether is charged is unwritten (N15).
- "New to you" from the Codex's met state; the §7.8 budget shown when the route carries more than the band allows ("2 laws you have never met; at your level the Observatory offers at most 1").

**Layer 4, with Sages and abilities in the simulation:**
- Sage: a sheet of unlocked Sages (Keeper-level unlocks, §11.7), the guardian excluded ("On guard at the Heart"), each with its three powers and uses; from Keeper level 2.
- Abilities shown on the crew cards with "2 uses".

**Layer 5, with universes of several realms:**
- Route: the chart proposes the shortest route; drag the route line through another realm's island to add it (and a two-tap alternative, §20.8: tap "Route through…", tap a realm); the way out drawn too; the clock stays the shortest route's (§5.4).
- Entry from the landing picker's realm and tile; the chart's `only` list.

Accessibility and states throughout: every row is a button with a spoken name; warnings lead with a glyph; offline (G41) the planner works on a stocked lease and says the heist "counts once the server confirms it".

Effort: **XL** across its layers (Layer 1 is **S-M**; the rest is mostly simulation and server work that the planner only draws).

---

## 6. Register-worthy items

Numbered N1-N15 here; the parent assigns ids. Each says what it is, the evidence, and what to do.

**N1. The owner's answers F39, C41, F44, F46 and F51 are not in v3.6, and Screens v3 draws the rules they replaced** (contradiction, significant). Evidence: `docs/decisions/answers.json` (F39 B, C41 B, F44 D, F46 B with "client: the target card shows laws, guards and ward counts", F51 B); v3.6 §9.4 line 4560 still "2% of the raider's Starlight, from 100 to 25,000, returned in full after a clean heist"; §12.3 line 6922 "within 3 Keeper levels"; §12.4 line 6936 the paid scout; §23.2 line 11237 now "showing only the free scouting facts (12.4)"; diffs.txt lists no change to §5.4, §9.4, §12.3, §12.4 or §12.22. Design: `data_v35.js:15` (fee from holdings), `screens_main.js:524` ("Keepers 21–27"), `screens_main.markup.html:649-652` (locked panel, paid scout). The server follows the answers (`server/src/economy.mjs:163-178`; `service.mjs:532`). Rec: the owner confirms whether the answers stand; if they do, apply their drafted edits in v3.7 (they are in the brief's `doc_edit` fields) and reword §23.2's Observatory row ("showing name, Keeper level, realms, Renown, rough loot, and each realm's laws, guards by role and ward counts"); the screens follow the answers and draw the fee per target from the server.

**N2. The scout report shows guard posts, ward positions and patrols** (deviation, significant; not in §23.5). Evidence: §12.4 line 6936 "but not where they are"; §12.12 line 7141 "A scout shows no positions (12.4); patrols are learned in the heist"; C37 fixed by brief 38; design `realm_diorama.js:267-276` (guard reach discs, "×N" pins, ward rings and "✦" pins), `screens_main.js:532`, `:537-540` (patrol sentences, post and ward coordinates), Threats tab "5 wards · 3 hidden traps". Rec: add the row to §23.5 ("Scout report | Guard posts, ward rings and patrol notes on the 3D view | No positions and no patrols | 12.4, 12.12"); build the scout view without them.

**N3. What of a target's layout the raider sees before the heist is unwritten** (gap, significant). Evidence: §5.4 line 822-825 (any edge tile; heard unless "in fog, darkness or tall grass" — the raider must see edge terrain to choose); §12.12 line 7141 (no positions); §10.3 (Crystal Wall and Thorn Hedge "Seen: Always"); §11.8 line 6229 (the Cartographer's map "with ward positions"); F46 (the bundle is public anyway). The design shows the whole 3D realm with buildings, the Vault and a route to it. Rec: one sentence in §12.4 saying what the planner and scout draw: proposed, the ground and terrain of every realm, the Vault, and the always-seen wards, with no guard posts, hidden wards or pylons until the heist (or a Cartographer's map).

**N4. Generated targets have no label in the Observatory** (deviation, significant; must-show via §12.22). Evidence: §12.22 step 4 line 7433 "labelled as a generated target at the point of attack … must not pass as another player's" and "labelled with the band they come from"; design final tag `screens_main.js:525` labels anything not a Trace as "ECHO". Rec: §23.5 row; the build carries a `generated` flag and a GENERATED ribbon.

**N5. Drifting ruins: three ruins at one difficulty each, or three ruins with three difficulties each** (gap, significant). Evidence: §12.10 line 7115 "three universes built by the game each day"; §12.12 line 7135 "Every ruin offers three openly labelled difficulties with their rewards shown, and a recommendation the player can ignore"; §23.2 line 11237 "drifting ruins apart, at three labelled difficulties (12.12)"; design `screens_main.js:526` (three tiles, Easy/Medium/Hard, no rewards, no recommendation). Rec: decide; by §12.12's rule text, each of the three ruins opens to its three difficulties with rewards and a "Suggested" one; reword §23.2 to match.

**N5b. The landing picker offers one named spot per realm** (deviation, significant; must-show). Evidence: §5.4 line 822 "any edge tile of any outer realm"; §12.5 line 6944; §23.2 line 11293 "Every outer realm's edge"; design `LANDINGS` `screens_main.js:82-85` (three spots). Rec: §23.5 row; the build adds the edge view per realm.

**N6. A target card's depth, before a landing is chosen** (gap, minor). Evidence: §12.22 line 7424: depth is "the number of realms the route from the landing realm to the Heart crosses" and "Every offered target shows its depth", but the landing is chosen after the card; "crosses" does not say whether the landing realm and the Heart count. Design: "1 realm to the Heart" for a one-link route. Rec: define the card's depth as the shortest route from any outer realm, counted in links (which the clock already uses), or as the matchmaker's own centre value; one sentence in §12.22.

**N7. Where a Trace target sits in the list** (gap, minor). Evidence: §12.3 line 6932 (Trace once within 24 h, free scout, no fee) and §12.22's guarantee about "the median offered target"; design puts the Trace target as the first of three cards. If it takes a slot, the list's middle moves and the guarantee is measured on a list the matchmaker did not choose. Rec: the Trace card is shown in addition to the three to five, pinned first.

**N8. Whether a scout shows loot by realm** (gap, minor). Evidence: §12.4 lists "a rough loot estimate" as free and not loot by realm as paid; §9.4 "Storehouses in outer realms … are fully exposed, so where you place them decides what raiders pass" and "scouting changes the decision"; design strip "~420", "~260", and "~3,300 VAULT · 77% of total". Rec: decide; if yes, add "and each realm's rough exposed loot" to §12.4's scout list.

**N9. What a target card shows of a 13-15 target** (gap, minor). Evidence: §12.4 free facts include "name"; §20.2 "Profile | Private" for 13-15 (private by default for 16-17); §17.8 line 8979 "raids are anonymous while they happen"; the client already names other players "Keeper" and the first letters of their account (`client/README.md`, Friends). Design shows first names. Rec: say in §12.4 or §20.2 whether a minor's name appears on a raider's card; propose "Keeper" and the realm's word-list name for 13-15.

**N10. The scout's 15 minutes, and a plan made without one** (gap, minor; moot if N1's F46 B stands). Evidence: §12.4 "A scout stays valid for 15 minutes"; §13 line 7486 "the scouting rules (laws are always visible before you commit)"; design's "Plan without scouting" and no expiry anywhere. Rec: if the paid scout stays, say what the planner shows unscouted (laws on the route hidden, "New to you" unknown) and what happens when a scout lapses during planning.

**N11. §23.5's text-size row is not accurate for the planner** (finding, minor). Evidence: §23.5 line 11515 "only the heist, planner and result meet the floor"; the planner's Crew tab draws 9, 10.5, 11 and 12 px (`screens_main.markup.html:761-763`). Rec: correct the row.

**N12. Typefaces** (deviation, minor; every screen). Evidence: §21.8 line 10992 (Baloo 2, Marcellus) and §21.11's licence ledger (two typefaces); design uses Manrope throughout and Lilita One on the landing picker (`screens_main.markup.html:773-778`). Rec: §23.5 row "Type | Manrope and Lilita One | Baloo 2 and Marcellus | 21.8", or adopt the design's faces and add them to §21.8 and the ledger.

**N13. Entry by a fault: where it is offered and whether faults show before the heist** (gap, minor). Evidence: §12.5 line 6944 "or a fault if the target is overloaded"; §5.4 "Faults" row; nothing in §12.4 says a target's faults or strain band are visible; the design has no fault state. Rec: one sentence in §12.4 (the strain band and open faults are free facts, or scout facts) and a card in the landing picker.

**N14. The planner refuses to start without a Carrier** (deviation, significant; adds a mechanic; not in §23.5). Evidence: §11.1 lines 5922-5968 (every role carries 104 to 300; "so no one bag decides the haul"); §12.5 (no role requirement); design `screens_main.js:584` ("No Carrier: nobody can carry loot out"), `:605` (`ctaOk` and `go` require a Carrier); the TRY note "without a Carrier you cannot launch". Also launching with fewer than three (`pOn.length>0`) against §12.5's 3 to 5. Rec: §23.5 rows; the build warns ("No Carrier: your bags hold less") and never blocks, and requires the crew size §12.5 gives.

**N15. When a cast's Aether is paid** (gap, minor). Evidence: §12.5 line 6956 "costs 30 Aether per point of the law's base cost"; §24.13 puts the entry fee at validation, not at lease; nothing says whether a cast is paid when planned, when cast, or refunded if unused. Rec: one clause in §12.5; proposed "paid at validation, only for casts used", matching the fee.

**N16. The Wanderer makes a sixth target** (contradiction, minor). Evidence: §12.3 line 6922 "3 universes (5 at level 5)"; §10.2 lines 5726-5755 (3, 3, 4, 4, 5); §11.7 line 6215 Wanderer at home "The Observatory offers one more target"; §23.2 "Three to five universes". Rec: say "three to six" in §12.3 and §23.2, or make the Wanderer's bonus stop at five.

Also for the parent, not a register item: `GET /v1/offer` sends each target's `rating`, `deviation` and `predicted` to the device (`server/src/matchmaking.mjs:199-205`, `:262`), which §12.15 says are never shown, and takes its list size from the query (`server/src/http.mjs:517`) instead of the player's Observatory level. Both are fixed by the Observatory view model in §2.5.

---

## 7. Proposed roadmap tasks (stage SC)

In order; each names what it waits on.

| Task | What | Waits on | Effort |
|---|---|---|---|
| TC.15a | Landing picker, Stage A: `landing_heard`/`landing_reach` in sim and the extension; the edge view on the leased island; the chosen tile as the replay's first command; `default_landing()` only offline | nothing | M |
| TC.15b | The raid slice and controller; routes; Home → Observatory; heist starts from the raid's lease | nothing | S |
| TC.15c | Observatory view model on the server (size by Observatory level, reasons, flags, fee per target, caps, shield; no ratings) and the Observatory screen with Trace, echo and capped states | N1 answered | M |
| TC.15d | Planner Layer 1 (entry, clock from lease, fee, laws, start) | TC.15a, TC.15b | S |
| TC.15e | Scout report on one island: `RulebornIsland.scouting()`, planning-mode RealmView without positions, law chips → law card, LAST TIME | N1, N2, N3 answered; law card from the Weaving/Codex plan | M |
| TC.15f | Matchups module (rules-driven) and the Crew tab | roster data (TC.12) | M |
| TC.15g | Aether ledger; refresh; paid scout if N1 keeps it | G42 production slice | M |
| TC.15h | Planner Layer 2 (roster, rest, guarding, wake) with the crew in the replay header | TC.12 roster; sim crew composition | L |
| TC.15i | Planner Layers 3-4 (casts, Sage) | Codex service, Aether, sim casts, Sages and abilities | L |
| TC.15j | Multi-realm: Observatory universes, scout per realm, landing picker Stage B, route drag, depth | crossing realms (T3.3 "Not yet"), D71 | XL |
| TC.15k | Ruins and generated targets in the Observatory | D66's generator port | M |
| TC.15l | The 3D look: `UniverseChart` with `only`, the scout `RealmDiorama` without positions, sky art per target | the art pass (§26.2's art-style test) | L |
