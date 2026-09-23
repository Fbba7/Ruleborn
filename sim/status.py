#!/usr/bin/env python3
"""Run every gate the simulation core has, and write sim/status.json.

    python3 sim/status.py

This is what the audit page reads to say what is built. It records results,
not claims: every test by name with its outcome, every golden replay with its
size and whether it verifies, and every target with the digest it produced.
`systems.json` says which tests prove which system; the page shows a system
as built only if all of them passed here.

`run_spike.sh` calls this, so there is one gate rather than two that could
disagree.
"""

import json
import pathlib
import re
import subprocess
import sys

import content_gate

HERE = pathlib.Path(__file__).resolve().parent
SEEDS = [1, 6840123409045651457, 18446744073709551615, 42, 999983]
TICKS = 7200


def sh(*cmd: str, check: bool = True) -> str:
    out = subprocess.run(cmd, cwd=HERE, capture_output=True, text=True)
    if check and out.returncode != 0:
        sys.stdout.write(out.stdout)
        sys.stderr.write(out.stderr)
        raise SystemExit(f"failed: {' '.join(cmd)}")
    return out.stdout + out.stderr


def tests() -> dict[str, str]:
    out = sh("cargo", "test", "--release", "--", "--test-threads=1", check=False)
    return {m.group(1): ("passed" if m.group(2) == "ok" else "failed")
            for m in re.finditer(r"^test tests::(\w+) \.\.\. (ok|FAILED)$", out, re.M)}


def goldens() -> list[dict]:
    rows = []
    out = sh("cargo", "run", "--release", "--quiet", "--example", "where_diverge")
    verdicts = dict(re.findall(r"^(\S+\.rbh)\s+(.+)$", out, re.M))
    for path in sorted((HERE / "golden").glob("*.rbh")):
        rows.append({"file": path.name, "bytes": path.stat().st_size,
                     "verifies": verdicts.get(path.name) == "verifies"})
    return rows


def targets() -> list[dict]:
    sh("cargo", "build", "--release", "--quiet")
    sh("cargo", "build", "--release", "--quiet", "--target", "wasm32-unknown-unknown")
    rows = []
    for seed in SEEDS:
        native = sh("cargo", "run", "--release", "--quiet", "--bin", "spike", "--",
                    str(seed), str(TICKS))
        wasm = sh("node", "wasm_spike.mjs", str(seed), str(TICKS))
        nd = re.search(r"^digest (\w+)", native, re.M).group(1)
        wd = re.search(r"^digest (\w+)", wasm, re.M).group(1)
        size = int(re.search(r"^encoded (\d+)", native, re.M).group(1))
        # The server's half: rules version, island hash, a recorded replay's
        # hash and the verdict on it, from each build (§24.12).
        nv = re.search(r"^validator (.+)$", native, re.M).group(1)
        wv = re.search(r"^validator (.+)$", wasm, re.M).group(1)
        rows.append({"seed": str(seed), "native": nd, "wasm": wd,
                     "validator_agree": nv == wv, "validator": nv.split()[-5:],
                     "agree": nd == wd and nv == wv, "bytes": size})
    return rows


def main() -> int:
    floats_ok = subprocess.run([sys.executable, "no_floats.py"], cwd=HERE,
                               capture_output=True).returncode == 0
    gate = content_gate.compare(*content_gate.load(), content_gate.source_text())
    facts = content_gate.facts_compare(content_gate.source_text())
    laws = content_gate.laws_compare(content_gate.source_text())
    wards = content_gate.wards_compare(content_gate.source_text())
    gate["checked"] += facts["checked"] + laws["checked"] + wards["checked"]
    gate["wrong"] += facts["wrong"] + laws["wrong"] + wards["wrong"]
    checked, wrong = gate["checked"], gate["wrong"] + [
        f"{p} — compared by nothing and listed nowhere" for p in gate["uncovered"]]
    t = tests()
    g = goldens()
    x = targets()
    status = {
        "_what": "Written by sim/status.py. Results, not claims: the audit "
                 "page derives what is built from this file and systems.json.",
        "ticks": TICKS,
        "floats_absent": floats_ok,
        "tests": dict(sorted(t.items())),
        "goldens": g,
        "cross_target": x,
        "content": {
            "agree": len(checked),
            "disagree": wrong,
            "not_modelled": [f"{what} — {why}"
                             for what, why in content_gate.NOT_MODELLED]
                            + [f"rule sheet {what} — {why}"
                               for what, why in content_gate.LAW_PARAMS_NOT_MODELLED],
            "readings": gate["readings"],
        },
    }
    (HERE / "status.json").write_text(json.dumps(status, indent=1) + "\n")

    passed = sum(1 for v in t.values() if v == "passed")
    agree = sum(1 for r in x if r["agree"])
    print(f"  float ban: {'holds' if floats_ok else 'BROKEN'}")
    print(f"  content: {len(checked)} values agree with content/ and tools/design_facts.py"
          + (f", {len(wrong)} DISAGREE" if wrong else ""))
    print(f"  tests: {passed} of {len(t)} passed")
    print(f"  goldens: {sum(r['verifies'] for r in g)} of {len(g)} verify, "
          f"largest {max(r['bytes'] for r in g)} bytes of 2048")
    for r in x:
        print(f"  seed {r['seed']:<21} {r['native']}  "
              f"{'agree' if r['agree'] else 'DIVERGED'}   {r['bytes']} bytes")
    # The audit page reads systems.json against this file. A test nothing
    # claims is invisible there, and a claimed test that no longer exists
    # would leave a system that cannot be shown as built — both are
    # bookkeeping faults, and both fail here rather than on the page.
    manifest = json.loads((HERE / "systems.json").read_text())
    claimed = {name for system in manifest["systems"] for name in system["tests"]}
    unclaimed = sorted(set(t) - claimed)
    vanished = sorted(claimed - set(t))
    if unclaimed:
        print(f"  tests no system claims: {', '.join(unclaimed)}")
    if vanished:
        print(f"  tests systems.json names that do not exist: {', '.join(vanished)}")

    ok = floats_ok and not wrong and passed == len(t) and all(r["verifies"] for r in g) \
        and agree == len(x) and not unclaimed and not vanished
    print(f"\n  {'every gate holds' if ok else 'A GATE FAILED'} — "
          f"written to sim/status.json")
    return 0 if ok else 1


if __name__ == "__main__":
    raise SystemExit(main())
