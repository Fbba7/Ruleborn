#!/usr/bin/env python3
"""Check this repository's own documents against each other.

    python3 tools/check_docs_consistency.py

The analysis of the design document found four systems specified twice, with one
copy left stale. Producing a dozen documents about that and then letting them
drift the same way would be a poor joke — and it already started: four files
claimed four different counts of the same register.

So the same discipline applies here. This checks:

  * every count claimed in prose against the register it describes
  * every internal link resolves to a file that exists
  * every spec file is listed in the spec index, and vice versa
  * every register item that names a spec file names one that exists
  * the published artifact URL is the same everywhere it appears
  * counts quoted from a tool's output match what that tool prints today

It fails the build. That is the point.
"""

import pathlib
import ast
import re
import sys

ROOT = pathlib.Path(__file__).resolve().parent.parent
sys.path.insert(0, str(ROOT / "tools"))
from audit_register import REGISTER                                 # noqa: E402

SPEC_DIR = ROOT / "docs" / "design" / "spec"
GENERATED = ROOT / "docs" / "design" / "generated"

problems: list[str] = []


def fail(msg: str) -> None:
    problems.append(msg)


def markdown_files() -> list[pathlib.Path]:
    out = []
    for path in ROOT.rglob("*.md"):
        if any(part in (".git", "generated") for part in path.parts):
            continue
        out.append(path)
    return sorted(out)


def rel(path: pathlib.Path) -> str:
    return str(path.relative_to(ROOT))


def check_counts(files: list[pathlib.Path]) -> None:
    """Counts claimed in prose must match the register.

    Every number here was found wrong at least once. The README said 25 of 88
    items fixed while the register had 35 of 106, and 54 edits across 32 items
    while it had 70 across 40 — numbers that were true when they were typed
    and that nothing re-derived. A count in prose is a copy of a fact, which
    is 31.2's subject; the difference is that these copies are checkable.
    """
    from audit_register import EDITS, V3, V31, status

    kinds = {
        "contradiction": sum(1 for i in REGISTER if i["kind"] == "contradiction"),
        "gap": sum(1 for i in REGISTER if i["kind"] == "gap"),
    }
    total = len(REGISTER)
    fixed = sum(1 for i in REGISTER if status(i) == "fixed")
    by_v3 = sum(1 for i in REGISTER if V3.get(i["id"], {}).get("status") == "fixed")
    by_v31 = sum(1 for i in REGISTER if V31.get(i["id"], {}).get("status") == "fixed")
    edits = sum(len(v) for v in EDITS.values())
    edited_items = len(EDITS)

    patterns = [
        (re.compile(r"(\d+)\s+confirmed internal contradictions"), kinds["contradiction"],
         "confirmed internal contradictions"),
        (re.compile(r"tracked as (\d+) items"), total, "items tracked"),
        (re.compile(r"as (\d+) tracked items"), total, "items tracked"),
        (re.compile(r"register is at (\d+)", re.I), total, "register size"),
        (re.compile(r"(\d+) (?:specification )?gaps\b"), kinds["gap"], "gaps"),
        (re.compile(r"\*\*(\d+) of \d+ register items are fixed"), fixed,
         "items fixed in the document"),
        (re.compile(r"\*\*\d+ of (\d+) register items are fixed"), total,
         "items tracked"),
        (re.compile(r"(\d+) by v3\.0 and \d+ more by v3\.1"), by_v3,
         "items fixed by v3.0"),
        (re.compile(r"\d+ by v3\.0 and (\d+) more by v3\.1"), by_v31,
         "items fixed by v3.1"),
        (re.compile(r"(\d+) are drafted across \d+"), edits, "drafted edits"),
        (re.compile(r"\d+ are drafted across (\d+)"), edited_items,
         "items carrying an edit"),
    ]
    def problems(text: str) -> list[str]:
        """Every count in one document that disagrees with the register.

        Pulled out of the loop so the self-test can feed it a sentence rather
        than rewriting README.md on disk: a check that can only be exercised
        by editing the repository is one nobody exercises.
        """
        out = []
        for pattern, expected, label in patterns:
            for match in pattern.finditer(text):
                claimed = int(match.group(1))
                if claimed != expected:
                    out.append(f"claims {claimed} {label}, register has {expected}")
        return out

    check_counts.problems = problems          # for the self-test
    for path in files:
        for problem in problems(path.read_text(encoding="utf-8")):
            fail(f"{rel(path)}: {problem}")


def check_links(files: list[pathlib.Path]) -> None:
    """Every relative markdown link must resolve."""
    link = re.compile(r"\[[^\]]+\]\((?!https?:|#)([^)#]+)")
    for path in files:
        for match in link.finditer(path.read_text(encoding="utf-8")):
            target = (path.parent / match.group(1)).resolve()
            if not target.exists():
                fail(f"{rel(path)}: broken link to {match.group(1)}")


def check_spec_index() -> None:
    """The spec index and the spec directory must agree.

    The file-name pattern must allow hyphens and digits. An earlier version used
    ``[a-z_]+`` and reported `first-build.md` as unlisted when it was listed —
    a false positive, which is its own kind of failure: it sent me to "fix" a
    file that was already correct, and I added a duplicate row before noticing.
    """
    index = SPEC_DIR / "README.md"
    if not index.exists():
        fail("docs/design/spec/README.md is missing")
        return
    text = index.read_text(encoding="utf-8")
    on_disk = {p.name for p in SPEC_DIR.glob("*.md")} - {"README.md"}
    listed = set(re.findall(r"\(([a-z0-9_-]+\.md)\)", text))
    for name in sorted(on_disk - listed):
        fail(f"spec/{name} exists but is not listed in spec/README.md")
    for name in sorted(listed - on_disk):
        fail(f"spec/README.md lists {name}, which does not exist")


