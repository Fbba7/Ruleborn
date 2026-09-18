#!/usr/bin/env python3
"""Every check over the design document, in one place, with one verdict.

Usage:
    python3 tools/check_document.py [path to the built HTML]
    python3 tools/check_document.py --self-test

Until now this repository ran two checkers over one document, which is the
fault the audit register exists to record, applied to the tools (T1.11).

  * ``tools/vendor/check.py`` shipped with v3.1. It reads the **HTML** and
    checks structure: canonical constants, section numbering, citations both
    ways, generated-block hashes, content inventory recounted from the tables.
    It exits non-zero on any failure, because it is a build gate.

  * ``tools/check_design_consistency.py`` is this repository's. It reads the
    **text** and checks design claims: the note economy, chord reachability,
    what a raid pays, the Vault phase, supersession. It always exits zero,
    because most of what it reports is an open register item rather than a
    build break.

Merging them needs three things, and only the third is interesting.

**One artefact.** The two read different files. Two checkers pointed at two
paths can silently check two different versions of the document; this one takes
the HTML and derives the text from it with ``extract_design_doc``, so the two
views cannot disagree about what they are reading.

**One verdict.** Their exit conventions are incompatible on purpose, so the
merge needs a third state. Every check here declares whether it is *structural*
— it must pass, and a failure breaks the build — or *tracked*, meaning it is
expected to fail while a named register item is open. That makes four outcomes
rather than two, and two of them are news:

    PASS      structural, passing
    OPEN      tracked, failing, and its register item is open — expected
    RETIRED   tracked, now passing: the document was fixed, so close the item
    BREAK     structural failure, or a tracked check failing while the register
              says its item is closed — the register is lying about the document

**Checks that derive rather than recognise.** This is the part worth the work,
and F24 is why. v3.1's checker bans the phrase ``15, 30 or 60 pages`` to enforce
the four-rank page costs, and reports green on v3.1 — while 7.6 still says
*"15 pages for a common law, 30 for a rare one, 60 for a deep one"*, which is
the same model in different words. **A banned phrase can prove a phrasing
absent; it can never prove a model absent, and it reports the stronger claim.**

So the page costs are checked by derivation instead: read the rank table, read
all 48 law sheets, then find every place in the document that associates a rank
with a page count *in any of its three grammatical forms* and check each one
against the table. ``--self-test`` proves the difference by planting 7.6's
sentence in a clean document and showing the phrase ban miss it.
"""

from __future__ import annotations

import collections
import contextlib
import hashlib
import html
import io
import json
import os
import re
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

import check_design_consistency as design          # noqa: E402
from extract_design_doc import extract             # noqa: E402

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
DEFAULT_DOC = os.path.join(ROOT, "docs", "design", "ruleborn-game-design-v3.1.html")
CONSTANTS = os.path.join(ROOT, "content", "upstream", "constants.json")
CREATURES = os.path.join(ROOT, "content", "upstream", "creatures.json")

# --------------------------------------------------------------------------
# What each tracked check is waiting on
# --------------------------------------------------------------------------
#
# A tracked check is one the document is expected to fail while a register item
# is open. The item id is the whole point: it means a failure here is already
# written down somewhere a person reads, and it means a tracked check that
# starts passing can be reported as a retirement rather than ignored.
#
# Keys are check labels from check_design_consistency.run().
TRACKED = {
    "the authored law sheets match 7.9's own rank table": "C3",
    "7.6's restore costs match 7.9's pages column": "C23",
    "the law rarity split is stated once (7.7)": "C23",
    "opposite note pairs are within 2 laws of each other": "D13",
    "8.8's claim that the note table 'now runs eight or nine laws per note' holds": "C25",
    "heists supply 'roughly a third' of resources (9.4) / '40% of mid-game growth' (12.1)": "C2",
    "the document states one loading rate": "C22",
    "the Vault loading rate is stated once (12.19)": "C22",
    "'who cracks' is a decision (12.6) rather than always the Breaker": "F6",
    "every ward's '+15% effect' names one quantity (10.2, 10.3)": "G3",
    "high scenario ≈ €168,000 at the stated 15% commission (22.5)": "C12",
}

PASS, OPEN, RETIRED, BREAK = "PASS", "OPEN", "RETIRED", "BREAK"

# --------------------------------------------------------------------------
# What each of v3.1's own checks became here
# --------------------------------------------------------------------------
#
# "Keep every check from both" is easy to claim and easy to get wrong, so the
# claim is machine-checked. Each key is a check v3.1's tools/vendor/check.py
# performs; each value is a substring of the merged check that subsumes it.
# ``--coverage`` runs both sides and fails if any of these no longer matches a
# check this file actually ran.
#
# Three entries point at a *stronger* check rather than a copy, and those are
# the merge's whole justification: v3.1 guards its page costs with a banned
# phrase, and a banned phrase cannot see 7.6 (F24).
COVERS = {
    "constant <name> == <value>":        "everywhere it appears",
    "constant stated in declared home":  "is stated in its declared home",
    "retired name absent":               "retired name absent:",
    "law table totals 48":               "48 laws specified in 7.7",
    "law count in prose matches table":  "the law count in the prose matches the authored sheets",
    "five-rank scheme populated":        "every rank in the scheme has laws in it",
    "no stale three-rank prose":         "superseded phrasing absent: three-rank prose",
    "stated page total":                 "the stated Codex total equals the sheets' own arithmetic",
    "restore figure":                    "the restore figure equals the Codex total less the starting laws",
    "inline products multiply out":      "every inline product multiplies out",
    "26.1 content counts":               "count matches the tables it summarises",
    "creature size and flight":          "size and flight re-derive",
    "roster and bible agree on role":    "11.2 and 11.11 agree on every ruleborn",
    "proportions inside the art range":  "sit inside the stated art range",
    "Library cost multipliers":          "the Library cost table reproduces its stated multipliers",
    "superseded: percent awareness":     "superseded phrasing absent: percent awareness",
    "superseded: single vision cone":    "superseded phrasing absent: single vision cone",
    "superseded: three-rank page costs": "superseded phrasing absent: three-rank page costs, verbatim",
    "superseded: cuteness range":        "superseded phrasing absent: cuteness range",
    "section numbers unique":            "section numbers unique and ascending",
    "subsections ascending":             "subsection numbers ascending within each section",
    "subsections contiguous":            "subsection numbers contiguous from 1",
    "every section has subsections":     "every section has subsections",
    "no dangling citations":             "no dangling citations",
    "no uncited sources":                "no uncited sources",
    "internal links resolve":            "all internal links resolve",
    "generated blocks hashed":           "generated blocks match their hash",
    "register closed":                   "31.9 lists no open items",
}

#: Checks here that v3.1's has no counterpart for. Each is either a design claim
#: (the whole of check_design_consistency) or one of the three added by the
#: merge itself.
ADDED_BY_THE_MERGE = (
    "every page cost in the document agrees with the rank table",   # F24, derived not recognised
    "the rank table's counts match the 48 authored law sheets",     # C3, from the sheets
    "every section citation in the prose resolves",                 # v3.1's renumbering, verified
    "a producer's partial output is stated once (5.8)",             # C27, two staffing rules
    "a birth is priced once (9.5)",                                 # C28, two birth curves
    "9.5's birth examples match 9.5's own birth formula",           # C28, and one cell
)


