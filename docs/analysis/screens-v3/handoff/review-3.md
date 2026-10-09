# Handoff review, Part 3: "What to change" (Part 2 of the fix brief) and the README's open items

Read against the repository at commit 6cc1d1e; the line numbers it cites in the register (AR), the brief and the roadmap (RM) are that commit's. What it proposes was checked and folded into the register's v3.6 layer, the brief and stage SD afterwards ([README.md](README.md)). The earlier reading's reports, cited by file name, are in the folder above.

## Sources and short names

- REV: the handoff's `docs/ruleborn-screen-review.md`, copied unchanged to `source/ruleborn-screen-review.md`; Part 2, lines 361-451 (my part). REV line numbers are file lines.
- README: the handoff's `README.md` (`source/README.md`), "Open items (not yet done in the prototype)", lines 230-239 (and line 228, which introduces them).
- SV3: handoff `prototype/Ruleborn Screens v3.dc.html`. META: `prototype/RulebornMeta.dc.html`. DIO: `prototype/realm-diorama.js`. DATA: `prototype/ruleborn-data.js`.
- SHOT: `scratch/shots/all/Gameplay_NN_*.png|txt` (the artifact at phone size; not kept). Extra captures from the earlier reading: `scratch/lcrtw_shots/rh_report0.png` (the raid report).
- DOC: `docs/design/ruleborn-game-design-v3.6.txt`, cited by line.
- Register `tools/audit_register.py` (v3.6 layer); brief `docs/decisions/brief.json`; answers `docs/decisions/answers.json`; roadmap `tools/roadmap.py` (stage SD); analysis `docs/analysis/screens-v3/`.
- R1-n: findings of Part 1's report (`review-1.md`), which covered REV:11-118. H-n: the README/SCREENS report (`intent.md`).

## The main result

Part 2 is the brief the screens were redone from, and they follow most of it. Every number in Part 2 agrees with v3.6, checked one by one: the 24 launch laws (rank, cost, notes and school all equal `content/laws.json`, which is extracted from v3.6; DATA's law table equals it too, rule text included), pages by rank (DOC:2217), §12.9's table (DOC:7074-7108), rest (DOC:6180), §5.1's slots (DOC:645-647), §5.5's prices and bands, §12.3/§12.4's Observatory (DOC:6922-6936), §5.4's skiff (DOC:828), §11.1's 420 and 120 (DOC:5953, 11579), §12.20 (DOC:7401), §18.2/§18.8 (DOC:8989, 9116-9121), §20.1 (DOC:10166), §16's beats (DOC:8840-8875).

Where Part 2 disagrees with v3.6 it is in four places, and in each the screens and the roadmap already follow v3.6: 44-point tap targets off the heist, "tap two portraits" to move, every guard's cone drawn, and (against a recorded answer rather than the document) the crack ring.

What is new here:
- **The crack ring.** Part 2 asks for it, the screens draw it and the earlier analysis adopted it, but the owner's recorded answer to F35 removed it ("its ring ... all go"), and the simulation follows that answer. R1-5 listed the brief's other restated rules and missed this one (R3-1, high).
- **Who may Trace.** v3.6 says "within 24 hours of being robbed", while a defender never loses anything. The server excludes foiled raids. The design and the owner's brief offer a Trace after every raid, held ones included. Nothing in the register notes this (R3-3).
- **Owner statements that bear on open items:** "Keep the Archivist card" (G48), "A getaway at 2 of 6 alarm is Loud" (C47), and "Raider names stay hidden while a raid is happening" (D83) (R3-4, R3-5, R3-6).
- **Gaps in task acceptance:** TD.17's gate reads only §23.2's Heist row. TD.66 leaves out the replay, the map, the outcome and the Trace window. TD.20, TD.5 and TD.23 each lack one line (R3-7 to R3-12).

## Coverage table

Status words: **applied** (the screens do it; quoted); **open, held by X**; **covered by X** (the line is a rule the register, analysis or roadmap already carries); **new R3-n**. "Roadmap" names the task that carries the line as acceptance.

### Apply to every screen (REV:363-377)

| REV | Line | Screens now | v3.6 | Roadmap | Status |
|---|---|---|---|---|---|
| 365 | Theft one-way; no "raided you −X", Revenge, stolen, steal; Trace: 24 h, free scout, no fee; laws never stolen | No "Revenge", "stolen" or "steal" text anywhere (grep of SV3, META, DIO). One function is still named `raidRevenge`, at SV3:1015; it is code, not text. "Ines raided you · Held at Lantern Vale" and "Pell raided you ... you lost nothing" (META:1477) carry no loss. Trace on the Observatory ("TRACE · 24 H", "Free scout · Trace", SHOT 08) and in the raid report ("Trace Marta · Free scout · 22 h left", rh_report0) | Agrees (§13.2 DOC:7513, §12.3 DOC:6932). The Open Vault exception is C50 | TD.66 (Trace), TD.18 (no fee on a Trace) | **Applied.** The Trace card's fee is the §23.5 Trace target row. *Which* raids give a Trace is **new R3-3** |
| 366 | Text ≥13 pt, body 16 pt; taps ≥44 pt; heist controls ≥48 pt, none in a corner | Most text is still under 13 pt; only the heist, planner and result meet the floor | §21.8 "16 pixels" against §23.5's "16 pt" is held (register edit at audit_register.py:11039; v36-rules.md:268). **44 pt disagrees**: §21.1 (DOC:10411) asks 48 pt for every primary control and "Nothing interactive sits in a screen corner", on every screen | TD.2, TD.3 (gate: §21.1's sizes) | Text: **open, held by the §23.5 Text size row**. 44 pt: **new R3-13** (Part 2 against v3.6; the roadmap follows v3.6) |
| 367 | School shapes the same on law cards, Icons sheet and colour-blind panel: Heart circle, Motion chevron, Matter cube, Time hourglass, Energy bolt, Life leaf, Spirit eye | `RBIcons.school` draws the six schools correctly (DIO:9-16); there is no Heart circle. The colour-blind panel draws Matter as a hexagon, Life as a gem and Spirit as an ellipse (META:902; design-system.md §4.4) | Agrees with §5.2 (DOC:653-700) | TD.5 says only "keep Matter's cube edges" | Panel: **open, held by** the §23.5 Colour-blind row (Life), D87 (Spirit) and design-system.md §4.4 (Matter). Heart: D75 ("Neutral, the circle"). Task: **new R3-11** |
| 368 | Demo player Wren: adult, Keeper 24, five outer realms (sixth at 28), crew of five | `player:{name:'Wren',age:'18+',keeper:24,...,outerRealms:5,nextRealmAt:28,crew:5}` (DATA); "Opens at Keeper 28" (SHOT 01) | Agrees (§5.2 DOC:655; §12.5 crew 5 from Keeper 16) | Prototype only | **Applied** |
| 369 | Renown not rating; no XP, power score or builders; levels with Essence, building instant | "RATING" in the Profile header (META:342); "588 / 600 XP" and "+N power" (META:910, 914); `sel.builders<2` (SV3:975, 988) | Agrees (§12.15, §11.4, §10) | TD.24, TD.21, TD.19 refuse each | **Open, held by** the §23.5 Profile header and Character screen rows, and D73 (builders) |
| 370-376 | The 24 launch laws, with rank, cost and notes | DATA's 24 equal content/laws.json in rank, cost, notes, school and tier-I rule (my script, `scratch/r3/datalaws.py`). Part 2's list equals content too (`scratch/r3/laws.py`) | Agrees with §7.4/§7.10 | TD.20 and TD.44 read content | **Applied.** A Codex hint still names Day and night: held (D82 group, review-1 item 7) |
| 377 | Pages 10 / 20 / 35 / 60 | `pages:{Common:10,Uncommon:20,Rare:35,Deep:60}` (DATA); Codex "18/60, 5/10, 14/35" | Agrees (DOC:2217) | TD.44 | **Applied** |

