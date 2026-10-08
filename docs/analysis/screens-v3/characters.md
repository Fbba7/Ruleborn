# Characters and creatures: Screens v3's 43 sheets against design document v3.6

Paths in this report:
- `creatures/` means `scratchpad/art/named/creatures/`
- `doc` means `docs/design/ruleborn-game-design-v3.6.txt`
- `shots/` means `scratchpad/shots/`

## 0. What was read, and how

- **All 43 `*_dc.html` sheets, read from source.** I wrote a small extractor (`analysis/chars_scripts/extract.py`) that pulls each sheet's static text and its script data: `card`, `stats`, `spec`, `palette`, the clip list `CL`, the form or variant table `FD`, and `FL`. The dumps are in `analysis/chars_out/<Name>.txt`.
- **The 18 kinds were compared by script.** `analysis/chars_scripts/compare.py` checks each kind against §11.11's cards, §11.2's table and §21.6's table. Its output is `analysis/chars_cmp.txt`.
- **The sheets have a fixed layout.** In every kind sheet, line 69 is the level-1 role panel, 129 the law-modifier note, 153–156 the forms (`FD`), 160 the clips (`CL`), 166 the palette, 173 the card, 174 the stats and 182 the spec. Line numbers below use this layout.
- **Rendered captures.** The page-text captures in `shots/chars` cover sheets 01–30. Their text matches the source for every one I compared. Sheets 31–43 (anomalies, law creatures, wildlife) I read from source only.
- **Images I looked at:** Tidewalker, Echoplate, Glass Golem, Emberling, Twinned and `shots/all/Characters_index.png`.
- **Rig and sculpt modules** (`creatures/*.js`): I read only the parts cited below (`creature_kit.js`, the `stdClips` weights, marking names, fur shells). I did not run them, so I did not check animation content beyond the clip names and notes.
- **Section numbers.** The brief says "§11.4 animations", but §11.4 is Levels in every version from v2.3 to v3.6. The animation set is in §21.6 (doc:10656). The sheets make the same mistake: "the 15 animations the design document lists for every Ruleborn (11.4)".

## 1. Summary

- **§23.5's list of differences is mostly right.** All 12 rows of "Where the character sheets differ" were checked, plus §23.5's general claims:
  - 9 rows are confirmed exactly.
  - 3 rows are incomplete: school markings, illusory guards and swarmlings.
  - Two general claims are overstated: "each has the fifteen animations of 21.6" and "visitors and anomalies match 11.7, 11.8 and 17.3".
- **v3.6 left a hole in the Twinned.** Its change to the Twinned's gift ("every ability it fires, fires two times. Its crew's abilities fire once") leaves the gift doing nothing. A paradox-born has no role and no §11.11 card, so it has no ability to fire.
- **Paradox-born are still under-specified for a build.** They have:
  - no guard behaviour (§12.8 keys guard behaviour to role)
  - no school or marking
  - no rule-sheet line and no sound
  - forms that are not decided
  - a "shared" health pool that the sheet draws as 2 × 60
- **§23.5 missed several things.** Section 4 has the full list. In brief:
  - Four sheets label their kind CARRIER in the level-1 panel.
  - Seven sheets say a Carrier "moves fast with a load", against §11.1's "15% slower when loaded".
  - Five sheets make the school colour an accent rather than the main colour.
  - The Soulmender's Spirit mark is a spiral, and so is every Spirit header badge.
  - The work-loop animations do not exist as §21.6 asks: one per building, so three per kind.
  - Visitors, anomalies and law creatures carry "variant" mechanics: offers lasting 2 h longer, a bonus offer, an arena clock 20 s shorter, and creatures that "linger once".
  - Illusory guards "reform" after being walked through; §7.7 says they vanish.
  - Swarmlings are a separate beetle species. §12.21 and §21.7 make them small copies of the guard they came from.
  - There are no bees-and-butterflies for Verdant.
- **No 3D file exists to import.** Every model is three.js code. The one "Download GLB for Godot" line is text with no link, so the build needs an export pipeline before any character art reaches Godot.
- **`content/` must change.** It needs:
  - a paradox-born table with v3.6's numbers
  - a visitors table that encodes the Stray rule (no nineteenth kind)
  - the §11.11 "Rule sheet" line, which `tools/extract_content.py` never extracted
  - §21.6's height, colour and signature columns
  - The sim's `Role` enum also cannot hold a crew member without a role.

## 2. §23.5's "Where the character sheets differ", row by row

