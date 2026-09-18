#!/usr/bin/env python3
"""C3 as a table: what the three live rank statements cost, and whether the
rule behind the split survives the sheets it governs.

    python3 tools/law_ranks.py
    python3 tools/law_ranks.py --self-test

Why this exists
---------------
C3 has been open since the first audit and is one of the two gates still
blocking the Codex screen, because a screen that lists laws by rank cannot be
drawn until somebody says how many ranks there are. The register has described
it since v2.3 as a 345-page decision that means "re-tagging 14 laws and
re-deriving the page economy". Read out of v3.1 that is no longer what it is.

v3.1 moved §14.4 onto the sheets' own split — 18 common x 10 + 12 uncommon x 20
+ 6 rare x 35 + 12 deep x 60 = 1,350 pages — and the glossary (§7.1) and the
change log went with it. Two statements did not:

    §7.6   "Restoring a law: 15 pages for a common law, 30 for a rare one,
            60 for a deep one."           - three ranks, no Uncommon at all
    §7.9   a rank table counting 18 / 14 / 10 / 6

Everything else in the document is already on 18 / 12 / 6 / 12. So the decision
is not which taxonomy to build; it is which of two sentences to delete, and the
sheets, the page economy and the glossary have already voted. `splits()` prices
all three anyway, because a decision worth recording is worth showing the
alternatives to.

The part that is still a decision
---------------------------------
Underneath the arithmetic is the rule §7.9 exists to state, and it is the rule
rather than the counts that the Codex screen has to render:

    "rarity governs how long a law takes to get, while stability cost and
     conditions govern how strong it is. These are two dials, and the earlier
     version tied them together."

§7.1 restates it as a property of every law: "Rank sets how long a law takes to
acquire - not how strong it is (7.9)."

`principle()` tests that against the 48 sheets, and it does not hold. Rank
predicts stability cost at r = +0.80; in 88% of cross-rank pairs the rarer law
costs more. Rank predicts conditionality - the other dial §7.9 names - at
r = -0.04, which is nothing. The two dials are one dial, and it is the one
§7.9 says it must not be.

That is D31, and it is a content decision rather than a wording one, which is
why it is reported separately from the counts. Nothing here is written to
`content/laws.json`: the content files say what the document says, and this is
a measurement of them plus a proposal for it.
"""

import argparse
import collections
import itertools
import json
import pathlib
import re
import statistics
import sys

ROOT = pathlib.Path(__file__).resolve().parent.parent
CONTENT = ROOT / "content"

#: The rank ladder, cheapest first. Paradoxes sit outside it by §7.1's own
#: words ("with paradoxes outside the scale") and are not among the 48.
ORDER = ("Common", "Uncommon", "Rare", "Deep")

#: Every live statement of the split, with where it is said and what it prices.
#: `counts` is None where the statement gives prices without counts - §7.6 does
#: exactly that, which is half of why it survived four versions unnoticed.
SPLITS = {
    "sheets": dict(
        where="§7.7, the 48 authored law sheets, and §14.4's arithmetic",
        counts={"Common": 18, "Uncommon": 12, "Rare": 6, "Deep": 12},
        pages={"Common": 10, "Uncommon": 20, "Rare": 35, "Deep": 60},
    ),
    "7.9": dict(
        where="§7.9's rank table",
        counts={"Common": 18, "Uncommon": 14, "Rare": 10, "Deep": 6},
        pages={"Common": 10, "Uncommon": 20, "Rare": 35, "Deep": 60},
    ),
    "7.6": dict(
        where="§7.6's restore line, and §14.4 before v3.1",
        counts={"Common": 18, "Rare": 18, "Deep": 12},
        pages={"Common": 15, "Rare": 30, "Deep": 60},
    ),
}

#: §14.4's earning rates, which turn a page difference into days of play.
PAGES_PER_DAY_EARLY, PAGES_PER_DAY_LATE, EARLY_DAYS = 16, 23, 60

