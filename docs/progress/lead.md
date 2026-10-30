# The lead's handoff

Every cycle of the lead is a fresh session. It starts here and from
[`status/lead.json`](status/lead.json), runs one cycle of
[agent-protocol.md](../guides/agent-protocol.md#the-coordinator-and-the-lead-who-does-what),
then rewrites the "Now" section below and `status/lead.json`, and pushes.

## Running a cycle

1. `git fetch origin`; read `docs/progress/backlog.json` and every status file
   on the roster's branches (`agents` in the backlog).
2. Do the cycle's seven steps in order. Before merging, read `merging` in
   `status/lead.json`: a lock that has not expired means another cycle is
   merging, so skip the gate and the merge and push only `docs/progress/**`.
3. Check a candidate's files with
   `python3 tools/coord/owners.py diff <task_id> <main> <candidate>` and the
   claims with `owners.py claims`.
4. Run the candidate's full checks detached:
   `bash tools/run_checks.sh start <sha>`, then
   `bash tools/run_checks.sh wait <sha>` in the background. Main moves only
   on `PASS`.
5. After main moves, republish the two generated pages with `url` set: the
   audit (`docs/audit/index.html`) at
   https://claude.ai/artifact/8m5MgpjWfFurnfwc6b76sN, and the roadmap
   (`docs/roadmap/index.html`) at
   https://claude.ai/artifact/Yb1WxZ2eJCCbByitnd7fJf.

Main is the branch `claude/videogame-project-analysis-ewkkk2`. Push with
retries after 2, 4, 8 and 16 seconds.

## The program's scheduled tasks and sessions

Recorded here once they are created at launch on 30 October 2026.

## Now

- Cycle 0: the backlog is seeded with phase 0 (AD, AIA, K1) and the server
  decisions (SV); BT-02 and BT-03 are merged.
- Next: launch the four agents, about 15 minutes apart; from cycle 1, take
  the merge queue.
