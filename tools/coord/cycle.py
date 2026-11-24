#!/usr/bin/env python3
"""The coordinator's cycle, part 1: the bookkeeping steps, as a dry run.

    python3 tools/coord/cycle.py --dry-run              # print the actions
    python3 tools/coord/cycle.py --dry-run --json       # the same, as JSON
    python3 tools/coord/cycle.py --dry-run --out <file> # also the backlog it would write
    python3 tools/coord/cycle.py --self-test

Docs: docs/guides/agent-protocol.md, "The coordinator and the lead" ("One
cycle", steps 1 to 3 and the stall rule of step 6), and
docs/progress/lead.md, "Running a cycle".

What it does
------------
It fetches origin, reads the backlog, status/lead.json and requests.md from
main as origin has it (`origin/<main>`), and every roster agent's status
file from `origin/<its branch>` (the authoritative copy; copies on main are
history). Then it works out, without writing anything:

- **seen_at**: a status file that changed since the heads the last cycle
  recorded (`seen.heads` in status/lead.json) is seen now; otherwise the
  task's `claim.seen_at` stands, or, with none, the status commit's time.
- **leases**: a running lease (`claimed`, `working`, `resync`) is timed from
  `seen_at` (`lease_hours`, 3); one that has lapsed sends the task to
  `open`, with `prior_branch` and `prior_sha` when the branch holds work
  that main does not.
- **states**: each agent's `task_state` is copied into its task, with its
  lease into `claim` and its `ready_sha`, when the move is one the agent may
  make (the protocol's transitions). A state the agent may not set
  (`merged`, `resync`), a task that is not the agent's, or a move from a
  `merged` task is flagged, not copied.
- **next tasks**: the tasks an agent could start now, within the building
  cap (`cycle_needed.needs`), as "start" actions for the lead.
- **messages**: a message acknowledged in the recipient's pushed `acks` gets
  `acked_at`; one past `ack_by` without it is flagged (the agent is
  restarted by step 6).
- **requests**: every request in a status file that `requests.md` does not
  list yet is to be copied under its addressee; an answer pushed in any
  status file is to be copied too; an unanswered request past `due` is
  flagged for its default. Requests in `requests.md` past due
  (`cycle_needed.requests_due`) are flagged the same way.
- **stalls**: an `active` agent whose `expected_next_update_by` (at most
  `seen_at` + 45 minutes, or `long_run.expected_end`) has passed is
  stalled; one whose `progress_marker` has not changed for 2 hours is a
  busy stall; a task `blocked` for more than 2 hours, and a `ready` task
  waiting more than 2 hours, are alerts.

It prints the actions and, with `--out`, writes the backlog it would leave
to a file outside the repository, so the lead can diff it. It never
commits, never pushes and never writes the repository's files: only
`--dry-run` exists in part 1. The merge queue (owners.py diff, the
candidate's checks, the merge lock, the fast-forward) is part 2, BT-01b.
"""

import argparse
import copy
import datetime as dt
import json
import pathlib
import re
import subprocess
import sys
import tempfile

sys.path.insert(0, str(pathlib.Path(__file__).resolve().parent))
import cycle_needed as cn  # noqa: E402  (shared helpers; its behaviour is unchanged)

ROOT = pathlib.Path(__file__).resolve().parent.parent.parent
MAIN = cn.MAIN
REMOTE = "origin"
BACKLOG = "docs/progress/backlog.json"
ARCHIVE = "docs/progress/backlog-archive.json"
LEAD = "docs/progress/status/lead.json"
REQUESTS = "docs/progress/requests.md"

RUNNING = {"claimed", "working", "resync"}
#: States an agent writes, and the task states it may write each from.
AGENT_MOVES = {
    "claimed": {"open", "parked", "resync", "blocked"},
    "working": {"open", "claimed", "working", "resync", "blocked", "parked"},
    "ready": {"claimed", "working", "resync", "ready"},
    "blocked": {"claimed", "working", "resync"},
    "parked": {"claimed", "working", "resync", "blocked"},
    "open": {"claimed", "working"},  # an agent yielding its claim
}
STATUS_MINUTES = 45
BUSY_STALL = dt.timedelta(hours=2)
LONG_WAIT = dt.timedelta(hours=2)