class Ledger:
    """The four-state verdict, and the one thing every check reports into."""

    def __init__(self, quiet: bool = False) -> None:
        self.rows: list[tuple[str, str, str, str | None]] = []
        self.quiet = quiet

    def check(self, label: str, ok: bool, detail: str = "", tracks: str | None = None) -> None:
        """Record one result, in the four states the merge needs.

        The register is consulted, not assumed, so the two can disagree and the
        disagreement is itself a failure. A tracked check that passes while its
        item is still open is a retirement; one that fails while its item is
        closed means the register claims a fix the document does not carry,
        which is the exact fault C21-C24 were — and it now breaks the build.
        """
        still_open = _is_open(tracks) if tracks else False
        if ok:
            state = RETIRED if (tracks and still_open) else PASS
        else:
            state = OPEN if (tracks and still_open) else BREAK
        self.rows.append((state, label, detail, tracks))

    def of(self, state: str) -> list:
        return [r for r in self.rows if r[0] == state]

    def report(self) -> int:
        if not self.quiet:
            for state in (BREAK, RETIRED, OPEN, PASS):
                rows = self.of(state)
                if not rows:
                    continue
                print(f"\n{_HEADINGS[state]}  ({len(rows)})")
                for _, label, detail, tracks in rows:
                    tag = f"[{tracks}] " if tracks else ""
                    line = f"  {tag}{label}"
                    if detail and state in (BREAK, OPEN):
                        line += f"\n      {detail}"
                    print(line)
            print()
            print(f"{len(self.of(PASS))} passing, "
                  f"{len(self.of(OPEN))} open and tracked, "
                  f"{len(self.of(RETIRED))} newly retired, "
                  f"{len(self.of(BREAK))} broken.")
        return 1 if self.of(BREAK) else 0


_HEADINGS = {
    BREAK: "BROKEN — the document contradicts itself, or the register is stale",
    RETIRED: "RETIRED — fixed in the document; close the register item",
    OPEN: "OPEN — failing, and tracked in the register",
    PASS: "PASS",
}


def _is_open(item_id: str) -> bool:
    """Is this register item still open, according to the register itself?"""
    from audit_register import REGISTER, is_open
    if any(isinstance(i, dict) and i.get("id") == item_id for i in REGISTER):
        return is_open(item_id)
    return True


# --------------------------------------------------------------------------
# Views of the document
# --------------------------------------------------------------------------

def strip(x: str) -> str:
    return html.unescape(re.sub(r"\s+", " ", re.sub(r"<[^>]+>", " ", x)))


class Doc:
    """One artefact, two views, so the halves cannot read different versions."""

    def __init__(self, path: str, raw: str | None = None) -> None:
        self.path = path
        self.raw = raw if raw is not None else open(path, encoding="utf-8").read()
        body = re.sub(r"<style.*?</style>|<script.*?</script>|<svg.*?</svg>",
                      " ", self.raw, flags=re.S)
        # Normative text excludes the sources list, the research log and the
        # rename tables, which quote retired names deliberately.
        norm = re.sub(r'<section id="(research|references)">.*?</section>', " ", body, flags=re.S)
        norm = re.sub(r"<!--allow-retired-->.*?<!--/allow-retired-->", " ", norm, flags=re.S)
        self.all_text = strip(body)
        self.norm_text = strip(norm)
        self.text = extract(self.raw)          # the .txt view, derived here

    def section(self, sid: str) -> str:
        i = self.raw.find(f'<section id="{sid}">')
        if i < 0:
            return ""
        return self.raw[i:self.raw.find("</section>", i)]


# --------------------------------------------------------------------------
# The page economy, derived rather than recognised  (F24)
# --------------------------------------------------------------------------

RANK_WORDS = ("common", "uncommon", "rare", "deep", "paradox")


def rank_prices(doc: Doc) -> dict[str, int]:
    """Rank -> pages to restore, read out of the rank table itself."""
    prices: dict[str, int] = {}
    lines = [ln.strip() for ln in doc.text.split("\n")]
    for i, line in enumerate(lines):
        if line[2:].strip().lower() in RANK_WORDS and line.startswith("|"):
            cells = []
            for nxt in lines[i + 1:i + 5]:
                if not nxt.startswith("|"):
                    break
                cells.append(nxt[1:].strip())
            if len(cells) == 3 and cells[0].isdigit() and cells[2].isdigit():
                prices[line[2:].strip().capitalize()] = int(cells[2])
    return prices


def authored_ranks(doc: Doc) -> dict[str, int]:
    """Rank -> how many of the 48 law sheets actually carry it."""
    return collections.Counter(
        m.group(1) for m in re.finditer(
            r"(Common|Uncommon|Rare|Deep) · (?:Motion|Matter|Time|Energy|Life|Spirit) · cost \d+",
            doc.text))


def page_cost_claims(text: str) -> list[tuple[str, str, int, str]]:
    """Every place the document associates a rank with a page count.

    Returns (form, rank, pages, excerpt). Three grammatical forms carry this
    fact, and a phrase ban only ever covers the one it was written against:

      enumerated   "10, 20, 35 or 60 pages by rank"
      prose        "15 pages for a common law, 30 for a rare one, 60 for a deep one"
      arithmetic   "18 common × 10 + 12 uncommon × 20 + ..."

    The prose form is the one 7.6 uses and the one v3.1's phrase ban misses.
    """
    claims: list[tuple[str, str, int, str]] = []

    # arithmetic: "<count> <rank> × <pages>"
    for m in re.finditer(r"(\d+)\s+(common|uncommon|rare|deep)s?\s*×\s*(\d+)", text, re.I):
        claims.append(("arithmetic", m.group(2).capitalize(), int(m.group(3)), m.group(0)))

    # prose: inside any sentence that mentions pages, bind each rank word to
    # the nearest preceding number. This is what catches 7.6.
    for sentence in re.split(r"(?<=[.;])\s+", text):
        if "page" not in sentence.lower():
            continue
        if re.search(r"×", sentence):          # already counted as arithmetic
            continue
        tokens = [(m.start(), m.group(0)) for m in
                  re.finditer(r"\d[\d,]*|common|uncommon|rare|deep|paradox", sentence, re.I)]
        pending: int | None = None
        for _, tok in tokens:
            if tok[0].isdigit():
                pending = int(tok.replace(",", ""))
            elif pending is not None:
                claims.append(("prose", tok.capitalize(), pending, sentence.strip()[:110]))
                pending = None

    # enumerated: "a, b, c or d pages by rank"
    for m in re.finditer(r"((?:\d+,\s*)+\d+\s+or\s+\d+)\s+pages by rank", text, re.I):
        for n in re.findall(r"\d+", m.group(1)):
            claims.append(("enumerated", "*", int(n), m.group(0)))

    return claims


def check_page_economy(doc: Doc, led: Ledger) -> None:
    """C23, F24. Every page price in the document, against the rank table.

    C23 is the finding: one sentence still prices laws in three ranks. F24 is
    why it took a derived check to see it — v3.1 bans the retired model by
    searching for the string `15, 30 or 60 pages`, and §7.6 says the same thing
    with the clause rearranged, so the ban reports it absent. This reads the
    rank table and the 48 sheets and recomputes every price claim in each of
    the three grammatical forms that carry one.
    """
    prices = rank_prices(doc)
    sheets = authored_ranks(doc)

    led.check("the rank table states a page cost for every rank",
              set(prices) >= {"Common", "Uncommon", "Rare", "Deep"}, str(prices))
    if not prices:
        return

    legal = set(prices.values())
    wrong_rank, wrong_enum = [], []
    for form, rank, pages, excerpt in page_cost_claims(doc.norm_text):
        if rank == "*":
            if pages not in legal:
                wrong_enum.append(f"{pages} in {excerpt!r}")
        elif rank in prices and form == "arithmetic" and pages != prices[rank]:
            wrong_rank.append(f"{form}: {rank} at {pages}, table says {prices[rank]} — {excerpt!r}")
        elif rank in prices and form == "prose" and pages != prices[rank] and pages in (15, 30, 60):
            # 15/30/60 is the retired three-rank scale specifically. Restricting
            # the prose form to it keeps this from firing on every sentence that
            # happens to put a number near a rank word, while still catching the
            # model v3.1 believes it has deleted.
            wrong_rank.append(f"{form}: {rank} at {pages}, table says {prices[rank]} — {excerpt!r}")

    led.check(
        "every page cost in the document agrees with the rank table",
        not (wrong_rank or wrong_enum),
        "; ".join(wrong_rank + wrong_enum)[:400],
        tracks="C23")

    # the authored sheets and the table must agree on how many laws carry a rank
    disagree = {r: (sheets.get(r, 0), c) for r, c in
                [(r, int(n)) for r, n in _table_counts(doc).items()]
                if sheets.get(r, 0) != c}
    led.check("the rank table's counts match the 48 authored law sheets",
              not disagree,
              "; ".join(f"{r}: sheets {a}, table {b}" for r, (a, b) in disagree.items()),
              tracks="C3")


