#!/usr/bin/env python3
"""Validate the extracted content tables.

    python3 tools/validate_content.py

§24.9 asks for content validation that "fails the build rather than a player's
device", and for property tests asserting rules that must always hold — resonance
is symmetric, no chord divides by zero, no ordering depends on a hash. This is
that check for the content layer.

It reports two separate things, and only the first fails:

  ERRORS  the data is malformed or self-inconsistent. Always a bug.
  OPEN    a known, tracked contradiction in the design document. Expected until
          it is resolved; each carries the audit register id that tracks it, so
          the list shrinks as the document is reconciled rather than being
          silently tolerated.

Exit code is non-zero only for ERRORS.
"""

import collections
import itertools
import json
import pathlib
import sys

ROOT = pathlib.Path(__file__).resolve().parent.parent
CONTENT = ROOT / "content"

NOTES = ["Flow", "Weight", "Glow", "Hush", "Bloom", "Spark", "Echo", "Veil"]
OPPOSITE = {"Flow": "Weight", "Weight": "Flow", "Glow": "Hush", "Hush": "Glow",
            "Bloom": "Spark", "Spark": "Bloom", "Echo": "Veil", "Veil": "Echo"}
SCHOOLS = ["Motion", "Matter", "Time", "Energy", "Life", "Spirit"]
ROLES = ["Scout", "Breaker", "Carrier", "Warden", "Mender"]

#: §26.1's launch content table. A count that drifts from this is a real error.
EXPECTED = {"notes": 8, "laws": 48, "resonances": 44, "chords": 12,
            "terrain": 39, "ruleborn": 18}

REQUIRED_LAW_FIELDS = ["id", "name", "rank", "school", "stability_cost", "notes",
                       "tier_1", "tiers_2_3", "movement", "world",
                       "raider_use", "defender_use", "weakness", "sound"]

errors: list[str] = []
open_items: list[tuple[str, str]] = []


def err(msg: str) -> None:
    errors.append(msg)


def opn(item_id: str, msg: str) -> None:
    open_items.append((item_id, msg))


def load(name: str) -> list[dict]:
    path = CONTENT / f"{name}.json"
    if not path.exists():
        err(f"{name}.json is missing — run tools/extract_content.py")
        return []
    return json.loads(path.read_text(encoding="utf-8"))