class Repo:
    """Read-only access to a checkout and its remote."""

    def __init__(self, path, remote=REMOTE, main=MAIN):
        self.path, self.remote, self.main = pathlib.Path(path), remote, main

    def git(self, *args, check=True):
        r = subprocess.run(["git", "-C", str(self.path), *args],
                           capture_output=True, text=True)
        if check and r.returncode:
            raise subprocess.CalledProcessError(r.returncode, args, r.stdout, r.stderr)
        return r.stdout if check else r

    def fetch(self):
        self.git("fetch", "-q", "--prune", self.remote,
                 f"+refs/heads/*:refs/remotes/{self.remote}/*")

    def heads(self) -> dict:
        out = {}
        for line in self.git("ls-remote", "--heads", self.remote).splitlines():
            sha, ref = line.split("\t")
            out[ref[len("refs/heads/"):]] = sha
        return out

    def ref(self, branch):
        return f"{self.remote}/{branch}"

    def show(self, rev, path):
        r = self.git("show", f"{rev}:{path}", check=False)
        return r.stdout if r.returncode == 0 else None

    def json_at(self, rev, path):
        text = self.show(rev, path)
        if text is None:
            return None
        try:
            return json.loads(text)
        except json.JSONDecodeError:
            return None

    def changed(self, old, new, path) -> bool:
        if not old:
            return True
        r = self.git("diff", "--quiet", old, new, "--", path, check=False)
        return r.returncode != 0  # 1: differs; 128: old is unknown, treat as new

    def file_log(self, rev, path):
        """[(sha, commit time)] of the commits touching path, newest first."""
        out = []
        for line in self.git("log", "--format=%H %cI", rev, "--", path).splitlines():
            sha, when = line.split(" ", 1)
            out.append((sha, cn._ts(when)))
        return out

    def work(self, base, head, agent) -> bool:
        """Whether head holds work main lacks, beyond the agent's own progress files."""
        r = self.git("diff", "--name-only", f"{base}...{head}", check=False)
        own = {f"docs/progress/status/{agent}.json", f"docs/progress/{agent}.md"}
        return r.returncode == 0 and any(f and f not in own for f in r.stdout.splitlines())

    def ahead(self, base, head) -> int:
        r = self.git("rev-list", "--count", f"{base}..{head}", check=False)
        return int(r.stdout.strip() or 0) if r.returncode == 0 else 0


# --- reading -----------------------------------------------------------------

def read_world(repo: Repo, fetch=True) -> dict:
    if fetch:
        repo.fetch()
    main = repo.ref(repo.main)
    backlog = repo.json_at(main, BACKLOG)
    if backlog is None:
        raise SystemExit(f"no {BACKLOG} on {main}")
    archive = repo.json_at(main, ARCHIVE) or {}
    lead = repo.json_at(main, LEAD) or {}
    heads = repo.heads()
    statuses = {}
    for agent, info in sorted(backlog.get("agents", {}).items()):
        branch = (info or {}).get("branch")
        if not branch or branch not in heads:
            continue
        path = f"docs/progress/status/{agent}.json"
        status = repo.json_at(repo.ref(branch), path)
        log = repo.file_log(repo.ref(branch), path) if status is not None else []
        old = ((lead.get("seen") or {}).get("heads") or {}).get(branch)
        statuses[agent] = {
            "branch": branch,
            "head": heads[branch],
            "status": status,
            "unreadable": status is None and repo.show(repo.ref(branch), path) is not None,
            "status_time": log[0][1] if log else None,
            "new": status is not None and repo.changed(old, heads[branch], path),
            "marker_since": _marker_since(repo, repo.ref(branch), path, log, status),
            "ahead": repo.work(main, repo.ref(branch), agent),
        }
    return {
        "backlog": backlog,
        "archived": [t["id"] for t in archive.get("tasks", []) + archive.get("idle_queue", [])],
        "lead": lead,
        "requests_md": repo.show(main, REQUESTS) or "",
        "heads": heads,
        "statuses": statuses,
        "main_sha": heads.get(repo.main),
    }


def _marker_since(repo, rev, path, log, status):
    """When the current progress_marker was first pushed (commit time)."""
    if not status or not log:
        return None
    marker = status.get("progress_marker")
    since = log[0][1]
    for sha, when in log[1:]:
        old = repo.json_at(sha, path)
        if not isinstance(old, dict) or old.get("progress_marker") != marker:
            break
        since = when
    return since


