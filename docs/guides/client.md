# Client developer guide

The Godot client in `client/`: how to build it, test it, render a still,
add a string, and keep to the accessibility rules and the budgets. What the
client is and how its layers fit is in
[`client/README.md`](../../client/README.md) and
[`docs/architecture.md`](../architecture.md).

## Prerequisites

| Tool | Why | How to get it |
|---|---|---|
| Rust (stable) and `cargo` | `client/ext/`, the simulation as a GDExtension | rustup |
| Godot 4.7.2-stable (Linux x86-64) | the engine | `client/build.sh` fetches it into `~/.cache/ruleborn/` and checks its SHA-512; or set `RULEBORN_GODOT` to your own binary |
| Node 22.5 or later | the online test starts `server/` | nodejs.org |
| `gdlint` (gdtoolkit 4) | GDScript lint, run by `check_all.sh` | `pip install "gdtoolkit==4.*"` |
| `xvfb-run` and Mesa | rendering stills with no screen | your distribution's `xvfb` package |
| Rust targets `aarch64-linux-android`, `aarch64-apple-ios` | `client/export.sh check` | `export.sh` adds them with `rustup target add` |

## Build and test

```bash
bash client/build.sh        # builds client/ext, copies the goldens, fetches Godot once, imports
python3 client/status.py    # builds, runs every test headless, writes client/status.json
```

`status.py` starts `server/` on a free port with a fresh database and the
example island published (`RULEBORN_STUB_SIGNIN=1`), so the one test that
plays a heist against a real server can run; the simulation's WebAssembly
build must exist first (`bash sim/run_spike.sh`). It prints the TAP lines and
exits non-zero if any test failed.

To run the tests yourself against your own server:

```bash
RULEBORN_SERVER=http://127.0.0.1:8787 RULEBORN_CREDENTIAL=test:client \
  ~/.cache/ruleborn/Godot_v4.7.2-stable_linux.x86_64 --headless --path client -s res://tests/run.gd
```

Lint, as `check_all.sh` runs it:

```bash
(cd client && gdlint $(find . -name '*.gd' -not -path './.godot/*'))
```

The rules gdlint and Godot enforce here: GDScript warnings are errors (type
every variable and loop iterator, shadow nothing); class definitions in
gdlint's order; at most 20 public methods per class (`client/gdlintrc`);
no `class_name` load cycles between static initialisers.

### How the tests are organised

`client/tests/run.gd` is the runner. It calls each suite by its class name in
a fixed order (`A11yTests`, `WorldTests`, `KitTests`, …; about forty
`*_tests.gd` files in `client/tests/`), so **a new suite must be added to
`run.gd` by hand**; a file in the folder is not discovered by itself. The
runner separately checks that every script in the project compiles. Shared
fixtures are `tests/fixtures.gd` and `tests/plans.gd`. The run has a
deadline (`DEADLINE_SECONDS` in `run.gd`).

### The store builds

```bash
bash client/export.sh check     # compiles sim/ and ext/ for both phones' arm64; checks the pack
bash client/export.sh android   # needs ANDROID_HOME, ANDROID_NDK_HOME and Java
bash client/export.sh ios       # needs a Mac with Xcode and RULEBORN_APPLE_TEAM_ID
```

`check` runs anywhere and is part of `check_all.sh`; `client/pack_check.py`
confirms the exported pack holds every file the game reads by path and no
tests. Godot's export templates are fetched once and checked against a
pinned SHA-512.

## Rendering a still

Tracks judge their work by stills from the real client, rendered under Xvfb
with Mesa's software OpenGL and the Compatibility renderer (the one the
phones use):

```bash
bash tools/render/shoot.sh client/tests/shots/heist_shot.gd out.png          # 1080 × 2340
bash tools/render/shoot.sh client/tests/shots/world_shot.gd out.png 540 1170
SCREEN=settings TEXT=200 HC=1 LOCALE=de \
  bash tools/render/shoot.sh client/tests/shots/screen_meta.gd settings.png
```

Shot scripts live in `client/tests/shots/`; each reads its options from the
environment (the header comment of each script lists them; `screen_meta.gd`
takes `SCREEN`, `SCROLL`, `TEXT`, `HC`, `LOCALE`, `ME`). `shoot.sh` builds
Godot if it is missing and runs `--import` first so new class names resolve.
`SHOT_TIMEOUT` (seconds, default 300) bounds a shot.

