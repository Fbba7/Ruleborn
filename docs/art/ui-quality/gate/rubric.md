# The gate's rubric

**Version 1** (P0-AD-rubric, 30 October 2026). Owner: AD. Not yet calibrated:
every judged quality runs in shadow mode until `calibration.md` says it meets
its target (section 3.5 of `report.md`).

This is what the gate checks, quality by quality. It turns the 14 qualities of
section 4 of `report.md` into pass and fail criteria, folds in the design
document's rules where they are stricter or different (section 4.3 of
`report.md`; the design document wins, §23.5), gives the extreme anchors of each
quality (a clear pass and a clear fail), and says how each quality is checked
for each asset class: by a script, by the judge, or by the owner. The judge's
prompts, one per judged quality, are in [prompts/](prompts/README.md).

## How to read it

**The bar is the owner's, not this page's.** A candidate passes a judged
quality when it is at least as good on that quality as the weakest item the
owner labelled pass, and better than the strongest item the owner labelled
fail (section 3.6 of `report.md`). The criteria below are the vocabulary the
judge and the owner share, so that a verdict names what is wrong. They are not
a score: nothing here is rated 0 to 5.

**Each quality has:**
- **Pass needs**: every item must hold. An item marked *(scripted)* is measured
  by a check, not looked at; the judge takes it as given.
- **Fails on**: any one of these is a fail, whatever else is good.
- **Design rules**: the design document's rules that apply, which win over the
  benchmark games where they differ.
- **Clear pass** and **clear fail**: the extreme anchors, in words. Describing
  only the extremes works about as well as describing every level (section
  "LLM judges need pass/fail anchors" of `docs/research/agent-team-operating-model.md`).
  Until the owner labels the golden set (O3), each anchor names a provisional
  still from this repository; after O3, the anchors are the golden set's
  labelled items and these stills are only examples.
- **Method**: who checks it, for each asset class, and what the judge sees.

**Units.** Points (pt) are the design's 390 × 844 frame (§21.1); the client
draws at 1080 × 2340, about 2.8 pixels a point. A **value step** is 10 units of
CIELAB lightness L* (the 0–100 grey scale in ten steps), measured on medians:
the median L* of a control's face against the median L* of a ring of its ground
4 pt wide around its outer edge. "Two value steps" is ΔL* ≥ 20. `tools/ui_gate/`
implements it (P0-AD-sheet).

**The asset classes** are those of section 3.5 of `report.md`: style board, key
frame, kit art, icon, motion and screen. A screen is judged at 100% and 200%
text and in high contrast; the scripted checks also run at 150%.

**Verdicts.** Each judge call answers PASS, FAIL or UNKNOWN for one quality,
names the region, and gives a one-line reason. Each call is made three times
with the order of the pictures shuffled. Three passes pass; three fails fail;
a split takes three more samples, and 4 or more fails out of 6 is a fail,
otherwise it passes and goes on the next board; an UNKNOWN goes to the
exceptions queue (section 3.5 of `report.md`; decision D-06). The lead writes
the verdict file in the format of "The gate, step by step" in
`docs/guides/agent-protocol.md`, with `rubric_version: 1`.

## The method at a glance

| # | Quality | Scripted | Judge | Owner |
|---|---|---|---|---|
| 1 | Layered materials | yes | yes | boards |
| 2 | Display type | yes | yes | boards |
| 3 | Painted or rendered icons | yes | yes | board 2 |
| 4 | Press feedback | yes | no | frame strips; boards 1 and 4 |
| 5 | Reward juice | yes | no | frame strips; board 4 |
| 6 | Hierarchy | yes | yes | boards |
| 7 | Motion and idle life | yes | no | frame strips; boards 3 and 4 |
| 8 | Colour roles and value | yes | yes | boards |
| 9 | Character presence | yes | yes | board 3 |
| 10 | Phone scale and thumb reach | all of it | no | no |
| 11 | One component system | all of it | no | no |
| 12 | Minimal gameplay HUD | all of it | no | no |
| 13 | Light behind UI | yes | yes | boards |
| 14 | One art-direction idea | no | yes | every board |

What the judge checks for each asset class (section 3.5 of `report.md`):

