"""Tests for the heist harness.

Three kinds of assertion, and the first is the one that matters most:

  * that a run is **deterministic** — the same seed and policy give the same
    result, every time, in any process. §24.7 requires it of the real simulation
    and §19.27's numbers are worthless without it here;
  * that the harness implements the sections it claims to, checked against the
    document's own figures rather than against itself;
  * that the findings it produced still hold, so they are re-checked rather than
    re-argued.

Run with:  python3 -m tools.heist_harness.test_harness
"""

import statistics as st

from . import detect
from .fixed import TPS, TURN, Rng, angle_diff, turn_toward
from .island import generate
from .policy import POLICIES
from .report import run_batch
from .sim import BASE_TICKS, LINK_TICKS, Heist, path_to

SEEDS = range(40)


# -- determinism ----------------------------------------------------------

def test_a_run_is_a_function_of_its_seed():
    for seed in (0, 7, 41):
        a = Heist(generate(seed, 3), POLICIES["competent"]()).run()
        b = Heist(generate(seed, 3), POLICIES["competent"]()).run()
        assert (a.grade, a.ticks, a.fill, a.decisions) == \
               (b.grade, b.ticks, b.fill, b.decisions), seed


def test_islands_are_a_function_of_their_seed():
    for seed in (0, 7, 41):
        assert generate(seed, 3).tiles == generate(seed, 3).tiles


def test_the_rng_is_splitmix64():
    """The reference stream for seed 0, so a port can be checked against it."""
    assert [Rng(0).next() for _ in range(1)] == [16294208416658607535]
    r = Rng(0)
    assert [r.next() for _ in range(3)] == [
        16294208416658607535, 7960286522194355700, 487617019471545679]


def test_no_floating_point_decides_a_result():
    """§24.7. Every position, angle and suspicion value is an int."""
    h = Heist(generate(3, 3), POLICIES["competent"]())
    h.run()
    for m in h.crew:
        assert isinstance(m.x, int) and isinstance(m.y, int) and isinstance(m.carried, int)
    for g in h.guards:
        assert isinstance(g.x, int) and isinstance(g.suspicion, int) \
            and isinstance(g.facing, int)


# -- the document's own numbers -------------------------------------------

def test_the_clock_follows_5_4():
    """§5.4: 150 seconds plus 15 for each link, capped at 240."""
    for links in (0, 1, 2, 5, 9):
        h = Heist(generate(1, 3), POLICIES["competent"](),
                  crossing=[generate(100 + k, 3) for k in range(links)])
        assert h.clock == min(240 * TPS, BASE_TICKS + LINK_TICKS * links), links


def test_detection_zones_match_12_17():
    """A Scout sees 6 metres in a 45-degree cone, and nothing behind it."""
    from .fixed import tiles
    assert detect.zone("Scout", 0, 0, 0, tiles(1), 0) == "near"
    assert detect.zone("Scout", 0, 0, 0, tiles(3), 0) == "mid"
    assert detect.zone("Scout", 0, 0, 0, tiles(5), 0) == "far"
    assert detect.zone("Scout", 0, 0, 0, tiles(7), 0) is None
    assert detect.zone("Scout", 0, 0, 0, -tiles(2), 0) is None


def test_suspicion_fills_at_12_17s_stated_seconds():
    """Near fills in about half a second, mid in one, far in just under three."""
    for zone_name, seconds in (("near", 0.5), ("mid", 1.0), ("far", 2.8)):
        ticks = detect.SUS_MAX / detect.FILL[zone_name]
        assert abs(ticks / TPS - seconds) < 0.25, (zone_name, ticks / TPS)


def test_a_full_crew_loads_in_ten_seconds():
    """§12.19: 30 units a second, and a Carrier holds 300."""
    from .sim import LOAD_PER_SECOND, ROLES
    assert ROLES["Carrier"]["carry"] / LOAD_PER_SECOND == 10


def test_islands_never_seal_the_route():
    """§6.1. `generate` asserts it; this checks the assertion is reachable."""
    for seed in SEEDS:
        island = generate(seed, 3)
        assert island.route_exists(island.entry, island.vault), seed


def test_wards_stay_inside_5_2s_limit():
    for level in (1, 3, 5):
        island = generate(11, level)
        assert len(island.wards) <= 3 + level, (level, len(island.wards))


