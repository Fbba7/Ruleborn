#!/usr/bin/env python3
"""Classify every law by what kind of change it is, and emit the ones a
simulation can apply.

    python3 tools/law_effects.py            # the report
    python3 tools/law_effects.py --write    # also write content/law_effects.json

Why this exists
---------------
§7.3 is the architectural claim the whole design rests on: laws change a realm's
rule sheet rather than containing special cases. v3.0's §12.21 sharpens it into a
rule — "every tier effect of every law must be expressible as a change to a named
parameter. Anything that cannot be is a design smell to resolve while authoring,
not at implementation."

That is a testable claim about 48 pieces of content, and nobody has tested it.
This does, by trying to write each law down as a parameter change and recording
what happens when it cannot.

The five kinds
--------------
parameter   Scales or sets a number the rule sheet already has. The claim holds.
entity      Requires the simulation to spawn and track an object that does not
            otherwise exist — braziers, puffballs, afterimages, illusions.
event       Requires a periodic or conditional rule, not a parameter: something
            fires every N seconds, or on a condition, and changes the world.
attribute   Reads a property no character carries. §12.21 names three and fixes
            them in prose; C26 records that no table carries them.
authored    Needs a choice from the realm's owner that is not a number in a
            table: which way the realm tilts, where the streams run. These are
            the ones §13.3's generator has to make on the player's behalf, and
            nothing says how.

A law can be more than one. The report counts each law by its *hardest* kind,
because that is what decides whether §7.3's architecture survives contact.
"""

import collections
import json
import pathlib
import sys

ROOT = pathlib.Path(__file__).resolve().parent.parent
CONTENT = ROOT / "content"

#: The rule sheet the simulation actually has, which is the vocabulary a law
#: may change. Anything outside this list is not a parameter, whatever it looks
#: like in prose. Kept deliberately short: a vocabulary that grows to fit every
#: law is not a vocabulary, it is a list of special cases with a new name.
RULE_SHEET = {
    "crew_speed", "guard_speed", "loaded_speed", "clock_rate",
    "sight_range", "cone_angle", "suspicion_fill", "suspicion_decay",
    "noise_radius", "alarm_range",
    "structure_damage", "damage", "health_regen", "health_drain",
    "regrow_seconds", "hide_behind_walls", "still_is_invisible",
    "climb_levels", "leap_obstacles", "carry_weight",
}

