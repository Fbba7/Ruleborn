# Are the handoff's screens the screens the earlier reading analysed?

Part: diff. Sources: the handoff's `prototype/` (here `P/`), the artifact unpacked at `scratch/art/` (here `A/`), and the earlier reading in `docs/analysis/screens-v3/`. Neither `P/` nor `A/` is kept in the repository; the hashes of `P/` are in `data/prototype.md5`. The handoff's own documents are in `source/`, so README.md:65 is `source/README.md` line 65. Read against the repository at commit 6cc1d1e; the line numbers it cites in the register (AR), the brief and the roadmap (RM) are that commit's. What it proposes was checked and folded into the register's v3.6 layer, the brief and stage SD afterwards ([README.md](README.md)). The earlier reading's reports, cited by file name, are in the folder above.

## Answer

Yes. They are the same screens. The only difference is one row of the index's side-panel notes, which sits outside the phone frame.

- **RulebornMeta.dc.html** (screens 10 to 27, the nav bar) is byte-identical to the artifact's copy. Both hash to `93de9883…b184f8`.
- **Ruleborn Screens v3.dc.html** (the root: index, phone frame, screens 01 to 09 and 22) holds the same markup, text, numbers and bindings for all 13 `data-screen-label` blocks, once the bundler's re-serialisation is undone.
- **The script** is the same except for line 68, which is the `friends` row of the `SCREENS` notes table. A player never sees that row: it fills the index page's "MUST SHOW (23.2)" and "TRY" panel. The Friends screen itself is in RulebornMeta and is unchanged.
- **The data module** is the same: `P/ruleborn-data.js` equals `A/named/data_v35.js`. Both are `a184ffa231821559b3f5c73151a592a8601dd15d18aa40e4a16d018a7b6bb70d`.
- **Every file the two screen files load** matches the artifact's copy by sha256. That is 8 scripts plus 223 resource dependencies.
- **15 of the handoff's 244 prototype files have no copy in the artifact.** None of them changes a screen's content. Details are in §4.

So every finding the earlier reading made about a screen still holds for the handoff, and the 28 phone-size screenshots in `scratch/shots/all/` stand. Two follow-ups were needed, and both were made:

- One analysis sentence quotes the old note (finding DIFF-1).
- About 700 line citations point into artifact-only file names. They needed a fixed map to the handoff's files (finding DIFF-2), which is now [the analysis README's line map](../README.md).

## 1. How the files were compared

- **Extraction.** From `P/Ruleborn Screens v3.dc.html` I took three pieces:
  - the `<x-dc>` block (lines 232–840);
  - the `data-props` attribute of `<script type="text/x-dc" data-dc-script>` (line 841, HTML-unescaped);
  - the script body (lines 841–1518).
  
  The extraction script was `scratch/diffwork/extract.py` (not kept), run with `python3 -I`.
