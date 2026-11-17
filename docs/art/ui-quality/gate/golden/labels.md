# The golden set's labels

The labelling form for the golden set (README.md beside this file). There is
one row for each item and each quality its class is judged on (gate/rubric.md,
"The method at a glance"). The images are in images/, named by item id.

How to fill it in:

- **Label:** `pass`, `fail` or `n/a`. Use `n/a` only when the quality has
  nothing to judge in that image, for example quality 9 on a crop with no
  character. A blank row means it has not been labelled yet.
- **Critique:** one line saying what you see that decides the label, in the
  rubric's words where you can. For example: "gold plate flat, no bevel or
  gloss; reads as a fill".
- Judge the image as it is, at 1x first and then zoomed in. Do not look at
  items.json's `expected` or `why` before labelling. It is the builder's guess,
  and the labels are meant to test that guess.
- Do not change the Item or Quality columns. `python3 tools/ui_gate/golden.py
  check` fails if the rows no longer match items.json.

Who labels: at O3, AD labels every row here. A fresh subagent, given only
gate/rubric.md and the held-out images, labels the held-out third (the items
with `third` 3 in items.json) blind, in labels-blind.md. The two sets of labels
are then compared row by row. Where they disagree on a held-out row, the label
here becomes `fail`, and the critique says what each labeller saw.
P0-AD-calibrate uses the agreement on the held-out third to calibrate the
judge.

