#!/usr/bin/env python3
"""The wave's metrics, from the coordination data, as a digest section.

    python3 tools/coord/metrics.py                 # print the Markdown section
    python3 tools/coord/metrics.py --json          # the same figures, as JSON
    python3 tools/coord/metrics.py --fetch         # git fetch origin first
    python3 tools/coord/metrics.py --days 7 --now 2026-11-24T21:00:00Z
    python3 tools/coord/metrics.py --self-test     # fixture repository, no network

Docs: docs/guides/agent-protocol.md, "Waves: start, metrics and close" (the
"Metrics" table and its review thresholds). Backlog task BT-07.

It is read-only: it writes no file in the repository, commits nothing and
pushes nothing. `--fetch` only updates the remote-tracking refs. Main is read
as origin has it (`origin/<main>`), each roster agent's status from
`origin/<its branch>`; a figure the files cannot give is printed as "no
data", with the reason, and is never estimated.

Where each figure comes from
----------------------------
- **The backlog's history.** Every commit on main that touched
  `backlog.json` or `backlog-archive.json`, oldest first, gives each task's
  `state` at that commit's time. A task's ready episode starts at the first
  commit that shows it `ready`; it ends at `merged` (a merge) or at `resync`
  (a resync). So the times are those at which the lead's bookkeeping
  recorded each move, not the agents' own clocks.
  - **Merge lead time**: the mean of merged − ready over the merges in the
    window. When main never showed the task `ready` (the lead recorded the
    ready and the merge in one move), its ready time is its `ready_sha`'s
    committer time; without that object it has no lead time and is counted
    apart.
  - **Oldest ready task's wait**: now − the start of the ready episode of
    each task `ready` on main's head.
  - **Resync rate**: resyncs ÷ (merges + resyncs) in the window, counted per
    task: a candidate that batches three tasks counts three. Every move to
    `resync` counts, whatever state main showed before it.
  - **Blocked hours**: the hours tasks spent `blocked`, summed across
    tasks, per UTC day of the window.
- **The gate's verdicts** (the backlog's `verdicts_dir`, `*.json` files).
  - **Split verdicts per day**: verdict entries (one item, one quality)
    whose `result` is `split` or whose samples disagree, per UTC day of
    their `at`.
  - **Catch and false-fail rates per quality**: the verdicts carry no
    reference label, so these come from the blind audits' forms
    (`gate/audit/*.md`, the "| Task | Commit | Item | Quality | Label |"
    tables), each row joined to the gate's verdict on the same task, commit
    (prefix match), item and quality. Catch rate: of the audit's fails, the
    share the gate failed. False-fail rate: of the audit's passes, the share
    the gate failed. Rows without a verdict, or labelled `n/a`, or whose
    verdict is `unknown`, are left out.
- **The status files** on the agents' branches.
  - **Stalls**: agents `active` whose `expected_next_update_by` (or
    `long_run.expected_end`) has passed. The files keep no history of past
    stalls, so this is the count now, not per day.
- **Usage per merged task**: no file records usage, so it is "no data".
"""

import argparse
import collections
import datetime as dt
import json
import pathlib
import re
import subprocess
import sys
import tempfile

sys.path.insert(0, str(pathlib.Path(__file__).resolve().parent))
import cycle_needed as cn  # noqa: E402  (shared helpers; behaviour unchanged)

ROOT = pathlib.Path(__file__).resolve().parent.parent.parent
MAIN = cn.MAIN
BACKLOG = "docs/progress/backlog.json"
ARCHIVE = "docs/progress/backlog-archive.json"
VERDICTS = "docs/art/ui-quality/gate/verdicts/"
AUDITS = "docs/art/ui-quality/gate/audit/"
CATCH_TARGET = 0.80
FALSE_FAIL_TARGET = 0.20

THRESHOLDS = {
    "lead_time": "over 2 h on average",
    "oldest_ready": "over 2 h",
    "resync_rate": "over 1 in 3 candidates",
    "gate_rates": "catch under 80%, or false fails over 20%",
    "splits": "over 15",
    "stalls": "more than 1 a day",
    "blocked": "over 4 a day across the team",
    "usage": "1.5 × the phase 1 figure",
}


