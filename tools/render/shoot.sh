#!/usr/bin/env bash
# Render one still from the Godot client on a machine with no screen.
#
#   bash tools/render/shoot.sh client/tests/shots/heist_shot.gd out.png [W H]
#
# Software GL (Mesa llvmpipe) under Xvfb with the Compatibility renderer, the
# one the phones use. Extra settings go in the environment (TICKS, HOUR, ZOOM,
# PITCH, whatever the shot script reads). A new class_name needs one
# `godot --headless --path client --import` first; this script does that.
set -euo pipefail
cd "$(dirname "$0")/../.."
script=$1
out=$(realpath -m "$2")
w=${3:-1080}
h=${4:-2340}
godot=${RULEBORN_GODOT:-$HOME/.cache/ruleborn/Godot_v4.7.2-stable_linux.x86_64}
[ -x "$godot" ] || bash client/build.sh > /dev/null
"$godot" --headless --path client --import > /dev/null 2>&1 || true
rel=${script#client/}
SHOT=$out timeout "${SHOT_TIMEOUT:-300}" xvfb-run -a -s "-screen 0 ${w}x${h}x24" "$godot" --rendering-driver opengl3 \
  --path client -s "res://$rel" 2>&1 | grep -v "^$" | tail -20
[ -s "$out" ] && echo "wrote $out"
