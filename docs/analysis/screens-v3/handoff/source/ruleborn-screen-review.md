# Ruleborn Screen Review and fix brief

For Claude Design. Update the Ruleborn screens in this project. Keep the art direction, palette, characters and icons. Part 1 is the full review of the current screens against the Ruleborn design document v3.5. Part 2 is the specification for the screens to redo and the two new ones. Numbers in brackets, such as (12.7), are sections of the design document. Where a screen disagrees with this file, this file wins.

# Part 1. The review

All 28 gameplay screens, the Characters and Icons sheets, and the playable parts (the running heist, both result outcomes, the settings tabs, rehearsal) were rendered and played, then checked rule by rule against the design document.

Verdicts: 5 rework, 15 fix, 2 not designed, 6 keep, small fixes.

## Fix first

Ordered by how much of the game each one changes.

### 1. Theft reads as two-way

- **The screens show:** 01 Universe map shows “Marta raided Verdant −1,240 Essence” with a Revenge button; the caught result shows “−672 lost”; Defence curation and the Terrain editor mark tiles “STOLEN”; Profile counts “Laws stolen”; the title screen says “Steal them”.
- **The document says:** A defender loses nothing (13.2). The answer to being raided is Trace: one shot at the raider within 24 hours, free scout, no entry fee (12.3). A failed raid costs the haul and the entry fee, never progress (12.9, 12.14). Laws are learned from pages, not taken.
- **Screens:** 01 Universe map, 07 Heist result, 15 Defence curation, 20 Profile and stats, 21 First launch, 22 Terrain editor

### 2. The heist HUD breaks the control model

- **The screens show:** Twelve tap targets (Sneak, Walk, Run, All crew, four ability labels, Sage, Cast, Get out and the law banner). Abilities called Leap, Wade, Shield (“blocks one alarm”) and Return (“rewind 3 s”). Three hearts and stamina per creature. Three-star objectives.
- **The document says:** At most eight controls (12.7). Gait is a held tap on the ground, with no gait button (12.18). Each kind has one ability from 11.2, two uses with a 10-second lockout; Rewind was cut. Health is per role, 120 to 420, and a downed creature has 10 seconds before capture (12.20). Outcomes are Clean, Loud, Partial and Foiled (12.9).
- **Screens:** 02 Heist

### 3. Money buys progress on the season track

- **The screens show:** Season: “+5 tiers now · €5.99” and a “Legendary · this season only” robe. Shop: daily cosmetics priced in Starlight.
- **The document says:** Nothing skips waiting for money and nothing is sold that the free track pays in pages or Essence (20.3, 22.1). Nothing in a season expires (18.8). Cosmetics are priced in Starglass only (9.5).
- **Screens:** 17 Season, 18 Shop

### 4. Protections for 13 to 15 can be switched off

- **The screens show:** Settings shows the player as 13–15, yet the Wellbeing tab offers Off, 45 and 90 for the play-time reminder and an Off switch for quiet hours. The Shop shows no spending cap and the Profile, private at that age, has a Share button.
- **The document says:** For 13 to 15: a reminder every 60 minutes, no notifications 21:00–08:00, a €25 monthly cap with family approval, a private profile (20.2). The design's own Account tab lists these as fixed, so the two tabs disagree.
- **Screens:** 18 Shop, 19 Settings and wellbeing, 20 Profile and stats

### 5. The Observatory leaks the paid scout and breaks the target band

- **The screens show:** Cards show guard counts and law icons before scouting; the targets wear level badges 4 to 7 for a level-24 Keeper; reroll costs 400 Starlight; a Revenge ribbon; no depth and no reason shown.
- **The document says:** Free information is name, Keeper level, realms, Renown and a rough loot estimate; laws and guards are the paid scout (12.4). Targets sit within 3 Keeper levels (12.3). Refreshing costs 50 Aether, doubling within the hour (12.3). Each card shows its depth and why it was offered (12.15, 12.22).
- **Screens:** 08 Observatory

### 6. The heist route disagrees with the target

- **The screens show:** Marta's universe has four realms in the Observatory and Scout report, but the Planner and Landing picker offer six outer realms. The Scout report says “Land here” on the Heart. Clocks run 140 to 210 s. Crew is capped at 4.
- **The document says:** Skiffs cannot land on the Heart (5.4). The clock is 150 s plus 15 s per link to the Heart, at most 240 (5.4). A level-24 Keeper takes a crew of 5 (12.5).
- **Screens:** 06 Heist planner, 09 Scout report, 23 Landing picker