| §23.5 row | Verdict | Evidence |
|---|---|---|
| **Stats.** Own level-1 numbers on fifteen sheets, e.g. Tidewalker carry 140 | **Confirmed.** Exactly 15. | Only Featherkin (120/4.5/12/104), Skyskipper (160/3.6/8/300) and Mossbear (420/2.6/20/138) carry §11.1's role numbers. Tidewalker is 200/3.0/22/140 (`creatures/Tidewalker_dc.html:174`). The other 14 are listed in section 5.1. |
| **Character cards.** Eight drop rule sheet and sound; four change Best at and drop the building | **Confirmed exactly.** | Rule sheet and Sounds like are missing on Emberling, Stormhound, Sparkwright, Bloomling, Rootrunner, Echoplate, Lantern Wisp and Soulmender (line 173 of each). Best at is changed on Emberling ("Breaking wards and pylons"), Stormhound ("Scouting routes and fast getaways"), Sparkwright ("Keeping the Sage's power ready") and Bloomling ("Keeping the crew on their feet"). Only trivial differences elsewhere: section references dropped from card text — "(7.3)" on Prism Mite, "(11.7)" on Sparkwright, "(12.20)" on Echoplate — and curly apostrophes. |
| **Role accessories.** Eleven kinds carry a kind-specific item | **Confirmed: 11.** This counts Rambler's horns as "horn", Quarryback's pick tail as a hammer, and Rootrunner's basket as a pack. | Spec line 182 of each sheet: Featherkin binoculars; Glass Golem granite bracers; Hourkeeper brass hourglass and brow pin; Stillwatch gorget and pauldron; Emberling knuckle bands; Stormhound collar and bracers; Sparkwright tool belt; Mossbear bark bracers; Bloomling leaf charm; Lantern Wisp lantern frame; Soulmender spiral pendant. |
| **School markings.** "Six specs list no school-shape marking, and Echoplate's etched mark is a spiral" | **Incomplete, and the count does not hold.** | Only **Lantern Wisp** lists no marking (`Lantern_Wisp_dc.html:182`), and `lanternwisp.js` has no marking geometry. **Soulmender's** mark is also a spiral ("Glowing Spirit spiral pendant", `Soulmender_dc.html:182` and :57), and §23.5 does not name it. All three Spirit sheets use the same spiral glyph as their school badge in the page header, and so does the Echoplate's shield (seen in the image). The other 14 specs each list a marking. |
| **Matter's shape.** Called a hexagon | **Confirmed.** | "Matter hexagon as a marking" (`Glass_Golem_dc.html:182`, `Quarryback_dc.html:182`, `Prism_Mite_dc.html:182`). The header badge is a hexagon with three full diagonals (`Glass_Golem_dc.html` header SVG), not the cube's "Y" of inner edges. The icon library already has a proper cube: `icons_rbi.js:123` (`G.cube`). |
| **The Twinned.** Doubles every ability its crew fires | **Confirmed.** | "Twin suns: acts twice. Every ability it or its crew fires, fires two times" (`Twinned_dc.html:173`). See finding 1: v3.6's narrower rule leaves nothing to double. |
| **The Chronicler.** Rewind | **Confirmed.** | Clip `["p1","Rewind",…]` (`Chronicler_dc.html:127`). The other two proposals, Bookmark ("plants a ribbon-marker") and Still frame ("frames a spot; it freezes"), are also placeholders under §11.7. Bookmark should be checked against "none restores earlier state" when its power is written. |
| **The Stray.** A kitten, a nineteenth kind | **Confirmed.** | "A scruffy kitten with a bundle on a stick", 0.55 m, its own sculpt (`Stray_dc.html:173`, `creatures/stray.js`). |
| **Puffball flock.** Herd of 6–9, bleats at raiders it sees, heard at 3 tiles | **Confirmed.** | `Puffball_Flock_dc.html:174` (HERD 6–9, HEARD AT 3 tiles) and :173 ("Stands in paths and bleats at raiders it sees"). It also adds SPEED 2.0 and BLOCKS 1 tile; §7.7 states neither, and both are harmless. |
| **Swarmlings.** Own speed, sight, hearing and 20 health | **Confirmed, but incomplete.** | SPEED 4.6, SIGHT 2 tiles, HEALTH 20 (`Swarmlings_dc.html:174`); "hears twice as well", "Catches like a guard, one at a time" (:173). Missed: the look (finding 9). |
| **Illusory guards.** Tells: no shadow, a flicker, a ring of light | **Confirmed, but incomplete.** | Plus "Its eyes stay real, the easiest tell". Missed: "anyone can walk through them" and the clip "Walked through: Scatters and reforms" (`Illusory_Guards_dc.html:129`, :158). §7.7 says illusions vanish when touched (finding 8). |
| **Wildlife.** Moths give raiders away, fireflies gather on anyone hiding, beetles blur raiders behind glass, lanternfish light up waders, puffballs speed up hedges | **Confirmed.** | The five cues are on the Lantern Moths, Fireflies and Moths, Prism Beetles, Lanternfish and Puffballs and Bees sheets. Also missed: Lantern Vale moths "flash their eye-spots when disturbed" (`Fireflies_and_Moths_dc.html`, law note). This is a sixth giveaway cue. |

§23.5's general claims:

