# SP-bt-07 the metrics report: progress

- Status: Green (BT-07 ready at efea6a02; pre-check PASS).
- Progress: 0 of 1 tasks merged; 0 items passed by the gate (BT-07 has no gate items).
- Done: `tools/coord/metrics.py`, the digest's metrics section, with `--self-test`.
- Next: the lead merges BT-07 (no other task).
- Blocked by: none.
- Owner decision needed: none.

| Deliverable | Weight (h) | Status | Evidence |
|---|---:|---|---|
| BT-07 metrics digest section | 3 | ready (efea6a02) | `python3 tools/coord/metrics.py --self-test` |

## What it does

`python3 tools/coord/metrics.py` prints a Markdown section for the digest: one
row for each metric in agent-protocol.md's "Metrics" table, with the figure,
the review threshold and whether the figure is past it. A figure the files
cannot give reads "no data" with its reason. `--json` gives the same figures as
JSON; `--days N` sets the window (7 by default); `--now` fixes the time;
`--fetch` updates the remote-tracking refs first. It writes no repository file.

Sources: the history of `backlog.json` and `backlog-archive.json` on
`origin/<main>` (lead time, oldest ready wait, resyncs, blocked hours), the
gate's verdicts (split verdicts), the blind audits' forms joined to the verdicts
(catch and false-fail rates per quality) and the roster's status files on their
branches (stalls, now only). Usage per merged task is "no data": no file
records usage.

## Handoff

- Lead time: 36 of the last week's 52 merges were never shown `ready` on main
  (the lead recorded ready and merged in one commit). Their ready time is the
  `ready_sha`'s committer time, which comes before the agent's pre-check, so
  for those tasks the figure is slightly long.
- Stalls: the status files keep no history, so the figure is the count now,
  not a count per day.
- A shallow checkout gives a short history. The section notes that and names
  `git fetch --unshallow origin`.
- Request SP-bt-07-R1 (in the status file) asks the lead to wire the
  self-test into `tools/check_all.sh`.

## Tried and failed

- Timing ready from the backlog alone: 37 of 53 merges had no ready time.
  The `ready_sha` commit time fixed that for all but one.

## Stopped here

BT-07 is ready at efea6a02 (pre-check PASS, owners diff clean). Waiting for the merge; no task is left for this seat.
