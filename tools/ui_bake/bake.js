// The UI kit's bake (kit-spec.md section 6.6; report.md section 3, K1).
//
//   node tools/ui_bake/bake.js <family>...      bake the families named
//   node tools/ui_bake/bake.js --check [family...]   compare hashes, in seconds
//   node tools/ui_bake/bake.js --palette [family...]   write <art>/palette.json
//                                               (then bake the families named)
//
// Options: --art DIR (default art/ui), --out DIR (default client/ui/art),
// --config FILE (default tools/ui_bake/families.json), --tokens FILE
// (default client/ui/tokens.json). The tests use them to bake a fixture
// family into a scratch folder.
//
// A family of kind "scene" (the icons) is drawn by its own studio,
// art/ui/icons/studio/bake_icons.js, which this calls; its manifest has
// px_per_point null. A family whose pieces outgrow one 2048x2048 atlas is
// split into pages: <family>.webp, <family>_2.webp, ..., each with its _hc
// twin (kit-spec.md section 6.6). --palette writes art/ui/palette.json
// from tokens.json (kit-spec.md section 6.2), keeping the file's `kit`
// section, and --check compares it with tokens.json when it exists.
// A family whose entry in families.json names a "curves" file (the motion
// family: curves.json, report.md step 8) carries that file's JSON in its
// manifest's top-level `curves`, so the client reads the timings with the
// sprites; --check fails when the two differ.
//
// A family's sources live in <art>/<dir>/; the bake draws each source's faces
// in headless Chromium, once in the normal form and once in its high-contrast
// twin, packs both sets into two atlases with one layout (pack.py writes the
// lossless WebP files), and writes the manifest with sorted keys and a final
// newline, so a rebake is byte for byte. The source format is in README.md.
'use strict';
const fs = require('fs');
const os = require('os');
const path = require('path');
const crypto = require('crypto');
const { execFileSync } = require('child_process');

const HERE = __dirname;
const ROOT = path.resolve(HERE, '../..');
// The bake's own scripts, hashed with every family's sources: a change to
// how pieces are drawn or packed makes every manifest stale.
const SCRIPTS = ['bake.js', 'pack.py'];
const STATES = ['normal', 'pressed', 'disabled', 'locked'];
const MAX_SIDE = 2048;
const PAD = 2;
const NAME = /^[a-z0-9]+(_[a-z0-9]+)*$/;

class Refusal extends Error {}

function refuse(msg) {
  throw new Refusal(msg);
}

function parseArgs(argv) {
  const opts = {
    check: false,
    palette: false,
    families: [],
    art: path.join(ROOT, 'art/ui'),
    tokens: path.join(ROOT, 'client/ui/tokens.json'),
    out: path.join(ROOT, 'client/ui/art'),
    config: path.join(HERE, 'families.json'),
  };
  for (let i = 0; i < argv.length; i++) {
    const a = argv[i];
    if (a === '--check') opts.check = true;
    else if (a === '--palette') opts.palette = true;
    else if (a === '--art' || a === '--out' || a === '--config' || a === '--tokens') {
      if (i + 1 >= argv.length) refuse(`${a} needs a path`);
      opts[a.slice(2)] = path.resolve(argv[++i]);
    } else if (a.startsWith('-')) refuse(`unknown option ${a}`);
    else opts.families.push(a);
  }
  return opts;
}

function loadConfig(file) {
  const cfg = JSON.parse(fs.readFileSync(file, 'utf8'));
  cfg.file = file;
  return cfg;
}

// Every file under dir, as paths relative to base with forward slashes,
// sorted by code point so the order never depends on the file system.
function listFiles(dir, base) {
  if (!fs.existsSync(dir)) return [];
  const out = [];
  for (const e of fs.readdirSync(dir, { withFileTypes: true })) {
    const full = path.join(dir, e.name);
    if (e.isDirectory()) out.push(...listFiles(full, base));
    else if (e.isFile()) out.push(path.relative(base, full).split(path.sep).join('/'));
  }
  return out.sort((a, b) => (a < b ? -1 : a > b ? 1 : 0));
}

function sources(cfg, family, art) {
  return listFiles(path.join(art, cfg.families[family].dir), art);
}

function feed(h, name, file) {
  h.update(name);
  h.update(Buffer.from([0]));
  h.update(fs.readFileSync(file));
  h.update(Buffer.from([0]));
}

