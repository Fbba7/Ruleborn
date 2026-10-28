"""Pack bake_hud.js's pieces into one atlas (T14's proof), so the HUD draws
from one texture and Godot batches it.

    python3 tools/ui_research/pack_atlas.py PIECES_DIR OUT_DIR [NAME]

PIECES_DIR holds one PNG a piece and pieces.json ({name: {slice}}); OUT_DIR
gets NAME.webp (atlas by default; lossless: the repository keeps images under 400 KB, which a
PNG of this atlas is not) and manifest.json ({name: {x, y, w, h, slice}}). Shelves,
tallest first, 2 px apart, 1024 wide.
"""
import json
import os
import sys

from PIL import Image

WIDTH = 1024
PAD = 2


def main(src, out, name="atlas"):
    meta = json.load(open(os.path.join(src, "pieces.json")))
    images = {n: Image.open(os.path.join(src, n + ".png")).convert("RGBA") for n in meta}
    order = sorted(images, key=lambda n: (-images[n].height, n))
    x = y = PAD
    shelf = 0
    places = {}
    for n in order:
        im = images[n]
        if x + im.width + PAD > WIDTH:
            x = PAD
            y += shelf + PAD
            shelf = 0
        places[n] = (x, y)
        x += im.width + PAD
        shelf = max(shelf, im.height)
    height = 1
    while height < y + shelf + PAD:
        height *= 2
    atlas = Image.new("RGBA", (WIDTH, height), (0, 0, 0, 0))
    manifest = {}
    for n in sorted(places):
        px, py = places[n]
        atlas.paste(images[n], (px, py))
        w, h = images[n].size
        manifest[n] = {"x": px, "y": py, "w": w, "h": h, "slice": meta[n].get("slice")}
    os.makedirs(out, exist_ok=True)
    atlas.save(os.path.join(out, name + ".webp"), lossless=True, method=6)
    with open(os.path.join(out, "manifest.json"), "w") as f:
        json.dump(manifest, f, indent=1, sort_keys=True)
        f.write("\n")
    print(f"packed {len(manifest)} pieces into {name}.webp ({WIDTH}x{height})")


if __name__ == "__main__":
    main(*sys.argv[1:4])
