#!/usr/bin/env python3
"""Which setting, if any, puts each realm inside both of the document's bands?

    python3 -m tools.ward_budget [n]
    python3 -m tools.ward_budget --self-test

F26 found that §13.2's 30-45% hold band and §19.27's 15-25 decisions cannot
both be met at realm 1 by any setting §5.2 and §10.2 permit, and that the one
dial with the resolution to close it is the ward count. It recorded a measured
need of **10, 8, 6, 7, 8** wards at realms 1 to 5, against §5.2's
``3 + realm level`` — 4, 5, 6, 7, 8. Run as a table, four of those five rows
come back confirmed and realm 1 moves by one: ten wards holds 29.5% ± 2.3,
half a point under §13.2's floor, and eleven holds 32.5% ± 2.3. The budget is
**11, 8, 6, 7, 8**, and the window at realm 1 is one ward wide.

**That budget was read off a sweep one realm at a time, and never run as the
table it claims to be.** A defence budget is a table a player moves through,
and each row has to hold at the settings that row actually uses. So the range
is swept rather than the two recorded numbers tested, and what comes back is
the setting each realm needs or the fact that none exists.

The first version of this file held the geometry band count at two, borrowed
from `post_ladder.REALM_1`, and reported that no ward count reaches the bands
at realms 1 and 2 — that F26 was refuted. F26's own recommendation says why
that is wrong: *"that is why nothing works at two geometry bands … the answer
is one band with more wards rather than the reverse."* At one band its number
reproduces exactly, 30.8% at ten wards. **A constant borrowed from another
file is an assumption, not a setting**, and an assumption that contradicts the
finding under test turns a measurement into a refutation of nothing. The band
count is swept now, and which one a realm's answer uses is part of the answer.

Two rules this inherits. **A fix that breaks the realms that work is not a
fix**: realms 3 to 5 satisfy both bands on §5.2's own count, and the sweep has
to reproduce that. And **`links` counts crossing realms**, so three realms is
``links=2``; reading it as the realm count inflates every hold rate by about
fifteen points.

Where a realm has no setting at all, the depth is tried as well, because depth
is the one axis that is not like the others: it sets the decision count almost
by itself (F7) and leaves the hold rate to the defence.
"""


from __future__ import annotations

import math
import statistics
import sys

from tools.heist_harness.report import run_batch

from tools.design_facts import DECISION_BAND, HOLD_BAND   # 13.2, 12.6 (D37)

#: §5.2 as written. v3.2 said 3 + realm level; v3.3 replaced the formula with
#: a measured budget, 8, 8, 6, 7 and 8 (F26), declared once in design_facts.
def SPEC(realm: int) -> int:
    from tools.design_facts import WARD_LIMITS            # 5.2 (D37)
    return WARD_LIMITS[realm - 1]


#: What F26 recorded, kept so the report can say what happened to it rather
#: than quietly dropping it. It is not the proposal under test.
RECORDED = {1: 10, 2: 8, 3: 6, 4: 7, 5: 8}

#: What the sweep found, at one geometry band and n=400. The register states
#: this figure in three places \u2014 F26's body, F26's recommendation and the
#: design-gates panel \u2014 and `check_edits.ward_budget_agrees` checks all
#: three against it, because a number with three homes is the register's own
#: subject.
MEASURED = {1: 11, 2: 8, 3: 6, 4: 7, 5: 8}

#: The ward counts to sweep. \u00a75.2 gives 4 to 8 across the five realms and
#: F26 records a need of 6 to 10, so the range runs past both ends \u2014 the
#: question is what a realm *needs*, not what \u00a75.2 permits. An island
#: built past \u00a75.2 records its own budget so it can never be mistaken for
#: a legal one (see `Island.ward_budget`), which is what makes the
#: counterfactual columns safe to measure.
WARDS = range(3, 13)

#: The geometry bands to sweep. \u00a713.4 permits nought to two.
#:
#: This was held fixed at the value `post_ladder.REALM_1` uses \u2014 two \u2014
#: and the first run of this file reported that no ward count reaches the bands
#: at realms 1 and 2. F26's own recommendation says why: *"that is why nothing
#: works at two geometry bands \u2026 the answer is one band with more wards
#: rather than the reverse."* The run had measured the configuration F26
#: already ruled out, and would have reported it as refuting F26.
#:
#: **A constant borrowed from another file is an assumption, not a setting.**
#: The band count is swept now, and which band count each realm's answer uses
#: is part of the answer.
BANDS = (0, 1, 2)

