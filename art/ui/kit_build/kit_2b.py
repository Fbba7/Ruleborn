"""Batch 2b of the kit's art (kit-spec.md section 8.2): the tab bar and its
tabs, the segmented control, chips, tiles, the locked face, the toggle and the
slider. With it batch 2 covers all 35 skins. build_kit.py calls build_2b() and
writes the files.

    tab_bar/box                 the bar: a bronze bevel, an inner well, flush to the foot: normal
    tab_active/box              the chosen tab's violet cell in its gold rim: normal, pressed
    tab/tab                     an unchosen tab (no cell; a sunk well when pressed): normal, pressed
    tab/tab_heist               the Heist tab's gold halo: normal, pressed
    segmented/seg_track         the dark track, sunk: normal, disabled
    segmented/seg_track_light   the track on parchment, sunk: normal, disabled
    segmented/seg               an unchosen segment on the dark track: normal, pressed, disabled
    segmented/seg_light         an unchosen segment on parchment: normal, pressed, disabled
    segmented_on/seg_on         the chosen segment, cream in a gold rim (E1): normal, pressed, disabled
    segmented_on/seg_on_light   the chosen segment on parchment, leather in a gold rim: normal, pressed, disabled
    chip/chip                   a chip, off: normal, pressed, disabled, locked
    chip/chip_light             a chip on parchment, off: normal, pressed, disabled, locked
    chip_on/chip_on             a chip, on, cream in a gold rim: normal, pressed, disabled, locked
    chip_on/chip_on_light       a chip on parchment, on, leather in a gold rim: normal, pressed, disabled, locked
    tile/day_done               a streak day kept, a tan plate stamped with a bronze ring: normal
    tile/day_today              today, parchment ringed in gold: normal
    tile/day_later              a day to come, an empty slot: normal
    tile/week_day               a day's bar, violet: normal
    tile/week_today             today's bar: a lighter violet under a cream cap, in a gold rim, glowing: normal
    tile/reward_sky             a reward tile edged in sky, round pips: normal, locked
    tile/reward_pink            a reward tile edged in pink, diamond pips: normal, locked
    locked/locked               the locked face, teal, hatched in its corners: normal, pressed
    toggle/track_on             the switch's track, on, green, sunk: normal, pressed, disabled
    toggle/track_off            the switch's track, off, sunk: normal, pressed, disabled
    toggle/knob                 the switch's gold knob (a sprite): normal, pressed, disabled
    slider/track                the slider's rail, sunk: normal, pressed, disabled
    slider/fill                 the rail's gold fill: normal, pressed, disabled
    slider/knob                 the slider's gold knob (a sprite): normal, pressed, disabled

An unchosen chip on parchment is a tan plate, not the token's cream, as
K01's tertiary on parchment is: cream on parchment is no value step at all.
A chip that is off and the switch's off track are a smoked violet, not the
token's glass: glass on the night backdrop is under one value step, and an
interactive face needs two (kit-spec.md section 2.2).

Gold has two roles and no third. As a fill it is the main action's, and the
knobs' and the slider's fill, which are the control's one moving part. As a
rim it marks the chosen one of a set: tab_active, seg_on, chip_on, day_today
and week_today all wear the same gold rim, on a face that turns its ground's
value over (cream on the dark track, leather on parchment), so the chosen
state reads by value and by the rim's shape, not by hue. A kept day is not
chosen: it is a tan plate with a stamped ring, and holds no gold.
"""

from build_kit import C, HC, K, KIT, LINE, LINE_HC, Svg, col, p, rrect, stroke
from kit_1b import a, circle, foot_shade, hc_edge, ink, lit_band, rim_ring, stripes, top_light
from kit_2a import blur, corner_mask, frame_stops, top_round

