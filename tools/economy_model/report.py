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
    """§9.4's stated share against §9.6's minted haul."""
    lines = ["Raid income as a share of total income, by payout model", ""]
    lines.append(f"{'day':>4} {'production/day':>15} {'§9.4 share':>12} {'§9.6 minted':>13} "
                 f"{'§9.4 %':>8} {'§9.6 %':>8}")
    share_model, share_log = _run(archetype="engaged", days=320, faucet="share")
    mint_model, mint_log = _run(archetype="engaged", days=320, faucet="minted")
    for day in (31, 91, 181, 301):
        a, b = share_log.get(day), mint_log.get(day)
        if not (a and b):
            continue
        prod = a["starlight_per_day"]
        lines.append(
            f"{day:>4} {prod:>15,.0f} {a['heist_income']:>12,.0f} {b['heist_income']:>13,.0f} "
            f"{100 * a['heist_income'] / (prod + a['heist_income']):>7.0f}% "
            f"{100 * b['heist_income'] / (b['starlight_per_day'] + b['heist_income']):>7.0f}%"
        )
    lines += ["", "§9.4 and §12.1 claim heists supply a third to 40% of a player's resources.",
              "§9.6's formula, which supersedes them, supplies a few per cent."]
    return "\n".join(lines)


def all_reports() -> str:
    return "\n\n".join([
        production_vs_published(),
        position_budget(),
        raiding_trade_off(),
        faucet_comparison(),
    ])
