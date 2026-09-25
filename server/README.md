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

§9.6's three caps are enforced at grant, where §24.12's Validate "checks …
the caps": a raid never pays more than 1.98 times its base (derived from the
richness and difficulty terms that set it), a day never more than "half again
above" the whole fatigue curve, and a week never more than "five days' worth"
of it. Three readings are taken there (register **G20**): the curve is in the
raider's own Vault level's base, "five days' worth" is five days of the curve
rather than of the ceiling, and the week starts on Monday, UTC.

Target lists are §24.8's "file, not a query": `Service.targetLists()` writes
one content-addressed list a band, holding every island's current snapshot, and
`GET /v1/targets` names the current file for each; the file itself is fetched
by hash like a bundle, so an unchanged band keeps its edge cache. Two readings
(register **G21**): a band is a realm level, the unit of §12.22's guarantee,
and "generated periodically" is every fifteen minutes (`main.mjs`).

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
  the server. It filters by Renown within 150, Keeper level within 3 and
  rating within a band of the raider's recent success; sorts by predicted
  success; draws the middle from the band; counts echoes when fewer than
  three sit in the band; and only then widens rating, Keeper level and
  Renown, in that order, saying so.
- **Echoes.** A snapshot no island is on any more can be leased for 14 days;
  robbing it takes nothing from its owner and moves no Renown.
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
  fee and §9.4's "5% of what the crew was carrying": the simulation reports
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

## The season track, Starglass and cosmetics

`src/track.mjs` is §18.2's season track and §18.8's rules for it:

- **Stars.** Each heist earns season stars in the grant's transaction: the
  raider ten times §12.9's outcome, the defender the rest of ten. Stars are
  spent on tiers, and a season's unspent stars are gone when it ends (§9.1's
  "reset each season").