| Class | Scripted | Judged qualities | What the judge sees | Owner |
|---|---|---|---|---|
| Style board | contrast in both modes; colours from the tokens | none: no golden set yet | — | O2 |
| Key frame | targets, text, contrast, live words | none: the owner labels them at O3 | — | O3 |
| Kit art | twins, contrast in both modes, coverage, chrome count | 1, 2, 8, 13 | the catalogue sheet at phone size; full-resolution crops of three components | board 1 |
| Icon | the 2-point outline at the size shown; a dark shape at 32 pt; sizes | 1, 3, 8, 13 | the icon sheet at 48 and 96 pt at native resolution, and its grayscale | board 2 |
| Motion | timings, reduced forms, flashes, shake | none | — | board 4, from frame strips and clips |
| Screen | section 10 of `report.md`, and the scripted column above, at 100%, 150% and 200% text and in high contrast | 1, 2, 3, 6, 8, 9, 13, 14 | the still at 960 px on the long edge; full-resolution crops where the quality says | its board |

A quality that does not apply to an item (quality 9 on a settings screen with
no reward or offer, say) is recorded as not applicable by the launcher, never
judged.

## The qualities

### 1. Layered materials

The interface is built from things that look made: lit, thick and textured,
not flat fills.

**Pass needs:**
1. Every primary button and every panel has at least four layers: a body
   gradient lit from the top; a gloss band over the top 30–45%; a dark,
   hue-matched rim 2–4 pt wide; and a solid lip or drop 3–8 pt deep that gives
   it thickness.
2. Panels have a bevelled frame and an inner well, and the well reads as set
   into the frame.
3. Surfaces carry a material: §21.8's violet card, dark glass, leather,
   parchment and gold, dressed with grain, bevel, gloss and light, not new
   hues.
4. Every skin has its face per state (normal, pressed, disabled, locked) and
   its high-contrast twin *(scripted: `bake.js --check`)*.

**Fails on:**
- a primary control or panel that is a flat fill or a single gradient with no
  rim or lip;
- a material that reads as a web overlay: a uniform rounded rectangle with a
  hairline border and a blur;
- grain, bevel or gloss that is present at full resolution but turns into
  banding, mud or noise at phone size;
- a missing state face or twin *(scripted)*.

**Design rules:** §21.8 (the two surface families, outlined in ink #1A0C14;
high contrast: opaque cards, 3-point outlines, no glass); §21.3 (hand-painted
gradient textures only, no photographic textures).

**Clear pass:** the heist proof's panels in `docs/art/ui-quality/proof-heist-hud.png`,
middle column: the clock and loot panels have a gold bevelled frame, an inner
well, a lip and grain; the Cast and Get out buttons sit on thick lips.

**Clear fail:** the same image, left column (the deployed HUD): the clock is a
flat cream pill, and the panels are single fills with a thin border.

**Method:** scripted: twins and states. Judge: kit art on the catalogue sheet;
icons; screens on the still at 960 px plus full-resolution crops of three
components (one primary button, one panel, one pill), since grain and bevels
vanish when downscaled. Owner: every board.

### 2. Display type

Words and numbers on art read as part of the game: heavy, inked and sized to
be read at a glance.

**Pass needs:**
1. Every word over art (a scene, a texture, a gradient) has an ink outline all
   round at least 1.5 pt or 12% of its size wide, whichever is wider
   *(scripted: client tests)*.
2. Big numbers have a hard drop and a gradient fill as well as the outline.
3. Faces follow §21.8: Manrope for labels, body text and every number that
   changes, with tabular figures; Lilita One only for large numbers that do not
   change and some titles; Marcellus for titles and law names *(scripted: the
   font of each label node)*.
4. Nothing smaller than 13 pt at 100%, 150% and 200% text *(scripted)*.
5. Headers and numbers carry one consistent heavy treatment across the screen.

**Fails on:**
- any unstroked word over art, or a stroke that breaks, thins under 1.5 pt or
  merges into the art behind it;
- a drop shadow standing in for the outline (§21.8: a drop shadow does not
  count);
- a changing number in Lilita One or without tabular figures *(scripted)*;
- words with opacity, or secondary text on a dark surface darker than #B8A8D8
  *(scripted)*;
- text under 13 pt at any scale *(scripted)*;
- a header or number style that differs from the others of its rank on the
  same screen.