- **"The eighteen kinds match 11.2 and 21.6 in name, school, role, size, height, colours, look, proportions, personality, habit, ability, resistance and signature moment."**
  - **True of the header chips and cards** for name, school, role, size, height, look, proportions, personality, habit, ability, resistance and signature. All 18 heights match §21.6.
  - **Role is not true everywhere:** the level-1 panel mislabels four kinds (finding 3).
  - **Colour is not true as a rule:** §21.6 says "school colour is its main colour", and five or seven sheets break it (finding 5).
- **"Each has the fifteen animations of 21.6."** Each has 15 named clips. But the work loop is not "one per building", and most "work loop" clips are the §11.11 at-home habit (finding 6).
- **"A guard form with sash and lantern, its three forms and a squint test."** Confirmed for all 18: `FL` includes `guard`, the label reads "AS A GUARD · SASH + LANTERN", the three forms in `FD` match §11.10's text, and every sheet has a squint statement.
- **"The Sages, visitors and anomalies match 11.7, 11.8 and 17.3."**
  - The four launch Sages match word for word.
  - Visitors and anomalies carry variant mechanics that §11.8 and §17.3 do not have (finding 7).

## 3. Group by group

### 3.1 The 18 kinds

Notes for the table:
- **Stats** are health, speed, power, carry. §11.1's role numbers: Scout 120/4.5/12/104; Breaker 180/3.2/40/104; Carrier 160/3.6/8/300; Warden 420/2.6/20/138; Mender 130/3.4/6/104.
- **Panel** is the line-69 label and job line; ✓ means §11.1's role and job.
- **Main colour** is the first or largest palette entry at line 166.
- **"Work" clip** is line 160.

| # | Kind (role) | Sheet stats | Panel (line 69) | Accessory (spec) | Marking (spec) | Main colour | "Work" clip |
|---|---|---|---|---|---|---|---|
| 01 | Featherkin (Scout) | 120/4.5/12/104 ✓ | ✓ | binoculars | Motion chevron | sun gold ✓ | Star Well ✓ |
| 02 | Skyskipper (Carrier) | 160/3.6/8/300 ✓ | ✓ | big pack ✓ | chevron | sun gold ✓ | Star Well ✓ |
| 03 | Rambler (Breaker) | 240/3.2/38/96 | "Breaks walls, pylons and wards fastest" (drops the Vault, adds walls) | brass brow guard (+ horns) | chevron | gold fleece ✓ | habit: headbutts boulder |
| 04 | Glass Golem (Warden) | 400/2.4/18/120 | ✓ | granite bracers | Matter **hexagon** | violet ✓ | habit: watch the sky |
| 05 | Quarryback (Breaker) | 260/2.9/42/100 | as Rambler | pick tail + miner's lamp | hexagon | violet-grey ✓ | habit: digs a hole |
| 06 | Prism Mite (Carrier) | 120/3.6/14/80 | "Carries loot; **moves fast with a load**" | prism pack ✓ | hexagon | violet ✓ | habit: plays with itself |
| 07 | Tidewalker (Carrier) | 200/3.0/22/140 | "moves fast with a load" | shell pack ✓ | hourglass | **brown fur** (cyan on pack and bands only) | washes a pebble |
| 08 | Hourkeeper (Mender) | 180/2.6/16/60 | "Heals allies and keeps the crew standing" | hourglass + brow pin | hourglass | teal ✓ | habit: watches it drain |
| 09 | Stillwatch (Warden) | 280/2.7/30/60 | "Holds chokepoints and stops guards" | gorget + pauldron | hourglass | **slate** (cyan crest and wing bar) | habit: one leg |
| 10 | Emberling (Breaker) | 150/3.4/24/60 | **"CARRIER"**, "moves fast with a load" | knuckle bands | bolt | **charcoal** (orange cracks) | chases sparks |
| 11 | Stormhound (Scout) | 180/4.6/16/90 | **"CARRIER"**, "moves fast with a load" | collar + bracers | bolt | orange ✓ | chases its sparks |
| 12 | Sparkwright (Mender) | 160/3.5/12/70 | **"CARRIER"**, "moves fast with a load" | tool belt (+ goggles) | bolt | orange ✓ | rewires the lantern |
| 13 | Mossbear (Warden) | 420/2.6/20/138 ✓ | ✓ | bark bracers | leaf | slate body, moss mantle (arguable) | pats garden soil ✓ |
| 14 | Bloomling (Mender) | 110/3.2/8/50 | **"CARRIER"**, "moves fast with a load" | leaf charm | leaf | green ✓ | waters the stones |
| 15 | Rootrunner (Carrier) | 140/3.4/9/95 | "moves fast with a load" | basket ✓ | leaf badge | **bark brown**, labelled "Life-school brown" | rearranges the garden |
| 16 | Echoplate (Warden) | 260/2.4/16/60 | "Holds the line; guards the crew" | kite shield ✓ | **spiral** | **silver** (magenta trim and cape) | habit: polishes armour |
| 17 | Lantern Wisp (Scout) | 90/4.0/6/40 | "Sees what others miss" | lantern frame | **none** | magenta ✓ | lights every lantern |
| 18 | Soulmender (Mender) | 120/3.3/8/55 | "Keeps the crew on their feet" | spiral pendant | **spiral** | pale lilac fuzz, magenta hood (arguable) | habit: sits with the loser |

