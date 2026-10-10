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
import re
import sys

ROOT = pathlib.Path(__file__).resolve().parent.parent
sys.path.insert(0, str(ROOT / "tools"))
from design_doc import TEXT as DOC_TEXT                              # noqa: E402
CONTENT = ROOT / "content"

NOTES = ["Flow", "Weight", "Glow", "Hush", "Bloom", "Spark", "Echo", "Veil"]
OPPOSITE = {"Flow": "Weight", "Weight": "Flow", "Glow": "Hush", "Hush": "Glow",
            "Bloom": "Spark", "Spark": "Bloom", "Echo": "Veil", "Veil": "Echo"}
SCHOOLS = ["Motion", "Matter", "Time", "Energy", "Life", "Spirit"]
ROLES = ["Scout", "Breaker", "Carrier", "Warden", "Mender"]

#: §26.1's launch content table. A count that drifts from this is a real error,
#: except where the drift is itself a tracked contradiction — see BUILDINGS below.
EXPECTED = {"notes": 8, "laws": 48, "resonances": 44, "chords": 12,
            "terrain": 39, "ruleborn": 18, "roles": 5,
            "wards": 6, "sages": 4, "eras": 8}

#: 26.1's launch table, read rather than copied.
#:
#: Two of its rows were carried here as constants — 16 building types and 30
#: traits — which were true of v3.0. v3.1 recounted both from the tables they
#: summarise and made them 17 and 31, and this file went on reporting C8's
#: count and C10 against a document that had answered them. A hand-written
#: copy of a number the document states is the fault this repository exists
#: to record, so the whole table is read and the rows are looked up by name.
LAUNCH_ROWS = {
    "laws": "Laws", "resonances": "Signature resonances and chords",
    "ruleborn": "Ruleborn", "traits": "Traits", "sages": "Sages",
    "eras": "Eras", "buildings": "Building types",
    "terrain": "Terrain features",
}


def launch_table() -> dict[str, int]:
    """What 26.1 claims the launch content is, by row name."""
    doc = DOC_TEXT
    if not doc.exists():
        return {}
    block = re.search(r"^26\.1 .*?(?=^26\.2 )", doc.read_text(encoding="utf-8"),
                      re.S | re.M)
    if not block:
        return {}
    rows = dict(re.findall(r"^\| ([A-Za-z][^\n|]*)\n\| ([\d,]+)", block.group(0), re.M))
    out = {}
    for key, label in LAUNCH_ROWS.items():
        if label in rows:
            out[key] = int(rows[label].replace(",", ""))
    return out

#: A day-2 player's stability capacity, from the economy model. Used to ask
#: whether a "late-game discovery" is actually gated.
DAY_2_STABILITY = 51

#: The old names v2.3 replaced (§26.9). A surviving reference is a stale rename.
RETIRED_NAMES = ["Echo Knight", "Moss Giant", "Masquerade", "Creator Fund", "Lawbound"]

REQUIRED_LAW_FIELDS = ["id", "name", "rank", "school", "stability_cost", "notes",
                       "tier_1", "tiers_2_3", "movement", "world",
                       "raider_use", "defender_use", "weakness", "sound"]

errors: list[str] = []
open_items: list[tuple[str, str]] = []


#: Where each content file's values come from, as (first heading, next
#: heading) pairs in the design document. A file may have more than one source:
#: `ruleborn.json` carries \u00a711.11's bible and the columns \u00a711.2 adds,
#: and `buildings.json` carries \u00a710.2's table plus the Library, which
#: \u00a710.4 specifies instead \u2014 and being outside \u00a710.2 is C8.
EXTRACTED_FROM = {
    "laws":       [("7.7 Every law in full", "7.8 ")],
    "ruleborn":   [("11.11 The character bible", "12Heists"),
                   ("11.2 The 18 ruleborn", "11.3 "),
                   ("21.6 Characters", "21.7 ")],
    "terrain":    [("6.2 The 39 features", "6.3 ")],
    "notes":      [("8.1 The eight notes", "8.2 ")],
    "resonances": [("8.4 Signature resonances", "8.5 ")],
    "chords":     [("8.5 Chords", "8.6 ")],
    "roles":      [("11.1 Roles", "11.2 ")],
    "traits":     [("11.3 Traits", "11.4 ")],
    "buildings":  [("10.2 Every level of every building", "10.3 "),
                   ("10.4 The Library", "11Characters")],
    "wards":      [("10.3 Wards", "10.4 ")],
    "eras":       [("18.3 Eras", "18.4 ")],
    "sages":      [("11.7 Sages, the heroes", "11.8 ")],
    "visitors":   [("11.8 Special characters", "11.9 ")],
    "paradox_born": [("11.8 Special characters", "11.9 ")],
    "forms":      [("11.10 Law-shaped forms", "11.11 "),
                   ("11.11 The character bible", "12Heists")],
}

