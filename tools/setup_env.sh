#!/usr/bin/env bash
# Sets up a fresh container so that tools/check_all.sh can pass (backlog task
# BT-09). Idempotent and non-interactive: each step checks first and changes
# nothing when it is already satisfied, so a second run only reports "ok".
#
#   bash tools/setup_env.sh           # set up, then build the client
#   bash tools/setup_env.sh --check   # report what is missing; change nothing
#
# Every version it installs is pinned exactly here. It never runs
# Playwright's browser installer: the container's Chromium under
# $PLAYWRIGHT_BROWSERS_PATH (/opt/pw-browsers) is used, and the Python
# Playwright pinned below is the one whose Chromium that is (the container's
# Node Playwright, `require('playwright/package.json').version`, says which).
#
# What it does, in order (docs/guides/checks.md, "What it needs"):
#   1. checks the tools it cannot install itself: Python 3.10+, Rust 1.82+
#      (rustup), Node 22.5+ with npm, curl, git;
#   2. installs bubblewrap and xvfb from the distribution if absent (bwrap
#      contains tools/run_checks.sh's runs; xvfb-run serves the gate's
#      renders), at the distribution's own versions;
#   3. adds Rust's wasm32-unknown-unknown, aarch64-linux-android and
#      aarch64-apple-ios targets;
#   4. installs the Python packages below into the `python3` on PATH, the one
#      check_all.sh runs (a container's Debian Pillow may not import there);
#   5. checks that the pinned Playwright finds its Chromium;
#   6. runs `npm ci` in tools/ui_research (its lockfile pins three.js), when
#      its node_modules does not already match the lockfile;
#   7. runs `bash client/build.sh` (Godot 4.7.2, pinned and checksummed there;
#      the GDExtension; Godot's import cache). It is idempotent itself.
set -euo pipefail
root="$(cd "$(dirname "$0")/.." && pwd)"
cd "$root"

check_only=0
case "${1:-}" in
  "") ;;
  --check) check_only=1 ;;
  *) echo "usage: bash tools/setup_env.sh [--check]" >&2; exit 2 ;;
esac

# The pins. numpy 2.5 has no wheel for Python 3.11, so 3.11 takes the last
# numpy that has one; every other pin is the same on every Python.
GDTOOLKIT=4.5.0          # gdlint; check_all lints the client with it
LARK=1.2.2               # gdtoolkit's parser: its output depends on lark's
PLAYWRIGHT=1.63.0        # must match the container's Chromium (chromium-1243)
PILLOW=13.0.0
NUMPY=2.5.3
NUMPY_PY311=2.4.6
RUST_TARGETS=(wasm32-unknown-unknown aarch64-linux-android aarch64-apple-ios)

changed=0
missing=0
say() { echo "setup_env: $*"; }
die() { echo "setup_env: $*" >&2; exit 1; }
# fix <what> <command...>: runs the command unless --check, else counts it.
fix() {
  local what="$1"; shift
  if [ "$check_only" = 1 ]; then say "MISSING $what"; missing=$((missing + 1)); return 0; fi
  say "installing $what"
  "$@"
  changed=$((changed + 1))
}

# version_ge <have> <need>: dotted numeric versions.
version_ge() { [ "$(printf '%s\n%s\n' "$2" "$1" | sort -V | head -n1)" = "$2" ]; }

# 1. What this script cannot install.
for t in curl git python3 rustup cargo node npm; do
  command -v "$t" > /dev/null || die "$t is not on PATH; install it first (docs/guides/checks.md, \"What it needs\")"
done
py="$(python3 -c 'import sys; print("%d.%d" % sys.version_info[:2])')"
version_ge "$py" 3.10 || die "python3 is $py; check_all needs Python 3.10 or later"
rustv="$(rustc --version | awk '{print $2}')"
version_ge "${rustv%%-*}" 1.82 || die "rustc is $rustv; the simulation needs Rust 1.82 or later"
nodev="$(node --version | tr -d v)"
version_ge "$nodev" 22.5 || die "node is $nodev; the server needs Node 22.5 or later"
say "ok python3 $py, rustc $rustv, node $nodev"

# 2. The distribution's bubblewrap and xvfb.
apt_pkgs=()
command -v bwrap > /dev/null || apt_pkgs+=(bubblewrap)
command -v xvfb-run > /dev/null || apt_pkgs+=(xvfb)
if [ "${#apt_pkgs[@]}" -gt 0 ]; then
  command -v apt-get > /dev/null || die "${apt_pkgs[*]} missing and no apt-get to install them"
  as_root=(); [ "$(id -u)" = 0 ] || as_root=(sudo -n)
  fix "${apt_pkgs[*]} (apt)" sh -c "${as_root[*]} apt-get update -qq && DEBIAN_FRONTEND=noninteractive ${as_root[*]} apt-get install -y -qq --no-install-recommends ${apt_pkgs[*]}"
else
  say "ok bwrap, xvfb-run"
fi

