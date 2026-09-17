#!/usr/bin/env python3
"""Which ward count, if any, puts each realm inside both of the document's bands?

    python3 -m tools.ward_budget [n]
    python3 -m tools.ward_budget --self-test

F26 found that §13.2's 30-45% hold band and §19.27's 15-25 decisions cannot
both be met at realm 1 by any setting §5.2 and §10.2 permit, and that the one
dial with enough resolution to close it is the ward count. It recorded a
measured need of **10, 8, 6, 7, 8** wards at realms 1 to 5, against §5.2's
``3 + realm level`` — 4, 5, 6, 7, 8.

**Those two numbers do not survive being run as a proposal.** Measured at the
settings each realm would ship with, ten wards at realm 1 holds 52.8% and
carries 27 decisions — over the top of both bands, not inside them — and eight
at realm 2 holds 53.6% with 28. They were read off a sweep one realm at a time
and never run as the table they claim to be, which is what this file is for:
a budget is a table a player moves through, and each row has to be checked at
the settings that row actually uses.

So the recorded numbers are not tested here; the whole range is swept, and what
comes back is the ward count each realm needs or the fact that none exists.
Where none does, the nearest miss and its direction are the finding, because a
band that cannot be reached from either side is a different problem from a
tuning miss and has a different fix — which is F26's own point, one dial down.

Two rules this inherits. **A fix that breaks the realms that work is not a
fix**: realms 3 to 5 satisfy both bands today on §5.2's own count, and the
sweep has to reproduce that. And **`links` counts crossing realms**, so three
realms is ``links=2``; reading it as the realm count inflates every hold rate
by about fifteen points.
"""


from __future__ import annotations

import math
import statistics
import sys

from tools.heist_harness.report import run_batch

HOLD_BAND = (30.0, 45.0)
DECISION_BAND = (15, 25)

#: §5.2 as written: a realm at level L holds 3 + L wards.
def SPEC(realm: int) -> int:
    return 3 + realm


#: What F26 recorded, kept so the report can say what happened to it rather
#: than quietly dropping it. It is not the proposal under test.
RECORDED = {1: 10, 2: 8, 3: 6, 4: 7, 5: 8}

#: The ward counts to sweep. §5.2 gives 4 to 8 across the five realms; the
#: range runs past both ends because the question is what the realm *needs*,
#: not what §5.2 permits — an island built past §5.2 records its own budget so
#: it can never be mistaken for a legal one (see `Island.ward_budget`).
WARDS = range(2, 15)

#: The settings each realm's best island uses, from F26's sweep: the depth its
#: decision count needs and the post count §10.2 gives it. Held fixed so the
#: only thing moving down a realm's column is the ward count.
SETTINGS = {
    1: dict(depth=3, posts=1, bands=2),
    2: dict(depth=3, posts=1, bands=2),
    3: dict(depth=3, posts=1, bands=1),
    4: dict(depth=2, posts=1, bands=1),
    5: dict(depth=2, posts=1, bands=1),
}


def measure(n: int, realm: int, depth: int, posts: int, bands: int,
            wards: int) -> tuple[float, float, float]:
    """Hold rate, its standard error, and the median decision count.

    ``links`` counts *crossing* realms, so a depth of three realms is
    ``links=2``. Reading it as the realm count inflates every hold rate by
    about fifteen points, which is how `generator_settings.py` started and why
    it says so in its own docstring.
    """
    rs = run_batch(n, depth - 1, realm, "competent", laws="defensive",
                   shaped=bands, posts=posts, wards=wards)
    p = sum(1 for r in rs if not r.success) / len(rs)
    return (100 * p, 100 * math.sqrt(p * (1 - p) / len(rs)),
            statistics.median(r.crew_decisions for r in rs))


def inside(hold: float, dec: float) -> bool:
    return (HOLD_BAND[0] <= hold <= HOLD_BAND[1]
            and DECISION_BAND[0] <= dec <= DECISION_BAND[1])


def sweep(n: int, realm: int, refine: int) -> list[dict]:
    """Every ward count at one realm, cheap, then the near ones properly.

    A claim that *no* count lands both bands is only as good as the nearest
    miss, so the sample is spent where the answer is close. `generator_settings`
    does the same and for the same reason.
    """
    cfg = SETTINGS[realm]
    rows = []
    for wards in WARDS:
        hold, se, dec = measure(n, realm, wards=wards, **cfg)
        rows.append(dict(wards=wards, hold=hold, se=se, dec=dec))
    for row in rows:
        near = (HOLD_BAND[0] - 12 <= row["hold"] <= HOLD_BAND[1] + 12
                and DECISION_BAND[0] - 5 <= row["dec"] <= DECISION_BAND[1] + 5)
        if near:
            hold, se, dec = measure(refine, realm, wards=row["wards"], **cfg)
            row.update(hold=hold, se=se, dec=dec, refined=True)
        row.setdefault("refined", False)
        row["ok"] = inside(row["hold"], row["dec"])
    return rows