KIT_2B = {
    "bronze_light": ("#F2C45C", "tab_bar's rim #F2C45C: the bevel's lit edge"),
    "bronze": ("#8A5A1C", "tab_bar's line #8A5A1C: the bevel's body"),
    "bronze_dark": ("#5A3A12", "tab_bar's line, shaded: the bevel's foot"),
    "bar_well_mid": ("#261A52", "tab_bar_top #2C1E5C toward its middle: the well under the gloss"),
    "bar_well_low": ("#160E34", "tab_bar_bottom #120A2C, lifted a little: the well's foot"),
    "smoke_top": ("#6C5CB0", "text_on_night_3 #B8A8D8 toward tab_active_bottom: an off chip's lit top, two steps off the night"),
    "smoke_bottom": ("#50408C", "the off chip's foot"),
    "smoke_pressed_top": ("#4A3A84", "smoke_bottom, a step down"),
    "smoke_pressed_bottom": ("#5A4A98", "smoke_top, a step down: pressed, the light comes from under"),
    "smoke_lip": ("#241A52", "tab_bar_top, deep: the off chip's lip"),
    "smoke_rim": ("#B8A8D8", "text_on_night_3: the off chip's lit inner rim"),
    "smoke_disabled": ("#4A4460", "smoke, greyed and flat"),
    "smoke_hc": ("#5A4AA6", "violet_hc: the off chip, flat"),
    "smoke_hc_pressed": ("#463A86", "violet_hc, a step down"),
    "chosen_top": ("#5A3A24", "leather_chosen's top"),
    "chosen_bottom": ("#3E2716", "leather_chosen's foot"),
    "chosen_pressed_top": ("#4A2E1C", "leather_chosen's top, a step down"),
    "chosen_pressed_bottom": ("#321E10", "leather_chosen's foot, a step down"),
    "chosen_lip": ("#2A1A10", "seg_on_light's drop"),
    "chosen_rim": ("#FFDCB4", "seg_on_light's highlight"),
    "chosen_disabled": ("#6A5A50", "leather_chosen, greyed and flat"),
    "chosen_hc": ("#2A1A10", "seg_on_light's drop, flat: two steps off the black edge and the white tray"),
    "chosen_hc_pressed": ("#5A3A24", "leather_chosen's top, flat: pressed, lit from under"),
    "paper_lip": ("#C9A876", "chip_light's drop: a tan foot"),
    "tan_top": ("#D4B67E", "tertiary_parchment_top #D9BC86, a touch down: an unchosen chip on parchment, lit top"),
    "tan_bottom": ("#CAAA70", "tertiary_parchment_bottom #C6A266, a touch up: its foot (parchment_ink still reads on it)"),
    "tan_pressed_top": ("#CAA96E", "tan_bottom, a touch down: pressed, the light comes from under"),
    "tan_pressed_bottom": ("#D4B67E", "tan_top, a touch down"),
    "tan_hc": ("#C0C0C0", "a grey plate: two steps off white paper, black words on it"),
    "tan_hc_pressed": ("#B4B4B4", "tan_hc, a step down"),
    "gold_in_top": ("#D8A238", "gold #E9B65C, a step down: a chosen face pressed, shaded at its top"),
    "gold_in_mid": ("#E0AC44", "gold, a touch down: text_on_gold still reads on it"),
    "gold_in_bottom": ("#E8B450", "gold: pressed, the light comes from under"),
    "track_hc_edge": ("#7868C4", "violet_hc, lifted: the dark track's edge, two steps under the gold on it"),
    "paper_pressed_top": ("#EBDDBE", "tray_track's top: paper pressed in"),
    "paper_pressed_bottom": ("#E0CDA4", "tray_track's foot"),
    "track_line": ("#624328", "seg_track's line"),
    "track_disabled": ("#221A26", "track, flat"),
    "tray_line": ("#B08A58", "seg_track_light's line"),
    "tray_shade": ("#8A5A1C", "parchment_text_3: the tray's inner shade"),
    "later_line": ("#C9B48A", "day_later's line"),
    "today_ring": ("#E9B65C", "day_today's line: gold"),
    "week_top": ("#8C6CF0", "week_day's top"),
    "week_bottom": ("#4E34A8", "week_day's foot"),
    "week_hc": ("#7A5CE0", "week_day, flat"),
    "halo": ("#F2C45C", "tab_heist's glow"),
    "week_today_top": ("#DCD0FF", "week_day's top #8C6CF0 toward white: today's bar, two steps lighter than its neighbours"),
    "week_today_bottom": ("#A48CF4", "week_day's top, lifted: today's bar's foot"),
    "week_today_hc": ("#FFFFFF", "today's bar, flat: white among violet bars"),
    "stamp": ("#8A5A1C", "parchment_text_3: the ring stamped on a kept day"),
    "active_glow": ("#AA96FF", "tab_active's glow"),
    "tile_lip": ("#4A2A10", "reward tiles' drop"),
    "green_sunk": ("#1E6A1A", "green_bottom #349125, shaded: the on track's inner shade"),
    "track_on_pressed_top": ("#3E9A30", "green's body, a step down"),
    "track_on_pressed_bottom": ("#5CC542", "green's body: pressed, the light comes from under"),
    "green_off": ("#24604A", "green_muted's top: a disabled on track, flat"),
    "knob_disabled": ("#A89A80", "gold_disabled, a step down: a knob that cannot move"),
    "rail_top": ("#140A16", "track's top"),
    "rail_bottom": ("#24142A", "track's foot"),
}
KIT.update(KIT_2B)
K.update({k: v[0] for k, v in KIT_2B.items()})


def _mats(T):
    gold = [(0, C["gold_top"]), (0.46, C["gold"]), (1, C["gold_bottom"])]
    return {
        "gold": dict(face=gold,
                     pressed=[(0, K["gold_in_top"]), (0.5, K["gold_in_mid"]), (1, K["gold_in_bottom"])],
                     disabled=K["gold_disabled"], lip=C["gold_drop"], top=a("#FFFFFF", 0.6), foot=a(C["gold_rim"], 0.45),
                     gloss=0.3, hc=K["gold_hc"], hc_pressed=K["gold_hc_pressed"], hc_edge="#000000"),
        "chosen": dict(face=[(0, K["chosen_top"]), (1, K["chosen_bottom"])],
                       pressed=[(0, K["chosen_pressed_top"]), (1, K["chosen_pressed_bottom"])],
                       disabled=K["chosen_disabled"], lip=K["chosen_lip"], top=a(K["chosen_rim"], 0.4),
                       foot=a("#000000", 0.35), gloss=0.12, hc=K["chosen_hc"], hc_pressed=K["chosen_hc_pressed"],
                       hc_edge="#000000"),
        "smoke": dict(face=[(0, K["smoke_top"]), (1, K["smoke_bottom"])],
                      pressed=[(0, K["smoke_pressed_top"]), (1, K["smoke_pressed_bottom"])],
                      disabled=K["smoke_disabled"], lip=K["smoke_lip"], top=a(K["smoke_rim"], 0.75),
                      foot=a(K["smoke_lip"], 0.5), gloss=0.14, hc=K["smoke_hc"], hc_pressed=K["smoke_hc_pressed"],
                      hc_edge=K["edge_hc"]),
        "paper": dict(face=[(0, C["parchment_top"]), (1, C["parchment_bottom"])],
                      pressed=[(0, K["paper_pressed_top"]), (1, K["paper_pressed_bottom"])],
                      disabled=K["parchment_disabled"], lip=K["paper_lip"], top=a("#FFFFFF", 0.95),
                      foot=a(K["tray_shade"], 0.4), gloss=0.0, hc="#FFFFFF", hc_pressed=K["pill_hc_pressed"],
                      hc_edge="#000000"),
        "tan": dict(face=[(0, K["tan_top"]), (1, K["tan_bottom"])],
                    pressed=[(0, K["tan_pressed_top"]), (1, K["tan_pressed_bottom"])],
                    disabled=K["parchment_disabled"], lip=K["tertiary_parchment_lip"], top=a("#FFFFFF", 0.7),
                    foot=a(K["tray_shade"], 0.4), gloss=0.0, hc=K["tan_hc"], hc_pressed=K["tan_hc_pressed"],
                    hc_edge="#000000"),
        "locked": dict(face=frame_stops(T, "locked"), pressed=[(0, K["frame_locked_dark"]), (1, K["locked_bottom"])],
                       disabled=K["locked_hc"], lip=C["drop"], top=a("#FFFFFF", 0.4), foot=a("#000000", 0.35),
                       gloss=0.1, hc=K["locked_hc"], hc_pressed=K["frame_locked_dark"], hc_edge=K["edge_hc"]),
    }


