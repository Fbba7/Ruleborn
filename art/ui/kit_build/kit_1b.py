"""The kit's batch 1b sources (kit-spec.md sections 3, 4, 5 and 8.2): the
heist's other families and the overlays. Called by build_kit.py; not run on
its own.

Gold keeps one role here: a material, as a rim or an edge (the pill's gold
edge, glass's rim, the selected rim). No piece in this batch has a gold fill:
the main action is batch 1a's. Each family's own states stay in its own hue
(a pressed disc is a darker violet, never another colour).

Pieces, by skin (shapes are the material names KitSkin.piece looks up, or
`box`, the skin's fallback):

    panel_dark/box        card (E2): normal, locked
    panel_glass/box       glass over the world: normal
    well/box              a sunken well (E0): normal
    badge/box             the count badge (E1, 22 high): normal
    badge/dot             the attention dot (a sprite): normal
    pill/box              the currency pill (E1, 36 high, gold edge): normal, pressed
    tag/box               the dark plate (E1, 22 high): normal
    tag/tag_violet        violet: normal
    tag/tag_warn          the dark plate with a hatched orange cap: normal
    bar_track/box         the track (E0, 12 high): normal
    bar_track/tick        a tick on the track (a sprite): normal
    bar_fill/box          a neutral fill, tinted per use (band, school): normal
    bar_fill/alarm        the alarm fill, its leading cap hatched: normal
    disc/box              the violet disc (48, E2): normal, pressed, disabled, locked
    disc/level_disc       the plate disc (48, E1): normal
    disc_school/box       the neutral school ground, tinted: normal, pressed, disabled
    disc_school/frame     the disc's untinted ink, rim and gloss: normal, pressed, disabled
    locked/lock           the lock mark overlay (a sprite)
    selected/rim          the selected rim overlay (9-slice, radius 16)
    spinner/ring          the loading spinner (a sprite, rotated by the code)
"""

from build_kit import C, HC, K, KIT, LINE, LINE_HC, TRAVEL, Svg, col, p, rrect, stroke

# The colours this batch adds; each says what it comes from.
KIT_1B = {
    "edge_hc": ("#B8A8D8", "text_on_night_3: a dark piece's 3-point edge in high contrast, 7:1 on the hc night"),
    "plate_hc": ("#2A2060", "gradient.plate_dark's top, flat"),
    "card_locked_top": ("#22303E", "card #261A4C toward locked teal #3A8A90, a step"),
    "card_locked_bottom": ("#16202C", "card #1A1134 toward locked teal, a step"),
    "disc_lip": ("#2A1E7A", "tab_active_bottom #4532B8, deeper: the violet disc's lip"),
    "disc_pressed_top": ("#7A8AE6", "tab_active_top x0.86"),
    "disc_pressed_mid": ("#5848D2", "tab_active_mid x0.86"),
    "disc_pressed_bottom": ("#3A2A9E", "tab_active_bottom x0.86"),
    "school_light": ("#FFFFFF", "neutral, tinted: the ground's lit top becomes the school colour"),
    "school_mid": ("#D2D2D2", "neutral, tinted: the ground's body, a step under the school colour"),
    "school_dark": ("#8E8E8E", "neutral, tinted: the ground's foot"),
    "school_lip": ("#4A4A4A", "neutral, tinted: the lip, the school colour's deep shade"),
    "school_pressed": ("#B4B4B4", "school_mid, darker: pressed"),
    "school_disabled": ("#8A8A8A", "neutral, flat: the tint comes out muted"),
    "bar_neutral_top": ("#FFFFFF", "neutral, tinted: a bar's lit top"),
    "bar_neutral_bottom": ("#B4B4B4", "neutral, tinted: a bar's foot"),
    "warn_cap": ("#F07A3C", "energy: tag_warn's cap (not amber, so gold keeps one role)"),
    "lock_light": ("#F3EEFF", "text_on_night: the lock mark's body"),
    "lock_shade": ("#B8A8D8", "text_on_night_3: the lock mark's shaded side and shackle"),
}
KIT.update(KIT_1B)
K.update({k: v[0] for k, v in KIT_1B.items()})


def a(c, alpha):
    """Colour c at alpha (0 to 1) as #RRGGBBAA."""
    return c[:7] + "%02X" % round(alpha * 255)


def circle(cx, cy, r, fill="none", extra=""):
    return '<circle cx="%s" cy="%s" r="%s"%s%s/>' % (
        p(cx), p(cy), p(r), (' fill="%s"' % fill) if fill.startswith("url") or fill == "none" else col(fill), extra)


def ink(c=None, w=LINE):
    return stroke(c or C["ink_line"], w)


