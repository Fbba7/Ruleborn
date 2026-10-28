# Review of the next wave's UI plan (T16)

T16 read `report.md` as a sceptical reviewer who must run its plan tomorrow, checked it against the design document (`docs/design/ruleborn-game-design-v3.7.txt`), `docs/art/3d-program.md` and the stopped tracks' notes in `docs/art/tracks/`, and fixed it. This log lists every inconsistency and gap found, where it was, and how it was resolved.

**Marks.** **OWNER** means the owner must decide; the report's section 12 has the options and the default. **T15/INT** means another document or file must change, which T16 may not edit; the exact change is in the last section, for T15 or the integrator.

## Summary

- 62 findings in two rounds. The first round (R1–R46): 13 inconsistencies in numbers or references, 21 missing parts of the plan, 12 places where the plan broke or bent a rule of the design document or the repository. The second round, on the owner's request to specify the kit and test building against buying (R47–R62, section 5).
- All are resolved in `report.md`, `kit-spec.md` and `build-or-buy.md`. Twelve decisions need the owner (D1–D12). Outside T16's files: X1–X3 are done by the integrator; X4, X8 and X12 are needed now; X5–X7 and X11 only if the owner chooses them.
- **The two that change the picture most:**
  - **The plan costs 158 agent-hours, not "about 80".** T14's steps summed to 81 and left the screens uncosted (R14, 144 hours); the full kit adds 14 (R60).
  - **The ceilings were shares of Clash level, labelled "of the bar".** The plan reaches 3.75–4.25 out of 5: 75–85% of Clash level, 54–61% of the owner's bar, not 75–85% of the bar (R5).

## Measured by T16 on this container

| What | Result |
|---|---|
| `bake_hud.js` rebake | 23 s for 75 pieces twice; the atlas and manifest byte-identical to the committed ones |
| `bake_icons.js` rebake | 10 s for five icons; all five byte-identical |
| The proof's heist frame (`uiq_heist_hud.gd`, same settings as section 8) | 147 draw calls and 87,102 primitives with the new HUD; 136 draw calls and 96,333 primitives with the deployed HUD (T14 wrote 137) |
| One shot, warm | about 47 s (5 minutes cold, with the build and import) |
| Pinned tools | three.js 0.184.0 pinned in `tools/ui_research/package.json`; Playwright not pinned (the container has 1.63.0, Chromium build 1243); Node 22.22; Pillow 12.3.0 |

## 1. Inconsistencies in numbers and references

| # | Where | Found | Resolved |
|---|---|---|---|
| R1 | Section 1, and section 5.1's "Overall" | The overall score is 2.2 in one sentence and 2.1 in the next: one is the plain mean, the other the weighted one, and the text does not say which is the headline | The plain mean, 2.2, is the headline everywhere. The weighted mean is given once as 2.08. |
| R2 | Section 1, section 5.1 | "2.1, or 41%". The weighted mean is 2.075, which is 41.5% | 2.08, 41.5% |
| R3 | Section 1 | "Those six score lowest". They do not: character presence (1.9) and press feedback (2.0) score below material (2.1) and icons (2.1) | "Four of them are among the five lowest scores of the fourteen" |
| R4 | Section 1, section 5.1 | "About 30% of the bar" is asserted, never derived | Derived: three times v3 (2.36) is about 7 on the Clash-is-5 scale; 2.2 / 7 = 31%. "The bar is 7" is stated once and used for every share of the bar. |
| R5 | Section 6's ceiling column, section 9.4 | Ceilings are labelled "of the bar" but are shares of Clash level. Proof: today is 44% of Clash and 30% of the bar; B's "45–55%" from shaders alone, and the gate's threshold of 3.5, only make sense as shares of Clash. Read literally, "75–85% of the bar" is 5.3–6.0 out of 5, above Clash, which section 9.4 itself says the AI artist cannot reach | Every ceiling given as a score out of 5, a share of Clash level and a share of the bar: A + D 3.75–4.25 (75–85%, 54–61%); A alone 3.5–4.0 (70–80%, 50–57%); B 2.25–2.75 (45–55%, 32–39%) |
| R6 | Section 1 | "A perfect port of v3 lands near 48% of Clash level." v3's mean is 2.36, 47% | 47% of Clash level, 34% of the bar |
| R7 | Section 5.2 | "A perfect port would gain about 0.2." 2.36 − 2.21 = 0.15 | About 0.15 |
| R8 | Section 3 | The steps sum to 81 hours; the text says "about 80" without showing the sum | Section 3.7 shows the sum and the new total |
| R9 | Section 6, row C | "About 10 to set up, then about 1 hour a review round"; section 3 gives AD "about 8 agent-hours over the wave". The two cannot both hold | AD: 6 to set up and 14 of reviews, 20 in all, counted review by review (section 3.2) |
| R10 | Section 6, row D | "About 60 of A's 80 hours are its work" | The AI artists' work is 64 of 144 (AIA 36, AIA-2 28); after the kit spec, 70 of 158 (AIA 42, AIA-2 28; R60) |
| R11 | Sections 3 and 9.1 | Section 3's style board lists four materials (enamel, gold, wood, glass); section 9.1 lists five (with parchment) | Five, in both |
| R12 | Section 7 | 137 draw calls for the deployed HUD; T16 measured 136 on the same frame. T9's notes give 141 for the heist on another shot script (`ui_screen.gd`) | Noted in section 7. Section 10.1 sets one method for every screen. |
| R13 | Section 9.4, item 2 | "Blocks anything below 3.5 on qualities 1–3", which cannot apply to icons (no type) or motion (none of 1–3 apply) | Thresholds per asset class (section 3.5) |

