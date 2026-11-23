#!/usr/bin/env bash
# T3.1 and T3.2's gate: the float ban, every test, the golden replays, and the
# same digest from native x86-64 and WebAssembly at five seeds.
#
#     bash sim/run_spike.sh
#
# status.py runs all of it and writes sim/status.json, which is what the audit
# page reads to say what is built. One gate, so the page and the build cannot
# disagree about what passed. test_tools.py first: a blind gate tool fails it.
set -euo pipefail
cd "$(dirname "$0")"
echo "== the simulation core (T3.1, T3.2, T5.5, line of sight)"
python3 test_tools.py
python3 status.py
