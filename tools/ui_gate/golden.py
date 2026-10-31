#!/usr/bin/env python3
"""The golden set: its images, built from items.json, and the check on it and
on labels.md, the labelling form (section 3.6 of docs/art/ui-quality/report.md;
gate/golden/README.md).

    golden.py build [--only id,id]
        Writes gate/golden/images/<id>.png for every item: its source, cropped,
        and for a planted item the copy with one quality broken.
    golden.py labels [--force]
        Writes labels.md's empty form, one row per item and quality. It
        refuses to overwrite a form that exists unless --force.
    golden.py check
        Checks items.json (ids, classes, qualities, sources, the share of
        expected fails and borderline items), that every image exists at the
        size its crop gives, and that labels.md has exactly one row per item
        and quality, each label empty, pass, fail or n/a.
    golden.py --self-test
        The plants' tests: each breaks what it says and nothing else.

Every image is made the same way from the same sources.
"""
import json
import pathlib
import re
import sys

import numpy as np
from PIL import Image, ImageDraw, ImageFont

ROOT = pathlib.Path(__file__).resolve().parents[2]
GOLDEN = ROOT / "docs/art/ui-quality/gate/golden"
ITEMS = GOLDEN / "items.json"
LABELS = GOLDEN / "labels.md"
FONT = ROOT / "client/ui/fonts/manrope/Manrope-Variable.ttf"

# The judged qualities of each asset class (gate/rubric.md, "The method at
# a glance").
CLASSES = {
    "screen": [1, 2, 3, 6, 8, 9, 13, 14],
    "kit art": [1, 2, 8, 13],
    "icon": [1, 3, 8, 13],
}
QUALITY_NAMES = {
    1: "Layered materials", 2: "Display type", 3: "Painted or rendered icons",
    6: "Hierarchy", 8: "Colour roles and value", 9: "Character presence",
    13: "Light behind UI", 14: "One art-direction idea",
}
LABEL_VALUES = {"", "pass", "fail", "n/a"}


# ---------------------------------------------------------------- the plants

def flatten(im, colours):
    """A material flattened: the image cut to a few flat colours, so its
    gradients, gloss, grain and soft drops go (qualities 1 and 3)."""
    rgb = im.convert("RGB").quantize(colours, method=Image.Quantize.MEDIANCUT,
                                     dither=Image.Dither.NONE, kmeans=4)
    return rgb.convert("RGB")


def low_value(im, keep):
    """Value range squeezed toward its middle grey: keep 0.35 leaves about
    one value step where there were three (quality 8)."""
    a = np.asarray(im.convert("RGB")).astype(np.float64)
    mid = np.median(a.reshape(-1, 3), axis=0)
    out = mid + (a - mid) * keep
    return Image.fromarray(np.clip(out + 0.5, 0, 255).astype(np.uint8))


def hue_mirror(im):
    """Colour roles broken: hue mirrored about yellow, so red and green swap
    and gold, violet and the skies all move (quality 8)."""
    hsv = np.asarray(im.convert("RGB").convert("HSV")).copy()
    h = hsv[..., 0].astype(np.int32)
    hsv[..., 0] = ((85 - h) % 256).astype(np.uint8)  # 85 of 256 is green
    return Image.fromarray(hsv, "HSV").convert("RGB")


def unstroked(im, labels):
    """Labels in thin body type, without outline or drop, laid over the art
    (quality 2). labels: [[x, y, size, text], ...] in pixels of the image."""
    out = im.convert("RGB").copy()
    draw = ImageDraw.Draw(out)
    for x, y, size, text in labels:
        font = ImageFont.truetype(str(FONT), size)
        draw.text((x, y), text, fill=(255, 255, 255), font=font)
    return out


PLANTS = {
    "flatten": lambda im, p: flatten(im, p["colours"]),
    "low_value": lambda im, p: low_value(im, p["keep"]),
    "hue_mirror": lambda im, p: hue_mirror(im),
    "unstroked": lambda im, p: unstroked(im, p["labels"]),
}


# ---------------------------------------------------------------- build

def load():
    return json.loads(ITEMS.read_text())


def by_id(data):
    return {it["id"]: it for it in data["items"]}


def render(item, items):
    """The item's image: its source cropped, then its plant if any. A planted
    item's source may be another item's id."""
    src = item["source"]
    if src in items:
        im = render(items[src], items)
    else:
        im = Image.open(ROOT / src).convert("RGB")
    if item.get("crop"):
        im = im.crop(tuple(item["crop"]))
    plant = item.get("plant")
    if plant:
        im = PLANTS[plant["kind"]](im, plant)
    return im


def build(only=None):
    data = load()
    items = by_id(data)
    (GOLDEN / "images").mkdir(parents=True, exist_ok=True)
    for it in data["items"]:
        if only and it["id"] not in only:
            continue
        render(it, items).save(GOLDEN / it["image"], optimize=True)
        print(it["image"])


# ---------------------------------------------------------------- labels

def rows(data):
    for it in data["items"]:
        for q in it["qualities"]:
            yield it["id"], q


def labels(force=False):
    if LABELS.exists() and not force:
        sys.exit(f"{LABELS} exists; --force overwrites the labels in it")
    data = load()
    head = (GOLDEN / "labels-head.md").read_text()
    lines = [head.rstrip("\n"), "",
             "| Item | Quality | Label | Critique |", "|---|---|---|---|"]
    for iid, q in rows(data):
        lines.append(f"| {iid} | {q}. {QUALITY_NAMES[q]} |  |  |")
    LABELS.write_text("\n".join(lines) + "\n")
    print(LABELS)