# --- reading -----------------------------------------------------------------

class Git:
    """Read-only access to a checkout's objects."""

    def __init__(self, path):
        self.path = pathlib.Path(path)
        self._batch = None

    def run(self, *args, check=True):
        r = subprocess.run(["git", "-C", str(self.path), *args],
                           capture_output=True, text=True)
        if check and r.returncode:
            raise subprocess.CalledProcessError(r.returncode, args, r.stdout, r.stderr)
        return r

    def show(self, rev, path):
        """The file's text at rev, or None."""
        if self._batch is None:
            self._batch = subprocess.Popen(
                ["git", "-C", str(self.path), "cat-file", "--batch"],
                stdin=subprocess.PIPE, stdout=subprocess.PIPE)
        self._batch.stdin.write(f"{rev}:{path}\n".encode())
        self._batch.stdin.flush()
        header = self._batch.stdout.readline().decode().split()
        if len(header) < 3 or header[1] != "blob":
            return None
        data = self._batch.stdout.read(int(header[2]))
        self._batch.stdout.read(1)
        return data.decode("utf-8", "replace")

    def json_at(self, rev, path):
        text = self.show(rev, path)
        if text is None:
            return None
        try:
            return json.loads(text)
        except json.JSONDecodeError:
            return None

    def ls(self, rev, prefix):
        r = self.run("ls-tree", "-r", "--name-only", rev, "--", prefix, check=False)
        return r.stdout.splitlines() if r.returncode == 0 else []

    def log(self, rev, *paths):
        """[(sha, time)] of the commits touching paths, oldest first."""
        r = self.run("log", "--reverse", "--format=%H %cI", rev, "--", *paths, check=False)
        out = []
        for line in r.stdout.splitlines():
            sha, when = line.split(" ", 1)
            out.append((sha, cn._ts(when)))
        return out

    def commit_time(self, sha):
        """The committer time of sha, or None when the object is missing."""
        if not hasattr(self, "_times"):
            self._times = {}
        if sha not in self._times:
            r = self.run("show", "-s", "--format=%cI", f"{sha}^{{commit}}", "--", check=False)
            self._times[sha] = cn._ts(r.stdout.strip()) if r.returncode == 0 and r.stdout.strip() else None
        return self._times[sha]

    def has(self, rev):
        return self.run("rev-parse", "--verify", "-q", f"{rev}^{{commit}}", check=False).returncode == 0

    def shallow(self):
        return self.run("rev-parse", "--is-shallow-repository", check=False).stdout.strip() == "true"

    def close(self):
        if self._batch:
            self._batch.stdin.close()
            self._batch.wait()
            self._batch = None


def _tasks(doc):
    if isinstance(doc, dict):
        return [t for t in doc.get("tasks", []) if isinstance(t, dict) and t.get("id")]
    return []


def backlog_history(git, rev):
    """[(time, {task_id: (state, ready_sha)})] at each commit touching the backlog files."""
    out = []
    for sha, when in git.log(rev, BACKLOG, ARCHIVE):
        states = {}
        for path in (ARCHIVE, BACKLOG):  # the live backlog wins over the archive
            for t in _tasks(git.json_at(sha, path)):
                states[t["id"]] = (t.get("state"), t.get("ready_sha"))
        out.append((when, states))
    return out


