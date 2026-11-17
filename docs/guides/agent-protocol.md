# The agent protocol: states, files, the merge queue and the coordinator

This page is the exact protocol behind [agent-program.md](agent-program.md):
the roster, the one list of task states and who moves a task between them,
the formats of the files agents exchange, the merge queue, what the
coordinator and the lead do on each cycle, what an agent does when it is
blocked, and four worked examples. The brief,
[agent-brief.md](agent-brief.md), tells each agent which of these steps are
its own. Where this page and the program disagree, this page is the later
statement and the program should be fixed.

The rules here are mostly inference: no study measures merge queues, leases
or request deadlines for LLM agents. Where a rule rests on something
stronger, it says so. The research behind them is
[`docs/research/agent-team-operating-model.md`](../research/agent-team-operating-model.md).

## Order of authority

Order of authority: (1) the design document; (2) the owner's decisions
(`docs/decisions/answers.json`); (3) the wave's plan and its track table;
(4) `agent-program.md` and `agent-protocol.md`; (5) `agent-brief.md`;
(6) your prompt. A lower source may narrow a higher one, never widen it. If
two conflict, send the lead a request and keep working on what does not
conflict.

The UI wave's plan (section 3.8 of `report.md`) once said a ready branch
must contain main's head. By the owner's own work order to T17 (recorded in
[`T17-work-order-report.md`](../progress/T17-work-order-report.md)) the queue
on this page replaced that rule, and the plan now states the queue (request
T17-R1, done).

