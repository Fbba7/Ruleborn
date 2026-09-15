"""Three scripted crews: careless, competent, optimal (§19.27).

The point of three is comparison. §19.27's depth test is that skill separates
outcomes — "a game with depth separates them; a game without does not" — so these
differ only in the things the design says matter (timing, routes, greed) and in
nothing else. All three share the pathfinder, the speeds and the island.

How a crew plays, and why it is not a re-planner
------------------------------------------------
An earlier version re-planned the route whenever a cone crossed the next step.
It produced 130 "decisions" a run, and every one of them was the pathfinder
reacting to a guard turning its head. That is not what §12.6 describes.

§12.5 has the player plan a route *before* the heist, from a scout report. §12.6
then lists what is decided *during* it: "Take or skip forks; break a pylon or
not; when to use abilities and casts; whether to split", then "who cracks, who
loads, when to stop loading", then "where to call the skiff; whether to drop
loot". Every one is a discrete event at a place, not a continuous adjustment.

So a crew here holds a planned route and decides at **checkpoints**: the forks
and cover tiles along it, plus the Vault and the exit. That is the model the
document describes, and it is the only one under which the decision count means
what §12.6 says it means.

Counting decisions
------------------
    A decision is a point where the crew's commitment changed and more than one
    option was open.

Both halves matter, and the first does most of the work. Walking on past the
fifth checkpoint in a row is not five decisions — the crew is doing what it was
already doing. What counts is a **switch**: pushing where it was holding, going
around where it was pushing through, stopping where it was loading, leaving where
it was staying. Those are exactly the choices §12.6 lists, and nothing else is
counted.

Commitments are kept per member and per kind, so a route change and a loading
choice do not overwrite each other and get double-counted. The report prints
per-member as well as crew-level counts, because a number that moves with the
definition should never be quoted alone.
"""

from .detect import (ALERTED, INVESTIGATING, SUSPICIOUS, line_of_sight, zone)
from .fixed import TPS, U
from .sim import BREAKEVEN_FILL, LOAD_PER_SECOND, WIND_UP_TICKS, path_to

ROLE_POWER = {"Scout": 12, "Breaker": 40, "Carrier": 8, "Warden": 20, "Mender": 6}

#: A checkpoint every this many tiles of route, plus every fork. §12.6 wants a
#: decision every 8-12 seconds; a crouched crew covers about 2 tiles a second.
CHECKPOINT_EVERY = 3


