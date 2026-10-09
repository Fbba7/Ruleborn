# The design handoff against the plan

This reading compared your design handoff (`design_handoff_ruleborn`) with what the repository held at commit 6cc1d1e: v3.6, the audit register, the decision brief and the roadmap. Six readers each read one part of the handoff. A verifier then tried to refute every finding. This page gives the results that held up.

What held up was then folded in. The findings went into the register's v3.6 layer (`tools/audit_register.py`). Your statements went into the decision brief (`docs/decisions/brief.json`) as context on open entries, and the new questions as new entries. The build guidance went into the roadmap's stage SD (`tools/roadmap.py`). The earlier reading's reports in the folder above were corrected where this reading found them wrong (listed in [its README](../README.md)). No recorded answer was changed.

Short labels used below: **v3.6** is `docs/design/ruleborn-game-design-v3.6.txt`. **README**, **SCREENS** and **CHARACTERS** are your handoff's own `README.md`, `SCREENS.md` and `CHARACTERS.md`, and **REV** is its `docs/ruleborn-screen-review.md`. All four are copied unchanged to [`source/`](source/), so README:20 is line 20 of `source/README.md`. **SV3** is the handoff's `prototype/Ruleborn Screens v3.dc.html`. The prototype is not kept in the repository; its files are cited by their names in the handoff's `prototype/`, and [the line map](../README.md#sources-and-line-map) turns them into the artifact's names that the earlier reports use. Line citations into the register (AR), the brief and the roadmap (RM) are to commit 6cc1d1e, before this reading was folded in.

## The reports

| File | Part |
| --- | --- |
| [`intent.md`](intent.md) | `source/README.md` and `source/SCREENS.md`: your intent and the implementation spec; SCREENS.md's must-show lists against §23.2 |
| [`review-1.md`](review-1.md) | REV lines 11-118: "Fix first", "Numbers that disagree", "Not designed yet" |
| [`review-2.md`](review-2.md) | REV lines 120-358: improvements, text and tap sizes (all 28 screens measured), screen by screen, what works, fixes for the document |
| [`review-3.md`](review-3.md) | REV lines 361-451, "What to change", and the README's open items |
| [`assets.md`](assets.md) | `source/CHARACTERS.md`, the six baked meshes and the six world images the earlier reading never saw |
| [`diff.md`](diff.md) | Whether the handoff's prototype is the artifact the earlier reading analysed |
| [`data/`](data/) | Measurements the reports rely on: `screen-sizes.json` and `screen-sizes.txt` (text and tap sizes of all 28 screens), `bins.jsonl` (the six meshes decoded), `deps.txt` (the screen index's 223 dependencies), `prototype.md5` (hashes of the handoff's prototype files) |

---

## 1. Have we fully analysed the design and adapted the plan to it?

**Almost. The screens were fully analysed. Your four written documents and the six model files were not, until this reading.**

### What the earlier reading covered
- **All 28 screens**, from the artifact you published. This reading proved that artifact is the same as the handoff's prototype:
  - 229 of the handoff's 244 prototype files are byte-identical to it.
  - `RulebornMeta.dc.html` (screens 10 to 27) and the data module are identical.
  - The main screens file differs in one line only: a notes row for Friends that shows beside the phone frame, not in it (DIFF-1).
- From that reading came:
  - the v3.6 layer of the register, D73 to G69;
  - the open brief entries for the look (D89 to D93);
  - roadmap stage SD (TD.1 to TD.66);
  - the analysis in `docs/analysis/screens-v3/`.
- Its screenshots (`scratch/shots/all/`, not kept) still show the current screens.

### What it could not see
- **`README.md`, `SCREENS.md` and `CHARACTERS.md`**: your build instructions and your statements of intent.
- **`docs/ruleborn-screen-review.md`**: the fix brief you gave the design tool.
- **The six baked meshes** (`*.bin`, 21.1 MB).
- **Six top-level world renders**: heist, home, landing, realm, result and workshop.

### What this reading found
These counts are after merging duplicates across the six readers.

