# Screens v3 and v3.6 against the plan: the register, the roadmap and the completion figure

For the owner and the lead. "The register" is `tools/audit_register.py`, "the roadmap" is `tools/roadmap.py`, "completion" is `tools/completion.py`. Design-document sections are v3.6's (`docs/design/ruleborn-game-design-v3.6.txt`), with the line where the words matter. Reader reports are the files beside this one in `scratchpad/analysis/`.

## 0. What I read and ran

- **The roadmap**, all 1,387 lines; **completion**, all 464; **the register**: its header, `FRONTEND`, `BOTH`, `side_of`, `GATE_OWNER`, `DESIGN_GATES`, `DEPENDS`, `status()`, and every open item's body, recommendation and version notes. I listed the open items by importing the module, not by reading the generated page (`rr_scripts/open_items.py`, `rr_scripts/dump_open.py`, output `rr_open.json` and `rr_open_full.txt`).
- **The owner's answers**: `docs/decisions/answers.json`, and `brief.json` for the label of each chosen option.
- **Completion, run**: `python3 tools/completion.py`. I worked out each row's weight in points with `rr_scripts/weights.py`. Each row is its phase's §26.8 midpoint, shared equally between the phase's deliverables, as a share of that side's total.
- **v3.6**: the opening's "What changed" (lines 80–92), §14.4, §16, §18.2, §18.8, §20.8, §21.9, §23.1–§23.5, §24's engine row, §24.7, §26.2, §26.6 and §26.8, plus the v3.4→v3.6 section diffs in `v36/diffs.txt`.
- **Reader reports**:
  - All eight `screens-*.md`, in full where they cover what is built today, the plan, the roadmap and the register. The rest I searched by item id.
  - `design-system.md`: §1 and §8–§12.
  - `3d-pipeline.md`: §1, §2 and §7–§9.
  - `characters.md`: its summary and findings list.
  - `engine.md`, which the lead wrote.
- **Checked in the build myself**:
  - The engine pins: `client/project.godot:12`, `client/ext/Cargo.toml:11`, `client/ruleborn.gdextension:5`, `client/build.sh:13`, `client/export.sh:21,26`, `client/export_presets.cfg:27-28,92`.
  - `client/scripts/ui.gd:138,321` and the router's 13 routes (`client/app/router.gd:8-21`).
  - `client/status.json`: 100 of 100 tests passed.
  - The word shades in `client/ui/tokens.json:80-94`.
  - The 75% pace in `client/tests/a11y_tests.gd:325-349` and `client/scripts/heist_screen.gd:30,207`.
  - The simulation's command kinds (`sim/src/replay.rs:53-92`), its terrain features (`sim/src/grid.rs:116-137`) and `content/terrain.json` (39 rows).
  - `sim/systems.json` and `tools/design_facts.py:102`.
- **Not done**:
  - I did not run Godot, the client or the server.
  - I did not re-measure any reader's Screens v3 figure. Contrast, triangle counts and similar numbers are theirs and are attributed.
  - The Godot 4.7.2 measurement (100 of 100 tests after one change) is the lead's, from `engine.md`.
- **Moving target**: the lead is editing `tools/audit_register.py` in the working tree as I write. It has an empty `FOUND_IN_V36` and an empty `V36` layer. The open list here was computed with that layer empty. Line numbers into that file are as of this reading.

## 1. Summary

### The register

- **70 items are open.** `side_of` puts every one of them on the backend side. Everything in the `FRONTEND` and `BOTH` sets is settled. `DESIGN_GATES` has no open gate for screens or characters; its only open gate is C19, under realms. C37, named in the brief, is fixed.
- **v3.6 resolves none of the 70.**
  - Its text touches 15, all without closing them: C35, F37, G28, F41, F38, F35, F46, G40, D71, F55, D62, G31, F56, G30 and G42.
  - Screens v3 touches about 40 more (table in §3.3).
