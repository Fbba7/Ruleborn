"""Integer arithmetic, so a run is a function of its seed and nothing else.

§24.7 requires that no floating point decides a result. This module is the whole
of the arithmetic the harness uses, kept in one place so that claim is checkable
by reading one file rather than trusting every other one.

Units
-----
Position   1/256 of a tile, as `int`. A tile is one metre (§12.18).
Angle      1/1024 of a turn, as `int`. §12.17 gives turn rates in degrees per
           tick; 1024 divides evenly enough that 3, 4, 6 and 8 degrees a tick
           are exact within a unit.
Time       ticks at 30 Hz (§24.10).
"""

U = 256               #: position units per tile
TURN = 1024           #: angle units per full turn
TPS = 30              #: ticks per second (§24.10)

#: sin(theta) x 1024, for theta in angle units, quarter table.
_SIN = [round(__import__("math").sin(2 * __import__("math").pi * i / TURN) * 1024)
        for i in range(TURN)]


def sin(a: int) -> int:
    return _SIN[a % TURN]


def cos(a: int) -> int:
    return _SIN[(a + TURN // 4) % TURN]


def degrees(d: float) -> int:
    """Angle units from degrees, rounded once, at load time."""
    return int(round(d * TURN / 360))


def tiles(t: float) -> int:
    """Position units from tiles, rounded once, at load time."""
    return int(round(t * U))


def isqrt(n: int) -> int:
    return __import__("math").isqrt(n)


def dist2(ax: int, ay: int, bx: int, by: int) -> int:
    """Squared distance, in position units. Squared, so no root is taken."""
    dx, dy = ax - bx, ay - by
    return dx * dx + dy * dy


def angle_to(ax: int, ay: int, bx: int, by: int) -> int:
    """Bearing from a to b, in angle units.

    atan2 is floating point, so the result is rounded to an integer immediately
    and never used as a float. It is a lookup, not a decision: what the angle
    feeds is an integer comparison against a cone width.
    """
    import math
    return int(round(math.atan2(by - ay, bx - ax) * TURN / (2 * math.pi))) % TURN


def angle_diff(a: int, b: int) -> int:
    """Smallest absolute difference between two bearings, in angle units."""
    d = (a - b) % TURN
    return min(d, TURN - d)


def turn_toward(current: int, target: int, rate: int) -> int:
    """Rotate `current` toward `target` by at most `rate` units."""
    d = (target - current) % TURN
    if d > TURN // 2:
        d -= TURN
    if d > rate:
        d = rate
    elif d < -rate:
        d = -rate
    return (current + d) % TURN


class Rng:
    """SplitMix64, as §24.7 specifies for seeding.

    The harness uses it only to lay out islands and to pick patrol phases. No
    result inside a run depends on it, which is the property §12.17 asks for:
    "nothing here is random: a player who scouts an island can predict exactly
    what will happen".
    """

    MASK = (1 << 64) - 1

    def __init__(self, seed: int) -> None:
        self.state = seed & self.MASK

    def next(self) -> int:
        self.state = (self.state + 0x9E3779B97F4A7C15) & self.MASK
        z = self.state
        z = ((z ^ (z >> 30)) * 0xBF58476D1CE4E5B9) & self.MASK
        z = ((z ^ (z >> 27)) * 0x94D049BB133111EB) & self.MASK
        return z ^ (z >> 31)

    def below(self, n: int) -> int:
        return self.next() % n

    def choice(self, items):
        return items[self.below(len(items))]