def episodes(history, commit_time=lambda sha: None):
    """Merges, resyncs, open ready episodes and blocked intervals.

    A merge's ready time is the first commit on main that showed the task
    `ready`; when main never showed it ready (the lead recorded ready and
    merged in one move), it is the committer time of the task's `ready_sha`,
    and without that the merge has no lead time ("unseen")."""
    merges, resyncs, unseen = [], [], []
    ready_since, blocked_since, blocked = {}, {}, []
    last = {}
    for when, states in history:
        for tid, (state, ready_sha) in states.items():
            prev = last.get(tid)
            if state == prev:
                continue
            if state == "ready" and tid not in ready_since:
                ready_since[tid] = when
            if state == "merged":
                if tid in ready_since:
                    merges.append({"task": tid, "ready_at": ready_since.pop(tid), "merged_at": when,
                                   "from": "backlog"})
                else:
                    at = commit_time(ready_sha) if ready_sha else None
                    if at and at <= when:
                        merges.append({"task": tid, "ready_at": at, "merged_at": when, "from": "ready_sha"})
                    else:
                        unseen.append({"task": tid, "merged_at": when})
            elif state == "resync":
                resyncs.append({"task": tid, "at": when})
                ready_since.pop(tid, None)
            elif state != "ready":
                ready_since.pop(tid, None)
            if prev == "blocked" and tid in blocked_since:
                blocked.append((tid, blocked_since.pop(tid), when))
            if state == "blocked":
                blocked_since[tid] = when
            last[tid] = state
    return {"merges": merges, "resyncs": resyncs, "unseen": unseen,
            "ready_since": ready_since, "blocked": blocked,
            "blocked_since": blocked_since, "last": last}


def verdict_entries(git, rev, folder):
    out = []
    for path in git.ls(rev, folder):
        if not path.endswith(".json"):
            continue
        doc = git.json_at(rev, path)
        for e in doc if isinstance(doc, list) else [doc]:
            if isinstance(e, dict) and e.get("quality") and e.get("result"):
                out.append(e)
    return out


_ROW = re.compile(r"^\|(.*)\|\s*$")


def audit_rows(git, rev, folder):
    """Rows of the blind audits' forms: task, commit, item, quality, label."""
    rows = []
    for path in git.ls(rev, folder):
        if not path.endswith(".md"):
            continue
        cols = None
        for line in (git.show(rev, path) or "").splitlines():
            m = _ROW.match(line.strip())
            if not m:
                cols = None
                continue
            cells = [c.strip() for c in m.group(1).split("|")]
            if cols is None:
                low = [c.lower() for c in cells]
                if {"task", "commit", "item", "quality", "label"} <= set(low):
                    cols = {name: low.index(name) for name in ("task", "commit", "item", "quality", "label")}
                continue
            if set("".join(cells)) <= set("-: "):
                continue
            if max(cols.values()) < len(cells):
                rows.append({k: cells[i] for k, i in cols.items()} | {"source": path})
    return rows


def statuses(git, backlog, remote="origin"):
    out = {}
    for agent, info in (backlog.get("agents") or {}).items():
        branch = (info or {}).get("branch")
        if branch:
            s = git.json_at(f"{remote}/{branch}", f"docs/progress/status/{agent}.json")
            if isinstance(s, dict):
                out[agent] = s
    return out


# --- the figures -------------------------------------------------------------

def _hours(delta):
    return delta.total_seconds() / 3600


def _fmt_h(h):
    return f"{h:.1f} h"


def _day(t):
    return t.astimezone(dt.timezone.utc).date()


