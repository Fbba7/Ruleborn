#!/usr/bin/env python3
"""Check the simulation's detection numbers against content/detection.json.

    python3 sim/content_gate.py            # check, list what is not modelled
    python3 sim/content_gate.py --self-test

The content file is §12.17 reconciled; the simulation carries the same
numbers as Rust constants, because §24.7 forbids reading decimals where a
result is decided. Two copies of one fact drift, and this is where the drift
is caught: the spike's first fixture had the Scout's zones at half their size
and nothing noticed until the guard work reread §12.17 by hand.

Every value in the content file is either compared here or named as not
modelled yet, so a new field cannot slip past as silently agreeing.
"""

import json
import pathlib
import re
import sys

HERE = pathlib.Path(__file__).resolve().parent
CONTENT = HERE.parent / "content" / "detection.json"
SOURCES = ["src/lib.rs", "src/guard.rs", "src/noise.rs"]

# Values the content file holds that the simulation does not yet use. Each is
# listed so the gate reports it rather than passing over it.
NOT_MODELLED = [
    ("guards[].peripheral_degrees", "peripheral vision is not in perception yet"),
    ("modifiers: higher_ground, lower_ground", "the fixture has one level"),
    ("modifiers: running, unlit, still_in_grass", "no running, lighting or grass yet"),
    ("noise.off_screen_multiplier", "the simulation has no screen"),
    ("noise.sources: landing_1_level, landing_3_levels", "the fixture has one level"),
    ("noise.surfaces", "no surface materials yet"),
    ("alarm.realm_alarm_per_guard_found", "no knockouts yet, so none are found"),
    ("ambush", "§12.8's ambush is not built"),
]


def constants(text: str) -> dict[str, int]:
    """Every `pub const NAME: T = EXPR;` whose EXPR is integer arithmetic."""
    found: dict[str, int] = {}
    for name, expr in re.findall(r"pub const (\w+): \w+ = ([^;]+);", text):
        for known, value in sorted(found.items(), key=lambda kv: -len(kv[0])):
            expr = re.sub(rf"\b{known}\b", str(value), expr)
        if re.fullmatch(r"[\d\s+\-*/()]+", expr):
            found[name] = int(eval(expr.replace("/", "//")))  # digits only
    return found


def roles(text: str) -> dict[str, tuple[int, ...]]:
    return {m.group(7): tuple(int(g) for g in m.groups()[1:6])
            for m in re.finditer(r"\((\d+), (\d+), (\d+), (\d+), (\d+), (\d+)\),"
                                 r"\s*// (\w+)", text)}


def sounds(text: str) -> dict[str, int]:
    snake = lambda s: re.sub(r"(?<!^)([A-Z])", r"_\1", s).lower()
    return {snake(n): int(v) for n, v in re.findall(r"Sound::(\w+) => (\d+)", text)}


def compare(content: dict, text: str) -> tuple[list[str], list[str]]:
    """(checked, mismatched), each a list of human-readable lines."""
    k = constants(text)
    checked: list[str] = []
    wrong: list[str] = []

    def same(what: str, want, have) -> None:
        (checked if want == have else wrong).append(
            f"{what}: content {want}, simulation {have}")

    s = content["suspicion"]
    same("tick rate", content["_tick_rate"], k.get("TICKS_PER_SECOND"))
    same("suspicion max", s["max"], k.get("SUSPICION_MAX"))
    for zone in ("near", "mid", "far"):
        same(f"fill {zone}", s["fill_per_tick"][zone], k.get(f"FILL_{zone.upper()}"))
    same("decay", s["decay_per_tick"], k.get("DECAY_PER_TICK"))
    same("state floor", s["state_floor_ticks"], k.get("HOLD_TICKS"))
    for state in content["states"]:
        if state["id"] == "unaware":
            # The floor: from_suspicion answers Unaware below every threshold.
            same("unaware threshold", state["at"], 0)
        elif state["at"] is not None:
            same(f"{state['id']} threshold", state["at"],
                 k.get(f"{state['id'].upper()}_AT"))
    same("crouched halves the rate",
         next(m["multiplier"] for m in content["modifiers"] if m["id"] == "crouched"),
         0.5 if "per_tick / 2" in text else None)

    rows = roles(text)
    for g in content["guards"]:
        have = rows.get(g["role"])
        half = lambda m: 0 if m is None else round(m * 2)
        want = (g["cone_degrees"], half(g["near_m"]), half(g["mid_m"]),
                half(g["far_m"]), g["turn_degrees_per_tick"])
        if have is None:
            wrong.append(f"{g['role']}: in the content file, not in ROLES")
            continue
        for label, w, h in zip(("cone", "near", "mid", "far", "turn"), want, have):
            same(f"{g['role']} {label}", w, h)

    heard = sounds(text)
    for src in content["noise"]["sources"]:
        if src["id"].startswith("landing"):
            continue
        same(f"{src['id']} carries (half metres)", round(src["heard_within_m"] * 2),
             heard.get(src["id"]))

    a = content["alarm"]
    same("alert spreads within (m)", a["spread_radius_m"], k.get("SPREAD_METRES"))
    same("alert spreads after (ticks)", a["spread_delay_ticks"], k.get("SPREAD_DELAY_TICKS"))
    same("realm alarm max", a["realm_alarm_max"], k.get("ALARM_MAX"))
    same("realm alarm step (ticks)", 30 * content["_tick_rate"] // a["realm_alarm_per_30s"],
         k.get("ALARM_STEP_TICKS"))
    same("reinforcement at", a["reinforcement_at"], k.get("REINFORCE_AT"))
    return checked, wrong


def source_text() -> str:
    return "\n".join((HERE / p).read_text() for p in SOURCES)


def self_test() -> int:
    content = json.loads(CONTENT.read_text())
    text = source_text()
    _, wrong = compare(content, text)
    assert not wrong, wrong
    # The bug this gate exists for: the Scout's zones at half size.
    halved = text.replace("(0, 45, 4, 8, 12, 6)", "(0, 45, 2, 4, 6, 6)")
    assert halved != text, "the Scout row moved; update the self-test"
    _, wrong = compare(content, halved)
    assert any(w.startswith("Scout near") for w in wrong), wrong
    # A threshold written as arithmetic must still be read.
    moved = text.replace("TICKS_PER_SECOND / 2;", "TICKS_PER_SECOND / 3;")
    _, wrong = compare(content, moved)
    assert any(w.startswith("state floor") for w in wrong), wrong
    # A role deleted from ROLES is a failure, not a pass.
    gone = re.sub(r"\(4, 40, 3, 5, 0, 4\),\s*// Mender", "", text)
    _, wrong = compare(content, gone)
    assert any(w.startswith("Mender:") for w in wrong), wrong
    print("content_gate self-test: halved Scout, moved floor and missing role all caught")
    return 0


def main() -> int:
    if "--self-test" in sys.argv:
        return self_test()
    checked, wrong = compare(json.loads(CONTENT.read_text()), source_text())
    print(f"  content: {len(checked)} values agree with content/detection.json")
    for line in wrong:
        print(f"  DISAGREES {line}")
    for what, why in NOT_MODELLED:
        print(f"  not modelled: {what} — {why}")
    return 1 if wrong else 0


if __name__ == "__main__":
    raise SystemExit(main())
