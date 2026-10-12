"""Constants transcribed from the Ruleborn design document v2.3.

Everything here is quoted from the document rather than derived, so the model can
be validated against the document's own published tables. Where the document
contradicts itself, both values are recorded and the choice is made in
`config.py`, not here.

Section references are to the design document.
"""

import json
import pathlib
import re
from dataclasses import dataclass, field

_ROOT = pathlib.Path(__file__).resolve().parents[2]

# --------------------------------------------------------------------------
# Buildings (§10.2)
# --------------------------------------------------------------------------


@dataclass(frozen=True)
class Building:
    name: str
    costs: tuple[int, ...]           # Starlight, per level, index 0 == level 1
    spire_required: tuple[int, ...]  # Spire level needed for each level
    placement: str                   # "heart" | "every" | "outer"
    per_realm: int = 1               # how many one realm may hold at most
    # Producers only:
    hourly: tuple[int, ...] = ()     # output per hour at each level
    slots: tuple[int, ...] = ()      # worker slots at each level
    resource: str = ""
    keeper_required: tuple[int, ...] = ()   # the Library's Keeper gate (10.4)
    holds: tuple[int, ...] = ()             # Starlight and Essence each (9.1)


def _spire_every_level(n: int) -> tuple[int, ...]:
    """Ten-level buildings need a Spire of the same level (§10.1)."""
    return tuple(range(1, n + 1))


def _spire_odd(n: int) -> tuple[int, ...]:
    """Five-level buildings need half the Spire's level, rounded up (§10.1)."""
    return tuple(2 * i - 1 for i in range(1, n + 1))


SPIRE = Building(
    "Keeper's Spire",
    (1_000, 2_200, 4_840, 10_600, 23_400, 51_500, 113_400, 249_400, 548_800, 1_207_300),
    # The Spire is gated by Keeper level, not by itself (§14.2).
    spire_required=(0,) * 10,
    placement="heart",
)

#: Keeper level required for each Spire level (§14.2).
SPIRE_KEEPER_LEVEL = (1, 5, 9, 13, 17, 21, 25, 29, 33, 37)

BUILDINGS: dict[str, Building] = {
    "Vault": Building(
        "Vault",
        (800, 1_720, 3_700, 8_000, 17_100, 36_800, 79_000, 169_900, 365_300, 785_300),
        _spire_every_level(10), "heart",
    ),
    "Anchor Stone": Building(
        "Anchor Stone",
        (600, 1_320, 2_900, 6_400, 14_100, 30_900, 68_000, 149_700, 329_300, 724_400),
        _spire_every_level(10), "every",
    ),
    "Star Well": Building(
        "Star Well",
        (400, 900, 2_020, 4_600, 10_300, 23_100, 51_900, 116_800, 262_700, 591_200),
        _spire_every_level(10), "every", per_realm=2,
        hourly=(80, 108, 146, 197, 266, 359, 484, 654, 883, 1_191),
        slots=(1, 1, 1, 2, 2, 2, 3, 3, 3, 3), resource="starlight",
    ),
    "Aether Spring": Building(
        "Aether Spring",
        (400, 900, 2_020, 4_600, 10_300, 23_100, 51_900, 116_800, 262_700, 591_200),
        _spire_every_level(10), "every", per_realm=2,
        hourly=(60, 81, 109, 148, 199, 269, 363, 490, 662, 894),
        slots=(1, 1, 1, 2, 2, 2, 3, 3, 3, 3), resource="aether",
    ),
    "Garden": Building(
        "Garden",
        (400, 900, 2_020, 4_600, 10_300, 23_100, 51_900, 116_800, 262_700, 591_200),
        _spire_every_level(10), "every", per_realm=2,
        hourly=(40, 54, 73, 98, 133, 179, 242, 327, 441, 596),
        slots=(1, 1, 1, 2, 2, 2, 3, 3, 3, 3), resource="essence",
    ),
    "Storehouse": Building(
        "Storehouse",
        (500, 1_120, 2_530, 5_700, 12_800, 28_800, 64_900, 146_000, 328_400, 738_900),
        _spire_every_level(10), "outer",
    ),
    "Law Pylon": Building(
        "Law Pylon",
        (500, 1_120, 2_530, 5_700, 12_800, 28_800, 64_900, 146_000, 328_400, 738_900),
        _spire_every_level(10), "every", per_realm=3,
    ),
    "Hearth": Building(
        "Hearth", (700, 1_820, 4_730, 12_300, 32_000), _spire_odd(5), "every",
    ),
    "Nursery": Building(
        "Nursery", (1_000, 2_700, 7_290, 19_700, 53_100), _spire_odd(5), "outer",
    ),
    "Guardian Post": Building(
        "Guardian Post", (600, 1_560, 4_060, 10_500, 27_400), _spire_odd(5), "every", per_realm=3,
    ),
    "Ward": Building(
        "Ward", (350, 880, 2_190, 5_500, 13_700), _spire_odd(5), "every", per_realm=8,
    ),
    "Resonance Lab": Building(
        "Resonance Lab", (1_500, 4_200, 11_760, 32_900, 92_200), _spire_odd(5), "heart",
    ),
    "Observatory": Building(
        "Observatory", (1_200, 3_360, 9_410, 26_300, 73_800), _spire_odd(5), "heart",
    ),
    "Beacon": Building(
        "Beacon", (1_000, 2_800, 7_840, 22_000, 61_500), _spire_odd(5), "heart",
    ),
    "Visitor's Dock": Building(
        "Visitor's Dock", (1_500, 4_800, 15_360), (4, 7, 10), "heart",
    ),
}