- **The biggest effect on the plan is the owner's answers.** The owner answered 47 items on 25–26 September, and the build follows them. v3.6 took none of them. v3.6's §23.5 also makes the document win over the designs, so a screen now has three sources that disagree:
  - the document;
  - the design;
  - the owner's answer that the server already follows.

  Examples:
  - The Shop is priced in Starglass in both §22.1 and the design. The build has no currency (F41's answer).
  - The scout report shows positions in the design. §12.4 sells counts, and F46's answer makes scouting free.
  - The fee and the matchmaking window follow F39, C41 and F44 on the server, and the old text everywhere else.

  This is finding 1.

### The completion figure

- **The figures today**:
  - Frontend: 75.41% of 82.35 agent runs.
  - Backend: 89.24% of 155.65 agent runs.
- **Only four frontend rows are left**:
  - Project structure: 4.86 points.
  - Localisation in English and Brazilian Portuguese: 8.80.
  - Real-device matrix: 5.46.
  - Fix buffer: 5.46.
- **No Screens v3 task moves a frontend point by itself.** Completion counts §26.8's list, and §26.8 costs:
  - none of the 20 §23.2 screens outside the heist, the builder, the Workshop, the shop and track, the social screens and settings;
  - no design port;
  - no 3D world.
- **Where the work does lead to points**:
  - **Project structure (4.86):** the engine move to 4.7.2 is a precondition, because v3.6's store builds must be on 4.7.2, at API 36 and in Xcode 26. The row also needs a proof that reads a build result; today it is hard-coded as not started.
  - **Localisation (8.80):** needs every launch screen to exist first, then the owner's native read.
  - **Devices (10.92):** owner-gated.
- **The port can only lower the figure.** If it breaks or renames any of the 100 client tests that the done rows read, the figure drops (table in §2.4).
- **Two rows read done while holding a fraction of what they name**:
  - Crews (phase 1, backend): there are no abilities, Sage powers or casts in the simulation. Nothing in the register or the roadmap tracks them.
  - Terrain editing (phase 4, frontend): the simulation has 5 of the 39 features.

  This is finding 3.

### The roadmap

- **TC.7 becomes done.** The owner delivered the design, and §23.5 records it.
- **Its remaining Claude work becomes new tasks**, TC.15 to TC.41, in four tracks:
  - the foundation: the engine first, then tokens, components, motion, icons and the shell;
  - the 3D world;
  - the simulation and server the screens stand on;
  - the screen groups.
- **Two new tasks are the owner's**: TC.42, the rules the design leaves open, and TC.43, §26.2's pre-production exit.
- **Existing tasks to amend**: TC.3, TC.5, TC.8, TC.12, TC.14, the locks T5.1 and T5.4, and S6 and S7. S6 and S7's gates still name outside playtesters that §26.2 removed in v3.3 (finding 10).

## 2. How completion counts, and what can move it

### 2.1 The rules

These are the rules as `completion.py`'s docstring and code state them (`tools/completion.py:1-29, 188-418`):

- **Weights:** §26.8's phase midpoints, read from the document on every run. Inside a phase, each named deliverable takes an equal share, on the side of the app it lives on.
- **Deliverables:** §26.8's own list.
- **Done is read from results only**: sim systems whose tests all pass, server tests by name, client tests by name, content counts, or the checksum targets.
- **A missing proof**: `not_started(...)` is a hard 0. A proof that names a test which no longer exists fails `--self-test`, which `tools/check_all.sh:158` runs as a gate.

v3.6 did not change §26.8's run table. Only phase 0's note changed, so the weights are the same as on v3.4. I checked this by parsing both documents' tables.

### 2.2 What is left, in points

**Frontend: 75.41%.** Points are shares of 100 frontend points.

| Row (§26.8 phase) | Points | Proof today | What would count it | Who |
|---|---|---|---|---|
| Project structure (2) | 4.86 | `not_started("a client project builds on both stores' targets")`, `completion.py:204` | Both store builds, on Godot 4.7.2: Android at API 36 and iPhone in Xcode 26 with the iOS 26 SDK. v3.6 also asks for an upload to the Play internal track and TestFlight (§24 engine row, line 11643; §26.6, line 12439). A proof must read a recorded build result. | Claude: TC.15, then TC.3's check. Owner: a host for the Android SDK and NDK, and a Mac with Xcode 26 and the App Store team. |
| Localisation: English and Brazilian Portuguese (10 to 13) | 8.80 | `not_started`, `:352` | "Every launch screen and content name ships in both languages, the Portuguese read by a native speaker". Ten of the 28 launch screens exist today. | Claude: every screen task adds its words. Owner: the read (§26.9). |
| Real-device matrix (14) | 5.46 | `not_started`, `:381` | The client runs on the device matrix | Owner |
| Fix buffer (14) | 5.46 | `not_started`, `:383` | Launch fixes are closed | After the matrix |

**Backend: 89.24%.** Rows still open on the backend side:

- **Phase 0, the two phones:** 3.21 points, 1.61 for each target. They need the same store builds plus devices (T3.1).
- **Compliance, store declarations:** 4.66 (TC.14, the owner's filing).
- **Balance pass:** 2.89 (F55).

### 2.3 What each proposed task can move

Each row below is a task proposed in §4.3.

| Task | Frontend points under today's rules | Condition |
|---|---|---|
| TC.15: engine to 4.7.2 | 0 | It is the precondition for TC.3's 4.86, because v3.6 requires the store builds on 4.7.2. |
| TC.3, rewritten for v3.6 | +4.86 | Both stores build. The proof must also change to read a build record, for example `client/builds.json` written by `export.sh` with the engine version, SDK levels and the artefacts' digest. One option is to count each store separately, as `targets()` counts each platform for phase 0: 2.43 per store. That is a choice for whoever writes the proof, not a rule. |
| TC.16 to TC.19: tokens, components, motion, icons | 0 | No §26.8 row. They can lower the figure if Accessibility or Portrait interface tests fail (§2.4). |
| TC.20: the shell | 0 | Can lower Portrait interface. The design's chrome sits in the top band and the corners, where the layout check fails it (`screens-home-realm-shell.md` §1.5). |
| TC.21 to TC.25: the 3D world | 0 | No §26.8 row for art (3D report, finding 11). |
| TC.26 to TC.30: the simulation and server underneath | 0 frontend, 0 backend | Crews already reads 100%. If its proof gained the missing system (finding 3), the backend would read 0.41 points lower until TC.26 lands. |
| TC.31 to TC.41: the screen groups, Profile, Settings, First launch, Slower ruins, Landscape | 0 each | None has a row. Each must keep its tests' names and keep them passing (§2.4). TC.37 Profile and stats has no row on either side. |
| TC.5 after every launch screen exists | +8.80 | The owner's native read. |
| TC.8 | +5.46, then +5.46 | Devices. |

So, under completion's rules:

- Claude alone can move the frontend figure by **0 points**.
- Adding the owner's SDK host and Mac makes it **+4.86**.
- After every launch screen and the native read: **+8.80**.
- On devices: **+10.92**.

### 2.4 Rows the port can lower

Each row is proved by named client tests. A test that fails lowers its row by its share. A test that is renamed without changing `completion.py` in the same commit fails the self-test.

| Row | Points | Tests | Per test | Touched by |
|---|---|---|---|---|
| Accessibility | 8.80 | 12 | 0.73 | TC.16 to TC.18: contrast on the dark and parchment surfaces, and outlined text. TC.40: the "rehearsal … 75%" test. |
| Portrait interface | 4.86 | 3 | 1.62 | TC.17 and TC.20: controls in the top band and corners, text under 13 pt. |
| Localisation (phase 2) | 4.86 | 2 | 2.43 | Every screen task: words must come from the catalogue. |
| Save and settings | 4.86 | 1 | 4.86 | TC.38 |
| Render a replay | 5.67 | 3 | 1.89 | TC.24 and TC.31 |
| Capture input | 5.67 | 5 | 1.13 | TC.26, which changes the replay format and the goldens; TC.31; and TC.32's landing picker |
| Show a result | 5.67 | 2 | 2.83 | TC.31 |
| Terrain editing; Laws on the island; Testing your own defence | 5.77 each | 1 each | 5.77 | TC.29, TC.33 and TC.35 |
| Workshop screens | 8.50 | 9 | 0.94 | TC.35 |
| Shop, track and wallet screens | 4.37 | 8 | 0.55 | TC.36 |
| Social screens | 4.86 | 5 | 0.97 | TC.36 |

The gate for every task in §4.3 is the same, whatever else it says: `python3 client/status.py` shows 100 of 100 (or more) passing, and `python3 tools/completion.py --self-test` passes.

### 2.5 Why the figure cannot follow Screens v3

§26.8's phases cost the heist prototype (phase 3), the builder (phase 4), the Workshop (phase 7), shop and track screens (phase 8), social screens (phase 9) and settings (phase 2). Completion counts exactly those.

**The 28 §23.2 screens against completion:**

- **Eight have a completion row:** Heist, Heist result, Terrain editor (as the builder), Island Workshop, Season (the track), Shop, Friends, Settings.
- **Twenty have no row:** Universe map, Law card, Realm view, Weaving, Heist planner, Observatory, Scout report, Roster, Character, Sage hall, Law Codex, Resonance Lab, Defence curation, Rehearsal and defence log, First launch, Landing picker, Harmony view, Forms album, Share sheet, Profile and stats.

**The 28 screens against the build** (13 routes, `client/app/router.gd:8-21`):

- **Ten exist in some form:**
  - Universe map, as the home list plus the universe list;
  - Heist;
  - Result;
  - Season, as the track plus the league in the social screen;
  - Shop;
  - Settings;
  - First launch, as the age step only;
  - Terrain editor, as the builder;
  - Workshop;
  - Friends.
- **Eighteen have no screen at all.**

The design-system port and the 3D world have no row either.

This is G42's shape: G42 found no phase for the home economy, and TC.11 and TC.12 say "no figure moves". Here it applies to the interface. The honest fixes are:

- give §26.8 a costed phase, or rows inside phases 2 and 3, for the interface screens and the art;
- until then, the roadmap says plainly that the frontend figure measures §26.8's list and not the screens.

**For scale only.** This is arithmetic on completion's own rules, not a forecast. The frontend has 62.10 of 82.35 runs done. If §26.8 added R frontend runs that are not yet built, the figure would read 62.10 / (82.35 + R):

- R = 20.5, the midpoint of the 3D reader's 16–25 runs for the art alone, gives **60.4%**;
- R = 50 gives **46.9%**.

## 3. The register, item by item

### 3.1 Its shape after v3.6

- **The sides**: 70 items are open, and all have the status "open". `side_of` (`tools/audit_register.py:8022-8027`) puts all 70 on the backend side. The `FRONTEND` set (C9, C11, C20, C17, G9, G11) and the `BOTH` set (C6, C8, C10, C24, C26, G12, G3, D6, Q5, F16, F12) are all fixed. So the audit page's frontend side shows nothing open while Screens v3 is all frontend work.
- **The owner's answers name client work for ten open items** (`answers.json`, the `client` field): F37, F38, F41, F43, F46, F54, G19, G29, G34 and G35. They are filed as backend (finding 11).
- **The design gates**: `DESIGN_GATES` has no open gate for screens or characters; realms keeps C19 (`:8064-8127`). The screens area still says "The 27 screens in §23" and closes C11 as "27, not 23" (`:8108`, `:8113`), while §23.2 now lists 28 (finding 6).
- **C37 is fixed.** v3.6 records it as brief 38 in §32.8: "A scout shows no positions." Screens v3's scout report draws guard posts, ward positions and patrol routes all the same (`screens-observatory-scout-landing-planner.md`, a significant deviation that §23.5 does not list). So C37 stays fixed in the document, and the port must not draw positions.

### 3.2 The items the brief named, and the age protections

#### D72: alarm red and success green contrast, and grayscale (open, minor)

- **v3.6:** does not touch §21.8 or §21.10. D72's drafted edit (`:8377-8394`) still applies to unchanged text.
- **Screens v3**, as measured by the design-system reader:
  - **Success green improves.** Green words on the design's dark surfaces read at 7.6:1 (#3FBF7F) and 11.4:1 (#8FF0A8).
  - **Alarm red is the same or worse:**
    - white on #E2536B: 3.69:1;
    - the red count badges: 2.7–2.8:1 on screen;
    - red words on night: 4.19:1 on screen, Lc 35–37.
  - **The design's red fills end on #C42040**, which carries white at 5.79:1. That is the same answer as the client's #B3203A.
  - **In the heist HUD**, the alarm uses #E2536B as a fill for bells 4 to 6 (`screens-heist-result.md` §1.2). That is a mark, not words, which D72's reading allows.
  - **The grayscale half (§21.10) was not measured on Screens v3's island by any reader.** Its state is unknown.
- **For the plan:**
  - TC.16 carries D72's word shades for both of the design's surfaces, dark and parchment.
  - The drafted edit must be extended beyond paper panels.
  - The register and the client disagree on the shades themselves (finding 7).

#### C37: what the scout shows (fixed)

See §3.1. It does not change the plan beyond the port not drawing positions.

#### G41: offline as the exception (open, significant; the owner answered C; the client is built in TC.9)

- **v3.6:** does not change §24.12.
- **Screens v3:** draws no offline state for the player's own connection. "OFFLINE · n" appears only as friends' presence (`screens_meta.js`).
- **For the plan:** the build's TC.9 states keep their behaviour and are drawn with the design's components (TC.17). They are the lease stock, the offline prompt, the confirming hauls and the reconnect banner. G41 closes when the document takes the drafted §24.12 edit.

#### G35: friends are made by invite, and 13–15s are kept out of feeds (open, minor; the owner answered B; built)

- **v3.6:** does not change §12.11, §17.6 or §20.2.
- **Screens v3**, per the season reader:
  - The Share sheet lets a 13–15 post a clip to the Beacon feed. That is against G35's answer, and is the reader's SS16.
  - Friends show presence and a live "Raiding Ines" status, which §17.8 forbids (a significant deviation).
  - Presence and pings are not in the document (SS18).
- **For the plan:** TC.36 keeps the server's rule, which is that a 13–15's heists appear in no feed. Posting by a 13–15 and presence wait for the owner (TC.42).

#### G26: the Workshop's figures (open, significant; the owner answered B; built)

- **v3.6:** does not change §18.6 or §20.12.
- **Screens v3:** draws "SLOT 2 OF 5" for a Builder, where the server reads 8. Its "Fair budget 62% · Lv 6 band" is corrected in §23.5 (line 11492: "30 to 45% held at every level").
- **For the plan:** TC.35 draws the server's constants. G26 closes when §18.6 states them.

#### Age protections across the plan

- **The open register items about age:**
  - C43: word-list names for everyone. The owner answered A, and the design's name sheet agrees ("Names are built from word lists").
  - G35: see above.
  - D70: the deletion button.
  - F43: the choice to withdraw islands on deletion.
  - G39: deletion from the web.
  - G34: a minor's night.
  - D64: family approval for 13–15s is not built.
  - F41: a minor's spending caps.
- **v3.6 §23.5 corrects three rows:**
  - the share sheet's band (line 11461);
  - protections shown locked for 13–15s (11521);
  - the account tab highlighting the player's band (11526).
- **The settings reader found more**, for the lead to register:
  - The age-band preview changes the player's band (SF1).
  - The age step pre-selects 13–15 and has a way back from under 13 (SF2). The built check, TC.10 at `client/scripts/age_screen.gd`, already does neither, so the port must keep the build's behaviour.
  - Purchases show no caps (SF3).
  - A 13–15 is told "A parent can change these" (SF4).

### 3.3 Every open item

Key to the "v3.6" column: "—" means v3.6 does not touch the item's sections. Screens v3 entries are as the readers report them; "none reported" means no reader connected the item to a screen.

| Item | v3.6 | Screens v3 | What it means for the plan |
|---|---|---|---|
| C19: production tables | — | The design's numbers are not a source (§23.5, "One data file"). Its Aether 31,400 and Lab 5 h 30 are corrected to §10.2. | None. Screens read numbers from `content/` and the server. Owner's call (GATE_OWNER). |
| C35: Codex day 69 against day 234 | §14.4 adds the free-lane row, "not in the day counts". §14.3 is unchanged. | Codex counts only | None |
| F33, F52, F53: the Glare's reach, the base | — | none reported | None |
| G17: four terms of a settled raid | — | The result draws a fee line. | Draw the server's fee and haul. |
| C40, G21, F45, G32, D67, F47, G33, G37, F49, F50, G43, G24 | — | none reported | None |
| G18: a ward ignores its disarmer only on its tile | — | Not reported. The design's heist has no disarm walk. | None |
| F35: the crack's reach | §32.8 adds brief 37's row, "a ring around the Vault … shipping at 5 m". The owner's answer (D: no guard hears the Vault) is built and is not in v3.6. | The design draws a 5 m ring and a "Cracking · heard within 5 m" banner whose bar times the 5-second hearing cycle, against the answer (`realm_diorama.js:208`; `screens_main.markup.html:804`). It shows no Vault health. Neither the ring nor the banner is built. | Build follows the answer; part of finding 1. |
| F36: the raid-worth base | — | none | None |
| F37: a non-raider's levels and pages | §14.4 names the free lane but leaves it out of the counts. "The Library alone" stays. The owner's answer (B: goals and ruins) is not taken. | Draws quests, not §14.6's goals, and draws drifting ruins in the Observatory. | Client half of the answer: goals (server and Season, TC.36) and ruins (TC.30 and TC.32). |
| G19: the Heart's realm level | — | "The Heart 6" (the Spire's level) | Home and realm view label it from the server (realm level 3). The client half of answer B is that the builder locks it. |
| G20: day and week caps | — | Not drawn | Variants in the Observatory and result (TC.31, TC.32) |
| F38: strays against births | §11.8: the Stray is one of the eighteen kinds, which overrules the design's kitten. The rate is untouched. | No births screen (roster reader) | The adopt prompt at the next birth's price (TC.34, TC.36's track stray) |
| F39, C41, F44: fee, its return, the Keeper window | — | The Observatory, planner and result draw the replaced rules (observatory reader N1). | The cards read `stakes()` and the offer. Finding 1. |
| C42: the stray rate | — | — | None |
| G22: staffing order | — | One-tap reassign needs a default slot (roster reader M). | The default tap is the model's staffing order (TC.34). |
| D60: the bundle's Vault level is taken on trust | — | The realm view would publish the player's own realm. | Closes with TC.12's "builder publishing to own realms" slice. |
| G23: launch-law readings | — | Law card texts | Card text comes from content, with the readings written in (TC.33). |
| G25: §8's one-line rows | — | Weaving and Harmony compute the effects. | Effect strings from `client_strings.py` (TC.33) |
| D61: no chord draw, no crown laws | — | Crown laws invisible on home and the realm view (home reader) | TC.28: a stability module, and crown laws in the bundle |
| G26: Workshop figures | — | Builder slots 5 (server: 8) | See §3.2 |
| D62: no hold-band check before publishing | §23.5 row: "30 to 45% held at every level" (11492) | Invented hold figure (`js:123`); "a person reviews it within an hour" | TC.30's measurement queue closes the check. |
| C43: island names | — | Word lists for everyone, which agrees with answer A | None |
| F40, G27: Renown, league boundaries and rewards | — | Thresholds 0/600/…/3,600; rewards for every league, by the highest league reached (deviation) | Draw `leagues.json` and what the server grants (TC.36). |
| D63: constellations | — | The Constellation screen is version 1.1 and not drawn. | None |
| F41: Starglass | §18.8 now gives the free track pages, Essence and a stray, with no Starglass. §9.1 (4413-4416), §19.12 and §22.1 (11104) unchanged. | Shop and Starpass priced in Starglass (SS10) | The port prices in money, against §22.1's text. Finding 1. |
| F42: points or stars | — | Stars | None |
| G28: the track's numbers | §18.8 and §14.4: the free lane's contents named, pages "a few a season" (the server gives 25: five at tiers 5, 15, 25, 35 and 45, `server/src/track.mjs:51-53`) | 30 tiers (§23.5: 50); the Starpass adds 20% stars, which §18.8 forbids (SS1, blocking) | Draw the server's track. Refuse the +20%. |
| D64: no authored cosmetics; pages and strays on the device | — | Shop rails show looks, not authored sets. The result needs pages, rest and strays from the server. | TC.12's pages and roster slices come before TC.31's result. Authored sets are the owner's or an artist's. |
| G29: the session and the survey | — | "Worth your time" is two-point and per heist; the server takes 1–5 per session (heist reader F4). | The worth widget once a session, waiting on F4 (TC.42) |
| D65: no heatmaps, no error reporter | — | The result's decisive moment needs the simulation's event log. | TC.27 (event log) is half of D65's position export. |
| F43: what deletion keeps | — | The deletion line drops "withdraw my islands too". | TC.38 offers it, which is the answer's client half. |
| G30: Glicko-2 constants | §23.5: Profile header "Rating", corrected to Renown, and the rating stays internal | Profile says "RATING". | TC.37 header says Renown. |
| D66: no generator or crews in the simulation | — | Ruins at three difficulties, unlabelled fallbacks, three named rehearsal crews with no behaviour, curation alternatives | TC.30 (XL) gates ruins, rehearsals, curation, fallbacks and Slower ruins. |
| G31: pricing what a crew carries | §23.2's Rehearsal row now asks for each raid's report: "the haul denied, how long the defence held, where the crew was seen, what fired" | The report is drawn. The lab reader found the four measures undefined for one raid. | The defence log (TC.35) needs G31's price for "the haul denied". |
| F46: the scout is public | §32.8 records brief 38 ("no positions"). Answer B (a free scout; the card shows laws, guards and ward counts) is not taken. | The scout shows positions and patrols (deviation). | TC.32: a card per F46 B, and no positions. Finding 1. |
| G34: notification clock and night | — | The daily reminder is on at 18:30 by default (deviation). | TC.38's picker offers no time inside the night, and the IANA zone is sent on every launch. |
| D68: device notifications | — | "Season rewards" notifications, and no "experiment finished" | Device timers and permission (TC.8) |
| F48: friendly heists | — | The friend sheet offers a friendly heist. | Planner mode "friendly" (exists) |
| G35 | — | See §3.2 | See §3.2 |
| G36, D69: eras | — | Eras drawn as track chapters; this week's era is missing (SS4). | TC.36 shows `GET /v1/era`, which closes D69's client part. |
| G38: time limits | — | Profile: "Your last 25 raids are kept here" | The log shows what the server keeps (TC.37). |
| G39: web deletion | — | — | None |
| D70: declarations and the client screens | — | The Account tab has deletion. The age check is already built (TC.10). | TC.38 closes the deletion button. The title is half stale (finding 12). |
| F54: the non-raider's last level | — | Keeper bar with no gate state. The first session ends at Keeper 3 with "Level 4 opens …" (SF5). | Home's Keeper-bar gate (TC.11 and TC.12) |
| F55: §5.2's budget holds above the band | §23.5 rows say "the build follows" 30–45% ("Demo numbers", 11557; Workshop, 11492). F55 measured 47.6–95.5% at §5.2's budget. | Demo numbers: 75% held | Any hold figure on a screen comes from measurement. F55 decides the band. |
| F51: a Keeper can close every edge tile but one | — | The landing picker offers one named spot per realm, not any edge tile (deviation). | TC.32 stage A: any open edge tile, under F51 B's half-each-side rule. |
| G40: landing readings | §23.5 "Landing noise" row restates §5.4 (heard, or not heard; 6 tiles; 250) | A percentage | The picker shows "heard" from the simulation (`landing_heard`). |
| D71: one island | §23.5 "Scout report" row: skiffs cannot land on the Heart | The design's heist is one realm, the Heart, as the build's is. | Crossing realms (T3.3) gates the Observatory's universes, landing stage B, the planner's route and the slice. |
| G41 | — | No offline states | See §3.2 |
| G42: no phase for the home economy | §26.8: only phase 0's note changes | Adds the screens the home economy feeds: realm view production, roster, Codex, weaving, Lab, Aether | TC.12's slices become the critical path for six screen groups. Finding 2 extends G42 to the interface. |
| F56: the starting universe | §23.5 first-session row: "the session starts from a bare Heart" (11537) | The Heart is built at 0:00. | The first-session director needs F56 settled (finding 9). |
| G44: rate limits | — | No "held back" state | The build's message stays. |
| D72 | — | See §3.2 | See §3.2 |

## 4. The roadmap

### 4.1 TC.7

**Today:** "The design from Claude Design", owner you, ready (`tools/roadmap.py:1152-1156`).

**It becomes done.** Evidence: the Screens v3 artifact link (the owner's) and v3.6 §23.5 (line 11385): "Screens v3 … holds the designed screens, 43 character and creature sheets with 3D models, and 393 icons … The designs carry the look". Its detail should change to say that it lands through TC.16 to TC.20, and that the document wins on rules (§23.5).

**What remains splits two ways:**

- **Claude's part** becomes TC.16 to TC.19, plus TC.20 for the shell.
- **The owner's part** is the open rules the design raises, which become TC.42:
  - the design system's open rules:
    - DS-1, the surfaces;
    - DS-2, the typefaces;
    - DS-3, the icon finish;
    - DS-4, the colour-blind mode;
    - DS-5, interface motion;
    - DS-6, how outlined text counts for contrast;
  - D72;
  - F4, the worth scale;
  - the home layout and back control (H and I);
  - scout visibility (N2 and N3);
  - presence, quests, badges, the gift limit, whether a 13–15 may post, and the Open Vault league;
  - whether the design's first session is approved.

**None of these blocks TC.16 to TC.19.** The tokens carry the document's value with the design's beside it, so an answer flips a value without blocking the work (`ds_out/tokens.proposed.json`, design-system report §10.2).

### 4.2 Existing tasks to amend

- **SC's introduction** (`:941-948`):
  - "Godot 4.5" becomes "Godot 4.7.2, pinned (§24)".
  - "§24.12 makes offline the normal path" becomes "online is the rule and offline the exception (G41's answer)".
  - "§21 is written as the guide Claude Design works from" becomes "Screens v3, recorded in §23.5, is the visual reference, and the document wins on rules".
- **T3.4** (`:885-932`):
  - "a Godot 4.5 project" becomes 4.7.2 after TC.15.
  - Its "Not yet: §21's landing picker" closes with TC.32 stage A.
- **TC.3** (`:1001-1022`): the gate becomes "both stores' builds on 4.7.2, Android at API 36 (`gradle_build/target_sdk=36` in `client/export_presets.cfg`, confirmed at the first export, per §24), the iPhone in Xcode 26 with the iOS 26 SDK, uploaded to the Play internal track and TestFlight (§26.6)".
  - The "done here" export check ran with 4.5 templates (`client/export.sh:21,26`) and must be re-run on 4.7.2. The templates are 1.28 GB (`engine.md`).
  - Add `blocked_by=["TC.15"]`. Status stays "doing".
  - The points stay +4.86, once completion's proof reads the build record (§2.3).
- **TC.5** (`:1033-1040`): words go in as each screen is made. The +8.80 waits for every launch screen (TC.31 to TC.39) and the native read. Split it into TC.5 (Claude, ready) and TC.5b (the owner's read, blocked by the screen tasks), so the roadmap shows why it cannot count yet.
- **TC.6** (`:1041-1054`): keep it done.
  - "Only their look changes when the design lands" holds only if the port takes the look and refuses the design's mechanics.
  - Those mechanics are: the Starpass +20%, quests, star chests, league rewards for all, presence and live status. §23.5 says "a design never adds a mechanic" (line 11391).
- **TC.8** (`:1157-1163`). Add:
  - performance on the reference device against §21.3's budgets and §24's 60 fps floor and 25 ms drag (3D report, findings 1, 8 and 9);
  - VoiceOver and TalkBack;
  - local notifications and asking permission after the third session (D68, §25.2);
  - the platforms' age signals.
- **TC.12** (`:1085-1108`). Its next slices are what the screens need first:
  - the builder publishing to the player's own realms (closes D60);
  - workers and production, with an Aether ledger;
  - the roster: characters, homes, rest, assign and recall, waking and levels, and the starting five;
  - pages and the Codex, with restoration and study;
  - weaving state;
  - Insight.

  The gate stays as it is (G42).
- **TC.14** (`:1127-1138`):
  - "the engine's required-reason APIs" are 4.7.2's.
  - TC.37 (Profile: per-heist facts at settle) and TC.39 (the Keeper's name and face) add stored columns. The column test in `server/privacy.json` will catch them, and the filed declarations must be re-checked if TC.14 is filed before they land.
- **T5.1 and T5.4**, the locks on the simulation contract and on saves, bundles and versions. Add `blocked_by=["TC.23", "TC.26"]`. The crew manifest, abilities and casts (TC.26) and the appearance block (TC.23) change the replay header and bundle. Locking before them locks an incomplete contract.
- **S6 and S7.** Finding 10. Change:
  - T6.1's gate becomes §26.2 phase 2's harness gates (12334).
  - T6.1's blockers gain the slice's content:
    - T3.3's crossing realms;
    - TC.12's roster;
    - TC.26 (abilities and Sages);
    - TC.30 (ruins and rehearsals);
    - TC.43 (pre-production exit).
  - T6.2's fun gate (§19.5) moves to soft launch (T7.3), where §26.2 puts the gates that need players.
  - T7.1's gate becomes §26.2 phase 3's: "No dominant law in bot runs, and the same harness gates as phase 2".
- **NOT_YET** (`:1359-1387`):
  - "Detailed screen design" becomes "Designed (Screens v3, §23.5); built in SC's order".
  - "Character art" becomes "Sheets exist as code (43); export first (TC.21), §26.2's art-style test on devices (TC.43) before the quantity".
- **DESIGN_GATES['screens']** in the register: "The 28 screens in §23", and the handoff is done. Gates on the build, not the drawing, should name the new v3.6 items that decide what a screen shows, for example the worth scale and scout visibility.

### 4.3 New tasks

The readers' provisional ids collide: three of them used "TC.15". The numbering below replaces them, and the mapping column gives each reader's own id. Sizes and run counts are the readers' estimates. "Points" means the frontend points the task can move under completion as it stands.

**Track A: the foundation**

| Id | Task | Owner, status | Waits on | Readers' id and size | Points |
|---|---|---|---|---|---|
| TC.15 | Engine to Godot 4.7.2 and godot-rust api-4-7: `project.godot` features "4.7", `build.sh` 4.7.2-stable, `compatibility_minimum = 4.7`, Cargo `api-4-7`; `AccessibilityServer.LIVE_*` at `ui.gd:138,321`; `export.sh` templates 4.7.2; `target_sdk=36`; documents that say 4.5 (README, `client/README`, roadmap, the `privacy_manifest.py` docstring); check `settings.gd:40,42` against 4.7's class reference. Gate: 100 of 100 on 4.7.2, the goldens agree at every second, `export.sh check` passes on 4.7.2, gdlint is clean. | claude, ready | — | Measured in a copy: one code change (`engine.md`). S, one run. | 0, but a precondition of TC.3's 4.86 |
| TC.16 | Design tokens, the three fonts and the §21.11 licence ledger: `tokens.proposed.json` with the document's values as `value`, accessors for gradient, material, font and type, and a generated Theme. Every test passes unchanged. | claude, blocked | TC.15 | DS steps 1–2 | 0 |
| TC.17 | Materials, the rounded-box shader and the components: gold, leather, red, green and round buttons, sheets, chips, portrait tiles, banners. The checks learn the colour each word actually sits on (`text_bg`) and outlined text (DS-6). Gate: §21.1 sizes and §21.8 contrast at 100% and 200% text, in both languages. | claude, blocked | TC.16 | DS steps 3 and 5; the components in each screen report | 0 (risk: Accessibility, Portrait interface) |
| TC.18 | Motion: one helper, reduced motion that removes swoops and most particles, a lint rule against stray tweens, a flashing guard, and toasts treated as banners (`banners_stay`) | claude, blocked | TC.16 | DS-5, DS-7, DS-8. S to M. | 0 |
| TC.19 | Icons: Screens v3's 393, as 444 exported SVGs, rasterised in Chromium, with a manifest, `UI.icon()`, a test that every icon exists, and the school marks with Matter's cube edges | claude, blocked | TC.15 (import on 4.7.2) | DS step 4. M. | 0 |
| TC.20 | The shell: a persistent screen (the router keeps the shell, the HUD and the 3D world), tab bar, top HUD, badges, the nearest goal (§14.8), and the layout check split for controls used rarely | claude, blocked | TC.17. The owner's H and I for the home layout do not block a first cut. | Home report: shell, I, K, L. L. | 0 (risk: Portrait interface) |

**Track B: the 3D world**

| Id | Task | Owner, status | Waits on | Readers' id and size | Points |
|---|---|---|---|---|---|
| TC.21 | Art export harness: Playwright, a pinned Chromium and three r184 from npm; the prototype's modules, unedited, as inputs (committed or pinned); a GLB for each creature and kit piece; §21.3 budgets and §21.6 heights enforced; a manifest of §21.9 row by row. Check whether 4.7.2 imports a whole island (4.5 refused `EXT_mesh_gpu_instancing`). | claude, blocked | TC.15 | 3D TC.15. 3–5 runs. | 0 |
| TC.22 | Toon kit: the 3-step ramp, the clip-space 1.5 px outline, water and lava, sky, glows, the Hush, Spark and Echo variants. Golden screenshots need a GPU runner. | claude, blocked | TC.21 | 3D TC.16. 3–4 runs. | 0 |
| TC.23 | Appearance in the replay and the bundle (simulation and server): kind, form and outfit for each crew member and each posted guard, beside §24.11's four inputs | claude, ready | — | 3D TC.19 and finding 6. 1–2 runs. | 0 |
| TC.24 | The 3D world from the replay: island base around the simulation's grid, 1 tile = 1 m, interpolated actors, overlays per §21.12, the orthographic camera in 90° steps, tile picking. `RealmView` stays for screen readers. | claude, blocked | TC.22, TC.23 | 3D TC.17. 5–8 runs. | 0 (risk: Render a replay) |
| TC.25 | Characters in full: a note accessory and pattern for each form, the guard sash and lantern, role accessories (§21.6, §12.8), springs, portraits re-rendered | claude with the character artist, blocked | TC.21 | 3D TC.18. 4–6 runs. | 0 |

**Track C: what the screens stand on, in the simulation and on the server.** It sits here so the order is visible. It could equally be S3 or S5 work.

| Id | Task | Owner, status | Waits on | Readers' id and size | Points |
|---|---|---|---|---|---|
| TC.26 | Crew manifest in the replay (RBH3), the eighteen abilities, the four Sage powers, casts, the four-ready rule. The server validates the manifest against the roster. The harness decision band is re-measured and the goldens regenerated. | claude, ready | Before T5.1 and T5.4 | Heist report SIM-H1. L to XL. | 0 (finding 3) |
| TC.27 | The simulation's event log and exports: bells, wind-ups, alarms, knockouts and positions, for the decisive moment, guard speech, haptics, clips, per-heist facts and D65's heatmaps | claude, ready | — | Heist report SIM-H2. M. | 0 |
| TC.28 | Stability and weaving prices in the simulation (`sim::stability`, §5.5 and §8), for both client and server, with crown laws in the bundle (D61) | claude, ready | — | Weave report "T-econ". M. | 0 |
| TC.29 | Terrain in the simulation: the 34 features missing from 39, moss and clearing it, heights 0 to 3, directions and tunnels, terrain points | claude, ready | Answers on directions (lab report LD13, LD15, LD16) | Lab report TC.20a. XL. | 0 (finding 3) |
| TC.30 | The generator and crews in the simulation (D66): ruins, rehearsal crews and reference crews, the report recorder, generated fallbacks, and a server measurement queue that also gives D62's band check | claude, ready | Answers LD8, LD22, LD24 | Lab report TC.20b and TC.20d. XL. | 0 |
| (existing) TC.12 | The home economy's slices, as listed in §4.2 | claude, doing | — | — | 0 |
| (existing) T3.3 | Crossing realms and universes of several realms | claude, doing | — | — | — |

**Track D: the screens.** Each is built on TC.16 to TC.20 and keeps the 100 tests (§2.4).

| Id | Task | Owner, status | Waits on | Readers' id and size | Points |
|---|---|---|---|---|---|
| TC.31 | Heist and result: the HUD and its controls on the flat view first, then 3D, then the result with its moment and its variants by kind of target | claude, blocked | TC.17, TC.26, TC.27, TC.12 (pages, rest, strays); TC.24 for 3D | Heist report TC-H, TC-W, TC-R. L each. | 0 (risk: Render a replay, Capture input, Show a result) |
| TC.32 | Observatory, scout report, landing picker and planner. Stage A, the picker on one island, can start after TC.17. | claude, blocked | TC.17; then TC.12 (roster, Aether), T3.3, TC.30, and finding 1's precedence | Observatory report TC.15a–l, sizes S to XL | 0 |
| TC.33 | Weaving, the law card, the Codex and the Harmony view | claude, blocked | TC.17, TC.28, TC.12 (Codex, Aether, weaving) | Weave report TC.L1–L6. S to L. | 0 (risk: Laws on the island) |
| TC.34 | Roster, Character, Sage hall and Forms album. Content changes: `paradox_born.json`, the Stray rule, §11.11's rule-sheet field (characters report §5). | claude, blocked | TC.12 (roster), TC.26, TC.25 for the 3D stage | Roster report §7 | 0 |
| TC.35 | Lab, defence curation, rehearsal and defence log, terrain editor, and the Workshop on the design (keeping remix and withdraw) | claude, blocked | TC.29, TC.30, TC.17 | Lab report TC.20c and TC.20e–j | 0 (risk: Terrain editing, Testing your own defence, Workshop) |
| TC.36 | Season, Shop, Share sheet and Friends. Prices and rewards wait for TC.42's answers. Goals and streak on the server; the week's era. | claude, blocked | TC.17; TC.42 for prices, rewards and status | Season report TC-S1–S4, S6, S7 | 0 (risk: Shop, Social) |
| TC.37 | Profile and stats, with its server route (§23.2's new row): `GET /v1/profile`, per-heist facts written at settle, Renown over time, outcomes, defences held and leaked, records, the battle log with replays as long as they are kept, collection and badges. Private for 13–15s, private by default for 16–17s (§20.2). | claude, blocked | TC.17, TC.27; badges need a definition (TC.42) | Season report TC-S5. L. | 0 on either side |
| TC.38 | Settings and wellbeing in four tabs: protections shown locked by band (§23.2), deletion with "withdraw my islands too" (D70, F43), the reminder picker outside the night (G34), play-time reminders, `GET /v1/notifications`, profile visibility | claude, blocked | TC.17 | Settings report TC.15. L. | 0 (risk: Save and settings) |
| TC.39 | First launch in §23.5's order: title, the age step (TC.10, restyled, neutral, no way back), a summary of the band's protections, the Keeper's name and face (server, with §20.4's filter), then §16's beats | claude, blocked | TC.38 for the protections data; F56 (finding 9); for the beats, TC.31 to TC.35 and TC.30's ruins | Settings report TC.17 and TC.18. M, then XL. | 0 |
| TC.40 | Slower ruins (§20.8 line 10303, §23.5 line 11406): the setting becomes "slower ruins" and applies to drifting ruins only. Pause stays in ruins and rehearsals. The test and `completion.py:359` are renamed in one change. | claude, ready for the setting; the effect waits on ruins | TC.30 for the effect | S | 0 (risk: Accessibility, 0.73) |
| TC.41 | Landscape for every screen (§23.3; §23.5: "Not designed") | claude, blocked | The portrait screens accepted | Several reports | 0 |

**The owner's tasks**

| Id | Task | Owner, status | Waits on | Points |
|---|---|---|---|---|
| TC.42 | Settle what the design leaves to you (§4.1), and take the 47 recorded answers into the document (T1.6) | you, yours | — | 0 |
| TC.43 | §26.2's phase 1 exit: screens approved, and the art-style test on target devices (eight wards and six or seven defensive markers reading, under colour-blindness simulation) | you, blocked | TC.24, TC.8 | 0 |

### 4.4 Order and dependencies

1. **Now, with no owner input:**
   - TC.15, the engine. It is one run and it pins every later change to the engine v3.6 names.
   - Then TC.3's export check, re-run on 4.7.2.
2. **In parallel, the long poles, which need no design:**
   - TC.26, abilities, Sage powers and casts. It changes the replay format, so it must land before the locks.
   - TC.27, the event log.
   - TC.23, appearance.
   - TC.28, stability.
   - TC.12's slices, in the order of §4.2.
   - T3.3, crossing realms.
   - TC.29 and TC.30, both XL.
3. **The foundation:**
   - TC.16, then TC.17, then TC.18.
   - TC.19 alongside TC.16.
   - TC.20 once TC.17 is done.
4. **The 3D chain:**
   - TC.21, then TC.22, then TC.24, which also needs TC.23.
   - TC.25 after TC.21.
5. **The screens, in the order §26.2's vertical slice needs them.** The slice is a Heart and two realms, ruins only, 6 ruleborn, 2 Sages and rehearsals.
   1. TC.31, heist and result, on the flat view first.
   2. TC.32 stage A, then the Observatory with ruins (after TC.30), then the planner.
   3. Home and the realm view, inside TC.20 and TC.24.
   4. TC.33's weaving and law card.
   5. TC.34's roster and Sage hall.
   6. TC.35's rehearsal and defence log.

   Outside the slice, and after it:
   - the Codex and the Harmony view;
   - the Lab, curation, the terrain editor and the Workshop;
   - TC.36, then TC.37;
   - TC.39 last, because its beats need most of the other screens;
   - TC.41, landscape, after the portrait screens are accepted.

   Two can go early:
   - TC.38, Settings, needs only TC.17 and closes D70's and F43's client halves.
   - TC.40's setting.
6. **Locks, slice, exit:** T5.1 and T5.4 after TC.23 and TC.26. TC.43 before T6.1.

### 4.5 What stays gated on devices or the owner

- **TC.3:**
  - for Android, a host for the SDK and NDK (`dl.google.com` is refused here), or a machine that has them, plus a Play Console app;
  - for iPhone, a Mac with Xcode 26, the App Store team and TestFlight.
- **TC.8**: the phones' checksums (T3.1, +3.21 backend), the device matrix and the fix buffer (+10.92 frontend), §21.3's performance, the drag budget, screen readers, local notifications, and the platforms' age signals.
- **TC.43**: §26.2's art-style test on target devices, and "Screens approved".
- **TC.5b**: the native read (+8.80), after every screen.
- **TC.14**: filing (+4.66 backend). Re-check after TC.37 and TC.39 add data.
- **TC.42**: the design's open rules, and the answers into v3.7. Prices, rewards, worth and scout content wait for these. Tokens do not.
- **Authored cosmetic sets (D64)** and a character artist's work on TC.25.

## 5. Findings for the register

The other readers' findings are not repeated. Each finding here comes from mapping the plan: the register, the roadmap and completion against v3.6 and the build.

**1. v3.6 takes none of the owner's 47 recorded answers, and its §23.5 makes the document win over the designs. A screen now has three sources that disagree** (contradiction, significant; §23.5, §9.1, §9.4, §12.3, §12.4, §5.4, §22.1, §32.8).

- **The precedence:** §23.5 (11387): "This document wins wherever it states a rule, a number or a piece of text."
- **The answers:** `docs/decisions/answers.json` holds 47, recorded on 25–26 September (git log of the file). Most are built (`"build": "done"`). v3.6 changed none of their sections (`v36/diffs.txt`).
- **Examples:**
  - F41 C, no currency. Against it:
    - §22.1 (11104): "Starglass, in packs from about €1 to €50";
    - §9.1 (4413-4416);
    - Screens v3's Shop and Starpass, priced in Starglass (season reader SS10).
  - F39 B, C41 B, F44 D, F46 B and F51 B, against §9.4, §12.3, §12.4 and §5.4 as written. The design draws the replaced rules (observatory reader N1).
  - F35 D, no Vault call, against v3.6's new §32.8 row 37, which records "a ring around the Vault … shipping at 5 m".
- **Recommendation:**
  - State the build's precedence: a recorded answer whose register item is open with an edit drafted, then the document, then the design.
  - Have the port follow the build where an answer exists.
  - Take the answers into the next version (T1.6).

**2. Completion and §26.8 count none of the work Screens v3 sets, so the 75.41% frontend figure cannot move with it and overstates readiness** (gap, significant; §26.8, §23.2; extends G42 and the 3D report's finding 11).

- **The deliverables:** `tools/completion.py:188-384` lists the heist, the builder, Workshop, shop and track, social, settings and accessibility.
- **The screens:**
  - 20 of §23.2's 28 screens have no deliverable;
  - 18 have no screen in the build (`client/app/router.gd:8-21`);
  - the design-system port has no deliverable;
  - the 3D world has none either.
- **Why:** §26.8 (12503-12594) costs none of these.
- **Recommendation:** as G42 asks for the home economy, give §26.8 a costed phase, or rows in phases 2 and 3, for the interface screens and the art. Until then, the roadmap says the figure measures §26.8's list.
- **The direction:** down. For example, 62.10/(82.35+20.5) = 60.4% if only the art's 16–25 runs were added.

**3. Two rows read done while holding a fraction of what they name, and nothing tracks the missing part** (gap, significant; §12.6, §12.7, §6.2, §26.8).

- **Crews** (phase 1, backend, 4.07 points, read 100%) proves nine systems (`completion.py:194-197`). The simulation has twelve command kinds, and none is an ability, a Sage power or a cast (`sim/src/replay.rs:53-92`). §12.7's controls include the Sage and casts.
  - G23's body only notes "no abilities exist yet".
  - No register item or roadmap task builds them. A search of the register and the roadmap finds none.
- **Terrain editing** (phase 4, frontend, 5.77 points, read 100%) is proved by one test. The simulation has five of the 39 features: rock pillar, ruin wall, fence, fog bank and tall grass (`sim/src/grid.rs:116-137`, against `content/terrain.json`'s 39).
- **Recommendation:**
  - Add the missing system to each proof. Crews would then read 9 of 10, 0.41 backend points lower.
  - Add TC.26 and TC.29.
  - Lock T5.1 and T5.4 only after TC.26.

**4. The build is pinned to Godot 4.5, which v3.6 replaces, and v3.6 says no client code exists** (deviation, minor; §24, §26.6, opening line 91).

- **The rule:** §24 (11643) pins 4.7.2 with godot-rust api-4-7. It says Android's API 36 is "set in the export preset and confirmed at the first export".
- **The build:**
  - `client/project.godot:12` has features "4.5";
  - `client/ext/Cargo.toml:11` has `api-4-5`;
  - `client/ruleborn.gdextension:5` has `compatibility_minimum = 4.5`;
  - `client/build.sh:13` and `client/export.sh:21,26` use 4.5;
  - `client/export_presets.cfg:28` has `gradle_build/target_sdk=""`.
- **TC.3's "done here" export check** ran on 4.5 templates.
- **v3.6's own claim:** the opening (line 91) says "No client code exists yet, so the move costs nothing". In fact the client has 100 tests, and the move measured as three constants at `ui.gd:138,321`, four pins and a 1.28 GB template set (`engine.md`).
- **Recommendation:**
  - TC.15.
  - Set `target_sdk=36`.
  - Correct the opening's sentence.

**5. v3.6 puts the store builds in phase 0, while completion counts them in phase 2 with a proof that reads nothing** (gap, minor; §26.6, §26.8, `completion.py:189, 204`).

- **v3.6:** §26.6 (12439) has the spike "export an empty Godot 4.7.2 project … built in Xcode 26 and at Android API level 36, and upload both". §26.8's phase 0 note names "the store builds on Godot 4.7.2".
- **Completion:**
  - Phase 0 counts only checksums, on the backend.
  - "Project structure" in phase 2 (frontend) is a hard `not_started`.
- **Recommendation:** one proof that reads a recorded build (engine, SDK levels, upload), counted in one place, with the choice stated in `completion.py`.

**6. The screen and icon counts disagree in v3.6 and in the register** (contradiction, minor; §21.9, §23.2, §23.5; extends the design-system reader's DS-11).

- **v3.6:**
  - §21.9 (11044-11045): "Interface icons and screens | About 220 and 27".
  - §23.2 now lists 28 rows.
  - §23.5 (11385) says 393 icons.
- **The register:** `DESIGN_GATES` still says "The 27 screens in §23" (`tools/audit_register.py:8108`) and closes C11 as "27, not 23" (`:8113`).
- **The checker already expects 28:** `tools/check_document.py:1471`.
- **Recommendation:** §21.9 reads 28. Decide whether the icon budget follows Screens v3. Change the two register lines.

**7. D72's drafted edit and the client name different word colours, and the edit assumes paper panels that Screens v3 replaces** (contradiction, minor; §21.8).

- **The register** (D72's body, `:6754`; its edit, `:8384`): words are "#B3203A or #1D6B45".
- **The client** (`client/ui/tokens.json`):
  - `alarm_text` is #9A1B32 (`:88-90`);
  - `success_text` is #155A38 (`:92-94`);
  - #B3203A is the alarm fill (`:80-82`).
- **The design's surfaces** are dark cards and parchment. On them:
  - the design's red words fail (#E2536B on night, 4.19:1, Lc 35);
  - its red badges fail (2.7–2.8:1);
  - its green words pass (7.6:1).
- **Recommendation:** one set of word shades for each surface, defined once in `tokens.json`, with the edit's text checked against it.

**8. Slower ruins: the client applies §20.8's 75% to the builder's self-raid, and completion's accessibility proof names that test** (deviation, minor; §20.8, §23.5).

- **The rule:**
  - §20.8 (10303): "a slower mode for ruins that runs the simulation at 75% speed".
  - §23.5 (11406-11407): "Ruins only: never a heist against a player, never Renown".
- **The client:**
  - `client/scripts/heist_screen.gd:30` defines "a rehearsal: the player's own island, from the builder".
  - `:207` applies the pace there.
  - `client/tests/a11y_tests.gd:348` tests "a rehearsal can be … run at 75%", and `tools/completion.py:359` counts that test.
- **Ruins are not built** (D66).
- **Recommendation:** TC.40, renaming the test and the proof in one change.

**9. v3.6 adds a fourth account of the starting universe, and it disagrees with §16 and the build** (contradiction, minor; §23.5, §16, §11.5; extends F56).

- **§23.5** (11537): "the session starts from a bare Heart".
- **§16 at 5:00** (8860): "two strays follow the crew home to a free Hearth. The player puts them to work at the Star Well and the Garden". This happens with no building step.
- **§11.5** (6163) also speaks of "a free Hearth".
- **The build:** `tools/design_facts.py:102` STARTING_HEART is the Spire, Vault, Star Well, Aether Spring, Garden and Hearth.
- "Bare" is not defined.
- **Recommendation:** F56's one place, defining what is built at 0:00.

**10. The roadmap's S6 and S7 gates name outside playtesters that §26.2 removed, and the slice's blockers miss most of its content** (deviation, significant; §26.2; the pattern of C29 and T0.10).

- **The gates:**
  - T6.1 (`tools/roadmap.py:1315`): "≥ 7 of 10 outside playtesters ask for a second session".
  - T6.2 (`:1319`): "Run §19.5's fun gate".
  - T7.1 (`:1337`): "≥ 20% of testers still playing after a week".
- **What the document says:**
  - v3.6 §26.2 phase 2 (12334) exits on §19.27's harness gates: "No outside player is involved".
  - Phase 3 exits on "No dominant law in bot runs, and the same harness gates".
  - T1.10 (`:454-478`) records this as decided in v3.3.
- **The blockers:** T6.1 waits only on T5.1 to T5.5. The slice is "A Heart and two realms; … 6 ruleborn; 2 Sages; ruins only; rehearsals". That needs:
  - crossing realms (T3.3, "Not yet"; D71);
  - the roster on the server;
  - Sage powers in the simulation;
  - the generator and crews (D66).
- **Phase 1's exit** ("Screens approved; the art-style test … on target devices", 12329) has no task.
- **Recommendation:** as in §4.2, plus TC.43.

**11. Ten open items carry client work in the owner's answers, yet all 70 open items are filed as backend** (gap, minor; register sides).

- **The answers** (`answers.json`, field `client`): F37, F38, F41, F43, F46, F54, G19, G29, G34 and G35.
- **The filing:** `side_of` returns "backend" for anything not in `FRONTEND` or `BOTH` (`:8022-8027`), and both sets hold only settled items. So the audit page shows no open frontend work while these screens owe their halves.
- **Recommendation:** move the ten to `BOTH`, naming the client half.

**12. D70's title is half stale: the age check is built** (contradiction, minor; §20.1).

- **The title:** "the client has neither the age check nor deletion on a screen".
- **The build:** TC.10 is done (`tools/roadmap.py:1055-1067`; `client/scripts/age_screen.gd`, `client/data/age_check.gd`).
- **Recommendation:** retitle it to the deletion button and filing. The deletion button lands with TC.38.

## 6. Limits

- **Screens v3:** every fact about it here is a reader's or the lead's. I re-checked the build's side of each claim I cite, but I measured nothing in Screens v3 myself.
- **The open list** was computed while the lead's V36 layer was empty. If that layer moves statuses, the counts in §3 change with it.
- **Effort** is given as the readers' sizes or runs. I have not converted them into §26.8 runs or summed them, because that is the costing finding 2 asks §26.8 to make.
- **Proof changes:** where I suggest how a completion proof might change (per-store fractions, a build record), those are options under its rules, not values it computes today.
