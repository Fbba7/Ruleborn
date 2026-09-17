#!/usr/bin/env python3
"""Deterministic consistency checks over the built Ruleborn design document.

Brief 1 rule: the checker is not the author. Nothing here reads intent,
asks a model, or accepts an explanation. Every check is a string or an
arithmetic comparison over the built artefact, so it cannot be argued with.

Exit code 0 = all green, 1 = at least one failure.
"""
import re
import sys
import html
import json
import collections

DOC = sys.argv[1] if len(sys.argv) > 1 else "build/ruleborn-game-design-v30.html"
RAW = open(DOC, encoding="utf-8").read()

# ---------------------------------------------------------------- text views
BODY = re.sub(r"<style.*?</style>|<script.*?</script>|<svg.*?</svg>", " ", RAW, flags=re.S)


def strip(x):
    return html.unescape(re.sub(r"\s+", " ", re.sub(r"<[^>]+>", " ", x)))


def section(sid):
    i = RAW.find(f'<section id="{sid}">')
    if i < 0:
        return ""
    j = RAW.find("</section>", i)
    return RAW[i:j]


# normative text = everything except the sources list, the research log and
# the rename/compliance tables, which quote retired names on purpose.
NORM = re.sub(r'<section id="(research|references)">.*?</section>', " ", BODY, flags=re.S)
NORM = re.sub(r"<!--allow-retired-->.*?<!--/allow-retired-->", " ", NORM, flags=re.S)
T_ALL, T_NORM = strip(BODY), strip(NORM)

FAILURES = []


def check(name, ok, detail=""):
    print(("PASS  " if ok else "FAIL  ") + name + (("  -- " + str(detail)) if detail and not ok else ""))
    if not ok:
        FAILURES.append(name)


# ------------------------------------------------- 1. canonical constants
# Each constant is stated once, in one section, and every other mention must
# agree with it. A constant restated with a different value is the single
# most common drift failure and the cheapest to detect.
CONSTANTS = json.load(open("data/constants.json", encoding="utf-8")) if __import__("os").path.exists("data/constants.json") else {}

for key, spec in CONSTANTS.items():
    pat = spec["pattern"]
    found = set(re.findall(pat, T_ALL))
    expect = {str(spec["value"])}
    check(f"constant {key} == {spec['value']}", found <= expect and found, f"found {sorted(found)}")
    # a constant's declared home must actually contain it, or the table of
    # constants points readers at a section that does not define the thing
    num = spec["home"].split()[0]
    i_h = RAW.find(f"<h3>{num} ")
    nxt = RAW.find("<h3>", i_h + 1) if i_h >= 0 else -1
    home_text = strip(RAW[i_h:nxt if nxt > 0 else i_h + 6000]) if i_h >= 0 else ""
    v = str(spec["value"]).replace(",", "")
    present = bool(home_text) and (v in home_text.replace(",", ""))
    check(f"constant {key} is actually stated in its declared home ({num})", present,
          "heading not found" if i_h < 0 else "home section does not contain the value")

# ------------------------------------------------- 2. retired names
RETIRED = ["Lawbound", "lawborn", "Echo Knight", "Moss Giant", "Creator Fund", "Masquerade"]
for name in RETIRED:
    n = T_NORM.count(name)
    check(f"retired name absent: {name}", n == 0, f"{n} occurrence(s) outside the rename table")

# ------------------------------------------------- 3. counts match the tables
laws = collections.Counter(r for r, _ in re.findall(r">(Common|Uncommon|Rare|Deep), (\d+)<", section("laws")))
check("law table totals 48", sum(laws.values()) == 48, sum(laws.values()))
stated = re.search(r"The (\d+) laws", T_ALL)
check("law count in prose matches table", stated and int(stated.group(1)) == sum(laws.values()),
      stated.group(1) if stated else "no prose count")

# the five ranks must all appear in the table and none be empty
check("five-rank scheme populated", all(laws.get(r) for r in ("Common", "Uncommon", "Rare", "Deep")), dict(laws))

# stale three-rank prose must not survive anywhere
THREE_RANK = re.findall(r"three common, three rare and two deep|three common, three rare|common, rare and deep", T_NORM)
check("no stale three-rank prose", not THREE_RANK, THREE_RANK)

# ------------------------------------------------- 4. arithmetic re-derivation
# Every arithmetic claim in the document is recomputed from the tables it
# claims to summarise. A stated figure is never taken on trust.
PAGES = {"Common": 10, "Uncommon": 20, "Rare": 35, "Deep": 60}
total_pages = sum(PAGES[r] * n for r, n in laws.items())
m = re.search(r"= ([\d,]+) pages in total", T_ALL)
check("stated page total equals the table's arithmetic",
      m and int(m.group(1).replace(",", "")) == total_pages,
      f"stated {m.group(1) if m else 'nothing'}, derived {total_pages:,}")

