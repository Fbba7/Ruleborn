#!/usr/bin/env bash
# The store builds (TC.3): the simulation compiled for the phone's arm64, and
# Godot's export of the client around it, with the presets in
# export_presets.cfg.
#
#     bash client/export.sh android   an .apk in build/android/
#     bash client/export.sh ios       an Xcode project in build/ios/
#     bash client/export.sh check     what this machine can build, compiled
#                                     for both phones without linking
#
# Android needs the SDK and the NDK (ANDROID_HOME, ANDROID_NDK_HOME) and Java.
# The iPhone needs a Mac with Xcode, and the App Store team to sign as
# (RULEBORN_APPLE_TEAM_ID); the bundle identifier is the preset's.
# Godot's export templates are fetched once, like Godot, into its own folder.
set -euo pipefail
here="$(cd "$(dirname "$0")" && pwd)"
root="$(cd "$here/.." && pwd)"
target="${1:-check}"

godot="$(bash "$here/build.sh" | tail -n 1)"
templates="$HOME/.local/share/godot/export_templates/4.7.2.stable"
if [ "$target" != check ] && [ ! -f "$templates/version.txt" ]; then
  echo "fetching Godot's export templates"
  mkdir -p "$templates"
  curl -sSL --fail -o "$templates.tpz" \
    "https://github.com/godotengine/godot/releases/download/4.7.2-stable/Godot_v4.7.2-stable_export_templates.tpz"
  # The templates become the app players install: Godot's own sum for them,
  # checked before they are unpacked (T12's SR-26).
  python3 -c "import hashlib, sys; sys.exit(hashlib.sha512(open(sys.argv[1], 'rb').read()).hexdigest() != sys.argv[2])" \
    "$templates.tpz" ca4d71c4d7b81dfc15d1a98baa07534aa95b03fdda78a0075b06672e1648d2e5f40980c9adc28d23e1b92e732ee7bf3461997aa804af74ec2fcd7a93ccb84079 \
    || { rm -f "$templates.tpz"; echo "the export templates do not match their pinned sum" >&2; exit 1; }
  python3 - "$templates.tpz" "$templates" <<'EOF'
import os, sys, zipfile
z = zipfile.ZipFile(sys.argv[1])
for n in z.namelist():
    if not n.endswith("/") and any(k in n for k in ("android", "ios", "version")):
        open(os.path.join(sys.argv[2], os.path.basename(n)), "wb").write(z.read(n))
EOF
  rm "$templates.tpz"
fi

case "$target" in
  android)
    : "${ANDROID_HOME:?set ANDROID_HOME to the Android SDK}"
    : "${ANDROID_NDK_HOME:?set ANDROID_NDK_HOME to the Android NDK}"
    host="$(uname -s | tr '[:upper:]' '[:lower:]')-x86_64"
    export CARGO_TARGET_AARCH64_LINUX_ANDROID_LINKER="$ANDROID_NDK_HOME/toolchains/llvm/prebuilt/$host/bin/aarch64-linux-android24-clang"
    rustup target add aarch64-linux-android
    (cd "$here/ext" && cargo build --release --quiet --target aarch64-linux-android)
    mkdir -p "$here/bin/android" "$root/build/android"
    cp "$here/ext/target/aarch64-linux-android/release/libruleborn_godot.so" "$here/bin/android/"
    # A debug export, signed with Godot's debug key; a store release takes the
    # upload key from GODOT_ANDROID_KEYSTORE_RELEASE_PATH, _USER and _PASSWORD.
    mode="--export-debug"
    [ -n "${GODOT_ANDROID_KEYSTORE_RELEASE_PATH:-}" ] && mode="--export-release"
    "$godot" --headless --path "$here" "$mode" "Android" "$root/build/android/ruleborn.apk"
    ;;
  ios)
    [ "$(uname -s)" = Darwin ] || { echo "the iPhone build needs a Mac with Xcode" >&2; exit 1; }
    : "${RULEBORN_APPLE_TEAM_ID:?set RULEBORN_APPLE_TEAM_ID to the App Store team}"
    rustup target add aarch64-apple-ios
    (cd "$here/ext" && cargo build --release --quiet --target aarch64-apple-ios)
    mkdir -p "$here/bin/ios" "$root/build/ios"
    cp "$here/ext/target/aarch64-apple-ios/release/libruleborn_godot.dylib" "$here/bin/ios/"
    # The team is the owner's, so it is never written into the preset: a copy
    # carries it for this export only.
    cp "$here/export_presets.cfg" "$here/export_presets.cfg.kept"
    trap 'mv "$here/export_presets.cfg.kept" "$here/export_presets.cfg"' EXIT
    sed -i '' "s/^application\/app_store_team_id=\"\"/application\/app_store_team_id=\"$RULEBORN_APPLE_TEAM_ID\"/" \
      "$here/export_presets.cfg"
    "$godot" --headless --path "$here" --export-release "iPhone" "$root/build/ios/Ruleborn.ipa"
    echo "open build/ios/Ruleborn.xcodeproj in Xcode to sign, archive and upload"
    ;;
  check)
    # Both phones' arm64, compiled here without their linkers: the iPhone's
    # static library needs none, and Android's library is only checked. The
    # simulation's own wasm library is linked by nobody here (/bin/true), so
    # it is not stripped either.
    rustup target add aarch64-linux-android aarch64-apple-ios >/dev/null
    (cd "$here/ext" && CARGO_TARGET_AARCH64_APPLE_IOS_LINKER=/bin/true CARGO_PROFILE_RELEASE_STRIP=false \
      cargo rustc --release --quiet --lib --crate-type staticlib --target aarch64-apple-ios)
    (cd "$here/ext" && cargo check --release --quiet --lib --target aarch64-linux-android)
    # And the project's data, packed with the Android preset: every file the
    # game reads by path is in it.
    mkdir -p "$root/build/check"
    "$godot" --headless --path "$here" --export-pack "Android" "$root/build/check/client.pck" >/dev/null 2>&1
    python3 "$here/pack_check.py" "$root/build/check/client.pck"
    echo "arm64 for iPhone and Android compiles"
    ;;
  *)
    echo "usage: bash client/export.sh android|ios|check" >&2
    exit 2
    ;;
esac
