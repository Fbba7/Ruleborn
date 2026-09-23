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
from .sim import ASSIST, BREAKEVEN_FILL, LOAD_PER_SECOND, WIND_UP_TICKS, path_to

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
    #: Whether the crew watches §5.4's clock at all. See `_out_of_time`.
    watches_clock = False
    #: The suspicion at which it abandons the run. None never leaves early.
    flees_at: int | None = ALERTED
    #: What it does about a live ward on the next step: "through", "around",
    #: or "disarm". This is §12.6's "take or skip forks; break a pylon or not"
    #: and the crossover priced in docs/design/spec/wards.md.
    ward_answer = "through"
    #: The answer on a v3.2 island (island.RULES), where it differs.
    ward_answer_v32 = None

    def __init__(self) -> None:
        self.crew_decisions = 0
        self.member_decisions = 0
        self.crew_last = -10 ** 9
        self.commitment: dict[int, tuple] = {}
        self.planned = False
        self.checkpoints: dict[int, set] = {}
        self._memo_tick, self._memo = -1, {}
        #: (member, ward) pairs already found to have no way round.
        self._no_way_round: set[tuple[int, int]] = set()

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
            reach = heist.sheet.factor("sight_range")
            out = any(zone(g.role, g.x, g.y, g.facing, tx, ty, reach=reach)
                      and (not heist.sheet.flag("hide_behind_walls", 1)
                           or line_of_sight(island, g.x, g.y, tx, ty))
                      for g in heist.guards)
        self._memo[tile] = out
        return out

    # -- routing -----------------------------------------------------------

    def _live_ward(self, heist, tile):
        """A live ward whose sensor reaches this tile (§10.3, v3.3): its own
        tile for a Time Snare, 3 tiles for a Gravity Well, 2 for a Glare."""
        cx, cy = tile[0] * U + U // 2, tile[1] * U + U // 2
        for w in heist.island.wards:
            if w.spent or w.disarmed:
                continue
            if (w.x, w.y) == tile:
                return w
            wx, wy = w.x * U + U // 2, w.y * U + U // 2
            if w.reach and (cx - wx) ** 2 + (cy - wy) ** 2 <= (w.reach * U) ** 2:
                return w
        return None

    def _covering(self, heist, tile):
        """A ward, live or resetting, whose sensor reaches this tile and that
        this crew would rather not stand in; None if there is none."""
        cx, cy = tile[0] * U + U // 2, tile[1] * U + U // 2
        for w in heist.island.wards:
            if w.disarmed or self._answer(w) == "through":
                continue
            wx, wy = w.x * U + U // 2, w.y * U + U // 2
            if (w.x, w.y) == tile or (w.reach and (cx - wx) ** 2 + (cy - wy) ** 2
                                      <= (w.reach * U) ** 2):
                return w
        return None

    def _clear_spot(self, heist, tile):
        """Where to stand beside the Vault (or link) instead of `tile`, if
        `tile` is inside a ward's sensor and another tile beside it is not.
        The nearest by route, in a fixed order; None to stay."""
        if self._covering(heist, tile) is None:
            return None
        island = heist.island
        vx, vy = island.vault
        best = None
        for dy in (-1, 0, 1):
            for dx in (-1, 0, 1):
                t = (vx + dx, vy + dy)
                if (t == (vx, vy) or not island.walkable(*t)
                        or self._covering(heist, t) is not None):
                    continue
                route = path_to(island, tile, t, exact=True)
                if route and (best is None or len(route) < len(best[1])):
                    best = (t, route)
        return best[0] if best else None

    def _answer(self, ward) -> str:
        """What this crew does about a ward: one answer, or one per kind."""
        a = self.ward_answer
        if ward.rules == "v3.2" and self.ward_answer_v32 is not None:
            a = self.ward_answer_v32
        return a.get(ward.kind, "around") if isinstance(a, dict) else a

    def _plan(self, heist, m, goal) -> None:
        """One route, planned once per leg, and the checkpoints along it.

        The cones are read at planning time only — which is what a scout report
        gives you (§12.3) and what a player actually has.
        """
        tile = (m.x // U, m.y // U)
        def avoid_tile(t) -> bool:
            w = self._live_ward(heist, t)
            if w is not None and self._answer(w) == "around" and t != goal:
                return True
            return self.routes_around_cones and self._threatened(heist, t)

        answers = [a for a in (self.ward_answer, self.ward_answer_v32 or "")
                   for a in (a.values() if isinstance(a, dict) else (a,))]
        rounds = "around" in answers
        avoid = avoid_tile if (self.routes_around_cones or rounds) else None
        m.path = path_to(heist.island, tile, goal, avoid=avoid,
                         exact=goal == heist.island.entry)
        # v3.3's sensors reach up to three tiles, so on a small island every
        # way round can be covered. A crew with no way round walks through,
        # as it always did for a ward on its own tile.
        if not m.path and avoid is not None and tile != goal:
            cones = (lambda t: self._threatened(heist, t)) if self.routes_around_cones else None
            m.path = (path_to(heist.island, tile, goal, avoid=cones,
                              exact=goal == heist.island.entry)
                      or path_to(heist.island, tile, goal,
                                 exact=goal == heist.island.entry))
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
            # Beside the Vault or the link, but inside a ward's sensor: a
            # triggered ward re-arms (§10.3), so whoever stops there to crack
            # or to wait sets it off again at every reset. A crew that does
            # not walk through wards moves to a tile beside it that none
            # reaches, where there is one. D57: an earlier version stood still
            # in front of such a ward instead, which kept it off the tile by
            # accident; once that was fixed, three of a crew stood cracking on
            # a Lantern Glare beside the Vault and re-lit it every nine
            # seconds until the clock ran out.
            if adjacent and not heist.escaping:
                spot = self._clear_spot(heist, tile)
                if spot is not None:
                    if not m.path or m.path[-1] != spot:
                        m.path = path_to(island, tile, spot, exact=True)
                    adjacent = False
            # Only the target realm has a Vault; in a crossing realm the same
            # tile is the link, and reaching it is handled by the simulation.
            if adjacent and not heist.escaping and island is heist.target:
                decisions += self._at_vault(heist, i, m)
                continue
            # At the link, wait for the rest of the crew. An earlier version
            # re-planned from here to another tile beside it, and where v3.3's
            # sensors cover the tiles between, the nearest one to avoid them
            # was the long way round — so the crew was never beside the link
            # all at once, and never crossed.
            if adjacent and not heist.escaping:
                m.path = []
                continue

            # A new leg needs a route.
            if not m.path:
                self._plan(heist, m, goal)
                decisions += self._decide(heist, (i, "leg"), ("leg", goal), 2)
                continue

            # Disarming (§10.3, v3.3): fifteen seconds standing on the ward's
            # tile. A freeze — the ward's own, when it fires at its disarmer —
            # pauses it; stepping off would start it again, and this crew
            # does not step off.
            if m.disarm_ticks and island.rules == "v3.2":
                # v3.2: from beside the ward, which is the next step.
                m.disarm_ticks -= 1
                if m.disarm_ticks == 0:
                    w = self._live_ward(heist, m.path[0]) if m.path else None
                    if w:
                        w.disarmed = True
                        heist.wards_disarmed += 1
                continue
            if m.disarm_ticks:
                if not m.frozen_ticks:
                    m.disarm_ticks -= 1
                if m.disarm_ticks == 0:
                    w = next((w for w in island.wards
                              if (w.x, w.y) == tile and not w.disarmed), None)
                    if w:
                        w.disarmed = True
                        heist.wards_disarmed += 1
                    self._plan(heist, m, goal)
                continue
            here = next((w for w in island.wards if (w.x, w.y) == tile
                         and not w.disarmed and self._answer(w) == "disarm"), None)
            if here is not None and self.commitment.get((i, "ward"), (None,))[0] == "disarm":
                m.disarm_ticks = here.disarm_ticks
                continue
            ward = self._live_ward(heist, m.path[0]) if m.path else None
            if ward is not None:
                # Three options, always: walk through it, route around it, or
                # spend the time to disarm it.
                choice = self._answer(ward)
                if choice == "around" and (i, id(ward)) in self._no_way_round:
                    choice = "through"
                decisions += self._decide(heist, (i, "ward"), (choice, ward.kind), 3)
                if choice == "disarm" and ward.rules == "v3.2":
                    m.disarm_ticks = ward.disarm_ticks
                    continue
                if choice == "disarm":
                    # Onto its tile first: a disarmer stands on the ward.
                    m.path = path_to(island, tile, (ward.x, ward.y)) or m.path
                    choice = "through"
                if choice == "around":
                    before = tuple(m.path)
                    self._plan(heist, m, goal)
                    if m.path and tuple(m.path) != before:
                        continue
                    # No way round. Walking through is then not a decision —
                    # and it is walked: an earlier version stood still here
                    # re-planning every tick, which on-tile wards almost never
                    # reached and v3.3's reach, covering every tile beside a
                    # Vault, reached on most islands.
                    self.commitment[(i, "ward")] = ("through", ward.kind)
                    self._no_way_round.add((i, id(ward)))
                    m.path = m.path or list(before)

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
                damage = ROLE_POWER[m.role] * (2 if m.role == "Breaker" else 1)
                if heist.rules == "v3.3" and heist.crackers() >= 2:   # §11.1, assist
                    damage = damage * ASSIST[0] // ASSIST[1]
                heist.vault_health -= int(damage * heist.sheet.factor("structure_damage"))
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

        # This member can carry no more. That is not the crew's cue to leave.
        # §12.19 has every role loading its own bag at 30 a second, so a Scout's
        # 60 is full in two seconds and a Carrier's 300 takes ten — "a full crew
        # fills in about ten seconds, which is one decision at the eight-to-twelve
        # second cadence 12.6 sets for itself".
        #
        # Ending the phase on the first full bag made it two seconds long and
        # capped every crew at 53% fill whatever the island did, because the
        # Carrier — 300 of the crew's 560 — left with 60. That is exactly the
        # "two seconds and one option" §12.6 was criticised for and §12.19 was
        # written to fix, reintroduced here by the policy rather than by the spec.
        if not (heist.exposed <= 0
                or all(o.carried >= o.capacity or o.out or o.caught
                       for o in heist.crew)):
            return 0

        heist.escaping = True
        for o in heist.crew:
            o.path = []
        return self._decide(heist, (i, "vault"), ("full",), 1)

    def _should_stop(self, heist, filled: int) -> bool:
        return filled >= self.stop_at_fill or self._out_of_time(heist)

    #: Leave this many times the inbound journey in hand. 1.0 is "the way out
    #: takes as long as the way in, and I have exactly that left" — no margin,
    #: which is what a crew that has never been caught would do.
    clock_margin = 1.15

    def _out_of_time(self, heist) -> bool:
        """§12.19: "loading longer earns more and the alarm clock is the price."

        A price nobody can see is not a price, and until this was added no policy
        read `heist.clock` at all — so shortening §5.4's clock could only kill a
        crew outright, never change what it chose to do (D25). The estimate is
        the one a player makes: the way out is the way in, so what it cost to
        reach the Vault is what it will cost to leave.
        """
        if not self.watches_clock or heist.crack_started_at is None:
            return False
        inbound = heist.crack_started_at
        return heist.clock - heist.tick <= inbound * self.clock_margin


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
    watches_clock = True
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
    #: v3.3's disarm is fifteen seconds on the ward's own tile, where the ward
    #: fires at its disarmer (G16). A Snare's freeze and a Well's pull cost
    #: seconds, so those are disarmed; a Glare shows the crew to every guard,
    #: so the optimal crew goes round it.
    ward_answer = {"Time Snare": "disarm", "Gravity Well": "disarm",
                   "Lantern Glare": "around"}
    #: v3.2: spec/wards.md put the smash-or-disarm crossover at ward level 3.
    #: Disarming was silent where going around costs distance and exposure, so
    #: the optimal crew paid the seconds.
    ward_answer_v32 = "disarm"
    #: Not more trigger-happy than competent — better at never getting there.
    #: An earlier version fled at `INVESTIGATING` and scored *below* competent,
    #: because guards reach 600 often and leaving early with a third of a load
    #: is worse than finishing. That is a real result about the design: the
    #: break-even in §12.19 rewards finishing the job, not caution.
    flees_at = ALERTED

    def _should_stop(self, heist, filled: int) -> bool:
        if self._out_of_time(heist):
            return True
        pressure = max((g.suspicion for g in heist.guards), default=0)
        if pressure >= INVESTIGATING:
            return filled >= BREAKEVEN_FILL // 2
        if pressure >= SUSPICIOUS:
            return filled >= BREAKEVEN_FILL
        return filled >= 95


class Clearing(Optimal):
    """Clears the Heart before it touches the Vault (T0.11, F32).

    v3.3's crack noise calls every guard in the Heart to the Vault five
    seconds into cracking, and no ordinary crack is shorter. This crew plays
    the game that rule asks for: in the Heart, one member takes each guard
    down before anyone cracks, and the rest wait at the landing.

    §12.8 names the way in to a guard that walks a route: "already waiting
    unseen beside the guard's path and lets the guard come to it". So the
    taker goes, crouched and routing round every cone, to a tile beside the
    guard's next waypoint — in cover where there is any — stands still, and
    starts the two-second takedown as the guard comes past, from out of its
    cone. The harness has no hearing but the crack, so the approach is
    judged by sight alone; that is kinder to this crew than §12.17 is, and
    the result is an upper bound.

    It waits out a Suspicious guard, and gives up clearing — and cracks with
    what it has — the moment any guard in the Heart is Investigating or
    Alerted, or once a third of the clock is gone.
    """
    name = "clearing"
    #: How much of the clock clearing may spend before the crew cracks anyway.
    clear_budget = 1 / 3

    def __init__(self) -> None:
        super().__init__()
        self.cleared = False
        self._wait: dict[int, tuple] = {}

    def act(self, heist) -> int:
        if (self.cleared or heist.escaping or heist.island is not heist.target):
            return super().act(heist)
        live = [gi for gi, g in enumerate(heist.guards) if not g.down]
        spent = heist.tick >= heist.clock * self.clear_budget
        # Suspicion drains, so a Suspicious guard is waited out; one that is
        # Investigating or Alerted is looking, and the chance has gone.
        if (not live or spent
                or any(heist.guards[gi].state in ("investigating", "alerted")
                       for gi in live)):
            self.cleared = True
            for m in heist.crew:
                m.path = []
            return self._decide(heist, ("crew", "clear"), ("crack",), 2)
        decisions = 0
        crew = [m for m in heist.crew if not (m.out or m.caught or m.down_ticks)]
        if not crew:
            return 0
        # The fastest role takes; everyone else waits where they landed.
        taker = max(crew, key=lambda m: m.step)
        for m in crew:
            m.crouched = True
            if m is not taker:
                m.path = []
        if taker.takedown is not None:
            return 0
        tile = (taker.x // U, taker.y // U)
        calm = [i for i in live if heist.guards[i].state == "unaware"]
        if not calm:
            taker.path = []                      # hold still until it settles
            return 0
        gi = min(calm, key=lambda i: (heist.guards[i].x - taker.x) ** 2
                 + (heist.guards[i].y - taker.y) ** 2)
        g = heist.guards[gi]
        beside = (g.x - taker.x) ** 2 + (g.y - taker.y) ** 2 <= (U * 3 // 2) ** 2
        seen = zone(g.role, g.x, g.y, g.facing, taker.x, taker.y,
                    reach=heist.sheet.factor("sight_range"))
        if beside and not seen:
            taker.takedown, taker.path = gi, []
            return self._decide(heist, (heist.crew.index(taker), "clear"),
                                ("takedown", gi), 2)
        # Where to wait: beside the guard's next waypoint, in cover if any.
        way = g.patrol[g.leg % len(g.patrol)]
        spot = self._wait.get(gi)
        if spot is None or spot[0] != way:
            spot = (way, self._ambush_tile(heist.island, way))
            self._wait[gi] = spot
            taker.path = []
        wait_at = spot[1]
        if wait_at is None or tile == wait_at:
            return 0                                  # in place: let it come
        if not taker.path:
            avoid = lambda t: t != wait_at and self._threatened(heist, t)
            taker.path = (path_to(heist.island, tile, wait_at, avoid=avoid)
                          or path_to(heist.island, tile, wait_at))
            decisions += self._decide(heist, (heist.crew.index(taker), "clear"),
                                      ("wait", gi), 2)
        return decisions

    @staticmethod
    def _ambush_tile(island, way):
        """A walkable tile beside a waypoint, cover first, in a fixed order."""
        near = [(way[0] + dx, way[1] + dy)
                for dx, dy in ((0, -1), (-1, 0), (1, 0), (0, 1),
                               (-1, -1), (1, -1), (-1, 1), (1, 1))]
        near = [t for t in near if island.walkable(*t) and t not in (island.entry, island.vault)]
        if not near:
            return None
        return next((t for t in near if island.hides(*t)), near[0])


POLICIES = {p.name: p for p in (Careless, Competent, Optimal, Clearing)}
