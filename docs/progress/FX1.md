# FX1 server fixes (A): progress

- Status: Green. FX1-4-holds-codex: pre-check at 2003cc38 running; `ready_sha` and the result go in `docs/progress/status/FX1.json` when it ends.
- Progress: 3 of 6 tasks merged (FX1-1-workshop-pairs, 8ed7538f; FX1-2-leases, c7cdcbbd; FX1-3-workshop, e413e4a9); no gate items (fix tasks have none).
- Done: FX1-4: RB-15, RB-18, RB-36, RB-53, RB-56, each with a test committed before its fix; `cd server && npm test` 578 of 578; `owners.py diff` passes.
- Next: FX1-6-audit-server-a, in a fresh session.
- Blocked by: none.
- Owner decision needed: none.

| Deliverable | Weight (h) | Status | Evidence |
|---|---:|---|---|
| FX1-1-workshop-pairs: RB-30, RB-05, RB-06 | 3.0 | merged (8ed7538f) | `server/test/fix_fx1_workshop_pairs.test.mjs`; test commit 3785a41c; fixes in `server/src/workshop.mjs`, `server/src/service.mjs`, `server/src/matchmaking.mjs` |
| FX1-2-leases: RB-12, RB-14, RB-16, RB-17 | 3.5 | merged (c7cdcbbd) | `server/test/fix_fx1_leases.test.mjs`; test commit d1c34426; fixes 68b8d6f9, 092bc9fd, 2c55de1f, 165fa31f |
| FX1-3-workshop: RB-35, RB-37, RB-38, RB-39 | 3.5 | merged (e413e4a9) | `server/test/fix_fx1_workshop.test.mjs`; test commit bf0ff93e; fixes c717a9b1, 1faccdd2, 2ac59da1, a4817445 |
| FX1-4-holds-codex: RB-15, RB-18, RB-36, RB-53, RB-56 | 4.0 | pre-check (2003cc38) | `server/test/fix_fx1_holds_codex.test.mjs`; test commit 924726b8; fixes 103d4176, 1de6f966, 63f031ad, 07047356, b45dafe6 |
| FX1-6-audit-server-a | 4.0 | open | |
| FX1-7-audit-tools | 4.0 | open | |

## Handoff
- FX1-4-holds-codex (2026-11-21). Branch `claude/fix-server-a`. The pre-check result and `ready_sha` are in `docs/progress/status/FX1.json`.
  - **Tests first.** The six tests in `server/test/fix_fx1_holds_codex.test.mjs` were committed alone at 924726b8. All six fail on main (b4125468's server code, with the wasm simulation built). Each fails for its defect:
    ```
    not ok 1 - RB-15: a hold measurement that throws is no measured figure, and a republish of its bundle keeps the default prior (13.3, SEC-20)
      no measured figure from a failed measurement
      + { held: 0, hold: 0, raids: 30, status: 'measured' }
      - null
    not ok 2 - RB-15: a hold measurement whose bytes are gone from the store is no measured figure (13.3)
      no measured figure without the island's bytes
      + { held: 0, hold: 0, raids: 30, status: 'measured' }
      - null
    not ok 3 - RB-18: a universe with no link rows is raided as a universe: its links are made at the lease (5.4)
      error: 'a universe digest, its missing links made'   (crossings.of returned null)
    not ok 4 - RB-36: five foiled friendly heists in one day, each casting a law, pay the defender at most one page of it (SEC-24, 7.6)
      error: 'dave got 5 bloom pages'
    not ok 5 - RB-53: studying a heist whose island was erased by an under-13 deletion is refused 409 nothing_to_study, not a 500 (7.6, 20.11)
      error: 'a 4xx refusal'   (thrown: TypeError: Cannot read properties of null (reading '4'))
    not ok 6 - RB-56: a player's report, after the player is deleted as under-13, is not shown as the server's, and its dismissal leaves the spike flag (18.7, 20.11)
      + [ [ 1, 'unfair', true ] ]
      - [ [ 1, 'unfair', false ] ]
    ```
  - **RB-15** (103d4176). As the report's Fix line says. A measurement that throws, or whose bundle's bytes are gone, is stored with `held = -1`, and `holds.status()` returns null for it. Curation then shows no hold, and a later republish of the bundle (`service.publish`) keeps the default prior. The SEC-20 test, which expects the row to be marked, finished and never picked again, still passes unchanged.
  - **RB-18** (1de6f966). As the report's Fix line says. `crossings.of()` checks only that the bundle is the defender's Heart, then runs `links.ensure` and `links.upkeep`, then plans. One consequence: `upkeep` now also runs at the lease of a Heart with no universe. It is the same read the owner's universe page makes.
  - **RB-36** (63f031ad). As the report's Fix line says. The defender's page for a law cast in a foiled heist also requires `friendPages`, which is true for every mode but a friendly heist after the pair's first of the UTC day. The test casts Bloom, not the report's Aurora, because Bloom is one of the three starting laws a raider holds without restoring.
  - **RB-53** (07047356). As the report's Fix line says. `codex.study` refuses `409 nothing_to_study` when the heist's bundle bytes are gone. That reason is already used in `study`, so the client already words it.
  - **RB-56** (b45dafe6). As the report's Fix line says. The queue's `server` flag, and the dismissal's check for an open server report (RB-39), now also require `reason = 'completion_spike'`. Only the server files that reason: it is not one of `REPORT_REASONS`.
  - **Left for FX1-6's audit** (not in FX1-4's Fix lines). The same unguarded `lawsOf(store.get(bundle))` read is at `server/src/codex.mjs:128` (`afterHeist`), `server/src/service.mjs:823` and `:853` (settlement), and `server/src/matchmaking.mjs:338`. Each throws if a bundle is erased between lease and submit.
  - **Existing tests.** No existing test was changed, skipped or loosened. `cd server && npm test` passes 578 of 578.
  - **Merge evidence.** Main (02558e05, lead bookkeeping) was merged at 2003cc38 with no conflict. `owners.py diff FX1-4-holds-codex origin/claude/videogame-project-analysis-ewkkk2 2003cc38` reports "every changed path is inside its files". The fresh-container setup line and `bash client/build.sh` ran first (exit 0).
  - **Next.** FX1-6-audit-server-a, in a fresh session.

## Tried and failed
- 2026-11-21 Refused RB-30 with the report's new reason `taken_down`: the client contract needs every server reason worded in `client/i18n/strings.csv`, a file outside the task. Reused `island_withdrawn` instead.
- 2026-11-21 Ran the server tests before the wasm simulation was built: every service test fails with "ruleborn_sim.wasm is not built". `cargo build --release --target wasm32-unknown-unknown` in `sim/` builds it, and so does the pre-check.
