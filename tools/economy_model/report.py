"""Reports that compare the model against the design document's published tables."""

from . import data
from .config import Config
from .model import EconomyModel


def _run(**kwargs) -> tuple[EconomyModel, dict[int, dict]]:
    model = EconomyModel(Config(**kwargs))
    state = model.run()
    return model, {row["day"]: row for row in state.log}


def production_vs_published(days: int = 320) -> str:
    """§9.3's daily production against four readings of the build rules."""
    variants = {
        "2/realm, roster cap": dict(days=days),
        "2/realm, no cap": dict(days=days, enforce_worker_cap=False),
        "1/realm, roster cap": dict(days=days, producers_per_realm_override=1),
        "1/realm, no cap": dict(days=days, enforce_worker_cap=False,
                                producers_per_realm_override=1),
    }
    runs = {name: _run(archetype="engaged", **kw) for name, kw in variants.items()}

    lines = ["Starlight per day, as a percentage of §9.3's published figure", ""]
    lines.append(f"{'day':>4} {'published':>10}" + "".join(f"{n:>22}" for n in variants))
    for day, (starlight, _, _) in data.PUBLISHED_DAILY_PRODUCTION.items():
        row = f"{day:>4} {starlight:>10,}"
        for name in variants:
            entry = runs[name][1].get(day)
            row += (f"{100 * entry['starlight_per_day'] / starlight:>21.0f}%"
                    if entry else f"{'-':>22}")
        lines.append(row)

    lines += ["", "Keeper level 40 reached on day (published: 181)"]
    for name in variants:
        reached = runs[name][0].s.keeper_level_days.get(40, "never")
        lines.append(f"  {name:<24} {reached}")
    lines += ["", "Best fit is 1 producer per realm with no binding roster cap —"
                  " neither of which the build rules in §5.2 and §11.5 describe."]
    return "\n".join(lines)


def position_budget() -> str:
    """Whether the roster can staff the universe the build rules permit."""
    realms_outer, realms_all = 6, 7
    slots_per_producer = data.BUILDINGS["Star Well"].slots[-1]
    roster = 3 + realms_all * data.HEARTH_HOMES[-1]
    guard_posts = realms_outer * 3 + 3
    crew = 5

    lines = ["Character positions against the roster ceiling, at a finished universe", ""]
    for label, per_realm in (("§5.2 as written (2 of each from realm level 3)", 2),
                             ("as §9.3's production figures imply (1 of each)", 1)):
        slots = realms_all * per_realm * 3 * slots_per_producer
        total = slots + guard_posts + crew
        lines += [
            f"  {label}",
            f"    producer worker slots  {slots:>4}",
            f"    guard posts            {guard_posts:>4}",
            f"    heist crew             {crew:>4}",
            f"    positions to fill      {total:>4}",
            f"    roster ceiling         {roster:>4}  (3 at the Spire + 7 Hearths x 5 homes)",
            f"    coverage               {100 * roster / total:>3.0f}%"
            f"   — the roster would need to be {total / roster:.1f}x larger",
            "",
        ]
    return "\n".join(lines)


def raiding_trade_off() -> str:
    """How much production raiding actually costs — §11.6's core trade-off."""
    lines = ["What raiding costs in production terms (§11.6)", ""]
    lines.append(f"{'archetype':>10} {'roster':>7} {'crew':>5} {'heists':>7} "
                 f"{'withheld':>9} {'% of roster':>12}")
    for name in ("engaged", "regular", "casual"):
        model, _ = _run(archetype=name, days=181)
        withheld = model.workers_withheld_by_raiding()
        lines.append(
            f"{name:>10} {model.roster_size():>7} {model.crew_size():>5} "
            f"{model.arch.heists_per_day:>7} {withheld:>9.2f} "
            f"{100 * withheld / model.roster_size():>11.1f}%"
        )
    lines += ["", "A heist is 3 minutes plus 45 minutes' rest (§12.6, §11.6), so a crew of",
              "five raiding four times a day is unavailable for 16 character-hours out of",
              "744. The trade-off §11.6 calls the link between the two halves of the game",
              "is worth about 2% of production."]
    return "\n".join(lines)


