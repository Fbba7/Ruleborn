# FX2 fixer, server B: progress

- Status: Green. check_all PASS on 5281e8fb. FX2-10-curated-woven-law: SIM-12's server half and FX2-9's observatory.mjs:140 follow-up are fixed, each proof failing first. `cd server && npm test` passes 639 of 639.
- Progress: 8 of 10 tasks merged. FX2-9 is ready at f2181cf5, in the lead's merge. FX2-10 is built on it. No gate items.
- Done: SIM-12's "Left for the lead" (`woven_law_missing`); the Observatory's `echoes` flag after `current()`.
- Next: the lead answers FX2-R3 (server/test/setup.mjs), merges f2181cf5, then FX2-10's ready_sha 5281e8fb.
- Blocked by: FX2-R3 (blocking, default: granted).
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
| FX2-9-audit-b-match: AUD-B-01, AUD-B-06 (= FX1-A-07), FX1-A-09 | 1.25 | ready at f2181cf5, in the lead's merge | `server/test/fix_fx2_audit_match.test.mjs`, `fix_fx2_audit_season.test.mjs`, `fix_fx2_audit_observatory.test.mjs`, `fix_fx1_audit_server_a.test.mjs`, `generated.test.mjs`; `docs/security/audit-2026-11/server-b.md`, `server-a.md`. Commits: 965a64bd (proofs), 10a603a0 (AUD-B-01), 832c247d (AUD-B-06, FX1-A-07), 0201e4f2 (FX1-A-09), 4a0e2258 (reports), aa9b046f (status), f2181cf5 (merge of main 613f71c9) |
| FX2-10-curated-woven-law: SIM-12's Left for the lead, FX2-9's observatory.mjs:140 follow-up | n/a (no weight in backlog.json) | ready at 5281e8fb | `server/test/fix_fx2_curated_woven_law.test.mjs`, `fix_fx2_observatory_echoes.test.mjs`; `docs/security/audit-2026-11/sim.md`. Commits: 9fe9f86 (echoes proof), 5d4e59c (woven-law proof), ac08a0c (SIM-12), c4f746a (echoes), a495e58 (setup.mjs, FX2-R3), 22928c2 (status), 8713e6a and 61b1c9b (report), 5281e8f (merge of main 5963037) |

## Handoff
- **Last verified commit:** 5281e8fb, the merge of main (lead cycle 171, 5963037) into 61b1c9b with no conflict. The merge changed only the lead's files.
- **FX2-9:** not resynced. f2181cf5 is still not on main. FX2-10's branch holds it, so until the lead merges it, `owners.py diff` against main also lists FX2-9's files (matchmaking.mjs, server-a.md, server-b.md and five tests).

### The proofs, committed alone, before any fix
Both were run on the branch before the fix. Its server code was main's plus FX2-9's `matchmaking.mjs`, which touches neither `universe.mjs` nor the view's flag.

**9fe9f86, `server/test/fix_fx2_observatory_echoes.test.mjs`:** an echo whose owner is banned within the hour is dropped from the view by `current()`. On main the view still says `echoes: true`:
```
not ok 1 - FX2-9 follow-up: an echo dropped from the view because its owner was banned within the hour is not said (12.3)
  error: the view says no echo is among its targets   (true !== false)
```

**5d4e59c, `server/test/fix_fx2_curated_woven_law.test.mjs`:** SIM-12's three cases, a control and the hand-built case. On main:
```
not ok 1 - SIM-12: a curated layout given more woven laws than it has pylon spots is refused as woven_law_missing, not published without them (SR-16, 13.3)
  error: 'Missing expected exception (missing).'
not ok 2 - SIM-12: a curated layout given a woven law id the simulation does not know is refused as woven_law_missing, not published without it (SR-16, 13.3)
  error: Caught error: (stability: a law or school the simulation does not know)
not ok 3 - SIM-12: the generator's last draw, which keeps the realm's buildings and loses a woven law, is refused as woven_law_missing (SR-16, 13.3)
  error: 'Missing expected exception (missing).'
ok 4 - SIM-12: a curated layout with every woven law is still published (SR-16, 13.3)
not ok 5 - SR-16: a hand-built island without a law its realm wove is named woven_law_missing, and with every woven law it is not (24.8)
  error: 'Bloom is woven and not on the island: vault_level_not_built'
```
- **Case 1** weaves four laws in the Heart's rows. The Heart has two slots, and the generator's `zip` stops at the pylon spots it drew.
- **Case 2** weaves `no_such_law`. On main, publish then fails with the stability error instead of a named refusal.
- **Case 3**, the 64th draw: the server cannot feed it naturally. Not one of 19,200 seed and spire positions tried makes every draw fail. So the test stubs `build.curated` to answer the original's layout with the laws taken off. The build is shared by the test servers, so the stub is restored in a `finally`.

