# Why the interface is not premium yet, and the way there (T14; plan revised by T16 and T17)

The owner says the interface is "not even 30% there". The agents' progress files say 80–90%, and the integrator says "about halfway". This report finds out which reading is right and why. It also says what to do next and shows a proof.

T14 wrote the research (sections 1, 2, 4, 5, 7 and 9). T16 reviewed the plan as the agents who must run it would: T16 rewrote the plan and corrected numbers and rules in sections 1, 4, 5, 7 and 9, then specified the kit in full (`kit-spec.md`) and tested buying against building (`build-or-buy.md`). T17 then rebuilt the plan as **plan v3** on the research in `docs/research/agent-team-operating-model.md`: a gate built from scripted checks, pairwise comparison and the owner's labels in place of 0–5 scores; at most five building agents, in phases; a merge queue; the owner's time spent on a golden set, boards and audits instead of item-by-item approvals; and rules for sessions and tokens. Every change, and every place plan v3 does not follow the research and why, is in `plan-review.md` (round 3). How agents are organised in every wave is `docs/guides/agent-program.md`; what each agent reads first is `docs/guides/agent-brief.md`.

Everything here was measured or rendered from the deployed head (`dd326ca8`). Images are in this folder. Tools are in `tools/ui_research/`.

## Plan at a glance

**What the owner decides, and when (section 12).** Each decision has a default, so the wave never stops for an answer it does not yet need.

