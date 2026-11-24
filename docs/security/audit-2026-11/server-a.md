# Server audit, November 2026: server A

FX1-6-audit-server-a's half of the fix wave's extra checks
([bug report](../bug-report-2026-11.md), [server half](server.md)). This
audit read the code the report did not: `service.mjs` (offline play and
eras included), `matchmaking.mjs`, `holds.mjs`, `crossings.mjs`,
`codex.mjs`, `workshop.mjs` and `fund.mjs`. It followed their calls into
`accounts.mjs`, `weaving.mjs`, `seasons.mjs`, `links.mjs`, `limits.mjs`,
`defences.mjs`, `observatory.mjs`, `offline.mjs`, `eras.mjs`,
`generator.mjs` and `glicko.mjs`.

Every confirmed finding has a test in
`server/test/fix_fx1_audit_server_a.test.mjs`, named by its id, that fails
on main (`9fe151ad`).

- **Fixed in this task's files:** the test passes with the fix.
- **In a file this task does not own:** the test asserts today's
  behaviour. A comment marks it with the finding's id, and the fix flips
  it. The lead has a request for each one in `docs/progress/status/FX1.json`.

| Id | Priority | Where | State |
| --- | --- | --- | --- |
| FX1-A-01 | High | matchmaking.mjs | fixed |
| FX1-A-02 | Medium | accounts.mjs | request FX1-R3 |
| FX1-A-03 | Medium | workshop.mjs | fixed |
| FX1-A-04 | Low | workshop.mjs | fixed |
| FX1-A-05 | Medium | holds.mjs | fixed |
| FX1-A-06 | Medium | matchmaking.mjs | fixed |
| FX1-A-07 | Medium | matchmaking.mjs | fixed |
| FX1-A-08 | Medium | matchmaking.mjs | fixed |
| FX1-A-09 | Low | matchmaking.mjs | contested, request FX1-R9 |
| FX1-A-10 | Low | limits.mjs | request FX1-R4 |
| FX1-A-11 | Medium | matchmaking.mjs | fixed |
| FX1-A-12 | Low | service.mjs | fixed |
| FX1-A-13 | Medium | service.mjs | partly fixed, request FX1-R5 |
| FX1-A-14 | Low | codex.mjs | fixed |
| FX1-A-15 | Low | seasons.mjs | request FX1-R6 |
| FX1-A-16 | Low | links.mjs | request FX1-R7 |
| FX1-A-17 | Low | weaving.mjs | request FX1-R8 |

## Confirmed

### FX1-A-01: An echo whose bytes are gone breaks every player's target list

- **Priority / category:** High, matchmaking (availability).
- **Where:**
  - `matchmaking.mjs` `fresh()`, the chapter helper:
    `chapterOf(lawsOf(this.service.store.get(bundle)))`.
  - An echo is a snapshot from the last 14 days that is no one's island.
    Its bytes can be gone (FX1-A-02).
- **Input:** player A, under 13, publishes bytes X that player B has also
  published, and B's snapshot is the first. B republishes, so X is an
  echo. A's account is deleted, which erases X's bytes.
- **Should happen:** §12.22: the echo is no target, because there is
  nothing to play, and every other candidate is still drawn.
- **Happens:** `lawsOf(null)` throws inside `fresh()`. `listed()`, the
  Observatory and the hourly list throw for every player until the echo
  ages out, 14 days later.
- **Evidence:** test "FX1-A-01". On main, `fresh` throws.
- **Fix (made):** `bundleChapter(bundle)` returns null for missing bytes
  and remembers nothing for them. `fresh()` passes over an echo whose
  chapter is null.

### FX1-A-02: An under-13 deletion erases bytes that another player's echo still is

- **Priority / category:** Medium, privacy / data (the cause of FX1-A-01).
- **Where:** `accounts.mjs` `erase()`.
  - It keeps a bundle's bytes while another player's island, Workshop
    island, link or lease still needs them.
  - It does not keep them for another player's snapshot.