# --- planning ----------------------------------------------------------------

def _act(actions, kind, target, text, change=None):
    actions.append({"kind": kind, "target": target, "text": text, "change": change})


def plan(world: dict, now: dt.datetime) -> dict:
    """The actions a cycle would take, and the backlog it would leave."""
    backlog = copy.deepcopy(world["backlog"])
    lead = world["lead"]
    statuses = world["statuses"]
    tasks = {t["id"]: t for t in backlog.get("tasks", [])}
    lease_h = dt.timedelta(hours=backlog.get("lease_hours", 3))
    actions = []
    iso = cn._iso

    for agent, info in statuses.items():
        if info["status"] is None:
            what = "is not valid JSON" if info["unreadable"] else "is missing"
            _act(actions, "flag", agent, f"{agent}'s status file on {info['branch']} {what}")

    # 1. seen_at, states, claims and leases.
    seen_at = {}
    for agent, info in statuses.items():
        s = info["status"]
        if not s:
            continue
        task = tasks.get(s.get("task_id"))
        claim = (task or {}).get("claim") or {}
        if info["new"]:
            seen_at[agent] = now
        elif claim.get("agent") == agent and cn._ts(claim.get("seen_at")):
            seen_at[agent] = cn._ts(claim["seen_at"])
        else:
            seen_at[agent] = info["status_time"] or now
        tid, state = s.get("task_id"), s.get("task_state")
        if not tid or not state:
            continue
        if task is None:
            if tid not in world["archived"]:
                _act(actions, "flag", agent, f"{agent} reports task {tid}, which is not in the backlog")
            continue
        if task.get("assigned_to") not in (agent, None):
            _act(actions, "flag", tid, f"{agent} reports {tid} as {state}, but it is assigned to "
                 f"{task.get('assigned_to')}; not copied")
            continue
        old = task.get("state")
        if not info["new"] and claim.get("agent") != agent:
            continue  # an old status, e.g. after its lease lapsed: nothing new to copy
        if old == "merged":
            if state != "merged" and state != old:
                _act(actions, "flag", tid, f"{agent} reports {tid} as {state}; it is merged, not copied")
            continue
        if state in ("merged", "resync") or state not in AGENT_MOVES:
            if state != old:
                _act(actions, "flag", tid, f"{agent} reports {tid} as {state}, a state only the "
                     "coordinator sets; not copied")
            continue
        if state != old and old not in AGENT_MOVES[state]:
            _act(actions, "flag", tid, f"{agent} reports {tid} as {state}; {old} -> {state} is not a "
                 "move the agent may make; not copied")
            continue
        change = {}
        if state != old:
            change["state"] = state
        if state == "ready" and s.get("ready_sha") and s.get("ready_sha") != task.get("ready_sha"):
            change["ready_sha"] = s["ready_sha"]
        if state == "open":
            if claim:
                change["claim"] = None
        else:
            new_claim = {
                "agent": agent,
                "branch": info["branch"],
                "claimed_at": s.get("claimed_at") or claim.get("claimed_at"),
                "seen_at": iso(seen_at[agent]),
                "lease_until": iso(seen_at[agent] + lease_h) if info["new"] or not claim
                else claim.get("lease_until"),
            }
            if state not in RUNNING:  # ready, blocked, parked: the lease is paused
                new_claim["lease_until"] = claim.get("lease_until") or new_claim["lease_until"]
            if new_claim != claim:
                change["claim"] = new_claim
        if change:
            what = ", ".join(f"{k} {_short(v)}" for k, v in change.items())
            _act(actions, "copy", tid, f"{tid}: copy {agent}'s status: {what}", change)
            task.update(change)

    # 2. Expire lapsed leases.
    for tid, task in tasks.items():
        claim = task.get("claim") or {}
        until = cn._ts(claim.get("lease_until"))
        if task.get("state") not in RUNNING or not until or until >= now:
            continue
        agent = claim.get("agent") or task.get("assigned_to")
        info = statuses.get(agent) or {}
        branch = claim.get("branch") or info.get("branch")
        change = {"state": "open", "claim": None}
        if info.get("ahead"):
            change["prior_branch"] = branch
            change["prior_sha"] = info["head"]
        prior = f", prior {branch} at {info['head'][:8]}" if "prior_sha" in change else ", no work on the branch"
        _act(actions, "expire", tid, f"{tid}: {agent}'s lease lapsed at {iso(until)}: set open{prior}",
             change)
        task.update(change)

    # 3. The next tasks.
    flat = {a: i["status"] for a, i in statuses.items()}
    found = cn.needs({**backlog, "_archived": world["archived"]}, lead, flat, "", now)
    for tid in found["startable"]:
        _act(actions, "start", tid, f"{tid} can start: start {tasks[tid].get('assigned_to')}")

    # 4. Messages.
    acks = {a: set((i["status"] or {}).get("acks") or []) for a, i in statuses.items()}
    acks["lead"] = set(lead.get("acks") or [])
    for m in backlog.get("messages", []):
        if m.get("acked_at"):
            continue
        to = m.get("to")
        if m.get("id") in acks.get(to, set()):
            when = seen_at.get(to, now) if to != "lead" else now
            change = {"acked_at": iso(when)}
            _act(actions, "ack", m["id"], f"{m['id']} to {to}: acknowledged, set acked_at", change)
            m.update(change)
            continue
        by = cn._ts(m.get("ack_by"))
        if by and by < now:
            _act(actions, "flag", m["id"], f"{m['id']} to {to}: not acknowledged by {iso(by)}; "
                 f"restart {to}")

    # 5. Requests.
    text = world["requests_md"]
    listed = listed_requests(text)
    answers = {}
    for agent, info in statuses.items():
        for a in (info["status"] or {}).get("answers") or []:
            if isinstance(a, dict) and a.get("request_id"):
                answers.setdefault(a["request_id"], (agent, a))
    flagged = set()
    for agent, info in statuses.items():
        for r in (info["status"] or {}).get("requests") or []:
            if not isinstance(r, dict) or not r.get("id"):
                continue
            rid, to = r["id"], r.get("to")
            answer = answers.get(rid)
            if rid not in listed:
                also = f", with {answer[0]}'s answer" if answer else ""
                _act(actions, "request", rid, f"{rid} ({agent} to {to}): copy into requests.md "
                     f"under {to}{also}")
            elif answer and not listed[rid]:
                _act(actions, "request", rid, f"{rid}: copy {answer[0]}'s answer into requests.md "
                     "and mark it **Answered**")
            due = cn._ts(r.get("due"))
            if not answer and not listed.get(rid) and due and due < now:
                flagged.add(rid)
                _act(actions, "flag", rid, f"{rid} ({agent} to {to}) is past due {iso(due)} unanswered: "
                     f"apply its default and message both ({_short(r.get('default'))}), "
                     "or alert the owner if it changes a contract or a design rule")
            missing = [k for k in ("due", "default") if not r.get(k)]
            if missing:
                _act(actions, "flag", rid, f"{rid} ({agent}) lacks {' and '.join(missing)}")
    for rid in cn.requests_due(text, now):
        ids = set(listed_requests(f"## Open\n\n- **{rid}**\n")) or {rid}
        if not ids <= flagged | set(answers):
            _act(actions, "flag", rid, f"{rid} in requests.md is past due: apply its default")

    # 6. Stalls and waits.
    for agent, info in statuses.items():
        s = info["status"]
        if not s or s.get("agent_state") != "active":
            continue
        long_run = s.get("long_run") or {}
        due = cn._ts(long_run.get("expected_end")) if isinstance(long_run, dict) else None
        if due is None:
            due = seen_at[agent] + dt.timedelta(minutes=STATUS_MINUTES)
            own = cn._ts(s.get("expected_next_update_by"))
            if own and own < due:
                due = own
        if due < now:
            _act(actions, "flag", agent, f"{agent} is stalled: no status push since "
                 f"{iso(seen_at[agent])}, expected by {iso(due)}; restart {agent}")
        since = info["marker_since"]
        if since and now - since > BUSY_STALL:
            _act(actions, "flag", agent, f"{agent} busy stall: progress_marker unchanged since "
                 f"{iso(since)}; alert and stop the session")
    for tid, task in tasks.items():
        claim = task.get("claim") or {}
        agent = claim.get("agent") or task.get("assigned_to")
        since = seen_at.get(agent) if claim.get("agent") else None
        if task.get("state") == "blocked" and since and now - since > LONG_WAIT:
            _act(actions, "flag", tid, f"{tid} blocked since {iso(since)}: alert")
        if task.get("state") == "ready" and since and now - since > LONG_WAIT:
            _act(actions, "flag", tid, f"{tid} ready since {iso(since)}: alert, the merge queue waits")

    return {"at": iso(now), "main": world.get("main_sha"), "actions": actions, "backlog": backlog}


