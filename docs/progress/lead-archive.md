# Lead: archived "Now" entries

Entries moved out of [lead.md](lead.md) by `tools/coord/archive.py`,
newest first. Nothing here is current; lead.md's "Now" is.

## Now (archived)

- **Cycle 111**, 17 November 2026, from about 02:39Z (session
  `session_01SNkKxp3QH4szJPdrskLbcc`, started by the Opus 5.5 launcher).
  **Claims copied:** S2 works on P2-S2-home-6 (seen 02:21Z, lease to
  04:00Z): pre-check passed on e674b614, `gate_request` set there under
  M43, not ready. S1 works on P2-S1-result-6 (seen 02:32Z, lease to
  04:31Z): its own gate run passed at e4e78070, its pre-check of c9d70cc3
  running, not ready.
  **Requests:** S1-R35 (preview result-6 at c9d70cc3, not blocking, due
  10:17Z) copied to AD's section and answered: AD is started for it, and
  the merge does not wait for AD.
  **Gate and merges:** the advisory gate (rubric v3, ui-judge at effort
  high, three samples each, stills rendered by the lead from the home
  shot at e674b614) ran on S2's `gate_request`
  (docs/art/ui-quality/gate/verdicts/P2-S2-home-6/e674b614.json).
  Display type at home 100% text fails 3 of 3: the headline counts
  (1,460, 142.0k, 31.4k, 61.0k) are flat gold on dark plates beside a
  stroked 'Keeper 24'; AD-R45 (a) is still open at e674b614. The other
  five pass 3 of 3: Hierarchy at 100%, 200% pt_BR and high contrast,
  Character presence at 100%, Display type at 200% pt_BR. No split. It is
  home-6's first fail under M43; the note under AD-R45 tells S2 to fix
  (a) and the 100% counts in home-6 and request the gate again. Nothing
  is ready, so nothing merged and no check ran; the merge lock stays
  null.
  **Messages:** none new. M43 and M44 are due at 03:55Z.
  **Seats:** S1, S2 and AD working, three of four. AD's new session
  (`session_01SNkKxoJbJnMvxsrv2outFG`) takes S1-R35. Under M33 no task
  qualifies for the fourth seat before the phase-2 stop at 21:00Z.
  **Next:** cycle 112 re-gates home-6 at 100% text, Display type, when S2
  requests it, gates result-6 when S1 requests it, merges both as one
  candidate when both are ready (M42; one alone if the other is far
  off), checks M43 and M44 at 03:55Z, and restarts S1 or S2 only if its
  update time passes.

- **Cycle 110**, 17 November 2026, from about 02:14Z (session
  `session_01SNkKxqnwS161aj2Ndyfo94`, started by the Opus 5.5 launcher).
  **Claims copied:** S2 works on P2-S2-home-6 (seen 01:52Z, lease to
  04:00Z; pre-check running on e674b614, main merged in, then its gate
  request). S1 works on P2-S1-result-6 (seen 01:58Z, lease to 04:31Z;
  the Starlight tile framed with the crew's face, the totals baked, the
  helpers moved to result_fit.gd at f96569c0).
  **Requests:** AD answered S2-R34 at 01:57Z: S2's three changes stand,
  one objection kept and sent to the lead as AD-R45 (the live words
  after the baked figures echo below themselves and are cream beside
  gold). The lead copied both and answered AD-R45: S2 fixes it in home-6
  before ready, as AD's default offers, so nothing is seeded (M33).
  **Gate and merges:** nothing ready, so no gate ran and nothing merged;
  the merge lock stays null. No check ran.
  **Messages:** M42 acked. When home-6 and result-6 are both ready, the
  lead builds one candidate from both and runs the full checks once; only
  a failed batch is re-checked task by task. M43 (S2) and M44 (S1) are
  due at 03:55Z.
  **Seats:** S1 and S2 working, two of four. AD's session
  (`session_01SNkKxnPTEBNJrsj8BFDyUi`) is idle, its preview done. Under
  M33 no task qualifies before the phase-2 stop at 21:00Z: AD-R45 is
  answered inside home-6, and no failed gate quality or blocking check
  lacks a task. Phase 3's tasks are seeded once stop_at passes.
  **Next:** cycle 111 gates and merges home-6 and result-6 as one batch
  when both are ready (one alone if the other is still far off), checks
  M43 and M44 at 03:55Z, and restarts S1 or S2 only if its update time
  passes.

- **Cycle 109**, 17 November 2026, from about 01:38Z (session
  `session_01SNkKxqA691fQupEvYwZ32N`, started by the Opus 5.5 launcher).
  **Claims copied:** S2 works on P2-S2-home-6 (claimed 01:00Z, lease to
  04:00Z, last green eb40e8f4, build at 4c242628). S1 claimed
  P2-S1-result-6 at 01:31Z (lease to 04:31Z).
  **Requests:** S2-R34 copied to AD's section (blocking, due 03:30Z:
  preview home-6 at 4c242628 or later: gold baked numerals on every
  headline count, the counts shrunk to fit in de and pt, a leather-rim
  band round 'Keeper 24''s outline). AD started on it at 01:43Z
  (`session_01SNkKxnPTEBNJrsj8BFDyUi`); AD's prompt now names S2-R34 and
  M40. If AD has not answered by 03:30Z, S2-R34's default stands.
  **Gate and merges:** nothing ready, so no gate ran and nothing merged;
  the merge lock stays null. No check ran, so no missing tool to report
  (M37).
  **Messages:** M37, M38 and M39 acked.
  **Seats:** S1, S2 and AD, three of four. The fourth stays free: M39
  keeps the queue full, but under M33 no task qualifies before the
  phase-2 stop at 21:00Z (no open objection, failed gate quality or
  blocking check lacks a task). Phase 3's tasks are seeded once stop_at
  passes.
  **Next:** cycle 110 copies AD's answer to S2-R34, then gates and merges
  home-6 and result-6 when ready.

- **Cycle 108**, 17 November 2026, from about 00:14Z (session
  `session_01SNkKxnyW6RtDjtVJivG3bg`, started by the Opus 5.5 launcher).
  **Missing tool (M37):** the main checkout had no three.js under
  tools/ui_research/node_modules, so the ui guard stopped at its
  prerequisite check. The lead ran `npm ci` there and re-ran the guard.
  **Claims copied:** S2's P2-S2-home-5 is ready at eb40e8f4 and S1's
  P2-S1-heist-1 is ready at 90c8b15c.
  **Requests:** AD answered both of its previews. For S2-R33 the stills
  stand with no objection. For S1-R34 it kept two objections, sent to the
  lead as AD-R44. The lead copied AD-R44 and answered it: both points
  were already in heist-1's done_when. It then closed AD-R44, because the
  gate passes both items at 90c8b15c. They become notes, and nothing is
  seeded.
  **Gate (advisory, rubric v3):**
  - home-5 at eb40e8f4 fails Display type at home 100% and at 200% pt_BR,
    0 of 3 each. It passes Hierarchy (100%, high contrast and 200% pt_BR)
    and Character presence 3 of 3.
  - heist-1 at 90c8b15c passes all eight items. Hierarchy at 200% pt_BR
    with no plan and Layered materials at 200% passed 3 of 3. Painted or
    rendered icons passed 4 of 6, because the split first three samples
    took three more. The verdict is in
    `docs/art/ui-quality/gate/verdicts/P2-S1-heist-1/90c8b15c.json`.
  **Merges:**
  - P2-S2-home-5 merged as `fb8ff4b9`. Its candidate d202ec2e passed
    check_all (bwrap), owners.py and the ui guard.
  - P2-S1-heist-1 merged as `79c1f353`. Its candidate d68725cf, which sits
    on d202ec2e, passed check_all (bwrap), owners.py and the ui guard.
    owners.py passed after the lead granted client/world/fx_law_badge.gd.uid,
    the Godot uid file of the owned fx_*.gd. S1-R33's draw-call records
    are in the merge, with a raises entry: heist/200 goes from 116 to 118,
    and heist/hc from 120 to 121. Main had gained only lead records.
  - The audit and roadmap pages did not change, so neither was
    republished.
  **Seeded (M33):** P2-S2-home-6, to close home-5's Display type fails.
  Its outline goes on 'Keeper 24', all round. Its one big-number
  treatment goes on the purse counts, the gem count and Vibrante %.
  **Seats:** S2 started at 00:56Z on home-6
  (`session_01SNkKxqDPpd7eVdbFeT2dp8`). S1 started at 01:27Z on result-6 (`session_01SNkKxrHQgnrk4u1GoTLWJP`), because heist-1 had merged. That makes two of four seats in use. AD's session
  `session_01SNkKxq1MGyJ5jNneT2tqME` is idle, its two previews done. K1
  and S3 have no open task.
  **Next:** cycle 109 sends S2's and S1's preview requests to AD when
  they come, then gates and merges home-6 and result-6 when ready. Under
  M33 nothing else is seeded before the phase-2 stop at 21:00Z. BT-* and
  SV-B10 stay outside the UI wave.

- **Cycle 107**, 16 November 2026, from about 22:39Z (session
  `session_01SNkKxoeFFAtKhms3FvN3zQ`, started by the Opus 5.5 launcher).
  The container lacked the wasm32 target, so the first check_all on
  714b24ed failed at the simulation build. The lead installed the rustup
  targets and the pip packages, and the re-run passed.
  **Claims copied:** S2's P2-S2-home-5 is ready at eb40e8f4 (S2 is
  waiting) and S3's P2-S3-character-4 is ready at ee67dcea. S1's heist-1
  is still working.
  **Requests:** two copied. S2-R33 (blocking: AD previews home-5, due
  01:55Z) and S1-R34 (not blocking: AD previews heist-1's stills, due
  10:09Z) both go to AD. S3-R31's default was applied at its due, 23:08Z.
  **Merges:**
  - P2-K1-grow-1 merged as `d277dc25`.
  - P2-S3-character-4 merged as `80818878`. Its candidate 7e80197f passed
    check_all (bwrap), owners.py and the ui guard. Main had gained only
    docs/progress commits, so the candidate merged onto that head.
  - The audit and roadmap pages did not change, so neither was
    republished.
  **Gate:** character-4's advisory verdict is in
  `docs/art/ui-quality/gate/verdicts/P2-S3-character-4/ee67dcea.json`.
  Display type at character 200% pt_BR passes narrowly, 3 of 6: the split
  first three samples took three more. The critique notes a thin outline.
  Hierarchy passes 3 of 3.
  **Seats:** K1's seat freed when grow-1 merged, so AD started at 23:29Z
  on S2-R33, then S1-R34 (`session_01SNkKxq1MGyJ5jNneT2tqME`). In use: S1
  (heist-1), S2 (home-5, waiting on AD) and AD, three of four. K1 and S3
  have no open task.
  **Next:** cycle 108 gates and merges home-5 at eb40e8f4 once AD answers
  S2-R33, or once its default stands at 01:55Z. It merges heist-1 when
  ready, with S1-R33's records in its merge, and result-6 opens once
  heist-1 has merged. BT-* and SV-B10 stay outside the UI wave.

