#!/usr/bin/env python3
"""Write client/i18n/countries.csv: every country's name in the game's
languages, for the account panel's devices list (docs/security/auth.md),
which shows the country a device was last seen in as words, never a code or
an address.

    python3 tools/auth_countries.py           write it (needs Babel's CLDR data)
    python3 tools/auth_countries.py --check   fail if a code is missing or a row is malformed

The names are the Unicode CLDR's, through Babel; the codes are ISO 3166-1
alpha-2, the ones an edge's country header carries (cf-ipcountry).
"""

from __future__ import annotations

import csv
import io
import json
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / "client" / "i18n" / "countries.csv"
ISO = Path("/usr/share/iso-codes/json/iso_3166-1.json")
COLUMNS = ["en", "en_US", "pt_BR", "pt_PT", "de", "fr"]
# English (US) names its countries as English (UK) does.
CLDR = {"en": "en", "en_US": "en", "pt_BR": "pt_BR", "pt_PT": "pt_PT", "de": "de", "fr": "fr"}


def codes() -> list[str]:
    from babel import Locale
    known = Locale.parse("en").territories
    listed = [c["alpha_2"] for c in json.loads(ISO.read_text())["3166-1"]] if ISO.exists() else []
    return sorted(set(listed) or {c for c in known if len(c) == 2 and c.isalpha()})


def table() -> str:
    from babel import Locale
    names = {col: Locale.parse(CLDR[col]).territories for col in COLUMNS}
    out = io.StringIO()
    w = csv.writer(out, lineterminator="\n")
    w.writerow(["key", *COLUMNS])
    for c in codes():
        w.writerow([f"COUNTRY_{c}", *(names[col].get(c, names["en"].get(c, c)) for col in COLUMNS)])
    return out.getvalue()


def check() -> int:
    rows = list(csv.reader(OUT.open(encoding="utf-8")))
    bad = [r[0] for r in rows[1:] if len(r) != len(COLUMNS) + 1 or not all(r[1:])
           or not (r[0].startswith("COUNTRY_") and len(r[0]) == 10)]
    if rows[0] != ["key", *COLUMNS] or bad or len(rows) < 240:
        print(f"client/i18n/countries.csv is malformed: {rows[0]} {bad[:5]} {len(rows) - 1} rows")
        return 1
    print(f"client/i18n/countries.csv: {len(rows) - 1} countries in {len(COLUMNS)} languages")
    return 0


def main() -> int:
    if "--check" in sys.argv:
        return check()
    OUT.write_text(table(), encoding="utf-8")
    print(f"wrote {OUT.relative_to(ROOT)}")
    return check()


if __name__ == "__main__":
    sys.exit(main())
