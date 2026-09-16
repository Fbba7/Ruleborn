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


def test_the_harness_gives_the_same_answers_as_when_it_was_last_read():
    """A fingerprint over 40 runs, so a change in results is never silent.

    Two faults this session (D24, D25) changed every number the harness produces
    — the Vault phase's length and whether crews can see the clock — and both
    were found by reading the model rather than by anything failing. A
    performance change, a refactor, or a tweak to a policy can do the same thing
    without a single assertion going red, because every other test here asserts
    a band rather than a value.

    So this one asserts the values. **If you changed the model deliberately,
    update the digest and say what moved in the commit message** — that is the
    entire point of it. If you did not, something changed that you did not
    intend.
    """
    import hashlib

    runs = run_batch(25, 1, 3, "competent") + run_batch(15, 2, 3, "optimal")
    shape = [(r.grade, r.ticks, r.fill, r.decisions, r.alarm) for r in runs]
    digest = hashlib.sha256(repr(shape).encode()).hexdigest()
    # Changed once, deliberately, by D26: guards now start where `Patrol.phase`
    # says rather than always at waypoint zero.
    assert digest == "496955db53f8d3c4e13f7d1683dd4c47fb49a682f43301859cf1276e10b3c13d", (
        f"the harness now gives different results: {digest}")


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
    """§12.19: "a full crew fills in about ten seconds".

    The arithmetic — a Carrier's 300 at 30 a second — and then the simulation,
    which is the half that matters. The first version of this test checked only
    the arithmetic, and the simulation was meanwhile ending the Vault phase the
    moment the *smallest* bag filled: two seconds, with the Carrier leaving on 60
    of 300. Every crew banked 53% whatever the island did, and every ablation
    number in this harness was measured through it (D24).

    So the assertion is now on a run: a crew told to take everything must spend
    ten seconds doing it, and must actually end up full.
    """
    from .island import generate
    from .laws import Sheet
    from .sim import LOAD_PER_SECOND, ROLES, Heist

    assert ROLES["Carrier"]["carry"] / LOAD_PER_SECOND == 10

    heist = Heist(generate(0, 3, layers=frozenset()), POLICIES["careless"](),
                  realm_level=3, crossing=[], sheet=Sheet(), response=False)
    result = heist.run()
    assert result.fill == 100, result.fill
    carrier = next(m for m in heist.crew if m.role == "Carrier")
    assert carrier.carried / LOAD_PER_SECOND == 10, carrier.carried


def test_skill_polarises_outcomes():
    """F21. §13.2 wants "a populated middle" and watches for the opposite.

    A competent crew has one. A crew that reads §12.17's guards does not: it
    sweeps or comes home nearly empty, because the information turns every raid
    into an early yes-or-no. Asserted as the *gap* between the two, because that
    is the finding — the absolute shares move with tuning, the ordering should
    not.
    """
    from .island import generate
    from .laws import weave
    from .sim import Heist

    def middle(name: str, n: int = 50) -> float:
        fills = []
        for i in range(n):
            r = Heist(generate(i, 3), POLICIES[name](), realm_level=3,
                      crossing=[generate(900_000 + i * 8, 3)],
                      sheet=weave(i, 3, favour_defender=True)).run()
            if r.success:
                fills.append(r.fill)
        return sum(1 for f in fills if 20 <= f < 80) / len(fills)

    competent, optimal = middle("competent"), middle("optimal")
    assert competent > 0.55, competent
    assert optimal < competent * 0.5, (competent, optimal)


def test_the_break_even_is_not_at_12_19s_seventy_per_cent():
    """F20. §9.6 pays grade x fill, so that is what a stopping rule maximises.

    §12.19 states the break-even as a fact and calls it "the dial for the game's
    emotional peak". Measured, loading past 70% is worth more and costs nothing
    in success rate. Asserted as an inequality rather than as a location, because
    where the curve turns over is a much noisier quantity than whether 70% is
    below the turn.

    The sample size is calculated, not guessed. Paired over seeds at 700 raids a
    threshold, 90% beats 70% by +0.0364 with a per-seed standard deviation of
    0.212 — t = 4.5, which is what settles the finding. At n it fails with
    probability P(z < -0.0364 * sqrt(n) / 0.212): about 8% at n=120, which is a
    flaky gate, and under 0.2% at n=300, which is not. An earlier version of this
    test ran 120 and asserted a 10% margin on top, and would have failed roughly
    one build in twelve for no reason at all.
    """
    import statistics as st
    from .island import ALL_LAYERS, generate
    from .laws import weave
    from .policy import Competent
    from .sim import Heist

    grade_value = {"clean": 1.0, "loud": 0.7, "partial": 0.4, "foiled": 0.0}

    def expected(stop: int, n: int = 300) -> float:
        policy = type("Tuned", (Competent,), {"stop_at_fill": stop})
        values = []
        for i in range(n):
            island = generate(i, 3, layers=ALL_LAYERS)
            crossing = [generate(900_000 + i * 8, 3, layers=ALL_LAYERS)]
            r = Heist(island, policy(), realm_level=3, crossing=crossing,
                      sheet=weave(i, 3, favour_defender=True), response=True).run()
            values.append(grade_value[r.grade] * r.fill / 100)
        return st.mean(values)

    at_70, higher = expected(70), expected(90)
    assert higher > at_70, (at_70, higher)



