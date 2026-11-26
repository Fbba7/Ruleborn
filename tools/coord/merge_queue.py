#!/usr/bin/env python3
"""The coordinator's cycle, part 2: the merge-then-test queue.

    python3 tools/coord/cycle.py --merge --dry-run   # print what it would do; push nothing
    python3 tools/coord/cycle.py --merge             # run the queue: lock, check, move main
    python3 tools/coord/cycle.py --self-test         # this module's fixture tests included

Docs: docs/guides/agent-protocol.md, "The merge queue" (steps 1 to 5,
"Bookkeeping commits", "Batching", "After a merge") and "One cycle" (the
merge lock), and docs/progress/lead.md, "Running a cycle". Backlog task
BT-01b.

What one run does
-----------------
It fetches origin and reads the backlog and status/lead.json from main as
origin has it. Then, round by round:

1. **The lock.** `merging` in status/lead.json, when set and not expired,
   means another cycle is merging: the run stops there and changes nothing.
   An expired lock is cleared, and the clearing is noted in the report and
   in the commit that clears it.
2. **The ready tasks**, critical ones first, then in the order they became
   ready (`ready_at`, else `claim.seen_at`, else `updated_at`). A
   `ready_sha` the repository does not hold, or a change outside the task's
   files (`owners.py`'s rule, against main's head), sends the task to
   `resync` with the reason and a message to its agent. A ready task waiting
   more than 2 hours gets an owner-inbox entry.
3. **The candidate**: up to three ready tasks whose claimed `files` are
   disjoint (`owners.files_overlap`), each merged with `git merge --no-ff`
   onto main's head, in a temporary worktree. A task that conflicts is
   aborted out of the candidate and set to `resync`, with the conflicting
   paths in a message; the others go on. A task the batch already failed is
   taken alone.
4. **The lock is pushed** to main before any check runs: `merging` is
   `{candidate_sha, task_ids, started_at, expires_at}`, expiring after
   `2 × check_minutes + 10` minutes (60 with the backlog's 25). A rejected
   push means main moved: the round starts again from the new head.
5. **The checks**, through `tools/run_checks.sh` (its sandbox, its log
   outside the repository): the full checks on the candidate. They are
   reused from the builder's pre-check only for a single task whose
   `precheck` is PASS, exit 0, "All checks passed." at `ready_sha`, and
   whose candidate differs from `ready_sha` only under `docs/progress/`;
   then only the documentation check runs, and the full checks run on main
   after the merge. A task with `gate_items` also gets the UI kit's guard,
   unless its status or handoff records `ui guard: OK` at its `ready_sha`;
   and if the merge changed any of its own files, its gate verdict does not
   carry over, so it is held for the lead's gate run instead.
6. **On a pass** main moves: fast-forward to the candidate when main has not
   moved; when main gained only `docs/progress/` commits, the candidate is
   merged onto the new head and only the documentation check runs again.
   The lock commit is one of those, so the usual case is the merge (as in
   "Merge BT-01a candidate 8107ba62 onto main (checks passed at 8107ba62)"). One bookkeeping commit on top sets each
   task `merged` with its `merged_sha`, clears the lock and sets
   `last_merged`. If main gained code meanwhile, or another cycle took the
   lock, main is not moved: the lock is cleared and the round starts again.
7. **On a fail** a batch is split: each of its tasks is checked alone in the
   next rounds. A single task is set to `resync`, `attempts` + 1, with the
   failure lines in `resync_reason` and in a message to its agent; the lock
   is cleared in the same commit.
8. **Main red after a reused pre-check**: the merge is reverted at once and
   the task set to `resync`. If the revert cannot be pushed, the owner inbox
   says main is red.

The checks that cannot run at all (no sandbox, a lost run) clear the lock and
write an owner-inbox entry; nothing is set to `resync` for them.

`--dry-run` builds the candidate in a temporary worktree and prints every
action it would take, and stops before the first push: nothing is written to
the checkout and nothing is pushed. Every commit this module makes touches
only `docs/progress/**`, except the merge commits that move main to a
candidate that passed.
"""

import datetime as dt
import json
import os
import pathlib
import shutil
import subprocess
import sys
import tempfile
import time

sys.path.insert(0, str(pathlib.Path(__file__).resolve().parent))
import cycle as cy
import cycle_needed as cn
import owners

INBOX = "docs/progress/owner-inbox.md"
DOCS = "docs/progress/"
#: What the documentation check runs, through run_checks.sh (which counts a
#: run as passed only with this line in its log).
DOCS_CMD = "python3 tools/check_docs_consistency.py && echo 'All checks passed.'"
GUARD = "tools/ui_bake/guard.sh"
GUARD_CMD = f"bash {GUARD} && echo 'All checks passed.'"
WHO = "coordinator (merge queue)"
MAX_BATCH = 3
FAIL_LINES = 12
# How long the queue waits for a started run to write its pid file (seconds).
START_GRACE = 120
ACK_HOURS = 2


