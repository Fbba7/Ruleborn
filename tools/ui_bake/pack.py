"""Compose one atlas for tools/ui_bake/bake.js and write it as lossless WebP.

    python3 tools/ui_bake/pack.py < job.json

The job is {"out", "width", "height", "pieces": [[png, x, y, w, h], ...]}:
bake.js has already chosen every place, so this only copies each piece's
pixels into a transparent atlas and encodes it. Lossless WebP at method 6
from the same pixels is the same bytes, which keeps the bake byte for byte.
"""
import json
import sys

from PIL import Image


def main():
    job = json.load(sys.stdin)
    atlas = Image.new("RGBA", (job["width"], job["height"]), (0, 0, 0, 0))
    for png, x, y, w, h in job["pieces"]:
        im = Image.open(png).convert("RGBA")
        if im.size != (w, h):
            sys.exit(f"pack: {png} is {im.size[0]}x{im.size[1]}, expected {w}x{h}")
        atlas.paste(im, (x, y))
    atlas.save(job["out"], format="WEBP", lossless=True, quality=100, method=6)


if __name__ == "__main__":
    main()
