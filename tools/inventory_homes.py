#!/usr/bin/env python3
"""Every place the document states a launch-inventory count.

    python3 tools/inventory_homes.py
    python3 tools/inventory_homes.py --self-test

Why this exists
---------------
§26.1 is the project's statement of scope, and it is not where the numbers
live. The forms count appears in nine sections, the law count in fifteen. They
all agree, which is why nobody has looked: F25's point is that a fact with two
homes is found by reading only *after* it has diverged.

`check_document.check_launch_inventory` guards §26.1's rows,
`check_screen_counts` guards §23.2's must-show cells, and
`check_inventory_summaries` guards the six sections that state several counts
at once, and `check_every_inventory_mention` reads every remaining number the
document puts beside a content table's own noun. This prints all of them, so
the net is visible rather than asserted: which sections are read structurally,
which are read as a number, and which of the eleven partials each one is.

What it is for
--------------
D6 proposes cutting the forms from 144 to 54 and Q5 is the decision under it.
**This is the list of sections that edit would have to touch.** The forms
count has nine homes and §26.1 is one of them, so a cut made by finding the
launch table would leave eight sections stating the old number.

A *partial* is a count of part of the thing — §7.6's "12 laws are findable
from the start", §14.9's "All 8 forms of one ruleborn". They are listed
separately rather than filtered, because the difference between a partial and
a stale total is a reading, not a pattern, and a list nobody re-reads is the
thing this repository keeps finding.
"""

import argparse
import collections
import pathlib
import re
import sys

ROOT = pathlib.Path(__file__).resolve().parent.parent
sys.path.insert(0, str(ROOT / "tools"))
import check_document                                             # noqa: E402
from check_document import PARTIAL                                 # noqa: E402
from design_doc import HTML                                       # noqa: E402

#: Sections read by a check of their own, and which one.
#: ``check_every_inventory_mention`` reads every other mention in the
#: document, so nothing here is unguarded any more \u2014 these are the ones
#: something also checks *structurally*, row by row or cell by cell, rather
#: than as a number beside a noun.
GUARDED = {
    "26.1": "check_launch_inventory, row by row",
    "23.2": "check_screen_counts, every must-show cell",
    "19.13": "check_inventory_summaries", "26.8": "check_inventory_summaries",
    "27.2": "check_inventory_summaries", "30.6": "check_inventory_summaries",
    "30.8": "check_inventory_summaries", "30.11": "check_inventory_summaries",
}

#: Kinds whose count the prose never states, so §26.1 is its only home.
#: This is the shape §31.2 asks for, and it is worth naming because it is
#: rare: of eleven inventories, one.
ONLY_IN_LAUNCH_TABLE = {
    "eras": "§18.3 lists all eight by name and never counts them, so "
            "§26.1 is the only place the number 8 appears",
}


def homes(doc) -> dict:
    """kind -> {section: [(number, the line it is on)]}, totals and partials."""
    counts = check_document.inventory()
    out: dict = {}
    for kind, (_, noun) in counts.items():
        found = collections.defaultdict(list)
        for m in re.finditer(r"(?<![.\d])\b(\d+)\s+(?:" + noun + r")\b", doc.text):
            # "11.7 Sages, the heroes" is a heading, and its 7 is a section
            # number. Anything preceded by a dot and a digit is one.
            sec = check_document.section_at(doc, m.start())
            line = doc.text[doc.text.rfind("\n", 0, m.start()) + 1:
                            doc.text.find("\n", m.end())]
            found[sec].append((int(m.group(1)), line.strip().lstrip("| ").strip()))
        out[kind] = dict(found)
    return out


