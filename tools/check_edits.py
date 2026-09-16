#!/usr/bin/env python3
"""Check every edit in the audit register against the design document.

    python3 tools/check_edits.py

The register's `edits` field tells the owner what to type and where. That is only
useful if the text it quotes is actually in the document — an edit saying
"replace X with Y" where X does not exist is worse than no edit at all, because
it sends someone searching for a sentence nobody wrote.

So every `find` string is searched for verbatim, and a miss fails the build.
The same check catches the subtler case: a `find` that appears more than once,
which makes "replace it" ambiguous.
"""

import pathlib
import re
import sys

ROOT = pathlib.Path(__file__).resolve().parent.parent
sys.path.insert(0, str(ROOT / "tools"))
from audit_register import EDITS, REGISTER                          # noqa: E402

DOC = ROOT / "docs" / "design" / "ruleborn-game-design-v3.0.txt"
GENERATED = ROOT / "docs" / "design" / "generated"
CONTENT = ROOT / "content"
ACTIONS = {"replace", "delete", "insert", "regenerate", "retag"}

problems: list[str] = []


def normalise(text: str) -> str:
    """Curly quotes, dashes and runs of whitespace differ between the HTML export
    and anything typed by hand. Compare on the flattened form."""
    text = (text.replace("’", "'").replace("‘", "'")
                .replace("“", '"').replace("”", '"')
                .replace("—", "-").replace("–", "-")
                .replace("×", "x"))
    return re.sub(r"\s+", " ", text).strip()


def duplicate_keys() -> list:
    """Duplicate keys in the V3 and EDITS literals, which Python silently drops.

    `{"C20": a, "C20": b}` is legal and keeps only the second, so the register
    can lose an entry with no error anywhere. Once the module is imported the
    evidence is gone, so this reads the source.
    """
    import ast
    tree = ast.parse((ROOT / "tools" / "audit_register.py").read_text(encoding="utf-8"))
    out = []
    for node in ast.walk(tree):
        if not isinstance(node, ast.Assign):
            continue
        names = [t.id for t in node.targets if isinstance(t, ast.Name)]
        if not names or not isinstance(node.value, ast.Dict):
            continue
        seen = set()
        for key in node.value.keys:
            if not isinstance(key, ast.Constant):
                continue
            if key.value in seen:
                out.append(f"{names[0]} has {key.value!r} twice — Python keeps the "
                           f"second and drops the first silently")
            seen.add(key.value)
    return out


def main() -> int:
    if not DOC.exists():
        print(f"{DOC} is missing — run tools/extract_design_doc.py", file=sys.stderr)
        return 1
    haystack = normalise(DOC.read_text(encoding="utf-8"))

    import json
    laws = {law["name"]: law for law in
            json.loads((CONTENT / "laws.json").read_text(encoding="utf-8"))}
    creatures = {c["name"]: c for c in
                 json.loads((CONTENT / "ruleborn.json").read_text(encoding="utf-8"))}

    problems.extend(duplicate_keys())

    known = {i["id"] for i in REGISTER}
    for item_id in EDITS:
        if item_id not in known:
            problems.append(f"EDITS names {item_id}, which is not in the register")

    total = sum(len(v) for v in EDITS.values())

    for item_id, edits in EDITS.items():
        for n, edit in enumerate(edits, 1):
            where = f"{item_id} edit {n}"
            action = edit.get("action")
            if action not in ACTIONS:
                problems.append(f"{where}: action {action!r} is not one of "
                                f"{', '.join(sorted(ACTIONS))}")
                continue
            if not edit.get("section"):
                problems.append(f"{where}: no section")
            if action == "retag":
                target = edit.get("target", "")
                current = edit.get("find", "")
                law, creature = laws.get(target), creatures.get(target)
                if law is None and creature is None:
                    problems.append(f"{where}: retags {target!r}, which is not a "
                                    f"law or a ruleborn in content/")
                elif law is not None:
                    have = " ".join(law["notes"])
                    if have != current:
                        problems.append(f"{where}: says {target} carries "
                                        f"{current!r}; content/laws.json has "
                                        f"{have!r}")
                else:
                    # content/ruleborn.json carries §11.11's reading as `role` and
                    # §11.2's as `alt_11_2`, because both are in the document and
                    # C6 is that they disagree. An edit to §11.2 must quote
                    # §11.2's value, not the one it is being changed to.
                    if edit["section"].startswith("11.2"):
                        have = (creature.get("alt_11_2") or {}).get("role") \
                            or creature.get("role")
                    else:
                        have = creature.get("role")
                    if have != current:
                        problems.append(f"{where}: says \u00a7{edit['section']} "
                                        f"gives {target} as {current!r}; content/ "
                                        f"has {have!r}")
                continue
            if action == "regenerate":
                name = edit.get("from_", edit.get("from", ""))
                if not (GENERATED / name).exists():
                    problems.append(f"{where}: names {name}, which is not in "
                                    f"docs/design/generated/")
                continue
            if action in ("replace", "delete") and not edit.get("find"):
                problems.append(f"{where}: {action} with nothing to find")
                continue
            if action == "replace" and not edit.get("replace"):
                problems.append(f"{where}: replace with no replacement")
            needle = normalise(edit.get("find", ""))
            if not needle:
                continue
            hits = haystack.count(needle)
            if hits == 0:
                problems.append(f"{where}: §{edit['section']} — the document does "
                                f"not contain {needle[:70]!r}")
            elif hits > 1 and action != "insert":
                problems.append(f"{where}: §{edit['section']} — {needle[:50]!r} "
                                f"appears {hits} times, so \"replace it\" is ambiguous")

    # Coverage. The six clerical items fixed in v3.0 went on being reported as
    # open for a version, because the first pass over the new document checked
    # the six blocking items and not this batch. An item with an edit is
    # re-checked here every build; an item without one is checked by nobody.
    from audit_register import FOUND_IN_V3, V3
    def status(item):
        return V3.get(item["id"], {}).get("status") or item.get("status", "open")

    uncovered = [i["id"] for i in REGISTER
                 if i["kind"] in ("contradiction", "gap")
                 and status(i) not in ("fixed", "done", "adopted")
                 and i["id"] not in EDITS]

    # The same gap one level up. Six clerical contradictions and one decision
    # went on being reported open after v3.0 had settled them, because the sweep
    # over the new document covered the category that was on my mind and not the
    # others. An item with no V3 note has not been read against the current
    # version by anybody.
    unread = [i["id"] for i in REGISTER
              if i["kind"] != "deviation"
              and status(i) not in ("done", "adopted")
              and i["id"] not in V3
              and i["id"] not in FOUND_IN_V3]

    print(f"\nChecked {total} edits across {len(EDITS)} register items against "
          f"{DOC.name}.\n")
    if unread:
        print(f"  {len(unread)} items have no note saying what v3.0 did about "
              f"them, so nothing")
        print(f"  records whether they were read against the current version: "
              f"{', '.join(sorted(unread))}")
        print("  Not a failure — a to-do list.\n")
    if uncovered:
        print(f"  {len(uncovered)} open conflicts carry no edit, so nothing "
              f"re-checks them against")
        print(f"  the document: {', '.join(sorted(uncovered))}")
        print("  Not a failure — a to-do list. Drafting an edit is what puts an "
              "item under\n  this check.\n")
    if problems:
        print(f"{len(problems)} edits do not match the document:\n")
        for p in problems:
            print(f"  ✗ {p}")
        print()
        return 1
    print("  every quoted sentence is in the document, exactly once.\n")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
