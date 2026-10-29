# Review of the next wave's UI plan (T16; round 3 by T17)

T16 read `report.md` as a sceptical reviewer who must run its plan tomorrow, checked it against the design document (`docs/design/ruleborn-game-design-v3.7.txt`), `docs/art/3d-program.md` and the stopped tracks' notes in `docs/art/tracks/`, and fixed it. This log lists every inconsistency and gap found, where it was, and how it was resolved.

Rounds 1 and 2 are T16's. Round 3 (section 6) is T17's: plan v3, rebuilt on `docs/research/agent-team-operating-model.md`, with the places it does not follow the research.

**Marks.** **OWNER** means the owner must decide; the report's section 12 has the options and the default. **T15/INT** means another document or file must change, which T16 may not edit; the exact change is in the last section, for T15 or the integrator.

## Summary

- 62 findings in two rounds. The first round (R1–R46): 13 inconsistencies in numbers or references, 21 missing parts of the plan, 12 places where the plan broke or bent a rule of the design document or the repository. The second round, on the owner's request to specify the kit and test building against buying (R47–R62, section 5).
- All are resolved in `report.md`, `kit-spec.md` and `build-or-buy.md`. Twelve decisions need the owner (D1–D12). Outside T16's files: X1–X3 are done by the integrator; X4 and X8 are needed now, and X12 is replaced by round 3's X13; X5–X7 and X11 only if the owner chooses them.
- **Round 3 (R63–R95, N1–N11, X13–X16):** plan v3. The gate is rebuilt from scripted checks, pairwise checks against the owner's golden set and the owner's boards, and calibrated on the owner's labels; at most five building agents in four phases; a merge queue; the owner's time in seven kinds of short sittings; session and token rules, with the settings as proposals. 164 agent-hours. Two decisions are new: D13 (usage) and D14 (settings).
- **The two that changed the picture most in rounds 1 and 2:**
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

## 6. Third round: plan v3 on the research (T17)

The owner asked for the plan to follow the research in `docs/research/agent-team-operating-model.md`, which ends with an operating model for this wave. T17 read it in full and changed the plan where it finds the design weak. The research labels its claims as measured, reported, vendor guidance, opinion or inference; the column "Basis" gives the label of the evidence each change rests on. Where the basis is opinion or inference, the change is a judgement, not a finding.

**The changes**

