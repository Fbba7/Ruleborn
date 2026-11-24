# FX1 server fixes (A): progress

- Status: Ready. FX1-6-audit-server-a ready at 01cb97ac: pre-check PASS (02:19 UTC), owners.py pass; waiting for the merge.
- Progress: 4 of 6 tasks merged (FX1-1, FX1-2, FX1-3; FX1-4-holds-codex at e2e8f5a1); no gate items (fix tasks have none).
- Done: FX1-6: 17 findings (FX1-A-01 to A-17) in `docs/security/audit-2026-11/server-a.md`, each with a test in `server/test/fix_fx1_audit_server_a.test.mjs` that fails on main; 10 fixed in owned files, 1 partly, 5 marked and requested (FX1-R3 to R8), A-07 open as AUD-B-06 (FX1-R11), A-09 contested (FX1-R9); `cd server && npm test` 631 of 631.
- Next: FX1-7-audit-tools, in a fresh session.
- Blocked by: none.
- Owner decision needed: none (FX1-R9 and FX1-R10 are the lead's, each with a default).

| Deliverable | Weight (h) | Status | Evidence |
|---|---:|---|---|
| FX1-1-workshop-pairs: RB-30, RB-05, RB-06 | 3.0 | merged (8ed7538f) | `server/test/fix_fx1_workshop_pairs.test.mjs`; test commit 3785a41c; fixes in `server/src/workshop.mjs`, `server/src/service.mjs`, `server/src/matchmaking.mjs` |
| FX1-2-leases: RB-12, RB-14, RB-16, RB-17 | 3.5 | merged (c7cdcbbd) | `server/test/fix_fx1_leases.test.mjs`; test commit d1c34426; fixes 68b8d6f9, 092bc9fd, 2c55de1f, 165fa31f |
| FX1-3-workshop: RB-35, RB-37, RB-38, RB-39 | 3.5 | merged (e413e4a9) | `server/test/fix_fx1_workshop.test.mjs`; test commit bf0ff93e; fixes c717a9b1, 1faccdd2, 2ac59da1, a4817445 |
| FX1-4-holds-codex: RB-15, RB-18, RB-36, RB-53, RB-56 | 4.0 | merged (e2e8f5a1) | `server/test/fix_fx1_holds_codex.test.mjs`; test commit 924726b8; fixes 103d4176, 1de6f966, 63f031ad, 07047356, b45dafe6 |
| FX1-6-audit-server-a: FX1-A-01 to A-17 | 4.0 | ready (01cb97ac) | `docs/security/audit-2026-11/server-a.md`; `server/test/fix_fx1_audit_server_a.test.mjs`; test commits 6b3556f9, 5d5d2e82, b0e4cd1c, f33ccc18; fixes f1888bba, dfc5bf86, 244b9480, 533b793d, ccda8b22; A-07 reverted 01cb97ac (R11) |
| FX1-7-audit-tools | 4.0 | open | |

## Handoff
- Last verified commit: 01cb97ac (pre-check PASS 2026-11-24T02:19:53Z). Main ee42bb70 merged; main moved to 16c2046c (FX2-8) after the pre-check and merges clean.
- **FX1-6-audit-server-a (2026-11-23).** Branch `claude/fix-server-a`, from main e2e8f5a1, with main ee42bb70 merged. The audit read the files the report did not (`service.mjs`, `matchmaking.mjs`, `holds.mjs`, `crossings.mjs`, `codex.mjs`, `workshop.mjs`, `fund.mjs`) and followed their calls into the modules they use. The findings, the unproven claims and the rejected ones are in `docs/security/audit-2026-11/server-a.md`.
  - **Tests first.** Every finding's test, in `server/test/fix_fx1_audit_server_a.test.mjs`, was committed before its fix (6b3556f9, 5d5d2e82, b0e4cd1c, f33ccc18), and each fails on main for its defect.
  - **Fixed in owned files:** A-01 (an echo with erased bytes broke every target list), A-03, A-04, A-05, A-06, A-08, A-11, A-12 and A-14. A-13 is fixed in part: the full fix needs a `leases.realm` column in `db.mjs` (FX1-R5).
  - **Marked, not fixed** (files this task does not own). Each test asserts today's behaviour, a comment marks it with the finding's id, and a request names the fix: A-02 `accounts.mjs` (R3), A-10 `limits.mjs` (R4), A-15 `seasons.mjs` (R6), A-16 `links.mjs` (R7) and A-17 `weaving.mjs` (R8). R8's fix also changes `server/test/codex.test.mjs:211`.
  - **Open, same as AUD-B-06:** A-07. Its fix in `matchmaking.mjs` `current()` was made, then reverted after main brought FX2's AUD-B-06 proof (`fix_fx2_audit_observatory.test.mjs:56`), whose stillOpen wrapper fails once the defect is fixed. That file is not this task's. A-07's proof now runs under the same `stillOpen`. R11 asks for one task that lands the fix and unwraps both proofs.
  - **Contested:** A-09, the `echoes` flag on a thin list with no echo. `server/test/generated.test.mjs:56` asserts today's behaviour, so the test asserts it too and R9 asks the lead (default: leave it).
  - **Unproven:** the Renown pull-back over skipped seasons (R10, default one pull-back), the 13-15 crew rule (owner decision B4, asserted by SR-14) and curated wards' origin. No tests.
  - **A-03's refusal** reuses `404 no_such_report`. A new `already_resolved` broke `tools/check_all.sh`'s client contract, because `client/i18n/strings.csv` is not this task's.
  - **Existing tests.** No existing test was changed, skipped or loosened.
  - **Checks.** `cd server && npm test` passes 631 of 631, and `bash tools/check_all.sh` passes. The pre-check at 01cb97ac passed and is recorded. `owners.py diff FX1-6-audit-server-a origin/claude/videogame-project-analysis-ewkkk2 01cb97ac` reports every changed path inside the task's files.
  - **Next.** FX1-7-audit-tools, in a fresh session.
- **FX1-4-holds-codex resync (2026-11-23).** The lead set `resync` because candidate ea551636 (FX1-4 with FX2-5-auth-lows) failed RB-36's test with `crew_mismatch` at `server/test/fix_fx1_holds_codex.test.mjs:98`. Cause: FX2-5's RB-25 fix makes `home.crewProblem` compare each manifest member's form byte with the character's. RB-36's test wrote manifests without `form`.
  - Main (79079d43, with FX2-5 at 5f1cc425) merged into the branch at 59b6c398. Only `docs/progress/status/FX1.json` conflicted, and it is FX1's own file.
  - 9fe151ad: RB-36's test manifest members now carry `form: c.wire.form`, as FX2-5 did in `setup.mjs`, `casts.test.mjs` and `rest.test.mjs`. No assertion changed and no source changed. Before that commit, on the merge, `node --test test/fix_fx1_holds_codex.test.mjs` gave pass 5, fail 1 (`crew_mismatch`). After it, `cd server && npm test` passes 586 of 586.
  - Fresh-container setup line and `bash client/build.sh` ran first (exit 0). The pre-check at 9fe151ad passed: "All checks passed.", `DONE exit=0`, sandbox bwrap. `owners.py diff FX1-4-holds-codex origin/claude/videogame-project-analysis-ewkkk2 9fe151ad` reports "every changed path is inside its files". Main then moved only in lead bookkeeping (5813e854, 719c4ff3, `docs/progress/**`), so the pre-check stands.
  - **Next.** FX1-6-audit-server-a, in a fresh session, once FX1-4 merges.
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
  - **Merge evidence.** Main (02558e05, lead bookkeeping) was merged at 2003cc38 with no conflict. `owners.py diff FX1-4-holds-codex origin/claude/videogame-project-analysis-ewkkk2 2003cc38` reports "every changed path is inside its files". The fresh-container setup line and `bash client/build.sh` ran first (exit 0). The pre-check at 2003cc38 passed ("All checks passed.", exit 0, 21:44:27Z, sandbox bwrap).
  - **Next.** FX1-6-audit-server-a, in a fresh session.

## Tried and failed
- 2026-11-21 Refused RB-30 with the report's new reason `taken_down`: the client contract needs every server reason worded in `client/i18n/strings.csv`, a file outside the task. Reused `island_withdrawn` instead.
- 2026-11-21 Ran the server tests before the wasm simulation was built: every service test fails with "ruleborn_sim.wasm is not built". `cargo build --release --target wasm32-unknown-unknown` in `sim/` builds it, and so does the pre-check.
- 2026-11-23 FX1-A-09: setting `echoes` only when an echo was among the candidates broke `server/test/generated.test.mjs:51` ("echoes first"), which this task does not own. Reverted; A-09 is contested (FX1-R9).
- 2026-11-23 FX1-A-03 refused with a new `409 already_resolved`: `tools/check_all.sh`'s client contract needs every server code worded in `client/i18n/strings.csv`. Reused `404 no_such_report` instead.
- 2026-11-24 FX1-A-07's fix in `current()` (533b793d), after merging main ee42bb70: FX2's AUD-B-06 wrapper (`fix_fx2_audit_observatory.test.mjs:56`) failed with "no longer fails: it is fixed", and that file is not this task's. Reverted the fix and filed FX1-R11.
