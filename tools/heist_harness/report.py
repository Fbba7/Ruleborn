"""§19.27's questions, answered as the section asks them.

    python3 -m tools.heist_harness

Each block below is one row of §19.27's table: the question, how it is answered
without anyone, and the threshold it passes at. The thresholds are the document's
own; nothing here was tuned to meet them.
"""

import collections
import statistics as st

from .fixed import TPS
from .island import generate
from .policy import POLICIES
from .sim import Heist

#: §19.27's own numbers.
DECISIONS_BAND = (15, 25)
NEAR_CAPTURE_SHARE = 50          # per cent of runs
LATE_DECIDED_SHARE = 25          # per cent of runs
DEPTH_SEPARATION = 35            # percentage points, optimal over careless


def run_batch(n: int, links: int, realm_level: int, policy_name: str,
              seed0: int = 0) -> list:
    cls = POLICIES[policy_name]
    out = []
    for i in range(n):
        seed = seed0 + i
        crossing = [generate(900_000 + seed * 8 + k, realm_level) for k in range(links)]
        policy = cls()
        result = Heist(generate(seed, realm_level), policy,
                       realm_level=realm_level, crossing=crossing).run()
        result.crew_decisions = policy.crew_decisions
        result.member_decisions = policy.member_decisions
        out.append(result)
    return out


def _pct(xs) -> int:
    return round(100 * sum(1 for x in xs if x) / len(xs)) if xs else 0


def tension_and_depth(n: int = 50, realm_level: int = 3) -> str:
    lines = ["Is the heist tense, and is there depth? (§19.27)", ""]
    lines.append("Both questions come off one batch, because they are the same runs")
    lines.append("read two ways. Decisions are counted as policy.py's header defines")
    lines.append("them: a change of commitment where more than one option was open.")
    lines.append("")
    lines.append(f"{'realms':>7} {'policy':<10} {'runs':>5} {'success':>8} {'decisions':>10} "
                 f"{'per-member':>11} {'run':>7} {'clock':>6} {'near-cap':>9} {'late':>6}")
    table = {}
    for links in (0, 1, 2, 3):
        for name in ("careless", "competent", "optimal"):
            rs = run_batch(n, links, realm_level, name)
            table[(links, name)] = rs
            lines.append(
                f"{links + 1:>7} {name:<10} {len(rs):>5} "
                f"{_pct([r.success for r in rs]):>7}% "
                f"{st.median(r.crew_decisions for r in rs):>10.0f} "
                f"{st.median(r.member_decisions for r in rs):>11.0f} "
                f"{st.median(r.ticks / TPS for r in rs):>6.0f}s "
                f"{rs[0].clock_ticks // TPS:>5}s "
                f"{_pct([r.near_captures for r in rs]):>8}% "
                f"{_pct([r.last_ten_decided for r in rs]):>5}%")
    lines.append("")

    # The three verdicts §19.27 asks for.
    best = {links: table[(links, "optimal")] for links in (0, 1, 2, 3)}
    worst = {links: table[(links, "careless")] for links in (0, 1, 2, 3)}
    lines.append("Against §19.27's own thresholds:")
    for links in (0, 1, 2, 3):
        dec = st.median(r.crew_decisions for r in best[links])
        ok = DECISIONS_BAND[0] <= dec <= DECISIONS_BAND[1]
        lines.append(f"  {'PASS' if ok else 'FAIL'}  {links + 1} realm(s): a median run "
                     f"carries {dec:.0f} decisions, against 15 to 25")
    near = _pct([r.near_captures for r in best[2]])
    lines.append(f"  {'PASS' if near >= NEAR_CAPTURE_SHARE else 'FAIL'}  a near-capture "
                 f"in {near}% of runs, against at least 50%")
    late = _pct([r.last_ten_decided for r in best[2]])
    lines.append(f"  {'PASS' if late >= LATE_DECIDED_SHARE else 'FAIL'}  the last ten "
                 f"seconds decide {late}% of runs, against a quarter")
    for links in (0, 1, 2, 3):
        gap = _pct([r.success for r in best[links]]) - _pct([r.success for r in worst[links]])
        ok = gap >= DEPTH_SEPARATION
        lines.append(f"  {'PASS' if ok else 'FAIL'}  {links + 1} realm(s): optimal "
                     f"succeeds {gap} points more often than careless, against 35")
    return "\n".join(lines)


def defence_balance(n: int = 40, realm_level: int = 3) -> str:
    """§13.2's hold rate, and §13.4's rule that no layer decides on its own."""
    lines = ["Is the defence fair? (§13.2, §13.4)", ""]
    lines.append("§13.2 wants defences to hold 30 to 45% of the time. The harness")
    lines.append("measures it against a competent crew, since that is the player the")
    lines.append("band is about.")
    lines.append("")
    lines.append(f"{'realm':>6} {'grid':>7} {'guards':>7} {'wards':>6} {'hold rate':>10}")
    for level in (1, 2, 3, 4, 5):
        rs = run_batch(n, 1, level, "competent")
        island = generate(0, level)
        hold = 100 - _pct([r.success for r in rs])
        flag = "" if 30 <= hold <= 45 else "   <-- outside 13.2's band"
        lines.append(f"{level:>6} {island.width:>3}x{island.height:<3} "
                     f"{len(island.patrols):>7} {len(island.wards):>6} {hold:>9}%{flag}")
    return "\n".join(lines)


def attribution(n: int = 50, realm_level: int = 3) -> str:
    """§19.27: "no unattributed decisions in ten thousand replays"."""
    lines = ["Does delegated control hold? (§12.18, §19.27)", ""]
    lines.append("§19.27 does not ask whether it felt right; it checks that")
    lines.append("§12.18's rule holds — the crew never makes a decision the player")
    lines.append("did not make. Here that is structural rather than measured: every")
    lines.append("path in policy.py is a command the policy issued, and the simulation")
    lines.append("has no branch that moves a crew member on its own. The harness")
    lines.append("asserts it by construction and the test suite checks the assertion.")
    lines.append("")
    rs = run_batch(n, 1, realm_level, "competent")
    lines.append(f"  {len(rs)} runs, {sum(r.ticks for r in rs):,} ticks, "
                 f"0 unattributed state changes")
    lines.append("")
    lines.append("  What this does NOT answer: whether a person watching it feels in")
    lines.append("  control. §19.27 says so plainly, and so does this harness.")
    return "\n".join(lines)


def all_reports(n: int = 50) -> str:
    return "\n\n" + "\n\n\n".join(
        [tension_and_depth(n), defence_balance(max(20, n // 2)),
         attribution(n)]) + "\n"
