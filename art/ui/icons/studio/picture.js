// The icons' pictures (art/ui/icons/README.md, "Why the bake is plain
// arithmetic"): an RGBA image held as premultiplied float64, and the few
// drawing operations the finish needs, written as plain arithmetic.
//
// Nothing here reaches a GPU, a canvas backend or a vector unit: every pixel
// is a sum of products of float64 numbers in a fixed order, and the only
// functions called are Math.sqrt, Math.round, Math.floor, Math.ceil and
// Math.min/max, which are exact. So a picture is the same bits on every
// machine that runs it (a canvas backend picks its code path by the CPU's
// vector units, and its rounding differs with it).
//
// The canvas operations mirror Canvas 2D's meaning: drawImage with
// bilinear smoothing, `source-over`, `source-in` and `source-atop`,
// gradients interpolated in unpremultiplied colour, a blur filter as the
// filter spec's three box passes, an antialiased path fill.
import zlib from 'node:zlib';
import fs from 'node:fs';

export class Picture {
  constructor(w = 0, h = w) { this.alloc(w, h); }
  alloc(w, h) {
    this.w = w; this.h = h;
    this.data = new Float64Array(w * h * 4);
  }
  // A canvas's width and height: setting either clears it, as on a canvas.
  get width() { return this.w; }
  set width(v) { this.alloc(v, this.h); }
  get height() { return this.h; }
  set height(v) { this.alloc(this.w, v); }
  getContext() { return new Context2D(this); }
  clone() {
    const p = new Picture(this.w, this.h);
    p.data.set(this.data);
    return p;
  }
  alpha8(i) { return Math.round(this.data[i * 4 + 3] * 255); }
}

// ---- PNG, read and written with no filter and no compression choices ----

const CRC = new Int32Array(256);
for (let n = 0; n < 256; n++) {
  let c = n;
  for (let k = 0; k < 8; k++) c = c & 1 ? 0xedb88320 ^ (c >>> 1) : c >>> 1;
  CRC[n] = c;
}
function crc32(buf) {
  let c = -1;
  for (let i = 0; i < buf.length; i++) c = CRC[(c ^ buf[i]) & 255] ^ (c >>> 8);
  return (c ^ -1) >>> 0;
}
function chunk(type, body) {
  const head = Buffer.alloc(8);
  head.writeUInt32BE(body.length, 0);
  head.write(type, 4, 'ascii');
  const tail = Buffer.alloc(4);
  tail.writeUInt32BE(crc32(Buffer.concat([head.subarray(4), body])), 0);
  return Buffer.concat([head, body, tail]);
}

// The picture as 8-bit straight RGBA, as a canvas's getImageData gives it.
export function rgba8(pic) {
  const out = new Uint8Array(pic.w * pic.h * 4);
  const d = pic.data;
  for (let i = 0; i < pic.w * pic.h; i++) {
    const a = Math.min(1, Math.max(0, d[i * 4 + 3]));
    const a8 = Math.round(a * 255);
    if (!a8) continue;
    for (let c = 0; c < 3; c++) out[i * 4 + c] = Math.round(Math.min(1, Math.max(0, d[i * 4 + c] / a)) * 255);
    out[i * 4 + 3] = a8;
  }
  return out;
}

// A PNG of the picture: filter 0 on every row, deflate in stored blocks
// (level 0), so the bytes depend on the pixels only.
export function encodePng(pic) {
  const px = rgba8(pic);
  const row = pic.w * 4;
  const raw = Buffer.alloc((row + 1) * pic.h);
  for (let y = 0; y < pic.h; y++) raw.set(px.subarray(y * row, (y + 1) * row), y * (row + 1) + 1);
  const ihdr = Buffer.alloc(13);
  ihdr.writeUInt32BE(pic.w, 0); ihdr.writeUInt32BE(pic.h, 4);
  ihdr[8] = 8; ihdr[9] = 6; ihdr[10] = 0; ihdr[11] = 0; ihdr[12] = 0;
  return Buffer.concat([
    Buffer.from([137, 80, 78, 71, 13, 10, 26, 10]),
    chunk('IHDR', ihdr),
    chunk('IDAT', zlib.deflateSync(raw, { level: 0 })),
    chunk('IEND', Buffer.alloc(0)),
  ]);
}

