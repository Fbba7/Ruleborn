# The checks: `tools/check_all.sh`

One script runs every check in the repository, in dependency order:

```bash
bash tools/check_all.sh
```

It ends with `All checks passed.` and exit status 0, or stops at the first
failing step (`set -euo pipefail`) with a non-zero status. An agent marks a
task ready only when it ends green on the task's own commit (its pre-check),
and the lead runs it again on the merge candidate before main moves (see
[agent-program.md](agent-program.md#merging-the-queue-and-the-guards)). A
full run takes about 25 minutes, most of it the client's headless tests.
Beside it, on every merge candidate, the lead runs the UI kit's guard,
`bash tools/ui_bake/guard.sh` (about 12 minutes; Godot from
`client/build.sh`, `xvfb-run`, Node and the container's Chromium; it prints
`ui guard: OK`): a full rebake byte for byte, and draw calls, texture memory
and contrast against `tools/ui_bake/budgets.json` (D9 (b), K1-R3).

## Running it in the background: the worktree runner

Run the full checks on a separate worktree of the exact commit, with the log
outside the repository, so editing during the run cannot change what is
tested and the log cannot be committed by accident. The log always ends with
a `DONE exit=<code>` line
([agent-protocol.md](agent-protocol.md#running-the-checks)):

```bash
bash tools/run_checks.sh start          # checks HEAD in /tmp/check-<sha>, logs to /tmp/check-<sha>.log
bash tools/run_checks.sh wait <sha>     # in the background: blocks until DONE, prints the result
bash tools/run_checks.sh result <sha>   # {"state": "PASS"|"FAIL"|"RUNNING", ...}
```

- **A run passed** only if its log ends `DONE exit=0` **and** contains
  `All checks passed.` The failing step is the last heading in the log:
  `grep '^== ' "$log" | tail -1; tail -20 "$log"`.
- **A log without its `DONE` line** is a run that did not finish (a
  container restart kills every running process). Re-run it; the re-run
  belongs to the same task.
- `wait` and `result` remove the worktree once the run has finished.
- Start no full run after STOP_AT − 60 minutes with today's 25-minute checks.

## The quick checks

While iterating, run the quick checks instead of the whole script, and at the
start of every session
([agent-protocol.md](agent-protocol.md#terms)):

- `python3 tools/check_docs_consistency.py`, always;
- plus the steps in the table below for the areas your files touch: for the
  client, `python3 client/status.py`; for the server,
  `python3 server/status.py`; for the simulation, `bash sim/run_spike.sh`;
  for content, `python3 tools/validate_content.py`.

The quick checks never stand in for the full checks before a task is marked
ready.

## What it needs

| Tool | For |
|---|---|
| Python 3.10 or later (run here on 3.13) | most steps |
| Rust stable (1.82 or later, for `#[unsafe(no_mangle)]`) with the `wasm32-unknown-unknown`, `aarch64-linux-android` and `aarch64-apple-ios` targets | the simulation, the client's extension and `client/export.sh check` |
| Node 22.5 or later | the server, its load check, the WebAssembly spike |
| Godot 4.7.2 | fetched by `client/build.sh` on first use into `~/.cache/ruleborn/` |
| `gdlint` (`pip install "gdtoolkit==4.*"`) | the client's lint step |
| Python Playwright with a Chromium | the prototype's conformance check (`tools/check_prototype_conformance.py`) |
| Pillow and numpy (`pip install pillow numpy`) | the UI kit's bake (`pack.py`) and the UI wave gate's tools (`tools/ui_gate/`) |
| network access to github.com, once | Godot's download |

```bash
rustup target add wasm32-unknown-unknown aarch64-linux-android aarch64-apple-ios
pip install "gdtoolkit==4.*"
pip install playwright && python3 -m playwright install chromium
```

In a cloud container with Chromium already under `/opt/pw-browsers/`, install
the Python Playwright whose version matches that browser instead (the
container's Node Playwright reports it:
`node -e "console.log(require('playwright/package.json').version)"`), and skip
the `install chromium` step: Playwright finds the browser through
`PLAYWRIGHT_BROWSERS_PATH`. A mismatched version fails with "Executable
doesn't exist".

## Known contradictions do not fail it

The design document has known contradictions, each tracked as an open item in
the audit register. `tools/check_document.py` tells the two cases apart: a
check that fails while its register item is open is reported **OPEN** and
passes the gate; a check that fails with no item, or with an item the
register calls fixed, breaks the build. `tools/validate_content.py` reports
the same way over `content/`. So the build is green while the document still
has work to do, and turns red the moment something new goes wrong or an item
marked fixed regresses.

## The steps, in order

Each step is a heading the script prints (`== … ==`). Run any one of them on
its own with the command shown.

| Step | Commands | What fails it |
|---|---|---|
| Which design document every check reads | `python3 tools/design_doc.py`, `python3 tools/design_facts.py` | the pinned version is missing, or a fact can no longer be read from its home section |
| Design document consistency | `python3 tools/check_document.py` (and `--self-test`, `--coverage`) | a new contradiction; a fixed one back; a v3.1 shipped check no longer covered |
| §31.5's breakages | `python3 tools/mutation_gate.py`, `python3 tools/twice_stated.py --self-test` | a planted defect the checks fail to catch |
| The simulation core | `python3 sim/content_gate.py --self-test`, `bash sim/run_spike.sh` | the float ban, a test, a golden replay, native and WebAssembly disagreeing (writes `sim/status.json`) |
| The server | `design_facts.py --check-json server/src/facts.json`, `league_model.py --check …`, `python3 server/status.py`, `node server/load.mjs --check`, `node server/src/privacy.mjs --check`, `python3 tools/privacy_manifest.py --check`, `python3 tools/build_brief.py --check` | a server test; a generated JSON drifted; writes or reads per player moved; a stored column undeclared; the decision brief misquoting the document |
| The client | `client_strings.py --check`, `english_us.py --check`, `native_strings.py --check`, `client_contract.py`, `gdlint`, `python3 client/status.py`, `bash client/export.sh check` | a catalogue out of date; a client call the server does not serve; lint; a client test; the phone builds not compiling |
| What changed since the previous version | `python3 tools/version_diff.py --self-test` | |
| Launch-inventory counts | `python3 tools/inventory_homes.py --self-test` | |
| Content tables | `python3 tools/validate_content.py` (and `--self-test`) | `content/` disagreeing with the document, beyond open register items |
| Generated docs | `python3 tools/generate_docs.py --check` | `docs/design/generated/` out of date with `content/` |
| The register's edits | `python3 tools/check_edits.py` (and `--self-test`) | a drafted edit quoting a sentence the document does not have, or has twice |
| Analysis tools | `python3 tools/note_rebalance.py`; `--self-test` of `law_ranks.py`, `law_effects.py`, `ability_text.py`; `decision_support.py` with and without `--self-test` | |
| Economy model and heist harness | `python3 -m tools.economy_model.test_economy_model`, `python3 -m tools.heist_harness.test_harness` | |
| Generator settings | `python3 -m tools.generator_settings --self-test`, `post_ladder`, `ward_budget` | |
| The prototype | `python3 tools/build_prototype.py --check` (and `--self-test`), `build_stamp.py --self-test`, `check_prototype_conformance.py` | the published prototype out of date or off its rules |
| Dependency graph | `python3 tools/check_dependencies.py --write` | a cycle or dangling dependency; rewrites `docs/design/dependencies.md` |
| Register freshness | `python3 tools/check_findings_fresh.py` (and `--self-test`) | |
| Scope cut | `python3 tools/scope_cut.py --self-test` | |
| Unread fields | `python3 tools/check_unread_fields.py` | a field the harness computes and nothing reads |
| The agent program's tools | `bash tools/run_checks.sh --self-test`, `python3 tools/coord/owners.py --self-test`, `owners.py claims` when `docs/progress/backlog.json` exists | two tasks in flight whose files can meet |
| The UI wave's style board | `node art/ui/board/build_tokens.mjs --check`, `node art/ui/board/check_board.mjs` (and `--self-test`) | the tokens out of date with the board; a contrast or colour off the tokens |
| The UI kit's bake | `node tools/ui_bake/bake.js --check`, `node --test tools/ui_bake/test/bake.test.js` | an atlas or manifest out of date with `art/ui/`, or edited by hand; a bake test |
| The UI kit's screens | `python3 tools/ui_bake/check_screens.py` and its `--self-test` | a screen drawing chrome of its own (kit-spec.md section 7) past `tools/ui_bake/budgets.json`'s counts; the check missing a planted draw call, fill or texture |
| The UI wave gate's tools | `python3 tools/ui_gate/sheet.py --self-test` (also runs `colour.py`'s and `checks.py`'s tests) | a contact sheet, strip or crop drawn wrong; an image check missing its planted fail |
| **This repository's own documents** | `python3 tools/check_docs_consistency.py` (and `--self-test`) | see below |
| Audit register | `python3 tools/build_audit.py`, `python3 tools/check_audit_ui.py` (and `--self-test`) | rewrites `docs/audit/index.html`; fails on an inconsistent register |
| Roadmap | `python3 tools/completion.py --self-test`, `python3 tools/build_roadmap.py` | rewrites `docs/roadmap/index.html`; refuses a roadmap that contradicts itself |

Several steps **rewrite generated files** (`sim/status.json`,
`server/status.json`, `client/status.json`, `docs/design/dependencies.md`,
`docs/audit/index.html`, `docs/roadmap/index.html`). After a green run,
commit what changed with your work, so the pages show the run that passed.

## What the documentation check holds you to

`tools/check_docs_consistency.py` reads every Markdown file in the
repository (except `docs/design/generated/`). When you write a doc, these are
the rules it enforces:

- **Every relative link resolves.** A Markdown link to a path in the
  repository must point at a file that exists.
- **Counts about the register match the register.** Phrases such as "**N of
  M register items are fixed**", "tracked as N items", "N are drafted across
  M" are checked against `tools/audit_register.py`. Do not restate a count
  unless it is in one of those checked forms.
- **"§N.M" names a section of the current design document**, unless the
  text around it marks it as historical (it mentions v2.x, v3.0, a
  renumbering, or an earlier version). `docs/analysis/` is exempt as an
  archive of the v2.3 audit.
- **The README's tools listing matches `tools/`** both ways: every `.py`
  file and directory in `tools/` has a line in the fenced `tools/` block of
  `README.md`, and nothing listed is missing.
- **The README's "Can the drawing start?" table matches the register's
  gates.**
- **The spec index lists every spec file** in `docs/design/spec/`, and a
  spec's "Still open" list names only items the register has open.
- **One URL per published page.** A claude.ai artifact link is classified by
  the words in the 200 characters before it ("prototype", "decide them",
  "roadmap" or "progress", otherwise the audit), and each class must use one
  URL everywhere.
- **The document's current version** is named correctly wherever prose says
  "the design document at vX.Y".

## When it fails

The failures a fresh machine meets first:

| What you see | Why | Fix |
|---|---|---|
| `error[E0463]` … `failed: cargo build --release --quiet --target wasm32-unknown-unknown`, in the simulation step | the WebAssembly target is not installed | `rustup target add wasm32-unknown-unknown` |
| `gdlint: command not found`, in the client step | gdtoolkit is not installed | `pip install "gdtoolkit==4.*"` |
| `ModuleNotFoundError: No module named 'playwright'`, at `check_prototype_conformance.py` | Python Playwright is not installed | see "What it needs" above |
| `BrowserType.launch: Executable doesn't exist at …`, at the same step | the Python Playwright's version does not match the installed Chromium | install the matching version, or `python3 -m playwright install chromium` |
| `sign-in would be stubbed …` when starting the server by hand | no platform sign-in is configured (SR-29) | set `RULEBORN_STUB_SIGNIN=1` for local work |
| `check_docs_consistency.py` failing after a docs edit | a broken link, a count or citation it checks, or a new file in `tools/` not in the README's listing | the message names the file and line; see the rules above |

A step's own output names what failed; run that step alone with the command
in the table of steps to iterate quickly, then run the whole script again
before pushing.
