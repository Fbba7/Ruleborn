#!/usr/bin/env python3
"""C6's remaining half, creature by creature: are the two ability texts one
design written twice, or two designs?

    python3 tools/ability_text.py
    python3 tools/ability_text.py --self-test

Why this exists
---------------
C6 is the last gate holding the character screens, and the register has
described what is left of it as wording - "all 18 still give different ability
text, so the two sections are one reconciliation apart rather than two rosters
apart". That was written after v3.1 reconciled the schools and roles, and it is
too kind. Reading the 18 pairs out of `content/ruleborn.json`:

* **Cooldowns.** Fifteen pairs state one on both sides. In thirteen of them
  §11.2's is shorter, by a median of four seconds, and in one they agree. A
  difference that runs one way in thirteen of fourteen is not two people
  wording the same number differently; it is two balance passes, and §11.2's is
  the more generous one throughout.

* **Effects.** Twelve of the eighteen do a different thing, not the same thing
  by a different amount. Mossbear takes 50% less damage in §11.11 and heals 20%
  in §11.2. Prism Mite splits into copies with half the health, or into mites
  each carrying half the loot. Echoplate shields the whole crew and reflects, or
  shields one ally and does not. Three creatures - Quarryback, Tidewalker,
  Echoplate - have no cooldown in §11.11 at all, because §11.11 describes
  something continuous and §11.2 describes an activated power.

So the screen is not waiting for someone to choose a phrasing. It is waiting for
the eighteen abilities to be designed once. That is content work, and it is the
reason C6 stays a full gate on screens while it is only partly one on
characters: a character screen still has a portrait, a role, a school, traits
and levels to draw, and every one of those is settled.

What is a judgement here, and what is not
-----------------------------------------
`cooldowns()` is read out of the two texts and is not a judgement. `KIND` is:
each of the eighteen is classified by hand as `magnitude` or `effect` with the
reason written out, because no regular expression can tell "heals 20%" from
"takes 50% less damage" - they share no words and mean different things, while
"Glide 3 tiles" and "Glide over one gap" share a word and mean the same thing.

The check that keeps it honest is that `KIND` must name every creature in the
content file and no others, so a roster change cannot leave a stale judgement
behind. Nothing here is written to `content/ruleborn.json`; the content says
what the document says, and this is a reading of it.
"""

import argparse
import json
import pathlib
import re
import statistics
import sys

ROOT = pathlib.Path(__file__).resolve().parent.parent
CONTENT = ROOT / "content"

#: §11.11 states a cooldown after a semicolon, or as "per N s" where the
#: ability is a repeating one. §11.2's summary table puts it in trailing
#: parentheses. Anything else means that side states no cooldown, which is
#: itself the finding for three of the eighteen.
CD_BIBLE = (re.compile(r";\s*(\d+(?:\.\d+)?)\s*s"),
            re.compile(r"per (\d+(?:\.\d+)?)\s*s"))
CD_TABLE = re.compile(r"\((\d+(?:\.\d+)?)\s*s\)\s*$")

MAGNITUDE, EFFECT = "magnitude", "effect"

