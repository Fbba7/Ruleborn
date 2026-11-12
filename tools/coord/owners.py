#!/usr/bin/env python3
"""Who owns a path, and whether a change stays inside its task's files.

    python3 tools/coord/owners.py diff <task_id> <base> <head>
    python3 tools/coord/owners.py claims
    python3 tools/coord/owners.py owner <path>
    python3 tools/coord/owners.py --self-test

Backlog task BT-02 (docs/guides/agent-protocol.md, "The merge queue").

Why this exists
---------------
One owner per file: a task may change only the paths in its `files`, and the
tasks in flight at the same time have disjoint `files`. Until now the lead
compared `git diff --name-only` against the globs by eye, which is exactly the
check that gets skipped on the fifth candidate of the day.

- `diff` lists every path changed between `base...head` that the task does
  not own, and exits 1 if there is one. A task owns its `files`, the
  `exceptions` the lead granted on it, its agent's own status and
  progress files, and the pages `tools/check_all.sh` regenerates. A rename
  counts as both its paths, and no task owns an instruction file
  (`CLAUDE.md`, `AGENTS.md`, `CLAUDE.local.md`, anything under `.claude/`).
- `claims` exits 1 if two tasks in flight have `files` that can match the
  same path.
- `owner` names the in-flight task (and agent) whose `files` cover a path.

Globs: `**` is any number of path segments (including none), `*` and `?`
stay inside one segment. A pattern starting `!` removes paths from the ones
before it: `["art/ui/**", "!art/ui/icons/**"]`.

`--backlog <path>` reads another backlog than docs/progress/backlog.json.
"""

import fnmatch
import json
import pathlib
import re
import subprocess
import sys

ROOT = pathlib.Path(__file__).resolve().parent.parent.parent
BACKLOG = ROOT / "docs" / "progress" / "backlog.json"

#: The states in which a task holds its files.
IN_FLIGHT = {"claimed", "working", "ready", "resync", "blocked", "parked"}

#: What tools/check_all.sh rewrites; docs/guides/checks.md has the agent
#: commit them after a green run, so every task may change them.
GENERATED = [
    "sim/status.json", "server/status.json", "client/status.json",
    "docs/design/dependencies.md", "docs/audit/index.html", "docs/roadmap/index.html",
]


def _match_segments(pat: list, path: list) -> bool:
    if not pat:
        return not path
    if pat[0] == "**":
        return any(_match_segments(pat[1:], path[i:]) for i in range(len(path) + 1))
    if not path:
        return False
    return fnmatch.fnmatchcase(path[0], pat[0]) and _match_segments(pat[1:], path[1:])


def matches(pattern: str, path: str) -> bool:
    """True if the repository path matches the glob."""
    return _match_segments(pattern.strip("/").split("/"), path.strip("/").split("/"))


def owned(files: list, path: str) -> bool:
    """True if the path is in the set the list describes, negations applied."""
    inside = False
    for pattern in files:
        if pattern.startswith("!"):
            if inside and matches(pattern[1:], path):
                inside = False
        elif matches(pattern, path):
            inside = True
    return inside


def _wild(segment: str) -> bool:
    return any(c in segment for c in "*?[")


def _segments_meet(a: str, b: str) -> bool:
    """Can one path segment match both patterns? Errs towards yes."""
    if not _wild(a):
        return fnmatch.fnmatchcase(a, b)
    if not _wild(b):
        return fnmatch.fnmatchcase(b, a)
    head_a, head_b = a.split("*")[0], b.split("*")[0]
    tail_a, tail_b = a.split("*")[-1], b.split("*")[-1]
    heads = head_a.startswith(head_b) or head_b.startswith(head_a)
    tails = tail_a.endswith(tail_b) or tail_b.endswith(tail_a)
    return heads and tails


def _meet(a: list, b: list) -> bool:
    if not a or not b:
        return all(x == "**" for x in a + b)
    if a[0] == "**":
        return _meet(a[1:], b) or _meet(a, b[1:])
    if b[0] == "**":
        return _meet(a, b[1:]) or _meet(a[1:], b)
    return _segments_meet(a[0], b[0]) and _meet(a[1:], b[1:])


def overlap(a: str, b: str) -> bool:
    """True if some path can match both globs."""
    return _meet(a.strip("/").split("/"), b.strip("/").split("/"))


def _covered(negations: list, pattern: str) -> bool:
    """True if a negation removes every path the pattern can match."""
    pat = pattern.strip("/").split("/")
    for neg in negations:
        if neg == pattern:
            return True
        segs = neg.strip("/").split("/")
        if segs[-1] == "**" and len(pat) >= len(segs) - 1:
            prefix = segs[:-1]
            if all(p == n or (not _wild(p) and fnmatch.fnmatchcase(p, n))
                   for p, n in zip(pat, prefix)):
                return True
        elif not any(_wild(p) for p in pat) and matches(neg, pattern):
            return True
    return False


