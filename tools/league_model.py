#!/usr/bin/env python3
"""Where the league boundaries fall: §12.9's Renown, played forward.

    python3 tools/league_model.py              # the report
    python3 tools/league_model.py --json       # the boundaries, for the server
    python3 tools/league_model.py --check server/src/leagues.json

Why this exists
---------------
§18.1: "Renown places players in six leagues: Dust, Ember, Tide, Star, Nova and
Paradox, each with three divisions except Paradox. Nobody can drop out of Dust
or Ember, so new players only climb. At the end of a season … Renown is pulled
halfway back toward the floor of the player's league." §14.7 gives "design
targets for the Renown formula": when an engaged player arrives in each
league, and each league's share of active players at season end. Nowhere does
the document say how much Renown a league starts at, and the server cannot
place anyone without it.

And the formula has a property the targets do not mention. §12.9: "The
defender gains or loses the mirror amount." Renown moves; it is not made. A
raid adds to the raider exactly what it takes from the defender, and a foiled
one the reverse. So the only Renown that enters the game comes from the
floors: a defender at Dust's floor, or at Ember's once reached, cannot lose,
and the raider's gain is minted. Everything the leagues are built on is that
leak.

This plays the rules forward on a population and fits the boundaries to
§14.7's shares, then reports what the fit does to §14.7's other target, the
arrival times. What it assumes that the document does not state is listed in
`ASSUMED` and printed with the report.
"""

import bisect
import json
import pathlib
import random
import sys

sys.path.insert(0, str(pathlib.Path(__file__).resolve().parent))
from design_facts import (LEAGUE_DIVISIONS, LEAGUE_SHARES, LEAGUES, MATCH_WINDOW, RENOWN_CLEAN,  # noqa: E402
                          RENOWN_FOILED, RENOWN_OUTCOME, SEASON_WEEKS)

SEASON_DAYS = SEASON_WEEKS * 7

#: §14.1's three kinds of player: heists a day.
HEISTS_A_DAY = {"engaged": 4, "regular": 2, "casual": 1}

#: What the model needs that the document does not give. Each is printed with
#: the report, and the sensitivity section varies the ones that matter.
ASSUMED = {
    # §14.1 names three kinds of player and not how many of each.
    "mix": {"engaged": 0.2, "regular": 0.4, "casual": 0.4},
    # §14.5: "about 80% at first, 60% after a month" — read as success
    # falling linearly from 80% to 60% over a player's first 30 days.
    "success": (0.8, 0.6, 30),
    # A successful heist's grade: §12.9 has three and nothing says how often
    # each comes. Clean most, loud next, partial least.
    "grades": {"clean": 0.6, "loud": 0.25, "partial": 0.15},
    # A population that grows: players join evenly over the first three
    # seasons, and the fourth season's end is the one measured.
    "players": 1500,
    "seasons": 4,
    # §12.22 draws targets "within 150 Renown"; with none there, the
    # nearest. A target is any other player's island.
    "renown_window": MATCH_WINDOW[0],
}

#: §14.7's arrival targets for an engaged player, as days: "In the first
#: week", "By week 3", "Around month 2", "Month 3 onward" (for strong players).
ARRIVAL = {"Ember": 7, "Tide": 21, "Star": 60, "Nova": 90}


def clean_renown(raider: float, defender: float) -> float:
    base, scale, low, high = RENOWN_CLEAN
    return min(high, max(low, base * (1 + (defender - raider) / scale)))


class Player:
    __slots__ = ("kind", "joined", "renown", "ember", "arrived")

    def __init__(self, kind: str, joined: int):
        self.kind, self.joined = kind, joined
        self.renown = 0.0
        self.ember = False          # reached Ember: may not drop back to Dust
        self.arrived: dict[str, int] = {}


def league_of(renown: float, bounds: list[float]) -> int:
    """The league a Renown is in: the last boundary at or below it."""
    return bisect.bisect_right(bounds, renown) - 1


def floor(p: Player, bounds: list[float]) -> float:
    """§18.1: nobody drops out of Dust or Ember, so Dust's floor always holds
    and Ember's does once reached. From Tide up, a player can fall."""
    return bounds[1] if p.ember else bounds[0]


