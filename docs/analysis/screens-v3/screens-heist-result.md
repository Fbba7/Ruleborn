# Heist and Heist result: Screens v3 against v3.6, the build today, and the Godot plan

Scope: screen 02 Heist (the in-heist HUD, its controls, the alarm, the Vault, the Sage wheel, the escape) and screen 07 Heist result. Written for the owner. Every claim names where it was read. "Doc" means `docs/design/ruleborn-game-design-v3.6.txt`; "markup" is `art/named/screens_main.markup.html`; "main.js" is `art/named/screens_main.js`; "diorama" is `art/named/realm_diorama.js` (all under the scratchpad's `art/named/`).

## 0. What I read and ran

- Doc: §23.2 rows for Heist (11211–11213) and Heist result (11231–11233); §23.5 in full (11383–11635); §12.1–12.22 in full (6881–7436); §5.4 (814–840); §7.6 (2203–2228); §9.1, §9.4, §9.6 (4355–4735); §11.1, §11.2, §11.6, §11.7 (5922–6218); §15.3 (8758–8792); §16 (8840–8885); §17.6 (8925–8947); §19.5, §19.12, §19.16, §19.20 (9382–9933); §20.2, §20.3, §20.7, §20.8 (10170–10317); §21.1, §21.8, §21.12 (10390–11098); §24 engine table, §24.10, §24.12 (11637–12068); the v3.6 per-section diff (`v36/diffs.txt`).
- Design: markup heist block 781–823 and result block 824–869; main.js 41–98 (notes, crew, targets, landings, `initHeist`), 100–193 (state, `handleD`, `startHeist`, `useAbility`, `useSage`), 436–482 (heist view values), 607–660 (result view values); diorama 122–238 (the playable heist: `buildHeist`, `hAbility`, `hEscape`, `hDown`, `hCapture`, `hRegroup`, `hCast`, `hSage`, `hSend`, `hTap`, `hHold`, `hUpdate`) and 1253–1260 (pointer handling); `data_v35.js` (outcomes, fee, health).
- Screenshots: the supplied `shots/all/Gameplay_02_Heist.png/.txt` and `Gameplay_07_Heist_result.png/.txt`, plus my own captures, taken by serving the artifact locally with the Tweaks defaults rewritten (`analysis/hr_scripts/serve.mjs`, `shoot.mjs`), in `analysis/hr_shots/`: `heist_a` (start), `heist_tapground`, `heist_hold` (gait menu), `heist_ability` (lockout ring), `heist_sage` (Sage wheel), `heist_cast` (cast wheel), `heist_t40`, `heist_getout` (skiff countdown), `heistlh_*` (left-handed), and `res_{Clean,Loud,Partial,Foiled}_{top,mid,bottom}` (every outcome, with a law studied and "Not really" tapped), `res_Clean_1315_*` (13–15 band; identical to adult).
- Build: `client/scripts/heist_screen.gd`, `heist_hud.gd`, `result_screen.gd`, `realm_view.gd`, `client/features/heist/heist_controller.gd`, `client/data/repositories/heist_repository.gd`, `client/app/app_state.gd`, `router.gd`, `core/store.gd`, `client/scripts/ui.gd` (function list), `client/ui/tokens.json` (head), `client/app/haptics.gd`, `client/ext/src/lib.rs` (exported functions, `crew`, `guards`, `vault`), `client/i18n/strings.csv` (heist and result keys), `client/README.md`; `server/src/http.mjs` 1–107 (routes), `server/src/service.mjs` 700–800 (what a heist settles), `server/src/telemetry.mjs` 40–90; `sim/src/replay.rs` 40–160, `sim/src/lib.rs` (crew constant 353, `alarm_raised` 702, realm alarm 2141, outcome 3131, Alerted 3181); `tools/audit_register.py` (all 222 titles, plus D64, D71, C41, C42, G29 bodies), `tools/roadmap.py` (stage SC, T3.3, T3.4).
- Not read: the character sheets' own pages (another part), the other 26 screens' blocks except where a heist or result element is defined in them.

---

## 1. Heist (screen 02)

### 1.1 The §23.2 row

> | Heist | Play it. | At most eight controls (12.7), clock, alarm meter, vision cones, loot, Vault progress  (doc 11211–11213)

Related rules the row points at or that govern the HUD: §12.6 "Always on screen: the clock, the realm's alarm meter, the vision cones and awareness of guards the crew can see, carried loot with both what the bags can still take and what is left to load (12.19), each crew member's ability uses left, and the Vault's progress" (6998); §12.7 controls (7006–7030); §12.18 move orders (7352); §21.8 Heist layout and Ability uses (11000–11005); §21.12 one cone at a time (11082–11098); §21.1 heist camera "a closer follow camera at 50° pitch showing about 12 tiles across" (10390+).

§23.5's rows that touch this screen: "Role health in the prototype's data module" (Breaker 260, Carrier 200, Mender 180 → 180/160/130, §11.1); "Text size" (the heist is named as one of three screens that meet the 13 pt floor); "Landscape: Not designed"; "The designs' own notes". §23.5 also says (11418): "The heist screen, the planner, the result, the Observatory, Weaving, the defence log and the first launch already follow this document; these are the differences that remain." Section 1.4 shows that, for the heist and the result, that sentence is not true.

### 1.2 What the design shows

Layout, top to bottom (markup 781–823; screenshot `heist_a.png`):

1. **The world**, full screen: `<realm-diorama mode="heist" realm="heart">` (markup 783), a three.js scene of Marta's Heart: a round island, houses, Spire with a clock-face ring, the Vault with a "VAULT" label, paths, tall grass patches, a river; the crew of five as 3D creatures with coloured rings and a pip above each; three guards (one Glass Golem model with a helmet and a lantern, in Scout, Warden and Breaker roles; diorama 142–152). Camera: perspective, about 50° pitch, about 13 tiles across (diorama 513: `el=.87`, `d=13.2/...`), following the selected crew's centroid (diorama 236). A red vignette at the screen edge grows with the alarm and flashes when the crew is spotted (main.js 453 `edge`).
2. **Top-left, "Laws here"** (markup 786–789): a label and one chip per law running in the realm (Sleepwalk, Glass) with the law's own icon and name. Not tappable (`pointer-events:none`).
3. **Top-centre** (markup 790–796): the clock in a pill ("2:43", counting down from 2:45 = 165 s, main.js 98) that turns red and pulses in its last 30 s (main.js 453 `clockBox`); under it the **alarm panel**: "Alarm 0 / 6" and six bell segments, amber for 1–3 and red #E2536B for 4–6. The level is `hAl = min(6, events + floor(elapsed / 30))` (main.js 461), i.e. one level every 30 s plus events.
4. **Top-right loot panel** (markup 797–802): "Room 1,840" (what the bags can still take), "Left 2,600" (what is left to load), a bar showing how full the bags are with a white tick at the target, and "Load to 80%". The target is fixed at 0.8 (`initHeist`, main.js 98).
5. **Centre banners** at y 214 (markup 803–806), one at a time: the 2.6-second intro card "Marta's Heart · Reach the Vault · skiff out in 20 s"; while at the Vault "Cracking · heard within 5 m" with a bar that cycles every 5 s; after Get out "Skiff in N s · hold the edge"; when a guard reaches Alerted a red "! HEARD YOU · Alarm +1 · they are looking" (or "WARD TRIPPED").
6. **Wheels** (markup 807–808), opening above the bottom-right column: the Sage wheel with three cards "Recall 1 left / Reveal 2 left / Suspend 1 left" (`heist_sage.png`), and the cast wheel "Half gravity 1 left / Stillness 1 left" (`heist_cast.png`). A card with no uses, or any card during the Sage's cooldown, is greyed.
7. **Bottom-left crew row** (markup 809–815): five 56 px round portraits (Pip, Mo, Bramble, Hollow, Ash) each with two diamond pips for uses (hollow when spent), a 52×7 health bar and the name. During the 10 s lockout a ring sweeps round the portrait with the seconds in the middle (`heist_ability.png`); down shows a red disc with the seconds to capture; captured shows "OUT" and greys the portrait. Tapping a ready portrait fires the ability (main.js 191).
8. **Bottom-right column** (markup 816–820): the Sage portrait (60 px, the Archivist) with a 20-second cooldown dial and seconds; "Cast" (64×58); "Get out" (red, 64×58), which becomes "Regroup" (cyan) while the crew is split (more than 4.5 m apart, diorama 238) and "Skiff N s" (grey) once called.
9. **Hint line** at the bottom (markup 821): a contextual sentence, always on (`hintOn:true`, main.js 464): "Tap crew, then ground · hold ground to sneak or run", "Tap a portrait to use its ability · two uses each", "Stand next to a downed crew member for 3 s to revive it", "Pip loads while the Vault cracks · guards within 5 m hear it", "Hold the edge until the skiff lands".

Left-handed (Tweak `leftHanded`): the crew row and the right column swap sides and the portrait order reverses (main.js 466–472; `heistlh_a.png`). The top HUD does not move.

Interactions, as built in the diorama (122–238, 1253–1260):

- Tap a crew member in the world: select it alone, or toggle it in a multi-selection (185–188). Tap the ground: send the selection, at the last gait (184). Hold the ground 420 ms (1253): a "Crouch / Walk / Run" menu at the finger (`heist_hold.png`); the choice sends at that gait. The first hold also zooms out (193). Pinch: zoom between close and whole realm (1256).
- Tap a guard: the nearest selected crew member walks crouched to the guard's back and, if the guard is still Unaware on arrival, knocks it out ("SILENT TAKEDOWN"), otherwise "TOO LATE" (185–188, 202).
- Route preview: a dotted path to the destination, red where it crosses a guard's cone (235).
- Guards: three-zone cones with sharp tiers (opacities .42/.28/.16), corner-of-eye halving, crouch halving, running ×1.75, tall grass invisibility when still, a fill bar travelling from the guard towards the crew member it is noticing; only the most threatening guard's full cone is drawn, the others show a small facing wedge (233). Speech: "Hm?", "Who's there?", "Intruder!", "Must be the wind.", "Got one!", "Zzz…" (218–222). Cones and turn rates match §12.17's table (diorama 142).
- Vault: when crew member 0 (Pip) stands still within 2.3 m, loot accrues at 140 a second (280 during its ability), coins fly to the panel, a 5 m ring is drawn and every 5 s guards within 5 m start Investigating (208–213).
- Down: at zero health a crew member drops, has 10 s, and is revived to 30% by an ally standing next to it for 3 s (203); otherwise captured.
- Get out (173–175): the skiff flies to the edge nearest the crew's centroid, 20 s at the Heart and 5 s elsewhere; everyone runs to it; when all are aboard the heist ends.
- Abilities as prototyped (166–172): Stuff the satchel (×2 load for 5 s), Unslowed (+25% speed for 6 s), Root (half damage 6 s), Stand over (8 s return-at-40% field), Burst (stuns guards within 1.6 m for 2.5 s). Sage (180): Recall returns a downed member at 40%, Reveal "WARDS REVEALED", Suspend "LAW SUSPENDED · 10 s" (at the crew's position). Casts (179): a 4-radius circle "STILLNESS · 10 s" at the first selected crew member.
- Motion and feel: screen shake on hits and alerts, a 1.3-second slow-motion (world at 25%) on each alert (218), coins flying to the loot panel, haptic buzz patterns, synthesised sounds.

### 1.3 Must-show check

| Must show (§23.2, §12.6, §21.8) | In the design | Verdict |
|---|---|---|
| At most eight controls (§12.7) | 5 portraits + Sage + Cast + Get out = 8 | Met at rest. A wheel or the hold menu adds 2–3 more live buttons while the portraits stay live underneath (`heist_sage.png`, wheel at z-index 6 over the row). |
| Clock | Countdown pill, red last 30 s | Met. |
| Alarm meter | "Alarm N / 6", six segments | Met; the number makes it independent of colour. |
| Vision cones (and awareness) | Focused guard's three-zone cone, others' facing wedges, travelling fill, state colours and speech | Met, following §21.12. |
| Loot (bags can take, left to load) | Room and Left | Met. |
| Vault progress | A bar of how full the bags are, with the target tick | **Partly missing**: there is no cracking progress (Vault health, §12.6: "1,500 health per Vault level"). The crack banner's bar is the 5-second hearing cycle, not the Vault. |
| Ability uses left (§12.6, §21.8) | Two pips, hollow when spent | **Partly**: §21.8 asks for "two pips with the number beside them"; no number. No pause mark for a waiting fifth ability. |
| Sage cooldown dial with seconds (§21.8, §11.7) | Yes, 20 s | Met. |
| Law banner top-left (§21.8, §15.3) | "Laws here" chips | Met (persistent), plus a 2.6 s entry card. |

### 1.4 Deviations: where the design breaks a v3.6 rule (the document wins)

| # | What | Design shows | Doc says | Section | Listed in §23.5 |
|---|---|---|---|---|---|
| H1 | Role health in the heist | Carrier 200, Breaker 260 (main.js 439 `HPR`; diorama 129 `HPM`) | 160, 180, Mender 130 | 11.1 | Yes ("Role health in the prototype's data module") |
| H2 | Vault phase | Only crew member 0 loads, automatically, at 140/s while standing near; cracking and loading happen together; no Vault health (diorama 208) | Who cracks, who helps, who loads and when to stop are the decisions; 1,500 health a Vault level, Breakers double, assist +25%; once open every role loads at 30/s, 60 under Skyskipper; the crew never acts unordered | 12.6, 12.19, 12.18 | No |
| H3 | Vault progress | Bags-fill bar only | "the Vault's progress" always on screen | 12.6, 23.2 | No |
| H4 | Alerted guard raises the realm alarm a level | "HEARD YOU · Alarm +1" and `alarmAdd += 1` on Alerted (diorama 218; main.js 113) | The realm alarm climbs only once every 30 s, once per knocked-out guard discovered, once per bell rung | 12.6, 12.17 | No |
| H5 | Abilities ready at once | All five portraits ready at the start | At most four ready; in a crew of five the rightmost waits, shown with a pause mark | 12.6, 21.8 | No |
| H6 | Uses shown | Pips only | Two pips with the number beside them | 21.8 | No |
| H7 | Ability effects | Burst stuns guards within 1.6 m for 2.5 s (diorama 171); Unslowed gives +25% speed (diorama 168, `fastU` ×1.25) | Emberling: triple Power to every ward and pylon within 1 tile; Tidewalker: nothing slows it for 6 s (no speed bonus) | 11.2 | No (§23.5 lists only the Character screen's ability differences) |
| H8 | Aiming | Sage powers and casts fire on tap at the first selected crew member (diorama 179–180); Suspend cannot choose which law; a cast cannot be placed | Portraits, powers and casts can be dragged onto the world to aim; and "nothing needs a drag that can't also be done as two taps" | 12.7, 20.8 | No |
| H9 | Get out by hold | Tap only, to the edge nearest the centroid | "Hold to choose where the skiff comes" | 12.7 | No |
| H10 | Split group's portraits | Health only | "the other group's portraits show its health and danger" | 12.6 | No |
| H11 | No law pylons in the world | No pylon exists in the diorama at all (no pylon code in realm_diorama.js) | Breaking a pylon is a crossing decision, gives a page, and a pylon shows its school colour and glyph with a first-sight tag | 12.6, 15.3 | No (the Realm view row covers looks, not absence in the heist) |
| H12 | Guard attack wind-up | A 0.7 s "grab" with no drawn wind-up (diorama 222) | Every attack shows a 0.8 s wind-up; one hit every 0.8 s for Power | 12.8, 12.16, 12.20 | No |
| H13 | Guard roles at a glance | One Glass Golem model for every guard, with a helmet | Role accessories so a guard's role reads at a glance | 12.8, 21.6 | Character sheets row covers accessories; not the heist |
| H14 | Grace at the start | Guards cannot notice anything for the first 4.2 s (diorama 214), 1.6 s after the player can act | No grace period | 12.17 | No |
| H15 | Intro and crossing | The heist is one realm: the crew starts on the Heart's rim; no outer realm, link swoop, per-realm banner | Skiffs cannot land on the Heart; the heist crosses outer realms by links with a 1 s swoop | 5.4, 12.6 | The build's own D71 says the same of the build |
| H16 | Typefaces and panels | Manrope labels, Lilita One title, dark leather HUD panels | Baloo 2 labels and numbers, Marcellus titles; ink #221C3A on paper panels at 85% | 21.8, 21.11 | No (sibling reports raise it for every screen) |
| H17 | Load target | Fixed 80% readout, not settable anywhere | "The player sets how full they want the crew before it leaves" | 12.6, 12.19 | No (a gap in the doc too, finding F2) |
| H18 | Captured label | "OUT" on a captured portrait (markup 811) | Captured; "Get out" means escaping, so "OUT" reads as escaped | 12.20 | No (text) |
| H19 | Landscape | Not designed | Portrait and landscape; never rotate mid-heist | 23.3 | Yes |
| H20 | Gait menu buttons | 44 px tall (diorama 160) | Each control at least 48 points | 12.7, 21.1 | No |

### 1.5 Adoptable: where the doc is silent and the design breaks no rule

- The whole HUD arrangement, which matches §21.8's heist layout region by region.
- "Laws here" as a persistent top-left list of law chips with their icons, plus a two-to-three second entry card naming the realm and the goal (§15.3's two-second banner).
- The "Room / Left / bar with target tick / Load to N%" loot panel: two numbers in the same unit, a fill bar and the target marked.
- Alarm as six segments, amber then red from 4, with "N / 6".
- The clock pill that turns red and pulses at 1 Hz in the last 30 s (within §20.8's three-flashes rule).
- The hold-the-ground gait menu (Crouch / Walk / Run) at the finger, with a plain tap sending at the last gait: this is §12.18 drawn.
- Tap a guard to send the nearest selected member to ambush it. §12.20 allows a fight at any moment but no section says how one is ordered; tapping the guard is the natural mapping and the build already does it (`heist_controller.gd:71`). The design also switches that member to crouch for the approach; that is the crew choosing a gait, so the build should keep the member's current gait (§12.18 "The crew never makes a decision the player did not make").
- Auto-focus of the most threatening guard for §21.12's "selected guard" (the guard with the highest suspicion, ties to the nearest), others shown as facing wedges.
- The route preview with red segments where it crosses a lit cone: it shows what is already true.
- Not the 5 m crack ring or the "Cracking · heard within 5 m" banner. §12.17 asks for the ring, but the owner's answer to F35 (D: no guard hears the Vault) removed the call, and the build follows the answer. C45 asks which source wins; while F35's answer stands, neither is built.
- Speech bubbles for state changes (§12.16 gives only examples).
- The Sage wheel as three cards with "N left", greyed during the cooldown; the cast wheel likewise. Tapping a card fires at a default target, with drag or two-tap to aim added (H8).
- Regroup replacing Get out while split (this is §12.7), cyan; "Skiff N s" countdown on the same button after calling.
- Mirroring for left-handed play (§12.7) including the portrait order.
- Coins flying into the loot panel ("rewards fly into their counter", §21.8).
- The contextual hint line, provided it can be switched off and stops after the first few heists (§15.3's "never a lecture"; §20.8 "banners … stay until dismissed if the player chooses").
- Slow-motion on an alert: owner's choice (finding F11). Wildlife cues are adopted by §23.5 (jellyfish under Current, ash moths before a vent) and appear in the heist world.

### 1.6 Prototype behaviour not to port

The prototype's heist is a toy simulation in JavaScript. The build's heist is `sim/`, which the server re-simulates, so none of the following carries over: the second, unrendered HUD pass at main.js 453 (three "stars" objectives "Empty the Vault / No alarm raised / Out before 1:00", SNEAK/WALK/RUN buttons, "SELECT ALL", a suspicion bar labelled QUIET/LISTENING/HEARD!, and hints "RUN drains stamina · guards grab for 1 heart"); stamina; hearts; guard damage of 90 a grab (diorama 222); loot rates of 140/280; "LOOT DROPPED" only for crew member 0 (176); the shield that cancels an alert ("BLOCKED", 218); Burst's stun; Unslowed's speed bonus; the 4.2 s grace; the clock that runs on a 250 ms browser timer independent of the world (main.js 188), so slow-motion steals clock time.

### 1.7 What the build has today

- `client/scripts/heist_screen.gd` (322 lines): a `Control` with `HeistHud` at the top, a flat 2D `RealmView` filling the middle, a hint plate, an action row (`_build`, 285–322): gait button cycling Walk/Crouch/Run (304), Halt (308), Drop half (309), Get out (310), and a row of three crew buttons labelled with role letters. The world steps in real time at 30 ticks a second (`_process`, 217). Online it leases the first target in the lists and submits the replay through the outbox (`begin_online`, `finish` 174). Haptics on alarm rise and on a ward or pylon falling (`_feel`, 256). Rehearsals pause and run at 75%.
- `client/scripts/heist_hud.gd` (51 lines): clock as elapsed / total counting up (37), alarm as six ●/○ pips with words, loot as "Bags can take N / left M" (51). No red last 30 s, no Vault progress, no portraits.
- `client/features/heist/heist_controller.gd` (213 lines): one selected member; `tap_tile` (71) reads the tile and gives one of the sim's commands (move, select, attack or drag a guard, crack or load the Vault, break a pylon, disarm a ward); `load_up(100)` (140) always loads to full; `get_out` (144) then a tile tap calls the skiff; twelve command kinds (`enum Kind`, 17); `CREW := 3` (23); `TICKS := 150*30` (20).
- `client/scripts/realm_view.gd` (311 lines): the island drawn flat; guard states as marks "? ?? ??? !" (§20.8); one guard's cone drawn tile by tile from the sim's sight (`selected_guard`, 33; first guard on its feet by default; `select_guard_near`, 278).
- `client/ext/src/lib.rs`: `RulebornReplay` exports `give`, `step`, `record`, `validate`, `crew` (at, role, carried, carry, health, standing, gait), `guards` (at, facing, cone, far, state, down), `wards`, `pylons`, `vault` (at, health, exposed, open), `seen`, `alarm`, `outcome`, `landings`, `reaching`. No guard suspicion, role or zones; no crew kind, ability state or down timer; no event log.
- `sim/`: twelve command kinds, no ability, Sage or cast (`replay.rs` 53–96); the replay header carries `crew: u8` only (`replay.rs` 137–154) and roles come from a fixed list (`lib.rs` 353); the realm alarm is time plus discovered knockouts, no bells yet (`lib.rs` 2141); `alarm_raised` is set when any guard reaches Alerted (`lib.rs` 702, 3181) and separates Clean from Loud (`lib.rs` 3131).
- Server routes the heist uses: `POST /v1/leases`, `GET /v1/offer`, `GET /v1/targets`, `GET /v1/bundles/:hash`, `POST /v1/heists/:token` (http.mjs 5–14). The lease carries seed, ticks and era; no crew, Sage or casts.
- Renderer: `gl_compatibility` (project.godot 26–27), Godot 4.5 (project.godot 12). v3.6 §24 pins Godot 4.7.2 with godot-rust api-4-7.

### 1.8 Plan: building the heist in Godot 4.7 on the existing architecture

The order matters because the HUD's bottom row (abilities, Sage, casts) has nothing to command until the simulation has those commands, and the 3D world must share the shell's world (sibling report on the home and realm screens plans one persistent `World` Node3D).

**Step 0. Engine.** Move to Godot 4.7.2 and godot-rust api-4-7 (sibling plan), before any 3D work.

**Step 1. Simulation (Rust, `sim/`), the dependency nobody has scheduled.**
1. Crew manifest in the replay: a new magic `RBH3` whose header carries, per crew member, the character id, kind (one of §11.2's eighteen), level and traits; the Sage id, level and power uses; the casts (law id, tier). Roles then come from the kind, not from `lib.rs` 353. The server validates the manifest against the player's roster at lease time.
2. Three command kinds in the four free values of the 4-bit kind (`replay.rs` 225): `Ability` (x = member, y = target tile or entity), `Sage` (x = power, y = target), `Cast` (x = slot, y = circle centre). Each of the eighteen abilities as a change to a named parameter (§12.21's rule), two uses, the 10 s lockout, the at-most-four-ready queue (§12.6); the Archivist's three powers first (Suspend picks a law, Reveal, Recall at 40%), the 20 s cooldown; casts as a 4-tile circle for 10 s.
3. Bell posts (alarm +1 when rung, §6.2, §12.17) and guard attack wind-ups as visible state.
4. An event log, not part of the checksum: tick-stamped records of guard state changes with cause (seen whom, in which zone; heard what), crew down, revived, caught, boarded; the alarm level and its cause; wards triggered; pylons broken; Vault opened; skiff called and arrived; law blink-outs (faults, Flicker). The result screen's decisive moment, the guard speech, the haptics, the replay annotations and the 15-second clip all read it.
5. Re-measure the decision band with abilities in (§12.6's 15–25 rule says each ability drops to one use if the median leaves the band), and regenerate the goldens under `RBH3`.

**Step 2. Extension (`client/ext/src/lib.rs`).** Export: crew `kind`, `ability_uses`, `lockout_ticks`, `ready`/`waiting`, `down_ticks_left`, `revive_progress`; guards `role`, `suspicion` (0–1000), zone radii, corner angle, `wind_up` progress; `vault` `health_max`; pylons with law id, school and health; wards visible only when seen or revealed; `alarm_raised`; the realm's clock rate (Haste); `events(since_tick)`.

**Step 3. Controller and presenter (no nodes, tested headless).**
- `HeistController` keeps the one-tap-one-command model and gains intents: `tap_member(i, additive)`, `tap_ground(tile)` at the last gait, `hold(tile)` returning the options that fit (ground: crouch / walk / run; a wall, ledge or vent: its action; the Vault: crack, load to the target; a pylon: break; a ward: disarm; a knocked-out guard: drag; a crew member: stop, drop half, drop all, see finding F9), `ability(member, target := auto)`, `sage(power, target := auto)`, `cast(slot, at)`, `get_out(at := nearest)`, `regroup()`, and `set_load_target(percent)` (finding F2). Every drag has a two-tap form (§20.8).
- `HeistHudPresenter` (new, `features/heist/heist_hud_presenter.gd`) turns the replay's state into one dictionary the view draws: clock text, red flag, Haste rate; alarm level and the newest effect's one-line text when it rises (§20.8 "every rule visible on screen when it matters"); Room, Left (hidden until the Vault opens, finding F12), fill, target; Vault progress (cracking health, then loading toward the target); portraits (uses with the number, lockout fraction and seconds, waiting pause mark, down seconds, revive progress, caught, health, danger when split); Sage (dial, uses per power); casts (uses); Get out / Regroup / Skiff N s; the banner of the moment (entry, crack, skiff, "Seen: this heist is Loud now" in place of "Alarm +1"); the hint line (switchable).
- A `heist` store slice already exists (`app_state.gd`); add `load_target`, `crew_manifest`, `sage`, `casts` to what `heist_started` takes from the planner.

**Step 4. The 3D world (shared `World` in a heist mode).**
- Build the realm from the simulation's island (`size`, `features`, `heights`, `surfaces`), square, 10–14 tiles (§21.1), not from the prototype's round layout; the prototype's island rim, rock, roots and waterfall kit dresses it.
- Creatures, buildings and props: export the design's three.js models once to glTF with three.js's GLTFExporter in a headless browser (the same method the sibling report proposes), including the rigs and the fifteen animations of §21.6, then import; the guard form with sash and lantern from the character sheets, with §21.6's role accessories. Materials replaced by one toon shader (three-step ramp, violet shadows, rim) with an inverted-hull outline.
- Overlays drawn as 3D meshes: the focused guard's three-zone cone with sharp edges and the others' facing wedges (§21.12); the travelling suspicion fill; tall grass, shade and cover as ground; pylons with the school colour and glyph and a first-sight tag (§12.6); wards when seen or revealed; the 5 m crack ring only if C45 restores it (see §1.5); the route preview with danger segments; bodies; the skiff; cast circles; wind-ups. Text over the world (guard speech, tags, the VAULT label) as 2D `Control`s placed with `Camera3D.unproject_position`, so text stays crisp, readable by the screen reader and above 13 pt.
- Camera: perspective follow at 50° pitch, about 12 tiles across (§21.1 heist camera), following the group last touched (§12.6), pinch to the whole realm, a one-second swoop between realms (removed under reduced motion), screen shake at most 4 px and switchable (§21.8, §20.8).
- Budgets of §21.3 (under 150 draw calls; merge the island's static meshes; `CPUParticles3D` on the compatibility renderer).

**Step 5. The HUD view.** `scenes/heist_screen.tscn` becomes a `SubViewportContainer` (the world) under a `CanvasLayer` HUD built from new components in `scripts/ui.gd` (each from tokens, each with an AccessKit name): `HudPanel`, `ClockPill`, `AlarmBells`, `LawChip`, `LootPanel`, `PortraitButton` (pips with number, lockout ring, pause mark, down and caught overlays, health bar), `SageButton` (dial), `ActionButton` (Cast, Get out / Regroup / Skiff), `PowerWheel` (modal: the rest of the HUD is inert while it is open, so eight tappable things is kept, finding F10), `HoldMenu`, `Banner`, `HintLine`. Left-handed mirroring in the component layout, and §20.8's "moved" later. A landscape layout (§23.3) with the panels at the sides.

**Step 6. Variants on the same screen.** No Sage before Keeper level 2 and no cast without a slot: hide those buttons (the first-session heist has neither, §16). Crew of 3 or 4. Generated targets labelled at the point of attack (§12.22 step 4) in the entry card. Ruins and rehearsals: a pause (§20.8) and the slower 75% mode for ruins (§23.5 adopted). Echo trials: the style objectives (clean, fast, untouched) shown live.

**Step 7. Tests.** Presenter tests for every state above; the §21.1 checks already run on every screen (size, reach, corners) extended to "never more than eight live controls" with wheels open; a golden replay that uses an ability, a Sage power and a cast; the planned heist given live through the new controls records the golden byte for byte (the existing test, `README` "Tests").

Effort: **XL**. The sim work (manifest, eighteen abilities, Sage, casts, events) is about a third; the 3D world and asset pipeline about a third; HUD, controller, presenter and variants the rest.

---

## 2. Heist result (screen 07)

### 2.1 The §23.2 row

> | Heist result | Celebrate or learn. | The outcome (Clean, Loud, Partial or Foiled) with its multipliers (12.9), the decisive moment with a three-second replay and one thing to try (12.13), loot kept, the entry fee, the law to study, Renown, rest for every crew member, "worth your time?"  (doc 11231–11233; changed in v3.6 from "Grade, loot kept, law to study, Renown, rest times, replay")

§23.5's rows that touch it: "Trace target: Charged or refunded an entry fee on the Observatory card, the planner and every result → No entry fee on a Trace (12.3)"; "Text size" (the result meets the 13 pt floor; body text should be 16); "The designs' own notes". The design's own must-show note (main.js 47) lists "Starlight, Essence and Renown" where §23.2 says "loot kept … Renown"; the doc's list wins and the design covers it.

### 2.2 What the design shows

One scrolling page over a violet sky (gold rays and confetti for every outcome but Foiled, a red-tinted sky for Foiled), with a fixed bottom bar (markup 824–869; screenshots `res_*`):

1. **Header** (markup 831–837): kicker "HEIST COMPLETE" or "HEIST FOILED"; the outcome as a 52 px Marcellus title (Clean, Loud, Partial, Foiled); the condition from §12.9 ("Alarm raised · everyone out"); a chip with the multipliers ("Haul ×0.7 · Renown ×0.8"; Foiled "No loot · Renown −8"); a subline "Marta's Heart · 2:14 · 2 / 6 alarm" whose alarm is fixed per outcome at 0, 2, 4 and 6 (main.js 645).
2. **Moment card** (markup 838–844): a 64 px play button "3 s" (it only plays a sound in the prototype, main.js 626 `replay`), "The moment · 0:48" and the sentence ("Your Carrier was spotted crossing the open ledge"); under a rule, the Archivist's portrait with "The Archivist · try this" and one suggestion. The four variants (main.js 637–638): Clean "Your crew crossed the open ledge while the Scout faced away" / "Kofi's universe is two realms deep. Same crew, a bigger haul."; Loud as quoted; Partial "Bramble was caught holding the gate for the others" / "Root Bramble before the Warden reaches it: half damage for 6 s."; Foiled "The Warden caught Pip at the Vault door" / "Sleepwalk guards hear running. Walk the last four tiles to the Vault."
3. **Reward tiles** (markup 845, not Foiled): Starlight, Essence, Renown as three cards that pop in (Clean +3,300 / +1,150 / +19; Loud +2,310 / +805 / +15; Partial +1,320 / +460 / +10). Renown follows §12.9's formula with 1,420 against 1,460 (main.js 635).
4. **What you kept** (markup 846, Foiled only): "Your crew is home, resting 180 min · +1 page of the law you study · Marta's laws are now in your Codex · Renown −8 · nothing else is lost".
5. **Entry fee line** (markup 847): "Entry fee 2,840 returned" (Clean, Loud), "Half the entry fee returned · 1,420" (Partial), "Entry fee 2,840 paid to Marta" (Foiled). The fee is 2% of 142,000 Starlight (data_v35.js `fee`).
6. **Study card** (markup 848–852): "Study one law you crossed · +N pages" with three paper chips (Sleepwalk, Glass, Glowing dark) showing "+3" Clean, "+2" Loud and Partial, "+1" Foiled; one tap picks and says "Sleepwalk +2 pages added".
7. **Rest row** (markup 853–856): "Every crew member rests 45 min" (Clean), 60 (Loud), "Caught crew rest 180 min, the rest 60" (Partial, the caught member ringed red), 180 (Foiled), with five faces and minutes.
8. **Easier version** (markup 857, Foiled only): "Two misses on Marta. Try "Marta's outer ring", the same laws with one guard fewer."
9. **Worth card** (markup 858–862): "Was this worth your time?" with two buttons, Yes and Not really; after a tap "Thanks. It helps us tune the targets you see."
10. **Bottom bar** (markup 864–867): a 58 px "Home" button and a wide gold CTA "RAID AGAIN · Idle crew of 5 ready" (red for Foiled) that opens the Observatory.

The 13–15 band shows the same page.

### 2.3 Must-show check

| Must show (§23.2) | In the design | Verdict |
|---|---|---|
| The outcome | Title | Met |
| Its multipliers (§12.9) | Chip | Met |
| The decisive moment with a three-second replay | Card with time, sentence, 3 s button | Met in layout; the replay itself is not built in the prototype |
| One thing to try (§12.13) | "try this" line | Met in layout; the Clean variant is not tied to its moment (finding F13) |
| Loot kept | Starlight and Essence tiles; Foiled "What you kept" | Met |
| The entry fee | Fee line | Met, except a Trace (listed in §23.5) |
| The law to study | Study card | Met; no "pages to go" (finding F16) |
| Renown | Tile; Foiled in the chip and the kept list | Met |
| Rest for every crew member | Rest row | Met |
| "Worth your time?" | Two-button card | Present but on a two-point scale where the doc reads a five-point average (finding F4) |

### 2.4 Deviations

| # | What | Design shows | Doc says | Section | Listed in §23.5 |
|---|---|---|---|---|---|
| R1 | Trace target's fee | "Entry fee 2,840 returned" on Marta, who is the Trace target (main.js 79 `traceOn:true`) | No entry fee on a Trace | 12.3 | Yes |
| R2 | Worth scale | Yes / Not really | "4.3 out of 5" and "4 out of 5" averages; the server validates 1–5 | 19.5, 25.1, 27 (12087) | No |
| R3 | Thank-you text | "It helps us tune the targets you see." | Targets are drawn by Renown band and the player's choice, and nothing is hidden; no matchmaking tuned for engagement | 12.15, 19.12 | No |
| R4 | Easier version of a player's universe | "Marta's outer ring, the same laws with one guard fewer" | The easier version by name belongs to ruins, whose difficulty is chosen; "Heists against players are never adjusted for engagement at all"; for player targets the three-strike rule leaves "a new route revealed, or a different target suggested" | 12.12, 12.14, 19.12 | No |
| R5 | Subline alarm | Clean "0 / 6 alarm" at 2:14 | The realm alarm reaches 4 by time alone at 2:14 | 12.17 | No (finding F5) |
| R6 | Tip attribution | "The Archivist · try this" every result | §15.3 separates the Archivist's tips (at most one a session, can be turned off) from the result's one thing to try (every result) | 15.3 | No |
| R7 | Clean tip | Suggests a different, richer target | "a single suggestion tied to that moment" | 12.13 | No |
| R8 | CTA text | "Idle crew of 5 ready" though the five who went are resting and the roster holds six (main.js 71–77, 658) | The roster's states (resting characters cannot go) | 11.6, 12.5 | No (a related planner row is listed) |
| R9 | Foiled kept list | "Renown −8 · nothing else is lost" while the fee was paid to the defender | Foiled: entry fee "Paid to defender" | 12.9 | No (text) |
| R10 | Pages to go | "+2" only | "Every album, law, level and track shows "2 pages to go"" | 14.8 | No |
| R11 | Share | No share | "After each heist the game cuts a 15-second vertical clip of its best moment, with the laws labelled, ready to share in one tap"; 13–15 cannot share outside the game | 17.6, 20.7 | No |
| R12 | Typefaces, panels | Manrope, Marcellus title, dark panels with paper study card | Baloo 2 and Marcellus; ink on paper panels | 21.8 | No (sibling reports) |
| R13 | Body text | 14–15 px for the moment, the tip and the kept list | 16 pt body | 21.8 | Yes ("Text size") |
| R14 | Pluralisation | "+1 pages added" (main.js 653) | — | text | No |
| R15 | Rest minutes | Flat 45/60/180 | "Hearths shorten rest 5% per level" | 11.6 | No (numbers come from the build) |
| R16 | Landscape | Not designed | Portrait and landscape | 23.3 | Yes |

### 2.5 Adoptable

- The page order: outcome and multipliers, the moment with its replay and the one thing to try, rewards, fee, the study choice, rest, then the worth question and the next step. It follows §23.1's own description of the result ("The moment that decided it, with a three-second replay, then one suggestion, then the worth-your-time tap").
- §12.9's condition line under the title ("Alarm raised · everyone out"), which is the doc's own text.
- The multipliers as one chip; Foiled's chip "No loot · Renown −8".
- "What you kept" for Foiled: it is §20.3's "Losses are capped and results show what was kept" and §12.14's "the loss is the haul, never the progress", once its last line is corrected (R9).
- The study chooser as three paper chips with the law's icon; one tap commits.
- The rest row with a face per crew member and the caught member ringed.
- The celebration (rays, confetti, the tiles popping), off under reduced motion, and the red sky for Foiled. Haul counting up into the tiles is §19.20's "deliberate ending".
- The fixed bottom bar: Home and the next step. The CTA's sub-line is a good place for one honest line of what comes next (§19.20), such as the real idle count and the next raid's fatigue (×0.85, §9.6).

### 2.6 What the build has today

- `client/scripts/result_screen.gd` (104 lines): a centred card with the grade (`Strings.term("GRADE", …)`), a detail line and a check line; buttons Watch it (32, to the replay screen), Again (50), Home (53). `show_verdict` (73) shows: the server's grade, "N loot banked — the server minted M (fee F)" (`RESULT_BANKED_SERVER`), the Keeper experience (`KeeperPresenter.earned`), "Re-simulated by the server: accepted", the offline "confirming" state, a refusal with its reason, and the Workshop and rehearsal variants (rate, publish, back to the builder).
- `HeistController.settled` (`heist_controller.gd` 200): maps the server's answer to `{grade, banked, haul, fee, keeper}`; the rest of the answer is dropped.
- Server, `POST /v1/heists/:token` (`service.mjs` 784): returns `verdict`, `fee`, `feeReturned`, `haul` (starlight, essence, total, `cappedBy`), `renown` (raider, defender), `renownCounted`, `stars`, `rating`, `defence`, `keeper`, `mode`, and `friendPages` for a friendly heist. No pages, study, rest, strays, Insight or Codex entries: D64 says pages and strays are held on the device, and the roster is not on the server yet (TC.12's next slice).
- Telemetry: `worth` events are a 1–5 integer (`telemetry.mjs` 70, 84), at most 24 a day, one per session (`telemetry.mjs` 51).
- The replay screen re-simulates a replay tick by tick (`replay_screen.gd`), which is what the three-second replay needs.

### 2.7 Plan: building the result in Godot 4.7

**Step 1. Server.**
- Pages, the Codex and the roster on the server (D64's recommendation, TC.12's next slices), because the result's study, rest and strays are settled there.
- Extend the settle answer with: `crossed` (the laws the crew met, from the replay), `studyPages` (3, 2 or 1 by §7.6), `pylonPages`, `firstMet` (laws that joined the Codex with 1 page), `floorPage` (every eighth heist, §7.6), `rest` (per crew member, minutes, after Hearths), `strays`, `insight` (finding F15), `targetKind` (player, echo, generated, Trace, ruin, friendly, trial, challenge, Workshop, rehearsal).
- A new route `POST /v1/heists/:token/study {"law"}`: once, idempotent; returns the pages added and the pages to go.
- `worth`: keep `POST /v1/events` once the scale is decided (finding F4).
- Later: a route to post a shared clip to the feed (§24 "no video is stored on the server unless shared").

**Step 2. The moment and the tip (device, from the replay).**
- `MomentPicker` (`features/heist/moment_picker.gd`, no nodes): reads the sim's event log (section 1.8 step 1.4) and returns `{tick, sentence_key, args, focus_member, focus_guard, cause}` by a rule written down (finding F3): Foiled and Partial, the first capture traced back to when its captor reached Alerted on it; Loud, the first Alerted and its cause; Clean, the closest call (the highest suspicion any guard reached on a crew member); a fault or a law blinking off at that tick is named as the cause (§12.13 "never blame luck … says so plainly").
- `content/tips.json` keyed by cause and context (seen in the open, heard running, crack ping, ward triggered, caught while reviving, clock ran out), words in `i18n/content.csv`; one tip, never a purchase.

**Step 3. Presenter.** `ResultPresenter` (pure) builds the page's view model from the stored verdict, the server's answer and the moment: kicker, outcome title, §12.9 condition, multipliers chip, subline (target, duration, the peak realm alarm truly), moment card, try line, reward tiles (Starlight, Essence, Renown, season stars, Insight; only those that apply to the target kind), the kept list (Foiled), the fee line by outcome and target kind (none on a Trace; echo, ruin and friendly variants), the caps and "Renown not counted this week" notes (G20, F40), the study chips with "+N · M to go", first-met laws and pylon pages, strays, the rest row, the three-strike offer by target kind, the worth widget (once a session), and the CTA with the true idle count. While online, the reward tiles wait for the server's answer and reveal then; offline they show what was carried, marked confirming (§24.12: "nothing is ever confirmed before it is real").

**Step 4. View.** `scenes/result_screen.tscn` as a scroll page with a fixed bottom bar, from new components: `OutcomeHeader`, `MomentCard` with an inline three-second replay (a `SubViewport` running the shared world in replay mode from tick − 45 to tick + 45, the crew member and guard highlighted, looped once; the full annotated replay stays behind "Watch it", §15.3), `RewardTile` (count-up), `KeptList`, `StudyChip`, `RestFace`, `WorthRow`, `CtaBar`, celebration effects that reduced motion removes. A one-tap share of the 15-second clip where §20.7 allows (finding F14), opening the Share sheet.

**Step 5. Tests.** Presenter tests for every outcome × target kind × validation state; `MomentPicker` tests on the goldens; the a11y and layout checks at 200% text.

Effort: **L** (the page itself M; server pages/roster/study and the moment picker make it L). It depends on the sim's event log and on pages and the roster reaching the server.

---

## 3. Findings for the register

Numbered F1… here only; ids are for the parent to assign.

**F1. The heist's abilities, Sage powers and casts have nothing to command** (deviation, significant). The design's bottom row is five ability portraits, a Sage and a cast (markup 809–820), as §12.7 requires. `sim/` has twelve command kinds and none of these (`replay.rs` 53–96); the replay header carries a crew count (`replay.rs` 137–154) and roles come from a fixed list (`lib.rs` 353); the register mentions in passing that "no abilities exist yet" (G23's body) but no item or roadmap task covers building them. Rec: a SIM task: a crew manifest in the replay (`RBH3`), `Ability`, `Sage` and `Cast` commands, the eighteen abilities as parameter changes, the four-ready rule, the Archivist's powers, casts; the server validates the manifest against the roster; the harness re-measures §12.6's band.

**F2. The load target has no control anywhere** (gap, significant). §12.6 (6992): "The player sets how full they want the crew before it leaves". §12.5's planning table and §12.7's controls do not list it. The design shows a fixed "Load to 80%" (main.js 98 `tgt:.8`; markup 801, not tappable) and the planner has none; the build loads to 100% on a tap (`heist_controller.gd` 140). Rec: the target is set in the planner (a stepper, 50–100% in tens, default the last used) and can be changed in the heist by a held tap on the Vault (§12.18's held-tap rule), so the eight-control cap holds; the `Load` command already carries a percent.

**F3. How the decisive moment and the one thing to try are chosen is not written** (gap, significant). §12.13 asks every result to name "the moment that decided it and what could have been done instead", with a three-second replay, and §23.2 makes it a must-show; no section says how the moment is found, and the simulation keeps no event log to find it from. The design hard-codes four sentences (main.js 637–638). Rec: a rule in the doc (or the register) and a deterministic picker on the device: the first capture traced to its Alerted (Foiled, Partial), the first Alerted (Loud), the closest call (Clean), a fault or blink named as the cause; tips from a content table keyed by cause; the sim gains an event log (not in the checksum).

**F4. "Was this worth your time?": two points or five, and per heist or per session** (contradiction, significant). §19.5 "one tap"; §19.5 and §25.1 gate on an average of "4.3 out of 5" / "4 out of 5" (also 12087); §20.3 and §19.5 ask it every session; §23.2 asks it on every heist result. The server validates 1–5 and counts one per session (`telemetry.mjs` 51, 84). The design offers Yes / Not really (markup 860), which cannot produce a five-point average. Rec: one row of five one-tap faces or stars on the result, asked on the first result of a session (or the last before leaving), never required.

**F5. "Alarm" means two things, and the design and the simulation took different ones** (contradiction, significant). §12.9's Clean is "No alarm" and Loud "Alarm raised"; §12.17's Alerted guard "raises the alarm"; but the realm alarm (§12.6, §12.17) climbs every 30 seconds whatever the crew does, so "no alarm" cannot mean the realm alarm. The simulation reads it as a flag set when any guard reaches Alerted (`lib.rs` 702–704, 3181). The design reads it as a realm-alarm level per alert ("HEARD YOU · Alarm +1", diorama 218; main.js 113), and its result shows Clean at "0 / 6 alarm" after 2:14 (main.js 645), which §12.17 makes impossible. Rec: v3.7 renames §12.9's condition ("no guard alerted") and keeps "alarm" for the 0–6 ladder; the heist banner says "Seen: this heist is Loud now"; the result's subline shows the true peak realm alarm or drops it.

**F6. Two result texts promise adjustments the document forbids** (deviation, significant). "Thanks. It helps us tune the targets you see." (markup 861) implies the worth rating steers matchmaking, against §12.15 "Nothing is hidden. Targets are drawn by Renown band and the player's own choice" and §19.12 (no matchmaking tuned for engagement). "Two misses on Marta. Try "Marta's outer ring", the same laws with one guard fewer." (main.js 656) offers an easier copy of a player's universe, where §12.12 keeps "an easier version, visibly and by name" for chosen-difficulty content and says "Heists against players are never adjusted for engagement at all". Neither is in §23.5. Rec: "Thanks." alone (or "It helps us make the game better"); for player targets the three-strike rule offers a different target or a revealed route (§12.14), and the easier version only for ruins.

**F7. The Vault phase in the design is automatic, Carrier-only and without cracking progress** (deviation, significant; also a must-show partly missing). The design loads for crew member 0 only, by standing near, at 140 a second while cracking at the same time (diorama 208), and its "Vault progress" is a bags-fill bar (markup 800). §12.6 and §12.19 make who cracks, who helps, who loads and when to stop the decisions, with 1,500 health a Vault level, the assist bonus, and 30 a second for every role once open; §12.18 forbids actions the player did not order; §12.6 and §23.2 require the Vault's progress on screen. Rec: crack and load are orders (tap or hold on the Vault), and the panel's bar shows cracking health until the Vault opens, then fill toward the target.

**F8. No law pylons in the heist world** (deviation, significant). The diorama has no pylon at all (no pylon code in realm_diorama.js), so the heist cannot show §12.6's crossing decision "break a pylon or not", its page, or "a pylon shows its law's school colour and that law's own glyph … and a tag names its law the first time the crew sees it" (§12.6, §15.3). §23.5's Realm view row ("Workers, pylons, wards and guard posts look alike") covers looks, not absence. Rec: design a pylon per school (the realm-view work) and draw it in the heist with its tag; the build's sim already breaks pylons.

**F9. §12.7's controls cannot stop a crew member or drop loot** (gap, minor). §12.6 makes "whether to drop loot to run faster" an escape decision and §12.19 prices it; standing still matters for tall grass and Stillness (§12.17). §12.7's table and §12.18's held taps give no way to do either. The build has Halt and Drop buttons outside §12.7's list (`heist_screen.gd` 308–309); the design has neither. Rec: a held tap on a crew member offers Stop, Drop half, Drop all (an extension of §12.18's held-tap rule, no new control, no new mechanic).

**F10. The eight-control cap against wheels, menus, the law card on request and pause** (gap, minor). With the Sage wheel open the design has eleven live buttons (`heist_sage.png`); §15.3 wants the law banner and card "on request" after the third time, and §20.8 a pause "at any time in ruins and rehearsals", each one more control beside five portraits, Sage, Cast and Get out. Rec: wheels and held-tap menus are modal (everything else inert while open), the law card opens from a held tap on a law chip only when no wheel is open, and pause is the system back gesture or the clock itself in ruins and rehearsals; the doc says which.

**F11. The design adds a start-of-heist grace and a slow-motion on each alert** (deviation, minor). Guards notice nothing for the first 4.2 s, 1.6 s after the player can act (diorama 214); the world slows to 25% for 1.3 s at each alert while the prototype's clock keeps running (diorama 218; main.js 188). Neither is in §12.17. Rec: no grace (the simulation's tick 0 is after the entry card); the slow-motion is the owner's call, and if kept it slows the simulation and its clock together, applies to every player (not removed by reduced motion, so no one gets less time) and appears in replays.

**F12. Vault contents: hidden until it opens, or always on screen** (contradiction, minor). §12.12 "the Vault's contents are only revealed when it opens" and §19.16 "A Vault shows its size before its contents" against §12.6, §12.19 and §21.8, which keep "what is left to load" always on screen. The design shows "Left 2,600" from the first second (markup 799); so does the build (`heist_hud.gd` 51). Rec: before the Vault opens, Left shows the free scout's rough estimate (§12.4) or "?", and the exact figure once open.

**F13. The one thing to try: voice and tie** (deviation, minor). The design labels it "The Archivist · try this" on every result (markup 843), merging §15.3's Archivist's tips ("at most one per session; can be turned off") with the result's one thing to try; its Clean variant suggests a richer target (main.js 638) instead of something "tied to that moment" (§12.13). Rec: label it "Try this" (or let the Sage that came voice it without the Archivist tip's limits), and tie every variant to its moment.

**F14. No clip to share on the result** (deviation, minor). §17.6: "After each heist the game cuts a 15-second vertical clip of its best moment, with the laws labelled, ready to share in one tap"; §20.7 limits 13–15 to in-game sharing. The design's result has no share entry. Rec: a share button on the moment card, opening the Share sheet, following the age band.

**F15. Insight from heists has no amount, and the result has no line for it** (gap, minor). §9.1: Insight is earned from "Successful heists, Lab discoveries, anomalies"; §12.1 lists it as a reason to raid; §11.7 levels Sages with it. No section says how much a heist gives; the design and the server show none. Rec: a number per outcome in §9.1 or §12.1, then a tile on the result. (Strays and season stars, which do have rules, also need a line on the result.)

**F16. The study chips show "+N" but not what is left** (deviation, minor). §14.8: "Every album, law, level and track shows "2 pages to go", not "83% complete"". The study card (markup 850) shows only "+2". Rec: "+2 · 6 to go", which also makes the choice a decision. The result should also list first-met laws and pylon pages, which §7.6 and §12.6 grant on every outcome; the design lists them only on Foiled.

**F17. The result has one variant; the game has about ten** (gap, significant). Targets: player, echo (no Renown, G30), generated fallback (labelled, §12.22), Trace (no fee, listed in §23.5), drifting ruin (pages and Essence, no Renown, §12.10), echo trial (style score, Insight and cosmetics, §12.10), friendly heist (no haul; the friend earns a page per raider caught, §12.11), challenge link, Workshop island and rehearsal (the build has these two). Validation states (§24.12): confirming, refused, lease expired, cap reached ("whatever is left under the cap, and a clear message"), plus the server's "Renown not counted" past ten matchmade heists a week (F40). And the first session's first result shows a law unlocked and two strays (§16). The design draws only the matchmade-player case. Rec: a variant table in the screen spec, carried by `ResultPresenter`; numbers revealed only once the server answers (online).

**F18. §23.5's claim that the heist and result "already follow this document" does not hold** (finding, minor). §23.5 (11418) lists only Role health, Trace, Text size, Landscape and the notes for these screens; F4–F8, F11, F13, H5–H10, H12, H14 and R8–R10 are further differences between the designs and v3.6, and F7 and the abilities (H7) add mechanics. Rec: v3.7's §23.5 lists them, or the register carries them as the design's open differences.

**F19. Going to the background mid-heist is not specified** (gap, minor). A phone call or a switch away stops the app; §20.8 allows pausing only in ruins and rehearsals and §24.12 says a heist runs on the device. Nothing says whether the heist pauses, continues or ends when the app leaves the foreground, nor what happens to a lease left mid-heist. Rec: the simulation pauses with the app and resumes after a three-second countdown; a heist abandoned for longer than the lease is submitted as played so far.

Also for the register, not new items: D71 (the heist is one island) now also covers the design, which is one realm (the Heart) with no link crossing; and the per-realm alarm (whether a realm's alarm counts from the heist's start or from entering it) needs a rule when crossing is built.

---

## 4. Roadmap and audit: proposed changes

Stage SC (client) and the sim and server stages would gain:

1. **SIM-H1 Crew manifest, abilities, Sage powers, casts** (F1): `RBH3`; three command kinds; the eighteen abilities; the four-ready rule; the Archivist first; casts; server manifest validation against the roster; harness decision-band re-measure; goldens regenerated. Blocks the HUD's bottom row.
2. **SIM-H2 Event log and exports**: the sim's event log (F3), bells, wind-ups; the extension exports listed in 1.8 step 2. Blocks the moment picker, guard speech, haptics and clips.
3. **SRV-R1 Pages, Codex and roster on the server** (D64's own recommendation; TC.12's next slices): then the settle answer's extra fields and `POST /v1/heists/:token/study`.
4. **TC-H HUD and controls**: `HeistHudPresenter`, the controller's new intents (hold menus, Stop/Drop, load target, two-tap aims), the HUD components, left-handed and landscape; gate: §12.7 and §21.8's must-shows met with the live-control check.
5. **TC-W Heist world in 3D**: the shared `World` in heist mode, glTF export of the design's models, toon look, cones and overlays, camera; gate: §21.3 budgets on the reference device.
6. **TC-R Result**: `MomentPicker`, `ResultPresenter`, the page, the inline replay, share, variants (F17); gate: every §23.2 must-show in every variant.
7. **Doc decisions for v3.7** (owner): F2 (where the load target is set), F3 (the moment rule), F4 (worth scale and frequency), F5 (alarm wording), F6 (no easier copy of a player's universe), F9 (Stop and Drop by held tap), F10 (modal wheels, pause), F11 (grace and slow-motion), F12 (Vault contents), F15 (Insight amounts), F19 (background), and the typefaces and panels (sibling reports).

Order: engine move → SIM-H1 and SIM-H2 (in parallel with the shell's World) → TC-H on the flat view (it works without 3D) → TC-W → SRV-R1 → TC-R.

## 5. Questions for the owner

1. Where is the load target set: in the planner only, or also in the heist by a held tap on the Vault (F2)?
2. Worth your time: five one-tap points once a session, or the design's two buttons with the gates rewritten (F4)?
3. Keep the slow-motion on alerts (F11)? If yes, it applies to everyone and slows the clock too.
4. "Try this" voiced by the Archivist, by the Sage that came, or by nobody (F13)?
5. Typefaces and panels: the design's (Manrope, Lilita One, dark leather) by amending §21.8 and §21.11, or the document's (Baloo 2, paper panels)?
