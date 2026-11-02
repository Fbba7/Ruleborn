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

Latest lead cycle session: `session_01SNkKxokCvaGUnmATx2vzaZ` (cycle 18,
2 November 2026, from 23:38Z).

Retired on 30 October 2026, disabled and kept for their run history: the old
lead cycle `trig_018vvUDvm2PkMuXrcJPQ9BiB`, watchdog
`trig_01LatSpptvktXzQcEwYfn51A`, and the four restart tasks
(`trig_018WBkwVBocWr9kGbkrt1xs4`, `trig_01WpPzWUnLmna8PDzUYDhQVj`,
`trig_01JFG1PbKiumCjB4f61JcyJE`, `trig_016TpQMGvejeoBKfyQNWPd6Y`).

Agent sessions (on the repository at main, tagged `ruleborn:ui-wave` and
`ruleborn:<agent>`), the latest first per agent:

| Agent | Session | Task | Branch | Created |
|---|---|---|---|---|
| gate run dev-fable (Fable 5.1) | `session_01SNkKxonjTzEysQx5wxdp97` (working) | AD-R6 for P0-AD-calibrate | `claude/ui-gate-runs` | 2026-11-02 23:40Z |
| gate run dev-opus (Opus 5.5) | `session_01SNkKxogMyzESz7z3XzwBUJ` (working) | AD-R6 for P0-AD-calibrate | `claude/ui-gate-runs` | 2026-11-02 23:40Z |
| AD | `session_01SNkKxpHbYoyKJJjMRSPCPZ` (idle, done) | P0-AD-calibrate | `claude/ui-ad` | 2026-10-31 18:33Z |
| K1 | `session_01SNkKxnxY3qKwypH2HQMfd8` (idle, done) | P0-K1-tokens-2 (restart: K1-R8 answered) | `claude/ui-bake` | 2026-10-31 18:40Z |
| K1 | `session_01SNkKxnJNP5X4uedWQBNKZt` (idle, replaced) | P0-K1-tokens-2 (restart: K1-R7 answered) | `claude/ui-bake` | 2026-10-31 17:42Z |
| K1 | `session_01SNkKxopXscd2QpqKuzHGnG` (idle, replaced) | P0-K1-tokens-2 | `claude/ui-bake` | 2026-10-31 16:59Z |
| AD | `session_01SNkKxokei5gETTF4KU2gsD` (idle, done) | O3 | `claude/ui-ad` | 2026-10-31 16:21Z |
| AD | `session_01SNkKxmwhuyTLjRXnCt5A2r` (idle, done) | P0-AD-golden-2 | `claude/ui-ad` | 2026-10-31 14:25Z |
| AIA | `session_01SNkKxpFZ1uLvbaTsn7n9HE` (idle, done) | P0-AIA-board-4 | `claude/ui-artist` | 2026-10-31 13:41Z |
| AIA | `session_01SNkKxoXUhGbw3TiCMG8jXR` (idle, done) | P0-AIA-keyframes-3 | `claude/ui-artist` | 2026-10-31 12:29Z |
| K1 | `session_01SNkKxrCv585ZiQCx71ojeP` (idle, done) | P0-K1-tokens | `claude/ui-bake` | 2026-10-31 10:10Z |
| AIA | `session_01SNkKxmdAT9ocJLJRoW6uGa` (idle, done) | P0-AIA-keyframes-2 | `claude/ui-artist` | 2026-10-31 10:10Z |
| AD | `session_01SNkKxnCEmtyRg2DDynmLDX` (idle, done) | O2-2 | `claude/ui-ad` | 2026-10-31 05:55Z |
| K1 | `session_01SNkKxoiPGxkUFw8gAbm5vo` (idle, done) | P0-K1-kitskin | `claude/ui-bake` | 2026-10-31 03:41Z |
| AIA | `session_01SNkKxpN6fMr3qL58LFyGpB` (idle, done) | P0-AIA-keyframes-1 | `claude/ui-artist` | 2026-10-31 03:41Z |
| K1 | `session_01SNkKxqyVvQxD3Cjbxg3UDD` (idle, done) | P0-K1-contract-2 | `claude/ui-bake` | 2026-10-31 01:41Z |
| AIA | `session_01SNkKxr9KX9r2CU9dJRRN4u` (idle, done) | P0-AIA-board-3 | `claude/ui-artist` | 2026-10-31 01:41Z |
| AD | `session_01SNkKxoRUnSxVTboNzf92kH` (idle, done) | P0-AD-golden | `claude/ui-ad` | 2026-10-31 01:41Z |
| K1 | `session_01SNkKxoCgMUfc9LdKPccMVL` (idle, done) | P0-K1-bake-2 | `claude/ui-bake` | 2026-10-31 00:29Z |
| AD | `session_01SNkKxqyTwjQ4QFYuR3isqC` (idle, done) | O2 | `claude/ui-ad` | 2026-10-31 00:29Z |
| K1 | `session_01SNkKxqS4p6oNGXrgf2HMJC` (idle, done) | P0-K1-bake-1 (restart: K1-R2 answered) | `claude/ui-bake` | 2026-10-30 22:41Z |
| AD | `session_01SNkKxqWsnZkA94QgU4fUmT` (idle, done) | P0-AD-sheet (restart: AD-R2 answered) | `claude/ui-ad` | 2026-10-30 22:41Z |
| AIA | `session_01SNkKxqs5iybVZtkaAz6tXt` (idle, done) | P0-AIA-board-2 | `claude/ui-artist` | 2026-10-30 21:52Z |
| SV | `session_01SNkKxq1HJVZM14B553NQx6` (idle, done) | SV-B11-B12 (restart: the last session found SV-B7-B9 unmerged) | `claude/server-decisions` | 2026-10-31 03:41Z |
| SV | `session_01SNkKxpyzv8gcd4M9afzaPz` (idle, did not start) | SV-B11-B12 | `claude/server-decisions` | 2026-10-31 01:40Z |
| SV | `session_01SNkKxoTc2asTZD7Uigvf1m` (idle, done) | SV-B7-B9 | `claude/server-decisions` | 2026-10-30 21:52Z |
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
Tasks: P0-AD-golden, then O2-2, P0-AD-golden-2, O3, P0-AD-calibrate as their deps merge (P0-AD-rubric and P0-AD-sheet are merged; O2 is ready). O2, O2-2 and O3 are yours (report.md section 3.4): you approve the board and contract, and label the golden set, in place of the owner; for O3's blind second labelling, launch a fresh subagent given only gate/rubric.md and the held-out items.
STOP_AT: 2026-11-06T21:00:00Z (= 18:00 America/Sao_Paulo)
Wave plan: docs/art/ui-quality/report.md section 3     Phase: 0

