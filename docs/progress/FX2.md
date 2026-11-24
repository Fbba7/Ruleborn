# FX2 fixer, server B: progress

- Status: Green. FX2-9-audit-b-match's four findings are fixed, each proof plain and failing on main first. `cd server && npm test` passes 633 of 633. check_all PASS on f2181cf5.
- Progress: 8 of 9 tasks merged (FX2-1 at 23cf8a90, FX2-2 at 8ed7538f, FX2-3 at c7cdcbbd, FX2-4 at e413e4a9, FX2-5 at 5f1cc425, FX2-6 at ab25eb88, FX2-7 at bc7f27e8, FX2-8 at cd5f98fb). FX2-9 is ready at f2181cf5. No gate items.
- Done: AUD-B-01 (Medium) and AUD-B-06 (Low) of the server-b audit; FX1-A-07 (= AUD-B-06, FX1-R11) and FX1-A-09 (FX1-R9) of the server-a audit.
- Next: the lead merges f2181cf5.
- Blocked by: nothing.
- Owner decision needed: none.

| Deliverable | Weight (h) | Status | Evidence |
|---|---:|---|---|
| FX2-1-db-store-home: RB-01, RB-02, RB-07, RB-22 | 3.5 | merged at 23cf8a90 | `server/test/fix_fx2_db_store_home.test.mjs` |
| FX2-2-trace-telemetry: RB-31, RB-32, RB-49, RB-21, candidate 21 | 3.5 | merged at 8ed7538f | `server/test/fix_fx2_trace_telemetry.test.mjs`; `docs/security/audit-2026-11/server.md` |
| FX2-3-shop: RB-08, RB-09, RB-11, RB-10, RB-13 | 4.0 | merged at c7cdcbbd | `server/test/fix_fx2_shop.test.mjs` |
| FX2-4-purge-notify: RB-33, RB-34, RB-46, RB-47, RB-48 | 4.0 | merged at e413e4a9 | `server/test/fix_fx2_purge_notify.test.mjs`. Commits: 7dad0e16 (tests), 81580799 (test assertion name), 0c9e6c67 (RB-33), 0f3b6494 (RB-34), a9678f50 (RB-46), e4b8d44c (RB-47), 5cdb0318 (RB-48), 20acfab8 (merge of main), b4445a58 (status) |
| FX2-5-auth-lows: RB-23, RB-24, RB-25, RB-26, RB-60, candidate 23 | 4.0 | merged at 5f1cc425 | `server/test/fix_fx2_auth_lows.test.mjs`. Commits: 83ba326a (tests), b63fe5ca (RB-23), d981f86f (RB-24), 51c133ad (RB-25), 20fd2dee (RB-26), 268243b4 (RB-60 test guard), cfc93897 (RB-60), df07570d (candidate 23), 5e4979d0 (merge of main), 82e31a1 (RB-25: FX2-R1's three test lines), 326f9a2 (merge of main 57c23193) |
| FX2-6-audit-server-b: the audit of main.mjs's configuration and fourteen server modules | 4.0 | merged at ab25eb88 | `docs/security/audit-2026-11/server-b.md`; `server/test/fix_fx2_audit_*.test.mjs`, `server/test/fix_fx2_open.mjs`. Commits: 1080f1f9 (proofs), 8e5040b9 (AUD-B-11), aff2441c (AUD-B-09), 40f375df and 53796600 (AUD-B-08), b0f8519b (AUD-B-12), 2235e681 (AUD-B-03, AUD-B-04), 7d713b26 (AUD-B-02, AUD-B-07), a8886d67 (report), 1cb9620a (merge of main), d259b10f (status) |
| FX2-7-audit-b-config: AUD-B-14, 15, 16, 17, 18, 19 (main.mjs's configuration) | 1.5 | merged at bc7f27e8 | `server/test/fix_fx2_audit_config.test.mjs`; `docs/security/audit-2026-11/server-b.md`. Commits: bfe73490 (proofs), 51006c1a (AUD-B-14 proof corrected), c0a00136 (AUD-B-14, 17, 19), 323293f8 (AUD-B-15), c7e630cc (AUD-B-16), 35a8ea86 (AUD-B-18), 4372844d (report), 0006a4d9 (merge of main 92beb32b) |
| FX2-8-audit-b-lows: AUD-B-05, 10, 13, 20 | 2.0 | merged at cd5f98fb | `server/test/fix_fx2_audit_auth.test.mjs`, `fix_fx2_audit_privacy.test.mjs`, `fix_fx2_audit_load.test.mjs`; `docs/security/audit-2026-11/server-b.md`. Commits: 35be457f (proofs), 85dfb089 (AUD-B-10), d049bd61 (AUD-B-05), 6f61d03a (AUD-B-13), 5229de90 (AUD-B-20), 3820abc7 (report), 708d5e5d (status, FX2-R2), 4d3e779c (merge of main ee42bb70) |
| FX2-9-audit-b-match: AUD-B-01, AUD-B-06 (= FX1-A-07), FX1-A-09 | 1.25 | ready at f2181cf5 | `server/test/fix_fx2_audit_match.test.mjs`, `fix_fx2_audit_season.test.mjs`, `fix_fx2_audit_observatory.test.mjs`, `fix_fx1_audit_server_a.test.mjs`, `generated.test.mjs`; `docs/security/audit-2026-11/server-b.md`, `server-a.md`. Commits: 965a64bd (proofs), 10a603a0 (AUD-B-01), 832c247d (AUD-B-06, FX1-A-07), 0201e4f2 (FX1-A-09), 4a0e2258 (reports), aa9b046f (status), f2181cf5 (merge of main 613f71c9) |

## Handoff
- **Last verified commit:** f2181cf5, the merge of main (lead cycle 170, 613f71c9) into aa9b046f with no conflict; the merge changed only the lead's files (`docs/progress/`, `docs/audit/`, `docs/roadmap/`). The commits after it change only this handoff and the status file.

### The proofs (965a64bd, run on main's code `ad0191ea`)
The `stillOpen` wrappers of AUD-B-01 (two tests), AUD-B-06 and FX1-A-07 became plain proofs. The FX1-A-09 test now asserts the lead's answer to FX1-R9, and `fix_fx2_audit_match.test.mjs` is new. All committed alone, before any fix. On main, with the wasm built, 7 tests failed:

| Test | Failure on main |
|---|---|
| AUD-B-01, the hourly target lists do not fix an absent island owner's tier price | "10 × 21 ÷ 56, rounded": expected 4, actual 10 |
| AUD-B-01, a raider's Observatory view does not open the target owner's standing | "the defender has not appeared in season 2": a standing row is there (actual 1) |
| AUD-B-06, an island republished with a closed chapter's law within the hour is not shown | "a chapter-2 island is shown to a chapter-1 raider" |
| FX1-A-07, a card swapped to a republished island shows only laws from the raider's open chapters | "a chapter-2 island is not offered to a chapter-1 raider": the target list holds the new bundle `fec07672…` |
| FX1-A-09, the list says echoes only when an echo is among its targets (fix_fx1_audit_server_a) | "no echo is among the targets": expected false, actual true |
| FX1-A-09, a thin list that reached for an echo it did not offer does not say echoes (fix_fx2_audit_match) | "the list says no echo is among its targets": expected false, actual true |
| generated.test.mjs, a thin list reaches for the game's generated islands … | "no echo is offered: there is none (FX1-A-09)": expected false, actual true |

The control in `fix_fx2_audit_match.test.mjs` (a thin list that offers an echo says so) passes on main and after the fix.

### Tests corrected
- **`server/test/generated.test.mjs:56`** asserted `thin.echoes === true` ("echoes first") with no echo among the candidates, which is the defect FX1-A-09 names. Corrected to `false`. The rest of the test (the generated island is offered, `generated` is true) is unchanged.
- **The FX1-A-09 test in `fix_fx1_audit_server_a.test.mjs`** asserted today's behaviour as "contested". It now asserts `echoes` is false, per FX1-R9's answer, and is renamed to say what it checks.
- No other test changed. `matchmaking.test.mjs:108` (a thin list with an echo among its targets says echoes) and `fix_fx1_workshop_pairs.test.mjs:106` (false, false) hold under the fix unchanged.

### The fixes (all in `server/src/matchmaking.mjs`)
- **AUD-B-01** (10a603a0): `renownSeen(account, now)` reads the owner's standing if there is one, else where it would start (the last season's close pulled back, or 0), the way `profile.mjs`'s `leagueSeen` does, and writes nothing. `live()` (an owner with no standing) and `fresh()` (an echo's owner) use it in place of `seasons.league`. `raider()` still calls `seasons.league` for the raider: that is the raider appearing in the season.
- **AUD-B-06 = FX1-A-07** (832c247d): FX1's proposal. `current()` cannot read the raider, so a swapped card takes its new bundle's chapter (`bundleChapter`), and a swap whose chapter is above the card it replaces, or whose bytes are gone (null, FX1-A-01), is dropped. The island returns in the next hourly list, filtered as usual.
- **FX1-A-09** (0201e4f2): the reach is unchanged (the internal flag is now `withEchoes`); the returned `echoes` is `targets.some((c) => c.echo)`.
- **FX1-6's fixes on the same lines are kept:** FX1-A-01 (`bundleChapter` null), FX1-A-06, FX1-A-08 and FX1-A-11 tests pass.
- **Reports** (4a0e2258): in `server-b.md` AUD-B-01 and AUD-B-06 read "fixed (FX2-9-audit-b-match)", each with a Fixed line, and the summary sentence counts two in FX2-9 and none open. In `server-a.md` FX1-A-07 and FX1-A-09 read the same; FX1-A-09 is no longer marked contested, and its entry gives the answer and the tests.

