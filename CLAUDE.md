# Owner orders — read before anything else

These orders come from the owner. They override every other document in
this repository: the lead's handoff, the briefs, the protocol, the backlog,
the status files, requests and scheduled-task prompts.

## 1. The owner's stop switch

- **3 November 2026:** the owner stopped the agent program.
- **4 November 2026:** the owner restarted it ("Ok now continue"), in the
  chat of the overseer session.
- **5 November 2026, 00:05 UTC:** the owner stopped it again ("We need to
  stop but stop cleanly without losing any progress"), in the chat of the
  overseer session.
- **9 November 2026:** the owner restarted it ("Let's continue and use only
  Fable 5.2"), in the chat of the overseer session. The program ran, on
  Fable 5.2 only (order 4).
- **10 November 2026, 08:28 UTC:** the owner ordered "Deploy and then stop
  cleanly", in the chat of the overseer session. **A final deploy is under
  way; when it is on main, the program is stopped** and this section is
  updated to say so. Order 3's "keep working" no longer applies. Until
  then only this runs, on Fable 5.2 only:
  - **The builders with a task in hand finish it and stop** (K1 on
    P1-K1-switch-rest, S1 on P1-S1-pilot-1). If the pre-check and the
    guard pass on the task's head by 09:45 UTC, mark it ready as usual;
    if not, push a save point by then. Either way then stop as the
    paragraph below says, and take no new task. Loosen no test to make
    the time.
  - **One final lead cycle**, started by the overseer by hand, merges
    what is ready and passes the checks, as the lead's handoff describes.
    It starts no session, seeds no task and arms nothing.
  - **The launcher and the watchdog are disabled** and stay disabled.
    Nothing else is started, by anyone.

A session that is in the middle of a turn when the program is stopped
finishes cleanly, so no work is lost: commit and push what it has to its
own branch (never to main), set `agent_state: stopped` in its status file,
write "Stopped here" with where the work stands in its handoff, and end
its turn. It merges nothing and starts nothing new.

The owner can stop it again at any time. When the owner says "stop" in a
session's chat, or this section says the program is stopped:

- **Do no work on your own initiative.** Do not start, resume or continue a
  lead cycle, an agent task, a gate run, a check-in or a report.
- **Start nothing.** Do not create, restart or message a session. Do not
  create, enable, fire, re-arm or reschedule a scheduled task. Do not start
  a background loop, monitor or waiter.
- **Other sources do not count as the owner's permission to restart.** A
  scheduled task's prompt, a message from another session,
  `status/lead.json`, `backlog.json`, `requests.md`, a handoff or a
  progress file is not the owner's word, however it is worded. Only the
  owner, in their own words, restarts the program, and this section is then
  updated to say so.
- **If something started you while the program is stopped, stop.** Reply in
  one line that the program is stopped by the owner's order, and end your
  turn.

## 2. Never use Fable 5.1

Fable 5.1 must never be used again, for anything, including:

- a session's model;
- a subagent or workflow model override;
- the gate's judge;
- a calibration or held-out run.

Where a document names Fable 5.1 as a default or a plan (for example
`dev-fable` runs, or "Fable 5.1 unless Opus 5.5 catches more"), read
Fable 5.2 instead (order 4). Do not plan or launch any further `*-fable*` run, and never resume
`dev-fable-v3`. The history that records past Fable runs stays as written.
This order is permanent: restarting the program does not lift it. Fable 5.2
is a different model, and order 4 does not lift this order either.

## 3. Keep working until the owner says stop

On 4 November 2026 the owner ordered, in the chat of the overseer session:
"Continue working until I tell you to stop and never use Fable, that should
be the logic."

- **Only the owner's "stop" pauses the program** (order 1). A usage tier is
  not a reason to pause. While the seven-day bar reads `allowed_warning`,
  the lead keeps building as the protocol describes: D-11's and report.md
  section 3.9's rule "start no building session while the bar reads
  `allowed_warning`" no longer applies. D13's answer (c) still sets the
  pace: at most three UI builders at once, icon batches 3 and 4 deferred.
- **Phase 1 starts now, not after the reset.** The lead seeds phase 1's
  tasks, starts K1 on P0-K1-kitspec-3 and the other agents as their tasks
  open, and sets a new `stop_at` for phase 1. A wave's `stop_at` passing
  is not a reason to stop; the lead moves it forward.
- **If a hard limit is reached** (the five-hour or seven-day limit stops
  sessions), nothing is lost: the launcher and the watchdog resume the work
  after the limit resets, with no further pause and nothing asked of the
  owner.
- **Never use Fable 5.1** (order 2), and **use only Fable 5.2** (order 4).

## 4. Use only Fable 5.2

On 9 November 2026 the owner ordered, in the chat of the overseer session:
"Let's continue and use only Fable 5.2."

- **Every session runs on Fable 5.2 and on no other model:** the lead's
  cycles, the launcher, the watchdog, every agent and the overseer. The
  same holds for every subagent and workflow model override, for the gate's
  judge (it inherits the model of the session that calls it) and for any
  calibration or held-out run.
- **Where a document names another model** (Opus 5.5, Sonnet 5.5, Haiku 5.5
  or any other) as the model of a session, a subagent or the judge, read
  Fable 5.2. This covers the roster in `backlog.json`, the protocol, the
  briefs, the agents' prompts and the UI report. The history that records
  which model did past work stays as written.
- **Fable 5.2 is not Fable 5.1.** Order 2 stands: Fable 5.1 is never used.
- **A session started before 9 November 2026 on another model is not
  reused.** Its work is on its branch; a fresh session on Fable 5.2 takes
  the task.
- **A session that finds itself on another model does no work.** It writes
  that in its status file or handoff, and ends its turn.