## 2. Gaps in the plan

| # | Where | Found | Resolved |
|---|---|---|---|
| R14 | Section 3, step 7 | The screen tracks are not costed. The "80 agent-hours" covers art and pipeline only | Costed: S1 14, S2 8, S3 14 (36). Total 144 (158 after the kit spec, R60), plus up to 20 of re-work. **OWNER: D1** |
| R15 | Section 3 | K1 is "an engineering track" with no agent; the screen tracks have no agents. Every interface track has stopped | Seven named agents with branches (section 3.1) |
| R16 | Section 3 | AIA's 61 hours run in series and would take about five days alone | Icons split to a second artist, AIA-2, on the same studio; consistency is enforced by the one studio, palette and outline rule. AIA's critical path is 36 hours (42 after the kit spec, R60). |
| R17 | Section 3 | No inputs or outputs: no files or paths for any step | Each step lists what it reads and writes (section 3.2) |
| R18 | Section 3 | No file ownership for the new tracks; the bake output and the kit would collide in `client/ui/` | Ownership table (section 3.1): AIA owns `art/ui/` and `client/ui/art/` (written only by the bake); K1 owns the bake and the rest of `client/ui/`. **T15/INT: X1** |
| R19 | Section 3 | No dependencies or order beyond "in this order" and "in parallel" | Each step says what it waits for; section 3.3 is the day-by-day schedule |
| R20 | Section 3 | No schedule | Section 3.3: six days after G0, about 12 agent-hours a day for each agent |
| R21 | Section 3 | The owner's approvals are named (board and key frames) but not when, or what the owner sees | Four gates, G0–G3, with what the owner sees at each (section 3.4) |
| R22 | Section 3 | The gate says "qualities 1–3 at least 3.5" and nothing else; no thresholds for key frames, icons, motion or screens | A pass mark per asset class (section 3.5) |
| R23 | Section 3 | No wave target: when is the wave done? | Each of the five screens at 3.5 or more, with 1–3 at 3.5 or more (section 3.6). **OWNER: D10** |
| R24 | Section 3 | Nothing says what happens when a piece fails the gate | Two rounds, then the owner chooses among three options; a failed screen keeps its look (section 3.5) |
| R25 | Section 3 | No risks | Section 11 |
| R26 | Section 3 | AD is an agent scoring another agent's art; nothing checks AD | AD re-scores today's screens within 0.2 of section 5.1 at set-up; the owner calibrates AD at G2 (section 3.4) |
| R27 | Section 3, step 3 | "KitSkin looks backed by textures, so every screen inherits them." The menu screens (settings among them) draw through T10's own layer, `ScreenKit` and `ScreenBox`, not `KitSkin` (22 scripts), so they would not inherit anything | S3 routes `ScreenKit`'s materials through `KitSkin` (4 hours, step 10) |
| R28 | Section 3 | No migration: nothing says how screens move from the code-drawn kit to the texture-backed one without a broken in-between state | A switch per material family with the code-drawn box as fallback; switched on only when the family and its high-contrast twins pass; layouts move after (section 10.9) |
| R29 | Sections 7 and 8 | 200% text not done on the proof (T14's own note), and no step owns it | K1's step 4: frames sized from their words; checked at 200% for every screen (section 10.2) |
| R30 | Section 3 | No checks for the pipeline, and no run times | Section 10.8: a seconds-long hash check and client tests in check_all; a 3-minute full rebake and a 12-minute budget run before every push and merge. **OWNER: D9** |
| R31 | Section 3 | No versioning or regeneration of baked assets; Playwright not pinned | Section 10.7: pinned three.js and Playwright, versions in every manifest, byte-for-byte rebakes (verified on T14's bakes) |
| R32 | Section 3 | No texture-memory, atlas-size or install-size budget; the design document sets none | Section 10.1: 1024² atlases (2048² at most), 24 MiB resident, 8 MB installed, two icon sizes. **OWNER: D8** |
| R33 | Section 3 | Numerals: baked numerals hold only digits; nothing covers separators, the heist's "Left ?" (§21.8), or the two launch languages | Section 10.4: digits plus , . : / + − % × ? with a fixed advance; formatting from the client per language |
| R34 | Section 3 | School-colour variants as "extra bakes" would multiply memory by six | Baked once in neutral and tinted per school (section 10.5) |

## 3. Rules of the design document and the repository

| # | Rule | Found | Resolved |
|---|---|---|---|
| R35 | §23.5: "The designs carry the look: layout, art, motion, the models and the icons." | The plan said the key frames "replace v3 as the reference". That needs §23.5 changed | **OWNER: D2.** Default: key frames are targets that keep the designs' layouts and icon shapes. Proposed text in X5. |
| R36 | §21.8 Motion: "150 to 250 milliseconds, easing out ... without overshoot" | The rubric (qualities 4, 5, 7) asked for overshoot, 80–150 ms springs and 150–350 ms screen changes; the proof's press springs past its size within 0.4 s | The rubric now follows §21.8 (section 4.3); the curves are data. **OWNER: D3.** Proposed text in X6. |
| R37 | §21.8 Type: Manrope for labels and changing numbers (tabular figures); Lilita One for large numbers that do not change | The rubric asked for "one heavy display face for all numbers and headers"; the proof's labels are Lilita One and its loot count, which changes, is baked display numerals | Rubric aligned (section 4.3); default follows §21.8. **OWNER: D4.** Proposed text in X7. |
| R38 | §21.8 Type: outline at least 1.5 points or 12% of size | The rubric asked for 8–15% of cap height, which can be thinner | Rubric uses §21.8's rule |
| R39 | §21.8 and §21.1: 48-point hit areas, nothing under 13 points | The rubric asked for 44 points and 11 points | Rubric uses 48 and 13. Section 5.1's scores stand: the kit's tests already hold the screens to them. |
| R40 | §21.3: "Characters are not drawn in a physically based material; their portraits are rendered from the imported models in this look." | The Pip crew badge, the proof of the character route, was lit in three.js's physically based studio | Character, Sage and building icons go through Godot's toon portrait studio (3 hours added to icons). Noted in sections 9.2, 9.3 and 10.6. |
| R41 | §21.3: "one toon look for everything"; §21.8 Icons: "a three-stop gradient, a gloss and a soft drop shadow" | The proof's object icons are lit physically, with a hard ink drop | Soft drop, per §21.8. Whether objects may be lit physically is **OWNER: D5**; until then character and building icons go first. |
| R42 | §21.9: about 390 interface icons "as Screens v3 draws them" | The plan re-authors 60; the other 330 or so stay flat, so two styles would show side by side, with no plan for them | **OWNER: D6** (60 now and the rest later at about 140 hours; or a cheap harmonising pass; or all now) |
| R43 | §20.8 Comfort: reduced motion gives every animation a reduced form and keeps one particle, a reward landing in its counter; no more than three flashes a second | The plan's juice and idle shine had no reduced forms; glints and sparkles had no flash limit | A reduced form for each motion, shown at the gate (section 10.3) |
| R44 | §20.8 Seeing and Screen readers; §21.8 contrast and high contrast (opaque, 3-point outlines, no glass) | Nothing checked contrast over baked art, the high-contrast twin's rules, colour-blind simulation, or spoken names for pictures of numbers | Section 10.2 |
| R45 | §21.8 Sound and Haptics; §21.11 sound generated or public-domain | The rubric's qualities 4 and 5 ask for sound; the client has no sound at all, and no agent makes any | Motion fires named events for a later sound track and calls the existing haptics; 4 and 5 scored without sound. **OWNER: D7** |
| R46 | §21.11: fonts under the OFL, a ledger for every outside file | Baked numerals, the MSDF import of Lilita One, and the build tools (three.js, Playwright, Chromium) were not in any ledger; an image-generation tool (section 9.4) would bring in outside images | Section 10.6: the MSDF is an import setting on the unmodified font; numerals are pictures, recorded in a new ledger row; a tools ledger; image generation needs the owner's decision first |

## 4. Changes outside T16's files

T16 edits only `docs/art/ui-quality/**` and `docs/progress/T16.md`. These are for T15 (documentation) or the integrator.

**X1. `docs/art/3d-program.md`, the track table** (T15). Add after the T12 row:

| Track | Branch | Owns (new files allowed under these) | Delivers |
|---|---|---|---|
| AD Art director | `claude/ui-ad` | `docs/art/ui-quality/gate/**`, `tools/ui_gate/**` | The rubric, the reference sheet and a published score for every piece of interface art before it merges (`docs/art/ui-quality/report.md` section 3.5). Never authors. |
| AIA AI UI artist | `claude/ui-artist` | `art/ui/**` except `art/ui/icons/`, `client/ui/art/**` (written only by the bake) | The style board, five key frames, the kit art and the motion art, with high-contrast twins |
| AIA-2 AI UI artist, icons | `claude/ui-artist-icons` | `art/ui/icons/**`, `client/tests/shots/icon_*.gd` | The 60 most-seen icons, rendered and finished in 2D, characters through the toon portrait studio |
| K1 Bake pipeline and kit (takes over T9) | `claude/ui-bake` | `tools/ui_bake/**`, `tools/ui_research/**`, `client/prototypes/ui_quality/**`, `client/tests/shots/uiq_*.gd`, and T9's files except `client/ui/art/` | The bake, the texture-backed kit behind a switch per material family, and its checks |
| S1 Heist and result screens (takes over T5's screen files) | `claude/ui-screens-heist` | T5's `heist_screen.gd`, `heist_hud.gd`, `result_screen.gd`, `replay_screen.gd`, `client/world/fx_*.gd` | The heist and result on the new kit, with the reward sequence |
| S2 Home screen (takes over T4's home) | `claude/ui-screens-home` | `client/scripts/home.gd` | Home on the new kit |
| S3 Character and settings screens (takes over T7's character screen and T10) | `claude/ui-screens-meta` | `client/scripts/character_screen.gd`, T10's files | Character and settings on the new kit; `ScreenKit` routed through `KitSkin` |

**X2. `docs/art/3d-program.md`, "What done looks like"** (T15). After "Every still beats the matching design still ...", add: "From the UI wave on, interface stills are also scored by the art director on the 14-quality rubric (`docs/art/ui-quality/report.md` section 4), and a screen's target is its approved key frame where the owner has adopted one (section 12, D2)."

**X3. `client/export_presets.cfg`** (integrator). Both presets' `exclude_filter="tests/*"` becomes `exclude_filter="tests/*, prototypes/*"`, so T14's prototype art (about 1 MB) stops shipping in the pack before K1 deletes it.

**X4. `README.md`, the tools listing** (T15, when K1 lands). Add `ui_bake/` and `ui_gate/` beside `ui_research/`, and drop `ui_research/` once K1 retires it.

**X5. If the owner chooses D2 (a)** (the owner, through whoever edits the design document): in §23.5, after "The designs carry the look: layout, art, motion, the models and the icons.", add "Where the owner has approved a key frame for a screen (`docs/art/ui-quality/`), it carries that screen's look in place of the designs; this document's rules still win over both."

**X6. If the owner chooses D3 (a)**: in §21.8's Motion row, "150 to 250 milliseconds, easing out, for every interface movement: the designs' movements are kept and timed to it, without overshoot" becomes "150 to 250 milliseconds, easing out, for every interface movement: the designs' movements are kept and timed to it, without overshoot, except a button's release and a reward's reveal, which may overshoot and settle within 350 milliseconds".

**X7. If the owner chooses D4 (a)**: in §21.8's Type row, after "Marcellus for titles and law names.", add "Over baked art, labels may be Lilita One with an ink outline, and a number that changes may be drawn in baked numerals of fixed width." If the owner picks Titan One at the style board instead, the sentence names it, and the licence paragraph of §21.11 adds it beside the three typefaces.

**X8. For the integrator: the heist's primitives.** The proof's frame prints 87,102 primitives with the new HUD and 96,333 with the deployed one. §21.3 allows about 60,000 triangles in a heist. Most of this is the world, not the interface; whoever owns the world should measure the world alone.

**X9. Not changed, noted:** `docs/progress/T14.md` still says "about 80 agent-hours". It is T14's own file and records what T14 delivered; the plan's figure is now in `report.md`.

**X10. For whoever sets up the next agents' containers:** check_all needed three things this container lacked: Rust's `wasm32-unknown-unknown` target, `gdlint` (gdtoolkit 4), and Python's `playwright` at 1.63.0 to match the installed Chromium. T16 installed them locally; nothing in the repository changed. The UI wave's agents will need all three.

**X11. If the owner chooses D11 (a)** (the owner, through whoever edits the design document): in §21.11's table, after the "Sound, if any is not generated" row, add a row: "Particle and texture sprites | A public-domain dedication (CC0) only, as raw material: recoloured and baked through the game's own pipeline, and listed in the art ledger. Never a whole interface kit, an icon or a character."

**X12. `docs/art/3d-program.md`, the AD row** (T15 or the integrator). The kit spec gives AD one more file. The row becomes:

| Track | Branch | Owns (new files allowed under these) | Delivers |
|---|---|---|---|
| AD Art director | `claude/ui-ad` | `docs/art/ui-quality/gate/**`, `docs/art/ui-quality/kit-spec.md`, `tools/ui_gate/**` | The rubric, the reference sheet and a published score for every piece of interface art before it merges (`docs/art/ui-quality/report.md` section 3.5); keeps the kit spec and answers component requests (`kit-spec.md` section 7). Never authors. |

The other six rows stand as the integrator added them. K1's row already covers the catalogue shot (`client/tests/shots/ui_*.gd`) and `tools/ui_bake/check_screens.py`; K1's catalogue stills go to `docs/art/shots/ui-bake/`, as every track's stills go to `docs/art/shots/<track>/`.

## 5. Second round: the kit, and build or buy

The owner asked for the kit to be specified in full and for the plan's assumption, that the AI artists make every piece of art from scratch, to be tested against existing kits and assets. The results are `kit-spec.md` and `build-or-buy.md`, folded into the report.

| # | Where | Found | Resolved |
|---|---|---|---|
| R47 | Report section 3 | The plan assumed every piece of art is authored from scratch, without checking what exists | Tested in `build-or-buy.md`: the assumption holds. Nothing adoptable supplies Ruleborn's identity, characters or icons; the closest kits look like other games; the best adoption (CC0 particles) saves 3 hours. **OWNER: D11** |
| R48 | §21.11 | The plan never said that §21.11 forbids outside art, paid or free ("Nothing in this game is paid for"; everything but fonts, sound and code is "made for this game") | Section 10.6 and `build-or-buy.md` section 1; buying is **OWNER: D12**, not recommended |
| R49 | Report step 5 | The kit was about ten named parts ("frames, buttons, bars, rings, ribbons, badges, numerals"). The five screens and the menus need 47 components | `kit-spec.md` section 4 |
| R50 | Today's kit | 108 materials in `tokens.json`, against the rubric's quality 11 (at most 4 button styles, 3 frames, 1 ribbon, 1 badge, 1 currency pill) | 35 skins, with every material mapped (`kit-spec.md` section 8.2) |
| R51 | Report section 3 | Only "pressed faces" were planned; no other state | Nine states defined once, and a matrix per component (`kit-spec.md` sections 3 and 4) |
| R52 | The owner's list; §21.8 | Toasts were asked for, but §21.8 says an informative notice is "never a toast that clears itself" | No toast component; the banner (K29) is the only notice |
| R53 | The owner's list; §20.8 | Tooltips need hover, which a phone lacks, or a long press, which §20.8 rules out without a two-tap form | An info popover opened by a tap on a 48-point (i) control (K30) |
| R54 | Report section 3 | No plan for a slider (needed for §20.8's separate volumes), a toggle, a text field, a spinner, an empty state or an info popover | K05, K06, K11, K34, K35, K30, with skins |
| R55 | T10's layer | `ScreenParts` duplicates kit parts (pill, chip, badge, segmented control, section, stat, row, resource, status plate, empty state): two component systems | Mapped to the kit's components and replaced after this wave; `ScreenBox` dropped once S3 routes `ScreenKit` through `KitSkin` (`kit-spec.md` section 8.1) |
| R56 | Report section 3 | No governance: any screen could add chrome of its own, which is how the client reached 383 `draw_*` and `FxPen` calls | Requests through AD; reuse first; a check in check_all that refuses new local chrome (`kit-spec.md` section 7) |
| R57 | Report section 3 | No single view of the kit for AD to score | The catalogue sheet, with a coverage test (`kit-spec.md` section 6.4) |
| R58 | Section 7; `bake_hud.js` | The proof's numerals are four finishes (gold, white, timer, timer red; the bake's comment says three, counting the timer once) and lack the full stop, minus and question mark that section 10.4 needs | The full set is in `kit-spec.md` section 2.2's T3; K1 adds the missing marks |
| R59 | Ownership | Nobody owned the kit spec after this wave | AD keeps it. **T15/INT: X12** (the AD row) |
| R60 | Report sections 3.3 and 3.7 | The kit spec adds work: AIA's kit art 10 → 16 hours, K1 24 → 31, AD 20 → 21 | 158 hours (155 with D11); still six days. AIA's kit art spans days 3–4 and motion days 4–5; K1's families switch on across days 3–4. **OWNER: D1** |
| R61 | `build-or-buy.md` 2.6 | Spine and Rive were the obvious tools for UI animation | Spine's Godot runtime is official but not permissively licensed ($69–439 a seat, §21.11's code rule); Rive has no official Godot runtime (a community alpha with macOS builds only). Neither adopted |
| R62 | `tokens.json`; §21.8 | A bar filling to a new value takes 450 ms, past §21.8's 150–250 for "every interface movement"; the token calls it "a value changing, not a transition" | Kept as T9 set it; the owner confirms the reading inside D3 |

## Stopped here

T16 first stopped at about 18:30 UTC on 28 October. On the owner's new task, T16 resumed at 21:30 UTC, specified the kit (`kit-spec.md`), tested building against buying (`build-or-buy.md`), folded both into the report and this log, and stopped again with everything pushed green on `claude/ui-plan`.

**Done:** 62 findings (R1–R62), all resolved. The plan has a one-page summary, seven agents with their files, ten steps with inputs, outputs, waits, pass marks and hours, a six-day schedule, four owner gates, a full kit spec, a build-or-buy answer, budgets, rules, risks and twelve owner decisions.

**Still needs the owner:** D1 (158 agent-hours) before anything starts; D2–D5 and D11 at the times in report section 12; D6–D10 and D12 have defaults.

**Still needs others:** X4, X8 and X12 (T15 or the integrator); X5–X7 and X11 only if the owner chooses them; X10 for container set-up.