#: Sections v3.1 renumbered, and what each became. v3.1 filled four holes left
#: by v3.0's deletions — 5.8, 7.8, 10.4 and 25.3 were all missing — which
#: shifted the section after each of them down by one. The register records
#: this as "a renumbering is never only clerical"; these were the four, and
#: this repository had 41 references to the old numbers.
# v3.1 moved 7.10 to 7.9, and v3.3 reused the number for a new section (what a
# law costs to build, and the 24 that ship first), so a citation of 7.10 is
# current again and can no longer be told from a stale one by number alone.
RENUMBERED = {"5.9": "5.8", "10.5": "10.4", "25.5": "25.4"}

#: Directories whose files describe an earlier version of the design document
#: and use that version's numbering on purpose. Renumbering them would make
#: the archive describe a document it never read, so their citations are read
#: against the version each file names and are not checked here. They are
#: listed rather than skipped silently, because an unchecked file that nobody
#: knows is unchecked is the same as no check.
ARCHIVES = ("docs/analysis/",)

#: Files whose section references another check already owns, with its own
#: table of deliberate exceptions. `check_edits.dangling_prose_sections` reads
#: every reference in the register's prose and `check_edits.KNOWN_UNRESOLVABLE`
#: says which are meant not to resolve — D29 quotes the old numbers because it
#: is the record of the renumbering. Checking it here as well would mean two
#: exception tables for one question, which is the fault both files exist to
#: record.
OWNED_ELSEWHERE = ("tools/audit_register.py",)

#: A stale number is deliberate when the text around it says so. The phrases
#: are the ones this repository actually uses for it — "v3.0's 5.9", "5.9 is
#: now 5.8", "renumbered 5.8 in v3.1".
#: A section citation, written with the character or with the
#: six-character escape a Python source file may carry instead.
CITE = re.compile(r"(?:§|\\u00a7)(\d+\.\d+)")

HISTORICAL = re.compile(
    r"v2\.\d|v3\.0|renumber|is now \u00a7|was \u00a7|older version|earlier version",
    re.I)


def prose_files() -> list[pathlib.Path]:
    """Every file in this repository that cites the design document in prose."""
    out = []
    for pattern in ("docs/**/*.md", "tools/**/*.py", "README.md"):
        for path in ROOT.glob(pattern):
            if any(part in (".git", "vendor", "upstream", "__pycache__")
                   for part in path.parts):
                continue
            out.append(path)
    return sorted(set(out))


def current_version() -> str:
    """The version of the design document this repository reads.

    Taken from `check_document.DEFAULT_DOC` rather than from the newest file
    on disk: the older versions are still in `docs/design/` on purpose, and
    which one the checks read is the fact that matters. One home for it, which
    is 31.2's rule applied to the tooling.
    """
    import check_document
    m = re.search(r"-v(\d+\.\d+)\.html$", check_document.DEFAULT_DOC)
    return m.group(1) if m else ""


def check_document_version(files: list[pathlib.Path]) -> None:
    """D30. Prose naming the document's version must name the one being read.

    The README opened "design document at v3.0" for as long as v3.1 had been
    the one every tool read, and pointed "Full detail" at v2.3 — two versions
    back. A reader who followed it would have been reading a document this
    repository no longer checks anything against.

    Only the present-tense forms are checked. "v3.0 answered the audit" is a
    statement about what an older version did and stays as it is; "the design
    document at v3.0" is a claim about now.
    """
    now = current_version()
    if not now:
        fail("the design document's version cannot be read from "
             "check_document.DEFAULT_DOC, so nothing here can be checked against it")
        return
    present = re.compile(
        r"(?:design document(?: is now)? at|read (?:now )?against|"
        r"checked against|validated against) v(\d+\.\d+)", re.I)
    for path in dict.fromkeys(files + [ROOT / "README.md"]):
        text = path.read_text(encoding="utf-8")
        for m in present.finditer(text):
            if m.group(1) != now:
                fail(f"{rel(path)}: says {m.group(0)!r}, and the checks read "
                     f"v{now}")


def check_document_links() -> None:
    """A link to a design-document file must point at the current one.

    `docs/analysis/` is exempt: it is the v2.3 audit and links to the document
    it audited, which is the honest thing for an archive to do.
    """
    now = current_version()
    named = re.compile(r"ruleborn-game-design-v(\d+\.\d+)\.(?:html|txt)")
    # Every prose file, not only the markdown: three tools' usage examples
    # told a reader to run them against v3.0, which is the version the content
    # pipeline was quietly still reading (D30).
    for path in prose_files():
        name = rel(path)
        if any(name.startswith(a) for a in ARCHIVES) or name in OWNED_ELSEWHERE:
            continue
        lines = path.read_text(encoding="utf-8").splitlines()
        for i, line in enumerate(lines):
            # The file name carries the version, and HISTORICAL matches "v2.3"
            # — so a link to the v2.3 document marks itself historical and the
            # first version of this check passed on the two links that started
            # it. The names are removed before the window is read.
            window = named.sub("", " ".join(lines[max(0, i - 2):i + 3]))
            for m in named.finditer(line):
                if m.group(1) != now and not HISTORICAL.search(window):
                    fail(f"{name}:{i + 1} points at "
                         f"{m.group(0)}, and the current document is v{now}")


