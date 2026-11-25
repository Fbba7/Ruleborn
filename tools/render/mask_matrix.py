#!/usr/bin/env python3
"""The plan's eight-moment matrix, masked and measured (3D0-M2-mask-tool).

    python3 tools/render/mask_matrix.py OUTDIR [--jobs N] [--no-render]
        [--moments start,sneak,...] [--tiles 15,11,7]

Renders client/tests/shots/screen_heist.gd at each moment and camera width
through tools/render/mask.py (into OUTDIR/<moment>-<tiles>/), then compares
each still with the matrix of docs/art/3d-quality/plan.md, section 2.6:
the crew's heights, the nearest guard's and the vault's rating. It writes
OUTDIR/matrix.json and OUTDIR/matrix.md, and prints the table.

15 tiles is ZOOM 1 and 7 tiles ZOOM 2; 11 tiles lies between the zoom
levels, so it is drawn with TILES=11 (mask_pass.gd sets the camera there).
docs/art/3d-quality/mask.md states the tolerances.
"""
import json
import os
import subprocess
import sys
from concurrent.futures import ThreadPoolExecutor
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
SHOT = ROOT / "client/tests/shots/screen_heist.gd"
GODOT = os.environ.get("RULEBORN_GODOT", str(Path.home() / ".cache/ruleborn/Godot_v4.7.2-stable_linux.x86_64"))

# plan.md section 2.6: crew height range (points), nearest guard and vault
# at 15 / 11 / 7 tiles. "cross" is left out, as in the plan.
PLAN = {
    "start": ([(24, 28), (33, 38), (53, 60)], ["clear", "cut", "off"], ["clear", "under panel", "under panel"]),
    "sneak": ([(24, 28), (33, 38), (53, 60)], ["clear", "cut", "off"], ["clear", "clear", "clear"]),
    "vault": ([(24, 27), (33, 38), (53, 59)], ["clear", "clear", "cut"], ["clear", "clear", "clear"]),
    "alarm": ([(23, 28), (31, 38), (49, 61)], ["clear", "clear", "clear"], ["clear", "clear", "under panel"]),
    "escape": ([(25, 28), (34, 38), (53, 60)], ["cut", "off", "off"], ["clear", "clear", "off"]),
    "entry": ([(24, 27), (33, 37), (52, 59)], ["cut", "off", "off"], ["clear", "clear", "off"]),
    "hold": ([(24, 28), (33, 38), (53, 60)], ["clear", "cut", "off"], ["clear", "clear", "clear"]),
}
TILES = [15, 11, 7]
# A height within this share of the plan's range end counts as a match
# (mask.md, "Tolerances").
HEIGHT_TOL = 0.08


def env_for(tiles: int) -> dict:
    if tiles == 15:
        return {"ZOOM": "1"}
    if tiles == 7:
        return {"ZOOM": "2"}
    return {"ZOOM": "1", "TILES": str(tiles)}


def run_one(out: Path, moment: str, tiles: int, render: bool) -> dict:
    d = out / f"{moment}-{tiles}"
    if render:
        env = dict(os.environ, MOMENT=moment, SHOT_TIMEOUT=os.environ.get("SHOT_TIMEOUT", "1200"),
                   MASK_NO_IMPORT="1", **env_for(tiles))
        cmd = [sys.executable, str(ROOT / "tools/render/mask.py"), str(SHOT), str(d)]
    else:
        env = dict(os.environ)
        cmd = [sys.executable, str(ROOT / "tools/render/mask.py"), str(SHOT), str(d), "--no-render"]
    d.mkdir(parents=True, exist_ok=True)
    with open(d / "mask.out", "w") as f:
        subprocess.run(cmd, env=env, stdout=f, stderr=subprocess.STDOUT, text=True)
    p = d / "measure.json"
    return json.loads(p.read_text()) if p.exists() else {}


def within(v, lo, hi) -> bool:
    return v is not None and lo * (1 - HEIGHT_TOL) <= v <= hi * (1 + HEIGHT_TOL)


