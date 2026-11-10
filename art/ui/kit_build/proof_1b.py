#!/usr/bin/env python3
"""Proofs the kit's batch 1b (kit_1b.py) at phone size, in both modes.

    python3 art/ui/kit_build/proof_1b.py [--check] [--all]

Two stills a mode, drawn from the baked atlas as the phone shows it:
`controls` puts the discs (each state, the lock on the locked one), the
pill (not on parchment: it sits in the top bar), the tags, the badges and
the bars on each of the four grounds;
`surfaces` puts the dark card (plain, locked, selected), the glass panel,
the well with its bars, and the school disc tinted for each school.

The gate's value-steps check runs on every interactive control (the discs
and the pill), and each word is measured against the face under it, 4.5:1.
The contact sheets hold every batch 1b piece through the gate's tool.
"""
import json
import os
import subprocess
import sys

import numpy as np
from PIL import Image, ImageDraw

import proof_kit as pk
from proof_kit import PX, ROOT, rgb, vgrad, wcag

sys.path.insert(0, os.path.join(ROOT, "tools/ui_gate"))
import checks  # noqa: E402

OUT = os.path.join(os.path.dirname(os.path.abspath(__file__)), "proof_1b")
FRAME = (390, 844)
SCHOOLS = ["motion", "matter", "time", "energy", "life", "spirit"]
# The skins batch 1b adds to the kit atlas.
SKINS = ["panel_dark", "panel_glass", "well", "badge", "pill", "tag", "bar_track", "bar_fill", "disc",
         "disc_school", "locked", "selected", "spinner"]
# Batch 2c's shapes in batch 1b's skins: proof_2c.py holds them.
LATER = {"panel_dark__album", "panel_dark__fact", "panel_dark__plate", "bar_track__bar_track_light", "tag__tag",
         "tag__island_label", "pill__pill_gold_edge"}


class Atlas(pk.Atlas):
    def has(self, name):
        return name in self.man["pieces"]


def tint(im, hexcol):
    """A neutral piece times its vertex colour, as the kit tints it."""
    a = np.asarray(im, dtype=float)
    c = np.array(rgb(hexcol) + (255,), dtype=float) / 255
    return Image.fromarray(np.clip(a * c, 0, 255).astype(np.uint8), "RGBA")


def text(im, xy, words, pt, ink, outline=None, anchor="mm"):
    d = ImageDraw.Draw(im)
    f = pk.font(pt)
    sw = round(1.5 * PX) if outline else 0
    d.text((round(xy[0] * PX), round(xy[1] * PX)), words, fill=ink, font=f, anchor=anchor,
           stroke_width=sw, stroke_fill=outline)


class Board:
    def __init__(self, hc):
        self.hc = hc
        self.im = Image.new("RGB", (round(FRAME[0] * PX), round(FRAME[1] * PX)))
        self.controls, self.words = [], []

    def ground(self, y_pt, h_pt, stops):
        self.im.paste(vgrad(self.im.width, round(h_pt * PX) + 1, stops), (0, round(y_pt * PX)))

    def put(self, pic, x, y, name=None, interactive=False, role="secondary"):
        self.im.paste(pic, (round(x * PX), round(y * PX)), pic)
        rect = [x, y, pic.width / PX, pic.height / PX]
        if name:
            self.controls.append({"name": name, "rect": [round(v, 2) for v in rect], "role": role,
                                  "interactive": interactive, "persistent": False})
        return rect

    def word(self, name, rect, words, pt, ink, outline=None, band=(0.3, 0.7)):
        """Words centred on rect, measured against the face under them."""
        x, y, w, h = rect
        face = np.asarray(self.im, dtype=float)[round((y + h * band[0]) * PX):round((y + h * band[1]) * PX),
                                                round((x + w * 0.15) * PX):round((x + w * 0.85) * PX)]
        under = tuple(np.median(face.reshape(-1, 3), axis=0))
        text(self.im, (x + w / 2, y + h / 2), words, pt, ink, outline)
        cr = wcag(ink, outline if outline else under)
        self.words.append({"check": "label-contrast", "control": name, "ratio": round(cr, 2),
                           "against": "outline" if outline else "face",
                           "result": "PASS" if cr >= 4.5 else "FAIL"})


