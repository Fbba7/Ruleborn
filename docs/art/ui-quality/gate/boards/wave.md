# Wave board: the five screens before and after, at O7

Posted by AD, P3-AD-wave-board, 18 November 2026. This board is not blind:
it reads the gate's verdicts in `gate/verdicts/` beside the stills.

## Ruling

**The wave does not stand yet. One re-work is left, and it is an exit
item.** Everything else stands.

| Rank | Request | Screen | File | Owner | Why it is needed for phase 3's exit (M57) | Default |
|---:|---|---|---|---|---|---|
| 1 | **AD-R67** | settings, Access tab, 100% text | `client/scripts/settings_screen.gd` | S3 (a follow-up task the lead assigns; no task in flight owns the file) | Section 3.6 accepts the wave only when "the second blind audit found no miss left unfixed". Audit 2's miss on P3-S3-settings-3 (settings at 100%, Hierarchy) is still open on main: `settings_screen.gd` has not changed since `7972485a`. | The Access tab at 100% gets one lead in the squint. The gold A / A buttons stay the tab's primary, as key frame 05 and board 5 (F) have them. The "High contrast" and "Motion" switch rows move off cream parchment onto the dark plate with cream words, as the law sample moved at `5fc97aac`. The title keeps its plate, and the tab strip and Back stay as they are. Done when the gate passes "settings at 100% text" on Hierarchy 3 of 3, the 200% and high-contrast forms still pass, and AD previews the stills (M12). |

No other request is an exit item. The notes at the end go to phase 4's
list under M57 and hold nothing.

How each open item was weighed against section 3.6:

| Open item | Section 3.6's clause | AD's ruling |
|---|---|---|
| Audit 2's miss: P3-S3-settings-3 at `7972485a`, settings at 100%, Hierarchy | "the second blind audit found no miss left unfixed" | **Re-work: AD-R67, rank 1.** The miss is not fixed on main (Part 1, settings). |
| Board 2's wait on icon batches 3 and 4, deferred by D13 (c) | "no board has an open objection" | **Stands; no request.** Board 2 holds no objection: it is unposted, because report.md has it posted "when batch 4 passes", and D13 (c), the owner's answer, defers batches 3 and 4. Board 2 moves to the next wave with D6 (a)'s "rest in a later wave". Quality 3 is judged at O7 where the painted batches 1 and 2 land (Part 2). |
| D6 (a)'s two icon styles | "every quality that applies" | **Stands; no request.** D6 (a) is decided: 60 icons painted now, about 330 flat until a later wave. The two styles share the palette, the ink outline and the top-left light, so a screen that shows both still reads as one family (`wave/d6a-side-by-side.png`). The flat icons' outlines are heavier; that is a note for the later wave, not an objection. |
| Any board's open objection | "no board has an open objection" | **None is open.** Every AD request from boards 1 to 5, flow 2 and previews 1 and 2 is closed (Part 6). AD-R65 and AD-R66 are verified on main here. |
| The gate's passes | "passes the gate on every quality that applies, at 100% and 200% text and in high contrast" | **Met**, with AD's reading of the cells the gate never judged (Part 2). |
| Section 10's checks | "section 10's checks pass" | **Met**: draw calls and contrast pass on all 15 shots (Part 4), every motion has its reduced form and passes `check_frames.py` (Part 3), and `bash tools/check_all.sh` passed at this board's ready commit (the handoff in `docs/progress/AD.md` names the record). |

When AD-R67 passes, the wave stands at O7 with no further board: AD's
preview of its stills is the last step.

## How the stills were made

The after stills were rendered on `claude/ui-ad` with main merged at
`9fa88560`, whose `client/`, `art/` and `tools/` match main's `9f0c107a`;
the before stills at `dd326ca8`, in a detached worktree.

| Still | Script | Environment | Where |
|---|---|---|---|
| after, 100% | `universe_home.gd`, `screen_heist.gd`, `screen_result.gd`, `screen_character.gd`, `screen_settings.gd` | `FIT=1` | `wave/<screen>-100.png`, right half |
| after, 200% | the same | `FIT=1 TEXT=200 LOCALE=pt_BR`, and again with `LOCALE=de` | `wave/<screen>-200-pt_BR.png`, `wave/<screen>-200-de.png` |
| after, high contrast | the same | `FIT=1 CONTRAST=1` (home, heist, result); `FIT=1 HC=1` (character, settings) | `wave/<screen>-hc.png` |
| after, character offline at 200% | `screen_character.gd` | `FIT=1 OFFLINE=1 TEXT=200`, `LOCALE=pt_BR` and `LOCALE=de` | `wave/character-offline-200.png` |
| before | the same scripts, except settings: `screen_meta.gd` with `SCREEN=settings` | no `FIT` (the fit check is newer than `dd326ca8`); `TEXT=200 LOCALE=pt_BR`, `CONTRAST=1` or `HC=1` as above | left half of each pair |