### 7. Law data has drifted from the Codex

- **The screens show:** Five ranks and eight stability costs are wrong, every law shows pages out of 10, tier III cost is ignored, a third Heart slot appears, crown slots are missing, and Day and night, Tidemark and Current are offered at launch.
- **The document says:** Ranks and costs are in 7.4; pages to restore are 10, 20, 35 or 60 by rank (7.6); tiers multiply cost by 1.3 and 1.6 (5.5); the Heart has two realm slots plus one or two crown slots at the Spire (5.1); only the launch 24 exist at launch (7.10).
- **Screens:** 03 Law card, 05 Weaving, 13 Law collection, 24 Harmony view

### 8. Results ignore the outcome rules

- **The screens show:** Stars graded by loot; rest of 12 to 18 minutes with one creature “Ready”; +3 pages after a loud raid and after being caught; Renown −6 when caught; “Raid again” with the crew resting.
- **The document says:** Rest is 45, 60 or 180 minutes for every crew member (11.6). Studying a crossed law gives 2 pages, 3 if clean, 1 if foiled (7.6). Foiled costs a flat 8 Renown (12.9). Every session can end with “Was this worth your time?” (20.3).
- **Screens:** 07 Heist result

### 9. Two flows are not designed

- **The screens show:** The Defence log tab does not open, and First launch is a title screen only.
- **The document says:** After every raid the defender sees the haul the defence denied, how long it held the crew, where the crew was seen and which wards fired (13.2), with Trace. First launch is the age-band check (20.1) and the ten-minute first session (16).
- **Screens:** 16 Rehearsal and defence log, 21 First launch

## Numbers that disagree with the document

Each row is a value a player would see. Most come from the prototype carrying its own copies of the tables.

| Screen | Shows | Should be | Rule |
|---|---|---|---|
| 01 | Aether 38.2k | Storage tops out at 34,000, at Spire 10 | 10.2 |
| 01 | Six outer realms at Keeper level 24 | The sixth opens at Keeper level 28 | 5.2 |
| 01, 04 | “Skyfield strained” with fault badges; Realm view says Humming 82% | Strain is universe-wide; faults open only from 100% | 5.5 |
| 03 | Stillness at tier III: 15 points, 600 Aether | 15 × 1.6 = 24 points, so 960 Aether | 5.5, 5.6 |
| 04 | Heart “Laws 2/3”; “Builders 2/2” | Two realm slots plus crown slots; building is instant | 5.1, 10 |
| 05 | +15% strain lands in Steady, from 82% | 97% is Brimming | 5.5 |
| 05 | Half gravity 960 Aether | 12 points × 40 = 480; 600 even with a dissonance | 5.6, 7.4 |
| 06 | Crew 4/4 | Five from Keeper level 16 | 12.5 |
| 07 | Rest 18, 18 and 12 min; Hollow ready | 45 clean, 60 loud, 180 caught, for every crew member | 11.6 |
| 07 | +3 pages after a loud raid and after being caught | 2 pages, 3 if clean, 1 if foiled | 7.6 |
| 07 | Caught: Renown −6 | Foiled: a flat −8 | 12.9 |
| 08 | Reroll 400 Starlight | 50 Aether, doubling with each refresh in the hour | 12.3 |
| 08 | Targets at Keeper levels 4 to 7 for a level-24 player | Within 3 Keeper levels | 12.3 |
| 08 | Sky ruin pays 2,200 Starlight | Drifting ruins pay pages and Essence, no Renown | 12.10 |
| 10, 11 | XP bar; level 6 for 1,250 Essence | No XP; level 6 costs 150 × 1.55⁴ ≈ 866 Essence | 11.4 |
| 11 | Ability usable “once a heist” | Two uses, 10-second lockout | 11.2 |
| 11 | Skyskipper resists no-jump zones | It is unbothered by Leapfrog's noise | 11.2 |
| 12 | Sage level 4 of 10, levels with heists | Levels 1 to 40, with Insight | 11.7 |
| 13 | Inward pull Uncommon; Haste, Static, Thorns, Echoes Common | Deep; Rare, Rare, Rare; Uncommon | 7.4 |
| 13 | Costs: Bounce 10, Inward pull 15, Brittle stone 12, Haste 11, Static 12, Kinship 10, Thorns 13, Echoes 14 | 14, 22, 10, 18, 16, 14, 15, 18 | 7.4 |
| 13 | Pages out of 10 for every law | 10, 20, 35 or 60 by rank | 7.6 |
| 14 | Settle time 2 to 12 h per resonance | The Lab's level sets it: 8 h at level 1 down to 3 h at level 5 | 10.2 |
| 17 | 30 tiers | 50 tiers | 18.2 |
| 20 | Rating 1,460 | Ratings stay internal; show Renown | 12.15 |
| 22 | 80 terrain points in the Heart | 40 + 10 per Spire level, so 100 if the Heart's “6” is Spire 6 | 6.1 |
| 23 | Clocks 140 to 210 s | 150 + 15 per link: 165 s for one hop, 180 s for two | 5.4 |
| 23 | Landing noise +25% and +40% | Heard or not; heard means guards within 6 tiles start at 250 of 1,000 suspicion | 5.4 |
| 24 | Chord shown as 10% cheaper | It also draws 192 stability while it sounds | 8.5 |
| 25 | 62% “fair” for level 6 | Authored islands must hold 30 to 45% at every level | 13.2 |

