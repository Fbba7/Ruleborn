#!/usr/bin/env python3
"""The icons' scripted checks (rubric.md quality 3, rules 2 and 3), on the
baked atlases in client/ui/art/:

  python3 art/ui/icons/studio/check_icons.py [icons_48 icons_256]

1. The outline is 2 pt at the size shown (3 pt in high contrast, finish.js's
   RULES). A family's pieces show at SHOWN_PT (finish.js's, mirrored): 48 pt
   for icons_48, 96 pt for icons_256. From the centre of mass, 180 rays find the outermost run of ink
   (opaque, darker than 0.2) and measure it across the edge (the run along
   the ray times the cosine between the ray and the edge's normal). The
   median must be at least 0.85 of 2 pt and the tenth percentile at least
   0.6 (a narrow neck may pinch it; a missing or broken outline fails).
2. A dark shape at 32 pt. The silhouette (alpha over 0.5) at 32 pt on a
   2.8 px/pt client (90 px) covers 25 to 85% of its square, and is not a
   blob: its overlap with the ellipse of its own moments is under 0.96.
   The ring holds: at least 90% of the silhouette's edge is dark (the ink,
   or the soft drop under it), or in high contrast light (the keyline).

Exit 1 if any piece fails, with the figures for each.
"""
import json
import math
import sys
from pathlib import Path

from PIL import Image

ROOT = Path(__file__).resolve().parents[4]
ART = ROOT / 'client/ui/art'
SHOWN_PT = {'icons_48': 48, 'icons_256': 96}
CLIENT_PX_PER_PT = 2.8


def lum(p):
    return (0.299 * p[0] + 0.587 * p[1] + 0.114 * p[2]) / 255


def inky(p):
    return p[3] > 200 and lum(p) < 0.2


def outline(im, want, want_pt=2):
    w, h = im.size
    px = im.load()
    a = [(x, y) for y in range(h) for x in range(w) if px[x, y][3] > 128]
    cx = sum(x for x, _ in a) / len(a)
    cy = sum(y for _, y in a) / len(a)
    alpha = lambda x, y: px[x, y][3] if 0 <= x < w and 0 <= y < h else 0
    runs = []
    for i in range(180):
        t = i / 180 * 2 * math.pi
        dx, dy = math.cos(t), math.sin(t)
        r = max(w, h)
        # The outermost ink pixel on the ray, then the run of ink inward.
        while r > 0:
            x, y = int(cx + dx * r), int(cy + dy * r)
            if 0 <= x < w and 0 <= y < h and inky(px[x, y]):
                break
            r -= 0.5
        if r <= 0:
            runs.append(0.0)
            continue
        end = r
        while r > 0:
            x, y = int(cx + dx * r), int(cy + dy * r)
            if not inky(px[x, y]):
                break
            r -= 0.5
        x, y = int(cx + dx * end), int(cy + dy * end)
        gx = alpha(x + 2, y) - alpha(x - 2, y)
        gy = alpha(x, y + 2) - alpha(x, y - 2)
        g = math.hypot(gx, gy)
        cos = abs(gx * dx + gy * dy) / g if g else 1.0
        runs.append((end - r) * max(cos, 0.3))
    runs.sort()
    med = runs[len(runs) // 2]
    p10 = runs[len(runs) // 10]
    ok = med >= 0.85 * want and p10 >= 0.6 * want
    return ok, f'outline median {med:.1f} px, p10 {p10:.1f} px, {want_pt} pt = {want:.1f} px'


def shape32(im, hc):
    side = round(32 * CLIENT_PX_PER_PT)
    s = im.resize((side, side), Image.LANCZOS)
    px = s.load()
    sil = {(x, y) for y in range(side) for x in range(side) if px[x, y][3] > 128}
    cover = len(sil) / side ** 2
    n = len(sil)
    mx = sum(x for x, _ in sil) / n
    my = sum(y for _, y in sil) / n
    cxx = sum((x - mx) ** 2 for x, _ in sil) / n
    cyy = sum((y - my) ** 2 for _, y in sil) / n
    cxy = sum((x - mx) * (y - my) for x, y in sil) / n
    det = cxx * cyy - cxy ** 2
    ell = {(x, y) for y in range(side) for x in range(side)
           if det and (cyy * (x - mx) ** 2 - 2 * cxy * (x - mx) * (y - my) + cxx * (y - my) ** 2) / det <= 4}
    iou = len(sil & ell) / len(sil | ell)
    edge = [(x, y) for x, y in sil if any((x + i, y + j) not in sil for i, j in ((1, 0), (-1, 0), (0, 1), (0, -1)))]
    dark = sum((lum(px[x, y]) > 0.7) if hc else (lum(px[x, y]) < 0.3) for x, y in edge) / len(edge)
    ok = 0.25 <= cover <= 0.85 and iou < 0.96 and dark >= 0.9
    return ok, f'32 pt ({side} px): covers {cover:.0%}, ellipse overlap {iou:.2f}, ring edge {dark:.0%}'


def main(families):
    bad = 0
    for fam in families:
        m = json.loads((ART / f'{fam}.json').read_text())
        for mode, key in (('normal', 'normal'), ('hc', 'high_contrast')):
            atlas = Image.open(ART / m['atlas'][key]).convert('RGBA')
            for name, p in sorted(m['pieces'].items()):
                im = atlas.crop((p['x'], p['y'], p['x'] + p['w'], p['y'] + p['h']))
                want = (3 if mode == 'hc' else 2) * p['w'] / SHOWN_PT[fam]
                o_ok, o = outline(im, want, 3 if mode == 'hc' else 2)
                s_ok, s = shape32(im, mode == 'hc')
                ok = o_ok and s_ok
                bad += not ok
                print(f"{'ok  ' if ok else 'FAIL'} {fam} {mode:6} {name}: {o}; {s}")
    return 1 if bad else 0


if __name__ == '__main__':
    sys.exit(main(sys.argv[1:] or sorted(SHOWN_PT)))
