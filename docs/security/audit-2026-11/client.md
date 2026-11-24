# Client audit, November 2026

The client half of the fix wave's extra checks
([bug report](../bug-report-2026-11.md), task FX4-4-audit-client). It covers
the Godot client code the report did not read: `client/features` beyond the
auth and network files, `client/core`, `client/app`, `client/data` and
`client/ext`. `client/scripts`, `client/world` and `client/ui` were read for
the paths these lead into; they are read-only for this task, apart from
`client/scripts/result_screen.gd`. It also settles the report's five client
suspicions.

**The proof rule.** A finding is **confirmed** only when a test fails on
main (`1c4fd104`, the branch point; the client code there is the code the
proofs first ran on). Each such test stays in the suite, in
`client/tests/fix_audit_client_tests.gd`, named by its finding id. A finding
fixed here is a plain check: it failed on main and passes with its fix. A
finding proven but not fixed here is a **still-open** check, marked
`# Audit finding CLI-N`: it passes while the defect is there, and once the
defect is fixed it fails and says to make it a plain check. No test was
skipped or loosened. Anything not proven that way is listed under
"Unproven", with what was tried.

Twelve findings are fixed on `claude/fix-client` (commits `4d5a17d3`,
`684353ef` and `8f91599d`). Two are proven and still open: CLI-1, whose cause
is on the server, and CLI-18, whose code is read-only for this task. The full
client suite's result after the fixes (`python3 client/status.py`) is in
`docs/progress/FX4.md`, Evidence.

## Summary

| ID | Priority | Category | Location | Title | State |
|---|---|---|---|---|---|
| CLI-1 | High | frontend-backend contract | `client/features/curation/curation_controller.gd apply_swap` | A curation swap is woven and paid, then its publish is refused while it weaves | proven, open |
| CLI-2 | High | security | `client/features/auth/auth_session.gd sign_out` | A sign-out during a token renewal leaves a live session, and the phone keeps its token | fixed |
| CLI-4 | High | frontend/UI | `client/data/draft.gd start_remix` | A second remix overwrites the player's own kept island | fixed |
| CLI-5 | Medium | security | `client/features/auth/auth_session.gd sign_out` | A sign-out whose access token the server refuses never falls back to the refresh token | fixed |
| CLI-6 | Medium | frontend/UI | `client/features/curation/curation_controller.gd preview_swap` | A second swap previewed keeps the first swap's law on the draft | fixed |
| CLI-7 | Medium | frontend/UI | `client/features/curation/curation_controller.gd preview_swap` | A swap that changes nothing on the island is still woven and paid | fixed |
| CLI-10 | Medium | frontend/UI | `client/features/realm/realm_controller.gd load_realm` | A late realm load shows one realm's island under another | fixed |
| CLI-11 | Medium | frontend/UI | `client/data/repositories/heist_repository.gd first_target` | The target fallback treats a player's curated island as the game's own | fixed |
| CLI-13 | Medium | integration | `client/data/outbox.gd _read` | One malformed outbox item stops every flush, so nothing behind it is ever sent | fixed |
| CLI-14 | Medium | integration | `client/app/app_lifetime.gd` | `notices.seen()` is never called, so a crashed session reports 0 seconds | fixed |
| CLI-15 | Medium | frontend/UI | `client/scripts/result_screen.gd _study` | A study tile tapped twice sends two studies | fixed |
| CLI-18 | Medium | frontend/UI | `client/scripts/stage_rehearsal.gd` | A style card tapped while another crew plays shows that crew's result under the new card | proven, open |
| CLI-22 | Low | security | `client/core/action_log.gd add` | The action log keeps account ids | fixed |
| CLI-24 | Low | frontend/UI | `client/features/social/social_controller.gd load_friends` | A failed blocks call empties the blocked list on screen | fixed |

CLI-3, CLI-8, CLI-9, CLI-16, CLI-17, CLI-19, CLI-20, CLI-21 and CLI-23 were
found but not proven: see "Unproven". CLI-12 is covered by RB-32, already on
main.

## High

### CLI-1: A curation swap is woven and paid, then its publish is refused while it weaves
- **Priority / category:** High / frontend-backend contract.
- **Where:** `client/features/curation/curation_controller.gd` `apply_swap`,
  lines 128-156. With `server/src/universe.mjs`'s publish check (SR-16),
  lines 363-367, which takes only laws that are ready.
- **Input:** a curator previews a swap and applies it.
- **Should happen:** §13.3 and §5.6: the swap is woven, and the island
  shows the new law once it is ready. The player is not charged for a change
  that is then refused.