#: The depth and post count each realm uses: the depth §12.6's decision
#: target implies, and one post at every realm, as F26's sweep ran.
SETTINGS = {
    1: dict(depth=3, posts=1),
    2: dict(depth=3, posts=1),
    3: dict(depth=3, posts=1),
    4: dict(depth=2, posts=1),
    5: dict(depth=2, posts=1),
}

#: Which document's wards the sweep builds (island.RULES). F26 measured
#: v3.2's — every ward on its own tile — and v3.3 adopted its answer. Under
#: v3.3's sensor reach the ward count stops being a dial at all (F33): which
#: kinds a realm holds matters more than how many, so this sweep, which asks
#: "how many", is a v3.2 question and is kept as one.
RULES = "v3.2"


def measure(n: int, realm: int, depth: int, posts: int, bands: int,
            wards: int) -> tuple[float, float, float]:
    """Hold rate, its standard error, and the median decision count.

    ``links`` counts *crossing* realms, so a depth of three realms is
    ``links=2``. Reading it as the realm count inflates every hold rate by
    about fifteen points, which is how `generator_settings.py` started and why
    it says so in its own docstring.
    """
    # Without v3.3's crack noise, which swamps the wards it measures (F32).
    rs = run_batch(n, depth - 1, realm, "competent", laws="defensive",
                   shaped=bands, posts=posts, wards=wards, crack_noise=False,
                   rules=RULES)
    p = sum(1 for r in rs if not r.success) / len(rs)
    return (100 * p, 100 * math.sqrt(p * (1 - p) / len(rs)),
            statistics.median(r.crew_decisions for r in rs))


def inside(hold: float, dec: float) -> bool:
    return (HOLD_BAND[0] <= hold <= HOLD_BAND[1]
            and DECISION_BAND[0] <= dec <= DECISION_BAND[1])


def sweep(n: int, realm: int, refine: int) -> list[dict]:
    """Every ward count at every band count for one realm, cheap, then refine.

    A claim that *no* setting lands both bands is only as good as the nearest
    miss, so the sample is spent where the answer is close. `generator_settings`
    does the same and for the same reason.
    """
    cfg = SETTINGS[realm]
    rows = []
    for bands in BANDS:
        for wards in WARDS:
            hold, se, dec = measure(n, realm, wards=wards, bands=bands, **cfg)
            rows.append(dict(wards=wards, bands=bands, hold=hold, se=se, dec=dec))
    for row in rows:
        # Refine only what could still change its verdict. An earlier version
        # used a twelve-point margin, which caught most of the sweep and made
        # a forty-minute run out of a five-minute question: a cell forty points
        # outside is not going to move into the band at four times the sample.
        near = (HOLD_BAND[0] - 6 <= row["hold"] <= HOLD_BAND[1] + 6
                and DECISION_BAND[0] - 3 <= row["dec"] <= DECISION_BAND[1] + 3)
        if near:
            hold, se, dec = measure(refine, realm, wards=row["wards"],
                                    bands=row["bands"], **cfg)
            row.update(hold=hold, se=se, dec=dec, refined=True)
        row.setdefault("refined", False)
        row["ok"] = inside(row["hold"], row["dec"])
    return rows


#: The depths \u00a712.6's decision target implies, from F7: a heist carries
#: about 10 decisions across one realm, 17 across two, 24 across three.
DEPTHS = (2, 3)


def other_depth(n: int, realm: int, near: dict, wards: range) -> list[dict]:
    """The same realm at the other depth, for a realm no setting reaches.

    The ward axis and the post axis share a fault: both buy hold rate and
    decision count together, so neither can move one band without moving the
    other. Depth is the axis that is not like that \u2014 it sets the decision
    count almost by itself (F7) and leaves the hold rate to the defence \u2014
    so when a realm has no setting, the honest next question is whether it has
    one at a depth the matchmaker could send a crew to instead.

    Run around the nearest miss and at that miss's band count, so the only
    thing changing against the table above is the depth. Run only for the
    realms that need it: a sweep that measures every realm at every depth
    spends most of its sample confirming what the first table already settled.
    """
    cfg = dict(SETTINGS[realm])
    out = []
    for depth in DEPTHS:
        for count in wards:
            cfg["depth"] = depth
            hold, se, dec = measure(n, realm, wards=count,
                                    bands=near["bands"], **cfg)
            out.append(dict(depth=depth, wards=count, hold=hold, se=se,
                            dec=dec, ok=inside(hold, dec)))
    return out


def _why(row: dict) -> str:
    bits = []
    if not HOLD_BAND[0] <= row["hold"] <= HOLD_BAND[1]:
        bits.append("hold too low" if row["hold"] < HOLD_BAND[0] else "hold too high")
    if not DECISION_BAND[0] <= row["dec"] <= DECISION_BAND[1]:
        bits.append("too few decisions" if row["dec"] < DECISION_BAND[0]
                    else "too many decisions")
    return ", ".join(bits) or "inside both"


