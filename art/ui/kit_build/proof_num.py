#!/usr/bin/env python3
"""Proof sheets of the baked numerals (batch 1c, kit_num.py) at the phone's
width and density: numbers set from the atlas pieces by their advances, at
100% and 200% text, in English and Brazilian Portuguese, normal and high
contrast, on the grounds they sit on; measured; and the contact sheets.

    python3 art/ui/kit_build/proof_num.py            # writes art/ui/kit_build/proof_num/
    python3 art/ui/kit_build/proof_num.py --check    # exit 1 if a check fails

The checks, for every piece in both atlases:
  - fill-contrast: the fill against its ink outline, at the fill's worst
    pixel (the fill's pixels, two pixels in from the outline): 4.5:1 and
    APCA Lc 60 (client/ui/colour_check.gd's bold short text);
  - outline: the outline that shows outside the fill, from the source's
    stroke (half of it), at least max(1.5 pt, 12% of the size);
  - tabular: every digit of a finish has one advance, and every piece of a
    finish one height.

The stills live outside art/ui/kit/ so they never change the bake's hash.
The numbers here are set by hand; in the game the client's own number
formatting picks the glyphs (report.md section 10.4).
"""
import json
import os
import re
import subprocess
import sys

import numpy as np
from PIL import Image, ImageDraw

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
import kit_num  # noqa: E402
import proof_kit as pk  # noqa: E402
from proof_kit import PX, ROOT, rgb, vgrad, wcag  # noqa: E402

OUT = os.path.join(HERE, "proof_num")
KIT = os.path.join(ROOT, "art/ui/kit")
WIDTH = 390
LC_NEEDED = 60  # bold words under 36 points (colour_check.gd's MIN_LC_SHORT)

CHARS = {str(d): str(d) for d in range(10)}
CHARS.update({",": "comma", ".": "period", ":": "colon", "/": "slash", "+": "plus", "−": "minus",
              "%": "percent", "×": "x", "?": "question", " ": "space"})

# What each language writes (report.md section 10.4): English 1,234 and 12.5;
# Brazilian Portuguese 1.234 and 12,5. Each row: (finish, number).
SAMPLES = {
    "en": [
        [("timer", "12:05"), ("timer_red", "0:09")],
        [("gold", "1,234"), ("gold", "+250"), ("gold", "×2")],
        [("white", "3/5"), ("white", "−15%"), ("white", "12.5"), ("white", "?")],
    ],
    "pt_br": [
        [("timer", "12:05"), ("timer_red", "0:09")],
        [("gold", "1.234"), ("gold", "+250"), ("gold", "×2")],
        [("white", "3/5"), ("white", "−15%"), ("white", "12,5"), ("white", "?")],
    ],
}


def apca(text, ground):
    """APCA Lc of text on ground, as client/ui/colour_check.gd computes it."""
    def y(c):
        c = np.asarray(c, dtype=float) / 255
        v = 0.2126729 * c[0] ** 2.4 + 0.7151522 * c[1] ** 2.4 + 0.0721750 * c[2] ** 2.4
        return v if v > 0.022 else v + (0.022 - v) ** 1.414
    yt, yb = y(text), y(ground)
    if abs(yb - yt) < 0.0005:
        return 0.0
    if yb > yt:
        s = (yb ** 0.56 - yt ** 0.57) * 1.14
        return 0.0 if s < 0.1 else (s - 0.027) * 100
    s = (yb ** 0.65 - yt ** 0.62) * 1.14
    return 0.0 if s > -0.1 else abs((s + 0.027) * 100)