def raised(svg, st, hc, x, y, w, fh, r, drop, m, lw=1.5, locked=None, hatch=None):
    """A raised face in material m: a solid lip `drop` points under it, the
    face's gradient, a gloss band, a lit inner rim at the top, a shaded one at
    the foot, an ink edge. Pressed, the face sits down on its lip, darker,
    shaded from the top. Disabled is flat and muted, with no lip or gloss.
    Locked is the locked material, hatched in the corners `hatch` points
    square. High contrast: a flat fill, a black lip, a 3-point edge."""
    b = []
    lk = st == "locked"
    if lk:
        m = locked
    fy = y + (drop if st == "pressed" else 0)
    if hc:
        fill = {"normal": m["hc"], "pressed": m["hc_pressed"], "disabled": K["disabled_hc"], "locked": m["hc"]}[st]
        if st in ("normal", "locked") and drop:
            b.append(rrect(x, y + drop, w, fh, r, "#000000"))
        b.append(rrect(x, fy, w, fh, r, fill))
        if lk:
            b.append(rrect(x, fy, w, fh, r, stripes(svg, "#000000", 6, 2), ' mask="%s"' % corner_mask(svg, hatch)))
        b.append(hc_edge(x, fy, w, fh, r, m["hc_edge"]))
        return b
    if st == "disabled":
        b.append(rrect(x, fy, w, fh, r, m["disabled"]))
        b.append(rrect(x, fy, w, fh, r, "none", stroke(K["disabled_line"], lw)))
        return b
    if st != "pressed" and drop:
        b.append(rrect(x, y + drop, w, fh, r, m["lip"], ink(C["ink_line"], lw)))
    b.append(rrect(x, fy, w, fh, r, svg.grad(m["pressed"] if st == "pressed" else m["face"])))
    if lk:
        b.append(rrect(x, fy, w, fh, r, stripes(svg, a("#FFFFFF", 0.14)), ' mask="%s"' % corner_mask(svg, hatch)))
    i = lw / 2 + 0.6
    if st == "pressed":
        b.append(top_light(svg, x + i, fy + i, w - 2 * i, fh - 2 * i, r - i, a("#000000", 0.4), 2.2))
    else:
        if m["gloss"]:
            g = lw + 1.2
            b.append(lit_band(svg, x + g, fy + g, w - 2 * g, fh, max(r - g, 1), m["gloss"], min(fh * 0.42, 13)))
        b.append(top_light(svg, x + i, fy + i, w - 2 * i, fh - 2 * i, r - i, m["top"], 1.5))
        b.append(foot_shade(svg, x + i, fy + i, w - 2 * i, fh - 2 * i, r - i, m["foot"], 1.8))
    b.append(rrect(x, fy, w, fh, r, "none", ink(C["ink_line"], lw)))
    return b


def gold_rim(svg, st, hc, x, fy, w, fh, r, lw=1.5, wd=2.2):
    """The chosen state's mark, the same on every chosen face: a gold rim
    just inside the ink edge, lit at the top, with a bronze hairline inside
    it. Disabled, the rim stays as a grey line, so chosen still reads.
    High contrast: a flat gold band inside the 3-point edge."""
    if hc:
        i = LINE_HC + 1.25
        c = "#000000" if st == "disabled" else K["gold_hc"]
        return [rrect(x + i, fy + i, w - 2 * i, fh - 2 * i, max(r - i, 1), "none", stroke(c, 2 if st == "disabled" else 2.5))]
    if st == "disabled":
        i = lw / 2 + wd / 2 + 0.6
        return [rrect(x + i, fy + i, w - 2 * i, fh - 2 * i, max(r - i, 1), "none", stroke(K["disabled_line"], 1.2))]
    i = lw / 2 + wd / 2
    j = lw / 2 + wd + 0.4
    g = svg.grad([(0, C["gold_top"]), (0.4, K["today_ring"]), (1, C["gold_bottom"])] if st != "pressed" else
                 [(0, C["gold_bottom"]), (0.6, K["today_ring"]), (1, C["gold"])])
    return [rrect(x + i, fy + i, w - 2 * i, fh - 2 * i, max(r - i, 1), "none", ' stroke="%s" stroke-width="%s"' % (g, p(wd))),
            rrect(x + j, fy + j, w - 2 * j, fh - 2 * j, max(r - j, 1), "none",
                  stroke(K["bronze"], 0.8) + ' stroke-opacity="0.7"')]


def chosen(svg, st, hc, x, y, w, fh, r, drop, m, lw=1.5, locked=None, hatch=None):
    """A raised face that is the chosen one of its set: material m, in the
    gold rim. Locked, it is the locked face, as an unchosen one is."""
    b = raised(svg, st, hc, x, y, w, fh, r, drop, m, lw, locked, hatch)
    if st == "locked":
        return b
    fy = y + (drop if st == "pressed" else 0)
    rim = gold_rim(svg, st, hc, x, fy, w, fh, r, lw)
    return b[:-1] + rim + b[-1:] if not hc else b + rim


def sunk(svg, st, hc, x, y, w, h, r, fill, line, shade, flat, hc_fill, hc_line, lw=1.5):
    """A sunk bed (a track, an empty slot): its fill, shaded inside along the
    top edge, a faint lit line inside the foot, its own line round it."""
    b = []
    if hc:
        b.append(rrect(x, y, w, h, r, K["disabled_hc"] if st == "disabled" else hc_fill))
        b.append(hc_edge(x, y, w, h, r, hc_line))
        return b
    if st == "disabled":
        b.append(rrect(x, y, w, h, r, flat))
        b.append(rrect(x, y, w, h, r, "none", stroke(K["disabled_line"], lw)))
        return b
    b.append(rrect(x, y, w, h, r, svg.grad(fill)))
    i = lw / 2 + 0.7
    b.append(top_light(svg, x + i, y + i, w - 2 * i, h - 2 * i, max(r - i, 0.5), shade, 2.4))
    b.append(foot_shade(svg, x + i, y + i, w - 2 * i, h - 2 * i, max(r - i, 0.5), a("#FFFFFF", 0.16), 1.2))
    b.append(rrect(x, y, w, h, r, "none", stroke(line, lw)))
    return b


# --- Tab bar -----------------------------------------------------------------

