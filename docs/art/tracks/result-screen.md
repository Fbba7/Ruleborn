# The result screen from the kit alone

Branch `claude/ui-screens-heist`, task P2-S1-result-1. The result screen (§23.2: "Grade, loot kept, … replay"; F6), `client/scripts/result_screen.gd`, built from the kit on key frame `art/ui/keyframes/03-result.png` with no chrome of its own. Where the kit cannot build what the key frame shows, that is a request to K1 through the lead, in `docs/progress/status/S1.json`, and the screen meanwhile uses the default written with the request.

## What was done

Before, the screen drew its own surfaces: `FxSkin` plates, `RbBox`, `StyleBoxFlat`s, `HeistHud._gold_rim` on the haul tile, and drawn bars. That was 47 such references in the file at `43f81a56`. Now there are none. `check_screens.py` counts 0 draw and 0 fill in the file, against the 5 and 1 recorded. Lowering the record in `tools/ui_bake/budgets.json` is K1's job (S1-R19).

| Part (key frame 03) | Now |
|---|---|
| The night, and the sunburst behind a heist that paid | The kit's frame, and `KitNav.celebrate` when the heist paid. A foiled or refused heist keeps the plain night. |
| Kicker, medal, title, condition, multipliers, length and peak | `KitNav.hero`, with the title at 40 points as the key frame's Marcellus (the kit hero uses 52). The medal sits beside the title, and the multipliers go on `KitStatus.set_pill`. |
| The moment | `UI.panel("card")` holding `KitControls.big_action` in gold with the replay's length, beside when and what happened. With large text they stand one above the other. |
| Starlight, Essence, Renown | `KitCards.reward` tiles, all three on parchment as in the design's still 07 (P2-S1-result-6). Starlight is wider, with the crew's lead in a ring on its corner. The totals are baked in the kit's `num_gold` numerals. They sit in `KitLayout.columns`, and stack one above another with large text. |
| Study one law you crossed | `UI.panel("card")`. The laws are `UI.action` buttons in the kit's tertiary face (`ghost`: violet on the dark card) in `KitLayout.columns`, with the heading font and `UI.clear_box(6, 4)`. They fall to a two-column `KitLayout.grid` when a word will not fit (`_fit_laws`). |
| The crew home | `UI.panel("glass")`. Three faces overlap in `KitRing`s, framed as `KitSocial`'s avatars, beside how long the crew rests. |
| Home and Raid again | `UI.panel("glass")`, as the key frame's `result-bottom glass`. Inside are `UI.action` in the kit's tertiary face (`ghost`: violet on glass) with the `hud/home` icon, and `KitControls.action2` wide in gold (red when foiled) with the idle crew line. |

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
- **`KitNav.reward` dresses the sunburst in high contrast too** (S1-R32). It dresses `Sky` with `night_rays` whatever the outcome or the contrast, and the token has no high-contrast form, while key frame 03-result_hc keeps the plain night. Until K1 answers, `start_reward` puts the plain night back after the call where the outcome does not celebrate (`_celebrates`).

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

## Board 4's objections A, B, D and E (P2-S1-result-3)

Board 4 objected to four things on the result screen. All four are met at 5e844ac3.

- **A, the reward figures.** The figures are drawn in the home's "Keeper 24" finish (`_display`): the display face, filled solid (deep gold on the cream Starlight tile, cream on the dark tiles), with a heavy ink outline (0.21 of the size) and a hard drop straight down (0.08 of the size, at least 1.5 points). The finish is the same in high contrast, on the solid tiles.
- **B, the haul on the first screen at 200%.** When the reward rows would fall under the action bar, the hero's words (kicker, title, condition, subline) go down by the least of three steps (0.88, 0.78, 0.7) that lifts the third row above the bar (`ResultFit.hero_shrink`). Each step's saving is measured from the lines the words actually take, so a second fitting before the next layout picks the same step. Results:
  - de needs the first step: the kicker takes one line and the condition two.
  - en and pt_BR fit at full size.
  - `screen_result.gd`'s FIT check now fails when any reward tile ends below the top of the actions (or below the viewport), and the de 200% still is part of the fit check.
