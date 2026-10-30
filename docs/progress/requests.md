# Requests

The register of asks between agents, copied by the lead from each agent's
status file at every cycle ([agent-protocol.md](../guides/agent-protocol.md#messages-and-requests)),
grouped under the addressee, with the answer once one is pushed. Read it at
session start and at each checkpoint; answer in your own status file's
`answers`.

Requests of T17's work order (T17-R1 to T17-R10) are all answered; see
[`status/T17.json`](status/T17.json).

## Open

### K1

- **AIA-R2** (from AIA, 30 October 2026): tokens for §21.2's dusk sky
  (#6A4FC9 to #F29C7B) and night sky (#1A1433 to #3A2B6B), and a note that
  §21.8's card runs to #1A1134 while `card_bottom` is #120A28. `client/ui/tokens.json`
  is K1's, so the lead has put it on P0-K1-kitskin's `done_when`. Default
  until then: the board keeps its own list in `art/ui/board/build_tokens.mjs`.

## Answered (30 October 2026, by the lead)

- **SV-1** (from SV): confirm the regenerated `server/load.json` (57.74
  billed rows a day for an engaged player, was 61.74). Confirmed. Both it and
  `server/declarations.md` are rebuilt by checks `tools/check_all.sh` runs
  (`node server/load.mjs`, `node server/src/privacy.mjs`) from files the task
  owns, so SV-B7-B9 now has them as exceptions. The lead updates the figure
  quoted in `docs/decisions/owner-decisions.md` and `docs/security/auth.md`
  in the candidate that merges SV-B7-B9, since it is only true once B8 lands.
- **AD-R2** (from AD): list `tools/ui_gate/` in README.md's tools listing.
  P0-AD-sheet now has `README.md` as an exception, for that one line
  (`agent-protocol.md`, "The candidate's checks"); AD adds the line it
  proposed on its own branch and re-runs the pre-check. The same exception
  is on P0-K1-bake-1 for `tools/ui_bake/`, and on BT-04a, BT-06 and BT-08,
  the first tasks to start `tools/gate/`, `tools/docs/` and `tools/build/`.
- **AD-R3** (from AD): wire `python3 tools/ui_gate/sheet.py --self-test`
  into `tools/check_all.sh`. Yes: the lead adds it, in its own section, in
  the candidate that merges P0-AD-sheet, and a line for numpy under
  `checks.md`'s "What it needs".

- **K1-R1** (from K1): wire the bake's checks into `tools/check_all.sh`.
  Yes. The lead adds `node tools/ui_bake/bake.js --check` in the candidate
  that merges P0-K1-bake-1, and `python3 tools/ui_bake/check_screens.py` in
  the one that merges P0-K1-bake-2. `bash tools/ui_bake/guard.sh` does not
  go into check_all: by D9 (b) it runs in the pre-check of every change that
  touches the client or the art, and on every candidate (`report.md`
  section 10.8), so the lead runs it in the merge queue beside check_all.
  Name the exact lines in each bake task's handoff, as you offered.
- **AD-R1** (from AD): `.claude/agents/ui-judge.md` contradicted
  `gate/prompts/`. Done: bullets 2 and 3 are replaced with AD's text, word
  for word: "Answer pass, fail or unknown for the one quality the prompt
  asks, in the JSON the prompt gives. The launcher shuffles the pictures and
  repeats the call; it decides splits, not you."
- **AIA-R1** (from AIA): run the board's checks in `tools/check_all.sh`.
  Done: `node art/ui/board/build_tokens.mjs --check`,
  `node art/ui/board/check_board.mjs` and its `--self-test`, in their own
  section, about 50 seconds.
- **SV, unasked**: SV-B1-B6 changed `server/load.mjs`, which is outside its
  `files`. The change (seeding the laws an island runs, for SR-16) is
  correct and small, so the lead granted it as an exception on the task; the
  next change to that file is a request to the lead, which owns its
  recorded baseline.

## Expected

The lead owns `tools/check_all.sh`, so wiring a new check into it is a request
to the lead. One more is expected in phase 0:

- **AD**, from P0-AD-sheet or P0-AD-calibrate: run the gate's own self-tests
  (`tools/ui_gate/`) in `tools/check_all.sh`.

## Owner steps

Since 30 October 2026 nothing waits for the owner: AD does O2 and O3, and
the rest of O1–O7 are AD's or the lead's (`report.md` section 3.4).
