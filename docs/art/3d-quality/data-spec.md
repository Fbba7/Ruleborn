# What the extension hands the 3D (the data spec)

The data track's phase 0 deliverable for the 3D quality plan
([`plan.md`](plan.md), phase 0, step 5, and section 9). It lists every
field the plan's screens need from the extension (`client/ext/src/lib.rs`,
the class `RulebornReplay`), with its type, where the simulation computes
it and what reading it costs.

This spec is **frozen at the end of phase 0.** Phase 1 builds against it.
How it may change after that is in "Freeze rules", at the end.

## Contents

1. Where the fields come from
2. Guards (phase 0: done)
3. The six states and the meter
4. What the screen already has
5. Phase 1 additions: sight on the ground
6. Phase 1 additions: noise
7. Phase 1 additions: order previews
8. Costs, measured
9. Freeze rules
10. Who reads what

## 1. Where the fields come from

Every field below is read from the simulated world (`sim::World`) by the
extension at the moment the client asks. Nothing is stored for the screen,
and nothing is written back into the world.

- **The world read.** Every function reads `w()`: the world of the realm
  the crew is in during a crossing, or the heist's own world otherwise.
- **Units.**
  - Positions and distances are in tiles. One tile is one metre (§21.1).
    They are converted from the simulation's fixed point (`Fx`, 32
    fractional bits) by `tiles()`.
  - Angles are in radians, converted by `radians()`.
  - Tile indices are row-major, `y * width + x`, over `size()`.
- **The replay does not change.** The stored replay (`Heist::encode`,
  `sim/src/replay.rs`) holds the seed, the island digest, the rules
  version, the ticks, the crew, the commands, the era data and one checksum
  a second. It holds no guard and no tile state, so a field the screen reads
  cannot change it. The test
  `reading_the_guards_every_tick_leaves_the_replay_byte_for_byte`
  (`client/ext/src/lib.rs`) shows this for `guards()`:
  - it reads every guard every tick of a recorded heist;
  - it records the replay;
  - it compares the bytes with a golden pinned from main's code before this
    change: 697 bytes, SHA-256 `afc82a08…d4e179a8`.

## 2. Guards (phase 0: done)

`guards() -> Array[Dictionary]`: one dictionary per guard, in the world's
guard order. That order is stable for the whole heist, so the array index is
the guard's index for `seen(index)` and for every per-guard function below.

| Key | Type | Meaning | Sim source | New in phase 0 |
|---|---|---|---|---|
| `at` | Vector2 | Where it stands, in tiles | `Guard.at` | |
| `facing` | float | The way it faces, in radians | `Guard.facing` | |
| `cone` | float | The cone's whole arc, in radians | `Guard.cone` | |
| `near` | float | Near zone's reach, in tiles | `Guard.near` | yes |
| `mid` | float | Mid zone's reach, in tiles | `Guard.mid` | yes |
| `far` | float | Far zone's reach, in tiles; 0 for a role with no far zone | `Guard.far` | |
| `peripheral` | float | The corner of the eye's whole arc, in radians | `Guard.peripheral` | yes |
| `suspicion` | int | The meter, 0 to 1000 | `Guard.suspicion` | yes |
| `state` | String | One of the six states, by name | `Guard.state` (`sim::guard::State`) | |
| `down` | bool | Knocked out | `Guard.knocked_out` | |

The three ranges are the guard's **base** reach, before laws, light and
height scale them. A screen that draws zones on the ground uses the
per-tile zones of section 5, not these radii. The radii are for a cheap
outline: the thin cone for the guards that are not chosen (plan, direction
E).

**Cost:** one pass over the guards, one dictionary each. Nothing is
computed: every value is a field the simulation already holds.

**Shown working:**
- **The test.** The replay test above.
- **The shot.** `client/tests/shots/heist_suspicious.gd` plays the island
  fixture until a guard is Suspicious. It prints that guard's dictionary,
  then renders the moment with each guard's state over its head. It fails
  if no guard turns Suspicious within 900 ticks, or if the meter reads
  under 200. It printed:

  ```
  tick 69 guard 0 {"at": (6.5, 4.5), "facing": 1.5708, "cone": 0.785, "near": 2.0,
  "mid": 4.0, "far": 6.0, "peripheral": 1.92, "suspicion": 204, "state": "Suspicious",
  "down": false}
  ```

  At that moment guard 1 reads Investigating. The trial of plan section 9
  saw `suspicion` only at 0, so this is the first moment the meter is shown
  above 0.

