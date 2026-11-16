#!/usr/bin/env bash
# The UI guards in one command (report.md sections 3.8, 10.1 and 10.8;
# kit-spec.md section 7), for the pre-check of every change that touches the
# client or the art, and for every candidate. Not in check_all (D9 (b)).
#
#   bash tools/ui_bake/guard.sh               every guard, about 12 minutes
#   bash tools/ui_bake/guard.sh --self-test   proves the guards refuse a
#                                             planted extra draw call (in a
#                                             screen's source and on a shot)
#                                             and planted grey words, and the
#                                             prerequisite check refuses a
#                                             worktree that lacks one
#   bash tools/ui_bake/guard.sh --prereqs     the prerequisite check alone,
#                                             in a second or two
#
# 0. The prerequisites, first in every mode (M19, M32): the native library
#    client/bin/libruleborn_godot.so and the pinned Godot (bash
#    client/build.sh), tools/ui_research/node_modules with three.js, Node with
#    the container's Playwright and its Chromium, Python 3 with Pillow (WebP),
#    xvfb-run, timeout and cmp. Each one missing is named with the command
#    that installs it, and the guard exits 1 before any guard runs.
#
# 1. The full rebake, byte for byte: each family with a manifest in
#    client/ui/art/ (SVG and scene alike) is baked again into a scratch
#    folder and compared file by file, every page with its twin. With none baked yet, the test fixture is baked twice instead,
#    so the pinned tools are still shown to be byte for byte.
# 2. bake.js --check: hashes, twins, regions, sizes and the motion family's
#    curves; then art/ui/motion/check_curves.py, the curves' own rules
#    (150 to 250 ms a step, ease out, no overshoot, flashes and shake).
# 3. check_screens.py: no chrome of a screen's own above the counts recorded.
# 4. budget_shots.py: draw calls, texture memory and contrast on the five key
#    screens at 100% and 200% text and in high contrast, against
#    tools/ui_bake/budgets.json.
#
# Logs and stills go to $UI_GUARD_LOGS, else a scratch folder it prints.
set -uo pipefail
here="$(cd "$(dirname "$0")" && pwd)"
root="$(cd "$here/../.." && pwd)"
cd "$root"
export UI_GUARD_LOGS="${UI_GUARD_LOGS:-$(mktemp -d "${TMPDIR:-/tmp}/ui_guard.XXXXXX")}"
mkdir -p "$UI_GUARD_LOGS"
failed=()

step() { echo "== $1 =="; }

