#!/usr/bin/env python3
"""Move finished work out of the two files every cycle reads.

    python3 tools/coord/archive.py            # move, then print what moved
    python3 tools/coord/archive.py --check    # exit 1 if anything would move
    python3 tools/coord/archive.py --self-test

Docs: docs/guides/agent-protocol.md, "One cycle", step 7.

Why this exists
---------------
Every lead cycle reads docs/progress/backlog.json and docs/progress/lead.md
in full. By cycle 108 they held 100 merged tasks and 112 "Now" entries,
about 470 kB that the cycle reads for nothing: a merged task never changes
again, and an old "Now" entry is history. This script moves them to two
archive files. Nothing is deleted, and both moves are idempotent, so the
lead runs it at step 7 of every cycle, after rebasing onto main.

backlog.json -> docs/progress/backlog-archive.json
  A `merged` task moves unless a task that is not merged lists it in
  `deps` (that task's check still reads it). Merged `idle_queue` entries
  move too. Messages, agents and settings stay. The archive is a JSON
  object {"tasks": [...], "idle_queue": [...]}, oldest first;
  tools/coord/owners.py and tools/coord/cycle_needed.py read it, so a dep
  or a `diff <task_id>` on an archived task still works.

lead.md "## Now" -> docs/progress/lead-archive.md
  The first KEEP entries stay, and so do the pinned ones (the entries
  CLAUDE.md links to: "Stopped here", "Restart, ...", "After the stop",
  "The stop"). The others move to the top of the archive's "## Now
  (archived)" list, newest first, in the order they stood. An entry is a
  line starting "- " at the left margin, with everything up to the next.
"""

import argparse
import json
import pathlib
import re
import sys
import tempfile

ROOT = pathlib.Path(__file__).resolve().parent.parent.parent
PROGRESS = ROOT / "docs" / "progress"
BACKLOG = PROGRESS / "backlog.json"
BACKLOG_ARCHIVE = PROGRESS / "backlog-archive.json"
LEAD = PROGRESS / "lead.md"
LEAD_ARCHIVE = PROGRESS / "lead-archive.md"

KEEP = 3
PINNED = re.compile(r"- \*{0,2}(Stopped here\b|Restart,|After the stop\b|The stop\b)")
NOW = "## Now\n"
ARCHIVED = "## Now (archived)\n"
LEAD_HEADER = (
    "# Lead: archived \"Now\" entries\n\n"
    "Entries moved out of [lead.md](lead.md) by `tools/coord/archive.py`,\n"
    "newest first. Nothing here is current; lead.md's \"Now\" is.\n\n"
    + ARCHIVED + "\n")


# --- backlog ----------------------------------------------------------------

def split_backlog(backlog: dict) -> tuple:
    """(kept backlog, moved tasks, moved idle entries)."""
    tasks = backlog.get("tasks", [])
    needed = {d for t in tasks if t.get("state") != "merged"
              for d in t.get("deps", [])}
    moved = [t for t in tasks if t.get("state") == "merged" and t["id"] not in needed]
    idle = backlog.get("idle_queue", [])
    moved_idle = [t for t in idle if t.get("state") == "merged"]
    kept = dict(backlog)
    kept["tasks"] = [t for t in tasks if t not in moved]
    if "idle_queue" in backlog:
        kept["idle_queue"] = [t for t in idle if t not in moved_idle]
    return kept, moved, moved_idle


def load_archive(path: pathlib.Path = BACKLOG_ARCHIVE) -> dict:
    if not path.exists():
        return {"_comment": "Merged tasks moved out of backlog.json by "
                            "tools/coord/archive.py, oldest first.",
                "tasks": [], "idle_queue": []}
    return json.loads(path.read_text())


def archived_ids(path: pathlib.Path = BACKLOG_ARCHIVE) -> set:
    a = load_archive(path)
    return {t["id"] for t in a.get("tasks", []) + a.get("idle_queue", [])}


def _dump(data) -> str:
    return json.dumps(data, indent=2, ensure_ascii=False) + "\n"


# --- lead.md ----------------------------------------------------------------

def split_now(text: str) -> tuple:
    """(head through "## Now\\n", entries, tail from the next "## ")."""
    start = text.index(NOW) + len(NOW)
    nxt = re.search(r"^## ", text[start:], re.M)
    end = start + nxt.start() if nxt else len(text)
    body = text[start:end]
    lead_in = re.match(r"(?:(?!- ).*\n)*", body).group(0)
    entries = re.split(r"(?m)^(?=- )", body[len(lead_in):])
    entries = [e for e in entries if e]
    return text[:start] + lead_in, entries, text[end:]


def split_lead(text: str) -> tuple:
    """(new lead.md text, moved entries)."""
    head, entries, tail = split_now(text)
    kept, moved = [], []
    for i, e in enumerate(entries):
        (kept if i < KEEP or PINNED.match(e) else moved).append(e)
    if not moved:
        return text, []
    body = "".join(kept)
    if not body.endswith("\n\n") and tail:
        body = body.rstrip("\n") + "\n\n"
    return head + body + tail, moved


def add_to_lead_archive(archive: str, moved: list) -> str:
    if not archive:
        archive = LEAD_HEADER
    at = archive.index(ARCHIVED) + len(ARCHIVED)
    rest = archive[at:].lstrip("\n")
    block = "".join(e if e.endswith("\n") else e + "\n" for e in moved)
    block = block.rstrip("\n") + "\n"
    return archive[:at] + "\n" + block + ("\n" + rest if rest else "")


