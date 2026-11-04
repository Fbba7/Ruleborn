# The 60 icons first made in the toon route

Owner: AIA-2. The icons are named `group/name`, as in `client/ui/icons/manifest.json`
(the diorama icons they replace). The one exception is `crew/`: character
badges, which have no diorama icon. They are ordered by how often a player
sees them: the heist first (its controls, and the currencies it pays out),
then its status, then rewards, then navigation. "256" marks an icon that is also
baked to `icons_256`, the large reward size. Every icon is baked to `icons_48`.

Batches 3 and 4 are deferred (D13 (c)). The lead opens them.

## Batch 1: heist controls and currencies

### 1a: the heist's controls (P1-AIA2-icons-1a)

| # | Icon | Object |
|---|---|---|
| 1 | heistcontrols/cast | the Sage's wand casting a spark |
| 2 | heistcontrols/getout | an open door and the escape arrow |
| 3 | heistcontrols/ability | the crew member's ability burst: a bolt and a flare |
| 4 | heistcontrols/aim | a crosshair ring |
| 5 | heistcontrols/regroup | three crew pips drawn together round a flag |
| 6 | heistcontrols/splitcrew | three crew pips fanned apart on a three-way fork |
| 7 | heistcontrols/callskiff | the skiff with a call ring |
| 8 | heistcontrols/sagewheel | the Sage's power wheel, as a helm in the six school colours |

### 1b: currencies and resources (P1-AIA2-icons-1b)

| # | Icon | Object | 256 |
|---|---|---|---|
| 9 | resources/starlight | two struck gold stars (proof, baked) | 256 |
| 10 | resources/aether | a cloud vial | 256 |
| 11 | resources/essence | a drop of the essence green | 256 |
| 12 | resources/renown | a laurel medal | 256 |
| 13 | currencies/starglass | a cut star gem in the toon light | 256 |
| 14 | currencies/insight | an eye lens | 256 |
| 15 | currencies/seasonstars | a cluster of season stars | 256 |

## Batch 2: heist status and rewards

### 2a: what the heist shows while it runs (P1-AIA2-icons-2a)

| # | Icon | Object |
|---|---|---|
| 16 | heiststatus/lootbag | the loot sack, tied |
| 17 | heiststatus/clock | a pocket clock |
| 18 | heiststatus/bagcapacity | a sack with its fill line |
| 19 | heiststatus/alarm | a ringing bell |
| 20 | heiststatus/spotted | an open eye with a flash |
| 21 | heiststatus/vaultprogress | the vault door, a ring of progress |
| 22 | hud/shield | a rounded shield |
| 23 | hud/strain | a cracked gauge |

### 2b: rewards (P1-AIA2-icons-2b)

| # | Icon | Object | 256 |
|---|---|---|---|
| 24 | currencies/pages | a stack of codex pages | 256 |
| 25 | season/tierreward | a ribboned reward chest | 256 |
| 26 | alerts/seasonreward | the season chest, open | 256 |
| 27 | hud/star | a single gold star | |
| 28 | heistoutcomes/clean | a clean-heist seal | 256 |
| 29 | heistoutcomes/worthyourtime | a full sack with a star | 256 |
| 30 | crew/pip | Pip's badge, a render from the portrait studio (proof, baked) | |

## Batch 3: navigation (deferred)

| # | Icon |
|---|---|
| 31 | tabs/islands |
| 32 | tabs/codex |
| 33 | tabs/heist |
| 34 | tabs/crew |
| 35 | tabs/friends |
| 36 | generalui/back |
| 37 | generalui/close |
| 38 | generalui/settings |
| 39 | generalui/confirm |
| 40 | generalui/cancel |
| 41 | generalui/info |
| 42 | generalui/lock |
| 43 | hud/home |
| 44 | hud/next |
| 45 | hud/prev |

## Batch 4: the rest of the most-seen icons (deferred)

| # | Icon |
|---|---|
| 46 | hud/compass |
| 47 | hud/plus |
| 48 | hud/crew |
| 49 | hud/warning |
| 50 | hud/play |
| 51 | hud/collectall |
| 52 | generalui/more |
| 53 | generalui/search |
| 54 | generalui/new |
| 55 | generalui/timer |
| 56 | generalui/levelup |
| 57 | generalui/help |
| 58 | crewroles/warden |
| 59 | crewroles/breaker |
| 60 | crewroles/scout |

The order was checked against how often the client's scripts name each icon
(`generalui/lock` 10 times, `crewroles/warden` 8, `generalui/back` and
`hud/shield` 7, and so on, counted on 4 November 2026). It was then
reordered so that the heist and its rewards come first, as the task asks.
