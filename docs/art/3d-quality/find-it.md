# The find-it test

The test for [plan.md](plan.md) Q9 ("find it in five seconds") and Q13
(sneak, walk and run told apart). A person would be shown a still for five
seconds and asked five questions. Here the answers come from the masks
([mask.md](mask.md)), with no judge and no opinion: the scorer asks of each
object whether it can be found, in the plan's own terms. The command is
`python3 tools/render/findit.py OUTDIR` (`--jobs N`, `--only a,b`,
`--no-render`, `--self-test`). It renders each still through
`tools/render/mask.py`, so it needs the same Godot and Xvfb as the mask tool,
and takes about three minutes for the ten stills with three jobs. It renders
with `MASK_NO_IMPORT=1` (no asset import per still), so a fresh checkout
runs `bash client/build.sh` once first; without it the shot has no imported
assets to load.

## The stills

Ten stills of the heist screen, the plan's moments at today's camera (15
tiles) and three of them at 11 tiles, the zoom the plan sets for the
pilot.

| Still | Moment | Tiles |
|---|---|---:|
| start-15, sneak-15, vault-15, alarm-15, escape-15, entry-15, hold-15 | start, sneak, vault, alarm, escape, entry, hold | 15 |
| start-11, sneak-11, escape-11 | start, sneak, escape | 11 |

The table is `STILLS` in `findit.py`. Each still is a fixed moment of
`client/tests/shots/screen_heist.gd`, so a run is repeatable.

## The questions

Five per still, so ten stills give 50 answers. Q9's target is 90% right,
45 of 50.

| Question | Right when |
|---|---|
| Where is every crew member? | every crew member in view is found (below) |
| Where is every guard? | every guard in view is found |
| Where is the vault? | its pixels in the id mask are at least 300, not cut by the frame's edge, less than half under a panel, and under 20% markers |
| Where is the exit? | the same, for the exit |
| Which route from the chosen crew member to the exit is safest? | the walkable ground joins the chosen crew member's feet to the exit in view without crossing a panel, and every guard in view has its own sight drawn (below) |

A figure is **found** when all four hold. They are the plan's own targets
for Q2, Q3 and Q4, so a figure the plan calls readable is one the test finds:

- it is clear: whole, not cut by the frame, not under a panel;
- its head (the top 30%) is at least 80% seen;
- it stands at least 32 points tall (Q2);
- at most 5% of its pixels are within 18 gray levels of the ground behind it (Q3).

A figure is **in view** when it is shown and has pixels in the frame
(`px > 0`); a guard is asked only if it is also on its feet. A crew member
or a guard wholly off the frame is not asked about: the questions are about
what the still shows. One partly on the frame is asked, and is not found
(it is cut).

A guard's **sight is drawn** when its own sight shows on the ground round
its feet. The 3D markers are not in the id mask; they are in `marks3d.png`
(mask.md), drawn in their own colours (`client/world/fx_ground.gd`,
§21.12). The shown guard gets its cone, its edge and its ring in the
alarm's red, and no fan. Every other guard on its feet gets its facing as a
pale dashed fan reaching 1.6 m, and no cone. The scorer maps each pixel
back to the ground with a homography fitted to every figure's feet (world x
and z in `mask.json` to the frame), and counts, for each guard, the sight
pixels from 0.7 to 2 m from its feet. It leaves out:

- the guard's own rings (0.62 m);
- 0.65 m round every other figure (their rings);
- any point nearer another guard on its feet than this one, so a
  neighbour's fan is the neighbour's.

The shown guard is picked as `WorldView.shown_guard` picks it: the selected
guard when `mask.json` names one (`selected_guard`), else the most aware,
then the one nearest the chosen crew member. It needs 40 red pixels there,
and pale ones do not count for it, since the client draws it no fan. Any
other guard needs 40 pale pixels, and red ones do not count for it, so the
shown guard's cone is not read as a neighbour's sight. A sight under a
panel does not count. `findit.json` keeps each guard's counts
(`route.sight`).

