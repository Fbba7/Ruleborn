#!/usr/bin/env python3
"""The 3D baseline (3D0-M1-baseline): one command renders and measures every
3D shot, then writes docs/art/3d-quality/baseline.md.

    python3 docs/art/3d-quality/baseline/run.py [--jobs 2] [--only NAME,NAME] [--no-render]

For each shot it runs tools/render/mask.py (the mask tool of 3D0-M2-mask-tool)
into /tmp/ruleborn_baseline/<name>/ (or $BASELINE_WORK/<name>/; only
measure.json and the budget line are kept, in baseline/data/<name>.json), then
builds the table. The shot's own settings are in SHOTS below (TAB for
screen_defences, etc.). A shot that prints no budget line of its own gets one
added to a copy of its script (INJECT below); the script in client/ is not
changed.

It exits 1 when a shot fails for any reason but the mask tool's known limit
(request M1-R2: no WorldView in the shot, or an error inside mask_pass.gd):
no still, no "wrote" or "saved" line, no budget line, a script error in the shot, or a
timeout. Each shot's verdict is printed, and kept in its data file.
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

# name -> (shot script, environment, budget line to add before print("wrote") or None)
LAWS_LINE = '\tawait BudgetSplit.line(self, "laws")\n'
# universe_screens holds the screen in a Control variable; its UniverseView is
# read with get() and printed like universe_home.gd and universe_zoom.gd do.
UNIVERSE_LINE = (
    '\tvar _baseline_world: UniverseView = screen.get("world")\n'
    '\tprint("triangles ", _baseline_world.triangles, " draw calls ", _baseline_world.draw_calls(), " frame ",\n'
    '\t\tRenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_TOTAL_PRIMITIVES_IN_FRAME), " prims ",\n'
    '\t\tRenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_TOTAL_DRAW_CALLS_IN_FRAME), " calls")\n')
INJECT = {
    "screen_laws": LAWS_LINE,
    "universe_map": UNIVERSE_LINE,
    "universe_screen": UNIVERSE_LINE,
}

# name -> (shot script, environment)
SHOTS = {
    "screen_heist": ("screen_heist.gd", {}),
    "screen_replay": ("screen_replay.gd", {}),
    "screen_result": ("screen_result.gd", {}),
    "screen_laws": ("screen_laws.gd", {}),
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
    "universe_map": ("universe_screens.gd", {"SCREEN": "map"}),
    "universe_screen": ("universe_screens.gd", {"SCREEN": "universe"}),
}

BUDGET = re.compile(r"^budget: (\S+): (.*)$")


def script_for(name: str, out: Path) -> Path:
    """The shot script, or a copy with a budget line added (INJECT)."""
    src = ROOT / "client/tests/shots" / SHOTS[name][0]
    line = INJECT.get(name)
    if line is None:
        return src
    text = src.read_text()
    anchor = '\tprint("wrote")\n'
    if anchor not in text:
        raise SystemExit(f"{name}: no print(\"wrote\") in {src.name} to add the budget line before")
    out.mkdir(parents=True, exist_ok=True)
    copy = out / "src" / src.name
    copy.parent.mkdir(exist_ok=True)
    copy.write_text(text.replace(anchor, line + anchor, 1))
    return copy


def run_one(name: str) -> dict:
    _script, env = SHOTS[name]
    out = WORK / name
    for old in ("shot.png", "godot.log", "measure.json", "id.png"):
        (out / old).unlink(missing_ok=True)
    cmd = [sys.executable, str(ROOT / "tools/render/mask.py"), str(script_for(name, out)), str(out)]
    r = subprocess.run(cmd, env=dict(os.environ, **env), capture_output=True, text=True, cwd=ROOT)
    return {"name": name, "returncode": r.returncode, "stdout": r.stdout[-4000:]}


def verdict(name: str) -> tuple:
    """("ok" | "mask limit" | "failed", reason). A mask limit is request M1-R2."""
    out = WORK / name
    log = out / "godot.log"
    if not log.exists():
        return "failed", "no godot.log (the shot did not run)"
    lines = log.read_text(errors="replace").splitlines()
    # The shots end on "wrote", "wrote <state>" (screen_result) or "saved <size>" (universe_zoom).
    if not (out / "shot.png").exists() or not any(ln.strip() == "wrote" or ln.startswith(("wrote ", "saved ("))
                                                  for ln in lines):
        return "failed", "no still written (no shot.png or no \"wrote\" / \"saved\")"
    if not any(ln.startswith(("budget:", "draw calls ", "triangles ")) for ln in lines):
        return "failed", "no budget line"
    errors = []
    for i, ln in enumerate(lines):
        if ln.startswith(("SCRIPT ERROR", "ERROR: Parse")):
            # The error's own frame is its "at:" line, the next line of the log.
            at = lines[i + 1].strip() if i + 1 < len(lines) else ""
            errors.append((ln.strip(), at.startswith("at:") and "/tools/render/mask_pass.gd:" in at))
    shot_errors = [e for e, in_mask in errors if not in_mask]
    if shot_errors:
        return "failed", "script error in the shot: " + shot_errors[0]
    if (out / "measure.json").exists():
        return "ok", ""
    if errors:
        return "mask limit", "error inside mask_pass.gd: " + errors[0][0]
    if any("mask: no WorldView" in ln for ln in lines):
        return "mask limit", "no WorldView in the shot"
    return "failed", "the mask tool measured nothing, for no known reason"


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
        unknown = [n for n in names if n not in SHOTS]
        if unknown:
            raise SystemExit(f"unknown shots: {', '.join(unknown)}")
    failed = []
    if "--no-render" not in args:
        with ThreadPoolExecutor(jobs) as ex:
            for res in ex.map(run_one, names):
                state, why = verdict(res["name"])
                print(f"{res['name']}: mask.py exit {res['returncode']}, {state}" + (f" ({why})" if why else ""),
                      flush=True)
                if state == "failed":
                    failed.append(res["name"])
                    print(res["stdout"], flush=True)
    DATA.mkdir(exist_ok=True)
    for n in names:
        rec = collect(n)
        (DATA / f"{n}.json").write_text(json.dumps(rec, indent=1, sort_keys=True) + "\n")
    import table
    table.write(HERE.parent / "baseline.md")
    if failed:
        print(f"{len(failed)} shot(s) failed: {', '.join(failed)}", file=sys.stderr)
        return 1
    return 0


if __name__ == "__main__":
    sys.path.insert(0, str(HERE))
    sys.exit(main())
