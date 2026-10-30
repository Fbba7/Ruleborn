// The UI kit's bake (kit-spec.md section 6.6; report.md section 3, K1).
//
//   node tools/ui_bake/bake.js <family>...      bake the families named
//   node tools/ui_bake/bake.js --check [family...]   compare hashes, in seconds
//
// Options: --art DIR (default art/ui), --out DIR (default client/ui/art),
// --config FILE (default tools/ui_bake/families.json). The tests use them to
// bake a fixture family into a scratch folder.
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
    families: [],
    art: path.join(ROOT, 'art/ui'),
    out: path.join(ROOT, 'client/ui/art'),
    config: path.join(HERE, 'families.json'),
  };
  for (let i = 0; i < argv.length; i++) {
    const a = argv[i];
    if (a === '--check') opts.check = true;
    else if (a === '--art' || a === '--out' || a === '--config') {
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
  const atlas = m.atlas || {};
  if (!pow2(atlas.width) || !pow2(atlas.height) || atlas.width > MAX_SIDE || atlas.height > MAX_SIDE) {
    problems.push(`${family}.json: atlas ${atlas.width}x${atlas.height} is not powers of two up to ${MAX_SIDE}`);
  }
  let bytes = 0;
  for (const [key, expect] of [['normal', family + '.webp'], ['high_contrast', family + '_hc.webp']]) {
    if (atlas[key] !== expect) problems.push(`${family}.json: atlas.${key} is ${atlas[key]}, expected ${expect}`);
    const f = path.join(opts.out, expect);
    if (!fs.existsSync(f)) {
      problems.push(`${expect} is missing`);
      continue;
    }
    bytes += fs.statSync(f).size;
    const size = webpSize(f);
    if (!size) problems.push(`${expect} is not a WebP file`);
    else if (size.width !== atlas.width || size.height !== atlas.height) {
      problems.push(`${expect} is ${size.width}x${size.height}, the manifest says ${atlas.width}x${atlas.height}`);
    }
  }
  for (const [n, p] of Object.entries(m.pieces || {})) {
    if (p.x < 0 || p.y < 0 || p.w <= 0 || p.h <= 0 || p.x + p.w > atlas.width || p.y + p.h > atlas.height) {
      problems.push(`${n} lies outside the atlas`);
    }
    if (p.slice && (p.slice.l + p.slice.r > p.w || p.slice.t + p.slice.b > p.h)) problems.push(`${n}: 9-slice margins exceed the piece`);
  }
  return { problems, bytes, pieces: Object.keys(m.pieces || {}).length, atlas };
}

function check(cfg, opts) {
  const families = opts.families.length ? opts.families : Object.keys(cfg.families).sort();
  let failed = 0;
  let total = 0;
  for (const family of families) {
    const r = checkFamily(cfg, family, opts);
    total += r.bytes || 0;
    if (r.problems.length) {
      failed++;
      for (const p of r.problems) console.log(`FAIL ${family}: ${p}`);
    } else if (r.atlas) {
      console.log(`ok   ${family}: ${r.pieces} pieces, ${r.atlas.width}x${r.atlas.height}, ${r.bytes} bytes for both atlases`);
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

async function bakeFamily(browser, cfg, family, opts) {
  const fam = cfg.families[family];
  if (!fam) refuse(`no family ${family} in ${path.relative(ROOT, cfg.file)}`);
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

    const lay = layout(pieces, fam.width || 1024);
    const outFiles = {};
    for (const [mode, file] of [['normal', family + '.webp'], ['hc', family + '_hc.webp']]) {
      const job = {
        out: path.join(work, file),
        width: lay.width,
        height: lay.height,
        pieces: pieces.map((p) => [path.join(work, mode, p.name + '.png'), lay.places[p.name].x, lay.places[p.name].y, p.w, p.h]),
      };
      execFileSync('python3', [path.join(HERE, 'pack.py')], { input: JSON.stringify(job) });
      outFiles[file] = job.out;
    }
    const manifest = {
      format: 1,
      family,
      sources_hash: sourcesHash(cfg, family, opts.art),
      atlas: { normal: family + '.webp', high_contrast: family + '_hc.webp', width: lay.width, height: lay.height },
      px_per_point: ppp,
      pieces: {},
    };
    for (const p of pieces) {
      const e = { x: lay.places[p.name].x, y: lay.places[p.name].y, w: p.w, h: p.h, slice: p.slice, tint: p.tint };
      if (p.advance !== undefined) e.advance = p.advance;
      manifest.pieces[p.name] = e;
    }
    fs.mkdirSync(opts.out, { recursive: true });
    let bytes = 0;
    for (const [file, src] of Object.entries(outFiles)) {
      fs.copyFileSync(src, path.join(opts.out, file));
      bytes += fs.statSync(src).size;
    }
    fs.writeFileSync(path.join(opts.out, family + '.json'), manifestText(manifest));
    console.log(`baked ${family}: ${pieces.length} pieces twice into ${lay.width}x${lay.height}, ${bytes} bytes for both atlases`);
  } finally {
    fs.rmSync(work, { recursive: true, force: true });
  }
}

async function bake(cfg, opts) {
  if (!opts.families.length) refuse('name the families to bake: ' + Object.keys(cfg.families).sort().join(', '));
  for (const f of opts.families) if (!cfg.families[f]) refuse(`no family ${f} in ${path.relative(ROOT, cfg.file)}`);
  const { chromium } = require('playwright');
  const browser = await chromium.launch();
  try {
    for (const family of opts.families) await bakeFamily(browser, cfg, family, opts);
  } finally {
    await browser.close();
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

module.exports = { main, manifestText, sourcesHash, layout, webpSize, loadConfig, listFiles };