def _iso(t: dt.datetime) -> str:
    return t.astimezone(dt.timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ")


def _s(sha):
    return (sha or "")[:8]


# --- git ---------------------------------------------------------------------

class Git(cy.Repo):
    """The coordinator's checkout: read and write, never with hooks."""

    def __init__(self, path, remote=cy.REMOTE, main=cy.MAIN, env=None):
        super().__init__(path, remote, main)
        self.env = env

    def git(self, *args, check=True, cwd=None):
        r = subprocess.run(["git", "-c", "core.hooksPath=/dev/null", "-C", str(cwd or self.path),
                            *args], capture_output=True, text=True, env=self.env, check=False)
        if check and r.returncode:
            raise subprocess.CalledProcessError(r.returncode, args, r.stdout, r.stderr)
        return r.stdout if check else r

    def sha(self, rev):
        if not rev:
            return None
        r = self.git("rev-parse", "--verify", "--quiet", f"{rev}^{{commit}}", check=False)
        return r.stdout.strip() if r.returncode == 0 else None

    def ancestor(self, a, b) -> bool:
        return self.git("merge-base", "--is-ancestor", a, b, check=False).returncode == 0

    def paths(self, a, b) -> list:
        return [p for p in self.git("diff", "--name-only", "--no-renames", a, b).splitlines() if p]

    def only_docs(self, a, b) -> bool:
        return all(p.startswith(DOCS) for p in self.paths(a, b))

    def push_main(self, sha) -> bool:
        """A non-force push of sha to main: False when main moved meanwhile."""
        r = self.git("push", "-q", self.remote, f"{sha}:refs/heads/{self.main}", check=False)
        return r.returncode == 0


class Tree:
    """A temporary detached worktree of the coordinator's checkout."""

    def __init__(self, repo: Git, base: str):
        self.repo, self.base = repo, base

    def __enter__(self):
        self.dir = tempfile.mkdtemp(prefix="coord-merge-")
        self.repo.git("worktree", "add", "-q", "--detach", self.dir, self.base)
        return self

    def __exit__(self, *exc):
        self.repo.git("worktree", "remove", "--force", self.dir, check=False)
        shutil.rmtree(self.dir, ignore_errors=True)
        self.repo.git("worktree", "prune", check=False)

    def g(self, *args, check=True):
        return self.repo.git(*args, check=check, cwd=self.dir)

    def head(self):
        return self.g("rev-parse", "HEAD").strip()

    def reset(self, sha):
        self.g("reset", "-q", "--hard", sha)

    def merge(self, sha, message) -> list:
        """Merge sha with --no-ff; on a conflict abort and return the paths."""
        r = self.g("merge", "--no-ff", "--no-edit", "-m", message, sha, check=False)
        if r.returncode == 0:
            return []
        paths = [p for p in self.g("diff", "--name-only", "--diff-filter=U").splitlines() if p]
        self.g("merge", "--abort", check=False)
        return paths or [f"(merge failed: {(r.stderr or r.stdout).strip().splitlines()[-1:]})"]

    def read(self, path):
        p = pathlib.Path(self.dir) / path
        return p.read_text() if p.exists() else None

    def write(self, path, text):
        p = pathlib.Path(self.dir) / path
        p.parent.mkdir(parents=True, exist_ok=True)
        p.write_text(text)

    def commit(self, message) -> str:
        self.g("add", "-A", "--", DOCS)
        self.g("commit", "-q", "--allow-empty", "-m", message)
        return self.head()

    def revert(self, sha, message) -> bool:
        r = self.g("revert", "--no-edit", "-m", "1", sha, check=False)
        if r.returncode:
            self.g("revert", "--abort", check=False)
            return False
        self.g("commit", "-q", "--amend", "-m", message)
        return True


# --- the checks --------------------------------------------------------------

class Checks:
    """tools/run_checks.sh from the coordinator's own checkout (never the
    candidate's copy), polled until the run ends."""

    def __init__(self, repo: Git, env=None, full_cmd=None, docs_cmd=DOCS_CMD,
                 guard_cmd=GUARD_CMD, poll=15, timeout_min=120, start_grace=START_GRACE):
        self.repo, self.env = repo, env
        self.cmds = {"full": full_cmd, "docs": docs_cmd, "guard": guard_cmd}
        self.poll, self.timeout = poll, timeout_min * 60
        self.start_grace = start_grace

    def _env(self, kind):
        env = dict(self.env if self.env is not None else os.environ)
        cmd = self.cmds[kind]
        if cmd:
            env["CHECK_CMD"] = cmd
        else:
            env.pop("CHECK_CMD", None)
        if kind != "full":
            # run_checks.sh keys its logs by sha: each kind gets its own folder.
            sub = pathlib.Path(env.get("CHECK_DIR", "/tmp")) / f"coord-{kind}"
            sub.mkdir(parents=True, exist_ok=True)
            env["CHECK_DIR"] = str(sub)
        return env

    def _sh(self, kind, *args):
        script = self.repo.path / "tools" / "run_checks.sh"
        return subprocess.run(["bash", str(script), *args], capture_output=True, text=True,
                              env=self._env(kind), check=False)

    def _pid_file(self, kind, sha) -> pathlib.Path:
        # run_checks.sh's own naming: <CHECK_DIR>/check-<full sha>.pid.
        d = pathlib.Path(self._env(kind).get("CHECK_DIR") or "/tmp")
        return d / f"check-{self.repo.sha(sha) or sha}.pid"

    def _settle(self, kind, sha):
        """Wait for the runner start launched to write its pid file.

        start waits five seconds for it; a loaded machine can take longer.
        A result read before the file is there says LOST and removes the
        run's worktree, so the run that follows fails or is lost. Past the
        grace period, the result that follows tells what happened."""
        pidf, waited = self._pid_file(kind, sha), 0
        while waited < self.start_grace:
            try:
                if pidf.read_text().strip():
                    return
            except OSError:
                pass
            time.sleep(self.poll)
            waited += self.poll

    def result(self, kind, sha) -> dict:
        r = self._sh(kind, "result", sha)
        try:
            return json.loads(r.stdout.strip().splitlines()[-1])
        except (IndexError, json.JSONDecodeError):
            return {"sha": sha, "state": "ERROR", "summary": (r.stderr or r.stdout).strip()[-300:]}

    def run(self, kind, sha) -> dict:
        res = self.result(kind, sha)
        if res["state"] == "PASS":
            return res
        if res["state"] != "RUNNING":
            r = self._sh(kind, "start", sha)
            if r.returncode:
                lines = (r.stderr or r.stdout).strip().splitlines()
                return {"sha": sha, "state": "ERROR",
                        "summary": lines[0] if lines else f"start exited {r.returncode}"}
            self._settle(kind, sha)
        waited = 0
        while True:
            res = self.result(kind, sha)
            if res["state"] == "LOST":
                # result looks for the DONE file before it looks for the
                # runner, so a run that ends between the two reads as LOST.
                # The DONE file is in place before the runner exits: a second
                # read tells such a run from one that was killed.
                res = self.result(kind, sha)
            if res["state"] != "RUNNING":
                break
            if waited >= self.timeout:
                return {**res, "state": "TIMEOUT",
                        "summary": f"still running after {self.timeout // 60} minutes"}
            time.sleep(self.poll)
            waited += self.poll
        if res["state"] == "FAIL":
            res["lines"] = _fail_lines(res.get("log"))
        return res


def _fail_lines(log) -> list:
    try:
        text = pathlib.Path(log).read_text(errors="replace")
    except (OSError, TypeError):
        return []
    lines = [ln for ln in text.splitlines() if ln.strip() and not ln.startswith("DONE exit=")]
    return lines[-FAIL_LINES:]


# --- the bookkeeping ---------------------------------------------------------

class Book:
    """The changes a round makes to main's docs/progress files."""

    def __init__(self, backlog, lead, inbox, archive, now, who=WHO):
        self.backlog, self.lead, self.inbox = backlog, lead, inbox
        self.archive, self.now, self.who = archive, now, who
        self.notes = []          # one line each, for the commit message
        self.dirty = False

    def task(self, tid):
        return next(t for t in self.backlog["tasks"] if t["id"] == tid)

    def _touch(self, t):
        t["updated_at"], t["updated_by"] = _iso(self.now), self.who
        self.backlog["updated_at"], self.backlog["updated_by"] = _iso(self.now), self.who
        self.dirty = True

    def _next_message(self):
        n = 0
        for m in self.backlog.get("messages", []) + (self.archive or {}).get("messages", []):
            if str(m.get("id", "")).startswith("M") and m["id"][1:].isdigit():
                n = max(n, int(m["id"][1:]))
        return f"M{n + 1}"

    def message(self, to, text):
        mid = self._next_message()
        self.backlog.setdefault("messages", []).append(
            {"id": mid, "to": to, "text": f"{text} Add {mid} to your acks.",
             "sent_at": _iso(self.now), "ack_by": _iso(self.now + dt.timedelta(hours=ACK_HOURS)),
             "acked_at": None})
        self.dirty = True
        return mid

    def resync(self, tid, reason):
        t = self.task(tid)
        t["state"] = "resync"
        t["attempts"] = int(t.get("attempts") or 0) + 1
        t["resync_reason"] = reason
        self._touch(t)
        agent = owners.agent_of(t)
        if agent:
            self.message(agent, f"From the merge queue: {tid} is set to resync at ready "
                                f"{_s(t.get('ready_sha'))}: {reason} Merge main into your branch, "
                                "fix it, run the pre-check and mark the task ready again.")
        self.notes.append(f"{tid} to resync: {reason}")

    def merged(self, tid, sha):
        t = self.task(tid)
        t["state"], t["merged_sha"] = "merged", sha
        t.pop("resync_reason", None)
        self._touch(t)
        self.lead["last_merged"] = {"task_id": tid, "sha": _s(sha)}
        self.notes.append(f"{tid} merged ({_s(sha)})")

    def lock(self, candidate, tids, minutes):
        self.lead["merging"] = {"candidate_sha": candidate, "task_ids": list(tids),
                                "started_at": _iso(self.now),
                                "expires_at": _iso(self.now + dt.timedelta(minutes=minutes))}
        self._lead_touch()

    def unlock(self, note=None):
        if self.lead.get("merging") is not None:
            self.lead["merging"] = None
            self._lead_touch()
        if note:
            self.notes.append(note)

    def _lead_touch(self):
        self.lead["updated_at"] = _iso(self.now)
        self.dirty = True

    def owner(self, title, what, done, needs, key=None):
        """An owner-inbox entry, newest first, once per key (default: the title)."""
        text = self.inbox or "# Owner inbox\n\n"
        key = key or title
        if any(ln.startswith("## ") and key in ln for ln in text.splitlines()):
            return False
        entry = (f"## {self.now.strftime('%Y-%m-%d %H:%MZ')}: {title}\n\n"
                 f"- **What:** {what}\n- **Done:** {done}\n- **Needs the owner:** {needs}\n\n")
        i = text.find("\n## ")
        self.inbox = text + "\n" + entry if i < 0 else text[:i + 1] + entry + text[i + 1:]
        self.dirty = True
        self.notes.append(f"owner inbox: {title}")
        return True

    def write(self, tree: Tree):
        dump = lambda o: json.dumps(o, indent=2, ensure_ascii=False) + "\n"
        tree.write(cy.BACKLOG, dump(self.backlog))
        tree.write(cy.LEAD, dump(self.lead))
        if self.inbox is not None:
            tree.write(INBOX, self.inbox)


def _book(repo: Git, head, now):
    backlog = repo.json_at(head, cy.BACKLOG)
    if backlog is None:
        raise SystemExit(f"no readable {cy.BACKLOG} on {repo.main} at {_s(head)}")
    return Book(backlog, repo.json_at(head, cy.LEAD) or {"agent": "lead"},
                repo.show(head, INBOX), repo.json_at(head, cy.ARCHIVE), now)


# --- reading the tasks -------------------------------------------------------

def ready_time(t):
    claim = t.get("claim") or {}
    return t.get("ready_at") or claim.get("seen_at") or t.get("updated_at") or ""


def ready_tasks(backlog) -> list:
    ready = [t for t in backlog["tasks"] if t.get("state") == "ready"]
    return sorted(ready, key=lambda t: (not t.get("critical"), ready_time(t), t["id"]))


def _branch(backlog, t):
    claim = t.get("claim") or {}
    agent = owners.agent_of(t)
    return claim.get("branch") or (backlog.get("agents", {}).get(agent) or {}).get("branch")


def _agent_text(repo, backlog, t, sha):
    """The agent's status file and handoff, from its branch (else at ready_sha)."""
    agent = owners.agent_of(t)
    branch = _branch(backlog, t)
    revs = ([repo.ref(branch)] if branch else []) + [sha]
    status = handoff = None
    for rev in revs:
        if status is None:
            status = repo.json_at(rev, f"docs/progress/status/{agent}.json")
        if handoff is None:
            handoff = repo.show(rev, f"docs/progress/{agent}.md")
    return status or {}, handoff or ""


def precheck_ok(status, sha) -> bool:
    p = status.get("precheck") or {}
    return (p.get("state") == "PASS" and p.get("exit") == 0
            and p.get("summary") == "All checks passed."
            and bool(p.get("sha")) and sha.startswith(p["sha"]) and len(p["sha"]) >= 7)


def guard_ok(status, handoff, sha) -> bool:
    text = json.dumps(status) + "\n" + handoff
    return any("ui guard: OK" in ln and sha[:8] in ln for ln in text.splitlines())


def pick(ok: list, alone: set, max_batch=MAX_BATCH) -> list:
    """The first ready task and up to max_batch - 1 more with disjoint files."""
    if not ok:
        return []
    first = ok[0]
    if first[0]["id"] in alone or max_batch <= 1:
        return [first]
    batch = [first]
    for t, sha in ok[1:]:
        if len(batch) >= max_batch:
            break
        if t["id"] in alone:
            continue
        if all(not owners.files_overlap(t.get("files", []), b.get("files", [])) for b, _ in batch):
            batch.append((t, sha))
    return batch


# --- the queue ---------------------------------------------------------------

class Report:
    def __init__(self, dry_run):
        self.dry_run, self.actions, self.merged, self.resync = dry_run, [], [], []

    def act(self, kind, target, text):
        self.actions.append({"kind": kind, "target": target, "text": text})

    def render(self) -> str:
        lines = [f"{a['kind']:>8}  {a['target']}: {a['text']}" for a in self.actions]
        lines = lines or ["nothing to do"]
        if self.dry_run:
            lines.append("dry run: nothing written, nothing pushed")
        else:
            lines.append(f"merged: {', '.join(self.merged) or 'none'}; "
                         f"resync: {', '.join(dict.fromkeys(self.resync)) or 'none'}")
        return "\n".join(lines)


def _message(subject, notes, trailers):
    body = "\n".join(f"- {n}" for n in notes)
    tail = "\n".join(trailers)
    return subject + (f"\n\n{body}" if body else "") + (f"\n\n{tail}" if tail else "")


def run_queue(repo: Git, checks: Checks, dry_run=True, now_fn=cn._now, fetch=True,
              max_batch=MAX_BATCH, max_candidates=3, trailers=(), max_rounds=12) -> Report:
    rep = Report(dry_run)
    alone, skip, tested = set(), set(), 0
    for _ in range(max_rounds):
        if dry_run:
            # Nothing is pushed, so a task set to resync is still ready on main.
            skip.update(rep.resync)
        if fetch:
            repo.fetch()
        head = repo.sha(repo.ref(repo.main))
        now = now_fn()
        book = _book(repo, head, now)
        minutes = 2 * int(book.backlog.get("check_minutes") or 25) + 10

        # 1. The lock.
        lock = book.lead.get("merging")
        if lock:
            expires = cn._ts(lock["expires_at"]) if lock.get("expires_at") else None
            ids = ", ".join(lock.get("task_ids") or []) or "?"
            if expires and expires > now:
                rep.act("skip", "lock", f"held for {ids} (candidate {_s(lock.get('candidate_sha'))}) "
                                        f"until {lock['expires_at']}: no merge this cycle")
                break
            note = (f"expired merge lock cleared (candidate {_s(lock.get('candidate_sha'))}, "
                    f"{ids}, expired {lock.get('expires_at')})")
            book.unlock(note)
            rep.act("lock", "lock", note)

        # 2. The ready tasks.
        ready = [t for t in ready_tasks(book.backlog) if t["id"] not in skip]
        if ready:
            oldest = ready[0] if not ready[0].get("critical") else min(ready, key=ready_time)
            since = ready_time(oldest)
            if since and now - cn._ts(since) > cy.LONG_WAIT:
                hours = (now - cn._ts(since)).total_seconds() / 3600
                if book.owner(f"{oldest['id']} ready since {since} and not merged",
                              f"{oldest['id']} has waited {hours:.1f} hours in the merge queue "
                              f"(ready {_s(oldest.get('ready_sha'))}; the protocol's alert is 2 hours).",
                              "the merge queue keeps taking ready tasks in order.",
                              "nothing, unless the queue stays stuck: the lead's write-up says why.",
                              key=f"{oldest['id']} ready since {since}"):
                    rep.act("inbox", oldest["id"], f"waiting {hours:.1f} h: owner-inbox entry")
        ok = []
        for t in ready:
            sha = repo.sha(t.get("ready_sha"))
            if not sha:
                book.resync(t["id"], f"ready_sha {t.get('ready_sha')} is not in the repository "
                                     f"(fetched from {repo.remote}); push the branch.")
                rep.act("resync", t["id"], "ready_sha not found")
                rep.resync.append(t["id"])
                continue
            bad = owners.unowned(t, owners.changed(head, sha, repo.path))
            if bad:
                book.resync(t["id"], "changes outside the task's files: " + ", ".join(bad[:10])
                            + (f" and {len(bad) - 10} more" if len(bad) > 10 else "") + ".")
                rep.act("resync", t["id"], f"{len(bad)} path(s) outside its files")
                rep.resync.append(t["id"])
                continue
            ok.append((t, sha))

        batch = pick(ok, alone, max_batch) if tested < max_candidates else []
        if ok and not batch:
            rep.act("stop", "queue", f"{max_candidates} candidate(s) checked this run; "
                                     f"{len(ok)} ready task(s) wait for the next")
        if not batch:
            if not ok and not ready and not book.dirty:
                rep.act("idle", "queue", "no ready task")
            _flush(repo, book, rep, head, "Merge queue: bookkeeping", trailers)
            break

        with Tree(repo, head) as tree:
            # 3. The candidate.
            taken = []
            for t, sha in batch:
                conflicts = tree.merge(sha, f"Merge {t['id']} (ready {_s(sha)})")
                if conflicts:
                    book.resync(t["id"], "conflicts with main: " + ", ".join(conflicts) + ".")
                    rep.act("resync", t["id"], "conflict: " + ", ".join(conflicts))
                    rep.resync.append(t["id"])
                else:
                    taken.append((t, sha))
            if not taken:
                _flush(repo, book, rep, head, "Merge queue: conflicts to resync", trailers)
                continue
            cand = tree.head()
            ids = [t["id"] for t, _ in taken]
            one = taken[0] if len(taken) == 1 else None
            reuse = False
            guard = False
            hold = []
            for t, sha in taken:
                status, handoff = _agent_text(repo, book.backlog, t, sha)
                if t.get("gate_items"):
                    mine = [p for p in repo.paths(sha, cand) if owners.owned(t.get("files", []), p)]
                    if mine:
                        hold.append((t, mine))
                    if tree.read(GUARD) is not None and not guard_ok(status, handoff, sha):
                        guard = True
                if one and t is one[0]:
                    reuse = (precheck_ok(status, sha) and repo.only_docs(sha, cand))
            if hold:
                # The gate re-runs on this candidate (protocol step 5): the
                # lead's job. These tasks leave this run; the rest go on.
                for t, mine in hold:
                    rep.act("hold", t["id"], "the merge changed its own files ("
                            + ", ".join(mine[:5]) + "): its gate verdict does not carry over; "
                            "the lead re-runs the gate on the candidate")
                    skip.add(t["id"])
                continue
            how = (f"checks reused from the pre-check at {_s(one[1])}" if reuse
                   else "full checks" + (" and the UI guard" if guard else ""))
            rep.act("candidate", "+".join(ids), f"{_s(cand)} on main {_s(head)}: {how}")

            if dry_run:
                rep.act("would", "lock", f"push merging {{candidate {_s(cand)}, {ids}}} for "
                                         f"{minutes} min, run the {how}, then move main")
                rep.act("would", "push", "nothing pushed (dry run)"
                        + (f"; pending bookkeeping: {'; '.join(book.notes)}" if book.notes else ""))
                break

            # 4. The lock, pushed before any check.
            book.lock(cand, ids, minutes)
            tree.reset(head)
            book.write(tree)
            lock_sha = tree.commit(_message(
                f"Merge queue: lock for {' and '.join(ids)} (candidate {_s(cand)})",
                book.notes, trailers))
            if not repo.push_main(lock_sha):
                rep.act("retry", "lock", "main moved before the lock was pushed: starting again")
                continue
            rep.act("lock", "+".join(ids), f"pushed ({_s(lock_sha)}), expires {book.lead['merging']['expires_at']}")
            tested += 1

            # 5. The checks.
            res = checks.run("docs" if reuse else "full", cand)
            if res["state"] == "PASS" and guard:
                res = checks.run("guard", cand)
            if res["state"] not in ("PASS", "FAIL"):
                _cannot(repo, checks, rep, ids, res, now_fn, trailers)
                break
            if res["state"] == "FAIL":
                _failed(repo, rep, taken, res, alone, now_fn, trailers)
                continue

            # 6. Main moves.
            moved = _move(repo, checks, rep, tree, taken, cand, head, lock_sha, now_fn, trailers)
            if moved and reuse:
                _after(repo, checks, rep, one[0], moved, now_fn, trailers)
    return rep


def _flush(repo, book, rep, head, subject, trailers) -> bool:
    """Push the round's bookkeeping, if any; True when there was none or it landed."""
    if not book.dirty:
        return True
    if rep.dry_run:
        rep.act("would", "push", "bookkeeping: " + "; ".join(book.notes))
        return True
    with Tree(repo, head) as tree:
        book.write(tree)
        sha = tree.commit(_message(subject, book.notes, trailers))
        if repo.push_main(sha):
            rep.act("push", "main", f"{_s(sha)}: " + "; ".join(book.notes))
            return True
    rep.act("retry", "main", "main moved before the bookkeeping was pushed")
    return False


def _relock(repo, now_fn, subject, trailers, change, attempts=4):
    """Apply change(book) on main's newest head and push it; the pushed sha or None."""
    for _ in range(attempts):
        repo.fetch()
        head = repo.sha(repo.ref(repo.main))
        book = _book(repo, head, now_fn())
        if change(book) is False:
            return None
        with Tree(repo, head) as tree:
            book.write(tree)
            sha = tree.commit(_message(subject, book.notes, trailers))
            if repo.push_main(sha):
                return sha
    return None


def _ours(book, cand) -> bool:
    lock = book.lead.get("merging") or {}
    return lock.get("candidate_sha") == cand


def _cannot(repo, checks, rep, ids, res, now_fn, trailers):
    summary = res.get("summary") or res["state"]
    rep.act("error", "+".join(ids), f"the checks did not run to the end ({res['state']}): {summary}")

    def change(book):
        if _ours(book, res.get("sha")):
            book.unlock(f"lock cleared: the checks did not run ({res['state']}: {summary})")
        book.owner("the merge queue cannot run the checks",
                   f"run_checks.sh gave {res['state']} for candidate {_s(res.get('sha'))} "
                   f"({', '.join(ids)}): {summary}",
                   "the lock is cleared and no task is set to resync; the tasks stay ready.",
                   "nothing, if the next cycle runs them; otherwise the checks' sandbox "
                   "(bubblewrap, or CHECK_USER) on the coordinator's machine.",
                   key="the merge queue cannot run the checks")
    sha = _relock(repo, now_fn, "Merge queue: lock cleared, the checks did not run", trailers, change)
    rep.act("push" if sha else "error", "main", f"lock cleared ({_s(sha)})" if sha else
            "could not clear the lock: it expires on its own")


def _failed(repo, rep, taken, res, alone, now_fn, trailers):
    ids = [t["id"] for t, _ in taken]
    lines = res.get("lines") or []
    summary = res.get("summary") or "the checks failed"
    if len(taken) > 1:
        alone.update(ids)
        rep.act("split", "+".join(ids), f"the batch failed ({summary}): each is checked alone")

        def change(book):
            if not _ours(book, res.get("sha")):
                return False
            book.unlock(f"batch {' and '.join(ids)} failed ({summary}); each re-checked alone")
        subject = f"Merge queue: batch {' and '.join(ids)} failed, lock cleared"
    else:
        tid = ids[0]
        reason = f"the checks failed on candidate {_s(res.get('sha'))}: {summary}" + (
            "\n" + "\n".join(lines) if lines else "")
        rep.act("resync", tid, f"checks failed: {summary}")
        rep.resync.append(tid)

        def change(book):
            book.resync(tid, reason)
            if _ours(book, res.get("sha")):
                book.unlock()
        subject = f"Merge queue: {tid} to resync (checks failed), lock cleared"
    sha = _relock(repo, now_fn, subject, trailers, change)
    rep.act("push" if sha else "error", "main", f"{_s(sha)}" if sha else
            "could not push the result: the lock expires on its own")


def _move(repo, checks, rep, tree, taken, cand, base, lock_sha, now_fn, trailers, attempts=4):
    """Move main to the candidate that passed; the sha that brought it, or None."""
    ids = [t["id"] for t, _ in taken]
    for _ in range(attempts):
        repo.fetch()
        head = repo.sha(repo.ref(repo.main))
        book = _book(repo, head, now_fn())
        if not _ours(book, cand):
            rep.act("abort", "+".join(ids), "the lock is no longer this candidate's (expired and "
                                            "taken by another cycle): main not moved")
            return None
        if head == base or repo.ancestor(head, cand):
            tree.reset(cand)
            landed = cand
        elif repo.only_docs(base, head):
            tree.reset(head)
            if tree.merge(cand, f"Merge {' and '.join(ids)} candidate {_s(cand)} onto main "
                                f"(checks passed at {_s(cand)})"):
                rep.act("retry", "+".join(ids), "the candidate conflicts with main's newer "
                                                "bookkeeping: checked again from the new head")
                _relock(repo, now_fn, "Merge queue: lock cleared, main moved", trailers,
                        lambda b: b.unlock("lock cleared: main's bookkeeping conflicts "
                                           f"with candidate {_s(cand)}") if _ours(b, cand) else False)
                return None
            landed = tree.head()
        else:
            rep.act("retry", "+".join(ids), "main gained code while the checks ran: "
                                            "checked again from the new head")
            _relock(repo, now_fn, "Merge queue: lock cleared, main moved", trailers,
                    lambda b: b.unlock(f"lock cleared: main gained code during candidate "
                                       f"{_s(cand)}'s checks") if _ours(b, cand) else False)
            return None
        # The bookkeeping, from main's newest files: the candidate's copy is older.
        for t, _ in taken:
            book.merged(t["id"], landed)
        book.unlock()
        book.write(tree)
        final = tree.commit(_message(f"Merge queue: {' and '.join(ids)} merged ({_s(landed)}); "
                                     "lock cleared", book.notes, trailers))
        if landed != cand:
            res = checks.run("docs", final)
            if res["state"] != "PASS":
                rep.act("error", "+".join(ids), f"the documentation check failed after the merge "
                                                f"onto main: {res.get('summary')}")
                _failed(repo, rep, taken, {**res, "sha": cand}, set(), now_fn, trailers)
                return None
        if repo.push_main(final):
            rep.act("merged", "+".join(ids), f"main at {_s(final)} (merged at {_s(landed)})")
            rep.merged.extend(ids)
            return landed
        rep.act("retry", "main", "main moved before the merge was pushed: merging again")
    rep.act("error", "+".join(ids), "main kept moving: not merged; the lock expires on its own")
    return None


def _after(repo, checks, rep, task, landed, now_fn, trailers):
    """The full checks on main after a merge that reused the pre-check."""
    tid = task["id"]
    res = checks.run("full", landed)
    if res["state"] == "PASS":
        rep.act("checked", tid, f"main passed the full checks after the merge ({_s(landed)})")
        return
    if res["state"] != "FAIL":
        rep.act("error", tid, f"the full checks on main did not run to the end: {res.get('summary')}")
        return
    summary = res.get("summary")
    lines = res.get("lines") or []
    for _ in range(4):
        repo.fetch()
        head = repo.sha(repo.ref(repo.main))
        book = _book(repo, head, now_fn())
        with Tree(repo, head) as tree:
            if not tree.revert(landed, f"Revert {tid}'s merge {_s(landed)}: main failed the full "
                                       f"checks after it ({summary})"):
                break
            book.resync(tid, f"main failed the full checks after the merge at {_s(landed)} "
                             f"(the pre-check was reused); the merge is reverted: {summary}"
                        + ("\n" + "\n".join(lines) if lines else ""))
            book.task(tid)["merged_sha"] = None
            book.write(tree)
            sha = tree.commit(_message(f"Merge queue: {tid} reverted, to resync", book.notes,
                                       trailers))
            if repo.push_main(sha):
                rep.act("revert", tid, f"main failed after the merge ({summary}): reverted at {_s(sha)}")
                rep.merged.remove(tid)
                rep.resync.append(tid)
                return
    rep.act("error", tid, "main is red and the revert could not be pushed")

    def change(book):
        book.owner(f"main is red after {tid}'s merge",
                   f"the full checks failed on main at {_s(landed)} after {tid} merged on its "
                   f"reused pre-check: {summary}",
                   "the revert could not be made or pushed; the next lead cycle retries it.",
                   "nothing, unless main is still red at the next cycle.",
                   key=f"main is red after {tid}'s merge")
    _relock(repo, now_fn, "Merge queue: main red", trailers, change)


# --- self-test: fixture branches in local bare repositories ------------------

STUB_FULL = ("if ls FAIL* >/dev/null 2>&1; then echo '== unit tests =='; "
             "echo 'FAILED: test_x'; exit 1; fi; echo '== unit tests =='; echo 'All checks passed.'")
STUB_DOCS = ("if [ -e docs/progress/DOCS_FAIL ]; then echo '== docs =='; echo 'docs broken'; "
             "exit 1; fi; echo 'All checks passed.'")


def _fixture(tmp: pathlib.Path):
    """origin.git with main, a ready task on each of four branches, and the
    real run_checks.sh; returns (coord, git, env)."""
    env = {"GIT_AUTHOR_NAME": "t", "GIT_AUTHOR_EMAIL": "t@example.invalid",
           "GIT_COMMITTER_NAME": "t", "GIT_COMMITTER_EMAIL": "t@example.invalid",
           "GIT_CONFIG_GLOBAL": "/dev/null", "GIT_CONFIG_NOSYSTEM": "1",
           "PATH": os.environ.get("PATH", "/usr/bin:/bin"), "HOME": str(tmp),
           "CHECK_UNSANDBOXED": "1", "CHECK_DIR": str(tmp / "runs")}
    (tmp / "runs").mkdir()

    def git(cwd, *args):
        return subprocess.run(["git", "-C", str(cwd), *args], check=True, capture_output=True,
                              text=True, env=env).stdout

    origin, work = tmp / "origin.git", tmp / "work"
    git(tmp, "init", "-q", "--bare", "-b", "main", str(origin))
    git(tmp, "init", "-q", "-b", "main", str(work))
    git(work, "remote", "add", "origin", str(origin))

    def write(path, text):
        p = work / path
        p.parent.mkdir(parents=True, exist_ok=True)
        p.write_text(text if isinstance(text, str) else json.dumps(text, indent=2) + "\n")

    def commit(msg):
        git(work, "add", "-A")
        git(work, "commit", "-q", "-m", msg)
        return git(work, "rev-parse", "HEAD").strip()

    T = "2026-11-17T{}:00Z".format
    agents = {a: {"branch": f"b/{a.lower()}"} for a in ("A", "B", "C", "D", "E")}

    def task(tid, agent, files, ready_at, **kw):
        t = {"id": tid, "assigned_to": agent, "files": files, "deps": [], "gate_items": [],
             "attempts": 0, "critical": False, "state": "ready", "ready_sha": None,
             "merged_sha": None, "ready_at": ready_at,
             "claim": {"agent": agent, "branch": agents[agent]["branch"], "seen_at": ready_at}}
        t.update(kw)
        return t

    backlog = {"check_minutes": 25, "agents": agents, "messages": [{"id": "M7", "to": "A"}],
               "tasks": [task("ta", "A", ["src/a/**"], T("11:00")),
                         task("tb", "B", ["src/b/**"], T("11:10")),
                         task("tc", "C", ["src/c/**"], T("11:20")),
                         task("td", "D", ["src/shared.txt"], T("11:30")),
                         task("te", "E", ["src/e/**"], T("09:00"), state="working")]}
    (work / "tools").mkdir()
    shutil.copy(pathlib.Path(__file__).resolve().parent.parent / "run_checks.sh",
                work / "tools" / "run_checks.sh")
    write("src/shared.txt", "base\n")
    write(cy.BACKLOG, backlog)
    write(cy.LEAD, {"agent": "lead", "merging": None, "last_merged": None})
    write(INBOX, "# Owner inbox\n\nIntro.\n\n## 2026-11-01 00:00Z: old\n\n- **What:** x\n")
    commit("main")
    git(work, "push", "-q", "origin", "main")

    readies = {}

    def branch(agent, files, status=None):
        git(work, "checkout", "-q", "-B", agents[agent]["branch"], "main")
        for path, text in files.items():
            write(path, text)
        sha = commit(f"{agent} work")
        if status is not None:
            status = {"agent": agent, **status}
            if status.get("precheck") == "PASS":
                status["precheck"] = {"sha": sha, "state": "PASS", "exit": 0,
                                      "summary": "All checks passed.", "finished_at": T("11:00")}
            write(f"docs/progress/status/{agent}.json", status)
            commit(f"{agent} status")
        git(work, "push", "-q", "-f", "origin", agents[agent]["branch"])
        readies[agent] = sha
        return sha

    branch("B", {"src/b/x.txt": "b\n"})
    branch("C", {"src/c/x.txt": "c\n", "README.md": "not C's\n"})      # outside its files
    branch("D", {"src/shared.txt": "d\n"})
    git(work, "checkout", "-q", "main")
    # Main moves on: src/shared.txt changes, so D conflicts.
    write("src/shared.txt", "main\n")
    commit("main: shared")
    # A branches after it (as if it merged main before ready): its candidate
    # differs from its ready_sha only in docs/progress, so its pre-check counts.
    branch("A", {"src/a/x.txt": "a\n"}, {"precheck": "PASS"})
    git(work, "checkout", "-q", "main")
    b = json.loads((work / cy.BACKLOG).read_text())
    for t in b["tasks"]:
        t["ready_sha"] = readies.get(t["assigned_to"])
    write(cy.BACKLOG, b)
    commit("lead cycle: ready shas")
    git(work, "push", "-q", "origin", "main")

    coord = tmp / "coord"
    git(tmp, "clone", "-q", str(origin), str(coord))
    git(coord, "config", "user.name", "coord")
    git(coord, "config", "user.email", "coord@example.invalid")
    return coord, work, git, env


def self_test() -> list:
    """The fixture tests; returns the names of the failed checks."""
    fails = []

    def check(name, cond):
        if not cond:
            fails.append(f"merge_queue: {name}")

    now = dt.datetime(2026, 11, 17, 13, 30, tzinfo=dt.timezone.utc)
    clock = lambda: now
    with tempfile.TemporaryDirectory() as d:
        tmp = pathlib.Path(d)
        coord, work, git, env = _fixture(tmp)
        repo = Git(coord, main="main", env=env)
        checks = Checks(repo, env=env, full_cmd=STUB_FULL, docs_cmd=STUB_DOCS, poll=0.2,
                        timeout_min=2)

        def origin_main():
            return git(coord, "ls-remote", str(tmp / "origin.git"), "refs/heads/main").split()[0]

        def at_main(path):
            repo.fetch()
            return repo.json_at("origin/main", path)

        # Dry run: the candidate and the plan, nothing pushed or written.
        before, status_before = origin_main(), git(coord, "status", "--porcelain")
        rep = run_queue(repo, checks, dry_run=True, now_fn=clock)
        out = rep.render()
        check("dry-run pushes nothing", origin_main() == before)
        check("dry-run writes nothing", git(coord, "status", "--porcelain") == status_before
              and "coord-merge-" not in git(coord, "worktree", "list"))
        check("dry-run says so", "dry run: nothing written, nothing pushed" in out)
        check("dry-run batch", any(a["kind"] == "candidate" and a["target"] == "ta+tb"
                                   for a in rep.actions))
        check("dry-run owners", any(a["kind"] == "resync" and a["target"] == "tc" for a in rep.actions))
        check("dry-run conflict", any(a["kind"] == "resync" and a["target"] == "td"
                                      and "src/shared.txt" in a["text"] for a in rep.actions))
        check("dry-run inbox", any(a["kind"] == "inbox" and a["target"] == "ta" for a in rep.actions))

        # A held lock: the queue does nothing.
        held = {"candidate_sha": "f" * 40, "task_ids": ["zz"], "started_at": "2026-11-17T13:00:00Z",
                "expires_at": "2026-11-17T14:00:00Z"}
        lead = json.loads((work / cy.LEAD).read_text())
        lead["merging"] = held
        (work / cy.LEAD).write_text(json.dumps(lead, indent=2) + "\n")
        git(work, "commit", "-qam", "lock held")
        git(work, "push", "-q", "origin", "main")
        before = origin_main()
        rep = run_queue(repo, checks, dry_run=False, now_fn=clock)
        check("held lock skips", origin_main() == before
              and [a["kind"] for a in rep.actions] == ["skip"])

        # A real run, the same lock now expired; a docs-only commit lands on
        # main while the batch's checks run, and tb's branch has a FAIL marker
        # so the batch fails, ta passes alone (its pre-check reused, the full
        # checks after), tb goes to resync with the failure lines.
        later = dt.datetime(2026, 11, 17, 14, 30, tzinfo=dt.timezone.utc)
        git(work, "checkout", "-q", "b/b")
        (work / "FAIL_b").write_text("x\n")
        git(work, "add", "-A")
        git(work, "commit", "-qm", "B: a failing change")
        git(work, "push", "-q", "-f", "origin", "b/b")
        tb_sha = git(work, "rev-parse", "HEAD").strip()
        git(work, "checkout", "-q", "main")
        b = json.loads((work / cy.BACKLOG).read_text())
        for t in b["tasks"]:
            if t["id"] == "tb":
                t["ready_sha"] = tb_sha
        (work / cy.BACKLOG).write_text(json.dumps(b, indent=2) + "\n")
        git(work, "commit", "-qam", "tb ready again")
        git(work, "push", "-q", "origin", "main")
        # FAIL_b is at the root, outside tb's files: give tb that exception.
        b["tasks"][1]["exceptions"] = ["FAIL_b"]
        (work / cy.BACKLOG).write_text(json.dumps(b, indent=2) + "\n")
        git(work, "commit", "-qam", "tb exception")
        git(work, "push", "-q", "origin", "main")

        bumped = {"n": 0}
        real_run = checks.run

        def run_and_bump(kind, sha):
            # While the first candidate's checks run, the lead pushes a docs-only commit.
            if bumped["n"] == 0 and kind == "full":
                bumped["n"] = 1
                git(work, "pull", "-q", "--ff-only", "origin", "main")
                (work / "docs/progress/notes.md").write_text("a note\n")
                git(work, "add", "-A")
                git(work, "commit", "-qm", "lead: a note")
                git(work, "push", "-q", "origin", "main")
            return real_run(kind, sha)
        checks.run = run_and_bump
        rep = run_queue(repo, checks, dry_run=False, now_fn=lambda: later,
                        trailers=("Coordinator: test",))
        out = rep.render()
        b = at_main(cy.BACKLOG)
        lead = at_main(cy.LEAD)
        tasks = {t["id"]: t for t in b["tasks"]}
        kinds = [a["kind"] for a in rep.actions]
        check("expired lock cleared", "lock" in kinds and "expired merge lock cleared" in out)
        check("batch split", "split" in kinds)
        check("ta merged", tasks["ta"]["state"] == "merged" and bool(tasks["ta"]["merged_sha"])
              and rep.merged == ["ta"])
        check("ta reused precheck", "checks reused from the pre-check" in out
              and "main passed the full checks after the merge" in out)
        check("tb resync with lines", tasks["tb"]["state"] == "resync"
              and "FAILED: test_x" in (tasks["tb"].get("resync_reason") or "")
              and tasks["tb"]["attempts"] == 1)
        check("tc resync owners", tasks["tc"]["state"] == "resync"
              and "README.md" in tasks["tc"]["resync_reason"])
        check("td resync conflict", tasks["td"]["state"] == "resync"
              and "src/shared.txt" in tasks["td"]["resync_reason"])
        msgs = {m["to"]: m for m in b["messages"] if m["id"] != "M7"}
        check("messages", set(msgs) == {"B", "C", "D"} and all(
            m["id"][1:].isdigit() and int(m["id"][1:]) > 7 and m["acked_at"] is None
            for m in msgs.values()) and "src/shared.txt" in msgs["D"]["text"])
        check("lock cleared", lead["merging"] is None
              and (lead["last_merged"] or {}).get("task_id") == "ta")
        check("te untouched", tasks["te"]["state"] == "working")
        git(coord, "fetch", "-q", "origin")
        log = git(coord, "log", "--format=%s%n%b", "origin/main")
        check("merged onto newer docs head", "a note" in git(coord, "log", "--format=%s", "origin/main")
              and "candidate" in log and "onto main (checks passed at" in log)
        check("ta's code on main", git(coord, "show", "origin/main:src/a/x.txt") == "a\n")
        check("tb's code not on main", "FAIL_b" not in git(coord, "ls-tree", "--name-only",
                                                             "origin/main"))
        check("trailers", "Coordinator: test" in log)
        inbox = git(coord, "show", f"origin/main:{INBOX}")
        check("inbox entry", "ta ready since" in inbox and inbox.index("ta ready since")
              < inbox.index("old") and "- **Needs the owner:**" in inbox)
        check("only docs and merges", all(
            repo.only_docs(f"{c}^1", c) or len(git(coord, "rev-list", "--parents", "-n1", c).split()) > 2
            for c in git(coord, "rev-list", "--first-parent", f"{before}..origin/main").split()))
        check("worktrees removed", "coord-merge-" not in git(coord, "worktree", "list"))

        # A second run: nothing ready, nothing pushed.
        before = origin_main()
        rep = run_queue(repo, checks, dry_run=False, now_fn=lambda: later)
        check("idle", origin_main() == before and [a["kind"] for a in rep.actions] == ["idle"])

        # The checks cannot run: the lock is cleared, the inbox says so, the
        # task stays ready.
        git(work, "pull", "-q", "--ff-only", "origin", "main")
        git(work, "checkout", "-q", "-B", "b/e", "main")
        (work / "src/e").mkdir(parents=True)
        (work / "src/e/x.txt").write_text("e\n")
        git(work, "add", "-A")
        git(work, "commit", "-qm", "E work")
        git(work, "push", "-q", "-f", "origin", "b/e")
        te_sha = git(work, "rev-parse", "HEAD").strip()
        git(work, "checkout", "-q", "main")
        b = json.loads((work / cy.BACKLOG).read_text())
        for t in b["tasks"]:
            if t["id"] == "te":
                t.update(state="ready", ready_sha=te_sha, ready_at="2026-11-17T14:20:00Z")
        (work / cy.BACKLOG).write_text(json.dumps(b, indent=2) + "\n")
        git(work, "commit", "-qam", "te ready")
        git(work, "push", "-q", "origin", "main")
        nobox = dict(env)
        nobox.pop("CHECK_UNSANDBOXED")
        nobox["CHECK_BWRAP"] = "/nonexistent/bwrap"
        rep = run_queue(repo, Checks(repo, env=nobox, full_cmd=STUB_FULL, poll=0.2, timeout_min=1),
                        dry_run=False, now_fn=lambda: later)
        b, lead = at_main(cy.BACKLOG), at_main(cy.LEAD)
        te = next(t for t in b["tasks"] if t["id"] == "te")
        check("cannot run: stays ready", te["state"] == "ready" and lead["merging"] is None
              and "error" in [a["kind"] for a in rep.actions])
        check("cannot run: inbox", "the merge queue cannot run the checks"
              in git(coord, "show", f"origin/main:{INBOX}"))

        # The reused pre-check, then main fails the full checks: reverted.
        b = at_main(cy.BACKLOG)
        git(work, "pull", "-q", "--ff-only", "origin", "main")
        git(work, "checkout", "-q", "-B", "b/e", "main")
        (work / "FAIL_e").write_text("x\n")
        git(work, "add", "-A")
        git(work, "commit", "-qm", "E: breaks main")
        te_sha = git(work, "rev-parse", "HEAD").strip()
        (work / "docs/progress/status/E.json").write_text(json.dumps(
            {"agent": "E", "precheck": {"sha": te_sha, "state": "PASS", "exit": 0,
                                        "summary": "All checks passed."}}) + "\n")
        git(work, "add", "-A")
        git(work, "commit", "-qm", "E status (a pre-check that lies)")
        git(work, "push", "-q", "-f", "origin", "b/e")
        git(work, "checkout", "-q", "main")
        b = json.loads((work / cy.BACKLOG).read_text())
        for t in b["tasks"]:
            if t["id"] == "te":
                t.update(ready_sha=te_sha, exceptions=["FAIL_e"])
        (work / cy.BACKLOG).write_text(json.dumps(b, indent=2) + "\n")
        git(work, "commit", "-qam", "te ready again")
        git(work, "push", "-q", "origin", "main")
        checks.run = real_run
        rep = run_queue(repo, checks, dry_run=False, now_fn=lambda: later)
        b = at_main(cy.BACKLOG)
        te = next(t for t in b["tasks"] if t["id"] == "te")
        check("revert after reuse", te["state"] == "resync" and te["merged_sha"] is None
              and "reverted" in te["resync_reason"] and "revert" in [a["kind"] for a in rep.actions]
              and "FAIL_e" not in git(coord, "ls-tree", "--name-only", "origin/main"))

        # Under load, run_checks.sh's start can return before its detached
        # runner has written the pid file. A result read then says LOST and
        # removes the run's worktree, so the queue must not read one before
        # the pid file is there.
        def fake(name, **kw):
            d = tmp / name
            d.mkdir()
            return _FakeRunner(repo, {**env, "CHECK_DIR": str(d)}, **kw)
        late = fake("late", pid_delay=1.0, states=["RUNNING", "PASS"])
        res = late.run("full", "a" * 40)
        late.timer.join()
        check("late pid file: no early result", "LOST" not in late.seen)
        check("late pid file: the run passes", res["state"] == "PASS")
        # result looks for the DONE file, then for the runner: a run that ends
        # between the two reads as LOST once, then as ended.
        ended = fake("ended", states=["RUNNING", "LOST", "PASS"])
        res = ended.run("full", "b" * 40)
        check("run ended between reads: passes", res["state"] == "PASS")
        lost = fake("lost", states=["RUNNING", "LOST", "LOST"])
        res = lost.run("full", "c" * 40)
        check("run lost: says so", res["state"] == "LOST")
    return fails


class _FakeRunner(Checks):
    """run_checks.sh as seen under load, for the self-test: start returns at
    once, the runner writes its pid file pid_delay seconds later, and from
    then on result gives states in turn (the last one again once they run
    out). Before the pid file is there, result says LOST, as run_checks.sh's
    does."""

    def __init__(self, repo, env, states, pid_delay=0.0):
        super().__init__(repo, env=env, full_cmd="true", poll=0.05, timeout_min=1)
        self.states, self.pid_delay = list(states), pid_delay
        self.seen, self.timer = [], None

    def _sh(self, kind, *args):
        sha = args[1]
        d = pathlib.Path(self._env(kind)["CHECK_DIR"])
        pidf, logf = d / f"check-{sha}.pid", d / f"check-{sha}.log"
        if args[0] == "start":
            logf.write_text("")
            write = lambda: pidf.write_text("4242\n")
            if self.pid_delay:
                import threading
                self.timer = threading.Timer(self.pid_delay, write)
                self.timer.start()
            else:
                write()
            return subprocess.CompletedProcess(args, 0, f"started: sha={sha}\n", "")
        if not logf.exists():
            state = "NONE"
        elif not (pidf.exists() and pidf.read_text().strip()):
            state = "LOST"
        else:
            state = self.states.pop(0) if len(self.states) > 1 else self.states[0]
        self.seen.append(state)
        return subprocess.CompletedProcess(args, 0, json.dumps(
            {"sha": sha, "state": state, "summary": "", "log": str(logf)}) + "\n", "")


if __name__ == "__main__":
    f = self_test()
    print("self-test FAILED: " + ", ".join(f) if f else "self-test passed")
    sys.exit(1 if f else 0)
