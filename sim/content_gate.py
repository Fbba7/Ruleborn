#!/usr/bin/env python3
"""Check the simulation's numbers against content/detection.json and roles.json.

    python3 sim/content_gate.py            # check, and list what is not modelled
    python3 sim/content_gate.py --self-test

The content files are §12.17 and §11.1 as data; the simulation carries the same
numbers as Rust constants, because §24.7 forbids reading decimals where a
result is decided. Two copies of one fact drift, and this is where the drift
is caught: the spike's first fixture had the Scout's zones at half their size
and nothing noticed until the guard work reread §12.17 by hand.

**Coverage is enforced, not claimed.** Every number in both files is walked,
and each has to be compared, named as not modelled yet, or named as derived
from one that is. The first version of this gate said as much in prose and
did not check it — and the peripheral modifier sat in the file neither
compared nor listed.

The simulation also needs two numbers the document does not give; they are
listed as `READINGS` so they are reported beside the checks rather than
passing for the document's.
"""

import json
import pathlib
import re
import sys

HERE = pathlib.Path(__file__).resolve().parent
CONTENT = HERE.parent / "content" / "detection.json"
ROLES = HERE.parent / "content" / "roles.json"
SOURCES = ["src/lib.rs", "src/guard.rs", "src/noise.rs", "src/grid.rs", "src/heist.rs"]

# Values the content files hold that the simulation does not yet use, by path
# prefix. Each is reported so none passes as agreeing by being absent.
NOT_MODELLED = [
    ("modifiers.higher_ground", "the fixture has one level"),
    ("modifiers.lower_ground", "the fixture has one level"),
    ("noise.sources.landing_1_level", "the fixture has one level"),
    ("noise.sources.landing_3_levels", "the fixture has one level"),
    ("noise.off_screen_multiplier", "the simulation has no screen"),
    ("ambush.level_advantage_cap", "every character is level 1: there are no levels yet"),
]

# Rule-sheet parameters (§12.21) the simulation does not read yet. Every
# other parameter must appear as `Param::Name` in the simulation's source.
LAW_PARAMS_NOT_MODELLED = [
    ("climb_levels", "the fixture has one level"),
    ("leap_obstacles", "no leaping: a fence stops feet"),
    ("touch_damage", "Thorns: \"touching walls or hedges costs 5% health\" — "
                     "and the document never says what a touch is"),
    ("unlit_drain", "Soul lanterns: needs lantern light, an object not built"),
    ("regrow_seconds", "set by Crystal growth and Bloom; nothing regrows yet"),
    ("carry_weight", "no law sets it"),
    ("cone_angle", "no law sets it"),
]

# Values that restate another value in different units, and are covered by
# the comparison of the value they restate.
DERIVED = [
    ("suspicion.fill_seconds", "the same as fill_per_tick, in seconds"),
    ("suspicion.decay_seconds", "the same as decay_per_tick, in seconds"),
]

# Rules the content file states in words, held by a named test rather than by
# a number. The gate checks the test exists; status.py checks it passed.
HELD_BY_TEST = {
    "modifiers.still_in_grass": "standing_still_in_tall_grass_hides_until_a_guard_walks_in",
    "alarm.realm_alarm_per_guard_found":
        "a_knocked_out_guard_found_by_another_raises_the_realm_alarm",
    "ambush.hits_to_down_equal_level_guard":
        "two_ambush_hits_knock_out_a_guard_of_equal_level_in_every_pairing",
}

# Numbers the simulation needs and the document does not give.
READINGS = [
    ("CROUCH_PACE", "crouched speed against §11.1's", "no section gives one"),
    ("RUN_PACE", "running speed against §11.1's", "no section gives one"),
    ("REVIVE_HEALTH", "the health a revived crew member gets back",
     "§12.20 says an ally \"revives it\" and not with what"),
    ("FIXTURE_EXPOSED", "what the fixture's Vault holds, in bag units",
     "§9.6 prices the exposed share in Starlight and nothing converts it to Carry"),
]


def constants(text: str) -> dict[str, object]:
    """Every `pub const NAME: T = EXPR;`, as an int or a tuple of ints."""
    found: dict[str, object] = {}
    for name, expr in re.findall(r"pub const (\w+): [^=]+= ([^;]+);", text):
        for known, value in sorted(found.items(), key=lambda kv: -len(kv[0])):
            if isinstance(value, int):
                expr = re.sub(rf"\b{known}\b", str(value), expr)
        tup = re.fullmatch(r"\(\s*(\d+)\s*,\s*(\d+)\s*\)", expr.strip())
        if tup:
            found[name] = (int(tup.group(1)), int(tup.group(2)))
        elif re.fullmatch(r"[\d\s+\-*/()]+", expr):
            found[name] = int(eval(expr.replace("/", "//")))  # digits only
    return found


