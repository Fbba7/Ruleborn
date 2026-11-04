# Usage projection at the end of phase 0

The lead's projection for phase 0's last exit criterion
([report.md](../art/ui-quality/report.md) sections 3.2 and 3.9), filed for
OV-R1 ([requests.md](requests.md)) in lead cycle 27, 4 November 2026, 04:40Z.

## What was measured

- **`/usage` could not be read.** It is an interactive command, and a lead
  cycle runs unattended in a cloud session. The only reading available is the
  rate-limit status in the session's own metadata (`get_session`): the
  seven-day bar reads `allowed_warning`, resetting on 9 November 2026 at
  17:00Z. It gives a tier, not a percentage.
- **No share per model.** The reading is the account's, not any session's
  (G-43), and every session since 2 November ran on one model (Opus 5.5),
  with Sonnet 5.5 idle. So the share per agent-hour is measured only for the
  whole program, from what phase 0 used.

## What phase 0 used

- **First week (to 2 November 17:00Z):** phase 0's building (planned at 43
  agent-hours) and the lead's cycles used the whole weekly bar. The program
  was paused on 31 October 20:55Z to wait for the reset (owner inbox).
- **Second week (from 2 November 17:00Z):** in about 36 hours, about 21% of
  the week, the gate runs (dev-fable, dev-opus to v3 and held-opus: about
  2,000 judge calls), AD's P0-AD-calibrate-2 and lead cycles 18 to 27 put
  the bar into its warning tier, with the five-hour limit reached once (3
  November). The share used is well above the share elapsed plus 10 points,
  which is "running hot" by D-11.

So one weekly bar bought about phase 0's 43 planned hours, with the gate's
calibration on top.

## The projection

| | Agent-hours | Weekly bars at phase 0's rate |
|---|---|---|
| Phase 1 | 58 | about 1.3 |
| Phase 2 | 62 | about 1.4 |
| Phase 3 | 1, plus the 20-hour reserve | about 0.5 |
| 20% reserve for the lead and recovery | about 28 | about 0.6 |
| **Total** | **about 169** | **about 3.9** |

The wave's `stop_at` is 6 November 2026 at 21:00Z, before the next reset,
and the bar is already in warning. **It does not fit**, even at three
builders: phases 1 to 3 need about four more weekly bars.

## What applies

- **D13's answer (c):** three builders at once, never four or five; icon
  batches 3 and 4 deferred. The backlog's `building_cap` of 4 (three UI
  builders plus SV) stays the ceiling, and SV has no open task.
- **Superseded on 4 November 2026 by owner order 3 (CLAUDE.md):** a usage
  tier is no longer a reason to pause, and phase 1 starts now, not after the
  reset. The two items below are kept as history.
- **D-11 and section 3.9's tiers:** while the bar reads `allowed_warning`,
  the lead starts no new building session and no idle-queue task; the
  critical path (the lead, K1, the gate, AIA, S1) is the last to stop, so the
  first sessions after the reset are K1's and AIA's phase 1 steps.
- **Phase 0's exit criteria are all met** with this file. Phase 1 starts
  (tasks seeded, agents started) after the 9 November 17:00Z reset, or
  earlier only if the bar leaves its warning tier. The wave's `stop_at`
  falls before that, so the owner is told (owner inbox, 4 November 04:40Z);
  the default is to keep the program as it is and let the next wave's
  `stop_at` be set when phase 1 is seeded.
- **Measure again at the reset:** with one agent running for its first 30
  minutes alone (G-43's staggered start), the lead reads the bar's movement
  and replaces the rate above.