Every after run printed "fit ok". The before set has home at 100% only,
result without a high-contrast form, and no German runs, so:

- home's 200% and high-contrast pairs set the after beside home's 100%
  before;
- result's high-contrast pair sets it beside result's 100% before,
  labelled "no hc form";
- every German pair uses the Brazilian Portuguese before.

At `dd326ca8` settings ignored the text size: its 200% before looks the
same as its 100% before.

Each pair is `bin/pair.py`'s four panels, every panel 960 px tall (phone
size): before, after, before in grayscale, after in grayscale. The
grayscale is `tools/ui_gate/sheet.py still --gray`. The strips are
`tools/ui_gate/sheet.py strip` over the frames of the motion shot scripts,
picked by `art/ui/motion/stamp.py` as `art/ui/motion/strips.sh` picks them.
The colour-blindness sheets are `tools/ui_gate/sheet.py cvd` on each atlas
in `art/ui/`. The budgets are `python3 tools/ui_bake/budget_shots.py`,
without `--record`.

## Part 1: the five screens, before and after

### Home

| Form | Pair |
|---|---|
| 100% | `wave/home-100.png` |
| 200%, pt_BR | `wave/home-200-pt_BR.png` |
| 200%, de | `wave/home-200-de.png` |
| High contrast | `wave/home-hc.png` |

The keeper's portrait is now the toon in a gold ring, beside the display
title "Keeper 24": character presence starts in the top-left corner. The
purse is three painted coins in raised chips, the nav is five painted
icons on a gold-ruled bar, and the experience card and the gold Collect
button make one bottom row. In grayscale the gold Collect is the lightest
shape below the map, and the title the lightest above it. The raid notice
of the before is gone from the first screen. At 200% both languages fit,
and the title still leads.

### Heist

| Form | Pair |
|---|---|
| 100% | `wave/heist-100.png` |
| 200%, pt_BR | `wave/heist-200-pt_BR.png` |
| 200%, de | `wave/heist-200-de.png` |
| High contrast | `wave/heist-hc.png` |

The heist is the wave's pilot and carries all eight judged qualities. The
markers stand on the playfield in display type; the leather controls and
the crew tray sit under one light from the top left. AD-R65 is met: at
200%, COFRE and TRESOR stand clear of the crew tray.

### Result

| Form | Pair |
|---|---|
| 100% | `wave/result-100.png` |
| 200%, pt_BR | `wave/result-200-pt_BR.png` |
| 200%, de | `wave/result-200-de.png` |
| High contrast | `wave/result-hc.png` |

The outcome word ("Clean") is display type on a sunburst, the loot is one
raised cream card, and RAID AGAIN is the only gold action beside a quieter
Home. In grayscale the outcome word and the loot card lead, then RAID
AGAIN.

### Character

| Form | Pair |
|---|---|
| 100% | `wave/character-100.png` |
| 200%, pt_BR | `wave/character-200-pt_BR.png` |
| 200%, de | `wave/character-200-de.png` |
| High contrast | `wave/character-hc.png` |
| Offline, 200%, pt_BR and de | `wave/character-offline-200.png` |

The toon stands on a lit dais with its name on a dark plate. The ability is
the first card, on the dark plate, and Level up is the one gold action.
AD-R66 is met: offline at 200%, the HABILIDADE / FÄHIGKEIT header stands
above the foot, where it stands online.

### Settings

| Form | Pair |
|---|---|
| 100% | `wave/settings-100.png` |
| 200%, pt_BR | `wave/settings-200-pt_BR.png` |
| 200%, de | `wave/settings-200-de.png` |
| High contrast | `wave/settings-hc.png` |

The title is display type on its plate, the tabs carry icons, and the text
size reads 100% between two gold As. **This is where the wave's one
re-work is.** In grayscale at 100%, five light shapes compete: the cream
tab strip, the two gold As, the cream "High contrast" and "Motion" switch
rows, and the cream Back. The title is darker than all of them, and nothing
leads. That is audit 2's critique word for word, and no task has touched
`settings_screen.gd` since `7972485a`. The gate passed this cell 5 of 6;
the blind audit is the stricter reader here, and section 3.6 follows the
audit. The 200% and high-contrast forms pass, and the default of AD-R67
leaves them as they are.

