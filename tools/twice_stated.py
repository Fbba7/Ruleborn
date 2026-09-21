#!/usr/bin/env python3
"""Facts the design document states in more than one section, found by scanning.

    python3 tools/twice_stated.py
    python3 tools/twice_stated.py --self-test

Why this exists
---------------
§31.2's rule is that every fact has exactly one place it is stated. F25 lists
six facts that break it, and all six were found by reading — which means all
six had already *diverged*, because a contradiction is what reading finds. A
fact stated twice that still agrees looks like prose.

Those are the ones that matter. The load rate, the rank split and the two
rosters all agreed until one copy was edited, and then they were C22, C3 and
C6. §31.2 is about one home, not about agreement.

So this scans instead of reading: every sentence carrying a number, paired
across sections by word overlap. D39 came out of it — §7.4 restates 240 of
§7.7's facts word for word — and so did D40, a revive threshold granted by
four systems at three different values.

What is exempt, and why
-----------------------
Nothing is exempt by rule. Every exemption is a named section or a named pair
with the reason written beside it, because a rule would quietly grow and a
list has to be re-read. `RESTATING` holds sections whose job is to restate —
the evidence log, the decision log, the sources list, "claims we don't rely
on" — and `COVERED` holds pairs something else already answers, each naming
what answers it.

D44 is the pass that read the residue. Of the eleven pairs nothing covered,
four became exemptions, four were already register items that said so badly,
three were faults, and one stayed live: §5.1 and §7.1 price a law's economy
with the clauses reversed, agreeing today and guarded by nothing.

**§29.1 is not exempt, and neither is a cell that cites its own home.** The
appendix is an index, and C21 is the proof that this kind drifts: it carried
the detection model §12.8 had deleted, and cited §12.8 as the source. The §19
evidence tables cite their homes too, and two of them have already drifted
apart about whether tracks start partly filled. A citation makes a
restatement *checkable*, which is not the same as safe — D43 is the check it
makes possible.
"""

import argparse
import collections
import itertools
import pathlib
import re
import sys

ROOT = pathlib.Path(__file__).resolve().parent.parent
sys.path.insert(0, str(ROOT / "tools"))
import check_document                                             # noqa: E402

#: Words that carry no subject. A pair sharing only these shares nothing.
STOP = set("the a an of to and or in is are for that with it its on at by as "
           "be this each every all from per".split())

#: A pair is a restatement when it shares at least this many content words and
#: this much of their union. Both are needed: the count stops a short sentence
#: pairing on two words, the ratio stops a long one pairing on a fifth of
#: itself.
SHARED_WORDS, OVERLAP = 6, 0.5

#: Sentences shorter than this carry no fact; longer than this are paragraphs
#: and pair on their shape rather than their content.
MIN_LEN, MAX_LEN = 25, 220

#: Sections whose job is to restate, with the reason each one is allowed to.
#: A prefix, so "30." covers the whole evidence log and "19.8" one subsection.
RESTATING = {
    "30.": "the evidence log; restating the evidence it logs is what a log is",
    "27.": "the decision log, for the same reason",
    "28.3": "the sources list; an annotated entry states what its source "
            "found, and the body cites it by number",
    "19.8": "\u201cclaims we don\u2019t rely on\u201d; naming a rejected "
            "claim requires stating what replaces it",
}

#: Pairs something else already answers, with what answers them. Each was read
#: against its two sections once, which is the only way a list like this stays
#: worth having: an unexamined row is a row nobody is responsible for.
COVERED = {
    ("7.4", "7.7"): "D39 compares all 240 facts field by field",
    ("21.7", "7.7"): "D39; one of the 48 movement signatures it compares",
    ("11.10", "18.3"): "D40; one revive threshold from four systems at three "
                       "values",
    ("29.1", "5.4"): "D43 checks every appendix row against the section it "
                     "cites",
    ("29.1", "9.5"): "D43, the same row-by-row comparison",
    ("12.5", "5.4"): "D44; the heist clock has three homes and only \u00a712.5 "
                     "carries the Haste clause",
    ("2.7", "25.1"): "D44; \u00a72.7 derives its monthly players from "
                     "\u00a725.1\u2019s gate, and rounds outward",
    # The §19 evidence tables summarise a rule in an "In Ruleborn" column
    # and cite its home in the same cell. That is the best shape a restatement
    # can have and it is still not safety — C21 cited its home too. It
    # makes the restatement *checkable*, which is a different thing, and the
    # drift these two already carry ("Albums" against "Albums and tracks",
    # both citing §14.8) is what it looks like when nobody checks.
    ("19.11", "19.2"): "D44; an evidence cell citing its home, already drifted",
    ("19.2", "19.4"): "D44; the same, still agreeing",
}


def sections(doc) -> dict:
    """The document split by subsection number."""
    out, current = {}, None
    for part in re.split(r"\n(?=\d+\.\d+ )", doc.text):
        m = re.match(r"(\d+\.\d+) ", part)
        if m:
            current = m.group(1)
            out[current] = part
        elif current:
            out[current] += part
    return out