// SHA-256 over the family's sources (path relative to art/ui, a zero byte,
// the bytes, a zero byte, in sorted path order), then the bake's own inputs
// the same way: its scripts, the families file and the fonts it draws with,
// each named by its path from the repository root.
function sourcesHash(cfg, family, art) {
  const h = crypto.createHash('sha256');
  for (const rel of sources(cfg, family, art)) feed(h, rel, path.join(art, rel));
  const own = SCRIPTS.map((s) => path.join(HERE, s)).concat([cfg.file]);
  for (const f of Object.keys(cfg.fonts || {}).sort()) own.push(path.join(ROOT, cfg.fonts[f]));
  for (const file of own) feed(h, path.relative(ROOT, file).split(path.sep).join('/'), file);
  return 'sha256:' + h.digest('hex');
}

// The family's curves (its "curves" file in its source folder, parsed), or
// undefined when the family names none. A named file that is missing or not
// JSON refuses the bake.
function curves(cfg, family, art) {
  const name = cfg.families[family].curves;
  if (name === undefined) return undefined;
  const file = path.join(art, cfg.families[family].dir, name);
  if (!fs.existsSync(file)) refuse(`${family}: its curves file ${path.relative(ROOT, file)} is missing`);
  try {
    return JSON.parse(fs.readFileSync(file, 'utf8'));
  } catch (e) {
    refuse(`${family}: ${path.relative(ROOT, file)} is not JSON: ${e.message}`);
  }
}

function sortKeys(v) {
  if (Array.isArray(v)) return v.map(sortKeys);
  if (v && typeof v === 'object') {
    const o = {};
    for (const k of Object.keys(v).sort()) o[k] = sortKeys(v[k]);
    return o;
  }
  return v;
}

// The manifest's one layout: top-level keys a line each, a piece a line each.
function manifestText(m) {
  const lines = [];
  const keys = Object.keys(m).sort();
  keys.forEach((k, i) => {
    const comma = i < keys.length - 1 ? ',' : '';
    if (k === 'pieces') {
      const names = Object.keys(m.pieces).sort();
      if (names.length === 0) {
        lines.push(`  "pieces": {}${comma}`);
        return;
      }
      lines.push('  "pieces": {');
      names.forEach((n, j) => {
        const c = j < names.length - 1 ? ',' : '';
        lines.push(`    ${JSON.stringify(n)}: ${JSON.stringify(sortKeys(m.pieces[n]))}${c}`);
      });
      lines.push(`  }${comma}`);
    } else {
      lines.push(`  ${JSON.stringify(k)}: ${JSON.stringify(sortKeys(m[k]))}${comma}`);
    }
  });
  return '{\n' + lines.join('\n') + '\n}\n';
}

// --- The art's palette (kit-spec.md section 6.2) ------------------------

const PALETTE_WHAT = 'The art\'s palette, generated from client/ui/tokens.json by tools/ui_bake/bake.js ' +
  '(kit-spec.md section 6.2); never edited by hand. `kit` holds the colours the kit\'s faces add, ' +
  'which enter tokens.json through K1 with their skins.';

// A token section's colours flat ({name: value}), sorted by name.
function flat(section) {
  const out = {};
  for (const k of Object.keys(section || {}).sort()) {
    const v = section[k];
    if (v && typeof v === 'object' && 'value' in v) out[k] = v.value;
  }
  return out;
}

// The palette from tokens.json: the colours flat, normal and high contrast,
// the gradients' stops resolved to hex, and `kit` as `kit` holds it now
// (the colours the kit's faces add; they move into tokens.json with their
// skins, request AIA-R10).
function palette(tokens, kit) {
  const color = flat(tokens.color);
  const gradient = {};
  for (const k of Object.keys(tokens.gradient || {}).sort()) {
    const g = tokens.gradient[k];
    if (k.startsWith('_') || !g || typeof g !== 'object' || !('value' in g)) continue;
    gradient[k] = g.value.map(([o, c]) => [o, c in color ? color[c] : c]);
  }
  return { _what: PALETTE_WHAT, color, color_high_contrast: flat(tokens.color_high_contrast), gradient, kit: kit || {} };
}

function readJson(file) {
  return fs.existsSync(file) ? JSON.parse(fs.readFileSync(file, 'utf8')) : null;
}