## Part 2: the gate's passes per screen and quality

From `gate/verdicts/`, the latest verdict on each cell. "adv." marks
qualities whose verdicts are advisory (owner-checked, section 3.5), which
AD reads on this board. A dash is a cell the gate never ran.

| Screen | Quality | 100% | 200% | High contrast | Verdicts passed, all rounds |
|---|---|---|---|---|---:|
| home | Character presence | pass 3/3 (adv.) `P2-S2-home-6` | — | — | 9 of 11 |
| home | Colour roles and value | — | — | pass 3/3 (adv.) `P2-S2-home-1` | 2 of 2 |
| home | Display type | pass 3/3 (adv.) `P3-S2-home-7` | pass 3/3 (adv.) `P2-S2-home-6` | — | 5 of 13 |
| home | Hierarchy | pass 3/3 (adv.) `P3-S2-back-1` | pass 3/3 (adv.) `P3-S2-home-7` | pass 3/3 (adv.) `P3-S2-home-7` | 25 of 28 |
| heist | Character presence | pass 4/6 (adv.) `P2-S1-toon-drop` | pass 3/3 (adv.) `P2-S1-heist-1` | — | 4 of 8 |
| heist | Colour roles and value | pass 3/3 (adv.) `P2-S1-heist-1` | pass 3/3 (adv.) `P2-S1-heist-1` | pass 3/3 (adv.) `P3-S1-hc-offline-2` | 4 of 7 |
| heist | Display type | pass 3/3 (adv.) `P1-S1-pilot-5` | pass 3/3 (adv.) `P3-S1-marker-1` | — | 4 of 10 |
| heist | Hierarchy | pass 3/3 (adv.) `P1-S1-pilot-3` | pass 3/3 (adv.) `P2-S1-heist-1` | pass 3/3 (adv.) `P1-S1-pilot-2` | 5 of 8 |
| heist | Layered materials | pass 3/3 (adv.) `P1-S1-pilot-1` | pass 3/3 (adv.) `P2-S1-heist-1` | — | 2 of 3 |
| heist | Light behind UI | pass 3/3 (adv.) `P1-S1-pilot-1` | pass 5/6 (adv.) `P1-S1-pilot-1` | — | 2 of 2 |
| heist | One art-direction idea | pass 3/3 (adv.) `P2-S1-heist-1` | pass 3/6 (adv.) `P1-S1-pilot-1` | — | 2 of 3 |
| heist | Painted or rendered icons | pass 5/6 (adv.) `P1-S1-pilot-1` | pass 4/6 (adv.) `P2-S1-heist-1` | — | 2 of 3 |
| result | Character presence | pass 4/6 (adv.) `P3-S1-hc-offline-1` | — | — | 6 of 7 |
| result | Colour roles and value | — | — | pass 3/3 (adv.) `P2-S1-result-1` | 1 of 1 |
| result | Display type | pass 3/3 (adv.) `P2-S1-result-6` | pass 3/3 (adv.) `P2-S1-result-6` | — | 3 of 6 |
| result | Hierarchy | pass 3/3 (adv.) `P2-S1-result-3` | pass 3/3 (adv.) `P3-S1-result-7` | pass 3/3 (adv.) `P2-S1-result-6` | 13 of 14 |
| character | Character presence | pass 3/3 (adv.) `P2-S3-character-2` | — | — | 3 of 3 |
| character | Colour roles and value | — | — | pass 3/3 (adv.) `P2-S3-character-2` | 3 of 3 |
| character | Display type | pass 3/3 (adv.) `P2-S3-character-2` | pass 3/6 (adv.) `P2-S3-character-4` | — | 3 of 8 |
| character | Hierarchy | pass 3/3 (adv.) `P2-S3-character-2` | pass 3/3 (adv.) `P3-S3-offline-1` | pass 4/6 (adv.) `P2-S3-character-2` | 12 of 14 |
| settings | Colour roles and value | pass 3/3 (adv.) `P2-S3-screenkit` | — | pass 3/3 (adv.) `P2-S3-settings` | 4 of 4 |
| settings | Display type | pass 3/3 (adv.) `P2-S3-settings-2` | pass 3/3 (adv.) `P2-S3-settings-2` | — | 6 of 10 |
| settings | Hierarchy | pass 5/6 (adv.) `P3-S3-settings-3` | pass 3/6 (adv.) `P2-S3-settings-2` | pass 3/3 (adv.) `P2-S3-settings` | 11 of 14 |
| settings | Layered materials | pass 4/6 (adv.) `P2-S3-screenkit` | — | — | 1 of 1 |

