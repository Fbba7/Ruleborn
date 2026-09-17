#!/usr/bin/env python3
"""Extract the plain text of the Ruleborn design document from its HTML export.

The HTML export is ~1.6 MB, of which ~95% is embedded base64 fonts and inline SVG
figures. This strips those and emits a greppable plain-text rendering, so the
design can be searched, diffed between versions, and cross-checked by scripts.

Usage:
    python3 tools/extract_design_doc.py \
        docs/design/ruleborn-game-design-v3.1.html \
        docs/design/ruleborn-game-design-v3.1.txt

Table cells are emitted as "| cell" lines, one per line, which is what the
consistency checks in tools/ rely on.
"""

import html
import re
import sys


def extract(src: str) -> str:
    # Drop style and script blocks (embedded fonts live in <style>).
    s = re.sub(r"<style.*?</style>", "", src, flags=re.S | re.I)
    s = re.sub(r"<script.*?</script>", "", s, flags=re.S | re.I)

    # Drop long data: URIs and inline SVG figures, leaving a marker.
    s = re.sub(r"data:[^\"'()\s]{200,}", "[DATA]", s)
    s = re.sub(r"<svg.*?</svg>", "[SVG]", s, flags=re.S | re.I)

    # Block-level tags become newlines; table cells become "| " prefixes.
    block = (
        "br|/p|/div|/h[1-6]|/li|/tr|/td|/th|/section|/article|"
        "/table|/ul|/ol|/blockquote|/pre"
    )
    s = re.sub(rf"<({block})[^>]*>", "\n", s, flags=re.I)
    s = re.sub(
        r"<(h[1-6]|p|div|li|tr|section|article|table|ul|ol|blockquote|pre)[^>]*>",
        "\n",
        s,
        flags=re.I,
    )
    s = re.sub(r"<t[dh][^>]*>", " | ", s, flags=re.I)

    # Remaining tags, then entities.
    s = re.sub(r"<[^>]+>", "", s)
    s = html.unescape(s)

    # Tidy whitespace.
    s = re.sub(r"[ \t]+", " ", s)
    s = re.sub(r"\n[ \t]+", "\n", s)
    s = re.sub(r"\n{3,}", "\n\n", s)
    return s.strip() + "\n"


def main() -> int:
    if len(sys.argv) != 3:
        print(__doc__, file=sys.stderr)
        return 2
    src_path, out_path = sys.argv[1], sys.argv[2]
    with open(src_path, encoding="utf-8") as fh:
        src = fh.read()
    text = extract(src)
    with open(out_path, "w", encoding="utf-8") as fh:
        fh.write(text)
    print(f"{src_path} ({len(src):,} bytes) -> {out_path} ({len(text.split()):,} words)")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
