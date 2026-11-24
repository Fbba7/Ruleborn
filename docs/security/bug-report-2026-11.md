# Ruleborn: confirmed defects

Repository: https://github.com/Fbba7/Ruleborn, commit `96777f7f16fbd4d6b8f56de37b9e424e6ef83d4a`.

**What was read, in three workflow runs** (details in "What was read" below):
- **Batch 1:** the Node server's most exposed modules and the Godot client's network layer (47 files, about 11,800 lines).
- **Batch 2:** the remaining server modules, the simulation's parsing core (`ffi.rs`, `replay.rs`, `heist.rs`, `island.rs`, `universe.rs`, `grid.rs`) and the client app shell and native extension (33 files, about 11,500 lines).
- **Batch 2 proving run:** proved batch 2's suspicions, and gave `ffi.rs` and `heist.rs` the second look they had missed.

In total, about 23,300 lines in 80 files were read; about 132,000 lines of the repository's code were not (listed below).

A defect is in this list only if a second agent, working on its own, proved it. It either wrote a test that fails on the current code ("demonstrated") or quoted the exact lines. All 60 below were **demonstrated**. Some client (GDScript) defects were demonstrated on line-for-line ports, because Godot can't run here; those entries say so.

Each defect's test, its output and the suggested fix (`fix.diff`) are in `/mnt/session/outputs/tests/b1-prove-<N>/` (batch 1) or `tests/b2-prove-<N>/` (batch 2). `<N>` is the candidate number given in each entry. Server tests that ran without the WebAssembly simulation (which isn't built here) come with the stub `setup.stub.mjs` they used.

## Summary

| ID | Priority | Category | Location | Title |
|---|---|---|---|---|
| RB-27 | High | frontend/UI | `client/app/services.gd build` | The HTTP transport is never added to the scene tree on a normal launch, so every API call fails |
| RB-01 | High | integration | `server/src/db.mjs transaction()` | A failed transaction never rolls back on Node 22.5–22.15 |
| RB-02 | High | integration | `server/src/stores.mjs GameCenter.prepare` | A cached Game Center certificate is never fetched again |
| RB-28 | High | backend | `sim/src/lib.rs World::heal` | Regrowth cuts any Vault above level 1 down to level-1 health |
| RB-29 | High | backend | `sim/src/universe.rs Crossing::go` | In a universe heist, a realm's alarm counts from the start of the heist, not from the crew's arrival |
| RB-30 | High | security | `server/src/workshop.mjs publish` | A creator can republish, byte for byte, an island a moderator removed |
| RB-03 | High | frontend-backend contract | `client/data/api.gd public_json` | `public_json` blanks the shared session token for the whole request |
| RB-04 | High | frontend-backend contract | `client/data/api.gd raw` | Ending other devices fails whenever the access token is stale |
| RB-31 | High | frontend-backend contract | `server/src/observatory.mjs view` | Tapping a free Trace can start a paid raid instead |
| RB-05 | High | backend | `server/src/service.mjs grant` | An echo raid uses up the pair's daily scoring |
| RB-06 | High | backend | `server/src/matchmaking.mjs offer` | Players' curated islands are treated as the game's generated fallbacks |
| RB-32 | High | frontend-backend contract | `server/src/telemetry.mjs batch` | One refused telemetry batch blocks the device's event queue for good |
| RB-07 | High | backend | `server/src/home.mjs nursery` | Raising a Nursery that has never given a birth loses its ready births |
| RB-08 | Medium | backend | `server/src/shop.mjs Shop.claim` | A Play purchase is acknowledged before it is checked |
| RB-09 | Medium | backend | `server/src/shop.mjs Shop.claim` | Race on a minor's monthly cap |
| RB-33 | Medium | security | `server/src/edge.mjs queuePurge` + `http.mjs` bundles | The under-13 edge purge misses other URLs that serve the same bundle |
| RB-34 | Medium | security | `server/src/accounts.mjs` erase / `finishErasures` | An under-13 deletion never purges the cached target lists that name the child |
| RB-11 | Medium | backend | `server/src/stores.mjs appStoreTransaction` | A StoreKit transaction with quantity > 1 is accepted as one item |
| RB-35 | Medium | security | `server/src/workshop.mjs play`/`submitPlay` | A Workshop play can be verified under any rules build the server still holds |
| RB-10 | Medium | frontend-backend contract | `server/src/stores.mjs playPurchase` | The client sends the Play receipt as a string and the server needs an object |
| RB-12 | Medium | backend | `server/src/matchmaking.mjs current` + `service.mjs lease` | Yesterday's generated islands can be leased as echoes |
| RB-36 | Medium | backend | `server/src/codex.mjs afterHeist` | Repeat friendly heists pay the defender a law page every time |
| RB-37 | Medium | backend | `server/src/workshop.mjs publish` + `fund.mjs` | Listing the same island several times multiplies one fan's completions and Island Fund time |
| RB-13 | Medium | integration | `server/src/stores.mjs keep` | A new Game Center key is evicted as soon as it is cached |
| RB-14 | Medium | backend | `server/src/service.mjs lease` | Asking again for a held Trace is refused |
| RB-15 | Medium | backend | `server/src/holds.mjs work` | A failed hold measurement is stored as a real measurement |
| RB-39 | Medium | backend | `server/src/workshop.mjs resolve` | Dismissing a player's report turns off spike review for that island for good |
| RB-38 | Medium | backend | `server/src/workshop.mjs ladder` | Featured islands still count toward the creator ladder after moderation removes them |
| RB-40 | Medium | backend | `sim/src/island.rs check`/`decode` | An island's entrance can be placed inside a wall or on the Vault |
| RB-41 | Medium | integration | `client/app/services.gd sign_in` (170-171) | `Services.sign_in()` forces a token refresh on every call |
| RB-42 | Medium | frontend/UI | `client/app/services.gd send_events` | Overlapping event sends post events twice and drop later ones |
| RB-43 | Medium | frontend-backend contract | `client/ext/src/lib.rs RulebornReplay::load` | The replay screen re-simulates a leased heist on the test island |
| RB-16 | Medium | backend | `server/src/service.mjs challengeLease` | A refused upload uses up a challenge link |
| RB-17 | Medium | backend | `server/src/matchmaking.mjs offer` | An offer of size 1 returns the easiest candidate |
| RB-18 | Medium | backend | `server/src/crossings.mjs of` | A universe with no link rows is never raided as a universe |
| RB-19 | Medium | backend | `server/src/sim.mjs Build` | An older pinned wasm build cannot be loaded |
| RB-20 | Medium | frontend-backend contract | `client/features/shop/shop_presenter.gd kind_of` | The free hatch outfit can't be worn from the shop screen |
| RB-21 | Medium | frontend-backend contract | `server/src/home.mjs rate` | `full_at` is null while a producer's worker rests |
| RB-22 | Medium | backend | `server/src/home.mjs:514-516` | Raising a Nursery pays out past hours at the new rate |
| RB-44 | Medium | backend | `sim/src/lib.rs World::report` | A defender's report says the defence "held" for the whole clock after any Prism mite split |
| RB-45 | Medium | backend | `sim/src/lib.rs` clock end (3767) | A slowed heist clock never catches the crew still inside |
| RB-46 | Medium | backend | `server/src/notifications.mjs raids` | The raid notification lists refused (invalid) submissions |
| RB-47 | Medium | backend | `server/src/notifications.mjs raided` | Friendly and challenge heists after the day's first notification are never notified |
| RB-48 | Medium | backend | `server/src/notifications.mjs send`/`raids` | A raid can be pushed twice after a push retry |
| RB-49 | Medium | general | `server/src/observatory.mjs trace` | The Trace can point at an older raider instead of the most recent one |
| RB-50 | Medium | general | `sim/src/island.rs weave` | In the island builder, tapping the Vault with the law tool deletes that law |
| RB-51 | Medium | backend | `server/src/lab.mjs chordOf` | Crossing an island hints only the first chord each group of three laws makes |
| RB-52 | Medium | backend | `server/src/lab.mjs hint` (206) | The Lab's hint can name a resonance that can't be found at launch |
| RB-53 | Medium | backend | `server/src/codex.mjs study` | Studying a heist whose island was erased answers 500 |
| RB-23 | Medium | backend | `server/src/auth.mjs rotateHoursOf` | A refresh-rotation span of 720 h signs devices out after 30 days |
| RB-24 | Low | security | `server/src/auth.mjs signOutWith` | A lapsed refresh token can still sign out every device |
| RB-25 | Low | security | `server/src/home.mjs crewProblem` | The manifest's form byte is not checked |
| RB-54 | Low | security | `sim/src/replay.rs decode`/`read_varint` | The replay decoder accepts several byte strings for the same heist |
| RB-26 | Low | backend | `server/src/http.mjs` roles route (244-246) | The roles route ignores the constellation id in the URL |
| RB-56 | Low | backend | `server/src/workshop.mjs queue`/`resolve` | After an under-13 deletion, a player's reports look like the server's own spike reports |
| RB-55 | Low | general | `sim/src/replay.rs Heist::encode` (289) | A command for actor 16 or above is recorded as a different crew member |
| RB-57 | Low | general | `sim/src/island.rs claim` | Placing a ward or pylon on a guard standing in tall grass leaves the island unpublishable |
| RB-58 | Low | frontend/UI | `client/app/router.gd go_back` | The system back button resets the roster's stage and filter |
| RB-59 | Low | frontend/UI | `client/core/action_log.gd add` (18) | Navigation entries in the action log lose the screen name |
| RB-60 | Low | general | `server/src/pages.mjs plain` | The public privacy policy shows leftover reference text |

**Per priority:** Critical 0 · High 13 · Medium 37 · Low 10 (60 total)

**Per category:** backend 32 · security 7 · frontend-backend contract 8 · general 5 · frontend/UI 4 · integration 4

The list is in priority order, with the most severe first within each level. IDs are stable across batches (RB-01 to RB-26 come from batch 1, RB-27 to RB-60 from batch 2), so they are not in numeric order.

---

## High