def lit_band(svg, x, y, w, h, r, alpha, edge):
    """A gloss band from the face's top to `edge` points down, brighter at the
    left (light from the top left), fading downward."""
    g = svg.grad([(0, a("#FFFFFF", alpha)), (0.7, a("#FFFFFF", alpha * 0.45)), (1, a("#FFFFFF", alpha * 0.2))])
    return rrect(x, y, w, edge, r, g)


def rim_ring(x, y, w, h, r, c, wd):
    return rrect(x + wd / 2, y + wd / 2, w - wd, h - wd, max(r - wd / 2, 0.5), "none", stroke(c, wd))


def top_light(svg, x, y, w, h, r, c, wd):
    """An inner rim lit at the top, gone by the middle."""
    g = svg.grad([(0, c), (0.45, c[:7] + "00"), (1, c[:7] + "00")])
    return rrect(x + wd / 2, y + wd / 2, w - wd, h - wd, max(r - wd / 2, 0.5), "none",
                 ' stroke="%s" stroke-width="%s"' % (g, p(wd)))


def foot_shade(svg, x, y, w, h, r, c, wd):
    """An inner rim darkened at the foot."""
    g = svg.grad([(0, c[:7] + "00"), (0.55, c[:7] + "00"), (1, c)])
    return rrect(x + wd / 2, y + wd / 2, w - wd, h - wd, max(r - wd / 2, 0.5), "none",
                 ' stroke="%s" stroke-width="%s"' % (g, p(wd)))


def hc_edge(x, y, w, h, r, c, wd=LINE_HC):
    """A high-contrast edge, inset so all of its width shows."""
    return rrect(x + wd / 2 - 0.5, y + wd / 2 - 0.5, w - wd + 1, h - wd + 1, max(r - wd / 2, 0.5), "none", stroke(c, wd))


def cap_mask(svg, x0, x1):
    """A mask keeping only x0..x1 (a fixed 9-slice column)."""
    svg.ids += 1
    mid = "m%d" % svg.ids
    svg.defs.append('<mask id="%s" maskUnits="userSpaceOnUse" x="0" y="0" width="%s" height="%s">'
                    '<rect x="%s" y="0" width="%s" height="%s" fill="#FFFFFF"/></mask>'
                    % (mid, p(svg.w), p(svg.h), p(x0), p(x1 - x0), p(svg.h)))
    return "url(#%s)" % mid


def stripes(svg, colour, period=6, bar=2.5):
    svg.ids += 1
    pid = "s%d" % svg.ids
    svg.defs.append('<pattern id="%s" width="%s" height="%s" patternUnits="userSpaceOnUse" '
                    'patternTransform="rotate(45)"><rect width="%s" height="%s"%s/></pattern>'
                    % (pid, p(period), p(period), p(bar), p(period), col(colour)))
    return "url(#%s)" % pid


# --- Panels ------------------------------------------------------------------

def panel_dark():
    """The dark card (panel_dark: card, album, fact, plate, ...), E2. Its gloss
    band ends in the 9-slice's middle row, so on a tall card the band covers
    the card's top half instead of a fixed strip."""
    W, FH, DROP, R = 40, 40, S_DROP_M, 16
    H = 1 + FH + DROP + 1
    svg = Svg(W, H, [18, 18, 18, 22])
    x, y, w = 1, 1, W - 2
    for st in ("normal", "locked"):
        for hc in (False, True):
            b = []
            if hc:
                b.append(rrect(x, y + DROP, w, FH, R, "#000000"))
                b.append(rrect(x, y, w, FH, R, HC["card_top"]))
                if st == "locked":
                    b.append(rrect(x, y, w, FH, R, stripes(svg, a(K["locked_hc"], 1), 6, 2), ' mask="%s"' % cap_mask(svg, 0, 12)))
                b.append(hc_edge(x, y, w, FH, R, K["locked_hc"] if st == "locked" else K["edge_hc"]))
                svg.state(st, b, hc=True)
                continue
            b.append(rrect(x, y + DROP, w, FH, R, a(C["drop"], 0.75)))
            if st == "normal":
                b.append(rrect(x, y, w, FH, R, svg.grad([(0, C["card_lit_mid"]), (0.5, C["card_top"]), (1, C["card_bottom"])])))
            else:
                b.append(rrect(x, y, w, FH, R, svg.grad([(0, K["card_locked_top"]), (1, K["card_locked_bottom"])])))
                # Hatched left cap, the locked material's mark; the lock overlay sits on top.
                b.append(rrect(x, y, w, FH, R, stripes(svg, a(K["locked_top"], 0.45)), ' mask="%s"' % cap_mask(svg, 0, 13)))
            b.append(lit_band(svg, x + 3, y + 2.5, w - 6, FH, R - 3, 0.09, 18.5))
            b.append(rim_ring(x + 1, y + 1, w - 2, FH - 2, R - 1, a("#FFFFFF", 0.07), 1.5))
            b.append(top_light(svg, x + 1, y + 1, w - 2, FH - 2, R - 1,
                               a(K["locked_top"], 0.55) if st == "locked" else a(C["tab_active_top"], 0.35), 1.5))
            b.append(foot_shade(svg, x + 1, y + 1, w - 2, FH - 2, R - 1, a("#000000", 0.35), 2.5))
            b.append(rrect(x, y, w, FH, R, "none", ink(C["ink_deep"], 1.5)))
            svg.state(st, b)
    return svg.text()