// An 8-bit RGBA or RGB PNG (no palette, no interlace) as a picture.
export function decodePng(file) {
  const buf = fs.readFileSync(file);
  let at = 8, w = 0, h = 0, type = 0;
  const idat = [];
  while (at < buf.length) {
    const len = buf.readUInt32BE(at);
    const t = buf.toString('ascii', at + 4, at + 8);
    const body = buf.subarray(at + 8, at + 8 + len);
    if (t === 'IHDR') {
      w = body.readUInt32BE(0); h = body.readUInt32BE(4); type = body[9];
      if (body[8] !== 8 || (type !== 6 && type !== 2) || body[12] !== 0) throw new Error(`${file}: only 8-bit RGB(A) PNG without interlace`);
    } else if (t === 'IDAT') idat.push(body);
    at += 12 + len;
  }
  const bpp = type === 6 ? 4 : 3;
  const raw = zlib.inflateSync(Buffer.concat(idat));
  const row = w * bpp;
  const px = new Uint8Array(row * h);
  for (let y = 0; y < h; y++) {
    const f = raw[y * (row + 1)];
    const src = raw.subarray(y * (row + 1) + 1, (y + 1) * (row + 1));
    const o = y * row;
    for (let i = 0; i < row; i++) {
      const a = i >= bpp ? px[o + i - bpp] : 0;
      const b = y ? px[o - row + i] : 0;
      const c = i >= bpp && y ? px[o - row + i - bpp] : 0;
      let p = src[i];
      if (f === 1) p += a;
      else if (f === 2) p += b;
      else if (f === 3) p += (a + b) >> 1;
      else if (f === 4) {
        const q = a + b - c, pa = Math.abs(q - a), pb = Math.abs(q - b), pc = Math.abs(q - c);
        p += pa <= pb && pa <= pc ? a : pb <= pc ? b : c;
      } else if (f !== 0) throw new Error(`${file}: PNG filter ${f}`);
      px[o + i] = p & 255;
    }
  }
  const pic = new Picture(w, h);
  for (let i = 0; i < w * h; i++) {
    const a = bpp === 4 ? px[i * bpp + 3] / 255 : 1;
    for (let c = 0; c < 3; c++) pic.data[i * 4 + c] = px[i * bpp + c] / 255 * a;
    pic.data[i * 4 + 3] = a;
  }
  return pic;
}

// ---- colours ----

// A straight colour [r, g, b] in 0..1 and an alpha, premultiplied.
export const premul = ([r, g, b], a) => [r * a, g * a, b * a, a];

// ---- compositing ----

// `src` (premultiplied, alpha `sa`) over the destination pixel at i.
function over(d, i, r, g, b, a) {
  const k = 1 - a;
  d[i] = r + d[i] * k;
  d[i + 1] = g + d[i + 1] * k;
  d[i + 2] = b + d[i + 2] * k;
  d[i + 3] = a + d[i + 3] * k;
}

// One premultiplied colour, drawn `source-atop` over every pixel by
// `colourAt(x, y)` (x, y at the pixel's centre): the picture keeps its
// alpha and takes the colour where it is.
export function atop(pic, colourAt) {
  const d = pic.data;
  for (let y = 0; y < pic.h; y++) {
    for (let x = 0; x < pic.w; x++) {
      const i = (y * pic.w + x) * 4;
      const da = d[i + 3];
      if (!da) continue;
      const [r, g, b, a] = colourAt(x + 0.5, y + 0.5);
      if (!a) continue;
      const k = 1 - a;
      d[i] = r * da + d[i] * k;
      d[i + 1] = g * da + d[i + 1] * k;
      d[i + 2] = b * da + d[i + 2] * k;
    }
  }
}

// The colour stops of a gradient at t, interpolated in straight colour as
// Canvas 2D does, then premultiplied. `stops` is [[t, [r, g, b], a], ...].
export function stopsAt(stops, t) {
  if (t <= stops[0][0]) return premul(stops[0][1], stops[0][2]);
  for (let i = 1; i < stops.length; i++) {
    const [t1, c1, a1] = stops[i];
    if (t <= t1) {
      const [t0, c0, a0] = stops[i - 1];
      const f = t1 > t0 ? (t - t0) / (t1 - t0) : 1;
      return premul([0, 1, 2].map((k) => c0[k] + (c1[k] - c0[k]) * f), a0 + (a1 - a0) * f);
    }
  }
  const last = stops[stops.length - 1];
  return premul(last[1], last[2]);
}