| # | Decision | When | Default if not decided |
|---|---|---|---|
| D1 | Approve plan v3: seven building roles, at most five at once, 164 agent-hours plus up to 20 for re-work; a lead and a judge beside them | O1, before phase 0 | Nothing starts |
| D14 | The session settings P1–P6 (section 3.9), each with its exact value | O1 | Agents follow the same rules by hand; no setting is changed |
| D4 | A display face and baked numerals for labels and changing numbers on art (a change to §21.8's type rule) | O2, in phase 0 | §21.8 as written: Manrope for labels and changing numbers |
| D5 | Object icons rendered with physically based light (gold, gems, glass), as interface art | O2, in phase 0 | Character and building icons start first, in the toon look |
| D2 | The key frames the owner labels "pass" become the visual reference in place of Screens v3 (a change to §23.5) | O3, end of phase 0 | Key frames are targets and golden references only; Screens v3 stays the reference for layout and icons |
| D13 | What to do if the usage projection does not fit the weekly limit | End of phase 0 | Three builders at once, icon batches 3 and 4 deferred |
| D3 | Overshoot on presses and reward reveals (a change to §21.8's motion rule) | Before phase 2 | §21.8 as written: 150–250 ms, easing out, no overshoot |
| D11 | CC0 particle sprites as raw material for the reward sequence (a change to §21.11); saves 3 hours | Before phase 2 | §21.11 as written: AIA makes them |

**The wave's target (section 3.6).** Each of the five key screens (home, heist, result, character, settings) passes the gate on every quality that applies to it, at 100% and 200% text and in high contrast, and its family board stands without the owner's objection. The bar is the owner's own pass and fail labels in the golden set, not an agent's score. On T14's 0–5 scale, where today is 2.2, that bar is estimated at about 3.5: 70% of Clash level and about 50% of the owner's bar. The plan's honest ceiling is 3.75–4.25 (section 6).

**The team (section 3.1).** One lead, seven building roles and a judge. A model is chosen per session and never switched inside one.

| Agent | Role | Model | Hours |
|---|---|---|---|
| Lead | Integrator. Seeds and refills the backlog, runs the merge queue, watches status files, writes the owner's digests. Does not build or judge. | Opus 5.5, medium effort | Outside the total; about 16 |
| AD | Art director. Turns the rubric into checks, builds the golden set, calibrates the judge. Phase 0 only. Never authors art. | Opus 5.5 | 9 |
| Gate | The judge. Short read-only runs: one isolated check per visual quality, three samples each. | Fable 5.1; Opus 5.5 only if calibration shows it catches more | 16 |
| AIA | AI UI artist: style board, key frames, kit art, motion art | Opus 5.5 | 42 |
| AIA-2 | AI UI artist on the same studio: the 60 most-seen icons | Opus 5.5 | 28 |
| K1 | Kit owner: the kit contract, the bake pipeline, the texture-backed kit, the UI guards | Opus 5.5 in phases 0–1; a fresh Sonnet 5.5 session in phase 2 | 33 |
| S1 | Heist (the pilot screen) and result, with the reward sequence | Sonnet 5.5 | 14 |
| S2 | Home | Sonnet 5.5 | 8 |
| S3 | Character and settings; routes the menu screens' own kit through the new one | Sonnet 5.5 | 14 |
| | **Total** (T16's plan: 158; section 3.7 has the differences) | | **164** (161 with D11), plus up to 20 of re-work |

A screen that fails the gate twice moves to a fresh Opus 5.5 session; its hours come from the re-work reserve.

**The phases (section 3.2).** A phase starts only when the one before has met its exit criteria. The kit contract and the golden set are frozen before any screen is built.

| Phase | Building at once | Agent-hours | Wall-clock | Exit |
|---|---|---|---|---|
| 0. Calibrate and freeze | 3: AD, AIA, K1 | 43 | about 22 h | Style board and kit contract approved and frozen (O2); key frames and golden set labelled (O3); the judge meets its catch-rate target; backlog seeded |
| 1. Foundations | 4: K1, AIA, AIA-2, S1 (pilot heist) | 58 | about 18 h | Kit families and icon batches 1–2 pass the gate; the pilot heist passes the gate; board 1 (kit and heist) stands |
| 2. Screens | 5: S1, S2, S3, AIA, AIA-2; K1 only in a slot that frees | 62 | about 19 h | Every screen passes the gate; the exceptions queue is empty; the first blind audit is done |
| 3. Polish and harden | up to 5, from the reserve | 1, plus up to 20 | about 6 h | The owner's wave board stands; the second blind audit is done |

About 65 wall-clock hours of agent work: six days at about 12 working hours a day, as before, if the owner answers O2, O3 and board 1 within the working day (board 1's default adds up to 24 hours). At three builders (D13) it is about 12 hours longer.

**The owner's time (section 3.4): about 4½ to 6¼ hours over the wave,** in place of approving items one by one.

| When | What | Minutes |
|---|---|---|
| O1, before phase 0 | Approve the plan, the settings and the defaults (D1, D14, D7–D10, D12) | 20 |
| O2, phase 0 | Approve the style board and the frozen kit contract (D4, D5) | 15 |
| O3, end of phase 0 | Label the golden set, 30–60 items, pass or fail per quality with a one-line critique (D2) | 60–90, once |
| O4, phases 1–3 | Five family boards; each merges after 24 hours unless you object | 70 in all |
| O5, daily | Clear the exceptions queue | 10–20 a day |
| O6, end of phase 2 and wave end | Blind audit of 10–20 items the gate passed | 15–20 each |
| O7, wave end | The wave board (D6) | 20 |

**The gate (section 3.5).** Four checks in order of cost. (1) Scripted checks on every push: budgets, contrast, sizes, text scales, the kit's rules. (2) The judge, on a different model from the artists: one isolated pairwise check per static visual quality against the owner's labelled anchors, sampled three times; it blocks only on three fails out of three and sends split or "Unknown" verdicts to the owner's exceptions queue. (3) The merge queue's guards on the combined tree. (4) The owner's boards and blind audits, for what a still cannot show (presses, juice, motion) and to measure the judge. The judge may block nothing until it catches at least 80% of the owner's fails in the held-out third of the golden set. The 14-quality rubric stays as the vocabulary; section 3.5 says how each quality is checked.

**Merging (section 3.8).** One change at a time, as soon as it is ready; the hourly cycle is only the longest wait. Each agent brings main into its own branch and resolves its own conflicts. Main only fast-forwards to a commit whose checks passed on exactly that tree, so the guards (the database's `node server/load.mjs --check`, and the UI's budget, contrast, draw-call and chrome guards) always run on what lands.

**The kit ([kit-spec.md](kit-spec.md)).** 47 components in 35 baked skins (today: 108 materials), each with its states (normal, pressed, disabled, selected, locked, attention, loading, high contrast, reduced motion), one set of tokens, names and files, a catalogue sheet, rules for adding a component, and what happens to every part of today's kit. K1 owns it; it is frozen at the end of phase 0 and changes after that only through K1 with the lead's approval.

**Build or buy ([build-or-buy.md](build-or-buy.md)).** Build. §21.11 allows outside fonts (OFL) and code (permissive) but no outside art, paid or free. Nothing on the market supplies Ruleborn's identity, characters or icons, and the kits that come closest look like other games. The one adoption worth asking for is CC0 particle sprites, which saves 3 hours (decision D11). No purchase is recommended (D12).

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
- **Option C, an art-director gate**, checking the AI artist's work against the owner's labels (section 3.5).

The ranked options with costs are in section 6.

The two proofs show that this works in this engine, within budget, and is much richer than code-drawn chrome:
- **The heist HUD (section 7):**
  - rebuilt from art baked offline in headless Chromium: lit bevels, grain, studs, painted icons, numerals with stroke, drop and gradient;
  - one 1024² atlas;
  - 147 draw calls against 137 today, under §21.3's 150;
  - every word still live text from the strings tables.
- **The reward icons (section 9):** Starlight, Essence and Renown, plus a chest and a crew badge from Pip's own model, modelled and lit in three.js and finished in 2D at 256 px. Icons are the asset class this report first said needed a human hand. They score 3.7 out of 5 on the rubric's icon qualities, against 2.2 for today's.

Both proofs rebake byte for byte: `bake_hud.js` in 23 seconds for its 75 pieces twice, `bake_icons.js` in 10 seconds for five icons (measured by T16 on this container).

### 3.1 The agents, their models and their files

Every track that built the interface has stopped, so the wave needs new agents. Each owns the files below; new files are allowed under them. Nobody else edits them: one owner per file, shared files included. A change another agent needs is a request to the file's owner (section 3.8), never an edit.

| Agent | Model, and why | Branch | Owns | Takes over from |
|---|---|---|---|---|
| Lead | Opus 5.5, medium effort: triage and planning need judgement, but the merges are mechanical | main (`claude/videogame-project-analysis-ewkkk2`) | `docs/progress/backlog.json`, `docs/progress/requests.md`, the owner's digests, and every file no track owns | the integrator |
| AD, art director | Opus 5.5: writing pass and fail criteria and choosing anchors is judgement work | `claude/ui-ad` | `docs/art/ui-quality/gate/**` except `gate/verdicts/`, `tools/ui_gate/**` | (new) |
| Gate, the judge | Fable 5.1, a different model from the artists, which reduces self-preference; Opus 5.5 only if it catches more of the owner's fails on the held-out labels (section 3.5) | `claude/ui-gate` | `docs/art/ui-quality/gate/verdicts/**` | (new) |
| AIA, AI UI artist | Opus 5.5: judgement-heavy visual work, where Sonnet trails | `claude/ui-artist` | `art/ui/**` except `art/ui/icons/`; `client/ui/art/**` (written only by the bake) | (new) |
| AIA-2, AI UI artist for icons | Opus 5.5, as AIA | `claude/ui-artist-icons` | `art/ui/icons/**`, `client/tests/shots/icon_*.gd` | (new) |
| K1, kit owner | Opus 5.5 for the contract and the component API (phases 0–1); a fresh Sonnet 5.5 session for requests and fixes against the frozen contract (phase 2) | `claude/ui-bake` | `docs/art/ui-quality/kit-spec.md`, `tools/ui_bake/**`, `tools/ui_research/**`, `client/prototypes/ui_quality/**`, `client/tests/shots/uiq_*.gd`, and T9's files: `client/scripts/ui.gd`, `client/ui/**` except `client/ui/art/`, `tools/ui/`, `client/tests/ui_kit_tests.gd`, `client/tests/a11y_tests.gd`, `client/tests/shots/ui_*.gd` | T9 (UI kit), T14 (the proof), AD (the kit spec) |
| S1, heist and result | Sonnet 5.5, medium effort: spec-following work against a frozen kit and golden screens, which the gate checks | `claude/ui-screens-heist` | T5's `heist_screen.gd`, `heist_hud.gd`, `result_screen.gd`, `replay_screen.gd`, `client/world/fx_*.gd` | T5 |
| S2, home | Sonnet 5.5, as S1 | `claude/ui-screens-home` | T4's `client/scripts/home.gd` | T4 |
| S3, character and settings | Sonnet 5.5, as S1 | `claude/ui-screens-meta` | T7's `character_screen.gd`; T10's files (`client/scripts/screen_*.gd`, `settings_screen.gd`, `client/tests/shots/screen_*.gd`) | T7, T10 |
| Search and log triage | Haiku 5.5 subagents, under 100k tokens: retrieval is cheap and low-risk | none | none | (new) |

**Escalation.** A screen that fails the gate twice (section 3.5) moves to a fresh Opus 5.5 session, which starts from the screen agent's handoff (section 3.9) on the same branch. If the pilot heist needs that escalation, the lead tells the owner at the end of phase 1 whether the phase 2 screens should start on Opus 5.5, with the hours it costs.

Three notes on files:
- **The bake writes into AIA's folder.** K1 owns the bake scripts; AIA owns the art sources in `art/ui/` and the baked results in `client/ui/art/`. Only the bake writes there, so the two never edit the same file. `art/` is outside the Godot project, so sources are never imported or shipped.
- **Hotspot files have one owner each.** `client/ui/tokens.json`, the theme and `KitSkin` are K1's; `project.godot`, autoload registries and `client/export_presets.cfg` are the lead's. `client/i18n/strings.csv` has one owner at a time, named in the backlog; an agent that needs new string keys asks that owner (section 3.8). `art/ui/palette.json` is generated from the tokens by the bake.
- **Character icons need T7's portrait studio** (`client/world/portrait*.gd`), read only, through AIA-2's own shot scripts (section 10.6).

`docs/art/3d-program.md`'s track table needs these rows changed: the new rows are in `plan-review.md` X13.

### 3.2 Phases

A phase starts only when every exit criterion of the one before is met and committed. The lead checks them, records the result in the backlog, and starts each agent's next phase in a fresh session (section 3.9).

| Phase | Entry | Work | Building at once | Exit |
|---|---|---|---|---|
| 0. Calibrate and freeze | D1 approved at O1; backlog seeded by the lead | AD builds the gate and the golden set (step 1). AIA makes the style board (step 2), then the key frames (step 3). K1 freezes the kit contract and starts the pipeline (step 4). | 3 | The style board and kit contract v1 are approved (O2) and committed as frozen. The owner has labelled the golden set (O3). The judge meets its target on the held-out third, or each quality that misses is moved to the owner (section 3.5). The ownership map and backlog are committed. The usage projection is made (section 3.9) and D13 answered if needed. |
| 1. Foundations | Phase 0's exit | K1 finishes the pipeline and the texture-backed kit (step 4). AIA makes the kit art (step 5). AIA-2 starts the icons (step 6). S1 builds the pilot heist from the kit alone (step 7). | 4 | The kit families the heist uses, and icon batches 1–2, pass the gate and are merged. The pilot heist passes the gate. Board 1 (kit and heist) stands: the owner let it stand, or 24 hours passed without an objection. This is the one board phase 2 waits for, because a contract or style error caught here is not copied into three screens. |
| 2. Screens | Phase 1's exit; D3 and D11 answered or defaulted | AIA makes the motion art (step 8). S1 moves the result screen (step 9), S2 home (step 10), S3 character and settings (step 11). AIA-2 finishes the icons. K1 answers component requests in a slot that frees. | 5 | Every screen passes the gate at 100% and 200% text and in high contrast. Boards 2–5 are posted. The exceptions queue is empty. The first blind audit (O6) is done. |
| 3. Polish and harden | Phase 2's exit | Re-work from the boards, the audit and the exceptions, from the 20-hour reserve (step 12) | up to 5 | No board has an open objection. The second blind audit is done. The owner's wave board (O7) stands. |

**Concurrency.** At most five building sessions at once, plus the lead and short gate runs. Idle capacity is never a reason to raise the cap: an agent that finishes early takes a task from the backlog's idle queue (asset-import checks, tests, overflow sweeps in Brazilian Portuguese at 200% text, kit documentation) or stops. If usage runs hot, the cap drops to three (section 3.9).

### 3.3 The steps

Each step lists its owner, phase, what it reads and writes, what it waits for, how the gate checks it, and its hours. The gate's methods are in section 3.5. Every step is one or more backlog tasks (section 3.8), claimed one per session.

**Step 1. AD builds the gate and the golden set.** Owner: AD. 9 hours. Phase 0. Waits for nothing; calibration waits for O3.
- Reads: sections 4, 5 and 10 of this report; `docs/research/agent-team-operating-model.md`; `docs/design/ruleborn-game-design-v3.7.txt` §21.8, §20.8 and §21.10.
- Writes:
  - `gate/rubric.md`, version 1: the 14 qualities of section 4 as pass and fail criteria, with the design document's rules folded in (section 4.3), the extreme anchors of each (what a clear pass and a clear fail look like), and the method for each quality and asset class (section 3.5). Every later edit is a new version and is re-validated.
  - `gate/golden/items.json` and the images it lists: 30–60 items for the owner to label. Natural fails: today's five screens and Screens v3's five stills. Likely passes and borderline cases: T14's heist proof and its five icons, AIA's style board and the five key frames at 200% text and in high contrast. Planted fails: copies of key frames with one quality broken (labels without stroke, a flattened material, a flat icon, one value step between control and ground). At least a third of the items are expected to fail and at least a quarter to be borderline.
  - `gate/golden/labels.md`: the owner's form, one row per item and quality: pass or fail, and a one-line critique.
  - `gate/prompts/<quality>.md`: one prompt per judged quality (section 3.5).
  - `tools/ui_gate/`: `sheet.py` (a contact sheet at phone size, at 48 and 96 points and as a grayscale thumbnail, §21.10; a frame strip from a list of frames; stills downscaled to 960 pixels on the long edge, and full-resolution crops of named regions); the image checks of section 3.5 (value steps, the HUD's share of the screen, colour-blindness simulation); `calibrate.py` (the split into thirds, catch rates per quality, the audit sample).
  - `gate/calibration.md`: the split, the results per quality, the judge model chosen, and the rubric version they hold for.
- Done when: the judge meets the target on the held-out third, or each quality that misses is listed as owner-checked; the rubric and golden set are committed as version 1.

**Step 2. AIA makes the style board.** Owner: AIA. 6 hours. Phase 0. Waits for nothing.
- Reads: §21.2 and §21.8 (colours, type, icons), this report's sections 4 and 9, `tools/ui_research/`.
- Writes: `art/ui/board/board.html` and `board.png`. The board shows:
  - the material set (enamel, gold, wood, glass, parchment), dressing §21.8's surfaces (the violet card, dark glass, leather, parchment and gold) in §21.2's and §21.8's own colours: it adds grain, bevel, gloss and light, not new hues (new hues would need §21.8 changed, to be raised at O2);
  - the type treatments, both under §21.8 as written and under decision D4, so the owner can choose at O2;
  - the outline and glint rules and the studio light;
  - four hero icons;
  - the high-contrast form of each material.
- Checked by: the scripted checks for contrast in both modes and colours from the tokens. The board is not judged: it is part of the contract the owner approves at **O2**, with K1's frozen kit contract.

**Step 3. AIA makes five key frames.** Owner: AIA. 10 hours. Phase 0. Waits for O2.
- Reads: the approved board; the design's own HTML for the five screens (`art/design/stills/screens/` 01, 02, 07, 11 and 19 and their sources); §21.8's home and heist layouts.
- Writes: `art/ui/keyframes/<nn>-<screen>.html` and `.png` for home, heist, result, character and settings, at 1080 × 2340, each also at 200% text and in high contrast.
- Keeps: §21.8's arrangements, 48-point targets, 13-point text and live words from the strings tables, in English and Brazilian Portuguese.
- Checked by: the scripted checks; then the owner labels them in the golden set at **O3**. A key frame labelled pass on a quality becomes that quality's golden reference for its screen. A key frame labelled fail on a quality gets one round of re-work, re-labelled in the next exceptions queue.

**Step 4. K1 freezes the kit contract and builds the pipeline and the texture-backed kit.** Owner: K1. 33 hours: 16 in phase 0, 15 in phase 1, 2 in phase 2. Waits for nothing to start; switches material families on as AIA's kit art passes the gate.
- Reads: `kit-spec.md`; `tools/ui_research/` (`bake_hud.js`, `bake_icons.js`, `pack_atlas.py`), `client/prototypes/ui_quality/`, `client/ui/kit_skin.gd`, T9's notes (`docs/art/tracks/ui-kit.md`).
- Phase 0 writes the **kit contract**: `kit-spec.md` sections 2–6 marked frozen, version 1 (tokens, states, the 47 components, names, the manifest's format and the functions screens call), and the ownership map of section 3.1's hotspot files. After the freeze a change to the contract goes through K1, needs the lead's approval, and counts as delivered only when every consumer has acknowledged it (`docs/guides/agent-program.md`).
- Phases 0–1 write:
  - `tools/ui_bake/`: one bake for every family. `bake.js <family>` renders the sources in `art/ui/` and packs atlases with a manifest of regions and 9-slice margins. `--check` compares the sources' hash with the manifest's in seconds.
  - `client/ui/art/`: written only by the bake: `<family>.webp`, `<family>_hc.webp` and `<family>.json`.
  - `KitSkin`: texture-backed materials behind a switch per material family, with the code-drawn box as the fallback (section 10.9); today's 108 materials mapped onto the kit's 35 skins (`kit-spec.md` section 8.2).
  - The catalogue sheet, `client/tests/shots/ui_kit_catalogue.gd`: every component in every state, normal and high contrast, at 100% and 200% text, in both languages, with a test that it covers the inventory (`kit-spec.md` section 6.4).
  - `tools/ui_bake/check_screens.py` in check_all: screens may not add chrome of their own (`kit-spec.md` section 7).
  - `tools/ui_bake/guard.sh`, the UI guards in one command for every pre-merge run: the full rebake byte for byte, and draw calls, texture memory and contrast for the five screens at 100% and 200% text and in high contrast, against the counts recorded in `tools/ui_bake/budgets.json` (section 3.8).
  - Labels in their own z layer above the art, so art and words batch apart (section 7's rule 2).
  - Frames sized from their words, so 200% text works (the proof did not do this).
  - Baked numerals with a fixed advance, and the separators of both launch languages (section 10.4).
  - School pieces baked once in neutral and tinted per school (section 10.5).
  - Tests, and the checks in `tools/check_all.sh` (section 10.8).
  - The fonts' licence ledger rows for anything new (section 10.6).
- Phase 2: a fresh Sonnet 5.5 session answers component requests against the frozen contract (`kit-spec.md` section 7) and fixes what the screens find.
- Done when: section 10's checks pass; the heist proof runs on the kit at 147 draw calls or fewer; and the prototype in `client/prototypes/ui_quality/` is no longer read by anything, then deleted.

**Step 5. AIA makes the kit art.** Owner: AIA. 16 hours. Phase 1. Waits for phase 0's exit and for K1's pipeline.
- Reads: the board and the key frames; `kit-spec.md` (the 47 components, their states and the 35 skins).
- Writes: `art/ui/kit/<skin>/<shape>.svg`: the 35 skins with a face per state (normal, pressed, disabled, locked), the overlays (selected rim, lock, attention badge, spinner), and numerals in four finishes with the full set of marks. Each comes with its high-contrast twin.
- Order: in two batches, the heist's families first, so the pilot can start.
- Checked by: the scripted checks (every piece has its twin, contrast in both modes, the catalogue's coverage); the judge on the catalogue sheet at phone size, on qualities 1, 2, 8 and 13, against crops of the golden key frames and the approved board.

**Step 6. AIA-2 makes the icons.** Owner: AIA-2. 28 hours: 16 in phase 1, 12 in phase 2. Waits for phase 0's exit; object icons also wait for D5.
- Reads: the board, `art/ui/palette.json`, the studio in `tools/ui_research/icons.html`, the 43 models in `client/art/creatures/`, T7's portrait studio.
- Writes: `art/ui/icons/<name>.js` (one scene each), baked to `client/ui/art/icons_48.webp` (128 px per icon) and `icons_256.webp` (256 px, reward icons only).
- Scope: the 60 most-seen icons (currencies, rewards, heist controls, nav), about 25 minutes an icon (25 hours), plus 3 hours to set up the character route through Godot's toon portrait studio (section 10.6, §21.3).
- Batches: four batches of 15, each through the gate before the next, in the order the screens need them: heist controls and currencies first. Until D5 is decided, character and building icons go first. Batches 3 and 4 are the first work deferred if usage runs hot (D13).
- Checked by: the scripted checks (the 2-point outline at the size shown; each icon reads as a dark shape at 32 points, `docs/art/3d-program.md`'s silhouette rule); the judge at 48 and 96 points and in grayscale, on qualities 1, 3, 8 and 13, against the golden icons.

**Step 7. S1 builds the pilot heist.** Owner: S1. 6 hours. Phase 1. Waits for the heist's kit families and icon batch 1 to pass the gate and merge.
- Builds the heist from the kit alone, with no chrome of its own. It is the test of the frozen contract: what the pilot cannot build from the kit becomes a component request now, before three screens copy the gap.
- Writes: its screen files; `client/tests/shots/` stills before and after; its notes in `docs/art/tracks/`.
- Checked by: the screen class in section 3.5; then **board 1** (the kit and the heist) at O4.

**Step 8. AIA makes the juice and motion art.** Owner: AIA. 10 hours (7 if the owner allows CC0 particle sprites, D11). Phase 2. Waits for step 5 and decision D3.
- Writes: `art/ui/motion/` (burst, sparkle, shine and coin sprites) baked to `client/ui/art/motion.webp`, and `art/ui/motion/curves.json` (every curve's times and easing). K1's kit `Motion` reads the curves (today's `UiqJuice` is the pattern).
- Covers: the result screen's reward sequence (anticipation, burst, reveal, coins flying to their counter, the counter rolling and pulsing), a press with squash and recovery, and an idle shine on primary buttons.
- Each motion has its reduced form (section 10.3).
- Checked by: the scripted checks on timing, reduced forms and flashes (section 3.5); then the owner, from frame strips full and reduced, on **board 4** (result and motion). A still cannot show motion, so the judge does not block it.

**Step 9. S1 moves the result screen.** Owner: S1. 8 hours. Phase 2. Waits for the motion art (step 8); the layout on the kit can start before it.
- Same outputs as step 7. Checked by: the screen class; board 4.

**Step 10. S2 moves the home screen.** Owner: S2. 8 hours. Phase 2. Waits for phase 1's exit.
- Same outputs as step 7. Checked by: the screen class; **board 3** (home).

**Step 11. S3 moves the character and settings screens.** Owner: S3. 14 hours. Phase 2. Waits for phase 1's exit.
- The menu screens draw through T10's own layer (`ScreenKit`, `ScreenBox` in `client/scripts/screen_*.gd`), not `KitSkin`, so they would not inherit the new kit. S3 routes `ScreenKit`'s materials through `KitSkin` (4 of its 14 hours), so every menu screen inherits it.
- Same outputs as step 7. Checked by: the screen class; **board 5** (menus).

**Step 12. Polish and harden.** Owners: as the backlog assigns, by file. Up to 20 hours of reserve. Phase 3. Re-work from the boards, the blind audit and the exceptions; escalations to Opus 5.5 come from here too.

**The gate's runs through the wave.** Owner: the gate. 16 hours, in short read-only runs on the judge model: calibration (2, phase 0); the two kit-art batches, icon batches 1–2 and the pilot heist (5, phase 1); icon batches 3–4 and the other four screens with their second rounds (8, phase 2); the final re-checks (1, phase 3). Each run also writes the owner's exceptions packet. **Icon board 2** is posted when batch 4 passes.

### 3.4 The owner's time

The owner's time goes where review pays most: the plan, the contract, the labels every gate enforces, and samples. It does not go on a stream of approvals, which decay into rubber-stamping (the research's evidence on this is reported and secondary). In all, about 4½ to 6¼ hours over the wave.

| When | What the owner sees | What the owner does | Minutes | Default if the owner is away |
|---|---|---|---|---|
| O1, before phase 0 | This plan at a glance; section 12; the settings in section 3.9 | Decides D1 and D14; accepts or changes the defaults of D7–D10 and D12 | 20 | Nothing starts without D1 |
| O2, phase 0, after step 2 | `art/ui/board/board.png` beside today's heist and the design's, with its type both ways; K1's frozen kit contract | Approves the board and the contract, or redirects with notes; decides D4 and D5 | 15 | Steps 3 and 4 wait; AD and K1 go on |
| O3, end of phase 0 | `gate/golden/labels.md` and its images, the key frames among them | Labels each item pass or fail on each quality listed, with a one-line critique, including clear fails and borderline cases; decides D2 | 60–90, once | Phase 1 does not start: the judge cannot be calibrated without the labels |
| O4, phases 1–3 | Five family boards: 1 kit and heist, 2 icons, 3 home, 4 result and motion, 5 character and settings. Each shows 5–10 items beside their golden references at phone size, frame strips for motion, and the gate's verdicts | Objects to an item, with a note, or lets the board stand | about 15 each, 10 for icons: 70 | **Merges after 24 hours unless the owner objects** (section 3.8) |
| O5, daily | The exceptions queue (`gate/verdicts/exceptions.md`): split and "Unknown" verdicts, owner-checked qualities, pieces that failed twice with their three options | Decides each | 10–20 a day | Items wait; nothing in the queue merges |
| O6, end of phase 2 and at wave end | 10–20 items the gate passed, mixed with 3–5 it failed, on the golden set's form, without the gate's verdicts | Labels them blind | 15–20 each | The second audit is a condition of phase 3's exit |
| O7, wave end | The five screens before and after; the frame strips; draw calls and texture memory per screen; the counts of items passing the gate | Lets the wave stand or names what must be re-worked; decides D6 | 20 | The wave ends with the boards as they stand |

Default merges are safe only while the blind audits confirm the judge's catch rate (section 3.5).

### 3.5 The gate

The gate replaces the 0–5 scores of T14 and T16's plan. LLM judges agree with people far better when comparing two pictures than when scoring one on a scale; they drift towards lenient middle scores, and they vary from run to run (measured, in the research). So the gate asks narrower questions, compares against pictures the owner has judged, repeats each question, and measures itself against the owner.

**The four checks, in order of cost.**
1. **Scripted checks**, on every push and in the merge queue: draw calls, texture memory, atlas sizes and the install size (section 10.1); contrast in both modes over the baked art; 48-point targets and 13-point text at 100%, 150% and 200%; twins, hashes and coverage; the chrome count; timings and reduced forms. A scripted fail blocks.
2. **The judge**, for the qualities a still can show. One isolated call per quality, on read-only tools (`Read`, `Grep`, `Glob`), with no access to the author's notes or reasoning. Each call sees the candidate and two anchors from the golden set for that quality and asset class: the weakest item the owner labelled pass, and the strongest the owner labelled fail. It answers PASS, FAIL or UNKNOWN for that one quality, names the region, and gives a one-line reason. The order of candidate and anchors is shuffled on each call. Each call is made three times. Three fails block, with the reason and a crop; three passes pass; anything else goes to the owner's exceptions queue.
3. **The merge queue's guards** on the combined tree (section 3.8).
4. **The owner**: the family boards for what a still cannot judge (presses, juice, motion, and the whole screen's idea), the daily exceptions, and the blind audits that measure the judge.

A worker marks a task ready only after checks 1 and 2 pass on its branch. Its own assessment is recorded in its progress file as a claim with evidence and counts towards no check. Progress is reported as the number of items passing the gate, never as a self-estimated percentage.

**How each of the 14 qualities is checked.** The rubric (section 4) stays as the vocabulary; this is how each quality is checked under the new gate.

| # | Quality | Scripted | Judge (pairwise against the anchors) | Owner |
|---|---|---|---|---|
| 1 | Layered materials | Every skin has its face per state and its twin (`bake.js --check`) | Yes: the still at 960 px, plus full-resolution crops of three components, since grain and bevels vanish when downscaled | Boards |
| 2 | Display type | Every label over art is T1 or T2 with an outline of at least 1.5 points or 12% of its size; 13 points at 200% (client tests) | Yes, on full-resolution crops of headers and numbers only | Boards |
| 3 | Painted or rendered icons | The 2-point outline at the size shown; a dark shape at 32 points | Yes, at 48 and 96 points at native resolution | Board 2 |
| 4 | Press feedback | The press curve within §21.8 (or D3), travel of 2–4 points, the haptic call, a reduced form | No | Frame strips, boards 1 and 4 |
| 5 | Reward juice | Every step of the sequence present; a reduced form with one coin; no more than three flashes a second | No | Frame strips, board 4 |
| 6 | Hierarchy | One primary action, 1.5–2× the next by area, from the shot's control rectangles | Yes, on the grayscale still | Boards |
| 7 | Motion and idle life | Every screen change through `Motion`, with times in range; at least three idle loops on home; a reduced form for each | No | Frame strips, boards 3 and 4 |
| 8 | Colour roles and value | 4.5:1 over the pixels in both modes; interactive things at least two value steps off their ground; colours only from the palette; a colour-blindness sheet | Yes: the semantic hues and the rarity ladder read | Boards |
| 9 | Character presence | Home has a live character node | Yes | Board 3 |
| 10 | Phone scale and thumb reach | All of it: targets, text sizes at three scales, 3–5 nav items, the main action in the bottom centre band | No | No |
| 11 | One component system | All of it: the chrome count does not rise, the skin limits, the catalogue's coverage | No | No |
| 12 | Minimal gameplay HUD | All of it: the persistent HUD at most 15% of the screen, from the control rectangles | No | No |
| 13 | Light behind UI | Modals have the scrim | Yes: one light direction, sunbursts on rewards | Boards |
| 14 | One art-direction idea | No | Yes, on the whole still | Every board |

So the judge makes at most 8 isolated checks per screen (qualities 1, 2, 3, 6, 8, 9, 13 and 14), 24 calls with three samples, and 4 per icon sheet (1, 3, 8 and 13). What applies to each asset class:

| Class | Scripted | Judged | Owner |
|---|---|---|---|
| Style board | Contrast, colours from the tokens | none (no golden set yet) | O2 |
| Key frame | Targets, text, contrast, live words | none: the owner labels them at O3 | O3 |
| Kit art | Twins, contrast in both modes, coverage, chrome count | 1, 2, 8, 13 on the catalogue sheet | Board 1 |
| Icon | Outline, silhouette, sizes | 1, 3, 8, 13 | Board 2 |
| Motion | Timings, reduced forms, flashes, shake | none | Board 4 |
| Screen | Section 10's checks and the scripted column above, at 100% and 200% text and in high contrast | 1, 2, 3, 6, 8, 9, 13, 14 | Its board |

**Calibration.** The judge blocks nothing until it is calibrated.
1. **The golden set.** 30–60 items (step 1), labelled by the owner at O3, per quality, with a one-line critique. The labels are split by item into thirds, by asset class: a training third that AD reads to write the prompts, a development third to tune them, and a held-out third that is measured once per rubric version.
2. **What is measured.** For each judged quality, on the held-out third: the **catch rate**, the share of the owner's fails that the judge fails three times out of three; the false-block rate, the share of the owner's passes it fails; and the share it sends to exceptions. Raw agreement is not used: a judge that passes everything agrees 90% of the time with a set that is 90% passes. Results are written as counts ("7 of 8 fails caught"), because the set is small.
3. **The target.** A catch rate of at least 80% on every judged quality, with no more than 20% false blocks and no more than 30% sent to exceptions. The research sets no number; these are T17's choice, set high because judges are reported to catch only 30–60% of bad items. With 60 items and about five judged qualities each, the held-out third has about 100 labels and perhaps five fails per quality, so a quality's figure is rough: the weekly audit's fresh labels are the real test.
4. **The judge model.** Fable 5.1 and Opus 5.5 are both run on the development third. Fable 5.1 is chosen unless Opus 5.5 catches more; then Opus 5.5 judges and the blind audit doubles in size, since the artists also run on Opus 5.5.
5. **If a quality misses the target.** AD revises that quality's prompt against the training and development critiques, at most twice, and measures again. If it still misses, the other model is tried. If both miss, that quality becomes **owner-checked**: the judge's verdict on it is advisory and the quality goes on every board. The wave goes on.
6. **The blind audit (O6).** The gate draws 10–20 random items it passed, spread over the classes, and mixes in 3–5 it failed, so a blind owner cannot assume everything passes. The owner labels them on the golden set's form without the verdicts. Every owner fail on an item the gate passed is a miss. One miss on a judged quality pauses default merges for that quality: AD, in a fresh session from the reserve, revises its prompt against the critique, re-measures on the held-out third plus the audit's items, and default merges resume when the target holds again. The audit's labels join the golden set.
7. **Recalibration** also follows any change of judge model, any rubric edit (the rubric's version is logged, since the owner's bar moves as they see work), and any new asset class.

**When a piece fails.**
1. The gate writes `gate/verdicts/<item>-<round>.md`: which qualities failed and why, with a crop.
2. The author re-works it. A second round is normal.
3. **A screen that fails a second time** moves to a fresh Opus 5.5 session (section 3.1). **Art that fails a second time** goes to the exceptions queue with three options: accept it with the verdict noted, change the board so it passes, or keep the code-drawn kit's form for that piece. The wave goes on around it.
4. A screen that fails stays on its current look. Its material families can still be switched on for other screens (section 10.9), because the switch is per family, not per screen.

### 3.6 The wave's target

The wave is accepted at O7 when each of the five screens passes the gate on every quality that applies, at 100% and 200% text and in high contrast; no board has an open objection; the second blind audit found no miss left unfixed; and section 10's checks pass.

The bar is the owner's: a screen passes a quality when the calibrated judge, or the owner for owner-checked qualities, finds it at least as good as the weakest item the owner labelled pass. On T14's 0–5 scale that bar is estimated at about 3.5, against 2.2 today: 70% of Clash level, about 50% of the owner's bar (7, section 1). That is an estimate for comparison, not a gate. The ceiling of this plan is 3.75–4.25 (section 6). The rest of the bar needs what section 9.4 says the AI artist lacks: invention, painterly texture and hand-timed effects.

### 3.7 Hours

T14's steps summed to 81 hours ("about 80"). T16 made it 144, then 158 with the full kit. Plan v3 makes it **164**.

| Step | T14 | T16 | Plan v3 | Why it changed |
|---|---|---|---|---|
| AD and the gate | 8 | 21 | 25 | AD's set-up becomes the checks, the golden set and calibration (6 → 9). Reviews become the judge's runs on another model (15 → 16): fewer whole-screen scores, but three samples per quality and calibration runs |
| Style board | 6 | 6 | 6 | |
| Key frames | 10 | 10 | 10 | Now in phase 0, since the pairwise gate needs them as golden references |
| Kit contract, pipeline and kit (K1) | 12 | 31 | 33 | Freezing the contract and the ownership map (1); the guard command and its budget records (1) |
| Kit art | 10 | 16 | 16 | |
| Icons | 25 | 28 | 28 | |
| Juice and motion | 10 | 10 | 10 | 7 with D11 |
| Screens | not costed | 36 | 36 | Now on Sonnet 5.5; the risk that they take longer is carried by the reserve and the escalation rule |
| **Total** | **81** | **158** | **164** | 161 with D11. Plus up to 20 hours of re-work, escalations included. The lead's time (about 16 hours) is outside the total |

**By phase:** 43, 58, 62 and 1, plus the reserve in phase 3.

| Phase | AD | Gate | AIA | AIA-2 | K1 | S1 | S2 | S3 | Total |
|---|---|---|---|---|---|---|---|---|---|
| 0 | 9 | 2 | 16 | | 16 | | | | 43 |
| 1 | | 5 | 16 | 16 | 15 | 6 | | | 58 |
| 2 | | 8 | 10 | 12 | 2 | 8 | 8 | 14 | 62 |
| 3 | | 1 | | | | | | | 1 |
| **Total** | **9** | **16** | **42** | **28** | **33** | **14** | **8** | **14** | **164** |

**Against the research's allocation.** The research proposes 158 hours split 14, 43, 71 and 30 by phase, with 44 for the artists, 26 for the kit, 66 for the screens and 22 for the art director. It calls that split its own allocation, to be adjusted to the backlog. Plan v3 keeps its step costs instead, for three reasons. The research's phase 0 has no board or key frames, yet its own gate compares against owner-approved golden screens, so 16 of AIA's hours move into phase 0. The plan's steps cost the artists at 70 hours (60 icons at about 25 minutes each, 35 skins with their states and twins), not 44. And the screens are costed step by step at 36; the research's 66 would hold for screens built on Opus 5.5 without a frozen kit.

The AI artists' share is 70 hours (AIA 42, AIA-2 28).

### 3.8 Merging

**One change at a time, as soon as it is ready.** The hourly cycle of earlier waves becomes the longest a ready change waits, not the only time merges happen.

1. **Ready.** A change is ready when its branch contains main's current head, `bash tools/check_all.sh` printed "All checks passed" on exactly that commit (its log ends in a `DONE exit=0` line), `tools/ui_bake/guard.sh` passed on it if the change touches the client or the art, and the gate passed every item it carries. The worker writes `ready` and the commit in its status file (`docs/guides/agent-program.md`).
2. **The queue.** The lead takes ready changes in the order they became ready, one at a time, with the critical path first (the kit contract and shared art before screens; AIA's chain before the rest). If the ready commit contains main's head, the lead fast-forwards main to it: the tree that passed the checks is exactly the tree that lands. If main has moved, the lead marks the task `resync` in the backlog.
3. **Conflicts are the worker's.** The worker brings main into its own branch (a merge, the repository's convention), resolves its own conflicts, re-runs the checks and marks ready again. A conflict in a file the worker does not own is never resolved by editing it: the worker stops that task and sends a request to the file's owner.
4. **If the worker has stopped,** the lead merges its last ready commit with main on a temporary branch, runs the full checks there and fast-forwards main only if they pass. This is the hourly cycle, and the only time the lead merges by hand. If that merge conflicts, the lead resolves nothing: the task waits for its owner's next session.
5. **Default merges.** A family's pieces (kit art, icons, kit code) merge as soon as they pass, behind their family switch, so the screens can build on them. What players would see waits on its board: a family's switch-on commit and a screen's new layout merge 24 hours after the board is posted unless the owner objects. An objection keeps the switch off and makes the item a task for phase 3.

**Guards on the combined tree.** Separate branches stop textual collisions, not semantic ones: two changes that pass alone can fail together, as the merge that undid the database optimisation did. Each guard encodes an intent, so a merge that breaks it fails:

| Guard | What it protects | Where it runs |
|---|---|---|
| `node server/load.mjs --check` | The database's reads and writes per player | check_all |
| `node tools/ui_bake/bake.js --check` | Bakes match their sources; every piece has its twin; atlas sizes and the install total | check_all |
| `python3 tools/ui_bake/check_screens.py` | No screen adds chrome of its own | check_all |
| The client's kit and accessibility tests | 48-point targets and 13-point text at 200%; contrast over the baked art in both modes; the material switch's fallback | check_all (`client/status.py`) |
| `tools/ui_bake/guard.sh` | Draw calls under 150 and no higher than recorded, texture memory at most 24 MiB, for the five screens at 100% and 200% text and in high contrast; the full rebake byte for byte | Every ready change that touches the client or the art, and the lead's hand merges; in check_all if the owner chooses D9 (a) |

Because main only fast-forwards to a commit on which these passed, no merge can land a combination nobody tested.

**Requests.** An agent that needs a change in another agent's file writes a request in its own status file. The file's owner answers in its own files (K1 answers kit requests in `kit-spec.md` section 7), and the lead copies open requests into `docs/progress/requests.md` in each digest. Nothing is delivered until its recipient acknowledges it (`docs/guides/agent-program.md`).

### 3.9 Sessions, tokens and usage

Every request resends the whole conversation, so a session's cost per tool call grows with its context: one at 350k tokens costs about 3.5 times as much per call as one at 100k, and recalls less (the research's arithmetic at list prices; plan-limit units are not published). The rules:

- **A fresh session at every phase boundary and every task boundary.** Before it ends, the agent rewrites the handoff section of its progress file: the last verified commit, what is done, what is half done, open hypotheses and the next step. The next session starts from the handoff, the backlog and `git log`, then runs the basic checks before new work. A session continues or compacts only when the next step depends on unwritten state, such as a live debugging hypothesis.
- **An earlier compaction point:** 200k tokens (P1), not the 967k at which 1M-context models compact in cloud sessions.
- **Test output goes to files.** Long runs write to a log ending in a `DONE exit=<code>` line; the agent reads only the failures and the last lines. A restarted agent re-runs any run whose log lacks the marker.
- **Stills for judging are downscaled where that does not hurt the judgement.** The judge sees whole screens at 960 pixels on the long edge (about 560 image tokens for a phone portrait, against about 3,300 at full size), and full-resolution crops for type, grain and small icons, which downscaling would hide. Builders look at their stills through a subagent or at the same size, and never keep more than a few images in their context.
- **Never switch model inside a session.** Each model has its own cache, so a switch re-reads everything at full price. The same goes for toggling fast mode, adding or removing an MCP server, and `opusplan`. A different model means a fresh session with a handoff.
- **Subagents for searches and log triage** run on Haiku 5.5 and stay under 100k tokens. They never give a gate verdict.

**Usage.** Every session draws on one account's five-hour window and weekly limit; Fable 5.1 is reported to have its own weekly limit on Max plans, which is one more reason to put the judge on it.
- At the end of phase 0 the lead reads `/usage`, works out the share of the weekly bar that one agent-hour on each model used, and projects phases 1–3 plus a 20% reserve for the lead and recovery. If it does not fit, the owner decides D13: wait for the weekly reset before phase 2, enable usage credits (then P2), or cut scope. The default is three builders at once with icon batches 3 and 4 deferred.
- **Tiers.** As headroom shrinks, the idle queue checkpoints and stops first, then icon batches 3–4 and the second-round polish, then S2 and S3; the lead, K1, the gate, AIA and S1 (the critical path) stop last.
- Heavy exploration is staggered: no two Opus 5.5 sessions start a new step in the same half hour.
- Every agent commits and pushes after each verified step, so a limit pause costs time but no work. No `/loop`, check-ins or messages that wake an idle session to resend its whole context.

**Settings proposed to the owner (D14).** T17 changed no setting or config file. Each of these is a proposal, with its exact value; the research labels the settings' behaviour as vendor documentation, which changes often, so the lead checks each against the current docs before applying it.

| # | Setting | Exact value | Where | Why |
|---|---|---|---|---|
| P1 | `CLAUDE_CODE_AUTO_COMPACT_WINDOW` | `200000` | The cloud environment's environment variables, for every session of the wave | Compacts at 200k instead of about 967k |
| P2 | `promptCacheTtl` | `"1h"` | `.claude/settings.json` | Only if usage credits are enabled (D13): on credits the main conversation otherwise drops to the 5-minute cache, and every 25-minute test wait becomes a full re-read |
| P3 | A `PreToolUse` hook on `Bash` | `{"matcher": "Bash", "hooks": [{"type": "command", "command": "python3 tools/hooks/filter_tests.py"}]}` | `.claude/settings.json`; the script, written by the lead if approved, appends `> test-results/<commit>.log 2>&1; echo "DONE exit=$?"` and shows only `grep -A 5 -E '(FAIL\|ERROR\|error:)' \| head -100` and the last line to runs of `check_all.sh`, `status.py` and `cargo test` | A 10,000-line log costs hundreds of tokens, not tens of thousands |
| P4 | A `Stop` hook | `{"hooks": [{"type": "command", "command": "python3 tools/hooks/stop_guard.py"}]}` | `.claude/settings.json`; the script exits 2 while the time is before the agent's `stop_at` less 30 minutes and its status is not `stopped`, `done` or `blocked` | Stops agents ending early on a misread time; the harness overrides it after eight blocks in a row |
| P5 | The judge's subagent | `.claude/agents/ui-judge.md` with `tools: Read, Grep, Glob` and `model: inherit`; the gate's sessions are started on the judge model | `.claude/agents/` | Read-only enforced, not requested; one isolated context per check |
| P6 | `autoContinueAtUsageLimit` | `true` | `.claude/settings.json` | A session paused at the limit continues at the reset; `send_later` stays the fallback |

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
| 1 | **A + D. An authored-asset pipeline, authored by an AI UI artist.** UI art authored as SVG/HTML (from the design's own sources) and as three.js scenes, baked offline in headless Chromium into atlases: 9-slices, sprites and baked numerals; icons rendered from 3D and finished in 2D. Checked by C. | 3.75–4.25: 75–85% of Clash level, 54–61% of the bar (section 9.4) | 164 (section 3.7): the AI artists 70, the kit 33, the screens 36, the art director and the gate 25; 161 with CC0 particles (D11) | Agent-authored art can be generic without key frames and a reviewer, which is why C goes with it. Texture memory: a 1024² atlas is 4 MiB of video memory uncompressed (section 10.1). High contrast needs its own bake. | Good. Textured quads are cheaper per pixel than `rb_box`'s signed-distance shader. One atlas batches. The proof is at 147 calls (section 7). No post-processing. Words stay live, so the strings tables and text scale still work. |
| – | A alone: the same pipeline with an engineer choosing the look and no artist role | 3.5–4.0: 70–80% of Clash level, 50–57% of the bar | about 94 (K1 33, the screens 36, the art director and the gate 25): no style board, key frames or rendered icons | The look is tuned by an engineer, without a board the owner approves | Same as A + D |
| 2 | **C. Process: a standing art director, the rubric and a quality gate.** Goes with A + D; it is not an alternative to it. | No pixels by itself; +0.25–0.5 from better choices | 25 in plan v3: 9 to build the checks and the golden set, 16 of the judge's runs (section 3.3) | Low, once calibrated: the judge is measured against the owner's labels and audited blind (section 3.5) | Neutral |
| 3 | **B. A much stronger shader and material system.** Grain, a lit bevel from the signed distance, gradient text through a canvas shader, glow | 2.25–2.75: 45–55% of Clash level, 32–39% of the bar | 25–35, plus the screens | Per-pixel cost on low-end phones (every panel pays for noise and lighting each frame). GLSL ES 3.0 limits. Icons and type stay as they are. Each look is still tuned by numbers rather than drawn. | Medium. Fill rate rather than draw calls is the risk. §21.3 forbids full-screen post-processing, so glow and bloom must stay per item. |
| 4 | **E. Adopt existing kits.** A commercial casual kit's buttons and frames, CC0 particles, an icon pack (`build-or-buy.md`) | 3.0–3.5 at best: the kits' materials reach 3–3.5, but their look is shared with other games, which caps quality 14 (one idea) and the owner's "three times v3" | 156 with A + D: saves about 8 hours | §21.11 forbids outside art, paid or free, so it needs the design document changed (D11) and a purchase (D12). Kits have no sources, so no high-contrast twins, school tints or rebuilds from code. Icon packs need attribution, which §21.11 rules out | The PNGs atlas and 9-slice well; Unity prefabs and effects do not carry over |

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
- **Judged as art, not as numbers:** the gate checks each piece against the owner's labelled references before it ships (section 3.5).

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

With the gate and the owner's labels, the AI UI artist is likely to reach **3.75–4.25 out of 5: 75–85% of Clash level, 54–61% of the owner's bar** (7, section 1). T14 first wrote "75–85% of the bar"; the figures were shares of Clash level. It falls short in these places:
- **Charm and invention.** Its shapes come from primitives and code. A Clash gem has exaggerated, characterful facets and painted colour shifts that a person invented. The AI artist's gem is correct, not memorable. Mascots, the logo and hand-lettered titles are where this shows most.
- **Painterly texture.** With no image-generation tool here, there are no brushstrokes. Texture is procedural (grain, planks, noise), which reads as clean 3D rather than painted.
- **Taste across a whole set.** The AI artist sees each render and corrects it (every fix in section 9.3 came from looking). But it judges one piece at a time, and drifts unless held to a reference.
- **Frame-by-frame effects.** Bursts and particles can be baked from procedural shapes. Hand-timed effect animation, the Spine or Animate kind, is beyond it.

How the plan covers those:
1. **The owner approves the style board and labels the five key frames** in the golden set before production (O2, O3). Invention is concentrated where a human eye decides once, and the AI artist then executes the approved look at volume, where it is strong.
2. **The gate checks every piece** against the owner's golden references, one quality at a time, at 48 points and in grayscale, and blocks confident fails (section 3.5). That stops drift.
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
| Atlas size | 1024² for a screen family (the kit itself takes two, `kit-spec.md` section 8.2); 2048² at most, the largest size the OpenGL ES 3.0 standard guarantees on every phone | The bake refuses a larger atlas |
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
- **Colour.** No information by colour alone (§20.8): rarities and schools carry shape as well as colour. One set of school colours, with no palette switch (§20.8), so there are no colour-blind variants to bake, but every atlas is checked by colour-blindness simulation before the wave board (O7).
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

No glint, sparkle or shine flashes more than three times a second (§20.8). Screen shake is never above 4 pixels (§21.8) and can be switched off (§20.8).

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

- **Made, not licensed (§21.11).** Every pixel is made by code in this repository, and the sources are kept in the repository beside the bakes (they are not shipped), so the art is "made for this game". The build tools (three.js 0.184.0 under the MIT licence, Playwright 1.63.0 and its Chromium under Apache 2.0 and BSD) are permissive and are not shipped. K1 records them in a tools ledger beside the fonts' ledger.
- **Fonts.** The three faces are under the Open Font Licence with their texts shipped (`client/ui/fonts/LEDGER.md`). Baked numerals are pictures drawn with Lilita One, not font files, and the ledger says so in a new row.
- **No outside art.** No image comes from outside: no stock, no generated image, no game art, no bought or CC0 kit (§21.11; `build-or-buy.md`). The benchmark panels in the audit images are written descriptions. If the owner allows CC0 particle sprites (D11), K1 adds `client/ui/art/LEDGER.md` in the fonts' ledger's pattern, and the downloaded files stay out of the repository.
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
| Full rebake, byte for byte: under a minute for the kit, about 2 minutes for 60 icons (at the proof's rates) | `tools/ui_bake/guard.sh`, before every ready change that touches the client or the art, and in the lead's hand merges (section 3.8) | about 3 minutes |
| Draw calls and texture memory for the five screens at 100% and 200% text and in high contrast: 15 shots at about 47 seconds each, warm (T16 measured one) | `tools/ui_bake/guard.sh`, as above | about 12 minutes |

Putting the last two in check_all would add about 15 minutes to every run. Whether to is decision D9 (section 12). Until it is decided they run before a change is marked ready and in the lead's hand merges, and a failure blocks the change. Since main only fast-forwards to a commit they passed on (section 3.8), they always hold on the combined tree.

No test is skipped, disabled or loosened. Tests that check today's code-drawn look keep running until the switch is on everywhere (section 10.9).

### 10.9 Moving screens without a broken in-between state

1. **A switch per material family** in `KitSkin`: gold, leather, card, parchment, glass and the rest of `client/ui/tokens.json`'s materials. Off, the material draws as today. On, it draws from the atlas. A piece missing from the manifest falls back to the code-drawn box and logs it, so a screen is never blank.
2. **A family switches on** only when its pieces and their high-contrast twins pass the gate, the contrast tests pass, every screen's draw calls are no higher than before, and the family's board has stood for 24 hours without the owner's objection (section 3.8). Then every screen that uses it changes together, which is the point: no screen is half old and half new.
3. **The menu screens** draw through T10's `ScreenKit`, not `KitSkin`. S3 routes `ScreenKit`'s materials through `KitSkin` (step 10), so they switch with everything else.
4. **Arrangements move later.** The screen tracks change each screen's layout to its key frame after the families are on. A screen that fails its gate keeps its layout on the new materials.
5. **Going back** is one switch off.
6. **The prototype** (`client/prototypes/ui_quality/`) is folded into the kit and deleted at the end of step 4. Until then it ships in the exported pack (the presets exclude only `tests/*`); the integrator should exclude `prototypes/*` (`plan-review.md`).

### 10.10 Sound and haptics

The rubric's press feedback and reward juice ask for a sound per step (qualities 4 and 5). The client has no sound at all yet: no audio player in any script. §21.8 sets the instruments, and §21.11 says sound is generated or public-domain. No agent in this plan makes sound, so:
- the plan's motion fires named events (press, coin landed, counter done, reveal) that a sound track can hang sounds on later;
- haptics already exist (`client/app/haptics.gd`, §21.8's light tap on buttons), and the motion calls them;
- the owner judges qualities 4 and 5 without sound in this wave, and the boards say so.

Whether to add a sound track now is decision D7 (section 12).

## 11. Risks

| Risk | What it would do | Mitigation |
|---|---|---|
| The AI artist's work is correct but generic | Screens pass but do not feel premium | The owner approves the board (O2) and labels the key frames (O3); quality 14 is judged and on every board; an image-generation tool, if one is connected, slots in under the same gate (section 9.4) |
| The judge agrees with itself, not with the owner | Passes rise while the look does not | A different model from the artists; calibration on the owner's labels with a catch-rate target; blind audits of its passes, which pause default merges on a miss (section 3.5) |
| The judge misses its target on a quality | That quality cannot block | Two prompt revisions, then the other model, then the quality is owner-checked on the boards; the wave goes on |
| The golden set is too small to measure well | A catch rate of "4 of 5" says little | Results written as counts; the audits' labels join the set; recalibration on every rubric edit |
| Sonnet 5.5 builds weaker screens than Opus 5.5 would | Second rounds and escalations | The pilot tests it in phase 1; two fails move a screen to a fresh Opus 5.5 session from the reserve |
| The merge queue becomes the bottleneck | Ready changes wait on each other's 25-minute checks | Fewer than 40 changes over about 65 hours at five builders; the critical path goes first; the hourly hand merge is the longest wait |
| Draw calls over 150 | A screen cannot merge | One atlas per family; words in their own layer; the check before every push; fall back to the code-drawn piece for the costliest part |
| Texture memory on a 3 GB phone | Stutter or a crash on old phones | Two icon sizes (128 and 256 px); per-screen atlases loaded and freed; high contrast replaces, never adds; the 24 MiB check |
| The owner is not available | O2 or O3 holds phase 0; board 1 can hold phase 2 for up to 24 hours; later boards stand by default | AIA works ahead at risk on its branch and merges nothing; K1 does not wait on O2; boards merge after 24 hours unless the owner objects; the exceptions queue waits without blocking the rest |
| The motion and type rules stay as §21.8 says (D3, D4 not decided) | Qualities 2, 4, 5 and 7 cap lower | The plan works either way; the curves and type treatments are data, so a later decision is a change of numbers |
| A bake stops rebuilding byte for byte | Nobody can tell a real change from noise | Pinned tools; the manifest records versions; the full rebake runs before every push |
| Nothing here runs on a real phone | Frame time on the reference device is unmeasured | Draw calls and texture memory are measured on the same renderer (Compatibility); frame time on the reference device is checked by the developer before release |
| The renderer's known faults (section 7's findings) | A white square in place of a ring; the shot aborts after writing | Textured polygons in their own canvas items; shots check that the PNG was written |
| Usage limits pause the wave | Every agent stalls together | The projection at the end of phase 0 (D13); tiers that stop the least critical first; a 20% reserve; a commit after every verified step; P6 and `send_later` to resume (section 3.9) |
| Brazilian Portuguese runs longer | Words overflow frames | Frames sized from their words; every key frame and screen checked in both languages |
| The kit grows back into many looks | Rubric quality 11 falls; texture memory grows | Requests go to K1, the kit's one owner; reuse first; the limits in `kit-spec.md` section 7; the screens' chrome check refuses local chrome |

## 12. Owner decisions

D1–D5, D11, D13 and D14 are in the plan at a glance; D11 and D12 come from `build-or-buy.md`. Each has a default, so the wave never stops for an answer it does not yet need.

| # | Decision | Why it is needed | Options | Default | When |
|---|---|---|---|---|---|
| D1 | Approve plan v3 | 164 agent-hours in four phases; seven building roles, at most five at once; a lead and a judge beside them (sections 3.1–3.7) | Approve; approve a smaller scope (for example A alone, about 94 hours); reject | Nothing starts | O1, before phase 0 |
| D2 | The approved key frames become the visual reference | §23.5: "The designs carry the look: layout, art, motion, the models and the icons." Key frames that replace Screens v3 need that sentence changed | (a) Change §23.5 so approved key frames carry the look where they differ from the designs; (b) keep §23.5, key frames are targets only | (b): key frames keep the designs' layouts and icons' shapes, and push material, type and light | O3, end of phase 0 |
| D3 | Overshoot on presses and reward reveals | §21.8: "150 to 250 milliseconds, easing out ... without overshoot". Clash-level juice overshoots | (a) Change §21.8 to allow overshoot on presses and reward reveals, at most 350 ms, with the reduced form unchanged; (b) keep §21.8. Either way, confirm that a bar filling to a new value (450 ms in `tokens.json`) is a value changing, not a movement | (b) | Before phase 2 |
| D4 | A display face for labels and changing numbers on art | §21.8 gives labels and changing numbers to Manrope. The proof's labels are Lilita One and its loot count is baked numerals | (a) Change §21.8 to allow Lilita One (or Titan One, an OFL face to compare on the board, `build-or-buy.md`) for labels on art, and baked numerals with a fixed advance for changing numbers; (b) keep §21.8 | (b): labels in Manrope with an ink outline; baked numerals only for numbers that do not change | O2, in phase 0 |
| D5 | Object icons lit physically | §21.3 asks for "one toon look for everything"; the proof's gold, gem and chest are lit physically (section 10.6) | (a) Allow it for interface icons of objects, never characters; (b) every icon in the toon look | Character and building icons start first; object icons wait | O2, in phase 0 |
| D6 | How many icons | §21.9 counts about 390 interface icons, "as Screens v3 draws them". The plan re-authors the 60 most-seen; the other 330 or so stay flat, so two styles show side by side | (a) 60 now, the rest in a later wave (about 140 hours at the same rate); (b) 60 now, and give the rest the new outline and glint rules only; (c) all now | (a) | O7, wave end |
| D7 | Sound | The rubric's qualities 4 and 5 ask for sound; the client has none (section 10.10) | (a) No sound this wave, events ready for it; (b) add a sound track | (a) | O1 |
| D8 | Texture and install budgets | The design document sets none (section 10.1) | Approve 24 MiB resident and 8 MB installed, or set others | The proposed numbers | O1 |
| D9 | What check_all runs | The full rebake and the screen budgets would add about 15 minutes (section 10.8) | (a) In check_all; (b) before every push and at every merge | (b) | O1 |
| D10 | The wave's target | The gate's bar is the owner's own labels; on T14's scale it is estimated at about 3.5, about half the owner's bar (section 3.6) | Accept it; label a higher bar in the golden set, with more hours | The bar the owner's labels set at O3 | O1, confirmed at O3 |
| D11 | CC0 particle sprites as raw material | §21.11: outside art is not allowed; only fonts (OFL), sound (public domain) and code (permissive) may come from outside. CC0 particles would save 3 hours of motion art (`build-or-buy.md`) | (a) Add to §21.11: "Particle and texture sprites under a public-domain dedication (CC0), as raw material only, recoloured and baked through the game's own pipeline and listed in the art ledger"; (b) keep §21.11 | (b): AIA makes them (10 hours, not 7) | Before phase 2 |
| D12 | Buying anything | §21.11: "Nothing in this game is paid for." `build-or-buy.md` recommends no purchase. If the owner wants one anyway: a casual UI kit (Layer Lab "GUI Pro – Casual Game", $39.99), Spine (Essential $99, on sale at $69 when checked; Professional $439, on sale at $369) | Buy nothing; or name the item, which also needs §21.11 changed | Buy nothing | O1 |
| D13 | If the usage projection does not fit | The weekly limit is close, and every session draws on it (section 3.9) | (a) Wait for the weekly reset before phase 2; (b) enable usage credits, with P2; (c) cut scope: three builders at once, icon batches 3–4 deferred | (c) | End of phase 0 |
| D14 | The session settings | P1–P6 (section 3.9) change the environment and `.claude/settings.json`, which only the owner may approve | Approve each, or none | None applied: agents follow the rules by hand (fresh sessions, filtered output, no model switches) | O1 |

What D2, D3, D4 and D11 would change in the design document is written out in `plan-review.md`. Neither T16 nor any agent in this plan edits the design document.

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

The bakes (`tools/ui_research/bake_hud.js`, `bake_icons.js`, `pack_atlas.py`) are the starting point for K1 and the AI UI artist in section 3. T16 and then T17 (plan v3) have since revised the plan; see the plan at a glance and `plan-review.md`.
