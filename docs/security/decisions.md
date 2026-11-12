# Security decisions

The choices made for the findings of the deep security run (SEC-n) that
needed a decision rather than a plain fix: what was chosen, and why. The
recommended option was taken in each case; where a detail was left open, the
safer reading was chosen, and it is marked **detail**. Every change has a test
that failed before it and passes after; the test is named in each entry.

This is the record of these choices only. The SR-n findings are in
[`review.md`](review.md), and sign-in's design is in [`auth.md`](auth.md).

## Replays and leases

### SEC-18 B: what is kept of a refused replay

- **Chosen:** a replay's bytes are hashed when they arrive and stored only
  once its header checks pass (well formed, island, seed, clock, era, lease
  time). A refusal after that point is stored while the account's day (UTC)
  holds less than 2 MiB of stored replay bytes (`REPLAY_BYTES_A_DAY`); past
  that, it is settled with nothing stored. Refused replays are kept 7 days
  (`REFUSED_KEEP_DAYS`), validated ones 90.
- **Why:** junk bytes cost the server disk for every refused upload. A
  refusal worth keeping is one past the cheap checks, and a daily quota bounds
  what any one account can make the server hold.
- **Detail:** the quota counts every byte stored that day, validated replays
  too; low disk on a refusal stores nothing instead of answering 503. A
  validated heist is always stored.
- **Tests:** `server/test/security_deep_heists.test.mjs`, "SEC-18 B". SR-08 in
  `security_heists.test.mjs` expected 200 for junk bytes and now expects 410.

### SEC-25 B: refusing a lease and asking again

- **Chosen:** when an account's newest lease on a target was settled by a
  refusal and would still be live, the next lease keeps its seed (a new token
  and expiry). At most 10 refusals a day (`MAX_REFUSALS_A_DAY`); past that,
  429 `too_many_refusals` on any new lease.
- **Why:** refusing a lease and taking a new one rerolled the seed until a
  favourable draw came up. Keeping the seed takes the reroll away; the daily
  cap bounds what is left.
- **Tests:** `security_deep_heists.test.mjs`, "SEC-25 B".

### SEC-22: the pace a tile may carry

- **Chosen:** only the paces the rules define, 0 (normal), 60 (mud) and 115
  (a fast path). Any other byte is `Malformed::Pace`, answered 400
  `island_malformed`; 100 is still refused as a second encoding of normal.
- **Why:** any byte decoded, so a hand-edited island could set every tile to
  1% of normal speed, slower than an honest editor can make one. The set was
  checked against the format, the tile rules, the generator and the tests.
- **Tests:** the simulation's `a_pace_the_rules_do_not_define_is_refused`;
  `server/test/security_deep_sim.test.mjs`, "SEC-22". The WebAssembly build was
  remade; the client's native library keeps the old decoding until its next
  build.

## Rewards and ratings

### SEC-24: friendly heists

- **Chosen:** the first friendly heist between two players in a UTC day pays
  pages and may roll a stray; later ones that day pay neither. A friendly heist
  needs a crew manifest (`crew_required`).
- **Why:** two friends could trade friendly heists all day for pages and
  strays. A crewless submission skipped the crew checks.
- **Detail:** the pair is unordered: A on B then B on A the same day pays
  once, not once each way.
- **Tests:** `security_deep_heists.test.mjs`, "SEC-24".

### SEC-39: later raids of a pair the same day

- **Chosen:** only a pair's first raid of a UTC day moves either player's
  rating. Later ones are not rated; their haul and Keeper XP are unchanged.
- **Why:** two accounts could raid each other repeatedly to move a rating by
  arrangement. The haul already has its own caps.
- **Tests:** `security_deep_heists.test.mjs`, "SEC-39". `db_writes.test.mjs`
  raided one pair 21 times; each raid now has its own defender, with the same
  assertions.

### SEC-26: who counts for Workshop numbers and Fund time

- **Chosen:** a completion, rating or play counts only from an account at
  least 7 days old at Keeper level 3 or more, recorded when it happens in a
  `counted` column (default 0). Of accounts that have played no other
  creator's island, at most 3 a UTC day count for one creator
  (`LONE_FANS_A_DAY`). The ladder, the view's numbers, browse's "top" and the
  Fund read only counted rows; the view shows the rest as `uncounted`.
- **Why:** new accounts made for the purpose could lift an island's numbers
  and its creator's Fund time.
- **Detail:** qualification is fixed when the row is written, so an account
  farmed today does not start counting when it ages. The shape and size of the
  per-creator cap were chosen here.
- **Tests:** `server/test/security_deep_social.test.mjs`, "SEC-26".

### SEC-41: listing another creator's island unchanged

- **Chosen:** publishing is refused, 409 `already_published` (or
  `remix_unchanged` for a remix), when another creator has an item with the
  same island that is listed or was taken down. A creator may list their own
  island again, and one its creator withdrew does not block.
- **Why:** a copy of someone else's island could be listed as one's own.
- **Tests:** `security_deep_social.test.mjs`, "SEC-41". Three tests that used
  one island under two creators as a fixture now use changed bytes or a
  withdrawn item; their assertions are unchanged.

## Purchases

### SEC-29 A: a receipt whose intent is gone

- **Chosen:** when a lapsed intent is deleted, a tombstone with the intent's
  id and account only is kept for 90 days. A receipt naming it is granted only
  to that account; anyone else gets 409 `intent_mismatch`.
