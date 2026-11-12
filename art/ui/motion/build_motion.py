#!/usr/bin/env python3
"""Writes the motion family's sprite sources (report.md step 8, D11 (b)):
the burst, sparkle, shine and coin sprites the result screen's reward
sequence and the primary buttons' idle shine draw, each with its
high-contrast twin, from client/ui/tokens.json.

    python3 art/ui/motion/build_motion.py
    node tools/ui_bake/bake.js motion

Every colour is a token of the board's materials (gold, cream, paper, ink);
the sources are written, never edited by hand: change this file and rerun.
Sizes are in points (6 pixels a point in the atlas), all whole points.

The sprites are drawn white-hot at their centre and fade to nothing at their
edge, so code can scale and fade them along the curves in curves.json without
a hard rim showing. Their high-contrast twins are opaque: paper or gold
fills on a black ink edge, no glow (report.md section 10.2). No sprite is a
flash by itself: how often one may light is curves.json's `flash_hz_most`.
"""
import json
import math
import os

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.abspath(os.path.join(HERE, "..", "..", ".."))
T = json.load(open(os.path.join(ROOT, "client/ui/tokens.json")))
C = {k: v["value"] for k, v in T["color"].items() if isinstance(v, dict) and "value" in v}
HC = {k: v["value"] for k, v in T["color_high_contrast"].items() if isinstance(v, dict) and "value" in v}

GOLD_TOP, GOLD, GOLD_BOTTOM = C["gold_top"], C["gold"], C["gold_bottom"]
GOLD_RIM, GOLD_DROP, CREAM = C["gold_rim"], C["gold_drop"], C["cream"]
WHITE, INK = "#FFFFFF", HC["ink"]   # high contrast's ink is #000000
LINE_HC = T["size"]["line_hc"]["value"] if isinstance(T["size"]["line_hc"], dict) else T["size"]["line_hc"]

HEAD = ('<svg xmlns="http://www.w3.org/2000/svg" width="{w}" height="{h}">\n'
        '  <!-- Written by art/ui/motion/build_motion.py from client/ui/tokens.json; do not edit. -->\n')


def f(x):
    return ("%.3f" % x).rstrip("0").rstrip(".")


def write(skin, shape, w, h, defs, normal, hc):
    d = os.path.join(HERE, skin)
    os.makedirs(d, exist_ok=True)
    s = HEAD.format(w=w, h=h)
    if defs:
        s += "  <defs>\n" + "".join("    %s\n" % x for x in defs) + "  </defs>\n"
    s += '  <g data-state="normal">\n' + "".join("    %s\n" % x for x in normal) + "  </g>\n"
    s += '  <g data-state="normal" data-mode="hc">\n' + "".join("    %s\n" % x for x in hc) + "  </g>\n"
    s += "</svg>\n"
    open(os.path.join(d, shape + ".svg"), "w").write(s)


def star(cx, cy, points, r_out, r_in, rot=-90.0):
    pts = []
    for i in range(points * 2):
        r = r_out if i % 2 == 0 else r_in
        a = math.radians(rot + 180.0 * i / points)
        pts.append("%s,%s" % (f(cx + r * math.cos(a)), f(cy + r * math.sin(a))))
    return " ".join(pts)


def rays(cx, cy, n, r0, r1, half_w, rot=-90.0):
    """`n` tapering rays from radius r0 to r1, each `half_w` points wide each
    side of its foot."""
    out = []
    for i in range(n):
        a = math.radians(rot + 360.0 * i / n)
        ux, uy = math.cos(a), math.sin(a)
        px, py = -uy * half_w, ux * half_w
        fx, fy = cx + r0 * ux, cy + r0 * uy
        out.append("M%s %s L%s %s L%s %s Z" % (
            f(fx + px), f(fy + py), f(cx + r1 * ux), f(cy + r1 * uy), f(fx - px), f(fy - py)))
    return " ".join(out)


