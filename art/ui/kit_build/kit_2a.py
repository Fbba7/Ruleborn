"""The kit's batch 2a sources (kit-spec.md sections 3, 4 and 8.2): the calm
surfaces and the chrome. Called by build_kit.py; not run on its own.

Gold keeps its two roles from batches 1a and 1b: the main action's fill
(not here) and a material, as a rank frame or a rim. The rank frames are the
only rank ladder the kit draws (kit-spec.md section 2.1), and each rank adds a
shape as well as a metal, so the ladder reads in greyscale and to colour-blind
eyes: oak is plain grained wood; silver adds an inner groove; gold adds the
groove and a stud in each corner; prismatic adds the groove and a cut gem in
each corner. Every piece takes one light from the top left.

Pieces, by skin (shapes are the material names KitSkin.piece looks up, or
`box`, the skin's fallback):

    panel_parchment/box              parchment (E2): normal, locked
    panel_parchment/parchment_done   the done parchment, a green corner and its tick: normal
    panel_parchment/sheet_parchment  the parchment sheet from the bottom (E3): normal
    sheet/box                        the dark sheet from the bottom (E3): normal
    sheet/handle                     the grab handle on the dark sheet (a sprite)
    sheet/handle_parchment           the grab handle on the parchment sheet (a sprite)
    popup/box                        the popup's dark frame (E3: lip and soft shadow): normal
    frame_oak/box                    the oak rank frame (a ring around a panel): normal, locked
    frame_silver/box                 the silver rank frame: normal, locked
    frame_gold/box                   the gold rank frame: normal, locked
    frame_prismatic/box              the prismatic rank frame: normal, locked
    header/box                       the top bar's band (flush with the top, E2): normal
    header/name_plate                the leather name plate (E1): normal
    ribbon/box                       the ribbon's neutral ground, tinted per school: normal
    ribbon/frame                     the ribbon's untinted ink, gloss and fold: normal
    ribbon/chapter                   the untinted violet ribbon (a section title): normal

The tinted ribbon is two pieces at the same rect, as disc_school is: the
tinted `box` under the untinted `frame`, so the gloss stays white light and the
ink stays ink whatever the school.
"""

from build_kit import C, HC, K, KIT, LINE, LINE_HC, Svg, col, p, rrect, stroke
from kit_1b import a, cap_mask, circle, foot_shade, hc_edge, ink, lit_band, rim_ring, stripes, top_light

KIT_2A = {
    "parchment_lip": ("#8A5A1C", "parchment_text_3: parchment's solid lip, a tan foot, not a black one"),
    "parchment_deckle": ("#C9A86A", "parchment_bottom #F1E3C4 two steps down: the inset deckle line"),
    "parchment_locked_top": ("#E4EEE8", "parchment_top toward locked teal, a step"),
    "parchment_locked_bottom": ("#BCD2CC", "parchment_bottom toward locked teal, a step"),
    "done_corner_top": ("#5ED092", "success #3FBF7F, lit: the done corner's top"),
    "done_corner_bottom": ("#2E9A62", "success #3FBF7F, shaded: the done corner's foot"),
    "popup_rim": ("#3E2E86", "card_lit_glow #5A3CA8 toward card, a raised bevel ring"),
    "header_top": ("#2E2060", "card_lit_mid #2A1A56, lifted: the top bar's band"),
    "header_bottom": ("#1C1240", "card_bottom #1A1134, lifted a little"),
    "frame_locked_light": ("#7AB6BA", "locked_top #4A9AA0, lit: a locked frame's bevel"),
    "frame_locked_dark": ("#24545C", "locked_bottom #30707A, deeper"),
    "oak_hc": ("#8A5630", "frame_oak's body, flat"),
    "silver_hc": ("#C8D0DC", "frame_silver's body, flat"),
    "prismatic_hc": ("#C29AFF", "frame_prismatic's violet stop, flat"),
    "gem_light": ("#FFFFFF", "the prismatic gem's lit facet"),
    "ribbon_tail": ("#A8A8A8", "neutral, tinted: the tail, a step under the band"),
    "ribbon_fold": ("#5A5A5A", "neutral, tinted: the fold, the school colour's deep shade"),
    "ribbon_hc": ("#D2D2D2", "neutral, flat, tinted in high contrast"),
    "chapter_tail": ("#4836B0", "tab_active_bottom #4532B8: the violet ribbon's tail"),
    "chapter_fold": ("#24186A", "tab_active_bottom, deep: the violet ribbon's fold"),
}
KIT.update(KIT_2A)
K.update({k: v[0] for k, v in KIT_2A.items()})

DROP_M, DROP_L = 4, 5


