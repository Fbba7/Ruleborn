#!/usr/bin/env bash
# Build the client for this machine: the simulation as a GDExtension, the
# golden replays it plays, and Godot's import cache.
#
#     bash client/build.sh
#
# Godot itself is fetched once, pinned to the version project.godot names, into
# ~/.cache/ruleborn (or $RULEBORN_GODOT, if set, is used as it is).
set -euo pipefail
here="$(cd "$(dirname "$0")" && pwd)"
root="$(cd "$here/.." && pwd)"

version="4.7.2-stable"
godot="${RULEBORN_GODOT:-$HOME/.cache/ruleborn/Godot_v${version}_linux.x86_64}"
if [ ! -x "$godot" ]; then
  mkdir -p "$(dirname "$godot")"
  url="https://github.com/godotengine/godot/releases/download/${version}/Godot_v${version}_linux.x86_64.zip"
  echo "fetching Godot ${version}"
  curl -sSL --fail -o "$godot.zip" "$url"
  # Godot's own SHA512-SUMS.txt for this release: a swapped download is
  # refused before it is unpacked (T12's SR-26).
  python3 -c "import hashlib, sys; sys.exit(hashlib.sha512(open(sys.argv[1], 'rb').read()).hexdigest() != sys.argv[2])" \
    "$godot.zip" 9aa00f7a605200940bce3027a567b782f49bd8e940dd06ae9e987bd65aee1b1467edd56ed84fcdcbdd44354bf613bdbb4e5d2913e925850368e150c59ed54c65 \
    || { rm -f "$godot.zip"; echo "Godot's download does not match its pinned sum" >&2; exit 1; }
  python3 -c "import sys, zipfile; zipfile.ZipFile(sys.argv[1]).extractall(sys.argv[2])" \
    "$godot.zip" "$(dirname "$godot")"
  rm "$godot.zip"
  chmod +x "$godot"
fi

# The simulation, linked into the client (§24.7). Release, like the server's
# WebAssembly build, so both run the same optimised arithmetic.
(cd "$here/ext" && cargo build --release --quiet)
mkdir -p "$here/bin" "$here/goldens"
cp "$here/ext/target/release/libruleborn_godot.so" "$here/bin/"
cp "$root"/sim/golden/*.rbh "$here/goldens/"

# Godot's first open of a project writes its import cache; a missing cache
# makes class_name scripts unknown to a headless run.
"$godot" --headless --path "$here" --import >/dev/null 2>&1 || true
echo "$godot"
