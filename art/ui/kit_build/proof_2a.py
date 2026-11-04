#!/usr/bin/env python3
"""Proofs the kit's batch 2a (kit_2a.py) at phone size, in both modes.

    python3 art/ui/kit_build/proof_2a.py [--check] [--all]

Three stills a mode, drawn from the baked atlas as the phone shows it:
`panels` puts the header with its Marcellus title and name plate, the
parchment panel (normal, locked with the lock, done, selected), the four
rank frames over the dark card and over parchment, normal and locked, and
the ribbons (the violet chapter ribbon and the neutral ribbon tinted for
each school, its frame drawn over the tint);
`popup` puts the popup over the scrim with its ribbon title, its body words
and a primary button;
`sheets` puts the dark sheet and the parchment sheet, each with its handle.

The gate's value-steps check runs on every interactive control (the button
and the parchment panels, which open their quest), and each word is
measured against the face or outline under it: 4.5:1 and APCA Lc 60.
The contact sheets hold every batch 2a piece through the gate's tool.
"""
import json
import os
import subprocess
import sys

import numpy as np
from PIL import Image, ImageDraw, ImageFont

import proof_kit as pk
from proof_kit import PX, ROOT, rgb, vgrad, wcag
from proof_1b import tint, Board as Board1b
from proof_num import apca

sys.path.insert(0, os.path.join(ROOT, "tools/ui_gate"))
import checks  # noqa: E402

OUT = os.path.join(os.path.dirname(os.path.abspath(__file__)), "proof_2a")
FRAME = (390, 844)
SCHOOLS = ["motion", "matter", "time", "energy", "life", "spirit"]
SKINS = ["panel_parchment", "sheet", "popup", "frame_oak", "frame_silver", "frame_gold",
         "frame_prismatic", "header", "ribbon"]
RANKS = ["oak", "silver", "gold", "prismatic"]
MARCELLUS = os.path.join(ROOT, "client/ui/fonts/marcellus/Marcellus-Regular.ttf")
HARD_DROP = 2  # points: a Marcellus title's hard drop (T2)


def face_font(pt, display):
    if display:
        return ImageFont.truetype(MARCELLUS, round(pt * PX))
    return pk.font(pt)


class Board(Board1b):
    def __init__(self, hc):
        super().__init__(hc)
        self.im = Image.new("RGB", (round(FRAME[0] * PX), round(FRAME[1] * PX)))

    def overlay(self, rgba):
        base = self.im.convert("RGBA")
        base.alpha_composite(rgba)
        self.im = base.convert("RGB")

    def say(self, name, rect, words, pt, ink, outline=None, drop=False, display=False, band=(0.3, 0.7)):
        """Words centred on rect. T0 is plain ink on the face; T1 adds an ink
        outline of 1.5 points; T2 adds a hard drop under it. The ratio is
        taken against the outline when there is one, else the face under."""
        x, y, w, h = rect
        a = np.asarray(self.im, dtype=float)
        face = a[round((y + h * band[0]) * PX):round((y + h * band[1]) * PX),
                 round((x + w * 0.15) * PX):round((x + w * 0.85) * PX)]
        under = tuple(np.median(face.reshape(-1, 3), axis=0))
        d = ImageDraw.Draw(self.im)
        f = face_font(pt, display)
        cx, cy = round((x + w / 2) * PX), round((y + h / 2) * PX)
        sw = round(1.5 * PX) if outline else 0
        if drop:
            d.text((cx, cy + round(HARD_DROP * PX)), words, fill=outline or rgb("ink_deep"), font=f,
                   anchor="mm", stroke_width=sw, stroke_fill=outline or rgb("ink_deep"))
        d.text((cx, cy), words, fill=ink, font=f, anchor="mm", stroke_width=sw, stroke_fill=outline)
        against = outline if outline else under
        cr, lc = wcag(ink, against), apca(ink, against)
        ok = cr >= 4.5 and lc >= 60
        self.words.append({"check": "label-contrast", "control": name, "ratio": round(cr, 2),
                           "apca_lc": round(lc, 1), "against": "outline" if outline else "face",
                           "treatment": "T2" if drop and outline else "T1" if outline else "T0",
                           "font": "Marcellus" if display else "Manrope",
                           "result": "PASS" if ok else "FAIL"})


def inks(hc):
    """(white words, the ink outline, words on parchment) in this mode."""
    if hc:
        return rgb("#FFFFFF"), rgb("#000000"), rgb("#000000")
    return rgb("text_on_night"), rgb("ink_deep"), rgb("parchment_ink")


