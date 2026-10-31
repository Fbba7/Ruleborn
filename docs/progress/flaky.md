# Flaky tests

Tests that failed and then passed unchanged, each with its fix task
([agent-program.md](../guides/agent-program.md), the lead's file on main).

## Open

### Concurrent check runs share Godot's `user://` and its download cache

- **Seen:** lead cycle 3, 30–31 October 2026. Three runs of
  `tools/check_all.sh` at once in one container (candidates `7dda0a33` and
  `e152462d` beside `fd2c9662`) each failed the client test "the builder lays
  the six with a direction, turns them with a second tap, digs a tunnel mouth
  by mouth, and the island it writes carries both (6.2, G56)"
  (`client/tests/run.gd`; detail `true true false true true true []`, so
  `faced_turned` was false). `7dda0a33` re-run alone passed unchanged
  (`DONE exit=0`, 00:58Z). Earlier the same cycle, two runs started together
  both fetched Godot into `~/.cache/ruleborn/`, and one failed with "Godot's
  download does not match its pinned sum"; it passed re-run once the cache
  was filled.
- **Cause (likely):** every run's worktree is separate, but Godot's
  `user://` (under `~/.local/share/godot/`) and `~/.cache/ruleborn/` are
  shared. The builder opens on the saved draft (`Draft.island()`,
  `client/scripts/builder_screen.gd`), so another run's draft changes what the
  test starts from.
- **Until fixed:** run full checks one at a time in a container. The lead's
  merge queue does.
- **Fix task:** BT-10 (backlog): `tools/run_checks.sh` gives each run its own
  `HOME` data directories (`XDG_DATA_HOME`, `XDG_CONFIG_HOME`), seeded with the
  Godot download, and a lock around the first download.

### Godot's import can end incomplete, and `client/build.sh` does not notice

- **Seen:** lead cycle 3, 31 October 2026, candidate `e152462d` (SV-B7-B9
  onto main) run alone at 00:59Z: 363 of 371 client tests passed (385 run
  on the same commit an hour earlier). The eight failures are the fonts, the
  icons, the toon material, text at 150% and 200% and the 48-point controls,
  and Godot's log has thousands of `Cannot open file
  'res://.godot/imported/manrope_800.woff2-….fontdata'` and the same for
  `lock.png-….ctex`: the import cache was missing files. The change is
  server files and two documents, which Godot does not import. Re-run once
  at 01:13Z (result in `lead.md`, "Now").
- **Cause (likely):** `client/build.sh` runs `godot --headless --import`
  with its output discarded and `|| true`, so an import that stops early
  leaves a partial `client/.godot/` and the tests run anyway.
- **Fix task:** BT-11 (backlog): `client/build.sh` checks that every
  imported resource's cache file exists after `--import` and fails, naming
  the first one missing, instead of running the tests on a partial cache.
