#!/usr/bin/env python3
"""Writes the kit's batch 1a sources (kit-spec.md sections 3, 4.1 and 5),
batch 1b's (kit_1b.py: the heist's other families and the overlays),
batch 1c's (kit_num.py: the baked numerals), batch 2a's (kit_2a.py:
the panels, sheets, popup, rank frames, header and ribbon), batch 2b's
(kit_2b.py: the tab bar, tabs, segmented, chips, tiles, locked, toggle and
slider) and
art/ui/palette.json (section 6.2) from client/ui/tokens.json.

    python3 art/ui/kit_build/build_kit.py
    node tools/ui_bake/bake.js kit

Every colour a face draws with is a token, or one of the few the kit's faces
add (`KIT` below: the tertiary's two plates, the pressed, disabled and
high-contrast fills), which go into tokens.json through K1 with the skins.
The sources are written, never edited by hand; change this file and rerun.
Sizes are in points; 1 point is 6 pixels in the atlas, so every size here is
a multiple of 1/6.
"""
import json
import os

ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", "..", ".."))
TOKENS = os.path.join(ROOT, "client/ui/tokens.json")
KIT_DIR = os.path.join(ROOT, "art/ui/kit")
# Skins written beside the kit, not into it: none now (the atlas has pages,
# so disc_school, once kept here, is baked with the rest). A skin named in
# DEFERRED is written to NEXT_DIR, which the bake does not read.
NEXT_DIR = os.path.join(ROOT, "art/ui/kit_next")
DEFERRED = ()
PALETTE = os.path.join(ROOT, "art/ui/palette.json")

T = json.load(open(TOKENS))
C = {k: v["value"] for k, v in T["color"].items() if isinstance(v, dict) and "value" in v}
HC = {k: v["value"] for k, v in T["color_high_contrast"].items() if isinstance(v, dict) and "value" in v}
S = {k: (v["value"] if isinstance(v, dict) else v) for k, v in T["size"].items() if k != "_what"}

LINE = S["line"]            # 2: the ink edge
LINE_HC = S["line_hc"]      # 3: the ink edge in high contrast
RADIUS = S["radius_l"]      # 16: a button's corners
LIP = S["drop_m"]           # 4: the solid lip (E2)
TRAVEL = S["press_travel"]  # 3: the pressed face sinks this far

