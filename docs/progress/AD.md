# AD art director: progress

- Status: Green at the last pre-check (a392bcb); the last push holds O3's labels (c89f4e8), pre-check running.
- Progress: 6 of 8 tasks merged (P0-AD-rubric, P0-AD-sheet, O2, P0-AD-golden, O2-2, P0-AD-golden-2); O3 working; 0 items passed by the gate (AD's tasks carry no gate items).
- Done: P0-AD-rubric, P0-AD-sheet, O2, P0-AD-golden, O2-2 and P0-AD-golden-2 (merged); O3: labels.md labelled in full (363 rows: 188 pass, 175 fail), labels-blind.md labelled blind (123 rows).
- Next: O3's pre-check, then ready; then P0-AD-calibrate.
- Blocked by: none.
- Owner decision needed: none from AD. Two rows of kit-spec.md section 2.1 (success words on dark; the menus' backdrop shape) stay pending the brief entries K1-R4 asked the lead for.

| Deliverable | Weight (h) | Status | Evidence |
|---|---:|---|---|
| P0-AD-rubric: rubric v1 and judge prompts | 3 | merged (167ccf6c) | `gate/rubric.md`, `gate/prompts/*.md`; pre-check PASS at 334224c, 2026-10-30T01:44:46Z (`All checks passed.`, `DONE exit=0`) |
| P0-AD-sheet: `tools/ui_gate/sheet.py` and image checks | 3 | merged | pre-check PASS at f5e9571, 2026-10-30T23:20:33Z (`All checks passed.`, `DONE exit=0`); `python3 tools/ui_gate/sheet.py --self-test` passes (planted fails for value steps, HUD share and hierarchy); `gate/shots.md` |
| O2: approve the board and kit contract | 0.5 | merged (fdd82b7c) | pre-check PASS at 586cc5a, 2026-10-31T01:04:30Z (`All checks passed.`, `DONE exit=0`); `gate/approvals/O2.md`; value steps measured with `tools/ui_gate/checks.py`; `check_docs_consistency.py` clean |
| P0-AD-golden: golden set part 1 | 2 | merged (a38a3790) | pre-check PASS at 7d8c4ed, 2026-10-31T02:25:32Z (`All checks passed.`, `DONE exit=0`); `gate/golden/items.json`, `images/`, `labels.md`, `README.md`; `python3 tools/ui_gate/golden.py check` ("45 items, 238 label rows"), run by `sheet.py --self-test` in `check_all.sh` |
| O2-2: re-approve the redirected points | 0.5 | merged (fafc1a13) | pre-check PASS at a392bcb, 2026-10-31T06:36:42Z (`All checks passed.`, `DONE exit=0`); `gate/approvals/O2-2.md`; `checks.py value-steps` passes on all 11 controls of `board.png` and `board_hc.png` (BUILD ΔL* 26.6, was 6.2); every contrast figure in kit-spec.md's revised rows recomputed and matching; `check_docs_consistency.py` clean |
| P0-AD-golden-2: golden set part 2 | 1 | merged (520565f9) | pre-check PASS at b6fce49; 60 items; `golden.py check` |
| O3: label the golden set | 2.5 | working (c89f4e8) | `gate/golden/labels.md` (363 rows, none blank), `labels-blind.md` (123 rows, a fresh Opus 5.5 subagent given only the rubric, the form and the 20 held-out images); `golden.py check` "60 items, 363 label rows"; `check_docs_consistency.py` clean |
| P0-AD-calibrate: calibration | 3 | open (waits for O3) | |

## Handoff
- Last verified commit: a392bcb (pre-check green, 2026-10-31T06:36:42Z); O3's c89f4e8 is in its pre-check (log /tmp/check-c89f4e8f16d4b15a4aafdf0613bac5eda151636f.log).
- Done: O3's labelling. AD labelled every row in four batches (today and v3; t14, board, ai and the kit and icon plants; the heist plants and the home and heist key frames; the result, character and settings key frames), each judged on the images against rubric version 1. AD overrode one call across batches: quality 9 fails on the kf-heist family (kf-heist, -text200, -hc, plant-kf-heist-cast-sunk), because the stone and knight portraits are in a physically based material. The blind labeller labelled the held-out third (20 items, 123 rows: 49 pass, 74 fail) with no access to items.json or labels.md.
- Agreement on the held-out third: 94 of 123 rows (76%). By quality: 1 17/20, 2 16/17, 3 10/14, 6 9/11, 8 17/20, 9 7/10, 13 12/20, 14 6/11. The 29 disagreements are labelled fail in labels.md, with each labeller's reason; in 22 of them the blind labeller was the stricter one.
- Half done: nothing beyond the pre-check.
- Open hypotheses for P0-AD-calibrate: qualities 13 and 14 have the weakest agreement (60% and 55%): the rubric does not say whether high contrast may drop the reward glow or the panels' light, nor how much plain chrome a screen may carry before quality 14 fails; rubric version 2 should say. Quality 2's "word over art" reads a backdrop gradient as art, which fails every normal-mode result, character and settings key frame; it is also a version 2 question. ai-essence fails quality 3 (refraction reads as physically based), though rubric version 1 names it as the clear-pass anchor: replace the anchor. A plant breaks more than the quality it names (plant-heist-one-step fails six qualities; the flattened icons fail 13 too); calibrate should score plants on every labelled row, not only the one they break.
- Next step: when the pre-check passes, `bash tools/run_checks.sh record c89f4e8f16d4b15a4aafdf0613bac5eda151636f AD`, set ready_sha c89f4e8, agent_state waiting, push, end the session.

## Tried and failed
- 2026-10-30 first pre-check of f5e9571: failed at the wasm32 cargo build because this container lacked the wasm32-unknown-unknown target (setup step skipped); installed it and re-ran: PASS
- 2026-10-31 first two pre-checks of 7d8c4ed: failed at the wasm32 cargo build, then at `gdlint: command not found`, because this fresh container was not set up (agent-brief "Starting a session", step 2); ran `rustup target add wasm32-unknown-unknown aarch64-linux-android aarch64-apple-ios` and `pip install "gdtoolkit==4.*" "playwright==1.63.0"`, re-ran: PASS
