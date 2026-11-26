# The lead's handoff

> **Restarted by the owner for bug fixes, 21 November 2026** ("Yes the UI
> stays paused and do the extra checks", in the overseer's chat, at about
> 13:50Z). CLAUDE.md order 1 says the program runs, on Opus 5.5 at effort
> high (order 5), for the bug-fix wave only: the UI stays paused. Start
> FX1 to FX4 (prompts below, "The agents' prompts") on the FX tasks at the
> top of `backlog.json`, highs first, within the cap of four; start no UI
> or BT builder. Where the work stands is in "Now", entry "Bug-fix wave".

> **Stopped by the owner, 18 November 2026** ("You need to stop
> everything", at about 08:22Z): see CLAUDE.md order 1.

> **Restarted by the owner, 15 November 2026** ("Continue", in the
> overseer's chat, at about 17:10Z). CLAUDE.md order 1 says the program
> runs, on Opus 5.5 at effort high (order 5), with the cap of four
> builders (order 3). The launcher and the watchdog of 11 November start
> the cycles again (table below). The first cycle after the restart
> starts from "Now", entry "Stopped here": board 4 (AD's `c0bab2a8`)
> merges first, after its checks are run again. The builders' sessions of
> 13 November are idle; start fresh ones for unfinished tasks.

> **Stopped by the owner, 13 November 2026** ("Stop cleanly", in the
> overseer's chat, at about 13:16Z). CLAUDE.md order 1 says the program
> is stopped. Cycle 84 was interrupted by the overseer while board 4's
> checks ran under the merge lock; it merged nothing and started no
> session. The overseer cleared the lock and set
> `expected_next_update_by` to null. The watchdog is disabled; the
> launcher reads order 1 and stops. Where the work stands is in "Now",
> entry "Stopped here".

> **Restarted by the owner, 11 November 2026** ("We still need to keep the
> UI process we were doing with the phases running as it was", then "Make
> sure it is running now", in the overseer's chat, at about 01:00Z).
> CLAUDE.md order 1 says the program runs, on Fable 5.2 only (order 4):
> every session the lead creates and every subagent it starts runs on
> Fable 5.2, and on no other model. Fable 5.1 is never used (order 2).
> The launcher and the watchdog are a new pair, created after the restart
> was on main (table below); every older one stays disabled. Cycle 51 is
> the first cycle after the restart. What it starts from is in "Now",
> entries "Restart, 11 November 2026" and "After the stop".

> **Stopped by the owner, 10 November 2026** ("Deploy and then stop
> cleanly", 08:28Z, in the overseer's chat), until the restart of 11
> November. The final deploy is on main (merges `e072364a` and
> `718ddcbe`, the lead's last write-up `8f03235f`). Cycle 50 was the
> last cycle before the stop, started by the overseer by hand; it merged
> what was ready and passed the checks, started no session, seeded no
> task and armed nothing. No session worked and nothing was merged
> between the stop and the restart.

> **Restarted by the owner, 9 November 2026** ("Let's continue and use only
> Fable 5.2", in the overseer's chat). The program ran from then until the
> stop of 10 November, on Fable 5.2 only (CLAUDE.md order 4): every session
> the lead creates and every subagent it starts runs on Fable 5.2, and on
> no other model. Fable 5.1 is never used
> (order 2). The launcher and the watchdog are new scheduled tasks firing
> into new Fable 5.2 sessions (table below); the old ones stay disabled.
> Since the stop of 10 November these two are disabled as well.
>
> Where the work stands after cycle 50, the final cycle (10 November
> 2026, 10:33Z):
>
> | Task | Branch | State |
> |---|---|---|
> | P1-AIA-kit-6 | `claude/ui-artist` | merged, `e072364a` (gate: Layered materials failed 3 of 3, advisory; P1-AIA-kit-7 carries the notes) |
> | P1-K1-switch-rest | `claude/ui-bake` | merged, `e072364a`; branch head `a2e75777`, K1 stopped |
> | P1-S1-pilot-1 | `claude/ui-screens-heist` | merged, `718ddcbe` (gate, advisory: 5 of 16 pass in the verdict file; cycle 50's entry says 4 and lists five) |
> | P1-AIA-kit-7 | `claude/ui-artist` | open, deps merged, not started; branch head `0c27e773` |
> | P1-S1-pilot-2 | `claude/ui-screens-heist` | open, deps merged, not started; branch head `376d86a9` |
> | P1-AD-board-1 | `claude/ui-ad` | open, waits for P1-S1-pilot-2, not started; branch head `1be67031` |
>
> Main passed check_all and guard.sh in cycle 50's container. Tasks
> done: 46 of 61. At the restart of 11 November no builder was working:
> every session was stopped or idle, and each open task needs a fresh
> session. The sessions of 4 November ran on Opus 5.5 and are not reused.
>
> **Owner orders.** The owner stopped the program on 3 November 2026,
> restarted it on 4 November, stopped it again on 5 November, restarted
> it on 9 November, stopped it on 10 November and restarted it on 11
> November 2026. Read the owner
> orders in
> [`CLAUDE.md`](../../CLAUDE.md) first: they override this file.

Every cycle of the lead is a fresh session, created by the launcher with the
repository checked out at main. It starts here and from
[`status/lead.json`](status/lead.json), runs one cycle of
[agent-protocol.md](../guides/agent-protocol.md#the-coordinator-and-the-lead-who-does-what),
then rewrites the "Now" section below and `status/lead.json`, and pushes.

## Running a cycle

0. Run `python3 tools/coord/cycle_needed.py`. If it exits 3, nothing
   changed since the last cycle: write nothing, push nothing, reply
   "Skipped: nothing new" and end your turn. On any other exit, a crash
   included, go on.
1. `git fetch origin`; save the branch heads with
   `python3 tools/coord/cycle_needed.py heads > <scratch>/heads.json`
   (outside the repository); read `docs/progress/backlog.json` and every
   status file on the roster's branches (`agents` in the backlog). Merged
   tasks are in `docs/progress/backlog-archive.json` and old "Now" entries
   in [`lead-archive.md`](lead-archive.md); read those only when a task or
   an entry you need is not here.
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
   `model` Opus 5.5 (the owner's order 5), with effort medium, or high
   when the task is complex by the owner's order 6 (CLAUDE.md), which
   says what counts; write the effort in the sessions table, title `Ruleborn <agent> <task id>`, tags `ruleborn:ui-wave`
   and `ruleborn:<agent>`, and as prompt a first line giving the reason
   (start, or restart and why) followed by the agent's prompt below. Start
   an agent when its next task is open with its deps merged and it has no
   session working. Before creating a session, call `get_session` on the
   agent's last one in the table below: while it is working, create none.
   One session per agent at a time; at most one restart per agent per
   cycle. Record every new session in the table.
   Every new or restarted builder's prompt tells it to read
   `docs/process/superpowers/README.md` first and follow CLAUDE.md
   order 8 with the skills there.
7. Write alerts to `docs/progress/owner-inbox.md`; ask the owner nothing,
   apply defaults. Keep the queue full (the protocol's "Keeping the queue
   full": a startable task or idle entry per free seat, phase 3 seeded once
   phase 2's exit is met or its `stop_at` passes). End by adding your entry
   at the top of "Now" below and rewriting `status/lead.json`
   (`updated_at`, `expected_next_update_by` = `updated_at` + 3 hours,
   `cycle` + 1, `next_step`), set "Latest lead cycle session" below to your
   own session (`get_session` with no ID), then, after rebasing onto main,
   run `python3 tools/coord/archive.py`, then
   `python3 tools/coord/cycle_needed.py record <scratch>/heads.json` (last,
   so `seen` holds what this cycle left; the next cycle ends at once while
   nothing changes), run `python3 tools/check_docs_consistency.py`, commit
   and push main.

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
| The launcher: one fresh lead cycle session an hour on Opus 5.5 at effort medium by order 6 (its stored prompt still says effort high; order 6 wins), unless the last is still working; if `create_session` is refused, it replies with the exact reason (created 15 Nov at 18:45Z) | `trig_01NksvDVV7iRJi4zrU7Uf7Te` | the launcher, `session_01SNkKxqooGx7cgr8Gdcf6S4` (Opus 5.5, effort high) | hourly at :38 |
| The watchdog (G-67): if `status/lead.json` is stale or the launcher's last run failed, starts one cycle itself on Opus 5.5 at effort medium by order 6 (its stored prompt still says effort high; order 6 wins) and alerts, naming any refusal of `create_session` with its exact reason (created 15 Nov at 18:46Z) | `trig_01RTRucUN1KoyRtkdMc3BAfH` | the watchdog, `session_01SNkKxmfz7eY3hZG1QRvPEn` (Opus 5.5, effort high) | every 2 hours at :08 |
| The launcher's second firing, so a cycle can start every half hour: the same prompt as the hourly firing, into the same session; it skips while the last cycle is working (created 16 Nov at 23:39Z at the owner's request to speed the program up) | `trig_0155PATecuM4Cm5NGsEsbkX1` | the launcher, `session_01SNkKxqooGx7cgr8Gdcf6S4` (Opus 5.5, effort high) | hourly at :13 |

**The pair in this table is the working pair**, created on 15 November
2026 at 18:45Z (the launcher's :13 firing was added on 16 November), after the restart of 15 November was on main.

The Opus 5.5 pair of 11 November is retired: launcher
`trig_01T7B65veojXUDAKzLK3FFBP` (into `session_01SNkKxoNHJW6nWHDeA8Mfth`)
and watchdog `trig_01A1NwZvKD6MDUosh4jyvqqr` (into
`session_01SNkKxnxxr83hSzGYBXwyr3`). The launcher's run of 15 November at
17:38Z had its `create_session` call refused, so no cycle started; the
overseer started cycle 85 by hand. Both were disabled on 15 November 2026
at 18:45Z and 18:47Z, and are never re-enabled. Their sessions, which had
run since 11 November, are not reused; the fresh pair above takes their
scheduled tasks, with the same plain prompts.

The Fable 5.2 pair of 11 November is retired: launcher
`trig_01U7kEeot7dmuJuNZVQJ7Bhm` (into `session_01SNkKxoSssjoHhFMVu5fLBN`)
and watchdog `trig_0195QvFjjm2oUgeCeyhU4bp4` (into
`session_01SNkKxrFNAJUoT99Tauv1rD`), created at 01:10Z after the restart
commit (`40c92625`) was on main (its first run started cycle 51's session)
and disabled on 11 November 2026 at 19:49Z. From about 05:30Z that day every Fable 5.2 session of the program,
these two included, stood still with its seven-day limit reading
`rejected`, so no cycle started after cycle 52. It stays disabled and is
never re-enabled. The overseer interrupted the Fable 5.2 sessions at
19:49Z: the launcher and watchdog above, cycle 52's lead
(`session_01SNkKxrATVfECHBXAWskbLg`) and its duplicate
(`session_01SNkKxnH8TzJqFh4YN5MvvE`), and the builders AIA
(`session_01SNkKxqH1rhueBqbuneEFSq`, P1-AIA-kit-7), K1
(`session_01SNkKxpc8H8L5VAJUYuNCba`, P1-K1-disc-host) and S1
(`session_01SNkKxqxd6Shqp4e1AafGUY`, P1-S1-pilot-2). None is reused
(order 5): their work is on their branches, and the lead starts each
unfinished task anew on Opus 5.5. Cycle 52's merge lock expired at 06:30Z.

The pair of 9 November is retired: launcher
`trig_01ChLd51gPMwzsKrXifYfkYj` (into `session_01SNkKxoc1ntTt7RqPTLViwy`)
and watchdog `trig_016aHfeAQkYXB6Z5X361irkE` (into
`session_01SNkKxpLf6R26Jp1H6iXTPv`), disabled on 10 November 2026 (the
launcher at 08:30Z, the watchdog at 08:34Z) on the owner's order to
deploy and stop. It stays disabled and is never re-enabled.

A scheduled task that fires into a session runs on that session's model,
and a session keeps the CLAUDE.md it was created with, so a restart
creates the two anew instead of re-enabling them. Both read CLAUDE.md
first and do nothing while order 1 says the program is stopped.

**Create these two sessions only after the restart is on main.** A
session keeps the CLAUDE.md it was created with; `git fetch` does not
refresh it. A first pair was created on 9 November at 20:55Z, four minutes
before the restart commit (`b5e822ac`, 20:59Z), so their CLAUDE.md still
said the program was stopped. The launcher's first run, fired by hand at
21:30Z, was refused when it called `create_session`, and no lead cycle
started. That pair is retired and stays disabled, never re-enabled:
launcher `trig_015MfKt65r6dHc7ozcWK9gRj` (into
`session_01SNkKxoZzkq3w8QP1Q43bBT`) and watchdog
`trig_01TrtGdoG6u7tDQe4Yn6BLpF` (into `session_01SNkKxmyJfHHm4UViVkYKYY`).

Latest lead cycle session: `session_01SNkKxpn5ZJDS7qZnMd2BFF` (cycle 214,
26 November 2026 from about 05:14Z, started by the Opus 5.5 launcher).
Cycle 212's was `session_01SNkKxpNTzU8p6veGpMZKBD` (26 November, from
about 04:14Z).
Cycle 210's was `session_01SNkKxpQsrHbWjUUKuWhdXk` (26 November, from
about 02:39Z).
Cycle 209's was `session_01SNkKxoG12caN7yyrvRzWSB` (26 November, from
about 02:14Z).
Cycle 208's was `session_01SNkKxp2mpvTYM3zZh3Gi1C` (26 November, from
about 01:38Z).
Cycle 207's was `session_01SNkKxr9K2YqiE7qf9taX7r` (26 November, from
about 01:15Z).
Cycle 206's was `session_01SNkKxnGQoazsb2Zn5jJzzd` (26 November, from
about 00:14Z).
Cycle 205's was `session_01SNkKxpVk3qU9Sg2wwL1V6J` (25 November, from
about 23:38Z).
Cycle 204's was `session_01SNkKxnHHPKMvqUk6akhCWX` (25 November, from
about 23:15Z).
Cycle 203's was `session_01SNkKxq8jXHuXvuJg4yvtE3` (25 November, from
about 22:15Z).
Cycle 202's was `session_01SNkKxqroqqoKeHuicPgcmk` (25 November, from
about 20:50Z).
Cycle 201's was `session_01SNkKxqSFEXjTCRxvhrgqb1` (25 November, from
about 20:14Z).
Cycle 197's was `session_01SNkKxoyugNa4BQjRBSzsYK` (25 November, from
about 17:40Z).
Cycle 196's was `session_01SNkKxoHmwS3dddh2WLvudH` (25 November, from
about 17:14Z).
Cycle 195's was `session_01SNkKxqxDHnxcUgHuGLSEXt` (25 November, from
about 16:39Z).
Cycle 193's was `session_01SNkKxqKcNj6xVjwrFQ9Xt4` (25 November, from
about 15:15Z).
Cycle 192's was `session_01SNkKxnzfoApztAshnsqsfp` (25 November, from
about 14:39Z).
Cycle 191's was `session_01SNkKxpEYznsGFjJLSHAYZS` (24 November, from
about 22:39Z).
Cycle 190's was `session_01SNkKxpurNviahy9ajdou9c` (24 November, from
about 22:14Z).
Cycle 189's was `session_01SNkKxo8JRgqBuCXFzt9dyF` (24 November, from
about 21:10Z).
Cycle 188's was `session_01SNkKxnyDUhJ1nCERqWyiAM` (24 November, from
about 20:14Z).
Cycle 187's was `session_01SNkKxo4wWyrJULuKf9ezgK` (24 November, from
about 19:45Z).
Cycle 186's was `session_01SNkKxqiFeCtTZE4nW7CtE5` (24 November, from
about 18:14Z).
Cycle 184's was `session_01SNkKxr2G8KQZktz2Zq8Ty8` (24 November, from
about 17:14Z).
Cycle 182's was `session_01SNkKxpHsQytV7iJPKhPoRL` (24 November, from
about 15:15Z).
Cycle 180's was `session_01SNkKxoEVVxDru4qsQF6zoa` (24 November, from
about 13:40Z).
Cycle 178's was `session_01SNkKxomdzcgoV8B8sTfZyr` (24 November, from
about 12:15Z).
Cycle 177's was `session_01SNkKxn8DSWinMpBGFgKJ18` (24 November, from
about 11:14Z).
Cycle 176's was `session_01SNkKxr4FBaDyTw226PfY2p` (24 November, from
about 10:14Z).
Cycle 175's was `session_01SNkKxqAuzTc5eTrFD3gtqF` (24 November, from
about 08:39Z).
Cycle 174's was `session_01SNkKxnMNhTQKiDu6mShtEP` (24 November, from
about 07:39Z).
Cycle 172's was `session_01SNkKxpgsn8Ad15uPi5ptnD` (24 November, from
about 05:35Z).
Cycle 171's was `session_01SNkKxqyMFdbVCW6QjLfJjC` (24 November, from
about 04:14Z).
Cycle 170's was `session_01SNkKxpQs7VVsV7GiXLmF8A` (24 November, from
about 03:40Z).
Cycle 169's was `session_01SNkKxnXrzUVLGqiGNmw1FR` (24 November, from
about 00:30Z).
Cycle 168's was `session_01SNkKxn1dZLeKHPjZ3mFguK` (23 November, from
about 23:13Z).
Cycle 167's was `session_01SNkKxpBYuqfDPQtPhugfWH` (23 November, from
about 22:05Z).
Cycle 166's was `session_01SNkKxr1ZSqi1YJiktk15QA` (23 November, from
about 21:39Z).
Cycle 165's was `session_01SNkKxpouhMqDYtpvhRsNr4` (23 November, from
about 21:20Z, the first cycle after the owner's restart of 23 November).
Cycle 164's was
`session_01SNkKxnEwW1ec5DJwnyoz4w` (21 November, from 21:39Z). Cycle
163's was `session_01SNkKxpcmxyDQn5DN27H68P` (from 21:14Z). Cycle
162's was `session_01SNkKxpKnFvTro6bdPJL9Ah` (from 20:10Z). Cycle
161's was `session_01SNkKxq7tRdEEZo5rkVPq4N` (from 19:39Z). Cycle
160's was `session_01SNkKxniTiRqQzPk2REyWq3` (from 18:39Z). Cycle
159's was `session_01SNkKxqKMkJiLRMM5bReP25` (from 18:14Z). Cycle
158's was `session_01SNkKxotqqNutawUf3M2pYb` (from 17:14Z). Cycle
157's was `session_01SNkKxqS8YH5ACTyg5ANTEz` (from 16:39Z). Cycle
156's was `session_01SNkKxmoamFWusvtLCG6EYC` (from 16:14Z). Cycle
155's was `session_01SNkKxo9bZSEQwttAmfNMX2` (from 15:14Z). Cycle
154's was `session_01SNkKxrGtCCvMiSUGwxCxup` (from 14:38Z). Cycle
153's was `session_01SNkKxr8vD91wFJCWPCztin` (from 14:15Z). Cycle
152's was `session_01SNkKxpjqNeDGHxFAxH2tjX` (from 14:06Z). Cycle
151's was `session_01SNkKxokQpSagJjzwYyeSuc` (18 November, from 08:13Z). Cycle
150's was `session_01SNkKxmm9uYmBksgbVUdjx9` (from 07:39Z). Cycle
149's was `session_01SNkKxrEmwKsYJezgFLCenb` (from 07:16Z). Cycle
148's was `session_01SNkKxnbZyh2sWsw9VhvuzX` (from 06:38Z). Cycle
147's was `session_01SNkKxpkKtCP2X5qJXco6ET` (from 05:39Z). Cycle
146's was `session_01SNkKxmdvLviNaCD3jf7YyA` (from 05:14Z). Cycle
145's was `session_01SNkKxphmrV3zwhPP7SkLLW` (from 04:15Z). Cycle
144's was `session_01SNkKxpJiWgbAtFKHtJZVPD` (from 03:39Z). Cycle
143's was `session_01SNkKxr53JyfW9VxwmrgaWV` (from 02:39Z). Cycle
142's was `session_01SNkKxpS24uPCXVy7p6bfK3` (from 02:14Z). Cycle
141's was `session_01SNkKxpEocuxTAPfpiN5b9n` (from 01:14Z). Cycle
140's was `session_01SNkKxpYPYZFhmxMYvxis4C` (from 23:38Z). Cycle
139's was `session_01SNkKxq4x4crXhYQkGcqX1K` (from 22:10Z). Cycle
138's was `session_01SNkKxpDFMUeUQciTDiwm62` (from 21:39Z). Cycle
137's was `session_01SNkKxnomTXF5W6AXtNDsaA` (from 21:14Z). Cycle
136's was `session_01SNkKxrHpFT28u48DFoYrxa` (from 20:45Z). Cycle
135's was `session_01SNkKxoHjTC6kV1CKeERwpY` (from 20:15Z). Cycle
134's was `session_01SNkKxpdca9RpS7R3j3gtZj` (from 19:38Z). Cycle
133's was `session_01SNkKxoFjecESfuZnwv7P5q` (from 19:16Z). Cycle
132's was `session_01SNkKxodysAxdoGSovguhgy` (from 18:39Z). Cycle
131's was `session_01SNkKxqumwkRG2bcMXAVVKV` (from 17:40Z). Cycle
130's was `session_01SNkKxoSr8iTomtimvAv5qj` (from 16:39Z). Cycle
129's was `session_01SNkKxo6AC6mQLT1hXmpwj5` (from 16:15Z). Cycle
128's was `session_01SNkKxom61CMr2pCMfuPfrv` (from 14:40Z). Cycle
127's was `session_01SNkKxqo2Pg29quXQtWaLHf` (from 14:18Z). Cycle
126's was `session_01SNkKxn49cnTinuA9di25Qn` (from 13:19Z). Cycle
125's was `session_01SNkKxnqEmBjkMNWvPgkCUt` (from 12:16Z). Cycle
124's was `session_01SNkKxosMXTnrRdW5v1jg9P` (from 11:15Z). Cycle
123's was `session_01SNkKxowru6g45cY8RLHmf5` (from 10:30Z). Cycle
122's was `session_01SNkKxmvEc842zraQZ21dQc` (from 09:39Z). Cycle
121's was `session_01SNkKxmiG2fJkzw87V4rNvc` (from 08:40Z). Cycle
120's was `session_01SNkKxnVWqySe65bs6CXACW` (from 08:05Z). Cycle
119's was `session_01SNkKxqCqKwynFeQfEP4pR3` (from 07:40Z). Cycle
118's was `session_01SNkKxpjRpZTfmY8CdqhAf9` (from 07:14Z). Cycle
117's was `session_01SNkKxqbBzHeQrccHM7ZD6p` (from 06:15Z). Cycle
116's was `session_01SNkKxqWFq56FsNSSyzA9pi` (from 05:10Z). Cycle
115's was `session_01SNkKxoNbeTeKGGMsN9ry59` (from 04:38Z). Cycle
114's was `session_01SNkKxqWporDHiELckV82hr` (from 04:14Z). Cycle
113's was `session_01SNkKxod4oGpNKzH7kz1EUJ` (from 03:40Z). Cycle
112's was `session_01SNkKxnALgp923n1Xz8RyLi` (from 03:14Z). Cycle
111's was `session_01SNkKxp3QH4szJPdrskLbcc` (from 02:39Z). Cycle
110's was `session_01SNkKxqnwS161aj2Ndyfo94` (from 02:14Z). Cycle
109's was `session_01SNkKxqA691fQupEvYwZ32N` (from 01:38Z). Cycle
108's was `session_01SNkKxnyW6RtDjtVJivG3bg` (from 00:14Z). Cycle
107's was `session_01SNkKxoeFFAtKhms3FvN3zQ` (from 22:39Z on 16 November). Cycle
106's was `session_01SNkKxotGbP1EXkMF8w5cpy` (from 21:39Z). Cycle
105's was `session_01SNkKxpseg4mh8yx1YBk6dS` (from 20:38Z). Cycle
104's was `session_01SNkKxq7RefUXnN7oBncd9P` (from 19:39Z). Cycle
103's was `session_01SNkKxnS8D88S3KnnZyABwf` (from 17:39Z). Cycle
102's was `session_01SNkKxr2KqhZcMDPDNjAD3g` (from 16:39Z). Cycle 101's was
`session_01SNkKxr2W1EVjzynnMCEqVA` (from 13:41Z). Cycle 100's was `session_01SNkKxoqsyfRu7nQ4xvraaU` (from 11:40Z). Cycle 99's was `session_01SNkKxqWs3DXEToJqEWQxXa` (from 10:39Z). Cycle
98's was `session_01SNkKxpnLgsoTHAqFj6UTHk` (from 09:35Z). Cycle
97's was `session_01SNkKxorVw3MyhDkJsvRqhq` (from 08:39Z). Cycle
96's was `session_01SNkKxo5L5nkx6LE2sYyMSz` (from 06:41Z). Cycle
95's was `session_01SNkKxmibsJftfpUThu9TXk` (from 05:39Z). Cycle
94's was `session_01SNkKxpxY6kjJC1TT6B65fn` (from 04:39Z). Cycle
93's was `session_01SNkKxqD2VSCqdpQojkHwTN` (from 03:35Z). Cycle
92's was `session_01SNkKxq7DW11Lp53nLDiX6H` (from 02:40Z). Cycle
91's was `session_01SNkKxoQWzjnjZaBEiPTh6V` (from 01:28Z, started by the
launcher). Cycle
90's was `session_01SNkKxpfmJKpwccgABc1Cdi` (from 00:44Z, started by the
launcher). Cycle
89's was `session_01SNkKxorJnFq3sLfbYDVUV8` (from 23:38Z, started by the
launcher). Cycle
88's was `session_01SNkKxqWhdKcPGLZVjTXGsX` (from 22:39Z, started by the
launcher). Cycle
87's was `session_01SNkKxqFHvZUY3kRm8JAVzo` (from 20:39Z, started by the
launcher). Cycle 86's
was `session_01SNkKxnnyaLSgG88hAKxd5z` (from 19:39Z, started by the
launcher). Cycle 85's
was `session_01SNkKxqLYw4qY5UxycWNhTR` (from 18:01Z, started by the
overseer after the owner's restart, the launcher's own session-start
refused). Cycle 84's was
`session_01SNkKxpqF4gx3yYhsXenUGt` (13 November from 12:38Z, interrupted
at the owner's stop). Cycle 83's was `session_01SNkKxn5sZ5Ez5cQQFwtAon`
(13 November from 11:38Z, started by the Opus 5.5 launcher). Cycle 82's
was `session_01SNkKxrMnNScoFR7y7AJx71` (from 10:38Z). Cycle 81's
was `session_01SNkKxmrBHkRN8tALzCsGkF` (from 09:38Z). Cycle 80's
was `session_01SNkKxorbtQPjVTWkgJKyfY` (from 08:38Z). Cycle 79's
was `session_01SNkKxpZSJe4qP28t2awv1v` (from 07:38Z). Cycle 78's
was `session_01SNkKxo77VSsG6MDN6kJbhE` (from 05:39Z). Cycle 77's
was `session_01SNkKxq8jXKxVQg8t1Ub3bT` (from 04:39Z). Cycle 76's
was `session_01SNkKxnLXN4d7GMy12F1W5F` (from 03:38Z). Cycle 75's
was `session_01SNkKxozSRuvzVXmhKrTz3w` (from 02:38Z). Cycle 74's
was `session_01SNkKxq74K4BtMR3MtbQTe1` (from 23:39Z). Cycle 73's
was `session_01SNkKxnQNXyshnSaWRSFz4A` (from 22:39Z). Cycle 72's
was `session_01SNkKxq8UPsw413Cqn38hyd` (from 20:39Z). Cycle 71's
was `session_01SNkKxr8rzRPkaA8ocqu69E` (from 18:39Z). Cycle 70's
was `session_01SNkKxpKUASWJcNRTsGDfsp` (from 16:38Z). Cycle 69's
was `session_01SNkKxnAEyrHDn5aRYpjvTB` (from 14:39Z). Cycle 68's
was `session_01SNkKxnfPvJzu1iksNyMgNw` (from 13:39Z). Cycle 67's
was `session_01SNkKxqJqzRbvVerXcUszbd` (from 12:39Z). Cycle 66's
was `session_01SNkKxqr3DC7Kb5YZfijUtN` (from 11:39Z). Cycle 65's
was `session_01SNkKxqZN7A6CTcTtr4tEcm` (from 10:38Z). Cycle 64's
was `session_01SNkKxqijuvwjXHbeAGDLGB` (from 09:39Z). Cycle 63's
was `session_01SNkKxnWuvvM5evq2WinaFR` (from 08:39Z). Cycle 62's
was `session_01SNkKxqEW3A3hwRz6VufQz5` (from 07:39Z). Cycle 61's
was `session_01SNkKxrEkx6oXeGzdGm4sDr` (from 06:39Z). Cycle 60's
was `session_01SNkKxp1vEH7M7oEGRULZPR` (from 04:38Z). Cycle 59's
was `session_01SNkKxpnpDTy3xKH1cD7N64` (from 03:41Z). Cycle 58's
was `session_01SNkKxq63oZNWPm4cReDWcP` (from 02:38Z). Cycle 57's
was `session_01SNkKxoLAJu3YypfTqBzR97` (from 01:39Z). Cycle 56's
was `session_01SNkKxoW2tKv8QRKNSnU1yd` (from 00:40Z). Cycle 55's
was `session_01SNkKxnNomdRK7U7hfS4cvz` (from 21:38Z). Cycle 54's
was `session_01SNkKxqcjmNkScYYnT5Er2i` (from 20:39Z). Cycle 53's
was `session_01SNkKxq9SSpFo8PxqxGC3p8` (from 19:51Z, the first cycle on
Opus 5.5 at effort high, order 5; its first commit, `2fccd5b2`, names it
with a mistyped ID in its trailer). Cycle 52's was `session_01SNkKxrATVfECHBXAWskbLg` (11 November
2026 from 05:20Z, on Fable 5.2, started by the launcher; it took the merge
lock for P1-AIA-kit-7 and stood still on its seven-day limit, and the lock
expired at 06:30Z). The watchdog started a second cycle session at the same minute
(`session_01SNkKxnH8TzJqFh4YN5MvvE`), which stood down (`95985299`) and
did no work. Cycle 51's was `session_01SNkKxnDPjsoJBxjS6oA73p` (the
first cycle after the restart of 11 November 2026, from 01:11Z, started by
the launcher). Cycle 50's was `session_01SNkKxnL64HmHVVoj2K58mZ` (the last
cycle before the stop, 10 November 2026 from 09:19Z to about 10:33Z,
started by the overseer by hand). Cycle 49's was `session_01SNkKxonDy8BxQGiqJJMXsB`
(from 07:38Z to about 07:55Z). Cycle 48's was
`session_01SNkKxqhTHTeKwMPJKdCubU` (from 03:38Z; paused from about
04:20Z to 06:50Z). Cycle
47's was `session_01SNkKxqErNms87y9wMHpJWR` (from 01:51Z); the watchdog
started a second cycle session at the same minute
(`session_01SNkKxqgeutvzGq4AWJLbqG`), which did no work. Cycle 46's was `session_01SNkKxoVXNfpAABNM81P62e`, cycle
45's `session_01SNkKxoFQJdmfH1eKm7DbKK`. Cycle 44's, of 4 November
2026 from 23:39Z, was recorded here as `session_01SNkKxqKY1WGt7cJSaqyYtWj`,
which is not a valid ID (one character too many); treat an ID that
`get_session` rejects as "not working".

