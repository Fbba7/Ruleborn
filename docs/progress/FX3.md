# FX3 simulation fixes: progress

- Status: Active. FX3-2-island merged. FX3-3-clock-report: all three fixes committed; pre-check running at 9aa26794.
- Progress: FX3-3-clock-report: RB-44 (a split Prism mite held the defender's report to the whole clock), RB-45 (a slowed clock never caught the crew still inside), RB-19 (an older pinned build could not load). Each has a fail-first test, committed before its fix.
- Done: `cargo test` in `sim` 346 of 346, golden replays still verify (no rebake); `cd server && npm test` 562 of 562; `python3 sim/status.py` every gate holds.
- Next: the pre-check result, `owners.py diff`, then ready.
- Blocked by: none.
- Owner decision needed: none.

| Deliverable | Weight (h) | Status | Evidence |
|---|---:|---|---|
| FX3-1-heal-alarm: RB-28 and RB-29 | 3.0 | merged | lead cycle 158 |
| FX3-2-island: RB-40, RB-50, RB-57, candidates 7 and 34 | 4.0 | merged | `sim/src/tests.rs` `rb40_an_entrance_in_a_wall_or_on_the_vault_is_not_published`, `rb50_weaving_a_law_onto_the_vault_is_refused_and_keeps_the_law`, `rb57_a_ward_or_pylon_on_a_guard_in_tall_grass_replaces_the_grass_too`, `candidate_7_the_same_law_twice_is_not_published`, `candidate_34_a_tunnel_mouth_under_a_raised_wall_is_no_way_out`; `sim/src/island.rs`, `sim/src/path.rs`, `server/src/sim.mjs` |
| FX3-3-clock-report: RB-44, RB-45, RB-19 | 3.0 | in progress | `sim/src/tests.rs` `rb44_a_split_and_rejoined_mite_does_not_hold_the_report_to_the_whole_clock`, `rb44_a_crossings_reports_count_only_the_crew_for_held`, `rb45_a_slowed_clock_still_catches_whoever_is_inside_at_the_last_tick`; `server/test/fix_fx3_older_build.test.mjs`; `sim/src/lib.rs`, `sim/src/universe.rs`, `server/src/sim.mjs` |

## Handoff
- FX3-3-clock-report (2026-11-21). Branch `claude/fix-sim`. Main merged at 9aa26794 (lead cycle 160's files only, no conflict).
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
  - **Next.** The pre-check at 9aa26794, then `owners.py diff`, then ready.
