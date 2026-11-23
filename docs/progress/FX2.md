# FX2 fixer, server B: progress

- Status: Green. FX2-7-audit-b-config is ready at 0006a4d9: AUD-B-14 to AUD-B-19 fixed in `server/src/main.mjs`, each proof plain and failing on main first. `cd server && npm test` passes 614 of 614.
- Progress: 6 of 7 tasks merged (FX2-1 at 23cf8a90, FX2-2 at 8ed7538f, FX2-3 at c7cdcbbd, FX2-4 at e413e4a9, FX2-5 at 5f1cc425, FX2-6 at ab25eb88). FX2-7 is ready. No gate items.
- Done: main.mjs's configuration findings of the server-b audit: AUD-B-14 and AUD-B-15 (High), AUD-B-16, 17 and 18 (Medium), AUD-B-19 (Low).
- Next: the lead merges FX2-7-audit-b-config and routes AUD-B-18's residual guard in `seasons.mjs` (below).
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
| FX2-7-audit-b-config: AUD-B-14, 15, 16, 17, 18, 19 (main.mjs's configuration) | 1.5 | ready at 0006a4d9 | `server/test/fix_fx2_audit_config.test.mjs`; `docs/security/audit-2026-11/server-b.md`. Commits: bfe73490 (proofs), 51006c1a (AUD-B-14 proof corrected), c0a00136 (AUD-B-14, 17, 19), 323293f8 (AUD-B-15), c7e630cc (AUD-B-16), 35a8ea86 (AUD-B-18), 4372844d (report), 0006a4d9 (merge of main 92beb32b) |

## Handoff
- **Last verified commit:** 0006a4d9, the merge of main (lead cycle 167, 92beb32b) into 4372844d with no conflict; the merge changed only `docs/progress/`. The commit after it changes only this handoff and the status file.

### The proofs (bfe73490, run on main's `main.mjs`)
Each `stillOpen` wrapper of `fix_fx2_audit_config.test.mjs` became the plain proof, committed alone. On main's code, 8 tests failed and 2 passed: the defaults control, and AUD-B-18's service proof, which stays in `stillOpen`. The failures on main:

| Test | Failure on main |
|---|---|
| AUD-B-14, empty `RULEBORN_DELETIONS` keeps the journal on disk | "the journal's folder is on disk": `false !== true` |
| AUD-B-14, real sign-in and empty `RULEBORN_DELETIONS` refused | `true !== false` (it started) |
| AUD-B-15, Apple roots without the bundle id refused | "RULEBORN_GAMECENTER_ROOTS": `true !== false` |
| AUD-B-16, empty `RULEBORN_MAX_CONNECTIONS` keeps the default | "the listener answers (got ECONNRESET)": expected 'number', actual 'string' |
| AUD-B-16, unreadable `RULEBORN_MAX_CONNECTIONS` refused | "abc": `true !== false` |
| AUD-B-17, empty `RULEBORN_HEADERS_TIMEOUT_MS` keeps 10 s | `false !== true` (the socket stayed open) |
| AUD-B-18, `RULEBORN_SEASON_START=next monday` refused | `true !== false` |
| AUD-B-19, empty `RULEBORN_REPLAYS_MIN_FREE_MB` keeps 512 MiB | `0 !== 536870912` |

### Tests corrected (the expectation encoded the defect, or was wrong)
- **AUD-B-14's first proof**, FX2-6's version, showed that `new Store("")` loses an entry, which is that store's design and not the defect. In bfe73490 it boots `main.mjs` with an empty `RULEBORN_DELETIONS` and asserts that the journal's folder `data/deletions` is on disk, and that the inside-data warning names it (the folder checked is the folder used).
- **The same proof, again (51006c1a):** the boot helper sets `RULEBORN_GOOGLE_CLIENT_IDS`, so it ran with real sign-in, and the inside-data check refused the start it asserts. It now boots with the client ids empty, which is stubbed sign-in. Re-run on main's `main.mjs`, it still fails: "the journal's folder is on disk", `false !== true`.
- Two proofs were added beside the plain ones. AUD-B-15 checks GC roots only, StoreKit only, and both. AUD-B-16 refuses `abc`, `0`, `-1` and `1.5`. No other test changed.

### The fixes (all in `server/src/main.mjs`)
- **AUD-B-14, and AUD-B-17 and AUD-B-19 by the same step** (c0a00136): `settled(process.env)`, at the top, deletes every empty or blank `RULEBORN_*` variable before any is read, so each `??` takes its default.
  - **Not as the Fix line says:** the `Store` is not given `journalDir`. `security_deep_heists.test.mjs:54` pins its expression, and that file is not mine. After `settled()`, both expressions name the same folder, and the first AUD-B-14 proof shows it.
  - `security_deep_heists.test.mjs:52` and `security_deep_http.test.mjs:147,149` pin the other three expressions, which are unchanged too.
- **AUD-B-15** (323293f8): Game Center or StoreKit roots without `RULEBORN_BUNDLE_ID` stop the start, as the Play pair does.
- **AUD-B-16** (c7e630cc): after `settled()`, `RULEBORN_MAX_CONNECTIONS` and `RULEBORN_HEADERS_TIMEOUT_MS` must each be a whole number of at least 1, or unset. `RULEBORN_REPLAYS_MIN_FREE_MB` must be one of at least 0, because `docs/guides/server.md:93` documents 0 as turning the floor off. Any other value stops the start.
- **AUD-B-18** (35a8ea86): `main.mjs` parses `RULEBORN_SEASON_START` before building the service and stops the start when the value is not finite.

### For the lead to route (outside this task's files)
- AUD-B-18's second proof, "with seasonStart NaN there is no current season", stays in `stillOpen("AUD-B-18 (seasons.mjs)")`. The seasons constructor's own guard is in `seasons.mjs`. `main.mjs` now refuses the value first, so this is defence in depth, Low at most.

### Merge and evidence
- **`cd server && npm test`** on 4372844d and on 0006a4d9: 614 tests, 614 pass, 0 fail, 0 skipped.
- **`python3 tools/coord/owners.py diff FX2-7-audit-b-config origin/claude/videogame-project-analysis-ewkkk2 0006a4d9`:** "FX2-7-audit-b-config: every changed path is inside its files".
- **check_all:** `bash tools/run_checks.sh start 0006a4d9`, in bwrap, after the fresh-container setup (it exited 0). The result is in the status file's `precheck`, recorded with `record 0006a4d9… FX2`.

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