def top_round(x, y, w, h, r, fill="none", extra=""):
    """A rect rounded at its top corners only (a sheet, flush with the
    screen's foot)."""
    d = "M%s %sV%sQ%s %s %s %sH%sQ%s %s %s %sV%sZ" % (
        p(x), p(y + h), p(y + r), p(x), p(y), p(x + r), p(y), p(x + w - r), p(x + w), p(y), p(x + w),
        p(y + r), p(y + h))
    return '<path d="%s"%s%s/>' % (d, (' fill="%s"' % fill) if fill.startswith("url") or fill == "none" else col(fill), extra)


def bottom_round(x, y, w, h, r, fill="none", extra=""):
    """A rect rounded at its bottom corners only (the top bar, flush with the
    screen's top)."""
    d = "M%s %sH%sV%sQ%s %s %s %sH%sQ%s %s %s %sZ" % (
        p(x), p(y), p(x + w), p(y + h - r), p(x + w), p(y + h), p(x + w - r), p(y + h), p(x + r), p(x),
        p(y + h), p(x), p(y + h - r))
    return '<path d="%s"%s%s/>' % (d, (' fill="%s"' % fill) if fill.startswith("url") or fill == "none" else col(fill), extra)


def blur(svg, sd):
    svg.ids += 1
    fid = "f%d" % svg.ids
    svg.defs.append('<filter id="%s" x="-50%%" y="-50%%" width="200%%" height="200%%">'
                    '<feGaussianBlur stdDeviation="%s"/></filter>' % (fid, p(sd)))
    return ' filter="url(#%s)"' % fid


def corner_mask(svg, c):
    """A mask keeping the four c-point corners (a 9-slice's fixed cells)."""
    svg.ids += 1
    mid = "m%d" % svg.ids
    rects = "".join('<rect x="%s" y="%s" width="%s" height="%s" fill="#FFFFFF"/>' % (p(x), p(y), p(c), p(c))
                    for x in (0, svg.w - c) for y in (0, svg.h - c))
    svg.defs.append('<mask id="%s" maskUnits="userSpaceOnUse" x="0" y="0" width="%s" height="%s">%s</mask>'
                    % (mid, p(svg.w), p(svg.h), rects))
    return "url(#%s)" % mid


# --- Parchment ---------------------------------------------------------------

def parchment_face(svg, b, x, y, w, fh, r, st):
    """Parchment's layers: a tan lip, the paper's gradient, a white lit top,
    a warm foot shade, the inset deckle line, an ink edge."""
    b.append(rrect(x, y + DROP_M, w, fh, r, K["parchment_lip"], ink(C["ink_line"], LINE)))
    if st == "locked":
        g = svg.grad([(0, K["parchment_locked_top"]), (1, K["parchment_locked_bottom"])])
    else:
        g = svg.grad([(0, C["parchment_top"]), (0.5, "#F6EAD0"), (1, C["parchment_bottom"])])
    b.append(rrect(x, y, w, fh, r, g))
    if st == "locked":
        b.append(rrect(x, y, w, fh, r, stripes(svg, a(K["locked_bottom"], 0.3)), ' mask="%s"' % corner_mask(svg, 17)))
    b.append(top_light(svg, x + 1, y + 1, w - 2, fh - 2, r - 1, a("#FFFFFF", 0.95), 2))
    b.append(foot_shade(svg, x + 1, y + 1, w - 2, fh - 2, r - 1, a(C["parchment_text_3"], 0.45), 2.5))
    b.append(rrect(x + 4.5, y + 4.5, w - 9, fh - 9, r - 4.5, "none",
                   stroke(K["parchment_deckle"], 1) + ' stroke-opacity="0.7"'))
    b.append(rrect(x, y, w, fh, r, "none", ink(C["ink_line"], LINE)))