The owner decided the work order's D-01 to D-14 on 29 October 2026, with
T17's defaults. The answers, including D-02's cycle, D-09's settings and
D-14's protection of main, are listed in
[agent-program.md](agent-program.md#the-work-orders-decisions).

## Terms

| Term | Meaning |
|---|---|
| main | The branch `claude/videogame-project-analysis-ewkkk2`, the lead's branch |
| Lead, integrator | Plans, keeps the backlog, runs the merge queue. The only agent that moves main |
| Coordinator | The mechanical part of the lead's job, done by script once it exists (planned: backlog task BT-01). Until then the lead does it by hand on its scheduled cycle |
| Candidate | A local merge of main's head with one or more ready changes, checked before main moves to it |
| Full checks | `bash tools/check_all.sh` plus every guard the wave's plan lists (the UI wave: `tools/ui_bake/guard.sh` for changes that touch the client or the art, once K1 has written it) |
| Pre-check | The full checks, run by the agent on its own `ready_sha` before it marks ready |
| Quick checks | `python3 tools/check_docs_consistency.py`, plus the steps in [checks.md](checks.md)'s table for the areas your files touch (for the client, `python3 client/status.py`). Nothing defined them before this page |
| Status file | `docs/progress/status/<agent>.json`, on the agent's own branch |
| Progress file | `docs/progress/<agent>.md` |
| Backlog | `docs/progress/backlog.json`, on main, written only by the lead |
| Requests log | `docs/progress/requests.md`, on main, written by the lead |
| Owner inbox | `docs/progress/owner-inbox.md`, on main, written by the lead: every alert and every question waiting on the owner |

## The roster

Each wave's plan names its agents. The UI wave's are in section 3.1 of
[`report.md`](../art/ui-quality/report.md); this table adds what the
protocol needs (the tier and the shared things each one owns). Files are
owned by the agent holding the claimed task, inside the globs below, never
by a role in general.

> **Models since 9 November 2026.** By the owner's order 4
> ([CLAUDE.md](../../CLAUDE.md)), every model named in the table below
> reads Fable 5.2: the lead, every agent, every subagent and the gate's
> judge. The Model column keeps the plan as it stood before that order.
> The gate so runs on the same model as the agents it checks; its verdicts
> are advisory and the owner checks every quality.

| Agent | Role | Branch | Model | Active phases | Owns (globs) | Tier |
|---|---|---|---|---|---|---|
| Lead | Lead | main | Opus 5.5, medium effort | all | `docs/progress/backlog.json`, `docs/progress/requests.md`, `docs/progress/owner-inbox.md`, `docs/progress/flaky.md`, `docs/progress/status/lead.json`, the verdict files it writes for the gate, the hotspot files (`client/project.godot`, autoload registries, `client/export_presets.cfg`), `tools/check_all.sh`, the toolchain pins, the server, and every file no other agent owns | 1 |
| AD | Art director: writes the gate's criteria, golden set and shot lists; reviews the integrated flows at each phase end | `claude/ui-ad` | Opus 5.5 | 0, then one short session at each phase end | `docs/art/ui-quality/gate/**` except `gate/verdicts/`, `tools/ui_gate/**` | 1 |
| Gate | Independent reviewer, read-only | `claude/ui-gate` | Opus 5.5 (never Fable 5.1: owner, 3 November 2026) | 0–3, in short runs | none: its verdicts are written by its launcher | 1 |
| AIA | Maker: the kit art and the motion art | `claude/ui-artist` | Opus 5.5 | 0–2 | `art/ui/**` except `art/ui/icons/**`; `client/ui/art/**` (written only by the bake) | 1 |
| AIA-2 | Maker: the icons | `claude/ui-artist-icons` | Opus 5.5 | 1–2 | `art/ui/icons/**`, `client/tests/shots/icon_*.gd` | 2 (batches 3–4: 3) |
| K1 | Contract owner: the UI kit, its bake and its guards | `claude/ui-bake` | Opus 5.5 in phases 0–1; Sonnet 5.5 in phase 2 | 0–2 | `docs/art/ui-quality/kit-spec.md`, `tools/ui_bake/**` (the guard baselines in `tools/ui_bake/budgets.json` included), `tools/ui_research/**`, `client/prototypes/ui_quality/**`, `client/tests/shots/uiq_*.gd`, `client/scripts/ui.gd`, `client/ui/**` except `client/ui/art/**`, `tools/ui/**`, `client/tests/ui_kit_tests.gd`, `client/tests/a11y_tests.gd`, `client/tests/shots/ui_*.gd` | 1 |
| S1 | Maker: heist and result | `claude/ui-screens-heist` | Sonnet 5.5 | 1–2 | `client/scripts/heist_screen.gd`, `heist_hud.gd`, `result_screen.gd`, `replay_screen.gd`, `client/world/fx_*.gd` | 1 |
| S2 | Maker: home | `claude/ui-screens-home` | Sonnet 5.5 | 2 | `client/scripts/home.gd` | 2 |
| S3 | Maker: character, settings and the menu screens | `claude/ui-screens-meta` | Sonnet 5.5 | 2 | `client/scripts/character_screen.gd`, `client/scripts/screen_*.gd`, `client/scripts/settings_screen.gd`, `client/tests/shots/screen_*.gd` | 2 |
| SV | Maker: the owner's server decisions B1–B12 ([owner-decisions.md](../decisions/owner-decisions.md#build-tasks)), outside the UI wave's three building slots by the owner's approval of 30 October 2026 | `claude/server-decisions` | Sonnet 5.5; a fresh Opus 5.5 session after a second failed pre-check | 0–1 | only the files its task lists: the lead's server files it assigns to it | 2 |
| Specialists | One narrow job each | `claude/ui-spec-<job>` | chosen per job | as the backlog lists | only the files their task lists | 3 |

**Shared things and their owners.** The string table
`client/i18n/strings.csv` has one owner at a time, named on the task in the
backlog (section 3.1 of `report.md`). Route tables, the server API the
client calls, `server/load.mjs`'s recorded baseline and the toolchain are the
lead's, and every change to them is a lead-owned backlog task. The UI guards'
baselines are K1's. The gate's rubric, golden set and shot lists are AD's.
Planned: backlog task BT-08 splits strings and routes into per-screen files
merged by script, so each screen owns its own.

**A guard baseline** rises only by a request to the guard's owner, giving the
reason, with the lead's approval, recorded beside the baseline.

**Sub-leads** are not used in the UI wave: it has at most five builders.

### The schedule against the cap

The cap is three building sessions at once until merge throughput is
measured (decision D-05), then whatever the sizing rule below
allows, never more than the wave plan's five. The lead and the gate's short
runs are outside the cap.

| Phase | Building at once | Who | When a slot frees |
|---|---|---|---|
| 0 | 3 | AD, AIA, K1 | none needed |
| 1 | 3 until the check time is measured, then up to 4 | K1, AIA, AIA-2 | S1 (the critical path), once the heist's kit families and icon batch 1 have merged (report step 7) |
| 2 | 4 by the owner's order of 12 November 2026 (CLAUDE.md order 3); 3 while the seven-day bar reads `allowed_warning` | S1, AIA, S2 | S3, then AIA-2, then K1's request slot |
| 3 | up to 5 | as the backlog assigns | the idle queue |

**The sizing rule.** Builders running at once ≤ merges per hour × average
task hours, where merges per hour ≈ 60 ÷ check minutes per candidate. As
soon as two tasks are ready at once, batch 2–3 changes per candidate
(re-checking them one at a time if the batch fails); if the oldest ready
task still waits more than 2 hours, lower the cap. The
lead measures the real check time after phase 1 and records it in the
backlog's `check_minutes`. With today's 25-minute checks that is about 2.4
merges an hour (inference; Appendix B of the work order estimated 0.8–1.3
under the old rules).

## Tasks and their states

One list of states is used in the backlog, the status files and every page.

| task_state | Set by | When | Lease |
|---|---|---|---|
| `open` | lead or coordinator (an agent yielding a claim writes it in its own status) | created; lease expired; claim yielded | none |
| `claimed` | agent | it started the task the lead assigned it, or (later waves) the claim protocol is done | runs (3 h, renewed by each *pushed* status commit) |
| `working` | agent | first work commit | runs |
| `ready` | agent | pre-check passed and gate passed at `ready_sha` | paused |
| `resync` | coordinator | candidate has a textual conflict or fails checks | runs |
| `blocked` | agent | waiting on a blocking request, or main is red | paused until the request's `due` |
| `merged` | coordinator | main moved to the candidate | ended |
| `parked` | agent | stopped mid-task at STOP_AT | paused; the claim is kept until the next wave unless the lead reopens it |

**Transitions.** `open → claimed → working → ready → merged` is the normal
path. `ready → resync → working → ready` when a candidate fails.
`working → blocked → working` when the request is answered or its `due`
passes. Any of `claimed`, `working`, `resync` or `blocked` goes to `parked` at
STOP_AT, and to `open` when the lease lapses. `parked → open` only when the
lead reopens it, and then it records `prior_branch` and `prior_sha`.

**The agent's own state** is separate. `agent_state` is one of:

| agent_state | Meaning |
|---|---|
| `active` | A session is working |
| `waiting` | No session runs; the task is `ready` or `blocked`, and the lead restarts the agent when that changes |
| `stopped` | Stopped at STOP_AT, or by a tier-stop message it acknowledged |
| `done` | Neither the backlog nor the idle queue has a task its role may take |

### The task format

The backlog's format, with examples, is
[`backlog.example.json`](../progress/backlog.example.json).

| Field | Meaning |
|---|---|
| `id`, `title`, `phase`, `role` | What the task is and which agent may take it |
| `assigned_to` | The agent the lead assigned the task to (the UI wave), or `null` where agents claim (later waves) |
| `model` | The model the task runs on, set by the lead from the routing table; escalation changes it |
| `files` | The paths the task may change. Globs are allowed; a new file inside one of them belongs to the claimant. Tasks claimed at the same time have disjoint `files` |
| `deps` | Task ids that must be `merged` first |
| `done_when` | The checks that must pass, as commands, gate classes or owner sign-offs. A task that adds an optimisation lists the guard that protects it |
| `gate_items` | `[{"item", "qualities": [...]}]`: what the gate checks. Empty for work no judge checks; a contract has an owner sign-off in `done_when` instead |
| `attempts` | Gate fails so far; at 2, the escalation rule applies |
| `estimate_h`, `tier` | Hours (at most 4 for one session); the usage tier (1 stops last, 3 first) |
| `critical` | `true` on the wave's critical path; the merge queue takes these first |
| `state` | A task_state above |
| `claim` | `agent`, `branch`, `claimed_at`, `seen_at` (when the coordinator first saw the push), `lease_until`; or `null` |
| `prior_branch`, `prior_sha` | Set when a lease lapsed with work on the old branch; the next claimant merges `prior_sha` first |
| `ready_sha`, `merged_sha` | The commit marked ready, and main's commit after the merge |

The order of the `tasks` array is priority: the first `open` task an agent
may take is the one it takes.

### Taking work: assignment in the UI wave

In the UI wave each role has one agent, so **the lead assigns tasks** and
agents do not race for them. The lead sets `assigned_to` on each task and
names the task in the agent's launch prompt or in a message. An agent takes
the first task in `tasks` order whose `assigned_to` is its own id, whose
`state` is `open` (or `parked`, `resync` or `blocked` with its own branch as
the work) and whose `deps` are all `merged`; it writes its status file with
that `task_id` and `task_state: "claimed"`, `claimed_at` and `lease_until`
three hours later, and pushes. It never takes a task assigned to someone
else. If it has none, it sets `agent_state: "done"`, pushes and ends the
session; the lead assigns more at its next cycle and starts a fresh
session. Leases, `prior_sha` and the states work the same way as for a
claim. The lead reassigns a task only after its lease lapses.

**Keeping the queue full** (from 17 November 2026, so no seat waits a
cycle for work). At the end of every cycle the backlog holds at least one
task per free seat that an agent could start: `open`, its deps merged (or
one dep `ready`, below), its files disjoint from the work in flight. When
the product tasks run short, the lead refills `idle_queue` with the kinds
section 3.2 of the UI report lists (an overflow sweep of a merged screen in
pt_BR at 200%, fixes from the advisory gate notes, a docs or test gap in
the agent's files). Once phase 2's exit is met, or its `stop_at` passes,
the lead seeds phase 3's tasks from S3-R32, the board's objections, the
audit's findings and the open exceptions, with the order M33 sets.

**Stacked tasks.** A task whose one unmerged dep is `ready` need not wait
for that dep to merge: the lead may start it "stacked on <dep>". The agent
branches from main, merges the dep's `ready_sha` and builds on it (the
brief's "Taking work", step 4). In the queue the stacked task goes right
after its dep and never before: its candidate is taken from a main that
holds the dep, `owners.py diff` runs against that main (so the dep's files
do not count as the stacked task's), and both get their full checks (a
stacked candidate never differs from its `ready_sha` only under
`docs/progress/`, so the reuse in "The merge queue", step 4, never
applies). If the dep goes to `resync`, the stacked task waits; once the dep
is ready anew the agent merges main and the new `ready_sha`.

**The claim protocol** is for later waves, where several agents share a
role: the agent picks the first `open` task its role may take, writes the
claim in its own status file, pushes and checks again; "earlier" is the
earlier push as the coordinator sees it, and on a tie the lower agent id
wins (string order: `AD` before `S1`). The loser writes `open` for it and
picks again.

## The status file

One JSON object at `docs/progress/status/<agent>.json` on the agent's own
branch, rewritten and pushed on every status commit. **The authoritative copy
is on `origin/<agent-branch>`.** Copies that reach main through merges are
history; never read them for claims or leases. Read another agent's with:

```bash
git fetch origin
git show origin/<their-branch>:docs/progress/status/<agent>.json
```

```json
{
  "agent": "S2",
  "role": "S2",
  "branch": "claude/ui-screens-home",
  "model": "Sonnet 5.5",
  "agent_state": "active",
  "task_id": "P2-S2-home",
  "task_state": "working",
  "claimed_at": "2026-11-03T09:05:00Z",
  "lease_until": "2026-11-03T12:40:00Z",
  "updated_at": "2026-11-03T09:40:00Z",
  "expected_next_update_by": "2026-11-03T10:25:00Z",
  "long_run": null,
  "progress_marker": {"last_green_sha": "1a2b3c4", "next_step": "Move the currency pills onto K23; then the 200% text shot"},
  "precheck": null,
  "gate_request": null,
  "ready_sha": null,
  "stop_at": "2026-11-03T21:00:00Z",
  "acks": ["M7"],
  "requests": [
    {
      "id": "S2-R1",
      "from": "S2",
      "to": "K1",
      "ask": "A currency pill with a storage bar at 200% text",
      "files": ["client/ui/kit_status.gd"],
      "blocking": false,
      "created_at": "2026-11-03T09:40:00Z",
      "due": "2026-11-03T15:40:00Z",
      "default": "S2 uses the plain currency pill and files the bar as a phase 3 task",
      "escalate_to": "lead"
    }
  ],
  "answers": [
    {"request_id": "S1-R3", "answer": "Use K17 with the compact variant; no change needed", "at": "2026-11-03T09:38:00Z"}
  ]
}
```

| Field | Rule |
|---|---|
| `expected_next_update_by` | At most `updated_at` + 45 min, unless `long_run` is set |
| `long_run` | `{"log": "<path>", "expected_end": "<UTC>"}` while a run longer than 45 minutes is going; `expected_end` at most 90 minutes after `updated_at` |
| `progress_marker` | `last_green_sha` and `next_step`. If it is unchanged for 2 hours while `agent_state` is `active`, the coordinator flags a busy stall |
| `precheck` | `{"sha", "exit", "finished_at", "summary"}` from the pre-check's log: the last check heading reached and its last line |
| `gate_request` | `{"sha", "items"}`: asks the lead to launch the gate on those items at that commit |
| `requests` | Every field above is required. `due` is at most 6 hours after `created_at` for a blocking request (inference) |
| `answers` | Answers to requests addressed to this agent |

**Leases and stalls are timed from pushes.** A lease is renewed only by a
pushed status commit, timed from when the coordinator first sees it (its
`seen_at`), not from the agent's own timestamps. The coordinator reads
`expected_next_update_by` as at most `seen_at` + 45 minutes (or
`long_run.expected_end`). An agent is **stalled** when that time has passed
with no newer pushed status.

## Messages and requests

**Messages** are the lead's instructions, kept in the backlog's `messages`:

```json
{"id": "M7", "to": "S2", "text": "...", "sent_at": "2026-11-03T09:30:00Z", "ack_by": "2026-11-03T10:30:00Z", "acked_at": null}
```

A message is delivered only when its id is in the recipient's pushed `acks`.
Only the lead's messages are instructions.

**Requests** are asks between agents, written in the sender's status file in
the format above. At each cycle the coordinator (by hand until BT-01) copies
every open request into `docs/progress/requests.md` on main, grouped under
the addressee's id, with the answer once one is pushed. An addressee reads
that file at session start and at each checkpoint, answers in its own status
file's `answers`, and makes any change in its own files. A request is an
ask, not an order: the addressee checks it against its files, the design
document and the wave's plan.

**When a request's `due` passes** unanswered, the lead either applies its
`default` and tells both agents in a message, or, if the default would
change a contract or a design rule, alerts the owner.

## When someone else's file blocks you

1. Run `git merge --abort`, or stash your partial change.
2. Send a request with `blocking: true`, `due`, `default` and
   `escalate_to: "lead"`.
3. Set `task_state: blocked`; the lease pauses.
4. Write your handoff, push, and end the session.

When the request is answered, or its `due` passes and the lead applies the
default or escalates, the lead restarts you. A blocked agent never keeps a
session alive just to renew its lease.

**A file you need that nobody owns,** or a new file outside your globs, is
assigned by the lead, asked for by request.

**Files Godot rewrites.** The editor and importer rewrite `.import` files,
`.uid` files (468 and 564 of them are tracked), `project.godot` and resource
files. Before committing, run `git status` and restore generated changes
outside your files with `git checkout -- <path>`. If you need one, send a
request.

## When main is red, or a check fails outside your files

The lead owns keeping main green. If a check fails outside your files:

1. Run that check on main's head.
2. If it fails there too, send a request to the failing file's owner, copied
   to the lead, and set `blocked`.
3. If it passes on main, re-run it once on your branch. If it then passes,
   record a flaky-test request for `docs/progress/flaky.md` (the lead's
   file), and the lead files a fix task.

Never re-run until green without recording it.

## Running the checks

The pre-check runs on a separate worktree of the exact commit, with its log
outside the repository, so editing during the run cannot change what is
tested and the log cannot be committed by accident. `tools/run_checks.sh`
(backlog task BT-03) does all of it:

```bash
bash tools/run_checks.sh start            # checks HEAD; prints the log path
bash tools/run_checks.sh wait <sha>       # blocks until DONE, then prints the result
bash tools/run_checks.sh result <sha>     # PASS, FAIL or RUNNING, as JSON
bash tools/run_checks.sh record <sha> <agent>   # writes precheck into your status file
```

`start` adds a detached worktree at `/tmp/check-<sha>`, runs
`bash tools/check_all.sh` there under `nohup setsid`, and appends
`DONE exit=<code> sha=<sha>` to `/tmp/check-<sha>.log` when it ends. `wait`
and `result` remove the worktree once the run is done.

The candidate's code is not trusted (SEC-19). The run goes inside bwrap,
with everything read-only but its worktree and a private `/tmp`, no network,
no capabilities and none of the environment's secret-looking variables;
without bwrap, as the unprivileged user `CHECK_USER`; with neither, `start`
refuses and says why, unless `CHECK_UNSANDBOXED=1` is set (a warned, local
opt-out). Install bubblewrap on the machine that runs the lead.

- **A run passed** only if its log ends `DONE exit=0` **and** contains
  `All checks passed.` `check_all.sh` runs under `set -euo pipefail`, prints
  a `== <check> ==` heading before each step and stops at the first failure,
  so the failing step is the last heading in the log; `result` reports it
  as `summary`. A grep for `FAIL` or `error:` is only a helper: it misses
  `panicked` and `AssertionError`.
- **Background runs.** In this harness a job started with `nohup setsid`
  keeps running after the tool call ends (T17 checked it with `sleep`, and
  the integrator saw a `check_all.sh` run finish that way), but a container
  restart kills every running process. Run `wait` in the harness's
  background mode (or under its monitor), never as a foreground sleep. The
  `DONE` line is the only proof the run finished (reported, by the
  integrator and T17).
- `CHECK_CMD` overrides the command run, for the script's own tests only.

Start no full check after STOP_AT − (check minutes + 35); with today's
25-minute checks, that is STOP_AT − 60 minutes.

## The gate, step by step

1. **The maker asks.** At a commit where its scripted checks pass, it sets
   `gate_request: {"sha", "items"}`, commits and pushes.
2. **The lead launches.** At its next cycle the lead (the coordinator once
   BT-05 exists) starts fresh, read-only gate sessions on the judge's model,
   three samples per quality. The gate reads only the stills rendered from
   the item's shot list, the rubric, the references and the item's files,
   never the progress files, notes or the maker's reasoning. Planned:
   backlog task BT-04 renders the stills from the shot list at the requested
   commit; until it exists, the lead renders them with the shot scripts the
   wave's plan names, from the shot list AD keeps, not from stills the maker
   chose.
3. **The verdict.** The gate's final message is its verdict. The launcher
   writes it to `<verdicts>/<task_id>/<sha>.json` on main, where
   `<verdicts>` is the folder the wave's plan names (the UI wave:
   `docs/art/ui-quality/gate/verdicts/`), else `docs/progress/verdicts/`.
   One object per item and quality:

   ```json
   {"task_id": "P1-S1-pilot", "sha": "9f8e7d6", "item": "heist at 200% text", "quality": "Display type", "rubric_version": 1, "judge": "Fable 5.1", "samples": ["fail", "pass", "fail"], "result": "split", "critique": "Timer numerals lose their outline over the gold bar", "at": "2026-11-04T10:12:00Z"}
   ```

4. **Results.** Three passes pass; three fails fail. A **split**, where the
   wave's plan sets no rule of its own, takes three more samples: 4 or more
   fails out of 6 is a fail, otherwise it passes and goes on the next board
   (decision D-06). The UI wave's plan has adopted it (section 3.5 of
   `report.md`, request T17-R4, done), so splits do not swamp the owner. An
   **Unknown**
   goes to the exceptions queue; unanswered after 24 hours, it is treated as
   a split.
