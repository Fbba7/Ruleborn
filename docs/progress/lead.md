# The lead's handoff

> **Owner orders.** The owner stopped the program on 3 November 2026 and
> restarted it on 4 November 2026. Fable 5.1 is never used again, and
> `dev-fable-v3` is never resumed. Read the owner orders in
> [`CLAUDE.md`](../../CLAUDE.md) first: they override this file.

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

Latest lead cycle session: `session_01SNkKxngpz6t5F8cyrdiup4` (cycle 37,
4 November 2026, from 15:39Z, started by the launcher).

Retired on 30 October 2026, disabled and kept for their run history: the old
lead cycle `trig_018vvUDvm2PkMuXrcJPQ9BiB`, watchdog
`trig_01LatSpptvktXzQcEwYfn51A`, and the four restart tasks
(`trig_018WBkwVBocWr9kGbkrt1xs4`, `trig_01WpPzWUnLmna8PDzUYDhQVj`,
`trig_01JFG1PbKiumCjB4f61JcyJE`, `trig_016TpQMGvejeoBKfyQNWPd6Y`).

Agent sessions (on the repository at main, tagged `ruleborn:ui-wave` and
`ruleborn:<agent>`), the latest first per agent:

| Agent | Session | Task | Branch | Created |
|---|---|---|---|---|
| K1 | `session_01SNkKxrN8TYssSGXSznyneA` (working) | P1-K1-atlas-draw | `claude/ui-bake` | 2026-11-04 14:41Z |
| AIA-2 | `session_01SNkKxmwwK7YE4rm4Mh8nS1` (working) | P1-AIA2-icons-1a | `claude/ui-artist-icons` | 2026-11-04 14:41Z |
| AIA | `session_01SNkKxqU4sZmrYcBz3mbRR2` (working) | P1-AIA-kit-1 | `claude/ui-artist` | 2026-11-04 12:44Z |
| K1 | `session_01SNkKxpvstSMYkV1wwCL3rU` (idle, done) | P0-K1-kitspec-3 | `claude/ui-bake` | 2026-11-04 12:44Z |
| AIA-2 | `session_01SNkKxnm9wVSENc6xKHm79A` (idle, done) | P1-AIA2-toon-route | `claude/ui-artist-icons` | 2026-11-04 12:44Z |
| AD | `session_01SNkKxrEMe4td5Bk4zmN1Ed` (idle, done) | P0-AD-calibrate-2 | `claude/ui-ad` | 2026-11-03 11:09Z |
| gate run dev-fable (Fable 5.1) | `session_01SNkKxonjTzEysQx5wxdp97` (idle, done: 444 lines, 6 unknown, `0e78b6ce`) | AD-R6 for P0-AD-calibrate | `claude/ui-gate-runs` | 2026-11-02 23:40Z |
| gate run dev-opus (Opus 5.5) | `session_01SNkKxogMyzESz7z3XzwBUJ` (idle, done) | AD-R6 for P0-AD-calibrate | `claude/ui-gate-runs` | 2026-11-02 23:40Z |
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
Tasks: P1-AD-board-1 once its deps merge (every phase 0 AD task is merged). O2, O2-2 and O3 were yours (report.md section 3.4): you approve the board and contract, and label the golden set, in place of the owner; for O3's blind second labelling, launch a fresh subagent given only gate/rubric.md and the held-out items.
STOP_AT: 2026-11-09T21:00:00Z (= 18:00 America/Sao_Paulo)
Wave plan: docs/art/ui-quality/report.md section 3     Phase: 1

