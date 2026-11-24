# FX4 client fixer: progress

- Status: FX4-4-audit-client ready. The client audit is written, 12 findings
  are fixed, each after a test that failed on main, and 2 are proven and
  still open.
- Progress: 3 of 5 tasks merged (FX4-1, FX4-2, FX4-3); FX4-4 ready for the
  lead; no gate items (fix wave).
- Done: `docs/security/audit-2026-11/client.md`, CLI-1 to CLI-24.
- Next: the lead merges FX4-4; follow-ups for CLI-1 (server), CLI-18
  (`stage_rehearsal.gd`) and the unproven items, if wanted.
- Blocked by: none.
- Owner decision needed: none.

| Deliverable | Weight (h) | Status | Evidence |
|---|---:|---|---|
| FX4-1-transport: RB-27, RB-03, RB-04 | 3.5 | merged | lead cycle 155, `c28600bb` |
| FX4-2-trace-events: RB-31, RB-32, RB-41, RB-42 | 3.5 | merged | `8ed7538f` |
| FX4-3-replay-shop-nav: RB-43, RB-20, RB-58, RB-59 | 3.5 | merged | `8be82e6f` on main |
| FX4-4-audit-client: the client audit | 4 | ready | see Handoff |

## Handoff

- Last verified commit: the ready_sha in `status/FX4.json`.
- The report: [`docs/security/audit-2026-11/client.md`](../security/audit-2026-11/client.md).
  It lists each finding with Where, Input, Should happen, Happens, the
  proof and the fix, then the report's five client suspicions, Unproven,
  What was read and Still not read.
- Commits, in order:
  - `c4a5eb7c`: the proofs, committed before any fix:
    `client/tests/fix_audit_client_tests.gd` (FixAuditClientTests) and its
    `.uid`, run from the aggregator `client/tests/fix_tests.gd`.
  - `4d5a17d3`: the fixes for CLI-2, 4, 5, 6, 7, 10, 11, 13, 15, 22 and 24.
  - `684353ef`: CLI-11's order (an authored island, then a curated one,
    then the generator's), after the full suite caught the first version.
  - `8f91599d`: CLI-14's proof and fix (`client/app/app_lifetime.gd`).

### The proofs, failing on main

Main is `1c4fd104`, the branch point; its client code is the code the
proofs ran on.

- The plain checks failed on main, each before its fix:
  - CLI-2, 4, 5, 6, 7, 10, 11, 13, 15, 22 and 24 (run on `c4a5eb7c`, the
    scratch runner `FixAuditClientTests` alone: 11 `not ok`);
  - CLI-14 (run before `8f91599d`'s fix: `not ok 14 - CLI-14: a session
    the app never closed is ended at the last time it was seen open, not
    at its start (24)`).
- After the fixes, all 14 checks pass.
- The two still-open checks, CLI-1 and CLI-18, pass while their defect
  holds. They fail once it is fixed, and then they say to make them plain
  checks.

### Follow-ups for the lead (not in this task's files)

- **CLI-1 (High):** a curation swap's publish is refused while its law
  weaves. The fix is on the server (SR-16 takes the slot's weaving law), or
  the client waits to publish until the law is woven.
- **CLI-18 (Medium):** `client/scripts/stage_rehearsal.gd`. A run asked for
  while one plays should start the new style's run.
- **CLI-3 (High, unproven):** `client/scripts/heist_screen.gd`. An offline
  heist sends the planner's crew.
- **CLI-8 and CLI-9:** contract notes for the server. The Observatory card
  has no owner, and the Defences trace has no `across`.
- **FX4-R1** (from FX4-3) still stands.

### Evidence

- `python3 client/status.py` after the fixes: 468 of 468 passed (its run
  before `3c29854a` gave 464 of 466; see Tried and failed).
- The scratch runner, `FixAuditClientTests` alone: 14 checks, all `ok`.
- `bash client/build.sh`: passes.
- The program's main merged at `0fbb5dbb` (35 commits, none under `client/`).
- The pre-check and the owners diff are recorded in `status/FX4.json`
  (`precheck`, `ready_sha`).

## Tried and failed

- CLI-11's first fix made every player's generated island equal to an
  authored one. Three server-backed tests then failed (the leased heist
  Foiled, the Keeper XP check and the workshop creator test). Under
  `--example`, the server publishes the `example:universe` account's islands
  as generated, and those tests want the authored `example:defender`
  Heart. Keeping authored islands first fixed it.
- CLI-14's first test freed an `AppLifetime` after putting `App.services`
  back. Its teardown then ended and closed the suite's services and set
  `App.services` to null, so home showed no controls in the layout checks
  (464 of 466). Free the node while `App.services` is null.
- A freed Object reads as null in GDScript: compute a check's flags before
  `queue_free`.
- CLI-21's race (roster `collect_all`) needs a slow transport.
  `FakeTransport` answers at once; the `SessionServer` class in the audit
  tests shows how to slow one route.
- `client/status.py` needs the simulation's WebAssembly built first (`cd
  sim && cargo build --locked --release --target wasm32-unknown-unknown`).
- `client/tests/run.gd` is at gdlint's 1000-line limit: new tests go in an
  aggregator such as `fix_tests.gd`.
