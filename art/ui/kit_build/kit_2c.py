"""Kit batch 2c: the own-name shapes of seven materials that drew as their
skin's box, and the warn tag redrawn light. Run through build_kit.py (it
imports this module and writes its SVGs with the others).

    panel_dark/album            a Codex chapter's album: a bevelled tan frame round a sunk parchment well, radius 22: normal
    panel_dark/fact             a fact tile, a parchment slip in a tan rim on a tan lip: normal
    panel_dark/plate            a name or level plate, parchment in a gold rim, radius 8: normal
    bar_track/bar_track_light   a progress track on parchment, a sunk tan groove: normal
    tag/tag                     a ribbon tag, cream in a gold rim: normal
    tag/tag_warn                a state tag, warm paper with a hatched orange cap: normal
    tag/island_label            an island's label, a cream pill: normal
    success/banner_success      the raid banner, a deep green card edged and lit green: normal

Each shape has the states listed above and no more; for a state a shape
lacks, the code draws its own box. Sizes follow each material's radius: a
9-slice's corner cells must hold the whole corner.

Two more shapes are drawn here and held back (HELD): pill/pill_gold_edge
(normal, pressed) and success/green_muted (normal, pressed). With them the
atlas needs a fourth page, so until one is allowed they stay out of the
build and the code draws those two materials.

Gold keeps its two roles (kit_2b.py): the ribbon tag's token fill is gold,
and a tag is no action, so it is cream in a gold rim; the warn tag's token
fill is amber, a hue beside gold, so it is a paler warm paper and its cap
says "warn" by shape. Both keep their tokens' dark words.

Batch 2d redrew the album, the fact slip, the plate, the light track and the
banner in place: same names, sizes and slices. A 9-slice's centre is one
stretched sample, so paper grain lives where the cells are fixed (specks in
the corners) or where a mark runs along the stretch (laid lines in the top
and bottom rows); the stretched middle of a large album stays plain paper.
"""

import random

from build_kit import C, HC, K, KIT, LINE, LINE_HC, LIP, TRAVEL, Svg, col, face_layers, hc_set, mat, p, rrect, stroke
from kit_1b import a, cap_mask, foot_shade, hc_edge, ink, lit_band, rim_ring, stripes, top_light
from kit_2a import blur, corner_mask

KIT_2C = {
    "fact_line": ("#C9A876", "material.fact's line #C9A876: the fact tile's soft tan edge"),
    "fact_lip": ("#9A7440", "material.fact's drop, deepened to a solid tan: a 2 point lip reads on cream at phone size"),
    "fact_edge": ("#8F6B3A", "fact_line, deepened: the slip's outer edge, a clear value step off the album's paper"),
    "fact_rim_top": ("#F2DDB0", "fact_line, lit: the top of the slip's rim"),
    "album_frame_top": ("#F3DFB2", "parchment_deckle #C9A86A, lit: the album frame's bevel at its top"),
    "album_frame_mid": ("#D6B67E", "parchment_deckle, a step lighter: the album frame's face"),
    "album_frame_bottom": ("#B08A54", "parchment_deckle, shaded: the album frame's bevel at its foot"),
    "album_well_line": ("#7A5428", "parchment_lip #8A5A1C, deeper: the line where the frame meets the well"),
    "album_well_top": ("#F4E6C6", "parchment_bottom #F1E3C4, a touch lighter: the well's paper under its gloss"),
    "album_well_bottom": ("#EBD9B4", "parchment_bottom, a step down: the well's paper at its foot"),
    "paper_grain": ("#8A5A1C", "parchment_lip #8A5A1C: the paper's specks, fibres and laid lines, drawn faint"),
    "fact_top": ("#FFFDF6", "parchment_top #FFFBF0, lifted: a fact tile sits lighter than its panel"),
    "track_light_top": ("#9C7C4C", "material.bar_track_light's line #B08A58, shaded: the groove's top, well under the cream panel in value"),
    "track_light_bottom": ("#C2A674", "material.bar_track_light's #E0CDA4, two steps down: the groove's foot"),
    "track_light_line": ("#6E4E26", "material.bar_track_light's line #B08A58, deepened: the groove's edge"),
    "track_light_hc": ("#D8D8D8", "pill_hc_pressed: a grey rail, a step off white paper, a white fill reads on it"),
    "warn_paper_top": ("#FFEBCB", "parchment_top toward warn_cap #F07A3C, a step: the warn tag's paper"),
    "warn_paper_bottom": ("#FBD3A0", "parchment_bottom toward warn_cap, a step"),
    "well_top": ("#140A16", "material.pill_gold_edge's text_bg #140A16: the well's top"),
    "well_bottom": ("#24142A", "material.pill_gold_edge's text_bg #24142A: the well's foot"),
    "well_pressed": ("#0C060E", "well_top, pressed in"),
    "banner_lip": ("#0A0618", "material.banner_success's drop #0A0618"),
    "banner_top": ("#2F7A5E", "success #3FBF7F, deep: the banner's face at its top, so a white line's ink outline shows on it"),
    "banner_mid": ("#25634F", "banner_top, a step down"),
    "banner_bottom": ("#1A4A3E", "banner_top, two steps down: the banner's foot"),
    "banner_edge_dark": ("#1E7A50", "success #3FBF7F, shaded: the banner's edge at its foot and when pressed"),
    "banner_pressed_top": ("#1A1238", "card_bottom #1A1134, the pressed banner's top"),
    "banner_pressed_bottom": ("#120B28", "card_bottom, deeper"),
    "banner_disabled": ("#2C2838", "card_top #261A4C, desaturated"),
    "green_muted_top": ("#24604A", "gradient.green_muted's top"),
    "green_muted_bottom": ("#163E30", "gradient.green_muted's foot"),
    "green_muted_pressed_top": ("#1A4A38", "green_muted_top, pressed in"),
    "green_muted_pressed_bottom": ("#103026", "green_muted_bottom, pressed in"),
    "green_muted_lip": ("#0A3A20", "material.green_muted's drop #0A3A20"),
    "green_muted_disabled": ("#3A4A44", "green_muted, desaturated"),
    "green_muted_hc": ("#0F4A2E", "color_high_contrast.success_text #0F4A2E: a deep green, white words on it"),
    "green_muted_hc_pressed": ("#0A3420", "green_muted_hc, pressed in"),
}
KIT.update(KIT_2C)
K.update({k: v[0] for k, v in KIT_2C.items()})