def _table_counts(doc: Doc) -> dict[str, str]:
    counts: dict[str, str] = {}
    lines = [ln.strip() for ln in doc.text.split("\n")]
    for i, line in enumerate(lines):
        if line.startswith("|") and line[2:].strip().lower() in ("common", "uncommon", "rare", "deep"):
            nxt = lines[i + 1] if i + 1 < len(lines) else ""
            if nxt.startswith("|") and nxt[1:].strip().isdigit():
                counts[line[2:].strip().capitalize()] = nxt[1:].strip()
    return counts


# --------------------------------------------------------------------------
# Structural checks — the half v3.1 shipped, reimplemented on our side
# --------------------------------------------------------------------------

def check_constants(doc: Doc, led: Ledger) -> None:
    if not os.path.exists(CONSTANTS):
        return
    for key, spec in json.load(open(CONSTANTS, encoding="utf-8")).items():
        found = set(re.findall(spec["pattern"], doc.all_text))
        led.check(f"constant {key} == {spec['value']}, everywhere it appears",
                  bool(found) and found <= {str(spec["value"])}, f"found {sorted(found)}")
        num = spec["home"].split()[0]
        i = doc.raw.find(f"<h3>{num} ")
        nxt = doc.raw.find("<h3>", i + 1) if i >= 0 else -1
        home = strip(doc.raw[i:nxt if nxt > 0 else i + 6000]) if i >= 0 else ""
        led.check(f"constant {key} is stated in its declared home ({num})",
                  bool(home) and str(spec["value"]).replace(",", "") in home.replace(",", ""),
                  "heading not found" if i < 0 else "the home section does not contain the value")


def check_retired_names(doc: Doc, led: Ledger) -> None:
    for name in ("Lawbound", "lawborn", "Echo Knight", "Moss Giant", "Creator Fund", "Masquerade"):
        n = doc.norm_text.count(name)
        led.check(f"retired name absent: {name}", n == 0, f"{n} outside the rename table")


def check_arithmetic(doc: Doc, led: Ledger) -> None:
    bad = [f"{a}×{b}≠{c}" for a, b, c in re.findall(r"(\d+) × (\d+) = ([\d,]+)", doc.all_text)
           if int(a) * int(b) != int(c.replace(",", ""))]
    led.check("every inline product multiplies out", not bad, str(bad[:5]))

    prices = rank_prices(doc)
    sheets = authored_ranks(doc)
    if prices and sheets:
        derived = sum(prices[r] * n for r, n in sheets.items() if r in prices)
        m = re.search(r"= ([\d,]+) pages in total", doc.all_text)
        led.check("the stated Codex total equals the sheets' own arithmetic",
                  bool(m) and int(m.group(1).replace(",", "")) == derived,
                  f"stated {m.group(1) if m else 'nothing'}, derived {derived:,}")

        # 14.4 states the restore figure as the total less the three free
        # commons. Both halves of that subtraction have to hold.
        m2 = re.search(r"([\d,]+) − 30 = ([\d,]+) pages", doc.all_text)
        led.check("the restore figure equals the Codex total less the starting laws",
                  bool(m2)
                  and int(m2.group(1).replace(",", "")) == derived
                  and int(m2.group(2).replace(",", "")) == derived - 30,
                  str(m2.groups()) if m2 else "the formula is missing")

    led.check("every rank in the scheme has laws in it",
              all(sheets.get(r) for r in ("Common", "Uncommon", "Rare", "Deep")), str(dict(sheets)))

    prose = re.search(r"The (\d+) laws", doc.all_text)
    led.check("the law count in the prose matches the authored sheets",
              bool(prose) and int(prose.group(1)) == sum(sheets.values()),
              f"prose says {prose.group(1) if prose else 'nothing'}, "
              f"sheets give {sum(sheets.values())}")


def check_inventory(doc: Doc, led: Ledger) -> None:
    roster = doc.section("characters")
    creatures = re.findall(r'<td data-label="Ruleborn"><strong>([^<]+)</strong>',
                           roster[roster.find("11.2"):roster.find("11.3")])
    inventory = {
        "Laws": sum(authored_ranks(doc).values()),
        "Ruleborn": len(creatures),
        "Building types": building_types(doc),
    }
    for label, actual in inventory.items():
        m = re.search(r'<td data-label="Content">' + re.escape(label) + r"</td><td[^>]*>(\d+)</td>",
                      doc.raw)
        led.check(f"26.1's {label.lower()} count matches the tables it summarises",
                  bool(m) and int(m.group(1)) == actual,
                  f"stated {m.group(1) if m else 'nothing'}, counted {actual}")


def building_types(doc: Doc) -> int:
    """How many building types the document specifies.

    10.2 is headed "Every level of every building" and contains sixteen; the
    Library is specified in 10.4 instead, which is C8. An earlier version wrote
    `len(buildings) + 1` for that, and the +1 is an assumption rather than a
    count: the moment C8 is fixed by folding 10.4 into 10.2 this would read
    eighteen, 26.1 would look wrong, and the fix would look like the fault.
    Counting the names makes it true either way.
    """
    names = {b.strip() for b in
             re.findall(r"<h4[^>]*>(.*?)</h4>", doc.section("buildings"), flags=re.S)}
    if "The Library" in doc.raw:
        names.add("The Library")
    return len(names)


def check_asset_budget(doc: Doc, led: Ledger) -> None:
    """C8. 21.9's launch asset budget against the counts it is a budget for.

    The art schedule is sized from the content list, so every row in 21.9 is a
    second home for a number specified somewhere else. 26.1 moved to seventeen
    building types in v3.1 and 21.9 still prices sixteen, so the schedule is
    four building looks short - which C8 records and no check could see,
    because "16 types x 4 = 64" is correct arithmetic about the wrong sixteen
    and the check that multiplies out every inline product passes it happily.

    That is F24's rule for the third time: a check that recognises a product
    can never question either factor. These rows are derived from the same
    inventory 26.1 is checked against, so the budget cannot drift from the
    content again.
    """
    roster = doc.section("characters")
    creatures = re.findall(r'<td data-label="Ruleborn"><strong>([^<]+)</strong>',
                           roster[roster.find("11.2"):roster.find("11.3")])
    #: what 21.9 budgets for -> (how to read its number, the count it must
    #: match, where that count is specified, the item that owns the
    #: disagreement where the register already records one)
    rows = [
        ("building looks", r"Building looks \((\d+) types",
         building_types(doc), "10.2 and 10.4, which 26.1 counts", "C8"),
        ("law signatures", r"Law signatures and paradoxes</td><td[^>]*>(\d+)",
         sum(authored_ranks(doc).values()), "7.7's sheets", None),
        ("ruleborn", r"Characters: ruleborn[^<]*</td><td[^>]*>(\d+)",
         len(creatures), "11.2's roster", None),
    ]
    for label, pattern, expected, home, tracks in rows:
        m = re.search(pattern, doc.raw)
        led.check(f"21.9's launch budget for {label} matches {home}",
                  bool(m) and int(m.group(1)) == expected,
                  f"21.9 budgets for {m.group(1) if m else 'nothing'} "
                  f"{label}; {home} gives {expected}", tracks=tracks)


