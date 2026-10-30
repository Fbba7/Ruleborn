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

Scheduled tasks on the owner's account (each run is a fresh session that
clones the repository if it is missing; push notifications on). All six were
disabled on 2026-10-30 at about 09:15Z, when the wave was stopped; see Now.

| Task | ID | Schedule (UTC) |
|---|---|---|
| The lead's cycle | `trig_018vvUDvm2PkMuXrcJPQ9BiB` | hourly at :38 (the platform's minimum interval is an hour) |
| The watchdog (G-67): alerts the owner if `status/lead.json` is stale or the cycle is disabled | `trig_01LatSpptvktXzQcEwYfn51A` | every 2 hours at :38 |
| Restart AD | `trig_018WBkwVBocWr9kGbkrt1xs4` | only when fired |
| Restart AIA | `trig_01WpPzWUnLmna8PDzUYDhQVj` | only when fired |
| Restart K1 | `trig_01JFG1PbKiumCjB4f61JcyJE` | only when fired |
| Restart SV | `trig_016TpQMGvejeoBKfyQNWPd6Y` | only when fired |

Agent sessions (cloud sessions on the repository at main, tagged
`ruleborn:ui-wave` and `ruleborn:<agent>`; all four archived at the stop,
their work pushed on their branches):

| Agent | Session | Branch | Launched |
|---|---|---|---|
| K1 | `session_01SNkKxo9cYeD2q9TQAaj2Uj` | `claude/ui-bake` | 2026-10-30 00:38Z |
| AD | `session_01SNkKxqUsV3mCCyYnJyXexs` | `claude/ui-ad` | 2026-10-30 00:56Z |
| AIA | `session_01SNkKxr7CHJ3iSQWWrN6UfP` | `claude/ui-artist` | 2026-10-30 01:11Z |
| SV | `session_01SNkKxo35ecgs4qmETmP1Ye` | `claude/server-decisions` | 2026-10-30 01:26Z |

A restart (cycle step 6) fires the agent's restart task with `fire_trigger`,
passing the reason as text; a cycle's session cannot create sessions itself.
The fired session attaches the repository with `add_repo` (push access),
reads its handoff and status file on its branch, and resumes with the prompt
below. Every scheduled session attaches the repository the same way, because
scheduled tasks carry no repository of their own.

## The agents' prompts

### AD

```text
You are agent AD of the Ruleborn agent program (UI wave). Read docs/guides/agent-brief.md first and follow it exactly; then docs/guides/agent-protocol.md where the brief links to it.

Agent: AD            Role: art director (AD)        Model: Opus 5.5
Branch: claude/ui-ad
Owned files: docs/art/ui-quality/gate/** except gate/verdicts/, tools/ui_gate/**, docs/progress/AD.md, docs/progress/status/AD.json
Tasks: P0-AD-rubric, then P0-AD-sheet, P0-AD-golden, P0-AD-golden-2, P0-AD-calibrate as their deps merge
STOP_AT: 2026-11-06T21:00:00Z (= 18:00 America/Sao_Paulo)
Wave plan: docs/art/ui-quality/report.md section 3     Phase: 0

Main is claude/videogame-project-analysis-ewkkk2; branch claude/ui-ad from it (create it if it does not exist) and push only to claude/ui-ad with git push -u origin claude/ui-ad, retrying after 2, 4, 8 and 16 seconds on network failures. Take the first task in docs/progress/backlog.json on main whose assigned_to is AD, whose state is open and whose deps are all merged; when none is left, set agent_state "done", push, and end the session. One task per session. Pre-check with bash tools/run_checks.sh (start, then wait in the background, then record) before marking a task ready. Do not open a pull request. Do not stop to ask the owner anything: requests go to the lead in your status file, with a default.
```

### AIA

```text
You are agent AIA of the Ruleborn agent program (UI wave). Read docs/guides/agent-brief.md first and follow it exactly; then docs/guides/agent-protocol.md where the brief links to it.

Agent: AIA            Role: maker (AIA): kit art and motion art        Model: Opus 5.5
Branch: claude/ui-artist
Owned files: art/ui/** except art/ui/icons/**, docs/progress/AIA.md, docs/progress/status/AIA.json
Tasks: P0-AIA-board-1, then P0-AIA-board-2, P0-AIA-keyframes-1 to -3 as their deps merge
STOP_AT: 2026-11-06T21:00:00Z (= 18:00 America/Sao_Paulo)
Wave plan: docs/art/ui-quality/report.md section 3     Phase: 0

Main is claude/videogame-project-analysis-ewkkk2; branch claude/ui-artist from it (create it if it does not exist) and push only to claude/ui-artist with git push -u origin claude/ui-artist, retrying after 2, 4, 8 and 16 seconds on network failures. Take the first task in docs/progress/backlog.json on main whose assigned_to is AIA, whose state is open and whose deps are all merged; when none is left, set agent_state "done", push, and end the session. One task per session. Pre-check with bash tools/run_checks.sh (start, then wait in the background, then record) before marking a task ready. Do not open a pull request. Do not stop to ask the owner anything: requests go to the lead in your status file, with a default.
```