#: Keys the extractor *adds* rather than reads. These are this repository's
#: annotations on the document's content \u2014 which register item a row waits
#: on, what the document does not state about it \u2014 so they have no
#: provenance in the document by design.
ANNOTATIONS = {"id", "source", "needs_decision", "conflict_severity",
               "missing", "note", "_source", "_status", "_note", "_tick_rate"}


def check_provenance() -> list[str]:
    """D42. Every extracted value must be inside the section it was read from.

    D41 was a law sheet whose block ran to the end of the document, so the
    extractor re-paired every table after it and a column heading from
    \u00a721.7 landed in \u00a77.7's content. The bug was in the bounding, and
    nothing in this file could see it: it checked that every required field was
    *present*, never that a value came from where it claims to.

    This is the general guard for that class, and it is independent of how the
    extractor pairs cells \u2014 which is the part that keeps going wrong.
    `fields()` and `table()` both zip by position, so one stray cell shifts
    every row after it, and a shifted value almost always comes from outside
    its own section.

    It is not the whole net. D41's actual bad value was the *label* "How
    characters move", which does appear inside \u00a77.7 \u2014 that one is
    caught by the label check above. A value pulled from a neighbouring section
    is caught here. The two overlap in neither direction, which is why both
    exist.
    """
    doc = DOC_TEXT.read_text(encoding="utf-8")
    out = []
    for name, sources in EXTRACTED_FROM.items():
        path = CONTENT / f"{name}.json"
        if not path.exists():
            continue
        spans = []
        for first, nxt in sources:
            try:
                start = doc.index("\n" + first)
                spans.append(doc[start:doc.index("\n" + nxt, start)])
            except ValueError:
                out.append(f"{name}: the document has no section "
                           f"\u201c{first}\u201d to read it from")
        if not spans:
            continue
        rows = json.loads(path.read_text(encoding="utf-8"))
        for row in (rows if isinstance(rows, list) else [rows]):
            if not isinstance(row, dict):
                continue
            for key, value in row.items():
                if key in ANNOTATIONS or not isinstance(value, str):
                    continue
                if value.strip() and not any(value.strip() in s for s in spans):
                    out.append(
                        f"{name}: {row.get('name', row.get('id', '?'))}.{key} "
                        f"is \u201c{value.strip()[:44]}\u201d, which is not in "
                        f"{' or '.join(a for a, _ in sources)}")
    return out


def err(msg: str) -> None:
    errors.append(msg)


def opn(item_id: str, msg: str) -> None:
    open_items.append((item_id, msg))


#: Numbers a closed register item states, checked against the data on every
#: build. A closed item's note is prose nobody re-derives, so a number inside
#: one is exactly the kind that goes quietly wrong.
pinned: list[tuple[str, str, object, object]] = []


def pin(item_id: str, what: str, got, expected) -> None:
    pinned.append((item_id, what, got, expected))


def register_says_open(item_id: str) -> bool:
    """Whether the audit register still has this item open.

    `check_document.py` owns this question and this imports its answer rather
    than working it out again, because two implementations of "is it open" is
    the fault the whole register exists to record.
    """
    import check_document
    return check_document._is_open(item_id)


def stale_reports() -> list[tuple[str, str]]:
    """Reports about items the register says are closed.

    This file reported G12 on every build for as long as it read v3.0, and
    would have gone on reporting it after v3.1 answered it \u2014 the register
    had G12 closed, and nothing compared the two. That is C21 to C24 exactly:
    a fix that landed in one place and a copy that nobody retired.

    `check_document.py` has the four-state verdict for the same reason; this
    is the third of its four states, the one that says the checker is now the
    thing that is out of date.
    """
    return [(i, m) for i, m in open_items if not register_says_open(i)]


def _doc_declares_attributes() -> bool:
    """C26. Whether the design document claims size and flight are stated properties.

    C26 was that §12.21 declared size and flight as properties of every
    ruleborn and no table carried them. v3.1 put them in §11.2, and this is
    the sentence that says so — the content reader keys off it, so if the
    declaration ever leaves the document the tables stop claiming the fields.
    """
    doc = DOC_TEXT
    if not doc.exists():
        return False
    text = doc.read_text(encoding="utf-8")
    return "Size is a band on every ruleborn" in text


def load(name: str) -> list[dict]:
    path = CONTENT / f"{name}.json"
    if not path.exists():
        err(f"{name}.json is missing — run tools/extract_content.py")
        return []
    return json.loads(path.read_text(encoding="utf-8"))


