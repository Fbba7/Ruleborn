# Store declarations

Written by `server/src/privacy.mjs` from `server/privacy.json`, which declares every column the
server stores; do not edit here. What the forms ask, answered from what the server does.

## App Store Connect: App Privacy

Do you or your third-party partners collect data from this app? **Yes.** Used to track you: **none** — no data type is used for tracking, and Ruleborn has no advertising (§20.2).

| Category | Data type | Purposes | Linked to the user | Used for tracking | What it is |
|---|---|---|---|---|---|
| Identifiers | User ID | Analytics, App Functionality, Other Purposes | Yes | No | the account id, the platform identity, the telemetry pseudonym |
| Identifiers | Device ID | App Functionality | Yes | No | the push token |
| Location | Coarse Location | App Functionality | Yes | No | the country a signed-in device was last seen in, for its devices list; never an address |
| Purchases | Purchase History | Analytics, App Functionality, Other Purposes | Yes | No | store purchases and gifts (products, prices, refunds), owned cosmetics and premium tracks |
| User Content | Gameplay Content | App Functionality | Yes | No | islands, heists and their replays, ratings, seasons |
| User Content | Other User Content | App Functionality, Other Purposes | Yes | No | reports of Workshop islands |
| Usage Data | Other Usage Data | Analytics, App Functionality, Other Purposes | Yes | No | friends, constellations, crews, blocks; notification settings, moderation |
| Usage Data | Product Interaction | Analytics, App Functionality | Yes | No | sessions and what was done in them |
| Diagnostics | Crash Data | Analytics | Yes | No | whether a session ended in a crash |
| Other Data | Other Data Types | App Functionality, Other Purposes | Yes | No | the age band; the device's time zone |

## Google Play: Data safety

- Does your app collect or share any of the required user data types? **Yes** (collected; shared: **No**).
- Is all of the user data collected by your app encrypted in transit? **Yes**.
- Account creation: **Sign-in with the platform's own identity (Game Center, Sign in with Google)**.
- Deletion: account deletion inside the app **Yes**; a web link to request deletion: **/account/delete on the game's server, signed in with Google (G39)**; deleting some data without the account: **No**.

| Category | Data type | Collected | Shared | Processed ephemerally | Required or optional | Purposes |
|---|---|---|---|---|---|---|
| Personal info | User IDs | Yes | No | No | Required | Account management, Analytics, App functionality, Fraud prevention, security, and compliance |
| Device or other IDs | Device or other IDs | Yes | No | No | Optional | App functionality |
| Location | Approximate location | Yes | No | No | Required | Account management, Fraud prevention, security, and compliance |
| Financial info | Purchase history | Yes | No | No | Required | Analytics, App functionality, Fraud prevention, security, and compliance |
| App activity | Other user-generated content | Yes | No | No | Required | App functionality, Fraud prevention, security, and compliance |
| App activity | Other actions | Yes | No | No | Required | Account management, Analytics, App functionality, Fraud prevention, security, and compliance |
| App activity | App interactions | Yes | No | No | Required | Account management, Analytics, App functionality, Fraud prevention, security, and compliance |
| App info and performance | Crash logs | Yes | No | No | Required | Analytics |
| Personal info | Other info | Yes | No | No | Required | Account management, App functionality, Fraud prevention, security, and compliance |

## Age ratings

Chosen rating: **13+** (§20.1: "Rating: 13+ on the App Store, chosen on purpose even though the content alone would likely rate 9+"). Question names are the 2025 forms'; check them against the live form when filing.

App Store Connect's age rating questionnaire:

