# Why the interface is not premium yet, and the way there (T14)

The owner says the interface is "not even 30% there". The agents' progress files say 80–90%, and the integrator says "about halfway". This report finds out which reading is right and why. It also says what to do next and shows a proof.

Everything here was measured or rendered from the deployed head (`dd326ca8`). Images are in this folder. Tools are in `tools/ui_research/`.

## 1. Verdict

**The owner is right. Against the owner's bar we are at about 30%.**

I scored our five most important screens (home, heist, result, character and settings) against 14 checkable qualities of premium mobile UI (section 4). The mean is 2.2 out of 5, with 5 meaning Clash Royale or Brawl Stars level. It falls to 2.1, or 41% of Clash level, when the six qualities that most separate premium from competent count double. The owner's bar is *above* Clash, and three times Screens v3. Those six score lowest:

| Quality | Score (out of 5) |
|---|---|
| Material | 2.1 |
| Display type | 1.7 |
| Painted icons | 2.1 |
| Reward juice | 1.3 |
| Motion | 1.8 |
| One art-direction idea | 1.5 |

So "about 30% of the bar" is a fair figure.

The agents' 80–90% is not a quality measure. It counts finished deliverables against a list. Their "vs design" rounds measure how closely a still matches the design's layout. On that test they do well: our screens now match the design closely (`audit-*.png`).

**Matching the design cannot reach the bar.** Screens v3 itself scores 2.4 out of 5 on the same rubric (section 5.2):
- a dark-violet web-panel look, with rims of 1.5 px at 35–50% opacity;
- most text in Manrope at 10–11 pt with no stroke;
- dark on dark, about one step of value apart.

A perfect port of v3 lands near 48% of Clash level. "Three times v3" is not a direction you can polish toward. It needs a different target and a different way of making pixels.

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
- **Option A, an authored-asset pipeline**, made by Option D, a standing **AI UI artist** agent (section 9). The owner chose this over a human artist.
- **Option C, an art-director gate**, scoring the AI artist's work.

The ranked options with costs are in section 6.

The two proofs show that this works in this engine, within budget, and is much richer than code-drawn chrome:
- **The heist HUD (section 7):**
  - rebuilt from art baked offline in headless Chromium: lit bevels, grain, studs, painted icons, numerals with stroke, drop and gradient;
  - one 1024² atlas;
  - 147 draw calls against 137 today, under §21.3's 150;
  - every word still live text from the strings tables.
- **The reward icons (section 9):** Starlight, Essence and Renown, plus a chest and a crew badge from Pip's own model, modelled and lit in three.js and finished in 2D at 256 px. Icons are the asset class this report first said needed a human hand. They score 3.7 out of 5 on the rubric's icon qualities, against 2.2 for today's.

The next wave, in this order. **AIA** is the AI UI artist, a standing agent that authors all UI art (section 9.1).

1. **AD, a standing art director** (about 8 agent-hours over the wave). A reviewer, never an author.
   - Owns the 14-quality rubric in section 4 and a reference sheet of described benchmark screens.
   - Scores every piece AIA proposes, before anything is merged:
     - 0–5 per quality, at phone size;
     - the icon set at 48 px and in grayscale;
     - a frame strip for anything that moves.
   - A piece merges only if its score does not drop. Qualities 1–3 must reach at least 3.5.
   - Publishes the scores, so "progress" means quality.
2. **AIA: style board, then key frames** (day 1, about 16 hours).
   - **Style board** (about 6 hours): one board with the material set (enamel, gold, wood, glass), the type treatments, the outline and glint rules, the studio light, and four hero icons.
   - **Key frames** (about 10 hours): a premium target still for each of the five screens as HTML/SVG, built from the design's own HTML and pushed to the bar.
   - The owner approves or redirects the board and the key frames. They replace v3 as the reference.