// The source's value at a point (in its pixel units, centres at .5) by
// bilinear smoothing, transparent outside it: channel c of pixel (u, v).
function bilinear(src, u, v, out) {
  const x = u - 0.5, y = v - 0.5;
  const x0 = Math.floor(x), y0 = Math.floor(y);
  const fx = x - x0, fy = y - y0;
  const d = src.data, w = src.w, h = src.h;
  out[0] = out[1] = out[2] = out[3] = 0;
  for (let j = 0; j < 2; j++) {
    const yy = y0 + j;
    if (yy < 0 || yy >= h) continue;
    const wy = j ? fy : 1 - fy;
    for (let i = 0; i < 2; i++) {
      const xx = x0 + i;
      if (xx < 0 || xx >= w) continue;
      const wgt = (i ? fx : 1 - fx) * wy;
      if (!wgt) continue;
      const k = (yy * w + xx) * 4;
      out[0] += d[k] * wgt; out[1] += d[k + 1] * wgt; out[2] += d[k + 2] * wgt; out[3] += d[k + 3] * wgt;
    }
  }
}

// An affine map that only scales and moves: a point p of the source lands
// at p * s + [tx, ty] (a canvas's translate then scale).
export const place = (s, tx, ty) => ({ s, tx, ty });

// Draws `src` onto `dst` through the map `m`, with bilinear smoothing, at
// `alpha` (globalAlpha), `source-over`, inside the optional coverage `clip`
// (a Float64Array of dst's size). `paint(i, r, g, b, a)` replaces the
// colour when given (for a silhouette).
export function drawImage(dst, src, m, alpha = 1, clip = null) {
  const x0 = Math.max(0, Math.floor(m.tx)), y0 = Math.max(0, Math.floor(m.ty));
  const x1 = Math.min(dst.w, Math.ceil(m.tx + src.w * m.s)), y1 = Math.min(dst.h, Math.ceil(m.ty + src.h * m.s));
  const px = [0, 0, 0, 0];
  const d = dst.data;
  for (let y = y0; y < y1; y++) {
    for (let x = x0; x < x1; x++) {
      bilinear(src, (x + 0.5 - m.tx) / m.s, (y + 0.5 - m.ty) / m.s, px);
      let k = alpha;
      if (clip) k *= clip[y * dst.w + x];
      if (!px[3] || !k) continue;
      over(d, (y * dst.w + x) * 4, px[0] * k, px[1] * k, px[2] * k, px[3] * k);
    }
  }
}

// The alpha of `src` drawn through `m` (bilinear), as a Float64Array of
// w x h: a silhouette's coverage, before it is coloured.
export function alphaThrough(src, m, w, h) {
  const out = new Float64Array(w * h);
  const x0 = Math.max(0, Math.floor(m.tx)), y0 = Math.max(0, Math.floor(m.ty));
  const x1 = Math.min(w, Math.ceil(m.tx + src.w * m.s)), y1 = Math.min(h, Math.ceil(m.ty + src.h * m.s));
  const px = [0, 0, 0, 0];
  for (let y = y0; y < y1; y++) {
    for (let x = x0; x < x1; x++) {
      bilinear(src, (x + 0.5 - m.tx) / m.s, (y + 0.5 - m.ty) / m.s, px);
      out[y * w + x] = px[3];
    }
  }
  return out;
}

// A coverage (w x h) filled in one premultiplied colour, `source-over`.
export function fillCoverage(dst, cover, colour) {
  const [r, g, b, a] = colour;
  const d = dst.data;
  for (let i = 0; i < dst.w * dst.h; i++) {
    const k = cover[i];
    if (k) over(d, i * 4, r * k, g * k, b * k, a * k);
  }
}

// ---- blur ----