#: Places in a Hearth at each level (§10.2). Roster = 3 + sum of these (§11.5).
HEARTH_HOMES = (3, 3, 4, 4, 5)

#: Producing buildings hold this many hours of output before collection (§10.2).
STORAGE_HOURS = 12

# --------------------------------------------------------------------------
# Realms (§5.2)
# --------------------------------------------------------------------------

try:                                        # §5.2's and §9.5's realm facts,
    from ..design_facts import (REALM_KEEPER_LEVELS, REALM_LEVEL_COSTS,  # from their
                                REALM_LEVEL_SPIRE, REALM_OPEN_COST)  # one home
except ImportError:
    from design_facts import (REALM_KEEPER_LEVELS, REALM_LEVEL_COSTS,
                              REALM_LEVEL_SPIRE, REALM_OPEN_COST)

#: Keeper level at which each of the six outer realms becomes available.
REALM_UNLOCK_KEEPER_LEVEL = REALM_KEEPER_LEVELS

#: Star Wells / Aether Springs / Gardens permitted per outer realm, by realm level.
PRODUCERS_PER_REALM = (1, 1, 2, 2, 2)

#: Law slots per outer realm, by realm level.
REALM_LAW_SLOTS = (1, 1, 2, 2, 3)
HEART_LAW_SLOTS = 2

# --------------------------------------------------------------------------
# Stability (§5.5)
# --------------------------------------------------------------------------

def spire_stability(level: int) -> int:
    return 30 + 8 * level


def anchor_stability(level: int) -> int:
    return 8 + 5 * level


#: (upper strain bound, production multiplier, band name). Last entry is open-ended.
STRAIN_BANDS = (
    (0.40, 1.00, "Quiet"),
    (0.70, 1.05, "Steady"),
    (0.90, 1.10, "Humming"),
    (1.00, 1.15, "Brimming"),
    (1.10, 1.15, "Strained"),
    (1.25, 1.15, "Cracking"),
    (float("inf"), 1.15, "Breaking"),
)

TIER_COST_MULTIPLIER = (1.0, 1.3, 1.6)

# --------------------------------------------------------------------------
# Production (§9.3)
# --------------------------------------------------------------------------

#: Staffing factor by number of workers assigned, index 0 == unstaffed.
STAFFING = (0.0, 0.6, 0.85, 1.0)

