"""§13.4's ablation, run as the section specifies it.

    python3 -m tools.heist_harness ablation
    python3 -m tools.heist_harness ablation 400     # §13.4's own sample size

§13.2 gives five defence layers target shares — Geometry 25%, Guards 20%, Wards
20%, Laws 20%, Response 15% — and one rule above them: **no single layer above
25%**, because "if one layer decides outcomes, the other four are decoration".

§13.4 then says exactly how to measure it, and is worth quoting because it is the
most precisely specified test in the document:

    "Run the same thousand raids against the island with that layer switched
     off, and see how much the hold rate falls. Do it for every combination of
     the five layers — there are only thirty-two — and divide the credit the way
     cooperative game theory does."

Dividing credit that way means the Shapley value, which is the unique attribution
satisfying the properties you would want: every layer's shares sum to the whole,
a layer that never changes an outcome gets nothing, and two layers that always
act identically get the same share. It is implemented below in full rather than
approximated, because with five players there are only 120 orderings.

What the shares are *of*
------------------------
The hold rate above the bare island. v(∅) is a realm with walls, a Vault and
nothing else — the island §13.3 promises never exists — and v(all) is the
generated defence. Each layer's share is its part of the distance between them,
which is the only reading under which the five shares sum to 100%.
"""

import itertools
import math
import statistics as st

from .island import ALL_LAYERS, LAYERS, generate
from .laws import Sheet, weave
from .policy import POLICIES
from .sim import Heist

#: §13.2's targets, and the ceiling that matters more than any of them.
TARGET_SHARE = {"geometry": 25, "guards": 20, "wards": 20, "laws": 20, "response": 15}
LAYER_CEILING = 25
HOLD_BAND = (30, 45)


def hold_rate(subset: frozenset, n: int, realm_level: int, seed0: int = 0,
              policy: str = "competent", law_mode: str = "defensive",
              response_model: str = "published",
              clock_pct: int = 100, exposed_pct: int = 100) -> float:
    """The share of raids this combination of layers turns back."""
    cls = POLICIES[policy]
    held = 0
    for i in range(n):
        seed = seed0 + i
        island = generate(seed, realm_level, layers=subset)
        sheet = (weave(seed, realm_level, favour_defender=law_mode == "defensive")
                 if "laws" in subset else Sheet())
        crossing = [generate(900_000 + seed * 8, realm_level, layers=subset)]
        result = Heist(island, cls(), realm_level=realm_level, crossing=crossing,
                       sheet=sheet, response="response" in subset,
                       response_model=response_model,
                       clock_pct=clock_pct, exposed_pct=exposed_pct).run()
        held += not result.success
    return 100 * held / n


#: §9.6's grade multiplier. Haul = B(V) × grade × difficulty × richness ×
#: fatigue × fill, so what a defence actually denies a raider is the product of
#: the two terms a defence can move: the grade and the fill.
GRADE_VALUE = {"clean": 1.0, "loud": 0.7, "partial": 0.4, "foiled": 0.0}


def haul_denied(subset: frozenset, n: int, realm_level: int, seed0: int = 0,
                policy: str = "competent", law_mode: str = "defensive",
                response_model: str = "published",
                baseline: float | None = None,
                clock_pct: int = 100, exposed_pct: int = 100) -> float:
    """The share of the raider's potential haul this combination of layers denies.

    §13.4 specifies the ablation against the **hold rate**, and that metric cannot
    see most of what a defence does. §12.9 grades a raid clean, loud, partial or
    foiled and §9.6 multiplies the haul by 1.0, 0.7, 0.4 and 0. A defence that
    turns every clean run on an island into a partial one takes 60% of the
    raider's income and scores **zero** on the hold rate, because none of those
    raids was turned back.

    So this is the same ablation against what §9.6 actually pays: the mean of
    grade × fill, expressed as the share denied against a bare island. Recorded
    as a finding in its own right; see docs/design/spec/response.md.
    """
    cls = POLICIES[policy]
    total = 0.0
    for i in range(n):
        seed = seed0 + i
        island = generate(seed, realm_level, layers=subset)
        sheet = (weave(seed, realm_level, favour_defender=law_mode == "defensive")
                 if "laws" in subset else Sheet())
        crossing = [generate(900_000 + seed * 8, realm_level, layers=subset)]
        r = Heist(island, cls(), realm_level=realm_level, crossing=crossing,
                  sheet=sheet, response="response" in subset,
                  response_model=response_model,
                  clock_pct=clock_pct, exposed_pct=exposed_pct).run()
        total += GRADE_VALUE[r.grade] * r.fill / 100
    mean = total / n
    if baseline is None:
        return mean
    return 100 * (1 - mean / baseline) if baseline else 0.0