def paper(svg, st, hc, x, y, w, fh, r, line, lw, lip, dh, deckle=False, top=None):
    """A parchment face: a lip `dh` points under it, the paper's gradient, a
    white lit top, a warm foot shade, an optional deckle line, its edge.
    Locked is the paper toward the locked teal, hatched in its corners."""
    b = []
    if hc:
        b.append(rrect(x, y + dh, w, fh, r, "#000000"))
        b.append(rrect(x, y, w, fh, r, HC["paper"]))
        if st == "locked":
            b.append(rrect(x, y, w, fh, r, stripes(svg, K["locked_hc"], 6, 2), ' mask="%s"' % corner_mask(svg, min(r + 1, 17))))
        b.append(hc_edge(x, y, w, fh, r, K["locked_hc"] if st == "locked" else "#000000"))
        return b
    b.append(rrect(x, y + dh, w, fh, r, lip, ink(line, lw)))
    if st == "locked":
        g = svg.grad([(0, K["parchment_locked_top"]), (1, K["parchment_locked_bottom"])])
    else:
        g = svg.grad([(0, top or C["parchment_top"]), (0.5, "#F6EAD0"), (1, C["parchment_bottom"])])
    b.append(rrect(x, y, w, fh, r, g))
    if st == "locked":
        b.append(rrect(x, y, w, fh, r, stripes(svg, a(K["locked_bottom"], 0.3)), ' mask="%s"' % corner_mask(svg, min(r + 1, 17))))
    i = lw / 2
    b.append(top_light(svg, x + i, y + i, w - 2 * i, fh - 2 * i, r - i, a("#FFFFFF", 0.95), 2))
    b.append(foot_shade(svg, x + i, y + i, w - 2 * i, fh - 2 * i, r - i, a(K["fact_line"], 0.55), 2.5))
    if deckle:
        b.append(rrect(x + 4.5, y + 4.5, w - 9, fh - 9, r - 4.5, "none",
                       stroke(K["parchment_deckle"], 1) + ' stroke-opacity="0.7"'))
    b.append(rrect(x, y, w, fh, r, "none", ink(line, lw)))
    return b


def clip(svg, x, y, w, h, r):
    svg.ids += 1
    cid = "c%d" % svg.ids
    svg.defs.append('<clipPath id="%s">%s</clipPath>' % (cid, rrect(x, y, w, h, r, "#FFFFFF")))
    return ' clip-path="url(#%s)"' % cid


