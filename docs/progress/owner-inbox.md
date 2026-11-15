# Owner inbox

Alerts and questions for the owner, newest first. The lead also sends each one
as a direct message (work-order decision D-03). An entry is closed by
recording the answer under it.

## 2026-11-15 20:09Z: the lead was past its update time, cycle 86 still working (watchdog)

- **What:** `status/lead.json` was past its `expected_next_update_by` of
  19:58:10Z when checked at 20:09Z (last update 19:46Z; it holds the merge
  lock for P2-S3-settings until 20:46Z). The launcher had not failed: it
  is enabled and its last run succeeded at 19:39Z.
- **Done:** started no session. The "Latest lead cycle session" line in
  `lead.md` still names cycle 85 (`session_01SNkKxqLYw4qY5UxycWNhTR`, now
  idle). Commit `19e936c` names cycle 86's session,
  `session_01SNkKxnnyaLSgG88hAKxd5z` (created 19:39Z by the launcher),
  and that session is still working: check_all is running on the S3
  candidate. Starting a second lead would have clashed with its merge.
- **Needs the owner:** nothing.

## 2026-11-13 10:12Z: the lead was just past its update time, cycle 81 still working (watchdog)

- **What:** `status/lead.json` was past its `expected_next_update_by` of
  10:12Z by a few seconds when checked at 10:12:16Z (last update 09:46Z,
  cycle 81). The launcher had not failed: it is enabled and its last run
  succeeded at 09:38Z.
- **Done:** started no session. The latest lead cycle session on record
  (`session_01SNkKxmrBHkRN8tALzCsGkF`, cycle 81, created 09:38Z) is still
  working: it reports guard.sh passed and check_all running.
- **Needs the owner:** nothing.

## 2026-11-12 05:42Z: main failed check_all after the overseer's security commits; fixed (lead, cycle 60)

- **What:** main had failed `tools/check_all.sh` since the overseer's
  security commits `c888bed7` (SEC-17) and `e39e9048` (SEC-30/SEC-29).
  There were three breakages: a sim test not claimed in
  `sim/systems.json`, the failure code `ERR_BAD_ROUTE` with no words in
  `client/i18n/strings.csv`, and two gdlint errors (an unused variable's
  name in `client/features/auth/auth_controller.gd`, a line over 120 in
  `client/tests/security_tests.gd`). Each blocked a merge candidate in
  turn.
- **Done:** fixed by lead commits `22d4328c`, `77e48b27` and `a13c5d07`,
  with no test loosened. check_all then passed and P1-S1-pilot-3 merged
  as `085c812a`.
- **Needs the owner:** nothing. Security fixes landing on main would
  merge more smoothly if they ran `bash tools/check_all.sh` first.

## 2026-11-12 00:41Z: the lead was stale, the launcher had just started a cycle (watchdog)

- **What:** `status/lead.json` was past its `expected_next_update_by` of
  23:34Z (last update 22:19Z, cycle 55). The launcher had not failed: it
  is enabled and its last run succeeded at 00:38Z. The latest lead cycle
  session on record (`session_01SNkKxnNomdRK7U7hfS4cvz`, cycle 55) has
  completed. The watchdog's own firing of 00:09Z reached its session only
  at 00:40Z.
- **Done:** started no session. At 00:40Z the launcher's session
  (`session_01SNkKxoNHJW6nWHDeA8Mfth`) reported "lead cycle 56 launched".
  A second cycle from the watchdog would only duplicate it, as with the
  duplicate cycles 47 and 52.
- **Needs the owner:** nothing.

## 2026-11-11 05:21Z: the lead was stale, a lead cycle is started (watchdog)

- **What:** `status/lead.json` was past its `expected_next_update_by` of
  02:35Z (last update 01:20Z, cycle 51). The launcher itself had not
  failed: it is enabled and its last run succeeded at 04:38Z, yet no
  lead cycle has written to main since 01:15Z. The latest lead cycle
  session on record (`session_01SNkKxnDPjsoJBxjS6oA73p`, cycle 51) is
  idle.
- **Done:** started a lead cycle on Fable 5.2,
  `session_01SNkKxnH8TzJqFh4YN5MvvE`.
