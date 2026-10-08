# Weaving, Law card, Law collection (Codex), Harmony view: Screens v3 against v3.6, and how to build them

Scope: four screens of Screens v3 (the owner's Claude Design artifact), read against design document v3.6, and planned for the Godot client on the architecture `client/` already has. The document is `docs/design/ruleborn-game-design-v3.6.txt` (cited as §N.M, with line numbers where a quote matters). Design source is in `scratchpad/art/named/` (cited as `screens_main.js:N`, `screens_meta.js:N`, `*.markup.html:N`).

The rule I applied is §23.5 (lines 11383-11393). Where the document states a rule, a number or a piece of text, the document wins. Where it is silent and a design breaks no rule, the design is adopted. A design never adds a mechanic. §23.2 is the must-show list; the designs' own notes are not.

## 0. How this was read

- Markup blocks: Weaving `screens_main.markup.html:577-623`, Law card `screens_main.markup.html:871-892`, Codex `screens_meta.markup.html:167-180`, Harmony `screens_meta.markup.html:489-508`.
- Logic: Weaving `screens_main.js:340-428`. Law card is `lawView`/`lawX` at `screens_main.js:193-214`; the looping preview is `pvEl` at `screens_main.js:215-236`. Codex is `screens_meta.js:385-430`. Harmony is `screens_meta.js:1066-1131`. Prototype data is `screens_main.js:2-92` and `data_v35.js`.
- Screenshots: `shots/all/Gameplay_03_Law_card`, `_05_Weaving`, `_13_Law_collection` and `_24_Harmony_view` (.png and .txt). The supplied Harmony capture was scrolled, so I rendered the design myself at phone size, in more states. Those captures are in `scratchpad/analysis/wlch_shots/`:
  - `hm_tidehold`, `hm_skyfield_cel`, `hm_skyfield`, `hm_ember`, `hm_crystal`, `hm_verdant_cel`, `hm_verdant`
  - `wv_default`, `wv_frictionless`, `wv_glass`, `wv_halfgravity`, `wv_info`
  - `lc_front`, `lc_back`, `lc_next_*`, `lc_n13_*`
  - `cx_top`, `cx_mid`, `cx_end`, `cx_res`, `cx_res_end`

  The bundle needs React from unpkg, which this network refuses. I served `art/` locally, routed React to the npm tarball (`scratchpad/analysis/wlch_vendor`), and served `RulebornMeta.dc.html` from `art/named/`. The scripts are in `scratchpad/analysis/wlch_scripts/`.
- The build: `client/` (README, `core/store.gd`, `app/app_state.gd`, `app/router.gd`, `features/universe/*`, `scripts/builder_screen.gd`, `scripts/realm_view.gd`, `scripts/ui.gd`, `i18n/*`), `client/ext/src/island.rs`, `sim/src/combos.rs`, `server/src/http.mjs` (route list, lines 5-99), `server/src/universe.mjs`, `server/src/sim.mjs`, `content/*.json`, `tools/roadmap.py` (stage SC, lines 936-1170), and `tools/audit_register.py` (searched by topic; items read: G25, D60, D61, G42, F56, G43, C9).
- Not read: the Resonance Lab, Realm view and Scout report blocks beyond what these four screens link to; `realm_diorama.js` beyond its attributes (`mode`, `realm`, `clean`, `focusLaw`); the creature sheets.

## 1. What the four screens share, and what the build lacks for all of them

These four screens are one system: the law table, a law's state for this player (met, pages, restored, tier, where woven), the universe's woven laws, the §5.5 pricing, and the §8 combinations with their discovery state. Most of the cost is in that shared layer, not in the screens.

| Shared need | Today | What to build |
|---|---|---|
| The law table (school, rank, notes, base cost, launch flag) | `content/laws.json` (48 laws, with rule, tiers, movement, world, raider and defender use, weakness, sound). Compiled into `sim/` as `laws_table`. The client sees only ids (`RulebornIsland.palette()["laws"]`, `client/ext/src/island.rs:255`) and names (`i18n/content.csv`, `LAW_*`). | Expose the table from the extension (`RulebornLaws.table()` → id, school, rank, base cost, notes, launch), so the client reads the same table the simulation plays. |
| Law words: rule, tier lines, weakness, resonance and chord effects, harmony and dissonance effects | Names only. `tools/client_strings.py:43-55` writes `LAW_`, `NOTE_`, `RES_`, `CHORD_`, `WARD_`, `GROUND_`, `BUILDING_` and `REALM_` names. | Extend `client_strings.py` to emit `LAWRULE_*` (tier_1), `LAWTIERS_*`, `LAWWEAK_*`, `RESFX_*`, `CHORDFX_*`, `NOTEDOES_*`, `HARMFX_*` (§8.2 table) and `CLASHFX_*` (§8.3 table). The §8.2 and §8.3 effect texts are not in `content/notes.json` yet, so `extract_content.py` needs those two tables. |
| Icons: 48 law glyphs, 8 note symbols, 4 rank frames and gems, 7 stability-band gauges, harmony/dissonance/chord/resonance marks, 6 school shapes | `scripts/ui.gd:13` has text glyphs for school shapes. No image icons. | Export the design's icon library (`icons_rbi.js` groups `laws`, `lawnotes`, `lawranksandtiers`, `stabilitybands`, `harmony`, `realms`; `icons_schools.js` `RBLaw.frame` materials) to SVG files with a one-off node script. Godot imports SVG. The note symbols match §8.1 (wave, anchor, sun, crescent, sprout, star, ring, mask). |
| §5.5 pricing and §8 combinations, once, for client and server | `sim/src/combos.rs` says which combinations sound in one realm's island, by tick. Cost and draw are explicitly "the economy's to settle" (`combos.rs:9-16`, G25). D61: a bundle carries no crown laws and the chord draw is unchecked. The server has no stability, no Aether and no law ownership. | A pure Rust module, `sim/src/stability.rs`: given the universe's woven laws (realm and crown, with tiers), the realm schools, the capacity and the era, it returns each law's cost, each realm's harmonies, dissonances, resonances and chords, which chords can pay their draw, total strain and the band. Export it through `ffi.rs` (WASM, the server) and the GDExtension (the client). This follows §24.7's "written once" for pricing, so the Weaving preview the client shows is the number the server charges. |
| Law ownership: met, pages, restored, tier, mastery; resonances and chords found or hinted | Nothing on the server. No route in `http.mjs:5-99`. `sim` reports `Outcome.pages` (broken pylons, `sim/src/lib.rs:3146`), but the server does not credit pages to laws. | A Codex service on the server (G42's "restoring laws" slice): tables for per-law pages, met and tier, discovery rows, school milestones and mastery tracks. Pages are credited at heist settlement per §14.4: the study choice, the first meeting, pylons, a foiled heist, the eighth-heist floor and the Library. |
| Aether | `GET /v1/balance` is `{starlight, essence}`. No Aether anywhere on the server (grep). | An Aether balance with its faucets (Aether Spring production) and its sinks (weaving at 40 per point, upkeep, tiers, the Lab). This is G42's production slice; Weaving cannot ship without it. |
| A sheet over any screen | `app/router.gd` swaps whole scenes (`change_scene_to_file`). No overlay. | `Router.overlay(name, params)` and `close_overlay()`: a CanvasLayer owned by `App`, recorded in the ROUTE slice so the action log keeps it. The Law card needs it, and so do the other sheets in Screens v3. |
| A looping law preview (§7.8, §21.7: "a looping four-second preview of its movement signature") | `RealmView` draws a `RulebornReplay` tick by tick (`scripts/realm_view.gd:41`). The builder already previews an island by starting a heist on it (`builder_screen.gd:187`). | A `LawPreview` component: a small island (`RulebornIsland.reset/set_ground/weave/set_vault`), started with `RulebornReplay.start` on a fixed seed with a per-law script of commands (`give`), stepped for 120 ticks (4 s at 30 per second) and looped. It shows the rule as the simulation actually plays it. The scripts (24 small command lists, for example "wade across the stream" for Slow rivers or "stand still 2 s near a guard" for Stillness) are content. The 3D movement signatures replace the drawing in the art pass. |

The design's own state is not a source (§23.5 "One data file for every screen ... the prototype's module is not a source"). Its numbers for the 24 launch laws (rank, notes, base cost) match `content/laws.json` exactly (`screens_main.js:9-33`, `screens_meta.js:386,393`, checked line by line). The launch resonances do not: the Codex hint for "Stillness + a Spirit law" (`screens_meta.js:428`) names no launch resonance. Stillness's two resonances are with Mirror images and Day and night, neither a launch law (`content/resonances.json`).

---

## 2. Weaving

### 2.1 What the document asks

- §23.2 row (line 11223): "Weaving | Put laws into slots. | Two or three recommended laws, stability bar with its seven bands, and the harmonies and clashes a law would cause before it's woven".
- §23.5 (line 11505): "Weaving | No recommended laws | Two or three recommended laws | 23.2". The same section says Weaving "already follow[s] this document" otherwise (line 11418).
- Rules the screen carries:
  - §5.1: crown and realm laws; a crown law costs double; crown slots at Spire 2 and 5; the Heart has 2 realm slots, outer realms 1, 2 or 3 by realm level; the same law cannot be both crown and realm (lines 645-649).
  - §5.5: capacity, the cost formula, strain, and the seven bands with their effects (lines 839-900).
  - §5.6: weaving times of 10 min, 40 min and 2 h; 40 Aether a point; "While a slot is being woven it is empty"; removal is instant and the slot then rests an hour; upkeep (lines 965-969).
  - §8.2: "Harmonies are shown automatically when weaving" (line 3926).
  - §8.6: dissonance is shown "While weaving, with a warning".
  - §15.2: "Weaving Bloom beside Half gravity; the stability bar".
  - §15.3: "Weaving preview | Shows harmonies, clashes and the stability band before committing | Always on".
  - §16 at 6:30: the player "sees the stability bar for the first time" (line 8864).
  - §19.6: "Two or three recommended laws with a comparison" (line 9468).
  - §20.8: "hold times adjustable" and "nothing needs ... a drag that can't also be done as two taps" (line 10300).
  - §24 "Offline play": "Building, weaving and assigning work offline, confirmed on reconnection".

### 2.2 What the design shows (Gameplay_05; wv_* captures)

Top to bottom, at 390×844:

1. **Back button** (to Realm view), top left (`markup:580-583`).
2. **Realm tapestry** (`markup:584-589`): a woven-cloth panel with three slot gems. Each gem shows the law's school glyph, its name and a sub-line: the law's notes, "Slot 2", "Crown · every realm", "Realm level 3/5" when locked, or "Weaving · 10 min" while weaving. The target slot pulses (`rbSocket`). An SVG weft (`weftEl`, `screens_main.js:255`) runs a wavy thread through the woven slots in each school's colour and a dashed thread to the target slot. At the Heart the third position is the crown law.
3. **The big card** (`markup:590-603`), 252×302:
   - A rank gem.
   - An "i" button that opens the Law card.
   - A preview area with spinning rays and a foil sheen (strong for Epic and Legendary, which are not ranks in §7.1). The preview is fed by `pvEl` but renders only a sky-plus-figure vignette.
   - A school-coloured name banner, the school glyph with the school name, and the rule (4 lines max).
   - The card can be dragged. Pulled up past 110 px it shows "Release to weave" and vibrates.
4. **Three cells** (`markup:605-609`): COST (Aether), STRAIN ("+3% = 85% → HUMMING", the band name coloured), READY IN ("10 min").
5. **The deck** (`markup:612-619`): a horizontal carousel of every restored law not already in this realm or crowned. Each card shows the glyph, a rank initial, an Aether chip, a ♪ (harmony) or ✕ (clash) badge, the name and "+N% strain" coloured by size. The deck is sorted harmony first, clash last, then cheapest (`screens_main.js:361`). A tap selects; the selected card lifts and the others fan.
6. **The weave button** (`markup:621`): "Hold or swipe the card up", subtitled "440 Aether · 11 pts · ready in 10 min". Holding for 1 s fills the button with light, with haptic ticks (`screens_main.js:424`). It changes to "Need N Aether" or "Too much strain" (when the projection reaches Breaking).
7. **Weave sequence** (`screens_main.js:427`): phase 1 sparks fly from deck to card (1 s); phase 2 rays and flash (1 s); phase 3 the card flies into the slot, which pops, Aether is deducted, and the slot reads "Weaving · 10 min" (1.2 s); then back to Realm view with `weaved:true`.

The rule logic the design uses:
- Harmony and clash per woven law and per note (`screens_main.js:355`), with the §8.2 and §8.3 effect strings (`:352-353`).
- Cost = base × tier × 0.8 (realm school) × 0.85 per harmony × 1.25 per clash (`:356`).
- Capacity 356, a constant (`:357`).
- Strain delta = this law's cost ÷ capacity (`:361-362`).
- Aether = points × 40 and ready time by tier (`:365`).
- Band names and effects as §5.5 (`:363`).

### 2.3 Numbers against the document

| Item | Design | Document | Verdict |
|---|---|---|---|
| Weaving time | 10 min, 40 min, 2 h (`:365`) | §5.6 the same | Matches |
| Aether per point | 40 (`:365`) | §5.6: 40 | Matches |
| Band names and effects | `wCONS` (`:363`) | §5.5 table | Matches (shortened: "laws may blink off") |
| Cost formula | Tier, realm school, 0.85 per harmony, 1.25 per clash; no crown ×2, no resonance ×0.8, no chord ×0.9 (`:356`) | §5.5 line 845 has all seven factors | Deviation (finding 14) |
| Who pays a harmony or clash | Only the new law is re-priced; strain delta = new law ÷ capacity (`:361-362`) | §8.2 "lowers the stability cost of both laws"; §8.3 "raises both laws' stability cost"; §5.5 strain includes "the draw of every sounding chord" | Deviation (finding 14). A weave that completes a chord moves strain by the chord's draw, 192 points (§8.5 line 4227), which the design never shows. |
| Capacity | 356, fixed (`:357`) | §5.5: Spire 30 + 8×level, plus Anchor Stones 8 + 5×level | Placeholder. The server already holds the buildings (`universe.mjs`), so capacity can be computed now. |
| The Heart's school | Spirit (`screens_main.js:35`), so Spirit laws get −20% at the Heart | §5.2: the Heart is "Neutral" | Deviation (finding 13) |
| Breaking | Refuses a weave whose projection lands in Breaking (`:406`) | §5.5: "Breaking ... No new weaving" | The document does not say whether a weave may push strain into Breaking (finding 21). |
| Harmony counting | Per woven law per shared note (`:355`) | Unstated; the Harmony view counts once per note (`screens_meta.js:1077`) | Gap (finding 10) |

### 2.4 Must-show missing

1. **Two or three recommended laws.** Listed in §23.5. The design offers the whole deck. §19.6 adds "with a comparison". No section says how the recommendation is chosen (finding 20).
2. **The stability bar with its seven bands.** The design computes it: `bands`, `mNow`, `mProj`, `seg`, `consTag` and `cons` at `screens_main.js:384-386`. The markup never renders it. Every `wv.*` binding in `screens_main.markup.html` was listed, and none is `wv.bands`, `wv.mNow`, `wv.mProj`, `wv.seg` or `wv.cons`. What shows is a text cell ("+3% = 85% → HUMMING"). Not listed in §23.5 (finding 1).
3. **The harmonies and clashes a law would cause, before it is woven.** The design computes the lines: `sel.combos` at `screens_main.js:382` gives "HARMONY with Stillness · Hush −15%" with the §8.2 effect. The markup does not render them either. What shows is a bare ♪ or ✕ badge on a deck card, with no partner, note, effect or warning (§8.6: dissonance "with a warning"). Not listed in §23.5 (finding 1).

### 2.5 Deviations

| What | Design shows | Document says | Section | In §23.5? |
|---|---|---|---|---|
| Recommended laws | The whole deck, sorted | Two or three recommended laws, with a comparison | §23.2, §19.6 | Yes |
| Seven-band bar | A text cell; the bar's code is dead | A stability bar with its seven bands, "always on" | §23.2, §15.3, §16 | No |
| Harmony and clash detail | A ♪ or ✕ glyph; the detail code is dead | Harmonies and clashes before weaving; dissonance with a warning | §23.2, §8.2, §8.6, §15.3 | No |
| Pricing | New law only; no crown, resonance, chord or draw | Both laws re-priced; all factors; draw included | §5.5, §8.2, §8.3, §8.5 | No |
| The Heart's school | Spirit | Neutral | §5.2 | No |
| Hold to weave | A fixed 1 s hold, or a 110 px upward drag | Hold times adjustable; any drag also doable as two taps | §20.8 | No |
| Crown slots | One crown position at Spire 6 | Two from Spire 5 | §5.1 | Yes ("Crown slots") |
| Text size | 8-11 px labels | 13 pt minimum | §21.8 | Yes ("Text size") |
| Tapestry capacity | Three positions | Up to five laws: 3 realm slots at realm level 5 plus 2 crown | §5.1 | No (a layout limit, not a rule) |
| Removing and the 1 h rest | No remove; the Law card's "Replace in Weaving" only navigates (`screens_main.js:670`, `lawReplace`) | Removal is instant; the slot then rests an hour | §5.6 | No (missing interaction) |
| While weaving | The slot shows the law with "Weaving · 10 min" | "While a slot is being woven it is empty" | §5.6 | No (presentation only: the build must draw it as pending and not count it as defending) |

### 2.6 Adopted silently (break no rule)

- The tapestry strip with the weft thread, the pulsing target socket and the locked slot reading "Realm level N".
- The big card with rank gem, banner, school glyph and rule, the "i" opening the Law card, and the foil on rarer ranks. Map the foil to Rare and Deep; Epic and Legendary are not §7.1 ranks.
- The three cells (cost, strain → band, ready in).
- The deck carousel: Aether chip, ♪/✕ badge and coloured "+N% strain". Keep it as the full list below the recommended two or three.
- Drag-up to weave with a haptic at the threshold, and the hold button's fill and ticks, once §20.8's adjustable hold exists.
- The three-phase weave effect, the card flying into its slot, then the return to Realm view. Reduced motion collapses it to a 150-250 ms fade (§21.8 Motion).
- "Need N Aether" and "Too much strain" disabled states.

### 2.7 Adds a mechanic?

No. The design's deck sort and its "Too much strain" rule touch on things the document leaves open (findings 20 and 21) but add nothing a player can do.

### 2.8 What the build has today

- `client/scripts/builder_screen.gd`: a LAW tool weaves a law at a tile, `island.weave(k, x, y)` (`:148-149`). A "together" line names harmonies, clashes, resonances and chords as words (`:206-221`, via `RulebornIsland.combos()`, `client/ext/src/island.rs:233-252`). `budget()` gives law slots by realm level (`island.rs:208-223`).
- No slots, crown laws, tiers, stability, strain, Aether, weaving time or slot rest anywhere.
- Server: `GET/POST /v1/universe` for realms and buildings (`http.mjs:23-26`); `law_pylon` "One per law slot" (`content/buildings.json`, `universe.mjs:65`). No weaving route and no Aether.

### 2.9 Server needs

1. **Aether.** A balance with faucets (Aether Spring production, G42 production slice) and sinks; `GET /v1/balance` gains `aether`.
2. **Law ownership.** The Codex service in §4.9 below: only restored laws may be woven, and the tier woven is the tier owned.
3. **Woven state per universe.** For each realm: slots (realm and crown), the law, its tier, `ready_at` and `rest_until`. Capacity comes from the Spire and Anchor Stones, which are held already.
4. **Routes:**
   - `GET /v1/weave`, or inside `GET /v1/universe`: the woven state and capacity.
   - `POST /v1/universe/realms/:realm/weave {slot, law}` and `POST /v1/universe/crown/weave {slot, law}`. These charge 40 Aether a point at the §5.5 price and set `ready_at` by tier. They refuse with `not_restored`, `slot_locked`, `slot_busy`, `slot_resting`, `crown_and_realm` (§5.1), `breaking` (§5.5), `aether_short`, and `needs_spire_level` for crown slots.
   - `DELETE .../weave/:slot`: instant, sets `rest_until` to now + 1 h (§5.6).
   - Every purchase names the state it leads to, as `universe.mjs` purchases do, so an offline retry is answered as made (§24.12).
5. **Pricing as one function.** `sim::stability` (section 1), called by the route and by the client preview.
6. **The bundle.** A realm's island bundle must carry what the universe has woven, crown laws included (D61), with the chord draw checked against capacity (D61, §8.6).
7. **Upkeep.** §5.6, but see finding 12: "the realm's stability budget" has no definition.

### 2.10 Plan for the Godot build

**Scene.** `scenes/weave.tscn` with `scripts/weave_screen.gd`. The route is `&"weave"` with params `{realm, slot?, law?}`. It is opened from the Realm view's slot, from the Law card's "Weave into a realm" (pass `law`; the screen adds a compact realm picker when no realm is given) and from the Universe strain bar.

**State and presenter.** A feature `features/weave/`:
- `WeaveState` slice `&"weave"`: `{realm, slot, selected, phase (idle|weaving|done), busy, error, last}`, with actions `weave_opened`, `law_selected`, `weave_asked`, `weave_made`, `weave_failed`, `unweave_made`.
- The universe and codex views stay in their own slices (`UniverseState`, a new `CodexState`).
- `WeavePresenter.screen(universe, codex, weave)` is static, as `UniversePresenter` is. It returns:
  - `tapestry`: up to 5 positions, each with law, notes, state woven/weaving/resting/locked/empty, and countdown;
  - `card`: the selected law's name, school shape, rank, rule, `LawPreview` params;
  - `cells`: cost in Aether and points, strain now → projected with band names, ready time;
  - `band_bar`: 7 segments with widths from §5.5 (0-40, 40-70, 70-90, 90-100, 100-110, 110-125, 125+, the last drawn to 140), now and projected markers, the projected band's effect line;
  - `combos`: each harmony, clash, discovered resonance and payable chord this weave makes, in words, with partner, note and %, plus a dissonance warning (§8.6);
  - `recommended`: 2-3, each with a one-line comparison;
  - `deck`: everything else;
  - `button`: label and state.

  Every number comes from `RulebornStability.price()` run on the universe with and without the candidate, so the preview is the server's price. Undiscovered resonances and chords follow whatever finding 8 settles.

**Components** (in `scripts/ui.gd` now, replaced by Claude Design's later):
- `UI.law_tile(law, size)`: deck card and Codex tile, frame by rank.
- `UI.slot_gem(slot)`.
- `UI.band_bar(view)`: a `Control` with `_draw`, using the seven gauge icons from `stabilitybands`.
- `UI.combo_line(c)`: harmony, clash, resonance or chord with the note symbol and %.
- `UI.hold_button(text, on_done)`: hold time from `Settings.hold_ms`, a new §20.8 setting; with reduced motion it shows no fill animation, just the countdown.

**Input.**
- The card takes `InputEventScreenDrag`; past 110 points it arms, with a haptic from `app/haptics.gd`.
- §20.8's two-tap equivalent: tapping a deck card selects it, and a "Weave" tap then confirms. The hold is a confirm, and its duration is the setting.
- No action needs two fingers.

**Data flow.**
1. Tap: `weave_asked`.
2. `UniverseController.weave(realm, slot, law)` calls the repository (`UniverseRepository.weave`).
3. On success: `weave_made` with the universe the server returns, and the animation.
4. Offline (G41 online first, §24 "weaving offline, confirmed on reconnection"): the intent goes into the outbox (`data/outbox.gd` gains a weave kind), the slot shows "confirming …", and the server's answer replaces it.

**3D.** None for this screen. The weft and tapestry are 2D (`Line2D` with a shader for the moving dash), the rays and foil are CanvasItem shaders, and the preview is `LawPreview` (2D now, 3D vignette in the art pass).

**Removing.** A long-press, or a "…" on a woven slot, offers "Remove". It needs a confirm tap, because Aether spent is not returned. The slot then shows a 1 h rest countdown.

**Tests.**
- Presenter tests: band edges at 40, 70, 90, 100, 110 and 125%; a harmony re-pricing both laws; a crown law at ×2; a chord's draw entering strain; Breaking refusal.
- A contract test for the new routes (`tools/client_contract.py`).
- The §21.1 size check at 150% and 200% text.

**Order.** `sim::stability`, then the server Aether and woven state, then the routes, then the presenter and tests, then the screen.

### 2.11 Effort

XL. Most of it is server and simulation (Aether, ownership, woven state, pricing as one function, the outbox kind). The screen itself is L.

---

## 3. Law card

### 3.1 What the document asks

- §23.2 (line 11215): "Law card | Explain one law in seconds. | Icon with school shape, one-line rule, looping preview, rank, pages".
- §23.5 (line 11495): "Law card | A pause sign on the front, no looping preview | The school's shape and a looping preview | 23.2".
- §21.7 (line 10980): "Law card: the school shape and colour at the top, the law's name, a looping four-second preview of its movement signature, a one-line rule, notes as symbols, rank and tier pips."
- §15.3: "Banner and card shown the first three times for each law, then only on request".
- §7.8: "a card with a looping preview".
- §7.6: pages to restore 10/20/35/60; tier II costs 20 pages + 2,000 Aether at Spire 4, tier III 40 pages + 8,000 Aether at Spire 7 (lines 2217-2219).
- §20.8: "law names always written out, never only as icons".

### 3.2 What the design shows (Gameplay_03; lc_* captures)

It is an overlay over any screen (`markup:871`), with a blurred dim backdrop and "LAW 9 OF 24" plus a close button at the top.

A flip card, 330×540, with a frame by rank (Oak, Silver, Gold, Prismatic; `icons_schools.js` `FR`).

**Front** (`markup:874-877`):
- A stability gem with the tiered cost (24 for Stillness at tier III: 15 × 1.6), the name in Marcellus, and three tier pips.
- A large art panel with slow rays and the law's glyph. For Stillness the glyph is a pause sign. A mastery star sits top right when the law is at tier III.
- An info strip: rank chip, school word, "Mastered · Tier III", "Tier I" or "Restoring · 31%", and "Woven in The Heart", "Restored · not woven yet" or "Restore all pages to weave".

**Back** (`markup:878-883`):
- Glyph, name, and "COMMON · TIME · HUSH".
- THE RULE, the full rule.
- STABILITY "24 pts" and WEAVE COST "960 Aether".
- WOVEN IN: realm chips with "Lv 6".
- WEAK AGAINST: two tappable counter-laws with a reason. Tapping one jumps to that card.

**Controls.** Previous ‹, FLIP CARD and next ›. At the bottom, "Pair it in the Lab" and "Weave into a realm". When opened from a realm where the law is woven, these become "See it in action" and "Replace in Weaving" (`markup:891-892`).

**Motion.** A 3D flip of 0.6 s with overshoot, rays turning over 40 s, and a glow on Deep or mastered cards.

### 3.3 Must-show missing

1. **The school shape.** The front names the school in words only (listed in §23.5).
2. **The looping preview.** The front shows a static glyph (listed in §23.5).
3. **The one-line rule on the face.** The rule is only on the back, behind a flip. §21.7 puts it on the card with the name and preview. Not listed (finding 3).
4. **Notes as symbols.** The front has no notes; the back has words only. §21.7 asks for symbols, and §20.8 "every note a symbol". Not listed (finding 3).
5. **Pages.** These appear only as "Restoring · 31%". §23.2 says pages: give "11 of 35 pages", and for a restored law the next tier's price ("Tier II: 20 pages, 2,000 Aether, Spire 4"). Not listed (finding 3).

### 3.4 Deviations

| What | Design shows | Document says | Section | In §23.5? |
|---|---|---|---|---|
| School shape and preview | A pause-sign glyph, no preview | The school's shape and a 4 s looping preview | §23.2, §21.7 | Yes |
| Rule on the face | Back only | On the card | §21.7 | No |
| Notes | Words, back only | As symbols | §21.7, §20.8 | No |
| Pages | Percent, while restoring only | Pages | §23.2, §7.6 | No |
| WEAK AGAINST | Law-versus-law counters invented in `screens_main.js:197`. Stillness: Whispers "One alarm still reaches every guard" and Haste "Hard to stop in time". Static: Slow rivers "Water grounds the charge" and Glass "Glass walls carry no current". | Each law has one weakness in §7.7 (Stillness: "Any Glow law breaks the hiding."; Static: "Crews that bunch up get stunned together.") and no such interactions | §7.7, §23.5 | No (finding 2) |
| "Mastered" | Tier III = mastered | Mastery is a per-school track (§18.5), and "Master a school" means weaving and crossing every law of a school at tier III and winning with each (§14.9) | §18.5, §14.9 | No (finding 4) |
| "Weave into a realm" on an unrestored law | Enabled (lc_n13: Static at 31%) | Only a restored law can be woven (§7.6 restoring) | §7.6 | No (presentation: disable it and say why) |
| Text size | 9.5-11.5 px labels | 13 pt | §21.8 | Yes |

### 3.5 Adopted silently

- An overlay sheet that opens from any law chip, banner, deck card or Codex tile, with "Law N of 24" and previous/next through the launch 24.
- Front and back with the flip. The back holds the full rule, the tier lines from `tiers_2_3`, the §7.7 weakness, raider and defender use, and the stability and weave cost.
- Frame material by rank (Oak, Silver, Gold, Prismatic), the colour carried with a rank name in words.
- Woven-in chips with realm level.
- The two context actions: Lab and Weave; and in a realm, See it in action and Replace (Replace then needs §5.6's remove and rest).
- Close by tap outside or ×.

### 3.6 Adds a mechanic?

Yes: the WEAK AGAINST counters assert interactions between laws that no section states and the simulation does not play ("Water grounds the charge"). Under §23.5 they are not built. The back shows §7.7's weakness line instead.

### 3.7 What the build has today

- Nothing for this screen. No law card, overlay or preview.
- Names in `i18n/content.csv`; no rule text, weakness or tier lines.
- `RealmView` and `RulebornReplay` can drive a preview (section 1).

### 3.8 Server needs

- `GET /v1/codex` (section 4.9) for pages, tier, restored and woven-in. Woven-in can also come from the universe view.
- A per-law "card seen" count for §15.3's "first three times". It can live on the device. Server-side keeps it across devices; it is cheap as a small counter row, or a telemetry-derived field.
- `POST /v1/codex/:law/tier {to}` if the card hosts tier-up. §7.6 prices tiers, and no screen in §23.2 names where tier-up happens; the card or the Codex is the natural place.

### 3.9 Plan for the Godot build

**Scene.** `scenes/law_card.tscn` with `scripts/law_card_sheet.gd`, opened with `Router.overlay(&"law_card", {law, context: &"realm"|&"heist"|&"any", realm?})`.

**Presenter.** `features/laws/law_presenter.gd` is static and shared with Codex, Weaving and Harmony. `LawPresenter.card(id, codex_view, universe_view)` returns:
- `name`, `school` (shape glyph and icon), `rank` (word and frame);
- `tier` (pips 0-3), `notes` (symbol plus word);
- `rule_line` (the first sentence of tier_1), `rule_full`, `tiers_line`, `weakness`, `raider_use`, `defender_use`;
- `stability` (tiered), `weave_cost` (stability × 40);
- `pages` ("11 of 35 pages" or the next tier's price), `woven_in` (realm names and levels);
- `actions` (enabled, and why not).

**Components.**
- `UI.law_card(view)` with a front and a back. Front: school shape and name at top, `LawPreview` in the art panel, the one-line rule, note symbols, rank, tier pips and pages.
- The flip is a `Tween` on `scale.x` to 0 and back, swapping faces at 0; reduced motion swaps instantly. A real 3D flip (`SubViewport` onto a quad) is not worth it here.
- Previous and next buttons are 48 pt. A swipe also pages, and §20.8's two-tap equivalent is the buttons.

**Heist context.** The design opens the card over a live heist (Gameplay_03's background is the heist). A player's heist cannot pause (§20.8 allows pausing in ruins and rehearsals only), so the card sits over the running simulation. In ruins and rehearsals it should pause. That is the build's choice, not a rule.

**§15.3 auto-show.** The heist law banner and the first three meetings of each law open the card. Keep a `LawCardSeen` counter in `user://` until the server holds it.

**Tests.**
- Presenter: tiered cost; pages text by state; actions disabled for an unrestored law; notes always have symbol and word.
- §21.1 sizes at 200%.
- A screen-reader name on every control (`tests/a11y_tests.gd`).

### 3.10 Effort

M for the card. L with `LawPreview` (24 per-law command scripts plus the component), which Weaving and the Scout report reuse.

---

## 4. Law collection (Codex)

### 4.1 What the document asks

- §23.2 (line 11255): "Law Codex | The collection. | the launch 24 laws by school and rank, growing toward 48 by season, opening in chapters (7.6), "?" for unknown laws, resonances found, mastery".
- §23.5 (line 11510): "Codex | Schools labelled as chapters | Chapters are unlock steps by Keeper level; schools are albums | 7.6".
- §7.6 (lines 2205-2225):
  - "The first time a player meets a law it joins the Codex with 1 page".
  - "The Codex opens in chapters: at launch it holds the launch 24, 12 findable from the start and all 24 from Keeper level 6. ... Matchmaking only shows universes running laws from open chapters".
  - Restoring costs 10/20/35/60 pages; the tier prices.
  - "Each school's album opens partly filled ... and pays a milestone at two, four and all eight laws restored: a Codex stamp, a skiff pennant ..., and the school's crest".
- §7.9: each school a set of eight. §14.4: the launch 24 are 10 common, 7 uncommon, 6 rare and 1 deep, 510 pages. §8.6: a resonance is shown "Once discovered; the Codex shows how many remain in each school" (line 4304). §14.9: "Find every chord ... The complete Codex". §15.3: "Codex notes | What the player has seen each law do | Filled in automatically". §18.5: "Mastery tracks | One per school, filled by crossing and weaving its laws". §19.6: "Unknown laws shown as "?"".

### 4.2 What the design shows (Gameplay_13; cx_* captures)

1. **Hub tabs:** All laws | Harmony | Lab (the Laws bottom tab's three screens).
2. **Header card:** a progress ring "18/24", "Codex of Laws", "6 hidden · 3 mastered", and a switch "RESONANCES 2/12" that turns the screen into the Resonances tab.
3. **School filter chips:** "All 18/24" plus six school icons; the selected one expands to "Time 4/4".
4. **Search field and rank filter:** All, plus four frame swatches.
5. **A NEXT LEAD card:** an unknown law's frame, "Unknown Matter law · Seen in Mira's Hive · Uncommon · Silver frame", and a SCOUT button that opens the Observatory.
6. **One album per school:**
   - A band with school icon, name, "CHAPTER I"-"VI", and "3 of 4 restored · album 2 paid".
   - A 4-column grid of law tiles. Each tile has a frame by rank, a stability badge, a tier or pages badge ("I", "★", "18/60"), the glyph, the name, the rank, and a status pill: "In Skyfield", "Ready to weave", "Restoring" or a hint.
   - Unknown tiles show "?", a silhouette glyph, "Unknown", the rank and a hint ("Scout Matter realms", "Seen in Mira's Hive", "Energy realms at night", "Win a storm heist", "Rumoured near Verdant", "Spirit realms, level 8+"; `screens_meta.js:396`).
   - A NEW ribbon (Echoes).
   - An empty-state line for filters: "Hidden laws only appear once you find a page."
7. **Resonances tab** (cx_res): an explanation, then 12 cards in three states. FOUND shows both laws, the name and the effect. HINT shows one law plus "?" and "You crossed this in Kofi's universe. Its partner is a Spirit law." HIDDEN reads "Undiscovered · Pair two laws in the Resonance Lab to find it." A floating "OPEN THE LAB" button.
8. **Bottom nav:** Islands, Laws (raised, with a "!" badge), Heist, Crew, Friends.

### 4.3 Numbers against the document

- Ranks, notes and base costs of the 24: all match `content/laws.json` (`screens_meta.js:386,393`).
- Pages needed by rank: 10/20/35/60 match §7.6.
- Album milestones at 2 and 4: match §7.6. A launch album has four laws, so "all eight" waits for seasons.
- "2/12" resonances: matches the 12 launch resonances (§7.10, §8.4; recomputed from content: 12).
- The design's hinted resonance (Stillness with a Spirit law) does not exist at launch (section 1).
- The Mangrove banks text differs: the design has "slow anyone crossing" (`screens_meta.js:428`), the document "slow crews by a further 20%" (§8.4). The document wins; the build reads content.

### 4.4 Must-show missing

1. **Chapters** as Keeper-level unlock steps. Listed in §23.5. The design labels schools "CHAPTER I"-"VI" and shows no chapter lock (12 findable, then 24 at Keeper 6). Which 12 are in chapter 1 is not stated (finding 5).
2. **"Growing toward 48 by season."** The design is fixed at /24. The 24 later laws (chapters 3-5 at Keeper 12, 18 and 24) need a visible future in each album (8 slots per school per §7.9, four of them "coming in a season"). That keeps "six sets of eight" (§7.9) legible.
3. **"Resonances found ... how many remain in each school"** (§8.6). The design gives one total, 2/12 (finding 16).
4. **"Mastery."** The design's "3 mastered" counts laws at tier III; the document's mastery is a per-school track (finding 4).
5. **Codex notes** (§15.3, "What the player has seen each law do, filled in automatically"). Absent from the design. §23.2 does not list it, but §15.3 is a rule (finding 19).

### 4.5 Deviations

| What | Design shows | Document says | Section | In §23.5? |
|---|---|---|---|---|
| Chapters | Schools labelled as chapters | Chapters are Keeper-level steps; schools are albums | §7.6 | Yes |
| Unknown-law hints and Next lead | Location and acquisition hints, some describing things that do not exist ("Win a storm heist"; "Spirit realms, level 8+", where realm levels stop at 5, §5.2/§9.6) | Unknown laws are "?"; a law joins on first meeting | §19.6, §7.6, §23.5 | No (finding 6) |
| Rank of an unknown law | Shown (rank word and frame) | "?" for unknown laws | §23.2, §19.6 | No. Minor; the build decides. Showing the rank while hiding the name is a reasonable reading of "?". |
| Per-law "mastered" | Tier III = mastered, with a star | School mastery tracks | §18.5, §14.9 | No (finding 4) |
| Resonance counts | Total only | Remaining per school | §8.6 | No (finding 16) |
| Hint content | One law plus the partner's school | "Hinted at after crossing"; no content stated | §8.4, §8.6 | No (finding 17) |
| Text size | 7.5-11 px in tiles | 13 pt | §21.8 | Yes |

### 4.6 Adopted silently

- The Laws hub tabs (All laws, Harmony, Lab).
- The progress ring header, with a switch between Laws and Resonances.
- School filter chips with counts, search, and a rank filter with frame swatches (frame plus word, never colour alone).
- An album per school with "N of 4 restored" and the milestone state.
- Tiles with stability badge, tier pips or pages ("18/60"), glyph, name, rank and status ("In Skyfield", "Ready to weave", "Restoring").
- The NEW ribbon, the empty state, the Resonances list in found, hinted and hidden states, the "Open the Lab" button, and a tile tap opening the Law card.

### 4.7 Adds a mechanic?

Yes, two:
- The unknown-law location hints and "Next lead" add what a player can see: where an unmet law can be found, and that a scout or a specific target leads to it. "Win a storm heist" and "level 8+" describe acquisition routes that do not exist.
- The per-law "mastered" status redefines mastery.

Neither is built until the document writes it.

### 4.8 What the build has today

- Nothing. No Codex screen, no law ownership on the server, no pages credited.
- The roadmap's TC.12 lists "the Codex's restorations" as a later slice of the home economy (`tools/roadmap.py:1085-1107`, G42).

### 4.9 Server needs

**Tables:**
- `law_state(account, law, met_at, pages, restored_at, tier)`
- `discovery(account, kind=resonance|chord|paradox, id, state=hinted|found, at, via)`
- `school_milestone(account, school, step)`
- `mastery(account, school, ...)`, whose fields wait on finding 4
- `codex_note(account, law, kind, count)`, for finding 19

**Settlement** (`service.mjs`, where a heist is settled):
- Credit §14.4's pages: 1 for a first meeting (per finding 7's definition), 1 for each pylon broken (`Outcome.pages` already exists), and 1 for a foiled heist.
- The study choice: 2 pages, or 3 if clean, for one crossed law chosen on the result screen. Add `POST /v1/heists/:token/study {law}`, or take it in the submit body.
- The eighth-heist floor (§7.6), and the Library trickle (production slice).
- Restoration when pages reach the rank's need, with §14.2's experience for restoring.

**Routes:**
- `GET /v1/codex`: laws (met, pages, need, restored, tier, woven_in), chapter (open count and next unlock level), schools (restored count, milestones paid), resonances by school (found, hinted with the hint's content, hidden count), chords (found, hinted), mastery tracks, notes.
- `POST /v1/codex/:law/tier {to}`: pages, Aether and Spire gate.

**Matchmaking.** It must only offer universes running laws from open chapters (§7.6). This needs the chapter list (finding 5) and touches `matchmaking.mjs`.

### 4.10 Plan for the Godot build

**Scene.** `scenes/codex.tscn` with `scripts/codex_screen.gd`, route `&"codex"`. It is the Laws tab's root, with hub tabs to `&"harmony"` and `&"lab"`.

**Feature.** `features/codex/`:
- `CodexState` slice `{view, busy, error, filter: {school, rank, query}, tab: laws|res}`, with actions `codex_asked`, `codex_loaded`, `codex_failed`, `codex_filtered`, `codex_tab`, `tier_asked`, `tier_made`.
- `CodexRepository` (`GET /v1/codex`, `POST tier`).
- `CodexPresenter.screen(slice)` returns:
  - the header (known/24, hidden, mastery per finding 4);
  - filters;
  - albums: per school a band (name, shape, restored N of 4, milestones, chapter lock if any) and tiles, each with its state (unknown "?", restoring "pages of need", restored with tier pips, woven in) and a `law` id for the card;
  - the resonance list (found, hinted, hidden, with per-school remaining counts);
  - notes.

**Components.**
- `UI.law_tile` (shared with Weaving), `UI.album_band`, `UI.filter_chip`, and `UI.field` (exists, `scripts/ui.gd:100`) for search.
- The grid: at 13 pt minimum and up to 200% text, four columns of 86 pt tiles do not fit 360 pt. Use a `GridContainer` whose `columns` is computed from width and `Settings.text_scale` (4 → 3 → 2). The tile keeps glyph, name and a status line; rank becomes the frame plus a word.

**Discovery and vocabulary.** The Resonances tab and the Harmony tab wait for §16's teaching beat (the first resonance at 10:00 of the first session). Until then the tab is absent, so the words "resonance" and "chord" arrive one at a time (§15.6).

**Tests.**
- Presenter: chapter locks by Keeper level; "?" tiles carry no name; per-school remaining counts; milestones at 2 and 4.
- Repository against `FakeTransport`; the contract check for `/v1/codex`.

**Order.** Server tables and settlement, then `GET /v1/codex`, then presenter and tests, then the screen. Tier-up can follow.

### 4.11 Effort

L. The server work (pages at settlement, restoration, discovery) is most of it. The screen is M.

---

## 5. Harmony view

### 5.1 What the document asks

- §23.2 (line 11295): "Harmony view | See how laws combine. | Notes on every law, harmonies and clashes in each realm, discovered resonances and chords".
- §8.2 / §8.3 effects and costs. §8.4 resonances: "hidden until discovered in the Lab, or hinted at after crossing them" (line 3990). §8.5 chords: "lowers the cost of all three laws by 10% ... While it sounds, a chord also draws its own stability", and "The Lab names chords — from level 3 it identifies one the player has woven or crossed" (line 4219). §8.6: shown "Once discovered" for resonances and chords.
- §8.8: three distinct laws make a chord. §8.2: "Crown laws count in every realm". §8.7 order.
- §21.7 (line 10984): "Harmony on screen: a thread in the note's colour links the two pylons; a dissonance is a jagged, flickering line; a chord forms a slowly turning triangle of light between three pylons."
- §24 "Harmony resolver": "Harmonies, dissonances and chords are worked out per realm whenever laws are woven, and stored in that realm's rule sheet."
- §7.8: "Harmony shown on the route: Keeper 1-9 harmonies only; 10-19 plus signature resonances; 20+ plus chords and paradoxes". That is the heist route, but it is the document's own staging of these words.

### 5.2 What the design shows (Gameplay_24; hm_* captures)

1. **Hub tabs:** All laws | Harmony | Lab.
2. **A realm tab strip** (scrolls): Tidehold, The Heart, Skyfield, Crystalline, Emberreach, Verdant (`screens_meta.js:1066`). Each tab carries a dot: red for a clash, gold for a chord, green for a harmony, grey for none.
3. **A clash banner** when the realm clashes: "Bloom vs Spark clash · laws +25%" (hm_ember).
4. **A 3D realm diorama backdrop** (`realm-diorama mode="realm" clean="1"`, `markup:491`). Over it float up to three law cards, each with the glyph, the name ("Kinship · crown" for a crown law), note chips and a cost delta pill ("−10%", "+25%", "±0%"). Between each pair run animated beams with flowing motes in the note's colour, labelled "FLOW −15%". A clash is a red-and-dark striped beam, flickering. A chord is a dashed triangle with a gold "♪ CHORD ♪ Deep sleep" label (hm_tidehold).
5. **"Sounding in Tidehold"** with a net "Law cost −10%" pill and dots when there are several combinations.
6. **Combination rows** (scroll): a hex badge with the kind's icon, a kind tag (CHORD, HARMONY, CLASH, RESONANCE), a % pill, the name and the effect plus cost line ("All three laws cost 10% less. While it sounds, the chord draws 192 stability."). Tapping a row highlights its beam and dims the rest. With nothing sounding: "One law alone makes no harmony. Weave a second law that shares Bloom ..." (`screens_meta.js:1114`).
7. **A first-time reveal:** switching to a realm whose combinations the player has not "seen" opens a full-screen celebration, "HARMONY FORMED", "CHORD FORMED" or "RESONANCE FOUND", with name, effect, cost line and "Nice!" (`screens_meta.js:1120,1128`; hm_skyfield_cel).
8. **Bottom nav.**

Logic (`screens_meta.js:1076-1086`):
- A harmony is every note carried by two or more laws, each of those laws ×0.85 once per note.
- A clash is both notes of an opposite pair present, each law involved ×1.25.
- A chord is the first of `CHD` that three distinct laws can carry (correct per §8.8), each ×0.9, with the text "draws 192 stability". There is no check that capacity can pay.
- A resonance is any pair in `SIG` (only Mangrove banks), ×0.8.
- None is filtered by discovery.
- The net pill is the mean of the multipliers.

### 5.3 Must-show

1. **"Notes on every law."** Shown, as text chips. §20.8 wants a symbol per note; the beam tags use the note icons (`lawnotes`) and the chips do not.
2. **"Harmonies and clashes in each realm."** Shown.
3. **"Discovered resonances and chords."** Shown, but not filtered by discovery. Undiscovered ones are named and celebrated (finding 8).
4. **The Lantern Vale realm** is in the TRY note but not in `RL`. The TRY note says Verdant clashes, but Bloom and Kinship harmonise on Bloom. The design's notes are not the must-show list (§23.5), so this is only a stale note.

### 5.4 Deviations

| What | Design shows | Document says | Section | In §23.5? |
|---|---|---|---|---|
| Undiscovered resonances and chords | Named, priced and celebrated on first view ("CHORD FORMED", "RESONANCE FOUND") | Shown once discovered; discovered in the Lab (resonances) or named by the Lab from level 3 (chords); crossing gives a hint | §8.4, §8.5, §8.6 | No (finding 8) |
| Chord payability | Always sounds | Sounds only if the universe can pay the draw | §8.5, §8.6, §5.5 | No (minor; the build computes it) |
| A crown law's cost per realm | Kinship shows +25% in Emberreach, ±0% in Skyfield, −10% in Tidehold | One law, one cost; unstated how its combinations in several realms add up | §5.5, §8.2 | No (finding 9) |
| Harmony count | Once per note | Unstated; Weaving counts per pair | §8.2 | No (finding 10) |
| Threads | Between floating cards; the clash a straight striped bar; the chord a dashed triangle with marching dashes | Thread between the two pylons; dissonance jagged and flickering; chord a slowly turning triangle between three pylons | §21.7 | No (finding 18) |
| Layout capacity | Three laws (`POS` for 1-3, `screens_meta.js:1090`) | Up to five per realm (3 realm slots plus 2 crown, §5.1), more with an era or a Grand Law from 1.1 (§5.1 scopes) | §5.1 | No (a build layout limit) |
| Text size | 7.5-10.5 px chips | 13 pt | §21.8 | Yes |

### 5.5 Adopted silently

- Harmony as a tab of the Laws hub.
- The realm tab strip with status dots. The dot is colour, so it also needs a shape or glyph: ♪ chord, ✓ harmony, ⚡ clash.
- The 3D diorama backdrop of the selected realm.
- Floating law cards with note chips and cost pills; animated beams with note tags; the chord label.
- "Sounding in" with a net pill; the combination rows that highlight their beam; a law card tap opening the Law card; the clash banner.
- A first-time celebration for a **harmony** or a **clash**, which are automatic and shown from the first day (§8.6), and for a resonance or chord once the Lab has found or named it.

### 5.6 Adds a mechanic?

Yes. The first-view reveal makes viewing one's own realm a discovery path for resonances and chords that §8.6 does not have. It changes what a player can see.

### 5.7 What the build has today

- `builder_screen.gd:206-221` names the combinations of the island in the builder as one line of words, resonances and chords included, "since this is the owner's own island".
- `RulebornIsland.combos()` (`client/ext/src/island.rs:233-252`) gives harmonies, dissonances, resonances and chords for one realm's bundle (no crown laws, D61).
- No 3D. The client draws flat and top-down (`scripts/realm_view.gd:5-8`).

### 5.8 Server needs

- The woven state of every realm, crown included (section 2.9).
- The discovery state (section 4.9).
- Pricing per realm from `sim::stability`.
- The "seen" set for first-time reveals, small and per account. A device copy is acceptable.

### 5.9 Plan for the Godot build

**Scene.** `scenes/harmony.tscn` with `scripts/harmony_screen.gd`, route `&"harmony"` with params `{realm?}`.

**Feature.** `features/harmony/`. `HarmonyPresenter.screen(universe, codex, ui)` returns:
- `realms`: tabs with a status mark in glyph and word;
- `laws`: each realm and crown law with notes as symbol plus word, and its cost change;
- `threads`: law pairs with kind and note;
- `chord`: a triangle if one sounds and can pay;
- `rows`: combinations, discovery-filtered, with "Something else sounds here: the Lab can name it" for an undiscovered one, as finding 8 settles;
- `net`: the realm's law-cost change computed from real costs, not a mean of multipliers.

All numbers come from `RulebornStability.price()`.

**3D.** The realm diorama is shared with the Universe map and Realm view, whose analysis owns it.
- This screen needs: `mode=realm`, `clean` (no other overlays), a fixed camera framing, and the screen positions of the law pylons (`Camera3D.unproject_position` on each pylon node) so cards and threads anchor to pylons, as §21.7 puts them.
- Threads are a `Line2D` per pair in a `Control` over the `SubViewportContainer`, with a shader scrolling the note-coloured dash. A dissonance is a jagged polyline with a flicker kept under 3 Hz (§20.8: no flashing above three a second). A chord is a slowly rotating `Polygon2D` outline.
- Reduced motion freezes the motion and keeps the shapes.
- Before the diorama exists, use the flat `RealmView` of the realm's island with the pylon tiles. It already places pylons.

**Layout for five laws.** Cards anchored at their pylons with a collision nudge. When pylons crowd, collapse to name chips at the pylon with the card below.

**Celebration.** A modal sheet for a first harmony or clash, or for a discovery the Lab or a crossing just made. Never for an undiscovered resonance or chord.

**Vocabulary staging.** Show only harmonies and clashes before the first resonance beat. Show chords once the Lab can name them (Lab level 3) or one is discovered (§8.5, §15.6).

**Tests.**
- Presenter: a crown law counted in every realm; chord payability by capacity; the discovery filter; five-law layout; status marks never colour-only.

### 5.10 Effort

L. It depends on the 3D diorama (shared), `sim::stability` and the discovery state.

---

## 6. Findings for the register

Only items not already in §23.5 or the register. I searched `tools/audit_register.py` for: codex, discovered, hint, crown, mastery, meets, harmony, chord draw, upkeep, stability budget, chapter, findable, weaving. The near ones are G25 (effect readings), D61 (sim plays no crown laws and does not check the draw), G42 (the home economy slices) and C9 (a stale "36 laws", which v3.6's Codex row has fixed: it now reads "the launch 24 ... growing toward 48").

1. **[deviation, significant] Weaving renders neither the seven-band stability bar nor the harmonies and clashes a law would cause; its code computes both.**
   - Evidence: §23.2 line 11225; §15.3 "Weaving preview ... harmonies, clashes and the stability band before committing | Always on"; §16 6:30 "sees the stability bar for the first time"; §8.6 dissonance "While weaving, with a warning". `screens_main.js:382` (`sel.combos`) and `:384-386` (`bands`, `mNow`, `mProj`, `seg`, `cons`) are never bound in `screens_main.markup.html:577-623`. What shows is "+3% = 85% → HUMMING" and a ♪ or ✕ glyph. §23.5 says Weaving "already follow[s] this document" except recommended laws (line 11418).
   - Rec: list it in §23.5's table. The build renders the bar and the combination lines the design's own code computes.

2. **[deviation, significant] The Law card's WEAK AGAINST invents law-versus-law counters.**
   - Evidence: `screens_main.js:197` (`CT`), for example Static is weak against "Slow rivers: Water grounds the charge" and "Glass: Glass walls carry no current", and Stillness against "Haste: Hard to stop in time". §7.7 gives one weakness each (`content/laws.json`: Stillness "Any Glow law breaks the hiding."; Static "Crews that bunch up get stunned together."). No section states these interactions; §23.5 line 11391 forbids a design adding one.
   - Rec: the back shows §7.7's weakness, plus raider and defender use. List it in §23.5.

3. **[deviation, minor] The Law card's face lacks the one-line rule, notes as symbols and pages.**
   - Evidence: §21.7 line 10980 ("the law's name, a looping four-second preview ..., a one-line rule, notes as symbols, rank and tier pips"); §23.2 "pages". The front (`screens_main.markup.html:874-877`) has name, glyph, rank, tier pips and "Restoring · 31%". The rule and the notes, as words, are on the back only.
   - Rec: add these to §23.5's Law card row. The build puts them on the face.

4. **[deviation and gap, significant] "Mastery" is a per-law tier III in the design and a per-school track in the document, and the track has no figures.**
   - Evidence: `screens_main.js:196` (`mast = tier III`) and the "Mastered · Tier III" star; Codex "3 mastered" (`screens_meta.js:391,406`). §18.5: "Mastery tracks | One per school, filled by crossing and weaving its laws". §14.9: "Master a school | Weave and cross every law of one school, at tier III, and win with each". §23.2 Codex "mastery". No section says what fills a track, by how much, or its milestones.
   - Rec: define the track: events, counts, milestones, and the "title and visual style" rewards. Name tier III "Tier III", not "mastered".

5. **[gap, significant] §7.6 opens the Codex with "12 findable from the start" and never says which twelve.**
   - Evidence: line 2215. `tools/economy_model/model.py:617`: "Which laws each chapter holds is not stated by rank, so the cheapest remaining law is always taken to be open". The same sentence makes matchmaking "only show universes running laws from open chapters".
   - Rec: list chapter 1's twelve, which must include the three starting laws (Half gravity, Slow rivers, Bloom), for example two per school. Do the same for chapters 3-5 as seasons add laws.

6. **[deviation, significant] The Codex adds hints and a "Next lead" for unknown laws, some naming things that do not exist.**
   - Evidence: `screens_meta.js:396`: "Win a storm heist", "Spirit realms, level 8+" (realm levels stop at 5, §5.2 and §9.6 line 4654), "Energy realms at night", "Seen in Mira's Hive", plus a SCOUT button. Against §19.6 "Unknown laws shown as "?"" and §7.6 "joins the Codex with 1 page" on first meeting.
   - Rec: build "?" tiles with no location hint until the document writes a lead rule. If wanted, a lead could reuse §12.15's offer reasons. List it in §23.5.

7. **[gap, significant] "Meeting" a law is undefined.**
   - Evidence: §7.6 line 2205; §14.4 "Meeting a law for the first time | 1"; §7.8 "Laws on the route the player has never met". The scout report shows each realm's laws (§12.4), and the design treats a scouted law as still unknown ("Seen in Mira's Hive"). Unstated: whether meeting is crossing its realm in a heist, being on the route, seeing it scouted, meeting it in a ruin, or the Archivist giving it.
   - Rec: define meeting (for example: a heist or ruin route enters a realm running it). Say whether scouting reveals the name without the page.

8. **[gap, significant] What an owner sees of an undiscovered resonance or chord active in their own realm.**
   - Evidence: §8.4 line 3990 "hidden until discovered in the Lab, or hinted at after crossing"; §8.5 line 4219 "The Lab names chords"; §8.6 "Once discovered". But §5.5's price applies ×0.8 per resonance, ×0.9 per chord and the chord's draw, 192, unconditionally, so Weaving's strain and the Harmony view's costs move by unexplained amounts. The design names and celebrates them on first view (`screens_meta.js:1080,1120,1128`). The client's builder already names them "since this is the owner's own island" (`client/scripts/builder_screen.gd:206-208`).
   - Rec: state it. Either weaving both laws, or all three, discovers it (a new path, to write into §8.6), or it applies and shows as an unnamed "something sounds here" until the Lab names it.

9. **[gap, significant] A crown law's cost when it harmonises or clashes in several realms.**
   - Evidence: §8.2 "Crown laws count in every realm ... A harmony lowers the stability cost of both laws by 15%"; §5.5 prices one law once. §8.5's worked example has a crown law in one realm only. The design shows a different delta for Kinship per realm (+25% Emberreach, ±0% Skyfield, −10% Tidehold; hm_*).
   - Rec: state whether a crown law's discounts and penalties compound across every realm, apply once, or are counted per realm in strain.

10. **[gap, significant] Harmony counting.**
    - Evidence: §8.2 "When two laws ... share a note, they harmonise" leaves open: three laws on one note (one harmony or three pairs), and two laws sharing two notes. §8.5's example only fixes two different notes on two different partners (Thorns ×0.85²). The design counts per pair per note in Weaving (`screens_main.js:355`) and once per note in Harmony (`screens_meta.js:1077`).
    - Rec: one sentence in §8.2, mirrored in §5.5.

11. **[gap, significant] The first session weaves laws that §5.6 says take 10 minutes.**
    - Evidence: §16 line 8848 at 0:30 "places it in their Heart. Stones lift"; line 8864 at 6:30 Bloom woven, "sees the stability bar"; the session ends at 10:00. §5.6 line 965 "10 minutes at tier I". No exemption is written.
    - Rec: state that first-session weaves (or the starting laws' first weave) are instant.

12. **[contradiction, minor] Upkeep is priced against "the realm's stability budget", but stability exists only per universe.**
    - Evidence: §5.6 line 969 "25% when the realm's stability budget is fully spent ... a realm running laws worth half its stability"; §9.5 and §29.1 the same. §5.5: "Stability is how much law a universe can hold".
    - Rec: define a realm's share (its woven laws' cost ÷ capacity, with crown laws charged to the Heart or split), or price upkeep on the universe's total.

13. **[deviation, minor] The prototype gives the Heart the Spirit school, so Spirit laws get the 0.8 realm-school discount there.**
    - Evidence: `screens_main.js:35` (`heart:{...school:'Spirit'}`) and `:356`. §5.2: Heart | Neutral.
    - Rec: the build follows §5.2; list it in §23.5.

14. **[deviation, minor] Weaving's projection prices only the new law, without crown, resonance, chord or draw.**
    - Evidence: `screens_main.js:356` (`wCostOf`) and `:361-362`, against §5.5 line 845 (all seven factors) and §8.2/§8.3 "both laws".
    - Rec: the build uses one shared pricing function. List it in §23.5 so nobody copies the prototype's arithmetic.

15. **[deviation, minor] Hold to weave is fixed at 1 s.**
    - Evidence: `screens_main.js:424` (`p>=1`). §20.8 line 10300 "hold times adjustable". `client/README.md` says the client holds nothing, "so there is no hold time to adjust", and Settings has no hold time.
    - Rec: add a hold-time setting before any hold ships, and keep the two-tap path (§20.8).

16. **[deviation and gap, minor] The Codex counts resonances in one total, and the document does not say how a two-school resonance counts.**
    - Evidence: §8.6 line 4304 "the Codex shows how many remain in each school". The design shows 2/12 (`screens_meta.js:406`). Mangrove banks joins Time and Life.
    - Rec: say how a two-school resonance counts in each school's remaining number.

17. **[gap, minor] What a crossing hint reveals.**
    - Evidence: §8.4 "hinted at after crossing them in someone else's universe"; §8.5 "crossing one gives a hint". The content is unstated. The design: one law plus the partner's school, and where it was crossed (`screens_meta.js:428`).
    - Rec: write the hint's content (the design's form is a good default).

18. **[deviation, minor] The Harmony view's threads are not §21.7's.**
    - Evidence: §21.7 line 10984 (thread between the two pylons; dissonance jagged and flickering; chord a slowly turning triangle). The design draws beams between floating cards, a straight striped bar and a dashed triangle with marching dashes (`screens_meta.js:1093-1100,1125`).
    - Rec: the build anchors the threads to pylons and draws §21.7's shapes. List it in §23.5.

19. **[gap, significant] Codex notes (§15.3) are in no screen design and are undefined.**
    - Evidence: §15.3 "Codex notes | What the player has seen each law do | Filled in automatically". The design's Codex and Law card have nothing like it, and §23.2's Codex row does not list it.
    - Rec: define what is recorded (for example: times crossed, what it did to the crew, pylons broken) and add it to §23.2's Codex or Law card row.

20. **[gap, minor] No rule for choosing Weaving's two or three recommended laws, or for the comparison.**
    - Evidence: §23.2 line 11225 and §19.6 line 9468 ("with a comparison"). Nothing says what is recommended: harmony first and no clash, the cheapest strain, the realm's school, or what defends best. The design's deck sort (harmony, then no clash, then cheapest; `screens_main.js:361`) is one candidate.
    - Rec: state the ranking and what the comparison shows.

21. **[gap, minor] Weaving edges the document leaves open.**
    - (a) Whether a weave may take strain into Breaking. The design refuses it (`screens_main.js:406`); §5.5 only says Breaking allows no new weaving.
    - (b) What happens to a woven law when its tier is raised: re-woven at the new tier's time, or upgraded in place.
    - (c) Whether one law may be woven as a realm law in several realms at once. §5.1 forbids only crown plus realm; the design allows it.
    - Rec: one line each in §5.5, §5.6 and §5.1.

## 7. Roadmap tasks this implies (stage SC, and the server work under G42)

In dependency order. "S/M/L/XL" is effort.

1. **TC.L1 Law data and words on the client (S).**
   - The extension exposes the law table.
   - `client_strings.py` emits rules, tier lines, weaknesses, uses, and resonance, chord, harmony and clash effects. `extract_content.py` gains §8.2's and §8.3's effect tables.
   - Icons exported from the design to SVG.
2. **TC.L2 Overlay route and `LawPreview` (L).**
   - `Router.overlay`.
   - The preview component on `RulebornIsland` and `RulebornReplay`, with 24 per-law command scripts as content.
3. **TC.L3 Law card (M).** It depends on L1 and L2. Codex fields are filled once L5 exists; until then it shows the law alone.
4. **T-econ `sim::stability` (M).** §5.5 pricing and §8 combinations for a universe, exported to WASM (server) and GDExtension (client). Golden tests on §8.5's worked example (27.44 → draw 192) and §5.5's worked rows. This also closes the D61 side for the pricing.
5. **G42 slice: Codex on the server (L).** Law state, pages at settlement (§14.4 sources, the study choice, the floor), restoration with §14.2's experience, discovery rows, milestones, tier-up, `GET /v1/codex`. It needs findings 5, 7, 8 and 4 answered, or an interim reading recorded as a deviation.
6. **TC.L4 Codex screen (M).** It depends on L1 and server slice 5.
7. **G42 slice: Aether and weaving on the server (L).** Aether balance and faucets, woven state, weave, unweave and crown routes with timers and rest, bundles consistent with woven laws, crown laws carried (D61). It depends on 4 and 5.
8. **TC.L5 Weaving screen (L).** It depends on 4, 5 and 7, the outbox weave kind, and the §20.8 hold-time setting.
9. **TC.L6 Harmony view (L).** It depends on 4, 5 and 7, plus the 3D realm diorama (from the Universe and Realm view work). It can ship first over the flat `RealmView`.

Each screen task is gated in the current way: presenter and reducer tests, the contract check, §21.1 sizes at 200% in both languages, a11y names, and the colour check.

## 8. Limits

- The 3D diorama component and its Godot port belong to the Universe map and Realm view analysis. I read only the attributes this screen uses.
- I did not read the Resonance Lab screen, whose rules (Lab level, experiment times, insight pages) feed the discovery state here.
- I did not run the client or the server. Statements about them come from reading the code cited.
- I did not check the design's colours against §21.2 and §21.8 contrast. The colour check in `ui/colour_check.gd` will, once tokens land.
