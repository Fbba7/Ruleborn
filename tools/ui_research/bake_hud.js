// Bake the heist HUD's authored UI art (T14's proof, docs/art/ui-quality/).
//
//   node tools/ui_research/bake_hud.js
//
// Every piece is drawn once, offline, as SVG in headless Chromium, where a
// bevel can be lit (feSpecularLighting), a surface can carry grain
// (feTurbulence), and text can have a gradient fill, a thick stroke and a
// drop at no cost to the phone. Each piece is screenshotted on a transparent
// background, then all are packed into one atlas (pack_atlas.py) in
// client/prototypes/ui_quality/art/, with each piece's place and 9-slice
// margins in manifest.json. In the game each is one textured quad, and the
// whole HUD one texture, so Godot batches it.
'use strict';
const fs = require('fs');
const path = require('path');
const os = require('os');
const { execFileSync } = require('child_process');
const { chromium } = require('playwright');

const root = path.resolve(__dirname, '../..');
const out = path.join(root, 'client/prototypes/ui_quality/art');
const lilita = 'file://' + path.join(root, 'client/ui/fonts/lilita_one/LilitaOne-Regular.ttf');

const INK = '#1A0C14';
const pieces = [];
let uid = 0;

function piece(name, w, h, body, slice) {
  pieces.push({ name, w, h, body, slice });
}

// Shared definitions: the lit bevel, the enamel's grain, the soft drop.
const defs = `
<filter id="bevel" x="-10%" y="-10%" width="120%" height="120%">
  <feGaussianBlur in="SourceAlpha" stdDeviation="2.4" result="b"/>
  <feSpecularLighting in="b" surfaceScale="5" specularConstant="1.15" specularExponent="18"
    lighting-color="#FFF6DA" result="s"><feDistantLight azimuth="235" elevation="24"/></feSpecularLighting>
  <feComposite in="s" in2="SourceAlpha" operator="in" result="s2"/>
  <feComposite in="SourceGraphic" in2="s2" operator="arithmetic" k1="0" k2="1" k3="0.75" k4="0"/>
</filter>
<filter id="bevelsoft" x="-10%" y="-10%" width="120%" height="120%">
  <feGaussianBlur in="SourceAlpha" stdDeviation="5" result="b"/>
  <feSpecularLighting in="b" surfaceScale="6" specularConstant="1.0" specularExponent="16"
    lighting-color="#FFFFFF" result="s"><feDistantLight azimuth="250" elevation="26"/></feSpecularLighting>
  <feComposite in="s" in2="SourceAlpha" operator="in" result="s2"/>
  <feComposite in="SourceGraphic" in2="s2" operator="arithmetic" k1="0" k2="1" k3="0.45" k4="0"/>
</filter>
<filter id="grain" x="0" y="0" width="100%" height="100%">
  <feTurbulence type="fractalNoise" baseFrequency="0.9" numOctaves="2" seed="7" result="n"/>
  <feColorMatrix type="matrix" values="0 0 0 0 1  0 0 0 0 1  0 0 0 0 1  0 0 0 0.5 -0.18"/>
  <feComposite in2="SourceGraphic" operator="in"/>
</filter>
<filter id="soft" x="-30%" y="-30%" width="160%" height="160%"><feGaussianBlur stdDeviation="6"/></filter>
<filter id="soft2" x="-30%" y="-30%" width="160%" height="160%"><feGaussianBlur stdDeviation="2.5"/></filter>
<filter id="glow" x="-50%" y="-50%" width="200%" height="200%"><feGaussianBlur stdDeviation="9"/></filter>
<linearGradient id="gold" x1="0" y1="0" x2="0" y2="1">
  <stop offset="0" stop-color="#FFF4C2"/><stop offset="0.28" stop-color="#F7CB55"/>
  <stop offset="0.62" stop-color="#D08A26"/><stop offset="1" stop-color="#7E4512"/>
</linearGradient>
<linearGradient id="goldText" x1="0" y1="0" x2="0" y2="1">
  <stop offset="0" stop-color="#FFFBE6"/><stop offset="0.45" stop-color="#FFE38A"/>
  <stop offset="0.55" stop-color="#F9C640"/><stop offset="1" stop-color="#E59A1C"/>
</linearGradient>
<linearGradient id="whiteText" x1="0" y1="0" x2="0" y2="1">
  <stop offset="0" stop-color="#FFFFFF"/><stop offset="0.5" stop-color="#FFFFFF"/>
  <stop offset="0.56" stop-color="#F1E6FF"/><stop offset="1" stop-color="#D9C6F2"/>
</linearGradient>
<linearGradient id="redText" x1="0" y1="0" x2="0" y2="1">
  <stop offset="0" stop-color="#FFE9EC"/><stop offset="0.5" stop-color="#FF9AA8"/>
  <stop offset="0.56" stop-color="#FF5C74"/><stop offset="1" stop-color="#E0304E"/>
</linearGradient>
<linearGradient id="enamel" x1="0" y1="0" x2="0" y2="1">
  <stop offset="0" stop-color="#5A3790"/><stop offset="0.5" stop-color="#3A2066"/><stop offset="1" stop-color="#261341"/>
</linearGradient>
<linearGradient id="gloss" x1="0" y1="0" x2="0" y2="1">
  <stop offset="0" stop-color="#FFFFFF" stop-opacity="0.34"/><stop offset="1" stop-color="#FFFFFF" stop-opacity="0"/>
</linearGradient>
<radialGradient id="stud" cx="0.38" cy="0.32" r="0.7">
  <stop offset="0" stop-color="#FFFBEA"/><stop offset="0.3" stop-color="#FFD866"/>
  <stop offset="0.75" stop-color="#B86E1A"/><stop offset="1" stop-color="#5C300A"/>
</radialGradient>
`;