def roles(text: str) -> dict[str, tuple[int, ...]]:
    return {m.group(8): tuple(int(g) for g in m.groups()[1:7])
            for m in re.finditer(r"\((\d+), (\d+), (\d+), (\d+), (\d+), (\d+), (\d+)\),"
                                 r"\s*// (\w+)", text)}


def column(text: str, fn: str) -> dict[str, int]:
    """A §11.1 column as `Role::fn` states it: `Role::Scout => 45` and so on."""
    body = re.search(rf"fn {fn}\(self\) -> i\d+ \{{(.*?)\n    \}}", text, re.S)
    return {n: int(v) for n, v in re.findall(r"Role::(\w+) => (\d+)", body.group(1))} \
        if body else {}


def sounds(text: str) -> dict[str, int]:
    snake = lambda s: re.sub(r"(?<!^)([A-Z])", r"_\1", s).lower()
    body = re.search(r"fn half_metres\(self\) -> u16 \{(.*?)\n    \}", text, re.S)
    return {snake(n): int(v) for n, v in re.findall(r"Sound::(\w+) => (\d+)", body.group(1))} \
        if body else {}


def leaves(node, path: str = ""):
    """Every numeric or boolean leaf, by dotted path; list items by id or role."""
    if isinstance(node, dict):
        for k, v in node.items():
            if k.startswith("_") and k != "_tick_rate":
                continue
            yield from leaves(v, f"{path}.{k}" if path else k)
    elif isinstance(node, list):
        for item in node:
            key = item.get("id") or item.get("role") if isinstance(item, dict) else None
            if key is not None:
                rest = {k: v for k, v in item.items() if k not in ("id", "role")}
                yield from leaves(rest, f"{path}.{key}")
    elif isinstance(node, bool) or isinstance(node, (int, float)):
        yield path


