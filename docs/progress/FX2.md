# FX2 fixer, server B: progress

- Status: Green. FX2-6-audit-server-b is ready at d259b10f: 20 findings proven, 8 fixed here, 12 open with running proofs. `cd server && npm test` passes 607 of 607.
- Progress: 5 of 6 tasks merged (FX2-1 at 23cf8a90, FX2-2 at 8ed7538f, FX2-3 at c7cdcbbd, FX2-4 at e413e4a9, FX2-5 at 5f1cc425). FX2-6 is ready. No gate items.
- Done: the server-b audit, `docs/security/audit-2026-11/server-b.md`: AUD-B-01 to AUD-B-20, three unproven, seven rejected. Fixed here: AUD-B-02, 03, 04, 07, 08, 09, 11 and 12, each with a proof committed first that fails on main.
- Next: the lead merges FX2-6-audit-server-b and routes the twelve open findings, which are outside this task's files.
- Blocked by: nothing.
- Owner decision needed: none.

| Deliverable | Weight (h) | Status | Evidence |
|---|---:|---|---|
| FX2-1-db-store-home: RB-01, RB-02, RB-07, RB-22 | 3.5 | merged at 23cf8a90 | `server/test/fix_fx2_db_store_home.test.mjs` |
| FX2-2-trace-telemetry: RB-31, RB-32, RB-49, RB-21, candidate 21 | 3.5 | merged at 8ed7538f | `server/test/fix_fx2_trace_telemetry.test.mjs`; `docs/security/audit-2026-11/server.md` |
| FX2-3-shop: RB-08, RB-09, RB-11, RB-10, RB-13 | 4.0 | merged at c7cdcbbd | `server/test/fix_fx2_shop.test.mjs` |
| FX2-4-purge-notify: RB-33, RB-34, RB-46, RB-47, RB-48 | 4.0 | merged at e413e4a9 | `server/test/fix_fx2_purge_notify.test.mjs`. Commits: 7dad0e16 (tests), 81580799 (test assertion name), 0c9e6c67 (RB-33), 0f3b6494 (RB-34), a9678f50 (RB-46), e4b8d44c (RB-47), 5cdb0318 (RB-48), 20acfab8 (merge of main), b4445a58 (status) |
| FX2-5-auth-lows: RB-23, RB-24, RB-25, RB-26, RB-60, candidate 23 | 4.0 | merged at 5f1cc425 | `server/test/fix_fx2_auth_lows.test.mjs`. Commits: 83ba326a (tests), b63fe5ca (RB-23), d981f86f (RB-24), 51c133ad (RB-25), 20fd2dee (RB-26), 268243b4 (RB-60 test guard), cfc93897 (RB-60), df07570d (candidate 23), 5e4979d0 (merge of main), 82e31a1 (RB-25: FX2-R1's three test lines), 326f9a2 (merge of main 57c23193) |
| FX2-6-audit-server-b: the audit of main.mjs's configuration and fourteen server modules | 4.0 | ready at d259b10f | `docs/security/audit-2026-11/server-b.md`; `server/test/fix_fx2_audit_*.test.mjs`, `server/test/fix_fx2_open.mjs`. Commits: 1080f1f9 (proofs), 8e5040b9 (AUD-B-11), aff2441c (AUD-B-09), 40f375df and 53796600 (AUD-B-08), b0f8519b (AUD-B-12), 2235e681 (AUD-B-03, AUD-B-04), 7d713b26 (AUD-B-02, AUD-B-07), a8886d67 (report), 1cb9620a (merge of main), d259b10f (status) |

## Handoff
- **Last verified commit:** d259b10f, with main (lead cycle 166, 719c4ff3) merged at 1cb9620a with no conflict; the merge changed only `docs/progress/`. The commit after it changes only this handoff, the status file and one summary sentence of the report (the count of rejected suspicions).

### The proofs
- Every proof was committed in 1080f1f9, before any fix, and run on main's `server/src/`; each failed. The test names are in the report, one per entry.
- A finding proven but outside this task's files runs inside `stillOpen(id, proof)` (`server/test/fix_fx2_open.mjs`): it passes while the proof fails with an assertion error, rethrows any other error, and fails once the finding is fixed, saying so. Nothing is skipped. Whoever fixes one turns its wrapper back into the plain proof.

### The fixes (all in the task's files)
- **AUD-B-02 and AUD-B-07** (7d713b26, `observatory.mjs`): a card's `keeper_name` is null when generated or across a block (§17.8); an echo's card describes the one island the echo is.
- **AUD-B-03 and AUD-B-04** (2235e681, `telemetry.mjs`): the buyer share counts only buyers with a `session_start` in the period; a batch accepts a device clock up to `CLOCK_SKEW_MS` (5 min) ahead, keeping such an event at the server's time. `server/test/telemetry.test.mjs`'s "too far ahead" threshold moved to `T0 + CLOCK_SKEW_MS + 1`, which still tests the same refusal.
- **AUD-B-08** (53796600, `auth_http.mjs`): with no web client id, `deleteByGoogle` refuses with 401 `google_identity_refused` after reading the body, so the game's own Google token cannot delete through the web route.
- **AUD-B-09** (aff2441c, `auth.mjs`): a spent proof is refused through its window's last millisecond (`expires_at >= now`).
- **AUD-B-11** (8e5040b9, `auth.mjs`): an empty `RULEBORN_REFRESH_ROTATE_HOURS` is unset, not 0.
- **AUD-B-12** (b0f8519b, `pages.mjs`): "1 day", not "1 days".

### Open, for the lead to route (outside this task's files)
- High: AUD-B-14 (an empty `RULEBORN_DELETIONS` keeps the deletion journal in memory) and AUD-B-15 (Game Center and StoreKit roots without `RULEBORN_BUNDLE_ID` switch both off silently), both `main.mjs`.
- Medium: AUD-B-01 (`matchmaking.mjs`, target lists fix an absent owner's tier price), AUD-B-05 (`auth_http.mjs` prove and `delete.html`), AUD-B-16, 17 and 18 (`main.mjs` configuration).
- Low: AUD-B-06 (`matchmaking.mjs`), AUD-B-10 (`tokens.mjs:55`), AUD-B-13 (`privacy.json`), AUD-B-19 (`main.mjs:224`), AUD-B-20 (`load.mjs:453`).
- Each entry in the report has its proposed fix.

### A note for the lead (not a request)
- SR-14 is rejected as a finding: `social.mjs` follows the owner's ruling (`owner-decisions.md:41`) and `security_owner.test.mjs:82` guards it. But §20.7 gives a 13 to 15's co-op as "Friends only", and a crew of mixed ages may need squaring with it once co-op and the crew thread are built.

### Merge and evidence
- **`cd server && npm test`** on d259b10f: 607 tests, 607 pass, 0 fail.
- **`python3 tools/coord/owners.py diff FX2-6-audit-server-b origin/claude/videogame-project-analysis-ewkkk2 d259b10f`:** "FX2-6-audit-server-b: every changed path is inside its files".
- **check_all:** `bash tools/run_checks.sh` on d259b10f, in bwrap: PASS, finished 2026-11-23T22:21:52Z; the log ends `DONE exit=0` and contains "All checks passed." Recorded in the status file.
- **Main moved after the pre-check** (e2e8f5a1 and 876a87fd, lead cycle 167: FX1-4-holds-codex). It merges into d259b10f with no conflict, and on that merge in a scratch worktree `cd server && npm test` passes 613 of 613. Not committed here, so the ready sha stays the pre-checked one.

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
