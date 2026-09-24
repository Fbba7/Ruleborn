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
import itertools
import pathlib
import re
import sys

ROOT = pathlib.Path(__file__).resolve().parent.parent
sys.path.insert(0, str(ROOT / "tools"))
from audit_register import EDITS, REGISTER, SETTLED, V3, V31, status  # noqa: E402

from design_doc import TEXT as DOC                                # noqa: E402
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
    ("D29", "5.9"): "deliberate: D29 is the record of v3.1's renumbering, so it "
                    "quotes the old numbers beside the new ones",
    ("D29", "25.5"): "deliberate, as above: the four §25.5 sentences in "
                     "spec/validation.md are what the item is about",
    ("D30", "10.5"): "deliberate: D30 is about the Library moving from §10.5 "
                     "to §10.4, and names both",
    ("D29", "13.5"): "deliberate: §13.5 is the reference D29 found that no "
                     "renumbering explains — the item exists because it "
                     "resolves to nothing",
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
    "F31": "a decision for the owner first: \u00a77.3 now closes the rule "
           "sheet at twenty parameters, so splitting two means a twenty-second",
    "C36": "a pacing decision for the owner: which daily heist count the "
           "upgrade pacing is priced at",
    "C37": "a decision for the owner: whether a scout shows patrol routes",
    "D56": "no document sentence: the fix is sim/ and the harness",
    "D57": "no document sentence: the fix is the harness",
    "F33": "a design decision for the owner: whether the Lantern Glare is "
           "budgeted apart or made a dial, which decides the sentence",
    "G17": "four one-clause decisions for the owner; the server's readings "
           "are named where it takes them",
    "D58": "no document sentence: the fix is the economy model",
    "D59": "no document sentence: the fix is the harness",
    "F36": "a decision for the owner: which day the raid-worth check is read "
           "on, which sets the base and the sentence",
    "F37": "a decision for the owner: where a non-raider's experience comes "
           "from, which decides the sentence",
    "G19": "a decision for the owner: the Heart's own ward and post counts",
    "G20": "a decision for the owner: whose base the day and week caps are in; "
           "the server's reading is named where it takes it",
    "G21": "a decision for the owner: what a target list's band is and how often "
           "it is rebuilt; the server's reading is named where it takes it",
    "F38": "a design decision for the owner: what the birth rate is tuned "
           "against once strays fill the roster",
    "F39": "a design decision for the owner: what the entry fee is keyed to",
    "C41": "a decision for the owner: which section owns the fee's return",
    "C42": "a decision for the owner: the stray rate",
    "G22": "decisions for the owner: the staffing order, the realm order and "
           "whether posts are staffed, which decide the sentences",
    "G23": "decisions for the owner: each reading is a rule the designer may "
           "keep or replace, and the sheet's sentence follows the choice",
    "G24": "a decision for the owner: §7.3's sheet is closed and versioned, so "
           "splitting a row makes rule sheet version 3",
    "G25": "decisions for the owner: each row's rule is a design choice the "
           "readings only stand in for",
    "D61": "a limit of this build, not a sentence in the document",
    "G26": "decisions for the owner: each figure and list is a design choice the "
           "server's constants only stand in for",
    "D62": "limits of this build, not sentences in the document",
    "C43": "a decision for the owner: whether players 16 and over may type island names",
    "F40": "a decision for the owner: which of §14.7's two targets the leagues keep, "
           "and whether Renown is made as well as moved",
    "G27": "decisions for the owner: the boundaries, the lower leagues' rewards "
           "and the rounding",
    "D63": "limits of this build, and version 1.1's scope",
    "F41": "a decision for the owner: what Starglass is, and what its 1:1 is to",
    "F42": "a one-word decision for the owner, and whether goals earn stars",
    "G28": "decisions for the owner: every figure is a design choice the "
           "server's constants only stand in for",
    "D64": "limits of this build: the stores, the device's inventories, and "
           "cosmetics not yet authored",
    "G29": "decisions for the owner: what a session is, the retention and the survey",
    "D65": "limits of this build: the heatmaps need the simulation, and the reporter a choice",
    "F43": "a decision for the owner, with legal advice: what deletion keeps",
    "F44": "a one-number decision for the owner: the window or the tier",
    "F45": "a decision for the owner: whether strength filters targets",
    "G30": "decisions for the owner: each figure is a design choice the "
           "server's constants only stand in for",
    "D66": "limits of this build: the reference crews and the generator live "
           "in the harness",
    "G31": "decisions for the owner: the price of a carried bag, and which "
           "share the rule reads",
    "F46": "a decision for the owner: whether scouting is enforced, at the cost "
           "of the edge cache",
    "G32": "decisions for the owner: a proof's freshness and how refunds land",
    "D67": "limits of this build: Google's APIs and Apple's notifications need the network",
    "F47": "a decision for the owner: the budget and the cost table, re-derived "
           "from what a heist must write",
    "G33": "a figure for the owner: the share of monthly players active on a day",
    "G34": "decisions for the owner: gathering raids, and reminders at night",
    "D68": "limits of this build: push needs the operator's credentials",
    "F48": "a decision for the owner: what a game among friends pays and counts",
    "G35": "decisions for the owner: how friends are made, and what minors show them",
    "D60": "no document sentence: the fix is the server",
    "F35": "a design decision for the owner: how the reach is sized, and "
           "whether a hit on the Vault is heard at 5 m, which decides the "
           "sentence",
    "F34": "a re-measurement first: \u00a713.2 already defers its table to "
           "the aligned re-run (32), and that re-run sets the numbers",
    "F32": "a design decision for the owner: whether the Heart is cleared "
           "before every crack, which decides whether the noise changes",
    "G16": "a decision for the owner: whether a ward's sensor ignores the "
           "crew member disarming it",
    "G15": "a pricing decision for the owner: the conversion has to be chosen "
           "before there is a sentence to draft",
    "D55": "no document sentence: the fix is the harness",
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
    "D52": "a reading aid, not a document fault: what one version changed,\n            # measured rather than taken from its changelog",
    # Two edits exist and they contradict each other: one rewrites the
    # cooldowns, the other rewrites \u00a712.6's decision count. Drafting both
    # would be drafting a contradiction, and drafting one would be making the
    # decision rather than putting it.
    "D32": "two mutually exclusive edits; the reading has to be chosen first",
    "D34": "no document sentence: the fix is the harness's stopping rule",
    "D38": "no document sentence: the fix is four more derived checks, which "
           "is F24's programme rather than an edit to \u00a731.5",
    "D40": "three edits that contradict each other until the number is "
           "chosen: \u00a711.10, \u00a718.3 and \u00a711.11 each state a "
           "different value for one mechanic",
    "D39": "no document sentence to replace: \u00a77.4 becomes generated from "
           "\u00a77.7 (D15's fix), and until it does the divergence is checked "
           "rather than prevented",
}


