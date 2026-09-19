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

#: §12.8 and §12.20. One hit every 0.8 seconds for damage equal to Power, on
#: both sides; the first hit on a guard that has not noticed the crew is
#: tripled. The 0.8 is the only cadence the document states.
WIND_UP = 0.8
AMBUSH_MULTIPLIER = 3.0

#: §12.6. The Vault's health, per Vault level.
VAULT_HEALTH_PER_LEVEL = 1_500

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
    "WIND_UP": "12.8",
    "AMBUSH_MULTIPLIER": "12.8",
    "VAULT_HEALTH_PER_LEVEL": "12.6",
    "GRADE_VALUE": "12.9",
}


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
                   and n not in ("ROOT", "CONTENT", "HOME"))
    if missing or extra:
        print(f"\n  HOME and the module disagree: missing {missing}, "
              f"undeclared {extra}")
        return 1
    return 0


if __name__ == "__main__":
    sys.exit(main())
