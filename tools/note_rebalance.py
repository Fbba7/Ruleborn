#!/usr/bin/env python3
"""The note rebalance §8.8 states in the past tense and has not happened.

    python3 tools/note_rebalance.py

§8.8, added in v3.0:

    "The same count also rebalanced the notes themselves: Glow was carried by
     twelve laws and its opposite Hush by six... The table now runs eight or
     nine laws per note, and since the note count is frozen at eight and laws
     are the expansion axis (24), that balance is a permanent constraint on
     every future season rather than a one-time tidy."

Parsing all 48 law sheets gives Glow 12, Flow 11, Echo 10, Weight 9, Spark 8,
Bloom 8, Veil 7, Hush 6 — identical to v2.3. The paragraph is correct about why
it matters and wrong about it being done. That is C25.

This is the change it describes, written out law by law. Nine edits reach nine
laws for every note, and each one is argued from §8.1's own definition of the
note rather than chosen to make the arithmetic work — because a rebalance that
puts Hush on a law that makes noise has fixed a table and broken the system the
table is for.

Nothing here is applied to `content/laws.json`. The content files are extracted
from the document and must keep saying what the document says; this is a
proposal for the document.
"""

import collections
import itertools
import json
import pathlib
import sys

ROOT = pathlib.Path(__file__).resolve().parent.parent
CONTENT = ROOT / "content"

#: §8.1. A law may not carry two opposite notes, and a chord needs three
#: different notes none of which are opposites (§8.5).
OPPOSITE = {"Flow": "Weight", "Weight": "Flow", "Glow": "Hush", "Hush": "Glow",
            "Bloom": "Spark", "Spark": "Bloom", "Echo": "Veil", "Veil": "Echo"}

#: §8.1's own words for what each note means. Every edit below cites one.
MEANS = {
    "Flow": "change how things move: speed, direction, jumping, sliding",
    "Weight": "slow, pull, hold and weigh down",
    "Glow": "light, reveal and show",
    "Hush": "hide, silence and still",
    "Bloom": "grow, heal and multiply",
    "Spark": "burst, stun, break and surge",
    "Echo": "return, repeat and rewind",
    "Veil": "disguise, deceive and transform",
}

#: law id -> (drop, add, why). `drop` or `add` may be None for a law that loses
#: or gains a note rather than trading one.
EDITS = {
    # -- Glow -3 ----------------------------------------------------------
    "flock": ("Glow", "Veil",
              "Six puffballs that wander, block narrow paths and make guards "
              "react to them are deception. Nothing about Flock lights up."),
    "crystal_growth": ("Glow", "Veil",
                       "Stone regrowing as crystal is a transformation, which is "
                       "Veil\u2019s own word. The clarity is a consequence of the "
                       "material, not the effect of the law."),
    "leapfrog": ("Glow", "Spark",
                 "Nothing in Leapfrog lights up either. Its second clause is a "
                 "noisy landing \u2014 \u201cguards within 4 tiles notice 25% "
                 "faster\u201d \u2014 and an impact is a burst."),

    # -- Flow -2 ----------------------------------------------------------
    "soul_swap": ("Flow", "Hush",
                  "The swap is a disappearance at the instant of a knockout, not "
                  "a change to how anyone moves. Hush is hide and still."),
    "aurora": ("Flow", None,
               "Aurora moves nothing. Flow is \u201cchange how things move: "
               "speed, direction, jumping, sliding\u201d and this law changes "
               "only what can be seen. It cannot take Hush instead \u2014 that is "
               "Glow\u2019s opposite \u2014 so it becomes a one-note Glow law, "
               "which 25 of the 48 already are."),

    # -- Echo -1 ----------------------------------------------------------
    "lodestones": ("Echo", None,
                   "Nothing in Lodestones returns, repeats or rewinds. It is "
                   "entirely a pull, which is Weight."),

    # -- the three additions ----------------------------------------------
    "day_and_night": (None, "Hush",
                      "The light-and-dark law carries neither Glow nor Hush. "
                      "\u201cVision halves in the dark\u201d is Hush exactly, and "
                      "Echo stays for the cycle."),
    "honeycomb": (None, "Hush",
                  "Sticky ground makes everyone slower and quieter; \u00a712.17\u2019s "
                  "own noise table has moss quieter and gravel and water louder, "
                  "which is why Slow rivers is not the candidate here. The "
                  "weakest of the nine, and the one to drop first if eight will "
                  "do."),
    "rewind": (None, "Bloom",
               "Restoring broken things is healing as much as it is repeating. "
               "Echo stays, because the law is the rewind."),
}


