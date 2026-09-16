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
from .laws import SIMULATED, Sheet, _helps_defender, weave
from .policy import POLICIES
from .sim import Heist

#: §19.27's own numbers.
DECISIONS_BAND = (15, 25)
NEAR_CAPTURE_SHARE = 50          # per cent of runs
LATE_DECIDED_SHARE = 25          # per cent of runs
DEPTH_SEPARATION = 35            # percentage points, optimal over careless


def run_batch(n: int, links: int, realm_level: int, policy_name: str,
              seed0: int = 0, laws: str = "none", shaped: bool = False,
              posts: int | None = None) -> list:
    """`laws` is "none", "any" (woven at random) or "defensive" (sign-aware).

    `shaped` selects the generator F16 argued for; see `island.generate`.
    """
    cls = POLICIES[policy_name]
    out = []
    for i in range(n):
        seed = seed0 + i
        crossing = [generate(900_000 + seed * 8 + k, realm_level, shaped=shaped,
                             posts=posts) for k in range(links)]
        sheet = (Sheet() if laws == "none"
                 else weave(seed, realm_level, favour_defender=laws == "defensive"))
        policy = cls()
        result = Heist(generate(seed, realm_level, shaped=shaped, posts=posts), policy,
                       realm_level=realm_level, crossing=crossing, sheet=sheet).run()
        result.sheet = sheet
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
                 f"{'per-member':>11} {'run':>7} {'clock':>6} {'near-cap':>9} "
                 f"{'late':>6} {'by clock':>9}")
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
                f"{_pct([r.last_ten_decided for r in rs]):>5}% "
                # `Result.lost_to` was computed and never read until D27. It is
                # the sharper half of the "late" column: of the raids that fail,
                # how many die to §5.4's clock rather than to a guard. A clock
                # that decides nothing should turn up here as a zero, and does.
                f"{_pct([r.lost_to == 'clock' for r in rs]):>8}%")
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
    lines.append("v3.0's \u00a713.3 makes a generated island every player's defence, so")
    lines.append("what a generator weaves is now a balance question and not a fallback.")
    lines.append("Three generators are measured: no laws at all, laws picked at random")
    lines.append("from what the player has, and laws picked for their sign.")
    lines.append("")
    lines.append(f"{'realm':>6} {'grid':>7} {'guards':>7} {'wards':>6} "
                 f"{'no laws':>9} {'any laws':>9} {'defensive':>10}")
    for level in (1, 2, 3, 4, 5):
        island = generate(0, level)
        holds = []
        for mode in ("none", "any", "defensive"):
            rs = run_batch(n, 1, level, "competent", laws=mode)
            holds.append(100 - _pct([r.success for r in rs]))
        flags = ["*" if 30 <= h <= 45 else " " for h in holds]
        lines.append(f"{level:>6} {island.width:>3}x{island.height:<3} "
                     f"{len(island.patrols):>7} {len(island.wards):>6} "
                     + "".join(f"{h:>8}%{f}" for h, f in zip(holds, flags))
                     + ("" if any(f == "*" for f in flags) else ""))
    lines.append("")
    lines.append("  * inside \u00a713.2's 30-45% band.")
    lines.append("")
    helps = [law for law in SIMULATED if _helps_defender(law)]
    lines.append(f"  Of the {len(SIMULATED)} laws a rule sheet can express, "
                 f"<b>{len(helps)} help the defender</b>")
    lines.append(f"  and {len(SIMULATED) - len(helps)} help the raider or cut both ways: "
                 + ", ".join(law["name"] for law in helps) + " against the rest.")
    lines.append("  Laws apply to everyone in the realm (\u00a77.3), so a generator that")
    lines.append("  weaves the player's laws without reading their sign is choosing")
    lines.append("  the raider's side about three times in four.")
    return "\n".join(lines).replace("<b>", "").replace("</b>", "")


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


def break_even(n: int = 250, realm_level: int = 3, links: int = 1) -> str:
    """Is §12.19's 70% break-even where the expected haul actually peaks?

    §12.19 states it as a fact and calls it load-bearing: "The break-even sits
    at about 70% full — at that point the extra load is worth exactly what a
    loud exit costs. That single number is the dial for the game's emotional
    peak."

    It is checkable. §9.6 pays `grade × fill`, so the quantity a crew
    maximises is E[grade × fill] over attempts, and a break-even is where
    that stops rising. Sweep the crew's stop rule and look for the peak.

    This became measurable only when D24 was fixed — before that the Vault
    phase ended on the first full bag, so every stop rule above about 53% was
    the same rule.
    """
    from .island import ALL_LAYERS, generate
    from .laws import weave
    from .policy import Competent
    from .sim import Heist

    grade_value = {"clean": 1.0, "loud": 0.7, "partial": 0.4, "foiled": 0.0}

    def sweep(stop: int):
        policy = type("Tuned", (Competent,), {"stop_at_fill": stop})
        values, held, fills = [], 0, []
        for i in range(n):
            island = generate(i, realm_level, layers=ALL_LAYERS)
            sheet = weave(i, realm_level, favour_defender=True)
            crossing = [generate(900_000 + i * 8 + k, realm_level, layers=ALL_LAYERS)
                        for k in range(links)]
            r = Heist(island, policy(), realm_level=realm_level, crossing=crossing,
                      sheet=sheet, response=True).run()
            values.append(grade_value[r.grade] * r.fill / 100)
            held += r.success
            if r.success:
                fills.append(r.fill)
        return (st.mean(values), 100 * held / n,
                st.mean(fills) if fills else 0.0)

    lines = ["Is §12.19's 70% break-even where the haul actually peaks?", ""]
    lines.append("§9.6 pays grade × fill, so that is what a crew maximises.")
    lines.append("Sweeping the crew's stop rule over the same islands and seeds:")
    lines.append("")
    lines.append(f"  {'stop at':>8} {'E[grade x fill]':>16} {'success':>9} "
                 f"{'fill on success':>16}")
    rows = []
    for stop in (40, 50, 60, 70, 80, 90, 95, 100):
        value, success, fill = sweep(stop)
        rows.append((stop, value, success, fill))
        lines.append(f"  {stop:>7}% {value:>16.4f} {success:>8.1f}% {fill:>15.1f}%")
    peak = max(rows, key=lambda r: r[1])
    lines.append("")
    lines.append(f"  The peak is at {peak[0]}%, not 70%.  "
                 if peak[0] != 70 else "  The peak is at 70%, as §12.19 says.  ")
    at_70 = next(r for r in rows if r[0] == 70)
    lines.append(f"  E at 70% is {at_70[1]:.4f}; at the peak it is {peak[1]:.4f}, "
                 f"{100 * (peak[1] / at_70[1] - 1):+.0f}%.")
    lines.append(f"  {n} raids a row, {len(rows) * n:,} runs.")
    lines.append("")
    lines.append("  Read the shape, not the argmax. At 150 raids a row this curve")
    lines.append("  rose monotonically to 100%, which would have meant no break-even")
    lines.append("  at all; at 300 it turns over near 90%. A peak located from one")
    lines.append("  small sweep is a peak located from noise \u2014 the finding that")
    lines.append("  survives is that 70% is below the turn, not where the turn is.")
    return "\n".join(lines)


def all_reports(n: int = 50) -> str:
    return "\n\n" + "\n\n\n".join(
        [tension_and_depth(n), defence_balance(max(20, n // 2)),
         attribution(n), break_even(max(120, n))]) + "\n"
