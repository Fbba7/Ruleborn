#!/usr/bin/env bash
# Every check in the repository, in dependency order.
#
#   ./tools/check_all.sh
#
# Non-zero exit means something is actually wrong.
#
# A known contradiction in the design document is not "something wrong" — it is
# work not yet done, and it is tracked in the audit register. check_document.py
# tells the two apart: a check that fails while its register item is open is
# reported OPEN and passes the gate; one that fails with no item, or with an
# item the register calls fixed, breaks the build. validate_content.py reports
# the same way over content/.
set -euo pipefail
cd "$(dirname "$0")/.."

echo "== design document consistency =="
python3 tools/check_document.py --self-test
python3 tools/check_document.py --coverage
python3 tools/check_document.py

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
echo "== the generator's settings, against both bands the document sets =="
python3 -m tools.generator_settings --self-test

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