# The colours the faces add to the tokens (AIA's, kit-spec.md K01's tertiary
# and section 3's states). Each says what it is lifted or muted from.
KIT = {
    # K01 tertiary, violet: the dark card lifted, lit from the top.
    "tertiary_violet_top": ("#7A68C2", "card #261A4C lifted ~34 L*, lit top"),
    "tertiary_violet_bottom": ("#6250AA", "card #1A1134 lifted ~30 L*"),
    "tertiary_violet_lip": ("#140C2A", "card's foot, darker"),
    # K01 tertiary, parchment: parchment lifted (darkened) to a tan plate.
    "tertiary_parchment_top": ("#D9BC86", "parchment #F1E3C4 lowered ~16 L*, lit top"),
    "tertiary_parchment_bottom": ("#C6A266", "parchment lowered ~24 L*"),
    "tertiary_parchment_lip": ("#7A5428", "parchment_text_3 #8A5A1C, deeper"),
    # Pressed: each material darker (section 3, P).
    "gold_pressed_top": ("#E2BF72", "gold_top x0.88"),
    "gold_pressed_mid": ("#D09C44", "gold x0.88"),
    "gold_pressed_bottom": ("#A8702A", "gold_bottom x0.85"),
    "leather_pressed_light": ("#55303F", "leather_light x0.8"),
    "leather_pressed_mid": ("#2E1826", "leather_mid x0.8"),
    "red_pressed_top": ("#E86A7C", "alarm_light x0.86"),
    "red_pressed_bottom": ("#A01834", "red_deep x0.82"),
    "green_pressed_top": ("#76C440", "green top x0.86"),
    "green_pressed_mid": ("#4AA834", "green mid x0.85"),
    "green_pressed_bottom": ("#2A7A1E", "green bottom x0.84"),
    # Disabled: flat, muted (section 3, D); words keep 4.5:1 on them.
    "gold_disabled": ("#B8A88C", "gold, desaturated; text_on_gold 8:1 on it"),
    "leather_disabled": ("#4A3C44", "leather, desaturated; text_on_leather 7:1"),
    "red_disabled": ("#8A5862", "alarm, desaturated; on_alarm 5.9:1"),
    "green_disabled": ("#5A7856", "green, desaturated; text_on_green 5.4:1"),
    "violet_disabled": ("#6A6488", "tertiary violet, desaturated; text_on_night 8:1"),
    "parchment_disabled": ("#C4B69C", "tertiary parchment, desaturated; parchment_ink 9:1"),
    "disabled_line": ("#2E2632", "ink_line softened: a flat face's edge"),
    # High contrast: one opaque fill a face, 3-point ink edges, no gloss.
    "gold_hc": ("#F2C14E", "gold, flat"),
    "gold_hc_pressed": ("#D9A630", "gold, flat, darker"),
    "leather_hc": ("#7A4660", "leather lifted, so it steps off the opaque card"),
    "leather_hc_pressed": ("#64384E", "leather lifted, darker"),
    "red_hc_pressed": ("#8A1328", "alarm_fill (hc), a shade darker"),
    "green_hc": ("#4AAA4C", "green, flat"),
    "green_hc_pressed": ("#3E9A40", "green, flat, darker"),
    "violet_hc": ("#5A4AA6", "tertiary violet, flat"),
    "violet_hc_pressed": ("#4C3C96", "tertiary violet, flat, darker"),
    "parchment_hc": ("#C9A462", "tertiary parchment, flat"),
    "parchment_hc_pressed": ("#B08A4A", "tertiary parchment, flat, darker"),
    "disabled_hc": ("#8A8494", "every disabled face in high contrast: one grey"),
    "locked_hc": ("#2E6E76", "locked teal, flat"),
    # Locked on the night backdrop's lit foot: gradient.locked lifted a step.
    "locked_top": ("#4A9AA0", "gradient.locked's #3A8A90, lifted: 2 value steps off the lit backdrop"),
    "locked_bottom": ("#30707A", "gradient.locked's #245A66, lifted"),
}
K = {k: v[0] for k, v in KIT.items()}


def p(v):
    """A number in points, as short as it can be written."""
    return ("%.4f" % v).rstrip("0").rstrip(".")


