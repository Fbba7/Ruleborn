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

## How it is built

One direction for data, one job a layer, so a defect is found by asking
which layer's job it was. The shape is the one mobile clients converge on
(unidirectional data as Redux and The Composable Architecture do it, with
repositories in front of the network), in Godot's own terms:

| Layer | Where | Its one job | Tested |
|---|---|---|---|
| Views | `scenes/`, `scripts/*_screen.gd` | Draw what they are given and send taps and buttons on; hold no state that outlives them and call no network | the layout, size and catalogue checks on every screen |
| Controllers and presenters | `features/<feature>/` | Turn taps into commands and state into what a view shows, with no nodes | headless, by calling them (`HeistController`) |
| The store | `core/store.gd`, `app/app_state.gd` | Hold the app's state in slices, changed only by an action a reducer owns; log every action | headless (`tests/core_tests.gd`) |
| Repositories | `data/repositories/` | The only code that calls server/, one per area, each call a `Result` | against a `FakeTransport`, and end to end against the real server |
| The outbox | `data/outbox.gd` | §24.12's queue: a heist's or a Workshop play's replay, and a store receipt, kept until the server has answered | headless: offline, a restart, a refusal, a 5xx |
| The API and transport | `data/api.gd`, `data/*_transport.gd` | HTTPS only, a bearer token, the server's refusal reason as the failure code | headless |
| Services | `app/services.gd`, `app/app.gd` | Build everything once (the composition root); a test builds its own with fakes | by every test |
| The look | `ui/tokens.json`, `ui/tokens.gd`, `scripts/ui.gd`, `scripts/palette.gd` | Every colour, size and timing, cited; the components built from them | the token check |

**Where the design lands.** Claude Design's tokens replace `ui/tokens.json`
and its components replace `scripts/ui.gd`'s; no screen names a colour or a
size of its own.

**Finding a defect.** Every failure is one code — the server's own refusal
reason, or the client's (`unreachable`, `timeout`, `malformed_response`) —
shown to the player in words (`core/errors.gd`) and written to the action
log with the route it came from, never a token. The log holds the last 64
actions and failures, so a report carries the steps that led to it.
`tools/client_contract.py` fails the build if the client calls a route the
server does not serve, or if a code the server can refuse with has no words.

**Online first, offline the exception** (G41, as the owner answered). Every
call signs in by itself when there is no session, and signs in again once
when the server refuses an expired one (`Api.reauth`). While online the
phone keeps three leases in stock with their islands (`data/lease_stock.gd`).
A heist started with no network says going online is recommended — a heist
played now counts only once the server confirms it — and plays a stocked
lease only if the player chooses to. Its replay goes into the outbox before
it is sent, and the result shows the phone's own check, marked as confirming
(§24.12). What waited is sent by itself when the network is back, from home
or the next heist, with a banner saying so; one result the server cannot
decide now waits without holding up the rest, and the server answers a
repeat from its first decision, so nothing is paid twice.

**Accessibility (§20.8, §21.8, §21.10).** Built into the components, so
every screen and Claude Design's components inherit it, and checked on every
screen by `tests/a11y_tests.gd`:

- *Seeing.* Text size to 200% (Settings), body text scaling in full and
  titles only until body text reaches them; buttons wrap their words past a
  width and rows wrap onto more lines, and every screen is laid out again at
  150% and 200% in both languages against §21.1's rules. A high-contrast mode
  (`color_high_contrast` in the tokens), on at first launch if the phone's
  own setting is. Every word on every screen is checked against what is
  behind it by WCAG's 4.5:1 and by APCA's perceptual model, in both modes
  (`ui/colour_check.gd`). The six school colours are simulated for the three
  common forms of colour blindness and must stay apart, and each school has a
  shape. Nothing is carried by colour alone: a ward is drawn as its school's
  shape, a guard's state has a mark (? ?? ??? !), a crew member has its
  role's letters, a status leads with a glyph (✓ ! ⓘ …), the chosen crew
  member is said in words. §21.8's alarm red and success green are too light
  to carry words at 4.5:1, so words in them use deeper shades (D72).
- *Hearing.* Nothing is carried by sound: the client has no sounds yet, and
  every cue it has is visual, with a haptic form (§21.8's four patterns, in
  `app/haptics.gd`). Three volumes, music apart from alerts.
- *Moving.* One finger, taps only; nothing is held, so there is no hold time
  to adjust. The hand's controls mirror for left-handed play. A rehearsal —
  the player's own island, raided from the builder — pauses at any time and
  runs at 75% on request.
- *Understanding.* Banners lead with their glyph and stay until dismissed if
  the player chooses.
- *Comfort.* Reduced motion, on at first launch if the phone's setting is;
  nothing flashes or shakes.
- *Screen readers.* Godot 4.5's AccessKit support: every control has a name
  in words (a symbol button says what it does), banners announce themselves,
  and the realm is described in words.
- *Grayscale (§21.10).* Every feature that changes a route, and water, is
  edged in ink, 3:1 against the ground by value.