## Not designed yet

States and flows the document requires that no screen shows.

- **Defender's raid report.** Haul denied, time held, where seen, wards fired, and the Trace button (13.2, 12.3). The Defence log tab does not open.
- **First session.** Age-band check (20.1), the ten-minute script (16) and the notice before a first raid that ends the 72-hour protection.
- **Vault phase.** Who cracks and the assist bonus (11.1), the crack-reach ring (12.6), the load-target control (12.19), storehouses on the route.
- **Heist edge states.** Split crew and Regroup (12.7), downed with 10 s to capture and revive (12.20), skiff call with its 5 or 20 s arrival (5.4), the clock's red last 30 s, a pylon break and its page, the Sage wheel and cooldown dial (11.7, 21.8), the cast wheel and circle (12.5).
- **Planner fields.** Route, Sage, casts, entry fee (2% of Starlight, 100 to 25,000) and flags on unfamiliar laws (12.5, 23.2).
- **Crown slots.** One crown slot at Spire 2 and a second at Spire 5 (5.1). No screen shows them.
- **Paradox warning.** The Lab warns when a pairing is unstable (7.5).
- **Landscape and left-handed.** Landscape layout (23.3) and the mirrored heist HUD (12.7). Settings has the switch, no screen shows the result.
- **Interactions.** Eleven screens still say “coming in a later turn”: 11 to 19, 21, 22 and 26.
- **Loss and retry.** “Was this worth your time?” (20.3) and the easier version offered after two failures (12.12, 12.14).

## Improvements

Changes beyond compliance that would make the screens easier to play and keep them in step with the document.

- **One planning funnel.** Landing is chosen in three places today: the Scout report's “Land here”, the Planner's landing cards and the Landing picker. Keep the Landing picker as the only place and give the Planner a summary bar that always shows entry, route, crew, Sage, casts, clock and entry fee.
- **A heist HUD built on the portraits.** Tap a portrait to fire its ability, with two pips and a lockout ring on the portrait; hold on the ground for gait; tap two portraits to move them together. Clock and alarm go top centre, Sage and Get out come in from the corners, and every visible guard gets its cone and an awareness meter.
- **Results that teach.** Lead with the grade and its multipliers in one line, let the player pick the law to study, put the 3-second decisive moment at the top and end with a one-tap “Worth your time?”. On a loss, list what was kept. The caught screen already names the decisive moment well.
- **Feed the prototype from the document.** Nearly every number above is drift. Export the laws, ruleborn, buildings and constants from the design document as JSON and have the prototype read them, so a screen cannot disagree with the document. The document's build already writes constants.json.
- **One player, one age band.** Wren is 13–15 in Settings and Share and an adult everywhere else. Make the adult the default and add a 13–15 switch that changes every protected element at once: reminder, quiet hours, cap, private profile, preset chat.
- **Bigger text and targets.** 21.8 sets 13 pt as the smallest text and 16 pt for body text; the heist needs 48-pt targets. Every measured screen falls below (table below).
- **One set of school shapes.** Use 5.2's shapes everywhere: circle, chevron, cube, hourglass, bolt, leaf, eye. The Icons sheet draws Motion as a star and Spirit as a flame; the colour-blind panel uses a different set again.
- **Words for systems that exist.** Steal, stolen, revenge, rating, XP, power and builders all name systems the game does not have. Use pages, loot carried out, Trace, Renown and Essence levels.

## Text and tap sizes, measured

21.8 sets 13 pt as the smallest text; 12.7 asks for 48-pt targets in the heist. 44 pt is the platform minimum used below.