# The prerequisites (step 0). Prints one line per missing piece, with the
# command that installs it, and returns non-zero if any is missing.
prereqs() {
  local missing=0 version godot lib
  need() { echo "missing: $1"; echo "  install: $2"; missing=1; }
  have() { command -v "$1" > /dev/null 2>&1; }
  lib=client/bin/libruleborn_godot.so
  [ -f "$lib" ] || need "the native library $lib" "bash client/build.sh"
  version=$(sed -n 's/^version="\(.*\)"$/\1/p' client/build.sh 2> /dev/null)
  godot="${RULEBORN_GODOT:-$HOME/.cache/ruleborn/Godot_v${version:-4.7.2-stable}_linux.x86_64}"
  [ -x "$godot" ] || need "the Godot binary $godot" \
    "bash client/build.sh (it fetches Godot ${version:-4.7.2-stable}; or set RULEBORN_GODOT)"
  [ -f tools/ui_research/node_modules/three/build/three.module.js ] || need \
    "three.js in tools/ui_research/node_modules (the icon bake's)" \
    "(cd tools/ui_research && npm ci), or in a worktree: ln -s <main checkout>/tools/ui_research/node_modules tools/ui_research/node_modules"
  if ! have node; then
    need "node" "install Node 22 and put it on PATH"
  elif ! (cd tools/ui_bake && node -e "require.resolve('playwright')") > /dev/null 2>&1; then
    need "Node's playwright module (bake.js draws in its Chromium)" "npm install -g playwright@1.63.0"
  elif ! (cd tools/ui_bake && node -e "
      const fs = require('fs'); const p = require('playwright').chromium.executablePath();
      process.exit(p && fs.existsSync(p) ? 0 : 1)") > /dev/null 2>&1; then
    need "Playwright's Chromium" "npx playwright@1.63.0 install chromium"
  fi
  if ! have python3; then
    need "python3" "install Python 3 and put it on PATH"
  elif ! python3 -c "from PIL import features; raise SystemExit(0 if features.check('webp') else 1)" \
      > /dev/null 2>&1; then
    need "Python's Pillow with WebP (pack.py)" "pip install pillow"
  fi
  have xvfb-run || need "xvfb-run (the shots run under it)" "apt-get install -y xvfb"
  have timeout || need "timeout" "apt-get install -y coreutils"
  have cmp || need "cmp (the rebake compares with it)" "apt-get install -y diffutils"
  return $missing
}

if [ "${1:-}" = "--prereqs" ] || [ "${1:-}" = "--self-test" ] || [ -z "${1:-}" ]; then
  step "prerequisites"
  t0=$SECONDS
  if ! prereqs; then
    echo "ui guard: FAIL (prerequisites missing, $((SECONDS - t0)) s; no guard ran)"
    exit 1
  fi
  echo "every prerequisite is here ($((SECONDS - t0)) s)"
  [ "${1:-}" = "--prereqs" ] && { echo "ui guard: prerequisites OK"; exit 0; }
else
  echo "usage: bash tools/ui_bake/guard.sh [--self-test | --prereqs]" >&2
  exit 2
fi

rebake() {
  local scratch fam f manifests=()
  scratch=$(mktemp -d "${TMPDIR:-/tmp}/ui_rebake.XXXXXX")
  shopt -s nullglob
  for f in client/ui/art/*.json; do manifests+=("$f"); done
  shopt -u nullglob
  if [ ${#manifests[@]} -eq 0 ]; then
    echo "no family baked in client/ui/art/ yet; baking the test fixture twice"
    local fx=tools/ui_bake/test/fixture
    for n in 1 2; do
      node tools/ui_bake/bake.js fixture --config "$fx/families.json" --art "$fx/art" \
        --out "$scratch/$n" > "$UI_GUARD_LOGS/rebake-fixture-$n.log" 2>&1 || {
        echo "the fixture's bake $n failed: $UI_GUARD_LOGS/rebake-fixture-$n.log"; return 1; }
    done
    for f in fixture.json fixture.webp fixture_hc.webp; do
      cmp -s "$scratch/1/$f" "$scratch/2/$f" || { echo "rebake differs: fixture's $f"; return 1; }
    done
    echo "the fixture rebakes byte for byte"
    rm -rf "$scratch"
    return 0
  fi
  for f in "${manifests[@]}"; do
    fam=$(basename "$f" .json)
    node tools/ui_bake/bake.js "$fam" --out "$scratch" > "$UI_GUARD_LOGS/rebake-$fam.log" 2>&1 || {
      echo "the bake of $fam failed: $UI_GUARD_LOGS/rebake-$fam.log"; return 1; }
    # The manifest and every page with its twin (kit-spec.md section 6.6),
    # on either side, so a page gained or lost differs too.
    local parts=() d
    shopt -s nullglob
    for d in client/ui/art "$scratch"; do
      for f in "$d/$fam.json" "$d/$fam.webp" "$d/${fam}_hc.webp" "$d/${fam}"_[0-9]*.webp; do
        parts+=("$(basename "$f")")
      done
    done
    shopt -u nullglob
    for part in $(printf '%s\n' "${parts[@]}" | sort -u); do
      cmp -s "client/ui/art/$part" "$scratch/$part" || {
        echo "rebake differs: client/ui/art/$part is not what its sources bake to"; return 1; }
    done
    echo "$fam rebakes byte for byte"
  done
  rm -rf "$scratch"
}

# The prerequisite check on a scratch worktree: guard.sh itself, with the
# library and node_modules linked in or left out. Prints what it said; returns
# 0 when it did what $4 expects ("pass", or the missing piece's name).
prereq_case() {
  local fake out rc t0 name=$1 lib=$2 mods=$3 want=$4
  fake=$(mktemp -d "${TMPDIR:-/tmp}/ui_prereq.XXXXXX")
  mkdir -p "$fake/tools/ui_bake" "$fake/tools/ui_research" "$fake/client/bin"
  cp tools/ui_bake/guard.sh "$fake/tools/ui_bake/"
  ln -s "$root/client/build.sh" "$fake/client/build.sh"
  [ "$lib" = yes ] && ln -s "$root/client/bin/libruleborn_godot.so" "$fake/client/bin/"
  [ "$mods" = yes ] && ln -s "$root/tools/ui_research/node_modules" "$fake/tools/ui_research/"
  t0=$SECONDS
  out=$(UI_GUARD_LOGS="$fake/logs" bash "$fake/tools/ui_bake/guard.sh" --prereqs 2>&1); rc=$?
  rm -rf "$fake"
  echo "$name: exit $rc in $((SECONDS - t0)) s"
  if [ $((SECONDS - t0)) -gt 20 ]; then echo "$out"; echo "too slow: the check must answer in seconds"; return 1; fi
  if [ "$want" = pass ]; then
    [ $rc -eq 0 ] && return 0
    echo "$out"; echo "a worktree with every prerequisite is refused"; return 1
  fi
  if [ $rc -ne 0 ] && [ "$(grep -c '^missing:' <<< "$out")" -eq 1 ] \
      && grep -q "^missing: .*$want" <<< "$out" && grep -q "^  install: " <<< "$out" \
      && grep -q "no guard ran" <<< "$out"; then
    grep -A1 "^missing:" <<< "$out"
    echo "refused, as it should be"
    return 0
  fi
  echo "$out"; echo "not refused for $want alone"; return 1
}

if [ "${1:-}" = "--self-test" ]; then
  step "the prerequisite check refuses a worktree that lacks one"
  prereq_case "with both" yes yes pass || failed+=("prereqs: a prepared worktree")
  prereq_case "without the library" no yes "libruleborn_godot.so" || failed+=("prereqs: no library")
  prereq_case "without node_modules" yes no "node_modules" || failed+=("prereqs: no node_modules")
  step "check_screens self-test"
  python3 tools/ui_bake/check_screens.py --self-test || failed+=("check_screens self-test")
  step "a draw call planted in a screen's source"
  plant=$(mktemp -d "${TMPDIR:-/tmp}/ui_plant.XXXXXX")
  mkdir -p "$plant/client"
  cp -r client/scripts client/world "$plant/client/"
  printf '\n\nfunc _guard_plant() -> void:\n\tdraw_rect(Rect2(0, 0, 8, 8), Color.MAGENTA)\n' \
    >> "$plant/client/scripts/result_screen.gd"
  if python3 tools/ui_bake/check_screens.py --root "$plant" > "$UI_GUARD_LOGS/plant-source.log" 2>&1; then
    echo "not refused"; failed+=("planted source draw call")
  elif grep -q "RISE client/scripts/result_screen.gd: .* draw" "$UI_GUARD_LOGS/plant-source.log"; then
    grep "RISE" "$UI_GUARD_LOGS/plant-source.log"
    echo "refused, as it should be"
  else
    cat "$UI_GUARD_LOGS/plant-source.log"; failed+=("planted source draw call: refused for another reason")
  fi
  rm -rf "$plant"
  step "an extra draw call planted on the result screen"
  python3 tools/ui_bake/budget_shots.py --only result/100 > "$UI_GUARD_LOGS/plant-clean.log" 2>&1 \
    || { cat "$UI_GUARD_LOGS/plant-clean.log"; failed+=("result/100 fails unplanted"); }
  grep "result/100" "$UI_GUARD_LOGS/plant-clean.log" | head -1
  if python3 tools/ui_bake/budget_shots.py --only result/100 --plant draw > "$UI_GUARD_LOGS/plant-shot.log" 2>&1; then
    cat "$UI_GUARD_LOGS/plant-shot.log"; failed+=("planted draw call on the result screen")
  elif grep -q "^FAIL result/100: [0-9]* draw calls, recorded" "$UI_GUARD_LOGS/plant-shot.log"; then
    grep "^FAIL" "$UI_GUARD_LOGS/plant-shot.log"
    echo "refused, as it should be"
  else
    cat "$UI_GUARD_LOGS/plant-shot.log"; failed+=("planted draw call: refused for another reason")
  fi
  step "grey words planted on the result screen"
  if python3 tools/ui_bake/budget_shots.py --only result/100 --plant contrast > "$UI_GUARD_LOGS/plant-words.log" 2>&1; then
    cat "$UI_GUARD_LOGS/plant-words.log"; failed+=("planted grey words on the result screen")
  elif grep -q "^FAIL result/100: [0-9]* words below .*PLANTED" "$UI_GUARD_LOGS/plant-words.log"; then
    grep "^FAIL" "$UI_GUARD_LOGS/plant-words.log" | cut -c1-160
    echo "refused, as it should be"
  else
    cat "$UI_GUARD_LOGS/plant-words.log"; failed+=("planted grey words: refused for another reason")
  fi
else
  step "full rebake, byte for byte"
  rebake || failed+=("rebake")
  step "bake --check"
  node tools/ui_bake/bake.js --check || failed+=("bake --check")
  step "the motion curves' rules"
  python3 art/ui/motion/check_curves.py || failed+=("check_curves")
  step "screens add no chrome of their own"
  python3 tools/ui_bake/check_screens.py || failed+=("check_screens")
  step "draw calls, texture memory and contrast on the five screens"
  python3 tools/ui_bake/budget_shots.py || failed+=("budget shots")
fi

echo "logs: $UI_GUARD_LOGS"
if [ ${#failed[@]} -gt 0 ]; then
  echo "ui guard: FAIL (${failed[*]})"
  exit 1
fi
echo "ui guard: OK"
