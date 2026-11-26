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
--self-test draws a small stage through the mask pass and checks that
the stage's own interface (drawn over the stage, as the character
screen's pills are) reads as interface, not world.
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


# The self-test's shot: a stage in the frame's top half, its backdrop and
# foot fade as built, and over it a magenta plate added as the character
# screen adds its level badge (stage.add_child), at x 10-30%, y 10-30% of
# the stage. Below the stage nothing is drawn.
SELF_SHOT = """extends SceneTree
func _initialize() -> void:
\t_go()


func _go() -> void:
\troot.size = Vector2i(1080, 2340)
\tvar stage := StageHero.new()
\tstage.anchor_right = 1.0
\tstage.anchor_bottom = 0.5
\troot.add_child(stage)
\tvar badge := Control.new()
\tbadge.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
\tstage.add_child(badge)
\tvar plate := ColorRect.new()
\tplate.color = Color(1, 0, 1)
\tplate.anchor_left = 0.1
\tplate.anchor_right = 0.3
\tplate.anchor_top = 0.1
\tplate.anchor_bottom = 0.3
\tbadge.add_child(plate)
\tfor i in 10:
\t\tawait process_frame
\tstage.moving = false
\tawait RenderingServer.frame_post_draw
\troot.get_texture().get_image().save_png(OS.get_environment("SHOT"))
\tquit()
"""


def self_test() -> int:
    """The stage's own interface reads as interface (ui_a = ui_b, hidden in
    world.png and id.png); its backdrop as world; nothing drawn is black."""
    import numpy as np
    from PIL import Image
    bad = []
    with tempfile.TemporaryDirectory() as tmp:
        shot, out = Path(tmp) / "mask_self.gd", Path(tmp) / "out"
        shot.write_text(SELF_SHOT)
        code = render(shot, out, 540, 1170)
        if not (out / "id.png").exists():
            print(f"self-test FAIL: the pass wrote no masks (exit {code})")
            print((out / "godot.log").read_text(errors="replace")[-3000:])
            return 1
        im = {n: np.asarray(Image.open(out / f"{n}.png").convert("RGB")).astype(int)
              for n in ("beauty", "ui_a", "ui_b", "world", "behind", "id")}
        h, w = im["beauty"].shape[:2]

        def at(name: str, fx: float, fy: float) -> np.ndarray:
            return im[name][int(fy * h), int(fx * w)]

        def near(a: np.ndarray, b, tol: int = 8) -> bool:
            return bool(np.abs(a - np.asarray(b)).max() <= tol)

        # The foot fade fills the stage's last fifth (frame rows 40-50%).
        plate, back, foot, below = (0.2, 0.1), (0.7, 0.3), (0.5, 0.48), (0.5, 0.8)
        checks = [
            ("beauty shows the plate", near(at("beauty", *plate), (255, 0, 255))),
            ("ui_a shows the plate (interface)", near(at("ui_a", *plate), (255, 0, 255))),
            ("ui_b shows the plate (interface)", near(at("ui_b", *plate), (255, 0, 255))),
            ("world.png hides the plate", not near(at("world", *plate), (255, 0, 255), 60)),
            ("behind.png hides the plate", not near(at("behind", *plate), (255, 0, 255), 60)),
            ("id.png hides the plate", near(at("id", *plate), (0, 0, 0), 2)),
            ("ui_a covers the backdrop red", near(at("ui_a", *back), (255, 0, 0))),
            ("ui_b covers the backdrop green", near(at("ui_b", *back), (0, 255, 0))),
            ("world.png shows the backdrop", near(at("world", *back), at("beauty", *back))),
            ("ui_a covers the foot fade red (world)", near(at("ui_a", *foot), (255, 0, 0))),
            ("world.png shows the foot fade", near(at("world", *foot), at("beauty", *foot))),
            ("world.png is black where nothing is drawn", near(at("world", *below), (0, 0, 0), 2)),
        ]
        for name, ok in checks:
            print(("ok   " if ok else "FAIL ") + name)
            if not ok:
                bad.append(name)
    print("self-test " + ("FAIL" if bad else "ok"))
    return 1 if bad else 0


def main() -> int:
    if "--self-test" in sys.argv:
        return self_test()
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
