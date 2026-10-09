"""Islands to raid, generated from a seed.

§13.3 in v3.0 makes generated defences the default rather than the fallback:
"Every player has a defence from the first minute — generated from their realm,
their laws and their ruleborn — legal, coherent, and never empty." So a generator
is no longer a harness convenience; it is the shipping feature, and this is a
first sketch of what it has to guarantee.

Two rules it must not break:

  * §6.1's route rule — the last path to the Heart can never be sealed.
  * §13.4's layer limits — a realm at level L holds 3+L wards and 1..3 posts.

Both are asserted, not hoped for: `Island.check()` raises rather than returning
a malformed island, because an island the generator can produce is an island a
player will be given.
"""

import pathlib
from dataclasses import dataclass, field

from .fixed import U, Rng, tiles

#: §6.2 and §6.1. `blocks_sight` is what makes a cone bend; `hides` is cover.
TERRAIN = {
    "floor":  dict(walkable=True,  blocks_sight=False, hides=False),
    "wall":   dict(walkable=False, blocks_sight=True,  hides=False),
    "hedge":  dict(walkable=False, blocks_sight=True,  hides=False),
    "grass":  dict(walkable=True,  blocks_sight=False, hides=True),
    "vault":  dict(walkable=False, blocks_sight=True,  hides=False),
}


@dataclass
class Patrol:
    """A guard's route, as tile waypoints it walks between and back.

    `level` is §10.2's Guardian Post level, 1 to 5. §10.2 sells each level as
    "guard +10% health and sight"; only the sight half is modelled, because the
    harness has no guard health — a crew never wins a fight by attrition here.

    The baseline is ambiguous in the document: §10.2 gives level 1 as "+10%"
    without saying what it is 10% above, and guards exist only at posts. This
    reads level 1 as the baseline, so the multiplier is 1 + 0.1 x (level - 1)
    and every measurement taken before post levels existed is unchanged.
    """
    role: str
    waypoints: list[tuple[int, int]]
    phase: int = 0
    level: int = 1


#: §10.3 (v3.3): each triggered ward's level-1 reset, and its sensor's reach.
#: Read from content/wards.json, the table's one home, rather than typed.
def _ward_table() -> tuple[dict, dict]:
    import json
    import re as _re
    rows = json.loads((pathlib.Path(__file__).resolve().parents[2] / "content"
                       / "wards.json").read_text(encoding="utf-8"))
    resets, reach = {}, {}
    for r in rows:
        m = _re.fullmatch(r"(\d+) s", r.get("resets_after", ""))
        if m:
            resets[r["name"]] = int(m.group(1))
        within = _re.search(r"within (\d+) tiles", r.get("sensor", ""))
        reach[r["name"]] = int(within.group(1)) if within else 0
    return resets, reach


from ..design_facts import DISARM_SECONDS                   # 10.3 (D37)
from ..design_facts import GUARD_POSTS, WARD_LIMITS          # 5.2 (D37)
RESET_SECONDS, REACH_TILES = _ward_table()

#: The triggered wards the generator places, cycled in this order. `generate`
#: takes another kit as `ward_kinds`: F33 is that which kinds are in it
#: matters more, under v3.3's sensor reach, than how many.
WARD_KINDS = ("Time Snare", "Gravity Well", "Lantern Glare")

#: Which document's wards and budgets an island is built to. "v3.3" is the
#: document and the default. "v3.2" is what every ward and budget number in
#: this register before D56's second pass was measured on — a ward fires on
#: its own tile only, disarms in 3 s + 1 s a level from beside it, resets in
#: 10 s less a second a level, §5.2 allows 3 + realm level of them and posts
#: 1, 1, 2, 2 and 3 guards — kept so those numbers stay reproducible, as
#: `crack_noise=False` keeps the layer numbers F32 would otherwise swamp.
#: F33 is the difference between the two. "v3.4" is v3.3's wards with brief
#: 37's two changes to the heist — the crack calls only guards within its
#: reach (§12.6), and a ward's sensor ignores the crew member disarming it
#: (§10.3) — and is now the default; "v3.3" keeps the whole-Heart call and
#: the literal G16 reading, so D57's, F33's and F34's numbers reproduce.
#: "v3.7" is v3.4 with §12.17's realm's watch, guards at realm levels 1 to 3
#: tuned so §5.2's budget lands in §13.2's band, and is now the default; "v3.4"
#: keeps full-strength guards at every level, so F55's numbers reproduce. The
#: budget itself is design_facts' at every version but v3.2's.
RULES = ("v3.2", "v3.3", "v3.4", "v3.7")


