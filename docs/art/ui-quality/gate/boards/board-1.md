# Board 1: the kit and the heist

Posted by AD, P1-AD-board-1, 11 November 2026, on main at `d880807e`
(P1-S1-pilot-2 merged). This is O4's first family board (section 3.4 and step
7 of `../../report.md`). It holds nine items, each shown beside its golden
reference at phone size, with the gate's verdicts. AD checks every
owner-checked quality (`../calibration.md`: 1, 2, 3, 6, 8, 9, 13 and 14) and,
because this is board 1, quality 4 (press feedback) from a frame pair.

**Round 2 (P1-AD-board-1b, 12 November 2026, on main at `085c812a`): the
board still does not stand.** C and E are closed. A stays open until the
kit's numerals are switched on (P1-K1-numerals-on). B is narrowed to one
case: a heist with no crew plan, at 200% text in pt_BR, where the crew tray
covers the load bar. D is narrowed to Hollow's body against its own disc,
and Bramble's grain. See "Round 2" at the end of this page. Round 1 is kept below as it was posted.

**Round 1 decision: the board does not stand.** Five objections are open (listed in
"Objections" below). Four are against the pilot heist and one against its
200% Portuguese layout. The kit and icon batches 1–2 stand on AD's check. Phase
2 waits for this board (section 3.8 of the report), so the objections go to
the lead as requests in `docs/progress/status/AD.json`, each with a default.

## How to read it

- **Golden reference.** For screens this is the heist key frame that AD
  approved in place of the owner (`../approvals/O2.md`), at
  `art/ui/keyframes/02-heist*.png`. For the kit and the icons it is the style
  board, `art/ui/board/board.png`. The rubric's pass and fail anchors
  (`../rubric.md`) are the bar for each quality.