def ward_budget_agrees() -> list:
    """F26's ward budget must read the same everywhere the register states it.

    It is stated three times — in F26's body, in its recommendation, and in
    the design-gates panel, where it tells a designer how many objects a realm
    holds. The measurement moved realm 1 from ten wards to eleven, and two of
    the three would have kept saying ten.

    `ward_budget.MEASURED` is the one home. This reads the register rather
    than the tool's own tables, so a number typed into prose is checked
    against the number the sweep produced.
    """
    import re as _re
    import sys as _sys
    _sys.path.insert(0, str(ROOT))
    from audit_register import DESIGN_GATES
    from tools.ward_budget import MEASURED
    want = ", ".join(str(MEASURED[r]) for r in sorted(MEASURED))
    blobs = [(i["id"] + " " + k, i.get(k, ""))
             for i in REGISTER if i["id"] == "F26" for k in ("body", "rec")]
    blobs += [("the design gates", DESIGN_GATES["realms"]["gates"].get("F26", ""))]
    out = []
    for where, text in blobs:
        plain = _re.sub(r"<[^>]+>|&nbsp;", " ", text)
        found = _re.findall(r"\b(\d+,\s*\d+,\s*\d+,\s*\d+,\s*\d+)\b", plain)
        budgets = [f for f in found if f.replace(" ", "") != "4,5,6,7,8"]
        if not budgets:
            continue
        for budget in budgets:
            if _re.sub(r"\s+", " ", budget) != want:
                out.append(f"{where}: states a ward budget of {budget}, and "
                           f"ward_budget.MEASURED is {want}")
    return out


