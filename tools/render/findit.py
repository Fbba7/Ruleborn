#!/usr/bin/env python3
"""The find-it test, scored from the mask (3D0-M2-find-it).

    python3 tools/render/findit.py OUTDIR [--jobs N] [--no-render] [--only a,b]
    python3 tools/render/findit.py --self-test

Renders the fixed set of stills (STILLS below, named in
docs/art/3d-quality/find-it.md) through tools/render/mask.py into
OUTDIR/<still>/, answers the five questions of each from the masks with no
judge and no opinion, and writes OUTDIR/findit.json and OUTDIR/findit.md.
--no-render scores masks already in OUTDIR. The clips (CLIPS) are scored from
a series of masked frames by `score_clip`; see find-it.md for what is
rendered today.
"""
import json
import os
import subprocess
import sys
from concurrent.futures import ThreadPoolExecutor
from pathlib import Path

import numpy as np

sys.path.insert(0, str(Path(__file__).resolve().parent))
import measure as M  # noqa: E402

ROOT = Path(__file__).resolve().parents[2]
SHOT = "client/tests/shots/screen_heist.gd"

# The thresholds are the plan's own targets (plan.md section 4), so the test
# asks "could a player find it" in the terms the plan sets for Q2, Q3, Q4.
MIN_POINTS = 32.0   # Q2: a figure at least this tall (points)
MAX_BLEND = 0.05    # Q3: at most this share of a figure within 18 grays of the ground
MIN_SEEN = 0.80     # Q4: at least this share of a figure's head seen
MAX_COVER = 0.20    # a vault or exit under markers by at most this share
# A guard's sight is read from marks3d.png (the 3D markers alone, mask.md):
# the shown guard's red cone and edge, every other guard's pale fan
# (client/world/fx_ground.gd). Both start at the guard's feet, so a guard's
# sight is the sight pixels on the ground between SIGHT_INNER and
# SIGHT_OUTER metres from its feet, past its own rings (0.62 m) and short of
# the next tiles' cones; the fan reaches 1.6 m (FAN_REACH).
SIGHT_INNER = 0.7   # metres from the feet
SIGHT_OUTER = 2.0
SIGHT_PIXELS = 40   # fewest sight pixels in that ring that show the sight
RING_CLEAR = 0.65   # metres round every other figure left out (its rings)
# world_view.gd's AWARE: the shown guard is the most aware, then the one
# nearest the chosen crew member (WorldView.shown_guard).
AWARE = {"Unaware": 0, "Returning": 0, "Suspicious": 1, "Investigating": 2, "Searching": 3, "Alerted": 4}
MIN_OBJECT = 300    # fewest id-mask pixels that show a vault or an exit
CELL = 6            # the route's grid, pixels

# The fixed stills: name -> shot environment (screen_heist.gd; mask.md).
# Seven moments at today's camera (15 tiles) and three at 11 tiles.
STILLS = {
    "start-15": {"MOMENT": "start", "ZOOM": "1"},
    "sneak-15": {"MOMENT": "sneak", "ZOOM": "1"},
    "vault-15": {"MOMENT": "vault", "ZOOM": "1"},
    "alarm-15": {"MOMENT": "alarm", "ZOOM": "1"},
    "escape-15": {"MOMENT": "escape", "ZOOM": "1"},
    "entry-15": {"MOMENT": "entry", "ZOOM": "1"},
    "hold-15": {"MOMENT": "hold", "ZOOM": "1"},
    "start-11": {"MOMENT": "start", "ZOOM": "1", "TILES": "11"},
    "sneak-11": {"MOMENT": "sneak", "ZOOM": "1", "TILES": "11"},
    "escape-11": {"MOMENT": "escape", "ZOOM": "1", "TILES": "11"},
}

QUESTIONS = [
    ("crew", "Where is every crew member?"),
    ("guards", "Where is every guard?"),
    ("vault", "Where is the vault?"),
    ("exit", "Where is the exit?"),
    ("route", "Which route from the chosen crew member to the exit is safest?"),
]

