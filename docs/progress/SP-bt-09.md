# SP-bt-09 environment setup: progress

- Status: Green pending; `tools/setup_env.sh` pushed at 1a8a6ea7, its full pre-check running.
- Progress: 0 of 1 tasks merged; 0 items passed by the gate (BT-09 has no gate items).
- Done: `tools/setup_env.sh`: one idempotent, non-interactive setup with every installed version pinned; a `--check` mode that changes nothing.
- Next: record the pre-check, mark BT-09 ready.
- Blocked by: none.
- Owner decision needed: none.

| Deliverable | Weight (h) | Status | Evidence |
|---|---:|---|---|
| BT-09: environment setup with pinned versions | 2 | pre-check running | runs below; pre-check: the status file's `precheck` |

## Handoff

- Last verified commit: 1a8a6ea7 (setup runs below, 2026-11-24 22:3x UTC); full pre-check: the status file's `precheck`.
- What the script does, in order: checks what it cannot install (python3 3.10+, rustc 1.82+, node 22.5+, npm, curl, git); installs `bubblewrap` and `xvfb` from apt only when `bwrap` or `xvfb-run` is absent (the distribution's versions: the one unpinned step); `rustup target add` of the three targets that are missing; `python3 -m pip install` of the pins that do not hold (`gdtoolkit==4.5.0`, `lark==1.2.2`, `playwright==1.63.0`, `pillow==13.0.0`, `numpy==2.5.3`, or `numpy==2.4.6` on Python 3.11, which has no numpy 2.5 wheel), a pin counting as held only if the version matches and the module imports (the November container's broken Debian Pillow had a version but did not import); checks that the pinned Playwright finds its Chromium under `PLAYWRIGHT_BROWSERS_PATH` (never the browser installer); `npm ci` in `tools/ui_research` unless its `node_modules/.package-lock.json` already matches the lockfile; `bash client/build.sh`.
- Run 1 in this fresh container (python3 3.13; the targets, gdlint and Playwright were already there): `MISSING python packages pillow==13.0.0` (3.13 had `13.0.0.post1`, not the pin), `MISSING tools/ui_research/node_modules`, `MISSING client build`; the run installed those two, built the client (3 min 18 s, Godot download and cargo build), `done, 2 installed`, exit 0.
- Run 2: every step `ok`, `done, 0 installed`, 8 s; `--check` then `0 missing`, exit 0; `git status` shows nothing but the script. build.sh re-copies `client/bin/libruleborn_godot.so` and the goldens (same content, new mtime): build.sh's own behaviour, unchanged here.
- Python 3.11: in a 3.11 venv on PATH, run 1 installed `gdtoolkit==4.5.0 lark==1.2.2 playwright==1.63.0 pillow==13.0.0 numpy==2.4.6`, found the Chromium, exit 0; `--check` then `0 missing`; `gdlint --version` 4.5.0.
- Not changed: run_checks.sh, check_all.sh, client/build.sh, README.md. The documentation check passes without a README line (`no inconsistencies`), so no request for one.
- Open hypotheses: the apt step (bwrap, xvfb absent) was not exercised here, as both are present; it needs root or passwordless sudo.
- Next step: none once ready. Then the brief's "Starting a session" step 2 and checks.md's "What it needs" can point at `bash tools/setup_env.sh` (the lead's files; request SP-bt-09-R1).

## Tried and failed

- 2026-11-24 pinning `numpy==2.5.3` everywhere: numpy 2.5 has no wheel for Python 3.11 (`pip download --python-version 3.11` lists up to 2.4.6), so 3.11 takes 2.4.6.
- 2026-11-24 pinning `pillow==13.0.0.post1` (what this container had): it is not on PyPI; the pin is 13.0.0.
