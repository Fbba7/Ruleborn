// The icons' finish (art/ui/icons/README.md): the style board's rules
// (art/ui/board/studio.html, bakeIcon), rule for rule, on an icon module's
// render. Drawn at R, then scaled to the family's pixels.
//
//   normal: a soft glow in the icon's light colour, a soft drop in `drop`,
//           the ink outline (2 points at 48), the inner light, the glints;
//   hc:     a keyline in `text_on_night` outside a thicker ink outline, the
//           inner light, no glow, drop or glints.
import * as S from './toon.js';

const { tok, rgba } = S;
export const R = 640;
const rgb = (name) => [1, 3, 5].map((i) => parseInt(tok(name).slice(i, i + 2), 16));
// Outline and keyline widths are in points of the size an icon is shown at
// (rubric.md quality 3: "2 pt at the size shown"); the board's 1/24 of the
// side is 2 points at 48.
export const SHOWN_PT = { icons_48: 48, icons_256: 96 };
export const RULES = {
  outline: 2, outlineHc: 3, keylineHc: 1.5, ink: 'ink_line', keyline: 'text_on_night',
  drop: 'drop', glint: 'cream', glintMax: 2, glintSize: 0.075,
};

// Every finish canvas is a software one (willReadFrequently), so its
// pixels can be read back without a GPU round trip.
export function canvas(w, h = w) {
  const c = document.createElement('canvas');
  c.width = w; c.height = h;
  c.getContext('2d', { willReadFrequently: true });
  return c;
}
function silhouette(src, colour) {
  const c = canvas(src.width, src.height);
  const x = c.getContext('2d');
  x.drawImage(src, 0, 0);
  x.globalCompositeOperation = 'source-in';
  x.fillStyle = colour;
  x.fillRect(0, 0, c.width, c.height);
  return c;
}
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
  const a = src.getContext('2d').getImageData(0, 0, sw, sh).data;
  const alpha = new Uint8Array(w * h);
  for (let y = 0; y < sh; y++) {
    for (let x = 0; x < sw; x++) alpha[(y + pad) * w + x + pad] = a[(y * sw + x) * 4 + 3];
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
  const out = canvas(w, h);
  const o = out.getContext('2d');
  const img = o.createImageData(w, h);
  const px = img.data;
  for (let y = 0; y < h; y++) {
    for (let x = 0; x < w; x++) f[x] = dist[y * w + x];
    edt1d(f, d, v, z, w);
    for (let x = 0; x < w; x++) {
      const cover = Math.min(1, Math.max(0, r + 0.5 - Math.sqrt(d[x])));
      // The shape's own soft edge is kept where it is wider than the grow.
      const al = Math.max(Math.round(cover * 255), alpha[y * w + x]);
      if (!al) continue;
      const i = (y * w + x) * 4;
      px[i] = rgb[0]; px[i + 1] = rgb[1]; px[i + 2] = rgb[2]; px[i + 3] = al;
    }
  }
  o.putImageData(img, 0, 0);
  return out;
}
function grow(x, src, colour, r) {
  const pad = Math.ceil(r) + 2;
  x.drawImage(grown(src, colour, r, pad), -pad, -pad);
}
function glint(ctx, x, y, s) {
  ctx.save();
  const halo = ctx.createRadialGradient(x, y, 0, x, y, s * 0.5);
  halo.addColorStop(0, rgba(RULES.glint, 0.9));
  halo.addColorStop(1, rgba(RULES.glint, 0));
  ctx.fillStyle = halo;
  ctx.beginPath(); ctx.arc(x, y, s * 0.5, 0, Math.PI * 2); ctx.fill();
  ctx.fillStyle = rgba(RULES.glint, 1);
  ctx.beginPath();
  ctx.moveTo(x, y - s); ctx.quadraticCurveTo(x, y, x + s * 0.7, y);
  ctx.quadraticCurveTo(x, y, x, y + s); ctx.quadraticCurveTo(x, y, x - s * 0.7, y);
  ctx.quadraticCurveTo(x, y, x, y - s);
  ctx.fill();
  ctx.restore();
}

// The module's render at R: its own `draw` if it has one (a character's
// badge composes a Godot render), else its `build` scene in the studio.
async function shotOf(icon) {
  const out = canvas(R);
  const src = icon.draw ? await icon.draw(S, R) : S.renderTo(icon.build(S), R);
  out.getContext('2d').drawImage(src, 0, 0);
  return out;
}

// One icon module, finished in one mode at `px` pixels square, to be shown
// at `pt` points.
export async function finish(icon, px, mode, pt) {
  const shot = await shotOf(icon);
  const hc = mode === 'hc';
  const out = canvas(R);
  const x = out.getContext('2d');
  const draw = (c) => { x.drawImage(c, 0, 0); };
  x.save(); x.translate(R * 0.06, R * 0.05); x.scale(0.88, 0.88);
  const ow = (hc ? RULES.outlineHc : RULES.outline) / pt * R / 0.88;
  if (!hc) {
    x.save(); x.filter = `blur(${R * 0.034}px)`; x.globalAlpha = 0.85;
    draw(silhouette(shot, rgba(icon.light, 0.6))); x.restore();
    // The soft drop (§21.8; rubric.md quality 3 fails a hard ink drop):
    // the silhouette, wide blur, half strength, set down and right of the
    // top-left key.
    x.save(); x.filter = `blur(${R * 0.022}px)`; x.globalAlpha = 0.55;
    x.translate(R * 0.012, R * 0.04); draw(silhouette(shot, tok(RULES.drop))); x.restore();
  } else {
    grow(x, shot, rgb(RULES.keyline), ow + RULES.keylineHc / pt * R / 0.88);
  }
  grow(x, shot, rgb(RULES.ink), ow);
  const lit = canvas(R);
  const l = lit.getContext('2d');
  l.drawImage(shot, 0, 0);
  l.globalCompositeOperation = 'source-atop';
  const [lx, ly, lr, lc, la] = icon.inner;
  const g = l.createRadialGradient(lx * R, ly * R, 0, lx * R, ly * R, lr * R);
  g.addColorStop(0, rgba(lc, la));
  g.addColorStop(1, rgba(lc, 0));
  l.fillStyle = g;
  l.fillRect(0, 0, R, R);
  // §21.8's three-stop body gradient over the whole render, lit from the
  // top: the key's cream at the top, clear through the middle, the drop's
  // shade at the foot. A flat face (a door, a star's front) then reads as
  // lit from above, not as one fill.
  const body = l.createLinearGradient(0, R * 0.08, 0, R * 0.92);
  body.addColorStop(0, rgba(RULES.glint, 0.3));
  body.addColorStop(0.45, rgba(RULES.glint, 0));
  body.addColorStop(0.6, rgba(RULES.drop, 0));
  body.addColorStop(1, rgba(RULES.drop, 0.32));
  l.fillStyle = body;
  l.fillRect(0, 0, R, R);
  draw(lit);
  if (!hc) for (const [gx, gy, k] of (icon.glints || []).slice(0, RULES.glintMax)) glint(x, gx * R, gy * R, RULES.glintSize * R * 1.3 * k);
  x.restore();
  const small = canvas(px);
  const s = small.getContext('2d');
  s.imageSmoothingQuality = 'high';
  s.drawImage(out, 0, 0, px, px);
  return small.toDataURL('image/png');
}
