# SP-bt-01 the coordinator script: progress

- Status: Green (3D0-CO-queue-flake ready at e0a0499c; pre-check PASS).
- Progress: 0 of 1 tasks merged in this session; 0 items passed by the gate (the task has no gate items).
- Done: both causes of the merge-queue self-test flake fixed; cycle.py reads acks given as strings or objects.
- Next: the lead's verifier and the merge.
- Blocked by: none.
- Owner decision needed: none.

| Deliverable | Weight (h) | Status | Evidence |
|---|---:|---|---|
| BT-01a dry-run coordinator cycle | 4 | merged (earlier session) | `python3 tools/coord/cycle.py --self-test` |
| 3D0-CO-queue-flake | 2 | ready (e0a0499c) | `python3 tools/coord/cycle.py --self-test`, 20 runs in a row |

## Handoff
- Last verified commit: e0a0499c (pre-check PASS, 02:39Z; `owners.py diff 3D0-CO-queue-flake` passes). Code review: ready to merge, no critical or important issues; its Minor 1 is fixed (below), Minors 2 and 3 are slow-but-correct paths left as they are, Minor 4 (a long docstring line) is fixed.
- Done, merge queue (`tools/coord/merge_queue.py`). The "lock cleared" flake (`last_merged` read as None) came from `tools/run_checks.sh` reporting LOST for a run that was fine, so the queue took its "cannot run the checks" path. Two races, both handled in the queue, not in run_checks.sh:
  - `start` waits only 5 s for the detached runner's pid file. Under load a `result` read before the file exists says LOST, and its cleanup removes the run's worktree. `Checks.run` now waits up to `START_GRACE` (120 s) for `<CHECK_DIR>/check-<full sha>.pid` after its own `start`, before the first `result`.
  - `result` checks for the `.done` file, then whether the runner is alive. A run that ends between the two reads as LOST. The runner moves `.done` into place before it exits, so `Checks.run` reads a LOST result a second time before taking it. A run that is really lost still reads LOST. The second read is skipped when the pid file never turned up in the grace period: that first LOST read removed the worktree, and a runner that starts after it could only end as a misleading FAIL (found by the code review).
  - The "lock cleared" check no longer crashes on a None `last_merged`.
  - New self-test cases with a fake runner: a late pid file, a run that ends between the reads, a run that is really lost, and a pid file that turns up only after the grace period. The first, second and fourth fail on the code before their fix; the third guards that a lost run still reads as lost.
- Done, acks (`tools/coord/cycle.py`). `ack_ids()` reads a status file's `acks` given as strings or as objects with an `id`. Before the fix, M2.json's object acks crashed `plan()` with "unhashable type: 'dict'". The self-test fixture now has S2 acking M4 as an object, with the check "ack given as an object", which failed before the fix.
- Verified: 20 of 20 sequential runs of `python3 tools/coord/cycle.py --self-test` at e0a0499c, and 16 of 16 under load (16 parallel runs beside 8 CPU hogs); before the last fix, 64 of 64 under load. The dry run against the live repository works.
- Requests: SPbt01-R2 (cycle_needed.py would crash on object acks in lead.json) and SPbt01-R3 (the two races in run_checks.sh belong to its owner). Both are in the status file, each with a default.
- Next step: the lead's verifier reviews the diff; then the merge.

## Tried and failed
- Copying an old status after its lease lapsed re-claimed the task. Fixed: an unchanged status is copied only while the task's claim is still the agent's.
- The flake did not reproduce on an idle machine. It showed only under CPU load, which is how both races were found.
- The first fake-runner test let its pid-file timer fire after the temp folder was deleted (FileNotFoundError). Fixed by joining the timer after the run.
