# FX2 fixer, server B: progress

- Status: Waiting. FX2-4-purge-notify is ready at b4445a58 once check_all passes (running). It has fail-first tests, fixes for RB-33, RB-34, RB-46, RB-47 and RB-48, and main merged. `cd server && npm test` passes 566 of 566.
- Progress: 3 of 4 tasks merged (FX2-1 at 23cf8a90, FX2-2 at 8ed7538f, FX2-3 at c7cdcbbd), FX2-4 ready. No gate items.
- Done: RB-33, RB-34, RB-46, RB-47 and RB-48, each with a test written first that fails on main.
- Next: the lead's merge of FX2-4.
- Blocked by: none.
- Owner decision needed: none.

| Deliverable | Weight (h) | Status | Evidence |
|---|---:|---|---|
| FX2-1-db-store-home: RB-01, RB-02, RB-07, RB-22 | 3.5 | merged at 23cf8a90 | `server/test/fix_fx2_db_store_home.test.mjs` |
| FX2-2-trace-telemetry: RB-31, RB-32, RB-49, RB-21, candidate 21 | 3.5 | merged at 8ed7538f | `server/test/fix_fx2_trace_telemetry.test.mjs`; `docs/security/audit-2026-11/server.md` |
| FX2-3-shop: RB-08, RB-09, RB-11, RB-10, RB-13 | 4.0 | merged at c7cdcbbd | `server/test/fix_fx2_shop.test.mjs` |
| FX2-4-purge-notify: RB-33, RB-34, RB-46, RB-47, RB-48 | 4.0 | ready at b4445a58 | `server/test/fix_fx2_purge_notify.test.mjs`. Commits: 7dad0e16 (tests), 81580799 (test assertion name), 0c9e6c67 (RB-33), 0f3b6494 (RB-34), a9678f50 (RB-46), e4b8d44c (RB-47), 5cdb0318 (RB-48), 20acfab8 (merge of main), b4445a58 (status) |

## Handoff
- **Last verified commit:** b4445a58, the `ready_sha`. It is 20acfab8 (main 6cfd40b4 merged) plus the status file. The commit after it changes only this handoff and the status file.

### The tests
- All five tests are in one file, `server/test/fix_fx2_purge_notify.test.mjs`, committed alone in 7dad0e16 before any fix. They were run on 7dad0e16, whose `server/src/` is main's. All five fail:
  - **RB-33** (`a bundle is served only at the one URL the under-13 purge names`): `/v1/bundles/b5bbd56f…b232?v=2 is not a URL the edge would ever be asked to purge`, `200 !== 404`.
  - **RB-34** (`an under-13 deletion asks the edge to purge the target lists that named the child`): `the edge was asked to purge the list; asked=["/v1/bundles/b5bbd56f…b232"]`. Only the island's bundle was purged.
  - **RB-46** (`the raid notification lists only validated heists, never a refused submission`): the push also listed `{ grade: null, heist: 'b9c4cfda…535e' }`, the refused junk submission.
  - **RB-47** (`a friendly heist after the day's first raid is told in the same message`): the push listed only the raid; the expected `{ grade: 'foiled', heist: 'dee9f4ff…7883' }` was missing.
  - **RB-48** (`a raid that lands while a push is in flight is told once, after the push is retried`): `each raid told once`. N1 was sent with `[x1, x2, x3]` and N2 with `[x2, x3]`: actual tokens `[x3, x3, x1, x2, x2]`, expected `[x3, x1, x2]`.
- **One test line was corrected after the fail-first commit** (81580799): the RB-33 test called `assert.notmatch`, which does not exist; node's name is `assert.doesNotMatch`. On main the test failed before reaching that line, at the status check quoted above, so the failure is unchanged.

### The fixes
- **RB-33** (0c9e6c67, `http.mjs` `GET /v1/bundles`). The report's Fix: a bundle is served only when the path is exactly `bundlePath(hash)` (`edge.mjs`, the path the purge names) and the URL has no `?`, even an empty one. `?v=2`, `/x`, a trailing `/` and a bare `?` answer 404 `not_found`.
- **RB-34** (0f3b6494, `accounts.mjs` `finishErasures`). The report's Fix: it reads every list and previous hash named in `target_lists` before `targetLists({keepPrevious: false})` and after it, and queues an edge purge (`queuePurge`) for each named before and not after. `deleteAccount` already calls `purgeEdge` after an under-13 deletion. A list that did not name the child keeps its hash, so it is not purged.
  - Not fixed, outside the entry: a crash between the remake and the queued purges loses those purges; the next start's `finishErasures` sees the new lists only.
