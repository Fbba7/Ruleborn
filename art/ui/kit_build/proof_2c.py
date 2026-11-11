#!/usr/bin/env python3
"""Proofs the kit's batches 2c and 2d (kit_2c.py) at phone size, in both modes.

    python3 art/ui/kit_build/proof_2c.py [--check] [--all]

One still a mode, drawn from the baked atlas as the phone shows it: the
album page with its fact slips, plates and a light bar track; the island's
label on the backdrop; the tags (the plain tag, the warning tag, and the
violet tag beside them) on the dark card and on parchment; and the success
banner under the success button. The gold-edged pill and the muted green are
held out of the atlas (kit_2c.py, HELD), so they are not here.

The gate's value-steps check runs on every interactive control, and each
word is measured against the face or outline under it: 4.5:1 and APCA Lc 60.
The contact sheets hold every batch 2c piece through the gate's tool.
"""
import json
import os
import subprocess
import sys

import proof_kit as pk
from proof_kit import ROOT, rgb
from proof_1b import tint
from proof_2a import Board, inks, FRAME

sys.path.insert(0, os.path.join(ROOT, "tools/ui_gate"))
import checks  # noqa: E402

OUT = os.path.join(os.path.dirname(os.path.abspath(__file__)), "proof_2c")
PIECES = ["panel_dark__album", "panel_dark__fact", "panel_dark__plate", "tag__island_label", "tag__tag",
          "tag__tag_warn", "bar_track__bar_track_light", "success__banner_success"]


def still(hc, atlas):
    b = Board(hc)
    g = pk.grounds(hc)
    white, outline, pink = inks(hc)
    dark = rgb("#000000") if hc else rgb("text_on_gold")
    b.ground(0, FRAME[1], g["backdrop"])
    # The island's label, on the map.
    r = b.put(atlas.draw("tag__island_label__normal", 150, 26), 120, 14, "island label", False)
    b.say("island label words", [r[0], r[1], r[2], 24], "Ember Isle", 13, pink)
    # The album page: fact slips, plates, a light track.
    b.put(atlas.draw("panel_dark__album__normal", 366, 278), 12, 52, "album", False)
    b.say("album title", [24, 62, 342, 32], "Field Notes", 20, pink, display=True)
    for i, (words, sub) in enumerate([("Speed", "12 m/s"), ("Mass", "4 kg")]):
        x = 28 + i * 170
        r = b.put(atlas.draw("panel_dark__fact__normal", 162, 62), x, 102, "fact %d" % i, False)
        b.say("fact %d words" % i, [r[0], r[1] + 4, r[2], 26], words, 14, pink)
        b.say("fact %d value" % i, [r[0], r[1] + 28, r[2], 26], sub, 16, pink)
    for i, words in enumerate(["I", "II", "III", "IV"]):
        x = 28 + i * 84
        r = b.put(atlas.draw("panel_dark__plate__normal", 76, 40), x, 176, "plate %d" % i, False)
        b.say("plate %d words" % i, [r[0], r[1], r[2], 38], words, 14, pink)
    b.put(atlas.draw("bar_track__bar_track_light__normal", 334, 14), 28, 234, "light track", False)
    fill = tint(atlas.draw("bar_fill__box__normal", 190, 14), "#000000" if hc else "#7A4FE0")
    b.put(fill, 28, 234)
    b.say("track words", [28, 256, 334, 26], "7 of 12 found", 14, pink)
    # Tags on parchment (inside the album) and on the dark card.
    for row, (gname, y) in enumerate([("parchment", 286), ("dark card", 346)]):
        if gname == "dark card":
            b.ground(y - 6, 50, g[gname])
        x = 28
        for piece, words, ink, ol in [("tag__tag__normal", "NEW", dark, None),
                                      ("tag__tag_warn__normal", "2h left", dark, None),
                                      ("tag__tag_violet__normal", "Event", white, outline)]:
            w = 30 + 8 * len(words)
            name = "%s on %s" % (piece.split("__")[1], gname)
            r = b.put(atlas.draw(piece, w, 26), x, y + 4 if row else y, name, False)
            b.say(name + " words", [r[0], r[1], r[2], 24], words, 12, ink, ol)
            x += w + 10
    # The success button on the dark card, and the success banner under it.
    b.ground(452, 150, g["dark card"])
    r = b.put(atlas.draw("success__box__normal", 112, 52), 16, 468, "success button", True, role="primary")
    b.say("success button words", [r[0], r[1], r[2], 44], "Claim", 16, white, outline)
    r = b.put(atlas.draw("success__banner_success__normal", 358, 60), 16, 534, "success banner", False)
    b.say("success banner words", [r[0], r[1], r[2], 54], "Reward added to your bag", 15, white, outline)
    return b


def tiles(atlas, mode):
    paths = []
    for n in sorted(n for n in atlas.man["pieces"] if n.rsplit("__", 1)[0] in PIECES):
        p = atlas.man["pieces"][n]
        pic = atlas.draw(n, max(p["w"] / 6, 56), max(p["h"] / 6, 44))
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
        board = still(hc, atlas)
        png = "shapes_%s.png" % mode
        board.im.save(os.path.join(OUT, png))
        data = {"image": png, "frame_pt": list(FRAME), "text_scale": 1.0, "controls": board.controls}
        with open(os.path.join(OUT, "shapes_%s.json" % mode), "w") as f:
            json.dump(data, f, indent=1)
            f.write("\n")
        rows = checks.value_steps(checks.Shot(data, base=OUT)) + board.words
        for r in rows:
            r["mode"], r["still"] = mode, "shapes"
            fails += r["result"] == "FAIL"
        results += rows
        subprocess.run([sys.executable, os.path.join(ROOT, "tools/ui_gate/sheet.py"), "contact",
                        os.path.join(OUT, "contact_2c_%s.png" % mode), *tiles(atlas, mode),
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
