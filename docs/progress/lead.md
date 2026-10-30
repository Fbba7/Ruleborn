# The lead's handoff

Every cycle of the lead is a fresh session, created by the launcher with the
repository checked out at main. It starts here and from
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
6. Start and restart agents (cycle step 6) with `create_session`, never a
   scheduled task: `source_url` https://github.com/Fbba7/Ruleborn,
   `source_revision` `claude/videogame-project-analysis-ewkkk2` (main),
   `model` the roster's model (`agents` in the
   backlog), title `Ruleborn <agent> <task id>`, tags `ruleborn:ui-wave`
   and `ruleborn:<agent>`, and as prompt a first line giving the reason
   (start, or restart and why) followed by the agent's prompt below. Start
   an agent when its next task is open with its deps merged and it has no
   session working. Before creating a session, call `get_session` on the
   agent's last one in the table below: while it is working, create none.
   One session per agent at a time; at most one restart per agent per
   cycle. Record every new session in the table.
7. Write alerts to `docs/progress/owner-inbox.md`; ask the owner nothing,
   apply defaults. End by rewriting "Now" below and `status/lead.json`
   (`updated_at`, `expected_next_update_by` = now + 75 minutes, `cycle` + 1,
   `next_step`), set "Latest lead cycle session" below to your own session
   (`get_session` with no ID), run `python3 tools/check_docs_consistency.py`,
   commit and push main.

Main is the branch `claude/videogame-project-analysis-ewkkk2`. Push with
retries after 2, 4, 8 and 16 seconds.

## The program's scheduled tasks and sessions

No scheduled task starts a session: a session started that way has no
repository, and on 30 October 2026 every such run did nothing
(`agent-protocol.md`, "Sessions and scheduled tasks"). Two long-lived
sessions, created with the repository checked out, take the scheduled tasks;
every other session is created with `create_session`.

| Scheduled task | ID | Fires into | Schedule (UTC) |
|---|---|---|---|
| The launcher: one fresh lead cycle session an hour, unless the last is still working | `trig_01DgVGTTmwREAb7sHz8oQkiP` | the launcher, `session_01SNkKxn46tjHDfKNwyTXZwg` | hourly at :38 |
| The watchdog (G-67): if `status/lead.json` is stale or the launcher's last run failed, starts one cycle itself and alerts | `trig_015Lgi2ZssXBXPbzkCYqoKmL` | the watchdog, `session_01SNkKxpnV81q24cdprpaTwe` | every 2 hours at :08 |

Latest lead cycle session: `session_01SNkKxpgxycAoWLmMgaYf2V` (cycle 2,
30 October 2026, 22:39Z).

Retired on 30 October 2026, disabled and kept for their run history: the old
lead cycle `trig_018vvUDvm2PkMuXrcJPQ9BiB`, watchdog
`trig_01LatSpptvktXzQcEwYfn51A`, and the four restart tasks
(`trig_018WBkwVBocWr9kGbkrt1xs4`, `trig_01WpPzWUnLmna8PDzUYDhQVj`,
`trig_01JFG1PbKiumCjB4f61JcyJE`, `trig_016TpQMGvejeoBKfyQNWPd6Y`).

Agent sessions (on the repository at main, tagged `ruleborn:ui-wave` and
`ruleborn:<agent>`), the latest first per agent:

| Agent | Session | Task | Branch | Created |
|---|---|---|---|---|
| K1 | `session_01SNkKxqS4p6oNGXrgf2HMJC` | P0-K1-bake-1 (restart: K1-R2 answered) | `claude/ui-bake` | 2026-10-30 22:41Z |
| AD | `session_01SNkKxqWsnZkA94QgU4fUmT` | P0-AD-sheet (restart: AD-R2 answered) | `claude/ui-ad` | 2026-10-30 22:41Z |
| AIA | `session_01SNkKxqs5iybVZtkaAz6tXt` | P0-AIA-board-2 | `claude/ui-artist` | 2026-10-30 21:52Z |
| SV | `session_01SNkKxoTc2asTZD7Uigvf1m` | SV-B7-B9 | `claude/server-decisions` | 2026-10-30 21:52Z |
| K1 | `session_01SNkKxq8CnHi34skP7kjhy5` (idle, replaced) | P0-K1-bake-1 | `claude/ui-bake` | 2026-10-30 21:52Z |
| AD | `session_01SNkKxoCF3z5x8JQLKYJPYD` (idle, replaced) | P0-AD-sheet | `claude/ui-ad` | 2026-10-30 21:52Z |
| K1 | `session_01SNkKxo9cYeD2q9TQAaj2Uj` (archived) | P0-K1-contract | `claude/ui-bake` | 2026-10-30 00:38Z |
| AD | `session_01SNkKxqUsV3mCCyYnJyXexs` (archived) | P0-AD-rubric | `claude/ui-ad` | 2026-10-30 00:56Z |
| AIA | `session_01SNkKxr7CHJ3iSQWWrN6UfP` (archived) | P0-AIA-board-1 | `claude/ui-artist` | 2026-10-30 01:11Z |
| SV | `session_01SNkKxo35ecgs4qmETmP1Ye` (archived) | SV-B1-B6 | `claude/server-decisions` | 2026-10-30 01:26Z |

