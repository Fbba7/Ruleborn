# AD art director: progress

- Status: Green at 3f3797c (pre-check PASS, 2026-10-31T19:23Z); P0-AD-calibrate ready, waiting for the lead (merge, the runs and P0-AD-calibrate-2, AD-R6).
- Progress: 7 of 8 tasks merged (P0-AD-rubric, P0-AD-sheet, O2, P0-AD-golden, O2-2, P0-AD-golden-2, O3); P0-AD-calibrate ready at 3f3797c; 0 items passed by the gate (AD's tasks carry no gate items).
- Done: the seven above; P0-AD-calibrate: `tools/ui_gate/calibrate.py` (split, anchors, run plans with blind codes, the D-06 scoring, the audit draw, self-test wired into `sheet.py --self-test`) and `gate/calibration.md`; plans for `dev-fable` and `dev-opus` (366 calls each).
- Next: P0-AD-calibrate-2 (AD-R6) once the lead's runs are written.
- Blocked by: none. The gate runs are the lead's (AD-R6); until they are scored, all eight judged qualities stay in shadow mode.
- Owner decision needed: none from AD. Two rows of kit-spec.md section 2.1 (success words on dark; the menus' backdrop shape) stay pending the brief entries K1-R4 asked the lead for.

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

## Handoff
- Last verified commit: 3f3797c (pre-check green, 2026-10-31T19:23Z); P0-AD-calibrate ready.
- Done: `tools/ui_gate/calibrate.py`: `split` (the thirds and O3's labels per quality and third), `anchors` (PASS and FAIL ANCHOR per class and quality from the training third only: borderline natural first, then plants), `plan` (one call per labelled row and sample, pictures shuffled, blind codes salted per run), `extra` (samples 4-6 for splits), `render` (pictures and filled prompts into a folder outside the repo), `score` (D-06 rule; catch, false-block and exception counts against the target), `audit` (O6's draw), `--self-test`. `gate/calibration.md` holds the split, anchors, run plan, steps, expectations from O3 and an empty results table. Rubric and golden set stay version 1 (golden README says so). Request AD-R6: the lead launches dev-fable and dev-opus and files P0-AD-calibrate-2 for the scoring, model choice, prompt revisions and held-out run.
- Half done: nothing; the first done_when (the judge meets its target) moves to P0-AD-calibrate-2 by AD-R6, since the runs are the lead's.
- Open hypotheses: qualities 13, 14, 2 and 3 are the likely misses (calibration.md, "What to expect"); icon quality 8 has no FAIL ANCHOR in the training third.
- Next step: P0-AD-calibrate-2, once the lead files it and the runs are written: `calibrate.py score --run dev-fable <verdicts file> --markdown`, the same for dev-opus, choose the model, then `plan --third 3 --model <m> --run held-<m>`.

## Tried and failed
- 2026-10-30 first pre-check of f5e9571: failed at the wasm32 cargo build because this container lacked the wasm32-unknown-unknown target (setup step skipped); installed it and re-ran: PASS
- 2026-10-31 first two pre-checks of 7d8c4ed: failed at the wasm32 cargo build, then at `gdlint: command not found`, because this fresh container was not set up (agent-brief "Starting a session", step 2); ran `rustup target add wasm32-unknown-unknown aarch64-linux-android aarch64-apple-ios` and `pip install "gdtoolkit==4.*" "playwright==1.63.0"`, re-ran: PASS
