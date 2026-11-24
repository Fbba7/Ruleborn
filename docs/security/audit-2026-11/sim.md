# Simulation audit, November 2026

The simulation half of the fix wave's extra checks
([bug report](../bug-report-2026-11.md), task FX3-5-audit-sim). It covers
the code the report did not read: `sim/src/ffi.rs`, `lib.rs` beyond the
paths the report proved, `path.rs`, `stability.rs`, `events.rs`, `guard.rs`,
`sight.rs`, `era.rs`, `rng.rs`, `fixed.rs`, `noise.rs`, `combos.rs`,
`reference.rs`, `ruleborn.rs`, the bins and the Python tools in `sim/`. It
also settles the report's five sim suspicions ("Still not read", `ffi.rs`,
`island.rs` and `grid.rs`).

**The proof rule.** A finding is **confirmed** only when a test fails on
main (`f32be7db`, the branch point after the tests were committed). Each such
test stays in the suite, marked in a comment with its finding id
(`// Audit finding SIM-N`), and passes once the fix is in. No test was
skipped or loosened. Anything not proven that way is listed under
"Unproven", with what was tried.

All nine findings are fixed on `claude/fix-sim` (commit `f08f52b9`). After
the fixes, `cargo test --release` passes 358 of 358, the five goldens
still verify, and native and WebAssembly agree at all five seeds.

## Summary

| ID | Priority | Category | Location | Title |
|---|---|---|---|---|
| SIM-1 | Medium | backend (simulation) | `sim/src/lib.rs World::sees_body` | A knocked-out guard in a bush or thicket is found as if in the open |
| SIM-2 | Medium | frontend-backend contract | `sim/src/ffi.rs rb_record*` | The recorders return replays over 2 KB, which `rb_verify` then refuses |
| SIM-3 | Medium | tooling (gate) | `sim/no_floats.py` | The float ban lets `1f64`, `1e3`, `1_000.5`, `1.`, and floats after a `"//"` or on a `*p =` line through |
| SIM-4 | Medium | tooling (gate) | `sim/status.py tests()` | The gate counts only `tests::` and ignores cargo's exit code, so stability's tests can fail unseen |
| SIM-6 | Medium | backend (simulation) | `sim/src/lib.rs World::charge` | A Rambler's charge through a Crystal Wall ignores Cracked gardens and Shattered glass |
| SIM-5 | Low | backend (simulation) | `sim/src/lib.rs World::step` | The Hourkeeper's rewind loses a hit taken in a tick the ally was healed |
| SIM-7 | Low | backend (simulation) | `sim/src/lib.rs World::raise_wall` | A Prism half that has folded back still blocks the Glass golem's wall |
| SIM-8 | Low | backend (simulation) | `sim/src/lib.rs World::fire_ward` | A Gravity Well cuts a Time Snare's freeze short |
| SIM-9 | Low | backend (simulation) | `sim/src/lib.rs World::bounce` | A bounce mushroom never lands a crew member on a bridge |

No High was found. The Mediums change a heist's result, which the server
then agrees with because it runs the same simulation (SIM-1, SIM-6). Or they
refuse an honest player (SIM-2), or they let the gate pass what it exists to
refuse (SIM-3, SIM-4).

## Medium

### SIM-1: A knocked-out guard in a bush or thicket is found as if in the open
- **Priority / category:** Medium / backend (simulation).
- **Where:** `sim/src/lib.rs` `World::sees_body`, line 2366. Only tall grass
  was tested (`Some(Feature::TallGrass) if from != to => return false`).
  Compare `noticed`, lines 2278-2300, which applies every hiding feature to a
  still crew member.
- **Input:** a guard knocked out on a tile with a bush (or a thicket three
  tiles from a guard who can see that tile), and no crew member on the tile.
- **Should happen:** §12.8 (v3.3): "a body is seen exactly as a still crew
  member lying on its tile would be, so tall grass, a bush, fog or a tunnel
  hides it". A bush hides a lone still crew member, and a thicket hides
  anyone beyond 1 tile. So neither body is found.
- **Happens:** the guard finds the body in its first second, and
  `knockouts_discovered` rises. That raises the alarm (§12.9). The same gap
  covers every feature with a `hides_beyond` distance. A lit lantern also
  failed to reveal a body in tall grass, though `noticed` lets it reveal a
  crew member there.
