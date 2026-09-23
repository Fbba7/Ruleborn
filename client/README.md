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

Four screens, opened from `scenes/home.tscn`:

**Home.** Play a heist, or watch replays.

**The heist screen** (`scenes/heist_screen.tscn`). A heist on the fixture
realm, played: the world steps in real time and every tap becomes a simulation
command stamped with the tick it was made (§24.10: *"a move or an ability with
its tick, crew member and target"*). Tap a crew member to select it, tap the
ground to send it there; Crack, Load and Get out act for the selected member,
and Get out calls the skiff (§5.4) to the next tile tapped. When the clock runs
out the command log is written down as the replay a device queues (§24.12) and
checked the way the server checks it. There is no server connection yet, so the
seed is fixed where a lease would bring one.

**The result screen.** The grade the check gave, never the device's own claim:
a replay the re-simulation refuses pays nothing (§24.12). Watch it, play again,
or go home.

**The replay screen** (`scenes/replay_screen.tscn`). The heist just played,
then the golden replays, each re-simulated one tick at a time through
`RulebornReplay` and drawn after each tick. Every second it compares its own
checksum with the one the replay carries (§24.10) and says on screen whether it
still matches — so a phone that drifted from the server would show it, not
quietly play a different heist. Tap a guard to see what its cone reaches, drawn
tile by tile with sharp edges (§21.12); the tiles come from the simulation's own
sight rule, not from a second copy of it here.

Every screen is built from `scripts/ui.gd`, so §21.1 and §21.8 are applied in
one place: a 9:19.5 portrait frame, the clock and alarm at the top centre and
loot at the top right, every control at least 48 points and in the lower
two-thirds, nothing in a corner or within 44 points of the notch or the home
bar. The colours are §21.2's and §21.8's, named once in `scripts/palette.gd`.

The drawing is flat and top-down. §21.1's diorama — a 35° orthographic camera,
toon shading, ink outlines — is the art pass, not this; what this proves is the
part that has to be right before any art: the phone runs the server's rules,
and what the player does is what the server re-plays.

## Tests

`tests/run.gd`, headless, as TAP; `status.py` writes the results to
`status.json`, which [`tools/completion.py`](../tools/completion.py) reads:

- the client's rules version is the one every golden replay names;
- every golden replay re-simulates with every second agreeing with its
  checksums, and the planned heist plays out Clean;
- the replay screen plays a golden to its end and shows its grade;
- every tap makes the one command it names, stamped with the tick it was made;
- the planned heist's commands, given live on the heist screen, record the
  golden replay byte for byte, and the check grades it Clean;
- the heist just played replays with every second agreeing, and a replay with
  an altered checksum is refused;
- the result screen shows the verdict, grade or refusal;
- every control on every screen meets §21.1's size, reach, corner and
  safe-area rules, in a 9:19.5 frame and a 9:16 one (a headless run has no
  screen, so the test sets the window to each), and no text is smaller than 13
  points (§21.8).

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
- **The rest of the crew's commands.** The heist screen gives move, crack,
  load and the skiff. Gait, halt, attack, break, drop, disarm and drag are in
  the simulation and the replay format but have no control yet.
- **The server.** A heist is checked on the phone by the same function the
  server runs; sending it to `server/` for a lease and a grant is the network
  client, next.
- **Fonts.** §21.8 names Baloo 2 and Marcellus; the client uses Godot's default
  font until they are added.
- **The law banner.** §21.8 puts the realm's laws at the top left of the heist
  layout. A woven law already changes what is drawn — a law that halves sight
  halves the cone — but the screen does not yet name it.

## Layout

    project.godot           portrait, 1080 × 2340, the compatibility renderer
    ruleborn.gdextension    loads bin/libruleborn_godot.so
    ext/                    the extension: RulebornReplay, over sim/
    scenes/                 home, heist, result and replay screens
    scripts/                the screens, the realm view and heads-up display,
                            the shared UI pieces, the palette, the session hand-off
    tests/run.gd            headless tests, TAP
    tests/screenshot.gd     a still, under a virtual display
    build.sh, status.py     build, test, write status.json