class Svg:
    def __init__(self, w, h, sl):
        self.w, self.h, self.slice = w, h, sl
        self.defs, self.groups = [], []
        self.ids = 0

    def grad(self, stops, x2=0, y2=1, x1=0, y1=0, radial=None):
        self.ids += 1
        gid = "g%d" % self.ids
        st = "".join('<stop offset="%s" stop-color="%s"%s/>' % (
            p(o), c[:7], ' stop-opacity="%s"' % p(int(c[7:9], 16) / 255) if len(c) == 9 else "")
            for o, c in stops)
        if radial:
            cx, cy, r = radial
            self.defs.append('<radialGradient id="%s" cx="%s" cy="%s" r="%s" fx="%s" fy="%s">%s</radialGradient>'
                             % (gid, p(cx), p(cy), p(r), p(cx), p(cy), st))
        else:
            self.defs.append('<linearGradient id="%s" x1="%s" y1="%s" x2="%s" y2="%s">%s</linearGradient>'
                             % (gid, p(x1), p(y1), p(x2), p(y2), st))
        return "url(#%s)" % gid

    def cap_mask(self):
        """A mask that keeps the left and right 12 points and hides the
        middle column (18 to 20 points) the 9-slice stretches."""
        self.ids += 1
        mid = "m%d" % self.ids
        w = self.w
        st = [(0, 1), (12 / w, 1), (17 / w, 0), (21 / w, 0), (26 / w, 1), (1, 1)]
        self.defs.append('<linearGradient id="%sg" x1="0" y1="0" x2="%s" y2="0" gradientUnits="userSpaceOnUse">%s'
                         '</linearGradient>' % (mid, p(w), "".join(
                             '<stop offset="%s" stop-color="#FFFFFF" stop-opacity="%s"/>' % (p(o), p(a)) for o, a in st)))
        self.defs.append('<mask id="%s" maskUnits="userSpaceOnUse" x="0" y="0" width="%s" height="%s">'
                         '<rect width="%s" height="%s" fill="url(#%sg)"/></mask>' % (
                             mid, p(w), p(self.h), p(w), p(self.h), mid))
        return "url(#%s)" % mid

    def pattern_stripes(self, colour):
        self.ids += 1
        pid = "s%d" % self.ids
        a = int(colour[7:9], 16) / 255 if len(colour) == 9 else 1
        self.defs.append('<pattern id="%s" width="6" height="6" patternUnits="userSpaceOnUse" '
                         'patternTransform="rotate(45)"><rect width="2.5" height="6" fill="%s" '
                         'fill-opacity="%s"/></pattern>' % (pid, colour[:7], p(a)))
        return "url(#%s)" % pid

    def state(self, name, body, hc=False, sl=None):
        attrs = 'data-state="%s"' % name
        if hc:
            attrs += ' data-mode="hc"'
        if sl:
            attrs += ' data-slice="%s"' % " ".join(p(v) for v in sl)
        self.groups.append("  <g %s>\n%s\n  </g>" % (attrs, "\n".join("    " + b for b in body)))

    def text(self):
        out = ['<svg xmlns="http://www.w3.org/2000/svg" width="%s" height="%s"%s>'
               % (p(self.w), p(self.h), ' data-slice="%s"' % " ".join(p(v) for v in self.slice) if self.slice else "")]
        out.append("  <!-- Written by art/ui/kit_build/build_kit.py from client/ui/tokens.json; do not edit. -->")
        out.append("  <defs>\n" + "\n".join("    " + d for d in self.defs) + "\n  </defs>")
        out += self.groups
        out.append("</svg>")
        return "\n".join(out) + "\n"


def col(c):
    return ' fill="%s"%s' % (c[:7], ' fill-opacity="%s"' % p(int(c[7:9], 16) / 255) if len(c) == 9 else "")


def stroke(c, w):
    return ' stroke="%s" stroke-width="%s"%s' % (
        c[:7], p(w), ' stroke-opacity="%s"' % p(int(c[7:9], 16) / 255) if len(c) == 9 else "")


def rrect(x, y, w, h, r, fill="none", extra=""):
    return '<rect x="%s" y="%s" width="%s" height="%s" rx="%s"%s%s/>' % (
        p(x), p(y), p(w), p(h), p(r), (' fill="%s"' % fill) if fill.startswith("url") or fill == "none" else col(fill), extra)


# --- A button face (9-slice) -------------------------------------------------
# The piece: a face W wide and FACE high, its lip below it; the ink edge is
# centred on the face's outline, so the piece is 1 point larger all round.

W = 38
FACE = 42