| # | Where | Found | Resolved | Basis |
|---|---|---|---|---|
| R63 | Report 3.5 | The gate scored every piece 0–5 per quality against thresholds. LLM judges are weakest at absolute scores: pairwise agreement with people is much higher than agreement on scales, scores bunch near the middle, and repeated scores of the same output often differ | Four checks: scripted checks; one isolated pairwise check per static visual quality against the owner's weakest-pass and strongest-fail anchors, sampled three times, blocking only on three fails, splits to the owner's exceptions; the merge queue's guards; the owner for what a still cannot show | Measured (via search summaries) |
| R64 | Report 3.1, 3.5 | AD scored the artists' work with no model named, so it could be the artists' own model, and with no limit on its tools | The judge runs on Fable 5.1, a different model from the artists, read-only (`Read`, `Grep`, `Glob`), without the author's notes. Opus 5.5 judges only if it catches more on the held-out labels, and then the blind audit doubles | Measured (self-preference); vendor guidance (read-only reviewers) |
| R65 | Report 3.4, 3.2 step 1 | AD was calibrated by re-scoring today's screens within 0.2 of T14's scores and by one owner score of one key frame within 0.5. Both measure agreement with another score, not whether the judge catches what the owner would fail | A golden set of 30–60 items labelled by the owner per quality (O3); thirds for training, development and held-out; the catch rate on the owner's fails as the measure, with a target (80%, at most 20% false blocks, at most 30% to exceptions), two prompt revisions, the other model, then owner-checked | Opinion and secondary (the method); the target is T17's |
| R66 | Report 3.5 | Nothing checked the gate's passes after the wave started | Blind audits of 10–20 passes mixed with 3–5 fails, at the end of phase 2 and at wave end (O6); one miss pauses default merges for that quality until the judge is re-validated; the labels join the golden set | Inference |
| R67 | Report 3.5 | Press, juice and motion (qualities 4, 5, 7) were scored from frame strips | Scripted checks for timings, reduced forms and flashes; the owner judges the strips on the boards. Static-screenshot judges overrate interaction | Measured (via search summary) |
| R68 | Report 3.5 | The rubric's 14 qualities had no method under the new gate | Kept as the vocabulary, with a table of how each is checked: 10, 11 and 12 entirely by script; 1, 2, 3, 6, 8, 9, 13 and 14 judged (with scripted parts where they exist); 4, 5 and 7 by script and the owner. A table per asset class | Inference |
| R69 | Report 3.3 (T16's schedule) | Seven agents ran at once on day 4 (AD, AIA, AIA-2, K1, S1, S2, S3) | At most five building sessions at once, plus the lead and short gate runs; three if usage runs hot (D13) | Vendor guidance (3–5 teammates); inference |
| R70 | Report 3.2–3.3 | Days, not phases: the screens could start before the kit contract or any reference was fixed | Four phases with entry and exit criteria. The kit contract and the golden set are frozen in phase 0; one pilot screen in phase 1; three screens in parallel only in phase 2 | Reported and inference (contract first) |
| R71 | Report 3.1; `kit-spec.md` 6.2 and 7 | Every screen track wrote rows into `gate/requests.md`, a file another agent owned, from its own branch: a shared file. AD owned the kit spec while K1 owned the kit | One owner per file, hotspot files named. K1 owns `kit-spec.md` (the contract) and answers requests in its request log; requests are raised in the requester's own status file | Vendor guidance |
| R72 | Report 3.3 | Work was a schedule of named steps; nothing for an agent that finishes early, and no claims | Every step is backlog tasks with time-limited claims, and an idle queue (`docs/guides/agent-program.md`, `docs/progress/backlog.example.json`) | Reported |
| R73 | Report 3.1 | No model per role | A model per role with its reason; never switched inside a session; the escalation rule (a screen that fails twice moves to a fresh Opus 5.5 session) | Vendor guidance and secondary benchmarks; inference |
| R74 | Report 3.8; `docs/guides/agent-program.md` | The integrator merged every green head hourly into an integration branch and resolved what clashed | A merge queue: one change at a time, as soon as ready; main only fast-forwards to a commit whose checks passed on that tree; each worker resolves its own conflicts; the hourly hand merge is the longest wait and resolves nothing | Reported (an integrator agent became the bottleneck); inference |
| R75 | Report 3.8, 10.8 | The UI budgets ran "at the integrator's merge run", and nothing named the guards against semantic conflicts | A guard table: the database's `node server/load.mjs --check`; the bake check; the chrome check; the client's contrast and size tests; `tools/ui_bake/guard.sh` for draw calls, texture memory and the rebake, against recorded counts. Fast-forward-only merging puts them on the combined tree | Documented practice; inference |
| R76 | Report 3.4 | The owner approved items one by one (the board, each key frame, the wave) and calibrated AD | O1–O7: the plan, the board and contract, the golden set (60–90 minutes, once), five family boards with "merges after 24 hours unless you object", a daily exceptions queue, two blind audits, the wave board; minutes for each | Secondary (rubber-stamping); inference |
| R77 | Report 3.8 | A default merge of everything after 24 hours would hold every screen behind the kit's board | Pieces merge as soon as they pass, behind their family switch; what players would see (a switch-on, a new layout) waits on its board's 24 hours. Phase 2 waits for board 1 only | Inference |
| R78 | Report 3.9 | No rules for sessions or tokens | A fresh session at each phase and task boundary with a handoff; compaction at 200k; test output to files with a completion marker; stills at 960 pixels for judging with full-resolution crops where downscaling would hide the quality; no model switch inside a session; Haiku 5.5 subagents for searches | Vendor guidance; inference |
| R79 | Report 3.9, 11 | Usage limits were met by "each agent schedules its own resume" | A projection from `/usage` at the end of phase 0 with a 20% reserve; tiers that stop the least critical first; staggering; a commit after every verified step; D13 | Inference |
| R80 | Report 3.9, 12 | Settings were not discussed | Proposals P1–P6 with exact values, decided as D14. T17 changed no setting | Vendor guidance |
| R81 | Report 3.7 | 158 hours | 164: AD and the gate 21 → 25, K1 31 → 33. By phase 43, 58, 62 and 1, plus up to 20 of re-work; the lead's about 16 outside | Step costs |
| R82 | Report 3.3 (T16's schedule) | A six-day table | Phases in wall-clock hours: about 65, six working days as before; up to 24 more if board 1 waits for its default; about 12 more at three builders | Step costs |
| R83 | Report 3.3, steps 3 and 1 | Key frames were scored by AD and approved by the owner at G2 | Key frames are made in phase 0 and labelled by the owner in the golden set: they become the references the pairwise gate compares against | Inference |
| R84 | Report 3.3, step 7 | The heist was one of three screens built in parallel | The heist is the pilot, built from the kit alone in phase 1, before three screens copy any gap in the contract | Inference |
| R85 | Report 3.6, D10 | The target was a mean of 3.5 out of 5 | Every applicable quality passes the calibrated gate and every board stands. On T14's scale the bar is estimated at about 3.5; that figure is for comparison, not a gate | Inference |
| R86 | Report 12 | Decisions were timed by day and gate (G0–G3) | Timed by O1–O7 and phase; D13 (usage) and D14 (settings) added; D1 and D10 reworded | |
| R87 | Report 11 | Risks assumed the scored gate | The judge agreeing with itself; missing its target; a golden set too small; weaker Sonnet screens; the merge queue as bottleneck; the owner away; usage | |

**Consistency, read end to end after the changes**

| # | Where | Found | Resolved |
|---|---|---|---|
| R88 | The research and the plan | The research calls its item checks G0–G3; the plan called its owner gates G0–G3 | Owner points are O1–O7 and the gate's checks are numbered 1–4 everywhere |
| R89 | Report 6 | Costs of 158, about 90, 20 and 150 | 164, about 94, 25 and 156 |
| R90 | Report 9.1, 9.4 | "AD scores every piece", "the owner approves the key frames" | The gate checks; the owner labels the key frames |
| R91 | Report 10.2, 10.8, 10.9, 10.10 | "Before G3"; budgets "at the integrator's merge run"; a family switched on when it passed "AD's gate"; "AD scores qualities 4 and 5" | O7; `guard.sh` before a change is ready; the board's 24 hours added to switching on; the owner judges 4 and 5 |
| R92 | `kit-spec.md` 6.2, 6.4, 7 | AD as owner of the spec, the scores and the requests | K1 owns the spec and the request log; the gate writes verdicts; a freeze rule at the top of the page |
| R93 | `build-or-buy.md` 3, 4 | 158 and 155 hours; "day 5"; "K1's 31" | 164 and 161; phase 2; 33 |
| R94 | Report 4, 5 and 9.3 | T14's 0–5 scores of today's screens, Screens v3 and the proof icons | Kept: they are T14's audit and explain the verdict, not a gate. The gate no longer produces scores |
| R95 | `docs/art/3d-program.md`, "What done looks like" | Says interface stills are "scored by the art director on the 14-quality rubric" | **T15/INT: X14** |

**Where plan v3 does not follow the research, and why**

| # | The research says | Plan v3 | Why |
|---|---|---|---|
| N1 | Phases of 14, 43, 71 and 30 agent-hours (158) | 43, 58, 62 and 1, plus up to 20 of re-work (164) | The research calls its split its own allocation. Checked against the steps: its phase 0 has no board or key frames, but its own gate needs owner-approved golden screens before anything is judged, so 16 of AIA's hours move into phase 0 |
| N2 | Artists 44, kit 26, screens 66, art director 22 | 70, 33, 36 and 25 | The plan's step costs: 60 icons at about 25 minutes, 35 skins with states and twins, five screens costed one by one. The risk that Sonnet 5.5 screens take longer is carried by the reserve and the escalation rule |
| N3 | About 40 wall-clock hours at five builders | About 65 | AIA's 42 hours run in series (board, key frames, kit art, motion), and the result screen waits on the motion art. That chain, not the cap, sets the length |
| N4 | The owner approves the plan, kit contract, ownership map and budget choice in one 20-minute sitting before phase 1 | O1 (the plan, 20 minutes, before phase 0) and O2 (the board and the frozen contract, 15 minutes, in phase 0); the budget choice is D13 at the end of phase 0 | Nothing may start before D1, and the key frames are built from the approved board, so the board's approval cannot wait for phase 1 |
| N5 | Pairwise against golden screens; describe extreme anchors | The prompts describe the extreme anchors in words; the pictures shown are the boundary items (the weakest pass and the strongest fail) | The question is pass or fail at the owner's bar, so the pictures that decide it sit at the bar |
| N6 | No catch-rate figure | 80% catch rate, at most 20% false blocks, at most 30% to exceptions | A gate needs a number. It is T17's opinion, set high because judges are reported to catch only 30–60% of bad items |
| N7 | Workers rebase onto main | Workers bring main in by a merge | The repository's convention; a rebase of a pushed branch needs a force push. The point the research makes, that the agent holding the context resolves its own conflicts, is kept |
| N8 | A "confident fail" blocks | Confident means three fails out of three samples | The research does not define it. Two of three goes to the owner: the queue costs minutes, a wrong block costs a re-work round |
| N9 | Status in `status/<agent>.json`, handoffs in separate files | Status in `docs/progress/status/<agent>.json` on the agent's own branch; the handoff as a section of the agent's progress file | One fewer file per agent to keep in step; agents push only to their own branch, so the status file must live there |
| N10 | A Stop hook, `CLAUDE_CODE_AUTO_COMPACT_WINDOW`, cache TTL and output filters "every session runs with" | Proposals P1–P6 for the owner (D14), with the rules also written for agents to follow by hand | The owner's instruction: no agent changes settings or config files |
| N11 | Interaction-dependent qualities to "captured-frame review or the owner" | The owner, from frame strips; the judge does not block them | No source measures judges on frame strips; the safe reading of the evidence is that a judge of stills overrates them |

## 7. Changes outside T17's files (round 3)

**X13. `docs/art/3d-program.md`, the track table** (T15 or the integrator). Plan v3 changes three rows and adds one; the other five UI rows (AIA, AIA-2, S1, S2, S3) stand.

| Track | Branch | Owns (new files allowed under these) | Delivers |
|---|---|---|---|
| AD Art director | `claude/ui-ad` | `docs/art/ui-quality/gate/**` except `gate/verdicts/`, `tools/ui_gate/**` | Phase 0 only: the rubric as pass and fail criteria, the golden set for the owner to label, the judge's prompts and its calibration (`docs/art/ui-quality/report.md` section 3.5). Never authors art |
| Gate The judge | `claude/ui-gate` | `docs/art/ui-quality/gate/verdicts/**` | Short read-only runs: a verdict per item and quality, three samples each, the owner's exceptions queue and the blind-audit samples (`report.md` section 3.5) |
| K1 Kit owner, bake pipeline and kit (takes over T9) | `claude/ui-bake` | `docs/art/ui-quality/kit-spec.md`, `tools/ui_bake/**`, `tools/ui_research/**`, `client/prototypes/ui_quality/**`, `client/tests/shots/uiq_*.gd`, and T9's files except `client/ui/art/` | The kit contract (frozen at the end of phase 0) and its request log; the bake; the texture-backed kit behind a switch per material family; the UI guards (`tools/ui_bake/guard.sh`) |

The rows' order: AD, Gate, AIA, AIA-2, K1, S1, S2, S3. The X12 row is replaced by AD's row above. Under the table, add: "The UI wave runs in phases with at most five of these building at once, and each row's model is in `docs/art/ui-quality/report.md` section 3.1."

**X14. `docs/art/3d-program.md`, "What done looks like"** (T15 or the integrator). The X2 sentence becomes: "From the UI wave on, interface stills also pass the art director's gate (`docs/art/ui-quality/report.md` section 3.5): scripted checks, a calibrated judge comparing them with the owner's labelled golden set, and the owner's boards; a screen's target is its approved key frame where the owner has adopted one (section 12, D2)."

**X15. The owner: D14.** P1–P6 in report section 3.9 are proposals only. If approved, the lead applies them (P1 in the environment's variables; P2–P6 in `.claude/settings.json` and `.claude/agents/`) and writes the two hook scripts they name.

**X16. For whoever starts the wave's sessions.** X10 still holds: this container also lacked Rust's `wasm32-unknown-unknown` target, `gdlint` and Python's `playwright` 1.63.0; T17 installed them locally to run check_all. The judge's sessions are started on the judge model (Fable 5.1, or Opus 5.5 if calibration chooses it), the screen agents' on Sonnet 5.5, and nobody switches a session's model.

## Stopped here (T16)

T16 first stopped at about 18:30 UTC on 28 October. On the owner's new task, T16 resumed at 21:30 UTC, specified the kit (`kit-spec.md`), tested building against buying (`build-or-buy.md`), folded both into the report and this log, and stopped again with everything pushed green on `claude/ui-plan`.

**Done:** 62 findings (R1–R62), all resolved. The plan has a one-page summary, seven agents with their files, ten steps with inputs, outputs, waits, pass marks and hours, a six-day schedule, four owner gates, a full kit spec, a build-or-buy answer, budgets, rules, risks and twelve owner decisions.

**Still needs the owner:** D1 (158 agent-hours) before anything starts; D2–D5 and D11 at the times in report section 12; D6–D10 and D12 have defaults.

**Still needs others:** X4, X8 and X12 (T15 or the integrator); X5–X7 and X11 only if the owner chooses them; X10 for container set-up.

## Stopped here (T17)

T17 stopped on 29 October with everything pushed green on `claude/plan-v3`.

**Done:** plan v3 of the UI wave, rebuilt on the agent-team research: the gate (scripted checks, an isolated pairwise judge on Fable 5.1 sampled three times, the merge queue's guards, the owner), calibrated on a golden set of 30–60 owner labels with an 80% catch-rate target and blind audits; seven building roles in four phases with at most five at once; a model per role and the escalation rule; a fast-forward-only merge queue with guards on the combined tree; the owner's time in O1–O7 (about 4½ to 6¼ hours); session, token and usage rules with six settings proposed (P1–P6); 164 agent-hours (43, 58, 62 and 1 by phase, plus up to 20 of re-work), about 65 wall-clock hours. Logged as R63–R95, with N1–N11 where the plan does not follow the research. The operating model for every wave is `docs/guides/agent-program.md`; the brief is `docs/guides/agent-brief.md`; the backlog format is `docs/progress/backlog.example.json`.

**Still needs the owner:** D1 and D14 at O1; D4 and D5 at O2; D2 at O3; D13 at the end of phase 0 if usage does not fit; D3 and D11 before phase 2. D6–D10 and D12 have defaults.

**Still needs others:** X13 and X14 (T15 or the integrator); X15 if the owner approves D14; X16 for whoever starts the sessions.