REALM_MATCH_BONUS = 1.10          # a producer in a realm of its school (§5.2)
REALM_LAW_BONUS = 0.10            # per realm law of a matching school (§5.1)
CROWN_LAW_BONUS = 0.05            # per crown law of a matching school (§5.1)

# --------------------------------------------------------------------------
# Keeper levels (§14.2)
# --------------------------------------------------------------------------

try:                                        # §14.2's table and sources, from
    from ..design_facts import (KEEPER_XP_TO_NEXT, STARLIGHT_PER_XP,  # their one home
                                XP_PER_FOILED_HEIST, XP_PER_LAW_RESTORED,
                                XP_PER_SUCCESSFUL_HEIST)
except ImportError:
    from design_facts import (KEEPER_XP_TO_NEXT, STARLIGHT_PER_XP,
                              XP_PER_FOILED_HEIST, XP_PER_LAW_RESTORED,
                              XP_PER_SUCCESSFUL_HEIST)
#: Level 40 is the top: the table gives the experience to each level after 1.
KEEPER_LEVEL_CAP = len(KEEPER_XP_TO_NEXT) + 1

# --------------------------------------------------------------------------
# Raiding (§9.6 and §9.4)
# --------------------------------------------------------------------------

try:                                        # as tools.economy_model, or with
    from ..design_facts import (ATTEMPT_BAND, DIFFICULTY,         # tools/ on the path
                                HAUL_BASE, HAUL_FATIGUE, HAUL_GROWTH)
except ImportError:
    from design_facts import (ATTEMPT_BAND, DIFFICULTY,           # 9.6 (D37)
                              HAUL_BASE, HAUL_FATIGUE, HAUL_GROWTH)
#: v3.2's base, before §9.6's raid-worth check raised it to 2,400
#: (`design_facts.HAUL_BASE`). Kept because the findings measured against the
#: old formula (F14, C4) reproduce on it; `Config.document()` mints from
#: the document's base (D58).
V32_HAUL_BASE = 100
#: An attempt is worth this fraction of a clean same-level haul (§9.6), which
#: that section calls "the number the progression curve is built on". It is
#: E[grade] over all attempts: 62.5% succeed, split 35% clean / 40% loud / 25%
#: partial, so 0.625 x (0.35x1.0 + 0.40x0.7 + 0.25x0.4) = 0.456.
HAUL_VALUE_PER_ATTEMPT = 0.46

#: v3.0's §9.6 multiplied the haul by `fill`, "the share of the crew's bags
#: actually loaded" (§12.19). 0.46 was not re-derived against it. Measured in the
#: heist harness, a crew that plays to §12.19's own break-even and gets out has
#: filled about two fifths of its bags:
#:
#:     python3 -m tools.heist_harness depth
#:
#: so the value of an attempt is 0.46 x 0.40, not 0.46. This is the C19 pattern
#: applied to the one number §9.6 names as load-bearing.
#:
#: Was 0.52 until the Vault phase was fixed (D24). The harness was ending the
#: phase when the *smallest* bag filled, which pinned every crew near 53%
#: whatever it did — so the figure was not only wrong, it was a constant where
#: the truth is a spread.
MEASURED_FILL_ON_SUCCESS = 0.40

#: And the spread, which is the part §9.6 has no term for at all. The same
#: islands, the same seeds, a crew that plays to 95% instead of §12.19's 70%:
#: 0.89. So what a raid pays varies by 2.2x with how well it is played, against
#: a formula whose only skill-like term is the grade multiplier.
MEASURED_FILL_OPTIMAL = 0.89
#: §9.4's balance target: a successful heist yields this share of a day's production.
HEIST_SHARE_OF_DAILY_PRODUCTION = 0.20

#: Heist success rate by day, from the arc in §14.5.
def heist_success_rate(day: int) -> float:
    if day <= 3:
        return 0.80
    if day <= 14:
        return 0.75
    if day <= 30:
        return 0.70
    return 0.60


