"""Run the §19.27 harnesses.

    python3 -m tools.heist_harness                 # every report
    python3 -m tools.heist_harness depth           # one report
    python3 -m tools.heist_harness depth 500       # more runs a cell

§19.27 asks for "thousands of heists". The defaults are smaller so the reports
are quick to re-run while a number is being changed; pass a count to widen them.
A run is about 80 milliseconds, so a thousand a cell is a couple of minutes.
"""

import sys

from . import ablation, report

REPORTS = {
    "depth": report.tension_and_depth,
    "defence": report.defence_balance,
    "ablation": ablation.report,
    "control": report.attribution,
}


def main() -> int:
    args = sys.argv[1:]
    runs = None
    if args and args[-1].isdigit():
        runs = int(args.pop())
    if args:
        name = args[0]
        if name not in REPORTS:
            print(f"unknown report {name!r}; choose from {', '.join(REPORTS)}",
                  file=sys.stderr)
            return 2
        print(REPORTS[name](runs) if runs else REPORTS[name]())
        return 0
    print(report.all_reports(runs) if runs else report.all_reports())
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