def tab_bar():
    """The tab bar (K09): full width, flush to the foot, rounded at the top.
    A bronze bevel frames an inner well; the well is shaded under the bevel
    and glossed below it; a soft shadow falls up onto the screen."""
    W, TOP, CAP, FOOT = 72, 8, 26, 6
    FH = CAP + 2 + FOOT
    H = TOP + FH
    R, TH = 24, 4
    svg = Svg(W, H, [35, TOP + CAP, 35, FOOT])
    x, y, w = 0, TOP, W
    for hc in (False, True):
        b = []
        if hc:
            b.append(top_round(x, y, w, FH, R, HC["card_top"]))
            b.append(top_round(x + 1.5, y + 1.5, w - 3, FH, R - 1.5, "none", stroke(K["edge_hc"], LINE_HC)))
            svg.state("normal", b, hc=True)
            svg.state("pressed", b, hc=True)
            continue
        b.append(top_round(x + 2, y - 3, w - 4, FH, R, a("#000000", 0.62), blur(svg, 2.2)))
        f = FH
        bevel = svg.grad([(0, K["bronze_light"]), (2.2 / f, "#C8923A"), (4.4 / f, K["bronze"]), (1, K["bronze_dark"])])
        b.append(top_round(x, y, w, FH, R, bevel))
        b.append(top_round(x + 0.9, y + 0.9, w - 1.8, FH, R - 0.9, "none",
                           stroke(C["cream"], 0.9) + ' stroke-opacity="0.75"'))
        wx, wy, ww, wr = x + TH, y + TH, w - 2 * TH, R - TH
        wh = FH - TH
        well = svg.grad([(0, "#2C1E5C"), ((CAP - TH) / wh, K["bar_well_mid"]),
                         ((CAP - TH + 2) / wh, K["bar_well_low"]), (1, "#120A2C")])
        b.append(top_round(wx, wy, ww, wh, wr, well))
        # The well's shade under the bevel, then its gloss; both end above the stretched row.
        sh = svg.grad([(0, a("#000000", 0.55)), (1, a("#000000", 0))])
        b.append(top_round(wx, wy, ww, 7, wr, sh))
        gl = svg.grad([(0, a("#FFFFFF", 0)), (0.25, a("#FFFFFF", 0.12)), (1, a("#FFFFFF", 0))])
        b.append(top_round(wx + 3, wy + 4, ww - 6, 17, wr - 3, gl))
        b.append(top_round(wx, wy, ww, wh + 2, wr, "none", ink(C["ink_deep"], 1.5)))
        b.append(top_round(x, y, w, FH + 2, R, "none", ink(C["ink_line"], 1.5)))
        svg.state("normal", b)
        # The bar itself is never pressed (its tabs are): pressed repeats
        # normal, so K09's pressed row finds a piece for every face.
        svg.state("pressed", b)
    return {"tab_bar/box.svg": svg.text()}


def tabs():
    out = {}
    # The chosen tab: a violet cell raised on its lip, in a gold rim, glowing.
    M, FACE, R, DROP = 6, 42, 16, 3
    W, H = M + FACE + M, M + FACE + DROP + M
    svg = Svg(W, H, [26, 26, 26, 29])
    x, y, w = M, M, FACE
    for st in ("normal", "pressed"):
        fy = y + (DROP if st == "pressed" else 0)
        for hc in (False, True):
            b = []
            if hc:
                if st == "normal":
                    b.append(rrect(x, y + DROP, w, FACE, R, "#000000"))
                b.append(rrect(x, fy, w, FACE, R, K["violet_hc"] if st == "normal" else K["smoke_hc_pressed"]))
                b.append(hc_edge(x, fy, w, FACE, R, K["gold_hc"]))
                svg.state(st, b, hc=True)
                continue
            b.append(rrect(x - 2, fy - 2, w + 4, FACE + 4, R + 2, a(K["active_glow"], 0.55 if st == "normal" else 0.3),
                           blur(svg, 2.2)))
            if st == "normal":
                b.append(rrect(x, y + DROP, w, FACE, R, K["disc_lip"], ink(C["ink_deep"], LINE)))
                face = [(0, C["tab_active_top"]), (0.45, C["tab_active_mid"]), (1, C["tab_active_bottom"])]
            else:
                face = [(0, K["disc_pressed_top"]), (0.45, K["disc_pressed_mid"]), (1, K["disc_pressed_bottom"])]
            b.append(rrect(x, fy, w, FACE, R, svg.grad(face)))
            if st == "normal":
                b.append(lit_band(svg, x + 5.5, fy + 5.5, w - 11, FACE, R - 5.5, 0.3, 14))
            rim = svg.grad([(0, C["cream"]), (0.3, K["bronze_light"]), (1, "#C8923A")])
            b.append(rrect(x + 2, fy + 2, w - 4, FACE - 4, R - 2, "none", ' stroke="%s" stroke-width="2"' % rim))
            b.append(rrect(x + 3.6, fy + 3.6, w - 7.2, FACE - 7.2, R - 3.6, "none", stroke(K["bronze"], 1.2)))
            if st == "pressed":
                b.append(top_light(svg, x + 5, fy + 5, w - 10, FACE - 10, R - 5, a("#000000", 0.4), 2.5))
            b.append(rrect(x, fy, w, FACE, R, "none", ink(C["ink_deep"], LINE)))
            svg.state(st, b)
    out["tab_active/box.svg"] = svg.text()

    # An unchosen tab has no cell; pressed, a well sinks under its icon.
    S, R = 34, 14
    svg = Svg(S, S, [16, 16, 16, 16])
    for st in ("normal", "pressed"):
        for hc in (False, True):
            b = []
            if st == "normal":
                # No cell: one clear pixel's worth, so the piece exists and draws nothing.
                b.append(rrect(1, 1, S - 2, S - 2, R, a("#FFFFFF", 0.004)))
            elif hc:
                b.append(rrect(1, 1, S - 2, S - 2, R, HC["glass"]))
                b.append(hc_edge(1, 1, S - 2, S - 2, R, K["edge_hc"]))
            else:
                b.append(rrect(1, 1, S - 2, S - 2, R, a("#000000", 0.34)))
                b.append(top_light(svg, 1.8, 1.8, S - 3.6, S - 3.6, R - 0.8, a("#000000", 0.55), 2.4))
                b.append(foot_shade(svg, 1.8, 1.8, S - 3.6, S - 3.6, R - 0.8, a(K["active_glow"], 0.4), 1.2))
            svg.state(st, b, hc=hc)
    out["tab/tab.svg"] = svg.text()

    # The Heist tab: a gold halo behind its icon, a thin gold ring.
    S, M, R = 48, 6, 14
    svg = Svg(S, S, [23, 23, 23, 23])
    for st in ("normal", "pressed"):
        for hc in (False, True):
            b = []
            if hc:
                b.append(rrect(M, M, S - 2 * M, S - 2 * M, R, HC["glass"] if st == "pressed" else a("#FFFFFF", 0.004)))
                b.append(hc_edge(M, M, S - 2 * M, S - 2 * M, R, K["gold_hc"]))
                svg.state(st, b, hc=True)
                continue
            halo = svg.grad([(0, a(K["halo"], 0.5 if st == "normal" else 0.28)), (0.55, a(K["halo"], 0.2 if st == "normal" else 0.1)),
                             (1, a(K["halo"], 0))], radial=(0.5, 0.5, 0.5))
            b.append(rrect(0, 0, S, S, S / 2, halo))
            if st == "pressed":
                b.append(rrect(M, M, S - 2 * M, S - 2 * M, R, a("#000000", 0.3)))
                b.append(top_light(svg, M + 0.8, M + 0.8, S - 2 * M - 1.6, S - 2 * M - 1.6, R - 0.8, a("#000000", 0.5), 2.4))
            ring = svg.grad([(0, a(C["cream"], 0.9)), (0.5, a(K["halo"], 0.7)), (1, a(K["bronze"], 0.8))])
            b.append(rrect(M + 0.75, M + 0.75, S - 2 * M - 1.5, S - 2 * M - 1.5, R - 0.75, "none",
                           ' stroke="%s" stroke-width="1.5"' % ring))
            svg.state(st, b)
    out["tab/tab_heist.svg"] = svg.text()
    return out


