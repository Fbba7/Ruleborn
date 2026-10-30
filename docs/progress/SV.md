# SV server decisions: progress

- Status: Green on the server tests (482 of 482, `python3 server/status.py`); pre-check PASS at 2f3c0dd (All checks passed, 2026-10-30T02:19Z).
- Progress: 0 of 3 tasks merged; SV-B1-B6 ready at 2f3c0dd, awaiting the lead's merge.
- Done: B1 to B6 (SR-09, SR-10, SR-12, SR-14, SR-15, SR-16) in `server/src`, the six tests in `security_owner.test.mjs` changed to the decided behaviour.
- Next: SV-B7-B9 once SV-B1-B6 merges, then SV-B11-B12.
- Blocked by: none.
- Owner decision needed: none.

| Deliverable | Weight (h) | Status | Evidence |
|---|---:|---|---|
| SV-B1-B6 | 4 | ready | `server/test/security_owner.test.mjs`, `python3 server/status.py` |
| SV-B7-B9 | 4 | open (dep SV-B1-B6) | |
| SV-B11-B12 | 3 | open (dep SV-B7-B9) | |

## Handoff
- Last verified commit: 2f3c0dd396db823d08d06a492151db56b911aef3 (pre-check green, 2026-10-30T02:19Z)
- Done: B1 target lists carry no `rating`/`deviation`; B2 `shop.redeem` refuses an intent-less receipt past the month's cap (`monthly_cap`); B3 `ONE_PLAYER_ONE_ISLAND_S = 3600` caps each player-island pair per quarter in `fund.played`; B4 `joinCrew` needs a friend or constellation-mate of one member, a friend of every member for a 13-to-15 (`not_friends`); B5 exposed loot clamped to 750 (`FULL_CREW_CARRY`) at publish; B6 `universe.problems` returns `law_not_woven` for a law not finished in the realm's slots (seeded accounts stay exempt). Guards (G60) are not built, as decided.
- Test support: `server/test/setup.mjs` weaves the laws of a bundle for tests not about SR-16; `server/load.mjs` does the same for its population (a file outside the task's list, changed by three lines because the publish rule broke it; no other agent owns it).
- `client/tests/share_tests.gd` needed no change: its island has no laws and the example server's accounts are seeded. Godot is not installed in this container, so the client suite was not run here.
- Next step: SV-B7-B9.

## Tried and failed
- 2026-10-30 first pre-check: failed the client contract (no string for the new crew refusal); fixed by answering `not_friends`. Second: gdlint missing in the container; installed per the brief.
- 2026-10-30 `node --test test/` (a directory): fails to load; the package script `node --test test/*.test.mjs` is the way.
