# SP-bt-04 the gate shot renderer: progress

- Status: Green at the last push; BT-04a resync (cycle 186): render.py now renders under run_checks.sh's sandbox (read-only HOME and .git). Full pre-check running.
- Progress: 0 of 2 tasks merged; 0 items passed by the gate (BT-04a has no gate items).
- Done: `tools/gate/render.py` (shot list format, still rendering of a listed item at a given sha, 960 px grayscale, manifest) and its fixtures; the resync's fix (build cache falls back to the temporary folder; the commit is exported with git archive instead of a worktree).
- Next: the lead merges BT-04a and adds its self-test to check_all (SP-bt-04-R1); then BT-04b (frame strips, 200% text and high-contrast variants, named crops) in a later session.
- Blocked by: none.
- Owner decision needed: none.

| Deliverable | Weight (h) | Status | Evidence |
|---|---:|---|---|
| BT-04a: shot list format and still renderer | 3 | resync, fix pushed | sandboxed self-test at ba6b3ab5: exit 0, "the fixture item at ba6b3ab5, ok"; at the unfixed 55af5f41: OSError Errno 30 (below) |
| BT-04b: strips, variants, crops | 2 | open | |

## Handoff

- Last verified commit: ba6b3ab5 (`CHECK_CMD='bash client/build.sh && python3 tools/gate/render.py --self-test' bash tools/run_checks.sh start ba6b3ab5`, bwrap, exit 0, 2026-11-24T19:48:09Z); full pre-check of the ready commit: see the status file's `precheck`.
- The resync (cycle 186): under run_checks.sh's bwrap sandbox HOME and the shared .git are read-only. Two things failed there, not one: `cache_dir()` (mkdir and mkdtemp under `~/.cache/ruleborn/gate`) and, behind it, `git worktree add`, which writes `.git/worktrees/<name>` (probed in bwrap: `fatal: could not create leading directories of '.git/worktrees/x': Read-only file system`).
- The fix, in `tools/gate/render.py`: `cache_dir()` probes its folder ($RULEBORN_GATE_CACHE or ~/.cache/ruleborn/gate) by creating it and a temporary file in it; when that fails it uses `<tempfile.gettempdir()>/ruleborn-gate` (TMPDIR first) and says so on stderr. The commit is exported with `git archive <sha> | tar -x` into a temporary folder in that cache, which only reads the objects; the folder is removed afterwards (`--keep` keeps it and prints where). The render is not skipped and no test is loosened: the self-test gained a case (an unwritable RULEBORN_GATE_CACHE must fall back to the temporary folder, which the old code fails with an OSError), and its "worktree left behind" check became "exported tree left behind".
- Reproduced before the fix, at 55af5f41 (main merged, old render.py), with `CHECK_CMD='bash client/build.sh && python3 tools/gate/render.py --self-test' bash tools/run_checks.sh start 55af5f41`: `FAIL`, exit 1, `OSError: [Errno 30] Read-only file system: '/root/.cache/ruleborn/gate/gate-55af5f41-pbq8ntg8'` from `render()`'s `tempfile.mkdtemp(..., dir=cache_dir())` (render.py:229). The folder existed on this host from an unsandboxed run, so it failed at mkdtemp rather than at cache_dir()'s mkdir as in the lead's run: the same read-only HOME.
- After the fix, at ba6b3ab5, same command: exit 0, log: `render.py: the shot list's parser, ok` / `the build cache's fallback, ok` / `render.py: the build cache is /tmp/ruleborn-gate: /root/.cache/ruleborn/gate cannot be written (Read-only file system)` / `render.py: the fixture item at ba6b3ab5, ok` / `DONE exit=0`. (run_checks.sh's `result` says FAIL for it only because that narrowed command never prints "All checks passed.")
- Timing: in the sandbox the cache is the run's private /tmp, so every check_all run builds the GDExtension once (about 5 min of that run on 4 cores, 19:42 to 19:48 with build.sh); outside it, the cache under ~/.cache stays warm (about 15 s).
- Done before (f1df3f1e, carried over): `render.py still|list|plan|--self-test`, the shot-list format (docstring), `tools/gate/fixtures/shots.json` and `test_shots.json`.
- Requests: SP-bt-04-R1 stands (the lead adds `python3 tools/gate/render.py --self-test` after `python3 tools/ui_gate/sheet.py --self-test` in check_all's AD-R3 section, in the merge candidate); SP-bt-04-R2 to AD stands.
- Open hypotheses: two renders at once share cargo's lock and write the library cache through a per-process temporary file, so they should not clash; not tested under load.
- Next step: none for BT-04a once ready. BT-04b next, in its own session.

## Tried and failed

- 2026-11-24 the self-test first expected a 1080 × 2340 still: `screen_settings.gd` renders at 540 × 1170, so the test now checks only that the still is not tiny and that its grayscale is 960 px, gray and not blank.
- 2026-11-24 (resync) falling back only the cache folder to TMPDIR, as first suggested: `git worktree add` then fails too, because the sandbox binds the shared .git read-only; the commit is now exported with git archive instead.
