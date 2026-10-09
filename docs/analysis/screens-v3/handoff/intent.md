# Handoff README.md and SCREENS.md: the owner's intent and the implementation spec, against v3.6

Part: `intent`. Sources read in full: the handoff's `README.md` (239 lines) and `SCREENS.md` (179 lines), both copied unchanged to `source/` and cited as README.md:line and SCREENS.md:line. Checked against `docs/design/ruleborn-game-design-v3.6.txt` (cited as v36:line), the register (`tools/audit_register.py`, cited as AR:line), the brief (`docs/decisions/brief.json`, cited as brief:line), the answers (`docs/decisions/answers.json`), the roadmap (`tools/roadmap.py`, cited as RM:line) and the earlier analysis (`docs/analysis/screens-v3/`). Prototype source was read where a README statement describes it; the screen files the earlier reading saw are byte-identical to the handoff's except the root page's packaging, the `.bin` meshes, three.js and six `world/*.png` (hash comparison of all 244 files: 229 identical).

Read against the repository at commit 6cc1d1e; the line numbers it cites in the register (AR), the brief and the roadmap (RM) are that commit's. What it proposes was checked and folded into the register's v3.6 layer, the brief and stage SD afterwards ([README.md](README.md)). The earlier reading's reports, cited by file name, are in the folder above.

Rules applied. v3.6 §23.5 (v36:11387-11393): the document wins on a rule, a number or a piece of text; where it is silent and a design breaks no rule, the design is adopted; a design never adds a mechanic; §23.2 is the must-show list. Statements in the handoff such as "final" or "at the user's request" are the owner's intent. None is a recorded answer, and none is treated as one here.

## Findings

### H-1 (intent, high). The handoff calls the UI's colours, type, spacing, copy, numbers and interactions final

- README.md:20: "**High fidelity.** Colours, type, spacing, copy, numbers and interactions are final. Recreate the UI pixel-accurately at 390 × 844 logical points".
- v36:11387: "This document wins wherever it states a rule, a number or a piece of text." v36:11385: "The designs carry the look: layout, art, motion, the models and the icons."
- So for colours, type and spacing (the look), the owner's word and §23.5 point the same way. For copy and numbers they do not: §23.5's own table lists 30 places where the design's numbers or words lose (v36:11423-11568), and the register adds D73 to D96.
- It bears on four open brief entries whose recommendation depends on reading the owner's intent: D89 (surfaces; brief:5935), D90 (typefaces; brief:6002), D91 (icon finish and motion; brief:6672) and C44 (home layout and chrome; brief:4383). It also bears on C45 (brief:4522): the handoff's precedence names no recorded answer (see H-13).
- "Interactions are final" includes the motion timings D91's recommended option C would shorten (H-9).

Proposed: brief-context D89, D90, D91, C44: add one line each, "The owner's handoff (README.md:20) calls colours, type, spacing, copy, numbers and interactions final and asks for a pixel-accurate rebuild. This is intent, not an answer. Where §23.5 says the document wins (numbers, words, §21.1's sizes, §21.8's timings and contrast) it still wins." Do not mark any of them answered.

### H-2 (intent, high). Camera and gestures: the owner wants pinch and twist with no zoom buttons, and the 3D camera "final"; §20.8 and §21.1 say otherwise

- README.md:178: "**Camera:** a high three-quarter angle. Players pinch to zoom and twist to rotate; there are no zoom buttons." README.md:22: "The 3D scenes are also high fidelity for composition, camera, palette, scale and motion." SCREENS.md:31 (Realm view): "Pinch to zoom, twist to turn."
- v36:10300 (§20.8): "No action needs more than one finger; nothing needs a fast tap, a double tap or a drag that can't also be done as two taps". v36:10402 (§21.1): "An orthographic diorama view at a 35° pitch in a tall frame, rotatable in 90° steps, with three zoom levels".
- D75 (AR:6823) already holds both rows as departures ("Rotate and zoom — two fingers only … nothing on screen calls them"; "Camera — perspective, 28° wide on the map and 20° in a realm, pitched about 46°"), with the rec "Add the rows to §23.5; the build follows the document". D75 has no brief entry. The handoff now says the owner wants exactly what D75 says the build will not do.
- "Palette" and "scale" bear on D92 (the diorama's 10% saturation and four-step ramp; brief recommends C) and D93 (every view several times over §21.3's budgets).
- The roadmap does not carry the one-finger controls at all: TD.19 (RM:1827) and TD.10 (RM:1455) name "the orthographic camera in 90-degree steps" and tile picking, but no rotate or zoom control a single finger can use. The analysis proposed them (screens-home-realm-shell.md:306 "rotate and zoom buttons beside the gestures (§20.8)").

