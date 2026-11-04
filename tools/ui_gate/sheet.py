#!/usr/bin/env python3
"""The pictures the gate's judge and the owner's boards look at (section 3.5
of docs/art/ui-quality/report.md; gate/rubric.md, "The method at a glance").

    sheet.py still <in.png> <out.png> [--long 960] [--gray]
        A screen still at 960 px on its long edge; --gray gives its grayscale
        (§21.10's squint: the same L*, the colour removed).
    sheet.py contact <out.png> <icon.png>... [--sizes 48,96] [--ground #hex]
        A contact sheet at phone size: each image drawn at each size in
        points at the phone's density (1080 px over 390 pt), in colour and in
        grayscale, on the given ground.
    sheet.py strip <out.png> <frame.png>... [--height 480] [--every 1]
        A frame strip: the frames side by side at one height, numbered.
    sheet.py crops <shot.json> <out-dir> [--names a,b] [--margin 8]
        Full-resolution crops of a shot's named control rectangles, with a
        margin in points (gate/shots.md).
    sheet.py cvd <in.png> <out.png> [--long 720]
        The colour-blindness sheet: the still beside its protanopia,
        deuteranopia and tritanopia simulations (quality 8).
    sheet.py --self-test
        The tests of this file, colour.py and checks.py, golden.py's tests
        and check, and calibrate.py's tests.

Every output is a PNG, made the same way from the same input.
"""
import argparse
import pathlib
import sys

import numpy as np
from PIL import Image, ImageDraw, ImageFont

sys.path.insert(0, str(pathlib.Path(__file__).resolve().parent))
import checks  # noqa: E402
import colour  # noqa: E402

PX_PER_PT = 1080 / 390  # §21.1's frame, drawn at 1080 x 2340
GAP = 16
LABEL_H = 22
INK = (20, 18, 26)
PAPER = (236, 232, 224)
CVD_KINDS = ("protanopia", "deuteranopia", "tritanopia")


def _font():
    return ImageFont.load_default()


def flatten(im, ground=(0, 0, 0)):
    """RGB, with any transparency laid over the ground."""
    if im.mode == "RGB":
        return im
    rgba = im.convert("RGBA")
    out = Image.new("RGB", rgba.size, ground)
    out.paste(rgba, mask=rgba.getchannel("A"))
    return out


def gray(im):
    return Image.fromarray(colour.grayscale(np.asarray(flatten(im))))


def fit_long(im, long):
    w, h = im.size
    k = long / max(w, h)
    return im.resize((max(1, round(w * k)), max(1, round(h * k))), Image.LANCZOS)


def still(im, long=960, as_gray=False):
    out = fit_long(flatten(im), long)
    return gray(out) if as_gray else out


def _label(draw, xy, text, fill=INK):
    draw.text(xy, text, fill=fill, font=_font())


