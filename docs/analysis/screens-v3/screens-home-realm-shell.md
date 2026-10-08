# Universe map, Realm view and the navigation shell: Screens v3 against v3.6, and the Godot build

Scope: the home screen (Universe map, §23.2 row 1), the Realm view (§23.2 row 4), and the navigation shell every screen sits in (top HUD, resource bar, tab bar, badges, side buttons, the menu sheet, sub-screen headers and hub tabs, banners). Read-only analysis; nothing in the repository was changed.

## 0. What was read, and how

Design document: `docs/design/ruleborn-game-design-v3.6.txt` — §5.1–5.8, §6.1–6.2 (rows used), §9.1–9.4, §10 intro, §10.1, §10.2 (Spire, Vault, Anchor Stone, Star Well, Aether Spring, Storehouse, Law Pylon, Hearth, Nursery, Guardian Post, Ward headers), §10.3, §12.3, §14.6, §14.8, §18.8, §19.12, §20.2, §20.3, §20.8, §21.1–21.5, §21.8–21.12, §22.1, §23.1–23.5, §24 (engine row); the v3.4→v3.6 diffs in `scratchpad/v36/diffs.txt`.

Screens v3 (owner's Claude Design artifact, unpacked):
- `art/named/screens_main.markup.html` — home block lines 365–468, realm block 469–576, tab bar 431–440, menu sheet 442–466 (the line 319 "navGame" block is the prototype's own screen index, not an in-game element).
- `art/named/screens_main.js` — data at lines 34–38, state and navigation 100–126, home/realm view-model 127–187, menu groups 430, rStat (realm laws panel) 338–341, tab bar 665–666, strain pill 672, collect-all 676, build trays 156–162, selection actions 146–155.
- `art/named/screens_meta.markup.html` / `screens_meta.js` — the same tab bar repeated on meta screens (markup 44–48, 158–162 …), the back-button header (markup 248, 297, 374, 512), the hub segmented control (`screens_meta.js`, the `HB`/`hub` block near its end).
- `art/named/realm_diorama.js` — the `<realm-diorama>` three.js element: data 60–90 (realms, universe layout, links, faults, locks, building kinds, Heart and generated layouts), camera 512, island 945, realm 1057, universe 1073–1170, rail/labels 1224–1239, collect/focus 1240–1243, building info/select/move/upgrade/workers 1275–1291, rotate/zoom 1393–1396, focus/unfocus/open 1400–1405.
- `art/named/data_v35.js` (the prototype's data module — §23.5 says it is not a source).
- Screenshots: `shots/all/Gameplay_01_Universe_map.png/.txt`, `Gameplay_04_Realm_view.png/.txt`. I also drove the prototype myself (Playwright, React served locally) to capture states the stock shots do not show: the menu sheet (top and scrolled), the island focus card for Skyfield and the Heart, the locked sixth realm, the realm view with its laws panel open, and more as listed in section 7. Those captures are in `scratchpad/analysis/hrs/shots4/`.

The build: `client/` (README; `scripts/home.gd`, `scripts/universe_screen.gd`, `scripts/ui.gd`, `scripts/realm_view.gd`, `app/router.gd`, `app/app_state.gd`, `app/services.gd`, `core/store.gd`, `features/universe/*`, `features/keeper/keeper_presenter.gd`, `data/repositories/universe_repository.gd`, `ui/tokens.json`, `ui/tokens.gd`, `tests/run.gd` 556–600, `project.godot`, `ext/src/island.rs`, `ext/Cargo.toml`), `server/` (`src/http.mjs` route list 1–90, `src/universe.mjs`, `src/facts.json` keys), `sim/src/island.rs` 94–110, `tools/roadmap.py` stage SC (930–1165), `tools/audit_register.py` (G42, F56, G43, FRONTEND/BOTH sets).

Not read: the Rust sim beyond the island struct; the economy model; other agents' screens in depth (Weaving, Terrain editor, Defence curation, Observatory are referred to only where the home or realm view hands off to them).

Rule applied throughout (§23.5): the document wins wherever it states a rule, number or text; where it is silent and a design breaks no rule, the design is adopted; a design never adds a mechanic.

---

## 1. The navigation shell

### 1.1 What the design shows

The shell is not one component in the prototype; it is assembled per screen. Read together it is:

1. **Top HUD on the Universe map only** (markup 370–396):
   - Top-left: the Keeper's portrait in a ring whose gold arc is the Keeper-level progress (conic 68%), a level badge ("24") under it, the name "Wren" in Marcellus 18 px, and a Renown chip (pink gem, "1,460"). Tapping it opens the menu sheet (`menuOpen`).
   - Top-right: the universe stability pill — a band-coloured dot and "82% · Humming" (`strainV`, screens_main.js:672). Tapping it goes to Weaving.
   - Under them, full width: three resource bars (Starlight, Aether, Essence), each a dark capsule with the currency icon, the value ("142.0k"), a 3 px storage fill along its bottom edge in the currency colour, and a "FULL" tag at 90% of the cap (`rbar`, screens_main.js:168–169; caps hard-coded 200,000 / 80,000 / 65,000). Collected resources fly into these bars and the bar pulses.
2. **Side buttons** on the map (markup 385–392), 44 px leather circles with a plate label: left — Defence (red badge "2", and a cyan shield chip "5h 12m"), Lab; right — Season (badge "3"), Shop (green badge "!").
3. **Bottom tab bar** (markup 431–440; repeated on Observatory, Roster, Codex, Lab, Workshop, Forms, Friends): five tabs — Islands, Laws, Heist (centre, with a pulsing gold glow), Crew, Friends. The active tab's icon pops up (45 → 68 px, bobbing 2.4 s), its label grows (10 → 13.5 px). Each tab carries a badge: Islands "3", Laws "!", Heist "4", Crew "▲", Friends "3" (static in the markup). Tab grouping (screens_main.js:666): Islands = home, realm, weave, terrain, workshop, curation, rehearsal; Laws = codex, harmony, lab; Heist = observatory, scout, planner, landing; Crew = roster, character, sages, forms; Friends = friends, share.
4. **Menu sheet** (markup 442–466; groups at screens_main.js:430): a full-height parchment sheet opened from the portrait — a header card (portrait, "Keeper 24 · Renown 1,460 · 128 heists", STATS › to Profile and stats, close ×) and every screen grouped by tab (ISLANDS, HEIST, CREW, LAWS, FRIENDS, MORE: Profile, Season, Shop, Settings), each row with icon, name, one-line purpose, a count badge and "YOU ARE HERE". It is the only way to Settings and Profile from home besides the side buttons.
5. **Sub-screen header** (meta markup 248, 297, 374, 512): a 44 px back button top-left that always goes home, a kicker ("SEASON 2 · TIME") and a title (Lilita One 23 px), and a chip on the right (e.g. "18 days").
6. **Hub segmented control** at the top of the Crew tab (Roster / Sages / Forms) and the Laws tab (All laws / Harmony / Lab), 36 px tall (screens_meta.js, `HB`/`hub`).
7. **Realm view chrome** has no tab bar: big round MAP (80 px, bottom-left), WEAVE (64 px, above it, "1 free" badge) and BUILD (84 px gold, bottom-right).
8. **Transitions** (screens_main.js:102, 187): a 160 ms fade with a 0.985 scale between screens; entering a realm from the map is a camera dive into the island with the realm's sky fading in (realm_diorama.js:1404–1405).
9. **Toasts and banners**: the raid banner over the tab bar (markup 398–405), the locked-realm toast (406), and in meta screens a gold toast at the top.
10. **Sound and haptics**: synthesised tones per tap/collect/open and `navigator.vibrate` (realm_diorama.js:37–52).

### 1.2 What the document asks of it

- §21.1 Screen: portrait 9:19.5, one-handed, every frequently used control in the lower two-thirds, primary controls ≥ 48 pt (9 mm), nothing interactive in a screen corner, nothing important within 44 pt of the notch or the home bar.
- §21.8 Type: body ≥ 16 px, nothing below 13 pt, Baloo 2 for labels and numbers (tabular numerals), Marcellus for titles and law names; contrast 4.5:1 plus a perceptual check. Colours: ink #221C3A on paper panels at 85% over the world; gold for main actions, red #E2536B alarms, green #3FBF7F success. Motion 150–250 ms easing out; buttons squash; rewards fly into their counter; shake ≤ 4 px; reduced motion removes swoops and most particles. Haptics: light tap on buttons.
- §21.8 Home layout: resources with storage bars top-left; Keeper level and Renown top-right; stability band top-centre; build, weave and terrain tools bottom-left; a large skiff-shaped Heist button bottom-right; alerts down the left edge.
- §23.1 (the Godot mock-ups): "Resources and strain at the top, the closest goal and the two main actions in the thumb zone, five tabs at the foot."
- §23.3: landscape everywhere, remembered per device, never more information than portrait, interface moved to the sides.
- §20.8: one finger for everything, two-tap alternative to every drag, adjustable hold times, text to 200%, high contrast, reduced motion, nothing by colour alone, every menu works with VoiceOver/TalkBack.
- §14.8: the home screen surfaces the goal closest to done; progress is said as "N to go", never "83% complete"; progress bars never appear in the shop.
- §18.8: no timers on the home screen, no "last chance" banners.
- §21.11: Baloo 2 and Marcellus are the licence ledger's first entries.

### 1.3 Where the shell differs

| # | What | Design shows | Document says | § | In §23.5? |
|---|---|---|---|---|---|
| S1 | Home placement | Keeper + Renown top-left, strain top-right, resources as a full-width row, no build/weave/terrain on home, Heist as the centre tab, alerts on both edges and a bottom banner | Resources top-left, Keeper/Renown top-right, stability top-centre, build/weave/terrain bottom-left, skiff Heist button bottom-right, alerts down the left | 21.8 | No |
| S2 | Bottom tab bar | Five tabs edge to edge; the outer tabs reach the bottom corners and the buttons end 18 px above the bottom edge | Nothing interactive in a corner; nothing within 44 pt of the home bar. (§23.1 itself describes "five tabs at the foot") | 21.1, 23.1 | No |
| S3 | Back button | Top-left corner on every sub-screen, at 50 pt | Frequently used controls in the lower two-thirds; nothing in a corner | 21.1 | No |
| S4 | Hub tabs | Top of Crew and Laws tabs, 36 pt tall | Frequently used controls in the lower two-thirds; ≥ 48 pt | 21.1 | No |
| S5 | Tap sizes | Side buttons 44, strain pill 30, raid × 28, Trace 32, hub 36, law chips 30 | Primary controls ≥ 48 pt | 21.1 | No |
| S6 | Text sizes | Tab labels 10 px, badges 9.5–10, plates 8.5, Renown 12 | Nothing below 13 pt | 21.8 | Yes ("Text size") |
| S7 | Typefaces | Manrope for labels and numbers, Lilita One for meta titles, Marcellus for names | Baloo 2 and Marcellus, both in the licence ledger | 21.8, 21.11 | No |
| S8 | Panels | Dark translucent capsules with light text over the world; parchment for sheets | Ink on paper panels at 85% | 21.8 | No |
| S9 | Timer on home | "5h 12m" shield chip on the Defence button | No timers on the home screen; no shield exists past §12.3's first 72 hours | 18.8, 12.3 | No |
| S10 | Nearest goal | None on the home screen | The home screen surfaces whichever goal is closest to done | 14.8, 23.1 | No |
| S11 | Landscape | Not designed | Portrait and landscape | 23.3 | Yes |

What the shell gets right, and the build keeps: badges carry a number or a glyph ("!", "▲") as well as a colour; the active tab is marked by size and position, not colour alone; motion durations (150–320 ms) sit at or near §21.8's band; rewards fly into their counter; buttons squash on press; a light haptic on taps.

### 1.4 Silent adoptions (document silent, no rule broken)

- The five-tab grouping (Islands, Laws, Heist, Crew, Friends) and which screens belong to each tab; the Heist tab as the visual centre.
- The menu sheet as a map of every screen, opened from the portrait, with "YOU ARE HERE" and count badges.
- The hub segmented control inside the Crew and Laws tabs (placement must still meet §21.1, see S4).
- Badges on tabs and side buttons, if every badge is driven by real state the player can act on (§14.6's rule for notifications is the right test: storage full, a character rested, an experiment finished, a heist against you, a claimable tier).
- The Keeper-level ring around the portrait (with §14.8's "N to go" said in words beside it or on tap).
- The screen fade and the dive into a realm (reduced motion turns the dive into a cut).
- No tab bar inside the realm view; MAP / WEAVE / BUILD as its own action cluster.

### 1.5 What the build has today

- Routing is whole-scene swapping: `client/app/router.gd:8–22` maps 13 routes to `.tscn` files and `go()` calls `change_scene_to_file` (line 26–27). Nothing persists between screens, so a tab bar or a top HUD would be rebuilt on every navigation and the 3D world could not survive the Universe→Realm dive.
- Home is a list: `client/scripts/home.gd:9–12` lists nine places as buttons, the Keeper bar as text (pips "●●●○…" and "N of M to level K+1", `features/keeper/keeper_presenter.gd:10–26`), and a fixed "Play" button.
- Components: `client/scripts/ui.gd` (frame with 44 pt safe margins at 65–66, buttons ≥ 48 pt at 189/236, corner clearance at 277–278), tokens in `client/ui/tokens.json` citing §21.2/§21.8 (day sky, paper panels at 85%, alarm/success shades deepened under D72). The README says Claude Design's tokens and components replace these (`client/README.md`, "Where the design lands").
- The layout check `client/tests/run.gd:556–600` fails any fixed button under 48 pt, in the top third of the screen ("above the thumb zone"), within 44 pt of top or bottom, or in a bottom corner (15% of width × 8% of height). The design's portrait/menu, strain pill, side buttons, back button, hub tabs, MAP and BUILD buttons and the two outer tabs would all fail it.
- Fonts: none; Godot's default font (README "Not yet: Fonts").
- Engine: `client/project.godot:12` is Godot 4.5 and `client/ext/Cargo.toml:11` builds godot-rust 0.5.5 with `api-4-5`; v3.6 §24 pins Godot 4.7.2-stable and `api-4-7`.

### 1.6 The plan for the shell (Godot 4.7, on the existing architecture)

Order matters: the shell comes first, because both 3D screens need a world that outlives a screen change.

1. **A persistent shell scene** — `scenes/shell.tscn` + `scripts/shell.gd`, made the main scene instead of `home.tscn`. Children, back to front:
   - `World` — one `Node3D` diorama (section 2.6) that stays loaded; its mode is universe, realm, or hidden.
   - `Content` — a full-rect `Control` where screens mount.
   - `Chrome` — `TopHud`, `SideAlerts`, `TabBar`, `RealmActions`, `BackHeader`, `HubTabs`, each shown or hidden per route.
   - `Overlay` — sheets (menu, focus card, law card), banners, toasts.
   The router keeps its API: `Router.go(name, params)` still dispatches `navigated`; its `change` callable becomes `shell.mount(path)` (instancing into `Content`) whenever the shell exists, and stays a recorder in tests. Add per-route metadata in `Router.ROUTES`: `tab` (islands/laws/heist/crew/friends/none), `chrome` (map, realm, header, hub, none), `world` (universe, realm, none). `Shell` listens to `store.changed(ROUTE)` and configures itself; no screen draws chrome of its own.
2. **New store slices and presenters**, headless and tested like the others:
   - `HudState` / `HudPresenter.bar(slices)` → keeper (level, XP to go, portrait), Renown (from `GET /v1/league`), three resources with value, cap, share, `full` (≥ 90%), all from the server's numbers; the stability band from the universe view (S-H below).
   - `BadgePresenter.badges(slices)` → per tab and side button, each with a count or glyph and a spoken form; driven by the universe (ready to collect, fault opened), the track (claimable tiers, `GET /v1/track`), friends feed, defence log (raids since last seen), roster (level up — when the roster exists).
   - `GoalPresenter.nearest(slices)` → §14.8's closest goal of any kind, said as "N to go".
3. **Components**, replacing `scripts/ui.gd`'s placeholders under the same names where they exist: `ResourceBar`, `KeeperBadge`, `StrainPill`, `RoundAction` (leather circle + plate + badge), `Badge`, `TabBar` (raised active tab, bob animation, reduced-motion still), `MenuSheet`, `BackHeader`, `HubTabs`, `Banner`, `FocusCard`, `LawChip` (school shape + name, never icon alone, §20.8). Each keeps the accessibility the current components have: an accessible name, focus order, 200% text, high contrast, the glyph-plus-words status.
4. **Tokens**: add the design's values to `ui/tokens.json` with `"from": "Screens v3 markup line N"` beside §21's — the leather rim `#1A0C14`, gold ramp `#FFF6D8 → #F2C45C → #B8741E`, parchment `#F8EDD4 → #E8D6AE`, ink-brown `#2A1A10`, the drop-shadow style (`0 3px 0`), the pop curve `cubic-bezier(.3,1.6,.5,1)` 320 ms, the bob 2.4 s. Keep §21.8's alarm/success and D72's deepened text shades. `ui/colour_check.gd` must learn the dark capsules as a background so every word on them is still checked at 4.5:1 and APCA.
5. **Fonts**: Baloo 2 (labels, numbers, tabular figures via OpenType `tnum`) and Marcellus (titles, names), as §21.8 and §21.11 require — unless the owner amends §21.8/§21.11 to Manrope and Lilita One (both are also under the Open Font Licence; that is a choice, not a licensing problem). Ship the licence text in Settings' legal page (§21.11).
6. **Icons**: the five tab icons are inline SVG in the markup (431–440) and export as files directly; the 393-icon library (`icons_rbi.js`, `window.RBI(group,name)`) is plain SVG strings and can be written out by a small Node script with a `window` shim. 163 call sites use its `<text>` helper; whether Godot's SVG importer renders `<text>` was not verified — convert those to paths if it does not.
7. **Placement rules made real** (S2–S5): the design's look kept, its hit rects moved:
   - every control's hit rect ≥ 48 pt even where the drawn shape is smaller (a transparent margin around side buttons, labels, chips);
   - the tab bar's background runs under the home indicator, but its five buttons sit above the bottom safe inset and inside the middle 70% of the width (five 54 pt tabs fit at 390 pt), so no tab is in a corner;
   - top-band controls (portrait/menu, strain pill, back, hub) are the infrequent ones; §21.1 allows that ("every frequently used control"), but `tests/run.gd:577–600 (the top-third rule at line 593)` does not. Change the check to tag controls as frequent (must be in the lower two-thirds) or not (may sit in the top band but never in a corner and never within the safe inset), and tag the back button frequent: move it into the lower band (a bottom-left "back" plate above the tab bar) or accept a swipe-back gesture plus a lower-band button. This is an owner decision (finding H).
8. **Landscape** (§23.3): the shell is the only place this lands — tab bar becomes a left rail, the top HUD a right column, the world gets the same tiles larger. Never rotate mid-heist.
9. **Engine move**: Godot 4.7.2 and `api-4-7` per §24 before the shell lands, so the shell is written once against the pinned engine.

Effort: L. Server needs for the shell alone: Aether in `GET /v1/balance` (today `{starlight, essence}`, server/src/http.mjs:15) and the storage caps, a "raids on you since" list for the defence badge and the banner, and the Keeper's name and face (§23.5's adopted first-launch order) on the account.

---

## 2. Universe map (home)

### 2.1 The §23.2 row

| Screen | Its job | Must show |
|---|---|---|
| Universe map | Home. See every realm and link at once. | Realms with their laws, links, strain band, faults, alerts, resources, heist button |

§23.5 rows that touch it: "Realm view strain … home reads Humming 82%" (home is the one that is right), "Aether storage 31,400 against 34,000 at Spire 6", "Text size", "3D universe charts — more outer islands than the target has" (the Observatory/scout charts, not home), "Landscape", "The designs' own notes".

### 2.2 What the design shows (top to bottom)

- The `<realm-diorama mode="universe">` fills the screen (markup 367): a starry violet sky with a slowly turning galaxy, nebulae, comets and floating rocks (realm_diorama.js:1073–1134); seven islands in a 2–3–2 column (UMAP, :73) — Skyfield and Crystalline at the top, Lantern Vale (locked, greyed, misted), the Heart (larger, with a pink beam, dome and three rotating rings) and Tidehold in the middle, Verdant and Emberreach at the bottom; each island a cut rock with hanging crystals in its school colour, waterfalls of particles, an aura and a coloured rim ring, with its own buildings in miniature (the five or seven most important, :945+).
- Links between islands as 3D bridges with a 22 px type badge at the midpoint (stone arch, rope, chute ">>", rift swirl) (:1164–1171, `ULINKS` :75): Heart–Skyfield stone, Heart–Tidehold stone, Heart–Verdant rift, Skyfield–Crystalline rope, Crystalline–Tidehold chute, Tidehold–Emberreach rope, Emberreach–Verdant stone; links to the locked island are not drawn.
- Each island's label: realm icon, name (Marcellus 12 px, the Heart 14), level badge (9 px) — and, when buildings are ≥ 90% full, a pulsing resource pill with how many; a red "!" bolt badge when the island has a fault (none in the demo, `UFAULT={}`). The locked island's label reads "Opens at Keeper 28".
- First tap on a label or island: the camera eases in and a focus card rises (markup 407–430): icon, "Skyfield", "Motion · Level 4 · 2 of 2 law slots", law chips ("Half gravity", "Bounce" — each opens the law card), a "1 fault" chip if any, "Ready ✦560 ◉0 ◆0", "5 buildings", and two buttons: Collect all, ENTER REALM. Second tap (or Enter realm) dives into the realm view. Tapping the locked island shows "Your sixth realm · Opens at Keeper level 28 · you are 24".
- The HUD of section 1.1 (portrait/renown, strain pill, three resource bars, four side buttons, tab bar).
- A centre "COLLECT 3.4k" button above the tab bar collects every realm at once; amounts fly into the bars (screens_main.js:676).
- About two seconds after arriving, a red skiff flies to Verdant and the raid banner rises: "Marta raided Verdant · you lost nothing / Your defence kept 1,240 Essence safe / TRACE ×" (screens_main.js:104; realm_diorama.js:1210). TRACE goes to the Observatory with Marta first.

### 2.3 Against the must-show list

| Must show | In the design | Verdict |
|---|---|---|
| Realms | Six, with level; the sixth locked with its Keeper level | Shown |
| …with their laws | Only after tapping an island (focus card chips); the map at rest shows no laws; the Heart's crown law (Kinship, `REALMS.heart.crownLaws`, screens_main.js:35) is shown nowhere | Partly; crown laws missing |
| Links | Bridges with type badges | Shown; a chute's direction (§5.3, "the owner sets the direction") is not |
| Strain band | "82% · Humming" pill | Shown (universe-level, as §5.5 says) |
| Faults | Code for a per-island badge and a "1 fault" chip; none in the demo | Not shown in the demo, and drawn per island rather than between two realms (§5.4) |
| Alerts | Raid banner, badges | Shown |
| Resources | Three bars with a storage underline and FULL | Shown, against invented caps |
| Heist button | The centre Heist tab | Shown (not skiff-shaped, not bottom-right — S1) |
| From elsewhere: nearest goal (§14.8, §23.1) | None | Missing |
| From elsewhere: screen reader reads the map realm by realm (§20.8) | Labels are buttons with names | Partly (no laws/strain in words) |

### 2.4 Deviations

| What | Design shows | Document says | § | In §23.5? |
|---|---|---|---|---|
| Home layout | See S1 | §21.8 Home layout | 21.8 | No |
| The Heart's school | "Spirit · Level 6" in the focus card; the Heart's icon, glow and beam are Spirit magenta (`REALMS.heart.school='Spirit'`, screens_main.js:35, realm_diorama.js:61) | The Heart is Neutral, with a circle | 5.2 | No |
| The Heart's level | "The Heart 6", "Level 6" (the Spire's level) | The Heart has no realm level of its own; the build counts it as realm level 3 (G19); 6 is the Spire | 5.2, 10.2 | No |
| Crown laws | Not shown on the map or in the Heart's card | A crown law works in every realm, at full strength; "Realms with their laws" | 5.1, 23.2 | No |
| Faults | Per island ("!" badge, "1 fault" chip) | Faults open *between* realms; a crew jumps through once; Strained one, Cracking two or three, Breaking four | 5.4, 5.5 | No |
| Storage caps | 200,000 / 80,000 / 65,000 (screens_main.js:168); "FULL 61.0k" | Starlight/Essence: Vault + Storehouses (Vault 6: 173,400 each); Aether: 29,000 at Spire 6 | 10.2 | Aether only |
| Home timer | "5h 12m" shield chip on Defence (markup 386) | No timers on the home screen; no shield exists past the first 72 hours (§12.3), and Wren is Keeper 24 | 18.8, 12.3 | No |
| Nearest goal | None | Home surfaces the goal closest to done, "N to go" | 14.8 | No |
| Raid banner text | "you lost nothing" always | True by default; in the Open Vault league the defender does lose (§9.4) | 9.4 | No |
| Sky | Fixed violet galaxy | The sky follows the player's local time (day, dusk, night gradients) | 21.2 | No |
| Camera | Perspective, 28° field, ~46° pitch (realm_diorama.js:512) | Orthographic, 35° pitch, 90° rotation steps, three zoom levels | 21.1 | No |
| Demo realm levels | Skyfield 4, Crystalline 5, Tidehold 4 at Spire 6 | Realm level 4 needs Spire 7, 5 needs Spire 9; Keeper 24 allows Spire 6 | 5.2, 10.2 | No (prototype data) |
| Text size, tap size, corners | Labels 12/9 px, label buttons 22–26 px tall, side buttons 44 | ≥ 13 pt; ≥ 48 pt; no corners | 21.1, 21.8 | Text only |
| Landscape | Not designed | Both | 23.3 | Yes |

### 2.5 Silent adoptions

The universe as a 2–3–2 column with the Heart in the middle and the locked realm greyed in mist; link type badges at the midpoint; ready-to-collect pills on labels; the two-step tap (focus, then enter) with the focus card; Collect all per realm and for the whole universe (collecting is already the player's to do, §9.3; this is how, not what); the raid skiff animation and the raid banner with TRACE (§12.3, §13.2's "the haul denied"); the dive into a realm; the Heart's beam, dome and rings; hanging crystals in each realm's school colour; waterfalls under each island (§21.1 asks for them).

### 2.6 What the build has today

- `client/scripts/home.gd` — a list of nine destinations, the Keeper bar in words, a Play button (lines 9–43). No map.
- `client/scripts/universe_screen.gd` + `features/universe/*` + `data/repositories/universe_repository.gd` — the server's universe as a list of realms with buildings, their next levels and prices, "room" to build, the next realm to open; two-tap purchases (`_tap`, lines 116–128) with the reason a purchase is blocked in words (`universe_presenter.gd:238–252`). This flow is the right data layer for the realm view's build tray and the focus card, and it is tested (`tests/universe_tests.gd`).
- Server: `GET /v1/universe` (server/src/http.mjs:22; `Universe.view`, server/src/universe.mjs) returns `{keeper, spire, starlight, realms:[{realm, type, level, buildings:[{kind, n, level, top, next}], room, raise}], open}`. It has no laws, links, stability, strain, faults, production, Aether or storage caps. `GET /v1/keeper` (Keeper bar) and `GET /v1/league` (Renown) exist.
- Nothing 3D exists in the client: `client/scripts/realm_view.gd` draws a heist flat and top-down from the simulation; the README calls the diorama "the art pass". The renderer is `gl_compatibility` (project.godot).
- The sim has no links or faults; multi-realm universes are "Not yet" (tools/roadmap.py:875).

### 2.7 Server needs

1. `GET /v1/universe` to carry, per realm, the woven laws (realm laws from the published island, crown laws from the Heart), and for the universe: stability capacity (Spire + Anchor Stones, §5.5), the woven cost, strain %, band, open faults as realm pairs, links (type, ends, chute direction), per-realm ready production, storage caps (§10.2), Aether.
2. Production on the server (§9.3's formula; G42's "workers, production" slice): stored amounts per building, capped at 12 hours.
3. `POST /v1/universe/collect` `{realm?}` → amounts added, capped at storage.
4. Links: build/remove/turn (`POST /v1/universe/links {a, b, type}`, `PUT …/direction`), at §5.3's prices and limits (Heart 4 sockets, outer 3; one per outer realm plus two; chutes 2; rift 1 at 20 Aether an hour).
5. `GET /v1/defences?since=` → raids on the player (raider, realm, outcome, haul denied, Trace open until), for the banner and the defence badge.
6. Aether in the ledger and in `GET /v1/balance`.

### 2.8 The plan (Godot 4.7)

1. **World**: `scenes/world/diorama.tscn` + `scripts/world/diorama.gd`, owned by the shell. One `Camera3D` with `projection = PROJECTION_ORTHOGONAL` at a 35° pitch (§21.1), rotation in 90° steps, three zoom sizes (universe, realm, close-up). The prototype's narrow-angle perspective looks almost the same; the document wins.
2. **Islands**: `scripts/world/island_builder.gd` ports `makeIsland` (realm_diorama.js:945): the noisy rim (`EF`), the layered dirt/rock cylinders, the inverted rock cone, hanging cones, roots and waterfalls — generated in code, which is also §21.11's licensing position. Palette per realm from §21.4/§5.7 in a `content/` table, not from the prototype's colours where they differ. Two options for buildings and creatures: (a) port the three.js builders to GDScript `SurfaceTool` meshes; (b) export the prototype's meshes once to glTF with three.js r184's GLTFExporter (MIT, allowed by §21.11) and import them, overriding materials with the toon shader. (b) keeps the owner's models exactly and is far cheaper; it needs GLTFExporter from npm and a headless browser, both available here.
3. **Look**: one toon `ShaderMaterial` (three-step ramp, violet-tinted shadows, soft rim) and an inverted-hull outline as `next_pass` (cull front, grow 1.5 px), both fine on the compatibility renderer; `CPUParticles3D` for motes, waterfalls and crystals (cheaper and safer than GPU particles there); sky as a gradient `ShaderMaterial` on a background quad that follows the player's local time (§21.2), tinted per realm only inside the realm view. Budgets of §21.3 (≤ 150 draw calls; merge each island's static meshes).
4. **Labels**: 2D `Control`s in the shell's overlay, placed each frame from `Camera3D.unproject_position`, so text stays crisp, meets 13 pt, and is reachable by the screen reader; each label's hit rect is 48 pt. Picking on the world: a ray from the camera against one `StaticBody3D` per island.
5. **Presenter**: `UniversePresenter.map(slices)` beside the existing `screen()` → per realm: name, type and shape (the Heart's circle), level (the Heart says "Spire 6"), woven laws (realm and crown, each with its school shape and name), ready amounts, faults (by pair), locked state with its Keeper level; links with type and chute direction; strain and band; the nearest goal. Spoken form per realm for §20.8.
6. **Interactions**: tap label/island → `FocusCard` (laws, faults, ready, Collect all, Enter realm); second tap → dive (a cut under reduced motion) and `router.go(&"realm", {realm})`; tap locked → toast; strain pill → Weaving; Heist tab → Observatory; COLLECT → `UniverseController.collect()` with rewards flying into the bars; raid banner → Trace or dismiss.
7. **Faults**: drawn as a glowing crack between the two realms of each open fault (and a badge on both labels), once the server says which pairs (finding M).
8. **Tests**: presenter tests (laws including crown, faults, caps, the Heart's level wording, nearest goal), a flow test (tap → card → enter → realm route), the layout check on the HUD, a still from `tests/screenshot.gd` for review.

Effort: XL (the diorama and the server data together). It depends on the shell, on production and links on the server, and on the engine move.

---

## 3. Realm view

### 3.1 The §23.2 row

| Screen | Its job | Must show |
|---|---|---|
| Realm view | Build and shape one realm. | Grid, terrain and budget, buildings, workers, pylons, wards, guard posts |

§23.5 rows that touch it: "Realm view strain — Steady 62% while home reads Humming 82% → strain belongs to the universe (5.5)"; "Realm view — workers, pylons, wards and guard posts look alike → each can be told apart (23.2)"; "Aether storage"; "Crown slots" (Weaving); "Text size"; "Landscape".

### 3.2 What the design shows

- The diorama in realm mode (markup 471): one island filling the screen, its sky the realm's own gradient, buildings at their levels with roofs in the realm's colours, paths drawn between them, small creatures walking to and from producers, collect bubbles over full producers ("Full! Tap to collect", realm_diorama.js `bubble`), a waterfall off the rim.
- Header (474–480): a 62 px realm medallion with a level badge ("6" for the Heart) and the realm name with a caret that opens a realm picker (508: "YOUR REALMS · Tap to travel", one row per realm with "Motion · 2/2 laws · you are here" and "LV 4").
- Top-right: three compact resource capsules (481–485).
- A "LAWS 1/2 · Steady · 62%" pill (487); open (488–496), a vertical panel of three slot buttons — filled (school medallion and short name, opens the law card), "+" Weave, or "Locked" — and a vertical stability meter with "62% STABILITY" (the realm's own strain, `rsW = 32 + 2 × Σ law cost`, screens_main.js:338).
- From the law card, "See it in action" plays a lens (497–503): a creature acts the law out in the realm for 12 s ("IN THIS REALM … Watch: …").
- Left/right edge arrows to the previous/next realm (486).
- Bottom: MAP (80 px, bottom-left corner), WEAVE (64 px, "1 free"), BUILD (84 px gold, bottom-right corner); a centre "Collect 645 · 4 buildings" button when anything is ready (509).
- Tap a building: a banner with its name, level and storage bar, and a row of round actions — INFO, WORKERS "1/2", UPGRADE (price, or seconds left), COLLECT (amount), MOVE (517–528; screens_main.js:146–155). INFO opens a sheet (529–548): stored amount, worker dots with − / +, "Upgrading to Lv N" with a countdown bar, and Move / Collect / Upgrade.
- Hold a building 420 ms to lift and drag it; MOVE does the same; a placement sheet says "Drag it to a free tile, then confirm" or "That spot is taken" with Cancel / Place (566–575). The tile grid appears only while placing or moving (realm_diorama.js:1057, grid opacity 0 otherwise).
- BUILD opens a tray (549–565) with three kinds — Build, Terrain, Defence — and sub-tabs:
  - Build › Economy: Star Well 1,200 "3 / 4", Aether Loom 900 "2 / 3", Essence Garden 800 "2 / 4"; Homes: Hearth 600 "Houses 2 workers" "5 / 8", Storehouse 2,400 "Protects loot from raids" "1 / 2"; Arcane: Ward 400 "Rune circle that raises the alarm" "4 / 8", Pylon 1,800 "Links wards; guards hear alarms" "Lv 7". Meter "Workers 9 idle".
  - Terrain › Water: Pond "Swimmers ignore; slows raiders" 4 pts, Stream 6 pts; Height: Hill "Blocks sight lines" 5 pts, Cliff "A wall raiders must climb" 8 pts; Growth: Hedge "Cover you can hide behind" 3 pts, Grove "Tall trees; hides wards" 4 pts. Meter "54 / 80 points".
  - Defence › Posts: Scout post 1,500 "Fast guard; sees far", Warden post 1,800 "Tough guard; holds chokepoints", Breaker post 2,100 "Hits hard; breaks crew shields"; Wards: Rune circle 400 "Alarms when crossed", Grate 600 "Traps a crew member for 3 s", Lantern 500 "Lights up hiding spots". Meter "Guards 4 / 6".
- Gestures: pinch to zoom, twist to rotate (in 90° steps), drag to pan (realm_diorama.js pointer handlers; `rotate`, `zoomIn/Out` at :1393–1396). The logic for rotate and zoom buttons exists (screens_main.js:185) but no markup binds it.

### 3.3 Against the must-show list

| Must show | In the design | Verdict |
|---|---|---|
| Grid | A round island; a circular set of tiles drawn only while placing or moving | Partly; not the §5.2 square grid |
| Terrain and budget | Terrain on the island; budget only inside the Terrain tray ("54 / 80") | Partly; the tray's features and costs are not §6.2's |
| Buildings | Yes | Shown, with invented kinds/counts (below) |
| Workers | Walking creatures; worker dots in INFO | Shown; look like guards and others (§23.5 lists this) |
| Pylons | No law pylon exists in the diorama (no pylon code in realm_diorama.js); the tray's "Pylon" is a spire-shaped building with an invented effect | Missing |
| Wards | Ward props; the tray's three ward types | Shown, but not §10.3's wards |
| Guard posts | Typed posts | Shown, but typed by the post, not by the ruleborn |

### 3.4 Deviations

| What | Design shows | Document says | § | In §23.5? |
|---|---|---|---|---|
| Realm strain | "Steady · 62%" per realm | Strain belongs to the universe | 5.5 | Yes |
| Look-alike objects | Workers, pylons, wards, posts alike | Each can be told apart | 23.2 | Yes |
| Law pylons | Absent; laws live only in the LAWS panel | One Law Pylon per law slot, an obelisk topped with the school's shape, pulsing; "law pylons with their zones; law chips float over the pylons" | 10.2, 21.5, 23.1 | No (only "look alike") |
| "Pylon" building | "Links wards; guards hear alarms", 1,800, spire glyph | No such building or effect; alarms spreading is Whispers' (a law) | 10.2, 7.4 | No — adds a mechanic |
| Build timers | Upgrades take 10 s + 1.5 s × level, at most two at once (realm_diorama.js:1291), with a countdown | "There are no build timers: building and upgrading are instant" | 10 | No — adds a mechanic |
| Upgrade price | 800 × level (screens_main.js:148) | §10.2's table per building | 10.2 | No |
| Producers per realm | Two Star Wells in the Heart (realm_diorama.js:88), three Wells and three Gardens in outer realms (:89), "3 / 4" etc. in the tray | One Star Well, one Aether Spring, one Garden per realm | 5.8 | No |
| Worker slots | Two for every producer at every level (realm_diorama.js:1275, 1289) | 1 at levels 1–3, 2 at 4–6, 3 at 7–10 | 10.1 | No |
| Storehouse | "Protects loot from raids", offered in the Heart, "1 / 2" | Outer realms, one each, fully exposed | 9.4, 10.2 | No — the opposite of the rule |
| Hearth | "Houses 2 workers", "5 / 8" | One per realm; homes 3 at level 1, rest faster | 10.2 | No |
| Guard posts | Scout/Warden/Breaker posts at different prices; "breaks crew shields" | One Guardian Post kind; one ruleborn stands at each, and its role is the guard's; 1/1/2/3/3 by realm level (the Heart as level 3: 2) | 10.2, 9.2, 5.2 | No — adds mechanics |
| Wards | Rune circle (alarm when crossed), Grate (traps 3 s), Lantern (lights hiding spots), 400/600/500 | Six wards: Gravity Well, Crystal Wall, Time Snare, Static Coil, Thorn Hedge, Lantern Glare; 350 at level 1 | 10.3, 10.2 | No — adds mechanics |
| Terrain tray | Pond "swimmers ignore; slows raiders" 4 pts; Stream 6; Hill 5; Cliff "a wall raiders must climb" 8; Hedge 3 "cover"; Grove 4 "hides wards"; "54 / 80" | Pond: deep, only swimmers cross, 2 a tile, Tidehold and Verdant only, Keeper 3; Stream 1 a tile, wading 20% slower; no Hill or Grove (Raised ground, Tree); Cliff edge free, made by height, blocks climbing; Hedge 1 a tile, blocks, cut in 3 s, blocks sight; budgets 45–105 outer, 40 + 10 × Spire in the Heart | 6.1, 6.2 | No |
| Grid shape | Round island, circular tile mask (realm_diorama.js:92) | 10 × 10 to 14 × 14 square grids; the sim's islands are square (`client/ext/src/island.rs` `side()`) | 5.2, 21.1 | No |
| Building names | Aether Loom, Essence Garden, Guard Post, Spire | Aether Spring, Garden, Guardian Post, Keeper's Spire | 10.2 | No |
| Heart's slots | A third "Locked" slot on the Heart | The Heart has 2 realm slots, always | 5.1 | No |
| Crown laws in a realm | Not shown | A crown law applies in every realm at full strength | 5.1 | No |
| One finger | Rotate and zoom only by pinch and twist | No action needs more than one finger | 20.8 | No |
| Corners and home bar | MAP and BUILD in the bottom corners, 26–28 px above the edge | No corners; 44 pt clear of the home bar | 21.1 | No |
| Tap sizes | Edge arrows 36 × 56, laws pill 34, slots 44, lens × and i 30, worker − + 34, tray close 36, tray tabs 30–32 | ≥ 48 pt | 21.1 | No |
| Text sizes | Slot labels 7.5 px, STABILITY 7.5, plates 10, tray counts 10 | ≥ 13 pt | 21.8 | Yes |
| Producer storage | 320 / 140 / 240 a building | 12 hours of output (a level-1 Star Well holds 960) | 9.3 | No (prototype data) |
| Landscape | Not designed | Both | 23.3 | Yes |

### 3.5 Silent adoptions

The realm medallion and picker; edge arrows between realms; the LAWS pill opening a vertical slot strip (fed by the universe's band, not a realm strain); the law lens that acts a woven law out inside the realm (a visual demonstration, it changes nothing); collect bubbles and a realm Collect button; the building banner with round actions (Info, Workers, Upgrade, Collect, Move — Upgrade instant); paths drawn between buildings; the three-kind tray (Build / Terrain / Defence) as a shape, filled from §6.2, §10.2 and §10.3; the placement sheet with Cancel / Place and a red "spot taken" message; hold-to-lift as a shortcut beside MOVE (hold time adjustable, §20.8); WEAVE's "1 free" badge.

### 3.6 What the build has today

- No realm view. The builder (`client/scenes/builder.tscn`, `scripts/builder_screen.gd`) edits an island through `RulebornIsland` (`client/ext/src/island.rs`: `reset(level)`, `side()`, `ground/set_ground`, `occupant`, `place_ward`, `post_guard`, `weave`, `set_vault`, `laws`, `budget`, `problems`, `combos`) — ground on the grid, posts, wards, woven laws with their pylons, the Vault — and checks the island with `Island::check`. Only eight of §6.2's features are offered (those the sim models). It draws with the heist's flat view.
- The universe screen buys and raises buildings per realm (section 2.6). The two do not meet: the economy's buildings (`server/src/universe.mjs`, rows of `{realm, kind, n, level}`) have no positions, and the island (`sim/src/island.rs:94–110`: realm level, Vault level and one-tile position, entrance, tiles, guards, wards, laws) has no economy buildings. §10.1 says buildings sit on the grid (2 × 2; the Spire and Vault 3 × 3) and block movement and sight.
- No roster on the server (workers), no production, no weaving state (timers, resting slots) on the server.

### 3.7 Server needs

1. Building positions: either the island format grows a building list `(kind, n, x, y)` with §10.1's footprints, which the sim treats as blocking movement and sight (sim + server + extension), or the server keeps positions and writes them into the island on publish. The first keeps one source and makes heists honour §10.1.
2. `POST /v1/universe/buildings/:realm/:kind/:n/move {x, y}` (free and instant, §10.1), and placement on build.
3. Upgrades stay instant (`POST /v1/universe/buildings` already is).
4. Workers: the roster (§11.5) and `PUT …/workers {characters}` within §10.1's slots; staffing feeds production (§5.8, §9.3).
5. Production and collect per building and per realm (as 2.7).
6. Weaving state per slot (weaving until, resting until; §5.6) and crown laws, for the LAWS strip.
7. The player's own island per realm: `GET /v1/islands` → `{realm: bundle hash}` (only `PUT /v1/islands/:realm` and `GET /v1/bundles/:hash` exist today).

### 3.8 The plan (Godot 4.7)

1. **Same diorama, realm mode**: the island's organic rim from section 2.8, with §5.2's square grid laid inside it (a 14 × 14 grid needs an island radius of at least about 10 tiles; the prototype's island radius is 12.7). The grid drawn faintly always (must-show) and strongly in edit modes.
2. **One model of the realm**: `RealmState` holds the island bytes (from the local draft, `data/draft.gd`, or the published bundle) and the universe's buildings for that realm; `RealmPresenter.view(slices)` → header (name, shape, realm level or "Spire N" for the Heart), slots (realm laws and crown laws in effect, open, weaving with time left, resting, locked only where a level can unlock it), the universe band (never a realm strain), terrain points used/available (`RulebornIsland.budget()`), ready totals, and per object: kind, level, footprint, state, spoken description.
3. **Objects told apart** (§23.5): workers carry their producer's tool and walk; Guardian Posts are platforms with a lantern and the posted ruleborn in sash and lantern with its role accessory (§21.6); wards are their §10.3 props with the school shape; Law Pylons are obelisks with the school's shape on top, a zone ring, and a law chip floating over each (§23.1) that opens the law card or the lens.
4. **Trays from content, not the prototype**: Build lists only kinds §10.2 allows in this realm, with the count from the server's `room` (`universe_presenter.gd:220`) and §10.2's price and needs; Terrain opens the Terrain editor or lists §6.2's features from `content/terrain.json` with their points; Defence lists the realm's Guardian Posts (assign a ruleborn) and §10.3's six wards up to §5.2's limit. Every edit goes through `RulebornIsland` (the builder's path), so what the realm view shows is what is published and raided; the builder becomes this screen's edit mode instead of a separate screen.
5. **Interactions**: tap → banner with round actions; Upgrade is instant at §10.2's price through `UniverseController.build`; Move is two taps (MOVE, then a tile) with drag as a shortcut; rotate and zoom buttons beside the gestures (§20.8); previous/next realm and the picker; MAP returns with the reverse dive.
6. **Placement rules**: MAP/WEAVE/BUILD moved off the corners and above the home-bar inset, hit rects ≥ 48 pt, text ≥ 13 pt.
7. **Tests**: presenter (counts from `room`, prices from content, no timers, Heart wording, crown laws), island round-trip with buildings once the format has them, the layout check, a still.

Effort: XL. It depends on the shell and the diorama, on building positions (sim + server), on production and the roster.

---

## 4. Findings for the register

Each is not already in §23.5's table. Severity is mine; the owner decides.

A. **The realm view's build tray and diorama add mechanics and break five rules** (significant, deviation). Several producers of a kind per realm (§5.8), a Storehouse that "protects loot" offered in the Heart (§9.4, §10.2: outer realms, fully exposed), worker slots fixed at two (§10.1: 1/2/3 by level), typed guard posts with their own stats and "breaks crew shields" (§10.2: one ruleborn stands at each), three invented wards (§10.3's six), and a "Pylon" that links wards so guards hear alarms (no such building; Whispers is a law). Evidence: `screens_main.js:156`, `realm_diorama.js:78–89, 1275, 1289`. Rec: build the trays from §6.2/§10.2/§10.3 data; record in §23.5 as "Where the screens differ".

B. **Build timers** (significant, deviation): `startUpgrade` gives 10 s + 1.5 s × level and two builders at once (`realm_diorama.js:1291`; markup 541 "Upgrading to Lv N"), against §10's "There are no build timers: building and upgrading are instant". Rec: instant upgrades; add the row to §23.5.

C. **The realm view's terrain tray contradicts §6.1–6.2** (significant): Pond, Stream, Cliff and Hedge with other effects and prices, Hill and Grove that are not features, and a budget (80) no realm has. Rec: the tray (or the Terrain editor it opens) reads `content/terrain.json`.

D. **No law pylons in the realm view** (significant, must-show missing). §23.2 must-show "pylons"; §10.2 one per law slot; §23.1 "law pylons with their zones; law chips float over the pylons". The diorama has no pylon object; §23.5 records only that pylons "look alike". Rec: add pylons (obelisk + school shape + zone) and the floating chips; correct §23.5's row.

E. **Round island against §5.2's square grids** (significant, deviation): `realm_diorama.js:92` builds a circular tile set; §5.2's grids are 10 × 10 to 14 × 14 and the sim's islands are square. Rec: keep the round rock, draw the square grid inside it, show the grid always (faint) and in edit modes.

F. **The Heart drawn as a Spirit realm, its "level" the Spire's, and crown laws invisible** (significant): `screens_main.js:35`, `realm_diorama.js:61`, focus card "Spirit · Level 6 · 1 of 2 law slots"; §5.2 (Neutral, circle), §5.1 (crown laws everywhere), §23.2 "Realms with their laws". Also a third "Locked" slot on the Heart (§5.1: always 2). Rec: Neutral circle; "Spire 6"; crown laws on the Heart and as a band on every realm's laws.

G. **A timer and a shield on the home screen** (significant): the Defence button's "5h 12m" shield chip (markup 386) against §18.8's "no timers on the home screen" and a shield the document does not have past §12.3's first 72 hours (Wren is Keeper 24; §22.1 lists shields among things never sold). Rec: no timer on home; show §12.3's protection only while it lasts, in words, on the defence screen.

H. **§21.8's home layout, §23.1's "five tabs at the foot" and §23.5's "designs carry the layout" do not agree** (significant, contradiction). §21.8 states placements as a rule (resources top-left, Keeper/Renown top-right, stability top-centre, build/weave/terrain bottom-left, skiff Heist button bottom-right, alerts down the left); §23.1 describes the home with five tabs at the foot; §23.5 gives the designs "layout" while saying the document wins where it states a rule. The design follows neither §21.8 nor fully §23.1. Rec: owner decides; recommended to rewrite §21.8's Home layout row to the design's arrangement and keep §21.1's measurable rules (thumb zone, corners, safe area, sizes) as the rule.

I. **§21.1's placement rules against the design's chrome, and the client's check stricter than §21.1** (significant). The tab bar's outer tabs sit in the bottom corners and inside the home-bar inset; the back button is top-left on every sub-screen; hub tabs, side buttons, strain pill and labels are under 48 pt; MAP and BUILD are in the corners. `client/tests/run.gd:577–600 (the top-third rule at line 593)` fails every fixed button in the top third, though §21.1 says "every frequently used control". Rec: hit rects ≥ 48 pt everywhere; tabs inside the middle 70% and above the inset; the back control moved into the lower band; the check split into frequent and infrequent controls; record the outcome in §23.5.

J. **Rotate and zoom need two fingers in the realm view** (significant, §20.8 "No action needs more than one finger"). The buttons' logic exists (`screens_main.js:185`) with nothing in the markup. Rec: rotate and zoom buttons in the realm view (and the heist's pinch, if the heist agent has not covered it).

K. **Typefaces** (minor, deviation): Manrope and Lilita One for labels, numbers and titles; §21.8 names Baloo 2 and Marcellus and §21.11's licence ledger starts with them. Rec: Baloo 2 and Marcellus, or amend §21.8 and §21.11 if the owner prefers the design's faces (all four are OFL).

L. **No nearest goal on the home screen** (significant, must-show from §14.8 and §23.1). Rec: a goal chip in the thumb zone, "N to go", never in the shop and never for money.

M. **Faults have no home in the build and the document does not say where they open** (minor, gap). §5.4/§5.5 give counts per band (one, two or three, four) and say faults open between realms, but not which pairs or how they are chosen; the design draws a per-island badge; the sim has no faults or links (multi-realm universes are "Not yet", `tools/roadmap.py:875`). Rec: §5.5 to say how a fault's pair is chosen (e.g. between the most strained realm and its nearest unlinked neighbour, deterministic from the universe), and the home draws it between the two.

N. **Buildings are not on the grid anywhere** (significant, build gap). §10.1: buildings sit on the grid (2 × 2, the Spire and Vault 3 × 3) and block movement and sight. The island the sim reads carries a one-tile Vault, posts, wards and pylons only (`sim/src/island.rs:94–110`); the server's buildings have no positions (`server/src/universe.mjs`). So heists ignore buildings and the realm view cannot place them. Rec: buildings with footprints in the island format and the sim; positions on the server; the publish check holds the island's buildings to those built (as `universe.mjs` already does for realm, realm level and Vault).

O. **Sky and camera** (minor, deviation): fixed skies (galaxy on the map, one gradient per realm) against §21.2's local-time sky; a narrow perspective camera against §21.1's orthographic 35° view. Rec: follow §21.2 and §21.1; per-realm tints inside the realm.

P. **Engine pin** (minor, deviation; may be reported by others): `client/project.godot:12` is Godot 4.5 and `client/ext/Cargo.toml:11` builds `api-4-5`; v3.6 §24 pins 4.7.2-stable with `api-4-7`. Rec: move before the shell and diorama are written.

Q. **Building names and the prototype's numbers** (minor): "Aether Loom", "Essence Garden", "Guard Post", "Spire" against §10.2's names; storage caps 200,000/80,000/65,000; realm levels 4–5 at Spire 6; buildings above the Spire's level (a Star Well at 7 and the diorama's own Spire at 7, `realm_diorama.js:88`, while the HUD says Spire 6 — §10.1: no building above the Spire's level); producer caps 320/140/240; upgrade price 800 × level. The prototype's module is not a source (§23.5) and the client already reads `content/buildings.json` through the server; listed so nobody copies them.

---

## 5. Order of work

1. Engine to 4.7.2 / `api-4-7` (P).
2. The shell: persistent scene, router metadata, HUD/badge/goal presenters, components, tokens, fonts, icons, the split layout check (I, K, L). Effort L.
3. Server: Aether and caps; production and collect; universe view with laws, stability, strain, faults, links; raids-on-you list (2.7). Part of G42's remaining slices.
4. The diorama: camera, island builder, toon look, labels, picking — first in universe mode (section 2.8). XL with 3.
5. Buildings on the grid (N), then the realm view (section 3.8) with pylons (D), trays from content (A, C), instant upgrades (B), one-finger controls (J). XL.
6. Landscape for both and the shell (§23.3).

## 6. Questions only the owner can answer

1. H: rewrite §21.8's home layout to the design's arrangement, or move the design to §21.8's?
2. I: where the back control goes (lower band, or top with a swipe-back gesture), and whether the layout check should distinguish frequent controls.
3. K: Baloo 2/Marcellus (as written) or Manrope/Lilita One (amend §21.8 and §21.11)?
4. M: how a fault's pair of realms is chosen.
5. N: buildings in the island format (one source, honoured by heists) or positions on the server only.
6. The asset route: port the prototype's mesh builders to GDScript, or export them once to glTF from the prototype and re-material them in Godot.

## 7. Captures I made

In `scratchpad/analysis/hrs/shots4/` (live renders of the prototype at 390 × 844, React served locally; script `scratchpad/analysis/scripts/states.mjs`): `home_a.png` (home with the raid banner), `home_menu.png`, `home_menu_bottom.png` (the menu sheet), `home_focus_skyfield.png` ("Motion · Level 4 · 2 of 2 law slots", Half gravity and Bounce, Ready ✦560), `home_focus_heart.png` ("Spirit · Level 6 · 1 of 2 law slots", Stillness only — no crown law), `home_locked.png`, `realm_a.png`, `realm_laws_open.png` (Stillness, + Weave, a Locked third slot, 62% stability), `realm_lawcard.png`, `realm_tray_build.png` (Star Well 1,200 "3 / 4", Aether Loom 900 "2 / 3", Essence Garden 800 "2 / 4", "Workers 9 idle"), `realm_tray_terrain.png`, `realm_tray_defence.png` (Scout/Warden/Breaker posts, "Guards 4 / 6"), `realm_picker.png`, `realm_selected.png` (a Star Well at "Lv 7" in a universe whose Spire is 6, "WORKERS 1/2" where §10.1 gives a level-7 producer three slots, upgrade "5.6k" = 800 × 7, collect 320 / 320). States after those (the INFO sheet, the next realm, a selected guard post) were still rendering when this report was written; their descriptions above come from the markup and logic, cited by line.
