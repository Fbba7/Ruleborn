# AD art director: progress

- Status: Green: pre-check PASS at b6fce49 (2026-10-31T15:09:43Z); P0-AD-golden-2 ready.
- Progress: 5 of 8 tasks merged (P0-AD-rubric, P0-AD-sheet, O2, P0-AD-golden, O2-2); P0-AD-golden-2 ready (b6fce49); 0 items passed by the gate (AD's tasks carry no gate items).
- Done: the five above; P0-AD-golden-2: the golden set holds 60 items (32 expected fails, 18 borderline, 13 planted), with the key frames, a new sink plant and a held-out third with its blind form.
- Next: O3 (waits for P0-AD-golden-2), then P0-AD-calibrate.
- Blocked by: none.
- Owner decision needed: none from AD. Two rows of kit-spec.md section 2.1 (success words on dark; the menus' backdrop shape) stay pending the brief entries K1-R4 asked the lead for.

| Deliverable | Weight (h) | Status | Evidence |
|---|---:|---|---|
| P0-AD-rubric: rubric v1 and judge prompts | 3 | merged (167ccf6c) | `gate/rubric.md`, `gate/prompts/*.md`; pre-check PASS at 334224c, 2026-10-30T01:44:46Z (`All checks passed.`, `DONE exit=0`) |
| P0-AD-sheet: `tools/ui_gate/sheet.py` and image checks | 3 | merged | pre-check PASS at f5e9571, 2026-10-30T23:20:33Z (`All checks passed.`, `DONE exit=0`); `python3 tools/ui_gate/sheet.py --self-test` passes (planted fails for value steps, HUD share and hierarchy); `gate/shots.md` |
| O2: approve the board and kit contract | 0.5 | merged (fdd82b7c) | pre-check PASS at 586cc5a, 2026-10-31T01:04:30Z (`All checks passed.`, `DONE exit=0`); `gate/approvals/O2.md`; value steps measured with `tools/ui_gate/checks.py`; `check_docs_consistency.py` clean |
| P0-AD-golden: golden set part 1 | 2 | merged (a38a3790) | pre-check PASS at 7d8c4ed, 2026-10-31T02:25:32Z (`All checks passed.`, `DONE exit=0`); `gate/golden/items.json`, `images/`, `labels.md`, `README.md`; `python3 tools/ui_gate/golden.py check` ("45 items, 238 label rows"), run by `sheet.py --self-test` in `check_all.sh` |
| O2-2: re-approve the redirected points | 0.5 | merged | pre-check PASS at a392bcb, 2026-10-31T06:36:42Z (`All checks passed.`, `DONE exit=0`); `gate/approvals/O2-2.md`; `checks.py value-steps` passes on all 11 controls of `board.png` and `board_hc.png` (BUILD ΔL* 26.6, was 6.2); every contrast figure in kit-spec.md's revised rows recomputed and matching; `check_docs_consistency.py` clean |
| P0-AD-golden-2: golden set part 2 | 1 | ready (b6fce49) | pre-check PASS at b6fce49, 2026-10-31T15:09:43Z (`All checks passed.`); `gate/golden/items.json`, `images/`, `labels.md`, `labels-blind.md`, `README.md`; `python3 tools/ui_gate/golden.py check` ("60 items, 363 label rows"); `check_docs_consistency.py` clean |
| O3: label the golden set | 2.5 | open (waits for P0-AD-golden-2) | |
| P0-AD-calibrate: calibration | 3 | open (waits for O3) | |

## Handoff
- Last verified commit: b6fce49 (pre-check green, 2026-10-31T15:09:43Z).
- Done: P0-AD-golden-2. Added 15 key frame items (five pages, each as written, with text at 200% and in high contrast; whole frame scaled to 540 x 1170) and four plants in them (unstroked island names, the result plates flattened, the Heist tab's loot bag flattened, the heist's cast button sunk with the new `sink` plant). Re-cropped the board plates from the O2-2 rebake: icons now pass, borderline; enamel and wood pass, not borderline. Dropped board-hc-enamel, board-hc-gold, ai-renown and today-icon-renown to stay at 60. `golden.py` gains `size`, `split`, the sink plant and the blind form; `check` guards the thirds. The key frame items' `why` hold AD's judgment of the large-text form (AIA-R4, AIA-R5): home, heist and character fail at 200%; result and settings pass, borderline.
- Half done: nothing.
- Open hypotheses: the unstroked island names may be too small for a judge to notice at 1x; if O3's blind labeller passes quality 2 there, raise their size before P0-AD-calibrate. The O2 hypotheses on quality 8's ring measure and rubric version 2 still stand for P0-AD-calibrate.
- Next step: O3. Label every row of `labels.md` without first opening items.json's `why`. Then launch a fresh subagent given only `gate/rubric.md`, `labels-blind.md` and the images of the held-out third (items with `third` 3) to fill `labels-blind.md`. Where the two disagree, `labels.md` says fail, with both critiques.

## Tried and failed
- 2026-10-30 first pre-check of f5e9571: failed at the wasm32 cargo build because this container lacked the wasm32-unknown-unknown target (setup step skipped); installed it and re-ran: PASS
- 2026-10-31 first two pre-checks of 7d8c4ed: failed at the wasm32 cargo build, then at `gdlint: command not found`, because this fresh container was not set up (agent-brief "Starting a session", step 2); ran `rustup target add wasm32-unknown-unknown aarch64-linux-android aarch64-apple-ios` and `pip install "gdtoolkit==4.*" "playwright==1.63.0"`, re-ran: PASS
