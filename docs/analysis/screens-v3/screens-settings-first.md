# Settings and wellbeing, and First launch: Screens v3 against v3.6, and the Godot build

Scope: the two §23.2 screens "Settings and wellbeing" and "First launch". For each: what the design shows (read from its markup and logic and captured state by state), how it compares with §23.2's must-show row and §23.5's rows, what the build has today, and how to build it on the existing client architecture. Findings that belong in the audit register are collected in section 3, the owner's decisions in section 4, and roadmap changes in section 5.

Short names used below: **meta.js** = `scratchpad/art/named/screens_meta.js`; **markup** = `scratchpad/art/named/screens_meta.markup.html`; **doc** = `docs/design/ruleborn-game-design-v3.6.txt`. "Captures" are mine, in `scratchpad/analysis/sf_shots/` (390x844 phone frame, 152 files: every tab of Settings for an adult and for a 13–15 player, and every phase and beat of First launch), made with `sf_scripts/shoot.mjs` against the shared design server on port 8866 (`?ab=1` sets the design's own 13–15 Tweak).

## 0. What I read

- Doc: §23.1–§23.5 (11193–11712), §20.1–§20.12 (10158–10388), §16 (8833–8885), §25.2 (12141–12181), §14.6 (8327–8337), §14.2 table rows 1–6 (7738–7800), §5.2 realm opening levels and shapes (653–712), §5.5 bands (839–900), §5.6 weaving times (963–969), §7.6 starting laws (2203–2228), §7.7 Half gravity, Slow rivers, Stillness, Bloom (2265, 2761–2800, 3226–3240), §8.6 (4317), §11.3 traits (6142), §11.6 rest (6165–6186), §12.4 free scouting facts (6934–6936), §12.7 controls (7006–7030), §12.9 outcomes (7072–7111), §12.10 ruins (7113–7117), §13.1 the guided build (7488–7509), §15.2 learning map (8637–8700), §18.8 (9108–9128), §19.12 (9664–9700), §21.8 interface (10986–11016), the §24 table (11640–11712). v3.6 diffs (`scratchpad/v36/diffs.txt`): the Settings row gained "any protection the age band fixes is shown locked (20.2)"; the First launch row did not change.
- Design: markup 371–429 (Settings), 431–470 (First launch); meta.js 888–953 (Settings logic), 953–1021 (First launch logic), the state at meta.js 7 (`stg`, `flStep`, `flBand`, `flPh`, `flName`, `flAv`); `icons_rbi.js` group `settingsandwellbeing` (16 icons); the gallery captures `shots/all/Gameplay_19_Settings_and_wellbeing.*` and `Gameplay_21_First_launch.*`.
- Build: `client/scripts/settings.gd`, `settings_screen.gd`, `age_screen.gd`, `home.gd`, `data/age_check.gd`, `data/repositories/account_repository.gd`, `app/services.gd`, `app/app_state.gd`, `app/router.gd`, `app/haptics.gd`, `app/app_lifetime.gd`, `core/store.gd`, `scripts/ui.gd` (function list), `ui/tokens.json` (head), `i18n/strings.csv` (settings and age rows), `tests/age_tests.gd`, `tests/a11y_tests.gd` (settings part), `client/README.md`; `server/src/http.mjs` route list (1–90) and handlers (495–580), `notifications.mjs` (1–200, 255–330), `safety.mjs` (1–60), `privacy.mjs` (1–80), `workshop.mjs` 89–93, `db.mjs` 54–57, `facts.json` (`NIGHT_HOURS`, `SPENDING_CAPS_EUR`), `service.mjs` lease modes (372–417); `tools/roadmap.py` stage SC (938–1165); `tools/audit_register.py` items G8, G9, G29, G34, G39, C43, D68, D70, F37, F41, F43, F54 and the FRONTEND/BOTH sets; sibling reports `screens-heist-result.md` (F4), `screens-season-shop-share-friends-stats.md` (SS11), `screens-home-realm-shell.md` (shell components), `screens-weave-law-codex-harmony.md` (hold time).
- Not read: `docs/design/spec/first-build.md` beyond its first 60 lines; the creature sheets; `realm_diorama.js` internals (only that the title and the beats mount it with `mode="universe"`/`mode="realm" realm="heart"`).

---

## 1. Settings and wellbeing

### 1.1 The rows that govern it

§23.2 (doc 11279–11281): *"Settings and wellbeing | Control the experience. | Reminder time, play-time reminders, notifications, accessibility, languages; any protection the age band fixes is shown locked (20.2)"*. The last clause is new in v3.6.

§23.5 rows that touch it:
- Adopted: *"Slower ruins | An accessibility option that runs drifting ruins at 75% speed. Ruins only: never a heist against a player, never Renown (12.10, 19.12)"*.
- Differ: *"Text size | Most screens set most text below 13 pt … | 13 pt at the smallest, 16 pt body | 21.8"*; *"Locked protections | Drawn like open choices for 13–15 | Shown locked | 20.2, 23.2"*; *"Account tab | Highlights the 13–15 band for an adult | Highlights the player's band | 20.2"*; *"Colour-blind panel | Life drawn as a gem | Life is a leaf | 5.2"*; *"Landscape | Not designed"*; *"The designs' own notes"* (the gallery note "MUST SHOW (23.2)" quotes the v3.4 row, without the locked clause, and "TRY: Coming in a later turn").

The rules the screen carries: §20.2's table (chat, profile, night notifications, play-time reminder, purchases, tracking, by band), §14.6 (what notifications exist; a reminder time or none; nothing at night), §18.8 (no notification when a season ends), §25.2 (notifications asked for after the third session, with a reason), §20.5 (deletion inside the game, age bands not birthdates), §20.6 and §20.8 (the accessibility set), §20.10 and §20.11 (help section and ticket form, published contact, terms), §20.12 (a deleted player's islands may stay as an unnamed derelict or be withdrawn at their request), §21.8 (13 pt floor, 16 pt body, haptics, sound), §23.3 (orientation remembered per device).

### 1.2 What the design shows

One screen, `data-screen-label="19 Settings and wellbeing"` (markup 371–429), dark starfield background. Top to bottom:

1. **Header** (markup 373): round leather Back button (to home, `go.home`), title "Settings" (Marcellus 26), and on the right an "AGE 18+" pill (`stg.bandT`) that jumps to the Account tab (`bandGo`, meta.js 907+).
2. **Four tabs** (markup 374; meta.js `tabs`): WELLBEING (hourglass icon), GAME (speaker), ACCESS (accessibility figure), ACCOUNT (person). Active tab is a gold raised plate; inactive tabs at 62% opacity. Tab state `stgTab`, default `w`.
3. **Scrolling body** (markup 375) with four tab bodies:

**WELLBEING** (markup 376–391; captures `st_w_top`, `st_w_mid`, `minor_st_w_top`, `minor_st_w_mid`)
- A hero card: a 112 px conic **ring** showing minutes played today ("38 MIN TODAY", hard-coded `todayM: '38'`), a moving dot at the ring's end when a reminder interval is set, and beside it "Pause card in N min" / "It waits until your heist ends, then suggests a break." or, with the reminder off, "Play-time reminder is off / Turn it on below for a gentle pause card." (meta.js 911–918).
- Inside the card, **THIS WEEK** "4 h this week": seven bars M–S (`WK` meta.js 900: 52, 31, 44, 18, 36, 21, 38 min; today gold), and when a reminder interval is set a dashed line across the bars labelled with the interval ("60 MIN") at that height (`limLine`).
- **Reminders** card (markup 381): three rows, each with icon, name, description and a segmented control:
  - *Play-time reminder* "A pause card after long play." Off / 45 min / 60 min / 90 min (`PT_O`, meta.js 897). Default by band: 13–15 60 (locked), 16–17 90, 18+ Off (`ptDef`, `ptLock = band === 0`).
  - *Quiet hours* "No notifications 22:00 – 08:00." On / Off, with a 24-hour gradient strip whose night segments are hatched (`q1`, `q2`). Night start 21:00 for 13–15, 22:00 otherwise; locked On for both minor bands (`qhOn = minor ? true : …`, meta.js 898).
  - *Daily reminder* "One nudge a day if something is ready. Never at night." 12:00 / 18:30 / 20:00 / Off, **default 18:30** (`rtOpts`, meta.js 923; capture `st_w_mid`).
  - A locked row carries a small chip "AGE 13–15" with a lock glyph (8.5 px) beside its name; the locked segmented control keeps the chosen segment gold and dims the others to 35%; tapping a dimmed one says "Set by your age band (13–15)" (meta.js 892 `sgO`).