const rr = (x, y, w, h, r) =>
  `M${x + r},${y} h${w - 2 * r} a${r},${r} 0 0 1 ${r},${r} v${h - 2 * r} a${r},${r} 0 0 1 ${-r},${r} ` +
  `h${-(w - 2 * r)} a${r},${r} 0 0 1 ${-r},${-r} v${-(h - 2 * r)} a${r},${r} 0 0 1 ${r},${-r} z`;

// A framed panel: ink outline, a lit gold rim, an inner ink line, an enamel
// body with grain, a shadow under the rim and a gloss, studs at the corners,
// all sitting on a hard drop and a soft shadow. `fill` is a gradient id.
function panel(w, h, opts = {}) {
  const r = opts.r ?? 30, rim = opts.rim ?? 9, pad = opts.pad ?? 14, drop = opts.drop ?? 9;
  const fill = opts.fill ?? 'enamel', studs = opts.studs ?? true;
  const id = 'p' + (uid++);
  const W = w - 2 * pad, H = h - 2 * pad - drop;
  const x = pad, y = pad;
  const ri = r - 4 - rim;
  const inner = rr(x + 4 + rim, y + 4 + rim, W - 8 - 2 * rim, H - 8 - 2 * rim, Math.max(ri, 4));
  let s = `<defs><clipPath id="${id}c"><path d="${inner}"/></clipPath></defs>`;
  s += `<path d="${rr(x + 2, y + 10, W - 4, H, r)}" fill="#000" opacity="0.55" filter="url(#soft)"/>`;
  s += `<path d="${rr(x, y + drop, W, H, r)}" fill="#0A0408"/>`;
  s += `<path d="${rr(x, y, W, H, r)}" fill="${INK}"/>`;
  s += `<path d="${rr(x + 4, y + 4, W - 8, H - 8, r - 4)} ${inner}" fill-rule="evenodd" fill="url(#gold)" filter="url(#bevel)"/>`;
  s += `<path d="${rr(x + 4, y + 4, W - 8, H - 8, r - 4)}" fill="none" stroke="#FFF8D8" stroke-opacity="0.55" stroke-width="1.5"/>`;
  s += `<path d="${inner}" fill="url(#${fill})"/>`;
  s += `<g clip-path="url(#${id}c)">`;
  s += `<rect x="0" y="0" width="${w}" height="${h}" fill="#fff" filter="url(#grain)" opacity="0.5"/>`;
  s += `<path d="${inner}" fill="none" stroke="#000" stroke-opacity="0.55" stroke-width="10" filter="url(#soft2)" transform="translate(0,3)"/>`;
  const gy = y + 4 + rim + 4, gh = (H - 8 - 2 * rim) * 0.42;
  s += `<path d="${rr(x + rim + 12, gy, W - 2 * rim - 24, gh, Math.min(16, gh / 2))}" fill="url(#gloss)"/>`;
  s += `</g>`;
  s += `<path d="${inner}" fill="none" stroke="${INK}" stroke-width="3"/>`;
  if (studs) {
    for (const [cx, cy] of [[x + r * 0.62, y + r * 0.62], [x + W - r * 0.62, y + r * 0.62],
      [x + r * 0.62, y + H - r * 0.62], [x + W - r * 0.62, y + H - r * 0.62]]) {
      s += `<circle cx="${cx}" cy="${cy + 1.5}" r="7.5" fill="${INK}"/>`;
      s += `<circle cx="${cx}" cy="${cy}" r="6" fill="url(#stud)"/>`;
    }
  }
  return s;
}