**Design rules:** §21.8's type row (faces, the outline rule, 13 pt, no opacity,
the secondary-text floor, a law title on a light school colour sits on a
plate). The owner kept §21.8's faces (D4 (b)): the benchmarks' one heavy face
everywhere is not the target.

**Clear pass:** the clock "2:18" in the middle column of
`proof-heist-hud.png`: heavy numerals with an ink outline all round, a drop and
a fill gradient, on a lit well.

**Clear fail:** the place labels and pills in the left column of
`docs/art/ui-quality/audit-home.png`: small Manrope without stroke over a busy
scene.

**Method:** scripted: outline width, faces, sizes, opacity. Judge:
full-resolution crops of headers and numbers only (one crop per text rank,
at most four), at 100% and 200% text. Owner: boards.

### 3. Painted or rendered icons

Things of value look like objects you could hold, not glyphs.

**Pass needs:**
1. Every currency, reward and chest icon has a 3D form with a top-left key
   light, a rim light, a specular highlight and a dark outline.
2. The outline is 2 pt at the size shown *(scripted)*.
3. Each icon reads as a dark shape at 32 pt *(scripted: the silhouette rule of
   §21.1)*.
4. Icons are finished with §21.8's volume: a three-stop gradient, a gloss and a
   soft drop shadow.
5. Every icon is in the one toon look (§21.3; D5 (b)): no physically based
   metal, gem or glass lighting, and characters rendered from their imported
   models.
6. A law icon's frame is its school's shape, never another (§21.8); a school
   icon carries its school's shape (§21.2).

**Fails on:**
- a flat or line glyph for a thing of value;
- an icon that loses its shape or turns to a blob at 48 pt;
- an outline missing, broken or thinner than 2 pt at the size shown;
- a hard ink drop where §21.8 asks for a soft drop;
- a photoreal or physically based finish;
- a law icon in the wrong frame.

**Design rules:** §21.8's icon row; §21.1's silhouette rule (a dark shape at
32 pt); §21.3's one toon look; §21.2's school shapes.

**Clear pass:** the "AI UI artist (256 px)" row of
`docs/art/ui-quality/ai-artist-icons.png`: Starlight, Essence and Renown
modelled, lit top-left, with a rim and a specular, and readable at the phone
size below. (The Pip badge in that row was lit physically, which §21.3 rules
out: it is not an anchor.)

**Clear fail:** the "Client today" row of the same image: flat gradient glyphs
with an outline and no form or light.

**Method:** scripted: outline, silhouette, sizes. Judge: icon sheets at 48 and
96 pt at native resolution and in grayscale; on screens, a crop of the
currency row and of any reward. Owner: board 2.

### 4. Press feedback

A press is felt: the control sinks and darkens, and comes back.

**Pass needs:**
1. On touch-down the control sinks 2–4 pt onto its lip or squashes slightly,
   and darkens.
2. Release returns within 150–250 ms, easing out, without overshoot (§21.8;
   D3 (b)) *(scripted)*.
3. A light haptic tap on buttons (§21.8) *(scripted: the haptic call)*.
4. A reduced form: it sinks and darkens, without squash (section 10.3 of
   `report.md`) *(scripted)*.

**Fails on:** no visible press state; travel under 2 pt or over 4 pt; a
release outside 150–250 ms or with overshoot; no haptic call; no reduced form.

**Design rules:** §21.8's motion and haptics rows; §20.8's reduced motion. No
sound this wave (D7 (a)): the quality is judged without it.

**Clear pass:** a frame strip in which the button drops onto its lip and
darkens on the touch-down frame and is back by 250 ms, with no frame larger
than the rest size.

**Clear fail:** the proof's press in `docs/art/ui-quality/proof-motion.png`,
which springs past its size and settles within 0.4 seconds: rich, but outside
§21.8.

**Method:** scripted: curve, travel, haptic, reduced form. Not judged: a still
cannot show a press. Owner: frame strips, full and reduced, on boards 1 and 4.

### 5. Reward juice

A reward is an event: it builds, lands and is counted.

