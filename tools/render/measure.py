#!/usr/bin/env python3
"""Q1 to Q6, Q11 and Q12 for one still, from the mask pass's images
(3D0-M2-mask-tool; docs/art/3d-quality/mask.md is the method).

    python3 tools/render/measure.py OUTDIR      # masks from tools/render/mask.py
    python3 tools/render/measure.py --self-test

Writes OUTDIR/measure.json and prints a summary. Sizes are in points: a
pixel times 360 over the frame's width (one point is three pixels on a
1080-wide phone).
"""
import json
import sys
from collections import deque
from pathlib import Path

import numpy as np
from PIL import Image

# The classes of id.png (tools/render/mask_pass.gd).
BACKGROUND, CREW, GUARD, VAULT, EXIT, MARKER, SHADOW = 0, 1, 2, 3, 4, 5, 6
WALKABLE, PATH, GROUND_OTHER, CLIFF, WATER, DECORATION, BUILDING, PIECE = 7, 8, 9, 10, 11, 12, 13, 14
GUARD_SHADOW = 15
# The tile kinds in id.png's green channel on the statics.
T_OPEN, T_COVER = 1, 5
GROUND = (WALKABLE, PATH, GROUND_OTHER, CLIFF, WATER)
TOPS = (WALKABLE, PATH, GROUND_OTHER)

# Thresholds, as mask.md states them.
COVERED = 0.5  # a pixel is under the interface when under half the world shows through it
BAND_ROW = 0.20  # Q1: a row is in the clear band when under a fifth of it is covered
STRICT_ROW = 0.10  # Q1, the strict reading: under a tenth of the row covered,
# counting the 2D markers (bubbles, labels, icons) as interface items too
GRAY = 18  # Q3: within 18 gray levels of the ground behind
HEAD = 0.30  # Q4: a head is the top 30% of a figure's outline
SEEN = 0.80  # Q4: at least 80% visible
SOLO = 24  # a solo pixel belongs to the figure when a channel is above this (the backdrop stays under it)
MARK_ALPHA = 0.3  # a 2D marker pixel is one at least this opaque
CLEAR, CUT, UNDER, OFF = "clear", "cut", "under panel", "off"
THIRD = 1 / 3  # Q11 on a character screen: the character at least a third of the screen's height

# Which questions each kind of screen answers (mask.md, "Kinds of screen").
# mask.json's "screen" names the kind; a mask without one is a heist still.
# A question left out is not measured there, and says why.
SCREENS = ("heist", "realm", "character", "universe", "none")
WHY = {
    "realm": {
        "Q2": "a realm screen draws no figures", "Q3": "a realm screen draws no figures",
        "Q4": "a realm screen draws no figures or markers", "Q6": "a realm screen draws no figures or markers",
    },
    "character": {
        "Q5": "a character stands on a plinth, not on ground with paths and buildings",
        "Q6": "a character screen draws no world markers",
    },
    "universe": {
        "Q2": "the universe draws islands, not figures", "Q3": "the universe draws islands, not figures",
        "Q4": "the universe's pins are interface, not world markers",
        "Q5": "the islands are too small for paths and buildings to read",
        "Q6": "the universe's pins are interface, not world markers",
        "Q12": "the islands float over the sky with no ground to cast on",
    },
    "none": {q: "the screen draws no 3D world view" for q in ("Q2", "Q3", "Q4", "Q5", "Q6", "Q11", "Q12")},
}
FIGURE_QUESTIONS = ("Q2", "Q3", "Q4", "Q6")
PREFIX = {"crew": "c", "guard": "g", "character": "h"}


def load(path: Path) -> np.ndarray:
    return np.asarray(Image.open(path).convert("RGBA")).astype(np.int16)


def luma(rgb: np.ndarray) -> np.ndarray:
    """Rec. 601 gray, 0 to 255."""
    return 0.299 * rgb[..., 0] + 0.587 * rgb[..., 1] + 0.114 * rgb[..., 2]


