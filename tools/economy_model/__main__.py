"""Run the economy model's reports.

    python3 -m tools.economy_model            # every report
    python3 -m tools.economy_model production # one report
"""

import sys

from . import report

REPORTS = {
    "production": report.production_vs_published,
    "positions": report.position_budget,
    "raiding": report.raiding_trade_off,
    "faucet": report.faucet_comparison,
    "sinks": report.sink_audit,
}


def main() -> int:
    if len(sys.argv) > 1:
        name = sys.argv[1]
        if name not in REPORTS:
            print(f"unknown report {name!r}; choose from {', '.join(REPORTS)}", file=sys.stderr)
            return 2
        print(REPORTS[name]())
        return 0
    print(report.all_reports())
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
