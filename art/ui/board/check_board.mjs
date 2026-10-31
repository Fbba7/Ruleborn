// The style board's scripted checks (section 3.3, step 2, of
// docs/art/ui-quality/report.md: "contrast in both modes and colours from
// the tokens"). In the normal and the high-contrast mode it checks that:
//
//   1. tokens.css is what build_tokens.mjs writes from client/ui/tokens.json,
//      and each colour it takes from the design document is written in the
//      section it cites;
//   2. board.html names no colour of its own: no colour literal in its styles,
//      and color-mix only fades one variable toward transparent;
//   3. every colour the page computes, on every element and pseudo-element,
//      is a colour of tokens.json or of that list, at some alpha;
//   4. every word marked data-check meets §21.8: Manrope, Marcellus or Lilita
//      One, loaded; 13 points or more (16 for body text); weight 800 or less;
//      no opacity; tabular figures on the number roles; and contrast of 4.5:1
//      and APCA's level for its size and weight (client/ui/colour_check.gd's
//      thresholds), against its ink outline when it has one of 1.5 points or
//      more, else against the pixels behind its letters at their worst point;
//   5. studio.html, which renders the icons and the studio, names no colour
//      of its own either: no literal, and every colour it names is a token;
//      It lights every piece in the toon look (§21.3, D5 (b)): no physically
//      based material, environment map, metalness or clear coat;
//   6. every hero icon in art/ keeps the outline rule: its silhouette is
//      edged in ink_line (in high contrast, in the text colour around the
//      ink) and the ink is as wide as the rule asks;
//   7. every control on board.png and board_hc.png stands two value steps
//      (ΔL* 20) off what it sits on: tools/ui_gate/checks.py value-steps on
//      the shots shoot_board.mjs writes beside them.
//
//   node art/ui/board/check_board.mjs [--out report.json]
//   node art/ui/board/check_board.mjs --self-test   plants faults; each must fail
import { readFileSync, writeFileSync, mkdtempSync } from 'node:fs';
import { tmpdir } from 'node:os';
import { execFileSync } from 'node:child_process';
import { dirname, join } from 'node:path';
import { fileURLToPath, pathToFileURL } from 'node:url';
import { createRequire } from 'node:module';
import { build, DESIGN } from './build_tokens.mjs';

const require = createRequire(import.meta.url);
const { chromium } = require('playwright');

const here = dirname(fileURLToPath(import.meta.url));
const root = join(here, '..', '..', '..');
const BOARD = join(here, 'board.html');
const STUDIO = join(here, 'studio.html');
const ART = join(here, 'art');
export const ICONS = ['starlight', 'essence', 'law', 'loot'];

// ---- colour arithmetic, as client/ui/colour_check.gd does it ----
const MIN_RATIO = 4.5;
const lin = (c) => (c <= 0.04045 ? c / 12.92 : ((c + 0.055) / 1.055) ** 2.4);
const lum = ([r, g, b]) => 0.2126 * lin(r / 255) + 0.7152 * lin(g / 255) + 0.0722 * lin(b / 255);
export const ratio = (a, b) => {
  const la = lum(a), lb = lum(b);
  return (Math.max(la, lb) + 0.05) / (Math.min(la, lb) + 0.05);
};
export function apca(text, bg) {
  const y = ([r, g, b]) => {
    const v = 0.2126729 * (r / 255) ** 2.4 + 0.7151522 * (g / 255) ** 2.4 + 0.072175 * (b / 255) ** 2.4;
    return v > 0.022 ? v : v + (0.022 - v) ** 1.414;
  };
  const yt = y(text), yb = y(bg);
  if (Math.abs(yb - yt) < 0.0005) return 0;
  if (yb > yt) {
    const s = (yb ** 0.56 - yt ** 0.57) * 1.14;
    return s < 0.1 ? 0 : (s - 0.027) * 100;
  }
  const s = (yb ** 0.65 - yt ** 0.62) * 1.14;
  return s > -0.1 ? 0 : Math.abs((s + 0.027) * 100);
}
export const lcNeeded = (points, bold) => (points >= 36 ? 45 : points >= 24 || bold ? 60 : 75);

const hexRgb = (h) => [1, 3, 5].map((i) => parseInt(h.slice(i, i + 2), 16));
const hex = ([r, g, b]) => '#' + [r, g, b].map((v) => Math.round(v).toString(16).padStart(2, '0')).join('').toUpperCase();

