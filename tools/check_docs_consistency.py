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
    """Counts claimed in prose must match the register."""
    kinds = {
        "contradiction": sum(1 for i in REGISTER if i["kind"] == "contradiction"),
        "gap": sum(1 for i in REGISTER if i["kind"] == "gap"),
    }
    total = len(REGISTER)

    patterns = [
        (re.compile(r"(\d+)\s+confirmed internal contradictions"), kinds["contradiction"],
         "confirmed internal contradictions"),
        (re.compile(r"tracked as (\d+) items"), total, "items tracked"),
        (re.compile(r"as (\d+) tracked items"), total, "items tracked"),
        (re.compile(r"register is at (\d+)", re.I), total, "register size"),
        (re.compile(r"(\d+) (?:specification )?gaps\b"), kinds["gap"], "gaps"),
    ]
    for path in files:
        text = path.read_text(encoding="utf-8")
        for pattern, expected, label in patterns:
            for match in pattern.finditer(text):
                claimed = int(match.group(1))
                if claimed != expected:
                    fail(f"{rel(path)}: claims {claimed} {label}, register has {expected}")


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
    check_register_references()
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
    print("  listing and the artifact URLs all agree.\n")
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
    print("self-test passed")


if "--self-test" in sys.argv:
    _self_test()
    raise SystemExit(0)


if __name__ == "__main__":
    raise SystemExit(main())