_ID = re.compile(r"([A-Za-z0-9]+(?:-[A-Za-z0-9]+)*?-R)(\d+)")


def listed_requests(text: str) -> dict:
    """{request id: closed} for every entry requests.md lists.

    An entry is "- **<ids>**" at the left margin; <ids> may be one id, a
    range ("S1-R1 to S1-R7") or a list ("A-R1, A-R2 and A-R4"). An entry is
    closed when it carries a closing marker or stands outside "## Open".
    """
    out = {}
    section = None
    for entry in re.split(r"\n(?=- \*\*|## )", text):
        if entry.startswith("## "):
            section = entry.split("\n", 1)[0].strip()
            continue
        head = re.match(r"- \*\*([^*]+)\*\*", entry)
        if not head:
            continue
        closed = section != "## Open" or bool(cn.CLOSED.search(entry))
        ids = _ID.findall(head.group(1))
        names = [p + n for p, n in ids]
        if len(ids) == 2 and " to " in head.group(1) and ids[0][0] == ids[1][0]:
            names = [ids[0][0] + str(i) for i in range(int(ids[0][1]), int(ids[1][1]) + 1)]
        for name in names:
            out[name] = out.get(name, False) or closed
    return out


def _short(v, n=60):
    s = json.dumps(v) if not isinstance(v, str) else v
    return s if len(s) <= n else s[:n - 3] + "..."