// A chunky pressable button, its face on a thick side of the same colour,
// darker, with a gloss band and a lit edge. `down` sinks the face onto it.
function button(w, h, c, down) {
  const pad = 12, side = down ? 4 : 13, r = 34;
  const W = w - 2 * pad, H = h - 2 * pad - 13;
  const fy = pad + (down ? 9 : 0);
  const id = 'b' + (uid++);
  let s = `<defs><linearGradient id="${id}f" x1="0" y1="0" x2="0" y2="1">
    <stop offset="0" stop-color="${c[0]}"/><stop offset="0.48" stop-color="${c[1]}"/><stop offset="1" stop-color="${c[2]}"/>
  </linearGradient><clipPath id="${id}c"><path d="${rr(pad + 5, fy + 5, W - 10, H - 10, r - 5)}"/></clipPath></defs>`;
  s += `<path d="${rr(pad + 2, pad + 14, W - 4, H, r)}" fill="#000" opacity="0.5" filter="url(#soft)"/>`;
  s += `<path d="${rr(pad, fy + side, W, H, r)}" fill="${INK}"/>`;
  s += `<path d="${rr(pad + 5, fy + side, W - 10, H - 5, r - 5)}" fill="${c[3]}"/>`;
  s += `<path d="${rr(pad, fy, W, H, r)}" fill="${INK}"/>`;
  s += `<path d="${rr(pad + 5, fy + 5, W - 10, H - 10, r - 5)}" fill="url(#${id}f)" filter="url(#bevelsoft)"/>`;
  s += `<g clip-path="url(#${id}c)">`;
  s += `<rect x="0" y="0" width="${w}" height="${h}" fill="#fff" filter="url(#grain)" opacity="0.35"/>`;
  s += `<path d="${rr(pad + 5, fy + H - 30, W - 10, 40, 20)}" fill="#000" opacity="${down ? 0.1 : 0.22}" filter="url(#soft2)"/>`;
  s += `<path d="${rr(pad + 16, fy + 11, W - 32, H * 0.36, 18)}" fill="url(#gloss)" opacity="${down ? 0.6 : 1}"/>`;
  s += `</g>`;
  s += `<path d="${rr(pad + 6, fy + 6, W - 12, H - 12, r - 6)}" fill="none" stroke="#fff" stroke-opacity="0.45" stroke-width="2"/>`;
  return s;
}

// Text as the best mobile HUDs set it: a gradient fill, a thick ink stroke
// and a hard drop the same ink, in Lilita One.
function display(text, x, y, size, fill, anchor = 'middle', stroke = 0) {
  const sw = stroke || Math.max(6, size * 0.16);
  const t = (dy, f, st) => `<text x="${x}" y="${y + dy}" font-family="Lilita" font-size="${size}" text-anchor="${anchor}"
    fill="${f}" stroke="${st}" stroke-width="${sw}" stroke-linejoin="round" paint-order="stroke">${text}</text>`;
  return t(size * 0.08, INK, INK) + t(0, `url(#${fill})`, INK);
}