def grain(svg, x, y, w, h, c, seed, n):
    """Paper grain for a 9-slice: specks and short fibres in the four fixed
    c-point corners (masked), seeded so the build repeats."""
    rnd = random.Random(seed)
    g = []
    for _ in range(n):
        px, py = x + rnd.random() * w, y + rnd.random() * h
        al = 0.1 + rnd.random() * 0.16
        if rnd.random() < 0.45:
            ln = 1.2 + rnd.random() * 2.4
            dy = (rnd.random() - 0.5) * 0.5
            g.append('<path d="M%s %sl%s %s" stroke="%s" stroke-opacity="%s" stroke-width="0.35" stroke-linecap="round"/>'
                     % (p(px), p(py), p(ln), p(dy), K["paper_grain"], p(al)))
        else:
            g.append('<circle cx="%s" cy="%s" r="%s" fill="%s" fill-opacity="%s"/>'
                     % (p(px), p(py), p(0.18 + rnd.random() * 0.3), K["paper_grain"], p(al)))
    return '<g mask="%s">%s</g>' % (corner_mask(svg, c), "".join(g))


def album(svg, x, y, w, fh, r, dh):
    """The album: a lip, a bevelled tan frame, a sunk well of paper with a
    gloss band under the frame's top, grain, an ink edge."""
    F = 5.5  # the frame's width
    wx, wy, ww, wh, wr = x + F, y + F, w - 2 * F, fh - 2 * F, r - F
    cl = clip(svg, wx, wy, ww, wh, wr)
    b = [rrect(x, y + dh, w, fh, r, C["gold_drop"], ink(C["ink_line"], LINE))]
    # The well's paper.
    b.append(rrect(wx, wy, ww, wh, wr, svg.grad([(0, K["album_well_top"]), (0.5, C["parchment_bottom"]), (1, K["album_well_bottom"])])))
    # Aged edges: the paper warms toward the frame.
    b.append('<g%s>%s</g>' % (cl, rrect(wx, wy, ww, wh, wr, "none", stroke(a(K["album_frame_bottom"], 0.55), 5) + blur(svg, 2.2))))
    # Laid lines, along the stretch, in the fixed top and bottom rows.
    lines = []
    for ly in (wy + 11.5, wy + 14, wy + 16.5, wy + wh - 4.5, wy + wh - 7, wy + wh - 9.5):
        lines.append('<rect x="%s" y="%s" width="%s" height="0.4" fill="%s" fill-opacity="0.2"/>' % (p(wx), p(ly), p(ww), K["paper_grain"]))
    b.append('<g%s>%s</g>' % (cl, "".join(lines)))
    b.append('<g%s>%s</g>' % (cl, grain(svg, wx, wy, ww, wh, 22, 2204, 150)))
    # The gloss band: white, hard-edged, under the frame's top.
    gl = svg.grad([(0, a("#FFFFFF", 0.95)), (1, a("#FFFFFF", 0.7))])
    b.append('<g%s>%s</g>' % (cl, rrect(wx + 2.2, wy + 2.6, ww - 4.4, 6, wr - 2.4, gl)))
    # The well sinks: the frame's shade on its top, a lit foot.
    b.append('<g%s>%s</g>' % (cl, rrect(wx, wy - 0.4, ww, wh, wr, "none", stroke(a(C["gold_drop"], 0.5), 2.6) + blur(svg, 0.9))))
    b.append(foot_shade(svg, wx + 0.4, wy + 0.4, ww - 0.8, wh - 0.8, wr - 0.4, a("#FFFFFF", 0.9), 1.2))
    # The frame: a bevel, lit at its top, dark where it meets the well.
    fg = svg.grad([(0, K["album_frame_top"]), (0.3, K["album_frame_mid"]), (1, K["album_frame_bottom"])])
    b.append(rrect(x + F / 2, y + F / 2, w - F, fh - F, r - F / 2, "none", ' stroke="%s" stroke-width="%s"' % (fg, p(F))))
    b.append(top_light(svg, x + 1, y + 1, w - 2, fh - 2, r - 1, a("#FFFFFF", 0.95), 1.6))
    b.append(foot_shade(svg, x + 1, y + 1, w - 2, fh - 2, r - 1, a(C["gold_drop"], 0.5), 1.6))
    b.append(rrect(x + F - 1.6, y + F - 1.6, w - 2 * F + 3.2, fh - 2 * F + 3.2, wr + 1.6, "none",
                   stroke(a("#FFFFFF", 0.35), 0.8)))
    b.append(rrect(wx, wy, ww, wh, wr, "none", stroke(K["album_well_line"], 1.1)))
    b.append(rrect(x, y, w, fh, r, "none", ink(C["ink_line"], LINE)))
    return b


