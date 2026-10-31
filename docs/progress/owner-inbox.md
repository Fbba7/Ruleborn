# Owner inbox

Alerts and questions for the owner, newest first. The lead also sends each one
as a direct message (work-order decision D-03). An entry is closed by
recording the answer under it.

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