def face_layers(svg, m, x, y, w, h, r, lit):
    """The layers of a lit material face at (x, y): base, inner rim,
    highlight, shade, gloss, ink edge (kit-spec.md section 4, layered
    materials; light from the top left)."""
    out = [rrect(x, y, w, h, r, m["fill"])]
    if m.get("stripes"):
        # Hatching only on the two end caps, fading out before the middle
        # column: the 9-slice stretches that column, and stretched diagonals
        # kink. A long locked button reads as hatched ends on teal.
        out.append(rrect(x, y, w, h, r, svg.pattern_stripes(m["stripes"]), ' mask="%s"' % svg.cap_mask()))
    if m.get("stitch"):
        # A tooled seam, not dashes: a groove and its lit lower lip, both
        # unbroken, so the stretched middle matches the ends.
        c, a = m["stitch"]
        out.append(rrect(x + 4.5, y + 4.5, w - 9, h - 9, max(r - 4.5, 2), "none",
                         stroke("#0A0408", 1) + ' stroke-opacity="0.55"'))
        out.append(rrect(x + 5.5, y + 5.5, w - 11, h - 11, max(r - 5.5, 2), "none",
                         stroke(c, 1) + ' stroke-opacity="%s"' % p(a)))
    if m.get("rim"):
        c, wd = m["rim"]
        out.append(rrect(x + 1 + wd / 2, y + 1 + wd / 2, w - 2 - wd, h - 2 - wd, r - 1 - wd / 2, "none", stroke(c, wd)))
    if m.get("highlight") and lit:
        c, wd = m["highlight"]
        g = svg.grad([(0, c), (0.42, c[:7] + "00"), (1, c[:7] + "00")])
        out.append(rrect(x + 1 + wd / 2, y + 1 + wd / 2, w - 2 - wd, h - 2 - wd, r - 1 - wd / 2, "none",
                         ' stroke="%s" stroke-width="%s"' % (g, p(wd))))
    if m.get("shade"):
        c, wd = m["shade"]
        g = svg.grad([(0, c[:7] + "00"), (0.6, c[:7] + "00"), (1, c)]) if lit else \
            svg.grad([(0, c), (0.35, c[:7] + "00"), (1, c[:7] + "00")])
        out.append(rrect(x + 1 + wd / 2, y + 1 + wd / 2, w - 2 - wd, h - 2 - wd, r - 1 - wd / 2, "none",
                         ' stroke="%s" stroke-width="%s"' % (g, p(wd))))
    if m.get("gloss") and lit:
        a = m["gloss"]
        # The gloss band sits in the top slice, so stretching never smears it;
        # brighter at the left, where the light comes from.
        g = svg.grad([(0, "#FFFFFF%02X" % round(a * 255)), (0.55, "#FFFFFF%02X" % round(a * 0.55 * 255)),
                      (1, "#FFFFFF%02X" % round(a * 0.25 * 255))], x2=1, y2=0)
        out.append(rrect(x + 4, y + 3, w - 8, 15, 8, g))
    out.append(rrect(x, y, w, h, r, "none", stroke(m["line"], m.get("line_w", LINE))))
    return out


def mat(fill, line=None, line_w=LINE, **kw):
    m = {"fill": fill, "line": line or C["ink_line"], "line_w": line_w}
    m.update(kw)
    return m


def hc_set(normal, pressed, disabled=None, lip="#000000"):
    ink = HC["ink"]
    return {
        "normal": mat(normal, ink, LINE_HC, lip=lip),
        "pressed": mat(pressed, ink, LINE_HC, lip=lip),
        "disabled": mat(disabled or K["disabled_hc"], ink, LINE_HC),
        "locked": mat(K["locked_hc"], ink, LINE_HC, lip=lip),
    }