# --- output ------------------------------------------------------------------

ORDER = ["copy", "expire", "start", "ack", "request", "flag"]
TITLES = {"copy": "Copy states and claims", "expire": "Expire leases", "start": "Start agents",
          "ack": "Acknowledgements", "request": "Requests", "flag": "Flags"}


def render(result: dict) -> str:
    lines = [f"coordinator dry run at {result['at']} (main {str(result['main'])[:8]})"]
    acts = result["actions"]
    for kind in ORDER:
        mine = [a for a in acts if a["kind"] == kind]
        if mine:
            lines.append(f"{TITLES[kind]}:")
            lines += [f"- {a['text']}" for a in mine]
    if not acts:
        lines.append("no actions")
    lines.append("dry run: nothing written, nothing pushed")
    return "\n".join(lines)


def run(repo_path, now=None, fetch=True, as_json=False, out=None, main=MAIN) -> str:
    now = now or cn._now()
    world = read_world(Repo(repo_path, main=main), fetch=fetch)
    result = plan(world, now)
    if out:
        p = pathlib.Path(out).resolve()
        if p.is_relative_to(pathlib.Path(repo_path).resolve()):
            raise SystemExit("--out must be outside the repository")
        p.write_text(json.dumps(result["backlog"], indent=1, ensure_ascii=False) + "\n")
    if as_json:
        return json.dumps({k: v for k, v in result.items() if k != "backlog"}, indent=1)
    return render(result)


# --- self-test: fixture branches in local bare repositories ------------------