def faucet_comparison() -> str:
    """§9.4's stated share, §9.6's minted haul, and the peg proposed in spec/economy.md."""
    lines = ["Raid income as a share of total income, by payout model", ""]
    lines.append(f"{'day':>4} {'production/day':>15} "
                 f"{'§9.4 share':>12} {'§9.6 minted':>13} {'pegged':>10}   "
                 f"{'§9.4':>6} {'§9.6':>6} {'peg':>6}")
    runs = {name: _run(archetype="engaged", days=320, faucet=name)[1]
            for name in ("share", "minted", "pegged")}
    for day in (31, 91, 181, 301):
        rows = {name: log.get(day) for name, log in runs.items()}
        if not all(rows.values()):
            continue
        prod = rows["share"]["starlight_per_day"]

        def pct(row):
            return 100 * row["heist_income"] / (row["starlight_per_day"] + row["heist_income"])

        lines.append(
            f"{day:>4} {prod:>15,.0f} "
            f"{rows['share']['heist_income']:>12,.0f} "
            f"{rows['minted']['heist_income']:>13,.0f} "
            f"{rows['pegged']['heist_income']:>10,.0f}   "
            f"{pct(rows['share']):>5.0f}% {pct(rows['minted']):>5.0f}% "
            f"{pct(rows['pegged']):>5.0f}%"
        )
    lines += ["", "§9.4 and §12.1 claim heists supply a third to 40% of a player's resources.",
              "§9.6's formula, which supersedes them, supplies a few per cent and thins as",
              "production compounds. The peg in docs/design/spec/economy.md replaces B(L)",
              "with the raider's own daily production, which holds the share flat by",
              "construction; tools/economy_model/test_economy_model.py asserts that it does."]

    # F14: v3.0 added `fill` to the same formula and left 0.46 alone.
    lines += ["", "What v3.0's `fill` term costs (F14). §9.6 calls 0.46 \"the number the",
              "progression curve is built on\" and then multiplied the haul by the share",
              "of the crew's bags loaded, which the harness measures at about 52%:", ""]
    lines.append(f"  {'day':>4} {'0.46':>12} {'0.46 x fill':>13} {'change':>8}")
    for day in (31, 91, 181, 301):
        pair = []
        for fill in (False, True):
            log = _run(archetype="engaged", days=320, faucet="minted",
                       apply_fill=fill)[1]
            pair.append(log[day]["heist_income"] if day in log else None)
        if all(pair):
            lines.append(f"  {day:>4} {pair[0]:>12,.0f} {pair[1]:>13,.0f} "
                         f"{100 * (pair[1] / pair[0] - 1):>7.0f}%")
    lines += ["", "  §9.6's own worked example, \"an upgrade costing 25 clean raids takes",
              f"  about 55 attempts\", becomes "
              f"{25 / (data.HAUL_VALUE_PER_ATTEMPT * data.MEASURED_FILL_ON_SUCCESS):.0f}."]
    return "\n".join(lines)


def all_reports() -> str:
    return "\n\n".join([
        production_vs_published(),
        position_budget(),
        raiding_trade_off(),
        faucet_comparison(),
        sink_audit(),
    ])


def sink_audit() -> str:
    """What §9.5's prices add up to, against §9.3's own published production.

    Deliberately computed from the document's published figures rather than from
    the model, so the result cannot be an artefact of how the model reads §5.9.
    """
    from . import sinks

    starlight, aether, essence = data.PUBLISHED_DAILY_PRODUCTION[301]
    lines = ["Where does Aether and Essence go? (§9.5 against §9.3)", ""]
    lines.append("§9.3 publishes what an engaged player makes on day 301:")
    lines.append(f"  Starlight {starlight:>9,}   Aether {aether:>9,}   "
                 f"Essence {essence:>9,}   a day")
    lines.append("")
    lines.append("§9.5 prices every sink. Totalled over a whole account:")
    lines.append("")

    births = sum(sinks.birth_cost(n, "geometric") for n in range(5, 38))
    levels = 38 * sum(data.CHARACTER_LEVEL_BASE
                      * data.CHARACTER_LEVEL_GROWTH ** (n - 2)
                      for n in range(2, data.MAX_CHARACTER_LEVEL + 1))
    capacity = data.spire_stability(10) + 7 * data.anchor_stability(10)
    weave = data.WEAVE_AETHER_PER_POINT * capacity
    upkeep_day = data.UPKEEP_AETHER_PER_POINT_HOUR * capacity * 24

    rows = [
        ("Essence", "every birth to the roster cap of 38", births, essence),
        ("Essence", "every one of 38 characters to level 10", levels, essence),
        ("Aether", "weaving a full 516-point sheet, once", weave, aether),
        ("Aether", "upkeep on that sheet, a day", upkeep_day, aether),
        ("Aether", "a Lab experiment at level 3", data.LAB_AETHER_PER_LEVEL * 3, aether),
        ("Aether", "scouting all seven realms of a target", 7 * data.SCOUT_AETHER_PER_REALM,
         aether),
    ]
    lines.append(f"  {'':<8} {'sink':<40} {'cost':>10} {'= days of day-301 income':>26}")
    for currency, label, cost, income in rows:
        days = cost / income
        when = (f"{days:>7.1f} days" if days >= 1
                else f"{days * 24:>7.1f} hours" if days * 24 >= 1
                else f"{days * 24 * 60:>7.0f} minutes")
        lines.append(f"  {currency:<8} {label:<40} {cost:>10,.0f} {when:>26}")

    total_e, total_a = births + levels, weave + upkeep_day * 400
    lines += [
        "",
        f"  Every Essence sink the document prices, added together, is "
        f"{(total_e) / essence:.0f} days",
        f"  of day-301 income. Every Aether sink except upkeep is under three hours.",
        "",
        "  Upkeep is the only recurring sink of any size, and at a full sheet it is "
        f"{100 * upkeep_day / aether:.0f}%",
        "  of a day's Aether. The other 97% has nowhere to go.",
        "",
        f"  §9.1 caps Aether at 5,000 a Spire level plus 3,000 — "
        f"{5000 * 10 + 3000:,} at Spire 10 —",
        f"  against {aether:,} produced a day, so most of it is never banked at all. "
        "Which",
        "  means an Aether Spring above a certain level buys nothing, and §10.2's",
        "  upgrade costs for it are a Starlight sink with no return.",
    ]
    return "\n".join(lines)
