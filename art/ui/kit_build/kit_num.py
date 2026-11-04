"""The kit's batch 1c sources (kit-spec.md sections 2.2 T3 and 6.1;
report.md section 10.4): the baked numerals. Called by build_kit.py; not run
on its own.

The face. These are numbers that change (the clock, the loot count, the
currency), so they are drawn with Manrope at its heaviest weight (800) and
its tabular figures, as §21.8 gives every number that changes and the owner
kept (D4 (b); report.md section 10.4). Lilita One stays with the large
numbers that never change, which are not baked.

Four finishes, each at one size in points (its size at 100% text; the bake
draws it at 200%). A slot shows a finish at that size or smaller, never
larger:

    gold       28   currency, rewards, the loot count: a gold fill
    white      22   counts on cards and badges: a white-to-lilac fill
    timer      28   the heist clock: a cool white fill
    timer_red  28   the clock in its last seconds: red words on dark, its
                    foot #FF9AAA (alarm_text_on_night) and lighter above

Each glyph is one piece, num_<finish>_<glyph>, with a fixed advance:

    0 to 9      the tabular figures: one advance a finish
    comma period colon slash plus minus percent x question
                each its own advance: its ink and a margin either side
    space       an empty piece, half a digit wide

The drawing: a gradient fill, an ink outline twice the rubric's visible width
under the fill (paint-order stroke), and a hard drop, an ink copy 0.08 of the
size straight down. A second pass of the fill, unstroked, lies over the face:
the variable font's contours overlap, and one pass leaves a faint seam where
they meet. Every fill pixel is at least Lc 60 and 4.5:1 on its outline
(proof_num.py measures it). The gradient runs from the cap height to the baseline in
the drawing's own units, so every glyph of a finish is lit the same.

The box (its width, height and advance in whole points). Every piece of a
finish has one height, with the baseline at one place. The box is the
advance cell plus 1 point on either side, so the outline and the drop never
clip: a piece is drawn centred on its advance cell, its left edge 1 point
before the pen.

High contrast (data-hc="class"): a flat fill, black outline and drop, the
same geometry.
"""

from build_kit import C, HC, K, KIT, p

# The colours this batch adds; each says what it comes from.
KIT_NUM = {
    "num_timer_bottom": ("#D6E4F2", "text_on_night_2, cooled: the clock's foot, not the time school's cyan"),
    "num_red_top": ("#FFE4E8", "alarm_text_on_night, lifted toward paper"),
    "num_red_mid": ("#FFBFC9", "half way from num_red_top to alarm_text_on_night"),
}
KIT.update(KIT_NUM)
K.update({k: v[0] for k, v in KIT_NUM.items()})

UPM = 2000.0
CAP = 1470 / UPM          # the digits' ink top (0, 2, 8 overshoot the 1440 cap)
TAB = 1240 / UPM          # the tabular figure's advance
PX = 1 / 6.0              # one pixel at the kit's 6 px a point

# The marks' ink, in Manrope 800 font units: (character, left, right).
MARKS = {
    "comma": (",", 120, 392),
    "period": (".", 184, 456),
    "colon": (":", 220, 494),
    "slash": ("/", 120, 776),
    "plus": ("+", 120, 1020),
    "minus": ("−", 120, 960),
    "percent": ("%", 120, 1680),
    "x": ("×", 120, 906),
    "question": ("?", 100, 1026),
}

# Each finish: size, gradient stops (offset, colour), its high-contrast fill.
FINISHES = {
    "gold": (28, [(0, "cream"), (0.45, "gold_top"), (0.55, "gold_round_mid"), (1, "gold")], "gold_hc"),
    "white": (22, [(0, "paper"), (0.5, "paper"), (0.56, "text_on_night_2"), (1, "pill_bottom")], "paper"),
    "timer": (28, [(0, "paper"), (0.5, "text_on_night"), (0.56, "text_on_night_2"), (1, "num_timer_bottom")],
              "paper"),
    "timer_red": (28, [(0, "num_red_top"), (0.5, "num_red_mid"), (0.56, "alarm_text_on_night"),
                       (1, "alarm_text_on_night")], "alarm_text_on_night"),
}