# --- run --------------------------------------------------------------------

def run(root: pathlib.Path, write: bool) -> list:
    prog = root / "docs" / "progress"
    paths = {k: prog / v for k, v in (("b", "backlog.json"), ("ba", "backlog-archive.json"),
                                       ("l", "lead.md"), ("la", "lead-archive.md"))}
    report = []
    backlog = json.loads(paths["b"].read_text())
    kept, moved, moved_idle = split_backlog(backlog)
    if moved or moved_idle:
        report.append(f"backlog: {len(moved)} tasks, {len(moved_idle)} idle entries")
        if write:
            arc = load_archive(paths["ba"])
            have = {t["id"] for t in arc["tasks"] + arc.get("idle_queue", [])}
            arc["tasks"] += [t for t in moved if t["id"] not in have]
            arc.setdefault("idle_queue", []).extend(
                t for t in moved_idle if t["id"] not in have)
            paths["ba"].write_text(_dump(arc))
            paths["b"].write_text(_dump(kept))
    text = paths["l"].read_text()
    new, entries = split_lead(text)
    if entries:
        report.append(f"lead.md: {len(entries)} Now entries")
        if write:
            old = paths["la"].read_text() if paths["la"].exists() else ""
            paths["la"].write_text(add_to_lead_archive(old, entries))
            paths["l"].write_text(new)
    return report


def self_test() -> int:
    fails = []

    def check(name, cond):
        if not cond:
            fails.append(name)

    backlog = {"agents": {"S1": {}}, "messages": [{"id": "M1"}], "tasks": [
        {"id": "a", "state": "merged"},
        {"id": "b", "state": "merged"},
        {"id": "c", "state": "open", "deps": ["b"]},
        {"id": "d", "state": "merged", "deps": ["a"]},
    ], "idle_queue": [{"id": "i1", "state": "merged"}, {"id": "i2", "state": "open"}]}
    kept, moved, idle = split_backlog(backlog)
    check("merged unreferenced tasks move", [t["id"] for t in moved] == ["a", "d"])
    check("a dep of open work stays", [t["id"] for t in kept["tasks"]] == ["b", "c"])
    check("merged idle entries move", [t["id"] for t in idle] == ["i1"])
    check("messages stay", kept["messages"] == [{"id": "M1"}])

    lead = ("# Lead\n\nintro\n\n## Now\n\nNewest first.\n\n"
            "- cycle 5\n  more\n- cycle 4\n- cycle 3\n- cycle 2\n"
            "- **Stopped here** (x)\n  detail\n- Restart, 11 November (y)\n- cycle 1\n\n## Later\n\nend\n")
    new, entries = split_lead(lead)
    check("first KEEP and pinned stay",
          "- cycle 5\n  more\n- cycle 4\n- cycle 3\n- **Stopped here** (x)\n  detail\n"
          "- Restart, 11 November (y)\n\n## Later"
          in new)
    check("lead-in stays", "## Now\n\nNewest first.\n\n- cycle 5" in new)
    check("the rest moves", entries == ["- cycle 2\n", "- cycle 1\n\n"])
    check("idempotent", split_lead(new) == (new, []))
    arc = add_to_lead_archive("", entries)
    check("archive keeps order", arc.endswith(ARCHIVED + "\n- cycle 2\n- cycle 1\n"))
    arc2 = add_to_lead_archive(arc, ["- cycle 3\n"])
    check("newer moves go on top",
          arc2.endswith(ARCHIVED + "\n- cycle 3\n\n- cycle 2\n- cycle 1\n"))

    with tempfile.TemporaryDirectory() as tmp:
        prog = pathlib.Path(tmp) / "docs" / "progress"
        prog.mkdir(parents=True)
        (prog / "backlog.json").write_text(_dump(backlog))
        (prog / "lead.md").write_text(lead)
        first = run(pathlib.Path(tmp), write=True)
        second = run(pathlib.Path(tmp), write=True)
        check("run moves once", len(first) == 2 and second == [])
        arc = json.loads((prog / "backlog-archive.json").read_text())
        check("archive holds the moved tasks", [t["id"] for t in arc["tasks"]] == ["a", "d"])
        check("archived_ids reads it",
              archived_ids(prog / "backlog-archive.json") == {"a", "d", "i1"})

    # The live files parse the same way the moves assume.
    if LEAD.exists():
        head, entries, tail = split_now(LEAD.read_text())
        check("live lead.md has Now entries", len(entries) > 0)
        check("live split round-trips", head + "".join(entries) + tail == LEAD.read_text())
    if fails:
        print("archive self-test FAILED: " + ", ".join(fails))
        return 1
    print("archive self-test passed")
    return 0


def main(argv=None) -> int:
    p = argparse.ArgumentParser(description=__doc__.split("\n")[0])
    p.add_argument("--check", action="store_true")
    p.add_argument("--self-test", action="store_true")
    a = p.parse_args(argv)
    if a.self_test:
        return self_test()
    report = run(ROOT, write=not a.check)
    if a.check:
        print("would move: " + "; ".join(report) if report else "nothing to archive")
        return 1 if report else 0
    print("moved: " + "; ".join(report) if report else "nothing to archive")
    return 0


if __name__ == "__main__":
    sys.exit(main())