def load() -> list:
    return json.loads((CONTENT / "laws.json").read_text(encoding="utf-8"))


def apply_edits(laws: list) -> list:
    """C25. The note rebalance §8.8 states in the past tense, applied.

    §8.8 says the table "now runs eight or nine laws per note". The 48 sheets
    give 12, 11, 10, 9, 8, 8, 7, 6 — identical to v2.3. This is the change it
    describes, law by law, and the check is that applying it reaches the count
    §8.8 claims without leaving a chord unreachable.
    """
    out = []
    for law in laws:
        notes = list(law["notes"])
        drop, add, _ = EDITS.get(law["id"], (None, None, None))
        if drop:
            if drop not in notes:
                raise SystemExit(f"{law['id']}: cannot drop {drop}; it carries {notes}")
            notes.remove(drop)
        if add:
            if add in notes:
                raise SystemExit(f"{law['id']}: already carries {add}")
            notes.append(add)
        if any(OPPOSITE[a] == b for a, b in itertools.combinations(notes, 2)):
            raise SystemExit(f"{law['id']}: would carry opposite notes {notes}")
        if not notes:
            raise SystemExit(f"{law['id']}: would carry no notes")
        out.append({**law, "notes": notes})
    return out


def pools(laws: list) -> dict:
    counts = collections.Counter(n for law in laws for n in law["notes"])
    return {n: counts.get(n, 0) for n in MEANS}


def chord_cost(laws: list, chords: list) -> dict:
    """The cheapest three distinct laws that form each chord (§8.5, v3.0)."""
    out = {}
    for chord in chords:
        notes = set(chord["notes"])
        banned = {OPPOSITE[n] for n in notes}
        pool = [law for law in laws
                if set(law["notes"]) & notes and not set(law["notes"]) & banned]
        best = None
        for combo in itertools.combinations(pool, 3):
            if notes <= set().union(*(set(x["notes"]) for x in combo)):
                cost = sum(x["stability_cost"] for x in combo)
                best = cost if best is None else min(best, cost)
        out[chord["name"]] = best
    return out


def main() -> int:
    laws = load()
    chords = json.loads((CONTENT / "chords.json").read_text(encoding="utf-8"))
    before, after = pools(laws), pools(apply_edits(laws))
    fixed = apply_edits(laws)

    print("The note rebalance §8.8 describes, written out\n")
    print(f"  {'note':<8} {'now':>4} {'after':>6}   {'means (§8.1)'}")
    for note in sorted(MEANS, key=lambda n: -before[n]):
        print(f"  {note:<8} {before[note]:>4} {after[note]:>6}   {MEANS[note]}")
    balanced = set(after.values())
    print(f"\n  after: {sorted(balanced)} laws per note "
          f"— {'balanced' if balanced <= {8, 9} else 'NOT balanced'}")
    print(f"  §8.8 asks for eight or nine each. Note-slots "
          f"{sum(before.values())} → {sum(after.values())} across {len(laws)} laws.\n")

    print(f"The {len(EDITS)} edits, each argued from §8.1's own definition:\n")
    for law in laws:
        if law["id"] not in EDITS:
            continue
        drop, add, why = EDITS[law["id"]]
        move = (f"{drop} → {add}" if drop and add
                else f"drop {drop}" if drop else f"add {add}")
        print(f"  {law['name']:<16} {'+'.join(law['notes']):<13} {move}")
        print(f"                   {why}\n")

    # Two properties the rebalance must not break.
    print("What it does to chords (§8.5, three distinct laws since v3.0):\n")
    old_cost, new_cost = chord_cost(laws, chords), chord_cost(fixed, chords)
    unreachable = [n for n, c in new_cost.items() if c is None]
    print(f"  {'chord':<18} {'now':>5} {'after':>7}")
    for chord in chords:
        name = chord["name"]
        a = old_cost[name] or 0
        b = new_cost[name]
        print(f"  {name:<18} {a:>5} {b if b is not None else 'unreachable':>7}")
    print()
    if unreachable:
        print(f"  {len(unreachable)} chord(s) become unreachable: {unreachable}")
        print("  That would be a worse problem than the imbalance. Rework the edits.")
    else:
        cheap_before = min(c for c in old_cost.values() if c)
        cheap_after = min(c for c in new_cost.values() if c)
        print(f"  Every chord stays reachable. The cheapest costs {cheap_before} "
              f"stability now and {cheap_after} after,")
        print(f"  against a day-2 capacity of 51 — so this does not fix D14, "
              f"which is a gating")
        print("  question rather than a distribution one.")
    return 1 if unreachable or balanced - {8, 9} else 0


if __name__ == "__main__":
    raise SystemExit(main())