def check_stale_citations() -> None:
    """A \u00a7N.M in this repository's own prose must be a section v3.1 has.

    `check_edits.py` checks the register's citations and `check_document.py`
    checks the document's own. Nothing checked the third set: the spec files,
    the generated analyses and the tools' docstrings, which is most of the
    prose here and all of the prose a contributor reads first.

    It is the same fault this repository exists to record. v3.1 moved four
    section numbers; the design document was updated and the repository that
    audits it was not, so `docs/design/spec/validation.md` argued about
    \u00a725.5 for four paragraphs after \u00a725.5 stopped existing.

    Three ways a stale number is allowed, and each is a claim in itself:
    the file is an archive of an earlier version (listed in ARCHIVES), the
    text around it says it is historical (HISTORICAL), or the number is one
    no version of this document has ever had \u2014 which is not allowed at
    all, and is reported as the harder problem it is.
    """
    import check_document
    doc = check_document.Doc(check_document.DEFAULT_DOC).text
    sections = set(re.findall(r"^(\d+\.\d+) ", doc, re.M))
    for path in prose_files():
        name = rel(path)
        if any(name.startswith(a) for a in ARCHIVES) or name in OWNED_ELSEWHERE:
            continue
        lines = path.read_text(encoding="utf-8", errors="replace").splitlines()
        for i, line in enumerate(lines):
            window = " ".join(lines[max(0, i - 3):i + 4])
            # A Python source file may write the section mark as the escape
            # \u00a7 rather than the character, and four stale citations in
            # decision_support.py hid behind exactly that: the first version of
            # this check read the character only and reported the file clean.
            for m in CITE.finditer(line):
                num = m.group(1)
                if num in sections or HISTORICAL.search(window):
                    continue
                became = RENUMBERED.get(num)
                fail(f"{name}:{i + 1} cites \u00a7{num}, "
                     + (f"which v3.1 renumbered to \u00a7{became}"
                        if became else
                        "which is not a section of v3.1 and not one of the four "
                        "v3.1 renumbered \u2014 so it names nothing"))


def check_tool_index() -> None:
    """The README's tools/ listing and the tools directory must agree.

    The spec index has been checked both ways since the day a spec file went
    unlisted. The tools listing is the same promise to a reader — it is where
    someone looks to find out what can be run — and it was not checked at all,
    so it had drifted: five tools existed that it never mentioned. A listing
    that is only ever added to by hand is a listing that is wrong.

    Directories are listed with a trailing slash and checked the same way.
    """
    readme = ROOT / "README.md"
    text = readme.read_text(encoding="utf-8")
    block = re.search(r"^tools/\n((?:  .*\n)+)", text, re.M)
    if not block:
        fail("README.md has no tools/ listing to check")
        return
    listed = set(re.findall(r"^  ([a-z0-9_]+(?:\.py|/))", block.group(1), re.M))
    on_disk = {p.name for p in (ROOT / "tools").glob("*.py")}
    on_disk |= {p.name + "/" for p in (ROOT / "tools").iterdir()
                if p.is_dir() and not p.name.startswith("__")}
    for name in sorted(on_disk - listed):
        fail(f"tools/{name} exists but is not listed in README.md")
    for name in sorted(listed - on_disk):
        fail(f"README.md lists tools/{name}, which does not exist")


def check_register_references() -> None:
    """A register item naming a spec file must name one that exists."""
    named = re.compile(r"docs/design/spec/([a-z0-9_-]+\.md)")
    for item in REGISTER:
        blob = item.get("body", "") + item.get("rec", "")
        for name in named.findall(blob):
            if not (SPEC_DIR / name).exists():
                fail(f"register {item['id']}: names spec/{name}, which does not exist")


def check_handoff_table() -> None:
    """The README's verdict table against the register's own gates.

    The table answers one question - can realms, screens or characters be
    handed to someone who will draw them - and a hand-typed answer to that
    question is the worst thing in this repository to get wrong: it is read
    to decide whether to start work, and a stale "Ready" costs whoever acts
    on it.

    So it is checked the way the audit page's band is: derived from
    DESIGN_GATES and GATE_OWNER, both directions. Every area must appear, with
    the right verdict and exactly the gates it is waiting on. This is the same
    rule the register applies to the design document - a number restated
    somewhere else is checked against its home or it is not allowed to be
    restated - turned on the README.
    """
    sys.path.insert(0, str(ROOT / "tools"))
    import build_audit
    from audit_register import DESIGN_GATES

    text = (ROOT / "README.md").read_text(encoding="utf-8")
    rows = {area.lower(): (word.strip(), waiting) for area, word, waiting in
            re.findall(r"^\| \*\*([A-Za-z]+)\*\* \| ([^|]+) \| ([^|]*)\|",
                       text, re.M)}
    if not rows:
        fail("README.md has no handoff verdict table to check")
        return
    for area in DESIGN_GATES:
        if area not in rows:
            fail(f"README.md's verdict table does not mention {area}")
            continue
        word, waiting = rows[area]
        want = build_audit.handoff(area)
        expect = build_audit.HANDOFF_WORDS[want["verdict"]][0]
        if word != expect:
            fail(f"README.md says {area} is {word!r}; its gates make it "
                 f"{expect!r}")
        listed = set(re.findall(r"\b([A-Z]+\d+)\b", waiting))
        if listed != set(want["open"]):
            fail(f"README.md has {area} waiting on {sorted(listed)}; the "
                 f"register has {sorted(want['open'])}")
    for area in set(rows) - set(DESIGN_GATES):
        fail(f"README.md's verdict table names {area}, which is not a design "
             f"area")