| Screen | Text below 13 pt | Smallest | Tap targets under 44 pt |
|---|---|---|---|
| 01 Universe map | 38 of 47 (81%) | 8.5 pt | 11 of 21 |
| 02 Heist | 39 of 48 (81%) | 9 pt | 8 of 12 |
| 03 Law card | 62 of 86 (72%) | 6.5 pt | 10 of 26 |
| 04 Realm view | 15 of 17 (88%) | 9 pt | 4 of 8 |
| 05 Weaving | 34 of 42 (81%) | 8 pt | 1 of 8 |
| 06 Heist planner | 24 of 29 (83%) | 8 pt | 2 of 10 |
| 07 Heist result | 27 of 36 (75%) | 8.5 pt | 0 of 5 |
| 08 Observatory | 29 of 37 (78%) | 8.5 pt | 5 of 14 |
| 09 Scout report | 49 of 57 (86%) | 8 pt | 3 of 9 |
| 11 Character | 25 of 32 (78%) | 7.5 pt | 5 of 8 |
| 12 Sage hall | 35 of 39 (90%) | 9 pt | 9 of 22 |
| 13 Law collection | 65 of 74 (88%) | 7.5 pt | 16 of 30 |
| 14 Resonance Lab | 57 of 62 (92%) | 8 pt | 4 of 30 |
| 15 Defence curation | 26 of 35 (74%) | 7.5 pt | 4 of 10 |
| 16 Rehearsal | 22 of 27 (81%) | 8.5 pt | 2 of 7 |
| 17 Season | 25 of 49 (51%) | 8 pt | 7 of 19 |
| 18 Shop | 28 of 37 (76%) | 8.5 pt | 5 of 14 |
| 19 Settings | 38 of 46 (83%) | 8.5 pt | 11 of 16 |
| 20 Profile | 35 of 45 (78%) | 8 pt | 37 of 38 |
| 21 First launch | 2 of 8 (25%) | 10 pt | 0 of 1 |

Measured in the rendered prototype on its 390 × 844 pt phone frame: the computed size of every visible text run, and the box of every button or tappable element. Counts include badges and the status bar. Roster was mid-transition when measured and is left out; 22 to 28 were not measured.

## Screen by screen

### 01 Universe map — Rework

- The raid toast takes Essence from you and offers Revenge. Defenders lose nothing (13.2); show what the defence denied and a Trace button (12.3).
- “Skyfield strained” with fault badges, while the Realm view reads Humming 82%. Strain belongs to the universe and faults open only from 100% (5.5).
- Six outer realms at Keeper level 24; the sixth opens at 28 (5.2). Aether 38.2k is above the 34,000 ceiling (10.2).
- The toast sits on top of Collect. 21.8 puts the stability band top centre, build, weave and terrain bottom left and a skiff-shaped Heist button bottom right; either follow it or change the document.

### 02 Heist — Rework

- Twelve tap targets against a cap of eight (12.7); the gait row breaks 12.18, which puts gait on a held tap.
- Leap, Wade, Shield and Return are no creature's ability. The crew on screen should fire their 11.2 abilities; Pip the Skyskipper's is Stuff the satchel. Rewind was cut.
- Hearts and stamina replace role health and the 10-second downed state (12.20).
- Three-star objectives replace the four outcomes (12.9), and “Out before 1:00” turns the soft clock into a target.
- Missing: clock and alarm at top centre (21.8), readable cones with awareness meters, ability pips and lockout ring, the crack-reach ring and the load target.
- Ability labels are 21 pt tall; Sage and Get out sit in the bottom corners, which 12.7 rules out.

### 03 Law card — Fix

- Tier III Stillness costs 24 stability and 960 Aether, not 15 and 600 (5.5, 5.6).
- Missing its note, Hush, and the looping preview (23.2); the art is a pause sign rather than Time's hourglass.
- “Oak frame 10/20” and “STAB” are unexplained; the smallest text is 6.5 pt.

### 04 Realm view — Fix

- “Laws 2/3”: the Heart has two realm slots, and crown slots live at the Spire (5.1).
- “Builders 2/2” implies build timers. Building and upgrading are instant (10).
- Workers, pylons, wards and guard posts cannot be told apart, and 23.2 asks for all four.

### 05 Weaving — Rework

