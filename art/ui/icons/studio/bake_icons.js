#!/usr/bin/env node
// The icon families' bake (art/ui/icons/README.md), until tools/ui_bake's
// bake.js renders kind "scene" itself (request AIA2-R1 to K1). It writes
// exactly what bake.js writes for an SVG family, with bake.js's own layout,
// manifest text, sources hash and pack.py:
//
//   node art/ui/icons/studio/bake_icons.js [icons_48] [icons_256] [--out DIR]
//
// Every `<group>/<name>.js` under art/ui/icons/ (studio/ and renders/ are
// not groups) whose `families` lists the family becomes the piece
// `<group>__<name>__normal`, px x px, in <family>.webp and its high-contrast
// twin in <family>_hc.webp.
'use strict';
const fs = require('fs');
const os = require('os');
const path = require('path');
const http = require('http');
const { execFileSync } = require('child_process');

const ROOT = path.resolve(__dirname, '../../../..');
const BAKE = path.join(ROOT, 'tools/ui_bake');
const { manifestText, sourcesHash, layout, loadConfig, listFiles } = require(path.join(BAKE, 'bake.js'));
const ICONS = path.join(ROOT, 'art/ui/icons');
const RESERVED = new Set(['studio', 'renders']);
const TYPES = { '.html': 'text/html', '.js': 'text/javascript', '.json': 'application/json', '.png': 'image/png' };

function serve() {
  const server = http.createServer((req, res) => {
    const rel = decodeURIComponent(new URL(req.url, 'http://x').pathname);
    const file = path.join(ROOT, rel);
    if (!file.startsWith(ROOT + path.sep) || !fs.existsSync(file) || !fs.statSync(file).isFile()) {
      res.writeHead(404); res.end(); return;
    }
    res.writeHead(200, { 'content-type': TYPES[path.extname(file)] || 'application/octet-stream' });
    res.end(fs.readFileSync(file));
  });
  return new Promise((ok) => server.listen(0, '127.0.0.1', () => ok(server)));
}

// The icon modules: `<group>/<name>`, sorted.
function modules() {
  return listFiles(ICONS, ICONS)
    .filter((r) => /^[a-z0-9_]+\/[a-z0-9_]+\.js$/.test(r) && !RESERVED.has(r.split('/')[0]))
    .map((r) => r.slice(0, -3));
}

async function main(argv) {
  let out = path.join(ROOT, 'client/ui/art');
  const fams = [];
  for (let i = 0; i < argv.length; i++) {
    if (argv[i] === '--out') out = path.resolve(argv[++i]);
    else fams.push(argv[i]);
  }
  const cfg = loadConfig(path.join(BAKE, 'families.json'));
  const families = fams.length ? fams : Object.keys(cfg.families).filter((f) => cfg.families[f].kind === 'scene').sort();
  const server = await serve();
  const { chromium } = require('playwright');
  const browser = await chromium.launch({ args: ['--use-angle=swiftshader', '--enable-unsafe-swiftshader', '--ignore-gpu-blocklist'] });
  try {
    const tab = await browser.newPage();
    tab.on('pageerror', (e) => console.error('page: ' + e.message));
    await tab.goto(`http://127.0.0.1:${server.address().port}/art/ui/icons/studio/page.html`);
    await tab.waitForFunction(() => window.ready === true);
    for (const family of families) {
      const fam = cfg.families[family];
      if (!fam || fam.kind !== 'scene') throw new Error(`${family} is not a scene family`);
      const work = fs.mkdtempSync(path.join(os.tmpdir(), 'icons-'));
      try {
        const pieces = [];
        for (const name of modules()) {
          const fams = await tab.evaluate(async (n) => (await import(`/art/ui/icons/${n}.js`)).default.families, name);
          if (!fams.includes(family)) continue;
          const piece = name.replace('/', '__') + '__normal';
          for (const mode of ['normal', 'hc']) {
            const url = await tab.evaluate(([n, f, px, m]) => window.finish(n, f, px, m), [name, family, fam.px, mode]);
            fs.mkdirSync(path.join(work, mode), { recursive: true });
            fs.writeFileSync(path.join(work, mode, piece + '.png'), Buffer.from(url.split(',')[1], 'base64'));
          }
          pieces.push({ name: piece, w: fam.px, h: fam.px });
        }
        if (!pieces.length) throw new Error(`${family}: no icon module lists it`);
        const lay = layout(pieces, fam.width || 1024);
        const manifest = {
          format: 1,
          family,
          sources_hash: sourcesHash(cfg, family, path.join(ROOT, 'art/ui')),
          atlas: { normal: family + '.webp', high_contrast: family + '_hc.webp', width: lay.width, height: lay.height },
          px_per_point: null,
          pieces: {},
        };
        fs.mkdirSync(out, { recursive: true });
        for (const [mode, file] of [['normal', family + '.webp'], ['hc', family + '_hc.webp']]) {
          const job = {
            out: path.join(out, file), width: lay.width, height: lay.height,
            pieces: pieces.map((p) => [path.join(work, mode, p.name + '.png'), lay.places[p.name].x, lay.places[p.name].y, p.w, p.h]),
          };
          execFileSync('python3', [path.join(BAKE, 'pack.py')], { input: JSON.stringify(job) });
        }
        for (const p of pieces) manifest.pieces[p.name] = { x: lay.places[p.name].x, y: lay.places[p.name].y, w: p.w, h: p.h, slice: null, tint: false };
        fs.writeFileSync(path.join(out, family + '.json'), manifestText(manifest));
        if (process.env.KEEP_PNG) fs.cpSync(work, path.join(process.env.KEEP_PNG, family), { recursive: true });
        console.log(`baked ${family}: ${pieces.length} pieces twice into ${lay.width}x${lay.height}`);
      } finally {
        fs.rmSync(work, { recursive: true, force: true });
      }
    }
  } finally {
    await browser.close();
    server.close();
  }
}

main(process.argv.slice(2)).catch((e) => { console.error('bake_icons: ' + e.message); process.exit(2); });