3. **K1, the bake pipeline and kit** (in parallel, about 12 hours, an engineering track).
   - Generalise `bake_hud.js`, `bake_icons.js` and `pack_atlas.py` into the kit's pipeline, packed into atlases.
   - High-contrast (§20.8) and school-colour variants as extra bakes.
   - Lilita One as a multichannel distance field.
   - `KitSkin` looks backed by textures, so every screen inherits them.
4. **AIA: kit art** (about 10 hours). Frames, buttons with their pressed faces, bars, rings, ribbons and numerals in four finishes, to the approved board.
5. **AIA: icons** (about 25 hours). Re-author the 60 most-seen icons (currencies, rewards, heist controls, nav) the section 9.2 way, about 25 minutes an icon once the studio is set up:
   - modelled and lit in three.js;
   - characters and buildings from their `.glb` models;
   - finished in 2D.
6. **AIA: juice and motion** (about 10 hours).
   - The result screen's reward sequence: anticipation, burst, overshoot, coins flying in arcs, counters rolling and pulsing.
   - An idle shine on primary buttons, and a press squash with recovery.
   - Burst and sparkle sprites baked like the icons.
   - Judged from frame strips.
7. **The screen tracks** then move their screens onto the new kit, judged by AD.

These estimates total about 80 agent-hours, with AD running throughout. The earlier plan was 50–60 agent-hours plus a human artist's contract. The extra hours are AIA doing what the artist would have done.

## 4. Benchmark: 14 checkable qualities

Sources and their limits are in section 4.2. The benchmark games are Clash of Clans (CoC), Clash Royale (CR), Brawl Stars (BS), Squad Busters (SB), Royal Match (RM), Monopoly GO (MGO) and Marvel Snap (MS).

A note on the evidence. Visual specifics come from my knowledge of the games, marked [GK]. Production facts come from sources seen through search-result summaries, marked [S]; the pages themselves could not be opened from this container (section 4.2). No game art is copied here; the benchmark panels in the audit images are written descriptions.

| # | Quality | The check | What the best do | Ref |
|---|---|---|---|---|
| 1 | Layered materials | Every primary button and panel has at least 4 layers: a gradient (light top), a gloss band over the top 30–45%, a dark hue-matched rim of 2–4 pt, and a solid lip or drop of 3–8 pt that gives it thickness. Panels have a bevelled frame and an inner well. No flat primary control. | CR and CoC capsule buttons on thick lips; RM gold frames around felt or parchment wells [GK] | 9-slice raster art [S1, S2] |
| 2 | Display type | One heavy display face for all numbers and headers. Every label on art has a stroke of 8–15% of cap height plus a hard drop. Big numbers have a gradient fill. No unstroked text over art. | CR's Supercell-Magic (a customised You Blockhead) everywhere, with a second face for chat [S3] | [S3] |
| 3 | Painted or rendered icons | Every currency, reward and chest icon has a 3D form, a top-left key light, a rim light, a specular highlight and a dark outline that reads at 48 px. No flat glyphs for things of value. | CoC gems and elixir, CR chests, MGO dice and cash [GK]. Supercell's Creature Shop renders models for in-game UI and marketing [S4] | [S4] |
| 4 | Press feedback | Touch-down sinks 2–4 pt onto the lip or squashes to 92–95%, and darkens. Release springs back with overshoot in 80–150 ms, with a sound. | Every CR, BS and RM button; BS's Super button flashes when charged [S5] | [S5] |
| 5 | Reward juice | Anticipation (0.3–1 s), a burst, the reveal with overshoot, icons flying in arcs to their counter, the counter rolling up and pulsing on each landing, a sound per step, stronger for rarer rewards. | CR chest opening; RM level complete; MGO payouts [GK]; "Juice it or lose it" [S6] | [S6] |
| 6 | Hierarchy | Exactly one primary action, 1.5–2× the next and the most saturated. At most about 5 things at the second level. It survives a grayscale squint. | CR and BS Battle/Play; RM's single Level button [GK] | [S7] |
| 7 | Motion and idle life | Every screen change animated in 150–350 ms. Popups back-ease in over a dimmed scene. At least 3 idle loops on home (shine sweeps, bobbing, a breathing CTA). No hard cuts. | RM's motion "communicates simplicity, polish and focus" [S8]; CR shine sweeps [GK] | [S8] |
| 8 | Colour roles and value | Fixed semantic hues (green go, gold primary, red danger, blue neutral, purple epic) and a rarity ladder. Interactive things at least 2 value steps off the background. | CR rarity colours carried through cards, chests and text [GK] | [GK] |
| 9 | Character presence | Home shows a live character (real-time 3D or skeletal). Rewards and offers are framed with character art. | BS's 3D Brawler idling in the lobby; the CR King's emotes [GK]; Supercell designs characters to read "in miniature" [S9] | [S9] |
| 10 | Phone scale and thumb reach | Targets of at least 44 pt, primaries about 1.5× that. Bottom nav of 3–5 items, the main CTA bottom-centre, text of at least 11 pt. | CR, BS and SB bottom tabs; BS joysticks sized to the device [S5] | [S10] |
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

