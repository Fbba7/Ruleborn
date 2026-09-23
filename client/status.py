#!/usr/bin/env python3
"""Build the client, run its tests headless, and write client/status.json.

    python3 client/status.py

The client's counterpart to server/status.py: every test by name with its
outcome, so what reads "built" elsewhere (tools/completion.py) is read from a
run rather than typed. It exits non-zero if any test failed, which is what
makes it a gate in tools/check_all.sh.
"""

import json
import pathlib
import re
import subprocess
import sys

HERE = pathlib.Path(__file__).resolve().parent


def run() -> dict[str, str]:
    build = subprocess.run(["bash", str(HERE / "build.sh")], capture_output=True, text=True)
    if build.returncode != 0:
        sys.stdout.write(build.stdout + build.stderr)
        raise SystemExit("client/build.sh failed")
    godot = build.stdout.strip().splitlines()[-1]
    out = subprocess.run([godot, "--headless", "--path", str(HERE), "-s", "res://tests/run.gd"],
                         capture_output=True, text=True, timeout=600)
    results = {}
    for m in re.finditer(r"^(not ok|ok) \d+ - (.+)$", out.stdout, re.M):
        results[m.group(2).strip()] = "passed" if m.group(1) == "ok" else "failed"
    if not results or out.returncode not in (0, 1):
        sys.stdout.write(out.stdout + out.stderr)
        raise SystemExit("no test results were read from the client's headless run")
    for line in out.stdout.splitlines():
        if line.startswith("  # "):
            print(line)
    return results


def main() -> int:
    results = run()
    status = {
        "_what": "Written by client/status.py. Results, not claims: "
                 "tools/completion.py reads what is built from this file.",
        "tests": dict(sorted(results.items())),
    }
    (HERE / "status.json").write_text(json.dumps(status, indent=1, ensure_ascii=False) + "\n",
                                      encoding="utf-8")
    failed = [name for name, r in results.items() if r != "passed"]
    print(f"  tests: {len(results) - len(failed)} of {len(results)} passed — "
          f"written to client/status.json")
    for name in failed:
        print(f"  FAILED: {name}")
    return 1 if failed else 0


if __name__ == "__main__":
    raise SystemExit(main())