5. **Fails.** Each fail adds 1 to the task's `attempts`. The maker reads the
   critique in the verdict file and re-works. At `attempts` = 2 the maker
   writes its handoff and ends the session; the lead sets the task's `model`
   to Opus 5.5 and restarts it from the handoff.
6. **Appeals.** An author may appeal one verdict per item, by request to the
   exceptions queue. An appeal does not add to `attempts`.
7. **Carry-over.** A gate pass at `ready_sha` carries over to the candidate
   if the merge changed none of the task's `files` and none of the contract's
   files; otherwise the gate re-runs on the candidate before main moves.

**Before calibration: shadow mode.** Until a quality meets its calibration
target, the gate runs in shadow mode for it: it records verdicts, and every
item of that quality goes on a board **before** merging. A contract (the
kit) always gets a board before it merges, whatever the gate's state. The
golden set the calibration needs is a phase 0 task, labelled from
references, earlier waves' stills and outside examples (the UI wave: step 1
and O3 in sections 3.3 and 3.4 of `report.md`). In the UI wave, AD reviews
the boards and labels the golden set, and nothing waits for the owner
(section 3.4 of `report.md`, 30 October 2026).

**Capacity.** Gate calls count in the usage projection. If the judge's model
reaches its own usage limit, gated merges pause for the affected qualities,
the scripted checks keep running, and the owner is alerted (decision D-04).
The judge is never switched to a model that makers use.

