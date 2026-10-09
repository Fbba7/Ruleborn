# Handoff review, Part 1: "Improvements", "Text and tap sizes", "Screen by screen", "What already works", "Fixes for the design document"

Read against the repository at commit 6cc1d1e; the line numbers it cites in the register (AR), the brief and the roadmap (RM) are that commit's. What it proposes was checked and folded into the register's v3.6 layer, the brief and stage SD afterwards ([README.md](README.md)). The earlier reading's reports, cited by file name, are in the folder above.

## Sources and short names

- REV: the handoff's `docs/ruleborn-screen-review.md`, copied unchanged to `source/ruleborn-screen-review.md`; lines 120-358 (my part). Line numbers below are REV's own.
- SV3: handoff `prototype/Ruleborn Screens v3.dc.html` (screens 01-09 and the landing picker).
- META: handoff `prototype/RulebornMeta.dc.html` (screens 10-28; byte-identical to the artifact's copy).
- ICONS: handoff `prototype/ruleborn-icons.js` (byte-identical to the artifact's `icons_rbi.js`).
- SHOT NN: `scratch/shots/all/Gameplay_NN_*.txt|png`, the artifact rendered at phone size (not kept).
- MEAS: my own measurement, every text run and tap target of all 28 screens, in `data/screen-sizes.json`, summarised per screen in `data/screen-sizes.txt` (script `scratch/r2/probe_r2.mjs`, not kept).
- DOC: `docs/design/ruleborn-game-design-v3.6.txt`. Register: `tools/audit_register.py`. Roadmap: `tools/roadmap.py`. Analysis: `docs/analysis/screens-v3/`.
- R1-n: findings of the sibling report `review-1.md` (my part does not repeat them).

Screen numbers: REV and the screenshots share numbering. REV 20 = SCREENS.md 19b Profile; 21 = 20 First launch; 22 = 21 Terrain editor; 23 = 22 Landing picker; 24 = 23 Harmony; 25 = 24 Workshop; 26 = 25 Forms; 27 = 26 Share; 28 = 27 Friends.

Is the artifact the current design? I diffed SV3 against the artifact's `screens_main.js` and `screens_main.markup.html`. After normalising the bundler's spelling (`sc-camel-on-click` against `onClick`, `sc-camel-view-box` against `viewBox`, comment anchors, inline fonts against a Google Fonts link, asset ids against `world/...` paths), the only content change is the Friends index note (SV3:68: "cosmetic gifts, preset pings, invites and add-by-code (17.6), block and report (17.8)" where the artifact said "page gifts"). So the screenshots show the current screens. META, the data module and the icon module are byte-identical.

## The main result

REV Part 1 was written against v3.5 and handed to the design tool; the screens were then reworked and v3.6 §23.5 recorded what still differs ("The heist screen, the planner, the result, the Observatory, Weaving, the defence log and the first launch already follow this document; these are the differences that remain", DOC:11418). Of the 113 bullets in my part (8 improvements, 94 screen bullets, 8 "already works", 3 document fixes) and the 20 size rows, most are **fixed** in the screens, and nearly every open one is a §23.5 row or a register item (C44, C49, D73, D75, D77, D78, D80-D85, D87, D91, F57, C45, G28, G48, G53, G54, G55, G69). v3.6 changed two rules the review relies on: §18.8 now keeps the free lane's pages, Essence and stray (DOC:85, 9124-9125, the owner's answer G28 B), and §23.2 gained the Profile row and declares itself the must-show list (DOC:11393, 11400-11401, 11315-11317). All three "Fixes for the design document" were taken into v3.6.

I measured text and tap sizes on all 28 screens with the review's method (every visible text run's computed size; the box of every button, link or pointer element; status bar and badges included). On the screens that did not change, my counts equal the review's to the run (09: 49 of 57 and 3 of 9; 12: 35 of 39 and 9 of 22; 20: 35 of 45 and 37 of 38), so the method matches. Heist, planner and result now meet the 13-pt floor almost entirely; every other screen still sets most text below 13 pt. That is §23.5's Text size row (DOC:11515) and the stage SD screen gate (`tools/roadmap.py:1244-1249`, "§21.1's sizes ... at 100%, 150% and 200% text").

Six things are not held anywhere: four small and two that change TD.18 and the icon export. They are R2-1 to R2-6 below.

## Text and tap sizes, measured (REV:133-160)

Review figures beside mine. Same frame (390 × 844), same counting. "<48" is §21.1's and §12.7's 48-point figure, which v3.6 uses; the review used 44.

