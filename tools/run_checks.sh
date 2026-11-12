#!/usr/bin/env bash
# The full checks on a separate worktree of one exact commit, with the log
# outside the repository (backlog task BT-03; docs/guides/agent-protocol.md,
# "Running the checks").
#
#   bash tools/run_checks.sh start [<sha>]          # default HEAD; prints sha and log
#   bash tools/run_checks.sh result <sha>           # one line of JSON: PASS, FAIL, RUNNING or LOST
#   bash tools/run_checks.sh wait <sha> [<minutes>] # blocks until it ends (run it in the background)
#   bash tools/run_checks.sh record <sha> <agent>   # writes precheck into docs/progress/status/<agent>.json
#   bash tools/run_checks.sh --self-test
#
# The run is detached (nohup setsid), so it outlives the tool call that
# started it; a container restart still kills it, and `result` then says
# LOST. A run passed only if its log ends `DONE exit=0` and contains
# "All checks passed." The worktree is seeded with the checkout's build
# caches (the Rust targets and Godot's import cache) so a run does not start
# from a cold build, and is removed once the run has ended.
#
# CHECK_DIR (default /tmp) is where the worktree and log go; CHECK_CMD
# (default `bash tools/check_all.sh`) is what runs, for this script's tests.
#
# The worktree shares the checkout's .git, so a run could plant a hook or a
# setting there (SEC-19): the runner's own git commands run no hooks, and a
# run during which .git/config (its branch entries aside) or .git/hooks
# changed is FAIL "repository changed by the run", whatever its log says
# (part A).
#
# The candidate's code is run contained (SEC-19, part B), in the first of:
#
# - bwrap (CHECK_BWRAP, default `bwrap`): the whole file system read-only,
#   the worktree and a private /tmp writable, /run empty, no network, its own
#   process tree, no capabilities (as root, bwrap otherwise keeps them, and
#   the read-only mounts can be remounted writable);
# - a separate unprivileged user (CHECK_USER), which owns the worktree and
#   nothing else of the lead's; run as root, the network is cut too
#   (`unshare --net`); through sudo it is not;
# - nothing, only if CHECK_UNSANDBOXED=1 is set, with a warning: for a
#   machine where the candidate may do anything the lead can.
#
# With none of them, `start` refuses (exit 3), says why and creates nothing.
# Contained, the run is not given the environment's variables that look like
# secrets (token, secret, password, credential, API key, auth).
# `result` names the containment in "sandbox". tools/test_run_checks.sh
# tests all of this.
set -euo pipefail
git() { command git -c core.hooksPath=/dev/null "$@"; }
root="$(git -C "$(dirname "$0")/.." rev-parse --show-toplevel)"
dir="${CHECK_DIR:-/tmp}"
cmd="${CHECK_CMD:-bash tools/check_all.sh}"
bwrap_bin="${CHECK_BWRAP:-bwrap}"
check_user="${CHECK_USER:-}"

paths() {
  wt="$dir/check-$1"; log="$dir/check-$1.log"; pidf="$dir/check-$1.pid"; gitf="$dir/check-$1.git"
  tmpd="$dir/check-$1.tmp"; modef="$dir/check-$1.sandbox"
}

# The flags every bwrap run takes, the probe included.
bwrap_flags=(--dev /dev --proc /proc --unshare-net --unshare-pid --unshare-ipc --unshare-uts
  --cap-drop ALL --die-with-parent --new-session)

# The environment's secrets, which the candidate's code is not given.
secret_vars() { compgen -e | grep -iE 'token|secret|passw|credential|api_?key|private_?key|auth' || true; }

# How to become CHECK_USER: as root, in a namespace with no network.
as_user() {
  if [ "$(id -u)" = 0 ]; then echo unshare --net -- runuser -u "$check_user" --
  else echo sudo -n -u "$check_user" --; fi
}

