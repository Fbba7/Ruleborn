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
| T6 | **Brute force** — guessing tokens, hammering sign-in | 128-bit session ids, 256-bit MACs. The document's limits per account (sign-ins) and per address (failures only). Refresh is held to the same account bucket as sign-in. |
| T7 | **Enumeration** — learning whether an identity has an account | A refused credential, a revoked session, an expired session and a forged token all answer the same `session_refused` / `platform_identity_refused`, and the same status. A limit answers 429 whether or not the account exists, and an address is held back on failures before any account is read. Sign-in makes an account for a new identity, so "exists" is never a different answer. |
| T8 | **Downgrade** — an old token format, `alg: none`, HTTP, a stubbed verifier in production | Only the current token version is read. JWT `alg` is pinned to RS256. The server refuses to start with real stores and stubbed sign-in (`main.mjs`). The client refuses a server reached in the clear. |
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
- Sessions closed or lapsed are deleted seven days after (§20.5's rule) by the
  daily `expireLapsed` job.

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
  place. The phone words the code with the engine's country names.
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
update. `server/load.mjs` now models the device as it behaves — signing in
once and refreshing when its hour is up — and `server/load.json` is
rewritten: one billed row a session, engaged players 81.15 → 86.15 billed
rows a day, $767 → $817 a month at a million monthly players. **Owner to
confirm** this addition to §24.1's budget (the register is not edited here).

## Checked by hand

- G39's page served by the real handler and loaded in Chromium (Playwright):
  its own script runs under its Content-Security-Policy, the nonce is in
  `data-nonce`, and the page itself raises no CSP violation. Google's script
  could not be fetched from the sandbox, so the button's own rendering was
  not seen here (T12 checked it in Chromium against the same sources).
- `main.mjs` started with `RULEBORN_TOKEN_KEYS="k7:…,k6:…"` signs tokens
  `a1.k7.…`; a key shorter than 32 characters stops it at start.

## Stopped here

At 04:45 UTC on 27 October 2026, on `claude/auth`.

**Built and proven** (check_all green; server 443 tests, client 13 auth checks):

- Sessions: an hour's access token, a rotating refresh token with reuse
  detection (a reused one ends its family), 30-day idle and 180-day
  absolute limits, key ids and a key ring for rotation, every MAC compared
  in constant time, one primary-key row read a request for revocation.
- Sign-out, sign-out everywhere, and every session ended by deletion, a
  ban and an identity change; closed sessions deleted after seven days.
- Platform proofs single-use: a Game Center salt and timestamp once, a
  Google token's server nonce once; every rejection path tested with the
  real verifiers. A proven Game Center key cannot be evicted by a caller
  cycling Apple's key names (T12's SR-20).
- The web deletion page: a nonce bound to a `__Host-` cookie, the web
  client's token only, issued within five minutes, once; cross-site and
  non-JSON posts refused; a strict CSP checked in Chromium (T12's SR-11).
- Limits: the document's sign-in numbers, refresh and nonce included, with
  the same answer whether or not an account exists.
- The device: the access token in memory, the refresh token behind the
  platform storage seam (memory only without a plugin), renewal on the
  monotonic clock, one at a time, the nonce fetched for Google; a sign-out
  that ends the session on the server or owes it, forgets every token,
  parks the unsent queue under the account and rebuilds the app's state;
  TLS pinning by project setting; no token in any log or file.
- The account panel, from the UI kit, every state in words, both sign-outs
  behind a confirm; stills in `docs/art/shots/auth/`.

**Open:**

- The native plugins: `RulebornSecureStore` (Keychain, Keystore),
  `RulebornGameCenter`, `RulebornGoogleSignIn`. Their contracts are in
  `client/features/auth/secure_store.gd` and `platform_identity.gd`; this
  machine has no Android SDK or Xcode to build them.
- No certificate is pinned until the production chain is known.
- The register is not told of `server/load.json`'s new numbers.

**For the owner to confirm:**

- One billed row a session for refresh: engaged players 81.15 → 86.15
  billed rows a day; $767 → $817 a month at a million monthly players.
- Lifetimes: access one hour (the document's), refresh 30 days idle and
  180 days absolute.
- Which CA the client pins.
- A sign-out keeps the age check and the first launch's answers on the
  phone (device-level), while the queue is parked by account.
- The account panel sits at the end of Settings (two lines in
  `settings_screen.gd`) until Settings has an Account tab.