def test_the_fill_term_cuts_9_6s_load_bearing_number_by_most_of_it():
    """F14. §9.6 names 0.46 as "the number the progression curve is built on",
    and that is E[grade] over all attempts. v3.0 then added a `fill` term to the
    same formula and left 0.46 alone.

    What §9.6 now pays is E[grade x fill], so that is what this measures, end to
    end rather than as a product of two averages. A crew playing to §12.19's own
    70% break-even earns about 0.13 an attempt.

    Sized against its own noise: at 400 seeds the mean is 0.132 with a standard
    error of 0.011, so the 0.25 bound below sits eleven standard errors above it
    and this cannot fail by chance. The bound is deliberately loose — the finding
    is that 0.46 is far too high, not that the true figure is exactly 0.13, and a
    tight assertion here would break on any deliberate tuning of the Vault phase.
    """
    import statistics as st
    from .island import ALL_LAYERS, generate
    from .laws import weave
    from .policy import Competent
    from .sim import Heist

    grade_value = {"clean": 1.0, "loud": 0.7, "partial": 0.4, "foiled": 0.0}
    tuned = type("Tuned", (Competent,), {"stop_at_fill": 70})
    values = []
    for i in range(200):
        r = Heist(generate(i, 3, layers=ALL_LAYERS), tuned(), realm_level=3,
                  crossing=[generate(900_000 + i * 8, 3, layers=ALL_LAYERS)],
                  sheet=weave(i, 3, favour_defender=True), response=True).run()
        values.append(grade_value[r.grade] * r.fill / 100)
    got = st.mean(values)
    assert got < 0.25, (
        f"an attempt is worth {got:.3f} of a clean same-level haul. F14 rests on "
        f"this being far below §9.6's stated 0.46; if it has risen to meet it, "
        f"either the fill term was re-derived or the Vault phase changed")


def test_designed_geometry_is_worth_several_times_generated_geometry():
    """F16's own caveat, which the finding could not settle without this.

    F16 measures geometry at a few per cent and says the thing that matters: it
    is measuring *generated* geometry, and §13.2's 25% is a claim about an island
    someone thought about. `designed.py` is that island. Turning the layer off
    and on with everything else held equal, designed geometry is worth several
    times what the generator's is — so §13.2's claim survives and F16 is a
    finding about the generator.

    Asserted as a ratio, because the absolute numbers move with every change to
    the crew and the generator and the ratio is the claim.
    """
    from .ablation import hold_rate
    from .designed import designed
    from .island import ALL_LAYERS, generate

    no_geometry = ALL_LAYERS - {"geometry"}
    made = (hold_rate(ALL_LAYERS, 40, 3) - hold_rate(no_geometry, 40, 3))
    drawn = (hold_rate(ALL_LAYERS, 40, 3, island_fn=designed)
             - hold_rate(no_geometry, 40, 3, island_fn=designed))
    assert made > 0, made
    assert drawn > made * 2.5, (made, drawn)


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
    """F7. §12.6's 15-25 band is reached by crossing realms, not inside one."""
    one = st.median(r.crew_decisions for r in run_batch(30, 0, 3, "optimal"))
    three = st.median(r.crew_decisions for r in run_batch(30, 2, 3, "optimal"))
    assert one < 15, one
    assert three >= one * 1.8, (one, three)