def white(hc):
    return rgb("#FFFFFF") if hc else rgb("text_on_night")


def controls_still(hc, atlas):
    b = Board(hc)
    g = pk.grounds(hc)
    band = FRAME[1] / len(g)
    ink = white(hc)
    for i, gname in enumerate(g):
        y0 = i * band
        b.ground(y0, band, g[gname])
        # Discs, each state; the lock sits on the locked one.
        for j, st in enumerate(pk.STATES):
            x = 16 + j * 60
            r = b.put(atlas.draw("disc__box__" + st, 48), x, y0 + 12, "disc %s @ %s" % (st, gname), True)
            if st == "locked":
                lock = atlas.draw("locked__lock__normal", 18)
                b.put(lock, r[0] + (r[2] - 18) / 2, r[1] + (48 - 21.6) / 2)
        lv = b.put(atlas.draw("disc__level_disc__normal", 48), 256, y0 + 12)
        text(b.im, (lv[0] + 24, lv[1] + 23), "7", 20, ink, None if hc else rgb("ink_line"))
        # The badge at its own size: a 22-point face on its foot.
        badge = atlas.draw("badge__box__normal", 24, 26)
        br = b.put(badge, 16 + 48 - 16, y0 + 4)
        b.word("badge 3 @ %s" % gname, [br[0], br[1], br[2], br[3] - 4], "3", 12,
               rgb("#FFFFFF") if hc else rgb("on_alarm"), band=(0.25, 0.7))
        b.put(atlas.draw("badge__dot__normal", 14), 256 + 40, y0 + 10)
        b.put(atlas.draw("spinner__ring__normal", 24), 330, y0 + 24)
        # The pill, normal and pressed, with its words; it sits in the top
        # bar, so never on parchment.
        for j, st in enumerate(["normal", "pressed"] if gname != "parchment" else []):
            r = b.put(atlas.draw("pill__box__" + st, 132, 36), 16 + j * 148, y0 + 78,
                      "pill %s @ %s" % (st, gname), True)
            b.word("pill %s @ %s" % (st, gname), [r[0], r[1] + (3 if st == "pressed" else 0), r[2], r[3] - 4],
                   "1,250", 14, rgb("#000000") if hc else rgb("ink_deep"))
        # Tags with their words.
        for j, (shape, words) in enumerate([("box", "NEW"), ("tag_violet", "RARE"), ("tag_warn", "LOW")]):
            r = b.put(atlas.draw("tag__%s__normal" % shape, 76, 24), 16 + j * 86, y0 + 128)
            b.word("tag %s @ %s" % (shape, gname), [r[0] + (14 if shape == "tag_warn" else 0), r[1],
                                                    r[2] - (14 if shape == "tag_warn" else 0), r[3] - 2],
                   words, 11, (rgb("#000000") if hc else rgb("text_on_gold")) if shape == "tag_warn" else ink,
                   band=(0.25, 0.65))
        # Bars: a track, a tinted fill, the alarm fill, a target tick.
        for j, (shape, col) in enumerate([("box", "life"), ("box", "time"), ("alarm", None)]):
            x, y = 16 + j * 122, y0 + 170
            b.put(atlas.draw("bar_track__box__normal", 110, 12), x, y)
            fill = atlas.draw("bar_fill__%s__normal" % shape, 70, 8)
            if shape == "box":
                fill = tint(fill, col)
            b.put(fill, x + 2, y + 2)
            b.put(atlas.draw("bar_track__tick__normal", 3), x + 88, y)
    return b