def shapley(values: dict) -> dict:
    """Each layer's Shapley value, over the 2^5 coalition values in `values`.

    phi_i = sum over subsets S without i of
            |S|!(n-|S|-1)!/n! * (v(S + i) - v(S))
    """
    n = len(LAYERS)
    out = {}
    for layer in LAYERS:
        others = [x for x in LAYERS if x != layer]
        total = 0.0
        for size in range(n):
            weight = math.factorial(size) * math.factorial(n - size - 1) / math.factorial(n)
            for combo in itertools.combinations(others, size):
                s = frozenset(combo)
                total += weight * (values[s | {layer}] - values[s])
        out[layer] = total
    return out


def report(n: int = 60, realm_level: int = 3,
           response_model: str = "published", metric: str = "hold") -> str:
    lines = ["§13.4's ablation: what each defence layer is worth", ""]
    lines.append("§13.2 sets five target shares and one rule above them — no")
    lines.append("layer above 25%, “if one layer decides outcomes, the other four")
    lines.append("are decoration”. §13.4 says to measure it across all 32")
    lines.append("combinations and divide the credit by Shapley value. Both are done here.")
    lines.append("")

    values = {}
    for size in range(len(LAYERS) + 1):
        for combo in itertools.combinations(LAYERS, size):
            values[frozenset(combo)] = hold_rate(
                frozenset(combo), n, realm_level, response_model=response_model)
    if metric == "haul":
        # The same coalitions, valued by what §9.6 pays instead of by §13.4's
        # hold rate. See `haul_denied` for why that is a different question.
        raw = {}
        for size in range(len(LAYERS) + 1):
            for combo in itertools.combinations(LAYERS, size):
                raw[frozenset(combo)] = haul_denied(
                    frozenset(combo), n, realm_level, response_model=response_model)
        bare_haul = raw[frozenset()]
        values = {k: 100 * (1 - m / bare_haul) if bare_haul else 0.0
                  for k, m in raw.items()}

    bare = values[frozenset()]
    full = values[ALL_LAYERS]
    unit = "held" if metric == "hold" else "of the haul denied"
    lines.append(f"  bare island (no layers at all)   {bare:>5.1f}% {unit}")
    lines.append(f"  the generated defence            {full:>5.1f}% {unit}"
                 + (f"   §13.2 wants {HOLD_BAND[0]}–{HOLD_BAND[1]}%"
                    if metric == "hold" else ""))
    lines.append("")

    phi = shapley(values)
    span = full - bare
    lines.append(f"  {'layer':<10} {'target':>7} {'measured':>9} {'points':>8}   verdict")
    for layer in LAYERS:
        share = 100 * phi[layer] / span if span else 0.0
        if abs(span) < 1:
            verdict = "no span to divide"
        elif share > LAYER_CEILING:
            verdict = f"over §13.2's {LAYER_CEILING}% ceiling"
        elif share < 0:
            verdict = "negative — it helps the raider"
        elif share < 5:
            verdict = "decoration"
        else:
            verdict = ""
        lines.append(f"  {layer:<10} {TARGET_SHARE[layer]:>6}% {share:>8.1f}% "
                     f"{phi[layer]:>7.1f}   {verdict}")
    lines.append("")
    lines.append(f"  Shares sum to {sum(100 * v / span for v in phi.values()) if span else 0:.0f}%"
                 " by construction; the Shapley value is the attribution that")
    lines.append("  makes that true, which is why §13.4 asks for it.")
    lines.append("")

    # Single-layer holds: the crudest reading, and the one a reader expects.
    lines.append("  Each layer alone, against the bare island:")
    for layer in LAYERS:
        lines.append(f"    {layer:<10} {values[frozenset({layer})]:>5.1f}% {unit}  "
                     f"({values[frozenset({layer})] - bare:+.1f} points)")
    lines.append("")
    lines.append(f"  {len(values)} combinations × {n} raids = {len(values) * n:,} runs.")
    lines.append(f"  §13.4 asks for 400 each — {len(values) * 400:,} runs — and says a")
    lines.append("  deterministic simulation does it in seconds. This one is Python and")
    lines.append("  takes about twenty minutes at that size; pass a count to widen it.")
    return "\n".join(lines)