| Screen | REV text < 13 pt | Now | REV smallest | Now | REV taps < 44 | Now | Now < 48 | Status |
|---|---|---|---|---|---|---|---|---|
| 01 Universe map | 38 of 47 (81%) | 34 of 45 (76%) | 8.5 | 8.5 | 11 of 21 | 11 of 21 | 16 | open: §23.5 Text size; taps C44 (side buttons 44, strain pill 30, Trace 32, × 28) |
| 02 Heist | 39 of 48 (81%) | 1 of 23 (4%) | 9 | 11 | 8 of 12 | 0 of 8 | 0 | **fixed**; the one run is the 3D "VAULT" label at 11 pt |
| 03 Law card | 62 of 86 (72%) | 7 of 15 card only (8 of 38 with the heist HUD under it) | 6.5 | 9 | 10 of 26 | 1 of 15 (Close 36) | 4 | improved, open: §23.5 Text size |
| 04 Realm view | 15 of 17 (88%) | 12 of 14 (86%) | 9 | 9 | 4 of 8 | 4 of 8 | 4 | open: §23.5; C44 (MAP in a corner) |
| 05 Weaving | 34 of 42 (81%) | 32 of 40 (80%) | 8 | 8 | 1 of 8 | 1 of 8 | 2 | open: §23.5 |
| 06 Heist planner | 24 of 29 (83%) | 1 of 21 (5%) | 8 | 11 | 2 of 10 | 2 of 9 (Plan/Crew tabs 36) | 8 (rows 44) | text fixed on the Plan tab; Crew tab still 9-12 px (analysis N11); taps: screen gate |
| 07 Heist result | 27 of 36 (75%) | 0 of 29 | 8.5 | 13 | 0 of 5 | 0 of 6 | 0 | **fixed** |
| 08 Observatory | 29 of 37 (78%) | 13 of 43 (30%) | 8.5 | 10 | 5 of 14 | 3 of 13 | 3 | improved, open: §23.5 |
| 09 Scout report | 49 of 57 (86%) | 49 of 57 (86%) | 8 | 8 | 3 of 9 | 3 of 9 | 4 | unchanged, open: §23.5 |
| 10 Roster | not measured | 53 of 59 (90%) | — | 9 | — | 10 of 27 | 11 | open: §23.5; C44 (hub tabs 36) |
| 11 Character | 25 of 32 (78%) | 25 of 32 (78%) | 7.5 | 8 | 5 of 8 | 5 of 8 | 6 | unchanged, open: §23.5 |
| 12 Sage hall | 35 of 39 (90%) | 35 of 39 (90%) | 9 | 9 | 9 of 22 | 9 of 22 | 9 | unchanged, open: §23.5 |
| 13 Law collection | 65 of 74 (88%) | 56 of 64 (88%) | 7.5 | 7.5 | 16 of 30 | 17 of 31 | 18 | open: §23.5 |
| 14 Resonance Lab | 57 of 62 (92%) | 52 of 57 (91%) | 8 | 8 | 4 of 30 | 4 of 30 | 4 | open: §23.5 |
| 15 Defence curation | 26 of 35 (74%) | 19 of 31 (61%) | 7.5 | 7.5 | 4 of 10 | 4 of 10 | 6 | open: §23.5 |
| 16 Rehearsal | 22 of 27 (81%) | 22 of 27 (81%) | 8.5 | 8.5 | 2 of 7 | 2 of 7 | 3 | unchanged, open: §23.5 |
| 17 Season | 25 of 49 (51%) | 24 of 45 (53%) | 8 | 8 | 7 of 19 | 7 of 19 | 8 | open: §23.5 |
| 18 Shop | 28 of 37 (76%) | 30 of 39 (77%) | 8.5 | 8.5 | 5 of 14 | 5 of 14 | 7 | open: §23.5 |
| 19 Settings | 38 of 46 (83%) | 35 of 43 (81%) | 8.5 | 8.5 | 11 of 16 | 11 of 16 | 12 | open: §23.5 |
| 20 Profile | 35 of 45 (78%) | 35 of 45 (78%) | 8 | 8 | 37 of 38 | 37 of 38 | 38 | unchanged, open: §23.5; taps: screen gate, C44 |
| 21 First launch | 2 of 8 (25%) | 2 of 8 (25%) | 10 | 10 | 0 of 1 | 0 of 1 | 0 | title only measured; open: §23.5 |
| 22 Terrain editor | not measured | 37 of 55 (67%) | — | 7.5 | — | 0 of 16 | 1 | open: §23.5 |
| 23 Landing picker | not measured | 30 of 47 (64%) | — | 7.5 | — | 3 of 8 | 4 | open: §23.5 |
| 24 Harmony view | not measured | 32 of 37 (86%) | — | 7.5 | — | 3 of 17 | 3 | open: §23.5 |
| 25 Island Workshop | not measured | 34 of 48 (71%) | — | 8.5 | — | 2 of 12 | 10 | open: §23.5 |
| 26 Forms album | not measured | 40 of 43 (93%) | — | 8 | — | 11 of 27 | 11 | open: §23.5 |
| 27 Share sheet | not measured | 21 of 25 (84%) | — | 8.5 | — | 3 of 12 | 7 | open: §23.5 |
| 28 Friends | not measured | 34 of 52 (65%) | — | 7.5 | — | 4 of 19 | 6 | open: §23.5 |

