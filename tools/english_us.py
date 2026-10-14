#!/usr/bin/env python3
"""Write English (US) from English (UK): one home for the game's English.

    python3 tools/english_us.py            # write the en_US columns and fields
    python3 tools/english_us.py --check    # fail if one differs from what this writes

The game's English is written once, in British spelling, as the design
document is: the `en` column of client/i18n/strings.csv and
client/platform/notifications.csv, and the `en` of each word in
server/src/words.json. The owner asked for English in UK and US forms. The
two differ in spelling, not in words, so the US form is the UK one through
SPELLING, written beside it — an `en_US` column, and an `en_US` on each word
whose spelling differs — and never typed by hand. A row whose US spelling
would read wrongly is fixed in SPELLING or the UK text, not in the column.
"""

from __future__ import annotations

import csv
import io
import json
import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
TABLES = [ROOT / "client" / "i18n" / "strings.csv", ROOT / "client" / "platform" / "notifications.csv"]
WORDS = ROOT / "server" / "src" / "words.json"

#: British spelling -> American, by word stem; a stem matches at a word's
#: start, so "recognis" covers recognise, recognised and recognising.
SPELLING = {
    "analys": "analyz", "apologis": "apologiz", "armour": "armor", "behaviour": "behavior",
    "cancelled": "canceled", "cancelling": "canceling", "catalogue": "catalog", "centre": "center",
    "colour": "color", "defence": "defense", "dialogue": "dialog", "enrol": "enroll",
    "favour": "favor", "fulfil": "fulfill", "grey": "gray", "harbour": "harbor", "harmonis": "harmoniz", "honour": "honor",
    "jewellery": "jewelry", "labour": "labor", "licence": "license", "metre": "meter",
    "neighbour": "neighbor", "odour": "odor", "offence": "offense", "organis": "organiz",
    "practise": "practice", "programme": "program", "realis": "realiz", "recognis": "recogniz",
    "rumour": "rumor", "splendour": "splendor", "theatre": "theater", "travelled": "traveled",
    "travelling": "traveling", "tyre": "tire", "valour": "valor", "vapour": "vapor",
}
#: Words the stems above would wrongly change.
KEEP = {"analyst", "analysts"}
_STEM = re.compile(r"\b(" + "|".join(sorted(SPELLING, key=len, reverse=True)) + r")(\w*)", re.I)


def us(text: str) -> str:
    def swap(m: re.Match) -> str:
        if m.group(0).lower() in KEEP:
            return m.group(0)
        stem = SPELLING[m.group(1).lower()]
        if m.group(1).isupper():
            stem = stem.upper()
        elif m.group(1)[0].isupper():
            stem = stem[0].upper() + stem[1:]
        return stem + m.group(2)
    return _STEM.sub(swap, text)


def table(path: Path) -> str:
    """The table with its en_US column made from `en`, right after it."""
    with path.open(encoding="utf-8", newline="") as f:
        rows = list(csv.reader(f))
    head = rows[0]
    if "en_US" not in head:
        head.insert(head.index("en") + 1, "en_US")
        for r in rows[1:]:
            r.insert(head.index("en_US"), "")
    en, col = head.index("en"), head.index("en_US")
    for r in rows[1:]:
        if len(r) > en:
            r[col] = us(r[en])
    out = io.StringIO()
    csv.writer(out, lineterminator="\n").writerows(rows)
    return out.getvalue()


def words() -> str:
    data = json.loads(WORDS.read_text(encoding="utf-8"))
    for kind in ("adjectives", "nouns"):
        for w in data[kind]:
            w.pop("en_US", None)
            if us(w["en"]) != w["en"]:
                w["en_US"] = us(w["en"])
    return json.dumps(data, ensure_ascii=False, indent=1) + "\n"


def outputs() -> dict[Path, str]:
    return {**{p: table(p) for p in TABLES}, WORDS: words()}


def main() -> int:
    changed = [p for p, text in outputs().items() if p.read_text(encoding="utf-8") != text]
    if "--check" in sys.argv:
        for p in changed:
            print(f"  ✗ {p.relative_to(ROOT)}: its US English differs from its UK English through "
                  f"SPELLING; run tools/english_us.py")
        if changed:
            return 1
        print("English (US) is English (UK) through the spelling table, in every table and word list")
        return 0
    for p, text in outputs().items():
        p.write_text(text, encoding="utf-8")
    print(f"wrote English (US) beside English (UK) in {len(TABLES)} tables and the word list")
    return 0


if __name__ == "__main__":
    sys.exit(main())