## 3. The six states and the meter

The screen draws all six states (plan, direction E). It needs no new field
for them, but it does need the rules below, so that the meter and the icons
agree with what the guard does. Every value is a constant in
`sim/src/lib.rs` or `sim/src/guard.rs`. The screen reads them from this
table and does not compute them: they change only with a rules version, and
then this table changes with them.

**The states:**

| `state` | Enters when | Meter |
|---|---|---|
| `Unaware` | The start, or after `Returning` | Under 200 |
| `Suspicious` | The meter reaches 200 (`SUSPICIOUS_AT`) | 200 to 599 |
| `Investigating` | The meter reaches 600 (`INVESTIGATING_AT`), **or the guard hears a sound**, or the crew lands within earshot | Any; hearing sets no minimum |
| `Alerted` | The meter reaches 1000 (`ALERTED_AT`, also `SUSPICION_MAX`), or the alarm spreads to it | 1000 |
| `Searching` | It loses an Alerted target; lasts 600 ticks (`SEARCHING_TICKS`) | Falling |
| `Returning` | The search ends; it walks back to its post | Falling |

**The meter's rates:**

- **How it fills.** Per tick, by zone: 67 near, 33 mid and 12 far
  (`FILL_NEAR`, `FILL_MID`, `FILL_FAR`). Then:
  - a crouched crew member fills it at ×1/2, a running one at ×7/4;
  - an unlit tile, ×1/2;
  - the corner of the eye, ×1/2;
  - Scree within 4 tiles, faster;
  - laws (`SuspicionFill`) scale it.
- **How it falls.** By 20 a tick (`DECAY_PER_TICK`), halved from alarm
  level 1.
- **Holds.** A state that falls waits 15 ticks first (`guard::HOLD_TICKS`);
  a rising one changes at once.

**Two consequences for the screen:**

- **A meter can skip Suspicious.** Hearing, a landing within earshot and a
  near-zone rush all reach Investigating without passing through it. The
  screen must not animate the meter "through" Suspicious to get there.
  This is why the shot walks the crew into the far zone.
- **The state is not a function of the meter.** A Searching or Returning
  guard can read any value. The icon follows `state`; the meter follows
  `suspicion`.

## 4. What the screen already has

These functions are not new, and phase 1 keeps them as they are. They are
listed so the spec is the one place to look.

**Per tile, row by row** (one entry per tile, read once a heist unless
noted):

| Function | Type | Meaning | Sim source | Cost |
|---|---|---|---|---|
| `size()` | Vector2i | Grid width and height | `Grid.width`, `Grid.height` | O(1) |
| `features()` | PackedByteArray | 0 open, else 1 + `sim::grid::Feature` code | `Grid::feature` | O(tiles) |
| `facings()` | PackedByteArray | 0 N, 1 E, 2 S, 3 W, 255 none | `Grid::facing` | O(tiles) |
| `surfaces()` | PackedByteArray | 0 plain, 1 gravel, 2 water, 3 moss | `Grid::surface` | O(tiles) |
| `heights()` | PackedByteArray | Height in levels | `Grid::height` | O(tiles) |
| `walls()` | Array[Vector2i] | Crystal walls up **this tick** | `Grid::is_raised` | O(tiles) |
| `tunnels()` | Array[Vector2i] | Mouth pairs, the lower first | `Grid::tunnel_exit` | O(tiles) |

**Per actor, each tick:**

| Function | Type | Keys | Sim source | Cost |
|---|---|---|---|---|
| `crew()` | Array[Dictionary] | `at` Vector2, `role` String, `carried` int, `carry` int, `health` int, `standing` String (Active, Down, Caught, Out, Gone), `gait` String (Walk, Crouch, Run), `kind` String, `uses` int, `ready` bool | `World.raiders` | O(crew) |
| `guards()` | Array[Dictionary] | Section 2 | `World.guards` | O(guards) |
| `wards()` | Array[Dictionary] | `at`, `kind`, `level`, `live` | `World.wards` | O(wards) |
| `pylons()` | Array[Dictionary] | `at`, `standing`, `law`, `school` | `World.laws` | O(laws) |
| `vault()` | Dictionary | `at`, `health`, `exposed`, `open` | `World.vault` | O(1) |
| `alarm()` | int | Alarm level, 0 to 6 | `World.alarm` | O(1) |