def panel_glass():
    """Glass over the world (panel_glass: glass, field_glass, tag_dark): the
    token's smoked fill, a lit top, a thin gold rim (gold as a material)."""
    W, FH, DROP, R = 34, 32, 2, 12
    H = 1 + FH + DROP + 1
    svg = Svg(W, H, [14, 14, 14, 16])
    x, y, w = 1, 1, W - 2
    for hc in (False, True):
        b = []
        if hc:
            b.append(rrect(x, y + DROP, w, FH, R, "#000000"))
            b.append(rrect(x, y, w, FH, R, HC["glass"]))
            b.append(hc_edge(x, y, w, FH, R, K["edge_hc"]))
            svg.state("normal", b, hc=True)
            continue
        b.append(rrect(x, y + DROP, w, FH, R, a(C["drop"], 0.35)))
        b.append(rrect(x, y, w, FH, R, C["glass"]))
        b.append(lit_band(svg, x + 2, y + 2, w - 4, FH, R - 2, 0.12, 12))
        b.append(rim_ring(x + 0.75, y + 0.75, w - 1.5, FH - 1.5, R - 0.75, a(C["gold"], 0.45), 1.5))
        b.append(top_light(svg, x + 2.5, y + 2.5, w - 5, FH - 5, R - 2.5, a("#FFFFFF", 0.22), 1))
        b.append(rrect(x, y, w, FH, R, "none", ink(a(C["drop"], 0.6), 1)))
        svg.state("normal", b)
    return svg.text()


def well():
    """A sunken well (E0): the token's fill, shadowed under its top lip, lit
    along its foot; no ink edge."""
    W, H, R = 32, 32, 14
    svg = Svg(W, H, [15, 15, 15, 15])
    x, y, w, h = 1, 1, W - 2, H - 2
    for hc in (False, True):
        b = []
        if hc:
            b.append(rrect(x, y, w, h, R, "#000000"))
            b.append(hc_edge(x, y, w, h, R, K["edge_hc"]))
            svg.state("normal", b, hc=True)
            continue
        b.append(rrect(x, y, w, h, R, "#06031066"))
        g = svg.grad([(0, a("#000000", 0.55)), (0.3, a("#000000", 0.0)), (1, a("#000000", 0))])
        b.append(rrect(x, y, w, h, R, g))
        b.append(top_light(svg, x, y, w, h, R, a("#000000", 0.6), 2.5))
        b.append(foot_shade(svg, x, y, w, h, R, a("#FFFFFF", 0.14), 1.25))
        svg.state("normal", b)
    return svg.text()


# --- Badge, pill and tags --------------------------------------------------