# Sets `mode` to bwrap, user, user-with-network or unsandboxed, or to "" with
# `why` saying what was missing.
pick_sandbox() {
  local out uid
  mode=""; why=""
  if ! command -v "$bwrap_bin" > /dev/null; then
    why="bwrap ($bwrap_bin) is not installed"
  elif out="$("$bwrap_bin" --ro-bind / / "${bwrap_flags[@]}" -- true 2>&1)"; then
    mode=bwrap; return
  else
    why="bwrap ($bwrap_bin) does not run here: ${out%%$'\n'*}"
  fi
  if [ -z "$check_user" ]; then
    why="$why; CHECK_USER is not set"
  elif ! uid="$(id -u "$check_user" 2>/dev/null)"; then
    why="$why; CHECK_USER=$check_user is no user on this machine"
  elif [ "$uid" = 0 ] || [ "$uid" = "$(id -u)" ]; then
    why="$why; CHECK_USER=$check_user is not a separate unprivileged user"
  elif out="$($(as_user) true 2>&1)"; then
    if [ "$(id -u)" = 0 ]; then mode=user; else mode=user-with-network; fi
    return
  else
    why="$why; cannot switch to CHECK_USER=$check_user: ${out%%$'\n'*}"
  fi
  if [ "${CHECK_UNSANDBOXED:-}" = 1 ]; then mode=unsandboxed; fi
}

# A hash of the shared .git's config, its branch entries aside (the lead sets
# upstreams while a run goes on), and of every hook's name, mode and content.
fingerprint() {
  local g; g="$(cd "$root" && cd "$(git rev-parse --git-common-dir)" && pwd)"
  {
    git config --file "$g/config" --no-includes --list 2>&1 | grep -v '^branch\.' || true
    if [ -d "$g/hooks" ]; then
      (cd "$g" && find hooks -print | LC_ALL=C sort | while IFS= read -r f; do
        if [ -L "$f" ]; then echo "link $f $(readlink "$f")"
        elif [ -f "$f" ]; then echo "file $f $(stat -c %a "$f") $(sha256sum < "$f")"
        else echo "other $f"; fi
      done)
    fi
  } | sha256sum | cut -d' ' -f1
}

# Alive and not a zombie: an orphan nobody reaps still answers kill -0.
alive() {
  local pid; [ -f "$pidf" ] && pid="$(cat "$pidf")" && kill -0 "$pid" 2>/dev/null || return 1
  [ "$(awk '{print $3}' "/proc/$pid/stat" 2>/dev/null)" != Z ]
}

resolve() { git -C "$root" rev-parse --verify --quiet "$1^{commit}" || { echo "no commit $1" >&2; exit 2; }; }

# The build outputs check_all.sh would otherwise rebuild from nothing.
seed() {
  local p
  for p in client/ext/target sim/target client/.godot client/bin client/goldens; do
    if [ -d "$root/$p" ] && [ ! -e "$1/$p" ]; then
      mkdir -p "$(dirname "$1/$p")"
      cp -a --reflink=auto "$root/$p" "$1/$p"
    fi
  done
}

cleanup() {
  if [ -d "$wt" ]; then
    git -C "$root" worktree remove --force "$wt" 2>/dev/null || rm -rf "$wt"
    git -C "$root" worktree prune
  fi
  rm -rf "$tmpd"
  rm -f "$pidf"
}

start() {
  local sha; sha="$(resolve "${1:-HEAD}")"; paths "$sha"
  if alive; then
    echo "already running: sha=$sha log=$log"; return 0
  fi
  pick_sandbox
  if [ -z "$mode" ]; then
    echo "refused: nothing here contains the candidate's code (SEC-19): $why." >&2
    echo "Install bubblewrap, or set CHECK_USER to an unprivileged user, or set CHECK_UNSANDBOXED=1 to run it with your own rights and network." >&2
    exit 3
  fi
  [ -e "$wt" ] && cleanup
  git -C "$root" worktree prune
  git -C "$root" worktree add --quiet --detach "$wt" "$sha"
  [ -n "${CHECK_CMD:-}" ] || seed "$wt"
  mkdir -p "$tmpd"
  local prefix=() gcommon v
  case "$mode" in
    bwrap)
      gcommon="$(cd "$root" && cd "$(git rev-parse --git-common-dir)" && pwd)"
      # The shared .git stays read-only even when it is under /tmp.
      # /run is emptied, so no host socket there can be reached either.
      prefix=("$bwrap_bin" --ro-bind / / --bind "$tmpd" /tmp --tmpfs /run --ro-bind "$gcommon" "$gcommon"
        --bind "$wt" "$wt" "${bwrap_flags[@]}" --setenv TMPDIR /tmp)
      for v in $(secret_vars); do prefix+=(--unsetenv "$v"); done
      prefix+=(--) ;;
    user|user-with-network)
      mkdir -p "$tmpd/home"
      chown -R "$check_user" "$wt" "$tmpd"
      read -r -a prefix <<< "$(as_user)"
      prefix+=(env)
      for v in $(secret_vars); do prefix+=(-u "$v"); done
      prefix+=(HOME="$tmpd/home" TMPDIR="$tmpd" PATH="$PATH"
        CARGO_HOME="${CARGO_HOME:-$HOME/.cargo}" RUSTUP_HOME="${RUSTUP_HOME:-$HOME/.rustup}") ;;
    unsandboxed)
      echo "warning: CHECK_UNSANDBOXED=1: the candidate's code runs with your rights and your network (SEC-19); $why." >&2 ;;
  esac
  echo "$mode" > "$modef"
  : > "$log"
  rm -f "$pidf"
  rm -f "$gitf.end"; fingerprint > "$gitf"
  # The log and the DONE line are written out here, outside the containment.
  local run; run="$(printf '%q ' "${prefix[@]}" bash -c "$(printf 'cd %q && %s' "$wt" "$cmd")")"
  # setsid may fork, so the run writes its own pid (also its process group).
  nohup setsid bash -c "echo \$\$ > '$pidf'; $run > '$log' 2>&1 < /dev/null; echo \"DONE exit=\$? sha=$sha\" >> '$log'" \
    > /dev/null 2>&1 < /dev/null &
  local i; for i in $(seq 50); do [ -s "$pidf" ] && break; sleep 0.1; done
  echo "started: sha=$sha log=$log sandbox=$mode"
}

