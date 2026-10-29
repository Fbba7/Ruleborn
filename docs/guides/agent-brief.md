# The agent brief: read this first

Every agent working on Ruleborn reads this page before anything else. A
prompt then only needs to say who you are and what your task is: your role,
your branch, your files, your backlog task or tasks, and your `STOP_AT`. The
reasons behind each rule, and the detail, are in
[agent-program.md](agent-program.md).

Ruleborn is a mobile heist game: a Godot 4.7.2 client on the Compatibility
renderer (`client/`), a Rust simulation (`sim/`), and a Node server
(`server/`). The design document in `docs/design/` is the authority for every
rule of the game.

## Hard rules

1. **Your branch only.** Push with `git push -u origin <your-branch>`. If a
   push fails on the network, retry after 2, 4, 8 and 16 seconds. Never push
   to main (`claude/videogame-project-analysis-ewkkk2`) or to another
   agent's branch. Never open a pull request unless the owner asks.
2. **Your files only.** Your prompt or the wave's track table names them. If
   you need a change in someone else's file, write a request (below). Never
   edit it, even to resolve a conflict.
3. **Protected files.** Never edit the design document
   (`docs/design/ruleborn-game-design-v3.7.txt`, or whichever version is
   current), `docs/decisions/answers.json`, or anything under
   `tools/vendor/`. A change to a design rule is an owner decision: prepare
   it and say so in your progress file.
4. **"§" cites the design document only.** In repository docs, "§21.8" means
   section 21.8 of the design document and nothing else; the documentation
   check fails a "§" that names no section of it. Cite other documents as
   "section 3.5 of `report.md`".
5. **No model names** in commits, code, comments or docs, except where a
   document must say which model a role uses. Then use the product name
   (Opus 5.5, Sonnet 5.5, Haiku 5.5, Fable 5.1), never an API identifier.
6. **Never skip, disable or loosen a test** to get green, and never edit a
   test's expectations to match a regression.
7. **Green before a push you mean to be merged.** Run
   `bash tools/check_all.sh` (about 25 minutes) until it prints
   `All checks passed.` Run it in the background with its output to a file
   and a completion marker:

   ```bash
   (bash tools/check_all.sh > check.log 2>&1; echo "DONE exit=$?" >> check.log) &
   ```

   Then read only the failures and the last lines:
   `grep -A 5 -E '(FAIL|ERROR|error:)' check.log | head -100; tail -3 check.log`.
   A commit titled `WIP` is a save point and is never merged; your last commit
   of a task must not start with `WIP`. A fresh container may lack Rust's
   `wasm32-unknown-unknown` target, `gdlint` (gdtoolkit 4) and Python's
   `playwright` 1.63.0: install them first
   (`rustup target add wasm32-unknown-unknown`,
   `pip install "gdtoolkit==4.*" "playwright==1.63.0"`).
8. **Your own assessment is not a check.** Report what passed, with
   evidence; never a self-estimated quality percentage.
9. **Settings are the owner's.** Do not change `.claude/` files, hooks,
   environment variables or other configuration unless your task says so;
   propose the change with its exact value instead.

## Reporting

Keep `docs/progress/<agent>.md`. It opens with exactly these six lines:

```markdown
# <agent> <name>: progress

- Status: Green / Red, and what the last push contains.
- Progress: NN%, counting only work that is pushed and passes check_all.
- Done: what is finished.
- Next: what comes next.
- Blocked by: what stops it, or none.
- Owner decision needed: the decisions only the owner can make, or none.
```

Then the deliverables table, then the handoff:

```markdown
| Deliverable | Weight | Status | Evidence |
|---|---:|---|---|

## Handoff
- Last verified commit: <sha> (check_all green, <UTC time>)
- Done / Half done / Open hypotheses / Next step
```

Evidence is a test, a commit, a still or a gate verdict. Update the file on
every push. Your track's notes (what was done, the evidence, what is still
worse, and "Stopped here") go where your prompt says.

Keep `docs/progress/status/<agent>.json` on your branch too, rewritten on
every status commit, at least every 45 minutes while you work. Its fields and
an example are in [agent-program.md](agent-program.md#communication-through-files).
The lead reads it to find claims, stalls, ready work, requests and
acknowledgements.

## Claiming work

1. `git fetch origin`; read `docs/progress/backlog.json` on main.
2. Pick the first `open` task your role may take whose `deps` are all
   `merged`. If there is none, take one from `idle_queue`. If there is none,
   follow the stop protocol.
3. Check that no other agent's status file claims it.
4. Write your status file (`task_id`, `state: "claimed"`, `claimed_at`,
   `lease_until` three hours later); commit and push; check again. If someone
   claimed it earlier, yield it and pick again.
5. Your claim lasts as long as you keep committing status: each status commit
   renews it for three hours. A lapsed claim must be made again.
6. **One task per session.** When it is merged, write your handoff and end
   the session; the next task starts fresh.

**Ready.** A task is ready when your branch contains main's head, the full
checks passed on exactly that commit, and the gate passed every item it
carries. Write `state: "ready"` and `ready_sha`. If the lead marks it
`resync`, merge main into your branch, resolve your own conflicts, re-run the
checks and mark it ready again.

**Requests.** Need something in someone else's file? Add it to `requests` in
your status file: an id, who it is for, what you need, and the file. Check
the answers at every checkpoint. Answer requests addressed to you as part of
your own work.

**Messages.** When the lead sends you an instruction, add its id to `acks` in
your next status commit. Until you do, it has not been delivered.

## Session hygiene

- **Start** by reading this brief, your handoff, the backlog and `git log`;
  run the quick checks before new work.
- **One model per session.** Never switch model, toggle fast mode or change
  MCP servers inside a session. If your task needs another model, hand off.
- **Keep the context small.** Read a file once. Read only the part you need.
  Send wide searches and log triage to a subagent on Haiku 5.5, and never
  ask it for a verdict. Keep test output in files. Look at images downscaled
  (about 960 pixels on the long edge) unless fine detail is the point, and
  never keep more than a few in your context.
- **End at a task boundary** with a rewritten handoff, rather than
  compacting. Compact only when the next step depends on something you have
  not yet written down.
- **Commit after every verified step,** so a restart or a usage pause loses
  nothing.

## Time and stopping

- Your `STOP_AT` is an absolute UTC time, for example
  `STOP_AT: 2026-11-03T21:00:00Z (= 18:00 America/Sao_Paulo)`. Check the time
  with `date -u`; never guess it.
- At `STOP_AT` minus 30 minutes, start no new task. Bring your work to its
  last verified state, commit and push (as `WIP` if it is not green), write
  `state: "stopped"` and `next_step` in your status file, rewrite your
  handoff, and write "Stopped here" in your notes.
- Do not stop earlier because the work looks done: take the next task or
  the idle queue. If your deadline is unclear, ask the lead in a request and
  keep working.
- **Restarts.** If you find a log without its `DONE exit=` line, its run did
  not finish: run it again.
- **Usage limits.** If a limit pauses you, commit first and, if you can,
  schedule your own resume with `send_later`.
