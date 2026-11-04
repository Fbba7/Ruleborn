#!/usr/bin/env python3
"""Proof stills of the baked kit faces (batch 1a) on the grounds they sit on,
at the phone's density, normal and high contrast, every state; measured with
the gate's value-steps check (tools/ui_gate/checks.py) and a label contrast
check; and the contact sheets (tools/ui_gate/sheet.py contact).

    python3 art/ui/kit_build/proof_kit.py            # writes art/ui/kit_build/proof/
    python3 art/ui/kit_build/proof_kit.py --check    # exit 1 if a face on its ground fails

The stills live outside art/ui/kit/ so they never change the bake's hash.
Words are drawn here only to measure them; in the game they are live (K1).
"""
import json
import os
import subprocess
import sys

import numpy as np
from PIL import Image, ImageDraw, ImageFont

ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", "..", ".."))
sys.path.insert(0, os.path.join(ROOT, "tools/ui_gate"))
import checks  # noqa: E402
import colour  # noqa: E402

OUT = os.path.join(os.path.dirname(os.path.abspath(__file__)), "proof")
ART = os.path.join(ROOT, "client/ui/art")
T = json.load(open(os.path.join(ROOT, "client/ui/tokens.json")))
C = {k: v["value"] for k, v in T["color"].items() if isinstance(v, dict) and "value" in v}
HC = {k: v["value"] for k, v in T["color_high_contrast"].items() if isinstance(v, dict) and "value" in v}
G = T["gradient"]
FRAME = (390, 844)
PX = 1080 / 390  # the phone's density, pixels a point
STATES = ["normal", "pressed", "disabled", "locked"]


def rgb(h):
    h = C.get(h, h).lstrip("#")
    return tuple(int(h[i:i + 2], 16) for i in (0, 2, 4))


def stops(name):
    return [(o, rgb(c)) for o, c in G[name]["value"]]


def vgrad(w, h, st):
    t = np.linspace(0, 1, h)[:, None]
    out = np.zeros((h, w, 3))
    for (o0, c0), (o1, c1) in zip(st, st[1:]):
        m = (t >= o0) & (t <= o1)
        k = np.clip((t - o0) / max(o1 - o0, 1e-6), 0, 1)
        col = np.array(c0) * (1 - k) + np.array(c1) * k
        out = np.where(m[..., None], np.broadcast_to(col[:, None, :], (h, w, 3)), out)
    return Image.fromarray(out.astype(np.uint8), "RGB")


# The grounds the batch's buttons sit on (kit-spec.md K01, section 4).
def grounds(hc):
    if hc:
        return {
            "backdrop": [(0, rgb(HC["night_top"])), (1, rgb(HC["night_top"]))],
            "dark card": [(0, rgb(HC["card_top"])), (1, rgb(HC["card_bottom"]))],
            "glass": [(0, rgb(HC["glass"])), (1, rgb(HC["glass"]))],
            "parchment": [(0, rgb(HC["paper"])), (1, rgb(HC["paper"]))],
        }
    sky = vgrad(1, 64, stops("phone_sky")).resize((1, 64))
    glass = np.array(rgb(C.get("glass", "#140A16")))
    glass_st = []
    for i, o in enumerate(np.linspace(0, 1, 5)):
        s = np.array(sky.getpixel((0, int(o * 63))))
        glass_st.append((o, tuple(int(v) for v in glass * 0.78 + s * 0.22)))
    return {
        "backdrop": stops("night"),
        "dark card": stops("card"),
        "glass": glass_st,
        "parchment": stops("parchment"),
    }


# Which faces sit on which grounds (kit-spec.md K01; report.md's board).
USES = {
    "button_primary__box": ["backdrop", "dark card", "glass"],
    "button_primary__gold_round": ["backdrop", "dark card", "glass"],
    "button_secondary__box": ["parchment"],
    "button_tertiary__box": ["backdrop", "dark card", "glass"],
    "button_tertiary__parchment": ["parchment"],
    "button_danger__box": ["backdrop", "dark card", "glass", "parchment"],
    "success__box": ["backdrop", "dark card", "glass", "parchment"],
}
# The words each face carries (the material's `text`), normal and high contrast.
WORDS = {
    "button_primary": ("text_on_gold", None, "#000000", None),
    "button_secondary": ("text_on_leather", None, "#FFFFFF", None),
    "button_tertiary__box": ("text_on_night", None, "#FFFFFF", None),
    "button_tertiary__parchment": ("parchment_ink", None, "#000000", None),
    "button_danger": ("on_alarm", "ink_line", "#FFFFFF", None),
    "success": ("text_on_green", "ink_line", "#000000", None),
}
LABEL = {"button_primary": "PLAY", "button_secondary": "BACK", "button_tertiary": "SKIP",
         "button_danger": "GET OUT", "success": "CLAIM"}


