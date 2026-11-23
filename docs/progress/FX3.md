# FX3 simulation fixes: progress

- Status: Waiting. FX3-4-lab-replay is ready at 7db937dd (pre-check PASS at 21:40Z, recorded). FX3-3-clock-report merged.
- Progress: FX3-4-lab-replay: RB-51 (a crossing hinted only the first chord of each three laws), RB-52 (a Lab hint could name a resonance not found at launch), RB-54 (several byte strings decoded as one heist), RB-55 (a command for actor 16 or above came back as another crew member). Each has a fail-first test, committed before its fix.
- Done: `cargo test` in `sim` 349 of 349, golden replays still verify (no rebake); `cd server && npm test` 574 of 574; `python3 sim/status.py` every gate holds.
- Next: the lead's merge, then FX3-5-audit-sim in a fresh session.
- Blocked by: none.
- Owner decision needed: none.

| Deliverable | Weight (h) | Status | Evidence |
|---|---:|---|---|
| FX3-1-heal-alarm: RB-28 and RB-29 | 3.0 | merged | lead cycle 158 |
| FX3-2-island: RB-40, RB-50, RB-57, candidates 7 and 34 | 4.0 | merged | `sim/src/tests.rs` `rb40_an_entrance_in_a_wall_or_on_the_vault_is_not_published`, `rb50_weaving_a_law_onto_the_vault_is_refused_and_keeps_the_law`, `rb57_a_ward_or_pylon_on_a_guard_in_tall_grass_replaces_the_grass_too`, `candidate_7_the_same_law_twice_is_not_published`, `candidate_34_a_tunnel_mouth_under_a_raised_wall_is_no_way_out`; `sim/src/island.rs`, `sim/src/path.rs`, `server/src/sim.mjs` |
| FX3-3-clock-report: RB-44, RB-45, RB-19 | 3.0 | merged | `sim/src/tests.rs` `rb44_a_split_and_rejoined_mite_does_not_hold_the_report_to_the_whole_clock`, `rb44_a_crossings_reports_count_only_the_crew_for_held`, `rb45_a_slowed_clock_still_catches_whoever_is_inside_at_the_last_tick`; `server/test/fix_fx3_older_build.test.mjs`; `sim/src/lib.rs`, `sim/src/universe.rs`, `server/src/sim.mjs` |
| FX3-4-lab-replay: RB-51, RB-52, RB-54, RB-55 | 3.5 | ready | `server/test/fix_fx3_lab_hints.test.mjs`; `sim/src/tests.rs` `rb54_a_tick_delta_past_u32_is_refused_not_wrapped`, `rb54_a_padded_varint_is_refused`, `rb55_a_command_for_actor_16_still_records_a_replay_that_round_trips`; `server/src/lab.mjs`, `sim/src/replay.rs`, `sim/src/lib.rs` |