The route is asked from the chosen crew member (`chosen` in `mask.json`).
When that crew member is not in view, the route is not found ("the chosen
crew member is not in view"); the scorer does not fall back to another.

A question with nothing to find (no guard in view, no exit in the still) is
answered "not found": a player cannot find what the picture does not show.
That makes "is the exit in the frame" part of the test, as the plan intends.

The scorer lists each wrong answer with its reasons (`findit.md`: "head seen
8%", "24 pt", "blends 13%", "under panel", "not in the frame"), so a miss
says what to fix. `findit.json` keeps the numbers.

## The clips

Q13 asks whether sneak, walk and run read apart in a two-second clip. A clip
is a series of ten masked frames, 0.2 seconds apart, of one crew member moving
at one gait; the question is "which gait is this?". The scorer reads the
chosen crew member's feet in each frame's `mask.json`, takes the screen speed
in points per second, and names the gait from it (`score_clip`; the edges,
`GAIT_EDGES`, are 4 and 9 points per second). A clip is right when the named
gait is the one shown.

| Clip | Shown |
|---|---|
| sneak | the chosen crew member sneaks |
| walk | the same walks |
| run | the same runs |

Three clips, three answers.

**What is rendered today: no clip.** The heist shot has no gait or clip hook:
a moment is a still, and the crew's pace is not set from the shot's
environment. The clip scorer is built and tested on drawn frames
(`--self-test`: feet moving at 2 and at 60 points per second read as sneak
and run), and the run reports no clip answers until frames exist.
`GAIT_EDGES` are provisional for the same reason: no clip has been
rendered to set them from, so they are set from the three clips' first
render. When the
shot can render a gait over a series of frames, the clips join the run with
no change to the scorer; this is request M2-R2 in M2's status file. The
timing half of Q13 (an order answered within 0.1 seconds) is a timing check,
not a find-it question, and is not part of this task.

## Today's build

Ten stills, 50 answers, run on this branch (the scorer reads
`mask.json` and the passes; the render is `findit.py <scratch>/fi`):

| Question | Found |
|---|---:|
| crew | 0 of 10 |
| guards | 0 of 10 |
| vault | 3 of 10 |
| exit | 2 of 10 |
| route | 2 of 10 |
| **all** | **7 of 50 (14%)** |

Q9 is 14% against a target of 90%. Nothing here is a fault of the tool; it is
the build, and the reasons say how:

- **Crew and guards: 0 of 10.** At 15 tiles the crew stand 24 to 29 points
  tall (14 for one half hidden in alarm-15), under the 32 of Q2. At 11 tiles
  they pass Q2. In all ten stills a crew member or a guard blends with the
  ground by 13 to 40% of its pixels, against Q3's 5%, and that alone fails
  every still. Where a panel or another figure hides a head (entry-15,
  hold-15, sneak-15, sneak-11), the head seen falls to 0 to 38%. A guard
  partly off the frame is cut (escape-15, entry-15, start-11); one wholly
  off it is not asked (g0 in escape-11).
- **Vault: 3 of 10.** Found in sneak, hold and the 11-tile sneak. In the
  others it is under a panel (the order bar over it, as plan.md 2.6 draws
  it) or covered by its own markers (vault-15: 24%).
- **Exit: 2 of 10.** The exit is in the frame only in the escape stills. In
  the other eight it is not drawn, so the player cannot find it.
- **Route: 2 of 10.** Found in both escape stills: the ground joins the
  chosen crew member to the exit, and every guard in view has its sight
  drawn (the shown guard's red cone, 5,574 pixels at 15 tiles and 10,372 at
  11; the other guard's pale fan, 750 at 15 tiles). In the other eight the
  exit is not in view, so there is no route to read. In the nine stills
  whose ground is fixed (all but entry-15, below), every guard in view has
  its sight drawn, the shown one by 3,257 red pixels or more and each other
  one by 410 pale pixels or more, against 40.

The 11-tile stills score the same as the 15-tile ones: the closer camera
fixes the size of the figures (Q2) but not their blending or the panels.

The sight's colour tests were set from this render: the cone renders
crimson (about 120, 20, 40), the fans lavender white (about 100, 90, 110 to
190, 170, 190), the crew rings orange (about 180, 60 to 100, 20) and the
effects' sparks bright pink (about 240, 200, 220); the tests take the first
two and leave out the others. Rings of the same size round random ground
points at least 3.7 m from every guard hold no sight pixels in most stills
(at most 3 of the 57 to 80 rings in a still pass 40), so the 40 a guard
needs is seldom met by chance. The stray hit checked, in sneak-11, is a
falling petal of the effects, shaded mauve (about 115, 78, 112), which the
fan test takes; a red hit can only credit the shown guard.

## Limits

- The test is a floor, not a proof of readability. It says a figure *can* be
  found on the plan's terms; a person's five seconds can still go wrong on a
  figure it finds (a look-alike, a busy ground). Q9 stays "measured by the
  mask" until a person plays the pilot (the phase 1 exit).
- The route question asks only that the ground joins and the sight shows. It
  does not rank routes; "safest" is the player's choice once both are drawn.
- The ground is fitted to the figures' feet, so it needs four figures at
  four distinct places. In entry-15 the three crew stand on one tile, so the
  ground is not fixed and no guard's sight is read there ("ground not
  fixed" in `route.sight`); that still has no exit in view, so its route
  is not found either way.
- The thresholds are constants at the top of `findit.py`
  (`MIN_POINTS`, `MAX_BLEND`, `MIN_SEEN`, `MAX_COVER`, `MIN_OBJECT`). They are
  the plan's; change them only when the plan does. The sight's (`SIGHT_INNER`,
  `SIGHT_OUTER`, `SIGHT_PIXELS`, `RING_CLEAR` and the colour tests in
  `sight_pixels`) are the scorer's own, set from today's render (above);
  check them again when the sight's look changes.
- The stills are Godot renders on the Compatibility renderer under Xvfb, as
  in mask.md; a run on another machine can differ in shading but not in the
  masks' classes.