- **Input:** as FX1-A-01.
- **Should happen:** §20.11 erases what is the child's. Bytes that are
  also another player's snapshot are that player's too, and stay.
- **Happens:** B's snapshot row stays, its bytes are gone, and B's echo
  cannot be played.
- **Evidence:** test "FX1-A-02". It asserts today's behaviour: the
  snapshot is B's and `bundle(X)` is null.
- **Fix (request FX1-R3):** add
  `UNION ALL SELECT 1 FROM snapshots WHERE bundle = :b AND owner != :a` to
  the bytes `erase()` keeps.

### FX1-A-03: Resolving a decided report again closes the island's newer reports unread

- **Priority / category:** Medium, moderation (§18.7, §20.4).
- **Where:** `workshop.mjs` `resolve()`. Resolving closes every open
  report on the island, and nothing stops a report already decided from
  being resolved again.
- **Input:**
  1. A moderator dismisses report R.
  2. Two days later the server files a `completion_spike` report on the
     same island.
  3. A stale moderation tab sends R's dismissal again.
- **Should happen:** the spike stays in the queue, and the island stays
  flagged for review.
- **Happens:** the spike is closed without anyone reading it, and the
  island is no longer flagged.
- **Evidence:** test "FX1-A-03".
- **Fix (made):** a decided report is refused another decision with
  404 `no_such_report`, the answer the client already has words for: the
  queue holds open reports only.

### FX1-A-04: Lone fans re-rating on a later day use up that day's lone-fan slots

- **Priority / category:** Low, Workshop ratings (SEC-26).
- **Where:** `workshop.mjs` `rate()`.
  - A re-rate moves `at` to today.
  - `counts()` measures the day's three lone-fan slots by `at`.
- **Input:**
  1. Three lone fans rate on day 1, and all three count.
  2. On day 2 they re-rate.
  3. A new lone fan rates on day 2.
- **Should happen:** the new fan counts. Re-rates add no counted fan.
- **Happens:** the re-rates fill day 2's three slots, and the new fan does
  not count.
- **Evidence:** test "FX1-A-04".
- **Fix (made):** a counted rating keeps the `at` of the day it first
  counted.

### FX1-A-05: After a rules upgrade, a live island's hold is never measured again

- **Priority / category:** Medium, holds (§13.3).
- **Where:** `holds.mjs`.
  - An island's hold is queued only at publish, under that day's rules.
  - `status()` and `work()` read only the current rules.
- **Input:** an island is measured. The server restarts on a new
  simulation build with new rules.
- **Should happen:** §13.3: the hold is measured under the rules the island
  is played under, and shows as "measuring…" until it lands.
- **Happens:** `status()` returns null, so the screen shows no hold. The
  queue never measures the island again unless it is republished.
- **Evidence:** test "FX1-A-05".
- **Fix (made):** `queueLive()` queues every live bundle once under the
  new rules. `status()` and `work()` call it.

### FX1-A-06: The defence log offers a Trace on a banned raider, and the lease refuses it

