#!/usr/bin/env python3
"""Emit the playable prototype's rule constants from the Python that defines them.

    python3 tools/build_prototype.py
    python3 tools/build_prototype.py --check     # fails on drift

The prototype at `prototypes/heist-gate/index.html` is a second implementation of
rules the harness already implements, and it went one commit and then sat still
while the harness changed eight times in a day. By the time anyone looked, it was
loading 150 units a second per character against §12.19's 30 — the difference
between a Vault phase of two seconds and one of ten, which is the single thing
this session spent the most effort getting right.

§30.18 states the rule this breaks, and the repository has been enforcing it
everywhere else: **a thing that exists only to restate something else should be
generated, never authored.** So the numbers are generated. The block between the
markers below is written from `content/` and from the harness modules, and
`--check` fails the build if the file on disk has drifted from what the Python
now says — exactly as `generate_docs.py` does for the design tables.

What this does NOT do, said plainly: it syncs the **numbers**, not the
**behaviour**. Two implementations with identical constants can still disagree
about what happens, and that is what `check_prototype_conformance.py` is for.
"""

import json
import pathlib
import sys

ROOT = pathlib.Path(__file__).resolve().parent.parent
sys.path.insert(0, str(ROOT))

PAGE = ROOT / "prototypes" / "heist-gate" / "index.html"
OPEN = "  // <<< GENERATED FROM THE PYTHON — build_prototype.py writes this"
CLOSE = "  // >>> END GENERATED"


def block() -> str:
    """The generated JavaScript, as a list of lines between the markers."""
    from tools.heist_harness import detect, fixed, sim

    roles = json.loads((ROOT / "content" / "roles.json").read_text(encoding="utf-8"))
    detection = json.loads((ROOT / "content" / "detection.json").read_text(encoding="utf-8"))
    suspicion = detection["suspicion"]

    def js(value) -> str:
        return json.dumps(value, separators=(", ", ": "))

    out = [OPEN,
           "  // Every number below comes from content/ or from tools/heist_harness.",
           "  // Change a rule there and rebuild; do not edit it here.",
           "  const G = {"]

    out.append(f"    TPS: {fixed.TPS}, U: {fixed.U},")
    out.append(f"    // §5.4: {sim.BASE_TICKS // fixed.TPS}s plus "
               f"{sim.LINK_TICKS // fixed.TPS}s a link, capped at "
               f"{sim.MAX_TICKS // fixed.TPS}s.")
    out.append(f"    BASE_TICKS: {sim.BASE_TICKS}, LINK_TICKS: {sim.LINK_TICKS}, "
               f"MAX_TICKS: {sim.MAX_TICKS},")
    out.append(f"    // §12.19: every role loads at this rate, not Carriers alone.")
    out.append(f"    LOAD_PER_SECOND: {sim.LOAD_PER_SECOND},")
    out.append(f"    BREAKEVEN_FILL: {sim.BREAKEVEN_FILL},")
    out.append(f"    VAULT_HEALTH_PER_LEVEL: {sim.VAULT_HEALTH_PER_LEVEL},")
    out.append(f"    WIND_UP_TICKS: {sim.WIND_UP_TICKS},")
    out.append("")
    out.append("    // §12.17, from content/detection.json.")
    out.append(f"    SUS_MAX: {suspicion['max']},")
    out.append(f"    SUS_FILL: {js(suspicion['fill_per_tick'])},")
    out.append(f"    SUS_DECAY: {suspicion['decay_per_tick']},")
    out.append(f"    STATE_FLOOR_TICKS: {suspicion['state_floor_ticks']},")
    out.append(f"    SUSPICIOUS: {detect.SUSPICIOUS}, INVESTIGATING: "
               f"{detect.INVESTIGATING}, ALERTED: {detect.ALERTED},")
    out.append("")
    out.append("    // §11.1, from content/roles.json.")
    out.append("    ROLES: {")
    for role in roles:
        out.append(f"      {role['id']}: {{ label: {js(role['name'])}, "
                   f"speed: {role['speed']}, hp: {role['health']}, "
                   f"power: {role['power']}, carry: {role['carry']} }},")
    out.append("    },")
    out.append("")
    out.append("    // Guard vision, from content/detection.json. Metres; a tile is a metre.")
    out.append("    GUARDS: {")
    for guard in detection["guards"]:
        far = guard["far_m"] if guard["far_m"] is not None else 0
        out.append(f"      {guard['role'].lower()}: {{ label: {js(guard['role'])}, "
                   f"cone: {guard['cone_degrees']}, near: {guard['near_m']}, "
                   f"mid: {guard['mid_m']}, far: {far}, "
                   f"periph: {guard['peripheral_degrees']}, "
                   f"turn: {guard['turn_degrees_per_tick']} }},")
    out.append("    },")
    out.append("")
    out.append("    // §9.6's grade multiplier, which is what a raid is finally worth.")
    out.append('    GRADE: { clean: 1.0, loud: 0.7, partial: 0.4, foiled: 0.0 },')
    out.append("  };")
    out.append(CLOSE)
    return "\n".join(out)


def rebuilt() -> str:
    text = PAGE.read_text(encoding="utf-8")
    if OPEN not in text or CLOSE not in text:
        raise SystemExit(
            f"{PAGE.relative_to(ROOT)} has no generated block. Add these two "
            f"lines around where the constants belong:\n  {OPEN}\n  {CLOSE}")
    head = text[:text.index(OPEN)]
    tail = text[text.index(CLOSE) + len(CLOSE):]
    return head + block() + tail


def main() -> int:
    current = PAGE.read_text(encoding="utf-8")
    fresh = rebuilt()
    if "--check" in sys.argv:
        if current != fresh:
            print("The prototype has drifted from the Python that defines its rules.")
            print("Run: python3 tools/build_prototype.py")
            return 1
        print("  the prototype's constants match the harness and content/.")
        return 0
    PAGE.write_text(fresh, encoding="utf-8")
    changed = "rewritten" if current != fresh else "unchanged"
    print(f"  {PAGE.relative_to(ROOT)} — {changed}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