### RB-27: The HTTP transport is never added to the scene tree on a normal launch, so every API call fails
- **Priority / category:** High / frontend/UI. Batch 2, candidate 36.
- **Where:** `client/app/services.gd` `build`, lines 98-100 (`parent.add_child(t)`), called from `client/app/app.gd:19`, which `client/scripts/home.gd:133-134` (`_ready`) calls. The main scene is `home.tscn` (`client/project.godot:11`).
- **Input:** a normal cold start of the app.
- **Should happen:** the HTTP transport is added under the root node and requests go out.
- **Happens:**
  - `root.add_child` runs while root is still calling its children's `_ready`. Godot refuses that call ("Parent node is busy setting up children…"), so the transport stays outside the tree.
  - Every `HttpTransport.send` then gets `ERR_UNCONFIGURED` from `request_raw` and returns `{"error":"request_failed"}`. This lasts until a sign-out rebuilds the services.
  - `app.gd:21-22` already defers its other `root.add_child` calls (`call_deferred`) for exactly this reason.
- **Evidence:** `tests/b2-prove-36/port.test.mjs` ports the Godot rules for adding a child during ready, plus the client code line for line. Output: `transport in tree: false result: { error: 'request_failed' }`. The engine rules in the port come from the prover's memory of the Godot 4 source, and Godot could not be run here, so please confirm this on a device. It matches a well-known Godot 4 error, though.
- **Fix:** add the transport with `parent.add_child.call_deferred(t)` when the parent is not ready yet. In `HttpTransport.send`, start with `if not is_inside_tree(): await tree_entered`. Checked in the port.

### RB-01: A failed transaction never rolls back on Node 22.5–22.15
- **Priority / category:** High / integration (runtime contract). Batch 1, candidate 12.
- **Where:** `server/src/db.mjs`, `transaction()`, lines 1319-1321. The supported range is set in `server/package.json:6` (`"engines": { "node": ">=22.5" }`).
- **Input:** run the server on any Node from 22.5 to 22.15. Then any `transaction(db, fn)` whose `fn` throws, for example a `Refused` raised inside a grant.
- **Should happen:** "all of it or none of it". The failed writes are undone and the next transaction works.
- **Happens:** `DatabaseSync.isTransaction` only exists from Node 22.16 / 24.0. On older Node it is `undefined`, so no `ROLLBACK` runs. The half-done writes stay visible on the connection, and every later `transaction()` throws "cannot start a transaction within a transaction". Plain writes after that sit uncommitted inside the dead transaction and are lost when the connection closes. In practice the backend is down until a restart, and data written in the meantime is lost.
- **Evidence:** `tests/b1-prove-12/rollback.test.mjs` uses a Proxy that hides `isTransaction`, to stand in for the older Node: `expected: 0 / actual: 1` rows after the failed transaction.
  ```js
  if (db.isTransaction) {
    try { db.exec("ROLLBACK"); } catch (rollbackErr) { err.rollback = rollbackErr; }
  }
  ```
- **Fix:** `if (db.isTransaction !== false)` (always try `ROLLBACK` when the property is missing), or raise `engines` to `>=22.16`. Checked: the test passes with the fix.

### RB-02: A cached Game Center certificate is never fetched again
- **Priority / category:** High / integration. Batch 1, candidate 18.
- **Where:** `server/src/stores.mjs`, `GameCenter.prepare`, lines 248-254. The check that then fails is `verify`, line 306.
- **Input:** the cached certificate for a `publicKeyUrl` (for example `gc-prod-6`) passes its `validTo` date, or Apple serves a renewed certificate at the same URL. Then a player signs in with that key.
- **Should happen:** the expired certificate is fetched again and the sign-in succeeds.
- **Happens:** `prepare` returns early whenever the URL is in the cache (`if (known) { … return; }`). `verifyChain` then rejects the expired certificate. Every Game Center sign-in that names that key gets a 401 until the process restarts.
- **Evidence:** `tests/b1-prove-18/gc_expiry.test.mjs` uses a real 1-day leaf and a renewed leaf served at the same URL: `fetches: 1`, `expected 'gc:T:_player1', actual null`.
- **Fix:** line 249: `if (known && now <= Date.parse(known.cert.validTo)) {`. Checked: the test passes and the existing Game Center unit tests still pass.

### RB-28: Regrowth cuts any Vault above level 1 down to level-1 health
- **Priority / category:** High / backend (simulation). Batch 2, found by the extra second look at `ffi.rs` and `heist.rs` (candidate 101).
- **Where:** `sim/src/lib.rs` `World::heal`, lines 4803-4806 (`let full = heist::VAULT_HEALTH_PER_LEVEL;`). Compare `from_island`, line 1069, which sets health to `1500 × vault_level`.
- **Input:** an island with `vault_level = 10` and the Regrowth law woven, stepped for one second. The stock `Island::example()` is level 3 and is affected too.
- **Should happen:** an untouched Vault stays at 15000 health, and healing is 2% of 15000 per second.
- **Happens:** health is capped at 1500 on the first heal tick. A defender who weaves Regrowth makes their own Vault up to 10× easier to crack, and the server's verification agrees, because it runs the same simulation.
- **Evidence:** `tests/b2-prove-101/tests_rs_added.diff`: `left: 1500, right: 15000`.
- **Fix:** store the full health on `Vault` at construction and use it in `heal`. Checked: the test passes, and so do all 337 simulation library tests.

### RB-29: In a universe heist, a realm's alarm counts from the start of the heist, not from the crew's arrival
- **Priority / category:** High / backend (simulation). Batch 2, candidate 8.
- **Where:** `sim/src/universe.rs` `Crossing::go`, line 522 (`next.tick = prev.tick`), together with `sim/src/lib.rs:3231` (`alarm = now / ALARM_STEP_TICKS …`).
- **Input:** a two-realm universe joined by a Stone link. The crew crosses to the Heart about 151 s in.
- **Should happen:** the Heart's alarm starts at 0 when the crew arrives, as in the harness the hold tables were measured on (`tools/heist_harness/sim.py:436-442`, "Each realm keeps its own alarm, from when the crew arrives").
- **Happens:** the Heart is at alarm 5 on the crew's first tick there, reinforced, and an extra Warden spawns. Every crossing after 30 s starts the next realm at a raised alarm. This affects every multi-realm heist.
- **Evidence:** `tests/b2-prove-8/prove8_test.rs`: `alarm 5 reinforced true guards 2 -> 3`, expected alarm 0.
- **Fix:** add an `alarm_from` tick to `World`, set it when a realm is first entered, and compute the alarm from `now - alarm_from`. Checked: the new test and the 18 existing realm tests pass. The golden replays were not re-run.

### RB-30: A creator can republish, byte for byte, an island a moderator removed
- **Priority / category:** High / security (moderation bypass). Batch 2, candidate 13.
- **Where:** `server/src/workshop.mjs` `publish`, lines 171-178. The duplicate check `listedElsewhere` only looks at other creators (`creator != ?`).
- **Input:** publish X → a player reports it as offensive → the moderator resolves with remove → the creator publishes X again.
- **Should happen:** refused. The removal is meant to take the island out of the Workshop.
- **Happens:** a new item with `removed_at NULL` is created and listed again straight away.
- **Evidence:** `tests/b2-prove-13/prove13.test.mjs`: the removed bytes were published again as a new item.
- **Fix:** refuse with `409 taken_down` when the creator has an item with the same bytes that was removed. Checked. (A creator could still change one byte to get past this; repeat offenders need a ban.)

### RB-03: `public_json` blanks the shared session token for the whole request
- **Priority / category:** High / frontend-backend contract. Batch 1, candidate 11.
- **Where:** `client/data/api.gd`, `public_json`, lines 130-133. The same pattern is in `client/features/auth/auth_session.gd` `_end_with`, lines 321-326.
- **Input:** while signed in, the observatory or curation screen loads `/v1/words` (`observatory_controller.gd:22`, `curation_controller.gd:44`) while another authed call (home view, outbox flush) is in flight.
  ```gdscript
  var held := token
  token = ""
  var r := await _raw(HTTPClient.METHOD_GET, path, PackedByteArray())
  token = held
  ```
- **Should happen:** a public GET leaves `api.token` alone.
- **Happens:**
  - The concurrent call sees `token == ""` and forces a refresh, which spends a refresh token for nothing.
  - When `public_json` returns, it writes the old token back over the renewed one, while `expires_at` and `account` describe the new session. Later calls are refused and trigger more renewals.
  - If the renewal answered for a different account, later calls go out with the previous account's token. This breaks the SEC-29 rule that a call is never sent as the account before.
- **Evidence:** `tests/b1-prove-11/public_json_race.test.mjs` is a line-for-line JS port, because Godot is not installed: `refreshes started by concurrent call: 1 | api.token = TOKEN_A | auth.account = B | later /v1/roster sent with: Bearer TOKEN_A`.
- **Fix:** give `_raw` an `authed := true` parameter and add the Authorization header only when `authed and token != ""`. Make `public_json` call `_raw(..., false)` and drop the save/blank/restore. Make the same change in `_end_with`. Checked on the port.

### RB-04: Ending other devices fails whenever the access token is stale
- **Priority / category:** High / frontend-backend contract. Batch 1, candidate 23.
- **Where:** `client/data/api.gd` `raw`, lines 61, 64 and 72. These treat every `POST /v1/session/*` as a sign-in route, so the call is never renewed or retried. The calls are in `client/features/auth/auth_controller.gd:97` (`sign_out_others`) and in `end_device`. The server side is `server/src/auth_http.mjs:110`.
- **Input:** the account panel has been open for more than an hour, or the app was launched with only a refresh token. The player taps "sign out other devices", which sends `POST /v1/session/end {others:true}`, or "end this device".
- **Should happen:** the token is renewed and the call succeeds. The `Api.reauth` doc promises that calls with no session or an expired one sign in and are retried.
- **Happens:** one POST goes out with an expired token or none. The server refuses it with `session_refused` and nothing retries, so the panel shows `AUTH_ACTION_FAILED`. This is the action a player uses against a lost or stolen phone. Link and unlink are not affected, because `_step_up` calls `ensure()` first.
- **Evidence:** `tests/b1-prove-23/prove.test.mjs` runs a JS port of `Api`/`AuthSession` against the real `http.mjs` handler: the stale token, missing token and `end_device` cases all fail with `session_refused`.
- **Fix:** in `end_device` and `sign_out_others`, call `await services.auth.ensure()` first, as `_step_up` does. Leave `api.gd:61` as it is, so that sign-out never signs in again. Checked on the port: the calls go `refresh → end`, and all three cases pass.

