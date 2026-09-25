# Store declarations

Written by `server/src/privacy.mjs` from `server/privacy.json`, which declares every column the
server stores; do not edit here. What the forms ask, answered from what the server does.

## App Store Connect: App Privacy

Do you or your third-party partners collect data from this app? **Yes.** Used to track you: **none** — no data type is used for tracking, and Ruleborn has no advertising (§20.2).

| Category | Data type | Purposes | Linked to the user | Used for tracking | What it is |
|---|---|---|---|---|---|
| Identifiers | User ID | Analytics, App Functionality, Other Purposes | Yes | No | the account id, the platform identity, the telemetry pseudonym |
| Identifiers | Device ID | App Functionality | Yes | No | the push token |
| Purchases | Purchase History | Analytics, App Functionality, Other Purposes | Yes | No | Starglass bought, the ledger, owned cosmetics |
| User Content | Gameplay Content | App Functionality | Yes | No | islands, heists and their replays, ratings, seasons |
| User Content | Other User Content | App Functionality, Other Purposes | Yes | No | reports of Workshop islands |
| Usage Data | Other Usage Data | Analytics, App Functionality, Other Purposes | Yes | No | friends, constellations, crews; notification settings, moderation |
| Usage Data | Product Interaction | Analytics, App Functionality | Yes | No | sessions and what was done in them |
| Diagnostics | Crash Data | Analytics | Yes | No | whether a session ended in a crash |
| Other Data | Other Data Types | App Functionality, Other Purposes | Yes | No | the age band; the device's offset from UTC |

## Google Play: Data safety

- Does your app collect or share any of the required user data types? **Yes** (collected; shared: **No**).
- Is all of the user data collected by your app encrypted in transit? **Yes**.
- Account creation: **Sign-in with the platform's own identity (Game Center, Play Games)**.
- Deletion: account deletion inside the app **Yes**; a web link to request deletion: **none yet (G39)**; deleting some data without the account: **No**.

| Category | Data type | Collected | Shared | Processed ephemerally | Required or optional | Purposes |
|---|---|---|---|---|---|---|
| Personal info | User IDs | Yes | No | No | Required | Account management, Analytics, App functionality, Fraud prevention, security, and compliance |
| Device or other IDs | Device or other IDs | Yes | No | No | Optional | App functionality |
| Financial info | Purchase history | Yes | No | No | Required | Analytics, App functionality, Fraud prevention, security, and compliance |
| App activity | Other user-generated content | Yes | No | No | Required | App functionality, Fraud prevention, security, and compliance |
| App activity | Other actions | Yes | No | No | Required | Analytics, App functionality, Fraud prevention, security, and compliance |
| App activity | App interactions | Yes | No | No | Required | Analytics, App functionality |
| App info and performance | Crash logs | Yes | No | No | Required | Analytics |
| Personal info | Other info | Yes | No | No | Required | App functionality, Fraud prevention, security, and compliance |

## Where each data type is stored