- **Artifact side.** `A/named/screens_main.js` and `A/named/screens_main.markup.html` are byte-identical to the bundle's `A/src/template_xdc_9.js` and `A/src/template_xdc_markup.html` (checked with `cmp`), so the unpacking was faithful. Its props are `A/src/template_props_9.json`.
- **Props.** Parsed as JSON, the two sides are equal. They hold `heistOutcome` (Clean, Loud, Partial, Foiled; default Loud), `leftHanded` (default false) and `ageBand` (18+ or 13–15; default 18+).
- **Script.** A plain `diff` gives one changed line (68). Line count and every other line are identical. As a check, root-file line N+840 equals `screens_main.js` line N for every N except 1 (the tag remainder), 68 and 678 (the closing remainder).
- **Markup.** Each side was parsed into a token stream with Python's `html.parser` (`tok.py`, `cmpbody.py`, `perlabel.py`). The parse undoes what the bundler changed and nothing else:
  - `sc-camel-on-click` becomes `onClick`;
  - `<stop/>` and `<stop></stop>` count as the same thing;
  - `data-comment-anchor="…"` attributes (the design tool's comment pins) are dropped;
  - `data-scout-deck=""` and `data-scout-deck` count as the same;
  - `url('world/portraits/x.png')` and `url("<uuid>")` both resolve to the resource id `w_world_portraits_x_png`, through the artifact's `index.json` `ext` map;
  - the handoff-only `<template id="__bundler_thumbnail">` is removed.
  
  Attribute order and whitespace in text are ignored. A planted one-letter change in a text run is detected (mutation test passed).
- **Result.** After normalisation, the 3,321 tokens from `</helmet>` to `</x-dc>` are equal on both sides, in the same order.

## 2. Per screen (root file)

Only the Index aside and the Notes aside are outside the phone frame. The other 11 rows are the screens. "Equal" means the whole token slice is the same: tags, attributes and styles, text, numbers and `{{ }}` bindings.

| data-screen-label | Root line (handoff) | Artifact markup line | Tokens | Text runs | Numbers in literal text | Bindings | Equal |
|---|---|---|---|---|---|---|---|
| Index | 238 | 313 | 115 | 17 | 8 | 44 | yes |
| Phone (frame, nav, overlays) | 288 | 363 | 3,172 | 364 | 29 | 843 | yes |
| 01 Universe map | 291 | 366 | 690 | 56 | 16 | 112 | yes |
| 04 Realm view | 395 | 470 | 462 | 62 | 1 | 170 | yes |
| 05 Weaving | 503 | 578 | 179 | 25 | 0 | 74 | yes |
| 08 Observatory | 551 | 626 | 533 | 33 | 3 | 76 | yes |
| 09 Scout report | 599 | 674 | 301 | 43 | 0 | 79 | yes |
| 06 Heist planner | 668 | 743 | 135 | 17 | 1 | 47 | yes |
| 22 Landing picker | 696 | 771 | 207 | 33 | 1 | 51 | yes |
| 02 Heist | 707 | 782 | 219 | 29 | 4 | 85 | yes |
| 07 Heist result | 750 | 825 | 186 | 30 | 1 | 63 | yes |
| 03 Law card | 796 | 871 | 195 | 33 | 0 | 54 | yes |
| Notes (index side panel) | 823 | 898 | 29 | 7 | 1 | 5 | yes (the markup; its text comes from the script, see below) |

The Phone slice contains the screen slices nested inside it, so its counts include theirs.

**Logic.** Every screen's state, handlers, numbers and strings are in the one script class. That class is identical apart from line 68: `REALMS`, `BUILDS`, `L` (laws), the heist and planner logic (for example the Carrier gate that N14 cites, `screens_main.js:584`/`605`, which is root lines 1424/1445), the landing clocks, the strain band and the result outcomes.

**RulebornMeta.dc.html** is byte-identical, so its 18 labels are identical too. They run from "10 Roster" to "27 Friends", and include "19b Player stats" and "23 Harmony view". Its props are identical as well (`$preview` 390×844; `screen` takes 17 values, default roster).

**Mounting.** README.md:65 says the root mounts RulebornMeta and passes it `screen`, `go`, `tabs`, `openLaw` and `ageBand`. The markup confirms it: `<dc-import name="RulebornMeta" screen="{{ metaScreen }}" go="{{ go }}" tabs="{{ tabs }}" open-law="{{ openLawFn }}" age-band="{{ ageBand }}">`. This is the same on both sides.

### The one difference: `SCREENS` row `friends` (handoff root line 908 = `screens_main.js:68`)

This row is shown only in the index's Notes aside, under "MUST SHOW (23.2)" and "TRY" (`Ruleborn Screens v3.dc.html:823–835`).

| | Artifact (`screens_main.js:68`) | Handoff (`Ruleborn Screens v3.dc.html:908`) |
|---|---|---|
| MUST SHOW | "Who's online, the friends' feed, friendly heists that take nothing (12.11), **page gifts, preset pings and invites (17.6)**" | "Who's online, the friends' feed, friendly heists that take nothing (12.11), **cosmetic gifts, preset pings, invites and add-by-code (17.6), block and report (17.8)**" |
| TRY | "Tap a friend at the top **to open their island, ping them or start a friendly heist; switch to Friends and send a page**" | "Tap a friend at the top **for their island, record, pings and a friendly heist. Raid back from the rematch card in the feed; add friends by code on Invite**" |

What this means:

- **Player view.** Nothing changes for the player. The Friends screen itself is unchanged.
- **The new note matches the screen.** The screen already drew the friend sheet with its record ("3 · You lead · 1"), the "Raid Tomas back" hero card, ADD BY CODE, Block and Report, and "Gift a look". All of these are in RulebornMeta, which is identical.
- **The new note is closer to v3.6.** Cosmetic gifting is §22.4 (doc:11173, "Players can gift cosmetics to friends"). Page gifts belong to crews and constellations from 1.1 (§17.4, doc:2221, doc:8959). §23.2's row is "Friends' feed, friendly heists, invitations, gifts" (doc:11311–11313).
- **What the new note still gets wrong:**
  - It still files "preset pings" under 17.6. §17.6 has no pings; that is register D86.
  - It credits "report" to 17.8. §17.8 covers blocking only; reporting is §20.4 (doc:10223).

## 3. Files the two screen files load

### The root file

- `support.js` is loaded from `<head>`.
- The `<helmet>` holds an importmap that maps `three` to `./three-shim.js`. It then loads `ruleborn-icons.js`, `law-glyphs.js`, an inline `world/`-URL rewriter (identical on both sides), `rb-art.js`, `ruleborn-data.js`, `three-global.js` and `realm-diorama.js`.
- The head also carries 223 `ext-resource-dependency` metas: world PNGs, the 43 character pages and their Hero/Rig pages, model modules, `three-global.js`, and React.

### RulebornMeta

- It loads only `support.js`.
- It uses the host's globals.
- It points iframes at `<Name> Rig.html` (`rigSrc`/`rigArt`, `RulebornMeta.dc.html:916`, the `ch` presenter).
- It uses `world/portraits/*.png`.

### Comparison against the artifact

The artifact files are named by uuid. Each one was found through `A/index.json`'s `ext` id map and `A/template.html`'s script srcs.

| Handoff file | Artifact copy (uuid / named) | sha256 (both) | Same |
|---|---|---|---|
| support.js | 105f16cb…379.js / creatures/support.js | 8fe7df74405f3c55f49b7249c74ea1397e65d07dea2b1bd3b4a489bec2e28cbe | yes |
| three-shim.js (importmap) | 0a91ec2e…4100ee451.js / creatures/three_shim.js | a6cda979bba9c1430fabad7aae906383cc2cf9f41985d3e1270bd7ae1eb9ba04 | yes |
| ruleborn-icons.js | efd94e88…3137b6.js / icons_rbi.js | c2b4677968d5d0e69af43f0e44a328d15daebdfc79fae2d9bdb9a650ececdcfd | yes |
| law-glyphs.js | cc9e8a2b…bdd1b317d76c.js / icons_schools.js | 479e0b6b32671b10abb2b42ae8d08002a1bc317bb6a5d939e7c3c7de864468d2 | yes |
| rb-art.js | 5e12db32…5c7c5279f90a.js / art_loader.js | 46bba2554e5ac949179f9ea4a8989f910b30d29e398f92a168bf113801586fe2 | yes |
| ruleborn-data.js | cad91930…16d018a7b6bb70d.js / **data_v35.js** | a184ffa231821559b3f5c73151a592a8601dd15d18aa40e4a16d018a7b6bb70d | yes |
| three-global.js | f856fef1…a93c481df314.js / creatures/three_global.js | de5afe20009e775b79e69d0c66a449d4c527d892dc62ef440b44f9bd5db29f75 | yes |
| realm-diorama.js | 747b52f7…c2e2a7233354.js / realm_diorama.js | 17da611533597526b3fc2f1691333fd1016d3ee1505ed3f84aaedc774d36cba8 | yes |
| RulebornMeta.dc.html | 748ade08…411c73a601ec.html / RulebornMeta.dc.html | 93de9883521a2957ca4665e8726a5b4861384d8e9f35887fa1b424bb8cb184f8 | yes |
| react.production.min.js | 19d582c3….js / creatures/react_production_min.js | d949f1c3687aedadcedac85261865f29b17cd273997e7f6b2bfc53b2f9d4c4dd | yes |
| react-dom.production.min.js | 2c5db1a7….js / creatures/react_dom_production_min.js | 35f4f974f4b2bcd44da73963347f8952e341f83909e4498227d4e26b98f66f0d | yes |
| The other 212 `ext-resource-dependency` files (world/land ×6, world/portraits ×24, world/obs ×4, world/scout ×4, 43 × `.dc.html`, 43 × Hero, 43 × Rig, model modules) | by `data-resource-id` → `index.json` uuid | each pair equal | 223 of 223 yes |

**Fonts.** The handoff root links Google Fonts (`Manrope:wght@400;…;900`, `Lilita One`, `Marcellus`). The artifact inlined the subsets Google serves: Manrope 400–800 (6 files), Lilita One 400 and Marcellus 400. These are the same faces and weights, and there is no Manrope 900 face on either side. The handoff ships no font files; README.md:120 and :210 say to take them from Google Fonts under the OFL. This is covered by TD.2 and D90, and by design-system.md:119, which already records "Google Fonts subsets" and that 900 renders as 800.

**Bundled and unbundled runs take different code paths.** The content is the same, but:

- The artifact sets `window.__resources`. As a result, the world-image rewriter swaps `world/…png` for resource URLs, and RulebornMeta's character iframes use `rigArt` through `rb-art.js`.
- The handoff, opened from disk or a server, has no `__resources`. Its images load by relative path, and its iframes load `<Name> Rig.html?embed=1&clip=idle` directly (RulebornMeta `rigSrc`).
- Both paths draw the same files.

## 4. The 15 handoff files with no copy in the artifact

| File | Loaded by a screen? | Effect on what the earlier reading saw |
|---|---|---|
| Ruleborn Screens v3.dc.html | root | §1–2: one notes row differs |
| skyskipper-game.bin | yes: `Skyskipper Rig.html:81` loads it. `realm-diorama.js:585` names it too, but that loader's only caller, `upHero`, is gated by `RB_HEROES`, which nothing sets, so the diorama never loads it | The artifact had no `.bin`. `loadBaked` catches the failed fetch (`skyskipper-sculpt.js:176`, `.catch(()=>{})`), and `buildSkyskipper` then builds the same SDF mesh at the same resolution (.0081) and caches it under the same key. Same model, slower first draw. Not a content difference. |
| archivist-game.bin, archivist-hero.bin, skyskipper-hero.bin | Rig and Hero pages (Character screen iframe, character sheets) | Same fallback (`creature-kit.js:57-58` catches and builds). Not a content difference. |
| mossbear.bin, featherkin.bin | `mossbear.js` and `featherkin.js` `BIN` constants | Same fallback. Not a content difference. |
| three.core.js, three.module.js | no. The Hero and Rig pages import three r184 from unpkg with SRI (`Archivist Rig.html` importmap: `https://unpkg.com/three@0.184.0/build/three.module.js`, `…three.core.js`). The screens use `three-global.js` through `three-shim.js`. | None. These are local copies listed in README.md:211 only. |
| world/heist.png, home.png, landing.png, realm.png, result.png, workshop.png | no. No prototype file and no handoff document refers to them; README.md:209 lists only `land/`, `scout/`, `portraits/` and `obs/`. They are 520-px-wide crops of the diorama, for example `home.png`, which shows "Skyfield · 2 laws · lv 4" and "The Heart · Spire 7 · Vault 6". | None on the screens. They belong to the assets part. |

In the other direction, every file in `A/named/` has a byte-identical handoff copy, except the four split files `screens_main.js`, `screens_main.markup.html`, `screens_meta.js` and `screens_meta.markup.html`. Those four are the artifact's split of the two `.dc.html` files.

## 5. Mapping the earlier reading's citations to the handoff

The register, the brief and the analysis cite lines and names in the artifact's split files. A grep finds about 709 such citations, on 106 lines of `tools/audit_register.py`, 29 of `docs/decisions/brief.json` and about 345 of `docs/analysis/screens-v3/*.md`. None of these files exists in the handoff. The offsets and renames that resolve them were each checked line by line. They are kept in one place, [the analysis README's line map](../README.md) (section "Sources and line map"). Aligned markup lines that are not byte-equal differ only in serialisation (§1).