def surfaces_still(hc, atlas):
    b = Board(hc)
    g = pk.grounds(hc)
    b.ground(0, FRAME[1], g["backdrop"])
    ink = white(hc)
    cards = [("normal", False), ("locked", False), ("normal", True)]
    for j, (st, sel) in enumerate(cards):
        x, y = 16 + j * 124, 16
        r = b.put(atlas.draw("panel_dark__box__" + st, 112, 140), x, y)
        if st == "locked":
            b.put(atlas.draw("locked__lock__normal", 24), x + 44, y + 52)
        if sel:
            b.put(atlas.draw("selected__rim__normal", 112, 140), x, y)
        if st != "locked":
            b.word("card words %s%s" % (st, " selected" if sel else ""), [x, y + 96, 112, 30],
                   "Card", 14, ink)
    # Glass panel over a lighter strip of world, and the well with bars.
    b.ground(176, 200, g["glass"] if hc else [(0, (90, 120, 200)), (1, (40, 50, 120))])
    r = b.put(atlas.draw("panel_glass__box__normal", 358, 170), 16, 190)
    b.word("glass words", [16, 196, 358, 40], "Glass panel", 16, ink)
    w = b.put(atlas.draw("well__box__normal", 326, 90), 32, 250)
    for j, col in enumerate(["energy", "spirit"]):
        y = 266 + j * 30
        b.put(atlas.draw("bar_track__box__normal", 294, 12), 48, y)
        b.put(tint(atlas.draw("bar_fill__box__normal", 180, 8), col), 50, y + 2)
    # The school disc, one per school, each state; the frame over the tint.
    b.ground(392, FRAME[1] - 392, g["dark card"])
    for row, st in enumerate(["normal", "pressed", "disabled"]):
        for j, school in enumerate(SCHOOLS):
            x, y = 16 + j * 60, 404 + row * 66
            under = tint(atlas.draw("disc_school__box__" + st, 48), school)
            b.put(under, x, y, "disc_school %s %s" % (school, st), True)
            b.put(atlas.draw("disc_school__frame__" + st, 48), x, y)
    # Every school disc also on the backdrop (normal), and a pill on glass.
    for j, school in enumerate(SCHOOLS):
        x, y = 16 + j * 60, 620
        b.put(tint(atlas.draw("disc_school__box__normal", 48), school), x, y,
              "disc_school %s on dark card 2" % school, True)
        b.put(atlas.draw("disc_school__frame__normal", 48), x, y)
    return b


def tiles(atlas, mode):
    paths = []
    for src, names in ((atlas, sorted(n for n in atlas.man["pieces"] if n.split("__")[0] in SKINS
                                      and n.rsplit("__", 1)[0] not in LATER)),):
        for n in names:
            p = src.man["pieces"][n]
            w_pt = p["w"] / 6
            pic = src.draw(n, max(w_pt, 48) if p.get("slice") else w_pt, max(p["h"] / 6, 36) if p.get("slice") else None)
            if p.get("tint"):
                pic = tint(pic, "matter")
            path = os.path.join(OUT, "tiles", mode, n + ".png")
            os.makedirs(os.path.dirname(path), exist_ok=True)
            pic.save(path)
            paths.append(path)
    return paths


def main(argv):
    os.makedirs(OUT, exist_ok=True)
    results, fails = [], 0
    for hc in (False, True):
        mode = "hc" if hc else "normal"
        atlas = Atlas(hc)
        for still, board in (("controls", controls_still(hc, atlas)), ("surfaces", surfaces_still(hc, atlas))):
            png = "%s_%s.png" % (still, mode)
            board.im.save(os.path.join(OUT, png))
            data = {"image": png, "frame_pt": list(FRAME), "text_scale": 1.0, "controls": board.controls}
            with open(os.path.join(OUT, "%s_%s.json" % (still, mode)), "w") as f:
                json.dump(data, f, indent=1)
                f.write("\n")
            rows = checks.value_steps(checks.Shot(data, base=OUT)) + board.words
            for r in rows:
                r["mode"], r["still"] = mode, still
                fails += r["result"] == "FAIL"
            results += rows
        subprocess.run([sys.executable, os.path.join(ROOT, "tools/ui_gate/sheet.py"), "contact",
                        os.path.join(OUT, "contact_1b_%s.png" % mode), *tiles(atlas, mode),
                        "--sizes", "60,120"], check=True)
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