- A third Heart slot, and no crown slots (5.1).
- “+15% → Steady” from a universe at 82% Humming. It would land at 97%, Brimming (5.5).
- Deck prices do not follow 40 Aether per stability point: Half gravity shows 960 for a 12-point law (5.6).
- Day and night, Tidemark and Current are offered though they do not ship at launch (7.10); Inward pull is badged Uncommon, but it is Deep.
- 23.2 asks for two or three recommended laws. The deck shows eighteen with no recommendation.
- Right: Glowing dark at 440 Aether and 10 minutes.

### 06 Heist planner — Fix

- Six landing realms for a universe with three outer realms.
- Crew 4/4; a level-24 Keeper takes five (12.5).
- Missing route, Sage, casts, entry fee and flags on unfamiliar laws (23.2). Landing is an edge tile, not a realm (5.4); leave it to the Landing picker.

### 07 Heist result — Rework

- Stars graded on loot. A getaway at 2 of 6 alarm is a Loud outcome, worth ×0.7 haul and ×0.8 Renown (12.9); say so.
- Rest shows 12 to 18 minutes and Hollow ready. Every crew member rests 45, 60 or 180 minutes (11.6), so “Raid again” needs another crew.
- The study is chosen by the player from the laws crossed: 2 pages, 3 if clean, 1 if foiled (7.6). Both variants show +3.
- Caught variant: shows “−672 lost” and Renown −6. A foiled raid loses the haul and the entry fee, and costs a flat 8 Renown (12.9).
- Missing “Was this worth your time?” (20.3).
- Prototype: a failed heist still opens the win screen, because the fail flag it passes is never read.

### 08 Observatory — Fix

- Guards and law icons appear before a paid scout (12.4).
- Target badges 4 to 7 for a level-24 Keeper; the band is 3 levels (12.3).
- Reroll costs 400 Starlight; the document says 50 Aether, doubling within the hour (12.3). Revenge should be Trace.
- “Sky ruin” pays Starlight among player targets. Ruins pay pages and Essence, no Renown, at three labelled difficulties (12.10, 12.12). Echoes need a mark.
- No depth and no reason offered on the card (12.15, 12.22); “+20% bonus” and the stars are unexplained.

### 09 Scout report — Fix

- “Land here · West edge, hedges” on the Heart. Skiffs cannot land there (5.4).
- Counts without positions are right (12.4); keep the 3D view free of guard and ward positions.
- Crew reads Mo, Bramble, Facet here and Pip, Mo, Bramble, Hollow on the next screens.
- The screen's job is to read their laws, yet the law cards sit behind tabs. Lead with them.

### 10 Roster — Fix

- XP bar and level up for 1,250 Essence. Levels are bought with Essence alone; level 6 costs about 866 (11.4).
- “Power 1,705” is a single score the document never defines, and it invites ranking creatures that 11.11 says no creature beats. Show role stats.

### 11 Character — Fix

- “Once a heist”; it is two uses with a 10-second lockout (11.2).
- Skyskipper is unbothered by Leapfrog's noise; it does not resist no-jump zones (11.2).
- Same XP and power problem as the Roster. Interactions are not built.

### 12 Sage hall — Fix

- Level 4 of 10, “levels with heists”. Sages level 1 to 40 with Insight (11.7).
- The Archivist's powers and uses match 11.7.

### 13 Law collection — Fix

- Ranks: Inward pull is Deep; Haste, Static and Thorns are Rare; Echoes is Uncommon (7.4).
- Eight costs differ from 7.4 (see the numbers table).
- Pages show x/10 for every law; restoring takes 10, 20, 35 or 60 by rank (7.6).
- Chapters here are schools. In the document chapters are unlock steps by Keeper level, and each school album pays at 2, 4 and 8 laws restored (7.6).
- Motion is marked Complete with two laws still restoring, and Frictionless is woven in Emberreach at 9 of 10 pages.

### 14 Resonance Lab — Fix

- Each resonance has its own settle time of 2 to 12 hours. The Lab's level sets experiment time, 8 hours down to 3 (10.2).
- “Recipe unique to you” contradicts the fixed, named pairs in 8.4 and would break shared guides.
- Missing the unstable-pairing warning for paradoxes (7.5) and the 3 pages an empty experiment returns (7.6).

### 15 Defence curation — Keep, small fixes

- The best screen in the set: hold gauge against 30 to 45%, sneak routes, alternatives with their own hold rates.
- Points A to D on the Heart read as landing spots. Raiders reach the Heart over links (5.3, 5.4); draw them as bridge arrivals.
- “STOLEN” tags: nothing is stolen from a defender.
- Missing: change one law with a fast preview, and naming from word lists (23.2, 13.3).

