#!/usr/bin/env python3
"""The 3D baseline (3D0-M1-baseline): one command renders and measures every
3D shot, then writes docs/art/3d-quality/baseline.md.

    python3 docs/art/3d-quality/baseline/run.py [--jobs 2] [--only NAME,NAME] [--no-render]

For each shot it runs tools/render/mask.py (the mask tool of 3D0-M2-mask-tool)
into baseline/work/<name>/ (git-ignored by size: only measure.json and the
budget line are kept in baseline/data/<name>.json), then builds the table.
The shot's own settings are in SHOTS below (TAB for screen_defences, etc.).
"""
import json
import os
import re
import subprocess
import sys
from concurrent.futures import ThreadPoolExecutor
from pathlib import Path

HERE = Path(__file__).resolve().parent
ROOT = HERE.parents[3]
WORK = Path(os.environ.get("BASELINE_WORK", "/tmp/ruleborn_baseline"))
DATA = HERE / "data"

# name -> (shot script, environment)
SHOTS = {
    "screen_heist": ("screen_heist.gd", {}),
    "screen_replay": ("screen_replay.gd", {}),
    "screen_result": ("screen_result.gd", {}),
    "screen_defences": ("screen_defences.gd", {"TAB": "0"}),
    "screen_realm": ("screen_realm.gd", {}),
    "screen_builder": ("screen_builder.gd", {}),
    "screen_curation": ("screen_curation.gd", {}),
    "screen_planner": ("screen_planner.gd", {}),
    "screen_scout": ("screen_scout.gd", {}),
    "screen_observatory": ("screen_observatory.gd", {}),
    "screen_landing": ("screen_landing.gd", {}),
    "screen_character": ("screen_character.gd", {}),
    "screen_roster": ("screen_roster.gd", {}),
    "screen_sage_hall": ("screen_sage_hall.gd", {}),
    "screen_forms": ("screen_forms.gd", {}),
    "screen_hatch": ("screen_hatch.gd", {}),
    "screen_first": ("screen_first.gd", {}),
    "universe_home": ("universe_home.gd", {}),
    "universe_zoom": ("universe_zoom.gd", {}),
}

BUDGET = re.compile(r"^budget: (\S+): (.*)$")


def run_one(name: str) -> dict:
    script, env = SHOTS[name]
    out = WORK / name
    cmd = [sys.executable, str(ROOT / "tools/render/mask.py"), str(ROOT / "client/tests/shots" / script), str(out)]
    r = subprocess.run(cmd, env=dict(os.environ, **env), capture_output=True, text=True, cwd=ROOT)
    return {"name": name, "returncode": r.returncode, "stdout": r.stdout[-4000:]}


def collect(name: str) -> dict:
    out = WORK / name
    rec = {"name": name, "budget": None, "measure": None}
    log = out / "godot.log"
    if log.exists():
        for ln in log.read_text(errors="replace").splitlines():
            if ln.startswith(("budget:", "draw calls ", "triangles ")):
                rec["budget"] = ln
    mj = out / "measure.json"
    if mj.exists():
        rec["measure"] = json.loads(mj.read_text())
    return rec


def main() -> int:
    args = sys.argv[1:]
    jobs = int(args[args.index("--jobs") + 1]) if "--jobs" in args else 2
    names = list(SHOTS)
    if "--only" in args:
        names = args[args.index("--only") + 1].split(",")
    if "--no-render" not in args:
        with ThreadPoolExecutor(jobs) as ex:
            for res in ex.map(run_one, names):
                print(res["name"], "exit", res["returncode"], flush=True)
    DATA.mkdir(exist_ok=True)
    for n in names:
        rec = collect(n)
        (DATA / f"{n}.json").write_text(json.dumps(rec, indent=1, sort_keys=True) + "\n")
    import table
    table.write(HERE.parent / "baseline.md")
    return 0


if __name__ == "__main__":
    sys.path.insert(0, str(HERE))
    sys.exit(main())
