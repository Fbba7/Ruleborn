# The agent program: how the team is organised and run

Most of this repository was written by agents working in parallel, each on
one *track*: a piece of work with its own branch, its own files and its own
notes. This page is the operating model for every wave from the UI wave on:
who does what, how work is split and claimed, how agents talk, how work
reaches main, how quality is checked, what the owner is asked to do, and
what to do when something breaks. What every agent reads first is the short
brief, [agent-brief.md](agent-brief.md); this page is the reasoning and the
detail behind it.

It rests on the research in
[`docs/research/agent-team-operating-model.md`](../research/agent-team-operating-model.md)
and on what went wrong in waves 4 and 5 (the last section). The research
labels its evidence as measured, reported, vendor guidance, opinion or
inference; where a rule here rests mostly on opinion or inference, it says
so. The quality bar, the look and the shot rules for the 3D and interface
tracks are in [`docs/art/3d-program.md`](../art/3d-program.md); the UI wave's
own plan is [`docs/art/ui-quality/report.md`](../art/ui-quality/report.md)
section 3.

## The model on one page

- **One lead, a few builders, an independent gate.** A lead plans, keeps the
  backlog and runs the merge queue; it does not build or judge. At most five
  building sessions run at once (three if usage runs hot). Nobody grades
  their own work.
- **Contracts first.** Whatever several agents build against (a kit, an API,
  a schema, a golden set of approved examples) is written, approved and
  frozen before they build in parallel.
- **One owner per file.** Shared files included. A change in someone else's
  file is a request, never an edit.
- **Work is pulled from a backlog** with time-limited claims, one task per
  session, and an idle queue for anyone who finishes early.
- **Truth lives in the repository,** not in conversations: progress files,
  status files, the backlog, handoffs. A message counts only when its
  recipient acknowledges it in a commit.
- **Merges are mechanical.** One change at a time, as soon as it is ready;
  main only moves to a commit whose checks passed on exactly that tree.
- **The owner reviews plans, labels and samples,** not streams of items.
  Every question has a default and a deadline.
- **Sessions are disposable.** A fresh session at every task boundary, with a
  handoff; small contexts; no model switch inside a session.
- **Deadlines are absolute UTC times,** and stopping follows a protocol.

## Roles

| Role | What it does | What it never does | Model |
|---|---|---|---|
| **Lead (integrator)** | Writes the wave's plan and backlog; seeds and refills the idle queue; runs the merge queue; watches status files for stalls; keeps acknowledgements; writes the owner's digests; owns every file no track owns, and the hotspot files (`project.godot`, autoload registries, export presets) | Builds features; judges quality; resolves another agent's conflicts by hand; approves its own integrated build as "good" (that would be self-assessment too) | Opus 5.5, medium effort; a fresh session per integration cycle |
| **Gate (independent reviewer)** | Checks work against agreed pass and fail criteria with read-only tools (`Read`, `Grep`, `Glob`), in short isolated runs, and writes verdicts. Calibrated against the owner's labels before it may block anything | Edits the work it checks; sees the author's reasoning; reports a score it was not asked for | A different model from the agents it checks (Fable 5.1 in the UI wave, if its calibration holds) |
| **Makers, by vertical slice** | Each owns one slice end to end (a screen, a feature, a subsystem) and its tests, builds against the frozen contracts, resolves its own conflicts, and marks work ready only when the scripted checks and the gate pass on its branch | Edits a contract or another slice's files; counts its own assessment as a check | Sonnet 5.5 for spec-following work against a frozen contract; Opus 5.5 where the work is judgement (art, design, architecture) |
| **Contract owner (kit owner)** | Owns a shared contract and the code behind it (in the UI wave, K1 owns the UI kit, its tokens and theme); freezes it before the slices build; answers requests, reuse first | Lets a slice change the contract; changes it after the freeze without the lead's approval and every consumer's acknowledgement | Opus 5.5 to design the contract; Sonnet 5.5 to maintain it once frozen |
| **Specialists, on demand** | A short session for one narrow job: a performance pass, a localisation overflow sweep, a security check, a design critique | Stays on after the job | Chosen per job |
| **The owner** | Decides rules, prices and plans; labels the golden set; reviews boards, exceptions and blind audits | Approves items one by one | |