#: The starting laws (§7.6), which §14.4 excludes from the restore total.
STARTING_LAWS = 3

#: A law's own tier I text is the only place the document says what the law
#: does at the rank it is tagged with, so it is where a condition would be
#: stated. This is a proxy and is reported as one: the load-bearing number in
#: `principle()` is stability cost, which the sheets state outright.
CONDITION = re.compile(
    r"\b(if|when|while|whenever|only|inside|during|after|unless|standing|"
    r"carrying|below|above|anyone (?:in|on))\b", re.IGNORECASE)


def load_laws() -> list:
    return json.loads((CONTENT / "laws.json").read_text(encoding="utf-8"))


def pearson(a: list, b: list) -> float:
    ma, mb = statistics.mean(a), statistics.mean(b)
    num = sum((x - ma) * (y - mb) for x, y in zip(a, b))
    den = (sum((x - ma) ** 2 for x in a) * sum((y - mb) ** 2 for y in b)) ** 0.5
    return num / den if den else 0.0


def codex_pages(split: dict) -> int:
    """The full Codex at tier I, the way §14.4 computes it."""
    return sum(split["counts"][r] * split["pages"][r] for r in split["counts"])


def restore_pages(split: dict) -> int:
    """§14.4's convention: the total less the three commons a player starts with."""
    return codex_pages(split) - STARTING_LAWS * split["pages"]["Common"]


def days_to_restore(pages: int) -> int:
    """§14.4's own curve: 16 pages a day for 60 days, 23 a day after."""
    early = PAGES_PER_DAY_EARLY * EARLY_DAYS
    if pages <= early:
        return round(pages / PAGES_PER_DAY_EARLY)
    return EARLY_DAYS + round((pages - early) / PAGES_PER_DAY_LATE)


def retag_cost(split: dict, laws: list) -> int:
    """How many of the 48 sheets must change rank to reach this split.

    The minimum number of moves between two distributions is the sum of the
    positive differences - every law that has to arrive somewhere leaves
    somewhere else, so counting one side counts the moves.
    """
    have = collections.Counter(law["rank"] for law in laws)
    want = split["counts"]
    return sum(max(0, want[r] - have.get(r, 0)) for r in want)


def uneven_ranks(split: dict, schools: int = 6) -> list[str]:
    """The ranks this split cannot spread evenly over the six schools.

    §7.9 asserts the even spread twice inside its own table - Common "Three per
    school", Deep "One per school" - and once outside it: "Collecting is
    grouped by school, eight laws each". A count that does not divide by six
    cannot be spread evenly, whatever the table says about it.

    This returns the failing ranks rather than a yes/no, because which ranks
    fail is the argument. §7.9's two symmetric rows are exactly the two it
    makes the claim about; the two it says nothing about are the two that
    break it.
    """
    return [r for r, n in split["counts"].items() if n % schools]


def splits(laws: list) -> list[dict]:
    """C3. Each live statement of the split, priced and costed."""
    out = []
    for name, split in SPLITS.items():
        pages = codex_pages(split)
        out.append(dict(
            name=name,
            where=split["where"],
            ranks=len(split["counts"]),
            counts=split["counts"],
            total=sum(split["counts"].values()),
            pages=pages,
            restore=restore_pages(split),
            days=days_to_restore(restore_pages(split)),
            retag=retag_cost(split, laws),
            uneven=uneven_ranks(split),
        ))
    return out


