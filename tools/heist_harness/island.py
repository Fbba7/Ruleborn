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
    """A guard's route, as tile waypoints it walks between and back."""
    role: str
    waypoints: list[tuple[int, int]]
    phase: int = 0


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

    @property
    def disarm_ticks(self) -> int:
        """§12.5 implies a disarm action; spec/wards.md specifies 3 s + 1 s a level."""
        return (3 + self.level) * 30

    @property
    def reset_ticks(self) -> int:
        """§10.2: 10 s at level 1, one second less a level."""
        return (11 - self.level) * 30


@dataclass
class Island:
    width: int
    height: int
    tiles: list[list[str]]
    entry: tuple[int, int]
    vault: tuple[int, int]
    patrols: list[Patrol] = field(default_factory=list)
    wards: list = field(default_factory=list)
    seed: int = 0
    realm_level: int = 3

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
        limit = 3 + self.realm_level
        if len(self.wards) > limit:
            raise AssertionError(
                f"island {self.seed}: {len(self.wards)} wards, §5.2 allows {limit} "
                f"at realm level {self.realm_level}")
        if not 1 <= len(self.patrols) <= 3:
            raise AssertionError(
                f"island {self.seed}: {len(self.patrols)} guard posts, §5.2 allows 1-3")
        for p in self.patrols:
            for wx, wy in p.waypoints:
                if not self.walkable(wx, wy):
                    raise AssertionError(
                        f"island {self.seed}: a {p.role} patrols through {self.at(wx, wy)}")


def generate(seed: int, realm_level: int = 3) -> Island:
    """A small realm, laid out so a route exists and a guard can see it.

    §5.2 gives realm grids by level; level 3 is 12x12. The layout is deliberately
    plain — a room with cover and two corridors — because the harness measures the
    decisions a heist offers, and an ornate island would measure the generator.
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

    # Two interior hedges, leaving a gap, so there is more than one way through.
    band = h // 2
    gap = 1 + rng.below(w - 3)
    for x in range(1, w - 1):
        if abs(x - gap) > 1:
            grid[band][x] = "hedge"

    # Cover: tall grass in clumps, never on the gap tile.
    for _ in range(3 + rng.below(3)):
        cx, cy = 1 + rng.below(w - 2), 1 + rng.below(h - 2)
        for dx in range(2):
            for dy in range(2):
                x, y = cx + dx, cy + dy
                if 0 < x < w - 1 and 0 < y < h - 1 and grid[y][x] == "floor" \
                        and (x, y) != (gap, band):
                    grid[y][x] = "grass"

    entry = (w // 2, h - 2)
    island = Island(w, h, grid, entry, (vx, vy), seed=seed, realm_level=realm_level)

    # Wards (§5.2: 3 + realm level). Placed on the route, because a ward beside
    # the path is scenery: §13.4's whole point is that a layer must contribute.
    from .sim import path_to                                        # local: cycle
    route = path_to(island, entry, (vx, vy))
    kinds = ["Time Snare", "Gravity Well", "Lantern Glare"]
    ward_level = 1 + (realm_level - 1) // 2
    for i in range(min(3 + realm_level, max(0, len(route) - 2))):
        spot = route[1 + (i * len(route)) // (3 + realm_level)]
        if any((wd.x, wd.y) == spot for wd in island.wards):
            continue
        island.wards.append(Ward(kinds[i % len(kinds)], spot[0], spot[1], ward_level))

    # One to three guards (§5.2), patrolling walkable loops.
    roles = ["Warden", "Scout", "Breaker"]
    count = 1 + (realm_level - 1) // 2
    for i in range(count):
        route = _patrol_route(island, rng, i)
        island.patrols.append(Patrol(roles[i % len(roles)], route,
                                     phase=rng.below(max(1, len(route) * 30))))

    island.check()
    return island


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