// Every colour a computed style can hold, as [r, g, b, a] with r, g, b in 0-255.
function parseColours(text) {
  const out = [];
  for (const m of text.matchAll(/rgba?\(([^)]*)\)/g)) {
    const p = m[1].split(/[\s,/]+/).filter(Boolean).map(Number);
    out.push([p[0], p[1], p[2], p.length > 3 ? p[3] : 1]);
  }
  for (const m of text.matchAll(/color\(srgb ([^)]*)\)/g)) {
    const p = m[1].split(/[\s/]+/).filter(Boolean).map(Number);
    out.push([p[0] * 255, p[1] * 255, p[2] * 255, p.length > 3 ? p[3] : 1]);
  }
  for (const m of text.matchAll(/\b(oklab|oklch|lab|lch|hsl|hwb)\(/g)) out.push(['unparsed', m[1]]);
  return out;
}

function allowedColours() {
  const set = new Map();
  const raw = readFileSync(join(root, 'client/ui/tokens.json'), 'utf8');
  for (const m of raw.matchAll(/"(#[0-9A-Fa-f]{6})(?:[0-9A-Fa-f]{2})?"/g)) set.set(m[1].toUpperCase(), 'tokens.json');
  for (const [name, [h, section]] of Object.entries(DESIGN)) set.set(h.toUpperCase(), `§${section} (${name})`);
  return set;
}
const near = (rgb, allowed) => {
  for (const h of allowed.keys()) {
    const t = hexRgb(h);
    if (Math.abs(t[0] - rgb[0]) <= 1.5 && Math.abs(t[1] - rgb[1]) <= 1.5 && Math.abs(t[2] - rgb[2]) <= 1.5) return h;
  }
  return null;
};

// ---- 1 and 2: the files ----
function designSection(id) {
  const out = execFileSync('python3', [join(root, 'tools/design_doc.py')], { cwd: root, encoding: 'utf8' });
  const v = out.match(/read v(\d+(?:\.\d+)*)/)[1];
  const lines = readFileSync(join(root, `docs/design/ruleborn-game-design-v${v}.txt`), 'utf8').split('\n');
  const start = lines.findIndex((l) => l.startsWith(`${id} `));
  const [maj, min] = id.split('.').map(Number);
  const end = lines.findIndex((l, i) => i > start && l.startsWith(`${maj}.${min + 1} `));
  return lines.slice(start, end).join('\n');
}

// The argument text of every call to `name(...)` in `code`, parentheses balanced.
function calls(code, name) {
  const out = [];
  for (let at = code.indexOf(name + '('); at >= 0; at = code.indexOf(name + '(', at + 1)) {
    let depth = 0, i = at + name.length;
    for (; i < code.length; i++) {
      if (code[i] === '(') depth++;
      else if (code[i] === ')' && --depth === 0) break;
    }
    out.push(code.slice(at + name.length + 1, i));
  }
  return out;
}

