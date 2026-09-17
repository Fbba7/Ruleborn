"""One heist, simulated tick by tick.

A run is a pure function of (island seed, crew, policy). Nothing inside the loop
consults a random source — §12.17's own requirement, and the thing that makes a
replay checkable on the server (§24.10).

What is modelled, and why each is here:

  * §12.17 perception, in full: three zones, peripheral arc, suspicion, six states
  * §12.18 movement: breadth-first paths on the tile graph, continuous position,
    crew passing through one another, and the command recorded rather than the path
  * §12.19 the Vault: crack, then load at 30 units a second, fill fraction banked
  * §12.20 capture: ten seconds down, loot dropped on the tile
  * §12.9 grades, which is what the harness is finally measuring

What is not: laws, wards, abilities, pylons, fights the crew starts. §19.27 asks
whether the heist carries decisions and whether skill separates outcomes, and
every one of those additions widens the gap between skill levels rather than
narrowing it — so leaving them out makes the harness's answer conservative.
"""

import json
import pathlib
from dataclasses import dataclass, field

from . import detect
from .laws import Sheet
from .detect import (ALERTED, DECAY, INVESTIGATING, STATE_FLOOR_TICKS, SUS_MAX,
                     SUSPICIOUS, VISION, fill_rate, line_of_sight, zone)
from .fixed import TPS, U, Rng, angle_to, dist2, tiles, turn_toward

ROOT = pathlib.Path(__file__).resolve().parent.parent.parent
ROLES = {r["name"]: r for r in
         json.loads((ROOT / "content" / "roles.json").read_text(encoding="utf-8"))}

#: §5.4: "150 seconds plus 15 seconds for each link on the shortest route from
#: the landing realm to the Heart, up to 240 seconds." The clock is therefore a
#: function of how far in the Vault is, which is why the harness crosses realms
#: rather than modelling one.
BASE_TICKS = 150 * TPS
LINK_TICKS = 15 * TPS
MAX_TICKS = 240 * TPS
VAULT_HEALTH_PER_LEVEL = 1_500           #: §12.6
LOAD_PER_SECOND = 30                     #: §12.19
WIND_UP_TICKS = int(0.8 * TPS)           #: §12.8, one hit per 0.8 s
SKIFF_TICKS = 5 * TPS                    #: §12.6, an outer realm
CRACK_AWARENESS_PER_5S = 10              #: §12.6, percent added to Heart guards

# -- the proposed response layer (docs/design/spec/response.md) -------------
#
# §13.2 names four things in the response layer — "bells, alarms, the Spire's
# reach, and the guardian Sage's single power" — and gives an effect to only the
# first two, both of which move guards. That is F15: with nothing of its own the
# layer is multiplicative with guards, and the Shapley value must then hand the
# two identical shares. These are effects for the other two, chosen so that
# neither passes through a guard. Both fire on the Vault opening, which is the
# one event in every heist an island observes with nobody standing there — and
# which §12.6 already makes the pivot into the Escape phase.
#
# `response_model="published"` is the default, so the harness keeps reproducing
# the document as written unless it is asked for the proposal.
SPIRE_GRACE_SECONDS = 25                 #: from the first hit on the Vault, minus the realm level
SPIRE_RESEAL_PER_SECOND = 20             #: against an exposed share of 560
#: §9.6's own floor, applied to the re-seal: "a clean raid on a fully sealed
#: island still pays 0.7 — nobody ever leaves with nothing."
#:
#: Read as a guarantee rather than as a cap: **this share of the exposed loot is
#: always reachable**, and the Spire races the crew for the rest. Without it a
#: fast re-seal empties the Vault before a slow crew loads anything, so the raid
#: banks zero and counts as foiled — which pushes the hold rate out of
#: §13.2's 30–45% band as the rate rises. With it the mechanism moves
#: the raider's stopping decision without ever taking the raid itself: measured,
#: 20 a second stopping at 45% moves the break-even from 100% to 80% and leaves
#: the hold rate at 44.5% against a 45.0% baseline.
SPIRE_RESEAL_FLOOR_PERCENT = 45
SAGE_SLOW_PERCENT = 30                   #: the Sage's single power: Weight
SAGE_TICKS = 20 * TPS

#: §12.19's break-even, and the number the harness exists to test.
BREAKEVEN_FILL = 70