def panel_parchment():
    out = {}
    W, FH, R = 40, 40, 16
    H = 1 + FH + DROP_M + 1
    x, y, w = 1, 1, W - 2
    svg = Svg(W, H, [18, 18, 18, 22])
    for st in ("normal", "locked"):
        for hc in (False, True):
            b = []
            if hc:
                b.append(rrect(x, y + DROP_M, w, FH, R, "#000000"))
                b.append(rrect(x, y, w, FH, R, HC["paper"]))
                if st == "locked":
                    b.append(rrect(x, y, w, FH, R, stripes(svg, K["locked_hc"], 6, 2), ' mask="%s"' % corner_mask(svg, 17)))
                b.append(hc_edge(x, y, w, FH, R, K["locked_hc"] if st == "locked" else "#000000"))
                svg.state(st, b, hc=True)
                continue
            parchment_face(svg, b, x, y, w, FH, R, st)
            svg.state(st, b)
    out["panel_parchment/box.svg"] = svg.text()

    # Done: the same paper with a green corner folded down at the top right
    # (inside the fixed corner cell) and an ink tick on it.
    svg = Svg(W, H, [18, 18, 18, 22])
    cx = x + w
    tri = '<path d="M%s %sH%sQ%s %s %s %sV%sZ"%s%s/>'
    for hc in (False, True):
        b = []
        if hc:
            b.append(rrect(x, y + DROP_M, w, FH, R, "#000000"))
            b.append(rrect(x, y, w, FH, R, HC["paper"]))
        else:
            parchment_face(svg, b, x, y, w, FH, R, "normal")
        # The seal: a green round stamp inside the corner cell, lit at the
        # top, an ink edge, an ink tick on it.
        sx, sy, sr = cx - 8.5, y + 8, 6
        g = svg.grad([(0, K["done_corner_top"]), (1, K["done_corner_bottom"])])
        fill = C["success"] if hc else g
        if not hc:
            b.append(circle(sx, sy + 1.5, sr, C["drop"]))
        b.append(circle(sx, sy, sr, fill, stroke("#000000" if hc else C["ink_line"],
                                                             LINE_HC if hc else LINE)))
        if not hc:
            b.append('<path d="M%s %sA%s %s 0 0 1 %s %s" fill="none"%s/>' % (
                p(sx - sr + 2), p(sy - 1), p(sr - 2), p(sr - 2), p(sx + sr - 2), p(sy - 1),
                stroke("#FFFFFF", 1.2) + ' stroke-opacity="0.55" stroke-linecap="round"'))
        b.append('<path d="M%s %sL%s %sL%s %s" fill="none"%s/>' % (
            p(sx - 3.5), p(sy + 0.2), p(sx - 1), p(sy + 2.8), p(sx + 3.6), p(sy - 2.6),
            stroke("#000000" if hc else C["ink_line"], 2.2) + ' stroke-linecap="round" stroke-linejoin="round"'))
        if hc:
            b.append(hc_edge(x, y, w, FH, R, "#000000"))
        svg.state("normal", b, hc=hc)
    out["panel_parchment/parchment_done.svg"] = svg.text()
    out["panel_parchment/sheet_parchment.svg"] = sheet_piece("parchment")
    return out


# --- Sheets and the popup ----------------------------------------------------

def sheet_piece(kind):
    """A sheet from the bottom (E3): rounded at the top, flush at the foot,
    a soft shadow above its top edge over the scrim. Its grab handle is its
    own sprite (sheet/handle), centred by the code: a 9-slice cannot centre
    it."""
    W, R, TOP, FH = 52, 22, 6, 40
    H = TOP + FH
    svg = Svg(W, H, [24, TOP + 24, 24, 4])
    x, y, w = 1, TOP, W - 2
    for hc in (False, True):
        b = []
        if hc:
            fill = HC["paper"] if kind == "parchment" else HC["card_top"]
            b.append(top_round(x, y, w, FH, R, fill))
            b.append(top_round(x + 1.5, y + 1.5, w - 3, FH, R - 1.5, "none",
                               stroke("#000000" if kind == "parchment" else K["edge_hc"], LINE_HC)))
            svg.state("normal", b, hc=True)
            continue
        b.append(top_round(x, y - 1.5, w, FH, R, a(C["drop"], 0.55), blur(svg, 2.2)))
        if kind == "parchment":
            g = svg.grad([(0, C["parchment_top"]), (0.35, "#F6EAD0"), (1, C["parchment_bottom"])])
            lit, edge = a("#FFFFFF", 0.95), C["ink_line"]
        else:
            g = svg.grad([(0, C["card_lit_mid"]), (0.4, C["card_top"]), (1, C["card_bottom"])])
            lit, edge = a(C["tab_active_top"], 0.4), C["ink_deep"]
        b.append(top_round(x, y, w, FH, R, g))
        if kind != "parchment":
            gl = svg.grad([(0, a("#FFFFFF", 0.09)), (1, a("#FFFFFF", 0))])
            b.append(top_round(x + 3, y + 2.5, w - 6, 16, R - 3, gl))
        tl = svg.grad([(0, lit), (0.4, lit[:7] + "00"), (1, lit[:7] + "00")])
        b.append(top_round(x + 1.25, y + 1.25, w - 2.5, FH, R - 1.25, "none",
                           ' stroke="%s" stroke-width="1.5"' % tl))
        if kind == "parchment":
            b.append(top_round(x + 4.5, y + 4.5, w - 9, FH, R - 4.5, "none",
                               stroke(K["parchment_deckle"], 1) + ' stroke-opacity="0.7"'))
        b.append(top_round(x, y, w, FH + 2, R, "none", ink(edge, LINE)))
        svg.state("normal", b)
    return svg.text()


