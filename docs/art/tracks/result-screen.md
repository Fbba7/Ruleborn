# The result screen from the kit alone

Branch `claude/ui-screens-heist`, task P2-S1-result-1. The result screen (§23.2: "Grade, loot kept, … replay"; F6), `client/scripts/result_screen.gd`, built from the kit on key frame `art/ui/keyframes/03-result.png` with no chrome of its own. Where the kit cannot build what the key frame shows, that is a request to K1 through the lead, in `docs/progress/status/S1.json`, and the screen meanwhile uses the default written with the request.

## What was done

Before, the screen drew its own surfaces: `FxSkin` plates, `RbBox`, `StyleBoxFlat`s, `HeistHud._gold_rim` on the haul tile, and drawn bars. That was 47 such references in the file at `43f81a56`. Now there are none. `check_screens.py` counts 0 draw and 0 fill in the file, against the 5 and 1 recorded. Lowering the record in `tools/ui_bake/budgets.json` is K1's job (S1-R19).

| Part (key frame 03) | Now |
|---|---|
| The night, and the sunburst behind a heist that paid | The kit's frame, and `KitNav.celebrate` when the heist paid. A foiled or refused heist keeps the plain night. |
| Kicker, medal, title, condition, multipliers, length and peak | `KitNav.hero`, with the title at 40 points as the key frame's Marcellus (the kit hero uses 52). The medal sits beside the title, and the multipliers go on `KitStatus.set_pill`. |
| The moment | `UI.panel("card")` holding `KitControls.big_action` in gold with the replay's length, beside when and what happened. With large text they stand one above the other. |
| Starlight, Essence, Renown | `KitCards.reward` tiles. Starlight is on parchment and wider; the other two are on glass. They sit in `KitLayout.columns`, and stack one above another with large text. |
| Study one law you crossed | `UI.panel("card")`. The laws are buttons in `KitLayout.columns` with the heading font and `UI.clear_box(6, 4)`. They fall to a two-column `KitLayout.grid` when a word will not fit (`_fit_laws`). |
| The crew home | `UI.panel("glass")`. Three faces overlap in `KitRing`s, framed as `KitSocial`'s avatars, beside how long the crew rests. |
| Home and Raid again | `UI.panel("glass")`, as the key frame's `result-bottom glass`. Inside are `UI.action` on parchment with the `hud/home` icon, and `KitControls.action2` wide in gold (red when foiled) with the idle crew line. |

Decisions:

- **Crew faces from the role.** A replay played by role alone names no kind for its crew. The goldens are like that, so the rest card showed no faces. A member with no kind now takes its role's default kind, `Cast.KIND[role]`, as the heist's portraits do (`FxPortrait`).
- **A raid bar that stands upright.** `KitControls.action2`'s label does not wrap. At 200% text "RAID AGAIN" ran past the button, and in pt_BR "ASSALTAR" alone was wider than the room beside Home. `_fit_raid` handles this in two steps:
  - When any one word will not fit, the bar's box turns vertical, with the raid first, full width.
  - Otherwise the words wrap inside the button, inset by its padding. The button's height grows to the lines.
  - The rooms are measured from the phone's width, the safe sides, the bar's padding and Home's width, not read from the layout, so the bar is fitted in `_ready`, before its first frame.
- **The multiplier pill breaks only at its dots.** At 200% text, "Saque ×1.0 · Renome / ×1.0" left "×1.0" alone on a line. Each part ("Renome ×1.0", "Renome −8") is kept whole with non-breaking spaces, so the pill breaks at " · ".
- **The bar is on glass, not on `tab_bar`.** The tab bar's skin is made to run off the screen at its foot (`KitTabs`: "only the gold top edge shows"). Standing in the page, its flat foot showed as cut. The key frame's bar is glass.
- **The actions follow the page** when it fits. Otherwise they go to the foot, under the scroll (F6, `_fit_actions`). The page is laid out first, the laws and the raid bar refitted, and only then measured.

## Evidence