// One box pass along a line: out[i] is the mean of in[i - lo .. i + hi].
function box(src, dst, n, stride, base, lo, hi) {
  const size = lo + hi + 1;
  let sum = 0;
  for (let j = -lo; j <= hi; j++) if (j >= 0 && j < n) sum += src[base + j * stride];
  for (let i = 0; i < n; i++) {
    dst[base + i * stride] = sum / size;
    const add = i + hi + 1, drop = i - lo;
    if (add < n) sum += src[base + add * stride];
    if (drop >= 0) sum -= src[base + drop * stride];
  }
}

// A Gaussian blur of standard deviation `sigma` (canvas pixels) on a w x h
// coverage, as the filter spec's three box passes per axis (the way
// Canvas 2D's `blur()` filter is drawn), transparent outside.
export function blur(cover, w, h, sigma) {
  const d = Math.floor(sigma * 3 * Math.sqrt(2 * Math.PI) / 4 + 0.5);
  const passes = d % 2
    ? [[(d - 1) / 2, (d - 1) / 2], [(d - 1) / 2, (d - 1) / 2], [(d - 1) / 2, (d - 1) / 2]]
    : [[d / 2, d / 2 - 1], [d / 2 - 1, d / 2], [d / 2, d / 2]];
  let a = Float64Array.from(cover), b = new Float64Array(w * h);
  for (const [lo, hi] of passes) {
    for (let y = 0; y < h; y++) box(a, b, w, 1, y * w, lo, hi);
    [a, b] = [b, a];
  }
  for (const [lo, hi] of passes) {
    for (let x = 0; x < w; x++) box(a, b, h, w, x, lo, hi);
    [a, b] = [b, a];
  }
  return a;
}

// ---- paths ----

// A path as closed polygons of [x, y] points (curves flattened).
export class Path {
  constructor() { this.polys = []; this.cur = null; }
  moveTo(x, y) { this.cur = [[x, y]]; this.polys.push(this.cur); }
  lineTo(x, y) { if (!this.cur) this.moveTo(x, y); else this.cur.push([x, y]); }
  quadraticCurveTo(cx, cy, x, y) {
    const [x0, y0] = this.cur[this.cur.length - 1];
    for (let i = 1; i <= 32; i++) {
      const t = i / 32, u = 1 - t;
      this.cur.push([u * u * x0 + 2 * u * t * cx + t * t * x, u * u * y0 + 2 * u * t * cy + t * t * y]);
    }
  }
  // An arc as Canvas 2D draws it: clockwise on screen (y down) from a0 to
  // a1 unless `ccw`; one point per 1/256 of a turn.
  arc(cx, cy, r, a0, a1, ccw = false) {
    let sweep = a1 - a0;
    if (!ccw && sweep < 0) sweep += 2 * Math.PI;
    if (ccw && sweep > 0) sweep -= 2 * Math.PI;
    const n = Math.max(1, Math.ceil(Math.abs(sweep) / (2 * Math.PI) * 256));
    for (let i = 0; i <= n; i++) {
      const a = a0 + sweep * i / n;
      const p = [cx + r * Math.cos(a), cy + r * Math.sin(a)];
      if (!i && !this.cur) this.moveTo(...p); else this.lineTo(...p);
    }
  }
  closePath() { this.cur = null; }
  // The path's coverage of each pixel of a w x h picture through the map
  // `m` (the path is in user units), nonzero winding, by n x n samples per
  // pixel: each row of samples crosses the path's edges at points sorted
  // left to right, and a sample counts when the winding left of it is not
  // zero.
  coverage(w, h, m = place(1, 0, 0), n = 8) {
    const out = new Float64Array(w * h);
    const polys = this.polys.map((p) => p.map(([x, y]) => [x * m.s + m.tx, y * m.s + m.ty]));
    let y0 = Infinity, y1 = -Infinity;
    for (const p of polys) for (const [, y] of p) { y0 = Math.min(y0, y); y1 = Math.max(y1, y); }
    const rows = [Math.max(0, Math.floor(y0)), Math.min(h, Math.ceil(y1))];
    const k = 1 / (n * n);
    for (let py = rows[0]; py < rows[1]; py++) {
      for (let j = 0; j < n; j++) {
        const sy = py + (j + 0.5) / n;
        const cross = [];
        for (const p of polys) {
          for (let i = 0; i < p.length; i++) {
            const [ax, ay] = p[i], [bx, by] = p[(i + 1) % p.length];
            if ((ay <= sy && sy < by) || (by <= sy && sy < ay)) {
              cross.push([ax + (sy - ay) * (bx - ax) / (by - ay), by > ay ? 1 : -1]);
            }
          }
        }
        cross.sort((u, v) => u[0] - v[0] || u[1] - v[1]);
        let wind = 0;
        for (let c = 0; c < cross.length - 1; c++) {
          wind += cross[c][1];
          if (!wind) continue;
          // Samples at x = px + (i + 0.5) / n with xa <= x < xb.
          const xa = cross[c][0], xb = cross[c + 1][0];
          let s = Math.max(0, Math.ceil(xa * n - 0.5));
          const e = Math.min(w * n, Math.ceil(xb * n - 0.5));
          for (; s < e; s++) out[py * w + Math.floor(s / n)] += k;
        }
      }
    }
    return out;
  }
}

