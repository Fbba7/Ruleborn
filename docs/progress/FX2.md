# FX2 fixer, server B: progress

- Status: Waiting. FX2-3-shop is ready at 427a1705 (pre-check PENDING; see "Merge and evidence"). It has fail-first tests, fixes for RB-08, RB-09, RB-11, RB-10 and RB-13, and main merged. `cd server && npm test` passes 556 of 556.
- Progress: 2 of 3 tasks merged (FX2-1 at 23cf8a90, FX2-2 at 8ed7538f), FX2-3 ready. No gate items.
- Done: RB-08, RB-09, RB-11, RB-10 and RB-13, each with a test written first that fails on main.
- Next: the lead's merge of FX2-3.
- Blocked by: none.
- Owner decision needed: none.

| Deliverable | Weight (h) | Status | Evidence |
|---|---:|---|---|
| FX2-1-db-store-home: RB-01, RB-02, RB-07, RB-22 | 3.5 | merged at 23cf8a90 | `server/test/fix_fx2_db_store_home.test.mjs` |
| FX2-2-trace-telemetry: RB-31, RB-32, RB-49, RB-21, candidate 21 | 3.5 | merged at 8ed7538f | `server/test/fix_fx2_trace_telemetry.test.mjs`; `docs/security/audit-2026-11/server.md` |
| FX2-3-shop: RB-08, RB-09, RB-11, RB-10, RB-13 | 4.0 | ready at 427a1705 | `server/test/fix_fx2_shop.test.mjs`. Commits: 3b4d287b (tests), 98f4c3f2 (RB-08), 1d9f4374 (RB-09), 0aab18c7 (RB-11), 05d93c45 (RB-10), 1ab236f9 (RB-13), 427a1705 (merge of main) |

## Handoff
- **Last verified commit:** 427a1705, the `ready_sha`: main 2e02482a merged into the branch. The commit after it changes only this handoff and the status file.

### The tests
- All seven tests are in one file, `server/test/fix_fx2_shop.test.mjs`, committed alone in 3b4d287b before any fix.
- They were run on 4bcc98b0, whose `server/` is main 8ed7538f's. Six fail:
  - **RB-08** (`a Play purchase the server will not grant is refused before Google is told anything`): `nothing acknowledged or consumed, so Play refunds each by itself`. Actual `['t-future', 't-theirs', 't-gone']`, expected `[]`. The 404 `no_such_product`, 409 `intent_mismatch` and 410 `account_deleted` answers already came on main, but from `redeem`, after Google had acknowledged each purchase.
  - **RB-09, race** (`two claims racing for a minor's last €25 do not both reach Google`): `only the granted one was acknowledged`. Actual `['tokA', 'tokB']`, expected `['tokA']`. The statuses were already `[201, 403]` on main, as the report says: the second was refused only after Google acknowledged it.
  - **RB-10, end to end** (`the Play receipt as the JSON string the client sends is verified and granted`): `402 !== 201`.
  - **RB-10, unit** (`a string receipt is read only as a short JSON object of strings`): actual `null`, expected `{ transaction: 'token-abc', product: 'premium.1', intent: null }`.
  - **RB-11** (`a StoreKit transaction for more than one item is refused, as Play's is`): `five items, one grant`. Actual `{ transaction: '2000000123', product: 'gift.robe-aurora', intent: null }`, expected `null`.
  - **RB-13** (`a ninth Game Center key, after eight have each signed a player in, is cached and used`): `gc-prod-9 sign-in works`, `null !== 'gc:T:_p'`.
- **The second RB-09 test passes on main** (`a claim the store refuses holds no place under the cap afterwards`). It guards the fix: a claim the store refuses must let go of its place under the cap.