try:
    from ..design_facts import ENTRY_FEE_RATE
except ImportError:
    from design_facts import ENTRY_FEE_RATE  # 9.4 (D37), of B(V) as the owner decided (F39)

# --------------------------------------------------------------------------
# Player archetypes (§14.1)
# --------------------------------------------------------------------------


@dataclass(frozen=True)
class Archetype:
    name: str
    sessions_per_day: int
    heists_per_day: int
    lab_experiments_per_day: int


ARCHETYPES = {
    "engaged": Archetype("engaged", 5, 4, 3),
    "regular": Archetype("regular", 3, 2, 2),
    "casual": Archetype("casual", 1, 1, 1),
    # §14.4's "player who never raids": the model gives them the engaged
    # player's sessions, since §14.4 prices only their pages.
    "never_raids": Archetype("never_raids", 5, 0, 3),
}

# --------------------------------------------------------------------------
# Published figures, for validation
# --------------------------------------------------------------------------

#: §9.3, engaged player, resources produced per day (before heist loot).
PUBLISHED_DAILY_PRODUCTION = {
    2: (2_100, 800, 500),
    8: (6_200, 4_600, 3_100),
    31: (17_300, 13_000, 8_700),
    91: (94_100, 70_600, 47_000),
    181: (152_800, 114_600, 76_400),
    301: (256_100, 192_100, 125_300),
}

#: §14.2, the day each archetype reaches selected Keeper levels.
PUBLISHED_KEEPER_DAYS = {
    #  level: (engaged, regular, casual)
    5: (4, 6, 13),
    10: (12, 22, 48),
    16: (31, 64, 135),
    20: (47, 88, 186),
    28: (90, 160, 333),
    40: (181, 274, 556),
}

#: §14.3, the day an engaged player reaches selected milestones.
PUBLISHED_MILESTONES_ENGAGED = {
    "Outer realm 1 opens": 2,
    "Outer realm 2 opens": 6,
    "Outer realm 3 opens": 13,
    "Outer realm 4 opens": 27,
    "Outer realm 5 opens": 52,
    "Outer realm 6 opens": 90,
    "Spire level 3": 10,
    "Spire level 5": 34,
    "Spire level 7": 73,
    "Spire level 10": 161,
}

#: §5.5, an engaged player's stability over time: (capacity, laws woven, strain).
PUBLISHED_STABILITY = {
    2: (51, 3, 0.78),
    8: (100, 4, 0.53),
    31: (202, 7, 0.56),
    61: (276, 12, 0.83),
    91: (347, 15, 0.82),
    181: (446, 22, 1.10),
    366: (516, 22, 0.96),
}


#: Hours a crew member is unavailable per heist: 3 minutes of heist (§12.6)
#: plus 45 minutes' rest after a clean escape (§11.6, §12.9).
CREW_HOURS_PER_HEIST = 0.8


# --------------------------------------------------------------------------
# Aether and Essence sinks (§9.5)
# --------------------------------------------------------------------------
#
# Until now the model produced these two and spent neither, which made every
# law-restoration date indicative only. §9.5 prices every sink; these are those
# prices, transcribed.

#: §9.5: "A new ruleborn: 100 x 1.15^(ruleborn owned) Essence (about 400 for the
#: 10th, 1,600 for the 20th, 6,600 for the 30th)". Those worked values match the
#: formula, so §9.5 is internally consistent.
BIRTH_BASE = 100
BIRTH_GROWTH = 1.15

#: §11.5, for the same thing: "A birth costs 100 Essence plus 40 per character
#: already owned." Linear, not geometric. At the roster ceiling of 38 the two
#: differ by eleven times. That is C28, and `Config.birth_rule` picks between
#: them.
BIRTH_LINEAR_BASE = 100
BIRTH_LINEAR_STEP = 40

#: §9.5 and §11.4: Essence to reach level n = 150 x 1.55^(n-2), up to level 10.
CHARACTER_LEVEL_BASE = 150
CHARACTER_LEVEL_GROWTH = 1.55
MAX_CHARACTER_LEVEL = 10