def check_creatures(doc: Doc, led: Ledger) -> None:
    if not os.path.exists(CREATURES):
        return
    creatures = json.load(open(CREATURES, encoding="utf-8"))
    bad = []
    for name, d in creatures.items():
        row = re.search(r'<td data-label="Ruleborn"><strong>' + re.escape(name) + r"</strong></td>.*?</tr>",
                        doc.raw, flags=re.S)
        if not row:
            bad.append(f"{name}: no row")
            continue
        size = re.search(r'<td data-label="Size">([^<]+)</td>', row.group(0))
        flies = re.search(r'<td data-label="Flies">([^<]+)</td>', row.group(0))
        if not size or size.group(1) != d["size"]:
            bad.append(f"{name}: size")
        if not flies or flies.group(1) != ("yes" if d["flies"] else "no"):
            bad.append(f"{name}: flies")
        band = "small" if d["heads"] < 2.0 else ("large" if d["heads"] > 2.5 else "standard")
        if band != d["size"]:
            bad.append(f"{name}: size does not re-derive from {d['heads']} heads")
    led.check(f"every creature's size and flight re-derive ({len(creatures)} creatures)",
              not bad, str(bad[:6]))

    art = re.search(r"([\d.]+) to ([\d.]+) heads tall", doc.all_text)
    lo, hi = (float(art.group(1)), float(art.group(2))) if art else (0.0, 0.0)
    outside = [n for n, d in creatures.items() if not (lo <= d["heads"] <= hi)]
    led.check(f"every creature's proportions sit inside the stated art range ({lo}–{hi} heads)",
              bool(art) and not outside, str(outside[:6]))


#: §12.17's vision table: role, cone, three zones, corner of the eye, turn rate.
VISION_ROW = 7


def vision_table(doc: Doc) -> dict:
    """§12.17's own table, read out of the document.

    The table is the evidence that the model is three zones inside a cone
    rather than one cone. Reading it is what lets `check_detection_model`
    assert the model instead of asserting that a sentence is absent.
    """
    seg = doc.raw[doc.raw.index("12.17 How guards perceive"):]
    seg = seg[:seg.index("12.18")]
    out = {}
    for row in re.findall(r"<tr>(.*?)</tr>", seg, flags=re.S):
        # `strip` here removes markup, not whitespace. An earlier version
        # keyed the table on "Scout " and then reported every role missing
        # from a table it had just read.
        cells = [strip(c).strip()
                 for c in re.findall(r"<td[^>]*>(.*?)</td>", row, flags=re.S)]
        if len(cells) == VISION_ROW and cells[1].endswith("\u00b0"):
            out[cells[0]] = cells[1:]
    return out


def states_table(doc: Doc) -> dict:
    """§12.17's guard states and the suspicion each is reached at."""
    seg = doc.raw[doc.raw.index("Being noticed takes time"):]
    seg = seg[:seg.index("Noise travels")]
    out = {}
    for row in re.findall(r"<tr>(.*?)</tr>", seg, flags=re.S):
        cells = [strip(c).strip()
                 for c in re.findall(r"<td[^>]*>(.*?)</td>", row, flags=re.S)]
        if len(cells) != 3:
            continue
        # "under 200" is a ceiling, not the value the state is reached at:
        # Unaware is everything below Suspicious. Reading it as 200 made the
        # content file look wrong for saying 0.
        if re.match(r"under\b", cells[1], flags=re.I):
            out[cells[0].lower()] = 0
            continue
        m = re.search(r"(\d[\d,]*)", cells[1])
        if m:
            out[cells[0].lower()] = int(m.group(1).replace(",", ""))
    return out


def _metres(cell: str) -> float | None:
    """The outer edge of a zone cell, or None where the zone does not exist."""
    if "none" in cell.lower():
        return None
    nums = re.findall(r"[\d.]+", cell)
    return float(nums[-1]) if nums else None


def check_detection_model(doc: Doc, led: Ledger) -> None:
    """C21, C1. The detection model, derived rather than recognised.

    F24's rule, applied to the second of v3.1's four supersession bans. The ban
    for the retired model is the string `one 120° cone`, and the one for
    percent awareness is a regular expression over the words. Both report a
    phrasing absent and are read as reporting a model gone, which is the
    stronger claim and not the one they make.

    What the model actually is, is in §12.17's own two tables, and both are
    readable:

      * **Not one cone.** Every guard row gives a cone, at least two graded
        zones inside it, and a corner-of-the-eye angle *wider* than the cone.
        A single-cone model cannot state a peripheral angle wider than its
        own cone, so this is a property the retired model does not have and
        cannot be given by rewording.
      * **Not percentages.** Every state the document names is reached at a
        suspicion value, and every threshold stated anywhere in the prose has
        to resolve against §12.17's table. `investigate at 50%` fails not
        because of the percent sign but because 50 is not 600.

    C21 is the item this is tracked to, and it was closed by v3.1 while the
    register kept it open and blocking for a version — the phrase ban passed
    on every build, and a passing ban cannot retire the item it is about. A
    derived check can, and this one does.
    """
    vision = vision_table(doc)
    led.check("12.17 gives every guard role a vision row", len(vision) == 5,
              f"read {sorted(vision)}")
    for role, cells in vision.items():
        cone = float(cells[0].rstrip("\u00b0"))
        zones = [_metres(c) for c in cells[1:4]]
        peripheral = float(cells[4].rstrip("\u00b0"))
        graded = [z for z in zones if z is not None]
        led.check(f"{role}'s vision is graded zones inside a cone, not one cone",
                  len(graded) >= 2 and graded == sorted(graded)
                  and peripheral > cone,
                  f"cone {cone}\u00b0, zones {zones}, peripheral {peripheral}\u00b0",
                  tracks="C1")

    states = states_table(doc)
    led.check("12.17 states a suspicion value for every guard state it names",
              set(states) >= {"suspicious", "investigating", "alerted"},
              str(states))
    # Every threshold the prose states, anywhere, against the table above.
    stated = re.findall(
        r"\b(suspicious|investigating|investigate|alerted|alarm)\s+at\s+"
        r"([\d,]+)\s*(%?)", doc.norm_text, flags=re.I)
    wrong = []
    for word, value, percent in stated:
        key = {"investigate": "investigating", "alarm": "alerted"}.get(
            word.lower(), word.lower())
        want = states.get(key)
        got = int(value.replace(",", ""))
        if percent or (want is not None and got != want):
            wrong.append(f"{word} at {value}{percent}, 12.17 says {want}")
    led.check("every guard-state threshold in the document is 12.17's own",
              not wrong, "; ".join(wrong), tracks="C21")

    # And the content table the harness reads, against the same two tables.
    path = os.path.join(ROOT, "content", "detection.json")
    if os.path.exists(path):
        with open(path, encoding="utf-8") as fh:
            data = json.load(fh)
        bad = []
        for guard in data["guards"]:
            cells = vision.get(guard["role"])
            if cells is None:
                bad.append(f"{guard['role']} is not in 12.17's table")
                continue
            want = (float(cells[0].rstrip("\u00b0")), _metres(cells[1]),
                    _metres(cells[2]), _metres(cells[3]),
                    float(cells[4].rstrip("\u00b0")),
                    float(re.findall(r"[\d.]+", cells[5])[0]))
            got = (float(guard["cone_degrees"]), guard["near_m"], guard["mid_m"],
                   guard.get("far_m"), float(guard["peripheral_degrees"]),
                   float(guard["turn_degrees_per_tick"]))
            if want != got:
                bad.append(f"{guard['role']}: 12.17 {want}, content {got}")
        for name, want in states.items():
            got = next((st["at"] for st in data["states"] if st["id"] == name), None)
            if got is not None and got != want:
                bad.append(f"{name}: 12.17 says {want}, content says {got}")
        led.check("content/detection.json reproduces 12.17's own tables",
                  not bad, "; ".join(bad))


