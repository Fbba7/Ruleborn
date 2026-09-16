#!/usr/bin/env python3
"""Which register numbers can be shown to be current, and which cannot.

    python3 tools/check_findings_fresh.py
    python3 tools/check_findings_fresh.py --self-test

Why this exists
---------------
The register is the project's source of truth and most of it is numbers. Those
numbers came out of the heist harness, and the harness has been wrong three
times in one session — D24's two-second Vault phase, D25's clock nobody read,
D26's guards all starting at the same waypoint. Each fix moved every result the
harness produces.

Some items say in prose when they were measured. Most do not, and prose is not
checkable: a reader cannot tell whether "geometry is 4.4% of the defence" was
measured before or after the fault that changed every share.

D28's lesson, turned on the register itself: **a number that cannot be shown to
be stale will be trusted for ever.** So an item that quotes a harness figure
carries `measured=`, the harness fingerprint it was measured against, and this
compares that against the fingerprint the harness has now.

What it does not do
-------------------
It cannot re-measure anything, and it does not try. It reports a backlog, the
way `check_edits.py` reports items without a drafted edit: not a failure, a list
of numbers nobody can currently vouch for. Marking an item `measured=` is a
claim that it was re-run, and it is only as honest as whoever typed it.
"""

import pathlib
import re
import sys

ROOT = pathlib.Path(__file__).resolve().parent.parent
sys.path.insert(0, str(ROOT / "tools"))

#: Set on an item whose numbers came out of the harness but whose provenance
#: nobody can reconstruct. Honest, and it keeps the item on the list.
UNKNOWN = "unknown"


def current_fingerprint() -> str:
    """The digest `test_the_harness_gives_the_same_answers_as_when_it_was_last_read`
    asserts. That test exists so a change in results is never silent; this reads
    the same value so the two can never disagree about what "now" means."""
    text = (ROOT / "tools" / "heist_harness" / "test_harness.py").read_text(
        encoding="utf-8")
    found = re.search(r'assert digest == "([0-9a-f]{64})"', text)
    if not found:
        raise SystemExit(
            "the harness fingerprint is not where this check expects it. Look in "
            "tools/heist_harness/test_harness.py for the digest assertion.")
    return found.group(1)


def quotes_the_harness(item: dict) -> bool:
    """Does this item rest on a number the harness produced?

    Deliberately broad. A false positive costs one line of `measured=`; a false
    negative is a stale number nobody is looking at.
    """
    text = (item.get("body", "") + item.get("rec", "")).lower()
    return any(s in text for s in ("heist_harness", "the harness", "simulated",
                                   "raids a cell", "runs a cell", "a coalition"))


def main() -> int:
    from audit_register import REGISTER

    now = current_fingerprint()
    if "--self-test" in sys.argv:
        # The check has to be able to fail, or it has never been shown to work.
        if not re.fullmatch(r"[0-9a-f]{64}", now):
            print("  the fingerprint read back is not a digest.")
            return 1
        fake = dict(id="X", body="measured over 300 raids a cell in the harness",
                    rec="", measured="0" * 64)
        if not quotes_the_harness(fake):
            print("  an item quoting the harness was not recognised as one.")
            return 1
        if fake["measured"] == now:
            print("  a deliberately stale fingerprint compared equal to the live one.")
            return 1
        print("  the freshness check can tell a stale fingerprint from the live one.")
        return 0

    rests = [i for i in REGISTER if quotes_the_harness(i)]
    fresh = [i for i in rests if i.get("measured") == now]
    stale = [i for i in rests if i.get("measured") not in (None, UNKNOWN, now)]
    undated = [i for i in rests if i.get("measured") in (None, UNKNOWN)]

    print(f"\nThe harness fingerprint is {now[:16]}.")
    print(f"{len(rests)} register items rest on a number it produced.\n")
    print(f"  {len(fresh):>3} measured against this harness")
    print(f"  {len(stale):>3} measured against an older one")
    print(f"  {len(undated):>3} with no recorded provenance")

    if stale:
        print("\n  Measured against a harness that has since changed — re-run "
              "before quoting:")
        for i in stale:
            print(f"    {i['id']:5} {i['title'][:64]}")
    if undated:
        print("\n  No provenance recorded, so nobody can say whether these are "
              "current:")
        for i in undated:
            print(f"    {i['id']:5} {i['title'][:64]}")
        print("\n  Not a failure — a to-do list. Re-run the item, then set "
              "measured= to the\n  fingerprint above. Three harness faults in one "
              "session is why this exists.")
    print()
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
