# The golden set's held-out labels

The blind labelling form for one third of the golden set. You are labelling
images of a mobile game's interface against the rubric. Read
docs/art/ui-quality/gate/rubric.md first; it is the only guide you need. Do not
open items.json, labels.md, README.md or anything else in this folder except
the images named below. They hold another labeller's guesses, and these labels
are meant to test them.

There is one row for each item and each quality its class is judged on (the
rubric's "The method at a glance"). The images are in images/, named by item
id: the row `board-glass | 1. Layered materials` is about images/board-glass.png.

How to fill it in:

- **Label:** `pass`, `fail` or `n/a`. Use `n/a` only when the quality has
  nothing to judge in that image, for example quality 9 on a crop with no
  character. Leave no row blank.
- **Critique:** one line saying what you see that decides the label, in the
  rubric's words where you can. For example: "gold plate flat, no bevel or
  gloss; reads as a fill".
- Judge each image as it is, at 1x first and then zoomed in. Judge each row on
  its own quality; a fail on one quality does not make the others fail.
- Do not change the Item or Quality columns. `python3 tools/ui_gate/golden.py
  check` fails if the rows no longer match the held-out items.

| Item | Quality | Label | Critique |
|---|---|---|---|
| today-home | 1. Layered materials | fail | Currency and status pills are uniform dark rounded rectangles with a hairline border, no gloss band or lip; reads as a web overlay |
| today-home | 2. Display type | fail | Keeper 14 and the nav labels sit unstroked over the scene and sky; big currency numbers have no outline, drop or gradient |
| today-home | 3. Painted or rendered icons | fail | Currency icons (sparkle, orb, drop) are small flat glyphs with no form, key light or specular |
| today-home | 6. Hierarchy | fail | A field of equal-weight pills and place badges with no single entry point; the small SEE button is the only gold and nothing leads |
| today-home | 8. Colour roles and value | fail | Dark pills and nav controls sit barely a value step off the dark violet sky; gold spent on non-action text (FULL) and the level ring |
| today-home | 9. Character presence | fail | No character in the interface; only figures a few points tall on the islands, nothing framed or alive |
| today-home | 13. Light behind UI | fail | Pills and banner are flat with barely a highlight; no consistent top-lit panels or lips beyond the SEE button |
| today-home | 14. One art-direction idea | fail | Toy islands under app-chrome pills and a web-style notification banner; the HUD would not read as this game with the world hidden |
| today-character | 1. Layered materials | fail | Info cards and segmented bar are single fills with a thin border; LEVEL UP has gloss and lip but no dark hue-matched rim |
| today-character | 2. Display type | fail | LEVEL UP and the big numbers (200, 160) have no ink outline, drop or gradient |
| today-character | 3. Painted or rendered icons | fail | Essence drop and heart are flat glyphs; ability and trait icons are small flat badges with no rim light or specular |
| today-character | 6. Hierarchy | pass | LEVEL UP is clearly the largest and most saturated control and stays brightest in grayscale; the rest steps down |
| today-character | 8. Colour roles and value | fail | Main action filled green instead of gold; green word RESISTS on parchment |
| today-character | 9. Character presence | pass | Large 3D Skyskipper on a plinth with a sunburst and nameplate, lit and framed |
| today-character | 13. Light behind UI | fail | Sunburst behind the character, but the dark cards and tab bar carry no top highlight; only the button is lit |
| today-character | 14. One art-direction idea | fail | Toy character and chunky button beside app-like dark cards and a flat segmented control |
| v3-heist | 1. Layered materials | fail | HUD panels are single dark fills with a gold border and small drop; no gloss band, bevel or inner well; clock is a flat cream pill |
| v3-heist | 2. Display type | fail | Laws here and crew names sit unstroked over the scene; clock numerals have no outline or gradient |
| v3-heist | 3. Painted or rendered icons | fail | Law icons (Sleepwalk, Glass) are small flat glyphs with no form or school frame |
| v3-heist | 6. Hierarchy | fail | Cast and Get out compete at equal size, and the three top panels carry similar weight; no single primary |
| v3-heist | 8. Colour roles and value | pass | Red kept for the exit/alarm role, green for crew bars, gold as frame material; controls stand well off the scene |
| v3-heist | 9. Character presence | pass | Crew and Archivist portraits rendered from the 3D models in the toon look, framed in rings and readable |
| v3-heist | 13. Light behind UI | fail | Panels have a lip below but no top highlight; barely any light on the HUD chrome |
| v3-heist | 14. One art-direction idea | fail | Toy island under flat app-style rectangles and a hint bar; HUD reads as overlay chrome |
| v3-result | 1. Layered materials | fail | The moment card is a uniform dark rounded rectangle with a hairline border; RAID AGAIN has no gloss band over its top |
| v3-result | 2. Display type | fail | Big reward numbers are plain dark text with no outline, drop or gradient; subtitle lines sit unstroked over the sunburst |
| v3-result | 3. Painted or rendered icons | fail | Reward icons are gradient glyphs with an outline and little form or rim light; law icons are flat line glyphs |
| v3-result | 6. Hierarchy | fail | Bright cream reward and law tiles outrank RAID AGAIN in grayscale; prose card sits at the weight of the reward |
| v3-result | 8. Colour roles and value | fail | Green +2 words on parchment; gold also spent on non-action frames and pills |
| v3-result | 9. Character presence | fail | Reward not framed with character art; only a tiny Archivist avatar |
| v3-result | 13. Light behind UI | fail | Sunburst only behind the title; reward tiles sit on a plain dark fill and RAID AGAIN is lit from the centre, not the top |
| v3-result | 14. One art-direction idea | fail | Toy reward tiles beside a web-style dark card with a hairline divider |
| t14-heist-hc | 1. Layered materials | pass | Panels have gold bevelled frames with rivets, inner well and lip; Cast and Get out carry gloss, dark rim and thick lip |
| t14-heist-hc | 2. Display type | pass | Words and numbers over art carry an ink outline all round with a heavy consistent treatment |
| t14-heist-hc | 3. Painted or rendered icons | fail | Bloom law icon is a flat green glyph with no form and no school-shaped frame |
| t14-heist-hc | 6. Hierarchy | fail | Cast and Get out compete for primary at near-equal size; no single control clearly leads |
| t14-heist-hc | 8. Colour roles and value | pass | Red for the exit, green bars, gold as frame material; controls stand two value steps off the scene |
| t14-heist-hc | 9. Character presence | pass | Crew portraits rendered in the toon look, framed in gold rings; most read at size |
| t14-heist-hc | 13. Light behind UI | pass | Every panel and button lit from the top with lips below, one direction throughout |
| t14-heist-hc | 14. One art-direction idea | pass | Chunky riveted frames, inked type and toy buttons all from the same toy box as the island |
| t14-hud-bottom | 1. Layered materials | pass | Cast and Get out have body gradient, gloss band, dark rim and thick lip; portrait rings bevelled |
| t14-hud-bottom | 2. Display type | pass | Crew names and button labels heavy with an ink outline all round over the scene |
| t14-hud-bottom | 8. Colour roles and value | pass | Red exit, violet cast, green bars; controls well off the scene in value |
| t14-hud-bottom | 13. Light behind UI | pass | Gloss on top and lips below on every button, one light direction |
| today-hud-bottom | 1. Layered materials | fail | Cast is a radial fill with thin rim and no gloss band; Get out gradient turns into visible banding |
| today-hud-bottom | 2. Display type | fail | Crew-name outline is thin, under the rule, and Bramble and Hollow run together over the scene |
| today-hud-bottom | 8. Colour roles and value | pass | Red exit, green bars, controls clearly off the violet scene |
| today-hud-bottom | 13. Light behind UI | pass | Buttons lighter at top with lips below; no conflicting light direction |
| board-glass | 1. Layered materials | fail | Glass pills are uniform rounded rectangles with a hairline gold border and blur; reads as a web overlay |
| board-glass | 2. Display type | fail | Pill numbers use a drop shadow standing in for the outline; words over sky unstroked |
| board-glass | 8. Colour roles and value | pass | Alarm in light red, success in light green on dark glass; roles read correctly over all three skies |
| board-glass | 13. Light behind UI | fail | No visible catch-light or top sheen on the pills; barely a highlight |
| board-parchment | 1. Layered materials | fail | Parchment grain and drop present, but the sheet is a single gradient with a thin outline: no bevelled frame, inner well or gloss |
| board-parchment | 2. Display type | pass | Words sit on a plain parchment surface in brown ink, Marcellus title and Manrope labels, nothing over a scene |
| board-parchment | 8. Colour roles and value | fail | Red and green words set directly on parchment |
| board-parchment | 13. Light behind UI | pass | Sheet lit at the top with its brown drop below, one direction |
| board-light | 1. Layered materials | fail | Stage panel is a single gradient with a thin rim and no lip; spheres show toon shading but no rim or lip structure |
| board-light | 2. Display type | pass | Text sits on a plain dark ground, not over art; headers consistent |
| board-light | 8. Colour roles and value | pass | Gold, enamel and leather samples used as materials only; no semantic hue misused |
| board-light | 13. Light behind UI | pass | All three spheres lit from the top left with shade below-right, one light direction |
| ai-starlight | 1. Layered materials | pass | Gold reads as a made material: lit body, gloss, shade and dark outline |
| ai-starlight | 3. Painted or rendered icons | pass | Modelled 3D star with top-left key light, rim light, specular and dark outline; reads as a shape |
| ai-starlight | 8. Colour roles and value | pass | Gold currency stands several value steps off the violet ground |
| ai-starlight | 13. Light behind UI | pass | Key light top left, shadow bottom right, consistent with panels |
| today-icon-starlight | 1. Layered materials | fail | Flat banded gradient fill inside an outline; reads as a fill, not a material |
| today-icon-starlight | 3. Painted or rendered icons | fail | Flat gradient glyph with an outline and one highlight stroke; no 3D form, rim light or specular |
| today-icon-starlight | 8. Colour roles and value | pass | Gold star stands well off the violet ground |
| today-icon-starlight | 13. Light behind UI | fail | Highlight sits on the upper-right edge, not the top-left key |
| plant-gold-flat | 1. Layered materials | fail | Gold is a flat posterised fill with a flat cream block for gloss; no body gradient or brushing; reads as a fill |
| plant-gold-flat | 2. Display type | pass | Labels sit on the button face in heavy dark ink, not over art; consistent across buttons |
| plant-gold-flat | 8. Colour roles and value | pass | Gold used only for main actions; buttons well off the violet ground |
| plant-gold-flat | 13. Light behind UI | pass | Light band on top and lip below on every button, one direction |
| plant-heist-one-step | 1. Layered materials | fail | Bevels, gloss and lips are washed into mud by the veil at phone size |
| plant-heist-one-step | 2. Display type | fail | Outlines lose contrast and merge into the art behind them |
| plant-heist-one-step | 3. Painted or rendered icons | fail | Bloom law icon is a flat glyph and every icon turns muddy, losing form |
| plant-heist-one-step | 6. Hierarchy | fail | Fails the grayscale squint: everything sits in one narrow value band, nothing leads |
| plant-heist-one-step | 8. Colour roles and value | fail | Controls sit about one value step off their ground; hues desaturated together |
| plant-heist-one-step | 9. Character presence | fail | Crew portraits washed out and barely recognisable at size |
| plant-heist-one-step | 13. Light behind UI | fail | The veil flattens the lit scene; panel highlights barely visible |
| plant-heist-one-step | 14. One art-direction idea | pass | Same toy-box frames, buttons and inked type throughout; one idiom, only the value is crushed |
| kf-home-hc | 1. Layered materials | fail | HC cards are opaque single fills with a white outline, no gloss, bevel or lip; only Collect is layered |
| kf-home-hc | 2. Display type | fail | Big currency numbers are plain white with no outline, drop or gradient |
| kf-home-hc | 3. Painted or rendered icons | pass | Nav, shop, season and currency icons are rendered with form, gloss and outline in one toon look |
| kf-home-hc | 6. Hierarchy | fail | Collect 3.4k and the centre Heist both gold and large, competing for primary |
| kf-home-hc | 8. Colour roles and value | pass | Gold on actions, red on alerts, green on progress; cards stand well off the sky |
| kf-home-hc | 9. Character presence | pass | Rendered character portrait framed top left, readable at size |
| kf-home-hc | 13. Light behind UI | fail | Lit scene, but the HC cards carry no top highlight; panels barely lit |
| kf-home-hc | 14. One art-direction idea | fail | Black rounded cards with white outlines read as app chrome beside toy islands and rendered icons |
| kf-result-text200 | 1. Layered materials | fail | Essence and Renown rows are dark fills with a hairline gold border and no lip; only the Starlight plate and RAID AGAIN are layered |
| kf-result-text200 | 2. Display type | fail | 1,288 is outlined but +46 and +12 of the same rank are not; subtitle prose unstroked over the sunburst |
| kf-result-text200 | 3. Painted or rendered icons | fail | Reward icons are small gradient glyphs with outline and a dot highlight; little 3D form or rim light |
| kf-result-text200 | 6. Hierarchy | fail | At 200% the prose subtitle sits at the weight of the reward; cream Starlight plate rivals RAID AGAIN in grayscale |
| kf-result-text200 | 8. Colour roles and value | pass | Gold on the main action and starlight; no misused alarm or success hues |
| kf-result-text200 | 9. Character presence | fail | Result shows no character framing the reward |
| kf-result-text200 | 13. Light behind UI | pass | Rewards sit on a sunburst; RAID AGAIN gloss on top with lip below |
| kf-result-text200 | 14. One art-direction idea | fail | Toy plate and button beside web-like dark hairline rows |
| kf-character-hc | 1. Layered materials | fail | Info cards are flat cream fills with a hairline outline and no lip; HC pills plain |
| kf-character-hc | 2. Display type | pass | Words sit on plain surfaces; Level up and its price heavy with an ink outline; headers consistent |
| kf-character-hc | 3. Painted or rendered icons | fail | Essence drop and trait icons are small gradient glyphs with little form or rim light |
| kf-character-hc | 6. Hierarchy | pass | Level up is the widest gold control by about three times; the rest steps down |
| kf-character-hc | 8. Colour roles and value | pass | Gold on actions, green for progress, cards and controls well off their grounds |
| kf-character-hc | 9. Character presence | pass | Large 3D Skyskipper rendered in the toon look, framed by the plinth and nameplate |
| kf-character-hc | 13. Light behind UI | fail | Plain dark backdrop with no glow; cards carry no top highlight |
| kf-character-hc | 14. One art-direction idea | fail | Black HC pills with white outlines and flat cream cards read as app chrome beside the toy character |
| kf-settings | 1. Layered materials | pass | Violet card with bevelled frame, inner well and gloss; parchment rows with grain and lip; gold buttons with gloss, rim and lip |
| kf-settings | 2. Display type | fail | Section headers Access and Seeing and comfort sit over the gradient backdrop with only a drop shadow, no outline |
| kf-settings | 3. Painted or rendered icons | fail | School icons are line glyphs on identical glossy circles; no school-shaped frames |
| kf-settings | 6. Hierarchy | fail | Thin group headers are outranked by the bright parchment rows they head |
| kf-settings | 8. Colour roles and value | pass | Gold on the action buttons and tab; schools differ by glyph as well as colour; toggles well off parchment |
| kf-settings | 13. Light behind UI | pass | Panels and buttons lit from the top with gloss bands and lips below, one direction |
| kf-settings | 14. One art-direction idea | pass | Every card, tab and button is chunky, inked and toy-like; no web chrome |
| plant-kf-home-unstroked | 1. Layered materials | fail | Translucent dark cards with a hairline gold rim and no lip; reads as a web overlay |
| plant-kf-home-unstroked | 2. Display type | fail | Thin unstroked place labels (Skyfield, The Heart, Verdant, Emberreach) sit directly over the scene |
| plant-kf-home-unstroked | 3. Painted or rendered icons | pass | Nav, shop, season and currency icons rendered with form, gloss and outline |
| plant-kf-home-unstroked | 6. Hierarchy | fail | Collect 3.4k and the centre Heist both gold and large, competing for primary |
| plant-kf-home-unstroked | 8. Colour roles and value | pass | Gold on actions, red on alerts, green on progress; controls off their ground |
| plant-kf-home-unstroked | 9. Character presence | pass | Rendered character portrait framed top left, readable at size |
| plant-kf-home-unstroked | 13. Light behind UI | fail | Lit scene, but cards carry no top highlight |
| plant-kf-home-unstroked | 14. One art-direction idea | fail | Thin web-style labels and translucent cards beside toy islands |
| plant-kf-heist-icon-flat | 1. Layered materials | fail | Two-tone posterised fills with no gradient, gloss or grain; reads as a flat fill |
| plant-kf-heist-icon-flat | 3. Painted or rendered icons | fail | Loot bag is a flat two-tone glyph with outline; no 3D form, rim light or specular |
| plant-kf-heist-icon-flat | 8. Colour roles and value | pass | Gold disc stands well off the dark ground; count badge distinct |
| plant-kf-heist-icon-flat | 13. Light behind UI | pass | Flat, but the lighter top and shaded foot keep one top light |