def principle(laws: list) -> dict:
    """D31. §7.9's rule, measured against the sheets §7.9 governs.

    Two correlations and one pair count. The pair count is there because a
    correlation over four ordered labels is easy to argue with and "how often
    does the rarer law cost more" is not.
    """
    index = {r: i for i, r in enumerate(ORDER)}
    rows = [(index[law["rank"]], law["stability_cost"],
             len(CONDITION.findall(law["tier_1"])), law["name"])
            for law in laws]
    ranks = [r for r, _, _, _ in rows]
    pairs = [(a, b) for a, b in itertools.combinations(rows, 2) if a[0] != b[0]]
    dearer = sum(1 for a, b in pairs if (a[0] < b[0]) == (a[1] < b[1]))
    bands = {}
    for r in ORDER:
        costs = sorted(law["stability_cost"] for law in laws if law["rank"] == r)
        conds = [len(CONDITION.findall(law["tier_1"]))
                 for law in laws if law["rank"] == r]
        bands[r] = dict(n=len(costs), low=costs[0], median=statistics.median(costs),
                        high=costs[-1], conditions=statistics.mean(conds))
    return dict(
        cost_r=pearson(ranks, [c for _, c, _, _ in rows]),
        condition_r=pearson(ranks, [c for _, _, c, _ in rows]),
        pairs=len(pairs),
        dearer=dearer,
        bands=bands,
    )


def report(laws: list) -> None:
    rows = splits(laws)
    print("C3: three statements of one split, priced\n")
    print(f"  {'':<8}{'ranks':>6}{'total':>6}{'Codex':>8}{'restore':>9}"
          f"{'days':>6}{'re-tag':>8}   {'per school'}")
    for row in rows:
        print(f"  {row['name']:<8}{row['ranks']:>6}{row['total']:>6}"
              f"{row['pages']:>8,}{row['restore']:>9,}{row['days']:>6}"
              f"{row['retag']:>8}   "
              f"{'even' if not row['uneven'] else ', '.join(row['uneven']) + ' cannot'}")
    print()
    for row in rows:
        counts = ", ".join(f"{n} {r.lower()}" for r, n in row["counts"].items())
        print(f"  {row['name']:<8} {row['where']}")
        print(f"  {'':<8} {counts}")
    print()

    sheets = next(r for r in rows if r["name"] == "sheets")
    nine = next(r for r in rows if r["name"] == "7.9")
    six = next(r for r in rows if r["name"] == "7.6")
    spread = max(r["pages"] for r in rows) - min(r["pages"] for r in rows)
    days = (max(r["days"] for r in rows) - min(r["days"] for r in rows))
    print(f"  The spread is {spread} pages, about {days} days of engaged play at "
          f"§14.4's own rates.")
    print(f"  Only the sheets' split costs nothing to adopt: it is what the 48 "
          f"law sheets are")
    print(f"  already tagged with, and what §14.4 already computes "
          f"{sheets['pages']:,} from. Adopting")
    print(f"  §7.9's would move {nine['retag']} sheets; §7.6's would move "
          f"{six['retag']} and delete a rank the sheets use.\n")
    print(f"  §7.9's is also the only one of the three that cannot give every "
          f"school the same")
    print(f"  ladder: {' and '.join(nine['uneven'])} do not divide by six. Its "
          f"table asserts the even spread")
    print(f"  for the two ranks that do - Common \"Three per school\", Deep "
          f"\"One per school\" - and")
    print(f"  says nothing about the two that do not. The sheets give every "
          f"school 3 / 2 / 1 / 2.\n")

    p = principle(laws)
    print("D31: the rule behind the split, measured against the sheets\n")
    print('  §7.9: "rarity governs how long a law takes to get, while stability '
          'cost and')
    print('        conditions govern how strong it is. These are two dials, and '
          'the earlier')
    print('        version tied them together."\n')
    print(f"  {'rank':<10}{'n':>3}{'stability cost':>18}{'conditions':>12}")
    print(f"  {'':<10}{'':>3}{'low  med  high':>18}{'per law':>12}")
    for r in ORDER:
        b = p["bands"][r]
        print(f"  {r:<10}{b['n']:>3}{b['low']:>7}{b['median']:>5.0f}"
              f"{b['high']:>6}{b['conditions']:>12.2f}")
    print()
    print(f"  rank vs stability cost   r = {p['cost_r']:+.2f}   "
          f"{p['dearer']} of {p['pairs']} cross-rank pairs "
          f"({100 * p['dearer'] / p['pairs']:.0f}%) have the rarer law costing more")
    print(f"  rank vs conditions       r = {p['condition_r']:+.2f}   "
          f"the other dial §7.9 names, and rank does not move it")
    print()
    print("  So the two dials are one dial, and it is the one §7.9 says it must "
          "not be.")
    print("  §7.9's own remedy cannot fix this: \"the answer is more stability "
          "cost or a")
    print("  tighter condition\" - and raising a rare law's stability cost "
          "raises r = +0.80,")
    print("  which is the thing that is wrong.\n")
    print("  The mechanism §7.9 names as the primary reason the split is fair "
          "does not")
    print("  discriminate by rank either. \"every rare and deep law appears in "
          "the scout")
    print("  report (12.5)\" - the scout report is §12.4, and what it shows for "
          "20 Aether")
    print("  per realm is \"each realm's laws\", every rank alike, for 15 "
          "minutes. Visibility")
    print("  cannot be charged against a deep law's strength when a common law "
          "pays it too.")