**Pass needs:**
1. Every step of the sequence is present: anticipation (0.3–1 s), a burst, the
   reveal, icons flying in arcs to their counter, the counter rolling up and
   pulsing on each landing *(scripted: each step's named event fires)*.
2. Each movement is 150–250 ms, easing out, without overshoot (§21.8; D3 (b)).
3. Rarer rewards are stronger: more particles, a longer anticipation, a
   brighter burst.
4. A reduced form: no anticipation or burst; one coin lands in its counter and
   the counter shows its new value (§20.8) *(scripted)*.
5. No more than three flashes a second *(scripted)*.

**Fails on:** a missing step; a reward shown as a static tile; no reduced
form; more than three flashes a second; overshoot.

**Design rules:** §21.8's motion row ("rewards fly into their counter");
§20.8's comfort row (the one particle reduced motion keeps is a reward landing
in its counter; no flashing above three a second). No sound this wave (D7 (a)).

**Clear pass:** a frame strip that shows a pause before the reveal, a burst on
a sunburst, coins in arcs, and the counter's value stepping up with a pulse on
each landing; its reduced strip shows one coin and the final value.

**Clear fail:** the result screen in `docs/art/ui-quality/audit-result.png`,
left column: the reward is one flat tile with no anticipation, flight or
count.

**Method:** scripted: steps, timings, flashes, reduced form. Not judged. Owner:
frame strips and clips on board 4.

### 6. Hierarchy

One thing on the screen is obviously the thing to do, and the rest falls in
behind it.

**Pass needs:**
1. Exactly one primary action, 1.5–2× the next control by area
   *(scripted: from the shot's control rectangles)*, and the most saturated
   thing on the screen. The shot list names each screen's primary; a screen
   whose list names none (settings) passes this item when its title and group
   headers outrank its rows.
2. At most about five things at the second level.
3. It survives the grayscale squint: in the grayscale still at 960 px, the
   primary is the first thing the eye lands on and the important elements are
   still readable (§21.10).

**Fails on:**
- two or more controls competing for the primary role, by size, saturation
  or value;
- a field of equal-weight pills and badges with no single entry point;
- a primary that disappears in grayscale;
- secondary content (prose, technical lines) at the visual weight of the
  reward or the main action.

**Design rules:** §21.10's grayscale thumbnail test (value structure first,
colour second); §21.8's home and heist layouts, which place things and so
decide what can be primary.

**Clear pass:** a home screen whose Heist entry is the largest, warmest and
brightest thing, with every other control visibly a step down.

**Clear fail:** the left column of `audit-home.png`: about fifteen pills and
badges of the same size and no single primary action.

**Method:** scripted: area ratio and count from the control rectangles. Judge:
the grayscale still at 960 px, beside the colour still. Owner: boards.

### 7. Motion and idle life

The interface is alive between taps, and moves the same way everywhere.

**Pass needs:**
1. Every screen change goes through the kit's `Motion`, 150–250 ms, easing
   out, without overshoot (§21.8; D3 (b)) *(scripted)*.
2. Popups ease in over a dimmed scene.
3. At least three idle loops on home: shine sweeps, bobbing, a breathing call
   to action *(scripted: count)*.
4. Each has a reduced form: a screen change becomes a cross-fade; idle shine
   stops (section 10.3 of `report.md`) *(scripted)*.
5. No glint, sparkle or shine flashes more than three times a second, and
   screen shake never exceeds 4 pixels (§20.8, §21.8) *(scripted)*.

**Fails on:** a hard cut between screens; a movement outside 150–250 ms or
with overshoot; fewer than three idle loops on home; a motion without a
reduced form; a flash rate above three a second; shake above 4 pixels.

**Design rules:** §21.8's motion row; §20.8's comfort row; §21.1's "gentle
physical humour in every animation".

**Clear pass:** a home frame strip over two seconds in which a shine crosses
the primary button, badges bob and the call to action breathes, each in step
with the others; its reduced strip is still.

**Clear fail:** a home strip in which nothing moves until it is tapped, and a
screen change that cuts in one frame.

**Method:** scripted: routing, timings, counts, reduced forms, flashes, shake.
Not judged: static-screenshot judges overrate motion. Owner: frame strips and
clips on boards 3 and 4.

### 8. Colour roles and value

Colour means something, the same thing everywhere, and nothing depends on
colour alone.

**Pass needs:**
1. Fixed semantic hues: gold for main actions, red #E2536B for alarms and
   green #3FBF7F for success as fills, rings and marks (§21.8); the school
   colours of §21.2 for school things; one rarity ladder used for cards,
   chests and text alike.