def files_overlap(a: list, b: list) -> list:
    """The pairs of positive globs that can match one path in both sets."""
    neg_a = [p[1:] for p in a if p.startswith("!")]
    neg_b = [p[1:] for p in b if p.startswith("!")]
    pairs = []
    for pa in (p for p in a if not p.startswith("!")):
        for pb in (p for p in b if not p.startswith("!")):
            if not overlap(pa, pb):
                continue
            if _covered(neg_a, pb) or _covered(neg_b, pa):
                continue
            pairs.append((pa, pb))
    return pairs


def agent_of(task: dict):
    claim = task.get("claim") or {}
    return claim.get("agent") or task.get("assigned_to")


def allowed(task: dict) -> list:
    """Everything the task may change."""
    files = list(task.get("files", [])) + list(task.get("exceptions", [])) + GENERATED
    agent = agent_of(task)
    if agent:
        files += [f"docs/progress/status/{agent}.json", f"docs/progress/{agent}.md"]
    return files


#: The agents' instruction files, which no task may change whatever its
#: globs: only the owner changes them (SEC-46).
INSTRUCTION = re.compile(r"(^|/)(CLAUDE\.md|AGENTS\.md|CLAUDE\.local\.md)$|(^|/)\.claude/")


def unowned(task: dict, changed: list) -> list:
    files = allowed(task)
    return [p for p in changed if INSTRUCTION.search(p) or not owned(files, p)]


def changed(base: str, head: str, cwd=ROOT) -> list:
    """Every path `base...head` changes, deletes or adds."""
    # A rename is listed as its old path and its new one, so both are checked
    # (SEC-27): with rename detection, the path renamed away was not shown.
    out = subprocess.run(["git", "diff", "--name-only", "--no-renames", f"{base}...{head}"],
                         cwd=cwd, capture_output=True, text=True, check=True).stdout
    return [p for p in out.splitlines() if p]


def _renamed_away() -> list:
    """`owners.py diff` on a temporary repository where a builder owning
    client/ui/ moved CLAUDE.md into it (SEC-27)."""
    import os
    import tempfile
    env = {**os.environ, "GIT_CONFIG_GLOBAL": os.devnull, "GIT_CONFIG_NOSYSTEM": "1"}
    with tempfile.TemporaryDirectory() as tmp:
        def git(*args):
            subprocess.run(["git", "-c", "user.name=t", "-c", "user.email=t@example.invalid",
                            "-c", f"core.hooksPath={os.devnull}", *args],
                           cwd=tmp, env=env, capture_output=True, check=True)
        git("init", "-q", "-b", "base")
        (pathlib.Path(tmp) / "CLAUDE.md").write_text("# orders\n" * 20)
        (pathlib.Path(tmp) / "client" / "ui").mkdir(parents=True)
        (pathlib.Path(tmp) / "client" / "ui" / "kit.gd").write_text("extends Node\n")
        git("add", "-A")
        git("commit", "-q", "-m", "base")
        git("checkout", "-q", "-b", "head")
        git("mv", "CLAUDE.md", "client/ui/notes.md")
        git("commit", "-q", "-m", "a rename")
        task = {"id": "T", "files": ["client/ui/**"], "assigned_to": "K1"}
        return unowned(task, changed("base", "head", cwd=tmp))


def clashes(tasks: list) -> list:
    """(task, task, glob, glob) for every overlap between tasks in flight."""
    live = [t for t in tasks if t.get("state") in IN_FLIGHT]
    found = []
    for i, a in enumerate(live):
        for b in live[i + 1:]:
            for pa, pb in files_overlap(a.get("files", []), b.get("files", [])):
                found.append((a["id"], b["id"], pa, pb))
    return found


def load(path: pathlib.Path) -> dict:
    return json.loads(path.read_text())


def _task(backlog: dict, task_id: str) -> dict:
    for t in backlog.get("tasks", []) + backlog.get("idle_queue", []):
        if t.get("id") == task_id:
            return t
    raise SystemExit(f"no task {task_id} in the backlog")


