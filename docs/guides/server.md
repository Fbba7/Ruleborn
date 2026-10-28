# Server developer guide

The Node server in `server/`: how to run it, test it, load-test it, and
configure it. What it does area by area is in
[`server/README.md`](../../server/README.md); how it fits with the client and
the simulation is in [`docs/architecture.md`](../architecture.md).

## Prerequisites

- **Node 22.5 or later.** No npm packages: the database is `node:sqlite`, the
  tests are `node:test`. `npm install` is not needed.
- **The simulation's WebAssembly build**, which the server loads to
  re-simulate heists:

  ```bash
  rustup target add wasm32-unknown-unknown   # once
  bash sim/run_spike.sh                      # builds sim/target/wasm32-unknown-unknown/release/ruleborn_sim.wasm
  ```

## Run it locally

```bash
RULEBORN_STUB_SIGNIN=1 node --no-warnings server/src/main.mjs                 # 127.0.0.1:8787
RULEBORN_STUB_SIGNIN=1 node --no-warnings server/src/main.mjs 8787 --example  # and publish the example island to raid
```

The first argument is the port (8787 by default). `--example` publishes an
example island so a fresh database has something to lease. Data goes to
`server/.data/` unless `RULEBORN_DATA` says otherwise; delete it for a fresh
start.

`RULEBORN_STUB_SIGNIN=1` accepts a stand-in sign-in credential, which is what
a desktop client sends (it has no Game Center or Play Games). Without it, and
without any platform configured, the server refuses to start (security
finding SR-29): a stubbed sign-in must be asked for.

## Test it

```bash
node --no-warnings --test server/test/*.test.mjs   # every test (about sixty files)
(cd server && npm test)                            # the same, through package.json
python3 server/status.py                           # the same as TAP, written to server/status.json
```

`status.py` is what `check_all.sh` runs: it fails if any test fails, and
`server/status.json` is what the roadmap's completion figure reads
(`tools/completion.py`). Tests run against the real WebAssembly build, so
build `sim/` first.

Test files are named by area (`service.test.mjs`, `shop.test.mjs`, …). Two
families are worth knowing:

- `security_*.test.mjs`: one test per security finding, from the security
  review ([`docs/security/review.md`](../security/review.md)). Each pins the
  fix; a failing one means a finding has come back.
- `db_*.test.mjs` and `cost.test.mjs`: the database's reads and writes per
  action, from the cost work ([`docs/server/db-cost.md`](../server/db-cost.md)).

## The load test

```bash
node --no-warnings server/load.mjs           # runs the load test and prints the report
node --no-warnings server/load.mjs --write   # and records it in server/load.json
node --no-warnings server/load.mjs --check   # what check_all.sh runs: fails if writes or reads moved since load.json
```

It plays a population of simulated players (`--players N`, `--days D`)
through the real service and the simulation's WebAssembly build, and counts
rows read and written as the database bills them, and the CPU a
re-simulation takes. Writes are deterministic; CPU time is the machine's. `server/load.json` is the
last measurement; [`docs/server/db-cost.md`](../server/db-cost.md) explains
what the numbers mean and what they cost a month.

## Configuration

Read from the environment by `server/src/main.mjs`. Everything has a
development default except what a real deployment needs.

| Variable | What it sets |
|---|---|
| `RULEBORN_DATA` | where the database and island store live (default `server/.data/`) |
| `RULEBORN_SECRET`, `RULEBORN_TOKEN_KEYS` | the keys that sign session tokens |
| `RULEBORN_REFRESH_ROTATE_HOURS` | how often a refresh token rotates (an owner decision; see [`docs/progress/T11.md`](../progress/T11.md)) |
| `RULEBORN_SEASON_START` | the first season's start |
| `RULEBORN_DELETIONS` | the account-deletion journal |
| `RULEBORN_STUB_SIGNIN` | `1` accepts a stand-in sign-in (development only) |
| `RULEBORN_GOOGLE_CLIENT_IDS`, `RULEBORN_GOOGLE_WEB_CLIENT_ID` | Google sign-in, and the web deletion page's |
| `RULEBORN_BUNDLE_ID`, `RULEBORN_GAMECENTER_ROOTS`, `RULEBORN_STOREKIT_ROOTS`, `RULEBORN_APPLE_SANDBOX` | Game Center and StoreKit proofs |
| `RULEBORN_PLAY_PACKAGE`, `RULEBORN_PLAY_LICENCE_KEY`, `RULEBORN_PLAY_SERVICE_ACCOUNT`, `RULEBORN_PLAY_TEST` | Google Play purchases |
| `RULEBORN_CF_ZONE`, `RULEBORN_CF_PURGE_TOKEN`, `RULEBORN_PUBLIC_ORIGIN` | purging deleted bundles from the edge cache |
| `RULEBORN_FCM_SERVICE_ACCOUNT`, `RULEBORN_FCM_PROJECT` | push notifications through Firebase Cloud Messaging |
| `RULEBORN_CONTACT` | the contact shown on the stores' pages |
| `RULEBORN_PEER_HEADER`, `RULEBORN_PLACE_HEADER` | which request headers carry the caller's address and country behind a proxy |

The meaning of each is in the module that reads it; `main.mjs` names them.
This table lists the names only and is not a deployment guide: **no production
deployment is described in this repository**: where and how the server is
to be deployed (the design names edge functions over a managed serverless
SQL database, and the cost work measures against Cloudflare D1's billing) is
not written down here (a question for the owner, in
[`docs/DOCS-CHANGES.md`](../DOCS-CHANGES.md)).

## Generated files the server reads

Never edit these by hand; regenerate them.

| File | Written by | Checked by |
|---|---|---|
| `server/src/facts.json` | `python3 tools/design_facts.py --json > server/src/facts.json` | `python3 tools/design_facts.py --check-json server/src/facts.json` |
| `server/src/leagues.json` | `python3 tools/league_model.py --json > server/src/leagues.json` | `python3 tools/league_model.py --check server/src/leagues.json` |
| `server/declarations.md` | `node --no-warnings server/src/privacy.mjs --write`, from `server/privacy.json` | `node --no-warnings server/src/privacy.mjs --check` |
| the iOS preset's privacy options in `client/export_presets.cfg` (Godot writes them into `PrivacyInfo.xcprivacy`) | `python3 tools/privacy_manifest.py`, from `server/privacy.json` and `server/ratings.json` | `python3 tools/privacy_manifest.py --check` |

## Adding a route

Routes are in `server/src/http.mjs`; the logic sits in one module per area.
The client's calls are checked against the routes: `python3
tools/client_contract.py` fails the build if the client calls a route the
server does not serve, or if a refusal reason the server can send has no
words on the client (`client/core/errors.gd`).
