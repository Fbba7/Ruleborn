# FX3 simulation fixes: progress

- Status: Waiting. FX3-2-island is ready at 16a5a961 (pre-check PASS at 18:35Z, recorded). FX3-1-heal-alarm merged in lead cycle 158.
- Progress: FX3-2-island: RB-40 (an entrance in a wall or on the Vault), RB-50 (weaving onto the Vault deleted the law), RB-57 (a ward or pylon on a guard in tall grass left the grass), and the unproven candidates 7 (the same law twice) and 34 (a covered tunnel mouth), both reproduced. Each has a fail-first test in `sim/src/tests.rs`, committed before its fix.
- Done: `cargo test` in `sim` 343 of 343, golden replays still verify (no rebake); `cd server && npm test` 549 of 549; `bash sim/run_spike.sh` every gate holds; `owners.py diff` passes.
- Next: the lead's merge, then FX3-3-clock-report in a fresh session.
- Blocked by: none. FX3-R1 (two problem strings in `client/i18n/strings.csv`) is open with the lead, not blocking.
- Owner decision needed: none.

| Deliverable | Weight (h) | Status | Evidence |
|---|---:|---|---|
| FX3-1-heal-alarm: RB-28 and RB-29 | 3.0 | merged | lead cycle 158 |
| FX3-2-island: RB-40, RB-50, RB-57, candidates 7 and 34 | 4.0 | ready | `sim/src/tests.rs` `rb40_an_entrance_in_a_wall_or_on_the_vault_is_not_published`, `rb50_weaving_a_law_onto_the_vault_is_refused_and_keeps_the_law`, `rb57_a_ward_or_pylon_on_a_guard_in_tall_grass_replaces_the_grass_too`, `candidate_7_the_same_law_twice_is_not_published`, `candidate_34_a_tunnel_mouth_under_a_raised_wall_is_no_way_out`; `sim/src/island.rs`, `sim/src/path.rs`, `server/src/sim.mjs` |

## Handoff
- FX3-2-island, ready (2026-11-21). Branch `claude/fix-sim`. Pre-check at 16a5a961: PASS ("All checks passed.", 18:35Z, recorded); `ready_sha` 16a5a961 is in `docs/progress/status/FX3.json`.
  - **RB-40.** `Island::check` never looked at the entrance, where the alarm-5 Warden comes in. It now appends `Problem::EntranceBlocked`, a new last bit (bit 9), when the entrance is the Vault's tile or a tile nobody can stand on with every Crystal Wall standing (the same `standing()` grid as `PostBlocked`). `PROBLEMS` in `server/src/sim.mjs` gains `entrance_blocked` in that place.
    - Test commit c1d07713, fix commit aaafc4f8. The test fails on main:
      ```
      panicked at src/tests.rs:6808:5:
      an entrance in the ruin wall: []
      ```
    - **One existing expectation corrected.** In `an_island_keeps_to_5_2_and_6_1_or_is_not_published`, the case that closes every edge tile also closes the entrance, (11, 11), a corner tile now under a pillar. Its expectation `[LandingBlocked, EdgeClosed]` becomes `[LandingBlocked, EdgeClosed, EntranceBlocked]` (in the fix commit). That is stricter, not looser: the island was already refused, and now also for its entrance.
  - **RB-50.** `weave` removed the law from its old pylon before `claim` refused the Vault tile. It now refuses the Vault up front, with the other refusals, before anything moves.
    - Test commit 366090a1, fix commit a9fe3dbd. The test fails on main:
      ```
      assertion `left == right` failed: the law stays where it was
        left: []
       right: [("haste", 1, 10)]
      ```
  - **RB-57.** `claim` called `clear` once, which took the guard and left the tall grass it stood in, so the ward or pylon put there was `Crowded`. It now clears until nothing is left (`while self.clear(x, y) {}`, as `place_building` does). The loop ends: each `clear` that returns true removes one thing, and it returns false on the Vault and on bare ground.
    - Test commit fcb159c3, fix commit e0ed3cd1. The test fails on main (guards, feature at (2, 7) after `place_ward`):
      ```
      assertion `left == right` failed
        left: (0, Some(TallGrass))
       right: (0, None)
      ```
  - **Candidate 7, reproduced.** `decode` and `check` both let one law sit on two pylons, and the sheet applies it once per pylon. `check` now appends `Problem::DuplicateLaw` (bit 10) and `PROBLEMS` gains `duplicate_law`. I chose the publish gate over a `decode` refusal so a stored bundle stays readable. The editor's `weave` already moves a law rather than adding it twice. The simulation still stacks a duplicate if handed one; nothing publishes one now.
    - Test commit 4738ec71, fix commit 9eaceda6. The test fails on main:
      ```
      panicked at src/tests.rs:6855:5:
      the same law twice passes the gate: []
      ```
  - **Candidate 34, reproduced.** `path::find_through` followed `grid.tunnel_exit` with no check on the far mouth, so a route came up into a crew's raised Crystal Wall. It now follows a tunnel only to a passable far mouth. `grid::tunnel_exit` is unchanged, because `underground()` relies on it. A building on a mouth was already refused at publish (`Crowded`), so the raised wall is the case that matters in a heist.
    - Test commit 8f80624d, fix commit 9c07e0a1. The test fails on main (the route's last three tiles are the far mouth (6, 2) and beyond):
      ```
      panicked at src/tests.rs:6873:5:
      a route comes up into the raised wall: Some([31, 34, 35, 36])
      ```
    - **Left for FX3-5-audit-sim.** `raise_wall` checks that nobody stands on a tile, but a crew member already inside a tunnel stands on neither mouth. A wall can therefore rise on the far mouth while someone walks the tunnel, and that route was planned before the wall. I did not change this here: it is outside candidate 34's input.
  - **Unproven, rechecked.** Both candidates reproduced, so nothing was added to `docs/security/audit-2026-11/sim.md`.
  - **Goldens.** No fix changes a golden outcome: `golden_replays_still_verify` passes, and no `sim/golden/*.rbh` was rebaked.
  - **`sim/systems.json`.** 351b90bb lists the four island tests under Publishing rules and the tunnel test under Pathfinding. It also commits the `sim/status.json` that `status.py` rewrote, whose only change is five new "passed" lines.
  - **FX3-R1 (not blocking).** The client shows a problem as `Strings.t("PROBLEM_" + name.to_upper())` (`client/scripts/builder_screen.gd:515`, `client/features/curation/curation_presenter.gd:235`). `PROBLEM_ENTRANCEBLOCKED` and `PROBLEM_DUPLICATELAW` are not in `client/i18n/strings.csv`, which is not an FX3 file. Default: the raw key shows until a strings or UI task adds the rows, with `build_words.mjs` rerun (M34).
  - **Merge evidence.** Main was merged at 16a5a961. It brought lead cycle 158's files only (backlog, lead.md, lead-archive.md, status files) and no conflict. `owners.py diff FX3-2-island origin/claude/videogame-project-analysis-ewkkk2 16a5a961` reports "every changed path is inside its files".
  - **Next.** FX3-3-clock-report, in a fresh session.
