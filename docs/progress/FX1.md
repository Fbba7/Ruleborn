# FX1 server fixes (A): progress

- Status: Green. FX1-1-workshop-pairs: fail-first tests and fixes for RB-30, RB-05 and RB-06 pushed; the first pre-check failed on a new refusal reason with no client words, fixed; main merged again; pre-check running at fd9af096.
- Progress: 0 of 6 tasks merged; no gate items (fix tasks have none).
- Done: RB-30, RB-05, RB-06, each with a test committed before its fix; `cd server && npm test` 543 of 543; `owners.py diff` passes.
- Next: record the pre-check, mark FX1-1 ready; then FX1-2-leases in a fresh session.
- Blocked by: none.
- Owner decision needed: none.

| Deliverable | Weight (h) | Status | Evidence |
|---|---:|---|---|
| FX1-1-workshop-pairs: RB-30, RB-05, RB-06 | 3.0 | working | `server/test/fix_fx1_workshop_pairs.test.mjs`; test commit 3785a41c; fixes in `server/src/workshop.mjs`, `server/src/service.mjs`, `server/src/matchmaking.mjs` |
| FX1-2-leases | 3.5 | open | |
| FX1-3-workshop | 3.5 | open | |
| FX1-4-holds-codex | 4.0 | open | |
| FX1-6-audit-server-a | 4.0 | open | |
| FX1-7-audit-tools | 4.0 | open | |

## Handoff
- FX1-1-workshop-pairs (2026-11-21). Branch `claude/fix-server-a`. The pre-check result and `ready_sha` are in `docs/progress/status/FX1.json`.
  - **Tests first.** All four tests in `server/test/fix_fx1_workshop_pairs.test.mjs` were committed alone at 3785a41c, and all four fail on main (51abbef0, the wasm simulation built):
    ```
    not ok 1 - RB-30: a creator cannot republish, byte for byte, an island a moderator removed (18.7)
      error: 'Missing expected exception.'
    not ok 2 - RB-05: an echo raid does not use up the pair's daily scoring (12.3, G30, G37)
      error: the pair's first real raid of the day scores
      expected: true
      actual: false
    not ok 3 - RB-05: a foiled echo does not keep a later real foil's fee from the defender (9.4, G30, G37)
      error: the pair's first real foil of the day passes the fee on
      expected: true
      actual: false
    not ok 4 - RB-06: players' live curated islands are in the live pool, offered before echoes (12.22, 13.3)
      error: three live islands of players sit in the band: no echoes, nothing of the game's
      expected: [false, false]
      actual:   [true, false]
    ```
  - **RB-30** (fix commits "RB-30: …"). `Workshop.publish` now refuses with `409` when the creator already has an item with the same bytes that a moderator removed. **Not the report's `taken_down` reason:** the first pre-check (at b67863b8) failed on the client contract, `client/i18n/strings.csv: no words for ERR_TAKEN_DOWN in every language`. That file is outside FX1-1's files. The refusal reuses `island_withdrawn` ("that island was withdrawn"), which is already worded in all six languages, and the test asserts that reason (commit 9f0cd78a). Request FX1-R1 offers the lead a dedicated ERR_TAKEN_DOWN string; the default is to keep `island_withdrawn`. The duplicate check for other creators is unchanged. The same creator can still list the same bytes twice under two names while neither is removed (the existing moderation test does this).
  - **RB-05** (fix commit "RB-05: …"). In `grant`, the pair query now adds `AND l.echo = ?`, bound to `lease.echo ? 1 : 0`, and the foiled-fee query adds `AND l.echo = 0`. As the report's Fix line says.
  - **RB-06** (fix commit "RB-06: …"). `offer` now treats an island as the game's own only when `origin === "generated" && owner === GENERATOR`, as `current()` does. As the report's Fix line says. `generated.test.mjs` and `matchmaking.test.mjs` still pass unchanged.
  - **Existing tests.** No existing test was changed, skipped or loosened.
  - **Merge evidence.** Main (2339d63a) was first merged at b67863b8. The pre-check there failed only on the client contract (above), and the result is recorded here, not re-run blind. After the RB-30 reason change, main (10909f76) was merged again at fd9af096 with no conflict. `owners.py diff FX1-1-workshop-pairs origin/claude/videogame-project-analysis-ewkkk2 HEAD` reports "every changed path is inside its files". `cd server && npm test` passes 543 of 543. `tools/client_contract.py` reports "205 failure codes have words in every language". The fresh-container setup line and `bash client/build.sh` ran first (SETUP_DONE=0). The pre-check at fd9af096 is in `docs/progress/status/FX1.json`.
  - **Next.** FX1-2-leases (RB-12, RB-14, RB-16, RB-17), in a fresh session.

## Tried and failed
- 2026-11-21 Refused RB-30 with the report's new reason `taken_down`: the client contract needs every server reason worded in `client/i18n/strings.csv`, a file outside the task. Reused `island_withdrawn` instead.
- 2026-11-21 Ran the server tests before the wasm simulation was built: every service test fails with "ruleborn_sim.wasm is not built". `cargo build --release --target wasm32-unknown-unknown` in `sim/` builds it, and so does the pre-check.