2. Words meet 4.5:1 and the perceptual check in both modes, measured over the
   pixels at their worst point, or against their outline where they have one
   (§21.8) *(scripted)*.
3. Interactive things are at least two value steps off their ground
   (ΔL* ≥ 20, above) *(scripted)*.
4. Colours come only from the palette (`art/ui/palette.json`, generated from
   the tokens) *(scripted)*.
5. No information carried by colour alone: rarities and schools carry a shape
   as well (§20.8, §21.2), checked on a colour-blindness sheet for the three
   common forms *(scripted: the sheet is made; the judge reads it)*.

**Fails on:**
- a semantic hue used for another role (gold on a cancel, green on a danger);
- words in red #E2536B or green #3FBF7F on parchment, or red words on a dark
  surface that are not #FF9AAA bold (§21.8) *(scripted)*;
- an interactive control one value step or less off its ground;
- a rarity or school told apart by colour alone, or two that merge on the
  colour-blindness sheet;
- a hue that is not in the palette.

**Design rules:** §21.8's colours row (the surfaces, the action, alarm and
success colours and their word forms, high contrast); §21.2 (school colours
and shapes, the neutrals, the skies; the HUD is checked over day, dusk and
night); §20.8's seeing row; §21.10 (value structure first).

**Clear pass:** a screen where every gold thing is an action, every red thing
an alarm, and the rarity frames step through one ladder that also changes
shape; on the colour-blindness sheet every school still differs by shape.

**Clear fail:** a screen whose leather buttons sit on a violet card of nearly
the same lightness, so in grayscale the buttons vanish, and whose rarities
differ by hue only.

**Method:** scripted: contrast, value steps, palette, colour-blindness sheet.
Judge: whether the semantic hues and the rarity ladder read, on the still at
960 px and its colour-blindness sheet. Owner: boards.

### 9. Character presence

The game's characters are on its screens, alive, not only in the world.

**Pass needs:**
1. Home shows a live character node (real-time 3D in the toon look)
   *(scripted: the node exists and animates)*.
2. The character reads at its size: a recognisable dark shape at 32 pt
   (§21.1), framed or lit so it stands out from the scene.
3. Rewards and offers are framed with character art where the screen shows
   them.
4. Portraits are rendered from the imported models in the toon look (§21.3).

**Fails on:** a home with no character, or one too small to recognise; a
character drawn in a physically based material; a reward or offer with no
character where the screen frames one; a character that is a flat sticker
with no light.

**Design rules:** §21.3 (characters in the one toon look; portraits rendered
from the imported models); §21.1 (silhouette at 32 pt).

**Applies to:** home, heist (the crew portraits), result and character. On
settings it applies only if the screen shows a reward or an offer; otherwise
it is not applicable.

**Clear pass:** the character screen in `docs/art/ui-quality/audit-character.png`,
left column: a 3D character on a plinth, large, lit and framed.

**Clear fail:** the home screen in the left column of `audit-home.png`: the
only characters are figures a few points tall on the islands, with nothing
framed or alive in the interface.

**Method:** scripted: the live node on home. Judge: the still at 960 px plus a
full-resolution crop of the character. Owner: board 3.

### 10. Phone scale and thumb reach

Everything can be read and hit with one thumb on a phone.

**Pass needs** *(all scripted)*:
1. Every hit area at least 48 pt (§21.1, §21.8); primaries about 1.5× that.
2. Nothing smaller than 13 pt, at 100%, 150% and 200% text (§21.8).
3. A bottom navigation of 3–5 items; on home, five tabs with the Heist in the
   centre, inside the safe area and clear of the corners (§21.8).
4. The main action and every frequently used control in the lower two-thirds
   of the screen (§21.1). Where §21.8 places a control elsewhere (the heist's
   Get out at the bottom right), §21.8's placement wins.
5. Nothing interactive in a screen corner, and nothing important within
   44 pt of the notch or the home bar (§21.1).
6. Frames sized from their words, so nothing overflows or clips at 200% text
   in English and Brazilian Portuguese.

**Fails on:** any of the above.

**Design rules:** §21.1's screen row; §21.8's home layout; §20.8's seeing row
(text to 200%).

**Clear pass / clear fail:** measured, not seen: the kit's pieces tests and
the shot's control rectangles report a number against each limit.

**Method:** scripted only. Not judged; not on boards.