// --- Icons, painted: dark outline, three tones, a specular dot. ---
function icon_door(cx, cy, s) {
  const k = s / 100;
  const T = (x, y) => `${cx + (x - 50) * k},${cy + (y - 50) * k}`;
  let g = `<g stroke="${INK}" stroke-width="${7 * k}" stroke-linejoin="round" stroke-linecap="round">`;
  g += `<path d="M${T(14, 8)} L${T(62, 8)} L${T(62, 92)} L${T(14, 92)} Z" fill="#3B1D10"/>`;
  g += `<path d="M${T(20, 14)} L${T(56, 14)} L${T(56, 92)} L${T(20, 92)} Z" fill="#7B3FD0"/>`;
  g += `<path d="M${T(20, 14)} L${T(48, 22)} L${T(48, 98)} L${T(20, 92)} Z" fill="#B5682A"/>`;
  g += `</g>`;
  g += `<path d="M${T(24, 20)} L${T(44, 25)} L${T(44, 40)} L${T(24, 36)} Z" fill="#E59A4E" opacity="0.8"/>`;
  g += `<circle cx="${cx + (41 - 50) * k}" cy="${cy + (58 - 50) * k}" r="${4.5 * k}" fill="#FFD866" stroke="${INK}" stroke-width="${2.5 * k}"/>`;
  g += `<path d="M${T(52, 56)} L${T(78, 56)} L${T(78, 44)} L${T(98, 64)} L${T(78, 84)} L${T(78, 72)} L${T(52, 72)} Z"
    fill="#5BE39A" stroke="${INK}" stroke-width="${7 * k}" stroke-linejoin="round"/>`;
  g += `<path d="M${T(56, 60)} L${T(80, 60)} L${T(80, 52)}" fill="none" stroke="#D8FFE8" stroke-width="${3.5 * k}" stroke-linecap="round"/>`;
  return g;
}

function icon_wand(cx, cy, s) {
  const k = s / 100;
  const T = (x, y) => `${cx + (x - 50) * k},${cy + (y - 50) * k}`;
  let g = `<path d="M${T(16, 90)} L${T(62, 40)}" stroke="${INK}" stroke-width="${20 * k}" stroke-linecap="round"/>`;
  g += `<path d="M${T(16, 90)} L${T(62, 40)}" stroke="#6B3A1C" stroke-width="${11 * k}" stroke-linecap="round"/>`;
  g += `<path d="M${T(18, 85)} L${T(58, 41)}" stroke="#C88A4A" stroke-width="${4 * k}" stroke-linecap="round"/>`;
  const star = (x, y, R, f) => {
    let p = '';
    for (let i = 0; i < 10; i++) {
      const a = -Math.PI / 2 + i * Math.PI / 5, rad = i % 2 ? R * 0.45 : R;
      p += (i ? 'L' : 'M') + T(x + Math.cos(a) * rad, y + Math.sin(a) * rad);
    }
    return `<path d="${p}Z" fill="${f}" stroke="${INK}" stroke-width="${6 * k}" stroke-linejoin="round"/>`;
  };
  g += `<circle cx="${cx + 18 * k}" cy="${cy - 22 * k}" r="${26 * k}" fill="#FFE07A" opacity="0.45" filter="url(#soft)"/>`;
  g += star(70, 28, 24, '#FFE07A');
  g += `<path d="M${T(64, 18)} L${T(70, 12)}" stroke="#FFFBEA" stroke-width="${4 * k}" stroke-linecap="round"/>`;
  g += star(30, 22, 10, '#9FE8FF') + star(88, 66, 9, '#FF9AE0');
  return g;
}

function icon_bell(cx, cy, s, lit, red) {
  const k = s / 100;
  const T = (x, y) => `${cx + (x - 50) * k},${cy + (y - 50) * k}`;
  const body = lit ? (red ? ['#FFB3BE', '#F2405C', '#9A1830'] : ['#FFF1B0', '#F5B83A', '#9C5A10']) : ['#7A6698', '#4E3C68', '#2E2044'];
  const id = 'g' + (uid++);
  let g = `<defs><linearGradient id="${id}" x1="0" y1="0" x2="1" y2="1"><stop offset="0" stop-color="${body[0]}"/>
    <stop offset="0.45" stop-color="${body[1]}"/><stop offset="1" stop-color="${body[2]}"/></linearGradient></defs>`;
  if (lit) g += `<circle cx="${cx}" cy="${cy}" r="${44 * k}" fill="${red ? '#FF4060' : '#FFC040'}" opacity="0.5" filter="url(#glow)"/>`;
  g += `<path d="M${T(50, 10)} C${T(74, 10)} ${T(78, 34)} ${T(78, 52)} L${T(90, 76)} L${T(10, 76)} L${T(22, 52)} C${T(22, 34)} ${T(26, 10)} ${T(50, 10)} Z"
    fill="url(#${id})" stroke="${INK}" stroke-width="${8 * k}" stroke-linejoin="round"/>`;
  g += `<circle cx="${cx}" cy="${cy + 34 * k}" r="${9 * k}" fill="${lit ? body[1] : '#2E1E40'}" stroke="${INK}" stroke-width="${6 * k}"/>`;
  if (lit) g += `<path d="M${T(34, 30)} C${T(36, 22)} ${T(42, 18)} ${T(48, 17)}" stroke="#fff" stroke-width="${6 * k}" stroke-linecap="round" fill="none" opacity="0.9"/>`;
  return g;
}