def self_test() -> None:
    # A glob match: ** spans segments, * stays in one.
    assert matches("tools/ui_gate/**", "tools/ui_gate/sheet.py")
    assert matches("tools/ui_gate/**", "tools/ui_gate/a/b/c.py")
    assert matches("tools/coord/owners.*", "tools/coord/owners.py")
    assert not matches("tools/coord/owners.*", "tools/coord/sub/owners.py")
    assert matches("docs/**/shots.json", "docs/shots.json")
    assert matches("docs/**/shots.json", "docs/gate/a/shots.json")
    assert not matches("client/ui/*.gd", "client/ui/art/x.gd")
    # Negation.
    art = ["art/ui/**", "!art/ui/icons/**"]
    assert owned(art, "art/ui/board/board.html")
    assert not owned(art, "art/ui/icons/coin.svg")
    # An unowned path, and the agent's own status file always allowed.
    task = {"id": "T", "files": ["tools/ui_gate/**"], "assigned_to": "AD"}
    changed = ["tools/ui_gate/sheet.py", "docs/progress/status/AD.json",
               "docs/progress/AD.md", "docs/audit/index.html", "client/project.godot"]
    assert unowned(task, changed) == ["client/project.godot"], unowned(task, changed)
    task["exceptions"] = ["client/project.godot"]
    assert unowned(task, changed) == []
    # SEC-27: the source side of a rename is checked too.
    assert _renamed_away() == ["CLAUDE.md"], _renamed_away()
    # SEC-46: no task's globs reach an instruction file.
    ui = {"id": "U", "files": ["client/ui/**", ".claude/**"], "assigned_to": "K1"}
    for path in ["client/ui/CLAUDE.md", "AGENTS.md", "client/ui/AGENTS.md",
                 "client/ui/CLAUDE.local.md", ".claude/settings.json", "client/ui/.claude/x.md"]:
        assert unowned(ui, [path]) == [path], path
    assert unowned(ui, ["client/ui/claude.md.import", "client/ui/kit.gd"]) == []
    # Overlapping claims.
    assert overlap("client/ui/**", "client/ui/art/**")
    assert overlap("client/**/*.gd", "client/ui/kit.gd")
    assert overlap("tools/coord/owners.*", "tools/coord/**")
    assert not overlap("tools/ui_gate/**", "tools/ui_bake/**")
    assert not overlap("client/ui/*.gd", "client/ui/art/**")
    assert not overlap("docs/a.md", "docs/b.md")
    k1 = ["client/ui/**", "!client/ui/art/**"]
    aia = ["art/ui/**", "!art/ui/icons/**", "client/ui/art/**"]
    assert files_overlap(k1, aia) == [], files_overlap(k1, aia)
    assert files_overlap(["client/ui/**"], aia) == [("client/ui/**", "client/ui/art/**")]
    assert files_overlap(["art/ui/icons/**"], aia) == []
    assert files_overlap(["art/ui/icons/a.svg"], aia) == []
    assert files_overlap(["art/ui/*/a.svg"], aia) == [("art/ui/*/a.svg", "art/ui/**")]
    tasks = [
        {"id": "A", "state": "working", "files": ["tools/ui_gate/**"]},
        {"id": "B", "state": "claimed", "files": ["tools/**"]},
        {"id": "C", "state": "open", "files": ["tools/**"]},
        {"id": "D", "state": "merged", "files": ["tools/ui_gate/**"]},
    ]
    assert clashes(tasks) == [("A", "B", "tools/ui_gate/**", "tools/**")], clashes(tasks)
    # The live backlog, when there is one, has no clash.
    if BACKLOG.exists():
        live = clashes(load(BACKLOG)["tasks"])
        assert not live, live
    print("owners.py self-test: ok")


def main(argv: list) -> int:
    if "--self-test" in argv:
        self_test()
        return 0
    backlog_path = BACKLOG
    if "--backlog" in argv:
        i = argv.index("--backlog")
        backlog_path = pathlib.Path(argv[i + 1])
        argv = argv[:i] + argv[i + 2:]
    if not argv:
        print(__doc__)
        return 2
    backlog = load(backlog_path)
    cmd = argv[0]
    if cmd == "diff" and len(argv) == 4:
        task = _task(backlog, argv[1])
        bad = unowned(task, changed(argv[2], argv[3]))
        for p in bad:
            print(f"not owned by {task['id']}: {p}")
        if not bad:
            print(f"{task['id']}: every changed path is inside its files")
        return 1 if bad else 0
    if cmd == "claims" and len(argv) == 1:
        found = clashes(backlog.get("tasks", []))
        for a, b, pa, pb in found:
            print(f"{a} ({pa}) and {b} ({pb}) can both change one path")
        if not found:
            print("tasks in flight have disjoint files")
        return 1 if found else 0
    if cmd == "owner" and len(argv) == 2:
        hits = [t for t in backlog.get("tasks", [])
                if t.get("state") in IN_FLIGHT and owned(t.get("files", []), argv[1])]
        for t in hits:
            print(f"{t['id']} ({agent_of(t) or 'unassigned'})")
        if not hits:
            print("no task in flight owns it: the lead does")
        return 0
    print(__doc__)
    return 2


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