def spec_open_claims(text: str) -> list[str]:
    """Register ids a "Still open" section claims are outstanding work.

    Only the *subject* of a bullet counts. A bullet may cite a settled item as
    context for a question that is genuinely open - `first-build.md` asks
    whether a day-2 guard counts against the roster and explains why with
    "Under F1 the roster is the binding constraint", and `vault.md` notes that
    a refinement "is not needed to close G4". Neither claims the item is open,
    and flagging them would send someone to fix a file that is right.

    `check_spec_index`'s own docstring records what that costs: a false
    positive here sent me to correct a correct file and I added a duplicate row
    before noticing. So the rule is narrow - the id must be in the bullet's
    leading bold run, which is where these files put the subject.
    """
    out = []
    for line in text.splitlines():
        bullet = re.match(r"\s*[-*]\s+(.*)", line)
        if not bullet:
            continue
        lead = re.match(r"\*\*(.+?)\*\*", bullet.group(1))
        if not lead:
            continue
        out += re.findall(r"\b([A-Z]{1,2}\d{1,2})\b", lead.group(1))
    return sorted(set(out))


def check_spec_status() -> None:
    """A spec file's "Still open" list must contain only items the register has
    open.

    The spec files are what a contributor reads to find out what to do, and
    each ends with a list of what it is still waiting on. Those lists are
    hand-written and nothing compared them with the register, so five of them
    sent a reader to settle work that v3.0 and v3.1 had finished.
    `spec/detection.md` still said "Settle the tick rate before writing the
    golden replays" against a register that has C7 fixed and a build check
    asserting `tick_rate == 30`.

    Citations were already checked here and did not catch it, because the fault
    is not in the numbers: every section these files cite still exists. It is
    the claim about an item's state that went stale, which is C21 to C24
    exactly, told about this repository's own documents instead of the design
    document's.
    """
    sys.path.insert(0, str(ROOT / "tools"))
    import check_document

    known = {i["id"] for i in REGISTER}
    for path in sorted(SPEC_DIR.glob("*.md")):
        text = path.read_text(encoding="utf-8")
        m = re.search(r"^##+ Still open\s*$(.*?)(?=^##|\Z)", text, re.M | re.S)
        if not m:
            continue
        for item in spec_open_claims(m.group(1)):
            if item not in known:
                fail(f"spec/{path.name} lists {item} as still open, and there "
                     f"is no such register item")
            elif not check_document._is_open(item):
                fail(f"spec/{path.name} lists {item} as still open; the "
                     f"register has it settled")


def check_tools_parse() -> None:
    """Every file under tools/ is valid Python, and every one is run by something.

    `check_all.sh` runs most of them, so most breakage surfaces. Not all: a
    tool nothing in the suite invokes can be left unparseable and the build
    stays green. This is the cheapest possible guard against that, and it was
    written after a patch script re-led a one-line docstring and swallowed its
    closing quotes in two files at once.

    The second half is a backlog rather than a failure. A tool nobody runs is
    not wrong, but it is not checked either, and the register's whole argument
    is that those are the same thing eventually.
    """
    suite = (ROOT / "tools" / "check_all.sh").read_text(encoding="utf-8")
    # A module the suite never names is still exercised if something the suite
    # runs imports it: `heist_harness/sim.py` is most of the harness and the
    # suite names only the test module. So the question is whether anything at
    # all reaches it, not whether the shell script says its name.
    imported = set()
    for path in (ROOT / "tools").rglob("*.py"):
        if "__pycache__" in path.parts:
            continue
        text = path.read_text(encoding="utf-8")
        for m in re.finditer(r"^\s*(?:from|import)\s+([.\w]+)", text, re.M):
            imported.update(m.group(1).lstrip(".").split("."))
        # `from . import sinks` names the module after the keyword, not
        # before it. The first version read only the dotted path, so every
        # relative-imported module in the harness and the economy model read
        # as run by nothing.
        for m in re.finditer(r"^\s*from\s+\.\S*\s+import\s+([\w,\s]+)",
                             text, re.M):
            imported.update(n.strip() for n in m.group(1).split(","))
    unrun = []
    for path in sorted((ROOT / "tools").rglob("*.py")):
        if any(part in ("__pycache__", "vendor") for part in path.parts):
            continue
        try:
            ast.parse(path.read_text(encoding="utf-8"))
        except SyntaxError as exc:
            fail(f"{rel(path)} does not parse: line {exc.lineno}, {exc.msg}")
            continue
        stem = path.stem
        if stem.startswith(("test_", "__")):
            continue
        module = f"{path.parent.name}.{stem}" if path.parent.name != "tools" else stem
        if stem not in suite and module not in suite and stem not in imported:
            unrun.append(rel(path))
    if unrun:
        print(f"\n  {len(unrun)} tool(s) that nothing runs and nothing imports, "
              f"so a fault in one\n  would not fail the build:")
        for name in unrun:
            print(f"    {name}")