def words_for(base, state, hc):
    skin = base.split("__")[0]
    w = WORDS.get(base) or WORDS[skin]
    if hc:
        if state == "disabled":
            return rgb("#000000"), None
        if state == "locked":
            return rgb("#FFFFFF"), None
        return rgb(w[2]), None
    if state == "locked":
        return rgb("text_on_night"), rgb("ink_line")
    return rgb(w[0]), (rgb(w[1]) if w[1] else None)


class Atlas:
    def __init__(self, hc):
        self.man = json.load(open(os.path.join(ART, "kit.json")))
        self.im = Image.open(os.path.join(ART, "kit_hc.webp" if hc else "kit.webp")).convert("RGBA")
        self.k = PX / self.man["px_per_point"]

    def piece(self, name):
        p = self.man["pieces"][name]
        return p, self.im.crop((p["x"], p["y"], p["x"] + p["w"], p["y"] + p["h"]))

    def draw(self, name, w_pt, h_pt=None):
        """The piece at w_pt x h_pt points on the phone: 9-sliced, its corners
        at the phone's density (the atlas holds 6 px a point)."""
        p, im = self.piece(name)
        k = self.k
        if not p.get("slice"):
            s = round(w_pt * PX) / im.width
            return im.resize((round(im.width * s), round(im.height * s)), Image.LANCZOS)
        sl = p["slice"]
        W, H = round(w_pt * PX), round((h_pt or p["h"] / 6) * PX)
        xs = [0, sl["l"], p["w"] - sl["r"], p["w"]]
        ys = [0, sl["t"], p["h"] - sl["b"], p["h"]]
        dx = [0, round(sl["l"] * k), W - round(sl["r"] * k), W]
        dy = [0, round(sl["t"] * k), H - round(sl["b"] * k), H]
        out = Image.new("RGBA", (W, H))
        for i in range(3):
            for j in range(3):
                src = im.crop((xs[i], ys[j], xs[i + 1], ys[j + 1]))
                size = (dx[i + 1] - dx[i], dy[j + 1] - dy[j])
                if size[0] > 0 and size[1] > 0 and src.width > 0 and src.height > 0:
                    out.paste(src.resize(size, Image.LANCZOS), (dx[i], dy[j]))
        return out


def font(pt):
    f = ImageFont.truetype(os.path.join(ROOT, "client/ui/fonts/manrope/Manrope-Variable.ttf"), round(pt * PX))
    try:
        f.set_variation_by_axes([800])
    except Exception:
        pass
    return f


def put_label(im, rect_px, text, ink, outline, face_h_px, sunk_px):
    d = ImageDraw.Draw(im)
    f = font(16)
    x, y, w, h = rect_px
    cx, cy = x + w / 2, y + 1 * PX + sunk_px + face_h_px / 2
    sw = round(2 * PX) if outline else 0
    d.text((cx, cy), text, fill=ink, font=f, anchor="mm", stroke_width=sw, stroke_fill=outline)
    return f


