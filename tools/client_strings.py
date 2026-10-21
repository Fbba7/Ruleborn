#!/usr/bin/env python3
"""Write client/i18n/content.csv: the names of the game's content, for the
client's string catalogue.

    python3 tools/client_strings.py            # write it
    python3 tools/client_strings.py --check    # fail if the committed file differs

A law's name, a note's, a resonance's, a chord's, a ward's, a terrain
feature's, a building's, a realm type's, a ruleborn's name and card, a
trait's name and effect, a Sage's name, powers and levels, and a form's
look and quirk each have one home: the content file they are
extracted into. The
client shows them, and every word the client shows comes from its catalogue
(client/scripts/strings.gd), so this writes them there rather than anyone
typing them twice.

Every language's column but English is the English name for now. These are
the coined words §26.9 sends to a native speaker's read-aloud before anything
is translated (a card's sentences go with its name, to the same reader), and a name invented here would be a translation nobody
decided on; the columns are filled so the catalogue test holds every key to
every language, and the owner's names replace them when that read is done.
The languages are client/i18n/strings.csv's columns, their one home; US
English is the name in US spelling (tools/english_us.py).
"""

import csv
import io
import json
import pathlib
import re
import sys

sys.path.insert(0, str(pathlib.Path(__file__).resolve().parent))

ROOT = pathlib.Path(__file__).resolve().parent.parent
CONTENT = ROOT / "content"
OUT = ROOT / "client" / "i18n" / "content.csv"

#: The terrain features the builder can lay, which are the ones the
#: simulation models: read from their one home, client/ext/src/island.rs
#: `GROUND`.
GROUND = re.findall(r'"(\w+)"', re.search(
    r"pub const GROUND: \[&str; \d+\] = \[(.*?)\];",
    (ROOT / "client" / "ext" / "src" / "island.rs").read_text(encoding="utf-8"), re.S).group(1))


def rows() -> list[tuple[str, str]]:
    load = lambda name: json.loads((CONTENT / name).read_text(encoding="utf-8"))
    out = []
    out += [(f"LAW_{l['id'].upper()}", l["name"]) for l in load("laws.json")]
    # §21.7's law card: "a one-line rule" — the first sentence of the law's
    # tier I rule, its section references dropped — and §7.7's one weakness
    # (§23.5's law card row). The law's own text is their one home.
    for l in load("laws.json"):
        rule = re.sub(r" \([^)]*\b\d+\.\d+[^)]*\)", "", l["tier_1"])
        out += [(f"LAW_RULE_{l['id'].upper()}", re.split(r"(?<=[.!?])\s+(?=[A-Z])", rule)[0]),
                (f"LAW_WEAKNESS_{l['id'].upper()}", l["weakness"])]
    out += [(f"NOTE_{n['id'].upper()}", n["name"]) for n in load("notes.json")]
    out += [(f"RES_{r['id'].upper()}", r["name"]) for r in load("resonances.json")]
    out += [(f"CHORD_{c['id'].upper()}", c["name"]) for c in load("chords.json")]
    out += [(f"WARD_{w['id'].upper()}", w["name"]) for w in load("wards.json")]
    terrain = {t["id"]: t["name"] for t in load("terrain.json")}
    # Moss is a surface (§6.1, §12.17), not one of §6.2's features: its name
    # is an ordinary word, translated in strings.csv.
    out += [(f"GROUND_{g.upper()}", terrain[g]) for g in GROUND if g in terrain]
    out += [(f"BUILDING_{b['id'].upper()}", b["name"]) for b in load("buildings.json")]
    # §11.11's character cards: each ruleborn's name, its ability and what
    # it is best at, as the Character screen shows them (§23.2); and §11.3's
    # traits, each with what it does. The card's words are its one home.
    for k in load("ruleborn.json"):
        out += [(f"RULEBORN_{k['id'].upper()}", k["name"]), (f"ABILITY_{k['id'].upper()}", k["ability"]),
                (f"BEST_AT_{k['id'].upper()}", k["best_at"]), (f"RESISTS_{k['id'].upper()}", k["resists"])]
    # §11.1's roles: what each does on a heist (its numbers are the
    # simulation's, RulebornReplay.role_numbers).
    out += [(f"ROLE_JOB_{r['id'].upper()}", r["job"]) for r in load("roles.json")]
    for t in load("traits.json"):
        out += [(f"TRAIT_{t['id'].upper()}", t["name"]), (f"TRAIT_EFFECT_{t['id'].upper()}", t["effect"])]
    # §11.7's Sages: each one's name, heist powers, at-home effect, and what
    # each fifth level adds (the Sage hall, §23.2).
    for sg in load("sages.json"):
        key = sg["id"].upper()
        out += [(f"SAGE_{key}", sg["name"]), (f"SAGE_POWERS_{key}", sg["heist_powers"]),
                (f"SAGE_HOME_{key}", sg["at_home"])]
        out += [(f"SAGE_LEVEL_{lv}_{key}", text) for lv, text in sg["levels"].items()]
    # §11.10's forms: each note's look and quirk, the same for every kind
    # (one per note, or the content disagrees with itself), and each note's
    # symbol (§8), for the Forms album (§23.2).
    looks = {}
    for f in load("forms.json"):
        looks.setdefault(f["note"], set()).add((f["look"], f["quirk"]))
    for note, pairs in looks.items():
        assert len(pairs) == 1, f"{note}'s forms differ in look or quirk"
        look, quirk = next(iter(pairs))
        # A cross-reference to this document's sections is for its readers,
        # not the player's: "(Revival, 7.3)" goes.
        quirk = re.sub(r" \([^)]*\b\d+\.\d+\)", "", quirk)
        out += [(f"FORM_LOOK_{note.upper()}", look), (f"FORM_QUIRK_{note.upper()}", quirk)]
    out += [(f"NOTE_SYMBOL_{n['id'].upper()}", n["symbol"]) for n in load("notes.json")]
    # §5.2's realm types, from their one home (the server sends the name).
    from design_facts import REALM_TYPES
    out += [(f"REALM_{t.upper().replace(' ', '_')}", t) for t in REALM_TYPES]
    return out


def locales() -> list[str]:
    """The game's languages: client/i18n/strings.csv's columns."""
    with (ROOT / "client" / "i18n" / "strings.csv").open(encoding="utf-8", newline="") as f:
        return next(csv.reader(f))[1:]


def render() -> str:
    from english_us import us
    buf = io.StringIO()
    w = csv.writer(buf, lineterminator="\n")
    w.writerow(["key", *locales()])
    for key, name in rows():
        w.writerow([key, *[us(name) if loc == "en_US" else name for loc in locales()]])
    return buf.getvalue()


def main() -> int:
    text = render()
    if "--check" in sys.argv:
        if not OUT.exists() or OUT.read_text(encoding="utf-8") != text:
            print("client/i18n/content.csv differs from content/: "
                  "run python3 tools/client_strings.py")
            return 1
        print(f"client/i18n/content.csv matches content/ ({len(rows())} names)")
        return 0
    OUT.write_text(text, encoding="utf-8")
    print(f"wrote {OUT.relative_to(ROOT)} ({len(rows())} names)")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
