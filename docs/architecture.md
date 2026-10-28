# Architecture

How Ruleborn is put together: three programs, one simulation shared by two of
them, and a heist's path through all three. Written from the code; file and
function names are given so each claim can be checked. The design's own
account of the backend is §24.1–24.13 of the design document.

## The three parts

```
                 sim/  (Rust: no engine types, no floats, no dependencies)
                  │                                   │
   linked as a Rust library                compiled to WebAssembly
                  ▼                                   ▼
   client/  Godot 4.7.2, GDScript      ◀── HTTPS ──▶   server/  Node 22.5+,
   + client/ext/ (GDExtension, Rust)                   node:sqlite, no npm packages
```

| Part | Language | What it is | Its README |
|---|---|---|---|
| `sim/` | Rust 2021, fixed point, no dependencies | The heist simulation: grid, pathfinding, sight, noise, guard states, laws, abilities, the Vault, the grade; island bundles and the validator; the replay format | [`sim/README.md`](../sim/README.md) |
| `client/` | GDScript on Godot 4.7.2 (Compatibility renderer), plus `client/ext/` in Rust (godot-rust) | The phone game: every screen, the 3D realm, the store of app state, the outbox; `client/ext/` exposes the simulation to GDScript as `RulebornReplay`, `RulebornIsland` and `RulebornStability` | [`client/README.md`](../client/README.md) |
| `server/` | JavaScript (ES modules) on Node 22.5 or later | The dynamic tier: leases, re-simulation of every heist in the same simulation built to WebAssembly, the ledger, accounts and sign-in, matchmaking, seasons, the shop, the Workshop and the rest of the meta-game | [`server/README.md`](../server/README.md) |

Around them:

| Directory | What it holds |
|---|---|
| `content/` | The game's content tables as JSON (laws, ruleborn, forms, features, buildings, roles, notes …), extracted from the design document and validated against it. The simulation's law table and the client's content strings are generated from it. See [`content/README.md`](../content/README.md). |
| `tools/` | Python and Node tools: the design-document checks, the audit register and roadmap generators, the economy model and heist harness, the client's string generators, and the art export harnesses. Listed one by one in the [README](../README.md#repository-layout). |
| `docs/` | Everything written about the game and the build. Indexed in [`docs/README.md`](README.md). |
| `art/design/` | The Screens v3 design's own 3D sources and its target stills. |
| `prototypes/heist-gate/` | A superseded browser prototype, kept because it is still published. |

## One simulation, two hosts

The whole architecture rests on one rule (§24.7): the heist simulation is
written once, with no engine types, and both the phone and the server run that
same compiled code.

