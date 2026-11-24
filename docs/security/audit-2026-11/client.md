# Client audit, November 2026

The client half of the fix wave's extra checks
([bug report](../bug-report-2026-11.md), task FX4-4-audit-client). It covers
the Godot client code the report did not read: `client/features` beyond the
auth and network files, `client/core`, `client/app`, `client/data` and
`client/ext`. `client/scripts`, `client/world` and `client/ui` were read for
the paths these lead into; they are read-only for this task, apart from
`client/scripts/result_screen.gd`. It also settles the report's five client
suspicions.

A second pass, task FX3-7-audit-client-2, proved or rejected the findings
FX4-4 left unproven (CLI-3, CLI-8, CLI-9, CLI-16, CLI-17, CLI-19, CLI-20 and
CLI-21), and read the client code FX4-4 did not: `client/world/island_builder.gd`,
`client/world/universe_island.gd`, `client/ui` and `heist_screen.gd` lines
520-999. Its proofs are still-open checks in
`client/tests/audit_client2_tests.gd`, written on `claude/fix-sim`; it fixes
nothing. For CLI-8 and CLI-9 it read `server/src` to settle which side is
wrong against the design.

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
| CLI-3 | High | frontend-backend contract | `client/scripts/heist_screen.gd play_stocked` | An offline heist plays three default crew and submits the planner's crew | proven, open |
| CLI-4 | High | frontend/UI | `client/data/draft.gd start_remix` | A second remix overwrites the player's own kept island | fixed |
| CLI-5 | Medium | security | `client/features/auth/auth_session.gd sign_out` | A sign-out whose access token the server refuses never falls back to the refresh token | fixed |
| CLI-6 | Medium | frontend/UI | `client/features/curation/curation_controller.gd preview_swap` | A second swap previewed keeps the first swap's law on the draft | fixed |
| CLI-7 | Medium | frontend/UI | `client/features/curation/curation_controller.gd preview_swap` | A swap that changes nothing on the island is still woven and paid | fixed |
| CLI-8 | Medium | frontend-backend contract | `client/features/planner/planner_controller.gd start`, `server/src/service.mjs lease` | A Trace or target leased with no owner raids the bundle's first holder, not the one shown | proven, open |
| CLI-9 | Medium | frontend-backend contract | `client/features/defences/defences_controller.gd trace`, `server/src/defences.mjs` | A Defences Trace is leased as the Heart alone, though the raider has a universe | proven, open |
| CLI-10 | Medium | frontend/UI | `client/features/realm/realm_controller.gd load_realm` | A late realm load shows one realm's island under another | fixed |
| CLI-11 | Medium | frontend/UI | `client/data/repositories/heist_repository.gd first_target` | The target fallback treats a player's curated island as the game's own | fixed |
| CLI-13 | Medium | integration | `client/data/outbox.gd _read` | One malformed outbox item stops every flush, so nothing behind it is ever sent | fixed |
| CLI-14 | Medium | integration | `client/app/app_lifetime.gd` | `notices.seen()` is never called, so a crashed session reports 0 seconds | fixed |
| CLI-15 | Medium | frontend/UI | `client/scripts/result_screen.gd _study` | A study tile tapped twice sends two studies | fixed |
| CLI-16 | Medium | frontend/UI | `client/world/world_view.gd _sync_skiff` | A replay shows its last skiff and goal ring from tick 0 | proven, open |
| CLI-17 | Medium | frontend/UI | `client/world/world_view.gd show_replay` | A replay of a larger crew, shown after a smaller one, keeps the old figures | proven, open |
| CLI-18 | Medium | frontend/UI | `client/scripts/stage_rehearsal.gd` | A style card tapped while another crew plays shows that crew's result under the new card | proven, open |
| CLI-19 | Medium | integration | `client/features/weaving/weaving_presenter.gd` | Two offline weaves aim at the same free slot, so the second is refused | proven, open |
| CLI-21 | Medium | frontend/UI | `client/features/roster/roster_controller.gd collect_all` | The roster's collect has no busy guard, and clears another change's | proven, open |
| CLI-22 | Low | security | `client/core/action_log.gd add` | The action log keeps account ids | fixed |
| CLI-24 | Low | frontend/UI | `client/features/social/social_controller.gd load_friends` | A failed blocks call empties the blocked list on screen | fixed |

FX3-7's second pass proved CLI-3, CLI-8, CLI-9, CLI-16, CLI-17, CLI-19 and
CLI-21, and rejected CLI-20 (see "Rejected"). CLI-23 is still not proven:
see "Unproven". CLI-12 is covered by RB-32, already on main.

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

### CLI-3: An offline heist plays three default crew and submits the planner's crew
- **Priority / category:** High / frontend-backend contract.
- **Where:** `client/scripts/heist_screen.gd` `play_stocked`, lines
  161-170, against the online start (lines 242-253) and `finish` (line
  291), with `client/data/repositories/heist_repository.gd`'s submission.