function icon_bag(cx, cy, s) {
  const k = s / 100;
  const T = (x, y) => `${cx + (x - 50) * k},${cy + (y - 50) * k}`;
  let g = `<path d="M${T(36, 28)} L${T(30, 12)} L${T(70, 12)} L${T(64, 28)} Z" fill="#B87A3A" stroke="${INK}" stroke-width="${7 * k}" stroke-linejoin="round"/>`;
  g += `<path d="M${T(36, 28)} C${T(8, 44)} ${T(8, 92)} ${T(50, 92)} C${T(92, 92)} ${T(92, 44)} ${T(64, 28)} Z"
    fill="#D99A50" stroke="${INK}" stroke-width="${7 * k}" stroke-linejoin="round"/>`;
  g += `<path d="M${T(60, 36)} C${T(80, 50)} ${T(82, 82)} ${T(52, 88)} C${T(76, 78)} ${T(74, 52)} ${T(58, 40)} Z" fill="#9A5E26"/>`;
  g += `<path d="M${T(34, 28)} L${T(66, 28)}" stroke="#F2405C" stroke-width="${8 * k}" stroke-linecap="round"/>`;
  g += `<circle cx="${cx}" cy="${cy + 12 * k}" r="${15 * k}" fill="#FFD866" stroke="${INK}" stroke-width="${5 * k}"/>`;
  g += `<text x="${cx}" y="${cy + 19 * k}" font-family="Lilita" font-size="${20 * k}" text-anchor="middle" fill="#9C5A10">✦</text>`;
  g += `<path d="M${T(28, 50)} C${T(28, 42)} ${T(32, 38)} ${T(38, 35)}" stroke="#FFE8C0" stroke-width="${5 * k}" stroke-linecap="round" fill="none"/>`;
  return g;
}

function gem(cx, cy, s, c) {
  const k = s / 100;
  const T = (x, y) => `${cx + (x - 50) * k},${cy + (y - 50) * k}`;
  let g = `<path d="M${T(50, 6)} L${T(92, 50)} L${T(50, 94)} L${T(8, 50)} Z" fill="${c[1]}" stroke="${INK}" stroke-width="${12 * k}" stroke-linejoin="round"/>`;
  g += `<path d="M${T(50, 6)} L${T(92, 50)} L${T(50, 50)} Z" fill="${c[0]}"/>`;
  g += `<path d="M${T(8, 50)} L${T(50, 94)} L${T(50, 50)} Z" fill="${c[2]}"/>`;
  g += `<path d="M${T(36, 30)} L${T(50, 16)}" stroke="#fff" stroke-width="${8 * k}" stroke-linecap="round"/>`;
  return g;
}

// A bar: a sunk track, or a glossy fill of three colours, as 9-slices.
function track(w, h) {
  const r = h / 2;
  let s = `<path d="${rr(0, 0, w, h, r)}" fill="${INK}"/>`;
  s += `<path d="${rr(3, 3, w - 6, h - 6, r - 3)}" fill="#160A22"/>`;
  s += `<path d="${rr(3, 3, w - 6, h * 0.45, (h * 0.45) / 2)}" fill="#000" opacity="0.5"/>`;
  s += `<path d="${rr(5, h - 7, w - 10, 3, 1.5)}" fill="#fff" opacity="0.12"/>`;
  return s;
}
function fillbar(w, h, c) {
  const r = h / 2, id = 'f' + (uid++);
  let s = `<defs><linearGradient id="${id}" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="${c[0]}"/>
    <stop offset="0.5" stop-color="${c[1]}"/><stop offset="1" stop-color="${c[2]}"/></linearGradient></defs>`;
  s += `<path d="${rr(0, 0, w, h, r)}" fill="url(#${id})"/>`;
  s += `<path d="${rr(5, 3, w - 10, h * 0.34, h * 0.17)}" fill="#fff" opacity="0.55"/>`;
  s += `<path d="${rr(0, 0, w, h, r)}" fill="none" stroke="${INK}" stroke-opacity="0.35" stroke-width="2"/>`;
  return s;
}