def slip(svg, x, y, w, fh, r, dh, edge, lw, lip, rim, top, seed):
    """A fact slip or a plate: a solid lip, the paper, a two-tone rim inside
    its edge, a hard gloss band, a foot shade, grain in its corners."""
    b = [rrect(x, y + dh, w, fh, r, lip, ink(edge, lw))]
    b.append(rrect(x, y, w, fh, r, svg.grad([(0, top), (0.45, C["parchment_bottom"]), (1, K["album_well_bottom"])])))
    i = lw / 2 + 1.5  # inside the rim
    cl = clip(svg, x + i, y + i, w - 2 * i, fh - 2 * i, r - i)
    b.append('<g%s>%s</g>' % (cl, grain(svg, x, y, w, fh, r, seed, 40)))
    gl = svg.grad([(0, a("#FFFFFF", 0.98)), (1, a("#FFFFFF", 0.75))])
    b.append('<g%s>%s</g>' % (cl, rrect(x + i + 0.9, y + i + 0.9, w - 2 * i - 1.8, 4.6, r - i - 0.9, gl)))
    b.append(foot_shade(svg, x + i, y + i, w - 2 * i, fh - 2 * i, r - i, a(K["album_frame_bottom"], 0.7), 2.4))
    # The rim: a lit-to-shaded band, a dark hairline inside it.
    rg = svg.grad([(0, rim[0]), (0.5, rim[1]), (1, rim[2])])
    b.append(rrect(x + lw / 2 + 0.7, y + lw / 2 + 0.7, w - lw - 1.4, fh - lw - 1.4, r - lw / 2 - 0.7, "none",
                   ' stroke="%s" stroke-width="1.5"' % rg))
    b.append(rrect(x + i, y + i, w - 2 * i, fh - 2 * i, r - i, "none", stroke(a(rim[3], 0.75), 0.6)))
    b.append(rrect(x, y, w, fh, r, "none", ink(edge, lw)))
    return b


def papers():
    out = {}
    # shape: face height, radius, lip height
    specs = {"album": (48, 22, 4), "fact": (28, 12, 2), "plate": (20, 8, 2)}
    for shape, (fh, r, dh) in specs.items():
        W, H = fh, 1 + fh + dh + 1
        c = r + 1
        svg = Svg(W, H, [c, c, c, c + dh])
        if shape == "album":
            body = album(svg, 1, 1, W - 2, fh, r, dh)
        elif shape == "fact":
            body = slip(svg, 1, 1, W - 2, fh, r, dh, K["fact_edge"], 1.5, K["fact_lip"],
                        (K["fact_rim_top"], K["fact_line"], K["album_frame_bottom"], K["album_well_line"]), K["fact_top"], 2211)
        else:
            body = slip(svg, 1, 1, W - 2, fh, r, dh, C["ink_line"], 1.5, C["gold_drop"],
                        (C["gold_top"], C["gold"], C["gold_bottom"], C["gold_rim"]), C["parchment_top"], 2212)
        svg.state("normal", body)
        line, lw = (C["ink_line"], LINE) if shape == "album" else (C["ink_line"], 1.5)
        svg.state("normal", paper(svg, "normal", True, 1, 1, W - 2, fh, r, line, lw, None, dh), hc=True)
        out["panel_dark/%s.svg" % shape] = svg.text()

    # The island's label: a cream pill.
    FH, DROP, R = 22, 2, 11
    W, H = 28, 1 + FH + DROP + 1
    svg = Svg(W, H, [12, 12, 12, 14])
    for hc in (False, True):
        svg.state("normal", paper(svg, "normal", hc, 1, 1, W - 2, FH, R, C["ink_line"], LINE, C["gold_drop"], DROP), hc=hc)
    out["tag/island_label.svg"] = svg.text()
    return out


