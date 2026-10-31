#!/usr/bin/env python3
"""One contact sheet of all five key frames: a row a page (home, heist,
result, character, settings), a column a form (as written, text at 200%,
high contrast), each in English and Brazilian Portuguese: the 30 stills
shoot_keyframes.mjs makes, each at a quarter of its size, named.

    python3 art/ui/keyframes/contact_sheet.py   writes contact_sheet.png
"""
import pathlib

from PIL import Image, ImageDraw, ImageFont

HERE = pathlib.Path(__file__).resolve().parent
ROOT = HERE.parent.parent.parent
PAGES = [("01-home", "Home"), ("02-heist", "Heist"), ("03-result", "Result"),
         ("04-character", "Character"), ("05-settings", "Settings")]
FORMS = [("", "As written"), ("_text200", "Text 200%"), ("_hc", "High contrast")]
LANGS = [("", "en"), ("_pt_BR", "pt_BR")]
THUMB = (270, 585)  # a quarter of 1080 x 2340
GAP = 16
SIDE = 150
HEAD = 64
GROUND = (20, 18, 26)
WORDS = (238, 230, 214)
DIM = (160, 150, 176)


def font(size):
    return ImageFont.truetype(str(ROOT / "client/ui/fonts/manrope/Manrope-Variable.ttf"), size)


def main():
    cols = [(f + l, f"{fn} · {ln}") for f, fn in FORMS for l, ln in LANGS]
    w = SIDE + len(cols) * (THUMB[0] + GAP) + GAP
    h = HEAD + len(PAGES) * (THUMB[1] + GAP) + GAP
    sheet = Image.new("RGB", (w, h), GROUND)
    d = ImageDraw.Draw(sheet)
    head, side = font(20), font(26)
    for c, (_, name) in enumerate(cols):
        d.text((SIDE + c * (THUMB[0] + GAP) + THUMB[0] / 2, HEAD / 2), name, fill=WORDS, font=head, anchor="mm")
    for r, (page, name) in enumerate(PAGES):
        y = HEAD + r * (THUMB[1] + GAP)
        d.text((GAP, y + THUMB[1] / 2), name, fill=WORDS, font=side, anchor="lm")
        d.text((GAP, y + THUMB[1] / 2 + 30), page[:2], fill=DIM, font=head, anchor="lm")
        for c, (suffix, _) in enumerate(cols):
            still = Image.open(HERE / f"{page}{suffix}.png").convert("RGB").resize(THUMB, Image.LANCZOS)
            sheet.paste(still, (SIDE + c * (THUMB[0] + GAP), y))
    sheet.save(HERE / "contact_sheet.png", optimize=True)
    print(f"contact_sheet.png: {w} x {h}, {len(PAGES) * len(cols)} stills")


if __name__ == "__main__":
    main()
