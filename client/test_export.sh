#!/usr/bin/env bash
# export.sh's Android signing gate (SEC-30), run on a copy of the script with
# build.sh, Godot, rustup and cargo stubbed: nothing is fetched or built.
#
#     bash client/test_export.sh
set -euo pipefail
here="$(cd "$(dirname "$0")" && pwd)"
work="$(mktemp -d)"
trap 'rm -rf "$work"' EXIT

mkdir -p "$work/client/ext/target/aarch64-linux-android/release" "$work/bin" "$work/home" "$work/sdk" "$work/ndk"
cp "$here/export.sh" "$work/client/export.sh"
touch "$work/client/ext/target/aarch64-linux-android/release/libruleborn_godot.so"
mkdir -p "$work/home/.local/share/godot/export_templates/4.7.2.stable"
touch "$work/home/.local/share/godot/export_templates/4.7.2.stable/version.txt"
printf '#!/usr/bin/env bash\necho "$*" >> "%s/godot.log"\n' "$work" > "$work/bin/godot"
printf '#!/usr/bin/env bash\necho "%s/bin/godot"\n' "$work" > "$work/client/build.sh"
printf '#!/usr/bin/env bash\nexit 0\n' > "$work/bin/rustup"
printf '#!/usr/bin/env bash\nexit 0\n' > "$work/bin/cargo"
chmod +x "$work/bin/godot" "$work/bin/rustup" "$work/bin/cargo"

pass=0
fail=0
check() {
  if [ "$2" = yes ]; then pass=$((pass + 1)); echo "ok - $1"; else fail=$((fail + 1)); echo "not ok - $1"; fi
}

run() {
  rm -f "$work/godot.log"
  env -u GODOT_ANDROID_KEYSTORE_RELEASE_PATH -u RULEBORN_DEBUG_EXPORT HOME="$work/home" \
    PATH="$work/bin:$PATH" ANDROID_HOME="$work/sdk" ANDROID_NDK_HOME="$work/ndk" "$@" \
    bash "$work/client/export.sh" android > "$work/out.txt" 2>&1
}

status=0
run || status=$?
check "without the upload key, the Android export refuses and exports nothing" \
  "$([ "$status" = 1 ] && [ ! -f "$work/godot.log" ] && grep -q RULEBORN_DEBUG_EXPORT "$work/out.txt" && echo yes || echo no)"

status=0
run RULEBORN_DEBUG_EXPORT=1 || status=$?
check "a developer's RULEBORN_DEBUG_EXPORT=1 still exports a debug APK, and is warned" \
  "$([ "$status" = 0 ] && grep -q -- "--export-debug Android" "$work/godot.log" && grep -q "debug-signed" "$work/out.txt" && echo yes || echo no)"

status=0
run GODOT_ANDROID_KEYSTORE_RELEASE_PATH="$work/upload.keystore" || status=$?
check "with the upload key, the export is a release, as before" \
  "$([ "$status" = 0 ] && grep -q -- "--export-release Android" "$work/godot.log" && echo yes || echo no)"

echo "$pass passed, $fail failed"
[ "$fail" = 0 ]
