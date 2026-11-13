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

## Tried and failed

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

The stills are taken at rest, after the sequence: the shot waits for `reward_done`, for at most 1200 frames, or fails. FIT, at the task's last client commit:

| Still | FIT | Draw calls (`SERVER=1`) |
|---|---|---|
| en, 100% (planned-clean) | ok | 114 |
| pt_BR, 200% | ok | 79 |
| de, 200% | ok | 78 |
| High contrast, 100% | ok | 114 |
| long-crew5 (Foiled), 100%, no sequence | ok | 116 |

The budget stills are inside their records: result/100 82 (record 94), result/200 79 (90), result/hc 82 (94). The reward layer is freed when the sequence ends, so it costs the still nothing.

The frame strips and clips (board 4) come from the same shot with `STRIP`. The screen's tweens are paused and stepped by a thirtieth of a second for each frame, so the strip shows the sequence as it plays, whatever the renderer's speed:

    STRIP=out/full SERVER=1 FIT=1 bash tools/render/shoot.sh client/tests/shots/screen_result.gd out.png
    REDUCED=1 STRIP=out/reduced SERVER=1 FIT=1 bash tools/render/shoot.sh client/tests/shots/screen_result.gd out.png
    python3 tools/ui_gate/sheet.py strip result-reward-full.png $(ls out/full/crop_*.png | sed -n '6~4p' | head -16) --height 480
    python3 tools/ui_gate/sheet.py strip result-reward-reduced.png $(ls out/reduced/crop_*.png | sed -n '7~2p' | head -10) --height 480
    ffmpeg -framerate 30 -i out/full/full_%03d.png -vf "scale=540:-2,format=yuv420p" -c:v libx264 -crf 20 result-reward-full.mp4

- **Full** (planned-clean, epic): 80 frames, the sequence over in 1.93 s. The strip shows the pause before the reveal, the burst on the sunburst, coins in arcs from the medal into the Starlight tile, and the counters stepping +378, +911, +1,703, +2,288, +2,310 (Essence and Renown with them), with a pulse on each landing.
- **Reduced:** 32 frames, over in 0.37 s. The medal fades in, one coin drops into the Starlight tile, and the final values (+2,310, +805, +15) appear.

The strips and clips are sent to AD for board 4 by request, since `docs/art/ui-quality/gate/**` is AD's (P2-AD-board-4).

## Tried and failed

- Reading the missing reduced coin as a texture or clipping fault. The coin was in the tree, with its texture, at full alpha and inside the scroll's rect. It was drawn under the page: the layer's z of 10 is counted on its own, below the page's 32. Raised, it shows.