class Policy:
    name = "base"
    crouches = True
    #: Whether the crew looks at cones at all when routing.
    routes_around_cones = True
    #: Whether it will hold at a checkpoint for a cone to sweep past.
    holds_at_checkpoints = False
    #: The fill at which it stops loading. §12.19's break-even is 70.
    stop_at_fill = BREAKEVEN_FILL
    #: The suspicion at which it abandons the run. None never leaves early.
    flees_at: int | None = ALERTED
    #: What it does about a live ward on the next step: "through", "around",
    #: or "disarm". This is §12.6's "take or skip forks; break a pylon or not"
    #: and the crossover priced in docs/design/spec/wards.md.
    ward_answer = "through"

    def __init__(self) -> None:
        self.crew_decisions = 0
        self.member_decisions = 0
        self.crew_last = -10 ** 9
        self.commitment: dict[int, tuple] = {}
        self.planned = False
        self.checkpoints: dict[int, set] = {}
        self._memo_tick, self._memo = -1, {}

    # -- decisions ---------------------------------------------------------

    def _decide(self, heist, who, what: tuple, options: int) -> int:
        """`who` is (member index, kind) so kinds do not overwrite each other."""
        previous = self.commitment.get(who)
        self.commitment[who] = what
        if previous == what or options < 2:
            return 0
        self.member_decisions += 1
        if heist.tick - self.crew_last < TPS:
            return 0
        self.crew_last = heist.tick
        self.crew_decisions += 1
        return 1

    # -- sight -------------------------------------------------------------

    def _threatened(self, heist, tile) -> bool:
        """Whether a tile is inside a cone that can actually reach it."""
        if self._memo_tick != heist.tick:
            self._memo_tick, self._memo = heist.tick, {}
        hit = self._memo.get(tile)
        if hit is not None:
            return hit
        island = heist.island
        out = False
        if not island.hides(*tile):
            tx, ty = tile[0] * U + U // 2, tile[1] * U + U // 2
            out = any(zone(g.role, g.x, g.y, g.facing, tx, ty)
                      and line_of_sight(island, g.x, g.y, tx, ty)
                      for g in heist.guards)
        self._memo[tile] = out
        return out

    # -- routing -----------------------------------------------------------

    def _live_ward(self, heist, tile):
        for w in heist.island.wards:
            if (w.x, w.y) == tile and not w.spent and not w.disarmed:
                return w
        return None

    def _plan(self, heist, m, goal) -> None:
        """One route, planned once per leg, and the checkpoints along it.

        The cones are read at planning time only — which is what a scout report
        gives you (§12.3) and what a player actually has.
        """
        tile = (m.x // U, m.y // U)
        def avoid_tile(t) -> bool:
            if self.ward_answer == "around" and self._live_ward(heist, t):
                return True
            return self.routes_around_cones and self._threatened(heist, t)

        avoid = avoid_tile if (self.routes_around_cones
                               or self.ward_answer == "around") else None
        m.path = path_to(heist.island, tile, goal, avoid=avoid,
                         exact=goal == heist.island.entry)
        marks = set()
        for i, step in enumerate(m.path):
            if i % CHECKPOINT_EVERY == 0 or self._options(heist.island, step) > 2:
                marks.add(step)
        self.checkpoints[id(m)] = marks

    def _options(self, island, tile) -> int:
        return sum(1 for dx, dy in ((0, -1), (-1, 0), (1, 0), (0, 1))
                   if island.walkable(tile[0] + dx, tile[1] + dy))

    # -- the tick ----------------------------------------------------------

    def act(self, heist) -> int:
        decisions = 0
        island = heist.island

        # Leaving early is the sharpest decision in the game: a partial escape
        # pays 0.4 and a foiled one pays nothing (§12.9).
        if self.flees_at is not None and not heist.escaping:
            pressure = max((g.suspicion for g in heist.guards), default=0)
            if pressure >= self.flees_at and any(m.carried for m in heist.crew):
                heist.escaping = True
                decisions += self._decide(heist, ("crew", "flee"), ("flee",), 2)
                for m in heist.crew:
                    m.path = []

        for i, m in enumerate(heist.crew):
            if m.out or m.caught or m.down_ticks:
                continue
            m.crouched = self.crouches
            tile = (m.x // U, m.y // U)
            goal = island.entry if heist.escaping else heist.goal_tile

            if heist.escaping and tile == island.entry:
                m.out = True
                continue

            adjacent = max(abs(tile[0] - island.vault[0]),
                           abs(tile[1] - island.vault[1])) <= 1
            # Only the target realm has a Vault; in a crossing realm the same
            # tile is the link, and reaching it is handled by the simulation.
            if adjacent and not heist.escaping and island is heist.target:
                decisions += self._at_vault(heist, i, m)
                continue

            # A new leg needs a route.
            if not m.path:
                self._plan(heist, m, goal)
                decisions += self._decide(heist, (i, "leg"), ("leg", goal), 2)
                continue

            # A live ward on the next step: through, around, or disarm.
            if m.disarm_ticks:
                m.disarm_ticks -= 1
                if m.disarm_ticks == 0:
                    w = self._live_ward(heist, m.path[0]) if m.path else None
                    if w:
                        w.disarmed = True
                        heist.wards_disarmed += 1
                continue
            ward = self._live_ward(heist, m.path[0]) if m.path else None
            if ward is not None:
                # Three options, always: walk through it, route around it, or
                # spend the time to disarm it.
                choice = self.ward_answer
                decisions += self._decide(heist, (i, "ward"), (choice, ward.kind), 3)
                if choice == "disarm":
                    m.disarm_ticks = ward.disarm_ticks
                    continue
                if choice == "around":
                    before = tuple(m.path)
                    self._plan(heist, m, goal)
                    if not m.path or tuple(m.path) == before:
                        # No way round. Walking through is then not a decision.
                        self.commitment[(i, "ward")] = ("through", ward.kind)
                    continue

            # At a checkpoint: push on, or hold for the cone to pass.
            if tile in self.checkpoints.get(id(m), ()):
                self.checkpoints[id(m)].discard(tile)
                blocked = self._threatened(heist, m.path[0]) if m.path else False
                # Two options exist when something is in the way: push through,
                # or not. Open floor with four exits is not four choices.
                options = 2 if blocked else 1
                if blocked and self.holds_at_checkpoints and m.wait_ticks < 3 * TPS:
                    m.wait_ticks += 1
                    decisions += self._decide(heist, (i, "move"), ("hold",), options)
                    continue
                if blocked and self.routes_around_cones:
                    self._plan(heist, m, goal)
                    decisions += self._decide(heist, (i, "move"), ("around",), options)
                    continue
                m.wait_ticks = 0
                decisions += self._decide(heist, (i, "move"), ("push",), options)
            elif m.wait_ticks:
                # Holding between checkpoints is not a new decision.
                if self._threatened(heist, m.path[0]) if m.path else False:
                    m.wait_ticks += 1
                    if m.wait_ticks < 3 * TPS:
                        continue
                m.wait_ticks = 0
        return decisions

    def _at_vault(self, heist, i: int, m) -> int:
        if not heist.vault_open:
            if heist.tick % WIND_UP_TICKS == 0:
                heist.vault_health -= ROLE_POWER[m.role] * (2 if m.role == "Breaker" else 1)
                if heist.vault_health <= 0:
                    heist.vault_open = True
            return self._decide(heist, (i, "vault"), ("crack",), 1)
        if m.carried < m.capacity and heist.exposed > 0:
            load = min(LOAD_PER_SECOND // TPS, m.capacity - m.carried, heist.exposed)
            m.carried += load
            heist.exposed -= load
            filled = (100 * sum(x.carried for x in heist.crew)
                      // sum(x.capacity for x in heist.crew))
            if self._should_stop(heist, filled):
                heist.escaping = True
                for o in heist.crew:
                    o.path = []
                return self._decide(heist, (i, "vault"), ("stop",), 2)
            return self._decide(heist, (i, "vault"), ("load",), 2)
        heist.escaping = True
        for o in heist.crew:
            o.path = []
        return self._decide(heist, (i, "vault"), ("full",), 1)

    def _should_stop(self, heist, filled: int) -> bool:
        return filled >= self.stop_at_fill


class Careless(Policy):
    """Runs straight at it. No cover, no timing, takes everything, never leaves."""
    name = "careless"
    crouches = False
    routes_around_cones = False
    holds_at_checkpoints = False
    stop_at_fill = 100
    flees_at = None
    ward_answer = "through"


class Competent(Policy):
    """Crouches, routes around what it can see, stops at §12.19's break-even."""
    name = "competent"
    crouches = True
    routes_around_cones = True
    holds_at_checkpoints = False
    stop_at_fill = BREAKEVEN_FILL
    flees_at = ALERTED
    ward_answer = "around"


class Optimal(Competent):
    """Also holds for a cone to sweep, and reads the alarm before loading on.

    The only policy that uses what §12.17 makes available — a guard's suspicion
    is visible and its cone predictable — which is the whole claim behind "a
    player who scouts an island can predict exactly what will happen".
    """
    name = "optimal"
    holds_at_checkpoints = True
    #: spec/wards.md puts the smash-or-disarm crossover at ward level 3. Disarming
    #: is silent where going around costs distance and exposure, so the optimal
    #: crew pays the seconds.
    ward_answer = "disarm"
    #: Not more trigger-happy than competent — better at never getting there.
    #: An earlier version fled at `INVESTIGATING` and scored *below* competent,
    #: because guards reach 600 often and leaving early with a third of a load
    #: is worse than finishing. That is a real result about the design: the
    #: break-even in §12.19 rewards finishing the job, not caution.
    flees_at = ALERTED

    def _should_stop(self, heist, filled: int) -> bool:
        pressure = max((g.suspicion for g in heist.guards), default=0)
        if pressure >= INVESTIGATING:
            return filled >= BREAKEVEN_FILL // 2
        if pressure >= SUSPICIOUS:
            return filled >= BREAKEVEN_FILL
        return filled >= 95


POLICIES = {p.name: p for p in (Careless, Competent, Optimal)}