def check_one_status_home() -> None:
    """No tool may work out an item's effective status for itself.

    The register carries three opinions about every item — its own `status`,
    what V3 records v3.0 did, and what V31 records v3.1 did — and the effective
    answer is the latest of the three. That expression existed **twelve times**
    across seven files, and four of the copies were written before V31 and
    never learned about it, so the nine items v3.1 closed read as open in all
    four. The audit page's own "Where to start" section therefore said sixty
    items were open, listed nine settled ones as work to do, and called F10
    blocked by something already fixed.

    §31.2's rule, broken by the tool that reports it, on the page it reports it
    on. `audit_register.status` is the home now, and this refuses a second
    copy: a `V31.get(...)["status"]` chained to a `V3.get(...)` anywhere but
    there is the fault coming back.

    Counting what one particular version fixed is a different question and is
    allowed — `by_v3` below asks it deliberately.
    """
    # Only the *chained* form is the effective-status expression. Counting
    # what one version fixed — `by_v31` below — asks a different question and
    # is allowed, so the pattern requires the fallback rather than the lookup.
    chained = re.compile(
        r"V31\.get\([^)]*\)\.get\([^)]*\)\s*\n?\s*or\s", re.S)
    v3_then_own = re.compile(
        r"V3\.get\([^)]*\)\.get\(\s*[\"']status[\"']\s*\)\s*or\s+\w+\.get\(")
    for path in sorted((ROOT / "tools").rglob("*.py")):
        if any(part in ("__pycache__", "vendor") for part in path.parts):
            continue
        if path.name == "audit_register.py":
            continue
        text = path.read_text(encoding="utf-8")
        if chained.search(text) or v3_then_own.search(text):
            fail(f"{rel(path)} works out an item's effective status itself; "
                 f"import audit_register.status instead")


def check_one_document_home() -> None:
    """D36. Only design_doc.py may name a version-pinned document filename.

    The document's filename carries its version, so every tool that opens it
    holds a copy of "which version are we on". There were nine, across six
    files, and nothing compared them — which is D30 exactly: the content
    tables were built from v3.0 and validated against v3.0, so the pair agreed
    and three of v3.1's improvements were invisible.

    `check_document_version` could not help. It reads prose that names a
    version; these are paths, and a path is not prose.

    Two exceptions, both honest. `extract_design_doc` converts one version's
    HTML into its own text and shows both in its usage line, which is what a
    usage line is for. `tools/vendor/` is the design document's own shipped
    checker: it belongs to the document, not to this repository, and pinning
    itself to the version it shipped with is correct.
    """
    versioned = re.compile(r"ruleborn-game-design-v\d")
    allowed = {"design_doc.py", "check_docs_consistency.py", "audit_register.py"}
    for path in sorted((ROOT / "tools").rglob("*.py")):
        if any(part in ("__pycache__", "vendor") for part in path.parts):
            continue
        if path.name in allowed:
            continue
        text = path.read_text(encoding="utf-8")
        for n, line in enumerate(text.splitlines(), 1):
            if not versioned.search(line):
                continue
            # A usage example in a docstring is documentation, not a constant.
            if path.name == "extract_design_doc.py" and n < 30:
                continue
            fail(f"{rel(path)}:{n} names a version-pinned document filename; "
                 f"import design_doc.HTML or design_doc.TEXT instead")

    # And the declared version must be the one every other check reads.
    import design_doc
    if design_doc.VERSION != current_version():
        fail(f"design_doc.VERSION is {design_doc.VERSION} and the checks read "
             f"v{current_version()}")
    for newer in design_doc.newer_on_disk():
        fail(f"docs/design has a v{newer} document and nothing reads it — "
             f"move design_doc.VERSION, or say why it is sitting there")


#: Files allowed to state a design fact for themselves, and why. Each is a
#: place where importing the shared answer would make a check vacuous or a
#: parser impossible.
OWN_READING = {
    "design_facts.py": "the home",
    "extract_content.py":
        "produces content/*.json, so it needs a vocabulary to recognise the "
        "document's tables before that content exists",
    "validate_content.py":
        "verifies content/*.json against the document. design_facts derives "
        "the notes and roles FROM that content, so importing them here would "
        "turn the check into x == x — a check that cannot fail",
    "check_design_consistency.py":
        "reads the document directly and uses the role and note names as a "
        "parsing vocabulary, the same bootstrap as extract_content",
}


