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
from audit_register import EDITS, REGISTER, V3, V31                  # noqa: E402

DOC = ROOT / "docs" / "design" / "ruleborn-game-design-v3.1.txt"
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


#: Section references in register prose that cannot resolve and are meant not
#: to, with a reason each. The pattern is check_unread_fields.py's KNOWN_UNREAD:
#: an entry here is debt somebody has looked at, not debt nobody has noticed.
KNOWN_UNRESOLVABLE = {
    ("D2", "25.5"): "deliberate: the sentence is about what v2.3's §25.5 said, "
                    "and names §25.4 as its replacement in the same breath",
}


def dangling_prose_sections(doc: str) -> list:
    """Every §N and §N.M written in register prose must resolve.

    `refs` lists and edit sections were already checked. The prose was not, and
    it holds 678 references — by far the largest surface. v3.1's renumbering
    left 37 of them pointing at sections that no longer existed, and they were
    found by hand rather than by anything running.

    Chapters are read from the document's own chapter headings rather than from
    the prefixes of subsection numbers. Chapter 4 has no subsections, so a set
    built from "N.M" prefixes does not contain it and four true references to
    §4 look broken — which is what the first version of this did.
    """
    sections = set(re.findall(r"^(\d+\.\d+) ", doc, re.M))
    chapters = set(re.findall(r"^(\d+)[A-Z]", doc, re.M))

    out = []

    def scan(item_id: str, field: str, text: str) -> None:
        for ref in re.findall(r"\u00a7(\d+(?:\.\d+)?)", text or ""):
            resolves = ref in sections if "." in ref else ref in chapters
            if resolves or (item_id, ref) in KNOWN_UNRESOLVABLE:
                continue
            out.append(f"{item_id}: {field} cites \u00a7{ref}, which is not a "
                       f"section or chapter of the document")

    for item in REGISTER:
        for field in ("title", "body", "rec"):
            scan(item["id"], field, item.get(field, ""))
    for name, table in (("v3.0 note", V3), ("v3.1 note", V31)):
        for item_id, entry in table.items():
            scan(item_id, name, entry.get("note", ""))
    return out


def dangling_sections(doc: str) -> list:
    """Every section an edit or an item names must exist in the document.

    Nothing checked this before, and the register had eight items and two edits
    pointing at sections v3.1 had renumbered away — §5.9, §7.10, §10.5 and
    §25.5. The quoted sentences still matched, because v3.1 moved the numbers
    and not the text, so `check_edits.py` reported everything green while the
    register's own navigation was broken.

    That is the register committing the fault it exists to record: a fact — here
    "where this lives" — written in two places, one of which moved. It is also
    why a renumbering is never only clerical.
    """
    sections = set(re.findall(r"^(\d+\.\d+) ", doc, re.M))
    out = []
    for item_id, edits in EDITS.items():
        for n, edit in enumerate(edits, 1):
            if edit["section"] not in sections:
                out.append(f"{item_id} edit {n}: names §{edit['section']}, which is "
                           f"not a section of the document")
    for item in REGISTER:
        for ref in item.get("refs", []):
            if re.fullmatch(r"\d+\.\d+", ref) and ref not in sections:
                out.append(f"{item['id']}: refs §{ref}, which is not a section of "
                           f"the document")
    return out


#: Why an open item carries no drafted edit. T1.3's rule is that an item
#: without an edit is checked by nobody, so every exception is named here
#: rather than re-reasoned each time somebody counts them.
#:
#: "covered by X" means the sentence this item wants changed is already quoted
#: by X's edit. Drafting a second copy would be the register committing the
#: fault it exists to record — one fact, two homes — so the link is the right
#: answer and the check enforces that X really does carry an edit.
NO_EDIT_BECAUSE = {
    "F9":  "covered by F11",    # both ask §13.3 to state the hold-rate band
    "F10": "covered by G10",    # both ask §12.21 to list the rule sheet
    "F19": "covered by F14",    # both are about §9.6's 0.46
    "F23": "covered by D14",    # both are about §8.5's chord gate
    "D13": "covered by C25",    # the note rebalance is C25's ten edits
    "F16": "no document sentence: the fix is the generator, in spec/generator.md",
    "F24": "no document sentence: the fix is the checker, and half of it is built",
    "F25": "no document sentence: the fix is the six items that have two homes",
    "D6":  "a proposal to the owner, not a document fault",
    "D9":  "a proposal to the owner, not a document fault",
    "D16": "a proposal awaiting sign-off; it becomes an edit when accepted",
    "D17": "a proposal awaiting sign-off; it becomes an edit when accepted",
    "D20": "a record of what v3.0 did, not something to change",
}


def unexplained_missing_edits() -> list:
    """Every open item either carries an edit or says why it does not.

    Decisions are exempt: a Q item is the owner's to make and has no sentence
    to draft. Everything else open or proposed needs an edit or an entry in
    NO_EDIT_BECAUSE, and a "covered by X" entry is only honest if X has one.
    """
    from audit_register import V3, V31

    def status(item):
        return (V31.get(item["id"], {}).get("status")
                or V3.get(item["id"], {}).get("status")
                or item.get("status", "open"))

    out = []
    for item in REGISTER:
        if status(item) not in ("open", "proposed") or item.get("kind") == "decision":
            continue
        if item["id"] in EDITS:
            continue
        reason = NO_EDIT_BECAUSE.get(item["id"])
        if not reason:
            out.append(f"{item['id']}: open with no drafted edit and no reason "
                       f"in NO_EDIT_BECAUSE \u2014 T1.3's rule is that an item "
                       f"without an edit is checked by nobody")
        elif reason.startswith("covered by "):
            other = reason.split()[-1]
            if other not in EDITS:
                out.append(f"{item['id']}: says it is covered by {other}, which "
                           f"carries no edit either")
    for item_id in NO_EDIT_BECAUSE:
        if item_id in EDITS:
            out.append(f"{item_id}: has a drafted edit and an entry in "
                       f"NO_EDIT_BECAUSE saying why it has none")
    return out