def handles():
    out = {}
    for name, (fill, edge, groove, hcfill) in {
            "handle": (C["text_on_night_3"], C["ink_deep"], a("#FFFFFF", 0.5), K["edge_hc"]),
            "handle_parchment": (C["parchment_text_3"], C["ink_line"], a("#FFFFFF", 0.35), "#000000")}.items():
        W, H = 42, 9
        svg = Svg(W, H, None)
        for hc in (False, True):
            b = []
            if hc:
                b.append(rrect(1.5, 1.5, W - 3, H - 3, (H - 3) / 2, hcfill))
                svg.state("normal", b, hc=True)
                continue
            b.append(rrect(1, 2, W - 2, H - 3, (H - 3) / 2, fill, ink(edge, 1.5)))
            b.append(rrect(4, 3.2, W - 8, 1.4, 0.7, groove))
            svg.state("normal", b)
        out["sheet/%s.svg" % name] = svg.text()
    return out


def popup():
    """The popup's frame (E3): a solid lip of drop_l, a soft shadow below it
    over the scrim, the lit card, a raised violet bevel ring and an ink edge.
    Its title is a ribbon (K19) set on top by the code."""
    ML, MT, MB, R, FW, FH = 8, 4, 12, 22, 50, 50
    W, H = ML * 2 + FW, MT + FH + DROP_L + MB
    svg = Svg(W, H, [ML + 24, MT + 24, ML + 24, MB + DROP_L + 24])
    x, y = ML, MT
    for hc in (False, True):
        b = []
        if hc:
            b.append(rrect(x, y + DROP_L, FW, FH, R, "#000000"))
            b.append(rrect(x, y, FW, FH, R, HC["card_top"]))
            b.append(hc_edge(x, y, FW, FH, R, K["edge_hc"]))
            svg.state("normal", b, hc=True)
            continue
        b.append(rrect(x - 1, y + DROP_L + 3, FW + 2, FH, R, a(C["drop"], 0.6), blur(svg, 4)))
        b.append(rrect(x, y + DROP_L, FW, FH, R, C["drop"], ink(C["ink_deep"], LINE)))
        b.append(rrect(x, y, FW, FH, R, svg.grad([(0, C["card_lit_glow"]), (0.22, C["card_lit_mid"]),
                                                   (1, C["card_lit_end"])])))
        b.append(rim_ring(x + 1, y + 1, FW - 2, FH - 2, R - 1, K["popup_rim"], 3))
        b.append(top_light(svg, x + 1, y + 1, FW - 2, FH - 2, R - 1, a(C["tab_active_top"], 0.6), 1.5))
        b.append(foot_shade(svg, x + 1, y + 1, FW - 2, FH - 2, R - 1, a("#000000", 0.4), 3))
        b.append(rrect(x + 4.5, y + 4.5, FW - 9, FH - 9, R - 4.5, "none", ink(a(C["ink_deep"], 0.8), 1)))
        b.append(lit_band(svg, x + 5, y + 5, FW - 10, FH, R - 5, 0.07, 18))
        b.append(rrect(x, y, FW, FH, R, "none", ink(C["ink_deep"], LINE)))
        svg.state("normal", b)
    return {"popup/box.svg": svg.text()}


# --- Rank frames -------------------------------------------------------------

FRAMES = {
    # rank: (token gradient, flat high-contrast fill, groove, studs, gems)
    # Every rank carries its own corner mark, so the rank reads by shape as
    # well as by colour: oak a dark nail head, silver a square rivet, gold a
    # round stud, prismatic a cut gem.
    "oak": ("frame_oak", "oak_hc", False, "nail", False),
    "silver": ("frame_silver", "silver_hc", True, "rivet", False),
    "gold": ("frame_gold", "gold_hc", True, True, False),
    "prismatic": ("frame_prismatic", "prismatic_hc", True, False, True),
}


def frame_stops(T, name):
    return [(o, C.get(c, c)) for o, c in T["gradient"][name]["value"]]


def ring(x, y, w, h, r, t, fill, extra=""):
    """A ring t points wide (outer rect minus inner), filled."""
    o = ('M%s %sH%sQ%s %s %s %sV%sQ%s %s %s %sH%sQ%s %s %s %sV%sQ%s %s %s %sZ' % (
        p(x + r), p(y), p(x + w - r), p(x + w), p(y), p(x + w), p(y + r), p(y + h - r), p(x + w), p(y + h),
        p(x + w - r), p(y + h), p(x + r), p(x), p(y + h), p(x), p(y + h - r), p(y + r), p(x), p(y), p(x + r), p(y)))
    xi, yi, wi, hi, ri = x + t, y + t, w - 2 * t, h - 2 * t, max(r - t, 0.5)
    i = ('M%s %sQ%s %s %s %sV%sQ%s %s %s %sH%sQ%s %s %s %sV%sQ%s %s %s %sZ' % (
        p(xi + ri), p(yi), p(xi), p(yi), p(xi), p(yi + ri), p(yi + hi - ri), p(xi), p(yi + hi),
        p(xi + ri), p(yi + hi), p(xi + wi - ri), p(xi + wi), p(yi + hi), p(xi + wi), p(yi + hi - ri),
        p(yi + ri), p(xi + wi), p(yi), p(xi + wi - ri), p(yi)))
    return '<path fill-rule="evenodd" d="%s %s"%s%s/>' % (
        o, i, (' fill="%s"' % fill) if fill.startswith("url") or fill == "none" else col(fill), extra)


