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


def problems(text):
    out = []
    lines = text.splitlines()
    top = {m.group(1) for line in lines if (m := re.match(r"^([A-Za-z_-]+):", line))}
    if "on" not in top:
        out.append("no top-level on:")
    for event in ("push", "pull_request"):
        if not re.search(rf"^  {event}:", text, re.M):
            out.append(f"does not run on {event}")
    if not re.search(r"^permissions:\n  contents: read\s*$", text, re.M):
        out.append("permissions is not exactly contents: read")
    uses = re.findall(r"uses:\s*(\S+)", text)
    if not uses:
        out.append("uses no checkout")
    for ref in uses:
        if not re.fullmatch(r"[\w.-]+/[\w.-]+@[0-9a-f]{40}", ref):
            out.append(f"action not pinned to a commit SHA: {ref}")
    for command in REQUIRED:
        if command not in text:
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