Spot checks:

- D86's "screens_meta.js:1241" maps to RulebornMeta.dc.html:1889, which holds the "Raiding Ines" row.
- Its "markup 607" maps to :615, which holds the same line.
- N14's "screens_main.js:584" maps to root :1424, which holds "No Carrier: nobody can carry loot out".

## 6. Findings

### DIFF-1 (stale, low): the Friends note quoted in the analysis is no longer the handoff's note

`docs/analysis/screens-v3/screens-season-shop-share-friends-stats.md:333` said: "The design's own note adds 'Who's online', 'page gifts' and 'preset pings' … Page gifts are not drawn (the TRY note's 'send a page' has no control)". The handoff's note (`Ruleborn Screens v3.dc.html:908`) no longer says "page gifts" or "send a page". It now reads "cosmetic gifts, preset pings, invites and add-by-code (17.6), block and report (17.8)", and the TRY line reads "Raid back from the rematch card in the feed; add friends by code on Invite". The conclusion still stands: the screen draws no page gifts, and page gifts are 1.1 crew and constellation features (§17.4).

Done: the sentence now says what the handoff's note says, that page gifts belong to constellation members from 1.1 (§17.4) and to crews (§17.7), and that report is §20.4. Nothing in the register changes, because D86 already holds pings and presence.

