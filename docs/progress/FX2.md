# FX2 fixer, server B: progress

- Status: Blocked on FX2-R1. FX2-5-auth-lows has all six fixes committed at 5e4979d0 (main 02558e05 merged). `cd server && npm test` gives 567 of 578: 11 tests in three files outside the task's files write replay manifests without the `form` byte, which RB-25 now checks.
- Progress: 4 of 5 tasks merged (FX2-1 at 23cf8a90, FX2-2 at 8ed7538f, FX2-3 at c7cdcbbd, FX2-4 at e413e4a9). FX2-5 is blocked on one request. No gate items.
- Done: RB-23, RB-24, RB-25, RB-26 and RB-60, and candidate 23 (it reproduced, fixed here). Each has a test written first that fails on main.
- Next: the lead answers FX2-R1. With its default, FX2 applies three one-line test corrections, then runs npm test, check_all and owners.py and marks the task ready.
- Blocked by: FX2-R1 (lead), due 2026-11-22T09:00:00Z.
- Owner decision needed: none.

| Deliverable | Weight (h) | Status | Evidence |
|---|---:|---|---|
| FX2-1-db-store-home: RB-01, RB-02, RB-07, RB-22 | 3.5 | merged at 23cf8a90 | `server/test/fix_fx2_db_store_home.test.mjs` |
| FX2-2-trace-telemetry: RB-31, RB-32, RB-49, RB-21, candidate 21 | 3.5 | merged at 8ed7538f | `server/test/fix_fx2_trace_telemetry.test.mjs`; `docs/security/audit-2026-11/server.md` |
| FX2-3-shop: RB-08, RB-09, RB-11, RB-10, RB-13 | 4.0 | merged at c7cdcbbd | `server/test/fix_fx2_shop.test.mjs` |
| FX2-4-purge-notify: RB-33, RB-34, RB-46, RB-47, RB-48 | 4.0 | merged at e413e4a9 | `server/test/fix_fx2_purge_notify.test.mjs`. Commits: 7dad0e16 (tests), 81580799 (test assertion name), 0c9e6c67 (RB-33), 0f3b6494 (RB-34), a9678f50 (RB-46), e4b8d44c (RB-47), 5cdb0318 (RB-48), 20acfab8 (merge of main), b4445a58 (status) |
| FX2-5-auth-lows: RB-23, RB-24, RB-25, RB-26, RB-60, candidate 23 | 4.0 | blocked on FX2-R1 | `server/test/fix_fx2_auth_lows.test.mjs`. Commits: 83ba326a (tests), b63fe5ca (RB-23), d981f86f (RB-24), 51c133ad (RB-25), 20fd2dee (RB-26), 268243b4 (RB-60 test guard), cfc93897 (RB-60), df07570d (candidate 23), 5e4979d0 (merge of main) |

## Handoff
- **Last verified commit:** 5e4979d0, which is df07570d with main 02558e05 (lead cycle 162) merged in, with no conflict. The commit after it changes only this handoff and the status file.

### The tests
- All six tests are in `server/test/fix_fx2_auth_lows.test.mjs`, committed alone in 83ba326a before any fix and run on it. 83ba326a's `server/src/` is main's. All six fail:
  - **RB-23** (`a device refreshing every hour stays signed in with a 720-hour rotation span`): `refresh #721 at 720.5 h refused: session_refused`.
  - **RB-24** (`a lapsed session's refresh token does not sign out everywhere`): `the same answer refresh gives for A`, expected 401, actual 200.
  - **RB-25** (`a manifest member's form must be the character's`): expected `'crew_mismatch'`, actual `undefined`.
  - **RB-26** (`the roles route acts only on the constellation its URL names`): `a wrong id answers 200`.
  - **RB-60** (`the privacy policy shows no leftover reference text`): `the page shows "(to, )"`.
  - **Candidate 23** (`viewing another player's profile does not fix their tier price`): `the view wrote no standing for the viewed player`, expected 0, actual 1.
- **One line of my own test was corrected after the fail-first commit** (268243b4). RB-60's last guard checked that "(ISO 3166" stays on the page, but that text was never on the rendered page, before the fix or after it. It now checks three prose parentheses the page does show: "(30 days unused", "(products, prices, refunds)" and "(an hour)". The test still fails before the fix with the same error, `the page shows "(to, )"`.