def compare(content: dict, role_rows: list, text: str) -> dict:
    k = constants(text)
    checked: list[str] = []
    wrong: list[str] = []
    touched: set[str] = set()

    def same(path: str, what: str, want, have) -> None:
        touched.add(path)
        (checked if want == have else wrong).append(
            f"{what}: content {want}, simulation {have}")

    def ratio(x: float) -> tuple[int, int]:
        for den in (1, 2, 4, 8):
            if abs(x * den - round(x * den)) < 1e-9:
                num = round(x * den)
                return (num, den)
        return (-1, -1)

    def reduced(t) -> tuple[int, int] | None:
        if not isinstance(t, tuple):
            return None
        from math import gcd
        g = gcd(*t)
        return (t[0] // g, t[1] // g)

    s = content["suspicion"]
    same("_tick_rate", "tick rate", content["_tick_rate"], k.get("TICKS_PER_SECOND"))
    same("suspicion.max", "suspicion max", s["max"], k.get("SUSPICION_MAX"))
    for zone in ("near", "mid", "far"):
        same(f"suspicion.fill_per_tick.{zone}", f"fill {zone}",
             s["fill_per_tick"][zone], k.get(f"FILL_{zone.upper()}"))
    same("suspicion.decay_per_tick", "decay", s["decay_per_tick"], k.get("DECAY_PER_TICK"))
    same("suspicion.state_floor_ticks", "state floor", s["state_floor_ticks"], k.get("HOLD_TICKS"))
    for state in content["states"]:
        path = f"states.{state['id']}.at"
        if state["id"] == "unaware":
            # The floor: from_suspicion answers Unaware below every threshold.
            same(path, "unaware threshold", state["at"], 0)
        elif state["at"] is not None:
            same(path, f"{state['id']} threshold", state["at"],
                 k.get(f"{state['id'].upper()}_AT"))

    for m in content["modifiers"]:
        if "multiplier" in m:
            const = {"crouched": "CROUCHED", "running": "RUNNING", "unlit": "UNLIT",
                     "peripheral": "PERIPHERAL"}.get(m["id"])
            if const:
                same(f"modifiers.{m['id']}.multiplier", f"{m['id']} multiplies the rate",
                     ratio(m["multiplier"]), reduced(k.get(const)))

    rows = roles(text)
    for g in content["guards"]:
        have = rows.get(g["role"])
        half = lambda m: 0 if m is None else round(m * 2)
        fields = (("cone_degrees", g["cone_degrees"]), ("near_m", half(g["near_m"])),
                  ("mid_m", half(g["mid_m"])), ("far_m", half(g["far_m"])),
                  ("turn_degrees_per_tick", g["turn_degrees_per_tick"]),
                  ("peripheral_degrees", g["peripheral_degrees"]))
        if have is None:
            wrong.append(f"{g['role']}: in the content file, not in ROLES")
            continue
        order = ("cone_degrees", "near_m", "mid_m", "far_m", "turn_degrees_per_tick",
                 "peripheral_degrees")
        got = dict(zip(order, have))
        for name, want in fields:
            same(f"guards.{g['role']}.{name}", f"{g['role']} {name}", want, got[name])

    heard = sounds(text)
    for src in content["noise"]["sources"]:
        if src["id"].startswith("landing"):
            continue
        same(f"noise.sources.{src['id']}.heard_within_m",
             f"{src['id']} carries (half metres)", round(src["heard_within_m"] * 2),
             heard.get(src["id"]))
    for surf in content["noise"]["surfaces"]:
        const = "QUIET_SURFACE" if surf["multiplier"] < 1 else "LOUD_SURFACE"
        same(f"noise.surfaces.{surf['id']}.multiplier", f"{surf['id']} carries",
             ratio(surf["multiplier"]), reduced(k.get(const)))

    a = content["alarm"]
    same("alarm.spread_radius_m", "alert spreads within (m)", a["spread_radius_m"],
         k.get("SPREAD_METRES"))
    same("alarm.spread_delay_ticks", "alert spreads after (ticks)", a["spread_delay_ticks"],
         k.get("SPREAD_DELAY_TICKS"))
    same("alarm.realm_alarm_max", "realm alarm max", a["realm_alarm_max"], k.get("ALARM_MAX"))
    same("alarm.realm_alarm_per_30s", "realm alarm step (ticks)",
         30 * content["_tick_rate"] // a["realm_alarm_per_30s"], k.get("ALARM_STEP_TICKS"))
    same("alarm.reinforcement_at", "reinforcement at", a["reinforcement_at"],
         k.get("REINFORCE_AT"))

    for path, test in HELD_BY_TEST.items():
        touched.add(path)
        (checked if f"fn {test}()" in text else wrong).append(
            f"{path}: held by the test {test}")

    for field, fn, scale in (("speed", "speed_tenths", 10), ("health", "health", 1),
                             ("power", "power", 1), ("carry", "carry", 1)):
        have = column(text, fn)
        for row in role_rows:
            same(f"roles.{field}.{row['name']}", f"{row['name']} {field}",
                 round(row[field] * scale), have.get(row["name"]))

    am = content["ambush"]
    same("ambush.stun_seconds", "ambush stun (ticks)",
         am["stun_seconds"] * content["_tick_rate"], k.get("AMBUSH_STUN_TICKS"))
    same("ambush.damage_multiplier", "ambush multiplies Power",
         (am["damage_multiplier"], 1), k.get("AMBUSH_POWER"))
    same("ambush.wind_up_seconds", "wind-up (ticks)",
         round(am["wind_up_seconds"] * content["_tick_rate"]), k.get("HIT_TICKS"))

    # Coverage: every number in both files is compared, not modelled, derived
    # or held by a test. Anything else is a value that could drift unseen.
    covered = [p for p, _ in NOT_MODELLED] + [p for p, _ in DERIVED]
    everything = list(leaves(content))
    for row in role_rows:
        everything += [f"roles.{f}.{row['name']}" for f in ("health", "speed", "power", "carry")]
    uncovered = [p for p in everything
                 if p not in touched
                 and not any(p == c or p.startswith(c + ".") for c in covered)
                 and not any(p.startswith(t + ".") or p == t for t in touched)]
    return {"checked": checked, "wrong": wrong, "uncovered": uncovered,
            "readings": [f"{n} = {k.get(n)} — {what}; {why}" for n, what, why in READINGS]}


def facts_compare(text: str) -> dict:
    """The simulation's copies of the facts `tools/design_facts.py` declares.

    Those are the document's numbers that have no content file — the Vault,
    loading, knockouts, the skiff — declared once there with the section that
    owns each. The harness imports them; the simulation cannot, being Rust,
    so it is checked against them here.
    """
    sys.path.insert(0, str(HERE.parent / "tools"))
    import design_facts as f
    k = constants(text)
    tps = k.get("TICKS_PER_SECOND")
    rows = [
        ("VAULT_HEALTH_PER_LEVEL", f.VAULT_HEALTH_PER_LEVEL, k.get("VAULT_HEALTH_PER_LEVEL")),
        ("BREAKER_VAULT_MULTIPLIER", (f.BREAKER_VAULT_MULTIPLIER, 1), k.get("BREAKER_VAULT_DAMAGE")),
        ("CRACK_NOISE", f.CRACK_NOISE, k.get("CRACK_NOISE")),
        ("CRACK_NOISE_SECONDS", f.CRACK_NOISE_SECONDS * tps, k.get("CRACK_NOISE_TICKS")),
        ("LOAD_PER_SECOND", f.LOAD_PER_SECOND, k.get("LOAD_PER_SECOND")),
        ("CARRIER_LOADED_PACE", (round(f.CARRIER_LOADED_PACE * 100), 100),
         k.get("CARRIER_LOADED_PACE")),
        ("AMBUSH_STUN_SECONDS", f.AMBUSH_STUN_SECONDS * tps, k.get("AMBUSH_STUN_TICKS")),
        ("AMBUSH_MULTIPLIER", (round(f.AMBUSH_MULTIPLIER), 1), k.get("AMBUSH_POWER")),
        ("WIND_UP", round(f.WIND_UP * tps), k.get("HIT_TICKS")),
        ("DOWN_SECONDS", f.DOWN_SECONDS * tps, k.get("DOWN_TICKS")),
        ("REVIVE_SECONDS", round(f.REVIVE_SECONDS * tps), k.get("REVIVE_TICKS")),
        ("MENDER_REVIVE_SECONDS", round(f.MENDER_REVIVE_SECONDS * tps),
         k.get("MENDER_REVIVE_TICKS")),
        ("SKIFF_OUTER_SECONDS", f.SKIFF_OUTER_SECONDS * tps, k.get("SKIFF_OUTER_TICKS")),
        ("SKIFF_HEART_SECONDS", f.SKIFF_HEART_SECONDS * tps, k.get("SKIFF_HEART_TICKS")),
    ]
    checked, wrong = [], []
    for name, want, have in rows:
        (checked if want == have else wrong).append(
            f"design_facts.{name}: {want}, simulation {have}")
    return {"checked": checked, "wrong": wrong}


def laws_compare(text: str) -> dict:
    """The generated law table against the content file, and the rule sheet
    against what the simulation reads."""
    import importlib.util
    spec = importlib.util.spec_from_file_location("build_laws", HERE / "build_laws.py")
    build = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(build)
    checked, wrong = [], []
    table = (HERE / "src" / "laws_table.rs").read_text()
    (checked if table == build.render() else wrong).append(
        "sim/src/laws_table.rs against content/law_effects.json (48 laws)")
    sheet = json.loads((HERE.parent / "content" / "law_effects.json").read_text())["_rule_sheet"]
    unread = dict(LAW_PARAMS_NOT_MODELLED)
    camel = lambda n: "".join(p.capitalize() for p in n.split("_"))
    lib = (HERE / "src" / "lib.rs").read_text()
    for p in unread:
        if p not in sheet:
            wrong.append(f"rule sheet {p}: listed as not modelled, but the sheet has "
                         f"no such parameter")
    for p in sheet:
        read = f"Param::{camel(p)}" in lib
        if read and p in unread:
            wrong.append(f"rule sheet {p}: listed as not modelled, but the simulation reads it")
        elif read:
            checked.append(f"rule sheet {p}: read by the simulation")
        elif p not in unread:
            wrong.append(f"rule sheet {p}: read by nothing and listed nowhere")
    return {"checked": checked, "wrong": wrong}


def source_text() -> str:
    return "\n".join((HERE / p).read_text() for p in SOURCES) + \
        (HERE / "src/tests.rs").read_text()


def load() -> tuple[dict, list]:
    return json.loads(CONTENT.read_text()), json.loads(ROLES.read_text())


def self_test() -> int:
    content, role_rows = load()
    text = source_text()
    r = compare(content, role_rows, text)
    assert not r["wrong"] and not r["uncovered"], (r["wrong"], r["uncovered"])

    def caught(label: str, prefix: str, c=content, t=text, rr=role_rows) -> None:
        got = compare(c, rr, t)
        found = got["wrong"] + got["uncovered"]
        assert any(w.startswith(prefix) for w in found), (label, found)

    # The bug this gate exists for: the Scout's zones at half size.
    halved = text.replace("(0, 45, 4, 8, 12, 6, 110)", "(0, 45, 2, 4, 6, 6, 110)")
    assert halved != text, "the Scout row moved; update the self-test"
    caught("halved Scout", "Scout near_m", t=halved)
    # A threshold written as arithmetic must still be read.
    caught("moved floor", "state floor", t=text.replace("TICKS_PER_SECOND / 2;", "TICKS_PER_SECOND / 3;"))
    # A role deleted from ROLES is a failure, not a pass.
    caught("missing role", "Mender:",
           t=re.sub(r"\(4, 40, 3, 5, 0, 4, 100\),\s*// Mender", "", text))
    # A wrong multiplier, and a wrong §11.1 speed.
    caught("running at double", "running multiplies",
           t=text.replace("RUNNING: (i32, i32) = (7, 4)", "RUNNING: (i32, i32) = (2, 1)"))
    caught("slow Scout", "Scout speed", t=text.replace("Role::Scout => 45", "Role::Scout => 40"))
    caught("weak Warden", "Warden health", t=text.replace("Role::Warden => 420", "Role::Warden => 400"))
    # The gap the first version had: a number in the file nothing compares.
    planted = json.loads(json.dumps(content))
    planted["modifiers"].append({"id": "in_rain", "effect": "rate", "multiplier": 0.8})
    caught("an unlisted modifier", "modifiers.in_rain", c=planted)
    # A rule held by a test whose test is deleted.
    caught("test gone", "modifiers.still_in_grass",
           t=text.replace("fn standing_still_in_tall_grass_hides_until_a_guard_walks_in()", "fn x()"))
    # And a design fact the simulation restates differently.
    got = facts_compare(text.replace("LOAD_PER_SECOND: i32 = 30", "LOAD_PER_SECOND: i32 = 25"))
    assert any(w.startswith("design_facts.LOAD_PER_SECOND") for w in got["wrong"]), got
    assert not facts_compare(text)["wrong"], facts_compare(text)["wrong"]
    assert not laws_compare(text)["wrong"], laws_compare(text)["wrong"]
    # A hand edit to the generated law table, and a rule-sheet parameter the
    # simulation stops reading without saying so.
    table = HERE / "src" / "laws_table.rs"
    real = table.read_text()
    try:
        table.write_text(real.replace("(Param::ClockRate, 5, 4)", "(Param::ClockRate, 3, 2)"))
        assert any("laws_table" in w for w in laws_compare(text)["wrong"])
    finally:
        table.write_text(real)
    lib = HERE / "src" / "lib.rs"
    real_lib = lib.read_text()
    try:
        lib.write_text(real_lib.replace("Param::AlarmRange", "Param::Alarm_Range"))
        assert any("alarm_range" in w for w in laws_compare(text)["wrong"])
    finally:
        lib.write_text(real_lib)
    print("content_gate self-test: halved Scout, moved floor, missing role, wrong "
          "multiplier, slow Scout, weak Warden, an uncompared number, a deleted test, "
          "a drifted design fact, a hand-edited law table and an unread rule-sheet "
          "parameter all caught")
    return 0


def main() -> int:
    if "--self-test" in sys.argv:
        return self_test()
    r = compare(*load(), source_text())
    facts = facts_compare(source_text())
    laws = laws_compare(source_text())
    r["checked"] += facts["checked"] + laws["checked"]
    r["wrong"] += facts["wrong"] + laws["wrong"]
    print(f"  content: {len(r['checked'])} values agree with content/detection.json, "
          f"roles.json and tools/design_facts.py")
    for line in r["wrong"]:
        print(f"  DISAGREES {line}")
    for line in r["uncovered"]:
        print(f"  UNCOVERED {line} — compared by nothing and listed nowhere")
    for what, why in NOT_MODELLED:
        print(f"  not modelled: {what} — {why}")
    for what, why in LAW_PARAMS_NOT_MODELLED:
        print(f"  not modelled: rule sheet {what} — {why}")
    for line in r["readings"]:
        print(f"  the simulation's reading: {line}")
    return 1 if r["wrong"] or r["uncovered"] else 0


if __name__ == "__main__":
    raise SystemExit(main())
