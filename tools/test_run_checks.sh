#!/usr/bin/env bash
# tools/run_checks.sh against a candidate that reaches for the lead's
# repository, machine or network (security finding SEC-19). Run by hand, and
# by tools/check_all.sh:
#
#   bash tools/test_run_checks.sh
#
# Each case is a throwaway repository with a copy of run_checks.sh, run with
# CHECK_CMD unset, so the candidate's own tools/check_all.sh runs, as it does
# for a real candidate.
#
# Part A, the check of the shared .git (cases 1 to 4, run unsandboxed so
# they hold on any machine):
#
# - a candidate that plants a hook in the shared .git and prints the closing
#   line is FAIL "repository changed by the run", not PASS;
# - so is one that changes .git/config outside its branch entries;
# - a hook already in .git/hooks does not run when the runner adds or
#   removes the worktree;
# - an honest candidate still passes, and so does one during which the lead
#   sets a branch's upstream (a `branch.*` entry in .git/config).
#
# Part B, the containment (cases 5 to 9):
#
# - with no bwrap, no CHECK_USER and no opt-out, `start` refuses, says why
#   and creates no worktree; so it does when bwrap is there but cannot run,
#   or CHECK_USER names nobody here;
# - CHECK_UNSANDBOXED=1 runs it, with a warning, and the result says so;
# - bwrap is called with the containment's flags (a stand-in bwrap that
#   records them), and the secret-looking variables are taken away;
# - under a real bwrap the candidate cannot write the shared .git or the
#   repository, cannot reach a listener on 127.0.0.1, sees no host /run and
#   holds no capability, so cannot remount anything writable. Set
#   CHECK_TEST_BWRAP to a bwrap binary if none is on PATH; with none, the
#   case prints NOT TESTED, and CHECK_TEST_REQUIRE_BWRAP=1 (CI sets it)
#   turns that into a failure;
# - as root, a run as CHECK_USER=nobody runs as that user, cannot write the
#   shared .git and cannot reach the listener either (NOT TESTED when not
#   root).
set -euo pipefail
here="$(cd "$(dirname "$0")" && pwd)"
tmp="$(mktemp -d)"
listener=""
trap '[ -z "$listener" ] || kill "$listener" 2>/dev/null || true; rm -rf "$tmp"' EXIT
export CHECK_DIR="$tmp/runs"; mkdir -p "$CHECK_DIR"
unset CHECK_CMD CHECK_USER
# Part A's cases run the same on every machine: no bwrap, explicitly unsandboxed.
export CHECK_BWRAP=/nonexistent/bwrap CHECK_UNSANDBOXED=1
failures=0
untested=()

# A repository whose tools/check_all.sh is `$1`; prints its HEAD. The commit
# message carries the case's name `$2`, so two cases with the same check_all.sh
# committed in the same second still get different shas, and one case's run
# directory in $CHECK_DIR is never another's.
repo() {
  local r="$tmp/repo-$2"
  git init --quiet "$r"
  mkdir -p "$r/tools"
  cp "$here/run_checks.sh" "$r/tools/run_checks.sh"
  printf '%s\n' "$1" > "$r/tools/check_all.sh"
  git -C "$r" -c core.hooksPath=/dev/null add tools
  git -C "$r" -c core.hooksPath=/dev/null -c user.email=t@t -c user.name=t -c commit.gpgsign=false \
    commit --quiet -m "candidate $2"
  git -C "$r" rev-parse HEAD
}

# The verdict of one run of `$1`'s HEAD.
verdict() {
  local r="$tmp/repo-$1" sha; sha="$(git -C "$r" rev-parse HEAD)"
  bash "$r/tools/run_checks.sh" start "$sha" > /dev/null 2>&1
  bash "$r/tools/run_checks.sh" wait "$sha" 1 || true
}

expect() {
  if [[ "$2" == *"$3"* ]]; then echo "ok: $1"; else echo "FAIL: $1: $2"; failures=$((failures + 1)); fi
}