What only a phone can check — VoiceOver and TalkBack reading the screens in
order, the vibrator's patterns — is the device matrix's (§26.8).

## What is here

Twelve screens, opened from `scenes/home.tscn`:

**The age check** (`scenes/age.tscn`, §20.1). At first launch, before
anything else: the platform is asked for the player's age band, and — its
age-range services not being in this build — the player is asked, neutrally,
once: under 13, 13 to 15, 16 or 17, 18 or older. Under 13, the game says it
is for 13 and up and no account is ever made; the question is not asked
again. The answer is kept on the phone (`data/age_check.gd`), no sign-in
happens before it, and it reaches the server with the first sign-in
(`PUT /v1/age`), which until then holds the account to the most protective
band.

**Home.** Play a heist, fixed at the bottom where the thumb rests, and every
other screen in a list that scrolls at large text.

**The season track** (`scenes/track.tscn`, §18.2, §18.8). Stars in hand, the
next tier and its price, a claim, and all fifty tiers with what the free and
premium tracks give; the season's premium track offered at its price.

**The shop** (`scenes/shop.tscn`, §19.12, §20.2, §22.1, F41). The wallet's
Starlight and Essence, each cosmetic at its money price — the store's own
price when the store gives one, the server's euros otherwise, written the
player's way — with Buy, Give and Wear, the month's spending and a minor's
cap; everything owned, bought or earned, to wear — an outfit by a crew
role, a law's visual by a law — and gifts to a chosen friend. The flows live
on Services, so leaving the screen mid-purchase loses nothing. A purchase is
the server's intent first (the cap holds before the store
takes money), then the platform store (`app/store_purchases.gd`; the
platforms' billing plugins are not in this build, which refuses and says so),
then the receipt through the outbox, kept until the server has decided it —
a 5xx, the store unreachable from the server, keeps it too (D67).

**The league and crews** (`scenes/social.tscn`, §17.1, §17.7, §18.1). The
league, division and Renown; the constellation, its members and roles, or
founding one named from the word lists; the crew, its invite, or starting
and joining one.

**Friends** (`scenes/friends.tscn`, §12.11, §17.6). Friends, the week's feed
of their heists, an invite to share and a code to accept, and a challenge
link to the player's island. Players are named "Keeper" and the first
letters of their account until the platforms' friend lists give their names.

**The Island Workshop** (`scenes/workshop.tscn`, §18.6, §18.7, §20.7). The
top, new and featured lists and the player's own, each island named in the
player's language from the word lists, with its realm level, completions,
remixes, ratings and maker; Play, Report with a reason, and Remix, and
Withdraw on the player's own, whose list shows their creator level. A player
aged 13 to 15 is shown the featured list only. A Workshop island is played
on the heist screen on the seed and clock its play was given, and its replay
goes through the outbox; the result says whether it cleared and counted, and
offers to rate it. A rehearsal that clears the player's own island offers to
publish it, named from the word lists. Remix makes the island the builder's
draft (`data/draft.gd`), and its publication names the original.

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

- **The store builds.** `export_presets.cfg` holds the Android and iPhone
  presets and `bash client/export.sh android|ios` builds each where its tools
  are: Android with the SDK and NDK (`ANDROID_HOME`, `ANDROID_NDK_HOME`), the
  iPhone on a Mac with Xcode (`RULEBORN_APPLE_TEAM_ID`; the team is never
  written into the preset). `bash client/export.sh check` runs anywhere: the
  simulation and extension compile for both phones' arm64, and the project
  exports with the Android preset, `pack_check.py` confirming the pack holds
  every file the game reads by path and no tests. The bundle identifier
  `app.ruleborn.client` is a stand-in until the stores' accounts exist.
  §24.7's spike — the extension loading on a real iPhone and Android — is the
  gate after that.
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

    project.godot           portrait, 1080 × 2340, the compatibility renderer;
                            GDScript warnings are errors (every declaration typed)
    ruleborn.gdextension    loads bin/libruleborn_godot.so, and each phone's arm64 build
    export_presets.cfg      the Android and iPhone exports; export.sh builds them,
                            pack_check.py checks what the pack carries
    ext/                    the extension: RulebornReplay and RulebornIsland, over sim/
    app/                    the composition root, the store's slices, the router
    core/                   Result, the store, the action log, failure words
    data/                   the API, transports, repositories, the outbox
    features/<feature>/     each area's state, controller and presenter: heist,
                            shop, social, workshop
    ui/tokens.json          the design tokens, each cited
    i18n/strings.csv        every word on screen, a column a language
    scenes/                 the screens: home, heist, result, replay, settings,
                            builder, track, shop, social, friends, workshop, age
    scripts/                the screens, the realm view and heads-up display,
                            the shared UI pieces, the palette, the string catalogue,
                            the saved settings
    tests/run.gd            headless tests, TAP; tests/core_tests.gd, the layers'
    tests/screenshot.gd     a still, under a virtual display
    build.sh, status.py     build, test, write status.json