- **D, the coins.** The coins now aim at the icon of the Starlight tile (or of the haul's tile when the split is hidden), not at the tile's centre (`_reward_mark`). Each coin starts the roll as it lands. The pulse is on the icon too, so the digits never move or hide behind a coin.
  - At 100% the icon stands above the number; at 200% (rows) it stands to its left.
  - The full strip (80 frames, 1.93 s), the 200% strip and the reduced strip (32 frames, one coin on the icon) show no frame where a coin covers a rolling figure.
- **E, the action bar.** At 200% text, Home is shown as its icon alone in every language, whether or not the raid stands upright, and the raid button leads the bar. Its spoken name and tooltip keep Home's word.

| Still (`SERVER=1 FIT=1`) | FIT | Draw calls |
|---|---|---|
| en, 100% | ok | 126 |
| High contrast, 100% | ok | 68 |
| en, 200% | ok | 113 |
| pt_BR, 200% | ok | 115 |
| de, 200% (hero one step down) | ok | 114 |
| High contrast, 200% | ok | 55 |

**The budget stills:**

| Still | Draw calls | Record | Without A's hard drop |
|---|---|---|---|
| result/100 | 91 | 89 | 89 |
| result/200 | 99 | 98 | 97 |
| result/hc | 27 | 27 | 27 |

The calls are A's hard drop on the three figures: taken out, the drop brings result/100 back to 89 and result/200 to 97. Board 4 asked for the drop, so the records go to the lead by request (S1-R28). Both figures stay well under the cap of 150.

### Objection F, the fold (AD's preview S1-R29)

AD's preview of `d896f254` added one objection. At 200% text in English (and high contrast at 200%), the first screen ended on the tops of a line's letters: "Re-simulated by the server" showed as a row of ticks and dashes just above the action bar. AD offered two fixes, a fade of about a line or a cut that never shows a part line. This is the cut, since a fade is one more draw call.

- **The cut.** `ResultFit.fold` runs whenever the bar sits under the page that scrolls. That is at text above 100%, or at 100% when the page overflows. It finds the line or card that the scroll's lower edge would cut (`ResultFit.part_line`). A line counts as cut when its baseline falls below the edge, so only the tops of its letters show; a line that loses only its descent stays whole. A card counts as cut when less than one line of body text of it shows. The corner's clearance under the bar then grows by that amount, which lifts the bar and the scroll's edge onto the gap above the cut line.
- **When it refits.** The cut is fitted again whenever the page or the scroll changes size, for example when the raid's words wrap. Each fitting measures from the edge as it stands without the cut, so repeated fittings settle on the same answer.
- **Where the first screen now ends:**
  - en 200%: "Entry fee 2,840 returned".
  - de 200%: "Eintrittsgebühr 2.840 erstattet".
  - pt_BR 200%: "Taxa de entrada de". The rest of that label starts below the edge.
- **The haul at pt_BR 200%.** `ResultFit.hero_shrink` now measures to the scroll's lower edge, including the column's separation above the bar, rather than to the bar's top. Before this change, the tighter FIT check found the Renome row's foot 12 px under the edge at pt_BR 200%.
- **The FIT check.** `screen_result.gd` now fails in two cases:
  - the scroll's lower edge cuts a line or a card;
  - a reward tile ends below the scroll's edge, when the bar is under the scroll.

| Still (`SERVER=1 FIT=1`) | FIT | Draw calls |
|---|---|---|
| en, 100% | ok | 126 |
| High contrast, 100% | ok | 68 |
| en, 200% | ok | 113 |
| pt_BR, 200% | ok | 115 |
| de, 200% | ok | 114 |
| High contrast, 200% | ok | 55 |
| pt_BR, 100% | ok | 128 |
| de, 100% | ok | 128 |
| High contrast, pt_BR 100% | ok | 70 |
| High contrast, de 200% | ok | 56 |
| High contrast, pt_BR 200% | ok | 57 |

The draw calls are the same as at `d896f254`, because the cut moves layout only and draws nothing new. The budget stills are given in the handoff (S1.md). They are unchanged, and S1-R28's two records still stand.

## Tried and failed

- **The totals with an outline and a hard ink drop:** result/200 rose to 93 draw calls, over its record of 90. The drop was removed and the outline kept.
- Turning the raid row upright with `vertical = true` on an `HBoxContainer`: it is ignored there. The row is a plain `BoxContainer`.
- Wrapping the raid words by setting the label's minimum width to the room: the label still wrapped at the full width of `action2`'s box, anchored over the whole button. The box is inset instead.
- Reading a still after a FIT failure: the shot quits before it saves, so the old still stayed and was misread as current. Renders now go to a fresh folder each round.
- Fitting the raid bar two frames after the screen opens, from the laid-out sizes: on that frame the bar still stood unfitted, and the client's large-text test, which measures on the second frame, saw the raid at 2094 to 2262 px (in the foot's safe area and corners) and its words asking for 1093 px (pt_BR, pt_PT and fr at 200%). The bar is now fitted in `_ready` from measured rooms.
- The bar on `tab_bar`, as in the earlier flow-result: its foot is drawn to run off the screen, and showed as a straight cut in the page.
- (F) A spacer under the page to lift its edge: a zero-height Control in a VBox still takes the column's separation, which moved the bar even when no line was cut. The cut grows the corner's clearance under the bar instead.
- (F) The first fold, fitted only when the page resized: it ran before the raid bar grew, and FIT failed at pt_BR and de 100% and 200%. It now also refits when the scroll resizes, measuring from the edge without the cut.
- (F) Counting every clipped line as a part line: Renome's "+0" lost 3 px of its descent and was counted as cut, which lifted the bar over the whole Renome tile at pt_BR 200%. A line is cut only when less than its ascent shows.