def check_banned_phrasings(doc: Doc, led: Ledger) -> None:
    """v3.1's phrase bans, kept — but no longer the only guard on their models.

    These are cheap and they catch a verbatim reintroduction, which is a real
    way for a deleted model to come back. What they cannot do is notice the
    same model stated differently, which is why check_page_economy exists.
    """
    for label, pat in (
        ("percent awareness", r"\d+%\s*awareness|awareness[^.]{0,30}\d+%"),
        ("single vision cone", r"one 120° cone"),
        ("three-rank page costs, verbatim", r"15, 30 or 60 pages"),
        ("three-rank prose",
         r"three common, three rare and two deep|three common, three rare|"
         r"common, rare and deep"),
        ("cuteness range that excludes its own creatures",
         r"two to two and a half heads tall;|explicit: two to two and a half heads"),
    ):
        hits = re.findall(pat, doc.norm_text, flags=re.I)
        led.check(f"superseded phrasing absent: {label}", not hits, str(hits[:3]))


def check_structure(doc: Doc, led: Ledger) -> None:
    nums = [int(x) for x in re.findall(r'<h2><span class="num">(\d+)</span>', doc.raw)]
    led.check("section numbers unique and ascending",
              nums == sorted(set(nums)) and len(nums) == len(set(nums)), str(nums))

    subs: dict[int, list[int]] = collections.defaultdict(list)
    for h in re.findall(r"<h3[^>]*>(.*?)</h3>", doc.raw, flags=re.S):
        m = re.match(r"\s*(\d+)\.(\d+)", strip(h))
        if m:
            subs[int(m.group(1))].append(int(m.group(2)))
    bad = {k: v for k, v in subs.items() if v != sorted(v) or len(v) != len(set(v))}
    led.check("subsection numbers ascending within each section", not bad, str(bad))
    gaps = {k: v for k, v in subs.items() if v != list(range(1, len(v) + 1))}
    led.check("subsection numbers contiguous from 1 (no holes left by deletions)", not gaps, str(gaps))
    led.check("every section has subsections", set(subs) <= set(nums),
              str(sorted(set(subs) - set(nums))))

    anchors = set(re.findall(r'id="(ref-\d+)"', doc.raw))
    cited = set(re.findall(r'href="#(ref-\d+)"', doc.raw))
    led.check("no dangling citations", not (cited - anchors), str(sorted(cited - anchors)[:8]))
    led.check("no uncited sources", not (anchors - cited), str(sorted(anchors - cited)[:8]))

    ids = set(re.findall(r'id="([^"]+)"', doc.raw))
    links = set(re.findall(r'href="#([^"]+)"', doc.raw))
    led.check("all internal links resolve", not (links - ids), str(sorted(links - ids)[:8]))

    gen = re.findall(r"<!--gen:([0-9a-f]{12})-->(.*?)<!--/gen-->", doc.raw, flags=re.S)
    bad_gen = [h for h, blk in gen
               if hashlib.sha256(strip(blk).strip().encode()).hexdigest()[:12] != h]
    led.check(f"generated blocks match their hash ({len(gen)} block(s))", not bad_gen, str(bad_gen))


def check_library_curve(doc: Doc, led: Ledger) -> None:
    """10.4's cost table must reproduce the multipliers its own formula states.

    C24 closed on the Library gaining all ten levels rather than three. This is
    the check that keeps the ten honest: a cost curve stated as a formula and
    also written out as a table is the same fact in two places, which is the
    register's whole subject.
    """
    lib = doc.raw[doc.raw.find("<h3>10.4"):doc.raw.find("<h3>11.1")]
    costs = [int(x.replace(",", "")) for x in re.findall(r'data-label="Cost">([\d,]+)', lib)]
    mults = re.findall(r"× ([\d.]+) a level", strip(lib))
    if len(costs) == 10 and len(mults) == 2:
        g1, g2 = float(mults[0]), float(mults[1])
        bad = [f"{i + 1}->{i + 2}: {r:.3f}" for i, r in
               enumerate(b / a for a, b in zip(costs, costs[1:]))
               if abs(r - (g1 if i < 4 else g2)) / (g1 if i < 4 else g2) > 0.02]
        led.check("the Library cost table reproduces its stated multipliers", not bad, str(bad))
    else:
        led.check("the Library cost table reproduces its stated multipliers", False,
                  f"{len(costs)} costs and {len(mults)} multipliers found")


# --------------------------------------------------------------------------
# The two of F25's six twice-stated facts that nothing checked  (C27, C28)
# --------------------------------------------------------------------------

def staffing_rules(doc: Doc) -> tuple[dict[str, list[int] | None], list[str]]:
    """Every section that states how a part-staffed producer pays, and what it says.

    C27 was recorded as two homes, 9.2 against 5.8. It is three, and the third
    is the one that matters: 9.2's caption and 9.3's production formula both
    carry the stepped share, and the drafted edit deletes only the caption,
    leaving the formula — which is the half that computes anything.

    Returns (homes, cross_references). A home states the rule; a cross-
    reference restates it and cites where it lives, which is what 31.2 asks
    for and not a second home. 27.2 and 30.18 both do the second, and a check
    that could not tell them apart would report five homes and be wrong about
    three of them.

    A home maps to the percentages it states, or to None where it states a
    proportion instead. A proportion has no numbers in it, so what can be
    compared is not the two rules against each other but each stepped figure
    against the share it should have been.
    """
    homes: dict[str, list[int] | None] = {}
    m = re.search(r"Staffing sets ((?:\d+%(?:, | or )?)+) output", doc.all_text)
    if m:
        homes["9.2"] = [int(x) for x in re.findall(r"(\d+)%", m.group(1))]
    # 9.3's formula carries the same steps as a multiplier: "staffing (0.6, ...)".
    f = re.search(r"staffing \(((?:[\d.]+(?:, | or )?)+)\)", doc.all_text)
    if f:
        homes["9.3"] = [round(100 * float(x)) for x in re.findall(r"[\d.]+", f.group(1))]
    if re.search(r"runs at the share of its worker slots that are filled",
                 doc.all_text):
        homes["5.8"] = None

    cited = []
    for m in re.finditer(r"partial staffing (?:that )?pays pro-rata", doc.all_text):
        tail = doc.all_text[m.end():m.end() + 140]
        ref = re.search(r"\((\d+\.\d+)\)", tail)
        if ref:
            cited.append(ref.group(1))
        else:
            homes.setdefault("an uncited restatement", None)
    return homes, cited


def birth_prices(doc: Doc) -> dict:
    """The two birth-cost formulas and 9.5's own worked examples, all evaluated.

    9.5 prices a birth geometrically and 11.5 linearly. Quoting the two
    sentences side by side understates it: they agree at the first birth and
    diverge elevenfold by the roster ceiling, which is a number a reader can
    act on and "geometric against linear" is not.

    Both formulas are read at their plain reading — the exponent is the count
    already owned, so the nth birth is priced at ``n - 1``. That reading is
    forced by the words "ruleborn owned" and "per character already owned",
    and by the two rows either side of it in the same table, which write their
    offsets out as ``level − 2`` and ``level − 1``. The birth row is the only
    one in 9.5 that leaves its offset to be inferred, which is why the check
    also compares the formula against 9.5's own worked examples: those sit one
    whole step of the curve higher, and one of the two is wrong.
    """
    geo = re.search(r"(\d+) × ([\d.]+)<sup>ruleborn owned</sup>", doc.raw)
    lin = re.search(
        r"A birth costs (\d+) Essence plus (\d+) per character already owned",
        doc.all_text)
    # Read only from the cell that carries the formula. An earlier version
    # matched "about N for the Nth" across the whole document and so found the
    # first example and missed the other two, because only the first is
    # written with "about" — a check that looked satisfied on a third of its
    # own evidence.
    cell = re.search(r"ruleborn owned</sup> Essence \(([^)]*)\)", doc.raw)
    out = {"examples": dict(
        (int(n), int(c.replace(",", ""))) for c, n in re.findall(
            r"([\d,]+) for the (\d+)(?:st|nd|rd|th)", cell.group(1) if cell else ""))}
    #: The ordinals 9.5 works out, and the Hearth cap 11.5 gives the roster.
    at = (10, 20, 30, 38)
    if geo:
        base, rate = int(geo.group(1)), float(geo.group(2))
        out["geometric"] = {n: base * rate ** (n - 1) for n in at}
        out["by_ordinal"] = {n: base * rate ** n for n in at}
    if lin:
        base, step = int(lin.group(1)), int(lin.group(2))
        out["linear"] = {n: base + step * (n - 1) for n in at}
    return out