def burst():
    # burst/rays: the reveal's light, 80 pt; long and short rays alternate.
    # Soft-edged, so code may draw it up to twice its size.
    W = 80; c = W / 2
    long_ = rays(c, c, 8, 5, 39, 4.5)
    short = rays(c, c, 8, 5, 28, 3.5, rot=-90 + 22.5)
    defs = [
        '<radialGradient id="r1" cx="0.5" cy="0.5" r="0.5"><stop offset="0" stop-color="%s"/>'
        '<stop offset="0.25" stop-color="%s"/><stop offset="0.7" stop-color="%s" stop-opacity="0.55"/>'
        '<stop offset="1" stop-color="%s" stop-opacity="0"/></radialGradient>' % (WHITE, CREAM, GOLD_TOP, GOLD),
        '<radialGradient id="r2" cx="0.5" cy="0.5" r="0.5"><stop offset="0" stop-color="%s" stop-opacity="0.9"/>'
        '<stop offset="0.35" stop-color="%s" stop-opacity="0.45"/><stop offset="1" stop-color="%s" stop-opacity="0"/>'
        '</radialGradient>' % (CREAM, GOLD_TOP, GOLD),
    ]
    normal = [
        '<circle cx="%s" cy="%s" r="25" fill="url(#r2)"/>' % (f(c), f(c)),
        '<path d="%s" fill="url(#r1)"/>' % long_,
        '<path d="%s" fill="url(#r1)" opacity="0.8"/>' % short,
        '<circle cx="%s" cy="%s" r="7.5" fill="%s"/>' % (f(c), f(c), WHITE),
    ]
    hc_long = rays(c, c, 8, 5, 37, 4.5)
    hc_short = rays(c, c, 8, 5, 27, 3.5, rot=-90 + 22.5)
    hc = [
        '<path d="%s" fill="%s" stroke="%s" stroke-width="%s" stroke-linejoin="round"/>' % (hc_short, GOLD, INK, f(LINE_HC)),
        '<path d="%s" fill="%s" stroke="%s" stroke-width="%s" stroke-linejoin="round"/>' % (hc_long, WHITE, INK, f(LINE_HC)),
        '<circle cx="%s" cy="%s" r="8.5" fill="%s" stroke="%s" stroke-width="%s"/>' % (f(c), f(c), WHITE, INK, f(LINE_HC)),
    ]
    write("burst", "rays", W, W, defs, normal, hc)

    # burst/ring: the shock ring that grows out of the burst, 80 pt.
    defs = ['<radialGradient id="r1" cx="0.5" cy="0.5" r="0.5">'
            '<stop offset="0.72" stop-color="%s" stop-opacity="0"/><stop offset="0.86" stop-color="%s"/>'
            '<stop offset="0.92" stop-color="%s" stop-opacity="0.7"/><stop offset="1" stop-color="%s" stop-opacity="0"/>'
            '</radialGradient>' % (CREAM, WHITE, GOLD_TOP, GOLD)]
    normal = ['<circle cx="%s" cy="%s" r="40" fill="url(#r1)"/>' % (f(c), f(c))]
    hc = ['<circle cx="%s" cy="%s" r="35" fill="none" stroke="%s" stroke-width="7"/>' % (f(c), f(c), INK),
          '<circle cx="%s" cy="%s" r="35" fill="none" stroke="%s" stroke-width="3"/>' % (f(c), f(c), WHITE)]
    write("burst", "ring", W, W, defs, normal, hc)