# 1. A planted hook and its own closing line.
repo 'echo "#!/bin/sh" > "$(git rev-parse --git-common-dir)/hooks/post-merge"
chmod +x "$(git rev-parse --git-common-dir)/hooks/post-merge"
echo "All checks passed."' hook > /dev/null
out="$(verdict hook)"
expect "a hook planted by the run fails it" "$out" '"state": "FAIL"'
expect "and says why" "$out" "repository changed by the run"

# 2. A setting written to the shared config.
repo 'git config core.fsmonitor "touch /dev/null"
echo "All checks passed."' config > /dev/null
out="$(verdict config)"
expect "a config change by the run fails it" "$out" "repository changed by the run"

# 3. A hook already there does not run on the runner's git commands.
repo 'echo "All checks passed."' planted > /dev/null
printf '#!/bin/sh\ntouch "%s"\n' "$tmp/hook-ran" > "$tmp/repo-planted/.git/hooks/post-checkout"
chmod +x "$tmp/repo-planted/.git/hooks/post-checkout"
out="$(verdict planted)"
expect "the runner's worktree add ran no hook" "$([ -e "$tmp/hook-ran" ] && echo ran || echo none)" none
expect "and the candidate passes" "$out" '"state": "PASS"'

# 4. Honest candidates.
repo 'echo "== one =="; echo "All checks passed."' honest > /dev/null
expect "an honest candidate passes" "$(verdict honest)" '"state": "PASS"'
repo 'git -C "'"$tmp"'/repo-upstream" config branch.main.remote origin
echo "All checks passed."' upstream > /dev/null
expect "a branch's upstream set during the run is not a change" "$(verdict upstream)" '"state": "PASS"'

# 5. Nothing to contain the candidate: refused, with the reason, and nothing made.
repo 'echo "All checks passed."' refused > /dev/null
r="$tmp/repo-refused"; sha="$(git -C "$r" rev-parse HEAD)"
code=0; err="$(env -u CHECK_UNSANDBOXED bash "$r/tools/run_checks.sh" start "$sha" 2>&1 > /dev/null)" || code=$?
expect "with no sandbox and no opt-out, start refuses" "exit $code" "exit 3"
expect "and says why" "$err" "refused: nothing here contains the candidate's code"
expect "naming the missing bwrap" "$err" "bwrap (/nonexistent/bwrap) is not installed"
expect "and the missing CHECK_USER" "$err" "CHECK_USER is not set"
expect "and makes no worktree and no log" \
  "$([ -e "$CHECK_DIR/check-$sha" ] || [ -e "$CHECK_DIR/check-$sha.log" ] && echo made || echo none)" none
code=0; err="$(env -u CHECK_UNSANDBOXED CHECK_USER=no-such-user-here bash "$r/tools/run_checks.sh" start "$sha" 2>&1 > /dev/null)" || code=$?
expect "a CHECK_USER that is no user is refused too" "exit $code: $err" "exit 3: refused"
expect "and says so" "$err" "CHECK_USER=no-such-user-here is no user on this machine"
printf '#!/bin/sh\necho "bwrap: No permissions to create new namespace" >&2\nexit 1\n' > "$tmp/broken-bwrap"
chmod +x "$tmp/broken-bwrap"
code=0; err="$(env -u CHECK_UNSANDBOXED CHECK_BWRAP="$tmp/broken-bwrap" bash "$r/tools/run_checks.sh" start "$sha" 2>&1 > /dev/null)" || code=$?
expect "a bwrap that cannot run is refused" "exit $code" "exit 3"
expect "with bwrap's own reason" "$err" "does not run here: bwrap: No permissions to create new namespace"

# 6. The explicit opt-out runs it, and warns.
err="$(bash "$r/tools/run_checks.sh" start "$sha" 2>&1 > /dev/null)"
expect "CHECK_UNSANDBOXED=1 warns" "$err" "warning: CHECK_UNSANDBOXED=1: the candidate's code runs with your rights"
out="$(bash "$r/tools/run_checks.sh" wait "$sha" 1 || true)"
expect "and runs the candidate" "$out" '"state": "PASS"'
expect "and the result says it was not contained" "$out" '"sandbox": "unsandboxed"'