- **Why:** after the intent was deleted, anyone holding the receipt could
  redeem it. The tombstone keeps nothing about the purchase, which fits the
  rule that lapsed intents are deleted.
- **Detail:** a tombstone skips the product check, since no product is kept.
  On account deletion it is kept with an id that leads to no one, so a deleted
  buyer's receipt goes to no one else. On the client, a request whose renewal
  changed the account is not sent (`account_changed`).
- **Tests:** `security_deep_shop.test.mjs`, "SEC-29"; the client's
  `auth_tests.gd`.

## Sign-in, devices and the server's start

### SEC-36: fetching Game Center keys

- **Chosen:** a Game Center key name more than 3 past the highest one fetched
  for its kind is refused without a fetch. The highest moves only for a
  certificate that chains to the pinned roots and names Apple. Fetches of new
  names are limited per address, and a production server does not start
  without `RULEBORN_PEER_HEADER`.
- **Why:** any caller could make the server fetch a new key name from Apple
  at will. Without the proxy's address header, every caller shares one limit.
- **Tests:** `security_deep_http.test.mjs`, "SEC-36". SR-20 in
  `security_t11.test.mjs` walked names the window now refuses, so it passed
  without testing anything; it now walks names that are fetched.

### SEC-37: where the push token lives

- **Chosen:** the token stays on the account with the session that registered
  it (`push_session`). It is cleared when that session signs out and on sign
  out everywhere.
- **Why:** a phone that signed out kept receiving the account's
  notifications.
- **Detail:** a token with no registering session is cleared at any sign-out
  (the client reports it again); delivery skips a token whose session has
  ended.
- **Tests:** `security_deep_social.test.mjs`, "SEC-37".

### SEC-38: the deletion journal beside the data

- **Chosen:** with real sign-in, the server refuses to start when
  `RULEBORN_DELETIONS` is `RULEBORN_DATA` or inside it, the default included.
  With stubbed sign-in it starts, with a warning.
- **Why:** restoring a backup of the data folder would bring back the journal
  of deletions with it, and with it accounts that were deleted.
- **Detail:** the data folder itself is refused as the journal too.
- **Operators:** set `RULEBORN_DELETIONS` to storage that is not restored with
  the data before upgrading, or the server will not start.
- **Tests:** `security_deep_timers.test.mjs`, "SEC-38".

### Cache-Control on the account deletion page

- **Chosen:** no change. The page already answers `cache-control: no-store`,
  and `auth_http.test.mjs` holds it there.
- **Why:** each serving mints a nonce and sets a cookie, so a shared cache
  could hand one visitor's nonce to the next. The design's
  `public, max-age=3600` stays rejected.

## Groups

### SEC-43: constellations

- **Chosen:** the founder may remove an elder or a member, and an elder a
  member (POST `/v1/constellations/:id/remove`). A removed player cannot join
  that constellation again for 7 days (`REMOVED_DAYS`); one who left of their
  own accord can return at once. A member's block no longer hides the
  constellation; only the founder's does.
- **Why:** a constellation had no way to remove a player, and one member's
  block hid an open group from the blocked player.
- **Detail:** an elder cannot remove an elder or the founder. Crews keep
  every member's block, since a crew is small and invite-only.
- **Tests:** `security_deep_social.test.mjs`, "SEC-43". The client has no
  screen for removal yet.

### SEC-42: a crew's invite

- **Chosen:** a crew's leader can rotate its invite (POST
  `/v1/crews/:id/invite`), and the old invite stops working at once.
- **Why:** an invite that leaked could not be taken back.
- **Detail:** crews have no leader role, so the leader is the current member
  who joined first: the founder while they stay, then the next. One person can
  rotate, and a crew is never left with nobody who can.
- **Tests:** `security_deep_social.test.mjs`, "SEC-42". The client has no
  screen for rotation yet.

## The checks themselves

### SEC-19 B: a candidate's checks run contained

- **Chosen:** `tools/run_checks.sh` runs the candidate's `check_all.sh` inside
  bwrap: the file system read-only but for the worktree, no network. Without a
  bwrap that runs, it runs as the unprivileged user `CHECK_USER`. With
  neither, it refuses (exit 3) and says why, unless `CHECK_UNSANDBOXED=1` is
  set, which warns.
- **Why:** the candidate's code is not trusted. It ran with the lead's rights,
  network and environment, and could write the shared `.git`.
- **Detail:** in bwrap, also a private `/tmp`, an empty `/run`, the shared
  `.git` read-only, no capabilities (as root, bwrap keeps them otherwise, and
  a remount would undo the read-only view), separate pid, ipc and uts
  namespaces, and no secret-looking environment variables.
- **Host:** install bubblewrap on the machine that runs the lead, or set
  `CHECK_USER`; until then the runner refuses.
- **Tests:** `tools/test_run_checks.sh`.

### SEC-28: CI, and protection of main

- **Chosen:** `.github/workflows/checks.yml` runs on every push and pull
  request: the WebAssembly build and the server's tests, `cargo test`, the
  documents check, the ownership self-test, `tools/test_run_checks.sh` with a
  real bubblewrap, and `client/test_export.sh`. Contents permission is
  read-only, and every action is pinned to a full commit SHA.
  `tools/check_ci.py` keeps it that way, and `check_all.sh` runs it.
- **Why:** main was protected only by convention.
- **Owner:** the workflow binds only once branch protection on main requires
  its `checks` status, a pull request, no force-push and no bypass. That is a
  repository setting.