- **Tiers.** Fifty, claimed in order. Tier 1 is free on day one (§14.8); each
  after costs a tier's stars, scaled to the time left for a player first seen
  late in a season (§18.8's catch-up). A past season's unclaimed tiers stay
  on offer, bought with this season's stars at that season's price.
- **Premium.** Bought with Starglass, for this season or an earlier one at the
  same price; its cosmetics come with every tier claimed, before or after.

`src/shop.mjs` is §22.1's shop and §20.2's caps:

- **Starglass** is held in the ledger as euros in hundredths (§19.12's 1:1).
  A pack is bought in two steps: an intent, refused if it would take a minor
  past the month's cap (€25 at 13 to 15, €50 at 16 and 17) and held for a
  quarter of an hour; then the store's receipt, granted once per store
  transaction. Adults get §20.2's monthly spending summary. `Service` takes a
  `verifyReceipt(store, receipt)` function, as it takes `verifyPlatform`;
  `main.mjs` gives none, so it refuses every receipt.
- **Cosmetics** are bought with Starglass from `src/cosmetics.json`, owned in
  §24.8's `accounts.cosmetics`, and worn slot by slot: one of each kind, an
  outfit a crew role and a visual a law. A lease carries the defender's worn
  set, so a raider sees the island as it was dressed.

The figures the document does not give — stars, tier price, rewards, packs —
are named constants, register **G28**. What Starglass is meant to be is
**F41**; what is not built is **D64**. A database made before Starglass has
its ledger rebuilt around its rows when opened.

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
  purchased (not pending or cancelled) and one pack. The purchase token is
  the transaction, granted once; the intent rides as its
  obfuscatedAccountId. Then Google is asked (`src/googleapi.mjs`, the Play
  Developer API as a service account): the purchase must still be paid for
  and not a licence tester's, unless the operator allows test purchases,
  and the server consumes it before granting — a purchase nobody consumes
  is refunded by Play after three days, whatever was granted.

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
  no entry fee, no Renown, stars or rating, and "the friend loses nothing";
  the outcome records the page the friend earns "for every raider their
  guards catch". A new player's protection does not stop a friend.
- **The friends' feed** is derived from the heists already written, so it
  costs no write: friends' heists, raiding or raided, from the last week.
- **A challenge link** is a code for the player's island that anyone holding
  it can play once, as a friendly heist is played.

The readings are **G35**; what a game among friends pays is **F48**.

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
  08:00 at 16 and 17 and, by default, for adults, who may open it), on the
  player's own clock; raids before a notification is sent are gathered into
  it. `main.mjs` delivers once a minute.
- **Push** (`src/push.mjs`) is Firebase Cloud Messaging's HTTP v1 API, sent
  as the project's service account (`RULEBORN_FCM_SERVICE_ACCOUNT`, its JSON
  key; `RULEBORN_FCM_PROJECT` if the project is not the key's own). A
  message names localisation keys — `ruleborn_raided_title` and `_body`,
  `ruleborn_reminder_title` and `_body` — which the app's native string
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

The readings are **G34**, what is not built **D68**.

## Under load

`load.mjs` is phase 14's load test. It plays §14.1's engaged, regular and
casual players through the service as built — every lease, validation,
grant, Renown line, star, rating and event batch — and measures what §24.1
budgets: rows written a player a day, by what wrote them, and the CPU a
re-simulation takes. The writes are deterministic, so `server/load.json`
keeps them and `bash tools/check_all.sh` fails if a change moves them
(`--write` records a new baseline). What it measured — an engaged day
writes at least 46 rows against §24.1's five, and a re-simulation takes
about 15 ms against the free plan's 10 — is register **F47**; its
readings are **G33**. Telemetry is written a batch to a row, as §24.1 asks.

## Telemetry

`src/telemetry.mjs` is §24's first-party analytics, under §20.5 and §24.3's
rules:

- **What is logged.** The server records what it decides: a session (a
  sign-in), a heist's "outcome, laws crossed, crew", and a purchase. The
  device sends the rest to `POST /v1/events` in batches — weaving, births,
  session ends, the one-tap "Was this worth your time?" and the survey — and a
  batch is checked whole: known events, known fields of known types, times no
  later than now, and no field that is a position ("The client never sends
  coordinates"). A player is surveyed at most once a quarter (§25.4).
- **Pseudonymous.** Every row is keyed by an HMAC of the account under the
  server's secret, so the events alone name nobody.
- **Kept 90 days.** `Telemetry.compact`, run daily by `main.mjs`, writes each
  finished cohort's day-1, day-7 and day-30 returns and each day's counts, and
  discards the raw events past 90 days.
- **Queryable.** `GET /v1/metrics` gives analysts the figures the launch
  gates read — players, sessions and the crash-free share, heists by
  outcome, the average "worth your time", the share who bought, and cohort
  retention — and `/v1/metrics/absence` §25.3's churn early warning.

The readings are register **G29**; the heatmaps and the error reporter are
**D65**.

## Deleting an account

`src/accounts.mjs` is §20.5's "Account and data deletion from inside the
game", reached by `DELETE /v1/account` — and by declaring an age under 13,
which §20.11 says is deleted at once. What identifies the person goes: the
platform identity (signing in again starts a new account), the telemetry
under their pseudonym, their islands from matchmaking and the target lists,
their places in constellations and crews, and any token they hold. What the
document keeps unchanged stays under an id that leads to nobody: the ledger,
Renown, heists, snapshots, and their Workshop islands, withdrawn rather than
deleted so a remix still names its original. That reading is register
**F43**. Their notifications, sent or waiting, go too, and a raid leased
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
finished when the server next starts. A raid leased on anyone before their
deletion settles for the raider and, like an echo, pays, rates and records
nothing of the one who is gone. A ban keeps only the platform identity, and
the day, in `bans`, apart from the account (§20.12's "minimum
identifiers"): it ends the player's friendships and invites, and a banned
player's deletion severs the rest like anyone's and clears the ban's time
from the account, so nothing matches it back.

§20.12's "backups included": each deletion is appended to a journal outside
the database — an account id, a reason, a time — before it is made, and
`main.mjs` makes every journalled deletion again at start, so a database
restored from before one does not bring the player back (**F50**). The
journal must live where a restore of the database does not reach.

## What the server stores, and the stores' declarations

`privacy.json` declares every column of every table — 236 in 39 — with the
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
seven days and a challenge link after its seven, and a band keeps its
current target list and the one before; at start the server sweeps any list
no band names, which a crash, a restore or an older server left. Every answer carries
`Strict-Transport-Security`, the listener's log names a route and never a
path's ids, and a new account holds the most protective age band, 13 to 15,
until the device's age check answers (`PUT /v1/age`). Not answered: the web
link Google asks for to request deletion without the app (**G39**); filing
both forms, and the client's age check and deletion button (**D70**).

    node server/src/privacy.mjs --write    # after changing privacy.json

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

Chat, the Grand Law vote, anomalies, page requests and borrowed crew are not
built — register **D63**.

## What is not built

- **Refunds after a grant** (D67): App Store Server Notifications and Play's
  voided purchases, which tell the server of a refund the player asked for
  after the grant; and a Play Games player id.
- **Crossing realms.** The simulation plays the Heart alone, so every lease
  is §5.4's 150 seconds with no links.
- **Family approval** for 13 to 15 (D64).
- §12.22's generated fallback targets (D66).
- **Constellation chat, votes and anomalies** (D63).
- **The landing.** The replay has no landing command yet; see `sim/README.md`.

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
    src/shop.mjs      Starglass packs, §20.2's caps, cosmetics owned and worn
    src/cosmetics.json  the cosmetics sold for Starglass (none authored yet)
    src/telemetry.mjs first-party events, pseudonymous, kept 90 days, and the report
    src/accounts.mjs  deleting an account: the person goes, the records stay; the journal
    src/privacy.mjs   privacy.json checked against the schema; declarations.md written
    privacy.json      every stored column: its store data type, purpose, time kept, deletion
    declarations.md   the App Privacy and Data safety answers, written from privacy.json
    src/glicko.mjs    Glicko-2, pure arithmetic
    src/matchmaking.mjs  §12.22's ratings and offer, §12.3's echoes, shield and Trace
    src/stores.mjs    the stores' proofs: Game Center, StoreKit 2, Google sign-in, Play purchases
    src/googleapi.mjs Google's APIs as a service account: a Play purchase looked up and consumed
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