## The merge queue

**Ready.** At `ready_sha` the agent's pre-check passed and the gate passed
every item in the task's `gate_items`. From UI phase 2, the branch holds
main as it stood when the pre-check started (the brief's "Before you mark
ready").

**The queue.**

1. The integrator takes ready tasks one at a time: critical path first, then
   in the order they became ready.
2. On a local candidate taken from main's head, it runs
   `git merge --no-ff <ready_sha>`.
3. On a textual conflict: abort, set the task to `resync`, and send the
   conflicting paths in a message. The agent merges main itself. Any path the
   agent does not own goes through "When someone else's file blocks you".
4. Otherwise run the full checks and the wave's guards on the candidate. If
   they pass, fast-forward main to the candidate. If they fail, set `resync`
   and attach the failure lines.
   **Reusing the builder's checks** (the owner's decision of 16 November
   2026, to speed up the queue). The lead skips its own `check_all.sh` when
   the task's `precheck` has `exit` 0 at `sha` equal to `ready_sha`, and the
   candidate differs from `ready_sha` only under `docs/progress/`:
   `git diff --quiet <ready_sha> <candidate> -- . ':(exclude)docs/progress'`.
   It skips the guard on the same terms when the builder's status or
   handoff records `ui guard: OK` at that `ready_sha`; otherwise it runs
   only the guard. It still runs `python3 tools/check_docs_consistency.py`
   on the candidate, records "checks reused from the pre-check at
   `<ready_sha>`" in the cycle's write-up, and runs `check_all.sh` on main
   after the merge under `nohup setsid`: if main fails, it reverts the merge
   at once and sets the task to `resync`. A batch, or a candidate whose
   diff with `ready_sha` touches anything outside `docs/progress/`, gets
   the full checks as before.
