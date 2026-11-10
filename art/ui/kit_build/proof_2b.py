#!/usr/bin/env python3
"""Proofs the kit's batch 2b (kit_2b.py) at phone size, in both modes.

    python3 art/ui/kit_build/proof_2b.py [--check] [--all]

Two stills a mode, drawn from the baked atlas as the phone shows it:
`controls` puts the segmented control on the backdrop (dark track, gold
chosen segment) and on parchment (tray track, leather chosen segment), the
chips in every state on glass and on parchment, the switch on and off and
the slider in every state on the dark card, and the tab bar at the foot with
its chosen tab, a pressed tab and the Heist tab;
`tiles` puts the streak's days and the week's bars on parchment, the reward
tiles (sky and pink, open and locked) on the dark card and on parchment,
and the locked face, normal and pressed.

The gate's value-steps check runs on every interactive control, and each
word is measured against the face or outline under it: 4.5:1 and APCA Lc 60.
The contact sheets hold every batch 2b piece through the gate's tool.
"""
import json
import os
import subprocess
import sys

import proof_kit as pk
from proof_kit import PX, ROOT, rgb
from proof_2a import Board, inks, FRAME

sys.path.insert(0, os.path.join(ROOT, "tools/ui_gate"))
import checks  # noqa: E402

OUT = os.path.join(os.path.dirname(os.path.abspath(__file__)), "proof_2b")
SKINS = ["tab_bar", "tab", "tab_active", "segmented", "segmented_on", "chip", "chip_on", "tile",
         "locked", "toggle", "slider"]
STATES = ["normal", "pressed", "disabled"]


def segmented(b, atlas, x, y, w, light, names, chosen, pressed, hc, white, outline, pink, st="normal"):
    """A segmented control w points wide at (x, y): the track, its segments."""
    track = "segmented__seg_track%s__%s" % ("_light" if light else "", "disabled" if st == "disabled" else "normal")
    b.put(atlas.draw(track, w, 48), x, y)
    sw = (w - 8) / len(names)
    for i, words in enumerate(names):
        sx = x + 4 + i * sw
        if i == chosen:
            r = b.put(atlas.draw("segmented_on__seg_on%s__%s" % ("_light" if light else "", st), sw, 42), sx, y + 3,
                      "segment chosen %s %s" % ("light" if light else "dark", st), st != "disabled",
                      role="primary")
            if st == "disabled":
                ink = rgb("#000000") if hc else rgb("text_on_night" if light else "text_on_gold")
            elif light:
                ink = rgb("#FFFFFF") if hc else rgb("text_on_leather")
            else:
                ink = rgb("#000000") if hc else rgb("text_on_gold")
            b.say("segment chosen words %s %s" % ("light" if light else "dark", st), [r[0], r[1], r[2], 38], words, 14, ink,
                  inactive=st == "disabled")
        else:
            face = "pressed" if i == pressed else st
            r = b.put(atlas.draw("segmented__seg%s__%s" % ("_light" if light else "", face), sw, 40), sx, y + 4)
            ink = rgb("#000000") if hc and st == "disabled" else pink if light else white
            b.say("segment words %s %s %d" % ("light" if light else "dark", st, i), r, words, 14, ink,
                  inactive=st == "disabled")


def chip(b, atlas, piece, x, y, w, words, ink, name, interactive=True, outline=None):
    r = b.put(atlas.draw(piece, w, 48), x, y, name, interactive)
    off = 2 if piece.endswith("pressed") else 0
    b.say(name + " words", [r[0], r[1] + off, r[2], 46], words, 14, ink, outline,
          inactive=piece.endswith("disabled"))
    return r


