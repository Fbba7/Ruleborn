#!/usr/bin/env python3
"""The motion shots' scripted checks (P2-AIA-motion-2; report.md 3.5).

    python3 art/ui/motion/check_frames.py <frames-root>

<frames-root> holds one folder per run of art/ui/motion/strips.sh, each with
the run's frames (f000.png...) and log.json (client/tests/shots/motion_rig.gd).
Godot ran the shots at --fixed-fps 60, so frame k is k/60 s after the motion
starts. A motion triggered after frame F is shot has t = (k - F) / 60 s at
frame k; frame 0 is the rest before the first trigger.

Every expected value is worked out from art/ui/motion/curves.json, the
source the kit's motion code reads, not from numbers copied here:

  timing    each measured value (press travel, scale and brightness; the
            prize's scale, brightness and rise; the counter's value and
            pulse; the shine band's place and alpha; the screens' alpha and
            scale) matches its step's cubic_out curve at t = k/60, within
            TOL. Matching every frame also proves nothing overshoots its end
            value or runs backwards.
  gather    the reward's anticipation is a gather, not a still pause: no
            sprite is lit before the tier's first gather step (a payoff
            step with a negative at_ms) starts, and no stretch of the
            anticipation longer than GATHER_STILL_MS shows the same image
            frame after frame.
  settle    once the last step has ended, every frame is the same image as
            the last one (nothing left drawn, nothing still moving). The
            shine is checked between sweeps against its rest frame.
  reduced   the reduced forms: the press sinks and darkens with no squash;
            the reward has no anticipation or burst, one coin, and the
            counter jumps from its old value to its new one at counter_set's
            time; the shine draws nothing (every frame equals frame 0); the
            screen change is a cross-fade with no scale. High contrast draws
            no shine either.
  flashes   no more than rules.flash_hz_most flashes in any one second. A
            flash is a pair of opposing changes in relative luminance of
            0.1 or more where the darker side is below 0.8 (the WCAG 2.x
            general-flash measure), taken over the whole frame and over each
            tile of a 4 x 4 grid (a far smaller area than WCAG's quarter of
            the central field, so a stricter test).

It prints one line per check and run, and exits 1 if any fails.
"""

import glob
import json
import math
import os
import sys

import numpy as np
from PIL import Image

HERE = os.path.dirname(os.path.abspath(__file__))
TOL = 0.004          # measured against expected, in the measured unit
TOL_PX = 1.01        # for positions in pixels
FLASH_STEP = 0.1     # WCAG: a change of 10% of the maximum relative luminance
FLASH_DARK = 0.8     # WCAG: ... where the darker image is below 0.80
GRID = 4
GATHER_STILL_MS = 150  # the longest still stretch the reward's anticipation may hold

failures = []


def co(t):
    """cubic_out on 0..1, clamped."""
    t = min(1.0, max(0.0, t))
    return 1.0 - (1.0 - t) ** 3


def report(run, name, problems):
    if problems:
        failures.append((run, name))
        print(f"FAIL {run}: {name}: {problems[0]}" + (f" (+{len(problems) - 1} more)" if len(problems) > 1 else ""))
    else:
        print(f"ok   {run}: {name}")


def track(steps, t, rest, edge=False):
    """The value a property takes at t ms when `steps` (start_ms, ms, from,
    to) run on it in turn: the latest started step's curve, or `rest` before
    any. edge=True treats a step starting exactly at t as not yet started (a
    frame on a step's first instant may show either side)."""
    v = rest
    for start, ms, a, b in sorted(steps, key=lambda s: s[0]):
        if t > start or (t == start and not edge):
            v = a + (b - a) * co((t - start) / ms) if ms > 0 else b
    return v


def near(measured, steps, t, rest, tol=TOL):
    """Whether `measured` is `track`'s value at t (either side of a step's
    first instant)."""
    return any(abs(measured - track(steps, t, rest, edge)) <= tol for edge in (False, True))


def t_ms(frame, trigger=0):
    return (frame - trigger) * 1000.0 / 60.0


def first_frame_after(ms, trigger=0):
    """The first frame shot at or after `ms` from the trigger."""
    return trigger + math.ceil(ms * 60.0 / 1000.0 - 1e-9)


def steps_of(lst, prop, target=None, shift=0.0, sub=None):
    out = []
    for s in lst:
        if s.get("property") != prop or (target and s.get("target") != target):
            continue
        a, b = s["from"], s["to"]
        if sub:
            a, b = sub(a), sub(b)
        out.append((shift + s["at_ms"], s["ms"], float(a), float(b)))
    return out


