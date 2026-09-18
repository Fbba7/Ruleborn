#!/usr/bin/env python3
"""Which laws a launch can drop, costed by what each one needs from the engine.

    python3 tools/scope_cut.py            # the report
    python3 tools/scope_cut.py --size 24  # cost a particular launch size

Why this exists
---------------
D6 proposes launching with 24 laws rather than §26.1's 48, and Q5 is the owner's
decision on it. F10 measured what makes that saving real or fake: **16 of the 48
are parameter changes and 32 need an engine feature**, so which 24 you drop
matters far more than that you drop 24. §26.1 costed all of them as content.

Two things then have to be checked before any cut is proposed, and neither has
been:

  * **§8.5's chords.** A chord needs three distinct laws carrying three named
    notes. Cut the wrong laws and a chord becomes unreachable — and §8.5 calls
    chords "the late-game discovery", so an unreachable one is a hole in the
    end of the game that would not show up for months.
  * **§7.7's eight per school.** Six schools, eight laws each. A cost-driven cut
    does not respect that on its own.

What the costs are, and what they are not
-----------------------------------------
The weights below are a judgement about engineering effort, not a measurement,
and they are stated here rather than buried so they can be argued with. What the
report is for is the *shape*: how much a cost-aware cut saves over an arbitrary
one, and which constraint actually binds. That conclusion is robust to the
weights; the absolute numbers are not.

  parameter  0  The rule sheet already has the number. This is what §7.3 claims
                every law is.
  attribute  1  One field on the creature table, plus the plumbing to read it.
                §12.21 names three and C26 records that no table carries them.
  event      2  A periodic or conditional rule inside the tick loop, which has
                to stay deterministic (§24.7).
  authored   2  A choice the realm's owner makes that is not a number: an editor
                affordance, and a rule for the generator to make it on their
                behalf (F12).
  entity     3  The simulation must spawn, track and render an object it
                otherwise has no reason to know about, deterministically.
"""

import argparse
import collections
import json
import pathlib

ROOT = pathlib.Path(__file__).resolve().parent.parent
COST = {"parameter": 0, "attribute": 1, "event": 2, "authored": 2, "entity": 3}
SCHOOLS = ("Motion", "Matter", "Time", "Energy", "Life", "Spirit")


def load():
    laws = json.loads((ROOT / "content" / "law_effects.json")
                      .read_text(encoding="utf-8"))["laws"]
    chords = json.loads((ROOT / "content" / "chords.json").read_text(encoding="utf-8"))
    for law in laws:
        law["cost"] = sum(COST[k] for k in law["kinds"])
    return laws, chords


def reachable(chord, kept) -> bool:
    """§8.8: the realm holds three distinct laws, and their notes carry the chord.

    Not the same as three laws each contributing a note, which is what this
    function asserted in its first draft and is a stricter rule than the document
    states. If two laws already carry all three notes, any third law completes the
    realm and the chord forms. That difference *is* D14: §8.8 changed the rule
    from three notes to three distinct laws in order to make chords late-game, and
    because 23 of the 48 laws carry two notes it did not make them much harder.
    A checker that quietly enforced the stricter rule would have hidden that.
    """
    want = set(chord["notes"])
    carriers = [set(law["notes"]) & want for law in kept]
    carriers = [c for c in carriers if c]
    if len(kept) < 3:
        return False
    # The fewest laws that together carry the chord's notes must be at most three.
    for i in range(len(carriers)):
        if carriers[i] == want:
            return True
        for j in range(i + 1, len(carriers)):
            if carriers[i] | carriers[j] == want:
                return True
            for k in range(j + 1, len(carriers)):
                if carriers[i] | carriers[j] | carriers[k] == want:
                    return True
    return False


def unreachable(chords, kept) -> list:
    return [c["name"] for c in chords if not reachable(c, kept)]


def per_school(size: int) -> int:
    return size // len(SCHOOLS)


def choose(laws, chords, size: int) -> list:
    """The cheapest `size` laws that keep every chord reachable and every school
    equally stocked. Greedy by cost within each school, then repaired."""
    quota = per_school(size)
    kept = []
    for school in SCHOOLS:
        pool = sorted((law for law in laws if law["school"] == school),
                      key=lambda law: (law["cost"], law["name"]))
        kept.extend(pool[:quota])

    # Repair: while a chord is unreachable, swap the costliest kept law in some
    # school for the cheapest dropped law in that school that fixes a chord.
    for _ in range(len(laws)):
        missing = [c for c in chords if not reachable(c, kept)]
        if not missing:
            break
        dropped = [law for law in laws if law not in kept]
        best = None
        for cand in sorted(dropped, key=lambda law: (law["cost"], law["name"])):
            same = [law for law in kept if law["school"] == cand["school"]]
            for out in sorted(same, key=lambda law: (-law["cost"], law["name"])):
                trial = [law for law in kept if law is not out] + [cand]
                if len(unreachable(chords, trial)) < len(missing):
                    gain = len(missing) - len(unreachable(chords, trial))
                    price = cand["cost"] - out["cost"]
                    if best is None or (-gain, price) < best[0]:
                        best = ((-gain, price), cand, out)
        if best is None:
            break
        _, cand, out = best
        kept = [law for law in kept if law is not out] + [cand]
    return kept