def build():
    svgs = {}
    # Each skin's materials per state. Gradients are made per file (their ids
    # live in the file), so a state's fill is a recipe until the file exists.
    recipes = {
        "button_primary": {
            "normal": dict(fill=[(0, C["gold_top"]), (0.46, C["gold"]), (1, C["gold_bottom"])],
                           highlight=("#FFFFFF8C", 2), shade=("#6B44204D", 3), gloss=0.32,
                           rim=("#FFF1C866", 1), lip=C["gold_drop"]),
            "pressed": dict(fill=[(0, K["gold_pressed_top"]), (0.46, K["gold_pressed_mid"]), (1, K["gold_pressed_bottom"])],
                            shade=("#6B442080", 3), rim=("#FFF1C833", 1), lip=C["gold_drop"]),
            "disabled": dict(fill=K["gold_disabled"], line=K["disabled_line"]),
            "hc": (K["gold_hc"], K["gold_hc_pressed"]),
        },
        "button_secondary": {
            "normal": dict(fill=("radial", [(0, C["leather_light"]), (0.55, C["leather_mid"]), (1, C["leather_dark"])]),
                           rim=(C["leather_rim"], 2), highlight=("#FFDCB433", 3), gloss=0.1,
                           stitch=("#E8C08A", 0.45), lip=C["drop"]),
            "pressed": dict(fill=("radial", [(0, K["leather_pressed_light"]), (0.55, K["leather_pressed_mid"]), (1, C["leather_dark"])]),
                            rim=(C["leather_rim"] + "B3", 2), shade=("#00000066", 3),
                            stitch=("#E8C08A", 0.3), lip=C["drop"]),
            "disabled": dict(fill=K["leather_disabled"], line=K["disabled_line"]),
            "hc": (K["leather_hc"], K["leather_hc_pressed"]),
        },
        "button_danger": {
            "normal": dict(fill=[(0, C["alarm_light"] if "alarm_light" in C else "#FF8A9A"), (1, C["red_deep"])],
                           rim=(C["leather_rim"], 2), highlight=("#FFFFFF40", 2), gloss=0.28, lip=C["drop"]),
            "pressed": dict(fill=[(0, K["red_pressed_top"]), (1, K["red_pressed_bottom"])],
                            rim=(C["leather_rim"] + "B3", 2), shade=("#00000059", 3), lip=C["drop"]),
            "disabled": dict(fill=K["red_disabled"], line=K["disabled_line"]),
            "hc": (HC["alarm_fill"], K["red_hc_pressed"]),
        },
        "success": {
            "normal": dict(fill=[(0, "#8EE050"), (0.5, "#5CC542"), (1, "#349125")],
                           highlight=("#FFFFFF59", 2), shade=("#1E5A1459", 3), gloss=0.3, lip="#1E5A14"),
            "pressed": dict(fill=[(0, K["green_pressed_top"]), (0.5, K["green_pressed_mid"]), (1, K["green_pressed_bottom"])],
                            shade=("#1E5A1480", 3), lip="#1E5A14"),
            "disabled": dict(fill=K["green_disabled"], line=K["disabled_line"]),
            "hc": (K["green_hc"], K["green_hc_pressed"]),
        },
        "button_tertiary": {
            "normal": dict(fill=[(0, K["tertiary_violet_top"]), (1, K["tertiary_violet_bottom"])], lip=K["tertiary_violet_lip"]),
            "pressed": dict(fill=[(0, K["tertiary_violet_bottom"]), (1, K["tertiary_violet_top"])], shade=("#14082A59", 3),
                            lip=K["tertiary_violet_lip"]),
            "disabled": dict(fill=K["violet_disabled"], line=K["disabled_line"]),
            "hc": (K["violet_hc"], K["violet_hc_pressed"]),
            "lip_h": 3,
        },
        "button_tertiary/parchment": {
            "normal": dict(fill=[(0, K["tertiary_parchment_top"]), (1, K["tertiary_parchment_bottom"])],
                           line=C["parchment_ink"], lip=K["tertiary_parchment_lip"]),
            "pressed": dict(fill=[(0, K["tertiary_parchment_bottom"]), (1, "#B08C52")], shade=("#4A2A1040", 3),
                            line=C["parchment_ink"], lip=K["tertiary_parchment_lip"]),
            "disabled": dict(fill=K["parchment_disabled"], line="#5A4636"),
            "hc": (K["parchment_hc"], K["parchment_hc_pressed"]),
            "lip_h": 3,
        },
    }
    lgrad = [(0, K["locked_top"]), (1, K["locked_bottom"])]
    for name, rc in recipes.items():
        skin, _, shape = name.partition("/")
        shape = shape or "box"
        lip_h = rc.get("lip_h", LIP)
        def resolve(svg, d):
            d = dict(d)
            f = d["fill"]
            if isinstance(f, tuple) and f[0] == "radial":
                d["fill"] = svg.grad(f[1], radial=(0.5, 0.28, 0.85))
            elif isinstance(f, list):
                d["fill"] = svg.grad(f)
            d.setdefault("line", C["ink_line"])
            return d

        x, y, w, r = 1, 1, W - 2, RADIUS
        H = 1 + FACE + lip_h + 1
        sl = [18, 20, 18, 4 + lip_h + 16]
        svg = Svg(W, H, sl)
        hc_normal, hc_pressed = rc["hc"]
        hcm = hc_set(hc_normal, hc_pressed)
        for st in ["normal", "pressed", "disabled", "locked"]:
            for hc in (False, True):
                if hc:
                    m = dict(hcm[st])
                else:
                    if st == "locked":
                        m = resolve(svg, dict(fill=lgrad, rim=("#FFFFFF26", 1.5), stripes="#FFFFFF29",
                                              highlight=("#FFFFFF40", 2), gloss=0.24, lip=C["drop"]))
                    else:
                        m = resolve(svg, rc[st])
                body = []
                if st == "disabled":
                    body += face_layers(svg, m, x, y, w, FACE, r, lit=False)
                else:
                    fy = y + (TRAVEL if st == "pressed" else 0)
                    body.append(rrect(x, y + lip_h, w, FACE, r, m["lip"], stroke(m["line"], m.get("line_w", LINE))))
                    body += face_layers(svg, m, x, fy, w, FACE, r, lit=(st != "pressed"))
                svg.state(st, body, hc=hc)
        svgs["%s/%s.svg" % (skin, shape)] = svg.text()

    svgs["button_primary/gold_round.svg"] = gold_round()
    # Batch 1b (kit_1b.py) is merged here, into this module's KIT, so the
    # palette holds its colours when this file runs as the script.
    import kit_1b
    KIT.update(kit_1b.KIT_1B)
    K.update({k: v[0] for k, v in kit_1b.KIT_1B.items()})
    svgs.update(kit_1b.build_1b())
    # Batch 1c (kit_num.py): the baked numerals, merged the same way.
    import kit_num
    KIT.update(kit_num.KIT_NUM)
    K.update({k: v[0] for k, v in kit_num.KIT_NUM.items()})
    svgs.update(kit_num.build_num())
    # Batch 2a (kit_2a.py): panels, sheets, popup, frames, header, ribbon.
    import kit_2a
    KIT.update(kit_2a.KIT_2A)
    K.update({k: v[0] for k, v in kit_2a.KIT_2A.items()})
    svgs.update(kit_2a.build_2a(T))
    # Batch 2b (kit_2b.py): tab bar, tabs, segmented, chips, tiles, locked, toggle, slider.
    import kit_2b
    KIT.update(kit_2b.KIT_2B)
    K.update({k: v[0] for k, v in kit_2b.KIT_2B.items()})
    svgs.update(kit_2b.build_2b(T))
    # Batch 2c (kit_2c.py): the own-name shapes of nine materials, and the warn tag.
    import kit_2c
    KIT.update(kit_2c.KIT_2C)
    K.update({k: v[0] for k, v in kit_2c.KIT_2C.items()})
    svgs.update(kit_2c.build_2c(T))
    return svgs


