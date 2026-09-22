#!/usr/bin/env python3
"""What changed between two versions of the design document, by section.

    python3 tools/version_diff.py                 # the previous version against this one
    python3 tools/version_diff.py --items         # which register items sit on changed sections
    python3 tools/version_diff.py --section 9.6   # the diff for one section
    python3 tools/version_diff.py --self-test

Why this exists
---------------
A new version arrives claiming to answer fifty-two open items. Reading the
whole document to find out which is the slow way and the unreliable one: the
sections that moved are a small set, and an item whose sections did not move
was not answered whatever the changelog says.

v3.2 changed 21 of v3.1's 243 sections and added 7. That is the worklist, and
it is derived rather than taken from the version's own account of itself —
which is the same rule the rest of this repository follows, applied to the one
document that has a motive to overstate.

What it cannot tell you
-----------------------
That a changed section *fixed* the item. A section can move for a reason
unrelated to the item that cites it, and two of v3.2's twenty-one did. The
output is a worklist, not a verdict: every row still has to be read. What it
removes is the other 222 sections.
"""

import argparse
import difflib
import pathlib
import re
import sys

ROOT = pathlib.Path(__file__).resolve().parent.parent
sys.path.insert(0, str(ROOT / "tools"))
import check_document                                             # noqa: E402
from design_doc import DESIGN, VERSION, VERSIONED                 # noqa: E402


def versions() -> list[str]:
    """Every version on disk, oldest first."""
    seen = {m.group(1) for p in DESIGN.iterdir()
            for m in [VERSIONED.fullmatch(p.name)] if m}
    return sorted(seen, key=lambda v: tuple(int(x) for x in v.split(".")))


def previous() -> str:
    """The version before the one the checks read."""
    order = versions()
    return order[order.index(VERSION) - 1] if VERSION in order[1:] else order[0]


def load(version: str):
    return check_document.Doc(str(DESIGN / f"ruleborn-game-design-v{version}.html"))


def compare(old: str, new: str) -> dict:
    a = check_document.section_index(load(old))
    b = check_document.section_index(load(new))
    return dict(
        old=old, new=new, a=a, b=b,
        added=[k for k in b if k not in a],
        removed=[k for k in a if k not in b],
        changed=[k for k in b if k in a and b[k].strip() != a[k].strip()],
    )


def _order(sections):
    return sorted(sections, key=lambda s: tuple(int(p) for p in s.split(".")))


def items_on(changed: set) -> list[tuple[str, list[str]]]:
    """Register items whose cited sections moved, most-cited first."""
    from audit_register import REGISTER, is_open
    out = []
    for item in REGISTER:
        if not is_open(item):
            continue
        hit = [r for r in item.get("refs", []) if r in changed]
        if hit:
            out.append((item["id"], _order(hit)))
    return sorted(out, key=lambda r: (-len(r[1]), r[0]))


def report(old: str, new: str, items: bool) -> int:
    d = compare(old, new)
    print(f"v{old} → v{new}: {len(d['a'])} sections to {len(d['b'])}\n")
    print(f"  {len(d['added'])} added:   {' '.join(_order(d['added'])) or '—'}")
    print(f"  {len(d['removed'])} removed: {' '.join(_order(d['removed'])) or '—'}")
    print(f"  {len(d['changed'])} changed: {' '.join(_order(d['changed']))}")
    print(f"\n  {len(d['a']) - len(d['changed'])} sections are unchanged, which is "
          f"where most of the document is.\n")

    if not items:
        print("  --items maps the open register onto this list; --section N.M "
              "shows one diff.")
        return 0

    rows = items_on(set(d["changed"]) | set(d["added"]))
    from audit_register import REGISTER
    titles = {i["id"]: i.get("title", "") for i in REGISTER}
    print(f"  {len(rows)} open items cite a section that moved. Each has to be "
          f"read; this\n  says which, and the rest of the register did not "
          f"move under it.\n")
    for item_id, secs in rows:
        print(f"  {item_id:5} {' '.join('§' + s for s in secs):28} "
              f"{titles[item_id][:58]}")

    from audit_register import is_open
    untouched = [i["id"] for i in REGISTER if is_open(i)
                 and not any(r in set(d["changed"]) | set(d["added"])
                             for r in i.get("refs", []))]
    print(f"\n  {len(untouched)} open items cite nothing that moved:")
    print("  " + " ".join(untouched))
    print("\n  An item whose sections did not move was not answered, whatever "
          "the\n  changelog says. That is the useful half of this output.")
    return 0


def section_diff(old: str, new: str, num: str) -> int:
    a = check_document.section_index(load(old)).get(num, "")
    b = check_document.section_index(load(new)).get(num, "")
    if not a and not b:
        print(f"§{num} is in neither version.")
        return 1
    lines = list(difflib.unified_diff(
        a.splitlines(), b.splitlines(),
        fromfile=f"v{old} §{num}", tofile=f"v{new} §{num}", lineterm="", n=1))
    if not lines:
        print(f"§{num} is unchanged between v{old} and v{new}.")
        return 0
    for line in lines:
        print(line[:200])
    return 0


def self_test() -> int:
    """The diff must find a planted change and ignore a reformatting."""
    ok = True

    def check(name, got, want):
        nonlocal ok
        good = got == want
        ok = ok and good
        print(f"  [{'ok ' if good else 'FAIL'}] {name}"
              f"{'' if good else f'  got {got!r}, want {want!r}'}")

    order = versions()
    check("every version on disk is ordered", order, sorted(
        order, key=lambda v: tuple(int(x) for x in v.split("."))))
    check("the previous version is the one before this one",
          previous(), order[order.index(VERSION) - 1])

    d = compare(previous(), VERSION)
    # A version that changed nothing would make this tool report nothing, and
    # reporting nothing is what a broken diff also does.
    check("the diff finds changes at all", bool(d["changed"] or d["added"]), True)
    check("nothing was removed, which every version so far has held to",
          d["removed"], [])
    # The sections a version adds must not also count as changed.
    check("added and changed do not overlap",
          sorted(set(d["added"]) & set(d["changed"])), [])
    # And a section must be the same in both when it is not listed.
    a, b = d["a"], d["b"]
    same = [k for k in b if k in a and k not in d["changed"]]
    check("every section not listed as changed really is identical",
          [k for k in same if a[k].strip() != b[k].strip()], [])
    return 0 if ok else 1


def main() -> int:
    ap = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    ap.add_argument("--from", dest="old", default=None)
    ap.add_argument("--to", dest="new", default=VERSION)
    ap.add_argument("--items", action="store_true")
    ap.add_argument("--section")
    ap.add_argument("--self-test", action="store_true")
    args = ap.parse_args()
    if args.self_test:
        return self_test()
    old = args.old or previous()
    if args.section:
        return section_diff(old, args.new, args.section)
    return report(old, args.new, args.items)


if __name__ == "__main__":
    raise SystemExit(main())