def compare(moment: str, k: int, m: dict) -> dict:
    heights, guards, vaults = PLAN[moment]
    lo, hi = heights[k]
    if not m:
        return {"moment": moment, "tiles": TILES[k], "error": "no measure"}
    q2, q11 = m["Q2"], m["Q11"]
    crew = [r["points"] for r in q2["crew"]]
    guard = (q11.get("nearest_guard") or {}).get("rating")
    vault = (q11.get("target") or {}).get("rating")
    row = {
        "moment": moment, "tiles": TILES[k],
        "crew": [min(crew), max(crew)] if crew else None, "plan_crew": [lo, hi],
        "crew_ok": bool(crew) and within(min(crew), lo, hi) and within(max(crew), lo, hi),
        "guards": [r["points"] for r in q2["guards"]],
        "silhouettes": [r["silhouette_points"] for r in q2["crew"]],
        "nearest_guard": guard, "plan_guard": guards[k], "guard_ok": guard == guards[k],
        "vault": vault, "plan_vault": vaults[k], "vault_ok": vault == vaults[k],
        "band": m["Q1"]["band"], "panels": m["Q1"]["panels_share"],
    }
    return row


def table(rows: list) -> str:
    out = ["| Moment | Tiles | Crew (pt) | Plan | Guards (pt) | Nearest guard / plan | Vault / plan |",
           "|---|---|---|---|---|---|---|"]
    for r in rows:
        if "error" in r:
            out.append(f"| {r['moment']} | {r['tiles']} | {r['error']} | | | | |")
            continue
        c = f"{r['crew'][0]:.1f}–{r['crew'][1]:.1f}" if r["crew"] else "none"
        mark = lambda ok: "" if ok else " ✗"
        g = ", ".join(f"{v:.1f}" for v in r["guards"])
        out.append(
            f"| {r['moment']} | {r['tiles']} | {c}{mark(r['crew_ok'])} | {r['plan_crew'][0]}–{r['plan_crew'][1]} | {g} "
            f"| {r['nearest_guard']} / {r['plan_guard']}{mark(r['guard_ok'])} "
            f"| {r['vault']} / {r['plan_vault']}{mark(r['vault_ok'])} |")
    n = [r for r in rows if "error" not in r]
    out.append("")
    out.append(f"Crew heights within tolerance: {sum(r['crew_ok'] for r in n)} of {len(n)}; "
               f"nearest guard as the plan: {sum(r['guard_ok'] for r in n)} of {len(n)}; "
               f"vault as the plan: {sum(r['vault_ok'] for r in n)} of {len(n)}.")
    return "\n".join(out)


def arg(name: str, default: str) -> str:
    if name in sys.argv:
        return sys.argv[sys.argv.index(name) + 1]
    return default


def main() -> int:
    pos = [a for i, a in enumerate(sys.argv[1:], 1)
           if not a.startswith("--") and sys.argv[i - 1] not in ("--jobs", "--moments", "--tiles")]
    if len(pos) != 1:
        print(__doc__)
        return 2
    out = Path(pos[0]).resolve()
    render = "--no-render" not in sys.argv
    moments = arg("--moments", ",".join(PLAN)).split(",")
    tiles = [int(t) for t in arg("--tiles", "15,11,7").split(",")]
    jobs = int(arg("--jobs", "2"))
    if render:
        subprocess.run([GODOT, "--headless", "--path", str(ROOT / "client"), "--import"],
                       stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
    work = [(m, t) for m in moments for t in tiles]
    with ThreadPoolExecutor(max_workers=jobs) as pool:
        results = list(pool.map(lambda w: run_one(out, w[0], w[1], render), work))
    rows = [compare(m, TILES.index(t), r) for (m, t), r in zip(work, results)]
    (out / "matrix.json").write_text(json.dumps(rows, indent=1) + "\n")
    text = table(rows)
    (out / "matrix.md").write_text(text + "\n")
    print(text)
    return 0


if __name__ == "__main__":
    sys.exit(main())
