# SP-bt-01 the coordinator script: progress

- Status: Amber (BT-01a working: tools/coord/cycle.py written, self-test passes; pre-check next).
- Progress: 0 of 2 tasks merged; 0 items passed by the gate (BT-01a has no gate items).
- Done: nothing yet.
- Next: BT-01a, the dry-run coordinator cycle in tools/coord/.
- Blocked by: none.
- Owner decision needed: none.

| Deliverable | Weight (h) | Status | Evidence |
|---|---:|---|---|
| BT-01a dry-run coordinator cycle | 4 | working | `python3 tools/coord/cycle.py --self-test` |
| BT-01b merge queue | 4 | open (later task) | - |

## Handoff
- Last verified commit: c0e8741 (main, not yet pre-checked on this branch)
- Done: tools/coord/cycle.py, the dry-run cycle (`--dry-run`, `--json`, `--out`), with a self-test on fixture branches in local bare repositories.
- Half done: wiring the self-test into tools/check_all.sh, which is not in BT-01a's files: request SPbt01-R1 to the lead.
- Open hypotheses: none.
- Next step: merge main, pre-check, mark ready.

## Tried and failed