def snap(v):
    """v points, rounded to a whole pixel."""
    return round(v / PX) * PX


def whole(v):
    """v points, rounded to a whole point: the box's sizes. The bake's
    screenshot clips in points, so a box of a fraction of a point loses it."""
    return float(round(v))


def colour(name):
    return K.get(name) or C[name]


def geometry(size):
    """The numbers one finish shares, in points, each a whole pixel."""
    return {
        "line": snap(0.25 * size),         # stroke width; half of it shows: 12.5% of the size
        "drop": snap(0.08 * size),
        "digit": whole(0.72 * size),       # a digit's advance
        "margin": snap(0.11 * size),       # a mark's margin either side of its ink
        "space": whole(0.35 * size),
        "pad": 1.0,                        # the box past the advance cell, each side
        "base": snap(0.90 * size),         # the baseline, from the top
        "height": whole(1.24 * size),
    }


def glyph_svg(finish, glyph):
    size, stops, hc_fill = FINISHES[finish]
    g = geometry(size)
    if glyph.isdigit():
        ch, adv = glyph, g["digit"]
        x, anchor = g["pad"] + adv / 2, "middle"
    elif glyph == "space":
        ch, adv = None, g["space"]
        x, anchor = 0, "start"
    else:
        ch, left, right = MARKS[glyph]
        adv = whole((right - left) / UPM * size + 2 * g["margin"])
        # The ink centred in the cell: the pen sits left of the ink by the
        # glyph's own side bearing.
        ink_w = (right - left) / UPM * size
        x, anchor = g["pad"] + (adv - ink_w) / 2 - left / UPM * size, "start"
    w = adv + 2 * g["pad"]
    h, base = g["height"], g["base"]
    y1, y2 = base - CAP * size, base
    st = "".join('<stop offset="%s" stop-color="%s"/>' % (p(o), colour(c)) for o, c in stops)
    ink, hc = C["ink_line"], HC["ink"]
    out = ['<svg xmlns="http://www.w3.org/2000/svg" width="%s" height="%s" data-advance="%s" data-hc="class">'
           % (p(w), p(h), p(adv))]
    out.append("  <!-- Written by art/ui/kit_build/build_kit.py (kit_num.py); do not edit. -->")
    out.append('  <defs><linearGradient id="f" gradientUnits="userSpaceOnUse" x1="0" y1="%s" x2="0" y2="%s">%s'
               '</linearGradient></defs>' % (p(y1), p(y2), st))
    out.append("  <style>text { font-family: 'Manrope'; font-variation-settings: 'wght' 800; "
               "font-feature-settings: 'tnum' 1; font-size: %spx; stroke-width: %s; stroke-linejoin: round; "
               "paint-order: stroke; }\n"
               "  .d { fill: %s; stroke: %s; } .f { fill: url(#f); stroke: %s; } .s { fill: url(#f); stroke: none; }\n"
               "  .hc .d { fill: %s; stroke: %s; } .hc .f { fill: %s; stroke: %s; } .hc .s { fill: %s; }</style>"
               % (p(size), p(g["line"]), ink, ink, ink, hc, hc, colour(hc_fill), hc, colour(hc_fill)))
    if ch is not None:
        for cls, dy in (("d", g["drop"]), ("f", 0), ("s", 0)):
            out.append('  <text class="%s" x="%s" y="%s" text-anchor="%s">%s</text>'
                       % (cls, p(x), p(base + dy), anchor, ch))
    out.append("</svg>")
    return "\n".join(out) + "\n"


GLYPHS = [str(d) for d in range(10)] + list(MARKS) + ["space"]


def build_num():
    return {"num_%s/%s.svg" % (f, gl): glyph_svg(f, gl) for f in FINISHES for gl in GLYPHS}
