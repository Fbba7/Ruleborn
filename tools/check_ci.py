#!/usr/bin/env python3
"""The CI workflow is there and runs what it must (SEC-28).

    python3 tools/check_ci.py

.github/workflows/checks.yml must run on every push and pull request, with
read-only contents permission, every action pinned to a full commit SHA, and
every check below. Branch protection, which makes it binding, is a setting on
GitHub and cannot be checked from here.
"""
import pathlib
import re
import sys

ROOT = pathlib.Path(__file__).resolve().parent.parent
WORKFLOW = ROOT / ".github" / "workflows" / "checks.yml"

# What the workflow must run, as text it must contain.
REQUIRED = [
    "cargo build --locked --release --target wasm32-unknown-unknown",
    "npm test",
    "cargo test --locked",
    "python3 tools/check_docs_consistency.py",
    "python3 tools/coord/owners.py --self-test",
    "CHECK_TEST_REQUIRE_BWRAP=1 bash tools/test_run_checks.sh",
    "bash client/test_export.sh",
    "python3 tools/check_ci.py",
]


def permissions(lines):
    """The top-level permissions: block, as {key: value}, or None if absent.

    FX1-T-08: the block runs to the next top-level key, so a line added
    under it is read, not ignored. A value on the permissions: line itself
    (write-all, read-all) is kept under the key "".
    """
    for i, line in enumerate(lines):
        m = re.match(r"^permissions:(.*)$", line)
        if not m:
            continue
        block = {}
        if m.group(1).split("#")[0].strip():
            block[""] = m.group(1).split("#")[0].strip()
        for entry in lines[i + 1:]:
            if entry.strip() == "" or entry.lstrip().startswith("#"):
                continue
            if not entry.startswith((" ", "\t")):
                break
            key, _, value = entry.split("#")[0].strip().partition(":")
            block[key.strip()] = value.strip()
        return block
    return None


def run_lines(lines):
    """The shell lines of every run: step, with comments cut away.

    FX1-T-08: a required command counts only where a step runs it, so one
    turned into a comment, or sitting in a step's name, does not.
    """
    out = []
    i = 0
    while i < len(lines):
        m = re.match(r"^(\s*)(?:- )?run:\s*(.*)$", lines[i])
        i += 1
        if not m:
            continue
        indent, first = len(m.group(1)), m.group(2)
        if first.strip() in ("|", ">", "|-", ">-", "|+", ">+"):
            while i < len(lines) and (lines[i].strip() == ""
                                      or len(lines[i]) - len(lines[i].lstrip()) > indent):
                out.append(lines[i])
                i += 1
        else:
            out.append(first)
    return [re.split(r"(?:^|\s)#", line, maxsplit=1)[0].strip() for line in out]


def problems(text):
    out = []
    lines = text.splitlines()
    top = {m.group(1) for line in lines if (m := re.match(r"^([A-Za-z_-]+):", line))}
    if "on" not in top:
        out.append("no top-level on:")
    for event in ("push", "pull_request"):
        if not re.search(rf"^  {event}:", text, re.M):
            out.append(f"does not run on {event}")
    if permissions(lines) != {"contents": "read"}:
        out.append("permissions is not exactly contents: read")
    uses = re.findall(r"uses:\s*(\S+)", text)
    if not uses:
        out.append("uses no checkout")
    for ref in uses:
        if not re.fullmatch(r"[\w.-]+/[\w.-]+@[0-9a-f]{40}", ref):
            out.append(f"action not pinned to a commit SHA: {ref}")
    runs = run_lines(lines)
    for command in REQUIRED:
        if not any(command in line for line in runs):
            out.append(f"does not run: {command}")
    return out


def self_test():
    good = WORKFLOW.read_text() if WORKFLOW.exists() else None
    bad = [
        ("", "does not run on push"),
        ("on:\n  push:\npermissions:\n  contents: write\n", "permissions is not exactly contents: read"),
        ("uses: actions/checkout@v6\n", "action not pinned to a commit SHA: actions/checkout@v6"),
    ]
    for text, expected in bad:
        assert expected in problems(text), (expected, problems(text))
    if good is not None:
        assert "does not run: npm test" in problems(good.replace("npm test", "npm tst"))
        # FX1-T-08: a wider block, a commented-out command, and one that is
        # only named, not run.
        perm = "permissions:\n  contents: read\n"
        assert perm in good
        for extra in ("  actions: write\n", "  # a note\n  id-token: write\n"):
            assert "permissions is not exactly contents: read" in problems(
                good.replace(perm, perm + extra)), extra
        assert "permissions is not exactly contents: read" in problems(
            good.replace(perm, "permissions: write-all\n"))
        for cut in ("# npm test", "echo ok # npm test"):
            assert "does not run: npm test" in problems(good.replace("npm test", cut, 1)), cut
        named = good.replace("run: npm test", "run: echo skipped")
        assert named != good and "does not run: npm test" in problems(named)


def main():
    self_test()
    if not WORKFLOW.exists():
        print(f"check_ci: {WORKFLOW.relative_to(ROOT)} is missing")
        return 1
    found = problems(WORKFLOW.read_text())
    for p in found:
        print(f"check_ci: {p}")
    if found:
        return 1
    print("check_ci: the workflow runs on push and pull request, pinned, with every check")
    return 0


if __name__ == "__main__":
    sys.exit(main())
