#!/usr/bin/env python3
"""Can the generator meet both of the document's own bands at once?

    python3 tools/generator_settings.py [runs a cell]
    python3 tools/generator_settings.py --self-test

The design document sets two numeric targets for a heist, in different sections,
and never checks them against each other:

    §19.27  a median run carries 15 to 25 decisions
    §13.2   a defence holds 30 to 45% of raids

F22 measured the second across guard posts and geometry bands and found the band
unreachable at §10.2's one post. It also observed that the two knobs are nearly
orthogonal — bands drive the decision count, posts drive the hold rate — and
recommended using them in that order: *lay bands until §19.27 is met, then fill
posts until §13.2 is met.*

This tool carries out that recommendation and reports whether it terminates. For
each realm level and each depth, it sweeps posts and bands and asks which
settings, if any, land inside **both** bands.

Depth is the reason this is not simply F22 re-run. §12.6's decision target is
itself a statement about depth — F7 measured 10 decisions across one realm, 17
across two, 24 across three — so the configuration that satisfies §19.27 is
fixed before the hold rate is measured at all. A hold rate measured at a depth
the decision band excludes is measuring a heist the document does not want.

Note on `links`: the harness counts *crossing* realms, so realms crossed is
``links + 1``. F22's table is ``links=1``, which is the two realms its text
states. Getting this backwards makes every hold rate look 15 points too high,
which is how this tool started.
"""

from __future__ import annotations

import math
import statistics
import sys

from tools.heist_harness.island import POSTS
from tools.heist_harness.report import run_batch

from tools.design_facts import DECISION_BAND, HOLD_BAND  # 13.2, 12.6 (D37)

REALMS = (1, 2, 3, 4, 5)
#: Realms crossed. Two and three are the depths §12.6's decision band implies.
DEPTHS = (2, 3)
BANDS = (0, 1, 2)
#: §5.2 permits one to three guard posts, whatever the realm level. The sweep
#: covers that whole range rather than an offset from §10.2's default, because
#: the question F22 raises is which point in §5.2's *permitted* range works —
#: not whether the range should be widened.
POST_RANGE = (1, 2, 3)


def validate_range() -> None:
    """Refuse a sweep the island generator would reject, before measuring.

    The first version of this tool swept ``POSTS(realm) + 2``, which asks for
    four posts at realm 3 and up. ``island.check()`` enforces §5.2's limit of
    three, so the run died — thirty minutes in, after eleven thousand heists,
    on a cell it could have rejected before the first one.

    D28's lesson was that a job which cannot fail cannot be trusted when it
    passes. This is the same fault inverted: a job that can only fail late
    throws away everything it did first. Both are fixed by asking the question
    early rather than discovering the answer.
    """
    from tools.heist_harness.island import generate
    for realm in REALMS:
        for posts in POST_RANGE:
            for bands in BANDS:
                generate(0, realm, shaped=bands, posts=posts)


def measure(n: int, realm: int, depth: int, posts: int, bands: int) -> tuple:
    """Hold rate, its standard error, and the median decision count."""
    # Without v3.3's crack noise: this sweep asks what posts and geometry do,
    # and with the noise on it answers nothing else (F32).
    rs = run_batch(n, depth - 1, realm, "competent", laws="defensive",
                   shaped=bands, posts=posts, crack_noise=False)
    held = sum(1 for r in rs if not r.success)
    p = held / len(rs)
    se = 100 * math.sqrt(p * (1 - p) / len(rs))
    return 100 * p, se, statistics.median(r.crew_decisions for r in rs)


def inside(value: float, band: tuple) -> bool:
    return band[0] <= value <= band[1]


def sweep(n: int = 120, refine: int = 400) -> list[dict]:
    """Measure every cell cheaply, then re-measure the close ones properly.

    A claim that *no* setting lands inside both bands is only as good as the
    nearest miss, so the cells near a boundary are the ones that need the
    sample. Measuring all ninety at the refined count would spend most of it on
    cells that are nowhere near — realm 5 on three posts holds nearly always,
    and no sample size changes that.
    """
    validate_range()
    rows = []
    for realm in REALMS:
        for depth in DEPTHS:
            for posts in POST_RANGE:
                for bands in BANDS:
                    hold, se, dec = measure(n, realm, depth, posts, bands)
                    rows.append(dict(realm=realm, depth=depth, posts=posts,
                                     bands=bands, hold=hold, se=se, decisions=dec,
                                     spec=posts == POSTS(realm), refined=False))

    for row in rows:
        near_hold = HOLD_BAND[0] - 10 <= row["hold"] <= HOLD_BAND[1] + 10
        near_dec = DECISION_BAND[0] - 4 <= row["decisions"] <= DECISION_BAND[1] + 4
        if near_hold and near_dec:
            hold, se, dec = measure(refine, row["realm"], row["depth"],
                                    row["posts"], row["bands"])
            row.update(hold=hold, se=se, decisions=dec, refined=True)

    for row in rows:
        row["hold_ok"] = inside(row["hold"], HOLD_BAND)
        row["dec_ok"] = inside(row["decisions"], DECISION_BAND)
    return rows