# --- Segmented control and chips ---------------------------------------------

def segmented(M):
    out = {}
    S, R = 30, 12
    beds = {"seg_track": ([(0, K["rail_top"]), (1, K["rail_bottom"])], K["track_line"], a("#000000", 0.7),
                          K["track_disabled"], HC["glass"], K["track_hc_edge"]),
            "seg_track_light": ([(0, K["paper_pressed_top"]), (1, K["paper_pressed_bottom"])], K["tray_line"],
                                a(K["tray_shade"], 0.55), K["parchment_disabled"], "#FFFFFF", "#000000")}
    for name, (fill, line, shade, flat, hcf, hcl) in beds.items():
        svg = Svg(S, S, [14, 14, 14, 14])
        # The bed is never pressed (its segments are): pressed repeats normal,
        # so K07's pressed row finds a piece for every face.
        for st in ("normal", "pressed", "disabled"):
            for hc in (False, True):
                svg.state(st, sunk(svg, "disabled" if st == "disabled" else "normal", hc, 1, 1, S - 2, S - 2, R,
                                   fill, line, shade, flat, hcf, hcl), hc=hc)
        out["segmented/%s.svg" % name] = svg.text()

    # An unchosen segment: words on the track; pressed, a wash over the track.
    S, R = 20, 8
    for name, wash, edge, hcf, hcl in (("seg", a("#FFFFFF", 0.14), a("#FFFFFF", 0.3), K["smoke_hc_pressed"], K["edge_hc"]),
                                       ("seg_light", a(C["parchment_ink"], 0.14), a(C["parchment_ink"], 0.4),
                                        K["pill_hc_pressed"], "#000000")):
        svg = Svg(S, S, [9, 9, 9, 9])
        for st in ("normal", "pressed", "disabled"):
            for hc in (False, True):
                b = []
                if st != "pressed":
                    b.append(rrect(1, 1, S - 2, S - 2, R, a("#FFFFFF", 0.004)))
                elif hc:
                    b.append(rrect(1, 1, S - 2, S - 2, R, hcf))
                    b.append(rrect(2, 2, S - 4, S - 4, R - 1, "none", stroke(hcl, 2)))
                else:
                    b.append(rrect(1, 1, S - 2, S - 2, R, wash))
                    b.append(top_light(svg, 1.6, 1.6, S - 3.2, S - 3.2, R - 0.6, edge, 1.2))
                svg.state(st, b, hc=hc)
        out["segmented/%s.svg" % name] = svg.text()

    FH, R, DROP = 22, 8, 2
    W, H = 22, 1 + FH + DROP + 1
    # The chosen segment: cream on the dark track, leather on the tray, each
    # in the gold rim. Gold is the rim, never the fill (the main action's).
    for name, m in (("seg_on", M["paper"]), ("seg_on_light", M["chosen"])):
        svg = Svg(W, H, [10, 10, 10, 12])
        for st in ("normal", "pressed", "disabled"):
            for hc in (False, True):
                svg.state(st, chosen(svg, st, hc, 1, 1, W - 2, FH, R, DROP, m), hc=hc)
        out["segmented_on/%s.svg" % name] = svg.text()
    return out


def chips(M):
    out = {}
    FH, DROP = 44, 2
    W, H = 48, 1 + FH + DROP + 1
    R = FH / 2
    L = ("normal", "pressed", "disabled", "locked")
    for skin, name, m, states in (("chip", "chip", M["smoke"], L),
                                  ("chip", "chip_light", M["tan"], L),
                                  # A chosen chip that is locked shows the locked face, as an unchosen one does.
                                  ("chip_on", "chip_on", M["paper"], L),
                                  ("chip_on", "chip_on_light", M["chosen"], L)):
        svg = Svg(W, H, [23, 22, 23, 25])
        for st in states:
            for hc in (False, True):
                face = chosen if skin == "chip_on" else raised
                svg.state(st, face(svg, st, hc, 1, 1, W - 2, FH, R, DROP, m, locked=M["locked"], hatch=20), hc=hc)
        out["%s/%s.svg" % (skin, name)] = svg.text()
    return out


# --- Tiles and the locked face -----------------------------------------------

def pip(svg, kind, cx, cy, r, colour, hc, lk):
    """A reward tile's corner mark: round for sky, a diamond for pink, so the
    two differ by shape, not by hue alone."""
    fill = "#FFFFFF" if hc else (K["frame_locked_light"] if lk else colour)
    edge = stroke("#000000" if hc else C["ink_line"], 1.2 if hc else 1) + ' stroke-linejoin="round"'
    if kind == "round":
        b = [circle(cx, cy, r, fill, edge)]
    else:
        r *= 1.25
        b = ['<path d="M%s %sL%s %sL%s %sL%s %sZ"%s%s/>' % (p(cx), p(cy - r), p(cx + r), p(cy), p(cx), p(cy + r),
                                                           p(cx - r), p(cy), col(fill), edge)]
    if not hc:
        b.append(circle(cx - r * 0.3, cy - r * 0.3, r * 0.3, a("#FFFFFF", 0.4 if lk else 0.8)))
    return b