Proposed: register-amend D75: quote README.md:178 and :22 in its body, and split two rows out to the brief: (a) the camera (is §21.1's orthographic 35° view a rule, or a look §23.5 gives the design?); (b) one-finger rotate and zoom, where §20.8 is a rule and stands under any answer, so the only open part is the form: always-visible buttons, buttons shown only with an accessibility setting, or a one-finger two-tap control. Roadmap-amend TD.19 and TD.10: "rotate and zoom reachable with one finger (§20.8), in the form the owner picks; pinch and twist kept as shortcuts".

### H-3 (intent, high). "Landscape is not supported" contradicts §23.3 and the roadmap's TD.28

- README.md:20: "scale it to the device; landscape is not supported."
- v36:11335 (§23.3): "Portrait is the default on phones; landscape is available everywhere and remembered per device." v36:11560-11562 (§23.5): "Landscape | Not designed | Portrait and landscape | 23.3". §23.3 costs it at "about 15 to 20% more interface work".
- TD.28 (RM:2123, "Landscape for every screen") builds it for every screen, blocked on 21 other tasks. No register item and no brief entry carries landscape; the owner's statement is the first sign that the owner may not want it.

Proposed: brief-new (with H-4): "Landscape at launch: everywhere (§23.3, §27.2), heists only (§21.1, §24, §27.5), or not at launch (the handoff)". TD.28 then waits on that answer as TD.50-TD.61 wait on theirs; an answer of "not at launch" closes TD.28 with nothing built and removes §23.5's Landscape row.

### H-4 (missed, high). v3.6 states landscape's scope two ways

- Everywhere: v36:11335 (§23.3) "landscape is available everywhere and remembered per device"; v36:12919 (§27.2) "landscape available everywhere and remembered per device".
- Heists only: v36:10411 (§21.1) "Heists can be rotated to landscape for a wider view"; v36:11643 (§24's engine row) "Portrait-first, landscape optional in heists"; v36:13065 (§27.5) "home, menus and the Workshop in portrait … heists playable in portrait with landscape optional (21.1)".
- The register has no item on it (a search of AR for "landscape" finds only D80's mention of §23.5's row). TD.28 builds the "everywhere" reading.

Proposed: register-new contradiction (minor, v3.6 against itself): "§23.3 and §27.2 put landscape on every screen; §21.1, §24 and §27.5 put it in heists only." Rec: the owner decides with H-3's brief entry; the losing sentences are rewritten in one line each.

### H-5 (spec, high). The handoff asks for a 390 × 844 frame scaled to the device; TD.2 keeps a 360-point frame

- README.md:20: "Recreate the UI pixel-accurately at 390 × 844 logical points and scale it to the device". SCREENS.md:3: "all exact sizes, colours and copy are in that element's inline styles".
- TD.2 (RM:1288, detail at RM:1303): "The frame stays at 360 points: a 390-point base would draw 13-pt text at 12 real points on 360-dp phones." The analysis found the same (design-system.md DS-10, §10.1).
- Scaling a 390-point layout to a 360-point phone multiplies every size by 0.923: §21.8's 13-point floor (v36:10992) becomes 12 points and §21.1's 48-point controls (v36:10411) become 44. So following the handoff literally breaks two rules the document states, on the phones §24 names as the reference device class. TD.2's choice is right under §23.5, but it is a roadmap decision against the owner's written instruction, with no register item or brief entry. C44's numbers already mix both frames (brief:4403 "at a 390-point frame, five 54-point tabs fit").

Proposed: register-new (gap, minor) and a brief entry: "The design is drawn at 390 points; the build lays it out on a 360-point frame and reflows, so §21.8's 13 points and §21.1's 48 points hold on every phone. Alternative: scale the 390 layout (the handoff), which needs the sizes raised by 8% first." Roadmap-amend TD.2: cite README.md:20 and say the 390-point layout is reflowed, never scaled down.

### H-6 (missed, medium). The eight note colours: §21.2 ties them to §8.1's wheel; the design has two palettes and the handoff picks one

- v36:10456 (§21.2): "Notes use the colours of the wheel in 8.1, each with its symbol". The wheel (v3.6 HTML, the §8.1 figure) fills: Flow #B3820A, Spark #D98A1A, Glow #C4541D, Echo #11809A, Weight #6A4FC9, Bloom #2C8541, Hush #3A3350, Veil #AD3A8D.
- README.md:116-117: "Flow `#3CC6D8`, Weight `#8C6CF0`, Glow `#F2B43C`, Hush `#5A4A9A`, Bloom `#5CC46A`, Spark `#F07A3C`, Echo `#E05CB4`, Veil `#8A7A6A`". All eight differ from the wheel.
- The design itself has two palettes: the Harmony view's (screens_meta.js:431, the README's) and Weaving's (screens_main.js:367: "Weight:'#5A6A9A' … Hush:'#8C6CF0' … Veil:'#B08AC0'"). Weight and Hush swap colours between the two screens, so the same note reads in two colours.
- Six of the README's note colours are school main colours (Flow = Time's #3CC6D8, Weight = Matter's, Glow = Motion's, Bloom = Life's, Spark = Energy's, Echo = Spirit's), so a note chip and a school tag can look alike; §20.8 forbids information by colour alone, and the symbol carries it, but the token set should not collide by accident.
- Not in the register, the brief or the analysis (searched AR, brief.json and docs/analysis/screens-v3 for "wheel", note hexes and "note colour").

Proposed: register-new (deviation, minor): "Note colours: the design uses two palettes that swap Weight and Hush, neither §8.1's wheel that §21.2 names." Rec: one palette; the document's wheel unless the owner amends §21.2 to the Harmony view's; Weaving follows it. Roadmap-amend TD.2: a `note` token set with the wheel's values as value and the Harmony view's beside them.

### H-7 (spec, medium). The README's school tokens give icon ramps, not §21.2's shadow tints

- README.md:108-114 lists each school as "light, base, dark, deepest", e.g. Motion `#FFF3C8 #F2B43C #A8641A #5A3208`. The base matches §21.2 (v36: §21.2 table). The dark stop does not match §21.2's shadow tint for any school: Motion #A8641A vs #B8741E, Matter #4E34A8 vs #5A3FB0, Time #16748A vs #1F8499, Energy #A8401A vs #B04A1E, Life #257A3A vs #2F8A45, Spirit #982E78 vs #9C3380.
- These are the `RBIcons` ramp (realm_diorama.js:7); the design's UI table `S` (screens_main.js:2-8) carries §21.2's exact shadows. design-system.md §2.1 says to keep the icon ramps inside the icon export, not as tokens.
- TD.2 (RM:1288) says §21.2's colours are ones "which the design matches exactly". That holds for `S`, not for the handoff's token list, which a porter would read first.

Proposed: roadmap-amend TD.2: "School tokens are §21.2's main and shadow (the design's `S`); the README's four-stop ramps are icon-internal and are not tokens."

### H-8 (stale, medium). D90's account of the typefaces is not the owner's role split

- README.md:121-126: "**Lilita One** 400: numbers, buttons, names, card titles … **Marcellus** 400: serif screen titles on some screens … **Manrope** 500–900: body and labels." README.md:69: titles in "Lilita One 26 pt … or Marcellus 26 pt on older screens".
- The source agrees with the README: on screens 10-27 the 26-pixel titles are Lilita One (screens_meta.markup.html: 6 at `400 26px/1 'Lilita One'`, 1 Marcellus at 26 px); Marcellus is the title face on 01-09 and 22 (18 `font-family:Marcellus` in screens_main.markup.html).
- D90's body (AR:8474) reads "screen titles and names in Marcellus (about 80)", and the brief's recommended option B (brief:6002) gives "Lilita One for large numbers that do not change and some titles; Marcellus for titles and law names". The owner's handoff makes Lilita One the face for numbers, buttons, names and most titles, and Marcellus the older one.
- §21.8 (v36:10992) asks for "tabular numerals"; D90 measured that Lilita One has none. So the handoff's "numbers in Lilita One" breaks a rule wherever a number changes in place, which option B already moves to Manrope. That move departs from the owner's stated role, and the brief should say so.

Proposed: brief-amend D90: restate option B as "the owner's split (README.md:121-126): Lilita One for display numbers, buttons, names and most titles; Marcellus for titles on the older screens; Manrope for body, labels and every number that changes (the one change from the handoff, for §21.8's tabular figures)". Register-amend D90's body: "screen titles: Lilita One on 10-27, Marcellus on 01-09 and 22".

### H-9 (intent, medium). Screen transitions at about 0.3 s: longer than §21.8 and than the design's own

- README.md:148: "**Screen transitions:** about 0.3 s. The old screen fades and scales slightly down (`scale(.985)`)". SCREENS.md:177: "switch scenes with the 0.3 s fade-and-scale described in the README."
- v36:11010 (§21.8): "150 to 250 milliseconds, easing out".
- The design's own screen change is 160 ms to the swap, a 180 ms fade and a 240 ms scale (screens_main.js:102 `setTimeout(…,160)`, :187 `opacity .18s ease,transform .24s`). The README asks for longer than the design does.
- D91 (AR:8571) and its brief entry (brief:6672) treat screen changes as compliant ("screen changes (160 to 240 ms, :102, :187) and the 180 ms press comply"; option B "screen changes 160 to 240 ms and the press 180 ms, as now"). The owner's written spec moves screen changes into the non-compliant set.

Proposed: brief-amend D91: add "The handoff specifies 0.3 s screen transitions (README.md:148, SCREENS.md:177), above §21.8's 250 ms; under A or C they run at 250 ms at most, under B at 300 ms." TD.4 needs no change (its helper holds the document's timing).

### H-10 (spec, medium). The camera dive and the lateral slide have no task, and their reduced-motion form is unwritten

- README.md:149: "the camera dives toward the island with an ease-out over about 1.2 s, then the realm view's UI fades in. Moving between realms in the realm view uses a lateral camera slide, not a cut."
- The prototype's dive is 950 ms on an ease-in-out cubic (realm_diorama.js: `p=Math.min(1,(now-D.t0)/950)`, `e=p<.5?4*p*p*p:…`), so the handoff and its own prototype disagree.
- v36:10306 (§20.8): "Reduced-motion mode removes swoops"; v36:11010 (§21.8) times interface motion at 150-250 ms but says nothing of camera moves. D91 covers interface motion only.
- The roadmap names neither: TD.6 (RM:1370) keeps the world persistent "between screens" and TD.19 (RM:1827) builds home and the realm view, with no dive, slide or their reduced forms. The analysis proposed them (screens-home-realm-shell.md:82, :205 "dive (a cut under reduced motion)").

Proposed: roadmap-amend TD.19: "the dive from home into a realm (about 1.2 s, easing out, README.md:149) and the lateral slide between realms, each a cut under reduced motion (§20.8); a test that reduced motion moves the camera in one frame". Brief-amend D91's also_needed: "whether §21.8's 150-250 ms covers camera moves; the build's reading is that it does not, and reduced motion cuts them".

### H-11 (intent, high). Friends' presence and pings: the owner lists them as server data and must-shows; D86 recommends none

- README.md:168: "Server data the prototype fakes: matchmaking targets (Observatory), scout intel, friends' presence and feed, the defence log and season time remaining."
- SCREENS.md:171 (Friends): "Who's online, the friends' feed, friendly heists that take nothing (12.11), cosmetic gifts, preset pings, invites and add-by-code (17.6), block and report (17.8)". SCREENS.md:166 (Share sheet): "post the clip to the Beacon".
- v3.6's Friends row (§23.2): "Friends' feed, friendly heists, invitations, gifts". No section has presence or pings between friends (D86, AR:8193).
- D86's brief entry (brief:5667) recommends "none at launch, the document as written". The handoff is the owner's clearest statement so far that presence is wanted. It is not an answer, and §23.5 still builds nothing that changes what a player can see until it is written.

Proposed: brief-context D86: "The owner's handoff lists friends' presence as server data to build (README.md:168) and puts 'Who's online' and 'preset pings' on Friends (SCREENS.md:171). Intent, not an answer." Consider leading D86's options with "presence for 16 and over, pings for all" if the owner's intent is to be offered first; the recommendation stays the brief's to make. TD.64 (blocked on TD.60) is unchanged.

### H-12 (intent, medium). The handoff says to port `ruleborn-data.js` as "the single data source"; §23.5 says the module is not a source

- README.md:17: "`prototype/ruleborn-data.js` is generated from the GDD and is the single data source for laws, realms, links, landing spots, crew and Sages. Port it to Godot `Resource` files or JSON rather than retyping values."
- v36:11415-11416 (§23.5, adopted): "One data file for every screen | The prototype reads all its numbers from one module. The build does the same from this document's tables and 31.3's constants; the prototype's module is not a source". §23.5 also lists the module's role health as wrong (Breaker 260, Carrier 200, Mender 180 against 180, 160, 130), and C45 (AR:6996) shows it carries the old fee formula (data_v35.js:15).
- The owner's pattern (one data file, ported, not retyped) is what §23.5 adopts. The owner's source (this module) is what §23.5 rules out. The roadmap follows §23.5: TD.33 (RM:1537) builds the content the screens read from the document. Its gate does not say that nothing is copied from the module.

Proposed: roadmap-amend TD.33's gate: "no value is read or copied from the prototype's data module; a check compares the module's laws, realms, links, crew and Sages with content/ and lists every difference as a §23.5 row or a register item". Brief-context C45: the handoff's precedence names the module, not the document's tables.

### H-13 (intent, medium). "The GDD wins" names v3.4, the must-show list claims to be §23.2's, and the precedence leaves out recorded answers

- README.md:17: "Where the design and the GDD disagree, **the GDD wins** (`docs/ruleborn-game-design-v34.html`)". README.md:227: "`ruleborn-game-design-v34.html`: the GDD, which is the source of truth." SCREENS.md:3: "'Must show' is the content GDD 23.2 requires on the screen."
- The direction agrees with §23.5 (v36:11387). The version does not: the repository's source is v3.6, which rewrote §23.2's Heist result, Observatory, Rehearsal and defence log, Settings rows and added Profile and stats.
- SCREENS.md's must-show matches v3.6's §23.2 in 13 rows, is equivalent in 1 (Share sheet) and differs in 14 (05, 07, 08, 09, 13, 14, 15, 16, 17, 19, 19b, 23, 24, 27; table below). It matches v3.4's §23.2 no better (its Heist result and Observatory rows are v3.4's "Grade, loot kept…" and "Three to five universes, echoes marked, Renown, realms, loot estimate, trace"). §23.5's last table row already rules: "The designs' own notes | Their must-show lists … | 23.2 is the must-show list" (v36:11567).
- The precedence names the GDD and the design only. C45 (brief:4522) asks whether a recorded answer comes first. The handoff does not answer that, and must not be read as option B ("the document as written").

Proposed: brief-context C45: "The owner's handoff states 'the GDD wins' over the design (README.md:17) and is silent on recorded answers; it names v3.4, the version before the answers. It neither keeps nor reverses them." Analysis-correct: add this report's must-show table to docs/analysis/screens-v3 as the comparison of the handoff's list with §23.2, every difference mapped to its item.

### H-14 (spec, medium). The README's state model holds a mechanic v3.6 lacks and four values v3.6 contradicts

README.md:160-166, against v3.6:
- "Heist session: … stamina" (README.md:165). v3.6 has no stamina (no occurrence in v3.6). The analysis lists it under "Prototype behaviour not to port" (screens-heist-result.md:114). A state model that carries it invites building it; §23.5: "A design never adds a mechanic" (v36:11391).
- "Crew: … level and XP" (README.md:164). §23.5: "An XP bar … | Levels bought with Essence" (Character screen row).
- "state (idle, working, guarding, on a heist, resting, asleep)" (README.md:164). v36:5920: "at any moment is either working, guarding, resting, on a heist or idle". "Asleep" is not a state; "Wake" ends a rest (§11.3's table, v36:6176-6182).
- "Realms: … and stability. Strain bands are Quiet, Steady, Humming and Strained" (README.md:163). v36:841: "its effects come in seven bands" (Quiet, Steady, Humming, Brimming, Strained, Cracking, Breaking), and §23.5 (v36:11447): "Strain belongs to the universe". The design's own data has all seven (screens_main.js:90).
- "Player: resources (… Starglass)" (README.md:162). F41's recorded answer removes Starglass as a balance; F57 (AR:8162) holds the design's Starglass prices.

The roadmap's tasks follow v3.6 on each (TD.14 prices strain per universe; TD.17 refuses the design's added heist mechanics; TD.21 levels with Essence), but none names stamina or the extra state, and the client's store (TC.1) is where a ported state model would land.

Proposed: roadmap-amend TD.17: "no stamina (README.md:165; not in v3.6)". TD.21: "five crew states (§11.3); Wake ends a rest". TD.14: "strain and its seven bands are the universe's (§5.5, §23.5)".

### H-15 (spec, medium). Sound and haptics: the handoff names five UI cues; v3.6 asks for more, and no roadmap task builds any

- README.md:151: "`RBSfx.play(name)` with the names `tap`, `open`, `collect`, `place`, `error`. Map them to Godot `AudioStreamPlayer` sounds plus `Input.vibrate_handheld`."
- The prototype defines ten synthesised cues (realm_diorama.js `SFX.play`: tap, tick, select, collect, place, rotate, whoosh, error, pick, open), calls an eleventh that does not exist (`RBSfx.play('levelup')`, screens_meta.js), and vibrates with 13 durations and three patterns (`SFX.buzz([25,20,25])`, `[30,40,30]`, `[40,30,60]`).
- v36:11013 (§21.8 Haptics): "A light tap on buttons, a medium pulse on abilities and pylon breaks, a success pattern on escape, a warning pattern on alarm." v36:11016 (§21.8 Sound): six school signatures, an instrument per school, layered music, alarm percussion, three volumes. v36:11047 (§21.9): "Audio: realm ambiences, school stingers, effects, music tracks | 7, 6, about 150, 8". §20.8: "every alarm and cue has a visual and a haptic form".
- `Input.vibrate_handheld` takes one duration (and amplitude); §21.8's patterns need sequencing.
- The roadmap has no audio task: a search of RM for "sound", "audio", "music", "stinger" and "ambience" finds only TC.1's services container, the settings' three volumes (RM:917) and TD.13's "the heist's haptics and words" read from the event log. TC.4 counts "haptics and separate volumes" as done; the client's heist already pulses on alarm and on a ward or pylon falling (screens-heist-result.md, §1.7).

Proposed: roadmap-new "Sound and haptics on §21.8": one audio service with the design's UI cues as placeholders, §21.8's four haptic patterns as named sequences (tested), §20.8's rule that every alarm has a haptic and a visual form checked by a test, and §21.9's audio list as a counted manifest (to make or contractor's), so the audio budget is a tracked number like TD.7's art.

### H-16 (spec, medium). Which screens are 3D: the handoff's SubViewport list is short, and one viewport per screen conflicts with TD.6's persistent world

- SCREENS.md:178: "3D screens (01, 02, 04, 06, 09, 15, 21, 22, 23) put a `SubViewport` with the island scene behind the UI layer, so taps that miss the UI reach the 3D world." README.md:176: "Port it as one Godot scene per mode that shares an island generator."
- The prototype also mounts `<realm-diorama>` on 16 Rehearsal and defence log (mode scout, RulebornMeta.dc.html:247) and twice on 20 First launch (universe at :441, realm at :461). v3.6 needs the world on three more: 07's "decisive moment with a three-second replay" (§23.2), 26's clip re-rendered from the replay and 18's "previews on your universe" (TD.46, RM, and TD.17).
- TD.6 (RM:1370): "The shell keeps the World, the content, the chrome … and the overlay", so the world survives the dive (H-10). A SubViewport per screen, or a scene per mode, rebuilds the world on every navigation.

Proposed: roadmap-amend TD.6: "one World under the shell, in a SubViewport behind the content, switched by mode (universe, plan, realm, heist, scout) rather than rebuilt; taps the UI does not take pass to it; it serves 01, 02, 04, 06, 07, 09, 15, 16, 18 (preview), 20, 21, 22, 23 and 26 (clip)". TD.10: "the island generator is shared by every mode".

### H-17 (spec, low). The nav bar's route groups and the two hubs are in no task

- SCREENS.md:5: "**Islands** → 01 … **Laws** → 13 … **Heist** → 08 … **Crew** → 10 … **Friends** → 27. The Crew tab hosts a hub with Roster · Sages · Forms, and the Laws tab a hub with All laws · Harmony · Lab, shown as a gold segmented control under the header." The prototype also marks a tab active for a group of routes (screens_main.js:665: Islands for home, realm, weave, terrain, workshop, curation, rehearsal; Heist for observatory, scout, planner, landing; Friends for friends and share).
- v3.6 is silent on hubs and tab grouping (adopted under §23.5). C44 (AR:6869) holds the hub tabs' size ("Hub tabs are 36 px"), not their existence.
- TD.6 (RM:1370) lists "top HUD, side alerts, tab bar, back header", with no hubs or route groups. TD.3 (RM:1310) lists "Gold, leather, red, green and round buttons, sheets, chips, portrait tiles, banners and cards", without the handoff's violet secondary button, segmented control or pill (SCREENS.md:179).

Proposed: roadmap-amend TD.6: "the tab-to-route groups and the Crew and Laws hubs as a segmented control, each segment 48 points (C44)". TD.3: add the violet button, the segmented control and the pill.

### H-18 (spec, low). The README names three link kinds; v3.6 and the prototype have four

- README.md:179: "three kinds connect the realms to the Heart and to each other: stone bridges, rope bridges and chutes (`ULINKS`)."
- v36: §5.3's table has Stone bridge, Rope bridge, Chute and Rift (v36:802 "Rift"). The prototype's `ULINKS` includes `['heart','verdant','rift']` (realm_diorama.js), and the analysis found all four link models (3d-pipeline.md:63; G61 "the four links are complete").

Proposed: roadmap-amend TD.19: "the four links of §5.3, the Rift included, with its 30-second closing drawn".

### H-19 (spec, low). Staged loading is not in the 3D tasks

- README.md:152: "3D content shows a spinner until it is ready. Characters stream in one at a time so the UI never freezes; keep this staging in Godot by instancing scenes across frames."
- v3.6 §24 sets "60 frames a second is a floor" and a 25 ms drag budget; §21.3 sets frame budgets (C52 holds the dispute). TD.7 (RM:1393) and TD.10 (RM:1455) say nothing of load staging.

Proposed: roadmap-amend TD.10: "models load on a worker thread and are instanced a few per frame, with a loading state, so no frame on the reference device misses C52's floor while a view fills".

### H-20 (spec, low). Autoload singletons against TC.1's architecture

- README.md:161: "a Godot version would use a few autoload singletons."
- TC.1 (RM:955, done): "Services … built in one container at start, so tests run with fakes and nothing reaches a global." The handoff's pattern would undo it. design-system.md §10 proposed a `Motion` autoload, which TD.4 replaced with a helper.

Proposed: no change to TC.1; note in TD.6 that the shell's state lives in TC.1's store, not in autoloads.

### H-21 (intent, low). "No jellyfish" is the universe background; Skyfield's jellyfish stay

- README.md:181: "**Universe background:** animated and alive, with stars, drifting planets and motes. It has no compass, no jellyfish and no kites; the user asked for these to be removed."
- v36: §5.7's Skyfield row is "Sky-drifting jellyfish" (v36:1010), and §23.5 adopts "Jellyfish drift with the wind under Current" (v36:11413). CHARACTERS.md:74 keeps them as Skyfield's wildlife (`skyjelly.js`).
- The diorama draws no wildlife in any realm (no moth, beetle, lanternfish or firefly in realm-diorama.js; v36-rules.md:16 "Wildlife cues: no wildlife anywhere"). A porter reading "no jellyfish" could drop Skyfield's too.

Proposed: roadmap-amend TD.32 (or TD.10): "wildlife is drawn in its realm as §5.7 lists it; the owner's removal of jellyfish, kites and the compass applies to the universe map's background only".

## SCREENS.md "Must show" against v3.6 §23.2

"Same" means the same content. Each difference names the item that holds it.

| # | SCREENS.md says (line) | v3.6 §23.2 says | Difference | Held by |
|---|---|---|---|---|
| 01 | Realms with their laws, links, strain band, faults, alerts, resources, heist button (:11) | same | none | — |
| 02 | At most eight controls, clock, alarm meter, vision cones, loot, Vault progress (:18) | same, with "(12.7)" | none | — |
| 03 | Icon with school shape, one-line rule, looping preview, rank, pages (:24) | same | none | — |
| 04 | Grid, terrain and budget, buildings, workers, pylons, wards, guard posts (:30) | same | none | — |
| 05 | One big law card with its looping preview, cost, strain and ready time; the realm tapestry; harmonies and clashes with woven laws; a deck (:36) | Two or three recommended laws, stability bar with its seven bands, and the harmonies and clashes a law would cause before it's woven | drops recommended laws and the seven-band bar; adds card, tapestry, deck | §23.5 Weaving row; D81 (preview row); TD.20 |
| 06 | Entry, route, crew, Sage, casts, clock, unfamiliar laws flagged (:42) | same | none (interaction "without a Carrier you cannot launch" is D78's Carrier row) | D78 |
| 07 | outcome and multipliers; decisive moment with a 3-second replay; Starlight, Essence and Renown; entry fee; law to study; rest; worth your time (:48) | …the decisive moment with a three-second replay and one thing to try (12.13), loot kept, the entry fee… | drops "one thing to try"; fee without the Trace exception | G48; §23.5 Trace row; TD.17 |
| 08 | Name, Keeper level, realms, Renown and rough loot only; depth and why offered; Trace and echo marks; entry fee; drifting ruins apart (:54) | Three to five universes … ruins apart, at three labelled difficulties (12.12) | drops "three to five" and the ruins' three labelled difficulties; free facts = §12.4 (agree) | C46; D78 (ruins row); TD.18 |
| 09 | Per realm: sky banner with guard and ward counts, law cards with previews and known/new tags, guards by role with patrol notes, wards by type, crew matchups (:61) | Realm-by-realm law cards, guards by role, ward counts, matchups | adds patrol notes (§12.12: patrols are learned in the heist) | D77; TD.18 |
| 10 | Every character's state, rest timers, one-tap reassign (:67) | same | none ("Level up glows green when XP is full" is §23.5's Character row) | §23.5 |
| 11 | School, role, ability, traits, level, best work (:75) | same | none | — |
| 12 | Powers, levels, guardian choice (:80) | same | none | — |
| 13 | Launch 24 laws by school and rank, chapters, "?" for unknown, resonances, mastery (:86) | …growing toward 48 by season, opening in chapters (7.6), "?" for unknown laws, resonances found, mastery | drops "growing toward 48"; "resonances found" becomes "resonances"; title "Law collection" against §23.2's "Law Codex" | §23.5 Codex row; G49; screens-weave-law-codex-harmony.md:361; TD.44 |
| 14 | Test realm with two pedestals, settle time as the clue, all 12 resonances shown as locked cards, found cards fly to the shelf (:93); job "Watch two laws meet" | Two law slots, timer, result, hints, paradox warning; job "Run experiments" | drops hints (replaced by the design's clue) and the paradox warning; adds twelve locked cards | G53; D83 (resonances row); G49; screens-lab-curation-rehearsal-terrain-workshop.md:84 (warning unreachable); TD.22, TD.65 |
| 15 | Real Heart island in 3D: hold gauge against the fair band, sneak routes, one guard cone at a time, ghost test run; layout, laws, posts and word-list name (:99) | generated layout and its alternatives; swap a law, move a post, pick another layout, name it; change this one law with a fast preview | drops alternatives, the swap and move verbs and the fast re-generating preview; adds hold gauge, routes, ghost run | G55; G54; D83 (sight row: the screen draws every cone); analysis lab:178 (verbs drawn); TD.22, TD.65 |
| 16 | Simulated crew choice, route replay, raids on you, trace (:104) | …raids on you, each with its report (the haul denied, how long the defence held, where the crew was seen, what fired; 13.2), Trace | drops the per-raid report | G57; TD.66 |
| 17 | Starpass track with free and premium lanes, claim reveals, daily/weekly/era quests that fill the pass, league road (:109) | League, track, era, weekly streak | drops the week's era and the weekly streak; adds quests | D84; D85 (era row); TD.23, TD.40 |
| 18 | Sets with real prices, previews on your universe, spending cap for minors (:114) | same | none | — |
| 19 | Reminder time, play-time reminders, notifications, accessibility, languages (:119) | same; any protection the age band fixes is shown locked (20.2) | drops "shown locked" | §23.5 Locked protections row; TD.25 |
| 19b | League and rating trend, heist and defence split, records, battle log with replays, collection and badges (:124) | Renown and league over time, never the internal rating (12.15); heists by outcome; defences held and leaked; records; battle log; collection and badges. Private, with no sharing, for 13 to 15 | asks for a rating trend; drops outcomes, held and leaked, and 13-15 privacy | §23.5 Profile header row; G69; D85; TD.24 |
| 20 | Age band check, then the moments in section 16 (:130) | same | none | — |
| 21 | 39 features by family, terrain points left, route check, live guard-sight preview (:135) | same | none | — |
| 22 | Every outer realm's edge, what guards would hear, the heist clock for each choice (:140) | same | none | — |
| 23 | Notes on every law, harmonies and clashes per realm, resonances and chords (:146) | …discovered resonances and chords | drops "discovered" | G49; screens-weave-law-codex-harmony.md (finding 7) |
| 24 | Creator ladder (18.7), publishing checks, fun / clever / fair ratings, completions, weekly spotlight (18.6) (:153) | Sandbox tools, playtest button, publishing checks, ratings and spotlights | drops sandbox tools and the playtest button | screens-lab-curation-rehearsal-terrain-workshop.md:434 (sandbox tools not drawn); TD.22's gate |
| 25 | 54 forms by kind and note, how to hatch each, trades (:159) | same | none | — |
| 26 | game-cut 15-second clip with laws labelled, your island as a challenge, the matching-cosmetic invite (17.6), age-band limits (20.7) (:165) | The 15-second clip, challenge link, invite gift, age-band limits | equivalent (§17.6's words); "post the clip to the Beacon" is D86's | D86; TD.23, TD.46 |
| 27 | Who's online, feed, friendly heists that take nothing (12.11), cosmetic gifts, preset pings, invites and add-by-code (17.6), block and report (17.8) (:171) | Friends' feed, friendly heists, invitations, gifts | adds presence and pings (D86); add-by-code (silent: adopted); block and report (§20.4) | D86 (H-11); C50 (Open Vault exception to "take nothing"); TD.23, TD.64 |

Totals: 13 same, 1 equivalent, 14 differ. Every difference is already held; H-13 asks that the table be recorded.

## Coverage: README.md

| Line | Statement | v3.6 | Status |
|---|---|---|---|
| 4 | Portrait strategy game; realms, laws, heists | agrees (§1, §23.3 portrait default) | covered: nothing to do |
| 7 | 28 screens in one 390 × 844 frame | §23.2 has 28 rows | covered (frame: H-5) |
| 8 | 43 character pages | §23.5 "43 character and creature sheets" | covered (CHARACTERS part; G61, TD.7) |
| 9 | Icon set of 31 groups | §23.5 counts 393 icons; RBI holds 360 in 31 groups | covered by TD.5 (four sources, 444 SVGs) |
| 10 | GDD v3.4 and the review brief, which the screens follow | repository has v3.6 | new finding H-13 |
| 12 | Target engine Godot 4.7.2 | agrees (§24, v36:11643) | covered by D76, TD.1 |
| 15 | HTML is a reference; rebuild with Control nodes, Themes, Node3D | agrees with §23.5 ("visual reference") | covered by TC.1, TD.3, TD.10 |
| 17 | GDD wins (v3.4) | direction agrees with §23.5; version stale | new finding H-13 |
| 17 | ruleborn-data.js is the single data source; port it | contradicts §23.5 (v36:11416) | new finding H-12 |
| 20 | UI final, pixel-accurate | §23.5 wins on numbers and words | new finding H-1 |
| 20 | 390 × 844 scaled to the device | breaks §21.8's 13 pt, §21.1's 48 pt on 360-dp phones | new finding H-5 |
| 20 | Landscape is not supported | contradicts §23.3 | new findings H-3, H-4 |
| 22 | 3D high fidelity for composition, camera, palette, scale, motion | camera contradicts §21.1; palette D92; scale D93 | new finding H-2 |
| 22 | Meshes generated at runtime; export or rebuild in Blender | §21.9; §26.8 | covered by G61, TD.7 |
| 24-29 | How to run; Tweaks (heistOutcome, leftHanded, ageBand 18+ / 13–15); data-screen-label | prototype only; ageBand omits 16–17 (§20.2) | covered: D87 and TD.25 build all three bands |
| 34-63 | Screen table (28 rows, file per screen) | §23.2 rows; "Law collection" vs "Law Codex" | covered (table above) |
| 65 | Root mounts RulebornMeta with screen, go, tabs, openLaw, ageBand | prototype only | covered: nothing to port |
| 68 | Canvas 390 × 844; status bar 0–48 pt | §21.1 safe areas | covered by C44 (safe areas), H-5 (frame) |
| 69 | Header at 50 pt; 40 × 40 back button top left; titles Lilita One 26 or Marcellus 26; currency pill | §21.1 corners and 48 pt; §21.8 type | covered by C44 (the prototype's back button is 44 px, screens_meta.markup.html:248, not the 40 stated); type: H-8 |
| 70 | Nav bar 92 pt, five tabs, Heist raised in the centre, violet gradient, gold rim | §21.8 home layout puts a skiff Heist button bottom right; §23.1 five tabs | covered by C44 |
| 71-72 | Selected and unselected tab looks | silent: adopted | covered: nothing to do (unselected label 10 px is §23.5's Text size row) |
| 73 | No dashed or ray patterns, removed at the user's request | silent: adopted | covered: nothing to do |
| 74 | Scroll areas; no sideways page scroll; only carousels | silent: adopted | covered: nothing to do |
| 75 | Tap targets 48 pt (12.7); eight controls in a heist | agrees (v36:7008) | covered by C44, TD.17's eight-control test |
| 80-81 | #1A0C14 outlines; #0A0408 / #0A0618 drops | §21.2 ink #221C3A | covered by D89, D92 (also_needed: outline ink) |
| 84-87 | Night surfaces and hero cards | §21.8 paper panels | covered by D89 |
| 89-92 | Gold button, selected segment, gold accents | §21.8 "gold for main actions" agrees | covered by D89, TD.3 |
| 94-97 | Cream cards, rim, text colours | §21.8 paper and ink | covered by D89; label #8A5A1C on #EAD7AE is 4.17:1, G59 |
| 99-100 | Violet secondary button | silent | covered by D89; component gap H-17 |
| 102-103 | Text on dark | silent | covered by D89, G59 |
| 105-106 | Status colours | red and green agree with §21.8; success #2FA868 2.98:1 and warning #F2C45C 1.61:1 on cream | covered by D72, F58, G59 |
| 108-114 | Six schools, four stops each | base agrees; dark stop is not §21.2's shadow | new finding H-7 |
| 116-117 | Eight note colours | §21.2 binds notes to §8.1's wheel | new finding H-6 |
| 120 | Three Google fonts, bundled as TTF | §21.8, §21.11 name Baloo 2 and Marcellus | covered by D90, TD.2 |
| 121 | Lilita One for numbers, buttons, names, card titles; sizes 13–26 | no tabular figures (§21.8) | new finding H-8 |
| 122 | Marcellus for titles on some screens | §21.8 "Marcellus for titles and law names" | new finding H-8 |
| 123-126 | Manrope 500–900; body 12–12.5; labels 9.5; metadata 10–11 | §21.8 16 pt body, 13 pt floor; Manrope has no 900 | covered by §23.5 Text size row, D90 (900 draws at 800), TD.2 |
| 127 | Text shadow 0 2px 0 #1A0C14 | silent | covered: adopted (TD.3) |
| 129-134 | Radii | silent | covered: adopted (design-system.md §4.1, TD.2) |
| 136-141 | Hard offset shadows; soft on floating cards; press translates 2–3 pt | §21.8 "buttons squash slightly" | covered by TD.3 (press with squash, design-system.md §10.3) |
| 143-144 | Spacing scale, insets, gaps | silent | covered: adopted (TD.2) |
| 147 | Every screen reachable from the nav bar, HUD or one action; Back returns | silent | covered by TD.6 |
| 148 | Transitions about 0.3 s, fade and scale .985 | §21.8 150–250 ms | new finding H-9 |
| 149 | Camera dive about 1.2 s; lateral slide between realms | §20.8 reduced motion removes swoops | new finding H-10 |
| 150 | Toasts hide after about 2 s | §20.8 banners stay if the player chooses | covered by D91 (toasts row), TD.4 |
| 151 | RBSfx names and haptics | §21.8 haptics and sound; §21.9 audio | new finding H-15 |
| 152 | Spinner; characters stream in across frames | §24 60 fps floor | new finding H-19 |
| 154 | Age band: shop spending limits | agrees (§20.2 €25 / €50 caps; adult summary) | covered by D85, D87, TD.23 |
| 155 | Challenge links to in-game friends only for 13–15 | agrees (§20.7) | covered by TD.23 |
| 156 | Gifting needs a parent's approval for minors | §22.4 "parental approval rules for minors", unwritten | covered by F57 (gift flow), G58 |
| 157 | Play-time reminders locked on for 13–15 | agrees (§20.2 every 60 minutes) | covered by G58 (16–17), TD.25 |
| 158 | Age check sends each band down its own first-session path (GDD 20.7) | §20.7 is creation and sharing; §23.5 adopts one order with a band summary | covered by §23.5 first-launch row, D87, TD.26 (citation is wrong; nothing to build) |
| (absent) | Night notifications, profile privacy, chat, clip sharing, Workshop browsing, co-op limits by band | §20.2, §20.7 | covered by TD.25, TD.23, TD.46, TD.24; the README's list is partial |
| 160-161 | State in two component classes; Godot would use autoloads | TC.1: no globals | new finding H-20 |
| 162 | Player resources incl. Starglass; Keeper level, Renown, league, age band | F41's answer: no Starglass | new finding H-14 (covered by F57) |
| 163 | Realm slots, buildings on grid, terrain, posts, wards, stability; four strain bands | §5.5 seven bands; strain is the universe's | new finding H-14 (grid: G45, TD.36) |
| 164 | Crew states incl. asleep; rest timer; level and XP; form; traits | §11.3 five states; no XP | new finding H-14 |
| 165 | Heist: positions, gait, stamina, HP, suspicion 0–1,000, alarm, loot, clock, charges, outcome | no stamina; the rest agree (v36:825, §12.6) | new finding H-14 |
| 166 | Collections: laws and mastery, resonances (12), forms (54), season, purchases, friends | agrees (§8.4 launch 12; §11.10 54) | covered (G49 for mastery) |
| 168 | Server data the prototype fakes | §24 server authoritative | targets, scout: D77, F46, TD.18; presence: new finding H-11; defence log: TD.66; season time: TD.23 |
| 171-174 | One `<realm-diorama>`, modes universe, plan, realm, heist, scout; attributes; CustomEvent | prototype only | covered by TD.10 (a still per mode) |
| 176 | One Godot scene per mode sharing an island generator | TD.6 keeps one World | new finding H-16 |
| 177 | Islands: rock, grass cap, terrain, buildings on a grid with footprints, wildlife, iceberg ground | §5.2 square grid 10–14; §10 footprints; §5.7 wildlife | covered by D75 (grid row), G45, TD.36; wildlife H-21 |
| 178 | Camera: high three-quarter; pinch and twist; no zoom buttons | §21.1, §20.8 | new finding H-2 (extends D75) |
| 179 | Three link kinds (ULINKS) | §5.3 four kinds | new finding H-18 |
| 180 | Only raid skiffs fly, along links or to a landing edge | silent (§5.4: skiffs land on any outer edge, never the Heart) | covered: adopted; nothing to do |
| 181 | Universe background: stars, planets, motes; no compass, jellyfish or kites (user's request) | §21.2 sky by local time; §5.7 Skyfield jellyfish | sky: covered by D91 (sky row); jellyfish scope: new finding H-21; compass and kites: silent, adopted |
| 184-188 | Character modules: build, makeRig, CLIPS, EXPR; Tidewalker's nine clips | §21.6 fifteen animations | covered by C54, TD.7 (the module also carries the kit's fourteen standard clips, 3d-pipeline.md:108) |
| 190 | Four heavy characters ship .bin | — | outside this part (characters part); covered by G61, TD.7 |
| 192-196 | Export path: build, sample at 30 fps, .glb, AnimationPlayer | §21.9 | covered by TD.7 (proved on Featherkin) |
| 199-206 | Icons: 31 groups, RBI data URLs, export SVG or raster 128 / 256 | §21.8 flat icons | covered by TD.5, D91 |
| 209 | world/ renders usable as is | §21.3 look (D92: portraits are renders of the physical look) | covered by D92, TD.11 (portraits re-rendered) |
| 210 | Fonts under the OFL | §21.11 open font licence | covered by D90, TD.2 (ledger) |
| 211-212 | three.js r184 and React 18.3.1 | prototype only | covered: nothing to port |
| 215-224 | File list | — | covered: informational |
| 226-228 | docs: GDD v3.4 is the source of truth; review brief | v3.6 is | new finding H-13 |
| 233 | Open item: theft is one-way, Trace shown | agrees (v36:7513, §12.3) | covered; Open Vault exception is C50 |
| 234 | Open item: the GDD's terms for rating, XP, power, builders, stolen, revenge | §12.15, §11.4, §10 | covered by §23.5 Profile and Character rows, D73 (builders), D85 |
| 235 | Open item: demo player Keeper 24, adult, 5 realms, crew of 5 | agrees (§5.2 five outer realms by Keeper 21; crew of 5 from Keeper 16) | covered (D75 for realm levels); "5 realms" means five outer realms |
| 236 | Open item: small fixes on 04, 10, 11, 12, 14, 15, 21, 24, 25, 27; school shapes on every law icon | §5.2 shapes | covered by the review part; D91, TD.5 (Matter's cube) |
| 238 | Open item: all text at least 13 pt | §21.8 also asks 16 pt body | covered by §23.5 Text size row, TD.2 |
| 239 | Open item: tap targets at least 44 pt (48 per 12.7) | §21.1, §12.7 48 pt | covered by C44 |

## Coverage: SCREENS.md

| Line | Statement | v3.6 | Status |
|---|---|---|---|
| 3 | "Must show" is GDD 23.2's | 14 rows differ | new finding H-13 (table above) |
| 5 | Tabs: Islands → 01, Laws → 13, Heist → 08, Crew → 10, Friends → 27 | §21.8 home layout; §23.1 five tabs | covered by C44; route groups: new finding H-17 |
| 5 | Crew hub Roster · Sages · Forms; Laws hub All laws · Harmony · Lab, gold segmented control | silent: adopted | new finding H-17 (size: C44) |
| 7 | Heist loop 01 → 08 → 09 → 06 → 22 → 02 → 07 | silent | covered by TD.18, TD.41 |
| 9-14 | 01 purpose, must-show, interactions, tab | agrees | covered (table; laws on home: D75 crown row) |
| 16-20 | 02 heist interactions: send, pair, hold for gait, ability two uses 10 s apart, down 10 s, revive 3 s, skiff 20 s at the Heart | agrees with v36:6871, 7401, 828 | covered by G47 (orders), TD.17 |
| 22-26 | 03 law card | agrees | covered by §23.5 Law card row, TD.20 |
| 28-32 | 04 realm view; pinch and twist | §20.8 | covered by D75; H-2 |
| 34-38 | 05 weaving; swipe up or hold to weave | §20.8 no drag without a two-tap path | covered by D81 (weave button row), TD.20 |
| 40-44 | 06 planner; landing cards; Carrier required | §12.5 | covered by D78, TD.18 |
| 46-50 | 07 result; Tweaks outcome; pick the law to study | §23.2 | covered (table), TD.17 |
| 52-57 | 08 Observatory; refresh 50 Aether doubling in the hour | agrees (v36:6924) | covered by C46, D78, TD.18 |
| 59-63 | 09 scout; Plan lands you at that realm | §5.4 no landing on the Heart | covered by D77, §23.5 Scout row |
| 65-71 | 10 Roster; Assign, Recall, Wake; Level up with XP; sort; silhouettes | §11.3, §11.4 | covered by D82, §23.5 Character row, TD.21 |
| 73-76 | 11 Character | agrees | covered by §23.5, D94, TD.21 |
| 78-82 | 12 Sage hall | agrees | covered by G52, TD.21 |
| 84-89 | 13 Law collection | differs | covered (table) |
| 91-95 | 14 Resonance Lab | differs | covered (table) |
| 97-100 | 15 Defence curation | differs | covered (table) |
| 102-105 | 16 Rehearsal and defence log | differs | covered (table) |
| 107-110 | 17 Season | differs | covered (table) |
| 112-115 | 18 Shop | agrees | covered by D85, F57, TD.23, TD.46 |
| 117-120 | 19 Settings | differs | covered (table) |
| 122-126 | 19b Profile; reached from the portrait or the star | differs | covered (table) |
| 128-131 | 20 First launch | agrees | covered by §23.5 first-launch order, D87, C51, TD.26 |
| 133-136 | 21 Terrain editor | agrees | covered by D83, G56, TD.22 |
| 138-142 | 22 Landing picker; tap or swipe cards | §5.4 any edge tile | covered by D78, TD.41 |
| 144-149 | 23 Harmony; first-time reveal; Tidehold chord; Verdant and Lantern Vale clash | §8; §21.7 | covered (table); D81 (threads row), TD.44 |
| 151-155 | 24 Workshop; name from word lists, then Publish | §18.6, §20.7, C43's answer | covered (table); D83, TD.22 |
| 157-161 | 25 Forms album | agrees | covered by D82, TD.45 |
| 163-167 | 26 Share sheet; three best moments; post to the Beacon | §17.6, §20.7 | covered (table); D86, TD.46 |
| 169-174 | 27 Friends; tap a friend; raid back from the rematch card; add by code | §12.11, §17.6, §20.4 | covered (table); H-11, D86, TD.23 |
| 177 | Scene per screen under one Control root keeping the nav bar; 0.3 s fade-and-scale | TD.6 shell; §21.8 timing | covered by TD.6; timing: new finding H-9 |
| 178 | SubViewport for 01, 02, 04, 06, 09, 15, 21, 22, 23 | prototype adds 16, 20; v3.6 needs 07, 18, 26 | new finding H-16 |
| 179 | Reusable scenes with a shared Theme: gold button, violet button, cream card, dark card, segmented tabs, pill | silent | covered by TC.1, TD.3; missing components: new finding H-17 |