Per screen, the latest verdict on every cell the gate ran passes:

| Screen | Cells passed | Unanimous |
|---|---:|---:|
| home | 7 of 7 | 7 |
| heist | 18 of 18 | 13 |
| result | 7 of 7 | 6 |
| character | 7 of 7 | 5 |
| settings | 8 of 8 | 5 |

A pass of 3 of 6 is a pass under the sampling rule: a split fails only on 4
or more fails of 6.

**AD's reading of the cells the gate never ran.** Every judged quality is
advisory, so these are AD's owner-check, from the after stills above:

| Screen | Quality | AD's reading |
|---|---|---|
| home | Layered materials | Pass: raised purse chips and a raised Collect over the dark experience plate, all over the starfield. |
| home | Painted or rendered icons | Pass: the purse and the nav are batch 1 and 2's painted icons; the island chips are D6 (a)'s flat set. |
| home | Light behind UI | Pass: one light from the top left; the Heart's glow sits behind the map, and home has no modal. |
| home | One art-direction idea | Pass. |
| result | Layered materials | Pass: the loot card is raised cream on the dark plates. |
| result | Painted or rendered icons | Pass: the medal and the sparkle are painted; Home's house is flat (D6 (a)). |
| result | Light behind UI | Pass: the sunburst behind the outcome word. |
| result | One art-direction idea | Pass. |
| character | Layered materials | Pass: the dark ability card on the cream tray, the tray on the plate. |
| character | Painted or rendered icons | Pass: the tab and card icons are painted. |
| character | Light behind UI | Pass: the light pool behind the toon on its dais. |
| character | One art-direction idea | Pass. |
| settings | Painted or rendered icons | Pass: the tab icons are painted; the school glyphs are D6 (a)'s flat set, kept so each school keeps its shape in every mode. |
| settings | Character presence | Does not apply: settings shows no character. |
| settings | Light behind UI | Pass: one light from the top left, and no modal or reward. |
| settings | One art-direction idea | Pass. |

Character presence and Colour roles and value were run on the forms where
they are judged (presence at 100%, colour in high contrast and at 100% on
the heist and settings); AD reads the other forms of those two from the
pairs, and finds nothing that fails.

## Part 3: the motion families (qualities 4, 5 and 7)

| Family | Full | Reduced | High contrast |
|---|---|---|---|
| Press | `wave/strip-press_full.png` | `wave/strip-press_reduced.png` | — |
| Reward | `wave/strip-reward_common.png`, `wave/strip-reward_rare.png`, `wave/strip-reward_epic.png` | `wave/strip-reward_reduced.png` | `wave/strip-reward_epic_hc.png` |
| Shine | `wave/strip-shine_full.png` | `wave/strip-shine_reduced.png` | `wave/strip-shine_hc.png` |
| Screen change | `wave/strip-screen_full.png` | `wave/strip-screen_reduced.png` | — |

Every line of `check_frames.py` reads "ok", ending "ok all: every motion in
both forms". The press squashes and springs back; the reward anticipates,
bursts and throws coins, and grows by tier; the shine sweeps once; the
screen change cross-fades. The reduced forms keep the state change without
the travel. AD's owner-check: press feedback, reward juice and motion and
idle life pass.

## Part 4: draw calls and texture memory per screen

`budget_shots.py`, without `--record`, against `budgets.json` ("shots"):
draw calls below 150 and no higher than recorded, textures at most 24 MiB,
words at 4.5:1 or better. It printed "OK" for all 15 shots.

| Shot | Draw calls (recorded) | Textures | Glyph caches beside | Words below 4.5:1 | Worst word |
|---|---|---:|---:|---|---:|
| home/100 | 148 (148) | 4.7 MiB | 14.5 MiB | 0 of 29 | 6.40 |
| home/200 | 124 (124) | 4.9 MiB | 138.0 MiB | 0 of 14 | 6.40 |
| home/hc | 148 (148) | 4.7 MiB | 14.5 MiB | 0 of 29 | 8.94 |
| heist/100 | 120 (120) | 2.1 MiB | 23.0 MiB | 0 of 15 | 6.17 |
| heist/200 | 118 (118) | 2.2 MiB | 52.5 MiB | 0 of 8 | 6.87 |
| heist/hc | 121 (123) | 2.1 MiB | 24.5 MiB | 0 of 15 | 5.94 |
| result/100 | 103 (103) | 1.1 MiB | 21.0 MiB | 0 of 15 | 4.78 |
| result/200 | 97 (99) | 1.1 MiB | 70.0 MiB | 0 of 10 | 8.82 |
| result/hc | 45 (45) | 1.1 MiB | 21.0 MiB | 0 of 15 | 6.23 |
| character/100 | 93 (103) | 2.4 MiB | 12.5 MiB | 0 of 23 | 8.28 |
| character/200 | 72 (80) | 2.4 MiB | 36.0 MiB | 0 of 10 | 8.98 |
| character/hc | 93 (103) | 2.4 MiB | 12.5 MiB | 0 of 23 | 10.52 |
| settings/100 | 51 (52) | 1.8 MiB | 13.0 MiB | 0 of 19 | 9.28 |
| settings/200 | 44 (47) | 1.7 MiB | 27.0 MiB | 0 of 16 | 9.37 |
| settings/hc | 51 (52) | 1.8 MiB | 13.0 MiB | 0 of 19 | 5.94 |