| Group | Question | Answer | Because |
|---|---|---|---|
| Features | Parental controls | **No** | §20.2: "Protections by age band" The age bands set the protections; there is no parental control in the app. |
| Features | Age assurance | **Yes** | §20.1: "at first launch the game asks the platform for the player's age band" |
| Features | Unrestricted web access | **No** | The app has no web view; its one link, the terms of use, opens in the device's own browser (client/scripts/workshop_screen.gd). |
| Features | User-generated content | **Yes** | §20.10: "Workshop islands are structured data — laws, terrain, guards, layout — not files" |
| Features | Messaging and chat | **No** | §17.1: "From version 1.1: up to 30 Keepers, joined through the Beacon from Keeper level 6: a founder, up to four elders, and members. Chat, shared replays and shared heist plans." Chat arrives with constellations in version 1.1; the launch build has none. Answer again when it ships. |
| Features | Advertising | **No** | §20.5: "no advertising identifiers" |
| Mature themes | Profanity or crude humor | **None** | §18.6: "Safety: island names come from word lists, 64 adjectives and 64 nouns in each launch language, at every age (20.7), so no name needs filtering; every island can be reported for one of five fixed reasons — an offensive name, impossible to clear, a copy of another creator’s island, a bug used to make it, or something else — with no free text; featured islands are reviewed by a person; and players aged 13 to 15 browse curated lists only (20.7)." No free text anywhere: every name a player gives comes from the game's word lists. |
| Mature themes | Horror or fear themes | **None** | §3: "Tone: wonder, cleverness and warmth; a heist caper in a picture-book sky." |
| Mature themes | Alcohol, tobacco or drug use or references | **None** | §3: "Tone: wonder, cleverness and warmth; a heist caper in a picture-book sky." |
| Medical or wellness | Medical or treatment information | **None** | §3: "Tone: wonder, cleverness and warmth; a heist caper in a picture-book sky." |
| Medical or wellness | Health or wellness topics | **None** | §3: "Tone: wonder, cleverness and warmth; a heist caper in a picture-book sky." |
| Sexuality or nudity | Mature or suggestive themes | **None** | §3: "Tone: wonder, cleverness and warmth; a heist caper in a picture-book sky." |
| Sexuality or nudity | Sexual content or nudity | **None** | §3: "Tone: wonder, cleverness and warmth; a heist caper in a picture-book sky." |
| Sexuality or nudity | Graphic sexual content and nudity | **None** | §3: "Tone: wonder, cleverness and warmth; a heist caper in a picture-book sky." |
| Violence | Cartoon or fantasy violence | **Infrequent or mild** | §3: "Nothing is killed; knocked-out characters wake up at home." Crews and guards knock each other out in a heist, in picture-book art; §20.1 puts the content alone at 9+. |
| Violence | Realistic violence | **None** | §3: "Nothing is killed; knocked-out characters wake up at home." |
| Violence | Prolonged graphic or sadistic realistic violence | **None** | §3: "Nothing is killed; knocked-out characters wake up at home." |
| Violence | Guns or other weapons | **None** | §3: "Nothing is killed; knocked-out characters wake up at home." |
| Chance-based activities | Simulated gambling | **None** | §20.3: "No paid randomness of any kind, and odds shown for every random reward." |
| Chance-based activities | Contests | **None** | §20.3: "No paid randomness of any kind, and odds shown for every random reward." Leagues rank play; nothing is entered or won for money. |
| Chance-based activities | Gambling | **No** | §20.3: "No paid randomness of any kind, and odds shown for every random reward." |
| Chance-based activities | Loot boxes | **No** | §20.3: "No paid randomness of any kind, and odds shown for every random reward." |

Google Play's IARC questionnaire:

| Question | Answer | Because |
|---|---|---|
| Violence | **Yes: cartoon or fantasy characters knocked out, no blood, no deaths** | §3: "Nothing is killed; knocked-out characters wake up at home." |
| Fear | **No** | §3: "Tone: wonder, cleverness and warmth; a heist caper in a picture-book sky." |
| Sexuality | **No** | §3: "Tone: wonder, cleverness and warmth; a heist caper in a picture-book sky." |
| Gambling | **No** | §20.3: "No paid randomness of any kind, and odds shown for every random reward." |
| Language | **No** | §18.6: "Safety: island names come from word lists, 64 adjectives and 64 nouns in each launch language, at every age (20.7), so no name needs filtering; every island can be reported for one of five fixed reasons — an offensive name, impossible to clear, a copy of another creator’s island, a bug used to make it, or something else — with no free text; featured islands are reviewed by a person; and players aged 13 to 15 browse curated lists only (20.7)." No free text anywhere: names come from the word lists. |
| Controlled substances | **No** | §3: "Tone: wonder, cleverness and warmth; a heist caper in a picture-book sky." |
| Crude humour | **No** | §3: "Tone: wonder, cleverness and warmth; a heist caper in a picture-book sky." |
| Users can interact or exchange content | **Yes: players raid each other's islands and play each other's Workshop islands; no chat, no free text** | §20.10: "Workshop islands are structured data — laws, terrain, guards, layout — not files" |
| Shares the user's location | **No** | §20.5: "Collect only what's needed to run the game" |
| Digital purchases | **Yes: cosmetics and the season track's premium track** | §20.3: "No power, speed or skipped waiting for money." |
| Purchases of random items (loot boxes) | **No** | §20.3: "No paid randomness of any kind, and odds shown for every random reward." |
| Unrestricted internet | **No** | §20.10: "No advertising SDKs and no cross-app tracking" |

Export compliance — Uses non-exempt encryption (ITSAppUsesNonExemptEncryption): **No: only standard TLS, for the game's own traffic, which is exempt** (§24.6: "Issued and renewed by the platform; every connection encrypted by default").

## Where each data type is stored