def numeric_sentences(body: str) -> list[tuple[str, set]]:
    out = []
    for sentence in re.split(r"(?<=[.!?])\s+|\n\|", body):
        sentence = sentence.strip().lstrip("| ").strip()
        if not re.search(r"\d", sentence):
            continue
        if not MIN_LEN <= len(sentence) <= MAX_LEN:
            continue
        words = {w for w in re.findall(r"[a-z]{3,}", sentence.lower())
                 if w not in STOP}
        if len(words) >= SHARED_WORDS:
            out.append((sentence, words))
    return out


def restatements(doc) -> list[dict]:
    rows = [(sec, s, w) for sec, body in sections(doc).items()
            for s, w in numeric_sentences(body)]
    out = []
    for (s1, t1, w1), (s2, t2, w2) in itertools.combinations(rows, 2):
        if s1 == s2:
            continue
        shared = w1 & w2
        if len(shared) < SHARED_WORDS:
            continue
        if len(shared) / len(w1 | w2) < OVERLAP:
            continue
        a, b = sorted((s1, s2))
        out.append(dict(a=a, b=b, first=t1, second=t2))
    return out


def why_exempt(row: dict) -> str | None:
    for prefix, reason in RESTATING.items():
        if row["a"].startswith(prefix) or row["b"].startswith(prefix):
            return reason
    return COVERED.get((row["a"], row["b"]))


def report(doc) -> int:
    rows = restatements(doc)
    live = [r for r in rows if not why_exempt(r)]
    by_pair = collections.Counter((r["a"], r["b"]) for r in live)
    exempt = collections.Counter(why_exempt(r) for r in rows if why_exempt(r))

    print(f"{len(rows)} restated sentences across "
          f"{len({(r['a'], r['b']) for r in rows})} section pairs\n")
    for reason, n in exempt.most_common():
        print(f"  {n:>3} exempt — {reason}")
    print(f"  {len(live):>3} live, in {len(by_pair)} "
          f"pair{'' if len(by_pair) == 1 else 's'}\n")
    for (a, b), n in sorted(by_pair.items(), key=lambda kv: (-kv[1], kv[0])):
        print(f"  §{a} / §{b}" + (f"   {n} sentences" if n > 1 else ""))
        for row in live:
            if (row["a"], row["b"]) == (a, b):
                print(f"      {row['first'][:96]}")
                print(f"      {row['second'][:96]}")
                break
    print("\n  Not a failure: a restatement is a second home, and a second home "
          "is only\n  a fault when the two disagree or when one is edited "
          "alone. This is the list\n  of places where that can happen without "
          "anything noticing.")
    return 0


def self_test() -> int:
    """The scan has to find a planted restatement and ignore a coincidence."""
    ok = True
    doc = check_document.Doc(check_document.DEFAULT_DOC)
    base = {(r["a"], r["b"], r["first"]) for r in restatements(doc)}

    def check(name, got, want):
        nonlocal ok
        good = got == want
        ok = ok and good
        print(f"  [{'ok ' if good else 'FAIL'}] {name}"
              f"{'' if good else f'  got {got!r}, want {want!r}'}")

    check("the document's own restatements are found", len(base) > 40, True)
    # A sentence repeated in another section must pair; two sentences that
    # merely share a unit must not.
    a = "The crew loads 30 units a second and fills its bags in ten seconds."
    b = "A crew loads 30 units a second, filling its bags in about ten seconds."
    c = "A guard turns 6 degrees a tick and holds its post for ten seconds."
    rows = [("1.1", a, set()), ("2.2", b, set()), ("3.3", c, set())]
    rows = [(s, t, {w for w in re.findall(r"[a-z]{3,}", t.lower())
                    if w not in STOP}) for s, t, _ in rows]
    def pairs(rows):
        out = []
        for (s1, t1, w1), (s2, t2, w2) in itertools.combinations(rows, 2):
            shared = w1 & w2
            if len(shared) >= SHARED_WORDS and len(shared) / len(w1 | w2) >= OVERLAP:
                out.append((s1, s2))
        return out
    check("a restated sentence pairs", ("1.1", "2.2") in pairs(rows), True)
    check("two sentences sharing only a unit do not",
          [p for p in pairs(rows) if "3.3" in p], [])
    # Every exemption must still match something, or it is a rule nobody needs
    # that will quietly widen.
    used = {why_exempt(r) for r in restatements(doc)} - {None}
    check("every exemption is doing work",
          sorted(used), sorted(set(RESTATING.values()) | set(COVERED.values())))
    return 0 if ok else 1


def main() -> int:
    ap = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    ap.add_argument("--self-test", action="store_true")
    args = ap.parse_args()
    if args.self_test:
        return self_test()
    return report(check_document.Doc(check_document.DEFAULT_DOC))


if __name__ == "__main__":
    sys.exit(main())
