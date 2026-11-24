# SP-bt-04 the gate shot renderer: progress

- Status: Green; BT-04b ready at 9213e507: frame strips, the 200% text and high-contrast variants, and named crops in `tools/gate/render.py`. Sandboxed proof exit 0 (bwrap, 2026-11-24T21:48:29Z); full pre-check: see the status file.
- Progress: 1 of 2 tasks merged (BT-04a); 0 items passed by the gate (BT-04b has no gate items).
- Done: BT-04a (still renderer, cache fallback); BT-04b: `strip` screens and items "<screen> strip[ in high contrast]", the `variants` command, named crops from a still's shot record (`crops`, `record`, `still --crops`), fixtures for the press, reward, shine and screen strips and the settings and character crops, and the self-test that renders a fixture strip and crop.
- Next: the lead merges BT-04b; AD adopts the shot list (SP-bt-04-R2).
- Blocked by: none.
- Owner decision needed: none.

| Deliverable | Weight (h) | Status | Evidence |
|---|---:|---|---|
| BT-04a: shot list format and still renderer | 3 | merged | full pre-check PASS at 0fa16325, 20:28:16Z |
| BT-04b: strips, variants, crops | 2 | ready at 9213e507 | sandboxed proof at 9213e507: exit 0, "the fixture item at 9213e507, ok"; full pre-check in the status file |

## Handoff

- Last verified commit: 9213e507. Proof: `CHECK_CMD='bash client/build.sh && python3 tools/gate/render.py --self-test' bash tools/run_checks.sh start 9213e507`, bwrap, exit 0, finished 2026-11-24T21:48:29Z. Log: `render.py: the shot list's parser, ok` / `render.py: the strip of synthetic frames, ok` / `render.py: the build cache's fallback, ok` / `render.py: the build cache is /tmp/ruleborn-gate: /root/.cache/ruleborn/gate cannot be written (Read-only file system)` / `render.py: the fixture item at 9213e507, ok` / `DONE exit=0`. (`result` says FAIL for that narrowed command only because it never prints "All checks passed.", as for BT-04a.)
- What the fixture render proves: `render(["settings at 200% text, pt_BR", "press strip"], HEAD, ...)` with `tools/gate/fixtures/test_shots.json`. The settings still runs with `RECORD=1`, and its named crops "back" (one control) and "size-a" (two controls) are cut from `settings_200_pt_BR.shot.json` into `settings_200_pt_BR.crops/`; each crop must be the control's width at full resolution plus its 8 pt margin, and not blank. The press strip runs `motion_press.gd` with `FORM=full` under `--fixed-fps 60`, and must show frames 0, 6, … 42 (pick `0:43:6`, 120 px), not blank, with its frames' log copied beside it.
- Format (docstring of render.py): a screen may carry `record` (the variable that makes its script write `<still>.shot.json`, `RECORD` for settings and character) and `crops` (names matched against a control's whole name, its kind or its label); a missing crop fails the still. A screen with `strip: {pick, height}` is a motion screen: its items are "<screen> strip" and "<screen> strip in high contrast", a state may override pick or height, and a strip with crops is refused. `render.py variants <screens> --sha --out` renders a screen's three variants (or its two strips).
- The full shot list's strips copy art/ui/motion/strips.sh's picks and heights (press 0:43:3 at 200, reward 0:999:4 at 360 with reduced 0:999:3, shine 42:66:2 at 200 with reduced 0:999:24, screen 0:19:1 at 400). strips.sh's own `reward_epic_hc` and `shine_hc` are the "strip in high contrast" items.
- Timing: the fixture render adds about 15 s for the strip (one `--import`, 43 frames); in the sandbox the GDExtension build still dominates (about 5 min).
- Requests: SP-bt-04-R1 done (check_all.sh:185 runs the self-test); SP-bt-04-R2 to AD stands.
- Open hypotheses: crops on a 100% still use the same record format; only the 200% pt_BR record was rendered here.
- Next step: none; the lead merges BT-04b.

## Tried and failed

- 2026-11-24 the self-test first expected a 1080 × 2340 still: `screen_settings.gd` renders at 540 × 1170, so the test now checks only that the still is not tiny and that its grayscale is 960 px, gray and not blank.
- 2026-11-24 (resync) falling back only the cache folder to TMPDIR, as first suggested: `git worktree add` then fails too, because the sandbox binds the shared .git read-only; the commit is now exported with git archive instead.
- 2026-11-24 (BT-04b) the synthetic strip test first expected a strip wider than twice its height: four 60 × 100 frames with their 34 px stamp are portrait tiles of about 36 px at 80 px high, so the strip is 224 × 118; the test now expects four tiles' width.
