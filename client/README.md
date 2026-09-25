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

Six screens, opened from `scenes/home.tscn`:

**Home.** Play a heist, watch replays, build your island, or change the
settings.

**The builder** (`scenes/builder.tscn`). An island, built (§13): lay ground on
the realm's grid, post guards, place wards, weave laws with their pylons, move
the Vault, and start a blank realm of any level. Every edit goes through
`RulebornIsland` — the simulation's own island and its own editing methods —
so the client never writes the bundle format, and whether the island may be
raided is `Island::check`, the rules the server publishes by, shown as
sentences until they are all met. What the woven laws make together (§8's
harmonies, clashes, resonances and chords) is named as they are woven. The
realm is drawn by the heist's own view, from a heist started on the island, so
what the builder shows is what a raider meets. Raid it plays the island on the
heist screen, offline, and the result leads back to the builder; the island is
kept on the phone. The ground offered is the eight of §6.2's thirty-nine
features the simulation models — rock pillar, ruin wall, fence, fog bank, tall
grass, gravel path, stream and raised ground — and the laws are §7.10's
launch twenty-four.

**The heist screen** (`scenes/heist_screen.tscn`). A heist on the fixture
realm, played: the world steps in real time and every tap becomes a simulation
command stamped with the tick it was made (§24.10: *"a move or an ability with
its tick, crew member and target"*). A tap is read by what is on the tile, and
is always the one command the player chose (§12.18): a crew member is selected;
a guard is attacked, or dragged if it is down; the Vault is cracked, or loaded
to full once open; a pylon is broken; a live ward is disarmed; anything else is
walked to. The buttons cycle the selected member's gait (walk, crouch, run),
halt it, drop half its loot, and — Get out — call the skiff (§5.4) to the next
tile tapped. Of the twelve command kinds, every one but the landing has a control;
the crew lands (§5.4) before the first step on an edge tile it can walk to the
Vault from, chosen by the heist's seed, until there is a landing picker. When the clock runs
out the command log is written down as the replay a device queues (§24.12) and
checked. With a server (`RULEBORN_SERVER`, or the project setting
`ruleborn/server_url`) the screen signs in, takes the first island in §24.8's
target lists that is not the player's own, leases it and plays it, and the
replay is submitted to `server/`, which re-simulates it and settles the fee and
the haul (§24.12). Without one it plays the fixture realm on a fixed seed and
checks the replay with the same function on the phone.

**The result screen.** The grade the check gave, never the device's own claim,
and — from the server — what it minted and the fee: a replay the re-simulation
refuses pays nothing (§24.12). Watch it, play again, or go home.

**The replay screen** (`scenes/replay_screen.tscn`). The heist just played,
then the golden replays, each re-simulated one tick at a time through
`RulebornReplay` and drawn after each tick. Every second it compares its own
checksum with the one the replay carries (§24.10) and says on screen whether it
still matches — so a phone that drifted from the server would show it, not
quietly play a different heist. Tap a guard to see what its cone reaches, drawn
tile by tile with sharp edges (§21.12); the tiles come from the simulation's own
sight rule, not from a second copy of it here.

**Settings** (`scenes/settings.tscn`). §20.6's language, a volume each for
music, effects and alerts, reduced motion and haptics. Each change is applied
and saved to `user://settings.cfg` as it is made, and read back on the next
launch; a first launch starts in the phone's language. The volumes are three
audio buses, so an alarm is never silenced with the music. Reduced motion and
haptics are kept but change nothing yet: the client has no swoops, particles
or vibration for them to turn off. Text size, left-handed controls and high
contrast wait for the accessibility pass rather than being offered before they
work.

**Words.** No screen holds text of its own. Every word comes from
`i18n/strings.csv`, or — for the content's own names, laws, notes,
resonances, chords, wards and ground — from `i18n/content.csv`, which
`tools/client_strings.py` writes from `content/` so each name keeps one home;
its Portuguese column holds the English names until §26.9's read-aloud.
Both reach the screens — one row a key, one column a language, English and
Brazilian Portuguese (§20.6) — through `scripts/strings.gd`, so a language is a
column and adding one touches no script. The Portuguese is a working draft for
these test screens: §26.9 puts the coined vocabulary's native-speaker
read-aloud before anything is translated for launch.

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
- every tap makes the one command it names, stamped with the tick it was made,
  and a tap on a guard, the Vault, a pylon or a ward makes the command it
  calls for;
- the planned heist's commands, given live on the heist screen, record the
  golden replay byte for byte, and the check grades it Clean;
- the heist just played replays with every second agreeing, and a replay with
  an altered checksum is refused;
- the result screen shows the verdict, grade or refusal;
- the whole loop against a real server — `status.py` starts `server/` on a free
  port and a fresh database with the example island published: sign in, take
  a target, lease it, play it through the heist screen's own controls, submit,
  and the server re-simulates it and pays 11,025;
- every control on every screen meets §21.1's size, reach, corner and
  safe-area rules, in a 9:19.5 frame and a 9:16 one (a headless run has no
  screen, so the test sets the window to each), and no text is smaller than 13
  points (§21.8); nothing asks for more width than the phone has — in both
  languages, since Portuguese runs longer;
- every string a script asks for is in the catalogue in both languages with
  the same placeholders, and in a pseudo-locale that wraps every catalogue
  string no screen shows a word that is not wrapped — a word typed into a
  script instead;
- settings changed on the settings screen are saved as they change and
  restored on the next launch, the language and the audio buses with them
  (against a file of the tests' own, never a player's);
- the builder lays ground on the grid and the island it writes reads back the
  same; it weaves laws and places their pylons, holds the realm to its law
  slots and names what the laws make together; and a player can raid their own
  island from it — the heist plays that island, the server's check judges the
  replay, and the result leads back to the builder.

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
- **Sign-in.** The server's sign-in takes a platform credential; a desktop
  build has no Game Center or Play Games, so it sends a stand-in the local
  server accepts. §12.22's target choice is not built either: the client takes
  the first island in the lists that is not its own.
- **The landing picker.** §21's Landing screen — every outer realm's edge,
  what guards would hear, and the clock for each choice — is not built; the
  heist screen lands the crew itself (see above), and nothing draws the crew
  until it has landed.
- **Fonts.** §21.8 names Baloo 2 and Marcellus; the client uses Godot's default
  font until they are added.
- **The law banner.** §21.8 puts the realm's laws at the top left of the heist
  layout. A woven law already changes what is drawn — a law that halves sight
  halves the cone — but the screen does not yet name it.

## Layout

    project.godot           portrait, 1080 × 2340, the compatibility renderer
    ruleborn.gdextension    loads bin/libruleborn_godot.so
    ext/                    the extension: RulebornReplay and RulebornIsland, over sim/
    i18n/strings.csv        every word on screen, a column a language
    scenes/                 home, heist, result, replay, settings and builder screens
    scripts/                the screens, the realm view and heads-up display,
                            the shared UI pieces, the palette, the string catalogue,
                            the saved settings, the session hand-off,
                            and server_client.gd, server/'s edge functions over HTTP
    tests/run.gd            headless tests, TAP
    tests/screenshot.gd     a still, under a virtual display
    build.sh, status.py     build, test, write status.json