The stills come from `client/tests/shots/screen_result.gd`, on the golden `planned-clean` unless `GOLDEN` names another, with the server's settle answer (`SERVER=1`). `FIT=1` fails the run, and writes no still, if any label's words do not fit their label or panel, if anything is wider than the phone, or if a button's longest word is wider than its room (new in this task):

    SERVER=1 FIT=1 bash tools/render/shoot.sh client/tests/shots/screen_result.gd out.png
    SERVER=1 FIT=1 TEXT=200 LOCALE=pt_BR bash tools/render/shoot.sh client/tests/shots/screen_result.gd out.png
    SERVER=1 FIT=1 CONTRAST=1 bash tools/render/shoot.sh client/tests/shots/screen_result.gd out.png

The gate's items:

- "result at 100% text": Hierarchy, Display type, Character presence.
- "result at 200% text, pt_BR": Display type, Hierarchy.
- "result in high contrast": Colour roles and value, Hierarchy.

FIT, at the task's last client commit:

| Still | FIT |
|---|---|
| en, 100% (planned-clean) | ok |
| pt_BR, 100% | ok |
| de, 100% | ok |
| High contrast, 100% | ok |
| en, 200% | ok |
| pt_BR, 200% | ok |
| de, 200% | ok |
| long-crew5 (Foiled), 100% | ok |
| long-crew5, pt_BR, 200% | ok |
| mid-crew4, short-crew3, edge-seed-max (Foiled), 100% | ok |

The budget stills (`python3 tools/ui_bake/budget_shots.py --only result/…`, no server answer) are all inside their records, and every word is at 4.5:1 or above:

| Budget still | Record | Now |
|---|---|---|
| result/100 | 94 | 82 |
| result/200 | 90 | 79 |
| result/hc | 94 | 82 |

With `SERVER=1` the full frame, island included, is 114 draw calls at 100% (en, pt_BR and de) and 78 to 79 at 200%. long-crew5 is 116 at 100% and 100 in pt_BR at 200%; mid-crew4 113, short-crew3 114, edge-seed-max 112.

The checks on the merge with main, `guard.sh` and the pre-check are in `docs/progress/S1.md` and the status file.

## What the kit cannot do yet

Each of these is a request to K1 through the lead, with the default the screen uses until it is answered:

- **action2's words do not wrap** at large text (S1-R15). The screen's `_fit_raid` reaches into the button's labels to wrap them, and stands the bar upright.
- **The hero title's size** (S1-R16). The kit spec says 34, `KitNav.hero` uses 52, and the key frame 40. The screen sets 40.
- **A portrait stack** (S1-R17). The overlapping faces are composed by the screen from `KitRing`s at the kit avatar's framing.
- **A dusk backdrop for a foiled heist** (S1-R18). The key frame's set has none. A foiled heist keeps the plain night.

## Open

- **Character presence is in the crew's faces.** The reward tiles themselves carry no character art, and neither does the key frame's. If the gate asks for a character beside the reward, that needs a figure or bust beside the tiles. This is new art placement, for AD to rule on.
- **With large text the page scrolls under the foot bar.** At 200% the actions sit at the foot and the moment's card passes under them as the page scrolls (F6's choice: the thumb's bar stays at the foot).
- **Home's icon stands at the left** of its button with its word centred when the bar is upright (pt_BR, 200%).

## The gate's advisory points (verdict at `8bec0d84`)

The advisory verdict passed 4 of 7. Lead cycle 76 asked each builder to take the cheap fixes before marking ready and to list the rest. Taken:

- **Display type at 100%: words on the art had no outline.** The hero's kicker, title, condition and length lines, and the fee, detail and server-check lines under the tiles, now carry the kit's ink outline (§21.8: 1.5 points or 12% of the size, as `UI.world_words`; 3 points in high contrast). The outline takes the place of the title's soft drop.
- **Display type at 100%: the totals were flat fills, and +2,310 was dark on cream.** The three totals are display numbers in the ink outline. Starlight is `gold_top` on parchment; Essence and Renown are `cream` on glass.
- **Display type at 200%, pt_BR: "3 s" was clipped.** `KitControls.big_action` keeps a fixed 76×64 px minimum, and its words grew past it. The moment's button now grows to its icon and words, from the kit's size up.

