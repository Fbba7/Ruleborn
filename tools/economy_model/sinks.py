"""What Aether and Essence are actually spent on (§9.5), and what that costs.

The model produced all three resources and spent only Starlight, which is why
every law-restoration date it gave was indicative. §9.5 prices every sink, so
they can be modelled rather than assumed — and the two that matter most are the
two the whole design now rests on:

  * **Births.** §5.9 makes the roster the scarcity the design is built on. What a
    character costs is therefore the most load-bearing price in the game, and the
    document gives it twice, differently (C28).
  * **Pages.** v3.0's §10.5 adds the Library as a second faucet, so restoring the
    Codex is no longer a function of raiding alone.

This module reads a finished run's daily log rather than changing the simulation,
because the question is what the player could afford out of what they produced,
not how the answer feeds back. Feedback would change the Starlight curve too, and
that curve is calibrated against the document.
"""

import collections

from . import data


def birth_cost(owned: int, rule: str) -> float:
    """§9.5's geometric price, or §11.5's linear one. See C28."""
    if rule == "linear":
        return data.BIRTH_LINEAR_BASE + data.BIRTH_LINEAR_STEP * owned
    return data.BIRTH_BASE * data.BIRTH_GROWTH ** owned


def library_pages(level: int) -> float:
    """§10.4 gives levels 1, 5 and 10. The rest are on the curve those imply.

    3 -> 9 -> 18 over ten levels is very close to geometric at 1.209 a level, so
    the seven missing rows are interpolated on that. Every other building in
    §10.2 lists every level; this is what C24 costs to work around.
    """
    if level <= 0:
        return 0.0
    known = data.LIBRARY_PAGES
    if level in known:
        return float(known[level])
    growth = (known[10] / known[1]) ** (1 / 9)
    return known[1] * growth ** (level - 1)


def roster_growth(state, rule: str = "geometric", housing_cap: int = 38) -> list:
    """Buy a character whenever the Essence is there and a home is free.

    Returns one row a day: the roster the player could afford, and what it cost.
    Starting roster is five (§11.5) and the cap is §11.5's ceiling.
    """
    owned, banked, rows = 5, 0.0, []
    for row in state.log:
        banked += row["essence_per_day"]
        spent = 0.0
        while owned < housing_cap:
            price = birth_cost(owned, rule)
            if price > banked:
                break
            banked -= price
            spent += price
            owned += 1
        rows.append(dict(day=row["day"], roster=owned, banked=banked,
                         spent=spent, next_price=birth_cost(owned, rule),
                         essence_per_day=row["essence_per_day"]))
    return rows


def page_income(state, library_level_by_day: dict, heists_per_day: int,
                pages_per_heist: float = 1.0) -> list:
    """Pages a day, from raiding and from the Library (§7.6, §10.4).

    §12.1 gives a heist "a page or two"; one is the conservative reading and the
    one that makes the Library's share look largest rather than smallest.
    """
    rows, total = [], 0.0
    for row in state.log:
        library = library_pages(library_level_by_day.get(row["day"], 0))
        raided = heists_per_day * pages_per_heist
        total += library + raided
        rows.append(dict(day=row["day"], library=library, raided=raided,
                         total=total))
    return rows


def codex_cost(rule: str = "three_rank") -> float:
    """What restoring all 48 laws costs in pages, under either rank split.

    §14.4 computes it as "15 commons x 15 + 18 rares x 30 + 12 deep x 60 = 1,485
    pages (the three starting laws are free)". The law sheets have since been
    re-tagged to 18/12/6/12, which §14.4 has not absorbed (C23).
    """
    if rule == "three_rank":
        return 15 * 15 + 18 * 30 + 12 * 60
    # Four ranks, on §14.4's own convention that the three starting laws are free.
    pages = data.PAGES_BY_RANK_V3
    return (15 * pages["Common"] + 12 * pages["Uncommon"]
            + 6 * pages["Rare"] + 12 * pages["Deep"])


def rest_minutes(grade: str, hearth_level: int) -> float:
    """§11.6's rest, after the Hearth's 5% a level."""
    cut = 1 - data.HEARTH_REST_CUT_PER_LEVEL * hearth_level
    return data.REST_MINUTES[grade] * max(0.0, cut)


def wake_cost(character_level: int, minutes_left: float) -> float:
    """§9.5: 2 Essence per character level per minute of rest left."""
    return data.WAKE_ESSENCE_PER_LEVEL_MINUTE * character_level * minutes_left