- **Priority / category:** Medium, backend (the defence-log side of
  [server.md](server.md)'s candidate 21).
- **Where:** `matchmaking.mjs` `traceable()`, which the defence log reads
  through `defences.mjs`. It never reads `accounts.banned_at` or
  `accounts.deleted_at`.
- **Input:** the raider robs the defender, and the Workshop then bans the
  raider.
- **Should happen:** no Trace button. The Observatory already offers none,
  and `lease(…, {trace: true})` refuses one.
- **Happens:** the defence log still offers the Trace, and tapping it is
  refused.
- **Evidence:** test "FX1-A-06".
- **Fix (made):** `traceable()` passes over a raider who is banned or
  deleted.

### FX1-A-07: A card swapped to a republished island can show laws from a chapter the raider has not opened

- **Priority / category:** Medium, matchmaking (§7.6).
- **Where:** `matchmaking.mjs` `current()`.
  - Within the hour, a card whose island was republished is swapped to the
    new bundle.
  - The list was filtered by chapter, but the new bundle's chapter is
    never checked.
- **Input:** a chapter-1 raider's list holds the defender's chapter-1
  island. The defender republishes the realm with Haste, a chapter-2 law.
- **Should happen:** §7.6: "Matchmaking only shows universes running laws
  from open chapters."
- **Happens:** the chapter-2 island is offered to the chapter-1 raider.
- **Evidence:** test "FX1-A-07".
- **Fix (made):** the swapped card carries its new bundle's chapter.
  - `current()` cannot read the raider, so it drops a swap whose chapter is
    above the card it replaces, or whose bytes are gone.
  - The island comes back in the next hourly list, filtered as usual.

### FX1-A-08: "Recent success" learns from raids that rated nothing

- **Priority / category:** Medium, matchmaking (G30, G37).
- **Where:** `matchmaking.mjs` `recentSuccess()`. It reads every validated
  raid, including a pair's later raids that UTC day and raids on an island
  whose owner is gone. `grant()` rates neither (`rating: null`).
- **Input:** a raider is foiled by a defender, then robs the same defender
  cleanly three times the same day.
- **Should happen:** the band is steered by the heists the rating learns
  from. One rated heist was foiled, so recent is 0.
- **Happens:** recent is 0.75. The raider's band moves on raids G37 keeps
  out of the rating, which is the farming G37 closes.
- **Evidence:** test "FX1-A-08".
- **Fix (made):** `recentSuccess()` reads only heists whose outcome has a
  rating.

### FX1-A-09: The list says it reached for echoes when there was none to reach for

- **Priority / category:** Low, matchmaking telemetry (§12.22).
  **Contested.**
- **Where:** `matchmaking.mjs` `offer()`. On a thin list it sets
  `echoes = true` whether or not an echo was among the candidates.
- **Input:** `offer(raider, [two authored candidates])`, with no echo.
- **Should happen:** if `echoes` means "an echo was reached for", it
  should be false, as `generated` is false when there is no generated
  island.
- **Happens:** `echoes` is true.
- **Evidence:** test "FX1-A-09 (contested)". It asserts today's behaviour.
  `server/test/generated.test.mjs:56` ("echoes first") asserts the same,
  with no echo candidate. The fix broke that test, so it was not kept.
- **Fix (request FX1-R9):** the lead decides what the flag means. If it
  means an echo was there, use
  `if (!enough(pool) && authored.length > liveOnly.length)` and change
  generated.test.mjs's line with it.

### FX1-A-10: IPv4-mapped addresses in hex or full form share one rate-limit bucket

- **Priority / category:** Low, rate limits.
- **Where:** `limits.mjs` `peerKey()`. Only the dotted `::ffff:a.b.c.d`
  form is read as IPv4.
- **Input:** `::ffff:c633:6407`, `0:0:0:0:0:ffff:198.51.100.7` and
  `::ffff:cb00:7101`.
- **Should happen:** the code's comment says "an IPv4 address as it is",
  so the keys should be `198.51.100.7`, `198.51.100.7` and `203.0.113.1`.
- **Happens:** all three give `0:0:0:0::/64`. Every caller whose address
  arrives in these forms shares one `failedSignIns` bucket and one
  `unsigned` bucket.
- **Reach:** doubtful. `cf-connecting-ip` and nginx's `$remote_addr`
  normally give the dotted form.
- **Evidence:** test "FX1-A-10". It asserts today's behaviour.
- **Fix (request FX1-R4):**
  - Expand the address to eight groups; a dotted tail counts as two.
  - If the first five groups are 0 and the sixth is `ffff`, key it as the
    dotted IPv4 address.
  - Otherwise take the /64 as now.

### FX1-A-11: A refused Trace upload uses up the Trace

- **Priority / category:** Medium, backend (the Trace's side of RB-16).
- **Where:**
  - `matchmaking.mjs` `traceable()` counts any Trace lease as the Trace
    used, even one whose only upload was refused.
  - `service.mjs` `lease()` then refuses the ask.
- **Input:**
  1. The raider robs B.
  2. B leases the Trace.
  3. B submits ten junk bytes, which are refused as `replay_malformed`.
  4. B asks for the Trace again.
- **Should happen:** §12.3: B "can target the raider once". §24.13: an
  unsubmitted heist reserves nothing. Read as RB-16 reads it, a refused
  upload is not a play.
- **Happens:** 403 `nothing_to_trace`. The Trace is lost for good.
- **Evidence:** test "FX1-A-11".
- **Fix (made):** `traceable()` passes over Trace leases whose uploads were
  all refused. A live Trace lease not yet played still counts as the
  Trace.
  - The plainer `validated = 1` form would break defences.test.mjs ("Traced
    once, the raid offers no Trace again").

### FX1-A-12: A lease at exactly `expires_at` has run out for `issue` but is live for `submit`

- **Priority / category:** Low, backend (boundary; §24.12, G17).
- **Where:** `service.mjs`.
  - `issue()` holds a lease only while `expires_at > now`.
  - `submit()` treats it as run out only when `now > expires_at`.
- **Input:**
  1. The raider takes lease L1.
  2. At exactly `L1.expiresAt`, the raider leases the target again and
     gets L2.
  3. The raider submits L1.
- **Should happen:** a lease that `issue` treated as run out is submitted
  only on the day's one grace.
- **Happens:** L1 is accepted as live, with grace 0. The raider holds L2
  and still has the day's grace. The window is 1 ms.
- **Evidence:** test "FX1-A-12".
- **Fix (made):** `submit()` checks `now >= lease.expires_at`.

### FX1-A-13: A raid on the second publisher of shared bytes is rated in the first publisher's realm

- **Priority / category:** Medium, ratings (§12.22).
- **Where:** `service.mjs` `grant()` passes `snapshot.realm` to `settle()`.
  The snapshot is one row per bundle, owned by its first publisher, so its
  realm is theirs.
- **Input:**
  1. A publishes bytes X in the heart.
  2. B publishes the same X in outer-1.
  3. The raider leases X naming B, and the raid validates.
- **Should happen:** B's outer-1 island plays the rated game.
  `targetLists` says of shared bytes that "each is a target of their own".
- **Happens:**
  - B's outer-1 rating stays at 0 games.
  - A B/heart rating row is made, for an island B never published.
  - If B has a real heart island, its rating is moved instead.
- **Evidence:** test "FX1-A-13".
- **Fix (made in part):** for a raid that is not an echo, `grant()` takes
  the realm of the defender's own island on that bundle. It prefers the
  snapshot's realm when the defender has an island there, and falls back
  to the snapshot's realm.
  - The exact fix (request FX1-R5) stores the realm on the lease at
    `issue()`, in a new `leases.realm` column in `db.mjs`, which this task
    does not own. Without it, a defender who republishes before the raid
    settles is rated in the realm the bundle is now in, if any.

### FX1-A-14: A law cast in both slots of a foiled heist gives the defender two pages

- **Priority / category:** Low, Codex (§7.6).
- **Where:** `codex.mjs` `afterHeist()` adds one page per cast.
  `keeper.planProblem` checks only the number of casts, so the same law can
  fill both slots (Keeper level 12, §12.5).
- **Input:** a foiled heist that cast `half_gravity` twice.
- **Should happen:** §7.6: "the defender gets one page of it".
- **Happens:** two pages.
- **Evidence:** test "FX1-A-14".
- **Fix (made):** one page for each law cast, counting each law once.

### FX1-A-15: The constellation league answers [] for an open season and for a season that never was

- **Priority / category:** Low, seasons.
- **Where:** `seasons.mjs` `constellationTable()`. `result()` refuses both
  cases.
- **Input:** `constellationTable(1)` while season 1 is open, and
  `constellationTable(99)`.
- **Should happen:** the same answers as `result()`: 409
  `season_still_open` and 404 `no_such_season`.
- **Happens:** `[]` for both, which looks like a season nobody placed in.
- **Evidence:** test "FX1-A-15". It asserts today's behaviour.
- **Fix (request FX1-R6):** refuse as `result()` does.

### FX1-A-16: A link's number is given again, so a retried DELETE takes down the next link

- **Priority / category:** Low, universe links.
- **Where:** `links.mjs`. A new link's number is one past the highest
  number in use, so removing the newest link frees its number.
- **Input:**
  1. Build a Rope Bridge (number n), and remove it.
  2. Build a Chute, which gets number n.
  3. The first DELETE is retried.
- **Should happen:** the retry finds nothing to take down.
- **Happens:** the retry takes the Chute down.
- **Evidence:** test "FX1-A-16". It asserts today's behaviour.
- **Fix (request FX1-R7):** a counter that only goes up.

### FX1-A-17: A weave taken out before it finishes counts as a mastery step

- **Priority / category:** Low, Codex mastery.
- **Where:** `weaving.mjs` marks the law woven in the Codex
  (`codex.woven`) when the weave starts.
- **Input:** weave `half_gravity` into the heart, unweave it before it
  finishes, and wait two hours.
- **Should happen:** a law counts once its weaving has finished.
- **Happens:** the Motion school's steps read 1.
- **Evidence:** test "FX1-A-17". It asserts today's behaviour.
- **Fix (request FX1-R8):** call `codex.woven` when the weave finishes.
  `server/test/codex.test.mjs:211` expects the step at the start and
  changes with the fix.

## Unproven

- **Renown pulled back once over several skipped seasons**
  (`seasons.mjs` `standing`, `pulledBack`).
  - What happens: Star+100 in season 1, absent through seasons 2 and 3,
    gives Star+50 in season 4.
  - For a defect: §18.1 pulls Renown back "at the end of a season", and
    seasons run back to back, which would mean three pull-backs.
  - Against: the code's comment says the pull-back is "from the last
    season they played", and an absent player gets no season rewards
    either.
  - This needs a design call (request FX1-R10, default: one pull-back). No
    test is committed.
- **The 13-15 friends-only crew rule is checked only on the joiner**
  (`social.mjs` `joinCrew`). An adult who is a friend of one member can
  join a crew holding a 13-15 player who is not their friend.
  - Against: §20.7's "Co-op heists: Friends only".
  - For: owner decision B4 records only "for a player aged 13 to 15, a
    friend of every member", and `security_owner.test.mjs`'s SR-14
    asserts that this adult joins.
  - This is the owner's recorded rule, so it needs the owner's word, not a
    code change. No test.
- **Curated wards and posts keep an island's generated origin.** §13.3's
  "authored once its terrain is edited" names only terrain, and the
  simulation's comment agrees. Ambiguous, so no test.

## Rejected

### service.mjs, offline play and eras

- **A banned defender is still paid and rated:** `grant`'s `gone` checks
  only `deleted_at`, but nothing comes of it.
  - There is no unban path, and sign-in refuses a banned account.
  - `notifications.raided` skips banned defenders.
  - Settling a raid already leased is kept on purpose.
- **Raid and Trace leases never check blocks:** deliberate. `safety.mjs`
  says, after §17.8, that blocked players' islands "stay each other's
  targets".
- **A Trace used up by an expired, unplayed lease:** cannot happen. The
  Trace lease is issued after the raid and lives 24 hours, the same window
  as `traceable`'s.
- **Crashes on an erased account's row:** erasure is an UPDATE, so the row
  stays.
- **The unguarded `lawsOf(store.get(lease.bundle))` reads FX1-4 left for
  this audit** (`codex.mjs` `afterHeist`, and two in `service.mjs`'s
  settlement): they would throw if a bundle were erased between lease and
  submit. `erase()` keeps no bytes for a lease on the erased defender's own
  island. But `submit()` reads the bytes first and refuses
  `island_withdrawn` when they are gone. The three reads follow in the same
  synchronous call, so no erase can come between. The fourth read,
  `matchmaking.mjs`'s chapter, is FX1-A-01.
- **Workshop plays deleted at expiry:** intended.
- **Offline actions:** the shapes in `offline.mjs` match the client's
  queue.
- **Eras:** the order and the Quiet Week match `sim/src/era.rs`.

### workshop, holds, fund, crossings, generator, glicko

- **Featuring skips the hold-band check:** the documented open gap D62
  (`docs/design/dependencies.md`).
- **The featured list never expires:** the design gives no spotlight
  length, and `browse('featured')` takes the newest 20 by design.
- **The first resolve closes every open report:** intended (the code's
  comment and RB-39's test). Only the repeat is a defect (FX1-A-03).
- **`work()` returns the raids asked for when nothing was played:**
  `main.mjs` ignores the return, and a bundle whose bytes are gone is
  marked lost (`held = -1`).
- **The clamp uses `facts.HOLD_RAIDS`:** every production row has that many
  raids. Only tests shorten it.
- **`played` written whole while `held` is added to:** one process, a
  synchronous `node:sqlite` and a single `setInterval` worker, so there is
  no second worker.
- **The fund's `report.held` units:** `sim/src/universe.rs` gives seconds,
  which `fund.mjs` expects.
- **Crossings, generator and Glicko:** no defect found. Glicko-2 matches
  the paper, including the Illinois algorithm.

### codex, weaving, seasons, links, track

- **Raids past the week's cap still pay pages:** §9.6 and §12.9 cap only
  the haul.
- **The rollover gives results and cosmetics to deleted accounts:** §20.12
  keeps season results severed, and nothing reaches them.
- **A retried link build gets 409 `already_linked`:** the answer is true,
  nothing is charged twice, and the client never retries the route.
- **`links.view` writes while reading:** the documented lazy migration,
  done synchronously.
- **A law released after launch can be the working law:** its pages build
  up for a later season's chapter ("nothing expires forever", §18.8).
- **A track claim is not idempotent:** the client re-sends only after
  `session_refused`, which means the first was never processed.
- **Mastery "crossed" steps count echoes and repeat heists:** the design
  doesn't tell them apart.
- **Seasons that pass while the server is down are never created:** this
  needs the server down for a whole season. Not pursued.

### matchmaking, defences, social, push, keeper, economy

- **The defence log shows the raider's current Keeper level:** §13.2,
  §23.2 and §24.3 don't say at-raid or current, and no at-raid level is
  stored.
- **A validly signed token whose session has ended drains the rate
  limits:** the deliberate G44 design ("limited by the token's signature
  before the account is read"). It touches only that player's own bucket,
  and only until the token expires.
- **`friends.accept` throws when the inviter's row is missing:**
  unreachable. Account rows are never deleted, and invites go on delete
  and on ban.
- **`safety.block`'s header says it closes invites and challenge links,
  but it deletes only friendships:** both are checked again at use
  (`friends.accept` and `service.challenge` read `safety.between`).
- **`push.mjs` `data.latest = heists.at(-1)`:** `notifications.raids()`
  orders oldest first, so it is the latest.
- **`keeper.planProblem`'s Sage indexing, and `economy.mjs`:** nothing
  contrary to the design or the code's comments.
- **`defences.mjs` `RAIDED` doesn't leave out seeded defenders:** it is the
  defender's own log, so it has no effect.