def stud(svg, cx, cy, r, hc, locked):
    if hc:
        return ['<circle cx="%s" cy="%s" r="%s"%s%s/>' % (p(cx), p(cy), p(r), col("#FFFFFF"), stroke("#000000", 1.5))]
    g = svg.grad([(0, K["frame_locked_light"] if locked else C["cream"]), (0.5, K["locked_top"] if locked else C["gold"]),
                  (1, K["frame_locked_dark"] if locked else C["gold_rim"])], radial=(0.38, 0.3, 0.8))
    return ['<circle cx="%s" cy="%s" r="%s" fill="%s"%s/>' % (p(cx), p(cy), p(r), g, stroke(C["ink_line"], 1.2)),
            '<circle cx="%s" cy="%s" r="%s"%s/>' % (p(cx - r * 0.35), p(cy - r * 0.38), p(r * 0.32),
                                                   col(a("#FFFFFF", 0.4 if locked else 0.85)))]


def nail(svg, cx, cy, r, hc, locked):
    """Oak's mark: a small dark iron nail head, a glint on its shoulder."""
    if hc:
        return ['<circle cx="%s" cy="%s" r="%s"%s%s/>' % (p(cx), p(cy), p(r), col("#000000"), stroke("#FFFFFF", 1))]
    return ['<circle cx="%s" cy="%s" r="%s"%s%s/>' % (p(cx), p(cy), p(r), col(C["ink_line"]),
                                                     ' fill-opacity="%s"' % ("0.75" if locked else "0.95")),
            '<circle cx="%s" cy="%s" r="%s"%s/>' % (p(cx - r * 0.3), p(cy - r * 0.35), p(r * 0.36),
                                                   col(a("#FFFFFF", 0.3 if locked else 0.6)))]


def rivet(svg, cx, cy, r, hc, locked):
    """Silver's mark: a square rivet, lit from the top left."""
    box = (p(cx - r), p(cy - r), p(2 * r), p(2 * r))
    if hc:
        return ['<rect x="%s" y="%s" width="%s" height="%s" rx="0.6"%s%s/>' % (box + (col("#FFFFFF"), stroke("#000000", 1.5)))]
    g = svg.grad([(0, K["frame_locked_light"] if locked else "#FFFFFF"), (1, K["frame_locked_dark"] if locked else C["silver_ink"])],
                 x2=1, y2=1)
    return ['<rect x="%s" y="%s" width="%s" height="%s" rx="0.6" fill="%s"%s/>' % (box + (g, stroke(C["ink_line"], 1.1))),
            '<rect x="%s" y="%s" width="%s" height="%s"%s/>' % (p(cx - r * 0.55), p(cy - r * 0.55), p(r * 0.6), p(r * 0.6),
                                                               col(a("#FFFFFF", 0.35 if locked else 0.8)))]


def gem(svg, cx, cy, r, hc, locked):
    pts = [(cx, cy - r), (cx + r, cy), (cx, cy + r), (cx - r, cy)]
    d = "M" + "L".join("%s %s" % (p(u), p(v)) for u, v in pts) + "Z"
    if hc:
        return ['<path d="%s"%s%s/>' % (d, col("#FFFFFF"), stroke("#000000", 1.5) + ' stroke-linejoin="round"')]
    g = svg.grad([(0, "#FFFFFF"), (0.35, "#8AF0C8"), (0.7, "#7AC4FF"), (1, "#C29AFF")], x2=1, y2=1) if not locked else \
        svg.grad([(0, K["frame_locked_light"]), (1, K["frame_locked_dark"])])
    top = "M%s %sL%s %sL%s %sL%s %sZ" % (p(cx - r), p(cy), p(cx), p(cy - r), p(cx + r), p(cy), p(cx), p(cy - r * 0.2))
    return ['<path d="%s" fill="%s"%s/>' % (d, g, stroke(C["ink_line"], 1.2) + ' stroke-linejoin="round"'),
            '<path d="%s"%s/>' % (top, col(a(K["gem_light"], 0.25 if locked else 0.55)))]


