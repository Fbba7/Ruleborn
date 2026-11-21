# FX3 simulation fixes: progress

- Status: Waiting. FX3-1-heal-alarm is ready at the pre-checked sha in `docs/progress/status/FX3.json`.
- Progress: FX3-1-heal-alarm: RB-28 (Regrowth heals a Vault up to its own level's health) and RB-29 (a realm's alarm counts from the crew's arrival). Each has a fail-first test in `sim/src/tests.rs`, committed before its fix.
- Done: `cargo test` in `sim` 338 of 338, golden replays still verify (no rebake); `cd server && npm test` 535 of 535; `owners.py diff` passes.
- Next: the lead's merge, then FX3-2-island in a fresh session.
- Blocked by: none.
- Owner decision needed: none.

| Deliverable | Weight (h) | Status | Evidence |
|---|---:|---|---|
| FX3-1-heal-alarm: RB-28 and RB-29 | 3.0 | ready | `sim/src/tests.rs` `rb28_regrowth_heals_a_vault_up_to_its_own_levels_health`, `rb29_a_realms_alarm_counts_from_when_the_crew_arrives`; `sim/src/heist.rs`, `sim/src/lib.rs`, `sim/src/universe.rs` |

## Handoff
- FX3-1-heal-alarm, ready (2026-11-21). Branch `claude/fix-sim`. The pre-check result and `ready_sha` are in `docs/progress/status/FX3.json`.
  - **RB-28.** `World::heal` capped the Vault at `heist::VAULT_HEALTH_PER_LEVEL` (1,500), so Regrowth's first heal cut a level-10 Vault from 15,000 to 1,500. The Vault now keeps `full` (1,500 a level, set where the island's Vault is built), and healing stops there.
    - Test commit a10dc9ee, fix commit 1ab25511. The test fails on main:
      ```
      assertion `left == right` failed: an untouched Vault stays at full health
        left: 1500
       right: 15000
      ```
    - With the fix, a Vault at 10,000 heals 2% of 15,000 a second (10,300 after one second). The existing level-1 test (`regrowth_heals_guards_pylons_and_the_vault_and_revives_nothing`) is unchanged and passes.
  - **RB-29.** The alarm climbed with `now / ALARM_STEP_TICKS`, counting from the heist's first tick. A crew crossing into a second realm 151 s in therefore arrived at alarm 5, already reinforced. `World` now has `alarm_from`, the tick the crew first entered the realm, and the alarm climbs with `now - alarm_from`. `Crossing::go` sets it when it builds a realm's world on first entry. The landing realm keeps 0, so a single-realm heist is unchanged.
    - Test commits 9ea01d54 and c49f223c, fix commit 80fce5b2. The test fails on main, matching the report's "alarm 5 reinforced true guards 2 -> 3":
      ```
      assertion `left == right` failed: the Heart's alarm on the crew's first tick there
        left: (5, true, 3)
       right: (0, false, 2)
      ```
    - **The test was corrected once, before the fix.** Its 30-second check first stepped `ALARM_STEP_TICKS` times. The last step's `now` is then 899 ticks after arrival, so the alarm reads 0 even with the fix. c49f223c steps `0..=ALARM_STEP_TICKS`. On main that check still fails, with the alarm at 3.
    - **A design choice to confirm.** A realm the crew comes back to keeps the `alarm_from` of its first arrival: its alarm goes on counting from then, not from the return. The design (§12.17) and the harness cover only forward legs, so nothing tests a return. If the lead wants a return to reset the count, it is a one-line change in `Crossing::go`.
  - **Goldens.** Neither fix changes a golden outcome: `golden_replays_still_verify` passes, and no `sim/golden/*.rbh` was rebaked.
  - **Existing tests.** No existing test was changed, skipped or loosened.
  - **Merge evidence.** Main was merged at bdc0ba84. It brought lead files only (backlog, lead.md, lead-archive.md, owner-inbox.md, requests.md, status/lead.json) and no conflict. `owners.py diff FX3-1-heal-alarm origin/claude/videogame-project-analysis-ewkkk2 bdc0ba84` reports "every changed path is inside its files".
  - **Next.** FX3-2-island, in a fresh session.