function writePalette(opts) {
  const file = path.join(opts.art, 'palette.json');
  const old = readJson(file);
  const p = palette(JSON.parse(fs.readFileSync(opts.tokens, 'utf8')), old && old.kit);
  fs.mkdirSync(opts.art, { recursive: true });
  fs.writeFileSync(file, JSON.stringify(p, null, 2) + '\n');
  console.log(`wrote ${path.relative(ROOT, file) || file}`);
}

// --check: the palette, when there is one, holds what tokens.json says (its
// words and its `kit` aside; the file may be written by another tool).
function checkPalette(opts) {
  const file = path.join(opts.art, 'palette.json');
  let old;
  try {
    old = readJson(file);
  } catch (e) {
    return [`palette.json is not JSON: ${e.message}`];
  }
  if (!old) return null;
  const want = palette(JSON.parse(fs.readFileSync(opts.tokens, 'utf8')), old.kit);
  const problems = [];
  for (const k of ['color', 'color_high_contrast', 'gradient']) {
    if (JSON.stringify(sortKeys(old[k])) !== JSON.stringify(sortKeys(want[k]))) {
      problems.push(`palette.json's ${k} is not tokens.json's: node tools/ui_bake/bake.js --palette`);
    }
  }
  return problems;
}

// Width and height of a WebP file from its header (VP8L, VP8X or VP8).
function webpSize(file) {
  const b = fs.readFileSync(file);
  if (b.length < 30 || b.toString('ascii', 0, 4) !== 'RIFF' || b.toString('ascii', 8, 12) !== 'WEBP') {
    return null;
  }
  const chunk = b.toString('ascii', 12, 16);
  if (chunk === 'VP8L') {
    const bits = b.readUInt32LE(21);
    return { width: (bits & 0x3fff) + 1, height: ((bits >>> 14) & 0x3fff) + 1 };
  }
  if (chunk === 'VP8X') return { width: b.readUIntLE(24, 3) + 1, height: b.readUIntLE(27, 3) + 1 };
  if (chunk === 'VP8 ') return { width: b.readUInt16LE(26) & 0x3fff, height: b.readUInt16LE(28) & 0x3fff };
  return null;
}

const pow2 = (n) => n > 0 && (n & (n - 1)) === 0;