def tiles(M):
    out = {}
    # Streak days: kept (a tan plate stamped with a bronze ring), today (paper in a gold ring), to come (an empty slot).
    FH, R, DROP = 30, 12, 3
    W, H = 30, 1 + FH + DROP + 1
    svg = Svg(W, H, [14, 14, 14, 17])
    for hc in (False, True):
        b = raised(svg, "normal", hc, 1, 1, W - 2, FH, R, DROP, M["tan"], lw=LINE)
        # The stamp: two rings pressed into the plate. Kept is a done thing,
        # not the chosen one, so it wears bronze ink and no gold.
        if hc:
            b.append(rrect(5.5, 5.5, W - 11, FH - 9, R - 4.5, "none", stroke("#000000", 1.5)))
        else:
            b.insert(-1, rrect(4.4, 4.4, W - 8.8, FH - 6.8, R - 3.4, "none", stroke(K["stamp"], 1.4) + ' stroke-opacity="0.85"'))
            b.insert(-1, rrect(6.6, 6.6, W - 13.2, FH - 11.2, R - 5.6, "none", stroke(K["stamp"], 0.7) + ' stroke-opacity="0.7"'))
            b.insert(-1, rrect(4.4, 5.2, W - 8.8, FH - 6.8, R - 3.4, "none", stroke("#FFFFFF", 0.7) + ' stroke-opacity="0.5"'))
        svg.state("normal", b, hc=hc)
    out["tile/day_done.svg"] = svg.text()

    svg = Svg(W, H, [14, 14, 14, 17])
    x, y, w = 1, 1, W - 2
    for hc in (False, True):
        b = []
        if hc:
            b.append(rrect(x, y + DROP, w, FH, R, "#000000"))
            b.append(rrect(x, y, w, FH, R, "#FFFFFF"))
            b.append(rrect(x + 3.5, y + 3.5, w - 7, FH - 7, R - 3.5, "none", stroke(K["gold_hc"], 2.5)))
            b.append(hc_edge(x, y, w, FH, R, "#000000"))
        else:
            b.append(rrect(x, y + DROP, w, FH, R, K["paper_lip"], ink(K["bronze"], 1.2)))
            b.append(rrect(x, y, w, FH, R, svg.grad([(0, C["parchment_top"]), (1, C["parchment_bottom"])])))
            ringg = svg.grad([(0, C["gold_top"]), (0.4, K["today_ring"]), (1, C["gold_bottom"])])
            b.append(rrect(x + 1.5, y + 1.5, w - 3, FH - 3, R - 1.5, "none", ' stroke="%s" stroke-width="3"' % ringg))
            b.append(top_light(svg, x + 3.5, y + 3.5, w - 7, FH - 7, R - 3.5, a("#FFFFFF", 0.95), 1.2))
            b.append(rrect(x + 3.2, y + 3.2, w - 6.4, FH - 6.4, R - 3.2, "none",
                           stroke(K["bronze"], 0.8) + ' stroke-opacity="0.6"'))
            b.append(rrect(x, y, w, FH, R, "none", ink(K["bronze"], 1.2)))
        svg.state("normal", b, hc=hc)
    out["tile/day_today.svg"] = svg.text()

    svg = Svg(W, H, [14, 14, 14, 17])
    for hc in (False, True):
        svg.state("normal", sunk(svg, "normal", hc, 1, 1 + DROP, W - 2, FH, R,
                                 [(0, K["paper_pressed_top"]), (1, K["paper_pressed_bottom"])], K["later_line"],
                                 a(K["tray_shade"], 0.45), K["parchment_disabled"], "#FFFFFF", "#000000"), hc=hc)
    out["tile/day_later.svg"] = svg.text()

    # A week's bars: corners 6 over 3. The 9-slice keeps the top cap; the body stretches.
    def bar(svg, x, y, w, h, fill, extra=""):
        d = "M%s %sV%sQ%s %s %s %sH%sQ%s %s %s %sV%sQ%s %s %s %sH%sQ%s %s %s %sZ" % (
            p(x), p(y + h - 3), p(y + 6), p(x), p(y), p(x + 6), p(y), p(x + w - 6), p(x + w), p(y), p(x + w), p(y + 6),
            p(y + h - 3), p(x + w), p(y + h), p(x + w - 3), p(y + h), p(x + 3), p(x), p(y + h), p(x), p(y + h - 3))
        return '<path d="%s"%s%s/>' % (d, (' fill="%s"' % fill) if fill.startswith("url") or fill == "none" else col(fill), extra)

    svg = Svg(16, 16, [7, 8, 7, 5])
    for hc in (False, True):
        b = []
        if hc:
            b.append(bar(svg, 1, 1, 14, 14, K["week_hc"]))
            b.append(bar(svg, 2.5, 2.5, 11, 11, "none", stroke(K["edge_hc"], LINE_HC)))
        else:
            b.append(bar(svg, 1, 1, 14, 14, svg.grad([(0, K["week_top"]), (1, K["week_bottom"])])))
            b.append(rrect(3, 2.6, 10, 1.4, 0.7, a("#FFFFFF", 0.45)))
            b.append(bar(svg, 1, 1, 14, 14, "none", ink(C["ink_line"], 1.5)))
        svg.state("normal", b, hc=hc)
    out["tile/week_day.svg"] = svg.text()

    G = 5
    svg = Svg(16 + 2 * G, 16 + 2 * G, [7 + G, 8 + G, 7 + G, 5 + G])
    for hc in (False, True):
        b = []
        # Today's bar is a bar like its neighbours, two steps lighter, with a
        # cream cap across its top (inside the fixed top row) and the chosen
        # state's gold rim: told by value and shape, not by hue.
        cap = '<path d="M%s %sV%sQ%s %s %s %sH%sQ%s %s %s %sV%sZ"%s/>'
        if hc:
            b.append(bar(svg, G + 1, G + 1, 14, 14, K["week_today_hc"]))
            b.append('<rect x="%s" y="%s" width="11" height="2"%s/>' % (p(G + 2.5), p(G + 6.2), col("#000000")))
            b.append(bar(svg, G + 4, G + 4, 8, 8, "none", stroke(K["gold_hc"], 1.5)))
            b.append(bar(svg, G + 2.5, G + 2.5, 11, 11, "none", stroke("#000000", LINE_HC)))
        else:
            b.append(rrect(G - 1, G - 1, 18, 18, 7, a(C["cream"], 0.55), blur(svg, 2)))
            b.append(bar(svg, G + 1, G + 1, 14, 14, svg.grad([(0, K["week_today_top"]), (1, K["week_today_bottom"])])))
            b.append(cap % (p(G + 1), p(G + 6.4), p(G + 6.4), p(G + 1), p(G + 1), p(G + 6.4), p(G + 1), p(G + 9.6),
                            p(G + 15), p(G + 1), p(G + 15), p(G + 6.4), p(G + 6.4), col(C["cream"])))
            b.append('<rect x="%s" y="%s" width="14" height="1.1"%s/>' % (p(G + 1), p(G + 6.4), col(C["ink_line"])))
            b.append(rrect(G + 3.4, G + 2.6, 9.2, 1.4, 0.7, a("#FFFFFF", 0.9)))
            rimg = svg.grad([(0, C["gold_top"]), (0.4, K["today_ring"]), (1, C["gold_bottom"])])
            b.append(bar(svg, G + 2.3, G + 2.3, 11.4, 11.4, "none", ' stroke="%s" stroke-width="1.3"' % rimg))
            b.append(bar(svg, G + 1, G + 1, 14, 14, "none", ink(C["ink_line"], 1.5)))
        svg.state("normal", b, hc=hc)
    out["tile/week_today.svg"] = svg.text()

    # Reward tiles (K39): paper in a 3-point rim of the reward's colour, a
    # white inner rim, a pip at each corner, a brown lip and a soft shadow.
    FH, R, DROP, MX, MT, MB = 30, 14, 3, 3, 2, 5
    W, H = MX + FH + MX, MT + FH + DROP + MB
    x, y, w = MX, MT, FH
    for name, colour, kind, hcc in (("reward_sky", C["time"], "round", "#1E7E8E"), ("reward_pink", C["spirit"], "diamond", "#A8307E")):
        svg = Svg(W, H, [17, 16, 17, 22])
        for st in ("normal", "locked"):
            lk = st == "locked"
            for hc in (False, True):
                b = []
                if hc:
                    b.append(rrect(x, y + DROP, w, FH, R, "#000000"))
                    b.append(rrect(x, y, w, FH, R, K["locked_hc"] if lk else "#FFFFFF"))
                    if lk:
                        b.append(rrect(x, y, w, FH, R, stripes(svg, "#000000", 6, 2), ' mask="%s"' % corner_mask(svg, 15)))
                    b.append(rrect(x + 4, y + 4, w - 8, FH - 8, R - 4, "none", stroke(K["edge_hc"] if lk else hcc, 2)))
                    b.append(hc_edge(x, y, w, FH, R, K["edge_hc"] if lk else "#000000"))
                else:
                    b.append(rrect(x - 1, y + 5, w + 2, FH, R, a("#000000", 0.4), blur(svg, 1.8)))
                    b.append(rrect(x, y + DROP, w, FH, R, C["drop"] if lk else K["tile_lip"], ink(C["ink_line"], 1.5)))
                    if lk:
                        b.append(rrect(x, y, w, FH, R, svg.grad(M["locked"]["face"])))
                        b.append(rrect(x, y, w, FH, R, stripes(svg, a("#FFFFFF", 0.14)), ' mask="%s"' % corner_mask(svg, 15)))
                        rimc = svg.grad([(0, K["frame_locked_light"]), (1, K["locked_top"])])
                    else:
                        b.append(rrect(x, y, w, FH, R, svg.grad([(0, C["parchment_top"]), (0.5, "#F6EAD0"),
                                                                 (1, C["parchment_bottom"])])))
                        rimc = svg.grad([(0, colour), (1, colour)])
                    b.append(rrect(x + 1.5, y + 1.5, w - 3, FH - 3, R - 1.5, "none", ' stroke="%s" stroke-width="3"' % rimc))
                    b.append(top_light(svg, x + 0.8, y + 0.8, w - 1.6, FH - 1.6, R - 0.8, a("#FFFFFF", 0.6), 1.2))
                    b.append(rrect(x + 4, y + 4, w - 8, FH - 8, R - 4, "none",
                                   stroke("#FFFFFF", 2) + ' stroke-opacity="%s"' % ("0.15" if lk else "0.7")))
                    b.append(foot_shade(svg, x + 3.2, y + 3.2, w - 6.4, FH - 6.4, R - 3.2,
                                        a("#000000" if lk else K["tray_shade"], 0.4), 1.5))
                    b.append(rrect(x, y, w, FH, R, "none", ink(C["ink_line"], 1.5)))
                c = R - (R - 1.5) * 0.7071
                for cx, cy in ((x + c, y + c), (x + w - c, y + c), (x + c, y + FH - c), (x + w - c, y + FH - c)):
                    b += pip(svg, kind, cx, cy, 2.5, colour, hc, lk)
                svg.state(st, b, hc=hc)
        out["tile/%s.svg" % name] = svg.text()

    # The locked face (a locked reward, a locked slot): teal, hatched.
    FH, R, DROP = 28, 12, 3
    W, H = 28, 1 + FH + DROP + 1
    svg = Svg(W, H, [13, 13, 13, 16])
    for st, as_ in (("normal", "locked"), ("pressed", "pressed")):
        for hc in (False, True):
            b = raised(svg, as_, hc, 1, 1, W - 2, FH, R, DROP, M["locked"], lw=LINE, locked=M["locked"], hatch=12)
            if as_ == "pressed" and not hc:
                b.insert(2, rrect(1, 1 + DROP, W - 2, FH, R, stripes(svg, a("#FFFFFF", 0.1)),
                                  ' mask="%s"' % corner_mask(svg, 12)))
            if not hc and as_ == "locked":
                b.insert(-1, rim_ring(2.2, 2.2, W - 4.4, FH - 2.4, R - 1.2, a("#FFFFFF", 0.15), 1.5))
            svg.state(st, b, hc=hc)
    out["locked/locked.svg"] = svg.text()
    return out