### The fixes
- **RB-08** (98f4c3f2, `shop.mjs` `claim`). This follows the report's Fix. Before `settleReceipt`, `claim` now refuses a deleted buyer (410), a product the server does not sell (404) and an intent that is another account's or another product's (409). It then runs `capCheck` unconditionally. `redeem` still checks each again after the store answers (SEC-33's test still passes).
- **RB-09** (1d9f4374, `shop.mjs`). This follows the report's Fix: a per-account record of claims still with the store, in memory, as the server runs as one process.
  - `Shop.pending`: account → `"store:txn"` → `{ price, heldUntil }`. A claim adds its entry after `capCheck` passes and before the await, and a `finally` removes it whatever the store answers, before the synchronous `redeem`.
  - `capCheck(account, p, i, now, claiming)` subtracts the other pending claims. It skips the claim's own key (a retry of the same transaction) and a claim whose own live intent is already counted as held, so no price is counted twice.
  - New helper `heldUntil(i, account)`: the old "own live intent" condition, as a time.
  - If the server ever runs as several processes, this must become a DB reservation, as the report says.
- **RB-11** (0aab18c7, `stores.mjs` `appStoreTransaction`). The report's Fix, word for word: a quantity other than 1 is refused; none named is one item.
- **RB-10** (05d93c45, `stores.mjs` `playPurchase`). The report's first Fix: a string receipt of at most 4 × `GOOGLE_MOST` characters is parsed and must be a JSON object. The object form is unchanged.
  - **For the client's owner, not in this task's files:** the Play adapter that replaces the `StorePurchases.buy` stub must put a JSON string (`JSON.stringify({data, signature})`) in `receipt`. `shop_controller.gd:81` passes it through `str()`, which leaves a String as it is but does not turn a Dictionary into valid JSON.
- **RB-13** (1ab236f9, `stores.mjs` `keep`). The report's Fix: `keep` never evicts the key it was just asked to keep. A proven key still goes only after every other unproven one, so SR-20's test passes.
- **Existing tests:** none was changed, skipped or loosened.

### Merge and evidence
- **Merge:** main 2e02482a (lead cycle 158, which merged FX2-2 at 8ed7538f: backlog, the lead's files and status only) merged at 427a1705 with no conflict. It changed no file under `server/`, so the setup from the start of the session holds.
- **Setup:** `rustup target add …` and `pip install …` ran. `(cd server && npm ci)` fails, as `server/` has no `package-lock.json`. I ran `npm install` there instead and deleted the lock file it wrote, which is outside this task's files. `bash client/build.sh`: exit 0. The sim's wasm was built with `cargo build --release --target wasm32-unknown-unknown` in `sim/`.
- **`cd server && npm test`** on 1ab236f9 (the same `server/` as 427a1705): 556 tests, 556 pass, 0 fail.
- **`python3 tools/coord/owners.py diff FX2-3-shop origin/claude/videogame-project-analysis-ewkkk2 427a1705`:** "every changed path is inside its files".
- **`bash tools/run_checks.sh`** (check_all, bwrap) on 427a1705: PENDING.
- **Open hypotheses:** none.
- **Next step:** the lead's merge. This session ends here (one task per session).

## Tried and failed
- 2026-11-21 The first RB-32 drain test passed on main, for the wrong reason (`401 session_refused`). Its session was made before the clock moved 12 h, and a session lasts an hour. It now signs in after the clock moves.
- 2026-11-21 Tried to make RB-49 fail on main by forcing query plans: `NOT INDEXED`, `INDEXED BY`, a dropped index and `reverse_unordered_selects`. All returned the right raider. See "The tests".
- 2026-11-21 Ran the Nursery tests before building the wasm: "ruleborn_sim.wasm is not built". Built it with `cargo build --release --target wasm32-unknown-unknown` in `sim/`.
- 2026-11-21 Raised the test Nursery to level 2 with the starting Spire: refused, `needs_spire_level`. The test helper now sets the Spire to level 3.
- 2026-11-21 `(cd server && npm ci)` in the setup line: no `package-lock.json` in `server/`. Ran `npm install` instead and deleted the lock file it wrote.
