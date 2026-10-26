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
