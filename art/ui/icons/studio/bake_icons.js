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
//
// The icons are drawn in Node by plain arithmetic (studio/raster.js and
// studio/picture.js), with no browser, GPU or canvas: the same bytes on
// every machine (README.md, "Why the bake is plain arithmetic").
'use strict';
const fs = require('fs');
const os = require('os');
const path = require('path');
const { pathToFileURL } = require('url');
const { execFileSync } = require('child_process');

const ROOT = path.resolve(__dirname, '../../../..');
const BAKE = path.join(ROOT, 'tools/ui_bake');
const { manifestText, sourcesHash, layout, loadConfig, listFiles } = require(path.join(BAKE, 'bake.js'));
const ICONS = path.join(ROOT, 'art/ui/icons');
const RESERVED = new Set(['studio', 'renders']);

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
  const { finish, shotOf, SHOWN_PT } = await import(pathToFileURL(path.join(__dirname, 'finish.js')).href);
  for (const family of families) {
    const fam = cfg.families[family];
    if (!fam || fam.kind !== 'scene') throw new Error(`${family} is not a scene family`);
  }
  const work = Object.fromEntries(families.map((f) => [f, fs.mkdtempSync(path.join(os.tmpdir(), 'icons-'))]));
  const pieces = Object.fromEntries(families.map((f) => [f, []]));
  try {
    // One render a module, finished for every family and mode that lists it.
    for (const name of modules()) {
      const icon = (await import(pathToFileURL(path.join(ICONS, name + '.js')).href)).default;
      const fams = families.filter((f) => icon.families.includes(f));
      if (!fams.length) continue;
      const shot = await shotOf(icon);
      const piece = name.replace('/', '__') + '__normal';
      for (const family of fams) {
        const fam = cfg.families[family];
        for (const mode of ['normal', 'hc']) {
          fs.mkdirSync(path.join(work[family], mode), { recursive: true });
          fs.writeFileSync(path.join(work[family], mode, piece + '.png'), finish(icon, shot, fam.px, mode, SHOWN_PT[family]));
        }
        pieces[family].push({ name: piece, w: fam.px, h: fam.px });
      }
    }
    for (const family of families) {
      const fam = cfg.families[family], list = pieces[family], dir = work[family];
      if (!list.length) throw new Error(`${family}: no icon module lists it`);
      const lay = layout(list, fam.width || 1024);
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
          pieces: list.map((p) => [path.join(dir, mode, p.name + '.png'), lay.places[p.name].x, lay.places[p.name].y, p.w, p.h]),
        };
        execFileSync('python3', [path.join(BAKE, 'pack.py')], { input: JSON.stringify(job) });
      }
      for (const p of list) manifest.pieces[p.name] = { x: lay.places[p.name].x, y: lay.places[p.name].y, w: p.w, h: p.h, slice: null, tint: false };
      fs.writeFileSync(path.join(out, family + '.json'), manifestText(manifest));
      if (process.env.KEEP_PNG) fs.cpSync(dir, path.join(process.env.KEEP_PNG, family), { recursive: true });
      console.log(`baked ${family}: ${list.length} pieces twice into ${lay.width}x${lay.height}`);
    }
  } finally {
    for (const dir of Object.values(work)) fs.rmSync(dir, { recursive: true, force: true });
  }
}

main(process.argv.slice(2)).catch((e) => { console.error('bake_icons: ' + e.message); process.exit(2); });