### 02 Heist (REV:379-390)

| REV | Line | Screens now | v3.6 | Roadmap | Status |
|---|---|---|---|---|---|
| 381 | At most eight; Regroup takes Get out's place | Five portraits, Sage, Cast and Get out make eight; `outT:h.split?'Regroup':...` (SV3:1314). With the Sage wheel open, eleven things can be tapped | Agrees (§12.7 DOC:7008, 7030) | TD.17 (an eight-controls test). Regroup is not named | Cap: **applied at rest**; the open wheel is **held by G47**. Regroup in TD.17: **new R3-7** |
| 382 | A portrait fires its own ability; Pip's Stuff the satchel at 60/s for 5 s | `CREW` abilities: Stuff the satchel, Unslowed, Root, Stand over, Burst, Crystal wall (SV3:911-917). The card reads "Loads loot at 60 a second instead of 30 for 5 s" (META:888) | Agrees (DOC:5997). Burst and Unslowed effects differ: D80 | TD.12 (sim), TD.17 | **Applied.** Effects: **held by D80** |
| 382 | Two pips with the number; hollow when spent; lockout ring; pause mark | Pips and ring yes; no number; no pause mark (all five ready at once) | Agrees (§21.8 DOC:11003; §12.6 DOC:6994) | TD.17 ("pips and lockout"); D80 is in its register list | **Open, held by D80** (Uses left; Abilities ready rows) |
| 382 | Drag a portrait to aim, or onto a fork to split | Neither. A power or cast fires at the first selected member | §12.7 (DOC:7012-7028) | Aiming: R1-3. Fork split: none | Aim: **covered by R1-3**. Split by drag: **new R3-7** |
| 383 | No gait buttons; hold ground for gait; plain tap at the last gait | "Tap crew, then ground · hold ground to sneak or run" (SV3:1321). SNEAK/WALK/RUN live only in the unrendered pass (SV3:1293) | Agrees (§12.18 DOC:7353) | Not in TD.17. The client today has a gait button (client/scripts/heist_screen.gd:304) | Screens: **applied**. Build: G47 holds the gait button, but TD.17's register list lacks G47: **new R3-7** |
| 383 | Tap two **portraits** to move them together; the All crew button goes | Selection is by tapping crew in the world; "SELECT ALL" is only in the unrendered pass (SV3:1293) | **Disagrees**: §12.7 has a portrait tap fire the ability, and §12.18 selects crew members (DOC:7353) | — | The screens follow v3.6. **New R3-13** (Part 2 against v3.6) |
| 384 | Sage wheel of three powers, 20 s dial; Cast wheel of one or two | `sagePw` Suspend / Reveal / Recall with "N left"; `sageDial` conic 20 s; `casts` two (SV3:1318-1319, 1322) | Agrees (§11.7, §21.8) | TD.17 (Sage dial); TD.12 | **Applied.** Portraits stay live under the wheel: **held by G47** |
| 385 | Layout: clock and alarm 0-6 top centre; law banner top left; loot top right as two numbers beside Vault progress; portraits bottom left; Sage, Cast, Get out bottom right, off the corners | SHOT 02: "Laws here" top left, "2:44" with "Alarm 0 / 6" top centre, "Room 1,840 · Left 2,600 · Load to 80%" top right, portraits bottom left, column bottom right (`bottom:'100px'`, SV3:1307-1308). No Vault progress | Agrees (§21.8 DOC:11000) | The gate reads only §23.2's row, not §21.8's Heist layout | Layout: **applied**. Vault progress: **held by D80**. Gate: **new R3-7** |
| 386 | Health bars; roles differ (Warden 420, Scout 120); no stamina; zero health drops loot, 10 s to capture; adjacent ally revives in 3 s | Health bars yes. `health:{Warden:420,Breaker:260,Carrier:200,Mender:180,Scout:120}`, `downedSec:10`, `reviveSec:{ally:3,mender:1.5}`, `reviveAt:.3` (DATA). "Stand next to a downed crew member for 3 s" (SV3:1321). Stamina survives only in the unrendered hint (SV3:1293) | Agrees (§12.20 DOC:7401; Part 2 leaves out the Mender's 1.5 s and the 30%, which DATA has) | Not in TD.17 | Breaker, Carrier and Mender health: **held by the §23.5 Role health row**. Stamina in README's state model: H-14. Health and revive in TD.17: **new R3-7** |
| 387 | Every visible guard shows its cone and an awareness meter | The focused guard's full cone; the others a facing wedge; a travelling fill (screens-heist-result.md §1.2) | **Disagrees**: §21.12 (DOC:11086) "One shape at a time. The selected guard's vision is drawn; the others show only their facing" | TD.42 (§21.12's cones) | The screens follow v3.6. **New R3-13** |
| 388 | While anyone cracks, a 5 m ring by walking path; guards inside hear | Ring drawn as `RingGeometry(4.86,5,96)` round the Vault (DIO:208); hint "guards within 5 m hear it" (SV3:1321) | v3.6 keeps it (DOC:6984). The owner's answer F35 = D removes it ("The 5-second call, its ring and the Vault's Sound::Breaking all go"); sim/src/heist.rs:20-22 follows the answer | Neither TD.17 nor TD.42 | **New R3-1** (the answer against the brief and the screens). Shape if kept: **new R3-2** |
| 388 | The load target | "Load to 80%", fixed (SV3:726; `tgt:.8`) | §12.6, §12.19 | TD.17 ("the Vault and load target") | **Held by G47** (no control) |
| 389 | No three-star objectives; clock red for the last 30 s; skiff 5 s / 20 s | Stars only in the unrendered pass (SV3:1293). `clockBox` turns red when `h.t<30` (SV3:1293). "Skiff in N s · hold the edge" (SV3:1320); `skiff:{outer:5,heart:20}` (DATA) | Agrees (§12.6, §5.4 DOC:828) | Not in TD.17 (it says only "Get out and the skiff") | **Applied.** In TD.17: **new R3-7** |
| 390 | Left-handed, mirrored | `LH2` flips the row and the column (SV3:1307); captured in `heistlh_*` | Agrees (§12.7 DOC:7030; §20.8) | Not in TD.17's detail or gate | **Applied.** In TD.17: **new R3-7** |

### 07 Heist result (REV:392-401)

| REV | Line | Screens now | v3.6 | Roadmap | Status |
|---|---|---|---|---|---|
| 394 | Outcome headline with multipliers | "Loud · Alarm raised · everyone out · Haul ×0.7 · Renown ×0.8" (SHOT 07) | Agrees (DOC:7074-7108) | TD.17 | **Applied** |
| 394 | "A getaway at 2 of 6 alarm is Loud" | "Marta's Heart · 2:14 · 2 / 6 alarm" under Loud (SHOT 07); Clean shows 0 / 6 | §12.9 "No alarm" against §12.6's ladder, which climbs every 30 s: open | TD.17 waits on C47 | **Held by C47**. Owner intent: **new R3-5** |
| 395 | Pick the law to study: +2, +3 Clean, +1 Foiled | "Study one law you crossed · +2 pages" with three chips (SHOT 07) | Agrees (DOC:2205) | TD.17 (the study and its POST) | **Applied.** "Pages to go": **held by D80** |
| 396 | Rest 45 / 60 / 180 | "Every crew member rests 60 min" | Agrees (DOC:6180, §12.9) | TD.17 | **Applied** |
| 396 | "Raid again" only with an idle crew, otherwise "Pick a crew" | Always "Raid again · Idle crew of 5 ready" (SV3:1498) | v3.6 is silent; §12.5's crew of 3 to 5 sets the minimum | Not in TD.17 | Error: **held by D80** (After the heist). Rule in TD.17: **new R3-8** |
| 397 | Fee returned (Clean, Loud), half (Partial), paid to the defender (Foiled) | "Entry fee 2,840 returned" (SHOT 07); `outcomes.*.fee` (DATA) | Agrees (§12.9; C41's answer B agrees) | TD.17 ("the fee by target kind") | **Applied.** Trace fee: §23.5 Trace target row. Fee base: C45/F39 (R1-5) |
| 398 | The decisive moment with a 3 s replay and one thing to try | "The moment · 0:48 · Your Carrier was spotted ..." with a 3 s button (SHOT 07) | §12.13 | TD.17, TD.13 | Layout **applied**. The rule: **held by G48** |
| 398 | "Keep the Archivist card" | "The Archivist · try this" (SV3:768) | §15.3 sets the Archivist's tips apart; G48 is open | TD.17 builds "Try this" | **New R3-4** (owner intent on G48) |
| 399 | On a loss, list what was kept; never show own stock as lost | Foiled: "Your crew is home ... Marta's laws are now in your Codex · Renown −8 · nothing else is lost" (screens-heist-result.md §2.2) | Agrees (§12.14, §20.3) | TD.17 says "loot kept" only | **Applied.** "Nothing else is lost" against the fee: **held by D80**. In TD.17: **new R3-8** |
| 400 | One-tap "Was this worth your time?" at the end (20.3) | "Yes / Not really" (SV3:785) | §19.5, §20.3 and §23.2 disagree on scale and frequency | TD.17 switchable on C47 | **Held by C47**. Part 2 cites §20.3 (per session): **new R3-5** |
| 401 | After two failures against the same target, an easier version by name | "Two misses on Marta. Try “Marta’s outer ring” ..." (SV3:1496) | §12.12 (DOC:7143); §19.12 | D79 refuses it for players | **Covered by R1-6** |

### 05 Weaving (REV:403-408)

| REV | Line | Screens now | v3.6 | Roadmap | Status |
|---|---|---|---|---|---|
| 405 | Heart: two realm slots, no third | Weaving: "Stillness · Empty Slot 2" (SHOT 05). The realm view still draws a locked third | Agrees (DOC:647) | Not in TD.20 | Weaving **applied**. Realm view: **held by D75**. In TD.20: **new R3-10** |
| 405 | Crown slots: one from Spire 2, a second from Spire 5; a crown law works everywhere at double cost | One crown slot ("Kinship · Crown · every realm") at Spire 6. `crownSlots(spire)` in DATA is right | Agrees (DOC:645) | TD.14 prices crowns; TD.20 does not name the slots | **Open, held by the §23.5 Crown slots row**. In TD.20: **new R3-10** |
| 406 | Aether = 40 × cost; cost = base × tier × modifiers; Glowing dark 11 pts, 440, 10 min | "440 Aether · 11 pts · ready in 10 min" (SHOT 05) | Agrees (§5.5, §5.6) | TD.14, TD.20 (prices from one function) | **Applied.** Price formula gaps: **held by D81** |
| 407 | Strain is the universe's; show the new band | "+3% = 85% → HUMMING" (SHOT 05) | Agrees (§5.5; §23.5 "Strain belongs to the universe") | TD.14, TD.20 | **Applied.** The seven-band bar is not drawn: **held by D81** |
| 408 | Two or three recommended laws; the deck holds launch laws only | No recommendations. The deck is launch laws only | Agrees (§23.2) | TD.20 | Recommended: **held by the §23.5 Weaving row**. Deck: **applied** |

### 08 Observatory (REV:410-417)

| REV | Line | Screens now | v3.6 | Roadmap | Status |
|---|---|---|---|---|---|
| 412 | Free: name, Keeper level, realms, Renown, rough loot; laws, guards and wards only after a paid scout at 20 Aether a realm | "Laws, guards and wards show after a scout", "Scout · 100 Aether" (five realms), "· 60 Aether" (three) (SHOT 08) | Agrees with §12.4 (DOC:6936). The owner's answer F46 B makes scouting free | TD.18 (pending C45) | **Covered by C45, R1-5** |
| 413 | Within 3 Keeper levels and 150 Renown; Wren 21-27 | "Keepers 21–27 · Renown within 150" (SHOT 08) | Agrees with §12.3 (DOC:6922). The answer F44 D changes the window | TD.18 | **Covered by C45, R1-5** |
| 414 | Depth and why; echoes marked; Trace ribbon for Revenge | "Depth · 1 realm to the Heart", "Why ...", "ECHO", "TRACE · 24 H" (SHOT 08) | Agrees (§12.15, §12.22) | TD.18 (why and depth) | **Applied.** What depth counts: **held by C46**. Generated targets: **D78** |
| 415 | Refresh 50 Aether, doubling within the hour | `refresh(n)=50*2^n` (DATA); the TRY line on SHOT 08 | Agrees (DOC:6924) | TD.18 | **Applied** |
| 416 | Drifting ruins apart: pages and Essence, no Renown, three labelled difficulties | "Drifting ruins · Pages, Essence, no Renown · Easy / Medium / Hard" (three ruins) | §12.12 (DOC:7135): *every* ruin offers three difficulties. Part 2's wording reads either way | TD.16, TD.18 | **Held by D78** (Drifting ruins row) |
| 417 | Entry fee: 2% of Starlight, 100 to 25,000 | "Entry fee 2,840 Starlight" | Agrees with §9.4. The answer F39 B changes the base | TD.18 (fee from the lease) | **Covered by C45, R1-5** |

### 17 Season (REV:419-423)

| REV | Line | Screens now | v3.6 | Roadmap | Status |
|---|---|---|---|---|---|
| 421 | 50 tiers; remove "+5 tiers now"; remove "this season only" | "STARPASS · TIER 30" (SHOT 17); no "+5 tiers" (grep); "Legendary · claimable in any later season" | Agrees (DOC:8989, 9116) | TD.23; the server has 50 tiers | 30 tiers: **held by the §23.5 Season track row**. The rest: **applied** |
| 422 | Premium bought with Starglass, cosmetics only; free track pages, Essence, a stray | Starglass pass; "Free at tier 30: The Chronicler"; a stray at 25 | Agrees with §18.2. The answer F41 C removes Starglass | TD.23 (money prices) | Starglass: **covered by F57, C45, R1-5**. Chronicler: **held by D85** |
| 423 | No countdowns or "last chance" banners | "18 days" chip on the header (SHOT 17) | §18.8 (DOC:9121) bans "last chance" banners and timers on the home screen | TD.23 shows "the season's end time"; the analysis adopts the chip (season analysis :109) | **New R3-12** |
| 423 | If star chests are random, show the odds and cap them | "AFTER TIER 30 · STAR CHESTS · One every 500 ★ · up to 10" | §20.3 (DOC:10209): odds for every random reward. §18.2 has no chests | TD.23 refuses chests | **Held by D84** |

### New screen: Defence report (REV:425-437)

| REV | Line | Screens now | v3.6 | Roadmap | Status |
|---|---|---|---|---|---|
| 427 | A list of raids on you; each opens a report | Defence log list with "Report ›" (META:241; rh_log) | §23.2 row (DOC:11269) | TD.66 | **Applied** |
| 429 | The outcome | Tags HELD, GOT OUT, FRIENDLY (META:1240), not §12.9's names | §12.9; held or leaked open | TD.66 does not name it | Labels: **held by G69, D85**. In TD.66: **new R3-9** |
| 430 | Haul denied | "Haul denied 3,300" (rh_report0) | §13.2 | TD.66, TD.39 | **Applied.** Its measure: **held by G57, G31** |
| 431 | How long it held the crew | "Held the crew 2:31" | §13.2 | TD.66, TD.39 | **Applied.** Measure: **G57** |
| 432 | Where the crew was seen, on the island map | 3D map with a route and "Seen 2 times: west hedges, Spire steps"; a "⚑ LAND HERE" flag on the Heart (rh_report0) | §13.2 says "where the crew was seen" (no map) | TD.66 has no map | Map **applied**. Flag on the Heart: **held by the §23.5 Scout report row** (same component; lab-curation analysis :272). Map in TD.66: **new R3-9** |
| 433 | Which wards fired and which guards caught anyone | "What fired · Bell post at the gate rang · Bramble caught three crew · Stillness hid your Warden" | §13.2 "what fired" | TD.66 | **Applied.** Definition: **G57** |
| 434 | A replay | "Watch replay" (META:249) | §13 (DOC:7467) "can watch the replay" | Not in TD.66 (T3.3 keeps replays 90 days) | **Applied.** In TD.66: **new R3-9** |
| 435 | Trace, live for 24 hours | "Trace Marta · Free scout · 22 h left" on a HELD raid | §12.3 (DOC:6932) "within 24 hours of being robbed" | TD.66 "Trace from each" | **Applied** in shape. Which raids qualify: **new R3-3**. Window in TD.66: **new R3-9** |
| 437 | Raider names hidden while a raid is happening | "A crew is in Tidehold now · The raider’s name shows when the raid ends" (META:240) | §13 "notified afterwards"; watching live is 1.1 (DOC:7483); §17.8 "raids are anonymous while they happen" (DOC:8979) | D83 refuses the live banner | **New R3-6** (owner intent on D83) |

### New screen: First launch (REV:439-451)

| REV | Line | Screens now | v3.6 | Roadmap | Status |
|---|---|---|---|---|---|
| 441 | Age band from the platform; under 13 told 13+, no account | Bands `['Under 13','13 to 15','16 or 17','18 or older']`. "Ruleborn is for 13 and up · No account was made" with CHANGE AGE RANGE (META:459-460, 1601) | Agrees (DOC:10166) | TC.10 done; TD.26 ("no way back from under 13") | **Applied.** The way back and the pre-selected band: **held by D87**. Prompts before the heist: **C51** |
| 442 | Title line "Your islands. Your rules. Their treasure." | META:442 | §1.1 (its "Store and trailer" line; v3.6 is silent on first launch, so adopted) | TD.26 | **Applied** |
| 444 | 0:00 The Archivist catches a falling page: Half gravity | "Catch the page": the player catches it (META:1603) | §16 (DOC:8844): "The Archivist catches" | TD.26 | **New R3-15** (low) |
| 445 | 0:30 placed in the Heart; stones lift | "Place it in the Heart ... Stones float"; "stability 96%" | §16 | TD.26 | **Applied.** No note at 0:30: **D87**. 96%: **§23.5 First session row** |
| 446 | 1:15 Featherkin, Emberling, Tidewalker wake, each shows its ability | "Wake the three · Featherkin scouts, Emberling breaks, Tidewalker swims"; "Scout · Breaker · Swimmer" | §16 | TD.26 | **Held by D87** (abilities named, not shown; Swimmer label) |
| 447 | 2:00 First heist into a Drifting ruin running Slow rivers | "That drifting ruin runs Slow rivers ... Launch the heist" | §16; the time is contested (§15.2, §25.2) | TD.26 | **Applied.** Timing: **C51**. Stars on HEIST WON: **D87** |
| 448 | 5:00 Slow rivers unlocked; two strays follow home | "Two strays followed you home. Put them to work at the Star Well." | §16 | TD.26 | **Held by D87** (Star Well alone). Essence from a Star Well: **§23.5 First session row** |
| 449 | 6:30 Bloom woven into the Heart's second slot; stability bar | "Here is Bloom ... Weave Bloom · Keep it green" | §16 | TD.26 | **Applied.** "Keep it green": **D87**. Instant weave: **C51** |
| 450 | 7:00 Two ruins to choose from | "Pick a ruin · You run this one alone" | §16 | TD.26 | **Held by D87** (chosen, never run) |
| 451 | 10:00 The Lab names Mangrove banks; three daily goals | "Mangrove banks. Your first signature resonance."; "Today’s goals" on the done screen (META:472) | §16; goals §14.6 | TD.26, TD.40 | **Applied.** Insight pages and tired crew: **D87**. "Keeper level 3" at the end: **D87**. The day-2 notice: **R1-2** |

### README "Open items" (README:228-239)

| README | Item | Status |
|---|---|---|
| 228-231 | "Items still open from it are listed below", to apply while implementing | Leaves out the HUD, result, Weaving, Observatory, Season, defence report and first launch, so it treats them as done. **New R3-14** (low) |
| 233 | Theft one-way, Trace shown | Done in the screens (see REV:365). The README is stale here. Covered (C50 for Open Vault). Trace eligibility: **R3-3** |
| 234 | The GDD's terms for rating, XP, power, builders, stolen, revenge | Stolen and revenge done. Rating, XP and power: **§23.5 Profile and Character rows**. Builders: **D73** |
| 235 | Demo player Keeper 24, adult, 5 realms, crew of 5 | **Applied** (DATA `player`) |
| 236 | Small fixes on 04, 10, 11, 12, 14, 15, 21, 24, 25 and 27; school shapes on every law icon | The README uses SCREENS.md numbers (21 = Terrain editor, 24 = Workshop, 25 = Forms, 27 = Friends; REV 22, 25, 26, 28). The fixes are Part 1's screen-by-screen items (another part), held by D75, D82, D83, D85, D86 and §23.5's rows. Shapes: **R3-11** |
| 238 | All text at least 13 pt | **Held by the §23.5 Text size row**; TD.2, TD.3 |
| 239 | All tap targets at least 44 pt (48 per GDD 12.7) | §21.1 asks 48 pt for primary controls on every screen. TD.3 follows §21.1. **R3-13** |

## Findings

### R3-1 (intent, high). The brief and the screens draw the crack ring that the owner's answer to F35 removed. R1-5's list of restated rules misses it, and the analysis adopted the ring

- REV:388: "While anyone cracks, draw a ring 5 m round the Vault by walking path: guards inside it hear the cracking (12.6)."
- The screens draw it. DIO:208: `H.reach=new T.Mesh(new T.RingGeometry(4.86,5,96),...)`, at the Vault. SV3:1321's hint: "Pip loads while the Vault cracks · guards within 5 m hear it".
- v3.6 keeps it (DOC:6984): "every 5 seconds of cracking every guard within the crack’s reach of the Vault, 5 m by the walking path, hears it ... The reach is drawn as a ring around the Vault while anyone cracks".
- The owner's recorded answer is F35 = D ("picked", build "done", answers.json). Brief F35 option D: "A hit on the Vault is heard by no guard. A guard beside it still sees the crew. The 5-second call, its ring and the Vault's Sound::Breaking all go."
- The simulation follows the answer (sim/src/heist.rs:20-22): "The owner decided no guard hears the Vault (F35): neither is simulated."
- C45 names this conflict: "F35's answer D (no guard hears the Vault) against v3.6's new §32.8 row for brief 37, 'shipping at 5 m'". It does not say that the screens draw the ring.
- Two readings treat the ring as settled:
  - screens-heist-result.md §1.5 adopts it: "The 5 m crack ring and the 'Cracking · heard within 5 m' banner ... §12.17 asks for the ring".
  - review-1's B3 marks it "Ring fixed".
- R1-5 lists the brief's other restated rules (F46, F44, F39, F41) and not F35.
- TD.17 and TD.42 say nothing either way. A port of the screens would draw a ring and a hint for a rule the simulation does not have.
- The owner wrote the brief after answering F35, so this is intent to raise, not an answer.

### R3-2 (missed, low). If the ring stays, the design draws it as a circle, not by the walking path

- DIO:208 draws a flat circle of radius 5 round the Vault.
- The rule is "5 m by the walking path" (DOC:6984). Part 2 says "guards inside it hear the cracking" (REV:388).
- Behind a wall, a guard inside the circle can be more than 5 m away by path, so the circle shows guards hearing who do not.
- §21.12 (DOC:11086-11088) asks for sharp shapes: "A tile is inside or outside."
- The analysis adopted the circle (heist-result.md §1.5). The register and the roadmap say nothing about its shape.
- This applies only if C45 restores §12.6's 5 m against F35 (R3-1).

### R3-3 (missed, medium). Who may Trace: v3.6 says "robbed", the server excludes foiled raids, and the design and the owner's brief give a Trace after every raid

- v3.6 §12.3 (DOC:6932): "Trace: within 24 hours of being robbed, a player can target the raider once, with a free scout and no entry fee." But §13.2 (DOC:7513): "theft is one-way and a defender loses nothing". No raid robs anyone, so "robbed" has no defined meaning.
- The server reads it narrowly. server/src/matchmaking.mjs:157-169: "Robbed: a raid on their island that was not foiled", with `json_extract(h.outcome, '$.verdict.grade') != 'foiled'`.
- The design gives a Trace after a held raid. META:1240's Marta row is HELD ("Three of four crew caught at the gate", "Denied 3,300") and carries "Free scout · 22 h left". The report shows "Trace Marta · Free scout · 22 h left" (rh_report0.png).
- The owner's brief says the same. REV:365: "The answer to a raid is **Trace**: within 24 hours, target the raider once". REV:435: every raid report has "a **Trace** button, live for 24 hours".
- No register item, brief entry or task records the three readings. TD.66 says "Trace from each". The server's README:135 repeats "a robbed player".
- The choice changes who can Trace, and so who gets a free scout and no fee.

### R3-4 (intent, medium). "Keep the Archivist card" bears on G48, whose recommendation drops the Archivist's heading

- REV:398: "At the top: the decisive moment with a 3-second replay ... plus one thing to try. **Keep the Archivist card.**"
- The screens keep it: "The Archivist · try this" (SV3:768).
- G48 is open. Its brief options:
  - A, recommended: the tip "in a row labelled 'Try this', not the Archivist's".
  - B: "As A, under the Archivist's heading ... §15.3 exempts it from the Archivist's one-a-session limit and from turning tips off".
- TD.17 builds "Try this" switchable on G48.
- The owner's line is not an answer. It is the strongest statement of intent on G48 in the handoff, and the brief's entry does not mention it.

### R3-5 (intent, medium). "A getaway at 2 of 6 alarm is Loud" and "(20.3)" bear on C47

- REV:394: "Headline is the outcome (12.9) ... **A getaway at 2 of 6 alarm is Loud.**" This reads §12.9's "alarm" as the six-level ladder, which is C47's option B reading.
- The screens follow it: "2:14 · 2 / 6 alarm" under Loud (SHOT 07).
- C47 records why that reading is hard: the ladder climbs "once every thirty seconds" (§12.6, DOC:6984), so "Clean must be redefined, since the ladder leaves 0 within 30 seconds" (brief C47, option B).
- REV:400 asks the worth question "At the end ... (20.3)". §20.3 asks it once per session, which is C47's option A frequency, not §23.2's every result.
- Neither line is an answer. Both are the owner's leaning on an open entry.

### R3-6 (intent, medium). "Raider names stay hidden while a raid is happening" asks for a live, anonymous raid; D83 refuses the banner without the owner's line

- REV:437: "Raider names stay hidden while a raid is happening." The design draws a live banner: "A crew is in Tidehold now · The raider’s name shows when the raid ends" (META:240).
- D83 refuses it. Its row reads "Defence log, a raid under way ... 'The defender is notified afterwards and can watch the replay', and watching live is version 1.1 — §13", and its recommendation "shows a raid only once it has ended".
- v3.6 speaks both ways:
  - §13 (DOC:7467): "The defender is notified afterwards". DOC:7483: watching live is version 1.1.
  - §17.8 (DOC:8979): "raids are anonymous while they happen".
- A practical limit D83 does not state: under §24.12 a heist runs on the device and settles at validation. The server knows of a raid under way only as an open lease, and an offline heist may never be submitted.
- The owner's brief explicitly expects the defender to see a raid in progress, so a flat refusal will surprise the owner.

### R3-7 (spec, medium). TD.17's gate reads only §23.2's Heist row, so most of Part 2's HUD, and of §12.6, §12.7 and §21.8, is in no acceptance test

- TD.17's detail lists "portraits with pips and lockout, Get out and the skiff, the alarm with its newest effect in words, the Vault and load target, the Sage dial".
- Its gate is "the screen gate for §23.2's Heist and Heist result rows ... no more than §12.7's eight controls live at once (a test)".
- §23.2's Heist row is "At most eight controls (12.7), clock, alarm meter, vision cones, loot, Vault progress" (DOC:11211-11213). Rules that Part 2 restates and v3.6 holds outside that row are in no test:
  - Regroup in Get out's place while split (§12.7, DOC:7030; REV:381).
  - Gait by a held tap on the ground, a plain tap at the last gait, and no gait button (§12.18, DOC:7353; REV:383). The client has a gait button today (client/scripts/heist_screen.gd:304). G47, which holds it, is in TD.12's register list but not TD.17's (TD.17 lists C47, D79, D80, G48).
  - Dragging a portrait onto a fork to split the crew (§12.7; REV:382). R1-3 covers aiming only.
  - A health bar per creature, down for 10 s, revived in 3 s (a Mender 1.5 s) at 30% (§12.20, DOC:7401; REV:386).
  - The clock red for its last 30 s (§12.6; REV:389).
  - The skiff's arrival, 5 s or 20 s (§5.4, DOC:828; REV:389).
  - Left-handed mirroring (§12.7, §20.8; REV:390).
  - §21.8's Heist layout and Ability uses rows (DOC:11000-11005; REV:385). The number beside the pips and the pause mark are in D80, but the gate does not read §21.8.
  - §12.6's "Always on screen ... awareness of guards the crew can see ... each crew member's ability uses left" (DOC:6998). TD.42 has the cones.
- Each of these is in the screens today (coverage table, rows 381-390), so the port can lose them unnoticed.

### R3-8 (spec, low). TD.17's result lacks the next-step rule and the "what was kept" list

- REV:396: "Show 'Raid again' only if an idle crew exists; otherwise 'Pick a crew'." The screens always read "Raid again · Idle crew of 5 ready" (SV3:1498). D80 records the error ("After the heist ... 'Idle crew of 5 ready' when all five went"), but gives no rule.
- REV:399: "On a loss: list what was kept (crew home, pages, Codex entries). Never show the player's own stock as lost." This is §12.14's "a foiled heist still returns the crew, the pages and the Codex entries" and §20.3's "results show what was kept".
- TD.17 says only "loot kept".
- v3.6 is silent on the CTA. §12.5's "A crew of 3 to 5" sets what "an idle crew" means.

### R3-9 (spec, medium). TD.66 leaves out the outcome, the replay, the map and the Trace window that the owner's spec and the screens have

- REV:427-437 asks each report for: the outcome; the haul denied; how long it held; where the crew was seen "on the island map"; which wards fired "and which guards caught anyone"; a replay; and "a Trace button, live for 24 hours".
- The screens have each (rh_report0.png: HELD tag, "Haul denied 3,300", "Held the crew 2:31", a 3D map with the route and "Seen 2 times", "What fired" including "Bramble caught three crew", "Watch replay", "Trace Marta · Free scout · 22 h left").
- v3.6 supports the replay: "The defender is notified afterwards and can watch the replay" (DOC:7467). T3.3 keeps replays 90 days for both sides.
- TD.66's detail is §23.2's four facts and "Trace from each". Its gate is "raids on you, each with its report, and Trace; the raid badge clears once the log is seen".
- No replay, outcome name, map, Trace window or eligibility (R3-3), and no rule on a raid under way (R3-6).

### R3-10 (spec, low). TD.20 does not name the Heart's two slots or the crown slots by Spire level

- REV:405: "Heart: two realm slots, no third. Add the crown slots at the Spire: one from Spire level 2, a second from Spire level 5."
- v3.6 agrees (DOC:645-647).
- The screens show one crown slot at Spire 6 (SHOT 05), held by §23.5's Crown slots row. The realm view draws a locked third Heart slot, held by D75.
- TD.20's detail and its §23.2 Weaving gate (recommended laws, seven-band bar, harmonies and clashes) cover neither. TD.14 prices crown laws but does not draw their slots.

### R3-11 (spec, low). TD.5 does not hold one set of seven school marks across every screen; the design has three sets and no Heart circle

- REV:367: "School shapes (5.2), the same on law cards, the Icons sheet and the colour-blind panel: Heart circle, Motion chevron, Matter cube, ..."
- The design has three sets (design-system.md §4.4):
  - `RBIcons.school` (DIO:9-16), right for the six schools, with no Neutral/Heart mark.
  - Dormant CSS clips.
  - The colour-blind panel's clips (META:902): Matter a hexagon, Life a gem, Spirit an ellipse.
- The register holds the pieces: §23.5's Colour-blind row (Life), D87 (Spirit), D75 (Heart Neutral, "the circle").
- TD.5 says only "The school marks keep Matter's cube edges". The analysis's advice to "Port set 1 only" (design-system.md §10.5) is not in any task.

### R3-12 (intent, low). "No countdowns" against the Season header's "18 days" and TD.23's "season's end time"

- REV:423: "No countdowns or 'last chance' banners."
- The Season header has an "18 days" chip with a timer icon (SHOT 17; season analysis :50). The analysis adopted it: "§18.8 bans timers on the home screen and 'last chance' banners, not a plain date on the season's own page. It must never turn red or pulse." (season analysis :109).
- TD.23 builds "the season's end time". README:168 lists "season time remaining" among server data.
- v3.6 §18.8 (DOC:9121): "No 'last chance' banners, no timers on the home screen, no notification when a season is ending". It is narrower than Part 2.
- The owner's two documents disagree with each other. v3.6 allows either, so the design is adopted only where it breaks no rule, and Part 2's "no countdowns" is the owner's stated preference.

### R3-13 (intent, low). Three Part 2 lines disagree with v3.6; the screens and the roadmap already follow v3.6

These are recorded so that nobody ports from the brief's wording:

1. **Tap targets.** REV:366 and README:239 ask 44 pt away from the heist. §21.1 (DOC:10411): "Primary controls are at least 9 mm across — about 48 points ... Nothing interactive sits in a screen corner", on every screen. 44 pt is the figure D47 removed from §19.2 (D47 is fixed; §19.2 now reads "about 48 points", DOC:9262). TD.3's gate uses §21.1.
2. **Moving two crew.** REV:383: "Tap two portraits to move them together". §12.7 has a portrait tap fire the ability (DOC:7012). §12.18: "Tap a crew member to select ... Tap two to move them together" (DOC:7353), meaning the crew in the world. The screens do it that way ("Tap crew, then ground", SV3:1321).
3. **Guards' cones.** REV:387: "Every visible guard shows its vision cone". §21.12 (DOC:11086): "One shape at a time. The selected guard's vision is drawn; the others show only their facing." The screens follow §21.12 (screens-heist-result.md §1.2).

### R3-14 (intent, low). The README's open items treat the screens Part 2 redid as done; the register holds about 60 departures in them

- README:228-239 lists only the global words, the "small fixes" and the size pass as still open.
- So the owner treats the HUD, result, Weaving, Observatory, Season, defence report and first launch as done. v3.6 §23.5 says the same: "The heist screen, the planner, the result, the Observatory, Weaving, the defence log and the first launch already follow this document" (DOC:11418).
- The register holds the departures in exactly these screens: D78 (5), D80 (11), D81 (5), D83 (13, defence log part), D84, D85 (7), D87 (13), and the open decisions G47, G48, C47, G57, C51.
- The owner will read D78 to D87's "Add the rows to §23.5" against a handoff that calls these screens finished.

### R3-15 (missed, low). First launch 0:00: the player catches the page; §16 has the Archivist catch it

- The design's first beat is "A page is falling out of the dark. Catch it before it’s gone." with the button "Catch the page" (META:1603).
- §16 (DOC:8844): "The Archivist catches a falling glowing page: Half gravity". REV:444 says the same.
- D87's first-launch beats row lists five other departures and not this one.
- It is a piece of text in §16's script, which the document wins on (§23.5).

## Not new (checked and already held)

Ids used in the coverage table: §23.5 rows (Role health, Trace target, Crown slots, Season track, Text size, Colour-blind panel, Profile header, Character screen, Scout report, Weaving, First session; DOC:11423-11568), C45, C46, C47, C50, C51, D73, D75, D78, D79, D80, D81, D83, D84, D85, D87, F57, G31, G47, G48, G57, G69; R1-2, R1-3, R1-5, R1-6; H-14; roadmap TD.2, TD.3, TD.5, TD.12, TD.13, TD.14, TD.16, TD.17, TD.18, TD.20, TD.23, TD.26, TD.39, TD.40, TD.42, TD.44, TD.66, TC.10.