def controls_still(hc, atlas):
    b = Board(hc)
    g = pk.grounds(hc)
    white, outline, pink = inks(hc)
    gold_ink = rgb("#000000") if hc else rgb("text_on_gold")
    leather_ink = rgb("#FFFFFF") if hc else rgb("text_on_leather")
    b.ground(0, FRAME[1], g["backdrop"])
    # Segmented, dark: every state.
    segmented(b, atlas, 16, 16, 358, False, ["Daily", "Weekly", "Season"], 0, 2, hc, white, outline, pink)
    segmented(b, atlas, 16, 72, 174, False, ["Easy", "Hard"], 1, None, hc, white, outline, pink, "pressed")
    segmented(b, atlas, 200, 72, 174, False, ["Easy", "Hard"], 0, None, hc, white, outline, pink, "disabled")
    # Chips on glass.
    b.ground(130, 122, g["glass"])
    row = [("chip__chip__normal", "All", white, outline), ("chip_on__chip_on__normal", "Motion", gold_ink, None),
           ("chip__chip__pressed", "Time", white, outline), ("chip__chip__disabled", "Life", white, outline)]
    x = 12
    for piece, words, ink, ol in row:
        w = 62 + 8 * len(words)
        if piece.endswith("disabled"):
            ink, ol = (rgb("#000000"), None) if hc else (rgb("text_on_night"), outline)
        chip(b, atlas, piece, x, 138, w, words, ink, "chip " + piece.split("__", 1)[1], not piece.endswith("disabled"), ol)
        x += w + 6
    x = 12
    for piece, words, ink, ol in [("chip__chip__locked", "Spirit", white, outline),
                                  ("chip_on__chip_on__pressed", "Energy", gold_ink, None),
                                  ("chip_on__chip_on__disabled", "Matter", gold_ink, None)]:
        w = 62 + 8 * len(words)
        r = chip(b, atlas, piece, x, 194, w, words, ink, "chip " + piece.split("__", 1)[1],
                 not piece.endswith("disabled"), ol)
        if piece.endswith("locked"):
            b.put(atlas.draw("locked__lock__normal", 16), r[0] + 8, r[1] + 12)
        x += w + 6
    # Parchment: segmented and chips.
    b.ground(252, 232, g["parchment"])
    segmented(b, atlas, 16, 262, 358, True, ["Story", "Laws", "Notes"], 1, 0, hc, white, outline, pink)
    segmented(b, atlas, 16, 316, 174, True, ["Mine", "All"], 0, None, hc, white, outline, pink, "pressed")
    segmented(b, atlas, 200, 316, 174, True, ["Mine", "All"], 0, None, hc, white, outline, pink, "disabled")
    x = 12
    for piece, words, ink in [("chip__chip_light__normal", "All", pink), ("chip_on__chip_on_light__normal", "Motion", leather_ink),
                              ("chip__chip_light__pressed", "Time", pink), ("chip__chip_light__disabled", "Life", pink)]:
        w = 62 + 8 * len(words)
        chip(b, atlas, piece, x, 372, w, words, ink, "chip " + piece.split("__", 1)[1], not piece.endswith("disabled"))
        x += w + 6
    x = 12
    for piece, words, ink, ol in [("chip__chip_light__locked", "Spirit", white, outline),
                                  ("chip_on__chip_on_light__pressed", "Energy", leather_ink, None),
                                  ("chip_on__chip_on_light__disabled", "Matter", leather_ink, None)]:
        w = 62 + 8 * len(words)
        if piece.endswith("disabled") and hc:
            ink = rgb("#000000")
        r = chip(b, atlas, piece, x, 426, w, words, ink, "chip " + piece.split("__", 1)[1],
                 not piece.endswith("disabled"), ol)
        if piece.endswith("locked"):
            b.put(atlas.draw("locked__lock__normal", 16), r[0] + 8, r[1] + 12)
        x += w + 6
    # The dark card: switches and sliders.
    b.ground(484, 270, g["dark card"])
    for j, st in enumerate(STATES):
        for i, on in enumerate((True, False)):
            x, y = 16 + j * 124 , 496 + i * 58
            name = "switch %s %s" % ("on" if on else "off", st)
            r = b.put(atlas.draw("toggle__track_%s__%s" % ("on" if on else "off", st), 92, 48), x, y,
                      name, st != "disabled")
            kx = x + 92 - 4 - 38 if on else x + 4
            b.put(atlas.draw("toggle__knob__%s" % st, 38), kx, y + 5)
            wr = [x + 6, y + 2, 44, 44] if on else [x + 42, y + 2, 44, 44]
            if st == "disabled":
                ink, ol = (rgb("#000000"), None) if hc else (rgb("text_on_night"), outline)
            else:
                ink, ol = white, outline
            b.say(name + " words", wr, "On" if on else "Off", 14, ink, ol, inactive=st == "disabled")
    for j, st in enumerate(STATES):
        y = 622 + j * 40
        b.put(atlas.draw("slider__track__%s" % st, 300, 14), 45, y + 9)
        fw = [180, 120, 220][j]
        b.put(atlas.draw("slider__fill__%s" % st, fw, 14), 45, y + 9)
        b.put(atlas.draw("slider__knob__%s" % st, 30), 45 + fw - 15, y + 1, "slider knob " + st, st != "disabled",
              role="primary")
    # The tab bar at the foot, five tabs: the chosen one, a pressed one, the Heist tab.
    BAR = 86
    b.put(atlas.draw("tab_bar__box__normal", 390, BAR + 8), 0, FRAME[1] - BAR - 8)
    tw = 390 / 5
    for i, words in enumerate(["Home", "Roster", "Heist", "Shop", "Laws"]):
        cx = i * tw + tw / 2
        y = FRAME[1] - BAR + 6
        if i == 1:
            b.put(atlas.draw("tab_active__box__normal", 66, 63), cx - 33, y - 4, "tab chosen", True, role="primary")
        elif i == 3:
            b.put(atlas.draw("tab__tab__pressed", 62, 54), cx - 31, y)
        elif i == 2:
            b.put(atlas.draw("tab__tab_heist__normal", 60, 60), cx - 30, y - 3)
        # A stand-in icon (the icons are the icon batches'): a cream disc in ink.
        from PIL import ImageDraw
        d = ImageDraw.Draw(b.im)
        r_ = 11 * PX
        d.ellipse([cx * PX - r_, (y + 24) * PX - r_, cx * PX + r_, (y + 24) * PX + r_],
                  fill=rgb("#FFFFFF") if hc else rgb("tab_label"), outline=outline, width=round(1.5 * PX))
        b.say("tab words %s" % words, [cx - 36, y + 46, 72, 22], words, 13,
              rgb("#FFFFFF") if hc else rgb("tab_label"), outline)
    return b


