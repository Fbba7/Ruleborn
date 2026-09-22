#!/usr/bin/env bash
# T3.1 — one function, the same checksum on every target.
#
#     bash sim/run_spike.sh
#
# §24.2: "the first technical task — before art, before content — is proving a
# heist replays identically on an ARM phone and an x86 server. If it does not,
# every one of those advantages disappears at once."
#
# This runs the two targets this repository can reach: native x86-64 and
# WebAssembly. They are not the same instruction set and not the same compiler
# backend, which is what makes agreement between them evidence rather than a
# tautology. The two it cannot reach — a real iPhone and a real Android — are
# the rest of T3.1's gate and need devices.
set -euo pipefail
cd "$(dirname "$0")"

SEEDS=(1 6840123409045651457 18446744073709551615 42 999983)
TICKS=${TICKS:-7200}

echo "== the float ban (24.10: 'refuses to compile if one appears')"
python3 no_floats.py

echo
echo "== building both targets"
cargo build --release --quiet
cargo build --release --quiet --target wasm32-unknown-unknown

echo
echo "== $TICKS ticks per seed, native against WebAssembly"
fail=0
for seed in "${SEEDS[@]}"; do
  native=$(cargo run --release --quiet --bin spike -- "$seed" "$TICKS" | awk '/^digest/{print $2}')
  wasm=$(node wasm_spike.mjs "$seed" "$TICKS" | awk '/^digest/{print $2}')
  if [ "$native" = "$wasm" ]; then
    printf '  seed %-21s %s  agree\n' "$seed" "$native"
  else
    printf '  seed %-21s native %s  wasm %s  DIVERGED\n' "$seed" "$native" "$wasm"
    fail=1
  fi
done

echo
if [ "$fail" -eq 0 ]; then
  echo "  ${#SEEDS[@]} seeds, ${TICKS} ticks each: every digest agrees across both targets."
  echo "  That is two of T3.1's four. A real iPhone and a real Android are the"
  echo "  other two, and they need devices this repository does not have."
else
  echo "  A digest diverged. §24.10: 'the first mismatched second narrows a"
  echo "  divergence to thirty ticks, then a tick-by-tick comparison finds it"
  echo "  exactly' — run the native binary with the seed to get the per-second list."
  exit 1
fi
