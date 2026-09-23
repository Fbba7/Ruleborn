#!/usr/bin/env python3
"""Facts the design document states, in one place, for the tools that read them.

    python3 tools/design_facts.py          # every fact, its value and its home

Why this exists
---------------
§31.4 pins four constants in the document's own data — tick rate, law count,
crew size, page total — and the build checker verifies them against the prose.
That rule stops at the document. One level out, in the tools that check it,
eleven more of the document's facts were each written down two to four times.

The worst are not the repeats. They are the disagreements:

  * `SETTLED` had four homes and `build_roadmap`'s was missing `withdrawn`,
    so a withdrawn item counted as open on the roadmap and settled everywhere
    else.
  * `HOLD_BAND` had four, as `(30.0, 45.0)` in three and `(30, 45)` in the
    fourth.
  * `CREW` meant the range 3-to-5 in one tool and the number 5 in another —
    the same name for two facts, which is worse than the same fact twice.

And the repeats that agree are worse than they look, because **four of them
restate data this repository has already extracted**. `content/notes.json`
carries the eight notes and their oppositions; `content/roles.json` carries the
five roles. Four tools typed the notes out again and four typed the roles.

So: derived from `content/` where the extraction already exists, declared with
the section that owns it where it does not, and
`check_docs_consistency.check_one_fact_home` refuses a second copy.
"""

import json
import pathlib
import re
import sys

ROOT = pathlib.Path(__file__).resolve().parent.parent
CONTENT = ROOT / "content"


def _load(name: str) -> list:
    return json.loads((CONTENT / f"{name}.json").read_text(encoding="utf-8"))


# -- derived: the extraction already exists, so nothing is typed twice -------

#: §8.1's eight notes, in the document's own order.
NOTES = tuple(n["name"] for n in _load("notes"))

#: §8.1's oppositions. A law may not carry a note and its opposite, and a chord
#: needs three notes none of which are opposites (§8.5).
OPPOSITE = {n["name"]: n["opposite"] for n in _load("notes")}

#: §11.1's five role names. Named for what it is: `heist_harness.sim.ROLES`
#: is the full stats table read from the same file, and one name for two facts
#: is worse than one fact in two places.
ROLE_NAMES = tuple(r["name"] for r in _load("roles"))

#: §7's six schools, read off the 48 law sheets rather than listed again.
SCHOOLS = tuple(dict.fromkeys(law["school"] for law in _load("laws")))


# -- declared: stated in prose, with the section that owns each -------------

#: §13.2. How often a defence should hold: "Below a quarter, defenders feel
#: helpless and stop designing. Above half, raiding feels futile."
HOLD_BAND = (30.0, 45.0)

#: §12.6. "roughly one every 8 to 12 seconds, or 15 to 25 in a run."
DECISION_BAND = (15, 25)
DECISION_SECONDS = (8, 12)

#: §12.5. Three characters, four from Keeper level 8, five from level 16.
CREW_RANGE = (3, 5)

#: §5.2 (v3.3): wards and guard posts by realm level 1 to 5, "a measured
#: budget, not a formula". v3.2's were 3 + realm level and 1 + (level - 1) // 2.
WARD_LIMITS = (8, 8, 6, 7, 8)
GUARD_POSTS = (1, 1, 2, 3, 3)

#: §12.8 and §12.20. One hit every 0.8 seconds for damage equal to Power, on
#: both sides. The 0.8 is the only cadence the document states.
WIND_UP = 0.8

#: §12.8 (v3.3): the first hit on an Unaware guard is a knockout "after a 2 s
#: takedown" (§29.1). v3.2's triple Power and half-health floor are gone.
TAKEDOWN_SECONDS = 2

#: §11.1 (v3.3): "While two or more characters work the same object, every
#: hit on it deals 25% more: the assist bonus."
ASSIST_BONUS = 0.25

#: §10.3 (v3.3): "The disarmer stands on the ward's tile for 15 seconds at
#: every ward level".
DISARM_SECONDS = 15

#: §12.6. The Vault's health, per Vault level.
VAULT_HEALTH_PER_LEVEL = 1_500

#: §12.6: "Breakers deal double damage to it."
BREAKER_VAULT_MULTIPLIER = 2

#: §12.6 (v3.3): "every 5 seconds of cracking every guard in the Heart hears
#: the Vault and starts Investigating it" — a heard event, not suspicion.
CRACK_NOISE_SECONDS = 5

#: §12.19: "Every role can load, at 30 units a second."
LOAD_PER_SECOND = 30

#: §11.1, the Carrier: "15% slower when loaded".
CARRIER_LOADED_PACE = 0.85