# The clips (Q13): frame series, spaced FRAME_SECONDS apart.
FRAME_SECONDS = 0.2
CLIPS = {
    "sneak": {"gait": "sneak"},
    "walk": {"gait": "walk"},
    "run": {"gait": "run"},
}
# Screen speed of the moving crew member's feet, points per second, below
# which a clip reads as each gait. Provisional: no clip has been rendered
# (find-it.md, "The clips"); set them from the three clips' first render.
GAIT_EDGES = (4.0, 9.0)


def _crew_named(s: "M.Still"):
    """The crew members in view: shown and with pixels in the frame."""
    return [f for f in s.figures if f["kind"] == "crew" and f.get("visible", True) and f["px"] > 0]


def _guards_in_view(s: "M.Still"):
    """The guards in view: shown, on their feet and with pixels in the frame
    (find-it.md: "every guard in view"); one off the frame is not asked."""
    return [f for f in s.figures if f["kind"] == "guard" and s.in_frame(f)]


def _height(s, f) -> float:
    """A figure's height in points: the plan's bounds measure, or its drawn
    silhouette for one lying down (its bounds stand it up)."""
    ys = np.nonzero(f["solo"].any(axis=1))[0]
    silhouette = (ys[-1] - ys[0] + 1) * s.pt if ys.size else 0.0
    if f.get("down") or f.get("span") is None:
        return float(silhouette)
    return float(f["span"] * s.pt)


def _blend(s, f):
    m = f["seen"]
    n = int(m.sum())
    if n < 20:
        return None
    gw, gb = M.luma(s.world[..., :3]), M.luma(s.behind[..., :3])
    return float((np.abs(gw - gb)[m] <= M.GRAY).sum() / n)


def _head_seen(s, f) -> float:
    ys = np.nonzero(f["solo"].any(axis=1))[0]
    if not ys.size:
        return 0.0
    top = ys[0] + max(1, int(round((ys[-1] - ys[0] + 1) * M.HEAD)))
    head = f["solo"].copy()
    head[top:, :] = False
    n = int(head.sum())
    return float((head & f["seen"]).sum() / n) if n else 0.0


def figure_found(s, f) -> dict:
    """A figure is found when it is clear of the frame's edge and the panels,
    its head is seen, it is tall enough and it parts from the ground."""
    rating = s.rate(f["solo"], s._whole(f))
    seen, tall, blend = _head_seen(s, f), _height(s, f), _blend(s, f)
    why = []
    if rating != M.CLEAR:
        why.append(rating)
    if seen < MIN_SEEN:
        why.append("head seen %.0f%%" % (seen * 100))
    if tall < MIN_POINTS:
        why.append("%.0f pt" % tall)
    if blend is None or blend > MAX_BLEND:
        why.append("blends %s" % ("n/a" if blend is None else "%.0f%%" % (blend * 100)))
    return {"name": f["name"], "found": not why, "why": why, "rating": rating,
            "head_seen": round(seen, 3), "points": round(tall, 1),
            "blend": None if blend is None else round(blend, 3)}


def object_found(s, key: str) -> dict:
    """The vault or the exit: drawn in the id mask, clear of the frame's edge
    and the panels, and little covered by markers. The exit has no bounds in
    mask.json, so both are read from the id mask."""
    kind = M.VAULT if key == "vault" else M.EXIT
    m = s.cls == kind
    n = int(m.sum())
    if n < MIN_OBJECT:
        return {"found": False, "why": ["not in the frame"], "rating": M.OFF, "pixels": n}
    under = float((m & s.covered).sum() / n)
    edge = bool(m[0].any() or m[-1].any() or m[:, 0].any() or m[:, -1].any())
    rating = M.UNDER if under >= 0.5 else M.CUT if edge else M.CLEAR
    cover = float((m & s.markers).sum() / n)
    why = []
    if rating != M.CLEAR:
        why.append(rating)
    if cover > MAX_COVER:
        why.append("markers cover %.0f%%" % (cover * 100))
    return {"found": not why, "why": why, "rating": rating, "pixels": n,
            "covered_by_markers": round(cover, 3)}


