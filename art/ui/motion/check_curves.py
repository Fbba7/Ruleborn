#!/usr/bin/env python3
"""Holds art/ui/motion/curves.json to §21.8's and §20.8's rules.

Every step lasts rules.shortest_ms to rules.longest_ms and uses an easing
from rules.easings (an instant set, ms 0 with easing "none", is allowed);
every easing named has no overshoot; every motion has a full and a reduced
form, the reduced one naming its form; every sprite named is a piece of
client/ui/art/motion.json; nothing repeats faster than rules.flash_hz_most;
the reward's tiers each anticipate 300 to 1000 ms (rubric quality 5) and a
rarer tier is stronger in every key (longer, more particles, a brighter and
larger burst, farther-flying particles, a wider gather), with the
anticipation's steps inside the shortest tier's anticipation and every
payoff step with a negative at_ms (the visible gather, before the burst)
starting no earlier than the anticipation of each tier it plays in (a step
whose count is a tier key plays only where that count is above 0); the
burst's sprites take one count each, so a count key that gates a gather on a
sprite is that sprite's count wherever it is above 0; and the reduced reward keeps exactly one coin landing in its
counter, with no anticipation or burst.

    python3 art/ui/motion/check_curves.py      # prints "ok" or each fault
"""
import json
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[3]
CURVES = ROOT / "art/ui/motion/curves.json"
MANIFEST = ROOT / "client/ui/art/motion.json"
FORMS = ("down", "up", "steps", "out", "in", "anticipation", "payoff", "on_landing")
TIERS = ("common", "rare", "epic")
TIER_KEYS = ("anticipation_ms", "sparkles", "dust", "burst_value", "burst_scale", "sparkle_points", "dust_points",
             "gather_points", "gather_dust")


def steps_of(form):
    for key in FORMS:
        for step in form.get(key, []):
            yield key, step


def check_tiers(full):
    faults = []
    tiers = full.get("tiers", {})
    if tuple(tiers) != TIERS:
        return [f"reward.full.tiers must be {', '.join(TIERS)}, in that order"]
    for tier in TIERS:
        for key in TIER_KEYS:
            if not isinstance(tiers[tier].get(key), (int, float)):
                faults.append(f"reward tier {tier} has no number {key}")
    if faults:
        return faults
    for tier in TIERS:
        ms = tiers[tier]["anticipation_ms"]
        if not (300 <= ms <= 1000):
            faults.append(f"reward tier {tier}: anticipation {ms} ms is outside 300-1000")
    for key in TIER_KEYS:
        values = [tiers[t][key] for t in TIERS]
        if not all(a < b for a, b in zip(values, values[1:])):
            faults.append(f"reward tiers: {key} must rise from common to epic, not {values}")
    if not full.get("anticipation"):
        faults.append("reward.full has no anticipation")
    if not full.get("payoff") or not any(s.get("target") == "burst" for s in full["payoff"]):
        faults.append("reward.full.payoff has no burst")
    if not full.get("on_landing"):
        faults.append("reward.full has no on_landing (the counter rolls and pulses)")
    shortest = min(tiers[t]["anticipation_ms"] for t in TIERS)
    for step in full.get("anticipation", []):
        if step.get("at_ms", 0) + step.get("ms", 0) > shortest:
            faults.append(f"reward.full.anticipation.{step.get('name')} outlasts the shortest anticipation, {shortest} ms")
    counts = {}
    for step in full.get("payoff", []):
        where = f"reward.full.payoff.{step.get('name')}"
        count = step.get("count", 1)
        key = count[5:] if isinstance(count, str) and count.startswith("tier.") else None
        if key is not None and key not in TIER_KEYS:
            faults.append(f"{where}: count {count} is not a tier key")
            continue
        if step.get("target") == "burst":
            counts.setdefault(step.get("sprite"), set()).add(key)
        at = step.get("at_ms", 0)
        if not isinstance(at, (int, float)):
            faults.append(f"{where}: at_ms is not a number")
            continue
        for tier in TIERS:
            plays = key is None or tiers[tier][key] > 0
            if plays and at < -tiers[tier]["anticipation_ms"]:
                faults.append(f"{where} starts {-at} ms before the burst, before tier {tier}'s "
                              f"{tiers[tier]['anticipation_ms']} ms anticipation does")
    for sprite, keys in counts.items():
        for tier in TIERS:
            n = {tiers[tier][k] if k else 1 for k in keys} - {0}
            if len(n) > 1:
                faults.append(f"reward tier {tier}: the burst's {sprite} has counts {sorted(n)}, not one")
    return faults


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
                if step.get("stagger_ms", 0) < 0:
                    faults.append(f"{where}: negative stagger")
                for end in ("from", "to"):
                    value = step.get(end)
                    if isinstance(value, str) and value.startswith("tier."):
                        if value[5:] not in TIER_KEYS:
                            faults.append(f"{where}: {value} is not a tier key")
                if "frame_ms" in step and step["frame_ms"] * len(step.get("sprites", [])) > hi:
                    faults.append(f"{where}: one turn of its sprites outlasts {hi} ms")
                for sprite in [step.get("sprite")] + step.get("sprites", []):
                    if sprite and sprite not in pieces:
                        faults.append(f"{where}: sprite {sprite} is not in motion.json")
    reward = curves["motions"]["reward"]
    faults += check_tiers(reward.get("full", {}))
    reduced = reward["reduced"]
    coins = [s for _, s in steps_of(reduced) if s.get("target") == "coin" and s.get("property") != "alpha"]
    if len(coins) != 1 or coins[0].get("count", 1) != 1:
        faults.append("reward.reduced must land exactly one coin (§20.8)")
    if reduced.get("anticipation") or reduced.get("payoff") or reduced.get("tiers"):
        faults.append("reward.reduced keeps the anticipation, the payoff or the tiers")
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
