"""One island designed by hand, to test F16's own caveat.

F16 records that geometry measures about 5% of a generated defence against
§13.2's 25% target, and says the thing that matters about it:

    "this measures *generated* geometry, not designed geometry. §13.2's 25% is a
     claim about an island someone thought about."

Nobody had tested the designed case, so the finding could not distinguish "the
design's claim about geometry is wrong" from "the generator is bad at geometry".
This module supplies the missing half: an island laid out deliberately, against
the same harness, the same guards, the same wards and the same ablation.

What the generator does, and why it is weak
-------------------------------------------
`generate` lays down one hedge band with a gap in it, then scatters three to
five 2x2 clumps of tall grass. Tall grass **hides the raider** (§12.17), and the
clumps land anywhere — including on the route. So a good part of what the
generator calls geometry is cover it hands to the attacker, which is how the
layer measures near zero and once measured negative.

What this island does instead, following §13.2's own list — "where the Vault
sits, which routes exist, what can be seen from where":

  * **The Vault sits in the middle of a spiral**, not across an open room.
  * **One way in.** Column 8 is the only corridor from the entry to the inner
    ring; the outer ring is a decoy loop that leads nowhere near the Vault.
  * **The route switchbacks** — up, left, down, right, up — so a crew crosses
    the same guard's cone more than once.
  * **No cover on the route.** The grass is in the decoy ring only, where it
    rewards a raider for going the wrong way.

Nothing here is beyond a player with §6.1's terrain points: it is walls, hedge
and grass on a 12x12 grid, which is what §13.2 means by free and unlimited.
"""

from .fixed import Rng
from .island import Island, Patrol, Ward

#: 12x12 is §5.2's grid for a realm at level 3, the level the harness measures.
#: `V` is the Vault, `E` the entry, `#` wall, `%` hedge, `,` tall grass.
MAP = [
    "############",
    "#,,,,,,,,,,#",
    "#,########,#",
    "#.#......#,#",
    "#.#.####.#,#",
    "#.#.#V.#.#,#",
    "#.#.#..#.#,#",
    "#.#.##.#.#,#",
    "#.#....#.#,#",
    "#.######.#,#",
    "#.......E..#",
    "############",
]

GLYPH = {"#": "wall", "%": "hedge", ",": "grass", ".": "floor",
         "V": "vault", "E": "floor"}


def _grid(geometry: bool) -> tuple:
    """The designed layout, or the bare room that is its geometry-off twin.

    The twin keeps the Vault and the entry exactly where they are and removes
    everything else, which is the same floor `generate` ablates against: §13.4
    measures a layer by what its absence costs, so the two islands must differ
    in nothing but the layer.
    """
    width, height = len(MAP[0]), len(MAP)
    vault = entry = None
    grid = []
    for y, row in enumerate(MAP):
        assert len(row) == width, f"row {y} is {len(row)} wide, not {width}"
        out = []
        for x, ch in enumerate(row):
            if ch == "V":
                vault = (x, y)
            elif ch == "E":
                entry = (x, y)
            edge = x in (0, width - 1) or y in (0, height - 1)
            if ch == "V":
                out.append("vault")
            elif geometry or edge:
                out.append(GLYPH[ch])
            else:
                out.append("floor")
        grid.append(out)
    assert vault and entry, "the map needs a V and an E"
    return grid, entry, vault


#: Two guards, which is what `generate` places at realm level 3. Their routes are
#: chosen the way a defender would choose them — on the one corridor in, and on
#: the inner approach — rather than at random. Both loops stay walkable in the
#: bare room as well, so the guards layer does not change when geometry does.
PATROLS = (
    ("Warden", ((8, 9), (8, 6), (8, 3), (8, 6))),
    ("Scout", ((3, 3), (3, 8), (6, 8), (3, 8))),
)

#: Six wards, §5.2's allowance at realm level 3, on the designed route.
WARD_SPOTS = ((8, 8), (8, 4), (6, 3), (3, 5), (4, 8), (6, 6))
WARD_KINDS = ("Time Snare", "Gravity Well", "Lantern Glare")


def designed(seed: int = 0, realm_level: int = 3, layers=frozenset(),
             rules: str = "v3.4") -> Island:
    """The hand-built island, ablated the same way `generate` is.

    The layout does not vary with the seed — there is one designed island, and
    that is the point of it. What the seed varies is **where the guards are when
    the crew arrives**, which is what actually differs between two raids on a
    real defender's island: the map is fixed and the patrol is not.

    Without that this measures nothing. The first version ignored the seed
    entirely, so every run in a batch was the same run, every coalition value was
    0 or 100, and the Shapley shares came out as the signature of a degenerate
    game — geometry 0.0%, and three layers on exactly 33.3%.
    """
    grid, entry, vault = _grid("geometry" in layers)
    island = Island(len(grid[0]), len(grid), grid, entry, vault,
                    seed=seed, realm_level=realm_level, rules=rules)

    if "wards" in layers:
        level = 1 + (realm_level - 1) // 2
        for i, (x, y) in enumerate(WARD_SPOTS):
            island.wards.append(Ward(WARD_KINDS[i % len(WARD_KINDS)], x, y, level,
                                     rules=rules))

    if "guards" in layers:
        rng = Rng(seed)
        for role, route in PATROLS:
            waypoints = [tuple(p) for p in route]
            # §12.17's guards are somewhere on their loop when a raid starts.
            island.patrols.append(
                Patrol(role, waypoints, phase=rng.below(max(1, len(waypoints) * 30))))

    island.check()
    return island