def markup_in_titles() -> list:
    """A register title must be plain text.

    A title is a value, not prose. It is escaped into the page, put in a
    `title=` attribute on the roadmap's progress bars, and quoted in the
    roadmap's "waits on" lists — three places where a tag cannot render. F16's
    carried an `<em>`, so the audit page showed a reader the literal text
    "<em>generated</em>" in a heading. The body and rec fields are prose and
    may carry inline markup; the title may not.
    """
    return [f"{item['id']}: the title carries markup ({m.group(0)}), and a "
            f"title is escaped wherever it is used"
            for item in REGISTER
            for m in [re.search(r"</?[a-z]+>", item["title"])] if m]


def dangling_edit_citations(doc: str) -> list:
    """A citation inside the text an edit would type must resolve too.

    `dangling_sections` checks where an edit *goes* and what an item *cites*.
    It does not read the replacement text, which is the one string in the
    register that is destined to become part of the document — so a drafted
    edit could carry a dead cross-reference all the way in, and two did:

        C27 replaces 9.2's sentence with one citing (5.9), which v3.1
            renumbered to 5.8 — the number its own `why` field uses
        C8  replaces 7.6's sentence with one citing (10.5), which v3.1
            renumbered to 10.4 — again the number its own `why` field uses

    Both are the same shape, and it is worth naming: the edit's prose for a
    human reader had the right section and the text for the document had the
    wrong one. Nothing compared them, because they are the same fact written
    twice, which is 31.2's rule turned on this register rather than on the
    document it audits.

    The document's own citations are checked by `check_document.py`. This is
    the same check moved one step earlier — before the sentence is typed,
    rather than after.
    """
    sections = set(re.findall(r"^(\d+\.\d+) ", doc, re.M))
    out = []
    for item_id, edits in EDITS.items():
        for n, edit in enumerate(edits, 1):
            for field in ("replace", "why"):
                for m in re.finditer(r"\((\d+\.\d+)\)", edit.get(field) or ""):
                    if m.group(1) not in sections:
                        out.append(
                            f"{item_id} edit {n}: the {field} text cites "
                            f"\u00a7{m.group(1)}, which is not a section of the "
                            f"document"
                            + (" \u2014 and this text is destined for the document"
                               if field == "replace" else ""))
    return out


def unexplained_missing_edits() -> list:
    """Every open item either carries an edit or says why it does not.

    Decisions are exempt: a Q item is the owner's to make and has no sentence
    to draft. Everything else open or proposed needs an edit or an entry in
    NO_EDIT_BECAUSE, and a "covered by X" entry is only honest if X has one.
    """

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