| Kind | Count | The ones that matter most |
|---|---|---|
| Your statements that bear on open decisions | 14 | "Final" UI (D89 to D91, C44); no zoom buttons and a "final" camera (D75); presence and pings (D86); no outline and lambert shading (D92); keep the Archivist card (G48); Loud read off the alarm ladder (C47); the crack ring (C45 and F35) |
| Places where your handoff and v3.6 disagree, with no item to decide them | 3 | **Landscape** (README: "not supported"; §23.3: every screen; §24 and §27.5: heists only); the **390-point frame** you ask to scale, against the build's 360-point reflow; **note colours** (two palettes, and neither is §8.1's wheel) |
| Screen problems the register missed | 4 | The scout report names abilities that were cut and a law that does not ship (R1-1); 21 law icons are framed in shapes that are not their school's (R2-3); first launch has the player catch the page, not the Archivist (R3-15); home's raid banner covers Collect (R2-4) |
| Build guidance missing from the roadmap's tasks | about 20 | The heist screen's gate (TD.17); the scout report funnel (TD.18); the defence report (TD.66); sound and haptics (no task at all); the persistent 3D world (TD.6); the character export: clip names, expressions, which images to keep (TD.7) |
| Register, roadmap or analysis text that is now out of date | 8 | G61 ("no model file exists"); TD.32 ("Verdant has no bees"); the analysis adopting the crack ring; citations that point to file names only the artifact had (DIFF-2) |

### What was folded in
1. **Four new decisions for you, in the brief:**
   - landscape at launch (C55);
   - the 390-point frame (D98);
   - D75's camera and gestures, now that you have called them final;
   - which raids open a Trace (G70).
2. **Context on open brief entries** (D89, D90, D91, C44, C45, F57, D86, D92, G48 and C47). Each records what your handoff says. None of them is answered by it.
3. **The register, the roadmap and the analysis:**
   - new register items: C55 landscape, D97 note colours, D98 the 390-point frame, G70 the word "robbed";
   - two more found folding the plan in, each v3.6 against itself and each a brief entry: C56, the second epoch's slot (§14.9 against §18.4), and C57, one guard's cone or every one (§21.12 against §12.6);
   - amendments to register items the handoff bears on;
   - amendments to stage SD's tasks, and two new tasks: TD.67 sound and haptics, and TD.68, your answer on landscape;
   - corrections to the earlier reading's reports.
4. **Changed when folded in.** The reports above are kept as written. These of their proposals were corrected or dropped:
   - review-1.md:106 adds "Wade" to D78's matchup row. Dropped: §11.2's Tidewalker wades, so the word is consistent.
   - review-1.md:124 has TD.28 stand unless you rewrite §23.3. It became a decision, C55, since v3.6 says it both ways.
   - intent.md:63 says the two palettes "swap Weight and Hush". They disagree on Weight, Hush and Veil (D97).
   - intent.md:137 cites "five crew states (§11.3)". The states are §11.6's.
   - review-3.md:23 and :175 say the design offers a Trace after every raid. It offers none after the two raids where no loot got out; its "HELD" raid with a Trace is a Partial (G70).
5. **Nothing in the handoff reverses a recorded answer.** It restates v3.5's rules in several places: the paid scout, the 3-level window, the fee as 2% of Starlight, Starglass and the crack ring. C45 already asks you which source wins. The handoff is a further reason to answer it.

With these changes in, the handoff has been read in full against the plan. One limit remains: the 3D world could not be run here, because the network blocks the CDN. The 3D findings come from source and from the existing screenshots.

---

## 2. Your statements that bear on open decisions

Each statement is context for the decision beside it. None is recorded as an answer. Where §23.5 says the document wins (rules, numbers, text), it still wins.