#: §9.5: weaving costs 40 Aether per point of stability, and upkeep 0.5 Aether an
#: hour per point.
WEAVE_AETHER_PER_POINT = 40
UPKEEP_AETHER_PER_POINT_HOUR = 0.5

# §9.5's scouting price, 20 Aether a realm, is gone: the owner made scouting
# free (F46), so it is not a sink.
#: §9.5: a Lab experiment is 400 Aether x Lab level.
LAB_AETHER_PER_LEVEL = 400

#: §10.4's Library curve, all ten levels.
#:
#: v3.0 added the Library (as §10.5) and gave three levels — 1, 5 and
#: 10 — so the other seven were interpolated on the curve those imply.
#: v3.1 states all ten, and they are not that curve: it reads 5, 6 and 8 at
#: levels 2 to 4 where the interpolation gives 3.7, 4.5 and 5.5, so the model
#: understated the Library by up to a third at every level the document had
#: not stated. The interpolation was honest about being one; what nobody had
#: was a reason to look again, because the file it would have looked in was
#: extracted from v3.0 too.
LIBRARY_PAGES = {1: 3, 2: 5, 3: 6, 4: 8, 5: 9,
                 6: 11, 7: 13, 8: 14, 9: 16, 10: 18}
LIBRARY_UNLOCK_KEEPER = 4

#: §7.6 and §14.4, the three-rank page costs still in the document (C23).
PAGES_BY_RANK = {"Common": 15, "Rare": 30, "Deep": 60}
#: §7.9's four-rank table, which the re-tagged law sheets now imply.
PAGES_BY_RANK_V3 = {"Common": 10, "Uncommon": 20, "Rare": 35, "Deep": 60}

# --------------------------------------------------------------------------
# Rest, and the one recurring price in §9.5
# --------------------------------------------------------------------------
#
# §11.6: "After a heist: 45 minutes after a clean escape, 60 after a loud one,
# 180 if caught. Hearths shorten rest 5% per level. Waking early costs 2 Essence
# per level per minute left." That last clause is the only price in the whole
# document that a player pays again every time they play, which is what makes it
# the one candidate for a recurring Essence sink.
REST_MINUTES = {"clean": 45, "loud": 60, "caught": 180}
HEARTH_REST_CUT_PER_LEVEL = 0.05
WAKE_ESSENCE_PER_LEVEL_MINUTE = 2

#: The proposal in docs/design/spec/sinks.md: upkeep as a share of the player's
#: own hourly Aether production, per point of stability held, so the price sits
#: on the same curve as the faucet that pays it.
UPKEEP_PEGGED_SHARE_PER_POINT = 0.0005


# --------------------------------------------------------------------------
# v3.4, read from content/ rather than transcribed (Config.document)
# --------------------------------------------------------------------------
#
# Everything above was transcribed from v2.3 and is kept, because the findings
# measured on it reproduce there. The document's own run reads the ladders from
# content/buildings.json, which check_all re-extracts from §10.2, so the model
# cannot fall behind the text the way this file did: the Aether Spring stopped
# at level 5 in v3.3 and the transcription still sold it ten.

_PLACEMENT = {"Heart": "heart", "Every realm": "every", "Outer realms": "outer",
              "One per law slot": "every"}


def _needs(text: str) -> tuple[int, int]:
    """(Spire, Keeper) from a §10.2 "Needs" cell."""
    spire = re.search(r"Spire (\d+)", text)
    keeper = re.search(r"Keeper level (\d+)", text)
    return (int(spire[1]) if spire else 0, int(keeper[1]) if keeper else 0)


