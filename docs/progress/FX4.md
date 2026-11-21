# FX4 client fixer: progress

- Status: FX4-2-trace-events ready (RB-31, RB-32, RB-41, RB-42 fixed, each after a test that failed on main).
- Progress: 1 of 4 tasks merged (FX4-1); FX4-2 ready for the lead; no gate items (fix wave).
- Done: RB-31, RB-32, RB-41 and RB-42 fixed on claude/fix-client.
- Next: FX4's next task, in a fresh session once the lead merges FX4-2.
- Blocked by: none.
- Owner decision needed: none.

| Deliverable | Weight (h) | Status | Evidence |
|---|---:|---|---|
| FX4-1-transport: RB-27, RB-03, RB-04 | 3.5 | merged | lead cycle 155, `c28600bb` |
| FX4-2-trace-events: RB-31, RB-32, RB-41, RB-42 | 3.5 | ready | see Handoff |

## Handoff

- Last verified commit: the ready_sha in `status/FX4.json`: the merge of
  main `10909f76` into claude/fix-client (`17a2cbc0`), plus this handoff.
- Commits, in order:
  - `df4481b6` fail-first tests: `client/tests/fix_trace_events_tests.gd`
    (FixTraceEventsTests). `client/tests/run.gd` now calls one aggregator,
    `client/tests/fix_tests.gd` (FixTests), which runs FixTransportTests and
    FixTraceEventsTests: run.gd stays at 1000 lines.
  - `5bf2839d` RB-31: `client/features/observatory/observatory_presenter.gd`.
  - `65d2be84` RB-41: `client/app/services.gd`.
  - `c2596844` RB-32: `client/app/services.gd`, `client/data/device_notices.gd`.
  - `444129d4` RB-42: `client/app/services.gd`.

### The tests, failing on main (before the fixes)

Run on `df4481b6` (main's client plus the tests), Godot 4.7.2 headless:

- **RB-31** (the raider's island is also an offered target; tap the Trace,
  then Plan): `not ok 166 - RB-31: a Trace whose island is also offered as a
  target opens as the Trace, free, and its Plan leases it as a Trace, not as
  the paid target with the same bundle` with `scout card kind player fee
  100.0, planner target kind player`.
- **RB-32** (120 queued events; an eight-day-old crashed session; a 429 and
  no network): `not ok 167 - RB-32: a queue the server refuses for good
  drains ...` with `120 events: batches [120, 120, 120], recorded 0, left
  120; eight days late: left 3, fresh one recorded false; kept after 429 2,
  after offline 2`. The test's server answers as `server/src/telemetry.mjs`
  `batch` does (413 over 100 events, 400 `bad_time` for an event more than
  seven days back).
- **RB-41** (sign_in three times with a fresh session): `not ok 168 -
  RB-41: signing in while the token is still fresh keeps it, with no renewal
  on each visit` with `visits [true, true, true], renewals 3, token kept
  false`.
- **RB-42** (two sends overlapping on a slow network, events added between):
  `not ok 169 - RB-42: overlapping event sends post each event once, and
  none is let go unsent` with `times each event was posted [2, 2, 1, 0], left
  0` (the first two posted twice, the fourth dropped unsent).

### The fixes

- **RB-31:** `ObservatoryPresenter.scout` takes a target with the chosen
  bundle only when the Trace does not have it, so the card the Plan button
  passes is the Trace (`kind` "trace", no fee) and the planner leases it as
  one.
- **RB-41:** `Services.sign_in` calls `session()` instead of
  `session(true)`: a fresh session is kept; an expired one is still renewed
  (`auth.fresh()`), and a refused call still renews through `Api.reauth`.
- **RB-32:** `Services.send_events` first lets go of events older than
  `DeviceNotices.LATE_MS` (seven days, the server's `LATE_MS`) through the new
  `DeviceNotices.drop_before`, then sends the queue in chunks of
  `EVENTS_BATCH` (100, the server's `BATCH`). A chunk refused for good — a
  4xx other than 401, 408 or 429 — is dropped; a 401/408/429, a 5xx or no
  network keeps the rest for the next send.
- **RB-42:** a `_sending` flag: a send overlapping one in flight returns at
  once, and the one in flight reads the queue again after each chunk, so
  what was added meanwhile goes in the same send.

### Evidence

- On `444129d4` (before the merge): `bash client/build.sh` exit 0;
  `python3 client/status.py`: 450 of 450 passed.
- The merge `17a2cbc0` brought only docs/progress changes from main, no
  client file.
- Pre-check on the ready_sha: see `precheck` in `status/FX4.json`.
- `python3 tools/coord/owners.py diff FX4-2-trace-events
  origin/claude/videogame-project-analysis-ewkkk2 17a2cbc0`: "every changed
  path is inside its files".

## Tried and failed

- `client/status.py` cannot start the server until the simulation's
  WebAssembly is built: `cd sim && cargo build --locked --release --target
  wasm32-unknown-unknown` first (the setup line adds the target but does not
  build it).
- The RB-03 overwrite passed on main by timing alone with the plain
  FakeTransport: the test's server delays the public route so the renewal
  lands while the public call is out.
- `client/tests/run.gd` is at gdlint's 1000-line limit: a later task adds its
  tests inside an aggregator such as FixTransportTests, not as new run.gd lines.
- A test that reads its FakeTransport after `Services.close()` hits a freed
  object (close queue_frees the transport) and aborts with no `ok`/`not ok`
  line: read what it recorded before close.