json_str() { python3 -c 'import json,sys; print(json.dumps(sys.argv[1]))' "$1"; }

result() {
  local sha; sha="$(resolve "$1")"; paths "$sha"
  local state exit_code=null finished=null summary=""
  if [ ! -f "$log" ]; then
    state=NONE; summary="no run for this commit"
  elif last="$(tail -n 1 "$log")" && [[ "$last" == "DONE exit="* ]]; then
    exit_code="${last#DONE exit=}"; exit_code="${exit_code%% *}"
    finished="\"$(date -u -r "$log" +%Y-%m-%dT%H:%M:%SZ)\""
    # Taken once, when the run is first seen ended, so a later `record` reads the same.
    [ -f "$gitf.end" ] || fingerprint > "$gitf.end"
    if [ ! -f "$gitf" ]; then
      state=FAIL; summary="no record of .git from the run's start (SEC-19): start the run again"
    elif [ "$(cat "$gitf")" != "$(cat "$gitf.end")" ]; then
      state=FAIL; summary="repository changed by the run: .git/config or .git/hooks differs from before it (SEC-19)"
    elif [ "$exit_code" = 0 ] && grep -qx "All checks passed." "$log"; then
      state=PASS; summary="All checks passed."
    else
      state=FAIL
      summary="$(grep '^== ' "$log" | tail -n 1 || true): $(grep -v '^DONE exit=' "$log" | grep -v '^\s*$' | tail -n 1 || true)"
    fi
    cleanup
  elif alive; then
    state=RUNNING; summary="$(grep '^== ' "$log" | tail -n 1 || true)"
  else
    state=LOST; summary="no DONE line and no process: the run was killed; start it again"
    cleanup
  fi
  local sandbox=null; [ ! -f "$modef" ] || sandbox="\"$(cat "$modef")\""
  echo "{\"sha\": \"$sha\", \"state\": \"$state\", \"exit\": $exit_code, \"finished_at\": $finished, \"summary\": $(json_str "$summary"), \"sandbox\": $sandbox, \"log\": \"$log\"}"
}

wait_for() {
  local sha; sha="$(resolve "$1")"; local limit=$(( ${2:-90} * 60 )) waited=0 out
  while :; do
    out="$(result "$sha")"
    case "$out" in *'"state": "RUNNING"'*) ;; *) break ;; esac
    if [ "$waited" -ge "$limit" ]; then break; fi
    sleep 15; waited=$((waited + 15))
  done
  echo "$out"
  case "$out" in *'"state": "PASS"'*) return 0 ;; *) return 1 ;; esac
}

record() {
  local sha; sha="$(resolve "$1")"; local agent="$2" out
  out="$(result "$sha")"
  case "$out" in *'"state": "PASS"'*|*'"state": "FAIL"'*) ;; *) echo "$out"; echo "nothing to record yet" >&2; return 1 ;; esac
  python3 - "$root/docs/progress/status/$agent.json" "$out" <<'EOF'