- **Proof:** `sim/src/tests.rs`, `sim_1_a_body_in_a_bush_is_not_found` and
  `sim_1_a_body_in_a_thicket_beyond_a_tile_is_not_found`. Both fail on main
  (`found` is true).
- **Fix (applied):** `sees_body` applies `noticed`'s feature rows to the
  body's tile, unless a lantern lights it:
  - tall grass from another tile;
  - any `hides_beyond(n)` feature beyond `n`;
  - a bush with no active crew member in it.

  Only the bush and the thicket have tests. The lantern part follows
  `noticed`'s code and has no test of its own.

### SIM-2: The recorders return replays over 2 KB, which `rb_verify` then refuses
- **Priority / category:** Medium / frontend-backend contract.
- **Where:** `sim/src/ffi.rs`, `rb_record_drawn` line 359, `rb_record`
  line 406 and `rb_record_crew` line 456: `if bytes.len() > BUFFER_BYTES`.
  `rb_verify` refuses anything over `MAX_HEIST_BYTES` (2048) with -9, and the
  server answers `too_large`.
- **Input:** an honest 3-minute heist on `Island::example_open()` with a
  landing and 180 move orders (one every 1.2 s), recorded through
  `rb_record`.
- **Should happen:** the recorder either returns a replay the verifier
  accepts, or refuses it at once (-9). The simulation itself accepts the log
  (`verify_on` is `Ok`).
- **Happens:** `rb_record` returns a 2,131-byte replay. Its only limit was
  the 64 KB shared buffer. `rb_verify` refuses that replay with -9. On the
  server a `too_large` refusal counts toward the day's `MAX_REFUSALS_A_DAY`,
  though the player did nothing wrong.
