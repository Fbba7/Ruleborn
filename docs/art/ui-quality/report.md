# Why the interface is not premium yet, and the way there (T14, plan revised by T16)

The owner says the interface is "not even 30% there". The agents' progress files say 80–90%, and the integrator says "about halfway". This report finds out which reading is right and why. It also says what to do next and shows a proof.

T14 wrote the research (sections 1, 2, 4, 5, 7 and 9). T16 reviewed the plan as the agents who must run it tomorrow would: T16 rewrote the plan (the plan at a glance, sections 3, 6, 10, 11 and 12) and corrected numbers and rules in sections 1, 4, 5, 7 and 9. Every change, and why, is in `plan-review.md` in this folder.

Everything here was measured or rendered from the deployed head (`dd326ca8`). Images are in this folder. Tools are in `tools/ui_research/`.

## Plan at a glance

**What the owner decides first (section 12).** Five decisions are needed before day 1 or at the gate named. The plan runs on safe defaults for the rest.

| # | Decision | When | Default if not decided |
|---|---|---|---|
| D1 | Approve the plan: 7 agents, 144 agent-hours, plus up to 20 for re-work | Before day 1 | Nothing starts |
| D2 | Make the approved key frames the visual reference in place of Screens v3 (a change to §23.5) | At gate G2, day 2 | Key frames are targets only; Screens v3 stays the reference for layout and icons |
| D3 | Allow overshoot on presses and reward reveals (a change to §21.8's motion rule) | Before day 4 | §21.8 as written: 150–250 ms, easing out, no overshoot |
| D4 | Allow a display face and baked numerals for labels and changing numbers on art (a change to §21.8's type rule) | At G1, end of day 1 | §21.8 as written: Manrope for labels and changing numbers |
| D5 | Allow object icons rendered with physically based light (gold, gems, glass), as interface art | Before day 2 | Character and building icons start first, in the toon look |

**The wave's target (section 3.6).** Each of the five key screens (home, heist, result, character, settings) scores at least **3.5 out of 5** on the 14-quality rubric, up from 2.2 today. That is 70% of Clash level and about **50% of the owner's bar**. The plan's honest ceiling is 3.75–4.25 out of 5: 75–85% of Clash level, 54–61% of the bar (section 6). The rest of the bar needs a later wave.

**The agents.**

| Agent | Role | Hours |
|---|---|---|
| AD | Art director. Scores everything against the rubric. Never authors. | 20 |
| AIA | AI UI artist. Style board, key frames, kit art, motion art. | 36 |
| AIA-2 | A second AI UI artist on the same studio. The 60 most-seen icons. | 28 |
| K1 | Bake pipeline and the texture-backed kit (engineering). | 24 |
| S1 | Heist and result screens onto the new kit, with the reward sequence. | 14 |
| S2 | Home screen onto the new kit. | 8 |
| S3 | Character and settings screens; routes the menu screens' own kit through the new one. | 14 |
| | **Total** (T14's plan said about 80; section 3.7 shows the difference) | **144** |

**The phases** (about 12 agent-hours a day for each agent; section 3.3 has the day-by-day schedule).

| Day | Work | Owner |
|---|---|---|
| 0 | | **G0:** approve the plan and decide D1 |
| 1 | AD sets up the gate. AIA makes the style board. K1 builds the pipeline. | **G1:** approve the style board (about 15 minutes) |
| 2 | AIA makes five key frames. AIA-2 starts icons. K1 finishes the pipeline. | **G2:** approve the key frames; decide D2 (about 30 minutes) |
| 3 | AIA makes kit art. K1 switches the kit's materials to textures, one family at a time. | |
| 4 | AIA makes motion art. AIA-2 finishes icons. S2 and S3 move their screens. S1 starts the heist. | |
| 5 | S1 moves the result screen with the reward sequence. AD scores every screen. | |
| 6 | Re-work reserve. AD's final scores. | **G3:** accept the wave (about 30 minutes) |

**The gate (section 3.5).** AD scores every piece before it merges: 0–5 per quality, at phone size, at 48 points and in grayscale, with a frame strip for anything that moves. A piece merges only if it meets its class's thresholds and no score drops. A piece that fails twice goes to the owner with options. Every score is published in `docs/art/ui-quality/gate/scores.md` beside its image.

**Rules the plan keeps (section 10).** Under §21.3's 150 draw calls on every screen, at 100% and 200% text and in high contrast. 48-point targets and 13-point text at 200%. Contrast in normal and high-contrast mode. A reduced form for every motion. Words stay live text from the strings tables, in English and Brazilian Portuguese. Pinned tools, and bakes that rebuild byte for byte. A switch per material family, so no screen is ever half-moved.

## 1. Verdict

**The owner is right. Against the owner's bar we are at about 30%.**

I scored our five most important screens (home, heist, result, character and settings) against 14 checkable qualities of premium mobile UI (section 4). **The mean is 2.2 out of 5**, with 5 meaning Clash Royale or Brawl Stars level: 44% of Clash level. The six qualities that most separate premium from competent score:

| Quality | Score (out of 5) |
|---|---|
| Material | 2.1 |
| Display type | 1.7 |
| Painted icons | 2.1 |
| Reward juice | 1.3 |
| Motion | 1.8 |
| One art-direction idea | 1.5 |

Four of them are among the five lowest scores of the fourteen. Counting those six double gives a weighted mean of 2.08, or 41.5% of Clash level. The headline figure everywhere in this report is the plain mean, 2.2.

**How 2.2 becomes "about 30%".** The owner's bar is *above* Clash, and three times Screens v3. Screens v3 scores 2.36 on the same rubric (section 5.2), so three times v3 is about 7 on a scale where Clash is 5. This report takes **the bar as 7 out of 5**. Then 2.2 is 31% of the bar: "about 30%" is a fair figure. Every "share of the bar" in this report divides by 7.

The agents' 80–90% is not a quality measure. It counts finished deliverables against a list. Their "vs design" rounds measure how closely a still matches the design's layout. On that test they do well: our screens now match the design closely (`audit-*.png`).

**Matching the design cannot reach the bar.** Screens v3 itself scores 2.4 out of 5 on the same rubric (section 5.2):
- a dark-violet web-panel look, with rims of 1.5 px at 35–50% opacity;
- most text in Manrope at 10–11 pt with no stroke;
- dark on dark, about one step of value apart.

A perfect port of v3 lands near 47% of Clash level, or 34% of the bar. "Three times v3" is not a direction you can polish toward. It needs a different target and a different way of making pixels.

## 2. Root causes

**Art direction (what we aim at).** The only target the agents have is Screens v3. It is an HTML/CSS mock-up whose materials are CSS inset shadows (`docs/analysis/screens-v3/design-system.md`, section 2.4) and whose type is mostly small Manrope. No still exists that shows the bar: nothing at Clash level, nothing "three times v3". `docs/art/3d-program.md` asks every still to "beat the matching design still", but it never says what beating it looks like. So agents converge on parity with v3.

**Production pipeline (how pixels get made).** Every piece of chrome is drawn by code at run time:
- 383 `draw_*` and `FxPen` calls in the client;
- one 33-uniform `rb_box` shader for every panel and button;
- the pips' digits drawn as seven-segment line strokes (`fx_portrait.gd` `SEGMENTS`).

The only authored raster UI in the client is the design's own icon set, exported flat at 144 px (370 PNGs). Studios at the bar make their UI as authored raster art (section 4.2):
- painted in Photoshop and animated in Animate or Spine;
- key icons rendered from 3D and painted over;
- shipped as 9-slices and atlases.

Code-drawn chrome caps out quickly:
- **No grain or lit bevels:** each new surface effect is new shader code that every screen pays for per pixel. So the materials stay smooth gradients, with banding visible in `docs/art/shots/ui-kit/sheet-materials-r1.png`.
- **Type has no weight:** labels get no thick stroke, drop or gradient fill.
- **Icons stay flat:** the icons are the design's vector icons.

**Process (how agents judge their work).** Agents grade their own stills against the design, one track per screen, round after round:
- The comparison is a side-by-side at phone size plus a grayscale thumbnail. That rewards layout and value match, not material, type or motion quality.
- Nobody outside the track scores the work.
- No rubric and no benchmark references exist.
- "Progress" is tasks done.
- Motion and juice are never judged, because the evidence is stills.

Five waves of this converged on v3 parity, which is where the method stops.

## 3. Recommendation and next-wave plan

**Recommended:**
- **Option A, an authored-asset pipeline**, made by Option D, a standing **AI UI artist** (section 9). The owner chose this over a human artist.
- **Option C, an art-director gate**, scoring the AI artist's work.

The ranked options with costs are in section 6.

The two proofs show that this works in this engine, within budget, and is much richer than code-drawn chrome:
- **The heist HUD (section 7):**
  - rebuilt from art baked offline in headless Chromium: lit bevels, grain, studs, painted icons, numerals with stroke, drop and gradient;
  - one 1024² atlas;
  - 147 draw calls against 137 today, under §21.3's 150;
  - every word still live text from the strings tables.
- **The reward icons (section 9):** Starlight, Essence and Renown, plus a chest and a crew badge from Pip's own model, modelled and lit in three.js and finished in 2D at 256 px. Icons are the asset class this report first said needed a human hand. They score 3.7 out of 5 on the rubric's icon qualities, against 2.2 for today's.

Both proofs rebake byte for byte: `bake_hud.js` in 23 seconds for its 75 pieces twice, `bake_icons.js` in 10 seconds for five icons (measured by T16 on this container).

### 3.1 The agents and their files

Every track that built the interface has stopped, so the wave needs new agents. Each owns the files below; new files are allowed under them. Nobody else edits them. A change another agent needs is the smallest hook, noted in the owner's track notes, as `docs/art/3d-program.md` asks.

| Agent | Branch | Owns | Takes over from |
|---|---|---|---|
| AD, art director | `claude/ui-ad` | `docs/art/ui-quality/gate/**`, `tools/ui_gate/**` | (new) |
| AIA, AI UI artist | `claude/ui-artist` | `art/ui/**` except `art/ui/icons/`; `client/ui/art/**` (written only by the bake) | (new) |
| AIA-2, AI UI artist for icons | `claude/ui-artist-icons` | `art/ui/icons/**`, `client/tests/shots/icon_*.gd` | (new) |
| K1, bake pipeline and kit | `claude/ui-bake` | `tools/ui_bake/**`, `tools/ui_research/**`, `client/prototypes/ui_quality/**`, `client/tests/shots/uiq_*.gd`, and T9's files: `client/scripts/ui.gd`, `client/ui/**` except `client/ui/art/`, `tools/ui/`, `client/tests/ui_kit_tests.gd`, `client/tests/a11y_tests.gd`, `client/tests/shots/ui_*.gd` | T9 (UI kit), T14 (the proof) |
| S1, heist and result | `claude/ui-screens-heist` | T5's `heist_screen.gd`, `heist_hud.gd`, `result_screen.gd`, `replay_screen.gd`, `client/world/fx_*.gd` | T5 |
| S2, home | `claude/ui-screens-home` | T4's `client/scripts/home.gd` | T4 |
| S3, character and settings | `claude/ui-screens-meta` | T7's `character_screen.gd`; T10's files (`client/scripts/screen_*.gd`, `settings_screen.gd`, `client/tests/shots/screen_*.gd`) | T7, T10 |

Two notes on files:
- **The bake writes into AIA's folder.** K1 owns the bake scripts; AIA owns the art sources in `art/ui/` and the baked results in `client/ui/art/`. Only the bake writes there, so the two never edit the same file. `art/` is outside the Godot project, so sources are never imported or shipped.
- **Character icons need T7's portrait studio** (`client/world/portrait*.gd`), read only, through AIA-2's own shot scripts (section 10.6).

`docs/art/3d-program.md`'s track table needs these rows; the exact text is in `plan-review.md` for T15 or the integrator.

### 3.2 The steps

Each step lists its owner, what it reads and writes, what it waits for, how AD's gate judges it, and its hours. The thresholds are in section 3.5.

**Step 1. AD sets up the gate.** Owner: AD. 6 hours. Day 1. Waits for nothing.
- Reads: sections 4, 5 and 10 of this report; `docs/design/ruleborn-game-design-v3.7.txt` §21.8, §20.8 and §21.10.
- Writes:
  - `gate/rubric.md`: the 14 qualities of section 4 with the design document's rules folded in (section 4.3), and a check per asset class;
  - `gate/reference.md`: the benchmark screens as written descriptions, one per quality, with the score each would get;
  - `gate/scores.md`: the score log, one row per piece and round;
  - `tools/ui_gate/sheet.py`: a contact sheet of any image at phone size, at 48 and 96 points, and as a grayscale thumbnail (§21.10); and a frame strip from a list of frames.
- Done when: the gate re-scores today's five screens and gets section 5.1's means within 0.2 per screen. That proves AD reads the rubric as T14 did.

**Step 2. AIA makes the style board.** Owner: AIA. 6 hours. Day 1. Waits for nothing.
- Reads: §21.2 and §21.8 (colours, type, icons), this report's sections 4 and 9, `tools/ui_research/`.
- Writes: `art/ui/board/board.html` and `board.png`, and `art/ui/palette.json`, the one palette file every later piece reads. The board shows:
  - the material set (enamel, gold, wood, glass, parchment), dressing §21.8's surfaces (the violet card, dark glass, leather, parchment and gold) in §21.2's and §21.8's own colours: it adds grain, bevel, gloss and light, not new hues (new hues would need §21.8 changed, to be raised at G1);
  - the type treatments, both under §21.8 as written and under decision D4, so the owner can choose at G1;
  - the outline and glint rules and the studio light;
  - four hero icons;
  - the high-contrast form of each material.
- Gate: AD scores qualities 1, 2, 3, 8, 11, 13 and 14 on the board.
- **Owner gate G1** (section 3.4).

**Step 3. AIA makes five key frames.** Owner: AIA. 10 hours. Day 2. Waits for G1.
- Reads: the approved board; the design's own HTML for the five screens (`art/design/stills/screens/` 01, 02, 07, 11 and 19 and their sources); §21.8's home and heist layouts.
- Writes: `art/ui/keyframes/<nn>-<screen>.html` and `.png` for home, heist, result, character and settings, at 1080 × 2340, each also at 200% text and in high contrast.
- Keeps: §21.8's arrangements, 48-point targets, 13-point text and live words from the strings tables, in English and Brazilian Portuguese.
- Gate: AD scores all 14 qualities on each key frame.
- **Owner gate G2**, with decision D2.

**Step 4. K1 builds the bake pipeline and the texture-backed kit.** Owner: K1. 24 hours. Days 1–3. Waits for nothing to start; switches material families on as AIA's kit art passes the gate (day 3).
- Reads: `tools/ui_research/` (`bake_hud.js`, `bake_icons.js`, `pack_atlas.py`), `client/prototypes/ui_quality/`, `client/ui/kit_skin.gd`, T9's notes (`docs/art/tracks/ui-kit.md`).
- Writes:
  - `tools/ui_bake/`: one bake for every family. `bake.js <family>` renders the sources in `art/ui/` and packs atlases with a manifest of regions and 9-slice margins. `--check` compares the sources' hash with the manifest's in seconds.
  - `client/ui/art/`: written only by the bake: `<family>.webp`, `<family>_hc.webp` and `<family>.json`.
  - `KitSkin`: texture-backed materials behind a switch per material family, with the code-drawn box as the fallback (section 10.9).
  - Labels in their own z layer above the art, so art and words batch apart (section 7's rule 2).
  - Frames sized from their words, so 200% text works (the proof did not do this).
  - Baked numerals with a fixed advance, and the separators of both launch languages (section 10.4).
  - School pieces baked once in neutral and tinted per school (section 10.5).
  - Tests, and the checks in `tools/check_all.sh` (section 10.8).
  - The fonts' licence ledger rows for anything new (section 10.6).
- Done when: section 10's checks pass; the heist proof runs on the kit at 147 draw calls or fewer; and the prototype in `client/prototypes/ui_quality/` is no longer read by anything, then deleted.

**Step 5. AIA makes the kit art.** Owner: AIA. 10 hours. Day 3. Waits for G1 and for K1's pipeline (end of day 2).
- Reads: the board and the key frames; T9's list of materials in `client/ui/tokens.json`.
- Writes: `art/ui/kit/*.svg`: frames and panels as 9-slices, buttons with pressed faces, bars, rings, ribbons, badges, and numerals in four finishes. Each comes with its high-contrast twin.
- Gate: AD scores the kit sheet page at phone size (`client/tests/shots/ui_kit_sheet.gd`) on qualities 1, 2, 8, 11 and 13. K1's tests must pass for contrast in both modes.

**Step 6. AIA-2 makes the icons.** Owner: AIA-2. 28 hours. Days 2–4. Waits for G1; object icons also wait for D5.
- Reads: the board, `art/ui/palette.json`, the studio in `tools/ui_research/icons.html`, the 43 models in `client/art/creatures/`, T7's portrait studio.
- Writes: `art/ui/icons/<name>.js` (one scene each), baked to `client/ui/art/icons_48.webp` (128 px per icon) and `icons_256.webp` (256 px, reward icons only).
- Scope: the 60 most-seen icons (currencies, rewards, heist controls, nav), about 25 minutes an icon (25 hours), plus 3 hours to set up the character route through Godot's toon portrait studio (section 10.6, §21.3).
- Batches: four batches of 15, each scored by AD before the next, in the order the screens need them: heist controls and currencies first. Until D5 is decided, character and building icons go first.
- Gate: at 48 and 96 points and in grayscale, qualities 1, 3, 8, 10, 11 and 13; each icon reads as a dark shape at 32 points (`docs/art/3d-program.md`'s silhouette rule).

**Step 7. AIA makes the juice and motion art.** Owner: AIA. 10 hours. Day 4. Waits for step 5 and decision D3.
- Writes: `art/ui/motion/` (burst, sparkle, shine and coin sprites) baked to `client/ui/art/motion.webp`, and `art/ui/motion/curves.json` (every curve's times and easing). K1 reads the curves in the kit's `Motion` (today's `UiqJuice` is the pattern).
- Covers: the result screen's reward sequence (anticipation, burst, reveal, coins flying to their counter, the counter rolling and pulsing), a press with squash and recovery, and an idle shine on primary buttons.
- Each motion has its reduced form (section 10.3).
- Gate: AD scores qualities 4, 5 and 7 from frame strips, full and reduced.

**Step 8. S1 moves the heist and result screens.** Owner: S1. 14 hours (heist 6, result 8). Days 4–5. Waits for G2, the kit families switched on (step 4), the icons (step 6) and, for the result, the motion art (step 7).
- Writes: its screen files; `client/tests/shots/` stills before and after; its notes in `docs/art/tracks/`.
- Gate: all 14 qualities, at 100% and 200% text and in high contrast; draw calls under 150.

**Step 9. S2 moves the home screen.** Owner: S2. 8 hours. Day 4. Waits for G2 and the kit families switched on.
- Same outputs and gate as step 8.

**Step 10. S3 moves the character and settings screens.** Owner: S3. 14 hours. Days 4–5. Waits for G2 and the kit families switched on.
- The menu screens draw through T10's own layer (`ScreenKit`, `ScreenBox` in `client/scripts/screen_*.gd`), not `KitSkin`, so they would not inherit the new kit. S3 routes `ScreenKit`'s materials through `KitSkin` (4 of its 14 hours), so every menu screen inherits it.
- Same outputs and gate as step 8.

**AD's reviews through the wave.** Owner: AD. 14 hours: the board (1), key frames (2), kit art (2), four icon batches (2), motion (1), five screens (5), the final scores (1).

### 3.3 Schedule

Each agent works about 12 hours a day. Agents in the same row run in parallel.

| Day | AD | AIA | AIA-2 | K1 | S1 | S2 | S3 | Owner |
|---|---|---|---|---|---|---|---|---|
| 0 | | | | | | | | G0: the plan, D1 |
| 1 | Set-up (6); scores the board (1) | Style board (6) | | Pipeline (12) | | | | G1 at day's end; D4 |
| 2 | Scores key frames (2) | Key frames (10) | Character route (3); batch 1 (6) | Pipeline (8) | | | | G2 at day's end; D2; D5 |
| 3 | Kit art (2); icon batch 1 (0.5) | Kit art (10) | Batches 2 and 3 (12) | Families switched on (4) | | | | |
| 4 | Icon batches 2–4 (1.5); motion (1) | Motion art (10) | Batch 4 (7) | | Heist (6) | Home (8) | Character, settings, menu kit (12) | D3 |
| 5 | Five screens (5) | Re-work | Re-work | Re-work | Result (8) | Re-work | Finish (2) | |
| 6 | Final scores (1) | Re-work reserve | | | | | | G3 |

The critical path is AIA's 36 hours plus the waits at G1 and G2. A gate that waits overnight moves every later day by one. While AIA waits at a gate, it starts the next step at risk on its own branch and merges nothing until the gate passes.

### 3.4 The owner's decision points

| Gate | When | What the owner sees | What the owner decides |
|---|---|---|---|
| G0 | Before day 1 | This plan at a glance, section 12 | D1, and any of D2–D5 now if wanted |
| G1 | End of day 1 | `art/ui/board/board.png` beside today's heist and the design's, with its type treatments both ways (§21.8 as written, and D4); AD's scores in `gate/scores.md` | Approve, or redirect with notes; decide D4. Nothing past step 2 merges without it. |
| G2 | End of day 2 | The five key frames beside today's screens and the design's stills, at phone size and in grayscale, at 200% text and in high contrast; AD's 14 scores per frame | Approve each key frame or send it back; decide D2 |
| G3 | Day 6 | The five screens before and after; frame strips of the reward sequence and the press, full and reduced; draw calls and texture memory per screen; AD's final table | Accept the wave, or name what must be re-worked |

The owner also calibrates AD at G2: the owner's own quick score of one key frame against AD's. Where they differ by more than 0.5 on a quality, AD rewrites that quality's notes in `gate/rubric.md` and re-scores.

### 3.5 The gate

AD scores every piece before it merges. AD is never the author of what it scores.

| Class | Judged on | Qualities | Pass |
|---|---|---|---|
| Style board | The board at phone size | 1, 2, 3, 8, 11, 13, 14 | each at least 3.5; then the owner's G1 |
| Key frame | Each frame at phone size, 200% text, high contrast, grayscale | all 14 | mean at least 4.0; 1, 2 and 3 at least 4.0; §21.10's grayscale test passes; then the owner's G2 |
| Kit art | The kit sheet at phone size | 1, 2, 8, 11, 13 | each at least 3.5; contrast tests pass in both modes |
| Icon | 48 and 96 points, grayscale, 32-point silhouette | 1, 3, 8, 10, 11, 13 | mean at least 3.5; none below 3 |
| Motion | Frame strips, full and reduced | 4, 5, 7 | each at least 3.5; timings within §21.8 or D3; a reduced form exists |
| Screen | 100% and 200% text, high contrast, grayscale | all 14 | mean at least 3.5; 1, 2 and 3 at least 3.5; no quality lower than before; section 10's checks pass |

Key frames have a higher bar than screens because a port always loses a little of its target.

**When a piece fails.**
1. AD writes in `gate/scores.md` which qualities failed and what would raise them, with a crop.
2. The author re-works it. A second round is normal.
3. A piece that fails a second time goes to the owner with three options: accept it with the score noted, change the board so it passes, or keep the code-drawn kit's form for that piece. The wave goes on around it.
4. A screen that fails stays on its current look. Its material families can still be switched on for other screens (section 10.9), because the switch is per family, not per screen.

### 3.6 The wave's target

The wave is accepted at G3 when each of the five screens scores **at least 3.5 out of 5**, with qualities 1, 2 and 3 at least 3.5 on every screen, and section 10's checks pass. Today the screens score 2.2.

3.5 out of 5 is 70% of Clash level and 50% of the owner's bar (7, section 1). The ceiling of this plan is 3.75–4.25 (section 6). The bar itself needs what section 9.4 says the AI artist lacks: invention, painterly texture and hand-timed effects.

### 3.7 Hours, against T14's estimate

T14's steps summed to 81 hours ("about 80"). This plan is 144.

| Step | T14 | This plan | Why it changed |
|---|---|---|---|
| AD | 8 | 20 | Set-up (6) and one review per board, key-frame set, kit batch, icon batch, motion set and screen (14) |
| Style board | 6 | 6 | |
| Key frames | 10 | 10 | |
| Pipeline and kit (K1) | 12 | 24 | Adds the checks and tests, the switch per family, frames sized from words for 200% text, numerals with both languages' separators, and retiring the prototype |
| Kit art | 10 | 10 | |
| Icons | 25 | 28 | Adds the character route through Godot's toon portrait studio (§21.3) |
| Juice and motion | 10 | 10 | |
| Screens | not costed | 36 | Five screens (32) and routing the menu screens' own kit through the new one (4) |
| **Total** | **81** | **144** | Plus a reserve of up to 20 hours for re-work after failed gates |

The AI artists' share is 64 hours (AIA 36, AIA-2 28). The earlier plan was 50–60 agent-hours plus a human artist's contract.

## 4. Benchmark: 14 checkable qualities

Sources and their limits are in section 4.2. The benchmark games are Clash of Clans (CoC), Clash Royale (CR), Brawl Stars (BS), Squad Busters (SB), Royal Match (RM), Monopoly GO (MGO) and Marvel Snap (MS).

A note on the evidence. Visual specifics come from my knowledge of the games, marked [GK]. Production facts come from sources seen through search-result summaries, marked [S]; the pages themselves could not be opened from this container (section 4.2). No game art is copied here; the benchmark panels in the audit images are written descriptions.

| # | Quality | The check | What the best do | Ref |
|---|---|---|---|---|
| 1 | Layered materials | Every primary button and panel has at least 4 layers: a gradient (light top), a gloss band over the top 30–45%, a dark hue-matched rim of 2–4 pt, and a solid lip or drop of 3–8 pt that gives it thickness. Panels have a bevelled frame and an inner well. No flat primary control. | CR and CoC capsule buttons on thick lips; RM gold frames around felt or parchment wells [GK] | 9-slice raster art [S1, S2] |
| 2 | Display type | One heavy display treatment for big numbers and headers. Every label on art has an ink outline all round of at least 1.5 pt or 12% of its size (§21.8's rule); big numbers also have a hard drop and a gradient fill. No unstroked text over art. Which face carries labels and changing numbers is §21.8's rule (section 4.3). | CR's Supercell-Magic (a customised You Blockhead) everywhere, with a second face for chat [S3] | [S3] |
| 3 | Painted or rendered icons | Every currency, reward and chest icon has a 3D form, a top-left key light, a rim light, a specular highlight and a dark outline that reads at 48 pt (§21.8: a 2-point outline at the size shown). No flat glyphs for things of value. | CoC gems and elixir, CR chests, MGO dice and cash [GK]. Supercell's Creature Shop renders models for in-game UI and marketing [S4] | [S4] |
| 4 | Press feedback | Touch-down sinks 2–4 pt onto the lip or squashes to 92–95%, and darkens. Release springs back within §21.8's 150–250 ms (the benchmarks overshoot; section 4.3), with a light haptic tap and a sound. | Every CR, BS and RM button; BS's Super button flashes when charged [S5] | [S5] |
| 5 | Reward juice | Anticipation (0.3–1 s), a burst, the reveal (the benchmarks overshoot; section 4.3), icons flying in arcs to their counter, the counter rolling up and pulsing on each landing, a sound per step, stronger for rarer rewards. | CR chest opening; RM level complete; MGO payouts [GK]; "Juice it or lose it" [S6] | [S6] |
| 6 | Hierarchy | Exactly one primary action, 1.5–2× the next and the most saturated. At most about 5 things at the second level. It survives a grayscale squint. | CR and BS Battle/Play; RM's single Level button [GK] | [S7] |
| 7 | Motion and idle life | Every screen change animated, in §21.8's 150–250 ms. Popups ease in over a dimmed scene. At least 3 idle loops on home (shine sweeps, bobbing, a breathing CTA). No hard cuts. A reduced form for each (§20.8). | RM's motion "communicates simplicity, polish and focus" [S8]; CR shine sweeps [GK] | [S8] |
| 8 | Colour roles and value | Fixed semantic hues (green go, gold primary, red danger, blue neutral, purple epic) and a rarity ladder. Interactive things at least 2 value steps off the background. | CR rarity colours carried through cards, chests and text [GK] | [GK] |
| 9 | Character presence | Home shows a live character (real-time 3D or skeletal). Rewards and offers are framed with character art. | BS's 3D Brawler idling in the lobby; the CR King's emotes [GK]; Supercell designs characters to read "in miniature" [S9] | [S9] |
| 10 | Phone scale and thumb reach | Targets of at least 48 pt (§21.8), primaries about 1.5× that. Bottom nav of 3–5 items, the main CTA bottom-centre, text of at least 13 pt (§21.8), at 200% text too. | CR, BS and SB bottom tabs; BS joysticks sized to the device [S5] | [S10] |
| 11 | One component system | At most about 4 button styles, 2–3 frames, 1 ribbon, 1 badge and 1 currency pill. Identical radius, stroke and drop everywhere. A new screen needs no new parts. | RM's follow-up reused its UI almost unchanged [S11] | [S11] |
| 12 | Minimal gameplay HUD | Persistent HUD at most about 15% of the screen. Information shown in the world where it can be (bars over units). | CR battle shows only the hand, elixir and timer [GK] | [S12] |
| 13 | Light behind UI | Modals dim the scene. Rewards sit on a sunburst. Home sits on a lit scene with a vignette. One light direction on every panel. | CR and CoC reward sunbursts; MGO's lit board [GK] | [S4] |
| 14 | One art-direction idea | The whole UI follows from one word or tone, and every component expresses it. | MGO's "timeless" (a Webby for art direction) [S13]; SB's "cute-but-badass" [S14] | [S13] |

### 4.1 What this says about production

These studios hand-author their raster UI. Their key icons and props are rendered from 3D and painted over. Motion comes from authored animation plus code tweens.
- Supercell's UI postings ask for Photoshop and Adobe Animate [S1].
- Community tooling shows Supercell's runtime `.sc` format carries "almost all 2D graphics (UI, VFX, particles…)" exported from Animate [S15].
- The Creature Shop makes renders used in in-game UI [S4].
- Scopely's MGO UI artists work in Photoshop and Illustrator; more than 100 people across 6 countries worked on the game's art and development [S13].

No source suggests procedural chrome at these games.

### 4.2 Sources

All were seen through search-result summaries. This container's network policy refused direct fetches of supercell.com, adobe.com and funovus.com, so claims tagged [S] rest on the summaries.

- S1: https://hitmarker.net/jobs/supercell-senior-ui-artist-2312825 and https://supercell.com/en/careers/uiux-artist-moco/1736197
- S2: https://docs.unity3d.com/ru/2020.2/Manual/9SliceSprites.html
- S3: https://www.fontsinuse.com/uses/66357/clash-royale-mobile-game
- S4: https://www.adobe.com/products/substance3d/magazine/supercell-helsinki-creating-stylized-content-for-clash-of-clans-and-clash-royale.html
- S5: https://www.pocketgamer.com/articles/076234/r/
- S6: https://rpgplayground.com/research-making-a-juicy-game/ (Jonasson and Purho, "Juice it or lose it", 2012)
- S7: https://binus.ac.id/bekasi/2025/03/analysis-towards-ui-ux-of-clash-royale-towards-the-gameplay/
- S8: https://funovus.com/blogs/royal-match-dominates-match-3-what-can-all-designers-learn
- S9: https://www.pocketgamer.biz/gdc-supercell-expanding-the-clash-of-clans-ip
- S10: https://supercell.com/en/careers/uiux-artist-brawl-stars/1884903
- S11: https://naavik.co/digest/april-13-2023/
- S12: https://bonndoc.ulb.uni-bonn.de/xmlui/handle/20.500.11811/14207?show=full
- S13: https://www.pocketgamer.biz/the-recipe-behind-monopoly-gos-art-style/ and https://winners.webbyawards.com/2025/ai-immersive-games/games-features/best-art-direction/324798/monopoly-go
- S14: https://supercell.com/en/careers/senior-marketing-artist-squad-busters/1739923
- S15: https://github.com/sc-workshop/SupercellSWF-Animate

### 4.3 Where the rubric meets the design document

The rubric describes the benchmark games. Where the design document sets a stricter or different rule, the design document wins (§23.5), and the rubric above says so:
- **Targets and text (quality 10).** T14 first wrote 44 points and 11 points, the benchmarks' figures. §21.8 asks for 48 and 13. The scores in section 5.1 stand: the kit's tests already hold our screens to 48 and 13.
- **Outlines (quality 2).** T14 first wrote 8–15% of cap height. §21.8 asks for at least 1.5 points or 12% of the type's size, which is wider.
- **Type faces (quality 2).** The benchmarks use one heavy face everywhere. §21.8 gives labels and every changing number to Manrope, and Lilita One to large numbers that do not change. Decision D4 (section 12) asks whether to change that.
- **Motion (qualities 4, 5 and 7).** The benchmarks overshoot, and T14 first wrote 80–150 ms springs and 150–350 ms screen changes. §21.8 asks for 150–250 ms, easing out, without overshoot. Decision D3 asks whether to change that.
- **Sound (qualities 4 and 5).** The client has no sound yet (section 10.10). This wave scores them without it.

## 5. Audit

### 5.1 Scores

Each screen was rendered fresh from `dd326ca8` with its shot script. The side-by-side images show ours, the design's, and a benchmark description:
- `audit-home.png`
- `audit-heist.png`
- `audit-result.png`
- `audit-character.png`
- `audit-settings.png`

Scores are 0–5, where 5 is the benchmark at its best. Motion (4, 5, 7) is scored from the code and the shots' moments, since stills cannot show it; that is the weakest evidence here.

| # | Quality | Home | Heist | Result | Character | Settings | Mean |
|---|---|---|---|---|---|---|---|
| 1 | Layered materials | 2 | 2 | 2 | 2.5 | 2 | 2.1 |
| 2 | Display type | 1.5 | 1.5 | 2 | 2.5 | 1 | 1.7 |
| 3 | Painted icons | 2.5 | 2 | 2 | 2 | 2 | 2.1 |
| 4 | Press feedback | 2 | 2 | 2 | 2 | 2 | 2.0 |
| 5 | Reward juice | 1.5 | 2 | 1 | 1 | 1 | 1.3 |
| 6 | Hierarchy | 1.5 | 3 | 3 | 3 | 2.5 | 2.6 |
| 7 | Motion and idle | 2 | 2 | 1.5 | 2 | 1.5 | 1.8 |
| 8 | Colour and value | 2 | 2.5 | 2 | 2.5 | 2 | 2.2 |
| 9 | Character presence | 1 | 3 | 1.5 | 3.5 | 0.5 | 1.9 |
| 10 | Phone scale and reach | 3 | 3.5 | 3.5 | 3 | 3.5 | 3.3 |
| 11 | Component system | 3 | 3 | 3 | 3 | 3 | 3.0 |
| 12 | HUD economy | 2.5 | 3 | 3 | 3 | 3 | 2.9 |
| 13 | Light behind UI | 3 | 3 | 2.5 | 3 | 1.5 | 2.6 |
| 14 | One idea | 1.5 | 1.5 | 1.5 | 1.5 | 1.5 | 1.5 |
| | **Mean (out of 5)** | 2.1 | 2.4 | 2.2 | 2.5 | 1.9 | **2.2** |

**Overall.** The plain mean is 2.2 out of 5 (2.21 unrounded), which is 44% of Clash level. Weighting the six qualities that separate premium from competent (1, 2, 3, 5, 7, 14) double gives 2.08, or 41.5%. Against the owner's bar of 7 (section 1), 2.2 is **about 30% of the bar** (31%).

What each screen shows:
- **Home.** Everything is equal weight: about fifteen pills and badges of the same size, and no single primary action. That contrasts with CR's one giant Battle button. Labels are small Manrope without stroke, over a busy scene.
- **Heist.** This is the strongest screen. It has the crew's rendered busts, and its layout matches the design. But the timer sits on a cream pill, and every word is Manrope without stroke. The HUD reads as a web overlay, not as part of the game.
- **Result.** The reward is one flat tile, with no anticipation, flight or count-up. A long sentence of prose and a "961-byte replay" line compete with the reward.
- **Character.** This is the best material work: a 3D character on a plinth, and a stroked LEVEL UP. Prose cards still carry the information, where the benchmark uses icon-and-number rows.
- **Settings.** An app's settings page in game colours: thin rows, small icons, no frame or ribbon.

What we already do well, and should keep:
- accessibility (text scale, high contrast, left-handed play);
- a real token system;
- the 3D world behind the UI;
- live-rendered character portraits;
- budget discipline.

### 5.2 The design scored the same way

Screens v3's five matching stills (`art/design/stills/screens/` 01, 02, 07, 11 and 19), scored as one set:

| # | 1 | 2 | 3 | 4 | 5 | 6 | 7 | 8 | 9 | 10 | 11 | 12 | 13 | 14 | Mean |
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
| Screens v3 | 2.5 | 2 | 2.5 | 2.5 | 2 | 2.5 | 2.5 | 2.5 | 2 | 2 | 2 | 3 | 3 | 2 | 2.4 (2.36) |

Where v3 sits above us:
- a little more gloss;
- its CSS press states and 86 keyframe animations (from `design-system.md`, section 5.1);
- the result's study card.

Where it sits below us:
- text at 10–11 pt, under §21.8's floor (row 10);
- 852 colours and 402 shadows, where we have a token system (row 11).

A perfect port would gain about 0.15 (2.36 against 2.21). The gap from the bar is in the target, not in the port.

## 6. The way forward: options, ranked

Ceilings are scores out of 5 on the rubric, where 5 is Clash level, with the share of Clash level and the share of the owner's bar (7, section 1). Today is 2.2: 44% of Clash level, 31% of the bar. Costs are agent-hours for the whole wave, screens included.

| Rank | Option | Ceiling | Cost (agent-hours) | Risk | Fit with Godot Compatibility and §21.3 |
|---|---|---|---|---|---|
| 1 | **A + D. An authored-asset pipeline, authored by an AI UI artist.** UI art authored as SVG/HTML (from the design's own sources) and as three.js scenes, baked offline in headless Chromium into atlases: 9-slices, sprites and baked numerals; icons rendered from 3D and finished in 2D. Scored by C. | 3.75–4.25: 75–85% of Clash level, 54–61% of the bar (section 9.4) | 144 (section 3.7): the AI artists 64, the pipeline and kit 24, the screens 36, the gate 20 | Agent-authored art can be generic without key frames and a reviewer, which is why C goes with it. Texture memory: a 1024² atlas is 4 MiB of video memory uncompressed (section 10.1). High contrast needs its own bake. | Good. Textured quads are cheaper per pixel than `rb_box`'s signed-distance shader. One atlas batches. The proof is at 147 calls (section 7). No post-processing. Words stay live, so the strings tables and text scale still work. |
| – | A alone: the same pipeline with an engineer choosing the look and no artist role | 3.5–4.0: 70–80% of Clash level, 50–57% of the bar | about 80 (K1 24, the screens 36, the gate 20): no style board, key frames or rendered icons | The look is tuned by an engineer, without a board the owner approves | Same as A + D |
| 2 | **C. Process: a standing art director, the rubric and a quality gate.** Goes with A + D; it is not an alternative to it. | No pixels by itself; +0.25–0.5 from better choices | 20 in this plan: 6 to set up, then about 1 hour a review (section 3.2) | Low. A gate that only checks itself; the owner calibrates the reviewer at G2. | Neutral |
| 3 | **B. A much stronger shader and material system.** Grain, a lit bevel from the signed distance, gradient text through a canvas shader, glow | 2.25–2.75: 45–55% of Clash level, 32–39% of the bar | 25–35, plus the screens | Per-pixel cost on low-end phones (every panel pays for noise and lighting each frame). GLSL ES 3.0 limits. Icons and type stay as they are. Each look is still tuned by numbers rather than drawn. | Medium. Fill rate rather than draw calls is the risk. §21.3 forbids full-screen post-processing, so glow and bloom must stay per item. |

The owner has chosen an AI UI artist over a human one (D, section 9). It turns A from "an engineer's pipeline" into an art track with an author. What it still cannot reach on its own, and how the gate covers that, is in section 9.4.

## 7. Proof: the heist HUD on authored art

**What was rebuilt.** Everything in §21.8's heist HUD:
- the laws here and the clock;
- the alarm's six bells;
- the loot panel with its bag, Room, Left, the load bar and its target tick;
- the crew's five portraits with their pips, health and names;
- the Sage's disc, Cast and Get out.

It is drawn over the same heist moment as the deployed screen, with the same data, using `tests/shots/screen_heist.gd`'s MANIFEST crew of five at the vault moment.

**Images.**
- `proof-heist-hud.png`: before, after and the design.
- `proof-heist-top.png` and `proof-heist-bottom.png`: detail crops.
- `proof-atlas.png`: the whole atlas.
- `proof-motion.png`: the press and the coin flight as frames.
- `proof-high-contrast.png`: before and after with high contrast on.

**How it is made.**
- `tools/ui_research/bake_hud.js` draws 75 pieces as SVG in headless Chromium:
  - lit gold bevels (`feSpecularLighting` on the rim's alpha);
  - enamel grain (`feTurbulence`), an inner shadow under the rim, a gloss band and studs;
  - buttons with a thick lip and a sunk pressed face;
  - painted icons (the door, the wand, the bag, three bell states, gems);
  - numerals in four finishes, each with a gradient fill, a thick ink stroke and a hard drop.
- `tools/ui_research/pack_atlas.py` packs them into one 1024² atlas (lossless WebP, 366 KB; a high-contrast twin of 244 KB) with a manifest of regions and 9-slice margins.
- In Godot (`client/prototypes/ui_quality/`):
  - `UiqArt` turns the manifest into `NinePatchRect`s, `AtlasTexture` sprites and glyph rows;
  - `UiqHud` lays out the HUD;
  - `UiqMedal` draws a portrait.
- Words stay live `Label`s (Lilita One, a multichannel distance field, one ink outline) from the strings tables (`HUD_*`, `HEIST_*`). §21.8 gives labels to Manrope; using Lilita One for them is decision D4 (section 12).

**Budget.** The same frame with nothing on top costs 77 draw calls. With the deployed HUD it costs 137; with this HUD, 147, under §21.3's 150. (T16 re-measured on 28 October: 147 with this HUD, 136 with the deployed one. Section 10.1 sets one method for every screen.)

Getting there taught three rules the kit will need:
1. **One atlas.** Separate PNGs cost 50 or more extra calls.
2. **Words in their own z layer above the art,** so art and text batch apart. A label's separate drop shadow is a whole extra pass per label, which cost 26 calls, so labels have a thick outline and no drop. The baked numerals keep their drop.
3. **Never below z 0.** The 3D world is drawn there; a portrait at z −1 vanished behind it.

**What it shows.**
- The materials have depth, light and grain, which code-drawn panels do not.
- Numbers read as game type, not app type.
- Buttons look pressable.
- Every icon has an outline and a highlight.

**High contrast (§20.8).** The bake runs twice: the same pieces in the same places, the second time on near-black enamel with no grain and a fainter gloss. That gives `atlas_hc.webp` (244 KB), which `UiqArt` loads when the setting is on. It is shown in `proof-high-contrast.png` against the deployed HUD in high contrast, and still costs 147 draw calls. An accessibility variant is one more bake, not a second set of drawing code.

**Motion.** `proof-motion.png` (`tests/shots/uiq_motion.gd`, curves in `UiqJuice`) shows five moments:
- Top: Get out pressed and let go. It sinks onto its lip and squashes to 92%, then springs back past its size with a back-ease and settles, all within 0.4 s. That breaks §21.8's motion rule (150–250 ms, no overshoot); the plan follows §21.8 unless the owner decides otherwise (D3, section 12).
- Below: coins fly in a stagger along an arc into the loot panel's bag. The number rolls up as each lands and the panel pulses. The lower row's columns are fractions of the flight, not the stamped times.

These are the curves a screen would tween along. A still strip is how the art director would judge motion.

**What it does not show.**
- An idle shine sweep, and sound.
- 200% text: the 9-slices stretch, but the prototype lays the HUD out at fixed sizes. A kit version would size its frames from the words, as the kit's boxes do now. The plan makes this K1's job (section 3.2, step 4).
- Rendered icons: the HUD's icons are vector paintings. Section 9 shows the rendered route the AI UI artist would use.

Against the rubric, the heist goes from 1.5–2 to about 3.5 on qualities 1–3. On qualities 1–3, that is roughly what one agent day of option A buys. It is also the wave's target for every screen (section 3.6).

**Findings for the kit's owners (not fixed here: not my files).** Both are risks in section 11.
- In one canvas item, a texture rect and `Portrait.draw_disc`'s textured polygon drew wrongly together on this renderer. A white square showed in place of the ring. Separate canvas items fixed it.
- Rendering the shot ends with a `malloc_consolidate()` abort *after* the PNG is written. It happens on `screen_heist.gd`'s path as well as mine.

## 8. Files

- `docs/art/ui-quality/`: this report, the audit and proof images, and `ai-artist-icons.png`.
- `tools/ui_research/`:
  - `bake_hud.js`: the bake;
  - `pack_atlas.py`: the atlas;
  - `compare.py`: the side-by-side images, kept under 400 KB.
- `client/prototypes/ui_quality/`: `uiq_art.gd`, `uiq_hud.gd`, `uiq_medal.gd` and `art/`.
- `client/prototypes/ui_quality/uiq_juice.gd`: the motion curves.
- `client/tests/shots/uiq_motion.gd`: the motion strip.
- `client/tests/shots/uiq_heist_hud.gd`: the before and after shots.
- `tools/ui_research/icons.html` and `bake_icons.js`: the AI UI artist's icons. Run `npm ci` in `tools/ui_research/` once for three.js (0.184.0, pinned). Playwright is not pinned there; it is the container's own (1.63.0). The plan pins both (section 10.7).
- `tools/ui_research/icons_compare.py`: the icon sheet.
- `client/prototypes/ui_quality/icons/`: the five icons at 256 px.
- `docs/art/ui-quality/crew-today-crop.png`: today's portrait, for the sheet. `OLD=1` gives the before; `HIDE=pause_button,hud,actions_band` gives a fair draw count.

To reproduce:
```
node tools/ui_research/bake_hud.js
MANIFEST=1 CAST=1 MOMENT=vault ESTIMATE=2600 HIDE=pause_button,hud,actions_band \
  bash tools/render/shoot.sh client/tests/shots/uiq_heist_hud.gd after.png
OLD=1 MANIFEST=1 CAST=1 MOMENT=vault ESTIMATE=2600 HIDE=pause_button \
  bash tools/render/shoot.sh client/tests/shots/uiq_heist_hud.gd before.png
```

## 9. The AI UI artist

The owner wants an AI UI artist in place of a human one. This section defines the role, says how it makes art with what this environment really has, proves it on the asset class this report first said needed a human hand, and says where it still falls short.

### 9.1 The role

The AI UI artist (AIA) is a standing agent that **owns the look of every pixel of interface that is not live text or the 3D world**. Its outputs:
- **The style board:** materials (enamel, gold, wood, glass, parchment), type treatments, the outline and glint rules, the studio light, and the hero icons. The owner approves it.
- **Key frames:** a target still for each screen, which becomes the reference.
- **Kit art:** frames and panels as 9-slices, buttons with their pressed faces, bars, rings, ribbons, badges, and baked numerals in finishes.
- **Icons:** currencies, rewards, chests, controls and nav, rendered and finished at 256 px.
- **Motion art:** bursts, sparkles, shine sweeps and coin sprites, plus the timing curves screens tween along (`UiqJuice` is the pattern).

How this differs from the code-drawn chrome the report rejects:
- **Drawn once, offline:** its art is authored and baked into atlases, not drawn every frame by GDScript and one shader.
- **No per-pixel cost on the phone:** it can afford real lighting, reflections, grain and blur, because the phone only shows the result.
- **Judged as art, not as numbers:** AD scores each piece against the rubric before it ships.

It does not own layout, behaviour or text. Screens and the kit stay engineering tracks that take its art.

### 9.2 The method, with what this environment has

What was checked:
- **Image generation: none.** No image-generation tool is connected to this environment, so nothing here is generated from a prompt. Every pixel comes from geometry, light and paint written as code.
- **Blender: not installed.**

What is available and used:
- **Headless Chromium** (Playwright) with WebGL through SwiftShader.
- **three.js 0.184**, from npm, with physically based materials, an environment map for reflections (`RoomEnvironment`), and tone mapping.
- **SVG and HTML/CSS**, including filters: lit bevels, turbulence grain, blur.
- **Canvas 2D compositing.**
- **Godot's own renderer** (its portrait studio already renders the characters).
- **The 43 character `.glb` models** in `client/art/creatures/`.

The icon pipeline, as `tools/ui_research/icons.html` and `bake_icons.js` run it:
1. **Model.** Build the object from geometry: an extruded star with a deep rounded bevel; a lathed drop; a faceted brilliant cut; a chest from rounded boxes, half-cylinders and a painted plank texture (a canvas drawn in code: seams and grain strokes). Characters would come from their `.glb` models, rendered in Godot's toon portrait studio (§21.3; section 10.6).
2. **Light.** One studio for every icon, so the set is consistent by construction:
   - a warm key from the top left;
   - a coloured rim from behind on the right;
   - a soft fill from below;
   - the room's reflections.

   Materials are physically based: gold metal with clearcoat, glassy liquid, a faceted gem with iridescence, and wood.
3. **Render** at 640 px on a transparent ground.
4. **Finish in 2D,** the painter's pass:
   - a soft glow of the icon's colour;
   - a hard ink drop shadow;
   - an ink outline grown from the silhouette, in a dark of the icon's own hue;
   - a painted inner light kept to the shape;
   - four-pointed glints where the key catches.
5. **Downsample** to 256 px.

The same studio, outline and glint rules apply to every icon, so a set of 60 stays one family.

### 9.3 The proof: reward icons the AI-artist way

`ai-artist-icons.png` shows Starlight, Essence, Renown, a chest and a crew badge. Each column has four rows:
- the client's icon today (the design's own, exported at 144 px);
- the icon as the design's result screen draws it;
- the AI UI artist's, at 256 px;
- both at phone size, on the design's reward tile at 96 px and alone at 48 px.

Ruleborn has no chest, so the chest stands beside the loot bag, the game's nearest reward container.

The crew badge is **Pip**, rendered from the character's own model (`skyskipper.glb`, with its painted textures) and standing out of a gold ring. It is shown against today's heist portrait and the design's. It proves the route for every character, Sage and building icon, from the 43 models the game already has. One correction: §21.3 says characters are never drawn in a physically based material, and this badge was lit in three.js's physically based studio. In the plan, character icons are rendered through Godot's portrait studio in the toon look and then finished the same way (section 10.6). Each icon took 10–30 minutes of modelling and two or three rounds of looking at the render and correcting it:
- the first renders were muddy until the tone mapping was changed;
- the gem first read too small at phone size;
- the chest's straps were rotated wrongly.

Scored on the rubric's qualities that apply to icons (5 is Clash level):

| # | Quality | Today and design (same icons) | AI UI artist |
|---|---|---|---|
| 1 | Layered materials | 1.5: flat fills with banded gradients | 4: metal, clearcoat, liquid, facets, wood under gold |
| 3 | Painted or rendered icons | 2: outline and one highlight dash, no form | 4: real form, top-left key, rim light, speculars, ink outline |
| 8 | Colour and value | 2.5 | 3.5: a wider value range; the gem's lighter facets read a little less at 48 px |
| 10 | Readable at phone scale | 3.5 | 3.5: the star and drop read better at 48 px, the gem slightly worse |
| 11 | One component system | 3: same outline | 4: one studio, one outline rule, one glint rule, by construction |
| 13 | Light | 1.5: none consistent | 4: one light direction across the set |
| 14 | One idea | 1.5 | 3: "treasure toys" begins to read; it needs the owner's style board |
| | **Mean** | **2.2** | **3.7** |

The other seven qualities (type, press, juice, hierarchy, motion, character, HUD) are screen-level and do not apply to an icon. The crew badge adds to character presence (quality 9), which scores 1.9 across our screens.

The scores are mine. The comparison is in the image, so the owner can check them by eye.

What 5 would need is in section 9.4.

### 9.4 The honest ceiling

With AD's gate and the owner's approvals, the AI UI artist is likely to reach **3.75–4.25 out of 5: 75–85% of Clash level, 54–61% of the owner's bar** (7, section 1). T14 first wrote "75–85% of the bar"; the figures were shares of Clash level. It falls short in these places:
- **Charm and invention.** Its shapes come from primitives and code. A Clash gem has exaggerated, characterful facets and painted colour shifts that a person invented. The AI artist's gem is correct, not memorable. Mascots, the logo and hand-lettered titles are where this shows most.
- **Painterly texture.** With no image-generation tool here, there are no brushstrokes. Texture is procedural (grain, planks, noise), which reads as clean 3D rather than painted.
- **Taste across a whole set.** The AI artist sees each render and corrects it (every fix in section 9.3 came from looking). But it judges one piece at a time, and drifts unless held to a reference.
- **Frame-by-frame effects.** Bursts and particles can be baked from procedural shapes. Hand-timed effect animation, the Spine or Animate kind, is beyond it.

How the plan covers those:
1. **The owner approves the style board and the five key frames** before production. Invention is concentrated where a human eye decides once, and the AI artist then executes the approved look at volume, where it is strong.
2. **AD scores every piece** on the rubric, at 48 points and in grayscale, against the approved board, and blocks anything under its class's thresholds (section 3.5). That stops drift.
3. **Consistency is enforced in code:** one studio, one outline, one glint, one palette file. The set cannot quietly diverge.
4. **If an image-generation tool is connected later,** it slots in at step 4 of section 9.2 as a texture and paint-over source, under the same gate. That is the most direct way past the painterly limit. It would need the owner's decision first: §21.11 says everything not listed there is "made for this game", and the licence of a generated image must be recorded in the ledger.

## 10. Rules the plan keeps

Each rule below is an acceptance check for the steps in section 3. Where the plan needs a rule in the design document changed, it says so and points to section 12.

### 10.1 Budgets on low-end phones (§21.3)

The phones: the reference device is a mid-range 4 GB Android at 60 frames a second; the oldest supported are a 3 GB Android and the oldest iPhone the iOS build runs on, never below 30 (the design document's reference-device row). The client draws at 1080 × 2340, about 2.8 pixels a point.

| Budget | Rule | How it is checked |
|---|---|---|
| Draw calls | Under 150 on every screen, with its world behind it, at 100% and 200% text and in high contrast (§21.3) | `RENDERING_INFO_TOTAL_DRAW_CALLS_IN_FRAME` in each screen's shot script, which prints "budget: N draw calls" as `uiq_heist_hud.gd` does. One method for every screen. |
| Triangles | The interface adds at most 2,000 triangles a screen (a 9-slice is 18). §21.3's triangle budgets are the world's, and the interface must not eat into them. | The same shot, with and without the interface |
| Atlas size | 1024² for a screen family; 2048² at most, the largest size the OpenGL ES 3.0 standard guarantees on every phone | The bake refuses a larger atlas |
| Texture memory | At most 24 MiB of interface textures resident on any screen. A 1024² atlas is 4 MiB uncompressed (lossless, no mipmaps, as the proof imports it). The high-contrast atlas replaces the normal one; it is never loaded beside it. | Godot's texture-memory monitor in each screen's shot |
| Install size | All interface atlases, normal and high contrast, at most 8 MB in the exported pack (lossless WebP; the proof's two atlases are 610 KB together) | The bake prints the total; `client/export.sh check` reads the pack |

The draw-call figure is tight. The proof's heist is at 147, three under the limit (T16 measured the same 147 again, and 136 for the deployed HUD on the same frame, against the 137 in section 7). T9's notes put other dense screens at 137–142. So:
- every screen uses one atlas for its family, plus the shared kit atlas;
- words go in their own z layer above the art (section 7's rule 2);
- portraits and other textured polygons stay in their own canvas items (section 7's findings);
- a screen over 149 does not merge.

The texture-memory and install-size numbers are new; the design document sets none. They are decision D8 (section 12).

The proof's frame also prints 87,102 primitives with the new HUD and 96,333 with the deployed one. Most of that is the world, and §21.3 allows about 60,000 triangles in a heist. This is the world tracks' question, not the interface's, and is passed to the integrator in `plan-review.md`.

### 10.2 Accessibility (§20.8, §21.8)

- **Targets and text.** 48-point hit areas (§21.8's home layout, from §21.1) and nothing smaller than 13 points (§21.8), at 100%, 150% and 200% text. The kit's pieces test already checks 48 and 13 at 200%; K1 extends it to every texture-backed piece. Frames are sized from their words, so 9-slices stretch with the text. The proof did not do this, and K1 must (step 4).
- **Contrast in both modes.** 4.5:1 and the perceptual check, words with an ink outline measured against the outline (§21.8). Over baked art, the check reads the atlas pixels under each label at their worst point, in the normal and the high-contrast atlas. The HUD over the world is checked over the day, dusk and night skies, as T9's `a11y_tests.gd` does now.
- **High contrast.** §21.8: opaque cards, 3-point outlines, secondary text raised to primary, no glass. Every baked piece has a high-contrast twin that meets this, and the bake refuses a family with a piece missing its twin.
- **Colour.** No information by colour alone (§20.8): rarities and schools carry shape as well as colour. One set of school colours, with no palette switch (§20.8), so there are no colour-blind variants to bake, but every atlas is checked by colour-blindness simulation before G3.
- **Screen readers.** Baked numerals and icon-only controls are pictures, so each keeps its spoken name (the kit's `spoken`), and VoiceOver and TalkBack read the live value.

### 10.3 Motion and reduced motion (§20.8, §21.8)

§21.8 sets every interface movement at 150–250 milliseconds, easing out, without overshoot, with a slight squash on press and rewards flying into their counter. The proof's press springs past its size and settles within 0.4 seconds, which breaks that rule. The plan follows §21.8 unless the owner decides D3 (section 12). The curves live in one file (`art/ui/motion/curves.json`), so either answer is a change of numbers, not of code.

Every motion has a reduced form (§20.8), shown in its frame strip at the gate:

| Motion | Full | Reduced |
|---|---|---|
| Press | Sinks onto its lip, squashes slightly, recovers | Sinks and darkens, no squash |
| Reward sequence | Anticipation, burst, reveal, coins flying in arcs, the counter rolling and pulsing | No anticipation or burst. One coin lands in its counter (the one particle §20.8 keeps), and the counter shows its new value |
| Idle shine on primary buttons | A sweep | None |
| Screen change | Its transition | A cross-fade |

No glint, sparkle or shine flashes more than three times a second (§20.8). Screen shake stays under 4 pixels and can be switched off.

### 10.4 Words, languages and numerals

- **Words stay live.** No word is ever baked into art. Every word comes from the strings tables (`client/i18n/strings.csv`), so translation, text size and screen readers keep working. `tools/client_strings.py --check` already runs in check_all.
- **Both launch languages.** English and Brazilian Portuguese (§20.6). Brazilian Portuguese runs longer, so frames are sized from their words, and every key frame and screen is checked in both. T9's tab bar is already tested in German and Portuguese.
- **Numerals.** Baked numerals cover 0–9 and the marks numbers need: the comma and full stop (English writes 1,234 and Brazilian Portuguese 1.234), the colon, the slash, plus, minus, percent, the multiplication sign and the question mark (the heist's "Left ?", §21.8). Changing numbers use a fixed advance, which is the point of §21.8's tabular figures. Each language's formatting comes from the client's own number formatting, never from the art.
- **Later languages.** §20.6 adds one locale a season after launch. Japanese, Korean and Chinese write numbers with these same digits, so the numerals hold. Their words need a fallback font, as today (`client/ui/fonts/LEDGER.md`).
- **Type faces.** §21.8 gives Manrope to labels and to every number that changes, and Lilita One to large numbers that do not change. The proof uses Lilita One for its labels and baked display numerals for the loot count, which changes. The plan follows §21.8 unless the owner decides D4 (section 12). Lilita One as a multichannel distance field is an import setting on the unmodified font, so its licence is unaffected.

### 10.5 School colours and variants

- Pieces that take a school's colour are baked once in neutral, with their ink, gloss and outline untinted, and tinted per school by vertex colour. Tinting keeps one atlas and still batches; six bakes would cost six times the memory.
- Each school piece carries its school's shape (§21.2), and a law's icon frame is its school's shape (§21.8).
- A law's title on a light school colour sits on a plate (§21.8).
- High contrast is the only other variant (section 10.2). There is no colour-blind palette (§20.8).

### 10.6 Licences and the design document's art rules (§21.11, §21.3, §21.8)

- **Made, not licensed (§21.11).** Every pixel is made by code in this repository, and the sources ship beside the bakes, so the art is "made for this game". The build tools (three.js 0.184.0 under the MIT licence, Playwright 1.63.0 and its Chromium under Apache 2.0 and BSD) are permissive and are not shipped. K1 records them in a tools ledger beside the fonts' ledger.
- **Fonts.** The three faces are under the Open Font Licence with their texts shipped (`client/ui/fonts/LEDGER.md`). Baked numerals are pictures drawn with Lilita One, not font files, and the ledger says so in a new row.
- **No outside art.** No image comes from outside: no stock, no generated image, no game art. The benchmark panels in the audit images are written descriptions.
- **Characters in the toon look (§21.3).** "Characters are not drawn in a physically based material; their portraits are rendered from the imported models in this look." The proof's Pip badge was lit in three.js's physically based studio, which breaks this. In the plan, character, Sage and building icons are rendered through Godot's portrait studio in the toon look, then finished in 2D. That is AIA-2's 3 hours of set-up.
- **Objects.** Whether gold, gems and glass may be lit physically, as interface art, is decision D5. §21.3 asks for "one toon look for everything"; §21.8 asks icons for "the designs' volume: a three-stop gradient, a gloss and a soft drop shadow". The proof's icons use a hard ink drop; the plan uses §21.8's soft drop.
- **Icons** keep §21.8's 2-point outline at the size shown, and are drawn to read on its 24-point grid.

### 10.7 Versions and regeneration

- **Pinned tools.** `tools/ui_bake/package.json` and its lock pin three.js 0.184.0 and Playwright 1.63.0, the version whose Chromium (build 1243) is installed on these containers; Playwright is not pinned today (only three.js is). Node 22 and Pillow 12.3 (which writes the WebP) are recorded too.
- **Every manifest records** its sources' hash (sources, palette, bake scripts) and every tool version.
- **Regeneration.** `node tools/ui_bake/bake.js <family>` rebuilds a family; `--all` rebuilds everything. Bakes are committed with their sources, since the export needs them and the phone cannot bake.
- **Byte for byte.** T16 re-ran both of T14's bakes: the atlas, the manifest and all five icons came out byte-identical. A bake that stops being identical on the pinned tools is a bug.

### 10.8 Checks and their run time

check_all runs about 25 minutes today. The plan adds:

| Check | Where | Time |
|---|---|---|
| `tools/ui_bake/bake.js --check`: every manifest's hash matches its sources; every piece has its high-contrast twin; regions inside the atlas; atlas sizes and the install total | check_all | seconds |
| Client tests: texture-backed pieces at 48 points and 13 points at 200% text; contrast over the baked art in both modes; the material switch's fallback; numerals for both languages | `client/status.py` (check_all) | under a minute added |
| Full rebake, byte for byte: under a minute for the kit, about 2 minutes for 60 icons (at the proof's rates) | K1's and AIA's pre-push run; the integrator's merge run | about 3 minutes |
| Draw calls and texture memory for the five screens at 100% and 200% text and in high contrast: 15 shots at about 47 seconds each, warm (T16 measured one) | K1's and the screen tracks' pre-push run; the integrator's merge run | about 12 minutes |

Putting the last two in check_all would add about 15 minutes to every run. Whether to is decision D9 (section 12). Until it is decided they run before every push and at every merge, and a failure blocks the push.

No test is skipped, disabled or loosened. Tests that check today's code-drawn look keep running until the switch is on everywhere (section 10.9).

### 10.9 Moving screens without a broken in-between state

1. **A switch per material family** in `KitSkin`: gold, leather, card, parchment, glass and the rest of `client/ui/tokens.json`'s materials. Off, the material draws as today. On, it draws from the atlas. A piece missing from the manifest falls back to the code-drawn box and logs it, so a screen is never blank.
2. **A family switches on** only when its pieces and their high-contrast twins pass AD's gate, the contrast tests pass, and every screen's draw calls are no higher than before. Then every screen that uses it changes together, which is the point: no screen is half old and half new.
3. **The menu screens** draw through T10's `ScreenKit`, not `KitSkin`. S3 routes `ScreenKit`'s materials through `KitSkin` (step 10), so they switch with everything else.
4. **Arrangements move later.** The screen tracks change each screen's layout to its key frame after the families are on. A screen that fails its gate keeps its layout on the new materials.
5. **Going back** is one switch off.
6. **The prototype** (`client/prototypes/ui_quality/`) is folded into the kit and deleted at the end of step 4. Until then it ships in the exported pack (the presets exclude only `tests/*`); the integrator should exclude `prototypes/*` (`plan-review.md`).

### 10.10 Sound and haptics

The rubric's press feedback and reward juice ask for a sound per step (qualities 4 and 5). The client has no sound at all yet: no audio player in any script. §21.8 sets the instruments, and §21.11 says sound is generated or public-domain. No agent in this plan makes sound, so:
- the plan's motion fires named events (press, coin landed, counter done, reveal) that a sound track can hang sounds on later;
- haptics already exist (`client/app/haptics.gd`, §21.8's light tap on buttons), and the motion calls them;
- AD scores qualities 4 and 5 without sound in this wave and notes it.

Whether to add a sound track now is decision D7 (section 12).

## 11. Risks

| Risk | What it would do | Mitigation |
|---|---|---|
| The AI artist's work is correct but generic | Screens score 3.5 but do not feel premium | The owner approves the board and key frames (G1, G2); key frames must score 4.0; an image-generation tool, if one is connected, slots in under the same gate (section 9.4) |
| AD agrees with itself, not with the owner | Scores rise while the look does not | The owner calibrates AD at G2; AD re-scores today's screens within 0.2 of section 5.1 at set-up; every score is published beside its image |
| Draw calls over 150 | A screen cannot merge | One atlas per family; words in their own layer; the check before every push; fall back to the code-drawn piece for the costliest part |
| Texture memory on a 3 GB phone | Stutter or a crash on old phones | Two icon sizes (128 and 256 px); per-screen atlases loaded and freed; high contrast replaces, never adds; the 24 MiB check |
| The owner is not available at a gate | Every later day slips | AIA works ahead at risk on its branch and merges nothing; K1 and AIA-2 do not wait on G2 |
| The motion and type rules stay as §21.8 says (D3, D4 not decided) | Qualities 2, 4, 5 and 7 cap lower | The plan works either way; the curves and type treatments are data, so a later decision is a change of numbers |
| A bake stops rebuilding byte for byte | Nobody can tell a real change from noise | Pinned tools; the manifest records versions; the full rebake runs before every push |
| Nothing here runs on a real phone | Frame time on the reference device is unmeasured | Draw calls and texture memory are measured on the same renderer (Compatibility); frame time on the reference device is checked by the developer before release |
| The renderer's known faults (section 7's findings) | A white square in place of a ring; the shot aborts after writing | Textured polygons in their own canvas items; shots check that the PNG was written |
| Usage limits pause an agent | A gate or merge waits | Each agent schedules its own resume and pushes green at least hourly |
| Brazilian Portuguese runs longer | Words overflow frames | Frames sized from their words; every key frame and screen checked in both languages |

## 12. Owner decisions

The first five are in the plan at a glance. Each has a default, so the wave never stops for an answer it does not yet need.

| # | Decision | Why it is needed | Options | Default | When |
|---|---|---|---|---|---|
| D1 | Approve the plan | 144 agent-hours and seven agents, not "about 80" (section 3.7) | Approve; approve a smaller scope (for example A alone, about 80 hours); reject | Nothing starts | Before day 1 |
| D2 | The approved key frames become the visual reference | §23.5: "The designs carry the look: layout, art, motion, the models and the icons." Key frames that replace Screens v3 need that sentence changed | (a) Change §23.5 so approved key frames carry the look where they differ from the designs; (b) keep §23.5, key frames are targets only | (b): key frames keep the designs' layouts and icons' shapes, and push material, type and light | At G2, day 2 |
| D3 | Overshoot on presses and reward reveals | §21.8: "150 to 250 milliseconds, easing out ... without overshoot". Clash-level juice overshoots | (a) Change §21.8 to allow overshoot on presses and reward reveals, at most 350 ms, with the reduced form unchanged; (b) keep §21.8 | (b) | Before day 4 |
| D4 | A display face for labels and changing numbers on art | §21.8 gives labels and changing numbers to Manrope. The proof's labels are Lilita One and its loot count is baked numerals | (a) Change §21.8 to allow Lilita One for labels on art, and baked numerals with a fixed advance for changing numbers; (b) keep §21.8 | (b): labels in Manrope with an ink outline; baked numerals only for numbers that do not change | Before day 3 |
| D5 | Object icons lit physically | §21.3 asks for "one toon look for everything"; the proof's gold, gem and chest are lit physically (section 10.6) | (a) Allow it for interface icons of objects, never characters; (b) every icon in the toon look | Character and building icons start first; object icons wait | Before day 2 |
| D6 | How many icons | §21.9 counts about 390 interface icons, "as Screens v3 draws them". The plan re-authors the 60 most-seen; the other 330 or so stay flat, so two styles show side by side | (a) 60 now, the rest in a later wave (about 140 hours at the same rate); (b) 60 now, and give the rest the new outline and glint rules only; (c) all now | (a) | At G3 |
| D7 | Sound | The rubric's qualities 4 and 5 ask for sound; the client has none (section 10.10) | (a) No sound this wave, events ready for it; (b) add a sound track | (a) | At G0 |
| D8 | Texture and install budgets | The design document sets none (section 10.1) | Approve 24 MiB resident and 8 MB installed, or set others | The proposed numbers | At G0 |
| D9 | What check_all runs | The full rebake and the screen budgets would add about 15 minutes (section 10.8) | (a) In check_all; (b) before every push and at every merge | (b) | At G0 |
| D10 | The wave's target | 3.5 out of 5 is about half the owner's bar (section 3.6) | Accept 3.5; ask for more (and more hours) | 3.5 | At G0 |

What D2, D3 and D4 would change in the design document is written out in `plan-review.md`. Neither T16 nor any agent in this plan edits the design document.

## T14 stopped here

T14 stopped at the wave's end with all four deliverables pushed and green on `claude/ui-research`.

**Done:**
- the benchmark (section 4);
- the audit with five side-by-sides and the design's own scores (section 5);
- the ranked options and the next-wave plan (sections 3 and 6);
- the proof (section 7): the heist HUD on authored art, its motion strip and its high-contrast bake, at 147 draw calls.

**After the owner's revision:**
- the AI UI artist replaces the human artist in the plan (sections 3, 6 and 9);
- four reward icons and a crew badge from Pip's own model prove the method: 3.7 against 2.2 on the icon qualities.

**Not done, for whoever takes this up:**
- the proof at §20.8's 200% text, which needs frames sized from their words;
- an idle shine sweep;
- the benchmark's sources read in full rather than through search summaries: this container could not open supercell.com, adobe.com or funovus.com.

The bakes (`tools/ui_research/bake_hud.js`, `bake_icons.js`, `pack_atlas.py`) are the starting point for K1 and the AI UI artist in section 3. T16 has since revised the plan; see the plan at a glance and `plan-review.md`.
