# FX3 simulation fixes: progress

- Status: Waiting. FX1-9-tools-gate is ready at ad5e56bf (pre-check PASS at 07:23Z, recorded). FX3-7-audit-client-2 is ready at 1ecd419f.
- Progress: FX1-9-tools-gate fixed the six gate and coordination findings of FX1-7's tools audit (FX1-T-03 High; FX1-T-04, 09, 22, 08, 05) and FX2-R4's py() stdout fault. Each has a plain test in `server/test/fix_fx1_tools_gate.test.mjs`, committed alone before its fix and failing on main.
- Next: the lead's merges of FX1-9-tools-gate and FX3-7-audit-client-2. The lead regenerates `docs/audit/index.html` (FX1-T-22's source fix). FX3 has no further open task.
- Blocked by: none.
- Owner decision needed: none.

| Deliverable | Weight (h) | Status | Evidence |
|---|---:|---|---|
| FX3-1-heal-alarm: RB-28 and RB-29 | 3.0 | merged | lead cycle 158 |
| FX3-2-island: RB-40, RB-50, RB-57, candidates 7 and 34 | 4.0 | merged | `sim/src/tests.rs` `rb40_an_entrance_in_a_wall_or_on_the_vault_is_not_published`, `rb50_weaving_a_law_onto_the_vault_is_refused_and_keeps_the_law`, `rb57_a_ward_or_pylon_on_a_guard_in_tall_grass_replaces_the_grass_too`, `candidate_7_the_same_law_twice_is_not_published`, `candidate_34_a_tunnel_mouth_under_a_raised_wall_is_no_way_out`; `sim/src/island.rs`, `sim/src/path.rs`, `server/src/sim.mjs` |
| FX3-3-clock-report: RB-44, RB-45, RB-19 | 3.0 | merged | `sim/src/tests.rs` `rb44_a_split_and_rejoined_mite_does_not_hold_the_report_to_the_whole_clock`, `rb44_a_crossings_reports_count_only_the_crew_for_held`, `rb45_a_slowed_clock_still_catches_whoever_is_inside_at_the_last_tick`; `server/test/fix_fx3_older_build.test.mjs`; `sim/src/lib.rs`, `sim/src/universe.rs`, `server/src/sim.mjs` |
| FX3-4-lab-replay: RB-51, RB-52, RB-54, RB-55 | 3.5 | merged | `server/test/fix_fx3_lab_hints.test.mjs`; `sim/src/tests.rs` `rb54_a_tick_delta_past_u32_is_refused_not_wrapped`, `rb54_a_padded_varint_is_refused`, `rb55_a_command_for_actor_16_still_records_a_replay_that_round_trips`; `server/src/lab.mjs`, `sim/src/replay.rs`, `sim/src/lib.rs` |
| FX3-5-audit-sim: SIM-1 to SIM-9, the report's sim suspicions | 4.0 | merged | `docs/security/audit-2026-11/sim.md`; `sim/src/tests.rs` `sim_1_*` to `sim_9_*` (nine tests); `sim/test_tools.py` (SIM-3, SIM-4); `sim/src/lib.rs`, `sim/src/ffi.rs`, `sim/no_floats.py`, `sim/status.py`, `sim/run_spike.sh`, `sim/systems.json` |
| FX3-6-audit-universe: SIM-10 to SIM-13, `universe.rs`, `island.rs`, `grid.rs`, `sim/examples/` | 4.0 | merged | `docs/security/audit-2026-11/sim.md`; `sim/src/tests.rs` `sim_10_a_command_for_actor_16_still_records_a_universe_replay_that_round_trips`, `sim_11_a_lantern_wisps_reveal_goes_with_it_across_to_the_next_realm`, `sim_12_a_curated_layout_never_drops_a_woven_law_unseen`, `sim_13_moving_the_vault_onto_a_guard_hidden_in_tall_grass_takes_the_grass_too`; `sim/src/universe.rs`, `sim/src/island.rs`, `sim/systems.json` |
| FX3-7-audit-client-2: CLI-3, 8, 9, 16, 17, 19, 20, 21 settled; CLI-25 to CLI-34 | 3.0 | ready | `docs/security/audit-2026-11/client.md`; `client/tests/audit_client2_tests.gd` (18 checks, registered in `client/tests/run.gd`) |
| FX1-9-tools-gate: FX1-T-03, 04, 05, 08, 09, 22 and FX2-R4 | 4.0 | ready | `server/test/fix_fx1_tools_gate.test.mjs` (11 tests); `server/test/fix_fx1_audit_tools_proofs.mjs`; `tools/run_checks.sh`, `tools/check_all.sh`, `tools/check_dependencies.py`, `tools/audit_register.py`, `tools/check_ci.py`, `tools/coord/owners.py`, `docs/guides/agent-protocol.md`, `docs/security/audit-2026-11/tools.md` |