def rank_frames(T):
    """A rank frame: a 6-point ring of its metal laid over a panel's face,
    hollow in the middle. The metal runs across the ring from its outer edge
    in (a bevel), lit along the top, shaded along the foot; an ink line on
    both edges. Locked: the ring in the locked material, hatched in its
    corners, the rank's own marks kept, dull."""
    out = {}
    W, R, TH = 48, 18, 6
    x = y = 1
    w = W - 2
    for rank, (grad, hcfill, groove, studs, gems) in FRAMES.items():
        svg = Svg(W, W, [22, 22, 22, 22])
        stops = frame_stops(T, grad)
        for st in ("normal", "locked"):
            for hc in (False, True):
                b = []
                lk = st == "locked"
                if hc:
                    b.append(ring(x, y, w, w, R, TH, K["locked_hc"] if lk else K[hcfill]))
                    if lk:
                        b.append(ring(x, y, w, w, R, TH, stripes(svg, "#000000", 6, 2), ' mask="%s"' % corner_mask(svg, 16)))
                    b.append(rrect(x + 0.5, y + 0.5, w - 1, w - 1, R - 0.5, "none", stroke("#000000", LINE_HC)))
                    b.append(rrect(x + TH - 0.5, y + TH - 0.5, w - 2 * TH + 1, w - 2 * TH + 1, R - TH + 0.5, "none",
                                   stroke("#000000", 2)))
                else:
                    if lk:
                        body = svg.grad([(0, K["frame_locked_light"]), (0.5, K["locked_top"]), (1, K["frame_locked_dark"])])
                    elif rank == "prismatic":
                        body = svg.grad(stops, x2=1, y2=1)
                    else:
                        body = svg.grad(stops)
                    b.append(ring(x, y, w, w, R, TH, body))
                    if rank == "prismatic" and not lk:
                        # A pearl sheen over the hues, so the ring reads as one cut material.
                        b.append(ring(x, y, w, w, R, TH, svg.grad([(0, a("#FFFFFF", 0.5)), (0.45, a("#FFFFFF", 0.1)),
                                                                   (1, a("#000000", 0.15))])))
                    if rank == "oak" and not lk:
                        # Grain along the ring: concentric, so it stretches cleanly.
                        for d, al in ((2.2, 0.5), (3.6, 0.3), (4.6, 0.45)):
                            b.append(rrect(x + d, y + d, w - 2 * d, w - 2 * d, R - d, "none",
                                           stroke(C["oak_grain"], 0.6) + ' stroke-opacity="%s"' % p(al)))
                    if lk:
                        b.append(ring(x, y, w, w, R, TH, stripes(svg, a("#FFFFFF", 0.22)), ' mask="%s"' % corner_mask(svg, 16)))
                    # The bevel: the outer half lit at the top, the inner half shaded at the foot.
                    b.append(top_light(svg, x + 1, y + 1, w - 2, w - 2, R - 1, a("#FFFFFF", 0.8 if not lk else 0.45), 1.5))
                    b.append(foot_shade(svg, x + 1, y + 1, w - 2, w - 2, R - 1, a("#000000", 0.4), 1.5))
                    inner = (x + TH - 1.2, w - 2 * TH + 2.4, R - TH + 1.2)
                    g = svg.grad([(0, a("#000000", 0.45)), (0.5, a("#000000", 0.1)), (1, a("#FFFFFF", 0.35))])
                    b.append(rrect(inner[0], inner[0], inner[1], inner[1], inner[2], "none",
                                   ' stroke="%s" stroke-width="1.2"' % g))
                    if groove:
                        m = TH / 2 + 0.2
                        b.append(rrect(x + m, y + m, w - 2 * m, w - 2 * m, R - m, "none",
                                       stroke(C["silver_ink"] if rank == "silver" else C["ink_line"], 0.8)
                                       + ' stroke-opacity="%s"' % ("0.5" if not lk else "0.35")))
                        b.append(rrect(x + m + 0.8, y + m + 0.8, w - 2 * m - 1.6, w - 2 * m - 1.6, R - m - 0.8, "none",
                                       stroke("#FFFFFF", 0.6) + ' stroke-opacity="0.5"'))
                    b.append(rrect(x, y, w, w, R, "none", ink(C["ink_line"], LINE)))
                    b.append(rrect(x + TH, y + TH, w - 2 * TH, w - 2 * TH, R - TH, "none", ink(C["ink_line"], 1.5)))
                c = TH / 2 + 3.2
                for cx, cy in ((x + c, y + c), (x + w - c, y + c), (x + c, y + w - c), (x + w - c, y + w - c)):
                    if studs == "nail":
                        b += nail(svg, cx, cy, 2.4, hc, lk)
                    elif studs == "rivet":
                        b += rivet(svg, cx, cy, 2.1, hc, lk)
                    elif studs:
                        b += stud(svg, cx, cy, 2.6, hc, lk)
                    if gems:
                        b += gem(svg, cx, cy, 3.4, hc, lk)
                svg.state(st, b, hc=hc)
        out["frame_%s/box.svg" % rank] = svg.text()
    return out