def check_twice_stated(doc: Doc, led: Ledger) -> None:
    """C27 and C28: the two facts F25 lists that no other check reaches."""
    homes, cited = staffing_rules(doc)
    stepped = {k: v for k, v in homes.items() if v}
    share = sorted(k for k, v in homes.items() if v is None)
    if stepped and share:
        n = max(len(v) for v in stepped.values())
        says = " and ".join(f"\u00a7{k}" for k in sorted(stepped))
        gives = " and ".join(f"\u00a7{k}" for k in share)
        gaps = []
        for i in range(n):
            told = sorted({v[i] for v in stepped.values() if i < len(v)})
            want = round(100 * (i + 1) / n)
            if all(abs(t - 100 * (i + 1) / n) <= 1 for t in told):
                continue
            gaps.append(f"{i + 1}/{n} staffed: {says} say "
                        f"{'/'.join(f'{t}%' for t in told)}, {gives} "
                        f"{'give' if len(share) > 1 else 'gives'} {want}%")
        led.check("a producer's partial output is stated once (5.8)", not gaps,
                  f"{len(homes)} homes"
                  + (f", plus {len(cited)} restatement(s) that cite "
                     f"\u00a7{cited[0]} and so are not homes" if cited else "")
                  + " \u2014 " + "; ".join(gaps), tracks="C27")
    else:
        # One rule, however many sections cite it, is what this check wants.
        # None at all means it has lost its subject, and a check that has lost
        # its subject passes for ever.
        led.check("a producer's partial output is stated once (5.8)",
                  bool(homes),
                  f"homes: {homes}" if homes else
                  "neither rule is where this check looks for it", tracks="C27")

    b = birth_prices(doc)
    geo, lin, examples = b.get("geometric"), b.get("linear"), b["examples"]
    if geo and lin:
        apart = [f"the {n}th: 9.5 gives {geo[n]:,.0f}, 11.5 gives {lin[n]:,.0f} "
                 f"({geo[n] / lin[n]:.1f}×)"
                 for n in sorted(geo) if abs(geo[n] - lin[n]) / lin[n] > 0.05]
        led.check("a birth is priced once (9.5)", not apart, "; ".join(apart),
                  tracks="C28")
    else:
        # Exactly one of the two formulas is what this check wants to see. None
        # at all is not success — it means the check can no longer find its own
        # subject, and a check that has lost its subject passes for ever.
        led.check("a birth is priced once (9.5)", bool(geo or lin),
                  f"9.5 formula {'found' if geo else 'missing'}, "
                  f"11.5 formula {'found' if lin else 'missing'}",
                  tracks="C28")

    # A formula and the examples beside it are the same fact twice over, which
    # is 31.2's rule at the smallest scale there is: inside one table cell.
    if geo and examples:
        off = [f"the {n}th: the formula gives {geo[n]:,.0f}, the cell says "
               f"{c:,} (= {b['by_ordinal'][n]:,.0f}, one step higher)"
               for n, c in sorted(examples.items())
               if n in geo and abs(geo[n] - c) / c > 0.03]
        led.check("9.5's birth examples match 9.5's own birth formula", not off,
                  "; ".join(off), tracks="C28")


def check_document_register(doc: Doc, led: Ledger) -> None:
    """The document's own audit table in 31.9 must carry nothing still open.

    This is v3.1's check on itself, kept. It is not the same as this
    repository's register, and the difference is the point of F24 and F25:
    31.9 lists what v3.1 believes it closed, and believing it is what this
    whole file exists to avoid.
    """
    reg = doc.section("decisions")
    still_open = re.findall(r">(OPEN|PROPOSED)<", reg)
    led.check("31.9 lists no open items in the document's own register",
              not still_open, str(collections.Counter(still_open)))


def check_cross_references(doc: Doc, led: Ledger) -> None:
    """Every "(12.17)"-style citation in the prose points at a section that exists.

    Not in either checker. v3.1 renumbered four chapters — 5.9 became 5.8,
    25.5 became 25.4 — and moved every citation with them. Nothing was checking
    that, and a renumbering that misses one leaves a reference pointing at
    whatever now holds that number, which reads correct and is not.
    """
    sections, dangling = _citations(doc)
    led.check(f"every section citation in the prose resolves ({len(sections)} sections)",
              not dangling, str(sorted(dangling)[:10]))


def _citations(doc: Doc) -> tuple[set[str], set[str]]:
    """Separate "(12.17, 5.4)" citations from "(1.0, 1.3, 1.6)" values.

    The document writes both as bare numbers in parentheses, so the two have to
    be told apart before either can be checked. A group counts as citations only
    when *every* decimal token in it could be a section: a chapter that exists,
    and a subsection of 1 or more. That rejects effect sizes (0.27, 0.40), which
    have no chapter 0, and 5.5's law-cost tiers (1.0, 1.3, 1.6), which are
    disqualified by the 1.0 — a subsection 0 does not exist anywhere.

    On v3.1 this accepts 275 groups, rejects exactly those four, and finds
    nothing dangling, which is what makes v3.1's renumbering trustworthy rather
    than merely claimed.
    """
    sections = set(re.findall(r"^(\d+\.\d+) ", doc.text, re.M))
    chapters = {s.split(".")[0] for s in sections}

    def could_be_a_section(tok: str) -> bool:
        if not re.fullmatch(r"[1-9]\d*\.\d+", tok):
            return False
        chapter, sub = tok.split(".")
        return chapter in chapters and not sub.startswith("0") and int(sub) >= 1

    dangling: set[str] = set()
    for m in re.finditer(r"\(([0-9][0-9.,\s]*[0-9])\)", doc.norm_text):
        tokens = [t.strip() for t in m.group(1).split(",")]
        decimals = [t for t in tokens if re.fullmatch(r"\d+\.\d+", t)]
        if not decimals or not all(could_be_a_section(t) for t in decimals):
            continue
        dangling |= {t for t in decimals if t not in sections}
    return sections, dangling


# --------------------------------------------------------------------------
# Running everything
# --------------------------------------------------------------------------

def run(path: str = DEFAULT_DOC, quiet: bool = False) -> Ledger:
    doc = Doc(path)
    led = Ledger(quiet=quiet)

    check_constants(doc, led)
    check_retired_names(doc, led)
    check_arithmetic(doc, led)
    check_inventory(doc, led)
    check_asset_budget(doc, led)
    check_creatures(doc, led)
    check_page_economy(doc, led)
    check_banned_phrasings(doc, led)
    check_detection_model(doc, led)
    check_library_curve(doc, led)
    check_twice_stated(doc, led)
    check_document_register(doc, led)
    check_structure(doc, led)
    check_cross_references(doc, led)

    # The design checks, run against the text view derived from this same HTML.
    for label, ok, detail in design.run(path, text=doc.text):
        led.check(label, ok, detail, tracks=TRACKED.get(label))

    return led


# --------------------------------------------------------------------------
# Self-test
# --------------------------------------------------------------------------

SELF_TEST_DOC = """<!doctype html><html><body>
<section id="laws"><h2><span class="num">7</span></h2>
<h3>7.6 Getting and improving laws</h3>
<p>PLACEHOLDER</p>
<h3>7.9 Rarity buys specificity</h3>
<table><tr><td>Rank</td><td>Count</td><td>Character</td><td>Pages to restore</td></tr>
<tr><td>Common</td><td>18</td><td>x</td><td>10</td></tr>
<tr><td>Uncommon</td><td>12</td><td>x</td><td>20</td></tr>
<tr><td>Rare</td><td>6</td><td>x</td><td>35</td></tr>
<tr><td>Deep</td><td>12</td><td>x</td><td>60</td></tr></table>
</section></body></html>"""