5. The gate's verdict carries over if the merge changed none of the task's
   `files` and none of the contract's files. Otherwise the gate re-runs on
   the candidate before main moves.

Main moves only to a candidate that passed on the integrator's side, or
whose checks were reused from the builder's pre-check under step 4.

**Main is protected by rule** (decision D-14). Platform branch protection is
not available from the agents' tools, so nothing configures it. Only the lead
or the coordinator moves main, through this queue, after `check_all.sh`
passes on the candidate (or on the same tree, by the builder's pre-check,
as step 4 allows); every other agent pushes only to its own branch.
GitHub runs `.github/workflows/checks.yml` on every push and pull request
(SEC-28): the server's and the simulation's tests, the documents check, the
ownership self-test and the runner's containment with a real bubblewrap. It
binds only once the owner turns on branch protection for main in the
repository's settings, requiring its `checks` status.

**The candidate's checks** also include an ownership check: every changed
path must match the task's `files` or an exception the lead granted:
`python3 tools/coord/owners.py diff <task_id> <main> <ready_sha>` (backlog
task BT-02). `python3 tools/coord/owners.py claims` checks that the tasks
being worked on at the same time have disjoint `files`. A task whose `files`
start a new folder under `tools/` has `README.md` as an exception, for that
folder's one line in the tools listing and nothing else, because
`tools/check_docs_consistency.py` fails until the folder is listed and the
line cannot land on main before the folder does.

