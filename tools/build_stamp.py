#!/usr/bin/env python3
"""One build stamp for every page this repository publishes.

    python3 tools/build_stamp.py             # every artifact, with its stamp
    python3 tools/build_stamp.py --self-test # proves the stamps still move

A published page and the page in the repository look nothing alike — the
publish pipeline rewrites the head, so they are never byte-identical and
comparing them directly is useless. Comparing dates is worse: the artifact
listing reports only a calendar day, so a commit and a publish on the same day
are indistinguishable, and the republish job built on that comparison would have
answered "already current" for ever from the first day the two coincided (D28).

So each page carries a digest of itself with its own stamp line removed. The
question the republish job asks becomes the one that actually matters — *is the
published page this page?* — and it has a straight answer.

Two marker forms, because the pages are different kinds of thing. The prototype
keeps its stamp as a JavaScript constant, so it can show it on screen; the
generated pages carry an HTML comment. `digest` strips both before hashing, so
one algorithm covers all three.
"""

import hashlib
import pathlib
import re
import sys

ROOT = pathlib.Path(__file__).resolve().parent.parent

# The HTML comment form, for pages that are generated whole.
COMMENT = re.compile(r'[ \t]*<!-- ruleborn-build [0-9a-f]* -->\n?')
# The JavaScript form, for the prototype, which displays its own stamp.
CONSTANT = re.compile(r'^ *BUILD: "[0-9a-f]*",\n', re.M)

# Every page this repository publishes, and where it publishes to.
ARTIFACTS = [
    ("prototype", "prototypes/heist-gate/index.html",
     "https://claude.ai/artifact/3jW7Zg1rTrzR6CF3cEVp2E"),
    ("audit", "docs/audit/index.html",
     "https://claude.ai/artifact/8m5MgpjWfFurnfwc6b76sN"),
    ("roadmap", "docs/roadmap/index.html",
     "https://claude.ai/artifact/Yb1WxZ2eJCCbByitnd7fJf"),
]


def digest(page: str) -> str:
    """Sixteen hex characters identifying this page, stamp line excluded."""
    bare = CONSTANT.sub("", COMMENT.sub("", page))
    return hashlib.sha256(bare.encode("utf-8")).hexdigest()[:16]


def stamped(html: str) -> str:
    """Return `html` carrying its own digest, as a comment before </body>."""
    bare = COMMENT.sub("", html)
    mark = f"<!-- ruleborn-build {digest(bare)} -->\n"
    if "</body>" in bare:
        return bare.replace("</body>", mark + "</body>", 1)
    return bare + mark


def self_test() -> int:
    """A stamp is only useful if it moves, and only safe if it settles."""
    page = "<html><body>\n<p>one</p>\n</body></html>"
    once, twice = stamped(page), stamped(stamped(page))
    if once != twice:
        print("  stamping twice does not settle — the stamp chases itself.")
        return 1
    if f"<!-- ruleborn-build {digest(once)} -->" not in once:
        print("  a stamped page does not carry its own digest.")
        return 1
    if digest(once) == digest(stamped(page.replace("one", "two"))):
        print("  the stamp did not move when the page did — it is a constant.")
        return 1
    if digest(page) != digest(once):
        print("  stamping a page changed its digest; the stamp is being hashed.")
        return 1

    for name, rel, _ in ARTIFACTS:
        path = ROOT / rel
        if not path.exists():
            print(f"  {name} is missing from disk: {rel}")
            return 1
        text = path.read_text(encoding="utf-8")
        if not (COMMENT.search(text) or CONSTANT.search(text)):
            print(f"  {name} carries no build stamp. Rebuild it.")
            return 1
    print(f"  {len(ARTIFACTS)} published pages carry a live build stamp.")
    return 0


def main() -> int:
    if "--self-test" in sys.argv:
        return self_test()
    missing = 0
    for name, rel, url in ARTIFACTS:
        path = ROOT / rel
        if not path.exists():
            print(f"  {name:10} MISSING  {rel}")
            missing += 1
            continue
        print(f"  {name:10} {digest(path.read_text(encoding='utf-8'))}  {rel}  {url}")
    return 1 if missing else 0


if __name__ == "__main__":
    raise SystemExit(main())