Past about five to eight builders, one lead should hand subsystems to
sub-leads. No study measures an LLM lead's span of control, so that number is
inference.

## Tracks

Each wave's track table is the authority for what each track owns, file by
file: [`docs/art/3d-program.md`](../art/3d-program.md#tracks) for the 3D and
interface tracks. This table says where each track's notes, progress and
stills are.

| Track | Branch | Notes (what was done, "Stopped here") | Progress | Stills |
|---|---|---|---|---|
| T1 Characters | `claude/3d-characters`, earlier `claude/3d-characters-2` | [`t1-characters.md`](../art/tracks/t1-characters.md), then [`t1b-`](../art/tracks/t1b-characters.md) and [`t1c-characters.md`](../art/tracks/t1c-characters.md) (sessions 3 to 5; the latest) | [`T1.md`](../progress/T1.md) | `docs/art/shots/t1-characters/`, `t1b/`, `t1c/`, `t1d/` (wave 5) |
| T2 Look | `claude/3d-look` | [`look.md`](../art/tracks/look.md) | none (stopped after wave 3) | `docs/art/shots/look/` |
| T3 Kit | `claude/3d-kit` | [`kit.md`](../art/tracks/kit.md) | [`T3.md`](../progress/T3.md) | `docs/art/shots/kit/` |
| T4 Universe | `claude/3d-universe` | [`universe.md`](../art/tracks/universe.md) | [`T4.md`](../progress/T4.md) | `docs/art/shots/universe/` |
| T5 Heist | `claude/3d-screens` | [`t5.md`](../art/tracks/t5.md) | [`T5.md`](../progress/T5.md) | `docs/art/shots/t5/` |
| T6 Realm screens | `claude/3d-screens-world` | [`T6.md`](../art/tracks/T6.md) | [`T6.md`](../progress/T6.md) | `docs/art/shots/T6/` |
| T7 Character screens | `claude/3d-character-screens` | [`t7.md`](../art/tracks/t7.md) | [`T7.md`](../progress/T7.md) | `docs/art/shots/t7/` |
| T8 Law effects (retired after wave 2; its files passed to T5) | `claude/3d-law-fx` | [`t8.md`](../art/tracks/t8.md) | none | `docs/art/shots/t8/` |
| T9 UI kit | `claude/ui-kit` | [`ui-kit.md`](../art/tracks/ui-kit.md) | [`T9.md`](../progress/T9.md) | `docs/art/shots/ui-kit/` |
| T10 Screens | `claude/ui-screens` | [`ui-screens.md`](../art/tracks/ui-screens.md) | [`T10.md`](../progress/T10.md) | `docs/art/shots/ui-screens/` |
| T11 Sign-in | `claude/auth` | [`docs/security/auth.md`](../security/auth.md) | [`T11.md`](../progress/T11.md) | `docs/art/shots/auth/` |
| T12 Security review | `claude/security-review` | [`docs/security/review.md`](../security/review.md) | [`T12.md`](../progress/T12.md) | none |
| T13 Database cost | `claude/db-cost` | [`docs/server/db-cost.md`](../server/db-cost.md) | [`T13.md`](../progress/T13.md) | none |
| T14 UI quality research | `claude/ui-research` | [`docs/art/ui-quality/report.md`](../art/ui-quality/report.md) | [`T14.md`](../progress/T14.md) | `docs/art/ui-quality/` |
| T15 Documentation | `claude/docs` | [`docs/DOCS-CHANGES.md`](../DOCS-CHANGES.md) | [`T15.md`](../progress/T15.md) | none |
| T16 UI plan review | `claude/ui-plan` | [`plan-review.md`](../art/ui-quality/plan-review.md) rounds 1–2 | [`T16.md`](../progress/T16.md) | `docs/art/ui-quality/` |
| T17 Plan v3 and the operating model | `claude/plan-v3` | [`plan-review.md`](../art/ui-quality/plan-review.md) round 3; this page; [agent-brief.md](agent-brief.md) | [`T17.md`](../progress/T17.md) | none |
| UI wave (AD, Gate, AIA, AIA-2, K1, S1–S3) | `claude/ui-*` | `docs/art/ui-quality/report.md` section 3.1 | `docs/progress/<agent>.md` | `docs/art/shots/<track>/` |
| Lead (integrator) | `claude/videogame-project-analysis-ewkkk2` | the audit register, the roadmap, the backlog | the roadmap page | none |

Two things to know when reading the older notes:

- **File names are mixed.** Some notes are named by track number (`T6.md`,
  `t5.md`), some by subject (`kit.md`, `universe.md`). They are kept as they
  are because other notes, commits and register items link to them; the table
  above is the map.
- **Some ownership claims overlap.** `client/tests/shots/screen_*.gd` is
  claimed by T6, T7 and T10 in their notes, and T8's notes still claim the
  law, Weaving and Harmony screens that the program table gives to T10. The
  program table is the later statement. From the UI wave on, an overlap is a
  bug in the plan: the lead names one owner.

## How work is split, claimed and owned

**Split by slice, behind contracts.** Work is divided into units that can be
tested on their own, each with an oracle (a test, a check, a golden
reference). Slices that cut across layers work once the interfaces between
them are committed files; before that, each agent invents its own
assumptions. So every wave starts with a phase that writes and freezes its
contracts, and only then runs slices in parallel. Phases have entry and exit
criteria, written in the wave's plan, which the lead checks and records.

**One owner per file.** The wave's track table gives every file one owner.
Hotspot files (project settings, autoload registries, themes and tokens,
lockfiles, schemas, route tables, string tables) are named explicitly, each
with one owner, or the lead. An agent that needs a change in a file it does
not own writes a request (below); it never edits the file.

**The backlog.** The lead keeps `docs/progress/backlog.json` on main: every
task of the wave, its owner role, the files it may touch, what it waits for,
how it is checked, its estimate, its tier, and its state. JSON, not Markdown,
because agents rewrite Markdown more readily. Only the lead writes it.
[`backlog.example.json`](../progress/backlog.example.json) shows the format
with tasks from the UI wave.

| Field | Meaning |
|---|---|
| `id`, `title`, `phase`, `role` | What the task is and who may take it |
| `files` | The paths the task may change; all are the role's own |
| `deps` | Task ids that must be `merged` first |
| `done_when` | The checks that must pass, as commands or gate classes |
| `estimate_h`, `tier` | Hours; the usage tier (1 stops last, 3 first) |
| `state` | `open`, `claimed`, `ready`, `resync`, `merged`, `blocked` |
| `claim` | `agent`, `branch`, `claimed_at`, `lease_until`, or `null` |
| `idle_queue` | Low-coupling tasks for anyone who finishes early |
| `messages` | The lead's instructions, each with an id and an acknowledgement deadline |

**Claiming.** Agents push only to their own branches, so a claim is made in
the agent's own status file and read by everyone else from their branches:

1. `git fetch origin`, read main's backlog, and pick the first `open` task
   your role may take whose `deps` are all `merged`; if none, take one from
   the idle queue; if none, stop (see the stop protocol).
2. Look for a competing claim: read the other agents' status files from
   their branches (`git show origin/<branch>:docs/progress/status/<agent>.json`).
3. Write your status file with the task's id, `state: "claimed"`,
   `claimed_at` and `lease_until` three hours later. Commit and push.
4. Check again. If another agent claimed the same task earlier, yield it
   (write `state: "open"` for it) and pick again.
5. The lead copies claims into the backlog at each cycle.

**Leases.** A claim lasts three hours and is renewed by any status commit;
agents commit their status at least every 45 minutes while working. When
`lease_until` passes with no commit, the lead marks the task `open` again and
says so in the digest; the old claimant must claim again before going on.
Leases exist because agents that die while holding a lock otherwise stall
everyone (reported). Three hours and 45 minutes are the research's suggested
defaults, not measured values.

**One task per session.** An agent takes one task, finishes it or hands it
off, and starts the next in a fresh session.

**The idle queue.** An agent that finishes early takes a task from the idle
queue (tests, asset-import checks, overflow sweeps in long languages,
documentation of a contract) or stops. Idle capacity is never a reason to
start more sessions or to raise the cap. The lead refills the queue at every
cycle.

## Communication through files

Everything that matters is a file in the repository. Conversations are lost
on restart; summaries passed from agent to agent lose detail.

| File | Who writes it | What it holds |
|---|---|---|
| `docs/progress/<agent>.md` | The agent, on its branch | The six-line header, the deliverables table, and a **Handoff** section rewritten at every task boundary (below) |
| `docs/progress/status/<agent>.json` | The agent, on its branch | Its machine-readable state: what the lead reads to find stalls, claims and acknowledgements (below) |
| `docs/progress/backlog.json` | The lead, on main | Tasks, claims, the idle queue, messages |
| `docs/progress/requests.md` | The lead, on main | Every open request between agents, copied from status files at each cycle, with its answer when there is one |
| A track's notes, `docs/art/tracks/<track>.md` or the wave's equivalent | The agent | What was done, the evidence, what is still worse, "Stopped here" |
| The lead's hourly status and the owner's digest | The lead | Links to the backlog and status files, not paraphrases of them |

**The status file.** One JSON object, rewritten on every status commit:

```json
{
  "agent": "S2",
  "branch": "claude/ui-screens-home",
  "task_id": "P2-S2-home",
  "state": "working",
  "claimed_at": "2026-11-03T09:05:00Z",
  "lease_until": "2026-11-03T12:40:00Z",
  "updated_at": "2026-11-03T09:40:00Z",
  "expected_next_update_by": "2026-11-03T10:25:00Z",
  "last_green_sha": "1a2b3c4",
  "ready_sha": null,
  "stop_at": "2026-11-03T21:00:00Z",
  "next_step": "Move the currency pills onto K23; then the 200% text shot",
  "acks": ["M7"],
  "requests": [
    {"id": "S2-R1", "to": "K1", "ask": "A currency pill with a storage bar at 200% text", "files": ["client/ui/kit_status.gd"]}
  ]
}
```

`state` is one of `claimed`, `working`, `ready`, `resync`, `blocked`,
`stopped`, `done`. An agent is **stalled** only when
`expected_next_update_by` has passed with no commit, which tells a stall from
a long test run.

**Requests.** An agent that needs something from another writes it in its
status file's `requests`. The addressee answers in its own files (the kit
owner, for instance, in the kit spec's request log) and the lead keeps
`docs/progress/requests.md` current. Answering is part of the addressee's
work, not an interruption: a request is checked at every checkpoint.

**Delivery and acknowledgement.** An instruction counts as delivered only when
its recipient acknowledges it: the lead writes it as a message with an id in
the backlog (and may also send it to the session directly), and the recipient
adds the id to `acks` in its next status commit. If no acknowledgement comes
by the message's deadline (the recipient's next `expected_next_update_by`),
the lead checks that the session is running and, for a scheduled message,
that the scheduled task is enabled and what its run actually did; it resends
once directly; then it tells the owner. A scheduled run reported as
"Succeeded" says how the session ended, not that the work was done (vendor
documentation).