- **Last session** card (markup 383–385): "Today · 17:40 · 24 min" and three tiles: +1,420 Heist won, 1 Law found, 2 Realm built (all constants, `lastS`).
- Computed but not drawn: a "worth it / not really" pair (`worth`, meta.js 930), `capT`/`capBar` (a spending cap bar, 13–15 only), `nextPause`, `ptOpts`, `qhTog`.

**GAME** (markup 392–402; captures `st_g_top`, `st_g_bottom`)
- Four **quick tiles** (96 px tall): Music, Effects, Haptics, Quiet, each ON/OFF with a green pill; Quiet is locked for minors (tap says "Set by your age band") but drawn the same as an open tile (`quick`, meta.js 932).
- **Volume**: three sliders Music 70%, Effects 85%, Alerts 90%, 5% steps, pointer down or drag sets the value (`vlO`, meta.js 905).
- **Notifications**: five switches, "You were raided · With the replay" (on), "Buildings ready" (on), "Crew rested" (on), "Weaving done" (off), "Season rewards" (on) (`notes`, meta.js 937), and a footnote "Quiet hours always win: nothing arrives 22:00 – 08:00." (21:00 for 13–15).
- **Language**: English / Português (BR) and "More languages arrive one per season."

**ACCESS** (markup 403–413; captures `st_a_top`, `st_a_mid`, `st_a_bottom`, `st_a_text200`, `st_a_deutan`)
- **Text size**: A− and A+ buttons, 100 / 125 / 150 / 200% with four dots, and a live parchment law card "Stillness — Anyone standing still for 1.5 seconds becomes invisible to guards." with the pause icon (markup 406).
- **Colour-blind mode**: Off / Deutan / Protan / Tritan, with the six school chips recoloured per palette (`CBP`, meta.js 903) and shaped by `SCH` (meta.js 902): Time hourglass, Motion chevron, Matter **hexagon**, Energy bolt, Life **gem**, Spirit **plain oval**. "Each school keeps its own shape in every mode."
- **Seeing and comfort**: High contrast (off), Reduced motion (off), Screen shake "On catches and pylon breaks" (on), Captions "For every spoken line" (on).
- **Controls and pace**: Left-handed controls "Mirror the heist buttons", Slower ruins "Ruins run at 75% speed", Banners stay "Until you dismiss them".
- Footnote: "Works with VoiceOver and TalkBack. No flashing above three a second. Nothing is told by sound alone."

**ACCOUNT** (markup 414–426; captures `st_c_top`, `st_c_mid`, `st_c_bottom`, `st_c_preview1315`, `minor_st_c_*`)
- **Keeper card**: portrait (archivist art), "Wren", "Keeper ID 7KQ2-19", "Signed in with Game Center", COPY.
- **Profile and stats** row: "Tide II · 1,460 · 128 heists won ›" (to the Profile screen).
- **Protections for your age**: a segmented control 13–15 / 16–17 / 18+ and five rows, Chat, Profile, Night alerts, Play reminder, Purchases (`PROT`, meta.js 906), text per band, and "Set from your device's age check. Preview other bands here."
- **Family approval** (13–15 only): "A parent approves purchases and gets a monthly summary." MANAGE ("Family approval opens on the parent's device", meta.js 948).
- **Safety and data**: Blocked players (2) ›, Report history ›, Download my data › (each only shows a toast).
- Green note "No ads and no tracking. Analytics never carry your name."
- **DELETE ACCOUNT AND DATA** (danger outline): "You will be asked twice. Your islands stay as unnamed ruins." (meta.js 951).
- Footer "Ruleborn 0.9 · Privacy policy · Terms".

Motion: tab and toggle changes animate 150–200 ms (`transition: background .15s`, knob `left .2s cubic-bezier(.3,1.4,.5,1)`), the text-size card resizes over .2 s, sounds `sfx('tap')`. No reduced-motion branch exists in the settings code.

