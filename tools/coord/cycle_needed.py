#!/usr/bin/env python3
"""Whether a lead cycle has anything to do this hour.

    python3 tools/coord/cycle_needed.py                  # decide
    python3 tools/coord/cycle_needed.py heads > <file>   # cycle step 1
    python3 tools/coord/cycle_needed.py record <file>    # cycle step 7
    python3 tools/coord/cycle_needed.py --self-test

Docs: docs/guides/agent-protocol.md, "The coordinator and the lead".

Why this exists
---------------
The launcher starts a lead cycle every hour, and each cycle reads about
120k tokens before it knows whether anything changed. Most quiet hours
nothing did: no branch moved, nothing is ready, no message waits. So each
cycle runs this script first (lead.md, "Running a cycle", step 0) and ends
at once when it exits 3. A launcher may run the same check before it
creates the cycle's session.

`decide` (no argument) exits 0 and prints the reasons when a cycle is
needed, and exits 3 with "nothing new since <time>" when it is not. Any
other exit, a crash included, means "run the cycle": the check fails open,
so a bug in it can cost tokens but never a stalled program.

A cycle is needed when any of these holds:

- a branch head (every branch on origin except main) differs from the one
  the last cycle recorded, or no cycle recorded any;
- `merging` is set in status/lead.json (a cycle that starts while the
  lock is set finds the previous cycle not working, so that cycle died
  holding the lock);
- something needs the lead that the last cycle had not seen: a `ready` task
  (with its `ready_sha`), a task an agent can start, a message to the lead
  it has not acknowledged, a request past its `due` with no answer, a lapsed
  claim lease, or an `active` agent whose `expected_next_update_by` passed
  (once when seen, and once more after 90 minutes);
- main has a commit after the last change to status/lead.json that touches
  CLAUDE.md, docs/guides/, docs/decisions/, docs/progress/requests.md,
  docs/art/ui-quality/, or docs/progress/backlog.json other than its
  `messages` (new messages are the item above);
- the heartbeat: `expected_next_update_by` is missing or under 20 minutes
  away, or `updated_at` is more than 3 hours old.

`heads` prints the branch heads as JSON; the lead saves them at step 1, so a
push that lands during the cycle is still new to the next one. `record`
writes `seen` into status/lead.json: those heads plus what needs the lead
in the tree as it stands at step 7, after the lead's own changes.
"""

import argparse
import datetime as dt
import json
import pathlib
import re
import subprocess
import sys

ROOT = pathlib.Path(__file__).resolve().parent.parent.parent
BACKLOG = ROOT / "docs" / "progress" / "backlog.json"
LEAD = ROOT / "docs" / "progress" / "status" / "lead.json"
REQUESTS = ROOT / "docs" / "progress" / "requests.md"
MAIN = "claude/videogame-project-analysis-ewkkk2"

#: Paths on main whose change after the lead's last write needs a cycle.
WATCHED = ("CLAUDE.md", "docs/guides/", "docs/decisions/",
           "docs/progress/requests.md", "docs/art/ui-quality/")
#: A request counts as answered once its entry carries one of these.
CLOSED = re.compile(r"\*\*(Answered|Default applied|Applied|Default stands|"
                    r"Recorded|Approved|Done|Granted)\*\*")
MONTHS = {m: i + 1 for i, m in enumerate(
    "January February March April May June July August September October "
    "November December".split())}
BUSY = {"claimed", "working"}
NOT_SEATS = {None, "lead"}
LATE_MINUTES = 90
EXIT_SKIP = 3


def _now() -> dt.datetime:
    return dt.datetime.now(dt.timezone.utc)


def _ts(value):
    if not value:
        return None
    try:
        return dt.datetime.fromisoformat(str(value).replace("Z", "+00:00"))
    except ValueError:
        return None