#: id -> (kind, why). `magnitude` means the two texts describe the same thing
#: and disagree about how much; `effect` means they describe different things.
#: Every reason quotes both sides, so a reader can disagree with the call
#: rather than with the count.
KIND = {
    "featherkin": (MAGNITUDE,
        "Both glide over an obstacle. §11.11 specifies it as 3 tiles and "
        "one height level, §11.2 as “one gap or wall” - a "
        "specification and a summary of the same move."),
    "skyskipper": (EFFECT,
        "§11.11 carries 40% more and hops; §11.2 only bounds 4 tiles "
        "while loaded. The carry bonus is a Carrier's whole reason to exist and "
        "only one side has it."),
    "rambler": (EFFECT,
        "§11.11 breaks “one wall or boulder” - terrain. "
        "§11.2 breaks “the first ward hit” - a placed defence. "
        "§6 and §10.2 are different systems with different budgets."),
    "glass_golem": (MAGNITUDE,
        "Both raise a crystal wall. §11.2 says it blocks guards, which is "
        "what a wall is for; the wall lasts 6 s or 5 s and the cooldown is 20 "
        "or 16."),
    "quarryback": (EFFECT,
        "§11.11 is a movement attack - “rolls 5 tiles then slams; "
        "double damage to walls” - with no cooldown. §11.2 is a timed "
        "buff: break walls and the Vault 50% faster for 6 s. The Vault is in "
        "one and not the other, and it is the thing a heist is for."),
    "prism_mite": (EFFECT,
        "§11.11 splits into “two half-health copies”, which is "
        "survivability. §11.2 splits into “two mites, each carrying "
        "half”, which is loot throughput. Half the health and half the "
        "loot are different halves."),
    "tidewalker": (EFFECT,
        "§11.11 is a terrain affinity that carries an ally through water "
        "and has no cooldown. §11.2 is an activated “ignore all "
        "slowing” for 6 s, solo, on 15 s. Water is a realm feature; "
        "slowing is a status."),
    "hourkeeper": (MAGNITUDE,
        "Both undo damage by rewinding an ally. The window is 3 s or 5 s and "
        "the cooldown 24 or 16."),
    "stillwatch": (EFFECT,
        "§11.11 freezes “one guard”; §11.2 freezes "
        "“one guard or ward”. A ward is a placed object rather than a "
        "character, and whether the freeze reaches it changes every ward-heavy "
        "layout — which is most of §13.4's."),
    "emberling": (EFFECT,
        "§11.11 is area damage plus a 1 s stun, which is crowd control "
        "against guards. §11.2 is heavy damage to “a ward or "
        "pylon”, which is single-target demolition. The stun exists on one "
        "side only."),
    "stormhound": (EFFECT,
        "§11.2 adds “hits chain to a second target”, which "
        "§11.11 has no trace of, and drops “carrying anything”, "
        "which §11.11 has. The speed is 40% or 60%."),
    "sparkwright": (EFFECT,
        "The one pair whose numbers agree exactly - 5 s off a cooldown, on a "
        "20 s cooldown - and they still differ: §11.11 cuts “one "
        "ally's”, §11.2 cuts “the Sage's power cooldowns”. "
        "§12.5 makes the Sage a separate slot from the crew, so this is "
        "the clearest case that the gap is not numeric."),
    "mossbear": (EFFECT,
        "§11.11 takes 50% less damage for 6 s; §11.2 heals 20% over "
        "4 s. Mitigation and healing are different resources and are countered "
        "differently."),
    "bloomling": (EFFECT,
        "§11.11 heals all nearby allies 15% at once, with no radius. "
        "§11.2 heals 6 a second for 5 s within 3 tiles. Instant against "
        "over-time, percentage against flat, and only one states the radius."),
    "rootrunner": (MAGNITUDE,
        "Both grow a root bridge over a gap. §11.2 gives it a life - 8 s - "
        "and a shorter cooldown."),
    "echoplate": (EFFECT,
        "§11.11 blocks one hit “for the crew” and returns it at "
        "40%. §11.2 shields “an ally”, takes its next hit, and "
        "reflects nothing. Crew against one ally, and a reflect on one side "
        "only."),
    "lantern_wisp": (MAGNITUDE,
        "Both reveal hidden wards within a radius: 6 tiles or a 5-tile area "
        "held for 6 s. §11.2 also names illusions, which is a kind of "
        "revealing rather than a second ability."),
    "soulmender": (MAGNITUDE,
        "Both share the crew's incoming damage. For 8 s or 6 s, on 22 s or "
        "18 s."),
}


def load() -> list:
    return json.loads((CONTENT / "ruleborn.json").read_text(encoding="utf-8"))


def cooldown(text: str, table: bool) -> float | None:
    if table:
        m = CD_TABLE.search(text)
        return float(m.group(1)) if m else None
    for pattern in CD_BIBLE:
        m = pattern.search(text)
        if m:
            return float(m.group(1))
    return None


def pairs(roster: list) -> list[dict]:
    out = []
    for c in roster:
        bible = c["ability"]
        table = c["alt_11_2"]["ability"]
        kind, why = KIND.get(c["id"], (None, ""))
        out.append(dict(
            id=c["id"], name=c["name"], role=c["role"],
            bible=bible, table=table, kind=kind, why=why,
            cd_bible=cooldown(bible, table=False),
            cd_table=cooldown(table, table=True),
        ))
    return out


