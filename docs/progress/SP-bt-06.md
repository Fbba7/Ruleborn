Status: working on BT-06, the documentation consistency check
Progress: schemas and check written; self-test catches 12 of 12 planted mismatches
Done: docs/progress/schema/{backlog,status,lead}.json, tools/docs/protocol_check.py with --self-test
Next: merge main, pre-check, mark ready
Blocked by: nothing (the plain check fails until the lead does requests R1-R5)
Owner decision needed: none

| Deliverable | File | State |
|---|---|---|
| Backlog schema | `docs/progress/schema/backlog.json` | written |
| Status file schema | `docs/progress/schema/status.json` | written |
| lead.json schema | `docs/progress/schema/lead.json` | written |
| The check, with `--self-test` | `tools/docs/protocol_check.py` | written; self-test passes |
| Disagreements found today | requests SP-bt-06-R1 to R5 in `status/SP-bt-06.json` | sent to the lead |
| Wiring into check_all.sh | request SP-bt-06-R6 | sent to the lead |

## Handoff

`python3 tools/docs/protocol_check.py` checks that the brief, the protocol,
section 3 of the UI report, the three schemas and the live files
(backlog.json, backlog.example.json, status/*.json, requests.md) agree on the
task, agent and request states, the fields and the examples. It prints
`file:line: message` for each mismatch and exits 1 if there are any.
`--root DIR` checks a copy. `--self-test` copies those files to a
temporary folder, checks that the copy gives the same result as the
repository, then plants twelve mismatches one at a time. Each must be
reported at the planted file, within three lines of where it was planted.
It uses the standard library only and no network.

It found 145 mismatches today. 18 are in the documents and the backlog
(R1 to R4) and 127 are drift in the live status files (R5). By the task's
rule, none of these files was edited. The lead fixes them, then wires the
check in (R6). Each request has a default.

Choices the lead may want to revisit:

- The request states `open`, `answered`, `defaulted` and `done` are my
  proposal, since the protocol has none.
- `gate_request.items` holds gate items `{item, qualities}`, as live files
  and the brief ("the items are your task's `gate_items`") have them.
- `lead.json`'s `alerts` takes strings, as the live file does.
- `OTHER_IDENTIFIERS` in the check lists the backticked words that are
  neither states nor fields (tool names and a verdict's fields). A new one
  in the brief or report section 3 must be added there or to a schema.

## Tried and failed

- My first parser for `{"a", "b"}` key lists missed the `{"a": "<v>"}`
  form, so `long_run`'s `expected_end` was reported as missing. It now
  strips the values first.
- The progress_marker row was first read for every backticked word in
  the row, which pulled in `agent_state` and `active`. It now reads only
  the first sentence.