**Sight and noise today:**

| Function | Type | Meaning | Sim source | Cost |
|---|---|---|---|---|
| `seen(index)` | PackedInt32Array | Tile indices guard `index`'s cone reaches: walls, height and laws included, the corner of the eye left out; empty for a sleeping or stunned guard | `World::seen_tiles` | O(tiles × sight line); 9.9 µs a guard (section 8) |
| `landing_reach()` | int | Walked tiles a landing is heard across | `World::landing_reach` | O(1) |
| `landing_marks()` | Array[Dictionary] | `at`, `covered`: whether a landing there goes unheard, from the terrain alone | `Island::landing_covered` | O(edge tiles) |

## 5. Phase 1 additions: sight on the ground

Direction E draws three zones for the chosen or nearest guard, and shows
hiding places and unlit tiles. `seen(index)` gives one set of tiles, with no
zones. The base radii of section 2 are not what decides: laws scale the
zones, light bands double or halve them, higher ground stretches the far
zone and lower ground removes it. These rules are private to the simulation
today. So the screen needs them per tile, from the simulation, the way
`seen()` does.

### `zones(index) -> PackedByteArray`

One byte per tile, row by row, for guard `index`:

- **Bits 0 and 1, the zone:** 0 not seen, 1 near, 2 mid, 3 far.
- **Bit 2:** set when the tile is seen only from the corner of the eye,
  at half the fill rate.

It is empty for a sleeping or stunned guard, or an index out of range.

- **Sim source.** A new pub `World::sight_zones(gi) -> Vec<u8>` in
  `sim/src/lib.rs`. It puts each tile's centre through the same geometry
  `noticed()` uses: `sees_geometry`, `below_sight`, `line_clear`,
  `sight_at` and `outer_zone`.
  - The zone tests move out of `noticed()` into one private helper that
    both call, so the drawing cannot disagree with the rule. This is the
    same promise `seen_tiles` makes.
  - The tiles with a non-zero zone and bit 2 clear must equal
    `seen_tiles(gi)`; a sim test asserts it.
- **What it does not include.** The crew-dependent hides, which depend on
  who stands where: Stillness, a still crew member in tall grass or a bush,
  Mirage, a tunnel. They are the cover flags below.
- **Cost.** Section 8. About the cost of `seen()`, which it replaces for
  the chosen guard. Called for one guard, on a change of guard or of tick
  group, not every frame.

### `cover() -> PackedByteArray`

One byte of flags per tile, row by row, **this tick**:

| Bit | Set when | Sim source |
|---|---|---|
| 0 | Unlit: the fill is halved | `World::unlit(tile) && !World::lantern_lit(tile)` |
| 1 | Lit by a lantern post: nothing hides there | `World::lantern_lit` |
| 2 | Hides a still crew member: tall grass, a bush with one crew member | `Grid::feature` |
| 3 | Hides anyone beyond some tiles: a thicket, a shade canopy, steam | `Feature::hides_beyond` |

- **Why the simulation.** "Unlit" changes with the tick: Flicker's bright
  and dark seconds, Tempest's lightning and the bands of Northern lights.
  The client cannot know it from `features()`.
- **The hide distance** for bit 3 is `hides_beyond()` less
  `World::hiding_tiles()` (the Hush harmony and Iron bell), so a phase 1
  key gives it per tile only if the markers track asks for it. The default
  is the flag alone.
- **Sim source.** A new pub `World::cover_tiles() -> Vec<u8>`, made public
  over the existing private `unlit` and `lantern_lit`.
- **Cost.** O(tiles × lanterns), once a tick group.

## 6. Phase 1 additions: noise

Plan section 14 leaves "how noise should reach the client" to this spec.
The decision is below.

### What decides how far a sound carries

The noise phase (`World::phase_noise`, `sim/src/lib.rs`) computes a reach in
walked tiles for each crew member that makes a sound this tick.

1. **The sound.**
   - A break is 5 m, a landing 2, 3 or 4 m, and a mushroom bounce its own.
   - Otherwise the gait: crouched 1 m, walking 2.5 m, running 4.5 m
     (`noise::Sound::half_metres`).
   - A dragged body is crouched; standing still is silent.
2. **What it is walked on.** Gravel and water carry further, moss less
   (`Surface::carry`).