def _iso(t: dt.datetime) -> str:
    return t.astimezone(dt.timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ")


def _git(*args) -> str:
    return subprocess.run(["git", *args], cwd=ROOT, check=True,
                          capture_output=True, text=True).stdout


# --- what needs the lead ---------------------------------------------------

def requests_due(text: str, now: dt.datetime) -> list:
    """Ids of the open requests past `due` with no answer."""
    m = re.search(r"^## Open\s*$", text, re.M)
    if not m:
        return []
    body = text[m.end():]
    nxt = re.search(r"^## ", body, re.M)
    body = body[:nxt.start()] if nxt else body
    out = []
    for entry in re.split(r"\n(?=- \*\*)", body):
        head = re.match(r"- \*\*([^*]+)\*\*", entry)
        if not head or CLOSED.search(entry):
            continue
        flat = " ".join(entry.split())
        made = re.search(r"(\d{1,2}) (%s) (\d{4})" % "|".join(MONTHS), flat)
        year = int(made.group(3)) if made else now.year
        due = re.search(r"\bdue (?:(\d{1,2}) (%s)(?: (\d{4}))?,? )?(\d{1,2}):(\d{2})Z"
                        % "|".join(MONTHS), flat)
        if not due:
            continue
        if due.group(1):
            day, month = int(due.group(1)), MONTHS[due.group(2)]
            year = int(due.group(3) or year)
        elif made:
            day, month = int(made.group(1)), MONTHS[made.group(2)]
        else:
            continue
        try:
            when = dt.datetime(year, month, day, int(due.group(4)), int(due.group(5)),
                               tzinfo=dt.timezone.utc)
        except ValueError:
            continue
        if when <= now:
            out.append(head.group(1).strip())
    return sorted(out)


def needs(backlog: dict, lead: dict, statuses: dict, request_text: str,
          now: dt.datetime) -> dict:
    """What needs the lead, as sets of ids (JSON-friendly)."""
    tasks = backlog.get("tasks", [])
    state = {t["id"]: t.get("state") for t in tasks}
    archived = set(backlog.get("_archived", ()))  # merged, moved by archive.py
    roster = set(backlog.get("agents", {}))
    busy = {t.get("assigned_to") for t in tasks if t.get("state") in BUSY}
    seats = {a for a in busy if a in roster}
    seats |= {a for a, s in statuses.items()
              if a in roster and (s or {}).get("agent_state") == "active"}
    cap = backlog.get("building_cap", 4)
    startable = []
    for t in tasks:
        agent = t.get("assigned_to")
        if t.get("state") != "open" or agent not in roster or agent in busy:
            continue
        if any(state.get(d) != "merged" and d not in archived
               for d in t.get("deps", [])):
            continue
        if agent not in seats and len(seats) >= cap:
            continue
        startable.append(t["id"])
    acks = set(lead.get("acks", []))
    messages = [m["id"] for m in backlog.get("messages", [])
                if m.get("to") == "lead" and m["id"] not in acks]
    leases = []
    for t in tasks:
        until = _ts((t.get("claim") or {}).get("lease_until"))
        if t.get("state") in BUSY and until and until < now:
            leases.append(f"{t['id']}@{_iso(until)}")
    stale = []
    for agent, s in sorted(statuses.items()):
        due = _ts((s or {}).get("expected_next_update_by"))
        if (s or {}).get("agent_state") == "active" and due and due < now:
            stale.append(f"{agent}@{_iso(due)}")
            if now - due > dt.timedelta(minutes=LATE_MINUTES):
                stale.append(f"{agent}@{_iso(due)}+late")
    return {
        "ready": {t["id"]: t.get("ready_sha") for t in tasks if t.get("state") == "ready"},
        "startable": sorted(startable),
        "messages": sorted(messages),
        "requests": requests_due(request_text, now),
        "leases": sorted(leases),
        "stale": stale,
    }


def reasons(lead: dict, heads: dict, found: dict, main_changes: list,
            now: dt.datetime) -> list:
    """Why a cycle is needed; empty when it is not."""
    out = []
    seen = lead.get("seen")
    if not isinstance(seen, dict) or not isinstance(seen.get("heads"), dict):
        return ["no cycle recorded what it saw"]
    if lead.get("merging"):
        out.append("the merge lock is set but no cycle is working")
    old = seen["heads"]
    for branch in sorted(set(heads) | set(old)):
        if heads.get(branch) != old.get(branch):
            out.append(f"branch {branch} moved")
    for tid, sha in sorted(found["ready"].items()):
        if seen.get("ready", {}).get(tid) != sha:
            out.append(f"task {tid} is ready at {str(sha)[:8]}")
    for key, what in (("startable", "task {} can start"),
                      ("messages", "message {} is not acknowledged"),
                      ("requests", "request {} is past due"),
                      ("leases", "lease {} lapsed"),
                      ("stale", "agent {} is late")):
        for item in found[key]:
            if item not in set(seen.get(key, [])):
                out.append(what.format(item))
    for change in main_changes:
        out.append(f"main changed: {change}")
    due, updated = _ts(lead.get("expected_next_update_by")), _ts(lead.get("updated_at"))
    if not due or due - now < dt.timedelta(minutes=20):
        out.append("heartbeat: expected_next_update_by is near or past")
    elif not updated or now - updated > dt.timedelta(hours=3):
        out.append("heartbeat: the last cycle is over 3 hours old")
    return out


# --- reading the repository ------------------------------------------------

def remote_heads() -> dict:
    out = {}
    for line in _git("ls-remote", "--heads", "origin").splitlines():
        sha, ref = line.split("\t")
        branch = ref[len("refs/heads/"):]
        if branch != MAIN:
            out[branch] = sha
    return out


def roster_statuses(backlog: dict, heads: dict) -> dict:
    out = {}
    for agent, info in backlog.get("agents", {}).items():
        branch = info.get("branch")
        if branch not in heads:
            continue
        try:
            _git("fetch", "-q", "origin", f"+refs/heads/{branch}:refs/remotes/origin/{branch}")
            out[agent] = json.loads(_git("show", f"origin/{branch}:docs/progress/status/{agent}.json"))
        except (subprocess.CalledProcessError, json.JSONDecodeError):
            out[agent] = None
    return out


def main_changes() -> list:
    """Commits after the last change to lead.json that need the lead."""
    rel = str(LEAD.relative_to(ROOT))
    last = _git("log", "-1", "--format=%H", "--", rel).strip()
    if not last:
        return []
    out = []
    for sha in _git("rev-list", "--reverse", f"{last}..HEAD").split():
        paths = _git("diff-tree", "--no-commit-id", "--name-only", "-r", sha).split()
        hit = [p for p in paths if p.startswith(WATCHED)]
        if "docs/progress/backlog.json" in paths and _backlog_beyond_messages(sha):
            hit.append("docs/progress/backlog.json")
        if hit:
            out.append(f"{sha[:8]} {', '.join(sorted(hit)[:3])}")
    return out


def _backlog_beyond_messages(sha: str) -> bool:
    try:
        new = json.loads(_git("show", f"{sha}:docs/progress/backlog.json"))
        old = json.loads(_git("show", f"{sha}^:docs/progress/backlog.json"))
    except (subprocess.CalledProcessError, json.JSONDecodeError):
        return True
    for d in (new, old):
        d.pop("messages", None)
        d.pop("updated_at", None)
        d.pop("updated_by", None)
    return new != old


def _load_tree(now):
    backlog = json.loads(BACKLOG.read_text())
    archive = BACKLOG.parent / "backlog-archive.json"
    if archive.exists():
        old = json.loads(archive.read_text())
        backlog["_archived"] = [t["id"] for t in old.get("tasks", [])
                                + old.get("idle_queue", [])]
    lead = json.loads(LEAD.read_text())
    text = REQUESTS.read_text() if REQUESTS.exists() else ""
    return backlog, lead, text


def cmd_decide() -> int:
    now = _now()
    backlog, lead, text = _load_tree(now)
    heads = remote_heads()
    found = needs(backlog, lead, roster_statuses(backlog, heads), text, now)
    why = reasons(lead, heads, found, main_changes(), now)
    if why:
        print("cycle needed:")
        for line in why:
            print(f"- {line}")
        return 0
    print(f"nothing new since {lead.get('seen', {}).get('at')}")
    return EXIT_SKIP


def cmd_heads() -> int:
    print(json.dumps(remote_heads(), indent=1, sort_keys=True))
    return 0


def cmd_record(heads_file: str) -> int:
    now = _now()
    heads = json.loads(pathlib.Path(heads_file).read_text())
    backlog, lead, text = _load_tree(now)
    found = needs(backlog, lead, roster_statuses(backlog, remote_heads()), text, now)
    lead["seen"] = {"at": _iso(now), "heads": heads, **found}
    LEAD.write_text(json.dumps(lead, indent=2) + "\n")
    print(f"recorded seen at {_iso(now)}: {len(heads)} heads, "
          f"{sum(len(v) for v in found.values())} items")
    return 0


# --- self-test --------------------------------------------------------------

def self_test() -> int:
    now = dt.datetime(2026, 11, 17, 12, 0, tzinfo=dt.timezone.utc)
    fails = []

    def check(name, cond):
        if not cond:
            fails.append(name)

    text = "\n".join([
        "# Requests", "", "## Open", "",
        "- **S1-R1** (from S1, 16 November 2026 10:00Z; due 17 November",
        "  11:00Z; not blocking): past, open.",
        "- **S1-R2** (from S1, 16 November 2026; due 17 November 13:00Z): future.",
        "- **S1-R3** (from S1, 17 November 2026 08:00Z; due 09:00Z): time only, past.",
        "- **S1-R4** (from S1, 16 November 2026; due 16 November 20:00Z): answered.",
        "  **Answered** (cycle 9): done.",
        "- **S1-R5** (from S1): no due.",
        "", "## Done", "",
        "- **S1-R6** (from S1, 1 November 2026; due 2 November 10:00Z): closed section.",
    ])
    check("requests_due", requests_due(text, now) == ["S1-R1", "S1-R3"])

    backlog = {
        "building_cap": 2,
        "_archived": ["z"],
        "agents": {"S1": {}, "S2": {}, "S3": {}},
        "tasks": [
            {"id": "a", "state": "merged", "assigned_to": "S1"},
            {"id": "b", "state": "claimed", "assigned_to": "S1",
             "claim": {"lease_until": "2026-11-17T11:00:00Z"}},
            {"id": "c", "state": "open", "assigned_to": "S1", "deps": ["a"]},
            {"id": "d", "state": "open", "assigned_to": "S2", "deps": ["a", "z"]},
            {"id": "e", "state": "open", "assigned_to": "S3", "deps": ["b"]},
            {"id": "f", "state": "ready", "assigned_to": "S2", "ready_sha": "abc"},
            {"id": "g", "state": "open", "assigned_to": "SP-x"},
        ],
        "messages": [{"id": "M1", "to": "lead"}, {"id": "M2", "to": "lead"},
                     {"id": "M3", "to": "S1"}],
    }
    lead = {"acks": ["M1"], "updated_at": "2026-11-17T11:00:00Z",
            "expected_next_update_by": "2026-11-17T14:00:00Z", "merging": None}
    statuses = {"S1": {"agent_state": "active",
                       "expected_next_update_by": "2026-11-17T10:00:00Z"},
                "S2": {"agent_state": "waiting"}, "S3": None}
    found = needs(backlog, lead, statuses, text, now)
    check("ready", found["ready"] == {"f": "abc"})
    # c: its agent is busy on b; e: its dep is not merged; g: not on the roster.
    check("startable", found["startable"] == ["d"])
    check("messages", found["messages"] == ["M2"])
    check("leases", found["leases"] == ["b@2026-11-17T11:00:00Z"])
    check("stale", found["stale"] == ["S1@2026-11-17T10:00:00Z",
                                      "S1@2026-11-17T10:00:00Z+late"])
    backlog["building_cap"] = 1
    check("cap", needs(backlog, lead, statuses, text, now)["startable"] == [])
    backlog["building_cap"] = 2

    heads = {"claude/ui-bake": "1" * 40}
    check("no seen", reasons(lead, heads, found, [], now) == ["no cycle recorded what it saw"])
    lead["seen"] = {"at": "x", "heads": dict(heads), **json.loads(json.dumps(found))}
    check("quiet", reasons(lead, heads, found, [], now) == [])
    check("moved", reasons(lead, {"claude/ui-bake": "2" * 40}, found, [], now)
          == ["branch claude/ui-bake moved"])
    check("new branch", reasons(lead, {**heads, "x": "3"}, found, [], now)
          == ["branch x moved"])
    more = json.loads(json.dumps(found))
    more["ready"]["f"] = "def"
    more["messages"].append("M9")
    check("new items", len(reasons(lead, heads, more, [], now)) == 2)
    fewer = {**found, "messages": []}
    check("gone items stay quiet", reasons(lead, heads, fewer, [], now) == [])
    check("main", reasons(lead, heads, found, ["abcd1234 CLAUDE.md"], now)
          == ["main changed: abcd1234 CLAUDE.md"])
    check("lock", reasons({**lead, "merging": {"x": 1}}, heads, found, [], now)
          == ["the merge lock is set but no cycle is working"])
    near = {**lead, "expected_next_update_by": "2026-11-17T12:10:00Z"}
    check("heartbeat near", len(reasons(near, heads, found, [], now)) == 1)
    old = {**lead, "updated_at": "2026-11-17T08:30:00Z"}
    check("heartbeat old", len(reasons(old, heads, found, [], now)) == 1)
    check("heartbeat missing",
          len(reasons({**lead, "expected_next_update_by": None}, heads, found, [], now)) == 1)

    if fails:
        print("self-test FAILED: " + ", ".join(fails))
        return 1
    print("self-test passed")
    return 0


def main(argv=None) -> int:
    ap = argparse.ArgumentParser(description=__doc__.split("\n")[0])
    ap.add_argument("command", nargs="?", choices=["heads", "record"])
    ap.add_argument("file", nargs="?")
    ap.add_argument("--self-test", action="store_true")
    args = ap.parse_args(argv)
    if args.self_test:
        return self_test()
    if args.command == "heads":
        return cmd_heads()
    if args.command == "record":
        if not args.file:
            ap.error("record needs the heads file saved at step 1")
        return cmd_record(args.file)
    try:
        return cmd_decide()
    except Exception as exc:  # fail open: the cycle runs in full
        print(f"check failed ({exc!r}); run the cycle")
        return 1


if __name__ == "__main__":
    sys.exit(main())
