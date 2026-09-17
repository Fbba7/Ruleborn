#!/usr/bin/env python3
"""Mutation test for tools/check.py.

Brief 1's tenth checklist item: a gate that has never been seen to fail is
not evidence of anything. This injects a known defect of each class into a
copy of the document and asserts the checker catches it. If any mutation
survives, the corresponding check is decorative and the build is not
trustworthy.

Usage: python3 tools/mutate.py build/ruleborn-game-design-v30.html
"""
import re
import sys
import subprocess
import tempfile
import os

DOC = sys.argv[1] if len(sys.argv) > 1 else "build/ruleborn-game-design-v30.html"
SRC = open(DOC, encoding="utf-8").read()

MUTATIONS = [
    # (name, expected failing check substring, mutate function)
    ("constant restated with a different value", "constant tick_rate",
     lambda s: s.replace("fixed 30 steps a second", "fixed 20 steps a second", 1)),
    ("retired name reintroduced in normative text", "retired name absent: Lawbound",
     lambda s: s.replace("<h3>1.1 The pitch</h3>", "<h3>1.1 The pitch</h3><p>Lawbound is a strategy game.</p>", 1)),
    ("stale three-rank prose returns", "no stale three-rank prose",
     lambda s: s.replace("<h3>7.2 Schools</h3>", "<h3>7.2 Schools</h3><p>Each school has three common, three rare and two deep laws.</p>", 1)),
    ("a law row deleted without updating the count", "law table totals 48",
     lambda s: s.replace('<td data-label="Rank, stability cost">Common, 14</td>', "", 1)),
    ("page arithmetic no longer re-derives", "stated page total equals",
     lambda s: s.replace("= 1,350 pages in total", "= 1,400 pages in total", 1)),
    ("a citation points at a source that does not exist", "no dangling citations",
     lambda s: s.replace('<h3>1.1 The pitch</h3>', '<h3>1.1 The pitch</h3><p><a href="#ref-999">[999]</a></p>', 1)),
    ("a cross-reference points nowhere", "all internal links resolve",
     lambda s: s.replace('<h3>1.1 The pitch</h3>', '<h3>1.1 The pitch</h3><p><a href="#no-such-anchor">see</a></p>', 1)),
    ("subsection numbers go backwards", "subsection numbers ascending",
     lambda s: s.replace("<h3>1.2 The seven pillars</h3>", "<h3>1.0 The seven pillars</h3>", 1)),
    ("a generated table is hand-edited", "generated blocks match their hash",
     lambda s: re.sub(r"(<!--gen:[0-9a-f]{12}-->)", r"\1<tr><td>hand-added row</td></tr>", s, count=1)),
    ("an audit item is left open", "no open audit items",
     lambda s: s.replace('<section id="decisions">', '<section id="decisions"><span>OPEN</span>', 1)),
    ("percent-based awareness leaks back in", "superseded model absent: percent awareness",
     lambda s: s.replace("<h3>1.1 The pitch</h3>", "<h3>1.1 The pitch</h3><p>Nearby guards start at 25% awareness.</p>", 1)),
    ("the roster and the character bible disagree on a role", "roster and character bible agree",
     lambda s: s.replace('>Featherkin</span><span class="lawmeta">Scout · Motion',
                         '>Featherkin</span><span class="lawmeta">Breaker · Motion', 1)),
    ("a creature's proportions fall outside the art range", "proportions sit inside",
     lambda s: s.replace("1.7 to 2.9 heads tall", "2.0 to 2.5 heads tall", 1)),
    ("the Library cost table stops matching its own curve", "Library cost table reproduces",
     lambda s: s.replace('<td class="n" data-label="Cost">36,200</td>',
                         '<td class="n" data-label="Cost">45,000</td>', 1)),
    ("a constant's declared home no longer contains it", "actually stated in its declared home",
     lambda s: s.replace("A crew of 3 to 5: 3 characters", "3 characters", 1)),
]

fails = []
for name, expect, fn in MUTATIONS:
    mutated = fn(SRC)
    if mutated == SRC:
        print(f"SKIP  {name}  -- mutation did not apply (anchor text moved)")
        fails.append(name + " [anchor moved]")
        continue
    with tempfile.NamedTemporaryFile("w", suffix=".html", delete=False, encoding="utf-8") as f:
        f.write(mutated)
        path = f.name
    out = subprocess.run([sys.executable, "tools/check.py", path], capture_output=True, text=True).stdout
    os.unlink(path)
    caught = any(line.startswith("FAIL") and expect in line for line in out.splitlines())
    print(("CAUGHT   " if caught else "SURVIVED ") + name)
    if not caught:
        fails.append(name)

print()
if fails:
    print(f"{len(fails)} mutation(s) survived -- those checks are decorative:")
    for f in fails:
        print("   -", f)
    sys.exit(1)
print(f"All {len(MUTATIONS)} mutations caught. The gate has teeth.")
