#!/usr/bin/env bash
# Bakes what the key frames draw under their interface, from the game itself:
# the worlds behind home and heist (in the normal and the high-contrast mode)
# and the portraits, into bg/ and art/. Run it again when the worlds or the
# models change; shoot_keyframes.mjs then photographs the pages.
#
#   bash art/ui/keyframes/bake.sh
set -euo pipefail
here="$(cd "$(dirname "$0")" && pwd)"
root="$(cd "$here/../../.." && pwd)"
cd "$root"
godot=${RULEBORN_GODOT:-$HOME/.cache/ruleborn/Godot_v4.7.2-stable_linux.x86_64}
[ -x "$godot" ] || bash client/build.sh > /dev/null
"$godot" --headless --path client --import > /dev/null 2>&1 || true
tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT
mkdir -p "$here/bg" "$here/art"
run() { timeout 300 xvfb-run -a -s "-screen 0 1080x2340x24" "$godot" --rendering-driver opengl3 --path client -s "$1" 2>&1 | grep -E "^(wrote|baked|SCRIPT ERROR)" || true; }

# The heist at the vault, with the design's crew of five (§21.8): the screen's
# interface hidden, since the page draws it.
hide=hud,hint_label,actions_band,column_node,pause_button
SHOT=$tmp/heist.png MOMENT=vault MANIFEST=1 ESTIMATE=2600 HIDE=$hide run res://tests/shots/screen_heist.gd
SHOT=$tmp/heist_hc.png MOMENT=vault MANIFEST=1 ESTIMATE=2600 HIDE=$hide CONTRAST=1 run res://tests/shots/screen_heist.gd
SHOT=$tmp/home.png run "$here/bake_home.gd"
SHOT=$tmp/home_hc.png CONTRAST=1 run "$here/bake_home.gd"
OUT=$here/art run "$here/bake_portraits.gd"

# The worlds go in as JPEG: they are photographs under the interface, and a
# PNG of each would be ten times the size. The only word in them is the
# heist world's own Vault tag (BUILDING_VAULT, "Vault" in every language).
python3 - "$tmp" "$here/bg" <<'EOF'
import sys
from PIL import Image
src, dst = sys.argv[1:]
for name in ["heist", "heist_hc", "home", "home_hc"]:
    im = Image.open(f"{src}/{name}.png").convert("RGB")
    assert im.size == (1080, 2340), (name, im.size)
    im.save(f"{dst}/{name}.jpg", quality=88, optimize=True)
    print("wrote", f"{dst}/{name}.jpg")
EOF