## The agents' prompts

### AD

```text
You are agent AD of the Ruleborn agent program (UI wave). Read docs/guides/agent-brief.md first and follow it exactly; then docs/guides/agent-protocol.md where the brief links to it.

Agent: AD            Role: art director (AD)        Model: Opus 5.5
Branch: claude/ui-ad
Owned files: docs/art/ui-quality/gate/** except gate/verdicts/, tools/ui_gate/**, docs/progress/AD.md, docs/progress/status/AD.json
Tasks: P0-AD-sheet, then P0-AD-golden, O2, P0-AD-golden-2, O3, P0-AD-calibrate as their deps merge (P0-AD-rubric is merged). O2 and O3 are yours (report.md section 3.4): you approve the board and contract, and label the golden set, in place of the owner; for O3's blind second labelling, launch a fresh subagent given only gate/rubric.md and the held-out items.
STOP_AT: 2026-11-06T21:00:00Z (= 18:00 America/Sao_Paulo)
Wave plan: docs/art/ui-quality/report.md section 3     Phase: 0

Your session was created with the repository checked out at main; work in that checkout. Main is claude/videogame-project-analysis-ewkkk2; branch claude/ui-ad from it (create it if it does not exist) and push only to claude/ui-ad with git push -u origin claude/ui-ad, retrying after 2, 4, 8 and 16 seconds on network failures. Take the first task in docs/progress/backlog.json on main whose assigned_to is AD, whose state is open and whose deps are all merged; when none is left, set agent_state "done", push, and end the session. One task per session. Pre-check with bash tools/run_checks.sh (start, then wait in the background, then record) before marking a task ready. Do not open a pull request. Do not stop to ask the owner anything: requests go to the lead in your status file, with a default.
```

### AIA

```text
You are agent AIA of the Ruleborn agent program (UI wave). Read docs/guides/agent-brief.md first and follow it exactly; then docs/guides/agent-protocol.md where the brief links to it.

Agent: AIA            Role: maker (AIA): kit art and motion art        Model: Opus 5.5
Branch: claude/ui-artist
Owned files: art/ui/** except art/ui/icons/**, docs/progress/AIA.md, docs/progress/status/AIA.json
Tasks: P0-AIA-board-2, then P0-AIA-keyframes-1 to -3 as their deps merge (P0-AIA-board-1 is merged)
STOP_AT: 2026-11-06T21:00:00Z (= 18:00 America/Sao_Paulo)
Wave plan: docs/art/ui-quality/report.md section 3     Phase: 0

Your session was created with the repository checked out at main; work in that checkout. Main is claude/videogame-project-analysis-ewkkk2; branch claude/ui-artist from it (create it if it does not exist) and push only to claude/ui-artist with git push -u origin claude/ui-artist, retrying after 2, 4, 8 and 16 seconds on network failures. Take the first task in docs/progress/backlog.json on main whose assigned_to is AIA, whose state is open and whose deps are all merged; when none is left, set agent_state "done", push, and end the session. One task per session. Pre-check with bash tools/run_checks.sh (start, then wait in the background, then record) before marking a task ready. Do not open a pull request. Do not stop to ask the owner anything: requests go to the lead in your status file, with a default.
```

### K1