def compute(git, rev, now, days=7, remote="origin"):
    since = now - dt.timedelta(days=days)
    backlog = git.json_at(rev, BACKLOG) or {}
    folder = backlog.get("verdicts_dir") or VERDICTS
    if not folder.endswith("/"):
        folder += "/"
    ep = episodes(backlog_history(git, rev), git.commit_time)
    m = {}

    # Merge lead time.
    window = [x for x in ep["merges"] if x["merged_at"] >= since]
    if window:
        mean = sum(_hours(x["merged_at"] - x["ready_at"]) for x in window) / len(window)
        worst = max(window, key=lambda x: x["merged_at"] - x["ready_at"])
        m["lead_time"] = {"value": round(mean, 2), "past": mean > 2,
                          "text": f"{_fmt_h(mean)} on average over {len(window)} merges in the last {days} days"
                                  + (f" ({sum(1 for x in window if x['from'] == 'ready_sha')} timed from the ready "
                                     "commit, as main never showed them ready)"
                                     if any(x["from"] == "ready_sha" for x in window) else "") + " "
                                  f"(longest {worst['task']}, {_fmt_h(_hours(worst['merged_at'] - worst['ready_at']))})"
                                  + (f"; {sum(1 for x in ep['unseen'] if x['merged_at'] >= since)} more merged "
                                     "without being shown ready, no lead time" if any(
                                         x["merged_at"] >= since for x in ep["unseen"]) else "")}
    else:
        m["lead_time"] = {"value": None, "past": None,
                          "text": f"no data: no merge recorded in the backlog's history in the last {days} days"}

    # Oldest ready task's wait.
    ready_now = [t["id"] for t in _tasks(backlog) if t.get("state") == "ready"]
    waits = [(tid, _hours(now - ep["ready_since"][tid])) for tid in ready_now if tid in ep["ready_since"]]
    if waits:
        tid, h = max(waits, key=lambda x: x[1])
        m["oldest_ready"] = {"value": round(h, 2), "past": h > 2,
                             "text": f"{_fmt_h(h)} ({tid}; {len(waits)} task(s) ready)"}
    else:
        m["oldest_ready"] = {"value": 0.0 if not ready_now else None, "past": False if not ready_now else None,
                             "text": "no task is ready on main" if not ready_now
                             else "no data: the ready tasks' start is not in the backlog's history"}

    # Resync rate.
    rs = [x for x in ep["resyncs"] if x["at"] >= since]
    total = len(window) + sum(1 for x in ep["unseen"] if x["merged_at"] >= since) + len(rs)
    if total:
        rate = len(rs) / total
        m["resync_rate"] = {"value": round(rate, 3), "past": rate > 1 / 3,
                            "text": f"{len(rs)} of {total} ({rate:.0%}) in the last {days} days, per task"
                                    + (f": {', '.join(sorted({x['task'] for x in rs}))}" if rs else "")}
    else:
        m["resync_rate"] = {"value": None, "past": None,
                            "text": f"no data: no candidate's outcome recorded in the last {days} days"}

    # Catch and false-fail rates per quality.
    verdicts = verdict_entries(git, rev, folder)
    by_key = {}
    for e in verdicts:
        key = (e.get("task_id"), e.get("item"), e.get("quality"))
        by_key.setdefault(key, []).append(e)
    per_q = collections.OrderedDict()
    for row in audit_rows(git, rev, AUDITS):
        label = row["label"].lower()
        if label not in ("pass", "fail"):
            continue
        sha = row["commit"].strip("`")
        found = [e for e in by_key.get((row["task"], row["item"], row["quality"]), [])
                 if e.get("sha") and (sha.startswith(e["sha"]) or str(e["sha"]).startswith(sha))]
        if not found:
            continue
        gate = max(found, key=lambda e: str(e.get("at", "")))["result"]
        if gate not in ("pass", "fail"):
            continue
        q = per_q.setdefault(row["quality"], {"fails": 0, "caught": 0, "passes": 0, "false": 0})
        if label == "fail":
            q["fails"] += 1
            q["caught"] += gate == "fail"
        else:
            q["passes"] += 1
            q["false"] += gate == "fail"
    rates = {}
    for qname, q in sorted(per_q.items()):
        catch = q["caught"] / q["fails"] if q["fails"] else None
        false = q["false"] / q["passes"] if q["passes"] else None
        past = (catch is not None and catch < CATCH_TARGET) or (false is not None and false > FALSE_FAIL_TARGET)
        rates[qname] = {"catch": catch, "false_fail": false, "past": past,
                        "text": (f"caught {q['caught']} of {q['fails']} ({catch:.0%})" if q["fails"]
                                 else "no audit fail") + "; " +
                                (f"false fails {q['false']} of {q['passes']} ({false:.0%})" if q["passes"]
                                 else "no audit pass")}
    m["gate_rates"] = {"value": rates, "past": any(r["past"] for r in rates.values()) if rates else None,
                       "text": "per quality, below" if rates else
                       "no data: the verdicts carry no reference labels and no blind-audit row matches a verdict"}

    # Split verdicts per day.
    per_day = collections.Counter()
    for e in verdicts:
        samples = [s for s in e.get("samples") or [] if s in ("pass", "fail")]
        at = cn._ts(e.get("at"))
        if at and at >= since and (e.get("result") == "split" or len(set(samples)) > 1):
            per_day[_day(at)] += 1
    if any(cn._ts(e.get("at")) and cn._ts(e.get("at")) >= since for e in verdicts):
        top = max(per_day.values(), default=0)
        busiest = max(per_day, key=per_day.get) if per_day else None
        m["splits"] = {"value": top, "past": top > 15,
                       "text": f"at most {top} a day in the last {days} days"
                               + (f" ({busiest.isoformat()}); {sum(per_day.values())} in all" if busiest else "")}
    else:
        m["splits"] = {"value": None, "past": None, "text": f"no data: no verdict in the last {days} days"}

    # Stalls (now).
    st = statuses(git, backlog, remote)
    stalled = []
    for agent, s in sorted(st.items()):
        if s.get("agent_state") != "active":
            continue
        due = cn._ts((s.get("long_run") or {}).get("expected_end")) or cn._ts(s.get("expected_next_update_by"))
        if due and due < now:
            stalled.append(agent)
    if st:
        m["stalls"] = {"value": len(stalled), "past": len(stalled) > 1,
                       "text": f"{len(stalled)} now" + (f" ({', '.join(stalled)})" if stalled else "")
                               + f", of {len(st)} status files read; the files keep no history of past stalls,"
                                 " so there is no per-day count"}
    else:
        m["stalls"] = {"value": None, "past": None,
                       "text": "no data: no roster agent's status file was readable on its branch"}

    # Blocked hours per day.
    intervals = list(ep["blocked"]) + [(t, s, now) for t, s in ep["blocked_since"].items()]
    hours = collections.Counter()
    for _tid, start, end in intervals:
        start, end = max(start, since), min(end, now)
        while start < end:
            day_end = dt.datetime.combine(_day(start) + dt.timedelta(days=1), dt.time(), dt.timezone.utc)
            cut = min(end, day_end)
            hours[_day(start)] += _hours(cut - start)
            start = cut
    top = max(hours.values(), default=0.0)
    busiest = max(hours, key=hours.get) if hours else None
    m["blocked"] = {"value": round(top, 2), "past": top > 4,
                    "text": f"at most {_fmt_h(top)} a day in the last {days} days"
                            + (f" ({busiest.isoformat()}); {_fmt_h(sum(hours.values()))} in all" if busiest else "")}

    m["usage"] = {"value": None, "past": None,
                  "text": "no data: no file records usage per session or task"}

    notes = []
    if git.shallow():
        notes.append("the checkout is shallow, so the backlog's history may start late: "
                     "`git fetch --unshallow origin` for the full figures")
    return {"now": cn._iso(now), "days": days, "rev": rev, "metrics": m, "notes": notes}


