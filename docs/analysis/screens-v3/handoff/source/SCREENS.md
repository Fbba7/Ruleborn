# Ruleborn screens

Every screen in the order of the prototype's index. "Source" is the file to open and the `data-screen-label` to search for; all exact sizes, colours and copy are in that element's inline styles. "Must show" is the content GDD 23.2 requires on the screen.

The nav bar's five tabs open: **Islands** → 01 Universe map, **Laws** → 13 Law collection, **Heist** → 08 Observatory, **Crew** → 10 Roster, **Friends** → 27 Friends. The Crew tab hosts a hub with Roster · Sages · Forms, and the Laws tab a hub with All laws · Harmony · Lab, shown as a gold segmented control under the header.

The heist loop is: 01 Universe map → 08 Observatory → 09 Scout report → 06 Heist planner → 22 Landing picker → 02 Heist → 07 Heist result.

## 01 · Universe map
- **Purpose:** Home. See every realm and link at once.
- **Must show:** Realms with their laws, links, strain band, faults, alerts, resources, heist button.
- **Interactions:** Tap an island label to open it. Plan a heist starts the loop.
- **Reached from:** the **Islands** tab of the nav bar.
- **Source:** `Ruleborn Screens v3.dc.html` → `data-screen-label="01 Universe map"`

## 02 · Heist
- **Purpose:** Play it.
- **Must show:** At most eight controls, clock, alarm meter, vision cones, loot, Vault progress.
- **Interactions:** Tap a crew member in the world, then the ground, to send it; tap two to move them together. Hold the ground to sneak, walk or run. Tap a portrait to fire that creature’s ability: two uses, 10 s apart. A creature at zero health is down for 10 s; stand next to it for 3 s to revive it. Get out calls the skiff: 20 s at the Heart.
- **Source:** `Ruleborn Screens v3.dc.html` → `data-screen-label="02 Heist"`

## 03 · Law card (overlay)
- **Purpose:** Explain one law in seconds.
- **Must show:** Icon with school shape, one-line rule, looping preview, rank, pages.
- **Interactions:** Opens over any screen from a law chip or banner.
- **Source:** `Ruleborn Screens v3.dc.html` → `data-screen-label="03 Law card"`

## 04 · Realm view
- **Purpose:** Build and shape one realm.
- **Must show:** Grid, terrain and budget, buildings, workers, pylons, wards, guard posts.
- **Interactions:** Tap a law chip to watch it play out. Tap a building for workers and upgrades; hold to move it. Pinch to zoom, twist to turn.
- **Source:** `Ruleborn Screens v3.dc.html` → `data-screen-label="04 Realm view"`

## 05 · Weaving
- **Purpose:** Put laws into slots.
- **Must show:** One big law card with its looping preview, cost, strain and ready time; the realm tapestry of woven slots; harmonies and clashes with woven laws; a deck of the other laws.
- **Interactions:** Tap a card in the deck to inspect it. Swipe the big card up into the empty slot, or hold the button, to weave.
- **Source:** `Ruleborn Screens v3.dc.html` → `data-screen-label="05 Weaving"`

## 06 · Heist planner
- **Purpose:** Plan the run.
- **Must show:** Entry, route, crew, Sage, casts, clock, unfamiliar laws flagged.
- **Interactions:** Swipe the landing cards or tap a realm on the 3D chart to land there; the skiff route, laws and risk update. Tap crew to seat or bench; without a Carrier you cannot launch.
- **Source:** `Ruleborn Screens v3.dc.html` → `data-screen-label="06 Heist planner"`

## 07 · Heist result
- **Purpose:** Celebrate or learn.
- **Must show:** The outcome and its multipliers; the decisive moment with a 3-second replay; Starlight, Essence and Renown; entry fee; the law to study; rest for every crew member; Was this worth your time?.
- **Interactions:** Switch Clean, Loud, Partial or Foiled in Tweaks. Pick the law to study.
- **Source:** `Ruleborn Screens v3.dc.html` → `data-screen-label="07 Heist result"`