def frames(run_dir, n):
    return [np.asarray(Image.open(os.path.join(run_dir, f"f{k:03d}.png")).convert("RGB"), dtype=np.int16)
            for k in range(n)]


def same(a, b):
    return int(np.abs(a - b).max()) <= 1


def settle_check(run, imgs, from_frame):
    last = imgs[-1]
    bad = [f"frame {k} differs from the last frame" for k in range(from_frame, len(imgs)) if not same(imgs[k], last)]
    if from_frame >= len(imgs):
        bad = [f"the run ends at frame {len(imgs) - 1}, before the motion settles at frame {from_frame}"]
    report(run, f"settle (frames {from_frame}..{len(imgs) - 1} still)", bad)


def luminance(img):
    c = img.astype(np.float64) / 255.0
    lin = np.where(c <= 0.04045, c / 12.92, ((c + 0.055) / 1.055) ** 2.4)
    return lin[..., 0] * 0.2126 + lin[..., 1] * 0.7152 + lin[..., 2] * 0.0722


def transitions(series):
    """Frames where the luminance turns by FLASH_STEP or more (a zigzag over
    the series), each with the darker side below FLASH_DARK."""
    out = []
    lo = hi = series[0]
    direction = 0
    ext = series[0]
    for k, v in enumerate(series[1:], 1):
        if direction == 0:
            lo, hi = min(lo, v), max(hi, v)
            if v - lo >= FLASH_STEP and lo < FLASH_DARK:
                direction, ext = 1, v
                out.append(k)
            elif hi - v >= FLASH_STEP and v < FLASH_DARK:
                direction, ext = -1, v
                out.append(k)
        elif direction == 1:
            if v > ext:
                ext = v
            elif ext - v >= FLASH_STEP and v < FLASH_DARK:
                direction, ext = -1, v
                out.append(k)
        else:
            if v < ext:
                ext = v
            elif v - ext >= FLASH_STEP and ext < FLASH_DARK:
                direction, ext = 1, v
                out.append(k)
    return out