def tiles_still(hc, atlas):
    b = Board(hc)
    g = pk.grounds(hc)
    white, outline, pink = inks(hc)
    gold_ink = rgb("#000000") if hc else rgb("text_on_gold")
    b.ground(0, FRAME[1], g["backdrop"])
    # A parchment panel with the streak's seven days.
    b.put(atlas.draw("panel_parchment__box__normal", 374, 190), 8, 12)
    b.say("streak title", [20, 22, 350, 30], "Day 4 of 7", 20, pink, display=True)
    # The days show the streak and are not pressed (the claim button is the
    # control), so they are not held to the value steps: today is cream in a
    # gold ring on parchment, as the designs have it.
    for i in range(7):
        kind = "day_done" if i < 3 else "day_today" if i == 3 else "day_later"
        x = 22 + i * 50
        r = b.put(atlas.draw("tile__%s__normal" % kind, 44, 52), x, 62, "day %d %s" % (i + 1, kind), False)
        ink = gold_ink if kind == "day_done" else pink
        yo = 3 if kind == "day_later" else 0
        b.say("day %d words" % (i + 1), [r[0], r[1] + yo, 44, 46], str(i + 1), 18, ink)
    # The week's bars, standing on a line.
    for i, h in enumerate([34, 52, 26, 60, 44, 16, 16]):
        x = 40 + i * 46
        if i == 4:
            b.put(atlas.draw("tile__week_today__normal", 38, h + 10), x - 5, 184 - h - 5)
        else:
            b.put(atlas.draw("tile__week_day__normal", 28, h), x, 184 - h)
    # Reward tiles on the dark card, then on parchment. A reward tile's face
    # is parchment, so on parchment only its locked face is shown: the designs
    # put the tiles on dark grounds (the result screen, the season's track).
    for row, gname in enumerate(["dark card", "parchment"]):
        y0 = 214 + row * 212
        b.ground(y0, 204, g[gname])
        for i, (kind, st) in enumerate([("reward_sky", "normal"), ("reward_pink", "normal"),
                                        ("reward_sky", "locked"), ("reward_pink", "locked")]):
            x = 10 + i * 94
            if gname == "parchment" and st == "normal":
                continue
            r = b.put(atlas.draw("tile__%s__%s" % (kind, st), 88, 104), x, y0 + 8,
                      "%s %s on %s" % (kind, st, gname), True)
            if st == "locked":
                b.put(atlas.draw("locked__lock__normal", 24), x + 32, y0 + 30)
                b.say("%s locked words %s" % (kind, gname), [x + 3, y0 + 62, 82, 24], "Lv 9", 14, white, outline)
            else:
                b.say("%s words %s" % (kind, gname), [x + 3, y0 + 62, 82, 24], "x250", 16, pink)
        # The locked face: normal, pressed, with the lock.
        for i, st in enumerate(["normal", "pressed"]):
            x = 16 + i * 120
            r = b.put(atlas.draw("locked__locked__%s" % st, 108, 76), x, y0 + 120,
                      "locked %s on %s" % (st, gname), True)
            off = 3 if st == "pressed" else 0
            b.put(atlas.draw("locked__lock__normal", 20), x + 12, y0 + 142 + off)
            b.say("locked %s words %s" % (st, gname), [x + 30, y0 + 122 + off, 74, 66], "Locked", 14, white, outline)
    return b


def tiles(atlas, mode):
    paths = []
    for n in sorted(n for n in atlas.man["pieces"] if n.split("__")[0] in SKINS and n != "locked__lock__normal"):
        p = atlas.man["pieces"][n]
        w_pt = p["w"] / 6
        pic = atlas.draw(n, max(w_pt, 56) if p.get("slice") else w_pt,
                         max(p["h"] / 6, 44) if p.get("slice") else None)
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
        for still, fn in (("controls", controls_still), ("tiles", tiles_still)):
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
                        os.path.join(OUT, "contact_2b_%s.png" % mode), *tiles(atlas, mode),
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
