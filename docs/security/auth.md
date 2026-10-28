# Sign-in and sign-out: threat model and design

Owner of this file: the auth track (T11). It covers how a player proves who
they are, how a session is held, how it ends, and what the device keeps.

The design document wins wherever it states a rule. The rules it states:

- §24.8: "No passwords. Platform identity — Game Center on iPhone, the
  player's Google account on Android — is exchanged for a short-lived signed
  token." A Game Center proof is Apple's signature over the player, the app, a
  timestamp and a salt, with the key fetched only from Apple's key hosts over
  HTTPS, checked to a pinned root and at most five minutes old. A Google ID
  token is accepted until its expiry, with five minutes of clock skew.
  Submissions are single-use (server-issued nonces).
- §24.1's limits: six sign-ins a minute an account (ten at once, then one
  every 10 seconds), twenty failed sign-ins a minute an address (twenty at
  once, then one every 3 seconds, an IPv6 address counted by its /64). Past
  a limit the answer is "held back", with when to retry.
- §20.5: collect only what is needed; anything that names a player and serves
  no purpose once closed is deleted within seven days of closing; deletion in
  the game and from a web page by signing in with the same Google account.
- §20.11–§20.12: deletion within thirty days, a ban that outlives the account.
- §20.2: age bands; an account is held to the most protective band until the
  device's age check answers.
- One account across iPhone, iPad, Android and later PC, with platform sign-in.

Where the document is silent (sign-out, refresh, revocation, what the device
stores) the choices below are the market standard, and each is marked
**Choice**.

## Threat model

Each threat: what the attacker wants, how, and what stops it. "Built" points
at the code and the test that prove it.

