# Build or buy: existing UI kits and assets (T16)

The plan (`report.md` section 3) has the AI UI artists author every piece of interface art. The owner asked whether that is right: would buying or adopting existing kits, icons, effects, fonts or tools save hours without making Ruleborn look generic? This page answers it. The kit being built is `kit-spec.md`.

Nothing was bought, downloaded into the repository or committed. Every candidate below is listed with its link and a licence summary from the source or from search summaries; where a source could not be opened, it says so. **Licence summaries are not legal advice**, and each must be read in full before anything is adopted.

## 1. The rule that decides most of this: §21.11

§21.11, "Made, not licensed", says: "Nothing in this game is paid for." It allows outside material in only three cases:
- **Fonts:** Open Font Licence only.
- **Sound, if not generated:** public-domain dedication only, with no attribution licences.
- **Code:** permissive licences only.

For everything else its rule is "Made for this game".

It also explains why: attribution licences "create a chain that must be kept accurate forever", "royalty-free" is not free, and a licence ledger records every outside file.

So under the design document as written:
- an OFL font may be adopted, but §21.8 names the three faces, so a new face also needs §21.8 changed;
- permissive code (MIT, Apache, BSD) may be adopted;
- **no outside art may be adopted at all**: not a paid kit, not a free CC0 kit, not an icon pack, not an effects pack.

Adopting any outside art is therefore an owner decision to change §21.11 (decision D11, `report.md` section 12), and any purchase is a further decision with its price (D12).

## 2. Candidates

"Ceiling" is how far the candidate could take its part of the interface on the rubric (`report.md` section 4), where 5 is Clash level. "Generic risk" is how likely players are to recognise it from other games.

### 2.1 Commercial mobile game UI kits