Other sheet text that is wrong but does not reach the build (the build follows the document):

- **Wrong law-modifier note on four sheets.** Emberling, Stormhound, Sparkwright and Bloomling carry the Prism Mite's note verbatim at line 129: "A tiny, light body like this one … by its own rule it sees straight through Glass and Mirror images". That is the Prism Mite's resistance, and Stormhound (0.9 m) and Sparkwright (0.8 m) are standard size. These are the same four sheets §23.5 flags for Best at.
- **Small wording differences.** Echoplate's signature drops ", translucent". The Stray's card says "waits until helped" while its stats say "WAITS 12 h".
- **Wrong section references in sheet headers.** Visitor headers cite "11.7" (Visitors are §11.8). Law-creature headers cite "6.3" (that is §6.3, terrain unlocks; law creatures are §7.7).

### 3.2 Sages (6)

- **The four launch Sages match §11.7 word for word:** unlock level, three powers with their uses, at home, and on guard (`chars_out/Archivist.txt` and the other three).
- **The Archivist's extra "Tips" line** ("One short line of advice, at most once a session; never blocks play; can be turned off") is the doc's own row at doc:8768–8770.
- **Looks match §21.6's Sage rows.**
- **Recharge.** The sheets show it as "RECHARGE 20 s"; §11.7 calls it the "cooldown", and Sparkwright's card cuts "the Sage's cooldown". The build should use one player-facing word, the document's.
- **Chronicler (Time) and Lamplighter (Energy).** Looks and powers are labelled as proposals on the sheets. §11.7 (v3.6) makes the power names placeholders. Their looks are not in §21.6 and are not on §23.5's adopted list (finding 16). The Lamplighter's proposed "Spark trail" shares its name with the Energy law "Spark trails"; this matters only if it ships.
- **Animations.** Each Sage has 10–11 clips: one per power, idle, walk, guard, home work, celebrate, rest. The document sets no Sage animation list, so these can be adopted.

### 3.3 Paradox-born (3)

- **Numbers and bodies match v3.6 §11.8 (doc:6259–6285):**
  - Reverser 120/3.8/8/70, standard, about 0.85 m, 2.2 heads.
  - Unmade 100/3.4/8/85, standard, 0.8 m, 2.4 heads.
  - Twinned speed 3.6 and power 7, small, 0.6 m each, 1.8 heads.
- **The Twinned's health and carry are drawn differently.** The sheet shows "2 × 60" health and "2 × 40" carry (`Twinned_dc.html:174`), where v3.6 says "120, shared by its two bodies" and "80, shared". Two pools of 60 and one shared pool of 120 behave differently when one body is hit, so the screen must show 120.
- **The sheets add to all three:**
  - personality, at home, best at and signature (none in the doc)
  - the three forms with §11.10's quirks (`FD` lines 153–156)
  - a guard form
  - "Legendary: no school badge; its paradox is its mark" (`Reverser_dc.html:182`)
- **What the doc does not say about them, which section 4 takes up:**
  - no role, so no §12.8 guard behaviour
  - no school, but §21.6 requires a school colour and marking on every ruleborn
  - no rule-sheet line for the gift; §11.11 requires one for every ability
  - no sound; §11.11 and §21.8 say every character is told apart by its sound
  - whether they have forms
- **§11.8's claim checks out.** "None is better than any role in every number" holds against roles.json: each paradox-born loses to some role on at least one number, and never beats one on all four.

### 3.4 Visitors (3)

- **Offers match §11.8.**
  - Cartographer: a full scouting map with ward positions, for Starlight; 12 h.
  - Collector: 3 for 1, 5 for 2 at Dock level 3.
  - Stray: one favour, three traits.
- **Looks match §21.6:** a balloon of maps (a mouse aviator), and a magpie merchant in a coat of pockets.
- **The Stray is a kitten.** This is listed in §23.5; v3.6 says it is one of the eighteen kinds, travelling with a bundle on a stick.
- **Missed by §23.5: the VARIANT buttons carry mechanics** (lines 153–156 on all three visitor sheets):
  - Night: "Offer lasts 2 h longer"
  - Festival: "Brings one bonus offer"
  - Echo: "Returns once more"

### 3.5 Anomalies (3)

- **What matches §17.3:** arrives in 48 h; a three-realm arena; two laws plus one a day (Devourer: Inward pull + Heavy ground; Hourglass Storm: Tidemark + Haste; Wildfire Bloom: Heat bloom + Regrowth); 3 runs a day; −10% for 12 h if it arrives.
- **Looks match §11.8's one-liners.**
- **Missed by §23.5: the VARIANT buttons carry mechanics** (lines 153–156):
  - Faint: "Weaker, early in the 48 h"
  - Enraged: "Arena clock runs 20 s shorter"
  - Echo: "Leaves once, returns once"

