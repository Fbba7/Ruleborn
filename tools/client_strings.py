#!/usr/bin/env python3
"""Write client/i18n/content.csv: the names of the game's content, for the
client's string catalogue.

    python3 tools/client_strings.py            # write it
    python3 tools/client_strings.py --check    # fail if the committed file differs

A law's name, a note's, a resonance's, a chord's, a ward's, a terrain
feature's, a building's and a realm type's each have one home: the content file they are extracted into. The
client shows them, and every word the client shows comes from its catalogue
(client/scripts/strings.gd), so this writes them there rather than anyone
typing them twice.

The Portuguese column is the English name for now. These are the coined words
§26.9 sends to a native speaker's read-aloud before anything is translated,
and a name invented here would be a translation nobody decided on; the column
is filled so the catalogue test holds every key to both languages, and the
real names replace it when that read is done.
"""

import csv
import io
import json
import pathlib
import sys

sys.path.insert(0, str(pathlib.Path(__file__).resolve().parent))

ROOT = pathlib.Path(__file__).resolve().parent.parent
CONTENT = ROOT / "content"
OUT = ROOT / "client" / "i18n" / "content.csv"

#: The terrain features the builder can lay, which are the ones the
#: simulation models (client/ext/src/island.rs `GROUND`).
GROUND = ["rock_pillar", "ruin_wall", "fence", "fog_bank", "tall_grass",
          "gravel_path", "stream", "raised_ground"]


def rows() -> list[tuple[str, str]]:
    load = lambda name: json.loads((CONTENT / name).read_text(encoding="utf-8"))
    out = []
    out += [(f"LAW_{l['id'].upper()}", l["name"]) for l in load("laws.json")]
    out += [(f"NOTE_{n['id'].upper()}", n["name"]) for n in load("notes.json")]
    out += [(f"RES_{r['id'].upper()}", r["name"]) for r in load("resonances.json")]
    out += [(f"CHORD_{c['id'].upper()}", c["name"]) for c in load("chords.json")]
    out += [(f"WARD_{w['id'].upper()}", w["name"]) for w in load("wards.json")]
    terrain = {t["id"]: t["name"] for t in load("terrain.json")}
    out += [(f"GROUND_{g.upper()}", terrain[g]) for g in GROUND]
    out += [(f"BUILDING_{b['id'].upper()}", b["name"]) for b in load("buildings.json")]
    # §5.2's realm types, from their one home (the server sends the name).
    from design_facts import REALM_TYPES
    out += [(f"REALM_{t.upper().replace(' ', '_')}", t) for t in REALM_TYPES]
    return out


def render() -> str:
    buf = io.StringIO()
    w = csv.writer(buf, lineterminator="\n")
    w.writerow(["key", "en", "pt_BR"])
    for key, name in rows():
        w.writerow([key, name, name])
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
