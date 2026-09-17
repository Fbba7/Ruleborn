#!/usr/bin/env python3
"""Regenerate every derived table in the document from its source of truth.

A derived table is one whose every cell can be computed from data stated
elsewhere. Those tables are never hand-written: they are emitted here,
wrapped in <!--gen:HASH--> ... <!--/gen--> where HASH is a digest of the
rendered text. tools/check.py recomputes the digest, so a hand edit to a
generated table fails the build instead of silently disagreeing with its
source.

Usage: python3 tools/generate.py build/ruleborn-game-design-v30.html
"""
import re
import sys
import html
import json
import hashlib
import collections

DOC = sys.argv[1] if len(sys.argv) > 1 else "build/ruleborn-game-design-v30.html"
RAW = open(DOC, encoding="utf-8").read()
PAGES = {"Common": 10, "Uncommon": 20, "Rare": 35, "Deep": 60}
SCHOOLS = ["Motion", "Matter", "Time", "Energy", "Life", "Spirit"]


def strip(x):
    return html.unescape(re.sub(r"\s+", " ", re.sub(r"<[^>]+>", " ", x)))


def wrap(inner):
    """Wrap a rendered block in its own content hash."""
    h = hashlib.sha256(strip(inner).strip().encode()).hexdigest()[:12]
    return f"<!--gen:{h}-->{inner}<!--/gen-->"


def splice(raw, marker, block):
    """Replace the generated block that follows `marker`, or insert one."""
    i = raw.find(marker)
    if i < 0:
        raise SystemExit(f"anchor not found: {marker!r}")
    j = i + len(marker)
    if raw[j:].lstrip().startswith("<!--gen:"):
        s = raw.index("<!--gen:", j)
        e = raw.index("<!--/gen-->", s) + len("<!--/gen-->")
        return raw[:s] + block + raw[e:]
    return raw[:j] + "\n" + block + raw[j:]


# ------------------------------------------------ source of truth: the laws
sec = RAW[RAW.find('<section id="laws">'):RAW.find("</section>", RAW.find('<section id="laws">'))]
parts = re.split(r"<h4[^>]*>(.*?)</h4>", sec, flags=re.S)
by_school = {}
for k in range(1, len(parts), 2):
    name = strip(parts[k]).strip()
    c = collections.Counter(r for r, _ in re.findall(r">(Common|Uncommon|Rare|Deep), (\d+)<", parts[k + 1]))
    if sum(c.values()):
        by_school[name] = c
totals = collections.Counter()
for c in by_school.values():
    totals.update(c)

rows = []
for school in SCHOOLS:
    c = by_school.get(school, collections.Counter())
    pages = sum(PAGES[r] * n for r, n in c.items())
    rows.append(
        "<tr><td data-label=\"School\">%s</td>%s<td class=\"n\" data-label=\"Laws\">%d</td>"
        "<td class=\"n\" data-label=\"Pages\">%d</td></tr>"
        % (school,
           "".join(f'<td class="n" data-label="{r}">{c.get(r, 0)}</td>' for r in PAGES),
           sum(c.values()), pages))
grand = sum(PAGES[r] * n for r, n in totals.items())
rows.append(
    "<tr><td data-label=\"School\"><strong>All six</strong></td>%s"
    "<td class=\"n\" data-label=\"Laws\"><strong>%d</strong></td>"
    "<td class=\"n\" data-label=\"Pages\"><strong>%s</strong></td></tr>"
    % ("".join(f'<td class="n" data-label="{r}"><strong>{totals.get(r, 0)}</strong></td>' for r in PAGES),
       sum(totals.values()), f"{grand:,}"))

law_table = (
    '<div class="table-wrap"><table>\n'
    '<tr><th>School</th>' + "".join(f'<th class="n">{r}</th>' for r in PAGES) + '<th class="n">Laws</th><th class="n">Pages</th></tr>\n'
    + "\n".join(rows) + "\n</table></div>\n"
    '<p class="gen-note">Generated from the law tables in 7.4 by <code>tools/generate.py</code>. '
    "Do not edit by hand: the build recomputes it and fails if the two disagree.</p>")

# ------------------------------------------------ source of truth: constants
consts = json.load(open("data/constants.json", encoding="utf-8"))
crows = "\n".join(
    f'<tr><td data-label="Constant">{k.replace("_", " ")}</td>'
    f'<td class="n" data-label="Value">{v["value"]}</td>'
    f'<td data-label="Unit">{v["unit"]}</td>'
    f'<td data-label="Defined in">{v["home"]}</td></tr>'
    for k, v in consts.items())
const_table = (
    '<div class="table-wrap"><table>\n'
    '<tr><th>Constant</th><th class="n">Value</th><th>Unit</th><th>Defined in</th></tr>\n'
    + crows + "\n</table></div>\n"
    '<p class="gen-note">Generated from <code>data/constants.json</code>. Each constant has exactly one '
    "home in this document; every other mention is checked against it.</p>")

out = RAW
out = splice(out, "<!--anchor:law-summary-->", wrap(law_table))
out = splice(out, "<!--anchor:constants-->", wrap(const_table))
open(DOC, "w", encoding="utf-8").write(out)
print(f"regenerated 2 blocks: law summary ({sum(totals.values())} laws, {grand:,} pages), "
      f"constants ({len(consts)} entries)")
