# AD art director: progress

- Status: P2-AD-board-3 ready (board 3, home, round 1 posted: **the board does not stand**, objections A to D, each a request to the lead). Pre-check in the status file.
- Progress: 14 of 14 tasks merged or ready (P0-AD-rubric, P0-AD-sheet, O2, P0-AD-golden, O2-2, P0-AD-golden-2, O3, P0-AD-calibrate, P0-AD-calibrate-2, P1-AD-board-1, P1-AD-board-1b, P1-AD-board-1c, P1-AD-board-1d, P2-AD-board-3); 0 items passed by the gate (every judged quality is owner-checked, so AD's board check decides).
- Done: P2-AD-board-3: `docs/art/ui-quality/gate/boards/board-3.md`, nine items with stills `board-3/*.png`, on the integration head at `abbe59eb` (home-2 merged as `807d68a7`); previews S3-R7, S2-R18 and S1-R24 answered in `status/AD.json`.
- Next: S2 fixes A to C (AD-R22 to AD-R24) and K1 fixes D (AD-R25), then AD re-checks only what the fixes change (board 3b); board 4 after result-2 merges (S1-R25 re-check done: S1-R24's four objections stand as fixed), board 5 after settings.
- Blocked by: none.
- Owner decision needed: none. AD decides board 3 in place of the owner.

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
| P1-AD-board-1c: re-check board 1 on numerals-on and pilot-4 | 1 | ready (pre-check in the status file) | `gate/boards/board-1.md` Round 3 and `gate/boards/board-1/r3-*.png`; five shots on main at `ed6bcfdc`, all `FIT=1` "fit ok" (no-plan 200% pt_BR included); A and B closed, D and F open; requests AD-R17 to AD-R19 in `status/AD.json` |
| P1-AD-board-1d: re-check board 1 on pilot-5 | 1 | ready (pre-check in the status file) | `gate/boards/board-1.md` Round 4 and `gate/boards/board-1/r4-*.png`; four shots on main at `cecf3a64`, all `FIT=1` "fit ok"; the no-plan 200% pt_BR shot matches S1's (mean diff 0.01); portrait L* matches S1's Part 5 table; D and F closed, board 1 stands; requests AD-R20 and AD-R21 in `status/AD.json` |
| P2-AD-board-3: board 3 (home) | 2 | ready (pre-check in the status file) | `gate/boards/board-3.md` and `gate/boards/board-3/*.png`; home rendered with `universe_home.gd`, `FIT=1`, at 100% and 200%, en and pt_BR, high contrast and `NOTICE=1`, beside `art/ui/keyframes/01-home*`; gate verdicts of home-1 (`977edd5b`) and home-2 (`3612e265`) cited per item; objections A to D as requests AD-R22 to AD-R25; `check_docs_consistency.py` clean |

## Handoff
- Last verified commit: see `precheck` in `status/AD.json`; P2-AD-board-3 ready.
- Done: board 3 (home), round 1, on `abbe59eb`. **The board does not stand.** Objections, in order of weight:
  - A (hard defect, S2, AD-R22): at 200% pt_BR with the raid notice, Collect is off the screen.
  - B (S2, AD-R23): at 100% the world is framed too low and the pins stack; the Defence badge lands on the Skyfield pin in pt_BR.
  - C (S2, AD-R24): the goal panel, realm pins and dock labels drop at 200% and in pt_BR at 100%. Keep the goal bar at every size.
  - D (K1, AD-R25): the dock labels sit on their tiles' gold rim (`client/ui/kit_tabs.gd`).
  - Stands: the companion (quality 9, note: clamp its yaw) and the top bar (note: the strain mark is a cyan dot, the key frame's is a pink bolt).
- Previews answered: S3-R7 (settings), S2-R18 (home part 2, which became board 3's objections) and S1-R24 (result part 2 at `aed28321`: the faces apart are accepted; four objections for result-2, the heaviest being that at 200% pt_BR the haul falls below the fold under the moment card).
- Checked: `check_docs_consistency.py` clean; the full checks in the pre-check (`check_all.sh` takes more than 10 minutes here, so it runs detached through `run_checks.sh`).
- Half done: nothing.
- Open hypotheses: home's shot fixture lacks notifications, a shield and a locked realm, so those states are unjudged; result's fixture has no roster, so RAID AGAIN's idle line is untested.
- S1-R25 (13 November 10:05Z): re-checked result-2 at `71167028` (pt_BR 200%, high contrast, en 100%, de 200%). The four S1-R24 objections stand as fixed. Outside the re-check's scope: at de 200% the tiles fall back to columns and only Sternenlicht is above the dock (AD-R26, for board 4).
- Next step: board 3b after AD-R22 to AD-R25 land, re-checking only what the fixes change; board 4 after result-2 merges (list AD-R26 there); board 5 after settings.

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
- 2026-11-13 `bash tools/check_all.sh` in the foreground: stopped by the tool's 10-minute limit at the mobile toolchain step, with server and client tests passed so far (535 and 409); ran the full checks detached through `run_checks.sh` instead.