def gold_round():
    """The round main action (`gold_round`, size `action_round` 60): a sprite."""
    d = S["action_round"]
    lip = 5
    W2 = d + 2
    H2 = d + lip + 2
    svg = Svg(W2, H2, None)
    cx, cy, r = W2 / 2, 1 + d / 2, d / 2

    def circle(cx, cy, r, fill="none", extra=""):
        return '<circle cx="%s" cy="%s" r="%s"%s%s/>' % (
            p(cx), p(cy), p(r), (' fill="%s"' % fill) if fill.startswith("url") or fill == "none" else col(fill), extra)

    stops = [(0, C["cream"]), (0.45, "#F2C45C"), (1, C["leather_rim"])]
    pstops = [(0, "#E8D6A8"), (0.45, "#D6A644"), (1, "#9A5E16")]
    for st in ["normal", "pressed", "disabled", "locked"]:
        for hc in (False, True):
            body = []
            if hc:
                fill = {"normal": K["gold_hc"], "pressed": K["gold_hc_pressed"],
                        "disabled": K["disabled_hc"], "locked": K["locked_hc"]}[st]
                fy = cy + (TRAVEL if st == "pressed" else 0)
                if st != "disabled":
                    body.append(circle(cx, cy + lip, r, "#000000", stroke("#000000", LINE_HC)))
                body.append(circle(cx, fy, r, fill, stroke("#000000", LINE_HC)))
                svg.state(st, body, hc=True)
                continue
            if st == "disabled":
                body.append(circle(cx, cy, r, K["gold_disabled"], stroke(K["disabled_line"], LINE)))
                svg.state(st, body)
                continue
            fy = cy + (TRAVEL if st == "pressed" else 0)
            body.append(circle(cx, cy + lip, r, C["gold_drop"], stroke(C["ink_line"], LINE)))
            if st == "locked":
                g = svg.grad([(0, K["locked_top"]), (1, K["locked_bottom"])])
                body.append(circle(cx, fy, r, g))
                body.append(circle(cx, fy, r, svg.pattern_stripes("#FFFFFF1F")))
                body.append(circle(cx, fy, r - 1.75, "none", stroke("#FFFFFF26", 1.5)))
            else:
                g = svg.grad(stops if st == "normal" else pstops, radial=(0.5, 0.2, 0.9))
                body.append(circle(cx, fy, r, g))
                body.append(circle(cx, fy, r - 2.5, "none", stroke("#8A5A1C", 3) + ' stroke-opacity="%s"' % (
                    "0.55" if st == "normal" else "0.4")))
                if st == "normal":
                    gl = svg.grad([(0, "#FFFFFF66"), (1, "#FFFFFF00")])
                    body.append('<ellipse cx="%s" cy="%s" rx="%s" ry="%s" fill="%s"/>' % (
                        p(cx - 3), p(fy - r * 0.45), p(r * 0.62), p(r * 0.34), gl))
            body.append(circle(cx, fy, r, "none", stroke(C["ink_line"], LINE)))
            svg.state(st, body)
    return svg.text()


