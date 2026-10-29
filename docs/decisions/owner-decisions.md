# Owner decisions, closed 2026-10-29

On 2026-10-29 the owner asked that nothing be left waiting on them and that
every open decision be closed. The lead closed each one below, taking the
asking agent's recommendation where it gave one and its stated default
otherwise. Where an option would have changed the design document, the lead
took the option that keeps it as written; the design document is not edited
here.

The UI wave's decisions D1–D14 are recorded in section 12 of
[`report.md`](../art/ui-quality/report.md), and the work order's D-01–D-14 in
[`agent-program.md`](../guides/agent-program.md). This page holds everything
else. "Build" means the decision needs code, listed under
[Build tasks](#build-tasks); "None" means nothing changes.

## Art (T3)

| Item | Decision | Build |
|---|---|---|
| The Heart's wall ring | Keep it, as T3's reading of §21.4's terraced citadel | None |
| The Vault's shape | §21.5's round domed strongbox, in the realm's roof colour | None |
| The back button (the kit's question) | The lowest row, beside the main action, as §21.1 asks | None |

## Sign-in (T11)

| Item | Decision | Build |
|---|---|---|
| Refresh-token rotation | Rotate only when the token is older than 24 hours (`RULEBORN_REFRESH_ROTATE_HOURS=24` in production), as T13 recommends; also write `used_at` and `place` only when they change by more than the devices list shows | B9 |
| Sessions rows in §24.1's write budget | Accepted; the current figure is the load model's (61.74 billed rows a day for an engaged player), see DB-7 | None |
| The client's certificate pin | Pin the certificate authority the production certificate chains to, never the leaf; set once the host below exists | B10 |
| Native Keychain, Keystore, Game Center and Google sign-in plugins | Deferred to release preparation, which needs a machine with Xcode 16 and Android SDK 35; the stand-ins stay until then. The Android store uses a Keystore AES-GCM key, not EncryptedSharedPreferences | Later |
| The devices list's country | Kept, declared to both stores as approximate location | None |

## Security fixes (T12, `docs/security/review.md`)

| Item | Decision | Build |
|---|---|---|
| SR-09 Raw ratings on public target lists | Drop `rating` and `deviation`; the patch is redone against today's `service.mjs` | B1 |
| SR-10 A minor's receipt without purchase intent past the month's cap | Refuse it | B2 |
| SR-12 One player's time on one island for the Island Fund | At most one hour a quarter (`ONE_PLAYER_ONE_ISLAND_S = 3600`), uncleared plays included | B3 |
| SR-14 Who may join a crew | A friend or constellation-mate of one member; for a player aged 13 to 15, a friend of every member | B4 |
| SR-15 An island's exposed loot until D60 is built | Clamp to 750, §9.6's median richness | B5 |
| SR-16 Laws the realm has not woven | Refuse them now; guards (G60) after | B6 |
| A storage quota for realm snapshots | Not now; revisit with the production host's storage limits | None |
| Workshop plays' life | A lease's one-day life; `expireLapsed` deletes unsubmitted plays | B7 |

## Database cost (T13, `docs/server/db-cost.md`)

| Item | Decision | Build |
|---|---|---|
| DB-1 The Observatory (raid list) | Serve it from the hourly target lists; a new island appears within the hour | B8 |
| DB-2 Glicko rating period | Keep one heist (§12.22 as written) | None |
| DB-3 Counting heists | Keep the telemetry event (§24.3 and §20.5 as written) | None |
| DB-4 The raid notification | List the day's raids by reference | B8 |
| DB-5 AUTOINCREMENT on append-only tables | Keep until the edge run shows whether `sqlite_sequence` is billed; drop it then if it is | Later |
| DB-6 The `event_batches_by_day` index | Keep | None |
| DB-7 §24.1's five-writes target | Accept about 62 billed rows a day for an engaged player for now; folding heists into one row is revisited at scale | None |

## Documentation (T15, `docs/DOCS-CHANGES.md`)

| Item | Decision | Build |
|---|---|---|
| Q1 Deploys and integration branches | Each deploy is one fast-forward of the main branch from a scratch integration branch (`intNN`) after `check_all` passes; the scratch branches are not kept, and nothing else happens to main after a merge | None |
| Q2 The production server | Cloudflare Workers with D1, which the cost work already assumes | None |
| Q3 T16's branch | Already recorded (`claude/ui-plan`) | None |
| Q4 Owners of single-commit files | Confirmed as `docs/README.md` infers them | None |
| Q5 D64 used twice | The season track's unbuilt part keeps D64 (first use); family approval takes the next free D number | B11 |
| Q6 Overlapping ownership | Already settled in `agent-program.md`: the lead names one owner | None |
| Q7 Renaming track notes | Keep the names, with the map | None |
| Q8 T2 Look | Closed | None |
| Q9 `fe-base.log` | Removed, and `*.log` ignored (commit 618480ce) | None |
| Q10 Reduced motion still flashes the screen edge | A defect: fix it, including Harmony's preview flashing twice a second | B12 |
| Q11 SR-09's patch | Redone, see SR-09 | B1 |

## Operating model (T17)

| Item | Decision | Build |
|---|---|---|
| G-67 Nobody notices a dead lead | A separate scheduled task checks the lead's last status commit every hour while a wave has agents building, and alerts in [`owner-inbox.md`](../progress/owner-inbox.md); the coordinator script (BT-01) takes this over later | Wave launch |
| G-70 A prompt whose deadline has passed | The lead checks `stop_at` against the clock before starting or messaging a session | None |

## Validation

| Item | Decision | Build |
|---|---|---|
| §25.4's ten testers (`docs/design/spec/validation.md`) | Not recruited yet; recruiting them is a task before soft launch | Later |

## Build tasks

These go to the next wave's backlog. Each keeps its tests: the six security
tests pinned in `server/test/security_owner.test.mjs` change from "needs the
owner" to the decided behaviour.

| Task | What | Files |
|---|---|---|
| B1 | SR-09: drop `rating` and `deviation` from target lists | `server/src/service.mjs`, `server/test/matchmaking.test.mjs` |
| B2 | SR-10: refuse the receipt | `server/src/shop.mjs` |
| B3 | SR-12: the Island Fund cap | `server/src/fund.mjs` |
| B4 | SR-14: the crew rule | `server/src/social.mjs`, `server/test/seasons.test.mjs` |
| B5 | SR-15: clamp exposed loot | `server/src/service.mjs` |
| B6 | SR-16: refuse unwoven laws | `server/src/service.mjs`, `server/src/universe.mjs`, `server/test/setup.mjs`, `client/tests/share_tests.gd` |
| B7 | Workshop plays' lease | `server/src/service.mjs`, the privacy register |
| B8 | DB-1 and DB-4 | the Observatory and notification paths in `server/src/` |
| B9 | Refresh rotation and skipped writes | `server/src/auth*.mjs`, `docs/guides/server.md` |
| B10 | The certificate pin | `ruleborn/tls_pins`, `client/data/http_transport.gd` |
| B11 | Renumber family approval | `server/README.md`, `tools/audit_register.py` |
| B12 | Reduced motion | `client/world/fx_anchors.gd`, `client/world/law_fx_harmony.gd`, the client README |
