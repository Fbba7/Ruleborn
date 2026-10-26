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
| T11 | **Account takeover through a platform switch** — a second identity attached to someone else's account | An account has exactly one platform identity; there is no linking route. Any future change of identity must go through `Auth.identityChanged`, which ends every session of that account. A proof only ever names `gc:` or `gp:` identities from its own verifier; a Google token cannot sign into a `gc:` account, and the web deletion page takes only `gp:`. |
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

- `POST /v1/session/end` ends this session. `POST /v1/session/end {"everywhere": true}`
  ends every session of the account. Both answer 200 when already ended
  (idempotent), so a retried sign-out is harmless.
- Deletion, a ban and an identity change end every session (`Auth.endAll`).

### Writes

A sign-in writes one `sessions` row, a refresh one update, a sign-out one
update. `server/load.json` is rewritten with them. **Owner to confirm:** this
adds about one row a session to §24.1's write budget.

## Stopped here

(Written at the end of the night.)