| Your statement (handoff) | Entry | What it means for the decision |
|---|---|---|
| "Colours, type, spacing, copy, numbers and interactions are final. Recreate the UI pixel-accurately" (README:20) | D89, D90, D91, C44, C45 | It agrees with §23.5 on the look. It conflicts with §23.5 on copy and numbers, where v3.6 says the document wins (v3.6:11387) |
| "scale it to the device" at 390 × 844 (README:20) | C44, new D98 | Scaling down to a 360-point phone draws 13-pt text at 12 pt and 48-pt controls at 44. TD.2 reflows on 360 instead (DS-10) |
| "landscape is not supported" (README:20) | new C55 | v3.6 disagrees with itself here. §23.3 and §27.2 put landscape on every screen; §24 and §27.5 put it in heists only. TD.28 builds every screen |
| "pinch to zoom and twist to rotate; there are no zoom buttons" and the 3D camera is "final" (README:178, :22) | D75 | §20.8 says no action needs two fingers. §21.1 sets an orthographic camera at 35°, turning in 90° steps. A brief entry was added for it |
| Friends' presence is server data to build; "Who's online", "preset pings" and "post the clip to the Beacon" (README:168; SCREENS:166, :171) | D86 | This is your clearest statement for option C. D86 recommends A, and §23.5 adds nothing until §17.6 is written |
| "match the toon look. Use soft lambert shading with a rim light, no black outline (it was removed at the user's request)" (CHARACTERS:99) | D92 | It asks for the toon look and no line on the characters, and names lambert shading, which the design uses nowhere. None of A, B or C drops the characters' line. D92's option D is the toon ramp with no outline on the characters; smooth shading would be a further reading |
| Lilita One for "numbers, buttons, names, card titles"; Marcellus "on some screens" (README:121-122) | D90 | The prototype sets names and many titles in Marcellus, so D90's body is accurate. Option B's move of changing numbers to Manrope stays |
| Screen changes take "about 0.3 s"; the camera dive takes about 1.2 s and eases out (README:148-149) | D91 | Both are slower than §21.8's 150 to 250 ms, and slower than the prototype's own 160 to 240 ms. Whether §21.8 covers camera moves is unwritten |
| "Keep the Archivist card." (REV:398) | G48 | Supports option B. The recommendation is A ("Try this") |
| "A getaway at 2 of 6 alarm is Loud"; the worth question is cited to §20.3 (REV:394, :400) | C47 | Favours B's outcome rule: Clean and Loud read off the alarm ladder. §20.3 asks the worth question once a session |
| The 5 m crack ring "guards inside it hear" (REV:388), drawn in the screens | C45 (F35 answered D) | Your answer F35 = D removed the ring, and the build follows that answer. The brief restates §12.6; it does not reverse F35 |
| Paid scout, a 3-level window, a fee of 2% of Starlight, Starglass prices (REV:30, :42, :113, :417) | C45, F57 | These restate v3.5's text. The review is undated against your answers of 25 and 26 September. No reversal is recorded |
| "the GDD wins" (v3.4), and ruleborn-data.js is "the single data source" (README:17) | C45 | Same direction as §23.5. But it names v3.4, which predates your answers, and the module that §23.5 rules out |
| "No countdowns or 'last chance' banners." (REV:423); "season time remaining" (README:168) | TD.23 (no decision) | §18.8 allows either. The proposal is to show the end date, never a count of days |

These statements need no decision:
- "Raider names stay hidden while a raid is happening" (REV:437) bears on D83's refusal of a live banner.
- "Mark trades as arriving in version 1.1" (REV:331) agrees with C49's drafted edit.
- "an easier version … against the same target" (REV:401) is met by D79's reading, so D79 stands.

---

## 3. The fix brief, item by item

Key: **Fixed** means fixed in the current screens. **Open** means still open, held by the id given. **v3.6** means v3.6 changed the rule. **New** means found in this reading.

### Part 1: the review

