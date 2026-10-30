#!/usr/bin/env python3
"""The gate's image checks (section 3.5 of docs/art/ui-quality/report.md;
gate/rubric.md, qualities 6, 8 and 12). Each reads a shot: a still and its
control rectangles, in the format of docs/art/ui-quality/gate/shots.md.

    python3 tools/ui_gate/checks.py value-steps <shot.json>
    python3 tools/ui_gate/checks.py hud-share <shot.json>
    python3 tools/ui_gate/checks.py hierarchy <shot.json>
    python3 tools/ui_gate/checks.py all <shot.json>
    python3 tools/ui_gate/checks.py --self-test

Prints one JSON line per result ({"check", "control", "result", ...}) and
exits 1 if any result is FAIL. A shot's image path is relative to the shot
file.

- value-steps (quality 8, pass item 3): every interactive control is at least
  two value steps off its ground: the median L* of its rectangle against the
  median L* of a ring of ground 4 pt wide around it, ΔL* >= 20. The ring
  leaves out other controls' rectangles. A ring with too little ground left
  to measure fails: the gate does not pass what it cannot see.
- hud-share (quality 12, pass item 1): the union of the persistent controls'
  rectangles is at most 15% of the frame.
- hierarchy (quality 6, pass items 1 and 2): exactly one primary, 1.5 to 2
  times the area of the next-largest interactive control; at most about five
  things at the second level (six pass, seven fail). A shot with no primary
  (settings) is not applicable to the ratio.
"""
import json
import pathlib
import sys

import numpy as np
from PIL import Image

sys.path.insert(0, str(pathlib.Path(__file__).resolve().parent))
import colour  # noqa: E402

FRAME_PT = (390, 844)  # §21.1
STEP = 10.0
VALUE_STEPS = 2
RING_PT = 4.0
MIN_RING_SHARE = 0.25  # of the full ring's pixels, after clipping and exclusions
HUD_MAX = 0.15
RATIO = (1.5, 2.0)
SECOND_LEVEL_MAX = 6


class Shot:
    def __init__(self, data, base=None, image=None):
        self.data = data
        self.frame = tuple(data.get("frame_pt", FRAME_PT))
        self.controls = data.get("controls", [])
        self._image = image
        self.base = pathlib.Path(base) if base else pathlib.Path(".")

    @classmethod
    def load(cls, path):
        path = pathlib.Path(path)
        return cls(json.loads(path.read_text()), base=path.parent)

    def image(self):
        if self._image is None:
            self._image = Image.open(self.base / self.data["image"])
        return self._image

    def rgb(self):
        im = self.image()
        if im.mode != "RGB":
            ground = Image.new("RGB", im.size, (0, 0, 0))
            rgba = im.convert("RGBA")
            ground.paste(rgba, mask=rgba.getchannel("A"))
            im = ground
        return np.asarray(im, dtype=np.uint8)

    def scale(self):
        return self.image().size[0] / self.frame[0]


def interactive(c):
    return c.get("interactive", True)


def area(rect):
    return max(rect[2], 0) * max(rect[3], 0)


def _px_box(rect, s, w, h, grow=0.0):
    x, y, rw, rh = rect
    x0 = int(round((x - grow) * s))
    y0 = int(round((y - grow) * s))
    x1 = int(round((x + rw + grow) * s))
    y1 = int(round((y + rh + grow) * s))
    return max(x0, 0), max(y0, 0), min(x1, w), min(y1, h)