# --- Toggle and slider -------------------------------------------------------

def knob(svg, st, hc, cx, cy, r, drop):
    """A gold knob: a lip, a domed gold face lit from the top left, a groove
    ring (its grip), an ink edge."""
    b = []
    fy = cy + (drop if st == "pressed" else 0)
    if hc:
        if st == "normal":
            b.append(circle(cx, cy + drop, r, "#000000"))
        b.append(circle(cx, fy, r, {"normal": K["gold_hc"], "pressed": K["gold_hc_pressed"], "disabled": K["disabled_hc"]}[st]))
        b.append(circle(cx, fy, r - 1, "none", stroke("#000000", 2)))
        return b
    if st == "disabled":
        b.append(circle(cx, fy, r, K["knob_disabled"]))
        b.append(circle(cx, fy, r - 0.75, "none", stroke(K["disabled_line"], 1.5)))
        return b
    if st == "normal":
        b.append(circle(cx, cy + drop, r, C["gold_drop"], ink(C["ink_line"], 1.5)))
        dome = [(0, C["cream"]), (0.35, C["gold_top"]), (0.7, C["gold"]), (1, C["gold_bottom"])]
    else:
        dome = [(0, K["gold_pressed_top"]), (0.5, K["gold_pressed_mid"]), (1, K["gold_pressed_bottom"])]
    b.append(circle(cx, fy, r, svg.grad(dome, radial=(0.36, 0.3, 0.8))))
    b.append(circle(cx, fy, r * 0.5, "none", stroke(C["gold_rim"], 1) + ' stroke-opacity="0.55"'))
    b.append(circle(cx, fy + 0.7, r * 0.5, "none", stroke("#FFFFFF", 0.8) + ' stroke-opacity="0.55"'))
    if st == "normal":
        b.append('<ellipse cx="%s" cy="%s" rx="%s" ry="%s"%s/>' % (p(cx - r * 0.2), p(fy - r * 0.55), p(r * 0.48),
                                                                  p(r * 0.22), col(a("#FFFFFF", 0.6))))
    b.append(circle(cx, fy, r - 0.75, "none", ink(C["ink_line"], 1.5)))
    return b


