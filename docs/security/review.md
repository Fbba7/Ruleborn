# Security review

A review of the whole app — server, simulation, client and supply chain — for
security issues, each one proven by a test that fails before its fix. Branch
`claude/security-review`.

Severity is by realistic impact on players and the operator: **Critical**
(any account or the economy taken over remotely), **High** (another player's
data or money, or a children's protection broken, by any player), **Medium**
(an exploit that needs effort or has bounded harm), **Low** (defence in depth,
or harm only to the caller).

Status is one of **fixed** (with its commit), **sent to T11** (sign-in and
session code, which the auth branch owns: the failing test is here, the fix is
theirs), or **needs the owner** (a fix would change a game rule or a design
decision).

## Findings

| Id | Severity | Area | Title | Status |
| --- | --- | --- | --- | --- |
| SR-01 | High | server | Any player could loosen their own age band | fixed |
| SR-02 | Medium | server | A heist's crew manifest was unchecked when the crew went unnamed | fixed |
| SR-03 | Medium | server | Every offer and Observatory view read the whole game's islands | fixed |
| SR-07 | Medium | server, sim | One trap in the simulation stopped its rules version until a restart | fixed |
| SR-17 | Medium | server | The hold queue stalled the server and could be filled by one player | fixed |
| SR-19 | Medium | server | A player could write the store full, half a second at a time | fixed |
| SR-04 | Low | server web | The web pages had no CSP, nosniff or referrer policy | fixed |
| SR-05 | Low | server | A block did not hide a player's profile | fixed |
| SR-06 | Low | client | The cleartext guard let a userinfo hide the host; the terms link could leave the server | fixed |
| SR-08 | Low | client, sim | A crafted replay could abort or freeze the app | fixed |
| SR-13 | Low | server | "constructor" and its like were taken as law ids | fixed |
| SR-18 | Low | server | A 13-to-15 could play any Workshop island by its id | fixed |
| SR-12 | Medium | server | The Island Fund pays one player's replays as if each were a new player | needs the owner |
| SR-15 | Medium | server | An island's exposed loot is the bundle's word (register D60) | needs the owner |
| SR-16 | Medium | server | An island's laws and guards are the bundle's word (register G60, G61) | needs the owner |
| SR-09 | Low | server | The public target lists carry every island's raw rating | needs the owner |
| SR-10 | Low | server | A minor's monthly cap holds only on the client's word | needs the owner |
| SR-14 | Low | server | A crew is anyone's who holds its invite, a 13-to-15's too | needs the owner |
| SR-11 | Low | server | The ID token that signs in also deletes the account, at once | fixed by T11 |
| SR-20 | Low | server | A caller can keep Game Center sign-in failing | fixed by T11 |
| SR-21 | Medium | server | The web deletion page refused every browser once deployed | fixed |
| SR-22 | Low | server | A player's own answers carried no word against caching | fixed |
| SR-23 | Low | server | The database was readable by every user on the machine | fixed |
| SR-24 | Low | server | A dead token could still sign a player out everywhere | fixed |
| SR-25 | Medium | server | One captured Game Center proof signed in again with its salt respelled | fixed |
| SR-26 | Low | build | Godot and its export templates were run and shipped unchecked | fixed |
| SR-27 | Low | client | A redirect carried the session token to another host, in the clear | fixed |
| SR-28 | Medium | server | Made-up refresh tokens could keep every player's session from renewing | fixed |
| SR-29 | Low | server | A server deployed without its platforms' settings let anyone in as anyone | fixed |

### SR-01 — Any player could loosen their own age band (High)

- **Where:** `server/src/workshop.mjs` `setAgeBand`, reached by `PUT /v1/age`
  (`server/src/http.mjs`).
- **What:** the route wrote whatever band it was sent, every time. §20.1:
  *"After the first answer the band can only tighten from the device … the
  server refuses any other loosening."* A 13-to-15 could send
  `{"band": "18+"}` and shed every protection §20.2 and §20.7 give the band:
  the €25 monthly cap, the quiet night, curated Workshop lists only, the
  private profile, challenge links to friends only, and the friends' feed.
- **Reproduce:** sign in, `PUT /v1/age {"band": "13-15"}`, then
  `PUT /v1/age {"band": "18+"}` — answered 200 and the account was an adult.
- **Test:** `server/test/security_age.test.mjs`.
- **Fix:** the account keeps when its age check first answered
  (`accounts.age_answered_at`, declared in `server/privacy.json`). The first
  answer sets any band; after it a looser band is refused with 403
  `age_band_only_tightens` and the band held. The platforms' age services,
  which §20.1 lets loosen a band, are not built; when they are, they set the
  band on the server's side, not through this route. An account made before
  this column has one answer left, which is the device's first one if it
  never sent it.
- **Status:** fixed.

### SR-02 — A heist's crew manifest was unchecked when the crew went unnamed (Medium)

- **Where:** `server/src/service.mjs` `submit`; `POST /v1/heists/:token`.
- **What:** an `RBH3` replay carries §12.5's crew manifest, and the
  simulation plays each member by the kind it names (role, size, speed,
  ability). §12.5: the manifest is one *"which the server checks against the
  roster it holds"*. The check (`home.crewProblem`) ran only when the request
  named the crew with `?crew=`; leave the query out and any three kinds were
  played, kinds the raider never hatched, and no character rested afterwards
  (§11.6), so the same crew could raid without pause.
- **Reproduce:** lease, record a replay whose manifest names kinds the raider
  does not hold, and `POST /v1/heists/:token` with no `?crew=`: validated and
  paid.
- **Test:** `server/test/security_heists.test.mjs`; `server/test/crew.test.mjs`
  now names its roster crew, as the device does.
- **Fix:** a replay carrying a manifest with no crew named is refused,
  `crew_not_named`, and pays nothing. A replay without a manifest (`RBH1`,
  `RBH2`) still plays §11.1's crew by role, as before. The client's planner
  always sends the two together (`planner_presenter.gd`), so it is unchanged.
- **Status:** fixed.

### SR-03 — Every offer and Observatory view read the whole game's islands (Medium)

- **Where:** `server/src/matchmaking.mjs` `candidates`, called by
  `GET /v1/offer` (`http.mjs`) and `GET /v1/observatory` and its refresh
  (`observatory.mjs`).
- **What:** each call made §12.22's candidates afresh: every current island
  and every echo, each with its rating and its owner's Renown read — two
  statements a candidate. §24.8 has choosing a target cost *"a cached
  download rather than a database search"*; these routes are the search,
  per caller. Measured here, 1,000 islands cost about 150 ms of the process
  a call, linear in islands. G44's bucket lets one account make 60 such calls
  at once and two a second after, so a handful of accounts holds a server
  that serves everyone else from one thread.
- **Reproduce:** publish many islands, then call `GET /v1/offer`
  repeatedly from one account and time it (or count statements, as the test
  does).
- **Test:** `server/test/security_limits.test.mjs`.
- **Fix:** one making of the candidates serves every caller for
  `CANDIDATES_MS` (a minute), and is made again at once when an island is
  published, replaced or taken away, or an account is banned or deleted
  (four aggregate reads tell). What moves in between — a rating, Renown, a
  new player's shield running out — only orders the list, and the lease
  checks the target again (`service.lease`). At 1,000 islands a repeated
  call now costs about 10 ms.
- **Left:** `Matchmaking.chapters` keeps a chapter for every bundle ever
  offered, for the process's life: small, but it grows with the game.
- **Status:** fixed.

### SR-04 — The web pages had no CSP, nosniff or referrer policy (Low)

- **Where:** `server/src/http.mjs` (`/terms`, `/privacy`, `/support`,
  G39's `/account/delete`), `server/src/pages.mjs`.
- **What:** the pages the stores link to went out with only a content type
  and a cache header; the deletion page added `x-frame-options` only. None
  carried a Content-Security-Policy, so an injection anywhere in a page
  (the privacy page is written from `privacy.json`, the support page from
  the operator's setting) would run, and no answer said `nosniff`. Nothing
  injectable was found (the pages escape what they interpolate): this is the
  defence behind that.
- **Test:** `server/test/security_web.test.mjs` (SR-04).
- **Fix:** every page is served `default-src 'none'`, its one inline style by
  its hash, `frame-ancestors 'none'`, `base-uri` and `form-action 'none'`,
  `nosniff` and `no-referrer`. The deletion page's own script is allowed by
  its hash and Google Identity Services by Google's published sources;
  Google's script sets inline styles and draws its logo from a `data:`
  image, so that page's styles take `'unsafe-inline'` (scripts never do).
  Checked in Chromium: every page renders, the sign-in button loads, and no
  CSP violation is reported. Every answer, JSON and bytes too, now carries
  `x-content-type-options: nosniff`. The deletion page's client id is put in
  with a replacer function, so a `$` in it is never read as a pattern.
- **Status:** fixed.

### SR-05 — A block did not hide a player's profile (Low)

- **Where:** `server/src/profile.mjs` `show`, `GET /v1/profile/:account`.
- **What:** §17.8: a blocked person *"disappear[s] from … anything with
  their name on it, and you disappear from theirs."* Every other route holds
  this (the Workshop, the feed, constellations, crews, challenge links); a
  blocked player could still read the blocker's open profile, and the
  blocker theirs.
- **Test:** `server/test/security_web.test.mjs` (SR-05).
- **Fix:** across a block either way the profile is answered 404
  `no_such_account`, as a deleted one is, so the block is not told.
- **Status:** fixed.

### SR-06 — The cleartext guard let a userinfo hide the host; the terms link could leave the server (Low)

- **Where:** `client/data/api.gd` `Api.secure`;
  `client/features/workshop/workshop_presenter.gd` `terms`.
- **What:** `secure()` let plain HTTP through when the host was the
  loopback, read as everything before the first `:` — so
  `http://localhost:1@edge.example/` passed, and a session token would go in
  the clear to `edge.example`. The URL comes only from `RULEBORN_SERVER` or
  the project setting, so it takes a misconfiguration, not an attacker. And
  the Workshop's terms link opened `api.base + url`, with `url` as the
  server's answer gave it: `@other.host/…` or `.other.host/` opens another
  site in the browser.
- **Test:** `client/tests/core_tests.gd` and `client/tests/workshop_tests.gd`
  (the checks named SR-06).
- **Fix:** plain HTTP is allowed only when the whole authority is
  `127.0.0.1` or `localhost` with at most a port, and the URL has no `@` or
  backslash anywhere. The terms link is used only if it is a path
  (`^/[a-z/]+$`), else `/terms`. `secure()` is the transport's guard, not
  sign-in code; the screen itself is untouched.
- **Status:** fixed.

### SR-07 — One trap in the simulation stopped its rules version until a restart (Medium)

- **Where:** `server/src/sim.mjs` `Build`; the cause is `sim/src/ffi.rs`
  `with_buffer`, whose `Mutex` a trap never unlocks.
- **What:** the simulation is built with `panic = "abort"`, so a panic in
  WebAssembly is a trap, and the trap leaves the instance's memory as it
  stopped: the buffer's lock held. Every later call on that instance traps
  too, so one input reaching any panic would stop every heist, Workshop
  play and publish on that rules version until the process restarts. A
  replay chooses its rules version and the server keeps every old build
  (§24.11), so a panic in any old build would stay reachable for good. A
  fuzzing pass (20,000 island mutations, 6,300 random command logs, 600
  universe crossings, mutated replays, stability and curation inputs, all
  with overflow checks on) found no trap the server's routes can reach;
  `recordDrawn` with a crew of none (`rng.below(0)`), a call only the tests
  make, shows it.
- **Test:** `server/test/security_sim.test.mjs`.
- **Fix:** every `Build` method that traps makes its instance again, fresh,
  before the error goes on: the one request fails (answered 500, its lease
  still submittable) and the next is served. The simulation itself is
  unchanged, so the rules version and the goldens are too.
- **Status:** fixed.

### SR-08 — A crafted replay could abort or freeze the app (Low)

- **Where:** `client/ext/src/lib.rs` `RulebornReplay.load`; the panic is in
  `sim/src/lib.rs` `World::outcome` (`1 << i` into a `u8` mask).
- **What:** `load` checked a replay decodes and names its island, but not
  its crew or clock. A crew of nine or more whose ninth member gets out
  overflows the out mask, and the extension is built to abort, so the app
  closes; a clock of 2³² ticks makes the replay and result screens step
  for ever. The server keeps every replay it is sent before checking it,
  and serves a heist's replay to its raider and defender, so a raider could
  hand a defender such a file. The defence log lists validated heists only,
  so no screen reaches one today: Low. The server's own `verified` already
  refuses a crew outside 3 to 5 and a clock outside §24.10's.
- **Test:** the fuzz case that found it (seed 13, a crew of 15) is in the
  review's scratch work, not the repository, since a client test would need
  a recorder for crews the simulation refuses; the client suite's replay
  checks run on the fixed `load`, and the server half has its own test.
- **Fix:** `load` refuses a replay whose crew or clock `verified` would
  refuse. The simulation's mask is unchanged, since changing the simulation
  changes its rules version. And the server no longer hands a defender the
  bytes of a submission it refused (`service.replay`): a defender watches
  the raids that were played; the raider keeps their own
  (`server/test/security_heists.test.mjs`, SR-08).
- **Status:** fixed.

### SR-13 — "constructor" and its like were taken as law ids (Low)

- **Where:** `server/src/codex.mjs` (`workOn`, `restore`, `tier`, `study`,
  `add`), `server/src/lab.mjs` `start`.
- **What:** a law was known by `BY_ID[law]` / `LAWS[l]`, plain objects that
  answer for `constructor`, `toString`, `__proto__` and the rest. Such a
  name passed as a law: `POST /v1/codex/working {"law": "constructor"}` was
  stored and later heists booked pages to a Codex row of that name, and a
  restore or tier of one threw inside the server — a 500 instead of a
  refusal. Only the caller's own account is touched; weaving, shop and the
  other modules already use `Object.hasOwn`.
- **Test:** `server/test/security_heists.test.mjs` (SR-13).
- **Fix:** a law is a law only as its own key (`Object.hasOwn`), so each of
  these names is refused 400 `no_such_law` or `malformed_body`.
- **Status:** fixed.

### SR-17 — The hold queue stalled the server and could be filled by one player (Medium)

- **Where:** `server/src/holds.mjs` `work`, scheduled by `server/src/main.mjs`.
- **What:** every island published queues §13.3's 800 raids of the
  reference crew, and the server worked the oldest measurement forty raids
  at a time, every five seconds. Measured here, forty raids are 1.3 to 1.9
  seconds of the one thread: while anything is queued, every request waits
  up to two seconds, a quarter to a third of the time. And the queue drains
  one island every 100 seconds, while one account publishing a new island
  each 20 seconds (its simulation bucket) adds five: oldest-first, every
  other player's island waited behind all of them, its hold *"measuring…"*
  and its rating the prior, for as long as the account kept on.
- **Test:** `server/test/security_limits.test.mjs` (SR-17).
- **Fix:** only a bundle some player's island now is gets measured (a
  superseded one waits, and is measured if published again), and owners
  take turns, each owner's oldest first, so one player has at most their
  seven realms in the queue and goes no further ahead than anyone else.
  The next measurement is chosen once, when the last one lands, and the
  index `islands_by_bundle` keeps that and the lease's holder lookup off a
  full scan. `main.mjs` plays two raids every quarter second: the same
  eight raids a second, a tenth of a second at a time. Three things are
  unchanged: the 800 raids, the cost of a measurement, and the result
  (`holds.test.mjs`: in parts as in one call). The measurement still costs
  about a third of one core while anything is queued; moving it off the
  request thread (a worker) is the deployment's next step.
- **Status:** fixed.

### SR-18 — A 13-to-15 could play any Workshop island by its id (Low)

- **Where:** `server/src/workshop.mjs` `play` and `remix`.
- **What:** §20.7 gives 13 to 15 *"Curated lists only"* for browsing the
  Workshop. `browse` held it, but `play` and `remix` took any listed item's
  id, and ids reach a player from more than the lists: a featured remix
  names its original (`remixOf`), which nobody curated.
- **Test:** `server/test/security_age.test.mjs` (SR-18).
- **Fix:** a 13-to-15 plays and remixes only an island a person featured, or
  their own, else 403 `curated_lists_only` (the code `browse` already
  answers, with its words on the client). Reporting is never held back.
- **Status:** fixed.

### SR-19 — A player could write the store full, half a second at a time (Medium)

- **Where:** `server/src/telemetry.mjs` `batch` (`POST /v1/events`),
  `server/src/friends.mjs` `invite` and `challenge`
  (`POST /v1/friends/invites`, `POST /v1/challenges`),
  `server/src/workshop.mjs` `play`, `server/src/shop.mjs` `intent`.
- **What:** G44's call bucket, two a second, was the only bound on what one
  account writes. A batch of device events holds up to 100, and only three
  kinds (sessions and the "worth" rating) had a daily count: `weave` and
  `birth` events had none. Measured here, sixty batches stored 870 kB, so
  two a second all day is about 2.5 GB a day from one account, kept §24.3's
  90 days, on a database §24.1 budgets by the row. An invite and a challenge
  link were each a row a call too, kept a week.
- **Test:** `server/test/security_limits.test.mjs` (SR-19).
- **Fix:** a player's device sends at most `DEVICE_EVENTS_A_DAY` events a
  day, every kind together — 400, twice the heavy day the module's own
  comment fits in one or two rows — and past it a batch is refused 429
  `too_many_events`. A player holds at most 50 open invites and 50 open
  challenge links (`MOST_OPEN`), as `safety.mjs` holds blocks to 500;
  past them 409, and a used or lapsed one frees its place. The same holds
  for the two other rows a call writes without a bound: a Workshop play
  (`POST /v1/workshop/:id/play`, kept for good) — at most
  `MOST_OPEN_PLAYS`, 50, unsubmitted from the last day — and a purchase
  intent, which only a minor's cap bounded — at most `MOST_OPEN_INTENTS`,
  10, open at once. The client has the words for all five refusals. No
  honest player reaches any of them.
- **Status:** fixed.

### SR-21 — The web deletion page refused every browser once deployed (Medium)

- **Where:** `server/src/auth_http.mjs` `deleteByGoogle`, behind the listener
  in `server/src/main.mjs`.
- **What:** the CSRF check compared the browser's `Origin` with the request
  URL's origin. `main.mjs` rebuilds every URL as `http://localhost` plus the
  path, so the URL's origin is never the page's: every real browser (which
  sends `Origin` on every POST) was refused `403 cross_site`. §20.5's
  deletion "from a web page", which Google Play requires of an app with
  accounts, never worked once deployed. The tests built their requests on
  `https://edge.example`, where the two agree, so none saw it.
- **Fix:** the check compares the `Origin`'s host with the `Host` header
  the proxy passed on (falling back to the URL's host where there is none).
  A foreign site still cannot pass: the victim's browser sends the real
  `Host` and the foreign `Origin`. The scheme is not compared: the server
  is HTTPS-only behind its proxy (HSTS). 4 lines in T11's file; T11 told
  here.
- **Test:** `server/test/security_config.test.mjs` (SR-21), with requests
  made as `main.mjs` makes them; it failed before the fix.

### SR-22 — A player's own answers carried no word against caching (Low)

- **Where:** `server/src/http.mjs` `handler`.
- **What:** only the session routes answered `Cache-Control: no-store`.
  Every other answer — a balance, a friends list, a profile — went out with
  no caching word, so any cache between phone and server (a corporate
  proxy, an edge rule that caches everything) was free to keep and serve
  it. OWASP's ASVS (V8.2.1) asks for anti-caching headers on sensitive
  data.
- **Fix:** an answer that says nothing of caching says `no-store`; bundles,
  target lists and pages keep their own rules. 2 lines.
- **Test:** `server/test/security_config.test.mjs` (SR-22); it failed
  before the fix.

### SR-23 — The database was readable by every user on the machine (Low)

- **Where:** `server/src/main.mjs`, where the data directory is made.
- **What:** the directory was made `0755` and SQLite made the database
  `0644`, so any account on the host — a co-tenant, a compromised
  service — could copy it: every player's platform identity, push token
  and age band. (The secret beside it was already `0600`, and refresh
  tokens are stored as salts, so a copy mints no session.)
- **Fix:** the directory is made, and kept, `0700`, as PostgreSQL insists
  of its own. 3 lines.
- **Test:** `server/test/security_config.test.mjs` (SR-21 and SR-23, as
  deployed): starts `main.mjs` on a free port, posts to the deletion route
  through `node:http` as a proxy would (SR-21 end to end), and reads the
  directory's mode. It failed before the fix.

### SR-29 — A server deployed without its platforms' settings let anyone in as anyone (Low)

- **Where:** `server/src/main.mjs`, `server/src/stores.mjs` `signIn`.
- **What:** with neither `RULEBORN_GAMECENTER_ROOTS` nor
  `RULEBORN_GOOGLE_CLIENT_IDS` set, sign-in is stubbed: a credential is
  taken as the identity it names (`"gc:anyone"`). That is the local
  server's, and the README says it "must not face a network", but the
  server started so in silence unless a store was configured too. A
  deployment with those two settings forgotten — a beta, a staging box, a
  restore from a bare environment — made accounts for whoever asked and
  signed anyone in as any identity they could name. Low: platform ids are
  not public, so taking a given player needs their id. The market standard
  is to fail closed.
- **Fix:** stubbed sign-in starts only with `RULEBORN_STUB_SIGNIN=1`, the
  flag the server already used for a test deployment with stores.
  `client/status.py` (the one harness that starts `main.mjs`) and the
  README's two local commands set it. **For the integrator:** a deployment
  meant to run stubbed must now set `RULEBORN_STUB_SIGNIN=1`. 8 lines in
  all.
- **Test:** `server/test/security_config.test.mjs` (SR-29): without the
  flag or a platform, `main.mjs` exits with its reason; with the flag it
  starts. It failed before the fix.

### SR-24 — A dead token could still sign a player out everywhere (Low)

- **Where:** `server/src/auth.mjs` `signOut` and `signOutWith` (T11's,
  this wave), behind `POST /v1/session/end {"everywhere": true}`.
- **What:** with an access token, "everywhere" checked only its signature
  and expiry, not its session; with a refresh token, only that the server
  had signed it once, not its generation or whether its session lived. So a
  copied access token whose session the player had since ended, or a
  refresh token rotated away long ago, signed the player out of every
  device — again each time they signed back in, for the old session's 180
  days and the seven its row is kept after. These are the tokens that
  sign-out and rotation are meant to make worthless (auth.md's T2, T9). The
  harm is a sign-out, which the platform undoes silently, so Low.
- **Fix:** "everywhere" by access token takes a live session (the same check
  every other route makes); by refresh token, the session's current
  generation while it lives. Ending one's own session stays idempotent.
  7 lines in T11's file; T11 told here. T11's wave-5 "every other device"
  and "end this device from the list" took the same dead token; the merge
  here holds them to the same check.
- **Test:** `server/test/security_auth.test.mjs` (SR-24); it failed before
  the fix.
- **For T11, not a finding:** `docs/security/auth.md` (T6) says session ids
  are 128-bit; they are SQLite row ids, sequential. Tokens are MACed, so a
  guessed id gains nothing, but each player's id tells them roughly how many
  sign-ins the game has had, and made SR-28 cheap to aim. A random 128-bit
  id, as the doc says, or the doc saying what is built.

### SR-28 — Made-up refresh tokens could keep every player's session from renewing (Medium)

- **Where:** `server/src/auth_http.mjs`, `POST /v1/session/refresh`, and
  `server/src/auth.mjs` `refresh` (T11's).
- **What:** a refresh is held to §24.1's sign-in bucket of the session its
  token names — ten at once, then one every ten seconds — and the bucket was
  spent before the token was checked. Session ids are sequential, so any
  caller could send made-up tokens (`r1.k0.<id>.0.<anything>`) naming each
  live session in turn, about one a session every ten seconds, and every
  player's real refresh was answered `429`. The device keeps its token and
  waits on a `429` (`AuthSession._renew`) rather than proving itself
  again, so its access token runs out and the player is off the server for
  as long as it lasts. Without `RULEBORN_PEER_HEADER`, the default, no
  address limit slows the sender; with it, a block of IPv6 /64s does. A
  thousand players' sessions cost about 100 requests a second.
- **Fix:** the token is admitted to its session's bucket only once its
  signature against the session's salt is proven: a made-up one costs one
  read by primary key and spends nothing of the player's. A proven session
  is still limited as before. 4 lines in T11's files; T11 told here. T11's
  wave-5 sign-out by refresh token spent the bucket the same way; the merge
  here admits it after the proof too.
- **Test:** `server/test/security_auth.test.mjs` (SR-28): thirty made-up
  tokens naming a player's session, then the player's refresh succeeds,
  and a proven holder is still held at the bucket's tenth. It failed before
  the fix.

### SR-25 — One captured Game Center proof signed in again with its salt respelled (Medium)

- **Where:** `server/src/auth_proofs.mjs` `verify` (T11's), over
  `GameCenter.verify` in `server/src/stores.mjs`.
- **What:** a Game Center proof is made single-use by spending its player,
  salt and timestamp. The salt was spent as the string sent, but Apple's
  signature covers its decoded bytes, and Node's base64 decoder ignores
  padding, whitespace and characters outside the alphabet: `AAEC`,
  `AAEC=`, `AA EC` and `AAEC!` are one salt. So one captured proof — from a
  proxy the player trusts, a log, a crash report — signed in as that player
  again and again for its five minutes, each time with a session of its
  own. That is account takeover from one capture, the replay auth.md's T3
  says is stopped. Medium: it needs the capture.
- **Fix:** the salt is spent by its bytes, re-encoded canonically. 1 line in
  T11's file; T11 told here.
- **Test:** `server/test/security_auth.test.mjs` (SR-25), with the real
  Game Center check and its fixture chain; it failed before the fix.

### SR-26 — Godot and its export templates were run and shipped unchecked (Low)

- **Where:** `client/build.sh` (the editor every check runs) and
  `client/export.sh` (the export templates, which become the app players
  install).
- **What:** both were fetched from GitHub's release page and unpacked with
  no check of what arrived. A swapped release asset, or a proxy the build
  machine trusts, would run its own code on the developer's machine and
  ship it inside the app. Before the fix the test's tampered "Godot" was
  unpacked and run by the build. Low: it needs GitHub or the machine's
  trust store compromised first; but SLSA and every store's guidance pin
  what a build downloads.
- **Fix:** each download is held to Godot's own `SHA512-SUMS.txt` for
  4.7.2-stable before it is unpacked, checked with `python3` (which both
  scripts already need, and which, unlike `sha512sum`, is on the Mac that
  builds for iPhone). The editor's sum matched a fresh download and the
  binary these checks run. 5 lines each; no track owns the scripts this
  wave. A Godot upgrade changes the version and both sums together.
- **Test:** `server/test/security_supply.test.mjs` (SR-26): `build.sh` with
  a `curl` that serves other bytes stops, unpacks nothing and leaves no
  download; the templates' pin is checked to come before their unpacking.
  It failed before the fix.

### SR-27 — A redirect carried the session token to another host, in the clear (Low)

- **Where:** `client/data/http_transport.gd` `send`, every call the client
  makes.
- **What:** Godot's `HTTPRequest` follows up to eight redirects by default
  and sends every header again to wherever one points. Measured with the
  4.7.2 engine headless: a request to `127.0.0.1:18901` carrying
  `Authorization: Bearer SECRET` was answered `302` to
  `http://localhost:18902/landed`, and the second host received
  `Authorization: Bearer SECRET`. The client's cleartext guard (SR-06)
  checks only the base URL. So any redirect in front of the server — a
  proxy or edge rule, a moved domain, a captive portal on a phone that
  trusts it — hands the session token on, over plain HTTP too. Low: the
  server itself never redirects.
- **Fix:** `request.max_redirects = 0`. Measured again: Godot answers
  `RESULT_REDIRECT_LIMIT_REACHED` (12) with the `302`, nothing reaches the
  second host, and the transport reports the call as unreachable, as for
  any network failure. 1 line.
- **Test:** `server/test/security_client.test.mjs` (SR-27) holds the
  transport to the setting, made before every request is sent, and checks
  no other client script makes a request of its own. The engine's
  behaviour was measured outside the suite, since the server's tests do not
  run Godot. It failed before the fix.

## Wave 5's diffs

Each track's branch, read as it was pushed, from d2343591.

| Branch | Commits read | What it touches | Verdict |
| --- | --- | --- | --- |
| second pushes, to 19:47 | `3d-characters-2` `cf97c52`, `3d-screens-world` `bc595b1`, `3d-universe` `04c5785`, `auth` `0841c20`, `ui-kit` `af7911c` | busts, the realm screens and their stages, the universe's badge, pins and purse, the account panel's layout, kit cards and layout | no finding: layout and drawing; no network, file, link, loaded data or native code; `auth` touched only `auth_panel.gd` |
| `claude/ui-screens` | 20 commits, `1573493` to `45a4a1e` | the age screen's line-up, the share card, settings and the account panel's layout, the Shop, Codex, Lab, Harmony, Weaving, Workshop and track screens | no finding: layout and words; environment read only by `tests/shots`. Not security, for the screens' owner: the share card now shows the challenge code upper-cased (`share_presenter.gd`), while codes are lower-case hex matched exactly (`friends.mjs` `opened`); the copied message keeps the real code, but when a screen takes a typed code it must lower-case it, or the server should |
| `claude/3d-screens` | `09d494c`, `ee298de`, `aba6273`, `c5ed1c1` | the heist screen and its hand, the HUD, the result; three new native accessors in `client/ext/src/lib.rs` (a member's kind and uses, the Sage, the casts) | no finding. The accessors read a replay's world, which a crafted replay shapes (SR-08), so each index was traced: the Sage is set only through `SAGES.get` (`crew_from`), every Sage has exactly three powers (`[(Power, u8); 3]`, as `uses: [u8; 3]`), casts are at most `MAX_CASTS` = 2 and checked against the law table when the manifest is read, and the new code looks them up with `get`. Environment read only by `tests/shots` |
| `claude/auth` | `f536fc2`, `82fe4d9`, `777f2a8`, `6ac2347` | the devices list, ending one device or every other, linking a second platform's identity, refresh rotation as a switch, the account panel | merged here, conflicts resolved, 462 server tests green. Linking is sound: both proofs fresh and single-use, one identity a platform, never one with an account or a ban, no merging, a ban covering linked identities through the one ban path (`workshop.mjs` → `endAll("banned")`), deletion forgetting them, unlinking proven by the identity that stays. Two new paths repeated SR-24 and SR-28 and are fixed with them: "every other device" and ending another device from the list took a dead access token; sign-out by refresh token spent the session's bucket before the token was proven |
| `claude/3d-kit` | `11b4fa3`, `6d8ddbd` | the realm kit's pieces, ground shader and dial | no finding: geometry and a shader; environment read only by `tests/shots/kit_realm.gd` |
| `claude/3d-universe` | `930fd3a`, `d02613c`, `13eec89` | the universe map's pins, notices, side panel, strain and whole view | no finding: drawing only; a file is written only by the probe in `tests/shots/universe_zoom.gd`; the realm icon is a `res://…/realm_<key>.svg` from the server's realm key, as before, so at worst another of the game's own pictures |
| `claude/ui-kit` | `5b864e6`, `3b109da`, `a829d14` | the kit's tabs, rails, rings, HUD and skins (`client/ui/`) | no finding: drawing only; the one `load` of a path built from the environment is the screenshot tool `tests/shots/ui_screen.gd`, which the export leaves out |
| `claude/3d-character-screens` | `316ea57`, `2c09fbe` | the character screens (Forms, roster, Sage hall), portraits and the first launch's stage | no finding: layout and rendering; environment read only by the screenshot tools under `tests/shots`, which the export leaves out (`exclude_filter="tests/*"`) |
| `claude/3d-characters-2` | `72c5966`, `51ea7ea` | busts for the heist's crew row and the Sage disc (`creature_bust*.gd`, `creature_model.gd`, `world_view.gd`) | no finding: rendering only, no network, file, link or loaded data; environment read only by its screenshot tool under `tests/shots` |

## Configuration against the market standard

Read against OWASP's Secure Headers and ASVS 4 (V3, V8, V14) and what a
mobile game's backend usually ships. Checked by running `main.mjs` here.

| Item | The build | Standard | Verdict |
| --- | --- | --- | --- |
| HTTPS | HSTS `max-age=31536000` on every answer; the listener binds 127.0.0.1 behind a TLS proxy; the client refuses cleartext | HSTS a year or more | held. `includeSubDomains` and preload are the operator's, once the domain is known |
| CORS | no `Access-Control-*` header anywhere; JSON-only POSTs | none for a native client | held |
| Caching | `no-store` on every player answer (SR-22); hashed bundles `immutable`; lists an hour | sensitive data not cached | fixed |
| Pages | CSP `default-src 'none'`, hashes, `frame-ancestors 'none'`, `nosniff`, `no-referrer` (SR-04) | the same | held. `Permissions-Policy` and COOP would add nothing on pages that run no script but Google's sign-in, whose popup COOP `same-origin` breaks |
| Cookies | one: `__Host-rb_delete`, `Secure; HttpOnly; SameSite=Strict; Path=/`, five minutes | `__Host-`, Secure, HttpOnly, SameSite | held |
| CSRF | Origin and Sec-Fetch-Site checked, JSON only, nonce in cookie and token (SR-11, SR-21) | the same | fixed (SR-21) |
| Bodies | 64 KB at the listener, per-route parsers, buckets per caller (G44) | a limit at the edge | held |
| Errors | `{error: code}`; logs name the route alone | no stack to the caller, no token in a log | held |
| Secrets | from the environment, or a `0600` file made atomically; a 32-character floor; key rings to rotate | a secret store, rotation | held. The data directory is now `0700` (SR-23) |
| Dependencies | the server has none (Node's own `node:sqlite`, `node:crypto`); Node ≥ 22.5 | patched LTS | held. Node 22 is LTS to April 2027: the operator should run its latest patch |
| Tools | `tools/art`: nine pinned packages, integrity hashes, no install scripts, `npm audit` clean on 27 October; `tools/ui` (new) needs only Playwright, as `tools/art` does | lockfile, audit | held |
| Rust | both lockfiles unchanged since the RustSec check of 26 October | `cargo audit` | held |
| Godot | editor and export templates fetched from GitHub releases | pinned checksums | fixed (SR-26) |

## The client, second pass

What the Godot client stores, logs and sends, the codes players share, and
what a modified client could claim. No new finding; each line is what was
read, so the next reader need not.

- **Stored** (`user://`, the app's sandbox, Android backups off with
  `user_data_backup/allow=false`): the sign-in state (whether signed out,
  and the opaque account id: no token), the age check's band, settings,
  the outbox (receipts, lease tokens, replays; see "Left as they are"), the lease
  stock, drafts, first-launch and device notices. The refresh token is in
  Keychain or Keystore through `SecureStore`, or nowhere: without the
  plugin nothing is kept. The access token is in memory only.
- **Logged:** `ActionLog` keeps 64 entries in memory, scalars of at most 64
  characters. The length is no guard (a refresh token is 53 characters),
  but no action carries one: only `AuthSession` touches it. Its
  `dump()` is called by nothing, so nothing leaves the phone. `push_error`
  lines name paths and codes, never a value.
- **Sent:** `Authorization: Bearer` and a content type; no device id,
  advertising id or location. Telemetry is bounded on the server (SR-19).
  Every id the client puts in a path from what a player typed or pasted
  (`open_challenge`, blocks, friends, constellations, Workshop items) is
  `uri_encode`d, so a pasted "code" like `../account` stays one segment
  (`..%2Faccount`); the rest are the server's own tokens and hashes.
- **Redirects:** none followed (SR-27).
- **TLS, measured** in the 4.7.2 engine headless against local HTTPS
  servers: a certificate from an authority the device does not trust is
  refused (`RESULT_TLS_HANDSHAKE_ERROR`); with that authority pinned as
  `HttpTransport.pinned` pins it (`TLSOptions.client(chain)`) the right
  host is served, and a certificate it issued for another name is refused.
  The token reached only the right host.
- **TLS:** the platform's authorities with the host checked; a build may pin
  (`ruleborn/tls_pins`, `HttpTransport.pinned`), and none does yet. Pinning
  is optional at the market standard for a game (MASVS-NETWORK-2); if the
  operator pins, pin the intermediate and ship a backup pin.
- **Share codes:** invites and challenge links are 48 random bits from the
  server's CSPRNG, five open a player, seven days, single use for an invite.
  Guessing one at the call bucket's rate finds nothing in a lifetime. A
  13-to-15's challenge opens only for friends (`Service.challenge`), and a
  block closes both. An invite is a bearer code: whoever holds one becomes a
  friend, so every "friends only" gate of §20.7 rests on a 13-to-15 not
  accepting a stranger's posted invite. That is the design (§17.6); a
  friend request the 13-to-15 must also accept would be the stricter
  reading, and is noted for the owner with SR-14.
- **Deep links:** not built (TD.23): no URL scheme, intent filter or
  associated domain in the export presets. When built, a link should carry
  only a challenge or invite code, open the screen that asks, and never act
  on its own.
- **A modified client** can send anything; what the server believes of it:
  heists are re-simulated from their seed and commands, crews checked
  against the roster (SR-02), offline actions remade by the online rules
  and timed by the server's clock, the age band only ever tightened
  (SR-01), ratings only after a validated play, Codex studies only of a law
  the heist crossed. It is still believed about an island's exposed loot,
  laws and guards (SR-15, SR-16), a minor's purchases with no intent
  (SR-10), and its time zone: a minor who sets another zone moves §20.2's
  night (`notifications.mjs`). The phone's own zone is the market's source
  for it, and the harm is to the caller alone, so it stays.

## Needs the owner

### Ready to say yes to

Each fix below was built on a scratch copy of this branch and run against
every server test (445). "Breaks" counts the tests that turned red beyond the
item's own pin, which the fix turns round. Each is the owner's one word:
its patch, with its test turned round, is in the appendix ("the six owner
fixes as patches") and applies with `git apply`.

| Id | Recommend | Size | Breaks | Cost to honest players |
| --- | --- | --- | --- | --- |
| SR-09 | Drop `rating` and `deviation` from the target lists | 4 lines, `service.mjs` | 1 test's assertion (`matchmaking.test.mjs`) | none: the device never reads them; `GET /v1/offer` runs §12.22 |
| SR-10 | Refuse a minor's new receipt with no intent past the month's cap, before it is settled | 13 lines, `shop.mjs` | none | an Ask-to-Buy approved after its intent lapsed, over the cap, is refused (Play refunds; Apple leaves it unfinished) |
| SR-12 | Cap one player's time on one island at one hour a quarter | 10 lines, `fund.mjs` | none | none a real player meets; one alt account credits 1 hour a quarter, not 180 a day |
| SR-14 | A joiner must be a friend of, or share the constellation with, one member; a 13-to-15 on either side must be friends with each | 11 lines, `social.mjs` | 1 test, 3 lines (`seasons.test.mjs` joins strangers) | none: the client's flow befriends first |
| SR-15 | Until D60, store an island's exposed loot as at most §9.6's median richness (one full crew's carry, 750) | 5 lines, `service.mjs` | none | the richest honest islands pay raiders richness 1.0, not up to 1.65 |
| SR-16 | Refuse a law not woven, and ready, in the realm's slots or the crown's (G61's half); guards (G60) after | 11 lines, `service.mjs`, `universe.mjs`; 6 in `test/setup.mjs` | none on the server; one client test against the server (`share_tests.gd` `_online`) publishes unwoven laws and must weave first | none: the builder only offers woven laws |

The designs, and the test each turns round (`server/test/security_owner.test.mjs`):

- **SR-09.** `targetLists` stops writing the two fields. The pin asserts
  `typeof c.rating === "number"`; it becomes `!("rating" in c) &&
  !("deviation" in c)`. `matchmaking.test.mjs`'s `deviation === 350` on the
  list moves to the offer's own test.
- **SR-10.** `Shop.withinCap(account, product)`, the check `intent` already
  makes, called from `claim` before the receipt is settled and from
  `redeem` when there is no intent. A restore of a purchase already granted
  answers from its grant first, so it is untouched. The pin's second
  `redeem` now throws `monthly_cap`, and the month's total stays at €24.
- **SR-12.** `played` keys each play by player and item and credits at most
  `ONE_PLAYER_ONE_ISLAND_S = 3600` seconds to each pair a quarter, uncleared
  plays included (§18.9 counts "time actually played"). The pin's 200 plays
  of 150 s credit 3,600 s, not 30,000. The number is the owner's; one hour
  is the recommendation.
- **SR-14.** In `joinCrew`'s transaction, before the insert: refused as
  `no_such_crew` (so a stranger learns nothing) unless some member is a
  friend or in the joiner's constellation, and, if the joiner or any member
  is 13 to 15, every member is the joiner's friend. The pin's minor is
  refused; befriended, they join.
- **SR-15.** `publish` stores `min(exposed, FULL_CREW_CARRY)`; the bytes and
  their hash are unchanged. The pin's `0xffffffff` is stored as 750. When D60
  derives the figure from the ledger, the clamp becomes that derivation.
- **SR-16.** `Universe.problems` takes the bundle's laws (`lawsOf`) and adds
  `law_not_woven` for any not in a ready slot of the realm or the crown. The
  test harness's non-strict `publish` weaves what it publishes, as it
  already raises the realm. The pin's Keeper with nothing woven is refused
  `island_not_publishable`. Guards (G60) need the bundle's guard to be
  matched to a posted character, which the bundle does not name yet: that
  half stays with the build.

### SR-09 — The public target lists carry every island's raw rating (Low)

- **Where:** `server/src/service.mjs` `targetLists`, served by
  `GET /v1/bundles/:hash` without a session and cached publicly an hour.
- **What:** §12.15: *"Ratings are internal … the raw numbers are never
  shown, because visible ratings invite target-shopping."* `GET /v1/offer`
  strips them, but each list file holds every island's `rating` and
  `deviation`, deliberately, so the device can run §12.22's `offer` on it
  (`server/test/matchmaking.test.mjs` asserts it). Any client can read
  them and shop for targets.
- **Test:** `server/test/security_owner.test.mjs` (SR-09). Each owner
  item's test pins the behaviour as it is today, so it passes; the fix turns
  its assertion round.
- **Choice:** drop the numbers from the lists and have the device ask
  `GET /v1/offer` (losing the offline offer), or coarsen them to the bands
  `offer` needs, or accept the device-side offer and amend §12.15.

### SR-10 — A minor's monthly cap holds only on the client's word (Low)

- **Where:** `server/src/shop.mjs` `redeem` and `intentOf`.
- **What:** §20.2's caps (€25 for 13 to 15, €50 for 16 and 17) are checked
  when the device asks for an intent, before the store takes money. A
  receipt with no intent is granted anyway, as a restore or a family's late
  approval is, and counted after. A modified client that skips the intent
  buys past the cap; the store has the money either way. The server could
  refuse to grant a minor's receipt with no intent over the cap — Play then
  refunds an unacknowledged purchase by itself, Apple does not — but that
  changes what a restore does, so it is the owner's call.
- **Test:** `server/test/security_owner.test.mjs` (SR-10).

### SR-12 — The Island Fund pays one player's replays as if each were a new player (Medium)

- **Where:** `server/src/fund.mjs` `played`.
- **What:** §18.9's fund is real money, *"divided … by time actually played
  on each island"*, and §18.9 caps *"one player's time on one island"* —
  with no number, so the build has no cap (`fund.mjs` says so). Every
  validated Workshop play counts its seconds, cleared or not, however many
  times the same player played. A creator with one second adult account
  (the platforms give identities freely) replaying their island once every
  20 seconds — the simulation bucket's rate — credits about 180 hours a day.
  Only §18.9's 2% a creator bounds it. §18.7's quarter weight for
  constellation-mates does not apply to an account outside the
  constellation.
- **Test:** `server/test/security_owner.test.mjs` (SR-12).
- **Choice:** the cap's number — say one play's time a player an island a
  day, or a few hours a quarter — and whether a play that does not clear
  counts at all.

### SR-14 — A crew is anyone's who holds its invite, a 13-to-15's too (Low)

- **Where:** `server/src/social.mjs` `joinCrew`, `POST /v1/crews/join`.
- **What:** §17.7's crew is *"formed inside a constellation, or with friends
  across constellations"*, and §20.7 holds a 13-to-15's co-op heists to
  *"Friends only"*. Joining asks only for the invite, so a stranger's
  invite, posted anywhere, puts a 13-to-15 in a crew with strangers — the
  layer §17.7 gives *"a private thread"*. Co-op heists and the thread are
  version 1.1's, not built, so nothing reaches them yet; the season tests
  join strangers to crews, so the build means it.
- **Test:** `server/test/security_owner.test.mjs` (SR-14).
- **Choice:** require a joiner to share the constellation with, or be a
  friend of, a member — and for 13 to 15, a friend of every member — before
  co-op heists or the thread are built.

### SR-15 — An island's exposed loot is the bundle's word (Medium; register D60)

- **Where:** `server/src/service.mjs` `publish` stores bytes 6 to 9 of the
  bundle as the snapshot's `exposed`; `grant` prices every raid on it from
  them (§9.6's richness and fill).
- **What:** §24.8 says a published island's Vault level and exposed loot
  *"come from the owner's own ledger and buildings on the server, never from
  the bundle's word, and a bundle that disagrees is refused"*. The Vault
  level is held to the one built; the exposed amount is not checked at all.
  A player holding nothing publishes `0xffffffff` and every raid on the
  island pays the most richness pays: a clean raid on a Vault 3 island at
  Keeper 1 mints 18,562 against 11,250 at the level median and 0 for an
  empty vault. Colluding players, or one player's second account, mint at
  the top of the band within §9.6's day and week caps, and the island also
  shows raiders the richest loot (`loot` on the Observatory card).
- **Test:** `server/test/security_owner.test.mjs` (SR-15).
- **Why not fixed here:** deriving the figure needs §9.6's level medians and
  §10.2's sealed shares, which the server's facts do not carry yet; the
  register already holds it as D60, left to the build (TC.12). Until then a
  cap at the level median's figure would close the abuse without the full
  derivation, but it changes what every honest rich island pays, so it is
  the owner's call.

### SR-16 — An island's laws and guards are the bundle's word (Medium; register G60, G61)

- **Where:** `server/src/service.mjs` `publish` and
  `server/src/universe.mjs` `problems`.
- **What:** §24.8: *"Each posted guard's kind, form and level ride in the
  bundle, checked against the owner's roster … so a realm plays what its
  owner wove."* `problems` checks the realm, its level, the Vault and where
  buildings stand; the simulation checks how many laws, wards and guards a
  realm level allows. Which laws, and whose guards, nobody checks. A new
  Keeper with nothing woven publishes Haste, a chapter-two law they cannot
  restore before Keeper 6, and guards no character is posted to. A stronger
  island than its owner has built foils more raids, and every foil pays the
  defender the fee and §12.9's share and moves Renown.
- **Test:** `server/test/security_owner.test.mjs` (SR-16).
- **Why not fixed here:** the register holds both as open with the build
  left (G60: posted guards against the roster; G61: crown laws carried in
  the bundle, and chords against the universe's stability). Refusing a law
  not woven in the realm is a few lines in `problems`, but the client's
  builder and every test that publishes an example island would have to
  weave first, so it belongs with that build work, not in a review.

## Sent to T11

### SR-11 — The ID token that signs in also deletes the account, at once (Low)

- **Where:** `server/src/http.mjs` `POST /v1/account/delete` (G39) and the
  Google verification in `server/src/stores.mjs`.
- **What:** the page posts a Google ID token, and any token for one of the
  server's client ids proving a `gp:` identity deletes that account — the
  same tokens the game signs in with — with no nonce tying it to the page,
  no check of its age beyond its expiry, and no second step. CSRF does not
  reach it (an attacker cannot mint the victim's token), but a token that
  leaks from anywhere it is sent deletes the account for its hour. Suggested:
  the page passes a server-issued nonce through GSI and the server requires
  it in the token, or the deletion takes only the web client id's tokens
  and a recent `iat`.
- **Test:** first pinned here with the real `GoogleSignIn` (one ID token
  minted for the Android client signed the game in and deleted the
  account); T11's fix carries its own test, `server/test/auth_http.test.mjs`
  (*"a web deletion needs a fresh Google token for the web client that
  carries this browser's nonce …"*), and the pin here was retired, since its
  harness wires Google in below T11's new check and would pass either way.
- **Status:** fixed by T11 on `claude/auth` (`11a8e3c`): the deletion takes
  only a token for the web client id, issued within five minutes, carrying
  the page's nonce from its cookie, sent same-origin as JSON. A trial merge
  of the two branches passes every server test (442).

### SR-20 — A caller can keep Game Center sign-in failing (Low)

- **Where:** `server/src/stores.mjs` `GameCenter.prepare`.
- **What:** a Game Center key is fetched from Apple at most one new URL a
  second, for the whole server, into a cache of eight. A caller who names
  key URLs Apple serves — `gc-prod-N.cer`, Apple's own names — has each one
  fetched and kept, so nine of them push out the key players sign in with;
  the next player's sign-in then needs a fetch, and the caller, naming one
  a second, keeps taking the one slot. Game Center sign-in fails for as
  long as they keep it up. A key in use stays at the back of the cache
  while players keep signing in, so it takes a quiet hour, and it needs
  Apple to serve nine or more names: likely, not verified from here.
- **Test:** `server/test/security_t11.test.mjs` (SR-20), with the fetch
  standing in for Apple serving every name.
- **Suggested:** keep the fetch slot for a credential that carries a
  signature, a player id and a fresh timestamp (the shape of a real one),
  hold names fetched but never used to sign anything outside the cache of
  keys in use, or let one caller's address fetch only one new name a minute.
- **Status:** sent to T11, who owns sign-in.

### For T11: what sign-out has to do

Not a finding yet, since sign-out is T11's to build: a session token
(`tokens.mjs`) is checked by its signature and expiry alone, and the account
row only for deletion and bans, so nothing today can end one before its hour.
A sign-out that only forgets the token on the phone leaves it good on the
server; a server-side revocation (a per-account generation in the token, or
a short list of revoked ids) is what makes sign-out mean it.

## Left as they are (Info)

Each was looked at and judged not worth a change now; each is one line to
pick up later.

- **The Android secure store's library.** `secure_store.gd`'s contract
  names `EncryptedSharedPreferences`, whose AndroidX library
  (`security-crypto`) was deprecated in 2025. The plugin is not in the repository yet;
  when it is written, a Keystore AES-GCM key (non-exportable, as the
  contract says) wrapping the value, or Tink over DataStore, is the current
  advice. T11's.
- **Deletion in the game takes the access token alone.** `DELETE
  /v1/account` (and `PUT /v1/age` to under 13) ends the account on the
  session's token, with no fresh proof; ASVS V3.7 asks a sensitive action
  to re-authenticate. The token lives an hour, is never logged, never in a
  URL and never followed through a redirect (SR-27), and the web page
  already asks for a fresh Google proof (SR-11). Asking the device for a
  silent platform proof with the deletion is T11's to weigh against the
  §20.5 rule that deletion be easy.

- **A crew by role skips resting.** After SR-02 a replay with no manifest
  (`RBH1`, `RBH2`) still plays §11.1's crew by role with no roster named,
  so no character rests after it. It plays no kind's ability, so it is the
  weaker crew; requiring every replay to name its crew would retire the
  older formats.
- **Simulation time on the request thread.** A heist's re-simulation is 30
  to 90 ms of the one thread; G44's six at once an account bounds one
  caller, not many. §24.1's edge isolates are what scale it.
- **Hourly target lists.** `targetLists` reads every island and its owner's
  Renown in one go, once an hour, on the request thread: honest load, not a
  caller's, but it grows with the game.
- **Unsigned reads.** `GET /v1/bundles/:hash` takes no session and no
  bucket, as §24.8's static files must; each miss is one indexed read and a
  file check, and the edge caches the hits.
- **Snapshots.** Every island published is a snapshot kept for good
  (§24.8), and its bytes in the store; the simulation bucket (one every 20
  seconds) is the only bound, about 4 MB a day an account at the most.
  §20.12's quota bounds the Workshop's islands, not a realm's; a quota of
  the same kind for realms is the owner's call.
- **Leases.** One lease a target a raider at a time (§24.13), but a raider
  may hold one on every island; unplayed ones are deleted seven days after
  they lapse (G38). Bounded by the game's islands, not by the caller.
- **A profile's record** reads all of a player's heists each time it is
  shown: slow for a heavy player, within the call bucket.
- **Unsubmitted Workshop plays.** `POST /v1/workshop/:id/play` writes a
  row naming the player that never expires, and `privacy.json` keeps every
  play as a record (F43). A play never submitted is the Workshop's
  unplayed lease, which §20.5 deletes seven days after it closes; it never
  closes, since a play has no expiry. Giving plays a lease's day, and
  deleting the unsubmitted ones with `expireLapsed`, is the owner's call.
- **The client's outbox** keeps receipts, lease tokens and replays as plain
  JSON in the app's sandbox (`user://`); Android backups are off. The
  session token is never written.
- **The client's event queue can stick.** `Services.send_events` sends
  every pending event as one batch and keeps them all on any refusal. Past
  100 (many sessions offline) the server refuses the batch as too large,
  and an event older than seven days as too late, both for good, so the
  queue never drains and grows with each session in `user://`. Not a
  security matter; for the client's owner: send at most 100 a time, and drop
  what the server refuses as malformed rather than held back.
- **`tools/art`** loads Playwright from the machine's global install
  (`PLAYWRIGHT_MODULE`), outside its lockfile, and its loopback file server
  checks paths by prefix: tools for the developer's machine, not shipped.

## Checked and held

What was tried and found sound, so the next reader need not try it again.

- **Authorisation by id.** Every route that names an object by id was read
  for whose it is: heists and replays (raider or defender only), leases
  (bound to the attacker), characters, strays, producers, buildings, links,
  weaving slots, Lab chambers, Codex studies (the heist must be the
  caller's), Workshop items (withdraw by creator only), moderation and
  metrics (staff flags), purchases (a transaction granted once, to its
  first account), gifts (to friends only). None reads or writes another
  account's object.
- **Fuzzing the edge.** All 118 routes `http.mjs` lists, each id slot filled
  with fifteen hostile values (`constructor`, `__proto__`, another account,
  a lease token, `1e309`, `%00` …) and seventeen bodies (bare values,
  arrays, prototype keys, every field an object, a list or `1e300`, offline
  actions and telemetry of every wrong shape): 7,771 calls, no answer a 500
  from the server's code (one came from the test harness's own helper).
- **SQL.** Every statement binds its values; the few built with `${…}` put
  in constants or column names from the code, never a caller's string.
- **Storage paths.** `store.mjs` takes only 64 hex characters as a key.
- **JSON.** `JSON.parse` makes `__proto__` an own key; bodies are read field
  by field, never merged into an object the code trusts; telemetry refuses
  any prototype but `Object.prototype`.
- **Tokens and receipts.** Session tokens are HMAC-signed and compared in
  constant time, refused for a deleted or banned account. App Store
  transactions and notifications are checked against the pinned root, the
  leaf and intermediate marked as Apple marks them, P-256 only, the bundle
  id and the environment; Play purchases against the licence key, package,
  state and quantity, and settled with Google before the grant; Google ID
  tokens for issuer, audience, expiry and issue time; Game Center keys only
  from Apple's two hosts, one URL a key. Outbound URLs are encoded or the
  operator's.
- **Races.** Every route is synchronous between its body read and its
  answer, so Node runs none of them interleaved; the one asynchronous grant
  (a Play receipt settled with Google) grants inside a transaction that
  re-checks the transaction first. Heists, Workshop plays, purchases and
  refunds are each keyed once.
- **Simulation.** Fuzzed natively and as WebAssembly (island and replay
  decoding, 6,300 random command logs, 600 universe crossings, mutated
  islands through the hold measure, stability and curation inputs): no
  panic the server's routes reach, and native and WebAssembly agree on
  every replay. The only `unsafe` is `#[unsafe(no_mangle)]`; lengths, not
  pointers, cross the boundary, checked with saturating adds.
- **Client.** The session token is kept in memory only; failures are
  logged by code and route, never a token; nothing is loaded or run from
  downloaded data (`load()` takes `res://` only; no `str_to_var`,
  `Expression` or resource packs); TLS is the platform's, with no unsafe
  options; Android backups are off. The screens render no rich text (no
  `RichTextLabel`, so no BBCode links to click), draw only images they
  generate themselves, open only the terms link (SR-06), and read the
  environment only on the desktop (`RULEBORN_SERVER`, `RULEBORN_CREDENTIAL`).
- **Supply chain.** The server has no dependencies. `tools/art` pins exact
  versions with a lockfile of nine registry packages, each with its
  integrity hash and no install script; `npm audit` finds nothing. The Rust
  crates pin `godot = "=0.5.5"`, commit both lockfiles, take every crate
  from crates.io with a checksum and have no build script of their own.
  `cargo audit` is not installed, so the RustSec advisory database (as of
  26 October 2026) was cloned and every crate in both lockfiles looked up
  in it by hand: none of the 19 has an advisory.
- **Secrets.** The whole history's 30 MB of diffs searched for private keys,
  Google, Stripe and GitHub tokens, AWS keys, client secrets, passwords and
  key stores: the only private keys are the Apple test chain under
  `server/test/fixtures/apple/`, generated by its `make.sh` and named as
  test CAs; production roots come only from the environment.

## How it was checked

- `bash client/build.sh` ran once. `bash tools/check_all.sh` was run after
  each batch of fixes; in this container it cannot print "All checks
  passed" for three reasons, none of them this branch's:
  - **`gdlint` is not installed**, and installing gdtoolkit was refused. The
    runs used a stand-in that only reports it is missing; the GDScript this
    branch changes was checked by hand against gdlint's line length, and
    adds no public method.
  - **One client test fails on this date:** *"against the server: Weaving
    offers the starting laws at the simulation's prices …"*. This week's era
    is High Tide (*"Slow rivers costs no stability"*), so Slow rivers is
    priced 0 and the test's `priced > 0` fails. It fails the same way on
    the base commit `1e8619b`; it is not a security matter, and it will fail
    on every branch until the era turns on 2 November.
  - **Python's `playwright` is not installed**, so
    `tools/check_prototype_conformance.py` cannot run.
  Every other step was run, including those after the client's (by hand,
  from the line after each failure), and passed: the simulation's gate,
  all of the server's tests, the client's other 339, the export check, and
  the docs, audit and roadmap builds, which end in "All checks passed."
- Each fixed finding's test was run against the code before its fix and
  failed, then passed after it. The tests of the owner's and T11's items
  pin the behaviour as it stands, so they pass until the fix.

## Appendix: the six owner fixes as patches

Each applies alone to this branch with `git apply`, its pinned test turned
round with it, and passes every server test; applied together all six pass
448 of 448 (built and run 27 October). Together, SR-12's and SR-15's patches
both add an import to `security_owner.test.mjs`, so the second needs its
import line added by hand.

### SR-09: no ratings on the target lists

```diff
diff --git a/server/src/service.mjs b/server/src/service.mjs
index bc0411e..9b15a13 100644
--- a/server/src/service.mjs
+++ b/server/src/service.mjs
@@ -296,15 +296,13 @@ export class Service {
       // §12.3: a new player's island is nobody's target yet.
       if (this.matchmaking.shielded(r.owner, now)) continue;
       if (!bands.has(r.band)) bands.set(r.band, []);
-      // What §12.22's steps read, so the device can run `offer` on the list.
-      const rating = this.matchmaking.islandRating(r.owner, r.realm);
+      // §12.15: ratings are internal; §12.22's `offer` runs on the server
+      // (GET /v1/offer), so a list carries no rating (T12's SR-09).
       bands.get(r.band).push({
         bundle: r.bundle, owner: r.owner, realm: r.realm, realmLevel: r.realm_level,
         vaultLevel: r.vault_level, exposed: r.exposed, keeperLevel: r.keeper_level,
         renown: this.seasons.league(r.owner, now).renown,
         origin: r.origin ?? (r.owner === GENERATOR ? "generated" : "authored"),
-        rating: rating ? Math.round(rating.rating) : null,
-        deviation: rating ? Math.round(rating.deviation) : null,
       });
     }
     const index = {};
diff --git a/server/test/matchmaking.test.mjs b/server/test/matchmaking.test.mjs
index 3e7cff2..bcb96d5 100644
--- a/server/test/matchmaking.test.mjs
+++ b/server/test/matchmaking.test.mjs
@@ -262,7 +262,7 @@ test("a bundle the raider holds is not offered to them, and equal entries sort o
   assert.deepEqual(order([p, q]), order([q, p]));
 });
 
-test("the offer over HTTP: the caller's list, its middle in the band, and ratings on the target lists", async () => {
+test("the offer over HTTP: the caller's list, its middle in the band, and no ratings on the target lists (12.15)", async () => {
   const t = twoPlayers(false);
   const call = (method, path, token) => t.handle(new Request(`https://edge.example${path}`, {
     method, headers: { authorization: `Bearer ${token}` } }));
@@ -275,7 +275,7 @@ test("the offer over HTTP: the caller's list, its middle in the band, and rating
   assert.deepEqual(body.targets.map((c) => c.bundle), [t.bundle]);
   const lists = t.service.targetLists();
   const list = JSON.parse(new TextDecoder().decode(t.service.bundle(Object.values(lists)[0])));
-  assert.equal(list.candidates[0].deviation, 350);
+  assert.equal(list.candidates[0].deviation, undefined, "ratings stay on the server (T12's SR-09)");
   assert.equal(list.candidates[0].origin, "authored");
 });
 
diff --git a/server/test/security_owner.test.mjs b/server/test/security_owner.test.mjs
index b1d5283..3a5aef8 100644
--- a/server/test/security_owner.test.mjs
+++ b/server/test/security_owner.test.mjs
@@ -14,14 +14,13 @@ import { raiseTo } from "../src/universe.mjs";
 import { twoPlayers, server } from "./setup.mjs";
 
 // SR-09: §12.15, "Ratings are internal … the raw numbers are never shown".
-test("SR-09 (needs the owner): a target list names every island's raw rating, which 12.15 says is never shown", () => {
+test("SR-09 (fixed): a target list names no island's rating, which 12.15 says is never shown", () => {
   const t = twoPlayers(false);
   const lists = t.service.targetLists();
   const list = JSON.parse(new TextDecoder().decode(t.service.bundle(Object.values(lists)[0])));
   assert.ok(list.candidates.length > 0);
   for (const c of list.candidates) {
-    assert.equal(typeof c.rating, "number");
-    assert.equal(typeof c.deviation, "number");
+    assert.ok(!("rating" in c) && !("deviation" in c));
   }
 });
 
```

### SR-10: a minor's cap without an intent

```diff
diff --git a/server/src/shop.mjs b/server/src/shop.mjs
index 782a536..b3285ff 100644
--- a/server/src/shop.mjs
+++ b/server/src/shop.mjs
@@ -138,6 +138,17 @@ export class Shop {
     return Math.max(0, cap * 100 - spent - held);
   }
 
+  /** §20.2's cap on a receipt that comes with no intent: a minor's new
+   *  purchase past the month's cap is refused unsettled, so Play refunds it
+   *  and an App Store one stays unfinished (T12's SR-10). A restore of one
+   *  already granted never reaches here. */
+  withinCap(account, p) {
+    const left = this.allowance(account);
+    if (p && left !== null && p.price > left) {
+      throw new Refused(403, "monthly_cap", { left, cap: facts.SPENDING_CAPS_EUR[this.ageBand(account)] * 100 });
+    }
+  }
+
   /**
    * Step one: ask to buy a product, for oneself or, as a gift, for a friend
    * (`for`). Refused over a minor's cap, before the store is asked for
@@ -200,6 +211,7 @@ export class Shop {
       const p = this.product(proof.product);
       if (!p) throw new Refused(404, "no_such_product");
       const i = this.intentOf(proof);
+      if (!i) this.withinCap(account, p);
       if (i) {
         if (i.account !== account || i.product !== proof.product) throw new Refused(409, "intent_mismatch");
         this.db.prepare("UPDATE purchase_intents SET redeemed_at = ? WHERE id = ?").run(now, i.id);
@@ -261,7 +273,7 @@ export class Shop {
     if (!done) {
       // Refused before the store is told anything, so nothing is consumed.
       if (this.refunded(store, proof.transaction)) throw new Refused(402, "receipt_refunded");
-      this.intentOf(proof);
+      if (!this.intentOf(proof)) this.withinCap(account, this.product(proof.product));
       const settled = await this.settleReceipt(store, proof);
       if (!settled?.ok) {
         const reason = settled?.reason ?? "receipt_refused";
diff --git a/server/test/security_owner.test.mjs b/server/test/security_owner.test.mjs
index b1d5283..bc2ec99 100644
--- a/server/test/security_owner.test.mjs
+++ b/server/test/security_owner.test.mjs
@@ -26,15 +26,15 @@ test("SR-09 (needs the owner): a target list names every island's raw rating, wh
 });
 
 // SR-10: §20.2's monthly cap, kept only when the device asks for an intent.
-test("SR-10 (needs the owner): a 13-to-15's receipts with no intent are granted past the month's cap", () => {
+test("SR-10 (fixed): a 13-to-15's receipt with no intent past the month's cap is refused", () => {
   const t = server({ firstBand: "13-15",
                      cosmetics: { items: [{ id: "big", kind: "outfit", price: 2400 }, { id: "more", kind: "outfit", price: 500 }] },
                      verifyReceipt: (_s, r) => ({ transaction: r, product: r === "t1" ? "big" : "more", intent: null }) });
   const minor = t.service.session("gc:minor");
   t.service.shop.redeem(minor.account, "app-store", "t1");
-  t.service.shop.redeem(minor.account, "app-store", "t2");
-  assert.equal(t.service.shop.allowance(minor.account), 0, "€29 granted against a €25 cap");
-  assert.ok(t.service.shop.summary(minor.account).months[0].cents > 2500);
+  assert.throws(() => t.service.shop.redeem(minor.account, "app-store", "t2"), (err) => err.reason === "monthly_cap");
+  assert.equal(t.service.shop.allowance(minor.account), 100, "€24 granted, €1 left of €25");
+  assert.equal(t.service.shop.summary(minor.account).months[0].cents, 2400);
 });
 
 // SR-12: §18.9's Island Fund is real money, divided by time played, and
```

### SR-12: an hour a player an island a quarter

```diff
diff --git a/server/src/fund.mjs b/server/src/fund.mjs
index adbb231..7ad34a5 100644
--- a/server/src/fund.mjs
+++ b/server/src/fund.mjs
@@ -26,8 +26,9 @@
 // A quarter is closed once, after it ends, by the daily job: the payouts are
 // written then and never again (G-register). Not built, because §18.9 gives
 // no numbers for them: the share per hour that "falls in bands as a
-// creator's total rises", the floor for an island past 500 completions, and
-// the cap on one player's time on one island. Identity checks and paying the
+// creator's total rises" and the floor for an island past 500 completions.
+// The cap on one player's time on one island is the owner's number (T12's
+// SR-12, ONE_PLAYER_ONE_ISLAND_S). Identity checks and paying the
 // money are outside the server.
 
 import { readFileSync } from "node:fs";
@@ -39,6 +40,10 @@ import { kin } from "./workshop.mjs";
 
 const facts = JSON.parse(readFileSync(new URL("./facts.json", import.meta.url), "utf8"));
 
+/** §18.9's cap on one player's time on one island, a quarter (T12's SR-12,
+ *  the owner's number): past it, a player's replays credit nothing. */
+export const ONE_PLAYER_ONE_ISLAND_S = 60 * 60;
+
 /** The UTC quarter `at` falls in: its number since 1970 and its bounds. */
 export function quarterOf(at) {
   const d = new Date(at);
@@ -100,14 +105,18 @@ export class Fund {
    *  on an island removed from the Workshop. */
   played(from, to) {
     const rows = this.db.prepare(
-      `SELECT p.player, p.ticks, p.outcome, i.creator, i.published_at FROM workshop_plays p
+      `SELECT p.player, p.item, p.ticks, p.outcome, i.creator, i.published_at FROM workshop_plays p
          JOIN workshop_items i ON i.id = p.item
         WHERE p.submitted_at >= ? AND p.submitted_at < ? AND i.removed_at IS NULL`).all(from, to);
     const out = {};
+    const each = new Map();
     for (const r of rows) {
       const o = r.outcome ? JSON.parse(r.outcome) : null;
       if (!o?.validated || r.player === r.creator) continue;
-      const seconds = Number.isInteger(o.report?.held) ? o.report.held : r.ticks / TICKS_PER_SECOND;
+      const played = Number.isInteger(o.report?.held) ? o.report.held : r.ticks / TICKS_PER_SECOND;
+      const key = `${r.player} ${r.item}`;
+      const seconds = Math.min(played, ONE_PLAYER_ONE_ISLAND_S - (each.get(key) ?? 0));
+      each.set(key, (each.get(key) ?? 0) + seconds);
       const weight = kin(this.db, r.player, r.creator, r.published_at) ? facts.KIN_COMPLETION_WEIGHT : 1;
       out[r.creator] = (out[r.creator] ?? 0) + seconds * weight;
     }
diff --git a/server/test/security_owner.test.mjs b/server/test/security_owner.test.mjs
index b1d5283..3d8b470 100644
--- a/server/test/security_owner.test.mjs
+++ b/server/test/security_owner.test.mjs
@@ -6,7 +6,7 @@
 import assert from "node:assert/strict";
 import { test } from "node:test";
 
-import { quarterOf } from "../src/fund.mjs";
+import { ONE_PLAYER_ONE_ISLAND_S, quarterOf } from "../src/fund.mjs";
 import { Social } from "../src/social.mjs";
 import { TICKS_PER_SECOND } from "../src/service.mjs";
 import { lawsOf } from "../src/telemetry.mjs";
@@ -41,7 +41,7 @@ test("SR-10 (needs the owner): a 13-to-15's receipts with no intent are granted
 // "the cap on one player's time on one island" is not built (fund.mjs: no
 // number for it). One second account replaying a creator's island all day
 // credits it hundreds of hours.
-test("SR-12 (needs the owner): one player replaying one island is credited every play's time", () => {
+test("SR-12 (fixed): one player replaying one island is credited an hour a quarter at most", () => {
   const t = server();
   const q = quarterOf(t.clock.now);
   const db = t.service.db;
@@ -55,8 +55,8 @@ test("SR-12 (needs the owner): one player replaying one island is credited every
     db.prepare(`INSERT INTO workshop_plays (token, player, item, seed, ticks, issued_at, submitted_at, outcome)
                 VALUES (?, ?, 'i', '1', ?, ?, ?, '{"validated":true}')`).run(`p${n}`, alt, 150 * TICKS_PER_SECOND, at, at);
   }
-  assert.equal(t.service.fund.played(q.starts_at, q.ends_at)[creator], 200 * 150,
-               "200 plays by one account, 200 plays' seconds");
+  assert.equal(t.service.fund.played(q.starts_at, q.ends_at)[creator], ONE_PLAYER_ONE_ISLAND_S,
+               "200 plays by one account, one hour");
 });
 
 // SR-14: §17.7's crews are "formed inside a constellation, or with friends
```

### SR-14: crews of friends or constellation-mates

```diff
diff --git a/server/src/social.mjs b/server/src/social.mjs
index 81cc6a1..63038b7 100644
--- a/server/src/social.mjs
+++ b/server/src/social.mjs
@@ -223,6 +223,17 @@ export class Social {
     return transaction(this.db, () => {
       const [, most] = facts.CREW_SIZE;
       if (this.crew(c.id).members.length >= most) throw new Refused(409, "crew_full", { size: most });
+      // §17.7: "formed inside a constellation, or with friends across
+      // constellations"; §20.7 holds a 13-to-15 to friends only, either way
+      // round (T12's SR-14).
+      const members = this.crew(c.id).members.map((m) => m.account);
+      const band = (a) => this.db.prepare("SELECT age_band FROM accounts WHERE id = ?").get(a)?.age_band;
+      const friend = (m) => this.service.friends.areFriends(account, m);
+      const mine = this.membership(account)?.constellation;
+      const near = (m) => friend(m) || (mine != null && this.membership(m)?.constellation === mine);
+      if (!members.some(near) || members.some((m) => (band(m) === "13-15" || band(account) === "13-15") && !friend(m))) {
+        throw new Refused(404, "no_such_crew");
+      }
       this.db.prepare("INSERT INTO crew_members (crew, account, joined_at) VALUES (?, ?, ?)")
         .run(c.id, account, this.now());
       return this.crew(c.id, account);
diff --git a/server/test/seasons.test.mjs b/server/test/seasons.test.mjs
index 2d9b93f..1ad7467 100644
--- a/server/test/seasons.test.mjs
+++ b/server/test/seasons.test.mjs
@@ -207,6 +207,9 @@ test("a ban takes the player out of their constellation, handing it on, and out
 test("a crew is four to eight, joined by its invite, and survives its founder leaving (17.7)", () => {
   const t = beacon(10);
   const [first, ...rest] = t.players;
+  // Formed inside a constellation (§17.7, T12's SR-14).
+  const c = t.social.found(first, { adjective: 0, noun: 0 });
+  for (const p of rest) t.social.join(p, c.id);
   const crew = t.social.startCrew(first);
   assert.equal(crew.formed, false, "one Keeper is not yet a crew");
   for (const p of rest.slice(0, 3)) t.social.joinCrew(p, crew.invite);
diff --git a/server/test/security_owner.test.mjs b/server/test/security_owner.test.mjs
index b1d5283..42a1405 100644
--- a/server/test/security_owner.test.mjs
+++ b/server/test/security_owner.test.mjs
@@ -62,15 +62,24 @@ test("SR-12 (needs the owner): one player replaying one island is credited every
 // SR-14: §17.7's crews are "formed inside a constellation, or with friends
 // across constellations", and §20.7 holds a 13-to-15's co-op heists to
 // friends only; joining takes only the invite.
-test("SR-14 (needs the owner): a 13-to-15 joins a crew of strangers with its invite", () => {
+test("SR-14 (fixed): a crew takes friends or constellation-mates, and a 13-to-15 only friends", () => {
   const t = server();
   const social = new Social(t.service);
   const stranger = t.service.session("gc:stranger").account;
   const minor = t.service.session("gc:minor").account;
+  const adult = t.service.session("gc:adult").account;
   t.service.db.prepare("UPDATE accounts SET age_band = '13-15' WHERE id = ?").run(minor);
   const crew = social.startCrew(stranger);
-  assert.equal(t.service.friends.areFriends(minor, stranger), false);
-  assert.equal(social.joinCrew(minor, crew.invite).members.length, 2);
+  const refused = (who) => assert.throws(() => social.joinCrew(who, crew.invite), (err) => err.reason === "no_such_crew");
+  refused(minor);
+  refused(adult);
+  const befriend = (a, b) => t.service.friends.accept(b, t.service.friends.invite(a).invite);
+  befriend(stranger, minor);
+  assert.equal(social.joinCrew(minor, crew.invite).members.length, 2, "a friend joins");
+  befriend(stranger, adult);
+  refused(adult);
+  befriend(minor, adult);
+  assert.equal(social.joinCrew(adult, crew.invite).members.length, 3, "a friend of every member joins a 13-to-15's crew");
 });
 
 // SR-15 (register D60): §24.8 has a published island's exposed loot "come
```

### SR-15: exposed loot at most the median's

```diff
diff --git a/server/src/service.mjs b/server/src/service.mjs
index bc0411e..51e4a16 100644
--- a/server/src/service.mjs
+++ b/server/src/service.mjs
@@ -24,7 +24,7 @@ import { readFileSync } from "node:fs";
 
 import { transaction } from "./db.mjs";
 import { Refused } from "./refused.mjs";
-import { capHaul, defenceShare, entryFee, feeReturned, haul, RAIDS_A_WEEK, RENOWN_HEISTS_A_WEEK } from "./economy.mjs";
+import { capHaul, defenceShare, entryFee, feeReturned, FULL_CREW_CARRY, haul, RAIDS_A_WEEK, RENOWN_HEISTS_A_WEEK } from "./economy.mjs";
 import { byWire, eraAt } from "./eras.mjs";
 import { Friends } from "./friends.mjs";
 import { Matchmaking } from "./matchmaking.mjs";
@@ -239,7 +239,10 @@ export class Service {
         `INSERT OR IGNORE INTO snapshots
            (bundle, owner, realm, realm_level, vault_level, exposed, rules, published_at, origin)
          VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)`)
-        .run(key, owner, realm, bundle[4], bundle[5], view.getUint32(6, true),
+        // §24.8: never the bundle's word. Until D60 derives it from the
+        // ledger, no island claims more than §9.6's median richness, 1.0
+        // (T12's SR-15).
+        .run(key, owner, realm, bundle[4], bundle[5], Math.min(view.getUint32(6, true), FULL_CREW_CARRY),
              build.rulesVersion, now, origin);
       // §13.3: a curated layout keeps the seed it was drawn from and its
       // terrain's digest while it stays generated (curation.mjs).
diff --git a/server/test/security_owner.test.mjs b/server/test/security_owner.test.mjs
index b1d5283..7ee05fd 100644
--- a/server/test/security_owner.test.mjs
+++ b/server/test/security_owner.test.mjs
@@ -6,6 +6,7 @@
 import assert from "node:assert/strict";
 import { test } from "node:test";
 
+import { FULL_CREW_CARRY } from "../src/economy.mjs";
 import { quarterOf } from "../src/fund.mjs";
 import { Social } from "../src/social.mjs";
 import { TICKS_PER_SECOND } from "../src/service.mjs";
@@ -76,14 +77,14 @@ test("SR-14 (needs the owner): a 13-to-15 joins a crew of strangers with its inv
 // SR-15 (register D60): §24.8 has a published island's exposed loot "come
 // from the owner's own ledger and buildings on the server, never from the
 // bundle's word"; the server stores the four bytes the client wrote.
-test("SR-15 (needs the owner, D60): an island's exposed loot is the bundle's word", () => {
+test("SR-15 (fixed until D60): an island's exposed loot is at most the median richness's, whatever the bundle says", () => {
   const t = server();
   const owner = t.service.session("gc:owner").account;
   const island = t.build.exampleIsland(true);
   new DataView(island.buffer, island.byteOffset).setUint32(6, 0xffffffff, true);
   const { bundle } = t.service.publish(owner, island);
   const exposed = t.service.db.prepare("SELECT exposed FROM snapshots WHERE bundle = ?").get(bundle).exposed;
-  assert.equal(exposed, 0xffffffff, "a player with nothing stored claims the most richness pays");
+  assert.equal(exposed, FULL_CREW_CARRY, "a claim of the most richness pays is held to 1.0");
   assert.deepEqual(t.service.balance(owner), { starlight: 0, essence: 0 });
 });
 
```

### SR-16: only woven laws

```diff
diff --git a/server/src/service.mjs b/server/src/service.mjs
index bc0411e..39eb5d8 100644
--- a/server/src/service.mjs
+++ b/server/src/service.mjs
@@ -229,7 +229,8 @@ export class Service {
     // And what the owner's universe has built: the realm open, its level,
     // the Vault (universe.mjs).
     const problems = [...read.problems, ...(realm === "heart" && bundle[4] !== HEART_LEVEL ? ["heart_level"] : []),
-                      ...this.universe.problems(owner, realm, bundle[4], bundle[5], build.buildings(bundle))];
+                      ...this.universe.problems(owner, realm, bundle[4], bundle[5], build.buildings(bundle),
+                                                lawsOf(bundle), this.now())];
     if (problems.length) throw new Refused(422, "island_not_publishable", { problems });
     const key = this.store.put(bundle, read.digest);      // the two SHA-256s must agree
     const now = this.now();
diff --git a/server/src/universe.mjs b/server/src/universe.mjs
index 0f446f8..e61da42 100644
--- a/server/src/universe.mjs
+++ b/server/src/universe.mjs
@@ -346,7 +346,7 @@ export class Universe {
    *  built, or its `buildings` ([{kind, x, y}]) not the realm's placed ones
    *  on their tiles. The game's own seeded islands answer to no universe
    *  (§13.1). */
-  problems(owner, realm, realmLevel, vaultLevel, buildings = []) {
+  problems(owner, realm, realmLevel, vaultLevel, buildings = [], laws = [], now = 0) {
     if (this.db.prepare("SELECT seeded FROM accounts WHERE id = ?").get(owner)?.seeded) return [];
     const out = [];
     const r = this.realms(owner).find((x) => x.realm === realm);
@@ -357,6 +357,12 @@ export class Universe {
     const at = (b) => `${b.kind} ${b.x} ${b.y}`;
     const placed = this.buildings(owner).filter((b) => b.realm === realm && b.x != null).map(at).sort();
     if (placed.join() !== buildings.map(at).sort().join()) out.push("buildings_not_as_placed");
+    // §24.8: "a realm plays what its owner wove" — each law woven, and ready,
+    // in this realm's slots or the crown's (T12's SR-16, register G61).
+    const woven = new Set(this.db.prepare(
+      "SELECT law FROM law_slots WHERE owner = ? AND realm IN (?, 'crown') AND law IS NOT NULL AND ready_at <= ?")
+      .all(owner, realm, now).map((r) => r.law));
+    if (laws.some((l) => !woven.has(l))) out.push("law_not_woven");
     return out;
   }
 }
diff --git a/server/test/security_owner.test.mjs b/server/test/security_owner.test.mjs
index b1d5283..62c502a 100644
--- a/server/test/security_owner.test.mjs
+++ b/server/test/security_owner.test.mjs
@@ -91,7 +91,7 @@ test("SR-15 (needs the owner, D60): an island's exposed loot is the bundle's wor
 // and "each posted guard's kind, form and level ride in the bundle, checked
 // against the owner's roster". Neither is checked: an island defends with
 // laws its owner never wove and guards nobody posted.
-test("SR-16 (needs the owner, G60 and G61): an island's laws and guards are the bundle's word", () => {
+test("SR-16 (laws fixed, G61; guards still the bundle's word, G60): an island runs only laws its owner wove", () => {
   const t = server({ strictUniverse: true });
   const owner = t.service.session("gc:owner").account;
   const island = t.build.exampleIsland(false);
@@ -102,5 +102,6 @@ test("SR-16 (needs the owner, G60 and G61): an island's laws and guards are the
   const posted = t.service.db.prepare("SELECT COUNT(*) AS n FROM characters WHERE owner = ? AND work_kind = 'guardian_post'")
     .get(owner).n;
   assert.equal(posted, 0, "nobody posted");
-  assert.match(t.service.publish(owner, island).bundle, /^[0-9a-f]{64}$/, "and the island is published to defend");
+  assert.throws(() => t.service.publish(owner, island),
+                (err) => err.reason === "island_not_publishable" && err.detail.problems.includes("law_not_woven"));
 });
diff --git a/server/test/setup.mjs b/server/test/setup.mjs
index e404b41..67b99e4 100644
--- a/server/test/setup.mjs
+++ b/server/test/setup.mjs
@@ -12,6 +12,7 @@ import { REALMS, Service } from "../src/service.mjs";
 import { Build, Builds } from "../src/sim.mjs";
 import { Store } from "../src/store.mjs";
 import { raiseTo } from "../src/universe.mjs";
+import { lawsOf } from "../src/telemetry.mjs";
 
 export const WASM = fileURLToPath(new URL(
   "../../sim/target/wasm32-unknown-unknown/release/ruleborn_sim.wasm", import.meta.url));
@@ -68,7 +69,13 @@ export function server({ strictUniverse = false, strictTerms = false, ...options
   if (!strictUniverse) {
     const publish = service.publish.bind(service);
     service.publish = (owner, bundle, realm = "heart", options = {}) => {
-      if (REALMS.includes(realm) && bundle?.length > 5) raiseTo(service.db, owner, realm, bundle[4], bundle[5]);
+      if (REALMS.includes(realm) && bundle?.length > 5) {
+        raiseTo(service.db, owner, realm, bundle[4], bundle[5]);
+        // And its laws woven in the realm, ready (T12's SR-16).
+        lawsOf(bundle).forEach((law, i) => service.db.prepare(
+          `INSERT INTO law_slots (owner, realm, slot, law, tier, ready_at) VALUES (?, ?, ?, ?, 1, 0)
+           ON CONFLICT (owner, realm, slot) DO UPDATE SET law = excluded.law, ready_at = 0`).run(owner, realm, 100 + i, law));
+      }
       return publish(owner, bundle, realm, options);
     };
   }
```

## Stopped here

Twenty findings: one High, eight Medium, eleven Low.

- **Fixed (12):** SR-01 (High); SR-02, SR-03, SR-07, SR-17 and SR-19
  (Medium); SR-04, SR-05, SR-06, SR-08, SR-13 and SR-18 (Low). Each has a
  test that failed before its fix and passes after.
- **Needs the owner (6):** SR-12, SR-15 and SR-16 (Medium); SR-09, SR-10
  and SR-14 (Low). Each test pins the behaviour as it stands; the decision
  turns it round. SR-15 and SR-16 are the register's D60, G60 and G61,
  open with the build left. The others are the build against a rule
  (§12.15, §20.2, §17.7 with §20.7) or a rule without its number (§18.9's
  cap), so no new register item was added: the register tracks the
  document, and these are written up here with their choices.
- **Sent to T11 (2):** SR-11, which T11 has fixed on `claude/auth`
  (`11a8e3c`), and SR-20, still open, its test in
  `server/test/security_t11.test.mjs`; and a note on what sign-out has to
  do, which T11's sessions now answer (`POST /v1/session/end`, refresh
  tokens). A trial merge of the two branches passes all 442 server tests.

Not reviewed in depth: the client's screens' layout code, beyond what they
open, run, load, render as rich text or log; `tools/` beyond its supply
chain; the design document's own security statements against each other.

What would be done next: SR-15 and SR-16 with the economy build (TC.12);
the hold measurement off the request thread; a cap on realm snapshots like
the Workshop's quota; and the client's event queue.
