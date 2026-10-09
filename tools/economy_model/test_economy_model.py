"""Tests for the economy model.

Two kinds of assertion:

  * that the model reproduces the design document where the document is
    self-consistent (its formulas, its early-game curve), which is what makes it
    trustworthy enough to reason with;
  * that the findings in docs/analysis/ still hold, so they are re-checked
    automatically rather than by re-reading 85,000 words.

Run with:  python3 -m pytest tools/economy_model/ -q
       or: python3 tools/economy_model/test_economy_model.py
"""

from dataclasses import replace

from . import data
from .config import Config
from .model import EconomyModel


# -- the document's own formulas ------------------------------------------

def test_stability_capacity_matches_worked_example():
    """§5.5: a Spire at 10 and seven Anchor Stones at 10 give 516."""
    capacity = data.spire_stability(10) + 7 * data.anchor_stability(10)
    assert capacity == 516


def test_building_costs_follow_a_geometric_curve():
    """§29.1: cost = base x growth^(level-1). Confirms the transcription.

    The published costs are rounded, so the growth rate is fitted across the
    whole curve rather than taken from the first step.
    """
    for name, spec in data.BUILDINGS.items():
        n = len(spec.costs)
        growth = (spec.costs[-1] / spec.costs[0]) ** (1 / (n - 1))
        for level, cost in enumerate(spec.costs[1:], start=2):
            predicted = spec.costs[0] * growth ** (level - 1)
            assert abs(cost - predicted) / cost < 0.03, (name, level, cost, predicted)


def test_producer_output_follows_the_published_curve():
    """G7. §9.3: output = base x 1.35^(level-1).

    G7 was that §24's Python model — the source of roughly a quarter of the
    document's numbers — was not in the document. This is the rebuilt model
    reproducing one of the curves it is supposed to have generated.
    """
    for name in ("Star Well", "Aether Spring", "Garden"):
        spec = data.BUILDINGS[name]
        for level, hourly in enumerate(spec.hourly[1:], start=2):
            predicted = spec.hourly[0] * 1.35 ** (level - 1)
            assert abs(hourly - predicted) / hourly < 0.02, (name, level)


def test_keeper_curve_matches_the_stated_target():
    """§14.2: an engaged player's day ~= 0.13 x level^1.96."""
    for level, published in ((16, 31), (28, 90), (40, 181)):
        predicted = 0.13 * level ** 1.96
        assert abs(predicted - published) / published < 0.10, (level, predicted, published)


# -- the model reproduces the early game ----------------------------------

def test_early_production_is_close_to_published():
    """D5. The first month should land within 10% of §9.3, or the model is wrong.

    D5 records the rebuild. This is the assertion that it is a rebuild of the
    same model rather than a different one: the first month has to land within
    10% of what §9.3 publishes.
    """
    model = EconomyModel(Config(archetype="engaged", days=31))
    state = model.run()
    by_day = {row["day"]: row for row in state.log}
    published = data.PUBLISHED_DAILY_PRODUCTION[31][0]
    modelled = by_day[31]["starlight_per_day"]
    assert abs(modelled - published) / published < 0.10, (modelled, published)


def test_early_keeper_levels_are_close_to_published():
    model = EconomyModel(Config(archetype="engaged", days=60))
    state = model.run()
    for level, (published, _, _) in data.PUBLISHED_KEEPER_DAYS.items():
        if level > 16:
            continue
        reached = state.keeper_level_days.get(level)
        assert reached is not None and abs(reached - published) <= 3, (level, reached, published)


# -- the findings ----------------------------------------------------------

def test_finding_raid_payout_models_disagree_by_an_order_of_magnitude():
    """C2: §9.4 claims a third of resources; §9.6's formula delivers a few per cent."""
    shares = {}
    for faucet in ("share", "minted"):
        model = EconomyModel(Config(archetype="engaged", days=181, faucet=faucet))
        state = model.run()
        row = state.log[-1]
        shares[faucet] = row["heist_income"] / (row["starlight_per_day"] + row["heist_income"])
    assert shares["share"] > 0.25, shares          # §9.4's own target, reproduced
    assert shares["minted"] < 0.10, shares         # §9.6's formula, an order of magnitude below
    assert shares["share"] / shares["minted"] > 10, shares