def number(atlas, finish, text, scale):
    """The number set from its pieces: an RGBA picture at the phone's density,
    each piece drawn centred on its advance cell, pens a whole advance apart."""
    pieces = [atlas.man["pieces"]["num_%s_%s" % (finish, CHARS[ch])] for ch in text]
    k = scale * PX / atlas.man["px_per_point"]   # phone pixels per atlas pixel
    pad = (pieces[0]["w"] - pieces[0]["advance"]) / 2
    width = sum(p["advance"] for p in pieces) + 2 * pad
    out = Image.new("RGBA", (round(width * k), round(pieces[0]["h"] * k)))
    pen = 0.0
    for ch in text:
        p, im = atlas.piece("num_%s_%s" % (finish, CHARS[ch]))
        pic = im.resize((round(p["w"] * k), round(p["h"] * k)), Image.LANCZOS)
        out.alpha_composite(pic, (round(pen * k), 0))
        pen += p["advance"]
    return out


def sheet(atlas, hc, scale, lang):
    """One still: a band per ground, the language's numbers flowed in rows."""
    g = pk.grounds(hc)
    lines = []  # (band, [(picture, x_pt)], height_pt)
    for gname in g:
        for row in SAMPLES[lang]:
            x, line, h = 16.0, [], 0.0
            for finish, text in row:
                pic = number(atlas, finish, text, scale)
                w = pic.width / PX
                if line and x + w > WIDTH - 16:
                    lines.append((gname, line, h))
                    x, line, h = 16.0, [], 0.0
                line.append((pic, x, finish, text))
                x += w + 14
                h = max(h, pic.height / PX)
            lines.append((gname, line, h))
    heights = {}
    for gname, _, h in lines:
        heights[gname] = heights.get(gname, 12) + h + 6
    total = sum(heights.values())
    im = Image.new("RGB", (round(WIDTH * PX), round(total * PX)))
    y0, tops = 0.0, {}
    for gname in g:
        im.paste(vgrad(im.width, round(heights[gname] * PX) + 1, g[gname]), (0, round(y0 * PX)))
        tops[gname] = y0 + 8
        y0 += heights[gname]
    d = ImageDraw.Draw(im)
    placed = []
    for gname, line, h in lines:
        y = tops[gname]
        for pic, x, finish, text in line:
            im.paste(pic, (round(x * PX), round(y * PX)), pic)
            placed.append({"name": "%s %s @ %s" % (finish, text, gname),
                           "rect": [round(x, 2), round(y, 2), round(pic.width / PX, 2), round(pic.height / PX, 2)]})
        tops[gname] = y + h + 6
    y0 = 0.0
    for gname in g:  # the ground's name, small, so the sheet reads alone
        d.text((round((WIDTH - 6) * PX), round((y0 + 3) * PX)), gname, fill=(255, 255, 255) if gname != "parchment"
               else (42, 26, 16), font=pk.font(8), anchor="ra")
        y0 += heights[gname]
    return im, placed, total


def erode(mask, n):
    """The mask less every pixel within n pixels of its edge, diagonals too."""
    m = mask.copy()
    for _ in range(n):
        out = m.copy()
        for dy in (-1, 0, 1):
            for dx in (-1, 0, 1):
                out &= np.roll(np.roll(m, dy, 0), dx, 1)
        m = out
    return m


def source(finish, glyph):
    return open(os.path.join(KIT, "num_%s" % finish, glyph + ".svg")).read()


