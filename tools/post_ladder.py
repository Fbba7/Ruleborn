#!/usr/bin/env python3
"""Would a steeper Guardian Post ladder close F26's gap, or move it?

    python3 -m tools.post_ladder [runs a cell]
    python3 -m tools.post_ladder --self-test

F26 found that at realm 1 the document's defence dials cannot reach §13.2's
30-45% hold band: the strongest island on one guard post holds 24.2% and the
weakest on two holds 62.4%, so the band sits inside a 38-point gap. Its second
recommendation was:

    "Or give the defence a dial finer than a guard that bites at realm 1.
     §10.2's post ladder is exactly the right shape and it is too weak there —
     five points across its whole range. Doubling its effect would make realm 1
     reachable and is one number in one table."

**That last sentence was an assertion, not a measurement**, and this file exists
because the register spent a commit criticising F22 for a recommendation that
named the wrong section. A recommendation is a claim like any other.

Two questions, and the second is the one that decides it.

**How steep does the ladder have to be?** §10.2 sells "+10% health and sight" a
level. The sweep finds the smallest step that brings the best one-post island at
realm 1 up to 30%.

**What does that step cost everywhere else?** Realms 3, 4 and 5 satisfy both
bands on one post at post level 1, where the ladder's slope makes no difference
at all. The risk is at the top of the ladder: a steeper slope means a maxed post
holds more, and those realms have no headroom above 45%. A fix that breaks the
realms that work is not a fix, and listing that collateral is the rule this
repository's own spec files are written to.
"""

from __future__ import annotations

import contextlib
import math
import statistics
import sys

from tools.heist_harness import sim
from tools.heist_harness.report import run_batch

from tools.design_facts import HOLD_BAND          # 13.2 (D37)
from tools.design_facts import DECISION_BAND      # 12.6 (D37)

#: §10.2's own slope: "+10% health and sight" a level.
DOCUMENT_STEP = 0.10
STEPS = (0.10, 0.20, 0.30, 0.40, 0.50)

#: The best one-post island at realm 1, from F26's sweep: the configuration that
#: gets closest to the band from below while keeping the decision count inside
#: §19.27's, **at §5.2's own ward count**.
#:
#: Two bands is right for this question and wrong for the next one, so it does
#: not travel. This file asks what the post ladder can do to the island §5.2
#: builds, and at four wards two bands is the strongest that island gets.
#: `ward_budget.py` asks what realm 1 *needs*, and there the answer is one band
#: with more wards — every ward adds decisions as well as hold, so a second
#: band spends headroom the wards need. An earlier version of `ward_budget.py`
#: imported this value, held it fixed, and reported F26 refuted on a
#: configuration F26 had already ruled out.
REALM_1 = dict(realm=1, depth=3, posts=1, bands=2)

#: The best configuration each upper realm has, from F26's sweep — the one a
#: steeper ladder must not break.
#:
#: Not all of them satisfy both bands at post level 1: realm 2 reads 26.2%
#: there and only enters the band at level 3. An earlier version of this called
#: the list ALREADY_WORKING and the report printed it under "where both bands
#: are already met", which its own level-1 column contradicted on the first
#: row. The list is what it is — the upper realms at their best settings — and
#: whether each is in the band is what the columns are for.
UPPER_REALMS = (
    dict(realm=2, depth=3, posts=1, bands=2),
    dict(realm=3, depth=3, posts=1, bands=1),
    dict(realm=4, depth=2, posts=1, bands=1),
    dict(realm=5, depth=2, posts=1, bands=1),
)


@contextlib.contextmanager
def ladder(step: float):
    """Run with a different §10.2 slope, then put it back.

    The constant is global, so a measurement that leaves it changed would
    silently corrupt every later one in the same process — which is the shape
    of D24, D25 and D26, all of which were a value nobody restored or read.
    """
    was = sim.POST_SIGHT_STEP
    sim.POST_SIGHT_STEP = step
    try:
        yield
    finally:
        sim.POST_SIGHT_STEP = was


def measure(n: int, realm: int, depth: int, posts: int, bands: int,
            level: int) -> tuple[float, float, float]:
    rs = run_batch(n, depth - 1, realm, "competent", laws="defensive",
                   shaped=bands, posts=posts, post_level=level)
    p = sum(1 for r in rs if not r.success) / len(rs)
    return (100 * p, 100 * math.sqrt(p * (1 - p) / len(rs)),
            statistics.median(r.crew_decisions for r in rs))