#: §12.20: "has ten seconds before capture. An ally standing adjacent revives
#: it in 3 seconds, a Mender in 1.5, and it returns at 30% of its full health"
#: (v3.3, G14).
DOWN_SECONDS = 10
REVIVE_SECONDS = 3.0
MENDER_REVIVE_SECONDS = 1.5
REVIVE_HEALTH = 0.30

#: §12.17 (v3.3, G13): "crouched, a crew member moves at half its role's
#: speed (11.1), and running, at double".
CROUCH_PACE = 0.5
RUN_PACE = 2.0

#: §5.4: the skiff "takes 5 seconds to reach an outer realm and 20 seconds to
#: fight the winds around the Heart".
SKIFF_OUTER_SECONDS = 5
SKIFF_HEART_SECONDS = 20

#: §12.9's grades, as the value each is worth when a run is scored.
GRADE_VALUE = {"clean": 1.0, "loud": 0.7, "partial": 0.4, "foiled": 0.0}

#: Where each declared fact is stated, so the report can cite it and a reader
#: can check it. The derived ones cite the content file instead.
HOME = {
    "NOTES": "content/notes.json (8.1)",
    "OPPOSITE": "content/notes.json (8.1)",
    "ROLE_NAMES": "content/roles.json (11.1)",
    "SCHOOLS": "content/laws.json (7)",
    "HOLD_BAND": "13.2",
    "DECISION_BAND": "12.6",
    "DECISION_SECONDS": "12.6",
    "CREW_RANGE": "12.5",
    "WARD_LIMITS": "5.2",
    "GUARD_POSTS": "10.2",
    "WIND_UP": "12.8",
    "TAKEDOWN_SECONDS": "29.1",
    "ASSIST_BONUS": "11.1",
    "DISARM_SECONDS": "10.3",
    "VAULT_HEALTH_PER_LEVEL": "12.6",
    "BREAKER_VAULT_MULTIPLIER": "12.6",
    "CRACK_NOISE_SECONDS": "12.6",
    "LOAD_PER_SECOND": "12.19",
    "CARRIER_LOADED_PACE": "11.1",
    "DOWN_SECONDS": "12.20",
    "REVIVE_SECONDS": "12.20",
    "MENDER_REVIVE_SECONDS": "12.20",
    "REVIVE_HEALTH": "12.20",
    "CROUCH_PACE": "12.17",
    "RUN_PACE": "12.17",
    "SKIFF_OUTER_SECONDS": "5.4",
    "SKIFF_HEART_SECONDS": "5.4",
    "GRADE_VALUE": "12.9",
}


#: How each declared fact reads in its home section, so the value here can be
#: checked against the document rather than trusted. Until v3.3 nothing did:
#: the rule above stops a second copy in the tools, and nothing stopped the one
#: copy going stale when the document moved. The pattern captures the value;
#: the function turns the capture into this module's unit.
_words = {"half": 0.5, "double": 2.0, "ten": 10, "two": 2, "three": 3}
_n = lambda x: _words.get(x, None) if x in _words else float(x.replace(",", ""))
STATED = {
    "HOLD_BAND": (r"Authored islands are held to (\d+) to (\d+)%",
                  lambda m: (float(m[0]), float(m[1]))),
    "DECISION_BAND": (r"or (\d+) to (\d+) in a run", lambda m: (int(m[0]), int(m[1]))),
    "DECISION_SECONDS": (r"roughly one every (\d+) to (\d+) seconds",
                         lambda m: (int(m[0]), int(m[1]))),
    "CREW_RANGE": (r"A crew of (\d+) to (\d+)", lambda m: (int(m[0]), int(m[1]))),
    "WARD_LIMITS": (r"the legibility cap 13.2 sets: (\d+), (\d+), (\d+), (\d+) and (\d+)",
                    lambda m: tuple(int(x) for x in m)),
    "GUARD_POSTS": (r"Every realm; (\d+), (\d+), (\d+), (\d+) and (\d+) by realm level "
                    r"\(5\.2\)\. One ruleborn", lambda m: tuple(int(x) for x in m)),
    "WIND_UP": (r"shows a ([\d.]+)-second wind-up", lambda m: float(m[0])),
    "TAKEDOWN_SECONDS": (r"after a (\d+) s takedown", lambda m: int(m[0])),
    "ASSIST_BONUS": (r"every hit on it deals (\d+)% more: the assist bonus",
                     lambda m: int(m[0]) / 100),
    "DISARM_SECONDS": (r"stands on the ward's tile for (\d+) seconds", lambda m: int(m[0])),
    "VAULT_HEALTH_PER_LEVEL": (r"([\d,]+) health per Vault level", lambda m: int(_n(m[0]))),
    "BREAKER_VAULT_MULTIPLIER": (r"Breakers deal (double) damage to it",
                                 lambda m: int(_n(m[0]))),
    "CRACK_NOISE_SECONDS": (r"every (\d+) seconds of cracking", lambda m: int(m[0])),
    "LOAD_PER_SECOND": (r"Every role can load, at (\d+) units a second",
                        lambda m: int(m[0])),
    "CARRIER_LOADED_PACE": (r"(\d+)% slower when loaded", lambda m: 1 - int(m[0]) / 100),
    "DOWN_SECONDS": (r"has (\w+) seconds before capture", lambda m: int(_n(m[0]))),
    "REVIVE_SECONDS": (r"revives it in (\d+) seconds", lambda m: float(m[0])),
    "MENDER_REVIVE_SECONDS": (r"a Mender in ([\d.]+)", lambda m: float(m[0])),
    "REVIVE_HEALTH": (r"returns at (\d+)% of its full health", lambda m: int(m[0]) / 100),
    "CROUCH_PACE": (r"crouched, a crew member moves at (half) its role's speed",
                    lambda m: _n(m[0])),
    "RUN_PACE": (r"and running, at (double)", lambda m: _n(m[0])),
    "SKIFF_OUTER_SECONDS": (r"takes (\d+) seconds to reach an outer realm",
                            lambda m: int(m[0])),
    "SKIFF_HEART_SECONDS": (r"and (\d+) seconds to (?:fight the winds around|reach) the Heart",
                            lambda m: int(m[0])),
    "GRADE_VALUE": (r"\| Clean\n[^\n]*\n\| ×([\d.]+)[\s\S]*?\| Loud\n[^\n]*\n\| ×([\d.]+)"
                    r"[\s\S]*?\| Partial\n[^\n]*\n\| ×([\d.]+)[\s\S]*?\| Foiled\n[^\n]*\n\| ×([\d.]+)",
                    lambda m: {"clean": float(m[0]), "loud": float(m[1]),
                               "partial": float(m[2]), "foiled": float(m[3])}),
}

