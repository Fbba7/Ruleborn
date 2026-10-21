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

## The kit (local, for T9 to fold in)

T9's kit had not landed when this started, so the screens stand on a small local one, in `client/scripts/screen_*.gd`:

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

## Still worse than the design

- The design stills had not landed; judged against `docs/analysis/screens-v3/screens-*.md`.
- Most screens are still the old lists (see the next steps).

## Next steps

Lab, Harmony, Season, Shop, Settings, Player stats, Share, Friends, Social, Workshop, Age; then rounds against the design stills.