def _fixture(tmp: pathlib.Path):
    """origin.git with main and agent branches; returns (clone, git)."""
    env_base = {"GIT_AUTHOR_NAME": "t", "GIT_AUTHOR_EMAIL": "t@example.invalid",
                "GIT_COMMITTER_NAME": "t", "GIT_COMMITTER_EMAIL": "t@example.invalid",
                "GIT_CONFIG_GLOBAL": "/dev/null", "GIT_CONFIG_NOSYSTEM": "1",
                "PATH": "/usr/bin:/bin:/usr/local/bin", "HOME": str(tmp)}

    def git(cwd, *args, when=None):
        env = dict(env_base)
        if when:
            env["GIT_AUTHOR_DATE"] = env["GIT_COMMITTER_DATE"] = when
        subprocess.run(["git", "-C", str(cwd), *args], check=True, capture_output=True,
                       text=True, env=env)

    origin, work = tmp / "origin.git", tmp / "work"
    subprocess.run(["git", "init", "-q", "--bare", "-b", "main", str(origin)], check=True,
                   capture_output=True)
    subprocess.run(["git", "init", "-q", "-b", "main", str(work)], check=True, capture_output=True)
    git(work, "remote", "add", "origin", str(origin))

    def write(path, obj):
        p = work / path
        p.parent.mkdir(parents=True, exist_ok=True)
        p.write_text(obj if isinstance(obj, str) else json.dumps(obj, indent=1) + "\n")

    def commit(msg, when):
        git(work, "add", "-A")
        git(work, "commit", "-q", "-m", msg, when=when)

    agents = {a: {"branch": f"b/{a.lower()}"} for a in ("S1", "S2", "S3", "S4", "S5", "S6")}
    T = "2026-11-17T{}:00Z".format
    backlog = {
        "lease_hours": 3, "building_cap": 6, "agents": agents,
        "tasks": [
            {"id": "t1", "assigned_to": "S1", "state": "open", "deps": [], "claim": None},
            {"id": "t2", "assigned_to": "S2", "state": "working", "deps": [],
             "claim": {"agent": "S2", "branch": "b/s2", "claimed_at": T("06:00"),
                       "seen_at": T("06:05"), "lease_until": T("09:05")}},
            {"id": "t3", "assigned_to": "S3", "state": "working", "deps": [],
             "claim": {"agent": "S3", "branch": "b/s3", "claimed_at": T("10:00"),
                       "seen_at": T("10:00"), "lease_until": T("13:00")}},
            {"id": "t4", "assigned_to": "S4", "state": "working", "deps": [],
             "claim": {"agent": "S4", "branch": "b/s4", "claimed_at": T("08:00"),
                       "seen_at": T("08:00"), "lease_until": T("11:00")}},
            {"id": "t5", "assigned_to": "S5", "state": "open", "deps": ["t1"], "claim": None},
            {"id": "t6", "assigned_to": "S6", "state": "open", "deps": [], "claim": None},
            {"id": "t7", "assigned_to": "S1", "state": "merged", "deps": [], "claim": None},
        ],
        "messages": [
            {"id": "M1", "to": "S1", "ack_by": T("11:00"), "acked_at": None},
            {"id": "M2", "to": "S3", "ack_by": T("11:00"), "acked_at": None},
            {"id": "M3", "to": "lead", "ack_by": T("13:00"), "acked_at": None},
        ],
    }
    write(BACKLOG, backlog)
    write(LEAD, {"agent": "lead", "acks": [], "merging": None, "seen": {"heads": {}}})
    write(REQUESTS, "# Requests\n\n## Open\n\n### S2\n\n- **S3-R1** (from S3, 17 November 2026; "
          "due 17 November 09:00Z): listed, past due, open.\n")
    commit("main", T("05:00"))
    git(work, "push", "-q", "origin", "main")

    def status(agent, when, **fields):
        s = {"agent": agent, "agent_state": "active", "acks": [], "requests": [], "answers": [],
             "progress_marker": {"last_green_sha": "x", "next_step": "y"}}
        s.update(fields)
        write(f"docs/progress/status/{agent}.json", s)
        commit(f"{agent} status", when)

    def branch(agent):
        git(work, "checkout", "-q", "-B", agents[agent]["branch"], "main")

    def push(agent):
        git(work, "push", "-q", "-f", "origin", agents[agent]["branch"])

    # S1 claims t1 and acknowledges M1.
    branch("S1")
    status("S1", T("11:50"), task_id="t1", task_state="claimed", claimed_at=T("11:50"),
           expected_next_update_by=T("12:35"), acks=["M1"])
    push("S1")
    # S2: lease lapsed (seen 06:05, nothing new since), work on the branch.
    branch("S2")
    write("work.txt", "s2 work")
    commit("S2 work", T("06:00"))
    status("S2", T("06:05"), task_id="t2", task_state="working",
           expected_next_update_by=T("06:50"),
           requests=[{"id": "S2-R1", "from": "S2", "to": "S3", "ask": "a",
                      "due": T("10:00"), "default": "do b"},
                     {"id": "S2-R2", "from": "S2", "to": "S1", "ask": "b",
                      "due": T("15:00"), "default": "do c"}])
    push("S2")
    # S3: marks t3 ready; M2 unacknowledged past ack_by; answers S2-R2;
    # the progress marker has been the same since 09:00 (busy stall).
    branch("S3")
    status("S3", T("09:00"), task_id="t3", task_state="working",
           progress_marker={"last_green_sha": "aaa", "next_step": "same"})
    status("S3", T("11:55"), task_id="t3", task_state="ready", ready_sha="r3",
           progress_marker={"last_green_sha": "aaa", "next_step": "same"},
           expected_next_update_by=T("12:40"),
           answers=[{"request_id": "S2-R2", "answer": "use c", "at": T("11:55")}])
    push("S3")
    # S4 reports merged (not its to set) and is stalled.
    branch("S4")
    status("S4", T("08:00"), task_id="t4", task_state="merged",
           expected_next_update_by=T("08:45"))
    push("S4")
    # S5 reports a task assigned to S6; S6 has no status file.
    branch("S5")
    status("S5", T("11:00"), task_id="t6", task_state="claimed", agent_state="waiting")
    push("S5")
    branch("S6")
    write("other.txt", "x")
    commit("S6 no status", T("11:00"))
    push("S6")
    git(work, "checkout", "-q", "main")

    # The coordinator's checkout: a separate clone, as a cycle session has.
    coord = tmp / "coord"
    subprocess.run(["git", "clone", "-q", str(origin), str(coord)], check=True, capture_output=True)
    # The last cycle saw S2's and S4's heads, so they are not new.
    heads = Repo(coord, main="main").heads()
    write(LEAD, {"agent": "lead", "acks": ["M3"], "merging": None,
                 "seen": {"heads": {b: heads[b] for b in ("b/s2", "b/s4")}}})
    commit("lead cycle", T("11:58"))
    git(work, "push", "-q", "origin", "main")
    return coord, origin


