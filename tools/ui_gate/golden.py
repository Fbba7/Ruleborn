#!/usr/bin/env python3
"""The golden set: its images, built from items.json, and the check on it and
on labels.md, the labelling form (section 3.6 of docs/art/ui-quality/report.md;
gate/golden/README.md).

    golden.py build [--only id,id]
        Writes gate/golden/images/<id>.png for every item: its source, cropped,
        and for a planted item the copy with one quality broken.
    golden.py labels [--force]
        Writes labels.md's empty form, one row per item and quality, and
        labels-blind.md's, the held-out third's rows only (the items whose
        "third" is 3). It refuses to overwrite a form that exists unless
        --force.
    golden.py split
        Sets each item's "third" (1, 2 or 3; 3 is held out): the items sorted
        by class, label, borderline flag and origin, then dealt in turn, so
        each third holds its share of each. Only version 1 items are dealt
        into the held-out third; an item a later version joined
        ("golden_version" 2 or more) is dealt into third 1 or 2, so the
        held-out third stays the one measured before.
    golden.py check
        Checks items.json (ids, classes, qualities, sources, the share of
        expected fails and borderline items, the thirds: the held-out third
        is about a third of the version 1 items and holds no later item),
        that every image
        exists at the size its crop and size give, and that labels.md (and
        labels-blind.md, the held-out third) has exactly one row per item and
        quality, each label empty, pass, fail or n/a.
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
BLIND = GOLDEN / "labels-blind.md"
HELD_OUT = 3
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


def sink(im, rect, keep, ring=10):
    """One control sunk into its ground: the pixels inside rect pulled toward
    the median colour of a ring around it, so keep 0.35 leaves about one
    value step between control and ground where there were three
    (quality 8). rect: [x0, y0, x1, y1] in pixels of the image."""
    a = np.asarray(im.convert("RGB")).astype(np.float64)
    h, w = a.shape[:2]
    x0, y0, x1, y1 = rect
    outer = np.zeros((h, w), bool)
    outer[max(0, y0 - ring):min(h, y1 + ring), max(0, x0 - ring):min(w, x1 + ring)] = True
    outer[y0:y1, x0:x1] = False
    ground = np.median(a[outer], axis=0)
    a[y0:y1, x0:x1] = ground + (a[y0:y1, x0:x1] - ground) * keep
    return Image.fromarray(np.clip(a + 0.5, 0, 255).astype(np.uint8))


PLANTS = {
    "flatten": lambda im, p: flatten(im, p["colours"]),
    "low_value": lambda im, p: low_value(im, p["keep"]),
    "hue_mirror": lambda im, p: hue_mirror(im),
    "unstroked": lambda im, p: unstroked(im, p["labels"]),
    "sink": lambda im, p: sink(im, p["rect"], p["keep"]),
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
    if item.get("size"):
        im = im.resize(tuple(item["size"]), Image.Resampling.LANCZOS)
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


def blind_rows(data):
    for it in data["items"]:
        if it.get("third") == HELD_OUT:
            for q in it["qualities"]:
                yield it["id"], q


def labels(force=False):
    data = load()
    for path, head, want in ((LABELS, "labels-head.md", rows(data)),
                             (BLIND, "labels-blind-head.md", blind_rows(data))):
        if path.exists() and not force:
            sys.exit(f"{path} exists; --force overwrites the labels in it")
        text = (GOLDEN / head).read_text()
        lines = [text.rstrip("\n"), "",
                 "| Item | Quality | Label | Critique |", "|---|---|---|---|"]
        for iid, q in want:
            lines.append(f"| {iid} | {q}. {QUALITY_NAMES[q]} |  |  |")
        path.write_text("\n".join(lines) + "\n")
        print(path)


def version(it):
    """The golden set version that joined the item (1 when not written)."""
    return it.get("golden_version", 1)


def split():
    """Deal the items into thirds, stratified, and write items.json. Version 1
    items go into all three; later items only into thirds 1 and 2."""
    data = load()
    for first, deal in ((True, 3), (False, 2)):
        order = sorted((it for it in data["items"] if (version(it) == 1) == first),
                       key=lambda it: (it["class"], it["expected"], it["borderline"],
                                       it["origin"], it["id"]))
        for n, it in enumerate(order):
            it["third"] = n % deal + 1
    ITEMS.write_text(json.dumps(data, indent=1, ensure_ascii=False) + "\n")
    for t in (1, 2, 3):
        print(f"third {t}: {sum(it['third'] == t for it in data['items'])} items")


ROW = re.compile(r"^\| ([a-z0-9-]+) \| (\d+)\. [^|]+\| ([^|]*)\| ([^|]*)\|$")


def read_labels(text):
    out = []
    for line in text.splitlines():
        m = ROW.match(line)
        if m:
            out.append((m[1], int(m[2]), m[3].strip(), m[4].strip()))
    return out


# ---------------------------------------------------------------- check

def problems(data, label_text, images=True, blind_text=None):
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
            elif it.get("size"):
                if Image.open(path).size != tuple(it["size"]):
                    bad.append(f"{iid}: image size differs from its size")
            elif it.get("crop"):
                x0, y0, x1, y1 = it["crop"]
                if Image.open(path).size != (x1 - x0, y1 - y0):
                    bad.append(f"{iid}: image size differs from its crop")
        if it.get("third") not in (1, 2, 3):
            bad.append(f"{iid}: third must be 1, 2 or 3 (golden.py split)")
        if not isinstance(version(it), int) or version(it) < 1:
            bad.append(f"{iid}: golden_version must be a whole number from 1")
        elif version(it) > 1 and it.get("third") == HELD_OUT:
            bad.append(f"{iid}: joined in version {version(it)}, so it cannot be "
                       "in the held-out third")
    n = len(ids)
    fails = sum(it["expected"] == "fail" for it in data["items"])
    border = sum(it["borderline"] for it in data["items"])
    if n < 30:
        bad.append(f"{n} items; 30 or more needed")
    if 3 * fails < n:
        bad.append(f"{fails} of {n} expected to fail; a third needed")
    if 4 * border < n:
        bad.append(f"{border} of {n} borderline; a quarter needed")
    held = [it for it in data["items"] if it.get("third") == HELD_OUT]
    n1 = sum(version(it) == 1 for it in data["items"])
    if n >= 30 and not (n1 // 3 <= len(held) <= n1 // 3 + 1):
        bad.append(f"{len(held)} items held out; a third of the {n1} version 1 "
                   "items needed")
    for what, test in (("an expected fail", lambda it: it["expected"] == "fail"),
                       ("a borderline item", lambda it: it["borderline"]),
                       ("a planted item", lambda it: it["origin"] == "planted")):
        if n >= 30 and not any(test(it) for it in held):
            bad.append(f"the held-out third has no {what}")
    if blind_text is not None:
        got = [(i, q) for i, q, _, _ in read_labels(blind_text)]
        if got != list(blind_rows(data)):
            bad.append("labels-blind.md's rows differ from the held-out third's "
                       "items and qualities (golden.py labels --force)")
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
    # The blind labels are part of the golden set: a missing file fails the
    # check instead of skipping its rows' comparison (FX1-T-18).
    if not BLIND.exists():
        print(f"golden: {BLIND.name} is missing; the held-out third's blind labels "
              "are part of the golden set")
        sys.exit(1)
    bad = problems(load(), LABELS.read_text(), blind_text=BLIND.read_text())
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
    # A later item may not be held out, and the held-out share counts
    # version 1 items only.
    base = {"class": "icon", "qualities": [3], "expected": "fail",
            "borderline": True, "origin": "planted",
            "plant": {"kind": "flatten", "breaks": 3}, "source": "README.md"}
    many = [dict(base, id=f"i{k}", image=f"images/i{k}.png",
                 third=3 if k < 10 else 1) for k in range(30)]
    many += [dict(base, id=f"j{k}", image=f"images/j{k}.png", golden_version=2,
                  third=1 + k % 2) for k in range(12)]
    form = "\n".join(f"| {it['id']} | 3. Painted or rendered icons | fail |  |"
                     for it in many)
    assert problems({"items": many}, form, images=False) == []
    many[-1]["third"] = 3
    bad = problems({"items": many}, form, images=False)
    assert any("cannot be in the held-out third" in b for b in bad)
    card = Image.new("RGB", (60, 40), (30, 20, 60))
    ImageDraw.Draw(card).rectangle((20, 10, 39, 29), fill=(240, 200, 80))
    sunk = np.asarray(sink(card, [20, 10, 40, 30], 0.35)).astype(float)
    want = np.array([30, 20, 60]) + 0.35 * np.array([210, 180, 20])
    assert abs(sunk[20, 30] - want).max() < 1.5, "the control keeps a third of its contrast"
    assert (sunk[2, 2] == (30, 20, 60)).all(), "the ground is left alone"
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
    elif argv[:1] == ["split"]:
        split()
    elif argv[:1] == ["check"]:
        check()
    else:
        print(__doc__)
        return 2
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