def test_finding_roster_cannot_staff_the_permitted_universe():
    """The build rules create roughly four times the positions the roster can fill."""
    slots_per_producer = data.BUILDINGS["Star Well"].slots[-1]
    roster = 3 + 7 * data.HEARTH_HOMES[-1]
    producer_slots = 7 * 2 * 3 * slots_per_producer      # §5.2 allows 2 of each from level 3
    guard_posts = 6 * 3 + 3                              # §5.2
    positions = producer_slots + guard_posts + 5         # + a crew of five (§12.5)
    assert roster == 38, roster
    assert positions == 152, positions
    assert roster / positions < 0.30, roster / positions
    # Even production alone, with one producer per realm, outruns the roster.
    assert 7 * 1 * 3 * slots_per_producer > roster


def test_finding_raiding_barely_costs_any_production():
    """§11.6 calls this the core trade-off; it is worth about 2% of the roster."""
    model = EconomyModel(Config(archetype="engaged", days=181))
    model.run()
    withheld = model.workers_withheld_by_raiding() / model.roster_size()
    assert withheld < 0.05, withheld


def test_finding_published_tables_imply_one_producer_per_realm():
    """§9.3's figures fit one producer per realm, not the two §5.2 permits."""
    published = data.PUBLISHED_DAILY_PRODUCTION[301][0]
    one, two = (
        EconomyModel(Config(archetype="engaged", days=301, enforce_worker_cap=False,
                            producers_per_realm_override=n)).run().log[-1]["starlight_per_day"]
        for n in (1, 2)
    )
    assert abs(one - published) < abs(two - published), (one, two, published)
    assert two / one > 1.5, (one, two)     # the second producer is worth ~2x production


# -- the proposal in docs/design/spec/economy.md ---------------------------

def _raid_share(faucet: str, archetype: str = "engaged", days: int = 301) -> dict[int, float]:
    """The fraction of a player's income that comes from raiding, by day."""
    state = EconomyModel(Config(archetype=archetype, days=days, faucet=faucet)).run()
    return {
        row["day"]: row["heist_income"] / (row["starlight_per_day"] + row["heist_income"])
        for row in state.log
    }


def test_pegged_faucet_holds_the_raid_share_steady_across_the_curve():
    """The proposal's whole claim: pegging to production fixes C2 by construction.

    §9.6's minted haul falls away as production compounds, which is the finding in
    05-quantitative-findings.md. Pegging the haul to the raider's own production
    should hold the share flat instead — not approximately, but exactly, since
    production divides out. The test asserts flatness rather than trusting the
    prose in spec/economy.md.
    """
    shares = _raid_share("pegged")
    sampled = [shares[day] for day in (31, 91, 181, 301)]
    assert max(sampled) - min(sampled) < 0.01, sampled

    # And the contrast: the model it replaces does not hold.
    minted = _raid_share("minted")
    drift = [minted[day] for day in (31, 91, 181, 301)]
    assert max(drift) - min(drift) > max(sampled) - min(sampled), (drift, sampled)


def test_pegged_faucet_scales_with_how_much_a_player_raids():
    """Raiding four times a day should be worth more of your income than raiding once.

    This is the property §12.1 needs and §9.6's minted haul does not deliver:
    under a minted haul the payout is set by the raider's own level, so a casual
    player raiding once earns a share of their income that is not obviously
    ordered against an engaged player's. Pegged, the ordering is structural.
    """
    by_archetype = {
        name: _raid_share("pegged", archetype=name, days=181)[181]
        for name in ("engaged", "regular", "casual")
    }
    assert by_archetype["engaged"] > by_archetype["regular"] > by_archetype["casual"], \
        by_archetype
    # And it stays a supplement, not a replacement: §9.4 wants about a third.
    assert by_archetype["engaged"] < 0.35, by_archetype