def buildings_v34() -> dict[str, Building]:
    rows = json.loads((_ROOT / "content" / "buildings.json").read_text(encoding="utf-8"))
    out: dict[str, Building] = {}
    for b in rows:
        if b["name"] == "Keeper's Spire":
            continue
        levels = b["levels"]
        needs = [_needs(lv["needs"]) for lv in levels]
        made = [re.match(r"([\d,]+) (Starlight|Aether|Essence) an hour; (\d+) worker slot",
                         lv["gives"]) for lv in levels]
        placement = next(v for k, v in _PLACEMENT.items() if b["placement"].startswith(k))
        held = [re.match(r"([\d,]+) Starlight and Essence each", lv["gives"]) for lv in levels]
        out[b["name"]] = Building(
            b["name"], tuple(lv["cost_starlight"] for lv in levels),
            tuple(n[0] for n in needs), placement,
            hourly=tuple(int(m[1].replace(",", "")) for m in made) if all(made) else (),
            slots=tuple(int(m[3]) for m in made) if all(made) else (),
            resource=made[0][2].lower() if all(made) else "",
            keeper_required=tuple(n[1] for n in needs),
            holds=tuple(int(m[1].replace(",", "")) for m in held) if all(held) else ())
    return out


def _constant(name: str) -> str:
    table = json.loads((_ROOT / "content" / "upstream" / "constants.json")
                       .read_text(encoding="utf-8"))
    return table[name]["value"]


try:
    from ..design_facts import STARTING_HEART
except ImportError:
    from design_facts import STARTING_HEART
#: The Heart's starting buildings by §10.2's names, the Spire aside: the model
#: holds the Spire's level apart from the realms' buildings.
STARTING_NAMES = tuple(
    b["name"] for i in STARTING_HEART if i != "keeper_s_spire"
    for b in json.loads((_ROOT / "content" / "buildings.json").read_text(encoding="utf-8"))
    if b["id"] == i)

#: §5.2 and §10.2: wards and guard posts by realm level. The Heart has no
#: realm level of its own; the owner decided it counts as level 3 (G19).
WARDS_BY_REALM_LEVEL = (8, 8, 6, 7, 8)
try:
    from ..design_facts import GUARD_POSTS, ROSTER_KEEP_SHARE
except ImportError:
    from design_facts import GUARD_POSTS, ROSTER_KEEP_SHARE      # 5.2, 9.5 (D37)

#: §10.2's Hearth: "characters up to level 2" at level 1, rising two a level.
HEARTH_CHARACTER_CAP = (2, 4, 6, 8, 10)

#: §9.5: "100 × 1.3455^ruleborn owned Essence, where owned is n − 1 for the nth
#: birth" (v3.7, F38 B: strays join at the birth price, which sets the rate),
#: read from §31.3's constants. The name keeps the version it was first read in.
BIRTH_GROWTH_V34 = float(_constant("birth_rate"))
#: §11.5: a new universe starts with five, and houses at most 38.
STARTING_ROSTER = 5
ROSTER_CEILING = 38

#: §32.9 derives the birth curve from "raid Essence at base 2,400 (half of each
#: haul)"; the server mints the same split (G17).
HAUL_ESSENCE_SHARE = 0.5

#: §7.6's page sources, per heist and per day.
PAGES_STUDY = 2               # "receives 2 of its pages, 3 if the heist was clean"
PAGES_STUDY_CLEAN_BONUS = 1
#: §9.6's split of a successful heist: 35% clean, 40% loud, 25% partial.
CLEAN_SHARE_OF_SUCCESSES = 0.35
#: The owner's answer to C41: the fee comes back in full after a clean or a
#: loud heist and half after a partial one — of the successes split 35% clean,
#: 40% loud and 25% partial (§9.6's split, above), 0.35 + 0.40 + 0.25 / 2.
FEE_RETURNED_SHARE_OF_SUCCESSES = 0.35 + 0.40 + 0.25 / 2
#: §9.4 as the document still reads it, for F39's finding only (the build
#: follows the owner's answer): "2% of the raider's Starlight, from 100 to
#: 25,000, returned in full after a clean heist".
DOCUMENT_FEE_RANGE = (100, 25_000)

