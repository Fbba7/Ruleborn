#!/usr/bin/env python3
"""The frames a motion strip shows, stamped with their frame number and time
(art/ui/motion/strips.sh; P2-AIA-motion-2).

    stamp.py <frames-dir> <a:b:c>

Takes the frames f000.png... of <frames-dir> in the python slice a:b:c,
writes each with a band along its top reading "frame k  N ms" (at 60 fps)
to <frames-dir>/strip/, and prints their paths in order.
"""
import pathlib
import sys

from PIL import Image, ImageDraw, ImageFont

FPS = 60
BAND = 34
INK = (20, 18, 26)
PAPER = (246, 244, 250)


def font(size):
    for p in ("/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf",
              "/usr/share/fonts/truetype/liberation/LiberationSans-Bold.ttf"):
        if pathlib.Path(p).exists():
            return ImageFont.truetype(p, size)
    return ImageFont.load_default()


def main():
    src = pathlib.Path(sys.argv[1])
    a, b, c = (int(x) for x in sys.argv[2].split(":"))
    out = src / "strip"
    out.mkdir(exist_ok=True)
    f = font(24)
    for path in sorted(src.glob("f[0-9]*.png"))[a:b:c]:
        k = int(path.stem[1:])
        im = Image.open(path).convert("RGB")
        sheet = Image.new("RGB", (im.width, im.height + BAND), PAPER)
        sheet.paste(im, (0, BAND))
        ImageDraw.Draw(sheet).text((10, 4), f"frame {k}   {k * 1000 / FPS:.0f} ms", fill=INK, font=f)
        dest = out / path.name
        sheet.save(dest)
        print(dest)


if __name__ == "__main__":
    main()