def test_the_exit_is_reachable_exactly():
    """The bug this catches cost half the runs: `path_to` targets tiles adjacent
    to the goal, which for the walkable exit means orbiting it for ever."""
    island = generate(8, 3)
    beside = (island.entry[0] - 1, island.entry[1])
    assert path_to(island, beside, island.entry, exact=True)[-1] == island.entry


# -- the findings ----------------------------------------------------------

def test_skill_separates_outcomes():
    """§19.27's depth threshold: optimal at least 35 points above careless."""
    careless = run_batch(40, 1, 3, "careless")
    optimal = run_batch(40, 1, 3, "optimal")
    gap = (100 * sum(r.success for r in optimal) / len(optimal)
           - 100 * sum(r.success for r in careless) / len(careless))
    assert gap >= 35, gap


def test_decisions_need_more_than_one_realm():
    """The finding: §12.6's 15-25 band is reached by crossing realms, not inside one."""
    one = st.median(r.crew_decisions for r in run_batch(30, 0, 3, "optimal"))
    three = st.median(r.crew_decisions for r in run_batch(30, 2, 3, "optimal"))
    assert one < 15, one
    assert three >= one * 1.8, (one, three)


def test_the_clock_is_not_a_pressure_device():
    """The finding: runs finish well inside §5.4's clock, so the last ten seconds
    decide almost nothing — against §19.27's target of a quarter of runs."""
    rs = run_batch(40, 1, 3, "optimal")
    late = 100 * sum(r.last_ten_decided for r in rs) / len(rs)
    used = st.median(r.ticks / r.clock_ticks for r in rs)
    assert late < 25, late
    assert used < 0.8, used


# -- the ablation ----------------------------------------------------------

def test_shapley_matches_two_known_cases():
    """The attribution §13.4 asks for, checked against cases with known answers."""
    import itertools
    from .ablation import shapley
    from .island import LAYERS

    def coalitions(fn):
        return {frozenset(c): fn(c)
                for s in range(len(LAYERS) + 1)
                for c in itertools.combinations(LAYERS, s)}

    # One layer does everything: it takes all the credit. Compared with a
    # tolerance, since the sum of 120 weighted terms does not land on 100.0
    # exactly in binary floating point.
    solo = shapley(coalitions(lambda c: 100.0 if "guards" in c else 0.0))
    assert abs(solo["guards"] - 100.0) < 1e-9, solo
    assert all(abs(v) < 1e-9 for k, v in solo.items() if k != "guards"), solo

    # Perfectly additive: equal shares.
    even = shapley(coalitions(lambda c: 10.0 * len(c)))
    assert all(abs(v - 10.0) < 1e-9 for v in even.values()), even


def test_guards_and_response_are_the_same_layer():
    """F15. §13.2 counts them as two layers at 20% and 15%.

    §13.2 defines response as "what turns being seen into being caught", which
    makes it multiplicative with guards rather than additive. Neither turns back
    a single raid without the other, in any coalition — so they are symmetric
    players and the Shapley value must assign them identical shares.
    """
    import itertools
    from .ablation import hold_rate
    from .island import LAYERS

    others = [x for x in LAYERS if x not in ("guards", "response")]
    for size in range(len(others) + 1):
        for combo in itertools.combinations(others, size):
            s = frozenset(combo)
            assert hold_rate(s | {"guards"}, 12, 3) == 0.0, combo
            assert hold_rate(s | {"response"}, 12, 3) == 0.0, combo


def test_no_layer_turns_back_a_raid_alone():
    """§13.2: "no layer decides an outcome on its own" — much more so than meant."""
    from .ablation import hold_rate
    from .island import LAYERS
    for layer in LAYERS:
        assert hold_rate(frozenset({layer}), 15, 3) == 0.0, layer


def test_ablation_layers_change_only_themselves():
    """An ablation that moves two things at once measures the confound.

    Turning geometry off once removed a ward as well, because the ward count was
    derived from the route length.
    """
    from .island import ALL_LAYERS
    for off in ("geometry", "guards"):
        for seed in (0, 5, 17):
            full = generate(seed, 3)
            without = generate(seed, 3, layers=ALL_LAYERS - {off})
            assert len(full.wards) == len(without.wards), (off, seed)


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
