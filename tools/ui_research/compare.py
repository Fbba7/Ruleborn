"""Side-by-side stills for docs/art/ui-quality/ (T14), each PNG under 400 KB.

    python3 tools/ui_research/compare.py out.png "Label A=a.png" "Label B=b.png" [--crop x0,y0,x1,y1] [--h 1100]
    python3 tools/ui_research/compare.py out.png ... --note "text for a panel with no image"

Each image is cropped (in fractions of its size, when --crop is given, so
stills of different sizes crop alike), scaled to one height and set in a row
with its label over it. A `Label=@text` panel holds words instead of an image
(the benchmark's description: no copyrighted game art enters the repo). The
row is quantised to a palette until it fits the 400 KB rule.
"""
import io
import sys
import textwrap

from PIL import Image, ImageDraw, ImageFont

FONT = "client/ui/fonts/manrope/Manrope-Variable.ttf"
LIMIT = 390_000


def main(argv):
    out = argv[0]
    crop = None
    height = 1100
    panels = []
    i = 1
    while i < len(argv):
        a = argv[i]
        if a == "--crop":
            crop = [float(v) for v in argv[i + 1].split(",")]
            i += 2
            continue
        if a == "--h":
            height = int(argv[i + 1])
            i += 2
            continue
        label, _, src = a.partition("=")
        panels.append((label, src))
        i += 1
    head = 44
    font = ImageFont.truetype(FONT, 26)
    small = ImageFont.truetype(FONT, 22)
    tiles = []
    for label, src in panels:
        if src.startswith("@"):
            w = int(height * 0.46)
            tile = Image.new("RGB", (w, height), (34, 26, 44))
            d = ImageDraw.Draw(tile)
            y = 20
            for para in src[1:].split("|"):
                for line in textwrap.wrap(para, 34):
                    d.text((18, y), line, fill=(236, 228, 246), font=small)
                    y += 30
                y += 14
        else:
            im = Image.open(src).convert("RGB")
            if crop:
                im = im.crop((int(crop[0] * im.width), int(crop[1] * im.height), int(crop[2] * im.width),
                              int(crop[3] * im.height)))
            tile = im.resize((max(1, round(im.width * height / im.height)), height), Image.LANCZOS)
        tiles.append((label, tile))
    gap = 12
    width = sum(t.width for _, t in tiles) + gap * (len(tiles) + 1)
    sheet = Image.new("RGB", (width, height + head + gap), (22, 16, 30))
    x = gap
    d = ImageDraw.Draw(sheet)
    for label, tile in tiles:
        d.text((x, 8), label, fill=(255, 222, 140), font=font)
        sheet.paste(tile, (x, head))
        x += tile.width + gap
    for colours in (None, 256, 128, 64):
        img = sheet if colours is None else sheet.quantize(colours, method=Image.Quantize.MEDIANCUT, dither=Image.Dither.FLOYDSTEINBERG)
        buf = io.BytesIO()
        img.save(buf, "PNG", optimize=True)
        if buf.tell() <= LIMIT:
            break
    while buf.tell() > LIMIT:
        sheet = sheet.resize((sheet.width * 9 // 10, sheet.height * 9 // 10), Image.LANCZOS)
        buf = io.BytesIO()
        sheet.quantize(128).save(buf, "PNG", optimize=True)
    open(out, "wb").write(buf.getvalue())
    print(f"wrote {out} ({buf.tell() // 1024} KB)")


if __name__ == "__main__":
    main(sys.argv[1:])