def check_specials(visitors, paradox, ruleborn, roles, forms, sages) -> list[str]:
    """§11.8 and the cards, as v3.7 settles them (G62, C53, G63, G52).

    No nineteenth kind: the Stray is one of the eighteen, so there are still
    eighteen ruleborn and 54 forms, and no paradox-born has a form. None is
    better than any role in every number (§11.8: "none is better than any
    role in every number"). The Twinned's health and carry are one body's
    pools. Every card carries §11.11's rule sheet and §21.6's body, height,
    colours and signature, and every Sage what it gains at each fifth level.
    """
    out = []
    if len(ruleborn) != 18 or len(forms) != 54:
        out.append(f"{len(ruleborn)} ruleborn and {len(forms)} forms: §11.8's Stray adds no kind")
    if len(visitors) != 3:
        out.append(f"visitors: {len(visitors)}, §11.8 lists 3")
    stray = [v for v in visitors if v["id"] == "stray"]
    if not stray or stray[0].get("kind") != "one of the eighteen":
        out.append("the Stray is not marked as one of the eighteen kinds")
    if len(paradox) != 3:
        out.append(f"paradox-born: {len(paradox)}, §11.8 lists 3")
    for p in paradox:
        if p.get("forms"):
            out.append(f"{p['name']}: has forms; paradox-born hatch without one (G62)")
        for r in roles:
            if (p["health"] >= r["health"] and p["speed"] >= r["speed"]
                    and p["power"] >= r["power"] and p["carry"] >= r["carry"]):
                out.append(f"{p['name']}: as good as a {r['name']} in every number, which "
                           f"§11.8 rules out")
    twinned = [p for p in paradox if p["id"] == "twinned"]
    if not twinned or not twinned[0].get("shared_pools"):
        out.append("the Twinned's health and carry are not one body's shared pools (C53)")
    for k in ruleborn:
        missing = [f for f in ("rule_sheet", "body", "height_m", "colours", "signature")
                   if not k.get(f)]
        if missing:
            out.append(f"{k['name']}: no {', '.join(missing)} (§11.11, §21.6)")
    for s in sages:
        if len(s.get("levels", {})) != 8:
            out.append(f"{s['name']}: what it gains at levels 5 to 40 is not all there (§11.7)")
    return out


def check_chapters(laws, text: str) -> list[str]:
    """§7.6: the Codex holds the launch 24, "12 findable from the start and
    all 24 from Keeper level 6. Chapter 1’s twelve are two of each school …
    the three starting laws among them." """
    out = []
    one = [l for l in laws if l.get("chapter") == 1]
    two = [l for l in laws if l.get("chapter") == 2]
    if len(one) != 12 or len(two) != 12:
        out.append(f"chapters: {len(one)} in chapter 1 and {len(two)} in chapter 2, §7.6 says 12 and 12")
    if any(not l.get("launch") for l in one + two):
        out.append("a law after launch is in chapter 1 or 2")
    schools = collections.Counter(l["school"] for l in one)
    if any(n != 2 for n in schools.values()) or len(schools) != 6:
        out.append(f"chapter 1 is not two of each school: {dict(schools)}")
    m = re.search(r"Starting laws: ([^.]+)", text)
    starting = [n.strip() for n in re.split(r",| and ", m.group(1).split(", all at")[0])
                if n.strip()] if m else []
    named = {l["name"] for l in one}
    for n in starting:
        if n not in named:
            out.append(f"starting law {n} is not in chapter 1")
    if not starting:
        out.append("§7.6's starting laws not found")
    return out


def check_forms(forms, ruleborn, laws, chords, note_names) -> list[str]:
    """§11.10: "Eighteen kinds and three notes make 54 forms. The three notes
    are the same for every kind: Hush, Spark and Echo, the three most carried
    by the 24 laws that ship at launch … Ties go to the note that completes
    more chords … and then to alphabetical order." Every clause recomputed."""
    out = []
    constants = json.loads((CONTENT / "upstream" / "constants.json").read_text(encoding="utf-8"))
    want = int(constants["law_shaped_forms"]["value"])
    if len(forms) != want:
        out.append(f"forms: {len(forms)} entries, §11.10 says {want}")
    kinds = {r["name"] for r in ruleborn}
    form_notes = sorted({f["note"] for f in forms})
    pairs = collections.Counter((f["kind"], f["note"]) for f in forms)
    for (kind, note), n in pairs.items():
        if n > 1:
            out.append(f"forms: {kind} in {note} appears {n} times")
        if kind not in kinds:
            out.append(f"forms: {kind} is not one of §11.11's eighteen kinds")
    if len(pairs) != len(kinds) * len(form_notes):
        out.append(f"forms: {len(pairs)} kind-and-note pairs, not every kind in every "
                   f"note ({len(kinds)} × {len(form_notes)})")
    carried = collections.Counter(n for law in laws if law.get("launch") for n in law["notes"])
    in_chords = collections.Counter(n for c in chords for n in c["notes"])
    ranked = sorted(carried, key=lambda n: (-carried[n], -in_chords[n], n))
    if form_notes != sorted(ranked[:len(form_notes)]):
        out.append(f"forms: the notes are {form_notes}; the launch laws' most carried, "
                   f"ties to chords then the alphabet, are {ranked[:len(form_notes)]}")
    out += [f"forms: {n} is not one of §8.1's notes" for n in form_notes
            if n not in note_names]
    return out


