# Server audit B, November 2026

The second half of the fix wave's server audit
([bug report](../bug-report-2026-11.md), task FX2-6-audit-server-b). The
audit read `main.mjs`'s configuration, `auth_http.mjs`, `auth_proofs.mjs`,
`tokens.mjs`, `privacy.mjs`, `refused.mjs`, `store.mjs`, `googleapi.mjs`,
`social.mjs`, `profile.mjs`, `observatory.mjs`, `notifications.mjs`,
`telemetry.mjs`, `pages.mjs` and `server/load.mjs`. It also followed the
report's server suspicions for these modules into the code they call.

Entries use the report's format and priority levels. Every confirmed entry
has a proof under `server/test/fix_fx2_audit_*.test.mjs`, committed in
1080f1f9 before any fix and run on main's code.

## How the open proofs run

Some findings are proven but not fixed here, because their code is outside
this task's files. Their proofs run inside `stillOpen(id, proof)`
(`server/test/fix_fx2_open.mjs`), on every test run, and nothing is skipped.

- `proof` asserts what the design asks for, so it fails on main.
- The wrapper passes while the proof fails with an assertion error, and
  rethrows any other error.
- Once the finding is fixed, the wrapper fails and says so. Whoever fixes
  it turns the wrapper back into the plain proof.

Node's `todo` would read better, but `tools/coord/status.py` counts a
top-level `not ok` as a failure, `todo` included.

## Summary

| ID | Priority | Where | State |
|---|---|---|---|
| AUD-B-14 | High | `main.mjs:149`, `:225` | fixed (FX2-7-audit-b-config) |
| AUD-B-15 | High | `main.mjs:73`, `:83`, `:91` | fixed (FX2-7-audit-b-config) |
| AUD-B-01 | Medium | `matchmaking.mjs:275`, `:348` | fixed (FX2-9-audit-b-match) |
| AUD-B-02 | Medium | `observatory.mjs` card | fixed here |
| AUD-B-03 | Medium | `telemetry.mjs` report | fixed here |
| AUD-B-04 | Medium | `telemetry.mjs` batch | fixed here |
| AUD-B-05 | Medium | `auth_http.mjs` prove, `delete.html` | fixed (FX2-8-audit-b-lows) |
| AUD-B-08 | Medium | `auth_http.mjs` deleteByGoogle | fixed here |
| AUD-B-16 | Medium | `main.mjs:379` | fixed (FX2-7-audit-b-config) |
| AUD-B-17 | Medium | `main.mjs:338` | fixed (FX2-7-audit-b-config) |
| AUD-B-18 | Medium | `main.mjs:219` | fixed (FX2-7-audit-b-config) |
| AUD-B-06 | Low | `matchmaking.mjs:308-323` | fixed (FX2-9-audit-b-match) |
| AUD-B-07 | Low | `observatory.mjs` card | fixed here |
| AUD-B-09 | Low | `auth.mjs` spend | fixed here |
| AUD-B-10 | Low | `tokens.mjs:55` | fixed (FX2-8-audit-b-lows) |
| AUD-B-11 | Low | `auth.mjs` rotateHoursOf | fixed here |
| AUD-B-12 | Low | `pages.mjs` | fixed here |
| AUD-B-13 | Low | `server/privacy.json` | fixed (FX2-8-audit-b-lows) |
| AUD-B-19 | Low | `main.mjs:224` | fixed (FX2-7-audit-b-config) |
| AUD-B-20 | Low | `load.mjs:453` | fixed (FX2-8-audit-b-lows) |

Eight are fixed here, six in FX2-7-audit-b-config, four in FX2-8-audit-b-lows, and two in FX2-9-audit-b-match. Two suspicions stay unproven; a third was settled in FX2-8-audit-b-lows.
Seven were checked and rejected, and the rest of the configuration,
`refused.mjs` and `store.mjs` showed no defect (see the last two sections).

## High

### AUD-B-14: An empty RULEBORN_DELETIONS keeps the deletion journal in memory

- **Priority / category:** High / backend (configuration, data retention).
- **Where:** `server/src/main.mjs:149` (`journalDir`, checked against
  `RULEBORN_DATA`) and `:225` (`deletions: new Journal(new Store(process.env.RULEBORN_DELETIONS ?? …))`).