def tags():
    out = {}
    FH, DROP, R = 22, 2, 6
    W, H = 24, 1 + FH + DROP + 1
    x, y, w = 1, 1, W - 2
    for shape in ("tag", "tag_warn"):
        svg = Svg(W, H, [8, 8, 8, 10])
        for hc in (False, True):
            b = []
            if hc:
                b.append(rrect(x, y + DROP, w, FH, R, "#000000"))
                b.append(rrect(x, y, w, FH, R, HC["paper"]))
                if shape == "tag_warn":
                    b.append(rrect(x, y, 7, FH, R, K["warn_cap"], ' mask="%s"' % cap_mask(svg, 0, 6)))
                    b.append(rrect(x + 2, y, 4, FH, 0, stripes(svg, "#000000", 4, 1.5)))
                    b.append('<rect x="6" y="1" width="1.5" height="%s" fill="#000000"/>' % p(FH))
                else:
                    # The rim, in high contrast: a second black rule inside the edge.
                    b.append(rrect(x + 4.5, y + 4.5, w - 9, FH - 9, 1.5, "none", stroke("#000000", 1)))
                b.append(hc_edge(x, y, w, FH, R, "#000000"))
                svg.state("normal", b, hc=True)
                continue
            if shape == "tag":
                b.append(rrect(x, y + DROP, w, FH, R, C["gold_drop"], ink(C["ink_line"], 1.5)))
                b.append(rrect(x, y, w, FH, R, svg.grad([(0, C["parchment_top"]), (1, C["parchment_bottom"])])))
                g = svg.grad([(0, C["gold_top"]), (0.5, C["gold"]), (1, C["gold_bottom"])])
                b.append(rrect(x + 1.65, y + 1.65, w - 3.3, FH - 3.3, R - 1.65, "none",
                               ' stroke="%s" stroke-width="1.8"' % g))
                b.append(rrect(x + 2.9, y + 2.9, w - 5.8, FH - 5.8, R - 2.9, "none",
                               stroke(C["gold_rim"], 0.7) + ' stroke-opacity="0.7"'))
                b.append(rrect(x, y, w, FH, R, "none", ink(C["ink_line"], 1.5)))
            else:
                b.append(rrect(x, y + DROP, w, FH, R, a(C["drop"], 0.8)))
                b.append(rrect(x, y, w, FH, R, svg.grad([(0, K["warn_paper_top"]), (1, K["warn_paper_bottom"])])))
                b.append(rrect(x, y, 8, FH, R, svg.grad([(0, "#FFB488"), (1, K["warn_cap"])]),
                               ' mask="%s"' % cap_mask(svg, 0, 6)))
                b.append(rrect(x, y, 6, FH, 0, stripes(svg, a(C["ink_line"], 0.5), 4, 1.5), ' mask="%s"' % cap_mask(svg, 1, 6)))
                b.append('<rect x="6" y="1.5" width="0.75" height="%s" fill="#0A0408" fill-opacity="0.7"/>' % p(FH - 1))
                b.append(top_light(svg, x + 0.5, y + 0.5, w - 1, FH - 1, R - 0.5, a("#FFFFFF", 0.8), 1.2))
                b.append(foot_shade(svg, x + 0.5, y + 0.5, w - 1, FH - 1, R - 0.5, a(K["warn_cap"], 0.45), 1.5))
                b.append(rrect(x, y, w, FH, R, "none", ink(C["ink_line"], 1)))
            svg.state("normal", b)
        out["tag/%s.svg" % shape] = svg.text()
    return out


def track_light():
    TH, R = 12, 6
    W, H = 16, TH + 2
    svg = Svg(W, H, [7, 7, 7, 7])
    x, y, w = 1, 1, W - 2
    b = [rrect(x, y, w, TH, R, svg.grad([(0, K["track_light_top"]), (1, K["track_light_bottom"])])),
         top_light(svg, x + 0.5, y + 0.5, w - 1, TH - 1, R - 0.5, a(C["gold_drop"], 0.7), 2.4),
         foot_shade(svg, x + 0.5, y + 0.5, w - 1, TH - 1, R - 0.5, a("#FFFFFF", 0.55), 1),
         rrect(x, y, w, TH, R, "none", ink(K["track_light_line"], 1))]
    svg.state("normal", b)
    svg.state("normal", [rrect(x, y, w, TH, R, K["track_light_hc"]), hc_edge(x, y, w, TH, R, "#000000", 2)], hc=True)
    return {"bar_track/bar_track_light.svg": svg.text()}