#: Free characters. §11.5: "About one heist in eight finds a stray in the
#: target universe; carrying it out adds it to the roster" — so one in eight
#: of the heists that succeed. §14.6 puts it as "a one-in-eight chance of a
#: stray or a bonus page" (C42). §18.2: the season track's free tier "gives
#: pages, Essence and a stray", once a season: "A season lasts eight weeks"
#: (§18.2).
HEIST_STRAY_CHANCE = 1 / 8
SEASON_DAYS = 56

#: The school each resource belongs to (§5.2's boosted resources), for §9.3's
#: "matching school" bonuses.
RESOURCES = ("starlight", "aether", "essence")
PAGES_PYLON = 1               # "Breaking a pylon gives a page"; the model breaks one a success
PAGES_FOILED = 1              # "a foiled heist gives one"
PAGES_DAILY_GOALS = 2         # §14.4: "About 2"

#: The owner's answer to F37: §16's tutorial ruins, two on day 1, pay a
#: successful heist's experience, and pay no haul.
TUTORIAL_RUINS = 2

#: The season track's free rewards (G28, answered), as server/src/track.mjs
#: gives them: 50 tiers, the first free to everyone and each after it 10
#: stars; a stray offer at the top, 5 pages every other fifth tier, and 500
#: Essence on the rest — the tenth tiers too, since F41's answer left no
#: Starglass (44 tiers of Essence, 5 of pages).
#: An attempt earns 4.97 stars at §9.6's 62.5% success and 35/40/25 split.
TRACK_TIERS = 50
TIER_STARS = 10
STARS_PER_ATTEMPT = 4.97
TRACK_TIER_ESSENCE = 500
TRACK_TIER_PAGES = 5


def free_track(tiers: int) -> tuple[int, int]:
    """The free track's Essence and pages over its first `tiers` tiers."""
    essence = pages = 0
    for t in range(1, min(tiers, TRACK_TIERS) + 1):
        if t == TRACK_TIERS:
            continue
        if t % 5 == 0 and t % 10:
            pages += TRACK_TIER_PAGES
        else:
            essence += TRACK_TIER_ESSENCE
    return essence, pages


FREE_TRACK_ESSENCE, FREE_TRACK_PAGES = free_track(TRACK_TIERS)

#: §7.6's chapters: the Keeper level at which the Codex holds each count of
#: laws. The launch Codex is the first two; the full 48 all five.
CODEX_CHAPTERS = ((1, 12), (6, 24), (12, 36), (18, 42), (24, 48))
try:
    from ..design_facts import STARTING_LAWS as _STARTING        # §7.6, its one home
except ImportError:
    from design_facts import STARTING_LAWS as _STARTING
#: §7.6: "Half gravity, Slow rivers and Bloom", three commons — how many.
STARTING_LAW_COUNT = len(_STARTING)


def codex(launch_only: bool) -> list[int]:
    """Page costs of every law, in the order the Codex opens them (7.6): the
    launch 24 are chapters 1 and 2, the other 24 chapters 3 to 5, and each
    part cheapest first. From content/laws.json's ranks and launch flags."""
    laws = json.loads((_ROOT / "content" / "laws.json").read_text(encoding="utf-8"))
    laws = laws["laws"] if isinstance(laws, dict) else laws
    launch = sorted(PAGES_BY_RANK_V3[law["rank"]] for law in laws if law.get("launch"))
    later = sorted(PAGES_BY_RANK_V3[law["rank"]] for law in laws if not law.get("launch"))
    return launch if launch_only else launch + later


#: §9.3 as v3.3 re-ran it under §5.8's rules: Starlight, Aether and Essence a
#: day for an engaged player. The v2.3 table above is the one the findings
#: were measured against.
PUBLISHED_DAILY_PRODUCTION_V34 = {
    2: (2_100, 800, 500),
    8: (6_200, 4_600, 3_100),
    31: (14_600, 11_000, 7_400),
    91: (46_800, 35_100, 23_400),
    181: (62_600, 47_000, 31_300),
    301: (122_500, 91_900, 59_900),
}
