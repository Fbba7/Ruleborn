#!/usr/bin/env python3
"""Compare the prototype's data module with content/ (TD.33, §23.5).

§23.5: "The prototype reads all its numbers from one module. The build does
the same from this document's tables and 31.3's constants; the prototype's
module is not a source." So nothing here feeds content/. This lists where the
module and content/ differ, and names for each the §23.5 row or register item
that already records it; a difference with neither is printed as new.

The module is not kept in this repository, so the comparison takes its path
and checks it is the handoff's file (the hash recorded in
docs/analysis/screens-v3/handoff/data/prototype.md5) before reading it. It
reads the module as text, never runs it.

    python3 -I tools/compare_module.py PATH/TO/ruleborn-data.js [--write]

--write records the result in docs/analysis/screens-v3/handoff/module.md.
"""
from __future__ import annotations

import hashlib
import json
import pathlib
import re
import sys

ROOT = pathlib.Path(__file__).resolve().parent.parent
CONTENT = ROOT / "content"
HASHES = ROOT / "docs/analysis/screens-v3/handoff/data/prototype.md5"
REPORT = ROOT / "docs/analysis/screens-v3/handoff/module.md"

#: Differences already on record: a §23.5 row ("Where" column) or a register
#: item, by what differs.
KNOWN = {
    "role health": "§23.5, “Role health in the prototype’s data module”",
}


def read_module(path: pathlib.Path) -> str:
    raw = path.read_bytes()
    digest = hashlib.md5(raw).hexdigest()
    recorded = {line.split()[1].lstrip("./"): line.split()[0]
                for line in HASHES.read_text(encoding="utf-8").splitlines() if line.strip()}
    if recorded.get("ruleborn-data.js") != digest:
        raise SystemExit(f"{path} is not the handoff's ruleborn-data.js "
                         f"(md5 {digest}, recorded {recorded.get('ruleborn-data.js')})")
    return raw.decode("utf-8")


def module_laws(text: str) -> dict:
    m = re.search(r"var LAWS=(\{.*?\});\s*var RB=", text, re.S)
    return json.loads(m.group(1))


def module_object(text: str, key: str) -> dict:
    """A flat {Name: number, …} literal from RB, such as health or pages."""
    m = re.search(key + r":\{([^{}]*)\}", text)
    return {k: float(v) for k, v in re.findall(r"(\w+):([\d.]+)", m.group(1))}


def compare(text: str) -> list[tuple[str, str, str, str]]:
    """(what, the module, content/, on record) for every difference."""
    out = []
    laws = {l["name"]: l for l in json.loads((CONTENT / "laws.json").read_text(encoding="utf-8"))}
    mod = module_laws(text)
    launch = {n for n, l in laws.items() if l.get("launch")}
    names = {l["name"] for l in mod.values()}
    for n in sorted(names - launch):
        out.append((f"{n}", "a launch law", "not a launch law", ""))
    for n in sorted(launch - names):
        out.append((f"{n}", "missing", "a launch law", ""))
    for l in mod.values():
        c = laws.get(l["name"])
        if not c:
            continue
        for field, theirs, ours in (("school", l["school"], c["school"]),
                                    ("rank", l["rank"], c["rank"]),
                                    ("stability cost", l["cost"], c["stability_cost"]),
                                    ("notes", l["notes"], c["notes"])):
            if theirs != ours:
                out.append((f"{l['name']}’s {field}", str(theirs), str(ours), ""))
    roles = {r["name"]: r for r in json.loads((CONTENT / "roles.json").read_text(encoding="utf-8"))}
    for name, hp in module_object(text, "health").items():
        if name in roles and roles[name]["health"] != hp:
            out.append((f"{name} health", f"{hp:g}", f"{roles[name]['health']:g}",
                        KNOWN["role health"]))
    constants = json.loads((CONTENT / "upstream/constants.json").read_text(encoding="utf-8"))
    pages = [int(n) for n in re.findall(r"\d+", str(constants["page_costs"]["value"]))]
    theirs = [int(v) for v in module_object(text, "pages").values()]
    if theirs != pages:
        out.append(("Pages to restore, by rank", str(theirs), str(pages), ""))
    return out


def report(rows: list[tuple[str, str, str, str]]) -> str:
    lines = ["# The prototype's data module against content/", "",
             "Written by `tools/compare_module.py` from the handoff's "
             "`prototype/ruleborn-data.js` (md5 in [data/prototype.md5](data/prototype.md5)). "
             "§23.5: the module is not a source, so each difference is the module's "
             "to correct, and the build reads content/.", "",
             "The module holds the 24 launch laws (name, school, rank, cost, notes) and "
             "a handful of constants. It has no realms, links, crew or Sages, so those "
             "have nothing to compare.", ""]
    if not rows:
        lines.append("No differences.")
    else:
        lines += ["| What | The module | content/ | On record |", "| --- | --- | --- | --- |"]
        lines += [f"| {a} | {b} | {c} | {d or '**new**'} |" for a, b, c, d in rows]
    return "\n".join(lines) + "\n"


def main(argv: list[str]) -> int:
    if not argv or argv[0].startswith("-"):
        print(__doc__)
        return 2
    rows = compare(read_module(pathlib.Path(argv[0])))
    text = report(rows)
    if "--write" in argv:
        REPORT.write_text(text, encoding="utf-8")
        print(f"wrote {REPORT.relative_to(ROOT)}")
    print(text)
    return 0


if __name__ == "__main__":
    raise SystemExit(main(sys.argv[1:]))