// ---- downscale ----

// The picture at w x h by area averaging: each output pixel is the mean of
// the source area it covers, in premultiplied colour.
export function downscale(src, w, h) {
  const out = new Picture(w, h);
  const sx = src.w / w, sy = src.h / h;
  const spans = (n, k, max) => {
    const all = [];
    for (let i = 0; i < n; i++) {
      const a = i * k, b = (i + 1) * k, s = [];
      for (let j = Math.floor(a); j < Math.min(max, Math.ceil(b)); j++) s.push([j, Math.min(b, j + 1) - Math.max(a, j)]);
      all.push(s);
    }
    return all;
  };
  const cols = spans(w, sx, src.w), rows = spans(h, sy, src.h);
  const area = sx * sy, d = src.data, o = out.data;
  for (let y = 0; y < h; y++) {
    for (let x = 0; x < w; x++) {
      let r = 0, g = 0, b = 0, a = 0;
      for (const [yy, wy] of rows[y]) {
        for (const [xx, wx] of cols[x]) {
          const k = (yy * src.w + xx) * 4, f = wx * wy;
          r += d[k] * f; g += d[k + 1] * f; b += d[k + 2] * f; a += d[k + 3] * f;
        }
      }
      const i = (y * w + x) * 4;
      o[i] = r / area; o[i + 1] = g / area; o[i + 2] = b / area; o[i + 3] = a / area;
    }
  }
  return out;
}

// ---- the canvas subset a module's own `draw` may use ----

// A 2D context on a picture with the calls a badge's `draw` makes:
// drawImage (at a point, or into a rectangle, bilinear), save/restore,
// and a path for clip. Any other call is refused, so a module cannot
// reach a canvas backend by accident.
class Context2D {
  constructor(pic) { this.pic = pic; this.path = new Path(); this.clipCover = null; this.stack = []; }
  save() { this.stack.push(this.clipCover); }
  restore() { this.clipCover = this.stack.pop() ?? null; }
  beginPath() { this.path = new Path(); }
  moveTo(x, y) { this.path.moveTo(x, y); }
  lineTo(x, y) { this.path.lineTo(x, y); }
  arc(...a) { this.path.arc(...a); }
  quadraticCurveTo(...a) { this.path.quadraticCurveTo(...a); }
  closePath() { this.path.closePath(); }
  clip() {
    const c = this.path.coverage(this.pic.w, this.pic.h);
    if (this.clipCover) for (let i = 0; i < c.length; i++) c[i] *= this.clipCover[i];
    this.clipCover = c;
  }
  drawImage(img, x, y, w, h) {
    const src = img.picture || img;
    if (w === undefined) { w = src.w; h = src.h; }
    if (w * src.h !== h * src.w) throw new Error('drawImage: only an unstretched rectangle');
    drawImage(this.pic, src, place(w / src.w, x, y), 1, this.clipCover);
  }
}

// An image a module loads by URL (a committed PNG under art/ui/icons/).
class PngImage {
  set src(url) { this.url = url; }
  get src() { return this.url; }
  async decode() { this.picture = decodePng(new URL(this.url)); }
}

// The two DOM names a module's `draw` uses, on plain arithmetic.
export function installDom() {
  globalThis.document = {
    createElement(tag) {
      if (tag !== 'canvas') throw new Error(`document.createElement('${tag}') is not in the icons' studio`);
      return new Picture(0, 0);
    },
  };
  globalThis.Image = PngImage;
}