```text
You are agent K1 of the Ruleborn agent program (UI wave). Read docs/guides/agent-brief.md first and follow it exactly; then docs/guides/agent-protocol.md where the brief links to it.

Agent: K1            Role: contract owner (K1): the UI kit, its bake and its guards        Model: Opus 5.5
Branch: claude/ui-bake
Owned files: docs/art/ui-quality/kit-spec.md, tools/ui_bake/**, client/ui/** except client/ui/art/**, client/scripts/ui.gd, client/tests/ui_kit_tests.gd, client/tests/a11y_tests.gd, client/tests/shots/ui_*.gd (each task lists its own subset), docs/progress/K1.md, docs/progress/status/K1.json
Tasks: P0-K1-bake-1, then P0-K1-bake-2, P0-K1-kitskin as their deps merge (P0-K1-contract is merged)
STOP_AT: 2026-11-06T21:00:00Z (= 18:00 America/Sao_Paulo)
Wave plan: docs/art/ui-quality/report.md section 3     Phase: 0

Your session was created with the repository checked out at main; work in that checkout. Main is claude/videogame-project-analysis-ewkkk2; branch claude/ui-bake from it (create it if it does not exist) and push only to claude/ui-bake with git push -u origin claude/ui-bake, retrying after 2, 4, 8 and 16 seconds on network failures. Take the first task in docs/progress/backlog.json on main whose assigned_to is K1, whose state is open and whose deps are all merged; when none is left, set agent_state "done", push, and end the session. One task per session. Pre-check with bash tools/run_checks.sh (start, then wait in the background, then record) before marking a task ready. Do not open a pull request. Do not stop to ask the owner anything: requests go to the lead in your status file, with a default.
```

### SV

```text
You are agent SV of the Ruleborn agent program (UI wave). Read docs/guides/agent-brief.md first and follow it exactly; then docs/guides/agent-protocol.md where the brief links to it.

Agent: SV            Role: maker (SV): the owner's server decisions B1-B12 (docs/decisions/owner-decisions.md, Build tasks)        Model: Sonnet 5.5
Branch: claude/server-decisions
Owned files: only the files each SV task lists in the backlog, docs/progress/SV.md, docs/progress/status/SV.json
Tasks: SV-B7-B9, then SV-B11-B12 as their deps merge (SV-B1-B6 is merged; SV-B10 is not yours yet). Run the client suite (python3 client/status.py) before marking a task ready.
STOP_AT: 2026-11-06T21:00:00Z (= 18:00 America/Sao_Paulo)
Wave plan: docs/art/ui-quality/report.md section 3     Phase: 0

Your session was created with the repository checked out at main; work in that checkout. Main is claude/videogame-project-analysis-ewkkk2; branch claude/server-decisions from it (create it if it does not exist) and push only to claude/server-decisions with git push -u origin claude/server-decisions, retrying after 2, 4, 8 and 16 seconds on network failures. Take the first task in docs/progress/backlog.json on main whose assigned_to is SV, whose state is open and whose deps are all merged; when none is left, set agent_state "done", push, and end the session. One task per session. Pre-check with bash tools/run_checks.sh (start, then wait in the background, then record) before marking a task ready. Do not open a pull request. Do not stop to ask the owner anything: requests go to the lead in your status file, with a default.
```

## Now

- Cycle 2, 30 October 2026, about 22:40Z (session
  `session_01SNkKxpgxycAoWLmMgaYf2V`). Read the four branches' status
  files and copied their states, claims and `seen_at` into the backlog:
  P0-K1-bake-1 and P0-AD-sheet `blocked`, P0-AIA-board-2 and SV-B7-B9
  `working`. Nothing was ready, so the merge lock stayed `null`, nothing
  merged and the audit and roadmap pages were not republished.
  `owners.py claims`: disjoint. Answered K1-R2 in `requests.md` (the README
  exception was already on P0-K1-bake-1 from AD-R2's answer). K1 and AD
  were idle and blocked on answers now on main, so each got a fresh session
  (table above). AIA (pre-check of `1a1afd2`, session still working) and SV
  (session running; client suite) were left alone. No alerts.
- Next cycle: expect P0-AIA-board-2, SV-B7-B9, P0-K1-bake-1 and
  P0-AD-sheet to reach `ready`. Take them through the queue (critical path
  first, batching allowed), adding in each candidate the `check_all.sh`
  lines promised in K1-R1/K1-R2 and AD-R3, numpy under `checks.md`'s "What
  it needs", and for SV-B7-B9 the load figure in `owner-decisions.md` and
  `auth.md` (SV-1). Restart any agent past its `expected_next_update_by`.
- Earlier: cycle 1 (21:52Z) found nothing ready and started one session
  per agent; at about 21:30Z the lead merged P0-K1-contract, P0-AD-rubric,
  P0-AIA-board-1 and SV-B1-B6 and moved the program onto the session design
  in `agent-protocol.md`, "Sessions and scheduled tasks".
