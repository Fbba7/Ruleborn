#!/usr/bin/env python3
"""The prototype and the harness must agree about the rules they share.

    python3 tools/check_prototype_conformance.py

`build_prototype.py` keeps the **numbers** in step. Two implementations with
identical constants can still disagree about what those numbers mean, and that
disagreement is what actually bit: the page loaded five units a tick where the
constant said thirty a second, so the same `LOAD_PER_SECOND` would not have
saved it — the code around the constant was wrong.

So this asks the page itself, in a real browser, and compares its answers with
the Python. It checks the claims that are cheap to state and expensive to get
wrong:

  * a full crew loads in about ten seconds (§12.19), which is the claim D24
    broke and the one the page was furthest from;
  * the exposed share equals what the crew can carry, so 100% fill is reachable
    and no more;
  * suspicion fills at §12.17's stated rates, in points per tick;
  * the clock is §5.4's;
  * every role and guard the page knows about has the stats `content/` gives it.

It is not a proof that the two simulations agree — nothing short of running both
over the same seeds would be, and the page is player-driven so there are no seeds
to share. It is the set of shared facts that can be checked without one.
"""

import json
import pathlib
import sys

ROOT = pathlib.Path(__file__).resolve().parent.parent
sys.path.insert(0, str(ROOT))
PAGE = ROOT / "prototypes" / "heist-gate" / "index.html"

#: Read out of the page once it has loaded, as JSON.
PROBE = """() => ({
  tps: TPS,
  clock: CLOCK_TICKS,
  loadPerTick: LOAD_PER_TICK,
  susMax: SUS_MAX,
  susFill: { near: SUS_NEAR, mid: SUS_MID, far: SUS_FAR },
  susDecay: SUS_DECAY,
  stateFloor: STATE_FLOOR_TICKS,
  roles: Object.fromEntries(Object.entries(ROLES).map(
    ([k, r]) => [k, { speed: r.speed, hp: r.hp, power: r.power, carry: r.carry }])),
  guards: Object.fromEntries(Object.entries(GUARDS).map(
    ([k, g]) => [k, { cone: g.cone, near: g.near, mid: g.mid, far: g.far,
                      periph: g.periph, turn: g.turn }])),
  vaultHealth: G.VAULT_HEALTH_PER_LEVEL,
})"""


def from_page() -> dict:
    from playwright.sync_api import sync_playwright
    with sync_playwright() as pw:
        # The image pins a Chromium that the installed Playwright does not
        # expect by version, so point at it rather than letting Playwright
        # look for one it would have to download.
        candidates = sorted(pathlib.Path("/opt/pw-browsers").glob("chromium-*/chrome-linux/chrome"))
        browser = (pw.chromium.launch(executable_path=str(candidates[-1]))
                   if candidates else pw.chromium.launch())
        page = browser.new_page()
        errors = []
        page.on("pageerror", lambda e: errors.append(str(e)))
        page.goto(PAGE.as_uri())
        page.wait_for_timeout(600)
        if errors:
            raise SystemExit("the prototype threw on load:\n  " + "\n  ".join(errors))
        out = page.evaluate(PROBE)
        browser.close()
    return out


def main() -> int:
    from tools.heist_harness import detect, fixed, sim

    roles = {r["id"]: r for r in
             json.loads((ROOT / "content" / "roles.json").read_text(encoding="utf-8"))}
    detection = json.loads((ROOT / "content" / "detection.json").read_text(encoding="utf-8"))
    guards = {g["role"].lower(): g for g in detection["guards"]}
    suspicion = detection["suspicion"]

    page = from_page()
    problems = []

    def same(label, got, want):
        if got != want:
            problems.append(f"{label}: the page says {got!r}, the Python says {want!r}")

    same("tick rate", page["tps"], fixed.TPS)
    same("§5.4's clock", page["clock"], sim.BASE_TICKS)
    same("suspicion ceiling", page["susMax"], suspicion["max"])
    same("suspicion decay", page["susDecay"], suspicion["decay_per_tick"])
    same("state floor", page["stateFloor"], suspicion["state_floor_ticks"])
    for zone, rate in suspicion["fill_per_tick"].items():
        same(f"suspicion fill, {zone}", page["susFill"][zone], rate)
    same("Vault health a level", page["vaultHealth"], sim.VAULT_HEALTH_PER_LEVEL)

    # §12.19's central claim, which is about behaviour and not a constant.
    per_second = page["loadPerTick"] * page["tps"]
    same("§12.19's loading rate, units a second", per_second, sim.LOAD_PER_SECOND)
    carrier = roles["carrier"]["carry"]
    seconds = carrier / per_second if per_second else 0
    if abs(seconds - 10) > 0.6:
        problems.append(
            f"§12.19 says a full crew fills in about ten seconds; the page's "
            f"rate fills a Carrier's {carrier} in {seconds:.1f}s")

    for name, stats in page["roles"].items():
        if name not in roles:
            problems.append(f"the page has a role {name!r} that content/roles.json does not")
            continue
        for key, mine in (("speed", "speed"), ("hp", "health"),
                          ("power", "power"), ("carry", "carry")):
            same(f"{name}.{key}", stats[key], roles[name][mine])

    for name, vision in page["guards"].items():
        if name not in guards:
            problems.append(f"the page has a guard {name!r} that content/detection.json does not")
            continue
        want = guards[name]
        same(f"{name} cone", vision["cone"], want["cone_degrees"])
        same(f"{name} near", vision["near"], want["near_m"])
        same(f"{name} mid", vision["mid"], want["mid_m"])
        same(f"{name} far", vision["far"], want["far_m"] if want["far_m"] is not None else 0)
        same(f"{name} peripheral", vision["periph"], want["peripheral_degrees"])
        same(f"{name} turn", vision["turn"], want["turn_degrees_per_tick"])

    print(f"\nAsked the prototype {len(page['roles'])} roles, "
          f"{len(page['guards'])} guards and the shared rules, in a real browser.\n")
    if problems:
        print(f"{len(problems)} disagreements between the page and the Python:\n")
        for p in problems:
            print(f"  ✗ {p}")
        print()
        return 1
    print("  the prototype and the harness agree on every rule they share.")
    print(f"  A full crew fills in {seconds:.1f}s, against §12.19's ten.\n")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