Home at 100% and in high contrast sits at 148, two under §21.3's 150, with
no headroom. AD-R67 touches settings only, which draws 51 at 100%.

## Part 5: colour blindness, every atlas

Each sheet is the atlas beside its protanopia, deuteranopia and tritanopia
simulations:

`wave/cvd-atlas-kit.png`, `wave/cvd-atlas-kit_hc.png`,
`wave/cvd-atlas-kit_2.png`, `wave/cvd-atlas-kit_2_hc.png`,
`wave/cvd-atlas-kit_3.png`, `wave/cvd-atlas-kit_3_hc.png`,
`wave/cvd-atlas-icons_48.png`, `wave/cvd-atlas-icons_48_hc.png`,
`wave/cvd-atlas-icons_256.png`, `wave/cvd-atlas-icons_256_hc.png`,
`wave/cvd-atlas-motion.png`, `wave/cvd-atlas-motion_hc.png`.

The roles hold by value and shape. The cream, gold and dark-plate skins
keep their value steps in all three simulations, and the danger red stays
darker than the gold. Under protanopia and deuteranopia the bright green
"go" skins and the gold skins both turn yellow; no screen tells them apart
by hue alone, since the words and icons differ, so this is a note, not a
request. The icons keep distinct silhouettes in every simulation; the
magenta and teal stars, which turn slate under protanopia, differ in shape.

## Part 6: the boards' objections

All closed:

| Objection | Closed by |
|---|---|
| AD-R42 (result, Display type at 200%) | the gate's pass 3/3, `P2-S1-result-6` |
| AD-R43 | P2-S3-account-4 |
| AD-R44 (heist, Hierarchy and Layered at 200%) | the gate's passes 3/3 |
| AD-R45 (home, Display type) | the gate's pass 3/3, P2-S2-home-6 |
| AD-R46 | P2-S1-result-6, then P3-S1-result-7 |
| AD-R47 | tabs-1 |
| AD-R48 | back-1 |
| AD-R49 | home-7 |
| AD-R50, AD-R51, AD-R63, AD-R64 | nav-1 |
| AD-R52 | settings-3 |
| AD-R53, AD-R58 | character-5 |
| AD-R54 | ruled no task (§19.20, §26.9) |
| AD-R55 | marker-1 |
| AD-R56, AD-R57 | hc-offline-1, hc-offline-2 |
| AD-R59 | tabs-1, home-7 |
| AD-R60 to AD-R62 | hc-offline-2 |
| AD-R65 | marker-1, verified on main here (Part 1, heist) |
| AD-R66 | P3-S3-offline-1, verified on main here (Part 1, character) |

AD-R52 closed board 5's objection on the settings tab; audit 2's miss on
the same screen is a separate item, and AD-R67 answers it.

## Notes, which hold nothing

These go to phase 4's list under M57: phase 3's exit does not need them.

- **Heist at 200%:** the vault's progress label ("Vault 0%") is not shown,
  and the playfield band is narrow.
- **Character offline at 200%:** the toon is cropped to its head. Character
  presence is judged at 100%, where the toon stands whole.
- **Glyph caches at 200%:** `budget_shots.py` counts them beside the
  textures, and home's reaches 138 MiB. Worth a look on a phone before the
  next wave.
- **Textures:** result's and settings' are about 0.5 MiB above their
  recorded bytes, far under the 24 MiB limit; `--record` was not run.
- **Green and gold under protanopia and deuteranopia** (Part 5).
- **D6 (a)'s flat icons** have heavier outlines than the painted 60; the
  later wave that paints them evens this out.
- S2-R44 (home at 125% in German, the purse takes two rows) stays deferred,
  and S1-R38's default stands.