- **Input:** the player plans a heist of four characters, taps Start, and
  the device has no network, so a stocked lease is played (§24.12).
- **Should happen:** §12.5: the plan is the heist's crew, offline as online.
  The heist plays the four, with their manifest, and the submission names
  them.
- **Happens:** `play_stocked` begins with `HeistController.CREW` (three)
  and no manifest. `finish` still submits the plan's ids as
  `?crew=12,15,19,21`. On reconnection `server/src/home.mjs` line 665
  refuses it `crew_mismatch`, and the haul is lost. With a three-character
  plan the server takes it, and rests characters that played as nobody.
- **Proof:** `_offline_heist_plays_another_crew`, a still-open check in
  `client/tests/audit_client2_tests.gd`. Played offline: crew 3, submitted `?crew=12,15,19,21`.
- **Fix (not applied):** `play_stocked` takes the crew size and manifest
  from the plan, as the online start does.

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

### CLI-8: A Trace or target leased with no owner raids the bundle's first holder, not the one shown
- **Priority / category:** Medium / frontend-backend contract (cause mostly
  on the server).
- **Where:** `client/features/planner/planner_controller.gd` `start`,
  lines 87-95, which dispatches the target as `{bundle, trace, across}`.
  On the server, `server/src/observatory.mjs` `card` gives no owner, and
  `server/src/service.mjs` `lease`, line 458, picks `holders[0]` (the
  lowest account id) when none is named. The Defences Trace
  (`client/features/defences/defences_controller.gd` line 70) is the same.
- **Input:** two accounts hold one bundle (identical bytes, such as an
  unchanged remix). The Observatory shows the second holder's island, and
  the player raids it.
- **Should happen:** §12.4 and §12.5: the heist is played against the
  island and player the card showed. A Defences Trace (§12.3) leads to the
  raider.
- **Happens:** the lease goes to the first holder by account id. The raider
  plays someone else, and their universe: `crossings.of` reads that
  holder's links, so it may be the Heart alone. A Defences Trace of a
  raider who shares their island with a lower id holder is refused `403
  nothing_to_trace`, because `matchmaking.traceable` is checked against the
  first holder. A server scratch test (not committed) showed all three.
- **Proof:** `_planner_drops_the_cards_owner`, a still-open check in `client/tests/audit_client2_tests.gd`:
  a card that names its owner is started with no owner. The server's half
  has no client test; see "Notes for other tasks".
- **Fix (not applied):** on the server, the card carries its owner and
  `lease` uses it (or picks the holder the attacker's list offered), and
  the Defences view's trace names the raider. On the client, the planner
  and the Defences controller pass the owner on to the lease.

### CLI-9: A Defences Trace is leased as the Heart alone, though the raider has a universe
- **Priority / category:** Medium / frontend-backend contract (cause on
  both sides).
- **Where:** `server/src/defences.mjs` line 74 sends `trace: {bundle}`,
  with no `across`. `client/features/defences/defences_controller.gd`
  `trace`, line 70, starts the target `{bundle, trace: true}`, and
  `heist_screen.gd` line 237 leases with `universe` false.
- **Input:** a raider's realms make a universe. The defender taps Trace on
  the raid in Defences.
- **Should happen:** §12.3 and §5.4: the Trace leads to the raider's
  universe, and the crew lands on an outer realm's edge (skiffs cannot land
  on the Heart). The Observatory's trace card of the same raider says
  `across: true`.
- **Happens:** the lease asks no universe, so the server issues the Heart
  alone. The scratch test showed `universe: null` as sent, and a universe of
  two realms when `universe: true` is asked.
- **Proof:** `_defences_trace_drops_across_and_owner`, a still-open check
  in `client/tests/audit_client2_tests.gd`: the target started is `{bundle, trace: true}`, whatever the trace
  says.
- **Fix (not applied):** `defences.mjs` adds `across` (and the owner, CLI-8)
  to the trace, and the controller passes them on. Or the client asks a
  universe for every Trace: the server answers the Heart alone when there is
  none.

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

### CLI-16: A replay shows its last skiff and goal ring from tick 0
- **Priority / category:** Medium / frontend/UI.
- **Where:** `client/world/world_view.gd` `_sync_skiff`, lines 732-747, and
  `client/world/fx_ground.gd` `order_goal`, line 171.
- **Input:** a replay in which crew member 1 calls the skiff, and member 0
  is sent to a goal, at tick 100. The player watches it from the start.
- **Should happen:** §5.4 and §21.8: the skiff shows once the Get out calls
  it, and the goal ring once the crew member is sent.
- **Happens:** both read the replay's commands from the end of its log, with
  no look at the tick. While a heist is played the log ends now, so that is
  right. A replay holds every command from the start, so at tick 0 the
  skiff already hovers where it is called at tick 100, and the ring marks a
  goal not yet given.