The hard ink drop the judge also named is left off the totals. Each outline or drop is a further text pass. With the drops, result/200 read 93 draw calls against its record of 90; without them it reads 90.

Not taken, as follow-ups:

- **Character presence** (fail at 100%). The judge asks for separate, larger crew portraits, about 60 px as in the anchor, or a character on the reward. Both are new art placement, for AD to rule on (S1-R20). With result/200 at its record of 90, larger portraits would also need draw calls freed elsewhere.
- **Baked numerals.** `KitNumerals` could draw the totals as the kit's baked display numbers, with the gradient and the drop, in place of a font with an outline.

Budget stills after the fixes (no server answer):

| Budget still | Record | Before | Now |
|---|---|---|---|
| result/100 | 94 | 82 | 89 |
| result/200 | 90 | 79 | 90 |
| result/hc | 94 | 82 | 89 |

With `SERVER=1` the full frame is 120 draw calls at 100% (en) and 90 at 200% (en, pt_BR). FIT is ok on en 100%, en 200%, pt_BR 200% and high contrast.

## Tried and failed

- **The totals with an outline and a hard ink drop:** result/200 rose to 93 draw calls, over its record of 90. The drop was removed and the outline kept.
- Turning the raid row upright with `vertical = true` on an `HBoxContainer`: it is ignored there. The row is a plain `BoxContainer`.
- Wrapping the raid words by setting the label's minimum width to the room: the label still wrapped at the full width of `action2`'s box, anchored over the whole button. The box is inset instead.
- Reading a still after a FIT failure: the shot quits before it saves, so the old still stayed and was misread as current. Renders now go to a fresh folder each round.
- Fitting the raid bar two frames after the screen opens, from the laid-out sizes: on that frame the bar still stood unfitted, and the client's large-text test, which measures on the second frame, saw the raid at 2094 to 2262 px (in the foot's safe area and corners) and its words asking for 1093 px (pt_BR, pt_PT and fr at 200%). The bar is now fitted in `_ready` from measured rooms.
- The bar on `tab_bar`, as in the earlier flow-result: its foot is drawn to run off the screen, and showed as a straight cut in the page.

# The reward sequence (P2-S1-result-2)

Branch `claude/ui-screens-heist`, task P2-S1-result-2. The rewards are counted in on the kit's `Motion.reward`, and the screen no longer counts them itself in `_process`.

## What was done

- **One call to the kit.** `ResultScreen.start_reward` calls `Motion.reward(grade_icon, tile, 0, to, tier, show)`, where:
  - the prize is the grade medal, and the counter is the Starlight tile, or the haul tile when there is no reward row;
  - the tier comes from the grade: Clean is epic, Loud rare, Partial common (`TIERS`);
  - `show` writes each step into the Starlight label, with Essence and Renown in proportion (`_write_reward`), so the three tiles step up together on each landing.
  Full form: the medal's anticipation, the burst on the sunburst, the reveal, then up to eight coins in arcs into the Starlight tile, each landing rolling and pulsing the counter. Reduced form (`Settings.reduced_motion`): the medal fades in, one coin drops into the tile and fades, and the counter is set to its final value.
- **When it starts.** `_ready` writes the tiles at zero and starts the reward 0.6 s after the screen opens, or at once with reduced motion. `hold_reward` holds it, for the shot. A heist with nothing to count (foiled, refused, no medal) plays no sequence.
- **The end.** `rewarded` is emitted, and `reward_done` set, when the sequence ends or when there was none. `_end_reward` writes the final values whatever the tween did, so the screen always comes to rest on the server's numbers.
- **The reward layer over the page (S1-R21).** Motion's layer is `top_level` with a z of 10. A `top_level` item's z does not add to its parents', and the result page is a `UI` layer at z 32 over the night, so the burst and every coin drew under the page and its tiles: the reduced coin did not show at all, and the full coins vanished as they reached the tiles. Until the kit answers, `_lift_reward` gives the layer the medal's whole z plus its own.

## Evidence

The stills are taken at rest, after the sequence: the shot waits for `reward_done`, for at most 1200 frames, or fails. The table below gives FIT at the task's first client commit (d2422a0):