def test_finding_the_fill_term_cuts_the_faucet_by_three_fifths():
    """F14: §9.6 added `fill` and left its own 0.46 average per attempt alone.

    §9.6 calls 0.46 "the number the progression curve is built on". The fill
    term multiplies the same haul, and the harness measures a crew playing to
    §12.19's own break-even escaping with two fifths of its bags — so the true
    figure is near 0.18. The test pins the size of the gap so it cannot close
    quietly in either direction.
    """
    assert abs(data.HAUL_VALUE_PER_ATTEMPT * data.MEASURED_FILL_ON_SUCCESS - 0.18) < 0.02

    without, with_fill = (
        EconomyModel(Config(archetype="engaged", days=181, faucet="minted",
                            apply_fill=fill)).run().log[-1]["heist_income"]
        for fill in (False, True)
    )
    cut = 1 - with_fill / without
    assert 0.52 < cut < 0.68, cut

    # §9.6's own worked example: "an upgrade costing 25 clean raids takes about
    # 55 attempts". With fill it is about twice that.
    attempts = 25 / (data.HAUL_VALUE_PER_ATTEMPT * data.MEASURED_FILL_ON_SUCCESS)
    assert 125 < attempts < 150, attempts

    # And the half §9.6 has no term for: the same formula, a crew that plays to
    # 95% instead of §12.19's break-even. The faucet is skill-dependent and the
    # progression curve is built on a single number.
    spread = data.MEASURED_FILL_OPTIMAL / data.MEASURED_FILL_ON_SUCCESS
    assert spread > 2.0, spread


def test_the_fill_term_is_off_by_default():
    """The model reproduces the document as published unless asked otherwise.

    A finding that silently changes the baseline is not a finding, it is a
    second version of the document.
    """
    assert Config().apply_fill is False


def test_finding_every_aether_and_essence_price_is_on_the_wrong_curve():
    """F17. The faucets multiply by 240 and 251; the prices aimed at them do not.

    This is the cause behind the symptom `sink_audit` reports. Pinned as two
    inequalities rather than as exact numbers, so re-tuning a price cannot make
    the finding quietly disappear without also fixing it.
    """
    from . import sinks

    rows = sinks.price_growth()
    biggest = {}
    for currency, _, _, _, mult in rows:
        biggest[currency] = max(biggest.get(currency, 0), mult)

    # Starlight's sink outruns its faucet; the other two fall far behind theirs.
    assert biggest["Starlight"] / 122 > 5, biggest
    assert biggest["Aether"] / 240 < 0.1, biggest
    assert biggest["Essence"] / 251 < 0.5, biggest


def test_finding_the_one_recurring_price_is_unreachable():
    """F17. §9.5 charges to wake a rested character; rotation means nobody does.

    §11.5 set the roster cap and §11.6 set the rest window. Divided into each
    other they say the price falls due at 199 heists a day, against the four
    §14.2's engaged player runs.
    """
    from . import sinks

    at_cap = sinks.heists_before_waking(38, 5) * 16
    assert at_cap > 150, at_cap
    assert data.ARCHETYPES["engaged"].heists_per_day * 40 < at_cap, at_cap


def test_the_flat_upkeep_means_two_different_things():
    """F17's diagnosis: 0.5 an hour a point is not too cheap, it is unanchored.

    On day 2 it takes most of a day's Aether; on day 301 it rounds to nothing.
    The pegged rate holds its proportion by construction, which is why this test
    asserts a *ratio* of ratios rather than either figure.
    """
    from . import sinks

    def flat_share(day, points):
        aether = data.PUBLISHED_DAILY_PRODUCTION[day][1]
        return data.UPKEEP_AETHER_PER_POINT_HOUR * points * 24 / aether

    early, late = flat_share(2, 40), flat_share(301, 516)
    assert early > 0.5, early           # most of a day's Aether
    assert late < 0.05, late            # a rounding error
    assert early / late > 15, (early, late)

    # Pegged, the same sheet costs the same share whatever the faucet is doing.
    a, b = (sinks.pegged_upkeep_per_hour(x, 516) * 24 / x
            for x in (data.PUBLISHED_DAILY_PRODUCTION[d][1] for d in (2, 301)))
    assert abs(a - b) < 1e-9, (a, b)


# -- §9.6 as v3.3 settled it (D58) -------------------------------------------

def test_the_document_preset_mints_from_the_documents_base_and_band():
    """D58: the model minted from v3.2's 100. `Config.document()` reads §9.6's
    base and band from design_facts: the band as the text states it, the base
    as the owner answered F36 (5,000; the text says 2,400)."""
    low, high = Config.document("low"), Config.document("high")
    assert low.haul_base == data.HAUL_BASE == 5000
    assert (low.attempt_value, high.attempt_value) == data.ATTEMPT_BAND
    assert low.faucet == "minted" and low.haul_level_source == "target"
    # §5.8's three rules, which §14.2 says generate the tables.
    assert (low.producers_per_realm_override, low.staffing_rule,
            low.crew_assigned_not_timed) == (1, "pro_rata", True)


