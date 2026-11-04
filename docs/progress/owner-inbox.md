# Owner inbox

Alerts and questions for the owner, newest first. The lead also sends each one
as a direct message (work-order decision D-03). An entry is closed by
recording the answer under it.

## 2026-11-04 21:58Z: the catalogue back to K1 a second time (lead, cycle 42)

- **What:** P1-K1-catalogue's candidate `aa1ab0b0` (main + `71562ab1`)
  failed check_all, 391 of 392: the catalogue coverage test finds kit-3's
  twelve numerals (`num_gold_*`, merged after K1's resync) with art but no
  component in SKINS_OF. The task is back at `resync` and K1 was
  restarted to add them. Every kit batch that merges before the catalogue
  breaks it the same way.
- **Default (no answer needed):** the lead merges the catalogue before
  P1-AIA-kit-4. After that, a kit batch whose skins are not yet in
  SKINS_OF fails the same test; the lead then grants the batch the
  SKINS_OF lines in `client/tests/shots/ui_kit_catalogue.gd` as a merge
  exception, or sends it to K1. The test is not loosened.

## 2026-11-04 21:40Z: a stray `main` branch on GitHub (lead, cycle 41)

- **What:** a lead push by mistake created a remote branch named `main`
  at `2455f3b5`. The program's main is
  `claude/videogame-project-analysis-ewkkk2`, which has every commit on
  it. The lead's attempt to delete the stray branch was refused by its
  permission check.
- **Default (no answer needed):** sessions are started on the real main
  by name. To clean up, delete the branch:
  `git push origin --delete main`.

## 2026-11-04 21:12Z: kit-3 gate verdicts, advisory; icons-1b back to its builder (lead, cycle 41)

- **What:** the gate judged P1-AIA-kit-3 (`3a04e828`, the numerals sheet
  at phone size, 100% and 200% text); verdicts are in
  `docs/art/ui-quality/gate/verdicts/P1-AIA-kit-3/3a04e828.json`. Display
  type and Colour roles and value pass 3 of 3. AIA-R15 (the numerals'
  route) is open with its default.
  - P1-AIA2-icons-1b's merge candidate failed guard.sh:
    `client/ui/art/icons_48_hc.webp` is not what its sources bake to (main's
    icons rebake byte for byte, so the stale file is on AIA-2's branch). The
    task is back at `resync`, and AIA-2 was restarted to rebake and mark it
    ready again.
- **Default (no answer needed):** kit-3 merges if check_all and guard.sh
  pass. icons-1b merges once AIA-2 marks it ready again; its gate verdicts
  still stand.

## 2026-11-04 19:45Z: icons-1b gate verdicts, advisory (lead, cycle 40)

- **What:** the gate judged P1-AIA2-icons-1b (`bef6eac2`, the six batch 1b
  currency icons at 48 and 96 pt and in grayscale); verdicts are in
  `docs/art/ui-quality/gate/verdicts/P1-AIA2-icons-1b/bef6eac2.json`.
  Layered materials, Painted or rendered icons, Colour roles and value, and
  Light behind UI pass 3 of 3. Icons-1a's failures (flat fills with decals,
  hue-only shapes, role colours used out of role) do not recur.
- **Default (no answer needed):** AIA-2 marks icons-1b ready. AIA2-R2's
  default applies: insight stays dropped from list.md, and batch 1b closes
  at six icons.

## 2026-11-04 18:47Z: kit-2 gate verdicts, advisory (lead, cycle 39)

- **What:** the gate judged P1-AIA-kit-2 (`fccd4b89`, kit art batch 1b);
  verdicts are in
  `docs/art/ui-quality/gate/verdicts/P1-AIA-kit-2/fccd4b89.json`.
  Layered materials, Colour roles and value, and Light behind UI pass 3 of
  3; kit-1's Colour roles notes (sand-gold second family, teal focus) do not
  recur.
  - Display type came back unknown 3 of 3: the batch 1b pieces carry no
    words, so there is no type to judge. It sits in the exceptions queue and
    counts as a split after 2026-11-05 18:47Z. P1-AIA-kit-3's numerals sheet
    is where Display type is first judged on kit art.
- **Default (no answer needed):** kit-2 merges behind its family switch
  (report.md 3.8 item 5) and AIA starts P1-AIA-kit-3.

## 2026-11-04 15:51Z: first phase 1 gate verdicts, advisory (lead, cycle 37)

- **What:** the gate judged P1-AIA-kit-1 (`c8915bc3`) and P1-AIA2-icons-1a
  (`c1d14d38`); verdicts are in `docs/art/ui-quality/gate/verdicts/`. Every
  quality is owner-checked since cycle 25, so the judge is advice and AD
  checks each quality on its boards.
  - Kit-1: Layered materials and Light pass; Colour roles fails (a sand-gold
    second button family, a danger button whose focus turns teal).
  - Display type on kit-1 came back unknown 3 of 3: the plates are blank, so
    there is no type to judge. It sits in the exceptions queue and counts as
    a split after 2026-11-05 15:46Z.
  - Icons-1a: Light passes; Layered materials, Painted icons and Colour roles
    fail (flat fills with sparkle decals; sagewheel wedges differ by hue
    alone; red, green and gold used outside their roles).
- **Default (no answer needed):** kit-1 merges behind its family switch
  (report.md 3.8 item 5); its Colour roles note goes to AIA for kit-2 and to
  AD's board 1. AIA-2 gets the icon critiques before icons-1a is ready.

## 2026-11-04 14:13Z: watchdog alert, lead past its update time while a merge lock is held

- **What was stale:** `status/lead.json` expected an update by 2026-11-04T13:59:30Z (last update 13:42:42Z). The launcher is healthy: last run SUCCEEDED at 13:39Z.
- **What the watchdog did:** started no session. The "Latest lead cycle session:" in `lead.md` (`session_01SNkKxofbM8PTQZdFF13dEe`, cycle 35) is completed. But a cycle 36 lead, which `lead.md` doesn't list, committed at 13:48Z and holds the merge lock on `P0-K1-kitspec-3` and `P1-AIA2-toon-route` until 14:42Z. A second lead started now could merge to main at the same time, so the watchdog did not start one (as on 2026-10-31 00:10Z). The launcher's next run (14:38Z) also checks the session it last created, so it should skip while cycle 36 is still working.
- **To fix:** the lead should record its session in `lead.md`'s "Latest lead cycle session:" line when its cycle starts, and set `expected_next_update_by` later than its merge lock's `expires_at`. Here it was 13:59:30Z, against a lock until 14:42:42Z. If cycle 36 has stopped, the next watchdog firing (16:08Z) starts a cycle once the lock has expired.
- **Resolved (lead, cycle 36, 14:39):** the cycle 36 lead (`session_01SNkKxrLqp81CeCToVADsyb`) was still working: check_all on the candidate ran 51 minutes (13:47Z to 14:38Z). It merged P0-K1-kitspec-3 and P1-AIA2-toon-route as `9b2bde70`, cleared the lock and recorded itself in `lead.md`. From now on the lead records itself and sets `expected_next_update_by` past its lock when it takes the lock.

## 2026-11-04 12:45Z: phase 1 started (lead, cycle 35)

- **What:** under your order of 4 November ("Continue working until I tell
  you to stop"), phase 1 is seeded (18 tasks, icon batches 3 and 4
  deferred) with `stop_at` 9 November 21:00Z, and three builders run: K1
  (kit spec, then the kit atlas), AIA (kit art) and the new icon artist
  AIA-2. The new screens agent S1 starts when its deps merge and a builder
  slot is free. Fable 5.1 is used nowhere.
- **Default (no answer needed):** the lead keeps building until you say
  stop.

## 2026-11-04 04:40Z: the usage projection does not fit (lead, cycle 27)

- **What:** phase 0's last exit criterion, the usage projection, is made:
  [`usage-projection.md`](usage-projection.md). The seven-day bar reads
  `allowed_warning` (reset 9 November 17:00Z); phase 0 used about one
  weekly bar, and phases 1 to 3 need about four more. D13's answer (c)
  applies: three builders at once, icon batches 3 and 4 deferred.
- **Also:** the wave's `stop_at` (6 November 21:00Z) falls before the
  reset, so phase 1 cannot start inside it while the bar is in warning.
- **Default (no answer needed):** phase 0 is closed; the lead starts no new
  building session until the reset, then seeds phase 1 and sets a new
  `stop_at` for it.

## 2026-11-04 01:58Z: C74, C75 and M1 closed

- **What:** the owner asked that everything waiting on them be solved.
- **C74 and C75:** closed as A/A, the recommendations, under the
  2026-10-29 rule; recorded in [`owner-decisions.md`](../decisions/owner-decisions.md#ui-kit-colours-c74-c75-closed-2026-11-04).
  The follow-up is K1-R9 in [`requests.md`](requests.md).
- **M1:** AIA acknowledged it at 01:34Z (`fd2620f2` on `claude/ui-artist`);
  the lead copies the ack at its next cycle.
- **Left for the owner, no deadline:** §21.8's sentence "success words keep
  #3FBF7F" now differs from C74's answer; only the owner edits the design
  document.

## 2026-11-03 06:10Z: watchdog alert, lead past its update time

- **What was stale:** `status/lead.json` expected an update by 2026-11-03T02:56:00Z. Its last update was at 01:41Z (cycle 19, `28c8bfea`), and nothing has been committed since. The launcher reports SUCCEEDED for its last run (05:38Z), yet no lead cycle has run since 01:41Z. The launcher session may be skipping or failing to create sessions; worth checking.
- **Latest recorded lead:** `session_01SNkKxpMi6cZ8M6M33w8ntT` (cycle 19) is completed, not working.
- **What the watchdog did:** started `session_01SNkKxo6TYzdUtAL4USoPyt` ("Ruleborn lead cycle 2026-11-03 06:11 UTC (watchdog)").
- **Note:** the 02:08Z and 04:08Z watchdog firings were delivered late, at 06:10Z, which is why this alert comes about 3 hours after the lead went stale.
- **Cause (lead, 06:20Z):** the account hit its five-hour usage limit (it reset at 05:40Z). The launcher session's last turn failed with "You've hit your 5-hour limit", so its 02:38Z to 05:38Z firings created no cycle, although the scheduled task records each delivery as SUCCEEDED. Nothing was lost: the dev-fable gate run kept working and is at about 304 of 414 verdicts.
- **Resolved (lead, 06:20Z):** cycle 20 (`session_01SNkKxo6TYzdUtAL4USoPyt`) ran. The launcher should start cycle 21 at 06:38Z on its own. No action for the owner.

## 2026-10-31 20:55Z: program paused by the owner

- **What:** the owner asked to stop the program cleanly. The launcher
  (`trig_01DgVGTTmwREAb7sHz8oQkiP`) and the watchdog
  (`trig_015Lgi2ZssXBXPbzkCYqoKmL`) scheduled tasks are disabled, not
  deleted. `expected_next_update_by` in `status/lead.json` is set to null,
  which the watchdog reads as stopped on purpose. Main is at `2c6a82c5`
  (lead cycle 17's handoff); nothing was left unpushed. No task was open
  and startable: the remaining phase 0 gate runs wait for the 2 November
  17:00Z usage reset.
- **To resume:** re-enable both scheduled tasks. The next lead cycle sets
  `expected_next_update_by` again.
- **Still open for the owner:** C74 and C75 need "A/A"; message M1 to AIA
  is past its `ack_by`.
- **Answer (2026-11-02 22:59Z):** the owner resumed the program after the
  2 November 17:00Z usage reset. Both scheduled tasks are re-enabled, the
  launcher was fired once by hand to start a lead cycle now, and
  `expected_next_update_by` is set to 2026-11-03 00:15Z (now + 75 min) so
  the watchdog watches the lead again.

## 2026-10-31 10:05Z: ready work waiting over 2 hours, and a lead container without the build tools (lead, cycle 8)

- **What:** O2-2 (a392bcb, ready 06:37Z) and P0-AIA-keyframes-1
  (b760d6f1, ready 06:26Z) waited over 3 hours behind SV-B11-B12. Cycle 8
  merged them as one batch candidate, `fafc1a13`, with AIA-R3's two
  `check_all.sh` lines.
- **Also:** this cycle's container (`session_01SNkKxnfFjzxesNmoxjhm96`)
  was missing what the README's quick start installs: the Rust targets
  `wasm32-unknown-unknown`, `aarch64-linux-android` and
  `aarch64-apple-ios`, `gdlint` (gdtoolkit 4) and the Python `playwright`
  package. It also had no client build in the checkout. The first two
  check runs failed on those, not on the change. Once they were installed,
  a full run took about 55 minutes, so the merge lock was renewed once,
  to 10:45Z. If the environment's setup script installs them, every lead
  cycle saves that time.
- **Action:** none needed; optionally add the README's quick-start
  installs to the environment's setup script.

## 2026-10-31 07:45Z: ready work waiting over 2 hours (lead, cycle 7)

- **What:** SV-B11-B12 has been ready since 04:45Z. It is in the merge
  queue now: cycle 6 (`session_01SNkKxmymBxL2H7jxeLAz9D`) holds the merge
  lock on its candidate `14c30355` until 08:20Z. Behind it are O2-2
  (a392bcb, ready 06:37Z) and P0-AIA-keyframes-1 (b760d6f1, ready
  06:26Z). P0-K1-kitskin merged at about 07:20Z.
- **Also:** the launcher started cycle 7 at 07:38Z while cycle 6 was
  still waiting on its checks. Cycle 7 did only the bookkeeping, as the
  lock requires.
- **Action:** none for the owner.

## 2026-10-31 03:45Z: ready work waiting over 2 hours (lead, cycle 5)

- **What:** P0-K1-bake-2 has been ready since 01:22Z. It is in the merge
  queue now: cycle 4 (`session_01SNkKxrCAg6Y8R7Hovb2PPH`) holds the merge
  lock on its candidate `48e0d156` until 04:37Z and is re-running
  `guard.sh`. Behind it, three more are ready: P0-K1-contract-2 (36b797fd),
  P0-AD-golden (7d8c4ed6) and P0-AIA-board-3 (e09807f3). The queue is slow
  because full checks run one at a time (`flaky.md`, BT-10).
- **Also:** the launcher started cycle 5 at 03:38Z while cycle 4 was still
  working (its session reads idle between turns). Cycle 5 did only the
  bookkeeping, as the lock requires, so nothing merged twice.
- **Action:** none for the owner; the next cycle without a lock takes the
  queue.

## 2026-10-31 00:10Z: watchdog alert, lead past its update time

- **What was stale:** `status/lead.json` expected an update by 2026-10-31T00:00:00Z (last update 2026-10-30T23:58Z). The launcher is healthy: last run SUCCEEDED at 2026-10-30T23:38Z.
- **What the watchdog did:** started no session. The "Latest lead cycle session:" in `lead.md` (`session_01SNkKxpgxycAoWLmMgaYf2V`, cycle 2) is review_ready. But a cycle 3 lead, which `lead.md` doesn't list, committed at 23:57:59Z and holds the merge lock on candidate `fd2c9662` until 00:58Z. A second lead started now could merge to main at the same time, so the watchdog did not start one.
- **To fix:** the cycle 3 lead should record its session in `lead.md`'s "Latest lead cycle session:" line and keep `expected_next_update_by` ahead of its merge lock. If that lead has stopped, the launcher (next run 00:38Z) or the next watchdog firing (02:08Z) starts a new cycle once the lock expires.
- **Resolved (lead, 00:31Z):** the cycle 3 lead (`session_01SNkKxnFBPxodvMYivAg4oB`) recorded itself in `lead.md` and moved `expected_next_update_by` past its merge lock. It finished at 01:45Z with four tasks merged and the lock cleared.

Nothing is open. Every decision open on 2026-10-29 was closed that day; see
[`owner-decisions.md`](../decisions/owner-decisions.md).
