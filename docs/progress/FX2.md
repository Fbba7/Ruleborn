# FX2 fixer, server B: progress

- Status: Waiting. FX2-2-trace-telemetry is ready at 873809b4 (pre-check PASS, 17:01:26Z, recorded). It has fail-first tests, fixes for RB-31, RB-49, RB-21, RB-32 (server half) and candidate 21, and main merged. `cd server && npm test` passes 545 of 545.
- Progress: 1 of 2 tasks merged (FX2-1 at 23cf8a90, FX2-2 ready). No gate items.
- Done: RB-31, RB-49, RB-21, RB-32 (server half) and candidate 21, each with a test written first. All but RB-49 fail on main; RB-49 is explained below.
- Next: the lead's merge of FX2-2. Request FX2-2-r1 is answered: the default.
- Blocked by: none.
- Owner decision needed: none.

| Deliverable | Weight (h) | Status | Evidence |
|---|---:|---|---|
| FX2-1-db-store-home: RB-01, RB-02, RB-07, RB-22 | 3.5 | merged at 23cf8a90 | `server/test/fix_fx2_db_store_home.test.mjs` |
| FX2-2-trace-telemetry: RB-31, RB-32, RB-49, RB-21, candidate 21 | 3.5 | ready at 873809b4, pre-check PASS | `server/test/fix_fx2_trace_telemetry.test.mjs`; `docs/security/audit-2026-11/server.md`. Commits: 388febd5 (tests), 948d5975 (RB-31), 8d63feb9 (RB-49), 60dfab43 (candidate 21), 536f4e9d (RB-32), 7bbbf794 (RB-21), 5a4fdc72 (audit note), d2eb98cd (merge of main) |

## Handoff
- **Last verified commit:** 873809b4, the `ready_sha` (pre-check green, 2026-11-21T17:01:26Z, "All checks passed.", recorded in the status file). It holds the merge d2eb98cd and this handoff; the status commit that marks ready changes only the status file and this handoff.

### The tests
- All six tests are in one file, `server/test/fix_fx2_trace_telemetry.test.mjs`, committed alone in 388febd5 before any fix.
- They were run on 8c4f9b2d, whose `server/` is main 23cf8a90's. Five fail:
  - **RB-31** (`the Trace's island is not also offered as a paid target…`): `and not among the targets the device matches the Trace's bundle against`. Actual `['player']`, expected `[]`.
  - **RB-21** (`full_at counts a resting worker from the end of its rest…`): `resting: the same fill, two hours later`. Actual `null`, expected `1790204700000`.
  - **RB-32, drain** (`a device that drops a chunk the server will never take…`): `the queue drains: 429 too_many_session_starts` five times, `120 !== 0`.
  - **RB-32, contract** (`a refusal the same batch can never get past is not a 429…`): actual `'429 too_many_session_starts'`, expected `'422 too_many_session_starts'`.
  - **Candidate 21** (`a banned raider's island is not offered as a Trace the lease would refuse`): `no Trace to a banned raider`. Actual is a trace card `{ across: false, band: 0, … }`, expected `null`.
- **RB-49 passes on main** (`ok 2`), on this SQLite build.
  - Every plan I could force returns A, the most recent raider: the default plan, `NOT INDEXED`, `INDEXED BY heists_by_attacker`, the defender's index dropped, and `reverse_unordered_selects` 0 and 1.
  - Only a hand-written `FROM leases l CROSS JOIN heists h` gives B before A.
  - The test still pins the order through the dropped index and both `reverse_unordered_selects` settings. It stays as a guard against a planner change.
  - Written up in `docs/security/audit-2026-11/server.md`, "Notes on the fixed entries".

