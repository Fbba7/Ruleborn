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
    """§10.5 gives levels 1, 5 and 10. The rest are on the curve those imply.

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
    """Pages a day, from raiding and from the Library (§7.6, §10.5).

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