NAMES = [
    ("lead_time", "Merge lead time, ready to merged"),
    ("oldest_ready", "Oldest ready task's wait"),
    ("resync_rate", "Resync rate"),
    ("gate_rates", "Catch rate and false-fail rate, per quality"),
    ("splits", "Split verdicts per day"),
    ("stalls", "Stalls"),
    ("blocked", "Blocked hours"),
    ("usage", "Usage per merged task"),
]


def _past(v):
    return {True: "**past**", False: "within", None: "no data"}[v]


def render(result):
    lines = [f"## Metrics ({result['now']}, last {result['days']} days)", "",
             "From `tools/coord/metrics.py` (backlog history on main, the gate's verdicts, the blind audits, "
             "the status files). Thresholds: agent-protocol.md, \"Waves: start, metrics and close\".", "",
             "| Metric | Figure | Review threshold | Past it? |", "|---|---|---|---|"]
    for key, name in NAMES:
        m = result["metrics"][key]
        lines.append(f"| {name} | {m['text']} | {THRESHOLDS[key]} | {_past(m['past'])} |")
    rates = result["metrics"]["gate_rates"]["value"]
    if rates:
        lines += ["", "| Quality | From the blind audits | Past the targets? |", "|---|---|---|"]
        for q, r in rates.items():
            lines.append(f"| {q} | {r['text']} | {_past(r['past'])} |")
    for n in result["notes"]:
        lines += ["", f"Note: {n}."]
    return "\n".join(lines) + "\n"