- **Happens:** `apply_swap` posts `POST /v1/weaving` (Aether spent, the slot
  now weaving, `ready_at` in the future), then publishes the draft at once
  with `PUT /v1/islands/heart`. The server refuses it, `422
  island_not_publishable` with `law_not_woven`, and the screen shows a
  failure. The published island keeps the old law's pylon, which is now in
  no slot, so every publish of that realm is refused until `ready_at`.
- **Proof:** `_swap_publish_is_refused_while_weaving`, a still-open check.
  The fake answers the publish as the server does. It passes on main and
  on this branch: woven, published with the new pylon, and the error is
  `island_not_publishable`.
- **Fix (not applied):** on the server, SR-16 accepts the slot's weaving law
  for its owner's publish. Or, on the client, the publish waits until the
  law is woven, and the screen says so. The server's rule decides which, so
  it is left to the lead.

### CLI-2: A sign-out during a token renewal leaves a live session, and the phone keeps its token
- **Priority / category:** High / security.
- **Where:** `client/features/auth/auth_session.gd` `sign_out`, lines
  164-176, and the renewal in `ensure` and `_renew`, lines 193-215 and 282.
- **Input:** the access token is being renewed (`POST /v1/session` on its
  way, slow network) when the player taps Sign out.
- **Should happen:** the sign-out ends the session, and the phone forgets
  every token (docs/security/auth.md).
- **Happens:** `sign_out` ends the old session and clears the vault. Then
  the renewal lands, and `_renew` stores the new session's tokens. The phone
  is signed in again with a session the server never ended.
- **Proof:** `_sign_out_during_a_renewal`. `SessionServer` answers
  `/v1/session` ten frames late. Fails on main: the token is the renewed
  one, and no `/v1/session/end` follows the renewal.
- **Fix (applied):** `sign_out` waits for a renewal on its way (`if _busy:
  await renewed`), so the session it ends is the newest.

### CLI-4: A second remix overwrites the player's own kept island
- **Priority / category:** High / frontend/UI.
- **Where:** `client/data/draft.gd` `start_remix`, lines 36-41.
- **Input:** the player's own island is the draft. They remix Workshop
  island A, then remix island B.
- **Should happen:** §18.6: the island a remix replaces is kept, and the
  player's own creation is never lost.
- **Happens:** the second remix keeps remix A in the one kept slot, over the
  player's own island. Restoring gives back remix A, and the player's island
  is gone.
- **Proof:** `_second_remix_keeps_the_players_island`. Fails on main: the
  island restored is A's.
- **Fix (applied):** a remix that replaces a remix leaves the kept island
  alone when that is the player's own (one with no original).

## Medium

### CLI-5: A sign-out whose access token the server refuses never falls back to the refresh token
- **Priority / category:** Medium / security.
- **Where:** `client/features/auth/auth_session.gd` `sign_out`, lines
  164-176.
- **Input:** the phone thinks its access token is fresh, but the server no
  longer accepts it (a key rotated, or a session ended on another device).
  The player signs out.
- **Should happen:** the session is ended by the refresh token, which
  `/v1/session/end` takes without a bearer.
- **Happens:** the bearer call gets `401 session_refused`, and `sign_out`
  stops there. The refresh token stays live on the server.
- **Proof:** `_sign_out_falls_back_to_the_refresh_token`. Fails on main: one
  `/v1/session/end`, and no call with `refreshToken`.
- **Fix (applied):** on `session_refused`, `sign_out` ends the session with
  the refresh token.

### CLI-6: A second swap previewed keeps the first swap's law on the draft
- **Priority / category:** Medium / frontend/UI.
- **Where:** `client/features/curation/curation_controller.gd`
  `preview_swap`, lines 112-117.
- **Input:** preview swapping slot 1 to `bloom`, then slot 1 to `embers`.
- **Should happen:** G54 and §13.3: the draft shows the swap that would be
  woven, `embers`.
- **Happens:** the second preview looks for the view's old law, which the
  first preview already replaced, so it changes nothing. The draft keeps
  `bloom` while the swap names `embers`.
- **Proof:** `_second_preview_swaps_the_shown_law`. Fails on main: the
  pylon is `pylon:bloom`.
- **Fix (applied):** the swap previewed before is taken back first.

### CLI-7: A swap that changes nothing on the island is still woven and paid
- **Priority / category:** Medium / frontend/UI.
- **Where:** `client/features/curation/curation_controller.gd`
  `preview_swap` and `apply_swap`.
- **Input:** a swap on a slot whose law has no pylon on the island.
- **Should happen:** the swap is refused at the preview, and nothing is
  spent.
- **Happens:** the preview changes nothing, and applying it weaves and pays
  for a law the island never shows.