def report(n: int = 120) -> str:
    rows = sweep(n)
    out = ["Can the generator meet both of the document's own bands?", ""]
    out.append(f"§13.2 wants a defence to hold {HOLD_BAND[0]:.0f}-{HOLD_BAND[1]:.0f}% "
               f"of raids; §19.27 wants a median run to carry "
               f"{DECISION_BAND[0]}-{DECISION_BAND[1]} decisions.")
    refined = sum(1 for r in rows if r["refined"])
    out.append(f"Competent crew, sign-aware laws, {n} raids a cell — and 400 for "
               f"the {refined} cells near a boundary, marked +. ± is one standard "
               f"error; * marks §10.2's own post count for that realm.")
    out.append("")
    out.append(f"{'realm':>5} {'depth':>5} {'posts':>5} {'bands':>5} "
               f"{'hold':>14} {'decisions':>9}   both?")

    solved, unsolved = [], []
    for realm in REALMS:
        for depth in DEPTHS:
            here = [r for r in rows if r["realm"] == realm and r["depth"] == depth]
            good = [r for r in here if r["hold_ok"] and r["dec_ok"]]
            (solved if good else unsolved).append((realm, depth, here, good))
            for r in here:
                flags = (("H" if r["hold_ok"] else "·") + ("D" if r["dec_ok"] else "·")
                         + ("+" if r["refined"] else " ")
                         + ("*" if r["spec"] else " "))
                star = "  <<<" if (r["hold_ok"] and r["dec_ok"]) else ""
                out.append(f"{r['realm']:>5} {r['depth']:>5} {r['posts']:>5} "
                           f"{r['bands']:>5} {r['hold']:>8.1f}% ±{r['se']:>3.1f} "
                           f"{r['decisions']:>9.0f}   {flags}{star}")
            out.append("")

    out.append(f"{len(solved)} of {len(solved) + len(unsolved)} realm/depth "
               f"combinations have a setting inside both bands.")
    if unsolved:
        out.append("")
        out.append("Where no setting exists, the nearest miss and by how much:")
        for realm, depth, here, _ in unsolved:
            near = min(here, key=lambda r: _distance(r))
            out.append(f"  realm {realm}, {depth} realms crossed: "
                       f"{near['posts']} posts, {near['bands']} bands — "
                       f"hold {near['hold']:.1f}% ±{near['se']:.1f}, "
                       f"{near['decisions']:.0f} decisions "
                       f"({_why(near)})")
    return "\n".join(out)


def _distance(r: dict) -> float:
    """How far outside the two bands a setting sits, in band-widths."""
    h = 0.0 if r["hold_ok"] else min(abs(r["hold"] - HOLD_BAND[0]),
                                     abs(r["hold"] - HOLD_BAND[1])) / 15.0
    d = 0.0 if r["dec_ok"] else min(abs(r["decisions"] - DECISION_BAND[0]),
                                    abs(r["decisions"] - DECISION_BAND[1])) / 10.0
    return h + d


def _why(r: dict) -> str:
    bits = []
    if not r["hold_ok"]:
        bits.append("hold too low" if r["hold"] < HOLD_BAND[0] else "hold too high")
    if not r["dec_ok"]:
        bits.append("too few decisions" if r["decisions"] < DECISION_BAND[0]
                    else "too many decisions")
    return ", ".join(bits) or "inside both"


def self_test() -> int:
    """The two things this tool could get wrong, both of which it did.

    ``links`` counts crossing realms, so a depth of two realms is ``links=1``.
    Reading it as the realm count inflates every hold rate by roughly fifteen
    points and makes F22's table look misreported when it is not.
    """
    ok = True

    depth_two = run_batch(30, 1, 3, "optimal")
    depth_one = run_batch(30, 0, 3, "optimal")
    a = statistics.median(r.crew_decisions for r in depth_one)
    b = statistics.median(r.crew_decisions for r in depth_two)
    rising = b > a
    print(f"  depth is links+1: one realm carries {a:.0f} decisions, "
          f"two carries {b:.0f} — {'rising' if rising else 'NOT RISING'}")
    ok = ok and rising

    # F22's own cell, at the depth its text states. Reproducing a published
    # number before building on it is the whole discipline here.
    # Recorded at 44.8% under v3.2's full-speed crouch; D56 re-measured it
    # at 66.0% under v3.3's half-speed one, and that is the number F22's note
    # now carries.
    hold, se, _ = measure(200, realm=1, depth=2, posts=2, bands=1)
    near = abs(hold - 66.0) <= 3 * se
    print(f"  F22's realm-1 cell at two realms crossed: {hold:.1f}% ±{se:.1f} "
          f"against its recorded 66.0% — {'reproduces' if near else 'DOES NOT REPRODUCE'}")
    ok = ok and near

    from tools.heist_harness.island import generate
    validate_range()
    print(f"  the sweep range validates: realms {REALMS}, posts {POST_RANGE}, "
          f"bands {BANDS}")
    try:
        generate(0, 3, shaped=0, posts=4)
    except AssertionError:
        print("  and four posts is rejected, which is what the first run "
              "discovered after 11,000 heists")
    else:
        print("    FAIL: four posts should be rejected — §5.2 allows 1 to 3")
        ok = False

    for value, band, expect in ((30.0, HOLD_BAND, True), (29.9, HOLD_BAND, False),
                                (45.0, HOLD_BAND, True), (45.1, HOLD_BAND, False)):
        if inside(value, band) is not expect:
            print(f"    FAIL: inside({value}) should be {expect}")
            ok = False
    print("  band edges are inclusive on both sides")
    return 0 if ok else 1


def main() -> int:
    if "--self-test" in sys.argv:
        return self_test()
    args = [a for a in sys.argv[1:] if not a.startswith("--")]
    print(report(int(args[0]) if args else 120))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