Your session was created with the repository checked out at main; work in that checkout. Before your first pre-check, install the tools a fresh container lacks: rustup target add wasm32-unknown-unknown aarch64-linux-android aarch64-apple-ios; pip install "gdtoolkit==4.*" "playwright==1.63.0"; then bash client/build.sh. Main is claude/videogame-project-analysis-ewkkk2; branch claude/ui-ad from it (create it if it does not exist) and push only to claude/ui-ad with git push -u origin claude/ui-ad, retrying after 2, 4, 8 and 16 seconds on network failures. Take the first task in docs/progress/backlog.json on main whose assigned_to is AD, whose state is open and whose deps are all merged; when none is left, set agent_state "done", push, and end the session. One task per session. Pre-check with bash tools/run_checks.sh (start, then wait in the background, then record) before marking a task ready. Do not open a pull request. Do not stop to ask the owner anything: requests go to the lead in your status file, with a default.
```

### AIA

```text
You are agent AIA of the Ruleborn agent program (UI wave). Read docs/guides/agent-brief.md first and follow it exactly; then docs/guides/agent-protocol.md where the brief links to it.

Agent: AIA            Role: maker (AIA): kit art and motion art        Model: Opus 5.5
Branch: claude/ui-artist
Owned files: art/ui/** except art/ui/icons/**, docs/progress/AIA.md, docs/progress/status/AIA.json
Tasks: P0-AIA-board-3, then P0-AIA-keyframes-1 to -3 as their deps merge (P0-AIA-board-1 and -2 are merged)
STOP_AT: 2026-11-06T21:00:00Z (= 18:00 America/Sao_Paulo)
Wave plan: docs/art/ui-quality/report.md section 3     Phase: 0

Your session was created with the repository checked out at main; work in that checkout. Before your first pre-check, install the tools a fresh container lacks: rustup target add wasm32-unknown-unknown aarch64-linux-android aarch64-apple-ios; pip install "gdtoolkit==4.*" "playwright==1.63.0"; then bash client/build.sh. Main is claude/videogame-project-analysis-ewkkk2; branch claude/ui-artist from it (create it if it does not exist) and push only to claude/ui-artist with git push -u origin claude/ui-artist, retrying after 2, 4, 8 and 16 seconds on network failures. Take the first task in docs/progress/backlog.json on main whose assigned_to is AIA, whose state is open and whose deps are all merged; when none is left, set agent_state "done", push, and end the session. One task per session. Pre-check with bash tools/run_checks.sh (start, then wait in the background, then record) before marking a task ready. Do not open a pull request. Do not stop to ask the owner anything: requests go to the lead in your status file, with a default.
```

### K1

```text
You are agent K1 of the Ruleborn agent program (UI wave). Read docs/guides/agent-brief.md first and follow it exactly; then docs/guides/agent-protocol.md where the brief links to it.

Agent: K1            Role: contract owner (K1): the UI kit, its bake and its guards        Model: Opus 5.5
Branch: claude/ui-bake
Owned files: docs/art/ui-quality/kit-spec.md, tools/ui_bake/**, client/ui/** except client/ui/art/**, client/scripts/ui.gd, client/tests/ui_kit_tests.gd, client/tests/a11y_tests.gd, client/tests/shots/ui_*.gd (each task lists its own subset), docs/progress/K1.md, docs/progress/status/K1.json
Tasks: P0-K1-contract-2, then P0-K1-kitskin as their deps merge (P0-K1-contract and P0-K1-bake-1 are merged; P0-K1-bake-2 is ready)
STOP_AT: 2026-11-06T21:00:00Z (= 18:00 America/Sao_Paulo)
Wave plan: docs/art/ui-quality/report.md section 3     Phase: 0

Your session was created with the repository checked out at main; work in that checkout. Before your first pre-check, install the tools a fresh container lacks: rustup target add wasm32-unknown-unknown aarch64-linux-android aarch64-apple-ios; pip install "gdtoolkit==4.*" "playwright==1.63.0"; then bash client/build.sh. Main is claude/videogame-project-analysis-ewkkk2; branch claude/ui-bake from it (create it if it does not exist) and push only to claude/ui-bake with git push -u origin claude/ui-bake, retrying after 2, 4, 8 and 16 seconds on network failures. Take the first task in docs/progress/backlog.json on main whose assigned_to is K1, whose state is open and whose deps are all merged; when none is left, set agent_state "done", push, and end the session. One task per session. Pre-check with bash tools/run_checks.sh (start, then wait in the background, then record) before marking a task ready. Do not open a pull request. Do not stop to ask the owner anything: requests go to the lead in your status file, with a default.
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

Your session was created with the repository checked out at main; work in that checkout. Before your first pre-check, install the tools a fresh container lacks: rustup target add wasm32-unknown-unknown aarch64-linux-android aarch64-apple-ios; pip install "gdtoolkit==4.*" "playwright==1.63.0"; then bash client/build.sh. Main is claude/videogame-project-analysis-ewkkk2; branch claude/server-decisions from it (create it if it does not exist) and push only to claude/server-decisions with git push -u origin claude/server-decisions, retrying after 2, 4, 8 and 16 seconds on network failures. Take the first task in docs/progress/backlog.json on main whose assigned_to is SV, whose state is open and whose deps are all merged; when none is left, set agent_state "done", push, and end the session. One task per session. Pre-check with bash tools/run_checks.sh (start, then wait in the background, then record) before marking a task ready. Do not open a pull request. Do not stop to ask the owner anything: requests go to the lead in your status file, with a default.
```

## Now

- Cycle 18, 2 November 2026, from 23:38Z (session
  `session_01SNkKxokCvaGUnmATx2vzaZ`): the first cycle since the owner's
  pause (31 October 20:55Z) and resume (2 November 22:59Z). Usage now
  reads `allowed` (get_session: five-hour limit, no warning), so the two
  development gate runs of AD-R6 are launched: `dev-fable` in
  `session_01SNkKxonjTzEysQx5wxdp97` (Fable 5.1) and `dev-opus` in
  `session_01SNkKxogMyzESz7z3XzwBUJ` (Opus 5.5), both on branch
  `claude/ui-gate-runs`, each writing
  `docs/art/ui-quality/gate/verdicts/P0-AD-calibrate/<run>.jsonl` and its
  run's extended `plan.jsonl`, pushing every 50 calls, and ending with a
  commit "gate-run <run>: done". No status file changed since cycle 17
  (AD, AIA, K1 and SV `waiting`, nothing ready), no merge lock, nothing
  to merge, no alerts.
- Next: when both runners' "done" commits are on `claude/ui-gate-runs`,
  copy the two verdict files to main (they are the lead's), mark the
  runner sessions done here, and start AD on P0-AD-calibrate-2; AD takes
  the two extended `plan.jsonl` files from `claude/ui-gate-runs` in that
  task (they are AD's files). If a runner is idle without its "done"
  commit, restart it once (it resumes, skipping calls already written).
- BT-10 and BT-11 (`flaky.md`) stay open on the lead, unstarted.
- Cycle 17 (31 October 20:38Z, session `session_01SNkKxr25ThMqb9Aeot1dEV`):
  bookkeeping only; gate runs deferred while the seven-day usage read
  `allowed_warning`.
- Cycle 16 (19:38Z, session `session_01SNkKxrPXYJXnGbD1R9Zte3`):
  P0-K1-tokens-2 (785cb2a8) and P0-AD-calibrate (3f3797c7) merged as one
  batch candidate `d7561425` (check_all PASS, "ui guard: OK") onto main
  as `eec44b50`.
- Housekeeping: this cycle pushed a stray ref
  `lead/candidate-d756142555c04e567a54cc5367cc5b85edd99a7e` by mistake;
  the proxy refuses branch deletes (HTTP 403), so it stays. It points at
  the merged candidate and is harmless; candidates stay local from now on.
- Gap for the next SV task (or whichever task next touches
  `client/tests/`): `client/tests/a11y_motion_tests.gd` (SV-B11-B12) is on
  main without its Godot `.uid`, which every other test has tracked; any
  build regenerates it untracked (`uid://da3c5n2shdgh7` here). The lead
  does not commit it, since its bookkeeping touches only `docs/progress/**`.
- Tools in a fresh container: `rustup target add wasm32-unknown-unknown
  aarch64-linux-android aarch64-apple-ios`, `pip install "gdtoolkit==4.*"
  "playwright==1.63.0"`, then `bash client/build.sh`, before
  `run_checks.sh start` (cycle 16 started one first and had to stop it).
  Run `guard.sh` in its own worktree of the candidate (`client/build.sh`
  there first); about 12 minutes beside check_all.
- Cycle 15 (18:38Z) granted K1-R8 and restarted K1. Cycle 14 (17:39Z)
  merged O3 (`316ff98c`). Cycle 13 (15:39Z) merged P0-AD-golden-2
  (`520565f9`) and P0-AIA-board-4 (`f920b57b`). Cycle 11 (13:39Z) merged
  P0-AIA-keyframes-3 (`d0dd8a36`). Cycle 9 (11:39Z) merged P0-K1-tokens
  and P0-AIA-keyframes-2 (`b8308788`). Cycle 8 (08:38Z) merged O2-2 and
  P0-AIA-keyframes-1 (`fafc1a13`). Cycle 6 (04:38Z to 08:10Z) merged
  P0-K1-contract-2, P0-AIA-board-3 with P0-AD-golden, P0-K1-kitskin and
  SV-B11-B12.
- Earlier: cycle 4 (01:38Z) merged O2 and P0-K1-bake-2; cycle 3 (30
  October 23:22Z to 31 October 01:50Z) merged P0-AIA-board-2,
  P0-K1-bake-1, P0-AD-sheet and SV-B7-B9 and opened `flaky.md`; cycles 1
  and 2 (30 October) started and restarted the agents.