def pill_gold_edge():
    FH, DROP = 36, 2
    W, H = 42, 1 + FH + DROP + 1
    R = FH / 2
    svg = Svg(W, H, [19, 18, 19, 21])
    x, y, w = 1, 1, W - 2
    for st in ("normal", "pressed"):
        fy = y + (DROP if st == "pressed" else 0)
        for hc in (False, True):
            b = []
            if hc:
                if st == "normal":
                    b.append(rrect(x, y + DROP, w, FH, R, "#000000"))
                b.append(rrect(x, fy, w, FH, R, "#000000" if st == "normal" else K["plate_hc"]))
                b.append(hc_edge(x, fy, w, FH, R, K["gold_hc"]))
                svg.state(st, b, hc=True)
                continue
            if st == "normal":
                b.append(rrect(x, y + DROP, w, FH, R, C["drop"], ink(C["ink_line"], 1)))
                b.append(rrect(x, fy, w, FH, R, svg.grad([(0, K["well_top"]), (1, K["well_bottom"])])))
            else:
                b.append(rrect(x, fy, w, FH, R, svg.grad([(0, K["well_pressed"]), (1, K["well_top"])])))
            # The well: shaded under its top edge, lit along its foot.
            b.append(top_light(svg, x + 2.6, fy + 2.6, w - 5.2, FH - 5.2, R - 2.6, a("#000000", 0.75), 2.5))
            b.append(foot_shade(svg, x + 2.6, fy + 2.6, w - 5.2, FH - 5.2, R - 2.6, a("#FFFFFF", 0.14), 1))
            if st == "normal":
                g = svg.grad([(0, C["gold_top"]), (0.5, C["gold"]), (1, C["gold_bottom"])])
            else:
                g = svg.grad([(0, C["gold_bottom"]), (1, C["gold"])])
            b.append(rrect(x + 1.5, fy + 1.5, w - 3, FH - 3, R - 1.5, "none", ' stroke="%s" stroke-width="2"' % g))
            b.append(rrect(x + 2.9, fy + 2.9, w - 5.8, FH - 5.8, R - 2.9, "none",
                           stroke(C["gold_rim"], 0.7) + ' stroke-opacity="0.8"'))
            b.append(rrect(x, fy, w, FH, R, "none", ink(C["ink_line"], 1)))
            svg.state(st, b)
    return {"pill/pill_gold_edge.svg": svg.text()}