# --- Header and ribbon -------------------------------------------------------

def header():
    """The top bar's band: flush with the top, rounded at its foot, a solid
    lip (E2) under it; the lit card, a thin lit line along the top and a lit
    rim above the foot. Its title is live T2 Marcellus."""
    W, FH, R = 40, 40, 16
    H = FH + DROP_M + 1
    svg = Svg(W, H, [18, 8, 18, 22])
    x, y, w = 1, 0, W - 2
    for hc in (False, True):
        b = []
        if hc:
            b.append(bottom_round(x, y + DROP_M, w, FH, R, "#000000"))
            b.append(bottom_round(x, y, w, FH, R, HC["card_top"]))
            b.append(bottom_round(x + 1.5, y - 2, w - 3, FH + 0.5, R - 1.5, "none", stroke(K["edge_hc"], LINE_HC)))
            svg.state("normal", b, hc=True)
            continue
        b.append(bottom_round(x, y + DROP_M, w, FH, R, a(C["drop"], 0.85), ink(C["ink_deep"], LINE)))
        b.append(bottom_round(x, y, w, FH, R, svg.grad([(0, K["header_top"]), (1, K["header_bottom"])])))
        gl = svg.grad([(0, a("#FFFFFF", 0.1)), (1, a("#FFFFFF", 0))])
        b.append(rrect(x + 2, y + 1, w - 4, 15, 4, gl))
        b.append(rrect(x, y + 1, w, 1.2, 0, a(C["tab_active_top"], 0.45)))
        g = svg.grad([(0, a(C["tab_active_top"], 0)), (0.6, a(C["tab_active_top"], 0)), (1, a(C["tab_active_top"], 0.45))])
        b.append(bottom_round(x + 1.5, y - 2, w - 3, FH + 0.5, R - 1.5, "none", ' stroke="%s" stroke-width="1.5"' % g))
        b.append(bottom_round(x, y - 3, w, FH + 3, R, "none", ink(C["ink_deep"], LINE)))
        svg.state("normal", b)
    out = {"header/box.svg": svg.text()}

    # The name plate (E1): leather, its rim the leather's brass, a gloss band.
    W, FH, R, D = 32, 28, 8, 2
    H = 1 + FH + D + 1
    svg = Svg(W, H, [12, 12, 12, 14])
    x, y, w = 1, 1, W - 2
    for hc in (False, True):
        b = []
        if hc:
            b.append(rrect(x, y + D, w, FH, R, "#000000"))
            b.append(rrect(x, y, w, FH, R, K["leather_hc"]))
            b.append(hc_edge(x, y, w, FH, R, "#000000"))
            svg.state("normal", b, hc=True)
            continue
        b.append(rrect(x, y + D, w, FH, R, C["drop"]))
        b.append(rrect(x, y, w, FH, R, svg.grad([(0, C["leather_light"]), (0.55, C["leather_mid"]), (1, C["leather_dark"])])))
        b.append(rim_ring(x + 1, y + 1, w - 2, FH - 2, R - 1, a(C["leather_rim"], 0.8), 1.5))
        b.append(lit_band(svg, x + 3, y + 3, w - 6, FH, R - 3, 0.14, 10))
        b.append(foot_shade(svg, x + 2.5, y + 2.5, w - 5, FH - 5, R - 2.5, a("#000000", 0.35), 1.5))
        b.append(rrect(x, y, w, FH, R, "none", ink(C["ink_line"], LINE)))
        svg.state("normal", b)
    out["header/name_plate.svg"] = svg.text()
    return out


RW, RB, ROFF, RTAIL = 64, 32, 6, 15  # width, band height, the tails' drop, the tails' reach


def ribbon_shapes():
    """The ribbon's outlines: the band, the two tails behind it (each a
    swallowtail), the two folds where the band turns under."""
    x0, x1 = 10, RW - 10
    y0 = 1
    ty0, ty1 = y0 + ROFF, y0 + ROFF + RB
    n = 5
    lt = "M%s %sH%sV%sH%sL%s %sZ" % (p(1), p(ty0), p(1 + RTAIL), p(ty1), p(1), p(1 + n), p((ty0 + ty1) / 2))
    rt = "M%s %sH%sL%s %sL%s %sH%sZ" % (p(RW - 1), p(ty0), p(RW - 1 - RTAIL), p(RW - 1 - RTAIL), p(ty1),
                                         p(RW - 1), p(ty1), p(RW - 1 - n))
    rt = "M%s %sH%sV%sH%sL%s %sZ" % (p(RW - 1), p(ty0), p(RW - 1 - RTAIL), p(ty1), p(RW - 1), p(RW - 1 - n),
                                      p((ty0 + ty1) / 2))
    lf = "M%s %sH%sV%sZ" % (p(x0), p(y0 + RB), p(1 + RTAIL), p(ty1))
    rf = "M%s %sH%sV%sZ" % (p(x1), p(y0 + RB), p(RW - 1 - RTAIL), p(ty1))
    return (x0, y0, x1 - x0), (lt, rt), (lf, rf)