### 3.6 Law creatures (3, after launch)

- **Puffball flock.** See section 2.
- **Swarmlings.** One design: a thumb-sized beetle in a tin helmet with a pin spear (`Swarmlings_dc.html:173`, :182, "Always appears in pairs"). It is not a small copy of the guard it came from (finding 9).
- **Illusory guards.** Exactly the real guard's sculpt in violet mirror glass, with tells. They are walked through and reform (finding 8).
- **All three carry form variants with quirks** (lines 153–156): Hush "Noticed 10% later", Spark "A little faster", Echo "Lingers once after it fades". §11.10's forms belong to the eighteen kinds only.

### 3.7 Realm wildlife (7)

- **Names match v3.6 §5.7 for six realms:** Heart lantern moths, Skyfield jellyfish, Crystalline prism beetles, Tidehold lanternfish, Emberreach ash moths, Lantern Vale fireflies and moths.
- **Verdant is the exception.** It is "Puffballs and Bees": the Flock puffball sculpt in honey wool with two orbiting bees ("Moves as the Flock puffball does"). v3.6 makes Verdant bees and butterflies. **There is no butterfly anywhere in the bundle** (searched `creatures/`, `screens_*.js`, `realm_diorama.js`).
- **The two adopted cues are present.** Jellyfish ride the wind under Current; ash moths "WARNS 1 s early".
- **Per-realm counts and ranges** (3–5 per lamp, 4–7 per realm, 2–3 per pond, 2–4 per vent) change nothing, so they can be adopted as scenery.
- **The wildlife variants** (Night, Storm "in the Grand Law weather", Pair) are cosmetic.

## 4. Findings for the register (not in §23.5, or in it but wrong)

Each finding gives its kind and severity, then the evidence and a recommendation.

### 1. The Twinned's gift does nothing after v3.6 (contradiction, significant)

- **The change.** v3.6 changed §11.8's Twin suns from "Acts twice: every ability fires two times." to "Acts twice: every ability it fires, fires two times. Its crew's abilities fire once." (`v36/diffs.txt` §11.8; doc:6250–6251).
- **Why that empties it:**
  - Paradox-born "have no role in 11.1" (doc:6257).
  - Abilities exist only on the 18 cards: §11.11 "These cards are the one home for every ability" (doc:6337).
  - The Reverser's gift is itself an ability ("two uses a heist, with the 10-second lockout"). The Twinned's gift is a modifier on abilities it does not have.
  - The sheet's version (doubling the crew's abilities) gave it an effect. v3.6 removed that and put nothing in its place.
- **Recommendation.** The owner writes what "acts twice" doubles, as a rule-sheet change (§7.3). Options: its own hits and loading against the shared 120 and 80 pools, or one two-use ability of its own with the lockout. Until then the Twinned cannot be built or balanced.

### 2. Paradox-born: what a build needs that v3.6 does not say (gap, significant)

- **Guarding.** "Guards are the defender's own ruleborn … and their role decides how they behave" (§12.8, doc:7034), with a behaviour row per role. Paradox-born have no role, so a paradox-born on a Guardian Post has no behaviour. The sheets give all three an "As a guard" form.
- **School.** §21.6: "Each ruleborn's school colour is its main colour, and its school shape appears as a marking." The sheets say "no school badge; its paradox is its mark".
- **Rule sheet and sound.** §11.11 requires every ability to be a named-parameter change (doc:6337) and every character to have a sound. The three gifts have neither; the sheets have no "Sounds like" line.
- **Forms.** §11.10 counts 54 forms as 18 kinds × 3 notes, and the Forms album completes "one note across every kind". The sheets give paradox-born Hush, Spark and Echo forms with the quirks, and the Echo quirk is a revival.
- **The Twinned's two bodies.** "One character drawn as two silhouettes" with a "shared" pool. The sheet draws the second body as a copy that replays the first 0.16 s late (`Twinned_dc.html` text) and shows two pools of 60. The simulation needs one body with a shared pool; the screens must show 120 and 80.
- **Recommendation.** One owner decision each: guard behaviour (or "paradox-born do not guard"), school mark (or the paradox mark adopted in §23.5), gift rule sheets and sounds, forms yes or no. Model the Twinned as one sim body, the second silhouette cosmetic.

### 3. Level-1 role panels mislabel four kinds and contradict the Carrier rule (deviation, minor)

- **Wrong role.** Line 69 reads "CARRIER · LEVEL 1 · 11.1" on Emberling (a Breaker), Stormhound (a Scout), Sparkwright (a Mender) and Bloomling (a Mender). Confirmed in the Emberling capture.
- **Wrong Carrier rule.** Seven sheets give the Carrier job as "Carries loot; moves fast with a load": Prism Mite, Tidewalker, Rootrunner and the four above. §11.1 says "Hauls loot; 15% slower when loaded", which the sim already implements (`sim/src/heist.rs:33`, `CARRIER_LOADED_PACE` 85/100).
- **Paraphrased jobs.** Ten sheets paraphrase the job, e.g. Breaker "Breaks walls, pylons and wards fastest" drops the Vault and adds walls.
- **Copied law note.** The same four sheets also carry the Prism Mite's law note (line 129).
- **Recommendation.** Add a row to §23.5: the panel follows §11.1's role and job column. Do not use these sheet panels as the character-screen template; generate from content (roles.json).