def shot(state, hc, atlas):
    """One still: a band per ground, the faces that sit on it."""
    g = grounds(hc)
    im = Image.new("RGB", (1080, round(FRAME[1] * PX)))
    bands = list(g)
    band_h = FRAME[1] / len(bands)
    controls, labels = [], []
    for b, gname in enumerate(bands):
        y0 = b * band_h
        im.paste(vgrad(1080, round(band_h * PX) + 1, g[gname]), (0, round(y0 * PX)))
        faces = [n for n, use in USES.items() if gname in use]
        cols = 2
        for i, base in enumerate(faces):
            name = "%s__%s" % (base, state)
            round_ = base.endswith("gold_round")
            w_pt, h_pt = (60, None) if round_ else (150, 54 if "tertiary" not in base else 53)
            pic = atlas.draw(name, w_pt, h_pt)
            col, row = i % cols, i // cols
            x = 30 + col * 180
            y = y0 + 16 + row * 72
            px, py = round(x * PX), round(y * PX)
            im.paste(pic, (px, py), pic)
            rect = [x, y, pic.width / PX, pic.height / PX]
            controls.append({"name": "%s @ %s" % (name, gname), "rect": [round(v, 2) for v in rect],
                             "role": "primary" if "primary" in base else "secondary", "interactive": True,
                             "persistent": False})
            if not round_:
                ink, outline = words_for(base, state, hc)
                skin = base.split("__")[0]
                face_h = 42 * PX * (150 * PX / round(150 * PX))
                sunk = 3 * PX if state == "pressed" else 0
                labels.append((name, gname, (px, py, pic.width, pic.height), ink, outline, sunk))
                put_label(im, (px, py, pic.width, pic.height), LABEL[skin], ink, outline, 42 * PX, sunk)
    return im, controls, labels


def wcag(a, b):
    def lum(c):
        lin = colour.to_linear(np.array(c, dtype=float).reshape(1, 3))[0]
        return 0.2126 * lin[0] + 0.7152 * lin[1] + 0.0722 * lin[2]
    la, lb = sorted([lum(a), lum(b)], reverse=True)
    return (la + 0.05) / (lb + 0.05)


def label_contrast(im, atlas, labels, state, hc):
    """Each label's colour against the face pixels under it (the median of
    the face's middle band) or against its ink outline, as §21.8 lets that
    count: 4.5:1 or more."""
    rows = []
    for name, gname, (x, y, w, h), ink, outline, sunk in labels:
        pic = atlas.draw(name, w / PX, h / PX)
        a = np.asarray(pic.convert("RGB"), dtype=float)[round(h * 0.3):round(h * 0.6), round(w * 0.1):round(w * 0.9)]
        face = tuple(np.median(a.reshape(-1, 3), axis=0))
        against = outline if outline else face
        cr = wcag(ink, against)
        rows.append({"check": "label-contrast", "control": "%s @ %s" % (name, gname),
                     "ratio": round(cr, 2) if cr else None,
                     "against": "outline" if outline else "face",
                     "result": "PASS" if cr and cr >= 4.5 else "FAIL"})
    return rows


def main(argv):
    os.makedirs(OUT, exist_ok=True)
    results, fails = [], 0
    for hc in (False, True):
        atlas = Atlas(hc)
        mode = "hc" if hc else "normal"
        for state in STATES:
            im, controls, labels = shot(state, hc, atlas)
            png = "faces_%s_%s.png" % (mode, state)
            im.save(os.path.join(OUT, png))
            data = {"image": png, "frame_pt": list(FRAME), "text_scale": 1.0, "controls": controls}
            with open(os.path.join(OUT, "faces_%s_%s.json" % (mode, state)), "w") as f:
                json.dump(data, f, indent=1)
                f.write("\n")
            rows = checks.value_steps(checks.Shot(data, base=OUT))
            rows += label_contrast(im, atlas, labels, state, hc)
            for r in rows:
                r["mode"], r["state"] = mode, state
                fails += r["result"] == "FAIL"
            results += rows
        # Contact sheet: each piece at phone size, as the gate's tool draws it.
        # Batch 1a's pieces only; proof_1b.py draws batch 1b's.
        names = sorted(n for n in atlas.man["pieces"] if n.rsplit("__", 1)[0] in USES)
        tiles = []
        for n in names:
            p = atlas.man["pieces"][n]
            pic = atlas.draw(n, 60 if "gold_round" in n else 120, None if "gold_round" in n else 52)
            path = os.path.join(OUT, "tiles", mode, n + ".png")
            os.makedirs(os.path.dirname(path), exist_ok=True)
            pic.save(path)
            tiles.append(path)
        subprocess.run([sys.executable, os.path.join(ROOT, "tools/ui_gate/sheet.py"), "contact",
                        os.path.join(OUT, "contact_%s.png" % mode), *tiles, "--sizes", "60,120"], check=True)
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
