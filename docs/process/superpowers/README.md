# Superpowers skills, copied for the builders

These files are the Superpowers skills that CLAUDE.md order 8 names. They are
copied from github.com/obra/superpowers at commit 22f0b46, under the MIT
License in [`LICENSE`](LICENSE) (c) 2025 Jesse Vincent. The owner chose this
copy on 25 November 2026, because the claude.ai plugin does not reach the
program's cloud sessions.

## How a builder uses them

At the start of each task, read the files below and follow them:

| Order 8 asks for | Read |
|---|---|
| A failing test before the fix or feature | [`test-driven-development/SKILL.md`](test-driven-development/SKILL.md), then [`writing-good-tests.md`](test-driven-development/writing-good-tests.md) |
| A root cause for each defect, failed check or send-back | [`systematic-debugging/SKILL.md`](systematic-debugging/SKILL.md) and the notes beside it |
| Re-running the checks and reading their output before "done" | [`verification-before-completion/SKILL.md`](verification-before-completion/SKILL.md) |
| A review before handing the task to the lead | [`requesting-code-review/SKILL.md`](requesting-code-review/SKILL.md) and [`code-reviewer.md`](requesting-code-review/code-reviewer.md) |
| Handling a send-back (builder) or writing one (the lead's verifier) | [`receiving-code-review/SKILL.md`](receiving-code-review/SKILL.md) |

## Where this repository differs

The repository's rules win wherever a skill says otherwise:

- "Your human partner" means the lead, reached through your status file and
  handoff. It is not the owner: ask the owner nothing.
- Never push to main, merge, open a pull request, or start a session or
  scheduled task. Push only to your own branch.
- The skills' `gh` steps (pull request threads, replies) do not apply.
- A skill named here but not copied (such as `superpowers:writing-skills`)
  is not part of order 8; skip it.
- `systematic-debugging/condition-based-waiting-example.ts.txt` was renamed
  from `.ts` so no build picks it up. It is example code from another
  project; its imports do not exist here.
- `systematic-debugging/find-polluter.sh` runs `npm test`. Adapt the command
  to the test runner of the code you are working on before using it.

If these files are missing, follow the same practice from order 8's list
anyway, and say so in your status file.