### The fixes
- **RB-31** (948d5975, `observatory.mjs` `view`). This follows the report's Fix: the Trace is worked out first, and its bundle is added to `aside` before the offer is built. Tapping the Trace now finds no paid card with its bundle. The test checks that the lease is `trace: true`, fee 0.
- **RB-49** (8d63feb9, `observatory.mjs` `trace`). This follows the report's Fix: `GROUP BY h.attacker ORDER BY MAX(h.submitted_at) DESC` replaces `SELECT DISTINCT … ORDER BY h.submitted_at DESC`.
- **Candidate 21** (60dfab43, the same query). It joins `accounts` and passes over a raider with `banned_at` or `deleted_at` set. The lease refuses those islands, so the Trace now moves on to the next raider. Confirmed and fixed. Written up under "Unproven, rechecked" in `docs/security/audit-2026-11/server.md`.
- **RB-21** (7bbbf794, `home.mjs` `rate`). This follows the report's Fix: with `{ ahead: true }`, `rate` also returns every worker, a resting one counted `from` the end of its rest (`max(from, away_until)`). The view's `fullAt` uses that list. `workers` and `per_hour`, now, are unchanged: a resting worker is still not counted as working.
- **RB-32**: the server half, as the task's title asks. This differs from the report's Fix line, which is mostly the client's.
  - The client's half is FX4-2-trace-events: chunks of 100, drop a chunk refused with a 4xx other than 429, keep it on a 429 or a 5xx. The drain test plays that rule against the real server.
  - On the server (536f4e9d, `telemetry.mjs`), the refusals no retry of the same batch can pass become 422, not 429:
    - `too_many_session_starts`, `too_many_session_ends` and `worth_too_often`, the per-day caps;
    - `survey_once_a_quarter`.
  - Under the old 429s, that rule kept the chunk forever (the drain test's 120 events).
  - `batch`'s doc comment now states the contract the device relies on:
    - 400, 413 or 422: drop the chunk.
    - 429 `too_many_requests` (with Retry-After) or a 5xx: keep the chunk.
    - 429 `too_many_events`: drop the chunk. It has no Retry-After.
- **`too_many_events` stays 429.**
  - SR-19's test, `server/test/security_limits.test.mjs:97` (`[202,202,202,202,429,429]`), pins it, and that file is outside this task's files.
  - Request FX2-2-r1 asked the lead to move it to 422. The lead answered in cycle 157: the default. It stays 429, FX4-2's client drops a chunk refused `429 too_many_events`, and `telemetry.mjs` documents that.
  - My contract test's last line expects `429 too_many_events` and names SR-19's test.
- **Existing tests:** none was changed, skipped or loosened. `telemetry.test.mjs` asserts the refusal reasons only, not the statuses. `limits.test.mjs:164` uses a stub 429 and is not affected.
- **RB-31's test, amended before it was pushed.** Its first draft called `lease(account, bundle, { trace: true })` with the options in the owner's place. That was corrected in the test commit itself, to `lease(account, bundle, null, { trace: true })`. Its fail-first assertion, on the targets, is the one quoted above.

### Merge and evidence
- **Merge:** main 10909f76 (lead cycles 155 and 156: backlog, the lead's files, requests and status files only) merged at d2eb98cd with no conflict.
- **On the merge:**
  - The setup line (`rustup target add wasm32-unknown-unknown aarch64-linux-android aarch64-apple-ios`, `pip install "gdtoolkit==4.*" "playwright==1.63.0"`, `npm install` in `server/`), then `bash client/build.sh`: exit 0.
  - `cd server && npm test`: 545 tests, 545 pass, 0 fail.
  - `bash tools/run_checks.sh` (check_all, bwrap) on 873809b4: PASS at 17:01:26Z, "All checks passed.", recorded.
  - `python3 tools/coord/owners.py diff FX2-2-trace-telemetry origin/claude/videogame-project-analysis-ewkkk2 873809b4`: "every changed path is inside its files".
  - Main then moved to 11a81ae6 (lead cycle 157: backlog, lead.md, lead-archive.md, requests.md, status/lead.json only), so 873809b4 is not re-merged and its checks stand.
- **Open hypotheses:** none.
- **Next step:** the lead's merge. This session ends here (one task per session).

## Tried and failed
- 2026-11-21 The first RB-32 drain test passed on main, for the wrong reason (`401 session_refused`). Its session was made before the clock moved 12 h, and a session lasts an hour. It now signs in after the clock moves.
- 2026-11-21 Tried to make RB-49 fail on main by forcing query plans: `NOT INDEXED`, `INDEXED BY`, a dropped index and `reverse_unordered_selects`. All returned the right raider. See "The tests".
- 2026-11-21 Ran the Nursery tests before building the wasm: "ruleborn_sim.wasm is not built". Built it with `cargo build --release --target wasm32-unknown-unknown` in `sim/`.
- 2026-11-21 Raised the test Nursery to level 2 with the starting Spire: refused, `needs_spire_level`. The test helper now sets the Spire to level 3.