// --check: everything a family's baked files must satisfy, without drawing.
function checkFamily(cfg, family, opts) {
  const problems = [];
  const srcs = sources(cfg, family, opts.art);
  const mfile = path.join(opts.out, family + '.json');
  if (!fs.existsSync(mfile)) {
    if (srcs.length) problems.push(`${srcs.length} sources in art/ui/${cfg.families[family].dir}/ but no ${family}.json: bake it`);
    return { problems, note: srcs.length ? '' : 'no sources yet' };
  }
  const text = fs.readFileSync(mfile, 'utf8');
  let m;
  try {
    m = JSON.parse(text);
  } catch (e) {
    return { problems: [`${family}.json is not JSON: ${e.message}`] };
  }
  if (manifestText(m) !== text) problems.push(`${family}.json is not as the bake writes it (edited by hand?)`);
  if (m.format !== 1) problems.push(`${family}.json: format ${m.format}, expected 1`);
  if (m.family !== family) problems.push(`${family}.json names family ${m.family}`);
  if (!srcs.length) problems.push(`${family}.json exists but its sources are gone`);
  const want = sourcesHash(cfg, family, opts.art);
  if (m.sources_hash !== want) problems.push(`${family}.json is stale: sources hash ${want}, manifest ${m.sources_hash}: rebake`);
  const fam = cfg.families[family];
  const ppp = fam.kind === 'scene' ? null : fam.px_per_point;
  if (m.px_per_point !== ppp) problems.push(`${family}.json: px_per_point ${m.px_per_point}, expected ${ppp}`);
  let want_curves;
  try {
    want_curves = curves(cfg, family, opts.art);
  } catch (e) {
    if (!(e instanceof Refusal)) throw e;
    problems.push(e.message);
  }
  const has = JSON.stringify(sortKeys(m.curves));
  if (has !== JSON.stringify(sortKeys(want_curves))) {
    if (m.curves === undefined) problems.push(`${family}.json carries no curves but ${fam.curves} is named: rebake`);
    else if (want_curves === undefined && fam.curves === undefined) problems.push(`${family}.json carries curves its family names no file for`);
    else problems.push(`${family}.json's curves are not ${fam.curves} as it stands: rebake`);
  }
  const atlas = m.atlas || {};
  const first = { normal: atlas.normal, high_contrast: atlas.high_contrast, width: atlas.width, height: atlas.height };
  const pages = atlas.pages === undefined ? [first] : atlas.pages;
  if (atlas.pages !== undefined) {
    if (!Array.isArray(pages) || pages.length < 2) problems.push(`${family}.json: atlas.pages lists fewer than two pages`);
    else if (JSON.stringify(sortKeys(pages[0])) !== JSON.stringify(sortKeys(first))) {
      problems.push(`${family}.json: atlas.pages[0] is not the atlas's own page`);
    }
  }
  let bytes = 0;
  const pageList = Array.isArray(pages) ? pages : [first];
  pageList.forEach((pg, i) => {
    const names = pageFiles(family, i + 1);
    if (!pow2(pg.width) || !pow2(pg.height) || pg.width > MAX_SIDE || pg.height > MAX_SIDE) {
      problems.push(`${family}.json: page ${i + 1} is ${pg.width}x${pg.height}, not powers of two up to ${MAX_SIDE}`);
    }
    for (const key of ['normal', 'high_contrast']) {
      const expect = names[key];
      if (pg[key] !== expect) problems.push(`${family}.json: page ${i + 1}'s ${key} is ${pg[key]}, expected ${expect}`);
      const f = path.join(opts.out, expect);
      if (!fs.existsSync(f)) {
        problems.push(`${expect} is missing`);
        continue;
      }
      bytes += fs.statSync(f).size;
      const size = webpSize(f);
      if (!size) problems.push(`${expect} is not a WebP file`);
      else if (size.width !== pg.width || size.height !== pg.height) {
        problems.push(`${expect} is ${size.width}x${size.height}, the manifest says ${pg.width}x${pg.height}`);
      }
    }
  });
  const stray = pageFiles(family, pageList.length + 1).normal;
  if (fs.existsSync(path.join(opts.out, stray))) problems.push(`${stray} is a page the manifest does not list: rebake`);
  for (const [n, p] of Object.entries(m.pieces || {})) {
    const page = p.page === undefined ? 1 : p.page;
    const pg = pageList[page - 1];
    if (!pg || (p.page !== undefined && page < 2)) {
      problems.push(`${n} is on page ${p.page}, which the atlas does not have`);
      continue;
    }
    if (p.x < 0 || p.y < 0 || p.w <= 0 || p.h <= 0 || p.x + p.w > pg.width || p.y + p.h > pg.height) {
      problems.push(`${n} lies outside its page`);
    }
    if (p.slice && (p.slice.l + p.slice.r > p.w || p.slice.t + p.slice.b > p.h)) problems.push(`${n}: 9-slice margins exceed the piece`);
  }
  return { problems, bytes, pieces: Object.keys(m.pieces || {}).length, atlas: first, pages: pageList.length };
}

// The files of a family's page `n` (from 1): the first is <family>.webp,
// the others <family>_<n>.webp, each with its _hc twin.
function pageFiles(family, n) {
  const stem = n === 1 ? family : `${family}_${n}`;
  return { normal: stem + '.webp', high_contrast: stem + '_hc.webp' };
}

function check(cfg, opts) {
  const families = opts.families.length ? opts.families : Object.keys(cfg.families).sort();
  let failed = 0;
  let total = 0;
  if (!opts.families.length) {
    const pal = checkPalette(opts);
    if (pal === null) console.log('ok   palette.json: none written yet');
    else if (pal.length) {
      failed++;
      for (const p of pal) console.log(`FAIL palette: ${p}`);
    } else console.log("ok   palette.json: tokens.json's colours and gradients");
  }
  for (const family of families) {
    const r = checkFamily(cfg, family, opts);
    total += r.bytes || 0;
    if (r.problems.length) {
      failed++;
      for (const p of r.problems) console.log(`FAIL ${family}: ${p}`);
    } else if (r.atlas) {
      const size = r.pages > 1 ? `${r.pages} pages` : `${r.atlas.width}x${r.atlas.height}`;
      console.log(`ok   ${family}: ${r.pieces} pieces, ${size}, ${r.bytes} bytes for both atlases`);
    } else {
      console.log(`ok   ${family}: ${r.note}`);
    }
  }
  console.log(`interface atlases: ${total} bytes in all`);
  return failed ? 1 : 0;
}