def badge():
    """The count badge (K27; badge_points 22 high, E1) and the attention dot."""
    out = {}
    D, DROP = 22, 2
    W, H = D + 2, D + DROP + 2
    svg = Svg(W, H, [11, 11, 11, 13])
    x, y, w, r = 1, 1, D, D / 2
    for hc in (False, True):
        b = []
        if hc:
            b.append(rrect(x, y + DROP, w, D, r, "#000000"))
            b.append(rrect(x, y, w, D, r, HC["alarm_fill"]))
            b.append(rim_ring(x + 2.5, y + 2.5, w - 5, D - 5, r - 2.5, HC["paper"], 1.5))
            b.append(hc_edge(x, y, w, D, r, "#000000"))
            svg.state("normal", b, hc=True)
            continue
        b.append(rrect(x, y + DROP, w, D, r, C["drop"]))
        b.append(rrect(x, y, w, D, r, svg.grad([(0, C["alarm"]), (0.45, C["red_deep"]), (1, C["alarm_text"])])))
        b.append(lit_band(svg, x + 3, y + 1.5, w - 6, 7, 3.5, 0.32, 7))
        b.append(top_light(svg, x + 1, y + 1, w - 2, D - 2, r - 1, a(C["alarm_light"], 0.8), 1.5))
        b.append(rrect(x, y, w, D, r, "none", ink(C["ink_line"], LINE)))
        svg.state("normal", b)
    out["badge/box.svg"] = svg.text()

    # The dot: a sprite, with a paper rim so it separates from any ground.
    D2 = 14
    W2, H2 = D2 + 2, D2 + 2 + 2
    svg = Svg(W2, H2, None)
    cx, cy, r = W2 / 2, 1 + D2 / 2, D2 / 2
    for hc in (False, True):
        b = []
        if hc:
            b.append(circle(cx, cy + 2, r, "#000000"))
            b.append(circle(cx, cy, r, HC["alarm_fill"]))
            b.append(circle(cx, cy, r - 2.5, "none", stroke(HC["paper"], 2)))
            b.append(circle(cx, cy, r - 0.75, "none", stroke("#000000", 1.5)))
            svg.state("normal", b, hc=True)
            continue
        b.append(circle(cx, cy + 2, r, C["drop"]))
        b.append(circle(cx, cy, r, svg.grad([(0, C["alarm_light"]), (0.5, C["alarm"]), (1, C["red_deep"])], radial=(0.4, 0.3, 0.8))))
        b.append(circle(cx, cy, r - 1.75, "none", stroke(C["on_alarm"], 1.5)))
        b.append('<ellipse cx="%s" cy="%s" rx="2.2" ry="1.4" fill="#FFFFFF" fill-opacity="0.7"/>' % (p(cx - 1.8), p(cy - 2.4)))
        b.append(circle(cx, cy, r, "none", ink(C["ink_line"], 1.5)))
        svg.state("normal", b)
    out["badge/dot.svg"] = svg.text()
    return out


def pill():
    """The currency pill (K23; pill_points 36, E1): the dark track with the
    token's gold edge (gold as a material, never a fill)."""
    FH, DROP = 36, 2
    W, H = 42, 1 + FH + DROP + 1
    R = FH / 2
    svg = Svg(W, H, [19, 18, 19, 21])
    x, y, w = 1, 1, W - 2
    track = [(0, "#140A16"), (1, "#24142A")]
    for st in ("normal", "pressed"):
        fy = y + (DROP if st == "pressed" else 0)
        for hc in (False, True):
            b = []
            if hc:
                if st == "normal":
                    b.append(rrect(x, y + DROP, w, FH, R, "#000000"))
                b.append(rrect(x, fy, w, FH, R, HC["glass"] if st == "normal" else "#000000"))
                b.append(hc_edge(x, fy, w, FH, R, K["edge_hc"]))
                svg.state(st, b, hc=True)
                continue
            if st == "normal":
                b.append(rrect(x, y + DROP, w, FH, R, C["drop"]))
            b.append(rrect(x, fy, w, FH, R, svg.grad(track if st == "normal" else track[::-1])))
            if st == "normal":
                b.append(lit_band(svg, x + 4, fy + 2.5, w - 8, FH, R - 3, 0.1, 13))
            b.append(rim_ring(x + 1, fy + 1, w - 2, FH - 2, R - 1, a(C["gold"], 0.9 if st == "normal" else 0.6), 1.5))
            if st == "normal":
                b.append(top_light(svg, x + 2.5, fy + 2.5, w - 5, FH - 5, R - 2.5, a(C["gold_top"], 0.45), 1))
            else:
                b.append(top_light(svg, x + 2.5, fy + 2.5, w - 5, FH - 5, R - 2.5, a("#000000", 0.5), 2))
            b.append(rrect(x, fy, w, FH, R, "none", ink(C["ink_line"], 1.5)))
            svg.state(st, b)
    return svg.text()


