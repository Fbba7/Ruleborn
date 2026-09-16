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
              policy: str = "competent", law_mode: str = "defensive") -> float:
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
                       sheet=sheet, response="response" in subset).run()
        held += not result.success
    return 100 * held / n


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


def report(n: int = 60, realm_level: int = 3) -> str:
    lines = ["§13.4's ablation: what each defence layer is worth", ""]
    lines.append("§13.2 sets five target shares and one rule above them — no")
    lines.append("layer above 25%, “if one layer decides outcomes, the other four")
    lines.append("are decoration”. §13.4 says to measure it across all 32")
    lines.append("combinations and divide the credit by Shapley value. Both are done here.")
    lines.append("")

    values = {}
    for size in range(len(LAYERS) + 1):
        for combo in itertools.combinations(LAYERS, size):
            values[frozenset(combo)] = hold_rate(frozenset(combo), n, realm_level)

    bare = values[frozenset()]
    full = values[ALL_LAYERS]
    lines.append(f"  bare island (no layers at all)   {bare:>5.1f}% held")
    lines.append(f"  the generated defence            {full:>5.1f}% held"
                 f"   §13.2 wants {HOLD_BAND[0]}–{HOLD_BAND[1]}%")
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
        lines.append(f"    {layer:<10} {values[frozenset({layer})]:>5.1f}% held  "
                     f"({values[frozenset({layer})] - bare:+.1f} points)")
    lines.append("")
    lines.append(f"  {len(values)} combinations × {n} raids = {len(values) * n:,} runs.")
    lines.append(f"  §13.4 asks for 400 each — {len(values) * 400:,} runs — and says a")
    lines.append("  deterministic simulation does it in seconds. This one is Python and")
    lines.append("  takes about twenty minutes at that size; pass a count to widen it.")
    return "\n".join(lines)
