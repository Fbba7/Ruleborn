#!/usr/bin/env bash
# Every check in the repository, in dependency order.
#
#   ./tools/check_all.sh
#
# Non-zero exit means something is actually wrong. Known contradictions in the
# design document are reported by validate_content.py but do not fail — they are
# tracked in the audit register and shrink as the document is reconciled.
set -euo pipefail
cd "$(dirname "$0")/.."

echo "== design document consistency =="
python3 tools/check_design_consistency.py docs/design/ruleborn-game-design-v2.3.txt

echo
echo "== content tables =="
python3 tools/validate_content.py

echo
echo "== generated docs are in sync with the data =="
python3 tools/generate_docs.py --check

echo
echo "== economy model =="
python3 -m tools.economy_model.test_economy_model

echo
echo "== this repository's own documents agree with each other =="
python3 tools/check_docs_consistency.py

echo
echo "== audit register builds =="
python3 tools/build_audit.py

echo
echo "All checks passed."