def controls(T):
    out = {}
    green = frame_stops(T, "green")
    # The switch's tracks: sunk pills the knob rides in.
    FH = 44
    S = FH + 4
    R = FH / 2
    tracks = {"track_on": (green, C["ink_line"], a(K["green_sunk"], 0.85), K["green_off"], K["green_hc"], "#000000",
                           [(0, K["track_on_pressed_top"]), (1, K["track_on_pressed_bottom"])]),
              "track_off": ([(0, K["smoke_bottom"]), (1, K["smoke_top"])], C["ink_line"], a(K["smoke_lip"], 0.85),
                            K["smoke_disabled"], K["smoke_hc"], K["edge_hc"],
                            [(0, K["smoke_pressed_top"]), (1, K["smoke_pressed_bottom"])])}
    for name, (fill, line, shade, flat, hcf, hcl, pressed) in tracks.items():
        svg = Svg(S, S, [23, 23, 23, 24])
        for st in ("normal", "pressed", "disabled"):
            for hc in (False, True):
                b = sunk(svg, "disabled" if st == "disabled" else "normal", hc, 1, 2, S - 2, FH, R,
                         pressed if st == "pressed" else fill, line, shade, flat,
                         hcf if st != "pressed" or name == "track_on" else K["smoke_hc_pressed"], hcl)
                svg.state(st, b, hc=hc)
        out["toggle/%s.svg" % name] = svg.text()

    svg = Svg(38, 40, None)
    for st in ("normal", "pressed", "disabled"):
        for hc in (False, True):
            svg.state(st, knob(svg, st, hc, 19, 19, 18, 2), hc=hc)
    out["toggle/knob.svg"] = svg.text()

    # The slider: a sunk rail, a gold fill, a gold knob.
    svg = Svg(16, 14, [7, 6, 7, 6])
    for st in ("normal", "pressed", "disabled"):
        for hc in (False, True):
            svg.state(st, sunk(svg, "disabled" if st == "disabled" else "normal", hc, 1, 1, 14, 12, 6,
                               [(0, K["rail_top"]), (1, K["rail_bottom"])], K["track_line"], a("#000000", 0.7),
                               K["track_disabled"], HC["glass"], K["edge_hc"], lw=1.2), hc=hc)
    out["slider/track.svg"] = svg.text()

    svg = Svg(16, 14, [7, 6, 7, 6])
    for st in ("normal", "pressed", "disabled"):
        for hc in (False, True):
            b = []
            if hc:
                b.append(rrect(1, 1, 14, 12, 6, K["disabled_hc"] if st == "disabled" else K["gold_hc"]))
                b.append(rrect(2, 2, 12, 10, 5, "none", stroke("#000000", 2)))
            elif st == "disabled":
                b.append(rrect(1, 1, 14, 12, 6, K["knob_disabled"]))
                b.append(rrect(1, 1, 14, 12, 6, "none", stroke(K["disabled_line"], 1.2)))
            else:
                b.append(rrect(1, 1, 14, 12, 6, svg.grad([(0, C["gold_top"]), (0.46, C["gold"]), (1, C["gold_bottom"])])))
                b.append(rrect(4, 2.8, 8, 1.6, 0.8, a("#FFFFFF", 0.7)))
                b.append(foot_shade(svg, 1.8, 1.8, 12.4, 10.4, 5.2, a(C["gold_rim"], 0.5), 1.4))
                b.append(rrect(1, 1, 14, 12, 6, "none", ink(C["ink_line"], 1.2)))
            svg.state(st, b, hc=hc)
    out["slider/fill.svg"] = svg.text()

    svg = Svg(30, 32, None)
    for st in ("normal", "pressed", "disabled"):
        for hc in (False, True):
            svg.state(st, knob(svg, st, hc, 15, 15, 14, 2), hc=hc)
    out["slider/knob.svg"] = svg.text()
    return out


def build_2b(T):
    M = _mats(T)
    svgs = {}
    svgs.update(tab_bar())
    svgs.update(tabs())
    svgs.update(segmented(M))
    svgs.update(chips(M))
    svgs.update(tiles(M))
    svgs.update(controls(T))
    return svgs