def sparkle():
    # sparkle/star: a four-point glint, 24 pt, with a soft halo.
    W = 24; c = W / 2
    defs = ['<radialGradient id="r1" cx="0.5" cy="0.5" r="0.5"><stop offset="0" stop-color="%s" stop-opacity="0.8"/>'
            '<stop offset="0.4" stop-color="%s" stop-opacity="0.3"/><stop offset="1" stop-color="%s" stop-opacity="0"/>'
            '</radialGradient>' % (CREAM, GOLD_TOP, GOLD)]
    normal = ['<circle cx="%s" cy="%s" r="9" fill="url(#r1)"/>' % (f(c), f(c)),
              '<polygon points="%s" fill="%s"/>' % (star(c, c, 4, 11.5, 2.2), CREAM),
              '<polygon points="%s" fill="%s"/>' % (star(c, c, 4, 8, 1.4), WHITE)]
    hc = ['<polygon points="%s" fill="%s" stroke="%s" stroke-width="%s" stroke-linejoin="round"/>'
          % (star(c, c, 4, 10, 2.6), WHITE, INK, f(LINE_HC))]
    write("sparkle", "star", W, W, defs, normal, hc)

    # sparkle/dot: the small mote that trails the coins and rides the burst, 8 pt.
    W = 8; c = W / 2
    defs = ['<radialGradient id="r1" cx="0.5" cy="0.5" r="0.5"><stop offset="0" stop-color="%s"/>'
            '<stop offset="0.45" stop-color="%s" stop-opacity="0.8"/><stop offset="1" stop-color="%s" stop-opacity="0"/>'
            '</radialGradient>' % (WHITE, GOLD_TOP, GOLD)]
    normal = ['<circle cx="%s" cy="%s" r="4" fill="url(#r1)"/>' % (f(c), f(c))]
    hc = ['<circle cx="%s" cy="%s" r="2.5" fill="%s" stroke="%s" stroke-width="1.5"/>' % (f(c), f(c), WHITE, INK)]
    write("sparkle", "dot", W, W, defs, normal, hc)


def shine():
    # shine/sweep: the idle shine's band, 40 x 80 pt, leaning 20 degrees.
    # Code moves it across a primary button's face, clipped to the face.
    # Its high-contrast twin is never drawn (the sweep is off in high
    # contrast and reduced motion); it is kept so the atlas stays one layout.
    W, H = 40, 80
    lean = math.tan(math.radians(20)) * H / 2
    def band(x, half):
        return "M%s 0 L%s 0 L%s %s L%s %s Z" % (
            f(x - half + lean), f(x + half + lean), f(x + half - lean), f(H), f(x - half - lean), f(H))
    defs = ['<linearGradient id="l1" x1="0" y1="0" x2="1" y2="0"><stop offset="0" stop-color="%s" stop-opacity="0"/>'
            '<stop offset="0.5" stop-color="%s" stop-opacity="0.62"/><stop offset="1" stop-color="%s" stop-opacity="0"/>'
            '</linearGradient>' % (WHITE, WHITE, WHITE),
            '<linearGradient id="l2" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="%s"/>'
            '<stop offset="0.5" stop-color="%s" stop-opacity="0.6"/><stop offset="1" stop-color="%s" stop-opacity="0.2"/>'
            '</linearGradient>' % (WHITE, WHITE, WHITE),
            '<mask id="m1"><rect width="%d" height="%d" fill="url(#l2)"/></mask>' % (W, H)]
    normal = ['<g mask="url(#m1)">',
              '  <path d="%s" fill="url(#l1)"/>' % band(W / 2 - 4, 9),
              '  <path d="%s" fill="%s" fill-opacity="0.5"/>' % (band(W / 2 + 9, 1.6), WHITE),
              '</g>']
    hc = ['<path d="%s" fill="%s" fill-opacity="0.5"/>' % (band(W / 2, 6), WHITE)]
    write("shine", "sweep", W, H, defs, normal, hc)


