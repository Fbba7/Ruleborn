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
python3 tools/check_design_consistency.py

echo
echo "== content tables =="
python3 tools/validate_content.py

echo
echo "== generated docs are in sync with the data =="
python3 tools/generate_docs.py --check

echo
echo "== the register's edits match the document =="
python3 tools/check_edits.py

echo
echo "== the proposed note rebalance is still valid =="
python3 tools/note_rebalance.py | tail -14

echo
echo "== economy model =="
python3 -m tools.economy_model.test_economy_model

echo
echo "== heist harness =="
python3 -m tools.heist_harness.test_harness

echo
echo "== the playable prototype matches the rules it claims to implement =="
python3 tools/build_prototype.py --check
python3 tools/build_prototype.py --self-test
python3 tools/build_stamp.py --self-test
python3 tools/check_prototype_conformance.py

echo
echo "== the dependency graph is well formed =="
python3 tools/check_dependencies.py --self-test
python3 tools/check_dependencies.py --write

echo
echo "== which register numbers can be shown to be current =="
python3 tools/check_findings_fresh.py --self-test
python3 tools/check_findings_fresh.py

echo
echo "== the law scope cut is costed and chord-safe =="
python3 tools/scope_cut.py --self-test

echo
echo "== every field the harness computes is read somewhere =="
python3 tools/check_unread_fields.py --self-test
python3 tools/check_unread_fields.py

echo
echo "== this repository's own documents agree with each other =="
python3 tools/check_docs_consistency.py

echo
echo "== audit register builds =="
python3 tools/build_audit.py

echo
echo "== roadmap builds and is internally consistent =="
python3 tools/build_roadmap.py

echo
echo "All checks passed."
