"""Constants transcribed from the Ruleborn design document v2.3.

Everything here is quoted from the document rather than derived, so the model can
be validated against the document's own published tables. Where the document
contradicts itself, both values are recorded and the choice is made in
`config.py`, not here.

Section references are to the design document.
"""

from dataclasses import dataclass, field

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

#: Starlight to open an outer realm, then to raise it to levels 2-5.
REALM_OPEN_COST = 2_000
REALM_LEVEL_COSTS = (6_000, 20_000, 55_000, 140_000)
REALM_LEVEL_SPIRE = (3, 5, 7, 9)

#: Keeper level at which each of the six outer realms becomes available.
REALM_UNLOCK_KEEPER_LEVEL = (3, 6, 10, 15, 21, 28)

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

#: Experience required to advance from level n to n+1, index 0 == level 1.
KEEPER_XP_TO_NEXT = (
    140, 90, 270, 370, 460, 620, 1_050, 1_020, 1_870, 2_230,
    2_450, 1_550, 3_920, 2_330, 3_580, 1_610, 8_700, 5_850, 6_790, 8_100,
    10_520, 13_450, 15_980, 19_480, 19_010, 21_280, 22_980, 26_960, 31_930, 31_830,
    32_990, 39_760, 40_660, 42_860, 49_230, 53_670, 51_850, 56_740, 57_880,
)
KEEPER_LEVEL_CAP = 40

XP_PER_SUCCESSFUL_HEIST = (30, 6)   # 30 + 6 x Keeper level
XP_PER_FOILED_HEIST = (10, 2)       # 10 + 2 x Keeper level
XP_PER_LAW_RESTORED = (60, 10)      # 60 + 10 x Keeper level
STARLIGHT_PER_XP = 40               # 1 XP for every 40 Starlight spent

# --------------------------------------------------------------------------
# Raiding (§9.6 and §9.4)
# --------------------------------------------------------------------------

HAUL_BASE = 100
HAUL_GROWTH = 1.5                   # B(L) = 100 x 1.5^(L-1); the master inflation lever
HAUL_FATIGUE = 0.85                 # per successive raid in a day
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


ENTRY_FEE_RATE = 0.02               # of the raider's Starlight, 100 to 25,000 (§9.4)
ENTRY_FEE_MIN, ENTRY_FEE_MAX = 100, 25_000

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

#: §9.5: scouting is 20 Aether a realm, and §12.3 says a scout lasts 15 minutes.
SCOUT_AETHER_PER_REALM = 20
#: §9.5: a Lab experiment is 400 Aether x Lab level.
LAB_AETHER_PER_LEVEL = 400

#: §10.5, new in v3.0. Only levels 1, 5 and 10 are given — every other building
#: in §10.2 lists all ten — so the missing seven are interpolated on the curve
#: the three stated points imply. That interpolation is C24's cost.
LIBRARY_PAGES = {1: 3, 5: 9, 10: 18}
LIBRARY_UNLOCK_KEEPER = 4

#: §7.6 and §14.4, the three-rank page costs still in the document (C23).
PAGES_BY_RANK = {"Common": 15, "Rare": 30, "Deep": 60}
#: §7.10's four-rank table, which the re-tagged law sheets now imply.
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
