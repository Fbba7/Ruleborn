#!/usr/bin/env python3
"""Draw calls, texture memory and contrast for the five key screens
(report.md sections 3.8 and 10.1), at 100% and 200% text and in high
contrast: fifteen shots on the real renderer, against budgets.json ("shots").

    python3 tools/ui_bake/budget_shots.py [--only home/100,...] [--record] [--plant]

Each screen's own shot script (client/tests/shots/) is wrapped, in a scratch
folder, by a script that extends it and snapshots each frame with
measure.gd, so the shot is unchanged and its last frame is the one measured. A shot passes
when its draw calls are under 150 and no higher than recorded, its texture
interface textures (those its canvas items hold, at 4 bytes a pixel; the
fonts' glyph caches are reported beside them) are at most 24 MiB, and no more of its words sit below 4.5:1 over the
pixels behind them than recorded. --record writes today's figures when none
is recorded, and afterwards only lowers them. --plant adds one extra draw
call to every shot (a square with a material of its own), which the guard
must refuse; guard.sh --self-test uses it. Logs and stills go to
$UI_GUARD_LOGS (default: a folder under the system's temporary directory).
"""
import json
import os
import re
import subprocess
import sys
import tempfile

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.normpath(os.path.join(HERE, "..", ".."))
BUDGETS = os.path.join(HERE, "budgets.json")
GODOT = os.environ.get("RULEBORN_GODOT",
                       os.path.expanduser("~/.cache/ruleborn/Godot_v4.7.2-stable_linux.x86_64"))
MODES = ("100", "200", "hc")
LINE = re.compile(r"^guard-measure: (\{.*\})\s*$", re.M)

WRAPPER = """extends "res://%(rel)s"
## guard.sh's wrapper (tools/ui_bake/budget_shots.py): the shot unchanged,
## measured as it quits.

const _MEASURE := preload("%(measure)s")

var _guard := _MEASURE.new()


func _initialize() -> void:
	process_frame.connect(func() -> void: _guard.snap(self))
	if OS.get_environment("GUARD_HC") != "":
		Settings.high_contrast = true
		Settings.apply()
	if OS.get_environment("GUARD_PLANT") != "":
		var plant := ColorRect.new()
		plant.material = CanvasItemMaterial.new()
		plant.color = Color(1, 0, 1)
		plant.size = Vector2(8, 8)
		plant.z_index = 4096
		root.add_child(plant)
	super._initialize()


func _finalize() -> void:
	_guard.report()
"""


def load_budgets():
    with open(BUDGETS, encoding="utf-8") as f:
        return json.load(f)


def write_budgets(budgets):
    with open(BUDGETS, "w", encoding="utf-8") as f:
        f.write(json.dumps(budgets, indent=2, sort_keys=True) + "\n")


def keys(shots, only):
    every = ["%s/%s" % (s, m) for s in sorted(shots["screens"]) for m in MODES]
    if not only:
        return every
    wanted = only.split(",")
    unknown = [k for k in wanted if k not in every]
    if unknown:
        raise SystemExit("budget_shots: no shot %s; the shots are %s" % (unknown, ", ".join(every)))
    return wanted


def shoot(key, screen, scratch, logs, plant):
    """Runs one wrapped shot; its measure, or None with the log's path."""
    name, mode = key.split("/")
    rel = screen["script"][len("client/"):]
    wrapper = os.path.join(scratch, "guard_%s.gd" % name)
    if not os.path.exists(wrapper):
        with open(wrapper, "w", encoding="utf-8") as f:
            f.write(WRAPPER % {"rel": rel, "measure": os.path.join(HERE, "measure.gd")})
    env = dict(os.environ)
    for k in ("TEXT", "HC", "CONTRAST", "GUARD_HC", "GUARD_PLANT"):
        env.pop(k, None)
    env.update(screen.get("env", {}))
    if mode == "200":
        env["TEXT"] = "200"
    if mode == "hc":
        env.update(screen.get("hc_env", {}))
        env["GUARD_HC"] = "1"
    if plant:
        env["GUARD_PLANT"] = "1"
    stem = key.replace("/", "-")
    env["SHOT"] = os.path.join(logs, stem + ".png")
    log = os.path.join(logs, stem + ".log")
    cmd = ["timeout", os.environ.get("SHOT_TIMEOUT", "300"), "xvfb-run", "-a", "-s",
           "-screen 0 1080x2340x24", GODOT, "--rendering-driver", "opengl3",
           "--path", os.path.join(ROOT, "client"), "-s", wrapper]
    with open(log, "w", encoding="utf-8") as out:
        subprocess.run(cmd, env=env, stdout=out, stderr=subprocess.STDOUT, cwd=ROOT)
    with open(log, encoding="utf-8", errors="replace") as f:
        found = LINE.findall(f.read())
    return (json.loads(found[-1]) if found else None), log


