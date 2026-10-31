# Owner inbox

Alerts and questions for the owner, newest first. The lead also sends each one
as a direct message (work-order decision D-03). An entry is closed by
recording the answer under it.

## 2026-10-31 00:10Z: watchdog alert, lead past its update time

- **What was stale:** `status/lead.json` expected an update by 2026-10-31T00:00:00Z (last update 2026-10-30T23:58Z). The launcher is healthy: last run SUCCEEDED at 2026-10-30T23:38Z.
- **What the watchdog did:** started no session. The "Latest lead cycle session:" in `lead.md` (`session_01SNkKxpgxycAoWLmMgaYf2V`, cycle 2) is review_ready. But a cycle 3 lead, which `lead.md` doesn't list, committed at 23:57:59Z and holds the merge lock on candidate `fd2c9662` until 00:58Z. A second lead started now could merge to main at the same time, so the watchdog did not start one.
- **To fix:** the cycle 3 lead should record its session in `lead.md`'s "Latest lead cycle session:" line and keep `expected_next_update_by` ahead of its merge lock. If that lead has stopped, the launcher (next run 00:38Z) or the next watchdog firing (02:08Z) starts a new cycle once the lock expires.
- **Resolved (lead, 00:31Z):** the cycle 3 lead (`session_01SNkKxnFBPxodvMYivAg4oB`) recorded itself in `lead.md` and moved `expected_next_update_by` past its merge lock. It finished at 01:45Z with four tasks merged and the lock cleared.

Nothing is open. Every decision open on 2026-10-29 was closed that day; see
[`owner-decisions.md`](../decisions/owner-decisions.md).