## 08 · Observatory
- **Purpose:** Choose a target.
- **Must show:** Name, Keeper level, realms, Renown and rough loot only; depth and why it was offered; Trace and echo marks; entry fee; drifting ruins apart.
- **Interactions:** Swipe between targets. Scout to see laws and guards. Refresh costs 50 Aether, doubling each time in the hour.
- **Reached from:** the **Heist** tab of the nav bar.
- **Source:** `Ruleborn Screens v3.dc.html` → `data-screen-label="08 Observatory"`

## 09 · Scout report
- **Purpose:** Read their laws.
- **Must show:** Per realm: sky banner with guard and ward counts, law cards with live previews and known/new tags, guards by role with patrol notes, wards by type, crew matchups.
- **Interactions:** Switch realms along the top; tap a law for its card; Plan lands you at that realm.
- **Source:** `Ruleborn Screens v3.dc.html` → `data-screen-label="09 Scout report"`

## 10 · Roster
- **Purpose:** Who does what.
- **Must show:** Every character’s state, rest timers, one-tap reassign.
- **Interactions:** Tap a card or the arrows to put a Ruleborn on stage. Assign, Recall or Wake them; Level up glows green when XP is full. Sort cycles Level / State / School; locked silhouettes show the kinds you haven’t hatched.
- **Reached from:** the **Crew** tab of the nav bar.
- **Lives in:** Crew hub (tabs Roster · Sages · Forms).
- **Source:** `RulebornMeta.dc.html` → `data-screen-label="10 Roster"`

## 11 · Character
- **Purpose:** One ruleborn in detail.
- **Must show:** School, role, ability, traits, level, best work.
- **Source:** `RulebornMeta.dc.html` → `data-screen-label="11 Character"`

## 12 · Sage hall
- **Purpose:** Heroes.
- **Must show:** Powers, levels, guardian choice.
- **Lives in:** Crew hub (tabs Roster · Sages · Forms).
- **Source:** `RulebornMeta.dc.html` → `data-screen-label="12 Sage hall"`

## 13 · Law collection
- **Purpose:** The collection.
- **Must show:** Launch 24 laws by school and rank, chapters, “?” for unknown, resonances, mastery.
- **Reached from:** the **Laws** tab of the nav bar.
- **Lives in:** Laws hub (tabs All laws · Harmony · Lab).
- **Source:** `RulebornMeta.dc.html` → `data-screen-label="13 Law Codex"`

## 14 · Resonance Lab
- **Purpose:** Watch two laws meet.
- **Must show:** Test realm with two law pedestals, settle time as the clue, all 12 resonances shown as locked cards, found cards fly to the shelf.
- **Lives in:** Laws hub (tabs All laws · Harmony · Lab).
- **Source:** `RulebornMeta.dc.html` → `data-screen-label="14 Resonance Lab"`

## 15 · Defence curation
- **Purpose:** Make the generated defence your own.
- **Must show:** Your real Heart island in 3D: hold gauge against the fair band, sneak routes drawn, one guard cone at a time, ghost test run; layout, laws, posts and word-list name.
- **Source:** `RulebornMeta.dc.html` → `data-screen-label="15 Defence curation"`

## 16 · Rehearsal and defence log
- **Purpose:** Test and learn defence.
- **Must show:** Simulated crew choice, route replay, raids on you, trace.
- **Source:** `RulebornMeta.dc.html` → `data-screen-label="16 Rehearsal and defence log"`

## 17 · Season
- **Purpose:** Long goals.
- **Must show:** Starpass track with free and premium lanes, claim reveals, daily/weekly/era quests that fill the pass, league road.
- **Source:** `RulebornMeta.dc.html` → `data-screen-label="17 Season"`

## 18 · Shop
- **Purpose:** Cosmetics.
- **Must show:** Sets with real prices, previews on your universe, spending cap for minors.
- **Source:** `RulebornMeta.dc.html` → `data-screen-label="18 Shop"`

## 19 · Settings and wellbeing
- **Purpose:** Control the experience.
- **Must show:** Reminder time, play-time reminders, notifications, accessibility, languages.
- **Source:** `RulebornMeta.dc.html` → `data-screen-label="19 Settings and wellbeing"`