**Overall.** The plain mean is 2.2 out of 5, which is 44% of Clash level. Weighting the six qualities that separate premium from competent (1, 2, 3, 5, 7, 14) double gives 2.1, or 41%. The owner's bar is above Clash level, so **about 30% of the bar**.

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
| Screens v3 | 2.5 | 2 | 2.5 | 2.5 | 2 | 2.5 | 2.5 | 2.5 | 2 | 2 | 2 | 3 | 3 | 2 | 2.4 |

Where v3 sits above us:
- a little more gloss;
- its CSS press states and 86 keyframe animations (from `design-system.md`, section 5.1);
- the result's study card.

Where it sits below us:
- text at 10–11 pt, under §21.8's floor (row 10);
- 852 colours and 402 shadows, where we have a token system (row 11).

A perfect port would gain about 0.2. The gap from the bar is in the target, not in the port.

## 6. The way forward: options, ranked

| Rank | Option | Ceiling (of the bar) | Cost (agent-hours) | Risk | Fit with Godot Compatibility and §21.3 |
|---|---|---|---|---|---|
| 1 | **A. Authored-asset pipeline.** UI art authored as SVG/HTML (from the design's own sources), baked offline in headless Chromium into atlases; 9-slices, sprites and baked numerals; icons painted, or rendered from the `.glb` models | 70–80% as an engineering pipeline alone; 75–85% with D as its author | about 80 with D (section 3) | Agent-authored art can still be generic without key frames and a reviewer, which is why C goes with it. Texture memory: one 1024² atlas a screen family, about 4 MB of video memory uncompressed. High contrast needs its own bake. | Good. Textured quads are cheaper per pixel than `rb_box`'s signed-distance shader. One atlas batches. The proof is at 147 calls (section 7). No post-processing. Words stay live, so the strings tables and text scale still work. |
| 1 (with A) | **D. An AI UI artist agent** (section 9). A standing agent that owns all UI art: it models, lights and finishes icons; authors frames, buttons and key frames; bakes motion sprites; scored by C | 75–85% (section 9.4) | about 60 of A's 80 hours are its work | Taste and novelty: shapes from primitives, no painterly brushwork, no image generation here. Covered by the owner approving its style board and key frames, and by AD's gate. | Same as A: everything it makes is baked into atlases; nothing new runs on the phone. |
| 2 | **C. Process: a standing art director, the rubric and a quality gate** | No pixels by itself; +5–10 points from better choices | about 10 to set up, then about 1 hour a review round | Low. A gate that only checks itself; the owner must calibrate the reviewer on the key frames. | Neutral |
| 3 | **B. A much stronger shader and material system.** Grain, a lit bevel from the signed distance, gradient text through a canvas shader, glow | 45–55% | 25–35 | Per-pixel cost on low-end phones (every panel pays for noise and lighting each frame). GLSL ES 3.0 limits. Icons and type stay as they are. Each look is still tuned by numbers rather than drawn. | Medium. Fill-rate rather than draw calls is the risk. §21.3 forbids full-screen post-processing, so glow and bloom must stay per item. |

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
- Words stay live `Label`s (Lilita One, a multichannel distance field, one ink outline) from the strings tables (`HUD_*`, `HEIST_*`).

**Budget.** The same frame with nothing on top costs 77 draw calls. With the deployed HUD it costs 137; with this HUD, 147, under §21.3's 150.

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
- Top: Get out pressed and let go. It sinks onto its lip and squashes to 92%, then springs back past its size with a back-ease and settles, all within 0.4 s.
- Below: coins fly in a stagger along an arc into the loot panel's bag. The number rolls up as each lands and the panel pulses. The lower row's columns are fractions of the flight, not the stamped times.

These are the curves a screen would tween along. A still strip is how the art director would judge motion.

**What it does not show.**
- An idle shine sweep, and sound.
- 200% text: the 9-slices stretch, but the prototype lays the HUD out at fixed sizes. A kit version would size its frames from the words, as the kit's boxes do now.
- Rendered icons: the HUD's icons are vector paintings. Section 9 shows the rendered route the AI UI artist would use.

Against the rubric, the heist goes from 1.5–2 to about 3.5 on qualities 1–3. On qualities 1–3, that is roughly what one agent day of option A buys.

**Findings for the kit's owners (not fixed here: not my files).**
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
- `tools/ui_research/icons.html` and `bake_icons.js`: the AI UI artist's icons. Run `npm ci` in `tools/ui_research/` once for three.js.
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
1. **Model.** Build the object from geometry: an extruded star with a deep rounded bevel; a lathed drop; a faceted brilliant cut; a chest from rounded boxes, half-cylinders and a painted plank texture (a canvas drawn in code: seams and grain strokes). Characters would come from their `.glb` models.
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

The crew badge is **Pip**, rendered from the character's own model (`skyskipper.glb`, with its painted textures) and standing out of a gold ring. It is shown against today's heist portrait and the design's. It proves the route for every character, Sage and building icon, from the 43 models the game already has. Each icon took 10–30 minutes of modelling and two or three rounds of looking at the render and correcting it:
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

With AD's gate and the owner's approvals, the AI UI artist is likely to reach **75–85% of the bar**. It falls short in these places:
- **Charm and invention.** Its shapes come from primitives and code. A Clash gem has exaggerated, characterful facets and painted colour shifts that a person invented. The AI artist's gem is correct, not memorable. Mascots, the logo and hand-lettered titles are where this shows most.
- **Painterly texture.** With no image-generation tool here, there are no brushstrokes. Texture is procedural (grain, planks, noise), which reads as clean 3D rather than painted.
- **Taste across a whole set.** The AI artist sees each render and corrects it (every fix in section 9.3 came from looking). But it judges one piece at a time, and drifts unless held to a reference.
- **Frame-by-frame effects.** Bursts and particles can be baked from procedural shapes. Hand-timed effect animation, the Spine or Animate kind, is beyond it.

How the plan covers those:
1. **The owner approves the style board and the five key frames** before production. Invention is concentrated where a human eye decides once, and the AI artist then executes the approved look at volume, where it is strong.
2. **AD scores every piece** on the rubric, at 48 px and in grayscale, against the approved board, and blocks anything below 3.5 on qualities 1–3. That stops drift.
3. **Consistency is enforced in code:** one studio, one outline, one glint, one palette file. The set cannot quietly diverge.
4. **If an image-generation tool is connected later,** it slots in at step 4 of section 9.2 as a texture and paint-over source, under the same gate. That is the most direct way past the painterly limit.

## Stopped here

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

The bakes (`tools/ui_research/bake_hud.js`, `bake_icons.js`, `pack_atlas.py`) are the starting point for K1 and the AI UI artist in section 3.