ROW = re.compile(r"^\| ([a-z0-9-]+) \| (\d+)\. [^|]+\| ([^|]*)\| ([^|]*)\|$")


def read_labels(text):
    out = []
    for line in text.splitlines():
        m = ROW.match(line)
        if m:
            out.append((m[1], int(m[2]), m[3].strip(), m[4].strip()))
    return out


# ---------------------------------------------------------------- check

def problems(data, label_text, images=True):
    bad = []
    ids = [it["id"] for it in data["items"]]
    if len(set(ids)) != len(ids):
        bad.append("duplicate item ids")
    items = by_id(data)
    for it in data["items"]:
        iid = it["id"]
        if not re.fullmatch(r"[a-z0-9-]+", iid):
            bad.append(f"{iid}: id is not lower-case words and hyphens")
        if it["class"] not in CLASSES:
            bad.append(f"{iid}: unknown class {it['class']}")
            continue
        if not set(it["qualities"]) <= set(CLASSES[it["class"]]):
            bad.append(f"{iid}: a quality the class {it['class']} is not judged on")
        if it["expected"] not in ("pass", "fail") or not isinstance(it["borderline"], bool):
            bad.append(f"{iid}: expected must be pass or fail, borderline true or false")
        if it["origin"] not in ("natural", "planted"):
            bad.append(f"{iid}: origin must be natural or planted")
        if (it["origin"] == "planted") != bool(it.get("plant")):
            bad.append(f"{iid}: a planted item, and only one, has a plant")
        if it.get("plant") and it["plant"]["kind"] not in PLANTS:
            bad.append(f"{iid}: unknown plant {it['plant']['kind']}")
        if it.get("plant") and it["plant"]["breaks"] not in it["qualities"]:
            bad.append(f"{iid}: the quality its plant breaks is not labelled")
        src = it["source"]
        if src not in items and not (ROOT / src).is_file():
            bad.append(f"{iid}: source {src} not found")
        if it["image"] != f"images/{iid}.png":
            bad.append(f"{iid}: image must be images/{iid}.png")
        elif images:
            path = GOLDEN / it["image"]
            if not path.is_file():
                bad.append(f"{iid}: {it['image']} missing (golden.py build)")
            elif it.get("crop"):
                x0, y0, x1, y1 = it["crop"]
                if Image.open(path).size != (x1 - x0, y1 - y0):
                    bad.append(f"{iid}: image size differs from its crop")
    n = len(ids)
    fails = sum(it["expected"] == "fail" for it in data["items"])
    border = sum(it["borderline"] for it in data["items"])
    if n < 30:
        bad.append(f"{n} items; 30 or more needed")
    if 3 * fails < n:
        bad.append(f"{fails} of {n} expected to fail; a third needed")
    if 4 * border < n:
        bad.append(f"{border} of {n} borderline; a quarter needed")
    want = list(rows(data))
    got = read_labels(label_text)
    if [(i, q) for i, q, _, _ in got] != want:
        bad.append("labels.md's rows differ from items.json's items and "
                   "qualities, in order (golden.py labels --force rewrites the form)")
    for i, q, lab, _ in got:
        if lab not in LABEL_VALUES:
            bad.append(f"labels.md {i} quality {q}: label {lab!r} is not pass, fail or n/a")
    return bad


def check():
    bad = problems(load(), LABELS.read_text())
    for b in bad:
        print("golden:", b)
    if bad:
        sys.exit(1)
    data = load()
    print(f"golden: ok, {len(data['items'])} items, "
          f"{sum(1 for _ in rows(data))} label rows")


# ---------------------------------------------------------------- self-test

def self_test():
    rng = np.random.default_rng(7)
    y = np.linspace(40, 220, 64)[:, None, None]
    grad = np.clip(y + rng.normal(0, 6, (64, 64, 3)), 0, 255).astype(np.uint8)
    im = Image.fromarray(grad)
    assert len(np.unique(np.asarray(flatten(im, 4)).reshape(-1, 3), axis=0)) <= 4
    a = np.asarray(im).astype(float)
    b = np.asarray(low_value(im, 0.35)).astype(float)
    assert abs((b.max() - b.min()) - 0.35 * (a.max() - a.min())) < 3
    red = Image.new("RGB", (4, 4), (220, 40, 40))
    r, g, _ = np.asarray(hue_mirror(red))[0, 0]
    assert g > r, "red should become green"
    plain = Image.new("RGB", (120, 40), (40, 30, 60))
    out = np.asarray(unstroked(plain, [[4, 4, 20, "Vault"]]))
    assert out.max() > 200, "the label is drawn"
    # The check finds what is missing.
    data = {"items": [{"id": "a", "class": "icon", "qualities": [3],
                       "expected": "pass", "borderline": False,
                       "origin": "natural", "source": "README.md",
                       "image": "images/a.png"}]}
    bad = problems(data, "| a | 3. Painted or rendered icons | maybe |  |", images=False)
    assert any("30 or more" in b for b in bad)
    assert any("a third" in b for b in bad)
    assert any("'maybe'" in b for b in bad)
    print("ui_gate golden self-test: ok")


def main(argv):
    if argv[:1] == ["--self-test"]:
        self_test()
    elif argv[:1] == ["build"]:
        only = None
        if "--only" in argv:
            only = set(argv[argv.index("--only") + 1].split(","))
        build(only)
    elif argv[:1] == ["labels"]:
        labels("--force" in argv)
    elif argv[:1] == ["check"]:
        check()
    else:
        print(__doc__)
        return 2
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