| Candidate | What it gives | Ceiling | Generic risk | Licence (summary) | Price | Fit with Godot 4.7 Compatibility and §21.3 |
|---|---|---|---|---|---|---|
| Layer Lab, "GUI Pro – Casual Game" ([itch.io](https://layerlab.itch.io/gui-pro-casual-game); also on the Unity Asset Store) | 1,200+ PNGs: sliced buttons, frames, popups, sliders, pictogram and item icons. No PSD or SVG sources | 3–3.5 on materials (glossy casual capsules on lips); 2.5–3 on icons | **High**: one of the most-sold casual kits; its buttons appear in many games | Commercial use and modification allowed; resale and redistribution prohibited; heavy use or more than one project needs the publisher (from search summaries; the licence text was not opened) | $39.99 | PNGs pack into our atlases and 9-slice fine. But no sources: no high-contrast twins, no school tints, no rebuild from code, so it breaks the bake's versioning (`report.md` section 10.7) |
| Other Layer Lab packs ("Simple Casual", "Fantasy RPG") ([itch.io](https://layerlab.itch.io/gui-pro-simple-casual)) | Same shape of product in other styles | as above | High | as above | about $30–40 each | as above |
| Envato Elements game GUI packs ([example](https://elements.envato.com/game-button-elements-SEEAV6R); [licence](https://help.elements.envato.com/hc/en-us/articles/360000628966-License-Terms)) | Buttons, panels, icons, often with PSD or AI sources | 2.5–3.5, varies | High | One licence per project; may not be redistributed as-is; registered per project while subscribed | Subscription (price not confirmed in search) | Sources sometimes included, so twins could be made by hand; still outside art |
| Unity Asset Store kits in general ([Unity's answer](https://support.unity.com/hc/en-us/articles/34387186019988-Can-I-use-assets-from-the-Asset-Store-with-other-engines)) | Many Clash-like kits | varies | High | Unity says assets may be used in other engines under its EULA, but not redistributed so that others can extract them; a third party reports the EULA requires downloading through Unity itself, and some assets are limited to Unity ([GameFromScratch](https://gamefromscratch.com/using-asset-store-assets-in-other-engines-is-it-legal/)) | varies | Unity prefabs are useless here; only the PNGs carry over |
| GameDev Market kits ([licence news](https://gamedevmarket.net/news/nfts-gamedev-market-asset-licenses/)) | Casual and fantasy GUI packs | varies | High | Pro Licence: no sharing or redistributing outside the finished product; a publisher reads that as forbidding source files in a repository others can fetch (search summaries; the full licence was not opened) | varies | as Layer Lab |

### 2.2 Free and CC0 kits

| Candidate | What it gives | Ceiling | Generic risk | Licence | Price | Fit |
|---|---|---|---|---|---|---|
| Kenney, "UI Pack" ([itch.io](https://kenney-assets.itch.io/ui-pack)) | Flat buttons, panels, sliders, checkboxes in several colours | 1.5–2: flat, no material, no lip | **Very high**: in thousands of jam games | CC0 1.0: any use, no attribution | Free | Fine technically; far below the bar |
| Kenney, "Particle Pack" ([Godot Asset Library](https://godotengine.org/asset-library/asset/784)) | About 80 particle sprites (sparks, smoke, light shapes) | Particles are small and tinted, so they can reach the juice's needs once finished in our bake | Low once tinted and composited | CC0 | Free | Good: sprites into the motion atlas |
| Parchment, 2D vector fantasy UI ([itch.io](https://denizen-games.itch.io/parchment-2d-vector-based-ui-for-fantasy-games)) | A Figma file of fantasy UI; still in development | 2.5 | Medium | CC BY 4.0: attribution required; its icons come from another pack with its own terms | Free | Vector, so it could be baked; attribution is what §21.11 rules out |

### 2.3 Icon packs

| Candidate | What it gives | Ceiling | Generic risk | Licence | Price | Fit |
|---|---|---|---|---|---|---|
| game-icons.net ([about](https://game-icons.net/about.html)) | 4,000+ flat silhouette icons | 1.5–2: flat glyphs, the opposite of rubric quality 3 | Very high | CC BY 3.0: credit each author | Free | Excluded by §21.11's attribution rule |
| Icons inside commercial kits (2.1) | Painted item and currency icons | 2.5–3 | High | as their kit | as their kit | No sources; they would not match our models or characters |

No icon pack can supply Ruleborn's own things (its 43 characters, its laws, its schools' shapes, its buildings), which are most of the 60 most-seen icons.

### 2.4 Effects (VFX) for reward juice

| Candidate | What it gives | Ceiling | Generic risk | Licence | Price | Fit |
|---|---|---|---|---|---|---|
| Kenney Particle Pack (2.2) | Base particle sprites | as above | Low | CC0 | Free | Good |
| Cartoon FX Remaster by Jean Moreno ([Unity Asset Store, free version](https://assetstore.unity.com/packages/p/cartoon-fx-remaster-free-109565)) | Toon bursts, sparkles, coins as Unity particle systems with custom shaders | High in Unity | Medium | Commercial use in games allowed (its readme, from search summaries) | Free version; paid packs about $9–30, a bundle about $48 (a sale snapshot) | **Poor**: built from Unity particle systems and shaders that do not run in Godot; only some textures carry over, and the EULA's download terms apply |

### 2.5 Fonts

| Candidate | Licence | Fits §21.11 | Note |
|---|---|---|---|
| Lilita One (in the game) | SIL OFL 1.1 | Yes | Already the display face (`client/ui/fonts/LEDGER.md`) |
| Titan One ([online-fonts](https://online-fonts.com/fonts/titan-one)) | SIL OFL 1.1 (third-party summary; Google Fonts' page not opened) | Yes, but §21.8 names three faces | A heavier, rounder display face, nearer the benchmarks' type; worth putting on the style board beside Lilita One under D4 |
| Fredoka | SIL OFL (from a kit's notes; not verified at the source) | Yes, with the same §21.8 caveat | Rounded; softer than the bar |
| Luckiest Guy ([online-fonts](https://online-fonts.com/fonts/luckiest-guy)) | Apache 2.0 | **No**: §21.11 says OFL only | Strong comic display face; a separate commercial "Pro" version exists |
| Supercell-Magic (Clash Royale's face) | Proprietary to its owner | No | Named only because the benchmark uses it |

### 2.6 UI animation tools with Godot runtimes

| Candidate | Godot 4 runtime | Licence of the runtime | Price | Fit |
|---|---|---|---|---|
| Spine ([runtime docs](https://eu.esotericsoftware.com/spine-godot); [purchase](https://en.esotericsoftware.com/spine-purchase)) | Yes, official: a GDExtension (no AnimationPlayer support) or a custom engine module (needs custom editor and export builds) | Free to integrate, but every user of the software must hold a Spine licence, so distributing needs a licence at integration: not a permissive licence | Essential $99 (on sale at $69 when checked), Professional $439 ($369 on sale), one-time; Enterprise from $2,499 a year above $500,000 revenue | **Conflicts with §21.11** (paid; not permissive). Also a GDExtension in a mobile Compatibility build, and an editor no agent here can run |
| Rive | **No official Godot runtime found.** A community GDExtension wrapping Rive's C++ runtime is marked alpha, with macOS builds only ([kibble-cabal/godot-rive](https://github.com/kibble-cabal/godot-rive)). Rive's own runtimes page could not be found through search | The community wrapper's licence was not checked | Rive's editor has paid plans (not checked) | Not ready for an Android and iOS release |

### 2.7 Godot themes and addons

| Candidate | What it gives | Licence | Fit |
|---|---|---|---|
| TweenFX ([Godot Asset Library](https://www.godotengine.org/asset-library/asset/4827)) | Juicy tween helpers (shake, pop) | MIT | Allowed by §21.11, but the kit's `Motion` already does this with reduced forms |
| Ui Juicer ([Godot Asset Library](https://godotengine.org/asset-library/asset/3617)) | A bounce button, fades | MIT | as above |
| Godot 4 UI Juice Kit ([itch.io](https://miisan.itch.io/godot-4-ui)) | Bouncing buttons, rolling counters, shake | MIT; in development | as above |
| Kenney's Godot themes | Flat themes | CC0 | Art: excluded by §21.11, and far below the bar |

None gives anything the kit lacks. Reading their counter-roll and bounce code is allowed and free; adopting it adds a dependency for little.

### 2.8 Figma kits and Figma-to-Godot routes

- **Figma community game UI kits** carry mixed licences: CC BY 4.0 (Parchment, above), single-project commercial licences without the `.fig` file (for example the Cozy Café kit on ArtStation), or platform-only licences. None was found under a licence §21.11 allows.
- **Figma to Godot:** no maintained importer was found. The nearest is a 2024 experiment that imports Figma layouts with "functional limitations" and open bugs in gradients, shadows and effects ([r/godot thread](https://redlib.hbubli.cc/r/godot/comments/1gbohkt/figma_export_to_godot_progress)). A PSD-to-Godot importer exists on the Godot forum.
- **Our own route already does this job:** the key frames and skins are HTML and SVG, baked in headless Chromium (`report.md` section 7). Figma would add an editor no agent here can drive, and an export step that loses the effects the bake keeps.

## 3. What adopting would save

The plan's art hours, and what each candidate could replace:

| Plan work | Hours | What could replace part of it | Hours saved | Why not more |
|---|---|---|---|---|
| Style board and key frames (AIA) | 16 | Nothing | 0 | The identity is the point; a bought kit's look is someone else's |
| Kit art: 35 skins with states and twins (AIA) | 16 | A commercial kit's buttons and frames | 4–6 at most | Its pieces still need our states, school tints, high-contrast twins and outlines redrawn, and it has no sources to bake from; and it makes the kit look like other games |
| Icons: 60 (AIA-2) | 28 | Nothing that fits: our characters, laws, schools and buildings are ours | 0–2 (a few generic items) | Icons from packs would clash with the rendered ones |
| Motion art (AIA) | 10 | CC0 particle sprites (Kenney) | 2–3 | The sequence's timing, the coin and the counter are ours |
| Display font | 0 | An OFL face (Titan One) under D4 | 0 | It costs nothing either way; it changes the look, not the hours |
| Motion code (K1) | in K1's 31 | MIT juice addons | 0–1 | `Motion` already exists with reduced forms |

At best, adopting outside art saves about 3 hours with CC0 particles, or about 8 hours with a commercial kit as well, out of 158. The commercial kit's saving comes with the biggest cost in the rubric: quality 14, "one art-direction idea", and the owner's bar of "three times Screens v3".

## 4. Recommendation

**Build, with three small adoptions.**

1. **Author everything that makes Ruleborn itself** (style board, key frames, the 35 skins, the 60 icons, the reward sequence) with the AI artists, as the plan says. Nothing on the market supplies these, and the generic look of the kits that come closest would cost more on the rubric than the hours they save.
2. **Adopt, within §21.11 as written:**
   - **an OFL display face to compare at the style board:** Titan One beside Lilita One, decided under D4 (it is a §21.8 change either way). Cost: none. Ledger: one row in `client/ui/fonts/LEDGER.md` if adopted;
   - **no code:** the MIT juice addons duplicate `Motion`.
3. **Ask the owner (D11) to allow CC0 particle sprites** as raw material for the reward sequence: Kenney's Particle Pack, always recoloured, finished and baked through our pipeline, each source file recorded in a new art ledger. It saves about 3 hours, costs nothing, and its risk of a generic look is low. It needs one line added to §21.11 (`plan-review.md` X11).
4. **Do not buy** a commercial kit, an icon pack or an effects pack, and do not adopt Spine or Rive. Spine's runtime licence is not permissive and costs $69–439 a seat; Rive has no official Godot runtime. If the owner wants to buy anyway, it is D12 with its price.

**What this does to the plan.**
- **Hours:** 158 without D11; 155 with it (motion art 10 → 7).
- **Schedule:** unchanged; the saving falls on day 5, inside AIA's motion step.
- **Ceiling:** unchanged at 3.75–4.25. Nothing adoptable raises it; a commercial kit would lower quality 14.
- **Ledger:** with D11, K1 adds `client/ui/art/LEDGER.md`, in the pattern of the fonts' ledger: file, source, licence (CC0 1.0), link, SHA-256 of the downloaded file, and which baked pieces use it. The downloaded files stay outside the repository; only the baked results and the ledger are committed.

## 5. Sources

Opened only through search summaries (pages not fetched): every link above. Not found: Rive's own statement of Godot support; the full texts of the Layer Lab, GameDev Market and Envato licences; Google Fonts' licence pages for Titan One and Fredoka.