def self_test() -> int:
    """Five cases, each one a way this could report the wrong thing."""
    ok = True

    def check(name: str, got, want) -> None:
        nonlocal ok
        good = got == want
        ok = ok and good
        print(f"  [{'ok ' if good else 'FAIL'}] {name}"
              f"{'' if good else f'  got {got!r}, want {want!r}'}")

    # §14.4 states this arithmetic in the document. If the sheets' split ever
    # stops reproducing it, one of the two has moved and the build should say so.
    check("the sheets' split reproduces §14.4's 1,350",
          codex_pages(SPLITS["sheets"]), 1350)
    check("§14.4's restore total, less the three starting commons",
          restore_pages(SPLITS["sheets"]), 1320)
    # C23 quotes the pre-v3.1 §14.4: 15 commons x 15 + 18 rares x 30 + 12 deep
    # x 60 = 1,485. That is the restore total, not the Codex total, because the
    # old convention also dropped the three starting laws.
    check("§7.6's split reproduces the 1,485 C23 quotes",
          restore_pages(SPLITS["7.6"]), 1485)
    # Every split must still be 48 laws: law_count is a frozen constant (§7.4).
    for name, split in SPLITS.items():
        check(f"{name} totals 48 laws", sum(split["counts"].values()), 48)
    # The re-tagging cost is the point of the table, and a split that equals
    # the sheets must cost nothing. An earlier version summed the absolute
    # differences and so reported every move twice.
    laws = load_laws()
    check("the sheets cost nothing to adopt", retag_cost(SPLITS["sheets"], laws), 0)
    check("§7.9's split moves six sheets", retag_cost(SPLITS["7.9"], laws), 6)
    # Only one of the three divides by six schools, which is the argument §7.9
    # makes and then breaks.
    # §7.6's 18/18/12 divides by six as well, so symmetry does not pick the
    # sheets out on its own - it rules §7.9's out. An earlier version of this
    # test asserted the stronger claim, and the report was written to match it.
    check("§7.9's split is the one that cannot spread evenly",
          {n: uneven_ranks(s) for n, s in SPLITS.items()},
          {"sheets": [], "7.9": ["Uncommon", "Rare"], "7.6": []})
    # D31's finding. A regression here means the sheets were re-costed, and
    # the register item is the thing to re-read, not this number.
    p = principle(laws)
    check("rank still predicts stability cost", round(p["cost_r"], 1), 0.8)
    check("rank still predicts nothing about conditions",
          abs(p["condition_r"]) < 0.15, True)
    return 0 if ok else 1


def main() -> int:
    ap = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    ap.add_argument("--self-test", action="store_true")
    args = ap.parse_args()
    if args.self_test:
        return self_test()
    report(load_laws())
    return 0


if __name__ == "__main__":
    sys.exit(main())