def coin_face(cx, cy, rx, ry, emboss=True):
    """A gold coin, rx wide and ry tall (rx < ry turns it towards its edge)."""
    e = rx / ry
    out = [
        '<ellipse cx="%s" cy="%s" rx="%s" ry="%s" fill="%s"/>' % (f(cx), f(cy + 1.5), f(rx), f(ry), GOLD_DROP),
        '<ellipse cx="%s" cy="%s" rx="%s" ry="%s" fill="url(#c1)" stroke="%s" stroke-width="1.5"/>' % (f(cx), f(cy), f(rx), f(ry), GOLD_RIM),
        '<ellipse cx="%s" cy="%s" rx="%s" ry="%s" fill="none" stroke="%s" stroke-width="1.2" stroke-opacity="0.75"/>' % (f(cx), f(cy), f(rx - 2.6 * e), f(ry - 2.6), GOLD_BOTTOM),
    ]
    if emboss:
        pts = star(0, 0, 5, 6.2, 2.7).split()
        sp = " ".join("%s,%s" % (f(cx + float(p.split(",")[0]) * e), f(cy + float(p.split(",")[1]))) for p in pts)
        sp_hi = " ".join("%s,%s" % (f(cx + float(p.split(",")[0]) * e), f(cy - 0.7 + float(p.split(",")[1]))) for p in pts)
        out += ['<polygon points="%s" fill="%s" stroke-linejoin="round"/>' % (sp, GOLD_BOTTOM),
                '<polygon points="%s" fill="%s"/>' % (sp_hi, GOLD_TOP)]
    out.append('<ellipse cx="%s" cy="%s" rx="%s" ry="%s" fill="url(#c2)"/>' % (f(cx - rx * 0.25), f(cy - ry * 0.45), f(rx * 0.5), f(ry * 0.32)))
    return out


def coin_hc(cx, cy, rx, ry, emboss=True):
    e = rx / ry
    out = ['<ellipse cx="%s" cy="%s" rx="%s" ry="%s" fill="%s" stroke="%s" stroke-width="%s"/>' % (f(cx), f(cy), f(rx - 0.5), f(ry - 0.5), GOLD, INK, f(LINE_HC))]
    if emboss:
        pts = star(0, 0, 5, 6, 2.8).split()
        sp = " ".join("%s,%s" % (f(cx + float(p.split(",")[0]) * e), f(cy + float(p.split(",")[1]))) for p in pts)
        out.append('<polygon points="%s" fill="%s" stroke-linejoin="round"/>' % (sp, INK))
    return out


def coin():
    # coin/face, coin/turn, coin/edge: the flying coin, 28 pt, in three
    # turns; code steps through them as the coin spins along its arc.
    W = 28; c = W / 2; r = 12.5
    defs = ['<linearGradient id="c1" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="%s"/>'
            '<stop offset="0.5" stop-color="%s"/><stop offset="1" stop-color="%s"/></linearGradient>' % (GOLD_TOP, GOLD, GOLD_BOTTOM),
            '<linearGradient id="c2" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="%s" stop-opacity="0.85"/>'
            '<stop offset="1" stop-color="%s" stop-opacity="0"/></linearGradient>' % (WHITE, WHITE)]
    write("coin", "face", W, W, defs, coin_face(c, c - 0.75, r, r), coin_hc(c, c, r, r))
    write("coin", "turn", W, W, defs, coin_face(c, c - 0.75, r * 0.55, r), coin_hc(c, c, r * 0.55, r))
    edge = ['<rect x="%s" y="%s" width="5" height="%s" rx="2.5" fill="%s"/>' % (f(c - 2.5), f(c - r + 0.75), f(2 * r), GOLD_DROP),
            '<rect x="%s" y="%s" width="5" height="%s" rx="2.5" fill="url(#c1)" stroke="%s" stroke-width="1.5"/>' % (f(c - 2.5), f(c - r - 0.75), f(2 * r), GOLD_RIM),
            '<rect x="%s" y="%s" width="1.4" height="%s" rx="0.7" fill="%s" fill-opacity="0.8"/>' % (f(c - 1.2), f(c - r + 2), f(2 * r - 6), WHITE)]
    edge_hc = ['<rect x="%s" y="%s" width="6" height="%s" rx="3" fill="%s" stroke="%s" stroke-width="%s"/>' % (f(c - 3), f(c - r), f(2 * r), GOLD, INK, f(LINE_HC))]
    write("coin", "edge", W, W, defs, edge, edge_hc)


if __name__ == "__main__":
    burst()
    sparkle()
    shine()
    coin()