def judge(key, got, recorded, limits):
    """Failures for one shot."""
    out = []
    calls = got["draw_calls"]
    if calls >= limits["draw_calls_below"]:
        out.append("%d draw calls, the limit is under %d (§21.3)" % (calls, limits["draw_calls_below"]))
    if recorded and calls > recorded["draw_calls"]:
        out.append("%d draw calls, recorded %d" % (calls, recorded["draw_calls"]))
    if got["texture_bytes"] > limits["texture_bytes_max"]:
        out.append("%.1f MiB of textures, the limit is %.0f MiB" % (
            got["texture_bytes"] / 1048576, limits["texture_bytes_max"] / 1048576))
    if recorded and got["words_below"] > recorded["words_below"]:
        out.append("%d words below %.1f:1, recorded %d: %s" % (
            got["words_below"], limits["contrast_floor"], recorded["words_below"],
            "; ".join(got["below"])))
    return out


def main(argv):
    record = "--record" in argv
    plant = "--plant" in argv
    only = ""
    if "--only" in argv:
        only = argv[argv.index("--only") + 1]
    budgets = load_budgets()
    shots = budgets["shots"]
    limits = shots["limits"]
    recorded = shots.get("recorded")
    first = recorded is None
    recorded = recorded or {}
    logs = os.environ.get("UI_GUARD_LOGS") or tempfile.mkdtemp(prefix="ui_guard_")
    os.makedirs(logs, exist_ok=True)
    scratch = tempfile.mkdtemp(prefix="ui_guard_wrappers_")
    subprocess.run([GODOT, "--headless", "--path", os.path.join(ROOT, "client"), "--import"],
                   stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
    failures, measured = [], {}
    for key in keys(shots, only):
        got, log = shoot(key, shots["screens"][key.split("/")[0]], scratch, logs, plant)
        if got is None:
            failures.append("%s: no measure (the shot did not finish; see %s)" % (key, log))
            print("budget_shots: %s FAIL, no measure, log %s" % (key, log), flush=True)
            continue
        measured[key] = {k: got[k] for k in ("draw_calls", "texture_bytes", "words_below")}
        problems = judge(key, got, None if first else recorded.get(key), limits)
        if not first and key not in recorded:
            problems.append("no recorded figures; run --record")
        print("budget_shots: %s %s: %d draw calls (recorded %s), %.1f MiB textures "
              "(%.1f MiB glyph caches beside), "
              "%d of %d words below %.1f:1 (recorded %s), worst %.2f" % (
                  key, "FAIL" if problems else "ok", got["draw_calls"],
                  recorded.get(key, {}).get("draw_calls", "none"), got["texture_bytes"] / 1048576,
                  got["font_cache_bytes"] / 1048576, got["words_below"], got["words"], limits["contrast_floor"],
                  recorded.get(key, {}).get("words_below", "none"), got["worst_ratio"]), flush=True)
        failures += ["%s: %s" % (key, p) for p in problems]
    print("budget_shots: logs and stills in %s" % logs)
    if record and not plant:
        if failures and not first:
            print("budget_shots: --record never raises a figure; a rise needs a request "
                  "to K1 and the lead's approval (kit-spec.md section 6.8)")
            for f in failures:
                print("FAIL " + f)
            return 1
        missing = [k for k in keys(shots, only) if k not in measured]
        if missing:
            print("budget_shots: not recorded, shots without a measure: %s" % ", ".join(missing))
            return 1
        for key, got in measured.items():
            was = recorded.get(key)
            if was:
                got = {k: min(got[k], was[k]) for k in got}
            recorded[key] = got
        shots["recorded"] = recorded
        write_budgets(budgets)
        print("budget_shots: recorded %d shots" % len(measured))
        return 0
    for f in failures:
        print("FAIL " + f)
    print("budget_shots: %s" % ("FAIL" if failures else "OK"))
    return 1 if failures else 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