def test_four_raids_are_worth_3_19_and_six_4_15():
    """§9.6's two worked fatigue figures."""
    assert round(EconomyModel.fatigue_sum(4), 2) == 3.19
    assert round(EconomyModel.fatigue_sum(6), 2) == 4.15


def test_a_days_raids_pay_the_base_times_the_band_times_fatigue():
    model = EconomyModel(Config.document("high", days=10))
    model.run()
    expected = (data.HAUL_BASE * data.HAUL_GROWTH ** (model.vault_level() - 1)
                * data.ATTEMPT_BAND[1] * EconomyModel.fatigue_sum(4))
    assert abs(model.heist_income(0.0) - expected) < 1e-6


def test_the_documents_own_raid_worth_arithmetic_sets_2400():
    """§9.6 set 2,400 as "the smallest hundred that passes", where "a crew of
    four leaves producers making about 109 an hour a worker" at Vault level 2.
    109 is the three level-3 producers' mean, (146 + 109 + 73) / 3, all three
    currencies; at it 2,400 passes by a hair and 2,300 fails."""
    b = data.BUILDINGS
    per_worker = (b["Star Well"].hourly[2] + b["Aether Spring"].hourly[2] + b["Garden"].hourly[2]) / 3
    assert round(per_worker) == 109, per_worker
    from . import raidworth as rw
    stay_home = 4 * per_worker * rw.HOURS_AWAY
    assert rw.attempt_value(2400, 2, data.ATTEMPT_BAND[0]) >= stay_home
    assert rw.attempt_value(2300, 2, data.ATTEMPT_BAND[0]) < stay_home


def test_finding_on_this_models_roster_the_raid_worth_check_fails_2400():
    """F36. Run with the roster the model staffs, an attempt at 2,400 pays
    less than staying home at Vault level 2, on the day it arrives and after;
    the base that passes depends on the model's choices, so it is a range,
    not a value §32.9's rule can set."""
    from . import raidworth as rw
    shipped = replace(Config.document(), haul_base=2400)       # §9.6 as the document ships it
    rows = {r.vault: r for r in rw.levels(shipped, 400)}
    assert rows[2].ratio < 1.0 and rows[2].ratio_first < 1.0, rows[2]
    assert rw.smallest_passing_base(shipped, 400, first_day_only=True) > 2400


def test_the_owners_base_is_the_smallest_hundred_passing_every_day():
    """F36, answered: the check holds on every day at every Vault level. With
    the fee an attempt keeps in it (F39), priced on each day with that day's fee kept, that is 5,000, and
    4,900 fails (F53: 4,600 is the value with the fee left out)."""
    from . import raidworth as rw
    assert data.HAUL_BASE == 5000
    assert rw.passes(Config.document(), 1200)
    assert not rw.passes(replace(Config.document(), haul_base=4900), 1200)
    assert rw.passes(replace(Config.document(), haul_base=4600, entry_fee=False), 1200)


# -- the full re-run (T2.6, C19) ---------------------------------------------

def test_the_documents_ladders_come_from_content_and_differ_only_where_v3_3_moved():
    """The transcription sold the Aether Spring ten levels after v3.3 cut it
    to five; the re-run reads §10.2 from content/buildings.json instead."""
    v34 = data.buildings_v34()
    assert len(v34["Aether Spring"].costs) == 5
    assert v34["Library"].keeper_required[:3] == (4, 7, 10)
    for name, spec in data.BUILDINGS.items():
        if name != "Aether Spring":
            assert v34[name].costs == spec.costs, name
            assert v34[name].hourly == spec.hourly, name


def test_the_codex_is_1200_pages_and_the_launch_set_510():
    """§14.4's two totals, from content/laws.json's ranks at §7.6's costs."""
    assert sum(data.codex(launch_only=False)) == 1200
    assert sum(data.codex(launch_only=True)) == 510


def test_an_engaged_player_earns_14_4s_pages():
    """§14.4: "about 16 a day over the first 60 days and about 23 a day after"."""
    model = EconomyModel(Config.document())
    early = []
    for _ in range(120):
        model.step()
        early.append(model.pages_today())
    assert 14 <= sum(early[:60]) / 60 <= 18, sum(early[:60]) / 60
    assert 20 <= sum(early[90:]) / 30 <= 26, sum(early[90:]) / 30