def check_one_fact_home() -> None:
    """D37. A fact the design document states is written down once.

    §31.4 pins four constants in the document's own data and the build checker
    verifies them against the prose. That rule stopped at the document. One
    level out, in the tools that check it, eleven more of its facts were each
    written down two to four times — and three of those sets disagreed:
    `SETTLED` was missing `withdrawn` in one of four homes, `HOLD_BAND` was
    `(30, 45)` in one of four and `(30.0, 45.0)` in the rest, and `CREW` meant
    the range 3-to-5 in one tool and the number 5 in another, which is the same
    name for two facts rather than the same fact twice.

    Four of the repeats restated data this repository had already extracted:
    `content/notes.json` carries the eight notes and their oppositions and
    `content/roles.json` carries the five roles, and four tools typed each out
    again.

    The exceptions in `OWN_READING` are the interesting part. A verifier that
    imports the thing it verifies has written a check that cannot fail, which
    is the fault this whole register is about — so `validate_content` keeps its
    own list on purpose, and the reason is recorded rather than left to be
    rediscovered.
    """
    import design_facts

    owned = {n for n in vars(design_facts)
             if n.isupper() and n not in ("ROOT", "CONTENT", "HOME")}
    for path in sorted((ROOT / "tools").rglob("*.py")):
        if any(part in ("__pycache__", "vendor") for part in path.parts):
            continue
        if path.name in OWN_READING:
            continue
        try:
            tree = ast.parse(path.read_text(encoding="utf-8"))
        except SyntaxError:
            continue                      # check_tools_parse reports this
        for node in tree.body:
            if not isinstance(node, ast.Assign):
                continue
            for target in node.targets:
                if isinstance(target, ast.Name) and target.id in owned:
                    fail(f"{rel(path)}:{node.lineno} states {target.id} for "
                         f"itself; import it from design_facts "
                         f"({design_facts.HOME.get(target.id, 'see that file')})")


def check_artifact_urls(files: list[pathlib.Path]) -> None:
    """One artifact, one URL, everywhere it is mentioned."""
    url = re.compile(r"https://claude\.ai/artifact/([A-Za-z0-9]+)")
    seen: dict[str, set[str]] = {}
    for path in files:
        text = path.read_text(encoding="utf-8")
        for match in url.finditer(text):
            # Group by the sentence context: audit register vs prototype.
            start = max(0, match.start() - 200)
            before = text[start:match.start()].lower()
            if "prototype" in before:
                context = "prototype"
            elif "roadmap" in before or "progress" in before:
                context = "roadmap"
            else:
                context = "audit"
            seen.setdefault(context, set()).add(match.group(1))
    for context, ids in seen.items():
        if len(ids) > 1:
            fail(f"the {context} artifact is referenced under {len(ids)} different "
                 f"URLs: {sorted(ids)}")


def check_tool_output_counts(files: list[pathlib.Path]) -> None:
    """Counts quoted from a tool's own output must match what it prints today.

    docs/analysis/README.md said "six findings and eight other checks" until the
    combat and Vault checks were added, at which point it was wrong and nothing
    noticed. The same trap as C1 and C3, one level up.
    """
    import subprocess

    claim = re.compile(
        r"confirms (\w+) findings and passes (\w+) other", re.I)
    # Counts in prose are spelled out, so the table has to keep up with the
    # counts. It stopped at fourteen and the seventeenth test reported itself as
    # "claims None", which is a checker failing rather than a document failing.
    words = {"one": 1, "two": 2, "three": 3, "four": 4, "five": 5,
             "six": 6, "seven": 7, "eight": 8, "nine": 9, "ten": 10,
             "eleven": 11, "twelve": 12, "thirteen": 13, "fourteen": 14,
             "fifteen": 15, "sixteen": 16, "seventeen": 17, "eighteen": 18,
             "nineteen": 19, "twenty": 20, "twenty-one": 21, "twenty-two": 22,
             "twenty-three": 23, "twenty-four": 24, "twenty-five": 25,
             "thirty": 30, "forty": 40, "fifty": 50}

    def to_int(word: str) -> int | None:
        return words.get(word.lower(), int(word) if word.isdigit() else None)

    def unparsed(path, word: str, what: str) -> None:
        fail(f"{rel(path)}: cannot read {word!r} as a number of {what} — "
             f"add it to this check's word table rather than leaving the claim "
             f"unchecked")

    result = None
    for path in files:
        text = path.read_text(encoding="utf-8")
        for match in claim.finditer(text):
            if result is None:
                out = subprocess.run(
                    [sys.executable, str(ROOT / "tools" / "check_design_consistency.py")],
                    capture_output=True, text=True, cwd=ROOT,
                ).stdout
                result = (out.count("[FAIL]"), out.count("[PASS]"))
            claimed = (to_int(match.group(1)), to_int(match.group(2)))
            if claimed != result:
                fail(f"{rel(path)}: claims {claimed[0]} findings and {claimed[1]} "
                     f"passing checks; check_design_consistency.py reports "
                     f"{result[0]} and {result[1]}")

    tests = re.compile(r"economy model's (\w+) tests")
    for path in files:
        for match in tests.finditer(path.read_text(encoding="utf-8")):
            claimed = to_int(match.group(1))
            actual = sum(
                1 for line in (ROOT / "tools" / "economy_model"
                               / "test_economy_model.py").read_text(encoding="utf-8").split("\n")
                if line.startswith("def test_")
            )
            if claimed is None:
                unparsed(path, match.group(1), "tests")
            elif claimed != actual:
                fail(f"{rel(path)}: claims {claimed} economy-model tests, there are {actual}")


def check_generated_marked() -> None:
    """Generated files must carry their banner, so nobody edits one by hand."""
    for path in GENERATED.glob("*.md"):
        first = path.read_text(encoding="utf-8").split("\n", 1)[0]
        if "GENERATED" not in first:
            fail(f"{rel(path)}: missing the generated-file banner")


