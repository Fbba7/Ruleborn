"""The AI UI artist's icons against what the game and the design have (T14,
docs/art/ui-quality/report.md section 9), as one PNG under 400 KB.

    python3 tools/ui_research/icons_compare.py docs/art/ui-quality/ai-artist-icons.png

Rows: the client's icon today (the design's own, exported at 144 px); the
icon as the design's result screen draws it (cropped from the still); the
AI UI artist's (bake_icons.js, 256 px); and both at phone size, on the
design's parchment reward tile at 128 px and alone at 48 px. Ruleborn has no
chest, so the chest's column sets it beside the loot bag, the game's nearest
reward container, and has no design crop. The last column is a crew member
from its own model (Pip, a Skyskipper), against today's heist portrait and
the design's.
"""
import io
import sys

from PIL import Image, ImageDraw, ImageFont

FONT = "client/ui/fonts/manrope/Manrope-Variable.ttf"
STILL = "art/design/stills/screens/07-heist-result-clean.png"
STILLS = {"pip": "art/design/stills/screens/02-heist.png"}
# name, the client's icon today, its box in the design still (or None).
ICONS = [
    ("starlight", "client/ui/icons/png/resources/starlight.png", (108, 834, 182, 902)),
    ("essence", "client/ui/icons/png/resources/essence.png", (356, 832, 422, 904)),
    ("renown", "client/ui/icons/png/resources/renown.png", (600, 836, 672, 902)),
    ("chest", "client/ui/icons/png/heiststatus/lootbag.png", None),
    # A crew member: today's portrait cropped from the deployed heist HUD
    # (heist screen, MANIFEST crew), and the design's from its heist still.
    ("pip", "docs/art/ui-quality/crew-today-crop.png", (14, 1300, 140, 1430)),
]
ROWS = ["Client today", "Design still", "AI UI artist (256 px)", "Phone size: today | AI"]
CELL = 220
LABEL = 300
BG = (58, 38, 92)
LIMIT = 390_000


def fit(im, side):
    im = im.convert("RGBA")
    k = side / max(im.width, im.height)
    return im.resize((max(1, round(im.width * k)), max(1, round(im.height * k))), Image.LANCZOS)


def tile(icon, side):
    """The design's parchment reward tile with an icon on it, at phone size."""
    t = Image.new("RGBA", (side, side), (0, 0, 0, 0))
    d = ImageDraw.Draw(t)
    d.rounded_rectangle((2, 6, side - 3, side - 1), 18, fill=(74, 42, 16))
    d.rounded_rectangle((2, 2, side - 3, side - 7), 18, fill=(253, 246, 228), outline=(242, 180, 60), width=4)
    i = fit(icon, side * 0.62)
    t.alpha_composite(i, ((side - i.width) // 2, (side - i.height) // 2 - 4))
    return t


def main(out):
    font = ImageFont.truetype(FONT, 24)
    sheet = Image.new("RGB", (LABEL + CELL * len(ICONS) + 20, 60 + CELL * len(ROWS)), BG)
    d = ImageDraw.Draw(sheet)
    for c, (name, _, _) in enumerate(ICONS):
        d.text((LABEL + CELL * c + 16, 16), name.capitalize() + {"chest": " (vs loot bag)", "pip": " (crew)"}.get(name, ""),
               fill=(255, 222, 140), font=font)
    for r, label in enumerate(ROWS):
        d.text((16, 60 + CELL * r + CELL // 2 - 14), label, fill=(236, 228, 246), font=font)
    for c, (name, today, box) in enumerate(ICONS):
        x = LABEL + CELL * c
        ai = Image.open(f"client/prototypes/ui_quality/icons/{name}.png").convert("RGBA")
        still = Image.open(STILLS.get(name, STILL)).convert("RGBA")
        cells = [fit(Image.open(today), 196), fit(still.crop(box), 196) if box else None, fit(ai, 200)]
        for r, im in enumerate(cells):
            if im is None:
                d.text((x + 40, 60 + CELL * r + CELL // 2 - 14), "(none)", fill=(150, 130, 180), font=font)
                continue
            sheet.paste(im, (x + (CELL - im.width) // 2, 60 + CELL * r + (CELL - im.height) // 2), im)
        # Phone size: on the tile at 128 px (today above, the AI's below is
        # too tall for the cell, so side by side at 96), and alone at 48.
        y = 60 + CELL * 3
        for k, src in enumerate([Image.open(today), ai]):
            t = tile(src, 96)
            sheet.paste(t, (x + 8 + 104 * k, y + 20), t)
            s = fit(src, 48)
            sheet.paste(s, (x + 32 + 104 * k, y + 140), s)
    for colours in (None, 256, 128):
        img = sheet if colours is None else sheet.quantize(colours, method=Image.Quantize.MEDIANCUT)
        buf = io.BytesIO()
        img.save(buf, "PNG", optimize=True)
        if buf.tell() <= LIMIT:
            break
    open(out, "wb").write(buf.getvalue())
    print(f"wrote {out} ({buf.tell() // 1024} KB)")


if __name__ == "__main__":
    main(sys.argv[1])
