# AD art director: progress

- Status: P0-AD-calibrate-2 done, pre-check pending (see the status file). The program was stopped on 3 November and restarted on 4 November under the owner's orders in the root `CLAUDE.md` (Fable 5.1 banned; Opus 5.5 only).
- Progress: 8 of 9 tasks merged or ready (P0-AD-rubric, P0-AD-sheet, O2, P0-AD-golden, O2-2, P0-AD-golden-2, O3, P0-AD-calibrate); P0-AD-calibrate-2 finishing; 0 items passed by the gate (AD's tasks carry no gate items).
- Done: P0-AD-calibrate-2: dev-fable and dev-opus scored, Opus 5.5 chosen as the judge, rubric versions 2 and 3, dev-opus-v2 and dev-opus-v3 run and scored, held-opus run once on rubric version 3 and scored. It missed the target on all eight qualities, so all eight are owner-checked (`gate/calibration.md`).
- Next: a golden set version 2 (more passing items per quality; relabel the flat law and currency glyphs on quality 3), then a fresh rubric version and held-out measurement, if the lead files it.
- Blocked by: none.
- Owner decision needed: none from AD. All eight judged qualities are owner-checked: AD checks each on every board, and the judge's verdicts are advice only.

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

## Handoff
- Last verified commit: see `precheck` in `status/AD.json`; P0-AD-calibrate-2 ready.
- Done: the lead's `dev-fable` and `dev-opus` runs (rubric version 1) scored: both missed all eight qualities; Opus 5.5 caught 33 of 48 fails against Fable 5.1's 23, so Opus 5.5 is the judge (and the owner's order of 4 November bans Fable 5.1 for good). Rubric version 2 (rulings for every quality) met 1, 2, 8 and 14 on the development third (`dev-opus-v2`); version 3 (rulings for 6, 9 and 13) met 2, 6 and 9 (`dev-opus-v3`). The held-out run `held-opus` (version 3, measured once) missed all eight, so all eight are owner-checked. Judge runs were launched as child cloud sessions on claude/ui-ad (subagents cannot spawn the ui-judge), each pushing `calibration/runs/<run>/results.jsonl`.
- Abandoned: `dev-fable-v3` (120 of 366 calls) by the owner's order; its results stay in the history, unscored.
- Half done: nothing. The rubric is at version 3, not 1 (two step-5 revisions); the golden set stays version 1.
- Open hypotheses: the held-out third has two to four passes on five qualities, so one false block decides the target; 8, 13 and 14 have real catch gaps on the same screens (`today-home`, `v3-result`, `today-character`, `today-hud-bottom`), where the labels fail details the judge does not weigh. Quality 3's false blocks are flat law and currency glyphs that the labels pass and that read as flat to the judge and to AD.
- Next step: golden set version 2 (more passing items per quality, per-item failing details from the owner's notes, the quality 3 relabel), then a rubric version 4 and a fresh held-out measurement with Opus 5.5.
- Request for the lead: copy `calibration/runs/*/results.jsonl` into `gate/verdicts/P0-AD-calibrate/` if the protocol wants them there (default: they stay where they are, in AD's files).

## Tried and failed
- 2026-10-30 first pre-check of f5e9571: failed at the wasm32 cargo build because this container lacked the wasm32-unknown-unknown target (setup step skipped); installed it and re-ran: PASS
- 2026-10-31 first two pre-checks of 7d8c4ed: failed at the wasm32 cargo build, then at `gdlint: command not found`, because this fresh container was not set up (agent-brief "Starting a session", step 2); ran `rustup target add wasm32-unknown-unknown aarch64-linux-android aarch64-apple-ios` and `pip install "gdtoolkit==4.*" "playwright==1.63.0"`, re-ran: PASS
- 2026-11-03 running the judge from a general-purpose subagent: it has no Agent tool, so it cannot call ui-judge; launched each run as a child cloud session instead.
- 2026-11-03 `render` can leave a call's crops missing (judges said so in a few reasons); not changed mid-calibration, so all runs saw the same conditions. Fix before the next rubric version.
