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

echo "== which design document every check reads =="
python3 tools/design_doc.py
python3 tools/design_facts.py > /dev/null

echo
echo "== design document consistency =="
python3 tools/check_document.py --self-test
python3 tools/check_document.py --coverage
python3 tools/check_document.py

echo
echo "== §31.5's own fifteen breakages, and the same defects reworded =="
python3 tools/mutation_gate.py
python3 tools/twice_stated.py --self-test

echo
echo "== the simulation core: every test, the goldens, and native against WebAssembly =="
# Writes sim/status.json, which the audit page's "What is built" band reads
# further down — so this has to run before build_audit.py, and does.
python3 sim/content_gate.py --self-test
bash sim/run_spike.sh

echo
echo "== the server: lease, validate, grant, against the simulation build just made =="
python3 tools/design_facts.py --check-json server/src/facts.json
python3 tools/league_model.py --check server/src/leagues.json
python3 server/status.py
node --no-warnings server/load.mjs --check
node --no-warnings server/src/privacy.mjs --check
python3 tools/privacy_manifest.py --check
python3 tools/build_brief.py --check

echo
echo "== the client: the same simulation inside Godot, and its screen =="
python3 tools/client_strings.py --check
python3 tools/client_contract.py
(cd client && gdlint $(find . -name '*.gd' -not -path './.godot/*'))
python3 client/status.py
# The store builds as far as this machine goes: both phones' arm64 compiled,
# and the exported pack holding what the game reads (TC.3).
bash client/export.sh check

echo
echo "== what changed since the previous version =="
python3 tools/version_diff.py --self-test

echo
echo "== where every launch-inventory count lives =="
python3 tools/inventory_homes.py --self-test

echo
echo "== content tables =="
python3 tools/validate_content.py --self-test
python3 tools/validate_content.py

echo
echo "== generated docs are in sync with the data =="
python3 tools/generate_docs.py --check

echo
echo "== the register's edits match the document =="
python3 tools/check_edits.py --self-test
python3 tools/check_edits.py

echo
echo "== the proposed note rebalance is still valid =="
python3 tools/note_rebalance.py | tail -14

echo
echo "== C3's rank splits, and whether §7.9's rule survives the sheets =="
python3 tools/law_ranks.py --self-test

echo
echo "== the three decisions 12.8, 12.19 and 12.6 turn on (F4, F5, F6) =="
python3 tools/decision_support.py --self-test
python3 tools/decision_support.py > /dev/null

echo
echo "== F12's eight authored laws, and the rule the generator gets =="
python3 tools/law_effects.py --self-test

echo
echo "== C6's 18 ability pairs, sorted by what kind of difference they are =="
python3 tools/ability_text.py --self-test

echo
echo "== economy model =="
python3 -m tools.economy_model.test_economy_model

echo
echo "== heist harness =="
python3 -m tools.heist_harness.test_harness

echo
echo "== the generator's settings, against both bands the document sets =="
python3 -m tools.generator_settings --self-test
python3 -m tools.post_ladder --self-test
python3 -m tools.ward_budget --self-test

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
python3 tools/check_docs_consistency.py --self-test
python3 tools/check_docs_consistency.py

echo
echo "== audit register builds =="
python3 tools/build_audit.py

echo
echo "== the audit page's tabs, bars and chips agree with the register =="
python3 tools/check_audit_ui.py --self-test
python3 tools/check_audit_ui.py

echo
echo "== roadmap builds and is internally consistent =="
python3 tools/completion.py --self-test
python3 tools/build_roadmap.py

echo
echo "All checks passed."