def season(players: list[Player], bounds: list[float], start: int, rng: random.Random,
           assumed: dict) -> None:
    grades = list(assumed["grades"])
    weights = list(assumed["grades"].values())
    hi, lo, span = assumed["success"]
    window = assumed["renown_window"]
    for day in range(start, start + SEASON_DAYS):
        live = [p for p in players if p.joined <= day]
        if len(live) < 2:
            continue
        order = sorted(live, key=lambda p: p.renown)
        keys = [p.renown for p in order]
        raids = [p for p in live for _ in range(HEISTS_A_DAY[p.kind])]
        rng.shuffle(raids)
        for raider in raids:
            # A target within the window, the nearest by Renown if none.
            # Chosen by index from the day's sorted snapshot, so a crowded
            # floor costs nothing to draw from.
            a = bisect.bisect_left(keys, raider.renown - window)
            b = bisect.bisect_right(keys, raider.renown + window)
            if b - a < 2:
                # The nearest two, which always holds someone else.
                i = bisect.bisect_left(keys, raider.renown)
                a = max(0, min(i - 1, len(order) - 2))
                b = a + 2
            target = raider
            while target is raider:
                target = order[rng.randrange(a, b)]
            age = day - raider.joined
            p_win = hi - (hi - lo) * min(age, span) / span
            if rng.random() < p_win:
                grade = rng.choices(grades, weights)[0]
                amount = clean_renown(raider.renown, target.renown) * RENOWN_OUTCOME[grade]
                raider.renown += amount
                target.renown = max(floor(target, bounds), target.renown - amount)
            else:
                raider.renown = max(floor(raider, bounds), raider.renown - RENOWN_FOILED)
                target.renown += RENOWN_FOILED
            for p in (raider, target):
                if p.renown >= bounds[1]:
                    p.ember = True
        for p in live:
            for i, name in enumerate(LEAGUES):
                if i and name not in p.arrived and p.renown >= bounds[i]:
                    p.arrived[name] = day - p.joined


def pull_back(players: list[Player], bounds: list[float]) -> None:
    """§18.1: "Renown is pulled halfway back toward the floor of the player's
    league" — each league's own lower boundary."""
    for p in players:
        f = bounds[league_of(p.renown, bounds)]
        p.renown = f + (p.renown - f) / 2


def run(bounds: list[float], assumed: dict, seed: int = 1):
    rng = random.Random(seed)
    kinds = list(assumed["mix"])
    n = assumed["players"]
    join_span = SEASON_DAYS * (assumed["seasons"] - 1)
    players = [Player(rng.choices(kinds, list(assumed["mix"].values()))[0],
                      int(i * join_span / n)) for i in range(n)]
    end = None
    for s in range(assumed["seasons"]):
        season(players, bounds, s * SEASON_DAYS, rng, assumed)
        if s == assumed["seasons"] - 1:
            end = [p.renown for p in players]
        pull_back(players, bounds)
    return players, end


def shares(end: list[float], bounds: list[float]) -> dict[str, float]:
    counts = [0] * len(LEAGUES)
    for r in end:
        counts[league_of(r, bounds)] += 1
    return {name: 100 * c / len(end) for name, c in zip(LEAGUES, counts)}


def fit(assumed: dict, ember: float, rounds: int = 8):
    """The four boundaries above Ember whose season-end shares are §14.7's,
    found by fixed point: play a population under a guess, move each boundary
    to the quantile the shares ask for, and play again.

    Ember's own boundary is not fitted, because the shares cannot fix it.
    Once reached, Ember is a floor (§18.1), so players pile up on it and
    almost nobody is left in Dust at season end whatever the boundary is: a
    first version that fitted all five returned 12, 56 or 100 depending only
    on where it started. It is set from §14.7's other target instead
    (`calibrate`)."""
    target = [LEAGUE_SHARES[n] for n in LEAGUES[2:]]
    above = [sum(target[i:]) for i in range(len(target))]      # share at or above each
    bounds = [0.0, float(ember)] + [ember * k for k in (2, 5, 10, 20)]
    for _ in range(rounds):
        _, end = run(bounds, assumed)
        ranked = sorted(end)
        new = [0.0, float(ember)] + [
            ranked[min(len(ranked) - 1, int(len(ranked) * (1 - a / 100)))] for a in above]
        # Boundaries rise with the league, and each is a whole number.
        for i in range(2, len(new)):
            new[i] = max(round(new[i]), new[i - 1] + 1)
        if new == bounds:
            break
        bounds = new
    return bounds


#: Dust's share at season end: the part of the population §14.7's five shares
#: leave (100 − 30 − 30 − 25 − 10 − 1).
DUST_SHARE = 100 - sum(LEAGUE_SHARES.values())


def calibrate(assumed: dict):
    """Ember's boundary, from the one share §14.7 leaves implicit: the highest
    boundary at which Dust still holds its residual share at season end, by
    bisection on whole points; the leagues above it then fitted to theirs.

    Setting it from the other target — an engaged player in Ember "in the
    first week" — was tried first and cannot hold with the shares: at the
    boundary that takes seven days, half the population is still in Dust at
    season end and Ember holds 2% (F40)."""
    lo, hi = 1, 1000
    while hi - lo > 4:
        mid = (lo + hi) // 2
        bounds = fit(assumed, mid, rounds=5)
        _, end = run(bounds, assumed)
        if shares(end, bounds)["Dust"] <= DUST_SHARE:
            lo = mid
        else:
            hi = mid
    return fit(assumed, lo)


