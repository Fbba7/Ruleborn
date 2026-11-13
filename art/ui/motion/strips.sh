#!/usr/bin/env bash
# The motion shots' frames, strips and clips (P2-AIA-motion-2; report.md
# step 8, board 4), and their checks:
#
#   bash art/ui/motion/strips.sh [shot...]     e.g. press reward_epic
#
# Each shot runs client/tests/shots/motion_<name>.gd under Xvfb with Godot's
# --fixed-fps 60, so frame k is k/60 s into the motion, in each form it has;
# its frames go to $MOTION_FRAMES (default: a scratch folder), then
# tools/ui_gate/sheet.py makes its strip under art/ui/motion/strips/ and
# ffmpeg its clip under art/ui/motion/clips/. Last, check_frames.py checks
# every log (timing, reduced forms, flashes).
set -euo pipefail
cd "$(dirname "$0")/../../.."
godot=${RULEBORN_GODOT:-$HOME/.cache/ruleborn/Godot_v4.7.2-stable_linux.x86_64}
[ -x "$godot" ] || bash client/build.sh > /dev/null
frames_root=${MOTION_FRAMES:-${TMPDIR:-/tmp}/ruleborn-motion}
out=art/ui/motion
mkdir -p "$out/strips" "$out/clips" "$frames_root"
"$godot" --headless --path client --import > /dev/null 2>&1 || true

# name | script | env | strip frames (python slice over the frame list) | strip height
runs=(
  "press_full|motion_press|FORM=full|0:43:3|200"
  "press_reduced|motion_press|FORM=reduced|0:43:3|200"
  "reward_common|motion_reward|FORM=full TIER=common|0:999:4|360"
  "reward_rare|motion_reward|FORM=full TIER=rare|0:999:4|360"
  "reward_epic|motion_reward|FORM=full TIER=epic|0:999:4|360"
  "reward_epic_hc|motion_reward|FORM=full TIER=epic HC=1|0:999:4|360"
  "reward_reduced|motion_reward|FORM=reduced TIER=epic|0:999:3|360"
  "shine_full|motion_shine|FORM=full|42:66:2|200"
  "shine_reduced|motion_shine|FORM=reduced|0:999:24|200"
  "shine_hc|motion_shine|FORM=full HC=1|0:999:24|200"
  "screen_full|motion_screen|FORM=full|0:19:1|400"
  "screen_reduced|motion_screen|FORM=reduced|0:19:1|400"
)
want=("$@")
for run in "${runs[@]}"; do
  IFS='|' read -r name script envs slice height <<< "$run"
  if [ ${#want[@]} -gt 0 ] && [[ ! " ${want[*]} " == *" $name "* ]]; then continue; fi
  dir="$frames_root/$name"
  rm -rf "$dir"; mkdir -p "$dir"
  echo "== $name"
  env $envs FRAMES="$dir" timeout "${SHOT_TIMEOUT:-240}" xvfb-run -a -s "-screen 0 1280x1280x24" \
    "$godot" --rendering-driver opengl3 --fixed-fps 60 --path client -s "res://tests/shots/$script.gd" 2>&1 \
    | grep -v "^$" | tail -5
  [ -s "$dir/log.json" ] || { echo "no frames for $name"; exit 1; }
  # The strip's frames, each stamped with its frame and time (sheet.py's own
  # label counts the strip's tiles); the clip uses the frames unstamped.
  mapfile -t picked < <(python3 "$out/stamp.py" "$dir" "$slice")
  python3 tools/ui_gate/sheet.py strip "$out/strips/$name.png" "${picked[@]}" --height "$height"
  # The clip: every frame at 60 fps, 480 px wide at most, as a looping GIF
  # with its own palette (no dithering, so no shimmer reads as a flash).
  ffmpeg -loglevel error -y -framerate 60 -i "$dir/f%03d.png" \
    -vf "scale='min(480,iw)':-2:flags=lanczos,split[a][b];[a]palettegen=stats_mode=full[p];[b][p]paletteuse=dither=none" \
    -loop 0 "$out/clips/$name.gif"
done
# Everything under art/ui/motion/ feeds the motion manifest's sources hash
# (tools/ui_bake/bake.js), strips and clips included, so the manifest is
# rebaked to match them; the sprites themselves come out byte for byte.
node tools/ui_bake/bake.js motion
python3 "$out/check_frames.py" "$frames_root"