| # | Threat | Defence |
|---|--------|---------|
| T1 | **Token theft** — an access token read off the wire, a log, a crash report, a URL, a backup | HTTPS only (client refuses `http://` except loopback; server sends HSTS). Tokens only in the `Authorization` header, never a URL. The client's action log and the server's error log name the route alone. Access tokens live an hour; a stolen one dies at sign-out (server-side check every request). The refresh token is in the platform's secure storage, never a plain file. |
| T2 | **Refresh-token theft** — the long-lived credential copied off a device | Rotation on every use; a refresh token used twice revokes its whole family (the thief and the player are both signed out, the player silently signs back in with the platform; the thief cannot). Idle limit 30 days, absolute limit 180 days. Stored on the server only as a salt; the token is an HMAC over it, so a database copy alone mints nothing, and neither does the key alone. |
| T3 | **Replay of a platform proof** — a captured Game Center signature or Google ID token sent again | Game Center: at most five minutes old, and each (player, salt, timestamp) accepted once inside that window. Google: `nonce` must be a server-issued, single-use, five-minute nonce; the same token is refused the second time. |
| T4 | **Forgery** — a made-up access or refresh token, a made-up platform proof | HMAC-SHA256 over every field with a server key; constant-time comparison; a key id in the token. Game Center's key fetched only from `static.gc.apple.com`/`sandbox.gc.apple.com` over HTTPS with no redirects, chained to a pinned root, Apple's organisation in the subject, the bundle id. Google: RS256 against Google's published keys (cached, refetched on an unknown `kid`, rate-limited), `iss`, `aud` among the app's client ids, `exp`/`iat` with five minutes of skew, `sub` numeric. `alg` is pinned (no `none`, no HS256 confusion). |
| T5 | **Session fixation** — an attacker plants a session id the victim then signs into | The server makes every session id itself, at sign-in, from a CSPRNG; a client never names one. A sign-in always makes a new session; the device throws away any session it held before. |
| T6 | **Brute force** — guessing tokens, hammering sign-in | 256-bit MACs over every token; session ids are sequential row ids, not secrets, so a guessed id gains nothing (the security review's note under SR-24). The document's limits per account (sign-ins) and per address (failures only). Refresh is held to the same account bucket as sign-in. |
| T7 | **Enumeration** — learning whether an identity has an account | A refused credential, a revoked session, an expired session and a forged token all answer the same `session_refused` / `platform_identity_refused`, and the same status. A limit answers 429 whether or not the account exists, and an address is held back on failures before any account is read. Sign-in makes an account for a new identity, so "exists" is never a different answer. |
| T8 | **Downgrade** — an old token format, `alg: none`, HTTP, a stubbed verifier in production | Only the current token version is read. JWT `alg` is pinned to RS256. The server refuses to start with stubbed sign-in, stores or not, unless `RULEBORN_STUB_SIGNIN=1` asks for it (`main.mjs`, SR-29). The client refuses a server reached in the clear. |
| T9 | **Lost or stolen device** | "Sign out everywhere" from any other device ends every session at once. The refresh token is in Keychain/Keystore, bound to the device (not in iCloud backups: `kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly`; Android Keystore-wrapped). Deleting the account or a ban ends every session. |
| T10 | **Shared device** — the next person picks up a signed-out phone | Sign-out ends the session on the server first, then clears the access token, the refresh token, every cached private state, and parks the outbox under the account it belongs to (never sent as someone else, never lost). |
| T11 | **Account takeover through a platform switch** — a thief's identity attached to someone else's account, to keep it after the stolen token dies | An account has the identity it was made with and at most one linked identity of the other platform (`linked_identities`). Linking needs a live session **and** two fresh, single-use proofs in the same request: one of an identity the account already signs in with (step-up) and one of the identity added — a stolen access token alone links nothing. An identity that has an account of its own, or a ban, is never linked (no merging). Unlinking needs a fresh proof of the identity that stays and ends every session the removed one signed in (`sessions.via`). A ban bans the linked identity too (`Auth.endAll(…, "banned")`); a deletion erases the link. The web deletion page takes only `gp:`, made-with or linked. |
| T16 | **A session left on a device the player no longer has** — sold, lent, lost | The devices list shows every live session: the device's kind and model as it named them, the country the edge last saw it in, when it was last used (to the hour), its platform. Any one is ended from any other device (`{"device": id}`), or every other at once (`{"others": true}`); an id of another account ends nothing and answers the same. |
| T12 | **Clock skew** — a phone's clock wrong by minutes or days | The server never trusts the device's clock: lifetimes are checked against the server's own. The client is told `expiresIn` (seconds) rather than an absolute time, refreshes a minute early, and on `session_refused` refreshes once anyway. Google tokens get five minutes of skew either way; Game Center's five-minute window is symmetric. |
| T13 | **CSRF on the web deletion page** | The page asks the server for a nonce (stored in an `HttpOnly; Secure; SameSite=Strict` cookie, double-submitted), gives it to Google Identity Services, and the server requires the ID token's `nonce` to match the cookie and to be unused. The POST must carry `Content-Type: application/json` and an `Origin` that is the server's own. |
| T14 | **Secrets in logs** | The server logs a route's first two segments only (`routeOf`), never a header or body; the client's action log does the same; tests assert both. |
| T15 | **Key compromise / rotation** | Tokens carry a key id; the server holds a keyring (`RULEBORN_TOKEN_KEYS`), signs with the first and accepts the rest, so a key is rotated without signing anyone out and retired after the refresh lifetime. The token key is derived apart from the telemetry pseudonym key, so rotating one never moves the other. |

## Design

### Tokens

**Choice:** an access token and a refresh token, the industry's OAuth shape,
without OAuth's ceremony (one first-party client).

- Access token: `a1.<kid>.<account>.<session>.<expiry>.<mac>`, HMAC-SHA256
  under key `kid`. Lives one hour — the document's "keeps its session for its
  hour". Checked on every request against the `sessions` row it names, in the
  same read as the account row the server already makes (deleted, banned), so
  sign-out is immediate and the read count grows by one primary-key row.
- Refresh token: `r1.<kid>.<session>.<generation>.<mac>`, the MAC over the
  session's random salt as well. Rotated on every use: the old generation is
  dead from then on.
- Reuse: a refresh token of an older generation, correctly signed, means two
  holders: the session (the family) is ended with reason `reused`, and every
  token of it refused.
- Lifetimes: access one hour; refresh 30 days idle, 180 days absolute.
  **Choice** (the market's usual range for a game).
- Sessions closed or lapsed are deleted seven days after (§20.5's rule) by
  `Auth.expire()` (`server/src/auth.mjs`), which the server runs on its
  daily timer beside `expireLapsed`.

### Sign-out

- `POST /v1/session/end` ends this session. `{"everywhere": true}` ends
  every session of the account; `{"others": true}` every one but this;
  `{"device": id}` one from the devices list. All answer 200 when already
  ended (idempotent), so a retried sign-out is harmless. Without a live
  access token only this session or every one can be ended, proven by the
  refresh token.
- Deletion, a ban and an identity change end every session (`Auth.endAll`).
- An access token never outlives its session's 180 days: one issued in the
  last hour lasts only to the end of them.

### Devices list (`GET /v1/session/devices`)

**Choice** (the market's: Google, Apple, Discord, Steam): each live
session with `device` (a kind from a fixed list: iPhone, iPad, Android
phone or tablet, PC, other), `model` (what the system calls it, at most 32
plain characters), `via` (`gc` or `gp`, never the identity), `place`, the
day it signed in, the hour it was last used and `idleHours` on the
server's clock; this device first. Also `identities`: which platforms sign
in to the account.

- **Place** is a country code (ISO 3166-1) from a header the edge sets
  from the address (`RULEBORN_PLACE_HEADER`, Cloudflare's `cf-ipcountry`),
  kept on the session at sign-in and refreshed with each refresh, in the
  same write. The address itself is never read for it or stored anywhere
  (the test scans the rows for the addresses it signed in from). Declared in
  `server/privacy.json` as approximate location (App Store "Coarse
  Location", Play "Approximate location"), for security, erased with the
  account, deleted seven days after the session ends. Unset header, no
  place. The phone words the code in the player's language from
  `client/i18n/countries.csv`, the CLDR's names for every ISO 3166-1
  country (`tools/auth_countries.py`, which needs Babel to write it).
- **Last used** is a refresh's `used_at`: no extra write, accurate to the
  hour, which is all the list shows.
- Nothing the device sends can name its player: the kind is from a list,
  the model is held to plain characters, and neither is required.

### One account on iPhone, iPad and Android (`POST /v1/session/link`, `/unlink`)

§24.8 names Game Center on iPhone and Google on Android, and the design
promises "One account across iPhone, iPad, Android and later PC, with
platform sign-in". iPhone and iPad share Game Center already; the move to
Android needs the account to also sign in with Google. Google's sign-in
runs on iPhone, so an iPhone can add it (`{"current": <Game Center proof>,
"credential": <Google proof>}`); afterwards the Android phone signs in to
the same account. An Android phone has no Game Center, so the way back is
the same link, made on the iPhone: the panel offers a platform only where
the device has its plugin. No account is ever merged into another.

**Recovery.** No password, so nothing to recover: a new or reset phone
signed in to the same Apple ID or Google account signs in to the same
account (the panel says so). The account follows the platform identity;
if that identity itself is lost, Apple's and Google's own recovery are the
route, and the support contact (§20.11) for anything else.

### Platform proofs (`server/src/auth_proofs.mjs`)

`stores.mjs` already checked the signatures; around it:

- Game Center: `(player, salt, timestamp)` is spent in `auth_spent` (by a
  SHA-256, so the row names nobody) until the five minutes it could be
  accepted in are over. Key fetched only from `static.gc.apple.com` /
  `sandbox.gc.apple.com`, HTTPS, no query/port/user, no redirects
  (`main.mjs`), chained to the pinned root, `O=Apple Inc.` in the subject.
- Google: the ID token's `nonce` must be a server nonce (`POST
  /v1/session/nonce`), in date, and is spent with the token. Nonces are
  MACed, not stored, so asking for one writes nothing and an address held
  back by the failure limit gets none.
- `verifyPlatform(credential, once)` is still the one seam: tests fake the
  platforms with a plain function; with no `once`, a real proof is refused,
  so single use cannot be skipped by forgetting to pass it.

### Web deletion page (`server/src/auth_http.mjs`, `server/web/delete.html`)

- Each serving draws a nonce, puts it in the page for Google Identity
  Services (`data-nonce`) and in a `__Host-rb_delete` cookie (`Secure;
  HttpOnly; SameSite=Strict; Path=/`, five minutes). The POST's ID token must
  carry exactly that nonce, once: a token minted for another page, another
  browser, or replayed, is refused.
- A POST with a foreign `Origin`, a `Sec-Fetch-Site` other than
  same-origin/none, or a body that is not JSON is refused before anything
  is read (no form can post JSON cross-site without a CORS preflight, which
  the server never grants).
- Strict CSP: `default-src 'none'`, the page's own script and style by a
  per-response nonce, Google's sign-in and nothing else; `frame-ancestors
  'none'`, `no-referrer`, `nosniff`, `no-store`.
- `no_such_account` is still a distinct answer here: only someone holding a
  valid Google token for that subject can ask, so it tells them only about
  their own account.

### Abuse limits

The document's numbers, in `limits.mjs` (unchanged): sign-ins ten at once
then one every 10 s by the identity a proof names (a refresh by its
session), failures twenty at once then one every 3 s by address (/64 for
IPv6). A limit answers `429 too_many_requests` with `Retry-After` and is the
same whether or not the account exists (`auth_http.test.mjs`). A refresh
failure counts as a failed sign-in; nonce requests are refused while an
address is held.

Every session path, and its bucket (`auth_devices.test.mjs` "every session
path is limited"):

| Path | Held by |
|---|---|
| `POST /v1/session` | the address's failures, then the identity proven |
| `POST /v1/session/nonce` | the address's failures (signed, never stored: nothing to fill) |
| `POST /v1/session/refresh` | the address's failures, then the session's sign-ins |
| `POST /v1/session/end` with a Bearer | the account's calls |
| `POST /v1/session/end` with a refresh token | the address's failures, then the session's sign-ins |
| `GET /v1/session`, `GET /v1/session/devices` | the account's calls |
| `POST /v1/session/link`, `/unlink` | the account's calls, then each proof as a sign-in: the address's failures and the identity it proves |
| `POST /v1/account/delete` (web) | the address's failures, then the identity proven |

**Back-off on the device** (`AuthSession`): a renewal the server never
decided (unreachable, a 5xx) is not tried again at once — the next
automatic one waits 2 s, then 4, 8 … at most 5 minutes, at half to all of
it (jitter, so phones that lost the server together do not return
together); the player's own tap skips that wait. A 429 waits the server's
`Retry-After`, whoever asks. A decision (refused, signed out) clears it.

### On the device (`client/features/auth/`)

- `AuthSession` holds the access token in memory (`Api.token`) and the
  refresh token in `SecureStore`: Keychain
  (`kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly`) or Android Keystore
  through the platform plugin singleton `RulebornSecureStore`
  (`read/write/erase`). **Without the plugin nothing is persisted**: the next
  launch signs in with the platform again. `FakeSecureStore` is the test
  double. **Open:** the two native plugins are not in this repository;
  their contract is in `secure_store.gd` and `platform_identity.gd`.
- Expiry is timed on `Time.get_ticks_msec()` (monotonic) from the server's
  `expiresIn`, renewed a minute early; one renewal at a time.
- `PlatformIdentity` asks `RulebornGameCenter` / `RulebornGoogleSignIn` for a
  proof (`request(nonce)` → `credential(answer)` signal), fetching the
  server's nonce first for Google. Without either, the local server's stub.
- `auth.json` on the phone holds only whether the player signed out and the
  account's opaque id; no token is in any file (`auth_tests.gd` scans them).
- HTTPS only (`Api.secure`); `HttpTransport` pins the server's chain when
  the project setting `ruleborn/tls_pins` names a PEM file (Godot's
  `TLSOptions.client(trusted_chain)`). **Owner to confirm:** pin the CA the
  production certificate chains to (pinning the leaf would break at every
  renewal); unset today, so the platform's authorities are trusted.

### Native plugins: the steps (the owner's third decision)

Each plugin is an engine singleton; the client turns it on by its presence
alone, so adding the built plugin to the export is the one switch. Until
then each has a working stand-in: memory-only storage, the local server's
stub sign-in, and `FakeSecureStore` / `FakePlatformIdentity` in tests.

| Singleton | Contract (GDScript) | iOS | Android |
|---|---|---|---|
| `RulebornSecureStore` | `read(key) -> String` ("" for none), `write(key, value) -> bool`, `erase(key)` (`secure_store.gd`) | Keychain generic password, service `com.<bundle>.session`, `kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly`, no access group | AES-256-GCM key in Android Keystore (non-exportable, `setUserAuthenticationRequired(false)`), ciphertext in app-private SharedPreferences; `allowBackup=false` for that file |
| `RulebornGameCenter` | `request(nonce)`, then the signal `credential(answer: Dictionary)`: `{playerId, bundleId, publicKeyUrl, signature, salt, timestamp}` base64 as Apple gives them, or `{"error": code}` (`platform_identity.gd`) | `GKLocalPlayer.local.authenticateHandler`, then `fetchItems(forIdentityVerificationSignature:)`; `teamPlayerID` as `playerId`; the nonce is unused (Apple's salt is the single use) | — |
| `RulebornGoogleSignIn` | as above, answering `{idToken}` | GoogleSignIn-iOS with the iOS client id and `serverClientID` = the web client id; `nonce` passed through. Only for linking (the panel's "Add your Google account") | Credential Manager, `GetGoogleIdOption` with `serverClientId` and `setNonce(nonce)`; `setFilterByAuthorizedAccounts(true)` first, `false` if none |

Error codes the plugins answer, each with words in the strings table:
`platform_cancelled` (the sheet closed), `no_platform_account` (no Game
Center or Google account on the phone).

Steps, on a machine with Xcode 16 and the Android SDK 35:

1. iOS: a Swift static library implementing the two iOS singletons through
   Godot's iOS plugin interface (`.gdip`), linked into the Xcode export;
   GameKit and the GoogleSignIn package added; the Game Center capability on
   the App ID.
2. Android: a Godot Android plugin (v2, `GodotPlugin` subclass, `.aar`) for
   `RulebornSecureStore` and `RulebornGoogleSignIn`; the dependencies
   `androidx.credentials`, `com.google.android.libraries.identity.googleid`.
3. Server: `RULEBORN_GOOGLE_CLIENT_IDS` lists the Android, iOS and web
   client ids; `RULEBORN_GAMECENTER_ROOTS` and `RULEBORN_BUNDLE_ID` set.
4. Check on each phone: sign in, kill the app, reopen — no platform sheet
   (the refresh token was kept); uninstall and reinstall — the platform
   proves it again (nothing in a backup); on iPhone add Google, then sign
   in on an Android phone with it: the same account.

### Sign-out on the device (`AuthController`)

1. Everything waiting is sent if the server answers.
2. The server ends the session (Bearer), or — the access token past its
   hour — the session the refresh token names. With no network the phone
   still forgets, and the refresh token is kept in secure storage only to
   send that sign-out, first thing, when the server next answers.
3. What still waits (§24.12's queue: a heist played offline) is **parked**
   under the account's id beside the outbox — never sent as another account
   (the server would refuse it as `lease_refused` and the queue would drop
   it), never deleted. The confirm dialog says how many, and so does the
   panel after. The same account signing in gets them back and sent.
4. The lease stock and unsent session events go; every in-memory state goes
   with the services, which `App.restart` builds anew.
5. Signed out, nothing signs in again by itself (`ensure` answers
   `signed_out`) until the player taps Sign in — on this launch or the next.

A lost phone: "Sign out everywhere" from another device ends its session,
but the phone's own Game Center or Google sign-in could still prove the
identity again, so the "sign out everywhere" confirm also tells the player
to remove a lost phone from their Apple ID or Google account.

### Interface

`client/scripts/auth_panel.gd` (kit pieces, words from `AuthPresenter`):
first launch, signing in, signed in (and on how many devices), offline,
failed with the reason in words, signed out. Sign out and Sign out
everywhere each confirm in `KitPanels.dialog` with the safe answer focused.
**Shared-file edit:** a few lines in `client/scripts/settings_screen.gd`
(T10's) add the design's Account tab and put the panel on it. The panel is
built from the same pieces as the rest of Settings (`ScreenParts.section`,
`ScreenParts.item`, `ScreenKit.button`), as the Settings still draws them:
the status card with the account's mark and its action at the end; the
signed-in devices, each a row with its own Sign out (this one marked "This
device"); Sign out every other device and Sign out everywhere; the ways to
sign in, with the other platform offered; the recovery line.

### Writes

A sign-in writes one `sessions` row, a refresh one update, a sign-out one
update. **One switch** for the owner's decision on that update:
`RULEBORN_REFRESH_ROTATE_HOURS` (default 0) rotates the refresh token on
every refresh; 24 rotates it once a day — within the day a refresh answers
a new access token and the same refresh token and writes nothing, so an
engaged player's 5 refresh rows a day become 1.33 (82.48 instead of 86.15
billed rows a day). The price: a copied refresh token is caught at the next
rotation, not the next refresh, and the devices list's "last used" and
country are as old as a day (`auth_devices.test.mjs` "rotating the refresh
token once a day"). `server/load.mjs` now models the device as it behaves — signing in
once and refreshing when its hour is up — and `server/load.json` is
rewritten: one billed row a session, engaged players 81.15 → 86.15 billed
rows a day, $767 → $817 a month at a million monthly players. **Owner to
confirm** this addition to §24.1's budget (the register is not edited here).

> **Note (T15, 28 October 2026):** these figures predate the database-cost
> work. `server/load.json` now reads 61.74 billed rows a day for an engaged
> player and $572 a month at a million
> ([`docs/server/db-cost.md`](../server/db-cost.md)); the once-a-day rotation
> has not been re-measured since.

## Checked by hand

- G39's page served by the real handler and loaded in Chromium (Playwright):
  its own script runs under its Content-Security-Policy, the nonce is in
  `data-nonce`, and the page itself raises no CSP violation. Google's script
  could not be fetched from the sandbox, so the button's own rendering was
  not seen here (T12 checked it in Chromium against the same sources).
- `main.mjs` started with `RULEBORN_TOKEN_KEYS="k7:…,k6:…"` signs tokens
  `a1.k7.…`; a key shorter than 32 characters stops it at start.

## Stopped here

At 23:00 UTC on 27 October 2026 (wave 5), on `claude/auth`.

**Built this wave and proven** (server `auth_devices.test.mjs`, 10 tests;
client `auth_tests.gd`, 18 checks with the round trip against the server):

- The devices list: kind, model, platform, country in words, last used;
  sign out one device, every other, or everywhere; an access token never
  outlives its session's 180 days.
- One account on iPhone, iPad and Android: link the other platform with
  two fresh proofs (step-up), unlink with a proof of the one that stays,
  no merging, a ban covering both, deletion erasing the link; recovery is
  the platform identity itself, and the panel says so.
- Limits on every session path, tabled above; the device's renewal
  backs off (2 s doubling to 5 minutes, jittered; a 429's Retry-After).
- The panel on Settings' Account tab in T10's Settings pieces, devices and
  ways to sign in each grouped in one card as the Settings still draws its
  rows; held by a test to the phone frame and 48-point controls in every
  language; stills in `docs/art/shots/auth/` (signed_in, linkable,
  confirm, device, signed_out, failed).
- The country in the player's language (`client/i18n/countries.csv`).
- Refresh's billed row is one switch (`RULEBORN_REFRESH_ROTATE_HOURS`).

**Open:**

- The native plugins (steps above): no Android SDK or Xcode here.
- No certificate is pinned until the production chain is known
  (`ruleborn/tls_pins`, one setting).

**For the owner to confirm:**

- Refresh's billed row: keep rotation on every refresh (86.15 rows a day
  for an engaged player) or set `RULEBORN_REFRESH_ROTATE_HOURS=24`
  (82.48, from `server/load.mjs` run with it).
- Which CA the client pins.
- The native Keychain/Keystore and sign-in plugins.
- Noted, not asked: the devices list's country is declared to both stores
  as approximate location (`server/privacy.json`); unset
  `RULEBORN_PLACE_HEADER` and no place is kept.
- Shared-file edits: the Account tab in `client/scripts/settings_screen.gd`
  (T10's), one line in `server/test/privacy.test.mjs`, the `sessions`
  columns and `linked_identities` in `server/src/db.mjs`, the place header
  in `server/src/main.mjs`, and Apple's "Coarse Location" in
  `tools/privacy_manifest.py` (the iOS privacy manifest written from it),
  `countries.csv` in `client/scripts/strings.gd`'s catalogue list, and
  `tools/auth_countries.py`'s line in `README.md`.
