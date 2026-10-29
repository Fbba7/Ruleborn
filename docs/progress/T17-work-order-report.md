# T17: report on the work order to fix the operating model and the brief

The owner's work order listed gaps G-01 to G-66 in
[agent-program.md](../guides/agent-program.md) and
[agent-brief.md](../guides/agent-brief.md). This is T17's report on it, in
the order's own format. The new page it recommended is
[agent-protocol.md](../guides/agent-protocol.md); the backlog format is
[backlog.example.json](backlog.example.json). No code was written.

Deadline: T17's prompt said 12:00 UTC on 29 October, which had passed when
the session started at 22:06 UTC. The integrator corrected it by scheduled
message (fired 22:06 UTC, read 22:19 UTC): STOP_AT is 04:00 UTC on 30 October,
with a target of a green, final push by 23:20 UTC on 29 October. The
correction is acknowledged here and in [`T17.md`](T17.md). The earlier
deadline is finding G-70.

## 1. Every gap and its outcome

"Fixed" means the pages now carry the fix: P is the program, R the protocol,
B the brief, E the backlog example. Lines cited in `report.md` are from
`docs/art/ui-quality/report.md` at this commit.

| Gap | Outcome | Where, or why |
|---|---|---|
| G-01 Order of authority | Fixed | P intro; R "Order of authority"; B intro. An exception for the merge rule is recorded in R (see G-69) |
| G-02 Roster and schedule | Fixed; partly closed by the repository | Role definitions for AD, AIA and AIA-2 and every branch were already in `report.md` lines 154–166 and the per-phase counts in lines 180–185. Added: R "The roster" (id, role, branch, model, phases, globs, tier) and "The schedule against the cap"; AD and AIA rows in P's roles table; a roster link in B |
| G-03 One state machine | Fixed | R "Tasks and their states" (the order's table, transitions, `agent_state`); used in P, B and E |
| G-04 Leases timed from pushes | Fixed | R "The status file" (`seen_at`, the 45-minute cap, `long_run`); B says "commit and push" |
| G-05 Claim tie-break | Fixed | R "The coordinator and the lead" (earlier push as the coordinator sees it; lower id on a tie); P and B claiming steps |
| G-06 Busy stalls | Fixed | `progress_marker` in R's schema; the flag in R "Alerts" |
| G-07 Merge, then test | Fixed | R "The merge queue" (the order's text); P "Merging"; B "Ready, and after". `report.md` line 390 still states the old rule: request T17-R1 |
| G-08 Where coordination data lives | Owner decision D-01, default applied | Main, made harmless by G-07; bookkeeping touches only `docs/progress/**` (R, P) |
| G-09 Which status copy counts | Fixed | R "The status file"; P; B reads with `git show origin/<branch>:…` |
| G-10 Coordinator and the lead's trigger | Fixed, build tasks BT-01 and BT-02, owner decision D-02 | R duties table and "One cycle"; the 30-minute scheduled cycle until BT-01 |
| G-11 The lead's status and failover | Fixed | R "The lead's own status and failover"; roster row; alert list. Residual gap: G-67 |
| G-12 Who restarts dead sessions | Fixed | R "One cycle" step 6; P "Failure recovery"; B "Time and stopping" |
| G-13 Alerts and owner channel | Fixed, owner decision D-03 | R "Alerts"; P "The owner's cadence" |
| G-14 The lead's hands-on work | Fixed, owner decision D-10, build task BT-08 | P lead row; B rule 1's exception and "If you are the lead"; roster |
| G-15 Team size from throughput | Fixed, owner decision D-05 | R "The sizing rule"; P "Merging" and "Concurrency" |
| G-16 Enforce ownership | Fixed, build task BT-02, owner decision D-14 | R "The merge queue" (ownership check, by hand until BT-02); P |
| G-17 When blocked | Fixed | R "When someone else's file blocks you"; B "When you're stuck" |
| G-18 Main red, failures outside your files | Fixed | R; P "Merging"; B "When you're stuck" |
| G-19 Request format and routing | Fixed | R "The status file" and "Messages and requests"; B; E's status example in R |
| G-20 After marking ready | Fixed | B "Ready, and after"; P "Sessions"; R trace A |
| G-21 New files | Fixed | Globs in R's task format, P, B rule 2; E uses globs |
| G-22 Ownership per agent | Fixed | R roster and task format; P "One owner per file" |
| G-23 Lapsed lease takeover | Fixed | R; P "Leases"; B claiming step 5; `prior_branch` and `prior_sha` in E (`P1-AIA-kit-1`) |
| G-24 Files Godot generates | Fixed (V-06 holds) | B rule 2; R |
| G-25 Specialists and idle tasks | Fixed | P roles and idle queue; B "If you are a specialist" |
| G-26 Changing a frozen contract | Fixed | R "Changing a frozen contract"; P contract-owner row; B "If you own a contract" |
| G-27 Shared things nobody owns | Fixed; partly closed by the repository | `report.md` line 171 already names owners for tokens, the theme, hotspot files and the string table. Added the rest in R "Shared things and their owners" and the baseline rule in R and P |
| G-28 Task size and overruns | Fixed | P "One task per session"; B claiming step 7. E's split tasks follow it; see G-68 |
| G-29 A safe way to run checks | Fixed, build task BT-03 (V-06, V-07, V-14 hold) | R "Running the checks"; B rule 7 |
| G-30 Record the pre-check | Fixed | `precheck` in R's schema and B |
| G-31 Progress line and Weight | Fixed | P and B headers; no "NN%" left |
| G-32 Handoff kept current | Fixed | P "Sessions"; B "Reporting" ("Tried and failed") |
| G-33 How agents use the gate | Fixed, build task BT-05; partly closed by the repository | `report.md` line 345 names the UI wave's verdict folder. Added: `gate_items`, `attempts`, `gate_request`, the launcher and the verdict format (R "The gate, step by step"; B "The gate"; E) |
| G-34 The gate before calibration | Fixed; largely closed by the repository | `report.md` lines 180–182 and 193 already make the golden set a phase 0 task and the kit contract an owner approval (O2). Added shadow mode and the contract-board rule (R, P item 6) |
| G-35 Calibration metrics; split and Unknown | Catch rate on the three-sample decision and a false-block target of 20% are closed by `report.md` lines 337–338. Split and Unknown defaults fixed as owner decisions D-06 and D-07 | R step 4; P item 2. The UI wave's own split rule outranks: request T17-R4 |
| G-36 The gate makes its own evidence | Fixed, build task BT-04 | P item 4; R step 2; AD owns the shot lists |
| G-37 Gate capacity and fallback | Fixed, owner decision D-04 | P item 12; R "Capacity" |
| G-38 Appeals and escalation | Fixed | P item 9 and "Model routing"; R steps 5–6; B |
| G-39 Boards after merge; audit rework | Fixed, owner decision D-08 | P item 7. The UI wave's plan holds player-visible changes until their board stands (`report.md` line 394); that is noted as its higher-authority rule |
| G-40 Rubric and golden-set locations | Fixed; partly closed by the repository | The UI wave's paths are in `report.md` lines 196–199 (step 1). Added the default paths and the lead as the decider of "new kind" (P item 8) |
| G-41 Review of the integrated product | Fixed | P item 11; roster (AD); hours by request T17-R5 |
| G-42 Motion, feel and flow | Fixed | P item 10 and the cadence table |
| G-43 Measuring usage | Fixed, owner decision D-11 | P "Concurrency" items 2–3 |
| G-44 Runaway sessions | Fixed | P "Concurrency" item 7; R |
| G-45 Stopping, "never early", empty backlog | Fixed | P stop protocol step 4 and "Concurrency" item 4; B "Time and stopping" and claiming step 2 |
| G-46 Last full check | Fixed | B "Time and stopping"; R; P "Failure recovery" |
| G-47 Each task's model | Fixed | `model` in R, E and B's prompt template; P "Model routing" |
| G-48 Staggering and the usage window | Fixed | P "Concurrency" item 5 (`start_at`); digest every 5 hours of clock time in the cadence table |
| G-49 Proposed settings | Owner decision D-09, default applied | P "Sessions" and "Hooks and settings": proposed, not set; B rule 9 relies on none. Corrections to P3 and P6: requests T17-R2 and T17-R3 |
| G-50 Wave start | Fixed | R "Waves: start, metrics and close"; P "Starting a wave" |
| G-51 Wave close | Fixed | R; P "Closing a wave" |
| G-52 Measuring the operating model | Fixed, build task BT-07 | R metrics table with thresholds; P |
| G-53 Owner time and absence | Fixed, owner decision D-12 | P cadence table recomputed (about 15–20 h) and the absence rule; request T17-R6 |
| G-54 Old ownership overlaps | Closed by the repository; wording fixed | `report.md` line 164 gives `client/scripts/screen_*.gd` and `client/tests/shots/screen_*.gd` to S3. P's "Tracks" now says so |
| G-55 Phase exit criteria | Fixed | P "Split by slice"; R |
| G-56 Sub-leads | Fixed | P and R: not used in the UI wave |
| G-57 Untrusted text and secrets | Fixed | B rule 10; P "Communication" |
| G-58 Backlog order | Fixed | R task format; P; B; `critical` in E |
| G-59 Guards for new optimisations | Fixed | P; R task format; E `P1-K1-atlas-pack` |
| G-60 Pinned toolchain | Build task BT-09 (owner: the lead) | P "Failure recovery" lists today's pins (V-15); B step 2 |
| G-61 Brief and program drifting | Build task BT-06 | The manual check of section 9.5 below |
| G-62 Sections per role; prompt template | Fixed | B "Your prompt" and the four role sections |
| G-63 What a new agent cannot find | Fixed | B "Starting a session", "Your status file", "Requests and messages"; quick checks defined in R "Terms" |
| G-64 "When you're stuck" | Fixed | B "When you're stuck" |
| G-65 Wave guards in "ready" | Fixed | B rule 7, R "Terms" and P use one definition of the full checks |
| G-66 Wording fixes in the brief | Fixed | All eight: commit and push; main explained; current version via `tools/design_doc.py`; `send_later` optional; "Don't re-read files that haven't changed"; image subagents never judge; rule 3 links the decision brief; two fails mean hand off |

## 2. Checks V-01 to V-16

| Check | Answer |
|---|---|
| V-01 | `docs/guides/agent-program.md`, `docs/guides/agent-brief.md`, `docs/guides/checks.md`, `docs/progress/backlog.example.json` |
| V-02 | `report.md` section 3.1 defines the roster, branches and files of Lead, AD, Gate, AIA, AIA-2, K1, S1–S3 (lines 150–172); 3.2 the phases with builders at once 3, 4, 5, 5 (lines 176–187); 3.5 the gate: three samples, splits and Unknown to the owner's exceptions queue, verdicts at `gate/verdicts/<item>-<round>.md`, catch rate on three-of-three, false blocks at most 20%, at most 30% to exceptions (lines 293–348); 3.8 the old merge rule and the guards, with baselines in `tools/ui_bake/budgets.json` (lines 386–408); 3.9 the settings P1–P6 (lines 427–436) |
| V-03 | No `.github/workflows` and no CI. The integrator reports that it merges by hand and uses scheduled tasks (cron-style triggers on the owner's account, and `send_later`); a disabled scheduled task delivered nothing; one-shot messages are confirmed by checking that the target session is running |
| V-04 | Not established. Every agent is told to push only to its own branch, the integrator only to main; nothing configures branch protection (reported by the integrator; no `.claude/` directory exists). D-01's default applies |
| V-05 | Before: `id`, `title`, `phase`, `role`, `files`, `deps`, `done_when`, `estimate_h`, `tier`, `state`, `claim`, `ready_sha`, `merged_sha`; `idle_queue`; `messages` with `acked_at`. Missing: `gate_items`, `attempts`, `model`, `critical`, `prior_branch`, `prior_sha`, the request fields; all added |
| V-06 | `.gitignore` ignores no logs, and a log is already committed: `fe-base.log` at the root (commit `5b864e6`, finding G-72). Godot's generated files are tracked: 468 `.uid` and 564 `.import` files |
| V-07 | `check_all.sh` runs under `set -euo pipefail`, prints a `== <check> ==` heading per step, stops at the first failure with a non-zero status, and ends `All checks passed.` on success. Sub-checks: the table in `checks.md`. "Quick checks" were defined nowhere; R "Terms" defines them |
| V-08 | `check_docs_consistency.py` checks relative links, "§N.M" against the current design document, register counts, the README's tools listing, the spec index, one URL per published page and the document's version. It does not check model names: that rule is on trust |
| V-09 | Yes: the prompt makes T17 the owner of the program, the brief and the backlog example, and allows new pages beside them and their README rows |
| V-10 | `design-tools.md` "The decision brief": `docs/decisions/brief.json` built by `tools/build_brief.py` into `docs/decisions/index.html`. Linked from B rule 3 |
| V-11 | The research labels: coordination and integrator bottlenecks reported; self-assessment inflation measured; JSON backlogs and leases reported; acknowledgements and the stop protocol inference; usage tiers inference; compaction a vendor setting plus inference. The pages keep these labels, and mark the new rules (leases from pushes, request deadlines, the sizing rule, thresholds) as inference |
| V-12 | On main, `docs/progress/` holds only the T-files and `backlog.example.json`: no `status/`, `requests.md` or `backlog.json` yet |
| V-13 | `tools/ui_bake/` does not exist; `guard.sh` is K1's to write in phase 1. The pages say "once K1 has written it" |
| V-14 | A job started with a plain `&` survived the end of its tool call (T17 started `sleep 300 &` and saw it running in a later call; the integrator saw a `check_all.sh` run finish that way). A container restart killed every running process (reported by the integrator). The harness also documents a background mode for long commands. Both recorded in R |
| V-15 | Godot `4.7.2-stable` in `client/build.sh`; Node `>=22.5` in `server/package.json`; Rust has no `rust-toolchain.toml` (`checks.md` asks for 1.82 or later); Python packages are pinned only in the brief (`gdtoolkit==4.*`, `playwright==1.63.0`); no `requirements.txt` |
| V-16 | `tools/design_doc.py` declares the current version (v3.7) once; every other tool reads it from there |

## 3. Owner decisions applied (defaults)

| ID | Default applied |
|---|---|
| D-01 | Coordination data on main; bookkeeping touches only `docs/progress/**` |
| D-02 | The lead's scheduled cycle every 30 minutes, enabled by the owner; the coordinator script later (BT-01) |
| D-03 | `docs/progress/owner-inbox.md` plus a direct message |
| D-04 | Pause gated merges for the affected qualities; scripted checks continue; alert the owner |
| D-05 | Three builders until merge throughput is measured; claiming with the tie-break |
| D-06 | Three more samples on a split; 4 or more fails of 6 is a fail; otherwise a pass reviewed on the next board (where the wave's plan sets no rule) |
| D-07 | False-fail target at most 20% (the UI wave's plan already sets it) |
| D-08 | Boards after merge; an objection creates a fix-or-revert task |
| D-09 | Compaction at 200k and the Stop hook: proposed, not set |
| D-10 | The lead owns hotspot files, through backlog tasks |
| D-11 | Drop to three builders when the share of the weekly limit used exceeds the share of the wave elapsed plus 10 points |
| D-12 | About 15–20 owner hours per two-week wave |
| D-13 | Status files are not dropped from candidates |
| D-14 | Protect main so only the lead or coordinator moves it, if the platform allows |

## 4. Requests for files T17 does not own

All are in T17's status file,
[`status/T17.json`](status/T17.json), in the request format, non-blocking,
due 2026-10-31T12:00:00Z, each with a default.

| Id | To | File | Ask |
|---|---|---|---|
| T17-R1 | lead | `report.md` 3.8, 3.2 | Merge-then-test queue; phase 2's five builders subject to the sizing rule |
| T17-R2 | lead | `report.md` 3.9 | P3 must be a `PostToolUse` hook returning `hookSpecificOutput.updatedToolOutput` |
| T17-R3 | lead | `report.md` 3.9 | P6 likely does not apply to cloud sessions; propose `CLAUDE_CODE_RETRY_WATCHDOG=1` and its recheck interval; P1's range |
| T17-R4 | lead | `report.md` 3.5, 3.1 | D-06 for splits; Unknown after 24 hours; JSON verdicts written by the launcher; shadow mode |
| T17-R5 | lead | `report.md` 3.1, 3.3, 3.7 | Hours for AD's flow reviews, motion clip boards and the lead's cycle |
| T17-R6 | lead | `report.md` 3.4 | The owner's hours against 15–20; the absence rule |
| T17-R7 | T15 | `checks.md` | The worktree runner and `DONE` marker; name the quick checks |
| T17-R8 | T15 | `DOCS-CHANGES.md` | Record the new protocol page and the rewrites |
| T17-R9 | owner | the owner's settings | Enable the lead's cycle (D-02), protect main (D-14), decide the settings (D-09), confirm the channel (D-03) |
| T17-R10 | lead | `fe-base.log`, `.gitignore` | Remove the committed log; ignore `*.log` (G-72) |

## 5. Acceptance tests

**9.1 Traces.** All four are rewritten in R "Worked examples": A ends with
every change merged and no wasted re-check; B ends `parked` with the re-run
written down, the lead having restarted the session; C ends answered,
defaulted or with an owner alert by `due`; D ends with the contract merged
on the owner's approval and no item merged on an uncalibrated verdict. No
step breaks.

**9.2 Lessons table.** P's lessons table has a "Now" column. Every row is
closed or closed once its named build task exists, except: the Stop hook and
compaction setting (proposed, so "mostly closed") and the lost-message row,
which stays partly open until the coordinator runs outside the lead (G-67).

**9.3 Cold-agent test.** Walked against the brief alone, for "S2, branch
`claude/ui-screens-home`, task P2-S2-home":

| Step | Where the brief answers it |
|---|---|
| 1 First session, no handoff | "Starting a session" step 3 |
| 2 Quick checks | Rule 7; "Starting a session" step 5 |
| 3 Environment | "Starting a session" step 2 |
| 4 Pick a task | "Claiming work" steps 1–2 |
| 5 Others' claims | "Claiming work" step 3 |
| 6 Status file | "Your status file", with the schema link |
| 7 Own files | "Your prompt"; rule 2; the roster link |
| 8 Request the gate | "The gate" |
| 9 Read a verdict | "The gate" |
| 10 Mark ready | "Ready, and after" |
| 11 After ready | "Ready, and after" |
| 12 Learn of a resync | "Ready, and after": the lead restarts you; the backlog shows `resync` |
| 13 Messages | "Requests and messages"; "Starting a session" step 4 |
| 14 Requests | "Requests and messages" |
| 15 Foreign conflict; outside failure | "When you're stuck" |
| 16 Stop | "Time and stopping" |

**9.4 Role and rule matrix.** Every cell is ✓ in R "Roles against the
rules", each with the rule that makes it so.

**9.5 Consistency.** Done by hand (BT-06 will automate it): one state list
(`open`, `claimed`, `working`, `ready`, `resync`, `blocked`, `merged`,
`parked`; and `active`, `waiting`, `stopped`, `done`) in R, P, B and E; one
definition of the full checks; every mechanism an agent carries out is in B
with a link to R or P; every JSON block in R and E parses with
`python3 -m json.tool`.

**9.6 Coverage.** Every heading of the program and the brief in Appendix D
was edited; "Lessons" was edited per Appendix C.

**9.7 Checks.** The documentation check passes. The full checks' result on
the final commit is in T17's final message and in
[`T17.md`](T17.md).

## 6. New findings

**G-67 · high · [inferred] · Nothing outside the lead notices a dead lead**
- Where: R "The lead's own status and failover".
- Problem: until BT-01 runs on its own trigger, the only thing that reads
  `status/lead.json` is the lead's own cycle.
- Fix: BT-01 runs as its own scheduled task, separate from the lead's
  session, and raises the stale-lead alert; until then the owner checks the
  lead's status and its scheduled task's last run daily.
- Outcome: owner decision (default: the owner's daily check); BT-01's
  `done_when` should name it.

**G-68 · medium · [text] · Two build tasks are bigger than one session**
- Where: the order's BT-01 (8 h) and BT-04 (5 h), against G-28's 4-hour limit.
- Fix: the lead splits them when it seeds the real backlog. The example keeps
  the order's figures so they can be checked against it; the product tasks
  in the example were split.
- Outcome: fixed in the example's product tasks; for BT-01 and BT-04, the
  lead's.

**G-69 · medium · [text] · The wave's plan outranks the protocol it should follow**
- Where: R "Order of authority", against `report.md` sections 3.5 and 3.8.
- Problem: the order of authority puts the wave's plan above the program,
  but the plan still states the old merge rule and sends every split to the
  owner.
- Fix: the merge-then-test queue is recorded as an exception by the owner's
  work order; requests T17-R1 and T17-R4 ask for the plan to be aligned.
- Outcome: fixed, pending the requests.

**G-70 · low · [text] · A prompt whose deadline has already passed**
- Where: B "Time and stopping".
- Problem: T17's prompt set a deadline (12:00 UTC on 29 October) that had
  passed when the session started. The correction arrived by scheduled
  message, which T17 read 13 minutes after it fired; nothing in the brief
  says what an agent does meanwhile.
- Fix: the lead checks STOP_AT against `date -u` before starting a session;
  an agent that finds its STOP_AT already passed sends the lead a request
  and keeps working until answered, under the brief's "deadline is unclear"
  rule.
- Outcome: covered for the agent by the existing rule; the lead's
  pre-start check is an owner decision (default: the lead does it).

**G-71 · low · [text] · `checks.md`'s background command lacks the marker**
- Where: `checks.md` ("`echo "exit $?"`" into `/tmp/check.log`).
- Fix: request T17-R7.

**G-72 · low · [text] · A log is committed and logs are not ignored**
- Where: `fe-base.log` at the root (commit `5b864e6`); `.gitignore`.
- Problem: the risk G-29 describes has already happened once.
- Fix: the lead removes `fe-base.log` and adds `*.log` to `.gitignore` (the
  lead owns files no track owns); the runner keeps logs in `/tmp`.
- Outcome: request T17-R10.