- **Proof:** `sim/src/tests.rs`,
  `sim_2_the_recorder_never_returns_a_replay_over_2_kb`, which fails on main
  ("rb_record returned a 2131-byte replay (limit 2048) that rb_verify
  refuses with -9").
- **Fix (applied):** the three recorders compare against `MAX_HEIST_BYTES`
  and return -9, as `rb_verify` does.
- **Not fixed here (outside this task's files):** the device's recorder
  (`client/ext/src/lib.rs` `record()`) and `World::give` have no cap of
  their own. A long, busy heist on a device can still produce a replay the
  server refuses. Proposed fix: the client should stop accepting commands
  (or warn) when the encoded size nears 2048 bytes, using the same constant.

### SIM-3: The float ban lets several float literals through
- **Priority / category:** Medium / tooling (gate). §24.10: "The simulation
  refuses to compile if one appears."
- **Where:** `sim/no_floats.py`:
  - `BANNED` matches only `\d+\.\d+`;
  - `ALLOW`, line 42, skips any line starting `*`;
  - line 63 cuts at the first `"//"` before stripping strings.
- **Input:** a crate source containing any of these:
  - `1f64`, `1.5f32`, `1e3`, `2.5e-1`, `1_000.5` or `1.`;
  - `let s = "//"; let z = 1.5;`;
  - a deref assignment `*p = 2.5;`.
- **Should happen:** the script exits 1 and names the line.
- **Happens:** it exits 0 for all eight cases ("no floating point in 1
  source files").
- **Proof:** `sim/test_tools.py`, `float_ban()`: eight "refuses" checks fail
  on main. Six "allows" checks (section numbers in comments and strings,
  `0x1e3`, `0..5`, `t.0.1`, `1.max(2)`, `*p = 2`) pass both before and after,
  so the fix does not widen the ban onto code it must allow.
  `run_spike.sh` now runs `test_tools.py` before `status.py`, so the gate
  runs these checks.
- **Fix (applied):** three changes.
  - A float-literal rule covering suffixes, exponents, underscores and a
    trailing `.`. A `.` followed by a letter, `_` or another `.` is a method,
    a field or a range.
  - `ALLOW` no longer skips a `*` line that is an assignment.
  - Strings are stripped before the line is cut at `//`.

  The real crate still passes (26 files).

### SIM-4: The gate counts only `tests::` and ignores cargo's exit code
- **Priority / category:** Medium / tooling (gate).
- **Where:** `sim/status.py` `tests()`, line 38: the regex
  `^test tests::(\w+) …` with `check=False`.
- **Input:** a failing test in another module. The crate has seven in
  `stability::tests`, for example
  `stability::tests::strain_falls_in_5_5s_seven_bands`. Or cargo can fail
  outside a test line (a doctest, a link failure).
- **Should happen:** "A GATE FAILED".
- **Happens:** the failing test is not counted, and cargo's exit status is
  never read, so status.py prints "every gate holds". The audit task proved
  this by changing one band in `sim/stability_cases.json` (`"band": 0` to
  `5`). `stability_cases_match_the_file` failed, cargo exited 101, and the
  gate still held. The seven stability tests have never appeared in
  `status.json` or on the audit page.
- **Proof:** `sim/test_tools.py`, `test_count()`. It feeds `status.tests()`
  a cargo run with a failing `stability::` test, then one that exits 101
  with every line `ok`. Both checks fail on main.
- **Fix (applied):** `tests()` counts every test line under the name
  `module::name` (`tests::` keeps the bare name, so existing claims are
  unchanged). A non-zero exit adds a failed entry
  `cargo test exited N`. A new system in `sim/systems.json`,
  "Stability" (§5.5, TD.14), claims the seven `stability::` tests, so the
  bookkeeping check of `status.py` holds.

### SIM-6: A Rambler's charge through a Crystal Wall ignores Cracked gardens and Shattered glass
- **Priority / category:** Medium / backend (simulation).
- **Where:** `sim/src/lib.rs` `World::charge`, lines 4238-4251. The other
  ways a Crystal Wall breaks (attacks, `hit_ward`) apply both resonances.
  The charge subtracted its damage and cleared the tile with neither.
- **Input:** a Crystal Wall in the Rambler's charge path, with either:
  - Brittle stone and Bloom woven (Cracked gardens), and the wall at 1
    health;
  - Glass and Brittle stone woven (Shattered glass), and the wall at full
    health, above the charge's damage.
- **Should happen:** Cracked gardens counts every structure broken (the
  outcome's `cracked`). Shattered glass: "glass walls break in one hit,
  leaving shards".
- **Happens:**
  - `cracked` stays 0.
  - Under Shattered glass the wall survives the charge, and no shards are
    left when it does break.

  Both resonances change a defender's result, and the server agrees with it.
- **Proof:** `sim/src/tests.rs`,
  `sim_6_a_ramblers_charge_through_a_crystal_wall_counts_for_cracked_gardens`
  and `sim_6_..._under_shattered_glass_leaves_shards`. Both fail on main.
- **Fix (applied):** the charge reads both resonances.
  - Under Shattered glass, one hit takes the wall's whole health, and its
    tile is pushed to `shards`.
  - A break adds Cracked gardens' count to `cracked`.

## Low

### SIM-5: The Hourkeeper's rewind loses a hit taken in a tick the ally was healed
- **Priority / category:** Low / backend (simulation).
- **Where:** `sim/src/lib.rs` `World::step`, line 1256:
  `r.lost[slot] = (was - r.health).max(0)`.
- **Input:** an ally in a thorn hedge (one hit a second), healed by a
  Bloomling's Bloom in the same tick as a thorn. Then the Hourkeeper rewinds
  the ally.
- **Should happen:** the comment in `step` says healing in the same tick is
  not netted off ("all the health it lost", §11.11). All three thorns come
  back.
- **Happens:** the heal netted that tick's loss to 0. The rewind gives back
  two thorns of three, so the ally ends 6 health short (72 against 78 in the
  test's figures).
- **Proof:** `sim/src/tests.rs`,
  `sim_5_the_hourkeeper_gives_back_a_hit_taken_in_a_tick_the_ally_was_healed`.
- **Fix (applied):** each crew member keeps `healed`, the health it gained
  this tick. `step` resets it, and `lost` is `was + healed - health`. Every
  heal goes through one `Raider::heal`:
  - Bloom;
  - the rewind;
  - Renew;
  - the hot spring;
  - two Sage/ability heals.

### SIM-7: A Prism half that has folded back still blocks the Glass golem's wall
- **Priority / category:** Low / backend (simulation).
- **Where:** `sim/src/lib.rs` `World::raise_wall`, the `free` closure, lines
  4416-4422. Its test was "standing is not Out and not Caught", so `Gone`
  (a folded Prism half) counted as somebody on the tile.
- **Input:** a Prism Mite splits, and its half walks to a tile and folds
  back there. The Glass golem then raises a wall on that tile.
- **Should happen:** the wall rises on tiles with "nobody and nothing on
  them". A Gone half is nobody.
- **Happens:** the wall is refused on that tile for the rest of the heist.
- **Proof:** `sim/src/tests.rs`,
  `sim_7_a_folded_prism_half_is_nobody_and_does_not_block_the_glass_golems_wall`.
- **Fix (applied):** only `Active` and `Down` crew members block, written as
  a `matches!` on those two. This also covers any state added later.

### SIM-8: A Gravity Well cuts a Time Snare's freeze short
- **Priority / category:** Low / backend (simulation).
- **Where:** `sim/src/lib.rs` `World::fire_ward`. The Time Snare (line 3932)
  and the Gravity Well (line 3951) each *set* `frozen_until`.
- **Input:** a crew member steps on a Time Snare two tiles from a Gravity
  Well. Both fire in the same tick.
- **Should happen:** the snare's 2.5 s freeze stands. The well's shorter
  hold does not shorten it.
- **Happens:** the well, fired second, overwrites the freeze with its own
  hold. The test's figures are 60 ticks against 75.
- **Proof:** `sim/src/tests.rs`,
  `sim_8_a_gravity_well_does_not_cut_short_a_time_snares_freeze`.
- **Fix (applied):** both take the later of the current freeze and their own
  (`frozen_until.max(...)`).

### SIM-9: A bounce mushroom never lands a crew member on a bridge
- **Priority / category:** Low / backend (simulation).
- **Where:** `sim/src/lib.rs` `World::bounce`, line 4577:
  `.filter(|&t| grid.at(t).passable())`. A bridged pond is standable
  (`grid.standable`), but its terrain is not passable.
- **Input:** a mushroom with a bridged pond three tiles on, and the crew
  member running across.
- **Should happen:** "the furthest of those tiles it can stand on": the
  bridge.
- **Happens:** the bridge is skipped, and the crew member lands short.
- **Proof:** `sim/src/tests.rs`, `sim_9_a_bounce_mushroom_lands_on_a_bridge_three_tiles_on`.
- **Fix (applied):** the filter uses `grid.standable(t)`.

## The report's sim suspicions

The bug report's "Still not read" listed five `ffi.rs`, `island.rs` and
`grid.rs` suspicions.

### `rb_record_drawn` with crew 0 divides by zero and traps
- **Result: confirmed, but already known and deliberate. Low /
  informational, not fixed.**
- **What was tried:** `rb_record_drawn(.., crew = 0, ..)` reaches
  `Rng::below(0)` in `draw()` and traps the WebAssembly instance. This is
  SR-07's trap lever: `server/test/security_sim.test.mjs:20` calls it on
  purpose, to prove that a trap disables the build rather than corrupting
  it. `rb_record_drawn` is a test-only export; no server path calls it with
  player input.
- **Proposed fix:** give the trap lever its own export (`rb_trap`). Then
  refuse crews outside 3-5 in `rb_record_drawn` (`return -5`), as
  `rb_record` does. Not done here, because SR-07's test would need to move
  with it.

### `rb_hold` has no bound on ticks
- **Result: rejected.**
- **What was tried:** `rb_hold` (`ffi.rs:556`) is called from one place,
  `server/src/holds.mjs:88`, with server-fixed `raids` and `ticks`. No
  request value reaches it. A clamp would be hardening only.

### The record functions return replays over the server's 2 KB limit
- **Result: confirmed, as SIM-2, and fixed.**

### "Second encodings" give one island several digests
- **Result: rejected at the byte level. The semantic half is unproven.**
- **What was tried:** a scratch test mutated every single byte of twelve
  encoded islands (examples and generated). For each mutation it checked
  that the bytes either fail `Island::decode`, or decode and re-encode to
  exactly the mutated bytes. No byte gave a second encoding of the same
  island. A different order of guards, wards, laws or buildings, and the
  surface or height values on blocking tiles, may still give two encodings
  of one playable island. That was not settled; see "Unproven".

### `tile_at` and `coords` wrap out-of-range positions onto real tiles
- **Result: rejected.**
- **What was tried:** a wrap needs a position of 65,536 tiles or more, since
  the casts are to `u16`. Grids are 10-14 tiles on a side, and every
  position comes from the simulation's own movement (clamped to the grid) or
  from a command checked against the side (`Heist::decode`, `give`).

## Unproven

Each item below was suspected while reading. It was not proven with a
failing test, so it is listed rather than fixed.

### `lib.rs`, lines 1-3010
- `verify()` does not call `island.check()`, so a malformed island is
  simulated rather than refused. The server checks the island at publish,
  so no reachable input was found.
- Copy zones are created with `until: u32::MAX`, so one lasts the whole
  heist. §11 gives no duration that this contradicts.
- Glare's suspicion gain applies when no guard has noticed anyone. It is not
  clear from §12.4 whether that is wrong.
- The Rebound chord picks its target by portrait order, not distance.
  §8.5's text does not decide which.
- The Spark Storm effect named in a dissonance table is not built. It may be
  intentional (not shipped at launch).

### `lib.rs`, lines 3020-6035
- `rejoin` mixes the half's and the mite's state when the mite is Down or
  Caught, and when the mite is Out while the half is Down. No test case was
  built.
- The report's `caught_by` and `seen` may count Prism halves as crew
  members.
- Ruled out (as far as was tried):
  - `neighbours` going out of range;
  - `clock_affords` dividing by zero;
  - `Report::encode` wrapping a count.

### `stability.rs`, `path.rs`, `events.rs`, `noise.rs` and the rest
1. Stability's decoder accepts trailing bytes, and reads any school index
   other than 255 as "no school".
2. A crown law gets no 0.9 chord discount for a chord sounding in an outer
   realm.
3. Crown chords may sound in every realm.
4. `chords.len() as u8` wraps above 255 chords. There are 12 at launch.
5. `band()` at capacity 0 returns 6.
6. `build_laws.py`'s escaping of quoted text.
7. `Fx::div(0)` and `Rng::below(0)` panic. No caller was found passing 0,
   except SR-07's deliberate lever.
8. `path.rs` `find_over_wall`'s cost model.
9. The noise field ignores one-way drops.
10. `events.rs`'s decisive-moment capture uses the last time the captor
    became Alerted, not the first.
11. `content_gate.py`'s `facts_compare` passes a value when both sides read
    `None`.
12. The generators may not reproduce what is checked in. Not re-run against
    every generated file.

### `ffi.rs`
- `rb_competent_universe` (lines 315-338) writes its result with no length
  check against `MAX_HEIST_BYTES`. It is a test and tooling export, and it
  was not shown to exceed the limit.
- `rb_record` and `rb_record_crew` accept any `ticks`. The simulation stops
  at its own clock, so no harm was shown.
- `Heist::encode` writes the command count `as u16`. 65,536 commands
  cannot fit in a 2 KB replay, so after SIM-2 a wrap cannot be returned.
- `universe.rs`'s own suspicions were not investigated by this task.

## What was read

| Slice | Files | Read |
|---|---|---|
| A | `sim/src/lib.rs` lines 1-3010 | every line |
| B | `sim/src/lib.rs` lines 3020-6035; the parts of `grid.rs`, `replay.rs`, `heist.rs` and `ruleborn.rs` it calls | every line of lib.rs; the rest in part |
| C | `path.rs`, `stability.rs`, `events.rs`, `guard.rs`, `sight.rs`, `era.rs`, `rng.rs`, `fixed.rs`, `noise.rs`, `combos.rs`, `reference.rs`, `ruleborn.rs`, `trig.rs`, `sha256.rs`, `bin/golden.rs`, `bin/spike.rs`; every Python tool in `sim/` (`status.py`, `no_floats.py`, `content_gate.py`, the `build_*.py` generators) | every line |
| D | `sim/src/ffi.rs`; `island.rs` and `grid.rs` for the suspicions; `server/src/sim.mjs`, `holds.mjs`, `service.mjs`, `lab.mjs`; `client/ext/src/lib.rs` | every line of ffi.rs; the rest where the suspicions led |

### Still not read
- `sim/src/universe.rs`, beyond what `ffi.rs` calls.
- `sim/src/island.rs` and `grid.rs`, beyond the suspicions above.
- The `sim/examples/` programs, apart from `where_diverge`, which the gate
  runs.