def run(path=ROOT, now=None, days=7, as_json=False, fetch=False, main=MAIN, remote="origin"):
    git = Git(path)
    try:
        if fetch:
            git.run("fetch", "-q", remote, f"+refs/heads/*:refs/remotes/{remote}/*")
        rev = f"{remote}/{main}"
        if not git.has(rev):
            raise SystemExit(f"metrics: {rev} is not in this checkout; run git fetch origin")
        result = compute(git, rev, now or cn._now(), days, remote)
    finally:
        git.close()
    if as_json:
        def enc(o):
            return o.isoformat() if hasattr(o, "isoformat") else str(o)
        return json.dumps(result, indent=2, default=enc) + "\n"
    return render(result)


# --- self-test ---------------------------------------------------------------

def _commit(repo, when, files, msg):
    for rel, doc in files.items():
        p = repo / rel
        p.parent.mkdir(parents=True, exist_ok=True)
        p.write_text(doc if isinstance(doc, str) else json.dumps(doc, indent=1))
    env = {"GIT_AUTHOR_DATE": when, "GIT_COMMITTER_DATE": when, "GIT_AUTHOR_NAME": "t",
           "GIT_AUTHOR_EMAIL": "t@example.invalid", "GIT_COMMITTER_NAME": "t",
           "GIT_COMMITTER_EMAIL": "t@example.invalid", "PATH": "/usr/bin:/bin:/usr/local/bin"}
    subprocess.run(["git", "-C", str(repo), "add", "-A"], check=True, env=env)
    subprocess.run(["git", "-C", str(repo), "commit", "-q", "-m", msg], check=True, env=env)
    return subprocess.run(["git", "-C", str(repo), "rev-parse", "HEAD"], check=True, env=env,
                          capture_output=True, text=True).stdout.strip()


def _backlog(states, agents=None, ready_shas=None):
    return {"verdicts_dir": VERDICTS, "agents": agents or {},
            "tasks": [{"id": k, "state": v} | ({"ready_sha": (ready_shas or {})[k]} if k in (ready_shas or {}) else {})
                      for k, v in states.items()]}