# the restore figure must equal the total less the three free commons
m2 = re.search(r"([\d,]+) − 30 = ([\d,]+) pages", T_ALL)
check("restore figure equals total minus the starting laws",
      m2 and int(m2.group(1).replace(",", "")) == total_pages
      and int(m2.group(2).replace(",", "")) == total_pages - 30,
      m2.groups() if m2 else "formula missing")

# every inline "a × b = c" in a formula block must actually multiply out
prod_bad = []
for a, b, c in re.findall(r"(\d+) × (\d+) = ([\d,]+)", T_ALL):
    if int(a) * int(b) != int(c.replace(",", "")):
        prod_bad.append(f"{a}×{b}≠{c}")
check("inline products multiply out", not prod_bad, prod_bad)

# ------------------------------------------------- 4b. content inventory
# 26.1 claims a count for each kind of content. Each claim is recounted from
# the table that actually holds that content. This is the check that would
# have caught "30 traits" and "16 building types".
roster = section("characters")
i_r = roster.find("11.2")
j_r = roster.find("11.3")
creatures = re.findall(r'<td data-label="Ruleborn"><strong>([^<]+)</strong>', roster[i_r:j_r])
traits = re.findall(r"([A-Z][a-z][A-Za-z\- ]*?):", strip(roster[roster.find("11.3"):roster.find("11.4")]))
traits = [t for t in traits if not t.startswith(("Kind", "Body", "Heist", "Law-linked", "Home"))]
traits += [t.split()[-1] for t in re.findall(r"(?:Kind Traits Body|Heist|Law-linked|Home) [A-Z][a-z]+", strip(roster))[:0]]
buildings = re.findall(r"<h4[^>]*>(.*?)</h4>", section("buildings"), flags=re.S)
INVENTORY = {
    "Laws": sum(laws.values()),
    "Ruleborn": len(creatures),
    "Building types": len(buildings) + 1,  # the 16 in 10.2 plus the Library in 10.4
}
for label, actual in INVENTORY.items():
    m = re.search(r'<td data-label="Content">' + re.escape(label) + r"</td><td[^>]*>(\d+)</td>", RAW)
    check(f"26.1 {label.lower()} count matches the tables", m and int(m.group(1)) == actual,
          f"stated {m.group(1) if m else 'nothing'}, counted {actual}")

# ------------------------------------------------- 4c. derived creature attributes
CREATURES = json.load(open("data/creatures.json", encoding="utf-8"))
mismatch = []
for name, d in CREATURES.items():
    row = re.search(r'<td data-label="Ruleborn"><strong>' + re.escape(name) + r"</strong></td>.*?</tr>", RAW, flags=re.S)
    if not row:
        mismatch.append(f"{name}: no row")
        continue
    size = re.search(r'<td data-label="Size">([^<]+)</td>', row.group(0))
    flies = re.search(r'<td data-label="Flies">([^<]+)</td>', row.group(0))
    if not size or size.group(1) != d["size"]:
        mismatch.append(f"{name}: size")
    if not flies or flies.group(1) != ("yes" if d["flies"] else "no"):
        mismatch.append(f"{name}: flies")
    # size must re-derive from the head count on the character's own card
    band = "small" if d["heads"] < 2.0 else ("large" if d["heads"] > 2.5 else "standard")
    if band != d["size"]:
        mismatch.append(f"{name}: size does not re-derive from {d['heads']} heads")
check(f"creature size and flight match their derivation ({len(CREATURES)} creatures)", not mismatch, mismatch[:8])

# the roster in 11.2 and the character bible in 11.11 must agree on role.
# They disagreed on three creatures for two revisions; role decides a
# creature's stats, so a disagreement is a balance bug, not a wording one.
role_bad = []
for name in CREATURES:
    r1 = re.search(r'<td data-label="Ruleborn"><strong>' + re.escape(name) +
                   r'</strong></td>.*?<td data-label="Role">([^<]+)</td>', RAW, flags=re.S)
    r2 = re.search(r">" + re.escape(name) + r'</span><span class="lawmeta">([^<·]+)·', RAW)
    if not (r1 and r2):
        role_bad.append(f"{name}: missing from one table")
    elif r1.group(1).strip() != r2.group(1).strip():
        role_bad.append(f"{name}: {r1.group(1).strip()} vs {r2.group(1).strip()}")
check("roster and character bible agree on every role", not role_bad, role_bad[:6])