def main() -> int:
    files = markdown_files()
    check_counts(files)
    check_links(files)
    check_spec_index()
    check_tool_index()
    check_stale_citations()
    check_document_version(files)
    check_document_links()
    check_register_references()
    check_handoff_table()
    check_spec_status()
    check_tools_parse()
    check_one_status_home()
    check_one_document_home()
    check_one_fact_home()
    check_artifact_urls(files)
    check_generated_marked()
    check_tool_output_counts(files)

    print(f"\nChecked {len(files)} markdown files against a register of "
          f"{len(REGISTER)} items.\n")
    if problems:
        print(f"{len(problems)} inconsistencies in this repository's own documents:\n")
        for p in problems:
            print(f"  ✗ {p}")
        print()
        return 1
    print("  no inconsistencies — counts, links, the spec index, the tools")
    print("  listing, the section citations and the artifact URLs all agree.\n")
    return 0


def _self_test() -> None:
    """Guard against the regex bug that produced a false positive once.

    Run with: python3 tools/check_docs_consistency.py --self-test
    """
    pattern = re.compile(r"\(([a-z0-9_-]+\.md)\)")
    for name in ("first-build.md", "economy.md", "check_all_2.md"):
        assert pattern.findall(f"[x]({name})") == [name], name
    print("  hyphenated and numeric spec file names are matched")

    # The tools listing is read out of a fenced block by shape, so the shape is
    # what can break: a row indented differently, or a directory without its
    # slash, would silently drop out of the listing and stop being checked.
    block = "tools/\n  a_tool.py      does a thing\n  sub_dir/       a directory\n"
    rows = re.search(r"^tools/\n((?:  .*\n)+)", block, re.M)
    assert rows, "the tools block was not found at all"
    found = set(re.findall(r"^  ([a-z0-9_]+(?:\.py|/))", rows.group(1), re.M))
    assert found == {"a_tool.py", "sub_dir/"}, found
    print("  the tools listing is read as both files and directories")

    # And it really is checked against the directory, not just parsed.
    listed = set(re.findall(
        r"^  ([a-z0-9_]+(?:\.py|/))",
        re.search(r"^tools/\n((?:  .*\n)+)",
                  (ROOT / "README.md").read_text(encoding="utf-8"),
                  re.M).group(1), re.M))
    missing = {p.name for p in (ROOT / "tools").glob("*.py")} - listed
    assert not missing, missing
    print(f"  and README.md lists all {len(listed)} entries in tools/")
    # The stale-citation check, which has three ways to let a number through
    # and so three ways to be wrong.
    import check_document
    doc = check_document.Doc(check_document.DEFAULT_DOC).text
    sections = set(re.findall(r"^(\d+\.\d+) ", doc, re.M))
    assert "5.8" in sections and "5.9" not in sections, "5.9 should be gone"
    assert "25.4" in sections and "25.5" not in sections, "25.5 should be gone"
    for old_num, new_num in RENUMBERED.items():
        assert old_num not in sections, f"{old_num} still exists"
        assert new_num in sections, f"{new_num} does not exist"
    print(f"  all {len(RENUMBERED)} renumbered sections are gone and their "
          f"replacements exist")

    # The verdict table, which is the one thing in the README somebody acts on
    # directly. It is checked in place rather than against a fixture: a table
    # planted in a string would prove the regex works and not that the README
    # is wired to it.
    global problems
    text = (ROOT / "README.md").read_text(encoding="utf-8")
    for label, planted, expect in (
        # The plant is derived, not typed: an earlier version replaced the
        # literal "| **Screens** | Not yet |" and stopped planting anything the
        # day screens moved to "Waiting on you" — a self-test whose fixture is
        # a copy of live state, which is the fault this whole file checks for,
        # committed inside the check for it.
        ("a Ready that is not true",
         re.sub(r"^(\| \*\*[A-Za-z]+\*\* \| )(?!Ready)[^|]+(\|)",
                r"\1Ready \2", text, count=1, flags=re.M),
         "its gates make it"),
        ("a gate quietly dropped from the list",
         # The first id, whether or not others follow: since v3.3 each area
         # waits on one item, and a plant that needs two plants nothing. And
         # whoever holds it: v3.4 moved the one left from "your decision" to
         # "my drafting", and a plant keyed to one owner's words planted
         # nothing the day the owner changed.
         re.sub(r"^(\| \*\*[A-Za-z]+\*\* \| [^|]+ \| [^|]*?)\b[A-Z]+\d+\b(?:, )?",
                r"\1", text, count=1, flags=re.M),
         "waiting on"),
        ("an area missing from the table",
         re.sub(r"^\| \*\*Characters\*\*.*\n", "", text, flags=re.M),
         "does not mention"),
    ):
        assert planted != text, f"could not plant {label}"
        (ROOT / "README.md").write_text(planted, encoding="utf-8")
        was, problems = problems, []
        try:
            check_handoff_table()
            caught = any(expect in p for p in problems)
        finally:
            problems = was
            (ROOT / "README.md").write_text(text, encoding="utf-8")
        assert caught, f"{label} went unnoticed"
        print(f"  a README verdict table with {label} is caught")

    # A tool that stops parsing. Planted in the tree rather than in a string,
    # because the check walks the tree — a fixture would prove the `ast` call
    # works and not that the walk reaches anything.
    broken = ROOT / "tools" / "_selftest_broken.py"
    broken.write_text('def f(:\n', encoding="utf-8")
    was, problems = problems, []
    try:
        check_tools_parse()
        caught = any("_selftest_broken" in p and "does not parse" in p
                     for p in problems)
    finally:
        problems = was
        broken.unlink()
    assert caught, "a tool that does not parse went unnoticed"
    print("  a tool under tools/ that stops parsing is caught")

    # A second home for the effective status. Planted as the exact expression
    # that was in four files, because that is the one that came back.
    copy = ROOT / "tools" / "_selftest_status.py"
    copy.write_text(
        'def status_of(item):\n'
        '    return (V31.get(item["id"], {}).get("status")\n'
        '            or V3.get(item["id"], {}).get("status")\n'
        '            or item.get("status", "open"))\n', encoding="utf-8")
    was, problems = problems, []
    try:
        check_one_status_home()
        caught = any("_selftest_status" in p for p in problems)
    finally:
        problems = was
        copy.unlink()
    assert caught, "a second copy of the effective status went unnoticed"
    print("  a tool working out an item's status for itself is caught")

    # A tool pinning itself to a version, and a newer document nobody reads.
    # Both planted on disk rather than in a string: the check walks the tree
    # and a fixture would prove the regex works, not that the walk arrives.
    import design_doc
    pinned = ROOT / "tools" / "_selftest_pinned.py"
    # Built rather than written out, so this file does not itself contain a
    # version-pinned filename for the checks above to find.
    stem = "ruleborn-game-design-v"
    pinned.write_text(f'DOC = "docs/design/{stem}3.0.txt"\n', encoding="utf-8")
    ahead = design_doc.DESIGN / f"{stem}9.9.txt"
    ahead.write_text("a draft nobody reads\n", encoding="utf-8")
    was, problems = problems, []
    try:
        check_one_document_home()
        found = "; ".join(problems)
    finally:
        problems = was
        pinned.unlink()
        ahead.unlink()
    assert "_selftest_pinned" in found, "a pinned document filename went unnoticed"
    assert "v9.9" in found, "a newer document nobody reads went unnoticed"

    # A tool stating a design fact for itself.
    restated = ROOT / "tools" / "_selftest_fact.py"
    restated.write_text("HOLD_BAND = (30, 45)\n", encoding="utf-8")
    was, problems = problems, []
    try:
        check_one_fact_home()
        caught = any("_selftest_fact" in p and "HOLD_BAND" in p for p in problems)
    finally:
        problems = was
        restated.unlink()
    assert caught, "a tool restating a design fact went unnoticed"
    print("  a tool pinned to a document version is caught, a newer document\n"
          "  sitting unread is caught, and so is a tool restating a design fact")

    for text, allowed in (("see \u00a75.9 for the rule", False),
                          ("v3.0's \u00a75.9, renumbered \u00a75.8 in v3.1", True),
                          ("an earlier version's \u00a713.5", True),
                          ("\u00a75.8 is the rule", True)):
        stale = [m.group(1) for m in CITE.finditer(text)
                 if m.group(1) not in sections]
        passes = not stale or bool(HISTORICAL.search(text))
        assert passes is allowed, (text, stale, passes)
    print("  a bare stale number is caught; one marked historical is allowed")

    # Run the check for real rather than reading `problems`, which the
    # self-test reaches before main() has filled it — an assertion against an
    # empty list passes for ever and says nothing.
    before = len(problems)
    check_stale_citations()
    got = problems[before:]
    del problems[before:]
    assert not got, f"{len(got)} stale citations in this repository: {got[:3]}"
    print(f"  and all {len(prose_files())} prose files cite only sections "
          f"v3.1 has")
    # The counts the README states, each mutated by one and shown to fail.
    check_counts(markdown_files())
    del problems[:]
    from audit_register import EDITS, V3, V31, status
    fixed = sum(1 for i in REGISTER if status(i) == "fixed")
    by_v3 = sum(1 for i in REGISTER if V3.get(i["id"], {}).get("status") == "fixed")
    by_v31 = sum(1 for i in REGISTER if V31.get(i["id"], {}).get("status") == "fixed")
    edits = sum(len(v) for v in EDITS.values())
    sentences = {
        "items fixed in the document":
            f"**{{}} of {len(REGISTER)} register items are fixed",
        "items tracked": f"**{fixed} of {{}} register items are fixed",
        "items fixed by v3.0": f"{{}} by v3.0 and {by_v31} more by v3.1",
        "items fixed by v3.1": f"{by_v3} by v3.0 and {{}} more by v3.1",
        "drafted edits": f"{{}} are drafted across {len(EDITS)}",
        "items carrying an edit": f"{edits} are drafted across {{}}",
    }
    truth = {"items fixed in the document": fixed, "items tracked": len(REGISTER),
             "items fixed by v3.0": by_v3, "items fixed by v3.1": by_v31,
             "drafted edits": edits, "items carrying an edit": len(EDITS)}
    for label, shape in sentences.items():
        right = check_counts.problems(shape.format(truth[label]))
        wrong = check_counts.problems(shape.format(truth[label] + 1))
        good = not right and any(label in w for w in wrong)
        assert good, (label, right, wrong)
    print(f"  all {len(sentences)} register counts the README states are "
          f"checked, and each fails when it is off by one")

    now = current_version()
    assert re.fullmatch(r"\d+\.\d+", now), now
    doc = design_doc.HTML
    assert doc.exists(), doc
    print(f"  the version the checks read is v{now}, and that document exists")
    print("self-test passed")


if "--self-test" in sys.argv:
    _self_test()
    raise SystemExit(0)


if __name__ == "__main__":
    raise SystemExit(main())
