# FX1 server fixes (A): progress

- Status: Green. FX1-13-codex-woven-at: fail-first test c9693432, fix e6f582a5, main 632ab460 merged at a1eb8cfb; ready at a1eb8cfb (pre-check PASS).
- Progress: 8 of 12 tasks merged (FX1-1, FX1-2, FX1-3, FX1-4, FX1-6, FX1-7, FX1-8, FX1-9); no gate items (fix tasks have none).
- Done: FX1-13: FX1-A-17's residual (FX1-R25) fixed after its fail-first test: mastery() counts the woven step only once woven_at is at or before now, in the Codex and the profile.
- Next: the lead merges FX1-13; then FX1-10-tools-contract once FX4-7-curation-swap-weave merges.
- Blocked by: none.
- Owner decision needed: none (FX1-R27 is the lead's, with a default).

| Deliverable | Weight (h) | Status | Evidence |
|---|---:|---|---|
| FX1-1-workshop-pairs: RB-30, RB-05, RB-06 | 3.0 | merged (8ed7538f) | `server/test/fix_fx1_workshop_pairs.test.mjs`; test commit 3785a41c; fixes in `server/src/workshop.mjs`, `server/src/service.mjs`, `server/src/matchmaking.mjs` |
| FX1-2-leases: RB-12, RB-14, RB-16, RB-17 | 3.5 | merged (c7cdcbbd) | `server/test/fix_fx1_leases.test.mjs`; test commit d1c34426; fixes 68b8d6f9, 092bc9fd, 2c55de1f, 165fa31f |
| FX1-3-workshop: RB-35, RB-37, RB-38, RB-39 | 3.5 | merged (e413e4a9) | `server/test/fix_fx1_workshop.test.mjs`; test commit bf0ff93e; fixes c717a9b1, 1faccdd2, 2ac59da1, a4817445 |
| FX1-4-holds-codex: RB-15, RB-18, RB-36, RB-53, RB-56 | 4.0 | merged (e2e8f5a1) | `server/test/fix_fx1_holds_codex.test.mjs`; test commit 924726b8; fixes 103d4176, 1de6f966, 63f031ad, 07047356, b45dafe6 |
| FX1-6-audit-server-a: FX1-A-01 to A-17 | 4.0 | merged (ddf4213d) | `docs/security/audit-2026-11/server-a.md`; `server/test/fix_fx1_audit_server_a.test.mjs`; test commits 6b3556f9, 5d5d2e82, b0e4cd1c, f33ccc18; fixes f1888bba, dfc5bf86, 244b9480, 533b793d, ccda8b22; A-07 reverted 01cb97ac (R11) |
| FX1-7-audit-tools: FX1-T-01 to T-22 | 4.0 | merged | `docs/security/audit-2026-11/tools.md`; `server/test/fix_fx1_audit_tools.test.mjs`, `server/test/fix_fx1_audit_tools_proofs.mjs`; proof commits 3c7ad511, 4ef72ffd; report b5283fa8 |
| FX1-8-server-a-lows: A-02, A-10, A-13, A-15, A-16, A-17, R10, AUD-B-18 | 3.0 | ready (dbf44adf) | `server/test/fix_fx1_audit_server_a.test.mjs`, `server/test/fix_fx1_server_a_lows.test.mjs`, `server/test/fix_fx2_audit_config.test.mjs`; test commit e0ea0eab; fixes 3e2e872f, 9c25c35f, 8180b333, 2419848b, ad2bc945, 991324a6, 14807c73, bad2df32; privacy e46fd2a5 (FX1-R24) |
| FX1-9-tools-gate | 3.0 | merged (e830e15b) | `server/test/fix_fx1_tools_gate.test.mjs`; merge a8b4c0a8 (ad5e56bf) |
| FX1-13-codex-woven-at: FX1-A-17's residual (FX1-R25) | 1.0 | ready (a1eb8cfb) | `server/test/fix_fx1_codex_woven.test.mjs`; test commit c9693432; fix e6f582a5 |

## Handoff
- **FX1-13-codex-woven-at (2026-11-24).** Branch `claude/fix-server-a`, with main 1f0475a4 merged (864c9597) before the claim and main 632ab460 merged at a1eb8cfb. FX1-A-17's residual, from request FX1-R25: `weaving.mjs` records `codex.woven_at` at the weave's finish time (FX1-8), but `mastery()` and the profile counted `woven_at != null`, so a law's woven step showed while its weave was unfinished.
  - **Test first.** c9693432, alone: `server/test/fix_fx1_codex_woven.test.mjs`. Three of Motion's twelve steps are set in the Codex (half_gravity crossed, bounce at tier III and crossed), so the woven step is the fourth, the school's first title. It weaves half_gravity at tier I (10 minutes, §5.6) and reads `codex.show().mastery` and `profile.view().titles` at the start, at 9 minutes (3 steps, no title expected) and at 10 minutes (4 steps, one title expected). On main, with the wasm simulation built:
    ```
    not ok 1 - FX1-A-17, FX1-R25: a weave still unfinished is no mastery step in the Codex or the profile (18.5, 5.6)
      error: the Codex: the weave has just started   4 !== 3   (expected: 3, actual: 4)
    ```
    With the Codex's asserts taken out (a throwaway copy, not committed), the profile's half fails on main too: "the profile: the weave has just started", actual `{ school: 'Motion', steps: 4, titles: 1, total: 12 }`, expected none.
  - **Fix.** e6f582a5, naming FX1-A-17 and FX1-R25: `mastery(by, now)` counts the woven step only when `woven_at <= now`. `Codex.view()` passes `this.service.now()`; `Profile.view()` passes the `now` it already reads from the service's clock, the clock `weaving.mjs` uses. Crossed and tier-III steps are unchanged.
  - **Existing tests.** None changed, skipped or loosened. `cd server && npm test` at e6f582a5: 669 of 669, 0 skipped. `owners.py diff FX1-13-codex-woven-at origin/claude/videogame-project-analysis-ewkkk2 HEAD`: "every changed path is inside its files".
  - **Request FX1-R27 (to the lead):** `docs/security/audit-2026-11/server-a.md`'s FX1-A-17 entry still says "Left as is: while a weave is unfinished, `codex.mjs`'s `mastery()` and the profile still show its step ... (request FX1-R25)". It should say the residual is fixed (FX1-13-codex-woven-at, e6f582a5). Not in this task's files.
  - **Checks on the merge.** The fresh-container setup line and `bash client/build.sh` ran, then `cargo build --release --target wasm32-unknown-unknown` in `sim/` built the simulation the server tests need. Pre-check of a1eb8cfb: `state` PASS, "All checks passed.", `DONE exit=0`, finished 09:08:50Z, sandbox bwrap; recorded in the status file. `ready_sha` a1eb8cfb; `owners.py diff FX1-13-codex-woven-at <main> a1eb8cfb` passes. Main then moved to 27751cf5, adding only `CLAUDE.md` (the owner's order 6, effort) and lead bookkeeping, none of it in FX1-13's files.
  - **Next.** The lead merges FX1-13; then FX1-10-tools-contract once FX4-7-curation-swap-weave merges, in a fresh session.
- Last verified commit: a1eb8cfb (pre-check PASS 2026-11-24T09:08:50Z, sandbox bwrap), FX1-13's ready sha. Before it, dbf44adf (FX1-8, PASS 07:29:36Z).
- **FX1-8-server-a-lows (2026-11-24).** Branch `claude/fix-server-a`, with main 3b162939 merged (f96e2632) before the claim. The medium and low findings of FX1-6's audit that were outside FX1-6's files, the Renown pull-back over skipped seasons, and AUD-B-18's residual.
  - **Tests first.** e0ea0eab, alone: it turns the "today's behaviour" assertions of `fix_fx1_audit_server_a.test.mjs` (A-02, A-10, A-15, A-16, A-17) into the behaviour that should happen, adds `fix_fx1_server_a_lows.test.mjs` (A-13's republished defender, FX1-R10), and takes AUD-B-18's service proof in `fix_fx2_audit_config.test.mjs` out of `stillOpen` as a plain `assert.throws(..., RangeError)` over NaN, Infinity and a string. On main, with the wasm simulation built, each fails for its defect:
    ```
    not ok - FX1-A-02: an under-13 deletion keeps bytes another player's echo is (20.11)
      error: "FX1-A-02: B's echo X keeps its bytes"   (bundle(X) is null)
    not ok - FX1-A-10: an IPv4-mapped address written in hex or in full is keyed as its IPv4 address
      + ['0:0:0:0::/64', '0:0:0:0::/64', '0:0:0:0::/64']
      - ['198.51.100.7', '198.51.100.7', '203.0.113.1']
    not ok - FX1-A-15: the constellation league refuses an open season and no season, as result() does
      error: 'Missing expected exception: the season is still open'
    not ok - FX1-A-16: a link's number is never given again, so a retried DELETE takes down nothing more
      error: 'the new link has a number of its own'   expected: 4  actual: 4 (notEqual)
    not ok - FX1-A-17: a weave taken out before it finishes is no mastery step (18.5)
      expected: 0  actual: 1
    not ok - FX1-A-13: a raid on an island its owner republished before it settled is rated in the realm it was leased in (12.22)
      expected: 1  actual: 0
    not ok - FX1-R10: each season that ended pulls Renown halfway back once, in order (18.1)
      expected: 267  actual: 304
    not ok - AUD-B-18: a seasonStart that is not a finite time is refused when the service is made
      error: 'Missing expected exception (RangeError): seasonStart NaN'
    ```
  - **Fixes**, one commit each, naming its id:
    - 3e2e872f FX1-A-02: `accounts.mjs` `erase()` keeps bytes another player's snapshot is.
    - 9c25c35f FX1-A-10: `limits.mjs` `peerKey()` expands to eight groups (a dotted tail is two) and keys `::ffff:` addresses, in any form, as dotted IPv4.
    - 8180b333 FX1-A-13: `issue()` stores the realm on the lease (`leases.realm`, in `db.mjs`'s CREATE TABLE and `ADDED`); `grant()` rates in it, the interim pick kept only as the fallback for an older lease.
    - 2419848b FX1-A-15: `constellationTable()` refuses 404 `no_such_season` and 409 `season_still_open`, as `result()` does.
    - ad2bc945 FX1-A-16: `accounts.links_n`, a counter that only goes up; a link's number is one past it (or past the highest in use, for rows from before the column).
    - 991324a6 FX1-A-17: `weave()` records `codex.woven` at the weave's finish time; a weave taken out (unweave, or a swap) before it finishes takes its unearned step with it, or moves it to the soonest finish still in a slot.
    - 14807c73 FX1-R10: `pulledBack(account, last, season)` pulls halfway to the league's floor once for each season that ended since the last one played. `standing()` passes its season; `profile.mjs:50` and `matchmaking.mjs:307` use the default, the current season, which is the season they open.
    - bad2df32 AUD-B-18: the `Seasons` constructor throws a `RangeError` for a `seasonStart` that is not finite.
  - **A test whose expectation encoded the defect:** `server/test/codex.test.mjs:211` ("mastery"), which counted a weave taken out before it finished as the Motion step. It now asserts 0 steps after the cancelled weave, 1 once a weave has run its `WEAVE_MINUTES`, and still 1 after weaving again. The AUD-B-18 service proof in `fix_fx2_audit_config.test.mjs` left `stillOpen`, as its comment said it would on the fix. No test was skipped or loosened.
  - **Residual (FX1-R25):** while a weave is unfinished, `codex.mjs` `mastery()` and the profile still show its step, as they count `woven_at != null` without the time. Not this task's files; default: left as is.
  - **Docs.** `server-a.md`: the table and each fixed entry read "fixed (FX1-8-server-a-lows)", the Renown entry under Unproven records R10's answer and fix. `server-b.md`: AUD-B-18's residual fixed (FX1-8-server-a-lows).
  - **Privacy (FX1-R24, granted by the lead's cycle 173).** e46fd2a5, named FX1-R24: `server/privacy.json` declares `leases.realm` (`{"type": "gameplay"}`, after `universe`) and `accounts.links_n` (`gameplay`, after `terms_version`, holding the newest link's number, §5.3); `server/declarations.md` regenerated with `node --no-warnings server/src/privacy.mjs --write` (both columns join the Gameplay Content list). Both files are in FX1-8's `exceptions` on main.
  - **FX1-T-11 (FX1-R26).** `npm test` failed FX1-T-11's `stillOpen` once in this container, because no `.pyc` of `check_document.py` was cached: its SyntaxWarning (line 505) becomes the last output line and the proof's value is undefined. It passes once the cache exists. Not this task's files. The lead's cycle 172 answered the same ask (FX2-R4): `py()` parses stdout only, in FX1-9-tools-gate's `done_when`, so R26 needs nothing more.
  - **Main merged.** Main eb4b8e59 merged at 7a9084a2, then main 66b2943b (cycle 173) at 674b0778, both with no conflicts.
  - **Checks on the merge.** The fresh-container setup line and `bash client/build.sh` ran (exit 0), then `bash sim/run_spike.sh` built the wasm simulation. `cd server && npm test` at dbf44adf: 663 of 663. The first run failed only FX1-T-11's `stillOpen` ("FX1-T-11 no longer fails"), the environment issue of FX1-R26 (no cached `.pyc` of `check_document.py`); once `tools/__pycache__/check_document.cpython-313.pyc` existed, all 663 passed. `owners.py diff FX1-8-server-a-lows origin/claude/videogame-project-analysis-ewkkk2 dbf44adf`: "every changed path is inside its files".
  - **Pre-check.** At dbf44adf (main 66b2943b merged): `state` PASS, "All checks passed.", `DONE exit=0`, finished 07:29:36Z, sandbox bwrap; recorded in the status file. `ready_sha` dbf44adf. Main then moved to 70a0f58, adding only FX4-6 (`client/ext/`) and lead bookkeeping, none of it in FX1-8's files; the lead's candidate run covers the two together.
  - **Next.** The lead merges FX1-8; then FX1-9 onward as the backlog assigns them, in a fresh session.
- Last verified commit: dbf44adf (pre-check PASS 2026-11-24T07:29:36Z, sandbox bwrap), FX1-8's ready sha. Before it, b30765cd (FX1-7, PASS 04:46:34Z). Main 613f71c9 merged; main has since moved only under `docs/progress/` (to db0614f0).
- **FX1-7-audit-tools (2026-11-24).** Branch `claude/fix-server-a`, with main 613f71c9 merged at b30765cd. A read-only audit of `tools/` (outside `tools/vendor/`), the art scripts in `art/design/` and `art/ui/`, the client prototypes and the docs scripts, asking whether a check can pass when it should fail, or a tool corrupt a committed file. The findings, the latent ones, the unproven ones and the tools found sound are in `docs/security/audit-2026-11/tools.md`.
  - **Proofs.** Each confirmed finding has a proof in `server/test/fix_fx1_audit_tools_proofs.mjs`, run by `server/test/fix_fx1_audit_tools.test.mjs` under `stillOpen` with its id. A proof runs the tool on disk against a planted input in a temporary folder; a tool that writes is pointed at a copy, so nothing inside the repository is written. Each fails on main 613f71c9.
  - **Highest:** FX1-T-03 (High). `run_checks.sh record` copies `exit` 0 from a run `result` calls FAIL, and the protocol's reuse rule then skips the lead's own `check_all.sh`. Then T-20 and T-21 (Medium/High: the client contract misses nine server failure codes, none with an `ERR_` row, and every client call outside `client/data/`).
  - **Nothing fixed.** Every affected file is the lead's. Requests: FX1-R20 (gate and coordination tools), R21 (contract and status files), R22 (document checks), R23 (UI tools), each defaulting to one fix task per group after the open FX tasks, in priority order.
  - **T-22's note.** `python3 tools/build_stamp.py` (its `main()`) exits 1 on main today: a double-escaped `<code>` at `docs/audit/index.html:1583`, from `tools/audit_register.py:13556`. Fix the source before adding `main()` to the gate.
  - **Unproven:** the ink alpha in `measure.gd` and `colour_check` (needs Godot in the test run), `export_icons --groups` (needs playwright and the design sources), `sheet.py` `_hex`, and `owners.py changed()` with quoted paths (fails safe).
  - **Existing tests.** No existing test was changed, skipped or loosened.
  - **Checks.** `cd server && npm test` passes 653 of 653. The pre-check at b30765cd passed ("All checks passed.", `DONE exit=0`) and is recorded. `owners.py diff FX1-7-audit-tools origin/claude/videogame-project-analysis-ewkkk2 b30765cd` reports every changed path inside the task's files.
  - **Next.** FX1-8-server-a-lows, in a fresh session.
- **FX1-6-audit-server-a (2026-11-23).** Branch `claude/fix-server-a`, from main e2e8f5a1, with main ee42bb70 merged. The audit read the files the report did not (`service.mjs`, `matchmaking.mjs`, `holds.mjs`, `crossings.mjs`, `codex.mjs`, `workshop.mjs`, `fund.mjs`) and followed their calls into the modules they use. The findings, the unproven claims and the rejected ones are in `docs/security/audit-2026-11/server-a.md`.
  - **Tests first.** Every finding's test, in `server/test/fix_fx1_audit_server_a.test.mjs`, was committed before its fix (6b3556f9, 5d5d2e82, b0e4cd1c, f33ccc18), and each fails on main for its defect.
  - **Fixed in owned files:** A-01 (an echo with erased bytes broke every target list), A-03, A-04, A-05, A-06, A-08, A-11, A-12 and A-14. A-13 is fixed in part: the full fix needs a `leases.realm` column in `db.mjs` (FX1-R5).
  - **Marked, not fixed** (files this task does not own). Each test asserts today's behaviour, a comment marks it with the finding's id, and a request names the fix: A-02 `accounts.mjs` (R3), A-10 `limits.mjs` (R4), A-15 `seasons.mjs` (R6), A-16 `links.mjs` (R7) and A-17 `weaving.mjs` (R8). R8's fix also changes `server/test/codex.test.mjs:211`.
  - **Open, same as AUD-B-06:** A-07. Its fix in `matchmaking.mjs` `current()` was made, then reverted after main brought FX2's AUD-B-06 proof (`fix_fx2_audit_observatory.test.mjs:56`), whose stillOpen wrapper fails once the defect is fixed. That file is not this task's. A-07's proof now runs under the same `stillOpen`. R11 asks for one task that lands the fix and unwraps both proofs.
  - **Contested:** A-09, the `echoes` flag on a thin list with no echo. `server/test/generated.test.mjs:56` asserts today's behaviour, so the test asserts it too and R9 asks the lead (default: leave it).
  - **Unproven:** the Renown pull-back over skipped seasons (R10, default one pull-back), the 13-15 crew rule (owner decision B4, asserted by SR-14) and curated wards' origin. No tests.
  - **A-03's refusal** reuses `404 no_such_report`. A new `already_resolved` broke `tools/check_all.sh`'s client contract, because `client/i18n/strings.csv` is not this task's.
  - **Existing tests.** No existing test was changed, skipped or loosened.
  - **Checks.** `cd server && npm test` passes 631 of 631, and `bash tools/check_all.sh` passes. The pre-check at 01cb97ac passed and is recorded. `owners.py diff FX1-6-audit-server-a origin/claude/videogame-project-analysis-ewkkk2 01cb97ac` reports every changed path inside the task's files.
  - **Next.** FX1-7-audit-tools, in a fresh session.
- **FX1-4-holds-codex resync (2026-11-23).** The lead set `resync` because candidate ea551636 (FX1-4 with FX2-5-auth-lows) failed RB-36's test with `crew_mismatch` at `server/test/fix_fx1_holds_codex.test.mjs:98`. Cause: FX2-5's RB-25 fix makes `home.crewProblem` compare each manifest member's form byte with the character's. RB-36's test wrote manifests without `form`.
  - Main (79079d43, with FX2-5 at 5f1cc425) merged into the branch at 59b6c398. Only `docs/progress/status/FX1.json` conflicted, and it is FX1's own file.
  - 9fe151ad: RB-36's test manifest members now carry `form: c.wire.form`, as FX2-5 did in `setup.mjs`, `casts.test.mjs` and `rest.test.mjs`. No assertion changed and no source changed. Before that commit, on the merge, `node --test test/fix_fx1_holds_codex.test.mjs` gave pass 5, fail 1 (`crew_mismatch`). After it, `cd server && npm test` passes 586 of 586.
  - Fresh-container setup line and `bash client/build.sh` ran first (exit 0). The pre-check at 9fe151ad passed: "All checks passed.", `DONE exit=0`, sandbox bwrap. `owners.py diff FX1-4-holds-codex origin/claude/videogame-project-analysis-ewkkk2 9fe151ad` reports "every changed path is inside its files". Main then moved only in lead bookkeeping (5813e854, 719c4ff3, `docs/progress/**`), so the pre-check stands.
  - **Next.** FX1-6-audit-server-a, in a fresh session, once FX1-4 merges.
- FX1-4-holds-codex (2026-11-21). Branch `claude/fix-server-a`. The pre-check result and `ready_sha` are in `docs/progress/status/FX1.json`.
  - **Tests first.** The six tests in `server/test/fix_fx1_holds_codex.test.mjs` were committed alone at 924726b8. All six fail on main (b4125468's server code, with the wasm simulation built). Each fails for its defect:
    ```
    not ok 1 - RB-15: a hold measurement that throws is no measured figure, and a republish of its bundle keeps the default prior (13.3, SEC-20)
      no measured figure from a failed measurement
      + { held: 0, hold: 0, raids: 30, status: 'measured' }
      - null
    not ok 2 - RB-15: a hold measurement whose bytes are gone from the store is no measured figure (13.3)
      no measured figure without the island's bytes
      + { held: 0, hold: 0, raids: 30, status: 'measured' }
      - null
    not ok 3 - RB-18: a universe with no link rows is raided as a universe: its links are made at the lease (5.4)
      error: 'a universe digest, its missing links made'   (crossings.of returned null)
    not ok 4 - RB-36: five foiled friendly heists in one day, each casting a law, pay the defender at most one page of it (SEC-24, 7.6)
      error: 'dave got 5 bloom pages'
    not ok 5 - RB-53: studying a heist whose island was erased by an under-13 deletion is refused 409 nothing_to_study, not a 500 (7.6, 20.11)
      error: 'a 4xx refusal'   (thrown: TypeError: Cannot read properties of null (reading '4'))
    not ok 6 - RB-56: a player's report, after the player is deleted as under-13, is not shown as the server's, and its dismissal leaves the spike flag (18.7, 20.11)
      + [ [ 1, 'unfair', true ] ]
      - [ [ 1, 'unfair', false ] ]
    ```
  - **RB-15** (103d4176). As the report's Fix line says. A measurement that throws, or whose bundle's bytes are gone, is stored with `held = -1`, and `holds.status()` returns null for it. Curation then shows no hold, and a later republish of the bundle (`service.publish`) keeps the default prior. The SEC-20 test, which expects the row to be marked, finished and never picked again, still passes unchanged.
  - **RB-18** (1de6f966). As the report's Fix line says. `crossings.of()` checks only that the bundle is the defender's Heart, then runs `links.ensure` and `links.upkeep`, then plans. One consequence: `upkeep` now also runs at the lease of a Heart with no universe. It is the same read the owner's universe page makes.
  - **RB-36** (63f031ad). As the report's Fix line says. The defender's page for a law cast in a foiled heist also requires `friendPages`, which is true for every mode but a friendly heist after the pair's first of the UTC day. The test casts Bloom, not the report's Aurora, because Bloom is one of the three starting laws a raider holds without restoring.
  - **RB-53** (07047356). As the report's Fix line says. `codex.study` refuses `409 nothing_to_study` when the heist's bundle bytes are gone. That reason is already used in `study`, so the client already words it.
  - **RB-56** (b45dafe6). As the report's Fix line says. The queue's `server` flag, and the dismissal's check for an open server report (RB-39), now also require `reason = 'completion_spike'`. Only the server files that reason: it is not one of `REPORT_REASONS`.
  - **Left for FX1-6's audit** (not in FX1-4's Fix lines). The same unguarded `lawsOf(store.get(bundle))` read is at `server/src/codex.mjs:128` (`afterHeist`), `server/src/service.mjs:823` and `:853` (settlement), and `server/src/matchmaking.mjs:338`. Each throws if a bundle is erased between lease and submit.
  - **Existing tests.** No existing test was changed, skipped or loosened. `cd server && npm test` passes 578 of 578.
  - **Merge evidence.** Main (02558e05, lead bookkeeping) was merged at 2003cc38 with no conflict. `owners.py diff FX1-4-holds-codex origin/claude/videogame-project-analysis-ewkkk2 2003cc38` reports "every changed path is inside its files". The fresh-container setup line and `bash client/build.sh` ran first (exit 0). The pre-check at 2003cc38 passed ("All checks passed.", exit 0, 21:44:27Z, sandbox bwrap).
  - **Next.** FX1-6-audit-server-a, in a fresh session.

## Tried and failed
- 2026-11-21 Refused RB-30 with the report's new reason `taken_down`: the client contract needs every server reason worded in `client/i18n/strings.csv`, a file outside the task. Reused `island_withdrawn` instead.
- 2026-11-21 Ran the server tests before the wasm simulation was built: every service test fails with "ruleborn_sim.wasm is not built". `cargo build --release --target wasm32-unknown-unknown` in `sim/` builds it, and so does the pre-check.
- 2026-11-23 FX1-A-09: setting `echoes` only when an echo was among the candidates broke `server/test/generated.test.mjs:51` ("echoes first"), which this task does not own. Reverted; A-09 is contested (FX1-R9).
- 2026-11-23 FX1-A-03 refused with a new `409 already_resolved`: `tools/check_all.sh`'s client contract needs every server code worded in `client/i18n/strings.csv`. Reused `404 no_such_report` instead.
- 2026-11-24 FX1-A-07's fix in `current()` (533b793d), after merging main ee42bb70: FX2's AUD-B-06 wrapper (`fix_fx2_audit_observatory.test.mjs:56`) failed with "no longer fails: it is fixed", and that file is not this task's. Reverted the fix and filed FX1-R11.