def report(n: int = 400) -> str:
    out = ["Would a steeper Guardian Post ladder close F26's gap?", ""]
    out.append(f"§13.2's band is {HOLD_BAND[0]:.0f}-{HOLD_BAND[1]:.0f}%. "
               f"Competent crew, sign-aware laws, {n} raids a cell, "
               f"± one standard error.")
    out.append("")

    # --- 1. how steep would it have to be -------------------------------
    out.append("1. Realm 1, three realms crossed, one post, two bands, "
               "post level 5 —")
    out.append("   the strongest island §10.2 permits there, at each ladder slope.")
    out.append("")
    out.append(f"   {'a level adds':>13} {'hold at level 5':>20} {'dec':>4}   reaches the band?")
    enough = None
    for step in STEPS:
        with ladder(step):
            hold, se, dec = measure(n, level=5, **REALM_1)
        reaches = hold >= HOLD_BAND[0]
        if reaches and enough is None:
            enough = step
        tag = "" if not reaches else ("  <- first slope that does"
                                      if enough == step else "  yes")
        marker = "  (§10.2's own)" if step == DOCUMENT_STEP else ""
        out.append(f"   {step * 100:>11.0f}% {hold:>14.1f}% ±{se:>3.1f} {dec:>4.0f}"
                   f"{tag}{marker}")

    if enough is None:
        out.append("")
        out.append("   No slope up to +50% a level reaches the band. The ladder "
                   "is not the fix.")
        return "\n".join(out)

    # --- 2. what it costs the upper realms -------------------------------
    out.append("")
    out.append(f"2. What a {enough * 100:.0f}%-a-level ladder does to the upper "
               f"realms, at their best settings.")
    out.append("   The slope does not apply at level 1, so the level-1 column is "
               "the same at every")
    out.append("   slope and shows where each realm starts; the question is the top "
               "of the ladder,")
    out.append("   which a player will eventually buy.")
    out.append("")
    out.append(f"   {'realm':>5} {'depth':>5} {'level 1':>16} {'level 5':>16}   still in band?")
    broken = []
    for cfg in UPPER_REALMS:
        with ladder(enough):
            lo, lo_se, _ = measure(n, level=1, **cfg)
            hi, hi_se, dec = measure(n, level=5, **cfg)
        ok = HOLD_BAND[0] <= hi <= HOLD_BAND[1]
        if not ok:
            broken.append((cfg["realm"], hi))
        out.append(f"   {cfg['realm']:>5} {cfg['depth']:>5} "
                   f"{lo:>10.1f}% ±{lo_se:>3.1f} {hi:>10.1f}% ±{hi_se:>3.1f}   "
                   f"{'yes' if ok else 'NO — over ' + str(HOLD_BAND[1])}")

    out.append("")
    if broken:
        out.append(f"   A {enough * 100:.0f}%-a-level ladder puts "
                   f"{len(broken)} of {len(UPPER_REALMS)} upper realms outside "
                   f"the band at the top of the ladder:")
        for realm, hold in broken:
            out.append(f"     realm {realm}: {hold:.1f}%")
        out.append("")
        out.append("   So the ladder does not close the gap; it moves it up the "
                   "realm levels.")
        out.append("   F26's second recommendation does not survive its own "
                   "collateral check.")
    else:
        out.append(f"   A {enough * 100:.0f}%-a-level ladder reaches the band at "
                   f"realm 1 and breaks none")
        out.append("   of the realms that already work. F26's second "
                   "recommendation holds, at that slope")
        out.append(f"   rather than at the doubling it guessed "
                   f"({'' if enough == 0.2 else 'which was ' + f'{0.2 * 100:.0f}%'}).")
    return "\n".join(out)


def self_test() -> int:
    """The ladder context manager must restore the constant, and must bite."""
    ok = True
    was = sim.POST_SIGHT_STEP
    with ladder(0.5):
        inside = sim.POST_SIGHT_STEP
    restored = sim.POST_SIGHT_STEP
    print(f"  ladder(0.5): {was} -> {inside} -> {restored}")
    if not (inside == 0.5 and restored == was):
        print("    FAIL: the slope was not set, or not restored")
        ok = False

    try:
        with ladder(0.5):
            raise RuntimeError("boom")
    except RuntimeError:
        pass
    if sim.POST_SIGHT_STEP != was:
        print(f"    FAIL: an exception left the slope at {sim.POST_SIGHT_STEP}")
        ok = False
    else:
        print("  and it restores the slope when the body raises")

    assert sim.post_sight(1) == 1.0, sim.post_sight(1)
    print(f"  level 1 is the baseline at every slope: "
          f"post_sight(1) == {sim.post_sight(1)}")

    flat, steep = measure(60, level=5, **REALM_1), None
    with ladder(0.5):
        steep = measure(60, level=5, **REALM_1)
    print(f"  a steeper ladder holds more: {flat[0]:.1f}% at +10% a level, "
          f"{steep[0]:.1f}% at +50%")
    if steep[0] <= flat[0]:
        print("    FAIL: the slope had no effect, so nothing below means anything")
        ok = False
    return 0 if ok else 1


def main() -> int:
    if "--self-test" in sys.argv:
        return self_test()
    args = [a for a in sys.argv[1:] if not a.startswith("--")]
    print(report(int(args[0]) if args else 400))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