### DIFF-2 (stale, medium): the analysis has no map from its citations to the handoff's files

The analysis README (`docs/analysis/screens-v3/README.md`, "How it was read") said the designs were "unpacked from the artifact the owner shared". It never said that `screens_main.js`, `screens_main.markup.html`, `screens_meta.js`, `screens_meta.markup.html` and the underscore names are the artifact's split and renamed files. Those names are not in the handoff. The SD tasks will be built from the handoff, and roughly 709 citations in the register, the brief and the analysis use these names and line numbers.

Done: the analysis README now has a "Sources and line map" section with the offsets and renames, the statement that the handoff's screens are proven the same (§1–2) apart from DIFF-1, and the data module's sha256. The register's and brief's evidence strings keep the old names, so the README map is the single place a reader resolves them.

## 7. Coverage

| Item | Status |
|---|---|
| Root file `<head>`: 223 resource metas and `support.js` | identical files (§3) |
| Root `data-props` (heistOutcome, leftHanded, ageBand) | equal |
| Root helmet: keyframes, style, importmap, inline world-URL rewriter, 6 script srcs | equal after normalisation; srcs map to identical files |
| Root helmet fonts: Google Fonts link in the handoff, inlined subsets in the artifact | same faces and weights; handoff ships no font files; covered by TD.2/D90 and design-system.md:119 |
| `__bundler_thumbnail` template | handoff only; never shown on a screen |
| Index aside (markup) | equal |
| Phone frame, nav bar, overlays | equal |
| 01 Universe map | equal |
| 04 Realm view | equal |
| 05 Weaving | equal |
| 08 Observatory | equal |
| 09 Scout report | equal |
| 06 Heist planner | equal |
| 22 Landing picker | equal |
| 02 Heist | equal |
| 07 Heist result | equal |
| 03 Law card | equal |
| Notes aside (markup) | equal |
| Script, every line but 68 (all screen logic, numbers, strings) | equal |
| Script line 68, the `SCREENS.friends` notes row | differs; not player-visible; new finding DIFF-1 |
| RulebornMeta.dc.html (screens 10–27, 18 labels, props, script) | byte-identical |
| README.md:65 (root mounts Meta with screen, go, tabs, openLaw, ageBand) | confirmed in markup |
| support.js, three-shim.js, ruleborn-icons.js, law-glyphs.js, rb-art.js, three-global.js, realm-diorama.js | sha256 match (§3) |
| ruleborn-data.js equals data_v35.js | confirmed (a184ffa2…) |
| The other 212 resource dependencies (world art, 43 × 3 character pages, model modules, React) | sha256 match, 223 of 223 |
| "229 of 244 prototype files byte-identical" | confirmed: 15 without a copy (§4) |
| skyskipper-game.bin (loaded by realm-diorama.js:585 in universe, scout and plan modes) | artifact fell back to the identical procedural build; no screen difference; .bin content left to the assets/3D part |
| archivist-game/-hero.bin, skyskipper-hero.bin, mossbear.bin, featherkin.bin | same fallback; no screen difference; left to the assets/3D part |
| three.core.js, three.module.js | not loaded locally (pages use unpkg with SRI); no screen difference |
| world/{heist,home,landing,realm,result,workshop}.png | loaded by nothing; no screen difference; left to the assets part |
| Bundled and unbundled runtime paths (`__resources`, rigSrc and rigArt) | same files, same content |
| shots/all/ (28 phone-size screens) | still valid for the handoff |
| Analysis citations into split and renamed files | new finding DIFF-2 |
| Friends note "preset pings (17.6)" | covered by D86 |
| Friends note "report (17.8)" | folded into DIFF-1 (report is §20.4) |
