#!/usr/bin/env python3
"""Each character's colour against its design portrait: the mean colour of
its bust (client/tests/shots/creature_colour.gd) and of the portrait in
art/design/stills/portraits, each over its own lightness, so the hue and
saturation are compared apart from how light the two lights draw them.

    xvfb-run -a "$GODOT" --rendering-driver opengl3 --path client \
        -s res://tests/shots/creature_colour.gd | grep MEAN > means.txt
    python3 tools/art/colour.py means.txt

($GODOT is ~/.cache/ruleborn/Godot_v4.7.2-stable_linux.x86_64; shoot.sh keeps
only a run's last lines, too few for all 24.)

Prints each kind's two triples, their largest channel difference, the two
lightnesses, and the sum of the differences (lower is closer)."""
import pathlib
import sys

from PIL import Image

ROOT = pathlib.Path(__file__).resolve().parents[2]


def portrait_mean(kind):
    path = ROOT / "art/design/stills/portraits" / f"{kind}.png"
    if not path.exists():
        return None
    image = Image.open(path).convert("RGBA").resize((60, 60))
    px = [p[:3] for p in image.getdata() if p[3] > 200 and sum(p[:3]) > 60]
    return tuple(sum(c[i] for c in px) / len(px) for i in range(3))


def main():
    total = 0.0
    for line in pathlib.Path(sys.argv[1]).read_text().splitlines():
        parts = line.split()
        if len(parts) != 5 or parts[0] != "MEAN":
            continue
        kind, ours = parts[1], tuple(float(v) for v in parts[2:])
        design = portrait_mean(kind)
        if design is None:
            continue
        lo, ld = sum(ours) / 3, sum(design) / 3
        on = [c / lo for c in ours]
        dn = [c / ld for c in design]
        diff = max(abs(a - b) for a, b in zip(on, dn))
        total += diff
        print(f"{kind:12s} ours {on[0]:.2f}/{on[1]:.2f}/{on[2]:.2f} design {dn[0]:.2f}/{dn[1]:.2f}/{dn[2]:.2f} "
              f"diff {diff:.2f} light {lo:.0f}/{ld:.0f}")
    print(f"sum {total:.2f}")


if __name__ == "__main__":
    main()