def school_hex(name, hc):
    hcs = pk.HC
    return hcs.get(name, pk.C[name]) if hc else pk.C[name]


def panels_still(hc, atlas):
    b = Board(hc)
    g = pk.grounds(hc)
    white, outline, pink = inks(hc)
    b.ground(0, FRAME[1], g["backdrop"])
    # The header across the top, its title in Marcellus (T2), the name plate.
    hr = b.put(atlas.draw("header__box__normal", 390, 64), 0, 0)
    b.say("header title", [16, 6, 230, 50], "Chapter 3", 28, white, outline, drop=True, display=True)
    np_r = b.put(atlas.draw("header__name_plate__normal", 112, 36), 262, 12)
    b.say("name plate", [np_r[0], np_r[1], np_r[2], np_r[3] - 4], "Lv 12", 14, white, outline)
    # The parchment ground strip with the parchment panels.
    b.ground(76, 150, g["dark card"])
    for j, (st, extra) in enumerate([("normal", None), ("locked", "lock"), ("normal", "done"),
                                     ("normal", "selected")]):
        x, y = 12 + j * 94, 88
        piece = "panel_parchment__parchment_done__normal" if extra == "done" else "panel_parchment__box__" + st
        r = b.put(atlas.draw(piece, 86, 120), x, y, "parchment %s" % (extra or st), True)
        if extra == "lock":
            b.put(atlas.draw("locked__lock__normal", 24), x + 31, y + 44)
        if extra == "selected":
            b.put(atlas.draw("selected__rim__normal", 86, 120), x, y)
        if extra != "lock":
            b.say("parchment words %s" % (extra or st), [x, y + 70, 86, 30], "Quest", 16, pink,
                  display=True, drop=False)
    # Rank frames over the dark card, then over parchment; normal and locked.
    for row, gname in enumerate(["dark card", "parchment"]):
        y0 = 238 + row * 186
        b.ground(y0, 176, g[gname])
        for i, st in enumerate(["normal", "locked"]):
            for j, rank in enumerate(RANKS):
                x, y = 12 + j * 94, y0 + 8 + i * 84
                # A portrait-shaped face under the frame, as the card shows it.
                face = atlas.draw("panel_dark__box__normal", 70, 70)
                b.put(face, x + 8, y + 2)
                b.put(atlas.draw("frame_%s__box__%s" % (rank, st), 78, 78), x + 4, y - 2)
                if st == "locked":
                    b.put(atlas.draw("locked__lock__normal", 22), x + 32, y + 26)
    # The ribbons: the chapter ribbon, then the neutral one for each school.
    b.ground(610, FRAME[1] - 610, g["backdrop"])
    r = b.put(atlas.draw("ribbon__chapter__normal", 300, 46), 45, 620)
    b.say("chapter ribbon", [r[0] + 20, r[1] + 1, r[2] - 40, 36], "Chapter 3", 20, white, outline,
          drop=True, display=True)
    for j, school in enumerate(SCHOOLS):
        x, y = 12 + (j % 2) * 186, 676 + (j // 2) * 54
        under = tint(atlas.draw("ribbon__box__normal", 180, 44), school_hex(school, hc))
        r = b.put(under, x, y)
        b.put(atlas.draw("ribbon__frame__normal", 180, 44), x, y)
        b.say("ribbon %s" % school, [r[0] + 20, r[1] + 1, r[2] - 40, 34], school.capitalize(), 20,
              white, outline, drop=True, display=True)
    return b


def popup_still(hc, atlas):
    b = Board(hc)
    g = pk.grounds(hc)
    white, outline, _ = inks(hc)
    # A busy screen under the scrim: the backdrop and dark cards.
    b.ground(0, FRAME[1], g["backdrop"])
    for j in range(6):
        b.put(atlas.draw("panel_dark__box__normal", 170, 120), 16 + (j % 2) * 188, 40 + (j // 2) * 140)
    sc = pk.T["gradient"]["scrim"]["value"]
    h = round(FRAME[1] * PX)
    t = np.linspace(0, 1, h)[:, None]
    c0, c1 = sc[0][1], sc[-1][1]
    def rgba(hx):
        hx = hx.lstrip("#")
        return np.array([int(hx[i:i + 2], 16) for i in (0, 2, 4, 6)], dtype=float)
    col = rgba(c0) * (1 - t) + rgba(c1) * t
    scrim = np.broadcast_to(col[:, None, :], (h, round(FRAME[0] * PX), 4)).astype(np.uint8)
    if hc:
        scrim = np.zeros_like(scrim)
        scrim[..., 3] = 235
    b.overlay(Image.fromarray(np.ascontiguousarray(scrim), "RGBA"))
    # The popup: 340 x 380 points with its margins; the face inside them.
    PW, PH = 342, 400
    px, py = (FRAME[0] - PW) / 2, 210
    b.put(atlas.draw("popup__box__normal", PW, PH), px, py)
    fx, fy, fw, fh = px + 8, py + 4, PW - 16, PH - 21
    # The ribbon title across the top edge.
    r = b.put(tint(atlas.draw("ribbon__box__normal", 260, 46), school_hex("matter", hc)), (FRAME[0] - 260) / 2, fy - 22)
    b.put(atlas.draw("ribbon__frame__normal", 260, 46), r[0], r[1])
    b.say("popup title", [r[0] + 20, r[1] + 1, r[2] - 40, 36], "Reward", 22, white, outline, drop=True,
          display=True)
    for i, line in enumerate(["You found the old key.", "It opens the tower door."]):
        b.say("popup body %d" % i, [fx + 20, fy + 70 + i * 28, fw - 40, 24], line, 16, white)
    # The rank frame of the reward in the middle.
    b.put(atlas.draw("panel_dark__box__normal", 96, 96), FRAME[0] / 2 - 48, fy + 140)
    b.put(atlas.draw("frame_gold__box__normal", 106, 106), FRAME[0] / 2 - 53, fy + 136)
    br = b.put(atlas.draw("button_primary__box__normal", 220, 56), (FRAME[0] - 220) / 2, fy + fh - 80,
               "popup button", True, role="primary")
    ink = rgb("#000000") if hc else rgb("text_on_gold")
    b.say("popup button words", [br[0], br[1], br[2], br[3] - 6], "CLAIM", 16, ink)
    return b


def sheets_still(hc, atlas):
    b = Board(hc)
    g = pk.grounds(hc)
    white, outline, pink = inks(hc)
    b.ground(0, FRAME[1], g["backdrop"])
    # The parchment sheet on the upper half (as a half-height sheet would
    # stand), the dark sheet from the foot.
    for kind, y, h in (("panel_parchment__sheet_parchment__normal", 40, 360), ("sheet__box__normal", 440, 404)):
        r = b.put(atlas.draw(kind, 390, h), 0, y)
        handle = "sheet__handle_parchment__normal" if "parchment" in kind else "sheet__handle__normal"
        b.put(atlas.draw(handle, 42), (FRAME[0] - 42) / 2, y + 12)
        par = "parchment" in kind
        b.say("sheet title %s" % ("parchment" if par else "dark"), [16, y + 32, 358, 40],
              "Quest log" if par else "Inventory", 28, pink if par else white,
              None if par else outline, drop=not par, display=True)
        for i in range(3):
            b.say("sheet line %d %s" % (i, "parchment" if par else "dark"), [32, y + 90 + i * 30, 326, 24],
                  ["Find the tower key", "Light the third lamp", "Speak with the keeper"][i], 16,
                  pink if par else white)
    return b


def tiles(atlas, mode):
    paths = []
    for n in sorted(n for n in atlas.man["pieces"] if n.split("__")[0] in SKINS):
        p = atlas.man["pieces"][n]
        w_pt = p["w"] / 6
        pic = atlas.draw(n, max(w_pt, 48) if p.get("slice") else w_pt,
                         max(p["h"] / 6, 36) if p.get("slice") else None)
        if p.get("tint"):
            pic = tint(pic, pk.C["matter"])
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
        atlas = pk.Atlas(hc)
        for still, fn in (("panels", panels_still), ("popup", popup_still), ("sheets", sheets_still)):
            board = fn(hc, atlas)
            png = "%s_%s.png" % (still, mode)
            board.im.save(os.path.join(OUT, png))
            data = {"image": png, "frame_pt": list(FRAME), "text_scale": 1.0, "controls": board.controls}
            with open(os.path.join(OUT, "%s_%s.json" % (still, mode)), "w") as f:
                json.dump(data, f, indent=1)
                f.write("\n")
            rows = (checks.value_steps(checks.Shot(data, base=OUT)) if board.controls else []) + board.words
            for r in rows:
                r["mode"], r["still"] = mode, still
                fails += r["result"] == "FAIL"
            results += rows
        subprocess.run([sys.executable, os.path.join(ROOT, "tools/ui_gate/sheet.py"), "contact",
                        os.path.join(OUT, "contact_2a_%s.png" % mode), *tiles(atlas, mode),
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
