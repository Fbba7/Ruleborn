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

#: The wards a question about another layer is asked on (island.RULES). On
#: the generator's islands v3.3's wards, whose sensors reach two and three
#: tiles, hold nearly every raid between them (F33), so — as
#: `crack_noise=False` does for F32 — the tests that pin what skill, depth,
#: the clock, the load, the posts or the geometry do are measured on v3.2's
#: on-tile wards and say so. The tests that pin what v3.3's wards do are
#: F33's, and run on the document.
LAYER = "v3.2"

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
    # Changed deliberately by D26 (guards start where `Patrol.phase` says), by
    # D55 (the corner of the eye is the zone's rate halved, as the content
    # file reads it, not the far zone's rate at any distance), and by v3.3's
    # bags (D16: Carry 104, 104, 300, 138 and 104, read from content/roles.json
    # — the only content change that moves it), and by D56: v3.3's half-speed
    # crouch and its crack noise (F32), both on here because both are the
    # document; and by D57: v3.3's wards and budgets (sensor reach, per-ward
    # resets, the 15-second disarm on the tile, 8/8/6/7/8 wards and 1/1/2/3/3
    # posts), the assist bonus, the two crew faults — standing still in
    # front of a ward with no way round, and wandering at a reached link —
    # and a crew that no longer stops to crack inside a ward's sensor; and by
    # v3.4, now the default rules: the crack calls only guards within 5 m of
    # the Vault by the walking path (F32, F35), a ward ignores its disarmer on
    # its tile (G16), and the optimal crew goes round what takes fifteen
    # seconds to disarm (D59); and by the owner's answers: no guard hears the
    # Vault, so the crack call is off by default (F35), and a Lantern Glare
    # reaches the guards within the alarm's spread, not the realm (F33); and by
    # v3.7, now the default rules: §12.17's realm's watch, under which a realm
    # level 3 guard sees 0.7 as far. Under rules="v3.4" the digest is still
    # 951d6c0c…, so the watch is the whole of the change; and by TD.69,
    # §12.17's alarm ladder under the v3.7 rules (decay halved from level 1,
    # a 20-second search from 3, a Glare's 8 m from 4, a Warden at 5, every
    # guard Searching at 6). With the ladder off the digest is 6d1c0c66….
    assert digest == "a4d88544918567b9d27c184a99acbc5f6d21402f1a89af95b815471f3a530012", (
        f"the harness now gives different results: {digest}")