| Still | FIT | Draw calls (`SERVER=1`) |
|---|---|---|
| en, 100% (planned-clean) | ok | 114 |
| pt_BR, 200% | ok | 79 |
| de, 200% | ok | 78 |
| High contrast, 100% | ok | 114 |
| long-crew5 (Foiled), 100%, no sequence | ok | 116 |

The budget stills are inside their records: result/100 82 (record 94), result/200 79 (90), result/hc 82 (94). The reward layer is freed when the sequence ends, so it costs the still nothing.

**Again on main** (P2-S1-result-1 merged as f41d100e, current main merged into the branch). FIT is ok for en 100%, pt_BR and de at 100% and 200%, high contrast, long-crew5 and reduced motion. With `SERVER=1`: en 100% 120 draw calls, de 100% 122, pt_BR 100% 122, long-crew5 123, reduced 119. The budget stills are result/100 89 (record 94), result/200 90 (90) and result/hc 89 (94). `guard.sh` and `check_screens.py` pass. German at 100% already scrolled under the bar at the phone's foot before this task (its rest line wraps to three lines): `_fit_actions` moves the bar there, as designed.

**The crew's faces, apart** (gate, P2-S1-result-1, Character presence: fail 3/3). The judge saw "three overlapping portraits of about 45 px at 960", against the anchor's "five separate portraits of about 60 px". The rest card now shows its three faces apart, 4 points between them, at 52 points: about 57 px each at 960. The page at 100% text had almost no room to spare. Separate faces at 56 points, beside a 14-point line wrapped to three lines, overran the scroll by 28 px and sent the bar to the foot. At 52 points the faces gain 4. The rest line drops to 13 points (the smallest size, 21.8), with no extra line spacing, beside them. The lines under the reward tiles close up from 6 to 4 points. The page then measures 2074 px against the scroll's 2076, so the actions still end the page at 100% text (F6).

The frame strips and clips (board 4) come from the same shot with `STRIP`. The screen's tweens are paused and stepped by a thirtieth of a second for each frame, so the strip shows the sequence as it plays, whatever the renderer's speed:

    STRIP=out/full SERVER=1 FIT=1 bash tools/render/shoot.sh client/tests/shots/screen_result.gd out.png
    REDUCED=1 STRIP=out/reduced SERVER=1 FIT=1 bash tools/render/shoot.sh client/tests/shots/screen_result.gd out.png
    python3 tools/ui_gate/sheet.py strip result-reward-full.png $(ls out/full/crop_*.png | sed -n '6~4p' | head -16) --height 480
    python3 tools/ui_gate/sheet.py strip result-reward-reduced.png $(ls out/reduced/crop_*.png | sed -n '7~2p' | head -10) --height 480
    ffmpeg -framerate 30 -i out/full/full_%03d.png -vf "scale=540:-2,format=yuv420p" -c:v libx264 -crf 20 result-reward-full.mp4
    ffmpeg -framerate 30 -i out/reduced/full_%03d.png -vf "scale=540:-2,format=yuv420p" -c:v libx264 -crf 20 result-reward-reduced.mp4

In strip mode the shot writes no `out.png`, so `shoot.sh` ends with exit 1 on its last check for that file. The frames are written all the same: count them rather than trusting the exit code. In the reduced folder, too, the whole frames are named `full_*.png`; the crops are `crop_*.png`.

- **Full** (planned-clean, epic): 80 frames, the sequence over in 1.93 s. The strip shows the pause before the reveal, the burst on the sunburst, coins in arcs from the medal into the Starlight tile, and the counters stepping +378, +911, +1,703, +2,288, +2,310 (Essence and Renown with them), with a pulse on each landing.
- **Reduced:** 32 frames, over in 0.37 s. The medal fades in, one coin drops into the Starlight tile, and the final values (+2,310, +805, +15) appear.
- **Re-rendered on main** with the faces apart: the same 80 and 32 frames, and the same steps. The strips crop the hero and the rewards, so the rest card is not in them.

The strips and clips are sent to AD for board 4 by request, since `docs/art/ui-quality/gate/**` is AD's (P2-AD-board-4).