// --- Baking -------------------------------------------------------------

// The piece's name from its source path inside the family's folder
// (kit-spec.md section 6.1): <skin>/<shape>.svg gives <skin>__<shape>__<state>;
// num_<finish>/<glyph>.svg gives num_<finish>_<glyph>.
function pieceBase(rel) {
  const parts = rel.replace(/\.svg$/, '').split('/');
  if (parts.length !== 2 || !parts.every((p) => NAME.test(p))) {
    refuse(`${rel}: a source is <skin>/<shape>.svg, in lower-case words`);
  }
  return { skin: parts[0], shape: parts[1], numeral: parts[0].startsWith('num_') };
}

function round(v, ppp, what, rel) {
  const px = v * ppp;
  if (Math.abs(px - Math.round(px)) > 1e-6) refuse(`${rel}: ${what} ${v} points is not a whole number of pixels at ${ppp} px a point`);
  return Math.round(px);
}

// Read a source's sizes, states and twins in the page (the browser parses SVG).
function describe(text) {
  const doc = new DOMParser().parseFromString(text, 'image/svg+xml');
  const svg = doc.documentElement;
  if (svg.nodeName !== 'svg' || doc.querySelector('parsererror')) return { error: 'not an SVG document' };
  const slice = (el) => (el.hasAttribute('data-slice') ? el.getAttribute('data-slice').trim().split(/[\s,]+/).map(Number) : null);
  const groups = [...svg.children].filter((c) => c.hasAttribute('data-state'));
  return {
    w: Number(svg.getAttribute('width')),
    h: Number(svg.getAttribute('height')),
    slice: slice(svg),
    tint: svg.getAttribute('data-tint') === 'true',
    advance: svg.hasAttribute('data-advance') ? Number(svg.getAttribute('data-advance')) : null,
    hcClass: svg.getAttribute('data-hc') === 'class',
    groups: groups.map((g) => ({ state: g.getAttribute('data-state'), hc: g.getAttribute('data-mode') === 'hc', slice: slice(g) })),
  };
}

// Put one face of the source on the page: only the state's group (or the
// whole drawing when it has no groups), in its normal or high-contrast form.
function stage([text, state, hc, hcClass, w, h]) {
  const doc = new DOMParser().parseFromString(text, 'image/svg+xml');
  const svg = document.importNode(doc.documentElement, true);
  const groups = [...svg.children].filter((c) => c.hasAttribute('data-state'));
  for (const g of groups) {
    const mine = g.getAttribute('data-state') === state && (g.getAttribute('data-mode') === 'hc') === (hc && !hcClass);
    if (!mine) g.remove();
  }
  if (hc && hcClass) svg.classList.add('hc');
  if (!svg.hasAttribute('viewBox')) svg.setAttribute('viewBox', `0 0 ${w} ${h}`);
  svg.setAttribute('width', w);
  svg.setAttribute('height', h);
  svg.style.display = 'block';
  const stageEl = document.getElementById('stage');
  stageEl.replaceChildren(svg);
}

function pageHtml(cfg) {
  let faces = '';
  for (const [family, rel] of Object.entries(cfg.fonts || {}).sort()) {
    faces += `@font-face { font-family: '${family}'; src: url('file://${path.join(ROOT, rel)}'); }\n`;
  }
  return `<!doctype html><html><head><meta charset="utf-8"><style>
${faces}html, body { margin: 0; padding: 0; background: transparent; }
#stage { position: absolute; left: 0; top: 0; line-height: 0; }
</style></head><body><div id="stage"></div></body></html>`;
}

// Shelves, tallest first, PAD pixels apart, at the family's width; the
// height is the next power of two. A wider atlas is tried before refusing.
function layout(pieces, width) {
  const order = [...pieces].sort((a, b) => b.h - a.h || b.w - a.w || (a.name < b.name ? -1 : 1));
  for (let W = width; W <= MAX_SIDE; W *= 2) {
    let x = PAD;
    let y = PAD;
    let shelf = 0;
    let fits = true;
    const places = {};
    for (const p of order) {
      if (p.w + 2 * PAD > W) {
        fits = false;
        break;
      }
      if (x + p.w + PAD > W) {
        x = PAD;
        y += shelf + PAD;
        shelf = 0;
      }
      places[p.name] = { x, y };
      x += p.w + PAD;
      shelf = Math.max(shelf, p.h);
    }
    let H = 1;
    while (H < y + shelf + PAD) H *= 2;
    if (fits && H <= MAX_SIDE) return { width: W, height: H, places };
  }
  refuse(`the pieces do not fit a ${MAX_SIDE}x${MAX_SIDE} atlas (report.md section 10.1): split the family`);
}