def test_the_corner_of_the_eye_is_the_zone_halved():
    """D55: the content file's reading, which `sim/` also follows.

    The Scout's cone is 45 degrees and its corner of the eye 110. Just over a
    tile away and 39 degrees off its facing, a raider is in the corner of its eye at near
    distance: half of near's 67, not far's 12 as the harness used to say.
    """
    from .fixed import tiles
    # (1, 0.8) tiles: 1.28 m away, 38.7 degrees off — in the corner of the eye.
    z = detect.zone("Scout", 0, 0, 0, tiles(1), tiles(1) * 8 // 10)
    assert z == "p:near", z
    assert detect.fill_rate(z, False, False, False, False) == 33
    assert detect.fill_rate("near", False, False, False, False) == 67


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
    """D24. §12.19: "a full crew fills in about ten seconds".

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
            r = Heist(generate(i, 3, rules=LAYER), POLICIES[name](), realm_level=3,
                      crossing=[generate(900_000 + i * 8, 3, rules=LAYER)],
                      sheet=weave(i, 3, favour_defender=True), crack_noise=False).run()
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
            island = generate(i, 3, layers=ALL_LAYERS, rules=LAYER)
            crossing = [generate(900_000 + i * 8, 3, layers=ALL_LAYERS, rules=LAYER)]
            r = Heist(island, policy(), realm_level=3, crossing=crossing,
                      sheet=weave(i, 3, favour_defender=True), response=True,
                      crack_noise=False).run()
            values.append(grade_value[r.grade] * r.fill / 100)
        return st.mean(values)

    # Without the crack noise (F32) and on v3.2's wards (LAYER): with the
    # noise every stop rule is worth under 0.02 and the curve has no shape.
    at_70, higher = expected(70), expected(90)
    assert higher > at_70, (at_70, higher)



def test_the_fill_term_cuts_9_6s_load_bearing_number_by_most_of_it():
    """F14. §9.6 names 0.46 as "the number the progression curve is built on",
    and that is E[grade] over all attempts. v3.0 then added a `fill` term to the
    same formula and left 0.46 alone.

    What §9.6 now pays is E[grade x fill], so that is what this measures, end to
    end rather than as a product of two averages. A crew playing to §12.19's own
    70% break-even earns about 0.13 an attempt. (Since v3.3's half-speed
    crouch and D57's crews, on v3.2's wards and without the crack noise, it
    is 0.059 at n=300; with the noise, under 0.02 — F32.)

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
        r = Heist(generate(i, 3, layers=ALL_LAYERS, rules=LAYER), tuned(), realm_level=3,
                  crossing=[generate(900_000 + i * 8, 3, layers=ALL_LAYERS, rules=LAYER)],
                  sheet=weave(i, 3, favour_defender=True), response=True,
                  crack_noise=False).run()
        values.append(grade_value[r.grade] * r.fill / 100)
    got = st.mean(values)
    assert got < 0.25, (
        f"an attempt is worth {got:.3f} of a clean same-level haul. F14 rests on "
        f"this being far below §9.6's stated 0.46; if it has risen to meet it, "
        f"either the fill term was re-derived or the Vault phase changed")


def test_designed_geometry_is_worth_more_than_generated_geometry():
    """F16's own caveat, which the finding could not settle without this.

    F16 measures geometry at a few per cent and says the thing that matters: it
    is measuring *generated* geometry, and §13.2's 25% is a claim about an island
    someone thought about. `designed.py` is that island. Turning the layer off
    and on with everything else held equal, designed geometry is worth more
    than the generator's — about three times, which is §13.3's "several
    times" — so §13.2's claim survives and F16 is a finding about the
    generator.

    Asserted as a difference, because the absolute numbers move with every
    change to the crew and the generator and the gap is the claim.
    """
    from .ablation import hold_rate
    from .designed import designed
    from .island import ALL_LAYERS, generate

    # Without the crack noise, which would decide the answer itself (F32),
    # and on v3.2's wards (LAYER). After D57's fixes to the crews the
    # generator's geometry is worth 14.4 points at n=160 and the designed
    # island's 44.4, about three times; at the n=40 run here, 15.0 and 62.5
    # (-7.5 and 57.5 before). What is asserted is the difference.
    no_geometry = ALL_LAYERS - {"geometry"}
    made = (hold_rate(ALL_LAYERS, 40, 3, crack_noise=False, rules=LAYER)
            - hold_rate(no_geometry, 40, 3, crack_noise=False, rules=LAYER))
    drawn = (hold_rate(ALL_LAYERS, 40, 3, island_fn=designed, crack_noise=False, rules=LAYER)
             - hold_rate(no_geometry, 40, 3, island_fn=designed, crack_noise=False, rules=LAYER))
    assert made < 20, made
    assert drawn > made + 30, (made, drawn)


def test_islands_never_seal_the_route():
    """§6.1. `generate` asserts it; this checks the assertion is reachable."""
    for seed in SEEDS:
        island = generate(seed, 3)
        assert island.route_exists(island.entry, island.vault), seed


def test_wards_stay_inside_5_2s_limit():
    """§5.2's limit: v3.3's measured 8, 8, 6, 7 and 8, and v3.2's 3 + level."""
    from tools.design_facts import WARD_LIMITS
    for level in (1, 3, 5):
        island = generate(11, level)
        assert len(island.wards) <= WARD_LIMITS[level - 1], (level, len(island.wards))
        island = generate(11, level, rules="v3.2")
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
    careless = run_batch(40, 1, 3, "careless", crack_noise=False, rules=LAYER)
    optimal = run_batch(40, 1, 3, "optimal", crack_noise=False, rules=LAYER)
    gap = (100 * sum(r.success for r in optimal) / len(optimal)
           - 100 * sum(r.success for r in careless) / len(careless))
    assert gap >= 35, gap


def test_a_crew_that_clears_the_heart_first_survives_the_crack_noise():
    """F32's other half, and T0.11. The noise decides a raid for a crew that
    cracks with the Heart's guards still standing; this crew takes them down
    first, waiting beside their patrols as §12.8 describes. In the Heart alone
    at realm 3, with no wards so that only the guards and the noise are in
    play, it succeeds 65.0% of the time with the noise on, where the optimal
    crew succeeds 20.0% (n=80); it knocks out 1.27 of the two guards a raid,
    and a guard finds a body in about one raid in four. Without the noise the
    two crews are level, 92.5% and 88.8%. The harness judges the approach by
    sight alone, so the clearing crew's number is an upper bound.

    Measured on v3.3's call to the whole Heart, which is what T0.11 was built
    against, and pinned there; v3.4's reach is F35's.
    """
    from .island import generate
    from .laws import Sheet
    from .sim import Heist

    def success(name: str, n: int = 40) -> float:
        wins = sum(Heist(generate(i, 3, wards=0, rules="v3.3"), POLICIES[name](),
                         realm_level=3, crossing=[], sheet=Sheet(),
                         crack_noise=True).run().success for i in range(n))
        return 100 * wins / n

    clearing, optimal = success("clearing"), success("optimal")
    assert clearing >= 2 * optimal, (clearing, optimal)
    assert clearing >= 40, clearing


def test_the_crack_noise_decides_nearly_every_raid():
    """F32. §12.6 (v3.3): "every 5 seconds of cracking every guard in the
    Heart hears the Vault and starts Investigating it."

    None of these crews takes a guard down first, and a Vault at realm level 3
    holds 4,500 — so the noise sounds several times while the crew is pinned
    beside it, and every guard in the Heart walks to where the crew is. With
    it, an optimal crew crossing two realms succeeds 7.5% of the time; without
    it, 65%. The same noise lifts §19.27's skill gap below its 35-point floor
    (7.5 against 65), which is the gate the document exits phases 2 and 3 on.
    """
    loud = run_batch(40, 1, 3, "optimal", crack_noise=True, rules=LAYER)
    quiet = run_batch(40, 1, 3, "optimal", crack_noise=False, rules=LAYER)
    with_noise = 100 * sum(r.success for r in loud) / len(loud)
    without = 100 * sum(r.success for r in quiet) / len(quiet)
    assert with_noise <= 20, with_noise
    assert without >= 50, without


def test_decisions_need_more_than_one_realm():
    """F7. §12.6's 15-25 band is reached by crossing realms, not inside one."""
    one = st.median(r.crew_decisions for r in run_batch(30, 0, 3, "optimal", rules=LAYER))
    three = st.median(r.crew_decisions for r in run_batch(30, 2, 3, "optimal", rules=LAYER))
    assert one < 15, one
    assert three >= one * 1.8, (one, three)


def test_the_clock_is_not_a_pressure_device():
    """F8. Runs finish well inside §5.4's clock, so the last ten seconds
    decide almost nothing — against §19.27's target of a quarter of runs."""
    rs = run_batch(40, 1, 3, "optimal", rules=LAYER)
    late = 100 * sum(r.last_ten_decided for r in rs) / len(rs)
    used = st.median(r.ticks / r.clock_ticks for r in rs)
    assert late < 25, late
    assert used < 0.8, used


# -- the ablation ----------------------------------------------------------

def test_the_clock_reaches_only_the_crew_that_cannot_use_it():
    """D25, D34. What reading §5.4's clock actually changes, policy by policy.

    D25 added the reading: until then no policy touched `heist.clock`, so
    shortening it could kill a crew outright but never change what one chose to
    do. This is that experiment re-run against the fix, and the fix reaches one
    policy of three.

    A competent crew with `watches_clock` on banks exactly what the same crew
    with it off banks, at every clock length tested — the same mean to the
    decimal, because `_out_of_time` needs the inbound journey to be long
    against what is left and a crew that does not hold at checkpoints never
    gets there. A value that is read and changes nothing is indistinguishable
    from one that is not read, which is D25's own lesson and D26's.

    The one crew it does reach is the optimal one, and there it is a wall
    rather than a price: it holds for cones, arrives late, and aborts loading
    altogether. §12.19 asks for a dial — "loading longer earns more and the
    alarm clock is the price" — and neither a no-op nor a cliff is one.

    Asserted as the comparison rather than the absolute numbers, because the
    means move with tuning and the shape is the finding.
    """
    from .island import generate
    from .laws import Sheet
    from .policy import Competent
    from .sim import Heist

    class Blind(Competent):
        name = "blind"
        watches_clock = False

    def banked(cls, clock_pct: int, n: int = 40) -> float:
        fills = []
        for i in range(n):
            fills.append(Heist(generate(i, 3, rules=LAYER), cls(), realm_level=3,
                               crossing=[generate(900_000 + i * 8, 3, rules=LAYER)],
                               sheet=Sheet(), clock_pct=clock_pct,
                               crack_noise=False).run().fill)
        return st.mean(fills)

    # v3.3's half-speed crouch makes the inbound journey long against what is
    # left, so `_out_of_time` now fires for the competent crew too: at 55% of
    # the clock it banks 14.6 where the blind crew banks 17.0 (after D57;
    # 20.4 and 23.7 before). That is the dial §12.19 asks for, reached by a
    # slower crew rather than by a change to the policy. Measured without the
    # crack noise (F32), on v3.2's wards (LAYER).
    seeing = banked(POLICIES["competent"], 55)
    blind = banked(Blind, 55)
    assert seeing < blind, (seeing, blind)

    # And the crew it does reach loses everything rather than some of it.
    full, short = (banked(POLICIES["optimal"], 100),
                   banked(POLICIES["optimal"], 55))
    assert full > 10, full
    assert short < full * 0.1, (full, short)


def test_shapley_matches_two_known_cases():
    """D23. The attribution §13.4 asks for, checked against cases with known answers.

    §13.4 is the most precisely specified test in the document — thirty-two
    combinations of five layers, credit divided the way cooperative game theory
    does. D23 records that it was built exactly as specified; this is the half
    of that claim which can be checked against answers known in advance.
    """
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
    """D21. spec/response.md's effects are a proposal, so they are off by default.

    A proposal that silently changes the baseline is not a proposal, it is a
    second version of the document — the same rule the economy model's
    `apply_fill` follows.
        D21 records that §19.27's harnesses were built and what they implement.
    This is the assertion behind it: the simulation reproduces the document's
    own numbers where it is not deliberately varying one.

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

    # Without the crack noise (F32), which puts the hold at 83%.
    bare = haul_denied(frozenset(), 30, 3, rules=LAYER, crack_noise=False)
    held = hold_rate(ALL_LAYERS, 30, 3, rules=LAYER, crack_noise=False)
    denied = haul_denied(ALL_LAYERS, 30, 3, baseline=bare, rules=LAYER,
                         crack_noise=False)
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


def test_a_crew_with_no_way_round_a_ward_walks_through_it():
    """D57. Two faults v3.3's sensor reach exposed. A crew that found no way
    round a live ward stood in front of it re-planning, and counted a crew
    decision every other second while it did; and a member beside a crossing
    realm's link re-planned to another tile beside it, the long way round
    wherever the tiles between were covered, so the crew was never beside
    the link at once. On a realm with nothing but v3.3's wards — whose
    sensors cover every tile beside the Vault here — every raid used to run
    out the clock in the first realm."""
    from .ablation import hold_rate
    from .sim import Heist

    wards = frozenset({"wards"})
    assert hold_rate(wards, 10, 3) == 0.0
    heist = Heist(generate(0, 3, layers=wards), POLICIES["competent"](),
                  realm_level=3, crossing=[generate(900_000, 3, layers=wards)],
                  response=False)
    result = heist.run()
    assert heist.crossings == 1 and result.success, (heist.crossings, result.grade)
    assert heist.policy.crew_decisions <= 5, heist.policy.crew_decisions


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
    at n=200 the standard error here is about 2.3 points, so the 28% bound sits
    well over 6 standard errors above the mean and the test fails by chance
    essentially never.

    The depth is worth stating, because an earlier version of this docstring got
    it wrong. F22's table is measured across **two** realms, where this cell
    reads 16.5%; this test crosses **one** (``crossing=[]``), where it reads
    12.5%. Both are under the 28% bound and the conclusion is the same, so the
    test was stricter than its own justification rather than weaker — but a
    sample-size argument computed against a different configuration from the one
    the test runs is not a justification, whichever way the error points.
    """
    from .island import generate
    from .laws import weave
    from .policy import Competent
    from .sim import Heist

    held = 0
    n = 200
    for i in range(n):
        island = generate(i, 1, shaped=True, posts=1, rules=LAYER)
        heist = Heist(island, Competent(), realm_level=1, crossing=[],
                      sheet=weave(i, 1, favour_defender=True), crack_noise=False)
        if not heist.run().success:
            held += 1
    rate = 100 * held / n
    assert rate < 28, (
        f"a realm-1 island on §5.2's one guard post held {rate:.1f}% of raids. "
        f"F22 measured 12.5% at this depth and 16.5% across two realms, and "
        f"concluded §13.2's 30-45% band is out of reach there; if this now "
        f"reaches the band the finding is stale")


def test_13_2s_band_falls_inside_a_gap_the_defence_cannot_enter():
    """F26. At realm 1, one guard post and two are 38 points apart, around a
    15-point band — which, under v3.2's rules, lay entirely between them.

    Measured with the decision count inside §19.27's 15-25 band, because a hold
    rate at a depth §12.6's decision target excludes is a hold rate for a heist
    the document does not want. At three realms crossed:

        strongest island on one post    24.2% ± 1.5   (n=800)
        weakest island on two posts     62.4% ± 1.7

    A 38-point gap around a 15-point band. §10.2's Guardian Post ladder is the
    only dial finer than a whole guard, and its entire range is worth about five
    points here — 15.0% at level 1 to 20.0% at level 5.

    The assertion is the **gap**, not either edge. The edges are a 3.8 and a
    10.1 standard-error claim at n=800, which this suite cannot afford to
    re-measure on every build; the gap is a far less noisy quantity and it is
    what the finding is about. The precise edges carry `measured=` provenance in
    the register instead, for the same reason F19 does.
    """
    from .island import generate
    from .laws import weave
    from .policy import Competent
    from .sim import Heist

    def hold(posts: int, bands: int, level: int, n: int = 250) -> float:
        held = 0
        for i in range(n):
            crossing = [generate(900_000 + i * 8 + k, 1, shaped=bands,
                                 posts=posts, post_level=level, rules=LAYER) for k in range(2)]
            heist = Heist(generate(i, 1, shaped=bands, posts=posts,
                                   post_level=level, rules=LAYER), Competent(), realm_level=1,
                          crossing=crossing, sheet=weave(i, 1, favour_defender=True),
                          crack_noise=False)
            if not heist.run().success:
                held += 1
        return 100 * held / n

    one_post = hold(posts=1, bands=2, level=5)     # the best one post can do
    two_posts = hold(posts=2, bands=1, level=1)    # the least two can do
    gap = two_posts - one_post
    assert gap > 20, (
        f"the gap between one guard post ({one_post:.1f}%) and two "
        f"({two_posts:.1f}%) has closed to {gap:.1f} points. F26 measured 38 "
        f"and concluded §13.2's 15-point band cannot be reached at realm 1; if "
        f"the defence now has that resolution the finding is stale")
    # v3.3 halved the crouch (G13), and a slower crew is caught more: the
    # best one post can do rose from 24.2% to 43.6%, inside the band, while
    # two posts rose from 62.4% to 81.2% (after D57; 42.0 and 80.0 before).
    # The gap is the same 38 points; the band now sits at its lower edge
    # rather than inside it. Measured without the crack noise, which swamps
    # both (F32), and on v3.2's wards (LAYER).
    assert 30 <= one_post, (
        f"one guard post at its best holds {one_post:.1f}%, under §13.2's band "
        f"again; under v3.3's crouch it measured 43.6%")


def test_wards_are_the_lever_realm_1_has_and_5_2_rations():
    """F26's fix. §5.2 gives realm 1 four wards and the band needs about ten.

    The assertion is the *ordering*, not the crossing point. Where the ward axis
    crosses 30% is a location and therefore noisy — 30.8% ± 1.6 at n=800, half a
    standard error inside — while "ten wards hold materially more than four" is
    a difference, and the difference is what the recommendation rests on.

    This is also the counterfactual guard: an island built with more wards than
    §5.2 allows sets `ward_budget`, so nothing here can be mistaken for a legal
    island. If §5.2's ward formula changes, this test is what says whether the
    new number reaches the band.
    """
    from .island import generate
    from .laws import weave
    from .policy import Competent
    from .sim import Heist

    def hold(wards: int, n: int = 200) -> float:
        held = 0
        for i in range(n):
            crossing = [generate(900_000 + i * 8 + k, 1, shaped=1, posts=1,
                                 wards=wards, rules=LAYER) for k in range(2)]
            heist = Heist(generate(i, 1, shaped=1, posts=1, wards=wards, rules=LAYER),
                          Competent(), realm_level=1, crossing=crossing,
                          sheet=weave(i, 1, favour_defender=True))
            if not heist.run().success:
                held += 1
        return 100 * held / n

    lawful, doubled = hold(4), hold(10)
    assert doubled - lawful > 6, (
        f"ten wards held {doubled:.1f}% against four at {lawful:.1f}%, a gap of "
        f"{doubled - lawful:.1f} points. F26 measured 11.6 and concluded the ward "
        f"axis is the one lever that reaches §13.2's band at realm 1; if that gap "
        f"has closed, the recommendation is stale")
    assert generate(0, 1, wards=10, rules=LAYER).ward_budget == 10, (
        "an island past §5.2's ward limit must carry ward_budget, so a "
        "counterfactual cannot be mistaken for a legal island")


def test_a_flat_ward_count_breaks_the_realms_that_work():
    """F26's collateral check, and the reason the fix is per realm.

    Ten wards is what realm 1 needs to reach §13.2's band. Applied everywhere it
    loses the band at realms 3 and 5, which satisfy it on §5.2's own count — the
    same shape as F27's steeper post ladder, which reached realm 1 and carried
    all four upper realms out of the top.

    Asserted at realm 3, where the break is largest and least ambiguous: 34.4%
    on §5.2's six wards against 53.6% on ten. The assertion is that ten wards
    pushes realm 3 clear of the band, not where it lands, because a fix that
    breaks a working realm is refuted by the direction alone.
    """
    from .island import generate
    from .laws import weave
    from .policy import Competent
    from .sim import Heist

    def hold(realm: int, wards: int, bands: int, n: int = 200) -> float:
        held = 0
        for i in range(n):
            crossing = [generate(900_000 + i * 8 + k, realm, shaped=bands,
                                 posts=1, wards=wards, rules=LAYER) for k in range(2)]
            heist = Heist(generate(i, realm, shaped=bands, posts=1, wards=wards, rules=LAYER),
                          Competent(), realm_level=realm, crossing=crossing,
                          sheet=weave(i, realm, favour_defender=True),
                          crack_noise=False)
            if not heist.run().success:
                held += 1
        return 100 * held / n

    lawful = hold(realm=3, wards=6, bands=1)      # §5.2's own count
    flat_ten = hold(realm=3, wards=10, bands=1)   # what realm 1 needs
    # Under v3.3's slower crouch realm 3 on its six wards reads 50.5%, five
    # points over the band rather than inside it (it was 42.0%); ten wards
    # reads 74.5% (after D57; 48.0 and 68.0 before). The claim is the
    # distance between them. Without the crack noise (F32), which puts both
    # near 80-90%, and on v3.2's wards (LAYER).
    assert flat_ten - lawful >= 15, (
        f"six wards {lawful:.1f}%, ten {flat_ten:.1f}%: a flat ten no longer "
        f"moves realm 3 far past what its own six do")
    assert flat_ten > 45, (
        f"ten wards at realm 3 held {flat_ten:.1f}%, inside §13.2's band. F26 "
        f"measured 53.6% and concluded a flat ward count breaks the realms that "
        f"work, which is why its recommendation is a per-realm table")


def test_one_lantern_glare_outweighs_a_realm_of_other_wards():
    """F33. §5.2 budgets wards by count; the Lantern Glare is a switch.

    §10.3's Glare "shows the crew to every guard in the realm", which with
    §12.17's near-zone fill is every guard Alerted within half a second — the
    response layer, set off by a ward. On v3.3's rules, at realm 3 on §5.2's
    two posts, one geometry band and three realms crossed (n=80): no ward
    holds 42.5%; one Glare 71.2%, two 97.5%, three or more every raid; while
    a kit with no Glare at all holds 41 to 68% at any count from one to
    seven, not monotonically, and 46.2% at §5.2's six. The resolution F26 credited to the ward
    count was a Glare arriving every third ward in the generator's order.
    """
    def held(kinds, wards: int, n: int = 60) -> float:
        rs = run_batch(n, 2, 3, "competent", laws="defensive", shaped=1, posts=2,
                       wards=wards, crack_noise=False, ward_kinds=kinds, glare_realm=True)
        return 100 * sum(not r.success for r in rs) / n

    two_glares = held(("Lantern Glare",), 2)
    six_others = held(("Time Snare", "Gravity Well"), 6)
    assert two_glares >= 85, two_glares
    assert two_glares - six_others >= 25, (two_glares, six_others)


def test_the_decided_glare_is_one_strong_pick_not_a_switch():
    """F52, decided: a Glare reaches a fixed 4 m, which Whispers does not
    stretch. Before that answer the Glare took the alarm's reach, the
    defensive weave picked Whispers, and two Glares held realm 3 at 91.5%
    against six Snares and Wells' 37.0% (n=200): F33's switch, back. At the
    fixed 4 m the brief's figures hold — two Glares 72.5% here (n=200; the
    brief measured 75.2% at n=400) — well short of the realm-wide Glare's
    97.5%, but still the strongest kind on the harness's realm 3.
    """
    two_glares, six_others = glare_holds()
    assert 55 <= two_glares <= 85, two_glares
    assert two_glares > six_others, (two_glares, six_others)


def glare_holds(n: int = 60) -> tuple:
    """Two Glares against six other wards, at realm 3 on two posts, with the
    Glare as the owner decided it (F33, F52): within a fixed 4 m."""
    def held(kinds, wards: int) -> float:
        rs = run_batch(n, 2, 3, "competent", laws="defensive", shaped=1, posts=2,
                       wards=wards, ward_kinds=kinds)
        return 100 * sum(not r.success for r in rs) / n
    return held(("Lantern Glare",), 2), held(("Time Snare", "Gravity Well"), 6)


def test_finding_5_2s_budget_holds_every_realm_level_above_13_2s_band():
    """F55 (T0.12). §13.2's table re-measured with every answer built — no
    guard hears the Vault (F35), a Glare reaches a fixed 4 m (F33, F52) — at
    v3.6's §5.2 wards and posts (8, 8, 6, 7, 8 on 1, 1, 2, 3, 3): the competent
    crew is held 47.6, 60.8, 59.9, 90.6 and 95.5% at realm levels 1 to 5
    (n=800), all above 30 to 45%. At three posts the guards alone hold realm 5
    at 58.4%, so no ward count reaches the band there. Measured under the
    rules it was found on (full-strength guards, rules="v3.4").
    """
    def held(level: int, wards=None, posts=None, n: int = 60) -> float:
        rs = run_batch(n, 2, level, "competent", laws="defensive", shaped=1,
                       wards=wards, posts=posts, rules="v3.4")
        return 100 * sum(not r.success for r in rs) / n

    assert held(3) >= 45                                   # 6 wards, 2 posts
    assert held(5, wards=0, posts=3) >= 45                 # v3.6's 3 posts, no wards
    assert held(3, wards=1, posts=2) <= 50                 # a setting inside reach


def test_the_realm_alarm_climbs_and_its_ladder_acts_as_12_17_says():
    """TD.69. §12.17's alarm climbs a level every thirty seconds, one per body
    found, to six, in each realm from when the crew arrives; at 5 a Warden
    arrives at the entry and at 6 every guard not chasing enters Searching.
    The v3.4 rules had no ladder here, so their alarm stays at 0."""
    from .sim import ALARM_STEP_TICKS, SEARCHING_TICKS
    h = Heist(generate(7, 3), POLICIES["competent"]())
    assert h.realm_alarm == 0
    h.tick = 2 * ALARM_STEP_TICKS
    assert h.realm_alarm == 2
    h.bodies_found += 1
    assert h.realm_alarm == 3, "a body found climbs it one more"
    h.tick = 9 * ALARM_STEP_TICKS
    assert h.realm_alarm == 6, "never above six"
    before = len(h.guards)
    h._alarm_steps()
    assert len(h.guards) == before + 1 and h.guards[-1].role == "Warden"
    assert all(g.state in ("searching", "alerted") for g in h.guards if not g.down)
    assert all(g.searching_left == SEARCHING_TICKS for g in h.guards if g.state == "searching")
    h._alarm_steps()
    assert len(h.guards) == before + 1, "once a realm"
    old = Heist(generate(7, 3, rules="v3.4"), POLICIES["competent"]())
    old.tick = 9 * ALARM_STEP_TICKS
    assert old.realm_alarm == 0


def test_v3_7s_budget_and_watch_hold_realm_levels_1_3_4_and_5_inside_13_2s_band():
    """F55, closed by v3.7 (option D): §5.2's wards 8, 8, 6, 2 and 0 on 1, 1, 2,
    1 and 1 posts, with §12.17's realm's watch tuning the guards at realm levels
    1 to 3, so "every level holds 30 to 45% again" (v3.7 publishes 37.5, 39.0,
    37.5, 38.0 and 36.9% at n = 800). With §12.17's alarm ladder built (TD.69)
    the harness's seeds hold levels 1, 3, 4 and 5 inside the band. Realm level
    2 does not: 46.4% at n = 800 at its watch of 0.75 (44.2% with the ladder
    off), and 38.8% at 0.7 — F62, a balance figure for the document."""
    from ..design_facts import HOLD_BAND
    lo, hi = HOLD_BAND
    for level in (1, 3, 4, 5):
        rs = run_batch(100, 2, level, "competent", laws="defensive", shaped=1)
        held = 100 * sum(not r.success for r in rs) / len(rs)
        assert lo <= held <= hi, (level, held)


def test_a_lever_scales_the_rule_sheet_on_top_of_the_laws():
    """F55's sweep (python3 -m tools.heist_harness levers): a lever multiplies
    the woven sheet, so guards that see seven-tenths as far hold realm 3 less
    often, and the same seeds with no lever reproduce the run exactly."""
    def held(lever=None, n: int = 40) -> float:
        rs = run_batch(n, 2, 3, "competent", laws="defensive", shaped=1, lever=lever)
        return 100 * sum(not r.success for r in rs) / n

    base = held()
    assert held() == base
    assert held({"sight_range": 0.7}) < base, base


def test_13_2s_hold_table_was_measured_at_one_guard_post():
    """F34. §13.2 (v3.3) lists realm 3's hold, 34.4%, at six wards and §5.2's
    two guard posts. F26's sweep, which that table quotes, ran one post in
    every realm. On the harness it was measured on (v3.2's wards, crack
    noise off, one band, three realms), realm 3 at six wards holds 50.5% on
    one post and 94.5% on two (n=200): the second post §5.2 gives it
    is worth some forty-five points, and the table's posts column is not the
    setting its holds were measured at.
    """
    def held(posts: int, n: int = 60) -> float:
        rs = run_batch(n, 2, 3, "competent", laws="defensive", shaped=1,
                       posts=posts, wards=6, crack_noise=False, rules=LAYER)
        return 100 * sum(not r.success for r in rs) / n

    one, two = held(1), held(2)
    assert two >= 75, two
    assert two - one >= 30, (one, two)


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
            island = generate(i, 1, shaped=bands, posts=2, rules=LAYER)
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



# -- v3.4 ------------------------------------------------------------------

def test_a_ward_ignores_its_disarmer_on_the_tile_and_not_on_the_way():
    """G16 and G18. §10.3 (v3.4): "While it disarms, the ward's sensor ignores
    that crew member … it still fires on anyone else in reach." A disarmer
    stands on the ward's tile, so the text covers the tile and not the walk
    there; `disarm_approach` is the generous reading that covers both."""
    from .island import Ward
    from .sim import U, Heist

    def fired(kind, where, walking_to=False, approach=False, disarming=True):
        island = generate(0, 3, wards=0)
        ward = Ward(kind, 5, 5)
        island.wards = [ward]
        heist = Heist(island, POLICIES["competent"](), crossing=[],
                      disarm_approach=approach)
        m = heist.crew[0]
        m.x, m.y = where[0] * U + U // 2, where[1] * U + U // 2
        m.disarming = ward if disarming else None
        m.path = [(5, 5)] if walking_to else []
        heist._wards()
        return ward.spent

    assert not fired("Time Snare", (5, 5)), "its disarmer, on the tile"
    assert fired("Time Snare", (5, 5), disarming=False), "anyone else"
    assert fired("Lantern Glare", (5, 7), walking_to=True), "G18: the walk is not covered"
    assert not fired("Lantern Glare", (5, 7), walking_to=True, approach=True), (
        "the generous reading covers the walk")


def test_the_optimal_crew_goes_round_what_takes_fifteen_seconds_to_disarm():
    """D59. The optimal crew's ward answers were set for v3.2's disarm, three
    seconds and one a level from beside the ward, and kept for v3.3's fifteen
    on the tile. At realm 3 with the crack noise off (n=40) the crew that
    disarmed succeeded 10.0% of the time, the competent crew 45.0%, and the
    same optimal crew going round every ward 52.5%. v3.4's answers go round."""
    from .policy import Optimal
    from .sim import Heist

    class Disarms(Optimal):
        ward_answer_v34 = None                    # v3.3's answers on a v3.4 island

    def success(cls, n: int = 40) -> float:
        wins = sum(Heist(generate(i, 3), cls(), realm_level=3, crossing=[],
                         crack_noise=False, glare_realm=True).run().success
                   for i in range(n))
        return 100 * wins / n

    around, disarms = success(POLICIES["optimal"]), success(Disarms)
    assert around - disarms >= 25, (around, disarms)


def test_every_metre_of_the_cracks_reach_costs_the_optimal_crew_depth():
    """F35. Brief 37's sweep (§32.9, v3.4). One realm at realm level 3: the
    optimal crew's lead over the careless one is +44 points with no call and
    +3 at the 5 m v3.4 ships (n=40 a cell, `depth --sweep crack_reach`). The
    harness has no hearing but the call, so its 5 m is also the design's
    per-hit 5 m, which v3.4 took to be the no-call case."""
    def gap(**kw) -> float:
        best = run_batch(60, 0, 3, "optimal", **kw)
        worst = run_batch(60, 0, 3, "careless", **kw)
        return 100 * (sum(r.success for r in best) - sum(r.success for r in worst)) / 60

    # v3.4's Glare, realm-wide, as the sweep was run (F33 has since narrowed it).
    quiet = gap(crack_noise=False, glare_realm=True)
    five = gap(crack_reach=5, crack_noise=True, glare_realm=True)
    assert quiet >= 30, quiet
    assert quiet - five >= 25, (quiet, five)


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
