# FX1 server fixes (A): progress

- Status: Green. FX1-2-leases ready at f3849470 (pre-check PASS, 18:30:38Z).
- Progress: 1 of 6 tasks merged (FX1-1-workshop-pairs, 8ed7538f); no gate items (fix tasks have none).
- Done: FX1-1 merged. FX1-2: RB-12, RB-14, RB-16, RB-17, each with a test committed before its fix; `cd server && npm test` 554 of 554; `owners.py diff` passes.
- Next: FX1-3-workshop, in a fresh session.
- Blocked by: none.
- Owner decision needed: none.

| Deliverable | Weight (h) | Status | Evidence |
|---|---:|---|---|
| FX1-1-workshop-pairs: RB-30, RB-05, RB-06 | 3.0 | merged (8ed7538f) | `server/test/fix_fx1_workshop_pairs.test.mjs`; test commit 3785a41c; fixes in `server/src/workshop.mjs`, `server/src/service.mjs`, `server/src/matchmaking.mjs` |
| FX1-2-leases: RB-12, RB-14, RB-16, RB-17 | 3.5 | ready (f3849470) | `server/test/fix_fx1_leases.test.mjs`; test commit d1c34426; fixes 68b8d6f9, 092bc9fd, 2c55de1f, 165fa31f |
| FX1-3-workshop | 3.5 | open | |
| FX1-4-holds-codex | 4.0 | open | |
| FX1-6-audit-server-a | 4.0 | open | |
| FX1-7-audit-tools | 4.0 | open | |

## Handoff
- FX1-2-leases (2026-11-21). Branch `claude/fix-server-a`. The pre-check result and `ready_sha` are in `docs/progress/status/FX1.json`.
  - **Tests first.** All five tests in `server/test/fix_fx1_leases.test.mjs` were committed alone at d1c34426. All five fail on main (8ed7538f, with the wasm simulation built):
    ```
    not ok 1 - RB-12: yesterday's generated island is not leased as an echo (12.22, generator.mjs)
      error: 'Missing expected exception: refused 410 superseded'
    not ok 2 - RB-12: an hourly list made before the rotation does not hand out yesterday's generated island (12.22)
      error: 'no stale card: ["0cc936624e251d63c81a46175e6ffbc6052466d03a3d87e4399d49ffad8aede2"]'
    not ok 3 - RB-14: asking again for a held Trace hands back the same lease (12.3, 24.13)
      Got unwanted exception: the second ask is not refused
      Actual message: "nothing_to_trace"
    not ok 4 - RB-16: a refused upload does not use up a challenge link (17.6)
      Got unwanted exception: a refused submission is not a play
      Actual message: "challenge_already_played"
    not ok 5 - RB-17: an offer of size 1 is the band's middle, guaranteed (12.22)
      the in-band middle
      + actual - expected
        [
      +   'a'
      -   'c'
        ]
    ```
  - **RB-12** (68b8d6f9). `lease` now refuses `410 superseded` when a snapshot on no island is the generator's (`snapshot.owner === GENERATOR`). In `current()`, only echo cards whose owner is not the generator are passed through unchanged. A generator card is now looked up like any live island, so a card from a list made before the rotation is swapped to the day's island. As the report's Fix line says.
  - **RB-14** (092bc9fd). In `lease`, when `traceable()` returns null, the Trace falls back to the `trace_of` of the attacker's newest lease on the bundle, if that lease is a live, unplayed Trace. `issue()` then hands that lease back. This follows the report's Fix line, narrowed to the newest lease, because `issue()` hands back only the newest. As the report says, an expired, unplayed Trace still uses its robbery up; that case is not part of this fix.
  - **RB-16** (2c55de1f). `challengeLease`'s "played" query now adds `AND h.validated = 1`. As the report's Fix line says. The test also checks that a validated play still uses up the link.
  - **RB-17** (165fa31f). `offer` takes the easier neighbours with `sorted.slice(Math.max(0, i - half), i)`. As the report's Fix line says. The test also checks that a size-3 offer is unchanged.
  - **Existing tests.** No existing test was changed, skipped or loosened. `cd server && npm test` passes 554 of 554.
  - **Merge evidence.** Main (2e02482a) was merged at f3849470 with no conflict. `owners.py diff FX1-2-leases origin/claude/videogame-project-analysis-ewkkk2 HEAD` reports "every changed path is inside its files". The fresh-container setup line and `bash client/build.sh` ran first (build exit 0). The pre-check at f3849470 passed ("All checks passed.", exit 0, 18:30:38Z, sandbox bwrap); `owners.py diff` at that sha passes. Main's later commit 7c7e389a is lead bookkeeping only (`docs/progress/`), so it was not merged.
  - **Next.** FX1-3-workshop (RB-35, RB-37, RB-38, RB-39), in a fresh session.

## Tried and failed
- 2026-11-21 Refused RB-30 with the report's new reason `taken_down`: the client contract needs every server reason worded in `client/i18n/strings.csv`, a file outside the task. Reused `island_withdrawn` instead.
- 2026-11-21 Ran the server tests before the wasm simulation was built: every service test fails with "ruleborn_sim.wasm is not built". `cargo build --release --target wasm32-unknown-unknown` in `sim/` builds it, and so does the pre-check.