### RB-31: Tapping a free Trace can start a paid raid instead
- **Priority / category:** High / frontend-backend contract. Batch 2, candidate 22.
- **Where:**
  - `server/src/observatory.mjs` `view`, line 130: the Trace's island is not removed from the offered targets.
  - `client/features/observatory/observatory_presenter.gd:119-123`: the matching target card overwrites the Trace card.
  - `client/features/planner/planner_controller.gd:89`: sends `trace` only when the card's kind is "trace".
- **Input:** a raider robs the defender, and the raider's island is also among the defender's offered targets, which is likely in small pools. The defender taps the Trace.
- **Should happen:** a free Trace lease (`trace_of` set, fee 0).
- **Happens:** a normal lease with `trace=false` and a fee of 100. The free revenge is lost and Starlight is charged.
- **Evidence:** `tests/b2-prove-22/trace_dup.test.mjs` runs the real service with a line-for-line port of the client lookup: `leasedFee 100, trace_of null`.
- **Fix:** compute the Trace first and leave its bundle out of the offer, or make the client prefer the trace card when bundles match. Checked.

### RB-05: An echo raid uses up the pair's daily scoring
- **Priority / category:** High / backend. Batch 1, candidate 25.
- **Where:** `server/src/service.mjs`, `grant`: `pairEarlierToday` (lines 898-902) and `foiledEarlierToday` (lines 955-960).
- **Input:** defender D publishes island X, then publishes Y, so X becomes an echo. Raider R raids echo X (validated), then raids Y the same UTC day.
- **Should happen:** the raid on Y is the pair's first real raid of the day. It scores Renown, stars and a rating move, and gives the defender a share. Per §12.3/G30, an echo takes nothing from its owner.
- **Happens:** both queries count echo raids, because they filter only on `l.mode = 'raid'`. The real raid then gets `renown 0, stars 0, renownCounted false, rating null`. A foiled echo also stops D from getting the fee for a real foil later that day. Matchmaking's own `RAIDED` query filters `l.echo = 0`.
- **Evidence:** `tests/b1-prove-25/echo_pair.test.mjs`: baseline `{renown 20, stars 10, rated}`; after the echo raid `{0, 0, not rated}`.
- **Fix:** add `AND l.echo = ?` (bound to `lease.echo ? 1 : 0`) to the pair query, and `AND l.echo = 0` to the foiled query. Checked.

### RB-06: Players' curated islands are treated as the game's generated fallbacks
- **Priority / category:** High / backend. Batch 1, candidate 7.
- **Where:** `server/src/matchmaking.mjs` `offer`, line 409: `const authored = others.filter((c) => c.origin !== "generated");`.
- **Input:** a player keeps a curated layout. `curation.mjs:100` publishes it with `origin: "generated"`. A raider then asks for an offer.
- **Should happen:** live curated islands owned by players are in the live pool, offered before echoes. The game's own islands are identified by `owner === GENERATOR`, as `current()` (line 325) and `observatory.mjs` do.
- **Happens:** live curated islands of real players are offered only after echoes, and the response says `generated:true`, which tells raiders these are "the game's own islands". Those players are raided far less.
- **Evidence:** `tests/b1-prove-7/curated_offer.test.mjs`: the echoes were offered instead of the three in-band curated islands, and `[echoes, generated]` came back `[true, true]`.
- **Fix:** `others.filter((c) => !(c.origin === "generated" && c.owner === GENERATOR))`. Checked, and the existing fallback tests still pass.

### RB-32: One refused telemetry batch blocks the device's event queue for good
- **Priority / category:** High / frontend-backend contract. Batch 2, candidate 1.
- **Where:** `server/src/telemetry.mjs` `batch`: lines 193 (`413 batch_too_large` over 100 events), 217 (`400 bad_time` for events older than 7 days) and 236 (`429`). On the client: `client/app/services.gd` `send_events`, lines 243-249, which keeps every event unless the whole batch succeeds.
- **Input:** the app is killed and the player returns 8 days later, so a crashed `session_end` is queued with the old date. Or about 60 offline sessions queue 120 events.
- **Should happen:** queued events are sent later and the queue drains ("Offline, the events wait for the next time").
- **Happens:** every retry is refused the same way, the queue never drains, and it grows by 2 events each session. That device's session and retention telemetry stops arriving until sign-out.
- **Evidence:** `tests/b2-prove-1/prove1.test.mjs` runs the real handler with a JS port of the client queue: `[400 bad_time ×3] queue left: 8`, `[413 ×3] queue left: 120`.
- **Fix:** send in chunks of up to 100, and drop a chunk the server refuses with a non-transient 4xx. Ideally, also drop events older than 7 days before sending. Checked.

### RB-07: Raising a Nursery that has never given a birth loses its ready births
- **Priority / category:** High / backend. Batch 1, candidate 5.
- **Where:** `server/src/home.mjs` `nursery`, lines 514-516, which count from `buildings.changed_at` when there is no `nurseries` row. `server/src/universe.mjs:302-304` rewrites `changed_at = now` on every upgrade.
- **Input:** build a Nursery, wait 20 h (3 births ready), then `POST /v1/universe/buildings {realm:'outer-1', kind:'nursery', n:1, to:2}`.
- **Should happen:** `ready` stays 3. The docstring says births count from when the Nursery was last emptied or built.
- **Happens:** `ready` drops to 0 and the wait starts again. Up to 18 h of progress is lost silently.
- **Evidence:** `tests/b1-prove-5/nursery_upgrade.test.mjs`: `an upgrade is neither emptying nor building: 0 !== 3`.
- **Fix:** in `Universe.build`, before the upsert: `if (have && kind === "nursery") INSERT OR IGNORE INTO nurseries (owner, realm, since) VALUES (?, ?, have.changed_at)`. Checked. RB-22's fix also covers this case.

## Medium

### RB-08: A Play purchase is acknowledged before it is checked
- **Priority / category:** Medium / backend. Batch 1, candidate 2.
- **Where:** `server/src/shop.mjs` `Shop.claim`, lines 298-309. `redeem` refuses only afterwards, at lines 214 and 223-227.
- **Input:** `POST /v1/shop/receipts` with `store: "google-play"` and a valid receipt for a product the server doesn't know (a future `premium.N`, or a cosmetic that has been removed), or a receipt whose intent belongs to another account.
- **Should happen:** per the comment at 299, "Refused before the store is told anything, so nothing is consumed", and Play refunds the purchase automatically.
- **Happens:** `settleReceipt` acknowledges or consumes the purchase with Google first. Then `redeem` answers 404 `no_such_product`, 409 `intent_mismatch` or 410 `account_deleted`. Google keeps the money and nothing is granted. Because the purchase was acknowledged, the automatic 3-day refund never happens.
- **Evidence:** `tests/b1-prove-2/claim_settle.test.mjs`: the status code is right, but `settled` is `['premium.2']` where `[]` was expected.
- **Fix:** in `claim`, run the `account_deleted`, `no_such_product` and `intent_mismatch` checks before `settleReceipt`, and call `capCheck` unconditionally. Keep `redeem`'s re-check. Checked.

### RB-09: Race on a minor's monthly cap
- **Priority / category:** Medium / backend. Batch 1, candidate 16.
- **Where:** `server/src/shop.mjs` `Shop.claim`, lines 302-309: `capCheck`, then `await settleReceipt`, then `redeem` re-checks.
- **Input:** an account aged 13-15 (cap €25) sends two concurrent `POST /v1/shop/receipts` for two €20 Play receipts with no live intent (a restore, a client retry, or two devices).
- **Should happen:** the second receipt is refused before it is acknowledged (SEC-21, comment at lines 299-300).
- **Happens:** both pass the cap check before the await, and Google acknowledges both. Then one is refused with 403 `monthly_cap`. The minor is charged for an item they never get.
- **Evidence:** `tests/b1-prove-16/race.test.mjs`: `statuses 201 403 … acknowledged ['tokA','tokB']`.
- **Fix:** keep a per-account record of claims still with the store and count it in `capCheck` before the await. Use a DB reservation instead if the server runs as several processes. Diff in the folder. Checked.