def tags():
    """Tags (badge_points 22 high, E1, radius 6): the dark plate, violet, and
    warn (the dark plate with a hatched orange cap, its shape mark)."""
    out = {}
    FH, DROP, R = 22, 2, 6
    W, H = 24, 1 + FH + DROP + 1
    plate = [(0, "#2A2060"), (1, "#140C34")]
    violet = [(0, "#6A55D0"), (1, "#4E3BAE")]
    for shape in ("box", "tag_violet", "tag_warn"):
        svg = Svg(W, H, [8, 8, 8, 10])
        x, y, w = 1, 1, W - 2
        for hc in (False, True):
            b = []
            if hc:
                b.append(rrect(x, y + DROP, w, FH, R, "#000000"))
                b.append(rrect(x, y, w, FH, R, K["violet_hc"] if shape == "tag_violet" else K["plate_hc"]))
                if shape == "tag_warn":
                    b.append(rrect(x, y, 7, FH, R, K["warn_cap"], ' mask="%s"' % cap_mask(svg, 0, 6)))
                    b.append(rrect(x + 2, y, 4, FH, 0, stripes(svg, "#000000", 4, 1.5)))
                b.append(hc_edge(x, y, w, FH, R, K["edge_hc"]))
                svg.state("normal", b, hc=True)
                continue
            b.append(rrect(x, y + DROP, w, FH, R, a(C["drop"], 0.8)))
            b.append(rrect(x, y, w, FH, R, svg.grad(violet if shape == "tag_violet" else plate)))
            if shape == "tag_warn":
                b.append(rrect(x, y, 8, FH, R, svg.grad([(0, "#FFB488"), (1, K["warn_cap"])]),
                               ' mask="%s"' % cap_mask(svg, 0, 6)))
                b.append(rrect(x, y, 6, FH, 0, stripes(svg, a(C["ink_line"], 0.45), 4, 1.5), ' mask="%s"' % cap_mask(svg, 1, 6)))
                b.append('<rect x="6" y="1.5" width="0.75" height="%s" fill="#0A0408" fill-opacity="0.6"/>' % p(FH - 1))
            b.append(lit_band(svg, x + 2, y + 1.5, w - 4, FH, R - 1.5, 0.16 if shape == "tag_violet" else 0.1, 8))
            b.append(top_light(svg, x + 1, y + 1, w - 2, FH - 2, R - 1,
                               a("#FFFFFF", 0.35 if shape == "tag_violet" else 0.18), 1))
            b.append(rrect(x, y, w, FH, R, "none", ink(C["ink_line"], 1)))
            svg.state("normal", b)
        out["tag/%s.svg" % shape] = svg.text()
    return out


# --- Bars ----------------------------------------------------------------------

def bars():
    """The bar's track (bar_points 12, E0), a tick on it, and its fills: a
    neutral one the code tints (bands, schools, progress) and the alarm's,
    whose leading cap is hatched so it is not told apart by hue alone."""
    out = {}
    TH, R = 12, 6
    W, H = 16, TH + 2
    svg = Svg(W, H, [7, 7, 7, 7])
    x, y, w = 1, 1, W - 2
    for hc in (False, True):
        b = []
        if hc:
            b.append(rrect(x, y, w, TH, R, "#000000"))
            b.append(hc_edge(x, y, w, TH, R, K["edge_hc"]))
            svg.state("normal", b, hc=True)
            continue
        b.append(rrect(x, y, w, TH, R, svg.grad([(0, "#0A050C"), (1, "#24142A")])))
        b.append(top_light(svg, x + 0.5, y + 0.5, w - 1, TH - 1, R - 0.5, a("#000000", 0.7), 2))
        b.append(foot_shade(svg, x + 0.5, y + 0.5, w - 1, TH - 1, R - 0.5, a("#FFFFFF", 0.16), 1))
        b.append(rrect(x, y, w, TH, R, "none", ink(C["ink_line"], 1)))
        svg.state("normal", b)
    out["bar_track/box.svg"] = svg.text()

    svg = Svg(3, 14, None)
    svg.state("normal", ['<rect x="1" y="2" width="1" height="10" fill="#0A0408" fill-opacity="0.75"/>',
                         '<rect x="2" y="2" width="0.5" height="10" fill="#FFFFFF" fill-opacity="0.3"/>'])
    svg.state("normal", ['<rect x="0.75" y="1" width="1.5" height="12" fill="%s"/>' % K["edge_hc"]], hc=True)
    out["bar_track/tick.svg"] = svg.text()

    FH, R = 8, 4
    W, H = 12, FH + 2
    for shape in ("box", "alarm"):
        svg = Svg(W, H, [5, 5, 5, 5])
        x, y, w = 1, 1, W - 2
        for hc in (False, True):
            b = []
            if hc:
                b.append(rrect(x, y, w, FH, R, "#FFFFFF" if shape == "box" else HC["alarm_fill"]))
                if shape == "alarm":
                    b.append(rrect(x, y, w, FH, R, stripes(svg, HC["paper"], 3, 1.25), ' mask="%s"' % cap_mask(svg, 7, 12)))
                b.append(rrect(x + 0.5, y + 0.5, w - 1, FH - 1, R - 0.5, "none", stroke("#000000", 1.5)))
                svg.state("normal", b, hc=True)
                continue
            if shape == "box":
                b.append(rrect(x, y, w, FH, R, svg.grad([(0, K["bar_neutral_top"]), (0.5, "#E0E0E0"), (1, K["bar_neutral_bottom"])])))
            else:
                b.append(rrect(x, y, w, FH, R, svg.grad([(0, C["alarm_light"]), (0.5, C["alarm"]), (1, C["alarm_fill"])])))
                b.append(rrect(x, y, w, FH, R, stripes(svg, a(C["ink_line"], 0.5), 3, 1.25), ' mask="%s"' % cap_mask(svg, 7, 12)))
            b.append(rrect(x + 1.5, y + 1, w - 3, 2.25, 1.1, "#FFFFFF66"))
            b.append(rrect(x, y, w, FH, R, "none", ink(C["ink_line"], 1)))
            svg.state("normal", b)
        text = svg.text()
        if shape == "box":
            text = text.replace("<svg ", '<svg data-tint="true" ', 1)
        out["bar_fill/%s.svg" % shape] = text
    return out


