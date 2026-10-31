#!/usr/bin/env bash
# The UI guards in one command (report.md sections 3.8, 10.1 and 10.8;
# kit-spec.md section 7), for the pre-check of every change that touches the
# client or the art, and for every candidate. Not in check_all (D9 (b)).
#
#   bash tools/ui_bake/guard.sh               every guard, about 12 minutes
#   bash tools/ui_bake/guard.sh --self-test   proves the guards refuse a
#                                             planted extra draw call (in a
#                                             screen's source and on a shot)
#                                             and planted grey words
#
# 1. The full rebake, byte for byte: each family with a manifest in
#    client/ui/art/ is baked again into a scratch folder and compared file
#    by file. With none baked yet, the test fixture is baked twice instead,
#    so the pinned tools are still shown to be byte for byte.
# 2. bake.js --check: hashes, twins, regions and sizes.
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
    for part in "$fam.json" "$fam.webp" "${fam}_hc.webp"; do
      cmp -s "client/ui/art/$part" "$scratch/$part" || {
        echo "rebake differs: client/ui/art/$part is not what its sources bake to"; return 1; }
    done
    echo "$fam rebakes byte for byte"
  done
  rm -rf "$scratch"
}

if [ "${1:-}" = "--self-test" ]; then
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