import json, pathlib, sys
path, run = pathlib.Path(sys.argv[1]), json.loads(sys.argv[2])
status = json.loads(path.read_text()) if path.exists() else {"agent": path.stem}
status["precheck"] = {k: run[k] for k in ("sha", "exit", "finished_at", "summary")}
path.parent.mkdir(parents=True, exist_ok=True)
path.write_text(json.dumps(status, indent=2) + "\n")
print(f"precheck recorded in {path}")
EOF
}

self_test() {
  local tmp; tmp="$(mktemp -d)"
  trap 'rm -rf "$tmp"' RETURN
  git init --quiet "$tmp/repo"
  git -C "$tmp/repo" -c user.email=t@t -c user.name=t -c commit.gpgsign=false commit --quiet --allow-empty -m one
  mkdir -p "$tmp/repo/tools" && cp "$0" "$tmp/repo/tools/run_checks.sh"
  local me="$tmp/repo/tools/run_checks.sh" sha out
  sha="$(git -C "$tmp/repo" rev-parse HEAD)"
  export CHECK_DIR="$tmp/runs"; mkdir -p "$CHECK_DIR"
  # Its own commands, not a candidate's: run them contained if this machine
  # can, and without otherwise (inside a contained run, it usually cannot).
  export CHECK_UNSANDBOXED=1

  # A pass: outlives the call that started it, ends DONE exit=0, worktree removed.
  CHECK_CMD="sleep 1; echo '== one =='; echo 'All checks passed.'" bash "$me" start > /dev/null 2>&1
  out="$(bash "$me" result "$sha")"; [[ "$out" == *'"state": "RUNNING"'* ]] || { echo "not running: $out"; return 1; }
  out="$(bash "$me" wait "$sha" 1)" || { echo "wait failed: $out"; return 1; }
  [[ "$out" == *'"state": "PASS"'* && "$out" == *'"exit": 0'* ]] || { echo "not a pass: $out"; return 1; }
  [ ! -d "$CHECK_DIR/check-$sha" ] || { echo "worktree left behind"; return 1; }
  bash "$me" record "$sha" AD > /dev/null
  python3 -c "import json,sys; p=json.load(open(sys.argv[1]))['precheck']; assert p['exit']==0 and p['sha']==sys.argv[2], p" \
    "$tmp/repo/docs/progress/status/AD.json" "$sha"

  # A failure: the summary names the last heading.
  rm -f "$CHECK_DIR/check-$sha.log"
  CHECK_CMD="echo '== two =='; echo boom; exit 3" bash "$me" start > /dev/null 2>&1
  if out="$(bash "$me" wait "$sha" 1)"; then echo "a failure passed: $out"; return 1; fi
  [[ "$out" == *'"state": "FAIL"'* && "$out" == *'"exit": 3'* && "$out" == *'== two ==: boom'* ]] || { echo "bad failure: $out"; return 1; }

  # Exit 0 without the closing line is still a failure.
  rm -f "$CHECK_DIR/check-$sha.log"
  CHECK_CMD="echo '== three =='" bash "$me" start > /dev/null 2>&1
  if out="$(bash "$me" wait "$sha" 1)"; then echo "no closing line passed: $out"; return 1; fi

  # A killed run (no DONE line, no process) is LOST, not RUNNING.
  rm -f "$CHECK_DIR/check-$sha.log"
  CHECK_CMD="sleep 30" bash "$me" start > /dev/null 2>&1
  kill -- "-$(cat "$CHECK_DIR/check-$sha.pid")" 2>/dev/null || true
  sleep 1
  out="$(bash "$me" result "$sha")"; [[ "$out" == *'"state": "LOST"'* ]] || { echo "not lost: $out"; return 1; }
  echo "run_checks.sh self-test: ok"
}

case "${1:-}" in
  start) start "${2:-HEAD}" ;;
  result) [ $# -eq 2 ] || { echo "usage: result <sha>" >&2; exit 2; }; result "$2" ;;
  wait) [ $# -ge 2 ] || { echo "usage: wait <sha> [minutes]" >&2; exit 2; }; wait_for "$2" "${3:-90}" ;;
  record) [ $# -eq 3 ] || { echo "usage: record <sha> <agent>" >&2; exit 2; }; record "$2" "$3" ;;
  --self-test) self_test ;;
  *) sed -n '2,20p' "$0"; exit 2 ;;
esac