- **RB-46** (a9678f50, `notifications.mjs` `raids`). The report's Fix: `h.validated = 1` in the query. `validated` is final when the heist row is written (`service.settle`), so no heist turns validated later.
- **RB-47** (e4b8d44c, `notifications.mjs` `raids`). The report's Fix: `l.echo = 0` replaces `${RAIDED}`, matching `grant()`, which notifies every heist that is not an echo and whose defender is not deleted. The `RAIDED` import is gone from `notifications.mjs`; `matchmaking.mjs` still exports and uses it. Whether friendly heists should notify at all is still the open design question the report names; this makes the result independent of the order heists land in.
- **RB-48** (5cdb0318, `notifications.mjs`). The report's Fix, with one further change it needs:
  - `send()` claims a notification and, in the same transaction, resolves a raid notification's list with `raids(n)` and stores it without `since`. The message is the stored data, and a retry sends the same list.
  - `raided()` now joins the newest waiting raid notification (`ORDER BY id DESC`). Without this, a raid x3 landing while N1 (resolved, waiting for its retry) and N2 (reading by reference) both wait could be written into N1 by name and also read by N2, which is a new double. The test covers that case.
  - Not fixed, outside the entry: a heist with the same millisecond as a claim and as a later raid's `since` could be read by both. This needs two writes in one millisecond.
- **Existing tests:** none was changed, skipped or loosened.

### Merge and evidence
- **Merge:** main 6cfd40b4 (lead cycle 160: backlog, the lead's files and status only) merged at 20acfab8 with no conflict. It changed no file under `server/`, so the setup from the start of the session holds.
- **Setup:** `rustup target add …` and `pip install …` ran, and `tools/ui_research` `npm ci` ran. `(cd server && npm ci)` fails, as `server/` has no `package-lock.json`. I ran `npm install` there instead and deleted the lock file it wrote, which is outside this task's files. `bash client/build.sh`: exit 0. The sim's wasm was built with `cargo build --release --target wasm32-unknown-unknown` in `sim/`. Setup exit 0.
- **`cd server && npm test`** on 20acfab8: 566 tests, 566 pass, 0 fail.
- **`python3 tools/coord/owners.py diff FX2-4-purge-notify origin/claude/videogame-project-analysis-ewkkk2 b4445a58`:** "every changed path is inside its files".
- **`bash tools/run_checks.sh`** (check_all, bwrap) on b4445a58: running.
- **Open hypotheses:** none.
- **Next step:** the lead's merge. This session ends here (one task per session).

## Tried and failed
- 2026-11-21 The first RB-32 drain test passed on main, for the wrong reason (`401 session_refused`). Its session was made before the clock moved 12 h, and a session lasts an hour. It now signs in after the clock moves.
- 2026-11-21 Tried to make RB-49 fail on main by forcing query plans: `NOT INDEXED`, `INDEXED BY`, a dropped index and `reverse_unordered_selects`. All returned the right raider. See "The tests".
- 2026-11-21 Ran the Nursery tests before building the wasm: "ruleborn_sim.wasm is not built". Built it with `cargo build --release --target wasm32-unknown-unknown` in `sim/`.
- 2026-11-21 Raised the test Nursery to level 2 with the starting Spire: refused, `needs_spire_level`. The test helper now sets the Spire to level 3.
- 2026-11-21 `(cd server && npm ci)` in the setup line: no `package-lock.json` in `server/`. Ran `npm install` instead and deleted the lock file it wrote.
- 2026-11-21 `git merge origin/main`: "refusing to merge unrelated histories". The program's main is `origin/claude/videogame-project-analysis-ewkkk2`; merged that instead.
- 2026-11-21 The RB-33 test called `assert.notmatch`, which node's assert does not have. Corrected to `assert.doesNotMatch` in 81580799.