def flash_check(run, imgs, most):
    lums = [luminance(i) for i in imgs]
    h, w = lums[0].shape
    areas = [("whole frame", slice(0, h), slice(0, w))]
    for r in range(GRID):
        for c in range(GRID):
            areas.append((f"tile {r},{c}", slice(r * h // GRID, (r + 1) * h // GRID),
                          slice(c * w // GRID, (c + 1) * w // GRID)))
    bad = []
    worst = 0
    for label, ys, xs in areas:
        series = [float(l[ys, xs].mean()) for l in lums]
        tr = transitions(series)
        for i, k in enumerate(tr):
            # flashes (pairs of opposing changes) within one second of frame k
            within = [j for j in tr[i:] if j - k < 60]
            flashes = len(within) // 2
            worst = max(worst, flashes)
            if flashes > most:
                bad.append(f"{label}: {flashes} flashes in the second from frame {k}")
                break
    report(run, f"flashes (at most {most} a second; most found {worst})", bad)


# ---- the motions ----------------------------------------------------------

def check_press(run, log, curves, imgs):
    form = log["form"]
    m = curves["press"][form]
    rel = log["release_frame"] - 1          # the release runs after this frame is shot
    travel = max(s["to"] for s in m["down"] if s["property"] == "travel_points")
    props = {"press": "travel_points", "scale": "scale", "value": "self_modulate_value"}
    bad = []
    for row in log["frames"]:
        t = t_ms(row["frame"])
        for key, prop in props.items():
            steps = steps_of(m["down"], prop) + steps_of(m["up"], prop, shift=t_ms(rel))
            rest = 1.0 if prop != "travel_points" else 0.0
            scale = travel if prop == "travel_points" else 1.0
            for button in ("gold", "leather"):
                got = row[button][key] * scale
                if not near(got, steps, t, rest, TOL * scale):
                    bad.append(f"frame {row['frame']} {button} {key} {got:.4f}, curve "
                               f"{track(steps, t, rest):.4f}")
    report(run, "timing (sink, squash, darken; release)", bad)
    if form == "reduced":
        bad = [f"frame {r['frame']} {b} scale {r[b]['scale']}" for r in log["frames"] for b in ("gold", "leather")
               if abs(r[b]["scale"] - 1.0) > 1e-6]
        low = min(r["gold"]["value"] for r in log["frames"])
        darken = [s for s in m["down"] if s["property"] == "self_modulate_value"][0]["to"]
        if abs(low - darken) > TOL:
            bad.append(f"darkest {low:.4f}, the reduced form darkens to {darken}")
        report(run, "reduced (no squash; darkens to %s)" % darken, bad)
    end = max(s["at_ms"] + s["ms"] for s in m["up"])
    settle_check(run, imgs, first_frame_after(end, rel))


def check_reward(run, log, curves, imgs):
    form = log["form"]
    ppp = log["px_per_point"]
    rest_y = log["rest_y"]
    frm, to = log["from"], log["to"]
    rows = log["frames"]
    if form == "full":
        f = curves["reward"]["full"]
        tier = f["tiers"][log["tier"]]

        def sub(v):
            return tier[v.split(".", 1)[1]] if isinstance(v, str) and v.startswith("tier.") else v

        A = tier["anticipation_ms"]
        ant = []
        for s in f["anticipation"]:
            s = dict(s)
            if s.get("ends_at") == "burst":
                s["at_ms"] = A - s["ms"]
            ant.append(s)
        pay = f["payoff"]
        scale = steps_of(ant, "scale", "prize") + steps_of(pay, "scale", "prize", shift=A)
        value = steps_of(ant, "self_modulate_value", "prize") + steps_of(pay, "self_modulate_value", "prize", shift=A)
        rise = [(A + s["at_ms"], s["ms"], rest_y + int(s["from"] * ppp), rest_y + int(s["to"] * ppp))
                for s in pay if s["target"] == "prize" and s["property"] == "offset_points"]
        fly = [s for s in pay if s["name"] == "coins_fly"][0]
        coins = min(8, to - frm)
        lands = [A + fly["at_ms"] + i * fly["stagger_ms"] + fly["ms"] for i in range(coins)]
        roll = [s for s in f["on_landing"] if s["name"] == "counter_roll"][0]["ms"]
        up = [s for s in f["on_landing"] if s["name"] == "counter_pulse_up"][0]
        down = [s for s in f["on_landing"] if s["name"] == "counter_pulse_down"][0]
        pulse_end = lands[-1] + down["at_ms"] + down["ms"]
        def plays(s):
            n = sub(s.get("count", 1))
            return not isinstance(n, (int, float)) or n > 0

        lit_from = min([A] + [A + s["at_ms"] for s in pay if s["target"] == "burst" and plays(s)])
        bad = []
        for r in rows:
            t, p, c = t_ms(r["frame"]), r["prize"], r["counter"]
            if not near(p["scale"], scale, t, 1.0):
                bad.append(f"frame {r['frame']} prize scale {p['scale']:.4f}, curve {track(scale, t, 1.0):.4f}")
            if not near(p["value"], value, t, 1.0):
                bad.append(f"frame {r['frame']} prize brightness {p['value']:.4f}, curve {track(value, t, 1.0):.4f}")
            if not near(p["y"], rise, t, rest_y, TOL_PX):
                bad.append(f"frame {r['frame']} prize y {p['y']:.2f}, curve {track(rise, t, rest_y):.2f}")
            if abs(p["alpha"] - 1.0) > 1e-6:
                bad.append(f"frame {r['frame']} prize alpha {p['alpha']}")
            started = sum(1 for x in lands if x < t)
            done = sum(1 for x in lands if x + roll <= t)
            if not frm + done <= c["value"] <= frm + started:
                bad.append(f"frame {r['frame']} counter {c['value']}, between {frm + done} and {frm + started} "
                           f"by the landings")
            if not 1.0 - TOL <= c["scale"] <= up["to"] + TOL:
                bad.append(f"frame {r['frame']} counter scale {c['scale']:.4f}, outside 1..{up['to']}")
            if t >= pulse_end + 1000 / 60 and abs(c["scale"] - 1.0) > TOL:
                bad.append(f"frame {r['frame']} counter scale {c['scale']:.4f} after the last pulse")
            if t < lit_from and r["lit"]:
                bad.append(f"frame {r['frame']}: {r['lit']} sprites lit before the gather's first step at "
                           f"{lit_from} ms")
        values = [r["counter"]["value"] for r in rows]
        if any(b < a for a, b in zip(values, values[1:])):
            bad.append("the counter runs backwards")
        if values[-1] != to:
            bad.append(f"the counter ends at {values[-1]}, not {to}")
        want = 2 + tier["sparkles"] + tier["dust"] + coins
        got = max(r["sprites"] for r in rows)
        if got != want:
            bad.append(f"{got} sprites in the layer, the tier wants {want} (rays, ring, "
                       f"{tier['sparkles']} sparkles, {tier['dust']} dust, {coins} coins)")
        if rows[-1]["layer"]:
            bad.append("the reward's layer is still there at the end")
        report(run, f"timing ({log['tier']}: {A} ms anticipation, burst, reveal, {coins} landings, pulses)", bad)
        still, longest, bad = 0, 0, []
        for k in range(2, len(imgs)):
            if t_ms(k) > A:
                break
            still = still + 1 if same(imgs[k], imgs[k - 1]) else 0
            longest = max(longest, still)
        if longest * 1000 / 60 > GATHER_STILL_MS:
            bad.append(f"the anticipation holds still for {longest} frames ({longest * 1000 / 60:.0f} ms)")
        report(run, f"gather (sprites lit from {lit_from} ms; still at most {GATHER_STILL_MS} ms of the "
                    f"{A} ms anticipation; longest {longest * 1000 / 60:.0f} ms)", bad)
        end = max([pulse_end] + [A + s["at_ms"] + s["ms"] + s.get("stagger_ms", 0) * (sub(s.get("count", 1)) - 1)
                                 for s in pay if s["target"] == "burst" or s["target"] == "prize"])
        settle_check(run, imgs, first_frame_after(end) + 1)
    else:
        steps = curves["reward"]["reduced"]["steps"]
        fade = steps_of(steps, "alpha", "prize")
        setting = [s for s in steps if s["name"] == "counter_set"][0]["at_ms"]
        jump = first_frame_after(setting)
        bad = []
        for r in rows:
            t, p, c = t_ms(r["frame"]), r["prize"], r["counter"]
            if r["frame"] > 0 and not near(p["alpha"], fade, t, 0.0):
                bad.append(f"frame {r['frame']} prize alpha {p['alpha']:.4f}, curve {track(fade, t, 0.0):.4f}")
            if abs(p["scale"] - 1) > 1e-6 or abs(p["value"] - 1) > 1e-6 or abs(p["y"] - rest_y) > 0.01:
                bad.append(f"frame {r['frame']}: the prize moves (scale {p['scale']}, brightness {p['value']}, "
                           f"y {p['y']})")
            if abs(c["scale"] - 1) > 1e-6:
                bad.append(f"frame {r['frame']}: the counter pulses ({c['scale']})")
            want = frm if r["frame"] < jump else to
            if c["value"] != want:
                bad.append(f"frame {r['frame']} counter {c['value']}, wanted {want} (set at {setting} ms)")
            if r["sprites"] > 1:
                bad.append(f"frame {r['frame']}: {r['sprites']} sprites, the reduced form keeps one coin")
        if not any(r["lit"] for r in rows):
            bad.append("no coin lands")
        report(run, f"reduced (no anticipation or burst; prize fades in; one coin; counter set at {setting} ms)", bad)
        end = max(s["at_ms"] + s["ms"] for s in steps)
        settle_check(run, imgs, first_frame_after(end) + 1)


def check_shine(run, log, curves, imgs):
    rows = log["frames"]
    off = log["form"] == "reduced" or log["high_contrast"]
    if off:
        bad = [f"frame {r['frame']}: a band is drawn" for r in rows if r["layer"] or r["shown"]]
        bad += [f"frame {k} differs from frame 0" for k in range(1, len(imgs)) if not same(imgs[k], imgs[0])]
        why = "reduced: none" if log["form"] == "reduced" else "high contrast: none"
        report(run, f"{'reduced' if log['form'] == 'reduced' else 'high contrast'} ({why}; every frame is the rest)",
               bad)
        return
    s = curves["shine"]["full"]
    first, period = s["first_wait_ms"], s["period_ms"]
    sweep = [x for x in s["steps"] if x["property"] == "x_fraction"][0]
    fade = [x for x in s["steps"] if x["property"] == "alpha"][0]
    span = max(x["at_ms"] + x["ms"] for x in s["steps"])
    bad = []
    quiet = []
    cycles = 0
    for r in rows:
        t = t_ms(r["frame"])
        j = math.floor((t - first) / period) if t >= first else -1
        local = t - first - j * period if j >= 0 else -1
        if 0 < local <= span:
            if local < 1000 / 60:
                cycles += 1
            x = sweep["from"] + (sweep["to"] - sweep["from"]) * co(local / sweep["ms"])
            a = fade["from"] if local <= fade["at_ms"] else \
                fade["from"] + (fade["to"] - fade["from"]) * co((local - fade["at_ms"]) / fade["ms"])
            if abs(r["x"] - x * r["width"]) > TOL_PX or abs(r["alpha"] - a) > TOL:
                bad.append(f"frame {r['frame']}: band at {r['x']:.1f} px, alpha {r['alpha']:.3f}; curve "
                           f"{x * r['width']:.1f} px, alpha {a:.3f}")
            if r["alpha"] > fade["from"] + TOL:
                bad.append(f"frame {r['frame']}: band alpha {r['alpha']:.3f} above {fade['from']}")
        elif local != 0:
            if r["shown"]:
                bad.append(f"frame {r['frame']}: a band shows at {t:.0f} ms, outside the sweeps")
            quiet.append(r["frame"])
    runs_for = (rows[-1]["t_ms"] - first) // period + 1
    if cycles != runs_for:
        bad.append(f"{cycles} sweeps, wanted {int(runs_for)} (first at {first} ms, then every {period} ms)")
    report(run, f"timing (first sweep at {first} ms, again every {period} ms; {cycles} sweeps)", bad)
    bad = [f"frame {k} differs from the rest frame between sweeps" for k in quiet if not same(imgs[k], imgs[0])]
    report(run, f"settle (all {len(quiet)} frames between sweeps are the rest)", bad)


def check_screen(run, log, curves, imgs):
    form = log["form"]
    m = curves["screen"][form]
    in_a = steps_of(m["in"], "alpha", "new_screen")
    in_s = steps_of(m["in"], "scale", "new_screen")
    out_a = steps_of(m.get("out", []), "alpha", "old_screen")
    bad = []
    for r in log["frames"]:
        t, o, n = t_ms(r["frame"]), r["old"], r["new"]
        want_new = track(in_a, t, 0.0)
        if not near(n["alpha"], in_a, t, 0.0):
            bad.append(f"frame {r['frame']} new alpha {n['alpha']:.4f}, curve {want_new:.4f}")
        if not near(n["scale"], in_s, t, 1.0):
            bad.append(f"frame {r['frame']} new scale {n['scale']:.4f}, curve {track(in_s, t, 1.0):.4f}")
        if out_a:
            if not near(o["alpha"], out_a, t, 1.0):
                bad.append(f"frame {r['frame']} old alpha {o['alpha']:.4f}, curve {track(out_a, t, 1.0):.4f}")
        elif abs(o["alpha"] - (1.0 - n["alpha"])) > TOL:
            bad.append(f"frame {r['frame']}: old alpha {o['alpha']:.4f} and new {n['alpha']:.4f} do not cross-fade")
        if abs(o["scale"] - 1.0) > 1e-6:
            bad.append(f"frame {r['frame']}: the old screen scales ({o['scale']})")
    label = "timing (out %d ms; in %d ms from %.3f)" % (out_a[0][1], in_a[0][1], in_s[0][2]) if form == "full" \
        else "reduced (a %d ms cross-fade, no scale)" % in_a[0][1]
    if form == "reduced" and in_s:
        bad.append("the reduced form scales")
    report(run, label, bad)
    end = max(s[0] + s[1] for s in in_a + in_s + out_a)
    settle_check(run, imgs, first_frame_after(end))


CHECKS = {"press": check_press, "reward": check_reward, "shine": check_shine, "screen": check_screen}


def main():
    if len(sys.argv) != 2:
        sys.exit(__doc__)
    root = sys.argv[1]
    data = json.load(open(os.path.join(HERE, "curves.json")))
    curves, rules = data["motions"], data["rules"]
    logs = sorted(glob.glob(os.path.join(root, "*", "log.json")))
    if not logs:
        sys.exit(f"no runs under {root}")
    seen = set()
    for path in logs:
        run_dir = os.path.dirname(path)
        run = os.path.basename(run_dir)
        log = json.load(open(path))
        imgs = frames(run_dir, len(log["frames"]))
        seen.add((log["motion"], log["form"]))
        CHECKS[log["motion"]](run, log, curves, imgs)
        flash_check(run, imgs, rules["flash_hz_most"])
    missing = [f"{m} {f}" for m in CHECKS for f in ("full", "reduced") if (m, f) not in seen]
    report("all", "every motion in both forms", [f"no run of {x}" for x in missing])
    print(f"{len(failures)} failed" if failures else "all motion checks pass")
    sys.exit(1 if failures else 0)


if __name__ == "__main__":
    main()
