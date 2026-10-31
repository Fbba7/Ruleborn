# AD art director: progress

- Status: Green: pre-check PASS at 586cc5a (2026-10-31T01:04:30Z); the last push holds O2's decision (`gate/approvals/O2.md`), ready.
- Progress: 1 of 7 tasks merged (P0-AD-rubric); P0-AD-sheet ready (f5e9571); O2 ready (586cc5a); 0 items passed by the gate (AD's tasks carry no gate items).
- Done: P0-AD-rubric (merged); P0-AD-sheet (ready); O2: the board and the contract approved in part, with two redirects (AD-R4 → P0-AIA-board-3, AD-R5 → P0-K1-contract-2) and a re-approval O2-2.
- Next: P0-AD-golden.
- Blocked by: none.
- Owner decision needed: none from AD. P0-K1-contract-2 may prepare decision brief entries for §21.2's menu backdrop and §21.8's red and green words on dark surfaces.

| Deliverable | Weight (h) | Status | Evidence |
|---|---:|---|---|
| P0-AD-rubric: rubric v1 and judge prompts | 3 | merged (167ccf6c) | `gate/rubric.md`, `gate/prompts/*.md`; pre-check PASS at 334224c, 2026-10-30T01:44:46Z (`All checks passed.`, `DONE exit=0`) |
| P0-AD-sheet: `tools/ui_gate/sheet.py` and image checks | 3 | ready (f5e9571) | pre-check PASS at f5e9571, 2026-10-30T23:20:33Z (`All checks passed.`, `DONE exit=0`); `python3 tools/ui_gate/sheet.py --self-test` passes (planted fails for value steps, HUD share and hierarchy); `gate/shots.md` |
| P0-AD-golden: golden set part 1 | 2 | open (waits for P0-AD-sheet, P0-AIA-board-2) | |
| O2: approve the board and kit contract | 0.5 | ready (586cc5a) | pre-check PASS at 586cc5a, 2026-10-31T01:04:30Z (`All checks passed.`, `DONE exit=0`); `gate/approvals/O2.md`; value steps measured with `tools/ui_gate/checks.py`; `check_docs_consistency.py` clean |
| O3: label the golden set | 2.5 | open (waits for P0-AD-golden-2) | |
| P0-AD-golden-2: golden set part 2 | 1 | open (waits for P0-AD-golden, P0-AIA-keyframes-3) | |
| P0-AD-calibrate: calibration | 3 | open (waits for O3) | |

## Handoff
- Last verified commit: 586cc5a (pre-check green, 2026-10-31T01:04:30Z).
- Done: O2. The board: gold, oak, glass, parchment, type, outline and glint rules and the high-contrast forms approved; the hero icons' physically based light (D5 (b), §21.3), the enamel card (reads as a web card at 1x), the selected card's glow and the leather button in its oak well (0.6 value steps) redirected. The contract: sections 3-6 approved but K01's tertiary ghost; section 2.1's four values that differ from §21.2 and §21.8 and section 2.2's title treatments redirected. Interim rulings in O2.md for the key frames.
- Half done: nothing.
- Open hypotheses: a tappable dark card on the night backdrop cannot clear two value steps by its fill (§21.8's colours); O2 has its step come from rim and lip. If P0-AIA-board-3 cannot meet it, quality 8's ring measure (median face against a 4 pt ring) may need to count the rim, as rubric version 2 at P0-AD-calibrate. Rubric version 2 also narrows quality 2's "gradient" (titles on the card and parchment are plain) and quality 14's "glass card with blur" (§21.8's dark glass is allowed).
- Next step: O2 is ready at 586cc5a. Next session: P0-AD-golden (its deps: P0-AD-sheet merged, P0-AIA-board-2 merged).

## Tried and failed
- 2026-10-30 first pre-check of f5e9571: failed at the wasm32 cargo build because this container lacked the wasm32-unknown-unknown target (setup step skipped); installed it and re-ran: PASS