#: Facts the document has moved past and this repository has not, each with
#: the register item that owns the gap. Reported as behind, not as agreeing:
#: the simulation still reads these values, so they stay declared until the
#: port lands, and then they go.
BEHIND: dict[str, tuple[str, str]] = {
    # Empty since D56: the ambush, the crack noise and disarming were ported
    # to sim/ and the harness, and their v3.2 facts deleted rather than kept.
}


def against_document() -> tuple[list[str], list[str]]:
    """(disagreements, facts behind the document), for every declared fact."""
    import design_doc
    sys.path.insert(0, str(ROOT / "tools"))
    import check_document
    from audit_register import is_open
    doc = check_document.Doc(str(design_doc.HTML))
    index = check_document.section_index(doc)
    wrong, behind = [], []
    for name, (pattern, read) in STATED.items():
        home = HOME[name]
        m = re.search(pattern, index.get(home, ""))
        value = read(m.groups()) if m else None
        if name in BEHIND:
            item, now = BEHIND[name]
            behind.append(f"{name} ({home}): {now} [{item}]")
            if not is_open(item):
                wrong.append(f"{name}: listed as behind under {item}, which "
                             f"the register calls settled")
            if m and value == globals()[name]:
                wrong.append(f"{name}: listed as behind under {item}, but "
                             f"{home} still states {value!r}")
            continue
        if value != globals()[name]:
            wrong.append(f"{name}: declared {globals()[name]!r}, {home} "
                         f"{'states ' + repr(value) if m else 'no longer states it'}")
    unstated = sorted(n for n, h in HOME.items()
                      if not h.startswith("content/") and n not in STATED)
    wrong += [f"{n}: declared with no pattern to check it by" for n in unstated]
    return wrong, behind


def main() -> int:
    print("What the design document says, and where each tool should read it "
          "from\n")
    width = max(len(k) for k in HOME)
    for name, home in HOME.items():
        value = repr(globals()[name])
        print(f"  {name:<{width}}  {value[:52]:<54}{home}")
    missing = sorted(set(HOME) - set(globals()))
    extra = sorted(n for n in globals()
                   if n.isupper() and len(n) > 2 and n not in HOME
                   and n not in ("ROOT", "CONTENT", "HOME", "STATED", "BEHIND"))
    if missing or extra:
        print(f"\n  HOME and the module disagree: missing {missing}, "
              f"undeclared {extra}")
        return 1
    wrong, behind = against_document()
    if behind:
        print("\n  Behind the document, and owned by a register item:")
        for line in behind:
            print(f"    {line}")
    if wrong:
        print("\n  Declared facts the document no longer states:")
        for line in wrong:
            print(f"    {line}")
        return 1
    print(f"\n  {len(STATED) - len(behind)} declared facts read back from their "
          f"home sections.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
