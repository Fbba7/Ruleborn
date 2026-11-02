# Owner inbox

Alerts and questions for the owner, newest first. The lead also sends each one
as a direct message (work-order decision D-03). An entry is closed by
recording the answer under it.

## 2026-10-31 20:55Z: program paused by the owner

- **What:** the owner asked to stop the program cleanly. The launcher
  (`trig_01DgVGTTmwREAb7sHz8oQkiP`) and the watchdog
  (`trig_015Lgi2ZssXBXPbzkCYqoKmL`) scheduled tasks are disabled, not
  deleted. `expected_next_update_by` in `status/lead.json` is set to null,
  which the watchdog reads as stopped on purpose. Main is at `2c6a82c5`
  (lead cycle 17's handoff); nothing was left unpushed. No task was open
  and startable: the remaining phase 0 gate runs wait for the 2 November
  17:00Z usage reset.
- **To resume:** re-enable both scheduled tasks. The next lead cycle sets
  `expected_next_update_by` again.
- **Still open for the owner:** C74 and C75 need "A/A"; message M1 to AIA
  is past its `ack_by`.
- **Answer (2026-11-02 22:59Z):** the owner resumed the program after the
  2 November 17:00Z usage reset. Both scheduled tasks are re-enabled, the
  launcher was fired once by hand to start a lead cycle now, and
  `expected_next_update_by` is set to 2026-11-03 00:15Z (now + 75 min) so
  the watchdog watches the lead again.

## 2026-10-31 10:05Z: ready work waiting over 2 hours, and a lead container without the build tools (lead, cycle 8)

- **What:** O2-2 (a392bcb, ready 06:37Z) and P0-AIA-keyframes-1
  (b760d6f1, ready 06:26Z) waited over 3 hours behind SV-B11-B12. Cycle 8
  merged them as one batch candidate, `fafc1a13`, with AIA-R3's two
  `check_all.sh` lines.
- **Also:** this cycle's container (`session_01SNkKxnfFjzxesNmoxjhm96`)
  was missing what the README's quick start installs: the Rust targets
  `wasm32-unknown-unknown`, `aarch64-linux-android` and
  `aarch64-apple-ios`, `gdlint` (gdtoolkit 4) and the Python `playwright`
  package. It also had no client build in the checkout. The first two
  check runs failed on those, not on the change. Once they were installed,
  a full run took about 55 minutes, so the merge lock was renewed once,
  to 10:45Z. If the environment's setup script installs them, every lead
  cycle saves that time.
- **Action:** none needed; optionally add the README's quick-start
  installs to the environment's setup script.

## 2026-10-31 07:45Z: ready work waiting over 2 hours (lead, cycle 7)

- **What:** SV-B11-B12 has been ready since 04:45Z. It is in the merge
  queue now: cycle 6 (`session_01SNkKxmymBxL2H7jxeLAz9D`) holds the merge
  lock on its candidate `14c30355` until 08:20Z. Behind it are O2-2
  (a392bcb, ready 06:37Z) and P0-AIA-keyframes-1 (b760d6f1, ready
  06:26Z). P0-K1-kitskin merged at about 07:20Z.
- **Also:** the launcher started cycle 7 at 07:38Z while cycle 6 was
  still waiting on its checks. Cycle 7 did only the bookkeeping, as the
  lock requires.
- **Action:** none for the owner.

## 2026-10-31 03:45Z: ready work waiting over 2 hours (lead, cycle 5)

- **What:** P0-K1-bake-2 has been ready since 01:22Z. It is in the merge
  queue now: cycle 4 (`session_01SNkKxrCAg6Y8R7Hovb2PPH`) holds the merge
  lock on its candidate `48e0d156` until 04:37Z and is re-running
  `guard.sh`. Behind it, three more are ready: P0-K1-contract-2 (36b797fd),
  P0-AD-golden (7d8c4ed6) and P0-AIA-board-3 (e09807f3). The queue is slow
  because full checks run one at a time (`flaky.md`, BT-10).
- **Also:** the launcher started cycle 5 at 03:38Z while cycle 4 was still
  working (its session reads idle between turns). Cycle 5 did only the
  bookkeeping, as the lock requires, so nothing merged twice.
- **Action:** none for the owner; the next cycle without a lock takes the
  queue.

## 2026-10-31 00:10Z: watchdog alert, lead past its update time

- **What was stale:** `status/lead.json` expected an update by 2026-10-31T00:00:00Z (last update 2026-10-30T23:58Z). The launcher is healthy: last run SUCCEEDED at 2026-10-30T23:38Z.
- **What the watchdog did:** started no session. The "Latest lead cycle session:" in `lead.md` (`session_01SNkKxpgxycAoWLmMgaYf2V`, cycle 2) is review_ready. But a cycle 3 lead, which `lead.md` doesn't list, committed at 23:57:59Z and holds the merge lock on candidate `fd2c9662` until 00:58Z. A second lead started now could merge to main at the same time, so the watchdog did not start one.
- **To fix:** the cycle 3 lead should record its session in `lead.md`'s "Latest lead cycle session:" line and keep `expected_next_update_by` ahead of its merge lock. If that lead has stopped, the launcher (next run 00:38Z) or the next watchdog firing (02:08Z) starts a new cycle once the lock expires.
- **Resolved (lead, 00:31Z):** the cycle 3 lead (`session_01SNkKxnFBPxodvMYivAg4oB`) recorded itself in `lead.md` and moved `expected_next_update_by` past its merge lock. It finished at 01:45Z with four tasks merged and the lock cleared.

Nothing is open. Every decision open on 2026-10-29 was closed that day; see
[`owner-decisions.md`](../decisions/owner-decisions.md).
