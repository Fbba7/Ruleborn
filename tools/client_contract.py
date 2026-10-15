#!/usr/bin/env python3
"""The contract between client/ and server/, checked from both sides' code.

    python3 tools/client_contract.py            report, and fail on a break
    python3 tools/client_contract.py --missing  print the ERR_ keys to add

Two things break silently when one side changes and the other does not, so
this fails the build on either (TC.2):

* A route the client calls that the server does not serve. The server's
  routes are the table at the top of server/src/http.mjs; the client's are
  the paths its repositories and API pass (client/data/). A path with a
  token in it matches a route's :param.
* A refusal the player cannot read. Every reason the server refuses with
  (`new Refused(status, "reason")`, `json({ error: "reason" })`, a settled
  heist's `refuse("reason")`) and every failure code the client makes
  (`Result.failure("code")`, a controller's `_fail("code")`) must have an ERR_ key in the client's catalogue
  (client/i18n/strings.csv) in every language, so `Errors.message` shows
  words, not a code.
"""

from __future__ import annotations

import csv
import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
SERVER = ROOT / "server" / "src"
CLIENT = ROOT / "client"

DOC_ROUTE = re.compile(r"^//\s+(GET|POST|PUT|DELETE|PATCH)\s+(/\S+)", re.M)
REFUSED = [re.compile(r'new Refused\(\d+,\s*"([a-z0-9_]+)"'),
           re.compile(r'json\(\{\s*error:\s*"([a-z0-9_]+)"'),
           re.compile(r'\brefuse\("([a-z0-9_]+)"\)')]
CLIENT_FAILURE = re.compile(r'(?:Result\.failure|_fail)\("([a-z0-9_]+)"')
TRANSPORT_ERROR = re.compile(r'\{"error":\s*"([a-z0-9_]+)"\}')
CALLS = [
    (re.compile(r'api\.get_json\("(/v1/[^"]*)"\s*(?:\+\s*\w+)?'), "GET"),
    (re.compile(r'api\.public_json\("(/v1/[^"]*)"\s*(?:\+\s*\w+)?'), "GET"),
    (re.compile(r'api\.post_json\("(/v1/[^"]*)"\s*(?:\+\s*\w+)?'), "POST"),
    (re.compile(r'api\.(?:json|raw)\(HTTPClient\.METHOD_(\w+),\s*"(/v1/[^"]*)"\s*(\+\s*\w+)?'), None),
    (re.compile(r'route := "(/v1/[^"]*)"\s*(\+\s*\w+)?'), "POST"),
    (re.compile(r'outbox\.send\(api,\s*\w+,\s*"(/v1/[^"]*)"\s*(\+\s*\w+)?'), "POST"),
]


def server_routes() -> list[tuple[str, list[str]]]:
    text = (SERVER / "http.mjs").read_text(encoding="utf-8")
    return [(m.group(1), m.group(2).split("?")[0].strip("/").split("/")) for m in DOC_ROUTE.finditer(text)]


def client_calls() -> list[tuple[str, str, str]]:
    out = []
    for path in sorted((CLIENT / "data").rglob("*.gd")):
        text = path.read_text(encoding="utf-8")
        for pattern, method in CALLS:
            for m in pattern.finditer(text):
                if method is None:
                    verb, route, tail = m.group(1), m.group(2), m.group(3)
                else:
                    verb, route = method, m.group(1)
                    tail = m.group(m.lastindex) if m.lastindex and m.lastindex > 1 else None
                    tail = tail if tail and tail.strip().startswith("+") else None
                route = route.replace("%s", ":x").replace("%d", ":x")
                # A query string is not part of the route.
                if "?" in route:
                    route, tail = route.split("?")[0], None
                if tail or route.endswith("/"):
                    route = route.rstrip("/") + "/:x"
                out.append((verb, route, str(path.relative_to(ROOT))))
    return out


def matches(route: str, pattern: list[str]) -> bool:
    parts = route.strip("/").split("/")
    # The client's :x (a value it fills in) stands only where the server takes
    # a :param; against a literal it would pass a typo.
    return len(parts) == len(pattern) and all(p == q or q.startswith(":")
                                              for p, q in zip(parts, pattern))


def server_reasons() -> set[str]:
    reasons: set[str] = set()
    for path in SERVER.glob("*.mjs"):
        text = path.read_text(encoding="utf-8")
        for pattern in REFUSED:
            reasons.update(pattern.findall(text))
    return reasons


def client_codes() -> set[str]:
    codes: set[str] = set()
    for path in CLIENT.rglob("*.gd"):
        if ".godot" in path.parts:
            continue
        text = path.read_text(encoding="utf-8")
        codes.update(CLIENT_FAILURE.findall(text))
        codes.update(TRANSPORT_ERROR.findall(text))
    return codes


def catalogue() -> tuple[list[str], dict[str, dict[str, str]]]:
    with open(CLIENT / "i18n" / "strings.csv", encoding="utf-8", newline="") as f:
        rows = list(csv.reader(f))
    locales = rows[0][1:]
    return locales, {r[0]: dict(zip(locales, r[1:])) for r in rows[1:] if r and r[0]}


def problems() -> tuple[list[str], list[str]]:
    out: list[str] = []
    routes = server_routes()
    for verb, route, where in client_calls():
        if not any(v == verb and matches(route, p) for v, p in routes):
            out.append(f"{where}: {verb} {route} is not a route server/src/http.mjs serves")
    locales, rows = catalogue()
    missing = []
    for code in sorted(server_reasons() | client_codes()):
        key = "ERR_" + code.upper()
        if key not in rows or any(not rows[key].get(l) for l in locales):
            missing.append(key)
    out += [f"client/i18n/strings.csv: no words for {k} in every language" for k in missing]
    return out, missing


def main() -> int:
    out, missing = problems()
    if "--missing" in sys.argv:
        print("\n".join(missing))
        return 0
    for line in out:
        print("  " + line)
    calls = len(client_calls())
    reasons = len(server_reasons() | client_codes())
    if out:
        print(f"client contract: {len(out)} break(s)")
        return 1
    print(f"client contract: {calls} client calls are server routes; {reasons} failure codes have words in every language")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