**Bookkeeping commits.** Coordination data stays on main (decision D-01,
applied): no session is shown to push anywhere but its own branch, and
nothing in the repository configures a second branch (check V-04). The
lead's bookkeeping commits touch only `docs/progress/**`, so they never
invalidate a ready change: readiness no longer depends on main's head. If
main gained only bookkeeping commits while a candidate's checks ran, the
lead merges the candidate onto the new head and re-runs only the
documentation check before moving main.

**Batching.** As soon as two or more tasks are ready at once, the lead
merges 2–3 of them into one candidate, provided their claims are disjoint.
If the batch fails, each is re-checked alone. (Phase 2, from 12 November
2026: phase 1's median wait from ready to merged was 2.1 hours, and waiting
for the 2-hour mark before batching cost most of it.)

**After a merge** the lead sets `merged` and `merged_sha` in the backlog. The
agent's stale status copy on main is ignored (decision D-13: candidates do
not drop status files).

## The coordinator and the lead: who does what

| Duty | Done by |
|---|---|
| Lease expiry; copying claims; acknowledgement and request deadlines; checking changes against ownership; stall flags; building and checking candidates; fast-forwarding main | Coordinator script (planned: BT-01, which calls BT-02's `tools/coord/owners.py` and BT-03's `tools/run_checks.sh`), on a trigger |
| Planning; writing tasks; refilling the idle queue; digests; escalations; phase decisions | The lead (an LLM session) |

Until BT-01 exists, the lead runs one cycle every hour as a scheduled task
(decision D-02, approved): it runs while a wave has agents building, and is
armed when the next wave launches. The plan was every 30 minutes; scheduled
tasks cannot run more often than hourly, so the cycle is hourly. Each day the lead checks that the task
is still enabled and reads its last run. The wake-up ban
applies to idle building sessions, not to the lead's scheduled cycle.

What is known about the trigger (reported by the integrator from this
project): the repository had no CI then (it has `.github/workflows/checks.yml`
since SEC-28); scheduled tasks
are cron-style triggers on the owner's account, plus one-shot `send_later`
messages; a disabled scheduled task delivered nothing; and a one-shot message
counts as delivered only after checking that the target session is running.