| Item | Quality | Label | Critique |
|---|---|---|---|
| today-home | 1. Layered materials | fail | pills, badges and the raid banner are flat dark fills with a thin gold hairline; no gloss band, rim or lip |
| today-home | 2. Display type | fail | place labels and currency numbers in small Manrope without an ink outline over the busy sky and islands |
| today-home | 3. Painted or rendered icons | fail | currency icons are small flat gradient glyphs; only the Islands tab art has some form |
| today-home | 6. Hierarchy | fail | about fifteen equal-weight pills and badges; the gold SEE on a notice outranks the Heist tab; no single primary |
| today-home | 8. Colour roles and value | fail | gold spent on a notice button and on the level ring rather than the main action; the pills sit at one value on the sky |
| today-home | 9. Character presence | fail | no character in the interface; the only figures are a few points tall on the islands |
| today-home | 13. Light behind UI | fail | the scene is lit, but the panels carry no top highlight or lip, so the UI does not sit in the scene's light |
| today-home | 14. One art-direction idea | fail | app-chrome pills and banner over the diorama; the chrome would not read as this game with the world hidden |
| today-heist | 1. Layered materials | fail | clock is a cream pill with a faint gradient; the other panels are single fills with a gold border and a short drop, no gloss band or well |
| today-heist | 2. Display type | fail | Laws here is gold body type with no outline over the sky; the clock 2:18 has no outline, drop or fill gradient |
| today-heist | 3. Painted or rendered icons | fail | law icon and the ability pips are flat glyphs; the crew portraits are the only modelled things |
| today-heist | 6. Hierarchy | fail | Get out is the most saturated control and competes with Cast, which is a dark plate the same size |
| today-heist | 8. Colour roles and value | fail | gold goes on a label and on information panels' rims, not on the main action; Cast carries no action colour |
| today-heist | 9. Character presence | pass | five rendered crew portraits, framed and lit, readable as shapes at their size, plus the caster badge |
| today-heist | 13. Light behind UI | fail | panels have barely a highlight and no consistent top light; they read pasted over the lit island |
| today-heist | 14. One art-direction idea | fail | the island is toy-like but the HUD panels are dark web cards with a hairline border |
| today-result | 1. Layered materials | fail | the moment card is a flat violet panel with a hairline border; only Raid again and the loot tile have a gradient and lip |
| today-result | 2. Display type | fail | +508 has no outline, drop or gradient; Clean is a thin title without outline over the sunburst |
| today-result | 3. Painted or rendered icons | fail | the loot reward is a flat sparkle glyph |
| today-result | 6. Hierarchy | pass | Raid again is the largest, warmest control and outranks the rest; the technical line is small and set back |
| today-result | 8. Colour roles and value | fail | gold spent on the multiplier pill, the header word and the loot tile's rim as well as the action |
| today-result | 9. Character presence | fail | the reward is not framed with character art; three tiny portraits sit in the moment card only |
| today-result | 13. Light behind UI | fail | a sunburst behind the title, but the reward sits on a plain cream tile on a flat backdrop, with no glow |
| today-result | 14. One art-direction idea | fail | a web layout of cards and text lines on a dark page; nothing looks cut from the islands' toy box |
| today-character | 1. Layered materials | fail | Disagreement, so fail: AD said pass (Level up has a lit body, gloss band, rim and lip; the parchment and ability cards have a frame and a set-in well; the small pills are flatter); the blind labeller said fail (Info cards and segmented bar are single fills with a thin border; LEVEL UP has gloss and lip but no dark hue-matched rim) |
| today-character | 2. Display type | fail | LEVEL UP leans on a drop shadow, not an ink outline, and its subline is thin unstroked type over the green gradient |
| today-character | 3. Painted or rendered icons | fail | ability, role and stat icons are small flat glyphs; the essence drop on the price is a flat glyph |
| today-character | 6. Hierarchy | pass | Level up is the largest and brightest control; tabs and cards sit clearly a step below |
| today-character | 8. Colour roles and value | fail | the main action is green, the success hue, and green and brown words sit on parchment |
| today-character | 9. Character presence | pass | a large lit 3D character on a plinth, framed by its name plate and the arrows |
| today-character | 13. Light behind UI | fail | Disagreement, so fail: AD said pass (the character is lit on a glowing plinth with rays, and the panels' highlights sit on top with lips below); the blind labeller said fail (Sunburst behind the character, but the dark cards and tab bar carry no top highlight; only the button is lit) |
| today-character | 14. One art-direction idea | fail | Disagreement, so fail: AD said pass (mostly one toy-box idiom: plinth, hex badge, chunky button and inked cards; the small status pills are its weakest part); the blind labeller said fail (Toy character and chunky button beside app-like dark cards and a flat segmented control) |
| today-settings | 1. Layered materials | fail | the row panels are uniform dark rounded rectangles with a hairline border; only the gold tab and the language button have gloss |
| today-settings | 2. Display type | fail | the Settings title is thin, unstroked type over the starfield; section headers are small gold words without outline |
| today-settings | 3. Painted or rendered icons | fail | the row and tab icons are small flat glyphs in sockets, no form or light |
| today-settings | 6. Hierarchy | fail | no primary, and the title does not outrank the gold tab and the gold language button, which are the loudest things |
| today-settings | 8. Colour roles and value | fail | gold marks a selected tab and a language picker, not main actions; minus and plus buttons sit near the card's value |
| today-settings | 13. Light behind UI | fail | thin rows on a plain night backdrop, no lit scene or vignette, barely a highlight on the panels |
| today-settings | 14. One art-direction idea | fail | an app's settings page in game colours |
| v3-home | 1. Layered materials | fail | currency and status pills are flat dark fills with a hairline border; the nav bar is a flat slab; only COLLECT has a gold gradient |
| v3-home | 2. Display type | fail | Wren and the currency numbers are unstroked body type over the sky and dark pills; no heavy display treatment for numbers |
| v3-home | 3. Painted or rendered icons | fail | nav icons are painted and outlined, but the currency icons in the top row are small flat glyphs in sockets |
| v3-home | 6. Hierarchy | fail | the selected Islands tab is the largest element and COLLECT the warmest; the Heist tab is a small equal tab; no single primary |
| v3-home | 8. Colour roles and value | pass | gold sits on COLLECT, the action, and the level ring; pills and tabs are well off their grounds; badges carry numbers or shapes |
| v3-home | 9. Character presence | fail | no live character on home; the crew tab icon is the only figure in the interface |
| v3-home | 13. Light behind UI | fail | a glowing island scene with a vignette, but the pills have no top highlight and the UI is not lit by it |
| v3-home | 14. One art-direction idea | fail | toy-like nav icons and islands beside flat app pills and a phone status bar; two idioms on one screen |
| v3-heist | 1. Layered materials | fail | the clock is a cream pill with a faint gradient; the law, alarm and loot panels are single dark fills with a gold border, no gloss or well |
| v3-heist | 2. Display type | fail | Laws here is gold body type without outline over the sky; the clock numerals have no outline or drop |
| v3-heist | 3. Painted or rendered icons | fail | the law icons are flat line glyphs; the ability pips are flat |
| v3-heist | 6. Hierarchy | fail | Get out is the most saturated control and competes with Cast; the crew row and law plates sit at the same weight |
| v3-heist | 8. Colour roles and value | fail | Disagreement, so fail: AD said fail (gold is on a label, panel rims and the VAULT sign; the main action Cast is a dark plate); the blind labeller said pass (Red kept for the exit/alarm role, green for crew bars, gold as frame material; controls stand well off the scene) |
| v3-heist | 9. Character presence | pass | five rendered crew portraits in the toon look, framed and lit, plus the caster badge; each reads at its size |
| v3-heist | 13. Light behind UI | fail | the island is lit, but the HUD panels carry little top light and no lip, and do not sit in it |
| v3-heist | 14. One art-direction idea | fail | dark web cards and a phone status bar over a toy diorama |
| v3-result | 1. Layered materials | fail | the moment card is a dark panel with a hairline border; reward tiles are cream fills with a coloured rim and no gloss |
| v3-result | 2. Display type | fail | Loud is heavy and inked, but +2,310, +805 and +15 have no outline, hard drop or gradient fill |
| v3-result | 3. Painted or rendered icons | fail | the reward icons are flat gradient glyphs; the law icons are line glyphs |
| v3-result | 6. Hierarchy | fail | Raid again leads, but three rewards, three law cards, the moment card and the tip prose make far more than five second-level things |
| v3-result | 8. Colour roles and value | fail | green +2 words on the cream parchment cards; rewards told apart by rim hue alone |
| v3-result | 9. Character presence | fail | rewards are not framed with character art; the Archivist is a small avatar beside the tip |
| v3-result | 13. Light behind UI | fail | a sunburst behind the title, but the rewards sit on plain cream tiles with no glow |
| v3-result | 14. One art-direction idea | fail | a card-based web report with flat glyphs; the title is the only piece in the game's idiom |
| v3-character | 1. Layered materials | pass | UPGRADE has a lit body, gloss, rim and lip; the parchment card has a gold frame and set-in rows; the ability well reads as set in |
| v3-character | 2. Display type | fail | UPGRADE is heavy and inked, but its subline and the XP count are thin unstroked words over gradients |
| v3-character | 3. Painted or rendered icons | pass | the role icons are modelled and outlined with a top light; the ability icon sits on a lit gold tile |
| v3-character | 6. Hierarchy | pass | UPGRADE is the largest control at the bottom, and the cards sit clearly below it |
| v3-character | 8. Colour roles and value | fail | the main action is green, the success hue, and green and violet label words sit on parchment |
| v3-character | 9. Character presence | pass | a large lit 3D Pip on a plinth, framed by the name plate and arrows |
| v3-character | 13. Light behind UI | pass | Pip stands lit on a glowing plinth with rays, and the panels are lit from the top with lips below |
| v3-character | 14. One art-direction idea | pass | one toy-box idiom across the plinth, hex badge, chunky button and inked parchment card; the phone bar is outside the UI |
| v3-settings | 1. Layered materials | fail | the main panels are dark rounded rectangles with a hairline border; only the gold tab and the segment buttons have gloss and lip |
| v3-settings | 2. Display type | fail | the Settings and Reminders titles are thin unstroked type on the backdrop; 38 has no outline or drop |
| v3-settings | 3. Painted or rendered icons | fail | row and tab icons are small and their form is lost at 1x; the bar chart is flat |
| v3-settings | 6. Hierarchy | fail | the gold ring, the gold tab and two gold segment buttons outrank the title; no clear order |
| v3-settings | 8. Colour roles and value | fail | gold marks selection and a chart bar, not main actions; the coloured quiet-hours bar carries meaning by hue alone |
| v3-settings | 13. Light behind UI | fail | a plain dark backdrop with no lit scene or vignette; panels barely lit |
| v3-settings | 14. One art-direction idea | fail | a wellbeing dashboard from an app, in game colours |
| t14-heist | 1. Layered materials | pass | gold bevelled frames with inner wells, studs and lips on clock, alarm and loot panels; Cast and Get out sit on thick lips with a gloss band |
| t14-heist | 2. Display type | pass | clock 2:18 heavy with ink outline, drop and fill; Laws here, crew names and button words outlined over the scene |
| t14-heist | 3. Painted or rendered icons | pass | loot seal and Cast star modelled and lit top-left with an outline; no value glyph is flat |
| t14-heist | 6. Hierarchy | fail | Cast and Get out are the same size and stacked, and in grayscale the red Get out pulls the eye first; no single primary |
| t14-heist | 8. Colour roles and value | pass | gold frames, red for the exit and alarm, green crew bars; buttons and pills two or more value steps off the scene |
| t14-heist | 9. Character presence | fail | crew portraits framed in gold rings, but Hollow and Bramble turn to purple and grey smudges at size; no dark shape at 32 pt |
| t14-heist | 13. Light behind UI | pass | one key from the top: highlights on top edges, lips and drops below on every panel and button; lit world behind |
| t14-heist | 14. One art-direction idea | pass | every panel, ring and button reads as gilded toy chrome from the island world; nothing web-like |
| t14-heist-hc | 1. Layered materials | pass | opaque high-contrast cards keep gold bevel, well and lip; §21.8 high contrast drops glass and grain as it should |
| t14-heist-hc | 2. Display type | pass | numbers and labels heavy with full ink outlines; hint on a dark plate |
| t14-heist-hc | 3. Painted or rendered icons | fail | Disagreement, so fail: AD said pass (loot seal and Cast star keep form, light and outline); the blind labeller said fail (Bloom law icon is a flat green glyph with no form and no school-shaped frame) |
| t14-heist-hc | 6. Hierarchy | fail | same as normal: Cast and Get out equal and stacked, Get out the most saturated control |
| t14-heist-hc | 8. Colour roles and value | pass | strong value separation everywhere; semantic hues held |
| t14-heist-hc | 9. Character presence | fail | Disagreement, so fail: AD said fail (Hollow and Bramble portraits still muddy at size; crew does not read as shapes); the blind labeller said pass (Crew portraits rendered in the toon look, framed in gold rings; most read at size) |
| t14-heist-hc | 13. Light behind UI | pass | top light and lips below kept on every panel |
| t14-heist-hc | 14. One art-direction idea | pass | same toy-box chrome as normal, made plain without changing idiom |
| t14-hud-top | 1. Layered materials | pass | gold bevelled frames with corner studs, inner violet wells, lips and drops; panels read as made things |
| t14-hud-top | 2. Display type | pass | 2:18 and the loot numbers heavy with ink outline and hard drop; one heavy treatment across the panels |
| t14-hud-top | 8. Colour roles and value | pass | gold on frames, cream numbers clearly off the dark wells; loot bar track and marker read |
| t14-hud-top | 13. Light behind UI | pass | highlights on top bevels, lips and drops below; one direction on every panel |
| t14-hud-bottom | 1. Layered materials | pass | Cast and Get out have gradient body, gloss, dark rim and thick lip; crew rings gilded; only the hint plate is plain |
| t14-hud-bottom | 2. Display type | pass | crew names and button words outlined in ink over the scene |
| t14-hud-bottom | 8. Colour roles and value | pass | buttons stand well off the world; red for exit, green crew bars; ring frames gold |
| t14-hud-bottom | 13. Light behind UI | pass | buttons and rings lit from the top with lips below, matching the key |
| today-hud-top | 1. Layered materials | fail | the clock is a flat cream pill; the law, alarm and loot panels are single fills with a gold border and a drop, no gloss band or well |
| today-hud-top | 2. Display type | fail | Laws here is gold body type without outline over the sky; 2:18 has no outline, drop or fill gradient |
| today-hud-top | 8. Colour roles and value | fail | gold is spent on a label and on every information panel's rim, not on actions |
| today-hud-top | 13. Light behind UI | fail | barely a highlight: no top light or gloss on the panels, only a soft drop below |
| today-hud-bottom | 1. Layered materials | fail | Cast and Get out have a rim and a lip but no gloss band; the hint bar is a flat pill with a hairline border |
| today-hud-bottom | 2. Display type | fail | Disagreement, so fail: AD said pass (crew names, Cast and Get out are heavy words with an ink outline over the world); the blind labeller said fail (Crew-name outline is thin, under the rule, and Bramble and Hollow run together over the scene) |
| today-hud-bottom | 8. Colour roles and value | fail | Disagreement, so fail: AD said fail (the main action Cast is a dark plate, while gold marks the selected crew name; Get out takes the alarm red); the blind labeller said pass (Red exit, green bars, controls clearly off the violet scene) |
| today-hud-bottom | 13. Light behind UI | fail | Disagreement, so fail: AD said fail (buttons and frames carry little top light; the lips are there but the faces read flat); the blind labeller said pass (Buttons lighter at top with lips below; no conflicting light direction) |
| board-enamel | 1. Layered materials | pass | violet card with gloss band over the top, hot spot top-left, dark rim, foot and ink edge; chosen card gold rim and foot, no glow |
| board-enamel | 2. Display type | pass | Marcellus title and Manrope labels on a calm card, clean and legible; nothing over art unstroked |
| board-enamel | 8. Colour roles and value | pass | gold only on the chosen state; charge pips differ by fill and ring, not colour alone |
| board-enamel | 13. Light behind UI | pass | key top-left on glaze and hot spot, foot and drop below |
| board-gold | 1. Layered materials | pass | brushed gold with three-stop body, gloss over the top, rim and thick lip; pressed face sinks |
| board-gold | 2. Display type | pass | heavy dark caps on the upper half of the gold face, legible at 1x |
| board-gold | 8. Colour roles and value | pass | gold reserved for main actions; words dark on gold with ample contrast |
| board-gold | 13. Light behind UI | pass | gloss and sparkle top-left, lip and drop below on every button |
| board-wood | 1. Layered materials | pass | oak frame with grain, bevel and inner well; leather pebbled and stitched on a lip |
| board-wood | 2. Display type | fail | THE WORKSHOP is outlined with a drop, but BUILD sits in thin unstroked Manrope on the textured leather |
| board-wood | 8. Colour roles and value | pass | leather clearly two value steps off the lit oak well; no hue roles misused |
| board-wood | 13. Light behind UI | pass | oak lit from the top, leather lit 28% from the top, drops below |
| board-glass | 1. Layered materials | fail | dark glass pills are uniform rounded rectangles with a hairline rim and a blur: the web overlay the rubric fails |
| board-glass | 2. Display type | fail | 2:41, 1:07 and 0:12 are plain body numerals with no outline, drop or fill gradient |
| board-glass | 8. Colour roles and value | pass | alarm words pink and escape words green in their dark-surface forms; pills read over all three skies |
| board-glass | 13. Light behind UI | fail | Disagreement, so fail: AD said pass (faint sheen top, soft drop below; one direction, though barely lit); the blind labeller said fail (No visible catch-light or top sheen on the pills; barely a highlight) |
| board-parchment | 1. Layered materials | fail | Disagreement, so fail: AD said pass (parchment with long fibres, browned rim, top light, ink edge and brown drop; reads as old paper, not a fill); the blind labeller said fail (Parchment grain and drop present, but the sheet is a single gradient with a thin outline: no bevelled frame, inner well or gloss) |
| board-parchment | 2. Display type | pass | Marcellus title and brown Manrope on calm paper, bold where light; legible |
| board-parchment | 8. Colour roles and value | fail | Disagreement, so fail: AD said pass (alarm and success words in their darker parchment forms, not the fill red and green); the blind labeller said fail (Red and green words set directly on parchment) |
| board-parchment | 13. Light behind UI | pass | lit at the top, browning and drop below |
| board-type | 1. Layered materials | pass | Sun-Step gold bar on a dark plate and the red Get out on a lip carry body, rim and lip |
| board-type | 2. Display type | pass | x250 and LEVEL 12 heavy with ink outline and hard drop; faces as §21.8 sets them |
| board-type | 8. Colour roles and value | pass | gold on the action bar, red on Get out, alarm and success words in their dark forms; law title on a dark plate |
| board-type | 13. Light behind UI | pass | Get out and the gold bar lit from the top, drops below |
| board-light | 1. Layered materials | fail | the only panel is a plain rounded rectangle with a faint rim and no gloss or lip; the spheres are swatches, not materials on a component |
| board-light | 2. Display type | pass | title and notes on the calm backdrop in §21.8 faces; nothing over art |
| board-light | 8. Colour roles and value | pass | nothing interactive; the dark enamel sphere sits close in value to the well but carries no role |
| board-light | 13. Light behind UI | pass | one cream key from the top left with violet shade on all three spheres |
| board-icons | 1. Layered materials | pass | tray has gloss band, rim and drop; icons modelled with bevels; glass pill as the board defines it |
| board-icons | 3. Painted or rendered icons | pass | starlight, essence, hourglass and loot bag modelled in the toon ramp, lit top-left, with specular and dark outline; read as grey shapes at 48 pt |
| board-icons | 8. Colour roles and value | pass | the four differ by shape as well as hue; grey row still distinct |
| board-icons | 13. Light behind UI | pass | all four lit from the top left, matching the tray |
| board-hc | 1. Layered materials | pass | each material made opaque with a 3-pt outline and its lip kept, as §21.8 high contrast asks |
| board-hc | 2. Display type | pass | labels heavy and dark-on-light or light-on-dark with full contrast |
| board-hc | 8. Colour roles and value | pass | value steps strong in both columns; dark surfaces take a light ring |
| board-hc | 13. Light behind UI | pass | lips and drops below every plain material; one direction |
| ai-starlight | 1. Layered materials | pass | gold body with three-stop gradient, gloss and soft drop |
| ai-starlight | 3. Painted or rendered icons | pass | modelled star lit top-left with rim, specular and dark outline |
| ai-starlight | 8. Colour roles and value | pass | gold reads as currency; strong value against the violet ground |
| ai-starlight | 13. Light behind UI | pass | key top-left, shade lower right |
| ai-essence | 1. Layered materials | pass | body gradient, gloss and drop present |
| ai-essence | 3. Painted or rendered icons | fail | glass-gem refraction and caustic inner light read physically based, against §21.3 toon look; outline green, not ink |
| ai-essence | 8. Colour roles and value | pass | green gem distinct by shape and value |
| ai-essence | 13. Light behind UI | pass | specular top-left, shade lower right |
| ai-chest | 1. Layered materials | pass | planked wood with grain, gold bands and studs, bevels and a drop |
| ai-chest | 3. Painted or rendered icons | pass | chest modelled, lit top-left, ink outline, specular glints; reads at 48 pt |
| ai-chest | 8. Colour roles and value | pass | wood and gold well separated in value; no role misused |
| ai-chest | 13. Light behind UI | pass | lit top-left, shade below and right |
| ai-pip | 1. Layered materials | pass | gold ring frame with gradient and dark outline around a mint well |
| ai-pip | 3. Painted or rendered icons | fail | Pip shaded with soft physical light and fur texture, not the toon ramp; figure spills out of its frame |
| ai-pip | 8. Colour roles and value | pass | character stands off the mint well; gold frame clear |
| ai-pip | 13. Light behind UI | pass | light from the top front, matching the frame highlight |
| today-icon-starlight | 1. Layered materials | fail | a flat gradient star with visible banding and one highlight; no material or volume |
| today-icon-starlight | 3. Painted or rendered icons | fail | a flat gradient glyph with an outline and no form, rim light or soft drop |
| today-icon-starlight | 8. Colour roles and value | pass | gold for a currency, clear value off the violet ground and in grayscale |
| today-icon-starlight | 13. Light behind UI | fail | Disagreement, so fail: AD said pass (the one highlight is top-left, in the common light direction); the blind labeller said fail (Highlight sits on the upper-right edge, not the top-left key) |
| today-icon-essence | 1. Layered materials | fail | a banded green gradient drop with a smudge inside; no material |
| today-icon-essence | 3. Painted or rendered icons | fail | a flat gradient glyph with outline and highlight, no 3D form, rim light or soft drop |
| today-icon-essence | 8. Colour roles and value | pass | the drop reads by shape as well as hue and holds its value in grayscale |
| today-icon-essence | 13. Light behind UI | pass | the highlight is top-left, matching the common key light |
| today-icon-loot | 1. Layered materials | fail | banded gradient fills on the bag, no grain or modelled material |
| today-icon-loot | 3. Painted or rendered icons | fail | more shape than the others but still a flat banded glyph, with a hard dark offset drop where §21.8 asks for a soft one |
| today-icon-loot | 8. Colour roles and value | pass | a warm gold-brown bag that keeps a clear dark shape in grayscale |
| today-icon-loot | 13. Light behind UI | pass | highlights on the top and top-left; shadow below |
| plant-gold-flat | 1. Layered materials | fail | gold cut to flat bands: brushing and gradient gone, gloss a hard cream stripe; reads as fills on a lip |
| plant-gold-flat | 2. Display type | pass | dark caps on the face still legible and heavy |
| plant-gold-flat | 8. Colour roles and value | pass | gold still marks the main actions; values still separate |
| plant-gold-flat | 13. Light behind UI | pass | light stripe on top, lip below; direction still reads |
| plant-enamel-flat | 1. Layered materials | fail | card body banded into flat steps, glaze a hard band; the enamel reads posterised |
| plant-enamel-flat | 2. Display type | pass | title and labels legible on the card |
| plant-enamel-flat | 8. Colour roles and value | fail | chosen card gold rim turned pale lilac and the teal pip grey: colours off the palette, chosen loses its role |
| plant-enamel-flat | 13. Light behind UI | pass | glaze on top, foot below; one direction |
| plant-hud-top-flat | 1. Layered materials | fail | panel bodies banded into two flat tones and the bevels stepped; gradient and grain gone at phone size |
| plant-hud-top-flat | 2. Display type | pass | numbers still heavy with ink outline and drop |
| plant-hud-top-flat | 8. Colour roles and value | pass | values still separate; only the Bloom flower lost its green to grey |
| plant-hud-top-flat | 13. Light behind UI | pass | top highlights and lips below survive |
| plant-starlight-flat | 1. Layered materials | fail | a single flat gold fill with a brown outline, no gradient, gloss or drop |
| plant-starlight-flat | 3. Painted or rendered icons | fail | flat glyph: no form, key light, rim or specular |
| plant-starlight-flat | 8. Colour roles and value | pass | gold currency still reads by shape and value |
| plant-starlight-flat | 13. Light behind UI | fail | no light at all on the icon, so no direction to match |
| plant-essence-flat | 1. Layered materials | fail | single flat green fill with an outline |
| plant-essence-flat | 3. Painted or rendered icons | fail | flat drop glyph with no form or light |
| plant-essence-flat | 8. Colour roles and value | pass | green drop reads by shape and value |
| plant-essence-flat | 13. Light behind UI | fail | no key light or shade on the icon |
| plant-heist-one-step | 1. Layered materials | fail | Global value squeeze turns bevels, gloss and lips to mud; panels read as flat fills |
| plant-heist-one-step | 2. Display type | fail | Ink outlines wash grey into the art; display type loses its weight |
| plant-heist-one-step | 3. Painted or rendered icons | fail | Icons lose their lit form and read as flat glyphs |
| plant-heist-one-step | 6. Hierarchy | fail | Nothing leads in grayscale; every mass sits in one mid-grey band |
| plant-heist-one-step | 8. Colour roles and value | fail | Controls sit about half a value step off their ground (dL* ~5) |
| plant-heist-one-step | 9. Character presence | fail | Portraits washed out and no longer stand out from the tray |
| plant-heist-one-step | 13. Light behind UI | fail | Highlights and the lit scene dissolve into haze; no light behind the UI |
| plant-heist-one-step | 14. One art-direction idea | pass | Toy leather-and-gold idiom still reads through the haze |
| plant-heist-dim | 1. Layered materials | pass | Gold bevelled frames, wells, gloss and lips survive the dim |
| plant-heist-dim | 2. Display type | pass | Outlined display numerals and titles still read |
| plant-heist-dim | 3. Painted or rendered icons | pass | Icons keep outline, form and key light |
| plant-heist-dim | 6. Hierarchy | pass | Cast still leads in grayscale though the margin is thin (borderline) |
| plant-heist-dim | 8. Colour roles and value | fail | Controls sit under one value step off their ground (dL* ~9); action gold no longer pops |
| plant-heist-dim | 9. Character presence | pass | Crew portraits rendered and framed in gold rings |
| plant-heist-dim | 13. Light behind UI | pass | Scene light dimmer but still sits behind the HUD (borderline) |
| plant-heist-dim | 14. One art-direction idea | pass | One toy leather-and-gold idiom throughout |
| plant-heist-unstroked | 1. Layered materials | pass | Gold bevelled frames, wells, lips and grain on every panel |
| plant-heist-unstroked | 2. Display type | fail | World labels Bramble · Carrier, Vault: 2 doors left, Guard route 3 · slow are thin white unstroked type over the art |
| plant-heist-unstroked | 3. Painted or rendered icons | pass | Icons toon-rendered with outlines and key light |
| plant-heist-unstroked | 6. Hierarchy | pass | Cast leads in grayscale; secondary controls fall behind |
| plant-heist-unstroked | 8. Colour roles and value | pass | Gold action, red exit; controls clear a value step |
| plant-heist-unstroked | 9. Character presence | pass | Crew portraits rendered in gold rings |
| plant-heist-unstroked | 13. Light behind UI | pass | Lit scene behind the HUD; panels catch top light |
| plant-heist-unstroked | 14. One art-direction idea | pass | Toy idiom holds, though the thin labels read like debug text (borderline) |
| plant-type-hue | 1. Layered materials | pass | bar and button keep body, rim and lip |
| plant-type-hue | 2. Display type | pass | display numbers keep outline and drop |
| plant-type-hue | 8. Colour roles and value | fail | hues mirrored: gold action bar lime, Get out green, alarm words green and success words pink; roles broken |
| plant-type-hue | 13. Light behind UI | pass | top light and drops kept |
| kf-home | 1. Layered materials | fail | Top HUD and experience cards are flat dark fills with a hairline tan border; island pills flat cream with no gloss band |
| kf-home | 2. Display type | fail | Big numbers 142.0k, 1,460, 82% are plain Manrope with no drop or gradient fill; no hero number treatment |
| kf-home | 3. Painted or rendered icons | pass | Nav and side icons are toon-rendered with outline and top-left key light |
| kf-home | 6. Hierarchy | fail | Collect and the gold Heist tab split the primary; eight cream island pills sit at the same grayscale value |
| kf-home | 8. Colour roles and value | pass | Gold marks actions, red reserved for badges; controls clear a value step off their ground |
| kf-home | 9. Character presence | fail | Only character is a ~44 pt corner avatar; nothing framed or alive in the interface |
| kf-home | 13. Light behind UI | pass | Lit violet scene with glow and vignette, Collect has a top gloss; cards themselves carry no light (borderline) |
| kf-home | 14. One art-direction idea | pass | Pills, icons, nav and Collect share one toy-box idiom though the cards are plain (borderline) |
| kf-home-text200 | 1. Layered materials | fail | Top HUD and experience cards are flat dark fills with a hairline tan border; island pills flat cream with no gloss band |
| kf-home-text200 | 2. Display type | fail | Currency icons overlap and clip the first glyphs of 142.0k, 31.4k, 82%; island pills lose their names |
| kf-home-text200 | 3. Painted or rendered icons | pass | Nav and side icons are toon-rendered with outline and top-left key light |
| kf-home-text200 | 6. Hierarchy | fail | Currency panels match the full-width Collect in weight; the top third is giant panels with no lead |
| kf-home-text200 | 8. Colour roles and value | pass | Gold marks actions, red reserved for badges; controls clear a value step off their ground |
| kf-home-text200 | 9. Character presence | fail | Corner avatar half hidden; no character presence in the interface |
| kf-home-text200 | 13. Light behind UI | pass | Lit violet scene with glow and vignette, Collect has a top gloss; cards themselves carry no light (borderline) |
| kf-home-text200 | 14. One art-direction idea | pass | Pills, icons, nav and Collect share one toy-box idiom though the cards are plain (borderline) |
| kf-home-hc | 1. Layered materials | fail | High-contrast cards are opaque with white outlines but still flat fills with no body gradient, gloss or lip |
| kf-home-hc | 2. Display type | fail | Big numbers 142.0k, 1,460, 82% are plain Manrope with no drop or gradient fill; no hero number treatment |
| kf-home-hc | 3. Painted or rendered icons | pass | Nav and side icons are toon-rendered with outline and top-left key light |
| kf-home-hc | 6. Hierarchy | fail | Collect and the gold Heist tab split the primary; eight cream island pills sit at the same grayscale value |
| kf-home-hc | 8. Colour roles and value | pass | Gold marks actions, red reserved for badges; controls clear a value step off their ground |
| kf-home-hc | 9. Character presence | fail | Disagreement, so fail: AD said fail (Only character is a ~44 pt corner avatar; nothing framed or alive in the interface); the blind labeller said pass (Rendered character portrait framed top left, readable at size) |
| kf-home-hc | 13. Light behind UI | fail | Disagreement, so fail: AD said pass (Lit violet scene with glow and vignette, Collect has a top gloss; cards themselves carry no light (borderline)); the blind labeller said fail (Lit scene, but the HC cards carry no top highlight; panels barely lit) |
| kf-home-hc | 14. One art-direction idea | fail | Disagreement, so fail: AD said pass (Pills, icons, nav and Collect share one toy-box idiom though the cards are plain (borderline)); the blind labeller said fail (Black rounded cards with white outlines read as app chrome beside toy islands and rendered icons) |
| kf-heist | 1. Layered materials | fail | HUD panels are leather with gold frame, stitch, grain and lip and Cast/Get out have gloss and lips, but the crew tray is a flat dark fill with a hairline rim |
| kf-heist | 2. Display type | pass | Clock 2:38 is heavy outlined numerals on a cream plate; Laws here is outlined gold display type |
| kf-heist | 3. Painted or rendered icons | pass | Sleepwalk, Glass, wand and door icons are toon-rendered with outlines and form |
| kf-heist | 6. Hierarchy | pass | Cast is the lightest mass in grayscale and Get out falls behind it by value though equal in area (borderline) |
| kf-heist | 8. Colour roles and value | pass | Gold for the Cast action, red for the Get out exit; every control clears a value step |
| kf-heist | 9. Character presence | fail | crew portraits rendered and framed in rings, but the stone portrait has a photographic rock texture and the knight a physically based metal sheen: a character in a physically based material, outside the one toon look |
| kf-heist | 13. Light behind UI | pass | Lit vault scene behind the HUD; panels catch top light, Cast glows |
| kf-heist | 14. One art-direction idea | pass | Leather, gold and toy-gem idiom held across HUD, tray and buttons |
| kf-heist-text200 | 1. Layered materials | fail | HUD panels are leather with gold frame, stitch, grain and lip and Cast/Get out have gloss and lips, but the crew tray is a flat dark fill with a hairline rim |
| kf-heist-text200 | 2. Display type | pass | Clock 2:38 is heavy outlined numerals on a cream plate; Laws here is outlined gold display type |
| kf-heist-text200 | 3. Painted or rendered icons | pass | Sleepwalk, Glass, wand and door icons are toon-rendered with outlines and form |
| kf-heist-text200 | 6. Hierarchy | fail | Full-width red Get out bar outsizes Cast; the exit takes the primary role |
| kf-heist-text200 | 8. Colour roles and value | pass | Gold for the Cast action, red for the Get out exit; every control clears a value step |
| kf-heist-text200 | 9. Character presence | fail | crew portraits rendered and framed in rings, but the stone portrait has a photographic rock texture and the knight a physically based metal sheen: a character in a physically based material, outside the one toon look |
| kf-heist-text200 | 13. Light behind UI | pass | Lit vault scene behind the HUD; panels catch top light, Cast glows |
| kf-heist-text200 | 14. One art-direction idea | pass | Leather, gold and toy-gem idiom held across HUD, tray and buttons |
| kf-heist-hc | 1. Layered materials | pass | High-contrast form: opaque cards with 3-pt light outlines, body gradient and drop |
| kf-heist-hc | 2. Display type | pass | Clock 2:38 is heavy outlined numerals on a cream plate; Laws here is outlined gold display type |
| kf-heist-hc | 3. Painted or rendered icons | pass | Sleepwalk, Glass, wand and door icons are toon-rendered with outlines and form |
| kf-heist-hc | 6. Hierarchy | pass | Cast is the lightest mass in grayscale and Get out falls behind it by value though equal in area (borderline) |
| kf-heist-hc | 8. Colour roles and value | pass | Gold for the Cast action, red for the Get out exit; every control clears a value step |
| kf-heist-hc | 9. Character presence | fail | crew portraits rendered and framed in rings, but the stone portrait has a photographic rock texture and the knight a physically based metal sheen: a character in a physically based material, outside the one toon look |
| kf-heist-hc | 13. Light behind UI | pass | Lit vault scene behind the HUD; panels catch top light, Cast glows |
| kf-heist-hc | 14. One art-direction idea | pass | Leather, gold and toy-gem idiom held across HUD, tray and buttons |
| kf-result | 1. Layered materials | fail | gold buttons, parchment Starlight plate and the moment panel are layered, but the Essence, Renown and crew panels are flat dark fills with a hairline gold border: no gloss band, no lip |
| kf-result | 2. Display type | fail | numbers outlined with a hard drop, but "HEIST COMPLETE", the subtitle, "1:52 · alarm 2/6" and "Entry fee 120 returned" sit unstroked on the sunburst |
| kf-result | 3. Painted or rendered icons | fail | reward icons (star, drop, gem, bell medal) are modelled and outlined, but the law reward rows use a thin line eye glyph and a bare glass pane, not icons framed in their school's shape |
| kf-result | 6. Hierarchy | pass | Raid again is the largest gold control and reads first after the reward in grayscale; the 3 S replay is gold too but half its size |
| kf-result | 8. Colour roles and value | pass | gold on actions (Raid again, replay), currencies keep their hues, "+3 pages" in the dark word green on parchment; Home and Raid well off their dark well |
| kf-result | 9. Character presence | fail | the only characters are three crew avatars about 30 pt across in a text row, the third a muddy blur; the reward is not framed with character art |
| kf-result | 13. Light behind UI | pass | rewards sit on a sunburst over a lit scene; panels and buttons lit from the top, lips below, one direction |
| kf-result | 14. One art-direction idea | pass | parchment, gold, inked violet cards and toy-like buttons all from one toy box over the island scene |
| kf-result-text200 | 1. Layered materials | fail | Starlight plate and Raid again keep gloss and lip, but the Essence and Renown rows are flat dark fills with a hairline border, no gloss or lip |
| kf-result-text200 | 2. Display type | fail | at 200% the subtitle "A guard alerted · everyone out" and "1:52 · alarm 2/6" are large unstroked words on the sunburst; numbers keep outline and drop |
| kf-result-text200 | 3. Painted or rendered icons | fail | Disagreement, so fail: AD said pass (star, drop and gem stay modelled with an outline and highlight; the law rows with the line glyph are not on this form); the blind labeller said fail (Reward icons are small gradient glyphs with outline and a dot highlight; little 3D form or rim light) |
| kf-result-text200 | 6. Hierarchy | fail | Disagreement, so fail: AD said pass (Raid again is by far the largest, warmest control; Home shrinks to an icon key; rewards step down in a clear list); the blind labeller said fail (At 200% the prose subtitle sits at the weight of the reward; cream Starlight plate rivals RAID AGAIN in grayscale) |
| kf-result-text200 | 8. Colour roles and value | pass | gold only on Raid again and the Starlight count; currency hues kept; controls well off their dark well |
| kf-result-text200 | 9. Character presence | fail | no character on the screen at all: the crew row is dropped at 200% and the reward has no character frame |
| kf-result-text200 | 13. Light behind UI | pass | rewards on the sunburst over the lit scene; one top light on every plate and button |
| kf-result-text200 | 14. One art-direction idea | fail | Disagreement, so fail: AD said pass (same toy-box plates, gold and parchment as the 100% form; nothing borrowed); the blind labeller said fail (Toy plate and button beside web-like dark hairline rows) |
| kf-result-hc | 1. Layered materials | pass | high-contrast form per §21.8: opaque cards with light 3-pt outlines, no glass; buttons and parchment plates keep gloss and lip |
| kf-result-hc | 2. Display type | pass | words sit on a plain dark fill, not art; big numbers outlined with a drop; one treatment per rank |
| kf-result-hc | 3. Painted or rendered icons | fail | reward icons modelled and outlined, but the law rows keep the thin line eye glyph and a bare pane with no school-shape frame |
| kf-result-hc | 6. Hierarchy | pass | Raid again largest gold control, first in grayscale after the reward |
| kf-result-hc | 8. Colour roles and value | pass | gold on actions, currency hues kept, outlines lift every card well off the ground |
| kf-result-hc | 9. Character presence | fail | crew avatars about 30 pt in a text row, one unreadable; reward not framed with character art |
| kf-result-hc | 13. Light behind UI | fail | the sunburst and scene are gone: the reward sits on a plain fill; panels still lit from the top |
| kf-result-hc | 14. One art-direction idea | pass | toy-like gold buttons and parchment plates kept; reads as this game even on the plain ground |
| kf-character | 1. Layered materials | pass | gold buttons and Level up with gloss and lip, parchment panel with grain, ability well bevelled and set in; trait cells are plain but read as wells inside the panel |
| kf-character | 2. Display type | fail | "Skyskipper · Carrier" and "Level 4 of 6" are unstroked words on the backdrop gradient; name plate, Level up and 90 are fine |
| kf-character | 3. Painted or rendered icons | pass | the Essence drop on the cost is modelled with gloss and outline; trait and tab icons are chunky inked badges |
| kf-character | 6. Hierarchy | pass | the character then Level up, the largest gold control at the bottom; arrows, LV badge and Heist tab are gold too but clearly smaller |
| kf-character | 8. Colour roles and value | pass | gold on actions and selected tab, green only on the progress pips, Motion tag in its school colour with its chevron; controls well off their ground |
| kf-character | 9. Character presence | pass | a large rendered toon character on a plinth, lit and framed by the name plate; reads as a dark shape at 32 pt |
| kf-character | 13. Light behind UI | pass | lit vignette behind the character; every panel and button lit from the top, lips below |
| kf-character | 14. One art-direction idea | pass | plinth, plate, parchment cards and gold buttons all from one toy box |
| kf-character-text200 | 1. Layered materials | pass | Heist tab, Level up and arrows keep gloss band, rim and lip; parchment and ability well bevelled |
| kf-character-text200 | 2. Display type | fail | "Skyskipper · Carrier" and "Level 4 of 6" large and unstroked on the backdrop gradient |
| kf-character-text200 | 3. Painted or rendered icons | pass | Essence drop modelled with gloss and outline; tab icons keep their volume |
| kf-character-text200 | 6. Hierarchy | pass | Level up is the largest gold control; the gold Heist tab is big but a step down |
| kf-character-text200 | 8. Colour roles and value | pass | same roles as 100%: gold actions, green progress, school tag with its shape |
| kf-character-text200 | 9. Character presence | pass | still a recognisable rendered character at the top, though squeezed between the 2/5 and free pills and half hidden by the plate |
| kf-character-text200 | 13. Light behind UI | pass | lit vignette and one top light on every plate |
| kf-character-text200 | 14. One art-direction idea | pass | the same toy-box parts as the 100% form |
| kf-character-hc | 1. Layered materials | fail | Disagreement, so fail: AD said pass (opaque cards with light outlines per §21.8's high contrast; gold buttons and parchment keep gloss and lip); the blind labeller said fail (Info cards are flat cream fills with a hairline outline and no lip; HC pills plain) |
| kf-character-hc | 2. Display type | pass | words on a plain dark fill, not art; name plate and numbers heavy and inked |
| kf-character-hc | 3. Painted or rendered icons | fail | Disagreement, so fail: AD said pass (Essence drop modelled; badges keep volume and outline); the blind labeller said fail (Essence drop and trait icons are small gradient glyphs with little form or rim light) |
| kf-character-hc | 6. Hierarchy | pass | character then Level up, the largest gold control |
| kf-character-hc | 8. Colour roles and value | pass | gold actions, green progress, outlines lift every control off the ground |
| kf-character-hc | 9. Character presence | pass | the same large rendered character on its plinth, framed by the plate |
| kf-character-hc | 13. Light behind UI | fail | Disagreement, so fail: AD said pass (no reward or modal; panels and buttons lit from the top, one direction); the blind labeller said fail (Plain dark backdrop with no glow; cards carry no top highlight) |
| kf-character-hc | 14. One art-direction idea | fail | Disagreement, so fail: AD said pass (same toy-box parts on the plain high-contrast ground); the blind labeller said fail (Black HC pills with white outlines and flat cream cards read as app chrome beside the toy character) |
| kf-settings | 1. Layered materials | pass | parchment tabs and rows with grain, gloss and lip; gold buttons layered; dark panels with a lit header band and bevel; Back on a set-in well |
| kf-settings | 2. Display type | fail | the group headers "Access" and "Seeing and comfort" are unstroked words on the backdrop gradient; 100% is heavy, outlined and dropped |
| kf-settings | 3. Painted or rendered icons | fail | Disagreement, so fail: AD said pass (school badges are glossy domed icons with an outline, each carrying its school's shape; gear and access icons have volume); the blind labeller said fail (School icons are line glyphs on identical glossy circles; no school-shaped frames) |
| kf-settings | 6. Hierarchy | fail | Disagreement, so fail: AD said pass (no primary named; the Settings plate and the gold Access tab outrank the rows, though the thin serif group headers barely outweigh the bold row labels); the blind labeller said fail (Thin group headers are outranked by the bright parchment rows they head) |
| kf-settings | 8. Colour roles and value | pass | gold only on actions and the selected tab; each school its colour plus its shape; toggles and buttons well off their ground |
| kf-settings | 13. Light behind UI | pass | backdrop lit from the top with a vignette; every panel and button lit from the top, lips below |
| kf-settings | 14. One art-direction idea | pass | a game's settings: parchment, gold and inked cards, not an app list |
| kf-settings-text200 | 1. Layered materials | pass | tabs, A buttons, Stillness parchment and Back keep gloss, rim and lip |
| kf-settings-text200 | 2. Display type | fail | the "Access" header is a large unstroked word on the backdrop gradient |
| kf-settings-text200 | 3. Painted or rendered icons | pass | the few icons keep volume and outline |
| kf-settings-text200 | 6. Hierarchy | pass | Settings title and the gold Access tab lead; the Access header outranks the row |
| kf-settings-text200 | 8. Colour roles and value | pass | gold on actions only; controls well off their ground |
| kf-settings-text200 | 13. Light behind UI | pass | lit backdrop with vignette; one top light |
| kf-settings-text200 | 14. One art-direction idea | pass | the same toy-box parts as the 100% form |
| kf-settings-hc | 1. Layered materials | pass | opaque cards with light 3-pt outlines per §21.8; parchment rows and gold buttons keep gloss and lip |
| kf-settings-hc | 2. Display type | pass | headers sit on a plain dark fill, not art; 100% heavy and inked |
| kf-settings-hc | 3. Painted or rendered icons | pass | school badges keep volume, outline and their shapes |
| kf-settings-hc | 6. Hierarchy | pass | title and Access tab lead, group headers over rows |
| kf-settings-hc | 8. Colour roles and value | pass | gold actions; green only on the on toggle; schools by shape and colour |
| kf-settings-hc | 13. Light behind UI | pass | no reward or modal; panels lit from the top, lips below |
| kf-settings-hc | 14. One art-direction idea | pass | same toy-box parts on the plain high-contrast ground |
| plant-kf-home-unstroked | 1. Layered materials | fail | Top HUD and experience cards are flat dark fills with a hairline tan border; island pills flat cream with no gloss band |
| plant-kf-home-unstroked | 2. Display type | fail | World labels Skyfield, Verdant, Emberreach, The Heart are thin white unstroked type; numbers plain Manrope |
| plant-kf-home-unstroked | 3. Painted or rendered icons | pass | Nav and side icons are toon-rendered with outline and top-left key light |
| plant-kf-home-unstroked | 6. Hierarchy | fail | Collect and the gold Heist tab split the primary; eight cream island pills sit at the same grayscale value |
| plant-kf-home-unstroked | 8. Colour roles and value | pass | Gold marks actions, red reserved for badges; controls clear a value step off their ground |
| plant-kf-home-unstroked | 9. Character presence | fail | Disagreement, so fail: AD said fail (Only character is a ~44 pt corner avatar; nothing framed or alive in the interface); the blind labeller said pass (Rendered character portrait framed top left, readable at size) |
| plant-kf-home-unstroked | 13. Light behind UI | fail | Disagreement, so fail: AD said pass (Lit violet scene with glow and vignette, Collect has a top gloss; cards themselves carry no light (borderline)); the blind labeller said fail (Lit scene, but cards carry no top highlight) |
| plant-kf-home-unstroked | 14. One art-direction idea | fail | Disagreement, so fail: AD said pass (Pills, icons, nav and Collect share one toy-box idiom though the cards are plain (borderline)); the blind labeller said fail (Thin web-style labels and translucent cards beside toy islands) |
| plant-kf-result-flat | 1. Layered materials | fail | flattened to a few flat colours: parchment grain, gloss bands and bevels gone; plates read as fills |
| plant-kf-result-flat | 2. Display type | fail | numbers keep an outline but lose their fill gradient; "Entry fee 120 returned" unstroked on the backdrop |
| plant-kf-result-flat | 8. Colour roles and value | fail | the currency hues collapse: the Essence drop is brown, the gem and star beige, so the colour roles no longer read |
| plant-kf-result-flat | 13. Light behind UI | fail | the sunburst and top light are posterized away; plates sit on a flat ground with no light |
| plant-kf-heist-icon-flat | 1. Layered materials | fail | Loot bag is a few flat posterised fills with no gradient or gloss |
| plant-kf-heist-icon-flat | 3. Painted or rendered icons | fail | Flat glyph: no 3D form, key light or specular |
| plant-kf-heist-icon-flat | 8. Colour roles and value | pass | Outline and value still read as a dark shape at 48 pt and in grayscale |
| plant-kf-heist-icon-flat | 13. Light behind UI | fail | Disagreement, so fail: AD said fail (No highlight left; light direction lost); the blind labeller said pass (Flat, but the lighter top and shaded foot keep one top light) |
| plant-kf-heist-cast-sunk | 1. Layered materials | fail | HUD panels are leather with gold frame, stitch, grain and lip and Cast/Get out have gloss and lips, but the crew tray is a flat dark fill with a hairline rim |
| plant-kf-heist-cast-sunk | 2. Display type | pass | Clock 2:38 is heavy outlined numerals on a cream plate; Laws here is outlined gold display type |
| plant-kf-heist-cast-sunk | 3. Painted or rendered icons | pass | Sleepwalk, Glass, wand and door icons are toon-rendered with outlines and form |
| plant-kf-heist-cast-sunk | 6. Hierarchy | fail | Get out now outranks the dulled Cast; the primary no longer leads |
| plant-kf-heist-cast-sunk | 8. Colour roles and value | fail | Cast face pulled to a muddy brown-gold; action gold no longer reads (dL* ~21, borderline) |
| plant-kf-heist-cast-sunk | 9. Character presence | fail | crew portraits rendered and framed in rings, but the stone portrait has a photographic rock texture and the knight a physically based metal sheen: a character in a physically based material, outside the one toon look |
| plant-kf-heist-cast-sunk | 13. Light behind UI | pass | Lit vault scene behind the HUD; panels catch top light, Cast glows |
| plant-kf-heist-cast-sunk | 14. One art-direction idea | pass | Leather, gold and toy-gem idiom held across HUD, tray and buttons |
| audit1-heist-hc-a4d87d18 | 6. Hierarchy | pass | Hierarchy: the gold Cast is the lightest control in the squint and the only main-action fill; the Room panel is larger but darker, so it does not compete. |
| audit1-heist-hc-a4d87d18 | 8. Colour roles and value | fail | Colour roles: the mauve Get out and Walk faces sit only 5-6 L* off the grass and sky behind them (under the 20 an interactive control needs); only the ink outline separates them, and the high-contrast cards stay mauve rather than light on dark. |
| audit1-home-text200-977edd5b | 2. Display type | fail | Display type: 'Guardião 24' sits over the sky with no ink outline, and the currency counts are flat cream headline figures with no outline, hard drop or gradient fill. |
| audit1-home-text200-977edd5b | 6. Hierarchy | pass | Hierarchy: Coletar is the full-width gold bar at the foot and leads in grayscale by size, place and weight. |
| audit1-settings-text200-9e602fcc | 2. Display type | pass | Display type: every word sits on a plate or card; the 200% figure is a headline figure with an ink outline, a hard drop and a gradient fill; nothing clipped or under 13 pt. |
| audit1-settings-text200-9e602fcc | 6. Hierarchy | pass | Hierarchy (borderline): no primary on settings; the Ajustes title plate leads by place and size, and the selected tab is dark brown with a gold rim, not a gold fill louder than the title. |
| audit1-result-b5843368 | 2. Display type | pass | Display type: words over the sunburst carry an ink outline of about 3 pt, and +508 is a headline figure with outline, hard drop and gradient fill. |
| audit1-result-b5843368 | 9. Character presence | fail | Character presence: the reward card (+508 Loot) shows no character and no crew portrait is on screen; a reward with no character fails. |
| audit1-home-hc-e674b614 | 6. Hierarchy | pass | Hierarchy: the gold Collect at the foot is the lightest control and leads; the XP panel is larger but dark, so it does not compete (v3). |
| audit1-home-c9a89e5a | 6. Hierarchy | pass | Hierarchy: the gold Collect at the foot leads in grayscale by size, place and weight; the tabs and info panel sit below it. |
| audit1-home-c9a89e5a | 9. Character presence | pass | Character presence: the keeper portrait is soft orange fur with a cream belly and dark eyes, a clear dark shape inside its gold ring, in the toon look. |
| audit1-character-hc-f1251e68 | 6. Hierarchy | pass | Hierarchy: Level up is the full-width foot control carrying the primary's label and leads; the white tabs are high-contrast cream cards that do not compete for lightness alone (v3). |
| audit1-character-hc-f1251e68 | 8. Colour roles and value | pass | Colour roles: gold only on Level up (main-action fill), the arrows and as frame material; controls clear ΔL* 20 (arrows 44, Level up 75, tabs 80); dark pills carry light outlines. |
| audit1-character-text200-6b7e6b42 | 2. Display type | fail | Display type: at 200% 'Skyskipper · Carregador' and 'Nível 3 de 10' sit over the sky with a 1-2 pt outline on about 32 pt words, under the 12% stroke words over art need. |
| audit1-character-text200-6b7e6b42 | 6. Hierarchy | pass | Hierarchy: Subir de nível is the full-width gold foot control and leads in grayscale. |
| audit1-home-text200-1697a6c6 | 2. Display type | fail | Display type: 'Guardião 24' sits over the sky with no ink outline, and the currency counts are flat headline figures with no outline, hard drop or gradient fill. |
| audit1-home-text200-1697a6c6 | 6. Hierarchy | pass | Hierarchy: Coletar is the full-width gold foot control and leads in grayscale. |
| audit1-home-hc-977edd5b | 6. Hierarchy | pass | Hierarchy: Collect leads at the foot; the XP panel is dark and does not compete. |
| audit1-home-hc-977edd5b | 8. Colour roles and value | fail | Colour roles: the XP bar is filled in the main-action gold (the key frame uses green), so gold takes a second role on a non-action. |
| audit1-settings-f0a36a41 | 2. Display type | pass | Display type: every word sits on a plate or card; the 100% figure has an ink outline, a hard drop and a gradient fill; nothing clipped or under 13 pt. |
| audit1-settings-f0a36a41 | 6. Hierarchy | pass | Hierarchy (borderline): no primary on settings; the title plate leads by place and size, the selected tab is dark with a gold rim, and the A steppers are cream, not gold. |
| audit1-home-e674b614 | 2. Display type | pass | Display type: 'Keeper 24' over the sky carries an ink outline of about 13% plus a rim band and drop; the currency counts are gradient-filled numerals with ink outline and drop (the outline reads weakly on the near-black plates, and the 'k' is cream, a minor inconsistency). |
| audit1-home-e674b614 | 6. Hierarchy | pass | Hierarchy: the gold Collect at the foot leads in grayscale by size, place and weight. |
| audit1-home-e674b614 | 9. Character presence | pass | Character presence: the keeper portrait is cream-orange soft fur with dark eyes, a clear face in its gold ring, in the toon look. |
| audit1-heist-text200-5470c4d3 | 1. Layered materials | fail | Layered materials: the large hint plate is one translucent dark fill with a hairline gold rim, no gloss band or lip, beside four-layer buttons and panels. |
| audit1-heist-text200-5470c4d3 | 2. Display type | fail | Display type: 'Laws here' over the night sky has an outline of about 1 pt that merges into the dark, crew names carry outlines far under 12%, and the 2:25 timer is a flat headline figure with no outline, drop or gradient. |
| audit1-heist-text200-5470c4d3 | 3. Painted or rendered icons | fail | Painted icons: the Bloom law icon is a flat green two-tone glyph with no key light, rim light or specular and no school frame. |
| audit1-heist-text200-5470c4d3 | 6. Hierarchy | fail | Hierarchy: the Cast slot ('No casts') is dim mauve, and the red Get out beside it, the same size and lighter, draws the eye first in grayscale; a red control before the primary fails. |
| audit1-heist-text200-5470c4d3 | 8. Colour roles and value | fail | Colour roles: No casts (ΔL* 9), Get out (17) and pause (17) sit under 20 against the island and sky; the Cast slot is mauve, not the main-action gold. |
| audit1-heist-text200-5470c4d3 | 9. Character presence | pass | Character presence (borderline): crew portraits read as toon bodies: Scout cream fur (light on its yellow ring, read by its face), Breaker charcoal with orange glow cracks in soft shading, Carrier brown fur with a cream chest. |
| audit1-heist-text200-5470c4d3 | 13. Light behind UI | pass | Light behind UI: the island scene is a lit ground; tops carry gloss and lips sit below, one light direction throughout. |
| audit1-heist-text200-5470c4d3 | 14. One art-direction idea | pass | One art-direction idea (borderline): toy leather panels and buttons throughout; the hint plate is plain but drawn without blur or web chrome. |
| audit1-result-aed28321 | 6. Hierarchy | pass | Hierarchy (borderline): Raid again is the large gold foot bar, about 2.3x Home, and leads by size, place and saturation (v3); the cream Loot card and Home are lighter, and the small 3 s replay button is also gold. |
| audit1-result-aed28321 | 9. Character presence | fail | Character presence: the +508 Loot reward card shows a sparkle and no character, and no crew is on screen; a reward with no character fails. |
| audit1-settings-hc-f5719f28 | 6. Hierarchy | pass | Hierarchy (borderline): no primary on settings; the title plate leads by place and size; the white cards are the high-contrast design (v3); the group headers are thin; the gold 100% is a figure, not a button. |
| audit1-settings-hc-f5719f28 | 8. Colour roles and value | pass | Colour roles: the selected tab is dark with a gold rim (material); green marks the on toggle; school icons carry shapes, not hue alone; light controls on dark clear ΔL* 20 by far. |
| audit1-home-3612e265 | 6. Hierarchy | pass | Hierarchy: the gold Collect leads in grayscale over the Islands and Heist tabs. |
| audit1-home-3612e265 | 9. Character presence | pass | Character presence: the same soft-fur toon portrait, a clear dark face shape inside its gold ring. |
| audit1-settings-5fc97aac | 2. Display type | pass | Display type: words sit on plates and cards (the group headers on dark pills); the 100% figure has a gold gradient, a thick ink outline and a drop; nothing clipped or under 13 pt. |
| audit1-settings-5fc97aac | 6. Hierarchy | fail | Hierarchy (borderline): settings has no primary, and the gold-filled A value steppers are the most saturated marks on screen and, with the cream tab strip, outweigh the dark title plate; a gold value button louder than the title fails. |
| audit1-home-a4090ec7 | 2. Display type | pass | Display type: 'Keeper 24' over the sky carries a warm ink outline and drop; the currency counts are gold-gradient headline figures with ink outline and drop, the 'k' now matching; labels sit on plates. |
| audit1-settings-hc-eed8b817 | 6. Hierarchy | pass | Hierarchy (borderline): no primary on settings; the Settings title plate leads by place and size; the white tab strip and A steppers are high-contrast cream cards (v3), not gold; group headers are smaller than the title but no louder than the rows. |
| audit1-settings-hc-eed8b817 | 8. Colour roles and value | pass | Colour roles: gold only as the selected tab's rim and the 100% figure; green marks the on toggle; school icons keep their shapes; white controls on dark clear ΔL* 20 by far. |