Method note (REV:160) — "Roster ... left out; 22 to 28 were not measured": now all measured (rows above). The analysis's own probe (`design-system.md` §8.2) excluded the status bar and found 72% of 1,049 runs under 13 px; it did not count taps. Held: text by §23.5 Text size row (DOC:11515) and analysis `design-system.md:130`; taps by C44 (chrome) and the stage SD screen gate (all screens); §23.5's claim for the planner is wrong on its Crew tab (analysis N11). Nothing new here.

## Coverage table

Status words: **fixed** (the screen now follows the rule); **open, held by X**; **v3.6 changed** (the rule the bullet cites moved); **new R2-n**.

### Improvements (REV:120-131)

| # | Bullet | Now | Status |
|---|---|---|---|
| I1 | One planning funnel: the Landing picker as the only place; a planner summary bar | Planner Plan tab rows "Entry › Lantern Vale · In fog · not heard", "Route ›", "Clock", "Crew", "Sage", "Casts", "Entry fee" (SHOT 06); Entry opens the picker. But the scout report still offers "⚑ LAND AT · West ledge, in the fog" per realm (SV3:625, 1405), and its "PLAN THE HEIST · With Mo, Bramble, Hollow" sets the planner's landing (`plan:()=>{...setState({landing:i});this.nav('planner')}`, SV3:1421) and promises a crew the planner does not take (planner "5 of 5 · Pip, Mo, Bramble, Hollow, Ash") | Summary bar **fixed**. Landing chosen in two places and the crew mismatch: **new R2-1** |
| I2 | A heist HUD built on the portraits | Five portraits fire abilities, pips and lockout ring; hold on ground for gait; clock and alarm top centre; Sage, Cast, Get out in a right column at y 552-744 of 844 (MEAS) | **Fixed** (R1 item 2). Remaining gaps held by D80, G47, analysis H8/H9 (R1-3) |
| I3 | Results that teach: grade and multipliers, pick the law, moment on top, worth question, list what was kept | "Loud · Haul ×0.7 · Renown ×0.8", "3 s · The moment · 0:48" second on the page, "Study one law you crossed", "Was this worth your time?" (SHOT 07); Foiled "What you kept" list (SV3:771, 1490) | **Fixed.** Moment rule G48; worth scale C47 |
| I4 | Feed the prototype from the document | `ruleborn-data.js` module; §23.5 adopts "One data file for every screen ... the prototype's module is not a source" (DOC:11415-11416); the build reads `content/*.json` extracted from the document | **Fixed / covered** (§23.5 adopted row; content/) |
| I5 | One player, one age band: adult default, a 13-15 switch changing every protection | Tweak `ageBand` default "18+" (SV3:841). Profile hides Share at 13-15 (META:1480); Settings locks (META:1545-1569). Share sheet still shows "You're 13–15, so clips stay inside the game" to the adult (SHOT 27); cap computed, not drawn | Adopted. Open: Share held by §23.5 Share sheet row (DOC:11460); cap D85, D87; band preview D87 |
| I6 | Bigger text and targets (13 pt, 16 pt body, 48-pt heist targets) | See the size table | Heist, result fixed; rest **open, held by** §23.5 Text size, C44, screen gate; "16 pt" against "16 pixels" unit held by C49 |
| I7 | One set of school shapes (5.2) everywhere | Screens use §5.2's set (`RBIcons.school`, analysis `design-system.md:161`). Colour-blind panel: Life a gem, Spirit an oval, Matter a hexagon. Law icons in ICONS frame each school in a non-§5.2 shape: Spirit a teardrop (flame), Matter a hexagon, Motion a plain circle (ICONS:183-188) | Panel **open, held by** §23.5 Colour-blind row (DOC:11530), D87, D91. Law-icon frames: **new R2-3** |
| I8 | Words for systems that exist: steal, stolen, revenge, rating, XP, power, builders | "steal", "stolen", "STOLEN": none (grep SV3, META). "REVENGE" only in dead code (SV3:1354). "RATING" (META:342), "588 / 600 XP" and "+539 power" (META:910-916), Roster TRY note "when XP is full" (META:890), builders cap in code (SV3:975, 988) | Mostly **fixed**. Open: rating §23.5 Profile header; XP and power §23.5 Character screen; builders D73; notes §23.5 "designs' own notes" row; title "Quiet Thief" D85 |

### Screen by screen (REV:162-340)