### 4. Spirit's shape and the marking count in §23.5 (deviation, minor)

- **The count.** §23.5 says "six specs list no school-shape marking". Only Lantern Wisp lists none (`Lantern_Wisp_dc.html:182`; no marking in `lanternwisp.js`).
- **Soulmender is not named.** Its mark is a Spirit spiral (`Soulmender_dc.html:182`, :57).
- **The spiral is the design's Spirit glyph.** All three Spirit sheet headers use it as the school badge.
- **The Matter badge** is a hexagon with three diagonals rather than a cube.
- **Recommendation.** Correct §23.5's row: Lantern Wisp has none; Echoplate and Soulmender use a spiral; the Spirit and Matter header badges are wrong. The build draws §5.2's eye and cube, and `icons_rbi.js` already has both (`G.eye` at :45, `G.cube` at :123).

### 5. School colour is not the main colour on five sheets (deviation, minor)

- **The rule.** §21.6: "Each ruleborn's school colour is its main colour". §23.5 says the colours match.
- **Where it breaks** (palette line 166 of each sheet; Tidewalker and Echoplate confirmed in captures):
  - Tidewalker: brown fur #9C6A3E for back and limbs; cyan only on the pack and bands.
  - Stillwatch: slate #4E627A body.
  - Emberling: charcoal #2E2428 skin.
  - Rootrunner: bark #8A5634, labelled "Life-school brown", while Life is green.
  - Echoplate: silver #B8BCCC plates.
- **Arguable:** Mossbear (slate body under a moss mantle) and Soulmender (pale lilac fuzz).
- **The doc's own colour column** lists the school colour first for each of these ("Cyan and sand", "Cyan and slate", "Orange and charcoal", "Green and brown", "Magenta and silver").
- **Recommendation.** Recolour those models in the export (a material change only), or adopt them in §23.5. The school mark keeps school readable either way. §10.3 says the same of wards, where colour is "a third cue and never the only one" (doc:5900).

### 6. Work loops: §21.6 asks for one per building; the sheets have one each, mostly the home habit (gap, significant)

- **§21.6's list** ends "…nap, and one work loop per building" (doc:10656).
- **Three buildings take workers:** Star Well, Aether Spring and Garden (§10.1, doc:4738; worker slots appear only in their tables). So each kind needs three work loops.
- **What the sheets have.** Each has one "work" clip (line 160). Only Featherkin and Skyskipper (Star Well) and Mossbear (Garden) work a building. The other 15 use the §11.11 at-home habit, e.g. Glass Golem "Watch the sky", Prism Mite "Plays with itself", Soulmender "Sits with the loser", Echoplate "Polishes armour nobody wears".
- **The habit is a separate requirement.** §11.11 requires "one habit you can watch at home", and §21.6's list does not have it. The sheets merge the two, so §23.5's "each has the fifteen animations of 21.6" overstates.
- **The knock-out clip.** §21.6 specifies "dizzy stars, then a puff of petals as it goes home". No sheet's knock-out description mentions this; only Hourkeeper says "dizzy". I did not check the rig code for it.
- **Recommendation.**
  - Count the clips per kind as the 14 shared clips + 3 building work loops + 1 home habit = 18.
  - Or the owner rules that one generic work loop serves all buildings.
  - Add the knock-out petals to the art checklist.

### 7. Variant mechanics on visitors, anomalies and law creatures (deviation, minor)

- **Visitors** (lines 154–156 on `Cartographer_dc.html`, `Collector_dc.html`, `Stray_dc.html`): Night "Offer lasts 2 h longer", Festival "Brings one bonus offer", Echo "Returns once more".
- **Anomalies** (`Devourer_dc.html`, `Hourglass_Storm_dc.html`, `Wildfire_Bloom_dc.html`, lines 154–156): Faint "Weaker, early in the 48 h", Enraged "Arena clock runs 20 s shorter", Echo "Leaves once, returns once".
- **Law creatures** (`Puffball_Flock_dc.html`, `Swarmlings_dc.html`, `Illusory_Guards_dc.html`, lines 154–156): Hush "Noticed 10% later", Spark "A little faster", Echo "Lingers once after it fades".
- **Why they are out.** Every one changes what a player earns or what a crew faces, which is a mechanic under §23.5. §23.5 says visitors and anomalies match.
- **Recommendation.** Add a row to §23.5: variants are not built; at most cosmetic tints.

### 8. Illusory guards reform after being walked through; §7.7 says they vanish (deviation, minor)