def _why(row: dict) -> str:
    bits = []
    if not HOLD_BAND[0] <= row["hold"] <= HOLD_BAND[1]:
        bits.append("hold too low" if row["hold"] < HOLD_BAND[0] else "hold too high")
    if not DECISION_BAND[0] <= row["dec"] <= DECISION_BAND[1]:
        bits.append("too few decisions" if row["dec"] < DECISION_BAND[0]
                    else "too many decisions")
    return ", ".join(bits) or "inside both"


def report(n: int = 120, refine: int = 400) -> str:
    out = ["Which ward count puts each realm inside both of the document's bands?", ""]
    out.append(f"\u00a713.2 wants {HOLD_BAND[0]:.0f}-{HOLD_BAND[1]:.0f}% held; "
               f"\u00a719.27 wants {DECISION_BAND[0]}-{DECISION_BAND[1]} decisions. "
               f"Competent crew, sign-aware laws,")
    out.append(f"{n} raids a cell and {refine} for the ones near a boundary, "
               f"marked +. \u00b1 is one standard error;")
    out.append("* marks the count \u00a75.2 gives that realm, r the count F26 "
               "recorded as its need.")
    out.append("")

    found, missed = {}, {}
    for realm in sorted(SETTINGS):
        rows = sweep(n, realm, refine)
        good = [r for r in rows if r["ok"]]
        if good:
            found[realm] = [r["wards"] for r in good]
        else:
            missed[realm] = min(rows, key=lambda r: (
                0 if HOLD_BAND[0] <= r["hold"] <= HOLD_BAND[1]
                else min(abs(r["hold"] - HOLD_BAND[0]),
                         abs(r["hold"] - HOLD_BAND[1])) / 15.0)
                + (0 if DECISION_BAND[0] <= r["dec"] <= DECISION_BAND[1]
                   else min(abs(r["dec"] - DECISION_BAND[0]),
                            abs(r["dec"] - DECISION_BAND[1])) / 10.0))
        cfg = SETTINGS[realm]
        out.append(f"  realm {realm} \u2014 {cfg['depth']} realms crossed, "
                   f"{cfg['posts']} post, {cfg['bands']} band(s)")
        out.append(f"    {'wards':>7} {'hold':>16} {'dec':>4}   both?")
        for r in rows:
            mark = ("*" if r["wards"] == SPEC(realm) else " ") + \
                   ("r" if r["wards"] == RECORDED[realm] else " ")
            verdict = ("yes" if r["ok"] else "\u00b7") + ("+" if r["refined"] else "")
            out.append(f"    {r['wards']:>5}{mark} {r['hold']:>10.1f}% "
                       f"\u00b1{r['se']:>3.1f} {r['dec']:>4.0f}   {verdict}")
        out.append("")

    out.append(f"  {len(found)} of {len(SETTINGS)} realms have a ward count "
               f"inside both bands.")
    for realm, counts in sorted(found.items()):
        note = "" if SPEC(realm) in counts else \
            f"  \u2014 \u00a75.2 gives {SPEC(realm)}, which is not among them"
        out.append(f"    realm {realm}: {counts}{note}")
    if missed:
        out.append("")
        out.append("  Where no ward count works, the nearest miss:")
        for realm, r in sorted(missed.items()):
            out.append(f"    realm {realm}: {r['wards']} wards \u2014 "
                       f"hold {r['hold']:.1f}% \u00b1{r['se']:.1f}, "
                       f"{r['dec']:.0f} decisions ({_why(r)})")

    out.append("")
    out.append("  Against what F26 recorded as the need:")
    for realm in sorted(SETTINGS):
        counts = found.get(realm)
        if counts is None:
            verdict = "no count works at all"
        elif RECORDED[realm] in counts:
            verdict = "confirmed"
        else:
            verdict = f"does not land the bands; {counts} do"
        out.append(f"    realm {realm}: recorded {RECORDED[realm]} \u2014 {verdict}")
    return "\n".join(out)


def self_test() -> int:
    """The three things this could get wrong, all of which something already has."""
    ok = True

    # 1. The ward override has to bite, or every column is the same column.
    few = measure(120, 1, wards=2, **SETTINGS[1])
    many = measure(120, 1, wards=10, **SETTINGS[1])
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
        generate(0, 1, shaped=2, posts=1, wards=None)
        g = generate(0, 1, shaped=2, posts=1, wards=10)
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
    print(f"  the sweep runs {min(WARDS)}\u2013{max(WARDS)} wards, covering "
          f"\u00a75.2's {sorted({SPEC(r) for r in SETTINGS})} and F26's "
          f"{sorted(set(RECORDED.values()))}")
    if outside:
        print(f"    FAIL: {outside} is outside the sweep, so the result would "
              f"be a claim about a range nobody stated")
        ok = False
    return 0 if ok else 1


def main() -> int:
    if "--self-test" in sys.argv:
        return self_test()
    args = [a for a in sys.argv[1:] if not a.startswith("--")]
    print(report(int(args[0]) if args else 120))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
