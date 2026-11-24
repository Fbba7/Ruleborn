#!/usr/bin/env python3
"""The gate's own tools, tested: the float ban (no_floats.py) and the test
count (status.py). A gate that passes what it should refuse is worse than no
gate, because the page then reports a property nobody checked.

    python3 sim/test_tools.py

run_spike.sh runs this before status.py, so a gate tool that goes blind
fails the gate.
"""

import contextlib
import io
import pathlib
import subprocess
import sys
import tempfile

HERE = pathlib.Path(__file__).resolve().parent
sys.path.insert(0, str(HERE))

import no_floats  # noqa: E402
import status  # noqa: E402

FAILURES: list[str] = []


def check(ok: bool, what: str) -> None:
    print(f"  {'ok  ' if ok else 'FAIL'} {what}")
    if not ok:
        FAILURES.append(what)


def floats_found(source: str) -> bool:
    """True when no_floats refuses a crate holding only `source`."""
    with tempfile.TemporaryDirectory() as d:
        (pathlib.Path(d) / "case.rs").write_text(source)
        was = no_floats.SRC
        no_floats.SRC = pathlib.Path(d)
        try:
            with contextlib.redirect_stdout(io.StringIO()):
                code = no_floats.main()
        finally:
            no_floats.SRC = was
        return code != 0


def float_ban() -> None:
    # Audit finding SIM-3 (docs/security/audit-2026-11/sim.md): each of these
    # is floating point in Rust, and no_floats.py let it through.
    for case in [
        "fn f() -> u32 { let x = 1f64; 0 }",
        "fn f() -> u32 { let x = 1.5f32; 0 }",
        "fn f() -> u32 { let x = 1e3; 0 }",
        "fn f() -> u32 { let x = 2.5e-1; 0 }",
        "fn f() -> u32 { let x = 1_000.5; 0 }",
        "fn f() -> u32 { let x = 1.; 0 }",
        'fn f() -> u32 { let s = "//"; let z = 1.5; 0 }',
        "fn f(p: &mut T) {\n    *p = 2.5;\n}",
    ]:
        check(floats_found(case), f"the float ban refuses {case!r}")
    # What it must keep allowing, so the fix does not turn the ban off.
    for case in [
        "// §24.10 says 0.5\nfn f() {}",
        "/*\n * §24.10 says 0.5\n */\nfn f() {}",
        'fn f() { panic!("§24.10: 0.5"); }',
        "fn f() -> u32 { 0x1e3 + 1e_x() }",
        "fn f() { for i in 0..5 {} let a = t.0.1; let b = 1.max(2); }",
        "fn f(p: &mut u32) {\n    *p = 2;\n}",
    ]:
        check(not floats_found(case), f"the float ban allows {case!r}")


CARGO = """\
running 3 tests
test stability::tests::strain_falls_in_5_5s_seven_bands ... FAILED
test tests::a_heist_replays ... ok
test tests::a_wall_blocks ... ok

test result: FAILED. 2 passed; 1 failed
"""


def test_count() -> None:
    # Audit finding SIM-4 (docs/security/audit-2026-11/sim.md): status.py
    # counted only `tests::` and never read cargo's exit code, so a failing
    # test in another module left "every gate holds".
    was = subprocess.run
    try:
        subprocess.run = lambda *a, **k: subprocess.CompletedProcess(a, 101, CARGO, "")
        got = status.tests()
    finally:
        subprocess.run = was
    check(got.get("a_heist_replays") == "passed", "a tests:: test keeps its bare name")
    check(got.get("stability::strain_falls_in_5_5s_seven_bands") == "failed",
          "a failing stability:: test is counted as failed")
    quiet = CARGO.replace("FAILED\n", "ok\n", 1)
    try:
        subprocess.run = lambda *a, **k: subprocess.CompletedProcess(a, 101, quiet, "")
        got = status.tests()
    finally:
        subprocess.run = was
    check(any(v == "failed" for v in got.values()),
          "cargo exiting non-zero fails the count even when every line says ok")


def main() -> int:
    float_ban()
    test_count()
    if FAILURES:
        print(f"\n  {len(FAILURES)} gate-tool checks FAILED")
        return 1
    print("\n  the gate's tools refuse what they should")
    return 0


if __name__ == "__main__":
    sys.exit(main())