def self_test() -> int:
    fails = []

    def check(name, cond):
        if not cond:
            fails.append(name)

    now = dt.datetime(2026, 11, 17, 12, 0, tzinfo=dt.timezone.utc)
    with tempfile.TemporaryDirectory() as d:
        tmp = pathlib.Path(d)
        coord, origin = _fixture(tmp)
        repo = Repo(coord, main="main")
        world = read_world(repo)
        result = plan(world, now)
        acts = result["actions"]
        texts = [a["text"] for a in acts]
        tasks = {t["id"]: t for t in result["backlog"]["tasks"]}

        def has(kind, target, part=""):
            return any(a["kind"] == kind and a["target"] == target and part in a["text"]
                       for a in acts)

        # States and claims copied, with seen_at now for a new push.
        check("t1 claimed", tasks["t1"]["state"] == "claimed" and has("copy", "t1"))
        check("t1 lease from seen_at",
              tasks["t1"]["claim"]["seen_at"] == "2026-11-17T12:00:00Z"
              and tasks["t1"]["claim"]["lease_until"] == "2026-11-17T15:00:00Z")
        check("t3 ready", tasks["t3"]["state"] == "ready" and tasks["t3"]["ready_sha"] == "r3")
        # Lease lapsed with work on the branch: open, prior recorded.
        check("t2 expired", tasks["t2"]["state"] == "open" and tasks["t2"]["claim"] is None
              and tasks["t2"]["prior_branch"] == "b/s2"
              and tasks["t2"]["prior_sha"] == world["heads"]["b/s2"])
        # Not the agent's to set, and not the agent's task.
        check("merged not copied", tasks["t4"]["state"] != "merged" and has("flag", "t4", "only the coordinator"))
        check("t4 expired", tasks["t4"]["state"] == "open" and has("expire", "t4", "no work"))
        check("other's task", has("flag", "t6", "assigned to S6") and tasks["t6"]["state"] == "open")
        check("missing status", has("flag", "S6", "missing"))
        # Next tasks: t6 (S6 free, no deps). t5 waits on t1.
        check("start", has("start", "t6") and not has("start", "t5"))
        # Messages.
        check("ack copied", has("ack", "M1") and has("ack", "M3"))
        check("ack missed", has("flag", "M2", "not acknowledged"))
        # Requests.
        check("request copy", has("request", "S2-R1", "copy into") and has("request", "S2-R2", "copy into"))
        check("request due", has("flag", "S2-R1", "past due") and not has("flag", "S2-R2", "past due"))
        check("requests.md due", has("flag", "S3-R1", "requests.md"))
        check("answer copied with request", has("request", "S2-R2", "with S3's answer"))
        lr = listed_requests("# R\n\n## Open\n\n- **A-R1 to A-R3** (x)\n- **B-R1, B-R2 and C-R4** "
                             "(y) **Answered**\n- **D-R1** (z)\n\n## Done in cycle 3\n\n- **E-R1** (w)\n")
        check("listed ranges", lr == {"A-R1": False, "A-R2": False, "A-R3": False, "B-R1": True,
                                      "B-R2": True, "C-R4": True, "D-R1": False, "E-R1": True})
        # Stalls.
        check("stalled", has("flag", "S4", "stalled") and not has("flag", "S1", "stalled"))
        check("busy stall", has("flag", "S3", "busy stall") and not has("flag", "S1", "busy stall"))
        # Main's backlog in the input is untouched by plan().
        check("input untouched", world["backlog"]["tasks"][0]["state"] == "open")

        # The CLI: --dry-run prints and pushes nothing; --out writes outside only.
        before = Repo(coord, main="main").heads()
        status_before = repo.git("status", "--porcelain")
        out = tmp / "backlog.out.json"
        cmd = [sys.executable, str(pathlib.Path(__file__).resolve()), "--dry-run",
               "--repo", str(coord), "--main", "main", "--now", "2026-11-17T12:00:00Z",
               "--out", str(out)]
        r = subprocess.run(cmd, capture_output=True, text=True)
        check("cli exit", r.returncode == 0)
        check("cli prints", "dry run: nothing written, nothing pushed" in r.stdout
              and "t2: S2's lease lapsed" in r.stdout)
        check("cli out", out.exists() and json.loads(out.read_text())["tasks"][1]["state"] == "open")
        check("nothing pushed", Repo(coord, main="main").heads() == before)
        check("nothing written", repo.git("status", "--porcelain") == status_before)
        r = subprocess.run(cmd[:-2] + ["--json"], capture_output=True, text=True)
        check("cli json", r.returncode == 0 and len(json.loads(r.stdout)["actions"]) == len(acts))
        r = subprocess.run([c for c in cmd if c != "--dry-run"], capture_output=True, text=True)
        check("needs --dry-run", r.returncode == 2)
        r = subprocess.run(cmd[:-1] + [str(coord / "x.json")], capture_output=True, text=True)
        check("out inside refused", r.returncode != 0 and not (coord / "x.json").exists())

        # A second run with nothing new: quiet for what was copied.
        world["lead"]["seen"] = {"heads": dict(world["heads"])}
        world["backlog"] = result["backlog"]
        for info in world["statuses"].values():
            info["new"] = False
        again = plan(world, now)
        check("idempotent copies", not [a for a in again["actions"] if a["kind"] in ("copy", "ack", "expire")])

    if fails:
        print("self-test FAILED: " + ", ".join(fails))
        for t in texts if "texts" in dir() else []:
            print("  " + t)
        return 1
    print("self-test passed")
    return 0


def main(argv=None) -> int:
    ap = argparse.ArgumentParser(description=__doc__.split("\n")[0])
    ap.add_argument("--dry-run", action="store_true", help="print the actions; write and push nothing")
    ap.add_argument("--json", action="store_true", help="print the actions as JSON")
    ap.add_argument("--out", help="write the backlog the cycle would leave to this file (outside the repository)")
    ap.add_argument("--repo", default=str(ROOT), help="the checkout to read (default: this one)")
    ap.add_argument("--main", default=MAIN, help="main's branch name")
    ap.add_argument("--now", help="the time to judge by (UTC, for tests)")
    ap.add_argument("--no-fetch", action="store_true", help="use the remote refs already fetched")
    ap.add_argument("--self-test", action="store_true")
    args = ap.parse_args(argv)
    if args.self_test:
        return self_test()
    if not args.dry_run:
        ap.error("only --dry-run exists in part 1 (BT-01a); writing and pushing come with BT-01b")
    now = cn._ts(args.now) if args.now else None
    print(run(args.repo, now=now, fetch=not args.no_fetch, as_json=args.json, out=args.out,
              main=args.main))
    return 0


if __name__ == "__main__":
    sys.exit(main())