- **Proof:** `_replay_shows_orders_from_its_end`, a still-open check in
  `client/tests/audit_client2_tests.gd`. At tick 0 the skiff is shown and
  the ring is at (8, 8).
- **Fix (not applied):** both take the last command at or before the
  current tick.

### CLI-17: A replay of a larger crew, shown after a smaller one, keeps the old figures
- **Priority / category:** Medium / frontend/UI.
- **Where:** `client/world/world_view.gd` `show_replay`, lines 271-283.
- **Input:** a three-crew replay, then a five-crew replay of the same
  island, shown in one `WorldView`.
- **Should happen:** §21.8: every crew member is drawn.
- **Happens:** the view rebuilds its statics, and with them the figures
  (`_build_statics` calls `_build_actors`, line 341), only when its key
  changes. The key is the island's size, features, heights, surfaces and
  realm, not the crew. Three figures stay, and two of the crew are never
  drawn.
- **Proof:** `_replay_of_another_crew_keeps_the_old_one`, a still-open
  check in `client/tests/audit_client2_tests.gd`: three figures after the five-crew replay, where a
  view that shows it first has five.
- **Fix (not applied):** the crew size (and roles) join the key, or the
  figures are rebuilt on their own when the crew changes.

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

### CLI-19: Two offline weaves aim at the same free slot, so the second is refused
- **Priority / category:** Medium / integration.
- **Where:** `client/features/weaving/weaving_presenter.gd` lines 110-113
  and 166, with `client/features/weaving/weaving_state.gd`'s `queued`.
- **Input:** the Heart has two free slots. With no network, the player
  weaves Stillness and then Bloom.
- **Should happen:** §24.12 and §5.6: both are queued and confirmed on
  reconnection, one in each slot.
- **Happens:** a queued weave leaves the view as it was, and the presenter
  aims every offer at the first free slot of the view. Both weaves name
  slot 1. On reconnection the server weaves the first and refuses the second
  `slot_taken`, though slot 2 was free.
- **Proof:** `_offline_weaves_aim_at_one_slot`, a still-open check in `client/tests/audit_client2_tests.gd`.
  The fake keeps slot state as the server does: slots sent `[1, 1]`, the
  second refused `slot_taken`.
- **Fix (not applied):** a queued weave marks its slot as taken in the
  view, so the next offer aims at the next free slot.

### CLI-21: The roster's collect has no busy guard, and clears another change's
- **Priority / category:** Medium / frontend/UI.
- **Where:** `client/features/roster/roster_controller.gd` `collect_all`,
  lines 91-106, against the guard of the other changes (line 109), and
  `client/features/roster/roster_state.gd`'s `change_made`.
- **Input:** a level is on its way (slow network) when the player collects;
  or the Home screen is left and opened again while a collect is on its way
  (its new button is enabled, `client/scripts/home.gd` line 718), and
  collected again.
- **Should happen:** §9.3 and §11.4: one change at a time. A level is sent
  once, and each producer is collected once.
- **Happens:** the collect dispatches `roster_changed`, which clears the
  level's busy flag, so a second tap sends the level again while the first
  is still on its way. Two collects at once both go out.
- **Proof:** `_collect_all_clears_another_changes_busy`, a still-open check
  in `client/tests/audit_client2_tests.gd`, with a fake that answers late: busy cleared, the level sent twice,
  two collects sent.
- **Fix (not applied):** `collect_all` takes the busy guard like the other
  changes, and leaves another change's flag alone.

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
- **CLI-20: offline builds of one building collapse into one outbox key.**
  Rejected by FX3-7. The key names every field of the action
  (`client/features/universe/universe_controller.gd` line 52: realm, kind,
  n and level), and the outbox keeps the first of two items with one key
  (`client/data/outbox.gd` line 35). A queued build leaves the view as it
  was, so a second tap on the same button is the same action, which the
  server would refuse `not_the_next_level` (`server/src/universe.mjs` line
  267). A build of another building, or to another level, has its own key
  and is kept. The plain check `_offline_builds_of_one_building`, in
  `client/tests/audit_client2_tests.gd`, holds it.

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
- CLI-8, on the server: `server/src/observatory.mjs` `card` gives no owner,
  and `server/src/service.mjs` `lease` (line 458) leases `holders[0]` when
  the lease names none. When two accounts hold one bundle, the raid goes to
  the lower account id, its universe comes from that holder's links, and a
  Defences Trace of the other holder is refused `403 nothing_to_trace`. The
  card, the Defences view's trace and the lease should name the holder
  shown.
- CLI-9, on the server: `server/src/defences.mjs` line 74 gives the trace
  as `{bundle}`, with no `across`, where `observatory.mjs` `trace` has it.
- `observatory.mjs` `card`'s `across` reads false on its first call for a
  universe whose links are not yet ensured, and true after: it depends on
  what was asked before. Seen in FX3-7's server scratch test; not proven
  with a committed test, as `server/` is not this task's.