def main() -> int:
    data = {name: load(name) for name in EXPECTED}
    if errors:
        report()
        return 1

    laws, notes = data["laws"], data["notes"]
    by_id = {law["id"]: law for law in laws}

    # -- counts ------------------------------------------------------------
    for name, want in EXPECTED.items():
        got = len(data[name])
        if got != want:
            err(f"{name}: {got} entries, §26.1 says {want}")

    # -- notes -------------------------------------------------------------
    note_names = [n["name"] for n in notes]
    if sorted(note_names) != sorted(NOTES):
        err(f"notes are {note_names}, expected {NOTES}")
    for n in notes:
        if OPPOSITE.get(n["name"]) != n["opposite"]:
            err(f"note {n['name']}: opposite is {n['opposite']}, "
                f"expected {OPPOSITE.get(n['name'])}")
        back = next((m for m in notes if m["name"] == n["opposite"]), None)
        if back and back["opposite"] != n["name"]:
            err(f"opposition is not symmetric: {n['name']} <-> {n['opposite']}")

    # -- laws --------------------------------------------------------------
    ids = [law["id"] for law in laws]
    for dup, count in collections.Counter(ids).items():
        if count > 1:
            err(f"duplicate law id {dup!r} ({count} times)")
    for law in laws:
        missing = [f for f in REQUIRED_LAW_FIELDS if f not in law]
        if missing:
            err(f"law {law.get('name', '?')}: missing {missing}")
        if law["school"] not in SCHOOLS:
            err(f"law {law['name']}: unknown school {law['school']}")
        if not 1 <= len(law["notes"]) <= 2:
            err(f"law {law['name']}: carries {len(law['notes'])} notes, expected 1 or 2")
        for note in law["notes"]:
            if note not in NOTES:
                err(f"law {law['name']}: unknown note {note!r}")
        # A law carrying a note and its own opposite would be internally dissonant.
        if len(law["notes"]) == 2 and OPPOSITE.get(law["notes"][0]) == law["notes"][1]:
            err(f"law {law['name']}: carries a note and its opposite")
        if not 1 <= law["stability_cost"] <= 60:
            err(f"law {law['name']}: stability cost {law['stability_cost']} out of range")

    per_school = collections.Counter(law["school"] for law in laws)
    if set(per_school.values()) != {8}:
        err(f"laws per school: {dict(per_school)}, expected 8 each")

    # -- resonances --------------------------------------------------------
    seen_pairs = {}
    for r in data["resonances"]:
        if len(r["laws"]) != 2:
            err(f"resonance {r['name']}: references {len(r['laws'])} laws, expected 2")
            continue
        for lid, lname in zip(r["laws"], r["law_names"]):
            if lid not in by_id:
                err(f"resonance {r['name']}: unknown law {lname!r}")
        if r["laws"][0] == r["laws"][1]:
            err(f"resonance {r['name']}: pairs a law with itself")
        # Resonance is symmetric: one pair, one resonance.
        key = tuple(sorted(r["laws"]))
        if key in seen_pairs:
            err(f"resonance {r['name']}: same law pair as {seen_pairs[key]}")
        seen_pairs[key] = r["name"]
        # Declared shared notes must actually be shared.
        if all(lid in by_id for lid in r["laws"]):
            actual = set(by_id[r["laws"][0]]["notes"]) & set(by_id[r["laws"][1]]["notes"])
            declared = set(r["shared_notes"])
            if declared != actual:
                err(f"resonance {r['name']}: declares shared notes {sorted(declared) or '—'}, "
                    f"but the laws share {sorted(actual) or '—'}")

    # -- chords ------------------------------------------------------------
    for c in data["chords"]:
        if len(c["notes"]) != 3:
            err(f"chord {c['name']}: {len(c['notes'])} notes, expected 3")
        if len(set(c["notes"])) != len(c["notes"]):
            err(f"chord {c['name']}: repeats a note")
        for a, b in itertools.combinations(c["notes"], 2):
            if OPPOSITE.get(a) == b:
                err(f"chord {c['name']}: contains the opposite pair {a}/{b}")

    # -- terrain -----------------------------------------------------------
    unlock_levels = {1, 3, 6, 10, 15, 21}
    for t in data["terrain"]:
        if t["keeper_level"] not in unlock_levels:
            err(f"terrain {t['name']}: unlocks at Keeper level {t['keeper_level']}, "
                f"not one of {sorted(unlock_levels)}")
    #: §6.3's own unlock table.
    expected_unlocks = {1: 14, 3: 5, 6: 6, 10: 5, 15: 5, 21: 4}
    actual_unlocks = collections.Counter(t["keeper_level"] for t in data["terrain"])
    if dict(actual_unlocks) != expected_unlocks:
        err(f"terrain unlocks per Keeper level: {dict(sorted(actual_unlocks.items()))}, "
            f"§6.3 says {expected_unlocks}")

    # -- ruleborn ----------------------------------------------------------
    rb_schools = collections.Counter(r["school"] for r in data["ruleborn"])
    if set(rb_schools.values()) != {3}:
        err(f"ruleborn per school: {dict(rb_schools)}, expected 3 each")
    for r in data["ruleborn"]:
        if r["role"] not in ROLES:
            err(f"ruleborn {r['name']}: unknown role {r['role']}")

    # =====================================================================
    # Known open contradictions — reported, not failed
    # =====================================================================

    ranks = collections.Counter(law["rank"] for law in laws)
    if "Uncommon" not in ranks:
        opn("C3", f"law ranks are {dict(ranks)} — §7.10 and §27.2 describe five "
                  f"ranks including 14 Uncommon, but no law is tagged Uncommon")

    pools = collections.Counter()
    for law in laws:
        for note in law["notes"]:
            pools[note] += 1
    two_note = sum(1 for law in laws if len(law["notes"]) == 2)
    reachable_with_two = 0
    for c in data["chords"]:
        banned = {OPPOSITE[n] for n in c["notes"]}
        pool = [law for law in laws
                if set(law["notes"]) & set(c["notes"]) and not set(law["notes"]) & banned]
        if any(set(c["notes"]) <= set(a["notes"]) | set(b["notes"])
               for a, b in itertools.combinations(pool, 2)):
            reachable_with_two += 1
    if reachable_with_two:
        opn("D14", f"{reachable_with_two} of {len(data['chords'])} chords are reachable "
                   f"with two laws, not the three §8.5 describes "
                   f"({two_note} of {len(laws)} laws carry two notes)")

    sounds = collections.Counter(law["sound"] for law in laws)
    if len(sounds) < len(laws):
        per_school = all(
            len({law["school"] for law in laws if law["sound"] == snd}) == 1
            for snd in sounds)
        opn("C20", f"48 laws share {len(sounds)} sound signatures"
                   f"{' — one per school' if per_school else ''}, but §21.8 says "
                   f"\"every law also has a sound signature, so a player can hear "
                   f"which rules are running\"")

    # The chord layer demands the notes evenly; the law layer does not supply them
    # evenly. Stating D13 this way is sharper than the raw pool imbalance.
    demand = collections.Counter(n for c in data["chords"] for n in c["notes"])
    if demand:
        ratio = {n: round(pools[n] / demand[n], 1) for n in NOTES if demand[n]}
        spread = max(ratio.values()) - min(ratio.values())
        worst = max(OPPOSITE.items(), key=lambda kv: abs(pools[kv[0]] - pools[kv[1]]))
        if spread > 1.0:
            opn("D13", f"{worst[0]} {pools[worst[0]]} laws against its opposite "
                f"{worst[1]} {pools[worst[1]]} — chords demand the notes evenly (" +
                ", ".join(f"{n} {demand[n]}" for n in NOTES) +
                ") but the law pool does not supply them evenly (" +
                ", ".join(f"{n} {pools[n]}" for n in NOTES) + ")")

    role_conflicts = [r["name"] for r in data["ruleborn"]
                      if r.get("conflict_severity") == "role"]
    wording = sum(1 for r in data["ruleborn"] if r.get("conflict_severity") == "wording")
    if role_conflicts:
        opn("C6", f"§11.2 and §11.11 give different roles for {', '.join(role_conflicts)}; "
                  f"{wording} more differ on ability wording")

    report()
    return 1 if errors else 0


def report() -> None:
    print()
    if errors:
        print(f"ERRORS  {len(errors)} — the data is malformed; fix before use\n")
        for e in errors:
            print(f"  ✗ {e}")
        print()
    else:
        print("ERRORS  none — every table is well formed and internally consistent\n")

    if open_items:
        print(f"OPEN    {len(open_items)} known contradictions in the design document")
        print("        (tracked in the audit register; expected until resolved)\n")
        for item_id, msg in open_items:
            print(f"  [{item_id}] {msg}")
        print()


if __name__ == "__main__":
    raise SystemExit(main())