// The family's pages: one atlas when its pieces fit (layout's), else
// shelves of MAX_SIDE wide pages, tallest first, a page ending when the
// next shelf would pass MAX_SIDE; the last page's height is the next power
// of two. A piece wider or taller than a page is still refused.
function paginate(pieces, width) {
  const big = pieces.find((p) => p.w + 2 * PAD > MAX_SIDE || p.h + 2 * PAD > MAX_SIDE);
  if (big) refuse(`the pieces do not fit a ${MAX_SIDE}x${MAX_SIDE} atlas (report.md section 10.1): ${big.name} is larger than a page`);
  try {
    const one = layout(pieces, width);
    for (const k of Object.keys(one.places)) one.places[k].page = 1;
    return [{ width: one.width, height: one.height, places: one.places }];
  } catch (e) {
    if (!(e instanceof Refusal)) throw e;
  }
  const order = [...pieces].sort((a, b) => b.h - a.h || b.w - a.w || (a.name < b.name ? -1 : 1));
  const pages = [];
  let page = null;
  let x = PAD;
  let y = PAD;
  let shelf = 0;
  let bottom = 0; // the lowest piece edge on the page
  // The page's height from its pieces, not from y: y has already moved to
  // the next shelf when that shelf opens a new page, and counting it would
  // add a padding twice and double a page that fits (FX1-T-13).
  const close = () => {
    let H = 1;
    while (H < bottom + PAD) H *= 2;
    page.height = H;
  };
  for (const p of order) {
    if (page && x + p.w + PAD > MAX_SIDE) {
      x = PAD;
      y += shelf + PAD;
      shelf = 0;
    }
    if (!page || y + p.h + PAD > MAX_SIDE) {
      if (page) close();
      page = { width: MAX_SIDE, height: MAX_SIDE, places: {} };
      pages.push(page);
      x = PAD;
      y = PAD;
      shelf = 0;
      bottom = 0;
    }
    page.places[p.name] = { x, y, page: pages.length };
    bottom = Math.max(bottom, y + p.h);
    x += p.w + PAD;
    shelf = Math.max(shelf, p.h);
  }
  close();
  return pages;
}

// A scene family (the icons) is drawn by its studio, which writes the same
// files and manifest as an SVG family, with px_per_point null.
const SCENE_STUDIO = path.join(ROOT, 'art/ui/icons/studio/bake_icons.js');

function bakeScene(cfg, family, opts) {
  if (path.resolve(opts.art) !== path.join(ROOT, 'art/ui') || path.resolve(cfg.file) !== path.join(HERE, 'families.json')) {
    refuse(`${family}: a scene family bakes from art/ui and tools/ui_bake/families.json only`);
  }
  if (!fs.existsSync(SCENE_STUDIO)) refuse(`${family}: kind "scene" is drawn by ${path.relative(ROOT, SCENE_STUDIO)}, which is missing`);
  try {
    execFileSync(process.execPath, [SCENE_STUDIO, family, '--out', opts.out], { stdio: 'inherit' });
  } catch (e) {
    refuse(`${family}: ${path.relative(ROOT, SCENE_STUDIO)} failed (exit ${e.status})`);
  }
}