Retired on 9 November 2026 (they fired into Opus 5.5 sessions), disabled
and kept for their run history: the launcher
`trig_01DgVGTTmwREAb7sHz8oQkiP` (into `session_01SNkKxn46tjHDfKNwyTXZwg`),
the watchdog `trig_015Lgi2ZssXBXPbzkCYqoKmL` (into
`session_01SNkKxpnV81q24cdprpaTwe`) and the overseer's one-shot check-in
`trig_01TLsnuwnbJBV11EePZc34TD`. Never re-enable them.

Retired on 30 October 2026, disabled and kept for their run history: the old
lead cycle `trig_018vvUDvm2PkMuXrcJPQ9BiB`, watchdog
`trig_01LatSpptvktXzQcEwYfn51A`, and the four restart tasks
(`trig_018WBkwVBocWr9kGbkrt1xs4`, `trig_01WpPzWUnLmna8PDzUYDhQVj`,
`trig_01JFG1PbKiumCjB4f61JcyJE`, `trig_016TpQMGvejeoBKfyQNWPd6Y`).

Agent sessions (on the repository at main, tagged `ruleborn:ui-wave` and
`ruleborn:<agent>`), the latest first per agent:

| Agent | Session | Task | Branch | Created |
|---|---|---|---|---|
| M2 | `session_01SNkKxqcJThi4swGsdinWkY` (Opus 5.5, effort high) | 3D0-M2-mask-screens (restart, cycle 214: resync attempt 3 after the verifier found the character screens count the stage's own interface (level_badge and the other screens' over/top) as world; Opus 5.5 high by order 7, a resync; M2's last session, `session_01SNkKxoEguEtd88C3hWyuT5`, is idle) | `claude/3d-mask` | 2026-11-26 05:25Z |
| M2 | `session_01SNkKxoEguEtd88C3hWyuT5` (Opus 5.5, effort high; idle, task sent to resync in cycle 214) | 3D0-M2-mask-screens (restart, cycle 211: resync attempt 2 after the verifier found the universe map's 2D pins leak into world.png and id.png (home.gd re-shows them each frame), so universe Q11 under-reads; Opus 5.5 high by order 7, a resync; M2's last session, `session_01SNkKxrB9QRrPjRunKNvHgP`, is idle) | `claude/3d-mask` | 2026-11-26 03:51Z |
| M2 | `session_01SNkKxrB9QRrPjRunKNvHgP` (Opus 5.5, effort high; idle, task sent to resync in cycle 211) | 3D0-M2-mask-screens (restart, cycle 209: resync after the verifier failed universe Q11 (the galaxy backdrop counted as island) and the realm's buildings classed as decoration; Opus 5.5 high by order 7, a resync; M2's last session, `session_01SNkKxmfUr1jfnjsq8DnggV`, is idle) | `claude/3d-mask` | 2026-11-26 02:31Z |
| SP-bt-01 | `session_01SNkKxqcX7brniT4BXdBWu8` (Opus 5.5, effort high; idle, task merged in cycle 210) | 3D0-CO-queue-flake (start, cycle 207: the coordinator task of cycle 206, assigned to the coordinator specialist; Opus 5.5 high as the task names, the merge queue and its lock; SP-bt-01's last session, `session_01SNkKxnk1jnaFLfc14YYCAq`, is idle, its task merged) | `claude/ui-spec-coord` | 2026-11-26 01:19Z |
| M2 | `session_01SNkKxmfUr1jfnjsq8DnggV` (Opus 5.5, effort medium; idle, task sent to resync in cycle 209) | 3D0-M2-mask-screens (start, cycle 206: M1-R2's mask task seeded after the baseline merged; Opus 5.5 medium by order 7, a complex task in tools/render; M2's last session, `session_01SNkKxpBiaVYnEU6QASbpEV`, is idle, its task merged) | `claude/3d-mask` | 2026-11-26 00:50Z |
| M1 | `session_01SNkKxpnpiNRd38EhMM9ukJ` (Opus 5.5, effort high) | 3D0-M1-baseline (restart, cycle 203: resync after the verifier found that --no-render overwrites the committed baseline data with nulls; Opus 5.5 high by order 7, a resync; M1's last session, `session_01SNkKxn9dm8J8WUsKvxtyJ6`, is idle) | `claude/3d-measure` | 2026-11-25 22:31Z |
| M2 | `session_01SNkKxpBiaVYnEU6QASbpEV` (Opus 5.5, effort high) | 3D0-M2-find-it (restart, cycle 202: resync after the verifier failed the shown guard's sight check (pale dots and petals credit it); Opus 5.5 high by order 7, a resync; M2's last session, `session_01SNkKxoLp1JEhwF88WFhv8b`, is idle) | `claude/3d-mask` | 2026-11-25 21:00Z |
| M1 | `session_01SNkKxn9dm8J8WUsKvxtyJ6` (Opus 5.5, effort high; idle, task sent to resync in cycle 203) | 3D0-M1-baseline (restart, cycle 200: resync after the verifier failed the table's coverage (screen_laws, universe_screens) and the '-' note; one tier up by order 7; M1's last session, `session_01SNkKxqcAXy4JEwSxwK6PFL`, is idle) | `claude/3d-measure` | 2026-11-25 19:51Z |
| DT1 | `session_01SNkKxnqKic2JjCv5tCXbXz` (Opus 5.5, effort high) | 3D0-DT1-data-spec (restart, cycle 200: resync after the verifier failed the realm watch in the fill rates; already the top tier by order 7; DT1's last session, `session_01SNkKxodKBY94BomQhXexAr`, is idle) | `claude/3d-data` | 2026-11-25 19:49Z |
| M2 | `session_01SNkKxoLp1JEhwF88WFhv8b` (Opus 5.5, effort high; idle, task sent to resync in cycle 202) | 3D0-M2-find-it (restart, cycle 199: resync after the verifier failed the route question and the off-frame guards; Opus 5.5 high by order 7, a resync; M2's last session, `session_01SNkKxpp86K3DcyB4kRkPow`, is idle) | `claude/3d-mask` | 2026-11-25 19:25Z |
| M1 | `session_01SNkKxqcAXy4JEwSxwK6PFL` (Sonnet 5.5, effort medium; idle, task sent to resync in cycle 200) | 3D0-M1-baseline (start, cycle 197: the budget split and the mask tool merged; Sonnet 5.5 medium by order 7, a simple docs-only task; M1's last session, `session_01SNkKxnNfLkQ2DLurDzjM8E`, is idle, its task merged) | `claude/3d-measure` | 2026-11-25 18:28Z |
| M2 | `session_01SNkKxpp86K3DcyB4kRkPow` (Sonnet 5.5, effort medium; idle, task sent to resync in cycle 199) | 3D0-M2-find-it (start, cycle 197: the mask tool merged; Sonnet 5.5 medium by order 7, a simple task in tools/render; M2's last session, `session_01SNkKxqUMV6Qs5KyydCjHjX`, is idle, its task merged) | `claude/3d-mask` | 2026-11-25 18:28Z |
| DT1 | `session_01SNkKxodKBY94BomQhXexAr` (Opus 5.5, effort high; idle, task sent to resync in cycle 200) | 3D0-DT1-data-spec (restart, cycle 197: resync after the verifier failed section 3's guard states; already the top tier by order 7) | `claude/3d-data` | 2026-11-25 18:15Z |
| DT1 | `session_01SNkKxpL9MBiEawLL7runx2` (Opus 5.5, effort high; idle, task sent to resync in cycle 197) | 3D0-DT1-data-spec (start, cycle 194: a new agent once M1's seat freed; Opus 5.5 high by order 7, it touches the extension and the replay's bytes) | `claude/3d-data` | 2026-11-25 15:42Z |
| M1 | `session_01SNkKxnNfLkQ2DLurDzjM8E` (Opus 5.5, effort high) | 3D0-M1-budget-split (restart, cycle 194: resync after the verifier failed the split; one tier up by order 7) | `claude/3d-measure` | 2026-11-25 16:31Z |
| M1 | `session_01SNkKxn3VgF7utqQN2JkCuy` (Sonnet 5.5, effort medium; idle, task sent to resync in cycle 194) | 3D0-M1-budget-split (start, cycle 192: a new agent; Sonnet 5.5 medium by order 7, a simple task in the shots and tools/render) | `claude/3d-measure` | 2026-11-25 14:42Z |
| M2 | `session_01SNkKxqUMV6Qs5KyydCjHjX` (Opus 5.5, effort medium) | 3D0-M2-mask-tool (restart, cycle 195: stale since 16:15Z; the last session went idle and disconnected after GitHub 503s, its status commit 108abe5e unpushed; same tier, the stop was the network) | `claude/3d-mask` | 2026-11-25 16:41Z |
| M2 | `session_01SNkKxpG1o34prYosYVfYED` (Opus 5.5, effort medium; idle and disconnected, replaced in cycle 195) | 3D0-M2-mask-tool (start, cycle 192: a new agent; Opus 5.5 medium by order 7, a complex task) | `claude/3d-mask` | 2026-11-25 14:42Z |
| CF1 | `session_01SNkKxp5DfWujKR3BZxFjQg` (Opus 5.5, effort medium; idle, task merged in cycle 194) | 3D0-CF1-style-frames (start, cycle 192: a new agent; Opus 5.5 medium by order 7, judgement on looks) | `claude/3d-camera` | 2026-11-25 14:42Z |
| AD | `session_01SNkKxqM8eV1Bdh5Hj1kPrX` (Opus 5.5, effort medium; idle, done) | P3-AD-wave-close (start by the overseer, by the owner's order: M63's O7 re-check; effort medium by order 6) | `claude/ui-ad` | 2026-11-24 23:30Z |
| SP-bt-05 | `session_01SNkKxpZxYqKXESzt9K8ZVK` (Opus 5.5, effort medium; stopped) | BT-05 (start, cycle 191: a new agent, once BT-04b merged; effort medium by order 6, a tools-only launcher that adds a new schema and changes no stored one) | `claude/ui-spec-gate-run` | 2026-11-24 23:17Z |
| SP-bt-06 | `session_01SNkKxr7UeYQUNErvUP7sgQ` (Opus 5.5, effort medium; stopped) | BT-06 (start, cycle 191: a new agent; effort medium by order 6, a tools-only check that adds new schemas and changes no stored one) | `claude/ui-spec-docs-check` | 2026-11-24 22:45Z |
| SP-bt-09 | `session_01SNkKxnPBMN3yNvawTfEeo9` (Opus 5.5, effort medium; stopped) | BT-09 (start, cycle 190: a new agent; effort medium by order 6, one tools-only script, tools/setup_env.sh) | `claude/ui-spec-setup` | 2026-11-24 22:16Z |
| SP-bt-07 | `session_01SNkKxntUxvJrAmwfuUT8wo` (Opus 5.5, effort medium) | BT-07 (start, cycle 189: a new agent; effort medium by order 6, a read-only tools-only task in tools/coord/metrics.*) | `claude/ui-spec-metrics` | 2026-11-24 21:34Z |
| SP-bt-04 | `session_01SNkKxooiW2REvhyUn5DXCa` (Opus 5.5, effort medium) | BT-04b (start, cycle 189: BT-04a merged as 56f3662b; effort medium by order 6, a tools-only task in tools/gate/; SP-bt-04's last session, `session_01SNkKxob5FVPEP75EW56UMP`, is idle, its task merged) | `claude/ui-spec-gate-render` | 2026-11-24 21:34Z |
| SP-bt-04 | `session_01SNkKxob5FVPEP75EW56UMP` (Opus 5.5, effort high) | BT-04a (resync, cycle 186: candidate 84be5f38 failed on render.py's self-test under the check sandbox's read-only HOME; effort high by order 6, a resync; SP-bt-04's last session, `session_01SNkKxnP8NpPyS23jXd4Upa`, is idle, its task ready at f1df3f1e) | `claude/ui-spec-gate-render` | 2026-11-24 19:35Z |
| SP-bt-01 | `session_01SNkKxnk1jnaFLfc14YYCAq` (Opus 5.5, effort high) | BT-01b (start, cycle 186: BT-01a merged as 99c9aa89; effort high by order 6, the merge queue and its lock, concurrency; SP-bt-01's last session, `session_01SNkKxnoYoXvgs2BTqD6NXy`, is idle, its task merged) | `claude/ui-spec-coord` | 2026-11-24 19:35Z |
| SP-bt-04 | `session_01SNkKxnP8NpPyS23jXd4Upa` (Opus 5.5, effort medium) | BT-04a (start, cycle 183: effort medium by order 6, a tools-only task in tools/gate/) | `claude/ui-spec-gate-render` | 2026-11-24 17:12Z |
| SP-bt-01 | `session_01SNkKxnoYoXvgs2BTqD6NXy` (Opus 5.5, effort medium) | BT-01a (start, cycle 183: effort medium by order 6, a dry-run tools-only task in tools/coord/) | `claude/ui-spec-coord` | 2026-11-24 17:12Z |
| S1 | `session_01SNkKxnAiVmwbdBsQYix7Y8` (Opus 5.5, effort high) | P4-S1-heist-vault (restart, cycle 187: second gate fail at 85be2fa8, attempts 2; effort high by order 6, the vault and a failed attempt; S1's last session, `session_01SNkKxrBVFU2PuzXccugcq8`, is idle) | `claude/ui-screens-heist` | 2026-11-24 19:52Z |
| S1 | `session_01SNkKxrBVFU2PuzXccugcq8` (Opus 5.5, effort high) | P4-S1-heist-vault (re-work, cycle 183: gate fail at 97ecb94f, attempts 1; effort high by order 6, the vault and a failed attempt; S1's last session, `session_01SNkKxp6Vp6uPSGzzYn1CNV`, is idle) | `claude/ui-screens-heist` | 2026-11-24 17:12Z |
| S1 | `session_01SNkKxp6Vp6uPSGzzYn1CNV` (Opus 5.5, effort high) | P4-S1-heist-vault (restart, cycle 181: reopened after the bug-fix wave; effort high by order 6, the task touches the vault; S1's last session, `session_01SNkKxrGVdaVPxzuPW8vwRg`, is idle) | `claude/ui-screens-heist` | 2026-11-24 14:59Z |
| S2 | `session_01SNkKxpVmnabuJ8D34eVaFy` (Opus 5.5, effort high) | P4-S2-home-purse (restart, cycle 181: reopened after the bug-fix wave; effort high by order 6, the task touches the purse; S2's last session, `session_01SNkKxneZ4WEHJSJUnhLjUj`, is idle) | `claude/ui-screens-home` | 2026-11-24 14:59Z |
| S3 | `session_01SNkKxmd5VK7q2FWEmAe3Be` (Opus 5.5, effort medium) | P3-S3-settings-4 (restart, cycle 181: reopened after the bug-fix wave; effort medium by order 6, settings layout in the client only; S3's last session, `session_01SNkKxo7BCcvsUE53DWANpH`, is idle) | `claude/ui-screens-meta` | 2026-11-24 14:59Z |
| FX3 | `session_01SNkKxmwFNqhHYqzetHQz3X` (Opus 5.5, effort high) | FX1-12-tools-ui (start, cycle 178: open since FX1-11-tools-docs merged at 7bbb9788; effort high by order 6, the task spans tools/ and server/ (its tests); FX3's last session, `session_01SNkKxmgmEjoRvu9UzjbupU`, is idle) | `claude/fix-sim` | 2026-11-24 12:50Z |
| FX3 | `session_01SNkKxmgmEjoRvu9UzjbupU` (Opus 5.5, effort high) | FX1-11-tools-docs (start, cycle 176: open since FX1-10-tools-contract merged at bdb052a8; effort high by order 6, the task spans tools/ and server/; FX3's last session, `session_01SNkKxnryguhFxw93wbzyLx`, is idle) | `claude/fix-sim` | 2026-11-24 11:01Z |
| FX4 | `session_01SNkKxpfHmWd8HXegEnr3P5` (Opus 5.5, effort medium) | FX4-8-rehearsal-rerun (start, cycle 176: its deps FX4-4 and FX4-7 merged; effort medium by order 6, a medium defect in the client only; FX4's last session, `session_01SNkKxoYfNyaJq9rBGUSuzk`, is idle) | `claude/fix-client` | 2026-11-24 10:17Z |
| FX3 | `session_01SNkKxnryguhFxw93wbzyLx` (Opus 5.5, effort high) | FX1-10-tools-contract (start, cycle 175: reassigned from FX1 with FX1-11 and FX1-12, its deps FX1-9 and FX4-7 merged; effort high by order 6, the task spans tools/, server/ and client/; FX3's last session, `session_01SNkKxqR9zT6xXyz2XFYKXb`, is idle) | `claude/fix-sim` | 2026-11-24 09:17Z |
| FX1 | `session_01SNkKxn8R6Rr28GFWpvcWZh` (Opus 5.5, effort high) | FX1-13-codex-woven-at (start, cycle 174: seeded from FX1-R25 after FX1-8-server-a-lows merged at e830e15b; FX1's last session, `session_01SNkKxpLTTBVYS7eUXqeFJr`, is idle) | `claude/fix-server-a` | 2026-11-24 08:29Z |
| FX4 | `session_01SNkKxoYfNyaJq9rBGUSuzk` (Opus 5.5, effort high) | FX4-7-curation-swap-weave (start, cycle 173: next task after FX4-6-device-replay-cap merged at ee4d64aa; FX4's last session, `session_01SNkKxqMB92sY6KUMaz9NgW`, is idle) | `claude/fix-client` | 2026-11-24 07:21Z |
| FX1 | `session_01SNkKxpLTTBVYS7eUXqeFJr` (Opus 5.5, effort high) | FX1-8-server-a-lows (restart, cycle 173: FX1-R24 granted; last session session_01SNkKxqoTBnLBZTVS18TPbn is idle, waiting on it) | `claude/fix-server-a` | 2026-11-24 06:48Z |
| FX1 | `session_01SNkKxqoTBnLBZTVS18TPbn` (Opus 5.5, effort high) | FX1-8-server-a-lows (start, cycle 171: deps FX1-6 and FX2-9 merged; last session session_01SNkKxppNySHfW7azVquQXU is idle) | `claude/fix-server-a` | 2026-11-24 05:30Z |
| FX3 | `session_01SNkKxqR9zT6xXyz2XFYKXb` (Opus 5.5, effort high) | FX1-9-tools-gate (start, cycle 172: reassigned from FX1, FX3's seat was free; row added by the lead in cycle 173) | `claude/fix-sim` | 2026-11-24 06:28Z |
| FX2 | `session_01SNkKxrBzWXR1vS1YHrW8zw` (Opus 5.5, effort high) | FX2-10-curated-woven-law (start, cycle 171: next open task, its dep FX3-6 merged; FX2-9-audit-b-match is ready and in the lead's merge; FX2's last session, `session_01SNkKxpD4TA2PFjhTUKW8Eb`, is idle) | `claude/fix-server-b` | 2026-11-24 04:56Z |
| FX4 | `session_01SNkKxqMB92sY6KUMaz9NgW` (Opus 5.5, effort high) | FX4-6-device-replay-cap (start, cycle 171: next task after FX4-5-problem-strings merged at d3183782; FX4's last session, `session_01SNkKxopnk1iG9R76L2ujyU`, is idle) | `claude/fix-client` | 2026-11-24 04:56Z |
| FX2 | `session_01SNkKxpD4TA2PFjhTUKW8Eb` (Opus 5.5, effort high) | FX2-9-audit-b-match (start, cycle 169: next task after FX2-8-audit-b-lows merged at cd5f98fb and FX1-6-audit-server-a at ddf4213d; FX2's last session, `session_01SNkKxnVeY5BcuXQfbPsPmN`, is idle) | `claude/fix-server-b` | 2026-11-24 03:38Z |
| FX1 | `session_01SNkKxppNySHfW7azVquQXU` (Opus 5.5, effort high) | FX1-7-audit-tools (start, cycle 169: next task after FX1-6-audit-server-a merged at ddf4213d; FX1's last session, `session_01SNkKxoYkrDKba5f2X3byBm`, is idle) | `claude/fix-server-a` | 2026-11-24 03:38Z |
| FX4 | `session_01SNkKxopnk1iG9R76L2ujyU` (Opus 5.5, effort high) | FX4-5-problem-strings (start, cycle 169: next task after FX4-4-audit-client merged at d5c16216; FX4's last session, `session_01SNkKxq3TGnXbTLc3pyMTQd`, is idle) | `claude/fix-client` | 2026-11-24 02:58Z |
| FX3 | `session_01SNkKxozbMJGfAJWTEzLykF` (Opus 5.5, effort high) | FX3-7-audit-client-2 (start, cycle 169: seeded from client.md's unproven findings after FX4-4-audit-client merged at d5c16216; FX3's last session, `session_01SNkKxpC2gbRiL8zzvf5zZc`, is idle) | `claude/fix-sim` | 2026-11-24 02:58Z |
| FX2 | `session_01SNkKxnVeY5BcuXQfbPsPmN` (Opus 5.5, effort high) | FX2-8-audit-b-lows (start, cycle 169: next task after FX2-7-audit-b-config merged at bc7f27e8; FX2's last session, `session_01SNkKxoWxCgQ4iNNoRWRghi`, is idle) | `claude/fix-server-b` | 2026-11-24 00:33Z |
| FX4 | `session_01SNkKxq3TGnXbTLc3pyMTQd` (Opus 5.5, effort high) | FX4-4-audit-client (start, cycle 167: next task after FX4-3-replay-shop-nav merged at 60a905ab; FX4's last session, `session_01SNkKxpABZrz4Mfhrmhdq7n`, is idle) | `claude/fix-client` | 2026-11-23 23:06Z |
| FX3 | `session_01SNkKxpC2gbRiL8zzvf5zZc` (Opus 5.5, effort high) | FX3-6-audit-universe (start, cycle 167: seeded from sim.md's "Still not read" after FX3-5-audit-sim merged at 490579d6; FX3's last session, `session_01SNkKxr46k63bAaFiJ5F3gi`, is idle) | `claude/fix-sim` | 2026-11-23 23:06Z |
| FX2 | `session_01SNkKxoWxCgQ4iNNoRWRghi` (Opus 5.5, effort high) | FX2-7-audit-b-config (start, cycle 167: seeded from server-b.md's confirmed findings after FX2-6-audit-server-b merged at ab25eb88; FX2's last session, `session_01SNkKxqkjiqLB1v3Vtjw8hm`, is idle) | `claude/fix-server-b` | 2026-11-23 23:06Z |
| FX1 | `session_01SNkKxoYkrDKba5f2X3byBm` (Opus 5.5, effort high) | FX1-6-audit-server-a (start, cycle 167: next task after FX1-4-holds-codex merged at e2e8f5a1; FX1's last session, `session_01SNkKxqf8d3D9CxTFED7uAn`, is idle) | `claude/fix-server-a` | 2026-11-23 22:20Z |
| FX4 | `session_01SNkKxpABZrz4Mfhrmhdq7n` (Opus 5.5, effort high) | FX4-3-replay-shop-nav (start, cycle 165: the owner's restart of 23 November; open since FX4-2-trace-events merged; the fourth seat, cap four with no seven-day warning; FX4's last session, `session_01SNkKxqMQ2aVNKyGDgeZMQy`, is idle, its task merged) | `claude/fix-client` | 2026-11-23 21:23Z |
| FX3 | `session_01SNkKxr46k63bAaFiJ5F3gi` (Opus 5.5, effort high) | FX3-5-audit-sim (restart, cycle 165: the owner's restart of 23 November; the cycle-164 session, `session_01SNkKxne1a1DLSJJZJn4mc2`, was interrupted at the stop of 21 November after its claim commit 941dd4a5 and is idle) | `claude/fix-sim` | 2026-11-23 21:23Z |
| FX2 | `session_01SNkKxqkjiqLB1v3Vtjw8hm` (Opus 5.5, effort high) | FX2-6-audit-server-b (start, cycle 165: the owner's restart of 23 November; next task after FX2-5-auth-lows merged at 5f1cc425; FX2's last session, `session_01SNkKxpZ9SYmNgdCeAw8sqx`, is idle) | `claude/fix-server-b` | 2026-11-23 21:23Z |
| FX1 | `session_01SNkKxqf8d3D9CxTFED7uAn` (Opus 5.5, effort high) | FX1-4-holds-codex (restart, cycle 165: the owner's restart of 23 November; the task is `resync`, its combined candidate with FX2-5 failed RB-36's test on the form byte; merge main, give RB-36's test manifests the form byte, rerun the checks; FX1's last session, `session_01SNkKxoFvZx6Npx6VHRteSw`, is idle) | `claude/fix-server-a` | 2026-11-23 21:23Z |
| FX3 | `session_01SNkKxne1a1DLSJJZJn4mc2` (Opus 5.5, effort high) | FX3-5-audit-sim (start, cycle 164: next task after FX3-4-lab-replay merged at f5870f77; the audit of the simulation) | `claude/fix-sim` | 2026-11-21 21:43Z |
| FX2 | `session_01SNkKxpZ9SYmNgdCeAw8sqx` (Opus 5.5, effort high) | FX2-5-auth-lows (restart, cycle 163: FX2-R1 granted, three test files in its exceptions; the session below ended its turn blocked on it) | `claude/fix-server-b` | 2026-11-21 21:16Z |
| FX1 | `session_01SNkKxoFvZx6Npx6VHRteSw` (Opus 5.5, effort high) | FX1-4-holds-codex (start, cycle 162: next task after FX1-3-workshop merged at e413e4a9; medium tier) | `claude/fix-server-a` | 2026-11-21 20:57Z |
| FX2 | `session_01SNkKxmg2qQ8HqKBzsGpMCx` (Opus 5.5, effort high; blocked on FX2-R1, replaced in cycle 163) | FX2-5-auth-lows (start, cycle 162: next task after FX2-4-purge-notify merged at e413e4a9; medium tier) | `claude/fix-server-b` | 2026-11-21 20:57Z |
| FX3 | `session_01SNkKxp6SqCgPtEaiERbSnT` (Opus 5.5, effort high) | FX3-4-lab-replay (start, cycle 162: next task after FX3-3-clock-report merged at e413e4a9; medium tier; cap three while the bar reads `allowed_warning`, FX4 waits) | `claude/fix-sim` | 2026-11-21 20:57Z |
| FX1 | `session_01SNkKxmoNcX1h8LTVeP5XNK` (Opus 5.5, effort high) | FX1-3-workshop (start, cycle 160: next task after FX1-2-leases merged at c7cdcbbd; medium tier) | `claude/fix-server-a` | 2026-11-21 19:13Z |
| FX2 | `session_01SNkKxnBNSWuPYLJtFjoP4M` (Opus 5.5, effort high) | FX2-4-purge-notify (start, cycle 160: next task after FX2-3-shop merged at c7cdcbbd; medium tier) | `claude/fix-server-b` | 2026-11-21 19:13Z |
| FX3 | `session_01SNkKxorHHkqpPHzjNrNryy` (Opus 5.5, effort high) | FX3-3-clock-report (start, cycle 160: next task after FX3-2-island merged at c7cdcbbd; medium tier; cap three while the bar reads `allowed_warning`, FX4 waits with the least work left) | `claude/fix-sim` | 2026-11-21 19:13Z |
| FX1 | `session_01SNkKxqAwEhhaxa4xEwqmCX` (Opus 5.5, effort high) | FX1-2-leases (start, cycle 158: next task after FX1-1-workshop-pairs merged at 8ed7538f; medium tier) | `claude/fix-server-a` | 2026-11-21 17:47Z |
| FX2 | `session_01SNkKxrM2E56bY4bUhSx5Q9` (Opus 5.5, effort high) | FX2-3-shop (start, cycle 158: next task after FX2-2-trace-telemetry merged at 8ed7538f; medium tier) | `claude/fix-server-b` | 2026-11-21 17:47Z |
| FX3 | `session_01SNkKxnzj1jLW96L7CkQ47A` (Opus 5.5, effort high) | FX3-2-island (start, cycle 158: open since FX3-1-heal-alarm merged at 23cf8a90; started in a seat the merge freed, cap three while the bar reads `allowed_warning`; FX4 waits, the least work left) | `claude/fix-sim` | 2026-11-21 17:47Z |
| FX1 | `session_01SNkKxoJFD1cxymge24jcxS` (Opus 5.5, effort high) | FX1-1-workshop-pairs (start, cycle 155: FX1's first session, high tier, deps none, in the seat FX3-1's merge freed; cap three while the bar reads `allowed_warning`) | `claude/fix-server-a` | 2026-11-21 16:08Z |
| FX2 | `session_01SNkKxnzeoEZGeu9uZfj2w9` (Opus 5.5, effort high) | FX2-2-trace-telemetry (start, cycle 155: next task after FX2-1-db-store-home merged at 23cf8a90; high tier) | `claude/fix-server-b` | 2026-11-21 16:08Z |
| FX4 | `session_01SNkKxqMQ2aVNKyGDgeZMQy` (Opus 5.5, effort high) | FX4-2-trace-events (start, cycle 155: next task after FX4-1-transport merged at 23cf8a90; high tier) | `claude/fix-client` | 2026-11-21 16:08Z |
| FX4 | `session_01SNkKxpaLsMGZP21royWUDx` (Opus 5.5, effort high) | FX4-1-transport (start, cycle 152: the bug-fix wave, M62; FX4's first session, first in the high tier, deps none) | `claude/fix-client` | 2026-11-21 14:09Z |
| FX2 | `session_01SNkKxnSsbQpjGppmXiBbGG` (Opus 5.5, effort high) | FX2-1-db-store-home (start, cycle 152: the bug-fix wave, M62; FX2's first session, high tier, deps none) | `claude/fix-server-b` | 2026-11-21 14:09Z |
| FX3 | `session_01SNkKxp7XpKf4e1axKU4F7x` (Opus 5.5, effort high) | FX3-1-heal-alarm (start, cycle 152: the bug-fix wave, M62; FX3's first session, high tier, deps none) | `claude/fix-sim` | 2026-11-21 14:09Z |
| S2 | `session_01SNkKxneZ4WEHJSJUnhLjUj` (Opus 5.5, effort high) | P4-S2-home-purse (start, cycle 149: seeded under M61 from S2-R44, phase 4's first home task, while phase 3's one exit item is held by S3; S2's last session, `session_01SNkKxpnKSbB1SgaR3ZrjwQ`, is idle, its task merged as 58a9a197) | `claude/ui-screens-home` | 2026-11-18 07:23Z |
| S1 | `session_01SNkKxrGVdaVPxzuPW8vwRg` (Opus 5.5, effort high) | P4-S1-heist-vault (start, cycle 149: seeded under M61 from the wave board's notes, phase 4's first heist task; S1's last session, `session_01SNkKxqdHWKAJ5VQDWhsTwQ`, is idle, its task merged as 3e8987b0) | `claude/ui-screens-heist` | 2026-11-18 07:23Z |
| S3 | `session_01SNkKxo7BCcvsUE53DWANpH` (Opus 5.5, effort high) | P3-S3-settings-4 (restart, cycle 149: AD-R68 from AD's preview 3, the tab strip, folded in before the gate run; ready 4a998521 withdrawn; S3's last session, `session_01SNkKxmmGcPDizHBY6ng1zz`, is idle) | `claude/ui-screens-meta` | 2026-11-18 07:23Z |
| AD | `session_01SNkKxmwmtLQbP3A4xcCpWR` (Opus 5.5, effort high) | S3-R45 (not blocking, due 12:00Z: preview P3-S3-settings-4's stills, AD-R67's answer, in `gate/boards/preview-3.md`) (start, cycle 148: S3-R45 copied; AD's last session, `session_01SNkKxnEBc1ok2qxGk7hpRb`, is idle, its task merged as 41ad4615) | `claude/ui-ad` | 2026-11-18 06:41Z |
| S3 | `session_01SNkKxmmGcPDizHBY6ng1zz` (Opus 5.5, effort high) | P3-S3-settings-4 (start, cycle 147: seeded for AD-R67, the wave board's one exit item, audit 2's miss on settings at 100% text; S3's last session, `session_01SNkKxqjkvtzBVBdApvpLwS`, is idle, its task merged as 3559ec39) | `claude/ui-screens-meta` | 2026-11-18 05:43Z |
| AD | `session_01SNkKxnEBc1ok2qxGk7hpRb` (Opus 5.5, effort high) | P3-AD-wave-board (start, cycle 145: the wave board, O7, phase 3's exit, seeded once P3-S1-marker-1 and P3-S3-offline-1 merged as 3559ec39; AD's last session, `session_01SNkKxnJHAVTyhVsLVjhU3m`, is idle, its task merged as 07e2c13d) | `claude/ui-ad` | 2026-11-18 04:55Z |
| S1 | `session_01SNkKxqdHWKAJ5VQDWhsTwQ` (Opus 5.5, effort high) | P3-S1-marker-1 (restart, cycle 143: S1-R43 granted, world_view.gd's `lift` for AD-R65 (M60); S1's last session, `session_01SNkKxqVesBsXCSfdHoP6BX`, went idle blocked on it, its branch at 020f5a52) | `claude/ui-screens-heist` | 2026-11-18 02:49Z |
| S3 | `session_01SNkKxqjkvtzBVBdApvpLwS` (Opus 5.5, effort high) | P3-S3-offline-1 (start, cycle 141: S3-R39's shorter pt_BR ERR_OFFLINE; its last dep, P3-K1-outline-1, merged as 2e17e1f1, K1's seat free; S3's last session, `session_01SNkKxoKvRK2mVxzbiptFn6`, is idle, its task merged as 995dcbfe) | `claude/ui-screens-meta` | 2026-11-18 01:47Z |
| AD | `session_01SNkKxnJHAVTyhVsLVjhU3m` (Opus 5.5, effort high) | P3-AD-audit-2 (start, cycle 141: the second blind audit, phase 3's exit, drawn in gate/audit/audit-2.md, then the previews S1-R42, S1-R41, S3-R40, AIA2-R4 and S3-R43 and M54's ack; a fresh session for the blind rules; AD's last session, `session_01SNkKxoHAV28mTbRdZouhPY`, is idle, its task merged as 2eff5f43) | `claude/ui-ad` | 2026-11-18 01:23Z |
| S1 | `session_01SNkKxqVesBsXCSfdHoP6BX` (Opus 5.5, effort high; idle, blocked on S1-R43, replaced in cycle 143) | P3-S1-marker-1 (start, cycle 140: seeded for AD-R55, the HUD draws above every map marker; P3-S2-back-1 merged, S2's seat free; S1's last session, `session_01SNkKxpSULfXqHgZQvrJKb4`, is idle, its task merged as fbae695a) | `claude/ui-screens-heist` | 2026-11-18 00:12Z |
| K1 | `session_01SNkKxn6UGKqas3XXoa59J8` (Opus 5.5, effort high), idle | P3-K1-outline-1, merged as 2e17e1f1 in cycle 141 (restart, cycle 140: K1-R28 granted on main, so merge main, change the granted lines, recheck and mark ready; K1's last session, `session_01SNkKxorBb4Hx1E3GUAr2GL`, idle waiting on the grant) | `claude/ui-bake` | 2026-11-17 23:44Z |
| S3 | `session_01SNkKxoKvRK2mVxzbiptFn6` (Opus 5.5, effort high) | P3-S3-settings-3 (start, cycle 139: seeded for AD-R52 in the third seat under the cap of three; S3's last session, `session_01SNkKxqvCzT3bnuPzL5KvLH`, completed P3-S3-nav-1, merged as 2dc57508) | `claude/ui-screens-meta` | 2026-11-17 22:59Z |
| K1 | `session_01SNkKxorBb4Hx1E3GUAr2GL` (Opus 5.5, effort high) | P3-K1-outline-1 (restart, cycle 139: K1-R27 granted on main, the four outline files are the task's exceptions, and P3-S3-nav-1 merged, so merge main, change those lines, recheck and mark ready; K1's last session, `session_01SNkKxr3SoTEVHPicDs7pG9`, idle waiting on the grant) | `claude/ui-bake` | 2026-11-17 22:57Z |
| S2 | `session_01SNkKxpnKSbB1SgaR3ZrjwQ` (Opus 5.5, effort high) | P3-S2-back-1 (restart, cycle 139: the lead's gate passes 'home at 100% text' with the quit question at 0bfa1d6a, 3 of 3, S2-R46 answered by the default and P3-S2-home-7 merged, so merge main, recheck and mark ready; S2's last session, `session_01SNkKxn1nyucpjrJfH22MCW`, idle) | `claude/ui-screens-home` | 2026-11-17 22:57Z |
| S2 | `session_01SNkKxn1nyucpjrJfH22MCW` (Opus 5.5, effort high) | P3-S2-back-1 (start, cycle 137: stacked on P3-S2-home-7, ready at 9ef7b295 and waiting for P3-AIA2-bake-1; S2's seat free at ready (M35); S2's last session, `session_01SNkKxnfpUVpuhWGguwhzhA`, is idle, its task ready) | `claude/ui-screens-home` | 2026-11-17 21:17Z |
| K1 | `session_01SNkKxr3SoTEVHPicDs7pG9` (Opus 5.5, effort high) | P3-K1-outline-1 (start, cycle 136: seeded for S3-R35, S3-R41 and S3-R37; S1's and S3's seats free at ready (M35); K1's last session, `session_01SNkKxq7JDCazLpMjivYruu`, is idle, its task merged as e3364018) | `claude/ui-bake` | 2026-11-17 21:09Z |
| AIA-2 | `session_01SNkKxq35wocEhfyMwmzRAR` (Opus 5.5, effort high) | P3-AIA2-bake-1 (start, cycle 134: S2-R45, the guard's byte-for-byte rebake failed on home-7's candidate on main's own icon bake; S2's seat free at ready (M35); a first session, `session_01SNkKxoME4QAYVNH1bBVGJ5`, was sent an incomplete prompt and archived within a minute, before it did any work) | `claude/ui-artist-icons` | 2026-11-17 20:01Z |
| S3 | `session_01SNkKxqvCzT3bnuPzL5KvLH` (Opus 5.5, effort high) | P3-S3-nav-1 (start, cycle 131: P3-S3-character-5 merged as c848afc3; seeded for AD-R50, R51, R63 and R64; S3's last session, `session_01SNkKxnZi7kDm1VGLiH5FC6`, is idle, its task merged) | `claude/ui-screens-meta` | 2026-11-17 18:22Z |
| S2 | `session_01SNkKxnfpUVpuhWGguwhzhA` (Opus 5.5, effort high) | P3-S2-home-7 (restart, cycle 132: its gate_request at c58d49c0 passes 12 of 12, so merge main, recheck and mark ready; S2's last session, `session_01SNkKxqf3uqLW1HGZt6KLXF`, idle since 17:32Z and past its 18:34Z update) | `claude/ui-screens-home` | 2026-11-17 18:45Z |
| S2 | `session_01SNkKxqf3uqLW1HGZt6KLXF` (Opus 5.5, effort high) | P3-S2-home-7 (start, cycle 128: P3-K1-tabs-1 merged as e3364018, K1's seat free; seeded for AD-R49's home part and AD-R59's caller; S2's last session, `session_01SNkKxpWQyicTk71sUaQiab`, is idle, its task merged as 6ecdecf3) | `claude/ui-screens-home` | 2026-11-17 15:42Z |
| AD | `session_01SNkKxoHAV28mTbRdZouhPY` (Opus 5.5, effort high), idle | P3-AD-preview-1, merged as 2eff5f43 in cycle 130 (start, cycle 128: P3-S1-hc-offline-1 merged as 7d0501d9, S1's seat free; seeded for S1-R40 and S3-R34; AD's last session, `session_01SNkKxnp8XMcnrw7r4cd79s`, is idle, its task merged as 06d96d05) | `claude/ui-ad` | 2026-11-17 15:31Z |
| K1 | `session_01SNkKxq7JDCazLpMjivYruu` (Opus 5.5, effort high), idle | P3-K1-tabs-1, merged as e3364018 in cycle 128 (start, cycle 125: seeded for AD-R47 and AD-R59; K1's last session, `session_01SNkKxrLmMHwDeCQXXnnsfn`, is idle, its task merged as 6ecdecf3) | `claude/ui-bake` | 2026-11-17 12:58Z |
| S3 | `session_01SNkKxnZi7kDm1VGLiH5FC6` (Opus 5.5, effort high), idle | P3-S3-character-5, merged as c848afc3 in cycle 131 (start, cycle 125: P3-K1-polish-2 merged as 6ecdecf3; S3's last session, `session_01SNkKxpXsYHy2L9mKvHcZBk`, is idle, its task merged) | `claude/ui-screens-meta` | 2026-11-17 12:58Z |
| S1 | `session_01SNkKxpSULfXqHgZQvrJKb4` (Opus 5.5, effort high) | P3-S1-hc-offline-2 (start, cycle 130: P3-AD-preview-1 merged as 2eff5f43, AD's seat free; AD-R60 to AD-R62 ruled in `boards/preview-1.md`; S1's last session, `session_01SNkKxpfWQzuYCK1pQhn9Wy`, is idle, its task merged as 7d0501d9) | `claude/ui-screens-heist` | 2026-11-17 17:19Z |
| AD | `session_01SNkKxnp8XMcnrw7r4cd79s` (Opus 5.5, effort high), idle | P3-AD-audit-1b, merged as 06d96d05 in cycle 126 (start, cycle 124: P3-AD-flow-2 merged as 744390e1; AD's last session, `session_01SNkKxpbxrV1iLPXhx2VvJB`, is idle, its task merged) | `claude/ui-ad` | 2026-11-17 12:06Z |
| K1 | `session_01SNkKxrLmMHwDeCQXXnnsfn` (Opus 5.5, effort high), idle | P3-K1-polish-2, merged as 6ecdecf3 in cycle 125 (restart, cycle 124: K1-R26 granted on main, so mark ready from fe983cae; K1's last session, `session_01SNkKxqUzSMWcDUgKbmzrEc`, went idle waiting on the grant) | `claude/ui-bake` | 2026-11-17 11:21Z |
| S2 | `session_01SNkKxpWQyicTk71sUaQiab` (Opus 5.5, effort high), idle | P3-S2-home-states, merged as 6ecdecf3 in cycle 125 (restart, cycle 123: AD answered S2-R42 with no objection at e9285afd, so mark ready; the lease lapsed at 10:30Z and the task was set open with prior_branch `claude/ui-screens-home` at 0f3a7a68; S2's last session, `session_01SNkKxqc1c89EaatiimmQ4C`, is idle) | `claude/ui-screens-home` | 2026-11-17 10:45Z |
| K1 | `session_01SNkKxqUzSMWcDUgKbmzrEc` (Opus 5.5, effort high; idle waiting on K1-R26, replaced in cycle 124) | P3-K1-polish-2 (start, cycle 122: P3-K1-polish-1 merged as 20304b70; K1's last session, `session_01SNkKxmdEQj6bHg2JvMnewm`, is idle, its task merged) | `claude/ui-bake` | 2026-11-17 10:14Z |
| AD | `session_01SNkKxpbxrV1iLPXhx2VvJB` (Opus 5.5, effort high), idle | S2-R42 (preview P3-S2-home-states, not blocking, due 16:00Z), then P3-AD-flow-2, merged as 744390e1 in cycle 124 (start, cycle 121: P3-AD-audit-1 merged as 1abc52ba; AD's last session, `session_01SNkKxp1i52e65jWBFfqp4t`, is idle, its task merged) | `claude/ui-ad` | 2026-11-17 09:33Z |
| S2 | `session_01SNkKxqc1c89EaatiimmQ4C` (Opus 5.5, effort high; idle waiting on S2-R42, its lease lapsed at 10:30Z, replaced in cycle 123) | P3-S2-home-states (start, cycle 118: phase 3 seeded under M49; S2's last session, `session_01SNkKxq8HjVf66y13L7w5BL`, is idle, its task merged) | `claude/ui-screens-home` | 2026-11-17 07:25Z |
| S1 | `session_01SNkKxqATU44HSCT5Am2dvc` (Opus 5.5, effort high), idle | P3-S1-result-7, merged as 1abc52ba in cycle 121 (start, cycle 118: phase 3 seeded under M49, the gate's Hierarchy fail at result 200% pt_BR; S1's last session, `session_01SNkKxpZ5ULnfUU5QKJPRM6`, is idle, its task merged as c6262802) | `claude/ui-screens-heist` | 2026-11-17 07:25Z |
| K1 | `session_01SNkKxmdEQj6bHg2JvMnewm` (Opus 5.5, effort high), idle | P3-K1-polish-1, merged as 20304b70 in cycle 122 (start, cycle 118: phase 3 seeded under M49, S3-R32 and S2-R35; K1's last session, `session_01SNkKxr27Br8FeRKiWvTJ1x`, is idle, its task merged) | `claude/ui-bake` | 2026-11-17 07:25Z |
| AD | `session_01SNkKxp1i52e65jWBFfqp4t` (Opus 5.5, effort high), idle | P3-AD-audit-1, merged as 1abc52ba in cycle 121 (start, cycle 118: phase 3 seeded under M49, the first blind audit, O6; AD's last session, `session_01SNkKxoJbJnMvxsrv2outFG`, is idle, its S1-R35 preview done) | `claude/ui-ad` | 2026-11-17 07:25Z |
| S2 | `session_01SNkKxq8HjVf66y13L7w5BL` (Opus 5.5, effort high) | P2-S2-home-6 (restart, cycle 115: its gate passes Display type 3/3 at a4090ec7, M46, so mark ready; S2's last session, `session_01SNkKxqDPpd7eVdbFeT2dp8`, is idle, waiting on the gate) | `claude/ui-screens-home` | 2026-11-17 04:48Z |
| AD | `session_01SNkKxoJbJnMvxsrv2outFG` (Opus 5.5, effort high) | S1-R35 (not blocking, due 2026-11-17T10:17Z: preview P2-S1-result-6 at c9d70cc3 or later) (start, cycle 111: S1-R35 copied; AD's last session, `session_01SNkKxnPTEBNJrsj8BFDyUi`, is idle, its S2-R34 preview done) | `claude/ui-ad` | 2026-11-17 02:45Z |
| AD | `session_01SNkKxnPTEBNJrsj8BFDyUi` (Opus 5.5, effort high; idle, S2-R34 answered at 01:57Z, AD-R45 to the lead; replaced in cycle 111) | S2-R34 (blocking, due 03:30Z: preview P2-S2-home-6 at 4c242628 or later) (start, cycle 109: S2-R34 copied; AD's last session, `session_01SNkKxq1MGyJ5jNneT2tqME`, is idle, its two previews done) | `claude/ui-ad` | 2026-11-17 01:43Z |
| S1 | `session_01SNkKxpZ5ULnfUU5QKJPRM6` (Opus 5.5, effort high) | P2-S1-result-6 (restart, cycle 116: resync per M47, the verdict-file conflict and four verdict files outside the task's files; S1's last session, `session_01SNkKxpBG3xx2UUqDBfeMa9`, is idle, its task ready at f6697161) | `claude/ui-screens-heist` | 2026-11-17 05:23Z |
| S1 | `session_01SNkKxpBG3xx2UUqDBfeMa9` (Opus 5.5, effort high; idle, its task ready at f6697161, replaced in cycle 116) | P2-S1-result-6 (restart, cycle 112: AD-R46's objection H, fixed in result-6 before it merges, then re-gated; S1's last session, `session_01SNkKxrHQgnrk4u1GoTLWJP`, is idle, its task ready at c9d70cc3) | `claude/ui-screens-heist` | 2026-11-17 03:19Z |
| S2 | `session_01SNkKxqDPpd7eVdbFeT2dp8` (Opus 5.5, effort high; idle waiting for the gate, replaced in cycle 115) | P2-S2-home-6 (start, cycle 108: P2-S2-home-5 merged as fb8ff4b9; its advisory gate's Display type fails at home 100% and 200% pt_BR, M33; S2's last session, `session_01SNkKxnd61Vr6rsj7aeL4cz`, is idle, its task merged) | `claude/ui-screens-home` | 2026-11-17 00:56Z |
| S3 | `session_01SNkKxpXsYHy2L9mKvHcZBk` (Opus 5.5, effort high), idle | P2-S3-character-4, merged (start, cycle 105: phase 2 exit, M25; the advisory gate's Display type fail on character at 200% text, pt_BR; S3's last session, `session_01SNkKxnS2WKmrL48Dmzje8k`, is idle, its task merged as 6d9a4bf1) | `claude/ui-screens-meta` | 2026-11-16 20:49Z |
| S2 | `session_01SNkKxnd61Vr6rsj7aeL4cz` (Opus 5.5, effort high) | P2-S2-home-5 (start, cycle 105: phase 2 exit, M25; the gate's Display type fail on home at 100% text; S2's last session, `session_01SNkKxrBFcY868FRDPnvoUz`, is idle, its task merged as 5803122d) | `claude/ui-screens-home` | 2026-11-16 20:49Z |
| S1 | `session_01SNkKxo7UZxeUrogyt29c1R` (Opus 5.5, effort high) | P2-S1-heist-1 (start, cycle 105: phase 2 exit, M25; the heist screen's open gate fails at 100% and 200% text; S1's last session, `session_01SNkKxpVcMU7QCMYR9SLhx3`, is idle, its task merged as 532296af) | `claude/ui-screens-heist` | 2026-11-16 20:47Z |
| K1 | `session_01SNkKxr27Br8FeRKiWvTJ1x` (Opus 5.5, effort high) | P2-K1-grow-1 (start, cycle 104: S1-R15, S1-R23, S3-R3 and S1-R32, the kit's buttons grow and wrap at large text and the reward sky stays plain under high contrast; K1's last session, `session_01SNkKxnzhmd9WDTWw6ChMw3`, is idle, its task merged as c0e0418b; idle, its task merged as d277dc25) | `claude/ui-bake` | 2026-11-16 20:22Z |
| K1 | `session_01SNkKxnzhmd9WDTWw6ChMw3` (Opus 5.5, effort high; idle, its task merged as c0e0418b in cycle 104) | P2-K1-guard-prereq (start, cycle 103: M32, guard.sh checks its prerequisites first; K1's last session, `session_01SNkKxnx23zG9HV4wddwVrq`, is idle, its task merged as 26cbd842) | `claude/ui-bake` | 2026-11-16 17:52Z |
| AD | `session_01SNkKxneJSddGy6BT3d1gxC` (Opus 5.5, effort high) | none: a duplicate of the row below, created by cycle 102 at 16:41Z, 33 seconds after cycle 101's, and archived at 16:42Z before it claimed anything | `claude/ui-ad` | 2026-11-16 16:41Z |
| AD | `session_01SNkKxq1MGyJ5jNneT2tqME` (Opus 5.5, effort high; idle, S2-R33 and S1-R34 answered; replaced in cycle 109) | previews S2-R33 (blocking: P2-S2-home-5, the purse's counts), then S1-R34 (P2-S1-heist-1's stills) (start, cycle 107: P2-K1-grow-1 merged as d277dc25 and freed K1's seat; AD's last session, `session_01SNkKxoVZrM6k7CuBbUpkM3`, is idle, its task done) | `claude/ui-ad` | 2026-11-16 23:29Z |
| AD | `session_01SNkKxoVZrM6k7CuBbUpkM3` (Opus 5.5, effort high) | P2-AD-board-3c, only H (restart, cycle 101: board 5c merged as 26cbd842 and home-4 as 5803122d; the session below ended done after board 5c) | `claude/ui-ad` | 2026-11-16 16:41Z |
| S3 | `session_01SNkKxnS2WKmrL48Dmzje8k` (Opus 5.5, effort high; idle, its task merged as 6d9a4bf1) | P2-S3-account-4 (start, cycle 101: AD-R43, board 5c's objection M) | `claude/ui-screens-meta` | 2026-11-16 16:41Z |
| S1 | `session_01SNkKxpVcMU7QCMYR9SLhx3` (Opus 5.5, effort high; idle, its task merged as 532296af) | P2-S1-result-5 (start, cycle 101: K1-R23, after P2-K1-kit-gaps-2 merged as 26cbd842) | `claude/ui-screens-heist` | 2026-11-16 16:41Z |
| AD | `session_01SNkKxr9VhN89uNMPX1WQ6Y` (Opus 5.5, effort high) | P2-AD-board-5c, then P2-AD-board-3c when P2-S2-home-4 merges (restart, cycle 101: board 5c opened with character-3's merge; the session below ended done) | `claude/ui-ad` | 2026-11-16 13:46Z |
| S2 | `session_01SNkKxrBFcY868FRDPnvoUz` (Opus 5.5, effort high; idle, its task merged as 5803122d) | P2-S2-home-4: gate request at 1697a6c6 and ready (restart, cycle 101: the session before went idle blocked on S2-R31 and S2-R30, both answered) | `claude/ui-screens-home` | 2026-11-16 13:46Z |
| K1 | `session_01SNkKxnx23zG9HV4wddwVrq` (Opus 5.5, effort high) | P2-K1-kit-gaps-2 (start, cycle 100: P2-K1-kit-gaps-1 merged as cf6165e9; the fourth seat with S2, AD and S1) | `claude/ui-bake` | 2026-11-16 12:24Z |
| AD | `session_01SNkKxoT1Zvr4LionPdFkEt` (Opus 5.5, effort high) | S2-R31 first (preview P2-S2-home-4 at c8de70fe), then S1-R31 (preview P2-S1-result-4), then P2-AD-board-5c and -3c when their tasks merge (restart, cycle 100: a seat free; S3-R29's default applied at 11:43Z) | `claude/ui-ad` | 2026-11-16 11:49Z |
| S1 | `session_01SNkKxnXsUaw4HRQU3Yc69h` (Opus 5.5, effort high) | P2-S1-result-4 (restart, cycle 100: the session below went idle waiting for the gate; the gate at 8753618a failed Display type, M30's close point) | `claude/ui-screens-heist` | 2026-11-16 11:49Z |
| S3 | `session_01SNkKxqxSgTQePYHeS97vWa` (Opus 5.5, effort high; idle, its task merged as 0ee8d9d8 in cycle 100) | P2-S3-character-3 (restart, cycle 99: S3-R30 granted, `client/scripts/auth_panel.gd` in its exceptions; the session below ended its turn waiting on it) | `claude/ui-screens-meta` | 2026-11-16 10:44Z |
| S1 | `session_01SNkKxpR61Xc97jycRSyB3B` (Opus 5.5, effort high; idle waiting for the gate, replaced in cycle 100) | P2-S1-result-4 (start, cycle 98: M25's fourth seat, phase 2's exit for the result screen; P2-S1-result-3 merged as 19cfe498) | `claude/ui-screens-heist` | 2026-11-16 09:43Z |
| K1 | `session_01SNkKxoSc1gCBJ4YfneEqN5` (Opus 5.5, effort high; idle, its task merged as cf6165e9 in cycle 100) | P2-K1-kit-gaps-1 (start, cycle 97: S3-R22, R24, R26 and R27 from IQ-kit-docs; P2-K1-tabs-3 merged as 1053266f) | `claude/ui-bake` | 2026-11-16 09:29Z |
| S3 | `session_01SNkKxpuAx4fJLdVkzpdFw8` (Opus 5.5, effort high; waiting on S3-R30, replaced in cycle 99) | P2-S3-character-3 (start, cycle 97: board 5b's objections K and L, AD-R40 and AD-R41; board 5b merged as 1053266f) | `claude/ui-screens-meta` | 2026-11-16 09:29Z |
| S2 | `session_01SNkKxoR9hEzsNNp5XQnTTG` (Opus 5.5, effort high) | P2-S2-home-4 (start, cycle 97: P2-K1-tabs-3 merged as 1053266f; the branch also carries IQ-import-check) | `claude/ui-screens-home` | 2026-11-16 09:28Z |
| AD | `session_01SNkKxrDXY9opvGEQBWJJEm` (Opus 5.5, effort high; idle, board 5b merged; replaced in cycle 100) | P2-AD-board-5b (restart, cycle 96: P2-S3-settings-2 merged as f675f05e; board 3c later) | `claude/ui-ad` | 2026-11-16 07:44Z |
| S3 | `session_01SNkKxoVbqcz1PXSbWEpF6Y` (Opus 5.5, effort high) | IQ-kit-docs (idle queue, M25; start, cycle 96: P2-S3-settings-2 merged, no S3 product task open) | `claude/ui-screens-meta` | 2026-11-16 07:44Z |
| AD | `session_01SNkKxmeSbBakuB4j1MjMoz` (Opus 5.5, effort high; done, S3-R21 answered at 07:00Z; replaced in cycle 96) | S3-R21 (re-check J on P2-S3-settings-2 at 9e602fcc), then P2-AD-board-3c and P2-AD-board-5b when open (restart, cycle 96) | `claude/ui-ad` | 2026-11-16 06:49Z |
| K1 | `session_01SNkKxpHjEg3z8ptenVQhCW` (Opus 5.5, effort high) | P2-K1-tabs-3 (start, cycle 96: AD-R38, board 3b's objection H, kit half) | `claude/ui-bake` | 2026-11-16 06:49Z |
| S2 | `session_01SNkKxoB47wLHjWYVpxbGNv` (Opus 5.5, effort high) | IQ-import-check (idle queue, M25; seat filled in cycle 96 while P2-S2-home-4 waits on P2-K1-tabs-3) | `claude/ui-screens-home` | 2026-11-16 06:49Z |
| AD | `session_01SNkKxp6Jtxgub8m9mNth9u` (Opus 5.5, effort high) | P2-AD-board-3b (board 3, second round; deps merged in cycle 94), then P2-AD-board-5b once P2-S3-settings-2 merges (restart, cycle 94; replaced in cycle 96) | `claude/ui-ad` | 2026-11-16 05:24Z |
| AD | `session_01SNkKxnNSwe9gUoLpoPTsuC` (Opus 5.5, effort high; done, S3-R19 and S2-R28 answered by 04:01Z; replaced in cycle 94) | S3-R19 first (re-check objection I on P2-S3-settings-2 at 25ed9fd9), then S2's re-check of (g) on P2-S2-home-3 once filed (restart, cycle 93; M20, M24) | `claude/ui-ad` | 2026-11-16 03:42Z |
| S2 | `session_01SNkKxnAA1sBLpf7cBYBHmb` (Opus 5.5, effort high) | P2-S2-home-3 (restart, cycle 92: AD's answer to S2-R27 keeps (f) as fixed at 8ff5ee23 and raises (g), the four side buttons missing at 200% in pt_BR and German; fix inside home-3, merge main, pre-check, re-check request of (g), ready; replaced in cycle 96) | `claude/ui-screens-home` | 2026-11-16 03:05Z |
| AD | `session_01SNkKxnih7NRgFAhLyJ3iuE` (Opus 5.5, effort high; done, S2-R27 and S3-R17 answered at 03:02Z; replaced in cycle 93) | S2-R27 first (M20, M24: re-check (f) on P2-S2-home-3 at 8ff5ee23), then S3-R17 (preview P2-S3-settings-2 at 60560762) | `claude/ui-ad` | 2026-11-16 02:48Z |
| K1 | `session_01SNkKxp9oEnbpwnq5zv4hEn` (Opus 5.5, effort high) | P2-K1-tabs-2 (start, cycle 91: S2-R24 and S2-R26; the fourth seat with S2, S3 and AD; replaced in cycle 96) | `claude/ui-bake` | 2026-11-16 01:50Z |
| AD | `session_01SNkKxmxBgcwrdBt9X39V3N` (Opus 5.5, effort high; done, S3-R16 answered and board 4b ready at 0662a940, replaced in cycle 92) | S3-R16 first (M20: re-check objection H on P2-S3-character-2 at 6b7e6b42), S2's re-check of (f) when filed, then P2-AD-board-4b (deps merged) | `claude/ui-ad` | 2026-11-16 01:50Z |
| S2 | `session_01SNkKxrMWzVsrupnQ5KsTGg` (Opus 5.5, effort high; idle after ready at 8ff5ee23, replaced in cycle 92) | P2-S2-home-3 (restart, cycle 91: AD's answer to S2-R25 holds (a) to (e) and raises (f), the realm pins' plates at 200%; fix inside home-3, merge main, pre-check, re-check request of (f), ready) | `claude/ui-screens-home` | 2026-11-16 01:50Z |
| AD | `session_01SNkKxp2nKS16efpGtUmaSG` (Opus 5.5, effort high; done, S2-R25 and S3-R15 answered, replaced in cycle 91) | S2-R25 first (M20: re-check S2-R22's (a) to (e) on P2-S2-home-3 at 823d2eac), then S3-R15 (preview P2-S3-character-2 at 45ca3158), then P2-AD-board-4b once P2-S1-result-3 shows merged | `claude/ui-ad` | 2026-11-16 00:51Z |
| S2 | `session_01SNkKxnhqmWB7hZwn9SeUuB` (Opus 5.5, effort high; idle after ready at 823d2eac, replaced in cycle 91) | P2-S2-home-3 (restart, cycle 88: AD's answer to S2-R22 keeps 1 to 5 as fixed and raises (a) to (e); fix them inside home-3, merge main, pre-check, re-check request, ready) | `claude/ui-screens-home` | 2026-11-15 22:44Z |
| AD | `session_01SNkKxpPaibzTsRuZzdTZic` (Opus 5.5, effort high; done, S2-R22 answered at 22:16Z, replaced in cycle 89) | S2-R22 first (M20: re-check S2-R20's objections 1-5 on P2-S2-home-3 at 13ff046f; S2's seat idle with its task ready), then the first open AD task, else done | `claude/ui-ad` | 2026-11-15 22:05Z |
| AIA | `session_01SNkKxqD2jxzsw1dZAgz7Ue` (Opus 5.5, effort high; idle, motion-3 ready at 1157bfb4) | P2-AIA-motion-3 (restart: merge main, run guard.sh, mark ready when its checks pass) | `claude/ui-artist` | 2026-11-15 20:45Z |
| AD | `session_01SNkKxnxMtbLFXk5d55r19u` (Opus 5.5, effort high; done, P2-AD-board-5 ready at 8b4b5827) | AD previews S1-R29 and AIA-R26, ack M23 (S3's freed seat), then the first open AD task | `claude/ui-ad` | 2026-11-15 20:13Z |
| S3 | `session_01SNkKxobxLMm7bkJemfXcuS` (Opus 5.5, effort high; done, P2-S3-settings-2 ready at 9e602fcc and merged; replaced in cycle 96) | P2-S3-character-2 (start: P2-AD-board-5 merged as d74bbbdf; AD-R31, R32, R33's character half, R34, R37; the fourth seat with S1, AIA and AD) | `claude/ui-screens-meta` | 2026-11-15 22:32Z |
| S3 | `session_01SNkKxmz8GQhVoYbmKSgiAL` (Opus 5.5, effort high; idle, its task merged) | P2-S3-settings (restart after the owner's restart: the gate on f0a36a41 passes all six rows, cycle 84's verdict carried to main in cycle 85; AD preview if owed, merge main, checks and guard.sh, ready) | `claude/ui-screens-meta` | 2026-11-15 18:08Z |
| AIA | `session_01SNkKxr42nS6EtCTLH5opM6` (Opus 5.5, effort high; idle, replaced at 20:45Z) | P2-AIA-motion-3 (start: board 4's objection C and D's strip target; M14, M21) | `claude/ui-artist` | 2026-11-15 18:05Z |
| S2 | `session_01SNkKxq9TRgdUDZjiKCeA3q` (Opus 5.5, effort high; idle after ready at 13ff046f, replaced in cycle 88) | P2-S2-home-3 (restart after the owner's restart: continue from the branch, S2-R20 objections 1 to 5, ready) | `claude/ui-screens-home` | 2026-11-15 18:05Z |
| S1 | `session_01SNkKxqB6A9FKaFvAKcXbLY` (Opus 5.5, effort high) | P2-S1-result-3 (start: board 4's objections AD-R27, R26, R29 and R30; stills to AD) | `claude/ui-screens-heist` | 2026-11-15 18:05Z |
| S2 | `session_01SNkKxquudGapkBBrdTGyQK` (Opus 5.5, effort high; stopped 13 Nov, replaced in cycle 85) | P2-S2-home-3 (restart: the last session idle since 09:55Z past its 10:58Z update; continue from c0b2bc49, merge main, pre-check, ready; AD's S2-R20 objections inside the task) | `claude/ui-screens-home` | 2026-11-13 11:23Z |
| AD | `session_01SNkKxnr3dQ98ULoLmDJcLd` (Opus 5.5, effort high; idle, board 4 merged as 14be4ddd in cycle 85) | S2-R20 first (preview home-3 at 0ffb6049 or newer), then P2-AD-board-4 (start: P2-S1-result-2 merged as 135a49b2; AD-R26 inside it) | `claude/ui-ad` | 2026-11-13 11:23Z |
| K1 | `session_01SNkKxpiU2Mw9DcThCLnW1H` (Opus 5.5, effort high; idle, tabs merged as 14be4ddd in cycle 85, replaced in cycle 91) | P2-K1-tabs (start: a free seat; board 3's objection D, AD-R25, and AD-R24's KitTabs part) | `claude/ui-bake` | 2026-11-13 10:50Z |
| AD | `session_01SNkKxqeNV7VTwM6RkPTRHh` (Opus 5.5, effort high; idle after answering S1-R25, replaced in cycle 82) | S1-R25 first (M20: re-check S1-R24's four objections in P2-S1-result-2 at 71167028), then the next open AD task, else done; P2-AD-board-3 ready at 4a48eef9 and in the merge queue | `claude/ui-ad` | 2026-11-13 09:44Z |
| S2 | `session_01SNkKxoy4LFKDybvN7vyFT5` (Opus 5.5, effort high; idle since 09:55Z with its check_all unreported, replaced in cycle 82) | P2-S2-home-3 (start: P2-S2-home-2 merged as 807d68a7; board 3's objections AD-R22 to AD-R24) | `claude/ui-screens-home` | 2026-11-13 08:53Z |
| S1 | `session_01SNkKxn8w6ndc88LGhoq4KQ` (Opus 5.5, effort high; idle, P2-S1-result-2 merged as 135a49b2) | P2-S1-result-2 (restart: AD's four S1-R24 objections stopped the merge in cycle 80; continue from aed28321, fix them, re-gate, ready) | `claude/ui-screens-heist` | 2026-11-13 08:53Z |
| AD | `session_01SNkKxoydJpnnk4xwpMmSj4` (Opus 5.5, effort high; idle after board 3 ready, replaced at 09:44Z) | P2-AD-board-3 (start: P2-S2-home-2 merged as 807d68a7; between boards, the previews S2-R18, S1-R24 and S3-R7) | `claude/ui-ad` | 2026-11-13 08:23Z |
| S1 | `session_01SNkKxp1GYKSQAkZjfQC3vM` (Opus 5.5, effort high; idle, replaced at 08:53Z) | P2-S1-result-2 (start: P2-S1-result-1 merged as f41d100e, P2-K1-motion merged; deliver M7 and M11) | `claude/ui-screens-heist` | 2026-11-13 06:13Z |
| S3 | `session_01SNkKxrGTeWurPkRy5fVrtk` (Opus 5.5, effort high; stopped 13 Nov, replaced in cycle 85) | P2-S3-settings (start: P2-S3-character merged as f41d100e) | `claude/ui-screens-meta` | 2026-11-13 06:13Z |
| AIA | `session_01SNkKxokBReWMyyoeH6tR9y` (Opus 5.5, effort high; idle, P2-AIA-motion-2 merged as 0bc0fbb9) | P2-AIA-motion-2 (restart: the last session went idle on AIA-R25 alone and its lease lapsed at 04:43:33Z; prior_sha 7fd401e7; AIA-R25's default applied early, M15; mark ready when its checks pass) | `claude/ui-artist` | 2026-11-13 04:45Z |
| S2 | `session_01SNkKxo9ZakHyaiiUKjsDBf` (Opus 5.5, effort high; idle, P2-S2-home-2 merged as 807d68a7) | P2-S2-home-2 (P2-S2-home-1 merged as 7e289af9; take its advisory gate points) | `claude/ui-screens-home` | 2026-11-13 05:22Z |
| S2 | `session_01SNkKxnuTWp4E5eG5m1dBtB` (Opus 5.5, effort high; idle, its task merged as 7e289af9) | P2-S2-home-1 (restart: the last session idle past its expected_next_update_by 01:18Z and its lease lapsed at 01:10Z; prior_sha 5164cc43; S2-R11's default applied early; take cycle 74's advisory gate points, then ready) | `claude/ui-screens-home` | 2026-11-13 02:43Z |
| S1 | `session_01SNkKxowrAJqRGxuKn8Tf1C` (Opus 5.5, effort high; idle, P2-S1-result-1 merged as f41d100e) | P2-S1-toon-drop (restart: the last session went idle waiting for the gate; advisory pass in verdicts/P2-S1-toon-drop/a7dd6501.json; mark ready); toon-drop merged as c0aa1bd6, the session builds P2-S1-result-1 next | `claude/ui-screens-heist` | 2026-11-12 23:41Z |
| S3 | `session_01SNkKxq23wc1i1XYqt7KM15` (Opus 5.5, effort high; idle, its task merged as f41d100e) | P2-S3-character (P2-S3-screenkit merged as 70057394; next task) | `claude/ui-screens-meta` | 2026-11-13 00:19Z |
| S3 | `session_01SNkKxqkkDvs1XEigTTp6o5` (Opus 5.5, effort high) | P2-S3-screenkit (restart: the last session idle past its expected_next_update_by 21:54:38Z and its lease lapsed at 22:16Z; prior_sha 03b3d762; answer Lead-R1, then ready); idle, its task merged as 70057394 | `claude/ui-screens-meta` | 2026-11-12 22:43Z |
| K1 | `session_01SNkKxqeMVkQseRbMLW4q8r` (Opus 5.5, effort high; idle, its task merged as ec2200b1) | P2-K1-motion (start: P2-AIA-motion-1 merged as a43e4d5a) | `claude/ui-bake` | 2026-11-12 22:02Z |
| S2 | `session_01SNkKxn7gvvhfq2Xjm1ocpN` (Opus 5.5, effort high; idle past its expected update, restarted in cycle 75) | P2-S2-home-1 (start: P2-flow-entry merged as 62c66327; S2-R4's default applies) | `claude/ui-screens-home` | 2026-11-12 22:02Z |
| S1 | `session_01SNkKxnTgyGWE1wfK5suMkd` (Opus 5.5, effort high; idle waiting for the gate, replaced at 23:41Z) | P2-S1-toon-drop (start: P2-S1-flow-replay merged as 509c43c2, P2-AIA2-busts merged) | `claude/ui-screens-heist` | 2026-11-12 22:02Z |
| S1 | `session_01SNkKxqKPyULbAiucFCfPRG` (Opus 5.5, effort high; idle, its task merged as 509c43c2) | P2-S1-flow-replay (start: P2-S1-flow-result merged as 9e1dd558; S1's session idle with its task merged; S1-R13 granted) | `claude/ui-screens-heist` | 2026-11-12 19:56Z |
| S2 | `session_01SNkKxozf5JRQDJPnSF8RWh` (Opus 5.5, effort high; idle, its task merged as 62c66327) | P2-flow-entry (start: P2-S2-flow-home merged as 7d899ce4; S2's session idle with its task merged) | `claude/ui-screens-home` | 2026-11-12 19:55Z |
| S3 | `session_01SNkKxnF4CGAt7d58kriezr` (Opus 5.5, effort high; idle past its expected update, restarted in cycle 73) | P2-S3-screenkit (start: S3's first session; report.md step 11, seeded in cycle 71; S2's session idle with its task ready, so S3 takes the third place in the cap) | `claude/ui-screens-meta` | 2026-11-12 19:13Z |
| AIA | `session_01SNkKxpZQK5vjTDskqnfXsB` (Opus 5.5, effort high; idle on AIA-R25 past its lease, replaced at 04:45Z) | P2-AIA-motion-2 (start: P2-K1-motion merged as ec2200b1; the fourth builder with S1, S2 and S3) | `claude/ui-artist` | 2026-11-13 01:41Z |
| AIA | `session_01SNkKxnSyJpXP86pzUyQUqT` (Opus 5.5, effort high; idle, its task merged as a43e4d5a) | P2-AIA-motion-1 (restart: the fourth builder by the owner's cap of four, M15; AIA-R23's default applied, the sheet stands; spec and checks passed at b96e3f64) | `claude/ui-artist` | 2026-11-12 20:42Z |
| AIA | `session_01SNkKxnntrrTGLutdQgN4sk` (Opus 5.5, effort high; idle waiting on AIA-R23, replaced at 20:42Z) | P2-AIA-motion-1 (start: report.md step 8, seeded in cycle 71; AIA's last session was a Fable 5.2 one, not reused) | `claude/ui-artist` | 2026-11-12 18:52Z |
| S1 | `session_01SNkKxpQyZFv1eTtnsa2WHD` (Opus 5.5, effort high; idle, its task merged) | P2-S1-flow-result (restart: expected_next_update_by 18:33:59Z passed, session idle; pre-check of 262904c4 lost with the old container) | `claude/ui-screens-heist` | 2026-11-12 18:44Z |
| S1 | `session_01SNkKxpXF5zd3wf5VZ65Utv` (Opus 5.5, effort high; idle, replaced at 18:44Z) | P2-S1-flow-result (start: P1-AD-board-1d merged as a154d246, board 1 stands, phase 2 open) | `claude/ui-screens-heist` | 2026-11-12 17:47Z |
| S2 | `session_01SNkKxpNwGbxJdZihbsYFS5` (Opus 5.5, effort high; idle, its task merged) | P2-S2-flow-home (start: a new agent in the roster; phase 2 open) | `claude/ui-screens-home` | 2026-11-12 17:47Z |
| AIA-2 | `session_01SNkKxoqXe6HWeBBVJdS6Ru` (Opus 5.5, effort high; idle, its task merged) | P2-AIA2-busts (start: board 1's note G, AD-R20; phase 2 open) | `claude/ui-artist-icons` | 2026-11-12 17:47Z |
| AD | `session_01SNkKxrFqhFsxDUmtqPET8E` (Opus 5.5, effort high; its task merged) | P1-AD-board-1d (start: P1-S1-pilot-5 merged as fe27c8f2; re-check objections D and F on pilot-5's stills; verdicts in verdicts/P1-S1-pilot-5/beb8a023.json) | `claude/ui-ad` | 2026-11-12 16:07Z |
| S1 | `session_01SNkKxn9y7QjFsFiRjgoaAP` (Opus 5.5, effort high; idle, its task merged) | P1-S1-pilot-5 (restart: the session below went idle waiting for the gate; verdicts in verdicts/P1-S1-pilot-5/beb8a023.json, all pass, advisory; mark ready from the handoff) | `claude/ui-screens-heist` | 2026-11-12 13:52Z |
| S1 | `session_01SNkKxoXAbUvoLyhk2tDXzh` (Opus 5.5, effort high; idle, replaced at 13:52Z) | P1-S1-pilot-5 (start: board 1's round 3 in P1-AD-board-1c, objections D and F open; AD-R17, AD-R18) | `claude/ui-screens-heist` | 2026-11-12 11:27Z |
| AD | `session_01SNkKxmtatzN7YRTTZcPFsL` (Opus 5.5, effort high; idle, its task merged) | P1-AD-board-1c (start: P1-K1-numerals-on and P1-S1-pilot-4 merged as 541e4c97; the gate's notes in verdicts/P1-S1-pilot-4/e846c531.json and verdicts/P1-K1-numerals-on/1d21bf4a.json) | `claude/ui-ad` | 2026-11-12 09:30Z |
| S1 | `session_01SNkKxnQXTay5oBDdKNoz8h` (Opus 5.5, effort high; idle, its task merged) | P1-S1-pilot-4 (start: board 1's round 2 in P1-AD-board-1b, objections D and B open; AD-R13, AD-R15) | `claude/ui-screens-heist` | 2026-11-12 06:54Z |
| K1 | `session_01SNkKxqEuMj3TF1SQMhjHgP` (Opus 5.5, effort high; idle, its task merged) | P1-K1-numerals-on (start: P1-S1-pilot-3 merged as 085c812a with the switch off; S1-R11, K1-R11, the gate's Display type note) | `claude/ui-bake` | 2026-11-12 05:39Z |
| AD | `session_01SNkKxpcpCTDib53apRny85` (Opus 5.5, effort high; idle, its task merged) | P1-AD-board-1b (start: P1-S1-pilot-3 merged as 085c812a; the gate's notes in verdicts/P1-S1-pilot-3/0d142dd0.json) | `claude/ui-ad` | 2026-11-12 05:39Z |
| S1 | `session_01SNkKxp6HQPTjRP521X89Gw` (Opus 5.5, effort high; idle, its task merged) | P1-S1-pilot-3 (start: P1-K1-heist-kit and P1-AD-board-1 merged as a01e4d6c; board 1's objections A-E) | `claude/ui-screens-heist` | 2026-11-12 01:21Z |
| AD | `session_01SNkKxqUaNgqwmejJAEzasn` (Opus 5.5, effort high; idle, its task merged) | P1-AD-board-1 (start: P1-S1-pilot-2 merged as d880807e) | `claude/ui-ad` | 2026-11-11 22:16Z |
| K1 | `session_01SNkKxrLVEpoeqhNUMybpRi` (Opus 5.5, effort high; idle, its task merged) | P1-K1-heist-kit (start: P1-K1-disc-host merged as 4dde8d03) | `claude/ui-bake` | 2026-11-11 21:16Z |
| K1 | `session_01SNkKxqMwm4w36af9FQvXVB` (Opus 5.5, effort high; idle, its task merged) | P1-K1-disc-host (restart: the Fable 5.2 session stood still and is not reused, order 5; merge prior_sha 905f9fca, finish guard, pre-check, handoff) | `claude/ui-bake` | 2026-11-11 19:54Z |
| S1 | `session_01SNkKxou5iRnrCMLMUqmcRa` (Opus 5.5, effort high; idle, its task merged) | P1-S1-pilot-2 (restart: as K1; merge prior_sha 38a154ea and do the task) | `claude/ui-screens-heist` | 2026-11-11 19:54Z |
| AIA | `session_01SNkKxqH1rhueBqbuneEFSq` (Fable 5.2, interrupted, not reused) | P1-AIA-kit-7 | `claude/ui-artist` | 2026-11-11 01:15Z |
| K1 | `session_01SNkKxpc8H8L5VAJUYuNCba` (Fable 5.2, interrupted, not reused) | P1-K1-disc-host | `claude/ui-bake` | 2026-11-11 01:15Z |
| S1 | `session_01SNkKxqxd6Shqp4e1AafGUY` (Fable 5.2, interrupted, not reused) | P1-S1-pilot-2 | `claude/ui-screens-heist` | 2026-11-11 01:15Z |
| AIA | `session_01SNkKxn3ipTmYbgSCzE7KeM` | P1-AIA-kit-6 (restart: AIA-R20 and AIA-R21 answered with their defaults; fill the handoff, mark ready, gate request); idle, done | `claude/ui-artist` | 2026-11-10 06:53Z |
| K1 | `session_01SNkKxoJ8mhZCTqZrVR3GTe` (stopped, done) | P1-K1-switch-rest | `claude/ui-bake` | 2026-11-10 07:33Z |
| S1 | `session_01SNkKxq8aqgTaKU6VpynuMm` (stopped, done) | P1-S1-pilot-1 | `claude/ui-screens-heist` | 2026-11-10 07:33Z |
| AIA | `session_01SNkKxqtMs5PEduX3C73kWc` (idle, replaced) | P1-AIA-kit-6 | `claude/ui-artist` | 2026-11-10 02:49Z |
| K1 | `session_01SNkKxokS4F9D68QZEPomby` (idle, done) | P1-K1-switch-heist (restart: K1-R13 answered, icons-2a merged; merge main, guard, pre-check, ready) | `claude/ui-bake` | 2026-11-10 02:49Z |
| AIA-2 | `session_01SNkKxmfMQZ66P5GyjL9tNY` (idle, done) | P1-AIA2-icons-2b | `claude/ui-artist-icons` | 2026-11-10 02:49Z |
| AIA | `session_01SNkKxoemFM74dP2XqeyASw` (idle, done) | P1-AIA-kit-5 | `claude/ui-artist` | 2026-11-09 22:23Z |
| K1 | `session_01SNkKxprLYRQQqA25xRhiQi` (idle, replaced) | P1-K1-switch-heist | `claude/ui-bake` | 2026-11-09 22:23Z |
| AIA-2 | `session_01SNkKxnFDNLwC9swBdJVTEM` (idle, done) | P1-AIA2-icons-2a (restart: resync, guard's rebake fails on icons_48_hc.webp; make finish.js's grow computed on pixels) | `claude/ui-artist-icons` | 2026-11-09 21:53Z |
| AIA | `session_01SNkKxpLGXniYM5JnmyzqE7` (idle, done; Opus 5.5, not reused) | P1-AIA-kit-4 (restart: resync, its nine skins missing from SKINS_OF) | `claude/ui-artist` | 2026-11-04 23:30Z |
| AIA-2 | `session_01SNkKxnB46NyYAV26hWtwrg` (idle, replaced; Opus 5.5, not reused) | P1-AIA2-icons-2a | `claude/ui-artist-icons` | 2026-11-04 23:21Z |
| K1 | `session_01SNkKxo2gLyAa89sh1bYjJq` (idle, done; Opus 5.5, not reused) | P1-K1-words | `claude/ui-bake` | 2026-11-04 23:21Z |
| AIA-2 | `session_01SNkKxoAA41vxL7RwwKNRGN` (idle, done) | P1-AIA2-icons-1b (restart: resync, icons_48_hc.webp is not what its sources bake to) | `claude/ui-artist-icons` | 2026-11-04 20:59Z |
| AIA-2 | `session_01SNkKxnfqxoDcFwrXf6z7o8` (idle, replaced) | P1-AIA2-icons-1b | `claude/ui-artist-icons` | 2026-11-04 18:34Z |
| K1 | `session_01SNkKxqXv3kuBk7Uya8STrT` (idle, done) | P1-K1-catalogue (restart: resync, kit-3's numerals missing from SKINS_OF) | `claude/ui-bake` | 2026-11-04 21:54Z |
| K1 | `session_01SNkKxorLGKFDuXX2ULtTU2` (idle, replaced) | P1-K1-catalogue (restart: resync, kit-2's skins missing from SKINS_OF) | `claude/ui-bake` | 2026-11-04 20:00Z |
| K1 | `session_01SNkKxnnyL6yNX5UpCnt8dH` (idle, replaced) | P1-K1-catalogue | `claude/ui-bake` | 2026-11-04 17:41Z |
| AIA | `session_01SNkKxmbXiobGvGu7DHZRJZ` (idle, replaced) | P1-AIA-kit-4 | `claude/ui-artist` | 2026-11-04 21:32Z |
| AIA | `session_01SNkKxqGqwHJU12VPiWB68i` (idle, done) | P1-AIA-kit-3 | `claude/ui-artist` | 2026-11-04 19:20Z |
| AIA | `session_01SNkKxmwaE4rQY339ct2nz9` (idle, done) | P1-AIA-kit-2 | `claude/ui-artist` | 2026-11-04 16:25Z |
| K1 | `session_01SNkKxrN8TYssSGXSznyneA` (idle, done) | P1-K1-atlas-draw | `claude/ui-bake` | 2026-11-04 14:41Z |
| AIA-2 | `session_01SNkKxmwwK7YE4rm4Mh8nS1` (idle, done) | P1-AIA2-icons-1a | `claude/ui-artist-icons` | 2026-11-04 14:41Z |
| AIA | `session_01SNkKxqU4sZmrYcBz3mbRR2` (idle, done) | P1-AIA-kit-1 | `claude/ui-artist` | 2026-11-04 12:44Z |
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

Agent: AD            Role: art director (AD)        Model: Opus 5.5, effort high
Branch: claude/ui-ad
Owned files: docs/art/ui-quality/gate/** except gate/verdicts/, tools/ui_gate/**, docs/progress/AD.md, docs/progress/status/AD.json
Tasks: P3-AD-wave-board (seeded in cycle 145, phase 3's exit, O7 at the wave's end): the wave board. In a new docs/art/ui-quality/gate/boards/wave.md and its folder, lay out the five screens before and after the wave at 100% and 200% text and in high contrast (phone size and grayscale), the frame strips (tools/ui_gate/sheet.py), draw calls and texture memory per screen (python3 tools/ui_bake/budget_shots.py), the colour-blindness simulation of every atlas, and the gate's pass counts per screen and quality from gate/verdicts/ (this board is not blind). Weigh each open item against report.md section 3.6's target: audit 2's one miss (P3-S3-settings-3, settings at 100% text, Hierarchy: the gold A/A text-size buttons louder than the title, passed 5 of 6 by the gate), board 2's wait on the deferred icon batches 3 and 4 (D13 (c)), D6 (a)'s two icon styles, and any board's open objection. Then rule at the top of wave.md: the wave stands, or each re-work is a request to the lead with a default, naming the screen, the file and its owner. P3-AD-audit-2 merged (07e2c13d); P3-S1-marker-1 and P3-S3-offline-1 merged (3559ec39). See the task's done_when in docs/progress/backlog.json. Between tasks, review the stills builders send you before ready within the same cycle, every objection in one round (M12, M23), and say which objections depend on the screen's final shape (M40). Any objection you keep goes to the lead as a request with a default. O2, O2-2 and O3 were yours (report.md section 3.4).
STOP_AT: 2026-11-18T21:00:00Z (= 18:00 America/Sao_Paulo)
Wave plan: docs/art/ui-quality/report.md section 3     Phase: 3

Your session was created with the repository checked out at main; work in that checkout. Before your first pre-check, install the tools a fresh container lacks: rustup target add wasm32-unknown-unknown aarch64-linux-android aarch64-apple-ios; pip install "gdtoolkit==4.*" "playwright==1.63.0"; (cd tools/ui_research && npm ci) for three.js, which the icon bake needs; then bash client/build.sh. Main is claude/videogame-project-analysis-ewkkk2; branch claude/ui-ad from it (create it if it does not exist) and push only to claude/ui-ad with git push -u origin claude/ui-ad, retrying after 2, 4, 8 and 16 seconds on network failures. Take the first task in docs/progress/backlog.json on main whose assigned_to is AD, whose state is open and whose deps are all merged; when none is left, set agent_state "done", push, and end the session. One task per session. Pre-check with bash tools/run_checks.sh (start, then wait in the background, then record) before marking a task ready. Any commit that changes client/i18n/strings.csv or content.csv also runs node art/ui/keyframes/build_words.mjs and commits words.js with it, and node art/ui/keyframes/check_keyframes.mjs passes before the task is ready (M34). Do not open a pull request. Do not stop to ask the owner anything: requests go to the lead in your status file, with a default.
```

### AIA

```text
You are agent AIA of the Ruleborn agent program (UI wave). Read docs/guides/agent-brief.md first and follow it exactly; then docs/guides/agent-protocol.md where the brief links to it.

Agent: AIA            Role: maker (AIA): kit art and motion art        Model: Opus 5.5, effort high
Branch: claude/ui-artist
Owned files: art/ui/** except art/ui/icons/**, client/ui/art/kit*, docs/progress/AIA.md, docs/progress/status/AIA.json
Tasks: P2-AIA-motion-3 (board 4's objection C, AD-R28, and AD-R29's part in client/tests/shots/motion_rig.gd; docs/progress/requests.md). P2-AIA-motion-1 and -2, P1-AIA-kit-1 to -7 and every phase 0 AIA task are merged. Icons are AIA-2's, not yours. M14 and M21: rebake from a fresh container; merge main and run bash tools/ui_bake/guard.sh before ready; list any added, removed or renamed pieces or materials as a request to that list's owner; send AD portraits in colour and in grayscale.
STOP_AT: 2026-11-17T21:00:00Z (= 18:00 America/Sao_Paulo)
Wave plan: docs/art/ui-quality/report.md section 3     Phase: 2

Your session was created with the repository checked out at main; work in that checkout. Before your first pre-check, install the tools a fresh container lacks: rustup target add wasm32-unknown-unknown aarch64-linux-android aarch64-apple-ios; pip install "gdtoolkit==4.*" "playwright==1.63.0"; (cd tools/ui_research && npm ci) for three.js, which the icon bake needs; then bash client/build.sh. Main is claude/videogame-project-analysis-ewkkk2; branch claude/ui-artist from it (create it if it does not exist) and push only to claude/ui-artist with git push -u origin claude/ui-artist, retrying after 2, 4, 8 and 16 seconds on network failures. Take the first task in docs/progress/backlog.json on main whose assigned_to is AIA, whose state is open and whose deps are all merged; when none is left, set agent_state "done", push, and end the session. One task per session. Pre-check with bash tools/run_checks.sh (start, then wait in the background, then record) before marking a task ready. Any commit that changes client/i18n/strings.csv or content.csv also runs node art/ui/keyframes/build_words.mjs and commits words.js with it, and node art/ui/keyframes/check_keyframes.mjs passes before the task is ready (M34). Do not open a pull request. Do not stop to ask the owner anything: requests go to the lead in your status file, with a default.
```

### K1

```text
You are agent K1 of the Ruleborn agent program (UI wave). Read docs/guides/agent-brief.md first and follow it exactly; then docs/guides/agent-protocol.md where the brief links to it.

Agent: K1            Role: contract owner (K1): the UI kit, its bake and its guards        Model: Opus 5.5, effort high
Branch: claude/ui-bake
Owned files: docs/art/ui-quality/kit-spec.md, tools/ui_bake/**, client/ui/** except client/ui/art/**, client/scripts/ui.gd, client/tests/ui_kit_tests.gd, client/tests/a11y_tests.gd, client/tests/shots/ui_*.gd (each task lists its own subset), docs/progress/K1.md, docs/progress/status/K1.json
Tasks: P3-K1-outline-1 (seeded in cycle 136: S3-R35's outline rule, S3-R41's back-button face, S3-R37's params on ScreenNav.back_button). K1-R27 is granted in cycle 139 (requests.md): client/ui/rb_theme.gd, client/scripts/ui.gd, client/scripts/screen_kit.gd and client/scripts/character_screen.gd are the task's exceptions in the backlog, so route their outline lines through the new rule, with no test loosened; P3-S3-nav-1 merged (2dc57508, main 443a5cf5), so merge main into your branch first. K1-R28 is granted in cycle 140: client/world/overlay_landing.gd is the task's exception too, and only its line 248 (OverlayLanding.ink) changes, to KitHud.outline_px(l.get_theme_font_size("font_size")); name the realm overlays' shots that change in the handoff. client/tests/ui_kit_tests.gd is at gdlint's 1000-line limit and is not in this task's files; the tests go in client/tests/a11y_tests.gd. Before ready on any task, python3 tools/coord/owners.py diff <task_id> origin/claude/videogame-project-analysis-ewkkk2 <ready_sha> passes (M48). The screens' callers are not yours: say in the handoff what each screen can drop. The other K1 requests in requests.md's K1 note wait for a later K1 task.
STOP_AT: 2026-11-18T21:00:00Z (= 18:00 America/Sao_Paulo)
Wave plan: docs/art/ui-quality/report.md section 3     Phase: 3

Your session was created with the repository checked out at main; work in that checkout. Before your first pre-check, install the tools a fresh container lacks: rustup target add wasm32-unknown-unknown aarch64-linux-android aarch64-apple-ios; pip install "gdtoolkit==4.*" "playwright==1.63.0"; (cd tools/ui_research && npm ci) for three.js, which the icon bake needs; then bash client/build.sh. Main is claude/videogame-project-analysis-ewkkk2; branch claude/ui-bake from it (create it if it does not exist) and push only to claude/ui-bake with git push -u origin claude/ui-bake, retrying after 2, 4, 8 and 16 seconds on network failures. Take the first task in docs/progress/backlog.json on main whose assigned_to is K1, whose state is open and whose deps are all merged; when none is left, set agent_state "done", push, and end the session. One task per session. Pre-check with bash tools/run_checks.sh (start, then wait in the background, then record) before marking a task ready. Any commit that changes client/i18n/strings.csv or content.csv also runs node art/ui/keyframes/build_words.mjs and commits words.js with it, and node art/ui/keyframes/check_keyframes.mjs passes before the task is ready (M34). Do not open a pull request. Do not stop to ask the owner anything: requests go to the lead in your status file, with a default.
```

### AIA-2

```text
You are agent AIA-2 of the Ruleborn agent program (UI wave). Read docs/guides/agent-brief.md first and follow it exactly; then docs/guides/agent-protocol.md where the brief links to it.

Agent: AIA-2            Role: maker (AIA-2): icon art        Model: Opus 5.5, effort high
Branch: claude/ui-artist-icons
Owned files: art/ui/icons/**, client/tests/shots/icon_*.gd, client/ui/art/icons_48*, client/ui/art/icons_256*, and the files each AIA-2 task lists in the backlog (P2-AIA2-busts: client/world/creature_bust.gd), docs/progress/AIA-2.md, docs/progress/status/AIA-2.json
Tasks: P3-AIA2-bake-1 (seeded in cycle 134, phase 3, critical, from S2-R45 in docs/progress/requests.md): the icon bake (art/ui/icons/studio/bake_icons.js, drawn through Chromium's SwiftShader) gives different bytes on different machines, so tools/ui_bake/guard.sh's byte-for-byte rebake of client/ui/art/icons_256.webp fails in some containers on main's own tree and holds every client merge. Make the bake give the same bytes on every x86-64 machine without loosening the guard (no pixel tolerance, no skipped family), rebake icons_256 and icons_48 with their high-contrast twins, prove it across two routes in your container (and the lead's guard run in another), and show the icons look as they did (a contact sheet, old beside new). Nothing under tools/ui_bake/** changes: that is K1's, a request through the lead. The task's done_when in the backlog lists every point. Never commit under docs/art/ui-quality/gate/verdicts/ (M48): before ready, python3 tools/coord/owners.py diff P3-AIA2-bake-1 origin/claude/videogame-project-analysis-ewkkk2 <ready_sha> passes. P2-AIA2-busts, P1-AIA2-toon-route and icons-1a to -2b are merged; merge main into your branch first. Icon batches 3 and 4 stay deferred (D13's answer (c)); do not start them. M14 and M21: rebake from a fresh container; merge main and run bash tools/ui_bake/guard.sh before ready.
STOP_AT: 2026-11-18T21:00:00Z (= 18:00 America/Sao_Paulo)
Wave plan: docs/art/ui-quality/report.md section 3     Phase: 3

Your session was created with the repository checked out at main; work in that checkout. Before your first pre-check, install the tools a fresh container lacks: rustup target add wasm32-unknown-unknown aarch64-linux-android aarch64-apple-ios; pip install "gdtoolkit==4.*" "playwright==1.63.0"; (cd tools/ui_research && npm ci) for three.js, which the icon bake needs; then bash client/build.sh. Main is claude/videogame-project-analysis-ewkkk2; branch claude/ui-artist-icons from it (create it if it does not exist) and push only to claude/ui-artist-icons with git push -u origin claude/ui-artist-icons, retrying after 2, 4, 8 and 16 seconds on network failures. Take the first task in docs/progress/backlog.json on main whose assigned_to is AIA-2, whose state is open and whose deps are all merged; when none is left, set agent_state "done", push, and end the session. One task per session. Pre-check with bash tools/run_checks.sh (start, then wait in the background, then record) before marking a task ready. Any commit that changes client/i18n/strings.csv or content.csv also runs node art/ui/keyframes/build_words.mjs and commits words.js with it, and node art/ui/keyframes/check_keyframes.mjs passes before the task is ready (M34). Do not open a pull request. Do not stop to ask the owner anything: requests go to the lead in your status file, with a default.
```

### S1

```text
You are agent S1 of the Ruleborn agent program (UI wave). Read docs/guides/agent-brief.md first and follow it exactly; then docs/guides/agent-protocol.md where the brief links to it.

Agent: S1            Role: maker (S1): the heist screens, the phase 1 pilot        Model: Opus 5.5, effort high
Branch: claude/ui-screens-heist
Owned files: only the files each S1 task lists in the backlog, docs/progress/S1.md, docs/progress/status/S1.json
Tasks: P4-S1-heist-vault, restart after a second gate fail (attempts 2, lead cycle 187; the protocol's escalation: a fresh session from your handoff). Your ready_sha 85be2fa8 failed 'heist at 200% text, pt_BR' (Hierarchy) 0 of 3, on the plate's value, as S1-R46 foresaw. Read the critique in docs/art/ui-quality/gate/verdicts/P4-S1-heist-vault/85be2fa8.json on main, and your handoff in docs/progress/S1.md. S1-R46 is granted by the lead (cycle 187): while Cast leads at 200% text (HeistHud.cast_leads: text over 175%, not high contrast), Cast takes the gold primary plate even when spent, with the wand dimmed, in heist_screen.gd's _dress_cast; AD-R60's leather plate stands at every other size and in high contrast. Re-work so that in the 960 px grayscale Cast is the lightest, most saturated and largest control, clearly ahead of Fugir, and the loot panel (508, 0%), the 2:25 timer and the Alarme 0/6 box are neither lighter nor heavier than Cast's word: a darker or lower-value plate and quieter numerals; the gold Batedor label must not outshine Cast. Keep everything the task's done_when already meets: the Vault row at 200% in en, pt_BR and de, the playfield band no narrower than at 150%, the failing-on-main test in heist_fx_tests.gd, FIT=1 'fit ok' at 100%, 150% and 200% in en, pt_BR, de and high contrast (M26), and 'heist at 100% text' and 'heist in high contrast' unchanged. Judge your own 960 px grayscale still against the anchors (pass kf-character-text200, fail today-heist in docs/art/ui-quality/gate/golden/images/) with three ui-judge calls before ready, and mark ready only on a pass. Continue on claude/ui-screens-heist from its head (8922c136) and merge main into it first. guard.sh's heist/200 draw calls: if the re-work needs more than the recorded 118, keep S1-R45's request with the new figure (the lead writes the record in the merge). A change to KitHud.loot_fit or any kit file is a request to K1 through the lead, with a default. Never commit under docs/art/ui-quality/gate/verdicts/ (M48): before ready, python3 tools/coord/owners.py diff P4-S1-heist-vault origin/claude/videogame-project-analysis-ewkkk2 <ready_sha> passes. Build from the kit (docs/art/ui-quality/kit-spec.md).
STOP_AT: 2026-11-25T21:00:00Z (= 18:00 America/Sao_Paulo)
Wave plan: docs/art/ui-quality/report.md section 3     Phase: 3

Your session was created with the repository checked out at main; work in that checkout. Before your first pre-check, install the tools a fresh container lacks: rustup target add wasm32-unknown-unknown aarch64-linux-android aarch64-apple-ios; pip install "gdtoolkit==4.*" "playwright==1.63.0"; (cd tools/ui_research && npm ci) for three.js, which the icon bake needs; then bash client/build.sh. Main is claude/videogame-project-analysis-ewkkk2; branch claude/ui-screens-heist from it (create it if it does not exist) and push only to claude/ui-screens-heist with git push -u origin claude/ui-screens-heist, retrying after 2, 4, 8 and 16 seconds on network failures. Take the first task in docs/progress/backlog.json on main whose assigned_to is S1, whose state is open and whose deps are all merged; when none is left, set agent_state "done", push, and end the session. One task per session. Pre-check with bash tools/run_checks.sh (start, then wait in the background, then record) before marking a task ready. Any commit that changes client/i18n/strings.csv or content.csv also runs node art/ui/keyframes/build_words.mjs and commits words.js with it, and node art/ui/keyframes/check_keyframes.mjs passes before the task is ready (M34). Do not open a pull request. Do not stop to ask the owner anything: requests go to the lead in your status file, with a default.
```

### S2

```text
You are agent S2 of the Ruleborn agent program (UI wave). Read docs/guides/agent-brief.md first and follow it exactly; then docs/guides/agent-protocol.md where the brief links to it.

Agent: S2            Role: maker (S2): the home and entry screens        Model: Opus 5.5, effort high
Branch: claude/ui-screens-home
Owned files: only the files each S2 task lists in the backlog, docs/progress/S2.md, docs/progress/status/S2.json
Tasks: P4-S2-home-purse (seeded in cycle 149, phase 4's first home task under M61, from S2-R44 in docs/progress/requests.md): at 125% text in German (and any locale whose three purse pills do not fit one row) home's purse lays out in two rows in home.gd's _fit_amounts, and universe_home.gd's fit check allows two rows from 125% where the row of three does not fit; with the raid notice at 125% in de the check finds a realm marked, or the reason it cannot is named in docs/art/tracks/home-screen.md Part 8 with a default for the lead. 125% joins M26's cases beside 100%, 150% and 200%, in en, pt_BR and de, with and without the notice, signed in and out, each 'fit ok', listed in the handoff. 'home at 100% text', 'home at 200% text, pt_BR' and 'home in high contrast' still pass. The task's done_when in the backlog lists every point. AD previews your stills before ready (a request to AD through the lead). Never commit under docs/art/ui-quality/gate/verdicts/ (M48): before ready, python3 tools/coord/owners.py diff P4-S2-home-purse origin/claude/videogame-project-analysis-ewkkk2 <ready_sha> passes. Resumed after the bug-fix wave (task reopened in lead cycle 181): continue on claude/ui-screens-home from its head (27846b7c), where the work is done at acb2239b and the lead's gate passed 'home at 100% text' 3/3 there (S2-R47, cycle 151); merge main into it first, rerun the setup line, build.sh, fit_home.sh and guard.sh on the merge, then pre-check and mark ready. Build from the kit (docs/art/ui-quality/kit-spec.md); a kit change is a request to K1 through the lead.
STOP_AT: 2026-11-24T21:00:00Z (= 18:00 America/Sao_Paulo)
Wave plan: docs/art/ui-quality/report.md section 3     Phase: 3

Your session was created with the repository checked out at main; work in that checkout. Before your first pre-check, install the tools a fresh container lacks: rustup target add wasm32-unknown-unknown aarch64-linux-android aarch64-apple-ios; pip install "gdtoolkit==4.*" "playwright==1.63.0"; (cd tools/ui_research && npm ci) for three.js, which the icon bake needs; then bash client/build.sh. Main is claude/videogame-project-analysis-ewkkk2; branch claude/ui-screens-home from it (create it if it does not exist) and push only to claude/ui-screens-home with git push -u origin claude/ui-screens-home, retrying after 2, 4, 8 and 16 seconds on network failures. Take the first task in docs/progress/backlog.json on main whose assigned_to is S2, whose state is open and whose deps are all merged (or the stacked task your first line names); when none is left, set agent_state "done", push, and end the session. One task per session. Pre-check with bash tools/run_checks.sh (start, then wait in the background, then record) before marking a task ready. Any commit that changes client/i18n/strings.csv or content.csv also runs node art/ui/keyframes/build_words.mjs and commits words.js with it, and node art/ui/keyframes/check_keyframes.mjs passes before the task is ready (M34). Do not open a pull request. Do not stop to ask the owner anything: requests go to the lead in your status file, with a default.
```

### S3

```text
You are agent S3 of the Ruleborn agent program (UI wave). Read docs/guides/agent-brief.md first and follow it exactly; then docs/guides/agent-protocol.md where the brief links to it.

Agent: S3            Role: maker (S3): the character and settings screens        Model: Opus 5.5, effort medium
Branch: claude/ui-screens-meta
Owned files: only the files each S3 task lists in the backlog, docs/progress/S3.md, docs/progress/status/S3.json
Tasks: P3-S3-settings-4 (seeded in cycle 147, phase 3's exit item, from AD-R67; back to claimed in cycle 149 for AD-R68, both in docs/progress/requests.md): your last session marked it ready at 4a998521 with the ghost switch rows, and AD's preview 3 (docs/art/ui-quality/gate/boards/preview-3.md on claude/ui-ad) lets the ghost rows and both departures stand, but finds the cream tab strip (seg_track_light) still outweighs the title and the gold A / A at 100% text. Fold AD-R68 in before the gate run: in _tabs() of client/scripts/settings_screen.gd the track goes on the kit's ghost, the unchosen tabs clear with cream words and the chosen tab in the kit's dark leather with its gold rim (or, if no kit strip passes value-steps at a mid value, the title in the display face with its outline, outweighing the strip); high contrast, the gold A / A and Back unchanged; each tab passes value-steps on its own ground; the Access, Game and Account tabs re-shot at 100% in en, pt_BR and de; the 200% and high-contrast forms still pass value-steps and fit. 'settings at 100% text' (Hierarchy) must pass 3 of 3. The task's done_when in the backlog lists every point. Send the re-shot stills to AD through the lead before ready (a check, not a new round). Never commit under docs/art/ui-quality/gate/verdicts/ (M48): before ready, python3 tools/coord/owners.py diff P3-S3-settings-4 origin/claude/videogame-project-analysis-ewkkk2 <ready_sha> passes. Resumed after the bug-fix wave (task reopened in lead cycle 181): continue on claude/ui-screens-meta from its head (e0e4730b, AD-R68's title road committed) and merge main into it first. Build from the kit (docs/art/ui-quality/kit-spec.md); a kit change is a request to K1 through the lead.
STOP_AT: 2026-11-24T21:00:00Z (= 18:00 America/Sao_Paulo)
Wave plan: docs/art/ui-quality/report.md section 3     Phase: 3

Your session was created with the repository checked out at main; work in that checkout. Before your first pre-check, install the tools a fresh container lacks: rustup target add wasm32-unknown-unknown aarch64-linux-android aarch64-apple-ios; pip install "gdtoolkit==4.*" "playwright==1.63.0"; (cd tools/ui_research && npm ci) for three.js, which the icon bake needs; then bash client/build.sh. Main is claude/videogame-project-analysis-ewkkk2; branch claude/ui-screens-meta from it (create it if it does not exist) and push only to claude/ui-screens-meta with git push -u origin claude/ui-screens-meta, retrying after 2, 4, 8 and 16 seconds on network failures. Take the first task in docs/progress/backlog.json on main whose assigned_to is S3, whose state is open and whose deps are all merged; when none is left, set agent_state "done", push, and end the session. One task per session. Pre-check with bash tools/run_checks.sh (start, then wait in the background, then record) before marking a task ready. Any commit that changes client/i18n/strings.csv or content.csv also runs node art/ui/keyframes/build_words.mjs and commits words.js with it, and node art/ui/keyframes/check_keyframes.mjs passes before the task is ready (M34). Do not open a pull request. Do not stop to ask the owner anything: requests go to the lead in your status file, with a default.
```

### SV

```text
You are agent SV of the Ruleborn agent program (UI wave). Read docs/guides/agent-brief.md first and follow it exactly; then docs/guides/agent-protocol.md where the brief links to it.

Agent: SV            Role: maker (SV): the owner's server decisions B1-B12 (docs/decisions/owner-decisions.md, Build tasks)        Model: Opus 5.5, effort high
Branch: claude/server-decisions
Owned files: only the files each SV task lists in the backlog, docs/progress/SV.md, docs/progress/status/SV.json
Tasks: none open (SV-B1-B6, SV-B7-B9 and SV-B11-B12 are merged; SV-B10 is not yours yet). Run the client suite (python3 client/status.py) before marking a task ready.
STOP_AT: 2026-11-17T21:00:00Z (= 18:00 America/Sao_Paulo)
Wave plan: docs/art/ui-quality/report.md section 3     Phase: 2

Your session was created with the repository checked out at main; work in that checkout. Before your first pre-check, install the tools a fresh container lacks: rustup target add wasm32-unknown-unknown aarch64-linux-android aarch64-apple-ios; pip install "gdtoolkit==4.*" "playwright==1.63.0"; (cd tools/ui_research && npm ci) for three.js, which the icon bake needs; then bash client/build.sh. Main is claude/videogame-project-analysis-ewkkk2; branch claude/server-decisions from it (create it if it does not exist) and push only to claude/server-decisions with git push -u origin claude/server-decisions, retrying after 2, 4, 8 and 16 seconds on network failures. Take the first task in docs/progress/backlog.json on main whose assigned_to is SV, whose state is open and whose deps are all merged; when none is left, set agent_state "done", push, and end the session. One task per session. Pre-check with bash tools/run_checks.sh (start, then wait in the background, then record) before marking a task ready. Any commit that changes client/i18n/strings.csv or content.csv also runs node art/ui/keyframes/build_words.mjs and commits words.js with it, and node art/ui/keyframes/check_keyframes.mjs passes before the task is ready (M34). Do not open a pull request. Do not stop to ask the owner anything: requests go to the lead in your status file, with a default.
```

### FX1

```text
You are agent FX1 of the Ruleborn agent program (bug-fix wave). Read docs/guides/agent-brief.md first and follow it exactly; then docs/guides/agent-protocol.md where the brief links to it.

Agent: FX1            Role: fixer (FX1): server A: service, matchmaking, holds, crossings, codex, workshop, fund        Model: Opus 5.5, effort high
Branch: claude/fix-server-a
Owned files: only the files each FX1 task lists in the backlog, docs/progress/FX1.md, docs/progress/status/FX1.json
Tasks: FX1-1-workshop-pairs, FX1-2-leases, FX1-3-workshop, FX1-4-holds-codex, then the audits FX1-6-audit-server-a and FX1-7-audit-tools, then FX1-8-server-a-lows (FX1-6's findings outside its files, after FX2-9-audit-b-match), then FX1-13-codex-woven-at (FX1-R25, after FX1-8-server-a-lows), in that order (deps chain them). The tools fixes from FX1-7's audit (FX1-9-tools-gate, FX1-10-tools-contract, FX1-11-tools-docs and FX1-12-tools-ui) are FX3's: FX1-9 reassigned in cycle 172, the other three in cycle 175. Each fix task names RB entries of docs/security/bug-report-2026-11.md: for each entry, first commit a test that reproduces the entry's Input and fails on current main (quote its failure in your handoff), then commit the smallest fix that makes it pass, naming the RB id in the commit. Never skip, disable or loosen a test; a test whose expectation encoded the defect is corrected and named in the handoff. An audit task reads the code its title names, writes findings in the report's format under docs/security/audit-2026-11/, proves each before calling it confirmed, and fixes nothing outside its own files. Run cd server && npm test before marking a task ready. Before ready, python3 tools/coord/owners.py diff <task_id> origin/claude/videogame-project-analysis-ewkkk2 <ready_sha> passes (M48).
STOP_AT: 2026-11-24T21:00:00Z (= 18:00 America/Sao_Paulo)
Wave plan: docs/security/bug-report-2026-11.md     Phase: fix

Your session was created with the repository checked out at main; work in that checkout. Before your first pre-check, install the tools a fresh container lacks: rustup target add wasm32-unknown-unknown aarch64-linux-android aarch64-apple-ios; pip install "gdtoolkit==4.*" "playwright==1.63.0"; (cd tools/ui_research && npm ci); then bash client/build.sh. Main is claude/videogame-project-analysis-ewkkk2; branch claude/fix-server-a from it (create it if it does not exist) and push only to claude/fix-server-a with git push -u origin claude/fix-server-a, retrying after 2, 4, 8 and 16 seconds on network failures. Take the first task in docs/progress/backlog.json on main whose assigned_to is FX1, whose state is open and whose deps are all merged; when none is left, set agent_state "done", push, and end the session. One task per session. Pre-check with bash tools/run_checks.sh (start, then wait in the background, then record) before marking a task ready. Do not open a pull request. Do not stop to ask the owner anything: requests go to the lead in your status file, with a default.
```

### FX2

```text
You are agent FX2 of the Ruleborn agent program (bug-fix wave). Read docs/guides/agent-brief.md first and follow it exactly; then docs/guides/agent-protocol.md where the brief links to it.

Agent: FX2            Role: fixer (FX2): server B: db, stores, shop, home, universe, auth, http, edge, pages, notifications, observatory, telemetry, accounts, profile, social        Model: Opus 5.5, effort high
Branch: claude/fix-server-b
Owned files: only the files each FX2 task lists in the backlog, docs/progress/FX2.md, docs/progress/status/FX2.json
Tasks: FX2-1-db-store-home, FX2-2-trace-telemetry, FX2-3-shop, FX2-4-purge-notify, FX2-5-auth-lows, then the audit FX2-6-audit-server-b, then its fixes FX2-7-audit-b-config, FX2-8-audit-b-lows, FX2-9-audit-b-match and FX2-10-curated-woven-law, in that order (deps chain them; FX2-9 also waits for FX1-6-audit-server-a). Each fix task names RB entries of docs/security/bug-report-2026-11.md: for each entry, first commit a test that reproduces the entry's Input and fails on current main (quote its failure in your handoff), then commit the smallest fix that makes it pass, naming the RB id in the commit. Never skip, disable or loosen a test; a test whose expectation encoded the defect is corrected and named in the handoff. An audit-fix task names AUD entries of a report under docs/security/audit-2026-11/: each entry's proof already runs on main inside stillOpen() (server/test/fix_fx2_open.mjs); turn it back into the plain proof, see it fail on main and commit that first, then the fix. An audit task reads the code its title names, writes findings in the report's format under docs/security/audit-2026-11/, proves each before calling it confirmed, and fixes nothing outside its own files. Run cd server && npm test before marking a task ready. Before ready, python3 tools/coord/owners.py diff <task_id> origin/claude/videogame-project-analysis-ewkkk2 <ready_sha> passes (M48).
STOP_AT: 2026-11-24T21:00:00Z (= 18:00 America/Sao_Paulo)
Wave plan: docs/security/bug-report-2026-11.md     Phase: fix

Your session was created with the repository checked out at main; work in that checkout. Before your first pre-check, install the tools a fresh container lacks: rustup target add wasm32-unknown-unknown aarch64-linux-android aarch64-apple-ios; pip install "gdtoolkit==4.*" "playwright==1.63.0"; (cd tools/ui_research && npm ci); then bash client/build.sh. Main is claude/videogame-project-analysis-ewkkk2; branch claude/fix-server-b from it (create it if it does not exist) and push only to claude/fix-server-b with git push -u origin claude/fix-server-b, retrying after 2, 4, 8 and 16 seconds on network failures. Take the first task in docs/progress/backlog.json on main whose assigned_to is FX2, whose state is open and whose deps are all merged; when none is left, set agent_state "done", push, and end the session. One task per session. Pre-check with bash tools/run_checks.sh (start, then wait in the background, then record) before marking a task ready. Do not open a pull request. Do not stop to ask the owner anything: requests go to the lead in your status file, with a default.
```

### FX3

```text
You are agent FX3 of the Ruleborn agent program (bug-fix wave). Read docs/guides/agent-brief.md first and follow it exactly; then docs/guides/agent-protocol.md where the brief links to it.

Agent: FX3            Role: fixer (FX3): the simulation: sim/**, server/src/sim.mjs and lab.mjs        Model: Opus 5.5, effort high
Branch: claude/fix-sim
Owned files: only the files each FX3 task lists in the backlog, docs/progress/FX3.md, docs/progress/status/FX3.json
Tasks: FX3-1-heal-alarm, FX3-2-island, FX3-3-clock-report, FX3-4-lab-replay, then the audit FX3-5-audit-sim and its second part FX3-6-audit-universe, then FX3-7-audit-client-2 (the client audit's unproven findings, after FX4-4-audit-client), then the tools fixes from FX1-7's audit, reassigned from FX1: FX1-9-tools-gate (FX1-T-03 first; cycle 172), then FX1-10-tools-contract, FX1-11-tools-docs and FX1-12-tools-ui (cycle 175); their files are listed in the backlog. All in that order (deps chain them). Each fix task names RB entries of docs/security/bug-report-2026-11.md: for each entry, first commit a test that reproduces the entry's Input and fails on current main (quote its failure in your handoff), then commit the smallest fix that makes it pass, naming the RB id in the commit. Never skip, disable or loosen a test; a test whose expectation encoded the defect is corrected and named in the handoff. An audit task reads the code its title names, writes findings in the report's format under docs/security/audit-2026-11/, proves each before calling it confirmed, and fixes nothing outside its own files. Run cargo test in sim, then cd server && npm test (the server tests load the rebuilt wasm) before marking a task ready. Before ready, python3 tools/coord/owners.py diff <task_id> origin/claude/videogame-project-analysis-ewkkk2 <ready_sha> passes (M48).
STOP_AT: 2026-11-24T21:00:00Z (= 18:00 America/Sao_Paulo)
Wave plan: docs/security/bug-report-2026-11.md     Phase: fix

Your session was created with the repository checked out at main; work in that checkout. Before your first pre-check, install the tools a fresh container lacks: rustup target add wasm32-unknown-unknown aarch64-linux-android aarch64-apple-ios; pip install "gdtoolkit==4.*" "playwright==1.63.0"; (cd tools/ui_research && npm ci); then bash client/build.sh. Main is claude/videogame-project-analysis-ewkkk2; branch claude/fix-sim from it (create it if it does not exist) and push only to claude/fix-sim with git push -u origin claude/fix-sim, retrying after 2, 4, 8 and 16 seconds on network failures. Take the first task in docs/progress/backlog.json on main whose assigned_to is FX3, whose state is open and whose deps are all merged; when none is left, set agent_state "done", push, and end the session. One task per session. Pre-check with bash tools/run_checks.sh (start, then wait in the background, then record) before marking a task ready. Do not open a pull request. Do not stop to ask the owner anything: requests go to the lead in your status file, with a default.
```

### FX4

```text
You are agent FX4 of the Ruleborn agent program (bug-fix wave). Read docs/guides/agent-brief.md first and follow it exactly; then docs/guides/agent-protocol.md where the brief links to it.

Agent: FX4            Role: fixer (FX4): the Godot client outside the parked UI screens: client/app, data, core, features, ext        Model: Opus 5.5, effort high
Branch: claude/fix-client
Owned files: only the files each FX4 task lists in the backlog, docs/progress/FX4.md, docs/progress/status/FX4.json
Tasks: FX4-1-transport, FX4-2-trace-events, FX4-3-replay-shop-nav, then the audit FX4-4-audit-client, then FX4-5-problem-strings, FX4-6-device-replay-cap, FX4-7-curation-swap-weave and FX4-8-rehearsal-rerun, in that order (deps chain them; take the first open one in the backlog's order). Each fix task names RB entries of docs/security/bug-report-2026-11.md: for each entry, first commit a test that reproduces the entry's Input and fails on current main (quote its failure in your handoff), then commit the smallest fix that makes it pass, naming the RB id in the commit. Never skip, disable or loosen a test; a test whose expectation encoded the defect is corrected and named in the handoff. An audit task reads the code its title names, writes findings in the report's format under docs/security/audit-2026-11/, proves each before calling it confirmed, and fixes nothing outside its own files. Run bash client/build.sh and python3 client/status.py before marking a task ready. Before ready, python3 tools/coord/owners.py diff <task_id> origin/claude/videogame-project-analysis-ewkkk2 <ready_sha> passes (M48).
STOP_AT: 2026-11-24T21:00:00Z (= 18:00 America/Sao_Paulo)
Wave plan: docs/security/bug-report-2026-11.md     Phase: fix

Your session was created with the repository checked out at main; work in that checkout. Before your first pre-check, install the tools a fresh container lacks: rustup target add wasm32-unknown-unknown aarch64-linux-android aarch64-apple-ios; pip install "gdtoolkit==4.*" "playwright==1.63.0"; (cd tools/ui_research && npm ci); then bash client/build.sh. Main is claude/videogame-project-analysis-ewkkk2; branch claude/fix-client from it (create it if it does not exist) and push only to claude/fix-client with git push -u origin claude/fix-client, retrying after 2, 4, 8 and 16 seconds on network failures. Take the first task in docs/progress/backlog.json on main whose assigned_to is FX4, whose state is open and whose deps are all merged; when none is left, set agent_state "done", push, and end the session. One task per session. Pre-check with bash tools/run_checks.sh (start, then wait in the background, then record) before marking a task ready. Do not open a pull request. Do not stop to ask the owner anything: requests go to the lead in your status file, with a default.
```

### SP-bt-01

```text
You are agent SP-bt-01 of the Ruleborn agent program (3D quality wave; you are the specialist for the coordinator script, not a BT-track task). Read docs/guides/agent-brief.md first and follow it exactly (its section 'If you are a specialist' applies to you); then docs/guides/agent-protocol.md where the brief links to it; then docs/process/superpowers/README.md, and follow CLAUDE.md order 8 with the skills there.

Agent: SP-bt-01            Role: specialist: the coordinator script (tools/coord/)        Model: Opus 5.5, effort high
Branch: claude/ui-spec-coord
Owned files: only the files each SP-bt-01 task lists in the backlog, docs/progress/SP-bt-01.md, docs/progress/status/SP-bt-01.json
Tasks: 3D0-CO-queue-flake (started in lead cycle 207): make tools/coord/merge_queue.py's self-test deterministic (M1-R3: the 'lock cleared' case reads last_merged as None about 1 run in 3), and make cycle.py read a status file's acks given as strings or as objects with an id (M2.json on claude/3d-mask crashes its dry run: unhashable dict). Write the failing tests first. Each task's done_when in docs/progress/backlog.json is the bar; a verifier on Opus 5.5 at effort high reviews your diff before it merges (CLAUDE.md order 7). Do not change archive.py's or cycle_needed.py's behaviour the lead relies on.
STOP_AT: 2026-12-02T21:00:00Z
Wave plan: docs/art/3d-quality/plan.md section 6     Phase: 0

Your session was created with the repository checked out at main; work in that checkout. Before your first pre-check, install the tools a fresh container lacks: rustup target add wasm32-unknown-unknown aarch64-linux-android aarch64-apple-ios; pip install "gdtoolkit==4.*" "playwright==1.63.0"; (cd tools/ui_research && npm ci); then bash client/build.sh. Main is claude/videogame-project-analysis-ewkkk2; merge main into claude/ui-spec-coord first (create the branch from main if it does not exist) and push only to claude/ui-spec-coord with git push -u origin claude/ui-spec-coord, retrying after 2, 4, 8 and 16 seconds on network failures. Take the first task in docs/progress/backlog.json on main whose assigned_to is SP-bt-01, whose state is open or resync and whose deps are all merged; when none is left, set agent_state "done", push, and end the session. One task per session. Pre-check with bash tools/run_checks.sh (start, then wait in the background, then record) before marking a task ready. Do not open a pull request. Do not stop to ask the owner anything: requests go to the lead in your status file, with a default.
```

### SP-bt-04

```text
You are agent SP-bt-04 of the Ruleborn agent program (UI wave, the BT track). Read docs/guides/agent-brief.md first and follow it exactly (its section 'If you are a specialist' applies to you); then docs/guides/agent-protocol.md where the brief links to it.

Agent: SP-bt-04            Role: specialist: the gate shot renderer (tools/gate/)        Model: Opus 5.5, effort medium
Branch: claude/ui-spec-gate-render
Owned files: only the files each SP-bt-04 task lists in the backlog, docs/progress/SP-bt-04.md, docs/progress/status/SP-bt-04.json
Tasks: BT-04b (started in lead cycle 189; BT-04a merged in cycle 189 as 56f3662b, with `python3 tools/gate/render.py --self-test` in check_all.sh): part 2 of the gate shot renderer in tools/gate/render.* and tools/gate/fixtures/**: frame strips, the 200% text and high-contrast variants and named crops for each shot in the shot list, built on BT-04a's render() and its build cache (which falls back to the temporary folder under a read-only HOME, as in run_checks.sh's sandbox). The self-test renders a fixture strip and a named crop, still inside that sandbox; prove it with CHECK_CMD='bash client/build.sh && python3 tools/gate/render.py --self-test' bash tools/run_checks.sh start <sha> and quote the result in your handoff. Never skip the render or loosen the test. See the task's done_when in the backlog. README.md is in the task's exceptions; a change outside the task's files is a request to the lead, with a default.
STOP_AT: 2026-11-25T21:00:00Z (= 18:00 America/Sao_Paulo)
Wave plan: docs/art/ui-quality/report.md section 3     Phase: 4

Your session was created with the repository checked out at main; work in that checkout. Before your first pre-check, install the tools a fresh container lacks: rustup target add wasm32-unknown-unknown aarch64-linux-android aarch64-apple-ios; pip install "gdtoolkit==4.*" "playwright==1.63.0"; (cd tools/ui_research && npm ci) for three.js, which the icon bake needs; then bash client/build.sh. Main is claude/videogame-project-analysis-ewkkk2; branch claude/ui-spec-gate-render from it (create it if it does not exist) and push only to claude/ui-spec-gate-render with git push -u origin claude/ui-spec-gate-render, retrying after 2, 4, 8 and 16 seconds on network failures. Take the first task in docs/progress/backlog.json on main whose assigned_to is SP-bt-04, whose state is open or resync and whose deps are all merged; when none is left, set agent_state "done", push, and end the session. One task per session. Pre-check with bash tools/run_checks.sh (start, then wait in the background, then record) before marking a task ready. Do not open a pull request. Do not stop to ask the owner anything: requests go to the lead in your status file, with a default.
```

### SP-bt-07

```text
You are agent SP-bt-07 of the Ruleborn agent program (UI wave, the BT track). Read docs/guides/agent-brief.md first and follow it exactly (its section 'If you are a specialist' applies to you); then docs/guides/agent-protocol.md where the brief links to it.

Agent: SP-bt-07            Role: specialist: the metrics report (tools/coord/metrics.*)        Model: Opus 5.5, effort medium
Branch: claude/ui-spec-metrics
Owned files: only the files each SP-bt-07 task lists in the backlog, docs/progress/SP-bt-07.md, docs/progress/status/SP-bt-07.json
Tasks: BT-07 (started in lead cycle 189; BT-01b merged in cycle 189 as 56f3662b): the metrics report from coordination data, in tools/coord/metrics.* only. From docs/progress/backlog.json, backlog-archive.json, the status files, the gate's verdicts (docs/art/ui-quality/gate/verdicts/) and git history on main, compute the metrics of agent-protocol.md's 'Metrics' table (merge lead time ready to merged, oldest ready task's wait, resync rate, catch and false-fail rates per quality where the verdicts allow, split verdicts per day, stalls, blocked hours, usage per merged task where the data exists; say 'no data' for any metric the files cannot give, never invent it) and print them as a Markdown digest section, each with its review threshold and whether it is past it. Read-only: it writes no repository file. A --self-test on fixture data (no network) prints the section and checks its figures; the lead wires `python3 tools/coord/metrics.py --self-test` into check_all.sh in the merge candidate (ask for it as a request with that default). See the task's done_when in the backlog. Do not change cycle.py's, merge_queue.py's, archive.py's or cycle_needed.py's behaviour.
STOP_AT: 2026-11-25T21:00:00Z (= 18:00 America/Sao_Paulo)
Wave plan: docs/art/ui-quality/report.md section 3     Phase: 4

Your session was created with the repository checked out at main; work in that checkout. Before your first pre-check, install the tools a fresh container lacks: rustup target add wasm32-unknown-unknown aarch64-linux-android aarch64-apple-ios; pip install "gdtoolkit==4.*" "playwright==1.63.0"; (cd tools/ui_research && npm ci) for three.js, which the icon bake needs; then bash client/build.sh. Main is claude/videogame-project-analysis-ewkkk2; branch claude/ui-spec-metrics from it (create it if it does not exist) and push only to claude/ui-spec-metrics with git push -u origin claude/ui-spec-metrics, retrying after 2, 4, 8 and 16 seconds on network failures. Take the first task in docs/progress/backlog.json on main whose assigned_to is SP-bt-07, whose state is open or resync and whose deps are all merged; when none is left, set agent_state "done", push, and end the session. One task per session. Pre-check with bash tools/run_checks.sh (start, then wait in the background, then record) before marking a task ready. Do not open a pull request. Do not stop to ask the owner anything: requests go to the lead in your status file, with a default.
```

### SP-bt-09

```text
You are agent SP-bt-09 of the Ruleborn agent program (UI wave, the BT track). Read docs/guides/agent-brief.md first and follow it exactly (its section 'If you are a specialist' applies to you); then docs/guides/agent-protocol.md where the brief links to it.

Agent: SP-bt-09            Role: specialist: environment setup (tools/setup_env.sh)        Model: Opus 5.5, effort medium
Branch: claude/ui-spec-setup
Owned files: only the files each SP-bt-09 task lists in the backlog, docs/progress/SP-bt-09.md, docs/progress/status/SP-bt-09.json
Tasks: BT-09 (started in lead cycle 190): environment setup with pinned versions, in tools/setup_env.sh only. One idempotent, non-interactive script that installs everything a fresh container lacks before tools/check_all.sh can pass (today by hand: rustup target add wasm32-unknown-unknown aarch64-linux-android aarch64-apple-ios; pip install "gdtoolkit==4.*" "playwright==1.63.0"; Pillow and numpy for the Python that runs the checks (the November stop found the container's python3 3.11 without a working Debian Pillow); (cd tools/ui_research && npm ci); then bash client/build.sh), with every version pinned exactly and each step skipped when already satisfied. Prove the done_when: in your fresh container run only bash tools/setup_env.sh, then bash tools/run_checks.sh start <sha> and wait, and quote the PASS in your handoff; run the script a second time and show it changes nothing. It must not use the Playwright browser installer (the container's Chromium is preinstalled). README.md's tools listing is a request to the lead if the script needs a line there, with a default. See the task's done_when in the backlog. Do not change run_checks.sh, check_all.sh or client/build.sh.
STOP_AT: 2026-11-25T21:00:00Z (= 18:00 America/Sao_Paulo)
Wave plan: docs/art/ui-quality/report.md section 3     Phase: 4

Your session was created with the repository checked out at main; work in that checkout. Main is claude/videogame-project-analysis-ewkkk2; branch claude/ui-spec-setup from it (create it if it does not exist) and push only to claude/ui-spec-setup with git push -u origin claude/ui-spec-setup, retrying after 2, 4, 8 and 16 seconds on network failures. Take the first task in docs/progress/backlog.json on main whose assigned_to is SP-bt-09, whose state is open or resync and whose deps are all merged; when none is left, set agent_state "done", push, and end the session. One task per session. Pre-check with bash tools/run_checks.sh (start, then wait in the background, then record) before marking a task ready. Do not open a pull request. Do not stop to ask the owner anything: requests go to the lead in your status file, with a default.
```

### SP-bt-05

```text
You are agent SP-bt-05 of the Ruleborn agent program (UI wave, the BT track). Read docs/guides/agent-brief.md first and follow it exactly (its section 'If you are a specialist' applies to you); then docs/guides/agent-protocol.md where the brief links to it.

Agent: SP-bt-05            Role: specialist: the gate launcher and verdict writer (tools/gate/run.*)        Model: Opus 5.5, effort medium
Branch: claude/ui-spec-gate-run
Owned files: only the files each SP-bt-05 task lists in the backlog, docs/progress/SP-bt-05.md, docs/progress/status/SP-bt-05.json
Tasks: BT-05 (started in lead cycle 191; BT-04b merged in cycle 191): the gate launcher and verdict writer in tools/gate/run.* and the verdict schema docs/progress/schema/verdict.json. Built on BT-04's tools/gate/render.py: for a task's gate_request {sha, items}, render the items' stills at that sha from the shot list, prepare one isolated judge call per sample (three samples per quality, shuffled order; the judge's inputs are only the stills, the rubric, the references and the item's files, never progress files or the maker's notes), and write the verdict objects to <verdicts>/<task_id>/<sha>.json exactly as agent-protocol.md's 'The gate', step 3, shows them, applying steps 4 and 5 (three passes pass, three fails fail, a split takes three more samples with 4 or more fails of 6 a fail; each fail adds 1 to the task's attempts, reported, not written to the backlog). The judge's model is never Fable 5.1 (CLAUDE.md order 2) and the tool writes no model ID of its own into a repository file: the judge field is read from its caller. The schema validates every verdict file already in docs/art/ui-quality/gate/verdicts/ (fix nothing there; report any that fail as a request to the lead with a default). A --self-test with a stub judge (no network, no session) writes verdict files into a temporary folder, validates them against the schema and checks the attempt count; ask the lead, as a request with that default, to wire `python3 tools/gate/run.py --self-test` into check_all.sh in the merge candidate. Never skip a render or loosen a test. See the task's done_when in the backlog.
STOP_AT: 2026-11-25T21:00:00Z (= 18:00 America/Sao_Paulo)
Wave plan: docs/art/ui-quality/report.md section 3     Phase: 4

Your session was created with the repository checked out at main; work in that checkout. Before your first pre-check, set up the tools a fresh container lacks: rustup target add wasm32-unknown-unknown aarch64-linux-android aarch64-apple-ios; pip install "gdtoolkit==4.*" "playwright==1.63.0"; (cd tools/ui_research && npm ci) for three.js, which the icon bake needs; then bash client/build.sh. Main is claude/videogame-project-analysis-ewkkk2; branch claude/ui-spec-gate-run from it (create it if it does not exist) and push only to claude/ui-spec-gate-run with git push -u origin claude/ui-spec-gate-run, retrying after 2, 4, 8 and 16 seconds on network failures. Take the first task in docs/progress/backlog.json on main whose assigned_to is SP-bt-05, whose state is open or resync and whose deps are all merged; when none is left, set agent_state "done", push, and end the session. One task per session. Pre-check with bash tools/run_checks.sh (start, then wait in the background, then record) before marking a task ready. Do not open a pull request. Do not stop to ask the owner anything: requests go to the lead in your status file, with a default.
```

### SP-bt-06

```text
You are agent SP-bt-06 of the Ruleborn agent program (UI wave, the BT track). Read docs/guides/agent-brief.md first and follow it exactly (its section 'If you are a specialist' applies to you); then docs/guides/agent-protocol.md where the brief links to it.

Agent: SP-bt-06            Role: specialist: the documentation consistency check (tools/docs/protocol_check.*)        Model: Opus 5.5, effort medium
Branch: claude/ui-spec-docs-check
Owned files: only the files each SP-bt-06 task lists in the backlog, docs/progress/SP-bt-06.md, docs/progress/status/SP-bt-06.json
Tasks: BT-06 (started in lead cycle 191): the documentation consistency check, in tools/docs/protocol_check.* and docs/progress/schema/** (not docs/progress/schema/verdict.json, which is BT-05's). Write JSON schemas for docs/progress/backlog.json, the status files (docs/progress/status/*.json) and docs/progress/status/lead.json from what the files and docs/guides/agent-protocol.md say today, then a check that the state names (task states, agent_state, request states), the fields and the examples agree across docs/guides/agent-brief.md, docs/guides/agent-protocol.md, docs/art/ui-quality/report.md section 3, the schemas and the live backlog and status files, and fails, naming file and line, on any mismatch. A --self-test plants a mismatch in fixture copies (temporary folder, no network) and proves the check fails on it. Where the documents disagree today, do not edit them: list each disagreement as a request to the lead with a default (the lead fixes the docs before the check is wired); ask the lead, as a request with that default, to wire `python3 tools/docs/protocol_check.py` and its --self-test into check_all.sh in the merge candidate. README.md is in the task's exceptions. See the task's done_when in the backlog.
STOP_AT: 2026-11-25T21:00:00Z (= 18:00 America/Sao_Paulo)
Wave plan: docs/art/ui-quality/report.md section 3     Phase: 4

Your session was created with the repository checked out at main; work in that checkout. Before your first pre-check, set up the tools a fresh container lacks: rustup target add wasm32-unknown-unknown aarch64-linux-android aarch64-apple-ios; pip install "gdtoolkit==4.*" "playwright==1.63.0"; (cd tools/ui_research && npm ci) for three.js, which the icon bake needs; then bash client/build.sh. Main is claude/videogame-project-analysis-ewkkk2; branch claude/ui-spec-docs-check from it (create it if it does not exist) and push only to claude/ui-spec-docs-check with git push -u origin claude/ui-spec-docs-check, retrying after 2, 4, 8 and 16 seconds on network failures. Take the first task in docs/progress/backlog.json on main whose assigned_to is SP-bt-06, whose state is open or resync and whose deps are all merged; when none is left, set agent_state "done", push, and end the session. One task per session. Pre-check with bash tools/run_checks.sh (start, then wait in the background, then record) before marking a task ready. Do not open a pull request. Do not stop to ask the owner anything: requests go to the lead in your status file, with a default.
```

### M1

```text
You are agent M1 of the Ruleborn agent program (3D quality wave). Read docs/guides/agent-brief.md first and follow it exactly; then docs/guides/agent-protocol.md where the brief links to it; then docs/process/superpowers/README.md, and follow CLAUDE.md order 8 with the skills there; then docs/art/3d-quality/plan.md, sections 6 and 7.

Agent: M1            Role: measure track: budget split, then the baseline        Model: Sonnet 5.5, effort medium
Branch: claude/3d-measure
Owned files: only the files each M1 task lists in the backlog, docs/progress/M1.md, docs/progress/status/M1.json
Tasks: 3D0-M1-budget-split, then 3D0-M1-baseline (after 3D0-M2-mask-tool merges), then 3D0-M1-baseline-2 (after 3D0-M2-mask-screens merges). Each task's done_when in docs/progress/backlog.json is the bar; a verifier on Opus 5.5 at effort high reviews your diff before it merges (CLAUDE.md order 7). If the task is harder than your model and effort, say so in your status file and end your turn.
STOP_AT: 2026-12-02T21:00:00Z
Wave plan: docs/art/3d-quality/plan.md section 6     Phase: 0

Your session was created with the repository checked out at main; work in that checkout. Before your first pre-check, set up the tools a fresh container lacks: rustup target add wasm32-unknown-unknown aarch64-linux-android aarch64-apple-ios; pip install "gdtoolkit==4.*" "playwright==1.63.0"; (cd tools/ui_research && npm ci); then bash client/build.sh. Main is claude/videogame-project-analysis-ewkkk2; branch claude/3d-measure from it (create it if it does not exist) and push only to claude/3d-measure with git push -u origin claude/3d-measure, retrying after 2, 4, 8 and 16 seconds on network failures. Take the first task in docs/progress/backlog.json on main whose assigned_to is M1, whose state is open or resync and whose deps are all merged; when none is left, set agent_state "done", push, and end the session. One task per session. Pre-check with bash tools/run_checks.sh (start, then wait in the background, then record) before marking a task ready. Do not open a pull request. Do not stop to ask the owner anything: requests go to the lead in your status file, with a default.
```

### M2

```text
You are agent M2 of the Ruleborn agent program (3D quality wave). Read docs/guides/agent-brief.md first and follow it exactly; then docs/guides/agent-protocol.md where the brief links to it; then docs/process/superpowers/README.md, and follow CLAUDE.md order 8 with the skills there; then docs/art/3d-quality/plan.md, sections 6 and 7.

Agent: M2            Role: measure track: the mask tool, then the find-it test        Model: Opus 5.5, effort medium (3D0-M2-find-it: Sonnet 5.5, effort medium)
Branch: claude/3d-mask
Owned files: only the files each M2 task lists in the backlog, docs/progress/M2.md, docs/progress/status/M2.json
Tasks: 3D0-M2-mask-tool, then 3D0-M2-find-it, then 3D0-M2-mask-screens (Opus 5.5, effort high on its resync). Each task's done_when in docs/progress/backlog.json is the bar; a verifier on Opus 5.5 at effort high reviews your diff before it merges (CLAUDE.md order 7). If the task is harder than your model and effort, say so in your status file and end your turn.
STOP_AT: 2026-12-02T21:00:00Z
Wave plan: docs/art/3d-quality/plan.md section 6     Phase: 0

Your session was created with the repository checked out at main; work in that checkout. Before your first pre-check, set up the tools a fresh container lacks: rustup target add wasm32-unknown-unknown aarch64-linux-android aarch64-apple-ios; pip install "gdtoolkit==4.*" "playwright==1.63.0"; (cd tools/ui_research && npm ci); then bash client/build.sh. Main is claude/videogame-project-analysis-ewkkk2; branch claude/3d-mask from it (create it if it does not exist) and push only to claude/3d-mask with git push -u origin claude/3d-mask, retrying after 2, 4, 8 and 16 seconds on network failures. Take the first task in docs/progress/backlog.json on main whose assigned_to is M2, whose state is open or resync and whose deps are all merged; when none is left, set agent_state "done", push, and end the session. One task per session. Pre-check with bash tools/run_checks.sh (start, then wait in the background, then record) before marking a task ready. Do not open a pull request. Do not stop to ask the owner anything: requests go to the lead in your status file, with a default.
```

### CF1

```text
You are agent CF1 of the Ruleborn agent program (3D quality wave). Read docs/guides/agent-brief.md first and follow it exactly; then docs/guides/agent-protocol.md where the brief links to it; then docs/art/3d-quality/plan.md, sections 6 and 7.

Agent: CF1            Role: camera and framing track: the three style frames        Model: Opus 5.5, effort medium
Branch: claude/3d-camera
Owned files: only the files each CF1 task lists in the backlog, docs/progress/CF1.md, docs/progress/status/CF1.json
Tasks: 3D0-CF1-style-frames. Each task's done_when in docs/progress/backlog.json is the bar; a verifier on Opus 5.5 at effort high reviews your diff before it merges (CLAUDE.md order 7). If the task is harder than your model and effort, say so in your status file and end your turn.
STOP_AT: 2026-12-02T21:00:00Z
Wave plan: docs/art/3d-quality/plan.md section 6     Phase: 0

Your session was created with the repository checked out at main; work in that checkout. Before your first pre-check, set up the tools a fresh container lacks: rustup target add wasm32-unknown-unknown aarch64-linux-android aarch64-apple-ios; pip install "gdtoolkit==4.*" "playwright==1.63.0"; (cd tools/ui_research && npm ci); then bash client/build.sh. Main is claude/videogame-project-analysis-ewkkk2; branch claude/3d-camera from it (create it if it does not exist) and push only to claude/3d-camera with git push -u origin claude/3d-camera, retrying after 2, 4, 8 and 16 seconds on network failures. Take the first task in docs/progress/backlog.json on main whose assigned_to is CF1, whose state is open or resync and whose deps are all merged; when none is left, set agent_state "done", push, and end the session. One task per session. Pre-check with bash tools/run_checks.sh (start, then wait in the background, then record) before marking a task ready. Do not open a pull request. Do not stop to ask the owner anything: requests go to the lead in your status file, with a default.
```

### DT1

```text
You are agent DT1 of the Ruleborn agent program (3D quality wave). Read docs/guides/agent-brief.md first and follow it exactly; then docs/guides/agent-protocol.md where the brief links to it; then docs/art/3d-quality/plan.md, sections 6 and 7.

Agent: DT1            Role: data track: the data spec and guards() fields        Model: Opus 5.5, effort high
Branch: claude/3d-data
Owned files: only the files each DT1 task lists in the backlog, docs/progress/DT1.md, docs/progress/status/DT1.json
Tasks: 3D0-DT1-data-spec. Each task's done_when in docs/progress/backlog.json is the bar; a verifier on Opus 5.5 at effort high reviews your diff before it merges (CLAUDE.md order 7). If the task is harder than your model and effort, say so in your status file and end your turn.
STOP_AT: 2026-12-02T21:00:00Z
Wave plan: docs/art/3d-quality/plan.md section 6     Phase: 0

Your session was created with the repository checked out at main; work in that checkout. Before your first pre-check, set up the tools a fresh container lacks: rustup target add wasm32-unknown-unknown aarch64-linux-android aarch64-apple-ios; pip install "gdtoolkit==4.*" "playwright==1.63.0"; (cd tools/ui_research && npm ci); then bash client/build.sh. Main is claude/videogame-project-analysis-ewkkk2; branch claude/3d-data from it (create it if it does not exist) and push only to claude/3d-data with git push -u origin claude/3d-data, retrying after 2, 4, 8 and 16 seconds on network failures. Take the first task in docs/progress/backlog.json on main whose assigned_to is DT1, whose state is open or resync and whose deps are all merged; when none is left, set agent_state "done", push, and end the session. One task per session. Pre-check with bash tools/run_checks.sh (start, then wait in the background, then record) before marking a task ready. Do not open a pull request. Do not stop to ask the owner anything: requests go to the lead in your status file, with a default.
```

## Standing notes

Notes that stay true from cycle to cycle; `archive.py` never moves them.

- BT-10 and BT-11 (`flaky.md`) stay open on the lead, unstarted.
- Tools in a fresh container: `rustup target add wasm32-unknown-unknown
  aarch64-linux-android aarch64-apple-ios`, `pip install "gdtoolkit==4.*"
  "playwright==1.63.0"`, then `bash client/build.sh`, before
  `run_checks.sh start` (cycle 16 started one first and had to stop it).
  Run `guard.sh` in its own worktree of the candidate (`client/build.sh`
  there first); about 12 minutes beside check_all.

## Now

- **Cycle 214**, 26 November 2026, from about 05:14Z (session
  `session_01SNkKxpn5ZJDS7qZnMd2BFF`, started by the Opus 5.5 launcher,
  Opus 5.5 at effort medium by order 7). The changes since cycle 213:
  M2 marked the 3D0-M2-mask-screens resync ready at d0d62a99 (pre-check
  PASS). **Verify / merge:** merge lock taken for candidate 723dd2de
  (main + d0d62a99); ownership and claims checks pass, the candidate
  differs from `ready_sha` only under `docs/progress/` and the docs
  check passes. The Opus 5.5 high verifier failed it. Attempt 2's points
  are fixed (universe pins hidden by alpha, the stray check returns 0
  and its self-test refuses a pin in id.png, universe Q11 under_share
  0.273, realm edges explained in mask.md, M2.md rewritten; the new
  self-test cases fail on main's measure.py). Blocking: on the
  character screens the stage's own interface (character_screen.gd's
  `level_badge`: pills, arrows, name plate; roster, forms, sage_hall
  and first add their `over`/`top` the same way) is counted as world
  (mask_pass.gd:723-725, 735, 747), so Q1 and Q4 read it as world and
  world.png shows interface; Q1's band on screen_character reads 27.4%
  instead of about 6.6%. Nothing merged; the task is `resync` (attempt
  3); lock cleared. **Started:** M2 on the resync
  (`session_01SNkKxqcJThi4swGsdinWkY`, Opus 5.5 high, a resync by order
  7). One builder works, under the cap of three while the seven-day bar
  reads `allowed_warning`. M1's seat waits for the mask task; SP-bt-01's,
  DT1's and CF1's seats are free with no 3D task open for them.
  **Requests:** M2-R1, M2-R2, SPbt01-R2 and SPbt01-R3 stay open, none
  past `due`. **Owner:** the phone trial and the style-frame pick are
  still open (owner inbox).

- **Cycle 213**, 26 November 2026, from about 04:39Z (session
  `session_01SNkKxp7dmCda8XWNfwYaUM`, started by the Opus 5.5 launcher,
  Opus 5.5 at effort medium by order 7). The changes since cycle 212:
  M2 pushed 114f5fda (the universe numbers without pins, an exact stray
  count test, its handoff) and merged main (d0d62a99); its session's
  turn ended with the pre-check running in the background, and its
  status (04:16Z, due 05:00Z) is not late. **Verify / merge:** nothing
  ready; no merge lock taken. **Started:** none; one builder (M2) works,
  under the cap of three while the seven-day bar reads
  `allowed_warning`. M1's seat waits for the mask task; SP-bt-01's,
  DT1's and CF1's seats are free with no 3D task open for them.
  **Requests:** M2-R1, M2-R2, SPbt01-R2 and SPbt01-R3 stay open, none
  past `due`. **Owner:** the phone trial and the style-frame pick are
  still open (owner inbox).

- **Cycle 212**, 26 November 2026, from about 04:14Z (session
  `session_01SNkKxpNTzU8p6veGpMZKBD`, started by the Opus 5.5 launcher,
  Opus 5.5 at effort medium by order 7). The changes since cycle 211:
  M2 claimed the 3D0-M2-mask-screens resync (attempt 2) and pushed two
  fixes (bfa7ed0b: a stage's own 2D hidden by alpha too, the look's
  vignette in the id pass, an id pass with stray colours refused;
  d2bd54e9: the id pass black behind the world view). M2's session is
  working (re-running the 22 mask shots) and its status is current.
  **Verify / merge:** nothing ready; no merge lock taken. **Started:**
  none; one builder (M2) works, under the cap of three while the
  seven-day bar reads `allowed_warning`. M1's seat waits for the mask
  task; SP-bt-01's, DT1's and CF1's seats are free with no 3D task open
  for them. **Requests:** M2-R1, M2-R2, SPbt01-R2 and SPbt01-R3 stay
  open, none past `due`. **Owner:** the phone trial and the style-frame
  pick are still open (owner inbox).

- **Restart, 25 November 2026** (the overseer). The owner restarted the
  program on the 3D quality plan ("Based on the plan made by Fable, let's
  start the work. Opus 5.5 Medium for complex tasks. Sonnet 5.5 Medium for
  simple tasks. Opus 5.5 High for complex tasks and to verify the work of
  others"); CLAUDE.md order 1 and the new order 7 record it. The UI wave
  stays closed. `backlog.json` now reads wave "3D quality wave", phase 0,
  `stop_at` 2026-12-02T21:00:00Z, and holds seven phase 0 tasks (plan.md
  section 6, "First tasks, in order"):
  - **M1** (`claude/3d-measure`, Sonnet 5.5 medium): 3D0-M1-budget-split,
    then 3D0-M1-baseline once the mask tool merges.
  - **M2** (`claude/3d-mask`, Opus 5.5 medium): 3D0-M2-mask-tool, then
    3D0-M2-find-it (Sonnet 5.5 medium).
  - **CF1** (`claude/3d-camera`, Opus 5.5 medium): 3D0-CF1-style-frames.
  - **DT1** (`claude/3d-data`, Opus 5.5 high: it touches the extension
    and the replay's bytes): 3D0-DT1-data-spec.
  - **Owner:** 3D0-OW-phone-trial (D4), once the budget split merges; and
    the pick of a style frame once CF1's frames merge. Never claimed by an
    agent.
  The four seats fill the cap of four. Before any merge, a verifier on
  Opus 5.5 at effort high (a subagent of the cycle) reviews the diff
  against `done_when` and plan.md and re-runs the checks; a failure goes
  back to the builder. Reading of the owner's two Opus tiers: medium for
  complex tasks, high for the hardest ones (order 7) and for every check.
  The launcher, its second firing and the watchdog of 15 November were
  re-enabled; the next lead cycle starts the four builders from the
  prompts under "The agents' prompts".

- **Stopped here, 24 November 2026** (the overseer, about 23:35Z). On
  24 November, about 23:25Z, the owner ordered that "UI done" is
  report.md's phases 0 to 3 and that every agent stops when phase 3
  closes (CLAUDE.md order 1). At about 23:30Z the owner approved the
  overseer's fast close ("Yes, do it"): the overseer did the lead's close
  steps (M65). **Merged:** P3-AD-wave-close (AD, ready at 3bfb8325; AD-R67
  and AD-R68 closed) onto main at **e33be6f9**. wave.md's ruling reads "The
  wave stands at O7". **Phase 3 is closed.** **The program is stopped.**
  **Builders, all stopped:** SP-bt-05 (BT-05, `claude/ui-spec-gate-run`,
  tip 64697568, not ready), SP-bt-06 (BT-06, `claude/ui-spec-docs-check`,
  tip 8b5338c5, not ready), SP-bt-09 (BT-09, `claude/ui-spec-setup`,
  ready at 1a8a6ea7 with its pre-check passed, not merged). Their status
  files are on their branches. The BT track, BT-08, icon batches 3 and 4
  and the wave board's follow-up list are outside "UI done": no phase 4
  is opened. **Lead:** idle after cycle 191; the merge lock is cleared.
  **Scheduled tasks:** all disabled (launchers
  `trig_01NksvDVV7iRJi4zrU7Uf7Te` and `trig_0155PATecuM4Cm5NGsEsbkX1`,
  watchdog `trig_01RTRucUN1KoyRtkdMc3BAfH`, and last the overseer's
  hourly status `trig_01B42Tpee2HLXTFaNUMUmofr`). Nothing restarts until
  the owner, in their own words, says what comes next.
- **Restart, 23 November 2026** (the overseer, about 21:20Z). The owner
  restarted the program, in the chat of the overseer session: "Continue,
  first the bugs then the UI" (CLAUDE.md order 1). It runs on Opus 5.5 at
  effort high (order 5), with the cap of four builders (order 3).
  **Bugs first:** resync FX1-4-holds-codex (merge main into
  `claude/fix-server-a`, give RB-36's test manifests the form byte,
  re-run the checks), start FX3-5-audit-sim afresh (its claim commit
  941dd4a5 is on `claude/fix-sim`), then FX4-3-replay-shop-nav and the
  other open FX tasks (FX1-6, FX2-6, FX4-4, FX4-5, FX1-7). Each builder
  is started anew with `create_session`. **Then the UI:** once every FX
  task is merged, unpark P3-S3-settings-4, P4-S1-heist-vault,
  P4-S2-home-purse and the BT track. **Scheduled tasks:** the working
  pair in "The program's scheduled tasks and sessions" is re-enabled, as
  at the restart of 21 November (launcher `trig_01NksvDVV7iRJi4zrU7Uf7Te`
  and `trig_0155PATecuM4Cm5NGsEsbkX1`, watchdog
  `trig_01RTRucUN1KoyRtkdMc3BAfH`), after this restart was on main. Every
  retired scheduled task stays disabled. Where the work stood: the entry
  "Stopped here, 21 November 2026" below.
- **Stopped here, 21 November 2026** (the overseer, about 23:15Z). At
  about 21:45 UTC the owner ordered, in the chat of the overseer session,
  "Merge cleanly what we have until now and then stop" (CLAUDE.md
  order 1). **The program is stopped.** **Merged:** FX2-5-auth-lows
  (ready at 574495aa; RB-23, RB-24, RB-25, RB-26, RB-60) onto main at
  **5f1cc425**. Its fail-first test 83ba326a precedes its fixes;
  `owners.py diff` passes. **Checks:** the full check on 5f1cc425 passed
  at 23:11Z (`tools/run_checks.sh`). Its first run failed on the
  environment, not a test: the style board step (AIA-R1) raised
  `ImportError: cannot import name '_imaging' from 'PIL'`, because the
  container's `python3` is 3.11 while its Debian Pillow is built for
  3.12. Pillow 10.4.0 was installed for Python 3.11 (checks.md: "Pillow
  and numpy (`pip install pillow numpy`)") and the re-run passed. Main
  then took the cycle-164 lead's docs-only commit 55d579a2;
  `check_docs_consistency.py` passes. **Not merged:** FX1-4-holds-codex
  is `resync` (ready 2003cc38). It passes alone, but the combined
  candidate ea551636 with FX2-5 failed RB-36's test with `crew_mismatch`
  (`server/test/fix_fx1_holds_codex.test.mjs:98`): FX2-5's RB-25 now
  checks the manifest's form byte. After a restart: merge main into
  `claude/fix-server-a`, give RB-36's test manifests the form byte,
  re-run the checks. FX3-5-audit-sim is `open` again: its session
  `session_01SNkKxne1a1DLSJJZJn4mc2` was interrupted after its claim
  commit 941dd4a5 on `claude/fix-sim`. **Sessions:** FX1 to FX4 are
  `stopped`; the cycle-164 lead pushed 55d579a2 at 22:18Z and is idle.
  **Scheduled tasks:** none is enabled. **Merge lock:** cleared. The UI
  stays paused. Start nothing until the owner restarts the program.
- **Stopped here**, 13 November 2026, about 13:20Z (the owner's "Stop
  cleanly"). Cycle 84 (session `session_01SNkKxpqF4gx3yYhsXenUGt`) took
  the merge lock for P2-AD-board-4 (candidate `842f09ab`, AD's ready
  `c0bab2a8`) and was interrupted while the checks ran: nothing merged,
  no builder started. Board 4 stays on AD's branch, ready, and merges
  first after a restart (re-run the checks). The other builders' work is
  on their branches: K1's tabs (check_all passes), S2's home-3 and S3's
  settings (gate on `f0a36a41` pending). Board 4's follow-ups
  (P2-S1-result-3, P2-AIA-motion-3, P2-AD-board-4b) are filed and not
  started.
- Restart, 11 November 2026 at about 01:15Z (the overseer, on the owner's
  words "We still need to keep the UI process we were doing with the
  phases running as it was" and "Make sure it is running now"): CLAUDE.md
  order 1 says the program runs, on Fable 5.2 only. Nothing ran and
  nothing was merged between cycle 50 (10 November, 10:33Z) and this
  entry; main moved only by the overseer's two write-ups (`312b1a12`,
  `1c6aa12a`). `stop_at` is still 14 November 21:00Z. A new launcher and
  a new watchdog were created after this entry's commit (`40c92625`) was
  on main; their IDs are in the table above. The security fixes named
  below landed at `ca96667f` (01:13Z).
  For cycle 51, the first cycle after the restart:
  - Every earlier session is stopped or idle and is not reused. Start
    fresh Fable 5.2 sessions: AIA on P1-AIA-kit-7 and S1 on
    P1-S1-pilot-2 (both open, deps merged). P1-AD-board-1 waits for
    pilot-2. At most three UI builders at once; icon batches 3 and 4
    stay deferred (D13 (c)).
  - Seed K1's next task and start K1 on it: first the disc drawn under
    the currency pills on kit catalogue parts K23 and K45, with a test
    (entry "The stop", "First fix on a restart"), then S1-R1 to S1-R7.
  - The overseer is also landing small security fixes on main, from a
    static review of the repository: comments and text in
    `docs/security/auth.md`, `server/src/auth.mjs` and
    `client/features/auth/secure_store.gd`, and one warning line each in
    `server/src/main.mjs` and `client/export.sh`. No builder owns those
    files. Fetch before a merge, as always; if such a commit lands in
    the middle of a merge, rebase the candidate and run the checks
    again.
- Restart, 9 November 2026 at 21:05Z (the overseer, on the owner's word
  "Let's continue and use only Fable 5.2"): CLAUDE.md order 1 says the
  program runs and order 4 says Fable 5.2 only. The backlog's roster and
  every task not yet merged name Fable 5.2; `stop_at` moved to 14 November
  21:00Z. New launcher and watchdog (table above). No lead cycle ran
  between 5 November 00:05Z and this entry, and nothing was merged. The
  three builders finished cleanly at the stop and all three tasks are
  ready with pre-check PASS: kit-4 at `f3456cac`, icons-2a at `6a382d97`,
  words at `0e829632`. The backlog still shows them `working`; the
  branches' status files are the newer record.
- After the stop (written for the restart; the owner restarted the
  program on 11 November 2026, entry "Restart, 11 November 2026" above).
  Tasks not merged, with branch, last commit and
  state: P1-S1-pilot-2 is open with its deps merged and not started; S1's branch `claude/ui-screens-heist` is at `376d86a9` (status and handoff after the ready commit), stopped.
  P1-AIA-kit-7 (batch 2d, the gate's notes on kit-6; K1-R16's two
  pressed and locked states could ride with it) is open with its deps
  merged and not started; `claude/ui-artist` is at `0c27e773`, AIA's
  session idle. `claude/ui-bake` is at `a2e75777`, all of it merged
  except K1's last status and handoff commits; K1 has no open task, and
  S1-R1 to S1-R7 would be its next one once the lead seeds it. Icon
  batches 3 and 4 stay deferred (D13 (c)). A restart needs new sessions
  on Fable 5.2 and, if the owner wants the hourly cycle again, a new
  launcher and watchdog created after the restart is on main.
- The stop, 10 November 2026 at about 10:45Z (the overseer, on the
  owner's order "Deploy and then stop cleanly"): CLAUDE.md order 1 said
  the program was stopped, until the restart of 11 November. Checked
  before writing it: main at `8f03235f`,
  merge lock free; cycle 50's session, K1's, S1's and AIA's all ended
  (`get_session`: idle, completed); launcher and watchdog disabled
  (`get_trigger`); no check-in armed. `status/lead.json` has
  `expected_next_update_by` null, which means stopped on purpose, not
  stale. Four things the entries above do not say, for the restart:
  - P1-AD-board-1 is the third open task of phase 1 (17 of 20 merged, 57
    of 64 hours). It waits for P1-S1-pilot-2; `claude/ui-ad` is at
    `1be67031`.
  - **First fix on a restart, with a test: a fault that came in with
    `e072364a`.** On the kit's catalogue (part K23, the currency pill) a
    large disc is drawn under every pill and covers the captions below.
    `KitStatus.resource()` in `client/ui/kit_status.gd` dresses the
    storage bar's track with the look `icon_disc`; the likely cause,
    read from the code and not proven by a run, is that this look draws
    the disc's sprite as wide as the bar. It is K1's file. Only the
    catalogue and sample pages call it
    (`client/tests/shots/ui_kit_catalogue.gd`,
    `client/tests/shots/ui_kit_pages.gd`); no game screen shows it, and
    no test caught it.
  - **Correction and addition to the fault above** (the overseer, 10
    November 2026 at about 19:40Z, on the owner's "Continue deeply";
    read from the history and the code, not proven by a run, because
    Godot is not in the overseer's container):
    - **The fault did not come in with `e072364a`.** The skin `disc` was
      switched on in `client/ui/kit_families.json` by `5274fba5` (9
      November, 22:41Z, "Switch on the kit's gated skins"), which reached
      main with the merge `3ac50485` (P1-K1-switch-heist, 10 November,
      07:33Z). The catalogue's pages 27, 44 and 45 on main were last
      rendered on 4 November, before the switch. K1 rebuilt the English
      pages in `53a14e17`, merged in `e072364a`: that is when the stills
      first showed the fault, not when the code got it.
    - **How it happens.** `KitSkin.SKINS` maps six looks to the skin
      `disc`: `disc`, `icon_disc`, `level_disc`, `gem`, `round_sky` and
      `round_violet` (`client/ui/kit_skin.gd`). The skin's pieces
      (`disc__box__<state>`) are sprites with no 9-slice, and
      `RbBox._draw_piece` draws a sprite as wide as its host, from the
      host's top, whatever the host's shape. On a round host that is
      right. On a bar track or an oval button it is a disc as wide as the
      host.
    - **Part K45 (the product card) has it too, and was not recorded.**
      Catalogue pages 44 and 45, English, normal, 100%: the Buy button
      (`KitCards.product`, `look` default `round_violet`,
      `client/ui/kit_cards.gd`) is drawn as a disc as wide as the button.
      It runs past the card and covers the state's caption in the states
      N, P, D (page 44) and S (page 45). State L (the teal oval) is
      right.
    - **"No game screen shows it" above is not established.** One game
      screen dresses a host that is not round in a look of the disc skin:
      the observatory's "echo" ribbon
      (`client/scripts/observatory_screen.gd`, `_ribbon`, the look
      `round_violet` on `OverlayHud.pill`, a pill). No still of the
      observatory was rendered after the switch, so whether it shows the
      fault is not known; the fix task renders it. The product card and
      the storage bar are called only by the catalogue, the sample pages
      and the tests today. Two more uses were read and look right: the
      week streak's prize tile (`client/ui/kit_hud.gd`, `round_violet`)
      is nearly square and draws as a disc on page 41, and the heist
      HUD's law chip uses `icon_disc` on a round host.
    - **Ruled out, by the diff `8e5cab5e..312b1a12`:** the switch file
      (`disc` was already on), the atlas manifest (the five disc pieces
      did not change), the callers (`KitCards.product` and
      `KitStatus.resource` did not change) and the catalogue test.
    - **What the fix task should deliver** (K1's files): the disc's
      sprite draws only on a round host, or `round_sky` and
      `round_violet` stop mapping to the sprite on a host that is not
      round (K1 decides and writes why); a test in
      `client/tests/ui_kit_tests.gd` that fails on main today; pages 27,
      44 and 45 rendered again in all eight variants, with a still of
      each game screen the fix changes. From then on, a task that
      switches a skin on renders again every catalogue page that skin
      changes, in the same task.
    - **An older fault on page 42 (part K43, the quest card), not from
      this wave:** the claim button's words run past the button's right
      edge in the states claim N, P and A. The page at `8e5cab5e` shows
      the same. It can ride with the fix above or follow it.
    - The scan behind this: all 46 English pages (normal, 100%) at
      `312b1a12`. Pages 1 to 26, 28 to 41, 43 and 46 show no fault. The
      Portuguese, high-contrast and 200% variants were not scanned.
  - The pilot heist's gate verdict has 5 passes of 16, not 4: the cycle
    50 entry above lists five (Layered materials at 100%, Painted or
    rendered icons at 100%, Light behind UI at both sizes, One
    art-direction idea at 200%), and so does
    `docs/art/ui-quality/gate/verdicts/P1-S1-pilot-1/5470c4d3.json`.
  - No still of the rebuilt heist HUD is committed. The gate judged
    stills rendered in cycle 50's container. P1-S1-pilot-2 should commit
    its stills, so the change can be shown.
