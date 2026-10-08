# v3.6's rule changes against the build, the register, and itself

Reader: v3.6 rules. Inputs read: docs/design/ruleborn-game-design-v3.6.txt (cited as §N.M, with v36.txt line numbers where a quote matters), the v3.4→v3.6 diffs, server/src/{track,shop,seasons,http,universe,keeper,service,matchmaking,notifications,db}.mjs, server/src/facts.json, client/scripts/{age_screen,settings,settings_screen,result_screen,heist_screen,track_screen}.gd, client/data/age_check.gd, client/app/router.gd, client/ui/tokens.json, client/i18n/strings.csv, sim/src/lib.rs, sim/src/laws_table.rs, content/*.json, tools/economy_model/{data,model,config}.py, docs/design/generated/pacing.md, tools/audit_register.py (as it stands in the working tree, with an empty `V36` layer), docs/decisions/{brief,answers}.json. The engine move (v3.5, Godot 4.7.2 + godot-rust v0.5.5 api-4-7) is out of scope here and is not re-planned; one stale sentence about it is noted in part 4.

Nothing in the repository was edited.

## 1. Summary

- v3.6 settles the free track: it keeps pages, Essence and a stray, and only the premium track is cosmetic (§18.8). The server already did this (server/src/track.mjs:49-58), so v3.6 now agrees with the build. G28 narrows but stays open. None of the track's figures entered the document: stars, tier price, catch-up formula and the rewards tier by tier are still missing. Of the doc edits in the owner's G28 answer (option B), only §18.8's rewording landed.
- §14.4's new row says the free lane gives "A few a season, not in the day counts below". The build gives 25 pages a season to engaged and regular players and 15 to casual ones (track.mjs:52). The published economy run also adds those pages to the Codex day counts (tools/economy_model/model.py:589-595, config.py:226-227). So "a few" and "not in the day counts" are both out of step with the build.
- The §23.5 adopted items are almost all unbuilt:
  - Profile and stats: no server read and no client route.
  - First-launch order: the age check goes straight to home (client/scripts/age_screen.gd:38-43).
  - Slower ruins: the client slows rehearsals instead (client/scripts/heist_screen.gd:205-207), and there are no ruins in the build.
  - Paradox-born numbers: no content table, and the sim's stats are keyed by role (sim/src/lib.rs:247).
  - Wildlife cues: no wildlife anywhere.
  - One data file: the client keeps design numbers in ui/tokens.json.
- The §23.2 rows v3.6 rewrote (result, settings, observatory, defence log) are far ahead of the built screens.
- Reading v3.6 against itself found new contradictions:
  - The Twinned's narrowed gift now doubles abilities it does not have (§11.8).
  - §11.7's new Sage rules ("each a change to a named parameter", "the one 20-second cooldown") contradict the four launch Sages' own powers and the same paragraph's levelling.
  - §18.8 still says "nothing in a season changes a heist" beside a free track that grants a stray, Essence and pages.
  - §9.1 still gives the free track Starglass and leaves it out of the sources of Pages and Essence, although §18.8 now names §18.2 as the home of what each track holds.
  - §21.9 still budgets 27 screens against §23.2's 28. C11 was fixed and is now reopened.
  - §23.5's "16 pt body" restates §21.8's "16 pixels".
  - The changelog line "No client code exists yet" is false.
- The §11.7 lockout question the brief raised checks out as consistent. "The crew's abilities have no cooldown" sits beside "the crew's ability lockouts" in the same paragraph, and §11.11 and §12.6 say the same.
- Every §23.5 figure checked against its home section matches: Aether storage, crown slots, Lab time, role health and role stat lines, landing noise, tiers, Flock and Swarm birth, and the 32% Quiet first law.

## 2. Each change: what v3.6 says, what the build does, what must change

### §5.7 Wildlife is scenery

v3.6 (v36.txt:1136): "Wildlife is scenery. No creature in the wildlife rows changes what a crew, a guard or a player can do, see or hear, and none looks like a law creature or a guard: puffballs belong to the Flock law (7.7), so Verdant's wildlife is bees and butterflies. Wildlife may show something that is already true — Skyfield's jellyfish drifting with the wind under Current, Emberreach's ash moths gathering a second before a vent bursts — because that adds no rule; perception is 12.17's alone." Verdant's row now reads "Bees and butterflies".

Build today:
- There is no wildlife in sim/, client/ or content/. A search for wildlife, jellyfish, moth, firefly, beetle, lanternfish, butterfly, bees and puffball finds nothing outside content/laws.json's Flock text.
- Flock exists only as a law. It is not at launch: sim/src/laws_table.rs:100 has `simulated: false, launch: false`.
- Current is not at launch either (laws_table.rs:68).
- The ember vent is a terrain row (content/terrain.json, "Bursts of flame every 8 seconds") with no simulation behind it.

What must change:
- Nothing to remove.
- When realm art arrives:
  - Wildlife is render-only, with no sim entity and no perception input.
  - Verdant gets bees and butterflies.
  - The Screens v3 wildlife mechanics listed in §23.5 are not ported: moths give raiders away, fireflies gather on anyone hiding, beetles blur raiders behind glass, lanternfish light up waders, puffballs speed up hedges.
- The two cues read sim state the build does not have yet: Current's direction, and a vent's burst timer. See part 4 for a conflict in the ash-moth cue.

### §11.7 Sage powers never restore earlier state

v3.6 (v36.txt:6217) adds: "The Chronicler (Time) and the Lamplighter (Energy) follow after launch. Their powers are written when they ship, under the rules every Sage follows: three powers, each a change to a named parameter (7.3), the one 20-second cooldown, earned and never sold. None restores earlier state, because Rewind was cut (7.4); the power names on their character sheets are placeholders (23.5)."

Build today:
- content/sages.json holds the four launch Sages only.
- The sim has no Sage powers yet. A search for Sage in sim/src finds none.
- No Chronicler or Lamplighter exists anywhere in the build.

What must change:
- Nothing now.
- When the after-launch Sages are authored, a content check should refuse any power that restores earlier state. tools/validate_content.py or tools/ability_text.py are the natural homes.
- The new sentence itself contradicts the launch Sages: see part 4, finding 2.

The brief's question about cooldowns was checked. §11.7 says "The crew's abilities have no cooldown (12.6) … Held breath slows it and the crew's ability lockouts alike (7.4)". §11.11 (v36.txt:6871) says "two uses a heist, with a lockout of 10 seconds between them and no cooldown", and §12.6 says the same. A lockout is not a cooldown in this document's vocabulary, so this is consistent. The Reverser's gift (v36.txt:6247) cites the same 10-second lockout.

### §11.8 The Stray, the Twinned, Paradox-born numbers

v3.6:
- The Stray (v36.txt:6235): "It is a ruleborn of one of the eighteen kinds, its kind drawn as a birth's is (11.5), shown travelling with a bundle on a stick (21.6); there is no nineteenth kind."
- The Twinned (v36.txt:6251): "Acts twice: every ability it fires, fires two times. Its crew's abilities fire once."
- Paradox-born (v36.txt:6257): "their level-1 numbers are their own, taken from their character sheets":

| Paradox-born | Health | Speed | Power | Carry | Body |
| --- | --- | --- | --- | --- | --- |
| The Reverser | 120 | 3.8 | 8 | 70 | Standard, about 0.85 m |
| The Twinned | 120, shared | 3.6 | 7 | 80, shared | Small, 0.6 m each |
| The Unmade | 100 | 3.4 | 8 | 85 | Standard, 0.8 m |

Build today:
- Visitors: no visitor exists in content or server.
  - Strays reach the build in one way only: track.mjs:51 gives `{ strayOffer: 1 }` at tier 50.
  - Pages and strays live on the device (track.mjs:202-204; D64).
  - The economy model prices a found stray at the next birth's price (config.py `priced_strays`, the owner's F38 answer B). §11.5 and §11.8 do not say so.
- Paradox-born: nothing.
  - No content table: tools/check_document.py:1105 lists "Visitors, paradox-born, anomalies: no content table enumerates them".
  - The sim's crew are five roles. `Role` (sim/src/lib.rs:247-253) carries health, speed, power and carry by match arm (lib.rs:300-330). `Size` is derived from role, and "nobody is small until a crew carries its ruleborn" (lib.rs:256-260).
  - So a paradox-born cannot be a crew member. In particular, the Twinned's one health and carry pool across two bodies, and its Small band, cannot be represented.
- The Twinned's gift: nothing is built, and nothing can be (part 4, finding 1).

What must change:
- content/ gains the three paradox-born rows from §11.8 through tools/extract_content.py.
- The sim gains per-character level-1 stats that are not keyed by `Role`, a Small body band, and a shared pool for the Twinned.
- The Stray visitor is drawn from the eighteen kinds, and no nineteenth kind is ever added to content/ruleborn.json, which today holds 18.
- The draw rule has no realm to draw from: see part 4.

### §14.4 The season track's free lane: pages, not in the day counts

v3.6 (v36.txt:8272-8273): "| The season track's free lane (18.2) | A few a season, not in the day counts below".

Build today:
- The server (track.mjs:49-58) gives:
  - 5 pages at tiers 5, 15, 25, 35 and 45: 25 pages a season.
  - 500 Essence on 44 tiers: 22,000 a season.
  - A stray offer at tier 50.
- Through the economy model's own pace (4.97 stars an attempt, 10 stars a tier), engaged and regular players claim all 50 tiers: 25 pages and 22,000 Essence. A casual player claims 28 tiers: 15 pages and 12,500 Essence. A non-raider claims tier 1 only: 500 Essence and no pages. These numbers were computed with tools/economy_model/data.py's `free_track`.
- The model adds the free track's pages to every raider's daily page income: `track = self._track()[1] / data.SEASON_DAYS` inside `pages_today` (model.py:589-595). This sits under `decided_income=True`, which the published run turns on (config.py:226-227).
- The Codex rows in docs/design/generated/pacing.md (launch 24 on day 29, all 48 on days 84–88 for an engaged player) therefore include free-lane pages.

What must change:
- Either the document states the number (25 a season, 15 at casual pace), or the server cuts it to "a few".
- Either the model drops track pages from the pages that set the Codex days, or the document says they are in. The effect is about 0.45 pages a day against an engaged player's 16 to 23, so the numbers move little. The rule is still explicit.

### §18.8 and §18.2: free track keeps pages, Essence and the stray; only premium is cosmetic

v3.6 §18.8 (v36.txt:9124-9125): "| Cosmetic only on the premium track | The premium track sells looks and nothing else (22.1). The free track's pages, Essence and stray (18.2) are small and stay claimable in a later season, so skipping a season costs time, never access, and nothing in a season changes a heist. 18.2 is the home of what each track holds; this row once said both tracks were cosmetic, which contradicted it."

§18.2 is unchanged (v36.txt:8989): "Fifty tiers, climbed with season points from heists, defences and discoveries. The free track gives pages, Essence and a stray. The premium track, bought with Starglass, adds cosmetics only."

Build today:
- track.mjs matches the rule.
  - The free track gives pages, Essence and a stray offer.
  - The premium track gives a cosmetic every fifth tier through §18.2's six kinds (track.mjs:38-39, 54-56).
  - Past seasons' tiers are claimable at their own price (track.mjs:137-163).
  - Catch-up fixes a player's tier price at `max(1, round(10 × time left ÷ season))` on first appearance (track.mjs:77-79; seasons.mjs:91-95).
- The premium track is a store product at €6 (shop.mjs:43-44), the owner's F41 answer. §18.2 still says "bought with Starglass".
- server/src/db.mjs:30 still carries `pass_expires_at`, a vestige of §24.8's "season pass expiry" (v36.txt:11928). The server records premium tracks per season instead.

What must change in the build: nothing for §18.8 itself.

What must change in the docs and tools that quote it:
- docs/decisions/brief.json's G28 entry quotes v3.4's "Cosmetic only, on both tracks" and "Nothing in a season affects a heist, so nobody is behind for skipping one". tools/build_brief.py --check now fails on both (scratchpad/v36/quickchecks.log, and re-run today).
- The register's G28 body still says "a tier costs twenty". track.mjs:36 sets `TIER_STARS = HEIST_STARS` (10), per the owner's answer B (docs/decisions/answers.json: "G28": option B).

### §23.2 Every screen to design: 28 screens, Profile and stats, four rows rewritten

v3.6:
- Profile and stats (v36.txt:11315-11317): "Renown and league over time, never the internal rating (12.15); heists by outcome (12.9); defences held and leaked; records; the battle log with replays; collection and badges. Private, with no sharing, for 13 to 15 (20.2)".
- Heist result (v36.txt:11233): "The outcome (Clean, Loud, Partial or Foiled) with its multipliers (12.9), the decisive moment with a three-second replay and one thing to try (12.13), loot kept, the entry fee, the law to study, Renown, rest for every crew member, "worth your time?"".
- Observatory (v36.txt:11237): "Three to five universes showing only the free scouting facts (12.4), the depth and the reason each was offered (12.15, 12.22), echoes marked, Trace, the entry fee; drifting ruins apart, at three labelled difficulties (12.12)".
- Rehearsal and defence log (v36.txt:11269): "… raids on you, each with its report (the haul denied, how long the defence held, where the crew was seen, what fired; 13.2), Trace".
- Settings and wellbeing (v36.txt:11281): "Reminder time, play-time reminders, notifications, accessibility, languages; any protection the age band fixes is shown locked (20.2)".

Build today:
- The client router has 13 routes (client/app/router.gd:9-21): home, age, heist, result, replay, settings, builder, track, shop, social, friends, workshop, universe. There is no profile, observatory, defence log, scout, planner, roster, Codex or Lab.
- Profile and stats:
  - The server has no read of a player's own history. The routes in http.mjs:168-228 and 468-570 cover league, season result, track, shop, cosmetics, replays by token (http.mjs:498) and the offer.
  - The data exists: the `heists` table keyed by attacker (db.mjs:164-184), `leases` with the defender, `renown` rows per heist and `season_results`.
  - Nothing defines "leaked", "records" or "badges", or whether a Partial counts as held (part 4).
- Result (client/scripts/result_screen.gd):
  - It shows the grade, banked/haul/fee, Keeper experience, and a button to the whole replay.
  - It has no multipliers, no three-second decisive moment, no one thing to try, no law to study, no Renown, no rest per crew member and no "worth your time?".
  - Renown is available: the server returns `renown` with the verdict (server/src/service.mjs:784).
  - The file's header still quotes v3.4's row: "Grade, loot kept, … replay" (result_screen.gd:3).
- Observatory:
  - The server's `GET /v1/offer` (http.mjs:513-520) returns each target with the island's internal `rating` and `deviation` (server/src/matchmaking.mjs:196), but no depth and no reason it was offered.
  - Trace is fee-free on the server (service.mjs:669), as §23.5 requires ("No entry fee on a Trace", 12.3).
- Defence log:
  - Replays are watchable by token.
  - There is no list of raids against a player, and no per-raid report. The lab/curation reader found that the four measures are neither defined for one raid nor recorded by the sim.
- Settings (client/scripts/settings_screen.gd):
  - It has language, three volumes, text size and six toggles.
  - It has no reminder time and no notifications, although the server takes them at `PUT /v1/notifications` (http.mjs:502).
  - Play-time reminders exist nowhere: a search for "play-time", "playtime" or "reminder" in client and server finds only the daily reminder.
  - No age-band protection is shown, locked or otherwise.

What must change:
- A server read for the profile (heists by outcome, defences, Renown by season, the battle log) and a client route.
- The result screen rebuilt to the row.
- The offer carries the reason and depth, and stops sending the internal rating to the device. §12.15: "the raw numbers are never shown". Today nothing on screen shows them, but they are on the wire.
- A raid list for the defence log.
- Settings gains the reminder time, the notifications, a play-time reminder (§20.2: every 60 minutes for 13 to 15, every 90 by default for 16 and 17), and the band's fixed protections drawn locked.

### §23.5's adopted items

| Item (v36.txt) | What v3.6 adopts | Build today | Must change |
| --- | --- | --- | --- |
| Profile and stats (11400) | "A screen the list lacked; now a 23.2 row, with Renown in place of a rating" | None: no route, no server read | See §23.2 above |
| First-launch order (11404) | "Title, the age-band check, a summary of the protections that band sets, the Keeper's name and face, then the first-session beats (16, 20.1)" | client/scripts/age_screen.gd: a title (`UI.title(APP_NAME)`, :14) and the four bands; on an allowed answer it goes to home (:38-43). No protections summary, no Keeper name or face, no §16 beats. The server has no player-name column (db.mjs:23-64) and no player-name word filter: server/src/words.json is for island names | Add the protections summary and the name and face steps. The name needs §20.4's "word filter … for chat, player names" and a decision on whether others see it (part 4) |
| Slower ruins (11407) | "An accessibility option that runs drifting ruins at 75% speed. Ruins only: never a heist against a player, never Renown (12.10, 19.12)" | `Settings.slow_rehearsals` (client/scripts/settings.gd:32-33) is applied only when `rehearsal` is true (heist_screen.gd:205-207) and is labelled "Rehearsals at 75%" (client/i18n/strings.csv:82-83). There are no drifting ruins in client or server | Rename it and apply it to drifting ruins only. Rehearsals keep §20.8's pause and lose the 75% |
| Paradox-born numbers and bodies (11409) | "Their level-1 numbers, sizes and proportions (11.8)" | Not in content/, and the sim cannot hold them (Role-keyed stats) | See §11.8 above |
| Wildlife cues (11413) | "Jellyfish drift with the wind under Current; ash moths gather a second before a vent bursts. They show what is already true (5.7)" | No wildlife; Current is not at launch; ember vents are not simulated | Render-only cues reading sim state once it exists. See part 4 on the moths |
| One data file for every screen (11416) | "The build does the same from this document's tables and 31.3's constants; the prototype's module is not a source" | Rule numbers come from: content/*.json (extracted tables); server/src/facts.json (82 constants generated by tools/design_facts.py); the sim's own Rust constants; and client/ui/tokens.json, which holds §20.8's 0.75 (`motion.rehearsal_pace`), §21.8's sizes and others, each with a `from`. The client does not read facts.json | Give the client one generated module from the same generator as facts.json, and move rule numbers such as the 75% out of the token file |

## 3. The open register, item by item

The effective status before v3.6 was read from audit_register.py's layers.

| Item | Before | After v3.6 | The v3.6 sentence | What remains |
| --- | --- | --- | --- | --- |
| G28: the track and shop have no numbers | open | **Narrowed** | §18.8: "Cosmetic only on the premium track \| The premium track sells looks and nothing else (22.1). The free track's pages, Essence and stray (18.2) are small and stay claimable in a later season…"; §14.4: "The season track's free lane (18.2) \| A few a season, not in the day counts below" | What the free track holds is settled. Still absent from the document: stars per heist and defence, the tier price (10, the owner's B), the catch-up formula, rewards tier by tier. Of B's doc edits, §9.1's Essence and Pages sources and §24.8's "season pass expiry" were not applied. The build's 25 pages against "a few", and its day counts (part 4, finding 4). Register body stale ("twenty"); brief.json quotes stale |
| F42: "season points" or "season stars", from which sources | open | **Unchanged** | §18.2 untouched: "Fifty tiers, climbed with season points from heists, defences and discoveries"; §9.1 still "Season stars \| … Heists, defences, discoveries, goals" (v36.txt:4406-4408) | The owner's answer A (stars, from heists and defences) is not in v3.6 |
| F37: a non-raider plateaus below Keeper 12 | open | **Narrowed, slightly** | §14.4: "The season track's free lane (18.2) \| A few a season, not in the day counts below" | F37's second paragraph objected that "the Library alone" excludes page sources a non-raider can reach, "the free season track" among them. v3.6 now excludes that one source on purpose. Still at v36.txt:8283: "A player who never raids earns the Library alone". The owner's answer B (Library plus a goal a day; the launch 24 as the ceiling) is not in the document, and the plateau stands |
| F54: a non-raider stops 6.5 experience short of Keeper 11 | open | **Unchanged** | (No v3.6 sentence touches §14.2 or the non-raider's experience.) | In the model a non-raider claims tier 1 only (500 Essence, no pages: model.py:599-606), so the free lane does not move the plateau. The owner's answer A (show a gate) is client work |
| C35: Codex day 69 (§14.4) against day 235 (§14.3) | open (V34) | **Unchanged** | §14.4: "not in the day counts below" leaves "Engaged: 60 days × 16 = 960, then 210 ÷ 23 = 9 more — about 69 days" as it was; §14.3's row still reads "48 laws owned \| Day 235" | Unchanged. The generated run (pacing.md: days 84–88) includes free-lane pages, which v3.6 now says the counts exclude |
| C11: screen count | fixed (V3) | **Reopened** | §23.2 now has 28 launch rows; §21.9 still says "Interface icons and screens \| About 220 and 27; two more with version 1.1 (23.2)" (v36.txt:11044-11045) | tools/check_document.py now checks 28 in §23.2 (working tree), but nothing reads §21.9's 27 |
| D70: declarations not filed; no age check or deletion on a screen | open | **Narrowed by the build, widened by v3.6** | §23.5: "Title, the age-band check, a summary of the protections that band sets, the Keeper's name and face, then the first-session beats" | The age check is built (age_screen.gd, client/data/age_check.gd). The deletion button is still not on a screen (client/data/repositories/account_repository.gd:26 exists; nothing calls it). The protections summary is new work |
| F38: strays fill the roster | open | **Unchanged** | §18.8 keeps the free track's stray; §11.8's Stray "joins the roster with three traits when it's done" | The owner's answer B (a found stray joins at the next birth's price) is in the model (config.py `priced_strays`) and not in §11.5 or §11.8 |
| F41: Starglass, currency or wrapper | open | **Unchanged** | §18.2: "The premium track, bought with Starglass"; §9.1: "Purchases; small amounts from the free season track" (v36.txt:4415) | §18.8's "sells looks and nothing else (22.1)" is compatible with either reading |
| D64: track and cosmetics built without stores, discoveries or a cosmetic | open | **Unchanged** | — | Pages and strays are still device-held, so a Profile "collection" has no server source |
| C42: one heist in eight, a stray or a page | open | **Unchanged** | — | — |
| C43: who gets word-list names | open | **Unchanged; one more name kind** | §23.5 adopts "the Keeper's name" | §20.4 filters player names, but no section says whether a 13–15 Keeper name is free text or from word lists, or who sees it |

Items that sound related but are not moved: G12 and F10 are already fixed; D48 was fixed in v3.3, and the Friends row is unchanged.

## 4. v3.6 against itself

### Checked and consistent

Every §23.5 figure the brief asked for, checked against its home section:

| §23.5 says | Home section | Holds |
| --- | --- | --- |
| Aether storage 29,000 at Spire 6 | §10.2 Spire row 6: "+78 stability; 29,000 Aether storage" | Yes |
| Crown slots two from Spire 5 | §5.1: "1 crown slot at Spire level 2 and a second at Spire level 5" | Yes |
| Resonance Lab 5 h | §10.2 Lab level 3: "2 slot(s); 5 h per experiment" | Yes |
| Breaker 180, Carrier 160, Mender 130, and the five role stat lines | §11.1, content/roles.json | Yes |
| Landing noise: heard means guards within 6 tiles start at 250 of 1,000 | §5.4 "Being seen landing" | Yes |
| Season track 50 tiers | §18.2 | Yes |
| Tidewalker a Carrier, Echoplate a Warden; Skyskipper resists Leapfrog's noise | §11.2 / content/ruleborn.json | Yes |
| Trace has no entry fee | §12.3 (v36.txt:6932) | Yes |
| Puffballs: six (9, 12); guards within 5 tiles 30% more aware | §7.7 Flock | Yes |
| Swarmlings: two at 30% | §7.7 Swarm birth tier I | Yes |
| Illusions revealed by Lantern Wisp or Prism Mite | §11.11 (Lantern Wisp reveals; Prism Mite "Sees through Glass and Mirror images") | Yes |
| Authored islands 30 to 45% at every level | §13.2 | Yes |
| One 12-point law in a 38-point Spire is 32%, Quiet | §5.5 (30 + 8 × 1 = 38; Quiet under 40%), Half gravity 12 | Yes |
| Matter a cube, Spirit an eye, Life a leaf | §5.2, §21.2 | Yes |
| Rating stays internal | §12.15 "Ratings are internal" | Yes |
| Rope bridge as a link | §5.3 | Yes |

Also consistent:
- §11.7 against §11.11 and §12.6 on cooldown and lockout (part 2).
- §23.2's defence-log report fields against §13.2 ("how much of the haul the defence denied, how long it held the crew up, where the crew was seen and which wards fired").
- Paradox-born "none is better than any role in every number": each paradox-born loses to every role on at least one stat.
- No normative section still says Godot 4.5. The only 4.5 mentions are in v3.5's changelog and §24's explanation.

### New contradictions and stale statements

1. **The Twinned's gift does nothing.** §11.8 (v36.txt:6251) narrows Twin suns to "every ability it fires, fires two times. Its crew's abilities fire once." Paradox-born "have no role in 11.1" (v36.txt:6257), and §11.11 has no card for any of them; the only paradox-born mentions are v36.txt:6245-6285, 10778 and 11602. So the Twinned has no ability to double. The Reverser's gift is itself an ability ("two uses a heist, with the 10-second lockout"); the Twinned's is a modifier on nothing. The characters reader reached the same conclusion independently.

2. **§11.7's new Sage rules contradict the Sages it sits beside.** "Under the rules every Sage follows: three powers, each a change to a named parameter (7.3), the one 20-second cooldown". This fails on both clauses:
   - §7.3 has "exactly twenty-two parameters". The launch Sages' Suspend (switch a law off), Reveal (show every ward), Jam (disable one ward), Copy (carry an enemy law), Rift (a two-way rift between realms), Plank and Vine bridge (lay a shortcut) and Decoy (plant a sapling guards chase) are not changes to any of them.
   - The same paragraph says "Every fifth level improves one power (an extra use, a longer effect or a shorter cooldown)". A levelled Sage's cooldown is not "the one 20-second cooldown".

3. **§18.8 keeps "nothing in a season changes a heist"** beside the free track's "pages, Essence and stray". A stray is a crew member, Essence buys levels, and pages raise law tiers. §18.3's eras, at launch, change a heist's rules every week. The owner's G28 answer B proposed "Nothing bought in a season affects a heist"; v3.6 dropped "bought".

4. **§14.4 against the build:** "A few a season, not in the day counts below", against the build's 25 pages a season (15 at casual pace) and a model that counts them (part 2).

5. **§9.1 against §18.2, now named home.** §18.8: "18.2 is the home of what each track holds". §9.1 still says:
   - Starglass is "Earned from … Purchases; small amounts from the free season track" (v36.txt:4415). §18.2 gives no Starglass, and the owner's F41 answer removed the currency.
   - Essence comes from "Gardens, heists" (v36.txt:4380), and Pages from "Heists, the Lab, the Collector, gifts, daily goals" (v36.txt:4387). Neither lists the track.

6. **§21.9 budgets 27 screens; §23.2 lists 28.** v36.txt:11045: "About 220 and 27". §23.5 also records 393 designed icons against §21.9's "about 220". That one is a budget against a supply rather than a contradiction, but §21.9 says its rows "are derived from the same inventory 26.1 is checked against", and the screen count was not.

7. **The Stray's kind has nothing to be drawn from.** "Its kind drawn as a birth's is (11.5)". A birth's draw weighs "the schools around the Nursery … 3 for each law woven in its realm, 2 for the realm's own school and 1 for each crown law" (§11.5, §11.9). The Stray arrives at the Dock in the Heart, a Neutral realm with no Nursery. Two other sections also still treat the Stray as its own creature:
   - §21.6 (v36.txt:10775): "the Stray is a scruffy little creature with a bundle on a stick".
   - §21.9: "visitors 3".

   The free track's stray and §11.9's heist strays ("born under one of the laws the crew crossed") each have their own draw, so the Stray visitor is the only one left without a rule.

8. **Profile and stats' must-show has undefined terms.** "Defences held and leaked": "leaked" appears nowhere else in the document. Nothing says whether a Partial, where some loot got out, is held or leaked, although §13.2's "Defences that hold" mirrors "Raids that succeed". "Records" and "badges" are undefined too: the season reader found the same for badges.

9. **The adopted Keeper's name has no rule.** §20.4 requires "a word filter … for … player names". §20.7 gives 13 to 15 word-list names for islands only. §20.2 makes a 13–15 profile private. Nothing says whether the Keeper's name is typed or picked, or whether a raider, a friend or a league table sees it. The server has no name and no player-name filter.

10. **The ash-moth cue changes what a player can see.** §5.7 says wildlife changes nothing a player can see, then allows moths that gather "a second before a vent bursts". No section gives an ember vent a tell of its own: terrain row "Bursts of flame every 8 seconds", §5.7's Emberreach row "timed vents". So the moths are the only one-second warning. §20.8's reduced-motion mode "removes swoops and most particles", so the cue either adds information or vanishes for players who need it.

    A smaller point under the same new rule: "none looks like a law creature or a guard". Crystalline's wildlife is "Prism beetles" (v36.txt:1033), and §11.11's Prism Mite, a ruleborn that can stand guard, is a "Tiny prism bug with a backpack" (v36.txt:6487, 10695), in its own school's realm.

11. **The units disagree.** §23.5 (v36.txt:11517) says "13 pt at the smallest, 16 pt body (21.8)". §21.8 (v36.txt:10992) says "Body text is at least 16 pixels … Nothing smaller than 13 points". The client took 16 as points (ui/tokens.json `size.body_points`, from "16 pixels").

12. **A stale changelog line.** v3.5's changelog, kept in v3.6 (v36.txt:91), says "No client code exists yet, so the move costs nothing." The repository has a Godot 4.5 GDScript client with a Rust extension at api-4-5 (ctx.md; client/ruleborn.gdextension). This flags only the sentence; the move itself is measured separately.

13. **Two tooling side effects of the v3.6 text, both already being dealt with:**
    - §23.5's line "23.2 is the must-show list. The designs' own notes are not." (v36.txt:11393) begins with a section number, so tools/check_document.py's section index read it as a heading. The working tree already adapts the splitter.
    - tools/build_brief.py --check fails on G28's two v3.4 quotes.

    The header line "Draft for review, September 2026" (v36.txt:11) is also older than §23.5's review "on 7 October 2026". This is cosmetic.

## 5. What the build should do next for v3.6, in order

1. Season track: pick the free-lane page count to match "a few" (or have the document state 25), and drop track pages from the Codex day counts in tools/economy_model/model.py:589-595, or have the document include them. Then update brief.json's G28 quotes and G28's register body (10 stars, not twenty).
2. Settings: reminder time, notifications, a play-time reminder (a §20.2 protection built nowhere), and locked protections by band. Also the deletion button D70 still lacks.
3. First launch: a protections summary after the age check. The Keeper's name and face only after the document says how a name is chosen, filtered and shown (finding 9).
4. Slower ruins: retarget `slow_rehearsals` to drifting ruins, once ruins exist.
5. Result screen to the rewritten row, using what the server already returns (`renown`, `fee`, `feeReturned`).
6. A server read for Profile and stats, once "leaked", "records" and "badges" are defined.
7. Paradox-born: a content table, and sim stats not keyed by role, once the Twinned's gift is written.
8. Offer: send the reason and depth, not the internal rating.
9. One client data module generated alongside server/src/facts.json.