## Merging: the queue and the guards

**When a change is ready.** Its branch contains main's current head; the full
checks (`bash tools/check_all.sh`, plus any wave-specific guard such as the
UI wave's `tools/ui_bake/guard.sh`) passed on exactly that commit, shown by a
log that ends `DONE exit=0`; and the gate passed every item it carries. The
agent writes `state: "ready"` and `ready_sha`.

**The queue.**

1. The lead takes ready changes one at a time, in the order they became
   ready, with the wave's critical path first. It does not wait for the hour.
2. If `ready_sha` contains main's head, the lead fast-forwards main to it. The
   tree that passed is exactly the tree that lands.
3. If main has moved, the lead marks the task `resync`. The agent merges main
   into its own branch (the repository's convention; rebasing a pushed branch
   would need a force push), resolves its own conflicts, re-runs the checks
   and marks ready again. A conflict in a file the agent does not own is a
   request to that file's owner, never an edit.
4. **The hourly cycle is the longest wait.** If an agent has stopped with a
   ready change, the lead merges it with main on a temporary branch, runs the
   full checks there, and fast-forwards main only if they pass. If that merge
   conflicts, the lead resolves nothing: the task waits for its owner.

Until wave 5 the integrator instead merged every green head into a fresh
integration branch each hour (merge commits titled
`Merge remote-tracking branch 'origin/claude/<track>' into intNN`), ran the
checks and moved main to it; tracks called a merged round a *deploy*. A
single agent integrating everything becomes the bottleneck, and the agent
that resolves a conflict should be the one that holds the context (reported).

**Guards against semantic conflicts.** Separate branches stop textual
collisions, not changes that pass alone and fail together; that is how a
merge silently undid the database optimisation. Each guard encodes an intent,
so a merge that breaks the intent fails:

- `node server/load.mjs --check`: the database's reads and writes per player
  may not rise (in check_all);
- the UI's guards: draw calls under §21.3's 150 and no higher than recorded,
  texture memory, contrast in both modes, the kit's chrome count, bakes that
  match their sources (the UI wave's plan, section 3.8);
- the documentation check, the content checks and the generated files' checks
  (see [checks.md](checks.md)).

A new optimisation or rule that a later merge could undo gets a guard in the
same change, and a short note of why it exists ("index X serves query Y;
guarded by test Z") beside the code or in its decision note.

## The quality gate and its calibration

Agents overrate their own work by roughly two to four times (measured); this
project's tracks rated themselves 80–99% done against an audit of about 30%.
So no agent's own assessment counts towards any check. It is recorded as a
claim with evidence, and progress is reported as the count of items passing
the gate.

Every wave whose quality is a matter of judgement has an independent gate,
built and calibrated before it may block anything:

1. **Scripted checks first.** Whatever can be measured is a script: budgets,
   sizes, contrast, text scales, coverage, timings.
2. **Narrow, isolated judge calls.** One call per quality, pass or fail (or
   "Unknown"), compared against reference examples the owner has labelled,
   never an absolute score on a scale. Each call is sampled about three times;
   only a unanimous fail blocks, and a split goes to the owner.
3. **A different model from the makers,** with read-only tools and no access
   to the makers' reasoning. Every model available here comes from one
   vendor, so the owner's labels are the only fully independent signal.
4. **Calibration.** The owner labels a golden set of 30–60 items pass or fail,
   with a one-line critique. The judge is measured on a held-out third by its
   **catch rate**: the share of the owner's fails it fails. Raw agreement is
   not used, because a judge that passes everything agrees with a mostly
   passing set. The wave's plan sets the target and what happens when it is
   missed (for the UI wave: at least 80%, then prompt revisions, the other
   model, and finally the owner checks that quality).
5. **Blind audits.** Weekly, and at the wave's end, the owner labels a random
   sample of items the gate passed, mixed with a few it failed, without seeing
   the verdicts. A miss pauses default merges for that quality until the judge
   is re-validated.
6. **Recalibration** after a change of judge model, a rubric edit, or a new
   kind of item. The rubric's versions are logged, since the owner's bar moves
   as they see work.
7. **What a still cannot show** (motion, feel, flow) goes to the owner, not to
   a judge of screenshots.

The UI wave's gate is specified in
[`docs/art/ui-quality/report.md`](../art/ui-quality/report.md) section 3.5.

## The owner's cadence

The owner's time goes where review pays: plans and contracts, the labels
every gate enforces, and samples. Per-item approval decays into
rubber-stamping (the research's evidence is secondary but consistent).

| When | What the owner does | About |
|---|---|---|
| Before a wave | Approves the plan, its hours and its defaults; approves any setting changes | 20 min |
| End of the contract phase | Approves the frozen contracts | 15 min |
| Once per kind of judged work | Labels the golden set | 60–90 min |
| Per family of work | A short board of 5–10 items beside their references. **Merges after 24 hours unless the owner objects** | 15 min each |
| Daily | The exceptions queue: split verdicts, "Unknown", what only the owner can judge | 10–20 min |
| Weekly and at wave end | A blind audit of the gate's passes | 15–20 min |
| At each five-hour usage window | Reads the lead's digest (nothing to approve) | 2 min |

Every question to the owner has a default and a time by which it is needed,
and the wave goes on around an unanswered one. The lead alerts the owner at
once only for a stall past `expected_next_update_by`, a disagreement between
the gate and an author that the rules do not settle, or usage below the
reserve. Decisions are listed in each progress file's "Owner decision needed"
line; larger ones (anything in the design) go through the decision brief
([design-tools.md](design-tools.md)).

## Concurrency and usage limits

All sessions, subagents, scheduled tasks and chats on the account draw on one
five-hour window and one weekly limit; Fable 5.1 is reported to have a
weekly limit of its own on Max plans. Anthropic publishes no token figure for
either. So:

1. **A cap.** At most five building sessions at once, plus the lead and short
   gate runs; three if usage runs hot.
2. **Measure early.** After the first phase, the lead reads `/usage`, works
   out the share of the weekly limit one agent-hour on each model used, and
   projects the rest of the wave plus a 15–20% reserve for the lead and
   recovery. If it does not fit, the owner chooses: wait for the weekly
   reset, enable usage credits, or cut scope (the wave's plan names the
   default).
3. **Tiers.** Every task has a tier. As headroom shrinks, tier 3 (the idle
   queue, later batches, polish) checkpoints and stops first; tier 1 (the
   lead, contract owners, the gate, the critical path) stops last.
4. **Stagger** heavy exploration, so several sessions do not start large
   reads in the same half hour.
5. **Pause-safe.** Every agent commits and pushes after each verified step, so
   a limit pause costs time but no work. An agent paused by a limit schedules
   its own resume (`send_later`) before it stops, if it can.
6. **Nothing that wakes idle sessions** for nothing: no `/loop`, no
   check-ins, no messages that make a sleeping session re-read its whole
   context.

## Model routing

A model is chosen per session, at its start, and never switched inside it:
each model has its own cache, so a switch re-reads the whole context at full
price. Fast mode, adding or removing MCP servers, and `opusplan` break the
cache the same way.

| Work | Model | Why |
|---|---|---|
| The lead | Opus 5.5, medium effort | Triage and planning; the merges themselves are mechanical |
| Design, art, contracts, architecture | Opus 5.5 | Sonnet 5.5 is reported to trail on open-ended work that needs sustained judgement |
| Spec-following work against a frozen contract, which a gate checks | Sonnet 5.5, medium effort | Half the price; benchmarks reported at launch put it level with or ahead of Opus 5.5 on terminal coding work (secondary) |
| The gate's judge | A different model from the makers: Fable 5.1 by default, kept only if it meets its catch-rate target | Models prefer their own output (measured) |
| Searches and log triage | Haiku 5.5 subagents, under 100k tokens | Retrieval is cheap and low-risk; never used for verdicts |

**Escalation.** A piece of Sonnet work that fails the gate twice moves to a
fresh Opus 5.5 session, which starts from the handoff on the same branch. A
cheap model running longer is not a free substitute for a stronger one
(reported), so the escalation is made early, not after a third round.

## Sessions and handoffs

Every request resends the whole conversation. A session at 350k tokens costs
about 3.5 times as much per tool call as one at 100k, and recalls less
(arithmetic at list prices; plan units are unpublished). So:

- **A fresh session at every task boundary** (a task merged, a phase
  ended). Before ending, the agent rewrites its handoff. Continue or compact
  only when the next step depends on state that is not written down, such as
  a live debugging hypothesis.
- **The handoff** is a section of the agent's progress file, rewritten, not
  appended to:

  ```markdown
  ## Handoff
  - Last verified commit: 1a2b3c4 (check_all green, 2026-11-03T14:10Z)
  - Done: ...
  - Half done: ... (on the branch, not ready)
  - Open hypotheses: ...
  - Next step: ...
  ```

- **A new session** reads the brief, its handoff, the backlog and `git log`,
  then runs the quick checks before new work, so it catches whatever the last
  session broke.
- **Compaction at 200k tokens,** not at the 967k at which 1M-context models
  compact in cloud sessions (`CLAUDE_CODE_AUTO_COMPACT_WINDOW`, proposed for
  the UI wave in its plan, section 3.9).
- **Keep output out of the context.** Long runs write to a log file; read the
  failures and the last lines. Look at images downscaled (about 960 pixels on
  the long edge) or through a subagent, with full-resolution crops only where
  fine detail is the point. Use a search subagent for wide searches.
- **Memory is the repository.** Claude Code's own memory is local to a
  machine, so anything worth keeping is a committed file. `CLAUDE.md` files
  stay short.

## Failure recovery

**Restarts.** Containers restart, and running commands, subagents and
session-scoped schedules do not survive. So every long run writes its output
to a log file that ends with a `DONE exit=<code>` line; a restarted agent
re-runs any run whose log lacks it. While iterating, run the relevant part of
the suite; run the full checks before marking a task ready.

**Did the message arrive?** See "Delivery and acknowledgement" above: no
acknowledgement in a status commit means not delivered.

**Deadlines.** Every deadline is written as an absolute time in ISO 8601 with
its offset, and with the owner's local time beside it:
`STOP_AT: 2026-11-03T21:00:00Z (= 18:00 America/Sao_Paulo)`. Agents check the
time with `date -u`, never by guessing from the conversation. Agents are
blind to the passing of time, and in the last waves several stopped early on
a misread time.

**The stop protocol.**

1. At `stop_at` minus 30 minutes, start no new task.
2. Bring the current work to its last verified state; commit and push it (a
   commit titled `WIP` if it is not green).
3. Write `state: "stopped"` and a `next_step` in the status file, the handoff
   in the progress file, and "Stopped here" in the notes.
4. Stop. Do not stop earlier because the work "looks done": an agent with
   time left takes the next task or the idle queue.
5. If the deadline is unclear, ask the lead in a request and keep working.

**Hooks.** A `Stop` hook can send an agent back to work while its time is
before `stop_at` less 30 minutes; the harness overrides it after eight blocks
in a row. It is proposed to the owner in the UI wave's plan (section 3.9),
not yet set.

## Lessons from waves 4 and 5

| What happened | The rule it led to |
|---|---|
| Ten agents rated their own work 80–99% done; an audit found about 30% | An independent, calibrated gate; progress reported as counts of items passing it; self-assessment recorded as a claim only |
| Agents collided on shared files | One owner per file, hotspot files named; requests instead of edits; contracts owned by one agent and consumed read-only |
| A merge silently undid the database optimisation | A guard that encodes the intent (`node server/load.mjs --check`); main moves only to a tested tree; one owner for the database files; a note of why the index exists |
| One agent sat idle after finishing early | The backlog's idle queue; one task per session; the lead refills the queue every cycle |
| Agents stopped early after misreading stop times | Absolute UTC deadlines with the local time beside them; `date -u`; the stop protocol; a Stop hook (proposed) |
| Every agent stalled together at the shared usage limit | A cap; a measured projection with a reserve; tiers; pause-safe commits |
| Container restarts killed test runs and cost one session about two and a half hours | Logs with a `DONE exit=<code>` marker; re-run when the marker is missing; commit after every verified step |
| A message sent through a disabled scheduled task never arrived | A message counts only when acknowledged in a status commit; check a scheduled task's enabled state and transcript |
| Sessions grew to 300k–400k tokens | Compaction at 200k; a fresh session per task with a handoff; output kept out of the context |
| The integrator merging every track each hour became the bottleneck | A merge queue, one change at a time; each agent resolves its own conflicts |
| Containers lacked tools check_all needs (Rust's `wasm32-unknown-unknown` target, `gdlint`, Python's `playwright` 1.63.0) | The brief lists them, and every agent installs them before its first check |

## Waves, progress files and stills

**Waves.** Work happens in *waves*: a stretch of hours in which a set of
tracks runs, ending at a time the owner sets. Each wave's work is headed by
its number in the notes ("Wave 5", "Fifth wave", "Session four (fifth
wave)": the wording varies by track). When a track stops, its notes get a
**"Stopped here"** section: what is pushed and green, what is half done, and
what the next agent should do first. Read that section before anything else
when picking a track up.

**Progress files.** Each running agent keeps `docs/progress/<agent>.md`. It
opens with the same six lines, so they can be read side by side:

```markdown
# T<n> <name>: progress

- Status: Green / Red, and what the last push contains.
- Progress: NN%, counting only work that is pushed and passes check_all.
- Done: what is finished.
- Next: what comes next.
- Blocked by: what stops it, or none.
- Owner decision needed: the decisions only the owner can make, or none.
```

Then a table of the agent's deliverables, with their weight, their status
and the evidence (a test, a commit, a still, a gate verdict):

```markdown
| Deliverable | Weight | Status | Evidence |
|---|---:|---|---|
```

Then the handoff (above). The **Owner decision needed** lines across every
progress file are the quickest list of what is waiting on the owner.

**Stills.** The 3D and interface tracks judge their work by stills rendered
from the real client (see [client.md](client.md#rendering-a-still)). Each
track commits the stills it judged by to `docs/art/shots/<folder>/`, the
folder named in the table above, as PNGs under 400 KB. From the UI wave on,
those stills are inputs to the gate, not the agent's own verdict.
