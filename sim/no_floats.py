#!/usr/bin/env python3
"""§24.10: "The simulation refuses to compile if one appears."

    python3 sim/no_floats.py

The document states that as a property of the build, so it is one. Floating
point is the single largest cause of the divergence T3.1 exists to rule out:
the same expression can be evaluated at different precisions on different
processors, and x87, SSE and WebAssembly do not have to agree.

This reads the crate's own sources. `build_table.py` uses decimal arithmetic
and is not part of the crate; it runs once and commits integers.
"""

import pathlib
import re
import sys

SRC = pathlib.Path(__file__).resolve().parent / "src"

#: A float type, a float literal, or a libm call. Written out rather than
#: matched loosely, because a rule that catches the word "offset" would be
#: turned off within a week.
BANNED = [
    (re.compile(r"\bf32\b|\bf64\b"), "a floating-point type"),
    (re.compile(r"(?<![\w.])\d+\.\d+(?![\w.])"), "a decimal literal"),
    (re.compile(r"\bas\s+f(?:32|64)\b"), "a cast to floating point"),
    (re.compile(r"\b(?:std|core)::f(?:32|64)\b"), "the float module"),
]

# There was a fourth rule here banning calls named sqrt, sin and cos, and it
# was wrong for the reason F24 is about: it caught this crate's own integer
# `sqrt` and `sin` — the replacements for libm, not the hazard — and would
# have been switched off within a day.
#
# The name is not the thing. A libm call needs a float argument, a float
# argument needs an `f32` or an `f64`, and those are caught above exactly. The
# three rules that remain are the ones that cannot be satisfied by rewording.

#: Lines allowed to mention one, with why. A section number in a comment is
#: not a decimal literal, and there is no way to tell them apart by pattern.
ALLOW = re.compile(r"^\s*(//|///|//!|\*)")


#: A string literal is text, not arithmetic. "§24.10" in a panic message is a
#: section number and `0.5` in one is a number a human will read — neither is
#: an expression a processor evaluates, and the ban is about expressions. This
#: strips quoted spans before the rules run, which is what stopped the check
#: reporting its own error messages.
TEXT = re.compile(r'"(?:[^"\\]|\\.)*"')


def strip_text(code: str) -> str:
    return TEXT.sub('""', code)


def main() -> int:
    problems = []
    for path in sorted(SRC.rglob("*.rs")):
        for n, line in enumerate(path.read_text().splitlines(), 1):
            if ALLOW.match(line):
                continue
            code = strip_text(line.split("//")[0])
            for pattern, what in BANNED:
                m = pattern.search(code)
                if m:
                    problems.append(
                        f"{path.relative_to(SRC.parent)}:{n} {what}: "
                        f"{m.group(0)!r} in {line.strip()[:70]!r}")
    if problems:
        print("The simulation contains floating point, which 24.10 forbids:\n")
        for p in problems:
            print(f"  {p}")
        return 1
    files = len(list(SRC.rglob("*.rs")))
    print(f"  no floating point in {files} source files — "
          f"types, literals, casts and libm all absent")
    return 0


if __name__ == "__main__":
    sys.exit(main())