### The fixes
- **SIM-12 (ac08a0c, `server/src/universe.mjs` `problems()`):** names `woven_law_missing` when a law the realm wove, and has finished weaving, is not on the island. It is one entry however many woven laws are missing, as `law_not_woven` is one entry however many laws are unwoven. publish already refuses any problem by name (422 `island_not_publishable`, `detail.problems`), so `layout` refuses it too. A slot being swapped is not in the woven set until its new law is ready, so swaps (CLI-1) are unchanged.
- **Hand-built islands are held to it too.** The design gives "one pylon per woven slot" in the realm view and the heist (§13.3), and SR-16 says a realm plays what its owner wove. No test or design line lets an island leave a woven law off.
  - **One corner for the lead:** `problems()` allows a bundle realm level below the realm's built level. Such an island has fewer law slots, so it may be unable to carry every woven law, and it would now be refused. No lawful case of this was found. If one should be allowed, scope the check to `origin: "generated"` in `curation.layout`.
- **FX2-9's follow-up (c4f746a, `server/src/observatory.mjs`):** `echoes` is read from the targets left after `current()`.
- **Report (8713e6a, 61b1c9b):** in `sim.md`, SIM-12's "Left for the lead (outside FX3's files)" reads "fixed (FX2-10-curated-woven-law)", with the fix and proof.

### Test corrected: FX2-R3
- **`server/test/setup.mjs` `weave()` (a495e58)** is outside FX2-10's files, so FX2-R3 asks the lead to grant it, with the default "granted".
  - The lenient test universe stands for an owner who wove what the island runs. It only ever added laws, so a test that republishes a different island kept the first island's laws woven. That shim encoded the defect.
  - With the fix, 9 tests were refused as `island_not_publishable`: crossings.test.mjs:155, fix_fx2_audit_observatory.test.mjs:27, fix_fx2_observatory_echoes.test.mjs:13, matchmaking.test.mjs:115, observatory.test.mjs:145, privacy.test.mjs:328, security_limits.test.mjs:63, and service.test.mjs:158 and :198.
  - The shim now also unweaves the realm's laws the island does not run, and numbers new slots after the highest. No test file changed.

### Client words
- No row is needed. The client shows any 422 `island_not_publishable` as ERR_ISLAND_NOT_PUBLISHABLE ("the island breaks a building rule", strings.csv:232). It has no row per server problem, `law_not_woven` included. So I sent no request. If the lead wants one, it is `PROBLEM_WOVEN_LAW_MISSING`, with its owner in the client.

### Merge and evidence
- **`cd server && npm test`** on 5281e8fb: 639 tests, 639 pass, 0 fail.
- **`python3 tools/coord/owners.py diff FX2-10-curated-woven-law origin/claude/videogame-project-analysis-ewkkk2 5281e8fb…`:** lists `server/test/setup.mjs` (FX2-R3) and FX2-9's files, which are not on main yet. Measured from f2181cf5, FX2-10 changes only its own files, setup.mjs and files already on main.
- **check_all:** `bash tools/run_checks.sh start` on 5281e8fb, in bwrap, after the setup line: PASS, finished 2026-11-24T05:39:10Z. The log ends `DONE exit=0` and contains "All checks passed." Recorded with `record 5281e8fb… FX2`. The commits after 5281e8fb change only this handoff and the status file.

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
- 2026-11-24 Read the Observatory cards' `.echo`: the cards have `kind: "echo"`. Only the candidates (`list.targets`) have `.echo`. The test now reads `kind`.
- 2026-11-24 Probed SIM-12's unknown law id through `curation.view`: it throws a stability error, since `swaps` prices each law. Probed with `layoutSeed` and `layout` instead.
- 2026-11-24 Case 3's stub of the shared `build.curated` leaked into the next test. It is now restored in a `finally`.
- 2026-11-24 The global `woven_law_missing` broke 9 tests through setup.mjs's add-only `weave()`. Corrected the shim: FX2-R3.
- 2026-11-24 Numbered the shim's new slots by COUNT after its deletes, and slots collided. Numbered them after MAX(slot) instead.