## Handoff
- FX1-9-tools-gate, ready (2026-11-24). Branch `claude/fix-sim`. Pre-check at ad5e56bf: PASS ("All checks passed.", 07:23Z, sandbox bwrap, recorded). The log shows the new step "the built pages carry no escaped markup (FX1-T-22)" passing. `ready_sha` ad5e56bf is in `docs/progress/status/FX3.json`. It merges main at `eb4b8e59` (lead cycle 172), with no conflict. After the merge I reran the fresh-container setup line (`rustup target add wasm32-unknown-unknown`, `pip install "gdtoolkit==4.*" "playwright==1.63.0"`), `bash client/build.sh` and the sim's WebAssembly build. Then `cd server && npm test` passed 666 of 666, and `bash tools/check_all.sh` ran as the pre-check: `run_checks.sh start`, `wait` in the background, `record ad5e56bf FX3`.
  - **Commits.**
    - Claim: 6c46a801.
    - The fail-first tests, all in one commit before any fix: 4fcb67a5.
    - The fixes:
      - FX2-R4: b37987d3;
      - FX1-T-03: ce84cfe2;
      - FX1-T-04: e64548f0;
      - FX1-T-09: a84687ea;
      - FX1-T-22: 2001157d;
      - FX1-T-08: f83a8454;
      - FX1-T-05: c55550b4.
    - tools.md States: be3badee. Merge of main: ad5e56bf.
  - **How each test failed on main** (at 4fcb67a5, whose tools are main's):
    - FX1-T-03, failed run: `record wrote a FAIL as {"sha":"…","exit":0,"finished_at":"…","summary":"== gdlint ==: skipped"}`.
    - FX1-T-03, passed run: `state` was `undefined`.
    - FX1-T-04: `a run that exited 101 reads {"sha":"…","state":"PASS","exit":0,…,"summary":"All checks passed.",…}`.
    - FX1-T-05: `overlaps missed: [false, false, false]`. Its disjoint-globs companion passes on main and still passes.
    - FX1-T-08: `[wide permissions, commented command] passed: [true, true, false, false, []]`.
    - FX1-T-09: `every gate command passed a stale file: [[0,0],false]`. The second value means the gate rewrote the file.
    - FX1-T-22, the gate's commands: `every gate command passed escaped markup: [0]`.
    - FX1-T-22, the order of the gate's steps: `check_all.sh has no plain build_stamp.py line`.
    - FX2-R4, a planted warning: `py() read undefined from: [1, 2]` followed by `SyntaxWarning: planted`.
    - FX2-R4, a tree with no cache: `py() read undefined from: "imported"` followed by `tools/check_document.py:505: SyntaxWarning: invalid escape sequence '\d'`.
    - FX1-T-11's stillOpen test also failed on main ("no longer fails"), because py() read the warning in place of the proof's value. It passes again after FX2-R4's fix.
  - **What changed.**
    - **FX1-T-03.**
      - `record` writes `state` and `exit`, and `exit` is 1 when the state is not PASS but the run exited 0.
      - The reuse rule in `agent-protocol.md` ("Reusing the builder's checks") now requires `state` `PASS`, `exit` 0 and the summary "All checks passed." at `ready_sha`.
      - **A precheck recorded before this fix has no `state` and is not reused.** That includes FX3-7's at 1ecd419f: the lead runs its own check for it.
    - **FX1-T-04.**
      - The detached runner writes a separate `check-<sha>.done` file holding its exit and the log's length at that moment.
      - `result` reads PASS and the summary only from that much of the log, so a leftover child that writes later cannot turn a failure into a pass.
      - The DONE line is still appended to the log, for readers.
    - **FX1-T-09.**
      - `check_dependencies.py --check` fails when `docs/design/dependencies.md` is not its rebuild.
      - The gate runs `--check` in place of `--write`. The committed page matches its rebuild today.
    - **FX1-T-22.**
      - The gate runs a plain `python3 tools/build_stamp.py` after `build_audit.py` and `build_roadmap.py`.
      - Its one hit on main came from the D50 edit text in `tools/audit_register.py`. That text put a `<code>` tag inside a field the page escapes; it now names the marker as plain text.
      - **The committed `docs/audit/index.html` still has the escaped tag.** It is not in this task's files. The gate rebuilds it before the new check, so the gate passes. The lead regenerates and commits it with `python3 tools/build_audit.py`, which changes two lines.
    - **FX1-T-08.**
      - `check_ci.py` parses the top-level `permissions:` block to the next top-level key, and requires exactly `{contents: read}`.
      - It counts a required command only on an uncommented `run:` line, single-line or block.
      - There are new self-test cases.
      - Not covered: a `permissions:` key inside a job is still not checked. A follow-up could refuse one.
    - **FX1-T-05.**
      - `_segments_meet` takes a segment's literal head and tail around any wildcard (`*`, `?`, `[..]`).
      - `files_overlap` gives each positive only the negations that follow it, as `owned()` does.
      - There are new self-test cases. `owners.py claims` still reports disjoint files.
    - **FX2-R4.** The proofs' `py()` parses the last line of stdout only.
      - The module now exports `TOOLS`, `run`, `py` and `checkRun` for the new test file.
      - `py(..., {fresh: true})` runs with an empty `pycache_prefix`, to reproduce a tree with no cache.
    - The six proofs left `PROOFS` in `fix_fx1_audit_tools_proofs.mjs`, and 16 remain still open. Each fixed entry in `tools.md` reads "fixed (FX1-9-tools-gate)", in the table and in the entry.
  - **Checks.**
    - Each tool's self-test passes: `run_checks.sh --self-test`, `bash tools/test_run_checks.sh`, `check_dependencies.py --self-test`, `owners.py --self-test` and `check_ci.py`.
    - `check_docs_consistency.py` finds nothing.
  - **Owners.** `owners.py diff FX1-9-tools-gate origin/claude/videogame-project-analysis-ewkkk2 ad5e56bf` reports "every changed path is inside its files".
  - **Next.** The lead's merge. FX3 has no further open task.
- FX3-7-audit-client-2, ready (2026-11-24). Branch `claude/fix-sim`. Pre-check at 1ecd419f: PASS ("All checks passed.", 05:04Z, recorded). `ready_sha` 1ecd419f is in `docs/progress/status/FX3.json`. It merges main at `85e5697e` (lead cycle 169), with no conflict. Locally, `python3 client/status.py` passes 486 of 486, `cd server && npm test` 631 of 631, `bash tools/check_all.sh` passes ("All checks passed.") and `check_docs_consistency.py` finds nothing.
  - **Commits.**
    - Claim: 111aa29d.
    - Proofs of the first pass's unproven findings: 585be289 (CLI-3, CLI-19, CLI-21; CLI-20 rejected), 153106cf (CLI-16, CLI-17), 9c1dbd59 (CLI-8, CLI-9). Write-up: 8c6391d0.
    - New findings CLI-25 to CLI-34, their checks and the write-up: 9c8c0bd3.
    - `client/tests/run.gd` kept within gdlint's 1000 lines: 9b65c40e. Main had it at exactly 1000; the new registration took it over, so one three-line comment became two and the registration has no comment of its own.
  - **The first pass's unproven findings.** All in `docs/security/audit-2026-11/client.md`.
    - Proven, open: CLI-3 (High: an offline heist plays three default crew and submits the planner's four ids, refused `crew_mismatch`), CLI-8, CLI-9, CLI-16, CLI-17, CLI-19 and CLI-21 (Medium).
    - CLI-8 and CLI-9: the client and the server are both wrong against the design. CLI-8: the observatory card and `service.mjs` `lease` name no owner, so the lease goes to `holders[0]`. CLI-9: `defences.mjs` gives the trace with no `across`. client.md's "Notes for other tasks" says what each side should send.
    - Rejected: CLI-20, with what was tried.
    - CLI-23 is not in this task (FX4-6 owns the ext); CLI-12 is RB-32, already on main.
  - **New findings.** Slice F of "What was read": `client/world/island_builder.gd`, `client/world/universe_island.gd`, every file in `client/ui`, `client/scripts/heist_screen.gd` 520-999.
    - Medium: CLI-25 (a Workshop island that does not load still takes orders and its reason is overwritten), CLI-26 (a held tap on the Vault offers gaits and Walk cracks it; the load target cannot be changed), CLI-27 (the held-tap menu is not modal), CLI-28 (`ColourCheck.lc_needed` gives Lc 60 to bold text at any size), CLI-29 (the Heart draws its Spire twice and moves its pin), CLI-30 (17 buildings and 16 spots: a full realm's eighth ward is not drawn).
    - Low: CLI-31 (the notice pulse overshoots and runs 500 ms), CLI-32 (a locked control still acts on ui_accept), CLI-33 (curtains hang from part of the rim), CLI-34 (the Heart's corner pool lies on the grid). CLI-31 and CLI-32 are latent: no screen calls `notice` or `locked` yet.
    - Smaller items not proven are under "Smaller, not proven", with why.
  - **Proofs.** 18 checks in `client/tests/audit_client2_tests.gd`, registered in `client/tests/run.gd`. Each is marked `# Audit finding CLI-N` and none is skipped. Each still-open check passes while its defect is there, and says to become a plain check once fixed.
  - **Nothing is fixed.** No file outside the task's files changed. `client/status.json` and `server/status.json`, which the runs regenerate, were restored.
  - **Still not read** (updated in client.md): the `client/scripts` other than the three read in full, and the `client/world` files not named in slices E and F.
  - **Owners.** `owners.py diff FX3-7-audit-client-2 origin/claude/videogame-project-analysis-ewkkk2 1ecd419f` reports "every changed path is inside its files".
  - **Next.** The lead's merge, and fix tasks for CLI-25 to CLI-34. FX3 has no further open task.
- FX3-6-audit-universe, merged (lead cycle 169, 5293e6b7). Ready (2026-11-24). Branch `claude/fix-sim`. Pre-check at 92dda030: PASS ("All checks passed.", 01:36Z, recorded). `ready_sha` 92dda030 is in `docs/progress/status/FX3.json`. 92dda030 merges main at `bc7f27e8` (lead cycles 168 and 169, the FX2-7 merge), with no conflict. The later commits are docs/progress only, so the pre-checked sha stays the ready one. The local `bash tools/check_all.sh` also passed.
  - **Commits.**
    - Claim: 18c7bd83.
    - SIM-10: fail-first test d8e552a1, fix 537bf425.
    - SIM-11: fail-first test 197dd630, fix 9f99e5d8.
    - SIM-12: fail-first test d4bc63d0, fix 57cd912a.
    - SIM-13: fail-first test be1a47d3, fix 6e28d564.
    - Write-up: f1e272db.
    - Each test fails on main at `1c4fd104`, the branch point.
  - **Findings.** They are in `docs/security/audit-2026-11/sim.md`, in the report's format.
    - SIM-12 (Medium): `Island::curated` wove the laws before it placed the buildings. A building whose footprint covered a pylon spot lifted the pylon, and its law with it, while the layout still published. The server's `problems()` checks only that every island law is in the woven set, not the reverse, so it did not catch this. The fix places the buildings first.
    - SIM-10 (Low): `record_universe` kept commands for actor 16 and above. The replay packs the actor in four bits, so such a command was recorded as actor 0. This is RB-55's defect in the universe recorder. Those commands are now dropped.
    - SIM-11 (Low): `Crossing::go` started each realm with no reveals, so a Lantern wisp's reveal ended at a link. The next realm now inherits them.
    - SIM-13 (Low): moving the Vault onto a guard hidden in tall grass left the grass behind. This is RB-57's defect in `set_vault`. The fix now clears the grass too.
  - **Left for the lead.** Both are in `requests`.
    - FX3-R2: SIM-12's server-side check. The sim can still lose a law unseen in three cases: more laws than pylon spots, an unknown law id, or 64 failed draws. A check at curated publish would catch all three.
    - FX3-R3: the device's universe recorder (`client/ext`) has no 2 KB check. It has the same gap SIM-2 found in the device's single-island recorder.
  - **Unproven.** sim.md's FX3-6 Unproven entry lists each item with what was tried:
    - a ward's delayed effect at a crossing;
    - several digests for one universe;
    - several Land commands at tick 0.
  - **Still not read** (updated in sim.md):
    - `replay.rs` and `heist.rs` beyond the parts called;
    - the generated `laws_table.rs` and `sin_table.rs`;
    - the client ext and the server's `curation.mjs`, `crossings.mjs` and `universe.mjs`, read only where the findings led.
  - **Goldens.** No fix changes a golden outcome, and no `sim/golden/*.rbh` was rebaked.
  - **No existing test was changed.**
  - **Owners.** `owners.py diff FX3-6-audit-universe origin/claude/videogame-project-analysis-ewkkk2 92dda030` reports "every changed path is inside its files".
  - **Next.** The lead's merge.
- FX3-5-audit-sim, merged (lead cycle 167, 490579d6).
  - Ready (2026-11-23). Branch `claude/fix-sim`. Pre-check at c333f546: PASS ("All checks passed.", 22:24Z, recorded); `ready_sha` c333f546 is in `docs/progress/status/FX3.json`. Main merged at c333f546 (lead cycles 165 and 166, docs/progress bookkeeping only, no conflict). Main has since gained lead cycle 167 and the FX1-4-holds-codex merge (e2e8f5a1, server files and FX1's, none of this task's); not merged, so the pre-checked sha stays the ready one.
  - **Commits.** Claim 039be74f; fail-first tests f32be7db (every proof fails there); fixes f08f52b9; findings commit c7878bcf.
  - **Findings.** `docs/security/audit-2026-11/sim.md`, in the report's format, with its line references against f32be7db (pre-fix code).
    - SIM-1 (Medium): `sees_body` ignored bushes, thickets and lanterns for a knocked-out guard (§12.8 v3.3).
    - SIM-2 (Medium): `rb_record`, `rb_record_crew` and `rb_record_drawn` returned replays over 2 KB, which `rb_verify` refuses; they now return -9. The device recorder (`client/ext`) has the same gap: outside these files, so proposed in sim.md.
    - SIM-3 (Medium): `no_floats.py` let `1f64`, `1e3`, `1_000.5`, `1.` and floats after a `"//"` or on a `*p =` line through.
    - SIM-4 (Medium): `status.py` counted only `tests::` lines and ignored cargo's exit code, so the seven `stability::` tests could fail unseen. A new system "Stability" (§5.5, TD.14) in `sim/systems.json` claims them.
    - SIM-6 (Medium): a Rambler's charge through a Crystal Wall ignored Cracked gardens and Shattered glass.
    - SIM-5, SIM-7, SIM-8, SIM-9 (Low): the Hourkeeper's rewind and a heal in the same tick; a Gone Prism half blocking the golem's wall; a Well cutting a Snare's freeze short; a bounce skipping a bridge.
  - **The report's suspicions.** `rb_record_drawn` with crew 0: confirmed, but it is SR-07's deliberate trap lever; not fixed (proposed: a dedicated trap export first). `rb_hold`'s ticks: rejected (server-fixed values only). Over 2 KB: SIM-2. Second encodings: rejected at the byte level (every single-byte mutation of twelve islands tried), the semantic half unproven. `tile_at`/`coords` wrap: rejected (needs 65,536 tiles).
  - **Gate.** `sim/run_spike.sh` now runs `python3 test_tools.py` before `status.py`, so the float ban and the test count are themselves tested.
  - **Goldens.** No fix changes a golden outcome; no `sim/golden/*.rbh` was rebaked.
  - **No existing test was changed.**
  - **Owners.** `owners.py diff FX3-5-audit-sim origin/claude/videogame-project-analysis-ewkkk2 c333f546` reports "every changed path is inside its files".
  - **Next.** The lead's merge.
- FX3-4-lab-replay, merged (ready 2026-11-21). Branch `claude/fix-sim`. Pre-check at 7db937dd: PASS ("All checks passed.", 21:40Z, recorded); `ready_sha` 7db937dd is in `docs/progress/status/FX3.json`. Main merged at 702b29e6 (lead cycle 162's files only, no conflict). An earlier pre-check at 702b29e6 failed on `sim/status.py` ("tests no system claims") because the new Rust tests were not yet listed in `sim/systems.json`; 7db937dd lists them, and that run is superseded. Main has since gained lead cycle 163 (57c23193, 11aa8614, docs/progress bookkeeping only); not merged, so the pre-checked sha stays the ready one.
  - **RB-51.** `Lab.crossed` took `chordOf`, the first chord in §8.8's table three laws make, so three laws completing two or more chords hinted only one of them. A new `chordsOf` returns every chord the three complete, each note carried by a different law; `crossed` hints each one not yet found. `chordOf` stays, as `chordsOf(..)[0]`, for `server/test/lab.test.mjs`.
    - Test commit efdc9028, fix commit 812c7e52. The test fails on main:
      ```
      error: 'clockwork hinted: ["ghost_tide","pinball"]'
      ```
  - **RB-52.** `Lab.hint` searched `RESONANCES` for an undiscovered resonance of the law, so an empty experiment could hint one that cannot be found at launch. It now searches `LAUNCH_RESONANCES`.
    - Test commit efdc9028, fix commit 451fad7a. The test fails on main:
      ```
      error: 'sleeping_streams can be found at launch: ["drifting_echoes","mangrove_banks","sleeping_streams"]'
      ```
  - **RB-54.** `Heist::decode` cast each tick delta `as u32`, so a delta of 2^32 + d read as d, and `read_varint` accepted padded forms (a trailing `0x00` byte) and over-long ones whose high bits fell off. One heist therefore had many byte strings. The decoder now refuses a delta past `u32`, a zero last byte after the first, and bits past 64 at the tenth byte, so each heist has the one encoding `encode` writes.
    - Test commit 03568ad3, fix commit 340a09d4. The tests fail on main:
      ```
      2^32 + 0 decodes as 0
      ```
      and
      ```
      a padded varint decodes
      ```
  - **RB-55.** The replay packs the actor in four bits (`(actor << 4) | kind`), so a command for actor 16 was encoded as actor 0, another crew member. `record_with` now drops commands for actor 16 or above before recording, as no crew member is named by them; every recorded heist round-trips.
    - Test commit 03568ad3, fix commit 6d2d8e8e. The test inserts a tick-1 MoveTo for actor 16 into `draw`'s log on `Island::example_open()`, records it, and checks the record keeps no such command and decodes to the same commands. It fails on main:
      ```
      the recorded heist keeps a command for an actor past 15
      ```
      (decoded, that command read `Command { tick: 1, actor: 0, kind: MoveTo, .. }`).
  - **Goldens.** No fix changes a golden outcome: `golden_replays_still_verify` passes, and no `sim/golden/*.rbh` was rebaked.
  - **`sim/systems.json`.** 7db937dd lists the RB-54 and RB-55 tests under Replay format, and commits the `sim/status.json` that `status.py` rewrote (three new "passed" lines).
  - **No existing test was changed.**
  - **Owners.** `owners.py diff FX3-4-lab-replay origin/claude/videogame-project-analysis-ewkkk2 7db937dd` reports "every changed path is inside its files".
  - **Next.** The lead's merge; FX3-5-audit-sim in a fresh session.
- FX3-3-clock-report, ready (2026-11-21). Branch `claude/fix-sim`. Pre-check at 9aa26794: PASS ("All checks passed.", 19:52Z, recorded); `ready_sha` 9aa26794 is in `docs/progress/status/FX3.json`. Main merged at 9aa26794 (lead cycle 160's files only, no conflict). Main has since gained lead cycle 161 (91ab2a52, bookkeeping only); not merged, so the pre-checked sha stays the ready one.
  - **RB-44.** `World::report` and `Crossing::reports` set `held` to the whole clock unless every raider in `raiders` was Out or Caught. A Prism mite's half is appended to `raiders` and retired as `Gone` at the rejoin, logging neither, so after any split the defence "held" for the whole clock. A new `World::crew_all_in` counts only the crew (raiders with no `half_of`); both reports use it.
    - Test commit 596289a8, fix commit 6e610477. The tests fail on main:
      ```
      assertion `left == right` failed: all three out at tick 300
        left: 65535
       right: 10
      ```
      (the test world's clock is unbounded, so the whole clock reads as the clamp), and for the crossing:
      ```
      all three out at tick 300: [165]
      ```
  - **RB-45.** §12.6's catch at the clock's end ran only when `clock_run` reached `clock * 1000`. An inverted Haste runs the clock at 4/5, so it never got there before the replay's last tick, and whoever was inside was never caught. The catch now also runs on the replay's last tick (`now + 1 >= clock`). At the normal rate `clock_run` reaches `clock * 1000` on that same tick, so an unslowed heist is unchanged; a quickened one still ends early as before.
    - Test commit 1601e5cb, fix commit 2fe3eb44. The test fails on main:
      ```
      assertion `left == right` failed: inside at the replay's last tick
        left: Active
       right: Caught
      ```
  - **RB-19.** `Build`'s trap-wrapping loop read each method as `this[name]`, which ran the `buildingKinds` and `footprints` getters at load, and a build without `rb_building_kinds` threw. The loop now reads `Object.getOwnPropertyDescriptor(Build.prototype, name).value`, as the report proposes, so getters are skipped (they were never wrapped anyway: their value is not a function).
    - Test commit 7fc59edd, fix commit 5e792a71. The test makes the older build from this checkout's by renaming the `rb_building_kinds` export to a same-length name, so the module stays valid. It fails on main:
      ```
      error: 'this.x.rb_building_kinds is not a function'
      name: 'TypeError'
      ```
  - **Goldens.** No fix changes a golden outcome: `golden_replays_still_verify` passes, and no `sim/golden/*.rbh` was rebaked.
  - **`sim/systems.json`.** 35a69624 lists the RB-44 tests under Event log and Universes and the RB-45 test under The skiff, the clock and the outcome. It also commits the `sim/status.json` that `status.py` rewrote, whose only change is three new "passed" lines.
  - **No existing test was changed.**
  - **Owners.** `owners.py diff FX3-3-clock-report origin/claude/videogame-project-analysis-ewkkk2 9aa26794` reports "every changed path is inside its files".
  - **Next.** The lead's merge; the next FX3 task in a fresh session.

## Tried and failed
- FX3-5-audit-sim: a first insertion of the nine tests into `sim/src/tests.rs` broke the file's last module; redone by appending after the last test. A first `npm test` failed because the wasm build was missing in the fresh container; the wasm was built and the tests rerun. Neither reached a commit.