def _fixture(tmp):
    repo = tmp / "repo"
    subprocess.run(["git", "init", "-q", "-b", "work", str(repo)], check=True)
    agents = {"A1": {"branch": "a1"}, "A2": {"branch": "a2"}, "A3": {"branch": "a3"}}
    day = "2026-11-20T"
    seq = [
        # T1: ready 08:00, merged 11:00 (3 h). T2: ready 09:00, resync 10:00, ready 12:00, merged 13:00 (1 h).
        # T3: blocked 06:00 to 11:00 (5 h). T4: ready 12:00, still ready. T5: merged at 12:00, never shown
        # ready; its ready_sha is the 10:00 commit (2 h). T6: merged at 12:00, its ready_sha is missing.
        ("06:00", {"T1": "working", "T2": "working", "T3": "blocked", "T4": "working", "T5": "working"}),
        ("08:00", {"T1": "ready", "T2": "working", "T3": "blocked", "T4": "working", "T5": "working"}),
        ("09:00", {"T1": "ready", "T2": "ready", "T3": "blocked", "T4": "working", "T5": "working"}),
        ("10:00", {"T1": "ready", "T2": "resync", "T3": "blocked", "T4": "working", "T5": "working"}),
        ("11:00", {"T1": "merged", "T2": "working", "T3": "working", "T4": "working", "T5": "working"}),
        ("12:00", {"T1": "merged", "T2": "ready", "T3": "working", "T4": "ready", "T5": "merged"}),
    ]
    shas = {}
    for hhmm, states in seq:
        rs = {"T5": shas["10:00"], "T6": "0123456789abcdef0123456789abcdef01234567"} if hhmm == "12:00" else {}
        states = states | {"T6": "merged" if hhmm == "12:00" else "working"}
        shas[hhmm] = _commit(repo, f"{day}{hhmm}:00Z", {BACKLOG: _backlog(states, agents, rs)}, f"backlog {hhmm}")
    # T1 moves to the archive at 13:00, T2 merges at 13:00.
    _commit(repo, f"{day}13:00:00Z", {
        ARCHIVE: {"tasks": [{"id": "T1", "state": "merged"}]},
        BACKLOG: _backlog({"T2": "merged", "T3": "working", "T4": "ready", "T5": "merged", "T6": "merged"},
                          agents, {"T5": shas["10:00"]})},
        "archive T1, T2 merged")
    v = lambda tid, sha, item, q, samples, result, at: {  # noqa: E731
        "task_id": tid, "sha": sha, "item": item, "quality": q, "samples": samples, "result": result, "at": at}
    verdicts = [
        v("T1", "aaaa1111", "home", "Hierarchy", ["fail"] * 3, "fail", "2026-11-20T09:00:00Z"),
        v("T1", "aaaa1111", "home", "Display type", ["pass", "fail", "pass"], "pass", "2026-11-20T09:00:00Z"),
        v("T2", "bbbb2222", "heist", "Hierarchy", ["pass"] * 3, "pass", "2026-11-20T09:30:00Z"),
        v("T2", "bbbb2222", "heist", "Display type", ["fail"] * 3, "fail", "2026-11-20T09:30:00Z"),
        v("T4", "cccc3333", "result", "Hierarchy", ["pass", "fail", "fail"], "split", "2026-11-19T10:00:00Z"),
        v("T4", "cccc3333", "result", "Display type", ["unknown"] * 3, "unknown", "2026-11-19T10:00:00Z"),
    ]
    audit = "\n".join([
        "# Audit", "", "| Task | Commit | Item | Quality | Label | Critique |", "|---|---|---|---|---|---|",
        "| T1 | aaaa1111ffff | home | Hierarchy | fail | weak |",        # caught
        "| T1 | aaaa1111ffff | home | Display type | fail | thin |",     # miss
        "| T2 | bbbb2222 | heist | Hierarchy | pass | fine |",           # true pass
        "| T2 | bbbb2222 | heist | Display type | pass | fine |",        # false fail
        "| T4 | cccc3333 | result | Display type | fail | n/a here |",   # verdict unknown: left out
        "| T9 | dddd4444 | home | Hierarchy | fail | no verdict |",     # no verdict: left out
        "| T2 | bbbb2222 | heist | Hierarchy | n/a | - |", ""])
    _commit(repo, "2026-11-20T14:00:00Z", {
        VERDICTS + "T1/aaaa1111.json": verdicts[:2], VERDICTS + "T2/bbbb2222.json": verdicts[2:4],
        VERDICTS + "T4/cccc3333.json": verdicts[4:], AUDITS + "audit-x.md": audit,
        "README": "not a verdict\n"}, "verdicts and audit")
    main_sha = subprocess.run(["git", "-C", str(repo), "rev-parse", "HEAD"], check=True,
                              capture_output=True, text=True).stdout.strip()
    subprocess.run(["git", "-C", str(repo), "update-ref", f"refs/remotes/origin/{MAIN}", main_sha], check=True)
    for agent, state, due in (("A1", "active", "2026-11-20T14:30:00Z"), ("A2", "active", "2026-11-20T16:00:00Z"),
                              ("A3", "waiting", "2026-11-20T10:00:00Z")):
        subprocess.run(["git", "-C", str(repo), "checkout", "-q", "--orphan", agent.lower()], check=True)
        subprocess.run(["git", "-C", str(repo), "rm", "-rq", "--cached", "."], check=True)
        sha = _commit(repo, "2026-11-20T14:00:00Z", {f"docs/progress/status/{agent}.json": {
            "agent": agent, "agent_state": state, "expected_next_update_by": due}}, f"status {agent}")
        subprocess.run(["git", "-C", str(repo), "update-ref", f"refs/remotes/origin/{agent.lower()}", sha],
                       check=True)
    subprocess.run(["git", "-C", str(repo), "checkout", "-q", "-f", "work"], check=True)
    return repo