// A portrait's ring: lit gold over ink, the disc left clear; and the glow a
// chosen one stands in.
function ring(d, chosen) {
  const c = d / 2, R = c - 10, w = chosen ? 20 : 17;
  let s = `<circle cx="${c}" cy="${c + 6}" r="${R - w / 2}" fill="none" stroke="#000" stroke-width="${w + 4}" opacity="0.5" filter="url(#soft)"/>`;
  s += `<path d="M${c - R},${c} a${R},${R} 0 1 0 ${2 * R},0 a${R},${R} 0 1 0 ${-2 * R},0 Z
    M${c - R + w},${c} a${R - w},${R - w} 0 1 1 ${2 * (R - w)},0 a${R - w},${R - w} 0 1 1 ${-2 * (R - w)},0 Z"
    fill-rule="evenodd" fill="${INK}"/>`;
  const a = R - 4, b = R - w + 4;
  s += `<path d="M${c - a},${c} a${a},${a} 0 1 0 ${2 * a},0 a${a},${a} 0 1 0 ${-2 * a},0 Z
    M${c - b},${c} a${b},${b} 0 1 1 ${2 * b},0 a${b},${b} 0 1 1 ${-2 * b},0 Z"
    fill-rule="evenodd" fill="url(#gold)" filter="url(#bevel)"/>`;
  s += `<circle cx="${c}" cy="${c}" r="${b}" fill="none" stroke="#000" stroke-opacity="0.6" stroke-width="7" filter="url(#soft2)"/>`;
  s += `<path d="M${c - b + 10},${c - b * 0.25} A${b - 6},${b - 6} 0 0 1 ${c + b * 0.5},${c - b + 12}" fill="none"
    stroke="#fff" stroke-opacity="0.35" stroke-width="10" stroke-linecap="round" filter="url(#soft2)"/>`;
  if (chosen) {
    return `<circle cx="${c}" cy="${c}" r="${R - 3}" fill="none" stroke="#FFE07A" stroke-width="12" filter="url(#soft)"/>` + s;
  }
  return s;
}

// The pieces. Sizes are the phone's pixels at 1080 wide.
piece('frame_panel', 200, 190, panel(200, 190), { l: 50, t: 50, r: 50, b: 60 });
piece('frame_plaque', 200, 190, panel(200, 190, { r: 44, rim: 12, fill: 'enamel' }), { l: 64, t: 62, r: 64, b: 70 });
piece('frame_chip', 160, 110, panel(160, 110, { r: 26, rim: 6, pad: 10, drop: 7, studs: false }),
  { l: 40, t: 36, r: 40, b: 44 });
piece('bar_track', 120, 34, track(120, 34), { l: 17, t: 0, r: 17, b: 0 });
piece('bar_gold', 120, 34, fillbar(120, 34, ['#FFF0A0', '#F7B930', '#C97616']), { l: 17, t: 0, r: 17, b: 0 });
piece('bar_green', 120, 34, fillbar(120, 34, ['#B8FFB0', '#4CD964', '#1E9440']), { l: 17, t: 0, r: 17, b: 0 });
piece('bar_red', 120, 34, fillbar(120, 34, ['#FFC0C8', '#F2405C', '#A81A34']), { l: 17, t: 0, r: 17, b: 0 });
const RED = ['#FF8A98', '#F23D5C', '#B81838', '#7A0C22'];
const VIOLET = ['#B497FF', '#7B4FE0', '#4E2AA8', '#2E1470'];
for (const [n, c] of [['red', RED], ['violet', VIOLET]]) {
  piece(`btn_${n}`, 220, 190, button(220, 190, c, false));
  piece(`btn_${n}_down`, 220, 190, button(220, 190, c, true));
}
piece('ring', 176, 176, ring(176, false));
// A portrait's ground, white so one sprite takes every school's colour: lit
// from the top left, darker at its rim.
piece('disc', 128, 128, `<defs><radialGradient id="dg" cx="0.4" cy="0.32" r="0.75"><stop offset="0" stop-color="#fff"/>
  <stop offset="0.6" stop-color="#D8D8D8"/><stop offset="1" stop-color="#7A7A7A"/></radialGradient></defs>
  <circle cx="64" cy="64" r="62" fill="url(#dg)"/>`);