- **User ID** (the account id, the platform identity, the telemetry pseudonym): `accounts.id`, `accounts.platform_identity`, `accounts.push_session`, `islands.owner`, `realms.owner`, `buildings.owner`, `characters.owner`, `producers.owner`, `nurseries.owner`, `stray_offers.owner`, `codex.owner`, `observatory_refreshes.owner`, `lab_experiments.owner`, `lab_discoveries.owner`, `law_slots.owner`, `studies.owner`, `snapshots.owner`, `target_lists.list`, `target_lists.previous`, `leases.attacker`, `leases.defender`, `heists.attacker`, `heists.defender`, `ledger.account`, `ratings.key`, `workshop_items.creator`, `workshop_plays.player`, `workshop_completions.player`, `workshop_ratings.player`, `workshop_remixes.player`, `workshop_reports.reporter`, `standings.account`, `season_results.account`, `renown.account`, `season_stars.account`, `track_claims.account`, `premium_tracks.account`, `constellation_members.account`, `crew_members.account`, `friends.a`, `friends.b`, `friends.invited_by`, `friend_invites.account`, `blocks.blocker`, `blocks.blocked`, `challenges.account`, `purchase_intents.account`, `purchase_intents.recipient`, `intent_tombstones.account`, `purchases.account`, `purchases.recipient`, `notifications.account`, `bans.identity`, `sessions.id`, `sessions.account`, `linked_identities.identity`, `linked_identities.account`, `event_batches.who`, `first_seen.who`, `links.owner`, `fund_payouts.creator`.
- **Device ID** (the push token): `accounts.push_token`.
- **Coarse Location** (the country a signed-in device was last seen in, for its devices list; never an address): `sessions.place`.
- **Purchase History** (store purchases and gifts (products, prices, refunds), owned cosmetics and premium tracks): `accounts.cosmetics`, `premium_tracks.season`, `premium_tracks.bought_at`, `purchase_intents.id`, `purchase_intents.product`, `purchase_intents.price`, `purchase_intents.created_at`, `purchase_intents.redeemed_at`, `intent_tombstones.id`, `intent_tombstones.deleted_at`, `purchases.store`, `purchases.txn`, `purchases.product`, `purchases.price`, `purchases.intent`, `purchases.at`, `refunds.store`, `refunds.txn`, `refunds.kind`, `refunds.at`, `event_batches.events`.
- **Gameplay Content** (islands, heists and their replays, ratings, seasons): `accounts.equipped`, `accounts.keeper_level`, `accounts.keeper_xp`, `accounts.working_on`, `accounts.guardian_sage`, `accounts.defences_seen_at`, `accounts.profile_public`, `accounts.keeper_adjective`, `accounts.keeper_noun`, `accounts.fund_opt_in`, `accounts.raids`, `accounts.raider_rating`, `accounts.raider_deviation`, `accounts.raider_volatility`, `accounts.raider_games`, `islands.realm`, `islands.bundle`, `islands.changed_at`, `islands.origin`, `islands.seed`, `islands.terrain`, `islands.name_adjective`, `islands.name_noun`, `realms.realm`, `realms.type`, `realms.level`, `realms.opened_at`, `buildings.realm`, `buildings.kind`, `buildings.n`, `buildings.level`, `buildings.changed_at`, `buildings.x`, `buildings.y`, `characters.kind`, `characters.traits`, `characters.level`, `characters.home`, `characters.via`, `characters.form`, `characters.name_adjective`, `characters.name_noun`, `characters.joined_at`, `characters.work_realm`, `characters.work_kind`, `characters.work_n`, `characters.work_since`, `characters.away_from`, `characters.away_until`, `producers.realm`, `producers.kind`, `producers.stored`, `producers.settled_at`, `nurseries.realm`, `nurseries.since`, `stray_offers.heist`, `stray_offers.kind`, `stray_offers.traits`, `stray_offers.law`, `stray_offers.found_at`, `stray_offers.answer`, `stray_offers.character`, `codex.law`, `codex.pages`, `codex.tier`, `codex.met_at`, `codex.restored_at`, `codex.woven_at`, `codex.crossed_at`, `observatory_refreshes.at`, `observatory_refreshes.shown`, `lab_experiments.chamber`, `lab_experiments.laws`, `lab_experiments.started_at`, `lab_experiments.ready_at`, `lab_experiments.unstable`, `lab_experiments.settled_at`, `lab_experiments.result`, `lab_discoveries.kind`, `lab_discoveries.id`, `lab_discoveries.found_at`, `law_slots.realm`, `law_slots.slot`, `law_slots.law`, `law_slots.tier`, `law_slots.ready_at`, `law_slots.rests_until`, `studies.token`, `studies.law`, `studies.pages`, `studies.at`, `snapshots.bundle`, `snapshots.realm`, `snapshots.realm_level`, `snapshots.vault_level`, `snapshots.exposed`, `snapshots.published_at`, `snapshots.origin`, `leases.token`, `leases.bundle`, `leases.seed`, `leases.ticks`, `leases.issued_at`, `leases.expires_at`, `leases.echo`, `leases.trace_of`, `leases.mode`, `leases.challenge`, `leases.era`, `leases.universe`, `heists.token`, `heists.bundle`, `heists.seed`, `heists.log_hash`, `heists.state_hash`, `heists.validated`, `heists.outcome`, `heists.review`, `heists.grace`, `heists.submitted_at`, `heists.day`, `ledger.starlight`, `ledger.essence`, `ledger.aether`, `ledger.paid`, `ledger.reason`, `ledger.heist`, `ledger.at`, `ledger.starlight_total`, `ledger.essence_total`, `ledger.aether_total`, `ledger.season`, `ledger.stars`, `ledger.stars_total`, `ledger.renown`, `ledger.renown_total`, `ratings.rating`, `ratings.deviation`, `ratings.volatility`, `ratings.games`, `ratings.updated_at`, `workshop_items.id`, `workshop_items.bundle`, `workshop_items.realm_level`, `workshop_items.name_adjective`, `workshop_items.name_noun`, `workshop_items.remix_of`, `workshop_items.cleared_by`, `workshop_items.bytes`, `workshop_items.published_at`, `workshop_items.withdrawn_at`, `workshop_items.featured_at`, `workshop_items.review`, `workshop_plays.token`, `workshop_plays.item`, `workshop_plays.seed`, `workshop_plays.ticks`, `workshop_plays.issued_at`, `workshop_plays.submitted_at`, `workshop_plays.outcome`, `workshop_plays.counted`, `workshop_completions.item`, `workshop_completions.weight`, `workshop_completions.at`, `workshop_completions.counted`, `workshop_ratings.item`, `workshop_ratings.fun`, `workshop_ratings.cleverness`, `workshop_ratings.fairness`, `workshop_ratings.at`, `workshop_ratings.counted`, `workshop_remixes.item`, `workshop_remixes.at`, `standings.season`, `standings.start`, `standings.ember`, `standings.tier_stars`, `season_results.season`, `season_results.renown`, `season_results.league`, `season_results.division`, `season_results.reward`, `renown.season`, `renown.amount`, `renown.reason`, `renown.heist`, `renown.at`, `renown.total`, `season_stars.season`, `season_stars.amount`, `season_stars.reason`, `season_stars.heist`, `season_stars.at`, `season_stars.total`, `track_claims.season`, `track_claims.tier`, `track_claims.track`, `track_claims.reward`, `track_claims.at`, `challenges.code`, `challenges.bundle`, `challenges.created_at`, `notifications.data`, `links.n`, `links.kind`, `links.a`, `links.b`, `links.built_at`, `links.paid_to`, `links.open`, `fund_payouts.seconds`, `files: bundles`, `files: replays`.
- **Other User Content** (reports of Workshop islands): `workshop_reports.item`, `workshop_reports.reason`, `workshop_reports.at`, `workshop_reports.resolved_at`, `workshop_reports.resolution`.
- **Other Usage Data** (friends, constellations, crews, blocks): `constellation_members.constellation`, `constellation_members.role`, `constellation_members.joined_at`, `constellation_members.left_at`, `constellation_members.removed`, `crew_members.crew`, `crew_members.joined_at`, `crew_members.left_at`, `friends.since`, `friends.gift_at`, `friend_invites.code`, `friend_invites.created_at`, `friend_invites.used_at`, `blocks.at`.
- **Product Interaction** (sessions and what was done in them): `accounts.created_at`, `sessions.created_at`, `sessions.used_at`, `sessions.ended_at`, `linked_identities.linked_at`, `event_batches.at`, `event_batches.day`, `event_batches.events`, `first_seen.day`.
- **Other Usage Data** (notification settings, moderation): `accounts.terms_version`, `accounts.banned_at`, `accounts.banned_reason`, `accounts.reminder_at`, `accounts.night_quiet`, `workshop_items.removed_at`, `workshop_items.removed_reason`, `notifications.kind`, `notifications.due_at`, `notifications.sent_at`, `bans.banned_at`, `bans.reason`, `sessions.ended`, `sessions.via`, `event_batches.events`.
- **Crash Data** (whether a session ended in a crash): `event_batches.events`.
- **Other Data Types** (the age band): `accounts.age_band`, `accounts.age_answered_at`.
- **Other Data Types** (the device's time zone): `accounts.time_zone`, `sessions.device`, `sessions.model`, `fund_payouts.cents`.

## What deleting an account does, table by table

Erased: gone. Severed: kept, under an account id that no longer leads to anyone (F43). Kept: not about a person.

| Table | Deleted at the player's request | Deleted because the player is under 13 | Kept for |
|---|---|---|---|
| `accounts` | severed | severed | good: a record (F43) |
| `islands` | erased | erased | as long as the account |
| `realms` | erased | erased | as long as the account |
| `buildings` | erased | erased | as long as the account |
| `characters` | erased | erased | as long as the account |
| `producers` | erased | erased | as long as the account |
| `nurseries` | erased | erased | as long as the account |
| `stray_offers` | erased | erased | as long as the account |
| `codex` | erased | erased | as long as the account |
| `observatory_refreshes` | erased | erased | as long as the account |
| `lab_experiments` | erased | erased | as long as the account |
| `lab_discoveries` | erased | erased | as long as the account |
| `law_slots` | erased | erased | as long as the account |
| `studies` | erased | erased | as long as the account |
| `snapshots` | severed | severed — the row stays, as nobody's; an under-13 player's islands' bytes are deleted from the store | good: a record (F43) |
| `target_lists` | severed | erased — lists are made again at once without the player, and the one before is deleted | while current |
| `leases` | severed | severed — an under-13 player's open leases are deleted | 7 days after expiring unplayed; a played lease is a record kept for good (F43) (`expireLapsed`) |
| `heists` | severed | severed — an under-13 player's replays are deleted at once | good: a record (F43) |
| `ledger` | severed | severed | good: a record (F43) |
| `ratings` | severed | erased — severed on a deletion; deleted for an under-13 player | good: a record (F43) |
| `defence_shares` | kept | kept | good: not about a person |
| `workshop_items` | severed | severed — listed with no creator shown, or withdrawn if the player asked; an under-13 player's islands are withdrawn and their bytes deleted | good: a record (F43) |
| `workshop_plays` | severed | erased — severed on a deletion; deleted for an under-13 player | 1 days after issuing it unsubmitted, its lease's life; a submitted play is a record kept for good (F43), keyed by an id that leads to no one once the account is deleted (`expireLapsed`) |
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
| `blocks` | erased | erased | as long as the account |
| `challenges` | erased | erased | 7 days (`friends.expire`) |
| `purchase_intents` | severed | severed | 7 days after lapsing unredeemed; a redeemed one is a record kept for good (F43) (`expireLapsed`) |
| `intent_tombstones` | severed | severed | 90 days after its intent is deleted (`expireLapsed`) |
| `purchases` | severed | severed | good: a record (F43) |
| `refunds` | kept | kept | good: a record (F43) |
| `notifications` | erased | erased | 7 days after sent (`notifications.expire`) |
| `bans` | kept | kept — kept: the ban outlives the account | as long as the ban |
| `sessions` | erased | erased | 7 days after signed out, ended, or lapsed (30 days unused, 180 days at most) (`auth.expire`) |
| `linked_identities` | erased | erased | as long as the account |
| `auth_spent` | kept | kept — kept: a hash names nobody, and lapses within five minutes | 1 days after its five minutes, when the proof could no longer be accepted anyway (`auth.expire`) |
| `erasures` | kept | kept | while current |
| `edge_purges` | kept | kept | while current |
| `event_batches` | erased | erased | 90 days (`telemetry.compact`) |
| `first_seen` | erased | erased | as long as the account |
| `cohorts` | kept | kept | good: not about a person |
| `event_days` | kept | kept | good: not about a person |
| `links` | erased | erased | as long as the account |
| `fund_quarters` | kept | kept | good: not about a person |
| `fund_payouts` | erased | erased | as long as the account |
| `island_holds` | kept | kept | good: not about a person |

## Outside the database

- `bundles`: the public object store: island bundles and target lists, fetched by hash. Kept islands for good; target lists the current one a band, and the one before for an hour after it is superseded (G38). On deletion: an under-13 player's island bytes are deleted, and the lists made again without them.
- `replays`: the private replay store, fetched only by a heist's two players. Kept 90 days. On deletion: an under-13 player's replays are deleted at once.
- `deletions`: the deletion journal, in object storage: an account id, a reason, a time and whether the player withdrew their Workshop islands, each deletion one object, outside the database so a restore cannot undo a deletion; a start makes again the last 31 days of it (F50). Kept for good: it is the deletion log. On deletion: a deletion is added, never removed.
- `secret`: the server's own key for tokens and pseudonyms. Kept for good. On deletion: not about a person.
- the device's requests: a session token naming the account; the bodies of each route; to the server, over HTTPS: the platform's edge terminates TLS and every answer carries Strict-Transport-Security.
- Game Center sign-in: nothing of the player's: the server fetches Apple's public key by the URL the proof names; to static.gc.apple.com, sandbox.gc.apple.com.
- Google sign-in: nothing of the player's: the server fetches the keys Google signs ID tokens with, from one fixed URL; to www.googleapis.com.
- a Play purchase settled: the purchase's product and token, which Google issued, to look it up and acknowledge it, or consume it if it is a gift; to Google's Play Developer API, as the app's own service account.
- Play's voided purchases, checked daily: nothing of the player's: the app's package and a time window; Google answers with the purchase tokens it voided; to Google's Play Developer API, as the app's own service account.
- push notifications: the push token and a message: localisation keys to show, how many raids and the latest one's id, or the reminder's day; it expires when the player's night begins; to Firebase Cloud Messaging, as the operator's service provider, which passes iPhone messages on to Apple's push service.
- the server's log: a route and an error; never a path's ids or a body; to the operator's platform.
