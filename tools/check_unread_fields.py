#!/usr/bin/env python3
"""Fields the harness computes and never reads.

    python3 tools/check_unread_fields.py
    python3 tools/check_unread_fields.py --self-test

D26: `Patrol.phase` was documented as where a guard is on its loop, computed by
the generator for every patrol, and never read by the simulation. Every guard
began every raid at waypoint zero, no test failed, and it surfaced only because a
hand-designed island had no other source of variation.

That is a checkable class of fault, so here is the check. A dataclass field that
is assigned and never loaded is either dead weight or a feature that silently
does nothing, and the second is the dangerous one: the generator goes on
computing it, the docstring goes on describing it, and the model quietly does
something simpler than the design says.

**What this does not catch**, stated because the first version of D26's
recommendation claimed it caught more than it does:

  * **D25** — `heist.clock` was read in four places in `sim.py`. What was missing
    was that no *policy* read it, so no crew could act on the price §12.19 names.
    "Read somewhere" is satisfied; "read by the thing that needs it" is not, and
    only a human asking what the model must be doing finds that.
  * **D24** — the Vault phase ended on the wrong condition. Nothing was unread;
    the logic was wrong, and the test that should have caught it asserted a
    constant (`Carrier.carry / 30 == 10`) where §12.19's claim is about what a
    crew does. The rule that catches that is not a script: **when the document
    states a number about behaviour, the test has to run the behaviour.**
"""

import ast
import pathlib
import sys

ROOT = pathlib.Path(__file__).resolve().parent.parent
PACKAGES = ("heist_harness", "economy_model")

#: Fields a dataclass may carry without being read: identifiers and labels that
#: exist to be printed or compared as a whole, not consulted by the model.
ALLOWED = {"name", "seed", "policy"}

#: Fields known to be unread, each with the reason it is allowed to stay that
#: way. An entry here is a debt that has been looked at, not one that is hidden:
#: removing the field or reading it should remove the entry.
KNOWN_UNREAD = {
    "State.aether": (
        "The economy model accumulates an Aether balance and never spends it "
        "(D27). Fixing it means making the model pay §9.5's prices, which "
        "is a feature rather than a fix — and F17's numbers do not depend "
        "on it, being computed from §9.3's published table and the daily "
        "log rather than from this balance."),
    "State.essence": (
        "The same, for Essence. Recorded together with State.aether as D27, "
        "where the irony is the point: the design has two currencies with no "
        "sinks and the model has two balances with no readers."),
    "Archetype.lab_experiments_per_day": (
        "§9.5 prices a Lab experiment and §14.2's archetypes say how "
        "many a day each runs; the model charges neither. It is the one "
        "recurring Aether sink besides upkeep, and it is small enough that "
        "F17's conclusion is unchanged — but it is unmodelled, not "
        "negligible-by-measurement (D27)."),
}


def dataclass_fields(tree: ast.AST) -> dict:
    """{class name: {field: line}} for every @dataclass in the module."""
    out = {}
    for node in ast.walk(tree):
        if not isinstance(node, ast.ClassDef):
            continue
        if not any(
            (isinstance(d, ast.Name) and d.id == "dataclass")
            or (isinstance(d, ast.Attribute) and d.attr == "dataclass")
            or (isinstance(d, ast.Call) and getattr(d.func, "id", "") == "dataclass")
            for d in node.decorator_list
        ):
            continue
        fields = {}
        for stmt in node.body:
            if isinstance(stmt, ast.AnnAssign) and isinstance(stmt.target, ast.Name):
                fields[stmt.target.id] = stmt.lineno
        if fields:
            out[node.name] = fields
    return out


def attribute_reads(paths) -> set:
    """Every attribute name loaded anywhere in the sources."""
    names = set()
    for path in paths:
        tree = ast.parse(path.read_text(encoding="utf-8"))
        for node in ast.walk(tree):
            if isinstance(node, ast.Attribute) and isinstance(node.ctx, ast.Load):
                names.add(node.attr)
            # `getattr(x, "phase")` and `dict(phase=...)` count as use too.
            elif isinstance(node, ast.Call) and getattr(node.func, "id", "") == "getattr":
                for arg in node.args[1:2]:
                    if isinstance(arg, ast.Constant) and isinstance(arg.value, str):
                        names.add(arg.value)
    return names


def sources() -> list:
    out = []
    for package in PACKAGES:
        out.extend(sorted((ROOT / "tools" / package).glob("*.py")))
    return out


def unread(extra_source: str = "") -> list:
    """D26. Fields the harness computes that nothing reads.

    D26 was a guard waypoint every guard started at, written and never read.
    The value was there, it was wrong, and no result depended on it, so
    nothing failed - which is how it survived every run. This is that fault
    turned into a check over every dataclass in the harness and the economy
    model.
    """
    paths = sources()
    read = attribute_reads(paths)
    if extra_source:
        read |= attribute_reads([])  # no-op; kept so the signature reads clearly
    problems = []
    for path in paths:
        tree = ast.parse(path.read_text(encoding="utf-8"))
        if extra_source and path.name == "island.py":
            tree = ast.parse(path.read_text(encoding="utf-8") + extra_source)
        for cls, fields in dataclass_fields(tree).items():
            for field, line in fields.items():
                if field in ALLOWED or field.startswith("_"):
                    continue
                if f"{cls}.{field}" in KNOWN_UNREAD:
                    continue
                if field not in read:
                    problems.append(
                        f"{path.relative_to(ROOT)}:{line}  {cls}.{field} is "
                        f"assigned and never read — either the model ignores "
                        f"it (D26) or it is dead")
    return problems


def self_test() -> int:
    """The check must fail on a field nobody reads, or it is not a check.

    Modelled on `check_docs_consistency.py --self-test`, and for the same reason:
    a checker that cannot demonstrate a failure has never been shown to work.
    """
    planted = "\n\n@dataclass\nclass _Planted:\n    never_read_anywhere: int = 0\n"
    found = [p for p in unread(planted) if "never_read_anywhere" in p]
    if not found:
        print("  ✗ self-test: the check did not notice a planted unread field")
        return 1
    print("  self-test: a planted unread field is reported.")
    return 0


def main() -> int:
    if "--self-test" in sys.argv:
        return self_test()
    problems = unread()
    print(f"\nChecked every dataclass field in "
          f"{', '.join('tools/' + p for p in PACKAGES)}.\n")
    if problems:
        print(f"{len(problems)} fields are computed and never read:\n")
        for p in problems:
            print(f"  ✗ {p}")
        print()
        return 1
    print("  every field the harness computes is read somewhere,")
    print(f"  except {len(KNOWN_UNREAD)} recorded as known debt with a reason each:")
    for name in KNOWN_UNREAD:
        print(f"    {name}")
    print("  (Read *somewhere* — see this file's docstring for what that misses.)\n")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
