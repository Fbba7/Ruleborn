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

Two kinds of provenance, and the stronger one is free
----------------------------------------------------
`measured=` is a one-off: someone re-ran the item and typed the fingerprint in.
It is only as honest as whoever typed it, and it goes stale the moment the
harness moves again.

**A test is better.** Where a test in the harness suite asserts a finding, that
finding is re-checked on every build, and it cannot silently drift — the build
goes red instead. So a test that pins an item opens its docstring with the item's
id, and this reads that rather than keeping a second list: the link lives in the
one place that already has to be right.

What it does not do
-------------------
It cannot re-measure anything, and it does not try. It reports a backlog, the
way `check_edits.py` reports items without a drafted edit: not a failure, a list
of numbers nobody can currently vouch for.
"""

import pathlib
import re
import sys


def plain(text: str) -> str:
    """Register titles carry inline markup; this is for a terminal."""
    return re.sub(r"<[^>]+>", "", text)


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


#: Files that are not checks and must not be scanned for pins.
NOT_CHECKS = ("__pycache__", "vendor")


def check_files() -> list[pathlib.Path]:
    """Every check in this repository, not only the harness suite."""
    return sorted(p for p in (ROOT / "tools").rglob("*.py")
                  if not any(part in NOT_CHECKS for part in p.parts))


def pinned_by_a_check() -> dict:
    """Which register items a check in this repository asserts.

    The convention the suite already follows: a function that exists to pin a
    finding opens its docstring with that finding's id, as in `F20. Section 9.6
    pays grade x fill...`. Parsing it keeps one list instead of two, which is
    the rule this repository applies to everything else it generates.

    **This used to read one file.** It opened `heist_harness/test_harness.py`
    and nothing else, because the findings it was written for came out of the
    harness. Every check written since lives somewhere else, so four items were
    reported as having no provenance while a check asserted each of them:
    `check_document.check_twice_stated` pins C27, `law_effects.generator_report`
    pins F12, and two economy-model tests pin C2 and F17. A provenance report
    that looks in one place reports the part it can see, which is the fault it
    exists to catch, committed inside it.
    """
    out: dict = {}
    for path in check_files():
        text = path.read_text(encoding="utf-8")
        for m in re.finditer(r'\ndef (\w+)\([^)]*\)[^:]*:\n\s+"""([^\n]*)', text):
            # A check may assert more than one finding, and several do:
            # `law_effects.classify` is both F10's count and D22's table. The
            # lead is therefore a list, not a single id.
            lead = LEAD.match(m.group(2).strip())
            if lead:
                for item in re.findall(r"[CDFGQT]\d{1,2}", lead.group(1)):
                    out.setdefault(item, []).append(f"{path.name}:{m.group(1)}")
    return out


#: The ids a docstring opens with. A list, because a check may assert more than
#: one finding - `law_effects.classify` is both F10's count and D22's table -
#: and ending on a word boundary rather than on punctuation, because the
#: convention in the suite includes the possessive: `F16's own caveat, which
#: the finding could not settle without this`. An earlier version of this
#: pattern required a full stop or a space and silently dropped that pin, which
#: is this file's own subject: a check that stops asserting something reads
#: exactly like a check that never did.
LEAD = re.compile(r"((?:[CDFGQT]\d{1,2})(?:,\s*[CDFGQT]\d{1,2})*)\b")


#: A register item that names a tool rests on a number that tool produced, and
#: the tool can move. `tools/x.py` and `tools/x/` both count.
NAMES_A_TOOL = re.compile(r"tools/([a-z_]+)(?:\.py|/)")