- **Determinism** is built into `sim/`: fixed point throughout (`fixed.rs`), a
  committed sine table instead of `libm` (`trig.rs`, `sin_table.rs`), integer
  random streams (`rng.rs`), no maps, overflow checks in release, and a fixed
  phase order per tick (`lib.rs`). `sim/no_floats.py` fails the build if a
  float appears. The full table of hazards is in
  [`sim/README.md`](../sim/README.md#how-determinism-is-obtained).
- **The client** links the crate directly. `client/ext/` is a godot-rust
  GDExtension whose `Cargo.toml` depends on `sim/` as a Rust library;
  `client/build.sh` builds it into `client/bin/libruleborn_godot.so`.
- **The server** loads the crate built for `wasm32-unknown-unknown`
  (`sim/target/wasm32-unknown-unknown/release/ruleborn_sim.wasm`, loaded in
  `server/src/main.mjs` through `Builds` in `server/src/sim.mjs`). It calls the
  C-style exports in `sim/src/ffi.rs` (`rb_verify`, `rb_verify_universe`,
  `rb_generate`, `rb_curated` and others).
- **Proof that the two agree**: `sim/status.py` (run by
  `bash sim/run_spike.sh`) runs the same 240-second heist natively and in
  WebAssembly at five seeds and compares the digests; the client's tests
  re-simulate every golden replay in `sim/golden/` and check every second's
  checksum. A real iPhone and a real Android are the two targets not yet
  proved (they need devices).
- **Rules versions.** A replay names the rules version it was played under;
  the version is computed from the build's behaviour. The server keeps one
  WebAssembly build per rules version it holds (`Builds` keys them by
  `rb_rules_version`) and refuses a replay whose version it does not hold
  (`rules_not_held`).

## A heist, end to end

A heist is a seed and a log of commands, never state (§24.10). Its path:

1. **Lease (server).** The client calls `POST /v1/leases`
   (`server/src/http.mjs`), which runs `Service.lease`
   (`server/src/service.mjs`). The server picks the seed, mints a single-use
   token bound to the attacker, fixes the clock (with the week's era), the
   rules version and an expiry, stores them in `leases` and returns them with
   the target island's content address. Nothing is paid yet.
2. **Play (device).** The heist screen
   (`client/scripts/heist_screen.gd`, driven by
   `client/features/heist/heist_controller.gd`) starts a `RulebornReplay`
   (`client/ext/src/lib.rs`) with the lease's seed, clock, crew and island.
   Each tap becomes one command stamped with its tick. When the heist ends,
   `record()` writes the replay bytes: header (seed, island hash, rules
   version, clock), command log and per-second checksums
   (`sim/src/replay.rs`).
3. **Queue (device).** The replay goes into the outbox
   (`client/data/outbox.gd`) before it is sent, so a crash, a restart or no
   network loses nothing (§24.12). The device shows its own result marked as
   waiting for confirmation.
4. **Validate (server).** `POST /v1/heists/:token` runs `Service.submit`. In
   order: the token belongs to the caller; a repeat gets the first decision
   back; the replay's header must match the lease (island, seed, clock, era);
   the lease must not be expired (one grace submission); the crew, its
   manifest and casts must be the player's; the rules version must be held;
   then `Build.verify` calls `rb_verify`, which re-simulates the heist and
   compares every second's checksum. A heist that does not reproduce pays
   nothing and is flagged for review, never banned.
5. **Grant (server).** In one database transaction, `Service.grant` mints the
   entry fee, the haul and the defender's share into the append-only ledger
   from the server's own verdict bytes, and writes the heist row.
6. **Watch (either side).** Any stored replay re-plays on the client by
   re-simulation; the replay screen checks its checksum against the replay's
   every second.

A heist across a universe (several realms) follows the same path with
`rb_verify_universe` and an `RBU1` bundle (`sim/src/universe.rs`,
`server/src/crossings.mjs`).

## What is authoritative where

| Fact | Authority | Why |
|---|---|---|
| A heist's seed, clock, era, rules version, expiry | The server's lease row | Fixed before play; the replay header must match it |
| What the crew did | The device's command log | The only thing the device contributes |
| What the heist came to (grade, loot, who got out) | The server's re-simulation (`rb_verify`'s verdict, "never the device's") | The device's own result is a preview |
| Currency and items | The server's ledger: balances are sums of append-only rows | `snapshots` and `ledger` refuse `UPDATE` and `DELETE` by trigger (`server/src/db.mjs`) |
| An island | Its bundle, stored by SHA-256 (`server/src/store.mjs`), checked by the simulation's validator against the publishing rules | Content-addressed, so it cannot change under a replay |
| Every number the server settles with | `server/src/facts.json`, generated by `tools/design_facts.py --json` from the design document | `check_all.sh` fails if it drifts |
| The rules themselves | `sim/` | The client never decides a rule again: "A rule the simulation decides is never decided again in the client" ([3D program](art/3d-program.md)) |

Two known gaps, both in the register and the security review: an island's
exposed loot and its laws and guards are, for now, the bundle's word (D60;
SR-15 and SR-16 in [`docs/security/review.md`](security/review.md)).

## Inside the client

The client is layered so data flows one way: views draw state and send taps
on; controllers and presenters (`client/features/<feature>/`) turn taps into
actions; a store (`client/core/store.gd`, `client/app/app_state.gd`) holds
state in slices changed only by reducers; repositories
(`client/data/repositories/`) are the only code that calls the server, each
call a `Result`; the outbox keeps what must reach the server. The
composition root is `client/app/services.gd`. The 3D world
(`client/world/`) draws only what the simulation and the screen's state give
it. The full table of layers is in
[`client/README.md`](../client/README.md#how-it-is-built).

## Inside the server

`server/src/http.mjs` is the edge function (a `Request` in, a `Response`
out); `server/src/main.mjs` wraps it in a local `node:http` listener for
development and tests. Each area of the game is one module (`service.mjs`
for lease, validate and grant; `seasons.mjs`, `shop.mjs`, `workshop.mjs`,
`friends.mjs` and so on); the module list is
[`server/README.md`](../server/README.md#layout). Locally the database is
SQLite through `node:sqlite`; the design's target is a managed serverless SQL
database, and the cost of that is measured in
[`docs/server/db-cost.md`](server/db-cost.md).

## Security and cost

- **Security.** The threat model and design of sign-in and sessions is
  [`docs/security/auth.md`](security/auth.md). The adversarial review of the
  whole app, with every finding (SR-01 onwards), its test and its fix or the
  owner's pending decision, is
  [`docs/security/review.md`](security/review.md).
- **Database cost.** Rows read and written per player per day, as the
  database bills them, what was cut, and the options left for the owner:
  [`docs/server/db-cost.md`](server/db-cost.md). The load test that measures it
  is `node --no-warnings server/load.mjs`; its last measurement is
  `server/load.json`.
- **Privacy.** Every stored column with its purpose and time kept is
  `server/privacy.json`; the stores' declarations are generated from it into
  [`server/declarations.md`](../server/declarations.md).