@dataclass
class Member:
    role: str
    x: int
    y: int
    carried: int = 0
    down_ticks: int = 0
    revive_ticks: int = 0
    wait_ticks: int = 0
    frozen_ticks: int = 0
    disarm_ticks: int = 0
    still_ticks: int = 0
    caught: bool = False
    out: bool = False
    path: list = field(default_factory=list)
    crouched: bool = True

    @property
    def capacity(self) -> int:
        return ROLES[self.role]["carry"]

    @property
    def step(self) -> int:
        """Position units per tick, from §11.1's tiles a second."""
        return max(1, int(ROLES[self.role]["speed"] * U) // TPS)


#: §10.2's Guardian Post ladder, as what one level adds to a guard's sight.
#: The document sells "+10% health and sight" a level, so 0.10; level 1 is the
#: baseline, giving a multiplier of 1 + STEP x (level - 1) and leaving every
#: number measured before post levels existed exactly where it was.
#:
#: It is a module constant rather than a literal because F26's recommendation
#: turns on it: the ladder is the only dial the document has that is finer than
#: a whole guard, and whether a *steeper* one would close F26's gap is a
#: question worth being able to ask rather than assert. See
#: tools/post_ladder.py.
POST_SIGHT_STEP = 0.10


def post_sight(level: int) -> float:
    return 1.0 + POST_SIGHT_STEP * (level - 1)


@dataclass
class Guard:
    role: str
    x: int
    y: int
    facing: int
    patrol: list
    leg: int = 0
    suspicion: int = 0
    state: str = "unaware"
    state_ticks: int = 0
    target: tuple | None = None
    #: §10.2's Guardian Post level, 1 to 5, as a sight multiplier of
    #: 1 + 0.1 x (level - 1). See island.Patrol for why level 1 is the baseline.
    level: int = 1


@dataclass
class Result:
    seed: int
    policy: str
    grade: str
    fill: int                 #: percentage of crew capacity banked
    ticks: int
    decisions: int
    near_captures: int
    peak_suspicion: int
    alarm: bool
    caught: int
    #: The grade the run would have had if the clock had stopped ten seconds early.
    grade_ten_seconds_earlier: str
    #: "clock", "caught", or "" when the run succeeded.
    lost_to: str = ""
    wards_triggered: int = 0
    wards_disarmed: int = 0
    crossings: int = 0
    clock_ticks: int = 0

    @property
    def success(self) -> bool:
        return self.grade in ("clean", "loud", "partial")

    @property
    def last_ten_decided(self) -> bool:
        return self.grade != self.grade_ten_seconds_earlier


GRADE_VALUE = {"clean": 1.0, "loud": 0.7, "partial": 0.4, "foiled": 0.0}


def path_to(island, start, goal, avoid=None, exact=False) -> list:
    """Breadth-first on the tile graph, fixed neighbour order (§12.18).

    `avoid` is a predicate naming tiles the policy would rather not cross — a
    callable rather than a set, because building the set means testing every tile
    on the map when the search only ever looks at a few. They are not walls: if no
    path avoids them, the search runs again without them, so a cautious policy is
    never simply stuck.
    """
    #: The Vault's own tile is not walkable, so a route to it means a route to a
    #: tile beside it. The exit is walkable and must be reached exactly — without
    #: `exact`, an escaping crew paths to a tile *next to* the exit, arrives, is
    #: still not out, and re-plans to another tile next to the exit, for ever.
    never = lambda _t: False                                      # noqa: E731
    for forbidden in ((avoid or never), never):
        prev = {start: None}
        frontier = [start]
        goals = {goal} if exact else {
            (goal[0] + dx, goal[1] + dy)
            for dx in (-1, 0, 1) for dy in (-1, 0, 1)} | {goal}
        found = None
        while frontier and not found:
            nxt = []
            for cur in frontier:
                if cur in goals and cur != start:
                    found = cur
                    break
                for dx, dy in ((0, -1), (-1, 0), (1, 0), (0, 1)):
                    n = (cur[0] + dx, cur[1] + dy)
                    if n in prev or not island.walkable(*n) or forbidden(n):
                        continue
                    prev[n] = cur
                    nxt.append(n)
            frontier = nxt
        if found:
            out = []
            while found:
                out.append(found)
                found = prev[found]
            return out[::-1][1:]
    return []


class Heist:
    #: §12.5: 3 characters, 4 from Keeper level 8, 5 from level 16. Five is the
    #: finished crew and the one every other number in this analysis assumes.
    DEFAULT_CREW = ("Scout", "Breaker", "Carrier", "Warden", "Mender")

    def __init__(self, island, policy, crew_roles=DEFAULT_CREW,
                 realm_level: int = 3, crossing=(), sheet=None, response: bool = True,
                 response_model: str = "published",
                 clock_pct: int = 100, exposed_pct: int = 100):
        """`crossing` is the outer realms the crew walks through on the way in.

        §12.6 splits a heist into Entry, Crossing, Vault and Escape, and gives the
        crossing 20 to 120 seconds of the run. A one-realm heist is the special
        case where that phase is empty, and it is not the common one: §5.4 prices
        the skiff by the number of links between the landing realm and the Heart.
        """
        self.crossing = list(crossing)
        self.leg = 0
        self.islands = self.crossing + [island]
        self.island = self.islands[0]
        self.target = island
        self.policy = policy
        self.realm_level = realm_level
        #: §7.3: the realm's rule sheet, after its laws are woven. An empty sheet
        #: is the default, which is the island with no laws on it.
        self.sheet = sheet or Sheet()
        #: §13.2's response layer (15%): "bells, alarms, the Spire's reach... what
        #: turns being seen into being caught." With it off a guard may reach
        #: Alerted and still not converge, and the alarm does not spread.
        self.response = response
        #: "published" reproduces §13.2 as written; "proposed" adds the two
        #: effects spec/response.md specifies for the Spire and the Sage.
        self.response_model = response_model
        self.vault_opened_at = None
        self.crack_started_at = None
        #: Exposed per-instance so the two dials can be swept without editing
        #: the module; the defaults are the ones spec/sinks.md's sibling file,
        #: spec/response.md, proposes.
        self.spire_grace = SPIRE_GRACE_SECONDS
        self.spire_reseal = SPIRE_RESEAL_PER_SECOND
        self.spire_floor = SPIRE_RESEAL_FLOOR_PERCENT
        #: The Sage's single power, as a percentage slow on loaded crew. Zero
        #: turns it off, which is how its contribution is measured separately
        #: from the Spire's reach.
        self.sage_percent = SAGE_SLOW_PERCENT
        self.sage_ticks = 0
        self.resealed = 0
        self._reseal_acc = 0
        self.clock = int(min(MAX_TICKS, BASE_TICKS + LINK_TICKS * len(self.crossing))
                         / self.sheet.factor("clock_rate"))
        # §5.4's clock and §12.19's exposed share, as whole percentages, so
        # they can be swept without editing the module. Both default to 100,
        # which is exactly the document — `clock_pct` is applied after the
        # division so the published value is reproduced bit for bit.
        self.clock = self.clock * clock_pct // 100
        self.vault_health = VAULT_HEALTH_PER_LEVEL * realm_level
        self.vault_open = False
        self.exposed = sum(ROLES[r]["carry"] for r in crew_roles) * exposed_pct // 100
        #: What the Spire's reach re-seals *down to*, never past (§9.6's floor).
        self.exposed_at_start = self.exposed
        self.crew = [Member(r, self.island.entry[0] * U + U // 2,
                            self.island.entry[1] * U + U // 2) for r in crew_roles]
        self.guards = []
        self._enter(self.island)
        self.tick = 0
        self.alarm = False
        self.decisions = 0
        self.near_captures = 0
        self.peak_suspicion = 0
        self.escaping = False
        self.grade_history = []
        self.wards_triggered = 0
        self.wards_disarmed = 0
        self.crossings = 0

    def _enter(self, island) -> None:
        """Place the guards of the realm the crew has just entered."""
        self.island = island
        # §12.17's guards are somewhere on their loop when a raid starts, and
        # `Patrol.phase` is what says where. It was computed by the generator and
        # never read here (D26), so every guard began every raid at waypoint
        # zero: the defence was always caught at the same moment of its cycle.
        # The phase is in ticks over the whole loop, 30 to a waypoint.
        self.guards = []
        for p in island.patrols:
            leg = (p.phase // 30) % len(p.waypoints) if p.waypoints else 0
            wx, wy = p.waypoints[leg]
            g = Guard(p.role, wx * U + U // 2, wy * U + U // 2, 0, p.waypoints,
                      level=p.level)
            g.leg = leg
            self.guards.append(g)

    @property
    def goal_tile(self):
        """What the crew is walking toward in this realm: a link, or the Vault."""
        return self.island.vault

    def _cross(self) -> bool:
        """Move on to the next realm once the whole crew reaches the link.

        §12.6: "Crossing a link plays a one-second swoop to the next realm." The
        alarm does not follow — §12.8's alarm "calls every guard in the realm".
        """
        if self.island is self.target or self.escaping:
            return False
        here = [m for m in self.crew if not m.out and not m.caught]
        if not here:
            return False
        link = self.island.vault
        if not all(max(abs(m.x // U - link[0]), abs(m.y // U - link[1])) <= 1
                   for m in here):
            return False
        self.leg += 1
        nxt = self.islands[self.leg]
        self._enter(nxt)
        for m in self.crew:
            m.x, m.y = nxt.entry[0] * U + U // 2, nxt.entry[1] * U + U // 2
            m.path = []
            m.wait_ticks = m.frozen_ticks = m.disarm_ticks = 0
        self.crossings += 1
        return True

    # -- guards ------------------------------------------------------------

    def _guard_move(self, g: Guard) -> None:
        if g.state == "alerted" and self.response:
            target = self._nearest_visible_crew(g)
            goal = (target.x, target.y) if target else (g.x, g.y)
        elif g.state == "investigating" and g.target:
            goal = g.target
        else:
            wx, wy = g.patrol[g.leg % len(g.patrol)]
            goal = (wx * U + U // 2, wy * U + U // 2)
            if dist2(g.x, g.y, *goal) < (U // 3) ** 2:
                g.leg += 1
        speed = max(1, int(ROLES[g.role]["speed"] * U * self.sheet.factor("guard_speed"))
                    // TPS)
        if g.state in ("investigating", "alerted"):
            speed = speed * 5 // 4
        if goal != (g.x, g.y):
            want = angle_to(g.x, g.y, *goal)
            g.facing = turn_toward(g.facing, want, VISION[g.role]["turn"])
            if dist2(g.x, g.y, *goal) > speed * speed:
                from .fixed import cos, sin
                g.x += cos(g.facing) * speed // 1024
                g.y += sin(g.facing) * speed // 1024

    def _nearest_visible_crew(self, g: Guard):
        best, best_d = None, None
        for m in self.crew:
            if m.out or m.caught:
                continue
            d = dist2(g.x, g.y, m.x, m.y)
            if best_d is None or d < best_d:
                best, best_d = m, d
        return best

    def _perceive(self, g: Guard) -> None:
        gained = 0
        # Hoisted: these are the same for every crew member on this tick, and
        # this loop runs once per guard per tick for the whole run.
        # §10.2 sells Guardian Post levels as "+10% health and sight". The
        # harness has no guard health, so only the sight half lands here.
        reach = self.sheet.factor("sight_range") * post_sight(g.level)
        walls_hide = self.sheet.flag("hide_behind_walls", 1)
        still_hides = self.sheet.flag("still_is_invisible")
        fill_factor = self.sheet.factor("suspicion_fill")
        for m in self.crew:
            if m.out or m.caught:
                continue
            z = zone(g.role, g.x, g.y, g.facing, m.x, m.y, reach=reach)
            if not z:
                continue
            # §7.7 Glass: "walls become see-through: nobody can hide behind them,
            # though they still block movement."
            if not walls_hide:
                pass
            elif not line_of_sight(self.island, g.x, g.y, m.x, m.y):
                continue
            tile = (m.x // U, m.y // U)
            hidden = self.island.hides(*tile) and not m.path and m.down_ticks == 0
            # §7.7 Stillness: standing still for 1.5 s hides you from guards.
            if still_hides and m.still_ticks >= int(1.5 * TPS):
                hidden = True
            rate = fill_rate(z, m.crouched, running=not m.crouched,
                             hidden=hidden, unlit=False)
            rate = int(rate * fill_factor)
            if rate:
                gained = max(gained, rate)
                g.target = (m.x, m.y)
        if gained:
            before = g.suspicion
            g.suspicion = min(SUS_MAX, g.suspicion + gained)
            # "Within a second of capture" (§19.27): one more second at this rate
            # would have alerted the guard, and it did not.
            if before < ALERTED and g.suspicion < ALERTED \
                    and g.suspicion + gained * TPS >= ALERTED:
                self.near_captures += 1
        else:
            g.suspicion = max(0, g.suspicion - DECAY)
        self.peak_suspicion = max(self.peak_suspicion, g.suspicion)

        want = g.state
        if g.suspicion >= ALERTED:
            want = "alerted"
        elif g.suspicion >= INVESTIGATING:
            want = "investigating"
        elif g.suspicion >= SUSPICIOUS:
            want = "suspicious"
        elif g.suspicion == 0:
            want = "unaware"
        g.state_ticks += 1
        if want != g.state and g.state_ticks >= STATE_FLOOR_TICKS:
            g.state, g.state_ticks = want, 0
        if g.state == "alerted" and self.response:
            self.alarm = True

    # -- the crew ----------------------------------------------------------

    def _advance(self, m: Member) -> None:
        if not m.path:
            return
        tx, ty = m.path[0]
        goal = (tx * U + U // 2, ty * U + U // 2)
        d2 = dist2(m.x, m.y, *goal)
        loaded = m.carried > 0
        factor = self.sheet.factor("loaded_speed" if loaded else "crew_speed")
        step = m.step if m.crouched else m.step * 2
        step = max(1, int(step * factor))
        if self.sage_ticks and loaded and self.sage_percent:
            step = max(1, step * (100 - self.sage_percent) // 100)
        if d2 <= step * step:
            m.x, m.y = goal
            m.path.pop(0)
            return
        from .fixed import cos, sin
        a = angle_to(m.x, m.y, *goal)
        m.x += cos(a) * step // 1024
        m.y += sin(a) * step // 1024

    # -- wards -------------------------------------------------------------

    def _wards(self) -> None:
        """Triggered wards fire on the first member to enter, then reset (§10.3).

        Effects are the spec/wards.md reading of §10.2's "effect +15%": a duration
        or a damage scales with level, never a distance.
        """
        for w in self.island.wards:
            if w.spent and self.tick >= w.reset_at:
                w.spent = False
            if w.spent or w.disarmed:
                continue
            for m in self.crew:
                if m.out or m.caught:
                    continue
                if (m.x // U, m.y // U) != (w.x, w.y):
                    continue
                scale = 100 + 15 * (w.level - 1)
                if w.kind == "Time Snare":
                    m.frozen_ticks = int(2.5 * TPS) * scale // 100
                elif w.kind == "Gravity Well":
                    m.frozen_ticks = 2 * TPS * scale // 100
                elif w.kind == "Lantern Glare":
                    # Shows the crew to every guard in the realm for 5 s (§10.3).
                    for g in self.guards:
                        g.suspicion = ALERTED
                w.spent = True
                w.reset_at = self.tick + w.reset_ticks
                self.wards_triggered += 1
                break

    def _capture_check(self) -> None:
        if not self.response:
            return
        for g in self.guards:
            if g.state != "alerted":
                continue
            for m in self.crew:
                if m.out or m.caught:
                    continue
                if dist2(g.x, g.y, m.x, m.y) <= (U * 3 // 4) ** 2:
                    m.down_ticks += 1
                    if m.down_ticks >= 10 * TPS:      # §12.20
                        m.caught = True
                        m.carried = 0                 # dropped on the tile
        # §12.20: an ally standing adjacent revives in 3 s, a Mender in 1.5.
        for m in self.crew:
            if not m.down_ticks or m.caught:
                continue
            helper = next(
                (o for o in self.crew
                 if o is not m and not o.out and not o.caught and not o.down_ticks
                 and dist2(o.x, o.y, m.x, m.y) <= U * U),
                None)
            if helper:
                m.revive_ticks += 1
                need = int(1.5 * TPS) if helper.role == "Mender" else 3 * TPS
                if m.revive_ticks >= need:
                    m.down_ticks = m.revive_ticks = 0
                continue
            m.revive_ticks = 0
            near = any(g.state == "alerted"
                       and dist2(g.x, g.y, m.x, m.y) <= (U * 3 // 4) ** 2
                       for g in self.guards)
            if not near:
                m.down_ticks = 0

    # -- response ----------------------------------------------------------

    def _respond(self) -> None:
        """The half of the response layer that works with no guard on the island.

        Two effects, both triggered by the Vault rather than by a sighting, which
        is what makes them independent of guards:

          * **The Spire's reach.** Cracking is loud (§12.17). `SPIRE_GRACE_SECONDS`
            after the first hit lands, the Vault starts sealing itself: the
            exposed share falls at `SPIRE_RESEAL_PER_SECOND` whether or not it is
            open yet. §9.6 already distinguishes exposed wealth from sealed, and
            already prices a fully sealed island at 0.7, so the quantity exists.
            A crew that cracks fast finds the Vault full; a slow crew finds it
            emptying; a crew that is slow enough finds nothing, which is the case
            that turns this into a hold rather than a smaller haul.
          * **The guardian Sage's single power.** Spent once, the moment the
            Vault opens. Modelled as *Weight*: loaded crew move at
            100 - `SAGE_SLOW_PERCENT` per cent for `SAGE_TICKS`.

        Neither exists in the document. §13.2 names both and specifies neither,
        which is the gap F15 records.
        """
        if self.crack_started_at is None:
            if self.vault_health < VAULT_HEALTH_PER_LEVEL * self.realm_level:
                self.crack_started_at = self.tick
            else:
                return
        if self.vault_open and self.vault_opened_at is None:
            self.vault_opened_at = self.tick
            if self.response and self.response_model == "proposed":
                self.sage_ticks = SAGE_TICKS
        if self.sage_ticks:
            self.sage_ticks -= 1
        if not (self.response and self.response_model == "proposed"):
            return
        grace = max(2, self.spire_grace - self.realm_level) * TPS
        floor = self.exposed_at_start * self.spire_floor // 100
        if self.tick - self.crack_started_at < grace or self.exposed <= floor:
            return
        # Accumulated rather than divided, so a rate that is not a whole number
        # of units a tick stays exact and stays deterministic.
        self._reseal_acc += self.spire_reseal
        back = min(self.exposed - floor, self._reseal_acc // TPS)
        self._reseal_acc -= back * TPS
        self.exposed -= back
        self.resealed += back

    # -- grading -----------------------------------------------------------

    def _grade_now(self) -> str:
        banked = sum(m.carried for m in self.crew if m.out)
        caught = sum(1 for m in self.crew if m.caught)
        if banked == 0:
            return "foiled"
        if caught:
            return "partial"
        if not all(m.out for m in self.crew):
            return "partial"
        return "loud" if self.alarm else "clean"

    # -- the loop ----------------------------------------------------------

    def run(self) -> Result:
        while self.tick < self.clock:
            for g in self.guards:
                self._guard_move(g)
                self._perceive(g)
            self._wards()
            if self._cross():
                self.tick += TPS            # §12.6's one-second swoop
                continue
            self.decisions += self.policy.act(self)
            self._respond()
            for m in self.crew:
                moving = bool(m.path) and not m.wait_ticks and not m.frozen_ticks
                m.still_ticks = 0 if moving else m.still_ticks + 1
                if m.frozen_ticks:
                    m.frozen_ticks -= 1
                    continue
                if not m.out and not m.caught and m.down_ticks == 0 \
                        and m.wait_ticks == 0 and m.disarm_ticks == 0:
                    self._advance(m)
            self._capture_check()
            self.grade_history.append(self._grade_now())
            self.tick += 1
            if all(m.out or m.caught for m in self.crew):
                break

        capacity = sum(m.capacity for m in self.crew)
        banked = sum(m.carried for m in self.crew if m.out)
        grade = self._grade_now()
        lost_to = ""
        if grade == "foiled":
            lost_to = "caught" if any(m.caught for m in self.crew) else "clock"
        # §19.27 asks whether "the last ten seconds decide the outcome". That is a
        # question about the clock, not about the run: a crew out at 60 seconds had
        # its outcome settled long before the last ten. So the comparison is the
        # grade with ten seconds of clock left — which, for a run that ended early,
        # is the final grade, and correctly counts as decided early.
        cutoff = self.clock - 10 * TPS
        earlier = (self.grade_history[cutoff]
                   if len(self.grade_history) > cutoff else grade)
        return Result(
            seed=self.target.seed, policy=self.policy.name,
            grade=grade,
            fill=100 * banked // capacity if capacity else 0,
            ticks=self.tick, decisions=self.decisions,
            near_captures=self.near_captures, peak_suspicion=self.peak_suspicion,
            alarm=self.alarm,
            caught=sum(1 for m in self.crew if m.caught),
            grade_ten_seconds_earlier=earlier, lost_to=lost_to,
            wards_triggered=self.wards_triggered,
            wards_disarmed=self.wards_disarmed,
            crossings=self.crossings, clock_ticks=self.clock,
        )