3. **The laws.** The zoned `NoiseRadius` factor at the source tile.
4. **The alarm.** From level 2, 1 m further, except a crouched step on moss
   (`alarm_noise_extra`).
5. **Chords.**
   - Deep sleep takes steps off a footstep.
   - Iron bell adds 2 tiles.
   - Wild hunt silences running.
6. **Spreading.** `noise::field` spreads that reach over walkable tiles,
   breadth first, the way the crew walks.
7. **Hearing.** A guard standing on a reached tile hears it and turns along
   `noise::way_around`.

### The decision: the simulation computes it; the client draws it

- **What the client does not do.** It does not rebuild the reach from
  `landing_reach()` and `surfaces()`. That would copy seven rules into
  GDScript, and they would drift the first time a law changed.
- **What the client does instead.** It asks for the tiles a sound would
  reach, with the same function the noise phase uses.

**The simulation's side.** A new pub
`World::sound_reach(tile, sound) -> u16` in `sim/src/lib.rs`:

- It holds steps 2 to 5 above, moved out of `phase_noise` unchanged.
- `phase_noise` then calls it, so a preview and the real sound cannot
  disagree.
- Wild hunt's silence is a reach of 0.
- The golden replay tests (`cargo test` in `sim/`) must pass unchanged.
  That is the test that the move changed no rule.

**The extension's side:** `noise(x, y, gait) -> Dictionary`.

| Key | Type | Meaning |
|---|---|---|
| `reach` | int | Walked tiles the sound carries, from `sound_reach` |
| `tiles` | PackedInt32Array | Tile indices it reaches, from `noise::field` |
| `steps` | PackedByteArray | Steps to each of `tiles`, the same order, capped at 255 |
| `heard_by` | PackedInt32Array | Indices of the awake guards standing on a reached tile |

- **Arguments.** `gait` is 0 walk, 1 crouch, 2 run, as `give`'s gait
  command takes it. A tile off the grid or not standable gives `reach` 0
  and empty arrays.
- **Cost.** One `sound_reach` (O(1)) and one `noise::field`
  (O(reached tiles)): 1.0 µs on the example island (section 8). Cheap
  enough to call on every change of the order's target tile.
- **What it is for.** Direction F's "how far the noise will carry". With
  `x, y` at a crew member's tile and its gait, it is also the ring a
  running crew member leaves during play.

### A live key for guards that heard

Phase 1 adds `heard` to `guards()`: a Vector2i, the tile of the sound the
guard heard this tick, or absent. It explains a guard's turn toward a sound
on screen.

- **Sim source.** `Guard.heard`, private today. A pub getter
  `Guard::heard()` is the whole change.
- **Cost.** O(1) per guard.

## 7. Phase 1 additions: order previews

Direction F draws the path before an order is confirmed and marks where on
it the crew will be seen.

### `route(actor, x, y) -> Array[Vector2i]`

The tiles crew member `actor` would walk if ordered to `(x, y)` now, in
order, its own tile first. It is empty when there is no way there.

- **Sim source.** A new pub `World::route_for(ri, to) -> Vec<TileIndex>`.
  It holds the route choice that the `MoveTo` command makes today, moved
  out unchanged:
  - from the far mouth when the crew member is inside a tunnel;
  - `path::find_over_wall` while it holds a wall pass;
  - `path::find_through` otherwise;
  - no re-aiming of a target inside a wall.

  `MoveTo` then calls it, so the drawn path is the walked one. The golden
  replay tests must pass unchanged.
- **Cost.** One path search: O(tiles) at most.

### `foresee(actor, x, y, ticks) -> Dictionary`

What happens if `actor` is ordered to `(x, y)` now and the heist runs on
for `ticks` ticks with no other order.

- **How.** A dry run on a copy of the world: `World` is `Clone`. The
  extension:
  1. clones `w()`;
  2. gives the `MoveTo` on the copy;
  3. steps the copy up to `ticks` times;
  4. after each step, asks `World::noticed(gi, actor)` for every guard;
  5. drops the copy.

  The heist's own world, its command log and its replay are never touched.
  The answer is exact: the copy runs the same rules, guard turns and
  routes, and the simulation is deterministic.