- **Proof:** `_swap_not_on_the_island_is_refused`. Fails on main: `POST
  /v1/weaving` is sent.
- **Fix (applied):** `preview_swap` fails with `swap_not_on_island` and
  clears the swap, so `apply_swap` has nothing to weave.

### CLI-10: A late realm load shows one realm's island under another
- **Priority / category:** Medium / frontend/UI.
- **Where:** `client/features/realm/realm_controller.gd` `load_realm`, lines
  19-32.
- **Input:** the realm view opens on the Heart, and the player opens an
  outer realm before the Heart's island arrives.
- **Should happen:** §23.2: the realm open shows its own island.
- **Happens:** the Heart's load finishes after the switch and writes its
  island into the realm slice, now the outer realm's.
- **Proof:** `_late_realm_load_is_dropped`. Fails on main: the outer realm
  holds the Heart's island bytes.
- **Fix (applied):** `load_realm` checks the realm again after each await,
  and drops a load for a realm no longer open.

### CLI-11: The target fallback treats a player's curated island as the game's own
- **Priority / category:** Medium / frontend/UI. The client twin of RB-06.
- **Where:** `client/data/repositories/heist_repository.gd` `first_target`,
  line 47.
- **Input:** a target list with the generator's island first, then a
  player's curated island (`origin: "generated"`, owned by a player).
- **Should happen:** §12.22: the game's own generated islands only when no
  player's island is there. A curated island is generated (§13.3), but it is
  still a player's.
- **Happens:** every `origin == "generated"` island counts as the game's,
  so the first one in the list wins, the generator's here.
- **Proof:** `_first_target_prefers_a_curated_island`. Fails on main: it
  chooses `gen`.
- **Fix (applied):** the game's own islands are those owned by
  `the-game-generator` (`server/src/generator.mjs`). The order is: an
  authored island first, then a curated one, then the generator's. The
  first version made curated islands equal to authored ones, and three
  server-backed tests failed. Under `--example`, the server
  (`server/src/main.mjs` lines 308-320) publishes the `example:universe`
  account's islands as generated, and those tests expect the authored
  `example:defender` Heart. Keeping authored islands first passes them.

### CLI-13: One malformed outbox item stops every flush, so nothing behind it is ever sent
- **Priority / category:** Medium / integration.
- **Where:** `client/data/outbox.gd` `_read`, lines 158-167. The flush,
  line 118, reads `item["json"]` and types the key and body.
