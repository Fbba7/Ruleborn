# FX4 client fixer: progress

- Status: FX4-1-transport ready (RB-27, RB-03, RB-04 fixed, each after a test that failed on main).
- Progress: 0 of 4 tasks merged; FX4-1 ready for the lead; no gate items (fix wave).
- Done: RB-27, RB-03 and RB-04 fixed on claude/fix-client.
- Next: FX4-2-trace-events, in a fresh session once the lead merges FX4-1.
- Blocked by: none.
- Owner decision needed: none.

| Deliverable | Weight (h) | Status | Evidence |
|---|---:|---|---|
| FX4-1-transport: RB-27, RB-03, RB-04 | 3.5 | ready | see Handoff |

## Handoff

- Last verified commit: the ready_sha in `status/FX4.json` (the merge of
  main `b2a0dc59` into claude/fix-client, plus this handoff).
- Commits, in order:
  - `b6945c6d` fail-first tests: `client/tests/fix_transport_tests.gd`
    (FixTransportTests), called from `client/tests/run.gd`.
  - `d7af253e` RB-27: `client/app/services.gd`, `client/data/http_transport.gd`.
  - `c9c51e07` RB-03: `client/data/api.gd`, `client/features/auth/auth_session.gd`.
  - `109469be` RB-04: `client/features/auth/auth_controller.gd`.

### The tests, failing on main (before the fixes)

Run on the parent of the fixes (`b6945c6d`, which is main's client plus the
tests). Tokens are labelled in the details, never printed.

- **RB-27** (the report asked for a device check; reproduced on Godot 4.7.2
  headless: services built from a `_ready` under a parent still readying its
  children, against a real local TCP server):
  `not ok - RB-27: on a cold start the services built under a parent still
  readying its children put the HTTP transport in the tree, and the first
  call reaches the server and is answered` with
  `listening true, transport in tree false, answer failed(request_failed { }),
  requests heard 0`. Godot logged "Parent node is busy setting up children,
  `add_child()` failed" at services.gd:100 and `!is_inside_tree()`
  ERR_UNCONFIGURED at `request_raw`. So RB-27 is **confirmed**.
- **RB-03**, a public GET beside a signed-in call:
  `not ok - RB-03: a public GET while signed in sends no token and leaves the
  session's alone ...` with `routes ["POST /v1/session/refresh",
  "GET /v1/balance", "GET /v1/words"], balance sent with the renewed token,
  token after the first token; renewal kept false, next call sent with the
  first token`.
- **RB-03**, an owed sign-out beside a call:
  `not ok - RB-03: a sign-out owed to the server is told with the refresh
  token alone ...` with `routes ["POST /v1/session/end",
  "POST /v1/session/end", "POST /v1/session/refresh", "GET /v1/balance"],
  end sent with no token, balance sent with the renewed token, token after
  the renewed token`.
- **RB-04** (four cases: stale or missing token, crossed with "sign out other
  devices" or "end device 3"; each failed alike):
  `not ok - RB-04: signing out other devices, or one of them, with a token
  past its hour or none at all renews the session first ...` with
  `stale others: failed(session_refused { "error": "session_refused",
  "status": 401 }), routes ["POST /v1/session/end", "POST /v1/session/refresh",
  "GET /v1/session/devices"], end sent with the first token, notice 'Could not
  change that: please sign in again'` (the missing-token cases: "end sent with
  no token").

### The fixes

- **RB-27:** `Services.build` adds the transport at once only when the parent
  is ready; otherwise it adds it deferred, once root is done readying.
  `HttpTransport.send` waits for `tree_entered` when it is not yet in the tree.
- **RB-03:** `Api._raw` takes `authed`; `public_json` and a new
  `public_post_json` send no Authorization header, instead of blanking the
  shared `Api.token` for the whole request and writing the old one back.
  `AuthSession._end_with` (the owed sign-out, ended by its refresh token)
  uses `public_post_json`.
- **RB-04:** `AuthController.end_device` and `sign_out_others` call
  `AuthSession.ensure()` first, through a new `_end`, as `_step_up` does.
  `api.gd`'s rule that `/v1/session/*` is never renewed or retried is left as
  the report asks.

### Evidence

- On `109469be` (before the merge): `bash client/build.sh` exit 0;
  `python3 client/status.py`: 446 of 446 passed.
- On the merge `4c8c0ad4` (main `b2a0dc59`): the setup line exit 0;
  `bash tools/check_all.sh`: see the ready_sha's pre-check in
  `status/FX4.json` (`precheck`) and the line below.
- `tools/coord/owners.py diff FX4-1-transport`: see below.

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