#: id -> (kinds, parameters, what the owner must choose, a note where it earns one)
#:
#: `params` are multipliers unless the name ends in _seconds or _levels, and are
#: written from the *raider's* point of view where a law is asymmetric.
EFFECTS = {
    # -- Motion ------------------------------------------------------------
    "bounce": (["event"], {}, [],
               "A rebound is a collision response, not a number: it needs the "
               "simulation to reflect a moving body off a surface."),
    "half_gravity": (["parameter"], {"leap_obstacles": 1}, [], ""),
    "tilt": (["parameter", "authored"], {"crew_speed": 1.30}, ["downhill side"],
             "The +30/-30 is a parameter; which way the realm slopes is not."),
    "current": (["parameter", "authored"], {"crew_speed": 1.30}, ["wind direction"], ""),
    "heavy_ground": (["parameter", "attribute"], {"loaded_speed": 0.70}, [],
                     "“Flyers are grounded” reads an attribute no "
                     "character carries (C26)."),
    "leapfrog": (["parameter"], {"noise_radius": 1.0, "suspicion_fill": 1.25}, [],
                 "Every third step being a hop is a gait, but its effect is a "
                 "suspicion multiplier, which the rule sheet has."),
    "frictionless": (["parameter", "event"], {"crew_speed": 1.20}, [],
                     "The speed cap is a parameter; “keeps sliding until it "
                     "hits something” is a physics rule."),
    "inward_pull": (["parameter", "authored"], {"crew_speed": 1.25, "loaded_speed": 0.65},
                    ["which direction is inward"],
                    "Inward is well defined for a realm with one Heart link and "
                    "not for a realm with two."),

    # -- Matter ------------------------------------------------------------
    "brittle_stone": (["parameter"], {"structure_damage": 2.0}, [], ""),
    "crystal_growth": (["parameter"], {"regrow_seconds": 8}, [], ""),
    "glass": (["parameter"], {"hide_behind_walls": 0}, [], ""),
    "density": (["parameter", "attribute"], {}, [],
                "Reads big and small, which §12.21 declares and no table carries."),
    "honeycomb": (["parameter"], {"crew_speed": 0.80, "climb_levels": 1}, [], ""),
    "lodestones": (["entity", "authored"], {"loaded_speed": 0.70}, ["two placements"], ""),
    "shifting_stones": (["entity", "authored"], {}, ["a loop the owner draws"],
                        "Moving walls change the walkable graph mid-run, which "
                        "the pathfinder in §12.18 assumes is static."),
    "transmute": (["event"], {}, [],
                  "Converting carried loot every 20 s at a 5% loss is an economy "
                  "rule inside a heist — the only law that touches §9.6."),

    # -- Time --------------------------------------------------------------
    "day_and_night": (["event", "parameter"], {"sight_range": 0.50}, [],
                      "The halving is a parameter; the 30-second switch is a clock."),
    "slow_rivers": (["parameter", "authored"], {"crew_speed": 0.50},
                    ["where the streams run"], ""),
    "stillness": (["parameter"], {"still_is_invisible": 1}, [], ""),
    "afterimage": (["entity"], {}, [],
                   "A decoy that guards path toward: a new object with its own "
                   "lifetime, and a new reason for a guard to investigate."),
    "delay": (["parameter"], {}, [],
              "A 3-second delay on ward triggering is a parameter the ward "
              "system does not currently have."),
    "haste": (["parameter"], {"crew_speed": 1.25, "guard_speed": 1.25,
                              "clock_rate": 1.25}, [], ""),
    "held_breath": (["event"], {}, [],
                    "Time advancing only while a crew member moves is not a "
                    "parameter of the simulation; it is a different simulation."),
    "rewind": (["event"], {}, [],
               "Restoring world state to 10 seconds earlier needs a snapshot "
               "history, which §24.10's input-log model does not keep."),

    # -- Energy ------------------------------------------------------------
    "glowing_dark": (["parameter"], {"sight_range": 0.50}, [], ""),
    "heat_bloom": (["entity", "authored"], {"damage": 1.25}, ["brazier placements"], ""),
    "spark_trails": (["entity"], {}, [],
                     "A trail is an object with a lifetime that guards can see."),
    "aurora": (["event", "entity"], {}, [],
               "Sweeping bands are moving regions that change sight range inside "
               "them — a parameter that varies by position and time."),
    "chain_lightning": (["event"], {"damage": 0.50}, [], ""),
    "static": (["event"], {}, [],
               "Charge accumulating with distance travelled is per-character "
               "state the rule sheet does not have."),
    "overcharge": (["event"], {}, [],
                   "“Every third ability, by anyone” is a realm-wide "
                   "counter shared between both sides."),
    "sunburst": (["event"], {}, [], "A 25-second timer with a shade test."),

    # -- Life --------------------------------------------------------------
    "bloom": (["parameter"], {"regrow_seconds": 10}, [], ""),
    "kinship": (["parameter"], {"health_regen": 0.015}, [], ""),
    "wild_paths": (["event"], {"crew_speed": 1.20}, [],
                   "Tiles changing after three crossings is per-tile state that "
                   "accumulates during the run."),
    "flock": (["entity"], {}, [], "Six wandering bodies that block and bleat."),
    "spores": (["entity"], {"crew_speed": 0.50}, [], "Drifting clouds with position."),
    "thorns": (["parameter"], {"health_drain": 0.05}, [], ""),
    "regrowth": (["parameter"], {"health_regen": 0.02}, [], ""),
    "swarm_birth": (["event", "attribute"], {}, [],
                    "Splitting a guard into two creates characters mid-run. "
                    "§12.21 fixes the attribute half and not this half."),

    # -- Spirit ------------------------------------------------------------
    "haunting": (["entity", "parameter"], {"guard_speed": 1.50}, [], ""),
    "soul_lanterns": (["entity", "authored"], {"health_drain": 0.01},
                      ["lantern placements"], ""),
    "whispers": (["parameter"], {"alarm_range": 999}, [],
                 "A range parameter set to the whole universe — which is the "
                 "cleanest law in the set, and the one that changes the most."),
    "echoes": (["event"], {}, [], "Returning a knocked-out character at 60%."),
    "sleepwalk": (["parameter"], {"sight_range": 0.0, "noise_radius": 1.0}, [],
                  "Sight off and hearing on is two parameters, both in the sheet."),
    "soul_swap": (["event"], {}, [],
                  "A conditional teleport at the moment of a knockout."),
    "borrowed_face": (["event"], {}, [],
                      "Identity confusion for 10 seconds: a per-character flag "
                      "with a timer and two cancel conditions."),
    "mirror_images": (["entity"], {}, [],
                      "Illusory guards that vanish on touch and still raise the "
                      "alarm — a guard that is not a guard."),
}