def rests_on_a_tool(item: dict) -> list[str]:
    """Which tools an item's own text says its numbers came from.

    Broader than `quotes_the_harness` and for the same reason the register
    exists: a number produced by `law_ranks.py` or `ability_text.py` is exactly
    as unverifiable in prose as one produced by the harness, and there are
    almost three times as many of them.
    """
    text = item.get("body", "") + item.get("rec", "")
    return sorted(set(NAMES_A_TOOL.findall(text)))


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
        # The four shapes the suite's docstrings actually use. The possessive
        # is the one that broke: tightening this pattern once dropped F16's pin
        # without dropping F16 from the report, so the report simply said the
        # finding had no provenance.
        shapes = {
            "F20. Section 9.6 pays grade x fill": ["F20"],
            "F16's own caveat, which the finding could not settle": ["F16"],
            "F10, D22. Every law written down as the kind of change": ["F10", "D22"],
            "C27 - two rules for partial staffing": ["C27"],
            "The clock follows 5.4": [],
        }
        for text, want in shapes.items():
            got = re.findall(r"[CDFGQT]\d{1,2}", m.group(1)) if (
                m := LEAD.match(text)) else []
            if got != want:
                print(f"  the docstring lead {text!r} read as {got}, want {want}")
                return 1
        print(f"  and all {len(shapes)} docstring lead shapes are read the same way.")
        # The scan must reach past the harness. It read one file until four
        # checks elsewhere were reported as asserting nothing.
        files = {f.name for f in check_files()}
        if len(files) < 5 or "law_effects.py" not in files:
            print(f"  the scan reaches {len(files)} file(s), not the whole of tools/.")
            return 1
        outside = {k: v for k, v in pinned_by_a_check().items()
                   if not any("test_harness" in n for n in v)}
        if not outside:
            print("  no pin was found outside the harness suite, so the scan is "
                  "still reading one file.")
            return 1
        print(f"  the scan covers {len(files)} files and finds "
              f"{len(outside)} pin(s) outside the harness suite.")
        return 0

    pinned = pinned_by_a_check()
    rests = [i for i in REGISTER if quotes_the_harness(i)]
    tested = [i for i in rests if i["id"] in pinned]
    rest = [i for i in rests if i["id"] not in pinned]
    fresh = [i for i in rest if i.get("measured") == now]
    stale = [i for i in rest if i.get("measured") not in (None, UNKNOWN, now)]
    undated = [i for i in rest if i.get("measured") in (None, UNKNOWN)]

    print(f"\nThe harness fingerprint is {now[:16]}.")
    print(f"{len(rests)} register items rest on a number it produced.\n")
    print(f"  {len(tested):>3} pinned by a test, so re-checked on every build")
    print(f"  {len(fresh):>3} re-measured once against this harness")
    print(f"  {len(stale):>3} measured against an older harness")
    print(f"  {len(undated):>3} with no provenance at all")

    if tested:
        print("\n  Pinned by a test — these cannot drift without the build going "
              "red:")
        for i in tested:
            print(f"    {i['id']:5} {', '.join(pinned[i['id']])}")

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
        print("\n  Not a failure — a to-do list, and the better way to clear it "
              "is a test\n  that pins the finding rather than a fingerprint typed "
              "in once. Three\n  harness faults in one session is why this exists.")

    # And the same question asked of every tool, not only the harness.
    on_tools = [(i, rests_on_a_tool(i)) for i in REGISTER if rests_on_a_tool(i)]
    held = [(i, t) for i, t in on_tools if i["id"] in pinned]
    loose = [(i, t) for i, t in on_tools if i["id"] not in pinned]
    print(f"\n{len(on_tools)} register items rest on a number some tool in this "
          f"repository produced.")
    print(f"  {len(held):>3} pinned by a check that names them")
    print(f"  {len(loose):>3} resting on a tool with nothing asserting the "
          f"number")
    if loose:
        print("\n  Nothing asserts these, so the tool can move and the register "
              "will not know:")
        for i, tools in loose:
            print(f"    {i['id']:5} {', '.join(tools):<28} "
                  f"{plain(i['title'])[:50]}")
        print("\n  To clear one, open a function's docstring in that tool with "
              "the item's id.\n  The check is then read off the code rather "
              "than listed twice.")
    print()
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
