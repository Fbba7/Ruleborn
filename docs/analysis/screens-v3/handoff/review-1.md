# Handoff review, Part 1: "Fix first", "Numbers that disagree", "Not designed yet"

Read against the repository at commit 6cc1d1e; the line numbers it cites in the register (AR), the brief and the roadmap (RM) are that commit's. What it proposes was checked and folded into the register's v3.6 layer, the brief and stage SD afterwards ([README.md](README.md)). The earlier reading's reports, cited by file name, are in the folder above.

## Sources and short names

- REV: the handoff's `docs/ruleborn-screen-review.md`, copied unchanged to `source/ruleborn-screen-review.md`; lines 11-118 (my part).
- SV3: handoff `prototype/Ruleborn Screens v3.dc.html` (screens 01-09 and the landing picker).
- META: handoff `prototype/RulebornMeta.dc.html` (byte-identical to the artifact's copy, checked with `cmp`).
- DATA: handoff `prototype/ruleborn-data.js`.
- SHOT: `scratch/shots/all/Gameplay_NN_*.txt|png` (the artifact rendered at phone size; same screens; not kept).
- DOC: `docs/design/ruleborn-game-design-v3.6.txt`.
- Register: `tools/audit_register.py` (v3.6 layer). Roadmap: `tools/roadmap.py`. Analysis: `docs/analysis/screens-v3/`.

Screen numbers. REV and the screenshots number screens the same way. SCREENS.md and the source labels differ from 19 on: REV 20 Profile = SCREENS 19b (`data-screen-label="19b Player stats"`); 21 First launch = 20; 22 Terrain editor = 21; 23 Landing picker = 22 (in SV3); 24 Harmony = 23; 25 Workshop = 24; 26 Forms = 25; 27 Share = 26; 28 Friends = 27.

## The main result

The review was the fix brief, and the current screens apply most of it. v3.6 §23.5 was written after those fixes: "The heist screen, the planner, the result, the Observatory, Weaving, the defence log and the first launch already follow this document; these are the differences that remain" (DOC:11418). So most items below are **fixed**. What is still open is, in almost every case, already a §23.5 row (the document's own decision, "the build follows") or a register item (D73, D75, D78, D79, D80, D82, D83, D84, D85, D87, C45, C47, F57, G46, G47, G57). The analysis missed one problem (the scout report's crew matchups), and two roadmap tasks lack guidance that the review and v3.6 both give.

v3.6 did not change any rule the review cites. I checked each one: §5.1 (DOC:645-649), §5.2 (DOC:655), §5.4 (DOC:814-834), §5.5 (DOC:843-900), §6.1 (DOC:1154), §7.4 costs and ranks (content/laws.json, which is extracted from v3.6), §7.6 (DOC:2205-2217), §7.10 (DOC:3846-3858), §8.5 (DOC:4227), §10.2 Aether storage and the Lab (DOC:4760-4823, 5666), §11.1, §11.2, §11.4, §11.6 (DOC:5922-6180), §12.3-12.5 (DOC:6920-6956), §12.7 (DOC:7006-7030), §12.9 (DOC:7072-7110), §12.12 (DOC:7141-7143), §13.2 (DOC:7513), §18.8 (DOC:9108-9126), §20.2 (DOC:10170-10205), §23.3 (DOC:11333-11360). Two review figures are loose, not changed: "Storage tops out at 34,000, at Spire 10" (34,000 is reached at Spire 7, DOC:4802), and "Eleven screens ... 11 to 19, 21, 22 and 26" (that list is twelve; §23.5 says twelve, DOC:11565).

## Coverage table

Status words: **fixed** (the screen now follows the rule); **open, held by X** (still wrong, and X already holds it); **new finding R1-n**.

### Fix first (REV:15-67)

| # | Item | What the screens show now | Status |
|---|---|---|---|
| 1 | Theft reads as two-way | 01: "Marta raided Verdant · you lost nothing / Your defence kept 1,240 Essence safe" with a TRACE button (SV3:326). 07 Foiled: "Renown −8 · nothing else is lost" (SV3:1490). 15 and 22: tiles read "✦ REACHED THE VAULT" (SHOT 15, 22); no "STOLEN" anywhere (grep). 20: records list "Pages studied", battle log "you lost nothing" (META:1240, 1477); no "Laws stolen". 21: "Your islands. Your rules. Their treasure." (SHOT 21), which is §1.1's own line (DOC:187). An unrendered "REVENGE" ribbon survives in dead code (SV3:1354), overridden by "TRACE · 24 H" / "ECHO" (SV3:1365). | **Fixed.** Left over: Foiled says "nothing else is lost" while the fee is "paid to Marta": held by D80 (Foiled row). |
| 2 | Heist HUD breaks the control model | Five portraits, Sage, Cast, Get out: eight (SHOT 02 png). Gait by holding the ground ("Tap crew, then ground · hold ground to sneak or run", SV3:1321). Abilities are §11.2's: Stuff the satchel, Unslowed, Root, Stand over, Burst, Crystal wall (SV3:911-917). Health bars, no hearts or stamina in the rendered HUD; the stars, SNEAK/WALK/RUN and "1 heart" text survive only in an unrendered pass (SV3:1293; analysis screens-heist-result.md §1.6). Outcomes Clean/Loud/Partial/Foiled. | **Fixed in the HUD.** Open: role health 260/200/180 (DATA `health`) held by §23.5 Role health row (DOC:11425); four-ready rule, uses-number, Burst and Unslowed effects held by D80; Sage wheel leaves portraits live (11 tappable) held by G47; drag-to-aim and hold Get out missing: analysis H8, H9, not in register or roadmap, see **R1-3**. The cut abilities still appear on the scout report: **R1-1**. |
| 3 | Money buys progress on the season track | "+5 tiers now" is gone (grep). The robe reads "Legendary · claimable in any later season" (SHOT 17). Still: "+20% ★" with the Starpass (META:272), 30 tiers (META:269), "AFTER TIER 30 · STAR CHESTS". Shop priced in Starglass ✦ ("120 ≈€1.20", "100 ✦ is always €1", SHOT 18). | **Partly fixed.** Star boost and Starpass-only quest held by D84; 30 tiers held by §23.5 Season track row (DOC:11475); Starglass held by F57 and C45 (the owner's answer to F41 removed the currency; the review asks for Starglass, see **R1-5**). |
| 4 | Protections for 13-15 can be switched off | For 13-15 the play-time reminder is locked at 60 min and quiet hours locked at 21:00-08:00 (`ptLock = band === 0`, `qhLock: minor`, META:1546, 1569). Profile hides Share for 13-15 (`shareOn: ageBand !== '13–15'`, META:1480). The €25 cap is computed (`zcapL`, META:1549) and never drawn; Shop and Payments show "ASK TO BUY" to every band (SHOT 18). | **Mostly fixed.** Locks drawn like open choices held by §23.5 Locked protections row (DOC:11520); Account tab highlight by §23.5 (DOC:11525); cap not drawn held by D85 and D87; band preview loosening the locks held by D87; 16-17 reminder Off held by G58. |
| 5 | Observatory leaks the paid scout | Cards show name, level, realms, Renown, rough loot, depth, why, entry fee; "Laws, guards and wards show after a scout" (SHOT 08). Levels 23, 25, 22 under "Keepers 21–27 · Renown within 150" (SV3:1364, 912-915). Refresh 50 Aether doubling (`RB.refresh`, SV3:1364; DATA). "TRACE · 24 H" ribbon. "Drifting ruins · Pages, Essence, no Renown". | **Fixed against v3.6.** But the owner's answers F46 (free scout), F44 (two below to three above) and F39 (fee from B(V)) replaced these rules; held by C45. Trace card still charges a fee: §23.5 Trace target row (DOC:11430). Ruins one difficulty each: D78. See **R1-5**. |
| 6 | Heist route disagrees with the target | Planner: "Lantern Vale → Heart · 1 link", "165 s · 150 + 15 per link", "Crew 5/5" (SHOT 06). Landing picker: three landings for Marta's three outer realms, 165/165/180 s (`LANDINGS`, SV3:922). Scout report: "No skiffs: strong winds ring the Heart" but the 3D view still draws "⚑ LAND HERE" on the Heart (SHOT 09). | **Mostly fixed.** Land-here flag held by §23.5 Scout report row (DOC:11485); 3D charts with six outer islands by §23.5 (DOC:11545); crew toggle still stops at four (`pOn.length>=4`, "of 4", SV3:1423, 1440) held by D78; three named landings instead of any edge held by D78. |
| 7 | Law data drifted from the Codex | Codex ranks and costs now match v3.6 (Inward pull DEEP 22, Haste RARE 18, Static RARE 16, Thorns RARE 15, Echoes UNCOMMON 18, Bounce 14, Brittle stone 10, Kinship 14, SHOT 13; content/laws.json agrees). Pages by rank (18/60, 5/10, 14/35, 12/20). Law card Stillness tier III "24 pts", "960 Aether" (SHOT 03). Heart "LAWS 1/2". Non-launch laws gone from the deck. | **Fixed.** Open: one crown slot at Spire 6 held by §23.5 Crown slots row (DOC:11455); a locked third Heart slot still drawn (`slots:[0,1,2]`, SV3:1180) and crown laws absent from home held by D75; a hint naming Day and night (META:1829) held by analysis screens-roster-character-sages-forms.md:278 (D82 group). |
| 8 | Results ignore the outcome rules | Loud: "Haul ×0.7 · Renown ×0.8", "+2 pages", "Every crew member rests 60 min" (SHOT 07); Foiled "Renown −8", "+1 page", 180 min (analysis screens-heist-result.md §2.2). "Was this worth your time?" Yes / Not really. CTA "RAID AGAIN · Idle crew of 5 ready". | **Fixed.** Open: "Idle crew of 5 ready" after all five went held by D80; two-point worth scale held by C47; "It helps us tune the targets you see" held by C47. |
| 9 | Two flows are not designed | Defence log now opens a report: "Haul denied", "Held the crew", "What fired", "Trace" (META:246-249, 1240-1248). First launch now runs title, age check, protections, name and face, the beats, and a done screen (META:440-475). | **Fixed (designed).** Departures held by D83 (live raid banner), G57 (report facts), D87, C51, G58; build tasks TD.66 and TD.26. |

### Numbers that disagree with the document (REV:73-103)

| # | Screen | Review row | Now | Status |
|---|---|---|---|---|
| N1 | 01 | Aether 38.2k; cap 34,000 at Spire 10 | "31.4k" (SHOT 01); DATA `aether:31400, aetherCap:34000, spire:6` | **Open, held by §23.5 Aether storage row** (DOC:11450: "29,000 at Spire 6"); DOC:4795 gives 29,000 at Spire 6, 34,000 from Spire 7 (DOC:4802). The review's "at Spire 10" was loose; the design then put 34,000 at Spire 6. |
| N2 | 01 | Six outer realms at Keeper 24 | "Opens at Keeper 28" on the sixth island (SHOT 01) | **Fixed** (DOC:655). |
| N3 | 01, 04 | "Skyfield strained" and fault badges; realm view 82% vs Humming | No fault badges: `UFAULT={}` (prototype `realm-diorama.js:76`); home "82% · Humming", realm view "Steady · 62%" (SHOT 01, 04) | Fault badges **fixed**. Strain split **open, held by §23.5 Realm view strain row** (DOC:11445). |
| N4 | 03 | Stillness tier III 15 pts, 600 Aether | "24 pts", "960 Aether" (SHOT 03) | **Fixed.** |
| N5 | 04 | Heart "Laws 2/3"; "Builders 2/2" | "LAWS 1/2" (SHOT 04); builder cap still in code (`sel.builders<2`, SV3:975, 988) | Slots **fixed**; builders **open, held by D73**. |
| N6 | 05 | +15% lands in Steady from 82% | "+3% = 85% → HUMMING" (SHOT 05) | **Fixed** (85% is Humming, DOC:868-869). Weaving's price formula gaps held by D81. |
| N7 | 05 | Half gravity 960 Aether | Deck shows 760: Half gravity is held at tier III (`tier:'III'`, SV3:851), 12 × 1.6 = 19 pts × 40 (SV3:1054, 1205) | **Fixed**: the price follows §5.5 and §5.6 for its tier. |
| N8 | 06 | Crew 4/4 | "Crew 5/5", "5 of 5" (SHOT 06); toggle still caps at four (SV3:1440) | **Open, held by D78** (crew size row). |
| N9 | 07 | Rest 18/18/12, Hollow ready | "Every crew member rests 60 min" (Loud) | **Fixed** (DOC:6176). |
| N10 | 07 | +3 pages loud and caught | "+2" Loud, "+1" Foiled, "+3" Clean | **Fixed** (DOC:2205). |
| N11 | 07 | Caught Renown −6 | "Renown −8" | **Fixed** (DOC §12.9). |
| N12 | 08 | Reroll 400 Starlight | "50" Aether, doubling (SV3:1364) | **Fixed.** Dead `reroll` charging 400 Starlight remains at SV3:1348 but is replaced at SV3:1364. |
| N13 | 08 | Levels 4 to 7 | 23, 25, 22; "Keepers 21–27" | **Fixed** against §12.3; the owner's answer F44 (22-27) held by C45. |
| N14 | 08 | Sky ruin pays 2,200 Starlight | "Drifting ruins · Pages, Essence, no Renown" | **Fixed.** Ruin difficulties and rewards held by D78. |
| N15 | 10, 11 | XP bar; level 6 for 1,250 | Roster "Lv 6 costs 866 Essence" (SHOT 10); Character still "588 / 600 XP" and "+539 power" (META:910) | Roster **fixed**; Character **open, held by §23.5 Character screen row** (DOC:11465). |
| N16 | 11 | "once a heist" | Label "ONCE A HEIST" (META:91) over body "Two uses a heist, 10 s apart." | **Open, held by §23.5 Character screen row.** |
| N17 | 11 | Skyskipper resists no-jump zones | "RESISTS No-jump zones" (META:908) | **Open, held by §23.5 Character screen row** (DOC:5998: "Unbothered by Leapfrog's noise"). |
| N18 | 12 | Sage level 4 of 10 | "Level 4 / 40 · levels with Insight" (SHOT 12) | **Fixed.** No Insight price or level-up: D82 (Sage hall row). |
| N19 | 13 | Five ranks wrong | DEEP, RARE, RARE, RARE, UNCOMMON | **Fixed.** |
| N20 | 13 | Eight costs wrong | 14, 22, 10, 18, 16, 14, 15, 18 | **Fixed** (content/laws.json `stability_cost`). |
| N21 | 13 | Pages out of 10 | 18/60, 5/10, 14/35, 11/35, 18/35, 2/10, 12/20, 6/20 | **Fixed** (DOC:2217). Schools labelled as chapters: §23.5 Codex row (DOC:11510). |
| N22 | 14 | Settle 2 to 12 h | "Lab level 3 runs each test in 5 h 30 min" (META:1112) | **Open, held by §23.5 Resonance Lab row** (DOC:11540: 5 h; DOC:5666 table: level 3 "2 slot(s); 5 h"). One chamber for two slots held by D83. |
| N23 | 17 | 30 tiers | "STARPASS · TIER 30" (META:269) | **Open, held by §23.5 Season track row** (DOC:11475). |
| N24 | 20 | Rating 1,460 | Header "TIDE II 1,460 RATING" (META:342) | **Open, held by §23.5 Profile header row** (DOC:11470). |
| N25 | 22 | 80 terrain points | "94 left of 100 points" (SHOT 22) | **Fixed** (DOC:1154). The realm view's own "54 / 80" tray held by D73. |
| N26 | 23 | Clocks 140 to 210 | 165, 165, 180 s | **Fixed** (DOC:832). |
| N27 | 23 | Landing noise +25%, +40% | Skyfield "+50%", "50% NOISE" (SHOT 23) | **Open, held by §23.5 Landing noise row** (DOC:11480). |
| N28 | 24 | Chord 10% cheaper only | "While it sounds, the chord draws 192 stability." (SHOT 24) | **Fixed** (DOC:4227). Weaving leaves the draw out of its price: D81. |
| N29 | 25 | 62% "fair" for level 6 | "Fair budget · 62% · Lv 6 band" (META:1786) | **Open, held by §23.5 Workshop checklist row** (DOC:11490). |

### Not designed yet (REV:109-118)

| # | Bullet | Now | Status |
|---|---|---|---|
| B1 | Defender's raid report | Designed: denied, held, seen, fired, Trace (META:246-249). | **Fixed (designed).** Facts nothing records: G57; live-raid banner: D83; build TD.66, TD.39. |
| B2 | First session: age band, ten-minute script, the notice before a first raid that ends the 72-hour protection | Age check, protections, name, beats designed (META:440-475). The only shield words are on the done card: "SHIELD · Safe for 72 h. Raiding a player ends it." (META:474). Nothing warns before the first player raid. | Script **designed**, departures held by D87, C51, G58, TD.26. The notice §16 asks for "before the first one" (DOC:8879) is in the analysis (screens-observatory-scout-landing-planner.md:157; screens-settings-first.md:263) but in no register item and no roadmap task: **R1-2**. |
| B3 | Vault phase: who cracks and assist, crack-reach ring, load target, storehouses on the route | 5 m crack ring drawn ("guards within 5 m hear it", SV3:1321). Loading is automatic for one member; "Load to 80%" fixed (SV3:726). | Ring **fixed**. Crack orders and Vault health held by D80; load target held by G47; storehouses on the route held by D71 (one-island heist) and D77 / analysis N8. |
| B4 | Heist edge states | Split and Regroup, downed 10 s and revive, skiff 5 s / 20 s, red last 30 s, Sage wheel and 20 s dial, cast wheel: all designed (SV3:1293, 1321; analysis §1.2). No pylon. Casts and powers fire at the first selected member and cannot be placed. | Mostly **fixed (designed)**. Pylons held by D74 and TD.31; placing a cast or power is **R1-3**. |
| B5 | Planner fields | Route, Sage, casts, entry fee, "New to you: Sleepwalk" (SHOT 06). | **Fixed (designed).** Fee as "2% of Starlight" against F39's answer held by C45; Trace fee by §23.5; resting crew by §23.5 Heist planner crew row (DOC:11440). |
| B6 | Crown slots | Weaving shows one crown slot, "Kinship · Crown · every realm" (SHOT 05); data has `crown:2` (SV3:875). | **Open, held by §23.5 Crown slots row** (DOC:11455) and D75 (crown laws absent from home and realm view). |
| B7 | Paradox warning | "Unstable pairing: two tier III laws with opposite notes. A 10% chance of a paradox." (META:1112). | **Fixed** (DOC §7.5, line 2181). |
| B8 | Landscape and left-handed | Left-handed heist designed (Tweak `leftHanded`, analysis §1.2). Landscape not designed. | Left-handed **fixed**. Landscape **open, held by §23.5 Landscape row** (DOC:11560) and TD.28. The handoff README says the opposite: **R1-4**. |
| B9 | Interactions: "coming in a later turn" | Still on 11-19, 21, 22 and 26 (SV3:1175; SHOT 11-19, 21, 22, 26): twelve screens. | **Open, held by §23.5 "The designs' own notes" row** (DOC:11565, "twelve screens"). |
| B10 | Loss and retry | Worth card designed. Foiled offers "Two misses on Marta. Try “Marta’s outer ring”, the same laws with one guard fewer." (SV3:1496). | Designed. Worth scale held by C47; the easier copy of a player's universe held by D79, which refuses it; the review asked for it against "the same target": **R1-6**. |

## Findings

### R1-1 (missed, medium). The scout report's crew matchups use abilities and a law v3.6 does not have

The Crew tab of the scout report (step 3) reads each crew member's line from a per-realm table (`D.m`, SV3:1411). The lines name the abilities REV item 2 removed from the heist:

- "Shield blocks a Breaker", "Shield eats a Whisper", "Shield holds a hit" for Bramble (SV3:1377, 1378, 1380); also "Bramble’s Shield eats one Whisper ping." (SV3:1372).
- "Rewinds one mistake" for Hollow (SV3:1380).
- "Leap rides the Current" for Pip (SV3:1379); "Pip’s Leap rides the Current a tile further." (SV3:1372).
- "Wades past lanterns" for Mo (SV3:1378).
- "Wall blocks sight" and "Wall hides from Glass" for Facet (SV3:1377, 1380).

v3.6 §11.2: Mossbear "Roots in place for 6 s, taking half damage" (DOC:6085); Echoplate "Stands over the crew for 8 s ... returns at once at 40%" (DOC:6109); Skyskipper "Stuffs its satchel" (DOC:5997); Glass Golem's wall "does not block sight" (DOC:6013). Rewind is gone (DOC:3835). Current is not a launch law (DOC:3844-3845), and the scout data gives Skyfield Bounce (SV3:1372), not Current. The heist itself was fixed (SV3:911-917), so the screens now teach two different crews.

The analysis says only "Matchups exist, but as authored prose" (screens-observatory-scout-landing-planner.md:241) and proposes a rules-driven matchups task TC.15f (:483). No register item names the wrong abilities (grep of the register for "matchup": only D47/D48, closed). The roadmap has no matchups work at all (grep of tools/roadmap.py: none); TD.18 does not mention them.

Proposed: register-amend D78 (title to include the scout report): add the row "Scout report, Crew tab — matchups naming Shield, Rewind, Leap, Wade and a sight-blocking wall, and Current (SV3:1372-1380) — §11.2's abilities and resistances; the launch 24 — §11.2, §7.10". Roadmap-amend TD.18: "The scout report's matchups are generated from §11.2's ability and resistance for each kind, §12.21's size and flight, and the realm's laws; no authored prose; a test that every matchup line names only the kind's own ability and the realm's own laws."

### R1-2 (spec, medium). The notice before a first player raid has no task

REV:110 asks for "the notice before a first raid that ends the 72-hour protection". v3.6 §16: "Day 2: the first heist against another player's universe. Because raiding a player ends the newcomer's 72-hour protection early, the game says so before the first one." (DOC:8879); §12.3: "or until they raid a player themselves" (DOC:6930). The design says it once, after the first session, on the done card (META:474), not before the raid. The analysis saw it (screens-observatory-scout-landing-planner.md:157, "The player's own shield is not mentioned ... must say that raiding it ends the protection"; screens-settings-first.md:263), and the server already knows (`shielded()`, matchmaking.mjs, analysis :53). But TD.18 (Observatory, scout, planner) and TD.26 (first launch) do not carry it, and no register item does.

Proposed: roadmap-amend TD.18: "While the player is protected, the first player target's card and the planner's Start say that raiding a player ends the 72-hour protection (§16 day 2, §12.3), from the offer's `shielded` field; a presenter test for the shielded state."

### R1-3 (spec, medium). Aiming a power or cast, and holding Get out, are in no task

REV:112 lists "the cast wheel and circle (12.5)"; §12.7's table gives each control a hold or drag: "Drag onto the world to aim", "Drag a power onto the world to aim it", "Drag to place the circle", "Hold to choose where the skiff comes" (DOC:7015-7028); §20.8 asks that nothing needs a drag that cannot also be two taps. The design fires every power and cast at the first selected crew member and calls the skiff to the nearest edge (analysis screens-heist-result.md table 1.4, H8 and H9). The analysis holds this (H8, H9), but D80 lists eleven other places and not these, G47 covers the commands but not their targets, TD.12 says only "casts as four-tile circles", and TD.17 lists "Get out and the skiff" with no hold.

Proposed: register-amend D80: add the rows H8 (aiming) and H9 (Get out by hold). Roadmap-amend TD.12: "Ability, Sage and Cast commands carry a target tile or entity (a cast's circle centre, Suspend's law)". Roadmap-amend TD.17: "drag or two taps to aim a portrait, a power or a cast; hold Get out to choose the skiff's edge; a test for each".

### R1-4 (intent, medium). The handoff README says landscape is not supported; v3.6 and the review say it ships

README:20: "Recreate the UI pixel-accurately at 390 × 844 logical points and scale it to the device; landscape is not supported." REV:116 lists "Landscape layout (23.3)" as not designed yet. v3.6 §23.3: "Portrait is the default on phones; landscape is available everywhere and remembered per device." (DOC:11335), and §23.5's Landscape row: "Not designed | Portrait and landscape" (DOC:11560). The README statement is the owner's handoff, not an answer to anything; the document wins on a rule. It bears on TD.28 (Landscape for every screen) and TD.6 (portrait-only shell).

Proposed: roadmap-amend TD.28: note that the handoff README says "landscape is not supported", that §23.3 and §23.5 win, and that TD.28 stands unless the owner rewrites §23.3. If the owner means it, it is a document change (a §23.3 edit), to ask under TD.29.

### R1-5 (intent, low). The fix brief restates rules the owner's recorded answers replaced

The review asks the designer for: "laws and guards are the paid scout (12.4)" and "Targets sit within 3 Keeper levels (12.3)" (REV:42), "entry fee (2% of Starlight, 100 to 25,000)" (REV:113, and Part 2 REV:417), and "Cosmetics are priced in Starglass only (9.5)" (REV:30). The owner's recorded answers say otherwise: F46 B, "the target card shows laws, guards and ward counts"; F44 D (two levels below to three above); F39 B (fee from B(V)); F41 C, no currency (docs/decisions/answers.json). The screens followed the review (SHOT 08 "Laws, guards and wards show after a scout"; "Keepers 21–27"; "Entry fee 2,840 Starlight · 2%"; ✦ prices). C45 and F57 hold the three-way conflict; the review is a fourth source on the design's side. It is not an answer: it cites the document and never mentions the answers.

Proposed: brief-context C45 and F57: add that the owner's own fix brief to the designer (handoff `docs/ruleborn-screen-review.md`) asked for the document's rules, not the answers, so the owner should confirm in C45 which stands; the handoff does not record a reversal.

### R1-6 (intent, medium). The review asked for an easier version against the same target; D79 refuses it for players

REV:118: "the easier version offered after two failures (12.12, 12.14)", and Part 2 REV:401: "After two failures in a row against the same target, offer an easier version by name (12.12)." The design built it on a player target: "Two misses on Marta. Try “Marta’s outer ring”, the same laws with one guard fewer." (SV3:1496). v3.6 §12.12: "After two failures in a row the game offers an easier version, visibly and by name ... Heists against players are never adjusted for engagement at all (19.12)." (DOC:7141-7143); §12.14 leaves "an easier version by name, a new route revealed, or a different target suggested" (DOC:7165). D79's rec refuses it outright: "an easier version, by name, only for ruins". The owner's brief suggests the owner read §12.12 as covering any target. That is not an answer, and §12.12 does not settle it either way.

Proposed: register-amend D79: record that the design follows the owner's fix brief ("against the same target"), that §12.12 does not limit the easier version to ruins, and make the player-target case an owner decision (a §12.12 sentence) rather than a refusal; until answered, the build follows D79's reading.

## Not new (checked and already held)

Everything else in my part is fixed in the screens or held, as the coverage table says. The ids used: §23.5 rows (DOC:11425-11565), D71, D73, D74, D75, D77, D78, D79, D80, D81, D82, D83, D84, D85, D87, C45, C47, F57, G46, G47, G57, G58; roadmap TD.18, TD.26, TD.28, TD.31, TD.39, TD.66.