def contact(images, sizes=(48, 96), ground=(64, 58, 76), names=None):
    """Rows: each size in colour, then each size in grayscale; one column per
    image. Each cell is the image fitted into a square of the size in points
    at phone density, at native resolution for that size."""
    names = names or [f"{i + 1}" for i in range(len(images))]
    cells = [round(s * PX_PER_PT) for s in sizes]
    col_w = max(cells) + GAP
    rows = [(s, c, g) for g in (False, True) for s, c in zip(sizes, cells)]
    width = GAP + 90 + col_w * len(images)
    height = LABEL_H + sum(c + GAP for _, c, _ in rows) + GAP
    sheet = Image.new("RGB", (width, height), PAPER)
    d = ImageDraw.Draw(sheet)
    for i, n in enumerate(names):
        _label(d, (GAP + 90 + i * col_w, 4), n[:24])
    y = LABEL_H
    for size, cell, as_gray in rows:
        _label(d, (GAP, y + cell // 2 - 6), f"{size} pt" + (" gray" if as_gray else ""))
        for i, im in enumerate(images):
            rgba = im.convert("RGBA")
            k = cell / max(rgba.size)
            rgba = rgba.resize((max(1, round(rgba.width * k)), max(1, round(rgba.height * k))),
                               Image.LANCZOS)
            tile = Image.new("RGB", (cell, cell), ground)
            tile.paste(rgba, ((cell - rgba.width) // 2, (cell - rgba.height) // 2),
                       mask=rgba.getchannel("A"))
            if as_gray:
                tile = gray(tile)
            sheet.paste(tile, (GAP + 90 + i * col_w, y))
        y += cell + GAP
    return sheet


def strip(frames, height=480, every=1):
    picked = list(enumerate(frames))[::every]
    tiles = []
    for i, im in picked:
        im = flatten(im)
        k = height / im.height
        tiles.append((i, im.resize((max(1, round(im.width * k)), height), Image.LANCZOS)))
    width = GAP + sum(t.width + GAP for _, t in tiles)
    sheet = Image.new("RGB", (width, height + LABEL_H + GAP), PAPER)
    d = ImageDraw.Draw(sheet)
    x = GAP
    for i, t in tiles:
        sheet.paste(t, (x, LABEL_H))
        _label(d, (x, 4), f"frame {i}")
        x += t.width + GAP
    return sheet


def crops(shot, names=None, margin=8.0):
    """{name: full-resolution crop} of the shot's control rectangles."""
    im = flatten(shot.image())
    s = shot.scale()
    out = {}
    for c in shot.controls:
        if names and c["name"] not in names:
            continue
        x, y, w, h = c["rect"]
        box = (max(0, round((x - margin) * s)), max(0, round((y - margin) * s)),
               min(im.width, round((x + w + margin) * s)), min(im.height, round((y + h + margin) * s)))
        if box[2] > box[0] and box[3] > box[1]:
            out[c["name"]] = im.crop(box)
    missing = set(names or ()) - set(out)
    if missing:
        raise SystemExit(f"no rectangle in the still for: {', '.join(sorted(missing))}")
    return out


def cvd(im, long=720):
    base = still(im, long)
    arr = np.asarray(base)
    panels = [("original", base)] + [
        (k, Image.fromarray(colour.simulate(arr, k))) for k in CVD_KINDS]
    w, h = base.size
    sheet = Image.new("RGB", (GAP + 2 * (w + GAP), GAP + 2 * (h + LABEL_H + GAP)), PAPER)
    d = ImageDraw.Draw(sheet)
    for n, (name, p) in enumerate(panels):
        x = GAP + (n % 2) * (w + GAP)
        y = GAP + (n // 2) * (h + LABEL_H + GAP)
        _label(d, (x, y + 4), name)
        sheet.paste(p, (x, y + LABEL_H))
    return sheet


def _hex(s):
    s = s.lstrip("#")
    return tuple(int(s[i:i + 2], 16) for i in (0, 2, 4))


# ---------------------------------------------------------------- self-test

def self_test():
    checks.self_test()  # colour.py's too
    rng = np.random.default_rng(3)
    photo = Image.fromarray(rng.integers(0, 256, size=(2340, 1080, 3), dtype=np.uint8))

    s = still(photo)
    assert s.size == (443, 960), s.size
    g = still(photo, as_gray=True)
    a = np.asarray(g)
    assert (a[..., 0] == a[..., 1]).all() and (a[..., 1] == a[..., 2]).all()
    assert still(Image.new("RGB", (2340, 1080)), 960).size == (960, 443)

    # A transparent icon: a red disc. Its cells are the right size, its
    # grayscale cells are grey, and the disc's centre keeps its L*.
    icon = Image.new("RGBA", (512, 512), (0, 0, 0, 0))
    ImageDraw.Draw(icon).ellipse((56, 56, 456, 456), fill=(220, 40, 40, 255))
    sheet = contact([icon, icon.rotate(45)], sizes=(48, 96), ground=(64, 58, 76), names=["a", "b"])
    c48, c96 = round(48 * PX_PER_PT), round(96 * PX_PER_PT)
    assert (c48, c96) == (133, 266)
    assert sheet.size == (GAP + 90 + 2 * (c96 + GAP), LABEL_H + 2 * (c48 + c96 + 2 * GAP) + GAP)
    arr = np.asarray(sheet)
    y48, x = LABEL_H + c48 // 2, GAP + 90 + c48 // 2
    assert tuple(arr[y48, x]) == (220, 40, 40), arr[y48, x]
    yg = LABEL_H + c48 + GAP + c96 + GAP + c48 // 2
    px = arr[yg, x]
    assert px[0] == px[1] == px[2]
    assert abs(colour.lightness(px) - colour.lightness(np.array([220, 40, 40]))) < 0.5
    corner = arr[LABEL_H + 1, GAP + 90 + 1]
    assert tuple(corner) == (64, 58, 76), corner

    frames = [Image.new("RGB", (1080, 2340), (i * 40, 0, 0)) for i in range(5)]
    st = strip(frames, height=200, every=2)
    w200 = round(1080 * 200 / 2340)
    assert st.size == (GAP + 3 * (w200 + GAP), 200 + LABEL_H + GAP), st.size
    assert tuple(np.asarray(st)[LABEL_H + 100, GAP + 2 * (w200 + GAP) + 5]) == (160, 0, 0)

    shot = checks.Shot({"image": "-", "controls": [
        {"name": "go", "rect": [100, 700, 190, 80]},
        {"name": "edge", "rect": [380, 0, 40, 40]}]}, image=photo)
    cs = crops(shot, margin=8)
    k = PX_PER_PT
    assert cs["go"].size == (round(298 * k) - round(92 * k), round(788 * k) - round(692 * k))
    assert cs["edge"].size[0] == 1080 - round(372 * k)  # clipped at the still's edge
    full = np.asarray(photo)[round(692 * k):round(788 * k), round(92 * k):round(298 * k)]
    assert (np.asarray(cs["go"]) == full).all()  # full resolution: not resampled
    try:
        crops(shot, names=["missing"])
        raise AssertionError("a missing name must fail")
    except SystemExit:
        pass

    # The colour-blindness sheet: four panels; red and green of one
    # luminance stay apart as drawn and meet in the deuteranopia panel.
    rg = Image.new("RGB", (400, 200), (255, 0, 0))
    rg.paste((0, 148, 0), (200, 0, 400, 200))
    sh = cvd(rg, long=400)
    assert sh.size == (GAP + 2 * (400 + GAP), GAP + 2 * (200 + LABEL_H + GAP))
    arr = np.asarray(sh)

    def pair(n):
        x = GAP + (n % 2) * (400 + GAP)
        y = GAP + (n // 2) * (200 + LABEL_H + GAP) + LABEL_H + 100
        lab = colour.lab(np.array([arr[y, x + 100], arr[y, x + 300]]))
        return np.linalg.norm(lab[0] - lab[1])
    assert pair(0) > 100 and pair(2) < 25 and pair(1) < 25 and pair(3) > 60
    print("ui_gate sheet self-test: ok")
    import golden  # the golden set's plants, and its items, images and form
    golden.self_test()
    golden.check()
    import calibrate  # the judge's calibration: the sampling rule, rates, anchors, audit
    calibrate.self_test()


def main(argv):
    if argv[:1] == ["--self-test"]:
        self_test()
        return 0
    p = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    sub = p.add_subparsers(dest="cmd", required=True)
    a = sub.add_parser("still")
    a.add_argument("src")
    a.add_argument("out")
    a.add_argument("--long", type=int, default=960)
    a.add_argument("--gray", action="store_true")
    a = sub.add_parser("contact")
    a.add_argument("out")
    a.add_argument("images", nargs="+")
    a.add_argument("--sizes", default="48,96")
    a.add_argument("--ground", default="#403A4C")
    a = sub.add_parser("strip")
    a.add_argument("out")
    a.add_argument("frames", nargs="+")
    a.add_argument("--height", type=int, default=480)
    a.add_argument("--every", type=int, default=1)
    a = sub.add_parser("crops")
    a.add_argument("shot")
    a.add_argument("out_dir")
    a.add_argument("--names", default="")
    a.add_argument("--margin", type=float, default=8.0)
    a = sub.add_parser("cvd")
    a.add_argument("src")
    a.add_argument("out")
    a.add_argument("--long", type=int, default=720)
    args = p.parse_args(argv)

    if args.cmd == "still":
        still(Image.open(args.src), args.long, args.gray).save(args.out)
    elif args.cmd == "contact":
        ims = [Image.open(f) for f in args.images]
        sizes = tuple(int(x) for x in args.sizes.split(","))
        contact(ims, sizes, _hex(args.ground), [pathlib.Path(f).stem for f in args.images]).save(args.out)
    elif args.cmd == "strip":
        strip([Image.open(f) for f in args.frames], args.height, args.every).save(args.out)
    elif args.cmd == "crops":
        out = pathlib.Path(args.out_dir)
        out.mkdir(parents=True, exist_ok=True)
        names = [n for n in args.names.split(",") if n] or None
        for name, im in crops(checks.Shot.load(args.shot), names, args.margin).items():
            im.save(out / f"{name}.png")
    elif args.cmd == "cvd":
        cvd(Image.open(args.src), args.long).save(args.out)
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