def report(n: int = 120, refine: int = 400):
    """Yields the report a line at a time, so a long sweep reports as it goes.

    Each realm's table is complete when its lines appear, which is what a
    reader watching a forty-minute run actually wants: not a progress bar,
    but the part of the answer that is already known.
    """
    yield "Which ward count puts each realm inside both of the document's bands?"
    yield ""
    yield (f"\u00a713.2 wants {HOLD_BAND[0]:.0f}-{HOLD_BAND[1]:.0f}% held; "
               f"\u00a719.27 wants {DECISION_BAND[0]}-{DECISION_BAND[1]} decisions. "
               f"Competent crew, sign-aware laws,")
    yield (f"{n} raids a cell and {refine} for the ones near a boundary, "
               f"marked +. \u00b1 is one standard error;")
    yield ("* marks the count \u00a75.2 gives that realm, r the count F26 "
               "recorded as its need.")
    yield ""

    found, missed = {}, {}
    for realm in sorted(SETTINGS):
        rows = sweep(n, realm, refine)
        good = [r for r in rows if r["ok"]]
        if good:
            found[realm] = [(r["bands"], r["wards"]) for r in good]
        else:
            missed[realm] = min(rows, key=lambda r: (
                0 if HOLD_BAND[0] <= r["hold"] <= HOLD_BAND[1]
                else min(abs(r["hold"] - HOLD_BAND[0]),
                         abs(r["hold"] - HOLD_BAND[1])) / 15.0)
                + (0 if DECISION_BAND[0] <= r["dec"] <= DECISION_BAND[1]
                   else min(abs(r["dec"] - DECISION_BAND[0]),
                            abs(r["dec"] - DECISION_BAND[1])) / 10.0))
        cfg = SETTINGS[realm]
        yield (f"  realm {realm} \u2014 {cfg['depth']} realms crossed, "
               f"{cfg['posts']} post")
        yield f"    {'bands':>5} {'wards':>6} {'hold':>16} {'dec':>4}   both?"
        for r in rows:
            mark = ("*" if r["wards"] == SPEC(realm) else " ") + \
                   ("r" if r["wards"] == RECORDED[realm] else " ")
            verdict = ("yes" if r["ok"] else "\u00b7") + ("+" if r["refined"] else "")
            yield (f"    {r['bands']:>5} {r['wards']:>4}{mark} "
                   f"{r['hold']:>10.1f}% \u00b1{r['se']:>3.1f} "
                   f"{r['dec']:>4.0f}   {verdict}")
        yield ""

    yield (f"  {len(found)} of {len(SETTINGS)} realms have a ward count "
               f"inside both bands.")
    for realm, counts in sorted(found.items()):
        note = "" if any(w == SPEC(realm) for _, w in counts) else \
            f"  \u2014 \u00a75.2 gives {SPEC(realm)} wards, which is not among them"
        yield f"    realm {realm}: {counts}{note}"
    if missed:
        yield ""
        yield "  Where no ward count works, the nearest miss:"
        for realm, r in sorted(missed.items()):
            yield (f"    realm {realm}: {r['wards']} wards, {r['bands']} band(s) "
                   f"\u2014 hold {r['hold']:.1f}% \u00b1{r['se']:.1f}, "
                   f"{r['dec']:.0f} decisions ({_why(r)})")

    if missed:
        yield ""
        yield ("  Depth is the axis wards and posts are not: it sets the decision "
               "count almost by itself")
        yield ("  (F7) and leaves the hold rate to the defence. For each realm "
               "with no ward count,")
        yield "  the same realm at both depths, around its nearest miss:"
        yield ""
        for realm in sorted(missed):
            near = missed[realm]["wards"]
            span = range(max(min(WARDS), near - 2), min(max(WARDS), near + 2) + 1)
            yield (f"    realm {realm} \u2014 {SETTINGS[realm]['posts']} post, "
                   f"{missed[realm]['bands']} band(s), around its nearest miss")
            yield (f"      {'realms':>7} {'wards':>6} {'hold':>16} {'dec':>4}"
                   f"   both?")
            solved = []
            for r in other_depth(refine // 2, realm, missed[realm], span):
                if r["ok"]:
                    solved.append((r["depth"], r["wards"]))
                verdict = "yes" if r["ok"] else "\u00b7"
                yield (f"      {r['depth']:>7} {r['wards']:>6} "
                       f"{r['hold']:>10.1f}% \u00b1{r['se']:>3.1f} "
                       f"{r['dec']:>4.0f}   {verdict}")
            if solved:
                yield (f"      <- realm {realm} is reachable after all, at "
                       f"{solved} (realms crossed, wards). The gap is the "
                       f"depth,")
                yield ("         which \u00a712.22's matchmaker does not "
                       "control (F13) \u2014 not the ward budget.")
            else:
                yield (f"      <- realm {realm} is out of reach on both depths "
                       f"as well as on every ward count.")
            yield ""

    yield ""
    yield "  Against what F26 recorded as the need:"
    for realm in sorted(SETTINGS):
        counts = found.get(realm)
        if counts is None:
            verdict = "no count works at all"
        elif any(w == RECORDED[realm] for _, w in counts):
            verdict = "confirmed"
        else:
            verdict = ("does not land the bands; (bands, wards) "
                       f"{counts} do")
        yield f"    realm {realm}: recorded {RECORDED[realm]} \u2014 {verdict}"


def self_test() -> int:
    """The three things this could get wrong, all of which something already has."""
    ok = True

    # 1. The ward override has to bite, or every column is the same column.
    few = measure(120, 1, wards=2, bands=1, **SETTINGS[1])
    many = measure(120, 1, wards=10, bands=1, **SETTINGS[1])
    print(f"  wards change the defence: 2 wards hold {few[0]:.1f}%, "
          f"10 hold {many[0]:.1f}%")
    if many[0] <= few[0]:
        print("    FAIL: the ward count had no effect, so nothing below means "
              "anything")
        ok = False

    # 2. §5.2's limit must be enforced when nothing overrides it, and lifted
    #    when something does — the counterfactual islands are legal only
    #    because they say so.
    from tools.heist_harness.island import generate
    try:
        generate(0, 1, shaped=2, posts=1, wards=None, rules=RULES)
        g = generate(0, 1, shaped=2, posts=1, wards=10, rules=RULES)
    except AssertionError as exc:
        print(f"    FAIL: a ward override was rejected: {exc}")
        return 1
    print(f"  an island built past §5.2 carries its budget: "
          f"ward_budget={g.ward_budget}, §5.2 would allow {SPEC(1)}")
    if g.ward_budget != 10:
        print("    FAIL: the override was not recorded on the island, so a "
              "counterfactual could be mistaken for a legal one")
        ok = False

    # 3. What F26 recorded has to differ from \u00a75.2 somewhere, or there is
    #    nothing for the sweep to disagree with.
    moved = [r for r in RECORDED if RECORDED[r] != SPEC(r)]
    print(f"  F26's recorded need differs from \u00a75.2 at realms {moved} and "
          f"agrees at {[r for r in RECORDED if r not in moved]}")
    if not moved:
        print("    FAIL: the recorded need is \u00a75.2, so there is nothing to check")
        ok = False

    # 4. The sweep has to cover \u00a75.2's own count and F26's recorded one at
    #    every realm. A realm could otherwise come back "no count works" while
    #    the working one was never tried \u2014 a negative result about a range
    #    nobody stated.
    outside = sorted({SPEC(r) for r in SETTINGS} | set(RECORDED.values())) 
    outside = [w for w in outside if w not in WARDS]
    print(f"  the sweep runs {min(WARDS)}\u2013{max(WARDS)} wards at "
          f"{list(BANDS)} geometry bands, covering \u00a75.2's "
          f"{sorted({SPEC(r) for r in SETTINGS})} and F26's "
          f"{sorted(set(RECORDED.values()))}")

    # 5. The band count must matter, or sweeping it is wasted sample — and the
    #    run that held it at two and reported F26 refuted would look the same.
    flat = measure(120, 1, wards=10, bands=0, **SETTINGS[1])
    two = measure(120, 1, wards=10, bands=2, **SETTINGS[1])
    print(f"  geometry bands change the defence at ten wards: "
          f"{flat[0]:.1f}% at 0 bands, {many[0]:.1f}% at 1, {two[0]:.1f}% at 2")
    if len({round(flat[0], 1), round(many[0], 1), round(two[0], 1)}) == 1:
        print("    FAIL: the band count had no effect, so sweeping it measures "
              "nothing")
        ok = False
    if outside:
        print(f"    FAIL: {outside} is outside the sweep, so the result would "
              f"be a claim about a range nobody stated")
        ok = False
    return 0 if ok else 1


def main() -> int:
    if "--self-test" in sys.argv:
        return self_test()
    args = [a for a in sys.argv[1:] if not a.startswith("--")]
    # Printed line by line and flushed, because the sweep takes minutes and a
    # job that prints nothing until it finishes cannot be told from a hung one
    # — which is the same lesson `generator_settings.validate_range` records
    # from the other end, where the failure came late instead of the output.
    for line in report(int(args[0]) if args else 120):
        print(line, flush=True)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
