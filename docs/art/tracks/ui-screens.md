# T10 Screens: the menus and meta screens

Branch `claude/ui-screens`. Every screen the 3D tracks do not own, rebuilt to the design's layout (Screens v3) on one set of surfaces, and the app shell: the five tabs, the Laws and Crew hubs, the back control.

## Before and after

| | Still |
|---|---|
| Before: every screen a centred list of sentences on the pale day sky | `docs/art/shots/ui-screens/00-before-a.png`, `00-before-b.png` |
| Round 1: the Codex, the Law card and Weaving on the new surfaces | `01-codex.png`, `01-law.png`, `01-weaving.png` |

Stills are rendered by `client/tests/shots/screen_meta.gd` (`SCREEN=<route>`, optional `SCROLL`, `TEXT` for the text size in percent, `HIDE=<class>` to count draw calls without a kind of node, `WIDE=1` to name what is wider than the frame), with each screen's state from its tests' samples (`client/tests/shots/screen_shots.gd`):

    SCREEN=codex bash tools/render/shoot.sh client/tests/shots/screen_meta.gd out.png

The window is 540 × 1170 showing the 1080 × 2340 frame (360 points at 3 pixels a point) at half size, the same aspect as the design's 390 × 844.

## The local kit (beside T9's)

The screens stand on T9's kit (`client/ui/kit_*.gd`: tab bar, segmented strips, school buttons, law cards, chapter bands) and on a small local layer over it, in `client/scripts/screen_*.gd`:

| File | What it is |
|---|---|
| `screen_box.gd` (`ScreenBox`) | A StyleBox that draws the design's materials: a vertical gradient of up to three stops, soft shadow or glow, the hard drop, the ink outline, one or two inner rims and the gloss, all as **one** triangle array (one draw call per box). |
| `screen_kit.gd` (`ScreenKit`) | The materials (`card`, `card_lit`, `well`, `glass`, `parchment`, `leather`, `gold`, `cream`, `red`, `green`, `active`, `tab`, and the rank frames `oak`, `silver`, `goldframe`, `prism`), the night backdrop, the four families of §21.8 (Manrope 800/600 with tabular figures, Lilita One, Marcellus), buttons in any material with the sink-and-squash press, and the design's icons. Every surface sets meta `behind` to the colours its words sit on. |
| `screen_parts.gd` (`ScreenParts`) | Pills, filter chips, count badges, the segmented control, section headings, stat tiles, list rows, resource pills, the status plate, a whole-panel tap target. |
| `screen_nav.gd` (`ScreenNav`) | The shell: the title header, the bottom dock with the round back button, the hub control, the five-tab bar. |
| `screen_meter.gd`, `screen_bands.gd`, `screen_coin.gd`, `screen_stars.gd`, `screen_draw.gd` | Bars and rings, §5.5's seven-band gauge, resource and school marks, the backdrop's stars, and the batcher they draw through. |

Icons: `tools/screen_icons/export.mjs` runs the design's `icons.js` and `school-marks.js` in node and writes 426 SVGs to `client/art/screen_icons/` (`<group>_<name>.svg`; laws framed by their school's shape as `law_<id>.svg`, their silhouettes `law_<id>_unknown.svg`, the resonances `resonance_<id>.svg`), with the design's class styles written onto each element for Godot's SVG reader. Imported at scale 6 (24-unit icons) or 3 (48-unit law marks).

## The shell, against the design and §21.1

The design puts the back button and the hub tabs at the top. §21.1 is the rule: "a sub-screen's back control sits in the lower band at 48 points", every frequently used control in the lower two-thirds, nothing interactive in a corner. So:

- the header carries the title and a resource pill, no control;
- a sub-screen's back button is the first control of its bottom dock, with the screen's actions beside it;
- the Laws hub's gold control (All laws · Harmony · Lab) sits just above the tab bar, in thumb reach;
- the tab bar sits 20 points above the safe area, so its outer tabs are clear of the bottom corners (the build checks 15% × 8%).

## Hooks in other tracks' files

- `client/tests/a11y_tests.gd` (shared): `_backgrounds` reads meta `behind` on a control (the colours a ScreenBox draws behind its words) and meta `sky` on the screen's root (the night backdrop's ends), so the contrast check measures words against what they really sit on. Six lines.

## Wave 4: the merged build's failures (fixed on this branch)

Merged `claude/videogame-project-analysis-ewkkk2` and `claude/ui-kit` (502b5a0). What failed on these screens, and the fix:

| Failure | Fix |
|---|---|
| Codex: a bare "I" (the tier numeral on a law card) | The numeral goes through the catalogue (`SCREEN_TIER_MARK`). |
| Codex: school names on the gold chapter band at 9.51:1, Lc 67 (Lilita at 22 points needs Lc 75; no ink on that gold reaches it) | The name in cream inside an ink stroke of 2.8 points, which §21.8 lets it be measured against, as the design draws it. |
| Codex: at 200% the summary (ring beside words) asked for 1230 px | Ring above the words at large text; the title wraps. |
| Codex: the count pill on the chapter band wrapped one glyph a line | Only the band's title and kicker wrap. |
| Codex: school filters split four and two | The six marks keep one row; All leads them or sits above. |
| Laws/Friends tab words at 4.49:1 (T9's tab bar: a 1.5-point stroke under §21.8's 12% of 15 points) | Worked round in `ScreenNav.bar`: the chosen tab's word gets a stroke of 12% of its size (2 points). **For T9:** the same change in `KitTabs.choose` would cover every screen. |
| Season at 200% Portuguese: the claim button 3 px into the bottom-right corner band | The Starpass card scrolls with the road at large text, so the dock keeps its place. |
| Friends, League and crews: the code field and its button side by side at large text | They stack at large text (no longer through `UI.row`). |
| Law card: the note line in secondary ink | Primary ink. |

`client/tests/_mine.gd` (kept out of git through `.git/info/exclude`) runs `run.gd`'s screen checks over `ONLY=<screens>` in a few minutes instead of the whole suite.

## Not this track's: one test red on the main branch too

`check_all` stops at one client test outside these screens: "against the server: Weaving offers the starting laws at the simulation's prices…" (`client/tests/weaving_tests.gd`, `_online`). The server recommends `slow_rivers` first for the Heart, priced 0 at 0 points (it is already woven there), so the test's price is 0. The main branch (`1e8619b`, run in a separate worktree here) fails it the same way, 337 of 338; this branch passes every other client test, 342 of 343. The server's `recommend` (`server/src/weaving.mjs`) or the simulation's price for a law already in the realm is where it is decided; neither is this track's.

## Wave 4 rounds, judged against the design stills

Stills: `docs/art/shots/ui-screens/w4a-<screen>.png`, the design's still on the left and this build on the right (Social has no design still).

| Round | Three worst differences | What changed |
|---|---|---|
| 1 Codex | count pill on the chapter band one glyph a line; school filters split 4 + 2; band title in ink on gold | pill kept whole; six marks on one row; cream title in its ink stroke |
| 2 Weaving | tapestry as sentences per slot; deck words broken mid-word; preview card taller than the design's | slot gems on a gold thread (solid between two laws) with name plates; four-card deck with price plates, names beneath; preview 132 points |
| 3 Law card | the two actions as short words, wrapped under the back button | "Pair it in the Lab" and "Weave into a realm" sharing the dock; every dock is one line when it fits |
| 4 Lab | chambers as two big text buttons | the design's test bench: gems in their school rings on a thread through the core |
| 5 Laws hub at 200% | "Harm/ony" broken mid-word | the hub becomes wrapping chips at large text |
| 6 First launch | a small icon and a plain title | the gold logo, the serif line under it, the universe's mark; at large text the mark gives way to the question |
| 7 Shop | cards titled "sage robe (robe-aurora)" | titled by the name ("Aurora"), the kind on its pill |
| 8 Workshop | five equal buttons per island | Play and Remix share the card's main row; why, report and block beneath |

## Still worse than the design

- The Laws hub (All laws · Harmony · Lab) sits above the tab bar by §21.1's rule, where the design puts it at the top: the scrolling area is 60% of the frame, against the design's 75%.
- T9's tab bar stands 20 points above the safe area for the corner rule, leaving a band of empty violet under the tabs.

- Settings has two tabs (Game, Access) where the design has four with a Wellbeing page (play-time ring, week chart, reminders); the game keeps no play-time record to draw.
- Harmony lists every realm's card (its test needs them all); the design shows one realm chosen from a chip row with the chord card beneath.
- The Lab has no resonance grid of twelve numbered tiles; its finds are a shelf.
- Cosmetics have no catalogue names: a card's title is the end of its id.
- Law rule lines (`LAW_RULE_*`) are English in every language.

## Next steps

Harmony's realm chips and chord card; the Lab's numbered resonance grid; Profile's rating card and renown chart; Friends' feed cards.

## Stopped here

(Written at each stop.)