| Item | Status |
|---|---|
| Fix 1: theft reads as two-way | **Fixed.** The Foiled fee wording is open (D80). The REVENGE tag is dead code at SV3:1354; do not port it |
| Fix 2: the heist HUD | **Fixed:** 8 controls, §11.2's abilities, health bars, hold for gait. **Open:** role health (§23.5 row), pip number and Burst (D80), live portraits under the wheels (G47), drag to aim and hold Get out (D80 amend, R1-3). The stamina and hearts hint at SV3:1293 is dead: :1321 overrides it. Three-star objectives are built but never drawn. Cut abilities remain on the scout report: **New** R1-1 |
| Fix 3: money on the season track | **Fixed:** "+5 tiers" and "this season only". **Open:** +20% stars (D84), 30 tiers (§23.5), Starglass (F57, C45) |
| Fix 4: protections for 13 to 15 | **Fixed:** reminder and quiet hours locked, Share hidden. **Open:** how a lock looks (§23.5), the cap (D85, D87), the band preview (D87), the 16 to 17 reminder (G58) |
| Fix 5: Observatory leaks and target band | **Fixed against v3.6.** It conflicts with answers F46, F44 and F39 (C45). Trace fee (§23.5), ruins (D78) |
| Fix 6: route against target | **Fixed** in the main. Land here on the Heart (§23.5); toggle capped at four and the landings (D78) |
| Fix 7: law data | **Fixed.** One crown slot (§23.5), the locked third slot (D75), the Day and night hint (D82 group) |
| Fix 8: results | **Fixed.** "Idle crew of 5" (D80; rule in TD.17), the worth question (C47) |
| Fix 9: two flows not designed | **Designed.** Departures held by D83, G57, D87, C51 and G58. First launch: the player catches the page, against §16: **New** R3-15 |
| Numbers N2, N4, N6, N7, N9 to N14, N18 to N21, N25, N26, N28 | **Fixed** |
| N1 Aether storage, N3 strain, N15 to N17 Character, N22 Lab settle time, N23 30 tiers, N24 rating, N27 landing noise, N29 Workshop 62% | **Open**, each in its §23.5 row |
| N5 builders, N8 crew 4 of 4 | **Open** (D73, D78) |
| B1 defender's report | **Designed.** G57, D83, TD.66, which lacks most of it: **New**, TD.66 amendment |
| B2 first session | **Designed** (D87, C51, G58). The notice before the first raid that it ends your 72 h protection: **New**, TD.18 |
| B3 Vault phase | Crack ring drawn against F35 (C45; **New** analysis correction). Crack orders (D80), load target (G47) |
| B4 heist edge states | Mostly designed. Pylons (D74). Placing casts and powers: **New**, D80 and TD.17 |
| B5 to B7 planner, crown slots, paradox | **Fixed** or open under C45, §23.5 and D75 |
| B8 landscape and left-handed | Left-handed **fixed**. Landscape: **New** C55 |
| B9 "Coming in a later turn" | **Open** on 12 screens (§23.5 notes row) |
| B10 loss and retry | **Designed.** The worth question (C47); an easier copy (D79 stands) |
| Sizes table | Heist, result and the planner's Plan tab **fixed**. Most other screens still have text under 13 pt (§23.5 Text size row, TD.2). Taps (C44). All 28 screens are now measured (review-2.md) |
| I1 one planning funnel | Summary bar **fixed**. The scout report still sets the landing and suggests a crew that Plan does not carry: **New**, TD.18 |
| I2, I3, I4, I8 | **Fixed** or held (D80, G47, G48, C47, §23.5, D73, D85) |
| I5 one age band | Adult default adopted. Share sheet (§23.5), cap (D85, D87) |
| I6 bigger text and targets | Partly **fixed**. §23.5 Text size row, C44, C49 |
| I7 school shapes | **Open** (§23.5 Colour-blind row, D87, D91). Law-icon frames: **New** R2-3. One set of marks: **New**, TD.5 |
| Screen notes 01 to 28 | Each is mapped in review-2.md. New beyond the above: the raid banner covers Collect (R2-4, TD.6); law cards sit behind the scout report's tabs (TD.18); the rehearsal plays on a flat 2D map (TD.43); trades marked for 1.1 (C49) |
| W1 to W8 what already works | Still true, except W4: Share for 13 to 15 is held by the §23.5 Share row |
| F1 to F3 fixes for the document | **Done in v3.6** (§18.8, §23.2's Profile row, §23.5's notes row). Leftovers: C49, G28, G69 |

### Part 2: what to change