def ground_map(s):
    """The ground plane's map from the frame back to the world: a homography
    fitted to every figure's feet (world x, z to frame x, y; mask.json),
    inverted, so each pixel has a ground position in metres. None when fewer
    than four figures fix it."""
    pts = [(f["world"][0], f["world"][2], f["feet"][0], f["feet"][1]) for f in s.figures
           if "world" in f and "feet" in f]
    if len(pts) < 4:
        return None
    a = []
    for x, z, u, v in pts:
        a.append([x, z, 1, 0, 0, 0, -u * x, -u * z, -u])
        a.append([0, 0, 0, x, z, 1, -v * x, -v * z, -v])
    _u, sv, vt = np.linalg.svd(np.asarray(a, float))
    if sv[-2] < 1e-9 * sv[0]:
        return None
    hm = vt[-1].reshape(3, 3)
    inv = np.linalg.inv(hm)
    yy, xx = np.mgrid[0:s.h, 0:s.w]
    q = np.einsum("ij,jhw->ihw", inv, np.stack([xx + 0.5, yy + 0.5, np.ones_like(xx, float)]))
    with np.errstate(divide="ignore", invalid="ignore"):
        gx, gz = q[0] / q[2], q[1] / q[2]
    return gx, gz


def sight_pixels(s):
    """marks3d.png's sight colours: red (the shown guard's cone, its edge and
    ring) and pale (the other guards' fans), each a boolean frame."""
    p = s.dir / "marks3d.png"
    if not p.exists():
        z = np.zeros((s.h, s.w), bool)
        return z, z
    rgb = M.load(p)[..., :3].astype(int)
    r, g, b = rgb[..., 0], rgb[..., 1], rgb[..., 2]
    lo, hi = rgb.min(axis=2), rgb.max(axis=2)
    # Crimson (the cone, about 120, 20, 40), not the crew rings' orange,
    # whose green is well over its blue.
    red = (r > 60) & (g * 10 < r * 4) & (b + 8 >= g) & (b * 10 < r * 7)
    # The fans' lavender white (#F3EEFF at 0.55, about 100, 90, 110 to 190,
    # 170, 190 as rendered): blue at least its red, not the effects' bright
    # pink sparks.
    pale = (lo > 60) & (hi - lo < 40) & (b + 8 >= r) & (b >= g) & (hi < 215)
    return red & ~s.covered, pale & ~s.covered


def shown_guard(s) -> int:
    """WorldView.shown_guard: the most aware guard on its feet, then the one
    nearest the chosen crew member's tile."""
    chosen = s.info.get("chosen", -1)
    near = next((f.get("world") for f in s.figures if f["kind"] == "crew" and f["index"] == chosen), None)
    best, key_best = -1, -float("inf")
    for f in s.figures:
        if f["kind"] != "guard" or f.get("down"):
            continue
        key = AWARE.get(str(f.get("state", "Unaware")), 0) * 1000.0
        if near is not None and f.get("world") is not None:
            # World x, z is the tile ("at", written as a string) less a fixed offset.
            key -= float(np.hypot(f["world"][0] - near[0], f["world"][2] - near[2]))
        else:
            key -= f["index"]
        if key > key_best:
            best, key_best = f["index"], key
    return best


def sight_of(s, guards: list) -> dict:
    """For each guard, whether its own sight is drawn: the shown guard's red
    cone, or another guard's pale fan, on the ground round its feet."""
    out = {}
    if not guards:
        return out
    ground = ground_map(s)
    red, pale = sight_pixels(s)
    shown = shown_guard(s)
    for g in guards:
        if ground is None:
            out[g["name"]] = {"drawn": False, "why": "ground not fixed", "red": 0, "pale": 0}
            continue
        gx, gz = ground
        wx, wz = g["world"][0], g["world"][2]
        d = np.hypot(gx - wx, gz - wz)
        ring = (d > SIGHT_INNER) & (d <= SIGHT_OUTER)
        for f in s.figures:
            if f is not g and "world" in f:
                ring &= np.hypot(gx - f["world"][0], gz - f["world"][2]) > RING_CLEAR
        n_red, n_pale = int((red & ring).sum()), int((pale & ring).sum())
        is_shown = g["index"] == shown
        drawn = n_pale >= SIGHT_PIXELS or (is_shown and n_red >= SIGHT_PIXELS)
        out[g["name"]] = {"drawn": drawn, "shown": is_shown, "red": n_red, "pale": n_pale}
    return out