## Handoff
- FX3-4-lab-replay, ready (2026-11-21). Branch `claude/fix-sim`. Pre-check at 7db937dd: PASS ("All checks passed.", 21:40Z, recorded); `ready_sha` 7db937dd is in `docs/progress/status/FX3.json`. Main merged at 702b29e6 (lead cycle 162's files only, no conflict). An earlier pre-check at 702b29e6 failed on `sim/status.py` ("tests no system claims") because the new Rust tests were not yet listed in `sim/systems.json`; 7db937dd lists them, and that run is superseded. Main has since gained lead cycle 163 (57c23193, 11aa8614, docs/progress bookkeeping only); not merged, so the pre-checked sha stays the ready one.
  - **RB-51.** `Lab.crossed` took `chordOf`, the first chord in §8.8's table three laws make, so three laws completing two or more chords hinted only one of them. A new `chordsOf` returns every chord the three complete, each note carried by a different law; `crossed` hints each one not yet found. `chordOf` stays, as `chordsOf(..)[0]`, for `server/test/lab.test.mjs`.
    - Test commit efdc9028, fix commit 812c7e52. The test fails on main:
      ```
      error: 'clockwork hinted: ["ghost_tide","pinball"]'
      ```
  - **RB-52.** `Lab.hint` searched `RESONANCES` for an undiscovered resonance of the law, so an empty experiment could hint one that cannot be found at launch. It now searches `LAUNCH_RESONANCES`.
    - Test commit efdc9028, fix commit 451fad7a. The test fails on main:
      ```
      error: 'sleeping_streams can be found at launch: ["drifting_echoes","mangrove_banks","sleeping_streams"]'
      ```
  - **RB-54.** `Heist::decode` cast each tick delta `as u32`, so a delta of 2^32 + d read as d, and `read_varint` accepted padded forms (a trailing `0x00` byte) and over-long ones whose high bits fell off. One heist therefore had many byte strings. The decoder now refuses a delta past `u32`, a zero last byte after the first, and bits past 64 at the tenth byte, so each heist has the one encoding `encode` writes.
    - Test commit 03568ad3, fix commit 340a09d4. The tests fail on main:
      ```
      2^32 + 0 decodes as 0
      ```
      and
      ```
      a padded varint decodes
      ```
  - **RB-55.** The replay packs the actor in four bits (`(actor << 4) | kind`), so a command for actor 16 was encoded as actor 0, another crew member. `record_with` now drops commands for actor 16 or above before recording, as no crew member is named by them; every recorded heist round-trips.
    - Test commit 03568ad3, fix commit 6d2d8e8e. The test inserts a tick-1 MoveTo for actor 16 into `draw`'s log on `Island::example_open()`, records it, and checks the record keeps no such command and decodes to the same commands. It fails on main:
      ```
      the recorded heist keeps a command for an actor past 15
      ```
      (decoded, that command read `Command { tick: 1, actor: 0, kind: MoveTo, .. }`).
  - **Goldens.** No fix changes a golden outcome: `golden_replays_still_verify` passes, and no `sim/golden/*.rbh` was rebaked.
  - **`sim/systems.json`.** 7db937dd lists the RB-54 and RB-55 tests under Replay format, and commits the `sim/status.json` that `status.py` rewrote (three new "passed" lines).
  - **No existing test was changed.**
  - **Owners.** `owners.py diff FX3-4-lab-replay origin/claude/videogame-project-analysis-ewkkk2 7db937dd` reports "every changed path is inside its files".
  - **Next.** The lead's merge; FX3-5-audit-sim in a fresh session.
- FX3-3-clock-report, ready (2026-11-21). Branch `claude/fix-sim`. Pre-check at 9aa26794: PASS ("All checks passed.", 19:52Z, recorded); `ready_sha` 9aa26794 is in `docs/progress/status/FX3.json`. Main merged at 9aa26794 (lead cycle 160's files only, no conflict). Main has since gained lead cycle 161 (91ab2a52, bookkeeping only); not merged, so the pre-checked sha stays the ready one.
  - **RB-44.** `World::report` and `Crossing::reports` set `held` to the whole clock unless every raider in `raiders` was Out or Caught. A Prism mite's half is appended to `raiders` and retired as `Gone` at the rejoin, logging neither, so after any split the defence "held" for the whole clock. A new `World::crew_all_in` counts only the crew (raiders with no `half_of`); both reports use it.
    - Test commit 596289a8, fix commit 6e610477. The tests fail on main:
      ```
      assertion `left == right` failed: all three out at tick 300
        left: 65535
       right: 10
      ```
      (the test world's clock is unbounded, so the whole clock reads as the clamp), and for the crossing:
      ```
      all three out at tick 300: [165]
      ```
  - **RB-45.** §12.6's catch at the clock's end ran only when `clock_run` reached `clock * 1000`. An inverted Haste runs the clock at 4/5, so it never got there before the replay's last tick, and whoever was inside was never caught. The catch now also runs on the replay's last tick (`now + 1 >= clock`). At the normal rate `clock_run` reaches `clock * 1000` on that same tick, so an unslowed heist is unchanged; a quickened one still ends early as before.
    - Test commit 1601e5cb, fix commit 2fe3eb44. The test fails on main:
      ```
      assertion `left == right` failed: inside at the replay's last tick
        left: Active
       right: Caught
      ```
  - **RB-19.** `Build`'s trap-wrapping loop read each method as `this[name]`, which ran the `buildingKinds` and `footprints` getters at load, and a build without `rb_building_kinds` threw. The loop now reads `Object.getOwnPropertyDescriptor(Build.prototype, name).value`, as the report proposes, so getters are skipped (they were never wrapped anyway: their value is not a function).
    - Test commit 7fc59edd, fix commit 5e792a71. The test makes the older build from this checkout's by renaming the `rb_building_kinds` export to a same-length name, so the module stays valid. It fails on main:
      ```
      error: 'this.x.rb_building_kinds is not a function'
      name: 'TypeError'
      ```
  - **Goldens.** No fix changes a golden outcome: `golden_replays_still_verify` passes, and no `sim/golden/*.rbh` was rebaked.
  - **`sim/systems.json`.** 35a69624 lists the RB-44 tests under Event log and Universes and the RB-45 test under The skiff, the clock and the outcome. It also commits the `sim/status.json` that `status.py` rewrote, whose only change is three new "passed" lines.
  - **No existing test was changed.**
  - **Owners.** `owners.py diff FX3-3-clock-report origin/claude/videogame-project-analysis-ewkkk2 9aa26794` reports "every changed path is inside its files".
  - **Next.** The lead's merge; the next FX3 task in a fresh session.
