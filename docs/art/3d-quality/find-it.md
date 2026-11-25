# The find-it test

The test for [plan.md](plan.md) Q9 ("find it in five seconds") and Q13
(sneak, walk and run told apart). A person would be shown a still for five
seconds and asked five questions. Here the answers come from the masks
([mask.md](mask.md)), with no judge and no opinion: the scorer asks of each
object whether it can be found, in the plan's own terms. The command is
`python3 tools/render/findit.py OUTDIR` (`--jobs N`, `--only a,b`,
`--no-render`, `--self-test`). It renders each still through
`tools/render/mask.py`, so it needs the same Godot and Xvfb as the mask tool,
and takes about three minutes for the ten stills with three jobs.

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
| Which route from the chosen crew member to the exit is safest? | the walkable ground joins the chosen crew member's feet to the exit in view without crossing a panel, and each visible guard has its sight drawn (at least 150 marker pixels within six guard-heights of its feet) |

A figure is **found** when all four hold. They are the plan's own targets
for Q2, Q3 and Q4, so a figure the plan calls readable is one the test finds:

- it is clear: whole, not cut by the frame, not under a panel;
- its head (the top 30%) is at least 80% seen;
- it stands at least 32 points tall (Q2);
- at most 5% of its pixels are within 18 gray levels of the ground behind it (Q3).

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
and run), and the run reports no clip answers until frames exist. When the
shot can render a gait over a series of frames, the clips join the run with
no change to the scorer; this is request M2-R2 in M2's status file. The
timing half of Q13 (an order answered within 0.1 seconds) is a timing check,
not a find-it question, and is not part of this task.

## Today's build

Ten stills, 50 answers, run on this branch (the scorer reads
`mask.json` and the passes; the render is `findit.py /tmp/fi`):

| Question | Found |
|---|---:|
| crew | 0 of 10 |
| guards | 0 of 10 |
| vault | 3 of 10 |
| exit | 2 of 10 |
| route | 0 of 10 |
| **all** | **5 of 50 (10%)** |

Q9 is 10% against a target of 90%. Nothing here is a fault of the tool; it is
the build, and the reasons say how:

- **Crew and guards: 0 of 10.** At 15 tiles the crew stand 24 to 29 points
  tall, under the 32 of Q2 (a guard in a still can be 40). At 11 tiles they
  pass Q2 (33 to 39 for crew, 53 for guards). In all ten stills a crew member
  or a guard blends with the ground by 13 to 40% of its pixels, against Q3's
  5%, and that alone fails every still. Where a panel or another figure hides
  a head (entry-15, hold-15, sneak-11), the head seen falls to 0 to 38%.
- **Vault: 3 of 10.** Found in sneak, hold and the 11-tile sneak. In the
  others it is under a panel (the order bar over it, as plan.md 2.6 draws
  it) or covered by its own markers (vault-15: 24%).
- **Exit: 2 of 10.** The exit is in the frame only in the escape stills. In
  the other eight it is not drawn, so the player cannot find it.
- **Route: 0 of 10.** Where the exit is not in view there is no route to
  read; in the escape stills the guards' sight is not drawn.

The 11-tile stills score the same as the 15-tile ones: the closer camera
fixes the size of the figures (Q2) but not their blending or the panels.

## Limits

- The test is a floor, not a proof of readability. It says a figure *can* be
  found on the plan's terms; a person's five seconds can still go wrong on a
  figure it finds (a look-alike, a busy ground). Q9 stays "measured by the
  mask" until a person plays the pilot (the phase 1 exit).
- The route question asks only that the ground joins and the sight shows. It
  does not rank routes; "safest" is the player's choice once both are drawn.
- The thresholds are constants at the top of `findit.py`
  (`MIN_POINTS`, `MAX_BLEND`, `MIN_SEEN`, `MAX_COVER`, `MIN_OBJECT`). They are
  the plan's; change them only when the plan does.
- The stills are Godot renders on the Compatibility renderer under Xvfb, as
  in mask.md; a run on another machine can differ in shading but not in the
  masks' classes.