# --- Discs ---------------------------------------------------------------------

D = 48
D_LIP = 4


def disc():
    """The violet disc (disc: disc, icon_disc, gem, round_sky, round_violet;
    48, E2, a sprite) in four states, and the plate disc (level_disc, E1)."""
    out = {}
    W, H = D + 2, 1 + D + D_LIP + 1
    cx, cy, r = W / 2, 1 + D / 2, D / 2
    svg = Svg(W, H, None)
    norm = [(0, C["tab_active_top"]), (0.5, C["tab_active_mid"]), (1, C["tab_active_bottom"])]
    pres = [(0, K["disc_pressed_top"]), (0.5, K["disc_pressed_mid"]), (1, K["disc_pressed_bottom"])]
    for st in ("normal", "pressed", "disabled", "locked"):
        fy = cy + (TRAVEL if st == "pressed" else 0)
        for hc in (False, True):
            b = []
            if hc:
                fill = {"normal": K["violet_hc"], "pressed": K["violet_hc_pressed"],
                        "disabled": K["disabled_hc"], "locked": K["locked_hc"]}[st]
                if st != "disabled":
                    b.append(circle(cx, cy + D_LIP, r - 0.5, "#000000"))
                b.append(circle(cx, fy, r - 0.5, fill))
                b.append(circle(cx, fy, r - 1.5, "none", stroke("#000000", LINE_HC)))
                svg.state(st, b, hc=True)
                continue
            if st == "disabled":
                b.append(circle(cx, cy, r - 0.5, K["violet_disabled"], ink(K["disabled_line"], LINE)))
                svg.state(st, b)
                continue
            b.append(circle(cx, cy + D_LIP, r - 0.5, K["disc_lip"], ink(C["ink_line"], 1.5)))
            if st == "locked":
                b.append(circle(cx, fy, r - 0.5, svg.grad([(0, K["locked_top"]), (1, K["locked_bottom"])])))
                b.append(circle(cx, fy, r - 0.5, stripes(svg, a("#FFFFFF", 0.16))))
                b.append(circle(cx, fy, r - 2.5, "none", stroke(a("#FFFFFF", 0.2), 1.5)))
            else:
                b.append(circle(cx, fy, r - 0.5, svg.grad(norm if st == "normal" else pres, radial=(0.42, 0.22, 0.9))))
                b.append(circle(cx, fy, r - 2.25, "none", ' stroke="%s" stroke-width="2"' % svg.grad(
                    [(0, a("#FFFFFF", 0.55 if st == "normal" else 0.2)), (0.5, a("#FFFFFF", 0)), (1, a("#000000", 0.35))])))
            if st == "normal":
                g = svg.grad([(0, a("#FFFFFF", 0.42)), (1, a("#FFFFFF", 0))])
                b.append('<ellipse cx="%s" cy="%s" rx="%s" ry="%s" fill="%s"/>' % (
                    p(cx - 4), p(fy - r * 0.48), p(r * 0.56), p(r * 0.3), g))
            b.append(circle(cx, fy, r - 0.5, "none", ink(C["ink_line"], 1.5)))
            svg.state(st, b)
    out["disc/box.svg"] = svg.text()

    W, H = D + 2, 1 + D + 2 + 1
    cx, cy, r = W / 2, 1 + D / 2, D / 2
    svg = Svg(W, H, None)
    for hc in (False, True):
        b = []
        if hc:
            b.append(circle(cx, cy + 2, r - 0.5, "#000000"))
            b.append(circle(cx, cy, r - 0.5, K["plate_hc"]))
            b.append(circle(cx, cy, r - 2, "none", stroke(K["edge_hc"], LINE_HC)))
            svg.state("normal", b, hc=True)
            continue
        b.append(circle(cx, cy + 2, r - 0.5, C["drop"]))
        b.append(circle(cx, cy, r - 0.5, svg.grad([(0, "#3A2C80"), (0.5, "#2A2060"), (1, "#140C34")], radial=(0.42, 0.22, 0.9))))
        b.append(circle(cx, cy, r - 3, "none", stroke(a(C["tab_active_top"], 0.5), 1.5)))
        b.append(circle(cx, cy, r - 1.5, "none", ' stroke="%s" stroke-width="2"' % svg.grad(
            [(0, a("#FFFFFF", 0.3)), (0.5, a("#FFFFFF", 0)), (1, a("#000000", 0.45))])))
        b.append(circle(cx, cy, r - 0.5, "none", ink(C["ink_line"], 1.5)))
        svg.state("normal", b)
    out["disc/level_disc.svg"] = svg.text()
    return out