def value_steps(shot):
    rgb = shot.rgb()
    h, w = rgb.shape[:2]
    s = shot.scale()
    lstar = colour.lightness(rgb)
    out = []
    for c in shot.controls:
        if not interactive(c):
            continue
        x0, y0, x1, y1 = _px_box(c["rect"], s, w, h)
        if x1 <= x0 or y1 <= y0:
            out.append({"check": "value-steps", "control": c["name"], "result": "FAIL",
                        "reason": "the rectangle is outside the still"})
            continue
        face = np.median(lstar[y0:y1, x0:x1])
        ring = np.zeros((h, w), dtype=bool)
        gx0, gy0, gx1, gy1 = _px_box(c["rect"], s, w, h, grow=RING_PT)
        ring[gy0:gy1, gx0:gx1] = True
        ring[y0:y1, x0:x1] = False
        full = ((x1 - x0) + 2 * RING_PT * s) * ((y1 - y0) + 2 * RING_PT * s) - (x1 - x0) * (y1 - y0)
        for other in shot.controls:
            if other is c:
                continue
            ox0, oy0, ox1, oy1 = _px_box(other["rect"], s, w, h)
            ring[oy0:oy1, ox0:ox1] = False
        n = int(ring.sum())
        row = {"check": "value-steps", "control": c["name"], "face_L": round(float(face), 1)}
        if n < MIN_RING_SHARE * full:
            row.update(result="FAIL", reason=f"only {n} ground pixels in the ring, too few to measure")
        else:
            ground = float(np.median(lstar[ring]))
            delta = abs(face - ground)
            row.update(ground_L=round(ground, 1), delta_L=round(float(delta), 1),
                       result="PASS" if delta >= VALUE_STEPS * STEP else "FAIL")
            if row["result"] == "FAIL":
                row["reason"] = f"{delta / STEP:.1f} value steps off its ground; needs {VALUE_STEPS}"
        out.append(row)
    return out


def union_area(rects, frame):
    """Exact area of the union of axis-aligned rectangles, clipped to the frame."""
    boxes = []
    for x, y, w, h in rects:
        x0, y0 = max(x, 0), max(y, 0)
        x1, y1 = min(x + w, frame[0]), min(y + h, frame[1])
        if x1 > x0 and y1 > y0:
            boxes.append((x0, y0, x1, y1))
    xs = sorted({b[0] for b in boxes} | {b[2] for b in boxes})
    total = 0.0
    for a, b in zip(xs, xs[1:]):
        spans = sorted((b0[1], b0[3]) for b0 in boxes if b0[0] <= a and b0[2] >= b)
        covered, top, bottom = 0.0, None, None
        for y0, y1 in spans:
            if top is None or y0 > bottom:
                if top is not None:
                    covered += bottom - top
                top, bottom = y0, y1
            else:
                bottom = max(bottom, y1)
        if top is not None:
            covered += bottom - top
        total += covered * (b - a)
    return total


def hud_share(shot):
    rects = [c["rect"] for c in shot.controls if c.get("persistent")]
    share = union_area(rects, shot.frame) / (shot.frame[0] * shot.frame[1])
    row = {"check": "hud-share", "control": "*", "share": round(share, 4),
           "result": "PASS" if share <= HUD_MAX else "FAIL"}
    if row["result"] == "FAIL":
        row["reason"] = f"the persistent HUD covers {share:.1%} of the screen; at most {HUD_MAX:.0%}"
    return [row]


def hierarchy(shot):
    out = []
    primaries = [c for c in shot.controls if c.get("role") == "primary"]
    others = sorted((c for c in shot.controls if interactive(c) and c.get("role") != "primary"),
                    key=lambda c: area(c["rect"]), reverse=True)
    if len(primaries) > 1:
        out.append({"check": "hierarchy", "control": ",".join(c["name"] for c in primaries),
                    "result": "FAIL", "reason": f"{len(primaries)} primaries; exactly one"})
    elif not primaries:
        out.append({"check": "hierarchy", "control": "*", "result": "N/A",
                    "reason": "the shot names no primary"})
    elif not others:
        out.append({"check": "hierarchy", "control": primaries[0]["name"], "result": "PASS",
                    "reason": "no other interactive control"})
    else:
        p, nxt = primaries[0], others[0]
        ratio = area(p["rect"]) / max(area(nxt["rect"]), 1e-9)
        row = {"check": "hierarchy", "control": p["name"], "next": nxt["name"],
               "ratio": round(ratio, 2),
               "result": "PASS" if RATIO[0] <= ratio <= RATIO[1] else "FAIL"}
        if row["result"] == "FAIL":
            row["reason"] = f"{ratio:.2f} times the next control by area; needs {RATIO[0]} to {RATIO[1]}"
        out.append(row)
    second = [c["name"] for c in shot.controls if c.get("role") == "secondary"]
    row = {"check": "hierarchy", "control": "second-level", "count": len(second),
           "result": "PASS" if len(second) <= SECOND_LEVEL_MAX else "FAIL"}
    if row["result"] == "FAIL":
        row["reason"] = f"{len(second)} things at the second level; about five"
    out.append(row)
    return out


