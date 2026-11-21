# FX2 fixer, server B: progress

- Status: Green. The last push holds FX2-1-db-store-home's fail-first tests, its four fixes (RB-01, RB-02, RB-07, RB-22) and current main merged; `cd server && npm test` 539 of 539.
- Progress: 0 of 1 tasks merged (FX2-1 on its way to ready); no gate items.
- Done: RB-01, RB-02, RB-07 and RB-22, each with a test that fails on main.
- Next: the pre-check through `run_checks.sh`, recorded; then ready for the lead's merge.
- Blocked by: none.
- Owner decision needed: none.

| Deliverable | Weight (h) | Status | Evidence |
|---|---:|---|---|
| FX2-1-db-store-home: RB-01, RB-02, RB-07, RB-22 | 3.5 | working | `server/test/fix_fx2_db_store_home.test.mjs`; commits a5a716b6 (tests), 225b3624 (RB-01), 41a688d5 (RB-02), 5c49d4d1 (RB-22's test), 1dd781cb (RB-22, RB-07) |

## Handoff
- Last verified commit: 1dd781cb (`cd server && npm test` 539 of 539, 2026-11-21); the pre-check comes next, on the merge with main.
- **Done.** One test file, `server/test/fix_fx2_db_store_home.test.mjs`, committed alone in a5a716b6 before any fix. The report's own test folders (`tests/b1-prove-*`) are not in the repository, so each test is written fresh from the entry's Input. On main 9c754b8 all four fail:
  - **RB-01** (`a transaction that throws is rolled back on a node:sqlite without isTransaction`). A Proxy hides `isTransaction`, as Node 22.5 to 22.15 lack it. It fails with `the failed write is undone` / `1 !== 0`.
  - **RB-02** (`an expired cached Game Center certificate is fetched again, and the sign-in succeeds`). It uses a 1-day leaf for the stand-in key under the stand-in chain, `server/test/fix_fx2_gc_short.pem` (openssl, `-days 1`). The clock moves past its validTo and the test signs in again. It fails with `the expired certificate is fetched again`, the diff showing `fetched` held one `https://static.gc.apple.com/public-key/gc-prod-6.cer` where two were expected.
  - **RB-07** (`raising a Nursery that has never given a birth keeps its ready births`). Build, wait 20 h, then raise to level 2. It fails with `an upgrade is neither emptying nor building` / `0 !== 3`.
  - **RB-22** (`raising a Nursery carries the hours before the raise at the old rate`). One birth (so the row exists), wait 5 h, then raise to level 2. It fails with `no birth is ready right after the raise: 5 h at the 6 h rate made none` / `1 !== 0`.
- **The fixes.**
  - **RB-01** (225b3624, `server/src/db.mjs` `transaction`). It rolls back unless `db.isTransaction` is `false`, so `undefined` on an older node:sqlite rolls back too. The report offered this or raising `engines` to 22.16. The code fix is one line and keeps older Node supported, so `server/package.json` is unchanged.
  - **RB-02** (41a688d5, `server/src/stores.mjs` `GameCenter.prepare`). It follows the report's Fix: a cached certificate is reused only while `now <= validTo`. Past that it goes through the rate-limited fetch again, and `keep()` replaces the entry.
  - **RB-22 and RB-07** (1dd781cb, `Home.carryNursery` in `server/src/home.mjs`, called from `Universe.build` before the upsert when an existing Nursery is raised).
    - It keeps the ready births, capped by the new level's holds.
    - It carries the part of a period made at the old rate over as the same share of the new period, written to `nurseries.since`.
    - The report's narrower RB-07 line (`INSERT OR IGNORE … have.changed_at`) would fix RB-07 alone. This one carry fixes both, as the report's RB-22 Fix says.
- **A test corrected.** RB-22's last assertion was mine and could never pass, so I corrected it on its own in 5c49d4d1. It read a `period` field that `home.show`'s Nursery view does not return. It now expects the next birth exactly 50 min after the raise: 5 h of 6 h is 5/6 of level 2's 5 h. Its fail-first assertion, ready `1 !== 0`, is unchanged, and the test still fails that way with the fix taken out. No existing test was changed, skipped or loosened.
- **Merge.** Main 4d488179 (lead cycle 152 files only: backlog, lead.md, lead-archive.md, owner-inbox.md, requests.md, status/lead.json) merged at 112f320c with no conflict. Before that merge: the setup line (`rustup target add wasm32-unknown-unknown`, `pip install "gdtoolkit==4.*" "playwright==1.63.0"`, plus the environment's script) exit 0, then `bash client/build.sh` exit 0.
- **Open hypotheses:** none.
- **Next step:** the pre-check (`run_checks.sh start` / `wait` / `record`), then `owners.py diff`, then ready.

## Tried and failed
- 2026-11-21 Ran the Nursery tests before building the wasm: "ruleborn_sim.wasm is not built". Built it with `cargo build --release --target wasm32-unknown-unknown` in `sim/`.
- 2026-11-21 Raised the test Nursery to level 2 with the starting Spire: refused, `needs_spire_level`. The test helper now sets the Spire to level 3.
