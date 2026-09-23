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
              "of the crew's bags loaded, which the harness measures at about 40%",
              "for a crew playing to §12.19's own break-even — and 89% for one",
              "playing to 95%, a spread §9.6 has no term for at all:", ""]
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
    per_attempt = data.HAUL_VALUE_PER_ATTEMPT * data.MEASURED_FILL_ON_SUCCESS
    best = data.HAUL_VALUE_PER_ATTEMPT * data.MEASURED_FILL_OPTIMAL
    lines += ["", "  §9.6's own worked example, \"an upgrade costing 25 clean raids takes",
              f"  about 55 attempts\", becomes {25 / per_attempt:.0f} — or "
              f"{25 / best:.0f} for a crew that plays to 95%.",
              "",
              "  That spread is the finding behind the finding. §9.6's formula has a",
              "  grade multiplier and no fill-skill term, so the number it calls \"the",
              f"  number the progression curve is built on\" varies "
              f"{data.MEASURED_FILL_OPTIMAL / data.MEASURED_FILL_ON_SUCCESS:.1f}x with how",
              "  well the same player plays the same island."]
    return "\n".join(lines)


def raid_worth(days: int = 1000) -> str:
    """§9.6's raid-worth check on the model's own roster, and the base it sets."""
    from . import raidworth as rw

    cfg = Config.document()
    lines = ["§9.6's raid-worth check, run with the roster the model staffs", "",
             f"  B(V) = {cfg.haul_base:,} × {data.HAUL_GROWTH}^(V−1); an attempt at the "
             f"band's lower edge ({data.ATTEMPT_BAND[0]}) with fatigue averaged over "
             f"{rw.HEISTS} heists", f"  against the crew's output over "
             f"{rw.HOURS_AWAY:g} hours (3 minutes away, 45 resting), all three "
             "currencies.", ""]
    lines.append(f"  {'Vault':>5} {'days at it':>11} {'crew':>5} {'a worker/h':>11} "
                 f"{'stay home':>10} {'an attempt':>11} {'on arrival':>11} {'worst day':>15}")
    for r in rw.levels(cfg, days):
        lines.append(f"  {r.vault:>5} {f'{r.first_day}–{r.last_day}':>11} {r.crew:>5} "
                     f"{r.per_worker_hour:>11,.0f} {r.stay_home:>10,.0f} {r.attempt:>11,.0f} "
                     f"{r.ratio_first:>10.2f}× {r.ratio:>7.2f}× day {r.binding_day:<4}")
    first = rw.smallest_passing_base(cfg, days, first_day_only=True)
    every = rw.smallest_passing_base(cfg, days)
    lines += ["",
              f"  Smallest hundred that passes, on the day each level arrives "
              f"(§9.6's reading, §10.2's build days): {first:,}",
              f"  Smallest hundred that passes on every day at every level:"
              f"                    {every:,}",
              f"  The document ships {data.HAUL_BASE:,}. §32.9: \"if an attempt fails at "
              "any level, the base", "  rises until it passes, and the pacing is recomputed.\""]
    # What §12.22's spread would move, were the model to carry a population.
    low, same, up = data.DIFFICULTY[2], data.DIFFICULTY[0], (data.DIFFICULTY[0]
                                                             + data.DIFFICULTY[1]) / 2
    spread = (low / data.HAUL_GROWTH + same + up * data.HAUL_GROWTH) / 3
    lines += ["", "  The target is §12.22's median offer, at the raider's own Vault level. "
              "A target drawn", "  evenly from one Vault level below, level and one above "
              f"(difficulty {low}, {same}, {up:.1f})", f"  would pay {spread:.3f}× that — "
              "so the median is the conservative reading."]
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
    the model, so the result cannot be an artefact of how the model reads §5.8.
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