### A corner outside the task's files
- `observatory.mjs:140` takes `echoes` from `offer()`'s list before `current()` filters it. An echo whose owner is banned or deleted within the hour is dropped by `current()`, but the view can still say `echoes: true`. `observatory.mjs` is not FX2-9's. A one-line follow-up there: `echoes: targets.some((c) => c.echo)`. No request: it is telemetry only, and the lead can seed it.

### Merge and evidence
- **`cd server && npm test`** on 4a0e2258: 633 tests, 633 pass, 0 fail, 0 skipped.
- **`python3 tools/coord/owners.py diff FX2-9-audit-b-match origin/claude/videogame-project-analysis-ewkkk2 f2181cf5…`:** "every changed path is inside its files".
- **check_all:** `bash tools/run_checks.sh start` on f2181cf5, in bwrap: PASS, finished 2026-11-24T04:19:09Z. The log ends `DONE exit=0` and contains "All checks passed." Recorded with `record f2181cf5… FX2`.

## Tried and failed
- 2026-11-21 The first RB-32 drain test passed on main, for the wrong reason (`401 session_refused`). Its session was made before the clock moved 12 h, and a session lasts an hour. It now signs in after the clock moves.
- 2026-11-21 Tried to make RB-49 fail on main by forcing query plans: `NOT INDEXED`, `INDEXED BY`, a dropped index and `reverse_unordered_selects`. All returned the right raider. See "The tests".
- 2026-11-21 Ran the Nursery tests before building the wasm: "ruleborn_sim.wasm is not built". Built it with `cargo build --release --target wasm32-unknown-unknown` in `sim/`.
- 2026-11-21 Raised the test Nursery to level 2 with the starting Spire: refused, `needs_spire_level`. The test helper now sets the Spire to level 3.
- 2026-11-21 `(cd server && npm ci)` in the setup line: no `package-lock.json` in `server/`. Ran `npm install` instead and deleted the lock file it wrote.
- 2026-11-21 `git merge origin/main`: "refusing to merge unrelated histories". The program's main is `origin/claude/videogame-project-analysis-ewkkk2`; merged that instead.
- 2026-11-21 The RB-33 test called `assert.notmatch`, which node's assert does not have. Corrected to `assert.doesNotMatch` in 81580799.
- 2026-11-23 Marked open findings with node's `todo`: `tools/coord/status.py` counts a top-level `not ok` as failed, `todo` included. Wrote `stillOpen` (`server/test/fix_fx2_open.mjs`) instead.
- 2026-11-23 AUD-B-08's first fix (40f375df) answered 503 in the route before anything else. It broke `limits.test.mjs:135` (G44: a 4xx sign-in failure counts) and `security_config.test.mjs:94` (SR-23: the cross-site check comes first). Moved the refusal into `deleteByGoogle` as a 401 (53796600).
- 2026-11-23 The AUD-B-04 skew broke `telemetry.test.mjs:67`, whose "too far ahead" event was 1 ms past the server's clock. Moved its threshold past the skew.
- 2026-11-23 Ran FX2-7's proofs on main before building the wasm: every boot failed for that reason, not the finding's. Built it with `cargo build --release --target wasm32-unknown-unknown` in `sim/`.
- 2026-11-23 AUD-B-14's corrected proof booted with the helper's real sign-in, so the inside-data check refused the start. It now boots with stubbed sign-in only (51006c1a).
- 2026-11-24 AUD-B-05's FX2-6 proof retried with the spent nonce, which the Fix keeps spent: no fix could pass it. The retry now uses the 404's fresh nonce.
- 2026-11-24 AUD-B-13's rewording changes `server/declarations.md` (generated, checked by `privacy.test.mjs`), outside the task's files: FX2-R2.
- 2026-11-24 Ran FX2-9's proofs before the setup line had built the wasm: "ruleborn_sim.wasm is not built" in every service test. Built it with `cargo build --release --target wasm32-unknown-unknown` in `sim/` and ran them again.