def decode(idp: np.ndarray):
    """The id pass's class and index per pixel: red and green carry the
    class (class // 4, class % 4) in steps of 64 from 32, blue the index in
    steps of 28 from 14 (tools/render/mask_pass.gd)."""
    hi = np.clip(idp[..., 0] // 64, 0, 3)
    lo = np.clip(idp[..., 1] // 64, 0, 3)
    idx = np.clip(idp[..., 2] // 28, 0, 9)
    cls = hi * 4 + lo
    # Black is the background, not class 0 at index 0's code (32, 32, 14).
    cls = np.where(idp[..., :3].max(axis=2) < 16, BACKGROUND, cls)
    return cls, idx


def code(cls: int, idx: int = 0):
    """The colour mask_pass.gd draws class `cls` at index `idx` in."""
    return (cls // 4 * 64 + 32, cls % 4 * 64 + 32, idx * 28 + 14)


def runs(flags: np.ndarray):
    """The longest run of True in `flags`: (start, length)."""
    best, start, at = (0, 0), None, 0
    for at, f in enumerate(list(flags) + [False]):
        if f and start is None:
            start = at
        elif not f and start is not None:
            if at - start > best[1]:
                best = (start, at - start)
            start = None
    return best


def components(mask: np.ndarray, step: int = 4, least: int = 2):
    """Connected parts of `mask`, on a grid of `step` pixels: a list of
    (count of cells, (x0, y0, x1, y1) in pixels, set of cells)."""
    h, w = mask.shape
    small = mask[: h - h % step, : w - w % step].reshape(h // step, step, w // step, step).any(axis=(1, 3))
    seen = np.zeros_like(small)
    out = []
    ys, xs = np.nonzero(small)
    for y0, x0 in zip(ys, xs):
        if seen[y0, x0]:
            continue
        cells, queue = set(), deque([(y0, x0)])
        seen[y0, x0] = True
        while queue:
            y, x = queue.popleft()
            cells.add((y, x))
            for dy, dx in ((1, 0), (-1, 0), (0, 1), (0, -1), (1, 1), (1, -1), (-1, 1), (-1, -1)):
                ny, nx = y + dy, x + dx
                if 0 <= ny < small.shape[0] and 0 <= nx < small.shape[1] and small[ny, nx] and not seen[ny, nx]:
                    seen[ny, nx] = True
                    queue.append((ny, nx))
        if len(cells) >= least:
            cy = [c[0] for c in cells]
            cx = [c[1] for c in cells]
            out.append((len(cells), (min(cx) * step, min(cy) * step, (max(cx) + 1) * step, (max(cy) + 1) * step), cells))
    return out


def grow(cells: set, by: int) -> set:
    out = set()
    for y, x in cells:
        for dy in range(-by, by + 1):
            for dx in range(-by, by + 1):
                out.add((y + dy, x + dx))
    return out


class Still:
    def __init__(self, folder: Path):
        self.dir = folder
        self.info = json.loads((folder / "mask.json").read_text())
        self.w, self.h = (int(round(v)) for v in self.info["frame"])
        self.pt = 360.0 / self.w
        ua, ub = load(folder / "ui_a.png"), load(folder / "ui_b.png")
        # How much of the world shows through each pixel: 1 where nothing is over it.
        self.through = np.clip((np.abs(ua[..., 0] - ub[..., 0]) + np.abs(ua[..., 1] - ub[..., 1])) / 510.0, 0, 1)
        self.covered = self.through < COVERED
        self.world = load(folder / "world.png")
        self.behind = load(folder / "behind.png")
        self.markers = load(folder / "markers.png")[..., 3] / 255.0 >= MARK_ALPHA
        self.markers2d = self.markers.copy()
        if (folder / "marks3d.png").exists():
            self.markers |= load(folder / "marks3d.png")[..., :3].max(axis=2) > 24
        self.cls, self.idx = decode(load(folder / "id.png"))
        self.screen = self.info.get("screen", "heist")
        if self.screen not in SCREENS:
            raise ValueError(f"mask.json: unknown screen {self.screen!r}")
        self.figures = self.info.get("figures", [])
        for f in self.figures:
            name = PREFIX[f["kind"]] + str(f["index"])
            p = folder / f"solo_{name}.png"
            f["name"] = name
            f["solo"] = (load(p)[..., :3].max(axis=2) > SOLO) if p.exists() else np.zeros((self.h, self.w), bool)
            kind = GUARD if f["kind"] == "guard" else CREW
            f["seen"] = (self.cls == kind) & (self.idx == f["index"]) & ~self.covered
            f["px"] = int(f["solo"].sum())

    def in_frame(self, f) -> bool:
        return f.get("visible", True) and f["px"] > 0 and not f.get("down", False)

    # Q1: the world's share of the screen.
    def q1(self):
        rows = self.covered.mean(axis=1)
        start, length = runs(rows < BAND_ROW)
        s_start, s_len = runs((self.covered | self.markers2d).mean(axis=1) < STRICT_ROW)
        return {
            "band": round(length / self.h, 4),
            "band_rows": [int(start), int(start + length - 1)],
            "strict_band": round(s_len / self.h, 4),
            "strict_rows": [int(s_start), int(s_start + s_len - 1)],
            "panels_share": round(float(self.covered.mean()), 4),
            "uncovered_share": round(1 - float(self.covered.mean()), 4),
        }

    # Q2: figure size.
    def q2(self):
        out = {"crew": [], "guards": [], "characters": []}
        for f in self.figures:
            if not self.in_frame(f) or "rect" not in f:
                continue
            ys = np.nonzero(f["solo"].any(axis=1))[0]
            silhouette = round((ys[-1] - ys[0] + 1) * self.pt, 1) if ys.size else 0.0
            # The measure is the plan's: the figure's bounds height, feet to
            # top, stood along the camera's up at its feet and projected
            # (mask_pass.gd "span"; mask.md, "Q2"). The drawn
            # silhouette (ink line included) and the projected box, which
            # runs taller because its depth adds to its height in perspective,
            # are kept beside it.
            span = f.get("span")
            row = {"name": f["name"], "role": f["role"],
                   "points": round(span * self.pt, 1) if span is not None else silhouette,
                   "silhouette_points": silhouette,
                   "bounds_points": round(f["rect"][3] * self.pt, 1)}
            out[{"crew": "crew", "guard": "guards", "character": "characters"}[f["kind"]]].append(row)
        for k in ("crew", "guards", "characters"):
            pts = [r["points"] for r in out[k]]
            out[k + "_least"] = min(pts) if pts else None
            out[k + "_most"] = max(pts) if pts else None
        least = [v for v in (out["crew_least"], out["guards_least"], out["characters_least"]) if v is not None]
        out["least"] = min(least) if least else None
        return out

    # Q3: figure separation.
    def q3(self):
        out = []
        gray_w, gray_b = luma(self.world[..., :3]), luma(self.behind[..., :3])
        for f in self.figures:
            m = f["seen"]
            n = int(m.sum())
            if not self.in_frame(f) or n < 20:
                continue
            lost = int((np.abs(gray_w - gray_b)[m] <= GRAY).sum())
            out.append({"name": f["name"], "pixels": n, "share": round(lost / n, 4)})
        shares = [r["share"] for r in out]
        return {"figures": out, "worst": max(shares) if shares else None,
                "least": min(shares) if shares else None}

    # Q4: heads and markers stay visible.
    def q4(self):
        heads = []
        for f in self.figures:
            if not self.in_frame(f):
                continue
            ys = np.nonzero(f["solo"].any(axis=1))[0]
            top = ys[0] + max(1, int(round((ys[-1] - ys[0] + 1) * HEAD)))
            head = f["solo"].copy()
            head[top:, :] = False
            n = int(head.sum())
            if n == 0:
                continue
            seen = (head & f["seen"]).sum() / n
            heads.append({"name": f["name"], "seen": round(float(seen), 3)})
        marks, under = [], []
        for count, box, cells in components(self.markers, least=3):
            x0, y0, x1, y1 = box
            if x1 - x0 >= 0.9 * self.w and y1 - y0 <= 8:
                # A hairline across the whole frame is a panel's edge, not a
                # marker.
                continue
            sub = self.markers[y0:y1, x0:x1]
            n = int(sub.sum())
            seen = float((sub & ~self.covered[y0:y1, x0:x1]).sum() / max(1, n))
            row = {"box": list(box), "seen": round(seen, 3)}
            # Wholly under a panel is a framing matter (Q1, Q11), not a
            # pile-up: listed, not counted.
            (under if seen == 0.0 else marks).append(row)
        worst = [r["seen"] for r in heads + marks]
        return {"heads": heads, "markers": marks, "under_panel": under,
                "worst": min(worst) if worst else None,
                "pass": all(v >= SEEN for v in worst)}

    # Q5: quiet ground.
    def q5(self):
        walk = ((self.cls == WALKABLE) | ((self.cls == DECORATION) & np.isin(self.idx, (T_OPEN, T_COVER)))) \
            & ~self.covered
        deco = (self.cls == DECORATION) & np.isin(self.idx, (T_OPEN, T_COVER)) & ~self.covered
        paths = components((self.cls == PATH) & ~self.covered, least=6)
        houses = [c for c in components((self.cls == BUILDING) & ~self.covered, least=20)]
        joined = []
        for _n, _box, cells in paths:
            near = grow(cells, 3)
            joined.append(sum(1 for _m, _b, hc in houses if near & hc))
        best = max(joined) if joined else 0
        return {"decoration_on_walkable": round(float(deco.sum() / max(1, walk.sum())), 4),
                "decoration_pixels": int(deco.sum()), "paths": len(paths), "buildings": len(houses),
                "buildings_on_one_path": best, "path_links_every_building": bool(houses) and best == len(houses)}

    def _objects(self):
        objs = []
        for f in self.figures:
            if self.in_frame(f):
                objs.append({"name": f["name"], "at": f["head"], "mask": f["solo"]})
        for key in ("vault", "exit"):
            if key in self.info:
                x, y, w, h = self.info[key]["rect"]
                m = np.zeros((self.h, self.w), bool)
                m[max(0, int(y)):max(0, int(y + h)), max(0, int(x)):max(0, int(x + w))] = True
                objs.append({"name": key, "at": self.info[key]["centre"], "mask": m})
        return objs

    # Q6: the marker budget.
    def q6(self):
        marks = self.markers | ((self.cls == MARKER) & ~self.covered)
        objs = self._objects()
        per = {o["name"]: 0 for o in objs}
        for _n, (x0, y0, x1, y1), _cells in components(marks, least=3):
            c = ((x0 + x1) / 2, (y0 + y1) / 2)
            if objs:
                near = min(objs, key=lambda o: (o["at"][0] - c[0]) ** 2 + (o["at"][1] - c[1]) ** 2)
                per[near["name"]] += 1
        over = {}
        for o in objs:
            n = int(o["mask"].sum())
            if n:
                over[o["name"]] = round(float((o["mask"] & self.markers).sum() / n), 3)
        return {"per_object": per, "most": max(per.values()) if per else 0, "covering": over,
                "worst_covering": max(over.values()) if over else 0.0}

    def rate(self, mask: np.ndarray, whole: float) -> str:
        """clear, cut (partly off the frame), under panel (half or more of
        what is on the frame under the interface) or off."""
        n = int(mask.sum())
        if whole <= 0 or n < 0.05 * whole or n == 0:
            return OFF
        if (mask & self.covered).sum() >= 0.5 * n:
            return UNDER
        if n < 0.9 * whole:
            return CUT
        return CLEAR

    def island_rating(self):
        """The island on a realm or universe screen: cut where the ground
        reaches an edge of the view, under panel when half or more of it is
        under the interface, else clear."""
        island = (self.cls >= WALKABLE) & (self.cls <= BUILDING)
        x, y, w, h = [int(round(v)) for v in self.info["view_rect"]]
        x0, y0, x1, y1 = max(0, x), max(0, y), min(self.w, x + w) - 1, min(self.h, y + h) - 1
        edges = {"left": bool(island[y0:y1, x0].any()), "right": bool(island[y0:y1, x1].any()),
                 "top": bool(island[y0, x0:x1].any()), "bottom": bool(island[y1, x0:x1].any())}
        n = int(island.sum())
        under = float((island & self.covered).sum() / max(1, n))
        rating = OFF if n == 0 else CUT if any(edges.values()) else UNDER if under >= 0.5 else CLEAR
        return edges, {"rating": rating, "pixels": n, "under_share": round(under, 3)}

    # Q11: framing.
    def q11(self):
        edges, island = self.island_rating()
        if self.screen in ("realm", "universe"):
            return {"island": island, "island_at_edges": edges, "pass": island["rating"] == CLEAR}
        if self.screen == "character":
            out = {"island_at_edges": edges}
            figs = [f for f in self.figures if f["kind"] == "character" and self.in_frame(f)]
            if not figs:
                return dict(out, character={"rating": OFF, "height_share": 0.0, "third": False}, **{"pass": False})
            pick = next((f for f in figs if f["index"] == self.info.get("chosen", -1)), figs[0])
            ys = np.nonzero(pick["solo"].any(axis=1))[0]
            share = round(float(ys[-1] - ys[0] + 1) / self.h, 4)
            rating = self.rate(pick["solo"], self._whole(pick))
            out["character"] = {"name": pick["name"], "rating": rating, "height_share": share,
                                "third": share >= THIRD}
            out["largest_figure_share"] = share
            out["pass"] = rating == CLEAR and share >= THIRD
            return out
        crew = [f for f in self.figures if f["kind"] == "crew" and f.get("visible", True)]
        chosen = self.info.get("chosen", -1)
        pick = next((f for f in crew if f["index"] == chosen), crew[0] if crew else None)
        out = {}
        if pick is not None:
            out["chosen"] = {"name": pick["name"], "rating": self.rate(pick["solo"], self._whole(pick))}
            guards = [f for f in self.figures if f["kind"] == "guard" and not f.get("down", False)]
            if guards:
                g = min(guards, key=lambda f: (f["world"][0] - pick["world"][0]) ** 2 + (f["world"][2] - pick["world"][2]) ** 2)
                out["nearest_guard"] = {"name": g["name"], "rating": self.rate(g["solo"], self._whole(g))}
                out["guards"] = {f["name"]: self.rate(f["solo"], self._whole(f)) for f in guards}
        if "vault" in self.info:
            # The vault's own pixels; its projected bounds only say how much
            # of it the frame cuts off (the bounds box is far larger than
            # the chest, and would call it under a panel it only grazes).
            x, y, w, h = self.info["vault"]["rect"]
            m = self.cls == VAULT
            inside_w = max(0.0, min(self.w, x + w) - max(0.0, x))
            inside_h = max(0.0, min(self.h, y + h) - max(0.0, y))
            part = (inside_w * inside_h) / max(1.0, w * h)
            whole = float(m.sum()) / part if part > 0 else 0.0
            out["target"] = {"name": "vault", "rating": self.rate(m, whole),
                             "under_share": round(float((m & self.covered).sum() / max(1, m.sum())), 3)}
        out["island_at_edges"] = edges
        tallest = max((f["rect"][3] for f in self.figures if self.in_frame(f) and "rect" in f), default=0)
        out["largest_figure_share"] = round(tallest / self.h, 3)
        return out

    def _whole(self, f) -> float:
        """A figure's whole outline area, guessed from its bounds where the
        frame cuts it."""
        if "rect" not in f:
            return float(f["px"])
        x, y, w, h = f["rect"]
        inside_w = max(0.0, min(self.w, x + w) - max(0.0, x))
        inside_h = max(0.0, min(self.h, y + h) - max(0.0, y))
        part = (inside_w * inside_h) / max(1.0, w * h)
        return f["px"] / part if part > 0 else 0.0

    # Q12: depth.
    def q12(self):
        shadows = {}
        for f in self.figures:
            if not self.in_frame(f):
                continue
            kind = GUARD_SHADOW if f["kind"] == "guard" else SHADOW
            n = int(((self.cls == kind) & (self.idx == f["index"])).sum())
            shadows[f["name"]] = n
        gray = luma(self.world[..., :3])
        tops = np.isin(self.cls, TOPS) & ~self.covered
        cliff = (self.cls == CLIFF) & ~self.covered
        house_shadow = []
        ground_mean = float(gray[tops].mean()) if tops.any() else 0.0
        for _n, (x0, y0, x1, y1), _c in components((self.cls == BUILDING) & ~self.covered, least=20):
            band = np.zeros_like(tops)
            band[y1:min(self.h, y1 + 16), x0:x1] = True
            g = band & tops
            if g.sum() >= 20 and ground_mean:
                house_shadow.append(round(float(gray[g].mean()) / ground_mean, 3))
        return {"figure_shadow_pixels": shadows,
                "figures_with_shadow": sum(1 for v in shadows.values() if v >= 20), "figures": len(shadows),
                "building_foot_luma_ratio": house_shadow,
                "buildings_with_shadow": sum(1 for r in house_shadow if r < 0.85),
                "cliff_luma": round(float(gray[cliff].mean()), 1) if cliff.any() else None,
                "top_luma": round(ground_mean, 1) if tops.any() else None,
                "cliffs_darker": bool(cliff.any() and tops.any() and gray[cliff].mean() < ground_mean)}


def measure(folder: Path) -> dict:
    s = Still(Path(folder))
    out = {"still": str(folder), "screen": s.screen, "frame": [s.w, s.h], "env": s.info.get("env", {}),
           "zoom": s.info.get("zoom")}
    why = dict(WHY.get(s.screen, {}))
    if s.screen == "realm" and any(s.in_frame(f) for f in s.figures):
        # A realm screen with figures on it (a camp's crew) answers the
        # figure questions as a heist does.
        why = {q: v for q, v in why.items() if q not in FIGURE_QUESTIONS}
    for q in ("Q1", "Q2", "Q3", "Q4", "Q5", "Q6", "Q11", "Q12"):
        out[q] = {"applies": False, "why": why[q]} if q in why else dict(getattr(s, q.lower())(), applies=True)
    return out


def write(folder: Path, result: dict) -> None:
    def plain(o):
        if isinstance(o, np.generic):
            return o.item()
        raise TypeError(type(o).__name__)

    (Path(folder) / "measure.json").write_text(json.dumps(result, indent=2, default=plain) + "\n")


def summary(r: dict) -> str:
    def line(q, text):
        e = r[q]
        if not e.get("applies", True):
            return f"{q:<3} not measured: {e['why']}"
        try:
            return f"{q:<3} " + text(e)
        except (KeyError, TypeError):
            return f"{q:<3} " + json.dumps({k: v for k, v in e.items() if not isinstance(v, (list, dict))})

    def q11(e):
        if "island" in e:
            sides = ", ".join(k for k, v in e["island_at_edges"].items() if v) or "none"
            return f"island {e['island']['rating']} (edges touched: {sides})"
        if "character" in e:
            c = e["character"]
            return f"character {c['rating']}, {c['height_share']:.1%} of the height ({'pass' if e['pass'] else 'fail'})"
        rating = lambda k: e.get(k, {}).get("rating", "-")  # noqa: E731
        return (f"chosen {rating('chosen')}, nearest guard {rating('nearest_guard')}, target {rating('target')}; "
                f"largest figure {e['largest_figure_share']:.1%} of the height")

    def q2(e):
        parts = [f"{k} {e[k + '_least']}-{e[k + '_most']} pt" for k in ("crew", "guards", "characters")
                 if e.get(k + "_least") is not None]
        return ", ".join(parts) or "no figures in frame"

    def q4(e):
        return f"least seen {e['worst']} ({'pass' if e['pass'] else 'fail'})"

    return "\n".join([
        line("Q1", lambda e: f"band {e['band']:.1%} (rows {e['band_rows'][0]}-{e['band_rows'][1]}), "
                             f"strict {e['strict_band']:.1%}, panels {e['panels_share']:.1%} of the pixels"),
        line("Q2", q2),
        line("Q3", lambda e: f"figure pixels near the ground's gray: {e['least']} to {e['worst']}"),
        line("Q4", q4),
        line("Q5", lambda e: f"decoration on walkable {e['decoration_on_walkable']:.1%}; "
                             f"{e['buildings_on_one_path']} of {e['buildings']} buildings on one path"),
        line("Q6", lambda e: f"most markers on one object {e['most']}; worst covering {e['worst_covering']}"),
        line("Q11", q11),
        line("Q12", lambda e: f"shadows {e['figures_with_shadow']}/{e['figures']}, buildings shadowed "
                              f"{e['buildings_with_shadow']}/{len(e['building_foot_luma_ratio'])}, cliffs darker "
                              f"{e['cliffs_darker']} ({e['cliff_luma']} vs {e['top_luma']})"),
    ])


def self_test() -> None:
    """The measures on a drawn still whose answers are known."""
    import tempfile
    w, h = 90, 195
    with tempfile.TemporaryDirectory() as tmp:
        d = Path(tmp)
        ua = np.zeros((h, w, 4), np.uint8)
        ua[..., 3] = 255
        ub = ua.copy()
        ua[..., 0] = 255
        ub[..., 1] = 255
        # Panels: rows 0-39 and 130-194 opaque gray in both.
        for im in (ua, ub):
            im[:40] = (90, 90, 90, 255)
            im[130:] = (90, 90, 90, 255)
        Image.fromarray(ua).save(d / "ui_a.png")
        Image.fromarray(ub).save(d / "ui_b.png")
        idp = np.zeros((h, w, 4), np.uint8)
        idp[..., 3] = 255
        idp[..., :3] = code(WALKABLE, T_OPEN)
        idp[60:80, 40:46, :3] = code(CREW, 0)
        Image.fromarray(idp).save(d / "id.png")
        world = np.full((h, w, 4), 120, np.uint8)
        world[60:80, 40:46, :3] = 124  # the figure within 18 grays of the ground
        world[60:65, 40:46, :3] = 240
        Image.fromarray(world).save(d / "world.png")
        Image.fromarray(np.full((h, w, 4), 120, np.uint8)).save(d / "behind.png")
        Image.fromarray(np.zeros((h, w, 4), np.uint8)).save(d / "markers.png")
        solo = np.zeros((h, w, 4), np.uint8)
        solo[60:80, 40:46] = (40, 8, 8, 255)
        Image.fromarray(solo).save(d / "solo_c0.png")
        info = {"frame": [w, h], "view_rect": [0, 0, w, h], "chosen": 0, "zoom": 1,
                "figures": [{"kind": "crew", "index": 0, "role": "rogue", "visible": True, "rect": [40, 60, 6, 20],
                             "head": [43, 60], "feet": [43, 80], "world": [0, 0, 0]}]}
        (d / "mask.json").write_text(json.dumps(info))
        r = measure(d)
        assert r["Q1"]["band_rows"] == [40, 129], r["Q1"]
        assert abs(r["Q1"]["panels_share"] - 105 / 195) < 1e-3, r["Q1"]
        assert r["Q2"]["crew_least"] == round(20 * 360 / w, 1), r["Q2"]
        assert r["Q3"]["worst"] == 0.75, r["Q3"]
        assert r["Q4"]["pass"], r["Q4"]
        assert r["Q11"]["chosen"]["rating"] == CLEAR, r["Q11"]
        assert r["Q11"]["island_at_edges"]["left"], r["Q11"]
        assert runs(np.array([1, 0, 1, 1, 1, 0, 1], bool)) == (2, 3)
        assert r["screen"] == "heist" and r["Q2"].get("applies", True), r["Q2"]
        summary(r)
    _realm_test()
    _character_test()
    print("measure self-test: ok")


def _still(d: Path, w: int, h: int, idp: np.ndarray, world: np.ndarray, info: dict, solos=None, behind=None) -> None:
    """Write a drawn still: panels over rows 0-39 and 130 to the end."""
    ua = np.zeros((h, w, 4), np.uint8)
    ua[..., 3] = 255
    ub = ua.copy()
    ua[..., 0] = 255
    ub[..., 1] = 255
    for im in (ua, ub):
        im[:40] = (90, 90, 90, 255)
        im[130:] = (90, 90, 90, 255)
    Image.fromarray(ua).save(d / "ui_a.png")
    Image.fromarray(ub).save(d / "ui_b.png")
    Image.fromarray(idp).save(d / "id.png")
    Image.fromarray(world).save(d / "world.png")
    Image.fromarray(world if behind is None else behind).save(d / "behind.png")
    Image.fromarray(np.zeros((h, w, 4), np.uint8)).save(d / "markers.png")
    for name, solo in (solos or {}).items():
        Image.fromarray(solo).save(d / f"solo_{name}.png")
    (d / "mask.json").write_text(json.dumps(info))


def _realm_test() -> None:
    """A realm still: no figures; the island runs off the left edge, one
    building with a darker foot, a cliff darker than the tops."""
    import tempfile
    w, h = 90, 195
    with tempfile.TemporaryDirectory() as tmp:
        d = Path(tmp)
        idp = np.zeros((h, w, 4), np.uint8)
        idp[..., 3] = 255
        idp[50:110, 0:80, :3] = code(WALKABLE, T_OPEN)
        idp[110:125, 0:80, :3] = code(CLIFF)
        idp[60:80, 30:50, :3] = code(BUILDING, 3)
        world = np.zeros((h, w, 4), np.uint8)
        world[..., 3] = 255
        world[50:110, 0:80, :3] = 150
        world[80:96, 30:50, :3] = 90  # the building's foot shadow
        world[110:125, 0:80, :3] = 60
        world[60:80, 30:50, :3] = 200
        info = {"screen": "realm", "frame": [w, h], "view_rect": [0, 0, w, h], "chosen": -1, "zoom": 0,
                "figures": []}
        _still(d, w, h, idp, world, info)
        r = measure(d)
        for q in ("Q2", "Q3", "Q4", "Q6"):
            assert r[q]["applies"] is False and r[q]["why"], (q, r[q])
        assert r["Q11"]["island"]["rating"] == CUT and r["Q11"]["island_at_edges"]["left"], r["Q11"]
        assert not r["Q11"]["island_at_edges"]["right"], r["Q11"]
        assert r["Q11"]["pass"] is False, r["Q11"]
        assert r["Q12"]["buildings_with_shadow"] == 1 and r["Q12"]["cliffs_darker"], r["Q12"]
        assert "Q2  not measured" in summary(r), summary(r)
        # The same island drawn inside the frame passes.
        idp[50:125, 0:5, :3] = 0
        _still(d, w, h, idp, world, info)
        r = measure(d)
        assert r["Q11"]["island"]["rating"] == CLEAR and r["Q11"]["pass"], r["Q11"]


def _character_test() -> None:
    """A character still: one figure 80 of 195 rows tall (over a third),
    its contact shadow under it, before a plain backdrop."""
    import tempfile
    w, h = 90, 195
    with tempfile.TemporaryDirectory() as tmp:
        d = Path(tmp)
        idp = np.zeros((h, w, 4), np.uint8)
        idp[..., 3] = 255
        idp[120:128, 30:60, :3] = code(GROUND_OTHER)
        idp[45:125, 40:52, :3] = code(CREW, 0)
        idp[125:128, 36:56, :3] = code(SHADOW, 0)
        world = np.full((h, w, 4), 30, np.uint8)
        world[..., 3] = 255
        world[45:125, 40:52, :3] = 200
        behind = np.full((h, w, 4), 30, np.uint8)
        behind[..., 3] = 255
        solo = np.zeros((h, w, 4), np.uint8)
        solo[45:125, 40:52] = (40, 8, 8, 255)
        info = {"screen": "character", "frame": [w, h], "view_rect": [0, 0, w, h], "chosen": 0, "zoom": 0,
                "figures": [{"kind": "character", "index": 0, "role": "skyskipper", "visible": True,
                             "rect": [40, 45, 12, 80], "head": [46, 45], "feet": [46, 125], "world": [0, 0, 0]}]}
        _still(d, w, h, idp, world, info, {"h0": solo}, behind)
        r = measure(d)
        assert r["screen"] == "character", r
        for q in ("Q5", "Q6"):
            assert r[q]["applies"] is False, (q, r[q])
        assert r["Q2"]["characters_least"] == round(80 * 360 / w, 1), r["Q2"]
        assert r["Q3"]["worst"] == 0.0, r["Q3"]
        assert r["Q4"]["pass"], r["Q4"]
        q11 = r["Q11"]
        assert q11["character"]["rating"] == CLEAR and q11["pass"], q11
        assert abs(q11["character"]["height_share"] - 80 / 195) < 1e-3 and q11["character"]["third"], q11
        assert r["Q12"]["figures_with_shadow"] == 1 and r["Q12"]["figure_shadow_pixels"] == {"h0": 60}, r["Q12"]
        summary(r)
        # Drawn 50 rows tall it is under a third of the height.
        idp[45:75, 40:52, :3] = 0
        solo[45:75] = 0
        info["figures"][0]["rect"] = [40, 75, 12, 50]
        _still(d, w, h, idp, world, info, {"h0": solo}, behind)
        q11 = measure(d)["Q11"]
        assert not q11["character"]["third"] and q11["pass"] is False, q11


if __name__ == "__main__":
    if sys.argv[1:] == ["--self-test"]:
        self_test()
    elif len(sys.argv) == 2:
        res = measure(Path(sys.argv[1]))
        write(Path(sys.argv[1]), res)
        print(summary(res))
    else:
        print(__doc__)
        sys.exit(2)