def sink_scaling() -> str:
    """Why Aether and Essence have no sinks, stated as one number each.

    `sink_audit` above totals the prices and finds them small. That is the
    symptom. This is the cause, and it is arithmetic rather than judgement: a
    faucet that multiplies by 240 across the curve and a price that multiplies by
    10 are not a balance problem, they are two things on different curves.
    """
    from . import sinks

    lines = ["Do §9.5's prices travel with §9.3's production?", ""]
    lines.append("Between day 2 and day 301 the three faucets multiply by:")
    lines.append("  Starlight ×122     Aether ×240     Essence ×251")
    lines.append("")
    lines.append(f"  {'':<9} {'price':<42} {'start':>9} {'end':>11} {'travel':>8}")
    rows = sinks.price_growth()
    for currency, label, first, last, mult in rows:
        lines.append(f"  {currency:<9} {label:<42} {first:>9,.0f} {last:>11,.0f} "
                     f"{'×' + format(mult, ',.0f'):>8}")
    lines.append("")

    income = {"Starlight": 122, "Aether": 240, "Essence": 251}
    lines.append("  The biggest sink in each currency, against that currency's faucet:")
    for currency in ("Starlight", "Aether", "Essence"):
        best = max(m for c, _, _, _, m in rows if c == currency)
        ratio = best / income[currency]
        verdict = (f"outruns its faucet {ratio:.0f}×" if ratio >= 1
                   else f"falls behind its faucet {1 / ratio:.0f}×")
        lines.append(f"    {currency:<10} biggest price travels ×{best:<6,.0f} "
                     f"faucet ×{income[currency]:<4}  {verdict}")
    lines.append("")
    # The same comparison over a whole account, which is the honest one: a
    # faucet runs every day and most of §9.5's prices are paid once.
    from .config import Config
    from .model import EconomyModel
    state = EconomyModel(Config(archetype="engaged", days=301)).run()
    lines.append("  Over a whole account to day 301, faucet against every price there is:")
    for currency, (produced, priced, ratio) in sinks.lifetime_absorption(state).items():
        lines.append(f"    {currency:<10} produced {produced:>12,.0f}   "
                     f"every sink, ever {priced:>11,.0f}   faucet is {ratio:>4.0f}× the sink")
    lines.append("")
    lines.append("  That is the whole finding. Starlight is permanently scarce because")
    lines.append("  §10.2's building curve is geometric and never ends. Nothing points a")
    lines.append("  geometric curve at Aether or Essence, so both drown.")
    lines.append("")

    # The one recurring price, and why it is never charged.
    lines.append("§9.5's one recurring price, and why nobody ever pays it")
    lines.append("")
    lines.append("  §11.6 rests a crew for 45 minutes after a clean escape and §9.5 charges")
    lines.append("  2 Essence a level a minute to wake them early. It is the only price in")
    lines.append("  the document a player pays again every session — and it only falls due")
    lines.append("  when there is nobody rested left to send:")
    lines.append("")
    lines.append(f"    {'roster':>7} {'crews in one rest window':>26} {'heists a day before a wake':>28}")
    for roster in (5, 10, 20, 38):
        rate = sinks.heists_before_waking(roster, 5)
        lines.append(f"    {roster:>7} {roster // 5:>26} {rate * 16:>28,.0f}")
    lines.append("")
    lines.append("  An engaged player raids four times a day (§14.2's archetypes). At the")
    lines.append("  roster cap the price falls due at 199 a day, so it is charged at 2% of")
    lines.append("  the rate it would need for anyone to meet it. Waking is not a sink that")
    lines.append("  is too cheap; it is a sink the roster cap makes unreachable.")
    lines.append("")

    # The proposal.
    lines.append("The proposal in spec/sinks.md: price upkeep off the faucet that pays it")
    lines.append("")
    lines.append(f"  {'day':>5} {'Aether a day':>13} {'points':>7} "
                 f"{'flat, §9.5':>18} {'pegged':>18}")
    for day, points in ((2, 40), (31, 113), (91, 285), (181, 446), (301, 516)):
        aether = data.PUBLISHED_DAILY_PRODUCTION[day][1]
        flat = data.UPKEEP_AETHER_PER_POINT_HOUR * points * 24
        peg = sinks.pegged_upkeep_per_hour(aether, points) * 24
        lines.append(f"  {day:>5} {aether:>13,} {points:>7} "
                     f"{flat:>10,.0f} ({100 * flat / aether:>4.1f}%) "
                     f"{peg:>10,.0f} ({100 * peg / aether:>4.1f}%)")
    lines.append("")
    lines.append("  §9.5's flat 0.5 an hour a point is 60% of a day's Aether on day 2 and")
    lines.append("  3.2% on day 301. It is not mispriced; it is one number doing two")
    lines.append("  different jobs, because production moved 240× underneath it. The")
    lines.append("  pegged rate rises with the sheet instead of with the calendar, which")
    lines.append("  is what makes weaving a fuller sheet a decision.")
    lines.append("")

    # And the part the peg cannot fix.
    absorbed = sinks.lifetime_absorption(state)
    lines.append("What the peg does not fix: the faucet is the other half")
    lines.append("")
    lines.append("  Pegging upkeep raises the share of a lifetime's Aether the document has")
    lines.append("  a price for from about an eighth to about a fifth. It cannot do more:")
    lines.append("  a sheet grows ×10 across the curve and Aether grows ×240, so even")
    lines.append("  charging a full sheet's worth of income leaves most of the faucet")
    lines.append("  unspent. Which level of each producer already covers every price there is:")
    lines.append("")
    for building, index, currency in (("Aether Spring", 1, "Aether"),
                                      ("Garden", 2, "Essence")):
        priced = absorbed[currency][1]
        rows = sinks.absorption_ladder(state, building, index, priced)
        enough = next((r for r in rows if r["covers"] >= 1), rows[-1])
        lines.append(f"    {building:<14} level {enough['level']:>2} already produces "
                     f"{enough['covers']:.1f}× every {currency} price in the document.")
        lines.append(f"    {'':<14} §10.2 sells {10 - enough['level']} more levels above it, "
                     f"up to {rows[-1]['covers']:.0f}×.")
    lines.append("")
    lines.append("  So the recommendation is the one §9.5's prices cannot reach on their")
    lines.append("  own: cut the faucets. That is cheap to do — it deletes a Starlight")
    lines.append("  sink, and Starlight is the one currency whose sink already outruns it.")
    return "\n".join(lines)
