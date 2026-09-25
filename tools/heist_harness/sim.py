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
from fractions import Fraction
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
from ..design_facts import HEIST_CLOCK                   # 5.4 (D37)
BASE_TICKS = HEIST_CLOCK[0] * TPS
LINK_TICKS = HEIST_CLOCK[1] * TPS
MAX_TICKS = HEIST_CLOCK[2] * TPS
from ..design_facts import (VAULT_HEALTH_PER_LEVEL, LOAD_PER_SECOND,  # D37
                            DOWN_SECONDS, REVIVE_SECONDS,
                            TAKEDOWN_SECONDS, ASSIST_BONUS,
                            MENDER_REVIVE_SECONDS, SKIFF_OUTER_SECONDS)
WIND_UP_TICKS = int(0.8 * TPS)           #: §12.8, one hit per 0.8 s
SKIFF_TICKS = SKIFF_OUTER_SECONDS * TPS  #: §5.4, an outer realm
#: §12.6 (v3.4) called "every 5 seconds of cracking" the guards within "the
#: crack's reach of the Vault, 5 m by the walking path". The owner decided no
#: guard hears the Vault (F35), so the call is off by default (`crack_noise`)
#: and its two figures are sweep settings here, kept so the runs that
#: measured F32 and brief 37 can still be made.
CRACK_NOISE_SECONDS = 5
#: §12.17: "guards within four metres start investigating half a second
#: later" — the alarm's spread, which a Lantern Glare reaches (F33).
SPREAD_METRES = 4
CRACK_NOISE_TICKS = CRACK_NOISE_SECONDS * TPS
CRACK_REACH_METRES = 5
#: v3.3's call reached "every guard in the Heart": a reach no island exceeds.
WHOLE_HEART = 10 ** 6
#: §12.8 (v3.3): a takedown takes two seconds and ends in a knockout if the
#: guard is still Unaware. §12.8 does not say whether a guard walking a patrol
#: keeps walking while it is taken down; if it did, no patrol could ever be
#: taken, so the harness reads the takedown as holding it in place.
TAKEDOWN_TICKS = TAKEDOWN_SECONDS * TPS
#: §11.1 (v3.3): two or more working one object hit a quarter harder. As a
#: ratio of whole numbers, so no float reaches a result.
ASSIST = Fraction(1 + ASSIST_BONUS).limit_denominator(100).as_integer_ratio()
#: §12.17 (v3.3): a crouched crew member moves at half its role's speed, as a
#: ratio of whole numbers so no float reaches a result. Read from
#: design_facts, the fact's one home; a module constant so its effect can be
#: measured by setting it back to (1, 1).
from ..design_facts import CROUCH_PACE as _CROUCH                 # 12.17 (D37)
CROUCH_RATIO = Fraction(_CROUCH).limit_denominator(100).as_integer_ratio()
#: §12.17: Investigating walks to the spot and searches it for ten seconds.
SEARCH_TICKS = 10 * TPS
#: §12.17's states by how alarmed, so a heard event can step a guard up and
#: never down.
RANK = {"unaware": 0, "suspicious": 1, "investigating": 2, "alerted": 3}

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
    #: The guard it is taking down, by index, and how far into the two
    #: seconds it is (§12.8, v3.3).
    takedown: int | None = None
    takedown_ticks: int = 0
    #: The ward it has chosen to disarm and is walking to or standing on
    #: (§10.3, v3.4: "while it disarms, the ward's sensor ignores that crew
    #: member").
    disarming: object = None

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
    #: Where it heard something it is investigating, and how long it has
    #: searched there. The harness has no hearing but this: the Vault's crack.
    heard: tuple | None = None
    search_ticks: int = 0
    #: Knocked out by a takedown (§12.8); whether another guard has found the
    #: body; and whether a takedown is holding it this tick.
    down: bool = False
    found: bool = False
    held: bool = False


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
    #: Guards taken down, and bodies another guard found (§12.8, v3.3).
    knockouts: int = 0
    bodies_found: int = 0

    @property
    def success(self) -> bool:
        return self.grade in ("clean", "loud", "partial")

    @property
    def last_ten_decided(self) -> bool:
        return self.grade != self.grade_ten_seconds_earlier


