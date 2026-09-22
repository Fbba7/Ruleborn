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
    "structure_damage", "damage",
    # Health, by whom it changes (F31): one name for two rules is a special case
    # the simulation would have to resolve per law.
    "ally_regen", "structure_regen", "touch_damage", "unlit_drain",
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
    "kinship": (["parameter"], {"ally_regen": 0.015}, [], ""),
    "wild_paths": (["event"], {"crew_speed": 1.20}, [],
                   "Tiles changing after three crossings is per-tile state that "
                   "accumulates during the run."),
    "flock": (["entity"], {}, [], "Six wandering bodies that block and bleat."),
    "spores": (["entity"], {"crew_speed": 0.50}, [], "Drifting clouds with position."),
    "thorns": (["parameter"], {"touch_damage": 0.05}, [], ""),
    "regrowth": (["parameter"], {"structure_regen": 0.02}, [], ""),
    "swarm_birth": (["event", "attribute"], {}, [],
                    "Splitting a guard into two creates characters mid-run. "
                    "§12.21 fixes the attribute half and not this half."),

    # -- Spirit ------------------------------------------------------------
    "haunting": (["entity", "parameter"], {"guard_speed": 1.50}, [], ""),
    "soul_lanterns": (["entity", "authored"], {"unlit_drain": 0.01},
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


#: F12's answer: what the generator does with each authored choice.
#:
#: Eight of the forty-eight laws carry a parameter that is not a number in a
#: table but an act of authorship - a slope, a wind direction, streams drawn on
#: a grid. That was fine while authorship was the default. §13.3 made curation
#: the default and authorship the deep end, so for most islands the generator
#: now makes these choices, and F12's own words are the risk: "a badly chosen
#: slope or stream turns the defender's law into the raider's."
#:
#: One rule covers all eight, and it is derived rather than invented:
#:
#:     Place every authored parameter against the shortest route from the
#:     landing edge to the Heart. Along it for what costs a crosser to pass,
#:     across it for what costs a crosser to cross, and never so that the
#:     route is sealed.
#:
#: Three things the document already states make that rule the only cheap one:
#:
#:   §6.1  the route to the Heart may never be sealed, so the generator
#:         already computes that route - the rule needs no new machinery.
#:   §12.5 the raider enters at any edge tile and moves inward, so "toward the
#:         Heart" and "against the raider" are the same direction.
#:   §12.7 the loaded escape is the tense half - a crew crosses the realm
#:         empty and recrosses it full, so anything that costs speed is worth
#:         more to the defender on the way out than on the way in.
#:
#: Each entry says which way the rule points for that law and why, and whether
#: the placement sits *off* the route. Only Lodestones does: a pull on the
#: route drags a crew along it, so it has to be beside one, and the clearance
#: is what keeps §6.1 true by construction rather than by a check afterwards.
#: Braziers and lanterns go on the route and seal nothing - damage and light
#: are not walls - so §6.1 needs no help from them.
GENERATOR_RULE = {
    "tilt": ("downhill toward the Heart", False,
             "A crew crosses in empty and leaves loaded (§12.7), so the slope "
             "should be with them going in and against them coming out. "
             "Downhill outward gives a loaded crew a fast escape, which is the "
             "defender's law working for the raider \u2014 F12's own failure "
             "case, in the first law on the list."),
    "current": ("blowing toward the Heart", False,
                "The same asymmetry as Tilt and for the same reason. A wind "
                "that helps the approach and hinders the escape spends its "
                "30% where §12.7 says the tension is."),
    "inward_pull": ("the shortest-path direction to the Heart, per tile", False,
                    "F12 records that \u201cinward\u201d is undefined for a "
                    "realm with two Heart links. Per-tile shortest path is "
                    "defined for any number of them, and §6.1's no-seal check "
                    "already computes it \u2014 so the ambiguity is answered "
                    "by a value the generator is holding anyway."),
    "lodestones": ("flanking the route, two tiles clear of it", True,
                   "Lodestones pull (note_rebalance drops their Echo for "
                   "exactly that). A pull placed on the route drags a crew "
                   "along it; placed beside it, it drags them off. Two tiles "
                   "of clearance keeps §6.1 true by construction rather than "
                   "by a check afterwards."),
    "shifting_stones": ("a loop crossing the route at right angles", False,
                        "The loop moves, so it interrupts the approach without "
                        "ever being a wall \u2014 a timing obstacle rather "
                        "than a seal. Crossing at right angles maximises how "
                        "often it meets a crew and minimises how far it "
                        "travels with one."),
    "slow_rivers": ("streams across the route, in the inner third", False,
                    "Water slows anyone standing in it, guards included, so a "
                    "stream laid along the route taxes the defence as much as "
                    "the raid. Across it, and close to the Heart, the crossing "
                    "falls on a loaded escape."),
    "heat_bloom": ("braziers on the route, at the Vault approach", False,
                   "A brazier is damage in a place. The one place every crew "
                   "must stand is the approach to the Vault, and it is the "
                   "place a crew is slowest, because §12.7 has them loading "
                   "for about ten seconds."),
    "soul_lanterns": ("lanterns on the route, covering each Guardian Post's "
                      "approach", False,
                      "Light reveals, and a reveal is worth what the thing "
                      "that sees it can do. A lantern where nothing watches is "
                      "decoration; on a post's approach it feeds §12.17's "
                      "detection with the guards already standing there."),
}


def authored_laws(effects: dict) -> list[str]:
    """The laws whose effect includes an act of authorship."""
    return sorted(lid for lid, e in effects.items() if "authored" in e["kinds"])


def unruled(effects: dict) -> tuple[list[str], list[str]]:
    """Authored laws with no generator rule, and rules for laws that are not
    authored.

    The second half is the one that goes wrong quietly: a law reclassified out
    of `authored` leaves its rule behind, and a rule nobody applies reads
    exactly like a rule that is being applied.
    """
    authored = set(authored_laws(effects))
    return (sorted(authored - set(GENERATOR_RULE)),
            sorted(set(GENERATOR_RULE) - authored))


def load_laws() -> list:
    return json.loads((CONTENT / "laws.json").read_text(encoding="utf-8"))


def classify(laws: list) -> dict:
    """F10, D22. Every law written down as the kind of change it is.

    F10 is the count this produces - sixteen of the forty-eight are parameter
    changes and the rest need something the engine does not have - and D22 is
    the fact that it exists at all: §7.3 claims laws are parameters and §12.21
    makes it a rule, and before this the claim could not be checked because the
    48 sheets state their effects in prose and nothing mapped them onto
    anything.
    """
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


def generator_report(effects: dict, laws: list) -> str:
    """F12, as eight rules and one sentence they all come from."""
    by_id = {law["id"]: law for law in laws}
    out = ["", "F12: what the generator does with the eight authored choices", ""]
    out.append("  Place every authored parameter against the shortest route from")
    out.append("  the landing edge to the Heart. Along it for what costs a")
    out.append("  crosser to pass, across it for what costs a crosser to cross,")
    out.append("  and never so that the route is sealed.")
    out.append("")
    out.append("  \u00a76.1 already makes the generator compute that route, so the")
    out.append("  rule needs no machinery it does not have.")
    out.append("")
    for lid in authored_laws(effects):
        rule, off_route, why = GENERATOR_RULE[lid]
        name = by_id[lid]["name"]
        out.append(f"  {name:<18}{rule}")
        if off_route:
            out.append(f"  {'':<18}(off the route by construction, so "
                       f"\u00a76.1 needs no second check)")
        out.append(f"  {'':<18}{why}")
        out.append("")
    missing, orphan = unruled(effects)
    if missing:
        out.append(f"  {len(missing)} authored law(s) with no rule: {missing}")
    if orphan:
        out.append(f"  {len(orphan)} rule(s) for laws that are not authored: {orphan}")
    return "\n".join(out)


def self_test() -> int:
    """The three ways this classification goes wrong."""
    ok = True

    def check(name: str, got, want) -> None:
        nonlocal ok
        good = got == want
        ok = ok and good
        print(f"  [{'ok ' if good else 'FAIL'}] {name}"
              f"{'' if good else f'  got {got!r}, want {want!r}'}")

    laws = load_laws()
    effects = classify(laws)
    check("all 48 laws are classified", len(effects), 48)
    # F12 counts eight, and the register's text says eight. If the
    # classification ever moves one in or out, F12 is the thing to re-read.
    check("F12's eight authored laws are still eight",
          len(authored_laws(effects)), 8)
    check("every authored law has a generator rule, and no rule is orphaned",
          unruled(effects), ([], []))
    # A rule that does not mention the route is not this rule.
    stray = [lid for lid, (rule, _, _) in GENERATOR_RULE.items()
             if "route" not in rule and "Heart" not in rule]
    check("every rule is stated against the route or the Heart", stray, [])
    # The flag and the words have to agree. An earlier version had braziers
    # and lanterns flagged off-route while their own rules said "on the
    # route", and the report printed both - a label and a text saying
    # different things is C6 in miniature, inside the fix for F12.
    off_words = ("flanking", "beside", "clear of")
    check("the off-route flag agrees with the rule it labels",
          [lid for lid, (rule, off, _) in GENERATOR_RULE.items()
           if off != any(w in rule for w in off_words)], [])
    return 0 if ok else 1


def main() -> int:
    if "--self-test" in sys.argv:
        return self_test()
    laws = load_laws()
    effects = classify(laws)
    print(report(effects))
    print(generator_report(effects, laws))
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
