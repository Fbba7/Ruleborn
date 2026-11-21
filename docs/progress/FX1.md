# FX1 server fixes (A): progress

- Status: Green. FX1-3-workshop ready at 24e171e8 (pre-check in `docs/progress/status/FX1.json`).
- Progress: 2 of 6 tasks merged (FX1-1-workshop-pairs, 8ed7538f; FX1-2-leases, c7cdcbbd); no gate items (fix tasks have none).
- Done: FX1-3: RB-35, RB-37, RB-38, RB-39, each with a test committed before its fix; `cd server && npm test` 566 of 566; `owners.py diff` passes.
- Next: FX1-4-holds-codex, in a fresh session.
- Blocked by: none.
- Owner decision needed: none.

| Deliverable | Weight (h) | Status | Evidence |
|---|---:|---|---|
| FX1-1-workshop-pairs: RB-30, RB-05, RB-06 | 3.0 | merged (8ed7538f) | `server/test/fix_fx1_workshop_pairs.test.mjs`; test commit 3785a41c; fixes in `server/src/workshop.mjs`, `server/src/service.mjs`, `server/src/matchmaking.mjs` |
| FX1-2-leases: RB-12, RB-14, RB-16, RB-17 | 3.5 | merged (c7cdcbbd) | `server/test/fix_fx1_leases.test.mjs`; test commit d1c34426; fixes 68b8d6f9, 092bc9fd, 2c55de1f, 165fa31f |
| FX1-3-workshop: RB-35, RB-37, RB-38, RB-39 | 3.5 | ready (24e171e8) | `server/test/fix_fx1_workshop.test.mjs`; test commit bf0ff93e; fixes c717a9b1, 1faccdd2, 2ac59da1, a4817445 |
| FX1-4-holds-codex | 4.0 | open | |
| FX1-6-audit-server-a | 4.0 | open | |
| FX1-7-audit-tools | 4.0 | open | |

## Handoff
- FX1-3-workshop (2026-11-21). Branch `claude/fix-server-a`. The pre-check result and `ready_sha` are in `docs/progress/status/FX1.json`.
  - **Tests first.** The five tests in `server/test/fix_fx1_workshop.test.mjs` were committed alone at bf0ff93e. All five fail on main (6cfd40b4's server code, with the wasm simulation built):
    ```
    not ok 1 - RB-35: a Workshop play recorded under an older rules build the server still holds is refused wrong_rules (SEC-31)
      + actual - expected
        [
      +   true,
      +   undefined
      -   false,
      -   'wrong_rules'
        ]
    not ok 2 - RB-37: one fan clearing three listings of the same island is one completion (18.7)
      only the first copy's clear is a completion
        [
          true,
      +   true,
      +   true
      -   false,
      -   false
        ]
    not ok 3 - RB-37: one fan's Island Fund time on three listings of the same island is capped once (18.9, SR-12)
      at most 3600 s a quarter from that fan
      9000 !== 3600
    not ok 4 - RB-38: featured islands removed by moderation no longer count on the creator ladder (18.7)
        [
      +   'loremaker',
      +   8
      -   null,
      -   5
        ]
    not ok 5 - RB-39: dismissing a player's report leaves spike review on for the island's later spikes (18.7)
      + []
      - [
      -   'completion_spike'
      - ]
    ```
  - **RB-35** (c717a9b1). `submitPlay` refuses `wrong_rules` when the replay's header names any rules build but `builds.current`. **This differs from the report's Fix line**, which adds a `rules` column to `workshop_plays`. That table is defined in `server/src/db.mjs`, which is not one of FX1-3's files. `play()` only ever issues plays under the current build, so the check closes the hole without a schema change. The cost: a play issued just before a rules upgrade and submitted after it is refused. Nothing is staked on a Workshop play, so the player only has to ask for a fresh play. Request FX1-R2 asks the lead for the column; its default keeps this check. `wrong_rules` is already worded in `client/i18n/strings.csv` (`ERR_WRONG_RULES`).
  - **RB-37** (1faccdd2). As the report's Fix line says:
    - A clear is no longer recorded as a completion when the player already has one on another live listing with the same creator and the same bundle. `outcome.counted` is false, and the spike count is not raised.
    - `Fund.played` keys SR-12's cap by player, creator and bundle instead of by item.
  - **RB-38** (2ac59da1). The ladder's featured count adds `AND removed_at IS NULL`, as the report's Fix line says.
  - **RB-39** (a4817445). On a dismiss, `review` is reset when any open report on the island is a server report (`reporter IS NULL`). The check runs before the reports are closed. As the report's Fix line says.
  - **Existing tests.** No existing test was changed, skipped or loosened. `cd server && npm test` passes 566 of 566.
  - **Merge evidence.** Main (6cfd40b4) was merged at 24e171e8 with no conflict. `owners.py diff FX1-3-workshop origin/claude/videogame-project-analysis-ewkkk2 24e171e8` reports "every changed path is inside its files". The fresh-container setup line and `bash client/build.sh` ran first (build exit 0). The pre-check ran at 24e171e8 (sandbox bwrap).
  - **Next.** FX1-4-holds-codex, in a fresh session.

## Tried and failed
- 2026-11-21 Refused RB-30 with the report's new reason `taken_down`: the client contract needs every server reason worded in `client/i18n/strings.csv`, a file outside the task. Reused `island_withdrawn` instead.
- 2026-11-21 Ran the server tests before the wasm simulation was built: every service test fails with "ruleborn_sim.wasm is not built". `cargo build --release --target wasm32-unknown-unknown` in `sim/` builds it, and so does the pre-check.
