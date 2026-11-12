# AD art director: progress

- Status: P1-AD-board-1b ready (board 1 round 2 posted; it still does not stand: A, B and D open, B and D narrowed; C and E closed). Pre-check in the status file.
- Progress: 11 of 11 tasks merged or ready (P0-AD-rubric, P0-AD-sheet, O2, P0-AD-golden, O2-2, P0-AD-golden-2, O3, P0-AD-calibrate, P0-AD-calibrate-2, P1-AD-board-1, P1-AD-board-1b); 0 items passed by the gate (every judged quality is owner-checked, so AD's board check decides).
- Done: P1-AD-board-1b: "Round 2" in `docs/art/ui-quality/gate/boards/board-1.md`, with stills `board-1/r2-*.png`, on main at `085c812a`.
- Next: P1-AD-board-1c re-checks A, B and D (and the "Laws here" header) once P1-K1-numerals-on and the fixes for AD-R13 and AD-R15 merge (seeding asked in AD-R16); phase 2 waits for board 1.
- Blocked by: none.
- Owner decision needed: none. AD decides board 1 in place of the owner.

| Deliverable | Weight (h) | Status | Evidence |
|---|---:|---|---|
| P0-AD-rubric: rubric v1 and judge prompts | 3 | merged (167ccf6c) | `gate/rubric.md`, `gate/prompts/*.md`; pre-check PASS at 334224c, 2026-10-30T01:44:46Z (`All checks passed.`, `DONE exit=0`) |
| P0-AD-sheet: `tools/ui_gate/sheet.py` and image checks | 3 | merged | pre-check PASS at f5e9571, 2026-10-30T23:20:33Z (`All checks passed.`, `DONE exit=0`); `python3 tools/ui_gate/sheet.py --self-test` passes (planted fails for value steps, HUD share and hierarchy); `gate/shots.md` |
| O2: approve the board and kit contract | 0.5 | merged (fdd82b7c) | pre-check PASS at 586cc5a, 2026-10-31T01:04:30Z (`All checks passed.`, `DONE exit=0`); `gate/approvals/O2.md`; value steps measured with `tools/ui_gate/checks.py`; `check_docs_consistency.py` clean |
| P0-AD-golden: golden set part 1 | 2 | merged (a38a3790) | pre-check PASS at 7d8c4ed, 2026-10-31T02:25:32Z (`All checks passed.`, `DONE exit=0`); `gate/golden/items.json`, `images/`, `labels.md`, `README.md`; `python3 tools/ui_gate/golden.py check` ("45 items, 238 label rows"), run by `sheet.py --self-test` in `check_all.sh` |
| O2-2: re-approve the redirected points | 0.5 | merged (fafc1a13) | pre-check PASS at a392bcb, 2026-10-31T06:36:42Z (`All checks passed.`, `DONE exit=0`); `gate/approvals/O2-2.md`; `checks.py value-steps` passes on all 11 controls of `board.png` and `board_hc.png` (BUILD ΔL* 26.6, was 6.2); every contrast figure in kit-spec.md's revised rows recomputed and matching; `check_docs_consistency.py` clean |
| P0-AD-golden-2: golden set part 2 | 1 | merged (520565f9) | pre-check PASS at b6fce49; 60 items; `golden.py check` |
| O3: label the golden set | 2.5 | merged (316ff98c) | pre-check PASS at c89f4e8, 2026-10-31T17:11:29Z (`All checks passed.`, `DONE exit=0`); `gate/golden/labels.md` (363 rows, none blank), `labels-blind.md` (123 rows, a fresh Opus 5.5 subagent given only the rubric, the form and the 20 held-out images); `golden.py check` "60 items, 363 label rows"; `check_docs_consistency.py` clean |
| P0-AD-calibrate: calibration | 3 | ready (3f3797c) | pre-check PASS at 3f3797c, 2026-10-31T19:23Z (`All checks passed.`, `DONE exit=0`); `tools/ui_gate/calibrate.py --self-test` (run by `sheet.py --self-test` in `check_all.sh`); `gate/calibration.md`; `gate/calibration/runs/dev-{fable,opus}/plan.jsonl`; `check_docs_consistency.py` clean |
| P0-AD-calibrate-2: score, choose the judge, revise, held-out | 2 | ready (pre-check in the status file) | `gate/calibration.md` Results: dev runs on rubric versions 1-3, `held-opus` on version 3 (all eight qualities missed, owner-checked); `gate/rubric.md` and `gate/prompts/` version 3; `calibration/runs/{dev-opus-v2,dev-opus-v3,held-opus}/` plans and results; `check_docs_consistency.py` clean |
| P1-AD-board-1: board 1 and the flow review | 2 | ready (pre-check in the status file) | `gate/boards/board-1.md` and `gate/boards/board-1/*.png`; stills re-rendered on main at `d880807e`; flow review below; requests AD-R7 to AD-R12 in `status/AD.json` |
| P1-AD-board-1b: re-check board 1 on pilot-3 | 1 | ready (pre-check in the status file) | `gate/boards/board-1.md` Round 2 and `gate/boards/board-1/r2-*.png`; three stills re-rendered on main at `085c812a` match S1's (mean diff ≤ 0.34, ≤ 0.75% of pixels > 16); the no-plan 200% pt_BR shot fails `FIT=1`; requests AD-R13 to AD-R16 in `status/AD.json` |

## Handoff
- Last verified commit: see `precheck` in `status/AD.json`; P1-AD-board-1b ready.
- Done: board 1 round 2 on main at `085c812a` (P1-S1-pilot-3 merged). **It still does not stand.**
  - A is open: the timer is still the flat `KitHud.clock`. S1's `numerals-*` stills show the fix behind the switch; A closes when P1-K1-numerals-on merges.
  - B is open, narrowed: S1's stills all have a crew plan and pass `FIT=1`. AD shot one on main with no plan (rehearsal, Workshop island, offline) at 200% pt_BR. Cast reads "Sem lançamentos", the tray grows to two button rows and covers the loot panel, and `FIT=1` fails (AD-R15).
  - C and E are closed.
  - D is open, narrowed: Hollow's violet body is one tone with its violet school disc, and Bramble is grainy and about 12 L* below its disc (AD-R13).
  - New: the unoutlined "Laws here" header could fail K1's numerals gate (AD-R14).
- Checked: three re-renders on main match S1's stills, so the stills stand for the integrated build.
- Half done: nothing.
- Open hypotheses: Bramble's grain may come from texture filtering in the portrait render, not the art; the portrait owner should look before AIA-2 changes the art.
- Next step: P1-AD-board-1c re-checks A, B and D and the header on new stills taken on main.

## Flow review

AD read the router (`client/app/router.gd`) and every `router.go` on the heist loop, and rendered the loop's screens on main at `d880807e` with `tools/render/shoot.sh` (`screen_first`, `universe_home` at 100% and 200%, `screen_observatory`, `screen_scout`, `screen_planner`, `screen_heist`, `screen_result`, `screen_replay`). The routes hold: first → home; the Heist tab → Observatory → Scout → Planner → heist → result; the result leads Home, to the replay, to Raid again and, after an own-island raid, back to the builder; the replay leads Home. `client/tests/run.gd` plays the whole loop against the server and the builder loop, and `observatory_tests.gd` follows Observatory → Scout → Planner, so no test is missing for the routes. Findings, none of which holds the board except E (request AD-R12):

| ID | Screen | Finding | Proposed fix |
|---|---|---|---|
| E | heist shot | `MOMENT=alarm` shows "Alarm 0/6", as sneak does. | Board objection E (AD-R11). |
| F1 | home, 100% | The raid notice's line ends "See how your defence …": the word "held" is cut. | Let the line wrap, as it does at 200%. |
| F2 | home, 200% | The universe shrinks to a strip; the island pins stack in a column over it and onto the raid notice, and the Lantern Vale, Tidehold and Emberreach pins are gone. The gem overlaps the "1,460" pill. | Hide or shrink the pins when the band is short (or show a list), and keep the gem inside its pill. |
| F3 | first | The tagline wraps, and "treasure." sits on Verdant's island. | Keep the tagline on a plate, or move the island ring below the tagline's measured height. |
| F4 | scout | The chip row (3, 410, 112%, 2) is cut at the panel's bottom edge. | Give the panel the row's height, or scroll it with a cue. |
| F5 | planner | "choose 3 to 3 crew" when the minimum is the maximum; the plan card's text runs under START THE HEIST with no scroll cue. | A second string, "choose %d crew", for min = max (`PLAN_NEEDS_CREW`); a scroll cue or a shorter card. |
| F6 | result | A Clean heist says "No guard alerted" over "2:45 · alarm 5 / 6". The lower 40% of the screen is empty, and "961-byte replay" is developer text. | Say what the peak counts, or show it only when a guard was alerted; move the actions up or fill the space with the haul; drop the byte count from the player's line. |
| F7 | replay | The timeline's markers pile up: four stars on one another and on the first bell. | Stack markers that share a time, or merge them into one marker with a count. |

## Tried and failed
- 2026-10-30 first pre-check of f5e9571: failed at the wasm32 cargo build because this container lacked the wasm32-unknown-unknown target (setup step skipped); installed it and re-ran: PASS
- 2026-10-31 first two pre-checks of 7d8c4ed: failed at the wasm32 cargo build, then at `gdlint: command not found`, because this fresh container was not set up (agent-brief "Starting a session", step 2); ran `rustup target add wasm32-unknown-unknown aarch64-linux-android aarch64-apple-ios` and `pip install "gdtoolkit==4.*" "playwright==1.63.0"`, re-ran: PASS
- 2026-11-03 running the judge from a general-purpose subagent: it has no Agent tool, so it cannot call ui-judge; launched each run as a child cloud session instead.
- 2026-11-03 `render` can leave a call's crops missing (judges said so in a few reasons); not changed mid-calibration, so all runs saw the same conditions. Fix before the next rubric version.
- 2026-11-11: `claude/ui-ad` and main had unrelated histories, so a plain merge failed; joined them with a merge (`--allow-unrelated-histories -s ours`, then `read-tree` of main), no force-push (6c3cd6fb).