| Screen | Bullet | Now | Status |
|---|---|---|---|
| 01 | Raid toast takes Essence, offers Revenge | "Marta raided Verdant · you lost nothing / Your defence kept 1,240 Essence safe", TRACE (SHOT 01) | **Fixed** |
| 01 | "Skyfield strained" and faults vs Humming 82% | Home "82% · Humming", no fault badges; realm view "Steady · 62%" (SHOT 04) | Faults **fixed**; split **open, §23.5 Realm view strain** (DOC:11445) |
| 01 | Six outer realms at 24; Aether 38.2k | Sixth "Opens at Keeper 28"; "31.4k" | Realms **fixed**; Aether **open, §23.5 Aether storage** |
| 01 | Toast on top of Collect; §21.8's home layout | Raid banner `bottom:'124px'`, full width, z-index 5 (SV3:1015) over COLLECT at `bottom:118px`, 38 tall (SV3:322) | Layout **open, held by C44**. The overlap itself: **new R2-4** |
| 02 | Twelve targets; gait row | 8 controls, all ≥ 56 pt (MEAS); gait by hold (SV3:1321) | **Fixed** |
| 02 | Leap, Wade, Shield, Return; Rewind | Stuff the satchel, Unslowed, Root, Stand over, Burst (MEAS aria labels) | **Fixed** in the HUD; scout matchups still name them: R1-1 |
| 02 | Hearts and stamina | Health bars, 10 s down and revive | **Fixed**; numbers §23.5 Role health; Sturdy "+1 heart" trait text (META:887) in analysis `screens-roster...md:154` |
| 02 | Three-star objectives; "Out before 1:00" | Outcomes Clean/Loud/Partial/Foiled; stars only in an unrendered pass (SV3:1293) | **Fixed** |
| 02 | Missing clock/alarm top centre, cones and meters, pips and lockout, crack ring, load target | All drawn; load target fixed at 80% | **Fixed**; load target G47, analysis H17 |
| 02 | Labels 21 pt tall; Sage and Get out in the bottom corners | Portraits 56 pt; Get out spans y 686-744, 100 pt above the bottom edge (MEAS) | **Fixed** |
| 03 | Stillness III 24 / 960 | "24 pts", "960 Aether" (SHOT 03) | **Fixed** |
| 03 | Missing Hush, looping preview; pause sign | "COMMON · TIME · HUSH"; no preview, pause art | Note **fixed**; preview and art **open, §23.5 Law card** (DOC:11495) |
| 03 | "Oak frame 10/20", "STAB", 6.5 pt | Gone (grep); "STABILITY" (SV3:802, 809); smallest 9 | **Fixed**; size §23.5 |
| 04 | "Laws 2/3" | "LAWS 1/2" | **Fixed**; third locked slot D75 |
| 04 | "Builders 2/2" | Not drawn; cap and timers in code (SV3:975, 988) | **Open, D73** |
| 04 | Workers, pylons, wards, posts alike | Unchanged | **Open, §23.5 Realm view**; no pylon D74 |
| 05 | Third Heart slot, no crown slots | One crown slot "Kinship · Crown · every realm" (SV3:1216); `slots:[0,1,2]` (SV3:1180) | **Open, §23.5 Crown slots** and D75 |
| 05 | "+15% → Steady" | "+3% = 85% → HUMMING" | **Fixed** |
| 05 | Deck prices off 40/pt | Half gravity 760 at tier III, Glowing dark 440 = 11 pts (13 × 0.85 harmony with Stillness, §5.5 DOC:845) | **Fixed**; partner not re-priced D81 |
| 05 | Non-launch laws; Inward pull Uncommon | Deck: Glowing dark, Delay, Bloom, Slow rivers, Bounce, Half gravity, Glass, Frictionless | **Fixed** |
| 05 | No recommended laws | None | **Open, §23.5 Weaving** (DOC:11500); TD.20 |
| 05 | Right: Glowing dark 440 / 10 min | "440 Aether · 11 pts · ready in 10 min" | Still right |
| 06 | Six landing realms | Entry row → picker with three realms | **Fixed**; one spot per realm D78 |
| 06 | Crew 4/4 | "Crew 5/5"; toggle stops at 4 (analysis :372) | Label **fixed**; toggle **open, D78** |
| 06 | Route, Sage, casts, fee, flags; landing is an edge tile | All rows drawn (SHOT 06) | **Fixed**; fee answers C45; edge tile D78 |
| 07 | Stars graded on loot; Loud | "Loud · Haul ×0.7 · Renown ×0.8 · 2 / 6 alarm" | **Fixed** |
| 07 | Rest 12-18 min, Hollow ready | "Every crew member rests 60 min" | **Fixed**; "Idle crew of 5 ready" D80 |
| 07 | Study chosen; +3 everywhere | "+2 pages" Loud, three chips to pick | **Fixed** |
| 07 | Caught "−672 lost", Renown −6 | Foiled "Renown −8 · nothing else is lost", fee "paid to Marta" | **Fixed**; "nothing else is lost" D80 |
| 07 | Missing worth question | "Was this worth your time? Yes / Not really" | **Fixed**; scale C47 |
| 07 | Fail flag never read | Read: `rsWin=!(...||st.heistFail)`, `if(st.heistFail)oc='Foiled'` (SV3:1448, 1473) | **Fixed** (a successful run still shows the Tweaks outcome, prototype-only) |
| 08 | Guards and laws before a paid scout | "Laws, guards and wards show after a scout" | **Fixed** against §12.4; F46 answer C45, R1-5 |
| 08 | Levels 4-7 | 23, 25, 22; "Keepers 21–27" | **Fixed**; F44 answer C45 |
| 08 | Reroll 400 Starlight; Revenge | "50" Aether doubling; "TRACE · 24 H" | **Fixed**; Trace fee §23.5 Trace target |
| 08 | Sky ruin pays Starlight; echoes mark | "Drifting ruins · Pages, Essence, no Renown"; "ECHO" ribbon | **Fixed**; one difficulty per ruin D78 |
| 08 | No depth or reason; "+20% bonus", stars | "Depth · 1 realm to the Heart", "Why · Trace ..."; bonus only in dead code (SV3:1351) | **Fixed** |
| 09 | "Land here" on the Heart | Panel "No skiffs: strong winds ring the Heart"; 3D still flags it | **Open, §23.5 Scout report** (DOC:11485) |
| 09 | Keep 3D free of positions | Threats tab draws guard discs and ward pins (analysis N2) | **Open, D77** |
| 09 | Crew names differ from next screens | "With Mo, Bramble, Hollow" (SV3:1414) vs planner five | **new R2-1** (part) |
| 09 | Law cards behind tabs; lead with them | Laws still chips on the second tab, "2 Threats" (analysis :222, :267) | **new R2-2** |
| 10 | XP bar; level 6 for 1,250 | "Lv 6 costs 866 Essence", "Level up 866 Essence" | **Fixed**; TRY note "when XP is full" §23.5 notes row |
| 10 | "Power 1,705"; show role stats | "♥ 200" (health, drawn from `ro.hero.power`, META:861) | Score **fixed**; 200 vs 160 §23.5 Role health; stats D82 |
| 11 | "Once a heist" | Label "ONCE A HEIST" over "Two uses a heist, 10 s apart" | **Open, §23.5 Character screen** |
| 11 | Skyskipper resists no-jump zones | "RESISTS No-jump zones" | **Open, §23.5 Character screen** |
| 11 | XP and power; interactions | "588 / 600 XP", "+539 power"; TRY "Coming in a later turn" | **Open, §23.5 Character screen** and notes row |
| 12 | Level 4 of 10, levels with heists | "Level 4 / 40 · levels with Insight" | **Fixed**; Insight price G52, D82 |
| 12 | Archivist powers match 11.7 | Suspend 1 use 10 s, Reveal, Recall (META:950; DOC:6199) | Still right |
| 13 | Five ranks | DEEP, RARE ×3, UNCOMMON (SHOT 13) | **Fixed** |
| 13 | Eight costs | 14, 22, 10, 18, 16, 14, 15, 18 | **Fixed** |
| 13 | Pages x/10 | 18/60, 5/10, 14/35, 11/35, 18/35, 2/10, 12/20, 6/20 | **Fixed** |
| 13 | Chapters are schools | "Motion · CHAPTER I · 3 of 4 restored · album 2 paid" | **Open, §23.5 Codex** (DOC:11510); TD.44; G49 |
| 13 | Motion "Complete"; Frictionless 9/10 woven | "3 of 4 restored"; Frictionless "I · In Emberreach" | **Fixed** |
| 14 | Per-resonance settle times | One time: "Lab level 3 runs each test in 5 h 30 min" (META:1112) | Per-pair **fixed**; 5 h 30 **open, §23.5 Resonance Lab**; the time as a clue G53 |
| 14 | "Recipe unique to you" | Gone (grep) | **Fixed**; but ten of twelve resonances are not §8.4's: D83 |
| 14 | Missing paradox warning and 3 pages | "Unstable pairing ... A 10% chance of a paradox."; "No resonance. You get 3 pages ..." (META:1112; DOC:2181, 2221) | **Fixed** |
| 15 | Best screen: gauge, routes, alternatives | Unchanged ("HOLDS 38% · In the fair band · 30–45%") | Still drawn; hold figure G55; all cones D83 |
| 15 | Points A-D read as landing spots | "⇢ Sky ⇢ Tide ⇢ Rift ⇢ Rope" | Arrows **fixed**; labels **open, §23.5 Heart arrivals** (DOC:11550) |
| 15 | "STOLEN" tags | "✦ REACHED THE VAULT" | **Fixed** |
| 15 | Change one law with preview; word-list names | Laws mode with SWAP (META:1189); "Names are built from word lists." (META:1182) | **Fixed (designed)**; swap rule G54; preview speed TD.16/TD.22 |
| 16 | Defence log does not open | Opens a report (R1 B1) | **Fixed** |
| 16 | Flat 2D map the only non-3D island | Rehearse replay still an SVG ellipse (META:233; SHOT 16); the report uses the 3D view (META:247) | **new R2-5** |
| 17 | "+5 tiers" for €5.99; free lane holds pages and Essence | "+5 tiers" gone; free lane still pays pages, Essence, a stray | Purchase **fixed**. Free lane: **v3.6 changed** — §18.8 keeps it (DOC:9124-9125; answer G28 B) |
| 17 | "Legendary · this season only" | "Legendary · claimable in any later season" | **Fixed** |
| 17 | 30 tiers; star chests "no limit"; odds | "STARPASS · TIER 30" (META:269); "One every 500 ★ · up to 10 a season" (META:276) | 30 tiers **open, §23.5 Season track**; chests capped but not in §18: **D84** (not built until written) |
| 18 | Daily picks in Starlight | "120 ≈€1.20" Starglass | **Fixed** to the review; but F41's answer removed the currency: **F57, C45** (R1-5) |
| 18 | Struck-through €10.40 | `was: ''` (META:1427); no struck price drawn | **Fixed** |
| 18 | No cap shown for 13-15 | "ASK TO BUY" to every band | **Open, D85, D87** |
| 18 | Right: euro figure, "no rush" | "≈€1.20", "Back again later, no rush" | Still right (prices F57) |
| 19 | Reminder and quiet hours switchable at 13-15 | Locked (`ptLock`, `qhLock`, META:1545-1569), drawn like open choices | Lock **fixed**; drawing **open, §23.5 Locked protections**; Account highlight §23.5; preview D87 |
| 19 | Colour-blind shapes | Life a gem, Spirit an oval (analysis `design-system.md:163`) | **Open, §23.5 Colour-blind panel, D87, D91** |
| 19 | Ask to Buy, no €25 cap | Unchanged | **Open, D85, D87** |
| 19 | Access tab thorough | Text size, left-handed, reduced motion, captions drawn; reduced motion read by nothing; no hold time, no moving controls | Not as good as the review says: **held by D91, D87** |
| 20 | "Rating 1,460" | "TIDE II 1,460 RATING" (META:342) | **Open, §23.5 Profile header** |
| 20 | Own ending categories | Clean 23%, Loud 48%, Partial 21%, Foiled 8% | **Fixed** (donut labels D85) |
| 20 | "Laws stolen"; 16-day streak | "Pages studied"; "6-week best streak, 4 days in 7" | **Fixed** |
| 20 | Share at 13-15; 37 of 38 taps; not in 23.2 | Share hidden at 13-15 (META:1480); 37 of 38 under 44 (MEAS); §23.2 row added (DOC:11315-11317) | Share **fixed**; taps **open**, screen gate; 23.2 **v3.6 changed**; held/leaked G69 |
| 21 | Only a title; age check and session | Full flow designed (META:440-475) | **Fixed (designed)**; D87, C51, G58, TD.26 |
| 21 | "Find them. Steal them." | "Your islands. Your rules. Their treasure." (§1.1, DOC:187) | **Fixed** |
| 22 | Families, budget, route check, sight toggle | All present | Still right; feature texts D83, moss D83 |
| 22 | "74 / 80" | "94 left of 100 points" (40 + 10 × Spire 6, §6.1) | **Fixed** |
| 22 | A-D markers, STOLEN | "⇢ Sky/Tide/Rift/Rope", "✦ REACHED THE VAULT" | STOLEN **fixed**; labels §23.5 Heart arrivals |
| 23 | Clocks 140-210 | 165, 165, 180 s | **Fixed** |
| 23 | Noise as percentages | Skyfield "+50%", "50% NOISE" | **Open, §23.5 Landing noise** |
| 23 | Six realms for four | Three cards for Marta's three outer realms | **Fixed** |
| 23 | Comparison and way-home good; the only landing screen | Kept; scout report still chooses the landing | Good pattern kept; "only landing screen": **R2-1** |
| 24 | Chord built from non-launch laws | Deep sleep: Slow rivers, Delay, Kinship · crown | **Fixed** |
| 24 | "−10%" without the 192 draw | "While it sounds, the chord draws 192 stability." | **Fixed** |
| 24 | Three laws in Tidehold need level 5 | Tidehold 4 holds two realm laws plus a crown law (2 slots at level 4, DOC:730-760) | **Fixed**; Tidehold at level 4 under Spire 6 D75 |
| 25 | "62% · fair · band for Lv 6" | "Fair budget · 62% · Lv 6 band" (META:1786) beside "38% held · fair" | **Open, §23.5 Workshop checklist** |
| 25 | Ladder, word-list names, clear-before-publish | Present | Still right; human review D83 |
| 26 | 54 forms; mark trades as 1.1 | "FORMS 28 / 54"; no trades anywhere on the screen | Forms right; trades: **held by C49** (§23.2 vs §11.10); owner's line supports C49's fix, **R2-6** |
| 27 | Age gating right | Shows the 13-15 message to the default adult (SHOT 27) | Regressed: **open, §23.5 Share sheet** |
| 28 | Friendly heists right | "Tomas raided your Heart · Your guards caught 2 of his crew. +2 pages earned" | Still right; presence D86 |
| 28 | Swift trait from Haste | "It was born swift, a body trait." (META:1903) | **Fixed** |