### 16 Rehearsal and defence log — Not designed

- Rehearse works. Defence log does not open, and it is where the raid report and Trace live (13.2, 12.3).
- The flat 2D map is the only non-3D island in the set.

### 17 Season — Rework

- “+5 tiers now” for €5.99 buys progress, and the free lane holds pages and Essence (20.3, 22.1).
- “Legendary · this season only”; nothing in a season expires (18.8).
- 30 tiers instead of 50 (18.2). Star chests with “no limit” clash with the caps on repeatable rewards (20.3); if their contents are random, show the odds.

### 18 Shop — Fix

- Daily picks are priced in Starlight; cosmetics are Starglass only (9.5).
- The struck-through €10.40 should be a real earlier price or go.
- No spending cap shown for a 13–15 player (20.2).
- Right: a euro figure beside every Starglass price, and “back again later, no rush”.

### 19 Settings and wellbeing — Fix

- At 13–15 the reminder can be set to Off, 45 or 90 and quiet hours can be turned off; 20.2 fixes both. The Account tab says they are fixed.
- The colour-blind panel's shapes do not match the school shapes in 5.2 or the Icons sheet.
- Purchases show Ask to Buy but not the €25 cap.
- The Access tab is thorough: text size, left-handed controls, reduced motion, captions.

### 20 Profile and stats — Fix

- “Rating 1,460”. Ratings stay internal (12.15); show Renown.
- Heist endings use their own categories; use Clean, Loud, Partial and Foiled.
- “Laws stolen” and a “16-day best streak”; the streak is weekly, four days in seven (14.6).
- Private for 13–15, yet it has Share. 37 of 38 tap targets are under 44 pt. The screen is not in 23.2.

### 21 First launch — Not designed

- Only a title screen. The age-band check (20.1) and the first session (16) are not designed.
- “Find them. Steal them.” Laws are not stolen; the document's line is “Your islands. Your rules. Their treasure.” (1.1).

### 22 Terrain editor — Keep, small fixes

- Families, budget, route check and the sight toggle are all there.
- “74 / 80” should say points left; the Heart's budget is 40 + 10 per Spire level (6.1).
- Same A to D markers and STOLEN tags as Defence curation.

### 23 Landing picker — Fix

- Clocks of 140 to 210 s ignore 5.4's 150 s + 15 s per link; 140 is below the floor.
- Noise as +25% and +40%. A landing is heard or not; heard means guards within 6 tiles start at 250 of 1,000 suspicion (5.4).
- Six realms for a four-realm universe.
- The side-by-side comparison and the way-home time are a good pattern; make this the only landing screen.

### 24 Harmony view — Fix

- Tidehold's chord is built from Day and night, Tidemark and Current, none of which ship at launch (7.10).
- The chord shows “−10%” but not its 192-stability draw (8.5), the cost that matters.
- Three laws in Tidehold need realm level 5 (5.2).

### 25 Island Workshop — Keep, small fixes

- “62% · fair · band for Lv 6”. Publishing checks a 30 to 45% hold, the same at every level (13.2).
- The creator ladder, word-list names and the clear-before-publish rule match 18.6 and 18.7.

### 26 Forms album — Keep, small fixes

- 54 forms and the outfit per completed kind match 11.10. Mark trades as arriving in version 1.1.

### 27 Share sheet — Keep, small fixes

- Age gating is right: at 13–15 clips stay inside the game (20.7).

### 28 Friends — Keep, small fixes

- Friendly heists are shown right: the friend loses nothing and earns a page per caught raider (12.11).
- “Its Swift trait came from her Skyfield's Haste”: Swift is a body trait, law-linked traits are a separate list (11.3), and Haste is a Time law.

## What already works

- The art direction is consistent and reads at a glance; the diorama islands show the idea without explaining it (23.4).
- Characters tab: all 18 kinds with the right role and school, and the Sages with the right unlock levels. Icons: 393 drawn on the 24-point grid (21.8).
- Defence curation: the hold gauge against the fair band, sneak routes and layout alternatives are the strongest screen in the set.
- Share sheet and Friends apply the age bands and friendly-heist rules exactly as 20.7 and 12.11 say.
- Settings Access: text size, colour-blind modes with shapes, left-handed controls, reduced motion and captions.
- The caught result names the decisive moment and gives one thing to try (12.13).
- Weaving shows cost, strain and time before committing, and Glowing dark's 440 Aether and 10 minutes are right.
- Workshop: the creator ladder and the publishing checks follow 18.6 and 18.7.

## Fixes for the design document

