# The server

The dynamic tier of §24.1: *"Edge functions against a managed serverless SQL
database. No virtual machine, no operating system, nothing to patch."* Its
one real job is §24.12's: re-simulate a heist the device played offline, and
only then mint what it earned.

    node --no-warnings --test server/test/*.test.mjs   # the tests (build sim/ first)
    node --no-warnings server/load.mjs                 # the load test, against §24.1's budget
    node server/src/main.mjs                           # run it locally, on 127.0.0.1:8787
    node server/src/main.mjs 8787 --example            # and publish the example island to raid

It needs Node 22.5 or later and nothing else — no packages. The simulation is
`sim/`'s WebAssembly build (`bash sim/run_spike.sh` builds it), and SQLite is
`node:sqlite`.

## What it does, stage by stage

| §24.12 | Here |
| --- | --- |
| **Lease** — "a target snapshot, a seed, a single-use token and an expiry a day away. Nothing is created yet." | `Service.lease`. §24.13's "one lease per target per player at a time" is a partial unique index, so the database holds it rather than the code. The clock is §5.4's, from `facts.json`. |
| **Play**, **Queue** | On the device: `sim/`'s same library records the replay (`rb_record`). |
| **Validate** — "re-simulates, compares, and checks the token, the expiry and the caps" | `Service.submit`: the token is bound to the attacker; the replay's header must name the leased snapshot, seed and clock; it is re-simulated by the build its rules version names; every second's checksum is compared. |
| **Grant** — "only then is the haul minted, into an append-only ledger" | `Service.grant`, in one transaction with the heist row: the entry fee (§9.4), the haul (§9.6), the fee returned after a clean, loud or partial heist (C41), and the fee paid to the defender after a foiled one (§12.9, G37). |

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
- A raider holding less than the fee pays whatever it holds.
- §24.12's expired lease gets "No reward, with one grace submission allowed":
  read as one expired submission honoured a day.

§9.6's three caps are enforced at grant, where §24.12's Validate "checks …
the caps": a raid never pays more than 1.98 times its base (derived from the
richness and difficulty terms that set it), a day never more than "half again
above" the whole fatigue curve, and a week never more than "five days' worth"
of it. Three readings are taken there (register **G20**): the curve is in the
raider's own Vault level's base, "five days' worth" is five days of the curve
rather than of the ceiling, and the week starts on Monday, UTC.

## What the owner decided

The owner answered the decision brief (`docs/decisions/answers.json`), and
where an answer changes a rule the document still states, the server follows
the answer and the register item waits for the document:

- **The base** (F36) is 5,000, where §9.6 ships 2,400: the smallest hundred
  at which §9.6's raid-worth check holds on every day, with the fee an
  attempt keeps inside it (F53). B(3), the example island’s, is 11,250.
- **The fee** (F39, C41, G37) is 2% of B(V) at the target's Vault level —
  100 at level 1, 3,844 at 10 — with no floor or cap, shown on the lease
  (`fee`) before the heist. It comes back in full after a clean or loud
  heist and half after a partial one; after a foiled one it passes to the
  defender on the pair's first foil of the day, and otherwise stays with
  the game.
- **The week** (G20, F40): 20 paid raids a week from Monday 00:00 UTC, and
  after that a raid costs nothing and pays nothing (`cappedBy: "week"`); the
  first ten matchmade heists of the week move Renown, and later ones pay
  their haul and move none. The lease carries the week's counts and names
  the cap it has reached (`capped`). The league boundaries are refitted to
  that limit (`tools/league_model.py`).
- **Games among friends** (F48) pay no haul, cost no fee and write no ledger
  line, and are not raids for fatigue or the week's count.
- **Echoes** (G30) rate the raider against the echo's island, which does not
  move, and "recent" counts only raids.
- **The Keeper window** (F44) runs from two levels below the raider to three
  above; **the Heart** (G19) is published only at realm level 3; target
  lists are rebuilt **hourly** (G21); a track tier costs **10 stars** (G28);
  the Workshop quota is **1 MiB** and the name lists **64 × 64** (G26).

Target lists are §24.8's "file, not a query": `Service.targetLists()` writes
one content-addressed list a band, holding every island's current snapshot, and
`GET /v1/targets` names the current file for each; the file itself is fetched
by hash like a bundle, so an unchanged band keeps its edge cache. Two readings
(register **G21**): a band is a realm level, the unit of §12.22's guarantee,
and "generated periodically" is once an hour, as the owner decided
(`main.mjs`). A list names players, so it is served with a cache life of one
rebuild, an hour, where an island's bytes are cached a year, and the list
before a band's current one is kept one rebuild after it is superseded and
then deleted, even if the band has not changed since (**G38**).

## Choosing a target

`src/matchmaking.mjs` and `src/glicko.mjs` are §12.22's steps and §12.3's
protections:

- **Ratings.** Raiders and islands are rated with Glicko-2 at §12.22's
  constants (deviation 350, volatility 0.06, system constant 0.5); every
  validated heist updates both. A new island enters at the middle of its
  origin's raider-success band, 350 wide.
- **The offer.** `offer` is a pure function of the raider and the
  candidates, so the device can run it on a target list, which carries each
  island's rating, deviation, Renown and origin; `GET /v1/offer` runs it on
  the server. It filters by Renown within 150, Keeper level from two below
  to three above (F44) and
  rating within a band of the raider's recent success; sorts by predicted
  success; draws the middle from the band; counts echoes when fewer than
  three sit in the band; and only then widens rating, Keeper level and
  Renown, in that order, saying so.
- **Echoes.** A snapshot no island is on any more can be leased for 14 days;
  robbing it takes nothing from its owner and moves no Renown; it rates the
  raider, and not the island (G30). A raid past the week's 20 opens no Trace.
- **Protections.** A new player's island is refused for 72 hours, or until
  they raid; a robbed player may Trace the raider once within 24 hours, with
  no entry fee.

The readings are **G30**; the simulator's prior, depth and the generated
fallbacks are **D66**. Two findings came out of it: **F44** (the 0.25 tier
is reachable) and **F45** (§12.3 and §12.22 filter differently).

## The Island Workshop

`src/workshop.mjs` is §18.6's Workshop, over the same simulation and store:

- **Publish.** An island reaches the Workshop only once its creator has
  cleared it — "so every island can be solved" — which the creator proves
  with a replay the server re-simulates on that island. It must also pass
  the simulation's publishing rules, carry a name from the word lists
  (`src/words.json`, in both launch languages, so each client shows it in its
  own), and fit the creator's slots and storage quota (§20.12): five islands,
  eight once §18.7's Builder.
- **Browse.** Top by completions, newest, and the featured spotlight a person
  chose; a player aged 13 to 15 sees the featured list only (§20.7).
- **Play.** A seed and a clock, with nothing staked and nothing minted. A
  clear by anyone but the creator is a completion, once a player (§18.7), and
  a sudden spike joins the moderation queue for a person to look at.
- **Rate** fun, cleverness and fairness — only players who played it.
- **Report and moderate.** Reports wait in a queue marked overdue past §20.4's
  24 hours. A moderator dismisses, removes (with a reason the creator is
  shown, §20.11) or bans; a ban takes the account's islands out of the
  Workshop and the target lists at once and refuses its sign-in (§20.12).
  A moderator also features an island, which counts toward §18.7's ladder.
- **Remix.** One tap hands over the island's bundle to open in a builder, and
  publishing the remix names its original (§25.1).
- **Never deleted.** An item's bundle, creator, name and lineage are fixed by
  trigger, and it cannot be deleted; a creator withdraws one, which frees its
  slot and keeps it.

Where the document names a rule without its figure — the word lists, the
slot count, the quota, what clearing means, the report reasons, what a spike
is — the server's reading is a named constant, listed in register **G26**.
A completion by a player in the creator's own constellation counts at a
quarter (§18.7). What waits on other systems — the authored hold-band check
and the Island Fund — is **D62**.

## Renown, leagues and seasons

`src/seasons.mjs` is §12.9's Renown and §18.1's seasons, booked in the same
transaction as the grant:

- **Renown.** A clean heist earns "20 × (1 + (defender's Renown − raider's
  Renown) ÷ 1,000), kept between 8 and 40", times the outcome; the defender
  loses the mirror amount. A foiled heist costs the raider a flat 8, and the
  defender gains what the raider lost. Renown is an append-only table by
  trigger, like the ledger, and a player's Renown is a sum over it.
- **Floors.** "Nobody can drop out of Dust or Ember": a loss stops at Dust's
  floor, or at Ember's once reached. So Renown only moves between players,
  and is minted only where a floor stops a loss — register **F40**, which
  measures what that does to §14.7's arrival times.
- **Leagues.** Six, each with three divisions except Paradox. Where each
  starts is not in the document: `src/leagues.json` is what
  `tools/league_model.py` fits to §14.7's season-end shares, over a
  simulated population of players raiding each other — register **G27**.
  `bash tools/check_all.sh` fails if the copy drifts from the model.
- **Defending pays.** A foiled heist gives the defender the raider's entry
  fee (on the pair's first foil of the day, G37) and §9.4's "5% of what the
  crew was carrying": the simulation reports
  what the crew took and did not bank, valued as the clean haul it would
  have been. §13.1's rule raises the share five points a season, to 20% at
  most, while fewer than 15% of the season's last-week players changed their
  defence (G31).
- **Seasons** last eight weeks, back to back from `RULEBORN_SEASON_START`.
  `Seasons.rollover` closes every ended season once — each player's final
  Renown, league and reward written down, Star, Nova and Paradox's season
  cosmetic granted, the constellation league ranked — and each player's next
  season opens "pulled halfway back toward the floor" of their league.
  `main.mjs` runs it at start and every fifteen minutes; it is idempotent.

## The season track, purchases and cosmetics

`src/track.mjs` is §18.2's season track and §18.8's rules for it:

- **Stars.** Each heist earns season stars in the grant's transaction: the
  raider ten times §12.9's outcome, the defender the rest of ten. Stars are
  spent on tiers, and a season's unspent stars are gone when it ends (§9.1's
  "reset each season").
- **Tiers.** Fifty, claimed in order. Tier 1 is free on day one (§14.8); each
  after costs a tier's stars, scaled to the time left for a player first seen
  late in a season (§18.8's catch-up). A past season's unclaimed tiers stay
  on offer, bought with this season's stars at that season's price. The free
  track gives Essence, five pages every other fifth tier, and a stray offered
  at the next birth's price at the top (F38).
- **Premium.** A store product of its own for each season, "premium.N", this
  season's or an earlier one's at the same €6; its cosmetics come with every
  tier claimed, before or after.

`src/shop.mjs` is §22.1's shop and §20.2's caps, as the owner answered F41:
there is no currency.

- **Everything is priced in money.** Each cosmetic in `src/cosmetics.json` and
  each season's premium track is its own store product at its euro price,
  which the track's view names (`premiumProduct`, `premiumPrice`) for the shop;
  there is no balance and there are no packs, and the ledger holds Starlight
  and Essence only. A purchase is two steps: an intent, refused if it would
  take a minor past the month's cap (€25 at 13 to 15, €50 at 16 and 17) and
  held for a quarter of an hour; then the store's receipt, granted once per
  store transaction. Adults get §20.2's monthly spending summary, refunds
  shown. `Service` takes a `verifyReceipt(store, receipt)` function, as it
  takes `verifyPlatform`.
- **Gifts** are the same item bought for a friend, as its own product,
  "gift." before the item's — a store sells an item its buyer owns only once
  — and granted to the friend the intent names. A gift's intent is kept 30
  days, since only it names the friend; a gift receipt after that is refused
  before the store settles it. Starglass survives only as
  the wrapper a gift arrives in, which is the device's (§19.12).
- **Refunds** (G32, answered through F41's): the store's report takes the
  product back from whoever received it — the cosmetic, off wherever it was
  worn, or the season's premium track and the cosmetics its tiers gave —
  once per refund, unless another purchase not refunded still gives them the
  same (a gift of what they also bought); a refund the store reverses gives
  it back (Apple's `REFUND_REVERSED`); and a receipt for a refunded
  transaction is refused.
  Apple's App Store Server Notifications (v2) come to
  `POST /v1/stores/apple/notifications`, checked against the same pinned root
  as a transaction; Play's voided purchases are asked for once a day.
- **Cosmetics** are owned in §24.8's `accounts.cosmetics`, and worn slot by
  slot: one of each kind, an outfit a crew role and a visual a law. A lease
  carries the defender's worn set, so a raider sees the island as it was
  dressed.

The figures the document does not give — stars, tier price, rewards — are
named constants, register **G28**; what is not built is **D64**. A database
made while there was Starglass has its ledger rebuilt around its other rows
when opened: what was paid stays in `purchases`, the record of money.

## The stores' proofs

`src/stores.mjs` checks what Apple and Google sign, without asking either
about any one player. Apple's, each against its own pinned roots:

- **Game Center sign-in.** §24.8: "Platform identity is exchanged for a
  short-lived signed token." The device's identity-verification signature
  covers the player, the app, a timestamp and a salt; the key is in a
  certificate issued to Apple Inc., fetched only from Game Center's key hosts
  and names (the one network call, made and cached by `preparePlatform`
  before the synchronous sign-in; an unseen name at most once a second, a
  failure remembered apart) and checked to Game Center's pinned roots; the
  signature must be at most five minutes old. The token it earns is
  HMAC-SHA256 (`tokens.mjs`).
- **App Store purchases.** A StoreKit 2 transaction is a JWS carrying its own
  chain: a leaf with Apple's StoreKit marker OID and a P-256 key, under an
  intermediate with its own marker, to StoreKit's pinned root; then the
  ES256 signature, the app's bundle ID, that it was not revoked, and that it
  is a Production purchase. The purchase intent's id rides the purchase as
  its appAccountToken, so it is a UUID.

And Google's:

- **Google sign-in.** The ID token "Sign in with Google" returns on Android:
  a JWT Google signs RS256 with keys it publishes at a fixed URL, fetched
  and cached by `preparePlatform` (again only when a token names a key not
  held, or the keys are past the age Google gave them, and at most once a
  minute), then its issuer, the server's own client id as audience, its
  times and its subject. It proves a Google account (`gp:<sub>`), not a Play
  Games player: Play Games Services gives a server only a code to exchange
  with Google, which is a call per sign-in (**D67**).
- **Play purchases.** The purchase's JSON as Play returned it, signed
  RSA-SHA1 with the app's licence key; then the package, that it is
  purchased (not pending or cancelled) and one item. The purchase token is
  the transaction, granted once; the intent rides as its
  obfuscatedAccountId. Then Google is asked (`src/googleapi.mjs`, the Play
  Developer API as a service account): the purchase must still be paid for
  and not a licence tester's, unless the operator allows test purchases,
  and the server acknowledges it before granting — or consumes it, if it
  is a gift, which can be bought again — since a purchase nobody
  acknowledges is refunded by Play after three days, whatever was granted.
  Once a day the server asks Play for the purchases it has voided since, and
  takes them back (`voided`).

Each credential goes only to its own platform's check, and a receipt only
to its own store's.

`main.mjs` takes `RULEBORN_GAMECENTER_ROOTS` and `RULEBORN_STOREKIT_ROOTS`
(the pinned certificates) and `RULEBORN_BUNDLE_ID`; `RULEBORN_APPLE_SANDBOX=1`
lets Sandbox purchases pay, for a test deployment. Google's are
`RULEBORN_GOOGLE_CLIENT_IDS` (the server's OAuth client ids, comma-separated),
`RULEBORN_PLAY_PACKAGE` and `RULEBORN_PLAY_LICENCE_KEY` (the Play Console's
base64 key; one without the other refuses to start), and
`RULEBORN_PLAY_SERVICE_ACCOUNT` (the path of the service account's JSON
key, without which Play receipts refuse to start) and `RULEBORN_PLAY_TEST=1`
for licence testers' purchases. It refuses to start
with either store's receipts and neither platform's sign-in — a server that
takes money must not take any credential as an identity — unless
`RULEBORN_STUB_SIGNIN=1` says it is a test. With no platform at all, it
takes any credential as the identity it names, refuses every receipt, and
must not face a network.
`RULEBORN_DATA` moves its database and bundles out of `server/.data/`, which
is how `client/status.py` gives each test run a fresh one. `RULEBORN_SECRET`
is the key session tokens are signed with and telemetry's pseudonyms made
under; unset, one is made on the first start and kept in the data directory
as `secret`, so a restart neither signs everyone out nor leaves a player's
earlier telemetry where their deletion cannot find it; a key shorter than
32 characters is refused. `RULEBORN_DELETIONS`
names the deletion journal (below). The tests use a
stand-in chain in `test/fixtures/apple/` (its `make.sh` regenerates it). The
readings are **G32**; Google Play's side is **D67**; and building this found
**F46**: every island is public by hash before any scout.

## Eras

`src/eras.mjs` is §18.3's week: the eight eras take turns, a week each from
the first season's first day. Every lease against a universe names the
week's era, a Quiet Week lease's clock is 30 seconds longer, and a replay
whose header names another era than its lease pays nothing — the rules are
the simulation's (`sim/src/era.rs`). The Workshop is out of the eras, so an
island cleared once is solvable every week. `GET /v1/era` says which it is
and when it ends. The readings are **G36**, what is not built **D69**, and
Quiet Week's clock past §5.4's cap is **F49**.

## Friends

`src/friends.mjs` is §12.11's friendly heists and §17.6's sharing:

- **Friends** are made by an invite one player shares and the other
  accepts, and either can end it.
- **A friendly heist** is a lease in its own mode, on a friend's island:
  no entry fee, no haul, no Renown, stars or rating, and "the friend loses
  nothing";
  the outcome records the page the friend earns "for every raider their
  guards catch". A new player's protection does not stop a friend.
- **The friends' feed** is derived from the heists already written, so it
  costs no write: friends' heists, raiding or raided, from the last week. A
  heist in which either side is 13 to 15 appears in no feed (**G35**).
- **A challenge link** is a code for the player's island that anyone holding
  it can play once, as a friendly heist is played.
- **The invite gift**: the friendship keeps who shared the invite, and the
  friend's first validated heist gives both players the matching cosmetic
  `invite-gift`, once; a friend who had played before accepting brings none.

How friends are made and whom the feed shows is the owner's answer to
**G35**; what a game among friends pays is **F48**.

## Replays and notifications

§13: "The defender is notified afterwards and can watch the replay."

- **Replays** are kept in a store of their own (`replays`, apart from the
  public one anyone may fetch by hash) and served to the heist's raider and
  defender at `GET /v1/heists/:token/replay`. §24.3 keeps them "30 to 90
  days": past 90, `expireReplays` (daily, in `main.mjs`) deletes the bytes
  and keeps the heist row and its hashes.
- **Notifications** (`src/notifications.mjs`) are §14.6's: "only for things
  the player can act on". The server sends the two it knows of — a heist
  against you, and the daily reminder a player chose — through an outbox:
  nothing goes out in §20.2's night (21:00 to 08:00 at 13 to 15, 22:00 to
  08:00 at 16 and 17 and, by default, for adults, who may open it), worked
  out in the IANA time zone the device reports, so daylight saving moves
  nothing; a device that has reported none is sent nothing. As the owner
  answered **G34**, a local day's raids are one message, sent with the day's
  reminder or, with none chosen, when the night ends, and a reminder time
  inside the night is refused; one already stored that the night comes to
  cover (an adult quietening it again) is cleared, and the answer says
  `reminderCleared`. A changed reminder, zone or night moves the waiting
  raids with it. `main.mjs` delivers once a minute.
- **Push** (`src/push.mjs`) is Firebase Cloud Messaging's HTTP v1 API, sent
  as the project's service account (`RULEBORN_FCM_SERVICE_ACCOUNT`, its JSON
  key; `RULEBORN_FCM_PROJECT` if the project is not the key's own). A
  message names localisation keys — `ruleborn_raided_title` and `_body`,
  `ruleborn_reminder_title` and `_body`, and for a reminder carrying the
  day's raids `ruleborn_reminder_raided_title` and `_body` with their count
  — which the app's native string
  tables hold, so each device shows it in its own language, and carries the
  notification as data: for raids, how many and the latest, never the
  night's whole list. It expires when the player's night begins (a reminder
  also at its day's end), so FCM and Apple drop it rather than wake a phone
  that was off or asleep inside §20.2's night; each kind collapses only
  with its own. Each is claimed before it is sent, so a raid landing
  meanwhile starts its own, and each send reads the clock and the token as
  they are then. A token FCM no longer knows, or names as malformed, is
  cleared; one FCM cannot take now is tried again after five minutes a try,
  six tries at most; one refused for good is not sent twice; and every tick
  logs its retries, give-ups and refusals by reason, never with a token.
  Without the key a due notification is logged, by kind and count only.

What is not built is **D68**.

## Under load

`load.mjs` is phase 14's load test. It plays §14.1's engaged, regular and
casual players through the service as built — every lease, validation,
grant, Renown line, star, rating and event batch — and measures what §24.1
budgets: rows written a player a day, by what wrote them, and the CPU a
re-simulation takes. The writes are deterministic, so `server/load.json`
keeps them and `bash tools/check_all.sh` fails if a change moves them
(`--write` records a new baseline). It counts rows twice: as SQLite changes
them, and as D1 bills them, each index entry a write touches being a row
written too (`billed`), and prices the plans from the billed count. What it
measured — an engaged day bills about 72 rows against §24.1's five, and a
re-simulation takes about 15 ms against the free plan's 10 — is register
**F47**; its readings are **G33**. What was cut to get there, each held by
`test/cost.test.mjs`:

- **One ledger row a player an event.** A heist books its raider's fee,
  haul and fee returned as one row, and its defender's fee and share as
  one; `paid` is the part §9.6's caps count. The lines are in the heist's
  outcome.
- **A player's day of telemetry is one row**, made by the day's first event
  and appended to by every later one in one UPDATE that touches no index.
  The server's own sign-in event is recorded once a day.
- **A lease is settled by its heist row**, never written again, and §24.13's
  one lease a target is kept by the issuing transaction.
- **A heist's row is written before the rows that name it.** Written after,
  it made SQLite search the ledger, Renown and stars whole for the rows it
  settled, on every heist.

## Telemetry

`src/telemetry.mjs` is §24's first-party analytics, under §20.5 and §24.3's
rules:

- **What is logged.** The server records what it decides: a sign-in (once a
  player a day), a
  heist's "outcome, laws crossed, crew", and a purchase. The device sends the
  rest to `POST /v1/events` in batches — its sessions, the app in the
  foreground from `session_start` to `session_end` (**G29**: a sign-in only
  proves who the player is), weaving, births, the one-tap "Was this worth
  your time?" and the survey — and a batch is checked whole: known events,
  known fields of known types, times no later than now, and no field that is
  a position ("The client never sends coordinates"). The survey is a monthly
  rotating sample, the eleven items and "does the game feel like a chore?";
  `GET /v1/survey` says whether it is the player's, and a yes is the asking:
  it is recorded, so a player who declines is not asked again that quarter
  (§25.4).
- **Pseudonymous.** Every row is keyed by an HMAC of the account under the
  server's secret, so the events alone name nobody.
- **Kept 90 days.** `Telemetry.compact`, run daily by `main.mjs`, writes each
  finished cohort's day-1, day-7, day-30 and day-60 returns — a week after
  its day 60, the longest a device may send a session late — and each day's
  counts, and discards the raw events past 90 days. A player's first day is
  their earliest session, in whatever order the device sends them.
- **Queryable.** `GET /v1/metrics` gives analysts the figures the launch
  gates read — players, sessions and the crash-free share, the median
  session's length and sessions a day, heists by outcome, the average "worth
  your time", the share for whom it feels like a chore, the share who bought,
  and cohort retention — and `/v1/metrics/absence` §25.3's churn early
  warning.

These are the owner's answers to **G29**; the heatmaps and the error
reporter are **D65**.

## Deleting an account

`src/accounts.mjs` is §20.5's "Account and data deletion from inside the
game", reached by `DELETE /v1/account` — and by declaring an age under 13,
which §20.11 says is deleted at once. What identifies the person goes: the
platform identity (signing in again starts a new account), the telemetry
under their pseudonym, their islands from matchmaking and the target lists,
their places in constellations and crews, and any token they hold. What the
document keeps unchanged stays under an id that leads to nobody: the ledger,
Renown, heists, snapshots, and their Workshop islands, which stay listed and
playable with no creator shown unless the player asks for them to be
withdrawn too — withdrawn, not deleted, so a remix still names its original.
That is the owner's answer to **F43**; `DELETE /v1/account` takes
`{"withdrawIslands": true}`. Their notifications, sent or waiting, go too, and a raid leased
before the deletion settles without owing them one.

A player under 13 is deleted further, as "anything collected" (§20.11): the
replays they played, their islands' bytes (unless another player's island,
Workshop island or link is the same bytes), their ratings, their Workshop
plays, ratings, completions and remixes, and their open leases go at once,
and the target lists are remade without them, the list before too; a raid
already leased on their island is refused as `island_withdrawn`. Bytes are
kept that another player's island, Workshop island, challenge link or lease
still is. The files go after the deletion's commit, each written first to
`erasures` in its transaction, so a deletion stopped between the two is
finished when the server next starts. The edge caches a bundle for a year by
its hash, so each erased bundle's URL is also queued in `edge_purges` and
purged from the edge's cache (`src/edge.mjs`, D70): Cloudflare's purge by
URL, thirty a call, asked as the deletion is made and then by the server's
minute tick. A purge the edge refuses or cannot take waits five minutes,
doubling to six hours, and is never given up, and the log says why each
time. The row goes when the edge confirms. `RULEBORN_CF_ZONE`,
`RULEBORN_CF_PURGE_TOKEN` and `RULEBORN_PUBLIC_ORIGIN` point it at the
zone; unset, the server is behind no edge and the purges wait. A raid leased on anyone before their
deletion settles for the raider and pays, rates and records nothing of the
one who is gone. A ban keeps only the platform identity, and
the day, in `bans`, apart from the account (§20.12's "minimum
identifiers"): it ends the player's friendships and invites, and a banned
player's deletion severs the rest like anyone's and clears the ban's time
from the account, so nothing matches it back.

§20.12's "backups included": each deletion is written to a journal outside
the database, in object storage, an object an entry — an account id, a
reason, a time and the withdraw choice — before it is made, and every start
(`main.mjs`'s, and the edge handler's before its first answer) makes again
the journal's deletions of the last 31 days, the restore window and a day,
so a database restored from before one does not bring the player back
(**F50**). The journal must live where a restore of the database does not
reach; it is kept for good as §20.12's log.

A player can also delete without the app (**G39**): `GET /account/delete`
serves a page that explains what goes and what stays and signs in with
Google — the Android game's own identity — and `POST /v1/account/delete`
takes that ID token and runs the same deletion at once, withdraw choice
included. `RULEBORN_GOOGLE_WEB_CLIENT_ID` is the page's OAuth client id, one
of `RULEBORN_GOOGLE_CLIENT_IDS`. An iPhone player deletes from the game on
any Apple device.

## What the server stores, and the stores' declarations

`privacy.json` declares every column of every table — 262 in 43 — with the
store data type it is, why it is kept, how long, and what an account's
deletion does to it; `src/privacy.mjs` checks it against the schema the
server actually opens and writes `declarations.md` from it: the answers to
App Store Connect's App Privacy and Google Play's Data safety, in their own
words, with where each data type is stored and what each table keeps after a
deletion. `test/privacy.test.mjs` fails on a column added undeclared, and
does what the declaration states: it deletes a player who has touched every
table — at their request and as under 13 — and checks every table against
it, and runs each time limit it names. Those limits are **G38**'s readings:
a sent notification is kept a week, an invite goes once used or after its
seven days and a challenge link after its seven, a purchase intent that
lapsed unredeemed and a lease that expired unplayed go seven days after
(`expireLapsed`), and a band keeps its current target list and, for an hour,
the one before; at start the server sweeps any list no band names, which a
crash, a restore or an older server left. Every answer carries
`Strict-Transport-Security`, the listener's log names a route and never a
path's ids, and a new account holds the most protective age band, 13 to 15,
until the device's age check answers (`PUT /v1/age`), which the client
sends with its first sign-in. `declarations.md` also carries the two age
rating questionnaires, answered in `ratings.json` with the sentence of the
design each answer rests on (the check fails if a quote leaves the
document), and `tools/privacy_manifest.py` writes the iPhone build's privacy
manifest and export-compliance key from the same two files. Not done:
filing both forms (roadmap TC.14), and the client's deletion button (**D70**).

    node server/src/privacy.mjs --write    # after changing privacy.json or ratings.json
    python3 tools/privacy_manifest.py       # and the iOS preset's manifest

## Blocking, the terms of use, and the pages the stores link to

§20.11's duties for a game where players see each other's work, in
`src/safety.mjs` and `src/pages.mjs`:

- **Blocking**, as §17.8 says it works: each player hidden from the other in
  the Workshop's lists and the friends' feed, a friendship between them
  ended, invites and challenge links between them closed — and their islands
  still each other's targets, since "a raid takes nothing" and a block that
  removed targets would let a player dodge strong defenders.
  `POST /v1/blocks`, `DELETE /v1/blocks/:account`, `GET /v1/blocks`.
- **The terms-of-use gate.** `web/terms.md` is the terms; its `Version:` line
  names the version. Publishing, playing, rating and remixing a Workshop
  island are refused (`terms_first`) until the player accepts the current one
  (`PUT /v1/terms`); reporting never waits for it. The terms ship as a draft
  version until the owner approves them.
- **The pages**: `GET /terms`, `GET /privacy` — written from `privacy.json`,
  so the policy says exactly what the server keeps, without the design's
  references — and `GET /support`, the operator's contact, from
  `RULEBORN_CONTACT="Name <address>"`; unset, `/support` is not served.

## How fast a caller may ask

`src/limits.mjs` holds each caller to token buckets in the process's memory,
never the database, since a limit that wrote a row a request would bill more
than it protects (F47). Each kind of bucket is capped at 50,000 callers, and
a kind drops only its own longest-idle caller, so sign-ins from addresses
anyone can vary never push out a player's buckets. Past a bucket the answer
is 429 `{"error": "too_many_requests", "retryAfter": seconds}` with
`Retry-After`. The app shows it as held back, not as offline, and its outbox
tries again later (G44).

- **Calls**, by account: 60 at once, then two a second. They are counted
  from the token's signature before the account is read, so a refused
  request reads nothing.
- **Simulations**, by account: a replay re-simulated, or an island or
  Workshop entry checked. Six at once, then one every 20 seconds.
- **Sign-ins**, by the account the credential proves, before anything is
  read: `POST /v1/session` and G39's deletion without the app. Ten at once,
  then one every 10 seconds. The app keeps its session for the hour it lasts
  rather than signing in for every heist.
- **Failed sign-ins**, by address: twenty at once, then one every 3 seconds.
  An IPv6 address counts by its /64. Only failures are counted, so players
  who share an address are never held by each other's sign-ins. The address
  comes from the header named by `RULEBORN_PEER_HEADER`, which the proxy in
  front of the listener sets to the caller's one address (`cf-connecting-ip`
  or `x-real-ip`, never `x-forwarded-for`). When it is unset, failures are
  not limited by address, and the log says so at start.

Each process, or edge isolate, keeps its own buckets. A caller spread across
isolates gets more; the platform's own rate limiting, keyed the same way, is
what holds that.

## Keeper levels

`src/keeper.mjs` is §14.2's Keeper experience and levels. A raid earns its
raider §14.2's experience at the level they raided at — 30 + 6 × level for a
success, 10 + 2 × level foiled — in the transaction that settles the haul, so
a retry pays it once, and climbs §14.2's table (`design_facts.KEEPER_XP_TO_NEXT`,
level 40 the top). It is earned wherever a haul is: not by a game among
friends (F48) or a raid past the week's 20 (G20). `GET /v1/keeper` is the
level and the bar to the next. The level is what the Keeper gates read — the
Beacon's Keeper 6, matchmaking's window — which until this nothing raised.
Spending earns it too, 1 for every 40 Starlight (below), and restoring a law
60 + 10 × level (the Codex, below).

## The universe

`src/universe.mjs` is the home economy's first part (§5.2, §9.5, §10.2): a
universe's realms and buildings. Outer realms open at §5.2's Keeper levels,
each of a type not yet owned, for 2,000 Starlight, and rise at its Spire
levels for §9.5's prices; buildings are built and raised at §10.2's costs and
needs, where §10.2 places them and as many as §5.2 and §5.8 allow. Every
purchase is paid from the ledger, earns §14.2's experience for spending with
no fraction lost between purchases, and names the level it leads to, so a
retry is answered and never charged twice. A new universe is the Heart with
the economy model's start (**F56**). What a universe has built is what its
islands may claim: `PUT /v1/islands` refuses a realm not opened, a realm
level above the realm's, or a Vault above the one built. `GET /v1/universe`
answers what each thing costs and needs and whether it can be bought now,
so the device never works a rule out itself.

**Where buildings stand (§10.1, TD.36).** *"Buildings sit on the realm grid
and block movement and sight. … Moving a building is free and instant, like
terrain."* Each building keeps its footprint's north-west tile, null until it
is placed; `PUT /v1/universe/buildings/place` moves one at no cost, refusing a
footprint off the realm's grid (`off_the_grid`) or over another building's
(`tile_taken`). The footprints are the simulation's own (`island.rs`
`BUILDING_CODES`, read through the WebAssembly build's `rb_building_kinds`):
the Spire 3 by 3, the rest 2 by 2. The Vault, pylons, posts and wards are
placed by the island's own lists, so they have no tile here
(`not_on_the_grid`). A published island must carry exactly the realm's
placed buildings on their tiles (`buildings_not_as_placed`, read with
`rb_island_buildings`); the simulation still judges what stands under them.

## The hold, measured

`src/holds.mjs` is §13.3's hold. Every island published is queued once by
its bundle and the rules version for §13.3's 800 raids of the competent
reference crew, which plays inside the simulation (`sim/src/reference.rs`,
`rb_hold`): three of a new Keeper's crew on the Heart's clock, each raid
landing where its seed draws among the spots near the shortest walk to the
Vault (G86). The queue is worked a few raids at a time (main.mjs), each part
from the digest's seed moved on, so a measurement in parts is the one in a
single call. When it lands, every island on that bundle not yet raided takes
§12.22's prior from it; the same bundle published again is answered from the
cache. Curation shows it as measuring until it lands, never as an estimate.

## The Island Fund

`src/fund.mjs` is §18.9's Island Fund. The daily job closes each ended
calendar quarter once: 10% of its net revenue — each purchase, less a
refund the store has not reversed, less §22.5's 15% — divided by the time
played on each opted-in creator of 18 or over's islands (each validated
Workshop play's seconds from the event log, none of the creator's own, a
quarter of a constellation-mate's, nothing on a removed island), no one
above 2%, what a cap leaves going to the rest in proportion (G85). `GET
/v1/fund` is the settings page: opted in or not, and each closed quarter's
pay, never a running counter; `PUT /v1/fund {"optIn"}` opts in at 18 or
over. The bands, the floor and the per-player cap have no numbers (G85);
identity checks and paying the money are outside the server.

## Links between realms

`src/links.mjs` is §5.3's links. Each outer realm opens with a Stone bridge to
the Heart while the Heart has one of its four sockets free, else to the first
opened realm with one (G84). `POST /v1/universe/links {"a", "b", "kind"}`
builds another at §5.3's price — a Rope bridge 300 Starlight, a Chute 1,500
and at most two, running from `a` to `b`, a Rift 5,000 and at most one — up
to one link an outer realm and two; `PUT /v1/universe/links/:n {"kind",
"from"?}` rebuilds one as another kind, and `DELETE /v1/universe/links/:n`
takes one down while every realm still reaches the Heart without a Rift. A
Rift's 20 Aether an hour is charged as the universe is read, and an unpaid
one stands closed. `GET /v1/universe` answers the links, each realm's depth
(the links on its shortest route to the Heart, which sets §5.4's clock for a
crew landing there), the deepest, and the realms §5.5's faults open from,
deepest first. Production takes §5.5's band and §9.3's 10% cut for a fault
opening from the producer's realm (home.mjs), and each Observatory card its
universe's depth and fault realms.

## The roster, its work, and what it produces

`src/home.mjs` is the home economy's second part (§5.8, §9.2, §9.3, §9.5,
§11.3 to §11.6):

- **The roster.** §15.6's Featherkin, Emberling and Tidewalker wake with the
  universe, two traits each; the first validated heist brings §11.5's two
  strays home free, born under the raided island's laws, three traits each.
  Characters live in the Spire's three places and each Hearth's homes, 38 at
  most, and rise a level for §9.5's Essence price up to twice their home's
  level.
- **Births** at a Nursery, one ready a period up to three, for 100 × 1.3455
  to the power of the characters owned, drawn from the realm's school with
  the roles the player has fewest of twice as likely. A birth names the
  roster size it leads to, so a retry is answered as born.
- **Work.** A character works a producer's slot or stands at a Guardian
  Post; its share counts from five minutes after it is assigned.
- **Production** is §9.3's: the table's rate at the producer's level, a
  slot's share for each worker, ×1.1 in a realm of the resource's school,
  and +15% for a worker of its schools and the work traits. The server
  integrates each worker's share over the time it counted whenever the
  staffing or the level changes, and a producer holds twelve hours. A
  collection is paid into the ledger, which now carries Aether; a Garden's
  pays the roster's keep, a quarter. The law term is weaving.mjs's; the
  stability and fault terms are 1 until TD.37 keeps them, and `GET /v1/home`
  says so. What the document leaves open is **G82**.
- **Generated targets** (§12.22, `generator.mjs`, D66). A seeded account,
  the game's own, publishes one island a realm level each UTC day, made by
  the simulation from that day's seed (`rb_generate`), so every server makes
  the same five; each realm's rating starts at the generated band's prior and
  is kept across the days. `offer` reaches for them after echoes and before
  widening any filter, and says so (`generated`); yesterday's are no echoes.
  The server stocks them before each target list.
- **Casts** (§12.5, §7.6). A cast the replay's manifest carries must be one
  of the raider's own restored laws (`cast_not_restored` otherwise). The
  verdict's 34th byte (`castsUsed`) says which were placed, and each used is
  billed at validation, `CAST_AETHER_PER_POINT` Aether a point of its law's
  stability cost, on the heist's one ledger row for the raider; a cast
  carried and never placed costs nothing, and a raider who cannot pay for
  what was cast has no heist to settle (`not_enough_aether`). A foiled heist
  gives the defender a page of each law cast. What a cast does is
  `sim/`'s: its law's zoned lines on a circle of 4 tiles for 10 seconds.
- **The crew and its rest** (§11.6, §12.9, TD.34). A heist names its crew from
  the roster: `POST /v1/heists/:token?crew=ids`, each a character the player
  holds, none twice, none away, as many as the replay's crew and, in an RBH3
  replay, each member's kind, level and traits the manifest's; otherwise the
  heist is refused as `crew_not_held`, `crew_mismatch` or `crew_resting`.
  The re-simulation's verdict now says who got out (`outMask`), so each
  member rests by its own outcome — 45 minutes clean, 60 loud or out of a
  Partial, 180 caught or foiled — × (1 − 0.05 × its Hearth's level) ×
  Loyal's 0.75 after a success and Sleepy's 1.5. The server learns of a heist
  when it is submitted, so the crew is away from then for the heist's length
  and its rest; production does not count it meanwhile, and `GET /v1/home`
  shows it resting until then. `POST /v1/home/characters/:id/wake` brings one
  back early for 2 Essence a level a minute left. A Spire home cuts nothing
  from rest until §11.6 says what it does (G51).
- **When it fills.** Each producer's `full_at` is the moment its store
  reaches what it holds, each worker counting from its own start, or null
  when it is full or unstaffed; the view's `night` is the §20.2 night the
  player keeps. The device sets §14.6's storage-full notice from the two
  (TD.74).

## The Codex

`src/codex.mjs` is §7.6's Codex. It starts with Half gravity, Slow rivers and
Bloom restored at tier I. A validated heist gives a page of each law met for
the first time, and a heist that pays gives a page for each pylon broken —
read from the re-simulation, which reports whose pylons they were — and every
eighth such heist a page of the law the player marked as worked on. A heist
allows one study of a law it crossed: 3 pages if clean, 1 if foiled, 2
otherwise. A friendly heist pays its owner a page of their worked-on law for
each raider caught. A law is restored at tier I for 10, 20, 35 or 60 pages
by rank, from Keeper level 6 for chapter 2, and pays §14.2's 60 + 10 × level;
tiers II and III cost 20 and 40 pages, 2,000 and 8,000 Aether, and Spire
levels 4 and 7. `GET /v1/codex` also shows each school's album, its four
launch laws in chapter order, one not yet met a "?" that names nothing
(D79), with the milestones its restored laws reach at 2, 4 and 8; and each
school's §18.5 mastery track, a step for each launch law woven, crossed in
a successful heist (any grade but Foiled, in a heist that pays) and raised
to tier III, with a title at a third, the school's style at two thirds and
a title at all of them (4, 8 and 12 at launch). §7.6's chapters close
matchmaking too: `offer` shows a raider only islands whose laws are all
from chapters they have open, a rule no widening reaches past, and the
game's generated islands run chapter 1's laws, open to everyone, so a thin
list still fills. A law is met by a heist's route, never by the offer or
the lease. What the document leaves open is **G83**.

## Built offline, confirmed on reconnection

§24: *"The device may build, weave and assign work offline, confirmed on
reconnection; everything else waits for the server."* `src/offline.mjs` takes
what the phone kept, `POST /v1/offline {"actions": [...]}`, up to 50 at once:
each `build`, `place` or `work` is made now, in the order the player made
them, by the same calls as online (universe.mjs's `build` and `place`,
home.mjs's `work`), and answered on its own — confirmed, with §14.2's
experience a build earned, or refused with the online reason. A refusal stops
nothing after it. A repeat is confirmed and changes nothing, since each
action names the state it leads to, so a queue sent twice pays once; and the
work counts from the server's confirmation, never from the phone's clock.
A weave and an unweave are confirmed the same way, the weaving time running
from the confirmation.

## The Observatory

`src/observatory.mjs` is §12.3's Observatory and §12.4's free scouting. `GET
/v1/observatory` offers 3 targets (4 from Observatory level 3, 5 at level 5),
one more while the Wanderer is at home, from Keeper level 20 (§11.7), each as
its target card: the Keeper level, realms, Renown, a rough loot
estimate, the universe's strain and its open faults by §5.5's thresholds, and
for the realm its laws, guards by role, wards by kind and watch, counted from
the public bundle with nothing placed. Each card carries the fee the lease
will charge (`stakes`) and why it was offered, never the rating; `GET
/v1/offer` drops the rating too. A Trace is pinned apart, with no fee.
`POST /v1/observatory/refresh` costs 50 Aether, doubling with each refresh in
the hour, and sets the targets shown aside.

## Weaving

`src/weaving.mjs` keeps what is woven (§5.1, §5.5, §5.6). A realm has §5.2's
law slots for its level, the Heart realm level 3's two, and the crown its
slots by the Spire, one at Spire level 2 and a second at 5. A law is woven
only once the Codex has restored it, at the Codex's tier, into an empty slot
that is not resting, once a realm, and crowned or woven in realms, never both.
It costs §5.6's 40 Aether a point of §5.5's cost of the law where it would be
woven — base × tier (1.0, 1.3, 1.6) × 2 if crowned × 0.8 in a realm of its
school, the terms that depend on the realm's other laws (harmonies,
resonances, chords, dissonances) and the week's era — priced by the
simulation's one function (TD.14, `sim/src/stability.rs`), which the client
calls too. It works after §5.6's 10 minutes, 40 minutes or 2 hours; until then
the slot is empty. Removing one is instant, and the slot rests an hour. No
weave is taken in a universe at Breaking, nor one that would take strain there
(§5.5: `breaking`, `would_break`); upkeep is TD.37's. `GET /v1/weaving` shows
each realm's slots, type, each restored law's price there, the Spire level
that opens the next crown slot, and §23.2's offers — each law's points, price,
time, band after, the notes it would harmonise and clash on, its resonances
and chords, and why it is refused, if it is — with two or three recommended,
harmony first, clash last, then the cheapest; and the universe's capacity,
strain and band. `POST /v1/weaving` weaves; `DELETE /v1/weaving/:realm/:slot`
empties. `GET /v1/weaving/harmony` is §23.2's Harmony view: each realm's laws,
the crown's among them, with their notes, and the harmonies, clashes,
resonances and the chords the simulation sounds, each with its factor; a
resonance or chord is unnamed until the Lab names it (§8.6). What
is woven is what home.mjs reads: §9.3's 1 + 0.10 per realm law of a producer's
school and 0.05 per crown law, a producer's store integrated in stretches cut
where a weaving finishes, so a law counts from then; and §11.5's births, their
school drawn 3 for each law woven in the realm, 2 for its own school and 1 for
each crown law, a law-linked trait three times as likely for a law the realm
runs (§11.3). The load run does not weave yet, so its rows a player a day
leave weaving out.

## The profile

`src/profile.mjs` is §23.2's Profile and stats. `GET /v1/profile` counts the
player's record from the heist rows, the Codex and the Lab: Renown and league
this season and each closed one, never the rating; heists by each outcome's
name; defences held and leaked, Partial apart (G69); seven of the designs'
ten records that have a fact — the fastest escape, the fewest caught, the
biggest haul, the longest defence held, and from each heist's event-log
report the fewest alarms, the most guards slept past and the edge raiders
most often land on — the other three answered as null; the collection, the
album's forms the roster has brought home and the cosmetics owned; §18.5's nine
badges graded at their marks (gold at the mark, silver at half and bronze at
a tenth, rounded up); titles from mastery; and the battle log with its
replays. §20.2: a 13-to-15 profile is never served to another account and
its switch cannot be turned on; anyone else's is served by
`GET /v1/profile/:account` only once `PUT /v1/profile {"public": true}`.

## Planning a heist

§12.5's limits hold by the raider's Keeper level when a heist is submitted
(keeper.mjs): a crew of 3, 4 from level 8 and 5 from 16; a Sage from level
2, unlocked, and never the one stationed at the Heart (§11.7); one cast
slot, two from level 12. `GET /v1/keeper` answers them as `plan` for the
device's planner, with the load targets; the home gives each character the
fields the replay's manifest carries (`wire`), and each Observatory card its
clock.

## Before the first heist

The first launch (§2.6, §20.2) reads two things before there is an
account, so neither route asks for a token: `GET /v1/protections`, each age
band's quiet night and spending cap from §20.2, and `GET /v1/words`, the
Workshop's word lists. The Keeper's name is an adjective and a noun from
those lists (G58), so it never needs moderation: `PUT /v1/keeper/name
{"adjective", "noun"}` refuses any other word, `GET /v1/keeper` answers it
as `name`, and each Observatory card names its target's Keeper.

## Curation

`src/curation.mjs` is §13.3's curation, "the default creative act".
`GET /v1/curation/:realm?page=n` answers the realm's island, its origin and
name, three of the generator's layouts a page — seeds that are the same for
one player and realm on every server — and what each woven law's swaps
would cost. `POST /v1/curation/:realm/layout {"seed"}` lays one: the
simulation draws the generated island from the seed with the realm's placed
buildings, its Vault's level and the laws woven there in place of its own
(`Island::curated`), and the server publishes it with the generated origin,
its seed and its terrain's digest. An island republished with
`PUT /v1/islands` keeps that origin while its terrain is the layout's —
posts moved and turned, laws swapped — and is authored once the terrain is
edited, so matchmaking judges it against the matching band (§12.22). A swap
is a weave with `"swap": true`: the new law in the old one's slot at §5.6's
price and time, with no hour's rest (G54). `PUT /v1/curation/:realm/name`
names the island from the word lists. The stealth-path count and the hold
measured for an island's digest (G55) are not built.

## The defence log

`src/defences.mjs` is §23.2's defence log. `GET /v1/defences` lists the
season's raids on the player, newest first: matchmade and Trace raids, not
echoes or games among friends. Each is held when Foiled and leaked otherwise,
Partial counted apart (§12.9, G69), with the facts settlement writes into the
heist's outcome (TD.39): the haul denied, the clean haul a full bag would make
on the island less the clean haul of what the raider banked, both priced as
§9.4 prices a crew's unbanked load (G31); how long the defence held, from the
landing to the last crew member out or caught; and the report the
re-simulation's event log gives (`rb_verify` writes it after the verdict,
sim.mjs `report`): where the crew landed, each place a guard reached Alerted
on seeing it, each ward that fired and how often, the bells rung, the realm
alarm's highest level and the posts whose guards caught anyone. A raid
settled before these were kept says so. Each row says whether its replay is
kept, names the island it was played on, and offers Trace where
`traceable()` names that raid (§12.3, G70). Reading the log clears the raid
badge, which `GET /v1/defences/badge` counts.

## The Resonance Lab

`src/lab.mjs` is §8.6's Lab. It has §10.2's chambers and hours for its level
(one chamber and 8 hours at level 1, three and 3 hours at 5), and each
chamber runs one experiment at a time: two restored laws, the first ever
five free minutes (§16), any other 400 Aether a Lab level (§9.5) for the
level's hours less the Archivist's fifth, which applies at home or on guard
(§11.7). An experiment settles when the Lab is next read: a resonance of its
two laws not yet found is found, and named from then on in the Harmony view;
otherwise it is empty and pays §7.6's 3 pages of the law worked on when that
law is in a placed law's school, else of the first placed, and the third
empty experiment with one law hints one of its undiscovered resonances by
its partner's school. A find pays 3 pages of the first law placed; §8.6 says
a discovery pays pages, not how many. From Lab level 3 the third sphere
names, once a UTC day and free, the first chord in §8.5's table the player
has woven (sounding in the universe, as the simulation sounds it) or crossed
and not named. A heist hints each resonance and chord the island it crossed
makes (§8.6). Two tier III laws with opposite notes are warned an unstable
pairing and run as an ordinary experiment until the paradox laws ship. The
home names the experiments running, so the device sets its own "experiment
finished" timer (§14.6). `GET /v1/lab` settles and shows the chambers, the
next experiment's price and time, what is found and hinted, and how many of
launch's 12 signature resonances remain in each school; `POST /v1/lab`
starts one; `POST /v1/lab/sphere` names a chord.

## Constellations and crews

`src/social.mjs` is §17.1's constellations and §17.7's crews:

- **Constellations.** The Beacon opens from Keeper level 6. Up to thirty
  Keepers: a founder, up to four elders the founder names, and members; a
  Keeper is in one at a time. Joining asks no approval, leaving costs
  nothing, and a founder who leaves hands it to the longest-standing elder,
  else member. Names come from the Workshop's word lists.
- **The constellation league** (§17.5) ranks by members' combined Renown at
  each season's close.
- **Crews** are four to eight, joined by an invite code — the only way
  friends "across constellations" find each other here — and carry on
  whoever leaves.
- **The player's own** constellation and crew are asked for by
  `GET /v1/constellations/mine` and `GET /v1/crews/mine`, so a device that
  knows nothing yet — a new phone, a reinstall — finds them.

Chat, the Grand Law vote, anomalies, page requests and borrowed crew are not
built — register **D63**.

## What is not built

- **A Play Games player id** (D67), and the operator's side of refunds:
  setting the notification URL in App Store Connect.
- **Crossing realms.** The simulation plays one island at a time, so every
  lease is §5.4's 150 seconds with no links, and a crew lands on the island
  it raids even when that is the Heart (D71).
- **Family approval** for 13 to 15 (D64).
- §12.22's generated fallback targets (D66).
- **Constellation chat, votes and anomalies** (D63).

## Layout

    src/sim.mjs       sim/'s WebAssembly builds, one per rules version
    src/store.mjs     content-addressed storage, cross-checked SHA-256
    src/db.mjs        §24.8's schema; append-only by trigger
    src/economy.mjs   §9.4's entry fee and §9.6's haul, in exact ratios
    src/tokens.mjs    signed session tokens
    src/service.mjs   lease, validate, grant
    src/refused.mjs   the refusal every module throws: a status and a reason
    src/seasons.mjs   §12.9's Renown, §18.1's leagues and seasons, the rollover
    src/leagues.json  the league boundaries, generated by tools/league_model.py
    src/social.mjs    §17's constellations and crews
    src/track.mjs     §18.2's season track: stars, tiers, the premium track
    src/shop.mjs      products priced in money, gifts, refunds, §20.2's caps, cosmetics owned and worn
    src/cosmetics.json  the cosmetics sold (none authored yet)
    src/telemetry.mjs first-party events, pseudonymous, kept 90 days, and the report
    src/edge.mjs      an under-13 deletion's bundles purged from the edge's cache (D70)
    src/offline.mjs   what the device built, placed, assigned and wove offline, confirmed in order
    src/weaving.mjs   §5.6's law slots, the crown's, and what each weave costs
    src/accounts.mjs  deleting an account: the person goes, the records stay; the journal
    web/delete.html   deletion without the app, signed in with Google (G39)
    src/privacy.mjs   privacy.json checked against the schema; declarations.md written
    privacy.json      every stored column: its store data type, purpose, time kept, deletion
    declarations.md   the App Privacy and Data safety answers, written from privacy.json
    src/glicko.mjs    Glicko-2, pure arithmetic
    src/matchmaking.mjs  §12.22's ratings and offer, §12.3's echoes, shield and Trace
    src/stores.mjs    the stores' proofs: Game Center, StoreKit 2, Google sign-in, Play purchases
    src/googleapi.mjs Google's APIs as a service account: a Play purchase looked up and settled, voided ones listed
    src/push.mjs      push through Firebase Cloud Messaging: the message, and what FCM's answer means
    src/notifications.mjs  the outbox: a heist against you, the daily reminder, §20.2's nights
    src/friends.mjs   friends, friendly heists, the friends' feed, challenge links
    src/eras.mjs      §18.3's era of the week, on every lease
    load.mjs          the load test; load.json its last measurement
    src/workshop.mjs  §18.6's Workshop: publish, browse, play, rate, report, moderate, remix
    src/words.json    the word lists Workshop names come from
    src/http.mjs      the edge function: Request in, Response out
    src/main.mjs      a local node:http listener around it
    src/facts.json    generated by tools/design_facts.py --json
    test/             node:test, against the real simulation build