async function bakeFamily(browser, cfg, family, opts) {
  const fam = cfg.families[family];
  if (!fam) refuse(`no family ${family} in ${path.relative(ROOT, cfg.file)}`);
  if (fam.kind === 'scene') return bakeScene(cfg, family, opts);
  if (fam.kind !== 'svg') refuse(`${family}: sources of kind "${fam.kind}" have no renderer yet`);
  const ppp = fam.px_per_point;
  const famDir = path.join(opts.art, fam.dir);
  const svgs = listFiles(famDir, famDir).filter((r) => r.endsWith('.svg'));
  if (!svgs.length) refuse(`${family}: no .svg sources in ${famDir}`);

  const work = fs.mkdtempSync(path.join(os.tmpdir(), 'ui-bake-'));
  try {
    const htmlFile = path.join(work, 'page.html');
    fs.writeFileSync(htmlFile, pageHtml(cfg));
    const tab = await browser.newPage({ deviceScaleFactor: ppp, viewport: { width: 64, height: 64 } });
    await tab.goto('file://' + htmlFile);
    await tab.evaluate(async (names) => {
      await Promise.all(names.map((n) => document.fonts.load(`16px "${n}"`)));
      await document.fonts.ready;
    }, Object.keys(cfg.fonts || {}));

    const pieces = [];
    for (const rel of svgs) {
      const text = fs.readFileSync(path.join(famDir, rel), 'utf8');
      const base = pieceBase(rel);
      const d = await tab.evaluate(describe, text);
      if (d.error) refuse(`${rel}: ${d.error}`);
      if (!(d.w > 0 && d.h > 0)) refuse(`${rel}: the root <svg> needs width and height in points`);
      const wpx = round(d.w, ppp, 'width', rel);
      const hpx = round(d.h, ppp, 'height', rel);
      // The faces: each state group, or the whole drawing as "normal".
      const faces = {};
      if (!d.groups.length) faces.normal = { normal: true, hc: d.hcClass, slice: null };
      for (const g of d.groups) {
        if (!STATES.includes(g.state)) refuse(`${rel}: state "${g.state}" is not one of ${STATES.join(', ')}`);
        faces[g.state] = faces[g.state] || { normal: false, hc: d.hcClass, slice: null };
        const f = faces[g.state];
        if (g.hc ? f.hcGroup : f.normal) refuse(`${rel}: state ${g.state} is drawn twice`);
        if (g.hc) f.hcGroup = f.hc = true;
        else {
          f.normal = true;
          f.slice = g.slice;
        }
      }
      for (const [state, f] of Object.entries(faces)) {
        if (!f.normal) refuse(`${rel}: state ${state} has a high-contrast form but no normal one`);
        if (!f.hc) refuse(`${rel}: state ${state} has no high-contrast twin (kit-spec.md section 3): add a data-mode="hc" group or data-hc="class"`);
      }
      if (base.numeral) {
        if (Object.keys(faces).length !== 1 || !faces.normal) refuse(`${rel}: a numeral has one face, normal`);
        if (d.advance === null) refuse(`${rel}: a numeral needs data-advance`);
      } else if (d.advance !== null) refuse(`${rel}: data-advance is for numerals only (num_<finish>/)`);
      for (const state of Object.keys(faces).sort()) {
        const s = faces[state].slice || d.slice;
        let slice = null;
        if (s) {
          if (s.length !== 4 || s.some((v) => !(v >= 0))) refuse(`${rel}: data-slice is four margins in points: left top right bottom`);
          const [l, t, r, b] = s.map((v, i) => round(v, ppp, ['left', 'top', 'right', 'bottom'][i] + ' margin', rel));
          if (l + r > wpx || t + b > hpx) refuse(`${rel}: the 9-slice margins exceed the piece`);
          slice = { l, t, r, b };
        }
        const name = base.numeral ? `${base.skin}_${base.shape}` : `${base.skin}__${base.shape}__${state}`;
        const piece = { name, rel, text, state, w: wpx, h: hpx, pw: d.w, ph: d.h, slice, tint: d.tint, hcClass: d.hcClass };
        if (base.numeral) piece.advance = round(d.advance, ppp, 'advance', rel);
        pieces.push(piece);
      }
    }
    const seen = new Set();
    for (const p of pieces) {
      if (seen.has(p.name)) refuse(`two sources make the piece ${p.name}`);
      seen.add(p.name);
    }

    // Draw every face twice, normal then high contrast.
    for (const mode of ['normal', 'hc']) {
      fs.mkdirSync(path.join(work, mode));
      for (const p of pieces) {
        await tab.setViewportSize({ width: Math.ceil(p.pw), height: Math.ceil(p.ph) });
        await tab.evaluate(stage, [p.text, p.state, mode === 'hc', p.hcClass, p.pw, p.ph]);
        await tab.evaluate(() => document.fonts.ready);
        await tab.screenshot({
          path: path.join(work, mode, p.name + '.png'),
          clip: { x: 0, y: 0, width: p.pw, height: p.ph },
          omitBackground: true,
        });
      }
    }
    await tab.close();

    const pages = paginate(pieces, fam.width || 1024);
    const place = {};
    for (const pg of pages) Object.assign(place, pg.places);
    const outFiles = {};
    const atlasPages = pages.map((pg, i) => {
      const files = pageFiles(family, i + 1);
      for (const [mode, file] of [['normal', files.normal], ['hc', files.high_contrast]]) {
        const job = {
          out: path.join(work, file),
          width: pg.width,
          height: pg.height,
          pieces: pieces
            .filter((p) => place[p.name].page === i + 1)
            .map((p) => [path.join(work, mode, p.name + '.png'), place[p.name].x, place[p.name].y, p.w, p.h]),
        };
        execFileSync('python3', [path.join(HERE, 'pack.py')], { input: JSON.stringify(job) });
        outFiles[file] = job.out;
      }
      return { normal: files.normal, high_contrast: files.high_contrast, width: pg.width, height: pg.height };
    });
    const atlas = Object.assign({}, atlasPages[0]);
    if (pages.length > 1) atlas.pages = atlasPages;
    const manifest = {
      format: 1,
      family,
      sources_hash: sourcesHash(cfg, family, opts.art),
      atlas,
      px_per_point: ppp,
      pieces: {},
    };
    const c = curves(cfg, family, opts.art);
    if (c !== undefined) manifest.curves = c;
    for (const p of pieces) {
      const e = { x: place[p.name].x, y: place[p.name].y, w: p.w, h: p.h, slice: p.slice, tint: p.tint };
      if (place[p.name].page > 1) e.page = place[p.name].page;
      if (p.advance !== undefined) e.advance = p.advance;
      manifest.pieces[p.name] = e;
    }
    fs.mkdirSync(opts.out, { recursive: true });
    // A page the last bake wrote and this one does not is removed with it.
    for (let n = pages.length + 1; ; n++) {
      const old = pageFiles(family, n);
      if (!fs.existsSync(path.join(opts.out, old.normal)) && !fs.existsSync(path.join(opts.out, old.high_contrast))) break;
      fs.rmSync(path.join(opts.out, old.normal), { force: true });
      fs.rmSync(path.join(opts.out, old.high_contrast), { force: true });
    }
    let bytes = 0;
    for (const [file, src] of Object.entries(outFiles)) {
      fs.copyFileSync(src, path.join(opts.out, file));
      bytes += fs.statSync(src).size;
    }
    fs.writeFileSync(path.join(opts.out, family + '.json'), manifestText(manifest));
    const size = pages.length > 1 ? `${pages.length} pages` : `${pages[0].width}x${pages[0].height}`;
    console.log(`baked ${family}: ${pieces.length} pieces twice into ${size}, ${bytes} bytes for both atlases`);
  } finally {
    fs.rmSync(work, { recursive: true, force: true });
  }
}