| Key | Type | Meaning |
|---|---|---|
| `seen_tick` | int | Ticks from now until a guard first notices the crew member, or -1 |
| `seen_at` | Vector2i | The tile it is noticed on (from `noticed`), absent if `seen_tick` is -1 |
| `seen_by` | int | That guard's index, absent if `seen_tick` is -1 |
| `heard_tick` | int | Ticks from now until a guard first hears it (`Guard::heard()`), or -1 |
| `arrives` | int | Ticks from now until it stands on `(x, y)`, or -1 within `ticks` |

- **The limit.** `ticks` is capped at 300 (10 seconds). The run stops early
  once all of `seen_tick`, `heard_tick` and `arrives` are known.
- **Cost.** One clone (0.6 µs) plus up to `ticks` steps (2.3 µs each), on
  the example island (section 8): about 0.7 ms at the cap.
  - That is too much for every frame, and enough for every change of the
    target tile.
  - The markers track calls it on that change, not per frame.
  - Larger islands scale with tiles and actors. Phase 1 measures it on the
    pilot realm's largest island before relying on it.
- **Why a dry run, not a formula.** The moment of being seen depends on
  guards turning, patrolling and hearing while the crew walks. A formula
  over today's cones would be wrong as soon as a guard moves. The dry run
  is right by construction and needs no new rule in the simulation.

### Not added: the reasons for being seen

`Guard.interest` (the tile it investigates) and `Guard.saw` (whether it saw
the crew this tick) are public in the simulation. The markers can use them
for "why" marks, but no screen of the plan draws them yet. They are not
added. When a phase 1 task asks for them, they are additive keys of
`guards()`: `interest` Vector2i, absent if none, and `saw` bool.

## 8. Costs, measured

These were measured on this container on 25 November 2026:

- **The build.** The simulation in release, a temporary benchmark (not
  committed).
- **The island.** The example island: 144 tiles and 2 guards.
- **The heist.** A crew of 3, stepped 3000 ticks with no orders.

| Operation | Time | Used by |
|---|---|---|
| `World::step`, one tick | 2.3 µs | `foresee` |
| `World::clone` | 0.6 µs | `foresee` |
| `World::seen_tiles`, one guard | 9.9 µs | `seen()`, `zones()` |
| `noise::field`, reach 20 | 1.0 µs | `noise()` |

**Caveats:**

- **The real build is slower.** The extension adds the dictionary building
  and the GDScript boundary on top: O(entries), small next to the above.
- **Islands vary in size.** A realm's heist island is larger than the
  example. Every cost above is linear in tiles, except `seen_tiles`, which
  is tiles × sight line. Phase 1's first task on `zones()` and `foresee()`
  re-measures them on the pilot realm's largest island, in the client's
  build.

## 9. Freeze rules

From the end of phase 0:

- **Additive only.** A key or a function is added; none is renamed, retyped
  or removed. A consumer that ignores an unknown key keeps working.
- **No change to the stored replay.** No field of this spec is written into
  `Heist`. A function that needs the future copies the world (`foresee`),
  and never steps or gives orders to the heist's own world.
- **Moves, not new rules.** Every sim change named here moves existing code
  into a pub function and calls it from where it was:
  - `sight_zones` and the zone helper;
  - `cover_tiles`;
  - `sound_reach`;
  - `route_for`;
  - `Guard::heard()`.

  The simulation's golden replay tests and the extension's byte-for-byte
  test must pass unchanged on each.
- **A new need is a request.** A track that needs a field not listed sends
  a request to the data track, which adds it here first and then in the
  code.
- **Units stay.** Tiles, radians, row-major indices, and states by their
  `sim::guard::State` name.

## 10. Who reads what

| Function | Read by | For |
|---|---|---|
| `guards()` | Markers and stealth (`fx_*.gd`, `overlay_hud.gd`); camera and framing (`world_view.gd`, nearest guard) | Meter, state icon, thin cone, framing rule |
| `zones(index)` | Markers and stealth (`fx_ground.gd`) | The three zones of the chosen guard |
| `cover()` | Markers and stealth (`fx_ground.gd`) | Hiding places and unlit tiles |
| `noise(x, y, gait)` | Markers and stealth (`fx_*.gd`) | How far an order's noise carries |
| `route(actor, x, y)` | Markers and stealth (`fx_*.gd`), with `world_view.gd` for input | The order's path |
| `foresee(actor, x, y, ticks)` | Markers and stealth (`fx_*.gd`) | Where on the path the crew is seen |
| `seen(index)` | Kept for current users; `zones()` replaces it for drawing | — |