These are decisions for the design document, not for the screens; listed so nothing in the review is lost.

- 18.2 says the free season track pays pages, Essence and a stray; 18.8 says both tracks are cosmetic only. One sentence has to go.
- Profile and stats is not in 23.2. Add it with its must-show list (Renown, not rating) or cut the screen.
- The design's own “Must show” notes differ from 23.2 on several screens (Weaving, Heist result, Observatory, Resonance Lab, Defence curation, Season). Since the document is the single source, the notes should quote 23.2.

# Part 2. What to change

## Apply to every screen

- **Theft is one-way.** A defender never loses anything (13.2). Remove "raided you −X", "Revenge", "stolen" and "steal" everywhere. The answer to a raid is **Trace**: within 24 hours, target the raider once, with a free scout and no entry fee (12.3). Raiders carry out loot and study pages of laws; laws are never stolen.
- **Sizes.** No text under 13 pt; body text 16 pt (21.8). Tap targets at least 44 pt; heist controls at least 48 pt, and none in a screen corner (12.7).
- **School shapes** (5.2), the same on law cards, the Icons sheet and the colour-blind panel: Heart circle, Motion chevron, Matter cube, Time hourglass, Energy bolt, Life leaf, Spirit eye.
- **Demo player.** Wren is an adult (18+), Keeper level 24, with five outer realms (the sixth opens at Keeper level 28) and a crew of five.
- **Words.** Renown, not rating. No XP, no power score, no builders: levels are bought with Essence, and building is instant.
- **Laws at launch** (7.10): only these 24. Name (rank, stability cost, notes).
  - Motion: Bounce (Common, 14, Flow/Echo); Half gravity (Common, 12, Flow); Frictionless (Rare, 20, Flow/Spark); Inward pull (Deep, 22, Weight)
  - Matter: Brittle stone (Common, 10, Spark); Glass (Common, 12, Glow); Density (Uncommon, 20, Weight); Honeycomb (Uncommon, 17, Weight/Hush)
  - Time: Slow rivers (Common, 10, Weight); Stillness (Common, 15, Hush); Delay (Uncommon, 14, Veil/Hush); Haste (Rare, 18, Flow/Spark)
  - Energy: Glowing dark (Common, 13, Hush); Aurora (Uncommon, 18, Glow); Chain lightning (Uncommon, 19, Spark); Static (Rare, 16, Spark)
  - Life: Bloom (Common, 11, Bloom/Hush); Kinship (Common, 14, Bloom); Thorns (Rare, 15, Bloom/Weight); Regrowth (Rare, 16, Bloom/Echo)
  - Spirit: Whispers (Common, 16, Glow/Echo); Echoes (Uncommon, 18, Echo); Sleepwalk (Uncommon, 17, Hush/Echo); Soul swap (Rare, 20, Veil)
  - Pages to restore a law: 10 Common, 20 Uncommon, 35 Rare, 60 Deep (7.6).

## 02 Heist: redo the HUD

- **At most eight things to tap** (12.7): 3 to 5 crew portraits, Sage, Cast, Get out. While the crew is split, Regroup takes Get out's place.
- **Portraits are the abilities.** Tap a portrait to fire that creature's own ability (one per kind, from the Characters sheet; Pip the Skyskipper's is Stuff the satchel: loads at 60 a second for 5 s). Each portrait shows two pips with the number of uses left; a spent pip is hollow; a ring sweeps round the portrait during the 10-second lockout; a pause mark shows when four abilities are already ready (21.8). Drag a portrait onto the world to aim, or onto a fork to split the crew.
- **No gait buttons** (12.18). Hold on open ground to choose crouch, walk or run; a plain tap sends at the last gait. Tap two portraits to move them together, so the All crew button goes.
- **Sage** opens a wheel of its three powers; its portrait shows a 20-second cooldown dial (11.7). **Cast** opens a wheel of the player's one or two casts.
- **Layout** (21.8): clock and alarm meter (0 to 6) top centre; law banner top left; loot top right as two numbers, what the bags can still take and what is left to load, beside the Vault's progress; portraits bottom left; Sage, Cast and Get out bottom right, kept off the corners.
- **Health, not hearts.** A health bar per creature; roles differ (Warden 420, Scout 120). No stamina. A creature at zero health drops its loot and has 10 seconds before capture; an adjacent ally revives it in 3 seconds (12.20).
- **Guards.** Every visible guard shows its vision cone and an awareness meter.
- **Vault.** While anyone cracks, draw a ring 5 m round the Vault by walking path: guards inside it hear the cracking (12.6). Add the load target: how full the crew should be before it leaves (12.19).
- **Remove** the three-star objectives. The clock turns red for its last 30 seconds. Calling the skiff shows its arrival: 5 s at an outer realm, 20 s at the Heart (5.4).
- Add a left-handed, mirrored variant.

