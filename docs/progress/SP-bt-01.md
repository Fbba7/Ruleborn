# SP-bt-01 the coordinator script: progress

- Status: Green (BT-01a ready at 37c99eba; pre-check PASS).
- Progress: 0 of 2 tasks merged; 0 items passed by the gate (BT-01a has no gate items).
- Done: BT-01a ready (tools/coord/cycle.py, the dry-run cycle).
- Next: BT-01b, the merge queue, once the lead opens it.
- Blocked by: none.
- Owner decision needed: none.

| Deliverable | Weight (h) | Status | Evidence |
|---|---:|---|---|
| BT-01a dry-run coordinator cycle | 4 | ready (37c99eba) | `python3 tools/coord/cycle.py --self-test` |
| BT-01b merge queue | 4 | open (later task) | - |

## Handoff
- Last verified commit: 37c99eba (pre-check PASS, 17:46Z; `owners.py diff BT-01a` passes).
- Done: `tools/coord/cycle.py --dry-run [--json] [--out FILE]` reads the backlog, lead.json and requests.md from origin's main and each roster agent's status from its branch. It prints what a cycle would do: copy states, claims and ready_sha (only moves the agent may make); expire lapsed leases (prior_branch/prior_sha when the branch holds work besides its progress files); list startable tasks (cycle_needed.needs); set acked_at for acknowledged messages and flag missed ones; copy new requests and answers into requests.md (ranges such as "S1-R1 to S1-R7" are parsed); flag past-due requests, stalls, busy stalls and tasks waiting more than 2 h as blocked or ready. It writes and pushes nothing; without `--dry-run` it exits 2. `--self-test` builds fixture branches in local bare repositories (no network) and checks that the remote heads and the working tree are unchanged after a run.
- Half done: request SPbt01-R1. tools/check_all.sh is not in BT-01a's files, so the lead adds `python3 tools/coord/cycle.py --self-test` after the archive.py self-test line, and adds it to the agent-program row of docs/guides/checks.md.
- Open hypotheses: on the live repository, the dry run lists 25 acknowledged messages whose acked_at is unset, and about 55 old requests still open in requests.md past due. Both are real lead bookkeeping, not noise from the script.
- Next step: BT-01b adds the write mode and the merge queue on top of plan().

## Tried and failed
- Copying an old status after its lease lapsed re-claimed the task. Fixed: an unchanged status is copied only while the task's claim is still the agent's.