## AD's four objections to S1-R24

AD answered the faces' preview (S1-R24) at 08:46Z with four objections. The re-check covers only these four. AD's notes (the gold kicker, the untested idle-crew line, the dock's order at 200%) are not objections and are left as they were.

1. **At 200% pt_BR the first screen showed no haul.** At large text the rewards now come before the moment card, as `03-result_text200_pt_BR`. The three reward tiles turn into rows (`_tile_row`): the icon at 26 points, then the word, then the number, left to right, 3 points of padding above and below, with 4 points between the rows. The third row (Renown) now ends above the dock. If a row's words would not fit the column on one line (German: "Sternenlicht" broke by its letters), `_fit_reward_rows` turns all three tiles back into columns (`_tile_column`) with 8 points between them. pt_BR keeps rows; de goes back to columns.
2. **High contrast had the sunburst's rays, stars and glow.** In high contrast the screen skips `KitNav.celebrate` and builds no island (`_build_world` returns), as `03-result_hc` and Collect's shine: a plain night behind the cards.
3. **At 200% pt_BR the multipliers pill wrapped to two lines.** `_chip_on_one_line` tries three steps in order and keeps the first that fits on one line: the words with 10 points of padding at 14 points; then thin spaces in place of the gaps and 6 points of padding; then the same at 12 points. Only when none fits does the pill wrap as before. pt_BR fits on the second step.
4. **At 100% the rest line took three lines.** The faces sit with no gap between them (0, from 4) and 6 points from the line (from 10), so the line has the room for two lines at 13 points.

At 200% text, when the raid's words stand upright, Home and the replay show as icon-only squares (with an accessibility name and tooltip), so the raid keeps its room.

The fitting lives in `client/scripts/result_fit.gd` (`ResultFit`), so result_screen.gd stays under gdlint's 1000 lines (S1-R27).

| Still (`SERVER=1 FIT=1`) | FIT | Draw calls |
|---|---|---|
| pt_BR, 200% | ok | 109 |
| en, 100% | ok | 120 (as before) |
| High contrast, 100% | ok | 62 |
| de, 200% (tiles as columns) | ok | 97 |

    SERVER=1 FIT=1 TEXT=200 LOCALE=pt_BR bash tools/render/shoot.sh client/tests/shots/screen_result.gd pt200.png
    SERVER=1 FIT=1 CONTRAST=1 bash tools/render/shoot.sh client/tests/shots/screen_result.gd hc.png
    SERVER=1 FIT=1 bash tools/render/shoot.sh client/tests/shots/screen_result.gd en100.png
    SERVER=1 FIT=1 TEXT=200 LOCALE=de bash tools/render/shoot.sh client/tests/shots/screen_result.gd de200.png

**The budget stills.** result/100 is 89 (record 94) and result/hc is 27 (94). result/200 is 98, against a record of 90 and the cap of 150. Bisecting showed the 8 calls come from the three changes together (the haul above the moment, the tiles as rows, the pill on one line), which are the first screen AD asked for. Taking any of them out brings back an objection. So the record goes to the lead by request (S1-R26), as S2-R7, S2-R16 and S2-R17 did for other screens. `check_screens.py` passes, with this screen still at 0 draw and 0 fill.

## Tried and failed

- Reading the missing reduced coin as a texture or clipping fault. The coin was in the tree, with its texture, at full alpha and inside the scroll's rect. It was drawn under the page: the layer's z of 10 is counted on its own, below the page's 32. Raised, it shows.
- (S1-R24 fixes) The reward rows with 12 points of side padding and a margin of slack in the fit: pt_BR asked 903 px of 900 and fell back to columns for nothing. The padding is 10 points and the fit has no slack beyond the rounding.
- (S1-R24 fixes) The reward tiles as rows in every language: German's "Sternenlicht" broke by its letters at 200%. Rows are kept only when every row fits; otherwise the tiles go back to columns.
- (S1-R24 fixes) The rows with the tiles' 8 points of padding and the 8-point row gap: the third row (Renown) ran under the dock at pt_BR 200%. 3 points of padding and a 4-point gap clear it.