## 19b · Profile and stats
- **Purpose:** Your record.
- **Must show:** League and rating trend, heist and defence split, records, battle log with replays, collection and badges.
- **Interactions:** Tap your portrait on the Universe map, or the star after a heist.
- **Source:** `RulebornMeta.dc.html` → `data-screen-label="19b Player stats"`

## 20 · First launch
- **Purpose:** Age check and the first session.
- **Must show:** Age band check, then the moments in section 16.
- **Source:** `RulebornMeta.dc.html` → `data-screen-label="20 First launch"`

## 21 · Terrain editor
- **Purpose:** Shape a realm.
- **Must show:** 39 features by family, terrain points left, route check, live guard-sight preview.
- **Source:** `RulebornMeta.dc.html` → `data-screen-label="21 Terrain editor"`

## 22 · Landing picker
- **Purpose:** Choose where to land.
- **Must show:** Every outer realm’s edge, what guards would hear, and the heist clock for each choice.
- **Interactions:** Tap an island or swipe the cards to compare edges; the route redraws.
- **Source:** `Ruleborn Screens v3.dc.html` → `data-screen-label="22 Landing picker"`

## 23 · Harmony view
- **Purpose:** See how laws combine.
- **Must show:** Notes on every law, harmonies and clashes per realm, resonances and chords.
- **Interactions:** Switch realms to see a first-time harmony reveal. Tap a combination below the island to highlight its beam, or a law card to open it. Tidehold sounds a chord; Verdant and Lantern Vale clash.
- **Lives in:** Laws hub (tabs All laws · Harmony · Lab).
- **Source:** `RulebornMeta.dc.html` → `data-screen-label="23 Harmony view"`

## 24 · Island Workshop
- **Purpose:** Build, test and publish islands.
- **Must show:** Creator ladder (18.7), publishing checks, fun / clever / fair ratings, completions and the weekly spotlight (18.6).
- **Interactions:** Tap the red “Name & cover” check to pick a name from word lists, then Publish. Tap the creator card for the ladder, Glass Maze for its stats, or any island in Discover for its details.
- **Source:** `RulebornMeta.dc.html` → `data-screen-label="24 Island Workshop"`

## 25 · Forms album
- **Purpose:** The creature collection.
- **Must show:** 54 forms by kind and note, how to hatch each, trades.
- **Lives in:** Crew hub (tabs Roster · Sages · Forms).
- **Source:** `RulebornMeta.dc.html` → `data-screen-label="25 Forms album"`

## 26 · Share sheet
- **Purpose:** Share a moment or a challenge.
- **Must show:** The game-cut 15-second heist clip with laws labelled, your island as a challenge, the matching-cosmetic invite (17.6) and age-band limits (20.7).
- **Interactions:** Switch between the three best moments, post the clip to the Beacon, then pick friends and send your island as a challenge.
- **Source:** `RulebornMeta.dc.html` → `data-screen-label="26 Share sheet"`

## 27 · Friends
- **Purpose:** Play together.
- **Must show:** Who’s online, the friends’ feed, friendly heists that take nothing (12.11), cosmetic gifts, preset pings, invites and add-by-code (17.6), block and report (17.8).
- **Interactions:** Tap a friend at the top for their island, record, pings and a friendly heist. Raid back from the rematch card in the feed; add friends by code on Invite.
- **Reached from:** the **Friends** tab of the nav bar.
- **Source:** `RulebornMeta.dc.html` → `data-screen-label="27 Friends"`

## Notes for Godot
- Build each screen as its own scene (`res://screens/<name>.tscn`) under one `Control` root that keeps the nav bar; switch scenes with the 0.3 s fade-and-scale described in the README.
- 3D screens (01, 02, 04, 06, 09, 15, 21, 22, 23) put a `SubViewport` with the island scene behind the UI layer, so taps that miss the UI reach the 3D world.
- Cards, chips and buttons repeat across screens; make them reusable scenes with a shared `Theme` (gold button, violet button, cream card, dark card, segmented tabs, pill).
