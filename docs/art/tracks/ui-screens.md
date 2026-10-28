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
| 9 Harmony | no way to choose the realm sounding but its card | the design's realm strip over the preview, the chosen realm's card first |
| 10 Profile | heists as a split bar and three narrow tiles | the design's two cards, Heists and Defence, each a ring of its share with its counts |
| 11 Season | dark empty boxes where a lane gives nothing; nodes unjoined | open road there; a gold line through the nodes, solid to the next tier |
| 12 Friends | faces, then every friend with Remove, then the feed as plain rows | faces, then Feed and Friends tabs; the week's raids as cream cards with their outcome on a disc |
| 13 Codex | chapter title thin and hollow on gold; (tried three cards a row: German rank words do not fit 84 points, reverted) | a gold drop under the title |
| 14 Share and the dock | Challenge and Invite stacked; dock buttons small and centred | tab strip, one card shown; a one-line dock's actions take the width left |
| 15 Strips and hubs | segments as words only | each segment its icon over its word (Settings, Profile, Share, Friends, Season, the Laws and Crew hubs) |
| 16 League, Shop | members as plain pills; kind filters in lower case | members with Friends' round portraits; filters lead with a capital |
| 17 Every screen at 200% | the Season road's cards clipped their words; portrait initials outgrew their round | wider tiers at large text, opened one before the next; portraits grow with the text |
| 18 Season | the road as separate nodes joined by threads | T9's `KitRail`: one rail, gold to the tier reached, the reached tier large in its ring, rewards over and under it |

High contrast (`HC=1` in the shot script) checked on Codex, Weaving, Law, Lab, Shop, Season, Profile and Friends: every surface keeps its edge; nothing found to fix.

## Shared files touched this wave (for T9 and the integrator)

- `README.md`: conflict markers left by an earlier merge of the kit in the tools listing (around `ui/`) hid the rest of the listing from `check_docs_consistency.py`. Resolved, keeping the `ui/` row.
- `tools/completion.py`: the roadmap's accessibility proof named the contrast test by its old wording; it now names it as `a11y_tests.gd` does ("…the realm's marks on their halo and every material's words on the stops they sit on included…"). T9's branch has the same stale line.
- For T9: the chosen tab's word in `KitTabs.choose` needs a stroke of 12% of its size for §21.8 to count it (this track sets it in `ScreenNav.bar`).

## Draw calls (§21.3: fewer than 150)

Measured with the shot script (`calls` line), at 540 × 1170, after this wave: Codex 119, Weaving 142, Law card 119, Lab 103, **Harmony 162**, Season 108 (the rail), Shop 62, Settings 61, Profile 70, Share 33, Friends 78, Workshop 82, First launch 23, League 35.

Harmony was already 155 at this track's wave-3 head. Of its 162, the live 3D preview (`client/world/law_fx_preview.gd`, T5's since T8 retired) is about 93 and T9's tab bar about 25 (each icon its own texture); the rest of the screen is about 44. A shorter preview shows more cards and costs more (165). **For T5:** a lighter preview for Harmony (the realm's pylons and links without the decoration props) would bring it under. **For T9:** an atlas for the tab and hub icons would save a call an icon.

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

Wave 4, about 04:00 UTC. Main (with the 00:45 and 02:45 integrations) and T9's kit merged in; `check_all` prints "All checks passed" on d4942aa (client 367 of 367, server 439 of 439): the server Weaving test above was fixed on main.

Still worse than the design, in order of how much a first-time player would notice:
1. Art the design has and the game does not: the Shop's featured set and daily picks, the Lab's test realm, the first launch's universe, character portraits for friends.
2. Density: the Laws hub and the tab bar sit low by §21.1, and law cards are two to a row (three do not fit German rank words), so the Codex shows less at once.
3. Harmony's draw calls (162) and the Lab's missing numbered resonance grid (it would cost about 50 calls).

Next: T5 to lighten Harmony's preview; T9 to stroke the chosen tab's word in the kit and atlas the icons; then the Settings wellbeing page once the game keeps play time.

