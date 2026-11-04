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
// Outline and keyline widths are in points of the size an icon is shown at
// (rubric.md quality 3: "2 pt at the size shown"); the board's 1/24 of the
// side is 2 points at 48.
export const SHOWN_PT = { icons_48: 48, icons_256: 96 };
export const RULES = {
  outline: 2, outlineHc: 3, keylineHc: 1.5, ink: 'ink_line', keyline: 'text_on_night',
  drop: 'drop', glint: 'cream', glintMax: 2, glintSize: 0.075,
};

// Every finish canvas is a software one (willReadFrequently): on a
// GPU-backed 2D canvas, a grow's hundreds of stamps were sometimes dropped
// when the machine was idle (an octagon instead of a ring round crew/pip in
// high contrast), so the bake differed with the machine's load.
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
// The silhouette grown by `r` pixels, drawn in one colour. The stamps sit
// at most a pixel apart round the circle: at the board's fixed 48, a thin
// point (a star's tip) left gaps that read as holes in the ring.
function grow(x, sil, r) {
  const n = Math.max(48, Math.ceil(2 * Math.PI * r));
  for (let i = 0; i < n; i++) {
    const a = i / n * Math.PI * 2;
    x.drawImage(sil, Math.cos(a) * r, Math.sin(a) * r);
  }
  x.drawImage(sil, 0, 0);
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
    grow(x, silhouette(shot, tok(RULES.keyline)), ow + RULES.keylineHc / pt * R / 0.88);
  }
  grow(x, silhouette(shot, tok(RULES.ink)), ow);
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