def main() -> int:
    data = {name: load(name) for name in list(EXPECTED) + ["traits", "buildings", "forms"]}
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

    # -- a value that is really a label -------------------------------------
    # D41. `extract_content.fields()` pairs a table's cells by position, so a
    # block that runs past its own section re-pairs every table after it and
    # the last matching label wins. Mirror images is the last law sheet, its
    # block ran to the end of the document, and §21.7's column header "How the
    # realm looks" overwrote its `world` with the *label* "How characters
    # move". One field of one law, wrong in the content every tool reads, and
    # nothing looked.
    #
    # The shape is general and the check is cheap: an extracted value must
    # never be one of the labels the extractor keys on.
    import extract_content
    labels = set(extract_content.FIELD_MAP) | set(extract_content.FIELD_MAP.values())
    for name, rows in data.items():
        for row in rows if isinstance(rows, list) else [rows]:
            if not isinstance(row, dict):
                continue
            for key, value in row.items():
                if isinstance(value, str) and value.strip() in labels:
                    err(f"{name}: {row.get('name', row.get('id', '?'))}.{key} "
                        f"is {value!r}, which is a field label rather than a "
                        f"value \u2014 the extractor mis-paired a table")

    for problem in check_provenance():
        err(problem)

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

    # -- forms (§11.10) ------------------------------------------------------
    for problem in check_forms(data["forms"], data["ruleborn"], laws, data["chords"],
                               note_names):
        err(problem)

    # -- the Codex's chapters (§7.6, G49) -----------------------------------
    for problem in check_chapters(data["laws"], DOC_TEXT.read_text(encoding="utf-8")):
        err(problem)

    # -- special characters (§11.8) and the cards (§11.11, §21.6), TD.33 ---
    for problem in check_specials(load("visitors"), load("paradox_born"), data["ruleborn"],
                                  load("roles"), data["forms"], data["sages"]):
        err(problem)

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

    # -- roles, buildings, wards, sages, eras -------------------------------
    role_names = {r["name"] for r in data["roles"]}
    if role_names != set(ROLES):
        err(f"roles are {sorted(role_names)}, expected {ROLES}")
    for r in data["roles"]:
        if not 1 <= r["speed"] <= 10:
            err(f"role {r['name']}: speed {r['speed']} out of range")

    for b in data["buildings"]:
        levels = [lvl["level"] for lvl in b["levels"]]
        if levels != list(range(1, len(levels) + 1)):
            if b.get("needs_decision"):
                opn(b["needs_decision"],
                    f"building {b['name']}: \u00a710.4 states levels {levels} only. "
                    f"Every other building lists every level, and the economy model "
                    f"cannot price a faucet with seven levels missing")
            else:
                err(f"building {b['name']}: levels are {levels}, "
                    f"expected 1..{len(levels)}")
        costs = [lvl["cost_starlight"] for lvl in b["levels"]]
        if costs != sorted(costs):
            err(f"building {b['name']}: costs are not monotonically increasing")
        if any(c <= 0 for c in costs):
            err(f"building {b['name']}: a level costs nothing")

    ward_schools = collections.Counter(w["school"] for w in data["wards"])
    if set(ward_schools) != set(SCHOOLS) or set(ward_schools.values()) != {1}:
        err(f"wards by school: {dict(ward_schools)}, expected one per school")

    # -- detection (the reconciled §12.17 spec) -----------------------------
    det = json.loads((CONTENT / "detection.json").read_text(encoding="utf-8")) \
        if (CONTENT / "detection.json").exists() else None
    if det:
        if det["_tick_rate"] != 30:
            err(f"detection: tick rate {det['_tick_rate']}, the §24.10 contract says 30")
        sus = det["suspicion"]
        for zone, seconds in sus["fill_seconds"].items():
            want = round(sus["max"] / (seconds * det["_tick_rate"]))
            got = sus["fill_per_tick"][zone]
            if abs(got - want) > 1:
                err(f"detection: {zone} zone fills at {got}/tick, but "
                    f"{seconds}s at {det['_tick_rate']} Hz needs {want}")
        want_decay = round(sus["max"] / (sus["decay_seconds"] * det["_tick_rate"]))
        if abs(sus["decay_per_tick"] - want_decay) > 1:
            err(f"detection: decay {sus['decay_per_tick']}/tick, "
                f"{sus['decay_seconds']}s needs {want_decay}")
        if sus["decay_per_tick"] >= sus["fill_per_tick"]["far"] * 2:
            err("detection: suspicion drains faster than the far zone fills, "
                "so a distant guard could never reach Suspicious")
        det_roles = {g["role"] for g in det["guards"]}
        if det_roles != set(ROLES):
            err(f"detection: guard roles {sorted(det_roles)}, expected {ROLES}")
        for g in det["guards"]:
            zones = [g["near_m"], g["mid_m"], g["far_m"]]
            present = [z for z in zones if z is not None]
            if present != sorted(present):
                err(f"detection: {g['role']} zone boundaries are not increasing: {zones}")
            if not 0 < g["cone_degrees"] <= g["peripheral_degrees"] <= 360:
                err(f"detection: {g['role']} cone {g['cone_degrees']}° is not inside "
                    f"its peripheral arc {g['peripheral_degrees']}°")
        thresholds = [s["at"] for s in det["states"] if s["at"] is not None]
        if thresholds != sorted(thresholds):
            err(f"detection: state thresholds are not ordered: {thresholds}")
        if thresholds[-1] != sus["max"]:
            err(f"detection: the top state triggers at {thresholds[-1]}, "
                f"but suspicion caps at {sus['max']}")
        noise = det["noise"]["sources"]
        if [n["heard_within_m"] for n in noise if n["id"] in ("crouched_walk", "walking", "running")] \
                != [1.0, 2.5, 4.5]:
            err("detection: the crouch/walk/run noise ladder does not match §12.17")

    # -- cross-references into the law table --------------------------------
    #
    # §6.2's "With laws" column and §18.3's era rules both name laws in prose.
    # A name that no longer exists is a rename that was not carried through.
    law_names = sorted((law["name"] for law in laws), key=len, reverse=True)
    prose = [("terrain " + t["name"], t["with_laws"]) for t in data["terrain"]]
    prose += [("era " + e["name"], e["rule"]) for e in data["eras"]]
    prose += [("ward " + w["name"], w["effect_level_1"]) for w in data["wards"]]
    for where, sentence in prose:
        for retired in RETIRED_NAMES:
            if retired in sentence:
                err(f"{where}: names {retired!r}, which v2.3 retired (§26.9)")

    # -- laws must key off attributes that exist ----------------------------
    #
    # §7.3's rule is that laws change a realm's rule sheet and never contain
    # special cases. A law reading an attribute no creature carries is the same
    # failure from the other side: the parameter it reads does not exist.
    #: What a law's vocabulary needs from the creature table, and which values
    #: satisfy it. The first version of this asked whether "big" was the *name*
    #: of a creature or a role, which it never could be, so the check reported
    #: the gap correctly for the wrong reason and would have gone on reporting
    #: it after the gap closed.
    LAW_ATTRS = {
        "big": ("size", {"large", "big"}),
        "small": ("size", {"small"}),
        "size": ("size", None),
        "mass": ("size", None),
        "flyer": ("flies", {"yes", "true"}),
        "flyers": ("flies", {"yes", "true"}),
    }

    def unsatisfiable(word: str) -> str | None:
        """Why the creature table has nothing for a law reading this word.

        Two ways it can have nothing, and they are different problems even
        though they are the same fault to a law at runtime. The field can be
        absent from every creature — nothing to read. Or the field can exist
        and no creature carry a value the word picks out: a size band whose
        every entry reads "standard" leaves "big characters get +30% health"
        applying to nobody, which is a content question and not a schema one.
        Returning which it is keeps the report honest about what to fix.
        """
        field, wanted = LAW_ATTRS[word]
        values = {str(r.get(field, "")).strip().lower()
                  for r in data["ruleborn"] if r.get(field)}
        if not values:
            return f"no creature carries a {field}"
        if wanted and not (values & wanted):
            return (f"every creature has a {field}, but none of them is "
                    f"{'/'.join(sorted(wanted))} \u2014 the values are "
                    f"{sorted(values)}")
        return None

    undefined = {a: why for a in LAW_ATTRS if (why := unsatisfiable(a))}
    #: 12.21 declares size a band on every ruleborn and flight a stated
    #: property. Whether the tables carry them is the question, not whether
    #: 12.21 says so, so the declaration only changes the wording of the report.
    declares_attributes = bool(undefined) and _doc_declares_attributes()
    for law in laws:
        text = f"{law.get('tier_1', '')} {law.get('tiers_2_3', '')}".lower()
        hits = sorted(a for a in undefined if a in text.split()
                      or f"{a} characters" in text or f"{a} ones" in text)
        if hits:
            why = "; ".join(dict.fromkeys(undefined[a] for a in hits))
            note = (" \u2014 \u00a712.21 declares size a band on every ruleborn "
                    "and flight a stated property"
                    if declares_attributes else
                    " \u2014 \u00a711.1 has health, speed, power and carry, and "
                    "\u00a711.11's proportions are art direction")
            opn("G12", f"law {law['name']} keys off {hits}: {why}{note}")

    # =====================================================================
    # Known open contradictions — reported, not failed
    # =====================================================================

    launch = launch_table()
    n_traits = len(data["traits"])
    claimed = launch.get("traits")
    if claimed is None:
        err("26.1's launch table has no trait count where this check looks "
            "for it, so C10 cannot be judged either way")
    elif n_traits != claimed:
        opn("C10", f"§11.3 enumerates {n_traits} traits, §26.1's launch table says "
                   f"{claimed}, and §17.3 names a \u201crare Starborn trait\u201d "
                   f"that appears in neither")

    names = {b["name"] for b in data["buildings"]}
    has_library = any("Library" in n for n in names)
    if not has_library:
        opn("C8", "the Library is referenced four times as the non-raiding page "
                  "source (§7.6, §12.1, §27.2, §30.15) but is not among the "
                  "building types in §10.2 — no cost, no levels, no placement rule")
    elif launch.get("buildings") not in (None, len(data["buildings"])):
        opn("C8", f"\u00a726.1's launch table says {launch['buildings']} building "
                  f"types and \u00a710.2 plus the Library give "
                  f"{len(data['buildings'])}")
    elif outside := [b["name"] for b in data["buildings"]
                     if b.get("needs_decision") == "C8"]:
        # v3.1 answered half of C8: 26.1 now counts 17 and the Library has all
        # ten levels. What is left is where it lives. An earlier version of
        # this check reported only the count, so when v3.1 fixed the count the
        # check went silent on an item that is still open — a check losing its
        # subject, which is the same fault as one that cannot fail.
        opn("C8", f"\u00a726.1 now counts {len(data['buildings'])} building types "
                  f"and the Library has all ten levels, but "
                  f"{', '.join(outside)} still sits outside \u00a710.2's table of "
                  f"every level of every building \u2014 which is where every "
                  f"other building is specified, and being outside it is how C8 "
                  f"happened")

    if all(w.get("missing") == "levels 2-5" for w in data["wards"]):
        opn("G3", "§10.3 specifies ward level 1 only, but §10.2 gives the Ward "
                  "building five levels and §21.9 budgets 6 types x 5 levels of props")

    # C3 used to be reported here as `if "Uncommon" not in ranks`, which stopped
    # being true the moment v3.0 re-tagged twelve laws into Uncommon \u2014 so for
    # two versions this file said nothing about the blocking item it was written
    # to watch. That is C6's fault and the UI gate's fault a third time: a check
    # that loses its subject reads exactly like a check that passes.
    #
    # What is left of C3 is a decision, so it is reported as one. The
    # comparison against \u00a77.9's table belongs to check_document.py, which
    # reads the document; this reports what the sheets cost to keep, which
    # nothing else measures.
    import law_ranks
    ranks = collections.Counter(law["rank"] for law in laws)
    if dict(ranks) != law_ranks.SPLITS["sheets"]["counts"]:
        err(f"law ranks are {dict(ranks)}, but law_ranks.SPLITS['sheets'] has "
            f"{law_ranks.SPLITS['sheets']['counts']} \u2014 the sheets moved and "
            f"the split that prices them did not")
    elif law_ranks.uneven_ranks(law_ranks.SPLITS["sheets"]):
        # v3.3 closed C3 the sheets' way, so this fires only if the sheets
        # stop giving every school the same ladder again.
        moves = law_ranks.retag_cost(law_ranks.SPLITS["7.9"], laws)
        uneven = law_ranks.uneven_ranks(law_ranks.SPLITS["sheets"])
        opn("C3", f"the 48 sheets carry {ranks['Common']}/{ranks['Uncommon']}/"
                  f"{ranks['Rare']}/{ranks['Deep']}, which is what \u00a714.4's "
                  f"1,350 pages is computed from and gives every school the same "
                  f"3/2/1/2 ladder; \u00a77.9's table still says 18/14/10/6, which "
                  f"would move {moves} sheets and leaves {' and '.join(uneven)} "
                  f"unable to divide by six schools. \u00a77.6 is the last "
                  f"three-rank statement in the document")

    # D31. \u00a77.1 and \u00a77.9 both state that rank sets how long a law takes to
    # acquire and not how strong it is. The sheets are where that is either
    # true or not, and it is measured rather than asserted \u2014 an earlier
    # version of this file took \u00a77.9's word for it, which is how a design rule
    # goes four versions without anyone checking whether the content obeys it.
    pr = law_ranks.principle(laws)
    # v3.3 withdrew the rule rather than enforcing it (7.9: "rank is a strength
    # ladder"), so the measurement contradicts the document only while the
    # document still claims two dials.
    claims = DOC_TEXT.exists() and "two dials" in DOC_TEXT.read_text(encoding="utf-8")
    if claims and (pr["cost_r"] > 0.5 or abs(pr["condition_r"]) > 0.3):
        opn("D31", f"\u00a77.9 splits rarity from strength into \"two dials\", and "
                   f"\u00a77.1 restates it per law \u2014 but across the 48 sheets rank "
                   f"predicts stability cost at r={pr['cost_r']:+.2f} "
                   f"({pr['dearer']} of {pr['pairs']} cross-rank pairs have the "
                   f"rarer law costing more) and predicts conditions, the other "
                   f"dial, at r={pr['condition_r']:+.2f}. The two dials are one "
                   f"dial, and it is the one \u00a77.9 says it must not be")

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
    # v3.0's §8.8 changed the rule to three *distinct laws*, which makes §8.5
    # true. Whether it makes a chord late-game is a different question, and the
    # cheapest three-law combination is how to answer it.
    #
    # A chord is "three different notes, none of them opposites, carried by
    # three distinct laws" (8.5): each law contributes one of the chord's
    # notes, and nothing bars a contributing law from carrying another. An
    # earlier version dropped any law carrying a note opposite to one in the
    # chord, which is a stricter game than the document's — §8.8's own
    # cheapest triple, Bloom with Brittle stone and Tilt, carries Bloom
    # against the chord's Spark, and that version priced it out.
    cheapest, all_common = None, 0
    for c in data["chords"]:
        pool = [law for law in laws if set(law["notes"]) & set(c["notes"])]
        best = None
        for combo in itertools.combinations(pool, 3):
            offers = [[n for n in l["notes"] if n in c["notes"]] for l in combo]
            if any(set(pick) == set(c["notes"]) for pick in itertools.product(*offers)):
                cost = sum(l["stability_cost"] for l in combo)
                if best is None or cost < best[0]:
                    best = (cost, [l["rank"] for l in combo])
        if best:
            cheapest = best[0] if cheapest is None else min(cheapest, best[0])
            all_common += set(best[1]) == {"Common"}
    # D14 is closed: 8.8 changed the rule to three distinct laws, which was
    # the item. What it did not do is make a chord late-game, and D14's own
    # v3.0 note records the three numbers that show it \u2014 so this reported
    # D14 as open on every build, against a register that had it fixed.
    #
    # The measurement is live and worth keeping; it is the label that was
    # wrong. It is pinned to the note instead: if the content ever moves these
    # numbers, the note is what has gone stale and the build says so. That is
    # check_findings_fresh.py's rule \u2014 a number that cannot be shown to be
    # stale will be trusted for ever \u2014 applied to a closed item.
    if cheapest is not None:
        pin("D14", "the cheapest chord's stability cost", cheapest, 32)
        pin("D14", "chords costing three commons", all_common, 8)
        pin("D14", "a day-2 stability capacity", DAY_2_STABILITY, 51)
    elif reachable_with_two:
        opn("D14", f"{reachable_with_two} of {len(data['chords'])} chords are reachable "
                   f"with two laws, not the three \u00a78.5 describes "
                   f"({two_note} of {len(laws)} laws carry two notes)")

    # v3.0's §21.8 now says "every school has a sound signature — six in all",
    # which is what the content holds. The check only fires against the older
    # wording, where every *law* had one.
    doc = DOC_TEXT
    per_law_claimed = doc.exists() and "every law also has a sound signature" in \
        doc.read_text(encoding="utf-8")
    sounds = collections.Counter(law["sound"] for law in laws)
    if per_law_claimed and len(sounds) < len(laws):
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
    # The wording half was never reported. `if role_conflicts:` meant that the
    # moment v3.1 reconciled the three role swaps this check went silent on an
    # item the register still had open — a check losing its subject, which
    # reads exactly like a check passing.
    if role_conflicts:
        opn("C6", f"§11.2 and §11.11 give different roles for "
                  f"{', '.join(role_conflicts)}, which changes crew "
                  f"composition, guard behaviour and the Nursery's "
                  f"fewest-roles-first rule; {wording} more differ on ability "
                  f"wording")
    elif wording:
        # Recorded as wording for two versions, and it is not: `ability_text`
        # reads the eighteen pairs and twelve of them do a different thing.
        # Calling it wording is the third way this check has understated its
        # own subject, after the role branch that went silent when the roles
        # reconciled.
        import ability_text
        rows = ability_text.pairs(data["ruleborn"])
        cd = ability_text.cooldowns(rows)
        effect = sum(1 for r in rows if r["kind"] == ability_text.EFFECT)
        opn("C6", f"§11.2 and §11.11 agree on every ruleborn's school "
                  f"and role — v3.1 closed that half — but all "
                  f"{wording} still give different ability text, and it is not "
                  f"wording: {effect} of {len(rows)} do a different thing rather "
                  f"than the same thing by a different amount, and of the "
                  f"{cd['both']} that state a cooldown on both sides "
                  f"§11.2's is shorter in {cd['shorter']}. Two balance "
                  f"passes, not two phrasings")

    report()
    return 1 if (errors or stale_reports()
                 or any(g != e for _, _, g, e in pinned)) else 0


