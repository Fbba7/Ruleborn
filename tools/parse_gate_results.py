#!/usr/bin/env python3
"""Read the result codes from the heist prototype and score both gates.

Testers finish the prototype with a one-line JSON code. Collect them one per
line in a file (blank lines and lines starting with # are ignored) and run:

    python3 tools/parse_gate_results.py results.txt

Thresholds come from the design document: §19.27 for gate 1, §13.3 for gate 2,
§30.8 for felt control. The script states its own confidence honestly — these
samples can show a large effect and not much else.
"""

import json
import statistics
import sys


def load(path: str) -> list[dict]:
    out = []
    for lineno, raw in enumerate(open(path, encoding="utf-8"), start=1):
        line = raw.strip()
        if not line or line.startswith("#"):
            continue
        try:
            out.append(json.loads(line))
        except json.JSONDecodeError:
            print(f"  ! line {lineno} is not a result code, skipped", file=sys.stderr)
    return out


def median(values: list[float]) -> float | None:
    return statistics.median(values) if values else None


def pct(part: int, whole: int) -> float:
    return 100.0 * part / whole if whole else 0.0


def verdict(ok: bool | None) -> str:
    return "PASS" if ok else ("—" if ok is None else "FAIL")


def main() -> int:
    if len(sys.argv) != 2:
        print(__doc__, file=sys.stderr)
        return 2
    rows = load(sys.argv[1])
    if not rows:
        print("No result codes found.", file=sys.stderr)
        return 1

    n = len(rows)
    print(f"\n{n} session{'s' if n != 1 else ''}\n")

    # ---- gate 1: does a no-loss heist feel tense? (§19.27) ----------------
    tense = [r["survey"]["tense"] for r in rows if r.get("survey", {}).get("tense")]
    pressure = [r["survey"]["pressure"] for r in rows if r.get("survey", {}).get("pressure")]
    enjoy = [r["survey"]["enjoy"] for r in rows if r.get("survey", {}).get("enjoy")]
    control = [r["survey"]["control"] for r in rows if r.get("survey", {}).get("control")]
    again = sum(1 for r in rows if r.get("again", 0) > 0)

    m_tense, m_enjoy = median(tense), median(enjoy)
    played_again = pct(again, n)
    high_control = pct(sum(1 for c in control if c >= 4), len(control)) if control else 0.0

    print("GATE 1 — does a no-loss heist feel tense? (§19.27)")
    print(f"  {verdict(m_tense is not None and m_tense >= 3):>4}  median tension        "
          f"{m_tense if m_tense is not None else '-':>5}  of 4      (threshold ≥ 3)")
    print(f"  {'    '}  median pressure       {median(pressure) if pressure else '-':>5}  of 4")
    print(f"  {verdict(m_enjoy is not None and m_enjoy >= 6):>4}  median enjoyment      "
          f"{m_enjoy if m_enjoy is not None else '-':>5}  of 10     (threshold ≥ 6)")
    print(f"  {verdict(played_again >= 60):>4}  chose to play again   {played_again:>5.0f}%"
          f"            (threshold ≥ 60%) — behaviour, not opinion")
    print()

    print("GATE 1b — playing, or watching? (§30.7 premise 3)")
    print(f"  {verdict(high_control >= 70):>4}  felt in control (4-5) {high_control:>5.0f}%"
          f"            (threshold ≥ 70%, §30.8)")
    orders = [h[4] for r in rows for h in r.get("heists", [])]
    if orders:
        print(f"  {'    '}  orders per heist      {median(orders):>5}"
              f"            (§12.6 wants 15-25 decisions a run)")
    print()

    # ---- gate 2: will anyone build a second island? (§13.3) --------------
    reached = [r for r in rows if r.get("built", 0) >= 1]
    second = sum(1 for r in reached if r.get("second"))
    rate = pct(second, len(reached))

    print("GATE 2 — will anyone build a second island, unprompted? (§13.3)")
    print(f"        reached the build step   {len(reached)} of {n}")
    print(f"        built a second island    {second}  =  {rate:.0f}%")
    if not reached:
        print("        -> no verdict: nobody got that far")
    elif rate >= 30:
        print("        -> AUTHORSHIP. Creation can carry the Workshop; build the")
        print("           creator ladder in §18.7 as designed.")
    elif rate >= 15:
        print("        -> AUTHORSHIP WITH HELP. Templates instead of a blank island,")
        print("           a guided build in onboarding, the raid replayed back to the")
        print("           builder, and recognition from the first week.")
    else:
        print("        -> PIVOT. Islands are largely generated and the player's")
        print("           creative act becomes choosing, tuning and naming one.")
        print("           Every other system survives intact (§13.3).")
    print()

    # ---- what the heists themselves did -----------------------------------
    heists = [h for r in rows for h in r.get("heists", [])]
    if heists:
        outcomes = {}
        for h in heists:
            outcomes[h[1]] = outcomes.get(h[1], 0) + 1
        spread = "  ".join(f"{k}:{v}" for k, v in sorted(outcomes.items()))
        print(f"HEISTS  {len(heists)} played   outcomes  {spread}")
        print(f"        median seconds {median([h[3] for h in heists])} of 150"
              f"   median heists per tester {median([len(r.get('heists', [])) for r in rows])}")
        print()

    print("Read with care: a sample of ten to twenty can show a large effect but")
    print("not measure a small one (§19.27). These gates ask large questions —")
    print("does anyone come back, does anyone build twice — so that is enough for")
    print("them, and not enough for tuning anything.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
