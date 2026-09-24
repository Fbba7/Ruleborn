"""Weaving laws into a generated realm (§5.5, §7.3, §13.3).

Only the 19 laws whose whole effect is a parameter change are applied — the ones
`tools/law_effects.py` classifies as such. The other 29 need an object to spawn,
a periodic rule, or an attribute no character carries, and pretending otherwise
would make the hold rate a measure of this file's imagination.

That restriction is itself the finding: §13.3 gives every player a generated
defence woven from "their realm, their laws and their ruleborn", and a generator
can only weave what a rule sheet can express.
"""

import json
import pathlib

from .fixed import Rng

ROOT = pathlib.Path(__file__).resolve().parent.parent.parent
_DATA = json.loads((ROOT / "content" / "law_effects.json").read_text(encoding="utf-8"))
LAWS = {law["id"]: law for law in _DATA["laws"]}
#: The laws the harness weaves: its own reading of the sheet (law_effects'
#: `harness`), not sim/'s, which applies more rows than this model does.
SIMULATED = [law for law in _DATA["laws"] if law["harness"]]

#: §5.5's capacity by realm level, from the economy model's own curve. A realm
#: may weave laws up to its share of the universe's pool.
STABILITY_BY_LEVEL = {1: 40, 2: 70, 3: 110, 4: 160, 5: 220}


class Sheet:
    """A realm's rule sheet: the parameters in force, after the laws are woven.

    Multipliers compound; flags are set by the last law that sets them. Both are
    §7.3's model — "laws change a realm's rule sheet rather than containing
    special cases" — and this class is the smallest honest test of whether that
    architecture survives 48 pieces of content.
    """

    MULTIPLIERS = {
        "crew_speed", "guard_speed", "loaded_speed", "clock_rate", "sight_range",
        "suspicion_fill", "suspicion_decay", "noise_radius", "structure_damage",
        "damage", "cone_angle", "alarm_range",
    }

    def __init__(self, woven=()):
        self.woven = list(woven)
        self.values = {}
        for law in self.woven:
            for key, value in law["params"].items():
                if key in self.MULTIPLIERS:
                    self.values[key] = self.values.get(key, 1.0) * value
                else:
                    self.values[key] = value

    def factor(self, key: str) -> float:
        return self.values.get(key, 1.0)

    def flag(self, key: str, default=0):
        return self.values.get(key, default)

    @property
    def names(self) -> list:
        return [law["name"] for law in self.woven]

    @property
    def cost(self) -> int:
        return sum(law["stability_cost"] for law in self.woven)


def weave(seed: int, realm_level: int, favour_defender: bool = False) -> Sheet:
    """Pick laws for a generated realm, inside §5.5's stability budget.

    `favour_defender` is the question §13.3 leaves open. A generator that picks
    at random weaves laws that help the raider about as often as they hinder —
    Half gravity and Haste are in the pool. A generator that reads the sign of
    each effect does not. Both are measured, because "generated from their laws"
    does not say which.
    """
    rng = Rng(seed ^ 0xA55E7)
    budget = STABILITY_BY_LEVEL[realm_level]
    pool = list(SIMULATED)
    if favour_defender:
        pool = [law for law in pool if _helps_defender(law)]
    woven, spent = [], 0
    for _ in range(len(pool)):
        law = rng.choice(pool)
        if law in woven or spent + law["stability_cost"] > budget:
            continue
        woven.append(law)
        spent += law["stability_cost"]
    return Sheet(woven)


#: Which way a parameter cuts. A law that speeds the crew up helps the raider,
#: whatever the defender paid for it.
_RAIDER_HELPED_IF_ABOVE_ONE = {"crew_speed", "loaded_speed", "leap_obstacles",
                               "climb_levels", "still_is_invisible"}
_RAIDER_HELPED_IF_BELOW_ONE = {"guard_speed", "sight_range", "suspicion_fill",
                               "noise_radius", "alarm_range"}


def _helps_defender(law: dict) -> bool:
    score = 0
    for key, value in law["params"].items():
        if key in _RAIDER_HELPED_IF_ABOVE_ONE:
            score -= 1 if value > 1 else 0
        elif key in _RAIDER_HELPED_IF_BELOW_ONE:
            score += 1 if value > 1 else -1
        elif key in ("touch_damage", "unlit_drain"):
            score += 1                      # hurts whoever moves: the crew
        elif key == "structure_damage":
            score -= 1
        elif key == "hide_behind_walls":
            score += 1                      # Glass: nobody hides behind a wall
        elif key == "structure_regrowth":
            score += 1                      # Regrowth: buildings, wards, guards
        # ally_healing (Kinship) heals whoever stands beside an ally, crew and
        # guards alike, so it cuts both ways and scores nothing. It used to
        # share health_regen with Regrowth and inherit Regrowth's +1 (F31).
    return score > 0