ORDER = ["parameter", "authored", "attribute", "entity", "event"]
HARDEST = {"parameter": 0, "authored": 1, "attribute": 2, "entity": 3, "event": 4}


def load_laws() -> list:
    return json.loads((CONTENT / "laws.json").read_text(encoding="utf-8"))


def classify(laws: list) -> dict:
    out = {}
    for law in laws:
        spec = EFFECTS.get(law["id"])
        if spec is None:
            raise SystemExit(f"law {law['id']} has no classification in EFFECTS")
        kinds, params, authored, note = spec
        bad = set(params) - RULE_SHEET
        if bad:
            raise SystemExit(f"law {law['id']} names parameters outside the rule "
                             f"sheet: {sorted(bad)}")
        out[law["id"]] = dict(
            id=law["id"], name=law["name"], school=law["school"], rank=law["rank"],
            stability_cost=law["stability_cost"], notes=law["notes"],
            kinds=kinds, params=params, authored=authored, note=note,
            hardest=max(kinds, key=lambda k: HARDEST[k]),
            simulated=bool(params) and max(kinds, key=lambda k: HARDEST[k]) in
            ("parameter", "authored"),
        )
    return out


def report(effects: dict) -> str:
    lines = ["§12.21's rule, measured against all 48 laws", ""]
    lines.append("  “Every tier effect of every law must be expressible as a")
    lines.append("   change to a named parameter. Anything that cannot be is a")
    lines.append("   design smell to resolve while authoring.”  — §12.21")
    lines.append("")
    hardest = collections.Counter(e["hardest"] for e in effects.values())
    total = len(effects)
    lines.append(f"{'kind':<12} {'laws':>5} {'share':>7}   what it needs from the engine")
    what = {
        "parameter": "nothing new — a number in the rule sheet",
        "authored": "a choice from the realm's owner",
        "attribute": "a property no character carries",
        "entity": "an object the simulation must spawn and track",
        "event": "a periodic or conditional rule, not a parameter",
    }
    for kind in ORDER:
        n = hardest.get(kind, 0)
        lines.append(f"{kind:<12} {n:>5} {100 * n // total:>6}%   {what[kind]}")
    clean = hardest.get("parameter", 0)
    lines.append("")
    lines.append(f"  {clean} of {total} laws are parameter changes and nothing else.")
    lines.append(f"  {total - clean} need something the rule sheet does not contain.")
    lines.append("  Each law is counted once above, under its hardest kind. The lists")
    lines.append("  below count every kind a law has, so they overlap.")
    lines.append("")

    lines.append("Laws needing an object the simulation must spawn:")
    lines.append("  " + ", ".join(sorted(e["name"] for e in effects.values()
                                         if "entity" in e["kinds"])))
    lines.append("")
    lines.append("Laws needing a periodic or conditional rule:")
    lines.append("  " + ", ".join(sorted(e["name"] for e in effects.values()
                                         if "event" in e["kinds"])))
    lines.append("")
    authored = sorted((e["name"], e["authored"]) for e in effects.values() if e["authored"])
    lines.append(f"Laws needing a choice from the realm's owner ({len(authored)}):")
    for name, choices in authored:
        lines.append(f"  {name:<18} {', '.join(choices)}")
    lines.append("")
    lines.append("  This last group is the one v3.0 made urgent. §13.3 now gives")
    lines.append("  every player a generated defence — “from their realm, their")
    lines.append(f"  laws and their ruleborn\u201d \u2014 and {len(authored)} of those "
                 "laws require a")
    lines.append("  decision that is not a number in a table. Which way does a")
    lines.append("  generated realm tilt? Where do its streams run? Nothing says,")
    lines.append("  and a generator that picks badly makes the law help the raider.")
    lines.append("")
    usable = [e for e in effects.values() if e["simulated"]]
    lines.append(f"What the harness can apply today: {len(usable)} laws, the ones whose")
    lines.append("effect is entirely parameters. Those are written to")
    lines.append("content/law_effects.json and woven into generated islands.")
    return "\n".join(lines)


def main() -> int:
    laws = load_laws()
    effects = classify(laws)
    print(report(effects))
    if "--write" in sys.argv:
        path = CONTENT / "law_effects.json"
        payload = {
            "_source": "tools/law_effects.py, classified against §7.3 and §12.21",
            "_rule_sheet": sorted(RULE_SHEET),
            "laws": [effects[law["id"]] for law in laws],
        }
        path.write_text(json.dumps(payload, indent=1, ensure_ascii=False) + "\n",
                        encoding="utf-8")
        print(f"\nwrote {path.relative_to(ROOT)}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