- **User ID** (the account id, the platform identity, the telemetry pseudonym): `accounts.id`, `accounts.platform_identity`, `islands.owner`, `snapshots.owner`, `target_lists.list`, `target_lists.previous`, `leases.attacker`, `leases.defender`, `heists.attacker`, `ledger.account`, `ratings.key`, `workshop_items.creator`, `workshop_plays.player`, `workshop_completions.player`, `workshop_ratings.player`, `workshop_remixes.player`, `workshop_reports.reporter`, `standings.account`, `season_results.account`, `renown.account`, `season_stars.account`, `track_claims.account`, `premium_tracks.account`, `constellation_members.account`, `crew_members.account`, `friends.a`, `friends.b`, `friend_invites.account`, `challenges.account`, `purchase_intents.account`, `purchases.account`, `notifications.account`, `bans.identity`, `event_batches.who`, `first_seen.who`.
- **Device ID** (the push token): `accounts.push_token`.
- **Purchase History** (Starglass bought, the ledger, owned cosmetics): `accounts.cosmetics`, `ledger.currency`, `ledger.amount`, `ledger.reason`, `ledger.at`, `premium_tracks.season`, `premium_tracks.bought_at`, `purchase_intents.id`, `purchase_intents.product`, `purchase_intents.price`, `purchase_intents.created_at`, `purchase_intents.redeemed_at`, `purchases.store`, `purchases.txn`, `purchases.product`, `purchases.price`, `purchases.intent`, `purchases.at`, `event_batches.events`.
- **Gameplay Content** (islands, heists and their replays, ratings, seasons): `accounts.equipped`, `accounts.keeper_level`, `islands.realm`, `islands.bundle`, `islands.changed_at`, `snapshots.bundle`, `snapshots.realm`, `snapshots.realm_level`, `snapshots.vault_level`, `snapshots.exposed`, `snapshots.published_at`, `leases.token`, `leases.bundle`, `leases.seed`, `leases.ticks`, `leases.issued_at`, `leases.expires_at`, `leases.state`, `leases.echo`, `leases.trace_of`, `leases.mode`, `leases.challenge`, `leases.era`, `heists.token`, `heists.bundle`, `heists.seed`, `heists.log_hash`, `heists.state_hash`, `heists.validated`, `heists.outcome`, `heists.review`, `heists.grace`, `heists.submitted_at`, `heists.day`, `ledger.heist`, `ratings.rating`, `ratings.deviation`, `ratings.volatility`, `ratings.games`, `ratings.updated_at`, `workshop_items.id`, `workshop_items.bundle`, `workshop_items.realm_level`, `workshop_items.name_adjective`, `workshop_items.name_noun`, `workshop_items.remix_of`, `workshop_items.cleared_by`, `workshop_items.bytes`, `workshop_items.published_at`, `workshop_items.withdrawn_at`, `workshop_items.featured_at`, `workshop_items.review`, `workshop_plays.token`, `workshop_plays.item`, `workshop_plays.seed`, `workshop_plays.ticks`, `workshop_plays.issued_at`, `workshop_plays.submitted_at`, `workshop_plays.outcome`, `workshop_completions.item`, `workshop_completions.weight`, `workshop_completions.at`, `workshop_ratings.item`, `workshop_ratings.fun`, `workshop_ratings.cleverness`, `workshop_ratings.fairness`, `workshop_ratings.at`, `workshop_remixes.item`, `workshop_remixes.at`, `standings.season`, `standings.start`, `standings.ember`, `standings.tier_stars`, `season_results.season`, `season_results.renown`, `season_results.league`, `season_results.division`, `season_results.reward`, `renown.season`, `renown.amount`, `renown.reason`, `renown.heist`, `renown.at`, `season_stars.season`, `season_stars.amount`, `season_stars.reason`, `season_stars.heist`, `season_stars.at`, `track_claims.season`, `track_claims.tier`, `track_claims.track`, `track_claims.reward`, `track_claims.at`, `challenges.code`, `challenges.bundle`, `challenges.created_at`, `notifications.data`, `files: bundles`, `files: replays`.
- **Other User Content** (reports of Workshop islands): `workshop_reports.item`, `workshop_reports.reason`, `workshop_reports.at`, `workshop_reports.resolved_at`, `workshop_reports.resolution`.
- **Other Usage Data** (friends, constellations, crews): `constellation_members.constellation`, `constellation_members.role`, `constellation_members.joined_at`, `constellation_members.left_at`, `crew_members.crew`, `crew_members.joined_at`, `crew_members.left_at`, `friends.since`, `friend_invites.code`, `friend_invites.created_at`, `friend_invites.used_at`.
- **Product Interaction** (sessions and what was done in them): `accounts.created_at`, `event_batches.at`, `event_batches.day`, `event_batches.events`, `first_seen.day`.
- **Other Usage Data** (notification settings, moderation): `accounts.banned_at`, `accounts.banned_reason`, `accounts.reminder_at`, `accounts.night_quiet`, `workshop_items.removed_at`, `workshop_items.removed_reason`, `notifications.kind`, `notifications.due_at`, `notifications.sent_at`, `bans.banned_at`, `bans.reason`, `event_batches.events`.
- **Crash Data** (whether a session ended in a crash): `event_batches.events`.
- **Other Data Types** (the age band): `accounts.age_band`.
- **Other Data Types** (the device's offset from UTC): `accounts.utc_offset`.

## What deleting an account does, table by table

Erased: gone. Severed: kept, under an account id that no longer leads to anyone (F43). Kept: not about a person.

| Table | Deleted at the player's request | Deleted because the player is under 13 | Kept for |
|---|---|---|---|
| `accounts` | severed | severed | good: a record (F43) |
| `islands` | erased | erased | as long as the account |
| `snapshots` | severed | severed — the row stays, as nobody's; an under-13 player's islands' bytes are deleted from the store | good: a record (F43) |
| `target_lists` | severed | erased — lists are made again at once without the player, and the one before is deleted | while current |
| `leases` | severed | severed — an under-13 player's open leases are deleted | good: a record (F43) |
| `heists` | severed | severed — an under-13 player's replays are deleted at once | good: a record (F43) |
| `ledger` | severed | severed | good: a record (F43) |
| `ratings` | severed | erased — severed on a deletion; deleted for an under-13 player | good: a record (F43) |
| `defence_shares` | kept | kept | good: not about a person |
| `workshop_items` | severed | severed — withdrawn; an under-13 player's islands' bytes are deleted | good: a record (F43) |
| `workshop_plays` | severed | erased — severed on a deletion; deleted for an under-13 player | good: a record (F43) |
| `workshop_completions` | severed | erased — severed on a deletion; deleted for an under-13 player | good: a record (F43) |
| `workshop_ratings` | severed | erased — severed on a deletion; deleted for an under-13 player | good: a record (F43) |
| `workshop_remixes` | severed | erased — severed on a deletion; deleted for an under-13 player | good: a record (F43) |
| `workshop_reports` | severed | severed — an under-13 player's reports stand as nobody's | good: a record (F43) |
| `seasons` | kept | kept | good: not about a person |
| `standings` | severed | severed | good: a record (F43) |
| `season_results` | severed | severed | good: a record (F43) |
| `renown` | severed | severed | good: a record (F43) |
| `season_stars` | severed | severed | good: a record (F43) |
| `constellation_results` | kept | kept | good: not about a person |
| `track_claims` | severed | severed | good: a record (F43) |
| `premium_tracks` | severed | severed | good: a record (F43) |
| `constellations` | kept | kept | good: not about a person |
| `constellation_members` | severed | severed — the player leaves; the row stays with left_at set | good: a record (F43) |
| `crews` | kept | kept | good: not about a person |
| `crew_members` | severed | severed — the player leaves; the row stays with left_at set | good: a record (F43) |
| `friends` | erased | erased | as long as the account |
| `friend_invites` | erased | erased | 7 days (`friends.expire`) |
| `challenges` | erased | erased | 7 days (`friends.expire`) |
| `purchase_intents` | severed | severed | good: a record (F43) |
| `purchases` | severed | severed | good: a record (F43) |
| `notifications` | erased | erased | 7 days after sent (`notifications.expire`) |
| `bans` | kept | kept — kept: the ban outlives the account | as long as the ban |
| `erasures` | kept | kept | while current |
| `event_batches` | erased | erased | 90 days (`telemetry.compact`) |
| `first_seen` | erased | erased | as long as the account |
| `cohorts` | kept | kept | good: not about a person |
| `event_days` | kept | kept | good: not about a person |

## Outside the database

- `bundles`: the public object store: island bundles and target lists, fetched by hash. Kept islands for good (snapshots); target lists the current and previous a band. On deletion: an under-13 player's island bytes are deleted, and the lists made again without them.
- `replays`: the private replay store, fetched only by a heist's two players. Kept 90 days (expireReplays). On deletion: an under-13 player's replays are deleted at once.
- `deletions.jsonl`: the deletion journal: an account id, a reason and a time a line, outside the database so a restore cannot undo a deletion. Kept for good: it is §20.12's log. On deletion: a deletion is added, never removed.
- `secret`: the server's own key for tokens and pseudonyms. Kept for good. On deletion: not about a person.
- the device's requests: a session token naming the account; the bodies of each route; to the server, over HTTPS: the platform's edge terminates TLS and every answer carries Strict-Transport-Security.
- Game Center sign-in: nothing of the player's: the server fetches Apple's public key by the URL the proof names; to static.gc.apple.com, sandbox.gc.apple.com.
- push notifications: the push token and a message: the heists raided, or the reminder's day; to Firebase Cloud Messaging, as the operator's service provider (not built, D68).
- the server's log: a route and an error; never a path's ids or a body; to the operator's platform.