def palette():
    """art/ui/palette.json: the tokens' colours flat, normal and high
    contrast, the gradients' stops resolved, and the kit's own additions."""
    def res(v):
        return C.get(v, v)
    grads = {}
    for k, g in T["gradient"].items():
        if k.startswith("_") or not isinstance(g, dict) or "value" not in g:
            continue
        grads[k] = [[o, res(c)] for o, c in g["value"]]
    return {
        "_what": "The art's palette, generated from client/ui/tokens.json by art/ui/kit_build/build_kit.py "
                 "(kit-spec.md section 6.2); never edited by hand. `kit` holds the colours the kit's faces add, "
                 "which enter tokens.json through K1 with their skins.",
        "color": dict(sorted(C.items())),
        "color_high_contrast": dict(sorted(HC.items())),
        "gradient": dict(sorted(grads.items())),
        "kit": {k: {"value": v[0], "from": v[1]} for k, v in sorted(KIT.items())},
    }


def main():
    svgs = build()
    for rel, text in sorted(svgs.items()):
        path = os.path.join(NEXT_DIR if rel.split("/")[0] in DEFERRED else KIT_DIR, rel)
        os.makedirs(os.path.dirname(path), exist_ok=True)
        with open(path, "w") as f:
            f.write(text)
        print("wrote", os.path.relpath(path, ROOT))
    with open(PALETTE, "w") as f:
        json.dump(palette(), f, indent=2, sort_keys=False)
        f.write("\n")
    print("wrote", os.path.relpath(PALETTE, ROOT))


if __name__ == "__main__":
    main()