def heists_before_waking(roster: int, crew: int, grade: str = "clean",
                         hearth_level: int = 5) -> float:
    """How many heists an hour a player can run before rotation runs out.

    This is why waking is not a sink. §9.5 charges to wake a character early, and
    the charge only ever falls due if the player has nobody rested left to send.
    With a roster of `roster` and a crew of `crew`, a player can field
    roster // crew crews inside one rest window and pay nothing.
    """
    rest_hours = rest_minutes(grade, hearth_level) / 60
    return (roster // crew) / rest_hours if rest_hours else float("inf")


def price_growth() -> list:
    """Every §9.5 price, and how far it travels from the start of the game to day 301.

    Income multiplies by 122 (Starlight), 240 (Aether) and 251 (Essence) between
    day 2 and day 301 (§9.3's own table). A price that does not travel with it
    stops being a price. Returns (currency, label, first, last, multiple), where
    a multiple of 1 means the price never moves at all.
    """
    rows = []

    # Starlight: §10.2's building curve, which is the control case.
    well = data.BUILDINGS["Star Well"]
    rows.append(("Starlight", "a Star Well level, 1 to 10",
                 well.costs[0], well.costs[-1], well.costs[-1] / well.costs[0]))
    rows.append(("Starlight", "realm levels 2 to 5", 6_000, 140_000, 140_000 / 6_000))

    # Aether.
    rows.append(("Aether", "weaving, at 40 a point (51 to 516 points)",
                 data.WEAVE_AETHER_PER_POINT * 51, data.WEAVE_AETHER_PER_POINT * 516,
                 516 / 51))
    rows.append(("Aether", "upkeep a day, same sheet",
                 data.UPKEEP_AETHER_PER_POINT_HOUR * 51 * 24,
                 data.UPKEEP_AETHER_PER_POINT_HOUR * 516 * 24, 516 / 51))
    rows.append(("Aether", "a Lab experiment, Lab 1 to 10",
                 data.LAB_AETHER_PER_LEVEL, data.LAB_AETHER_PER_LEVEL * 10, 10.0))
    rows.append(("Aether", "scouting a realm",
                 data.SCOUT_AETHER_PER_REALM, data.SCOUT_AETHER_PER_REALM, 1.0))

    # Essence.
    rows.append(("Essence", "the next birth, 5th to 38th",
                 birth_cost(5, "geometric"), birth_cost(37, "geometric"),
                 birth_cost(37, "geometric") / birth_cost(5, "geometric")))
    rows.append(("Essence", "a character level, 2 to 10",
                 data.CHARACTER_LEVEL_BASE,
                 data.CHARACTER_LEVEL_BASE * data.CHARACTER_LEVEL_GROWTH ** 8,
                 data.CHARACTER_LEVEL_GROWTH ** 8))
    rows.append(("Essence", "waking one character, level 1 to 10",
                 wake_cost(1, 45), wake_cost(10, 45), 10.0))
    return rows


def pegged_upkeep_per_hour(aether_per_day: float, points: int) -> float:
    """spec/sinks.md's proposal: upkeep as a share of the faucet that pays it.

    §9.5 charges a flat 0.5 Aether an hour a point, which is 3% of a day's Aether
    at a full sheet on day 301 and was most of a day's Aether on day 2 — the same
    price doing two different jobs because production moved 240x underneath it.
    Charging a share of production instead holds the ratio flat by construction,
    which is the property the pegged haul in spec/economy.md was adopted for.
    """
    return aether_per_day / 24 * data.UPKEEP_PEGGED_SHARE_PER_POINT * points


def lifetime_absorption(state) -> dict:
    """What share of everything a player produces the document has a price for.

    The per-day comparison in `report.sink_audit` understates the problem,
    because a faucet runs every day and most of §9.5's prices are paid once.
    Totalling both sides over the whole run is the honest comparison, and it is
    the one that shows how far apart they are.

    Returns {currency: (produced, priced, ratio)} where ratio is how many times
    over the faucet fills every sink the document has.
    """
    produced_a = sum(row["aether_per_day"] for row in state.log)
    produced_e = sum(row["essence_per_day"] for row in state.log)
    days = len(state.log)
    capacity = data.spire_stability(10) + 7 * data.anchor_stability(10)

    births = sum(birth_cost(n, "geometric") for n in range(5, 38))
    levels = 38 * sum(data.CHARACTER_LEVEL_BASE
                      * data.CHARACTER_LEVEL_GROWTH ** (n - 2)
                      for n in range(2, data.MAX_CHARACTER_LEVEL + 1))
    weave = data.WEAVE_AETHER_PER_POINT * capacity
    upkeep = data.UPKEEP_AETHER_PER_POINT_HOUR * capacity * 24 * days
    lab = data.LAB_AETHER_PER_LEVEL * 3 * 3 * days

    out = {}
    for name, produced, priced in (("Aether", produced_a, weave + upkeep + lab),
                                   ("Essence", produced_e, births + levels)):
        out[name] = (produced, priced, produced / priced if priced else float("inf"))
    return out


def absorption_ladder(state, building: str, currency_index: int,
                      priced: float) -> list:
    """Which level of a producer's ladder already covers every price there is.

    §10.2 sells ten levels of Aether Spring and ten of Garden. `lifetime_absorption`
    says the top of each ladder produces several times what the document ever
    prices. This finds the level where the ladder stops buying anything, by
    scaling the whole run's production by that level's share of level 10's.

    Approximate by construction — it assumes the shape of the curve rather than
    re-running the model at each level — and it does not need to be exact: the
    question is whether the answer is level 3 or level 9.
    """
    key = ("starlight_per_day", "aether_per_day", "essence_per_day")[currency_index]
    produced = sum(row[key] for row in state.log)
    hourly = data.BUILDINGS[building].hourly
    rows = []
    for level, rate in enumerate(hourly, start=1):
        share = rate / hourly[-1]
        rows.append(dict(level=level, hourly=rate, share=share,
                         lifetime=produced * share,
                         covers=produced * share / priced if priced else 0.0))
    return rows