function checkFiles(html, tokensCss) {
  const fails = [];
  if (tokensCss !== build()) fails.push({ kind: 'tokens', what: 'tokens.css is out of date: run node art/ui/board/build_tokens.mjs' });
  for (const [name, [h, section]] of Object.entries(DESIGN)) {
    if (!designSection(section).toUpperCase().includes(h.toUpperCase())) fails.push({ kind: 'tokens', what: `${name} ${h} is not written in §${section}` });
  }
  const styles = [...html.matchAll(/<style>([\s\S]*?)<\/style>/g)].map((m) => m[1]);
  const attrs = [...html.matchAll(/\s(?:style|fill|stroke|stop-color|flood-color|color)="([^"]*)"/g)].map((m) => m[1]);
  for (const text of [...styles, ...attrs]) {
    const code = text.replace(/\/\*[\s\S]*?\*\//g, '');
    for (const m of code.matchAll(/#[0-9A-Fa-f]{3,8}\b|\b(?:rgba?|hsla?|hwb|lab|lch|oklab|oklch|color)\(/g)) {
      fails.push({ kind: 'literal', what: `a colour literal in board.html: ${m[0]}` });
    }
    for (const m of code.matchAll(/(?<![-.#\w])(?:white|black|red|green|blue|gold|silver|gray|grey|orange|purple|pink|brown|yellow)(?![-\w])/g)) {
      fails.push({ kind: 'literal', what: `a named colour in board.html: ${m[0]}` });
    }
    for (const inner of calls(code, 'color-mix')) {
      if (!/^in srgb, var\(--[\w-]+\) (?:[\d.]+%|calc\([^()]*(?:\([^()]*\))?[^()]*\)), transparent$/.test(inner.trim())) {
        fails.push({ kind: 'literal', what: `color-mix must fade one variable toward transparent: color-mix(${inner})` });
      }
    }
  }
  return fails;
}

// The colours behind each word's letters. A pixel inside a word's boxes that
// differs between `black` and `white` (the words drawn in each) is under a
// letter. The letters are widened by RADIUS pixels for their antialiased
// edge, and the colours of `ground` (the words gone) under them are what the
// word is read against. The browser's own canvas decodes the screenshots.
const RADIUS = 2;
async function pixelsBehind(context, black, white, ground, rectLists) {
  const page = await context.newPage();
  try {
    return await page.evaluate(async ([a, b, c, lists, radius]) => {
      const read = async (src) => {
        const img = new Image();
        img.src = src;
        await img.decode();
        const canvas = document.createElement('canvas');
        canvas.width = img.width;
        canvas.height = img.height;
        const g = canvas.getContext('2d', { willReadFrequently: true });
        g.drawImage(img, 0, 0);
        return g.getImageData(0, 0, img.width, img.height);
      };
      const A = await read(a), K = await read(b), B = await read(c);
      const W = Math.min(A.width, K.width, B.width), H = Math.min(A.height, K.height, B.height);
      return lists.map((rects) => {
        const seen = new Map();
        for (const [x, y, w, h] of rects) {
          const x0 = Math.max(0, Math.floor(x)), y0 = Math.max(0, Math.floor(y));
          const x1 = Math.min(W, Math.ceil(x + w)), y1 = Math.min(H, Math.ceil(y + h));
          const ink = new Uint8Array((x1 - x0) * (y1 - y0));
          for (let py = y0; py < y1; py++) {
            for (let px = x0; px < x1; px++) {
              const i = (py * A.width + px) * 4;
              const d = Math.abs(A.data[i] - K.data[i]) + Math.abs(A.data[i + 1] - K.data[i + 1]) + Math.abs(A.data[i + 2] - K.data[i + 2]);
              if (d > 24) ink[(py - y0) * (x1 - x0) + (px - x0)] = 1;
            }
          }
          for (let py = y0; py < y1; py++) {
            for (let px = x0; px < x1; px++) {
              let near = false;
              for (let dy = -radius; dy <= radius && !near; dy++) {
                for (let dx = -radius; dx <= radius && !near; dx++) {
                  const qx = px + dx - x0, qy = py + dy - y0;
                  if (qx >= 0 && qy >= 0 && qx < x1 - x0 && qy < y1 - y0 && ink[qy * (x1 - x0) + qx]) near = true;
                }
              }
              if (!near) continue;
              const i = (py * B.width + px) * 4;
              seen.set((B.data[i] << 16) | (B.data[i + 1] << 8) | B.data[i + 2], [B.data[i], B.data[i + 1], B.data[i + 2]]);
            }
          }
        }
        return [...seen.values()];
      });
    }, [black, white, ground].map((png) => 'data:image/png;base64,' + png.toString('base64')).concat([rectLists, RADIUS]));
  } finally {
    await page.close();
  }
}


// ---- 5: the studio's colours ----
function checkStudio(code) {
  const fails = [];
  const tokens = JSON.parse(readFileSync(join(root, 'client/ui/tokens.json'), 'utf8')).color;
  const body = code.replace(/<!--[\s\S]*?-->/g, '').replace(/\/\/.*$/gm, '');
  for (const m of body.matchAll(/#[0-9A-Fa-f]{3,8}\b|\b0x[0-9A-Fa-f]{3,8}\b/g)) {
    fails.push({ kind: 'literal', what: `a colour literal in studio.html: ${m[0]}` });
  }
  for (const m of body.matchAll(/(?<![-.#\w'])(?:white|black|red|green|blue|silver|gray|grey|orange|purple|pink|brown|yellow)(?![-\w])/g)) {
    fails.push({ kind: 'literal', what: `a named colour in studio.html: ${m[0]}` });
  }
  // Every quoted name handed to the studio's colour functions, or set as a
  // piece's light, glint, ink or drop, must be a colour token.
  const names = new Set();
  for (const fn of ['tok', 'rgba', 'toon', 'gold', 'enamel', 'cloth', 'studio']) {
    for (const inner of calls(body, fn)) for (const m of inner.matchAll(/'([a-z_]+)'/g)) names.add(m[1]);
  }
  for (const m of body.matchAll(/\b(?:colour|sky|ground|light|ink|keyline|drop|glint): '([a-z_]+)'/g)) names.add(m[1]);
  for (const m of body.matchAll(/inner: \[[^\]]*'([a-z_]+)'/g)) names.add(m[1]);
  for (const n of names) if (!tokens[n]) fails.push({ kind: 'colour', what: `studio.html names ${n}, which is not a colour of tokens.json` });
  if (names.size < 10) fails.push({ kind: 'colour', what: `studio.html names only ${names.size} token colours; the check found too few to trust` });
  // The toon look: one ramp, no physically based light.
  for (const m of body.matchAll(/\b(?:Mesh(?:Physical|Standard|Phong|Lambert)Material|RoomEnvironment|PMREMGenerator|envMap\w*|metalness|clearcoat\w*|sheen\w*|transmission)\b/g)) {
    fails.push({ kind: 'pbr', what: `studio.html lights a piece outside the toon look: ${m[0]}` });
  }
  if (!/toonRamp/.test(body)) fails.push({ kind: 'pbr', what: 'studio.html has no toon ramp' });
  return fails;
}

// ---- 7: the value step of every control ----
const SHOTS = [join(here, 'board.shot.json'), join(here, 'board_hc.shot.json')];
function checkSteps(shots) {
  const fails = [];
  for (const shot of shots) {
    let out;
    try {
      out = execFileSync('python3', [join(root, 'tools/ui_gate/checks.py'), 'value-steps', shot], { encoding: 'utf8' });
    } catch (e) {
      out = String(e.stdout ?? '');
      if (!out) { fails.push({ kind: 'value-steps', what: `checks.py value-steps did not run on ${shot}: ${e.message}` }); continue; }
    }
    const rows = out.trim().split('\n').filter(Boolean).map((l) => JSON.parse(l));
    if (!rows.length) fails.push({ kind: 'value-steps', what: `${shot} has no controls` });
    for (const r of rows.filter((r) => r.result !== 'PASS')) {
      fails.push({ kind: 'value-steps', what: `${r.control} in ${shot.split('/').pop()}: ΔL* ${r.delta_L ?? '?'}, needs 20` });
    }
  }
  return fails;
}

// ---- 6: the outline rule, read from the icons' pixels ----
// The opaque silhouette (alpha 0.98 or more; the glow and the drop stay
// under it) is walked: its edge pixels must be the outline's colour, and the
// ink's area over the edge's length is the outline's mean width. The rule
// (studio.html's RULES) is 2 points at 48, so 1/24 of the box; 3 points in
// high contrast, inside a 1.5-point ring of the text colour.
export async function checkIcons(context, files = null) {
  const toks = JSON.parse(readFileSync(join(root, 'client/ui/tokens.json'), 'utf8')).color;
  const col = (n) => hexRgb(toks[n].value.slice(0, 7));
  const list = files ?? ICONS.flatMap((n) => [[n, 'normal'], [n, 'hc']]).map(([n, f]) => ({
    name: n + (f === 'hc' ? '_hc' : ''), file: join(ART, n + (f === 'hc' ? '_hc' : '') + '.png'), form: f }));
  const fails = [];
  const page = await context.newPage();
  try {
    for (const it of list) {
      let png;
      try { png = readFileSync(it.file); } catch { fails.push({ kind: 'icon', what: `${it.name}: ${it.file} is missing; run bake_art.mjs` }); continue; }
      const hc = it.form === 'hc';
      const edgeColour = hc ? col('text_on_night') : col('ink_line');
      const r = await page.evaluate(async ([src, ink, edge]) => {
        const img = new Image();
        img.src = src;
        await img.decode();
        const c = document.createElement('canvas');
        c.width = img.width; c.height = img.height;
        const g = c.getContext('2d', { willReadFrequently: true });
        g.drawImage(img, 0, 0);
        const W = c.width, H = c.height;
        const { data } = g.getImageData(0, 0, W, H);
        const at = (x, y) => (y * W + x) * 4;
        const solid = (x, y) => x >= 0 && y >= 0 && x < W && y < H && data[at(x, y) + 3] >= 250;
        const near = (i, rgb) => Math.abs(data[i] - rgb[0]) + Math.abs(data[i + 1] - rgb[1]) + Math.abs(data[i + 2] - rgb[2]) <= 48;
        let edgeN = 0, edgeOk = 0, inkN = 0, corners = 0;
        for (const [x, y] of [[0, 0], [W - 1, 0], [0, H - 1], [W - 1, H - 1]]) corners += data[at(x, y) + 3];
        for (let y = 0; y < H; y++) for (let x = 0; x < W; x++) {
          if (!solid(x, y)) continue;
          const i = at(x, y);
          if (near(i, ink)) inkN++;
          if (solid(x - 1, y) && solid(x + 1, y) && solid(x, y - 1) && solid(x, y + 1)) continue;
          edgeN++;
          if (near(i, edge)) edgeOk++;
        }
        return { W, H, edgeN, edgeOk, inkN, corners };
      }, ['data:image/png;base64,' + png.toString('base64'), col('ink_line'), edgeColour]);
      const width = r.inkN / Math.max(1, r.edgeN);
      const need = (hc ? 3 : 2) / 48 * r.W * 0.75;
      if (r.W !== 256 || r.H !== 256) fails.push({ kind: 'icon', what: `${it.name}: ${r.W} x ${r.H}, not 256 x 256` });
      if (r.corners > 0) fails.push({ kind: 'icon', what: `${it.name}: its corners are not transparent` });
      if (r.edgeOk / Math.max(1, r.edgeN) < 0.9) fails.push({ kind: 'icon', what: `${it.name}: ${Math.round(100 * r.edgeOk / r.edgeN)}% of its edge is the outline's colour; the rule wants all of it` });
      if (width < need) fails.push({ kind: 'icon', what: `${it.name}: the ink outline is ${width.toFixed(1)} px wide on average; the rule wants ${(need / 0.75).toFixed(1)}` });
      it.result = { edge: +(r.edgeOk / r.edgeN).toFixed(3), ink_px: +width.toFixed(1) };
    }
  } finally {
    await page.close();
  }
  return { fails, list };
}

// ---- 3 and 4: the page, in one mode ----
const COLOUR_PROPS = ['color', 'backgroundColor', 'backgroundImage', 'borderTopColor', 'borderRightColor',
  'borderBottomColor', 'borderLeftColor', 'boxShadow', 'textShadow', 'outlineColor', 'webkitTextStrokeColor',
  'webkitTextFillColor', 'fill', 'stroke', 'floodColor', 'stopColor', 'lightingColor', 'textDecorationColor', 'columnRuleColor'];

async function checkMode(page, mode, allowed, inject) {
  const fails = [];
  const rows = [];
  await page.goto(pathToFileURL(BOARD).href + (mode === 'hc' ? '?hc=1' : ''));
  if (inject) await page.addStyleTag({ content: inject });
  await page.evaluate(() => document.fonts.ready);
  await page.waitForTimeout(150);

  const faces = await page.evaluate(() => [...document.fonts].map((f) => [f.family.replace(/"/g, ''), f.status]));
  for (const [family, status] of faces) if (status !== 'loaded') fails.push({ kind: 'font', what: `${family} did not load (${status})` });

  // 3: every computed colour.
  const computed = await page.evaluate((props) => {
    const out = [];
    for (const el of document.querySelectorAll('*')) {
      if (el.closest('defs') && !['feFlood', 'stop'].includes(el.tagName)) continue;
      for (const pseudo of [null, '::before', '::after']) {
        const cs = getComputedStyle(el, pseudo);
        if (pseudo && (cs.content === 'none' || cs.content === 'normal')) continue;
        if (cs.display === 'none') continue;
        for (const p of props) {
          const v = cs[p];
          if (v && v !== 'none') out.push([el.tagName.toLowerCase() + (el.id ? '#' + el.id : '') + (el.className && el.className.baseVal === undefined ? '.' + String(el.className).split(' ').join('.') : '') + (pseudo || ''), p, v]);
        }
      }
    }
    return out;
  }, COLOUR_PROPS);
  const seen = new Set();
  for (const [where, prop, value] of computed) {
    for (const c of parseColours(value)) {
      if (c[0] === 'unparsed') { fails.push({ kind: 'colour', what: `${where} ${prop}: a ${c[1]}() colour the check cannot read` }); continue; }
      if (c[3] === 0) continue;
      if (!near(c, allowed)) {
        const key = `${hex(c)} ${prop}`;
        if (!seen.has(key)) fails.push({ kind: 'colour', what: `${where} ${prop}: ${hex(c)} is not a token colour` });
        seen.add(key);
      }
    }
  }

  // 4: the words.
  const texts = await page.evaluate(() => {
    const out = [];
    document.querySelectorAll('[data-check]').forEach((el, i) => {
      el.setAttribute('data-check-id', i);
      const cs = getComputedStyle(el);
      let opacity = 1;
      for (let n = el; n && n.nodeType === 1; n = n.parentElement) opacity *= +getComputedStyle(n).opacity;
      const after = getComputedStyle(el, '::after');
      const range = document.createRange();
      range.selectNodeContents(el);
      const rects = [...range.getClientRects()].map((r) => [r.left + scrollX, r.top + scrollY, r.width, r.height]);
      const family = cs.fontFamily.split(',')[0].replace(/"/g, '').trim();
      out.push({
        id: i, text: el.textContent.trim().slice(0, 40), cls: el.className,
        roles: [el.className, el.parentElement.className].join(' '),
        color: cs.color, fillImage: after.content !== 'none' ? after.backgroundImage : '',
        size: parseFloat(cs.fontSize), weight: +cs.fontWeight, family, tnum: cs.fontVariantNumeric,
        loaded: document.fonts.check(`${cs.fontWeight} ${cs.fontSize} "${family}"`),
        strokeW: parseFloat(cs.webkitTextStrokeWidth) || 0, strokeColor: cs.webkitTextStrokeColor,
        opacity, rects,
      });
    });
    return out;
  });

  // The pixels behind every word's letters. The letters are found by drawing
  // the words bare in black, then in white: a pixel that changes is under a
  // letter, whatever the ground. The ground is photographed with the words
  // gone. (These probe colours are drawn after the colour checks above.)
  // Inline and important, so no rule of the page outranks the probe.
  const probe = (colour) => page.evaluate((c) => {
    if (!document.getElementById('check-probe')) {
      const el = document.createElement('style');
      el.id = 'check-probe';
      el.textContent = '[data-check]::after{content:none!important}';
      document.head.append(el);
    }
    for (const el of document.querySelectorAll('[data-check]')) {
      el.style.setProperty('color', c, 'important');
      el.style.setProperty('-webkit-text-stroke-color', 'transparent', 'important');
      el.style.setProperty('text-shadow', 'none', 'important');
    }
  }, colour);
  await probe('#000');
  const black = await page.screenshot({ fullPage: true });
  await probe('#fff');
  const white = await page.screenshot({ fullPage: true });
  await probe('transparent');
  const ground = await page.screenshot({ fullPage: true });
  const behind = await pixelsBehind(page.context(), black, white, ground, texts.map((t) => t.rects));

  for (const t of texts) {
    const name = `"${t.text}"`;
    const fgs = [];
    if (t.fillImage && /transparent|rgba\(0, 0, 0, 0\)/.test(t.color)) {
      fgs.push(...parseColours(t.fillImage).filter((c) => c[3] > 0));
    } else {
      const [c] = parseColours(t.color);
      if (!c || c[3] < 1) fails.push({ kind: 'opacity', what: `${name}: words carry no opacity (colour ${t.color})` });
      if (c) fgs.push(c);
    }
    for (const c of fgs) if (!near(c, allowed)) fails.push({ kind: 'colour', what: `${name}: ${hex(c)} is not a token colour` });
    if (t.opacity < 1) fails.push({ kind: 'opacity', what: `${name}: drawn at opacity ${t.opacity.toFixed(2)}` });
    if (!['Manrope', 'Marcellus', 'Lilita One'].includes(t.family)) fails.push({ kind: 'type', what: `${name}: ${t.family} is not one of §21.8's faces` });
    if (!t.loaded) fails.push({ kind: 'font', what: `${name}: ${t.family} ${t.weight} is not loaded` });
    if (t.size < 13) fails.push({ kind: 'type', what: `${name}: ${t.size} points, under §21.8's 13` });
    if (/\bbody(-bold)?\b/.test(t.cls) && t.size < 16) fails.push({ kind: 'type', what: `${name}: body text at ${t.size} points, under 16` });
    if (t.weight > 800) fails.push({ kind: 'type', what: `${name}: weight ${t.weight}; §21.8 draws 900 at 800` });
    if (/\bnumber(-m)?\b/.test(t.roles) && !/tabular-nums/.test(t.tnum)) fails.push({ kind: 'type', what: `${name}: a number role without tabular figures` });

    const bold = t.weight >= 700;
    const need = lcNeeded(t.size, bold);
    const outline = t.strokeW / 2;
    let against, worstRatio = Infinity, worstLc = Infinity, worstBg = null;
    const measure = (fg, bg) => {
      const r = ratio(fg, bg), lc = apca(fg, bg);
      if (r < worstRatio || (r === worstRatio && lc < worstLc)) { worstRatio = r; worstBg = bg; }
      worstLc = Math.min(worstLc, lc);
    };
    if (outline >= 1.5 || (outline > 0 && outline >= 0.12 * t.size)) {
      against = `its ${outline}-point ink outline`;
      const [oc] = parseColours(t.strokeColor);
      if (!near(oc, allowed)) fails.push({ kind: 'colour', what: `${name}: outline ${hex(oc)} is not a token colour` });
      for (const fg of fgs) measure(fg, oc);
    } else {
      against = 'the pixels behind its letters, at their worst';
      if (outline > 0) fails.push({ kind: 'type', what: `${name}: an outline of ${outline} points is under 1.5, so it is measured against the ground` });
      const bgs = behind[texts.indexOf(t)];
      if (!bgs.length) fails.push({ kind: 'layout', what: `${name}: no pixels behind it to measure` });
      for (const fg of fgs) for (const bg of bgs) measure(fg, bg);
    }
    const ok = worstRatio >= MIN_RATIO && worstLc >= need;
    rows.push({ mode, text: t.text, family: t.family, points: t.size, weight: t.weight, fg: fgs.map(hex), against,
      worst_bg: worstBg ? hex(worstBg) : null, ratio: +worstRatio.toFixed(2), lc: +worstLc.toFixed(1), lc_needed: need, ok });
    if (!ok) fails.push({ kind: 'contrast', what: `${name} (${mode}): ${worstRatio.toFixed(2)}:1, Lc ${worstLc.toFixed(0)} on ${worstBg ? hex(worstBg) : '?'} against ${against}; needs ${MIN_RATIO}:1 and Lc ${need} at ${t.size} points${bold ? ' bold' : ''}` });
  }
  return { fails, rows };
}

export async function run({ inject = null, html = null, tokensCss = null, studio = null, icons = null, shots = null } = {}) {
  const allowed = allowedColours();
  const fails = checkFiles(html ?? readFileSync(BOARD, 'utf8'), tokensCss ?? readFileSync(join(here, 'tokens.css'), 'utf8'));
  fails.push(...checkStudio(studio ?? readFileSync(STUDIO, 'utf8')));
  fails.push(...checkSteps(shots ?? SHOTS));
  const rows = [];
  const browser = await chromium.launch();
  try {
    const context = await browser.newContext({ viewport: { width: 1160, height: 900 }, deviceScaleFactor: 1 });
    const page = await context.newPage();
    const errors = [];
    page.on('pageerror', (e) => errors.push(e.message));
    page.on('requestfailed', (r) => errors.push(`failed to load ${r.url()}`));
    for (const mode of ['normal', 'hc']) {
      const r = await checkMode(page, mode, allowed, inject);
      fails.push(...r.fails.map((f) => ({ ...f, what: f.what.includes(`(${mode})`) ? f.what : `[${mode}] ${f.what}` })));
      rows.push(...r.rows);
    }
    for (const e of errors) fails.push({ kind: 'page', what: e });
    const ic = await checkIcons(context, icons);
    fails.push(...ic.fails);
    rows.push(...ic.list.map((i) => ({ mode: 'icon', text: i.name, ...i.result, ok: !ic.fails.some((f) => f.what.startsWith(i.name + ':')) })));
  } finally {
    await browser.close();
  }
  return { fails, rows };
}

// A shot whose one control is a patch of the night with the night around it.
function flatShot() {
  const shot = JSON.parse(readFileSync(SHOTS[0], 'utf8'));
  const at = join(mkdtempSync(join(tmpdir(), 'board-')), 'flat.shot.json');
  writeFileSync(at, JSON.stringify({ ...shot, image: join(here, shot.image), controls: [{ name: 'a patch of night', rect: [150, 8, 40, 4] }] }));
  return at;
}

async function selfTest() {
  const html = readFileSync(BOARD, 'utf8');
  const css = readFileSync(join(here, 'tokens.css'), 'utf8');
  const studio = readFileSync(STUDIO, 'utf8');
  const cases = [
    ['a clean board passes', {}, null],
    ['a hue of its own fails', { inject: '#enamel .title{color:#123456!important}' }, 'colour'],
    ['a low-contrast word fails', { inject: '#parchment .body{color:var(--c-stone)!important}' }, 'contrast'],
    ['words at an opacity fail', { inject: '#gold .note{opacity:.7}' }, 'opacity'],
    ['a word under 13 points fails', { inject: '#type .caption{font-size:12px!important}' }, 'type'],
    ['an outline under 1.5 points is not measured against', { inject: '.display{--o:1px!important}' }, 'type'],
    ['a colour literal in the page fails', { html: html.replace('.world { position: relative;', '.world { color: #FF00FF; position: relative;') }, 'literal'],
    ['a mix of two colours fails', { html: html.replace('--lit-none: color-mix(in srgb, var(--c-paper) 0%, transparent);', '--lit-none: color-mix(in srgb, var(--c-paper) 50%, var(--c-ink));') }, 'literal'],
    ['stale tokens.css fails', { tokensCss: css.replace('--c-gold: #E9B65C;', '--c-gold: #E9B65D;') }, 'tokens'],
    ['a colour literal in the studio fails', { studio: studio.replace("saturation: 1.1,", "saturation: 1.1, tint: 0xFF00FF,") }, 'literal'],
    ['a physically based material in the studio fails', { studio: studio.replace("const cloth = (face) => toon(face);", "const cloth = (face) => new THREE.MeshStandardMaterial({ roughness: 0.8 });") }, 'pbr'],
    ['a control without its value step fails', { shots: [flatShot()] }, 'value-steps'],
    ['a studio colour that is not a token fails', { studio: studio.replace("studio('time_light')", "studio('time_glow')") }, 'colour'],
    ['an icon without its outline fails', { icons: [{ name: 'finish_1', file: join(ART, 'finish_1.png'), form: 'normal' }] }, 'icon'],
    ['an icon with a thin outline fails', { icons: [{ name: 'starlight as hc', file: join(ART, 'starlight.png'), form: 'hc' }] }, 'icon'],
  ];
  let bad = 0;
  for (const [what, opts, kind] of cases) {
    const { fails } = await run(opts);
    const ok = kind === null ? fails.length === 0 : fails.some((f) => f.kind === kind);
    console.log(`${ok ? 'ok  ' : 'FAIL'} ${what}${ok ? '' : `: got ${fails.map((f) => f.kind + ': ' + f.what).slice(0, 3).join('; ') || 'no failure'}`}`);
    if (!ok) bad++;
  }
  if (bad) { console.error(`${bad} self-test case(s) failed`); process.exit(1); }
  console.log('check_board self-test passed');
}

if (import.meta.url === pathToFileURL(process.argv[1]).href) {
  if (process.argv.includes('--self-test')) {
    await selfTest();
  } else {
    const { fails, rows } = await run();
    const outAt = process.argv.indexOf('--out');
    if (outAt > 0) writeFileSync(process.argv[outAt + 1], JSON.stringify({ rows, fails }, null, 1) + '\n');
    const words = rows.filter((r) => r.mode !== 'icon'), icons = rows.filter((r) => r.mode === 'icon');
    console.log(`words checked: ${words.length} (${words.filter((r) => r.ok).length} pass) across the normal and high-contrast modes`);
    console.log(`icons checked: ${icons.length} (${icons.filter((r) => r.ok).length} keep the outline rule): ${icons.map((r) => `${r.text} ${r.ink_px} px`).join(', ')}`);
    for (const r of words.filter((r) => !r.ok)) console.log(`  low: [${r.mode}] "${r.text}" ${r.ratio}:1 Lc ${r.lc} (needs ${r.lc_needed}) on ${r.worst_bg}`);
    for (const f of fails) console.log(`FAIL ${f.kind}: ${f.what}`);
    if (fails.length) process.exit(1);
    console.log('style board checks passed');
  }
}
