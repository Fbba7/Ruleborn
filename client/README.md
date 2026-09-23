# Client

The game on the phone: Godot 4.5 with the simulation linked in as a Rust
GDExtension, which is §24.7's plan — *"written once and compiled for every
target it runs on"*. The crate the server validates heists with
([`sim/`](../sim/README.md)) is the crate this client plays them with, so a
heist on the phone and the heist the server settles are the same computation,
not two implementations kept in step.

```bash
bash client/build.sh        # the extension, the golden replays, Godot's import cache
python3 client/status.py    # build, run the tests headless, write client/status.json
```

`build.sh` fetches Godot 4.5 once into `~/.cache/ruleborn` (or uses
`$RULEBORN_GODOT`). To look at it on a desktop, open `client/` in Godot 4.5
after building.

## What is here

**The replay screen** (`scenes/replay_screen.tscn`). It loads a golden replay,
re-simulates it one tick at a time through `RulebornReplay`, and draws the
realm after each tick. Every second it compares its own checksum with the one
the replay carries (§24.10) and says on screen whether it still matches — so a
phone that drifted from the server would show it, not quietly play a different
heist. Tap a guard to see what its cone reaches, drawn tile by tile with sharp
edges (§21.12); the tiles come from the simulation's own sight rule, not from a
second copy of it here.

The layout follows §21.1 and §21.8: a 9:19.5 portrait frame, the clock and
alarm at the top centre and loot at the top right, every control at least 48
points and in the lower two-thirds, nothing in a corner or within 44 points of
the notch or the home bar. The colours are §21.2's and §21.8's, named once in
`scripts/palette.gd`.

The drawing is flat and top-down. §21.1's diorama — a 35° orthographic camera,
toon shading, ink outlines — is the art pass, not this; what this proves is the
part that has to be right before any art: the phone runs the server's rules.

## Tests

`tests/run.gd`, headless, as TAP; `status.py` writes the results to
`status.json`, which [`tools/completion.py`](../tools/completion.py) reads:

- the client's rules version is the one every golden replay names;
- every golden replay re-simulates with every second agreeing with its
  checksums;
- the planned heist plays out Clean with every bag banked;
- the screen plays a golden to its end and shows its grade;
- every control meets §21.1's size, reach, corner and safe-area rules, in a
  9:19.5 frame and a 9:16 one (a headless run has no screen, so the test sets
  the window to each);
- no text is smaller than 13 points (§21.8).

To look at it without a desktop, `tests/screenshot.gd` renders a still under a
virtual display:

```bash
xvfb-run -s "-screen 0 1080x2340x24" ~/.cache/ruleborn/Godot_v4.5-stable_linux.x86_64 \
    --path client --rendering-driver opengl3 -s res://tests/screenshot.gd -- out.png planned-clean 20
```

## Not yet

- **The store builds.** Only a Linux build of the extension is made here. iOS
  and Android need their export templates and toolchains, and §24.7's spike —
  the extension building and loading on a real iPhone and Android — is the
  gate for them.
- **Input.** Taps are not yet commands; the screen plays replays, it does not
  record them (phase 3's "Capture input").
- **Fonts.** §21.8 names Baloo 2 and Marcellus; the client uses Godot's default
  font until they are added.
- **The law banner.** §21.8 puts the realm's laws at the top left of the heist
  layout. A woven law already changes what is drawn — a law that halves sight
  halves the cone — but the screen does not yet name it.

## Layout

    project.godot           portrait, 1080 × 2340, the compatibility renderer
    ruleborn.gdextension    loads bin/libruleborn_godot.so
    ext/                    the extension: RulebornReplay, over sim/
    scenes/                 the replay screen
    scripts/                the screen, the realm view, the palette
    tests/run.gd            headless tests, TAP
    tests/screenshot.gd     a still, under a virtual display
    build.sh, status.py     build, test, write status.json