The older route still works:

```bash
xvfb-run -s "-screen 0 1080x2340x24" ~/.cache/ruleborn/Godot_v4.7.2-stable_linux.x86_64 \
    --path client --rendering-driver opengl3 -s res://tests/screenshot.gd -- out.png planned-clean 20
```

Compare each still with the design's (`art/design/stills/`) side by side, at
phone size and in grayscale; commit the stills you judge by to
`docs/art/shots/<track>/` as PNGs under 400 KB (see
[the 3D program](../art/3d-program.md#seeing-your-work)).

## Strings and localisation

Every word on screen comes from a catalogue; a script never types a word.

| File | Holds | Written by |
|---|---|---|
| `client/i18n/strings.csv` | every interface string, a column per language | by hand, except its `en_US` column |
| `client/i18n/content.csv` | the content's names (laws, ruleborn, features …) | `python3 tools/client_strings.py`, from `content/` |
| `client/i18n/countries.csv` | country names for the account panel | `python3 tools/auth_countries.py` |
| `client/platform/notifications.csv` | push notification texts | by hand, except `en_US` |
| `client/platform/ios/*.lproj/`, `client/platform/android/res/values*/` | the phones' own notification tables | `python3 tools/native_strings.py`, from `notifications.csv` |

The languages are the columns `en, en_US, pt_BR, pt_PT, de, fr`, matching
`Strings.LOCALES` in `client/scripts/strings.gd`. British English (`en`) is
written by hand; US English is generated from it by a spelling table:
`python3 tools/english_us.py` (it also covers `server/src/words.json`).
Non-English content names hold the English text for now.

To add a string: add a row to `strings.csv` with every column filled (or the
English copied where no translation exists yet), run
`python3 tools/english_us.py`, and use the key from the script. Each of the
four generators has a `--check` mode, which `check_all.sh` runs. The tests
check every key a script asks for is in every language with the same
placeholders, and render every screen in a pseudo-locale that wraps every
catalogue string, so a word typed into a script shows up unwrapped.

## Accessibility checks

Built into the components and checked on every screen by
`client/tests/a11y_tests.gd`:

- every word against what is behind it, by WCAG 4.5:1 and by APCA, in normal
  and high-contrast modes (`client/ui/colour_check.gd`);
- the six school colours kept apart under simulated protanopia,
  deuteranopia and tritanopia;
- every screen laid out again at 150% and 200% text, in every language;
- nothing carried by colour alone; every control named for screen readers;
- left-handed mirroring, the hold time, reduced motion, haptics, banners.

The full list of what the client does for seeing, hearing, moving and
understanding is in
[`client/README.md`](../../client/README.md#how-it-is-built) under
"Accessibility". What only a phone can check (VoiceOver, TalkBack, the
vibrator) is not covered here.

## Budgets

The phone budget (§21.3): a realm 25,000–40,000 triangles on the home camera,
up to about 60,000 in a heist, under 150 draw calls, no full-screen
post-processing. Checked by:

| Where | What |
|---|---|
| `client/tests/world_tests.gd` | a heist realm within the triangle and draw-call budget (an outline pass counts as a second call) |
| `client/tests/kit_tests.gd` | buildings 2,000–8,000 triangles; a realm under 40,000 in few merged meshes |
| `client/tests/creature_tests.gd` | each character at most 6,000 triangles |
| `client/tests/shots/heist_budget.gd`, `look_budget.gd` | draw calls and triangles measured on the real renderer, through `shoot.sh` |

Tracks record measured draw calls per screen in their notes (for example the
table in [`docs/art/tracks/T6.md`](../art/tracks/T6.md)).

## Where things are

The directory map is the "Layout" section of
[`client/README.md`](../../client/README.md#layout). The UI kit (tokens, the
`rb_box` shader, typefaces, icons, components) is `client/ui/`, documented in
[`docs/art/tracks/ui-kit.md`](../art/tracks/ui-kit.md); the typefaces and
their licences are in [`client/ui/fonts/LEDGER.md`](../../client/ui/fonts/LEDGER.md).