CLEAN = "Restoring a law: 10 pages for a common law, 20 for an uncommon one, 35 for a rare one."
STALE = "Restoring a law: 15 pages for a common law, 30 for a rare one, 60 for a deep one."



#: A price list and a birth rule, for the two checks F25's list needed. Both
#: are written the way v3.1 writes them, so the self-test exercises the same
#: patterns the real document does rather than a simplified stand-in.
TWICE_DOC = """<!doctype html><html><body>
<section id="economy"><h2><span class="num">9</span></h2>
<h3>5.8 One producer of each kind per realm</h3>
<p>A producer STAFFING_RULE, so a half-staffed Well earns half.</p>
<h3>9.2 How everything connects</h3>
<table><tr><td>Working</td><td>Wells</td><td>Ruleborn</td>
<td>Staffing sets STEPS output</td></tr></table>
<h3>9.3 Production</h3>
<p>Output an hour = base &times; 1.35<sup>level &minus; 1</sup> &times; FORMULA_STAFFING</p>
<h3>9.5 Price list</h3>
<table><tr><td>A new ruleborn</td>
<td data-label="Cost">100 \u00d7 1.15<sup>ruleborn owned</sup> Essence (EXAMPLES)</td>
</tr></table>
<h3>11.5 Where characters come from</h3>
<p>BIRTH_RULE</p>
<h3>27.2 Decisions taken</h3>
<p>RESTATEMENT</p>
</section></body></html>"""

PRO_RATA = "runs at the share of its worker slots that are filled"
STEPPED = "60%, 85% or 100%"
PROPORTIONAL = "33%, 66% or 100%"
FORMULA_STEPPED = "staffing (0.6, 0.85 or 1.0)"
FORMULA_PLAIN = "staffing"
CITED = "One of each kind per realm; partial staffing pays pro-rata (5.8)"
UNCITED = "One of each kind per realm; partial staffing pays pro-rata, always"
NOTHING = "One of each kind per realm."
GEOMETRIC_EXAMPLES = "about 352 for the 10th, 1,423 for the 20th, 5,758 for the 30th"
SHIFTED_EXAMPLES = "about 400 for the 10th, 1,600 for the 20th, 6,600 for the 30th"
LINEAR = "A birth costs 100 Essence plus 40 per character already owned"
NO_LINEAR = "Births draw their kind from the schools of the woven laws"


def _twice_doc(steps: str, examples: str, birth: str,
               formula: str = FORMULA_PLAIN, restated: str = NOTHING) -> Doc:
    return Doc("<self-test>", TWICE_DOC
               .replace("STAFFING_RULE", PRO_RATA)
               .replace("FORMULA_STAFFING", formula)
               .replace("RESTATEMENT", restated)
               .replace("STEPS", steps)
               .replace("EXAMPLES", examples)
               .replace("BIRTH_RULE", birth))


def _self_test_twice_stated() -> bool:
    """C27 and C28 have to go green on a document that states each fact once.

    A check that only ever fails is indistinguishable from one that is broken,
    and both of these are failing against the real document today — so the
    version that matters is the one where the fault is absent.
    """
    ok = True
    cases = (
        ("both faults present", dict(steps=STEPPED, examples=SHIFTED_EXAMPLES,
                                     birth=LINEAR),
         {"partial output": False, "priced once": False, "birth examples": False}),
        ("each fact stated once", dict(steps=PROPORTIONAL,
                                       examples=GEOMETRIC_EXAMPLES, birth=NO_LINEAR),
         {"partial output": True, "priced once": True, "birth examples": True}),
        ("only the staffing fault", dict(steps=STEPPED,
                                         examples=GEOMETRIC_EXAMPLES, birth=NO_LINEAR),
         {"partial output": False, "priced once": True, "birth examples": True}),
        ("only the examples fault", dict(steps=PROPORTIONAL,
                                         examples=SHIFTED_EXAMPLES, birth=NO_LINEAR),
         {"partial output": True, "priced once": True, "birth examples": False}),
        # The state C27's drafted edit would leave if it only deleted 9.2's
        # caption: the table reads pro-rata and the formula still multiplies
        # by 0.6. This is the case the check was widened for.
        ("the caption fixed, the formula not",
         dict(steps=PROPORTIONAL, examples=GEOMETRIC_EXAMPLES, birth=NO_LINEAR,
              formula=FORMULA_STEPPED),
         {"partial output": False, "priced once": True, "birth examples": True}),
        # 31.2 allows a restatement that cites its home, so one must not read
        # as a second home.
        ("a restatement that cites its home",
         dict(steps=PROPORTIONAL, examples=GEOMETRIC_EXAMPLES, birth=NO_LINEAR,
              restated=CITED),
         {"partial output": True, "priced once": True, "birth examples": True}),
    )
    for name, kw, expect in cases:
        led = Ledger(quiet=True)
        check_twice_stated(_twice_doc(**kw), led)
        got = {}
        for state, label, _detail, _tracks in led.rows:
            for needle in expect:
                if needle in label:
                    # A tracked check that passes reports RETIRED rather than
                    # PASS, because its register item is still open. Both mean
                    # the fault is absent, which is what the case asserts.
                    got[needle] = state in (PASS, RETIRED)
        line = ", ".join(f"{k} {'green' if v else 'RED'}" for k, v in sorted(got.items()))
        print(f"  {name}: {line}")
        for needle, want in expect.items():
            if got.get(needle) is not want:
                print(f"    FAIL: {needle} should have been "
                      f"{'green' if want else 'RED'}, was {got.get(needle)}")
                ok = False
    return ok

def _self_test_f25_gate() -> bool:
    """The coverage report has to fail when F25 names a fact nothing checks.

    Otherwise it is a list printing itself back: every row green because every
    row was written by somebody who knew the check existed. Planting an id with
    no check is the only way to tell the two apart.
    """
    from audit_register import REGISTER
    f25 = next((i for i in REGISTER if i["id"] == "F25"), None)
    if not f25:
        print("  [FAIL] F25 is not in the register, so its list cannot be read")
        return False
    was = f25["body"]
    before = twice_stated_items()
    f25["body"] = was.replace("<code>", "<code>C99 a planted fact &middot; nowhere<br>", 1)
    listed = twice_stated_items()
    try:
        out = io.StringIO()
        with contextlib.redirect_stdout(out):
            rc = coverage()
    finally:
        f25["body"] = was
    caught = rc == 1 and "C99" in out.getvalue()
    print(f"  [{'PASS' if caught else 'FAIL'}] F25's list is read from F25 "
          f"({len(before)} facts) and a fact nothing checks "
          f"{'fails the coverage report' if caught else 'IS MISSED'}")
    return caught and len(listed) == len(before) + 1



def _self_test_detection() -> bool:
    """The same gap, for the second of the four bans.

    The retired model was "one 120 degree cone" and awareness in percent per
    second. Both bans search for those words. A document that states the same
    model in other words — a single undifferentiated cone, and a threshold as a
    percentage — passes both and fails the derived check, which reads §12.17's
    own two tables instead.
    """
    ok = True
    states = {"suspicious": 200, "investigating": 600, "alerted": 1000}

    for name, text, expect_clean in (
        ("12.17's own thresholds", "Suspicious at 200, investigating at 600, "
                                   "alerted at 1000.", True),
        ("the retired model in other words", "The guard investigates at 50 and "
                                             "the alarm at 100%.", False),
    ):
        banned = not re.findall(r"\d+%\s*awareness|awareness[^.]{0,30}\d+%|"
                                r"one 120\u00b0 cone", text, flags=re.I)
        wrong = []
        for word, value, percent in re.findall(
                r"\b(suspicious|investigating|investigate|alerted|alarm)\s+at\s+"
                r"([\d,]+)\s*(%?)", text, flags=re.I):
            key = {"investigate": "investigating", "alarm": "alerted"}.get(
                word.lower(), word.lower())
            if percent or int(value.replace(",", "")) != states.get(key):
                wrong.append(word)
        derived = not wrong
        print(f"  detection, {name}: phrase ban says "
              f"{'green' if banned else 'RED'}; derived check says "
              f"{'green' if derived else 'RED'}")
        if derived is not expect_clean:
            print("    FAIL: the derived check read it the wrong way round")
            ok = False
        if not expect_clean and not banned:
            print("    note: the phrase ban caught it too — the self-test is stale")

    # And the property a single cone cannot have: peripheral wider than cone.
    for label, cone, zones, peripheral, want in (
        ("three zones inside a cone", 45.0, [2.0, 4.0, 6.0], 110.0, True),
        ("one cone, no zones", 120.0, [6.0, None, None], 120.0, False),
    ):
        graded = [z for z in zones if z is not None]
        got = len(graded) >= 2 and graded == sorted(graded) and peripheral > cone
        print(f"  detection, {label}: reads as "
              f"{'graded zones' if got else 'a single cone'}")
        if got is not want:
            print("    FAIL: the zone test read it the wrong way round")
            ok = False
    return ok


