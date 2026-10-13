#!/usr/bin/env python3
"""Write the phones' own string tables for §14.6's notifications.

    python3 tools/native_strings.py            # write them
    python3 tools/native_strings.py --check    # fail if one differs or a key is missing

A push notification is drawn by the phone, not by the game: the server sends
localisation keys (server/src/push.mjs `KEYS`) and the phone looks them up in
the app's own tables, in the phone's language. The device's own timers —
storage full, a character rested, an experiment finished — are drawn the same
way. So the words live once, in client/platform/notifications.csv, and this
writes them where each phone reads them:

* iOS: client/platform/ios/<lang>.lproj/Localizable.strings, `%@` for an
  argument;
* Android: client/platform/android/res/values[-<lang>]/strings.xml, `%1$s`.

A phone with none of the game's languages gets its default: `en.lproj` and
`values`, which are US English, the form most such phones would choose;
British English is `en-GB` and `values-en-rGB`. Any Portuguese but Brazil's
is European (Android's `values-pt`).

The check also holds the table to its users: every key push.mjs sends, a
title and a body for each of §14.6's four kinds, both languages filled, and
the same arguments in each.
"""

from __future__ import annotations

import csv
import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
PLATFORM = ROOT / "client" / "platform"
SOURCE = PLATFORM / "notifications.csv"
PUSH = ROOT / "server" / "src" / "push.mjs"

#: §14.6: "only for things the player can act on (storage full, a character
#: rested, an experiment finished, a heist against you)".
KINDS = ("storage_full", "rested", "experiment", "raided")
LANGS = {"en": ("en-GB", "values-en-rGB"), "en_US": ("en", "values"), "pt_BR": ("pt-BR", "values-pt-rBR"),
         "pt_PT": ("pt-PT", "values-pt"), "de": ("de", "values-de"), "fr": ("fr", "values-fr")}
ARG = re.compile(r"\{(\d)\}")


def rows() -> list[dict]:
    with SOURCE.open(encoding="utf-8", newline="") as f:
        return list(csv.DictReader(f))


def _ios(text: str) -> str:
    text = text.replace("\\", "\\\\").replace('"', '\\"')
    return ARG.sub("%@", text)


def _android(text: str) -> str:
    text = (text.replace("&", "&amp;").replace("<", "&lt;").replace(">", "&gt;")
            .replace("\\", "\\\\").replace("'", "\\'").replace('"', '\\"'))
    return ARG.sub(lambda m: f"%{int(m.group(1)) + 1}$s", text)


HEAD = "Written by tools/native_strings.py from client/platform/notifications.csv; edit that."


def outputs() -> dict[Path, str]:
    table = rows()
    out = {}
    for lang, (ios, android) in LANGS.items():
        lines = [f"/* {HEAD} */"] + [f'"{r["key"]}" = "{_ios(r[lang])}";' for r in table]
        out[PLATFORM / "ios" / f"{ios}.lproj" / "Localizable.strings"] = "\n".join(lines) + "\n"
        xml = ['<?xml version="1.0" encoding="utf-8"?>', f"<!-- {HEAD} -->", "<resources>"]
        xml += [f'    <string name="{r["key"]}">{_android(r[lang])}</string>' for r in table]
        xml.append("</resources>")
        out[PLATFORM / "android" / "res" / android / "strings.xml"] = "\n".join(xml) + "\n"
    return out


def push_keys() -> set[str]:
    """Every localisation key server/src/push.mjs sends."""
    return set(re.findall(r'"(ruleborn_\w+)"', PUSH.read_text(encoding="utf-8")))


def problems() -> list[str]:
    table = rows()
    keys = [r["key"] for r in table]
    found = []
    if len(keys) != len(set(keys)):
        found.append("a key is written twice")
    for k in sorted(push_keys() - set(keys)):
        found.append(f"{k}: sent by push.mjs, missing from the table")
    for kind in KINDS:
        for part in ("title", "body"):
            if f"ruleborn_{kind}_{part}" not in keys:
                found.append(f"ruleborn_{kind}_{part}: §14.6's {kind} has no {part}")
    with SOURCE.open(encoding="utf-8", newline="") as f:
        head = next(csv.reader(f))[1:]
    if sorted(head) != sorted(LANGS):
        found.append(f"the table's languages {head} are not the phones' {sorted(LANGS)}")
    for r in table:
        for lang in LANGS:
            if not (r.get(lang) or "").strip():
                found.append(f"{r['key']}: no {lang}")
            elif sorted(ARG.findall(r["en"])) != sorted(ARG.findall(r[lang])):
                found.append(f"{r['key']}: {lang}'s arguments differ from English's")
    for path, text in outputs().items():
        if not path.exists() or path.read_text(encoding="utf-8") != text:
            found.append(f"{path.relative_to(ROOT)}: differs from the table; run tools/native_strings.py")
    return found


def main() -> int:
    if "--check" not in sys.argv:
        for path, text in outputs().items():
            path.parent.mkdir(parents=True, exist_ok=True)
            path.write_text(text, encoding="utf-8")
    found = problems()
    for p in found:
        print(f"  ✗ {p}")
    if found:
        return 1
    print(f"{len(rows())} notification strings, in each of the {len(LANGS)} languages, on both phones")
    return 0


if __name__ == "__main__":
    sys.exit(main())