def smallest_reaching_every_chord(laws, chords) -> tuple[int, int]:
    """The fewest laws that reach all twelve chords, two ways.

    The true minimum over every subset, and the minimum when laws are taken
    cheapest-first. The first says whether §8.5 can constrain a cut at all; the
    second says whether it constrains the cut anyone would actually make.

    Exhaustive up to six laws, which is enough: covering the eight notes needs at
    least four laws, since no law carries more than two.
    """
    import itertools
    best = len(laws)
    for size in range(3, 7):
        for combo in itertools.combinations(laws, size):
            if not unreachable(chords, list(combo)):
                best = size
                break
        if best == size:
            break
    cheap = len(laws)
    ordered = sorted(laws, key=lambda law: (law["cost"], law["name"]))
    for size in range(3, len(laws) + 1):
        if not unreachable(chords, ordered[:size]):
            cheap = size
            break
    return best, cheap


def report(size: int) -> str:
    laws, chords = load()
    out = ["Costing a launch-scope cut (D6, Q5, F10)", ""]
    kinds = collections.Counter(k for law in laws for k in law["kinds"])
    out.append(f"All {len(laws)} laws cost {sum(law['cost'] for law in laws)} points "
               f"of engine work: " + ", ".join(
                   f"{n} {k}" for k, n in sorted(kinds.items())))
    out.append("")

    floor, cheap_floor = smallest_reaching_every_chord(laws, chords)
    out.append(f"  §8.5's twelve chords are all reachable from as few as {floor} laws "
               f"chosen well,")
    out.append(f"  and from the {cheap_floor} cheapest taken blindly. **Chords cannot "
               f"constrain a cut to {size}**")
    out.append(f"  — it is §7.7's six schools that set the floor, not the chord table.")
    out.append("")

    kept = choose(laws, chords, size)
    naive = sorted(laws, key=lambda law: (law["rank"], law["name"]))[:size]
    for label, chosen in (("cost-aware", kept), ("by rank, ignoring cost", naive)):
        cost = sum(law["cost"] for law in chosen)
        miss = unreachable(chords, chosen)
        by_school = collections.Counter(law["school"] for law in chosen)
        param = sum(1 for law in chosen if law["kinds"] == ["parameter"])
        out.append(f"  {label:<24} {len(chosen)} laws, {cost:>3} points, "
                   f"{param} of them pure parameter changes")
        out.append(f"  {'':<24} schools {dict(by_school)}")
        out.append(f"  {'':<24} chords unreachable: "
                   + (", ".join(miss) if miss else "none"))
        out.append("")

    saved = sum(law["cost"] for law in naive) - sum(law["cost"] for law in kept)
    out.append(f"  Choosing the {size} by engine cost rather than by rank saves "
               f"{saved} points,")
    out.append(f"  which is {saved / max(1, sum(law['cost'] for law in naive)):.0%} "
               f"of the naive cut's engine work, for the same number of laws.")
    return "\n".join(out)


def self_test() -> int:
    """F23. Pin F23 and the cut, all of it exact rather than sampled.

    Nothing here draws a sample, so unlike the harness's findings these assert
    values and not bands. If one fails, the content changed under the finding.
    """
    import itertools
    laws, chords = load()

    # F23: four is the floor, and it is reached.
    if not any(not unreachable(chords, list(c))
               for c in itertools.combinations(laws, 4)):
        print("  no four laws reach all twelve chords; F23 is stale.")
        return 1
    if any(not unreachable(chords, list(c))
           for c in itertools.combinations(laws, 3)):
        print("  three laws now reach all twelve chords, which cannot happen "
              "while the wheel has eight notes and a law carries two.")
        return 1

    # The cut: cheaper, chord-safe, and evenly stocked.
    kept = choose(laws, chords, 24)
    naive = sorted(laws, key=lambda law: (law["rank"], law["name"]))[:24]
    if sum(law["cost"] for law in kept) >= sum(law["cost"] for law in naive):
        print("  the cost-aware cut is no cheaper than the rank-ordered one.")
        return 1
    if unreachable(chords, kept):
        print(f"  the cost-aware cut loses chords: {unreachable(chords, kept)}")
        return 1
    schools = collections.Counter(law["school"] for law in kept)
    if set(schools) != set(SCHOOLS) or len(set(schools.values())) != 1:
        print(f"  the cost-aware cut does not stock the schools evenly: {dict(schools)}")
        return 1

    print(f"  4 laws reach all 12 chords, 3 cannot; a cost-aware 24 costs "
          f"{sum(law['cost'] for law in kept)} against {sum(law['cost'] for law in naive)}.")
    return 0


def main() -> int:
    ap = argparse.ArgumentParser(description=__doc__)
    ap.add_argument("--size", type=int, default=24)
    ap.add_argument("--self-test", action="store_true")
    args = ap.parse_args()
    if args.self_test:
        return self_test()
    print(report(args.size))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
