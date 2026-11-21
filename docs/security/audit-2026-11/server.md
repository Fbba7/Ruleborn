# Server audit, November 2026

The server half of the fix wave's extra checks
([bug report](../bug-report-2026-11.md)). Each entry names the test that
settles it.

## Unproven, rechecked

### Candidate 21: a banned raider's island offered as a Trace

- **Claim:** `observatory.mjs` `trace` offers a banned raider's island as
  the Trace, but leasing it answers 410.
- **Result: confirmed, and fixed (FX2-2-trace-telemetry).**
- **Test:** `server/test/fix_fx2_trace_telemetry.test.mjs`, "candidate 21".
  A raider with a home of their own robs the defender with an open plan, so
  the defender has a Trace. The Workshop then bans the raider
  (`Workshop.ban`). On main, the defender's Observatory still offered the
  Trace card (kind `trace`, fee 0, the banned raider's bundle). Meanwhile,
  `service.lease` with `trace` leaves banned holders out, finds none, and
  refuses with 410 `superseded`.
- **Why:** the Trace's raiders query and `matchmaking.traceable` never read
  `accounts.banned_at`. The offer's candidates do (`matchmaking.candidates`).
- **Fix:** the Trace's query joins `accounts` and passes over a raider who
  is banned or deleted. The next most recent raider the player can answer
  is offered instead.

## Notes on the fixed entries

### RB-49: the order is the plan's, and this build's plans happen to agree

The entry's input is three robberies within 24 hours: A, then B, then A.
The test `server/test/fix_fx2_trace_telemetry.test.mjs`, "RB-49", runs it
through the service. On main it passes on this build's SQLite. It still
passes with the defender's index dropped, under `NOT INDEXED`, under
`INDEXED BY heists_by_attacker` and under
`PRAGMA reverse_unordered_selects`. With `SELECT DISTINCT`, every plan
SQLite picked here returned A first.

The query still leaves the order to the plan. `SELECT DISTINCT h.attacker
… ORDER BY h.submitted_at` sorts by a column the result does not hold.
Written by hand with the leases read first (`FROM leases l CROSS JOIN
heists h`), the same query returned B before A on the same rows.

The fix follows the report: `GROUP BY h.attacker ORDER BY
MAX(h.submitted_at) DESC`. The test stays as a guard. It reads the Trace
in every order the planner can be pushed to.