- **Cycle 106**, 16 November 2026, from about 21:39Z (session
  `session_01SNkKxotGbP1EXkMF8w5cpy`, started by the Opus 5.5 launcher).
  **Claims copied:** S1's P2-S1-heist-1, S2's P2-S2-home-5 and S3's
  P2-S3-character-4, all three working. K1's P2-K1-grow-1 claim was seen
  at 21:50Z. It is not ready yet: its pre-check is running at 050be78b, on
  the merge 4f10bc28.
  **Requests:** four copied.
  - S1-R33 (heist/200 and heist/hc draw-call budgets) is approved under
    M33, because both calls close failed gate qualities. The lead writes
    those records, with a raises entry, in the merge of heist-1.
  - S3-R32 (rb_box's parchment panel not drawn when scrolled) is logged
    for phase 3, about 1.5 h. No task is seeded under M33.
  - S3-R31 (AD preview of character-4) waits for a seat, which it does not
    have: all four are in use. Its default stands at its due, 23:08Z.
  - S3-R33 ("main moved backward") is answered: origin's `main` is the
    stray branch of 4 November, and the program's main contains f083c96c.
  **Gate:** S2's gate request, the re-run on main f083c96c that home-5
  asks for first, has its verdict in
  `docs/art/ui-quality/gate/verdicts/P2-S2-home-5/f083c96c.json`.
  - Display type at home 100% fails, 0 of 3. The purse's counts are flat
    cream, and 'Keeper 24' sits over the sky without an outline. The fail
    of 977edd5b stands, and S2's fix on its branch is the right one.
  - Hierarchy at 100% passes 3 of 3, and so does Hierarchy in high
    contrast.
  - Character presence at 100% passes 3 of 3; it failed at 977edd5b.
  - This run judged main as a baseline, so it adds nothing to home-5's
    attempts.
  **Merge:** none, because nothing was ready and the lock stayed null.
  **Seats:** four of four (K1, S1, S2, S3), so AD is not started.
  **Next:** cycle 107 merges grow-1, heist-1, home-5 and character-4 as
  each becomes ready, with S1-R33's records in heist-1's merge. Once a
  seat frees, it starts AD on the preview requests. Result-6 opens once
  grow-1 and heist-1 have merged. BT-* and SV-B10 stay outside the UI wave.

- **Cycle 105**, 16 November 2026, from about 20:38Z (session
  `session_01SNkKxpseg4mh8yx1YBk6dS`, started by the Opus 5.5 launcher).
  **Claims copied:** K1's P2-K1-grow-1 (claimed 20:25Z, seen 20:42Z).
  **Requests:** K1-R24 copied and granted:
  `client/tests/shots/ui_kit_grow.gd` and its `.uid` are in grow-1's
  exceptions now. M33 and M34 acked. Following M34, every agent's prompt
  now carries the words.js line: a commit that changes strings.csv or
  content.csv also commits a regenerated words.js, and
  check_keyframes.mjs passes before ready.
  **Gate and merge:** none. Nothing was ready, and the lock was null.
  **Seeded** (each closes a failed gate quality, M33): P2-S1-heist-1 (the
  heist screen's open fails at 100% and 200% text and at 200% pt_BR),
  P2-S2-home-5 (Display type at home 100%, re-gated first),
  P2-S3-character-4 (Display type at character 200% pt_BR) and
  P2-S1-result-6 (it drops result's local fixes and re-gates 100%; its
  deps are grow-1 and heist-1).
  **Seats:** K1 on grow-1, S1 on heist-1
  (`session_01SNkKxo7UZxeUrogyt29c1R`, 20:47Z), S2 on home-5
  (`session_01SNkKxnd61Vr6rsj7aeL4cz`, 20:49Z) and S3 on character-4
  (`session_01SNkKxpXsYHy2L9mKvHcZBk`, 20:49Z). Four seats of four are in
  use; AD previews through requests.
  **Next:** cycle 106 copies the new claims, routes the AD preview
  requests and merges grow-1, heist-1, home-5 and character-4 as each
  becomes ready. Result-6 opens once grow-1 and heist-1 have merged.
  BT-* and SV-B10 stay outside the UI wave.

- **Cycle 104**, 16 November 2026, from about 19:39Z (session
  `session_01SNkKxq7RefUXnN7oBncd9P`, started by the Opus 5.5 launcher).
  **Claims copied:** K1's P2-K1-guard-prereq (ready `e49d3d2a`).
  **Requests:** S1-R32 copied into requests.md's K1 section (KitNav.reward
  dresses the sky in `night_rays` even under high contrast; S1's default,
  its local fix in `result_screen.gd`, stands until the kit answers).
  **Gate and merge:** candidate `bb7e4d33` (guard-prereq) passed check_all
  (bwrap) and the ui guard, whose new prerequisite check reported
  "every prerequisite is here". Main had gained only docs/progress
  commits, so the candidate merged onto that head as `c0e0418b`, with the
  docs check rerun. M32 is done. The audit and roadmap pages did not
  change, so neither was republished.
  **Seeded:** P2-K1-grow-1 for K1, taking S1-R32, S1-R15, S1-R23 and S3-R3:
  action2, big_action and upgrade grow and wrap at large text, and reward
  leaves the sky plain under high contrast. S1 and S3 drop their
  screen-side fixes in later tasks of their own.
  **Seats:** K1 started at 20:22Z on P2-K1-grow-1
  (`session_01SNkKxr27Br8FeRKiWvTJ1x`). S1, S2, S3 and AD have no open
  task, so one seat of four is in use.
  **Next:** cycle 105 copies K1's claim and merges P2-K1-grow-1 when
  ready. Once it merges, it seeds S1's and S3's tasks to drop their local
  fixes, as K1's handoff names them. BT-* and SV-B10 stay outside the UI
  wave.

- **Cycle 103**, 16 November 2026, from about 17:39Z (session
  `session_01SNkKxnS8D88S3KnnZyABwf`, started by the Opus 5.5 launcher).
  **Claims copied:** AD's P2-AD-board-3c (ready `055840f7`), S1's
  P2-S1-result-5 (ready `8d2488cb`) and, later in the cycle, S3's
  P2-S3-account-4 (ready `635c33ee`, claim seen 18:10Z, merged). **Requests:**
  none new from the builders. M31 and M32 acked. From M32 (the
  overseer's lesson on M19) P2-K1-guard-prereq is seeded for K1:
  guard.sh checks its prerequisites first and names what is missing.
  **Gate and merge:** candidate `0c905be3` (board 3c + result 5) passed
  check_all and the ui guard and merged as `532296af`. Board 3c stands
  (H fixed). Its note that the chosen tab tile sits about 7 px proud is
  K1's to weigh at its next kit pass, not holding anything. The lead's
  strings candidate (S2-R32: WEAVING_BAND_0 to 6 translated into pt_BR,
  pt_PT, de and fr; S2-R29: the three orphan `.uid` files removed)
  first failed check_all at `7268cb98` with "words.js is not the game's
  words". Lesson: any change to strings.csv also needs `node
  art/ui/keyframes/build_words.mjs` and the regenerated words.js in the
  same candidate. Fixed in `6d10711e`. The fit runs (FIT=1 TEXT=200
  universe_home.gd) passed in pt_BR, pt_PT, de and fr. S3's P2-S3-account-4
  (`635c33ee`) was stacked on it as candidate `de3a577a`: check_all PASS,
  ui guard OK, merged as `6d9a4bf1`. S2-R32 and S2-R29 are done.
  **Seats:** K1 started at 17:52Z on P2-K1-guard-prereq
  (`session_01SNkKxnzhmd9WDTWw6ChMw3`). S3, S1, AD and S2 have no open
  task, so one seat of four is in use. **Next:** cycle 104 merges
  P2-K1-guard-prereq when ready. It may seed a K1 task from the pending
  K1 requests in requests.md's K1 note. BT-* and SV-B10 stay outside the
  UI wave.

- **Cycle 102**, 16 November 2026, from about 16:39Z (session
  `session_01SNkKxr2KqhZcMDPDNjAD3g`, started by the Opus 5.5 launcher).
  The launcher fired while cycle 101 (from 13:41Z) was still running,
  because "Latest lead cycle session" above named cycle 100's idle
  session until cycle 101's write-up. So both cycles started AD for
  P2-AD-board-3c, 33 seconds apart. Cycle 102 archived its duplicate
  (`session_01SNkKxneJSddGy6BT3d1gxC`) at 16:42Z, before it claimed
  anything. Cycle 101's AD session holds the claim. **Claims copied:**
  AD on P2-AD-board-3c and S3 on P2-S3-account-4, both claimed at 16:45Z
  with leases to 19:45Z. S1 (started 16:41Z) had not yet claimed
  P2-S1-result-5 at 16:47Z. **Requests:** none new. S2-R32 (the
  weaving band names) and S2-R29 (the three orphan `.uid` files) are
  held for one lead-owned candidate after P2-AD-board-3c merges, so the
  home stills AD is re-checking do not change under the review. S2-R32
  is due 17 November 19:33Z. **Gate and merge:** nothing ready, no
  lock taken. **Seats:** three of four (AD, S3, S1). K1 and S2 have no
  open task. **Next:** cycle 103 merges board 3c, account-4 and
  result-5 when ready, seeds what H still needs if board 3c keeps it
  open, then builds the strings candidate (S2-R32 and S2-R29).

- **Cycle 101**, 16 November 2026, from about 13:41Z (session
  `session_01SNkKxr2W1EVjzynnMCEqVA`, started by the Opus 5.5 launcher).
  **Requests:** AD-R42 (S2-R31 and S1-R31 previews) answered by S1's
  fix: the gate at `6fb2e3da` passed Display type; AD-R43 (board 5c's
  objection M, the signed-in leather 'Sign out' buttons 16 to 17.5 ΔL*
  off their card) answered as its default says: P2-S3-account-4 seeded
  for S3, closed by `checks.py value-steps`, no AD round 4; K1-R23 seeded
  as P2-S1-result-5 (result_screen.gd plays the reward through
  KitNav.reward); S2-R32 (the weaving band names) deferred to a
  lead-owned strings change in its own candidate, since translating
  changes the fit. **Gate** (advisory, rubric v3): P2-S1-result-4 at
  `6fb2e3da` passes Display type 3 of 3 at 200% pt_BR (the ink outline
  now grows with the text) and Hierarchy 3 of 3 at 200% pt_BR and in
  high contrast; P2-S2-home-4 at `1697a6c6` (home at 200% pt_BR) passes
  Hierarchy 3 of 3, and Display type split, so three more ran: 3 of 6
  fail, under the 4 that make a fail, so it passes (the failing samples
  read the currency counts as a flat cream fill; a note for board 3c). **Merged:**
  P2-S1-result-4 (candidate `049266b5`, merge `9a1d4db5`), P2-S2-home-4
  with IQ-import-check (candidate `6e323a0f`, merge `5803122d`, home/200
  recorded at 121 draw calls with S2-R30's raises entry) and
  P2-AD-board-5c with P2-K1-kit-gaps-2 (candidate `d1c52fce`, merge
  `26cbd842`), each on check_all PASS and "ui guard: OK". **Guard
  lesson:** in a fresh candidate worktree run `bash client/build.sh`
  first and link `tools/ui_research/node_modules` from the main checkout;
  without the library every shot hangs about 5 minutes, and without
  node_modules the icons_256 bake times out (the first run on home-4's
  candidate was killed at 30 minutes). **Started:** AD on board 3c
  (`session_01SNkKxoVZrM6k7CuBbUpkM3`), S3 on P2-S3-account-4
  (`session_01SNkKxnS2WKmrL48Dmzje8k`) and S1 on P2-S1-result-5
  (`session_01SNkKxpVcMU7QCMYR9SLhx3`), all at 16:41Z. The audit and the
  roadmap pages did not change, so they were not republished. Seats: AD,
  S3 and S1 working, three of four; K1 and S2 have no open task.
  **Next:** merge board 3c when ready (and seed what H still needs, if
  AD keeps it); merge account-4 and result-5 when ready; translate the
  weaving band names (S2-R32) as a lead-owned strings candidate.

- **Cycle 100**, 16 November 2026, from about 11:40Z (session
  `session_01SNkKxoqsyfRu7nQ4xvraaU`, started by the Opus 5.5 launcher).
  The fresh container lacked the wasm and phone Rust targets and the
  Python tools; the cycle installed them as the agents' prompts say
  (`rustup target add ...`, `pip install gdtoolkit playwright pillow
  numpy`). **Requests:** S2-R30 (home/200 at 121 draw calls) approved as
  its default says, written in the merge of P2-S2-home-4; S2-R31 (home-4
  preview at `c8de70fe`) copied for AD; S2-R32 (WEAVING_BAND_0 to 6 in
  English in every column) copied, its default holds until a lead-owned
  strings change after home-4 merges; S3-R29 answered by its default at
  11:43:26Z (S3 marked P2-S3-character-3 ready at `a6d5f2fb`; board 5c
  re-checks K and L). **Started:** AD (`session_01SNkKxoT1Zvr4LionPdFkEt`,
  11:49Z: S2-R31, S1-R31, then boards 5c and 3c), S1 restarted on
  P2-S1-result-4 (`session_01SNkKxnXsUaw4HRQU3Yc69h`, 11:49Z: the session
  before went idle waiting for the gate) and K1 on P2-K1-kit-gaps-2
  (`session_01SNkKxnx23zG9HV4wddwVrq`, 12:24Z;
  `client/tests/shots/ui_kit_*.gd.uid` added to its exceptions, the
  `.uid` exception kit-gaps-1 needed). **Gate** (advisory, rubric v3):
  P2-S3-character-3 at `a6d5f2fb`, at 200% text in pt_BR. Hierarchy
  passes 3 of 3. Display type split 2 to 1, so three more ran: 5 of 6
  fail. The subtitle and the level line over the starry backdrop carry a
  drop shadow but no outline at the top and left, and the flat gold
  HABILIDADE header differs from the stroked 'Subir de nível' header of
  the same rank; the 200 headline passes. Two Hierarchy samples note the
  HABILIDADE card is clipped by the Level up dock. An advisory fail holds
  nothing; these are board 5c's close points. Verdicts are in
  `verdicts/P2-S3-character-3/a6d5f2fb.json`. **Merged:**
  P2-K1-kit-gaps-1 (candidate `10bea1e4`, merge `cf6165e9`) and
  P2-S3-character-3 (candidate `04b6a0f0`, merge `0ee8d9d8`), each on
  check_all PASS and "ui guard: OK". The audit and the roadmap pages did
  not change, so they were not republished. Seats: K1, S1, S2 and AD
  working, four of four; S3 has no open task. **Next:** AD answers S2-R31
  and S1-R31, then takes board 5c (open now) and board 3c once home-4
  merges. Merge home-4 with IQ-import-check (`ade915de`) when ready,
  with home/200 at 121 and S2-R30's raises entry, then translate the
  weaving band names (S2-R32). Merge result-4 when ready. Merge
  kit-gaps-2 when ready.

- **Cycle 99**, 16 November 2026, from about 10:39Z (session
  `session_01SNkKxqWs3DXEToJqEWQxXa`, started by the Opus 5.5 launcher).
  Copied S1's claim on P2-S1-result-4 into the backlog (lease 12:43Z) and
  the agents' `seen_at`. **Requests:** S3-R30 granted as its default says
  (`client/scripts/auth_panel.gd` added to P2-S3-character-3's
  exceptions); S3, idle waiting on it, restarted at 10:44Z
  (`session_01SNkKxqxSgTQePYHeS97vWa`). S1-R31 and S3-R29 copied for AD;
  S3-R29's default (K and L stand as fixed, S3 marks ready at its
  pre-checked sha, AD's round 3 re-checks) applies at 11:43:26Z if AD has
  not answered. M26 (the report's lesson: a screen's fit script covers
  every fixture state) acked and added to the done_when of result-4,
  home-4 and character-3; M27 to M29 tell S1, S2 and S3. **Gate**
  (advisory, rubric v3): P2-S1-result-4 at `8753618a`, on S1's
  gate_request, stills rendered from the candidate (pt_BR 200% and high
  contrast, both "fit ok"). Hierarchy passes 3 of 3 at 200% pt_BR and 3
  of 3 in high contrast. Display type at 200% pt_BR fails 3 of 3: the
  gold kicker over the sunburst sky has no ink outline, and the summary
  lines keep a hairline edge that did not scale with the text. The
  reward figures pass. Verdicts are in
  `verdicts/P2-S1-result-4/8753618a.json`, and M30 gives S1 the close
  point. **Merged:** nothing; no task was ready. **Started:** S3 (above).
  Seats: K1, S1, S2 and S3 working, four of four. K1 is waiting on its
  pre-check at `9ec2e61b`; AD waits for a seat. **Next:** merge
  kit-gaps-1 when ready, then start AD (S3-R29 first if it is still open,
  then S1-R31) and K1 on kit-gaps-2. Merge home-4 with IQ-import-check,
  then AD takes board 3c. Merge character-3, then board 5c. Merge result-4
  when ready.

- **Cycle 98**, 16 November 2026, from about 09:35Z (session
  `session_01SNkKxpnLgsoTHAqFj6UTHk`, started by the Opus 5.5 launcher).
  Copied claims and leases into the backlog: P2-K1-kit-gaps-1 (K1, lease
  12:35Z), P2-S2-home-4 (S2, lease 12:35Z) and P2-S3-character-3 (S3,
  lease 12:30:15Z). **Requests:** none new. **Gate:** no task with gate
  items was ready. **Merged:** nothing; nothing new was ready, and
  IQ-import-check (`ade915de`) still waits to merge with P2-S2-home-4.
  **Seeded:** P2-S1-result-4 (S1, M25: phase 2's exit for the result
  screen, an overflow sweep in en, pt_BR and de at 100% and 200% text and
  in high contrast, the gate at 200% pt_BR and in high contrast, the
  advisory close points of result-3 answered); `owners.py claims`: tasks
  in flight disjoint. **Started:** at 09:43Z S1 on P2-S1-result-4
  (`session_01SNkKxpR61Xc97jycRSyB3B`). Seats: K1, S2, S3 and S1 working,
  four of four; the seven-day bar reads allowed. AD's last session
  (board 5b) is idle; its open question (AD-R40 and AD-R41's default) was
  answered in cycle 97 with character-3 and board 5c. **Next:** merge
  home-4 with IQ-import-check, then AD takes board 3c; merge character-3,
  then AD takes board 5c; merge kit-gaps-1, then K1 takes kit-gaps-2;
  merge result-4 when ready.

- **Cycle 97**, 16 November 2026, from about 08:39Z (session
  `session_01SNkKxorVw3MyhDkJsvRqhq`, started by the Opus 5.5 launcher).
  Copied task states and leases into the backlog: P2-K1-tabs-3 ready at
  `9e08db75` (K1), P2-AD-board-5b ready at `d48c880e` (AD) and IQ-kit-docs
  ready at `8f7a9fad` (S3); `exceptions` set to `[]` on board 5b and 3c,
  where null made `owners.py` fail. **Requests:** AD-R40 and AD-R41 (board
  5b's objections K and L) answered as their defaults say:
  P2-S3-character-3 (S3) and P2-AD-board-5c (AD, only K and L, after
  character-3) seeded. AD's status file dates them 09:20Z, ahead of the
  clock when the lead read them. S3-R22 to S3-R28 (IQ-kit-docs's findings
  for K1) answered: R22, R24, R26 and R27 go to P2-K1-kit-gaps-1, and R23
  and R25 to P2-K1-kit-gaps-2 (after kit-gaps-1), both seeded; R28's
  default stands. **Gate:** no task with gate items was ready.
  **Merged:** candidate `573416ab` (tabs-3, board 5b, IQ-kit-docs) as
  `1053266f`, after check_all PASS (09:27:17Z) and guard.sh "ui guard:
  OK" (first run, with three.js and the native library copied into the
  candidate's worktree). The lock was taken at 08:56Z and cleared with
  the merge. IQ-import-check (`ade915de`) stayed out: its branch carries
  one line of `docs/art/tracks/home-screen.md`, which it does not own, so
  it merges with P2-S2-home-4. **Restarted:** at 09:28Z S2 on
  P2-S2-home-4, S3 on P2-S3-character-3 and K1 on P2-K1-kit-gaps-1. Seats:
  K1, S2 and S3 working, three of four; AD has no open task (board 3c
  waits on home-4, board 5c on character-3). **Next:** merge home-4 with
  IQ-import-check, then AD takes board 3c; merge character-3, then AD
  takes board 5c; merge kit-gaps-1, then K1 takes kit-gaps-2.

- **Cycle 96**, 16 November 2026, from about 06:41Z (session
  `session_01SNkKxo5L5nkx6LE2sYyMSz`, started by the Opus 5.5 launcher).
  **Requests:** AD-R38 and AD-R39 (board 3b's objection H) answered as
  their defaults say: P2-K1-tabs-3 (K1), P2-S2-home-4 (S2, after tabs-3)
  and P2-AD-board-3c (AD, only H, after both) seeded. S3-R21 answered by
  AD at 07:00Z: J stands as fixed at `9e602fcc`, and S3 marked
  P2-S3-settings-2 ready there. S2-R29 (three orphan `.uid` files under
  `client/tests/`) copied, open; its default holds until a lead-owned
  removal. **Gate** (advisory, rubric v3): P2-S3-settings-2 at `9e602fcc`
  passes all four rows (`verdicts/P2-S3-settings-2/9e602fcc.json`); 100%
  Hierarchy clears `5fc97aac`'s fail, and 200% pt_BR Hierarchy split and
  passed on six samples, three fails of six. **Merged:** candidate
  `3ca39573` (P2-AD-board-3b at `31c4de6c`, P2-S3-settings-2 at
  `9e602fcc`) as `f675f05e`, after check_all PASS (07:32:14Z) and
  guard.sh "ui guard: OK". The first guard run timed out, and the second
  had no native library in the candidate's worktree; the third was clean.
  The lock was taken at 06:52Z and cleared with the merge. **Restarted:**
  at 06:49Z AD (S3-R21), K1 (P2-K1-tabs-3) and S2 (IQ-import-check from
  the idle queue, M25). After the merge, at 07:44Z, AD on P2-AD-board-5b and S3
  on IQ-kit-docs (idle queue, M25). S2's IQ-import-check is ready at
  `ade915de` (docs only). Seats: K1, AD and S3 working, S2 waiting on
  tabs-3, four of four. M25 acked. **Next:** merge IQ-import-check; K1
  finishes tabs-3, then S2 takes home-4, then AD takes board 3c; seed fix
  tasks from any objection board 5b keeps.

- **Cycle 95**, 16 November 2026, from about 05:39Z (session
  `session_01SNkKxmibsJftfpUThu9TXk`, started by the Opus 5.5 launcher).
  Copied task states and leases into the backlog: P2-AD-board-3b working
  (AD claimed it at 05:33Z, lease to 08:33Z), P2-S3-settings-2 working
  (S3's lease to 08:04Z). **Requests:** S3-R20 (preview of the Hierarchy
  fixes for the gate's advisory fail at `5fc97aac`) copied with AD's
  answer (05:30Z): the Hierarchy fixes stand and E, F and I stay fixed,
  but a new objection J holds settings-2 (at 100% in pt_BR, de and high
  contrast pt_BR the High contrast row left the first screen). S3-R21
  (re-check of J only, at `d66e9521`: plate padding removed, the row back
  on the first screen) copied, open, due 07:42Z. **Gate:** no request
  with a sha. **Merged:** nothing; nothing is ready. **Restarted:** none;
  S3 (next update by 06:27Z) and AD (by 06:40Z) are working. Seats: S3
  and AD, two of four; no other builder task is open. The generated
  pages did not change. **Next:** merge P2-S3-settings-2 when AD clears
  J and S3 marks it ready, gated at its ready sha; AD finishes board 3b,
  then P2-AD-board-5b once settings-2 merges; seed any fix tasks board 3b
  raises.

- **Cycle 94**, 16 November 2026, from about 04:39Z (session
  `session_01SNkKxpxY6kjJC1TT6B65fn`, started by the Opus 5.5 launcher).
  **Requests:** S2-R28 copied (re-check of (g) at `c9a89e5a`); AD had
  answered it at 04:00:52Z ((g) stands as fixed; pt_BR, pt_PT and fr
  give the 200% side buttons away as a trade until P2-K1-tabs-2, board 3b
  re-checks them) and S3-R19 at 03:53:41Z (I stands as fixed), so
  P2-S2-home-3 and P2-S3-settings-2 have no open AD objection.
  **Gate** (advisory, rubric v3): P2-S2-home-3 at `c9a89e5a` passes
  (Hierarchy and Character presence, three of three each,
  `verdicts/P2-S2-home-3/c9a89e5a.json`); P2-S3-settings-2 at
  `5fc97aac` (S3's pre-ready head) fails Hierarchy at 100% (two of six)
  and at 200% pt_BR (one of six), Display type passing three of three at
  both (`verdicts/P2-S3-settings-2/5fc97aac.json`). Advisory, so it holds
  nothing; its notes go to board 5b: lift the title plate's value or
  weight, give the group headers more weight than the rows, quieten the
  tab strip and the Stillness card, and at 200% shrink or darken the
  preview card. **Merged:** P2-S2-home-3 (home, part 3) as `d6f0bad3`
  and P2-K1-tabs-2 (KitTabs' height, KitLayout.tap) as `000a7140`, under
  the lock on candidate `31c3eaa1` (home-3 at `c9a89e5a`, tabs-2 at
  `87b21b06`, then budgets.json home/200 from 114 to 119 with a raises
  entry for S2-R21 and K1-R22: the guard read 119 on the candidate);
  owners diff and claims OK, check_all PASS (05:20:57Z), guard "ui guard:
  OK"; main merge `67484f47`, the lock cleared in the same push
  (`f96e7453`, M17). The generated pages did not change, so they were not
  republished. **Restarted** AD (`session_01SNkKxp6Jtxgub8m9mNth9u`,
  05:24Z) on P2-AD-board-3b, whose deps are now all merged, then board 5b
  once settings-2 merges. S2 and K1 have no next task and end done. Seats:
  S3 and AD, two of four. **Next:** merge P2-S3-settings-2 when S3 marks
  it ready, gated at its ready sha; then P2-AD-board-5b; seed any fix
  tasks board 3b raises.

- **Cycle 93**, 16 November 2026, from about 03:35Z (session
  `session_01SNkKxqD2VSCqdpQojkHwTN`, started by the Opus 5.5 launcher).
  Copied task states and leases into the backlog: P2-K1-tabs-2 working
  (K1's lease to 04:58Z, its three shot-test exceptions K1-R21),
  P2-S3-settings-2 working (S3's lease to 06:21Z), P2-S2-home-3 working
  (S2's lease to 06:15Z); owners claims disjoint. **Requests:** K1-R21
  (the catalogue and tabs shot tests as exceptions) and K1-R22 (home/200
  from 114 to 115 in budgets.json, written by the lead with tabs-2's
  merge) granted; S2-R21 raises the same record to 124 for home-3, so
  whichever of the two merges second takes the figure guard reads on its
  candidate, with its own raises entry. **Gate:** none run, no request
  carries a sha (S3's settings-2 request has none yet). **Restarted** AD
  (`session_01SNkKxnNSwe9gUoLpoPTsuC`, 03:42Z) on S3-R19, then S2's
  re-check of (g) once filed. **Merged:** nothing; no task is ready (S2
  pre-checking its fix of (g) at `398a38cb`, S3 pre-checking settings-2,
  K1's check_all running on `19bb8764`). Seats: S2, S3, K1 and AD, four of
  four; the bar reads allowed. **Next:** merge P2-S2-home-3 when S2 marks
  it ready and AD clears (g) (M20, M24: prepare the candidate while AD
  reviews, home/200 at 124 with the K1-R22 interplay above); merge
  P2-S3-settings-2 when ready, gated, and AD clears I (S3-R19); merge
  P2-K1-tabs-2 when ready, with the budgets.json entry.

- **Cycle 92**, 16 November 2026, from about 02:40Z (session
  `session_01SNkKxq7DW11Lp53nLDiX6H`, started by the Opus 5.5 launcher).
  Fresh container set up (M22). **Merged:** P2-AD-board-4b (board 4,
  second round) as `9850213a` and P2-S3-character-2 (character screen,
  part 2) as `f78cf9f1`, under the lock on candidate `f78cf9f1` (board-4b
  at `0662a940`, character-2 at `98ec21b4`); owners diff and claims OK,
  check_all PASS (DONE exit=0 at 03:19Z), guard "ui guard: OK"; M20 met by
  AD's S3-R16 answer (H stands as fixed); the lock cleared in the same
  push (M17). Guard note: the candidate worktree needs a copy of
  `tools/ui_research/node_modules` (three.js) or the icon rebake times
  out. **Gate** (advisory) on P2-S2-home-3 at `8ff5ee23`: Hierarchy five
  of six, Character presence three of three, a pass
  (`docs/art/ui-quality/gate/verdicts/P2-S2-home-3/8ff5ee23.json`).
  **AD** (`session_01SNkKxnih7NRgFAhLyJ3iuE`, restarted 02:48Z) answered
  S2-R27 and S3-R17 at 03:02Z and ended its turn done. S2-R27: (f) stands
  as fixed; new objection (g), at 200% without the notice in pt_BR and
  German the four side buttons are gone. By M24 home-3 went back to S2
  and S2 was restarted on (g) (`session_01SNkKxnAA1sBLpf7cBYBHmb`,
  03:05Z); home-3 stays working. S3-R17: C, E and F stand; new light
  objection I (the Account group heading), which S3 fixed at `25ed9fd9`
  and sent back as S3-R19 (copied to AD's section; AD was already
  restarted once this cycle). S3-R18 (the profile row's value step,
  `screen_account.gd`): default applied, to board 5b. **M24** acked.
  Seats: S2, S3 and K1 working (K1 on P2-K1-tabs-2), AD done; three of
  four, the bar reads allowed. **Next:** restart AD on S3-R19, then S2's
  re-check of (g) once filed (M20, M24: prepare the home-3 candidate
  while AD reviews, with home/200 at 124 and home-3's exceptions, and
  merge in the same cycle if AD clears it); merge P2-S3-settings-2 when
  S3 marks it ready, gated, and AD clears I; merge P2-K1-tabs-2 when
  ready.

- **Cycle 91**, 16 November 2026, from about 01:28Z (session
  `session_01SNkKxoQWzjnjZaBEiPTh6V`, started by the Opus 5.5 launcher).
  Fresh container set up (M22). AD (`session_01SNkKxp2nKS16efpGtUmaSG`)
  answered S2-R25 and S3-R15 and ended its turn done. **S2-R25:** (a) to
  (e) are met at `823d2eac`; new objection (f), quality 3/14: at de 200%
  without the notice the realm pins are wide cream plates (fix: plates
  sized to what they hold, or numbered chips at 200% in every language).
  So P2-S2-home-3 goes back from ready to working, and is not merged.
  **S3-R15:** A, B, C, D and G are met; new objection H (the status pill
  covered the face at 200%), which S3 fixed at `6b7e6b42` and sent back as
  S3-R16 (copied to AD's section). **Gate** (advisory) on
  P2-S3-character-2 at `6b7e6b42`: all seven rows pass (character at 100%:
  Character presence, Display type, Hierarchy 3 of 3; at 200% pt_BR:
  Display type, Hierarchy 3 of 3; high contrast: Colour roles and value 3
  of 3, Hierarchy 2 fails of 6, a pass;
  `docs/art/ui-quality/gate/verdicts/P2-S3-character-2/6b7e6b42.json`).
  **Seeded** P2-K1-tabs-2 (S2-R24 and S2-R26, files `kit_tabs.gd`,
  `kit_layout.gd`, `ui_kit_tests.gd`), added to P2-AD-board-3b's deps.
  **Restarted** S2 (`session_01SNkKxrMWzVsrupnQ5KsTGg`) on (f) inside
  home-3 and AD (`session_01SNkKxmxBgcwrdBt9X39V3N`) on S3-R16, then
  P2-AD-board-4b; **started** K1 (`session_01SNkKxp9oEnbpwnq5zv4hEn`) on
  P2-K1-tabs-2; all at 01:50Z. S3 (`session_01SNkKxobxLMm7bkJemfXcuS`)
  is working (its pre-check on `6b7e6b42` running) and was left as is.
  Seats: S2, S3, AD and K1, four of four; the bar reads allowed. **Merged:**
  nothing. **Next:** merge P2-S3-character-2 once S3 marks it ready at
  `6b7e6b42` (or a later head, gated again) and AD answers S3-R16 (M20;
  default at 03:20Z: H stands as fixed); merge home-3 once S2 marks it
  ready again and AD answers the re-check of (f), with S2-R21's home/200
  budget and S2-R23's exceptions as cycle 90's next step said.

- **Cycle 90**, 16 November 2026, from about 00:44Z (session
  `session_01SNkKxpfmJKpwccgABc1Cdi`, started by the Opus 5.5 launcher).
  Fresh container set up (M22). AD answered S1-R30 at 23:58Z (objection F
  is met at `904a3567`) and ended its turn; S2 marked
  P2-S2-home-3 ready at `823d2eac`. **Gate** (advisory) on home-3 at
  `823d2eac`: Hierarchy 3 of 3 pass, Character presence 3 of 3 pass
  (`docs/art/ui-quality/gate/verdicts/P2-S2-home-3/823d2eac.json`).
  **Requests copied:** S3-R15 (P2-S3-character-2 at `45ca3158`) to AD.
  **Restarted** AD (00:51Z, `session_01SNkKxp2nKS16efpGtUmaSG`) on
  S2-R25, then S3-R15, then P2-AD-board-4b. **Merged:** P2-S1-result-3
  as `19cfe498`, under the lock on candidate `8ec6a0fd` (result-3's
  `904a3567` with S1-R28's budgets: result/100 91 and result/200 99, with
  a raises entry); guard "ui guard: OK", check_all PASS at 01:22:36Z, M20
  met by AD's S1-R30 answer; the lock cleared in the same push (M17).
  S1 has no task. Seats: S2 (waiting on AD's S2-R25), S3 (working on
  character-2) and AD, three of four. **Next:** merge home-3 after AD
  answers S2-R25 (S2-R21's home/200 at 124 with a raises entry, S2-R23's
  exceptions); gate character-2 at `45ca3158` once S3 marks it ready and
  merge it after AD's S3-R15; P2-AD-board-4b now (AD), P2-AD-board-3b
  after home-3, P2-AD-board-5b after S3's two follow-ups; K1's requests
  wait for a K1 task.
- **Cycle 89**, 15 November 2026, from about 23:38Z (session
  `session_01SNkKxorJnFq3sLfbYDVUV8`, started by the Opus 5.5 launcher).
  Fresh container set up (M22). S1 passed its pre-check at `904a3567`
  and filed S1-R30 (AD's re-check of board 4's objection F) and a gate
  request. **Gate** (advisory) on P2-S1-result-3 at `904a3567`, result
  at 100% text: Hierarchy 3 of 3 pass, Character presence 3 of 3 pass
  (`docs/art/ui-quality/gate/verdicts/P2-S1-result-3/904a3567.json`);
  the samples' close point stays the reward tiles with no character art.
  **Requests copied:** S1-R30 and S2-R25 to AD; S2-R24, S2-R26 and S3-R9
  to S3-R14 to K1, waiting for a K1 task. **Started** AD (23:43Z,
  `session_01SNkKxnvq6vtnqW6Z4zLtBc`) in the fourth seat on S1-R30, then
  S2-R25 once S2 marks home-3 ready (M20); AD's prompt updated.
  **Merged:** none (result-3 waits on AD's answer to S1-R30; S2 is still
  pre-checking home-3 on `823d2eac`). Audit and roadmap unchanged (main
  did not move). Seats: S1, S2, S3 and AD, at the cap of four. **Next:**
  merge result-3 after AD's S1-R30 answer (S1-R28's budgets result/100
  91 and result/200 99, with a raises entry); merge home-3 after S2 marks
  it ready and AD answers S2-R25 (S2-R21's home/200 at 124, S2-R23's
  exceptions); P2-AD-board-4b once result-3 merges, P2-AD-board-3b after
  home-3, P2-AD-board-5b after S3's two follow-ups.
- **Cycle 88**, 15 November 2026, from about 22:39Z (session
  `session_01SNkKxqWhdKcPGLZVjTXGsX`, started by the Opus 5.5 launcher).
  Fresh container set up (M22). Claims copied (S3 claimed
  P2-S3-character-2 at 22:36Z). AD answered S2-R22 at 22:16Z: S2-R20's
  objections 1 to 5 stand as fixed, and new objections (a) to (e) go
  into home-3 before it merges (requests.md), so home-3 went back to
  `working`. AIA marked P2-AIA-motion-3 ready at `1157bfb4`; its five
  grayscale proofs `art/ui/proof/motion_gray/reward_*.png` (M21,
  reviewed by AD in AIA-R26) lay outside its `files`, so the lead added
  them as exceptions. **Merged** P2-AIA-motion-3: merge lock on
  candidate `b98da533` (main `2bca9108` + 1157bfb4), owners diff and
  claims clean, guard.sh OK, check_all PASS at 23:10:19Z; main had moved
  only with the lead's bookkeeping, so the merge went onto it with the
  docs check only: merge `746c0651`, lock cleared in the same turn. Audit and
  roadmap unchanged. **Restarted** S2 (22:44Z,
  `session_01SNkKxnhqmWB7hZwn9SeUuB`) on P2-S2-home-3 for (a) to (e);
  S2's prompt updated. Seats: S1, S2, S3 building; AIA's and AD's
  sessions idle; one seat free, kept for AD's re-checks (S1's F, then
  S2's (a) to (e)), as no other UI task has its deps met. **Next:** merge
  result-3 after F (S1-R28's budgets), home-3 after (a) to (e) (S2-R21,
  S2-R23); P2-AD-board-4b once result-3 merges, P2-AD-board-3b after
  home-3, P2-AD-board-5b after S3's two follow-ups.
- **Cycle 87**, 15 November 2026, from 20:39Z (session
  `session_01SNkKxqFHvZUY3kRm8JAVzo`, started by the Opus 5.5 launcher).
  Claims copied; S1-R29 and AIA-R26 answered by AD; S2-R21 approved
  (home/200 at 124, with a raises entry when home-3 merges); S2-R23
  granted (home-3's exceptions home_parts.gd and its .uid); S2-R22
  copied for AD; AD-R31 to AD-R37 (board 5's objections) answered by
  seeding P2-S3-character-2, P2-S3-settings-2 and P2-AD-board-5b. S2's
  advisory gate on `13ff046f` (home-3): Hierarchy and Character
  presence pass, 3 of 3 each; home-3 marked ready and waits on S2-R22
  (M20, due 16 November 07:55Z). **Restarted** AIA (20:45Z) on
  P2-AIA-motion-3 to merge main, run guard.sh and mark it ready.
  **Merged** P2-AD-board-5 (AD's `8b4b5827`): check_all PASS at
  22:31:32Z; main had moved only with the lead's bookkeeping, so the
  merge went onto it with the docs check only: merge `d74bbbdf`, lock
  cleared in the same turn. Audit and roadmap unchanged. **Started** AD
  (22:05Z) on S2-R22 in S2's freed seat (S2 idle with its task ready),
  and S3 (22:32Z) on P2-S3-character-2; the cap stays at four (S1, AIA,
  AD, S3). **Next:** merge result-3 after objection F (apply S1-R28's
  budgets, result/100 91 and result/200 99), motion-3 when ready, and
  home-3 once S2-R22 is answered or past due (apply S2-R21's 124 and
  S2-R23's exceptions); P2-AD-board-4b after result-3 and motion-3,
  P2-AD-board-3b after home-3, P2-AD-board-5b after S3's two follow-ups.
- **Cycle 86**, 15 November 2026, from 19:39Z (session
  `session_01SNkKxnnyaLSgG88hAKxd5z`, started by the Opus 5.5 launcher).
  Claims copied; S1-R28 approved (when result-3 merges, the lead records
  result/100 at 91 and result/200 at 99 in tools/ui_bake/budgets.json,
  with a raises entry); S1-R29 and AIA-R26 copied for AD. S1's advisory
  gate on `d896f254` (result at 100% text): Hierarchy 3 of 3 pass;
  Character presence split, 4 of 6 pass (weak point: the reward tiles
  hold currency icons with no character art). **Merged** P2-S3-settings
  (S3's `eb692c67`): check_all PASS at 20:11:03Z on candidate
  `0e2c553c` (the lock recorded `079d4487`, a stale candidate rebuilt
  before the checks), guard.sh OK (settings shots 48, 41 and 48 against
  52, 47 and 52); main had moved to the watchdog's `18fee078`
  (owner-inbox only), so the merge was redone onto it with the docs
  check only: merge `f6f9f71a`, lock cleared in the same turn. Audit and
  roadmap unchanged. The watchdog's 20:09Z alert (cycle 86 past its
  update time while the checks ran) needs nothing. **Started** AD on
  S3's freed seat (20:13Z) for the previews S1-R29 and AIA-R26 and
  M23's ack; the cap stays at four (S1, S2, AIA, AD). **Next:** merge
  result-3 (apply S1-R28's budgets), motion-3 and home-3 as they turn
  ready; P2-AD-board-4b after result-3 and motion-3.
- **Cycle 85**, 15 November 2026, from 18:01Z (session
  `session_01SNkKxqLYw4qY5UxycWNhTR`, started by the overseer after the
  owner's "Continue" of about 17:10Z). Fresh container set up (M22: the
  three rust targets, gdtoolkit 4, playwright 1.63.0, client/build.sh).
  Cycle 84's advisory verdicts carried to main (`fbdba3f3`): S3 settings
  on `f0a36a41`, all six rows pass; S2 home-3 on `14fdcdfe`, Hierarchy
  and Character presence pass. **Merged** P2-AD-board-4 (AD's
  `c0bab2a8`) and P2-K1-tabs (K1's `ba364ba8`) in one candidate
  (`9ee45863`): check_all PASS at 18:40:01Z, guard.sh OK (settings budget
  shots 49, 44 and 49 against 52, 47 and 52); merge `14be4ddd`, lock
  cleared in the same turn (`36e84c0a`). Audit and roadmap republished.
  **Started** four builders, the cap (order 3): S1 on P2-S1-result-3, S2
  on P2-S2-home-3 and AIA on P2-AIA-motion-3 (18:05Z, M14's rule in
  AIA's prompt, M21), S3 on P2-S3-settings (18:08Z); the stopped S2 and
  S3 sessions of 13 November are not reused. stop_at moved to
  17 November 21:00Z. **Next:** merge what turns ready (S3 settings and
  S2 home-3 likely first; M20 for screen tasks); P2-AD-board-4b waits on
  result-3 and motion-3, then AD takes a seat; AD and K1 are idle with
  nothing open.
- Cycle 83, 13 November 2026, from 11:38Z (session
  `session_01SNkKxn5sZ5Ez5cQQFwtAon`, started by the Opus 5.5 launcher):
  no merge (nothing ready); board 4's follow-ups filed; M22 acked.
  - **Fresh-container setup first** (M22, acked): the rustup targets, the
    pip packages, `bash client/build.sh` and `npm ci` in
    `tools/ui_research`, all exit 0 before any lock.
  - **Board 4** (AD, P2-AD-board-4 claimed 11:30Z, c0bab2a8): round 1
    does not stand, objections A to E (AD-R27, AD-R26, AD-R28, AD-R29,
    AD-R30). Defaults applied early (M18, as board 3's in cycle 80):
    P2-S1-result-3 (S1, 2h; A, B, D and E on the result screen),
    P2-AIA-motion-3 (AIA, 3h; C, and D's strip target in
    `motion_rig.gd`) and P2-AD-board-4b (AD, 1h; the re-check after both
    and board 4), inserted before P2-AD-board-5. Claims stay disjoint
    (`owners.py claims`). AD's pre-check runs; board 4 is docs and
    answers only and merges when ready.
  - **S2-R20 answered** by AD at 11:40Z: A and most of C stand on home-3;
    six objections (pins away from their islands, the world squeezed by
    the notice, Essence's 'Full' tag, the 200% strain chip, minor fits,
    and the dock label that is K1's in P2-K1-tabs). S2 takes 1 to 5
    inside P2-S2-home-3 before ready (its done_when, M12).
  - **Agents** (get_session, all idle in the working bucket, none past
    its expected update): AD (pre-check on board 4), K1 (check_all PASS
    on the merge 083a6fb1, guard.sh running, then ready), S2 (main merged
    at 14fdcdfe, pre-check and guard.sh next), S3 (pre-check on f0a36a41
    with the readout fix, then a gate_request). Claims copied: P2-K1-tabs
    and P2-AD-board-4 to claimed. Builders: AD, K1, S2 and S3, the cap of
    four; S1 and AIA start on result-3 and motion-3 as seats free. No
    session showed `allowed_warning`. No sessions created.
- Cycle 82, 13 November 2026, from 10:38Z (session
  `session_01SNkKxrMnNScoFR7y7AJx71`, started by the Opus 5.5 launcher):
  P2-S1-result-2 merged as `135a49b2`; S3's advisory gate fails Display
  type on the text-size readout; K1 and AD started, S2 restarted.
  - **Merge** (M17, M19, M20): AD answered S1-R25 at 10:05Z, all four
    objections fixed, so the lock was taken at `ad2df733` (10:43Z) on
    P2-S1-result-2 (ready e6b7dd74). The candidate, e6b7dd74 merged on
    that head plus S1-R26's budgets (result/200 98 with a raises entry,
    result/100 89, result/hc 27, and the check_screens figures), was
    `55a77882`. guard.sh OK (exit 0); check_all PASS at 11:22:10Z.
    Merged onto main's head as `135a49b2`, lock cleared in the same turn
    (`999db79f`). The audit and roadmap pages did not change.
  - **S3's gate, advisory** (P2-S3-settings at eed8b817;
    `verdicts/P2-S3-settings/eed8b817.json`, `ae09954e`): Hierarchy
    passes at 100% and in high contrast, and narrowly at 200% pt_BR
    (three of six fail: the "Ajustes" title barely larger than the
    "Acesso" pill, the tab strip first to the eye); Colour roles passes
    in high contrast. Display type fails three of three at 100% and at
    200% pt_BR: the text-size readout ("100%", "200%") is flat gold with
    no ink outline and no hard drop; the headers on plates now pass. The
    task stays with S3 to fix the readout and re-request the gate.
  - **Sessions:** K1 started on P2-K1-tabs in the free seat
    (`session_01SNkKxpiU2Mw9DcThCLnW1H`, 10:50Z). AD started after the
    merge (`session_01SNkKxnr3dQ98ULoLmDJcLd`, 11:23Z): S2-R20 first,
    then P2-AD-board-4 with AD-R26. S2 restarted
    (`session_01SNkKxquudGapkBBrdTGyQK`, 11:23Z): the last session sat
    idle from 09:55Z with its check_all on c0b2bc49 unreported, past its
    10:58Z update. S3 is running (guard.sh at 11:11Z). Builders: S2, S3,
    K1 and AD, the cap of four; S1 is idle with result-2 merged. No
    session showed `allowed_warning`.
  - **Requests:** S2-R20 (to AD) and AD's answer to S1-R25 copied; S2-R19
    default applied (the pt_BR goal string stays); AD-R26 default applied
    (into board 4). M21 acked.
- Cycle 81, 13 November 2026, from 09:38Z (session
  `session_01SNkKxmrBHkRN8tALzCsGkF`, started by the Opus 5.5 launcher):
  P2-AD-board-3 merged as `f5c9a801`, S1's advisory gate passes, AD
  started on S1-R25.
  - **Merge** (M17, M19): P2-AD-board-3 (ready 4a48eef9; docs and
    answers only). Merge lock taken at `c48c8563` (09:46Z); the
    candidate, 4a48eef9 merged on that head, was `0a3f5cad`. The first
    check run failed at 09:44:55Z on the fresh container (no
    wasm32-unknown-unknown target for std), not on the candidate; the
    rustup targets and pip packages were installed and the run restarted
    on the same sha. guard.sh OK (GUARD exit 0); check_all PASS at
    10:20:26Z. Merged onto main's head (lead-only commits since) as
    `f5c9a801` with the lock cleared in the same turn (one watchdog
    commit since). The audit and
    roadmap pages did not change.
  - **S1's gate, advisory** (P2-S1-result-2 at 71167028, result at 100%
    text; `verdicts/P2-S1-result-2/71167028.json`, `4ffffa75`):
    Hierarchy and Character presence pass, three of three each. The
    full-width gold Raid again leads in grayscale as clearly as the pass
    anchor's Level up; the three crew portraits read as faces in the toon
    look, larger than the pass anchor's.
  - **M20 acked**: result-2's merge lock waits for AD's answer to S1-R25
    or its due (14 November 09:22Z). AD started on S1-R25 in the free
    seat as `session_01SNkKxqeNV7VTwM6RkPTRHh` (09:44Z, effort high),
    then its next open task; the last AD session was idle after board 3.
  - **Requests:** S1-R25 (to AD) copied; S1-R26 approved (the lead
    records result/200 at 98, with a raises entry, and the lowered
    result/100 89, result/hc 27 and check_screens figures at result-2's
    merge); S1-R27 granted as exceptions (`client/scripts/result_fit.gd`
    and its `.uid` added to P2-S1-result-2); S3-R8 copied, the default
    stands (a later K1 task).
  - **Builders:** S1 (result-2, waiting on S1-R25), S2 (home-3), S3
    (settings) and AD, the cap of four; P2-K1-tabs waits for the next
    free seat. No session showed `allowed_warning`.
  - **Watchdog** (10:12Z, owner-inbox): lead.json was a few seconds past
    its 10:12Z, set before the check run; nothing started. The next step
    now says to set `expected_next_update_by` to at least a lock's expiry
    while a check runs.
- Cycle 80, 13 November 2026, from 08:38Z (session
  `session_01SNkKxorbtQPjVTWkgJKyfY`, started by the Opus 5.5 launcher):
  P2-S1-result-2's merge stopped before main moved on AD's S1-R24
  objections; board 3's follow-ups filed; S1 restarted, S2 started.
  - **Merge stopped** (M15, M19): result-2 (aed28321, advisory gate pass)
    was set ready and the lock taken at `bfe6d854`; the candidate was
    `a95cfd9a` (`7143af25`). The fresh container's tools were installed
    (rustup targets, pip packages, npm ci, client/build.sh). AD answered
    S1-R24 at 08:46Z with four objections to fix before the merge (the
    haul above the moment card at 200% pt_BR; rays, stars and glow off in
    high contrast; the multipliers pill on one line at 200% pt_BR; the
    rest line on two lines at 100%; the 52 pt faces stand), and result-2's
    done_when asks for that. The check run and guard.sh were stopped (the
    run reads LOST for a95cfd9a), the candidate worktree removed, the task
    put back to working under S1's claim and the lock released in
    `d17bce1c`. Main did not move; the audit and roadmap pages did not
    change.
  - **AD's answers** recorded in requests.md: S2-R18 (board 3), S1-R24
    (above) and S3-R7 (six objections, for S3 inside P2-S3-settings before
    its gate request).
  - **Board 3's follow-ups** (AD-R22 to AD-R25, defaults applied, M18):
    P2-S2-home-3 (S2, 3h; objections A to C on home-2's six files),
    P2-K1-tabs (K1, 1h; AD-R25 and the KitTabs part of AD-R24) and
    P2-AD-board-3b (AD, 1h; the re-check after both), inserted before
    P2-AD-board-4.
  - **Sessions** (`5654dca9` names their tasks in the prompts): S1
    restarted on result-2 as `session_01SNkKxn8w6ndc88LGhoq4KQ` (the last
    one idle at 126k context); S2 started on home-3 as
    `session_01SNkKxoy4LFKDybvN7vyFT5`. Both created at effort high.
    Builders: S1, S2, S3 and AD, the cap of four; P2-K1-tabs waits for a
    seat. The seven-day bar does not read `allowed_warning`.
- Cycle 79, 13 November 2026, from 07:38Z to 08:30Z (session
  `session_01SNkKxpZSJe4qP28t2awv1v`, started by the Opus 5.5 launcher):
  P2-S2-home-2 merged as `807d68a7`, two advisory gates, AD started on
  P2-AD-board-3.
  - **Merge** (M17, M19): P2-S2-home-2 (ready 3612e265, gate passed in
    cycle 78). Merge lock taken at `d76e2079` (07:43Z); the candidate,
    3612e265 merged on that head with S2-R17's records (home/100 and
    home/hc 145, home/200 114, and a raises entry), was `2e1ebe05`.
    guard.sh OK (GUARD_EXIT=0); check_all PASS at 08:22:10Z, run from the
    main checkout. Merged onto main's head (two lead-only commits since)
    as `807d68a7`, docs check clean, pushed with the lock cleared in the
    same turn (`abbe59eb`). S2-R17 recorded. S2 has no open task; its
    session stays idle. The audit and roadmap pages did not change.
  - **S1's gate, advisory** (P2-S1-result-2 at aed28321, result at 100%
    text; `verdicts/P2-S1-result-2/aed28321.json`): Hierarchy and
    Character presence pass, three of three each. Raid again leads by size
    and colour (narrower in grayscale than on the anchor); the three crew
    portraits read in the toon look.
  - **S3's gate, advisory** (P2-S3-settings at f5719f28;
    `verdicts/P2-S3-settings/f5719f28.json`): **Display type fails** at
    100% and at 200% pt_BR (the group headers 'Access' / 'Acesso' and
    'Seeing and comfort' sit on the starfield with a drop shadow, no ink
    outline; one sample saw the lower card's last row of labels clipped at
    200%), and **Hierarchy at 200% pt_BR fails** (the thin 'Ajustes' title
    is outranked in grayscale by the cream tab bar, the Stillness card and
    Voltar). Hierarchy at 100% split (pass, pass, fail), then passed five
    of six; high contrast passes Colour roles and Hierarchy. Shadow mode:
    `attempts` stays 0, as for every advisory fail so far; S3 takes the
    critique before ready, and every item goes on board 5.
  - **AD started** on P2-AD-board-3 as `session_01SNkKxoydJpnnk4xwpMmSj4`
    (08:23Z, effort high accepted), with the previews S2-R18, S1-R24 and
    S3-R7 to answer between boards. Builders: S1, S3 and AD (three, under
    the cap of four); no session showed `allowed_warning`.
  - **Requests:** S3-R6 granted (its shot script and
    `docs/art/shots/menu-screens/**` added to P2-S3-settings). S1-R23
    (to K1), S1-R24 and S3-R7 (to AD) copied.
  - **M18:** get_session on S1 (idle, its watch waiting on the gate), S2
    (idle, completed), S3 (idle, check-in at 08:13Z) and AIA (idle, no
    task): none needs a restart; the verdicts are on main for S1 and S3.
- Cycle 78, 13 November 2026, from 05:39Z to 07:00Z (session
  `session_01SNkKxo77VSsG6MDN6kJbhE`, started by the Opus 5.5 launcher):
  P2-S3-character and P2-S1-result-1 merged together as `f41d100e`,
  P2-AIA-motion-2 merged as `0bc0fbb9`,
  S1 and S3 started on their next tasks, S2's gate passed, S2-R17 approved.
  - **Batched merge** (M15, M17): P2-S3-character (ready 6f6a3b15, its
    advisory gate points taken) and P2-S1-result-1 (ready d0f4a899),
    disjoint claims. Merge lock taken at `61c4cb76` (05:49Z); the
    candidate, both merged on that head, was `f41d100e`. `owners.py diff`
    clean for both (S1's on the three-dot diff: its branch merged main
    before home-1, so the two-dot diff showed home-1's files). guard.sh OK;
    check_all PASS at 06:11:48Z, run from the main checkout; pushed to main
    as `f41d100e` and the lock cleared in the same turn (`df12e5f1`).
    S1-R19's default stands (result's record unchanged; check_screens
    passes either way).
  - **AIA's merge** (M17): P2-AIA-motion-2 (ready d0648763, its five
    shot scripts' `.gd.uid` companions granted as exceptions, by
    precedent). Merge lock taken at `c1a4e151` (06:17Z); the candidate,
    d0648763 merged on that head, was `0bc0fbb9`. `owners.py diff` clean.
    check_all PASS at 06:40:52Z, run from the main checkout. guard.sh
    failed twice on the container, not on the work: first the candidate
    worktree had no native library (character's shots, "no measure"; fixed
    with `bash client/build.sh` in the worktree), then the icon studio page
    timed out waiting for `window.ready` (the worktree had no
    `tools/ui_research/node_modules`, so three never loaded; fixed with
    `npm ci` there). The third run: every family rebakes byte for byte,
    check_screens and budget_shots OK, ui guard OK (06:52:57Z). Pushed to
    main as a fast-forward to `0bc0fbb9` and the lock cleared in the same
    turn. AIA has no open task; its session stays idle. Three builders
    run (S1, S2, S3).
  - **S1 and S3 started** (06:13Z, effort high accepted; both old sessions
    idle with their tasks merged): S1 on P2-S1-result-2 as
    `session_01SNkKxp1GYKSQAkZjfQC3vM` (its deps, result-1 and P2-K1-motion,
    merged; the prompt delivers M7 and M11 for its acks), S3 on
    P2-S3-settings as `session_01SNkKxrGTeWurPkRy5fVrtk`. With S2 and AIA
    that makes four builders, the cap; no session showed
    `allowed_warning`.
  - **S2's gate, advisory** (P2-S2-home-2 at 3612e265, home at 100% text;
    verdict in
    `docs/art/ui-quality/gate/verdicts/P2-S2-home-2/3612e265.json`):
    Character presence and Hierarchy pass, three of three each. The
    Keeper's portrait, about 110 px in its gold ring, reads as a figure in
    the toon look; Collect is the one large gold control and leads.
  - **Requests:** S2-R17 approved: when P2-S2-home-2 merges, the lead
    records home/100 and home/hc at 145 and home/200 at 114 in
    `tools/ui_bake/budgets.json`, with a raises entry for S2-R17; S2 may
    mark ready with guard.sh failing only on those lines. S2-R18 copied to
    requests.md; AD has no session, so its default stands at its due,
    11:39Z.
  - **Claims copied:** S2 (P2-S2-home-2, lease 08:23:34Z, pre-checking
    3612e265) and AIA (P2-AIA-motion-2, lease 07:48Z, ready d0648763 at
    05:46Z).
- Cycle 77, 13 November 2026, from 04:39Z to 05:25Z (session
  `session_01SNkKxq8jXKxVQg8t1Ub3bT`, started by the Opus 5.5 launcher):
  P2-S2-home-1 merged as `7e289af9`, S2 started on P2-S2-home-2, AIA restarted, two advisory gates, requests copied.
  - **Merge:** P2-S2-home-1, ready at 977edd5b (S2's pre-check PASS), as
    candidate 3d682157 on main's head (merge lock taken at 04:44:42Z,
    `580c9e4d`). At the merge the lead recorded S2-R16's raises in
    `tools/ui_bake/budgets.json`: shots home/100 and home/hc at 143 and
    home/200 at 112, with a raises entry for S2-R16, and the entries for
    `home.gd`, `screen_box.gd` and `universe_badge.gd` dropped, as S2's
    branch moved them. guard.sh OK on the candidate; check_all PASS at 05:20:17Z; merged as
    `7e289af9`.
  - **AIA restarted** on P2-AIA-motion-2 as
    `session_01SNkKxokBReWMyyoeH6tR9y` (04:45Z, effort high accepted): the
    last session (`session_01SNkKxpZQK5vjTDskqnfXsB`) went idle on
    AIA-R25 alone, with its checks passing at 7fd401e7, and its lease
    lapsed at 04:43:33Z. The task was set open with prior_branch
    `claude/ui-artist` at 7fd401e7. **AIA-R25's default applied early**
    (M15, as AIA-R23): AD has no session in the cap, so the strips stand
    as shot; any AD objection becomes a follow-up beside board 4. The new
    session claimed the task (lease 07:48Z) and was pre-checking its
    merge c8863682 (its commit of 04:52Z).
  - **Claims copied:** S1 (P2-S1-result-1, lease 06:08:36Z) pushed the
    gate's advisory points at 0a1a76fa (ink outlines on the words over
    art, display totals, the 3 s button grow). S3 (P2-S3-character, lease
    09:00Z) recorded its pre-check at 6f6a3b15 and asked for the gate.
  - **S2's gate, advisory** (P2-S2-home-1 at 977edd5b; verdict in
    `docs/art/ui-quality/gate/verdicts/P2-S2-home-1/977edd5b.json`): 4 of
    7 pass, every item three of three. Fails: Display type at 100% and
    at 200% (the headline currency counts are flat cream Manrope on dark
    plates, with no outline, hard drop or gradient; at 200% the
    'Guardião 24' header over the starfield has only a soft shadow), and
    Character presence (the only character is the small Keeper avatar,
    about 65 to 75 px). Passes: Hierarchy at all three settings (Collect
    leads) and Colour roles in high contrast. These are follow-ups for
    P2-S2-home-2.
  - **S3's gate, advisory** (P2-S3-character at 6f6a3b15; verdict in
    `docs/art/ui-quality/gate/verdicts/P2-S3-character/6f6a3b15.json`): 5
    of 7 pass. Fails, three of three: Display type at 100% and at 200%
    ('Skyskipper · Carrier'/'Carregador' and 'Level 3 of 10'/'Nível 3 de
    10' sit on the starfield with no ink outline, and the 'NV' tag runs
    over the badge edge; cycle 76's finding stands). Passes: Hierarchy at
    100% and 200%, Character presence, Colour roles in high contrast, and
    Hierarchy in high contrast at four of six (samples 1 to 3 split; two
    samples found the Level up bar mid-gray and about half the anchor's
    height under a heavier ability card, a follow-up).
  - **Requests copied:** S1-R21 (to K1: `Motion.reward`'s `top_level`
    layer draws under UI pages; S1's `_lift_reward` stands until the kit
    answers; due 14 November 03:47Z) and S1-R22 (to AD, preview before
    P2-S1-result-2's gate; due 14 November 03:47Z). K1 has no task and AD
    no slot, so each default stands at its due.
  - Builders: S1, S2, S3 and AIA make four, the cap; no session showed
    `allowed_warning`. No alert.
- Cycle 76, 13 November 2026, from 03:38Z to about 04:00Z (session
  `session_01SNkKxnLXN4d7GMy12F1W5F`, started by the Opus 5.5 launcher):
  no merge, two advisory gates, requests copied, M17 acknowledged.
  - **Claims copied:** S2 reclaimed P2-S2-home-1 (claimed 02:47Z, lease
    06:31:18Z; full checks running on d5465b92, then pre-check and ready).
    S1 (P2-S1-result-1, lease 06:08:36Z) and S3 (P2-S3-character, lease
    capped at 06:32Z, three hours from its last status) are working.
  - **AIA overdue:** its status (02:47Z, waiting on AIA-R25) promised an
    update by 02:51Z and none came; its lease on P2-AIA-motion-2 still runs
    to 04:43:33Z. Cycle 77 rechecks: if the lease has lapsed with no
    update, the task reopens with prior_branch `claude/ui-artist` at
    7fd401e7 and a fresh AIA session takes it.
  - **S3's gate, advisory** (P2-S3-character at f1251e68; verdict in
    `docs/art/ui-quality/gate/verdicts/P2-S3-character/f1251e68.json`):
    4 of 7 pass. Fails: Display type at 100% and at 200% pt_BR (outline
    the words over art, "Skyskipper · Carrier" and "Level 3 of 10"), and
    Hierarchy at 100% (pffffp; collapse the ability card or shrink its
    prose, and strengthen Level up). Passes: Character presence, Hierarchy
    at 200% and in high contrast (fpppff), Colour roles in high contrast.
  - **S1's gate, advisory** (P2-S1-result-1 at 8bec0d84; verdict in
    `docs/art/ui-quality/gate/verdicts/P2-S1-result-1/8bec0d84.json`):
    4 of 7 pass. Fails: Display type at 100% and at 200% pt_BR (outline
    HEIST COMPLETE, "Clean"/"Limpo", the subtitle, Entry fee and
    Re-simulated lines; give +2,310, +805 and +15 the display treatment;
    the "3 s" chip clips at 200%, let it grow with its text), and
    Character presence at 100% (crew portraits about 45 px against the
    anchor's 60; make them separate and larger, or put a character on the
    reward, as S1-R20 foresaw). Hierarchy passes at all three, Colour roles
    in high contrast. The gate is in shadow mode, so neither fail blocks
    a merge; each builder takes the cheap fixes before marking ready and
    lists the rest as follow-ups.
  - **Requests copied:** S2-R12, S2-R14 and S2-R15 (to K1; K1 has no task
    and no slot, so each default stands at its due 15:11Z). **Answered:**
    S2-R13 (the Keeper's portrait is the featherkin, the default) and
    S2-R16 (approved: the lead records home/100 and home/hc 143 and
    home/200 112 in `tools/ui_bake/budgets.json` when it merges
    P2-S2-home-1, in place of S2-R7's 139). S3-R5's due (04:45Z) passes
    with AD out of the cap; its default stands.
  - **M17 acknowledged:** batch ready tasks with disjoint claims, merge and
    clear the lock in the turn the check passes, run check_all from the
    main checkout.
  - Nothing ready, the merge lock is clear. Builders: S1, S2, S3 and AIA
    make four, the cap; no session showed `allowed_warning`. No alert.
- Cycle 75, 13 November 2026, from 02:38Z to about 02:50Z (session
  `session_01SNkKxozSRuvzVXmhKrTz3w`, started by the Opus 5.5 launcher):
  no merge, S2 restarted, requests copied.
  - **Claims copied:** S1 (P2-S1-result-1, lease 05:23:29Z) and AIA
    (P2-AIA-motion-2, lease 04:43:33Z) are working; S3's lease on
    P2-S3-character runs to 05:22Z.
  - **S2 restarted** on P2-S2-home-1 as `session_01SNkKxnuTWp4E5eG5m1dBtB`
    (02:43Z): the last session sat idle past its expected update (01:18Z)
    and its lease lapsed at 01:10Z, so the task was set open with
    prior_branch `claude/ui-screens-home` at 5164cc43. **S2-R11's default
    applied early** (M15, as AIA-R23 in cycle 72): AD has no session in the
    cap, so the stills stand. The new session takes cycle 74's advisory
    gate points (stale `art/ui/keyframes/01-home*.shot.json`, no character
    portrait, flat currency figures and name, the Heist tab not leading)
    where cheap, lists the rest as follow-ups, and marks the task ready.
  - **Requests copied:** S1-R15 to S1-R19 and S3-R3, S3-R4 (to K1; K1 has
    no task and no slot, so each default stands at its due); S1-R20 (to
    AD, preview before P2-S1-result-1's gate, due 14 November 02:23Z) and
    S3-R5 (to AD, the character stills, due 13 November 04:45Z). S3-R2's
    task (P2-S3-screenkit) has merged; its default stood.
  - Nothing ready, no gate request, the merge lock is clear. Builders: S1,
    S2, S3 and AIA make four, the cap; no session showed
    `allowed_warning`. The audit and roadmap pages did not change, so they
    were not republished. No alert.
- Cycle 74, 12 to 13 November 2026, from 23:39Z to 02:25Z (session
  `session_01SNkKxq74K4BtMR3MtbQTe1`, started by the Opus 5.5 launcher):
  three merges, three builders started, S2's advisory gate.
  - **S1 restarted** on P2-S1-toon-drop as
    `session_01SNkKxowrAJqRGxuKn8Tf1C` (23:41Z): the last session went idle
    waiting for the gate, whose advisory pass (cycle 73) lets S1 mark the
    task ready. It did, at 43f81a56.
  - **Merged P2-S3-screenkit** (ready cf4eecc2) as `70057394`, candidate
    `73b678eb`: guard.sh OK, check_all PASS at 00:16:51Z, the menu-screens
    stills granted to its files. S3 answered Lead-R1 (b657a59f): the
    settings shot records now come from the render itself, Game and
    Access.
  - **Merged P2-K1-motion** (ready b5d77219) as `ec2200b1`, candidate
    `6bbc1793`: claims checked, guard.sh OK, check_all PASS at 00:49:05Z.
  - **Merged P2-S1-toon-drop** (ready 43f81a56) as `c0aa1bd6`, candidate
    `47ac805e`: guard.sh OK, check_all PASS at 02:21:00Z (the first run
    failed on a read-only cargo lock because it was started inside the
    candidate's worktree, where `client/ext/target` is a link; re-run from
    the main checkout). S1's session is still running and builds
    P2-S1-result-1 on its branch past the ready commit; it claims the task
    now that toon-drop has merged, so no new S1 session was started.
  - **AIA-R25** (to AD, the motion strips before P2-AIA-motion-2 is ready,
    due 13 November 08:08Z) copied; AIA-R24's default stands (P2-K1-motion
    merged as K1 timed it); AIA-R22's due passed, its default stands (no
    tiled grain).
  - **Builders started** (Opus 5.5, effort high): S3 on P2-S3-character
    (`session_01SNkKxq23wc1i1XYqt7KM15`, 00:19Z, after screenkit merged)
    and AIA on P2-AIA-motion-2 (`session_01SNkKxpZQK5vjTDskqnfXsB`,
    01:41Z, after P2-K1-motion merged). Builders: S1, S2, S3 and AIA make
    four, the cap. No session showed `allowed_warning`. K1 has no open
    task; S2-R6, S2-R8, S2-R9 and S2-R10 wait for a K1 slot.
  - **Requests:** S2-R7 approved (home/100 and home/hc 119 to 139, logged
    in `raises`); P2-K1-motion has merged, so the lead writes the two
    records on P2-S2-home-1's candidate. S2-R5 granted for P2-S2-home-2
    (`universe_reward.gd` joins its files); its default stands for
    home-1. S2-R8, S2-R9 and S2-R10 (to K1) and S2-R11 (to AD, a preview
    of home before ready, default at its due 13 November 11:23Z) copied.
  - **S2's gate, advisory** (P2-S2-home-1 at 71d51d7f; home at 100%, at
    200% pt_BR and in high contrast; 21 samples, no splits; verdicts in
    `verdicts/P2-S2-home-1/71d51d7f.json`): Hierarchy fails on all three
    stills (no Collect; the small Heist tab is outranked by the raid
    banner's See button, the red raid card and the badged Islands tab),
    Character presence fails at 100% (no portrait: the avatar ring holds an
    emblem), Display type fails at 100% and 200% (the currency counts and
    'Keeper 14' are flat white, no outline, drop or gradient); Colour roles
    in high contrast pass 3-0. The stills were rendered at 71d51d7f because
    `art/ui/keyframes/01-home*.shot.json` still describe the old keyframe
    (Keeper 24, 'Collect all'); the crops were drawn by hand. Advisory: it
    blocks nothing; S2 gets the narrow points.
  - The audit and roadmap pages did not change, so they were not
    republished. No alert.
- Cycle 73, 12 November 2026, from 22:39Z to about 23:16Z (session
  `session_01SNkKxnQNXyshnSaWRSFz4A`, started by the Opus 5.5 launcher):
  the M16 fix, S1's advisory gate, S3 restarted.
  - **Claims copied:** K1 (P2-K1-motion), S1 (P2-S1-toon-drop) and S2
    (P2-S2-home-1) are working, with leases from their status files.
    **K1-R19 and K1-R20 granted:** P2-K1-motion's exceptions take the
    icon jsons, `kit.json`, `motion.json`, the ui_kit fixture and the
    motion shot. S2-R6 (to K1, default at its due, 13 November 22:52Z)
    and S1's second S1-R14 (to AD: a preview before the gate; default:
    the gate runs on a7dd6501) copied to `requests.md`.
  - **M16 acked and fixed:** `tools/test_run_checks.sh` now puts the
    case's name in each fixture commit, so two cases committed in the
    same second get different shas and never share a run directory.
    Candidate `220a00e5`: check_all PASS at 23:13:09Z (bwrap). Main had
    moved only with docs commits, so it went on as `6ca9c063`, its own test
    re-run (ok) and the docs check re-run. The merge lock is cleared.
  - **S3 restarted** on P2-S3-screenkit as
    `session_01SNkKxqkkDvs1XEigTTp6o5` (22:43Z). The last session went
    idle past its expected update (21:54Z) and its lease lapsed at 22:16Z.
    The new session answers Lead-R1 first, then marks the task ready.
    Builders: K1, S1, S2 and S3 make four, the cap. No session showed
    `allowed_warning`.
  - **S1's gate, advisory** (P2-S1-toon-drop at a7dd6501, heist at 100%
    text, Character presence; verdict in
    `verdicts/P2-S1-toon-drop/a7dd6501.json`): a split, then a pass, 2
    fails of 6. Ash's surface no longer drew a fail. Both fails read
    Bramble's and Hollow's portraits as flat vector fills next to the
    other three's soft-shaded renders. S1 may mark the task ready; the
    narrow point is in the critique.
  - No merge of a builder's task (none ready), no alert.
- Cycle 72, 12 November 2026, from 20:39Z to about 22:05Z (session
  `session_01SNkKxq8UPsw413Cqn38hyd`, started by the Opus 5.5 launcher):
  three merges, S3's advisory gate, AIA restarted, three builders started.
  - **M15 read and acked** (the owner's order of 12 November, about 20:00Z:
    the cap is four UI builders, three while the seven-day bar reads
    `allowed_warning`; batch merges as soon as two tasks are ready). No
    session showed `allowed_warning` all cycle.
  - **AIA restarted** on P2-AIA-motion-1 as `session_01SNkKxnSyJpXP86pzUyQUqT`
    (20:42Z). By M15 the lead applied AIA-R23's default ahead of its due:
    the sheet stands. AIA marked it ready at 49159bc0.
  - **Merged P2-S1-flow-replay** (ready b6a477f8) as `509c43c2`, candidate
    `ddc51ffa`, guard.sh OK. The first check_all failed only because the
    lead's container lacked the wasm32 Rust target and the Python tools.
    After installing them as the agents' setup line does, the re-run on
    the same sha passed. No test was changed.
  - **Batch-merged P2-flow-entry** (ready 2bf66433) as `62c66327` **and
    P2-AIA-motion-1** (ready 49159bc0) as `a43e4d5a`, by M15's batch rule.
    One candidate, `6fc96d56`: claims disjoint, guard.sh OK, check_all
    PASS at 21:59:44Z. `art/ui/proof/motion_sheet.png` joined motion-1's
    files (granted). The merge lock is cleared.
  - **S3's gate, advisory** (P2-S3-screenkit at 2b220cc3, settings at 100%
    text; verdicts in `verdicts/P2-S3-screenkit/2b220cc3.json`). Colour
    roles and value passed 3-0. Layered materials passed 4-2 after a
    split: the large Sound card has no frame or well. The crops
    were wrong: `05-settings.shot.json` gives the Access tab's controls,
    while `05-settings.png` shows the Game tab. **Lead-R1** to S3 (due 13
    November 09:45Z): fix the shot record, and say which tab the item
    shows, before ready.
  - **Requests:** S2-R3 answered with its default ('Crew: 0 of 3' under
    START THE HEIST). S2-R4 (to AD, due 13 November 08:15Z): flow-entry is
    merged, so its default applies; any objection from AD becomes a
    follow-up task beside P2-S2-home-1.
  - **Builders started** (22:02Z, Opus 5.5, effort high): S1 on
    P2-S1-toon-drop (`session_01SNkKxnTgyGWE1wfK5suMkd`), S2 on
    P2-S2-home-1 (`session_01SNkKxn7gvvhfq2Xjm1ocpN`), K1 on P2-K1-motion
    (`session_01SNkKxqeMVkQseRbMLW4q8r`). With S3 still on screenkit,
    that makes four, the cap. AIA, AIA-2 and AD are idle with their tasks
    merged. P2-AIA-motion-2 waits on P2-K1-motion.
  - **No alert** holds beyond those already listed.

- Cycle 71, 12 November 2026, from 18:39Z (session
  `session_01SNkKxr8rzRPkaA8ocqu69E`, started by the Opus 5.5 launcher):
  four merges, phase 2's remaining steps seeded, five sessions started.
  - **Merged P2-AIA2-busts** (ready 13e38050) as `fb07a2ce`. The merge lock
    is at `4d9f7379` and the candidate is `efefbeb7` on main `96dd6ba1`.
    The claims were disjoint, guard.sh was OK after `bash client/build.sh`
    in the worktree, and check_all passed at 19:11Z. Beyond the candidate's
    base, main had only the lead's docs/progress commits (`4d9f7379`,
    `537ccb76`, `b3426586`), which touch none of the candidate's files. So
    the merge went onto main's head, and the docs check was re-run there:
    clean.
  - **Merged P2-S2-flow-home** (ready 416449cc) as `7d899ce4`. The
    candidate is `1e438a19` (`efefbeb7` + 416449cc), and guard.sh was OK.
    The first check_all failed one fixture in `tools/test_run_checks.sh`
    ("and makes no worktree and no log"). S2 changes no runner file, and
    the test passed on `efefbeb7`. The likely cause is that the planted and
    refused test repos have the same tree and identity, so two commits in
    the same second share a sha. The re-run on the same sha passed at
    19:53Z, and no test was changed. The lock was extended in heartbeat
    `3c22038f`.
  - **Merged P2-S1-flow-result** (ready 8b47be96) as `9e1dd558`. The
    candidate is `1d6700ab` (`1e438a19` + 8b47be96), built while S2's
    check ran. Guard.sh was OK and check_all passed at 19:55Z. Main had
    only docs/progress commits beyond its base, so the merge went onto
    main's head, and the docs check was clean.
  - **The fixture in `tools/test_run_checks.sh` is flaky** (same-second
    commits of identical trees). It is noted for K1 or the lead as a test
    fix to make the two repos differ, never a loosening; until then, a
    lone FAIL of that fixture on a candidate that touches no runner file
    is re-run once.
  - **Requests:**
    - S3-R1 is granted.
    - S1-R13 is granted: `client/i18n/strings.csv` is an exception of
      P2-S1-flow-replay, for the RESULT_CONFIRMING row only.
    - S1-R14, AIA-R23 and S3-R2 (to AD) and AIA-R24 (to K1) are copied
      into requests.md. AD has no session in the cap, so their defaults
      apply at their due. AIA-R23 blocks P2-AIA-motion-1 until 01:05Z on
      13 November; AIA's session is waiting.
    - S3's status file read 19:40Z when it was pushed at 19:25Z; the lead
      took the push time for the claim's `seen_at`.
  - **Gate** (advisory, shadow mode; `verdicts/P2-AIA2-busts/13e38050.json`):
    heist at 100% text, Character presence. The first three samples split,
    1 pass to 2 fails, so three more were drawn. The six gave 2 fails, and
    a fail needs 4, so the item passes.
    - In all six samples, Bramble and Hollow read as figures against their
      rings (board 1's note G).
    - Both fails were on Ash's ember grain and eye highlights, read as a
      physically based finish. That is the narrow point for the next
      portrait pass.
    - P2-S2-flow-home has no gate items.
  - **The guard needs three.js in the merge worktree.** The first two
    guard runs on `efefbeb7` failed at "rebake": the icons_256 bake timed
    out on `page.waitForFunction`, because the worktree had no
    `tools/ui_research/node_modules`, and the bake page imports three from
    it. Linking the main checkout's `node_modules` into the worktree fixed
    it. Do the same before guard.sh in every merge worktree, and unlink it
    before `git worktree remove`.
  - **Seeded phase 2's remaining steps** (report.md section 3.3), 14 tasks:
    - motion art: P2-AIA-motion-1 and -2, P2-K1-motion;
    - the toon drop: P2-S1-toon-drop, for AIA2-R3;
    - the result screen: P2-S1-result-1 and -2;
    - home: P2-S2-home-1 and -2;
    - S3's screen kit, character and settings: P2-S3-screenkit,
      -character and -settings;
    - boards 3, 4 and 5.

    Board 2 is not seeded: it judges icon batches 3 and 4, which stay
    deferred (D13 (c)). **S3 is added to the roster**
    (`claude/ui-screens-meta`, prompt above).
  - **Requests answered:**
    - S2-R1 and S2-R2 are granted: `universe_badge.gd` and
      `universe_pins.gd` join P2-S2-home-1.
    - AIA2-R3 is answered with its default, task P2-S1-toon-drop.
  - **Sessions** (Opus 5.5, effort high accepted):
    - S1 was restarted on P2-S1-flow-result at 18:44Z
      (`session_01SNkKxpQyZFv1eTtnsa2WHD`): its expected_next_update_by of
      18:33:59Z had passed with the session idle.
    - AIA started on P2-AIA-motion-1 at 18:52Z
      (`session_01SNkKxnntrrTGLutdQgN4sk`).
    - S3 started on P2-S3-screenkit at 19:13Z
      (`session_01SNkKxnF4CGAt7d58kriezr`). S3's chain (screen kit,
      character, settings, board 5) is the longest left, so S3 takes the
      third place in the cap ahead of S2's next task.
    - S2 started on P2-flow-entry at 19:55Z
      (`session_01SNkKxozf5JRQDJPnSF8RWh`), after its last task merged.
    - S1 started on P2-S1-flow-replay at 19:56Z
      (`session_01SNkKxqKPyULbAiucFCfPRG`), after its last task merged.
      AIA is waiting on AIA-R23 with no session running, so its place is
      free.
    - The builders are S1, S2 and S3: the cap of three. AIA waits on
      AD's answer, and AIA-2 has no open task.
  - The launcher and the watchdog are enabled. The backlog has 89 tasks,
    61 merged. No owner-inbox entry. The audit and roadmap pages
    did not change, so they were not republished.
  - Next:
    - Merge P2-S3-screenkit, P2-flow-entry and P2-S1-flow-replay as they
      turn ready. On client candidates, run guard.sh after
      `bash client/build.sh` and the node_modules link in the worktree.
    - At AIA-R23's due (01:05Z, 13 November) or AD's answer, restart AIA
      on P2-AIA-motion-1 when a place in the cap is free.
    - Next in the queue: S2's P2-S2-home-1, S1's P2-S1-toon-drop.
- Cycle 70, 12 November 2026, from 16:38Z (session
  `session_01SNkKxpKUASWJcNRTsGDfsp`, started by the Opus 5.5 launcher):
  one merge, phase 2 opened, three sessions started.
  - **Merged P1-AD-board-1d** (ready 344353fe, pre-check PASS at 16:57Z)
    as `a154d246`: merge lock at `8b4faae6`, candidate `8a844628` on main
    `2c715c71`, `owners.py diff` clean, claims disjoint, check_all PASS
    at 17:45Z. Docs-only, so no guard. Main had only the lock commit
    beyond the candidate's base, so the merge went onto main's head.
    Lock released in the same push. The audit and roadmap pages did not
    change, so they were not republished.
  - **Board 1 stands** (board-1.md, Round 4): D and F closed; A, B, C and
    E were closed earlier. Note G (Bramble's and Hollow's features) does
    not hold the board.
  - **Phase 2 opened** (AD-R21's default): phase 1's exit criteria hold
    (report.md section 3.2). The kit families the heist uses and icon
    batches 1-2 are merged, the pilot heist passed the gate (advisory,
    shadow mode) and board 1 stands. The backlog's `phase` is 2, and every
    prompt below says Phase: 2.
  - **AD-R20 answered** as the default: P2-AIA2-busts (AIA-2,
    `client/world/creature_bust.gd`). **S2 added to the roster**
    (`claude/ui-screens-home`, prompt below) with P2-S2-flow-home, and
    P2-flow-entry moved from "any" to S2.
  - **Started three builders**, the cap of three, all at 17:47Z on
    Opus 5.5 with effort high accepted:
    - S1 on P2-S1-flow-result (`session_01SNkKxpXF5zd3wf5VZ65Utv`).
    - S2 on P2-S2-flow-home (`session_01SNkKxpNwGbxJdZihbsYFS5`).
    - AIA-2 on P2-AIA2-busts (`session_01SNkKxoqXe6HWeBBVJdS6Ru`).
    Before the starts, S1's last session and AIA-2's last session (a
    Fable 5.2 one, not reused) both read idle.
  - The launcher and the watchdog are enabled. The backlog has 75 tasks,
    58 merged. No owner-inbox entry.
  - Next:
    - Merge the flow tasks and the busts as they turn ready. Run guard.sh
      on client candidates, after `bash client/build.sh` in the worktree.
    - Then S1 takes P2-S1-flow-replay and S2 takes P2-flow-entry.
    - Seed phase 2's remaining steps (report.md section 3.3): AIA's
      motion art (step 8), the result screen (step 9), home (step 10),
      S3's character and settings (step 11), and boards 2-5. The cap of
      three stays, and icon batches 3 and 4 stay deferred (D13 (c)).
- Cycle 69, 12 November 2026, from 14:39Z (session
  `session_01SNkKxnAEyrHDn5aRYpjvTB`, started by the Opus 5.5 launcher):
  one merge, one session started.
  - **Merged P1-S1-pilot-5** (ready beb8a023; gate verdicts at
    `verdicts/P1-S1-pilot-5/beb8a023.json`, all pass, advisory) as
    `fe27c8f2`: merge lock at `3592745d`, candidate `2381087c` on main
    `8f4511ad`, `owners.py diff` clean, claims disjoint, check_all PASS
    at 15:28Z, ui guard OK (every budget shot within its record; heist
    119 of 120 draw calls at 100%). Main had only the lock commits beyond
    the candidate's base, so the merge went onto main's head with the
    docs check alone. Lock released in `cecf3a64`. The audit and roadmap
    pages did not change, so they were not republished.
  - The first guard run timed out (exit 124): the candidate worktree had
    no `client/bin/libruleborn_godot.so`, so every budget shot failed to
    compile, as cycle 53's note warns. After `bash client/build.sh` in
    the worktree the guard passed; the lock was renewed for the rerun
    (`d1d536b7`). This also closes cycle 68's note that guard.sh had not
    yet run on main after the SEC client commits.
  - **Started AD on P1-AD-board-1d** at 16:07Z
    (`session_01SNkKxrFqhFsxDUmtqPET8E`, Opus 5.5, effort high
    accepted): re-check objections D (Bramble and Hollow against their
    rings) and F on pilot-5's stills; if both close, board 1 stands and
    phase 2's flow tasks open. S1's session
    `session_01SNkKxn9y7QjFsFiRjgoaAP` is idle, its task merged; S1's
    next tasks (P2-S1-flow-result, P2-S1-flow-replay) wait on board-1d.
  - No new request. The launcher and the watchdog are enabled. One
    builder, under the cap of three. The backlog has 74 tasks, 57
    merged. No owner-inbox entry.
  - Next: merge board-1d when ready (docs-only, no guard needed). If
    board 1 stands, start S1 on P2-S1-flow-result and the other phase 2
    flow tasks within the cap of three; if D stays open, seed an AIA-2
    task for Bramble and Hollow at their source (S1-R12's default). Icon
    batches 3 and 4 stay deferred (D13 (c)).
- Cycle 68, 12 November 2026, from 13:39Z (session
  `session_01SNkKxnfPvJzu1iksNyMgNw`, started by the Opus 5.5 launcher):
  the gate for P1-S1-pilot-5, and S1 restarted; nothing merged.
  - **S1's pre-check passed** at `beb8a023` (exit 0) and it asked the
    gate for "heist at 100% text" and "heist at 200% text, pt_BR". The
    lead rendered both at `beb8a023` and ran the ui-judge (rubric v3,
    blind, shuffled pairs). Verdicts in
    `docs/art/ui-quality/gate/verdicts/P1-S1-pilot-5/beb8a023.json`:
    - 100%, Character presence: split, then **pass** at 3 fails of 6
      (a fail needs 4). Pip, Mo, Ash and the wizard read as framed toon
      figures; the samples split on Bramble and Hollow, now flat-painted,
      against their pale rings. Narrow: board-1d should re-check
      objection D.
    - 100%, Display type: **pass** (3 of 3). The timer's ink outline
      shows; "LAWS HERE" sits on the tag plate (objection F met).
    - 200% pt_BR, Display type: **pass** (3 of 3); "Alarme" and
      "~2.600" touch their frames, a layout note.
    The verdicts are advisory (shadow mode) and do not block the merge.
  - **S1 restarted:** its session `session_01SNkKxoXAbUvoLyhk2tDXzh`
    went idle at 13:04Z waiting for the verdicts, and its
    `expected_next_update_by` (13:49Z) passed. A fresh session
    `session_01SNkKxn9y7QjFsFiRjgoaAP` (Opus 5.5, effort high, the
    roster's prompt) reads the handoff, takes the verdicts and marks the
    task ready. The claim's lease follows S1's own (to 15:15Z).
  - No task is ready, so no merge lock was taken. No new request: S1-R1
    to S1-R12 are already in requests.md. Main had not moved before this
    cycle, so the pages were not republished.
  - The launcher and the watchdog are enabled. One builder, under the
    cap of three. The backlog has 74 tasks, 56 merged. No owner-inbox
    entry.
  - Next: merge pilot-5 when ready (owners diff, one full check at a
    time via tools/run_checks.sh, and guard.sh since it touches the
    client), then start AD on P1-AD-board-1d, which re-checks objection
    D. Icon batches 3 and 4 stay deferred (D13 (c)).
- Cycle 67, 12 November 2026, from 12:39Z (session
  `session_01SNkKxqJqzRbvVerXcUszbd`, started by the Opus 5.5 launcher):
  a bookkeeping cycle, nothing merged, no session started.
  - **S1 on P1-S1-pilot-5**, `working` (status 12:15Z, lease to 15:15Z,
    next update due 13:00Z): part 5 of the heist pilot written
    (`3690e4ca`); its pre-check failed one layout test (German "GESETZE
    HIER" on the tag widened the top row past 1080 px), fixed in
    `beb8a023` (a header wider than 80 points breaks between its words),
    and a second pre-check is running. Its session
    `session_01SNkKxoXAbUvoLyhk2tDXzh` reads working; not past its
    `expected_next_update_by`, so not restarted.
  - **New request S1-R12** (to the lead, not blocking): should AIA-2
    flat-paint Bramble and Hollow at their source? Recorded as the
    default in requests.md: the in-game flat pass stays as D's fix and
    the gate judges it; if the gate or board-1d leaves D open, the lead
    seeds an AIA-2 task then.
  - No task is ready and no gate request is open for an unmerged task
    (AIA's, AIA-2's, SV's and AD's status files still show merged
    tasks), so no merge lock was taken. Main did not move, so the pages
    were not republished.
  - The launcher (last run 12:39Z, succeeded) and the watchdog (last run
    12:12Z, succeeded) are enabled. One builder, under the cap of three.
    The backlog has 74 tasks, 56 merged. No owner-inbox entry.
  - Next: merge pilot-5 when ready (owners diff, one full check at a
    time, and guard.sh since it touches the client; guard.sh has not
    yet been run on main after the SEC client commits), then start AD on
    P1-AD-board-1d. Icon batches 3 and 4 stay deferred (D13 (c)).
- Cycle 66, 12 November 2026, from 11:39Z (session
  `session_01SNkKxqr3DC7Kb5YZfijUtN`, started by the Opus 5.5 launcher):
  a bookkeeping cycle, nothing merged, no session started.
  - **Claim recorded** from S1's status: P1-S1-pilot-5 `claimed`
    (claimed 11:28Z, lease to 14:28Z, next update due 12:08Z); its
    session `session_01SNkKxoXAbUvoLyhk2tDXzh` is working (prototyping
    the portraits' toon fills for objection D). Not past its
    `expected_next_update_by`, so not restarted.
  - No task is ready and no gate request is open for an unmerged task,
    so no merge lock was taken. No new request: S1-R1 to S1-R11 are
    already in requests.md.
  - The launcher (last run 11:38Z, succeeded) and the watchdog (last run
    10:09Z, succeeded) are enabled. Main did not move, so the pages were
    not republished. One builder, under the cap of three. The backlog
    has 74 tasks, 56 merged. No owner-inbox entry.
  - Next: merge pilot-5 when ready (owners diff, one full check at a
    time, and guard.sh since it touches the client; guard.sh has not
    yet been run on main after the SEC client commits), then start AD on
    P1-AD-board-1d. Icon batches 3 and 4 stay deferred (D13 (c)).
- Cycle 65, 12 November 2026, from 10:38Z (session
  `session_01SNkKxqZN7A6CTcTtr4tEcm`, started by the Opus 5.5 launcher):
  P1-AD-board-1c merged as `6ee0f7d3`; S1 started on P1-S1-pilot-5.
  - **Main had moved** by about 20 code commits from the security
    session (SEC-18 B to SEC-43, SEC-19 B's contained check runs,
    SEC-28's CI workflow, two client test fixes). The candidate's full
    check tested them together with board-1c.
  - **Candidate `906c5363` failed** check_all: gdlint reported "Cannot
    open file ... Read-only file system" 429 times. Cause: in a fresh
    container `~/.cache/gdtoolkit` does not exist, and SEC-19 B's bwrap
    run mounts HOME read-only, so lark cannot write its grammar cache.
    Fixed in `tools/run_checks.sh` (`a60576ff`): the contained run binds
    a fresh, writable cache folder there, as it already does for Godot's
    user folder. No check was skipped or loosened; the runner's
    self-test passes.
  - **Candidate `5e209009`** (main `a60576ff` plus ready `8bfb07bd`;
    owners diff clean) passed ("All checks passed.", DONE exit=0).
    Main had moved only by the lock commit, so it merged as `6ee0f7d3`
    after the docs check alone. Lock cleared.
  - **Board 1, round 3** (board-1.md): objections A and B closed; D (the
    portraits) and F (the header's ink outline) stay open, so board 1
    does not stand yet. AD-R17 and AD-R18 answered as the default: both
    go to S1 as **P1-S1-pilot-5** (heist_hud.gd is S1's file again).
    AD-R19 answered: the re-check is **P1-AD-board-1d** (deps pilot-5),
    and phase 2's four flow tasks now wait on board-1d.
  - **S1 started** on P1-S1-pilot-5: `session_01SNkKxoXAbUvoLyhk2tDXzh`,
    after its previous session was confirmed idle. One builder, under
    the cap of three. AD's session is idle, its task merged.
  - The launcher (last run 10:38Z, succeeded) and the watchdog (last run
    10:09Z, succeeded) are enabled. The audit and roadmap pages did not
    change, so they were not republished. The backlog has 74 tasks, 56
    merged. No owner-inbox entry.
  - Next: merge pilot-5 when ready (owners diff, one full check at a
    time, and guard.sh since it touches the client; guard.sh has not
    yet been run on main after the SEC client commits), then start AD on
    P1-AD-board-1d. Icon batches 3 and 4 stay deferred (D13 (c)).
- Cycle 64, 12 November 2026, from 09:39Z (session
  `session_01SNkKxqijuvwjXHbeAGDLGB`, started by the Opus 5.5 launcher):
  a bookkeeping cycle, nothing merged, no session started.
  - **Claim recorded** from AD's status: P1-AD-board-1c `claimed`
    (claimed 09:35Z, lease to 12:35Z, next update due 10:20Z); its
    session `session_01SNkKxmtatzN7YRTTZcPFsL` is working (rendering the
    stills on main for A, B, D and the header). `owners.py claims`:
    disjoint. Not past its `expected_next_update_by`, so not restarted.
  - No task is ready and no gate request is open for an unmerged task
    (K1's and S1's status files still show their merged tasks), so no
    merge lock was taken. No new request: every request in the status
    files is already in requests.md.
  - The launcher (last run 09:38Z, succeeded) and the watchdog (last run
    08:09Z, succeeded) are enabled. Main did not move, so the pages were
    not republished. One builder, under the cap of three. The backlog
    has 72 tasks, 55 merged. No owner-inbox entry.
  - Next: merge board-1c when ready; then S1 on P2-S1-flow-result and
    P2-S1-flow-replay (and the other phase 2 flow tasks) once board 1
    stands or its open objections are filed. One full check at a time
    (flaky.md). Icon batches 3 and 4 stay deferred (D13 (c)).
- Cycle 63, 12 November 2026, from 08:39Z (session
  `session_01SNkKxnWuvvM5evq2WinaFR`, started by the Opus 5.5 launcher):
  P1-S1-pilot-4 and P1-K1-numerals-on merged as `541e4c97`.
  - **Ready:** S1's pilot-4 at `e846c531` and K1's numerals-on at
    `1d21bf4a`. The lock (`cda39ca7`) named two candidates, `481254f9`
    (main + pilot-4) and `a4471d44` (`481254f9` + numerals-on). Owners
    checked: each diff only in its owner's files, budgets.json's change
    only the three heist records and their raises entry, heist_hud.gd
    only K1-R17's two changes.
  - **Checks:** the two candidates ran side by side from 08:47Z, against
    flaky.md's "Until fixed" rule. `481254f9` passed; `a4471d44` failed
    403 of 404 client tests, the settings test ("saved as they change and
    restored on the next launch"), because both runs share
    `user://settings.cfg`. Re-run alone, unchanged, it passed
    (`DONE exit=0`, "All checks passed.", 09:29Z). Recorded under
    flaky.md's first entry ("Seen again"); BT-10 is its fix task. The
    queue runs one full check at a time again.
  - **Gate (advisory, judge Opus 5.5, rubric 3):** pilot-4 fails
    Character presence at 100% text (3 of 3) and Hierarchy at 200% pt_BR
    with no crew plan (a split, 4 fails of 6); numerals-on fails Display
    type at 100% text (3 of 3): the timer is fixed (objection A met), but
    the "Laws here" header shows no ink outline. Advisory fails do not
    block a merge (pilot-3's precedent); the notes are in
    `verdicts/P1-S1-pilot-4/e846c531.json` and
    `verdicts/P1-K1-numerals-on/1d21bf4a.json`, and board-1c re-checks
    the header.
  - **Started:** AD on P1-AD-board-1c at 09:30Z, after the merge was on
    main (`ed6bcfdc`): `session_01SNkKxmtatzN7YRTTZcPFsL`, Opus 5.5 at
    effort high.
  - The backlog has 72 tasks, 55 merged. One builder running, under the
    cap of three. No new request; no owner-inbox entry. docs/audit and
    docs/roadmap did not change, so the pages were not republished.
  - Next: merge board-1c when ready; then S1 on P2-S1-flow-result and
    P2-S1-flow-replay. One full check at a time (flaky.md). Icon batches
    3 and 4 stay deferred (D13 (c)).
- Cycle 62, 12 November 2026, from 07:39Z (session
  `session_01SNkKxqEW3A3hwRz6VufQz5`, started by the Opus 5.5 launcher):
  a bookkeeping cycle, nothing merged, no session started.
  - **Claims recorded** from the status files: K1 on P1-K1-numerals-on
    (state `blocked` as K1's status says, on K1-R18, which cycle 61
    approved with M9; lease to 08:55Z; pre-check running at `ca66fe67`;
    its session `session_01SNkKxqEuMj3TF1SQMhjHgP` is idle between
    check-ins, its next update due 07:55Z) and S1 on P1-S1-pilot-4
    (working, lease to 09:55Z, last push `d62e2537` at 07:11Z: objections
    D and B built, FIT shots passing, the checks next; its session
    `session_01SNkKxnQXTay5oBDdKNoz8h` is running). `owners.py claims`:
    disjoint. Neither is past its `expected_next_update_by`, so neither
    was restarted.
  - No task is ready and no gate request is open, so no merge lock was
    taken. No new request: K1-R15 to K1-R18, S1-R8 to S1-R11 and AD-R13
    to AD-R16 are already in requests.md. AD has no open task until
    board-1c opens; AIA, AIA-2 and SV have none.
  - Main did not move, so the pages were not republished. Two builders,
    under the cap. The backlog has 72 tasks, 53 merged. No owner-inbox
    entry.
  - Next: merge numerals-on (budgets.json's change only the three heist
    records and their raises entry; heist_hud.gd only K1-R17's two
    changes) and pilot-4 when ready, then AD on board-1c. At most three
    builders; icon batches 3 and 4 stay deferred (D13 (c)).
- Cycle 61, 12 November 2026, from 06:39Z (session
  `session_01SNkKxrEkx6oXeGzdGm4sDr`, started by the Opus 5.5 launcher):
  P1-AD-board-1b merged; board 1 does not stand after round 2; two
  requests granted; S1 started on P1-S1-pilot-4.
  - **P1-AD-board-1b merged as `af14e1c7`** (ready `0387ca78`, docs
    only): check_all PASS on candidate `121464ac` at 07:27Z, `owners.py
    diff` clean, claims disjoint. Main moved during the check by
    bookkeeping commits only, so the merge went onto the new head and
    only the documentation check ran again. Board 1's round 2 leaves
    objections A, B and D and the 'Laws here' header open (AD-R13 to
    AD-R16).
  - **K1-R17 granted** (M8): `client/scripts/heist_hud.gd` is an
    exception of P1-K1-numerals-on, for `clock_label.visible = false` and
    AD-R14's header outline only, with no test changed. **K1-R18
    approved** (M9): the heist's draw-call records go up by 2 (120, 116,
    120; cap 150) for the header's drop, logged in `budgets.json`'s
    `raises`.
  - **P1-S1-pilot-4 seeded** (AD-R13, AD-R15: objection D, the
    portraits' L* step or ink silhouette; objection B, the tray at 200%
    pt_BR with no crew plan) and **P1-AD-board-1c** (AD-R16: round 3
    re-checks A, B, D and the header; deps numerals-on and pilot-4).
    Phase 2's four flow tasks now wait on board-1c.
  - Started S1 on P1-S1-pilot-4 (`session_01SNkKxnQXTay5oBDdKNoz8h`,
    Opus 5.5 at effort high). K1's own session continues: its check-in at
    06:54Z read the grant, and its 07:46Z check-in reads K1-R18's answer.
    AD has no open task until board-1c opens. Two builders, under the
    cap. The merge is docs only, so the pages were not republished. The
    backlog has 72 tasks, 53 merged. No owner-inbox entry.
  - Next: merge numerals-on and pilot-4 when ready, then AD on board-1c;
    phase 2 opens once board 1 stands. At most three builders; icon
    batches 3 and 4 stay deferred (D13 (c)).
- Cycle 60, 12 November 2026, from 04:38Z (session
  `session_01SNkKxp1vEH7M7oEGRULZPR`, started by the Opus 5.5 launcher):
  P1-S1-pilot-3 merged; three fixes to main; AD and K1 started.
  - **Main had failed check_all since the overseer's security commits**
    `c888bed7` (SEC-17) and `e39e9048` (SEC-30/SEC-29). Three candidates
    failed in turn, each on main's own breakage, not on pilot-3's
    content: `f6d39950` (sim test `an_exposure_above_i32_max_is_refused`
    not claimed in `sim/systems.json`), `5b6bac28` (`ERR_BAD_ROUTE` has
    no row in `client/i18n/strings.csv`) and `11d1b711` (gdlint: an
    unused variable's name in `auth_controller.gd`, a line over 120 in
    `security_tests.gd`). Fixed by lead commits `22d4328c` (the claim,
    under "Island bundles"), `77e48b27` (the words in every language)
    and `a13c5d07` (the bare call; the line split). No test loosened.
  - **P1-S1-pilot-3 merged as `085c812a`** (ready `0d142dd0`, board 1's
    objections A-E): check_all PASS at 05:32Z, ui guard OK, `owners.py
    diff` clean, claims disjoint. S1 marked it ready without the line
    `"numerals": true` (M7 not acknowledged; `kit_families.json` is
    main's), so it merged on S1-R11's default: stills with the switch
    off, objection A open. requests.md, S1-R11, records it.
  - Gate (advisory, rubric 3, 3 samples each;
    `verdicts/P1-S1-pilot-3/0d142dd0.json`): heist at 100% text: Display
    type fail (the 2:25 timer is flat dark figures on a cream plate; the
    "Laws here" header has no outline), Hierarchy pass, Character
    presence fail (Hollow's violet body melts into its ring; Bramble
    grainy). Heist at 200% text, pt_BR: Display type fail, Hierarchy
    pass.
  - **P1-K1-numerals-on seeded** (deps: pilot-3; K1; gate item: heist at
    100% text, Display type, with the switch on): the switch, every
    screen within its draw-call records, objection A's stills. Added to
    K1's Tasks line.
  - Started AD on P1-AD-board-1b (`session_01SNkKxpcpCTDib53apRny85`)
    and K1 on P1-K1-numerals-on (`session_01SNkKxqEuMj3TF1SQMhjHgP`),
    both Opus 5.5 at effort high; their last sessions were idle. S1 has
    no open task (its phase 2 tasks wait on board-1b). Two builders, under
    the cap. The pages did not change, so they were not republished. The
    backlog has 70 tasks, 52 merged. Owner-inbox entry on main's
    breakage.
  - Next: merge numerals-on and board-1b when ready (numerals-on's gate
    item shot with the switch on); then phase 2's flow tasks open. At
    most three builders; icon batches 3 and 4 stay deferred (D13 (c)).
- Cycle 59, 12 November 2026, from 03:41Z (session
  `session_01SNkKxpnpDTy3xKH1cD7N64`, started by the Opus 5.5 launcher):
  a bookkeeping cycle, nothing merged, no session started; one request
  answered.
  - S1 works on P1-S1-pilot-3 (session
    `session_01SNkKxp6HQPTjRP521X89Gw`, waiting on its check_all run;
    lease to 06:20Z, last push `0d142dd0` at 03:20Z): A to E built and
    noted; check_all on 75fb660a failed one layout test (the pre-landing
    tray at 1,129 px of 1,080 in pt_BR and pt_PT), fixed in a90ea011;
    check_all on a90ea011, the pre-check and the gate next. Not
    restarted. The claim's lease in the backlog moved to 06:20Z.
  - **S1-R11 answered** (blocking, due 10:46Z): granted.
    `client/ui/kit_families.json` is an exception of P1-S1-pilot-3 for
    the one line `"numerals": true` (K1-R11's answer adds the switch once
    the numerals' art passes the gate; kit-3's verdicts pass). check_all
    and guard run again with the line in, no test loosened; if either
    fails outside S1's files, S1 takes the default. Message M7 tells S1;
    requests.md, "Lead", has the answer. At the merge, check with
    `owners.py diff` that the file's change is that one line.
  - No task is ready and no gate request is open, so no merge lock was
    taken. AD's board-1b waits on pilot-3; K1, AD, AIA, AIA-2 and SV have
    no open task (their status files show only merged tasks). The
    leftover branch `lead/candidate-d7561425…` is cycle 16's and is
    stale. Main did not move since cycle 57, so the pages were not
    republished. One builder works (S1). The backlog has 69 tasks, 51
    merged. No owner-inbox entry.
  - Next: merge pilot-3 when ready (gate items: heist at 100% and at 200%
    text, pt_BR; render the stills on the candidate), then start AD on
    board-1b. At most three builders; icon batches 3 and 4 stay deferred
    (D13 (c)).
- Cycle 58, 12 November 2026, from 02:38Z (session
  `session_01SNkKxq63oZNWPm4cReDWcP`, started by the Opus 5.5 launcher):
  a bookkeeping cycle, nothing merged, no session started.
  - S1 works on P1-S1-pilot-3 (session
    `session_01SNkKxp6HQPTjRP521X89Gw` working, lease to 04:23Z, last
    push `74cd015e` at 02:17Z): A, C, D and E done; B's large-text layout
    done and check_screens OK, the heist/200 budget still reads 117
    against 115; then budgets, stills, pre-check and the gate. Not
    restarted.
  - No task is ready and no gate request is open, so no merge lock was
    taken. AD's board-1b waits on pilot-3; K1, AD, AIA, AIA-2 and SV have
    no open task. No new request (every request in the status files is
    in requests.md; none past due).
  - Main did not move since cycle 57, so the pages were not republished.
    One builder works (S1). The backlog has 69 tasks, 51 merged. No
    owner-inbox entry.
  - Next: merge pilot-3 when ready (gate items: heist at 100% and at 200%
    text, pt_BR; render the stills on the candidate), then start AD on
    board-1b. At most three builders; icon batches 3 and 4 stay deferred
    (D13 (c)).
- Cycle 57, 12 November 2026, from 01:39Z (session
  `session_01SNkKxoLAJu3YypfTqBzR97`, started by the Opus 5.5 launcher):
  a bookkeeping cycle, nothing merged, no session started.
  - S1's claim on P1-S1-pilot-3 recorded from its status file (working,
    lease to 04:23Z; A and E done, C, D and B next). Its session
    `session_01SNkKxp6HQPTjRP521X89Gw` is working, so it was not
    restarted. `owners.py claims`: disjoint.
  - No task is ready and no gate request is open, so no merge lock was
    taken. AD's board-1b waits on pilot-3; K1, AIA, AIA-2 and SV have no
    open task (their status files show only their merged tasks). No new
    request: S1-R8 to S1-R10 and AD-R7 to AD-R12 are already in
    requests.md, none past due.
  - Main gained three code commits from the overseer's security fixers
    since cycle 56 (`eeb33c9c`, `c888bed7`, `e39e9048`: SEC-47, SEC-17,
    SEC-30/SEC-29; sim, client data and auth files, none of S1's). They
    did not change the audit or roadmap pages, so these were not
    republished. pilot-3's candidate will be built on main's head as
    usual.
  - One builder works (S1). The backlog has 69 tasks, 51 merged. No
    owner-inbox entry.
  - Next: merge pilot-3 when ready (gate items: heist at 100% and at 200%
    text, pt_BR; render the stills on the candidate), then start AD on
    board-1b. At most three builders; icon batches 3 and 4 stay deferred
    (D13 (c)).
- Cycle 56, 12 November 2026, from 00:40Z (session
  `session_01SNkKxoW2tKv8QRKNSnU1yd`, started by the Opus 5.5 launcher):
  two merges in one candidate, six tasks seeded, one session started.
  - K1 marked P1-K1-heist-kit ready at e1cee5c1 and AD marked
    P1-AD-board-1 ready at 45d2c286; their claims were disjoint and
    `owners.py diff` was clean for both. Neither has gate items.
  - **Merged P1-K1-heist-kit and P1-AD-board-1** as `a01e4d6c`. The first
    candidate, 6766d05f, went stale during its checks: main gained 15
    security commits (SEC fixes, among them `owners.py` SEC-27/46 and
    `run_checks.sh` SEC-19, which now runs with `core.hooksPath=/dev/null`)
    from the overseer's desktop session `session_011GfsbJKS1vpggEBqbgYNLE`.
    Its runs were stopped; the candidate was rebuilt as 75593d76 on
    `f9994ecb`, the lock moved in `3ffa07f8`, and check_all PASS and
    guard.sh OK on it. Main then had only the lock commit beyond it, so
    the merges were redone on `3ffa07f8` and only check_docs_consistency
    was run again. No test was loosened (the removed lines are catalogue
    drawing code). The lock was released in `0beddac8`. The audit and
    roadmap pages did not change, so they were not republished.
  - **Requests answered** (requests.md, "Lead"): AD's blocking objections
    AD-R7 to AD-R11 (board 1's A-E) by P1-S1-pilot-3 (S1; it also owns
    `tools/ui_bake/budgets.json` for S1-R7 and `heist_hand.gd` for S1-R8)
    and AD's re-check P1-AD-board-1b. AD-R12's flow findings F1-F7 became
    phase 2 tasks: P2-S2-flow-home (F1, F2), P2-flow-entry (F3-F5, any
    maker), P2-S1-flow-result (F6) and P2-S1-flow-replay (F7), all
    waiting on board-1b. S1-R1 to S1-R6 were answered by heist-kit.
  - Started S1 on P1-S1-pilot-3 at 01:21Z
    (`session_01SNkKxp6HQPTjRP521X89Gw`, Opus 5.5, effort high accepted).
    One builder works; K1, AD and AIA have no open task. The backlog has
    69 tasks, 51 merged. No owner-inbox entry.
  - The lead's checkout is on a local branch `lead-main`: push with
    `git push origin HEAD:claude/videogame-project-analysis-ewkkk2`, not
    by the branch name, or git pushes a stale local ref and is rejected.
  - Next: merge pilot-3 when ready (gate items: heist at 100% and at 200%
    text, pt_BR), then start AD on board-1b. At most three builders; icon
    batches 3 and 4 stay deferred (D13 (c)).
- Cycle 55, 11 November 2026, from 21:38Z (session
  `session_01SNkKxnNomdRK7U7hfS4cvz`, started by the Opus 5.5 launcher):
  one merge, one gate run, one session started.
  - K1's claim on P1-K1-heist-kit recorded from its status file (lease to
    00:05Z). S1 marked P1-S1-pilot-2 ready at a4d87d18 at 21:43Z and asked
    for the gate; its new stills under `docs/art/shots/heist-pilot/**`
    were granted as an exception.
  - **Gate for P1-S1-pilot-2** (advisory, shadow mode; 3 ui-judge samples
    per item and quality, pictures shuffled; stills rendered on the
    candidate 134a0ddf), verdict in `39465f4`: heist in high contrast,
    Hierarchy pass and Colour roles and value pass; heist at 200% text,
    Hierarchy pass and **Display type fail** (3 of 3: the flat '2:25'
    timer has no ink outline, hard drop or gradient fill, and the crew
    names and 'Laws here' have no clear outline at 200%). As for pilot-1
    and kit-6, the fail is advisory and does not block the merge; AD's
    board (P1-AD-board-1) reviews it.
  - **Merged P1-S1-pilot-2** (ready a4d87d18) as `d880807e`: merge lock in
    `26e6c9a`, candidate 134a0ddf, `owners.py diff` clean, claims
    disjoint, check_all PASS, guard.sh OK, no test loosened. Main had
    gained only the verdict commit, so the merge was redone on `39465f4`
    and only check_docs_consistency was run again. The lock was released
    in this cycle's bookkeeping. The pages did not change, so they were not
    republished.
  - Started AD on P1-AD-board-1 at 22:16Z
    (`session_01SNkKxqUaNgqwmejJAEzasn`, Opus 5.5, effort high accepted).
    Two builders work (K1 and AD); S1 and AIA have no open task. S1's
    open requests S1-R1 to S1-R3 (kit_hud update calls, loot layout, law
    chip wrapping) are K1's in heist-kit, none blocking, defaults stand.
    The backlog has 63 tasks, 49 merged. No owner-inbox entry.
  - `run_checks.sh wait` can outlast a 10-minute foreground call (it was
    cut at 590 s while check_all still ran); wait on its log in the
    background instead.
  - Next: merge K1's heist-kit and AD's board-1 when each is ready. At
    most three builders; icon batches 3 and 4 stay deferred (D13 (c)).
- Cycle 54, 11 November 2026, from 20:39Z (session
  `session_01SNkKxqcjmNkScYYnT5Er2i`, started by the Opus 5.5 launcher):
  one merge, one session started, three requests recorded.
  - Claims recorded from the builders' status files: P1-K1-disc-host (K1,
    `claude/ui-bake`, lease to 22:58Z) and P1-S1-pilot-2 (S1,
    `claude/ui-screens-heist`, lease to 22:55Z). The idle queue's two
    items now name Opus 5.5 (order 5).
  - **Merged P1-K1-disc-host** (ready 62bbef35, no gate items) as
    `4dde8d03`: merge lock at `3d4acff1`, candidate on main's head,
    `owners.py diff` clean once the two Godot `.uid` companions of K1's
    new shot scripts (`ui_kit_round.gd.uid`, `ui_observatory_echo.gd.uid`)
    were granted as exceptions, as for earlier tasks; claims disjoint;
    check_all PASS; guard.sh OK; no test loosened (the two removed lines
    are catalogue drawing code). Lock released in `c4239219`. The audit
    and roadmap pages did not change, so they were not republished.
  - A fresh container lacks the tools: the first check_all failed on the
    missing wasm32 target and guard.sh on the missing Godot. Install them
    as the agents' prompts say (rustup targets, pip, `npm ci` in
    tools/ui_research, `bash client/build.sh`) in the lead's checkout, and
    run `bash client/build.sh` in the candidate worktree too before
    guard.sh, or every budget shot fails on the missing
    `libruleborn_godot.so`.
  - Requests from S1 (11 November, due 12 November 20:14Z, none
    blocking): S1-R8 (`heist_hand.gd` in S1's files; default stands for
    pilot-2), S1-R9 (gait and pause icons; default stands, icon art is
    AIA-2's and batches 3 and 4 are deferred), S1-R10 (`fx_portrait.gd`'s
    record to 19 draw; folded into P1-K1-heist-kit).
  - Started K1 on P1-K1-heist-kit at 21:16Z
    (`session_01SNkKxrLVEpoeqhNUMybpRi`, Opus 5.5, effort high accepted).
    S1 is still working on pilot-2 (pre-check on a4d87d18 running, then a
    gate request for the heist in high contrast and at 200% text). The
    backlog has 63 tasks, 48 merged. No owner-inbox entry.
  - Next: launch the gate on S1's gate request when it lands, then merge
    pilot-2 (S1 merges main first, as disc-host moved the goldens). Start
    AD on P1-AD-board-1 once pilot-2 is merged. At most three builders;
    icon batches 3 and 4 stay deferred (D13 (c)).
- Cycle 53, 11 November 2026, from 19:51Z (session
  `session_01SNkKxq9SSpFo8PxqxGC3p8`, started by the Opus 5.5 launcher;
  the first cycle on Opus 5.5 at effort high, order 5): one merge, two
  leases reopened, two sessions started.
  - Cycle 52 (Fable 5.2) took the merge lock for P1-AIA-kit-7 at 05:30Z
    and stood still on its seven-day limit; its gate verdict
    (`verdicts/P1-AIA-kit-7/961c7905.json`, advisory, four passes) was
    already on main. The lock expired at 06:30Z and was cleared
    (`2fccd5b2`).
  - The backlog's roster and every unmerged task now name Opus 5.5
    (`8bece1d8`). The leases of P1-K1-disc-host and P1-S1-pilot-2 lapsed
    with their Fable 5.2 sessions; both are open again with
    `prior_branch` and `prior_sha` (905f9fca on `claude/ui-bake`,
    38a154ea on `claude/ui-screens-heist`).
  - **Merged P1-AIA-kit-7** (ready 961c7905) as `6801e1ca`: candidate on
    main `8bece1d8`, `owners.py diff` clean, claims disjoint, check_all
    PASS, guard.sh OK. The first guard run failed (rebake: the icon bake
    timed out waiting for three.js) because the candidate worktree had no
    `tools/ui_research/node_modules`; after `npm ci` there it passed,
    byte for byte. Run `npm ci` in the candidate worktree before guard.sh.
    The audit and roadmap pages did not change, so they were not
    republished.
  - Started two Opus 5.5 sessions at effort high at 19:54Z (the
    `create_session` effort setting was accepted): K1 on P1-K1-disc-host
    (`session_01SNkKxqMwm4w36af9FQvXVB`) and S1 on P1-S1-pilot-2
    (`session_01SNkKxou5iRnrCMLMUqmcRa`). AIA has no open task. The
    backlog has 63 tasks, 47 merged. No owner-inbox entry.
  - Next: gate and merge disc-host and pilot-2 as they come ready, one at
    a time, disc-host first if both are ready (it touches the goldens and
    the bake stills; have S1 merge main). Start K1 on P1-K1-heist-kit
    once disc-host is merged, and AD on P1-AD-board-1 once pilot-2 is
    merged. Icon batches 3 and 4 stay deferred (D13 (c)).
- Cycle 51, 11 November 2026, from 01:11Z (session
  `session_01SNkKxnDPjsoJBxjS6oA73p`, started by the launcher; the first
  cycle after the restart, on Fable 5.2): no merge, two tasks seeded,
  three sessions started. Nothing was ready to gate or merge, no new
  request, no merge lock. Main's code moved only by the overseer's
  security fixes (`ca96667f`), so the pages were not republished.
  - Seeded two K1 tasks (`de49748e`): **P1-K1-disc-host** (critical; the
    skin's disc sprites are drawn as wide as their host, parts K23 and
    K45, pages 27, 44 and 45; a test that fails on main first, the three
    pages re-rendered in the eight variants, the six disc looks checked)
    and **P1-K1-heist-kit** (S1-R1 to S1-R6, after the disc fix; S1-R7
    waits). The backlog has 63 tasks, 46 merged. `owners.py claims`:
    the tasks in flight have disjoint files.
  - Every earlier session of AIA, K1 and S1 was idle (`get_session`) and
    is not reused. Started three fresh Fable 5.2 sessions at 01:15Z, the
    cap of three: AIA on P1-AIA-kit-7
    (`session_01SNkKxqH1rhueBqbuneEFSq`), K1 on P1-K1-disc-host
    (`session_01SNkKxpc8H8L5VAJUYuNCba`) and S1 on P1-S1-pilot-2
    (`session_01SNkKxqxd6Shqp4e1AafGUY`), which takes pilot-1's gate
    notes as its brief.
  - Next: gate and merge what comes ready (kit-7, disc-host, pilot-2),
    one merge at a time; disc-host touches the goldens and the bake
    stills, so merge it before pilot-2 if both are ready and have S1
    merge main. Start K1 on P1-K1-heist-kit once disc-host is merged,
    and AD on P1-AD-board-1 once pilot-2 is merged. Icon batches 3 and
    4 stay deferred (D13 (c)). The overseer may still land small fixes
    on main: fetch before a merge.
- Cycle 45, 9 November 2026, from 21:38Z (session
  `session_01SNkKxoFQJdmfH1eKm7DbKK`, started by the launcher; the first
  cycle after the restart, on Fable 5.2): two merges, one resync, three
  sessions started. Ran P1-AIA2-icons-2a's gate on `6a382d97` (Fable 5.2
  ui-judge samples, advisory): 12 of 12 pass, verdict in
  `docs/art/ui-quality/gate/verdicts/P1-AIA2-icons-2a/6a382d97.json`.
  The candidate of all three ready tasks (`3ebfb223`) failed guard.sh's
  rebake on `client/ui/art/icons_48_hc.webp` (piece `crew__pip__normal`):
  `art/ui/icons/studio/finish.js`'s `grow()` stamps with `drawImage` and
  the result differs between containers. That file is AIA-2's, so
  icons-2a went back as `resync` (reason in the backlog) to a fresh AIA-2
  session. kit-4 and words alone (`0fbb4723`): ui guard OK, check_all
  PASS at 22:22Z, owners diff clean, claims disjoint. Merged
  P1-AIA-kit-4 as `d2deb896` and P1-K1-words as `68cfd4e4`; lock
  released. Started AIA on P1-AIA-kit-5 (with kit-4's gate notes and the
  SKINS_OF reminder) and K1 on P1-K1-switch-heist. Three builders work,
  the cap. Both pages republished (audit version 218, roadmap version
  158). `stop_at` is 14 November 21:00Z.
- Cycle 46, 9 November 2026, from 22:39Z (session
  `session_01SNkKxoVXNfpAABNM81P62e`, started by the launcher):
  bookkeeping, one request answered, one early check. All three builders'
  sessions are working (`get_session`), none past its update time: AIA on
  P1-AIA-kit-5 (working, lease 01:25Z), K1 on P1-K1-switch-heist
  (claimed, lease 01:27Z), AIA-2 on the P1-AIA2-icons-2a resync (working,
  lease 00:54Z; grow computed on the pixels at `5ae7dbd5`, the atlases'
  import files at `ac4809ed`, pre-check running on `ac4809ed`, expected
  to end about 23:35Z). Claims copied to the backlog; owners.py claims
  clean. AIA-R17 granted with its default (requests.md): the batch 2b
  faces in `SKINS_OF` of `client/tests/ui_kit_tests.gd` are P1-AIA-kit-5's
  exception. Early check, not a merge check: in this fresh container
  (`npm ci` in tools/ui_research, then `node tools/ui_bake/bake.js
  icons_48 icons_256 kit --out <scratch>` one family at a time on the
  branch head `219ea6f0`), all eleven files, `icons_48_hc.webp` among
  them, match the committed ones byte for byte, so the reworked grow
  holds in a second container. No gate request, nothing ready, no merge
  lock taken, nothing merged, no session started, pages not republished,
  no owner-inbox entry.
- Cycle 47, 10 November 2026, from 01:51Z to about 03:00Z (session
  `session_01SNkKxqErNms87y9wMHpJWR`): two merges, one task seeded, three
  sessions started. All three builders were idle with work pushed:
  icons-2a ready at `ac4809ed`, kit-5 ready at `51269c72`, switch-heist
  blocked at `fd5cb0d2` on K1-R13 (the guard's rebake of
  `icons_48_hc.webp` on main, which icons-2a fixes). Gate (Fable 5.2
  ui-judge, three samples a quality, advisory): icons-2a 12 of 12 pass;
  kit-5 passes Layered materials, Display type and Light behind UI and
  fails Colour roles and value 3 of 3 (the main action's gold fill is
  also the selected segment, the selected chip, the claimed day tile and
  a chart bar; selection is told by hue alone; the school chips carry no
  school colour or shape). Verdicts in
  `docs/art/ui-quality/gate/verdicts/`. Candidate `5dabdc58` (main +
  icons-2a + kit-5): owners diff clean after kit-5's exceptions
  (`art/ui/kit_build/**`, `art/ui/palette.json`, `client/ui/art/kit_2*`,
  `kit_3*`), ui guard OK with the icon sheets rebaked byte for byte,
  check_all PASS at 02:47Z. Main moved to `027379a2`. A guard run in a
  fresh worktree needs `bash client/build.sh` there first (without the
  extension every budget shot fails with "no measure"). Requests
  (requests.md): K1-R12 granted (`client/ui/rb_box.gd` and
  `client/tests/ui_kit_tests.gd` are switch-heist's exceptions), K1-R13
  answered, K1-R14 part 3 and AIA-R18 go to P1-K1-switch-rest (files and
  done_when extended), K1-R14 parts 1 and 2 and the gate's notes on kit-5
  became the new task P1-AIA-kit-6. Started on Fable 5.2: AIA on kit-6,
  AIA-2 on icons-2b, K1 again on switch-heist (merge main, guard,
  pre-check, ready). The audit and roadmap pages did not change in this
  merge, so they were not republished. The watchdog's second cycle
  session of 01:51Z did no work.
- Cycle 48, 10 November 2026, from 03:38Z to about 07:40Z (session
  `session_01SNkKxqhTHTeKwMPJKdCubU`, started by the launcher; the
  session was paused from about 04:20Z to 06:50Z): two merges, two
  requests answered, three sessions started. icons-2b was ready: gate
  (Fable 5.2 ui-judge, three samples a quality, advisory) 12 of 12 pass,
  verdict in `docs/art/ui-quality/gate/verdicts/P1-AIA2-icons-2b/`;
  candidate `4058367a` ui guard OK, check_all PASS at 04:20Z; merged as
  `d30530ee`. AIA-R19 (wiring kit-6's skins) folded into
  P1-K1-switch-rest. switch-heist was ready: its diff to
  `client/tests/ui_kit_tests.gd` tightens the tests (exact SWITCHED_ON
  equality, a new `_parts()` test) and loosens none; candidate
  `f685870d` ui guard OK, check_all PASS at 07:32Z; merged as
  `3ac50485`. kit-6 was green at `00571a44` but blocked on AIA-R21:
  answered with its default (kit-6 is taken as ready without K1-R14
  part 1; disc_school stays in `art/ui/kit_next/`, unbaked and
  code-drawn; its bake is a later task, seeded when a screen asks), and
  AIA-R20 with its default (the kit stays at three pages; pill_gold_edge
  and green_muted stay code-drawn). kit-6's done_when and exceptions
  (`art/ui/kit_next/**`) and switch-rest's done_when and files are
  updated in the backlog. Started on Fable 5.2: AIA again on kit-6 (fill
  the handoff, mark ready, gate request), K1 on switch-rest, S1 on
  pilot-1 (its first session). AIA-2 has no open task (icon batches 3
  and 4 are deferred), so the builders are AIA, K1 and S1, the cap of
  three. The audit and roadmap pages did not change in these merges, so
  they were not republished. No owner-inbox entry.
- Cycle 49, 10 November 2026, from 07:38Z to about 07:55Z (session
  `session_01SNkKxonDy8BxQGiqJJMXsB`, started by the launcher): no
  merge; one gate, one message, one task seeded. Claims copied: K1 on
  switch-rest (lease 10:40Z), S1 on pilot-1 (lease 10:38Z); both
  sessions are running on Fable 5.2, and AIA's is idle with kit-6 ready
  at `00571a44`. Gate on kit-6 (Fable 5.2 ui-judge, three samples a
  quality, advisory): Display type, Colour roles and value (batch 2b's
  gold fault is fixed) and Light behind UI pass 3 of 3; Layered
  materials fails 3 of 3 (the album panel is a near-flat cream fill, the
  fact slips and plates have hairline rims, the success banner's glow
  bands at 60 and 120 pt); verdict in
  `docs/art/ui-quality/gate/verdicts/P1-AIA-kit-6/00571a44.json`.
  Candidate `37c28af0` (main `f8eba114` + kit-6): owners diff clean, ui
  guard OK, but check_all FAIL at 07:51Z, 394 of 395 client tests: the
  kit test that switch-heist tightened wants `KitSkin.OWN_SHAPE_ONLY`
  (nine materials, in `client/ui/kit_skin.gd`, K1's file) to equal the
  materials off their box's ground, and kit-6's atlas leaves only
  green_muted and pill_gold_edge there. kit-6's pre-check (04:14Z) ran
  before switch-heist was on main. So kit-6 was not merged and stays
  `ready`; no test was touched. Message M4 to K1 (backlog `messages`,
  and switch-rest's done_when): merge `origin/claude/ui-artist` at
  `00571a44` into `claude/ui-bake`, do the AIA-R19 wiring with
  OWN_SHAPE_ONLY brought to the atlas, and the lead merges kit-6 and
  switch-rest in one candidate. Seeded P1-AIA-kit-7 (batch 2d: the
  gate's notes on kit-6; names, sizes and margins of the baked pieces
  stay), deps kit-6, so no AIA session was started. The lock is
  released. The audit and roadmap pages did not change. No owner-inbox
  entry.
- Cycle 50, the final cycle, 10 November 2026, from 09:19Z to about
  10:33Z (session `session_01SNkKxnL64HmHVVoj2K58mZ`, started by the overseer by hand under the
  owner's order "Deploy and then stop cleanly"): started no session,
  seeded no task, touched no scheduled task. K1 and S1 had both stopped
  cleanly with their task ready before 09:45Z: switch-rest at `e012f9ff`
  (pre-check PASS 09:18Z; branch head `a2e75777`), pilot-1 at `5470c4d3`
  (pre-check PASS 09:31Z; branch head `376d86a9`). K1 acknowledged M5;
  S1's status file has no ack of M6 but S1 did what it says.
  First candidate `0e98262b` (main + `claude/ui-artist` at `00571a44` +
  `claude/ui-bake` at `e012f9ff`): owners diff clean for kit-6; for
  switch-rest it named the five kit files K1-R15 asks for and
  `client/tests/shots/ui_kit_rest.gd.uid`, all outside the task's
  list, granted as the task's exceptions (backlog). This container lacked the build tools at
  first, so the first check_all (no wasm target, E0463) and the first
  guard (`FAIL (rebake)`, the icon bake timed out without three.js)
  failed for the container, not the candidate; after the installs under
  "Tools in a fresh container", ui guard OK at 09:40Z and check_all PASS
  at 10:01Z. Merged P1-AIA-kit-6 and P1-K1-switch-rest as `e072364a`;
  AIA-R16, AIA-R18, AIA-R19 and K1-R14 part 3 are done with it
  (requests.md). K1-R16 answered with its default: album and fact stay
  out of `SKINS_OF`.
  Gate on pilot-1 at `5470c4d3` (Fable 5.2 ui-judge, three samples a
  quality, three more on a split, advisory), the heist at 100% and at
  200% text, eight qualities each: 4 of 16 pass. Pass: Layered materials
  at 100%, Painted or rendered icons at 100%, Light behind UI at both
  sizes, One art-direction idea at 200% (3 of 6 fail, one short of a
  fail). Fail: Display type at both sizes (the timer is flat, "Laws
  here" and the crew names have no ink outline, at 200% "Pip" is
  overlapped by Ash's portrait); Hierarchy at both (in grayscale the red
  Get out leads before the dark plum Cast); Colour roles and value at
  both (red fill on Get out while Alarm has none, no gold main-action
  fill, crew rings told apart by hue alone); Character presence at both
  (Hollow blends into its purple ring, Bramble is low in contrast);
  Layered materials at 200% (flat hint banner, Room panel without an
  inner well); Painted or rendered icons at 200% (Bloom is a tiny flat
  glyph, the Cast and Get out icons are gone); One art-direction idea
  at 100% (thin flat load bar, flat crew bars, hairline hint pill).
  Verdict in
  `docs/art/ui-quality/gate/verdicts/P1-S1-pilot-1/5470c4d3.json`. The
  gate is advisory and did not decide the merge; its notes are the
  brief for P1-S1-pilot-2 and for the kit work S1-R1 to S1-R7 ask of K1
  (requests.md).
  Candidate `6fb29341` (main `e072364a` + pilot-1 at `5470c4d3`): owners diff clean, claims disjoint, ui guard OK, check_all PASS at 10:33Z. Merged P1-S1-pilot-1 as `718ddcbe`; lock released.
  The audit and roadmap pages did not change and were not republished.
  No owner-inbox entry.
- Cycle 44, 4 November 2026, from 23:39Z (session
  `session_01SNkKxqKY1WGt7cJSaqyYtWj`, started by the launcher):
  bookkeeping and a diagnosis. All three builders are working (AIA
  kit-4 resync, pre-check on `f3456cac` to about 00:20Z; AIA-2 icons-2a
  at `6a382d97`, pre-check running; K1 words, no commit of code yet).
  Nothing ready, no merge lock, nothing merged, no session started, pages
  not republished. Backlog: K1's words and AIA-2's icons-2a copied to
  `working` with their claims; kit-4 `working` (lease kept at 03:00Z).
  Reproduced main's guard failure here: `node tools/ui_bake/bake.js
  icons_48` (after `npm ci` in tools/ui_research) rebakes `icons_48.json`
  and `icons_48.webp` byte for byte but not `icons_48_hc.webp`; two
  bakes in this container agree with each other, so the bake is
  deterministic per container and differs between containers. The only
  piece that differs is `crew__pip__normal` in high contrast: the
  committed file has a round ink ring with a white keyline; this
  container draws both rings as an octagon. That is `finish.js`'s
  `grow()` (hundreds of `drawImage` stamps of a silhouette) on pip, the
  one icon with its own `draw` (a WebGL render composited with an
  image). AIA-2's icons-2a branch does not touch `finish.js` or pip, so
  its candidate will fail guard the same way. No new owner-inbox entry
  (cycle 43's covers it). Cloud agent sessions cannot be messaged from a
  lead session (ListAgents lists none), so the finding waits for the
  resync.
- Next: when AIA-2 marks icons-2a ready, set it to `resync` (unless it
  already changed the finish) with this finding: make the outline and
  keyline grow independent of the canvas backend, for example a
  dilation computed on the pixels (`getImageData`, a disc of radius r)
  instead of stamped `drawImage` calls, rebake `icons_48*` and
  `icons_256*`, and show the rebake byte for byte in a fresh container
  (guard.sh). Merge kit-4 on ready once guard is green; if guard is still
  red only on `icons_48_hc.webp`, that file is AIA-2's and not kit-4's
  fault, but main still does not move on a red guard. Start AIA on
  P1-AIA-kit-5 after kit-4 merges, with the kit-4 gate notes (cycle 43).
  Never use Fable 5.1 (CLAUDE.md).

- Cycle 43, 4 November 2026, from 22:38Z (session
  `session_01SNkKxr5KfuQpAn8isazH9U`, started by the launcher): ran
  P1-AIA-kit-4's gate on `3eb4e200` (kit catalogue sheet, batch 2a; Opus
  5.5 ui-judge samples, advisory): Light behind UI passes; Layered
  materials (6 samples), Display type (6) and Colour roles and value
  fail (large panels flat with thin rims; same-rank titles treated
  differently; bronze and silver frames told apart by colour only).
  Batched P1-AIA2-icons-1b (`5ecb0202`) and P1-K1-catalogue (`ecec63dc`)
  on candidate `00e31ef0`: check_all PASS, guard.sh OK; merged as
  `90f72fd7` and `7e6de29d`. Started K1 on P1-K1-words
  (`session_01SNkKxo2gLyAa89sh1bYjJq`) and AIA-2 on P1-AIA2-icons-2a
  (`session_01SNkKxnB46NyYAV26hWtwrg`). Kit-4's candidate `050f2e10`
  (exceptions `art/ui/kit_build/**`, `art/ui/palette.json`,
  `client/ui/art/kit_2*`, kit-3's) failed check_all, 391 of 392: its
  nine skins have art but no SKINS_OF entry. guard.sh FAILED (rebake) on
  `client/ui/art/icons_48_hc.webp`, and main's own head `0a1a5eb0` fails
  the same way. The sources and file are unchanged since `00e31ef0`
  passed, but every bake since about 23:15Z drops the high-contrast halo
  and draws pip as an octagon, idle or loaded, so the icon finish still
  depends on the environment. Lock released. Kit-4 set to `resync` with
  the SKINS_OF block of `client/tests/ui_kit_tests.gd` granted, and AIA
  restarted (`session_01SNkKxpLGXniYM5JnmyzqE7`). Owner-inbox entry, no
  answer needed. Three builders, the D13 (c) cap. Pages republished.
  Godot's untracked .uid/.import files deleted, not committed.
- Next: nothing merges while main fails guard's rebake. Check
  P1-AIA2-icons-2a's candidate with guard.sh on ready; if
  `icons_48_hc.webp` still does not rebake, set it to `resync` with this
  finding (make the finish's halo and pip ring independent of the
  Chromium canvas backend). Merge kit-4 on ready once guard is green.
  Start AIA on P1-AIA-kit-5 after kit-4 merges, with the kit-4 gate
  notes: bevelled frame, inner well, gloss and lip for large panels; one
  outline and drop treatment per title rank; a shape mark (studs or
  pips) on the bronze and silver frames beyond colour. Never use Fable
  5.1 (CLAUDE.md).

- Cycle 42, 4 November 2026, from 21:38Z (session
  `session_01SNkKxnLzPFPR6HcJhTvYru`, started by the launcher): K1 was
  ready on P1-K1-catalogue at `71562ab1`. Granted
  `client/tests/shots/ui_kit_catalogue_art.gd` and its `.uid` (a helper
  split from the catalogue, owned by no other task) as the task's
  exceptions; owners.py diff then clean. Took the merge lock
  (`2d87db84`), built candidate `aa1ab0b0`: check_all FAIL, 391 of 392:
  the coverage test finds kit-3's twelve numerals (`num_gold_0` to `_9`,
  `_colon`, `_comma`, merged as `3f4766c7` after K1's resync) with art
  but no component in SKINS_OF. guard.sh stopped unfinished. Lock
  released, task set to `resync` (lease 5 November 01:00Z), K1 restarted
  (`session_01SNkKxqXv3kuBk7Uya8STrT`) with the failure lines.
  Owner-inbox entry, no answer needed. AIA-2 (icons-1b resync,
  pre-check running) and AIA (kit-4) still working: three builders, the
  D13 (c) cap. Nothing merged; pages not republished. Godot's untracked
  .uid/.import files deleted, not committed.
- Next: merge the catalogue before P1-AIA-kit-4 (rebuild the candidate,
  check_all and guard.sh; `npm ci` in tools/ui_research of the candidate
  worktree first). When kit-4 then merges, its new skins will lack SKINS_OF
  entries: grant those lines in `ui_kit_catalogue.gd` as kit-4's exception
  or send it to K1; never loosen the test. Merge AIA-2's icons-1b on
  ready. After the catalogue merges, start K1 on P1-K1-words. Never use
  Fable 5.1 (CLAUDE.md).

- Cycle 41, 4 November 2026, from 20:39Z (session
  `session_01SNkKxmc7wTBUoEfsJ3qwf9`, started by the launcher): ran
  P1-AIA-kit-3's gate on `3a04e828` (numerals sheet at phone size, 100%
  and 200% text; Opus 5.5 ui-judge samples, advisory): Display type and
  Colour roles and value pass 3 of 3. AIA-R15 filed with its default;
  AIA2-R2 closed with its default. Built a stacked candidate for
  icons-1b and kit-3: P1-AIA2-icons-1b's guard.sh FAILED (rebake:
  `client/ui/art/icons_48_hc.webp` is not what its sources bake to;
  main's icons rebake byte for byte, so the stale file is AIA-2's). Set
  icons-1b to `resync` and restarted AIA-2
  (`session_01SNkKxoAA41vxL7RwwKNRGN`) with the failure line. Checked
  kit-3 alone on candidate `ec84404b`: check_all PASS, guard.sh OK;
  merged as `3f4766c7`. Started AIA on P1-AIA-kit-4
  (`session_01SNkKxmbXiobGvGu7DHZRJZ`). Three builders (K1 catalogue
  resync, AIA-2 icons-1b resync, AIA kit-4), the D13 (c) cap. Pages
  republished. Godot's untracked .uid/.import files deleted, not
  committed. A push by mistake created a stray remote branch `main` at
  `2455f3b5` (deleting it was refused to the lead); start sessions on
  `claude/videogame-project-analysis-ewkkk2` by name, never on `main`,
  until the owner deletes it (owner-inbox entry).
- Next: merge K1's catalogue and AIA-2's icons-1b as each is ready again
  (rebuild the candidate, check_all and guard.sh); gate AIA's kit-4 on
  ready (kit catalogue sheet, batch 2a). Never use Fable 5.1 (CLAUDE.md).
- Cycle 40, 4 November 2026, from 19:39Z (session
  `session_01SNkKxqTNCgdepYrCx4541M`, started by the launcher): ran
  P1-AIA2-icons-1b's gate on `bef6eac2` (icon sheet, batch 1b, six icons
  at 48 and 96 pt and in grayscale; 12 Opus 5.5 ui-judge samples,
  advisory): Layered materials, Painted or rendered icons, Colour roles
  and value, and Light behind UI pass 3 of 3; icons-1a's fails do not
  recur. Verdicts and owner-inbox entry in `ecdff43a`, no answer needed;
  AIA2-R2 default applied (insight stays dropped from list.md, batch 1b
  closes at six icons). AIA-2 marks the task ready itself. Built
  P1-K1-catalogue's candidate `60d78155` (main + `c3a8b158`): guard.sh OK
  (after `npm ci` in tools/ui_research of the candidate worktree), but
  check_all FAIL, 391 of 392: the catalogue coverage test finds kit-2's
  skins (badge, bar_fill, bar_track, disc, locked, panel_dark,
  panel_glass, pill, selected, spinner) with art but no component in
  SKINS_OF, and locked__locked__normal and bar_track__bar_track__locked
  drawn from the code-drawn box. K1's branch predates kit-2 (`661f4f6a`).
  Set the task to `resync` (lease 23:00Z) and restarted K1
  (`session_01SNkKxorLGKFDuXX2ULtTU2`) with the failure lines. Three
  builders (AIA kit-3, AIA-2 icons-1b, K1), the D13 (c) cap. Godot's
  untracked .uid/.import files deleted, not committed. Pages not
  republished (main's code did not move).
- Next: merge K1's catalogue once it is ready again (rebuild the
  candidate, check_all and guard.sh); merge AIA-2's icons-1b on ready
  (gate passed); gate and merge AIA's kit-3 on ready (its gate item: numerals sheet at
  phone size, 100% and 200% text; Display type, Colour roles and value).
  Set `expected_next_update_by` past any merge lock. Never use Fable 5.1
  (CLAUDE.md).
- Cycle 39, 4 November 2026, from 18:38Z (session
  `session_01SNkKxoTLAFfAWjeMPjhfvd`, started by the launcher): ran
  P1-AIA-kit-2's gate on `fccd4b89` (contact sheets of the 23 batch 1b
  pieces; 12 Opus 5.5 ui-judge samples, advisory): Layered materials,
  Colour roles and value, and Light behind UI pass 3 of 3 (kit-1's
  Colour roles notes do not recur); Display type unknown 3 of 3 (no words
  on the pieces; exceptions queue, a split after 5 November 18:47Z).
  Owner-inbox entry, no answer needed. Merged kit-2 as `661f4f6a`
  (candidate `be0757d4`; check_all PASS, guard.sh OK; kit.json's
  `sources_hash` rebaked by bake.js, a merge exception; owners.py clean
  with the `art/ui/kit_build/**` and `art/ui/kit_next/**` exceptions).
  Started AIA on P1-AIA-kit-3 (`session_01SNkKxqGqwHJU12VPiWB68i`). K1
  (catalogue) and AIA-2 (icons-1b) still working: three builders, the
  D13 (c) cap. Godot's untracked .uid/.import files deleted, not
  committed. Pages not republished.
- Cycle 38, 4 November 2026, from 16:39Z (session
  `session_01SNkKxogLFWgTcU9Pd3EKdc`, started by the launcher): merged
  P1-K1-atlas-draw as `62188517` (candidate `a6212fcd`, ready at
  `2ae9c82c`; check_all and guard.sh PASS; kit.json's `sources_hash`
  rebaked by bake.js, a merge exception), with AIA-R13 and AIA-R14 folded
  into P1-K1-switch-heist first (`a5755db6`). Then merged P1-AIA2-icons-1a
  as `8ce107c9` (candidate `20a6a994`, ready at `cd30ce21`; check_all and
  guard.sh PASS, guard now rebakes kind "scene" itself, so the cycle 36
  substitute is retired; icons_48.json and icons_256.json conflicted on
  `sources_hash` only, taken from AIA-2 and rebaked by bake.js, a merge
  exception). Icons-1a merges behind its family switch with its advisory
  fails (cycle 37). K1-R10 done. Started K1 on P1-K1-catalogue
  (`session_01SNkKxnnyL6yNX5UpCnt8dH`) and AIA-2 on P1-AIA2-icons-1b
  (`session_01SNkKxnfqxoDcFwrXf6z7o8`). AIA is ready on P1-AIA-kit-2 at
  `fccd4b89`; its gate was not run this cycle (time). Three builders, the
  D13 (c) cap. Pages not republished.
- Next: run kit-2's gate (item "kit atlas contact sheet, batch 1b, at
  phone size"; Layered materials, Display type, Colour roles and value,
  Light behind UI; three samples each, Opus 5.5 ui-judge, advisory), then
  merge it and start AIA on P1-AIA-kit-3. Gate and merge K1's catalogue
  and AIA-2's icons-1b as they reach `ready`. Set
  `expected_next_update_by` past any merge lock. Never use Fable 5.1
  (CLAUDE.md).
- Cycle 37, 4 November 2026, from 15:39Z (session
  `session_01SNkKxngpz6t5F8cyrdiup4`, started by the launcher): merged
  P1-AIA-kit-1 as `5e5cccf9` (check_all PASS on candidate `103c569b`;
  owners.py clean once `art/ui/kit_build/**` was granted as an exception).
  guard.sh failed only its rebake step (kind "scene" icon families, as in
  cycle 36); with the substitute, kit rebaked with bake.js and both icon
  families with bake_icons.js, all nine files byte for byte. Gate (judge
  advisory, every quality owner-checked): kit-1 passes Layered materials
  and Light, fails Colour roles 3 of 3 (sand-gold second button family,
  teal focus on danger), Display type unknown 3 of 3 (blank plates;
  exceptions queue, a split after 5 November 15:46Z). Icons-1a
  (`c1d14d38`, carried to `5f759a03`, same pixels): Light passes; Layered
  materials, Painted icons and Colour roles fail 3 of 3. Owner-inbox entry,
  no answer needed. K1-R10 copied to requests.md. Started AIA on
  P1-AIA-kit-2 (`session_01SNkKxmwaE4rQY339ct2nz9`) with the Colour roles
  note. K1 (atlas-draw) and AIA-2 (icons-1a, gate requested at
  `5f759a03`, not yet ready) still working: three builders. Godot left
  icons_*.webp.import and a11y_motion_tests.gd.uid untracked after
  build.sh; the lead deleted them, not committed (their owners decide).
  Pages not republished.
- Next: gate and merge each task as it reaches `ready`. AIA-2's icons-1a
  verdicts are in (advisory, three fails): when it is ready, merge behind
  its family switch (report.md 3.8 item 5) unless the sha's pixels changed,
  in which case judge again. Keep the guard rebake substitute until K1's
  atlas-draw merges. Set `expected_next_update_by` past any merge lock.
  Never use Fable 5.1 (CLAUDE.md).
- Cycle 36, 4 November 2026, from 13:39Z (session
  `session_01SNkKxrLqp81CeCToVADsyb`, started by the launcher): merged
  P0-K1-kitspec-3 and P1-AIA2-toon-route in one batch as `9b2bde70`
  (check_all PASS; owners.py clean once
  `client/tests/shots/icon_portraits.gd.uid` was granted to the toon route
  as an exception, the P0-K1-kitskin precedent). guard.sh failed only its
  rebake step, because tools/ui_bake has no renderer for kind "scene"
  families yet; AIA2-R1's default applied: the lead rebaked the icon
  families with `art/ui/icons/studio/bake_icons.js` (after `npm ci` in
  tools/ui_research) and all six icon files matched byte for byte, and
  K1's P1-K1-atlas-draw now carries wiring kind "scene" into bake.js
  (AIA2-R1), with AIA-R9 and AIA-R12. K1-R9 done; AIA-R10 default stands.
  The watchdog's 14:13Z stale-lock alert resolved. Prompts now install
  three.js. Started K1 on P1-K1-atlas-draw
  (`session_01SNkKxrN8TYssSGXSznyneA`) and AIA-2 on P1-AIA2-icons-1a
  (`session_01SNkKxmwwK7YE4rm4Mh8nS1`); AIA still on P1-AIA-kit-1. Three
  builders, the D13 (c) cap. Pages not republished.
- Next: watch K1, AIA and AIA-2; gate and merge each task as it reaches
  `ready`. Until K1 wires kind "scene" into bake.js, substitute guard.sh's
  rebake step for icon families with bake_icons.js (`npm ci` in
  tools/ui_research first) and a byte compare. When taking the merge lock,
  set `expected_next_update_by` past the lock's expiry. S1 and AD wait on
  their deps and a free builder slot. If `stop_at` nears with work left,
  move it forward (order 3). Never use Fable 5.1 (CLAUDE.md).
- Cycle 35, 4 November 2026, from 12:39Z (session
  `session_01SNkKxofbM8PTQZdFF13dEe`, started by the launcher): phase 1
  started under owner order 3 (CLAUDE.md). Seeded 18 phase 1 tasks
  (`3939b11d`): K1's atlas-draw, catalogue, words and the two family
  switches; AIA's kit-1 to -5; the new agent AIA-2's toon route and icon
  batches 1a to 2b (batches 3 and 4 deferred, D13 (c)); the new agent S1's
  heist pilot 1 and 2 (Sonnet 5.5); AD's board 1. `phase` 1, `stop_at`
  2026-11-09T21:00:00Z. owners.py claims clean. Prompts updated (phase 1,
  new STOP_AT; AIA-2 and S1 added). Started three builders, the D13 (c)
  cap: K1 on P0-K1-kitspec-3 (`session_01SNkKxpvstSMYkV1wwCL3rU`), AIA on
  P1-AIA-kit-1 (`session_01SNkKxqU4sZmrYcBz3mbRR2`) and AIA-2 on
  P1-AIA2-toon-route (`session_01SNkKxnm9wVSENc6xKHm79A`). Nothing ready,
  nothing merged, pages not republished. Owner told (inbox, no answer
  needed).
- Next: watch K1, AIA and AIA-2; gate and merge each task as it reaches
  `ready`. S1 and AD wait on their deps (S1's pilot-1 on
  P1-K1-switch-heist and P1-AIA2-icons-1b); keep at most three UI builders
  at once, so S1 starts only when a builder slot is free. If `stop_at`
  nears with work left, move it forward (order 3). AD's golden set v2,
  rubric v4 and the `render` crop fix stay unfiled while the cap is full.
  Never use Fable 5.1 (CLAUDE.md).
- Cycle 34, 4 November 2026, from 11:39Z (session
  `session_01SNkKxqYuKcaV9WFPjR4eYL`, started by the launcher):
  bookkeeping only. No roster branch moved since cycle 27 (AD, AIA, K1
  and SV all `waiting` on tasks already merged; no new requests), no
  merge lock, nothing ready, nothing merged, pages not republished, no
  session started. The seven-day bar still reads `allowed_warning`
  (reset 2026-11-09T17:00Z).
- Next (owner order 3, CLAUDE.md, 4 November 2026): a usage tier is no
  longer a reason to pause. Start phase 1 now: seed phase 1's tasks
  (without icon batches 3 and 4), start K1 on P0-K1-kitspec-3 and the
  other agents as their tasks open, at most three UI builders at once
  (D13's answer (c)), and set a new `stop_at` for phase 1. The cycle 27
  rule below ("start no building session while the bar reads
  `allowed_warning`") no longer applies. Never use Fable 5.1 (CLAUDE.md).
- Cycles 28 to 33, 4 November 2026, 05:38Z to 10:40Z (sessions
  `session_01SNkKxqggtvFkbsicdmz58F`, `session_01SNkKxp3mbYDaJnVdPiRV3R`,
  `session_01SNkKxrFapFkzWn83y5X9ky`, `session_01SNkKxqLRk7TzD31oWv3kM6`,
  `session_01SNkKxo9TNVATJL3S4bNxyc`, `session_01SNkKxqdB4Qn1GGpgMJ8SUE`,
  all started by the launcher): bookkeeping only, each the same: nothing
  moved, nothing ready, usage in warning.
- Cycle 27, 4 November 2026, from 04:38Z (session
  `session_01SNkKxnqf4U1yn3FoEDAMTb`, started by the launcher): answered
  OV-R1 with [`usage-projection.md`](usage-projection.md). `/usage`
  cannot be read unattended; the seven-day bar reads `allowed_warning`
  (reset 2026-11-09T17:00Z). Phase 0 used about one weekly bar; phases 1
  to 3 need about four more, so the projection does not fit and D13's
  answer (c) applies (three builders, icon batches 3 and 4 deferred).
  Phase 0's exit criteria are all met. Owner alerted (inbox, 04:40Z; no
  answer needed). No roster status changed, no merge lock, nothing ready,
  nothing merged, pages not republished, no session started.
- Next: start no building session while the bar reads `allowed_warning`.
  After the reset: start K1 on P0-K1-kitspec-3, seed phase 1's tasks
  (without icon batches 3 and 4), set its `stop_at`, and re-measure the
  rate with one agent alone for its first 30 minutes. Never use Fable 5.1
  (CLAUDE.md).
- Cycle 26, 4 November 2026, from 03:39Z (session
  `session_01SNkKxn1EkNKS1Uoxxu2Lvn`, started by the launcher):
  bookkeeping only. No roster status changed since cycle 25 (AD, AIA, K1
  and SV all `waiting` on tasks already merged; no new requests), no
  merge lock, nothing ready, nothing merged, pages not republished.
  P0-K1-kitspec-3 (K1, open) stays unstarted: usage still reads
  `allowed_warning` (seven-day, resets 2026-11-09T17:00Z).
- Next: start K1 on P0-K1-kitspec-3 once usage allows; then decide on
  AD's golden set version 2 and rubric version 4. Never use Fable 5.1
  (CLAUDE.md).
- Cycle 25, 4 November 2026, from 02:39Z (session
  `session_01SNkKxnpW76h9UU2VzxnVPi`, started by the launcher): merged
  P0-AD-calibrate-2 (AD, ready at `8e4b808`). owners.py diff and claims
  clean; candidate `0e2a6317` passed check_all (03:15:33Z, "All checks
  passed."); main had gained only this cycle's lock commit, so the
  candidate went onto it as `0ff3278a` with the documentation check re-run.
  No guard: nothing under `client/` or `art/` changed. Results: Opus 5.5 is
  the judge; rubric version 3; the held-out run `held-opus` missed the
  target on all eight judged qualities, so all eight are owner-checked (AD
  checks each on every board; the judge's verdicts are advice).
  Pages not republished: the merge changed neither `docs/audit/`,
  `docs/roadmap/` nor their generators' sources, so the published pages
  already match main.
  AD's request on `results.jsonl` takes its default: the runs stay in
  `gate/calibration/runs/`. AD has no open task left (session idle, done).
- Filed K1-R9 (the overseer's follow-up to C74 and C75) as
  P0-K1-kitspec-3 for K1, open, about 0.5 h, documents and tokens.json
  notes only. Not started: usage still reads `allowed_warning` (seven-day,
  resets 2026-11-09T17:00Z), and it is not urgent. AIA's M1 ack is noted
  (owner inbox, 4 November 02:05Z).
- Next: AD proposes golden set version 2 (more passing items per quality,
  quality 3's relabel), then rubric version 4 and a fresh held-out run, and
  a fix to `render` leaving crops missing; not yet filed, since phase 0's
  close comes first and usage is in warning. Start K1 on P0-K1-kitspec-3
  once usage allows. Never use Fable 5.1 (CLAUDE.md).
- Cycle 24, 4 November 2026, from 01:39Z (session
  `session_01SNkKxperiwzZk3yVhDBHZf`, started by the launcher), the first
  cycle after the owner's restart: bookkeeping only. AD
  (`session_01SNkKxrEMe4td5Bk4zmN1Ed`, idle between turns, its own
  check-in due at 01:43Z to score) is still on P0-AD-calibrate-2,
  `working`, lease to 04:10Z: Opus-only runs dev-opus-v3 (426 calls) and
  held-opus (414 calls) pushed to `claude/ui-ad` (`1c886ca4`). AIA
  acknowledged M1 (`fd2620f2`), which closes the M1 item noted in the
  owner inbox on 31 October. No other roster status changed (AIA, K1 and
  SV status files still show tasks merged long ago), no merge lock,
  nothing to merge, pages not republished.
- Next: watch AD. When `status/AD.json` on `claude/ui-ad` shows
  P0-AD-calibrate-2 `ready`, gate and merge it (owners.py diff, check_all
  PASS), then republish both pages. Usage still reads `allowed_warning`
  (seven-day, resets 2026-11-09T17:00Z), so start no session beyond AD.
  Never use Fable 5.1 (CLAUDE.md).
- Cycle 23, 3 November 2026, from 11:39Z (session
  `session_01SNkKxoYmLFt1yB79vuEdqD`, started by the launcher):
  bookkeeping only. AD (`session_01SNkKxrEMe4td5Bk4zmN1Ed`) is working on
  P0-AD-calibrate-2: `status/AD.json` reads `working`, with dev-opus-v2
  (rubric version 2) results pushed to `claude/ui-ad` (`7f3945a0`, 309
  calls). No other roster status changed, no merge lock, nothing to merge,
  pages not republished.
- Next: watch AD. When `status/AD.json` on `claude/ui-ad` shows
  P0-AD-calibrate-2 `ready`, gate and merge it (owners.py diff, check_all
  PASS), then republish both pages. Usage still reads `allowed_warning`
  (seven-day, resets 2026-11-09T17:00Z), so start no session beyond AD.
- Cycle 22, 3 November 2026, from 11:08Z (session
  `session_01SNkKxp9qUS4iHzqFjbgh1C`, started by the launcher): `dev-fable`
  finished (`0e78b6ce` on `claude/ui-gate-runs`, 444 lines: 366 base calls
  plus 78 extra samples from the D-06 split rule, 6 unknown); its
  `dev-fable.jsonl` was copied to main (`720e309e`). Both development runs
  are now on main, so AD was started on P0-AD-calibrate-2
  (`session_01SNkKxrEMe4td5Bk4zmN1Ed`), told to take the extended
  `plan.jsonl` files (dev-fable +78, dev-opus +48 lines) from
  `claude/ui-gate-runs`. No status file changed, no merge lock, nothing to
  merge, pages not republished.
- Cycle 21 (06:38Z, session `session_01SNkKxodap1UHY9Fb2zQzaR`):
  bookkeeping only; `dev-fable` at 366 of 414.
- Cycle 20 (06:11Z, session
  `session_01SNkKxo6TYzdUtAL4USoPyt`, started by the watchdog): no lead
  cycle ran between 01:41Z and 06:11Z because the account hit its
  five-hour usage limit (owner-inbox, 06:10Z). Branches
  `claude/ui-screens` and `claude/ui-research` (not on the roster) are
  left alone.
- Cycle 19 (01:38Z, session `session_01SNkKxpMi6cZ8M6M33w8ntT`): dev-opus
  finished (`e3a9b94a`, 217 pass, 197 fail); its `dev-opus.jsonl` was
  copied to main.
- Cycle 18 (2 November 23:38Z, session `session_01SNkKxokCvaGUnmATx2vzaZ`):
  the first cycle after the owner's pause and resume; launched the two
  AD-R6 development gate runs on `claude/ui-gate-runs`.
- Cycle 17 (31 October 20:38Z, session `session_01SNkKxr25ThMqb9Aeot1dEV`):
  bookkeeping only; gate runs deferred while the seven-day usage read
  `allowed_warning`.
- Cycle 16 (19:38Z, session `session_01SNkKxrPXYJXnGbD1R9Zte3`):
  P0-K1-tokens-2 (785cb2a8) and P0-AD-calibrate (3f3797c7) merged as one
  batch candidate `d7561425` (check_all PASS, "ui guard: OK") onto main
  as `eec44b50`.
- Housekeeping: this cycle pushed a stray ref
  `lead/candidate-d756142555c04e567a54cc5367cc5b85edd99a7e` by mistake;
  the proxy refuses branch deletes (HTTP 403), so it stays. It points at
  the merged candidate and is harmless; candidates stay local from now on.
- Gap for the next SV task (or whichever task next touches
  `client/tests/`): `client/tests/a11y_motion_tests.gd` (SV-B11-B12) is on
  main without its Godot `.uid`, which every other test has tracked; any
  build regenerates it untracked (`uid://da3c5n2shdgh7` here). The lead
  does not commit it, since its bookkeeping touches only `docs/progress/**`.
- Cycle 15 (18:38Z) granted K1-R8 and restarted K1. Cycle 14 (17:39Z)
  merged O3 (`316ff98c`). Cycle 13 (15:39Z) merged P0-AD-golden-2
  (`520565f9`) and P0-AIA-board-4 (`f920b57b`). Cycle 11 (13:39Z) merged
  P0-AIA-keyframes-3 (`d0dd8a36`). Cycle 9 (11:39Z) merged P0-K1-tokens
  and P0-AIA-keyframes-2 (`b8308788`). Cycle 8 (08:38Z) merged O2-2 and
  P0-AIA-keyframes-1 (`fafc1a13`). Cycle 6 (04:38Z to 08:10Z) merged
  P0-K1-contract-2, P0-AIA-board-3 with P0-AD-golden, P0-K1-kitskin and
  SV-B11-B12.
- Earlier: cycle 4 (01:38Z) merged O2 and P0-K1-bake-2; cycle 3 (30
  October 23:22Z to 31 October 01:50Z) merged P0-AIA-board-2,
  P0-K1-bake-1, P0-AD-sheet and SV-B7-B9 and opened `flaky.md`; cycles 1
  and 2 (30 October) started and restarted the agents.