def self_test() -> int:
    """Show the derived check catching what the phrase ban cannot.

    This is F24 reduced to eleven lines. The planted sentence states the retired
    three-rank costs without using the banned phrase, so the phrase ban reports
    green on a document that carries the model it exists to delete.
    """
    ok = True

    for name, sentence, expect_clean in (("clean", CLEAN, True), ("stale", STALE, False)):
        doc = Doc("<self-test>", SELF_TEST_DOC.replace("PLACEHOLDER", sentence))

        banned = not re.findall(r"15, 30 or 60 pages", doc.norm_text, re.I)
        prices = rank_prices(doc)
        derived = not [c for c in page_cost_claims(doc.norm_text)
                       if c[1] in prices and c[2] != prices[c[1]] and c[2] in (15, 30, 60)]

        print(f"  {name} document: phrase ban says {'green' if banned else 'RED'}; "
              f"derived check says {'green' if derived else 'RED'}")

        if derived is not expect_clean:
            print(f"    FAIL: the derived check should have said "
                  f"{'green' if expect_clean else 'RED'}")
            ok = False
        if name == "stale" and banned is not True:
            print("    note: the phrase ban caught it after all — the self-test is stale")

    ok = _self_test_twice_stated() and ok
    ok = _self_test_f25_gate() and ok
    ok = _self_test_citations() and ok
    ok = _self_test_ledger() and ok
    ok = _self_test_detection() and ok

    if ok:
        print("\n  self-test: the derived check catches the three-rank model stated in\n"
              "  7.6's own words, which the banned phrase reports green. That is F24,\n"
              "  and it is the reason the two checkers were worth merging rather than\n"
              "  concatenating.")
    return 0 if ok else 1


CITE_DOC = """<!doctype html><html><body>
<section id="a"><h2><span class="num">5</span></h2>
<h3>5.1 One</h3><p>a</p><h3>5.2 Two</h3><p>PLACEHOLDER</p></section>
</body></html>"""


def _self_test_citations() -> bool:
    """A renumbering that misses a citation must be caught, and a value must not.

    Both halves matter. The check earns nothing if it cannot see a reference
    left pointing at a deleted section; it is worse than nothing if it reports
    every effect size and tier multiplier in the document as a broken link,
    which is what the first version of it did.
    """
    cases = [
        ("a resolving citation", "The rule is stated once (5.1).", set()),
        ("a citation left behind by a renumbering", "The rule is stated once (5.9).", {"5.9"}),
        ("an effect size, not a citation", "Rewards reduce later interest (0.40).", set()),
        ("5.5's law-cost tiers, not citations", "Base × tier (1.0, 1.3, 1.6).", set()),
    ]
    ok = True
    for name, sentence, expect in cases:
        _, dangling = _citations(Doc("<self-test>", CITE_DOC.replace("PLACEHOLDER", sentence)))
        good = dangling == expect
        print(f"  citations, {name}: {'caught' if dangling else 'clean'}"
              f"{'' if good else '  <-- FAIL, expected ' + (str(expect) or 'clean')}")
        ok = ok and good
    return ok


def _self_test_ledger() -> bool:
    """The four states, including the one neither checker could reach.

    A tracked check failing while the register calls its item fixed is the
    register lying about the document. Nothing caught that before: v3.1's
    checker has no register to consult, and this repository's could not fail
    the build. It is the fault C21-C24 all were, and it is now a build break.
    """
    import unittest.mock as mock
    cases = [
        ("structural, passing", True, None, True, PASS),
        ("structural, failing", False, None, True, BREAK),
        ("tracked, failing, item open", False, "C23", True, OPEN),
        ("tracked, passing, item open", True, "C23", True, RETIRED),
        ("tracked, failing, item closed", False, "C7", False, BREAK),
        ("tracked, passing, item closed", True, "C7", False, PASS),
    ]
    ok = True
    for name, result, tracks, item_open, expect in cases:
        led = Ledger(quiet=True)
        with mock.patch(__name__ + "._is_open", return_value=item_open):
            led.check("x", result, "", tracks=tracks)
        got = led.rows[0][0]
        good = got == expect
        print(f"  ledger, {name}: {got}{'' if good else '  <-- FAIL, expected ' + expect}")
        ok = ok and good
    return ok


def twice_stated_items() -> list[str]:
    """The register items F25 lists as facts with two homes, read from F25.

    F25's list is prose, and prose is how a list stops being true. Reading the
    ids out of it means the coverage report below fails when a fact is added to
    that list and nothing checks it — which is what C27 and C28 were, sitting
    unchecked in a list of six for as long as the list existed.
    """
    from audit_register import REGISTER
    item = next((i for i in REGISTER if i["id"] == "F25"), None)
    if not item:
        return []
    block = re.search(r"<code>(.*?)</code>", item["body"], re.S)
    return re.findall(r"(?:^|>)\s*([CDFGQ]\d+)\s", block.group(1) if block else "")


def coverage() -> int:
    """Fail if any check v3.1 performs is no longer covered here."""
    rows = run(quiet=True).rows
    labels = [row[1] for row in rows]
    missing = [v for v in COVERS.values() if not any(v in lab for lab in labels)]
    for name, needle in COVERS.items():
        hit = any(needle in lab for lab in labels)
        print(f"  [{'ok ' if hit else 'GAP'}] {name}")
    # This list is authored, which is the fault F24 is about, so it is checked
    # the same way COVERS is: a label here that no check produces is a claim
    # about work that is not being done. It is matched as a prefix rather than
    # exactly, because a label may carry a live count — and the first version
    # of this, which matched exactly, found that one already had.
    for label in ADDED_BY_THE_MERGE:
        hit = any(lab.startswith(label) for lab in labels)
        print(f"  [{'new' if hit else 'GONE'}] {label}")
        if not hit:
            missing.append(label)
    # F25's six twice-stated facts, each of which has to be checked by
    # something here rather than only written down over there.
    tracked = {row[3] for row in rows if row[3]}
    listed = twice_stated_items()
    if listed:
        print()
        for item_id in listed:
            hit = item_id in tracked
            print(f"  [{'ok ' if hit else 'GAP'}] F25's {item_id}: a fact with two "
                  f"homes, {'checked here' if hit else 'CHECKED BY NOTHING'}")
            if not hit:
                missing.append(f"F25 lists {item_id} and no check tracks it")

    print(f"\n  {len(COVERS)} of v3.1's checks covered, "
          f"{len(ADDED_BY_THE_MERGE)} added, {len(labels)} checks run in total.")
    if missing:
        print(f"  {len(missing)} GAP(S): {missing}")
    return 1 if missing else 0


def main() -> int:
    if "--self-test" in sys.argv:
        return self_test()
    if "--coverage" in sys.argv:
        return coverage()
    args = [a for a in sys.argv[1:] if not a.startswith("--")]
    path = args[0] if args else DEFAULT_DOC
    print(f"Checking {os.path.relpath(path, ROOT)}")
    return run(path).report()


if __name__ == "__main__":
    raise SystemExit(main())