def disc_school():
    """The school disc (disc_school: portrait_*, ring_*, window_*): a neutral
    ground the code tints by vertex colour, and an untinted frame (ink, rim,
    gloss) drawn over it (kit-spec.md section 4). Same size and lip as
    disc/box, so the two pieces stack."""
    out = {}
    W, H = D + 2, 1 + D + D_LIP + 1
    cx, cy, r = W / 2, 1 + D / 2, D / 2
    states = ("normal", "pressed", "disabled")

    svg = Svg(W, H, None)
    for st in states:
        fy = cy + (TRAVEL if st == "pressed" else 0)
        for hc in (False, True):
            b = []
            if st != "disabled":
                b.append(circle(cx, cy + D_LIP, r - 0.5, "#707070" if hc else K["school_lip"]))
            if hc:
                b.append(circle(cx, fy, r - 0.5, {"normal": "#FFFFFF", "pressed": "#D0D0D0", "disabled": "#9A9A9A"}[st]))
            elif st == "disabled":
                b.append(circle(cx, fy, r - 0.5, K["school_disabled"]))
            else:
                top = K["school_light"] if st == "normal" else K["school_mid"]
                mid = K["school_mid"] if st == "normal" else K["school_pressed"]
                b.append(circle(cx, fy, r - 0.5, svg.grad([(0, top), (0.55, mid), (1, K["school_dark"])], radial=(0.42, 0.22, 0.95))))
            svg.state(st, b, hc=hc)
    out["disc_school/box.svg"] = svg.text().replace("<svg ", '<svg data-tint="true" ', 1)

    svg = Svg(W, H, None)
    for st in states:
        fy = cy + (TRAVEL if st == "pressed" else 0)
        for hc in (False, True):
            b = []
            if hc:
                if st != "disabled":
                    b.append(circle(cx, cy + D_LIP, r - 0.5, "none", stroke("#000000", 1.5)))
                b.append(circle(cx, fy, r - 3.5, "none", stroke(HC["paper"], 1.5)))
                b.append(circle(cx, fy, r - 1.5, "none", stroke("#000000", LINE_HC)))
                svg.state(st, b, hc=True)
                continue
            line = K["disabled_line"] if st == "disabled" else C["ink_line"]
            if st != "disabled":
                b.append(circle(cx, cy + D_LIP, r - 0.5, "none", ink(line, 1.5)))
                # The ground's inner shade and rim: light at the top, dark at the foot.
                b.append(circle(cx, fy, r - 2.25, "none", ' stroke="%s" stroke-width="2.5"' % svg.grad(
                    [(0, a("#FFFFFF", 0.6 if st == "normal" else 0.25)), (0.45, a("#FFFFFF", 0)), (1, a("#000000", 0.4))])))
            if st == "normal":
                g = svg.grad([(0, a("#FFFFFF", 0.45)), (1, a("#FFFFFF", 0))])
                b.append('<ellipse cx="%s" cy="%s" rx="%s" ry="%s" fill="%s"/>' % (
                    p(cx - 4), p(fy - r * 0.5), p(r * 0.5), p(r * 0.26), g))
            b.append(circle(cx, fy, r - 0.5, "none", ink(line, LINE)))
            svg.state(st, b)
    out["disc_school/frame.svg"] = svg.text()
    return out


# --- Overlays ------------------------------------------------------------------