def route(s, guards: list) -> dict:
    """The safest route can be read when the ground joins the chosen crew
    member to the exit in view, and each guard's sight is drawn."""
    crew = _crew_named(s)
    chosen = s.info.get("chosen", -1)
    pick = next((f for f in crew if f["index"] == chosen), crew[0] if crew else None)
    why = []
    if pick is None or not (s.cls == M.EXIT).any():
        return {"found": False, "why": ["no chosen crew member or no exit in view"]}
    passable = np.isin(s.cls, (M.WALKABLE, M.PATH, M.DECORATION, M.CREW, M.GUARD, M.EXIT, M.VAULT,
                               M.MARKER, M.SHADOW, M.GUARD_SHADOW)) & ~s.covered
    fx, fy = (int(round(v)) for v in pick["feet"])
    seed = np.zeros_like(passable)
    seed[max(0, fy - CELL):fy + CELL, max(0, fx - CELL):fx + CELL] = True
    seed &= passable | (s.cls == M.CREW)
    goal = (s.cls == M.EXIT) & ~s.covered
    joined = False
    if seed.any() and goal.any():
        for _n, _box, cells in M.components(passable | seed, step=CELL, least=1):
            ys, xs = zip(*cells)
            grid = np.zeros((s.h // CELL + 1, s.w // CELL + 1), bool)
            grid[list(ys), list(xs)] = True
            sy, sx = np.nonzero(seed[: s.h - s.h % CELL, : s.w - s.w % CELL].reshape(
                s.h // CELL, CELL, s.w // CELL, CELL).any(axis=(1, 3)))
            gy, gx = np.nonzero(goal[: s.h - s.h % CELL, : s.w - s.w % CELL].reshape(
                s.h // CELL, CELL, s.w // CELL, CELL).any(axis=(1, 3)))
            if grid[sy, sx].any() and grid[gy, gx].any():
                joined = True
                break
    if not joined:
        why.append("ground does not join the chosen crew member to the exit")
    sight = sight_of(s, guards)
    unseen = [name for name, r in sight.items() if not r["drawn"]]
    if unseen:
        why.append("no sight drawn for " + ", ".join(unseen))
    return {"found": not why, "why": why, "joined": joined, "guards_without_sight": unseen,
            "sight": sight}


def score(folder: Path) -> dict:
    """Answer the five questions for one masked still."""
    s = M.Still(Path(folder))
    crew = [figure_found(s, f) for f in _crew_named(s)]
    guards_f = _guards_in_view(s)
    guards = [figure_found(s, f) for f in guards_f]
    answers = {
        "crew": {"found": bool(crew) and all(r["found"] for r in crew), "figures": crew},
        "guards": {"found": bool(guards) and all(r["found"] for r in guards), "figures": guards},
        "vault": object_found(s, "vault"),
        "exit": object_found(s, "exit"),
        "route": route(s, guards_f),
    }
    right = sum(1 for k, _q in QUESTIONS if answers[k]["found"])
    return {"still": str(folder), "answers": answers, "right": right, "of": len(QUESTIONS)}


def score_clip(folders: list, seconds: float = FRAME_SECONDS) -> dict:
    """The gait of a clip, from the chosen crew member's feet across a series
    of masked frames: the screen speed in points per second, then the gait."""
    pts = []
    pt = None
    for d in folders:
        info = json.loads((Path(d) / "mask.json").read_text())
        pt = 360.0 / info["frame"][0]
        chosen = info.get("chosen", -1)
        crew = [f for f in info["figures"] if f["kind"] == "crew"]
        pick = next((f for f in crew if f["index"] == chosen), crew[0] if crew else None)
        if pick is None:
            return {"gait": None, "speed": None, "why": f"no crew member in {Path(d).name}"}
        pts.append(pick["feet"])
    if pt is None or len(pts) < 2:
        return {"gait": None, "speed": None, "why": "fewer than two frames"}
    path = sum(np.hypot(b[0] - a[0], b[1] - a[1]) for a, b in zip(pts, pts[1:])) * pt
    speed = path / (seconds * (len(pts) - 1))
    gait = "sneak" if speed < GAIT_EDGES[0] else "walk" if speed < GAIT_EDGES[1] else "run"
    return {"gait": gait, "speed": round(float(speed), 2)}


def render_one(out: Path, name: str, env_add: dict) -> None:
    d = out / name
    d.mkdir(parents=True, exist_ok=True)
    env = dict(os.environ, SHOT_TIMEOUT=os.environ.get("SHOT_TIMEOUT", "1200"), MASK_NO_IMPORT="1", **env_add)
    with open(d / "mask.out", "w") as f:
        subprocess.run([sys.executable, str(ROOT / "tools/render/mask.py"), str(ROOT / SHOT), str(d)],
                       env=env, stdout=f, stderr=subprocess.STDOUT, text=True)


def table(results: dict) -> str:
    head = ["| Still"] + [k for k, _q in QUESTIONS] + ["right |"]
    out = [" | ".join(head), "|" + "---|" * (len(QUESTIONS) + 2)]
    totals = {k: 0 for k, _q in QUESTIONS}
    n = 0
    for name, r in results.items():
        if "error" in r:
            out.append(f"| {name} | " + " | ".join(["n/a"] * len(QUESTIONS)) + " | |")
            continue
        n += 1
        cells = []
        for k, _q in QUESTIONS:
            a = r["answers"][k]
            totals[k] += int(a["found"])
            cells.append("yes" if a["found"] else "no")
        out.append(f"| {name} | " + " | ".join(cells) + f" | {r['right']} of {r['of']} |")
    if n:
        total = sum(totals.values())
        out.append("| **all** | " + " | ".join(f"{totals[k]} of {n}" for k, _q in QUESTIONS)
                   + f" | {total} of {n * len(QUESTIONS)} ({100 * total / (n * len(QUESTIONS)):.0f}%) |")
    return "\n".join(out)


def reasons(results: dict) -> str:
    lines = []
    for name, r in results.items():
        if "error" in r:
            lines.append(f"- {name}: {r['error']}")
            continue
        for k, _q in QUESTIONS:
            a = r["answers"][k]
            if a["found"]:
                continue
            if "figures" in a:
                bad = [f"{f['name']} ({', '.join(f['why'])})" for f in a["figures"] if not f["found"]]
                lines.append(f"- {name}, {k}: " + "; ".join(bad or ["no figure in view"]))
            else:
                lines.append(f"- {name}, {k}: " + ", ".join(a["why"]))
    return "\n".join(lines)


def run(out: Path, jobs: int, render: bool, only: list) -> dict:
    names = [n for n in STILLS if not only or n in only]
    if render:
        with ThreadPoolExecutor(max_workers=jobs) as pool:
            list(pool.map(lambda n: render_one(out, n, STILLS[n]), names))
    results = {}
    for n in names:
        try:
            results[n] = score(out / n)
        except (OSError, KeyError, ValueError) as e:
            results[n] = {"error": f"{type(e).__name__}: {e}"}
    return results


def self_test() -> None:
    """A drawn still whose five answers are known, its guard's sight drawn,
    missing and under another guard's rule, and a drawn clip."""
    import tempfile
    from PIL import Image
    w, h = 90, 195
    # The ground of the drawn still: 10 pixels a metre, x right, z down.
    def feet(x, z):
        return [10 + 10 * x, 40 + 10 * z]
    with tempfile.TemporaryDirectory() as tmp:
        d = Path(tmp)
        ua = np.zeros((h, w, 4), np.uint8)
        ua[..., 3] = 255
        ub = ua.copy()
        ua[..., 0] = 255
        ub[..., 1] = 255
        for im in (ua, ub):
            im[:30] = (90, 90, 90, 255)
            im[170:] = (90, 90, 90, 255)
        Image.fromarray(ua).save(d / "ui_a.png")
        Image.fromarray(ub).save(d / "ui_b.png")
        idp = np.zeros((h, w, 4), np.uint8)
        idp[..., 3] = 255
        idp[..., :3] = M.code(M.WALKABLE, M.T_OPEN)
        idp[50:150, 18:70, :3] = M.code(M.PATH, 0)        # a path joins them all
        idp[60:100, 10:18, :3] = M.code(M.CREW, 0)       # crew: 40 px = 160 pt, tall
        idp[60:100, 60:68, :3] = M.code(M.GUARD, 0)      # guard
        idp[90:110, 38:58, :3] = M.code(M.VAULT, 0)
        idp[120:136, 65:85, :3] = M.code(M.EXIT, 0)
        Image.fromarray(idp).save(d / "id.png")
        world = np.full((h, w, 4), 40, np.uint8)
        world[60:100, 10:18, :3] = 230
        world[60:100, 60:68, :3] = 230
        Image.fromarray(world).save(d / "world.png")
        Image.fromarray(np.full((h, w, 4), 40, np.uint8)).save(d / "behind.png")
        Image.fromarray(np.zeros((h, w, 4), np.uint8)).save(d / "markers.png")
        for name, box in (("c0", (60, 100, 10, 18)), ("g0", (60, 100, 60, 68))):
            solo = np.zeros((h, w, 4), np.uint8)
            solo[box[0]:box[1], box[2]:box[3]] = (40, 8, 8, 255)
            Image.fromarray(solo).save(d / f"solo_{name}.png")
        # g0's sight: a wedge ahead of it, 1 to 1.8 m from its feet.
        yy, xx = np.mgrid[0:h, 0:w]
        fx, fy = feet(5.4, 6.0)
        dist = np.hypot(xx + 0.5 - fx, yy + 0.5 - fy)
        wedge = (dist > 10) & (dist < 18) & (yy < fy - 6) & (np.abs(xx + 0.5 - fx) < 8)

        def marks(colour):
            m = np.zeros((h, w, 4), np.uint8)
            m[..., 3] = 255
            if colour is not None:
                m[wedge] = (*colour, 255)
            Image.fromarray(m).save(d / "marks3d.png")
        marks((150, 140, 165))                          # a guard's pale fan, as rendered
        info = {"frame": [w, h], "view_rect": [0, 0, w, h], "chosen": 0, "zoom": 1,
                "vault": {"rect": [40, 90, 10, 20], "centre": [45, 100]},
                "exit": {"rect": [70, 120, 15, 10], "centre": [77, 125]},
                "figures": [
                    {"kind": "crew", "index": 0, "role": "rogue", "visible": True, "rect": [10, 60, 8, 40],
                     "head": [14, 60], "feet": feet(0.4, 6.0), "span": 40, "world": [0.4, 0, 6.0]},
                    {"kind": "guard", "index": 0, "role": "guard", "visible": True, "rect": [60, 60, 8, 40],
                     "head": [64, 60], "feet": feet(5.4, 6.0), "span": 40, "world": [5.4, 0, 6.0],
                     "state": "Unaware"},
                    # Wholly off the frame: shown, but no pixel of either is drawn.
                    {"kind": "crew", "index": 1, "role": "brute", "visible": True, "rect": [-60, -20, 8, 40],
                     "head": [-56, -20], "feet": feet(-6.6, -2.0), "span": 40, "world": [-6.6, 0, -2.0]},
                    {"kind": "guard", "index": 1, "role": "guard", "visible": True, "rect": [196, 260, 8, 40],
                     "head": [200, 260], "feet": feet(19.0, 26.0), "span": 40, "world": [19.0, 0, 26.0],
                     "state": "Unaware"}]}
        (d / "mask.json").write_text(json.dumps(info))
        r = score(d)
        a = r["answers"]
        assert len(a["crew"]["figures"]) == 1 and len(a["guards"]["figures"]) == 1, a
        assert a["crew"]["found"] and a["guards"]["found"], a
        assert a["vault"]["found"] and a["exit"]["found"], a
        assert list(a["route"]["sight"]) == ["g0"], a["route"]
        assert a["route"]["found"], a["route"]
        assert r["right"] == 5, r
        # No sight round the guard: the route is not found.
        marks(None)
        r = score(d)
        assert r["answers"]["route"]["guards_without_sight"] == ["g0"] and r["right"] == 4, r
        # The crew rings' orange is not a sight.
        marks((180, 100, 20))
        r = score(d)
        assert r["answers"]["route"]["guards_without_sight"] == ["g0"], r["answers"]["route"]
        # Nor are the effects' pink sparks.
        marks((240, 205, 225))
        r = score(d)
        assert r["answers"]["route"]["guards_without_sight"] == ["g0"], r["answers"]["route"]
        # The crimson cone counts for the shown guard alone.
        marks((120, 22, 42))
        r = score(d)
        assert r["answers"]["route"]["sight"]["g0"]["shown"] and r["right"] == 5, r
        info["figures"][3]["state"] = "Alerted"     # now g1 is the shown guard
        (d / "mask.json").write_text(json.dumps(info))
        r = score(d)
        assert not r["answers"]["route"]["sight"]["g0"]["shown"] and r["right"] == 4, r
        # Under a panel, the sight does not count.
        info["figures"][3]["state"] = "Unaware"
        (d / "mask.json").write_text(json.dumps(info))
        for p in ("ui_a.png", "ui_b.png"):
            im = np.array(Image.open(d / p))
            im[wedge] = (90, 90, 90, 255)
            Image.fromarray(im).save(d / p)
        r = score(d)
        assert not r["answers"]["route"]["found"], r["answers"]["route"]
        # Fewer than four figures do not fix the ground.
        few = dict(info, figures=info["figures"][:2])
        (d / "mask.json").write_text(json.dumps(few))
        r = score(d)
        assert r["answers"]["route"]["sight"]["g0"]["why"] == "ground not fixed", r["answers"]["route"]
        (d / "mask.json").write_text(json.dumps(info))
        # A crew member the same gray as the ground is not found.
        Image.fromarray(np.full((h, w, 4), 40, np.uint8)).save(d / "world.png")
        r = score(d)
        assert not r["answers"]["crew"]["found"], r
        # A clip: feet at 2 points per second read as a sneak, 60 as a run.
        folders = []
        for i in range(3):
            c = d / f"f{i}"
            c.mkdir()
            inf = json.loads(json.dumps(info))
            inf["figures"][0]["feet"] = [14 + 0.1 * i, 100]
            (c / "mask.json").write_text(json.dumps(inf))
            folders.append(c)
        assert score_clip(folders)["gait"] == "sneak", score_clip(folders)
        for i, c in enumerate(folders):
            inf = json.loads((c / "mask.json").read_text())
            inf["figures"][0]["feet"] = [14 + 3.0 * i, 100]
            (c / "mask.json").write_text(json.dumps(inf))
        assert score_clip(folders)["gait"] == "run", score_clip(folders)
        # A frame with no crew member gives no gait, and no error.
        inf = json.loads((folders[1] / "mask.json").read_text())
        inf["figures"] = [f for f in inf["figures"] if f["kind"] != "crew"]
        (folders[1] / "mask.json").write_text(json.dumps(inf))
        assert score_clip(folders)["gait"] is None, score_clip(folders)
        assert score_clip(folders[:1])["gait"] is None
    print("findit self-test: ok")


def main() -> int:
    if sys.argv[1:] == ["--self-test"]:
        self_test()
        return 0
    jobs = 3
    only = []
    pos = []
    it = iter(sys.argv[1:])
    for a in it:
        if a == "--jobs":
            jobs = int(next(it))
        elif a == "--only":
            only = next(it).split(",")
        elif not a.startswith("--"):
            pos.append(a)
    if len(pos) != 1:
        print(__doc__)
        return 2
    out = Path(pos[0]).resolve()
    results = run(out, jobs, "--no-render" not in sys.argv, only)
    (out / "findit.json").write_text(json.dumps(results, indent=2, default=lambda o: o.item()) + "\n")
    text = table(results) + "\n\n" + reasons(results) + "\n"
    (out / "findit.md").write_text(text)
    print(text)
    return 0


if __name__ == "__main__":
    sys.exit(main())