**Sessions and scheduled tasks** (since 30 October 2026). A scheduled task
that starts a fresh session on each firing starts it with no repository
checked out: on 30 October every lead and watchdog run stopped at the step
that attached it and did nothing, and the restart tasks would have done the
same. So no scheduled task in the program starts a session itself. Every
session is created with the repository checked out at main and with its
model set explicitly (Opus 5.5, or the roster's model), and the scheduled
tasks fire into sessions that already exist:

- **The launcher**, one long-lived session, takes the hourly scheduled task.
  Each firing it reads `status/lead.json` on main and checks the previous
  cycle's session; if that is still working it skips this hour. Otherwise
  it creates a fresh session for one lead cycle.
- **The quiet-hour skip.** Each lead cycle first runs
  `python3 tools/coord/cycle_needed.py`. On exit 3 nothing changed since
  the last cycle recorded what it saw (no branch moved, nothing ready or
  startable, no message, request, lease or late status waits, and the
  heartbeat is not due): the cycle writes nothing, pushes nothing and ends
  its turn. On any other exit, a crash included, it runs in full. The state
  the skip reads is `seen` in `status/lead.json`, never a session. A
  launcher may run the same check before it creates the session; its
  prompt can be changed only in its own conversation.
- **The lead's cycle** creates every agent session the same way: a fresh
  session per task, with the agent's prompt and the roster's model, on
  start and on every restart in step 6. It records each session in
  `lead.md`, "The program's scheduled tasks and sessions".
- **The watchdog**, a second long-lived session, takes the two-hourly
  scheduled task. It reads `status/lead.json` and the hourly task's last
  run; if the lead is stale, it creates one lead cycle session itself, so it
  does not depend on the launcher, and writes the alert.

A failed session is replaced, never resumed in place; its work is on its
branch and in its handoff.

**One cycle**, in order:

1. `git fetch origin`; save the branch heads
   (`python3 tools/coord/cycle_needed.py heads` to a file outside the
   repository); read every status file on the roster's branches.
2. Record `seen_at` for each new status push; expire lapsed leases (set
   `open`, record `prior_branch` and `prior_sha` if the old branch has work);
   copy each agent's `task_state` into its task and its lease into `claim`;
   assign the next tasks.
3. Copy open requests into `requests.md`; apply defaults for requests past
   `due`; check acknowledgements against `ack_by`.
4. Launch the gate for each `gate_request`; write the verdicts.
5. Take the merge queue as far as it goes in the cycle.
6. Restart every agent whose `expected_next_update_by` has passed, whose
   task left `blocked` or went to `resync`, or whose message went
   unacknowledged: a fresh session with the same prompt, created with the
   repository checked out and the roster's model (above), which reads its
   handoff. `send_later` is an optimisation, never the recovery plan.
7. Raise the alerts below; keep the queue full ("Keeping the queue full");
   write `status/lead.json` and the lead's handoff; run
   `python3 tools/coord/archive.py` (merged tasks to
   `backlog-archive.json`, old "Now" entries to `lead-archive.md`) and
   `python3 tools/coord/cycle_needed.py record <heads file>`, last, so
   `seen` holds what this cycle left; push.

**The merge lock.** A cycle can run into the next one, because the
candidate's checks take about 25 minutes and a resync or a red run adds a
second. So before step 4 the lead reads
`merging` in `status/lead.json` on main:
`{"candidate_sha", "task_ids", "started_at", "expires_at"}`, with
`expires_at` = `started_at` + 2 × the check minutes + 10 (60 minutes today).
If it is set and has not expired, another cycle is merging: this cycle skips
steps 4 and 5, does the bookkeeping steps and pushes only `docs/progress/**`.
Otherwise the lead writes its own `merging`, pushes it before starting the
checks, and clears it (`null`) when main has moved or the candidate failed.
An expired lock means that cycle died: the lead clears it, notes it in the
digest, and starts the merge again from main's head. The merging cycle
treats the other cycle's bookkeeping commits as the queue already allows: it
merges the candidate onto the new head and re-runs only the documentation
check.

**Claims** (later waves). "Earlier" means the earlier push as seen by the
coordinator. On a tie, the lower agent id wins (string order: `AD` before
`S1`).

**Lapsed leases.** When a lease lapses, the lead records `prior_branch` and
`prior_sha` on the task. The new claimant merges `prior_sha` before starting.
The old claimant must not push further work for that task.

**The lead's own status and failover.** Each cycle is a fresh session,
created by the launcher, that starts from `status/lead.json` and the lead's handoff in
`docs/progress/lead.md`, so no state lives only in one session.
`status/lead.json` holds `agent` (`"lead"`), `updated_at`,
`expected_next_update_by` (`updated_at` + 3 hours: a quiet hour's cycle
ends at once, and the heartbeat runs a full cycle 20 minutes before this),
`cycle` (a count), `seen` (what the cycle saw, for the quiet-hour skip),
`merging` (the lock above, or `null`), `last_merged` (`{"task_id", "sha"}`),
`alerts` (open alert ids) and `next_step`. A second scheduled task, the
**watchdog**, runs every two hours in its own session: if
`expected_next_update_by` has passed, it notifies the owner's phone, starts
one lead cycle session itself, and records the alert in the owner inbox. This closes
finding G-67 in T17's report except when both scheduled tasks fail together;
the owner's daily look at `status/lead.json` covers that.

**Runaway sessions.** No session runs past 2 × its task's estimate without a
handoff. The lead stops any session whose `progress_marker` is unchanged for
2 hours.

## Alerts

The lead writes each alert to `docs/progress/owner-inbox.md` and sends the
owner a direct message (decision D-03). It alerts at once for:

- a stall past `expected_next_update_by`, after one restart has failed;
- a busy-stall flag (`progress_marker` unchanged for 2 hours);
- a blocking request past its `due` whose default needs the owner;
- main red for more than 30 minutes;
- a task `blocked` for more than 2 hours;
- the oldest ready task waiting more than 2 hours;
- the gate unavailable;
- the lead's own status stale;
- a disagreement between the gate and an author that an appeal does not
  settle;
- usage below the reserve.

## Waves: start, metrics and close

**Phase 0 checklist.** Before any builder starts:

- the roster and its schedule;
- the environment script (planned: backlog task BT-09; until then the
  brief's install lines);
- the golden set task, and who labels it (the UI wave: AD at O3);
- the contracts to freeze, each with `version` and `consumers`;
- a backlog with `gate_items` and `model` on every task;
- the baseline metrics below;
- a test alert through the owner channel, acknowledged by the owner;
- the lead's scheduled cycle, armed (decision D-02).

**Phase exit criteria** are commands, gate classes or owner sign-offs. The
lead records them and does not judge them.

**Metrics,** in every digest (by hand until BT-07):

| Metric | Review threshold (inference) |
|---|---|
| Merge lead time, ready to merged | over 2 h on average |
| Oldest ready task's wait | over 2 h |
| Resync rate | over 1 in 3 candidates |
| Catch rate and false-fail rate, per quality | under the plan's targets (UI wave: catch 80%, false fails at most 20%) |
| Split verdicts per day | over 15 |
| Stalls | more than 1 a day |
| Blocked hours | over 4 a day across the team |
| Usage per merged task | 1.5 × the phase 1 figure |

At mid-wave, any metric past its threshold triggers a review of this
protocol (planned: BT-07 reports them). Within a phase, too: when a KPI in
the progress report rates worse, or a candidate fails on its first attempt,
the lead finds the cause the same day, sends the rule as a message to the
agent that can act on it, and adds a row to the program's lessons table for
the current phase. Lessons are not held until the wave closes.

**Wave close.** New ready changes are accepted until STOP_AT − 2 hours. The
final blind audit runs. `parked` tasks are listed in the backlog with their
branches. A short review compares the metrics with the targets and updates
the lessons table in the program.

## Changing a frozen contract

A contract's spec opens with `version` and `consumers`. Changing it after the
freeze takes four steps:

1. A request.
2. The lead's approval.
3. A message to every consumer, each acknowledged in `acks`.
4. A version bump.

Anything removed stays, marked deprecated, until the next phase.

## Worked examples

Each is a case that broke under the earlier rules, run under these.

### A. Four changes ready, then the lead writes the backlog

1. S1, S2, S3 and S4 mark `ready` at commits that contain M0, main's head.
   Each writes its handoff, pushes, sets `agent_state: waiting` and ends its
   session.
2. The lead's cycle builds candidate C1 = M0 + S1, runs the full checks
   (25 minutes), and fast-forwards main to C1. S1 is `merged`.
3. The lead commits a backlog update on main (M2). It touches only
   `docs/progress/**`; no ready change is invalidated.
4. Candidate C2 = M2 + S2 merges cleanly, passes and lands; then S3. Nobody
   is waiting in a session and nobody re-checks.
5. S4's merge has a textual conflict in a file S4 owns: the lead sets
   `resync` and messages the paths. At its next cycle it restarts S4 from
   its handoff; S4 merges main, re-runs its pre-check, and marks ready.
6. If the queue had grown past 2 hours, the lead would batch S3 and S4 into
   one candidate.

**Ends:** S1–S3 merged in about 75 minutes of checks, S4 merged after one
resync. No step depends on an agent noticing anything.

### B. A container restarts at STOP_AT − 40 minutes, during the checks

1. At STOP_AT − 65 the agent starts its pre-check on a separate worktree of
   `ready_sha`, sets `long_run` with `expected_end` at STOP_AT − 40, and
   pushes. Editing afterwards cannot change the tested tree.
2. At STOP_AT − 40 a restart kills the run and the session.
3. The lead's next cycle (within the hour) finds `expected_end` passed
   with no new status and restarts the agent from its handoff.
4. The fresh session runs the setup, finds the log without its `DONE` line,
   and checks the time: a 25-minute run cannot start after STOP_AT − 60. It
   does not start one. The re-run belongs to the same task, not a new one.
5. It sets `task_state: parked`, `agent_state: stopped`, and writes "pre-check
   of `<sha>` lost to a restart; re-run first" as the handoff's next step.

**Ends:** parked, with the next step written down. The wave close lists the
task; the next session re-runs the pre-check and marks it ready. Had the
restart come earlier, step 4 would have re-run the check at once.

### C. S1 needs a kit change and K1 has stopped

1. S1 writes request S1-R4 to K1 with `blocking: true`, `due` 6 hours on,
   a `default` ("build it from K12 plus a label; file the variant as a phase
   3 task") and `escalate_to: "lead"`. It aborts its partial change, sets
   `blocked`, writes its handoff, pushes and ends the session.
2. The lead's cycle copies S1-R4 into `requests.md` under K1. K1's
   `agent_state` is `stopped`, so the lead starts a K1 session if a slot and
   usage allow; K1 reads `requests.md` first and answers in its `answers`.
3. If no K1 session can run before `due`, the lead applies the default and
   messages S1 and K1. If the default would change the frozen contract, the
   lead alerts the owner instead.
4. Either way, the lead restarts S1 from its handoff.

**Ends:** answered by K1, or defaulted, or the owner alerted, by `due`. A task
`blocked` for more than 2 hours raises an alert of its own on the way.

### D. Contract work is ready before the gate is calibrated

1. Phase 0 has two tasks in parallel: the golden set (AD, labelled by AD
   at O3, its held-out third again by a blind second session) and the kit
   contract (K1).
2. The contract's `gate_items` is empty. K1 marks it ready when its
   pre-check passes, and the lead merges it like any task, so the work that
   builds on it (the bake) can start. It takes effect when AD approves it
   with the board at O2, whose `deps` include it; nothing consumes it before
   phase 1. A redirect at O2 becomes a new contract task for K1.
3. Phase 1 starts once the judge meets its target on the held-out third.
   Each quality that misses stays in shadow mode, so its items go on AD's
   board before they merge, until it meets the target or becomes
   owner-checked (checked by AD on the boards).

**Ends:** the contract takes effect on AD's approval; no item merges on an
uncalibrated verdict, and nothing waits forever for one.

## Roles against the rules

Every rule applies to every role as below; the brief has a section per role.

| Rule | Maker | Contract owner | Lead | Gate | Specialist |
|---|---|---|---|---|---|
| 1 Your branch only | ✓ | ✓ | ✓ moves main by this protocol | ✓ pushes nothing | ✓ |
| 2 Your files only | ✓ | ✓ contract changes by the four steps | ✓ hotspot edits are its own backlog tasks | ✓ reads only | ✓ only its task's files |
| 6–7 Tests and green | ✓ | ✓ | ✓ on every candidate | ✓ not applicable: changes nothing | ✓ |
| 8 Own assessment | ✓ the gate and checks decide | ✓ the sign-off decides (AD's in the UI wave) | ✓ approves no build as "good" | ✓ judges only others' work | ✓ |
| Taking work | ✓ takes the task the lead assigned | ✓ takes its assigned tasks like a maker | ✓ assigns, takes none | ✓ launched per request | ✓ takes its one assigned task |
| One task per session | ✓ | ✓ | ✓ one cycle per session | ✓ one quality per run | ✓ |
| Status every 45 min | ✓ | ✓ | ✓ every cycle, in `status/lead.json` | ✓ the launcher records each run | ✓ |
| Stop protocol | ✓ | ✓ | ✓ its own, below the others | ✓ runs end on their own | ✓ |