# 7. The flags bwrap is given, through a stand-in that records them and runs
# what follows `--`.
printf '#!/usr/bin/env bash\nprintf "%%s\\n" "$@" >> "%s"\nwhile [ "$1" != -- ]; do shift; done; shift; exec "$@"\n' \
  "$tmp/bwrap-args" > "$tmp/fake-bwrap"
chmod +x "$tmp/fake-bwrap"
repo 'echo "All checks passed."' flags > /dev/null
r="$tmp/repo-flags"; sha="$(git -C "$r" rev-parse HEAD)"
env -u CHECK_UNSANDBOXED CHECK_BWRAP="$tmp/fake-bwrap" RUN_CHECKS_TEST_TOKEN=not-for-the-candidate \
  bash "$r/tools/run_checks.sh" start "$sha" > /dev/null
out="$(bash "$r/tools/run_checks.sh" wait "$sha" 1 || true)"
expect "a run in bwrap passes" "$out" '"state": "PASS"'
expect "and the result says bwrap" "$out" '"sandbox": "bwrap"'
args="$(tr '\n' ' ' < "$tmp/bwrap-args" 2>/dev/null || echo "bwrap never called")"
expect "bwrap mounts everything read-only" "$args" "--ro-bind / / "
expect "but the worktree" "$args" "--bind $CHECK_DIR/check-$sha $CHECK_DIR/check-$sha "
expect "and a private /tmp" "$args" "--bind $CHECK_DIR/check-$sha.tmp /tmp "
expect "with the shared .git read-only over it" "$args" "--ro-bind $r/.git $r/.git "
expect "and /run emptied" "$args" "--tmpfs /run "
expect "cuts the network" "$args" "--unshare-net "
expect "and the process tree" "$args" "--unshare-pid "
expect "drops every capability" "$args" "--cap-drop ALL "
expect "and takes the secret-looking variables away" "$args" "--unsetenv RUN_CHECKS_TEST_TOKEN "

# A listener on 127.0.0.1, for the candidate to try to reach.
python3 -c '
import socket, sys
s = socket.socket(); s.bind(("127.0.0.1", 0)); s.listen(5)
open(sys.argv[1], "w").write(str(s.getsockname()[1]))
while True:
    c, _ = s.accept(); open(sys.argv[2], "a").write("reached\n"); c.close()
' "$tmp/port" "$tmp/reached" &
listener=$!
for _ in $(seq 50); do [ -s "$tmp/port" ] && break; sleep 0.1; done
port="$(cat "$tmp/port")"

# What a candidate reports of its reach: the shared .git, the repository, the
# listener, /run, its capabilities and the secret variable.
probe='touch "'"$tmp"'/repo-REPO/.git/hooks/post-merge" 2>/dev/null && echo "probe: hook written" || echo "probe: hook refused"
touch "'"$tmp"'/repo-REPO/planted" 2>/dev/null && echo "probe: repo written" || echo "probe: repo refused"
(exec 3<>/dev/tcp/127.0.0.1/'"$port"') 2>/dev/null && echo "probe: listener reached" || echo "probe: listener refused"
echo "probe: uid $(id -u)"
echo "probe: run holds $(ls -A /run 2>/dev/null | wc -l)"
echo "probe: capabilities $(awk "/^CapEff/ {print \$2}" /proc/self/status)"
echo "probe: token ${RUN_CHECKS_TEST_TOKEN:-unset}"
echo "All checks passed."'

# 8. A real bwrap.
# Only one that can run here: inside a contained run of check_all.sh, a
# nested bwrap usually cannot.
real_bwrap="${CHECK_TEST_BWRAP:-$(command -v bwrap || true)}"
if [ -n "$real_bwrap" ] && ! "$real_bwrap" --ro-bind / / --dev /dev --proc /proc --unshare-net --unshare-pid \
    --cap-drop ALL -- true > /dev/null 2>&1; then
  echo "(bwrap $real_bwrap cannot run here)"; real_bwrap=""
