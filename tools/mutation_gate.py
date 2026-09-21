#!/usr/bin/env python3
"""Two mutation suites over the design document's gates, and the gap between
them.

    python3 tools/mutation_gate.py
    python3 tools/mutation_gate.py --self-test     # the same, quickly

Why this exists
---------------
v3.1 ships its own checker in `tools/vendor/`, and §31.5 makes a claim about
it: *"Fifteen checks, and fifteen deliberate breakages that each one must
catch."* Nobody in this repository had ever run that. The vendor README keeps
the files unmodified so the claim can be re-run rather than believed, and this
re-runs it — against v3.1 rather than the v3.0 paths it shipped with, without
editing a line of it.

**It passes. All fifteen.** That is worth knowing and worth keeping green.

The second suite is the point
-----------------------------
A mutation suite tests each check against the defect the check was written
for. F24 is the observation that this is weaker than it sounds: the ban on the
retired page costs catches `15, 30 or 60 pages` and misses §7.6 saying the same
thing with the clause rearranged — which v3.1 still says, and which the gate
has reported green on every build since.

So `RESTATEMENTS` plants the same defects **in other words**: the wording a
writer would actually reach for, not a wording invented to dodge a regex. Each
one is the same model, the same contradiction, the same retired name.

The result is the argument for finishing F24's programme rather than a
complaint about the vendor gate, which is better than what this repository had
for the same job. Where a ban has been replaced with a check derived from the
document's own tables, the restatement is caught. Where it has not, it is not.

Nothing here edits `tools/vendor/`. Both suites run against a copy in a
temporary directory.
"""

import argparse
import os
import pathlib
import re
import shutil
import subprocess
import sys
import tempfile

ROOT = pathlib.Path(__file__).resolve().parent.parent
sys.path.insert(0, str(ROOT / "tools"))
from design_doc import HTML as DOC                                # noqa: E402

VENDOR = ROOT / "tools" / "vendor"
UPSTREAM = ROOT / "content" / "upstream"

#: Where a planted sentence goes: the first paragraph of the document, which is
#: normative text under a heading every version has had.
ANCHOR = '<h3>1.1 The pitch</h3>'

#: The same defects the gate names, said the way a writer would say them.
#:
#: Each entry is (name, the check it is a defect of, the sentence to plant, and
#: the argument that it is the same defect rather than a different one).
RESTATEMENTS = [
    ("percent awareness, as a threshold", "superseded model absent: percent awareness",
     "<p>The guard investigates at 50% and raises the alarm at 100%.</p>",
     "The ban reads `\\d+%\\s*awareness`, so it wants the word beside the "
     "number. This is the retired model's own wording, from §29.1 before "
     "v3.1 rewrote it — a threshold as a percentage, with the word "
     "'awareness' nowhere in the sentence."),

    ("three-rank prose, in the plural", "no stale three-rank prose",
     "<p>Each school has three commons, three rares and two deeps.</p>",
     "The ban lists three phrasings, all singular. The plural is the same "
     "claim about the same retired scheme and matches none of them."),

    ("a retired name, in lower case", "retired name absent: Lawbound",
     "<p>The lawbound era is over.</p>",
     "`T_NORM.count(\"Lawbound\")` is case-sensitive. A retired name is "
     "retired in every case, and prose lower-cases a proper noun the moment "
     "it becomes an adjective."),

    ("the tick rate, contradicted in other words", "constant tick_rate",
     "<p>The simulation advances 20 steps a second.</p>",
     "The constant is found by the pattern `fixed (\\d+) steps a second`, so "
     "a second value stated without the word 'fixed' is not compared against "
     "anything. This is C7 — two tick rates — reintroduced in the "
     "words the document uses everywhere else."),

    ("a single cone, spelled out", "superseded model absent: single vision cone",
     "<p>Each guard sees a single 120-degree cone.</p>",
     "The ban is the literal string `one 120° cone`. Spelling the degree "
     "sign out is what a writer does when the symbol is awkward, and it is "
     "the same deleted model."),

    ("the page costs, rearranged", "superseded model absent: three-rank page costs",
     "<p>Restoring a law costs 15 pages for a common law, 30 for a rare one "
     "and 60 for a deep one.</p>",
     "F24's own example, and the one §7.6 still contains. Same three "
     "ranks, same three numbers, one clause moved."),
]

#: What each suite catches today. Pinned, because the useful failure here is
#: an *improvement* that nobody notices: derive one of the remaining bans and
#: a restatement flips to caught, and this says so rather than passing quietly.
EXPECTED_VENDOR = 0
EXPECTED_OURS = {name for name, *_ in RESTATEMENTS}


def vendor_copy(tmp: pathlib.Path) -> pathlib.Path:
    """The shipped checker, unmodified, with the data it reads beside it."""
    (tmp / "tools").mkdir(parents=True, exist_ok=True)
    (tmp / "data").mkdir(exist_ok=True)
    for name in ("check.py", "mutate.py", "generate.py"):
        shutil.copy(VENDOR / name, tmp / "tools" / name)
    for path in UPSTREAM.glob("*.json"):
        shutil.copy(path, tmp / "data" / path.name)
    return tmp