def bad_sides() -> list:
    """Every id in FRONTEND, BOTH and DESIGN_GATES must be a real item.

    And a design gate must name something still open: an area gated by an item
    the register has closed is telling a designer to wait for work that is done.
    """
    from audit_register import BOTH, DESIGN_GATES, FRONTEND, V3, V31

    known = {i["id"] for i in REGISTER}
    out = []
    for name, table in (("FRONTEND", FRONTEND), ("BOTH", BOTH)):
        for item_id in table:
            if item_id not in known:
                out.append(f"{name} names {item_id}, which is not in the register")
    overlap = set(FRONTEND) & set(BOTH)
    if overlap:
        out.append(f"both frontend and both: {sorted(overlap)}")

    def status_or_none(item_id):
        if not any(i["id"] == item_id for i in REGISTER):
            return None
        return status(item_id)

    for area, spec in DESIGN_GATES.items():
        for item_id in spec["gates"]:
            st = status(item_id)
            if st is None:
                out.append(f"DESIGN_GATES[{area}] names {item_id}, which is not "
                           f"in the register")
            elif st not in ("open", "proposed"):
                out.append(f"DESIGN_GATES[{area}] says {item_id} gates the "
                           f"design, but the register has it {st} \u2014 a "
                           f"designer would be waiting for finished work")
        # And the mirror. `closed` is what gives each area a denominator, so a
        # gate listed there that is still open would count the area further
        # along than it is — the same lie as the one above, told the other way.
        for item_id in spec.get("closed", {}):
            st = status(item_id)
            if st is None:
                out.append(f"DESIGN_GATES[{area}] closed names {item_id}, "
                           f"which is not in the register")
            elif st in ("open", "proposed"):
                out.append(f"DESIGN_GATES[{area}] counts {item_id} as a gate "
                           f"already cleared, but the register has it {st} "
                           f"\u2014 put it under `partly` if only this area's "
                           f"half of it is done")
        # `partly` is for an item that still gates something and no longer gates
        # *this*: C6 blocked character art while the two rosters disagreed about
        # what three creatures were, and stopped when v3.1 reconciled them —
        # while staying open for the ability text, which is not something an
        # artist draws. The mirror of the rule above: an entry here whose item
        # has closed belongs under `closed`, or the area undercounts itself.
        for item_id in spec.get("partly", {}):
            st = status(item_id)
            if st is None:
                out.append(f"DESIGN_GATES[{area}] partly names {item_id}, "
                           f"which is not in the register")
            elif st not in ("open", "proposed"):
                out.append(f"DESIGN_GATES[{area}] has {item_id} partly cleared, "
                           f"but the register has it {st} \u2014 it belongs "
                           f"under `closed`")
        lists = ("gates", "closed", "partly")
        for a, b in itertools.combinations(lists, 2):
            both = set(spec.get(a, {})) & set(spec.get(b, {}))
            if both:
                out.append(f"DESIGN_GATES[{area}] lists {sorted(both)} under "
                           f"both {a} and {b}")
    return out


def gate_owners() -> list:
    """Every open design gate names who has to move next, and nothing else does.

    The handoff verdict on the audit page is derived from these, so a gate with
    no owner would crash the build and a stale owner would quietly widen the
    set the verdict is computed from. Neither is allowed to be a judgement call
    at read time.

    The rule that matters is the third one: an owner recorded for an item that
    is no longer an open gate is the shape every stale copy in this register
    has taken \u2014 the fix landed and the note about it did not.
    """
    from audit_register import DESIGN_GATES, GATE_OWNER, HANDOFF

    out = []
    open_gates = {g for spec in DESIGN_GATES.values() for g in spec["gates"]}
    for gate in sorted(open_gates - set(GATE_OWNER)):
        out.append(f"GATE_OWNER does not say who has to move next on {gate}, "
                   f"which is an open design gate")
    for gate in sorted(set(GATE_OWNER) - open_gates):
        out.append(f"GATE_OWNER names {gate}, which is not an open design gate "
                   f"\u2014 either it was cleared and this was not removed, or "
                   f"it belongs under `closed` or `partly`")
    allowed = set(HANDOFF) - {"ready"} | {"outside"}
    for gate, owner in sorted(GATE_OWNER.items()):
        if owner not in allowed:
            out.append(f"GATE_OWNER[{gate}] is {owner!r}, which is not one of "
                       f"{sorted(allowed)}")
    return out