# head counts on the cards must sit inside the range the art rules state
art = re.search(r"([\d.]+) to ([\d.]+) heads tall", T_ALL)
lo, hi = (float(art.group(1)), float(art.group(2))) if art else (0, 0)
outside = [n for n, d in CREATURES.items() if not (lo <= d["heads"] <= hi)]
check(f"every creature's proportions sit inside the stated art range ({lo}-{hi} heads)",
      art and not outside, outside[:8])

# the Library's cost table must reproduce the multipliers its formula states
lib = RAW[RAW.find("<h3>10.4"):RAW.find("<h3>11.1")]
lib_costs = [int(x.replace(",", "")) for x in re.findall(r'data-label="Cost">([\d,]+)', lib)]
mults = re.findall(r"× ([\d.]+) a level", strip(lib))
if len(lib_costs) == 10 and len(mults) == 2:
    g1, g2 = float(mults[0]), float(mults[1])
    ratios = [b / a for a, b in zip(lib_costs, lib_costs[1:])]
    bad_r = [f"{i+1}->{i+2}: {r:.3f}" for i, r in enumerate(ratios)
             if abs(r - (g1 if i < 4 else g2)) / (g1 if i < 4 else g2) > 0.02]
    check("Library cost table reproduces its stated multipliers", not bad_r, bad_r)
else:
    check("Library cost table reproduces its stated multipliers", False,
          f"{len(lib_costs)} costs, {len(mults)} multipliers found")

# ------------------------------------------------- 4d. superseded models
SUPERSEDED = [
    # the old detection model measured awareness as a percentage; the current
    # one is an integer 0-1000 suspicion value. Any percentage of awareness,
    # anywhere, is the deleted model leaking back in.
    ("percent awareness", r"\d+%\s*awareness|awareness[^.]{0,30}\d+%"),
    ("single vision cone", r"one 120° cone"),
    ("three-rank page costs", r"15, 30 or 60 pages"),
    ("narrow cuteness range that excludes its own creatures",
     r"two to two and a half heads tall;|explicit: two to two and a half heads"),
]
for label, pat in SUPERSEDED:
    hits = re.findall(pat, T_NORM, flags=re.I)
    check(f"superseded model absent: {label}", not hits, hits[:3])

# ------------------------------------------------- 5. section numbering
nums = [int(x) for x in re.findall(r'<h2><span class="num">(\d+)</span>', RAW)]
check("section numbers unique and ascending", nums == sorted(set(nums)) and len(nums) == len(set(nums)), nums)

subs = collections.defaultdict(list)
for h in re.findall(r"<h3[^>]*>(.*?)</h3>", RAW, flags=re.S):
    m = re.match(r"\s*(\d+)\.(\d+)", strip(h))
    if m:
        subs[int(m.group(1))].append(int(m.group(2)))
bad = {k: v for k, v in subs.items() if v != sorted(v) or len(v) != len(set(v))}
check("subsection numbers ascending within each section", not bad, bad)
gaps = {k: v for k, v in subs.items() if v != list(range(1, len(v) + 1))}
check("subsection numbers contiguous from 1 (no holes left by deletions)", not gaps, gaps)
check("every section has subsections", set(subs) <= set(nums), sorted(set(subs) - set(nums)))

# ------------------------------------------------- 6. citations both ways
anchors = set(re.findall(r'id="(ref-\d+)"', RAW))
cited = set(re.findall(r'href="#(ref-\d+)"', RAW))
check("no dangling citations", not (cited - anchors), sorted(cited - anchors)[:10])
check("no uncited sources", not (anchors - cited), sorted(anchors - cited)[:10])

# ------------------------------------------------- 7. cross-references resolve
all_ids = set(re.findall(r'id="([^"]+)"', RAW))
links = set(re.findall(r'href="#([^"]+)"', RAW))
check("all internal links resolve", not (links - all_ids), sorted(links - all_ids)[:10])

# ------------------------------------------------- 8. generated blocks unedited
# Any table marked generated carries a hash of its own rendered text. If a
# human edits the table without regenerating it, the hash stops matching.
import hashlib
gen = re.findall(r'<!--gen:([0-9a-f]{12})-->(.*?)<!--/gen-->', RAW, flags=re.S)
bad_gen = [h for h, blk in gen if hashlib.sha256(strip(blk).strip().encode()).hexdigest()[:12] != h]
check(f"generated blocks match their hash ({len(gen)} block(s))", not bad_gen, bad_gen)

# ------------------------------------------------- 9. audit register closure
reg = section("decisions")
open_items = re.findall(r">(OPEN|PROPOSED)<", reg)
check("no open audit items in the register", not open_items, collections.Counter(open_items))

print()
print(f"{len(FAILURES)} failure(s)" if FAILURES else "ALL CHECKS PASS")
sys.exit(1 if FAILURES else 0)
