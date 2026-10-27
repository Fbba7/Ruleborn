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
| SR-11 | Low | server | The ID token that signs in also deletes the account, at once | sent to T11 |

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

## Needs the owner

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
- **Test:** `server/test/security_t11.test.mjs` (SR-11), with the real
  `GoogleSignIn`: one ID token minted for the Android client signs the game
  in at `POST /v1/session` and deletes the account at
  `POST /v1/account/delete`. It pins the behaviour as it stands; the fix
  turns it round.
- **Status:** sent to T11, who owns sign-in.

## Left as they are (Info)

Each was looked at and judged not worth a change now; each is one line to
pick up later.

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
  options; Android backups are off.
- **Supply chain.** The server has no dependencies. `tools/art` pins exact
  versions with a lockfile of nine registry packages, each with its
  integrity hash and no install script; `npm audit` finds nothing. The Rust
  crates pin `godot = "=0.5.5"`, commit both lockfiles, take every crate
  from crates.io with a checksum and have no build script of their own;
  `cargo audit` is not installed and the advisory database could not be
  fetched through the proxy, so the crates' advisories are unchecked.
- **Secrets.** The whole history's 30 MB of diffs searched for private keys,
  Google, Stripe and GitHub tokens, AWS keys, client secrets, passwords and
  key stores: the only private keys are the Apple test chain under
  `server/test/fixtures/apple/`, generated by its `make.sh` and named as
  test CAs; production roots come only from the environment.
