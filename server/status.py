#!/usr/bin/env python3
"""Run the server's tests and write server/status.json.

    python3 server/status.py

The server's counterpart to sim/status.py: every test by name with its
outcome, so what reads "built" elsewhere (tools/completion.py) is read from
a run rather than typed. It exits non-zero if any test failed, which is what
makes it a gate in tools/check_all.sh.
"""

import json
import pathlib
import re
import subprocess
import sys

HERE = pathlib.Path(__file__).resolve().parent


def run() -> dict[str, str]:
    files = sorted(str(p.relative_to(HERE)) for p in (HERE / "test").glob("*.test.mjs"))
    out = subprocess.run(["node", "--no-warnings", "--test", "--test-reporter=tap", *files],
                         cwd=HERE, capture_output=True, text=True)
    results = {}
    # Top-level results only: node's TAP indents subtests, and every test
    # here is top-level.
    for m in re.finditer(r"^(not ok|ok) \d+ - (.+)$", out.stdout, re.M):
        results[m.group(2).strip()] = "passed" if m.group(1) == "ok" else "failed"
    if not results:
        sys.stdout.write(out.stdout + out.stderr)
        raise SystemExit("no test results were read from node --test")
    return results


def main() -> int:
    results = run()
    status = {
        "_what": "Written by server/status.py. Results, not claims: "
                 "tools/completion.py reads what is built from this file.",
        "tests": dict(sorted(results.items())),
    }
    (HERE / "status.json").write_text(json.dumps(status, indent=1, ensure_ascii=False) + "\n",
                                      encoding="utf-8")
    failed = [name for name, r in results.items() if r != "passed"]
    print(f"  tests: {len(results) - len(failed)} of {len(results)} passed — "
          f"written to server/status.json")
    for name in failed:
        print(f"  FAILED: {name}")
    return 1 if failed else 0


if __name__ == "__main__":
    raise SystemExit(main())