- **The sheet:** "anyone can walk through them" (`Illusory_Guards_dc.html:129`); clip "Walked through: Scatters and reforms" (:158).
- **§7.7:** "illusions vanish when touched", "pop into sparkles when touched", "one hit tells the truth" (doc:3699–3717).
- **Recommendation.** Extend §23.5's illusory-guards row: touched means gone.

### 9. Swarmlings must read as small copies of the guard they came from (deviation, minor)

- **The sheet.** One beetle species in a helmet with a pin spear, "Always appears in pairs" (`Swarmlings_dc.html:173`, :182), whatever the source guard.
- **The document:**
  - §12.21: "Split guards created by Swarm birth inherit the role of the guard they came from, at 30% of its health and power" (doc:7414).
  - §21.7 and §7.7: "Knocked-out guards pop into two tiny guards".
  - §21.6: a guard's role reads from its role accessory.
- **Recommendation.** After launch, swarmlings are the source guard's model at small scale, with its role accessory.

### 10. The Stray rule leaves choices to the build (gap, minor)

- **v3.6 §11.8:** "a ruleborn of one of the eighteen kinds, its kind drawn as a birth's is (11.5)".
- **Which weights?** §11.5 and §11.9 weight births by the Nursery's realm: 3 per woven law, 2 for the realm's school, 1 per crown law. The Stray arrives at the Dock in the Heart, which has no school (§5.2) and no Nursery.
- **Which form?** §11.10 decides a form by the notes of the Nursery's realm.
- **§21.6 was not updated.** It still says "a scruffy little creature", and a Stray can now be a 1.4 m Mossbear.
- **Art.** Every one of the 18 rigs needs a socket for the bundle-on-a-stick prop. Lantern Wisp has a wisp tail and no legs.
- **Recommendation.** The owner names the realm whose weights and notes apply (the Heart, or the realm where the favour was done) and updates §21.6's Visitors row.

### 11. No 3D asset exists for Godot (gap, significant)

- **What the models are.** Every model is three.js r184 code: "SDF clay volume -> surface nets -> painted + baked AO -> fur shells -> skinned rig" (`creatures/creature_kit.js:2`). Clips are functions of time (`stdClips`, :132).
- **No files.** There is no .glb, .gltf or .obj anywhere in `scratchpad/art`, and no art in `client/`. Skyskipper's "Download GLB for Godot (named parts and materials…) or OBJ + MTL" (`Skyskipper_dc.html:57`) is plain text with no link.
- **Mobile cost.** Fur shells run 4–7 layers (kit default 4, Tidewalker 5, Stormhound 7), which means alpha overdraw on mobile.
- **Law modifiers are text only.** §21.6's procedural law modifiers (gravity, time scale, lean and so on) appear only in the sheets' notes; `creature_kit.js` has lean but no gravity or time-scale handling.
- **A per-kind body weight exists.** Each rig has a weight `w` in `stdClips({w:…})`, from Emberling and Lantern Wisp 0.05 to Glass Golem 0.95. It could be adopted as §21.6's "the lighter the body, the bigger the effect" value.
- **Recommendation.**
  - A roadmap task: a headless export of each Rig page through three.js GLTFExporter. Sample every clip to keyframes; keep forms as material variants plus one accessory node (§21.6: "54 forms need 18 models"); include the guard sash and lantern as nodes; add a level of detail without fur at game scale.
  - A check that each exported clip set equals §21.6's list.
  - Law modifiers built in Godot, using `w` as a visual-only input.

### 12. `content/` lacks v3.6's characters (gap, significant)

- **No paradox-born table.** `tools/check_document.py:1105` still says "Visitors, paradox-born, anomalies: no content table enumerates them".
- **No "Rule sheet" field.** `tools/extract_content.py:162–166` (`CREATURE_FIELDS`) never extracts "Rule sheet", so `content/ruleborn.json` cannot carry "all of 11.11, word for word", which is §23.5's rule for cards.
- **§21.6's columns are not extracted:** height, colours, signature moment.
- **The sim cannot hold a role-less crew member.** `sim/src/lib.rs:244–253` keys every crew stat to one of five `Role` values.
- **Recommendation:** section 5.

### 13. Verdant's wildlife has no asset, and §21.9 budgets no wildlife or law creatures (gap, minor)

- **No Verdant asset.** v3.6 §5.7 makes Verdant bees and butterflies. The only Verdant sheet is the Flock puffball with bees, and no butterfly exists.
- **§21.9's asset list** (doc:11018–11028) has "18, 4, 3, 3; 3 later" characters. It does not budget the 7 wildlife sets, the 3 law creatures (after launch) or the 2 after-launch Sages, though Screens v3 designs all of them.
- **One more cue to drop.** Lantern Vale moths "flash their eye-spots when disturbed" is a giveaway cue the wildlife row should also exclude.
- **Recommendation.** Make a bees-and-butterflies asset; give wildlife and law creatures a §21.9 row.

### 14. "Rounded silhouette with no sharp points" (deviation, minor)