- **Needs the owner:** nothing.
- **Follow-up, 05:25Z (the watchdog's cycle session):** the launcher
  started a cycle session of its own five seconds earlier, at 05:20:21Z
  (`session_01SNkKxrATVfECHBXAWskbLg`, working). The lead was stale
  because every session stood still from about 01:16Z to 05:20Z; the
  launcher's four late firings arrived together at 05:20Z. That session
  runs cycle 52. This one (`session_01SNkKxnH8TzJqFh4YN5MvvE`) stands
  down so two leads do not gate, merge and start sessions at once, as
  with cycle 47's duplicate: it merges nothing and starts no session.
  It looks once more at about 05:45Z and runs the cycle only if the
  launcher's session has stopped without writing cycle 52.

## 2026-11-11 01:20Z: three builders working after the restart, two K1 tasks seeded (lead, cycle 51)

- **What:** the first cycle after the restart found nothing to gate or
  merge. Tasks done: 46 of 63.
- **Done:** seeded two K1 tasks: P1-K1-disc-host (the disc drawn as wide
  as its host under the currency pills, pages 27, 44 and 45, with a test
  that fails before the fix) and P1-K1-heist-kit (the kit work S1 asked
  for, S1-R1 to S1-R6). Started three fresh Fable 5.2 sessions: AIA on
  P1-AIA-kit-7, K1 on P1-K1-disc-host and S1 on P1-S1-pilot-2.
- **Needs the owner:** nothing.

## 2026-11-11 01:15Z: the program is restarted on the owner's word (overseer)

- **What:** the owner said, in the overseer session's chat, "We still need
  to keep the UI process we were doing with the phases running as it was",
  then "Make sure it is running now". CLAUDE.md order 1 now says the
  program runs, on Fable 5.2 only (order 4).
- **What ran since the stop:** nothing. The last work of the program is
  the lead's write-up of 10 November, 10:34Z (`8f03235f`). From then until
  this restart every scheduled task was disabled and no session worked.
  Main moved only by two commits of the overseer (`312b1a12`, `1c6aa12a`,
  10 November 19:36Z): a handoff note on the disc drawing fault.
- **Done:** a new launcher (hourly) and a new watchdog (two-hourly) are
  created after this commit is on main; their IDs go in `lead.md`. The
  first cycle after the restart is cycle 51: AIA on P1-AIA-kit-7, S1 on
  P1-S1-pilot-2, and K1 on the disc drawn under the currency pills.
- **Needs the owner:** nothing.

## 2026-11-10 02:55Z: two merges, kit-5's colour roles failed the gate, three builders working (lead, cycle 47)

- **What:** P1-AIA2-icons-2a and P1-AIA-kit-5 are merged (`027379a2`):
  check_all PASS and ui guard OK on the candidate, and the icon sheets now
  rebake byte for byte from one container to another. Tasks done: 12 of
  19.
- **Gate (advisory):** icons-2a passes 12 of 12. kit-5 passes three
  qualities and fails "Colour roles and value" 3 of 3: the gold fill of
  the main action is also used for selected segments and chips, claimed
  day tiles and a chart bar, and selection is told by hue alone. The gate
  is advisory, so kit-5 merged; the fix is the new task P1-AIA-kit-6.
- **Done:** three fresh Fable 5.2 sessions: AIA on kit-6, AIA-2 on
  icons-2b, K1 to finish P1-K1-switch-heist (it was blocked only on the
  icon rebake). That is the cap of three UI builders.
- **Also:** the watchdog and the launcher each started a cycle at 01:51Z;
  the second session did no work, and nothing merged twice.
- **Needs the owner:** nothing.

## 2026-11-10 01:51Z: lead was stale, watchdog started a cycle (watchdog)

- **What:** `lead.json` was past its `expected_next_update_by` of
  2026-11-10 00:10Z (last update 2026-11-09 22:55Z, cycle 46). The
  launcher's last run succeeded at 01:38Z, but its session reads a
  five-hour usage limit as rejected, which is the likely reason no cycle
  ran after 22:39Z. The latest lead cycle session
  (`session_01SNkKxoVXNfpAABNM81P62e`) had completed.
- **Done:** started `session_01SNkKxqgeutvzGq4AWJLbqG` ("Ruleborn lead
  cycle 2026-11-10 01:51 UTC (watchdog)") on Fable 5.2.
- **Needs the owner:** nothing.

## 2026-11-09 22:30Z: two merges, icons-2a back to AIA-2, three builders working (lead, cycle 45)

- **What:** the first lead cycle since the restart, on Fable 5.2.
  P1-AIA-kit-4 (`d2deb896`) and P1-K1-words (`68cfd4e4`) are merged:
  check_all PASS and ui guard OK on the candidate. Tasks done: 10 of 18.
- **Not merged:** P1-AIA2-icons-2a. Its gate passes (12 of 12, advisory),
  but with it the guard's rebake of `icons_48_hc.webp` differs from the
  committed file: the icon finish draws differently from one container to
  another. It went back to AIA-2 as a resync to make the outline grow
  computed on pixels.
- **Done:** three fresh Fable 5.2 sessions: AIA-2 on icons-2a, AIA on
  P1-AIA-kit-5, K1 on P1-K1-switch-heist. That is the cap of three UI
  builders. The audit and roadmap pages are republished.
- **Needs the owner:** nothing.

## 2026-11-09 21:05Z: restarted on Fable 5.2 only (overseer, on the owner's word)

- **What:** the owner said "Let's continue and use only Fable 5.2" in the
  overseer's chat. CLAUDE.md order 1 now says the program runs; the new
  order 4 says every session, subagent and judge runs on Fable 5.2 and on
  no other model. Fable 5.1 stays banned (order 2).
- **Done:** a new launcher (hourly at :38) and a new watchdog (every 2
  hours at :08), each firing into a new Fable 5.2 session. The old
  launcher, watchdog and check-in stay disabled. The backlog's roster and
  every task not yet merged name Fable 5.2.
- **Corrected at 21:36Z:** the first launcher and watchdog of the restart
  were created at 20:55Z, before the restart was on main, and started no
  lead cycle: the launcher's run at 21:30Z was refused when it tried to
  create the session. They are disabled. The ones in use were created at
  21:32Z: launcher `trig_01ChLd51gPMwzsKrXifYfkYj` and watchdog
  `trig_016aHfeAQkYXB6Z5X361irkE` (`lead.md` has the table). Until
  21:38Z no session had done any work since the restart.
- **Nothing was lost at the stop:** kit-4, icons-2a and words are all
  ready on their branches with pre-check PASS. The first cycle (21:38Z)
  takes them up; main's `icons_48_hc.webp` rebake still has to be fixed
  before guard is green.
- **Needs the owner:** nothing.

## 2026-11-04 23:33Z: two merges; kit-4 back to AIA; main's icon bake not stable (lead, cycle 43)

- **What:** merged P1-AIA2-icons-1b (`90f72fd7`) and P1-K1-catalogue
  (`7e6de29d`) after check_all PASS and ui guard OK on candidate
  `00e31ef0`. K1 started on P1-K1-words, AIA-2 on P1-AIA2-icons-2a.
  - P1-AIA-kit-4's gate (advisory, Opus 5.5 ui-judge, verdicts in
    `docs/art/ui-quality/gate/verdicts/P1-AIA-kit-4/3eb4e200.json`):
    Light behind UI passes. Layered materials fails (the large popup,
    sheet and header panels are near-flat fills with thin rims). Display
    type fails (same-rank titles get different outline and drop
    treatments). Colour roles and value fails (the bronze and silver
    frames differ only by hue and value, and their locked twins are
    identical). These are passed to AIA for kit-5.
  - Kit-4's candidate `050f2e10` failed check_all, 391 of 392: its nine
    new skins have no SKINS_OF entry. As set out in cycle 42's default,
    the SKINS_OF block of `client/tests/ui_kit_tests.gd` is granted to
    kit-4 as an exception, and AIA was restarted to add them. The test is
    not loosened.
  - guard.sh's rebake now fails on main itself:
    `client/ui/art/icons_48_hc.webp` bakes differently in this container.
    The halo is gone and pip is an octagon again, from the same sources
    that rebaked byte for byte about 30 minutes earlier. So AIA-2's
    icons-1b fix for a load-dependent bake does not hold in every
    environment, and until it does no candidate passes guard.
- **Default (no answer needed):** AIA-2 makes the icon finish
  environment-independent. The lead sends icons-2a back with this finding
  if its candidate's rebake still differs. Nothing merges while guard is
  red.

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