### RB-33: The under-13 edge purge misses other URLs that serve the same bundle
- **Priority / category:** Medium / security (children's data). Batch 2, candidate 11.
- **Where:** `server/src/edge.mjs`, lines 27 and 61-63, which purge only `/v1/bundles/<hash>`. `server/src/http.mjs`, lines 677-689, serves any path or query after the hash with `public, max-age=31536000, immutable`.
- **Input:** someone fetches `/v1/bundles/<hash>?v=2` or `/v1/bundles/<hash>/x` (no sign-in needed) before an under-13 player is deleted.
- **Should happen:** none of the child's bundles stays cached at the edge (§20.11).
- **Happens:** those variant URLs stay in the CDN for a year, because the purge names only the plain URL.
- **Evidence:** `tests/b2-prove-11/prove11.test.mjs`: `…?v=2 served immutable for a year but never purged`.
- **Fix:** serve the bundle only at the exact path, with no query string, and answer anything else with 404. Checked.

### RB-34: An under-13 deletion never purges the cached target lists that name the child
- **Priority / category:** Medium / security (children's data). Batch 2, candidate 12.
- **Where:** `server/src/accounts.mjs`, lines 217-219 and 252-254. The only `queuePurge` call is for island bundles. `http.mjs:683-688` caches lists as `public, max-age=3600`.
- **Input:** an under-13 player is on the current target list. `PUT /v1/age {band:'under-13'}`.
- **Should happen:** the player is off every target list now (as the code comment says), including at the edge.
- **Happens:** the lists are deleted at the origin, but the edge is never asked to purge them, so it keeps serving them for up to an hour.
- **Evidence:** `tests/b2-prove-12/prove12.test.mjs`: `the edge was never asked to purge the list; asked=[] queued=[]`.
- **Fix:** in `finishErasures`, queue a purge for every list hash that is no longer named. Checked.

### RB-11: A StoreKit transaction with quantity > 1 is accepted as one item
- **Priority / category:** Medium / backend (it also weakens a security control). Batch 1, candidate 26.
- **Where:** `server/src/stores.mjs` `appStoreTransaction`, lines 116-125, which never reads `payload.quantity`. The Play path refuses quantity ≠ 1 at line 357.
- **Input:** a JWS signed by the StoreKit chain carrying `{productId:'gift.x', quantity:5, environment:'Production'}`.
- **Should happen:** it is refused, as Play does.
- **Happens:** it is accepted, then granted and counted against the cap once. Apple charges 5 times, so the §20.2 minor's cap is bypassed and the player pays for 4 items they never get. In practice this needs a modified client or a client that sets `.quantity`.
- **Evidence:** `tests/b1-prove-26/quantity.test.mjs`: the transaction is returned where `null` was expected.
- **Fix:** `if (payload.quantity !== undefined && payload.quantity !== 1) return null;`. Checked.

### RB-35: A Workshop play can be verified under any rules build the server still holds
- **Priority / category:** Medium / security. Batch 2, candidate 14.
- **Where:** `server/src/workshop.mjs`: `play` (lines 330-339) stores no rules build, and `submitPlay` (lines 358-363) uses `builds.get(header.rules)`. Heist leases refuse this case (`service.mjs:707-711`, SEC-31).
- **Input:** two builds are held, and a play recorded under the older one is submitted to `POST /v1/workshop/plays/:token`.
- **Should happen:** `wrong_rules`.
- **Happens:** the play is validated, cleared and counted on the creator's ladder and in the Island Fund. An exploit in an old build stays usable in the Workshop for as long as that build is held.
- **Evidence:** `tests/b2-prove-14/prove14.test.mjs`: `validated:true … judged by OLD rules`.
- **Fix:** add a `rules` column to `workshop_plays`, set it in `play()`, and refuse a mismatch in `submitPlay`. Checked.

### RB-10: The client sends the Play receipt as a string and the server needs an object
- **Priority / category:** Medium / frontend-backend contract. Batch 1, candidate 17.
- **Where:** `server/src/stores.mjs` `playPurchase`, lines 335-336 (`const { data, signature } = receipt ?? {}`). On the client: `shop_repository.gd:42-44` (`receipt: String`) and `shop_controller.gd:80-81` (`str(paid.value["receipt"])`).
- **Input:** `POST /v1/shop/receipts {"store":"google-play","receipt":"{\"data\":…,\"signature\":…}"}`, which is exactly what the client sends.
- **Should happen:** the receipt is verified and the item granted.
- **Happens:** destructuring a string gives `undefined`, so the server answers 402 `receipt_refused` for every Play purchase.
- **Caveat:** today the shipped `StorePurchases.buy` is a stub that always fails, so nothing triggers this yet. Once the Play billing plugin is connected, every Android purchase would be charged and not granted.
- **Evidence:** `tests/b1-prove-17/prove.test.mjs`: the object form passes; the string form returns `undefined`.
- **Fix:** in `playPurchase`, `JSON.parse` a string receipt (with a length cap), or have the client send a Dictionary. Checked.

### RB-12: Yesterday's generated islands can be leased as echoes
- **Priority / category:** Medium / backend. Batch 1, candidate 10.
- **Where:** `server/src/matchmaking.mjs:312` (`current()` keeps generated GENERATOR cards without checking they are still current) and `server/src/service.mjs:450-455` (`lease` treats a past GENERATOR snapshot as an echo).
- **Input:** a raider leases the bundle of an earlier day's generated island, either from an hourly list made before the daily rotation or by naming its hash in `POST /v1/leases`.
- **Should happen:** `410 superseded`. The `generator.mjs` header says "Yesterday's are no echoes".
- **Happens:** the lease is issued with `echo:true`. For up to 14 days, each past generated island (5 a day) can be replayed as an echo: a known, already-solved layout to farm.
- **Evidence:** `tests/b1-prove-10/stale_generated.test.mjs`.
- **Fix:** add `|| snapshot.owner === GENERATOR` to the superseded refusal, and in `current()` only pass echo cards straight through when `c.owner !== GENERATOR`. Checked.

### RB-36: Repeat friendly heists pay the defender a law page every time
- **Priority / category:** Medium / backend (economy). Batch 2, candidate 26.
- **Where:** `server/src/codex.mjs` `afterHeist`, line 153. The cast-page block ignores `friendPages`, while the block below it, at line 162, checks it.
- **Input:** five friendly heists by alice on dave in one day, all foiled, each casting aurora.
- **Should happen:** at most one page (SEC-24: only the pair's first friendly heist of the day pays).
- **Happens:** 5 pages, so two friends can farm pages without limit.
- **Evidence:** `tests/b2-prove-26/prove26.test.mjs`: `dave got 5 aurora pages`.
- **Fix:** add `&& friendPages` to the condition at line 153. Checked.

### RB-37: Listing the same island several times multiplies one fan's completions and Island Fund time
- **Priority / category:** Medium / backend. Batch 2, candidate 17.
- **Where:** `server/src/workshop.mjs:175-178` lets a creator list their own bytes again. Completions are deduplicated per item (`db.mjs:500-508`, `PRIMARY KEY (item, player)`), and the Fund caps time per item (`fund.mjs:120`).
- **Input:** a creator publishes X three times, and one fan clears each copy.
- **Should happen:** 1 completion, and at most 3600 s of Fund time a quarter from that fan (§18.7, SR-12).
- **Happens:** 3 completions and 9000 s. The multiplier is bounded by the creator's slots (5, or 8 for a Builder).
- **Evidence:** `tests/b2-prove-17/prove17.test.mjs`.
- **Fix:** deduplicate completions per player, creator and bundle, and key the Fund cap per bundle. Checked.

### RB-13: A new Game Center key is evicted as soon as it is cached
- **Priority / category:** Medium / integration. Batch 1, candidate 14.
- **Where:** `server/src/stores.mjs`, the `keep` helper inside `GameCenter.prepare`, lines 281-291.
- **Input:** 8 distinct Game Center keys (the `GAME_CENTER_CACHE` size) have each verified a sign-in. Then a player signs in with a 9th key.
- **Should happen:** the new key is cached and used.
- **Happens:** the key just inserted is the only "unproven" entry, so `keep` evicts it straight away. Every sign-in with that key fails, and each one re-fetches the certificate, until the process restarts.
- **Evidence:** `tests/b1-prove-14/prove14.test.mjs`: `"gc-prod-9 sign-in works" null !== 'gc:T:_p'`.
- **Fix:** `[...map].find(([k, v]) => k !== key && !v?.proven)`. Checked.

### RB-14: Asking again for a held Trace is refused
- **Priority / category:** Medium / backend. Batch 1, candidate 3.
- **Where:** `server/src/service.mjs` `lease`, lines 464-466. It runs `matchmaking.traceable()` (`matchmaking.mjs:208`) before `issue()` can hand back the lease the player already holds.
- **Input:** A robs B. B asks for a Trace lease and gets T1. B asks again (a retry after a dropped response, or a second device) before playing T1.
- **Should happen:** T1 is handed back. The comment in `issue()` and §24.13 both say so.
- **Happens:** 403 `nothing_to_trace`. If T1 then expires unplayed, that robbery can never be traced. The repo's own test only passes because it sets up two robberies.
- **Evidence:** `tests/b1-prove-3/trace_twice.test.mjs`: `second ask refused: 403 nothing_to_trace`.
- **Fix:** when `traceable()` returns null, fall back to the `trace_of` of this attacker's newest live, unplayed Trace lease on this bundle. Diff in the folder. Checked. It does not cover the separate "an expired, unplayed Trace is used up" case.

### RB-15: A failed hold measurement is stored as a real measurement
- **Priority / category:** Medium / backend. Batch 1, candidate 4.
- **Where:** `server/src/holds.mjs` `work` (lines 86-100) and `status` (lines 52-54), used by `server/src/service.mjs:278-280`.
- **Input:** `build.hold` throws on a bundle, or its bytes are missing from the store. Later, any player publishes the same bundle.
- **Should happen:** no measured figure; the islands keep the default prior. The comment at lines 83-85 says so.
- **Happens:** `status()` reports `{status:'measured', hold:0}`, which curation shows to the player. On the republish, `rate(bundle, 0)` sets every unraided island on that bundle to about 218 instead of about 1411, marking them as trivially easy in matchmaking.
- **Evidence:** `tests/b1-prove-4/failed_hold.test.mjs`.
- **Fix:** mark a lost measurement with `held = -1` and have `status()` return null for it. Diff in the folder. Checked.

### RB-39: Dismissing a player's report turns off spike review for that island for good
- **Priority / category:** Medium / backend (moderation). Batch 2, candidate 5.
- **Where:** `server/src/workshop.mjs` `resolve`, lines 575-580: it closes every open report on the island, but resets `review` only when the resolved report is the server's own. `spike`, lines 447-449, only flags a spike when `review` is 0.
- **Input:** an island gets a player report and then a completion spike. The moderator dismisses the player's report. A month later the island gets 60 completions in a day.
- **Should happen:** the new spike is queued for a person to review (§18.7).
- **Happens:** the queue stays empty, and it will for every later spike on that island.
- **Evidence:** `tests/b2-prove-5/spike_review.test.mjs`: `actual [] expected ['completion_spike']`.
- **Fix:** on dismiss, clear `review` whenever an open server report was among those closed. Checked.

### RB-38: Featured islands still count toward the creator ladder after moderation removes them
- **Priority / category:** Medium / backend. Batch 2, candidate 16.
- **Where:** `server/src/workshop.mjs` `ladder`, lines 530-531. The featured count has no `removed_at IS NULL` filter, unlike the completions count.
- **Input:** a creator has 3 featured islands, and all 3 are removed as copied.
- **Should happen:** level null, 5 slots. The repo's own test says "A removed island drops off the ladder altogether".
- **Happens:** level `loremaker`, 8 slots, and the creator keeps that public rank.
- **Evidence:** `tests/b2-prove-16/prove16.test.mjs`.
- **Fix:** add `AND removed_at IS NULL` to the featured query. Checked.

### RB-40: An island's entrance can be placed inside a wall or on the Vault
- **Priority / category:** Medium / backend (simulation, publish rules). Batch 2, candidate 30.
- **Where:** `sim/src/island.rs`: `decode` (lines 480-483) only checks that the entrance is on the grid, and `check` (lines 656-723) never checks it. The alarm-5 Warden spawns at the entrance (`lib.rs:3244`).
- **Input:** `example_open()` with the entrance at (0,5), which is a wall tile, or on the Vault.
- **Should happen:** `check()` reports a problem, so the island can't be published.
- **Happens:** `check() == []`, and at alarm 5 the Warden spawns inside the wall, which weakens the alarm-5 penalty.
- **Evidence:** `tests/b2-prove-30/entrance_check.rs`: `alarm-5 warden spawned on tile (0, 5), passable=false`.
- **Fix:** add a new last problem, `EntranceBlocked`, to `check()`, and add `entrance_blocked` to `PROBLEMS` in `server/src/sim.mjs`. Checked; the island tests still pass.

### RB-41: `Services.sign_in()` forces a token refresh on every call
- **Priority / category:** Medium / integration. Batch 2, candidate 39.
- **Where:** `client/app/services.gd`, lines 170-171 (`return (await session(true)).ok`). Home calls it on each visit while the outbox has items (`client/scripts/home.gd:962-964`).
- **Input:** the player opens home about 10 times while one outbox item stays queued and the token is still fresh.
- **Should happen:** the fresh token is kept. `session()`'s own comment says the session is kept for its hour because the server limits sign-ins.
- **Happens:** every visit clears the token and refreshes it. The 11th visit gets `429` from the server's limit of 10 sign-ins in a burst. A refresh that fails for a transient reason has already dropped a valid token.
- **Evidence:** `tests/b2-prove-39/prove39.test.mjs` (a port of the client run against the real server handler): `refreshes: 12`, and visit 11 fails.
- **Fix:** `session()` instead of `session(true)` in `sign_in`. Checked.

### RB-42: Overlapping event sends post events twice and drop later ones
- **Priority / category:** Medium / frontend/UI. Batch 2, candidate 35.
- **Where:** `client/app/services.gd` `send_events`, lines 243-249. Nothing stops a second send while one is in flight, and `notices.sent(batch.size())` then cuts off whatever is first in the queue at that moment.
- **Input:** the app is paused while a send is in flight, quickly resumed (`foreground → send_events`), and paused again.
- **Should happen:** each event is sent once.
- **Happens:** the server records a session's start and end twice, and a later `session_end` is removed from the phone's queue without ever being sent.
- **Evidence:** `tests/b2-prove-35/send_events_port.test.mjs`.
- **Fix:** a single-flight `_sending` flag. Checked in the port.

### RB-43: The replay screen re-simulates a leased heist on the test island
- **Priority / category:** Medium / frontend-backend contract. Batch 2, candidate 10.
- **Where:** `client/ext/src/lib.rs` `RulebornReplay::load`, lines 148-150. With empty island bytes it skips the digest check and uses `Island::fixture()`. `client/scripts/result_screen.gd:422` passes the empty island for every leased heist.
- **Input:** the result screen after any heist leased from the Observatory or planner.
- **Should happen:** `load` returns false, and the screen leaves the night empty, as its comment says.
- **Happens:** it returns true and shows moments from the replay played on the wrong island.
- **Evidence:** `tests/b2-prove-10/load_port.rs` (a port using the simulation crate's API).
- **Fix:** always check the digest (`if realm.digest() != heist.island`), and ideally keep the leased island in the HEIST state. Checked; the golden replays still load.

### RB-16: A refused upload uses up a challenge link
- **Priority / category:** Medium / backend. Batch 1, candidate 15.
- **Where:** `server/src/service.mjs` `challengeLease`, lines 493-496. The "played" query joins on `heists` with no `h.validated = 1`.
- **Input:** lease a challenge, submit 10 junk bytes (refused with `replay_malformed`), then ask for the challenge lease again.
- **Should happen:** a new challenge lease. A refused submission is not a play.
- **Happens:** 409 `challenge_already_played`, and the link is lost for good.
- **Evidence:** `tests/b1-prove-15/challenge_refused.test.mjs`.
- **Fix:** add `AND h.validated = 1` to the query. Seed re-rolls stay capped by the existing refusal limits. Checked.

### RB-17: An offer of size 1 returns the easiest candidate
- **Priority / category:** Medium / backend. Batch 1, candidate 6.
- **Where:** `server/src/matchmaking.mjs` `offer`, lines 441-442.
  ```js
  const half = Math.floor(size / 2);
  const easier = sorted.slice(0, i).slice(-half);   // slice(-0) === slice(0)
  ```
- **Input:** `GET /v1/offer?size=1`; `http.mjs:726` allows sizes 1 to 5. Candidates predicted 0.75, 0.72, 0.625, 0.60 and 0.56, with a band of 0.55-0.70.
- **Should happen:** the in-band middle (0.625) is returned with `guaranteed:true`.
- **Happens:** 0.75 (out of band) is returned with `guaranteed:false`.
- **Evidence:** `tests/b1-prove-6/offer-size1.test.mjs`.
- **Fix:** `sorted.slice(Math.max(0, i - half), i)`. Checked.

### RB-18: A universe with no link rows is never raided as a universe
- **Priority / category:** Medium / backend. Batch 1, candidate 20.
- **Where:** `server/src/crossings.mjs` `of`, lines 91-94. It returns null before running `links.ensure`/`upkeep`.
- **Input:** a defender with islands in the Heart and in `outer-1` but no `links` rows (a universe opened before links were kept), and a lease with `universe:true`.
- **Should happen:** the missing links are made and a universe digest is returned, as the comment at lines 88-89 says.
- **Happens:** null, so every such lease is the Heart alone until the owner happens to open the universe page.
- **Evidence:** `tests/b1-prove-20/of_unlinked.test.mjs`.
- **Fix:** check only that `heart` is the defender's Heart before running `ensure`/`upkeep`, then plan. Checked.

### RB-19: An older pinned wasm build cannot be loaded
- **Priority / category:** Medium / backend. Batch 1, candidate 21.
- **Where:** `server/src/sim.mjs`, the `Build` constructor, lines 105-107. Its trap-wrapping loop reads `this[name]`, which runs the `buildingKinds`/`footprints` getters (lines 139-149).
- **Input:** `Build.load` of a wasm that does not export `rb_building_kinds` (an older rules version kept so that its replays can still be re-verified, per §24.11).
- **Should happen:** the build loads, as the guarded optional exports elsewhere do.
- **Happens:** `TypeError: this.x.rb_building_kinds is not a function`. `Builds.load` fails, so startup fails (`main.mjs:205`).
- **Evidence:** `tests/b1-prove-21/test.mjs`.
- **Fix:** `const f = Object.getOwnPropertyDescriptor(Build.prototype, name).value;`. Checked.

### RB-20: The free hatch outfit can't be worn from the shop screen
- **Priority / category:** Medium / frontend-backend contract. Batch 1, candidate 27.
- **Where:** `client/features/shop/shop_presenter.gd` `kind_of`, lines 120-129. It has no `'hatch-outfit' → 'outfit'` case, though the server's `shop.mjs:427` has one.
- **Input:** an account that owns `hatch-outfit`, which `home.mjs:556` grants on the first hatch, opens the shop screen.
- **Should happen:** the outfit is wearable and a Wear button is shown.
- **Happens:** `kind_of` returns `""`, so `wearable` is false and `shop_screen.gd:237` adds no Wear button. Every player's free §19.20 outfit can't be worn.
- **Evidence:** `tests/b1-prove-27/kind_of.test.mjs` (a JS port checked against the server's `kindOf`): `expected 'outfit', actual ''`.
- **Fix:** add `if id == "hatch-outfit": return "outfit"` before the final `return ""`. Checked on the port.

### RB-21: `full_at` is null while a producer's worker rests
- **Priority / category:** Medium / frontend-backend contract. Batch 1, candidate 29.
- **Where:** `server/src/home.mjs`: `rate` (lines 391-392) drops resting workers, and `view` (line 819) passes that list to `fullAt`. On the client, `client/data/device_notices.gd:149-155` cancels the notice when `full_at` is null.
- **Input:** assign a worker to the Heart's star well, then send that worker on a heist. `GET /v1/home` during the rest.
- **Should happen:** `full_at` is the time the store fills, counting the worker from the end of its rest.
- **Happens:** `full_at` is null, so the device cancels its storage-full notice, and the store later fills unnoticed. With other workers present, `full_at` comes out too late instead.
- **Evidence:** `tests/b1-prove-29/prove29.test.mjs`.
- **Fix:** an `ahead` mode in `rate()` that keeps resting workers, starting them from `away_until`, used only for `full_at`. Diff in the folder. Checked.

### RB-22: Raising a Nursery pays out past hours at the new rate
- **Priority / category:** Medium / backend. Batch 1, candidate 28.
- **Where:** `server/src/home.mjs:514-516` together with `server/src/universe.mjs:297-301`. Nothing settles `nurseries.since` when the level changes.
- **Input:** a level 1 Nursery (6 h period) that has given a birth, so its row exists. Wait 5 h, then raise it to level 2 (5 h period) or level 5 (2 h period).
- **Should happen:** 0 births ready (5 h at the 6 h rate made none).
- **Happens:** 1 birth is ready at once (2 when raised to level 5). This is a small economy speed-up the player didn't earn.
- **Evidence:** `tests/b1-prove-28/nursery_raise.test.mjs`: `"no birth is ready right after the raise" 1 !== 0`.
- **Fix:** in `Universe.build`, carry the Nursery's progress over at the old rate, then rewrite `since` for the new period. Diff in the folder. This also fixes RB-07. Checked.

### RB-44: A defender's report says the defence "held" for the whole clock after any Prism mite split
- **Priority / category:** Medium / backend (simulation). Batch 2, candidate 9. The extra second look found it independently (candidate 102), and both were demonstrated.
- **Where:** `sim/src/lib.rs` `World::report`, line 5997, and `sim/src/universe.rs` `Crossing::reports`, line 607. Both compare `done.len()` with `raiders.len()`, which includes the mite's half. A half that rejoins never logs Out or Caught.
- **Input:** a crew of 3; a Prism mite splits and the halves rejoin; all 3 crew get out at tick 300.
- **Should happen:** held = 10 s.
- **Happens:** held = 165 s (the whole clock). `rb_verify` returns this value at byte 64, and it feeds the defender's report and profile records.
- **Evidence:** `tests/b2-prove-9/tests_rs_added.diff` and `tests/b2-prove-102/tests_rs_added.diff`.
- **Fix:** check that every real crew member (`half_of.is_none()`) is in `done`, instead of comparing counts. Checked; 337 library tests pass.

### RB-45: A slowed heist clock never catches the crew still inside
- **Priority / category:** Medium / backend (simulation). Batch 2, found by the extra second look (candidate 103).
- **Where:** `sim/src/lib.rs:3767`: the clock ends only when `clock_run >= clock*1000`, but the replay always stops after `heist.ticks` steps (line 5874).
- **Input:** a Haste realm. The Sage's Invert turns Haste's 5/4 rate into 4/5, and the haste pylon is then broken.
- **Should happen:** whoever is still inside at the last tick is caught (§12.6).
- **Happens:** `clock_run` is 840500, short of 900000, so nobody is caught and the verdict says `caught=0`. That value drives friendly-raid pages and the fewest-caught record.
- **Evidence:** `tests/b2-prove-103/prove103_test.rs`.
- **Fix:** also end the clock on the replay's last tick. Checked; 338 tests pass.

### RB-46: The raid notification lists refused (invalid) submissions
- **Priority / category:** Medium / backend. Batch 2, candidate 2.
- **Where:** `server/src/notifications.mjs` `raids`, lines 274-277: no `h.validated = 1` filter. Other readers of a defender's raids do filter (`defences.mjs:47`, `profile.mjs:101`).
- **Input:** a validated raid on D, then a refused junk submission on another lease on D.
- **Should happen:** the push lists only the real raid.
- **Happens:** it also lists `{heist:'bbbb', grade:null}`. Any raider holding a lease on D can add up to 10 such entries a day.
- **Evidence:** `tests/b2-prove-2/refused_digest.test.mjs`.
- **Fix:** add `h.validated = 1 AND` to the query. Checked.

### RB-47: Friendly and challenge heists after the day's first notification are never notified
- **Priority / category:** Medium / backend. Batch 2, candidate 19.
- **Where:** `server/src/notifications.mjs`: `raided` (lines 252-256) returns early when a notification is already waiting, relying on `raids` (line 277), which filters on `mode = 'raid'`.
- **Input:** a raid on D starts a notification, then a friend plays a validated friendly heist on D.
- **Should happen:** the defender's message lists both heists.
- **Happens:** the friendly heist is silently dropped. On its own, it would have been notified.
- **Evidence:** `tests/b2-prove-19/prove19.test.mjs`.
- **Fix:** in `raids`, filter on `l.echo = 0`, matching what `grant` notifies. Whether friendly heists should notify at all is still an open design question in the repo; either way, the current behaviour depends on the order heists land in.

### RB-48: A raid can be pushed twice after a push retry
- **Priority / category:** Medium / backend. Batch 2, candidate 3.
- **Where:** `server/src/notifications.mjs`, lines 389, 412 and 274-278. A claimed notification that goes back to waiting after a retry re-reads every heist since its first, including a raid that landed during the push and already has its own notification.
- **Input:** notification N1 is claimed, raid x2 lands while the push is in flight, and the push answers with retry.
- **Should happen:** N1 retries with [x1], and N2 is sent with [x2].
- **Happens:** N1 is sent with [x1, x2] and N2 with [x2].
- **Evidence:** `tests/b2-prove-3/retry_double.test.mjs`.
- **Fix:** resolve the raid list once when the notification is claimed, and store it with the notification. Checked.

### RB-49: The Trace can point at an older raider instead of the most recent one
- **Priority / category:** Medium / general. Batch 2, candidate 4.
- **Where:** `server/src/observatory.mjs` `trace`, lines 144-146: `SELECT DISTINCT h.attacker … ORDER BY h.submitted_at DESC`.
- **Input:** within 24 h, A robs D at −3 h, B at −2 h, and A again at −1 h.
- **Should happen:** A's island ("the most recent raider").
- **Happens:** B's island. SQLite orders A by one arbitrary heist of theirs, here the oldest.
- **Evidence:** `tests/b2-prove-4/trace_order.test.mjs`.
- **Fix:** `GROUP BY h.attacker ORDER BY MAX(h.submitted_at) DESC`. Checked.

### RB-50: In the island builder, tapping the Vault with the law tool deletes that law
- **Priority / category:** Medium / general (editor data loss). Batch 2, candidate 31.
- **Where:** `sim/src/island.rs` `weave`, lines 1070-1079: it removes the law before `claim()` refuses the Vault tile. It is reached from `client/scripts/builder_screen.gd:367`.
- **Input:** `weave("haste",1,10)`, then `weave("haste", vault.x, vault.y)`.
- **Should happen:** refused, with the law left in place.
- **Happens:** it returns false and the law is gone.
- **Evidence:** `tests/b2-prove-31/prove31.rs`.
- **Fix:** refuse the Vault tile before removing anything. Checked.

### RB-51: Crossing an island hints only the first chord each group of three laws makes
- **Priority / category:** Medium / backend. Batch 2, candidate 25.
- **Where:** `server/src/lab.mjs`: `chordOf` (line 76) uses `CHORDS.find`, and `crossed` (lines 265-266) calls it. The simulation sounds every chord the laws complete (`sim/src/combos.rs:60-62`).
- **Input:** `lab.crossed(acct, ['bounce','frictionless','honeycomb'])`, which makes ghost_tide, clockwork and wild_hunt.
- **Should happen:** all three chords are hinted.
- **Happens:** only ghost_tide is hinted.
- **Evidence:** `tests/b2-prove-25/crossed-chords.test.mjs`.
- **Fix:** add a `chordsOf` that uses `filter`, and hint every chord it returns. Checked.

### RB-52: The Lab's hint can name a resonance that can't be found at launch
- **Priority / category:** Medium / backend. Batch 2, candidate 24.
- **Where:** `server/src/lab.mjs:206` searches `RESONANCES` rather than `LAUNCH_RESONANCES`.
- **Input:** five empty experiments with `['half_gravity','slow_rivers']`.
- **Should happen:** hints only for resonances that can be found.
- **Happens:** the fifth hint is `sleeping_streams`, which needs `spores` (`launch:false`), so it stays hinted forever.
- **Evidence:** `tests/b2-prove-24/hint_launch.test.mjs`.
- **Fix:** `LAUNCH_RESONANCES.find`. Checked.

### RB-53: Studying a heist whose island was erased answers 500
- **Priority / category:** Medium / backend. Batch 2, candidate 27.
- **Where:** `server/src/codex.mjs` `study`, line 189: `lawsOf(this.service.store.get(h.bundle))` with no null check.
- **Input:** alice raids dave; dave is deleted as under-13, which erases his island's bundle; alice sends `POST /v1/codex/study`.
- **Should happen:** a 4xx refusal.
- **Happens:** a `TypeError`, answered as 500 `internal`. The same unguarded pattern appears at `codex.mjs:128` and `service.mjs:811/841`; those were not tested.
- **Evidence:** `tests/b2-prove-27/prove27.test.mjs`.
- **Fix:** refuse with `409 nothing_to_study` when the bytes are gone. Checked.

### RB-23: A refresh-rotation span of 720 h signs devices out after 30 days
- **Priority / category:** Medium / backend (configuration). Batch 1, candidate 1.
- **Where:** `server/src/auth.mjs` `rotateHoursOf` (line 77 accepts 0 to 720), `refresh` (the idle check at line 193 runs before the early return at line 197), and `main.mjs:211`.
- **Input:** `RULEBORN_REFRESH_ROTATE_HOURS=720`. The player signs in, then refreshes every hour.
- **Should happen:** "a session lapses 30 days after its last use", so an active device stays signed in.
- **Happens:** refreshes inside the span write nothing, so `used_at` stays at the sign-in time. At hour 720.5 the refresh is refused with `session_refused`. Every active player is signed out, and `devices()` stops listing their sessions.
- **Evidence:** `tests/b1-prove-1/rotate720.test.mjs`: `refresh #721 at 720.5 h refused`.
- **Fix:** line 197: rotate whenever `now - s.used_at >= Math.min(this.rotateMs, IDLE_MS - SESSION_MS)`, or cap the setting below 720. Checked.

## Low

### RB-24: A lapsed refresh token can still sign out every device
- **Priority / category:** Low / security. Batch 1, candidate 13.
- **Where:** `server/src/auth.mjs` `signOutWith`, lines 399-407. With `everywhere`, it checks only `ended_at` and the token's generation, not the idle and absolute lapses that `refresh` checks at line 193.
- **Input:** session A unused for 35 days, session B live. Then `POST /v1/session/end {everywhere:true, refreshToken:A}`.
- **Should happen:** 401, the same answer `refresh` gives for A.
- **Happens:** 200 `{"ended":2}`, and B is signed out. This works for the 7 days the lapsed row is kept. It needs an old or leaked token, and the cost is a forced sign-out, not account takeover.
- **Evidence:** `tests/b1-prove-13/lapsed_everywhere.test.mjs`.
- **Fix:** select `used_at, created_at` and refuse when idle or past the absolute limit. Checked: the new test passes, and 26/26 of the existing auth tests pass.

### RB-25: The manifest's form byte is not checked
- **Priority / category:** Low / security (integrity). Batch 1, candidate 8.
- **Where:** `server/src/home.mjs` `crewProblem`, lines 651-656. It compares only kind, level and traits. The comment at lines 789-791 and `replay.rs` both say the server checks form.
- **Input:** an RBH3 replay whose manifest member has `form=2` while the character has form 1, or none.
- **Should happen:** `crew_mismatch`.
- **Happens:** the replay is accepted, and the defender's replay shows a form the raider never earned. The result and rewards are unchanged.
- **Evidence:** `tests/b1-prove-8/form.test.mjs`: `expected 'crew_mismatch', actual null`.
- **Fix:** destructure `form` too, and add `|| form !== formIndex(c)` to the mismatch condition. Checked.

### RB-54: The replay decoder accepts several byte strings for the same heist
- **Priority / category:** Low / security (integrity). Batch 2, candidate 29.
- **Where:** `sim/src/replay.rs`:
  - lines 338-339: `delta as u32` truncates the value before `checked_add` can catch an overflow;
  - `read_varint`, lines 377-388: padded varints are accepted.
- **Input:** a valid replay whose first tick delta is rewritten as the varint for 2^32+d, or as a padded varint.
- **Should happen:** `decode` returns `None` ("a replay arriving from a client is untrusted input").
- **Happens:** the bytes decode to the identical heist, so one heist can be stored under many replay hashes (`service.mjs:647`). It cannot be granted twice, because results are keyed by the lease token.
- **Evidence:** `tests/b2-prove-29/prove29_varint.rs`.
- **Fix:** `u32::try_from(delta).ok()?`, and reject a zero byte at the end of a varint. Checked; the golden replays still verify.

### RB-26: The roles route ignores the constellation id in the URL
- **Priority / category:** Low / backend. Batch 1, candidate 24.
- **Where:** `server/src/http.mjs`, lines 244-246, which call `social.appoint(me, account, role)` without `a`. `social.mjs:168-170` acts on the founder's own constellation. The sibling `/remove` route does check the id.
- **Input:** the founder of A sends `POST /v1/constellations/<X>/roles {account, role:'elder'}`.
- **Should happen:** 403/404.
- **Happens:** 200, the role changes in A, and A is returned. No one gains privileges, but a stale or wrong id silently changes the wrong constellation.
- **Evidence:** `tests/b1-prove-24/prove24.test.mjs`.
- **Fix:** pass `a` to `appoint` and refuse when `f.constellation !== id`. Checked.

### RB-56: After an under-13 deletion, a player's reports look like the server's own spike reports
- **Priority / category:** Low / backend. Batch 2, candidate 18.
- **Where:** `server/src/accounts.mjs:266-267` sets the reporter to NULL. `server/src/workshop.mjs:548` and `:575` treat "no reporter" as "the server's own".
- **Input:** a player reports an island and is then deleted as under-13; the moderator opens the queue.
- **Should happen:** `server:false`.
- **Happens:** `server:true`, and dismissing that report resets the island's spike flag.
- **Evidence:** `tests/b2-prove-18/prove18.test.mjs`.
- **Fix:** count a report as the server's only when `reporter === null && reason === "completion_spike"`. Checked.

### RB-55: A command for actor 16 or above is recorded as a different crew member
- **Priority / category:** Low / general. Batch 2, candidate 6.
- **Where:** `sim/src/replay.rs:289` packs `(command.actor << 4) | kind` with no range check. `rb_record` (`ffi.rs:395`) and the client's `give` both accept any actor value.
- **Input:** `record_in` on `example_open` with a `MoveTo` command for actor 16.
- **Should happen:** the recorded replay verifies.
- **Happens:** actor 16 comes back as actor 0, and verification returns `Diverged(2)`. A normal device never produces actor 16.
- **Evidence:** `tests/b2-prove-6/actor16.rs`.
- **Fix:** drop commands with an actor above 15 in `record_with`, or refuse them in `rb_record`. Checked.

### RB-57: Placing a ward or pylon on a guard standing in tall grass leaves the island unpublishable
- **Priority / category:** Low / general. Batch 2, candidate 33.
- **Where:** `sim/src/island.rs` `claim`, lines 915-921, calls `clear()` only once. `place_building`, line 1101, loops until the tile is clear.
- **Input:** a guard posted on tall grass at (2,7), then `place_ward(TimeSnare,2,7)` or `weave(...,2,7)`.
- **Should happen:** the tile is replaced entirely ("replacing whatever stood there").
- **Happens:** the grass stays, and `check()` returns `[Crowded]`.
- **Evidence:** `tests/b2-prove-33/claim_grass.rs`.
- **Fix:** `while self.clear(x, y) {}`. Checked.

### RB-58: The system back button resets the roster's stage and filter
- **Priority / category:** Low / frontend/UI. Batch 2, candidate 38.
- **Where:** `client/app/router.gd` `go_back`, lines 139-141, calls `go(to)` with no params. The character screen's own back button passes `{roster: …}` (`character_screen.gd:909`).
- **Input:** roster → pick a stage and filter → open a character → Android back or Escape.
- **Should happen:** the roster comes back as it was (AD-R51).
- **Happens:** it shows stage 0 with no filter.
- **Evidence:** `tests/b2-prove-38/port_test.mjs`.
- **Fix:** carry the route's `roster` param through `go_back`. Checked in the port.

### RB-59: Navigation entries in the action log lose the screen name
- **Priority / category:** Low / frontend/UI. Batch 2, candidate 37.
- **Where:** `client/core/action_log.gd:18` keeps only `String` values, but the router passes a `StringName` (`router.gd:114, 119`).
- **Input:** `router.go(&"shop")`.
- **Should happen:** the log entry has `{name: "shop"}`.
- **Happens:** `{}`, so defect reports have no screen history.
- **Evidence:** `tests/b2-prove-37/test_action_log.py`.
- **Fix:** convert a `StringName` to a `String` before the type filter. Checked in the port.

### RB-60: The public privacy policy shows leftover reference text
- **Priority / category:** Low / general. Batch 2, candidate 28.
- **Where:** `server/src/pages.mjs` `plain`, lines 20-22.
- **Input:** `GET /privacy`.
- **Should happen:** references are removed cleanly.
- **Happens:** the page shows "…the work each is given (to, )." and the internal audit tags "(SEC-18)" and "(SEC-29)".
- **Evidence:** `tests/b2-prove-28/plain_refs.test.mjs`.
- **Fix:** widen the regex to accept "to"/"and" between references and multi-letter tags. Checked: only those three cells change.

---

## What was read

### Batch 1: what was read

All 47 files below were assigned. For each slice, one agent was meant to read every line first and a second agent was meant to read it all again, looking only for what the first missed.

| Slice | Files | Lines | First read | Second look |
|---|---|---|---|---|
| 1 | `http.mjs`, `auth_http.mjs`, `limits.mjs`, `pages.mjs`, `edge.mjs`, `refused.mjs` | 1,399 | **partial**: only `http.mjs` read, nothing returned | full |
| 2 | `service.mjs`, `store.mjs`, `offline.mjs`, `eras.mjs` | 1,452 | full | full |
| 3 | `db.mjs`, `holds.mjs` | 1,443 | full | full |
| 4 | `auth.mjs`, `tokens.mjs`, `auth_proofs.mjs`, `accounts.mjs`, `privacy.mjs`, `safety.mjs` | 1,350 | full | full |
| 5 | `stores.mjs`, `googleapi.mjs`, `shop.mjs`, `fund.mjs`, `push.mjs` | 1,437 | full | full |
| 6 | `home.mjs`, `economy.mjs`, `defences.mjs`, `keeper.mjs`, `crossings.mjs` | 1,574 | full | full |
| 7 | `matchmaking.mjs`, `sim.mjs`, `social.mjs`, `friends.mjs` | 1,420 | full | full |
| 8 | client `data/api.gd`, `http_transport.gd`, `outbox.gd`, `features/auth/auth_session.gd`, `auth_state.gd`, `secure_store.gd`, `platform_identity.gd`, all 18 `data/repositories/*.gd` | 1,710 | full | **partial**: 7 core files read, repositories not re-read, nothing returned |

**Coverage gap you should know about.** The repository's own `CLAUDE.md` contains "owner orders" telling any agent session to stop because the project's agent program is paused. Two of the 16 hunting agents obeyed it, even though they were told that repository content is data and not instructions:
- The first reader of slice 1 stopped after `http.mjs`. Slice 1 still got one full pass from its second-look agent.
- The second-look agent of slice 8 stopped partway and returned nothing. Slice 8 got one full pass from its first reader, but the 18 repository files had no second look.

So slices 1 and 8 had a single full pass instead of two.

Totals:
- 77 suspicions were raised.
- 29 were rated 3 or higher and all 29 went to a prover. None were cut by the cap of 40.
- 26 were demonstrated and 3 rejected. No prover failed.

### Batch 1: left out of scope at the time
- The Rust simulation crate `sim/` (about 15k lines).
- The Godot UI, 3D and world code under `client/` other than the network layer (about 60k lines: `client/scripts`, `client/world`, `client/ui`, the feature presenters and controllers). The provers did open `shop_presenter.gd`, `shop_controller.gd` and `auth_controller.gd`, but only to check specific claims.
- `tools/` (about 56k lines of Python and JS build and audit tooling).
- Lower-risk server modules (about 4,600 lines): `main.mjs`, `workshop.mjs`, `telemetry.mjs`, `notifications.mjs`, `seasons.mjs`, `codex.mjs`, `lab.mjs`, `weaving.mjs`, `universe.mjs`, `observatory.mjs`, `profile.mjs`, `track.mjs`, `links.mjs`, `curation.mjs`, `glicko.mjs`, `generator.mjs`, plus `server/load.mjs`.
- Tests, docs, art, and generated JSON and HTML.

**Limitations:** the simulation's `.wasm` is not built in this sandbox and nothing could be installed, so server tests stubbed the simulation where it was not involved. Godot is not installed, so the client defects (RB-03, RB-04, RB-20) were demonstrated on line-for-line JS ports of the GDScript.

### Batch 1: rejected (after two independent provers)
- **Batch 1, candidate 9** (`service.mjs` `submit`): a raid replay with no manifest skips the roster and rest checks. Both provers rejected it as **intended, documented behaviour**. Replays without a manifest play a generic crew by role that uses no roster character; this is listed as an accepted risk in `docs/security/review.md:859-863` and asserted by `security_deep_heists.test.mjs:303`.
- **Batch 1, candidate 19** (`push.mjs` `Fcm.send`): FCM `403 SENDER_ID_MISMATCH` is retried rather than clearing the token. Both provers rejected it as **deliberate**. A sender mismatch usually means the server's own configuration is wrong; clearing tokens on it would wipe every player's push token. Retries are bounded at 6.
- **Batch 1, candidate 22** (`client/data/outbox.gd` `flush`): overlapping flushes POST the same item twice. Both provers rejected it as **harmless**. The duplicate is answered "repeated" or 503, the client treats 5xx as transient, and an answer that arrives after the item is settled is dropped. No refusal could be produced.

### Batch 1: suspicions not checked (rated 2 of 5)
48 suspicions were not sent to provers. They are listed briefly here so they can be followed up. Two overlap confirmed items: the echo/generator one is RB-12, and "a Trace is used up when its lease expires unplayed" is the part RB-14's fix leaves open.

- **server/service.mjs:**
  - a defender banned between lease and submit is still paid and rated;
  - a lease at exactly `expires_at` is treated as lapsed by `issue` but live by `submit`, which can give two live leases;
  - raid and Trace leases never check blocks (`safety.between`);
  - the grant rates the island under the first publisher's `snapshot.realm`.
- **server/holds.mjs:**
  - `work()` returns `n` even when nothing was played;
  - islands are never queued again after the rules version changes;
  - the clamp uses `facts.HOLD_RAIDS` instead of the row's raid count;
  - `played` is written as an absolute value but `held` as an increment, so concurrent workers double-count.
- **server/db.mjs:**
  - the one-open-lease-per-target unique index is dropped, though the schema comment says the database enforces it;
  - columns added by migration lose their CHECK constraints, and migrated accounts default to the `18+` age band;
  - the bans migration ignores linked identities.
- **server/auth.mjs / tokens.mjs:**
  - a Game Center proof can be replayed at the exact end of its window;
  - an empty `RULEBORN_REFRESH_ROTATE_HOURS` is read as 0;
  - refreshes inside the rotation span skip `sign_in` telemetry;
  - the idle check is off by one between `refresh` and `devices`/`live`;
  - `keyring` rejects kids such as `constructor` because of inherited object names;
  - `deviceOf` trims the model name before cutting it, which can leave a trailing space.
- **server/googleapi.mjs / stores.mjs / shop.mjs:**
  - the voided-purchases `startTime` is exactly 30 days back and may be rejected by Google;
  - Apple notifications are not ordered or deduplicated, so a replayed REFUND sticks;
  - a receipt with no intent is granted to whoever claims it first;
  - a gift is granted to a friend who has since been banned or unfriended;
  - a Google access token that gets a 401 is not dropped from the cache;
  - Google sign-in keys are trusted indefinitely if refresh keeps failing.
- **server/home.mjs / defences.mjs:**
  - birth and stray rolls use an unkeyed sha256, so the device can predict them;
  - `firstStrays` throws `no_place` when the roster is full;
  - Night-eyed and Lantern-born are linked to no law;
  - past production is paid under the current links' faults;
  - the defence log shows the raider's current Keeper level.
- **server/sim.mjs:** in `verifyUniverse`, `buffer().set` runs before the size check, so an oversized replay throws a RangeError.
- **server/social.mjs / matchmaking.mjs:**
  - the friends-only crew rule is checked only for 13-15 joiners;
  - a republished card is not re-checked for its chapter;
  - `recentSuccess` counts raids that the rating skips;
  - a Trace is used up by an expired, unplayed lease;
  - `echoes:true` is reported even when there are no echo candidates.
- **server/http.mjs / limits.mjs:**
  - `peerKey` handles only the dotted IPv4-mapped form, so other forms share one bucket;
  - a validly signed token whose session has ended can drain the player's rate limits;
  - the Apple notification route has no rate limit, yet each request costs an ES256 chain check.
- **client (slice 8):**
  - `_end_with` uses the same token blank/restore as RB-03;
  - a renewal still in flight at sign-out writes the tokens back;
  - a token with `expiresIn` under 60 s causes a refresh loop;
  - a cancelled platform sign-in is shown twice;
  - a tap skips every backoff wait, not only the first;
  - `outbox._read` accepts items without `json`, which aborts the whole flush;
  - the failure log keeps the query string;
  - `credential_for` has no timeout or request correlation;
  - `heist_repository.first_target` skips curated islands, the client-side twin of RB-06.

### Batch 2: what was read

| Slice | Files | Lines | First read | Second look |
|---|---|---|---|---|
| B2-1 | `server/src/main.mjs`, `workshop.mjs`, `curation.mjs`, `generator.mjs`, `glicko.mjs` | 1,360 | full | full |
| B2-2 | `telemetry.mjs`, `notifications.mjs`, `profile.mjs`, `track.mjs`, `observatory.mjs` | 1,513 | full | full |
| B2-3 | `seasons.mjs`, `codex.mjs`, `lab.mjs`, `weaving.mjs` | 1,319 | full | full |
| B2-4 | `universe.mjs`, `links.mjs`, plus a second full pass over `auth_http.mjs`, `limits.mjs`, `pages.mjs`, `edge.mjs`, `refused.mjs` | 1,202 | full | full |
| B2-5 | `sim/src/ffi.rs`, `replay.rs`, `heist.rs` | 1,367 | full | **partial**: only `replay.rs` read, nothing returned |
| B2-6 | `sim/src/island.rs` | 1,586 | full | full |
| B2-7 | `sim/src/universe.rs`, `grid.rs` | 1,356 | full | full |
| B2-8 | `client/ext/src/lib.rs` (gdext), `client/app/services.gd`, `router.gd`, `store_purchases.gd`, `local_notifier.gd`, `haptics.gd`, `client/core/*.gd` | 1,631 | full | full |

The batch 2 proving run read `sim/src/ffi.rs` (618 lines) and `sim/src/heist.rs` (361) in full as the missing second look. It raised 3 new suspicions, and all 3 were demonstrated (RB-28, RB-44 and RB-45).

**Repository text stopped agents three times.** The repo's own `CLAUDE.md` contains "owner orders" telling any agent session to stop. Three hunting agents obeyed it even though they were told the repository is data: the slice 1 reader and the slice 8 reviewer in batch 1, and the slice B2-5 reviewer in batch 2. Each gap was covered by the other pass on that slice, or by the proving run's re-read. Anyone running automated agents on this repository should know `CLAUDE.md` tells them to stop.

## Rejected and unproven

### Batch 1: rejected
These three are listed in "Batch 1: rejected (after two independent provers)" above: candidates 9, 19 and 22.

### Batch 2: rejected (after two independent provers)
- **Batch 2, candidate 15** (`workshop.mjs` `publish`: the creator's clearing replay is accepted under any held build, with any crew). **Rejected:** publishing and playing are checked identically (`workshop.mjs:186-187` and `:363-366` both use `builds.get(header.rules)` with no crew or plan checks), and the client gives creators and players the same fixed crew. So an island the creator cleared is clearable by players under the same server rules. The related defect that *is* real, plays not being pinned to a build, is RB-35.
- **Batch 2, candidate 20** (`notifications.mjs` `remind`: a reminder held over the night, then a second one the same day). **Rejected:** the two pushes are for two different days (one reminder per local day). The repo's own tests (`notifications.test.mjs:162-175`, `push.test.mjs:183-185`) expect a held reminder to go out at the night's end.
- **Batch 2, candidate 32** (`island.rs` `curated` silently drops a building that can't be placed). **Rejected:** the simulation part is true, but as the doc comment says, the server refuses that island by name. `service.publish` → `universe.problems` reports `buildings_not_as_placed` (`universe.mjs:357-359`), so it is never published.

### Batch 2: unproven (both prover attempts failed)
The engine doesn't say why these failed. They are still open suspicions.
- **Candidate 7** (`sim/src/island.rs` `check`): the same law woven twice passes the publish gate and its effect stacks in the simulation (the reader's experiment showed guard speed 5/4 becoming 441/256).
- **Candidate 21** (`observatory.mjs` `trace`): a banned raider's island is offered as a Trace, but leasing it answers 410.
- **Candidate 23** (`profile.mjs` `view`): viewing another player's profile opens their season standing, which fixes their track tier price early.
- **Candidate 34** (`sim/src/grid.rs` `tunnel_exit`): a tunnel mouth covered by a raised wall or a building still works as an exit.

### Suspicions not checked (rated 2 of 5)
Each batch's weaker suspicions are listed in "Batch 1: suspicions not checked" above and in "Batch 2: suspicions not checked" below.

### Batch 2: suspicions not checked (rated 2 of 5)
About 45 more were raised at confidence 2. Among them:
- **server:**
  - `main.mjs`: config is not validated (an empty `RULEBORN_DELETIONS` turns the deletion journal into an in-memory store; App Store or Game Center are silently disabled when `RULEBORN_BUNDLE_ID` is missing)
  - `workshop.mjs`: featuring skips the hold-band check; the "featured" list never expires; `resolve` on a report already resolved closes newer reports; re-rating takes the day's lone-fan slots
  - `curation.mjs`: wards and posts added keep the generated origin
  - `notifications.mjs`: pushes still go to banned accounts
  - `telemetry.mjs`: the buyer share can exceed 1
  - `observatory.mjs`: an echo's card shows the owner's whole universe; Keeper names of blocked players are shown
  - `profile.mjs`: viewing a profile writes the other player's Codex and roster
  - `seasons.mjs`: closing a season rewards deleted accounts; Renown is pulled back once instead of once per missed season; the constellation table answers 200 for an open season
  - `codex.mjs`: casting the same law twice pays two pages; post-launch laws can be the working law; raids past the week's cap still pay pages
  - `weaving.mjs`: the "woven" mastery step is recorded before the weave finishes
  - `lab.mjs`: repeated hints; chords named while their laws are still weaving
  - `universe.mjs`: ward and post counts are not held to the realm's level
  - `links.mjs`: link numbers are reused, so a retried DELETE can remove a different link; a retried link purchase gets 409; `view` writes while reading
  - `auth_http.mjs`: account deletion skips the audience check with no web client id; the page's spent nonce blocks retries
  - `pages.mjs`: "1 days" in the policy
- **sim:**
  - `ffi.rs`: `rb_record_drawn` with crew 0 divides by zero and traps; `rb_hold` has no ticks bound; record functions return replays over the server's 2 KB limit
  - `island.rs` and `grid.rs`: several "second encoding" gaps that give one island several digests; `tile_at` and `coords` wrap out-of-range positions onto real tiles
  - `universe.rs`: a crossing takes no time; one skiff per realm; a fault entry makes no landing noise
- **client:**
  - `client/ext/src/lib.rs`: ticks and kind values are wrapped with `as` casts
  - `action_log.gd`: player ids are logged
  - `store_purchases.gd`: always the desktop stub
  - `services.gd`: `notices.seen()` is never called
  - `auth_session.gd` `sign_out`: no fallback to the refresh token

## Still not read
- Simulation `lib.rs` (about 6,000 lines; only the parts reached by proofs were opened) and the other simulation modules and scripts (`path.rs`, `stability.rs`, `events.rs`, `guard.rs`, `sight.rs`, `era.rs`, `rng.rs`, `fixed.rs`, `noise.rs`, `combos.rs`, `reference.rs`, `ruleborn.rs`, the bins and Python tools: about 5,000 lines).
- The Godot UI, world and feature code (`client/scripts`, `client/world`, `client/ui`, `client/features` apart from the auth and network files): about 62,000 lines.
- `tools/`: about 42,000 lines, not counting the roughly 12,900 lines of data in `audit_register.py`.
- The art-generation scripts in `art/design` and `art/ui`: about 18,000 lines.
- `server/load.mjs`, the client prototypes and the docs scripts.