- **Input:** start the server with real sign-in and
  `RULEBORN_DELETIONS=` (set, but empty), as a deployment template with a
  blank line leaves it.
- **Should happen:** the deletion journal lives on its own storage, so a
  restore of the data folder cannot bring a deleted player back (F50,
  SEC-38). An empty value either falls back to the default folder or stops
  the start.
- **Happens:** `??` keeps the empty string, and `new Store("")` is the
  in-memory store. The journal of deletions is lost at every restart. Line
  149 checks `resolve("")` (the working directory) instead of the folder
  the journal really uses, so the check against `RULEBORN_DATA` passes too.
- **Proof:** `fix_fx2_audit_config.test.mjs`, both "AUD-B-14" tests.
  `main.mjs` with stubbed sign-in and an empty `RULEBORN_DELETIONS` leaves
  no journal folder on disk, and with real sign-in it starts and listens.
  (FX2-6's first proof showed `new Store("")` losing an entry, which is
  that store's design; FX2-7 replaced it with the boot.)
- **Fix:** use `||` for the default, or refuse an empty value. Then pass
  `journalDir` to the `Store` at line 225, so the folder checked is the
  folder used.
- **Fixed (FX2-7-audit-b-config):** `settled()`, at the top of `main.mjs`,
  deletes every empty or blank `RULEBORN_*` variable before any is read, so
  each `??` takes its default. The `Store` keeps its own expression, which
  `security_deep_heists.test.mjs` pins, rather than `journalDir`: after
  `settled()` both name the same folder, and the first AUD-B-14 proof boots
  with an empty value and sees the journal's folder on disk and the
  inside-data warning for that folder.

### AUD-B-15: Game Center and StoreKit roots without RULEBORN_BUNDLE_ID switch both off silently

- **Priority / category:** High / backend (configuration).
- **Where:** `server/src/main.mjs:73` (`bundleId … ?? null`), `:83` and
  `:91` (each verifier is built only when `bundleId` is set).
- **Input:** `RULEBORN_GAMECENTER_ROOTS` and `RULEBORN_STOREKIT_ROOTS`
  set, `RULEBORN_BUNDLE_ID` unset.
- **Should happen:** the start is refused, as for the other half-set pairs
  (the Play pair, the CF trio), because the operator asked for Apple
  sign-in and purchases.
- **Happens:** the server starts with Game Center sign-in and StoreKit
  purchases both off, and logs nothing that says why. Every iOS sign-in
  and purchase fails.
- **Proof:** `fix_fx2_audit_config.test.mjs`, "AUD-B-15": `main.mjs` with
  the test roots and no bundle id starts and listens.
- **Fix:** throw at startup when either roots variable is set without
  `RULEBORN_BUNDLE_ID`.
- **Fixed (FX2-7-audit-b-config):** as written.

## Medium

### AUD-B-01: The hourly target lists fix an absent island owner's tier price

- **Priority / category:** Medium / backend (seasons, §18.8).
- **Where:** `server/src/matchmaking.mjs:275` (`live`, `seasons.league(r.owner, now)`)
  and `:348` (`fresh`, the same for an echo's owner). Candidate 23 was the
  same defect in `profile.mjs`, fixed in FX2-5.
- **Input:** season 2 starts. The hourly job (`service.targetLists()`)
  runs, or a raider opens the Observatory, before the defender plays. The
  defender first plays in week 6, with 21 days left.
- **Should happen:** §18.8: "A player first seen in a season pays
  10 × (days left ÷ 56) stars a tier … fixed when the player first appears
  that season". The defender pays 4.
- **Happens:** `seasons.league` opens the defender's standing when the
  list is built, at 10 stars. Any player with a published island has their
  price fixed by the first hourly job of the season, so a late joiner never
  gets the discount.
- **Proof:** `fix_fx2_audit_season.test.mjs`, both "AUD-B-01" tests
  (the hourly job, and a raider's Observatory view): `tierStars` is 10,
  expected 4.
- **Fix:** read Renown without opening a standing, the way `leagueSeen`
  does for `profile.mjs`.
- **Fixed (FX2-9-audit-b-match):** `renownSeen` in `matchmaking.mjs` reads
  the owner's standing if there is one, else where it would start, and
  `live` and `fresh` use it. Both proofs are plain, and fail on main
  `ad0191ea` (`tierStars` 10, expected 4).

### AUD-B-02: A target card across a block names the blocked Keeper

- **Priority / category:** Medium / backend (safety, privacy).
- **Where:** `server/src/observatory.mjs`, the card's `keeper_name`.
- **Input:** the defender has named their Keeper. The raider blocks the
  defender (`safety.block(raider, defender)`) and opens the observatory.
- **Should happen:** §17.8: blocking "does not remove their island from
  the world", but the blocked player disappears from "anything with their
  name on it". The island stays a target, and its card names no Keeper.
- **Happens:** the island stays a target, as it should, and its card
  carries `keeper_name` with the blocked player's Keeper name.
- **Proof:** `fix_fx2_audit_observatory.test.mjs`, "AUD-B-02".
- **Fix (7d713b26):** `keeper_name` is null when the card is generated or
  `safety.between(account, owner)` holds.

### AUD-B-03: The buyer share counts buyers who did not play in the period

- **Priority / category:** Medium / backend (telemetry).
- **Where:** `server/src/telemetry.mjs`, `report`, the buyers query.
- **Input:** B and C start a session at 23:50 on day D and buy at 00:10 on
  D+1. A plays on D+1 and buys nothing. Report D+1 alone.
- **Should happen:** the share of players who bought something is buyers
  among that period's players: 0 of 1. The design (v3.7, line 11321) sets
  "at least 2% of monthly players buy something" as a global-launch gate,
  so an inflated share can pass the gate wrongly.
- **Happens:** the share counts every account with a purchase in the
  period, so it is 2 of 1. It can exceed 1.
- **Proof:** `fix_fx2_audit_telemetry.test.mjs`, "AUD-B-03".
- **Fix (2235e681):** the buyers query keeps a buyer only when the same
  account has a `session_start` in the period.

### AUD-B-04: A device clock a second ahead loses the whole batch

- **Priority / category:** Medium / backend (telemetry).
- **Where:** `server/src/telemetry.mjs`, `batch`.
- **Input:** a batch whose `session_end` is stamped one second after the
  server's clock.
- **Should happen:** a small skew is tolerated. The client drops a refused
  batch whole (`client/app/services.gd`), so a refusal loses every event in
  it.
- **Happens:** any event stamped later than the server's clock is a 400.
- **Proof:** `fix_fx2_audit_telemetry.test.mjs`, "AUD-B-04". The query
  reads only `session_*` events, because sign-in writes a `sign_in` event.
- **Fix (2235e681):** `CLOCK_SKEW_MS` (5 minutes) of tolerance, and an
  event within it is kept at the server's time. Further ahead is still
  refused. `telemetry.test.mjs`'s future-time check now uses
  `T0 + CLOCK_SKEW_MS + 1`, with a comment naming AUD-B-04. That test
  encoded the defect (one millisecond ahead was a refusal). The check
  stays, with its threshold moved.

### AUD-B-05: After a wrong Google account, the deletion page cannot be retried

- **Priority / category:** Medium / frontend (web deletion).
- **Where:** `server/src/auth_http.mjs`, `deleteByGoogle` (`prove`), and
  `server/delete.html`.
- **Input:** on the deletion page, the player signs in with a Google
  account that has no Ruleborn account (404), then with the right one.
- **Should happen:** the retry deletes the right account.
- **Happens:** `prove` spends the nonce before the 404 is decided, and the
  page keeps the same nonce, so the retry is refused with 401. The player
  must reload the page, and nothing tells them so.
- **Proof:** `fix_fx2_audit_auth.test.mjs`, "AUD-B-05": the retry
  answers 401, expected 200.
- **Fix:** the page reloads itself (a fresh nonce and cookie) after any
  failure, or the 404 answer carries a fresh nonce and sets its cookie.
  The nonce stays spent either way. `delete.html` is outside this task's
  files.
- **Fixed (FX2-8-audit-b-lows):** the second way. The 404 answers
  `{error: "no_such_account", nonce}` with the fresh nonce's cookie, and
  the page initialises Google's sign-in again with it. The proof's retry
  uses that nonce: with the spent one it is still refused, as it should be.

### AUD-B-08: With no web client id, the game's own token can delete through the web route

- **Priority / category:** Medium / backend (auth).
- **Where:** `server/src/auth_http.mjs`, `deleteByGoogle`. With
  `webClientId` unset, `auth_proofs.mjs` skips the audience check.
- **Input:** no `RULEBORN_GOOGLE_WEB_CLIENT_ID`. A client asks for a nonce
  and posts the game's own (Android client) ID token carrying it, with the
  nonce cookie, to `POST /v1/account/delete`.
- **Should happen:** without a web client, the web deletion takes nothing.
  The GET page already answers 503.
- **Happens:** the token is taken and the account is deleted (200).
- **Proof:** `fix_fx2_audit_auth.test.mjs`, "AUD-B-08": expected 401,
  actual 200.
- **Fix (53796600):** `deleteByGoogle` refuses with 401
  `google_identity_refused` when there is no web client id. The check sits
  after the body is read and `idToken` is type-checked, not in the route,
  for two reasons. A failure here counts toward failed sign-ins (G44,
  `limits.test.mjs`), and the cross-site check comes first (SR-23,
  `security_config.test.mjs`). The first attempt (40f375df) answered 503
  in the route, and it broke both.

### AUD-B-16: An empty or unreadable RULEBORN_MAX_CONNECTIONS refuses every connection, or removes the cap

- **Priority / category:** Medium / backend (configuration).
- **Where:** `server/src/main.mjs:379`
  (`Number(process.env.RULEBORN_MAX_CONNECTIONS ?? 2048)`).
- **Input:** `RULEBORN_MAX_CONNECTIONS=` (empty), or `abc`.
- **Should happen:** the default of 2048, or a refused start.
- **Happens:** empty gives 0, so the listener closes every connection.
  `abc` gives NaN, so there is no cap at all.
- **Proof:** `fix_fx2_audit_config.test.mjs`, "AUD-B-16": no request is
  answered. Its control, "the defaults close a socket …", shows the same
  boot answering with the defaults.
- **Fix:** one helper for every numeric variable: empty is unset, and a
  value that is not a finite positive integer stops the start.
- **Fixed (FX2-7-audit-b-config):** `settled()` unsets empty values
  (AUD-B-14), and a check after it refuses `RULEBORN_MAX_CONNECTIONS`,
  `RULEBORN_HEADERS_TIMEOUT_MS` and `RULEBORN_REPLAYS_MIN_FREE_MB` unless
  each is a whole number of at least 1 (the replay floor at least 0, which
  the server guide documents as turning it off). The second proof refuses
  `abc`, `0`, `-1` and `1.5`.

### AUD-B-17: An empty RULEBORN_HEADERS_TIMEOUT_MS turns the headers timeout off

- **Priority / category:** Medium / backend (configuration, SEC-34).
- **Where:** `server/src/main.mjs:338`.
- **Input:** `RULEBORN_HEADERS_TIMEOUT_MS=` (empty).
- **Should happen:** a socket that never finishes its headers is closed
  after 10 s (SEC-34).
- **Happens:** the value is 0, which node reads as no timeout. The socket
  stays open.
- **Proof:** `fix_fx2_audit_config.test.mjs`, "AUD-B-17", beside the
  control that sees the default close the socket within 12.5 s.
- **Fix:** the helper of AUD-B-16.
- **Fixed (FX2-7-audit-b-config):** by `settled()` (AUD-B-14).

### AUD-B-18: An unreadable RULEBORN_SEASON_START leaves no current season

- **Priority / category:** Medium / backend (configuration).
- **Where:** `server/src/main.mjs:219` (`Date.parse(...)`).
- **Input:** `RULEBORN_SEASON_START=next monday`.
- **Should happen:** the start is refused.
- **Happens:** `seasonStart` is NaN. The server starts and
  `seasons.current()` is undefined, so every caller that reads `.id` throws.
- **Proof:** `fix_fx2_audit_config.test.mjs`, both "AUD-B-18" tests (the
  boot, and the service with `seasonStart: NaN`).
- **Fix:** refuse a `seasonStart` that is not finite, in `main.mjs` or in
  the seasons constructor.
- **Fixed (FX2-7-audit-b-config):** in `main.mjs`. The seasons
  constructor's own guard is outside FX2-7's files, so the service proof
  (`seasonStart: NaN`) stays in `stillOpen`, for the owner of `seasons.mjs`.

## Low

### AUD-B-06: A republished island keeps its old chapter in the target list

- **Priority / category:** Low / backend (matchmaking, §7.6).
- **Where:** `server/src/matchmaking.mjs:308-323`, `current`.
- **Input:** a chapter-1 raider has a defender's island in their hourly
  list. Within the hour, the defender republishes with a chapter-2 law.
- **Should happen:** §7.6: matchmaking shows only universes that run laws
  from open chapters. The new island is not shown to the chapter-1 raider.
- **Happens:** `current` swaps in the new bundle and its snapshot, but
  keeps the card's old chapter, so the island is shown until the next
  hourly list.
- **Proof:** `fix_fx2_audit_observatory.test.mjs`, "AUD-B-06".
- **Fix:** in `current`, recompute the chapter of the swapped bundle, and
  drop the card when the raider cannot see that chapter.
- **Fixed (FX2-9-audit-b-match):** `current` cannot read the raider, so it
  drops a swap whose chapter is above the card it replaces, or whose bytes
  are gone; the island returns in the next hourly list. The same defect is
  FX1-A-07 (`server-a.md`). Both proofs are plain, and fail on main
  `ad0191ea`.

### AUD-B-07: An echo's card describes the owner's other realms

- **Priority / category:** Low / backend (Observatory).
- **Where:** `server/src/observatory.mjs`, the card.
- **Input:** a raider is offered an echo (one island at one realm).
- **Should happen:** the card describes the one island the lease is.
- **Happens:** realms, strain and band, clocks, depth and fault realms are
  read across all the owner's realms, as for a live owner.
- **Proof:** `fix_fx2_audit_observatory.test.mjs`, "AUD-B-07".
- **Fix (7d713b26):** a card that is generated or an echo is single, and
  each of those fields is read for its own realm only.

### AUD-B-09: A Game Center proof replayed at its window's last millisecond signs in

- **Priority / category:** Low / backend (auth).
- **Where:** `server/src/auth.mjs`, `spend`. `stores.mjs` takes a proof
  while `|now - timestamp| <= 5 min`.
- **Input:** a proof is used, then replayed at exactly
  `timestamp + GAME_CENTER_FRESH_MS`.
- **Should happen:** the replay is refused.
- **Happens:** the spent key is treated as expired at that millisecond
  (`expires_at > now`), but the proof is still fresh, so it signs in again.
- **Proof:** `fix_fx2_audit_auth.test.mjs`, "AUD-B-09". A millisecond
  earlier, its control is refused.
- **Fix (aff2441c):** `expires_at >= now`.

### AUD-B-10: A token key named `constructor` is refused as named twice

- **Priority / category:** Low / backend (auth configuration).
- **Where:** `server/src/tokens.mjs:55` (`if (keys[kid])` on a plain
  object). Line 85 already uses `Object.hasOwn`.
- **Input:** `RULEBORN_SECRET` with a key whose kid is `constructor` (or
  `toString`, any `Object.prototype` member). It is letters only, which is
  the kid's own rule.
- **Should happen:** the key is taken.
- **Happens:** "token key constructor is named twice", and the start fails.
- **Proof:** `fix_fx2_audit_auth.test.mjs`, "AUD-B-10".
- **Fix:** `Object.hasOwn(keys, kid)`, or a `Map`. Not this task's file.
- **Fixed (FX2-8-audit-b-lows):** `Object.hasOwn(keys, kid)`.

### AUD-B-11: An empty RULEBORN_REFRESH_ROTATE_HOURS rotates every refresh

- **Priority / category:** Low / backend (configuration).
- **Where:** `server/src/auth.mjs`, `rotateHoursOf`.
- **Input:** `RULEBORN_REFRESH_ROTATE_HOURS=` (empty).
- **Should happen:** unset, which means 24 hours (0 for the example
  deployment).
- **Happens:** `Number("")` is 0, so every refresh rotates.
- **Proof:** `fix_fx2_audit_auth.test.mjs`, "AUD-B-11".
- **Fix (8e5040b9):** an empty value is unset. An explicit "0" still
  means 0.

### AUD-B-12: The privacy page says "1 days"

- **Priority / category:** Low / frontend (copy).
- **Where:** `server/src/pages.mjs`, the retention table
  (`${k.days} days`).
- **Input:** render the privacy page. One retention lasts one day.
- **Should happen:** "1 day".
- **Happens:** "1 days".
- **Proof:** `fix_fx2_audit_privacy.test.mjs`, "AUD-B-12".
- **Fix (b0f8519b):** the singular when the number is 1.

### AUD-B-13: The privacy page names repository files and functions

- **Priority / category:** Low / frontend (copy).
- **Where:** `server/privacy.json`, the texts that render as
  "(docs/security/auth.md)", "(expireReplays)" and "(snapshots)", and
  line 2477, where `plain` strips a "§" and leaves "it is log".
- **Input:** render the privacy page.
- **Should happen:** prose a player can read. RB-60's fix (FX2-5) removes
  § and audit references, but these are code references.
- **Happens:** the four strings are on the page.
- **Proof:** `fix_fx2_audit_privacy.test.mjs`, one "AUD-B-13" test per
  string.
- **Fix:** reword the four texts in `privacy.json`, which is outside this
  task's files; at line 2477, for example, "for good: it is the deletion
  log". Do not widen `plain`, which would also strip prose
  parentheses.
- **Fixed (FX2-8-audit-b-lows):** the four texts reworded, "for good: it
  is the deletion log" among them, and `declarations.md` written again
  from `privacy.json`. `plain` is unchanged.

### AUD-B-19: An empty RULEBORN_REPLAYS_MIN_FREE_MB removes the free-space floor

- **Priority / category:** Low / backend (configuration, SEC-18).
- **Where:** `server/src/main.mjs:224`.
- **Input:** `RULEBORN_REPLAYS_MIN_FREE_MB=` (empty).
- **Should happen:** the 512 MiB floor, so replays stop before the disk
  fills (SEC-18).
- **Happens:** the floor is 0 bytes.
- **Proof:** `fix_fx2_audit_config.test.mjs`, "AUD-B-19". It reads
  `main.mjs`'s own `minFreeBytes` expression from the file and evaluates
  it with the empty value, so the proof follows the code.
- **Fix:** the helper of AUD-B-16.
- **Fixed (FX2-7-audit-b-config):** by `settled()` (AUD-B-14).

### AUD-B-20: The free plan's daily-player capacity ignores the daily share

- **Priority / category:** Low / tooling (capacity model).
- **Where:** `server/load.mjs:453`, `freePlanReadsPlayersADay`
  (`READS.freeDay / readsADay(result, 1)`).
- **Input:** the kept runs in `server/load.json`.
- **Should happen:** the daily players it reports read no more than the
  free plan's day, by `readsAMonth`'s own model, which turns daily players
  into monthly ones with `DAILY_SHARE` (dd/dn).
- **Happens:** it counts one player's reads, without the monthly players
  behind each daily one. It reports about 1.3 to 2 times too many: engaged
  4487 where the model allows 3552, regular 9773 for 6212, casual 16995
  for 8512.
- **Proof:** `fix_fx2_audit_load.test.mjs`, "AUD-B-20".
- **Fix:** with `[dn, dd] = facts.DAILY_SHARE`, use
  `READS.freeDay / readsADay(result, dd / dn)`, rewrite `load.json`, and
  recheck the capacity notes that quote the figure. `load.mjs` is outside this
  task's files.
- **Fixed (FX2-8-audit-b-lows):** as written. `load.json` is rewritten by
  `node server/load.mjs --write`: engaged 3504, regular 6178, casual 8497
  daily players (the reads moved by about 2% with main's queries since the
  figures above). No capacity note outside the report quoted the old
  figures.

## Unproven

- **`googleapi.mjs`, `voided(since)`: a window at the API's 30-day edge.**
  It sends `startTime=${Math.floor(since)}`, and `shop.mjs:414` calls it
  with now minus 30 days. Google documents that `startTime` "cannot be
  older than 30 days", so a request whose clock runs a little behind
  Google's may be refused. **Tried:** reading the code and the API's
  documented limit; it does not say how the edge is treated. It cannot be
  tested offline: the fake answers whatever it is given. **To prove:** one
  live call with a test key. **Proposed fix:** ask for 29 days and a few
  minutes, and recheck the margin the reconciliation needs.
- **`load.mjs:109`, `billed()`: inserts counted from `last_insert_rowid`.**
  `inserted = upsert ? rowid() !== before : true`, and `last_insert_rowid`
  belongs to the whole connection, not to the table. An upsert that
  inserts a row whose rowid happens to equal the rowid last inserted into
  another table is counted as an update, so its write is billed wrongly.
  **Tried:** reading the runner's insert paths. The run was not
  instrumented to find such a collision, so no input is shown that makes
  it wrong. **Proposed fix:** count with `changes` and a `SELECT` of the
  key before the upsert, not with the rowid.
- **`privacy.json:2475`: "withdraw choice an object".** It reads as a
  stripped reference, but the source text may be meant that way. **Tried:**
  the rendered page and the source. Left for whoever rewords AUD-B-13.
  **Settled (FX2-8-audit-b-lows):** a garble, not a reference. The
  journal (`accounts.mjs`, `Journal.append`) writes one object a deletion,
  `{account, reason, withdraw, at}`; the text now says so.

## Checked and rejected

- **The crew friends-only rule is checked only for a joiner aged 13 to 15
  (SR-14, `social.mjs:266-274`).** This is the owner's ruling, not a
  defect: SR-14 (`docs/decisions/owner-decisions.md:41`) asks "a friend
  or constellation-mate of one member; for a player aged 13 to 15, a
  friend of every member", and `server/test/security_owner.test.mjs:82`,
  "an adult friend of one member joins", guards it. A note goes to the
  lead: §20.7 gives a 13 to 15's co-op as "Friends only", which a crew of
  mixed ages may need to square once co-op and the crew thread are built.
- **`profile.view` runs `codex.ensure` and `home.ensure` for another
  player.** These writes add nothing new. `show()` serves a profile only
  after `share(true)`, which already ran `view(own)` and both ensures. The
  rows are deleted only by account deletion (`accounts.mjs:149` and 154),
  which also clears `profile_public`, and `show()` refuses a deleted or
  banned account.
- **Pushes to banned accounts.** `aided()` (`notifications.mjs:238-266`)
  and `remind()` (289-325) leave banned accounts out. `workshop.ban()`
  (`workshop.mjs:614-629`) calls `auth.endAll`, which runs `#unpush`
  (`auth.mjs:296-310`), and `send()` (408-413) skips a token whose
  `push_session` is not live. Tokens registered over HTTP always carry a
  session (`http.mjs:709-714`). The one gap is a legacy token with
  `push_session` NULL on an account that had no live session at the ban:
  too narrow to list. An optional hardening is `AND a.banned_at IS NULL`
  at `notifications.mjs:372-374`.
- **`deviceOf` can keep a trailing space** (`auth.mjs:62`: `.trim()` runs
  before `.slice(0, 32)`). Rejected as cosmetic: the value labels a
  session and decides nothing.
- **A sign-in nonce at its expiry.** The comparison is a strict `>`, so
  the boundary is handled.
- **The cache of Google access tokens** (`googleapi.mjs:49` and 71). A
  token is held until its `expires_in` (3600 s by default) less the
  margin, so a stale one lives about an hour at most. Rejected, low impact.
- **Google sign-in keys trusted without expiry.** They expire:
  `stores.mjs`, `GoogleSignIn.refresh`, keeps a key set for its
  `maxAgeMs`, capped at 24 hours, and one hour without it.
- **Configuration with no defect:** `RULEBORN_DATA`, `RULEBORN_SECRET`,
  `RULEBORN_REFRESH_ROTATE_HOURS` when set, `RULEBORN_FCM_PROJECT`, the
  Play pair, the CF trio, `RULEBORN_APPLE_ROOTS`, the interval guards,
  `MAX_READ` and the `headersSent` guard.
- **`refused.mjs` and `store.mjs`.** Both were read whole, and no input
  gave a wrong result.