## 07 Heist result: win and caught

- **Headline is the outcome** (12.9), with its multiplier: Clean (haul ×1.0), Loud (haul ×0.7, Renown ×0.8), Partial (haul ×0.4, Renown ×0.5), Foiled (no loot, a flat −8 Renown). A getaway at 2 of 6 alarm is Loud.
- **The player picks which crossed law to study:** +2 pages, +3 if clean, +1 if foiled (7.6).
- **Every crew member rests:** 45 min after Clean, 60 after Loud, 180 if caught (11.6). Show "Raid again" only if an idle crew exists; otherwise "Pick a crew".
- **Entry fee line:** returned after Clean or Loud, half returned after Partial, paid to the defender after Foiled.
- **At the top:** the decisive moment with a 3-second replay, such as "Your Carrier was spotted crossing the open ledge at 0:48", plus one thing to try. Keep the Archivist card.
- **On a loss:** list what was kept (crew home, pages, Codex entries). Never show the player's own stock as lost.
- **At the end:** a one-tap "Was this worth your time?" (20.3).
- After two failures in a row against the same target, offer an easier version by name (12.12).

## 05 Weaving

- **Heart:** two realm slots, no third. Add the **crown slots** at the Spire: one from Spire level 2, a second from Spire level 5. A crown law works in every realm and costs double stability (5.1).
- **Prices:** Aether = 40 × stability cost. Stability cost = base cost × tier (1.0, 1.3 or 1.6), then the modifiers. The Glowing dark example is right: 11 points, 440 Aether, 10 minutes.
- **Strain is universe-wide.** After weaving, show the universe's new band, for example 82% + 15% = 97%, Brimming (5.5).
- Lead with two or three recommended laws. The deck holds launch laws only.

## 08 Observatory

- **Free on the card:** name, Keeper level, number of realms, Renown, rough loot. Laws, guards and wards appear only after a paid scout: 20 Aether a realm (12.4).
- **Targets** sit within 3 Keeper levels and 150 Renown of the player (12.3); for Wren, levels 21 to 27.
- Each card shows its **depth** (realms crossed to reach the Heart) and **why it was offered** (12.15, 12.22). Mark echo universes. A Trace ribbon replaces Revenge.
- **Refresh** costs 50 Aether, doubling with each refresh in the same hour.
- **Drifting ruins** sit apart from player targets: they pay pages and Essence, no Renown, at three labelled difficulties (12.10, 12.12).
- Show the entry fee: 2% of Starlight, 100 to 25,000.

## 17 Season

- **50 tiers** (18.2). Remove "+5 tiers now". Remove "this season only": unclaimed tiers stay claimable in a later season (18.8).
- Premium track: bought with Starglass, cosmetics only. Free track: pages, Essence and a stray.
- No countdowns or "last chance" banners. If star chests are random, show the odds and cap how many can be opened.

## New screen: Defence report (the Defence log tab in 16)

A list of raids on you. Each raid opens a report (13.2):

- the outcome;
- the haul the defence denied;
- how long it held the crew;
- where the crew was seen, on the island map;
- which wards fired and which guards caught anyone;
- a replay;
- a **Trace** button, live for 24 hours.

Raider names stay hidden while a raid is happening.

## New screen: First launch (21)

- **Age-band check** from the platform: under 13, 13 to 15, 16 to 17, or 18 and over. Under 13 is told the game is for 13 and up, and no account is made (20.1).
- **Title line:** "Your islands. Your rules. Their treasure." (1.1).
- **The first ten minutes** (16), one beat per frame:
  - 0:00 The Archivist catches a falling page: Half gravity.
  - 0:30 The player places it in the Heart; stones lift.
  - 1:15 Three ruleborn wake (Featherkin, Emberling, Tidewalker), each showing its ability once.
  - 2:00 First heist, into a Drifting ruin running Slow rivers.
  - 5:00 The haul unlocks Slow rivers; two strays follow the crew home.
  - 6:30 The Archivist hands over Bloom; it is woven into the Heart's second slot and the stability bar appears.
  - 7:00 Two ruins to choose from.
  - 10:00 The Lab names Mangrove banks; three daily goals appear.
