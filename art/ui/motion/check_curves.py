#!/usr/bin/env python3
"""Holds art/ui/motion/curves.json to §21.8's and §20.8's rules.

Every step lasts rules.shortest_ms to rules.longest_ms and uses an easing
from rules.easings (an instant set, ms 0 with easing "none", is allowed);
every easing named has no overshoot; every motion has a full and a reduced
form, the reduced one naming its form; every sprite named is a piece of
client/ui/art/motion.json; nothing repeats faster than rules.flash_hz_most;
and the reduced reward keeps exactly one coin landing in its counter.

    python3 art/ui/motion/check_curves.py      # prints "ok" or each fault
"""
import json
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[3]
CURVES = ROOT / "art/ui/motion/curves.json"
MANIFEST = ROOT / "client/ui/art/motion.json"
FORMS = ("down", "up", "steps", "out", "in")


def steps_of(form):
    for key in FORMS:
        for step in form.get(key, []):
            yield key, step


def check(curves, pieces):
    faults = []
    rules = curves["rules"]
    lo, hi = rules["shortest_ms"], rules["longest_ms"]
    if rules.get("overshoot") is not False:
        faults.append("rules.overshoot must be false")
    for name in rules["easings"]:
        easing = curves["easings"].get(name)
        if easing is None:
            faults.append(f"easing {name} is not described")
        elif easing.get("overshoot") is not False:
            faults.append(f"easing {name} overshoots")
    if rules["shake_px_most"] > 4:
        faults.append("shake above 4 px (§21.8)")
    for mname, motion in curves["motions"].items():
        for fname in ("full", "reduced"):
            form = motion.get(fname)
            if form is None:
                faults.append(f"{mname} has no {fname} form")
                continue
            if fname == "reduced" and not form.get("form"):
                faults.append(f"{mname}.reduced names no form")
            period = form.get("period_ms")
            if period is not None and period < 1000 / rules["flash_hz_most"]:
                faults.append(f"{mname}.{fname} repeats faster than {rules['flash_hz_most']} a second")
            for key, step in steps_of(form):
                where = f"{mname}.{fname}.{key}.{step.get('name')}"
                ms, easing = step.get("ms"), step.get("easing")
                if ms == 0 and easing == "none":
                    pass
                elif not (lo <= ms <= hi):
                    faults.append(f"{where}: {ms} ms is outside {lo}-{hi}")
                elif easing not in rules["easings"]:
                    faults.append(f"{where}: easing {easing} is not allowed")
                if step.get("stagger_ms", 0) and step.get("count", 1) > 1:
                    if step["stagger_ms"] < 0:
                        faults.append(f"{where}: negative stagger")
                if "frame_ms" in step and step["frame_ms"] * len(step.get("sprites", [])) > hi:
                    faults.append(f"{where}: one turn of its sprites outlasts {hi} ms")
                for sprite in [step.get("sprite")] + step.get("sprites", []):
                    if sprite and sprite not in pieces:
                        faults.append(f"{where}: sprite {sprite} is not in motion.json")
    reduced = curves["motions"]["reward"]["reduced"]
    coins = [s for _, s in steps_of(reduced) if s.get("target") == "coin" and s.get("property") != "alpha"]
    if len(coins) != 1 or coins[0].get("count", 1) != 1:
        faults.append("reward.reduced must land exactly one coin (§20.8)")
    for _, s in steps_of(reduced):
        if s.get("target") == "burst" or s.get("name") == "anticipation":
            faults.append("reward.reduced keeps the burst or the anticipation")
    if curves["motions"]["shine"]["reduced"].get("steps"):
        faults.append("shine.reduced must be none")
    return faults


def main():
    curves = json.loads(CURVES.read_text())
    pieces = json.loads(MANIFEST.read_text())["pieces"]
    faults = check(curves, pieces)
    for fault in faults:
        print(fault)
    if faults:
        sys.exit(1)
    print("ok")


if __name__ == "__main__":
    main()