def ribbon():
    """The ribbon (K19): a band with a swallowtail behind each end, folded
    under. `box` is its neutral ground, tinted per school; `frame` its
    untinted ink, gloss and stitch; `chapter` the same ribbon in violet,
    untinted, for a section title with no school."""
    H = 1 + ROFF + RB + 2 + 1
    sl = [20, 14, 20, H - 14 - 6]
    (bx, by, bw), tails, folds = ribbon_shapes()
    path = lambda d, f, e="": '<path d="%s"%s%s/>' % (d, (' fill="%s"' % f) if f.startswith("url") else col(f), e)

    def ground(svg, hc, top, mid, bottom, tail, fold):
        b = []
        if hc:
            for d in tails + folds:
                b.append(path(d, fold if d in folds else tail))
            b.append(rrect(bx, by, bw, RB, 4, mid))
            return b
        for d in tails:
            b.append(path(d, C["drop"], ' transform="translate(0 2)" fill-opacity="0.7"'))
        b.append(rrect(bx, by + 2, bw, RB, 4, a(C["drop"], 0.7)))
        for d in tails:
            b.append(path(d, svg.grad([(0, tail), (1, fold)])))
        for d in folds:
            b.append(path(d, fold))
        b.append(rrect(bx, by, bw, RB, 4, svg.grad([(0, top), (0.55, mid), (1, bottom)])))
        return b

    def frame(svg, hc):
        b = []
        line = "#000000" if hc else C["ink_line"]
        lw = LINE_HC if hc else LINE
        if not hc:
            b.append(lit_band(svg, bx + 2, by + 2, bw - 4, RB, 3, 0.3, 12))
            b.append(top_light(svg, bx + 1, by + 1, bw - 2, RB - 2, 3, a("#FFFFFF", 0.55), 1.5))
            b.append(foot_shade(svg, bx + 1, by + 1, bw - 2, RB - 2, 3, a("#000000", 0.35), 2))
            # A stitched hem, as a solid groove and its lit line (a stretched
            # dash smears): along the top and the foot.
            for yy, c, al in ((by + 4, "#000000", 0.3), (by + 5, "#FFFFFF", 0.35),
                              (by + RB - 5, "#000000", 0.3), (by + RB - 4, "#FFFFFF", 0.25)):
                b.append(rrect(bx + 3, yy, bw - 6, 0.8, 0, a(c, al)))
            for d in tails:
                b.append(path(d, svg.grad([(0, a("#FFFFFF", 0.18)), (0.5, a("#FFFFFF", 0)), (1, a("#000000", 0.2))])))
        for d in tails + folds:
            b.append(path(d, "none", stroke(line, lw) + ' stroke-linejoin="round"'))
        b.append(rrect(bx, by, bw, RB, 4, "none", stroke(line, lw)))
        return b

    out = {}
    svg = Svg(RW, H, sl)
    for hc in (False, True):
        svg.state("normal", ground(svg, hc, K["school_light"], K["school_mid"], K["school_dark"], K["ribbon_tail"],
                                   K["ribbon_fold"]) if not hc else
                  ground(svg, hc, None, K["ribbon_hc"], None, K["ribbon_hc"], K["ribbon_fold"]), hc=hc)
    out["ribbon/box.svg"] = svg.text().replace("<svg ", '<svg data-tint="true" ', 1)
    svg = Svg(RW, H, sl)
    for hc in (False, True):
        svg.state("normal", frame(svg, hc), hc=hc)
    out["ribbon/frame.svg"] = svg.text()
    svg = Svg(RW, H, sl)
    for hc in (False, True):
        b = ground(svg, hc, C["tab_active_top"], C["tab_active_mid"], C["tab_active_bottom"], K["chapter_tail"],
                   K["chapter_fold"]) if not hc else ground(svg, hc, None, K["violet_hc"], None, K["violet_hc"],
                                                            K["chapter_fold"])
        svg.state("normal", b + frame(svg, hc), hc=hc)
    out["ribbon/chapter.svg"] = svg.text()
    return out


def build_2a(T):
    svgs = {}
    svgs.update(panel_parchment())
    svgs["sheet/box.svg"] = sheet_piece("dark")
    svgs.update(handles())
    svgs.update(popup())
    svgs.update(rank_frames(T))
    svgs.update(header())
    svgs.update(ribbon())
    return svgs
