# Season, Shop, Share sheet, Friends, Profile and stats: Screens v3 against v3.6, the build today, and the Godot plan

Scope: screen 17 Season (Pass, Quests and League tabs), 18 Shop (with its item page and buy sheet), 27 Share sheet (Clip, Challenge, Invite), 28 Friends (Feed, Friends, Invite, the friend sheet) and 20 Profile and stats (Overview, Battle log, Collection). Written for the owner. "Doc" is `docs/design/ruleborn-game-design-v3.6.txt`. "Meta markup" is `art/named/screens_meta.markup.html` and "meta.js" is `art/named/screens_meta.js`, both under the scratchpad. "Main" files are `screens_main.*`. Line numbers are file lines.

## 0. What I read and ran

- Doc: §23.2 rows Season (11271), Shop (11275), Share sheet (11307), Friends (11311), Profile and stats (11315); §23.5 in full (11383–11635) and its rows Profile and stats (adopted, 11400), One data file (11415), Share sheet (11460), Profile header (11470), Season track (11475), Text size (11515), Demo numbers (11555), Landscape (11560), The designs' own notes (11565); §9.1 (4355–4420), §9.4 (4547–4562), §9.5 (4564–4634), §11.7 (6188–6218), §11.8 (6219–6290), §11.10 (6303–6333), §12.3–12.4 (6920–6937), §12.9 (7072–7110), §12.11 (7119–7125), §12.15 (7173–7183), §14.6 (8327–8337), §14.7 (8339–8369), §14.8 (8371–8391), §17.6–17.8 (8925–8981), §18.1–18.5 (8983–9058), §18.8 (9108–9128), §19.10 (9602–9612), §19.12 (9664–9702), §20.1–20.7 (10158–10284), §21.8 (10986–11016), §22.1 (11100–11124), §22.4 (11171), §27.5 tail (13100–13110); the v3.6 per-section diff (`v36/diffs.txt`: §14.4, §18.8 and §23.2 touch these screens; §9.1, §12.9, §14.6, §17.6, §18.2, §20.2, §20.7 and §22.1 did not change).
- Design: meta markup blocks Season 245–293, Shop 294–327, Player stats 328–370 (the "post/share sheet ~328–370" in my brief is in fact Profile and stats, label "19b Player stats"), Share sheet 586–604, Friends 605–638 (tab bar 627–636); meta.js state 1–6, `seR`/`seClaim`/`seQClaim`/`seSwap` 152–165, Season 601–693, Shop 694–830, Profile 826–886, Share 1218–1238, Friends 1239–1285; main markup 385–392 (home side buttons Season and Shop), main.js 435 and 670 (menu sheet entry to Profile); `icons_rbi.js` head (the `season` group has an `era` icon the design never uses).
- Screenshots: the supplied `shots/all/Gameplay_17/18/20/27/28*.png/.txt`, and my own captures, made by serving the artifact locally (`analysis/sssfp_scripts/serve.mjs`, `shoot.mjs`): adult in `analysis/sssfp_shots/`, the 13–15 band (`?ab=1`, the Tweaks age band) in `analysis/sssfp_shots_minor/`. States captured: Season `season_pass`, `_pass_end`, `_claimall_reveal`, `_buy_sheet`, `_quests`, `_quests_bottom`, `_quest_claim`, `_quest_swap`, `_league`, `_league_bottom`; Shop `shop_top`, `_mid`, `_bottom`, `_detail_outfit`, `_detail_realmskin`, `_confirm_outfit`, `_confirm_realmskin`, `_confirm_set`, `_confirm_pack`, `_gift`, `_cat_glass`, `_cat_realmskins`; Profile `stats_overview_top/700/1400/2100/2800`, `_donut_loud`, `_log`, `_log_bottom`, `_collection`, `_collection_bottom`; Share `share_clip`, `_clip_m2`, `_clip_m3`, `_clip_posted`, `_challenge`, `_challenge_workshop`, `_challenge_sent`, `_invite`; Friends `friends_feed`, `_feed_bottom`, `_list`, `_invite`, `_sheet_kofi`, `_block`. Portrait PNGs did not load in my local serve (empty discs in some captures); layout and text are unaffected.
- Adult against 13–15 (text diffs of the captures): Season (all three tabs and the buy sheet) and the Share sheet are word for word the same; the Shop is the same apart from nothing (same "Ask to Buy" text, no cap shown); Profile differs only in the hidden SHARE button; Friends differs in the Invite tab's minor note and the "Gift a look" toast.
- Build: `client/README.md`; `client/scripts/track_screen.gd`, `shop_screen.gd`, `friends_screen.gd`, `social_screen.gd`; `client/features/shop/shop_state.gd`, `shop_controller.gd`, `shop_presenter.gd`; `client/features/social/social_state.gd` (head), `social_controller.gd`, `social_presenter.gd`; `client/data/repositories/track_repository.gd`, `shop_repository.gd`, `friends_repository.gd`, `social_repository.gd` (function list), `account_repository.gd` (function list); `client/app/router.gd`, `app_state.gd`, `services.gd`, `core/store.gd`; `client/scripts/ui.gd` (function list), `client/ui/tokens.json` (head); `client/i18n/strings.csv` (TRACK_, SHOP_, LEAGUE_, FRIENDS_ rows). Server: `server/src/http.mjs` 1–100 (routes), `track.mjs` (all), `seasons.mjs` 1–203, `friends.mjs` (all), `shop.mjs` 1–80, `leagues.json`, `cosmetics.json`, `db.mjs` table list and the heists, seasons, standings, renown, season_results, friends, friend_invites, challenges tables, `service.mjs` 600–800 (what a heist settles), `sim.mjs` 85–110 (the verdict's fields). Register: `tools/audit_register.py` (titles of every item touching these screens; bodies of F41, F42, G28, D64, C14, F54 and the FRONTEND/BOTH sets). Roadmap: `tools/roadmap.py` stage SC (TC.1–TC.14).
- Sibling reports read for what they already decided: `screens-home-realm-shell.md` (shell, tab bar, badges, fonts, engine move) and `screens-heist-result.md` (event log, moment picker, result share F14).
- Not read: the character sheets; `data_v35.js` beyond knowing §23.5 says it is no source; server `social.mjs`, `notifications.mjs`, `telemetry.mjs` bodies; the client tests' bodies.

### 0.1 The rule applied

§23.5: the document wins on any rule, number or text; where it is silent and a design breaks no rule, the design is adopted (and must be listed in §23.5 so the document stays the one source); a design never adds a mechanic, meaning anything that changes what a crew, guard or player can do, see, hear or earn. §23.2 is the must-show list; the designs' own "MUST SHOW" notes are not.

### 0.2 Things common to all five screens

- **Navigation.** Season and Shop are side buttons on the Universe map (main markup 390–391, badges "3" and "!"); Profile opens from the menu sheet behind the home portrait (main.js 435, 670) and from Settings (meta.js 928 `statsGo`); Friends is the fifth bottom tab (meta markup 627–636); the Share sheet is in the Friends tab group (main.js 666) and is opened from the rehearsal "Watch replay" button (meta markup 241) and the Friends Invite tab; its back button goes to the result (meta markup 589). The sibling home report plans the shell, tab bar and `BadgePresenter`; these screens mount into it.
- **Only two age bands exist in the design**: the Tweaks offer "18+" and "13–15". §20.2 and §20.7 have three (13–15, 16–17, 18+), and 16–17 changes the Shop cap (€50), clip sharing ("after a confirmation"), the profile ("private by default") and chat. Every band rule below has to be built for three bands.
- **Text size** (listed in §23.5, 11515): ribbons, chips and captions on all five screens are 7.5–11 px (for example rarity ribbons `font: 900 8.5px`, meta.js 619; the Shop's `p2S` 9.5 px, meta.js 760). The build keeps 13 pt minimum and 16 pt body; cards grow, and the a11y tests lay every screen out again at 150% and 200%.
- **Landscape** (listed, 11560): not designed for any of the five.
- **Numbers** are the prototype's own (tier 12, 340/500, 1,460 Renown, league thresholds 600/1,200/1,800/2,600/3,600, holds 62% and 90%, Forms 31/66). §23.5's "One data file" row says the prototype's data is no source; every number on these screens comes from the server or the content tables.
- **Typefaces and panels** (Manrope and Lilita One on dark leather against §21.8's Baloo 2 and Marcellus on paper) are raised by the sibling reports (home K, heist H16); not repeated here.

---

## 1. Season (screen 17)

### 1.1 The §23.2 row and the rules behind it

> | Season | Long goals. | League, track, era, weekly streak (doc 11271–11273)

- §18.1: eight-week seasons; six leagues Dust, Ember, Tide, Star, Nova, Paradox, three divisions each except Paradox; nobody drops out of Dust or Ember; "At the end of a season, rewards are given by league and Renown is pulled halfway back toward the floor of the player's league."
- §18.2: "Fifty tiers, climbed with season points from heists, defences and discoveries. The free track gives pages, Essence and a stray. The premium track, bought with Starglass, adds cosmetics only."
- §18.3: eras are one rule a week for every universe (Heavy Stars, The Long Night, High Tide, Wildgrowth, Echoing Skies, Static Storm, Glass Moon, Quiet Week).
- §18.5: "Star, Nova and Paradox leagues with season-end cosmetics."
- §18.8: nothing expires forever; catch-up built in; no countdown pressure; "The premium track sells looks and nothing else (22.1)" (changed in v3.6); "It has to earn its place".
- §14.6: "Daily goals: the player picks 3 of 6 offered goals … with one free swap. Rewards are small and shown as progress toward something the player chose." "Weekly streak: playing on 4 days out of 7 keeps it going. One automatic saver a week covers a missed week, and a broken streak is repaired by playing two days in a row. Streak rewards are cosmetic."
- §14.8: the track's first tier is complete on day one; always show what is left; "Progress bars never appear in the shop, and no purchase ever fills one."
- §9.1: Season stars are earned from "Heists, defences, discoveries, goals"; Starglass from "Purchases; small amounts from the free season track".
- §12.9: Renown for a clean heist = 20 × (1 + (defender − raider) ÷ 1,000), kept between 8 and 40, × outcome (Clean 1.0, Loud 0.8, Partial 0.5); Foiled −8 flat; the defender gains or loses the mirror.
- §20.3: "No power, speed or skipped waiting for money"; "No obligations"; "repeatable rewards have daily and weekly caps".
- §23.5 rows that concern it: Season track (30 tiers → 50, 11475); Text size; Landscape; The designs' own notes.

### 1.2 What the design shows

Header (meta markup 248): back to home, kicker "SEASON 2 · TIME", title "Held Breath" (Held breath is also a Time law, §7), a chip "18 days" with a timer icon. Tabs (249; meta.js 634): Pass (badge = tiers ready to claim), Quests (badge = quests ready to claim), League.

**Pass tab** (250–273):
1. A hero banner (252–263): "STARPASS · TIER 30 · Chronicler robe · Legendary · claimable in any later season", a cyan line "Free at tier 30: The Chronicler", "SEE TIER 30 ›" (smooth-scrolls to the end), a rendered Chronicler figure, drifting motes.
2. A tier strip (264): star badge with the tier (12), "TIER 12", "+20% ★" when the Starpass is owned (meta.js 670 `boostOn`), "160 to tier 13", a bar "340 / 500", and two jump buttons: "CLAIM" with a count (or "NEXT") and "TIER 15" (the next fifth tier). Claiming a quest floats "+40" here.
3. The track (265–269): a horizontal scroller with a STARPASS lane above and a FREE lane below a road. Each tier is a column: premium card (rarity ribbon COMMON/RARE/EPIC/LEGENDARY, icon, amount, a name on fifth tiers, a lock while the pass is not owned, a green ✓ stamp once claimed, a CLAIM button when claimable, a burst and "+600" fly-out on claim), a road node with the tier number (the current node bobs; the filled road scrolls stripes; a glowing tip marks progress), and the free card. Every fifth card is bigger with spinning rays; tier 30 is "FINAL". Gates before tiers 11 and 21 read "ERA II · THE STILL HOUR" and "ERA III" (meta.js 628). After tier 30: "STAR CHESTS · One every 500 ★ · up to 10 a season · 0 / 500" (268). The loop draws tiers 1–30 only (meta.js 607, 626) although the reward tables hold 50 (meta.js 153–154: the Chronicler and the Chronicler robe sit at index 50).
4. "CLAIM ALL n" floats bottom right when more than one tier is claimable (271).
5. A Starpass bar (272) while the pass is not owned: crown, "STARPASS · Cosmetics only · 12 rewards waiting", "600 ✦".
6. Buy sheet (290; `season_buy_sheet.png`): crown, "Starpass · Season 2 · Held Breath", four perks (Chronicler robe "A Sage outfit at tier 50", Clockwork isle, Six sky themes, "41 more cosmetics · Nothing that changes play"), "Cosmetic only: nothing on either track changes a heist. Unclaimed tiers stay claimable next season.", "Paid through the App Store · Ask to Buy applies", "Buy for 600 Starglass", "Not now". The same for 18+ and 13–15.
7. Reveal overlay (291; `season_claimall_reveal.png`): spinning rays, 24 sparks, confetti, a heading ("2 REWARDS", "TIER 13 REACHED", "STARPASS ACTIVE" or the rarity), cards flipping in, "Added to your stores · Essence, pages, insight and cosmetics", "TAP TO CONTINUE". A single common reward instead pops in place with a ✓ stamp (`seClaim`, meta.js 156–159).

**Quests tab** (274–279; `season_quests*.png`):
1. Weekly streak card: "4 of 7 days", seven cells M T W T F S ★ (done days ✓, today breathing, ★ a chest "+100"), and "Today · 6 of 10 min" with a bar (276; meta.js 683).
2. Daily ("New tomorrow"): Collect from 3 Star Wells +40 (⇄ SWAP), Finish a heist +40 (CLAIM), Rehearse your defence +30 (⇄ SWAP), "Starpass: win a heist unseen" +60 behind a STARPASS button (meta.js 4, `prem: 1`).
3. Season ("All season"): Hold 5 defences +180, Run 4 Lab tests +150, Restore 6 law pages +200, Play 3 friendly heists +120.
4. Event · The Still Hour ("4 days"): Discover a Time law +400, Reach a Vault unseen 10 times +300.
5. CLAIM adds the stars to the tier bar and may raise a tier with the reveal (`seQClaim`, 160–163). One free swap a day replaces a daily quest from a pool ("Quest swapped · next free swap tomorrow", `seSwap`, 164–165). With the Starpass each quest pays 20% more (`rT`, meta.js 684).

**League tab** (280–289; `season_league*.png`): a card "Tide league · #1,284 · 1,460 / 1,800 · 340 renown to Star league"; "League road · End-of-season rewards": Paradox 3,600 (pages ×60, Starglass 120), Nova 2,600 (×40, 80), Star 1,800 (×25, 40), Tide 1,200 "YOU" (×15, 20), Ember 600 "✓ Reached" (×10, insight ×5), Dust 0 "✓ Reached" (×5) (meta.js 688); "Earn renown": +30 Heist won, +20 Defence held, −10 Vault raided (meta.js 693); footer "At the end of the season you get the rewards for the highest league you reached." (287).

Motion: bobbing claimable cards, glints on rare and better, twinkles on epic and legendary, spinning rays on fifth tiers, road stripes, a breathing tip, a reveal with sparks and confetti. Sound cues through `RBSfx` (collect, tap, whoosh, open).

### 1.3 Must-show check

| Must show (§23.2) | In the design | Verdict |
|---|---|---|
| League | League tab with the six leagues, the player's place and "to next" | Met in shape; the reward table and the Renown rule it prints are wrong (1.4). Divisions appear only as "TIDE II" on Profile, not on the road. |
| Track | Pass tab, two lanes | Met, but 30 tiers (listed) |
| Era | Track chapters "ERA II · THE STILL HOUR", "ERA III" | **Missing.** §18.3's era is this week's rule for every universe; the design never shows it. The server has `GET /v1/era` (http.mjs:10) and the icon set has `season.era`. |
| Weekly streak | Weekly streak card | Met in shape; its reward, its day rule and its repair are not §14.6's (1.4). |

### 1.4 Where the design and v3.6 differ

| What | Design shows | Doc says | § | In §23.5? |
|---|---|---|---|---|
| Tier count | 30 tiers (meta.js 607, 626) | 50 | 18.2 | Yes |
| Starpass boost | "+20% ★" on the tier strip, quests pay ×1.2 with the pass (meta.js 670, 684) | Premium "adds cosmetics only"; "sells looks and nothing else"; "no purchase ever fills [a progress bar]"; "No power, speed or skipped waiting for money" | 18.2, 18.8, 14.8, 20.3 | No (SS1) |
| Starpass-only quest | "Starpass: win a heist unseen" +60 stars, locked without the pass (meta.js 4) | Same rules as above | 18.8, 20.3 | No (SS1) |
| Daily goals | Four fixed daily quests, one free swap a day | The player picks 3 of 6 offered goals, one free swap | 14.6 | No (SS2) |
| Season and event quests | Four season quests (+120 to +200) and two time-limited event quests (+300, +400, "4 days") | No such goals; stars come from heists, defences, discoveries, goals | 9.1, 18.2, 18.8 | No (SS2) |
| Weekly streak reward | "+100" chest on the seventh cell (meta.js 683) | "Streak rewards are cosmetic" | 14.6 | No (SS3) |
| What a played day is | "Today · 6 of 10 min" (markup 276) | "playing on 4 days out of 7" | 14.6, 19.12 | No (SS3) |
| Streak saver and repair | Not shown | One automatic saver a week; repaired by two days in a row | 14.6 | No (SS3) |
| Era | Three chapters of the track | One rule a week for every universe | 18.3, 23.2 | No (SS4) |
| Free-track Sage | "Free at tier 30: The Chronicler" (markup 262) | Free track: pages, Essence, a stray; Sages unlock by Keeper level (four Sages); the Chronicler is not a §11.7 Sage | 18.2, 11.7 | No (SS5); §23.5 lists only the Chronicler's Rewind power |
| League rewards | Pages and Starglass for every league, insight for Ember, "the highest league you reached" | Star, Nova, Paradox get season-end cosmetics; Starglass only from purchases and the free track; "rewards are given by league" | 18.5, 9.1, 18.1 | No (SS6) |
| Renown rule | "+30 Heist won · +20 Defence held · −10 Vault raided" | 20 × (1 + Δ/1,000), 8–40, × outcome; foiled −8; defender the mirror | 12.9 | No (SS7) |
| Overflow rewards | "STAR CHESTS · One every 500 ★ · up to 10 a season" | Nothing after the last tier | 18.2 | No (SS8) |
| Starpass price | "600 ✦" on the bar and "Buy for 600 Starglass", no money price | "Every price is shown in real money before purchase"; "Every cosmetic shows its real-money price" | 22.1, 19.12 | No (SS9) |
| Payment line | "Paid through the App Store · Ask to Buy applies" for every band | Family approval is 13–15's; adults get a monthly summary | 20.2 | No (SS11) |
| Reveal text | "Essence, pages, insight and cosmetics" | Free track gives no insight | 18.2 | No (text; fix in the build) |
| League thresholds | 0 / 600 / 1,200 / 1,800 / 2,600 / 3,600 | Not stated (G27); the server's fit is 0 / 128 / 176 / 254 / 458 / 806 (`server/src/leagues.json`) | 18.1 | Data, not a §23.5 item |
| Text size | 8.5–11 px ribbons and captions | 13 pt minimum | 21.8 | Yes |
| Landscape | Not designed | Portrait and landscape | 23.3 | Yes |

### 1.5 Silent adoptions (doc silent, no rule broken)

- The two-lane horizontal track with a road, rarity ribbons by reward size, bigger fifth tiers, the FINAL card, the jump buttons (CLAIM n, next fifth tier), "SEE TIER 50" (renumbered), CLAIM ALL, and the claim reveal with flying rewards (§21.8 "rewards fly into their counter"); reduced motion keeps the flip and drops rays, sparks and confetti.
- Season name and school ("SEASON 2 · TIME · Held Breath"): §18.7 already lets creators have "a say in one season's theme". Avoid a season name that is also a law name, or say "Season of Held breath".
- The days-left chip on the Season screen (§18.8 bans timers on the home screen and "last chance" banners, not a plain date on the season's own page). It must never turn red or pulse.
- Unclaimed tiers marked "claimable in any later season" (§18.8 says the same).
- The League road as a vertical list with the player's league highlighted, "✓ Reached" on passed leagues, and "N renown to Star league" (§14.8 "what's left").
- A global position (#1,284): no rule against it; the server would need to compute it. §17.7 says recognition is "peer-to-peer first", so keep it small.
- Daily goal swap button and "New tomorrow" (§14.6 has the one free swap).

### 1.6 The build today

- `client/scripts/track_screen.gd` (96 lines): a title, "N stars to spend", "Next: tier n for m stars", a status line, every tier as a text row ("Tier n: 500 Essence, and with the premium track a realm skin"), "Claim the next tier", "Premium track, €6.00" (store product), Home. It draws `ShopPresenter.track` (`client/features/shop/shop_presenter.gd:54–84`) from the `TRACK` slice (`client/features/shop/shop_state.gd:8, 17–22`); `ShopController.load_track`/`claim` (`client/features/shop/shop_controller.gd:19–40`) call `TrackRepository.view`/`claim` (`client/data/repositories/track_repository.gd:15–22`). Buying the premium track runs the F41 purchase flow (`shop_controller.gd:66–89`).
- League: `client/scripts/social_screen.gd:59–70` shows "Tide II", "N Renown in season S", "N Renown to the next league" from `SocialPresenter.league` (`client/features/social/social_presenter.gd:42–57`) and `GET /v1/league`. No road, no rewards, no thresholds of other leagues.
- Quests, daily goals, weekly streak: nothing in the client or the server. D64 records that "stars from discoveries and goals … happen on the device and … the server cannot yet check" them.
- Era: the heist reads the era from its lease (`client/features/heist/heist_controller.gd:50`); no screen shows the week's era; `GET /v1/era` (http.mjs:10) is unused by the client.
- Server: `GET /v1/track`, `POST /v1/track/claim` (http.mjs:73–74; `server/src/track.mjs`): 50 tiers (`facts.json:276`), 10 stars a tier (`TIER_STARS`), tier 1 free, catch-up price fixed at first appearance, free track 500 Essence / 5 pages on odd fifths / a stray offer at 50, premium a cosmetic every fifth tier through six kinds, premium track as store product `premium.<season>` at €6 (`facts.json:195`), unclaimed past tiers claimable with this season's stars. Stars only from heists and defences (`heistStars`). `GET /v1/league` (http.mjs:55; `seasons.mjs:163–170`): season, renown, league, division, floor, next threshold. Rollover writes `season_results` with the **final** league and gives a cosmetic only to Star, Nova, Paradox (`seasons.mjs:46–53, 178–203`). No season end time is returned by `/v1/track` or `/v1/league`.

### 1.7 What the server lacks for this screen

1. `GET /v1/goals`, `POST /v1/goals/pick {ids}` (3 of the 6 offered), `POST /v1/goals/:id/swap` (one free a day), `POST /v1/goals/:id/claim` → stars (§9.1) and pages (§9.1 lists daily goals as a page source). Goal progress must be counted on the server from what it already sees (heists, defences, Lab and Codex once TC.12 moves them) or the goal list limited to those; the daily cap of §20.3 applies.
2. `GET /v1/streak`: this week's played days (from validated heists, defences and sign-in days the server sees), the saver's state, the repair state, and the cosmetic it gives; a streak cosmetic in the catalogue.
3. Season end time (`seasons.ends_at`) on `/v1/track` or `/v1/league`.
4. `/v1/league` to carry the road: every league's lower bound and divisions (`leagues.json`) and its season-end reward as the server grants it; optionally the player's position.
5. Claim-all: `POST /v1/track/claim {"season", "through": n}` claiming in order inside one transaction, so a claim-all is one call and one reveal (today it would be n calls).
6. The week's era to the Season screen: `GET /v1/era` exists; nothing to add but the client call.

### 1.8 The plan (Godot 4.7, on the existing architecture)

1. **Engine first** (sibling home report step 9): Godot 4.7.2 and gdext `api-4-7` per §24's engine row; the client is on 4.5 today.
2. **State**: keep `ShopState.TRACK`; add `SeasonState` slices `GOALS` (offered, picked, progress, swaps left, claimed) and `STREAK` (days, saver, repair, reward), and keep `SocialState.LEAGUE` but widen its view with the road. Reducers are static, as today, and get tests in `client/tests/shop_tests.gd` / a new `season_tests.gd`.
3. **Repositories**: `TrackRepository` gains `claim_through(season, tier)`; new `GoalsRepository` (`/v1/goals*`, `/v1/streak`); `SocialRepository.league()` reads the widened view; a small `EraRepository.week()` (or a method on `HeistRepository`) for `/v1/era`.
4. **Presenters**: `SeasonPresenter.header` (season, school, name, days left, the week's era with its rule in words), `.pass` (50 columns: per tier its free and premium reward, state claimed/claimable/locked/future, size class by tier, "N to tier n+1", the next fifth tier, the claimable list), `.goals` (picked goals with "N to go", swap availability; the picker of six when nothing is picked), `.streak` (days, saver, "play two days in a row to repair"), `.league` (the road from the server's bounds and rewards, the player's league and division, "N Renown to Star"). The text "Earn renown" becomes §12.9's rule in words: "A clean heist earns 8 to 40 Renown, more against stronger Keepers; Loud ×0.8, Partial ×0.5; a foiled heist costs 8. A defence wins or loses the same." No Starpass multiplier anywhere.
5. **Components** (added to `scripts/ui.gd`, built from Claude Design's tokens when they replace `ui/tokens.json`): `TabStrip` (segmented, badge with a spoken count), `RewardCard` (ribbon, icon, amount, name, lock, ✓ stamp, CLAIM; sizes S/M/L), `TrackLane` (a `ScrollContainer` with an `HBoxContainer` of tier columns, two lane labels, and a road drawn in `_draw()` with the filled length from the presenter; keeps the current tier centred on open), `JumpButton`, `ProgressBarToGo` (bar plus "160 to tier 13" text, never a percent), `RevealOverlay` (rays, sparks, flip-in cards; reduced motion: a fade and the cards), `BottomSheet` (scrim, drag handle, focus trap for screen readers), `StreakRow` (seven cells with glyphs, not colour alone), `GoalRow`, `LeagueRow`. Icons: export `icons_rbi.js` groups `season`, `leagues`, `currencies` to SVG once (the sibling plan's icon pipeline) and import them; the 3D Chronicler art in the banner becomes a rendered still of the model or a premium-track cosmetic still.
6. **View**: `scenes/season.tscn` with `scripts/season_screen.gd` replacing `track.tscn` (router name `&"season"`; keep `&"track"` as an alias for the Shop's "See the track"). Three tab pages; the Pass page's track lane is the only horizontal scroller; CLAIM ALL is a thumb-zone button; the Starpass offer is a bar with a money price from `StorePurchases.price` and opens a `BottomSheet` whose text is band-aware (§20.2) and says nothing about Starglass unless F41 brings it back (SS10).
7. **Order**: (a) Pass on today's server (50 tiers, claim, claim-through, premium purchase, reveal), (b) League road and the week's era (server additions 3, 4), (c) goals and streak once the server has them, (d) landscape layout: tabs on the left, track full width.
8. **Tests**: presenter tests for 50 tiers, the claimable list, the "N to go" texts in both languages, the era line; a11y layout at 150%/200% (the track cards are the risk: a card holding a 13 pt ribbon and a 16 pt amount is about 120 × 150 pt); a flow test that claim-all is one call.

Effort: **L** (the track lane and reveal are M on their own; goals and streak need server work first).

---

## 2. Shop (screen 18)

### 2.1 The §23.2 row and the rules behind it

> | Shop | Cosmetics. | Sets with real prices, previews on your universe, spending cap for minors (doc 11275–11277)

- §22.1 sells "Starglass, in packs from about €1 to €50", "The season pass premium track (cosmetic), about €6 a season", "Cosmetic sets: realm skins, sky themes, bridge styles, outfits, Sage robes, emotes, law visuals", "Occasional supporter packs"; never resources, characters, skips, shields, random boxes; "Every price is shown in real money before purchase … Players under 18 have monthly spending caps (20.2)."
- §20.2 Purchases: 13–15 "Family approval where set up; €25 a month cap"; 16–17 "€50 a month cap"; 18+ "Monthly spending summary".
- §19.12: "Every cosmetic shows its real-money price. Starglass exists only as a gift and season-pass wrapper, always at a visible 1:1 rate"; "Everyone sees the same shop, at the same prices."
- §9.1 and §9.5: Starglass is earned from purchases and the free track, spent on cosmetics and the premium track; "Cosmetics: Starglass only". (F41 records that these disagree with §19.12; the owner answered F41 with no currency at all.)
- §22.4: "Players can gift cosmetics to friends, with a monthly limit and parental approval rules for minors."
- §14.6: notifications "only for things the player can act on (storage full, a character rested, an experiment finished, a heist against you)".
- §14.8: "Progress bars never appear in the shop, and no purchase ever fills one."
- §23.5 rows: Text size; Landscape; The designs' own notes. None is about the Shop's content.

### 2.2 What the design shows

Top to bottom (meta markup 294–327; `shop_top/mid/bottom.png`):
1. Header (297): back; "Shop"; a Starlight pill "142.0k" (no action); a Starglass pill "480 = €4.80 +" that opens the Starglass category.
2. Category chips (298): All, Realm skins, Outfits, Sage robes, Emotes, Skies & bridges, Starglass.
3. Hero carousel with dots (300–305): "FEATURED SET · Lantern Festival" (Lantern Vale Heart, Lantern Dusk sky, Lantern Bridges; "PREVIEW ON MY UNIVERSE"; "€8.99 · 899 ✦"); "SEASON · HELD BREATH · Premium track" (30 extra looks, a realm skin, "Missed tiers stay"; "SEE THE TRACK"; "600 Starglass · ≈ €5.99 · once a season"); "SUPPORTER PACK · Workshop Makers" (Tinkerer apron, Hammer emote, Maker badge; "WHAT IS INSIDE"; "€4.99 · coming soon").
4. Rails (306): Daily picks and New this week ("Back again later, no rush"), Realm skins ("What raiders land on"), Outfits ("For any ruleborn"), Sage robes ("For one Sage"), Emotes ("After a heist"), Skies, bridges and laws ("Around your universe"). Each tile: a lit stage in the item's colours with its art (island disc for realm skins, a character for outfits and robes, an icon for world items), a kind tag, ♥ if wished, ✓ if owned, the name, and a price button "120 ≈€1.20" (Starglass first, euros second) or "EQUIP" / "✓ EQUIPPED".
5. Starglass (307): "100 ✦ is always €1"; six packs 100 / 500 / 1,000 / 2,000 / 3,000 / 5,000 at €1–€50 with what each buys ("A realm skin", "A full set", "12 outfits", "6 realm skins", "10 realm skins"); "No bonus packs, so every price is easy to compare. Starglass never expires."
6. Payments (308): "Through the App Store · ASK TO BUY · With Family Sharing, a parent approves each purchase. Limits are set in Screen Time." The same for every band (`capTxt`, meta.js 817). A cap bar is computed (`capBar`) but no markup draws it.
7. Footer (309): "LOOKS ONLY · Nothing here changes a heist. No random boxes. Every look comes back, so there is no rush."
8. Item page (311–323; `shop_detail_outfit.png`, `shop_detail_realmskin.png`): full-screen stage with a spotlight cone and a pedestal (a realm skin stands as an island disc), kind chip, ♥ wishlist, name and "for" line ("any ruleborn"; a set says "3 items · €10.40 bought apart"); description; for outfits "TRY IT ON" with five ruleborn to swap onto the pedestal; where it is seen ("Raiders see it the moment they land", "Seen in every heist and replay", "On your law cards when others scout you"); "Part of Lantern Festival: all 3 for €8.99 · VIEW ›"; "GIFT · 3 left this month" and "BUY · 160 ✦ · ≈ €1.60 · or pay in euros".
9. Buy sheet (324; `shop_confirm_*.png`): "BUY OUTFIT · Tide Raincoat · Pay with Starglass 160 ✦ · You have 480 ✦. That is Starglass you already bought, so your cap does not change." or, when short, "Pay with the App Store €8.99 · You have 480 ✦, not enough, so this is paid in euros. A parent approves it first."; a "Monthly cap after this" bar that never shows (`cCap: false`, meta.js 788–790); CANCEL and USE 160 ✦ / BUY €8.99 / OVER CAP.
10. Logic: cap €25 for 13–15, none otherwise (meta.js 718); a purchase past it is refused with "That would pass your monthly cap"; the gift decrements a monthly count of 3 and says "Gift sent to Ines · a parent approves first" with no recipient choice and no payment (meta.js 819); the wishlist says "On your wishlist. We tell you when it is back" (741); "PREVIEW ON MY UNIVERSE" goes home with a toast "Previewing Lantern Festival" (779).

Motion: bobbing hero art and item pedestal, glints, carousel snap, a scale-pop on buy.

### 2.3 Must-show check

| Must show | In the design | Verdict |
|---|---|---|
| Sets with real prices | Lantern Festival €8.99 with its three items and "€10.40 bought apart"; every tile shows ≈€ | Met for sets; tiles lead with Starglass (see SS10). The Season screen's Starpass shows no money price (SS9). |
| Previews on your universe | A button that goes home with a toast; the item page shows a generic pedestal | **Missing** (SS12). Outfits have "try it on" with five ruleborn, which is a preview on a character, not on the universe. |
| Spending cap for minors | Never shown: no cap bar, no "€x of €25 left", identical text for 13–15 and adults | **Missing** (SS11). The refusal toast exists in logic only. |

### 2.4 Where the design and v3.6 differ

| What | Design shows | Doc says | § | In §23.5? |
|---|---|---|---|---|
| Currency | Starglass balance, ✦ prices, packs, 1:1 | Doc keeps Starglass (§9.1, §9.5, §22.1) and also "only as a gift and season-pass wrapper" (§19.12); the owner's F41 answer removed the currency and the build has none | 9.1, 9.5, 19.12, 22.1 | No (SS10; register F41 still open) |
| Cap and band texts | One "Ask to Buy" text for all; no cap shown; no 16–17 band | €25 (13–15), €50 (16–17), adult monthly summary | 20.2, 22.1 | No (SS11) |
| Universe preview | Absent | Must show | 23.2 | No (SS12) |
| Wishlist notice | "We tell you when it is back" | Notifications only for things the player can act on | 14.6 | No (SS13) |
| Gift | Fixed recipient, no payment, "a parent approves first" for adults; 3 a month | A monthly limit (no number) and approval rules for minors | 22.4 | No (SS14) |
| Starlight pill in the Shop | Shows the building currency; code for Starlight prices exists (empty `PAY`, meta.js 720) | "Cosmetics: Starglass only" | 9.5 | No (minor; do not build a Starlight price) |
| Text size | 8.5–11 px tags and prices | 13 pt | 21.8 | Yes |

### 2.5 Silent adoptions

- Category chips, the hero carousel, rails with one-line reasons ("What raiders land on"), the lit stage tiles, the item page with spotlight and pedestal, "try it on" for outfits, "where it is seen", the set link on an item, the set's "bought apart" saving, "Every look comes back, so there is no rush", "No random boxes", a supporter-pack card (§22.1 lists them).
- Daily picks and New this week, provided they are the same for everyone at the same time (§19.12) and carry no timer.
- A wishlist ♥ as a private list (without the notification, SS13).

### 2.6 The build today

- `client/scripts/shop_screen.gd` (143 lines): wallet line (Starlight and Essence), status, a "Gifts go to <friend> · Another friend" picker, each item "name — €price" with Buy and Give, each owned item with "Worn by: role/law" and Wear/Take off, the months' spending lines and "€x left to spend this month" for a minor, buttons Season track and Home. `ShopPresenter.shop` (`shop_presenter.gd:124–162`) prices each item with the store's localized price when it has one (`money`, 17–22) and lists owned items with their slots; `ShopState.SHOP` and `WALLET` (`shop_state.gd:11–14, 23–38`); `ShopController.load_shop`, `buy`, `wear` (`shop_controller.gd:43–98`): intent (cap held) → platform store (`app/store_purchases.gd`; billing plugins not in the build, so it refuses) → receipt through the outbox (`shop_repository.gd:39–54`).
- Server: `GET /v1/cosmetics`, `POST /v1/cosmetics/equip`, `POST /v1/shop/intents {product, for?}`, `POST /v1/shop/receipts`, `GET /v1/shop/summary`, Apple refund notifications (http.mjs:75–82; `shop.mjs`): no currency (F41 answer), €25/€50 caps, adult summary, gifts as the same product bought for a friend, refunds. The catalogue is empty (`server/src/cosmetics.json`; D64). No gift monthly limit (D64: "the document gives no number"). No wishlist, rotation, or preview data.

### 2.7 What the server lacks

1. An authored catalogue (D64): per item id, kind, set, money price (store product id), art key, colours, "where it is seen" text key, and set membership with the set's price. The design's 17 items (meta.js 697–713) are a starting list, not data.
2. Rails: a rotation the server publishes (daily picks, new this week) identical for every player, or drop the rails.
3. Gift limit per month and minors' approval state once F41/§22.4 give a number (SS14); `GET /v1/shop/summary` to also return gifts left.
4. The band on the summary (`13-15`, `16-17`, `18+`) so the view does not infer it.
5. If Starglass returns (SS10): a balance, packs as store products, spending Starglass on cosmetics and the premium track, and its own refund rules.

### 2.8 The plan

1. **Decide SS10 first.** The design's price buttons, header pill, packs section and buy sheet copy all assume Starglass; the server and client assume none. Either way the money price is shown; only the second line changes.
2. **State and presenter**: keep `ShopState.SHOP`/`WALLET`; extend the slice with `rails`, `sets`, `wishlist` (device-local, `user://wishlist.cfg`, unless synced is wanted) and `preview` (the item being previewed). `ShopPresenter.shop` gains `rails()` (by category), `item(id)` (description, where seen, set link, try-on targets, owned/equipped, the buy button's two lines), and `payments(band, summary)`: for 13–15 "€x of €25 left this month" plus "a parent approves each purchase" only where family approval is set up; for 16–17 "€x of €50 left"; for 18+ "This month: €x" (§20.2). `confirm(item)` returns the price line and, for 13–15 and 16–17, the cap after this purchase as words and a bar (this is the cap, not a progress bar toward a goal, so §14.8 is not engaged; say "€6 of €25 used this month").
3. **Components**: `ChipRow`, `Carousel` (paged `ScrollContainer` with dots, swipe and two arrow buttons for one-finger, two-tap use per §20.8), `ItemTile` (stage, art, tags, price button), `PriceButton` (money first; a store-localized price string from `StorePurchases.price`), `ItemPage` (full-screen route `&"shop_item"` with params), `ConfirmSheet` (a `BottomSheet`), `CapMeter` (words first), `Toast`.
4. **Previews on your universe** (must-show): `ShopPreview` opens the shared 3D `World` (sibling home plan: one persistent `World` Node3D) on the player's own universe with the previewed realm skin, sky theme or bridge style applied as a temporary material/skin override that is never saved; a bar "Previewing Lantern Festival · Buy · Done". Outfits and robes preview on the player's own ruleborn models in a small `SubViewport` (the character models' export is the character report's work). Law visuals preview on a law card.
5. **View**: `scenes/shop.tscn` rebuilt as category chips, carousel and rails; the item page and buy sheet as described; owned items move into the item page (EQUIP) and a "Yours" category rather than the current long list; the gift picker moves into the item page's GIFT sheet (friend list from `ShopState.SHOP.friends`, the month's gifts left, approval words by band).
6. **Wishlist**: a private ♥ with no notification (SS13), or none.
7. **Tests**: presenter tests for three bands, with and without a store price, a set's saving, the cap line in both languages; flow tests for buy and gift through the fake store; a11y for the item page at 200%.

Effort: **L** (M without the 3D preview; the preview depends on the shared World and models).

---

## 3. Share sheet (screen 27)

### 3.1 The §23.2 row and the rules behind it

> | Share sheet | Share a moment or a challenge. | The 15-second clip, challenge link, invite gift, age-band limits (doc 11307–11309)

- §17.6: Highlight clips: "After each heist the game cuts a 15-second vertical clip of its best moment, with the laws labelled, ready to share in one tap." Challenge links: "Send your island to a friend as a playable challenge. Where the platform allows, it opens instantly in a lightweight version of the game; otherwise it installs straight into that island." Invites with gifts: "A personal invite gives both players a matching cosmetic when the friend plays their first heist." Friends' feed: the Beacon, "Visible to friends in the game".
- §20.7: sharing clips outside the game: 13–15 No, 16–17 "After a confirmation", 18+ Yes; challenge links: 13–15 "To in-game friends only", others Yes.
- §24 Clips: "The deterministic replay is rendered on the phone into a 15-second vertical video; no video is stored on the server unless shared." §24 Instant play.
- §19.10: "Make every heist worth showing to a friend, and make showing it one tap."
- §17.8: raids are anonymous while they happen.
- §23.5 row Share sheet (11460): "Shows the 13–15 message to an adult → Follows the player's age band (20.7)".

### 3.2 What the design shows

Header (589): back to the result, "Share". Tabs (590): Clip, Challenge, Invite.

**Clip** (591–594, 598; `share_clip*.png`): a 9:16 card tilted over a second card: world image, a dotted path with crew portraits, a law chip ("HALF GRAVITY"), "RULEBORN" mark, "EPIC MOMENT" chip, "0:15", tap to pause, a caption ("Pip clears the Vault wall under Half gravity"), three facts ("3,300 LOOT · ESCAPED 2:14 · AT 1:42") and a looping progress bar. Under it three moment thumbnails with rarity colours: Vault wall leap 1:42 (EPIC), Past a guard 0:48 (RARE), Close escape 2:11 (LEGENDARY) (meta.js 1221–1222). Bottom panel: "Post to the Beacon · Friends see it in their Beacon feed" with three friend avatars "+3" (becomes "Posted to the Beacon · Kofi, Lea and 3 more friends can watch it"); "OUTSIDE THE GAME · Opens at 16" with Save video, Messages, More greyed for every band (meta.js 1231; markup 598); a note "You're 13–15, so clips stay inside the game. Names are always hidden." for every band (meta.js 1238).

**Challenge** (595, 599; `share_challenge*.png`): "CHALLENGE · Can you get through my Heart?" with a toggle Heart / Sunken Clock (a Workshop island); a seal "HOLDS 62%" (or "BEAT 2:31"); three facts "Lv 7 REALM · 3 LAWS · 5 GUARDS" (or "38% ESCAPE RATE · Lv 6 BUDGET BAND · 214 PLAYS"); "SEND TO IN-GAME FRIENDS · 2 of 4 picked" with friend avatars (online, "3 h ago", "Beat it 2:05"); "Send to 2 friends" → "Sent. It opens straight into your island"; the note "Challenge links go to in-game friends while you're 13–15." for every band. No way to send the link outside the game.

**Invite** (596, 600; `share_invite.png`): "You · gift · A friend", "Twin lantern trim · A matching skiff cosmetic for both of you, unlocked when your friend finishes their first heist."; your invites (Lea "Joined 4 days ago · TRIM EARNED", Rui "Installed · first heist next · WAITING"); "YOUR INVITE CODE · KEEPER-7KQ2 · Copy"; Messages, Copy link, More; note "Invites never share your Keeper name or where you are."

### 3.3 Must-show check

| Must show | In the design | Verdict |
|---|---|---|
| The 15-second clip | Clip card, 0:15, laws labelled, three moments | Met (as a mock: a still and a path, not the replay) |
| Challenge link | Sent to picked in-game friends only, for everyone | Partly: for 16+ the link outside the game is missing (SS15) |
| Invite gift | Twin lantern trim card and status list | Met |
| Age-band limits | Always the 13–15 text and locks | Listed in §23.5; the 16–17 "after a confirmation" step has no design (SS15) |

### 3.4 Where the design and v3.6 differ

| What | Design shows | Doc says | § | In §23.5? |
|---|---|---|---|---|
| Band texts and locks | 13–15 for everyone | Follow the band | 20.7 | Yes (11460) |
| 16–17 clip sharing | No band | After a confirmation | 20.7 | No (SS15) |
| Challenge outside the game for 16+ | Not offered | Challenge links are links ("opens instantly in a lightweight version … otherwise it installs straight into that island") | 17.6, 20.7 | No (SS15) |
| Clip moments | Three moments with rarities | "its best moment" | 17.6 | No; adoptable as a choice, but the rarity needs a rule (SS16) |
| Challenge facts | "HOLDS 62%", "3 LAWS · 5 GUARDS" | Island difficulty is internal; holds sit in 30–45%; law and guard counts are a paid scout's | 12.15, 13.2, 12.4 | Demo numbers row covers 75%-type figures; the exposure itself is not listed (SS19) |
| Text size | 9–11 px chips | 13 pt | 21.8 | Yes |

### 3.5 Silent adoptions

- Three tabs; a tilted 9:16 clip card with the law chip, caption and facts; moment thumbnails to choose from (a choice of which moment to share changes nothing a player earns); "Post to the Beacon" with the audience shown; friend multi-pick for challenges with their online state or "Beat it 2:05"; a Workshop island as a challenge as well as one's own Heart; the invite status list; the line "Invites never share your Keeper name or where you are."

### 3.6 The build today

- Client: no share sheet, no clip. `FriendsController.make_challenge` (`client/features/social/social_controller.gd:139–147`) asks `POST /v1/challenges` and the Friends screen shows "Your challenge: <code>"; `make_invite` shows "Your invite to share: <code>" (`client/scripts/friends_screen.gd:39–40`; `social_presenter.gd:112–114`). The replay screen re-simulates a heist tick by tick (`client/scripts/replay_screen.gd`), which is what a clip renders from.
- Server: `POST /v1/challenges {realm?}` and `GET /v1/challenges/:code` (http.mjs:98–99; `friends.mjs:105–121`): a 12-hex code to the caller's island in a realm, open 7 days, leased with mode "challenge"; invites `POST /v1/friends/invites` (single-use, 7 days) and `/accept` (http.mjs:94–95). No invite gift (no first-heist trigger, no inviter link on the invitee), no challenge addressed to friends, no clip or post, no Workshop-island challenge. `GET /v1/heists/:token/replay` serves only the raider and the defender (http.mjs:11).

### 3.7 What the server lacks

1. Invite gift: record which invite an account accepted at first sign-in (an invite code carried through install by a deep link or typed), and on that account's first validated heist grant the matching cosmetic to both; `GET /v1/friends/invites` listing the caller's invites with state (sent, joined, first heist done, gift given).
2. Challenges to chosen friends: `POST /v1/challenges {realm | workshop, to: [accounts]}` creating feed items for those friends (and for 13–15, only to friends, which is already the only path).
3. Clip posts: `POST /v1/clips {heist, from_tick, to_tick}` (no video: the friends' phones re-render from the replay), feed items of kind "clip", and replay access for a poster's friends limited to the posted window and to the replay's retention (§24.3, 30–90 days). Blocks and §20.7 apply; G35's "13–15 heists appear in no feed" must be squared with a 13–15 posting (SS16).
4. Deep links: universal links / app links for `challenge/<code>` and `invite/<code>`; a web fallback page that opens the store (server `pages.mjs` already serves pages).

### 3.8 The plan

1. **Dependencies**: the sim's event log and the moment picker from the heist/result report (its SIM-H2 and TC-R) choose the moments; the shared 3D World in replay mode (its TC-W) draws them.
2. **Clip, in game first**: `ClipCard` is a `SubViewport` (portrait 9:16) running the World in replay mode on the moment's tick window, with an overlay `Control` for the law chip, caption, facts and progress; tap to pause. `ClipPresenter` builds the caption from the event (law name from content, crew member's kind name; never a player's name). Posting to the Beacon sends the window (server 3), not a video.
3. **Clip, outside the game** (16–17 after a confirmation sheet, 18+ directly): render the window offline at a fixed frame rate into images and encode with the platform's encoder through a small plugin (iOS AVAssetWriter, Android MediaCodec), then hand the file to the OS share sheet. I did not find a runtime video encoder in Godot for phones; its Movie Maker mode is a command-line/editor mode. This is the XL part and can follow the in-game clip.
4. **Challenge**: `ChallengePresenter` (Heart or another realm, or a Workshop island the player published; the facts shown are the free scouting facts of §12.4: name, Keeper level, realms, Renown, a rough loot estimate, and for a Workshop island its plays and clear rate as the Workshop already lists them), a `FriendPicker` (multi-select avatars with a spoken state), "Send to n friends", and for 16+ a "Copy link / Messages / More" row through the OS share sheet with the deep link.
5. **Invite**: code with Copy, the OS share sheet, the gift card, the status list from server 1.
6. **Band**: `ShareRules.for_band(band)` returns which rows show, which are locked with words, and whether a confirmation sheet comes first; one table for the Share sheet, Friends and Profile, from §20.7 and §20.2, tested for all three bands.
7. **Route**: `&"share"` with params `{tab, heist?}`; opened from the result's moment card (sibling F14), from the feed's own clips, and from Friends' Invite.

Effort: **XL** (L without video export).

---

## 4. Friends (screen 28)

### 4.1 The §23.2 row and the rules behind it

> | Friends | Play together. | Friends' feed, friendly heists, invitations, gifts (doc 11311–11313)

- §12.11: "Friendly heists (at launch): rob a friend's island for fun. The friend loses nothing, both see the replay, and the friend earns a page for every raider their guards catch." 13–15 use preset pings in co-op (1.1).
- §17.6 (feed, clips, challenge links, invites with gifts), §17.8 (blocking hides each from the other; islands still meet as targets "because a raid takes nothing … and raids are anonymous while they happen"), §20.2 (chat by band; profile private for 13–15, private by default for 16–17), §20.4 ("Report and block from any name or message; reports reviewed by a person within 24 hours"), §20.5 (collect only what's needed), §20.7, §22.4, §19.10 ("a friend's island, a friendly heist or a co-op invite is always one tap from home").

### 4.2 What the design shows

1. Header (607): "Friends", a "3 online" pill, "Add" (→ Invite tab).
2. A row of friends (608): avatars with school badge and league icon, a status pill RAIDING / WORKSHOP / HOME, or "3 h ago" / "Yesterday".
3. Tabs (609): Feed (badge 4), Friends, Invite.
4. **Feed** (610–612; `friends_feed.png`): a hero card "FRIENDLY RAID · 1 H AGO · Tomas raided your Heart · Your guards caught 2 of his crew. · +2 pages earned · Raid Tomas back · Replay"; TODAY / EARLIER items with avatar, kind chip, time, text and an action tile: Kofi ESCAPED "Kofi's crew slipped through Ines's Glowing dark with 2,300 Starlight." (Watch, 0:15); Lea CHALLENGE "Sent you her Lantern Vale to beat: Stillness and Echoes, 2:30 on the clock." (Play, FOR YOU); Aiko HATCHED "Hatched a Spark Emberling. It was born swift, a body trait." (Cheer); Ines PUBLISHED "Published 'Tower of Held Breath', a Workshop island with Stillness and Echoes." (Play) (meta.js 1252–1256); footer "Only friends see this feed. Raids show no names while they happen."
5. **Friends** (613; `friends_list.png`): ONLINE · 3 and OFFLINE · 2 sections; each row: avatar with a presence dot, name, league icon, "Lv 31", status ("● Raiding Ines", "In the Workshop", "At home", "Seen 3 h ago"), "Friendly heists · you 3, Kofi 1", and "Raid · FOR FUN"; footer "A friendly heist takes nothing. Your friend earns a page for every raider their guards catch."
6. **Invite** (614–616): "Bring a Keeper" card with the Twin lantern trim, "YOUR CODE · KEEPER-7KQ2 · Copy", "Send invite" (→ Share sheet), "ADD BY CODE" field (KEEPER-0000, 11 characters) and Add ("Friend request sent"), "YOUR INVITES" list; for 13–15 "You're 13–15, so challenge links go to in-game friends only."
7. **Friend sheet** (617–626; `friends_sheet_kofi.png`, `friends_block.png`): avatar, name, "Nova league · Keeper 31", status pill "RAIDING · Raiding Ines"; the friend's island card "Kofi's Verdant · 31 KEEPER LV · 6 REALMS · 44% DEFENCE HOLDS"; a friendly-heist score "3 · You lead · 1"; "Friendly heist · Kofi loses nothing, and earns a page per raider caught"; Challenge, Gift a look (→ Shop; 13–15 "Pick a look. A parent approves it first"), Replay; "SEND A PING": Good heist!, Rematch?, Raid me!, Nice defence!; Block and Report ("Report sent. A person reviews every report"); the block confirm "Kofi won't see you in friends, pings or invites, and you won't see Kofi. Your islands can still meet as raid targets, because a raid takes nothing."
8. Bottom tab bar (627–636) with Friends active.

### 4.3 Must-show check

| Must show | In the design | Verdict |
|---|---|---|
| Friends' feed | Feed tab | Met |
| Friendly heists | Raid FOR FUN on every row, Friendly heist in the sheet, Raid back from the feed | Met |
| Invitations | Invite tab, code, add by code, status | Met |
| Gifts | Gift a look (→ Shop), the invite gift | Met |

The design's own note adds "Who's online", "page gifts" and "preset pings"; those are not §23.2 must-shows (§23.5's last row). Page gifts are not drawn (the TRY note's "send a page" has no control), which is right: page requests belong to constellations in 1.1 (§17.4).

### 4.4 Where the design and v3.6 differ

| What | Design shows | Doc says | § | In §23.5? |
|---|---|---|---|---|
| A raid named while it happens | "● Raiding Ines" on the row, pill and sheet (meta.js 1241) | "raids are anonymous while they happen" (and the design's own footer says so) | 17.8 | No (SS17) |
| Presence, last seen, pings | Online counts, status, "Seen 3 h ago", four preset pings | Not in the document; 13–15 profile private; notifications only for actionable things; chat rules by band | 20.2, 20.5, 14.6 | No (SS18) |
| A friend's hold rate | "44% DEFENCE HOLDS" | Island difficulty stays internal; free facts are name, Keeper level, realms, Renown, rough loot | 12.15, 12.4 | No (SS19) |
| Block text | "because a raid takes nothing" | §17.8 says the same, but §9.4's Open Vault league takes loot | 17.8, 9.4 | No (SS23, a v3.6 contradiction) |
| Remove a friend | Not offered | Not required; the build has it | — | — |
| Text size | 7.5–10 px pills and chips | 13 pt | 21.8 | Yes |

### 4.5 Silent adoptions

- The avatar row, the three tabs, the hero card for the latest friendly raid on you with "Raid back" and Replay, the feed cards with an action tile, HATCHED and PUBLISHED entries ("what friends just did", §17.6), Cheer (a reaction, earns nothing), the friendly-heist score between two friends (a record of friendly heists; earns nothing), online/offline grouping if SS18 keeps presence, the friend sheet with Friendly heist, Challenge, Gift a look, Replay, Block and Report, the block confirmation that says what blocking does and does not do.

### 4.6 The build today

- `client/scripts/friends_screen.gd` (79 lines): title, status, friends by name with Remove, blocked players with Unblock, the feed as text lines ("Keeper 3F2A raided Keeper 9A1C: Clean"), an invite-code field with Accept, Invite a friend, Challenge, Home. `SocialPresenter.friends` (`social_presenter.gd:92–118`), `SocialState.FRIENDS` (`social_state.gd:12, 31–38`), `SocialController.load_friends`, `make_invite`, `accept`, `unblock`, `remove`, `make_challenge` (`social_controller.gd:86–147`), `FriendsRepository` (`client/data/repositories/friends_repository.gd`). Players are "Keeper" and four letters until platform friend names are wired (`social_presenter.gd:34–38`).
- Server: friends, invites, accept, remove, feed (validated heists of friends in the last 7 days, minus anyone 13–15 and anyone blocked), challenges (http.mjs:93–99; `friends.mjs`); blocks (http.mjs:19–21). Friendly heists are leases of mode "friendly", settled with no Renown, stars or rating, and `friendPages = verdict.caught` (`service.mjs` 760–790; F48). No presence, pings, player reports (only Workshop reports, http.mjs:44), per-friend card facts, friendly-heist score, hatch/publish feed items, or feed entries for challenges.

### 4.7 What the server lacks

1. `GET /v1/friends` to return each friend's free facts (§12.4: Keeper level, realms, Renown and league), a friendly-heist score per pair (count of mode "friendly" leases each way with their outcomes), and "since".
2. Feed items beyond heists: challenges sent to me, Workshop publishes (exists in `workshop_items`), clip posts (Share 3), hatches only once the roster is on the server (D64; TC.12).
3. `POST /v1/reports {account, reason}` for players (§20.4), into the moderation queue the Workshop's reports use.
4. If SS18 keeps them: presence (last seen at a coarse grain, never the target of a raid), preset pings with a daily cap and §20.2's night hours.
5. The latest friendly raid on me with its replay token (the defender can already fetch the replay).

### 4.8 The plan

1. **State**: keep `SocialState.FRIENDS`; widen the friend entries (facts, score, presence if kept) and the feed entries (kind, actor, object, action, replay token or challenge code). Add `pings` and `reports` only if decided.
2. **Presenter**: `FriendsPresenter` (split from `SocialPresenter`) with `row()`, `feed()` (kinds raid/escape/foiled/challenge/publish/clip/hatch; never names a defender while a raid is live; after it, as §17.6's example does), `sheet(friend)` (free facts only, no hold rate), `invite()` and `band_rules` from the shared `ShareRules`.
3. **Components**: `Avatar` (portrait, school badge, league icon, optional presence dot with a spoken state), `AvatarRow`, `FeedCard` (with an action tile), `HeroCard`, `FriendRow`, `CodeField` (uppercase, KEEPER-format mask, paste), `PingChips` (if kept), `ConfirmSheet` for block, `ReportSheet` with reasons.
4. **Flows**: Friendly heist → the planner with mode "friendly" (the lease mode exists); Raid back → the same; Replay → the replay route with the token; Gift a look → Shop item page in gift mode; Challenge → Share sheet's Challenge tab with the friend preselected; Add by code → `accept(invite)` as G35 decided (the toast says "You and Kofi are friends", not "request sent").
5. **Names**: platform friend names when the platforms' friend lists are wired (README "Players are named Keeper…"); until then the Keeper tag.
6. **Remove** stays, in the sheet's overflow.

Effort: **M** (L if presence and pings are built).

---

## 5. Profile and stats (screen 20)

### 5.1 The §23.2 row and the rules behind it

> | Profile and stats | Your record. | Renown and league over time, never the internal rating (12.15); heists by outcome (12.9); defences held and leaked; records; the battle log with replays; collection and badges. Private, with no sharing, for 13 to 15 (20.2) (doc 11315–11317)

- New in v3.6 (adopted from the designs, §23.5 11400), with the "Profile header" deviation (11470): "Rating" → Renown.
- §12.15 ratings are internal; §12.9 the four outcomes; §20.2 Profile: 13–15 Private, 16–17 Private by default, 18+ Player's choice; §24.3 raw replays kept 30–90 days; §20.5 analytics pseudonymous.

### 5.2 What the design shows

1. Header (330): back, "Profile", SHARE (hidden for 13–15: `shareOn`, meta.js 832; toast "Profile card copied").
2. Identity card (333–334): portrait with Keeper level 24, "Wren", "#7KQ2-19 · Keeper for 214 days", "Title · Quiet Thief", a TIDE II badge; "1,460 RATING", "340 to Star league", a bar with "Tide 1,200 · Best 1,620 · Star 1,800".
3. Tabs (336): Overview, Battle log, Collection.
4. **Overview** (337–358; `stats_overview_*.png`): "Renown" chart (value, the selected day's change, "+201 in 30 days", ranges 7D / 30D / Season, a line with area, per-day gain/loss bars, tap a day); "Heists and defence": Heists 71% ring "128 won · 52 lost" with a last-10 strip "7 in a row", Defence 75% "94 held · 31 leaked" "3 in a row" (meta.js 850); "How heists end": a donut of 180 heists, Clean 23%, Loud 48%, Partial 21%, Foiled 8%, tap a slice (the centre label is wrong: Loud shows "PARTIAL", Partial shows "CAUGHT", meta.js 855; `stats_donut_loud.png`); "Escape time": 2:06 average, "14 s faster than last season", an 8-bin histogram; "Pages studied by school": a six-school radar, this season against last with deltas; "Defence by realm": held/leaked bars per realm with ▲▼ trend and a line "Skyfield leaks most. Raiders come in over the west bridge."; "When you play": a 12-week heatmap, tap a day for minutes, "60 days · 6-week best streak, 4 days in 7 · 33 min a day"; "Records": ten tiles (best win streak, fastest heist, best haul, clean escapes, pages studied, guards slept past, alarms per heist, crew knocked out, raiders stopped, most realms raided); "Favourites": three ruleborn with heist counts and the favourite law "Stillness · in 84 heists · TIME"; "Seasons": this, last and best with league and Renown.
5. **Battle log** (359–363; `stats_log.png`): filters All / Heists / Defence; cards with an outcome edge colour, title ("Raided Marta", "Ines raided you"), line ("Loud · studied Sleepwalk · 2:14"), chip (LOUD, HELD, FOILED, CLEAN, LEAKED), Renown change, crew portraits, time, REPLAY ("Replays come later"); "Your last 25 raids are kept here."
6. **Collection** (364–369; `stats_collection.png`): "Collection 66 / 124"; Laws found 18/24, Resonances 3/12, Ruleborn 14/22, Forms 31/66, each with "Next: …"; Badges: nine medals in bronze/silver/gold with progress (First heist, Ghost, Vault breaker, Iron wall, Law hunter, Resonant, Hoarder, Friendly, Paradox; meta.js 830).

### 5.3 Must-show check

| Must show | In the design | Verdict |
|---|---|---|
| Renown and league over time | Renown chart with ranges; Seasons list | Met; the header says "RATING" (listed) |
| Never the internal rating | Only the label | Listed (Profile header) |
| Heists by outcome | Donut with four outcomes | Met; labels wrong on tap (SS20) |
| Defences held and leaked | Defence card, per-realm bars | Met |
| Records | Ten tiles | Met; most need data nothing keeps (SS22) |
| Battle log with replays | Battle log with REPLAY | Met in shape (the button is a stub) |
| Collection and badges | Collection tab | Met; badges are undefined in the document (SS21) |
| Private, no sharing, for 13 to 15 | SHARE hidden for 13–15 | Met for the share button; 16–17 "private by default" has no design, and what a friend sees of a 13–15 player (Friends sheet) is not covered (SS18) |

### 5.4 Where the design and v3.6 differ

| What | Design shows | Doc says | § | In §23.5? |
|---|---|---|---|---|
| Header label | "RATING" | Renown | 12.15 | Yes (11470) |
| Donut labels | Loud → "PARTIAL", Partial → "CAUGHT" | Clean, Loud, Partial, Foiled | 12.9 | No (SS20) |
| Won/lost | Partial counted as lost (128 = Clean+Loud, 52 = Partial+Foiled) | Four outcomes; Partial pays ×0.4 and Renown ×0.5 | 12.9 | No (SS20) |
| Renown changes in the log | Foiled −18, Held +14 | Foiled −8 flat; defender the mirror | 12.9 | No (covered by SS7's evidence; the build shows the server's numbers) |
| Holds | Defence 75%, The Heart 90% | 30–45% | 13.2 | Yes (Demo numbers, 11555) |
| Collection totals | Forms 31/66, Ruleborn 14/22, total 124 | 54 forms (18 kinds × 3 notes); 18 kinds | 11.10, 11.2 | Data, not listed; the build counts from content |
| "Hourkeeper visits at Lv 26" | A kind arriving as a visitor at a level | Hourkeeper is one of the 18 kinds (Mender, Time), born or found | 11.2, 11.5 | Data; build writes "Next" lines from rules |
| Favourite law badge | Stillness drawn with a pause sign | The school's shape | 23.2 (law card) | Yes (Law card row) |
| Text size | 8–11 px axis labels and captions | 13 pt | 21.8 | Yes |

### 5.5 Silent adoptions

- The identity card (Keeper level on the portrait, tag, days as Keeper, title, league badge, "N to Star league" with the league floor and best marks), three tabs, the Renown chart with 7D/30D/Season and tap-to-read, the heist and defence split cards with last-10 strips (as outcome strips, SS20), the outcome donut, escape time histogram, pages by school radar, defence by realm with a one-line reason, the play calendar (days played; minutes only if SS22's source is settled), records, favourites, seasons list, the filtered battle log, collection bars with "Next", badges as medals with progress. All are displays of the player's own record and change nothing they can earn, provided badges pay nothing.

### 5.6 The build today

- Client: nothing. The closest pieces are `SocialRepository.result(season)` (`client/data/repositories/social_repository.gd:21`, the closed season's result) for the Seasons list, `SocialPresenter.league` for the header, `AccountRepository.keeper()` (`account_repository.gd:63`) for the level, and the replay route for REPLAY.
- Server: everything the Overview needs is partly in tables, not in a route. `renown` rows with `at` (Renown over time, `db.mjs` 333–347); `season_results` (league by season); `heists` with `outcome` JSON carrying the verdict (grade, out, caught, crew count, banked, capacity, pages, cracked, left — `sim.mjs:103–107`), the haul and Renown (`service.mjs` 790); `leases` with attacker, defender, realm and mode (defences held/leaked, per realm); `GET /v1/heists/:token/replay` for the raider or defender (http.mjs:11), replays deleted after 30–90 days with the row kept (`replay_gone`, `db.mjs` 176–179). Not kept anywhere: escape time, alarms, knockouts, guards passed, laws crossed per heist (telemetry records laws, pseudonymously), the defender's entry edge, minutes played, pages/forms/roster counts (device, D64), badges and titles.

### 5.7 What the server lacks

1. `GET /v1/profile` (the caller's own only; 13–15 never shareable): identity (tag, Keeper level, first-seen date, title), Renown series by day for 7/30 days and the season, best Renown this season, league history from `season_results`, heists by outcome, defences held/leaked overall and per realm with last season's comparison, records, favourites, the battle log page (last N raids and raids on you with tokens, outcome, Renown change, crew kinds, whether the replay is still kept), collection counts it holds, badges.
2. Per-heist facts written at settle from the re-simulation: escape tick, alarms raised, knockouts, guards passed asleep, realms entered, laws crossed, entry edge. These need sim exports (the heist report's event log, SIM-H2).
3. Badge definitions and progress (SS21), titles (§18.5 mastery milestones).
4. `GET /v1/profile/card` for a shareable card for 16+ by choice (16–17 off by default).

### 5.8 The plan

1. **State**: `ProfileState.PROFILE` (overview, log pages, collection, filters, ranges) with reducers; device-held counts (pages by school, forms, roster) merged from local stores until TC.12 moves them server-side, and marked so.
2. **Repository**: `ProfileRepository.overview()`, `.log(filter, before)`, `.card()`.
3. **Presenter**: `ProfilePresenter.header` ("Renown", never "rating"), `.renown(range)` (points, selected day, totals in words), `.split` (by outcome, not won/lost: four counts and a strip of the last ten outcomes with glyphs), `.donut` (each slice named by its outcome), `.defence_by_realm`, `.calendar` (days played; minutes only if decided), `.records`, `.favourites`, `.seasons`, `.log` (rows with outcome glyph and words, Renown change, "Replay" or "Replay no longer kept"), `.collection` (counts from content: 24 launch laws, 12 launch resonances, 54 forms, 18 kinds plus paradox-born as owned), `.badges`.
4. **Components**: chart controls drawn in `_draw()` with `draw_polyline`, `draw_arc`, `draw_colored_polygon`: `LineChart` (with day bars), `RingStat`, `Donut`, `Histogram`, `Radar` (six schools, each with its shape mark), `HeatCalendar`, `BarPair`; each chart has a text equivalent for screen readers (§20.8 "every menu, card and result works with VoiceOver and TalkBack") and a table toggle; tap targets 48 pt. `StatTile`, `MedalBadge`, `LogCard`, `FilterChips`, `RangeSegments`.
5. **Privacy**: 13–15 never sees SHARE; 16–17 sees it only after switching "Profile visible to friends" on in Settings; 18+ chooses. What friends see of the player (Friends sheet) follows the same switch.
6. **Route**: `&"profile"` with tab param; entries from the home portrait/menu (sibling shell), from the result ("star after a heist"), and from Settings.

Effort: **L** (M for the screen; the server aggregation and the per-heist facts make it L).

---

## 6. Findings for the register

Each is a conflict between Screens v3 and v3.6 not listed in §23.5, a must-show the design omits, a gap the build must decide, or a v3.6 self-contradiction. Ids are this report's.

**SS1 (blocking, deviation) The Starpass buys progress.** "+20% ★" on the tier strip when the pass is owned (meta.js 670 `boostOn`; markup 264) and every quest paying ×1.2 with it (meta.js 684 `rT: '+' + (sPrem ? Math.round(q.r * 1.2) : q.r)`), plus a daily quest only pass holders can claim ("Starpass: win a heist unseen", meta.js 4 `prem: 1`). More stars buy free-track tiers, which pay Essence and pages. §18.8 (v3.6): "The premium track sells looks and nothing else (22.1)"; §20.3: "No power, speed or skipped waiting for money"; §14.8: "no purchase ever fills one". Rec: build neither; quests pay the same with or without the pass; no pass-only quest.

**SS2 (significant, deviation) Quests are not §14.6's daily goals, and season and event quests are new earnings.** Design: four fixed daily quests with one free swap, four season quests (+120 to +200 stars) and two event quests ("Event · The Still Hour · 4 days", +300, +400) (meta.js 3–5; markup 277). §14.6: "the player picks 3 of 6 offered goals … with one free swap. Rewards are small and shown as progress toward something the player chose." §9.1 and §18.2 name the sources of stars; nothing in v3.6 defines season or event quests, and a time-limited quest sits badly with §18.8's "Nothing expires forever". Rec: build §14.6 (offer six, pick three, one swap, small rewards); season and event quests only if written into §14.6/§18 first, with their caps (§20.3).

**SS3 (significant, deviation) The weekly streak pays non-cosmetic rewards, needs ten minutes a day, and has no saver or repair.** Seventh cell "+100" with a chest (meta.js 683); "Today · 6 of 10 min" (markup 276). §14.6: "playing on 4 days out of 7 keeps it going. One automatic saver a week covers a missed week, and a broken streak is repaired by playing two days in a row. Streak rewards are cosmetic." §19.12 refuses obligation. Rec: any play counts as a day; show the saver and the repair; the reward a cosmetic.

**SS4 (significant, deviation) The era is drawn as a chapter of the track; the week's era is missing.** Gates "ERA II · THE STILL HOUR" and "ERA III" before tiers 11 and 21 (meta.js 628); §18.3: "Each week one rule changes for every universe" (eight named eras); §23.2 Season must show "era". Rec: show this week's era, its rule in words and when it ends (server `GET /v1/era` exists); no era gates on the track.

**SS5 (significant, deviation) The free track gives a Sage the document does not have.** "Free at tier 30: The Chronicler" (markup 262; meta.js 153 puts the Chronicler at free tier 50). §18.2: the free track gives "pages, Essence and a stray"; §11.7 has four Sages unlocked by Keeper level; the Chronicler appears in v3.6 only in §23.5's character-sheet table (its Rewind power refused). Rec: no Sage on the track; the premium track may carry a Sage robe for an existing Sage.

**SS6 (significant, deviation) League rewards: Starglass and pages for every league, and "the highest league you reached".** League road (meta.js 688; markup 287). §18.5: "Star, Nova and Paradox leagues with season-end cosmetics"; §9.1: Starglass earned from "Purchases; small amounts from the free season track"; §18.1: "rewards are given by league"; the server grants by the final league, a cosmetic to the top three only (`server/src/seasons.mjs:46–53, 178–203`). Rec: show what the server grants; state in §18.1 whether the reward follows the final or the highest league, and what Dust, Ember and Tide get (G27 is the related open item).

**SS7 (significant, deviation) "Earn renown: +30 Heist won, +20 Defence held, −10 Vault raided."** (meta.js 693; markup 285). §12.9: 20 × (1 + Δ/1,000), between 8 and 40, × outcome; foiled −8 flat; the defender the mirror. The battle log repeats wrong figures (foiled −18, held +14; meta.js 829). Rec: the League tab states §12.9 in words; the log shows the server's numbers.

**SS8 (minor, deviation) Star chests after the last tier.** "AFTER TIER 30 · STAR CHESTS · One every 500 ★ · up to 10 a season" (markup 268). §18.2 has fifty tiers and nothing after them; a reward loop is a new earning. Rec: not built unless written into §18.2 with its contents and cap.

**SS9 (minor, deviation) The Starpass shows no money price on the Season screen.** "600 ✦" and "Buy for 600 Starglass" (markup 272, 290); the Shop's card says "≈ €5.99", while "100 ✦ is always €1" makes 600 ✦ €6.00. §22.1: "Every price is shown in real money before purchase"; §19.12. Rec: the store's localized price on the bar and the sheet.

**SS10 (blocking for the Shop build, gap; updates F41) The design prices everything in Starglass; the owner's F41 answer removed it.** Design: Starglass pill "480 = €4.80", tiles "120 ≈€1.20", packs 100–5,000 ✦, "No bonus packs … Starglass never expires", buy sheets paying in ✦ (markup 297, 306–307, 324). v3.6 still has Starglass (§9.1, §9.5 "Cosmetics: Starglass only", §22.1 "Starglass, in packs from about €1 to €50") and also §19.12's "only as a gift and season-pass wrapper"; the server and client follow the owner's answer: "there is no currency" (`server/src/shop.mjs:1–13`; `client/scripts/shop_screen.gd:1–6`). Rec: confirm F41's answer and amend §9.1, §9.5, §18.2, §22.1 to match (then the design's ✦ lines become money lines), or reverse it and rebuild the server's currency; either way decide before the Shop and Season are drawn.

**SS11 (significant, deviation) The Shop and the Starpass sheet ignore §20.2's purchase row.** Everyone sees "Through the App Store · ASK TO BUY · With Family Sharing, a parent approves each purchase. Limits are set in Screen Time." (meta.js 817) and "Ask to Buy applies" (markup 290); the cap is computed only for 13–15 (€25, meta.js 718) and never drawn (`capBar` unused, `cCap: false` meta.js 788–790); 16–17 does not exist; adults get no monthly summary. Captures for 18+ and 13–15 are identical. §20.2: 13–15 "Family approval where set up; €25 a month cap", 16–17 "€50 a month cap", 18+ "Monthly spending summary"; §23.2 Shop must show "spending cap for minors". Rec: band-aware payments panel and buy sheet; the cap shown before purchase; the server already holds both caps and the summary.

**SS12 (significant, deviation) No preview on the player's universe.** "PREVIEW ON MY UNIVERSE" only navigates home with a toast (meta.js 779); the item page shows a generic pedestal. §23.2 Shop must show "previews on your universe". Rec: preview realm skins, skies and bridges on the player's own universe in the 3D world, unsaved.

**SS13 (minor, deviation) The wishlist promises a notification.** "On your wishlist. We tell you when it is back" (meta.js 741). §14.6: notifications "only for things the player can act on (storage full, a character rested, an experiment finished, a heist against you)"; §19.12 refuses offers timed to weakness. Rec: a private wishlist with no notification, or none.

**SS14 (minor, gap) §22.4's monthly gift limit has no number; the design uses three, and gives with no recipient or payment.** "GIFT · 3 left this month"; "Gift sent to Ines · a parent approves first" for adults too (meta.js 718, 819). D64 already notes the missing number. Rec: adopt 3 a month into §22.4 (via §23.5's adopted table) or set another; the gift flow picks a friend and pays like a purchase, with approval words only for minors.

**SS15 (minor, gap) The Share sheet models two bands, so 16–17's confirmation and adults' challenge link outside the game have no design.** Clip: "OUTSIDE THE GAME · Opens at 16" locked for everyone (markup 598; meta.js 1231); Challenge: friends in the game only, for everyone (markup 599). §20.7: clips outside the game for 16–17 "After a confirmation"; challenge links for 16+ are links (§17.6: "opens instantly in a lightweight version of the game; otherwise it installs straight into that island"). §23.5 lists the 13–15 message shown to adults, not these two. Rec: build all three bands from §20.7; add a confirmation sheet for 16–17 and a Copy link / OS share row for 16+.

**SS16 (minor, gap) Posting a clip to the Beacon: what is stored, who may watch, the rarity labels, and minors.** Design: "Post to the Beacon · Friends see it in their Beacon feed", moments graded EPIC/RARE/LEGENDARY (meta.js 1221–1229). §24 Clips: "no video is stored on the server unless shared"; §17.6's feed is "Visible to friends in the game"; the owner's G35 answer keeps 13–15 players' heists out of every feed, yet the design lets a 13–15 post. Nothing defines a moment's rarity. Rec: post the replay window, not a video; friends re-render it while the replay is kept (§24.3); decide whether a 13–15 may post; give rarity a rule or drop it.

**SS17 (significant, deviation) Friend status names the target while a raid happens.** "● Raiding Ines" on the friend row, pill and sheet (meta.js 1241; `friends_list.png`, `friends_sheet_kofi.png`). §17.8: "raids are anonymous while they happen"; the design's own feed footer says "Raids show no names while they happen." Rec: "Raiding" with no target, or no live status (see SS18).

**SS18 (significant, gap) Presence, last seen and preset pings are not in the document.** Design: "3 online", ONLINE/OFFLINE sections, "Seen 3 h ago", RAIDING/WORKSHOP/HOME, four preset pings (meta.js 1241–1285; markup 607–623); the same for 13–15. v3.6 has no presence or friend messaging at launch; §20.2 makes a 13–15 profile private and 16–17 private by default; §20.5 collects only what is needed; §14.6 limits notifications to actionable things. These change what a player can see and do, so they are mechanics under §23.5. Rec: decide whether to build presence and pings at launch; if yes, write them into §17.6 with what 13–15 and 16–17 show to friends, a ping's daily cap, and whether a ping notifies.

**SS19 (minor, deviation) Island difficulty is shown on the friend sheet and the challenge card.** "44% DEFENCE HOLDS" (meta.js 1277) and "HOLDS 62%" with "3 LAWS · 5 GUARDS" (meta.js 1223). §12.15: island difficulty is rated internally and "the raw numbers are never shown, because visible ratings invite target-shopping"; §12.4: law and guard counts are a paid scout's; §13.2: holds sit in 30–45%, so 62% is also a demo number. Rec: show §12.4's free facts only; keep a player's own hold rate on their own Profile.

**SS20 (minor, finding) The outcome donut mislabels two outcomes, and the split counts a Partial as lost.** `dL: ['CLEAN', 'PARTIAL', 'CAUGHT', 'FOILED'][ds]` against slices Clean, Loud, Partial, Foiled (meta.js 855; `stats_donut_loud.png` shows "87 PARTIAL" for Loud); 128 won = Clean 41 + Loud 87, 52 lost = Partial 38 + Foiled 14 (meta.js 850, 852). §12.9: four outcomes; a Partial pays ×0.4 and Renown ×0.5. Rec: name each slice by its outcome; show the split by outcome or define "won" in §12.9.

**SS21 (minor, gap) Badges and titles are must-shows with no definition.** §23.2 Profile: "collection and badges"; §18.5: mastery "Milestones unlock titles"; §18.7: the creator badge. The design proposes nine badges with bronze/silver/gold thresholds (meta.js 830) and a title "Quiet Thief". Rec: list the launch badges and titles (each pays nothing) in §23.5's adopted table or §18.5, and give the server their counters.

**SS22 (minor, gap) The Profile's records need facts nothing keeps, and its log promises "the last 25 raids".** Escape time, alarms per heist, guards slept past, knockouts, most realms in one raid, the entry edge ("Raiders come in over the west bridge"), favourite law, minutes played a day; pages, forms and roster counts are on the device (D64). The verdict holds only grade, out, caught, crew, banked, capacity, pages, cracked, left (`server/src/sim.mjs:103–107`). "Your last 25 raids are kept here" (markup 362) against §24.3's 30–90 days for raw replays. Rec: write the needed per-heist facts at settle from the re-simulation (with the sim's event log), keep log rows longer than replays and say when a replay is gone, and derive the calendar from days with a validated heist or defence unless minutes are wanted (then decide the source, given §20.5's pseudonymous analytics).

**SS23 (significant, contradiction in v3.6) §17.8's "a raid takes nothing" is false in §9.4's Open Vault league, and the league has no screen or build.** §17.8: "Their island can still appear as a target … a raid takes nothing: there is no harm to be protected from"; §9.4: "Players who want real stakes opt into the Open Vault league, where the rules below apply in full and rewards are 40% higher on both sides" (loot leaves the defender). The design's block sheet repeats §17.8 (meta.js 1284). Neither Screens v3 (League tab) nor the server (`grep` finds no Open Vault) has the league; the register has no item for it. Rec: say in §17.8 what blocking does for Open Vault players (for example, a block removes each from the other's Open Vault targets), and give the Open Vault opt-in a §23.2 home (the League tab) and a roadmap task, or move it after launch.

---

## 7. Order of work (for the roadmap's SC stage)

These assume the sibling plans' shell (`Shell`, tab bar, `BadgePresenter`), the engine move to Godot 4.7.2 / `api-4-7`, Claude Design's tokens replacing `ui/tokens.json` and the component library (TC.7), the shared 3D `World`, and the sim event log (heist report SIM-H2).

1. **TC-S0 Decisions** (owner): SS10/F41 (currency), SS18 (presence and pings), SS1–SS3 confirmed as "build the document", SS6 (final or highest league), SS14 (gift number), SS16 (minors posting), SS21 (badges). Nothing below draws a price line, a reward table or a status pill until these are answered.
2. **TC-S1 Shared pieces**: `TabStrip`, `BottomSheet`, `ConfirmSheet`, `Toast`, `Avatar`, `ProgressBarToGo`, `ChipRow`, `Carousel`, and `ShareRules.for_band` (one table from §20.2 and §20.7 for three bands, tested). Gate: a11y layout at 150%/200% in both languages.
3. **TC-S2 Season Pass on today's server**: `season.tscn`, `TrackLane`, `RewardCard`, `RevealOverlay`, claim-through route, band-aware premium sheet with the store price. Then the League road (server: bounds, rewards, season end) and the week's era (`GET /v1/era`).
4. **TC-S3 Shop**: authored catalogue (D64), rails, item page, buy and gift sheets with the cap (SS11), then the universe preview on the World (SS12).
5. **TC-S4 Friends**: widened friends and feed routes, player reports, the friend sheet, flows into the planner (mode "friendly"), Share and Shop.
6. **TC-S5 Profile**: `/v1/profile`, per-heist facts at settle, charts with text equivalents, privacy switch by band.
7. **TC-S6 Goals and streak**: server goals (offer 6, pick 3, swap, claim, caps) and streak (saver, repair, cosmetic), then the Quests tab.
8. **TC-S7 Share**: in-game clip from the replay window, Beacon posts, challenges to friends, invite gift (server first-heist trigger), deep links; then video export for 16+ through a platform encoder plugin.
9. **Landscape** for all five (§23.3), after portrait is accepted.

Roughly: S0 owner; S1 M; S2 L; S3 L; S4 M; S5 L; S6 M (server) + S (client); S7 XL.

## 8. Questions for the owner

1. F41: no currency (as answered and built) or Starglass as the design and v3.6 §9.1/§22.1 still say?
2. Presence ("online", "seen 3 h ago") and preset pings between friends at launch: yes or no, and what does a 13–15 or 16–17 player show to friends?
3. Season and event quests and a post-track star chest: write them into §14.6/§18, or keep §14.6's three-of-six daily goals only?
4. League season-end rewards: by the final league (as the server does) or the highest reached (as the design says), and what do Dust, Ember and Tide get?
5. Badges and titles for launch: adopt the design's nine badges (paying nothing)?
6. The gift limit: three a month?
7. May a 13–15 player post a clip to the Beacon, given G35 keeps their heists out of every feed?
8. The Open Vault league (§9.4): at launch with a screen, or later; and what does blocking do there?