def self_test():
    failures = []

    def check(cond, what):
        if not cond:
            failures.append(what)

    with tempfile.TemporaryDirectory() as tmp:
        repo = _fixture(pathlib.Path(tmp))
        before = subprocess.run(["git", "-C", str(repo), "status", "--porcelain"], capture_output=True,
                                text=True).stdout
        heads = subprocess.run(["git", "-C", str(repo), "show-ref"], capture_output=True, text=True).stdout
        now = cn._ts("2026-11-20T15:00:00Z")
        text = run(repo, now=now, days=7)
        res = json.loads(run(repo, now=now, days=7, as_json=True))["metrics"]
        print(text)
        check(res["lead_time"]["value"] == 2.0, f"lead time 2.0 h (3 h, 1 h and T5's 2 h), got {res['lead_time']}")
        check(res["lead_time"]["past"] is False, "lead time of 2.0 h is not past 'over 2 h'")
        check("over 3 merges" in res["lead_time"]["text"] and "(1 timed from the ready commit" in
              res["lead_time"]["text"], f"T5 timed from its ready_sha: {res['lead_time']['text']}")
        check("1 more merged without being shown ready" in res["lead_time"]["text"], "T6 counted apart")
        check(res["oldest_ready"]["value"] == 3.0 and res["oldest_ready"]["past"] is True,
              f"T4 ready since 12:00, 3 h at 15:00, past: {res['oldest_ready']}")
        check(res["resync_rate"]["value"] == 0.2 and res["resync_rate"]["past"] is False,
              f"1 resync of 5 candidates' outcomes (4 merges, T6 included): {res['resync_rate']}")
        rates = res["gate_rates"]["value"]
        check(rates.get("Hierarchy", {}).get("catch") == 1.0 and rates["Hierarchy"]["false_fail"] == 0.0
              and rates["Hierarchy"]["past"] is False, f"Hierarchy 1 of 1 caught, 0 of 1 false: {rates}")
        check(rates.get("Display type", {}).get("catch") == 0.0 and rates["Display type"]["false_fail"] == 1.0
              and rates["Display type"]["past"] is True, f"Display type 0 of 1 caught, 1 of 1 false: {rates}")
        check(res["splits"]["value"] == 1 and res["splits"]["past"] is False,
              f"one split a day (19th and 20th): {res['splits']}")
        check(res["stalls"]["value"] == 1 and "A1" in res["stalls"]["text"] and res["stalls"]["past"] is False,
              f"A1 stalled, A2 not due, A3 not active: {res['stalls']}")
        check(res["blocked"]["value"] == 5.0 and res["blocked"]["past"] is True,
              f"T3 blocked 06:00 to 11:00, 5 h: {res['blocked']}")
        check(res["usage"]["value"] is None and res["usage"]["text"].startswith("no data"), "usage is no data")
        check("| Resync rate | 1 of 5 (20%)" in text and "| within |" in text and "| **past** |" in text,
              "the Markdown table")
        # A window that holds none of it gives "no data", never a figure.
        far = json.loads(run(repo, now=cn._ts("2026-12-30T00:00:00Z"), days=7, as_json=True))["metrics"]
        check(far["lead_time"]["value"] is None and far["lead_time"]["text"].startswith("no data"),
              "no merge in the window is no data")
        check(far["resync_rate"]["value"] is None and far["splits"]["value"] is None, "empty window: no data")
        after = subprocess.run(["git", "-C", str(repo), "status", "--porcelain"], capture_output=True,
                               text=True).stdout
        heads_after = subprocess.run(["git", "-C", str(repo), "show-ref"], capture_output=True, text=True).stdout
        check(before == after and heads == heads_after, "read-only: the working tree and refs are unchanged")
    if failures:
        for f in failures:
            print(f"FAIL: {f}")
        return 1
    print("metrics self-test: ok")
    return 0


def main(argv=None):
    ap = argparse.ArgumentParser(description=__doc__.split("\n")[0])
    ap.add_argument("--json", action="store_true")
    ap.add_argument("--fetch", action="store_true", help="git fetch origin first (refs only)")
    ap.add_argument("--days", type=int, default=7)
    ap.add_argument("--now", help="UTC time to compute at (default: now)")
    ap.add_argument("--self-test", action="store_true")
    a = ap.parse_args(argv)
    if a.self_test:
        return self_test()
    now = cn._ts(a.now) if a.now else None
    if a.now and now is None:
        ap.error("--now must be an ISO time")
    sys.stdout.write(run(ROOT, now=now, days=a.days, as_json=a.json, fetch=a.fetch))
    return 0


if __name__ == "__main__":
    sys.exit(main())