def self_test() -> int:
    """The three states this file can report, each shown to be reachable.

    It had none of this. It reported G12, C10 and D14 as open contradictions
    against a document that had answered all three, for as long as it read
    v3.0 \u2014 and the numbers it compared against, 30 traits and 16 building
    types, were the only thing still saying so. Nothing compared its reports
    against the register, so nothing could notice.
    """
    ok = True

    launch = launch_table()
    want = {"laws", "ruleborn", "traits", "buildings", "terrain"}
    got = want & set(launch)
    print(f"  26.1's launch table reads {len(launch)} rows, including "
          f"{len(got)} of the {len(want)} this file compares against")
    if got != want:
        print(f"    FAIL: {sorted(want - got)} not found in 26.1")
        ok = False

    # A report about a closed item must be reported as stale, not as open.
    before = len(open_items)
    opn("D28", "planted: D28 is done and this claims otherwise")
    caught = any(i == "D28" for i, _ in stale_reports())
    del open_items[before:]
    print(f"  [{'PASS' if caught else 'FAIL'}] a report about a closed item is "
          f"{'reported stale' if caught else 'MISSED'}")
    ok = ok and caught

    # And a report about an open one must not be.
    # Whichever item is open today: a planted report must not depend on
    # the register standing still (G3 was the example until v3.3 closed it).
    from audit_register import REGISTER, is_open
    live = next(i["id"] for i in REGISTER if is_open(i))
    opn(live, f"planted: {live} is open and this is what that looks like")
    wrongly = any(i == live for i, _ in stale_reports())
    del open_items[before:]
    print(f"  [{'PASS' if not wrongly else 'FAIL'}] a report about an open item "
          f"is {'left alone' if not wrongly else 'WRONGLY CALLED STALE'}")
    ok = ok and not wrongly

    # A pinned number that has moved must fail.
    n = len(pinned)
    pin("D28", "planted", 1, 2)
    moved = any(g != e for _, _, g, e in pinned)
    del pinned[n:]
    print(f"  [{'PASS' if moved else 'FAIL'}] a pinned number that moved is "
          f"{'caught' if moved else 'MISSED'}")
    ok = ok and moved

    # The Library curve is the document's, not a fit.
    import importlib
    eco = importlib.import_module("economy_model.sinks")
    doc_levels = {lvl["level"]: int(lvl["gives"].split()[0])
                  for b in load("buildings") if b["id"] == "library"
                  for lvl in b["levels"]}
    bad = [l for l, v in doc_levels.items() if eco.library_pages(l) != v]
    print(f"  [{'PASS' if not bad else 'FAIL'}] the economy model's Library "
          f"curve is 10.4's own at all {len(doc_levels)} levels"
          + (f" \u2014 differs at {bad}" if bad else ""))
    ok = ok and not bad

    # D42's guard, shown to fail. Planted in the content rather than in a
    # fixture, because the check walks the committed files and a fixture would
    # prove the `in` works rather than that the walk arrives.
    import json as _json
    path = CONTENT / "ruleborn.json"
    original = path.read_text(encoding="utf-8")
    rows = _json.loads(original)
    # An era's name, from \u00a718.3. (A Sage's name no longer serves: \u00a721.6,
    # which the cards now read, describes the Sages too.)
    rows[0]["look"] = "The Long Night"
    path.write_text(_json.dumps(rows, indent=1, ensure_ascii=False) + "\n",
                    encoding="utf-8")
    try:
        caught = any("look" in p and "not in" in p for p in check_provenance())
    finally:
        path.write_text(original, encoding="utf-8")
    print(f"  [{'PASS' if caught else 'FAIL'}] a value read from outside its "
          f"own section is caught")
    ok = ok and caught

    # §11.10's note rule, shown to fail: Weight carries as many launch laws as
    # Echo and completes fewer chords, so forms in Weight break the tie-break.
    forms, laws, chords = load("forms"), load("laws"), load("chords")
    names = [n["name"] for n in load("notes")]
    clean = not check_forms(forms, load("ruleborn"), laws, chords, names)
    planted = [dict(f, note="Weight") if f["note"] == "Echo" else f for f in forms]
    caught = any("tie" in p for p in check_forms(planted, load("ruleborn"), laws, chords, names))
    print(f"  [{'PASS' if clean and caught else 'FAIL'}] §11.10's forms pass, and "
          f"forms in the wrong note are {'caught' if caught else 'MISSED'}")
    ok = ok and clean and caught
    return 0 if ok else 1


