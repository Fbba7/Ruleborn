#!/usr/bin/env python3
"""Side-by-side judging sheet (§21.10's two tests): stills in a row, each also
shown at phone size and as a grayscale thumbnail beneath.

    python3 tools/art/compare.py out.png a.png b.png [c.png ...] [--h 360] [--thumb 72]
        [--crop x,y,w,h] [--labels "design,ours"]

`--crop` cuts the same box out of every input first (pixels of the input).
"""
import argparse

from PIL import Image, ImageDraw, ImageOps


def main() -> None:
    ap = argparse.ArgumentParser()
    ap.add_argument("out")
    ap.add_argument("inputs", nargs="+")
    ap.add_argument("--h", type=int, default=360, help="height of the full-size row")
    ap.add_argument("--thumb", type=int, default=72, help="height of the grayscale thumbnail")
    ap.add_argument("--crop", default="")
    ap.add_argument("--labels", default="")
    ap.add_argument("--bg", default="#241A38")
    a = ap.parse_args()
    labels = a.labels.split(",") if a.labels else []
    tiles = []
    for p in a.inputs:
        im = Image.open(p).convert("RGBA")
        if a.crop:
            x, y, w, h = (int(v) for v in a.crop.split(","))
            im = im.crop((x, y, x + w, y + h))
        bg = Image.new("RGBA", im.size, a.bg)
        im = Image.alpha_composite(bg, im).convert("RGB")
        big = im.resize((max(1, round(im.width * a.h / im.height)), a.h), Image.LANCZOS)
        th = ImageOps.grayscale(im.resize((max(1, round(im.width * a.thumb / im.height)), a.thumb), Image.LANCZOS))
        tiles.append((big, th.convert("RGB")))
    gap = 8
    width = sum(t[0].width for t in tiles) + gap * (len(tiles) + 1)
    height = a.h + a.thumb + gap * 3 + (18 if labels else 0)
    sheet = Image.new("RGB", (width, height), a.bg)
    d = ImageDraw.Draw(sheet)
    x = gap
    for i, (big, th) in enumerate(tiles):
        y = gap
        if labels:
            d.text((x, y), labels[i] if i < len(labels) else "", fill="#F2E8D8")
            y += 18
        sheet.paste(big, (x, y))
        sheet.paste(th, (x, y + a.h + gap))
        x += big.width + gap
    sheet.save(a.out, optimize=True)


if __name__ == "__main__":
    main()