async function bake(cfg, opts) {
  if (opts.palette) writePalette(opts);
  if (opts.palette && !opts.families.length) return 0;
  if (!opts.families.length) refuse('name the families to bake: ' + Object.keys(cfg.families).sort().join(', '));
  for (const f of opts.families) if (!cfg.families[f]) refuse(`no family ${f} in ${path.relative(ROOT, cfg.file)}`);
  let browser = null;
  try {
    for (const family of opts.families) {
      if (!browser && cfg.families[family].kind !== 'scene') browser = await require('playwright').chromium.launch();
      await bakeFamily(browser, cfg, family, opts);
    }
  } finally {
    if (browser) await browser.close();
  }
  return 0;
}

async function main(argv) {
  try {
    const opts = parseArgs(argv);
    const cfg = loadConfig(opts.config);
    for (const f of opts.families) if (!cfg.families[f]) refuse(`no family ${f} in ${path.relative(ROOT, cfg.file)}`);
    return opts.check ? check(cfg, opts) : await bake(cfg, opts);
  } catch (e) {
    if (e instanceof Refusal) {
      console.error('bake: ' + e.message);
      return 2;
    }
    throw e;
  }
}

if (require.main === module) {
  main(process.argv.slice(2)).then((code) => process.exit(code));
}

module.exports = { main, manifestText, sourcesHash, curves, layout, paginate, palette, webpSize, loadConfig, listFiles };