def overlays():
    """Selected and locked marks and the spinner (kit-spec.md section 3): they
    combine with any face, so they are pieces of their own."""
    out = {}
    # The lock mark: a padlock, light body and shackle, ink edges, a drop.
    svg = Svg(20, 24, None)
    shackle = "M6 11 V7.5 a4 4 0 0 1 8 0 V11"
    for hc in (False, True):
        b = []
        if hc:
            b.append('<path d="%s" fill="none" stroke="#000000" stroke-width="5" stroke-linecap="round"/>' % shackle)
            b.append('<path d="%s" fill="none" stroke="#FFFFFF" stroke-width="2" stroke-linecap="round"/>' % shackle)
            b.append(rrect(2.5, 10, 15, 11.5, 3, "#FFFFFF", stroke("#000000", LINE_HC)))
            b.append(circle(10, 14.5, 1.75, "#000000"))
            b.append('<rect x="9.25" y="15" width="1.5" height="3.5" fill="#000000"/>')
            svg.state("normal", b, hc=True)
            continue
        b.append(rrect(3, 11.5, 15, 11.5, 3, a(C["drop"], 0.6)))
        b.append('<path d="%s" fill="none" stroke="%s" stroke-width="4.5" stroke-linecap="round"/>' % (shackle, C["ink_line"]))
        b.append('<path d="%s" fill="none" stroke="%s" stroke-width="2" stroke-linecap="round"/>' % (shackle, K["lock_shade"]))
        b.append(rrect(2.5, 10, 15, 11.5, 3, svg.grad([(0, K["lock_light"]), (1, K["lock_shade"])])))
        b.append(rrect(4, 11.25, 12, 2, 1, "#FFFFFF99"))
        b.append(rrect(2.5, 10, 15, 11.5, 3, "none", ink(C["ink_line"], 1.5)))
        b.append(circle(10, 14.5, 1.75, C["ink_deep"]))
        b.append('<rect x="9.25" y="15" width="1.5" height="3.5" fill="%s"/>' % C["ink_deep"])
        svg.state("normal", b)
    out["locked/lock.svg"] = svg.text()

    # The selected rim: 3 points of gold round a radius-16 face, 3 points out,
    # with a soft glow outside (card_selected's rim and glow).
    W = 40
    svg = Svg(W, W, [20, 20, 20, 20])
    for hc in (False, True):
        b = []
        if hc:
            b.append(rrect(1.5, 1.5, W - 3, W - 3, 18.5, "none", stroke("#000000", 1.5)))
            b.append(rrect(3.25, 3.25, W - 6.5, W - 6.5, 17, "none", stroke(K["gold_hc"], 2.5)))
            b.append(rrect(5, 5, W - 10, W - 10, 15, "none", stroke("#000000", 1)))
            svg.state("normal", b, hc=True)
            continue
        b.append(rrect(1.5, 1.5, W - 3, W - 3, 18.5, "none", stroke(a(C["card_selected_rim"], 0.25), 3)))
        b.append(rrect(3.5, 3.5, W - 7, W - 7, 17, "none", stroke(C["card_selected_rim"], 3)))
        b.append(rrect(3.5, 3.5, W - 7, W - 7, 17, "none", ' stroke="%s" stroke-width="1"' % svg.grad(
            [(0, a(C["cream"], 0.9)), (0.5, a(C["cream"], 0.2)), (1, a(C["gold_rim"], 0.6))])))
        b.append(rrect(5.25, 5.25, W - 10.5, W - 10.5, 15.25, "none", stroke(a(C["gold_rim"], 0.8), 0.5)))
        svg.state("normal", b)
    out["selected/rim.svg"] = svg.text()

    # The spinner: a quiet ring and a lit arc with a bright head; the code
    # turns it (reduced motion: the code shows it still, with "Loading").
    svg = Svg(24, 24, None)
    c, r = 12, 9
    arc = "M%s %s A%s %s 0 0 1 %s %s" % (p(c), p(c - r), p(r), p(r), p(c + r), p(c))
    for hc in (False, True):
        b = []
        if hc:
            b.append(circle(c, c, r, "none", stroke("#000000", 5)))
            b.append('<path d="%s" fill="none" stroke="#FFFFFF" stroke-width="3" stroke-linecap="round"/>' % arc)
            svg.state("normal", b, hc=True)
            continue
        b.append(circle(c, c, r, "none", stroke(a(C["ink_deep"], 0.55), 4.5)))
        b.append(circle(c, c, r, "none", stroke(a(C["text_on_night"], 0.22), 3)))
        b.append('<path d="%s" fill="none" stroke="%s" stroke-width="3" stroke-linecap="round"/>' % (
            arc, svg.grad([(0, a(C["text_on_night"], 0.35)), (1, C["text_on_night"])], x2=1, y2=1)))
        b.append(circle(c + r, c, 1.6, "#FFFFFF"))
        svg.state("normal", b)
    out["spinner/ring.svg"] = svg.text()
    return out


S_DROP_M = 4


def build_1b():
    svgs = {"panel_dark/box.svg": panel_dark(), "panel_glass/box.svg": panel_glass(), "well/box.svg": well(),
            "pill/box.svg": pill()}
    for f in (badge, tags, bars, disc, disc_school, overlays):
        svgs.update(f())
    return svgs