def run_vendor(tmp: pathlib.Path, doc: pathlib.Path) -> str:
    return subprocess.run([sys.executable, "tools/check.py", str(doc)],
                          cwd=tmp, capture_output=True, text=True).stdout


def shipped_suite(tmp: pathlib.Path) -> tuple[int, int, list[str]]:
    """§31.5's own fifteen breakages, run against the current document.

    `mutate.py` hard-codes v3.0's paths, so it is invoked with the document as
    an argument from inside the copy rather than edited.
    """
    out = subprocess.run([sys.executable, "tools/mutate.py", str(DOC)],
                         cwd=tmp, capture_output=True, text=True).stdout
    caught = [l for l in out.splitlines() if l.startswith("CAUGHT")]
    survived = [l for l in out.splitlines()
                if l.startswith("SURVIVED") or l.startswith("SKIP")]
    return len(caught), len(caught) + len(survived), survived


def _verdict_lines(doc: pathlib.Path) -> set[str]:
    out = subprocess.run([sys.executable, str(ROOT / "tools" / "check_document.py"),
                          str(doc)], capture_output=True, text=True).stdout
    return {l for l in out.splitlines() if not l.startswith("Checking")}


def restatement_suite(tmp: pathlib.Path) -> list[dict]:
    """Each restatement, against both checkers."""
    source = DOC.read_text(encoding="utf-8")
    clean_ours = _verdict_lines(DOC)
    out = []
    for name, check_name, sentence, why in RESTATEMENTS:
        planted = source.replace(ANCHOR, ANCHOR + sentence, 1)
        if planted == source:
            out.append(dict(name=name, why=why, vendor=None, ours=None,
                            note="the anchor moved; nothing was planted"))
            continue
        with tempfile.NamedTemporaryFile("w", suffix=".html", delete=False,
                                         encoding="utf-8") as fh:
            fh.write(planted)
            path = pathlib.Path(fh.name)
        vendor = any(l.startswith("FAIL") and check_name in l
                     for l in run_vendor(tmp, path).splitlines())
        ours = bool(_verdict_lines(path) - clean_ours)
        path.unlink()
        out.append(dict(name=name, why=why, vendor=vendor, ours=ours, note=""))
    return out


def report(quick: bool = False) -> int:
    ok = True
    with tempfile.TemporaryDirectory() as raw:
        tmp = vendor_copy(pathlib.Path(raw))

        if not quick:
            caught, total, survived = shipped_suite(tmp)
            print(f"§31.5's own fifteen breakages, against v{DOC.stem[-3:]}\n")
            print(f"  {caught} of {total} caught")
            for line in survived:
                print(f"    {line}")
            if caught != total or total != 15:
                print("  §31.5 says fifteen, and each must be caught.")
                ok = False
            else:
                print("  The claim holds. The shipped gate has teeth against the "
                      "defects it names.\n")

        rows = restatement_suite(tmp)
        print("The same defects, said in other words\n")
        width = max(len(r["name"]) for r in rows) + 2
        print(f"  {'':<{width}}{'shipped':>10}{'ours':>9}")
        for row in rows:
            v = "—" if row["vendor"] is None else (
                "caught" if row["vendor"] else "survives")
            o = "—" if row["ours"] is None else (
                "caught" if row["ours"] else "survives")
            print(f"  {row['name']:<{width}}{v:>10}{o:>9}")
            if row["note"]:
                print(f"  {'':<{width}}{row['note']}")
        print()
        for row in rows:
            print(f"  {row['name']}")
            print(f"    {row['why']}\n")

        vendor_caught = sum(1 for r in rows if r["vendor"])
        ours = {r["name"] for r in rows if r["ours"]}
        print(f"  The shipped gate catches {vendor_caught} of {len(rows)}; this "
              f"repository's catches {len(ours)} of {len(rows)}.")
        print("  All four bans are derived now: from the constants' own units, "
              "the 48 sheets'\n  per-school distribution, \u00a712.17's vision "
              "table, and a retired name read\n  case-insensitively. That is "
              "F24's programme finished, and D38 is the measurement\n  that "
              "said which four were still phrase bans.")
        if vendor_caught != EXPECTED_VENDOR or ours != EXPECTED_OURS:
            print(f"\n  This has moved: expected the shipped gate to catch "
                  f"{EXPECTED_VENDOR} and ours to catch {sorted(EXPECTED_OURS)}.")
            print("  If a ban was derived, update EXPECTED_OURS and D38 with it.")
            ok = False
    return 0 if ok else 1


def main() -> int:
    ap = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    ap.add_argument("--self-test", action="store_true",
                    help="skip the shipped fifteen, which are slow")
    args = ap.parse_args()
    return report(quick=args.self_test)


if __name__ == "__main__":
    sys.exit(main())