### 11. One component system

Every screen is built from the same few parts.

**Pass needs** *(all scripted)*:
1. At most about 4 button styles, 2–3 frames, 1 ribbon, 1 badge and 1 currency
   pill, as the kit contract defines them (`kit-spec.md`).
2. The same radius, stroke and drop everywhere.
3. A screen adds no chrome of its own: the chrome count does not rise
   (`tools/ui_bake/check_screens.py`).
4. The catalogue sheet covers every component in every state.

**Fails on:** a new skin or a hand-drawn panel in a screen file; a count above
the contract's limits; a component missing from the catalogue.

**Design rules:** none beyond the kit contract.

**Clear pass / clear fail:** measured, not seen.

**Method:** scripted only. AD's flow reviews at each phase end look for drift
the scripts miss (section 3.3 of `report.md`).

### 12. Minimal gameplay HUD

In a heist, the world is the screen.

**Pass needs** *(all scripted)*:
1. The persistent HUD covers at most 15% of the screen: the union of the
   persistent controls' rectangles over the screen's area, in portrait, at
   100% text.
2. Information that belongs to a thing in the world is shown on it where it
   can be.
3. The HUD keeps §21.8's heist layout.

**Fails on:** a persistent HUD over 15%; a layout that moves §21.8's pieces.

**Design rules:** §21.8's heist layout and ability uses.

**Clear pass / clear fail:** measured, not seen.

**Method:** scripted only (`tools/ui_gate/`, from the control rectangles).

### 13. Light behind UI

The interface sits in one light, and important moments are lit.

**Pass needs:**
1. Modals dim the scene behind them *(scripted: the scrim)*.
2. Rewards sit on a sunburst or glow.
3. Home sits on a lit scene with a vignette.
4. One light direction on every panel and icon: highlights top and top-left,
   shadows and lips below, matching the icons' top-left key light.

**Fails on:** a modal with no scrim; a reward on a plain fill; panels lit from
different directions, or a bevel lit from below; an icon lit from the right
beside panels lit from the left.

**Design rules:** §21.1 ("warm light on the islands and cool shadows
beneath"); §21.3 (no full-screen post-processing: glow and bloom are per
item).

**Clear pass:** the middle column of `proof-heist-hud.png`: every panel and
button lit from the top, lips below, one direction throughout.

**Clear fail:** the settings screen in `docs/art/ui-quality/audit-settings.png`,
left column: thin rows on a plain night backdrop, with no lit scene, no
vignette and barely a highlight on the panels.

**Method:** scripted: the scrim. Judge: the still at 960 px plus crops of two
panels and one icon. Owner: boards.

### 14. One art-direction idea

Every part of the interface follows from one idea.

**Pass needs:**
1. The whole interface follows §21.1's direction, as the approved style board
   states it: picture-book dioramas floating in a violet sky; chunky,
   soft-edged, toy-like shapes; warm light, cool shadows; inked outlines
   (#1A0C14) in one toon look.
2. Every component on the screen expresses it: frames, pills, buttons, icons
   and type look like they come from the same toy box as the islands.
3. Nothing reads as borrowed from another style: a web form, a flat material
   design, a photoreal object, a sci-fi glow.

**Fails on:** a screen where some components are toy-like and others are web
or app chrome; a piece in a different idiom (a thin line icon, a glass card
with blur, a photographic texture); a screen that would not be recognised as
this game with its world hidden.

**Design rules:** §21.1's style row; §21.3's one toon look and hand-painted
gradients; §21.11 (made for this game: no outside art).

**Clear pass:** a screen whose every frame, pill, icon and number could be
cut out and placed on an island without looking foreign.

**Clear fail:** the same settings screen: an app's settings page in game
colours.

**Method:** not scripted. Judge: the whole still at 960 px. Owner: every
board.

## Versions

Every edit to this page is a new version, logged here, and every judged
quality is re-measured on the held-out third before its verdicts block again
(section 3.5 of `report.md`, step 7). A verdict records the version it was
made under.

| Version | Date | What changed |
|---|---|---|
| 1 | 2026-10-30 | First version: the 14 qualities of section 4 of `report.md` as pass and fail criteria, with §21.8's, §21.1's, §21.3's, §20.8's and §21.10's rules folded in; anchors provisional until O3 |
