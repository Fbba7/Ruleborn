#!/usr/bin/env python3
"""Mask and measure one still (3D0-M2-mask-tool).

    python3 tools/render/mask.py client/tests/shots/screen_heist.gd OUTDIR

Runs the shot script as tools/render/shoot.sh does (Godot's Compatibility
renderer under Xvfb), with its quit() replaced by the mask pass
(tools/render/mask_pass.gd), which draws the same frame again as flat
masks into OUTDIR. Then tools/render/measure.py reads them and writes
OUTDIR/measure.json, Q1 to Q6, Q11 and Q12, and prints them.

The shot's own settings go in the environment as for shoot.sh (MOMENT,
ZOOM, HOUR, ...), and TILES sets a camera between zoom levels (the
plan's 11 tiles). --no-render measures masks already in OUTDIR.
tools/render/mask_matrix.py runs the plan's eight-moment matrix.
docs/art/3d-quality/mask.md is the method.
"""
import os
import re
import subprocess
import sys
import tempfile
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
GODOT = os.environ.get("RULEBORN_GODOT", str(Path.home() / ".cache/ruleborn/Godot_v4.7.2-stable_linux.x86_64"))


def patched(source: str, mask_pass: Path) -> str:
    """The shot script with each quit() running the mask pass first."""
    lines = [ln for ln in source.splitlines() if not ln.startswith("class_name ")]
    body = "\n".join(lines)
    body = re.sub(r"(?<![\w.])quit\(", "_mask_quit(", body)
    return body + f"""


func _mask_quit(code := 0) -> void:
\tif code == 0:
\t\tvar script: GDScript = load("{mask_pass}")
\t\tif script == null or not script.can_instantiate():
\t\t\tprinterr("mask: the mask pass failed to load")
\t\t\tquit(3)
\t\t\treturn
\t\tvar mask_pass: RefCounted = script.new()
\t\tawait mask_pass.run(self)
\tquit(code)
"""


def render(shot: Path, out: Path, w: int, h: int) -> int:
    out.mkdir(parents=True, exist_ok=True)
    if not os.access(GODOT, os.X_OK):
        subprocess.run(["bash", str(ROOT / "client/build.sh")], check=True, stdout=subprocess.DEVNULL)
    if not os.environ.get("MASK_NO_IMPORT"):
        subprocess.run([GODOT, "--headless", "--path", str(ROOT / "client"), "--import"],
                       stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
    with tempfile.TemporaryDirectory() as tmp:
        script = Path(tmp) / ("mask_" + shot.name)
        script.write_text(patched(shot.read_text(), ROOT / "tools/render/mask_pass.gd"))
        env = dict(os.environ, SHOT=str(out / "shot.png"), MASK_OUT=str(out))
        cmd = ["timeout", os.environ.get("SHOT_TIMEOUT", "300"), "xvfb-run", "-a", "-s",
               f"-screen 0 {w}x{h}x24", GODOT, "--rendering-driver", "opengl3",
               "--path", str(ROOT / "client"), "-s", str(script)]
        with open(out / "godot.log", "w") as f:
            run = subprocess.run(cmd, env=env, stdout=f, stderr=subprocess.STDOUT, text=True)
    log = (out / "godot.log").read_text(errors="replace").splitlines()
    for ln in log:
        if ln.startswith(("budget:", "mask:", "SCRIPT ERROR", "ERROR: Parse", "fit ")):
            print(ln)
    return run.returncode


def main() -> int:
    args = [a for a in sys.argv[1:] if not a.startswith("--")]
    if len(args) != 2:
        print(__doc__)
        return 2
    shot, out = Path(args[0]).resolve(), Path(args[1]).resolve()
    if "--no-render" not in sys.argv:
        code = render(shot, out, int(os.environ.get("W", 1080)), int(os.environ.get("H", 2340)))
        if not (out / "id.png").exists():
            print(f"mask: the pass wrote no masks (exit {code}); see {out / 'godot.log'}")
            return 1
    sys.path.insert(0, str(Path(__file__).parent))
    import measure
    result = measure.measure(out)
    measure.write(out, result)
    print(measure.summary(result))
    return 0


if __name__ == "__main__":
    sys.exit(main())