## Phase 2's exit (P2-S1-result-4)

The overflow sweep, the advisory gate's close points at `904a3567`, AD's board 4b note, and M26's rule that the fit check covers every state the screen shows.

- **Home and the laws in the tertiary face.** The gate's close point said Home and the law pills read lighter than Raid again in grayscale, so the raid led by size and place but not by value. Both are now `UI.action` in the kit's `ghost` skin (K01's tertiary button: violet on the glass or card), which is darker than gold in grayscale. Raid again stays the one light, wide shape at the foot. In high contrast the kit's own high-contrast faces apply, unchanged. No draw call more: the skin replaces the parchment one.
- **The reward tiles keep no character frame.** The gate's other close point (Character presence, 3 of 3) asked for character art on the reward tiles. The tiles are currency, Starlight, Essence and Renown, each with its own icon, and the crew card under them carries the characters' faces. A character frame on a currency tile would be a new placement of character art, which is AD's and the kit's to decide, not a fit fix. It is answered in AD's preview (S1-R31) and left as it is.
- **A short label goes under the fold whole.** AD's note for board 4b (S1-R30): at pt_BR 200% the first screen ended on "Taxa de entrada de", the first line of a two-line label. `ResultFit.part_line` now treats a label of up to three lines (`KEEP`) as one piece: when only its first lines show above the scroll's edge, the whole label goes under it, and the bar rises by the lines that would have shown. A longer label may still break at a line. It is still a cut, not a fade, so it adds no draw call. pt_BR 200% now ends on the Renome tile.
- **Every state in the fit check (M26).** `screen_result.gd` takes `STATE`: `confirming` (the server still re-simulating), `refused` (`REFUSED` is the server's code, default `replay_malformed`, worded from the error catalogue), `testing` (a rehearsal from the builder: Watch it, Back to the builder, Publish it) and `play` (a workshop play, settled as `WorkshopController` settles it: no split). With no `STATE` it shows the plain result, local or (with `SERVER`) server-checked, on any of the five goldens. The sweep below runs them all at 200% in en, pt_BR and de.

- **A rehearsal action's long word stays whole.** At 200% in German, "Veröffentlichen" (735 px) was wider than the widest control (666 px) and broke between its letters, which also left the page's foot 78 px into a line. `ResultFit.fit_whole` steps the button's words down the least sizes that keep its longest word whole; the other actions keep their size.
- **The words over the sky inked by their size (M30).** The advisory gate at `8753618a` failed Display type at pt_BR 200% on the hero: the gold kicker "ASSALTO CONCLUÍDO" read as unoutlined on the sunburst, and the lines under it kept a 2 to 3 px edge on 45 px glyphs. The outline was set from the words' points before the text size applied, so it stayed 6 px at every size. `ResultFit.ink` now sets it from the size each label is drawn at: an edge of 1.5 points, scaled with the text size (3 in high contrast), or 12% of the drawn size, whichever is more. It runs again when the hero shrinks to fit. Godot shows about a quarter of `outline_size` outside the glyph (measured: 21 gave 5 px on an 84 px face), so the constant is four times the edge. At pt_BR 200% the "N" of "Nenhum" (61 px tall) now has a 10 px ink edge, and the kicker 9 px. The kicker, title, condition, time and alarm line, and the lines under the tiles all take it. No draw call more: an outline is part of the glyph's draw. Re-swept at `3d357ac6` (FIT=1, 51 stills: the plain result plain and high contrast in en, pt_BR and de at 100% and 200%, the four goldens and local at 200%, every state at 200% and at en 100%, reduced motion, long-crew5): every still "fit ok", every draw call as in the table below (server-checked confirming 114, play 88, rechecked against `8753618a` on the same still).

Draw calls from each still's `budget:` line, with `FIT=1` (rehearsal rows after the fix above):

| State | en 200% | pt_BR 200% | de 200% |
|---|---|---|---|
| Server-checked, planned-clean | 113 | 115 | 114 |
| Server-checked, short-crew3 | 109 | 113 | 113 |
| Server-checked, mid-crew4 | 108 | 112 | 112 |
| Server-checked, long-crew5 | 111 | 115 | 115 |
| Server-checked, edge-seed-max | 107 | 111 | 111 |
| Local (not yet checked) | 99 | 99 | 101 |
| Confirming | 114 | 115 | 115 |
| Refused (`replay_malformed`) | 77 | 77 | 79 |
| Workshop play | 88 | 88 | 88 |
| Rehearsal | 97 | 97 | 100 |
| Rehearsal, high contrast | 32 | 32 | 35 |

All "fit ok". At 100% in English: local 91, confirming 118, refused 73, play 80, rehearsal 88 (de 90). The longest refusal, `removed_from_constellation` in German at 200%: 87. The plain result's sweep (en, pt_BR, de at 100% and 200%, each also in high contrast, long-crew5, reduced motion): 17 stills, all "fit ok", draw calls as before.

## The reward on K40's entry point (P2-S1-result-5)

`start_reward` now calls `KitNav.reward(self, grade_icon, tile, 0, to, tier, _write_reward.bind(to))` in place of `Motion.reward`. The medal, the coins into the Starlight tile (else the haul's), the other tiles counting with it, the outcome's tier and the reduced form under reduced motion are unchanged: `KitNav.reward` hands them to `Motion.reward` as before. `_lift_reward()` stays, after the call, so the medal's and coins' `top_level` layer still sits over the page.

- **`KitNav.celebrate(self)` is kept in `_ready`.** It dresses the sunburst from the first frame, while the reward waits `REWARD_WAIT` before it starts; dropped, the hero would stand on the plain night for that wait and then change backdrop under the title. It is only called where the outcome celebrates: a heist that paid (Clean, Loud, Partial), not in high contrast (`_celebrates`, which also replaces the inline test `_ready` had). The second dressing by `KitNav.reward`, with the same material, changes nothing on a celebrating outcome.
- **The plain night back where the outcome does not celebrate.** `KitNav.reward` dresses `Sky` with `night_rays` on every call. In high contrast that put rays behind the whole page (seen on the server-checked still with `CONTRAST=1`, the one high-contrast state whose reward plays: the diff with main covered the full backdrop), against key frame 03-result_hc and AD's S1-R24. `start_reward` dresses `Sky` back to `night` when `_celebrates` is false. Asked of K1 as S1-R32, under "What the kit cannot do yet".
- **No draw call more.** Budget shots: result/100 91, result/200 99, result/hc 27, each as its record in `tools/ui_bake/budgets.json`. Server-checked, en 200%: 113 planned-clean as before; server-checked high contrast 55.
- **`check_screens.py`: OK.**

The fit sweep, `FIT=1` on `client/tests/shots/screen_result.gd`, 56 stills, every one "fit ok" with 0 fails (M27: every fixture state the screen shows), in en, pt_BR and de each:

- the plain result at 100% and 200%, each also in high contrast;
- server-checked at 200% on each of the five goldens (planned-clean, short-crew3, mid-crew4, long-crew5, edge-seed-max), and server-checked in high contrast at 200%;
- local long-crew5 at 200%;
- at 200%: confirming (server-checked and local), refused (`replay_malformed`), testing (server-checked, local and high contrast) and workshop play;
- and en 100% with reduced motion, de 200% refused with `removed_from_constellation`.

| State | en 200% | pt_BR 200% | de 200% |
|---|---|---|---|
| Plain result | 99 | 99 | 101 |
| Plain result, high contrast | 34 | 34 | 36 |
| Server-checked, planned-clean | 113 | 115 | 114 |
| Server-checked, short-crew3 | 109 | 113 | 113 |
| Server-checked, mid-crew4 | 108 | 112 | 112 |
| Server-checked, long-crew5 | 111 | 115 | 115 |
| Server-checked, edge-seed-max | 107 | 111 | 111 |
| Server-checked, high contrast | 55 | 57 | 56 |
| Local long-crew5 | 105 | 107 | 107 |
| Confirming (server-checked) | 114 | 115 | 115 |
| Confirming (local) | 101 | 101 | 102 |
| Refused (`replay_malformed`) | 77 | 77 | 79 |
| Testing (server-checked) | 111 | 113 | 114 |
| Testing (local) | 97 | 97 | 100 |
| Testing, high contrast | 32 | 32 | 35 |
| Workshop play | 88 | 88 | 88 |

At 100%: plain 91 (pt_BR, de 93), high contrast 27 (pt_BR, de 29), reduced motion 90. de 200% refused with `removed_from_constellation`: 87. Each row matches the earlier sweep where that sweep shot the same state.

## The kit's fixes dropped, the gold totals and the crew's face (P2-S1-result-6)

**The screen-side fixes the kit now covers are gone** (`02c2e6b8`):

- **S1-R23:** the '3 s' replay button's grow closure. `KitControls.big_action` grows on its own.
- **S1-R15:** `_fit_raid`'s wrap and height. `KitControls.action2` wraps and grows. The Home square and the upright row at 200% stay.
- **S1-R32:** `_celebrates`' high-contrast clause. `KitNav.reward` and `KitNav.celebrate` keep the sky plain under high contrast. The re-dress to `night` stays for outcomes that do not celebrate.

The shot's FIT check now also fails words drawn outside their button.

**Character presence at 100% (`02c2e6b8`: 4-2 fail).** The crew's lead now stands in a ring on the Starlight tile's corner (`ResultFit.carrier`), as the carrier in key frame 03. At 100% the three faces on the rest card are apart and larger: `FACES` 3 at `FACE_POINTS` 52 (`32a87041`, `58a4a10f`).

**The reward totals take the display treatment.** `ResultFit.bake_totals` lays each total as `KitNumerals` glyphs, in the kit's `num_gold` finish: an ink outline, a hard drop and a gold gradient. The live label stays for its accessible name and its size, with `visible_characters = 0` so its own glyphs are not drawn. Hiding them by alpha still drew them; skipping them saves 14 draw calls at every setting (`f96569c0`). If a glyph is missing, `KitNumerals.make` hands back a live label.

- **One finish for one rank** (`24cc4d7c`). The haul and the three rewards are all `num_gold`. At pt_BR 200% the gate split on white totals reading flatter than the gold one of the same rank.
- **Every reward tile on parchment** (`e4e78070`). The gate's Display type at pt_BR 200% then failed 0/3: on the two glass tiles, the gold numerals' ink outline and drop sank into the dark ground, so +805 and +15 read flat and spread beside +2.310. The design's still 07 has all three tiles on parchment, so now the screen does too. The kit's `reward_gold` and `reward_green` are its gold and green *button* faces (tried, below), so plain parchment stands in for the coloured edges. This departs from key frame 03, where Essence and Renown sit on glass. AD was asked to preview it (S1-R35).

| Still (`SERVER=1 FIT=1`, at `e4e78070`) | FIT |
|---|---|
| en, 100% | ok |
| en, 200% | ok |
| pt_BR, 200% | ok |
| de, 200% | ok |
| High contrast, 100% | ok |
| High contrast, 200% | ok |

    SERVER=1 FIT=1 bash tools/render/shoot.sh client/tests/shots/screen_result.gd en100.png
    SERVER=1 FIT=1 TEXT=200 bash tools/render/shoot.sh client/tests/shots/screen_result.gd en200.png
    SERVER=1 FIT=1 TEXT=200 LOCALE=pt_BR bash tools/render/shoot.sh client/tests/shots/screen_result.gd pt200.png
    SERVER=1 FIT=1 TEXT=200 LOCALE=de bash tools/render/shoot.sh client/tests/shots/screen_result.gd de200.png
    SERVER=1 FIT=1 CONTRAST=1 bash tools/render/shoot.sh client/tests/shots/screen_result.gd hc.png
    SERVER=1 FIT=1 CONTRAST=1 TEXT=200 bash tools/render/shoot.sh client/tests/shots/screen_result.gd hc200.png

**Budgets.** `budget_shots.py`: result/100 88 (record 91), result/200 96 (99), result/hc 27 (27). Contrast: 0 words below 4.5:1 in each. The lead could record the two lower figures.

**The gate (advisory, rubric 3).** Each run had three samples, plus three more on a split. The verdicts are in `docs/art/ui-quality/gate/verdicts/P2-S1-result-6/`.

| Commit | Item | Quality | Samples | Result |
|---|---|---|---|---|
| `02c2e6b8` | 100% text | Display type | 4 pass, 2 fail | pass |
| `02c2e6b8` | 100% text | Character presence | 2 pass, 4 fail | fail |
| `58a4a10f` | 100% text | Display type | 3/3 | pass |
| `58a4a10f` | 100% text | Character presence | 3/3 | pass |
| `24cc4d7c` | 100% text | Display type, Character presence | 3/3 each | pass |
| `24cc4d7c` | 200% text, pt_BR | Hierarchy | 3/3 | pass |
| `24cc4d7c` | High contrast | Hierarchy | 3/3 | pass |
| `24cc4d7c` | 200% text, pt_BR | Display type | 0/3 | fail |
| **`e4e78070`** | 100% text | Display type | 3/3 | **pass** |
| **`e4e78070`** | 100% text | Character presence | 3/3 | **pass** |
| **`e4e78070`** | 200% text, pt_BR | Display type | 3/3 | **pass** |
| **`e4e78070`** | 200% text, pt_BR | Hierarchy | 3/3 | **pass** |
| **`e4e78070`** | High contrast | Hierarchy | 3/3 | **pass** |

### AD's objection H, a reward word broken (AD-R46)

AD's preview of `e4e78070` (S1-R35, board 4) kept one objection, H. At 200% German the Starlight row read "+2.310 Sternenlich / t": the word broke by its letters, and FIT passed it.

**The cause.** `ResultFit.reward_rows` measured each row by its live labels before `bake_totals` laid the gold glyphs, and the baked row was let grow to the words' width plus the outline. In German at 200% the row came out a few pixels wider than measured, so the name's label lost room and broke inside "Sternenlicht".

**The fix** (`b5843368`):

- `result_screen.gd` bakes the totals at their final words before the rows are measured, so `reward_rows` sees the rows as drawn.
- `reward_rows` measures each label at the wider of its minimum size and its words' width.
- `bake_totals` keeps the baked row within the live words' width above 125% text (the outline allowance stays at 100%, which the gate passed). The label is never narrower than its hidden words, since the fitting and the reader still use them.
- **FIT** now fails any wrapped label with a word wider than its room: "the word … breaks inside itself". On the old code at German 200% it fails "Sternenlicht"; on the new code it passes.

| Still (`SERVER=1 FIT=1`, at `b5843368`) | FIT | Draw calls |
|---|---|---|
| en, 100% | ok | 116 |
| en, 150% | ok | 101 |
| en, 200% | ok | 100 |
| pt_BR, 100% | ok | 118 |
| pt_BR, 150% | ok | 103 |
| pt_BR, 200% | ok | 102 |
| de, 100% | ok | 118 |
| de, 150% | ok | 101 |
| de, 200% | ok | 101 |
| High contrast, 100% | ok | 58 |
| High contrast, 200% | ok | 42 |

The draw calls are the shot test's own count, with the reward sequence still running, so they are not `budget_shots.py`'s figures. All are under the task's 150. At German 200%, "+2.310 Sternenlicht" stands on one line beside its total: the rows hold, without the column fallback, and all three rewards sit above the first screen's edge. Every reward word is whole at 4× in en, pt_BR and de at 200%, and in de at 150%. The 100%, pt_BR 200% and high-contrast stills are unchanged by eye.

    SERVER=1 FIT=1 TEXT=150 LOCALE=de bash tools/render/shoot.sh client/tests/shots/screen_result.gd de150.png
    SERVER=1 FIT=1 TEXT=200 LOCALE=de bash tools/render/shoot.sh client/tests/shots/screen_result.gd de200.png

The other stills use the commands above, with `TEXT` and `LOCALE` set to match.

**The gate at `b5843368`** (advisory, rubric 3; `verdicts/P2-S1-result-6/b5843368.json`):

| Commit | Item | Quality | Samples | Result |
|---|---|---|---|---|
| **`b5843368`** | 100% text | Display type | 3/3 | **pass** |
| **`b5843368`** | 100% text | Character presence | 3 pass, 3 fail | **pass** (split; on the next board) |
| **`b5843368`** | 200% text, pt_BR | Display type | 3/3 | **pass** |
| **`b5843368`** | 200% text, pt_BR | Hierarchy | 3/3 | **pass** |
| **`b5843368`** | High contrast | Hierarchy | 3/3 | **pass** |

Character presence split, and passes because a fail needs 4 or more fails of 6. The three fails each named one portrait: Ash's rock body with orange cracks, read as fine mottled grain (a physically based material under ruling v3). The three passes read the same body as matte and soft-shaded. The portraits are unchanged since `e4e78070`, which passed 3/3, so this is a close call on Ash's render, not on this fix. Ash's portrait comes from `client/world/fx_portrait.gd`, outside this task. If the next board finds the grain, the change belongs there.

### Tried and failed

- **The kit's `reward_gold`, `reward_green` and `reward_pink` on the three tiles,** as the tokens' note "parchment edged in the reward's colour" reads. `reward_gold` and `reward_green` draw through the kit's `button_primary` and `success` skins: a solid gold bar and a solid green bar. The gold one rivals Raid again. Only `reward_pink` and `reward_sky` are edged parchment tiles.
- **White totals on the glass tiles beside a gold one on parchment.** The gate split on Display type at pt_BR 200%: same rank, different treatment.
- **Gold totals on the glass tiles.** The gate failed it 0/3: the dark outline and drop vanish on the dark ground.
- **A baked row floored under its words** (the first H fix, r1): the gold row was kept narrower than the totals' text, so the hidden live label grew narrower than its words. FIT failed: "+805" drawn 224 px in 222. The label's minimum width is now the wider of its words and the baked row.

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
- (Board 4, B) Measuring the hero's saving from the label's size as set: the fit ran twice before a layout, and the second run read the already-shrunk size and shrank again (de went to 0.7). The saving is now measured from the height as laid out.