| Item | Status |
|---|---|
| Every screen: one-way theft and Trace (REV:365) | **Fixed.** Who may Trace: the design and the server agree on "not foiled". The defence log offers a Trace after the raid that got out and after a Partial it tags "HELD" (G69), and none after the two where no loot got out (`screens_meta.js:592`). Only the server adds a condition, no Trace for a raid past the raider's week cap, which carries out G20's answer. Your fix brief gives a Trace for every raid (REV:365, :435). §12.3's "robbed" is undefined: **New** G70, a decision. TD.66's "Trace from each": **New** amendment |
| Sizes: 13 pt, 16 pt body, 44 pt taps (REV:366) | 13 pt **open** (§23.5, TD.2). 16 pt against §21.8's "16 pixels" is held (the register's planned §23.5 text). 44 pt conflicts with §21.1's 48 pt for primary controls: **New** note on TD.29 |
| School shapes (REV:367) | **Open** (§23.5, D87, D91). **New:** TD.5 and R2-3 |
| Demo player, words, 24 launch laws, pages (REV:368-377) | **Fixed.** Words open (§23.5 rows, D73) |
| Heist HUD (REV:381-390) | **Fixed** in the screens. Open: G47, D80, §23.5 Role health. The gate is missing almost all of it: **New**, TD.17. "Tap two portraits" departs from §12.18 by one word. "Every visible guard's cone" follows §12.6 but not §21.12, which the build follows: **New** C57, a decision |
| Result (REV:394-401) | **Fixed** in the main. Open: C47, G48, D80. The rule for the next step and the list of what was kept: **New**, TD.17 |
| Weaving (REV:405-408) | **Fixed** in the main. Crown slots (§23.5), recommended laws (§23.5). Heart and crown slots: **New**, TD.20 (with the epoch's third slot) |
| Observatory (REV:412-417) | **Fixed against v3.6.** It conflicts with F46, F44 and F39 (C45). Ruins (D78), depth (C46) |
| Season (REV:421-423) | **Fixed** in the main. 30 tiers (§23.5), Starglass (F57), chests (D84). No countdowns: **New**, TD.23 |
| Defence report (REV:427-437) | **Designed.** Outcome labels (G69), measures (G57). TD.66 lacks the outcome, replay, map and Trace window: **New**. Names hidden during a raid: D83 amendment |
| First launch (REV:441-451) | **Designed.** D87, C51, G58, the §23.5 First session row. 0:00 has the player catch the page: **New** R3-15 |
| README open items (README:228-239) | They repeat §23.5's claim that these screens are done. The register already lists what remains (D78, D80, D81, D83 to D87). The "revenge" term (README:234) does not exist in v3.6: Trace replaced it |

---

## 4. What the build takes from the handoff

| Handoff guidance | Take it? | Task |
|---|---|---|
| Godot 4.7.2; HTML is a reference; Control and Theme for the interface, Node3D for the world (README:12-15) | Yes | TD.1, TC.1, TD.3, TD.10 |
| Port `ruleborn-data.js` as the single data source (README:17) | **No.** §23.5 rules the module out. The gate must forbid copying from it and list each difference | TD.33 |
| 390 × 844, scaled to the device (README:20) | Reflow on 360 unless you choose D98's alternative | TD.2 |
| Tokens: the six school ramps (README:108-114) | The ramps belong inside the icons and are not tokens. Use §21.2's main colour and shadow (the design's S) | TD.2 |
| Note colours (README:117) | §21.2 says notes use §8.1's wheel. The design has two palettes. D97 | TD.2 |
| Components: gold, violet, cream, dark, segmented tabs, pill (SCREENS:179) | Yes. Add the violet button, the segmented control and the pill | TD.3 |
| Tabs and their route groups; Crew and Laws hubs (SCREENS:5) | Yes, each segment 48 pt | TD.6 |
| A scene per screen with a 0.3 s fade (SCREENS:177) | Yes, at §21.8's 250 ms unless D91 says otherwise | TD.6, TD.4 |
| A SubViewport per 3D screen; one scene per mode (SCREENS:178, README:176) | **No.** One persistent World under the shell, switched by mode, serving 14 screens. One island generator shared by every mode | TD.6, TD.10 |
| Autoload singletons (README:160-161) | **No.** State lives in TC.1's store | TD.6 |
| Camera dive about 1.2 s; slide between realms (README:149) | Yes, each a cut under reduced motion | TD.19 |
| Pinch and twist, no buttons (README:178) | Pending D75. A one-finger form is needed whatever the answer (§20.8) | TD.19, TD.10 |
| Three link kinds (README:179) | **No.** §5.3 has four, the Rift included | TD.19 |
| No jellyfish, kites or compass (README:181) | Yes, on the universe background only. Skyfield keeps its jellyfish (§5.7) | TD.32 |
| Staged character loading (README:152) | Yes: a worker thread, a few instances a frame, a loading state | TD.10 |
| `RBSfx` cues; `vibrate_handheld` (README:151) | Yes, as placeholders. §21.8's four haptic patterns and §20.8's alarm forms need a task | **new TD.67** |
| Export: GLTFExporter at 30 fps, clips named by the CLIPS keys, binary .glb (CHARACTERS:93-98) | Yes. Clip names use each family's keys (`ko`; the Archivist's own set). Expressions export as `expr_<key>`. There is no `apply()` and no morphs. Bake every moving node, not only the bones (3d-pipeline.md §4.1) | TD.7 |
| Six `.bin` meshes (CHARACTERS:8) | Body-only caches, used as harness fixtures, never imported | TD.7 |
| "About 1.2 grid tiles tall" (CHARACTERS:100) | **No.** Heights per kind from §21.6, one tile to the metre (§21.1) | TD.7; D94 |
| "match the toon look", lambert shading with a rim light, no outline (CHARACTERS:99) | Pending D92 (option D) | TD.8 |
| `world/` renders "can be used as is" (README:209) | Portraits, land, scout and obs are re-rendered in D92's look. The six top-level PNGs are old screenshots and are not imported | TD.7, TD.11 |
| Must-show lists (SCREENS.md) | §23.2 wins. 13 rows match, 1 is equivalent and 14 differ, and every difference is held | screen gates |
| Prototype-only state: stamina, XP, "asleep", four strain bands, Starglass (README:162-165) | **No.** No stamina; five crew states; seven strain bands belonging to the universe | TD.17, TD.21, TD.14 |