from ..design_facts import GRADE_VALUE             # 12.9 (D37)


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
                 clock_pct: int = 100, exposed_pct: int = 100,
                 crack_noise: bool | None = None, crack_reach: int | None = None,
                 crack_seconds: int | None = None, disarm_approach: bool = False,
                 glare_realm: bool | None = None):
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
        #: §12.6's crack noise (v3.3). On is the document. Off is an ablation,
        #: like `response`: F32 is that with it on, the noise decides nearly
        #: every raid these crews play, so a question about any other layer is
        #: asked with it off and says so.
        self.crack_noise = crack_noise
        #: A Lantern Glare's reach: the whole realm, as §10.3 states and the
        #: v3.2 and v3.3 heists were measured, or the alarm's 4 m the owner
        #: decided (F33) under the current rules. None is the island's rules'
        #: own, as with the crack's reach; F33's evidence asks for the realm.
        self.glare_realm = glare_realm
        #: Which document's wards the Heart was built to (island.RULES). The
        #: v3.3 rules the harness also plays by — the assist bonus — follow
        #: it, so a v3.2 island is the v3.2 heist it was measured on.
        self.rules = getattr(island, "rules", "v3.4")
        #: §12.6 (v3.4): the crack calls the guards within this many metres of
        #: the Vault by the walking path. None is the rules' own — 5 m under
        #: v3.4, the whole Heart before it — and brief 37's sweep sets it.
        self.crack_reach = (crack_reach if crack_reach is not None
                            else WHOLE_HEART if self.rules in ("v3.2", "v3.3")
                            else CRACK_REACH_METRES)
        self._heard_from_vault = None
        if self.glare_realm is None:
            self.glare_realm = self.rules in ("v3.2", "v3.3")
        # The crack's call likewise: the document's at v3.2 and v3.3, which
        # those heists were measured with, and off under the current rules,
        # where the owner decided no guard hears the Vault (F35).
        if self.crack_noise is None:
            self.crack_noise = self.rules in ("v3.2", "v3.3")
        #: How often the call sounds: §12.6's five seconds, or brief 37's
        #: fallback of ten with the whole Heart.
        self.crack_every = (crack_seconds * TPS if crack_seconds
                            else CRACK_NOISE_TICKS)
        for isl in self.islands:
            for w in isl.wards:
                w.approach = disarm_approach
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
        self.knockouts = 0
        self.bodies_found = 0

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
        if g.held:
            return                        # being taken down: it does not walk on
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
        # §12.8 (v3.3): a body is seen as a still crew member lying on its tile
        # would be, so cover hides it; the first guard to see it raises the
        # realm alarm by one. The harness has no realm alarm, so it counts.
        reach_body = self.sheet.factor("sight_range") * post_sight(g.level)
        for other in self.guards:
            if not other.down or other.found:
                continue
            if self.island.hides(other.x // U, other.y // U):
                continue
            if (zone(g.role, g.x, g.y, g.facing, other.x, other.y, reach=reach_body)
                    and line_of_sight(self.island, g.x, g.y, other.x, other.y)):
                other.found = True
                self.bodies_found += 1
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
        # A heard spot holds Investigating until it has been searched.
        if g.heard is not None:
            if dist2(g.x, g.y, *g.heard) <= (U // 2) ** 2:
                g.search_ticks += 1
            if g.search_ticks >= SEARCH_TICKS:
                g.heard, g.search_ticks = None, 0
            elif RANK[want] < RANK["investigating"]:
                want = "investigating"
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
        # §12.17 (v3.3, G13): "crouched, a crew member moves at half its
        # role's speed (11.1), and running, at double". The harness has two
        # gaits, not three; before v3.3 its crouch was §11.1's full speed.
        step = (max(1, m.step * CROUCH_RATIO[0] // CROUCH_RATIO[1]) if m.crouched
                else m.step * 2)
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
                # §10.3 (v3.4, G16): "while it disarms, the ward's sensor
                # ignores that crew member" — on the ward's tile, having chosen
                # to. G18's generous reading ignores the walk there too.
                if w.rules not in ("v3.2", "v3.3") and m.disarming is w:
                    here = (m.x // U, m.y // U) == (w.x, w.y)
                    going = bool(m.path) and m.path[-1] == (w.x, w.y)
                    if here or (w.approach and going):
                        continue
                # §10.3 (v3.3): Time Snare on its tile, Gravity Well within 3
                # tiles and Lantern Glare within 2 — tile centres, straight line.
                cx, cy = w.x * U + U // 2, w.y * U + U // 2
                if w.reach == 0:
                    if (m.x // U, m.y // U) != (w.x, w.y):
                        continue
                elif dist2(m.x, m.y, cx, cy) > (w.reach * U) ** 2:
                    continue
                scale = 100 + 15 * (w.level - 1)
                if w.kind == "Time Snare":
                    m.frozen_ticks = int(2.5 * TPS) * scale // 100
                elif w.kind == "Gravity Well":
                    # "Pulls everyone within 3 tiles to its centre" — the harness
                    # pulls the first, which is the one whose route it breaks.
                    if w.reach:                            # v3.2: no pull
                        m.x, m.y, m.path = cx, cy, []
                    m.frozen_ticks = 2 * TPS * scale // 100
                elif w.kind == "Lantern Glare":
                    # Shows the crew for 5 s to every guard within the alarm's
                    # spread reach of it, 4 m by the sheet's alarm range (F33,
                    # decided; §10.3 says "every guard in the realm").
                    reach = SPREAD_METRES * self.sheet.factor("alarm_range") * U
                    for g in self.guards:
                        if self.glare_realm or dist2(g.x, g.y, cx, cy) <= reach * reach:
                            g.suspicion = ALERTED
                w.spent = True
                w.reset_at = self.tick + w.reset_ticks
                self.wards_triggered += 1
                break

    def _capture_check(self) -> None:
        if not self.response:
            return
        for g in self.guards:
            if g.down or g.state != "alerted":
                continue
            for m in self.crew:
                if m.out or m.caught:
                    continue
                if dist2(g.x, g.y, m.x, m.y) <= (U * 3 // 4) ** 2:
                    m.down_ticks += 1
                    if m.down_ticks >= DOWN_SECONDS * TPS:      # §12.20
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
                need = int((MENDER_REVIVE_SECONDS if helper.role == "Mender"
                            else REVIVE_SECONDS) * TPS)
                if m.revive_ticks >= need:
                    m.down_ticks = m.revive_ticks = 0
                continue
            m.revive_ticks = 0
            near = any(not g.down and g.state == "alerted"
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

    def _takedowns(self) -> None:
        """§12.8 (v3.3): a takedown on an Unaware guard, from beside it, takes
        two seconds in which the attacker does nothing else, and knocks the
        guard out if it is still Unaware when it lands. A guard that notices
        first is not knocked out; the harness has no fights, so the attempt
        simply fails with the guard now aware at arm's length."""
        for g in self.guards:
            g.held = False
        for m in self.crew:
            if m.takedown is None:
                continue
            g = self.guards[m.takedown] if m.takedown < len(self.guards) else None
            beside = (g is not None and not g.down
                      and dist2(g.x, g.y, m.x, m.y) <= (U * 3 // 2) ** 2)
            if (not beside or m.out or m.caught or m.down_ticks
                    or (m.takedown_ticks == 0 and g.state != "unaware")):
                m.takedown, m.takedown_ticks = None, 0
                continue
            g.held = True
            m.takedown_ticks += 1
            if m.takedown_ticks < TAKEDOWN_TICKS:
                continue
            if g.state == "unaware":
                g.down, g.held = True, False
                g.state, g.heard, g.target = "unaware", None, None
                self.knockouts += 1
            m.takedown, m.takedown_ticks = None, 0

    def crackers(self) -> int:
        """How many are working the Vault now, for the assist bonus."""
        if self.vault_open or self.island is not self.target:
            return 0
        vx, vy = self.island.vault
        return sum(1 for m in self.crew
                   if not (m.out or m.caught or m.down_ticks or self.escaping)
                   and max(abs(m.x // U - vx), abs(m.y // U - vy)) <= 1)

    def _within_crack_reach(self) -> set:
        """The tiles within the crack's reach of the Vault by the walking path
        (§12.6, v3.4): breadth-first from the Vault over walkable tiles, the
        same four-neighbour graph the crew routes on. One tile is one metre
        (§21.1)."""
        if self._heard_from_vault is None:
            island = self.target
            start = tuple(island.vault)
            seen, frontier = {start: 0}, [start]
            while frontier:
                nxt = []
                for cur in frontier:
                    if seen[cur] >= self.crack_reach:
                        continue
                    for dx, dy in ((0, -1), (-1, 0), (1, 0), (0, 1)):
                        n = (cur[0] + dx, cur[1] + dy)
                        if n not in seen and island.walkable(*n):
                            seen[n] = seen[cur] + 1
                            nxt.append(n)
                frontier = nxt
            self._heard_from_vault = set(seen)
        return self._heard_from_vault

    def _crack_noise(self) -> None:
        """§12.6: every five seconds of cracking, the guards within the crack's
        reach hear the Vault and start Investigating it — v3.4's 5 m by the
        walking path, v3.3's whole Heart. A heard event steps a guard up to
        Investigating and never down, and re-aims one that is already
        investigating something else."""
        if (not self.crack_noise or self.crack_started_at is None or self.vault_open
                or self.island is not self.target):
            return
        since = self.tick - self.crack_started_at
        if since <= 0 or since % self.crack_every:
            return
        vx, vy = self.target.vault
        spot = (vx * U + U // 2, vy * U + U // 2)
        near = (None if self.crack_reach >= WHOLE_HEART
                else self._within_crack_reach())
        for g in self.guards:
            if g.down or RANK[g.state] > RANK["investigating"]:
                continue
            if near is not None and (g.x // U, g.y // U) not in near:
                continue
            g.heard, g.target, g.search_ticks = spot, spot, 0
            if g.state != "investigating":
                g.state, g.state_ticks = "investigating", 0

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
                if g.down:
                    continue
                self._guard_move(g)
                self._perceive(g)
            self._wards()
            if self._cross():
                self.tick += TPS            # §12.6's one-second swoop
                continue
            self.decisions += self.policy.act(self)
            self._takedowns()
            self._respond()
            self._crack_noise()
            for m in self.crew:
                moving = bool(m.path) and not m.wait_ticks and not m.frozen_ticks
                m.still_ticks = 0 if moving else m.still_ticks + 1
                if m.frozen_ticks:
                    m.frozen_ticks -= 1
                    continue
                if not m.out and not m.caught and m.down_ticks == 0 \
                        and m.wait_ticks == 0 and m.disarm_ticks == 0 \
                        and m.takedown_ticks == 0:
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
            knockouts=self.knockouts, bodies_found=self.bodies_found,
        )