- **Input:** an outbox file with an item that has no `json` field, or a key
  or body that is not a string (an older build's file, or a partial write).
- **Should happen:** the outbox sends what it can; an item it cannot read
  is dropped.
- **Happens:** `_read` takes any item with the keys present. The flush
  stops at the bad item, every time, so everything queued behind it (a
  heist's replay among them) is never sent.
- **Proof:** `_outbox_reads_only_whole_items`. Fails on main: the bad items
  are read.
- **Fix (applied):** `_read` keeps only items whose key, route and body are
  strings and whose `json` is a bool; a missing `json` reads as false.

### CLI-14: `notices.seen()` is never called, so a crashed session reports 0 seconds
- **Priority / category:** Medium / integration. One of the report's client
  suspicions.
- **Where:** `client/data/device_notices.gd` `seen` (never called), and
  `client/app/app_lifetime.gd`, which drives the notices.
- **Input:** a session the app never closes: killed by the system, or
  crashed. The app is then launched again.
- **Should happen:** the next launch ends the old session at the last time
  it was seen open, as `device_notices.gd` intends.
- **Happens:** nothing marks the session seen, so it ends at its start, and
  the `session_end` event reports 0 seconds.
- **Proof:** `_open_session_is_marked_seen`. A session started two minutes
  ago, `AppLifetime` run for 31 s, then a fresh `DeviceNotices` started.
  Fails on main: the crashed session reports 0 seconds.
- **Fix (applied):** `AppLifetime._process` marks the open session seen
  every 30 seconds.

### CLI-15: A study tile tapped twice sends two studies
- **Priority / category:** Medium / frontend/UI.
- **Where:** `client/scripts/result_screen.gd` `_study`, lines 728-739.
- **Input:** a double tap on a study tile, before the server answers.
- **Should happen:** §7.6: one study a heist.
- **Happens:** both taps call `codex.study`. The second gets the
  `repeated` answer, and the tile then reads "0 pages".
- **Proof:** `_study_is_sent_once`. Fails on main: two studies are sent.
- **Fix (applied):** a `_studying` guard, set before the await. The buttons
  were already all disabled once an answer comes, so a study that failed
  was never retried here before either.

### CLI-18: A style card tapped while another crew plays shows that crew's result under the new card
- **Priority / category:** Medium / frontend/UI.
- **Where:** `client/scripts/stage_rehearsal.gd`, lines 184-186 and 214-217
  (read-only for this task).
- **Input:** on the rehearsal stage, tap the "greedy" style card while the
  cautious crew's run plays.
- **Should happen:** the greedy crew runs, and its card shows its result.
- **Happens:** a run asked for while one plays finishes the one playing.
  The style changes to greedy, no new run starts, and the cautious crew's
  result is shown under the greedy card.
- **Proof:** `_rehearsal_card_runs_its_own_crew`, a still-open check. It
  passes on main and on this branch: playing, card found, style `greedy`,
  runs 1.
- **Fix (not applied):** a run asked for while one plays stops it and
  starts the new style's run. Needs a task that owns
  `client/scripts/stage_rehearsal.gd`.

## Low

### CLI-22: The action log keeps account ids
- **Priority / category:** Low / security. One of the report's client
  suspicions.
- **Where:** `client/core/action_log.gd` `add`, lines 14-23.
- **Input:** `signed_in` and `friend_accepted`, with their `account` and
  `friend` fields.
- **Should happen:** §20.5: the defect report's log names no player.
- **Happens:** every short string field is kept, account ids among them.
- **Proof:** `_action_log_keeps_no_account_ids`. Fails on main: the account
  id is in the log.
- **Fix (applied):** a deny-list of fields that name a player: `account`,
  `friend`, `invite`, `owner`, `player` and `token`. A screen's name is
  still kept (RB-59).

### CLI-24: A failed blocks call empties the blocked list on screen
- **Priority / category:** Low / frontend/UI.
- **Where:** `client/features/social/social_controller.gd` `load_friends`,
  lines 101-103.
- **Input:** the friends load succeeds, and the blocks call fails (offline
  for a moment).
- **Should happen:** §17.8: the blocked players stay shown, each with
  Unblock.
- **Happens:** the list is replaced with an empty one, as if nobody were
  blocked.
- **Proof:** `_failed_blocks_keep_the_blocked_list`. Fails on main: the
  list is empty.
- **Fix (applied):** a failed blocks call keeps the list shown.

## The report's client suspicions

### `client/ext/src/lib.rs`: ticks and kind values are wrapped with `as` casts
Real, Low, and not proven (CLI-23 under "Unproven"). `ticks as u32`
(lines 220 and 301), `crew as u8` (221), `kind as u8` (340), and `actor as
u8` with `x as i16` and `y as i16` (361, 364) wrap an out-of-range value
onto a valid one, where they should refuse it. Every caller in the client
passes values in range, so no wrong result was reached.

### `action_log.gd`: player ids are logged
Confirmed and fixed: CLI-22.

### `store_purchases.gd`: always the desktop stub
Confirmed, but a feature gap rather than a defect: `client/app/services.gd`
line 134 builds the stub on every platform, because there is no platform
billing plugin yet. Not proven with a test; nothing goes wrong until
billing ships.

### `services.gd`: `notices.seen()` is never called
Confirmed and fixed: CLI-14.

### `auth_session.gd` `sign_out`: no fallback to the refresh token
Confirmed and fixed: CLI-5. Reading it also found CLI-2.

## Unproven

Each item below was suspected while reading. It was not proven with a
failing test, so it is listed rather than fixed.

### Found, not proven
- **CLI-3 (High): an offline heist is submitted with the planner's crew.**
  `client/scripts/heist_screen.gd` lines 161-170 and 291-292. A heist
  played offline from stock sends the planner's `?crew=` ids, not the three
  that played, so the server refuses `crew_mismatch` or rests the wrong
  characters. The proof needs the heist scene with its world and
  simulation. That was too heavy for a unit check, and the file is
  read-only here.
- **CLI-8 (Medium): the owner scouted is dropped on the way to the lease.**
  `client/features/planner/planner_controller.gd` lines 83-91 and
  `client/features/defences/defences_controller.gd` line 70 send no owner.
  On the server, `observatory.mjs`'s `card()` gives none, and
  `service.mjs` line 458 falls back to `holders[0]`. So the server never
  sends the owner, and the client has none to carry. This is a contract
  note for the server's tasks.
- **CLI-9 (Medium): a Defences trace is leased without `across`.**
  `defences_controller.gd` line 70 sends `{bundle, trace: true}`, and
  `server/src/defences.mjs` line 74 sends `trace: {bundle}` only. So the
  trace lands on the Heart (§5.4). The client cannot add what the server
  never says. A contract note, like CLI-8.
- **CLI-16 (Medium): `world_view.gd`'s `_sync_skiff` shows the replay's
  last skiff from tick 0.** `client/world/world_view.gd` lines 730-747. The
  same pattern is in `fx_ground.gd` line 170. Read-only; a `WorldView` check
  needs a recorded replay, which was not built.
- **CLI-17 (Medium): `show_replay`'s rebuild key has no crew, roles or
  seed.** `world_view.gd` lines 271-283. So a 5-crew replay shown after a
  3-crew one on the same island keeps the old crew. Read-only, and not
  built for the same reason as CLI-16.
- **CLI-19 (Medium): every offline weave aims at the same free slot.**
  `client/features/weaving/weaving_presenter.gd` lines 110-113 and 166 take
  the first empty slot from the last view. A second weave queued offline
  names the same slot, and the server refuses it `slot_taken`. The proof
  needs two weaves queued in the outbox and then flushed against a fake
  that holds slot state. Not built.
- **CLI-20 (Medium): offline builds of the same building collapse into one
  outbox key.** `client/features/universe/universe_controller.gd` lines
  51-70: the key is the building and level, so a second build queued
  offline replaces the first. Not built, for the same reason as CLI-19.
- **CLI-21 (Medium): the roster's `collect_all` has no busy guard.**
  `client/features/roster/roster_controller.gd` lines 91-106. A second
  tap sends again, and its end clears another change's busy flag.
  `FakeTransport` answers at once, so the race could not be staged without
  a slow fake.
- **CLI-23 (Low): the ext's `as` casts** (above). A proof needs the ext
  rebuilt with a test entry point, outside this task's checks.

### Covered elsewhere
- **CLI-12: telemetry past 24 session starts a day.** `services.gd` lines
  265-283. The server refuses a chunk with 422, and the client dropped the
  whole batch. RB-32, on main, already sends telemetry in chunks and drops
  only a chunk the server refuses.

### Smaller, not proven
- A sign-out during a telemetry send may drop events newer than the batch.
- A `RESUMED` with no `PAUSED` before it counts a crash.
- `accept_terms` has no busy guard.
- The planner does not clamp the load to the lease's limits. The server
  checks it.
- An unknown law becomes byte 255 in the island writer. The server refuses
  the island.
- An interior landing is labelled "east".
- Several minor layout and wording items in `heist_screen.gd`,
  `result_screen.gd` and the world views.

### Rejected
- A token whose `expiresIn` is under 60 s does not loop renewals.
- A tap that skips every backoff is by design (docs/security/auth.md
  line 200).
- The failure log keeps the query string, but only `list`, `limit` and
  `season` are ever in it.

### Checked and consistent
Route contracts with the server; the sage byte order; the fields of the
keeper, roster, hatch, map, first-heist and share features; the shop's buy
guard; the weaving busy guard; the outbox prefixes; the codex shapes;
`world_at` and `tile_at`; `TICKS_PER_SECOND`.

## What was read

| Slice | Files | Read |
|---|---|---|
| A | `client/features`: heist, planner, observatory, defences, roster, hatch, realm, keeper, map, first, share | every line |
| B | `client/features`: shop, social, workshop, curation, universe, weaving, harmony, lab, codex, profile, sages, forms, `law_presenter.gd` | every line |
| C | `client/app`, `client/core`, `client/data` and its repositories, `client/features/auth`, `client/ext/src/lib.rs` and `island.rs` | every line |
| D | `client/scripts`: `heist_screen.gd`, `result_screen.gd`, `planner_screen.gd`; the other scripts | the three in full, apart from `heist_screen.gd` 520-999; the rest skimmed |
| E | `client/world`: `world_view.gd`, `fx_ground.gd`, `fx_events.gd`, the overlay HUD, route, tiles and defence views, `universe_purse.gd`, `stage_scout.gd`, `universe_layout.gd` | every line |

### Still not read
- `client/world/island_builder.gd` and `universe_island.gd`.
- `client/ui`, apart from what slices D and E called (`kit_controls`,
  `kit_tabs` and most of the rest).
- `client/scripts/heist_screen.gd` lines 520-999 (layout).

### Notes for other tasks
- `server/src/main.mjs` lines 308-320: the `--example` fixture publishes
  the `example:universe` account's Heart and outer realm with `origin:
  "generated"`, owned by a seeded player account, not by
  `the-game-generator`. Its comment ("generated, never the lists' first
  authored target") still holds after CLI-11, because an authored island
  comes first. But after RB-06 and CLI-11 those islands count as a player's
  curated ones, ahead of the generator's. A test that wants a generated
  fallback target should publish under the generator's account.