### K1

```text
You are agent K1 of the Ruleborn agent program (UI wave). Read docs/guides/agent-brief.md first and follow it exactly; then docs/guides/agent-protocol.md where the brief links to it.

Agent: K1            Role: contract owner (K1): the UI kit, its bake and its guards        Model: Opus 5.5
Branch: claude/ui-bake
Owned files: docs/art/ui-quality/kit-spec.md, tools/ui_bake/**, client/ui/** except client/ui/art/**, client/scripts/ui.gd, client/tests/ui_kit_tests.gd, client/tests/a11y_tests.gd, client/tests/shots/ui_*.gd (each task lists its own subset), docs/progress/K1.md, docs/progress/status/K1.json
Tasks: P0-K1-contract, then P0-K1-bake-1, P0-K1-bake-2, P0-K1-kitskin as their deps merge
STOP_AT: 2026-11-06T21:00:00Z (= 18:00 America/Sao_Paulo)
Wave plan: docs/art/ui-quality/report.md section 3     Phase: 0

Main is claude/videogame-project-analysis-ewkkk2; branch claude/ui-bake from it (create it if it does not exist) and push only to claude/ui-bake with git push -u origin claude/ui-bake, retrying after 2, 4, 8 and 16 seconds on network failures. Take the first task in docs/progress/backlog.json on main whose assigned_to is K1, whose state is open and whose deps are all merged; when none is left, set agent_state "done", push, and end the session. One task per session. Pre-check with bash tools/run_checks.sh (start, then wait in the background, then record) before marking a task ready. Do not open a pull request. Do not stop to ask the owner anything: requests go to the lead in your status file, with a default.
```

### SV

```text
You are agent SV of the Ruleborn agent program (UI wave). Read docs/guides/agent-brief.md first and follow it exactly; then docs/guides/agent-protocol.md where the brief links to it.

Agent: SV            Role: maker (SV): the owner's server decisions B1-B12 (docs/decisions/owner-decisions.md, Build tasks)        Model: Sonnet 5.5
Branch: claude/server-decisions
Owned files: only the files each SV task lists in the backlog, docs/progress/SV.md, docs/progress/status/SV.json
Tasks: SV-B1-B6, then SV-B7-B9, SV-B11-B12 as their deps merge (SV-B10 is not yours yet)
STOP_AT: 2026-11-06T21:00:00Z (= 18:00 America/Sao_Paulo)
Wave plan: docs/art/ui-quality/report.md section 3     Phase: 0

Main is claude/videogame-project-analysis-ewkkk2; branch claude/server-decisions from it (create it if it does not exist) and push only to claude/server-decisions with git push -u origin claude/server-decisions, retrying after 2, 4, 8 and 16 seconds on network failures. Take the first task in docs/progress/backlog.json on main whose assigned_to is SV, whose state is open and whose deps are all merged; when none is left, set agent_state "done", push, and end the session. One task per session. Pre-check with bash tools/run_checks.sh (start, then wait in the background, then record) before marking a task ready. Do not open a pull request. Do not stop to ask the owner anything: requests go to the lead in your status file, with a default.
```

## Now

- Stopped on 2026-10-30 at about 09:15Z, at the owner's request. All six
  scheduled tasks are disabled and the four agent sessions are archived.
  Nothing was merged after BT-03.
- Ready on their branches, not merged (each needs check_all on main before
  merging):

  | Agent | Branch | Task | Ready at |
  |---|---|---|---|
  | K1 | `claude/ui-bake` | P0-K1-contract | `407790d` |
  | AD | `claude/ui-ad` | P0-AD-rubric | `334224c` |
  | AIA | `claude/ui-artist` | P0-AIA-board-1 | `aa11f0e` |
  | SV | `claude/server-decisions` | SV-B1-B6 | `2f3c0dd` |

- Open requests to the lead: K1-R1 and AIA-R1 (add their checks to
  check_all), AD-R1 (the gate prompts govern over
  `.claude/agents/ui-judge.md`), AIA-R2 (K1 to add dusk and night sky
  tokens).
- What went wrong, to fix before a restart:
  1. The lead's cycle ran hourly from 01:38Z to 08:38Z, but each run ended
     in about 30 seconds with no commit; its sessions show no repository
     attached. Main never moved, so the four ready tasks were never merged
     and no agent was restarted.
  2. The watchdog failed the same way and never alerted, although
     `status/lead.json` was stale from 01:45Z. It shares the cycle's setup,
     so it is not an independent check.
  3. Each agent session ran one task and stopped, and only the lead could
     restart it, so every agent sat idle from about 02:20Z.
  4. The scheduled runs and SV's session ran on the default model, not the
     one the plan set.
  5. K1 reported its contract as waiting for the owner's approval at O2,
     against the rule that nothing is left to the owner.
  6. SV did not run the client suite locally before marking its task ready.
- Before a restart: run one cycle by hand and confirm it commits; give the
  watchdog a check that does not depend on cloning; let agents take their
  next task without the lead; set the model on every session and task.