How the band works in the prototype (meta.js 889): `band = S2.band ?? (props.ageBand === '13–15' ? 0 : 2)`. The Account tab's preview control writes `S2.band` (`bandOpts`, meta.js 946), so a preview **is** a change of band for the whole screen: the header pill, every lock and every default follow it. The control's highlighted segment reads `S2.band ?? 0`, so an adult who has never touched it sees 13–15 highlighted (§23.5's "Account tab" row). I checked the consequence directly: as a 13–15 player, Account → tap "18+" → Wellbeing → the header reads "AGE 18+", the play-time reminder and quiet hours are unlocked, and both can be switched Off (`minor_un_w_after18_offs.png`).

Font sizes measured on the rendered page (text runs by computed size): Wellbeing 39 of 51 runs below 13 px, Game 22 of 34, Access 26 of 42, Account 28 of 40. Sizes in use run from 8.5 to 34 px. This is §23.5's "Text size" row.

### 1.3 Compared with the document

**Must-show coverage (§23.2):**

| Must show | In the design | Verdict |
|---|---|---|
| Reminder time | Daily reminder with three fixed times or Off | Present; defaults to 18:30 where §14.6 has the player choose (deviation D-S5) |
| Play-time reminders | Off/45/60/90 by band, ring, week chart | Present; 13–15 locked correctly |
| Notifications | Five kinds, quiet hours, footnote | Present but the list differs from §14.6: no "experiment finished", adds "Season rewards" (D-S4); no state for the phone's notification permission (§25.2) |
| Accessibility | Text size to 200%, colour-blind, high contrast, reduced motion, screen shake, captions, left-handed, slower ruins, banners stay | Mostly; **missing hold times adjustable** and **controls that can be moved** (§20.8 Moving: "controls can be mirrored for left-handed play and moved; hold times adjustable"); haptics only on/off where §20.8 says "adjustable or off" |
| Languages | English, Português (BR) | Present |
| Any protection the age band fixes, shown locked (§20.2) | Lock chips on two Wellbeing rows; a read-only table on Account | Partly: the locked rows are still segmented controls (§23.5 lists this); the Quiet quick tile is drawn open; the Purchases protection row has no cap (D-S3); a 13–15 player can unlock everything through the preview (D-S1) |

**Deviations not in §23.5** (detail and evidence in section 3):
- D-S1 The band preview changes the player's band and unlocks a minor's protections.
- D-S2 The purchases row omits the €25 and €50 caps and the adult monthly summary (§20.2); the 13–15 family approval text promises a parent a monthly summary the document gives only to adults.
- D-S3 (same root as D-S2) the table is the one place Settings shows protections, and it is wrong for two of three bands.
- D-S4 Notifications: "Season rewards" is not in §14.6's list and the server deliberately has none (`server/src/notifications.mjs:10-12`); "an experiment finished" (§14.6) is missing; "Buildings ready" is §14.6's "storage full".
- D-S5 Daily reminder on at 18:30 by default; §14.6 "Players choose a daily reminder time, or none"; the server defaults to none (`server/src/db.mjs:55`).
- D-S6 The text-size preview drops "and wards" from Stillness's tier I text (§7.7: "Anyone standing still for 1.5 seconds becomes invisible to guards and wards.").
- D-S7 The colour-blind panel draws Matter as a hexagon and Spirit as a plain oval (§5.2: cube, eye); §23.5 lists only the Life gem here.
- D-S8 Delete: "Your islands stay as unnamed ruins." without the withdrawal §20.12 offers ("or be withdrawn entirely at the player's request") and F43's answer.
- D-S9 A "60 MIN" line drawn across a chart of daily totals reads as a daily limit; §20.2's reminder is an interval, and the document has no daily limit.
- D-S10 No help section, ticket form or contact (§20.10, §20.11), no licences page; no profile visibility control for 16–17 ("Private by default") and 18+ ("Player's choice"), which the Profile screen's sibling plan already assumes lives in Settings.

**Silent adoptions** (the document is silent and no rule breaks):
- Four tabs, the gold active plate, the header band pill.
- The play-time ring and the week bars (with the limit line relabelled, D-S9); "It waits until your heist ends, then suggests a break."
- The Last session card as the §20.3 short summary's home in Settings.
- Quick tiles for Music, Effects, Haptics, Quiet.
- A switchable colour-blind palette (§20.8 asks only that palettes be tested; a switch breaks nothing so long as each school keeps its §5.2 shape).
- "Quiet hours always win" footnote; "More languages arrive one per season" (§20.6).
- Keeper card with Keeper ID and COPY; Blocked players list (§17.8 blocking exists); Report history; Download my data (needs server routes, §1.5); the privacy note.
- Fixed reminder times as presets (§14.6 says the player chooses a time; presets plus "Other…" would satisfy it better).

### 1.4 What the build has today

Client:
- `client/scripts/settings.gd:1-173`: a static `Settings` class saved to `user://settings.cfg`: locale, three volumes in tenths (`DEFAULT_VOLUME` music 7, effects 8, alerts 10), reduced motion and high contrast starting from the phone's own accessibility settings (`phone_says`, 81), haptics, text scale (steps from `ui/tokens.json` `text_scale`), left-handed, `slow_rehearsals` (75%, applied to the builder's own-island playtest, not to ruins), `banners_stay`. `apply()` sets the locale, swaps the palette for high contrast and drives three audio buses so an alarm is never silenced with the music (147–165). The header (9–11) says hold times and screen shake are not offered because nothing is held or shakes yet.
- `client/scripts/settings_screen.gd:1-114`: one scrolling list built from `scripts/ui.gd`: a language button that cycles (111), − and + steppers per volume (52–63) and for text size (65–73), six toggles as labelled buttons (75–82), Home. Rebuilt after every change, keeping scroll and focus (24–38).
- Route `&"settings"` (`client/app/router.gd:36`), reached from Home's list (`client/scripts/home.gd:9`).
- Not there: anything from the Wellbeing tab (play time, play-time reminder, quiet hours, daily reminder), notifications, the Account tab (protections, blocked list, deletion, terms, privacy), the band anywhere on the screen. `AccountRepository.delete_account(withdraw_islands)` exists (`client/data/repositories/account_repository.gd:26`) but no screen calls it (D70's "the deletion button … not built"). The blocked list is read by the social controller (`client/features/social/social_controller.gd:101`). Settings is not in the store: no slice, presenter or controller.

Server (`server/src/http.mjs` route list 1–90):
- `PUT /v1/notifications {timeZone, reminder, nightQuiet, pushToken}` (12, handler 502), implemented in `notifications.mjs:124-177`: refuses `bad_time_zone`, `bad_reminder_time`, `the_night_is_always_quiet_under_18`, `reminder_at_night`; clears a stored reminder the night now covers (`reminderCleared`). Nights from `facts.json` `NIGHT_HOURS`. Raids are gathered into one message a day (G34).
- `GET/PUT /v1/terms`, `GET/POST/DELETE /v1/blocks`, `/terms`, `/privacy`, `/support` (17–22), `PUT /v1/age` (28; under-13 deletes, 528–537), `DELETE /v1/account {withdrawIslands}` (30, 567–572), `GET /v1/shop/summary` (§20.2's monthly summary), `POST /v1/events` (the `worth` rating is an integer 1–5, `telemetry.mjs:70`).
- Not there: `GET /v1/notifications` (only PUT returns the settings), a per-kind opt-out (the server always queues "raided"), a Keeper name and face, a data export, a player's own report history, any record of play time (device-local is enough).

### 1.5 Plan: Settings in Godot on the existing architecture

**Principle.** The band is the platform's and the server's, never a setting. Every protection is read from one data module, drawn locked when fixed and as a control only when the band allows a choice. Nothing on this screen may change what a crew, guard or player can do (§23.5); every row maps to a §20 or §14.6 sentence or to a silent adoption listed above.

**Data and state**
1. `content/protections.json`, generated by a tool from `tools/design_facts.py` (one home, §31.2): per band and per §20.2 row, its value, whether it is fixed or a default, and the words. Night hours and caps already live in `server/src/facts.json` (`NIGHT_HOURS`, `SPENDING_CAPS_EUR`); generate both the server's facts and this file from the same place so the two sides cannot drift.
2. `features/settings/settings_state.gd`: a store slice `SETTINGS` mirroring `Settings` (so presenters read the store, not a static), plus `notifications` (server copy: reminder, nightQuiet, timeZone, raided opt-out), `permission` (the phone's notification permission: unknown, denied, granted), `playtime` (today's minutes, the last seven days), `band` (from `AgeCheck`), `confirming` (a server change in flight). Reducers: `setting_changed`, `notifications_loaded`, `notifications_refused`, `permission_changed`, `playtime_ticked`. `Settings` stays the file and `apply()` service; the controller writes through it and dispatches.
3. `features/settings/settings_presenter.gd` (pure, tested headless): one view model per tab. It decides locks from `protections.json` and the band: 13–15 play reminder "Every 60 minutes" and quiet hours 21:00–08:00 as locked rows; 16–17 quiet hours 22:00–08:00 locked, play reminder default 90 and changeable (whether to Off is decision O-7); 18+ both changeable. It words the Purchases row with the cap and the month's spending from `GET /v1/shop/summary` ("€6 of €25 this month", "€6 of €50 this month", "This month: €6"). It hides rows whose feature does not exist yet (Captions until a spoken line exists, Screen shake until something shakes) rather than showing switches that do nothing.
4. `features/settings/settings_controller.gd`: applies a change, saves, and for server-held fields calls a new `data/repositories/notifications_repository.gd` (`PUT /v1/notifications`; `GET /v1/notifications` once the server has it). Optimistic update with rollback and the server's refusal in words (`reminder_at_night` → "That time is inside your night", existing `core/errors.gd` path). Sends the device's IANA zone on every launch (G34's answer).
5. `app/playtime.gd` (service): counts foreground minutes per local day (hook `NOTIFICATION_APPLICATION_FOCUS_IN/OUT` and `NOTIFICATION_APPLICATION_PAUSED/RESUMED` in a node beside `AppLifetime`), keeps seven days in `user://playtime.cfg`, and raises the pause card at the interval: never mid-heist (the heist controller asks before showing it), shown when the result screen closes. Whether the interval counts continuous play or the day's total is decision O-7; the design counts the day's total.
6. `app/local_notifications.gd` (service with a fake): schedules the device's own timers (storage full, a character rested, an experiment finished, weaving done) inside the night rules, and asks the phone's permission only when §25.2 allows (after the third session with a reason on screen) or when the player switches a notification on in Settings (decision O-8). Godot has no built-in local-notification API on phones; this needs a small Android plugin and an iOS plugin, which are device work (TC.8). Until then the service is a fake and the rows show "Needs the phone's permission".

**Components** (in `scripts/ui.gd`'s successor, built from Claude Design's tokens, each with an accessible name, 48 pt targets, 200% text and high contrast, as TC.4 requires):
- From the shell plan: `BackHeader` (with the band pill, read-only: it opens the Account tab), `HubTabs` (the four tabs).
- New: `SettingRow` (icon, name, one-line description, trailing control); `Toggle` (switch that also reads "on"/"off" in words); `Segmented` (2–4 options); `LockedValue` (lock glyph + the value in words + "Set for ages 13 to 15", not a control, read by a screen reader as one sentence; this is §23.5's "Shown locked"); `VolumeSlider` (Godot `HSlider` styled to the gold track; a tap sets the value, so no drag is needed, §20.8; ui_left/right steps for switch access); `Stepper` (text size A−/A+ with the live `LawCard` preview from the Codex plan, text from `i18n/content.csv`); `QuickTile`; `PlayRing` (a `Control` with `_draw()` arcs, no animation under reduced motion) and `WeekBars` (seven bars, each with its minutes in its accessible name; the interval drawn as a marker on today's bar, not a line across all days); `ProtectionsTable`; `KeeperCard`; `LinkRow`; `DangerButton`; `ConfirmSheet` (from the result and shop plans) for deletion; a `BottomSheet` "Protections by age" for the preview.

**The four tabs, as built**
- Wellbeing: `PlayRing` + `WeekBars` + Reminders card (`LockedValue` or `Segmented` per band) + Daily reminder (`Segmented`: Off by default, three presets and "Other…" with a time picker that refuses times in the night) + Last session (from the session summary reducer the first-launch done screen also uses).
- Game: quick tiles; three `VolumeSlider`s (keep the three buses; move from tenths to twentieths only if the design's 5% steps are wanted); Notifications: You were raided (server-held: needs the opt-out field), Storage full, Crew rested, Experiment finished, Weaving done (§5.6 makes weaving a timed action, so it is something to act on), no Season rewards; a permission line when the phone has not granted it, with "Open phone settings"; quiet-hours footnote; Language `Segmented` (existing `next_language` logic, `Strings.LOCALES`).
- Access: Text size; Colour-blind palette (if adopted, O-9) with §5.2's shapes (cube, leaf, eye), the client's `ui/colour_check.gd` re-run on each palette; High contrast; Reduced motion; Screen shake (when something shakes); Captions (when a spoken line exists); Left-handed; **Hold time** (Short / Normal / Long, feeds `UI.hold_button` from the weave plan and the heist's "Get out" hold, §12.7); **Move controls** (§20.8 "moved": a layout editor for the heist HUD, later, device-tested); Slower ruins (rename `slow_rehearsals` → `slow_ruins` and apply it to ruins only, as §23.5 adopted); Banners stay.
- Account: `KeeperCard` (name, face, Keeper ID, "Signed in with Game Center" or "Google Play Games" from the platform), Profile and stats (route `&"profile"`), Profile visibility (locked Private for 13–15; toggle for 16–17, off by default; toggle for 18+, default per O-10), `ProtectionsTable` for the player's band with "Compare age bands" opening the read-only sheet, Family approval as a line of text only where the platform reports it (no MANAGE: the app cannot open the parent's device), Safety and data (Blocked players from `GET /v1/blocks`; Report history and Download my data once the server has them), Help and support (`/support`, the in-game help section of §20.10), Privacy policy, Terms, Licences (Godot's MIT notice and the fonts' OFL), the privacy note, Delete account (`ConfirmSheet` twice; second step offers "Withdraw my islands too" per §20.12 and F43; then `AccountRepository.delete_account`, local files cleared, back to first launch).

**Server needs**
- `GET /v1/notifications` (the screen on a new device), and a `raided` opt-out field in `PUT /v1/notifications`.
- Keeper profile: name and face on the account, with §20.4's word filter (the server has no free-text filter today; the Workshop names from word lists).
- Profile visibility per §20.2 (stored, enforced where profiles are read).
- `GET /v1/reports/mine` (Report history) and a data export (`GET /v1/account/export`) if those two adoptions stay.
- `PUT /v1/age` should stop accepting a less protective band from the device once the platform signal exists (decision O-4).

**Tests** (`client/tests/settings_tests.gd`, through `client/status.py`): presenter per band (what is locked, the cap wording, no Season rewards row); the preview never changes `AgeCheck.band()` or any lock; controller against `FakeTransport` for each refusal code and rollback; `playtime` across midnight and a suspended app; the a11y suite at 150% and 200% in both languages on every tab; the 13 pt floor; the contract check picks up the new routes.

**Order**: protections data → state, presenter, controller → Account tab (deletion closes D70) → Wellbeing → Game → Access → local notifications and permission (device) → move-controls editor (device).

**Effort: L.** Depends on the shell components, the Profile screen route, the Codex `LawCard`, the server routes above, and the platform plugins for notifications (device).

---

## 2. First launch

### 2.1 The rows that govern it

§23.2 (doc 11283–11285): *"First launch | Age check and the first session. | Age band check, then the moments in section 16"*.

§23.5:
- Adopted: *"The first-launch order | Title, the age-band check, a summary of the protections that band sets, the Keeper's name and face, then the first-session beats (16, 20.1)"*.
- Differ: *"First session | The Star Well yields Essence; stability 96% after one law; the Heart already built at 0:00 | Star Wells make Starlight; one 12-point law in a 38-point Spire is 32%, Quiet; the session starts from a bare Heart | 10.2, 5.5, 16"*; the Text size, Landscape and designs' notes rows.
- And (doc 11418) *"The heist screen, the planner, the result, the Observatory, Weaving, the defence log and the first launch already follow this document; these are the differences that remain."* Section 2.3 shows this is not true of the first launch.

The rules it carries: §20.1 (ask the platform for a band, four bands, no birthdate; under 13 told the game is for 13 and up and no account), §20.11 ("A neutral age gate, no accounts below 13"; "Penalties are per-violation and large, so the gate is not decorative"), §20.2 (what the band sets), §20.5 ("consent follows the player's country"), §16 (the beats), §15.2 (when each idea is taught), §25.2 (playing within 30 seconds, no account creation or permission prompts before the first heist, every first session ends with a robbed vault and a woven law, median time to the first heist under 45 s, the funnel), §5.2 and §14.2 (outer realm 1 at Keeper 3), §5.5 (stability), §5.6 (weaving times), §7.6/§7.7 (the three starting laws), §11.2/§11.3 (roles and traits), §12.9 (outcomes), §13.1 (a 60-second guided build before the first player heist), §20.3 (session summary and "worth your time"), §19.5/§25.1 (worth out of 5).

### 2.2 What the design shows

`data-screen-label="20 First launch"` (markup 431–470), six phases in `flPh` (meta.js 963–1021): `title` → `age` → (`block` | `setup`) → `name` → `play` (eight beats) → `done`.

1. **Title** (markup 433–436; `fl_00_title.png`): the 3D universe diorama (`realm-diorama mode="universe" realm="heart"`, fully built: six realms, bridges), a dark top and bottom gradient, the logo "RULEBORN" (Lilita One 60 with a sheen sweep), "Your islands. Your rules. Their treasure." (Marcellus), floating motes, three hero cut-outs at the bottom (Emberling, Featherkin, Tidewalker, popping in), "TAP TO BEGIN", a "13+" badge and "English · Português (BR)". The whole screen is the tap target.
2. **Age** (markup 437–439; `fl_01_age.png`): a glow over the dark, "Before the first page falls", "Your age range sets chat, sharing and spending. We never ask for a birth date." and a white bottom sheet styled like an iOS system sheet: app icon "R", "Share your age range?", "A range, never your birth date.", four radio rows Under 13 / 13 to 15 / 16 or 17 / 18 or older with **13 to 15 pre-selected** (`flBand: 1`, meta.js 7 and 963), a blue "Share" button, "Shared by your device. You can change it later with a parent."
3. **Block** (under 13; markup 450–452; `fl_02_block.png`): "Ruleborn is for 13 and up", "No account was made and nothing was saved. The pages will still be here when you're older.", and a button **CHANGE AGE RANGE** back to the age sheet.
4. **Setup** (markup 440–444; `fl_03/04/05`): "AGES 13 – 15", "Set up for you", a sub-line by band (13–15 "A parent can change these in Settings."; 16–17 "You can loosen chat yourself; the rest stays on."; 18+ "All of these can be changed in Settings.", meta.js 978), a parchment table of six rows (Chat, Profile, Night alerts, Play reminder, Purchases, Tracking, `FPROT` meta.js 954), "FOR EVERYONE": No paid randomness, No ads no tracking, Nothing decays while away (meta.js 1015), BACK and START.
5. **Name** (markup 445–449; `fl_06_name.png`): "YOUR KEEPER", "Who keeps this universe?", "Pick a face and a name. Both can change later."; three round faces (Featherkin, Emberling, Tidewalker; the chosen one larger with a gold ring); NAME field (14 characters, letters, digits and spaces, meta.js 973) with a dice button for a random name from ten; a hint ("Names are checked by a filter in every language." plus "Your profile stays private." for 13–15); "HOW RAIDERS SEE YOU": the name, "Keeper level 1 · 1 realm · Unranked", a SHIELDED pill; BACK and BEGIN.
6. **Play** (markup 453–460; `fl_play_0_a` … `fl_play_7_b`): the Heart in 3D (`mode="realm" realm="heart"`, already built), a top bar with the beat's time label ("0:00" … "10:00"), eight progress dots and SKIP; the beat title; a HUD of three counters (Laws, Ruleborn, Resonances) that pop "+1" when they rise; a large round tap target in the middle with the beat's icon, an orbit of three dots, a pulsing ring and a "TAP" hand; after the tap a radial flash, burst, rays and a parchment **reveal card** (tag, icon or the three heroes, name, sub-line; three stars on the heist; "KEEPER LEVEL 2/3" chips); the Archivist portrait and speech panel with a ✓ "what it teaches" line once acted; a big main button (the action's verb, then CONTINUE, then SEE YOUR HAUL). Beats 3 and 7 run a 1.7 s progress bar ("Escaping…", "Studying…"). Beat 5 shows a stability bar.
7. **Done** (markup 461–468; `fl_done_top.png`): confetti, "FIRST SESSION · 10 MIN", "Welcome home", five crew faces (the three plus Bloomling and Rambler), a Keeper level 3 badge with "Level 4 opens your first outer realm" and a bar, haul tiles 3 Laws / 5 Ruleborn / 1 Resonance, "Today's goals · resets 08:00" (Win two heists 1/2, Collect from the Star Well 1/3, Weave a law 0/1), "The Archivist guides you · then the hints fade" (Session 1 DONE "Laws, a heist, your first resonance"; Session 2 NEXT "Choose your first outer realm and its Nursery"; Session 3 "Raid another Keeper for the first time"), Star Well "Full in 3 h", Shield "Safe for 72 h. Raiding a player ends it.", "Was this worth your time? Yes / Not really", TO MY UNIVERSE.

The eight beats (`MOM` meta.js 955–962, reveals `RV` meta.js 964) against §16:

| §16 | Design beat (action → reveal) | Same? |
|---|---|---|
| 0:00 A shattered universe drifts in the dark. The Archivist catches a falling glowing page: Half gravity. Teaches: laws are things you find | "A falling page": "Catch the page" → NEW LAW Half gravity, "Common · Motion school" | Yes, but the player catches it, not the Archivist; the scene is a built Heart, not a shattered universe (listed) |
| 0:30 The player places it in their Heart. Stones lift, and a character leaps over a hedge. **The page shows the law's one note, Flow.** | "Place it in the Heart" → WOVEN INTO THE HEART, "Stones float · stability 96%" | No note shown anywhere; stability inverted (listed: 32%, Quiet) |
| 1:15 Three ruleborn wake: Featherkin, Emberling, Tidewalker. **Each shows its ability once.** | "Wake the three" → "3 RULEBORN JOINED · Your first crew · **Scout · Breaker · Swimmer**" | Abilities not shown; Swimmer is a trait (§11.3), a Tidewalker is a Carrier (§11.2) |
| 2:00 First heist into a Drifting ruin running Slow rivers; Tidewalker crosses, Emberling breaks the pylon, the Vault opens, escape with seconds left | "Launch the heist" → 1.7 s bar → HEIST WON "Slow rivers studied · Out with 0:04 to spare", **three stars**, **KEEPER LEVEL 2** | No heist is played; stars instead of §12.9's outcome; Keeper 2 (see below) |
| 5:00 The haul unlocks Slow rivers; two strays follow the crew home to a free Hearth; to work at the Star Well **and the Garden** | "Send them to work" → WORKING AT HOME "Star Well · +120 Essence an hour while you're away" | Essence (listed: Starlight); no Garden, no Hearth; §11.6's 5-minute start not shown |
| 6:30 The Archivist hands over Bloom; woven into the Heart's second slot; shares no note with Half gravity; the stability bar for the first time; the Archivist suggests Slow rivers and Bloom in the Lab; the experiment takes 5 minutes | "Weave Bloom" → NEW LAW Bloom "Common · Life school"; stability 96% → 82%, "See the bar? Every law costs stability. Keep it green." | Stability inverted (listed); "Keep it green" teaches the opposite of §5.5's bands; the Lab suggestion moves to 7:00 |
| 7:00 Two more ruins appear. The player chooses one **and runs it alone** | "Pick a ruin" → TARGET CHOSEN "The Lantern ruin · Guards asleep · 2 laws inside" | The ruin is chosen and never run |
| 10:00 The experiment finishes and names Mangrove banks, the first signature resonance, **with insight pages**, and three daily goals appear. The session ends with **the characters tired** and **the next realm two levels away** | "Name it" → RESONANCE FOUND "Mangrove banks · Slow rivers + Bloom · 1 of 12", **KEEPER LEVEL 3**; done: "Keeper level 3 · Level 4 opens your first outer realm" | No insight pages, no tired crew, and the realm is one level away at the wrong level (§5.2 and §14.2: outer realm 1 opens at Keeper 3) |

Font sizes: title 2 of 6 runs below 13 px, age 2 of 11, setup 19 of 22, name 10 of 14, play 7 of 13, done 31 of 40 (§23.5's Text size row).

### 2.3 Compared with the document

**Must-show coverage (§23.2: "Age band check, then the moments in section 16"):**

| Must show | Design | Verdict |
|---|---|---|
| Age band check | A four-band sheet, a protections summary, an under-13 stop | Present, but not neutral: 13–15 pre-selected and "CHANGE AGE RANGE" on the stop (D-F1); styled as an OS sheet |
| §16 0:00 | Present | Yes |
| §16 0:30 | No note Flow | **Missing** the note |
| §16 1:15 | No abilities shown | **Missing** "each shows its ability once" |
| §16 2:00 | A progress bar, no heist | The heist is the build's to play; the design is a storyboard |
| §16 5:00 | Star Well only | **Missing** the Garden and the free Hearth |
| §16 6:30 | Present, wrong numbers | Listed (stability) |
| §16 7:00 | Chosen, not run | **Missing** "runs it alone" |
| §16 10:00 | No insight pages, no tired crew, wrong Keeper levels | **Missing** two items; deviation D-F5 |

**Deviations not in §23.5** (detail in section 3): D-F1 non-neutral age gate; D-F2 "A parent can change these in Settings" for 13–15 and the 16–17/18+ sub-lines; D-F3 the Purchases row without caps (as Settings, D-S2); D-F4 SKIP ends the session with the full haul; D-F5 Keeper levels and the outer realm; D-F6 the note Flow and the other §16 items above; D-F7 "Swimmer" as a role; D-F8 three stars for an outcome; D-F9 "Was this worth your time? Yes / Not really" (two points against an average out of 5; same as the result screen's F4 in `screens-heist-result.md`); D-F10 the guide card omits §13.1's guided build before the first player heist (G9); D-F11 "Name it" suggests the player names the resonance (the experiment names it, §16).

**Listed in §23.5 and confirmed in the captures**: Star Well yields Essence (meta.js 964 RV[4]); stability 96% after one law and 82% after two (RV[1]; `stabV` meta.js 1009); the Heart built at 0:00 (the play phase mounts the built Heart diorama); text sizes; landscape not designed. What the build shows instead, worked from §5.5: capacity at Spire 1 is 30 + 8 = 38; Half gravity costs 12 (§7.7) so 12 / 38 = 32%, Quiet; Bloom costs 11 and shares no note, so 23 / 38 = 61%, Steady (+5% production). The line "Keep it green" goes: the bar's bands are named, and a fuller bar up to Brimming pays more (§5.5).

**Silent adoptions**: the title (3D universe, logo, tagline, heroes, 13+ and languages); the protections summary layout and the three "For everyone" promises (§20.3, §20.2); the Keeper's face from the three starting kinds and a random-name die; "How raiders see you" (matches §12.4's free facts, subject to O-11 for 13–15); the beat bar, the HUD counters, the reveal card, the Archivist panel, the per-beat "what it teaches" ✓ line (§16's third column); the done screen's haul tiles, today's goals with a reset time, the session guide "then the hints fade" (§25.2), Star Well timer, the 72-hour shield line (§16 Day 2).

**Where v3.6 contradicts itself here** (section 3, C-1 to C-3): when the first heist happens and whether minute one is guided (§15.2 vs §16 vs §25.2); "no permission prompts and no account before the first heist" (§25.2) against the platform age check (§20.1) and the adopted Keeper name step (§23.5); and the first session's weaving time (§5.6 vs §16).

### 2.4 What the build has today

Client:
- `client/scripts/age_screen.gd:1-43` and `scenes/age.tscn`: the title "Ruleborn", "How old are you?" (`AGE_QUESTION`), four buttons with **none suggested**, and under 13 the message "Ruleborn is for players aged 13 and up. No account has been made, and nothing about you has been sent." with no way back (`AGE_TOO_YOUNG`, `i18n/strings.csv:452-457`).
- `client/data/age_check.gd:1-77`: `BANDS`, the platform seam (`platform` Callable, "" today), the answer kept in `user://age.json`, an under-13 answer never replaced (88–94), `allows_account()`, `sent()`/`mark_sent()`.
- `client/app/services.gd:89-103`: no session until `age.allows_account()` (`age_check_first`), the band sent with the first sign-in (`PUT /v1/age`).
- `client/scripts/home.gd:22-25`: Home routes to `&"age"` until the check allows an account.
- Tests: `client/tests/age_tests.gd` (kept once, under 13 kept, the platform's answer taken, sent once, against the server).
- Not there: title, protections summary, Keeper name and face, any of §16's beats, the done screen, session summary, worth rating, the funnel events of §25.2. The heist screen plays a fixture realm or a leased island (README "The heist screen"), with no tutorial ruin, no Archivist and no Lab, roster, weaving screen or Observatory yet.

Server:
- `PUT /v1/age` (http.mjs:528-537): under 13 deletes the account; any other band is stored as sent (`workshop.mjs:89-93`), at any time.
- Leases have modes raid, friendly, challenge (`service.mjs:378`); no ruin mode, no tutorial islands, no starting laws or roster, no Lab, no daily goals, no Keeper name or face, no first-session-complete flag. `POST /v1/events` takes telemetry (funnel steps can be events).

### 2.5 Plan: First launch in Godot

**The decision that shapes it.** The design is a storyboard: each beat is "tap, reveal, continue". §16 and §25.2 want each lesson to be something the player does, a robbed vault and a woven law at the end, and play within 30 seconds. So the build is a director running over the real screens, not a ninth screen with its own fake heist. The design's overlay (beat bar, Archivist panel, reveal card, tap halo) becomes that director's look.

**Flow and state**
1. `features/onboarding/onboarding_state.gd`: slice `ONBOARDING` {phase: title | age | blocked | protections | keeper | beats | done, beat 0–7, acted, keeper {name, face}, completed}. Persisted to `user://onboarding.json` after every step, so a killed app resumes at the same beat; once `completed` (or the server says so for this account), never shown again on this or another device.
2. `features/onboarding/onboarding_controller.gd`: advances phases; owns the beat table (data, not code: `content/first_session.json` with each beat's §16 time, its teach line, its Archivist line key, its trigger and its completion event); listens to the store for the real events that complete a beat (`law_woven`, `heist_finished` with an outcome, `worker_assigned`, `lab_started`, `ruin_chosen`, `lab_finished`); sends §25.2's funnel steps as telemetry (`reached_first_heist`, `finished_first_heist`, `wove_first_law`, `finished_first_session`, with the elapsed seconds, so the median under 45 s and each step's share are measurable).
3. `features/onboarding/onboarding_presenter.gd`: the overlay's view model per beat (title, dots, the Archivist's line, the halo's target node path, the reveal card's content from the store, not constants).
4. Router: `&"title"`, `&"age"` (existing), `&"protections"`, `&"keeper"`, and the beats run on the existing routes (`&"universe"`/realm view, `&"heist"`, `&"result"`, weaving, roster, Lab, Observatory) with an `OnboardingOverlay` CanvasLayer added by the router while the phase is `beats`. `&"session_done"` for the done screen.

**Phases**
- Title (`scenes/title.tscn`): the shared 3D world renderer from the home/realm plan in universe mode, a slow camera drift, the logo and tagline, the three starting kinds (glTF from the creature rigs once ported; 2D cut-outs until then), "Tap to begin", 13+ and the language (tappable: switches between the two launch languages before any text-heavy screen). Loads behind the first frame so the tap is never blocked: §25.2's 30 seconds count from here. Reduced motion: no sheen, no motes, no hero pop.
- Age: ask the platform first through `AgeCheck.platform` (a `PlatformAge` service: iOS Declared Age Range, Google Play Age Signals; native plugins, device work). When the platform answers, no question is shown. Otherwise the existing neutral question restyled in the game's look (not as an OS sheet), **no answer pre-selected**. Under 13: the existing stop, with no "change age range" (the client already does this; the design's button goes). Sending the band stays as today.
- Protections (`scenes/protections.tscn`): `ProtectionsTable` from `content/protections.json` for the band (with the caps), the three promises, one honest sub-line per band (13–15 "These stay on until you are 16."; 16–17 "Chat and your profile can be opened later, with a confirmation."; 18+ "You can change these in Settings."). START.
- Keeper (`scenes/keeper_setup.tscn`): three faces, a name field (`UI.field`) with the die, the filter hint; kept on the phone until the first sign-in (no account before the first heist, §25.2), then sent (`PUT /v1/keeper/profile`, new). For 13–15, names from word lists if O-11 says so. "How raiders see you" uses the same card the Observatory shows.
- Beats, each on the real system:
  - 0:00 A bare Heart (Spire and Hearth only, §23.5) in the realm view; a page falls (particle + tap target); tap catches it; reveal card Half gravity, Common, Motion, the note **Flow** with its symbol.
  - 0:30 Place it: the weaving screen's slot, in a tutorial mode that weaves at once (O-12); the realm view shows stones lifting and a ruleborn leaping a hedge; the stability bar appears at 32%, Quiet.
  - 1:15 Wake three: Featherkin, Emberling, Tidewalker each play their ability animation once on the realm view; roles shown as §11.2's (Scout, Breaker, Carrier).
  - 2:00 First heist: the heist screen on a designed tutorial ruin (Slow rivers, one pylon, a Vault; tuned to about four in five, §16) played on the phone with a fixed seed and no network, so nothing waits for an account; the result screen shows the real outcome (Clean, Loud, Partial or Foiled) and the study of Slow rivers. Submitted to the server after sign-in like any offline heist (TC.9's outbox).
  - 5:00 Two strays at the free Hearth; the roster's one-tap assign to the Star Well and the Garden; the Star Well's Starlight shown starting after §11.6's 5 minutes.
  - 6:30 Bloom handed over; woven in the second slot (tutorial weave); the bar moves to 61%, Steady, with the band named; the Archivist suggests the Lab; the Lab starts its 5-minute experiment.
  - 7:00 Two ruins in an Observatory-lite list; the player chooses and runs it with the overlay hidden (unguided).
  - 10:00 The Lab finishes (the 5 minutes run while the player plays); Mangrove banks named by the experiment, insight pages shown; three daily goals appear.
- Done (`scenes/session_done.tscn`): the §20.3 summary from a session-summary reducer (what was really earned), the crew with their rest timers ("the characters tired"), the Keeper bar with the real level and "Keeper 3 opens your first outer realm", today's goals, the guide (Session 2: the first outer realm and its Nursery; the 60-second guided build before the first player heist, G9; Session 3: the first raid on another Keeper, with the 72-hour shield line), the worth rating on the scale O-5 decides, TO MY UNIVERSE.
- No SKIP that grants anything (O-6). A returning player whose account already completed it never sees the beats.

**Server needs**: Drifting ruins as a lease mode (§12.10: pages and Essence, no Renown) and the tutorial ruin set; the first session's grants (Half gravity, Slow rivers, Bloom at tier I; the three ruleborn and two strays; the Heart's Spire and Hearth); weaving into the Heart (a bundle change today via `PUT /v1/islands/heart`, which needs the laws owned); the Lab (start, finish, the first experiment's 5 minutes, insight pages); daily goals (pick 3 of 6 with a swap, §14.6); Keeper name and face; a first-session-complete flag; a policy for `PUT /v1/age` once platform signals exist (O-4).

**Tests**: a flow test from title to done with fakes (the router's recorder), every beat completed by its real event; resume after a kill at each beat; the funnel events; no sign-in before the first heist finishes; the age phase never pre-selects and never offers a way back from under 13; a11y at 200% in both languages for title, protections, keeper and done.

**Effort: XL.** It sits on the heist, result, weaving, roster, Lab, Observatory, realm view and 3D world, plus the server's ruins, roster, Lab and goals. The overlay, title, protections, keeper and done screens alone are M; the beats are only as ready as the screens they run on.

---

## 3. Findings for the register

Severity follows the register's words. "Listed" means in §23.5. Sibling ids: SS11 in `screens-season-shop-share-friends-stats.md`, F4 in `screens-heist-result.md`.

**SF1 (significant, deviation) The age-band preview changes the player's band, so a 13–15 player can switch off their own fixed protections.** Settings → Account → "Protections for your age … Preview other bands here" writes the band (`bandOpts`, meta.js 946) that every lock reads (`band = S2.band ?? …`, meta.js 889; `ptLock`, `qhOn`, meta.js 897–898). Captured: a 13–15 player taps 18+, the header reads "AGE 18+", and the play-time reminder and quiet hours go Off (`sf_shots/minor_un_w_after18_offs.png`). §20.2 fixes these for 13–15; §24 "Age bands from the platform". §23.5 lists the highlight and the open look, not this. Rec: the effective band comes only from `AgeCheck`/the server; comparison is a read-only sheet.

**SF2 (significant, deviation) The age check is not neutral.** The sheet pre-selects "13 to 15" (`flBand: 1`, meta.js 7, 963) and the under-13 stop offers "CHANGE AGE RANGE" back to the question (markup 452). §20.11: "A neutral age gate … Penalties are per-violation and large, so the gate is not decorative". The client already does it right (`client/scripts/age_screen.gd:3-5`, `client/data/age_check.gd:86-94`). The sheet is also drawn as an iOS system prompt ("Share your age range?", blue Share). Not listed (§23.5 says the first launch already follows the document). Rec: no pre-selection, no way back from under 13, the platform's own prompt where it exists and the game's own neutral question otherwise.

**SF3 (significant, deviation) The purchases protection is wrong in Settings and in First launch.** `PROT` (meta.js 906) and `FPROT` (meta.js 954): 13–15 "Ask to Buy · a parent approves", 16–17 and 18+ "Through the App Store". §20.2: 13–15 "Family approval where set up; €25 a month cap", 16–17 "€50 a month cap", 18+ "Monthly spending summary". §23.2's v3.6 Settings row requires protections the band fixes to be shown locked; the cap is one. The 13–15 card also promises "A parent … gets a monthly summary" (markup 420), which §20.2 gives to adults and which neither store guarantees. Same root as SS11 (the Shop). Rec: the band's cap and the month's spending in both places, from `GET /v1/shop/summary`; drop the parent summary unless built.

**SF4 (significant, deviation) The 13–15 summary says "A parent can change these in Settings."** (meta.js 978). §20.2 fixes 13–15's chat, night and play reminder, and §20.9: "16 and 17 year olds can move to filtered free chat after an explicit confirmation; 13 to 15 cannot." No parent control exists in the design or the document. The 16–17 line "the rest stays on" is also wrong for a profile that is "Private by default" and a reminder "Every 90 minutes by default". Rec: per-band lines that match §20.2.

**SF5 (significant, deviation) The first session ends at Keeper 3 with "Level 4 opens your first outer realm".** Reveals "KEEPER LEVEL 2" after the first heist and "KEEPER LEVEL 3" after the resonance (meta.js 998), done screen markup 462. §5.2: "Outer realms open at Keeper levels 3, 6, 10, 15, 21 and 28"; §14.2: level 3 unlocks "Outer realm 1 and its Nursery"; §16 10:00: "the next realm two levels away", i.e. the session ends at Keeper 1. Not in §23.5's first-session row. Rec: show the level the server computes; the line reads "Keeper 3 opens your first outer realm".

**SF6 (significant, must-show missing) Five of §16's moments are not in the design.** The note Flow at 0:30 ("The page shows the law's one note, Flow"; §8.6 "The first session teaches one note"); "Each shows its ability once" at 1:15; the Garden and the free Hearth at 5:00; "runs it alone" at 7:00; insight pages and "the characters tired" at 10:00 (MOM meta.js 955–962, RV 964). Rec: the build runs each on its real screen (section 2.5).

**SF7 (significant, deviation) SKIP ends the first session with its whole haul.** `skip` (meta.js 1014) goes to the done screen, whose haul is constant (3 laws, 5 ruleborn, 1 resonance, meta.js 1018). §25.2: "Every first session ends with the player having robbed a vault and woven a law into their own island". A skip that grants the session's rewards without play also changes what a player earns (§23.5's mechanic rule). Rec: no skip; or skip only for an account that completed it on another device.

**SF8 (significant, contradiction in v3.6) When the first heist is, and whether minute one is guided.** §15.2: "Moving the crew … | Minute 1 | A guided first heist in a ruin"; §16: "2:00 | First heist"; §25.2: "Median time to the first heist | Under 45 seconds" and "The first minute is unguided play". §23.5's adopted order adds title, age check, protections and the Keeper's name before §16's 0:00. Rec: one time and one rule; either move §16's heist to the first minute and drop the beats before it, or restate §25.2's median from the end of the age check with a figure the beats can meet.

**SF9 (minor, contradiction in v3.6) "No account creation, no permission prompts … before the first heist" (§25.2) against the age check and the Keeper name.** §20.1 asks the platform at first launch (Apple's Declared Age Range is a system prompt), and §23.5 adopts the Keeper's name before the first beat. Rec: say the age check is the one prompt before play, and the Keeper's name is kept on the phone and the account made after the first heist (the client already makes no account before the age check, `client/app/services.gd:89-91`).

**SF10 (minor, gap) The first session's weaves have no stated time.** §5.6: "10 minutes at tier I … While a slot is being woven it is empty"; §16 weaves Half gravity at 0:30 and Bloom at 6:30 and shows the stability bar at once, inside ten minutes. The design treats them as instant. Rec: say tutorial weaves are instant (or that the first one is), in §16.

**SF11 (significant, deviation) Notifications offered are not §14.6's.** The design offers "Season rewards" and lacks "an experiment finished" (meta.js 937). §14.6: "only for things the player can act on (storage full, a character rested, an experiment finished, a heist against you)"; §18.8: "no notification when a season is ending"; the server sends none for seasons on purpose (`server/src/notifications.mjs:10-12`). Rec: Storage full, Crew rested, Experiment finished, Weaving done (§5.6 makes it timed), You were raided; no Season rewards.

**SF12 (minor, deviation) The daily reminder is on at 18:30 by default.** `rtOpts` default index 1 (meta.js 923), captured in every Wellbeing shot. §14.6: "Players choose a daily reminder time, or none"; §14.10 "No win-back pressure"; §25.2 asks permission only after the third session; the server stores none until chosen (`server/src/db.mjs:55`). Rec: Off until the player picks a time.

**SF13 (minor, contradiction in v3.6) §14.6 says nothing is sent at night; §20.2 lets adults open the night.** §14.6: "nothing is sent at night (see 20.2)"; §20.2 18+: "Off 22:00 to 08:00 by default". The server and the design follow §20.2 (`notifications.mjs` header 9–11). Rec: §14.6 "nothing is sent at night unless an adult chooses otherwise (20.2)".

**SF14 (minor, gap) The play-time reminder: can 16–17 turn it off, and what does "every 60 minutes" count?** §20.2: 16–17 "Every 90 minutes by default". The design lets 16–17 choose Off, counts the day's total (38 min today → "Pause card in 22 min", meta.js 911–915) and draws the interval as a line across daily bars that reads as a daily limit (`limLine`). Rec: say whether Off is allowed at 16–17 and whether the interval is continuous play or the day's total; draw it as an interval.

**SF15 (significant, gap) Settings lacks four things §20 requires.** Hold times adjustable and controls that can be moved (§20.8 Moving; the heist has a hold, §12.7 "Hold to choose where the skiff comes"); an in-game help section and ticket form and published contact (§20.10, §20.11; the server already serves `/support`); a profile visibility control for 16–17 ("Private by default") and 18+ ("Player's choice") that the Profile and Share plans assume is in Settings. Not listed. Rec: add the rows (section 1.5).

**SF16 (minor, deviation) The deletion line drops the withdrawal.** "You will be asked twice. Your islands stay as unnamed ruins." (meta.js 951). §20.12: an island "may remain as an unnamed derelict in the ruins, or be withdrawn entirely at the player's request"; the server takes `withdrawIslands` (http.mjs:567-572, F43). Rec: offer the choice in the second confirmation.

**SF17 (minor, gap) How an age band changes is not written, and the server accepts any change.** The design: "You can change it later with a parent" (markup 439). §20.1 and §24 take the band from the platform; nothing says what happens on a birthday, a platform update or a wrong answer. `PUT /v1/age` stores any band at any time (http.mjs:528-537, `workshop.mjs:89-93`), so a modified client could loosen a minor's protections. Rec: bands change only by a new platform signal, or only toward more protection from the device.

**SF18 (minor, gap) Do raiders see a 13–15 player's Keeper name?** §12.4's free information starts with "name"; §20.2 makes a 13–15 profile private. The design shows "How raiders see you: Wren" for every band (markup 448). Rec: say whether the Keeper name is part of the private profile.

**SF19 (minor, gap) Consent by country and the terms gate have no place in the first launch.** §20.5: "consent follows the player's country" (digital consent from 13 to 16 across the EU); §20.11 (Google) "a terms-of-use gate". The server asks for terms before Workshop actions only (`safety.mjs` header). Neither has a step in the design or a sentence saying where it goes. Rec: say whether a 13–15 player below their country's consent age needs a parent's consent and where the terms are accepted.

**SF20 (minor, deviation) Two texts and two shapes in Settings' Access tab.** The text-size preview quotes Stillness as "… invisible to guards." (markup 406); §7.7 "… invisible to guards and wards." The colour-blind panel draws Matter as a hexagon and Spirit as a plain oval (`SCH`, meta.js 902); §5.2 cube and eye. §23.5 lists only the Life gem for this panel. Rec: doc text and §5.2 shapes.

**SF21 (minor, deviation) First-session labels that teach the wrong thing.** "Scout · Breaker · Swimmer" (meta.js 964 RV[2]): Swimmer is a trait (§11.3), a Tidewalker a Carrier (§11.2); three stars on the first heist (RV[3], markup 457) instead of §12.9's outcome; "Keep it green" (MOM[5]) against §5.5's bands, where a fuller bar pays more up to Brimming; "Name it" for a resonance the experiment names (§16). Rec: roles, outcome, band names, "See what it made".

**SF22 (minor, deviation) The session guide skips §13.1's guided build.** The done screen's guide goes from "Choose your first outer realm" to "Raid another Keeper" (meta.js 1017). §13.1: "Before the first heist against a player, a 60-second guided build … it is not optional." Relates to G9 (proposed). Rec: show it as session 2's step before the first raid.

Related but not new: the worth rating's two buttons (`rate`, meta.js 1020) against an average out of 5 is the result screen's F4; the text sizes, the locked-row look, the Account tab highlight, the Life gem, the Star Well's Essence, the stability numbers and the built Heart are §23.5's rows.

---

## 4. Decisions for the owner

- O-1 (SF8) The first heist: minute 1 (§15.2), 2:00 (§16) or under 45 s median (§25.2), and is minute one guided?
- O-2 (SF9) The age check as the one prompt before play; the Keeper's name kept on the phone until after the first heist?
- O-3 (SF10) Tutorial weaves instant?
- O-4 (SF17) How a band changes, and whether the server accepts a looser band from the device.
- O-5 (F4, D-F9) Worth your time: five one-tap points or two buttons with the gates rewritten (shared with the result screen).
- O-6 (SF7) No skip in the first session, or skip only for an account that completed it elsewhere?
- O-7 (SF14) 16–17 play-time reminder Off allowed? Interval of continuous play or of the day?
- O-8 (§25.2) May a player switch notifications on in Settings before the third session (the phone's permission asked then, with the reason on screen)?
- O-9 Keep the colour-blind palette switch (adoptable) or rely on the tested default palette alone (§20.8)?
- O-10 (SF15) 18+ profile visibility default.
- O-11 (SF18) Is a 13–15 Keeper name visible to raiders, and are 13–15 names free text or from word lists?
- O-12 Keep "Download my data" and "Report history" (each needs a server route)?

## 5. Roadmap and audit changes

Register (new items; FRONTEND unless noted): SF1, SF2, SF3 (BOTH; link SS11), SF4, SF5, SF6, SF7, SF8 (design), SF9 (design), SF10 (design), SF11 (BOTH), SF12 (BOTH), SF13 (design), SF14 (design), SF15 (BOTH), SF16, SF17 (BOTH; server), SF18 (design), SF19 (design), SF20, SF21, SF22 (link G9). Update D70: the deletion button is planned in Settings' Account tab; the age check exists (TC.10) and needs SF2's restyle only in look. Update D68: the client's notification service and permission timing are in the Settings plan.

Roadmap, stage SC:
- **TC.15 Settings and wellbeing (L)**: protections data generated from design facts; settings slice, presenter, controller; the four tabs; deletion; play-time service; GET /v1/notifications and the raided opt-out, Keeper profile, profile visibility on the server. Gate: §23.2's row with every §20.2 fixed protection shown locked, SF1/SF3/SF11/SF12/SF15 closed. Blocked by the shell components (home plan) and TC.7's tokens.
- **TC.16 Local notifications and the permission (M, device)**: Android and iOS plugins, the four device timers inside the night, §25.2's ask. Blocked by TC.3/TC.8.
- **TC.17 First launch shell (M)**: title, the neutral age step restyled (no pre-selection, no way back), protections summary, Keeper name and face (local, then the server), onboarding slice with resume, done screen with the session summary and worth rating, funnel events. Gate: SF2, SF3, SF4 closed; §25.2's funnel measurable.
- **TC.18 First session beats (XL)**: the director over the real screens, the tutorial ruin set and ruin leases, starting grants, the Lab's first experiment, daily goals. Blocked by the heist/result, weaving, roster, Lab, Observatory and realm view tasks and by O-1, O-3, O-6. Gate: §16's eight moments each completed by a real event, every first session ends with a robbed vault and a woven law.
- **Platform age signals (device)**: Declared Age Range and Play Age Signals behind `AgeCheck.platform`; with TC.8.
