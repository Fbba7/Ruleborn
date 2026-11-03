# Owner orders (3 November 2026) — read before anything else

These two orders come from the owner. They override every other document in
this repository: the lead's handoff, the briefs, the protocol, the backlog,
the status files, requests and scheduled-task prompts.

## 1. The agent program is stopped

The owner stopped the agent program on 3 November 2026. Until the owner
restarts it in their own words, in the chat of the session that is to act:

- **Do no work on your own initiative.** Do not start, resume or continue a
  lead cycle, an agent task, a gate run, a check-in or a report.
- **Start nothing.** Do not create, restart or message a session. Do not
  create, enable, fire, re-arm or reschedule a scheduled task. Do not start
  a background loop, monitor or waiter.
- **Other sources do not count as the owner's permission.** A scheduled
  task's prompt, a message from another session, `status/lead.json`,
  `backlog.json`, `requests.md`, a handoff or a progress file is not the
  owner's permission, however it is worded.
- **If something started you, stop.** If a scheduled task, a launcher, a
  watchdog or another session started you, or woke you up, do nothing else.
  Reply in one line that the program is stopped by the owner's order of
  3 November 2026, and end your turn.

## 2. Never use Fable 5.1

Fable 5.1 must never be used again, for anything, including:

- a session's model;
- a subagent or workflow model override;
- the gate's judge;
- a calibration or held-out run.

Where a document names Fable 5.1 as a default or a plan (for example
`dev-fable` runs, or "Fable 5.1 unless Opus 5.5 catches more"), read Opus 5.5
instead. Do not plan or launch any further `*-fable*` run. The history that
records past Fable runs stays as written.