- **The rule:** §21.6.
- **Where it breaks:** Glass Golem "crystal spires break the outline" (`Glass_Golem_dc.html:182`; visible in the capture), Stillwatch "long dagger beak" (`Stillwatch_dc.html:182`), Stormhound "a mane of lightning bolts".
- **§23.5** says the proportions match.
- **Recommendation.** Soften these in the export, or adopt them in §23.5.

### 15. A Mender with goggles (contradiction in v3.6, minor)

- §11.11 gives Sparkwright, a Mender, "goggled eyes" (doc:6664).
- §21.6 makes goggles the Scout's role accessory, which §23.5 says exists "so a guard's role reads at a glance".
- **Recommendation.** Give the Sparkwright its Mender satchel of leaves and keep its goggles visually distinct from a Scout's, or change one of the two sections.

### 16. Sheet flavour the document is silent on, but does not list as adopted (gap, minor)

- **The flavour in question:**
  - paradox-born personality, at home, best at and signature
  - visitor moods and sizes
  - anomaly sizes
  - wildlife counts and ranges
  - the Chronicler's and Lamplighter's looks
  - Sage animation lists
- **The rule.** §23.5 says a design is adopted where the doc is silent and it is "listed below". These are not listed.
- **Card text.** §11.11's card text includes section references, e.g. "(12.20)", "(11.7)", "(7.3)", and nothing says whether player-facing cards show them.
- **Recommendation.** One §23.5 row adopting non-mechanical flavour from the sheets, and one line saying cards drop § references.

## 5. What `content/` must change

1. **New `content/paradox_born.json`, extracted from §11.8's two tables (doc:6241–6285).**
   - Fields: id, name, from (the paradox), gift text, health, speed, power, carry, body (size band, height in m, heads), and `shared: ["health", "carry"]` for the Twinned.
   - Validator checks:
     - The size band derived from heads by §12.21's rule (under 2.0 small, 2.0–2.5 standard) equals the body column: Twinned small, Reverser and Unmade standard.
     - §11.8's own claim "none is better than any role in every number", computed against `roles.json`. It passes today.
     - `from` names one of §7.5's three paradoxes.
     - `ruleborn.json` stays at 18, three per school.
   - Add it to `EXTRACTED_FROM` in `tools/validate_content.py:98` and remove paradox-born from `NOT_DERIVED` in `tools/check_document.py:1101–1106`.
   - Keep it out of `ruleborn.json`, or the three-per-school check breaks.
   - It carries `needs_decision` for findings 1 and 2.
2. **New `content/visitors.json` from §11.8's Visitors table.**
   - The Stray row carries no kind: its kind is drawn as a birth.
   - Validator: no "stray" (or any nineteenth) id in `ruleborn.json`; `forms.json` stays 54 = 18 × 3.
   - The season-track stray in `server/src/track.mjs:43–51` (F38) is also one of the 18 when the roster is built.
3. **`content/ruleborn.json` additions.**
   - Add `"Rule sheet": "rule_sheet"` to `CREATURE_FIELDS` (`tools/extract_content.py:162`). All 18 cards carry it in v3.6 (doc:6335–6860); without it the card generator cannot meet §23.5's "word for word".
   - Add §21.6's `height_m`, `colours` and `signature`.
   - Optionally add `school_shape` from §5.2 (chevron, cube, hourglass, bolt, leaf, eye), so art and icons have one source.
4. **`content/sages.json`.** No numbers changed in v3.6. If the roster screen lists them, add an after-launch note for the Chronicler (Time) and Lamplighter (Energy) with powers "not yet written". Never take their sheet power names.
5. **`content/roles.json`.** Unchanged. The sheets' per-kind numbers are not adopted (§23.5).
6. **`content/forms.json`.** Unchanged unless the owner gives paradox-born forms (finding 2).
7. **sim.** A crew member's stats need a type that is not keyed by `Role` (`sim/src/lib.rs:244–253`) before a paradox-born can join a crew, and the Twinned needs one body with shared health and carry. No sim change is needed for the Stray: it is an ordinary kind.
8. **Housekeeping.** `content/README.md` says every ruleborn carries `conflict_severity`, but `ruleborn.json` has no such key (it has id, name, role, school, source, look, proportions, personality, at_home, ability, resists, best_at, sound, size, flies). The README is stale.

## 6. What to build from, and what to leave

- **Build from the sheets as visual reference:** sculpts, silhouettes, palettes (apart from finding 5), expressions, turnarounds, clip choreography, the form treatment (material plus one accessory), the guard sash and lantern, squint tests, and the rig weights `w`.
- **Build from the document:**
  - stats (§11.1 and §11.8)
  - card text (§11.11)
  - role accessories and school marks (§21.6 and §5.2)
  - the Twinned's and Stray's rules
  - law creatures (§7.7) and wildlife (§5.7 scenery)
  - no variants
- **Make first:** the export pipeline (finding 11). Then a generated-content check that each exported model's clip list, accessories and marks match content.
