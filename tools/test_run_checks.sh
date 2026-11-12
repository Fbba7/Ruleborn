#!/usr/bin/env bash
# tools/run_checks.sh against a candidate that changes the lead's repository
# (security finding SEC-19, part A). Run by hand:
#
#   bash tools/test_run_checks.sh
#
# Each case is a throwaway repository with a copy of run_checks.sh, run with
# CHECK_CMD unset, so the candidate's own tools/check_all.sh runs, as it does
# for a real candidate:
#
# - a candidate that plants a hook in the shared .git and prints the closing
#   line is FAIL "repository changed by the run", not PASS;
# - so is one that changes .git/config outside its branch entries;
# - a hook already in .git/hooks does not run when the runner adds or
#   removes the worktree;
# - an honest candidate still passes, and so does one during which the lead
#   sets a branch's upstream (a `branch.*` entry in .git/config).
set -euo pipefail
here="$(cd "$(dirname "$0")" && pwd)"
tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT
export CHECK_DIR="$tmp/runs"; mkdir -p "$CHECK_DIR"
unset CHECK_CMD
failures=0

# A repository whose tools/check_all.sh is `$1`; prints its HEAD.
repo() {
  local r="$tmp/repo-$2"
  git init --quiet "$r"
  mkdir -p "$r/tools"
  cp "$here/run_checks.sh" "$r/tools/run_checks.sh"
  printf '%s\n' "$1" > "$r/tools/check_all.sh"
  git -C "$r" -c core.hooksPath=/dev/null add tools
  git -C "$r" -c core.hooksPath=/dev/null -c user.email=t@t -c user.name=t -c commit.gpgsign=false \
    commit --quiet -m candidate
  git -C "$r" rev-parse HEAD
}

# The verdict of one run of `$1`'s HEAD.
verdict() {
  local r="$tmp/repo-$1" sha; sha="$(git -C "$r" rev-parse HEAD)"
  bash "$r/tools/run_checks.sh" start "$sha" > /dev/null
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

if [ "$failures" -ne 0 ]; then echo "test_run_checks.sh: $failures failed"; exit 1; fi
echo "test_run_checks.sh: ok"
