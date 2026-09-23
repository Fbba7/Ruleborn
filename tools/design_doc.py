#!/usr/bin/env python3
"""Which design document every check reads, in one place.

    python3 tools/design_doc.py            # the version, the files, what else is on disk

Why this exists
---------------
The document's filename carries its version, so every tool that opens it holds
a copy of "which version are we on". There were **nine** of those, across six
files, and nothing compared them.

That is D30, which was exactly this: `extract_content.py` built the content
tables from v3.0 and `validate_content.py` validated them against v3.0, so the
pair agreed and three of v3.1's improvements were invisible. D30 was fixed by
editing the two filenames, which leaves the next version to find the other
seven — and `check_document_version` could not help, because it reads prose
naming a version and these are paths.

So the version is declared once, here, and `check_docs_consistency.
check_one_document_home` refuses a version-pinned document filename anywhere
else. Two exceptions are named there and both are honest: `extract_design_doc`
converts one version's HTML into its own text and names both on purpose, and
`tools/vendor/` is the document's own shipped checker, which belongs to the
document rather than to this repository.

Why a constant rather than "the newest file present"
----------------------------------------------------
Reading the newest would never go stale, and would also repoint every gate in
the repository the moment a draft landed in `docs/design/`, before anyone
decided it was the one to read. The constant keeps that a decision, and
`newer_on_disk()` makes forgetting it a build message rather than a silence:
the checks say a newer document exists and nothing reads it.
"""

import pathlib
import re
import sys

ROOT = pathlib.Path(__file__).resolve().parent.parent
DESIGN = ROOT / "docs" / "design"

#: The version every check in this repository reads. Changing it is the whole
#: of moving to a new document; nothing else names a version.
VERSION = "3.3"

STEM = f"ruleborn-game-design-v{VERSION}"
HTML = DESIGN / f"{STEM}.html"
TEXT = DESIGN / f"{STEM}.txt"

#: Filenames that carry a version, which only this module may write.
VERSIONED = re.compile(r"ruleborn-game-design-v(\d+\.?\d*)\.(?:html|txt)")


def on_disk() -> list[str]:
    """Every document version present, oldest first."""
    seen = {m.group(1) for p in DESIGN.glob("*")
            if (m := VERSIONED.fullmatch(p.name))}
    return sorted(seen, key=lambda v: [int(x) for x in v.split(".")])


def text_of(version: str) -> pathlib.Path:
    """The text view of any version on disk, for a tool that reads history.

    Only this module writes versioned filenames; a tool that needs an older
    version asks for it by number rather than spelling the name.
    """
    return DESIGN / f"ruleborn-game-design-v{version}.txt"


def newer_on_disk() -> list[str]:
    """Versions newer than the one the checks read.

    Not a failure on its own: a draft may sit beside the current document for
    a while. It is a failure to leave it there unread without saying so.
    """
    key = [int(x) for x in VERSION.split(".")]
    return [v for v in on_disk() if [int(x) for x in v.split(".")] > key]


def main() -> int:
    print(f"The checks read v{VERSION}.")
    print(f"  {HTML.relative_to(ROOT)}  {'ok' if HTML.exists() else 'MISSING'}")
    print(f"  {TEXT.relative_to(ROOT)}   {'ok' if TEXT.exists() else 'MISSING'}")
    print(f"\nOn disk: {', '.join('v' + v for v in on_disk())}")
    newer = newer_on_disk()
    if newer:
        print(f"\n  A newer document is present and nothing reads it: "
              f"{', '.join('v' + v for v in newer)}.")
        print("  Move VERSION here, then run the gates: everything that names "
              "a version\n  follows from this one line.")
    if not (HTML.exists() and TEXT.exists()):
        print("\n  The declared version is not on disk.")
        return 1
    return 0


if __name__ == "__main__":
    sys.exit(main())
