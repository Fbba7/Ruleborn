// The icons' finish (art/ui/icons/README.md): the style board's rules
// (art/ui/board/studio.html, bakeIcon), rule for rule, on an icon module's
// render. Drawn at R, then scaled to the family's pixels.
//
//   normal: a soft glow in the icon's light colour, a soft drop in `drop`,
//           the ink outline (2 points at 48), the inner light, the glints;
//   hc:     a keyline in `text_on_night` outside a thicker ink outline, the
//           inner light, no glow, drop or glints.
//
// Every step is plain arithmetic on pictures (picture.js), never a canvas:
// the same bytes on every machine (README.md, "Why the bake is plain
// arithmetic").
import * as S from './toon.js';
import { Picture, place, drawImage, alphaThrough, fillCoverage, blur, atop, stopsAt, premul, Path, downscale, encodePng, installDom } from './picture.js';

const { tok } = S;
export const R = 640;
const rgb = (name) => [1, 3, 5].map((i) => parseInt(tok(name).slice(i, i + 2), 16));
// A token as a straight colour in 0..1 (the canvas's CSS colour).
const col = (name) => rgb(name).map((v) => v / 255);
// Outline and keyline widths are in points of the size an icon is shown at
// (rubric.md quality 3: "2 pt at the size shown"); the board's 1/24 of the
// side is 2 points at 48.
export const SHOWN_PT = { icons_48: 48, icons_256: 96 };
export const RULES = {
  outline: 2, outlineHc: 3, keylineHc: 1.5, ink: 'ink_line', keyline: 'text_on_night',
  drop: 'drop', glint: 'cream', glintMax: 2, glintSize: 0.075,
};

// The silhouette grown by `r` pixels, drawn in one colour (`rgb`, 0–255).
// Computed on the pixels, never drawn: the exact Euclidean distance from
// each pixel to the nearest pixel inside the shape (alpha of a half or
// more), then full ink up to `r` and one pixel of falloff. The same
// arithmetic on every machine, where stamping the silhouette round a
// circle with drawImage gave a ring on one canvas backend and an octagon
// on another.
const FAR = 1e20;
// Squared distance to the nearest zero of `f` along one line (Felzenszwalb
// and Huttenlocher's lower envelope of parabolas), written to `d`.
function edt1d(f, d, v, z, n) {
  let k = 0;
  v[0] = 0; z[0] = -FAR; z[1] = FAR;
  for (let q = 1; q < n; q++) {
    let s;
    for (;;) {
      const p = v[k];
      s = ((f[q] + q * q) - (f[p] + p * p)) / (2 * q - 2 * p);
      if (s > z[k]) break;
      k--;
    }
    k++; v[k] = q; z[k] = s; z[k + 1] = FAR;
  }
  k = 0;
  for (let q = 0; q < n; q++) {
    while (z[k + 1] < q) k++;
    const p = v[k];
    d[q] = (q - p) * (q - p) + f[p];
  }
}
// The grown shape may pass the render's own edge, so the result is `pad`
// pixels wider on every side.
function grown(src, rgb, r, pad) {
  const sw = src.width, sh = src.height;
  const w = sw + 2 * pad, h = sh + 2 * pad, n = Math.max(w, h);
  const alpha = new Uint8Array(w * h);
  for (let y = 0; y < sh; y++) {
    for (let x = 0; x < sw; x++) alpha[(y + pad) * w + x + pad] = src.alpha8(y * sw + x);
  }
  const dist = new Float64Array(w * h);
  const f = new Float64Array(n), d = new Float64Array(n);
  const v = new Int32Array(n), z = new Float64Array(n + 1);
  for (let i = 0; i < w * h; i++) dist[i] = alpha[i] >= 128 ? 0 : FAR;
  for (let x = 0; x < w; x++) {
    for (let y = 0; y < h; y++) f[y] = dist[y * w + x];
    edt1d(f, d, v, z, h);
    for (let y = 0; y < h; y++) dist[y * w + x] = d[y];
  }
  const out = new Picture(w, h);
  const px = out.data;
  for (let y = 0; y < h; y++) {
    for (let x = 0; x < w; x++) f[x] = dist[y * w + x];
    edt1d(f, d, v, z, w);
    for (let x = 0; x < w; x++) {
      const cover = Math.min(1, Math.max(0, r + 0.5 - Math.sqrt(d[x])));
      // The shape's own soft edge is kept where it is wider than the grow.
      const al = Math.max(Math.round(cover * 255), alpha[y * w + x]);
      if (!al) continue;
      const i = (y * w + x) * 4, k = al / 255;
      px[i] = rgb[0] / 255 * k; px[i + 1] = rgb[1] / 255 * k; px[i + 2] = rgb[2] / 255 * k; px[i + 3] = k;
    }
  }
  return out;
}
// The finish's frame: the render drawn at 0.88 of the side, set in by
// (0.06, 0.05) of it, so the glow and the drop have room.
const FRAME = { s: 0.88, tx: R * 0.06, ty: R * 0.05 };
// A point (x, y) of the render's own space in the frame, moved first by
// (dx, dy) in that space.
const framed = (dx = 0, dy = 0) => place(FRAME.s, FRAME.tx + FRAME.s * dx, FRAME.ty + FRAME.s * dy);