### What already works (REV:342-351)

| # | Claim | Now | Status |
|---|---|---|---|
| W1 | Art direction consistent; dioramas legible | Unchanged | Still so; the visual language waits on D89, D92, D90 |
| W2 | Characters tab right; 393 icons on the 24-point grid | §23.5 confirms the kinds (DOC:11570); 27 of 48 law icons are on a 48-unit grid in another style (analysis `design-system.md:242`) | Kinds right; icon finish D91; law-icon frames R2-3 |
| W3 | Defence curation strongest | Unchanged | Still drawn; G54, G55, D83 |
| W4 | Share and Friends apply age bands and friendly-heist rules | Share regressed (§23.5 Share sheet); friendly heists right; presence D86 | Partly stale (REV's claim), held |
| W5 | Settings Access complete | Reduced motion read by nothing; colour-blind palettes worse for two forms; no hold time | Held by D91, D87, analysis DS-4 |
| W6 | Caught result names the moment and one thing to try | Kept on Foiled | Still right; rule for choosing G48 |
| W7 | Weaving shows cost, strain, time; Glowing dark 440 / 10 min | Kept | Still right; bands and harmonies not drawn D81 |
| W8 | Workshop ladder and checks follow 18.6, 18.7 | Kept | Still right; checklist §23.5, human review D83 |

### Fixes for the design document (REV:353-358)

| # | Item | What v3.6 did | Status |
|---|---|---|---|
| F1 | 18.2 vs 18.8: one sentence has to go | §18.8 rewritten: "Cosmetic only on the premium track ... The free track's pages, Essence and stray (18.2) are small and stay claimable in a later season ... this row once said both tracks were cosmetic, which contradicted it" (DOC:9124-9125); change note DOC:85 | **Done in v3.6** (answer G28 B). Left over: "nothing in a season changes a heist" vs the free track's grants, and §9.1's sources: **C49**; numbers **G28** |
| F2 | Profile and stats not in 23.2 | New §23.2 row, "Renown and league over time, never the internal rating (12.15) ... Private, with no sharing, for 13 to 15" (DOC:11315-11317); §23.5 adopted row (DOC:11400-11401) | **Done.** Undefined "held and leaked", records, badges: **G69**, TD.24, TD.55 |
| F3 | Design notes differ from 23.2; quote 23.2 | §23.5: "23.2 is the must-show list. The designs' own notes are not." (DOC:11393) and the row "Their must-show lists ... 23.2 is the must-show list" (DOC:11565-11567). The notes still differ: Weaving (SHOT 05 "One big law card ..."), Lab ("settle time as the clue"), Curation, Rehearsal, Season ("daily/weekly/era quests that fill the pass"), Settings (no locks), Profile ("League and rating trend"), Workshop, Share, Friends | **Done in v3.6** as a rule; the design file is not edited: **held by §23.5 notes row** |

## Findings

### R2-1 (spec, medium). The scout report still chooses the landing and names a crew the planner ignores

REV:124 (owner's improvement): "Landing is chosen in three places today: the Scout report's 'Land here', the Planner's landing cards and the Landing picker. Keep the Landing picker as the only place". REV:226: "Crew reads Mo, Bramble, Facet here and Pip, Mo, Bramble, Hollow on the next screens." REV:316: "make this the only landing screen".

Now the planner sends Entry to the picker, but the scout report keeps a per-realm "⚑ LAND AT · West ledge, in the fog" (SV3:625, `landTxt`, SV3:1405), and its "PLAN THE HEIST" button sets the landing before opening the planner: `plan:()=>{const i=LANDINGS.findIndex(l=>l.key===sr.key);if(i>=0)this.setState({landing:i});this.nav('planner');}` (SV3:1421). Its subline promises a crew: `pg.crewTxt='With '+pg.picks.map(c=>c.name).join(', ')` gives "With Mo, Bramble, Hollow" (SV3:1414, 664; SHOT 09), while the planner opens with "5 of 5 · Pip, Mo, Bramble, Hollow, Ash" (SHOT 06). The crew names are still inconsistent from one screen to the next, as REV said.

The analysis adopts both ("'Plan the heist' with a suggested crew", `screens-observatory-scout-landing-planner.md:245`) and plans "'Plan the heist' → planner, landing realm preset when the page is an outer realm" (:270) and a Land tab with "the landing the player picked, or 'Choose a landing'" (:266). TD.18 says only "the planner starts from the landing picker (TD.41)". No register item holds it. v3.6 is silent (§23.2's Scout report row asks for law cards, guards, wards and matchups, DOC:11239-11241), so the owner's intent decides the flow.

Proposed: roadmap-amend TD.18: "The landing is chosen only in the landing picker (TD.41), opened from the planner's Entry row. The scout report shows each realm's hearing and clock facts but sets no landing; its Plan button opens the planner unchanged. Any crew the scout report suggests is the crew the planner opens with, or it is not shown. A presenter test: the planner's crew and entry after Plan equal what the scout report said."

### R2-2 (spec, low). The scout report's law cards sit behind the second tab; the owner asked to lead with them

REV:227: "The screen's job is to read their laws, yet the law cards sit behind tabs. Lead with them." Now: tabs "1 Land · 2 Threats · 3 Crew"; the laws are chips on Threats (analysis :222 "'LAWS' chips with a '!' on laws not yet met"). The analysis keeps the order and puts law cards on Threats (:267) and lists "the three tabs" as a silent adoption (:245). §23.2's row puts "Realm-by-realm law cards" first (DOC:11241); §23.2 names the job "Read their laws." TD.18 does not order the screen.

Proposed: roadmap-amend TD.18: "Each realm page opens on its law cards (with known and new tags and the looping preview); guards, wards and matchups follow. Landing facts sit on the landing picker (R2-1)."

### R2-3 (missed, medium). Law icons frame their school in shapes that are not §5.2's

REV:130: "Use 5.2's shapes everywhere ... The Icons sheet draws Motion as a star and Spirit as a flame". The screens' school marks now use §5.2's set (analysis `design-system.md:161`). But the law icons in ICONS put each law in a school-coloured frame whose shape is the school's own and is not §5.2's: `law()` (ICONS:183-188) frames Matter in a hexagon (`FR.hex`), Time in a ticked disc, Energy in a burst, Life in a scalloped badge, Spirit in a teardrop (`LPATH.tear`, ICONS:178: the flame REV names), and Motion in the default plain disc, which is the Neutral Heart's circle. All 48 law icons in `GROUPS.laws` (ICONS:222 onward) use it, and the Lab and curation draw them (`I('laws', ...)`, META:1076, 1189).

§5.2 gives one shape per school: Circle (Neutral), Chevron, Cube, Hourglass, Bolt, Leaf, Eye (DOC:663-701). §20.8: "School colours always paired with shapes" (DOC:10243). §21.8 Icons: "the school shape where relevant" (DOC:11007). §21.8 Law card: "the school shape and colour at the top" (DOC:10980). A Motion law framed by the Heart's circle and a Spirit law by a flame pair the colour with the wrong shape, which §20.8's colour-blind reading depends on.

Not held: analysis `design-system.md` §4.4 lists three shape sets and not this one; D91's icon row is about finish; §23.5's Colour-blind row covers only the Life gem.

Proposed: register-amend D91 (icons row): "Law icons — each school's law frame is its own shape: Matter a hexagon, Time a ticked disc, Energy a burst, Life a scalloped badge, Spirit a teardrop, Motion a plain disc (ruleborn-icons.js:178-188) — the school's §5.2 shape, or no frame and the shape mark beside it — §5.2, §20.8, §21.8". Roadmap-amend TD.5: "the law icons are exported with §5.2's school shape as the frame (or a plain frame plus the shape mark); a check that every school-coloured icon carries its §5.2 shape".

### R2-4 (missed, low). Home's raid banner covers the Collect button

REV:168: "The toast sits on top of Collect." It still does: the raid banner is `position:'absolute',left:'10px',right:'10px',bottom:'124px'`, z-index 5 (SV3:1015); COLLECT is `bottom:118px; height:38px`, centred (SV3:322), so the banner's lower edge sits 6 pt inside the button and covers it while shown. C44 holds the home layout question, not this overlap; the analysis lists the banner (`screens-home-realm-shell.md:42`) without the overlap.

Proposed: roadmap-amend TD.6 (or TD.19): "Banners and toasts never cover a live control; the overlay places them above the HUD's controls, and a layout test fails any control whose centre a banner covers."

### R2-5 (spec, low). The rehearsal replays on a flat 2D map

REV:271: "The flat 2D map is the only non-3D island in the set." Still so: the Rehearse tab draws an SVG ellipse (`<svg width="366" height="292" ...><ellipse ... fill="#6FAE5B">`, META:233; SHOT 16), while the defence report on the next tab uses the 3D realm view (META:247). The analysis describes it (`screens-lab-curation-rehearsal-terrain-workshop.md:250`) without a verdict. TD.43 says a rehearsal "replays its route" and does not say on what.

Proposed: roadmap-amend TD.43: "The rehearsal replays on the realm's own view, the flat RealmView until TD.42's 3D world lands and the same 3D world after, never a separate schematic map."

### R2-6 (intent, low). The owner's review asks to mark trades as version 1.1, which is C49's drafted fix

REV:331: "54 forms and the outfit per completed kind match 11.10. Mark trades as arriving in version 1.1." C49's first row drafts the same edit: "write 'trades (from 1.1)', as D48 did for the Friends row" (register C49; §23.2 DOC:11305 against §11.10 "Trading: from version 1.1"). The screen shows no trades at all. This is the owner's statement of intent, not a recorded answer, and C49's forms row is one of the seven one-line edits Claude drafts, so it settles nothing new; it supports the draft.

Proposed: brief-context C49: note that the owner's own fix brief (handoff `docs/ruleborn-screen-review.md`, Forms album) asks for trades to be marked as arriving in 1.1, which agrees with C49's drafted §23.2 edit.

## Not new (checked and already held)

Ids used: §23.5 rows (DOC:11425-11567), C44, C45, C47, C49, D73, D74, D75, D77, D78, D79, D80, D81, D82, D83, D84, D85, D86, D87, D89, D90, D91, D92, F57, G28, G47, G48, G49, G52, G53, G54, G55, G69; analysis N2, N11, H8, H9, H17, DS-4; roadmap TD.5, TD.6, TD.16, TD.18, TD.19, TD.20, TD.22, TD.24, TD.26, TD.43, TD.44, TD.55 and the stage SD screen gate; sibling findings R1-1, R1-3, R1-5.
