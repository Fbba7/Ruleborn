#!/usr/bin/env bash
# Renders the kit's catalogue sheet (kit-spec.md section 6.4) in its eight
# variants: English and Brazilian Portuguese, normal and high contrast, 100%
# and 200% text. One PNG per page in docs/art/shots/ui-bake/, named
# catalogue-<locale>-<n|hc>-<text>-NN.png, each under 400 KB.
#
#   bash tools/ui_bake/catalogue.sh            # all eight
#   bash tools/ui_bake/catalogue.sh en n 100   # one
set -euo pipefail
cd "$(dirname "$0")/../.."
out=docs/art/shots/ui-bake
limit=$((400 * 1024))
mkdir -p "$out"

one() {
  local loc=$1 look=$2 text=$3
  local stem="$out/catalogue-$loc-$look-$text"
  rm -f "$stem"-*.png
  local hc=""
  [ "$look" = hc ] && hc=1
  LOCALE=$loc HC=$hc TEXT=$text SHOT_TIMEOUT=${SHOT_TIMEOUT:-900} \
    bash tools/render/shoot.sh client/tests/shots/ui_kit_catalogue.gd "$stem-01.png" | grep -E "^catalogue:|SCRIPT ERROR" || true
  ls "$stem"-*.png > /dev/null
}

if [ $# -eq 3 ]; then
  one "$1" "$2" "$3"
else
  for loc in en pt_BR; do
    for look in n hc; do
      for text in 100 200; do
        one "$loc" "$look" "$text"
      done
    done
  done
fi

# A page over the limit is quantized to a palette; one that stays over fails.
python3 - "$out" "$limit" <<'EOF'
import glob, os, sys
from PIL import Image
out, limit = sys.argv[1], int(sys.argv[2])
bad = []
for f in sorted(glob.glob(os.path.join(out, "catalogue-*.png"))):
    if os.path.getsize(f) > limit:
        Image.open(f).convert("RGB").quantize(256, method=Image.Quantize.MEDIANCUT).save(f, optimize=True)
    if os.path.getsize(f) > limit:
        bad.append(f)
for f in bad:
    print("over 400 KB: " + f)
sys.exit(1 if bad else 0)
EOF
echo "catalogue pages: $(ls "$out"/catalogue-*.png | wc -l)"