CHECKS = {"value-steps": value_steps, "hud-share": hud_share, "hierarchy": hierarchy}


def run(name, shot):
    if name == "all":
        return [r for fn in CHECKS.values() for r in fn(shot)]
    return CHECKS[name](shot)


# ---------------------------------------------------------------- self-test

def _canvas(ground, size=(390, 844), s=1.0):
    return Image.new("RGB", (int(size[0] * s), int(size[1] * s)), ground)


def _fill(im, rect, rgb, s, noise=0):
    x, y, w, h = rect
    box = (int(round(x * s)), int(round(y * s)), int(round((x + w) * s)), int(round((y + h) * s)))
    patch = np.full((box[3] - box[1], box[2] - box[0], 3), rgb, dtype=np.int16)
    if noise:
        rng = np.random.default_rng(7)
        patch += rng.integers(-noise, noise + 1, size=patch.shape, dtype=np.int16)
    im.paste(Image.fromarray(np.clip(patch, 0, 255).astype(np.uint8)), box[:2])


def _lgrey(lstar):
    """The sRGB grey of a given L*."""
    for v in range(256):
        if colour.lightness(np.array([v, v, v])) >= lstar:
            return (v, v, v)
    return (255, 255, 255)


def self_test():
    colour.self_test()
    s = 1080 / 390
    ground = _lgrey(20)

    # Value steps: a control 3 steps off its ground passes; a planted control
    # one step off fails; noise and a bevel do not move a median.
    im = _canvas(ground, s=s)
    _fill(im, (40, 100, 120, 48), _lgrey(50), s, noise=12)
    _fill(im, (40, 100, 120, 6), _lgrey(80), s)  # a highlight lip
    _fill(im, (200, 100, 120, 48), _lgrey(29), s, noise=12)  # planted fail
    shot = Shot({"image": "-", "controls": [
        {"name": "good", "rect": [40, 100, 120, 48]},
        {"name": "flat", "rect": [200, 100, 120, 48]},
        {"name": "label", "rect": [40, 300, 120, 20], "interactive": False},
    ]}, image=im)
    r = {x["control"]: x for x in value_steps(shot)}
    assert r["good"]["result"] == "PASS" and 25 <= r["good"]["delta_L"] <= 35, r["good"]
    assert r["flat"]["result"] == "FAIL", r["flat"]
    assert "label" not in r

    # The ring leaves out a neighbour: a dark control butting a bright one is
    # measured against the real ground, not the neighbour.
    im = _canvas(ground, s=s)
    _fill(im, (40, 100, 100, 48), _lgrey(25), s)  # planted fail, next to a bright one
    _fill(im, (141, 100, 100, 48), _lgrey(90), s)
    shot = Shot({"image": "-", "controls": [
        {"name": "dim", "rect": [40, 100, 100, 48]},
        {"name": "bright", "rect": [141, 100, 100, 48]},
    ]}, image=im)
    r = {x["control"]: x for x in value_steps(shot)}
    assert r["dim"]["result"] == "FAIL" and r["dim"]["ground_L"] < 22, r["dim"]
    assert r["bright"]["result"] == "PASS", r["bright"]

    # A control with no ground around it cannot be measured, so it fails.
    shot = Shot({"image": "-", "controls": [
        {"name": "boxed", "rect": [100, 100, 50, 50]},
        {"name": "wall", "rect": [90, 90, 70, 9.5], "interactive": False},
        {"name": "wall2", "rect": [90, 150.5, 70, 9.5], "interactive": False},
        {"name": "wall3", "rect": [90, 90, 9.5, 70], "interactive": False},
        {"name": "wall4", "rect": [150.5, 90, 9.5, 70], "interactive": False},
    ]}, image=_canvas(ground, s=s))
    (r,) = value_steps(shot)
    assert r["result"] == "FAIL" and "too few" in r["reason"], r

    # Transparent stills are measured over black, and the scale follows the
    # still's width.
    im = Image.new("RGBA", (780, 1688), (0, 0, 0, 0))
    _fill(im, (10, 10, 100, 40), (255, 255, 255), 2.0)
    shot = Shot({"image": "-", "controls": [{"name": "w", "rect": [10, 10, 100, 40]}]}, image=im)
    (r,) = value_steps(shot)
    assert r["result"] == "PASS" and r["delta_L"] > 95, r

    # HUD share: overlaps count once; 10% passes, a planted 20% fails.
    fw, fh = FRAME_PT
    a = fw * fh
    tenth = [[0, 0, fw, a * 0.06 / fw], [0, fh - a * 0.04 / fw, fw, a * 0.04 / fw]]
    shot = Shot({"controls": [
        {"name": "top", "rect": tenth[0], "persistent": True},
        {"name": "top2", "rect": tenth[0], "persistent": True},
        {"name": "bottom", "rect": tenth[1], "persistent": True},
        {"name": "modal", "rect": [0, 0, fw, fh], "persistent": False},
    ]})
    (r,) = hud_share(shot)
    assert r["result"] == "PASS" and abs(r["share"] - 0.10) < 1e-6, r
    shot.controls.append({"name": "planted", "rect": [0, 200, fw, a * 0.10 / fw], "persistent": True})
    (r,) = hud_share(shot)
    assert r["result"] == "FAIL" and abs(r["share"] - 0.20) < 1e-6, r
    assert union_area([[-10, -10, 20, 20], [5, 5, 10, 10]], FRAME_PT) == 100 + 100 - 25
    assert union_area([[0, 0, 10, 10], [20, 0, 10, 10], [5, 5, 20, 2]], FRAME_PT) == 200 + 20

    # Hierarchy: 1.6 times passes; planted 1.2 times, two primaries and seven
    # second-level things each fail; no primary is not applicable.
    def h(controls):
        return {(x["control"] if x["control"] == "second-level" else "p"): x
                for x in hierarchy(Shot({"controls": controls}))}
    base = [{"name": "heist", "rect": [0, 0, 160, 100], "role": "primary"},
            {"name": "shop", "rect": [0, 0, 100, 100], "role": "secondary"},
            {"name": "deco", "rect": [0, 0, 300, 300], "interactive": False}]
    r = h(base)
    assert r["p"]["result"] == "PASS" and r["p"]["ratio"] == 1.6, r
    assert r["second-level"]["result"] == "PASS"
    r = h([dict(base[0], rect=[0, 0, 120, 100])] + base[1:])
    assert r["p"]["result"] == "FAIL", r
    r = h(base + [{"name": "raid", "rect": [0, 0, 160, 100], "role": "primary"}])
    assert r["p"]["result"] == "FAIL" and "2 primaries" in r["p"]["reason"], r
    r = h(base[:1] + [{"name": f"pill{i}", "rect": [0, 0, 40, 40], "role": "secondary"}
                      for i in range(7)])
    assert r["second-level"]["result"] == "FAIL", r
    r = h(base[1:])
    assert r["p"]["result"] == "N/A", r

    # A shot file on disk, end to end.
    import tempfile
    with tempfile.TemporaryDirectory() as d:
        im = _canvas(ground, s=s)
        _fill(im, (40, 700, 200, 80), _lgrey(60), s)
        im.save(f"{d}/still.png")
        pathlib.Path(f"{d}/shot.json").write_text(json.dumps({
            "image": "still.png", "controls": [
                {"name": "go", "rect": [40, 700, 200, 80], "role": "primary", "persistent": True}]}))
        rows = run("all", Shot.load(f"{d}/shot.json"))
        assert all(x["result"] in ("PASS", "N/A") for x in rows), rows
    print("ui_gate checks self-test: ok")


def main(argv):
    if argv[:1] == ["--self-test"]:
        self_test()
        return 0
    if len(argv) != 2 or argv[0] not in list(CHECKS) + ["all"]:
        print(__doc__, file=sys.stderr)
        return 2
    rows = run(argv[0], Shot.load(argv[1]))
    for r in rows:
        print(json.dumps(r, ensure_ascii=False))
    return 1 if any(r["result"] == "FAIL" for r in rows) else 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