def greens():
    """success's two other shapes, at its box's size and slice."""
    out = {}
    W, FACE, R = 38, 42, 16
    H = 1 + FACE + LIP + 1
    sl = [18, 20, 18, 4 + LIP + 16]
    x, y, w = 1, 1, W - 2

    # green_muted: the box's layers in a deep green.
    svg = Svg(W, H, sl)
    hcm = hc_set(K["green_muted_hc"], K["green_muted_hc_pressed"])
    for st in ("normal", "pressed"):
        for hc in (False, True):
            if hc:
                m = dict(hcm[st])
            elif st == "normal":
                m = mat(svg.grad([(0, K["green_muted_top"]), (1, K["green_muted_bottom"])]), rim=("#3FBF7F66", 1.5),
                        highlight=("#8FF0A84D", 2), shade=("#00000040", 3), gloss=0.1, lip=K["green_muted_lip"])
            elif st == "pressed":
                m = mat(svg.grad([(0, K["green_muted_pressed_top"]), (1, K["green_muted_pressed_bottom"])]),
                        rim=("#3FBF7F40", 1.5), shade=("#00000066", 3), lip=K["green_muted_lip"])
            elif st == "disabled":
                m = mat(K["green_muted_disabled"], K["disabled_line"])
            else:
                m = mat(svg.grad([(0, K["locked_top"]), (1, K["locked_bottom"])]), rim=("#FFFFFF26", 1.5),
                        stripes="#FFFFFF29", highlight=("#FFFFFF40", 2), gloss=0.24, lip=C["drop"])
            body = []
            if st == "disabled":
                body += face_layers(svg, m, x, y, w, FACE, R, lit=False)
            else:
                fy = y + (TRAVEL if st == "pressed" else 0)
                body.append(rrect(x, y + LIP, w, FACE, R, m["lip"], stroke(m["line"], m.get("line_w", LINE))))
                body += face_layers(svg, m, x, fy, w, FACE, R, lit=(st != "pressed"))
            svg.state(st, body, hc=hc)
    out["success/green_muted.svg"] = svg.text()

    # banner_success: a deep green card, edged green and lit green inside its edge.
    svg = Svg(W, H, sl)
    for st in ("normal",):
        fy = y + (TRAVEL if st == "pressed" else 0)
        for hc in (False, True):
            b = []
            if hc:
                fill = {"normal": HC["card_top"], "pressed": K["plate_hc"], "disabled": K["disabled_hc"],
                        "locked": HC["card_top"]}[st]
                edge = {"normal": K["green_hc"], "pressed": K["green_hc"], "disabled": "#000000",
                        "locked": K["locked_hc"]}[st]
                if st != "disabled":
                    b.append(rrect(x, y + LIP, w, FACE, R, "#000000"))
                b.append(rrect(x, fy, w, FACE, R, fill))
                if st == "locked":
                    b.append(rrect(x, fy, w, FACE, R, stripes(svg, K["locked_hc"], 6, 2), ' mask="%s"' % cap_mask(svg, 0, 12)))
                b.append(hc_edge(x, fy, w, FACE, R, edge))
                svg.state(st, b, hc=True)
                continue
            if st == "disabled":
                b.append(rrect(x, y, w, FACE, R, K["banner_disabled"]))
                b.append(rrect(x, y, w, FACE, R, "none", stroke(K["disabled_line"], LINE)))
                svg.state(st, b)
                continue
            b.append(rrect(x, y + LIP, w, FACE, R, K["banner_lip"], stroke(C["ink_line"], LINE)))
            if st == "normal":
                b.append(rrect(x, fy, w, FACE, R, svg.grad([(0, K["banner_top"]), (0.5, K["banner_mid"]), (1, K["banner_bottom"])])))
            elif st == "pressed":
                b.append(rrect(x, fy, w, FACE, R, svg.grad([(0, K["banner_pressed_top"]), (1, K["banner_pressed_bottom"])])))
            else:
                b.append(rrect(x, fy, w, FACE, R, svg.grad([(0, K["card_locked_top"]), (1, K["card_locked_bottom"])])))
                b.append(rrect(x, fy, w, FACE, R, stripes(svg, a(K["locked_top"], 0.45)), ' mask="%s"' % cap_mask(svg, 0, 13)))
            if st == "locked":
                b.append(top_light(svg, x + 1, fy + 1, w - 2, FACE - 2, R - 1, a(K["locked_top"], 0.55), 1.5))
                b.append(rrect(x, fy, w, FACE, R, "none", ink(C["ink_deep"], LINE)))
                svg.state(st, b)
                continue
            # The glow inside the edge: one blurred ring, a smooth ramp inward.
            k = 0.6 if st == "pressed" else 1
            b.append('<g%s>%s</g>' % (clip(svg, x, fy, w, FACE, R),
                                      rrect(x + 1, fy + 1, w - 2, FACE - 2, R - 1, "none",
                                            stroke(a(C["success_light"], 0.6 * k), 4.5) + blur(svg, 2.4))))
            if st == "normal":
                b.append(lit_band(svg, x + 3, fy + 2.5, w - 6, FACE, R - 3, 0.08, 18.5))
                g = svg.grad([(0, C["success_light"]), (0.4, C["success"]), (1, K["banner_edge_dark"])])
            else:
                b.append(top_light(svg, x + 2, fy + 2, w - 4, FACE - 4, R - 2, a("#000000", 0.4), 2.5))
                g = svg.grad([(0, K["banner_edge_dark"]), (1, C["success"])])
            b.append(rrect(x + 0.25, fy + 0.25, w - 0.5, FACE - 0.5, R - 0.25, "none", ' stroke="%s" stroke-width="2.5"' % g))
            b.append(rrect(x - 0.5, fy - 0.5, w + 1, FACE + 1, R + 0.5, "none", ink(C["ink_line"], 1)))
            svg.state(st, b)
    out["success/banner_success.svg"] = svg.text()
    return out


# Drawn, and kept out of the build while the atlas is held to three pages.
HELD = ("pill/pill_gold_edge.svg", "success/green_muted.svg")


def build_2c(T):
    svgs = {}
    svgs.update(papers())
    svgs.update(tags())
    svgs.update(track_light())
    svgs.update(pill_gold_edge())
    svgs.update(greens())
    for name in HELD:
        del svgs[name]
    return svgs
