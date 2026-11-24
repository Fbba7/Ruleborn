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


# A top-level TAP result: `ok N - name`, `not ok N - name`, either with a
# ` # SKIP` or ` # TODO` directive. Node writes a `#` inside a name as `\#`,
# so a name never holds ` # `.
TAP = re.compile(r"^(not ok|ok) \d+ - (.*?)(?: # (?i:(skip|todo))\b.*)?$", re.M)


def tap_results(text: str) -> dict[str, str]:
    """Each top-level test by name: "passed", "failed", "skipped" (a SKIP or
    TODO directive: the program never skips a test, so it fails the run,
    FX1-T-02) or "repeated" (two results under one name: one could hide the
    other, so the name fails the run, FX1-T-01). Node's TAP indents
    subtests; client/status.py reads the client's run with this too."""
    results: dict[str, str] = {}
    for m in TAP.finditer(text):
        name = m.group(2).strip()
        outcome = "skipped" if m.group(3) else "passed" if m.group(1) == "ok" else "failed"
        results[name] = "repeated" if name in results else outcome
    return results


def run() -> dict[str, str]:
    files = sorted(str(p.relative_to(HERE)) for p in (HERE / "test").glob("*.test.mjs"))
    out = subprocess.run(["node", "--no-warnings", "--test", "--test-reporter=tap", *files],
                         cwd=HERE, capture_output=True, text=True)
    results = tap_results(out.stdout)
    if not results:
        sys.stdout.write(out.stdout + out.stderr)
        raise SystemExit("no test results were read from node --test")
    # Node's own count, and its exit: a failure the lines above did not read
    # still fails the run.
    summary = {k: int(n) for k, n in re.findall(r"^# (fail|cancelled|skipped|todo) (\d+)$", out.stdout, re.M)}
    if out.returncode != 0 or any(summary.values()):
        if all(r == "passed" for r in results.values()):
            results["node --test: " + ", ".join(f"{k} {n}" for k, n in summary.items())
                    + f", exit {out.returncode}"] = "failed"
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
        print(f"  {results[name].upper()}: {name}")
    return 1 if failed else 0


if __name__ == "__main__":
    raise SystemExit(main())