piece('ring_chosen', 176, 176, ring(176, true));
piece('icon_getout', 110, 110, icon_door(55, 55, 92));
piece('icon_cast', 110, 110, icon_wand(55, 55, 92));
piece('icon_bag', 96, 96, icon_bag(48, 48, 84));
piece('bell_off', 64, 64, icon_bell(32, 32, 54, false, false));
piece('bell_amber', 64, 64, icon_bell(32, 32, 54, true, false));
piece('bell_red', 64, 64, icon_bell(32, 32, 54, true, true));
piece('pip', 40, 40, gem(20, 20, 34, ['#E8FFFF', '#7FE6FF', '#2C8FD0']));
piece('pip_spent', 40, 40, gem(20, 20, 34, ['#5A4A70', '#3A2C50', '#241A34']));
piece('tick', 26, 58, `<path d="M5,4 L21,4 L13,20 Z" fill="#FFF4C2" stroke="${INK}" stroke-width="4" stroke-linejoin="round"/>
  <rect x="10" y="16" width="6" height="38" rx="3" fill="#FFF4C2" stroke="${INK}" stroke-width="3"/>`);
// Numerals, baked per glyph in three finishes (text stays live: only the
// digits, which never need translating, are pictures).
const GLYPHS = { '0': '0', '1': '1', '2': '2', '3': '3', '4': '4', '5': '5', '6': '6', '7': '7', '8': '8', '9': '9',
  colon: ':', comma: ',', slash: '/', tilde: '~', percent: '%', plus: '+', x: '×' };
for (const [style, size, fill] of [['timer', 104, 'whiteText'], ['timer_red', 104, 'redText'],
  ['gold', 62, 'goldText'], ['white', 50, 'whiteText']]) {
  for (const [k, ch] of Object.entries(GLYPHS)) {
    const h = Math.round(size * 1.35), w = Math.round(size * (ch === '1' ? 0.7 : ch === ':' || ch === ',' ? 0.45 : 0.8));
    piece(`num_${style}_${k}`, w, h, display(ch, w / 2, size * 1.0, size, fill));
  }
}

function page() {
  let html = `<!doctype html><html><head><meta charset="utf-8"><style>
    @font-face { font-family: Lilita; src: url('${lilita}'); }
    body { margin: 0; background: transparent; }
    .p { display: inline-block; margin: 0; line-height: 0; }
  </style></head><body><svg width="0" height="0" style="position:absolute"><defs>${defs}</defs></svg>`;
  for (const p of pieces) {
    html += `<div class="p" id="${p.name}"><svg xmlns="http://www.w3.org/2000/svg" width="${p.w}" height="${p.h}"
      viewBox="0 0 ${p.w} ${p.h}">${p.body}</svg></div>`;
  }
  return html + '<span style="font-family:Lilita">0</span></body></html>';
}

(async () => {
  const pieceDir = fs.mkdtempSync(path.join(os.tmpdir(), 'uiq-pieces-'));
  const browser = await chromium.launch();
  const tab = await browser.newPage({ viewport: { width: 1200, height: 900 }, deviceScaleFactor: 1 });
  const file = path.join(pieceDir, 'sheet.html');
  fs.writeFileSync(file, page());
  await tab.goto('file://' + file);
  await tab.evaluate(() => document.fonts.ready);
  const meta = {};
  for (const p of pieces) {
    await tab.locator('#' + p.name).screenshot({ path: path.join(pieceDir, p.name + '.png'), omitBackground: true });
    meta[p.name] = { slice: p.slice || null };
  }
  await browser.close();
  fs.writeFileSync(path.join(pieceDir, 'pieces.json'), JSON.stringify(meta));
  fs.mkdirSync(out, { recursive: true });
  process.stdout.write(execFileSync('python3', [path.join(__dirname, 'pack_atlas.py'), pieceDir, out]));
  fs.rmSync(pieceDir, { recursive: true });
  console.log(`baked ${pieces.length} pieces into ${path.relative(root, out)}`);
})();