# 3. Rust's targets, for the active toolchain.
have_targets="$(rustup target list --installed)"
need_targets=()
for t in "${RUST_TARGETS[@]}"; do
  grep -qx "$t" <<< "$have_targets" || need_targets+=("$t")
done
if [ "${#need_targets[@]}" -gt 0 ]; then
  fix "rust targets ${need_targets[*]}" rustup target add "${need_targets[@]}"
else
  say "ok rust targets ${RUST_TARGETS[*]}"
fi

# 4. The Python packages, pinned, into the python3 check_all runs.
if [ "$py" = 3.11 ]; then numpy_pin="$NUMPY_PY311"; else numpy_pin="$NUMPY"; fi
pins=("gdtoolkit==$GDTOOLKIT" "lark==$LARK" "playwright==$PLAYWRIGHT" "pillow==$PILLOW" "numpy==$numpy_pin")
# A pin counts as satisfied only if its distribution has that exact version
# and its module imports (a broken system Pillow has the version but fails).
py_missing="$(python3 - "${pins[@]}" <<'EOF'
import importlib, importlib.metadata as md, sys
modules = {"gdtoolkit": "gdtoolkit", "lark": "lark", "playwright": "playwright.sync_api",
           "pillow": "PIL.Image", "numpy": "numpy"}
for pin in sys.argv[1:]:
    name, want = pin.split("==")
    try:
        ok = md.version(name) == want
        if ok:
            importlib.import_module(modules[name])
    except Exception:
        ok = False
    if not ok:
        print(pin)
EOF
)"
if [ -n "$py_missing" ]; then
  # PEP 668: a Debian python3 refuses pip without this flag; pip 23.0+ knows it.
  pipflags=(--quiet --disable-pip-version-check --no-input --root-user-action=ignore)
  if python3 -m pip install --help 2>/dev/null | grep -q -- --break-system-packages; then
    pipflags+=(--break-system-packages)
  fi
  # shellcheck disable=SC2086
  fix "python packages $(echo $py_missing)" python3 -m pip install "${pipflags[@]}" $py_missing
  # pip installs dependencies too; re-check that every pin now holds.
  [ "$check_only" = 1 ] || python3 - "${pins[@]}" <<'EOF'
import importlib.metadata as md, sys
bad = [p for p in sys.argv[1:] if md.version(p.split("==")[0]) != p.split("==")[1]]
sys.exit("setup_env: pins not met after pip: " + " ".join(bad) if bad else 0)
EOF
else
  say "ok python packages ${pins[*]}"
fi
command -v gdlint > /dev/null || [ "$check_only" = 1 ] || die "gdlint is not on PATH after installing gdtoolkit; add python3's scripts folder to PATH"

# 5. The pinned Playwright must find the container's Chromium: never the
# browser installer.
if [ "$check_only" = 0 ] || [ -z "$py_missing" ]; then
  chromium="$(python3 -c '
from playwright.sync_api import sync_playwright
with sync_playwright() as p:
    print(p.chromium.executable_path)')" || die "python3's Playwright did not start"
  [ -x "$chromium" ] || die "Playwright $PLAYWRIGHT expects Chromium at $chromium, which is absent (PLAYWRIGHT_BROWSERS_PATH=${PLAYWRIGHT_BROWSERS_PATH:-unset}); this script does not download browsers"
  say "ok chromium $chromium"
fi

# 6. tools/ui_research's three.js, from its lockfile. npm writes
# node_modules/.package-lock.json on install; when it equals the lockfile's
# packages, the folder is current.
ui="tools/ui_research"
current="$(node -e '
const fs = require("fs");
try {
  const want = JSON.parse(fs.readFileSync(process.argv[1] + "/package-lock.json")).packages;
  const have = JSON.parse(fs.readFileSync(process.argv[1] + "/node_modules/.package-lock.json")).packages;
  const names = Object.keys(want).filter((k) => k !== "");
  const same = names.every((k) => have[k] && have[k].version === want[k].version)
    && Object.keys(have).length === names.length;
  console.log(same ? "yes" : "no");
} catch (e) { console.log("no"); }' "$ui")"
if [ "$current" = yes ]; then
  say "ok $ui/node_modules"
else
  fix "$ui/node_modules (npm ci)" sh -c "cd '$ui' && npm ci --no-audit --no-fund --loglevel=error"
fi

# 7. The client: Godot, the GDExtension, the goldens and the import cache.
# build.sh skips what is current itself (Godot's download, cargo's build).
if [ "$check_only" = 1 ]; then
  godot="${RULEBORN_GODOT:-$HOME/.cache/ruleborn/Godot_v4.7.2-stable_linux.x86_64}"
  [ -x "$godot" ] && [ -f client/bin/libruleborn_godot.so ] && say "ok client build" \
    || { say "MISSING client build (bash client/build.sh)"; missing=$((missing + 1)); }
else
  say "building the client (bash client/build.sh)"
  bash client/build.sh > /dev/null
  say "ok client build"
fi

if [ "$check_only" = 1 ]; then
  say "$missing missing"
  [ "$missing" = 0 ]
else
  say "done, $changed installed"
fi