## Wave 5 rounds, judged against the design stills

Stills: `docs/art/shots/ui-screens/w5-<screen>.png`, the design's still on the left and this build on the right.

| Round | Three worst differences | What changed |
|---|---|---|
| 1 Harmony | 162 draw calls; the realm shown bare, no law named on it; realm strip as words only | `ScreenHarmonyStage` (this track's, over T5's `LawFxPreview`): no shadow pass and no walking figure, 118 calls; the laws' cards in the stage's corners, threaded to their pylons; realm chips with their marks; the realm sounding on parchment with a Sounding pill (137 calls) |
| 2 Settings | no Account tab; T11's panel in the old kit's look at the foot of Game | the design's fourth tab, Account: T11's `AuthPanel` dressed by `ScreenAccount` (lit card, the account's mark, status on parchment, gold sign-in, leather sign-outs), the Profile row and the no-tracking note |
| 3 Workshop | island cards a list of words; "Reason / Report / Block" as three big buttons on two lines; lists as chips | the lists as the strip with icons; each island headed by a lit cover (name, maker, level and tags, the realm's mark); the safety actions at 13 points on one line |
| 4 Lab | no resonance grid; finds a shelf of three | the design's numbered grid, four a row: finds on parchment, the hinted lit, each school's still to find dimmed with its count; found of all in the heading |
| 5 Profile | the heist and defence sentences above and below their cards, twice said | a heading; the sentences on the cards for a screen reader and a long press |
| 6 Friends | the invite code first, above the faces; feed cards a sentence each; no Invite tab | faces, then Feed · Friends · Invite; feed cards with the raider's portrait, the outcome's mark on its corner and its pill; the code and adding a friend under Invite (opened when a code is made) |
| 7 Share | a two-line title; no share card | titled Share; the challenge as a share card, its code large and inked |
| 8 Season | lane names scrolled off with the road | the Starpass's crown and the free lane's gift pinned at the left edge |
| 9 Codex | two cards a row, the album two screens tall | three a row wherever every met law's rank word fits a third of the album (T9's compact card); two in German |
| 10 First launch | a lone icon where the design gathers its characters | three of the ruleborn (T1's portraits through `Portrait.of`) under the universe's mark |
| 11 Weaving | 144 calls scrolled | its preview without the shadow pass, the figure kept (133) |
| 13 Settings' Access | the text size a stepper among the rest; every switch its own framed card | the design's text-size card (small and large A, the size in large figures over a dot a step, a law's card to read at that size); the switches as rows of one card with hairlines |
| 14 Shop | every card's art on the same dark well; kinds in lower case | each kind's stage edged in its colour (the design's reward tiles); kinds lead with a capital |
| 15 Profile's log | each heist a list row with a large gold Watch replay | a stripe in the outcome's colour down the row's edge, the outcome's mark and pill; Watch replay in leather |
| 16 First open with nothing yet | Harmony, Lab and Workshop an empty night under a red plate when their view cannot come; Friends with no friends opened on an empty feed | the screen's mark large on its own card with the reason and Try again (`ScreenParts.empty`); no friends opens Invite, where adding one is |
| 17 Lab's chambers | an idle chamber's spheres as large two-line buttons | 13 points, quiet under their gems |
| 18 Settings' Game | the three volumes three framed cards | rows of one card with hairlines, as Access |
| 19 League | the league's card a crest beside three lines | the profile's card: the place, Renown large in gold, the crest, the bar to the next league |
| 20 Workshop's rating | three centred rows of − words + at uneven widths | each aspect's words over five pips, − and + at its right, Send across the lit card |
| 21 Workshop's publish | the name it goes out under as a plain line | the panel lit and titled, the name large on parchment |
| 22 Law card | no way to the next law but back to the Codex | ‹ and › to the law met before and after, its place among them ("Law 5 of 6") |
| 23 Lab | a chamber's last result as three separate pills | one well, a find first in green |
| 24 Workshop's own list | the creator ladder as one sentence | the design's rail: four levels, the one reached lit, its counts beneath |
| 25 Season | reward words in lower case ("a realm skin") | each leads with a capital |
| 26 Every screen at 200% again | Share's kicker one letter a line; Settings' Language one letter a line; Harmony's stage cards covering the realm | the kicker takes the card's width; the language under its name; the stage shows the marks alone |
| 27 Weaving | Take out as large as the weave | 13 points under its slot |
| 28 Codex | the summary card four lines tall, the law worked on buried in it | the summary compact (ring, title, laws met, Keeper, Spire); the law worked on with its mark and the next chapter as the design's next-lead card |
| 29 Shop | the featured card's kicker as plain gold words | the design's gold tag |
| 30 Season | no crowning reward at the head of the track | the season's last reward headed large with its lane and tier (left out at large text, where the road comes first) |
| 31 Lab | level and price on two lines | one line where they fit |
| 32 Share's invite | "Invite a friend" said twice, the gift small | the gift large on a lit card with what both players get |
| 33 Harmony | each combination a long sentence with its percentage at the edge | the design's combination card: its kind and its cost change on pills over its words |
| 12 Large text and contrast | Harmony's Sounding pill at 12 points, its band 1151 px wide at 200%; the share card's dash 3.7:1 on the bright material; Workshop's remix tag squeezed narrow | 13 points and under the name at large text; the share card on the lit card, inked at 12%; the remix tag on its own line |

Every changed screen checked at 150% and 200% in six languages and in high contrast by `A11yTests` (the fast runner below); grayscale thumbnails of Harmony and Workshop compared.

## Hooks in other tracks' files, wave 5

- `client/scripts/auth_panel.gd` (T11): `signal built`, emitted at the end of `_build`, so a host screen dresses the panel after each build. Two lines; behaviour, words and the confirm unchanged. **For T11:** the Account tab dresses the panel's own nodes (the heading beside a mark, the status plate on parchment, buttons in the screens' materials); if the panel's children change order or kind, `ScreenAccount.dress` needs the same change.

## Draw calls, wave 5 (540 × 1170, `calls` line)

Harmony 137 (was 162; the stage alone without the laws' cards 118), Weaving 124 at the top and 133 scrolled (was 144), Codex 131, Lab 122 scrolled, Season 123, Law card 112, Friends 82, Workshop 90, Profile 75, Settings 62, Share 38, League 38, First launch 26.

**For T9:** the tab bar's words are cut at German lengths ("RAUBZU", "FREUND").

## Stopped here (wave 5)

About 23:20 UTC, then continued to 06:00 (the owner's extension). Main had not moved since d2343591; `check_all` prints "All checks passed" on the pushed head. 33 rounds this wave, listed above; stills `docs/art/shots/ui-screens/w5-*.png`.

The fast runner, `client/tests/_mine.gd` (kept out of git): `ONLY=<screens>` runs `A11yTests` over those screens (contrast in both modes, 150% and 200% in six languages); `FILES=<tests>` runs test files taking `(tree, check, mount, url)`, `FILES3=` those taking `(tree, check, url)`. It skips run.gd's catalogue and corner checks; the full client suite (`python3 client/status.py`) covers them.

Shot script switches added this wave: `TAB=<tab>` (Settings, Friends, Profile), `AUTH=signed_in`, `EMPTY=1` (before the state comes), `RATE=1` (Workshop's rating), `LIST=mine` (Workshop's own list). The 200% check in `A11yTests` does not catch a wrapping label squeezed to one glyph a line (Share's kicker, Settings' language passed it): look at the stills.

Still worse than the design, in order of how much a first-time player would notice:
1. Art the design has and the game does not: the Shop's featured set and daily picks, the Lab's test realm, friends' portraits (the server keeps no avatar).
2. The Season track's reward cards have no rank headers (the server sends no rank for a reward).
3. Settings has no Wellbeing tab (the game keeps no play time).

Next: T9's tab bar words at German lengths; a Season hero once rewards have names; the Lab's chambers shorter (the sphere buttons' words are what its test reads).