function grow(out, src, colour, r) {
  const pad = Math.ceil(r) + 2;
  drawImage(out, grown(src, colour, r, pad), framed(-pad, -pad));
}
// A soft silhouette: the render's alpha through the frame, blurred by
// `sigma` pixels, in one colour at `alpha` (the canvas's blur filter and
// globalAlpha on a `source-in` silhouette).
function soft(out, shot, m, sigma, colour, alpha) {
  const cover = blur(alphaThrough(shot, m, R, R), R, R, sigma);
  fillCoverage(out, cover, premul(colour, alpha));
}
// A glint of size `s` at (x, y) of the render's space: a cream halo fading
// out over half its size, and a four-pointed star with curved sides.
function glint(out, x, y, s) {
  const m = framed();
  const halo = new Path();
  halo.arc(x, y, s * 0.5, 0, Math.PI * 2);
  const cover = halo.coverage(R, R, m);
  const c = col(RULES.glint);
  const stops = [[0, c, 0.9], [1, c, 0]];
  const d = out.data;
  for (let py = 0; py < R; py++) {
    for (let px = 0; px < R; px++) {
      const k = cover[py * R + px];
      if (!k) continue;
      const ux = (px + 0.5 - m.tx) / m.s - x, uy = (py + 0.5 - m.ty) / m.s - y;
      const [r, g, b, a] = stopsAt(stops, Math.sqrt(ux * ux + uy * uy) / (s * 0.5));
      const i = (py * R + px) * 4, f = 1 - a * k;
      d[i] = r * k + d[i] * f; d[i + 1] = g * k + d[i + 1] * f; d[i + 2] = b * k + d[i + 2] * f; d[i + 3] = a * k + d[i + 3] * f;
    }
  }
  const star = new Path();
  star.moveTo(x, y - s); star.quadraticCurveTo(x, y, x + s * 0.7, y);
  star.quadraticCurveTo(x, y, x, y + s); star.quadraticCurveTo(x, y, x - s * 0.7, y);
  star.quadraticCurveTo(x, y, x, y - s);
  fillCoverage(out, star.coverage(R, R, m), premul(c, 1));
}

// The module's render at R: its own `draw` if it has one (a character's
// badge composes a Godot render), else its `build` scene in the studio.
// The same for every family and mode, so a bake renders it once.
export async function shotOf(icon) {
  installDom();
  return icon.draw ? await icon.draw(S, R) : S.renderTo(icon.build(S), R);
}

// One icon module, finished in one mode at `px` pixels square, to be shown
// at `pt` points: a PNG. `shot` is shotOf(icon).
export function finish(icon, shot, px, mode, pt) {
  const hc = mode === 'hc';
  const out = new Picture(R);
  const ow = (hc ? RULES.outlineHc : RULES.outline) / pt * R / 0.88;
  if (!hc) {
    soft(out, shot, framed(), R * 0.034, col(icon.light), 0.6 * 0.85);
    // The soft drop (§21.8; rubric.md quality 3 fails a hard ink drop):
    // the silhouette, wide blur, half strength, set down and right of the
    // top-left key.
    soft(out, shot, framed(R * 0.012, R * 0.04), R * 0.022, col(RULES.drop), 0.55);
  } else {
    grow(out, shot, rgb(RULES.keyline), ow + RULES.keylineHc / pt * R / 0.88);
  }
  grow(out, shot, rgb(RULES.ink), ow);
  const lit = shot.clone();
  const [lx, ly, lr, lc, la] = icon.inner;
  const inner = [[0, col(lc), la], [1, col(lc), 0]];
  atop(lit, (x, y) => stopsAt(inner, Math.sqrt((x - lx * R) ** 2 + (y - ly * R) ** 2) / (lr * R)));
  // §21.8's three-stop body gradient over the whole render, lit from the
  // top: the key's cream at the top, clear through the middle, the drop's
  // shade at the foot. A flat face (a door, a star's front) then reads as
  // lit from above, not as one fill.
  const body = [[0, col(RULES.glint), 0.3], [0.45, col(RULES.glint), 0], [0.6, col(RULES.drop), 0], [1, col(RULES.drop), 0.32]];
  atop(lit, (x, y) => stopsAt(body, (y - R * 0.08) / (R * 0.84)));
  drawImage(out, lit, framed());
  if (!hc) for (const [gx, gy, k] of (icon.glints || []).slice(0, RULES.glintMax)) glint(out, gx * R, gy * R, RULES.glintSize * R * 1.3 * k);
  return encodePng(downscale(out, px, px));
}