def cooldowns(rows: list[dict]) -> dict:
    """The mechanical half: where both sides state one, which way does it go?"""
    both = [r for r in rows if r["cd_bible"] is not None and r["cd_table"] is not None]
    deltas = [r["cd_table"] - r["cd_bible"] for r in both]
    return dict(
        both=len(both),
        shorter=sum(1 for d in deltas if d < 0),
        longer=sum(1 for d in deltas if d > 0),
        equal=sum(1 for d in deltas if d == 0),
        median=statistics.median(d for d in deltas if d) if any(deltas) else 0,
        missing=[r["name"] for r in rows if r["cd_bible"] is None],
    )


def unclassified(rows: list[dict]) -> tuple[list, list]:
    """Creatures with no judgement, and judgements with no creature."""
    ids = {r["id"] for r in rows}
    return ([r["name"] for r in rows if r["kind"] is None],
            sorted(set(KIND) - ids))


def report(rows: list[dict]) -> None:
    cd = cooldowns(rows)
    effect = [r for r in rows if r["kind"] == EFFECT]
    print("C6's remaining half: 18 creatures, two ability texts each\n")
    print(f"  {'':<14}{'role':<9}{'11.11':>7}{'11.2':>7}{'Δ':>7}   kind")
    for r in rows:
        a, b = r["cd_bible"], r["cd_table"]
        delta = f"{b - a:+.0f}" if a is not None and b is not None else ""
        print(f"  {r['name']:<14}{r['role']:<9}"
              f"{f'{a:.1f}' if a is not None else '—':>7}"
              f"{f'{b:.1f}' if b is not None else '—':>7}{delta:>7}   {r['kind']}")
    print()
    print(f"  Cooldowns: {cd['both']} pairs state one on both sides. "
          f"{cd['shorter']} have §11.2 shorter, {cd['longer']} longer, "
          f"{cd['equal']} equal;")
    print(f"  the median difference is {cd['median']:+.0f} seconds. "
          f"{len(cd['missing'])} state none in §11.11 at all "
          f"({', '.join(cd['missing'])}),")
    print(f"  because §11.11 describes something continuous there and "
          f"§11.2 an activated power.\n")
    print(f"  Effects: {len(effect)} of {len(rows)} do a different thing rather "
          f"than the same thing by a\n  different amount.\n")
    for r in effect:
        print(f"  {r['name']}")
        print(f"    11.11  {r['bible']}")
        print(f"    11.2   {r['table']}")
        print(f"           {r['why']}\n")
    print("  A difference that runs one way in "
          f"{cd['shorter']} of {cd['both']} is two balance passes, not two "
          "wordings. Settling")
    print("  it is designing eighteen abilities once. It is the last gate "
          "standing on the")
    print("  screens \u2014 C3 and C8 are decided in everything but two "
          "sentences and a table \u2014 and")
    print("  it does not hold the character art, which needs a portrait, a "
          "role and a school,")
    print("  all three settled since v3.1.")


def self_test() -> int:
    ok = True

    def check(name: str, got, want) -> None:
        nonlocal ok
        good = got == want
        ok = ok and good
        print(f"  [{'ok ' if good else 'FAIL'}] {name}"
              f"{'' if good else f'  got {got!r}, want {want!r}'}")

    rows = pairs(load())
    check("all 18 creatures are read", len(rows), 18)
    # A judgement with no creature, or a creature with no judgement, is how a
    # hand-written classification goes stale behind a roster change.
    check("every creature is classified and no judgement is orphaned",
          unclassified(rows), ([], []))
    cd = cooldowns(rows)
    check("13 of the 15 comparable pairs have §11.2 shorter",
          (cd["shorter"], cd["both"]), (13, 15))
    check("three creatures state no cooldown in §11.11",
          len(cd["missing"]), 3)
    check("12 of the 18 differ in effect",
          sum(1 for r in rows if r["kind"] == EFFECT), 12)
    # The two readers must not both match the same text, or a pair would be
    # compared with itself and always agree.
    check("§11.2's trailing-parenthesis form is not read as §11.11's",
          cooldown("Glide over one gap or wall (12 s)", table=False), None)
    check("§11.11's semicolon form is not read as §11.2's",
          cooldown("Glide 3 tiles, ignoring one height level; 14 s cooldown",
                   table=True), None)
    return 0 if ok else 1


def main() -> int:
    ap = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    ap.add_argument("--self-test", action="store_true")
    args = ap.parse_args()
    if args.self_test:
        return self_test()
    report(pairs(load()))
    return 0


if __name__ == "__main__":
    sys.exit(main())
