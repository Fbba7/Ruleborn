# Tools audit, November 2026

FX1-7-audit-tools' half of the fix wave's extra checks
([bug report](../bug-report-2026-11.md)). This audit read the code the
report did not, asking one question: **can a check pass when it should
fail, or can a tool corrupt a committed file?** Its scope:

- `tools/`, outside `tools/vendor/`: the gate (`check_all.sh`,
  `run_checks.sh`), the coordination tools (`tools/coord/`), the document
  and register checks, the client/server contract, and the UI tools
  (`tools/ui_bake/`, `tools/ui_gate/`);
- the art scripts in `art/design/` and `art/ui/`;
- the client prototypes and their builder;
- the docs scripts, and the two `status.py` files the gate runs.

Every confirmed finding has a proof in
`server/test/fix_fx1_audit_tools_proofs.mjs`, named by its id. A proof runs
the repository's own tool, as it is on disk, against an input planted in a
temporary folder. It never writes inside the repository: a tool that writes
is pointed at a copy. Each proof states what should happen and fails on main
(`613f71c9`).

Every tool here is outside this task's files, so nothing is fixed here.
`server/test/fix_fx1_audit_tools.test.mjs` wraps each proof in `stillOpen`
(`fix_fx2_open.mjs`). The wrapper passes while the proof fails, and fails
with "<id> no longer fails" once the finding is fixed. Whoever fixes a
finding moves its proof out of the list and into a plain test of its own.
To see why a proof fails, run it plain (the command is in the proofs
module's header).

Every affected file belongs to the lead: no task in flight owns it. The
requests are at the end, grouped by area, and in
`docs/progress/status/FX1.json`.

| Id | Priority | Where | State |
| --- | --- | --- | --- |
| FX1-T-03 | High | tools/run_checks.sh `record` | fixed (FX1-9-tools-gate) |
| FX1-T-20 | Medium/High | tools/client_contract.py | fixed (FX1-10-tools-contract) |
| FX1-T-21 | Medium/High | tools/client_contract.py | fixed (FX1-10-tools-contract) |
| FX1-T-04 | Medium | tools/run_checks.sh `result` | fixed (FX1-9-tools-gate) |
| FX1-T-09 | Medium | tools/check_all.sh, check_dependencies.py | fixed (FX1-9-tools-gate) |
| FX1-T-22 | Medium | tools/check_all.sh, build_stamp.py | fixed (FX1-9-tools-gate) |
| FX1-T-10 | Medium | check_findings_fresh.py, check_docs_consistency.py | fixed (FX1-11-tools-docs) |
| FX1-T-17 | Medium | check_audit_ui.py, validate_content.py | fixed (FX1-11-tools-docs) |
| FX1-T-08 | Medium | tools/check_ci.py | fixed (FX1-9-tools-gate) |
| FX1-T-07 | Medium | tools/ui_bake/check_screens.py | open: request FX1-R23 |
| FX1-T-01 | Medium | server/status.py | fixed (FX1-10-tools-contract) |
| FX1-T-02 | Medium | server/status.py | fixed (FX1-10-tools-contract) |
| FX1-T-11 | Medium, latent | tools/check_document.py | fixed (FX1-11-tools-docs) |
| FX1-T-05 | Low | tools/coord/owners.py | fixed (FX1-9-tools-gate) |
| FX1-T-06 | Low | art/ui/board/build_tokens.mjs | open: request FX1-R23 |
| FX1-T-12 | Low | tools/check_docs_consistency.py | fixed (FX1-11-tools-docs) |
| FX1-T-13 | Low | tools/ui_bake/bake.js | open: request FX1-R23 |
| FX1-T-14 | Low | tools/ui_bake/check_screens.py | open: request FX1-R23 |
| FX1-T-15 | Low | tools/ui_bake/check_screens.py | open: request FX1-R23 |
| FX1-T-16 | Low | tools/ui_bake/budget_shots.py | open: request FX1-R23 |
| FX1-T-18 | Low | tools/ui_gate/golden.py | open: request FX1-R23 |
| FX1-T-19 | Low | tools/ui_gate/sheet.py | open: request FX1-R23 |

## Confirmed

### FX1-T-03: `run_checks.sh record` hands the lead exit 0 for a failed run

- **State:** fixed (FX1-9-tools-gate). The proof is now a plain test in
  `server/test/fix_fx1_tools_gate.test.mjs`.
- **Priority / category:** High, gate (a failed run reads as passed).
- **Where:** `tools/run_checks.sh` `record()` (line 248). It copies `sha`,
  `exit`, `finished_at` and `summary` from `result` into the agent's
  `precheck`, and drops `state`.
- **Input:** a run whose command exits 0 without printing "All checks
  passed.": a step that prints an error and does not stop the script, or a
  gate edited to end early. `result` reads it as `FAIL` (line 219: PASS
  needs both).
- **Should happen:** the precheck the lead reads says the run failed.
- **Happens:** `record` accepts the FAIL (line 251) and writes
  `{"exit": 0, ...}`. The protocol's reuse rule
  (`docs/guides/agent-protocol.md`, "Reusing the builder's checks") skips
  the lead's own `check_all.sh` when the precheck has `exit` 0 at
  `ready_sha`. So the failed run is the only check the candidate gets
  before main moves.
- **Evidence:** proof "FX1-T-03". On main the precheck reads
  `{"exit": 0, "summary": "== gdlint ==: skipped"}` for a run `result`
  calls FAIL.
- **Fix:** have `record` write `state` too, and write `exit` as the run's
  exit only when `state` is PASS (else the real code, or 1 if it was 0).
  Have the lead's reuse rule check `state == "PASS"` as well as `exit == 0`.

### FX1-T-20: the contract check never reads nine failure codes the server sends

- **State:** fixed (FX1-10-tools-contract). The proof is now a plain test in
  `server/test/fix_fx1_tools_contract.test.mjs`.
- **Priority / category:** Medium/High, contract (a refusal the player
  cannot read passes the gate).
- **Where:** `tools/client_contract.py` `server_reasons()` (line 84) and
  its `REFUSED` patterns (line 34). They see only a literal string in
  `new Refused(n, "x")`, `json({ error: "x" })` and `refuse("x")`.
- **Input:** codes the server sends another way:
  - `server/src/shop.mjs:182`, a ternary:
    `new Refused(400, p.gift ? "gift_needs_a_friend" : "not_a_gift")`;
  - `server/src/sim.mjs:30-32` and `:233`, the sim's error table and
    `{ error: "island_malformed" }` returned, not passed to `json(...)`:
    `island_malformed`, `universe_malformed`, `crew`, `length`, `log`,
    `checksums`, `landing`.
- **Should happen:** each code needs an `ERR_` key in every language, or
  the gate fails (the file's own promise, lines 14-19).
- **Happens:** none of the nine is read, and `client/ui/strings.csv` has
  no `ERR_` row for any of them. The player sees the raw code.
- **Evidence:** proof "FX1-T-20". On main all nine are missing from
  `server_reasons() | client_codes()`.
- **Fix:** read the codes from the server's own tables as well: the sim's
  code map in `sim.mjs`, both arms of a ternary inside `new Refused(...)`,
  and `error: "x"` in any object literal. Add a self-test plant for each
  form. Then add the nine `ERR_` rows (the strings' owner).

### FX1-T-21: the contract check never reads the client's call sites outside client/data

- **State:** fixed (FX1-10-tools-contract). The proof is now a plain test in
  `server/test/fix_fx1_tools_contract.test.mjs`.
- **Priority / category:** Medium/High, contract (a call to a route that
  does not exist passes the gate).
- **Where:** `tools/client_contract.py` `client_calls()` (line 54-56):
  `(CLIENT / "data").rglob("*.gd")`.
- **Input:** API calls made outside `client/data/`:
  `client/features/auth/auth_session.gd` and
  `client/features/weaving/weaving_controller.gd` call `api.*_json(...)`.
- **Should happen:** every client call is checked against the server's
  routes.
- **Happens:** those files are never read, so a typo in their routes passes.
- **Evidence:** proof "FX1-T-21". On main both files are missing from the
  call sites `client_calls()` returns.
- **Fix:** walk all of `client/` (skipping `.godot/` and `tests/`), as
  `client_codes()` already does. Add a self-test plant of a bad route in a
  feature folder.

### FX1-T-04: a leftover child process can turn a failed run into PASS

- **State:** fixed (FX1-9-tools-gate). The proof is now a plain test in
  `server/test/fix_fx1_tools_gate.test.mjs`.
- **Priority / category:** Medium, gate. Only unsandboxed or `CHECK_USER`
  runs: bwrap's `--unshare-pid` and `--die-with-parent` kill the children.
- **Where:** `tools/run_checks.sh` `result()` (lines 207-223). It reads the
  log's last line (`tail -n 1`) as the DONE line, and greps the whole log
  for "All checks passed.".
- **Input:** a check that fails (exit 101) and leaves a background child
  behind. The child writes "All checks passed." and a `DONE exit=0` line
  after the outer shell's own `DONE exit=101`.
- **Should happen:** the run is FAIL: the DONE line written by the runner
  itself says 101.
- **Happens:** `result` reads the child's line, and the run is PASS, exit 0.
- **Evidence:** proof "FX1-T-04". On main the state is PASS with exit 0.
- **Fix:** have the runner write its DONE line to a separate file
  (`$log.done`) that only the outer `bash -c` writes, and read the exit and
  "All checks passed." from there and from the log up to that point. Or
  kill the run's process group before writing DONE.

### FX1-T-09: nothing in the gate notices a stale dependencies.md

- **State:** fixed (FX1-9-tools-gate). The proof is now a plain test in
  `server/test/fix_fx1_tools_gate.test.mjs`.
- **Priority / category:** Medium, gate (a committed page drifts).
- **Where:** `tools/check_all.sh:127-128` runs
  `check_dependencies.py --self-test` and `--write`. `--write`
  (`check_dependencies.py:236-237`) rewrites `docs/design/dependencies.md`
  and exits 0. No step compares it with the committed file (the gate has no
  `git diff`).
- **Input:** a committed `dependencies.md` that no longer matches its
  rebuild.
- **Should happen:** the gate fails, as `build_prototype.py --check` does
  for its page.
- **Happens:** both commands exit 0. The gate rewrites the file in the
  worktree and passes, and the stale file stays on the branch.
  (Today the committed file matches its rebuild.)
- **Evidence:** proof "FX1-T-09". It runs each `check_dependencies.py`
  command line of `check_all.sh` with the output pointed at a stale copy:
  `[0, 0]`.
- **Fix:** add `--check`, which builds the page and exits 1 if it differs
  from the committed one, and run that in the gate in place of `--write`.

### FX1-T-22: the gate never runs build_stamp's check for escaped markup

- **State:** fixed (FX1-9-tools-gate). The proof is now a plain test in
  `server/test/fix_fx1_tools_gate.test.mjs`.
- **Priority / category:** Medium, gate (a published page shows `<code>` as
  text).
- **Where:** `tools/check_all.sh:122` runs only
  `build_stamp.py --self-test`. `self_test()` (lines 100-127) checks the
  stamps and its own escaping fixture. `escaped_markup()` on the real pages
  runs only in `main()` (lines 130-150), which the gate never calls.
- **Input:** a published page whose text has `&lt;strong&gt;` in it.
- **Should happen:** the gate fails, as `main()` does.
- **Happens:** the gate's command passes.
- **Evidence:** proof "FX1-T-22". It runs each `build_stamp.py` command line
  of `check_all.sh` against pages with escaped markup: `[0]`.
- **Note:** `main()` exits 1 on main today:
  `docs/audit/index.html:1583` has a double-escaped `<code>`, whose source
  is `tools/audit_register.py:13556`. Fix that before adding `main()` to the
  gate, or the gate goes red.
- **Fix:** add `python3 tools/build_stamp.py` (no flag) to the gate, after
  the source is fixed.

### FX1-T-10: three-digit register ids are not read as ids

- **Priority / category:** Medium, document checks (a pin and an open claim
  go unseen). The register reached D100 (`docs/design/dependencies.md:42`).
- **Where:**
  - `tools/check_findings_fresh.py:111` and `:124` (`LEAD`):
    `[CDFGQT]\d{1,2}`;
  - `tools/check_docs_consistency.py:419` (`spec_open_claims`):
    `[A-Z]{1,2}\d{1,2}`, with `\b` on both sides.
- **Input:** a check whose docstring opens "D100.", and a spec bullet
  `**D100** cap`.
- **Should happen:** D100 is pinned by that check, and the bullet claims
  D100.
- **Happens:** `\d{1,2}` stops at "D10" and `\b` then fails, or (with
  `findall`) "D10" is read in place of D100. D100 and every later id are
  invisible to both checks.
- **Evidence:** proof "FX1-T-10". On main both lookups miss D100:
  `[false, false]`.
- **Fix:** `\d+` (or `\d{1,3}`) in all three patterns, and a self-test row
  for a three-digit id in each.

### FX1-T-17: a self-test killed mid-run leaves its plant in a committed file

- **Priority / category:** Medium, file corruption.
- **Where:** two self-tests plant into the committed file itself, and
  restore it only in `finally`:
  - `tools/check_audit_ui.py` `_self_test_built()` (lines 467-514) writes a
    planted `sim/status.json`;
  - `tools/validate_content.py` `self_test()` (lines 916-929) writes a
    planted `content/ruleborn.json` (`"look": "The Long Night"`).
- **Input:** the process dies between the write and the `finally`: a gate
  timeout, a SIGKILL, the five-hour limit stopping the session, or the
  watchdog killing a run.
- **Should happen:** the committed files are unchanged.
- **Happens:** the plant stays. The next `git add -A` or `git commit -a`
  commits a wrong `sim/status.json` (what is built) or a wrong era name in
  the content.
- **Evidence:** proof "FX1-T-17". Both self-tests run against copies, killed
  with `os._exit(9)` at a step inside the window. Both copied files are left
  changed.
- **Fix:** plant into a temporary copy, and point the check at it (both
  modules already read their root from a module variable: `build_audit.SIM`,
  `CONTENT`). A temporary copy also lets two runs share a checkout.

### FX1-T-08: check_ci passes wider permissions and a commented-out command

- **State:** fixed (FX1-9-tools-gate). The proof is now a plain test in
  `server/test/fix_fx1_tools_gate.test.mjs`.
- **Priority / category:** Medium for the permissions, Low for the
  comment. CI (the workflow can be widened unseen).
- **Where:** `tools/check_ci.py` `problems()`:
  - line 40, `^permissions:\n  contents: read\s*$` with `re.M`: `$`
    matches at the end of that line, so more lines may follow;
  - lines 48-49, `command not in text`: a substring test.
- **Input:** the workflow with `  actions: write` added under
  `permissions:`, and the workflow with `npm test` turned into `# npm test`.
- **Should happen:** both are refused: the check says "permissions is not
  exactly contents: read", and a required command must run.
- **Happens:** both pass.
- **Evidence:** proof "FX1-T-08". On main `problems()` finds nothing in
  either: `[false, false]`.
- **Fix:** parse the `permissions:` block to the next top-level key and
  compare it with `{"contents": "read"}`. Look for each required command
  on an uncommented `run:` line.

### FX1-T-07: check_screens counts no texture for single quotes or an upper-case extension

- **Priority / category:** Medium, UI budget (chrome outside the kit goes
  uncounted).
- **Where:** `tools/ui_bake/check_screens.py:46`, `IMAGE_LOAD`:
  `\b(?:pre)?load\(\s*\"[^\"]*\.(?:png|svg|webp|jpe?g)\"`. Double quotes
  only, and case-sensitive.
- **Input:** `load('res://world/a.png')` and `preload("res://world/a.PNG")`.
  GDScript takes both quotes, and Godot imports `.PNG`.
- **Should happen:** one texture each.
- **Happens:** none.
- **Evidence:** proof "FX1-T-07". On main the counts are `[0, 0]`.
- **Fix:** `["']` for the quotes (matching the closing one) and
  `re.IGNORECASE` on the extension, with self-test rows for both.

### FX1-T-01: server/status.py lets a passing test hide a failing one of the same name

- **State:** fixed (FX1-10-tools-contract). The proof is now a plain test in
  `server/test/fix_fx1_tools_contract.test.mjs`.
- **Priority / category:** Medium, gate (a failure reads as passed).
- **Where:** `server/status.py:28-29`. Results go into a dict keyed by the
  test's name, so a later `ok` with the same name overwrites an earlier
  `not ok`.
- **Input:** two test files, each with a top-level test named "same name":
  one fails and one passes.
- **Should happen:** the run fails.
- **Happens:** "tests: 1 of 1 passed", exit 0. `check_all.sh:43` runs this
  file, and its `npm test` step does catch the failure, but
  `server/status.json` (what `tools/completion.py` reads as built) records
  the test as passed.
- **Evidence:** proof "FX1-T-01". On main: "tests: 1 of 1 passed".
- **Fix:** key by `file › name`, or fail when a name repeats. Read node's
  own summary (`# fail N`) and fail if it is not 0.
- **Also:** `client/status.py:262-263` parses the same way. It needs
  Godot, so this proof does not run it.

### FX1-T-02: server/status.py records a skipped test as passed

- **State:** fixed (FX1-10-tools-contract). The proof is now a plain test in
  `server/test/fix_fx1_tools_contract.test.mjs`.
- **Priority / category:** Medium, gate (a test never run reads as passed).
- **Where:** `server/status.py:28-29`. TAP's `ok 1 - name # SKIP` matches
  `^(not ok|ok) \d+ - (.+)$` as `ok`, with "# SKIP" in the name.
- **Input:** `test("never run", { skip: true }, () => assert.fail("x"))`.
- **Should happen:** the run fails, or the test is recorded as skipped and
  not counted as built. The program never skips a test.
- **Happens:** "1 of 1 passed", recorded as passed.
- **Evidence:** proof "FX1-T-02".
- **Fix:** read the `# SKIP` and `# TODO` directives, record them as
  skipped, and fail on any.

### FX1-T-11: check_document passes a failed check that tracks an unknown id

- **Priority / category:** Medium, latent. Document checks (a typo turns a
  break into "open").
- **Where:** `tools/check_document.py:220-225`, `_is_open()`: an id the
  register does not hold is "open". So `Ledger.check(..., tracks="C999")`
  that fails is OPEN, not BREAK (line 185), and `report()` exits 0.
- **Input:** a failed check with `tracks="C999"`, or with a typo such as
  `tracks="C32"` for C23.
- **Should happen:** the check breaks the build. An id that is not in the
  register is a mistake in the check.
- **Happens:** the report is 0.
- **Evidence:** proof "FX1-T-11". No check on main tracks an unknown id
  today, hence latent.
- **Fix:** `_is_open` raises (or the ledger records BREAK) for an id the
  register does not hold.

### FX1-T-05: owners.py misses overlaps of `?` and `[..]` globs, and of an exclusion with a re-inclusion

- **State:** fixed (FX1-9-tools-gate). The proof is now a plain test in
  `server/test/fix_fx1_tools_gate.test.mjs`.
- **Priority / category:** Low, coordination (two tasks can be given one
  file).
- **Where:** `tools/coord/owners.py`:
  - `_segments_meet()` (line 90 on): with both sides wild, it compares
    only what comes before and after `*`, so `icon_?.svg` and `icon_a*`
    never meet;
  - `files_overlap()` (line 134): a pair is dropped when a negation
    covers either side, even when a later positive glob in the same list
    re-includes a path (`owned()` honours order; this does not).
- **Input:** `overlap("client/ui/icon_?.svg", "client/ui/icon_a*")`,
  `overlap("client/[ab]x.gd", "client/a*")`, and
  `files_overlap(["client/ui/**", "!client/ui/art/**", "client/ui/art/x.gd"],
  ["client/ui/art/**"])`.
- **Should happen:** all three overlap (`icon_a.svg`, `ax.gd`,
  `client/ui/art/x.gd`).
- **Happens:** `[false, false, false]`. No backlog glob uses `?` or `[..]`
  today, which keeps this Low.
- **Evidence:** proof "FX1-T-05".
- **Fix:** with both segments wild, err towards yes (say they meet unless
  both are literal), as the docstring promises. In `files_overlap`, apply a
  negation only to the positives before it.

### FX1-T-06: build_tokens.mjs `--check` passes anything under a path with a space

- **Priority / category:** Low, art script (a stale `tokens.css` passes).
- **Where:** `art/ui/board/build_tokens.mjs:93`:
  `import.meta.url === \`file://${process.argv[1]}\``. The URL is
  percent-encoded and argv is not, so under a path with a space (or any
  character a URL encodes) the main block never runs, and the script exits
  0 having checked nothing.
- **Input:** a checkout at `/tmp/fx1 audit tools x/` with a junk
  `tokens.css`.
- **Should happen:** `--check` exits 1, as it does without the space.
- **Happens:** exit 0. The gate's worktree (`/tmp/check-<sha>`) has no
  space, which keeps this Low.
- **Evidence:** proof "FX1-T-06".
- **Fix:** compare `fileURLToPath(import.meta.url)` with
  `path.resolve(process.argv[1])`.

### FX1-T-12: check_one_fact_home misses a design fact restated with a type annotation

- **Priority / category:** Low, document checks.
- **Where:** `tools/check_docs_consistency.py` `check_one_fact_home()`
  (line 618): only `ast.Assign` is looked at, so `ast.AnnAssign` is not.
- **Input:** `HOLD_BAND: tuple = (30.0, 45.0)` in a tool.
- **Should happen:** "states HOLD_BAND for itself; import it from
  design_facts".
- **Happens:** nothing is reported.
- **Evidence:** proof "FX1-T-12".
- **Fix:** take `ast.AnnAssign` (its `target`) as well.

### FX1-T-13: bake.js paginate makes pages taller than MAX_SIDE

- **Priority / category:** Low, UI bake (a valid family is refused).
- **Where:** `tools/ui_bake/bake.js` `paginate()` (line 476 on). A shelf is
  added to a page when it fits the width; the page's height is then rounded
  up to the next power of two with no limit, so a page can pass `MAX_SIDE`.
- **Input:** pieces of 2000×1021, 2000×1020 and 2000×100.
- **Should happen:** pages within 2048×2048: one page per tall piece.
- **Happens:** page heights `[4096, 128]`. Line 303 then refuses the
  manifest, so nothing bad ships, but the family cannot bake.
- **Evidence:** proof "FX1-T-13".
- **Fix:** start a new page when `y + p.h + PAD` would pass `MAX_SIDE`,
  checking the padded height the rounding uses.

### FX1-T-14: check_screens `--root` passes a folder with no screens

- **Priority / category:** Low, UI budget.
- **Where:** `tools/ui_bake/check_screens.py:315-322`, `main()`: `--root`
  with a wrong path (or an empty checkout) counts nothing and passes.
- **Input:** `main(["--root", <empty folder>])`.
- **Should happen:** exit 1: no screens found where screens must be.
- **Happens:** exit 0.
- **Evidence:** proof "FX1-T-14".
- **Fix:** fail when the scope has no `.gd` file.

### FX1-T-15: check_screens excuses a fill cleared on one branch only

- **Priority / category:** Low, UI budget.
- **Where:** `tools/ui_bake/check_screens.py:116-124`, `_clear_later()`:
  any later `name.draw_center = false` in the function excuses the fill,
  whatever block it is in.
- **Input:** `var box := StyleBoxFlat.new()` and, inside `if flag:`,
  `box.draw_center = false`.
- **Should happen:** one fill (it is drawn whenever `flag` is false).
- **Happens:** 0 fills.
- **Evidence:** proof "FX1-T-15".
- **Fix:** excuse only a clear at the same indentation as the `new()`.

### FX1-T-16: budget_shots `--record` cannot record a new screen

- **Priority / category:** Low, UI budget (the documented path is blocked).
- **Where:** `tools/ui_bake/budget_shots.py:172-186`. A screen with no
  figures gets "no recorded figures; run --record" in `failures`, and
  `--record` then refuses because there are failures.
- **Input:** `--record` with figures recorded for `home` and a new screen,
  `newscreen`, with none.
- **Should happen:** the new screen's figures are recorded (the usage,
  line 15: "--record writes today's figures when none is recorded").
- **Happens:** exit 1, and nothing is written.
- **Evidence:** proof "FX1-T-16". On main: `[1, false]`.
- **Fix:** do not add the "no recorded figures" problem when `--record` is
  given; record the new keys, and still refuse any rise on recorded ones.

### FX1-T-18: golden.py passes when labels-blind.md is missing

- **Priority / category:** Low, UI gate (the blind labels' check is skipped).
- **Where:** `tools/ui_gate/golden.py:317`:
  `blind_text=BLIND.read_text() if BLIND.exists() else None`.
- **Input:** `BLIND` pointing at a missing file.
- **Should happen:** the check fails: the blind labels are part of the
  golden set.
- **Happens:** exit 0.
- **Evidence:** proof "FX1-T-18".
- **Fix:** fail when the file is missing, or make it optional only behind a
  flag the gate never passes.

### FX1-T-19: sheet.py `crops` crashes on a name with a slash

- **Priority / category:** Low, UI gate (a crash, not a silent pass).
- **Where:** `tools/ui_gate/sheet.py:288`, `im.save(out / f"{name}.png")`.
- **Input:** `sheet.py crops art/ui/board/board.shot.json <out>`. Some of
  its names contain "/".
- **Should happen:** one crop per name.
- **Happens:** `FileNotFoundError`, because the folder for the part before
  the slash does not exist.
- **Evidence:** proof "FX1-T-19".
- **Fix:** replace "/" in the file name (or create the parent folder).

## Latent, no proof

These need a state the protocol does not produce today, or are a check
that proves less than it says. Not proven, so not confirmed.

- **`tools/coord/archive.py`:** a task merged again under an id already
  archived is dropped. `cycle_needed` counts an `_archived` dependency as
  met even while a live task with that id is open. Both need id reuse,
  which the protocol never does (merged is a terminal state).
- **`twice_stated`:** its self-test checks its own copy of `pairs()`, not
  `restatements()`, which the check runs.
- **`check_edits`:** the closed-set excuse accepts any edit to a file that
  is in the set.
- **`check_unread_fields`:** `KNOWN_UNREAD` holds a stale
  `"State.essence"`, and `@dataclasses.dataclass(...)` is not recognised as
  a dataclass.
- **`english_us`:** some suggested spellings are wrong.
- **`build_brief --check`:** it never compares the built page with the
  committed one.
- **`build_prototype`:** `GRADE` is typed by hand, not derived.
- **`native_strings`:** the iOS `%@` is not made positional, and a literal
  `%` is not escaped.
- **`version_diff`:** one self-test check is tautological.
- **`validate_content`:** the D14 pin compares a constant with itself.
- **`tools/ui_gate/compare.py`:** `--note` is in the usage but not
  implemented.

## Unproven

- **`measure.gd` and `colour_check` ignore the ink's alpha.** A
  half-transparent ink is measured at full strength: 6.98:1 measured
  against 3.70:1 as drawn, by hand arithmetic. Proving it needs Godot, at
  `/root/.cache/ruleborn/Godot_v4.7.2-stable_linux.x86_64`, in the test
  run; not attempted in `npm test`.
- **`export_icons --groups` keeps stale entries.** Proving it needs
  playwright and the design sources. Read, not run.
- **`sheet.py` `_hex` drops alpha.** Read only. No caller passes an alpha
  that matters today.
- **`owners.py changed()` and git's quotePath.** A path git quotes (a
  non-ASCII name) is not matched. Tried: it fails safe, since the unmatched
  path is reported as outside the task's files. Not a pass that should
  fail.

## Rejected or sound

Read and found to fail when they should:

- `league_model --check`; `sim/status.py`; the harness runners;
- `check_docs_consistency.py --self-test` (it does not rewrite README);
- `client_strings`; `privacy_manifest --check`;
  `check_prototype_conformance.py`; `client/pack_check`;
  `inventory_homes`;
- `validate_content.py`'s main checks;
- `build_stamp.py`'s `digest()` and `stamped()`;
- `build_prototype.py --check`.

## Requests to the lead

Each has a default: the lead seeds fix tasks after the FX tasks already
open, in priority order (High first), one task per group, each with a plain
test that replaces the proof's `stillOpen` entry.

- **FX1-R20, the gate and coordination tools** (done: FX1-9-tools-gate
  fixed all six): FX1-T-03 (first),
  FX1-T-04, FX1-T-09, FX1-T-22 (after its source fix), FX1-T-08, FX1-T-05.
  Files: `tools/run_checks.sh`, `tools/check_all.sh`,
  `tools/check_dependencies.py`, `tools/build_stamp.py`,
  `tools/check_ci.py`, `tools/coord/owners.py`, and the protocol's reuse
  rule for FX1-T-03.
- **FX1-R21, the contract and status files** (done: FX1-10-tools-contract
  fixed all four): FX1-T-20, FX1-T-21,
  FX1-T-01, FX1-T-02. Files: `tools/client_contract.py`,
  `server/status.py`, `client/status.py`, and nine `ERR_` rows in
  `client/i18n/strings.csv` (thirteen once the check read every code: era,
  manifest, method_not_allowed and no_landing_realm too).
- **FX1-R22, the document checks** (done: FX1-11-tools-docs fixed all
  four): FX1-T-10, FX1-T-17, FX1-T-11, FX1-T-12. Files: `tools/check_findings_fresh.py`,
  `tools/check_docs_consistency.py`, `tools/check_audit_ui.py`,
  `tools/validate_content.py`, `tools/check_document.py`.
- **FX1-R23, the UI tools (after the UI resumes, or with it):** FX1-T-07,
  FX1-T-06, FX1-T-13, FX1-T-14, FX1-T-15, FX1-T-16, FX1-T-18, FX1-T-19.
  Files: `tools/ui_bake/`, `tools/ui_gate/`,
  `art/ui/board/build_tokens.mjs`.
