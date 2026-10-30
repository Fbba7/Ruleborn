# SV server decisions: progress

- Status: Green on the server tests (486 of 486, `python3 server/status.py`); the pre-check for SV-B7-B9 is running at 85a6c76.
- Progress: 1 of 3 tasks merged (SV-B1-B6); SV-B7-B9 built, awaiting its pre-check.
- Done: B7 (workshop plays lapse after a day), B8 (DB-1 Observatory and offer from the hourly lists, DB-4 raids listed by reference), B9 (refresh rotates daily by default).
- Next: SV-B11-B12 once SV-B7-B9 merges.
- Blocked by: none.
- Owner decision needed: none.

| Deliverable | Weight (h) | Status | Evidence |
|---|---:|---|---|
| SV-B1-B6 | 4 | merged | `server/test/security_owner.test.mjs` |
| SV-B7-B9 | 4 | working | `workshop.test.mjs` (B7), `observatory.test.mjs`, `security_limits.test.mjs`, `notifications.test.mjs` (B8), `auth_devices.test.mjs` (B9) |
| SV-B11-B12 | 3 | open (dep SV-B7-B9) | |

## Handoff
- Last verified commit: 85a6c76 (server tests 486 of 486; pre-check pending)
- Done: B7 `expireLapsed` also deletes Workshop plays unsubmitted a day after issue (`plays` in its result; `server/privacy.json` `workshop_plays` keep is 1 day, declarations regenerated). B8 `matchmaking.listed` serves the Observatory and `/v1/offer` from candidates made with the hourly target lists (`relist` in `targetLists`; `LISTED_MS` one hour), `matchmaking.current` brings the few shown cards up to date (banned or deleted owner out, republished island's card swapped). A raid notification writes once for the first raid and stores `since`; later real raids write nothing and `Notifications.raids` reads them from `heists_by_defender` at send. B9 `rotateHoursOf` in `auth.mjs` defaults `RULEBORN_REFRESH_ROTATE_HOURS` to 24; inside the span a refresh writes nothing (already so).
- Changed expectations (decided behaviour, not regressions): `privacy.test.mjs` `expireLapsed` results gain `plays: 0`; `security_limits.test.mjs` SR-03 now expects the offer's candidates made again after an hour, not a minute.
- `server/load.json` (a file outside this task's list) is regenerated: B8's DB-4 removes 4 written rows a day, so the model reads 57.74 billed rows a day engaged (was 61.74). Request SV-1 to the lead covers it; `docs/decisions/owner-decisions.md` still quotes 61.74.
- Next step: record the pre-check, run `python3 client/status.py` (Godot may be missing here), mark ready.

## Tried and failed
- 2026-10-30 `candidates()` still serving the Observatory with a longer window: SR-03's test pins a minute and DB-1 asks for the hour, so a second hourly cache replaced it.
- 2026-10-30 first pre-check: failed the client contract (no string for the new crew refusal); fixed by answering `not_friends`. Second: gdlint missing in the container; installed per the brief.
- 2026-10-30 `node --test test/` (a directory): fails to load; the package script `node --test test/*.test.mjs` is the way.
