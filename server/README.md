# The server

The dynamic tier of §24.1: *"Edge functions against a managed serverless SQL
database. No virtual machine, no operating system, nothing to patch."* Its
one real job is §24.12's: re-simulate a heist the device played offline, and
only then mint what it earned.

    node --no-warnings --test server/test/*.test.mjs   # the tests (build sim/ first)
    node server/src/main.mjs                           # run it locally, on 127.0.0.1:8787

It needs Node 22.5 or later and nothing else — no packages. The simulation is
`sim/`'s WebAssembly build (`bash sim/run_spike.sh` builds it), and SQLite is
`node:sqlite`.

## What it does, stage by stage

| §24.12 | Here |
| --- | --- |
| **Lease** — "a target snapshot, a seed, a single-use token and an expiry a day away. Nothing is created yet." | `Service.lease`. §24.13's "one lease per target per player at a time" is a partial unique index, so the database holds it rather than the code. The clock is §5.4's, from `facts.json`. |
| **Play**, **Queue** | On the device: `sim/`'s same library records the replay (`rb_record`). |
| **Validate** — "re-simulates, compares, and checks the token, the expiry and the caps" | `Service.submit`: the token is bound to the attacker; the replay's header must name the leased snapshot, seed and clock; it is re-simulated by the build its rules version names; every second's checksum is compared. |
| **Grant** — "only then is the haul minted, into an append-only ledger" | `Service.grant`, in one transaction with the heist row: the entry fee (§9.4), the haul (§9.6), the fee returned after a clean heist, and the fee paid to the defender after a foiled one (§12.9). |

And the failure rows: a retry is answered from the first decision and pays
nothing twice; a replay that does not reproduce pays nothing, takes nothing
and is flagged for review, never banned; an expired lease pays nothing.

## What the database holds

§24.8's tables, in `src/db.mjs`: `accounts`, `islands`, `snapshots`, `heists`,
plus `leases` and the `ledger`. `snapshots` and `ledger` refuse `UPDATE` and
`DELETE` by trigger — "never edited" and "append-only" are properties of the
schema, not of the code that happens to use it. Balances are sums over the
ledger (§24.12: "currency is a ledger of minting events rather than a number
that gets overwritten").

Islands are stored by the SHA-256 of their bytes (`src/store.mjs`), and the
store requires Node's SHA-256 and the simulation's to agree on every one — so
`sim/src/sha256.rs` is checked against an independent implementation every
time an island is published. A bundle is served with a year's cache, which is
safe only because its address is its content.

## The rules it takes from elsewhere

Every number the server settles with comes from `src/facts.json`, which
`tools/design_facts.py --json` generates after reading each fact back from its
home section of the document; `bash tools/check_all.sh` fails if the copy
drifts. A full crew's carry comes from `content/roles.json`. Nothing is typed
from the prose.

Four things the document leaves open are read in `src/economy.mjs` and
`src/service.mjs`, each named where it is taken (register **G17**):

- §9.6's difficulty "Level or above 1.0 to 1.2" does not say where in the
  range a target falls: read as 0.1 a Keeper level above, capped at 1.2.
- §9.6 does not say what a haul is minted in. §32.9 derives the birth curve
  from "raid Essence at base 2,400 (half of each haul)": minted half Essence.
- §9.4's fee has a floor of 100 and nothing says what a raider holding less
  pays: whatever it holds.
- §24.12's expired lease gets "No reward, with one grace submission allowed":
  read as one expired submission honoured a day.

## What is not built

- **Platform sign-in.** §24.8: "Platform identity is exchanged for a
  short-lived signed token." The token is here (HMAC-SHA256); checking a Game
  Center or Play Games credential needs the stores' services, so `Service`
  takes a `verifyPlatform` function and the tests give it a fake one.
  `main.mjs` accepts any credential and must not face a network.
- **Crossing realms.** The simulation plays the Heart alone, so every lease
  is §5.4's 150 seconds with no links.
- **The daily and weekly caps** (§9.6: "a hard ceiling half again above" the
  fatigue curve, and "five days' worth" a week). Fatigue is applied; the two
  ceilings need the season's calendar and are not.
- **Target lists** (§24.8: "a file, not a query"), leagues, clans, the
  Workshop, Renown, and the defender's "5% of what the crew was carrying".
- **The landing.** The replay has no landing command yet; see `sim/README.md`.

## Layout

    src/sim.mjs       sim/'s WebAssembly builds, one per rules version
    src/store.mjs     content-addressed storage, cross-checked SHA-256
    src/db.mjs        §24.8's schema; append-only by trigger
    src/economy.mjs   §9.4's entry fee and §9.6's haul, in exact ratios
    src/tokens.mjs    signed session tokens
    src/service.mjs   lease, validate, grant
    src/http.mjs      the edge function: Request in, Response out
    src/main.mjs      a local node:http listener around it
    src/facts.json    generated by tools/design_facts.py --json
    test/             node:test, against the real simulation build
