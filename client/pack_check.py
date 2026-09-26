#!/usr/bin/env python3
"""What a store build carries: the files in a Godot pack exported with the
Android preset (client/export.sh check). The game reads its word catalogues,
its design tokens and its golden replays by path, so a pack without them
shows keys, not words; the tests never ship.

    python3 client/pack_check.py build/check/client.pck
"""

from __future__ import annotations

import struct
import sys

# Read by path at run time (scripts/strings.gd, ui/tokens.gd,
# scripts/replay_screen.gd), the scene the app opens on (exported, behind its
# remap), and the project settings.
NEEDED = {"i18n/strings.csv", "i18n/content.csv", "ui/tokens.json", "goldens/planned-clean.rbh",
          "scenes/home.tscn.remap", "project.binary"}


def files(path: str) -> list[str]:
    """Godot 4.5's pack: "GDPC", its format, version and flags, where the
    files start and where their directory is; each entry a padded path (no
    res://), offset, size, md5 and flags."""
    pack = open(path, "rb").read()
    if pack[:4] != b"GDPC":
        sys.exit(f"{path} is not a Godot pack")
    pos = struct.unpack_from("<Q", pack, 32)[0]
    count = struct.unpack_from("<I", pack, pos)[0]
    pos += 4
    out = []
    for _ in range(count):
        n = struct.unpack_from("<I", pack, pos)[0]
        out.append(pack[pos + 4:pos + 4 + n].rstrip(b"\0").decode())
        pos += 4 + n + 8 + 8 + 16 + 4
    return out


def main() -> None:
    listed = files(sys.argv[1])
    missing = sorted(NEEDED - set(listed))
    tests = sorted(f for f in listed if f.startswith("tests/"))
    if missing or tests:
        sys.exit(f"the exported pack is wrong: missing {missing}, tests packed {tests}")
    print(f"the exported pack's {len(listed)} files hold what the game reads, and no tests")


if __name__ == "__main__":
    main()
