# SP-bt-01 the coordinator script: progress

- Status: Green (BT-01b ready at 18570607; pre-check PASS).
- Progress: 1 of 2 tasks merged; 0 items passed by the gate (neither task has gate items).
- Done: BT-01a merged (99c9aa89); BT-01b written (tools/coord/merge_queue.py, `cycle.py --merge`), self-test passes.
- Next: the lead merges BT-01b; no further task.
- Blocked by: none.
- Owner decision needed: none.

| Deliverable | Weight (h) | Status | Evidence |
|---|---:|---|---|
| BT-01a dry-run coordinator cycle | 4 | merged (99c9aa89) | `python3 tools/coord/cycle.py --self-test` |
| BT-01b merge queue | 4 | ready (18570607) | `python3 tools/coord/cycle.py --self-test` (includes `merge_queue.self_test`) |

## Handoff
- Last verified commit: 18570607 (main 99b7b414 merged in; self-test passes; `owners.py diff BT-01b` passes; pre-check PASS 20:31Z; main 099b746f merged in after it, docs/progress only).
- Done: `tools/coord/merge_queue.py`, run as `python3 tools/coord/cycle.py --merge [--dry-run] [--json] [--trailer LINE] [--max-batch N] [--max-candidates N]`. Per round:
  - the lock in status/lead.json: an unexpired one stops the run; an expired one is cleared and noted;
  - the ready tasks, critical first, then by ready time; a missing ready_sha or a path outside the task's files (`owners.unowned` against main's head) sets resync with a message to the agent;
  - a candidate of up to three tasks with disjoint files, `git merge --no-ff` in a temporary worktree; a conflict aborts that task to resync with the paths;
  - the lock `{candidate_sha, task_ids, started_at, expires_at}` (2 × check_minutes + 10 = 60 min) committed and pushed on main before any check, with the round's pending bookkeeping;
  - the checks through run_checks.sh from the coordinator's checkout: full, or the docs check only when the pre-check counts (single task, PASS at ready_sha, candidate differs only under docs/progress), plus the UI guard for a task with gate_items unless `ui guard: OK` is recorded at its ready_sha; a gated task whose own files the merge changed is held for the lead's gate run;
  - on a pass: the lock must still be ours; fast-forward, or merge onto main's newer docs-only head and re-run the docs check; main gaining code clears the lock and retries; one bookkeeping commit sets merged, merged_sha, last_merged and clears the lock; after a reused pre-check the full checks run on main and a failure is reverted at once (owner inbox if the revert cannot be pushed);
  - on a fail: a batch is split and each task re-checked alone; a single task goes to resync, attempts + 1, with the failure lines in resync_reason and in a message;
  - checks that cannot run (no sandbox, lost) clear the lock and write an owner-inbox entry; the tasks stay ready;
  - owner-inbox entries (newest first, once per title): a ready task waiting more than 2 h, the checks unable to run, main red.
- `--dry-run` builds the candidate in a temporary worktree, prints the actions and stops before the first push. Every commit touches only docs/progress/** except the merges that move main.
- Tests: `merge_queue.self_test()`, called from `cycle.py --self-test` (check_all.sh line 158), on local bare repositories with the real run_checks.sh and stub check commands: dry run pushes and writes nothing, a held lock skips, an expired lock is cleared, owners violation, conflict, batch split, merge onto a newer docs head, pre-check reuse with the full checks after, a reverted merge, the checks unable to run, inbox entries, messages, trailers.
- Open hypotheses: the lock commit is itself a docs-only commit on main, so a pass is usually merged onto the new head rather than fast-forwarded (as cycle 186 did for BT-01a). The docs check then runs once more on the bookkeeping commit.
- Next step: the lead may run `cycle.py --merge --dry-run` in a cycle, then `--merge --trailer ...` in place of the hand-run queue. README.md's tools listing and docs/guides/checks.md are not this task's files; the lead may add merge_queue.py there.

## Tried and failed
- Copying an old status after its lease lapsed re-claimed the task. Fixed: an unchanged status is copied only while the task's claim is still the agent's.
- In a dry run, tasks set to resync stayed ready on main and were re-reported each round. Fixed: a dry run skips them in later rounds.