def test_the_clock_is_not_a_pressure_device():
    """F8. Runs finish well inside §5.4's clock, so the last ten seconds
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


def test_the_harness_reproduces_the_document_unless_asked():
    """spec/response.md's effects are a proposal, so they are off by default.

    A proposal that silently changes the baseline is not a proposal, it is a
    second version of the document — the same rule the economy model's
    `apply_fill` follows.
    """
    from .island import generate
    from .policy import POLICIES
    from .sim import Heist
    assert Heist(generate(0, 3), POLICIES["competent"]()).response_model == "published"


def test_a_standalone_response_effect_does_not_break_the_symmetry():
    """F15's first recommendation, measured and refused.

    The Spire's reach and the Sage's power both act with no guard involved. They
    still leave guards and response contributing nothing without each other, in
    every coalition, because a crew already leaves 47% of the exposed share
    behind and finishes at 40 seconds of a 165-second clock. See
    docs/design/spec/response.md.
    """
    import itertools
    from .ablation import hold_rate
    from .island import LAYERS

    others = [x for x in LAYERS if x not in ("guards", "response")]
    for size in range(len(others) + 1):
        for combo in itertools.combinations(others, size):
            s = frozenset(combo)
            assert hold_rate(s | {"response"}, 12, 3,
                             response_model="proposed") == 0.0, combo


def test_the_haul_metric_sees_what_the_hold_rate_cannot():
    """§13.4 measures the hold rate; §9.6 pays on grade x fill.

    The generated defence turns back about a third of raids and takes about four
    fifths of what the raider would otherwise have banked, because §12.9's grades
    multiply the haul by 1.0, 0.7, 0.4 and 0. Everything between "held" and
    "clean" is invisible to §13.4's metric, which is spec/response.md's first
    recommendation, pinned so it cannot quietly stop being true.
    """
    from .ablation import haul_denied, hold_rate
    from .island import ALL_LAYERS

    bare = haul_denied(frozenset(), 30, 3)
    held = hold_rate(ALL_LAYERS, 30, 3)
    denied = haul_denied(ALL_LAYERS, 30, 3, baseline=bare)
    # The level is not what this test is about — D26 moved it, and §13.2's band
    # is checked by `defence_balance`. What is asserted is the relationship.
    assert 20 < held < 75, held
    assert denied > 1.3 * held, (held, denied)


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


def test_one_guard_post_cannot_reach_13_2s_band():
    """F22. §5.2 gives realms 1 and 2 one guard post, and that caps the defence
    below §13.2's 30-45% band whatever the geometry does.

    Asserted at the generator's *best* geometry, because the claim is a ceiling:
    if the strongest island the generator can build still misses the band on one
    post, no weaker one reaches it either. Weakening the geometry would make the
    test pass more easily and prove less.

    Sample size, since this is the shape of assertion that went flaky before:
    measured at 16.5% over 400 raids. At n=200 the standard error is about 2.6
    points, so the 28% bound sits 4.4 standard errors above the mean and the
    test fails by chance on the order of once in a hundred thousand builds.
    """
    from .island import generate
    from .laws import weave
    from .policy import Competent
    from .sim import Heist

    held = 0
    n = 200
    for i in range(n):
        island = generate(i, 1, shaped=True, posts=1)
        heist = Heist(island, Competent(), realm_level=1, crossing=[],
                      sheet=weave(i, 1, favour_defender=True))
        if not heist.run().success:
            held += 1
    rate = 100 * held / n
    assert rate < 28, (
        f"a realm-1 island on §5.2's one guard post held {rate:.1f}% of raids. "
        f"F22 measured 16.5% and concluded §13.2's 30-45% band is out of reach "
        f"there; if this now reaches the band the finding is stale")


def test_the_geometry_is_a_dial_and_not_a_switch():
    """F22's second half. With the geometry on or off, a realm-1 island on two
    posts holds 15.5% or 51.5% and steps straight over §13.2's band; one band
    lands at 44.8%.

    The assertion is ordering, not location — each extra band holds more than
    the last — because the ordering is what makes the layer tunable, and it is a
    far less noisy quantity than any of the three rates. The gaps measured at
    n=400 are 29 and 7 points; this runs 120 a cell, where one standard error is
    about 4.5 points, and asserts only the larger gap.
    """
    from .island import generate
    from .laws import weave
    from .policy import Competent
    from .sim import Heist

    def hold(bands: int, n: int = 120) -> float:
        held = 0
        for i in range(n):
            island = generate(i, 1, shaped=bands, posts=2)
            heist = Heist(island, Competent(), realm_level=1, crossing=[],
                          sheet=weave(i, 1, favour_defender=True))
            if not heist.run().success:
                held += 1
        return 100 * held / n

    none, one = hold(0), hold(1)
    assert one > none + 10, (
        f"laying one switchback band moved the hold rate from {none:.1f}% to "
        f"{one:.1f}%. F22 rests on the geometry being a strength the generator "
        f"can turn; if one band changes nothing, it is a switch again")



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