fi
if [ -n "$real_bwrap" ]; then
  repo "${probe//REPO/bwrap}" bwrap > /dev/null
  r="$tmp/repo-bwrap"; sha="$(git -C "$r" rev-parse HEAD)"
  env -u CHECK_UNSANDBOXED CHECK_BWRAP="$real_bwrap" RUN_CHECKS_TEST_TOKEN=not-for-the-candidate \
    bash "$r/tools/run_checks.sh" start "$sha" > /dev/null
  out="$(bash "$r/tools/run_checks.sh" wait "$sha" 1 || true)"
  log="$(cat "$CHECK_DIR/check-$sha.log")"
  expect "in bwrap, the run passes" "$out" '"sandbox": "bwrap"'
  expect "in bwrap, the shared .git is read-only" "$log" "probe: hook refused"
  expect "and no hook is there afterwards" "$([ -e "$r/.git/hooks/post-merge" ] && echo there || echo none)" none
  # Under /tmp, as here, the repository's path is in the private /tmp: what counts is the real one.
  expect "in bwrap, the repository is not written" "$([ -e "$r/planted" ] && echo written || echo none)" none
  expect "in bwrap, 127.0.0.1 of the host is out of reach" "$log" "probe: listener refused"
  expect "in bwrap, the host's /run is not there" "$log" "probe: run holds 0"
  # Without them, nothing can be remounted writable: as root, bwrap would otherwise keep them.
  expect "in bwrap, the run holds no capability" "$log" "probe: capabilities 0000000000000000"
  expect "in bwrap, the secret variable is gone" "$log" "probe: token unset"
elif [ "${CHECK_TEST_REQUIRE_BWRAP:-}" = 1 ]; then
  expect "a real bwrap is on this machine (CHECK_TEST_REQUIRE_BWRAP=1)" "none that runs here" "a bwrap that runs"
else
  echo "NOT TESTED: a real bwrap (none that runs here; set CHECK_TEST_BWRAP to one)"
  untested+=("bwrap")
fi

# 9. A separate user, as root.
if [ "$(id -u)" = 0 ] && id -u nobody > /dev/null 2>&1 && unshare --net -- runuser -u nobody -- true 2>/dev/null; then
  repo "${probe//REPO/user}" user > /dev/null
  r="$tmp/repo-user"; sha="$(git -C "$r" rev-parse HEAD)"
  chmod a+rx "$tmp" "$CHECK_DIR"
  env -u CHECK_UNSANDBOXED CHECK_USER=nobody RUN_CHECKS_TEST_TOKEN=not-for-the-candidate \
    bash "$r/tools/run_checks.sh" start "$sha" > /dev/null
  out="$(bash "$r/tools/run_checks.sh" wait "$sha" 1 || true)"
  log="$(cat "$CHECK_DIR/check-$sha.log")"
  expect "as CHECK_USER, the run passes" "$out" '"sandbox": "user"'
  expect "as CHECK_USER, it runs as that user" "$log" "probe: uid $(id -u nobody)"
  expect "as CHECK_USER, the shared .git is not writable" "$log" "probe: hook refused"
  expect "as CHECK_USER, the repository is not writable" "$log" "probe: repo refused"
  expect "and is not written" "$([ -e "$r/planted" ] && echo written || echo none)" none
  expect "as CHECK_USER from root, 127.0.0.1 of the host is out of reach" "$log" "probe: listener refused"
  expect "as CHECK_USER, the secret variable is gone" "$log" "probe: token unset"
  expect "and the worktree is gone afterwards" "$([ -e "$CHECK_DIR/check-$sha" ] && echo there || echo none)" none
else
  echo "NOT TESTED: a run as a separate user (needs root, with its capabilities, and a user named nobody)"
  untested+=("user")
fi
expect "no candidate reached the listener" "$(cat "$tmp/reached" 2>/dev/null || echo none)" none

if [ "$failures" -ne 0 ]; then echo "test_run_checks.sh: $failures failed"; exit 1; fi
if [ "${#untested[@]}" -ne 0 ]; then echo "test_run_checks.sh: ok, NOT TESTED: ${untested[*]}"; exit 0; fi
echo "test_run_checks.sh: ok"