Your session was created with the repository checked out at main; work in that checkout. Before your first pre-check, install the tools a fresh container lacks: rustup target add wasm32-unknown-unknown aarch64-linux-android aarch64-apple-ios; pip install "gdtoolkit==4.*" "playwright==1.63.0"; (cd tools/ui_research && npm ci) for three.js, which the icon bake needs; then bash client/build.sh. Main is claude/videogame-project-analysis-ewkkk2; branch claude/ui-ad from it (create it if it does not exist) and push only to claude/ui-ad with git push -u origin claude/ui-ad, retrying after 2, 4, 8 and 16 seconds on network failures. Take the first task in docs/progress/backlog.json on main whose assigned_to is AD, whose state is open and whose deps are all merged; when none is left, set agent_state "done", push, and end the session. One task per session. Pre-check with bash tools/run_checks.sh (start, then wait in the background, then record) before marking a task ready. Do not open a pull request. Do not stop to ask the owner anything: requests go to the lead in your status file, with a default.
```

### AIA

```text
You are agent AIA of the Ruleborn agent program (UI wave). Read docs/guides/agent-brief.md first and follow it exactly; then docs/guides/agent-protocol.md where the brief links to it.

Agent: AIA            Role: maker (AIA): kit art and motion art        Model: Opus 5.5
Branch: claude/ui-artist
Owned files: art/ui/** except art/ui/icons/**, client/ui/art/kit*, docs/progress/AIA.md, docs/progress/status/AIA.json
Tasks: P1-AIA-kit-1, then P1-AIA-kit-2 to -5 as their deps merge (every phase 0 AIA task is merged). Icons are AIA-2's, not yours.
STOP_AT: 2026-11-09T21:00:00Z (= 18:00 America/Sao_Paulo)
Wave plan: docs/art/ui-quality/report.md section 3     Phase: 1

Your session was created with the repository checked out at main; work in that checkout. Before your first pre-check, install the tools a fresh container lacks: rustup target add wasm32-unknown-unknown aarch64-linux-android aarch64-apple-ios; pip install "gdtoolkit==4.*" "playwright==1.63.0"; (cd tools/ui_research && npm ci) for three.js, which the icon bake needs; then bash client/build.sh. Main is claude/videogame-project-analysis-ewkkk2; branch claude/ui-artist from it (create it if it does not exist) and push only to claude/ui-artist with git push -u origin claude/ui-artist, retrying after 2, 4, 8 and 16 seconds on network failures. Take the first task in docs/progress/backlog.json on main whose assigned_to is AIA, whose state is open and whose deps are all merged; when none is left, set agent_state "done", push, and end the session. One task per session. Pre-check with bash tools/run_checks.sh (start, then wait in the background, then record) before marking a task ready. Do not open a pull request. Do not stop to ask the owner anything: requests go to the lead in your status file, with a default.
```

### K1

```text
You are agent K1 of the Ruleborn agent program (UI wave). Read docs/guides/agent-brief.md first and follow it exactly; then docs/guides/agent-protocol.md where the brief links to it.

Agent: K1            Role: contract owner (K1): the UI kit, its bake and its guards        Model: Opus 5.5
Branch: claude/ui-bake
Owned files: docs/art/ui-quality/kit-spec.md, tools/ui_bake/**, client/ui/** except client/ui/art/**, client/scripts/ui.gd, client/tests/ui_kit_tests.gd, client/tests/a11y_tests.gd, client/tests/shots/ui_*.gd (each task lists its own subset), docs/progress/K1.md, docs/progress/status/K1.json
Tasks: P0-K1-kitspec-3, then P1-K1-atlas-draw, P1-K1-catalogue, P1-K1-words, P1-K1-switch-heist and P1-K1-switch-rest as their deps merge (every other phase 0 K1 task is merged)
STOP_AT: 2026-11-09T21:00:00Z (= 18:00 America/Sao_Paulo)
Wave plan: docs/art/ui-quality/report.md section 3     Phase: 1

Your session was created with the repository checked out at main; work in that checkout. Before your first pre-check, install the tools a fresh container lacks: rustup target add wasm32-unknown-unknown aarch64-linux-android aarch64-apple-ios; pip install "gdtoolkit==4.*" "playwright==1.63.0"; (cd tools/ui_research && npm ci) for three.js, which the icon bake needs; then bash client/build.sh. Main is claude/videogame-project-analysis-ewkkk2; branch claude/ui-bake from it (create it if it does not exist) and push only to claude/ui-bake with git push -u origin claude/ui-bake, retrying after 2, 4, 8 and 16 seconds on network failures. Take the first task in docs/progress/backlog.json on main whose assigned_to is K1, whose state is open and whose deps are all merged; when none is left, set agent_state "done", push, and end the session. One task per session. Pre-check with bash tools/run_checks.sh (start, then wait in the background, then record) before marking a task ready. Do not open a pull request. Do not stop to ask the owner anything: requests go to the lead in your status file, with a default.
```

### AIA-2

```text
You are agent AIA-2 of the Ruleborn agent program (UI wave). Read docs/guides/agent-brief.md first and follow it exactly; then docs/guides/agent-protocol.md where the brief links to it.

Agent: AIA-2            Role: maker (AIA-2): icon art        Model: Opus 5.5
Branch: claude/ui-artist-icons
Owned files: art/ui/icons/**, client/tests/shots/icon_*.gd, client/ui/art/icons_48*, client/ui/art/icons_256*, docs/progress/AIA-2.md, docs/progress/status/AIA-2.json
Tasks: P1-AIA2-toon-route, then P1-AIA2-icons-1a, -1b, -2a and -2b as their deps merge. Icon batches 3 and 4 are deferred (D13's answer (c)); do not start them.
STOP_AT: 2026-11-09T21:00:00Z (= 18:00 America/Sao_Paulo)
Wave plan: docs/art/ui-quality/report.md section 3     Phase: 1

Your session was created with the repository checked out at main; work in that checkout. Before your first pre-check, install the tools a fresh container lacks: rustup target add wasm32-unknown-unknown aarch64-linux-android aarch64-apple-ios; pip install "gdtoolkit==4.*" "playwright==1.63.0"; (cd tools/ui_research && npm ci) for three.js, which the icon bake needs; then bash client/build.sh. Main is claude/videogame-project-analysis-ewkkk2; branch claude/ui-artist-icons from it (create it if it does not exist) and push only to claude/ui-artist-icons with git push -u origin claude/ui-artist-icons, retrying after 2, 4, 8 and 16 seconds on network failures. Take the first task in docs/progress/backlog.json on main whose assigned_to is AIA-2, whose state is open and whose deps are all merged; when none is left, set agent_state "done", push, and end the session. One task per session. Pre-check with bash tools/run_checks.sh (start, then wait in the background, then record) before marking a task ready. Do not open a pull request. Do not stop to ask the owner anything: requests go to the lead in your status file, with a default.
```

### S1

```text
You are agent S1 of the Ruleborn agent program (UI wave). Read docs/guides/agent-brief.md first and follow it exactly; then docs/guides/agent-protocol.md where the brief links to it.

Agent: S1            Role: maker (S1): the heist screens, the phase 1 pilot        Model: Sonnet 5.5
Branch: claude/ui-screens-heist
Owned files: only the files each S1 task lists in the backlog, docs/progress/S1.md, docs/progress/status/S1.json
Tasks: P1-S1-pilot-1, then P1-S1-pilot-2 as their deps merge (pilot-1 waits on P1-K1-switch-heist and P1-AIA2-icons-1b).
STOP_AT: 2026-11-09T21:00:00Z (= 18:00 America/Sao_Paulo)
Wave plan: docs/art/ui-quality/report.md section 3     Phase: 1

Your session was created with the repository checked out at main; work in that checkout. Before your first pre-check, install the tools a fresh container lacks: rustup target add wasm32-unknown-unknown aarch64-linux-android aarch64-apple-ios; pip install "gdtoolkit==4.*" "playwright==1.63.0"; (cd tools/ui_research && npm ci) for three.js, which the icon bake needs; then bash client/build.sh. Main is claude/videogame-project-analysis-ewkkk2; branch claude/ui-screens-heist from it (create it if it does not exist) and push only to claude/ui-screens-heist with git push -u origin claude/ui-screens-heist, retrying after 2, 4, 8 and 16 seconds on network failures. Take the first task in docs/progress/backlog.json on main whose assigned_to is S1, whose state is open and whose deps are all merged; when none is left, set agent_state "done", push, and end the session. One task per session. Pre-check with bash tools/run_checks.sh (start, then wait in the background, then record) before marking a task ready. Do not open a pull request. Do not stop to ask the owner anything: requests go to the lead in your status file, with a default.
```

### SV

```text
You are agent SV of the Ruleborn agent program (UI wave). Read docs/guides/agent-brief.md first and follow it exactly; then docs/guides/agent-protocol.md where the brief links to it.

Agent: SV            Role: maker (SV): the owner's server decisions B1-B12 (docs/decisions/owner-decisions.md, Build tasks)        Model: Sonnet 5.5
Branch: claude/server-decisions
Owned files: only the files each SV task lists in the backlog, docs/progress/SV.md, docs/progress/status/SV.json
Tasks: none open (SV-B1-B6, SV-B7-B9 and SV-B11-B12 are merged; SV-B10 is not yours yet). Run the client suite (python3 client/status.py) before marking a task ready.
STOP_AT: 2026-11-09T21:00:00Z (= 18:00 America/Sao_Paulo)
Wave plan: docs/art/ui-quality/report.md section 3     Phase: 1

Your session was created with the repository checked out at main; work in that checkout. Before your first pre-check, install the tools a fresh container lacks: rustup target add wasm32-unknown-unknown aarch64-linux-android aarch64-apple-ios; pip install "gdtoolkit==4.*" "playwright==1.63.0"; (cd tools/ui_research && npm ci) for three.js, which the icon bake needs; then bash client/build.sh. Main is claude/videogame-project-analysis-ewkkk2; branch claude/server-decisions from it (create it if it does not exist) and push only to claude/server-decisions with git push -u origin claude/server-decisions, retrying after 2, 4, 8 and 16 seconds on network failures. Take the first task in docs/progress/backlog.json on main whose assigned_to is SV, whose state is open and whose deps are all merged; when none is left, set agent_state "done", push, and end the session. One task per session. Pre-check with bash tools/run_checks.sh (start, then wait in the background, then record) before marking a task ready. Do not open a pull request. Do not stop to ask the owner anything: requests go to the lead in your status file, with a default.
```

## Now

- Cycle 36, 4 November 2026, from 13:39Z (session
  `session_01SNkKxrLqp81CeCToVADsyb`, started by the launcher): merged
  P0-K1-kitspec-3 and P1-AIA2-toon-route in one batch as `9b2bde70`
  (check_all PASS; owners.py clean once
  `client/tests/shots/icon_portraits.gd.uid` was granted to the toon route
  as an exception, the P0-K1-kitskin precedent). guard.sh failed only its
  rebake step, because tools/ui_bake has no renderer for kind "scene"
  families yet; AIA2-R1's default applied: the lead rebaked the icon
  families with `art/ui/icons/studio/bake_icons.js` (after `npm ci` in
  tools/ui_research) and all six icon files matched byte for byte, and
  K1's P1-K1-atlas-draw now carries wiring kind "scene" into bake.js
  (AIA2-R1), with AIA-R9 and AIA-R12. K1-R9 done; AIA-R10 default stands.
  The watchdog's 14:13Z stale-lock alert resolved. Prompts now install
  three.js. Started K1 on P1-K1-atlas-draw
  (`session_01SNkKxrN8TYssSGXSznyneA`) and AIA-2 on P1-AIA2-icons-1a
  (`session_01SNkKxmwwK7YE4rm4Mh8nS1`); AIA still on P1-AIA-kit-1. Three
  builders, the D13 (c) cap. Pages not republished.
- Next: watch K1, AIA and AIA-2; gate and merge each task as it reaches
  `ready`. Until K1 wires kind "scene" into bake.js, substitute guard.sh's
  rebake step for icon families with bake_icons.js (`npm ci` in
  tools/ui_research first) and a byte compare. When taking the merge lock,
  set `expected_next_update_by` past the lock's expiry. S1 and AD wait on
  their deps and a free builder slot. If `stop_at` nears with work left,
  move it forward (order 3). Never use Fable 5.1 (CLAUDE.md).
- Cycle 35, 4 November 2026, from 12:39Z (session
  `session_01SNkKxofbM8PTQZdFF13dEe`, started by the launcher): phase 1
  started under owner order 3 (CLAUDE.md). Seeded 18 phase 1 tasks
  (`3939b11d`): K1's atlas-draw, catalogue, words and the two family
  switches; AIA's kit-1 to -5; the new agent AIA-2's toon route and icon
  batches 1a to 2b (batches 3 and 4 deferred, D13 (c)); the new agent S1's
  heist pilot 1 and 2 (Sonnet 5.5); AD's board 1. `phase` 1, `stop_at`
  2026-11-09T21:00:00Z. owners.py claims clean. Prompts updated (phase 1,
  new STOP_AT; AIA-2 and S1 added). Started three builders, the D13 (c)
  cap: K1 on P0-K1-kitspec-3 (`session_01SNkKxpvstSMYkV1wwCL3rU`), AIA on
  P1-AIA-kit-1 (`session_01SNkKxqU4sZmrYcBz3mbRR2`) and AIA-2 on
  P1-AIA2-toon-route (`session_01SNkKxnm9wVSENc6xKHm79A`). Nothing ready,
  nothing merged, pages not republished. Owner told (inbox, no answer
  needed).
- Next: watch K1, AIA and AIA-2; gate and merge each task as it reaches
  `ready`. S1 and AD wait on their deps (S1's pilot-1 on
  P1-K1-switch-heist and P1-AIA2-icons-1b); keep at most three UI builders
  at once, so S1 starts only when a builder slot is free. If `stop_at`
  nears with work left, move it forward (order 3). AD's golden set v2,
  rubric v4 and the `render` crop fix stay unfiled while the cap is full.
  Never use Fable 5.1 (CLAUDE.md).
- Cycle 34, 4 November 2026, from 11:39Z (session
  `session_01SNkKxqYuKcaV9WFPjR4eYL`, started by the launcher):
  bookkeeping only. No roster branch moved since cycle 27 (AD, AIA, K1
  and SV all `waiting` on tasks already merged; no new requests), no
  merge lock, nothing ready, nothing merged, pages not republished, no
  session started. The seven-day bar still reads `allowed_warning`
  (reset 2026-11-09T17:00Z).
- Next (owner order 3, CLAUDE.md, 4 November 2026): a usage tier is no
  longer a reason to pause. Start phase 1 now: seed phase 1's tasks
  (without icon batches 3 and 4), start K1 on P0-K1-kitspec-3 and the
  other agents as their tasks open, at most three UI builders at once
  (D13's answer (c)), and set a new `stop_at` for phase 1. The cycle 27
  rule below ("start no building session while the bar reads
  `allowed_warning`") no longer applies. Never use Fable 5.1 (CLAUDE.md).
- Cycles 28 to 33, 4 November 2026, 05:38Z to 10:40Z (sessions
  `session_01SNkKxqggtvFkbsicdmz58F`, `session_01SNkKxp3mbYDaJnVdPiRV3R`,
  `session_01SNkKxrFapFkzWn83y5X9ky`, `session_01SNkKxqLRk7TzD31oWv3kM6`,
  `session_01SNkKxo9TNVATJL3S4bNxyc`, `session_01SNkKxqdB4Qn1GGpgMJ8SUE`,
  all started by the launcher): bookkeeping only, each the same: nothing
  moved, nothing ready, usage in warning.
- Cycle 27, 4 November 2026, from 04:38Z (session
  `session_01SNkKxnqf4U1yn3FoEDAMTb`, started by the launcher): answered
  OV-R1 with [`usage-projection.md`](usage-projection.md). `/usage`
  cannot be read unattended; the seven-day bar reads `allowed_warning`
  (reset 2026-11-09T17:00Z). Phase 0 used about one weekly bar; phases 1
  to 3 need about four more, so the projection does not fit and D13's
  answer (c) applies (three builders, icon batches 3 and 4 deferred).
  Phase 0's exit criteria are all met. Owner alerted (inbox, 04:40Z; no
  answer needed). No roster status changed, no merge lock, nothing ready,
  nothing merged, pages not republished, no session started.
- Next: start no building session while the bar reads `allowed_warning`.
  After the reset: start K1 on P0-K1-kitspec-3, seed phase 1's tasks
  (without icon batches 3 and 4), set its `stop_at`, and re-measure the
  rate with one agent alone for its first 30 minutes. Never use Fable 5.1
  (CLAUDE.md).
- Cycle 26, 4 November 2026, from 03:39Z (session
  `session_01SNkKxn1EkNKS1Uoxxu2Lvn`, started by the launcher):
  bookkeeping only. No roster status changed since cycle 25 (AD, AIA, K1
  and SV all `waiting` on tasks already merged; no new requests), no
  merge lock, nothing ready, nothing merged, pages not republished.
  P0-K1-kitspec-3 (K1, open) stays unstarted: usage still reads
  `allowed_warning` (seven-day, resets 2026-11-09T17:00Z).
- Next: start K1 on P0-K1-kitspec-3 once usage allows; then decide on
  AD's golden set version 2 and rubric version 4. Never use Fable 5.1
  (CLAUDE.md).
- Cycle 25, 4 November 2026, from 02:39Z (session
  `session_01SNkKxnpW76h9UU2VzxnVPi`, started by the launcher): merged
  P0-AD-calibrate-2 (AD, ready at `8e4b808`). owners.py diff and claims
  clean; candidate `0e2a6317` passed check_all (03:15:33Z, "All checks
  passed."); main had gained only this cycle's lock commit, so the
  candidate went onto it as `0ff3278a` with the documentation check re-run.
  No guard: nothing under `client/` or `art/` changed. Results: Opus 5.5 is
  the judge; rubric version 3; the held-out run `held-opus` missed the
  target on all eight judged qualities, so all eight are owner-checked (AD
  checks each on every board; the judge's verdicts are advice).
  Pages not republished: the merge changed neither `docs/audit/`,
  `docs/roadmap/` nor their generators' sources, so the published pages
  already match main.
  AD's request on `results.jsonl` takes its default: the runs stay in
  `gate/calibration/runs/`. AD has no open task left (session idle, done).
- Filed K1-R9 (the overseer's follow-up to C74 and C75) as
  P0-K1-kitspec-3 for K1, open, about 0.5 h, documents and tokens.json
  notes only. Not started: usage still reads `allowed_warning` (seven-day,
  resets 2026-11-09T17:00Z), and it is not urgent. AIA's M1 ack is noted
  (owner inbox, 4 November 02:05Z).
- Next: AD proposes golden set version 2 (more passing items per quality,
  quality 3's relabel), then rubric version 4 and a fresh held-out run, and
  a fix to `render` leaving crops missing; not yet filed, since phase 0's
  close comes first and usage is in warning. Start K1 on P0-K1-kitspec-3
  once usage allows. Never use Fable 5.1 (CLAUDE.md).
- Cycle 24, 4 November 2026, from 01:39Z (session
  `session_01SNkKxperiwzZk3yVhDBHZf`, started by the launcher), the first
  cycle after the owner's restart: bookkeeping only. AD
  (`session_01SNkKxrEMe4td5Bk4zmN1Ed`, idle between turns, its own
  check-in due at 01:43Z to score) is still on P0-AD-calibrate-2,
  `working`, lease to 04:10Z: Opus-only runs dev-opus-v3 (426 calls) and
  held-opus (414 calls) pushed to `claude/ui-ad` (`1c886ca4`). AIA
  acknowledged M1 (`fd2620f2`), which closes the M1 item noted in the
  owner inbox on 31 October. No other roster status changed (AIA, K1 and
  SV status files still show tasks merged long ago), no merge lock,
  nothing to merge, pages not republished.
- Next: watch AD. When `status/AD.json` on `claude/ui-ad` shows
  P0-AD-calibrate-2 `ready`, gate and merge it (owners.py diff, check_all
  PASS), then republish both pages. Usage still reads `allowed_warning`
  (seven-day, resets 2026-11-09T17:00Z), so start no session beyond AD.
  Never use Fable 5.1 (CLAUDE.md).
- Cycle 23, 3 November 2026, from 11:39Z (session
  `session_01SNkKxoYmLFt1yB79vuEdqD`, started by the launcher):
  bookkeeping only. AD (`session_01SNkKxrEMe4td5Bk4zmN1Ed`) is working on
  P0-AD-calibrate-2: `status/AD.json` reads `working`, with dev-opus-v2
  (rubric version 2) results pushed to `claude/ui-ad` (`7f3945a0`, 309
  calls). No other roster status changed, no merge lock, nothing to merge,
  pages not republished.
- Next: watch AD. When `status/AD.json` on `claude/ui-ad` shows
  P0-AD-calibrate-2 `ready`, gate and merge it (owners.py diff, check_all
  PASS), then republish both pages. Usage still reads `allowed_warning`
  (seven-day, resets 2026-11-09T17:00Z), so start no session beyond AD.
- Cycle 22, 3 November 2026, from 11:08Z (session
  `session_01SNkKxp9qUS4iHzqFjbgh1C`, started by the launcher): `dev-fable`
  finished (`0e78b6ce` on `claude/ui-gate-runs`, 444 lines: 366 base calls
  plus 78 extra samples from the D-06 split rule, 6 unknown); its
  `dev-fable.jsonl` was copied to main (`720e309e`). Both development runs
  are now on main, so AD was started on P0-AD-calibrate-2
  (`session_01SNkKxrEMe4td5Bk4zmN1Ed`), told to take the extended
  `plan.jsonl` files (dev-fable +78, dev-opus +48 lines) from
  `claude/ui-gate-runs`. No status file changed, no merge lock, nothing to
  merge, pages not republished.
- Cycle 21 (06:38Z, session `session_01SNkKxodap1UHY9Fb2zQzaR`):
  bookkeeping only; `dev-fable` at 366 of 414.
- Cycle 20 (06:11Z, session
  `session_01SNkKxo6TYzdUtAL4USoPyt`, started by the watchdog): no lead
  cycle ran between 01:41Z and 06:11Z because the account hit its
  five-hour usage limit (owner-inbox, 06:10Z). Branches
  `claude/ui-screens` and `claude/ui-research` (not on the roster) are
  left alone.
- Cycle 19 (01:38Z, session `session_01SNkKxpMi6cZ8M6M33w8ntT`): dev-opus
  finished (`e3a9b94a`, 217 pass, 197 fail); its `dev-opus.jsonl` was
  copied to main.
- BT-10 and BT-11 (`flaky.md`) stay open on the lead, unstarted.
- Cycle 18 (2 November 23:38Z, session `session_01SNkKxokCvaGUnmATx2vzaZ`):
  the first cycle after the owner's pause and resume; launched the two
  AD-R6 development gate runs on `claude/ui-gate-runs`.
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