def report(doc) -> int:
    counts = check_document.inventory()
    found = homes(doc)
    rows = dict(check_document.launch_table(doc))

    print("Every section stating a launch-inventory count, and whether a "
          "check reaches it.\n")
    unguarded_total = 0
    for kind in sorted(found, key=lambda k: -len(found[k])):
        want = counts[kind][0]
        totals = {s: v for s, v in found[kind].items()
                  if any(n == want for n, _ in v)}
        partials = {s: v for s, v in found[kind].items() if s not in totals}
        # §26.1 states the count as a bare cell, so the noun scan misses it.
        in_launch = any(str(want) in rows.get(label, "")
                        for label, k in check_document.LAUNCH_ROWS.items()
                        if k == kind)
        homes_n = len(totals) + (1 if in_launch else 0)
        loose = [s for s in totals if s not in GUARDED]
        unguarded_total += len(loose)
        only = ONLY_IN_LAUNCH_TABLE.get(kind)
        print(f"  {kind} = {want}  — {homes_n} home"
              f"{'' if homes_n == 1 else 's'}, "
              f"{len(loose)} read as a number only")
        if only:
            print(f"      one home only: {only}")
        if in_launch:
            print(f"      §26.1   guarded ({GUARDED['26.1']})")
        for sec in sorted(totals):
            tag = (f"{GUARDED[sec]}" if sec in GUARDED
                   else "the number only (check_every_inventory_mention)")
            print(f"      §{sec:<7} {tag}")
        for sec in sorted(partials):
            why = PARTIAL.get((kind, sec))
            nums = sorted({n for n, _ in partials[sec]})
            print(f"      §{sec:<7} partial: "
                  f"{why or 'UNCLASSIFIED — read it'} {nums}")
        print()

    undeclared = [(kind, sec) for kind, secs in found.items() for sec in secs
                  if not any(n == counts[kind][0] for n, _ in secs[sec])
                  and (kind, sec) not in PARTIAL]
    print(f"  Every mention above is checked. {unguarded_total} of them are "
          f"read as a number\n  beside a noun and nothing more, so a count "
          f"moved into prose the scan does not\n  recognise would still be "
          f"invisible \u2014 that is what this report is for.")
    print(f"  {len(undeclared)} partial mentions are unclassified"
          f"{': ' + str(undeclared[:6]) if undeclared else ''}.")
    print("\n  Not a failure. A second home is a fault only when the two "
          "disagree or\n  when one is edited alone — and this is the list "
          "of sections an edit to\n  any of these counts has to visit. D6's "
          "cut of the forms to 54 is the\n  live example.")
    return 0


def self_test() -> int:
    """Every declared partial must still be one, and every kind must be found."""
    ok = True
    doc = check_document.Doc(str(HTML))
    counts = check_document.inventory()
    found = homes(doc)

    def check(name, got, want):
        nonlocal ok
        good = got == want
        ok = ok and good
        print(f"  [{'ok ' if good else 'FAIL'}] {name}"
              f"{'' if good else f'  got {got!r}, want {want!r}'}")

    check("every content kind is either stated in the prose or declared as "
          "living only in 26.1",
          sorted(k for k, v in found.items()
                 if not v and k not in ONLY_IN_LAUNCH_TABLE), [])
    check("every kind declared as living only in 26.1 really does",
          sorted(k for k in ONLY_IN_LAUNCH_TABLE if found.get(k)), [])
    # A declared partial that no longer states a non-total is an exemption
    # doing no work, which is how a list like this stops describing anything.
    idle = [(k, s) for (k, s) in PARTIAL
            if s not in found.get(k, {})
            or all(n == counts[k][0] for n, _ in found[k][s])]
    check("every declared partial is still a partial in the document", idle, [])
    # And every guarded section must really be guarded by the named check.
    names = set(dir(check_document))
    bad = sorted({g.split(",")[0] for g in GUARDED.values()} - names)
    check("every check named in GUARDED exists", bad, [])
    return 0 if ok else 1


def main() -> int:
    ap = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    ap.add_argument("--self-test", action="store_true")
    args = ap.parse_args()
    if args.self_test:
        return self_test()
    return report(check_document.Doc(str(HTML)))


if __name__ == "__main__":
    raise SystemExit(main())