def orphan_references() -> list:
    """Every id named anywhere in the register must resolve to an item.

    `bad_sides` covers FRONTEND, BOTH and DESIGN_GATES. The other six tables
    name items too, and nothing read them: EDITS, V3, V31, FOUND_IN_V3,
    RESEARCH and DEPENDS.

    The reason this is worth its own check is narrower than tidiness. **An item
    that is deleted by accident reads exactly like an item that was never
    there.** The register is one long Python literal edited by patch scripts,
    and a range that starts at one id and ends at another deletes whatever
    happens to sit between them \u2014 which is not alphabetical and not
    chronological. Seven items went that way in one edit while this file was
    being written, and the only thing that noticed was `build_audit.py` raising
    KeyError on a design gate. The README's item count is no guard either,
    because the same hand that loses an item updates the count to match.

    These six tables are the anchor: they were written when the items existed,
    they are spread through the file, and an item cannot vanish without leaving
    at least one of them pointing at nothing.
    """
    from audit_register import (BOTH, DEPENDS, EDITS, FOUND_IN_V3, FRONTEND,
                                REGISTER as ITEMS, RESEARCH, V3, V31)

    known = {i["id"] for i in ITEMS}
    out = []
    tables = [("EDITS", set(EDITS)), ("V3", set(V3)), ("V31", set(V31)),
              ("FOUND_IN_V3", set(FOUND_IN_V3)), ("RESEARCH", set(RESEARCH))]
    # DEPENDS names items on both sides of each arrow.
    depends = set(DEPENDS) | {d for deps in DEPENDS.values() for d in deps}
    tables.append(("DEPENDS", depends))
    for name, ids in tables:
        for item_id in sorted(ids - known):
            out.append(f"{name} names {item_id}, which is not in the register "
                       f"\u2014 either the id is wrong or the item was lost")
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

    # A lost item, which is the shape `orphan_references` is really for. It is
    # planted by removing an item rather than by adding a bad reference,
    # because that is how it happens: nobody types a wrong id, they delete a
    # dict and the tables that named it are left pointing at nothing.
    from audit_register import REGISTER as ITEMS
    victim = next(i for i in ITEMS if i["id"] == "C19")
    at = ITEMS.index(victim)
    ITEMS.remove(victim)
    caught = any("C19" in p for p in orphan_references())
    ITEMS.insert(at, victim)
    print(f"  [{'PASS' if caught else 'FAIL'}] an item deleted from the register "
          f"is {'caught' if caught else 'MISSED'} by the tables that name it")
    ok = ok and caught and not orphan_references()

    # A gate whose owner was left behind after it cleared. The handoff verdict
    # is computed from the open gates, so a stale owner does not change it
    # today - it changes it the day that item becomes a gate again for a
    # different reason, which is exactly when nobody will be looking.
    from audit_register import DESIGN_GATES as _dg, GATE_OWNER as _owner
    _owner["C11"] = "yours"
    stale = any("C11" in p for p in gate_owners())
    del _owner["C11"]
    area = next(a for a in _dg if _dg[a]["gates"])
    gate, why = next(iter(_dg[area]["gates"].items()))
    was = _owner.pop(gate)
    missing = any(gate in p for p in gate_owners())
    _owner[gate] = was
    print(f"  [{'PASS' if stale else 'FAIL'}] an owner left behind after its "
          f"gate cleared is {'caught' if stale else 'MISSED'}")
    print(f"  [{'PASS' if missing else 'FAIL'}] an open gate with nobody named "
          f"is {'caught' if missing else 'MISSED'}")
    ok = ok and stale and missing and not gate_owners()

    # The replacement text an edit would type in, which nothing read before.
    victim = next(iter(EDITS))
    planted = dict(section=EDITS[victim][0]["section"], action="replace",
                   find="x", replace="see the rule at (99.9)", why="planted")
    EDITS[victim].append(planted)
    caught = any("99.9" in p for p in dangling_edit_citations(doc))
    live = any("destined for the document" in p
               for p in dangling_edit_citations(doc))
    EDITS[victim].remove(planted)
    print(f"  [{'PASS' if caught and live else 'FAIL'}] a dead citation inside a "
          f"replacement is {'caught' if caught else 'MISSED'}")
    ok = ok and caught and live

    # The ward budget is stated three times and the measurement moved one of
    # its five numbers.
    from audit_register import DESIGN_GATES as _gates
    # F26 closed with v3.3, so the gate may not be there to overwrite.
    was_gate = _gates["realms"]["gates"].get("F26")
    _gates["realms"]["gates"]["F26"] = "measured at 10, 8, 6, 7, 8 against 4, 5, 6, 7, 8"
    caught = bool(ward_budget_agrees())
    if was_gate is None:
        del _gates["realms"]["gates"]["F26"]
    else:
        _gates["realms"]["gates"]["F26"] = was_gate
    print(f"  [{'PASS' if caught else 'FAIL'}] a ward budget that disagrees with "
          f"the sweep is {'caught' if caught else 'MISSED'}")
    ok = ok and caught and not ward_budget_agrees()

    # A title is escaped wherever it is used, so markup in one reaches a
    # reader as literal text. F16's carried an <em> into a page heading.
    first = REGISTER[0]
    was_title = first["title"]
    first["title"] = "a <em>planted</em> title"
    caught = bool(markup_in_titles())
    first["title"] = was_title
    print(f"  [{'PASS' if caught else 'FAIL'}] markup in a register title is "
          f"{'caught' if caught else 'MISSED'}")
    ok = ok and caught and not markup_in_titles()

    if dangling_edit_citations(doc):
        print("  [FAIL] a drafted edit still carries a dead citation")
        ok = False
    else:
        print("  [PASS] and every citation an edit would type in resolves")

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

    # Planted rather than borrowed: it used to take the first open item
    # already "covered by" another, and v3.4 closed the last of them.
    planted = dict(id="ZZ-covered", kind="finding", severity="minor",
                   status="open", title="planted", refs=[], body="", rec="")
    REGISTER.append(planted)
    NO_EDIT_BECAUSE["ZZ-covered"] = "covered by D20"   # D20 carries no edit
    caught = any("carries no edit either" in p for p in unexplained_missing_edits())
    del NO_EDIT_BECAUSE["ZZ-covered"]
    REGISTER.remove(planted)
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
    problems.extend(dangling_edit_citations(doc_text))
    problems.extend(markup_in_titles())
    problems.extend(ward_budget_agrees())
    problems.extend(unexplained_missing_edits())
    problems.extend(bad_sides())
    problems.extend(orphan_references())
    problems.extend(gate_owners())

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
            if action == "retag" and status(item_id) in SETTLED:
                # A settled item's retags are retired with it, exactly as its
                # replacements are: v3.3 re-noted C25's laws its own way, and
                # the edit that proposed another way is history, not a fault.
                continue
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
    from audit_register import FOUND_IN_V3
    uncovered = [i["id"] for i in REGISTER
                 if i["kind"] in ("contradiction", "gap")
                 and status(i) not in ("fixed", "done", "adopted")
                 and i["id"] not in EDITS]

    # The same gap one level up. Six clerical contradictions and one decision
    # went on being reported open after v3.0 had settled them, because the sweep
    # over the new document covered the category that was on my mind and not the
    # others. An item with no V3 note has not been read against the current
    # version by anybody.
    # v3.3 was read item by item (its layer in audit_register), so an item
    # with a note in any layer, or found in v3.3 itself, has been read.
    from audit_register import (V31 as _v31, V32 as _v32, V33 as _v33, V34 as _v34,
                                FOUND_IN_V33, FOUND_IN_V34)
    unread = [i["id"] for i in REGISTER
              if i["kind"] != "deviation"
              and status(i) not in ("done", "adopted")
              and not any(i["id"] in layer for layer in (V3, _v31, _v32, _v33, _v34))
              and i["id"] not in FOUND_IN_V3 | FOUND_IN_V33 | FOUND_IN_V34]

    print(f"\nChecked {total} edits across {len(EDITS)} register items against "
          f"{DOC.name}.\n")
    if unread:
        print(f"  {len(unread)} items have no note saying what any version did about "
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
    from audit_register import V31, V32, V33, V34
    closed = (set(V31) | set(V32) | {k for k, v in V33.items() if v["status"] != "open"}
              | {k for k, v in V34.items() if v["status"] != "open"})
    retired = [p for p in problems
               if "does not contain" in p and p.split()[0] in closed]
    real = [p for p in problems if p not in retired]

    if retired:
        print(f"  {len(retired)} edits no longer match, on items a later version "
              f"acted on:")
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
