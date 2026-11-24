# FX2 fixer, server B: progress

- Status: Green, blocked on one file grant. FX2-8-audit-b-lows's four findings are fixed, each proof plain and failing on main first. `cd server && npm test` passes 614 of 614 on the merge 4d3e779c. check_all PASS on it.
- Progress: 7 of 8 tasks merged (FX2-1 at 23cf8a90, FX2-2 at 8ed7538f, FX2-3 at c7cdcbbd, FX2-4 at e413e4a9, FX2-5 at 5f1cc425, FX2-6 at ab25eb88, FX2-7 at bc7f27e8). FX2-8 waits on FX2-R2. No gate items.
- Done: AUD-B-05 (Medium), AUD-B-10, AUD-B-13 and AUD-B-20 (Low) of the server-b audit.
- Next: the lead grants `server/declarations.md` (FX2-R2); then 4d3e779c can be taken as ready.
- Blocked by: FX2-R2, `server/declarations.md`, generated from `server/privacy.json` and outside the task's files. owners.py diff fails on that one path.
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

| FX2-8-audit-b-lows: AUD-B-05, 10, 13, 20 | 2.0 | blocked on FX2-R2 (pre-checked at 4d3e779c) | `server/test/fix_fx2_audit_auth.test.mjs`, `fix_fx2_audit_privacy.test.mjs`, `fix_fx2_audit_load.test.mjs`; `docs/security/audit-2026-11/server-b.md`. Commits: 35be457f (proofs), 85dfb089 (AUD-B-10), d049bd61 (AUD-B-05), 6f61d03a (AUD-B-13), 5229de90 (AUD-B-20), 3820abc7 (report), 708d5e5d (status, FX2-R2), 4d3e779c (merge of main ee42bb70) |

## Handoff
- **Last verified commit:** 4d3e779c, the merge of main (lead cycle 169, ee42bb70) into 708d5e5d with no conflict; the merge changed only `docs/progress/lead.md`. The commits after it change only this handoff and the status file.

### The proofs (35be457f, run on main's code)
Each `stillOpen` wrapper of the three test files became the plain proof, committed alone. On main, 7 tests failed and 4 passed (the regression tests of FX2-6's fixes: AUD-B-08, AUD-B-09, AUD-B-11 and AUD-B-12). The failures on main:

| Test | Failure on main |
|---|---|
| AUD-B-05, the right account after a wrong one (404) still deletes | `typeof nonce`: expected 'string', actual 'undefined' |
| AUD-B-10, a token key named `constructor` | "the key is refused: token key constructor is named twice" |
| AUD-B-13, no "(docs/security/auth.md)" | expected -1, actual 11863 |
| AUD-B-13, no "(expireReplays)" | expected -1, actual 13141 |
| AUD-B-13, no "(snapshots)" | expected -1, actual 12846 |
| AUD-B-13, no "it is log" | expected -1, actual 13468 |
| AUD-B-20, daily players within the free plan's reads | "engaged: 4487 daily players read 6314555 rows a day": expected true, actual false |

### Tests corrected
- **AUD-B-05's proof, FX2-6's version,** retried with the same spent nonce and expected 200. The Fix line says the nonce stays spent, so no fix could pass it. In 35be457f the retry uses the fresh nonce and cookie the 404 hands back. A control asserts the spent nonce is still refused (401). Run on main, it fails on the missing nonce (above). No other test changed.

### The fixes
- **AUD-B-10** (85dfb089, `tokens.mjs`): `Object.hasOwn(keys, kid)` in `keyring`.
- **AUD-B-05** (d049bd61, `auth_http.mjs`, `web/delete.html`): the Fix line's second way. `deleteByGoogle` catches its own `no_such_account` refusal, after `signIn` has counted the failure. It answers 404 `{error, nonce}` with a fresh nonce, and sets that nonce's `__Host-rb_delete` cookie. The page then calls `google.accounts.id.initialize` with the new nonce and renders the button again, with a message saying to use the Google account they play with. Any other failure says to reload. The CSP hash follows the script automatically (`DELETE_SCRIPT`). I checked the page script by evaluating it in node with a stubbed `google`, `document` and `fetch`. It has **not been tried against live Google Sign-In**.
- **AUD-B-13** (6f61d03a, `privacy.json`): the four texts reworded. "for good: it is the deletion log" is one of them. `plain` is not widened. The unproven "withdraw choice an object" was rechecked against `accounts.mjs`'s `Journal`, which writes one object a deletion, `{account, reason, withdraw, at}`. It now reads "whether the player withdrew their Workshop islands, each deletion one object". `node server/src/privacy.mjs --write` rewrote `server/declarations.md` (3 lines), which `privacy.test.mjs` requires. That file is FX2-R2.
- **AUD-B-20** (5229de90, `load.mjs`, `load.json`): `READS.freeDay / readsADay(result, dd / dn)`. `load.json` was rewritten by `node server/load.mjs --write` (56 s): engaged 3504, regular 6178, casual 8497 players a day, where it was 4487, 9773 and 16995. The kept reads moved by about 2% (engaged 967.5 → 987 rows a player a day), with main's queries since the last write. `node server/load.mjs --check` passes.
- **Capacity notes:** I grepped the repository for 4487, 9773 and 16995 and for `freePlanReadsPlayersADay`. Only `server-b.md` (this task's) quotes them. The design document's "1,500 per player-day at 10,000 monthly players" (v3.7, 24.1) is the budget's own arithmetic, not this figure. So no request was needed.
- **Report** (3820abc7): the four States read "fixed (FX2-8-audit-b-lows)". Each entry has a "Fixed" line, the summary sentence counts four here and two open, and the withdraw-choice suspicion is marked settled.

### Requests
- **FX2-R2** (to the lead): grant `server/declarations.md` to FX2-8-audit-b-lows as an exception. It is written from `privacy.json` (above). SV-B7-B9 held both files the same way. Default: granted; 4d3e779c is the ready sha.

### Merge and evidence
- **`cd server && npm test`** on 4d3e779c: 614 tests, 614 pass, 0 fail, 0 skipped.
- **`python3 tools/coord/owners.py diff FX2-8-audit-b-lows origin/claude/videogame-project-analysis-ewkkk2 4d3e779c`:** "not owned by FX2-8-audit-b-lows: server/declarations.md", the one path of FX2-R2. With the grant it passes, since every other path is a task file.
- **check_all:** `bash tools/run_checks.sh start 4d3e779c`, in bwrap: PASS, finished 2026-11-24T01:17:59Z. The log ends `DONE exit=0` and contains "All checks passed." Recorded with `record 4d3e779c… FX2`.
- **Stopped here:** `task_state: blocked` on FX2-R2 (blocking), not answered by 01:18Z. Once it is granted, 4d3e779c is the ready sha: nothing else is left to do.

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