### The fixes
- **RB-23** (b63fe5ca, `auth.mjs` `refresh`). A refresh inside the rotation span keeps the token only while the span is less than `IDLE_MS - SESSION_MS`. So whatever `RULEBORN_REFRESH_ROTATE_HOURS` says, a device refreshing on time rotates, and `used_at` moves, before the idle lapse.
- **RB-24** (d981f86f, `auth.mjs` `signOutWith`). "Everywhere" now refuses a refresh token whose session is past the idle lapse or the absolute limit, the same 401 `refresh` gives for it.
- **RB-25** (51c133ad, `home.mjs` `crewProblem`). Each member's `form` must equal `formIndex(c)`, beside kind, level and traits.
- **RB-26** (20fd2dee, `http.mjs` and `social.mjs`). The roles route passes the URL's id to `appoint`, which refuses a founder of another constellation with 403 `founder_only`. The id parameter is optional, so the existing callers in tests that pass none are unchanged.
- **RB-60** (cfc93897, `pages.mjs` `plain`). The reference pattern now takes "to" or "and" between references, and multi-letter tags such as SEC-18. The rendered page was compared before and after: only the three cells the report names change.
- **Candidate 23** (df07570d, `profile.mjs`). Another player's profile read their league through `seasons.league`, and that opened their standing and fixed their tier price at the viewer's time. A view of another player (`own: false`) now uses `leagueSeen`, which reads the standing if there is one, or else the opening `standing` would write, and writes nothing. A scratch test compared it with the player's own `seasons.league` over three seasons and found them equal. Since it reproduced, nothing goes under "Unproven, rechecked".

### FX2-R1: three tests that wrote the defect
- RB-25's fix makes 11 tests fail. They build replay manifests without `form`, which the device always writes (`home.show(...).characters[i].wire`). The three builders are outside this task's files. owners.py says "no task in flight owns it: the lead does", so, per the protocol and S3-R30's precedent, I committed none of them:
  - `server/test/casts.test.mjs:27`: `kind: KINDS.indexOf(c.kind), level: c.level,` → `kind: KINDS.indexOf(c.kind), form: c.wire.form, level: c.level,`
  - `server/test/rest.test.mjs:21`: the same change.
  - `server/test/setup.mjs:166` (`crewed`): `kind: kinds.indexOf(c.kind), level: c.level,` → `kind: kinds.indexOf(c.kind), form: c.wire.form, level: c.level,`
- With those three lines applied, `cd server && npm test` passes 578 of 578 (checked on df07570d and reverted). The 11 failing tests without them:
  - casts: "a cast used is paid at validation…", "a cast must be the raider's own restored law…", "a law cast in a foiled heist…"
  - rest: "a heist names its crew from the roster…", "a resting character is woken early…"
  - security_deep_heists: the two SEC-24 friendly heist tests.
  - Four more through `crewed`: RB-47's friendly heist test, "a friendly heist is for fun…", "a foiled raid earns a foiled heist's experience…" and "a challenge, a friendly heist or an echo robbed nobody…".

### For the audit (outside this task's entries, not fixed)
- `matchmaking.mjs` lines 275, 348 and 366 call `seasons.league` for accounts other than the caller, so they open those players' standings too, the way candidate 23 did.
- The privacy page still shows "(docs/security/auth.md)", "(expireReplays)" and "(snapshots)" (`privacy.json` lines 2078, 2138, 2465 and 2471). These are code references, not the § or audit references `plain` removes, and the report names only the three cells above.
- `profile.view` for another player still runs `codex.ensure` and `home.ensure` for them (`profile.mjs`, "written the first time they are asked for").

### Merge and evidence
- **Merge:** main 02558e05 merged at 5e4979d0 with no conflict. It changed only the backlog, the lead's files and status files.
- **`cd server && npm test`** on 5e4979d0: 578 tests, 567 pass, 11 fail (the 11 above). With FX2-R1's three lines: 578 of 578.
- **`python3 tools/coord/owners.py diff FX2-5-auth-lows origin/claude/videogame-project-analysis-ewkkk2 5e4979d0`:** "every changed path is inside its files".
- **check_all:** not run, because the task is not ready until FX2-R1 is answered.
- **Setup:** as in FX2-4. The wasm is built, and `npm install` in `server/` with its lock file deleted.
- **Next step:** once FX2-R1 is granted (its default), apply the three lines and commit them naming RB-25. Then run npm test, merge main, run check_all and owners.py, and set ready.

## Tried and failed
- 2026-11-21 The first RB-32 drain test passed on main, for the wrong reason (`401 session_refused`). Its session was made before the clock moved 12 h, and a session lasts an hour. It now signs in after the clock moves.
- 2026-11-21 Tried to make RB-49 fail on main by forcing query plans: `NOT INDEXED`, `INDEXED BY`, a dropped index and `reverse_unordered_selects`. All returned the right raider. See "The tests".
- 2026-11-21 Ran the Nursery tests before building the wasm: "ruleborn_sim.wasm is not built". Built it with `cargo build --release --target wasm32-unknown-unknown` in `sim/`.
- 2026-11-21 Raised the test Nursery to level 2 with the starting Spire: refused, `needs_spire_level`. The test helper now sets the Spire to level 3.
- 2026-11-21 `(cd server && npm ci)` in the setup line: no `package-lock.json` in `server/`. Ran `npm install` instead and deleted the lock file it wrote.
- 2026-11-21 `git merge origin/main`: "refusing to merge unrelated histories". The program's main is `origin/claude/videogame-project-analysis-ewkkk2`; merged that instead.
- 2026-11-21 The RB-33 test called `assert.notmatch`, which node's assert does not have. Corrected to `assert.doesNotMatch` in 81580799.