def divisions(bounds: list[float]) -> dict[str, list[int]]:
    """§18.1's three divisions, as thirds of each league's span; Paradox has
    none. Nova's span ends at Paradox."""
    out = {}
    for i, name in enumerate(LEAGUES[:-1]):
        lo, hi = bounds[i], bounds[i + 1]
        out[name] = [round(lo + (hi - lo) * k / LEAGUE_DIVISIONS) for k in range(LEAGUE_DIVISIONS)]
    return out


def arrivals(players: list[Player], kind: str) -> dict[str, float | None]:
    """The median day a player of `kind` who joined in the last season but one
    reaches each league — late enough that the leagues are full around it."""
    cohort = [p for p in players if p.kind == kind
              and SEASON_DAYS * (ASSUMED["seasons"] - 3) <= p.joined]
    out = {}
    for name in LEAGUES[1:]:
        days = sorted(p.arrived[name] for p in cohort if name in p.arrived)
        # Half the cohort must arrive for there to be a median arrival.
        out[name] = days[len(cohort) // 2] if len(days) > len(cohort) // 2 else None
    return out


def minted(assumed: dict, bounds: list[float]) -> float:
    """Renown in the population at the measured season's end: all of it was
    minted by the floors, since every raid only moves it."""
    _, end = run(bounds, assumed)
    return sum(end)


def report() -> str:
    bounds = calibrate(ASSUMED)
    players, end = run(bounds, ASSUMED)
    got = shares(end, bounds)
    out = ["League boundaries: §12.9's Renown played forward, fitted to §14.7", ""]
    out.append("  Renown is zero-sum between raider and defender (§12.9's mirror), so")
    out.append("  every point in the game was minted by a floor: a defender at Dust's")
    out.append("  or Ember's floor cannot lose, and the raider's gain is new.")
    out.append(f"  At the measured season's end the population holds {sum(end):,.0f} Renown,")
    out.append(f"  {sum(end) / len(end):,.0f} a player, all of it from the floors.")
    out.append("")
    out.append(f"  {'league':<9}{'from':>7}   {'share at season end':<22}{'§14.7':>6}")
    for i, name in enumerate(LEAGUES):
        want = LEAGUE_SHARES.get(name)
        out.append(f"  {name:<9}{bounds[i]:>7,.0f}   {got[name]:>5.1f}%{'':<15}"
                   f"{(str(want) + '%') if want else '—':>6}")
    out.append("")
    out.append("  When an engaged player arrives (median days after joining):")
    arr = arrivals(players, "engaged")
    for name, want in ARRIVAL.items():
        a = arr[name]
        out.append(f"    {name:<8} {('day ' + str(a)) if a is not None else 'not within the run':<20}"
                   f"§14.7: by day {want}")
    out.append("")
    out.append("  Divisions, as thirds of each league (§18.1):")
    for name, cuts in divisions(bounds).items():
        out.append(f"    {name:<8} {', '.join(f'{c:,}' for c in cuts)}")
    out.append("")
    out.append("  Assumed, since the document does not say:")
    for k, v in ASSUMED.items():
        out.append(f"    {k}: {v}")
    out.append("")
    out.append("  Sensitivity: the boundaries refitted with one assumption changed.")
    for label, change in [
        ("more engaged players (40/40/20)", {"mix": {"engaged": 0.4, "regular": 0.4, "casual": 0.2}}),
        ("success stays at 80%", {"success": (0.8, 0.8, 30)}),
        ("every success clean", {"grades": {"clean": 1.0, "loud": 0.0, "partial": 0.0}}),
    ]:
        b = calibrate({**ASSUMED, **change})
        out.append(f"    {label:<34} " + ", ".join(f"{n} {v:,.0f}" for n, v in zip(LEAGUES[1:], b[1:])))
    return "\n".join(out)


def boundaries() -> dict:
    bounds = calibrate(ASSUMED)
    return {"_what": "Generated by tools/league_model.py: §18.1's leagues, their lower "
                     "Renown boundaries fitted to §14.7's season-end shares (G27). "
                     "Never edited by hand.",
            "leagues": dict(zip(LEAGUES, [int(b) for b in bounds])),
            "divisions": divisions(bounds)}


def main() -> int:
    if "--json" in sys.argv:
        sys.stdout.write(json.dumps(boundaries(), indent=1) + "\n")
        return 0
    if "--check" in sys.argv:
        path = pathlib.Path(sys.argv[sys.argv.index("--check") + 1])
        if path.read_text(encoding="utf-8") != json.dumps(boundaries(), indent=1) + "\n":
            print(f"{path} has drifted from tools/league_model.py; regenerate it with "
                  f"python3 tools/league_model.py --json > {path}")
            return 1
        print(f"{path} matches tools/league_model.py")
        return 0
    print(report())
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