def report() -> None:
    print()
    if errors:
        print(f"ERRORS  {len(errors)} — the data is malformed; fix before use\n")
        for e in errors:
            print(f"  ✗ {e}")
        print()
    else:
        print("ERRORS  none — every table is well formed and internally consistent\n")

    moved = [(i, w, g, e) for i, w, g, e in pinned if g != e]
    if moved:
        print(f"MOVED   {len(moved)} number(s) a closed register item records\n")
        for item_id, what, got, expected in moved:
            print(f"  \u2717 [{item_id}] {what}: the data gives {got}, the item's "
                  f"note says {expected}")
        print()
    elif pinned:
        print("PINNED  every number these closed items record still holds: "
              + ", ".join(f"{w} = {g}" for _, w, g, _ in pinned) + "\n")

    stale = stale_reports()
    live = [(i, m) for i, m in open_items if (i, m) not in stale]
    if live:
        print(f"OPEN    {len(live)} known contradictions in the design document")
        print("        (tracked in the audit register; expected until resolved)\n")
        for item_id, msg in live:
            print(f"  [{item_id}] {msg}")
        print()
    if stale:
        print(f"STALE   {len(stale)} report(s) about items the register calls closed")
        print("        (this file is the thing out of date, not the document)\n")
        for item_id, msg in stale:
            print(f"  \u2717 [{item_id}] {msg}")
        print()


if __name__ == "__main__":
    raise SystemExit(self_test() if "--self-test" in sys.argv else main())