def self_test() -> int:
    """Plant each shape this check exists for, and prove it sees them.

    Three shapes, because all three happened. A section v3.1 renumbered away
    (37 of those, found by hand). A bibliography reference written as a section
    — G9's rec cited §49, which is the IKEA-effect citation [49] and not a
    section of a document with 31 chapters. And a chapter that is real but has
    no subsections, which a naive chapter set misses: §4 Core loops.
    """
    doc = DOC.read_text(encoding="utf-8")
    item = next(i for i in REGISTER if i["id"] == "F26")
    was, ok = item["rec"], True

    for label, planted, should_fire in (
        ("a section renumbered away", "see \u00a75.9 for the rule", True),
        ("a reference cited as one", "the finding at \u00a749 says", True),
        ("a chapter with no subsections", "\u00a74 names the loops", False),
    ):
        item["rec"] = planted
        fired = bool(dangling_prose_sections(doc))
        print(f"  [{'PASS' if fired == should_fire else 'FAIL'}] {label}: "
              f"{'caught' if fired else 'allowed'}")
        ok = ok and fired == should_fire
    item["rec"] = was

    if dangling_prose_sections(doc):
        print("  [FAIL] the register does not pass its own check with nothing planted")
        ok = False
    else:
        print("  [PASS] and the register itself is clean")

    # The other half: every open item accounted for, and a "covered by X" link
    # that actually leads to an edit.
    planted = dict(id="ZZ-selftest", kind="finding", severity="minor",
                   status="open", title="planted", refs=[], body="", rec="")
    REGISTER.append(planted)
    caught = bool(unexplained_missing_edits())
    REGISTER.remove(planted)
    print(f"  [{'PASS' if caught else 'FAIL'}] an open item with no edit and no "
          f"reason is {'caught' if caught else 'MISSED'}")
    ok = ok and caught

    first = next(k for k, v in NO_EDIT_BECAUSE.items() if v.startswith("covered by "))
    was = NO_EDIT_BECAUSE[first]
    NO_EDIT_BECAUSE[first] = "covered by D20"        # D20 carries no edit
    caught = any("carries no edit either" in p for p in unexplained_missing_edits())
    NO_EDIT_BECAUSE[first] = was
    print(f"  [{'PASS' if caught else 'FAIL'}] a covered-by link to an item with "
          f"no edit is {'caught' if caught else 'MISSED'}")
    ok = ok and caught

    if unexplained_missing_edits():
        print("  [FAIL] the register has an unexplained missing edit")
        ok = False
    else:
        print("  [PASS] and every open item carries an edit or a stated reason")
    return 0 if ok else 1


def main() -> int:
    if "--self-test" in sys.argv:
        return self_test()
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
    doc_text = DOC.read_text(encoding="utf-8")
    problems.extend(dangling_sections(doc_text))
    problems.extend(dangling_prose_sections(doc_text))
    problems.extend(unexplained_missing_edits())

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

    # Two items editing the same sentence. The register is a work order, and a
    # work order that tells the owner to replace one sentence two different ways
    # is worse than one that says nothing — whichever edit is applied second
    # cannot find its text. C18 and F17 both landed on §9.1's Aether cap this
    # way, each without knowing about the other.
    by_needle: dict = {}
    for item_id, edits in EDITS.items():
        for n, edit in enumerate(edits, 1):
            if edit.get("action") not in ("replace", "delete", "insert"):
                continue
            needle = normalise(edit.get("find", ""))
            if needle:
                by_needle.setdefault(needle, []).append((item_id, n, edit["action"]))
    for needle, owners in by_needle.items():
        if len(owners) < 2:
            continue
        # Two inserts beside the same anchor are additive and fine; anything
        # that rewrites the text is not.
        if all(action == "insert" for _, _, action in owners):
            continue
        who = ", ".join(f"{i} edit {n} ({a})" for i, n, a in owners)
        problems.append(f"{who} all act on {needle[:50]!r} — whichever is "
                        f"applied first destroys the text the others look for")

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
    # An edit whose target sentence has vanished is usually good news: the
    # document was fixed and the edit retired with it. v3.1 retired twelve at
    # once. An edit that now matches *twice*, or an item whose sentence never
    # existed, is a different thing and still a failure.
    from audit_register import V31
    retired = [p for p in problems
               if "does not contain" in p and p.split()[0] in V31]
    real = [p for p in problems if p not in retired]

    if retired:
        print(f"  {len(retired)} edits no longer match, on items a later version "
              f"closed:")
        for p in retired:
            print(f"    · {p.split(':')[0]}")
        print("  Not a failure — this is what retirement looks like. The "
              "sentence the edit\n  quoted is gone because it was fixed.\n")
    if real:
        print(f"{len(real)} edits do not match the document:\n")
        for p in real:
            print(f"  ✗ {p}")
        print()
        return 1
    print("  every quoted sentence is in the document, exactly once, or belongs "
          "to an item\n  a later version closed.\n")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