def measure(atlas, hc):
    """The checks on every numeral piece in this atlas."""
    rows = []
    ink = rgb(kit_num.HC["ink"]) if hc else rgb("ink_line")
    mode = "hc" if hc else "normal"
    for finish, (size, _, _) in kit_num.FINISHES.items():
        names = ["num_%s_%s" % (finish, gl) for gl in kit_num.GLYPHS]
        man = atlas.man["pieces"]
        # Tabular: one advance for the digits, one height for the finish.
        adv = {man["num_%s_%d" % (finish, i)]["advance"] for i in range(10)}
        hts = {man[n]["h"] for n in names}
        rows.append({"check": "tabular", "control": "num_%s" % finish, "advances": sorted(adv),
                     "heights": sorted(hts), "result": "PASS" if len(adv) == 1 and len(hts) == 1 else "FAIL"})
        # The outline that shows: half the source's stroke.
        line = float(re.search(r"stroke-width: ([0-9.]+);", source(finish, "0")).group(1))
        need = max(1.5, 0.12 * size)
        rows.append({"check": "outline", "control": "num_%s" % finish, "visible_pt": round(line / 2, 2),
                     "needed_pt": round(need, 2), "result": "PASS" if line / 2 >= need - 1e-6 else "FAIL"})
        # Fill against outline at the fill's worst pixel.
        worst = None
        for n in names:
            if n.endswith("_space"):
                continue
            _, im = atlas.piece(n)
            a = np.asarray(im, dtype=float)
            rgbv, alpha = a[..., :3], a[..., 3]
            dist = np.sqrt(((rgbv - np.array(ink)) ** 2).sum(-1))
            fill = erode((alpha > 250) & (dist > 60), 2)
            if not fill.any():
                rows.append({"check": "fill-contrast", "control": n, "result": "FAIL", "why": "no fill pixels"})
                continue
            px = rgbv[fill]
            ratios = [wcag(tuple(c), ink) for c in px[np.argsort(px @ [0.2126, 0.7152, 0.0722])[:20]]]
            lo = int(np.argmin(ratios))
            c = tuple(px[np.argsort(px @ [0.2126, 0.7152, 0.0722])[:20]][lo])
            r, lc = ratios[lo], apca(c, ink)
            if worst is None or r < worst[1]:
                worst = (n, r, lc, c)
        n, r, lc, c = worst
        rows.append({"check": "fill-contrast", "control": "num_%s (worst: %s)" % (finish, n),
                     "colour": "#%02X%02X%02X" % tuple(int(round(v)) for v in c), "ratio": round(r, 2),
                     "lc": round(lc, 1), "against": "outline",
                     "result": "PASS" if r >= 4.5 and lc >= LC_NEEDED else "FAIL"})
    for r in rows:
        r["mode"] = mode
    return rows


def main(argv):
    os.makedirs(OUT, exist_ok=True)
    results, fails = [], 0
    for hc in (False, True):
        atlas = pk.Atlas(hc)
        mode = "hc" if hc else "normal"
        rows = measure(atlas, hc)
        for scale in (1, 2):
            for lang in SAMPLES:
                im, placed, total = sheet(atlas, hc, scale, lang)
                stem = "numerals_%s_%d_%s" % (mode, scale * 100, lang)
                im.save(os.path.join(OUT, stem + ".png"))
                with open(os.path.join(OUT, stem + ".json"), "w") as f:
                    json.dump({"image": stem + ".png", "frame_pt": [WIDTH, round(total, 2)], "text_scale": scale,
                               "numbers": placed}, f, indent=1)
                    f.write("\n")
        for r in rows:
            fails += r["result"] == "FAIL"
        results += rows
        # Contact sheet: every numeral piece, as the gate's tool draws it.
        tiles = []
        for finish in kit_num.FINISHES:
            for gl in kit_num.GLYPHS:
                n = "num_%s_%s" % (finish, gl)
                _, pic = atlas.piece(n)
                path = os.path.join(OUT, "tiles", mode, n + ".png")
                os.makedirs(os.path.dirname(path), exist_ok=True)
                pic.save(path)
                tiles.append(path)
        subprocess.run([sys.executable, os.path.join(ROOT, "tools/ui_gate/sheet.py"), "contact",
                        os.path.join(OUT, "contact_num_%s.png" % mode), *tiles, "--sizes", "60,120"], check=True)
    with open(os.path.join(OUT, "results.json"), "w") as f:
        json.dump(results, f, indent=1)
        f.write("\n")
    for r in results:
        if r["result"] == "FAIL" or "--all" in argv:
            print(json.dumps(r))
    print("%d results, %d fail" % (len(results), fails))
    return 1 if fails and "--check" in argv else 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