@dataclass
class Ward:
    """A ward on a tile (§10.3), with the level scaling §10.2 prices.

    Only the three *triggered* kinds are modelled, because they are the ones that
    create a route decision — which is what the harness counts. Crystal Wall and
    Thorn Hedge are already terrain here; Static Coil is an aura and changes no
    route. See docs/design/spec/wards.md.
    """
    kind: str
    x: int
    y: int
    level: int = 1
    spent: bool = False
    disarmed: bool = False
    reset_at: int = 0
    rules: str = "v3.7"
    #: G18's generous reading of brief 37: the sensor also ignores a crew
    #: member on its way to disarm it, not only while it stands disarming.
    #: The heist sets it (`Heist(disarm_approach=...)`); off is the literal
    #: text.
    approach: bool = False

    @property
    def disarm_ticks(self) -> int:
        """§10.3 (v3.3): fifteen seconds standing on the ward's tile, at every
        level. (v3.2: spec/wards.md's 3 s + 1 s a level, from beside it.)"""
        if self.rules == "v3.2":
            return (3 + self.level) * 30
        return DISARM_SECONDS * 30

    @property
    def reset_ticks(self) -> int:
        """§10.3 (v3.3): each ward's own level-1 reset — Gravity Well 10 s,
        Time Snare 12, Lantern Glare 20 — and "each level also takes a tenth
        of the level-1 reset off" (C32's reconciliation). (v3.2: §10.2's
        10 s at level 1, one second less a level.)"""
        if self.rules == "v3.2":
            return (11 - self.level) * 30
        base = RESET_SECONDS[self.kind] * 30
        return base * (11 - self.level) // 10

    @property
    def reach(self) -> int:
        """§10.3 (v3.3), the sensor: tiles from the ward's centre, 0 for its
        own tile. (v3.2: every ward, its own tile.)"""
        return 0 if self.rules == "v3.2" else REACH_TILES[self.kind]


@dataclass
class Island:
    width: int
    height: int
    tiles: list[list[str]]
    entry: tuple[int, int]
    vault: tuple[int, int]
    patrols: list[Patrol] = field(default_factory=list)
    wards: list = field(default_factory=list)
    #: When set, the ward count was overridden past §5.2's own limit on purpose,
    #: and `check()` measures against this instead. F26 asks what realm 1 would
    #: need to reach §13.2's band, and §5.2 already places its maximum there —
    #: four wards, no headroom — so the question cannot be asked inside the
    #: rule. An island built this way is a *counterfactual*, not a legal island,
    #: and any number measured from it says what §5.2 would have to allow.
    ward_budget: int | None = None
    seed: int = 0
    realm_level: int = 3
    rules: str = "v3.7"

    def at(self, x: int, y: int) -> str:
        if not (0 <= x < self.width and 0 <= y < self.height):
            return "wall"
        return self.tiles[y][x]

    def walkable(self, x: int, y: int) -> bool:
        return TERRAIN[self.at(x, y)]["walkable"]

    def blocks_sight(self, x: int, y: int) -> bool:
        return TERRAIN[self.at(x, y)]["blocks_sight"]

    def hides(self, x: int, y: int) -> bool:
        return TERRAIN[self.at(x, y)]["hides"]

    # -- guarantees --------------------------------------------------------

    def route_exists(self, start: tuple[int, int], goal: tuple[int, int]) -> bool:
        """Breadth-first, fixed neighbour order (§12.18). The Vault's own tile is
        not walkable, so reaching any tile adjacent to it counts."""
        seen = {start}
        frontier = [start]
        goals = {(goal[0] + dx, goal[1] + dy)
                 for dx in (-1, 0, 1) for dy in (-1, 0, 1)}
        while frontier:
            nxt = []
            for x, y in frontier:
                if (x, y) in goals:
                    return True
                for dx, dy in ((0, -1), (-1, 0), (1, 0), (0, 1)):
                    n = (x + dx, y + dy)
                    if n not in seen and self.walkable(*n):
                        seen.add(n)
                        nxt.append(n)
            frontier = nxt
        return False

    def check(self) -> None:
        if not self.route_exists(self.entry, self.vault):
            raise AssertionError(
                f"island {self.seed}: no route from the entry to the Vault — "
                "§6.1 forbids sealing the last path to the Heart")
        limit = self.ward_budget if self.ward_budget is not None else WARDS(self.realm_level, self.rules)
        if len(self.wards) > limit:
            raise AssertionError(
                f"island {self.seed}: {len(self.wards)} wards, "
                f"{'the override' if self.ward_budget is not None else '§5.2'} "
                f"allows {limit} at realm level {self.realm_level}")
        for p in self.patrols:
            if not 1 <= p.level <= 5:
                raise AssertionError(
                    f"island {self.seed}: Guardian Post level {p.level}, "
                    f"§10.2 gives levels 1 to 5")
        if self.patrols and not 1 <= len(self.patrols) <= 3:
            raise AssertionError(
                f"island {self.seed}: {len(self.patrols)} guard posts, §5.2 allows 1-3")
        for p in self.patrols:
            for wx, wy in p.waypoints:
                if not self.walkable(wx, wy):
                    raise AssertionError(
                        f"island {self.seed}: a {p.role} patrols through {self.at(wx, wy)}")