- **Candidate.** The screens are S1's committed stills on main,
  `docs/art/shots/heist-pilot/after-*.png` (P1-S1-pilot-2). AD re-rendered
  the same five shots on main's integrated head (`tools/render/shoot.sh
  client/tests/shots/screen_heist.gd`, with `MOMENT`, `TEXT`, `CONTRAST` and
  `LOCALE`). They match S1's stills except where something animates: the
  mean difference is 0.25–0.51 levels, and 0.6–1.2% of pixels differ by more
  than 16. So S1's stills stand for the integrated build.
- **Images.** All are made with `tools/ui_gate/sheet.py` and are in
  [`board-1/`](board-1/). A strip puts the reference on the left (frame 0)
  and the candidate on the right, at the same height.
- **Verdicts** come from `../verdicts/<task>/<sha>.json`. Each result is
  written as pass, fail or unknown, with the votes in order. All of them are
  advice only, because every judged quality is owner-checked
  (`../calibration.md`).
- **AD's check** is written as stands, note or **objection**. A note is
  recorded for the next round and blocks nothing. An objection holds the
  board.

## The items

### 1. Heist at 100% text

![Heist at 100%, key frame and build](board-1/1-heist-100.png)

Grayscale squint: [`1-heist-100-gray.png`](board-1/1-heist-100-gray.png).
Colour-vision sheet: [`1-heist-100-cvd.png`](board-1/1-heist-100-cvd.png).

Gate: `P1-S1-pilot-1/5470c4d3`, the 100% shot, before pilot-2's rework.
- Materials: pass (ppp).
- Display type: fail (fff).
- Icons: pass (pfpppp).
- Hierarchy: fail (fff).
- Colour: fail (ffppff).
- Character: fail (fff).
- Light: pass (ppp).
- One idea: fail (fff).

Pilot-2 (`a4d87d18`) reworked hierarchy and colour, and was judged in high
contrast and at 200% only.

| Quality | AD's check |
|---|---|
| 1 Materials | Stands. The panels, law chips, Cast and Get out carry a top-lit gradient, an inked rim and a lip. |
| 2 Display type | **Objection A.** The timer "2:25" is flat dark figures on a cream pill, with no ink outline, hard drop or gradient fill: the rubric's fail anchor. The key frame's timer is an inked, outlined display figure. The crew names (Pip, Mo, Bramble, Hollow, Ash) carry a thin plum ink outline and hold over the world; at 4× zoom it is about 2 px, lighter than the kit's GET OUT outline, but it reads. "Laws here" is gold on the plain night sky with no outline; it reads there, so it is a note, not part of the objection. |
| 3 Icons | Stands. The law and action icons are the rebaked toon icons. Bloom is the weakest but still reads. |
| 6 Hierarchy | Stands after pilot-2. In grayscale the gold Cast is now the lightest and largest control. Get out is leather and smaller. The two-line hint bar is the heaviest dark mass after the panels, which is noted under objection C. |
| 8 Colour | Stands after pilot-2. Gold fill is on Cast only, red is gone from Get out, and the school marks are shapes. On the CVD sheet, the crew rings still differ by hue, but each also has a name and a portrait, so no information is carried by colour alone. |
| 9 Character | **Objection D.** Hollow's dark purple body merges with its purple ring at phone size. Bramble is low in contrast against its ring. |
| 13 Light | Note. There is one top light on every piece. The night scene is much darker than the key frame's lit island. That suits a sneak at night, but the world reads as a backdrop rather than a stage. |
| 14 One idea | **Objection C.** There is no crew tray. The portraits float on the world, while the key frame seats them on a bottom panel with cards and pips. Ash wraps alone onto a second row even at 100%. The flat hint bar and the thin load bar read as generic chrome beside the inked kit. |

### 2. Heist at 200% text, English

![Heist at 200%, key frame and build](board-1/2-heist-200.png)

Gate: `P1-S1-pilot-2/a4d87d18`.
- Display type: fail (fff).
- Hierarchy: pass (ppp).

The rest is from `P1-S1-pilot-1/5470c4d3` at 200%.
- Materials: fail (pffpff).
- Icons: fail (fff).
- Colour: fail (fff).
- Character: fail (fff).
- Light: pass (ppfppp).
- One idea: pass (ffpfpp).

| Quality | AD's check |
|---|---|
| 1 Materials | Stands after pilot-2. The Room panel carries a rim and a lip; no hint card shows at 200%. |
| 2 Display type | **Objection A**, the same as item 1: the flat timer. The names keep their thin ink outline at 200%. |
| 3 Icons | Stands. The Cast and Get out icons are back at 200%. |
| 6 Hierarchy | Stands, with a note. Cast leads. The loot panel and the law chips together take much of the top half. That is acceptable at 200%, but it should be measured against the HUD share in `../rubric.md` when the screen class checks it. |
| 8 Colour | Stands, as item 1. |
| 9 Character | **Objection D**, as item 1. |
| 13 Light | Stands, as item 1. |
| 14 One idea | **Objection C**, as item 1. |

### 3. Heist at 200% text, Portuguese (Brazil)

![Heist at 200% pt_BR, key frame and build](board-1/3-heist-200-pt.png)

Gate: this shot was not judged on its own (pilot-2's 200% shot is English).

| Quality | AD's check |
|---|---|
| 2 Display type, layout | **Objection B, a hard defect.** "Carregar até 80%" spills out of the loot panel and overlaps Pip's portrait in the crew row. The guard's bubble "Quem está aí?" is clipped behind the panel. A string that leaves its panel fails §20.8's text scaling, whatever the quality scores. |
| 1, 3, 6, 8, 9, 13, 14 | As item 2. |

### 4. Heist in high contrast, at 100% and 200%

![High contrast: key frame, build at 100%, build at 200%](board-1/4-heist-hc.png)

Gate: `P1-S1-pilot-2/a4d87d18`, high contrast.
- Hierarchy: pass (ppp).
- Colour: pass (ppp).

| Quality | AD's check |
|---|---|
| 1 Materials | Stands. Solid plum panels with inked rims, the high-contrast form on the style board. |
| 2 Display type | **Objection A** for the timer at 200%, as the judge found. The labels sit on solid fills in high contrast, so their missing outline matters less here. |
| 3 Icons | Stands. |
| 6 Hierarchy | Stands. Gold Cast leads in colour and in grayscale. |
| 8 Colour | Stands. |
| 9 Character | Stands. The high-contrast rings separate Hollow better, but objection D still holds in the normal mode. |
| 13 Light | Stands. |
| 14 One idea | **Objection C** (the crew tray), as item 1. |

### 5. Icons: heist controls (batch 1a)

![Heist control icons at 48 and 96 pt and in grayscale](board-1/5-icons-heistcontrols.png)

Reference: the style board's hero icons (`art/ui/board/board.png`, the
outline and glint rules).

Gate: `P1-AIA2-icons-1a/c1d14d38` (and `5f759a03`).
- Materials: fail (fff).
- Icons: fail (fff).
- Colour: fail (fff).
- Light: pass (ppp).

These verdicts are on the first bake. The eight icons were rebaked after
it, with a softer toon ramp, a gloss band and a body gradient (`bef6eac2`,
`5ae7dbd5`). The sheet above is from main's current
`client/ui/art/icons_48.webp`.

| Quality | AD's check |
|---|---|
| 1 Materials | Stands. The current bake has a top-lit gradient, a gloss band, a dark outline and a soft drop on every icon. |
| 3 Icons | Stands. They are modelled toon objects with a top-left key light, glints and a 2 pt outline. Every silhouette reads at 48 pt and in grayscale. |
| 8 Colour | Note for the next round (AIA-2). The sagewheel's six wedges differ by hue alone and merge in grayscale. The wedges are decoration, not information, so this does not hold the board. The aim reticle's red and the get-out arrow's green borrow the alarm and success hues. Prefer gold or cream for the reticle, and keep the arrow green only if Get out keeps no success meaning. |
| 13 Light | Stands. |
| 14 One idea | Stands. One toon look, the same as batches 1b and 2. |

### 6. Icons: heist status, HUD and outcomes (batches 2a and 2b)

![Status and HUD icons at 48 and 96 pt and in grayscale](board-1/6-icons-status-hud.png)

Gate:
- `P1-AIA2-icons-2a/ac4809ed` and `6a382d97`: all four judged qualities
  pass (ppp).
- `P1-AIA2-icons-2b/29e91db0`: all four pass (ppp).

| Quality | AD's check |
|---|---|
| 1, 3, 13, 14 | Stand. There is one toon look, one top-left light and an unbroken outline, and every silhouette holds at 48 pt and in grayscale. |
| 8 Colour | Stands. Red is kept to the alarm and danger ends, and each state also carries a shape. |

### 7. Icons: currencies, resources, alerts, season and crew pip (batch 1b and others)

![Currency and resource icons at 48 and 96 pt and in grayscale](board-1/7-icons-currencies.png)

Gate: `P1-AIA2-icons-1b/bef6eac2`, all four pass (ppp).

| Quality | AD's check |
|---|---|
| 1, 3, 13, 14 | Stand. |
| 8 Colour | Stands. Each currency has its own silhouette as well as its hue. Renown and starlight share gold, but their shapes differ (a medal and a sparkle). |

### 8. Kit pages beside the style board

![Style board enamel and gold, then kit proof pages](board-1/8-kit.png)

High contrast: [`8-kit-hc.png`](board-1/8-kit-hc.png).

Frame 0 is the style board (material 1, enamel, and material 2, gold).
Frames 1–3 are K1's proof pages on main:
- `art/ui/kit_build/proof/faces_normal_normal.png`
- `art/ui/kit_build/proof_1b/controls_normal.png`
- `art/ui/kit_build/proof_2a/panels_normal.png`

AD also checked the reworked batch 2b page, `proof_2b/controls_normal.png`
and `tiles_normal.png`.

Gate:
- `P1-AIA-kit-1/c8915bc3`: materials pass, colour fail, light pass.
- `P1-AIA-kit-2/fccd4b89`: all pass.
- `P1-AIA-kit-3/3a04e828`, the numerals: display type pass, colour pass.
- `P1-AIA-kit-4/3eb4e200`: materials, display type and colour fail; light
  pass.
- `P1-AIA-kit-5/51269c72`: colour fail; the rest pass.
- `P1-AIA-kit-6/00571a44`: materials fail; the rest pass.
- `P1-AIA-kit-7/961c7905`: all pass.

| Quality | AD's check |
|---|---|
| 1 Materials | Stands. Buttons, discs, pills, tags, tiles and frames carry all four layers (gradient, gloss band, rim, lip), the same as the style board's enamel and gold. Kit-4's and kit-6's fails were reworked in kit-6 and kit-7: the album panel now has a frame and a well. |
| 2 Display type | Stands. Words over colour (GET OUT, CLAIM, the school ribbons, Chapter 3) carry a full ink outline. Dark words on gold or cream plates (PLAY, SKIP) follow the style board's own START HEIST. Kit-3's numerals, timer finish included, pass. |
| 8 Colour | Stands, with a note. Kit-5's gold fill on selected segments and chips was reworked: selection is now cream with a gold rim, as the board says ("a gold rim, never a glow"). Kit-1's sand tertiary on cream is a second warm family. Screens must never set it beside the gold primary (note to S1 and the screen builders). |
| 13 Light | Stands. One top light on every page and ground. |
| 14 One idea | Stands. One chunky, inked, toy-box idiom across the four grounds. |
| 3, 6, 9 | Do not apply to kit art (section 3.5 of the report). |

### 9. Press feedback (quality 4)

![A button set at rest and pressed](board-1/9-press.png)

Frame 0 is `art/ui/kit_build/proof/faces_normal_normal.png` and frame 1 is
`faces_normal_pressed.png` (the top 560 px of each). The timing is in
`client/ui/tokens.json`: `press_ms` 180, `press_squash` 0.96. The motion is
`Motion.press` in `client/ui/motion.gd`, wired to every kit button in
`client/ui/kit_skin.gd`. The judge does not judge motion.

| Check | AD's check |
|---|---|
| Sinks 2–4 pt and darkens | Stands. The pressed face drops onto its lip, about 2.5 pt at 390 pt wide. The body darkens and the gloss band dims. The outline and label stay. |
| Release in 150–250 ms | Stands. The release takes 180 ms, easing out without overshoot. The press down takes 0.6 × 180 = 108 ms. |
| Note | This is a still pair, not a frame strip of the real kit in motion. The real-kit frame strips and clips belong on board 4 (result and motion), as step 8 of the report plans. Also, the space in "GET OUT" is tight on every face; widen the word space in the label style (K1, a note). |

## Objections

Each objection goes to the lead as a request in
`docs/progress/status/AD.json`, with a proposed owner and a default.

| ID | Item | Quality | Objection | Proposed fix | Owner |
|---|---|---|---|---|---|
| A | 1, 2, 4 | 2 | The heist timer is flat figures on a cream pill. | Draw the timer with `KitNumerals` (`client/ui/kit_numerals.gd`, the timer finish kit-3 passed), which no screen uses yet. Optional, not holding: give "Laws here" the kit's ink outline as on the crew names. | S1 |
| B | 3 | 2 / §20.8 | At 200% in pt_BR, "Carregar até 80%" leaves the loot panel and overlaps Pip, and the guard's bubble is clipped behind the panel. | Let the loot panel's line wrap or shrink within the panel, keep the crew row below the panel's measured height, and add a scripted check that no label leaves its panel at 200% in both locales. | S1 |
| C | 1–4 | 14 (and 6) | There is no crew tray: portraits float on the world, and Ash wraps alone onto a second row. The two-line dark hint bar and the thin load bar read as generic chrome. | Seat the crew on a bottom tray from the kit (`panel` with cards and pips, as the key frame shows), in one row at 100%. Make the hint a single kit pill. Use the kit's light bar for load. | S1 (kit pieces exist) |
| D | 1, 2 | 9 | Hollow merges with its purple ring, and Bramble is low in contrast. | Give each portrait ring a lighter inner rim or a cream mat, so that the body reads at 32 pt against the ring (ΔL* ≥ 20). | S1, with AIA-2 if the portrait art changes |
| E | flows | — | `MOMENT=alarm` at 100% shows "Alarm 0/6", the same as sneak, so the alarm moment shows no alarm state. | Make the shot script's alarm moment raise the alarm (or the HUD show it), so boards and the gate see the alarm state. | S1 |

Objection E came from the flow review, below. It holds the board only as far
as the alarm state cannot be checked.

Notes carried to the next round, which do not hold the board:
- The sagewheel's wedges are told apart by hue alone; the reticle is red and
  the get-out arrow green (AIA-2).
- Keep the sand tertiary away from the gold primary on screens (screen
  builders).
- Widen the word space in "GET OUT" (K1).
- Check the HUD share at 200% (the screen class).
- The night scene is dim against the key frame (S1, with the world team, if
  the art direction wants a lit stage).

## Flow review of the integrated build

See "Flow review" in `docs/progress/AD.md` for what AD ran and found. The
findings are requests to the lead in `docs/progress/status/AD.json`.

## When the board stands

The board stands when objections A–E are fixed and re-shot, and AD has
checked the new stills on this page. The lead seeds the fixes as phase 1
tasks. Under section 3.8 of the report, the board merges when AD lets it
stand, with no 24-hour wait.

## Round 2

Checked by AD, P1-AD-board-1b, 12 November 2026, on main at `085c812a`
(P1-S1-pilot-3 merged). The candidates are S1's part 3 stills in
`docs/art/shots/heist-pilot/`:
- `part3-*.png` are main as it stands, with the kit's numerals switched off.
  These are the gate's stills.
- `numerals-*.png` were shot by S1 with `"numerals": true` set locally in
  `client/ui/kit_families.json`, then restored.

What S1 changed is in "Part 3" of `docs/art/tracks/heist-pilot.md`. The gate
judged pilot-3 at `../verdicts/P1-S1-pilot-3/0d142dd0.json` (advice only):
- Heist at 100% text: Display type fail (fff); Hierarchy pass (ppp);
  Character presence fail (fff).
- Heist at 200% text, pt_BR: Display type fail (fff); Hierarchy pass (ppp).

**Decision: the board does not stand.** A, B and D are open (B and D
narrowed); C and E are closed.

AD re-rendered three of the stills on main at `085c812a` with the script and
settings in the track (`part3-sneak-100`, `part3-sneak-200-pt`,
`part3-alarm-100`). They match S1's: the mean difference is 0.07 to 0.34 of
255, and 0.1% to 0.75% of pixels differ by more than 16, which is the
world's motion. So S1's stills stand for the integrated build.

### The stills

Heist at 100%: the key frame, then main, then main with the numerals on.

![Heist at 100%: key frame, part 3, part 3 with numerals](board-1/r2-1-heist-100.png)

Grayscale: [`r2-1-heist-100-gray.png`](board-1/r2-1-heist-100-gray.png).
Colour-vision sheet: [`r2-1-heist-100-cvd.png`](board-1/r2-1-heist-100-cvd.png).

Heist at 200% in pt_BR: the key frame, then main, then main with the
numerals on.

![Heist at 200% pt_BR](board-1/r2-2-heist-200-pt.png)

Heist at 200% in English: the key frame, then main.

![Heist at 200%](board-1/r2-4-heist-200.png)

The alarm moment. The frames, in order:
- the key frame in high contrast;
- main at 100%;
- main in high contrast at 100%;
- main in high contrast at 200%;
- the last one with the numerals on.

![Alarm moment](board-1/r2-3-heist-alarm.png)

The crew tray at 100%, in colour and in grayscale (crop of
`part3-sneak-100.png`):

![Crew tray, colour and grayscale](board-1/r2-5-portraits.png)

Heist at 200% in pt_BR with no crew plan (left), beside the gate's still,
which has a plan (right). AD shot the left one on main without `MANIFEST=1`:
the default crew of three, as a rehearsal, a Workshop island or an offline
heist begins.

![Heist at 200% pt_BR, no plan beside a plan](board-1/r2-6-heist-200-pt-noplan.png)

### The objections

| ID | Round 2 | AD's check |
|---|---|---|
| A | **Open** | On main the timer is still `KitHud.clock`: flat dark figures on a cream plate, the rubric's fail anchor. The gate fails Display type at both sizes for it. With the numerals switched on (`numerals-*.png`), the timer is inked, outlined and filled like the key frame's, at 100%, at 200% in pt_BR and in high contrast. So the fix is ready but switched off. A closes when P1-K1-numerals-on merges and AD sees the timer in a still taken on main. |
| B | **Open, narrowed** | With a crew plan (the gate's stills), B holds. At 200% in pt_BR, "Carregar até 80%" stays inside the loot panel, and the crew tray starts below the panel. The guard's "Quem está aí?" is whole and drawn above the panels. S1's `FIT=1` check fails a shot when words leave their panel, when panels overlap, or when a bubble covers words, and it passes on all eight of S1's shots. But all eight have a plan. With no plan (`r2-6`), Cast reads "Sem lançamentos" and no longer fits on a row beside "Fugir". The tray grows to two button rows and starts at y 960 of 2340, over the loot panel (y 625 to 1131). The Batedor's portrait sits on "Carregar até 100%". `FIT=1` fails that shot: "Loot over the tray". In English at 200%, and in both languages at 100%, it passes with no plan. Note: at 200% the words sit 1–2 px from the panel's inner rim ("Alarme", "~2.600", the moon icon of "Glowing dark"). This does not hold the board, but at large text the panels should keep at least 4 pt inside the rim. |
| C | Closed | The crew, the Sage, Cast and Get out sit on one kit tray. The crew is in two rows, three and two, as the key frame has it, so Ash shares a row with Hollow. The hint is one kit bar with one clause, and the load bar is the kit's `loot_fit` bar. Notes: at 100% the tray ends about a seventh of the screen (about 350 px of 2340) above the bottom edge, leaving dead world under it; at 200% the pause button sits in the crew's rows beside Ash, where it reads as a crew control. |
| D | **Open, narrowed** | The cream mat does what round 1 asked: each disc now parts from its ring by a clear value step, inked on both sides. But the character still does not read against its own disc, and that disc is the problem. Hollow is a violet body on a violet disc: in grayscale the body and the disc are one tone, with no dark shape, and the face is only two white eyes. That is the rubric's smudge, and the gate fails Character presence for it (fff). Bramble's grey body is about 12 L* below its orange disc. It reads, but its surface shows a fine grain at phone size. Pip and Mo are light on light in grayscale too, but their faces and dark details carry them. |
| E | Closed | `MOMENT=alarm` shows "Alarm 3 / 6" with three pips lit, the red edge, and a guard asking "Who's there?". This holds at 100% and in high contrast at both sizes. |

### What B needs

The tray must not grow over the loot panel, whatever the Cast label says.
Either fix will do:
- Let the Cast button wrap its own label onto two lines, or shrink to the
  icon and a short word, so it keeps its row beside Get out.
- Or keep the tray's top below the loot panel and let the tray push down
  into the empty band under it (see C's note).

The check is S1's own: `FIT=1` with no `MANIFEST`, at `TEXT=200
LOCALE=pt_BR`. The gate's still list for the heist should gain this case,
so the next change that lengthens a label is caught. AD asks the lead
(AD-R15) to file it as a small S1 task (`heist_screen.gd`).

### What D needs

The disc behind each portrait comes from the character's school colour
(`client/world/fx_portrait.gd`, `Palette.SCHOOL`). So a body in its own
school's hue, like Hollow, falls on a disc of the same hue and value. Either
fix will do:
- Give the figure a value step of 20 L* or more against its disc. For
  example, a dark plum disc behind a light body, and a light disc behind a
  dark one. Keep the school's hue in the ring or the mat, not behind the
  figure.
- Or draw an ink silhouette outline around the rendered figure, as the
  key frame's portrait cards have.

Bramble's grain should be checked in the portrait render (filtering or
sampling of the model's texture). Change the portrait art only with AIA-2.

### A new note that the lead should place

"Laws here" (and "Leis aqui") is gold on the night sky with no ink outline.
In round 1 this was a note. The gate has now failed Display type on it twice
(pilot-3 at 100% and at 200% pt_BR). P1-K1-numerals-on is gated on Display
type at 100%, so it could fail on a label that is not in K1's files. AD asks
the lead (AD-R14) to give the header the kit's ink outline as a small S1 task
(`heist_hud.gd`), merged before or with the numerals switch. The crew names
now sit on the tray's dark glass, so their thin outline is enough there.

### What is still to be seen

Board 1 stands when:
- A: a still on main shows the timer in the kit's numerals (P1-K1-numerals-on);
- B: a still on main with no crew plan, at 200% in pt_BR, passes `FIT=1` with
  the tray below the loot panel;
- D: a still on main shows Hollow and Bramble reading against their discs.

AD re-checks only those three (and the header, if it is fixed by then), as
P1-AD-board-1c. Phase 2 still waits for board 1 (section 3.8 of the report).