def test_a_birth_costs_1_3455_to_the_number_owned():
    """§9.5's worked prices (v3.7): "about 1,450 for the 10th, 28,100 for the
    20th, 547,000 for the 30th"."""
    price = lambda n: data.BIRTH_BASE * data.BIRTH_GROWTH_V34 ** (n - 1)
    assert round(price(10), -1) == 1450
    assert round(price(20), -2) == 28100
    assert round(price(30), -3) == 547000


def test_finding_strays_fill_the_roster_whatever_a_birth_costs():
    """F38. §11.5's one heist in eight finds a stray, and §18.2's season track
    gives one more: they fill each home as it is built, so the 38th character
    arrives with the last Hearth level at any birth price, and §9.5's rule —
    the rate that puts the 38th on the day every building tops out — has no
    rate to find. Without strays it finds one."""
    from . import rerun
    free = dict(priced_strays=False)                # §11.5 as the document writes it
    assert rerun.tune_birth_rate(**free) is None
    cheap, dear = (rerun.run("engaged", "low", birth_growth=g, **free).day("38 ruleborn")
                   for g in (1.3265, 5.0))
    # A birth nearly four times dearer moves the 38th by days, not the months a
    # price should (3 days at the owner's base, 2 at the document's).
    assert abs(cheap - dear) <= 5, (cheap, dear)
    assert rerun.tune_birth_rate(heist_stray_chance=0.0, season_strays=False, **free) is not None


def test_priced_strays_give_the_birth_rule_its_rate_1_3455():
    """F38, answered: a stray joins at the next birth's price, so §9.5's rule
    has a rate again, the same at both edges of §9.6's band."""
    from . import rerun
    assert rerun.tune_birth_rate("low") == rerun.tune_birth_rate("high") == 1.3455


def _fees_and_raid_starlight(cfg: Config) -> tuple[float, float]:
    """Day 301, engaged: the fees a day's raids keep, and the Starlight they bring."""
    model = EconomyModel(cfg)
    for _ in range(300):
        model.step()
    fees = model.entry_fees(data.heist_success_rate(301))
    model.step()
    return fees, model.s.log[-1]["heist_income"] * (1 - data.HAUL_ESSENCE_SHARE)


def test_finding_the_entry_fee_outweighs_what_raids_pay_while_saving():
    """F39. §9.4's fee is 2% of what the raider holds, kept unless the heist is
    clean; §14.1's player saves for the next Spire level first, so on day 301
    an engaged player holding several hundred thousand pays more in kept fees
    than raids bring in Starlight."""
    fees, raid_starlight = _fees_and_raid_starlight(replace(Config.document(), document_fee=True))
    assert fees > 3 * raid_starlight, (fees, raid_starlight)


def test_the_owners_fee_is_a_small_share_of_what_raids_pay():
    """F39 and C41, answered: 2% of B(V), returned after a clean or loud heist
    and half after a partial one. Fees kept are under a quarter of raid
    Starlight on the same day."""
    fees, raid_starlight = _fees_and_raid_starlight(Config.document())
    assert 0 < fees < 0.25 * raid_starlight, (fees, raid_starlight)


def test_finding_a_player_who_never_raids_stops_levelling():
    """F37. Experience from spending is capped by the Spire, the Spire by the
    Keeper level, and pages by a Library that opens at Keeper 4."""
    model = EconomyModel(Config.document(archetype="never_raids"))
    state = model.run(600)
    # The owner's answer (daily goals, two tutorial ruins): the launch 24 by
    # about day 80, and a plateau below chapter 3's Keeper 12.
    assert state.milestones["24 laws owned"] <= 80, state.milestones
    assert state.keeper_level < 12, state.keeper_level
    assert "Codex restored" not in state.milestones
    # F54: the plateau is Keeper 10 with the bar 6.5 short of 11 — the near
    # miss the answer meant to keep out, held here until it is answered.
    need = data.KEEPER_XP_TO_NEXT[state.keeper_level - 1]
    assert state.keeper_level == 10 and need - state.keeper_xp < 10, (state.keeper_level, state.keeper_xp)


if __name__ == "__main__":
    passed = failed = 0
    for name, fn in sorted(globals().items()):
        if not name.startswith("test_") or not callable(fn):
            continue
        try:
            fn()
            print(f"  [PASS] {name}")
            passed += 1
        except AssertionError as exc:
            print(f"  [FAIL] {name}: {exc}")
            failed += 1
    print(f"\n{passed} passed, {failed} failed")
    raise SystemExit(1 if failed else 0)
