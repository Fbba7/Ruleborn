"""§12.17's perception model, as integers at 30 Hz.

Everything here comes from `content/detection.json`, which was extracted from the
document rather than transcribed, so re-tuning §12.17 re-tunes the harness.
"""

import json
import pathlib

from .fixed import TURN, U, angle_diff, angle_to, degrees, dist2, tiles

ROOT = pathlib.Path(__file__).resolve().parent.parent.parent
DETECTION = json.loads((ROOT / "content" / "detection.json").read_text(encoding="utf-8"))

SUS_MAX = DETECTION["suspicion"]["max"]
FILL = DETECTION["suspicion"]["fill_per_tick"]          # near / mid / far
DECAY = DETECTION["suspicion"]["decay_per_tick"]
STATE_FLOOR_TICKS = DETECTION["suspicion"]["state_floor_ticks"]

STATE_AT = {s["id"]: s["at"] for s in DETECTION["states"] if s["at"] is not None}
SUSPICIOUS = STATE_AT["suspicious"]
INVESTIGATING = STATE_AT["investigating"]
ALERTED = STATE_AT["alerted"]

#: Per guard role, already in integer units.
VISION = {}
for g in DETECTION["guards"]:
    VISION[g["role"]] = dict(
        cone=degrees(g["cone_degrees"]) // 2,            # half-width
        peripheral=degrees(g["peripheral_degrees"]) // 2,
        near=tiles(g["near_m"]) ** 2,
        mid=tiles(g["mid_m"]) ** 2,
        far=tiles(g["far_m"]) ** 2 if g["far_m"] else 0,
        turn=degrees(g["turn_degrees_per_tick"]),
    )
    # The furthest this role can see anything, precomputed: `zone` is the
    # harness's hottest function and most of its calls are a miss.
    VISION[g["role"]]["outer"] = max(VISION[g["role"]]["mid"],
                                     VISION[g["role"]]["far"])

#: §12.17's modifiers, as numerator/denominator so the arithmetic stays integer.
CROUCH = (1, 2)          # crouched halves how fast you are noticed
RUN = (7, 4)             # running raises it by three quarters
UNLIT = (1, 2)           # an unlit tile halves it again

#: The corner of the eye, from the content file rather than typed here: the
#: zone's own rate, halved (spec/detection.md). D55 — the harness used to give
#: the far zone's rate at any distance, a second reading of one sentence.
_PERIPHERAL = next(m["multiplier"] for m in DETECTION["modifiers"]
                   if m["id"] == "peripheral")
PERIPHERAL = (round(_PERIPHERAL * 4), 4)


def line_of_sight(island, ax: int, ay: int, bx: int, by: int) -> bool:
    """Whether b is visible from a, in position units, blocked per tile (§6.2).

    A supercover walk over the tiles the segment crosses: deterministic, integer,
    and symmetric, which matters because a replay is re-simulated server-side.
    """
    x0, y0 = ax // U, ay // U
    x1, y1 = bx // U, by // U
    dx, dy = abs(x1 - x0), abs(y1 - y0)
    x, y = x0, y0
    n = dx + dy
    x_inc = 1 if x1 > x0 else -1
    y_inc = 1 if y1 > y0 else -1
    error = dx - dy
    dx *= 2
    dy *= 2
    for _ in range(n):
        if (x, y) != (x0, y0) and island.blocks_sight(x, y):
            return False
        if error > 0:
            x += x_inc
            error -= dy
        else:
            y += y_inc
            error += dx
    return True


def zone(role: str, gx: int, gy: int, facing: int, tx: int, ty: int,
         reach: float = 1.0) -> str | None:
    """Which of a guard's three zones a point falls in, or None.

    Outside the cone but inside the peripheral arc, §12.17 gives "weak peripheral
    awareness". `content/detection.json` reads that as the same zones at half
    the rate, and so does `sim/`; the zone comes back prefixed "p:" so
    `fill_rate` can halve it. The harness used to answer the far zone's rate at
    any distance — a second reading of the same sentence (D55).
    """
    v = VISION[role]
    d2 = dist2(gx, gy, tx, ty)
    # §7.3: a law scales a parameter. Ranges are squared here, so a multiplier
    # on distance is its square on the comparison — done once, in integers.
    #
    # The unscaled case is separated out and the distance is tested first because
    # this function runs once per guard per crew member per tick and returns None
    # on most of them. `int(n * 1.0) == n` for the integer ranges in VISION, so
    # the two branches are the same arithmetic.
    if reach == 1.0:
        if d2 > v["outer"]:
            return None
        near, mid, far = v["near"], v["mid"], v["far"]
    else:
        scale = reach * reach
        near, mid, far = (int(v["near"] * scale), int(v["mid"] * scale),
                          int(v["far"] * scale))
        if d2 > max(far, mid):
            return None
    off = angle_diff(facing, angle_to(gx, gy, tx, ty))
    if off <= v["cone"]:
        if d2 <= near:
            return "near"
        if d2 <= mid:
            return "mid"
        if far and d2 <= far:
            return "far"
        return None
    if off <= v["peripheral"] and d2 <= max(mid, far):
        if d2 <= near:
            return "p:near"
        if d2 <= mid:
            return "p:mid"
        return "p:far"
    return None


def fill_rate(zone_name: str, crouched: bool, running: bool, hidden: bool,
              unlit: bool) -> int:
    """How much suspicion one tick in that zone adds.

    §12.17: "standing still in tall grass makes you invisible until a guard walks
    into the tile", which is the `hidden` case and returns nothing at all.
    """
    if hidden:
        return 0
    peripheral = zone_name.startswith("p:")
    rate = FILL[zone_name[2:] if peripheral else zone_name]
    if peripheral:
        rate = rate * PERIPHERAL[0] // PERIPHERAL[1]
    if crouched:
        rate = rate * CROUCH[0] // CROUCH[1]
    if running:
        rate = rate * RUN[0] // RUN[1]
    if unlit:
        rate = rate * UNLIT[0] // UNLIT[1]
    return max(1, rate)