#: §5.2's guard posts by realm level: one, except two at level 3 (v3.7).
def POSTS(realm_level: int, rules: str = "v3.7") -> int:
    """§5.2's guard posts by realm level (v3.7: 1, 1, 2, 1 and 1)."""
    if rules == "v3.2":
        return 1 + (realm_level - 1) // 2
    return GUARD_POSTS[realm_level - 1]


def WARDS(realm_level: int, rules: str = "v3.7") -> int:
    """§5.2's ward limit by realm level (v3.7: 8, 8, 6, 2 and 0; v3.2: three
    plus the realm level)."""
    if rules == "v3.2":
        return 3 + realm_level
    return WARD_LIMITS[realm_level - 1]


#: §13.2's five layers, in the order it lists them. `laws` is applied by the
#: rule sheet and `response` by the simulation; the other three shape the island.
LAYERS = ("geometry", "guards", "wards", "laws", "response")
ALL_LAYERS = frozenset(LAYERS)


def generate(seed: int, realm_level: int = 3, layers=ALL_LAYERS,
             shaped: bool | int = False, posts: int | None = None,
             post_level: int = 1, wards: int | None = None,
             rules: str = "v3.7", ward_kinds: tuple | None = None) -> Island:
    """A small realm, laid out so a route exists and a guard can see it.

    §5.2 gives realm grids by level; level 3 is 12x12. The default layout is
    deliberately plain — a room with cover and two corridors — because the harness
    measures the decisions a heist offers, and an ornate island would measure the
    generator.

    `shaped=True` is the generator F16 argued for and F9 and F11 measured the
    need for, built from the three rules the register already named: put the
    Vault far from the entry along the *route* rather than in a straight line,
    keep one route long, and put cover off the path rather than on it. It is a
    separate mode rather than a replacement, deliberately — every published
    number in this register was measured on the plain layout, and silently
    moving the floor under them would make the comparison meaningless. The
    comparison is the finding.
    """
    rng = Rng(seed)
    w = h = {1: 10, 2: 11, 3: 12, 4: 13, 5: 14}[realm_level]
    grid = [["floor"] * w for _ in range(h)]
    for x in range(w):
        grid[0][x] = grid[h - 1][x] = "wall"
    for y in range(h):
        grid[y][0] = grid[y][w - 1] = "wall"

    vx, vy = w // 2, 2
    grid[vy][vx] = "vault"

    # Geometry (§13.2, 25%): "which routes exist, what can be seen from where".
    # With the layer off the realm is a bare room, which is the island §13.3
    # promises never happens and the right floor to measure the layer against.
    clumps = 0
    if "geometry" in layers:
        gap = 1 + rng.below(w - 3)
        if shaped:
            # One route, long. Bands with their gaps on alternating sides force
            # the crew to double back across the realm instead of walking up the
            # middle — §13.2's "which routes exist" doing actual work.
            #
            # `shaped` is how many of those bands to lay, not a switch. A realm
            # has very few discrete defence settings — the guard posts are
            # integers and there are one or two of them early — and with the
            # geometry as an on/off choice realm 1 can only reach 6%, 15%, 16%
            # or 51%, so §13.2's 30-45% band has no setting that lands in it.
            # A layer that cannot be tuned cannot be balanced.
            rows = _bands(h)
            if shaped is not True:
                rows = rows[:max(0, int(shaped))]
            for i, band in enumerate(rows):
                opening = 1 if i % 2 == 0 else w - 2
                for x in range(1, w - 1):
                    if x != opening:
                        grid[band][x] = "hedge"
        else:
            # Two interior hedges, leaving a gap, so there is more than one way through.
            band = h // 2
            for x in range(1, w - 1):
                if abs(x - gap) > 1:
                    grid[band][x] = "hedge"

        clumps = 3 + rng.below(3)
        cover = [(1 + rng.below(w - 2), 1 + rng.below(h - 2)) for _ in range(clumps)]
        if not shaped:
            # Cover: tall grass in clumps, never on the gap tile.
            for cx, cy in cover:
                for dx in range(2):
                    for dy in range(2):
                        x, y = cx + dx, cy + dy
                        if 0 < x < w - 1 and 0 < y < h - 1 and grid[y][x] == "floor" \
                                and (x, y) != (gap, band):
                            grid[y][x] = "grass"
    else:
        rng.below(w - 3)              # keep the stream aligned across variants
        cover = [(rng.below(w - 2), rng.below(h - 2)) for _ in range(3 + rng.below(3))]

    entry = (w // 2, h - 2)
    assert rules in RULES, rules
    island = Island(w, h, grid, entry, (vx, vy), seed=seed, realm_level=realm_level,
                    rules=rules)

    if shaped and "geometry" in layers:
        # Cover off the path. Tall grass hides the *raider* (§12.17), so a clump
        # that lands on the route is cover handed to the attacker — which is what
        # F16 found a good part of the old layer was. Placed only where it cannot
        # shelter anyone walking the route, it is cover for a detour instead.
        _cover_off_route(island, cover)

    # Wards (§5.2's budget). Placed on the route, because a ward beside the path
    # is scenery: §13.4's whole point is that a layer must contribute — but
    # never where its sensor reaches the entry. A crew picks its landing along
    # a whole edge (§5.4), so no Keeper can ward every landing, and one ward
    # covering the harness's single entry would decide every raid on it.
    from .sim import path_to                                        # local: cycle
    route = path_to(island, entry, (vx, vy))
    kinds = list(ward_kinds or WARD_KINDS)
    ward_level = 1 + (realm_level - 1) // 2
    # §5.2 sets the count. It must not depend on any other layer,
    # or an ablation measures the confound rather than the layer: an earlier
    # version derived it from the route length, so turning geometry off removed a
    # ward as well, and the geometry share absorbed the ward's.
    ward_count = (WARDS(realm_level, rules) if wards is None else wards) if "wards" in layers else 0
    if wards is not None:
        island.ward_budget = wards
    spots = _ward_spots(island, route, ward_count, kinds)
    for i, spot in enumerate(spots):
        island.wards.append(Ward(kinds[i % len(kinds)], spot[0], spot[1], ward_level,
                                 rules=rules))

    # One to three guards (§5.2), patrolling walkable loops. `posts` overrides
    # §5.2's own formula, so what that formula costs can be measured rather than
    # argued: it is the only defence layer whose count is fixed by realm level.
    roles = ["Warden", "Scout", "Breaker"]
    allowed = POSTS(realm_level, rules) if posts is None else posts
    count = allowed if "guards" in layers else 0
    for i in range(count):
        route = _patrol_route(island, rng, i)
        island.patrols.append(Patrol(roles[i % len(roles)], route,
                                     phase=rng.below(max(1, len(route) * 30)),
                                     level=post_level))

    island.check()
    return island


def _bands(h: int) -> list[int]:
    """The rows a shaped realm walls off, from the top of the map downward.

    Three on a realm tall enough to hold them, two otherwise, and never the row
    the Vault or the entry stands on.
    """
    rows = [h // 4, h // 2, (3 * h) // 4] if h >= 12 else [h // 3, (2 * h) // 3]
    return [r for r in rows if 2 < r < h - 2]


def _cover_off_route(island: Island, clumps) -> None:
    """Lay each clump of tall grass somewhere it cannot shelter the route.

    Moving a clump rather than dropping it matters. §13.3 promises a generated
    island is "never empty", and a realm with no cover at all is a different
    defect from one that hands its cover to the raider. So each clump slides to
    the nearest anchor whose whole footprint is clear of the route, and is only
    dropped if the realm genuinely has nowhere to put it.
    """
    from .sim import path_to                                        # local: cycle
    route = path_to(island, island.entry, island.vault) or []
    beside = {(x + dx, y + dy) for x, y in route
              for dx in (-1, 0, 1) for dy in (-1, 0, 1)}

    def clear(ax, ay) -> bool:
        for dx in range(2):
            for dy in range(2):
                x, y = ax + dx, ay + dy
                if (x, y) in beside or island.at(x, y) != "floor":
                    return False
        return True

    anchors = [(x, y) for y in range(1, island.height - 2)
               for x in range(1, island.width - 2) if clear(x, y)]
    for cx, cy in clumps:
        if not anchors:
            return
        ax, ay = min(anchors, key=lambda a: (abs(a[0] - cx) + abs(a[1] - cy), a))
        for dx in range(2):
            for dy in range(2):
                island.tiles[ay + dy][ax + dx] = "grass"
        anchors = [a for a in anchors if clear(*a)]


def _ward_spots(island: Island, route: list, count: int, kinds: list) -> list:
    """`count` distinct walkable tiles, on the route where it is long enough and
    beside it where it is not, so the count never varies with another layer —
    and none whose sensor would reach the entry (see `generate`)."""
    out, used = [], set()
    ex, ey = island.entry
    for i in range(count):
        reach = 0 if island.rules == "v3.2" else REACH_TILES[kinds[i % len(kinds)]]
        clear = lambda t, r=reach: (t[0] - ex) ** 2 + (t[1] - ey) ** 2 > r * r
        if route:
            spot = route[(1 + (i * len(route)) // max(1, count)) % len(route)]
        else:
            spot = island.entry
        if spot in used or spot in (island.entry, island.vault) or not clear(spot):
            spot = _free_tile_near(island, spot, used, clear)
        if spot is None:
            continue
        used.add(spot)
        out.append(spot)
    return out


def _free_tile_near(island: Island, origin, used: set, ok=lambda t: True):
    """The nearest unused walkable tile, searched in a fixed order."""
    for radius in range(1, max(island.width, island.height)):
        for dy in range(-radius, radius + 1):
            for dx in range(-radius, radius + 1):
                if max(abs(dx), abs(dy)) != radius:
                    continue
                tile = (origin[0] + dx, origin[1] + dy)
                if tile in used or tile in (island.entry, island.vault):
                    continue
                if island.walkable(*tile) and ok(tile):
                    return tile
    return None


def _patrol_route(island: Island, rng: Rng, index: int) -> list[tuple[int, int]]:
    """Two to four walkable waypoints, biased toward the half the guard owns."""
    w, h = island.width, island.height
    top = index % 2 == 0
    ys = range(1, island.height // 2) if top else range(island.height // 2 + 1, h - 1)
    options = [(x, y) for y in ys for x in range(1, w - 1) if island.walkable(x, y)]
    if len(options) < 2:
        options = [(x, y) for y in range(1, h - 1) for x in range(1, w - 1)
                   if island.walkable(x, y)]
    route, used = [], set()
    for _ in range(2 + rng.below(3)):
        for _attempt in range(8):
            p = rng.choice(options)
            if p not in used:
                used.add(p)
                route.append(p)
                break
    return route if len(route) >= 2 else options[:2]
