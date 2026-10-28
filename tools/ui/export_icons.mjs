// The design's interface icons, out of its own modules and into the client.
//
//   node tools/ui/export_icons.mjs [--size 144]
//
// Runs art/design/diorama/icons.js (the RBI set: hud, currencies, buildings,
// wards, realms, terrain...), school-marks.js (the law icons and their
// frames) and the RBIcons block of realm-diorama.js (school marks, resources,
// building badges) in Chromium, the reference renderer, exactly as the
// screens did. Each icon is written twice:
//
//   client/ui/icons/svg/<group>/<name>.svg   the design's SVG, unchanged (Godot does not import these:
//                                            the folder carries .gdignore, since its filters, masks
//                                            and class rules are beyond the engine's SVG reader)
//   client/ui/icons/png/<group>/<name>.png   rasterised by Chromium at --size pixels (144 = 48 points),
//                                            then quantised to 256 colours by pack_icons.py
//
// and listed in client/ui/icons/manifest.json, which ui/icons.gd reads. The
// modules are read, never edited; one line is added to the copy loaded into
// the page so its private group table can be listed. The tab bar's five
// icons (`tabs/<id>`) are the inline SVGs of art/design/screens/
// RulebornMeta.dc.html's tab bar.
//
//   node tools/ui/export_icons.mjs --groups tabs   writes those groups only,
//                                                  keeping every other icon
import fs from 'node:fs';
import { spawnSync } from 'node:child_process';
import path from 'node:path';
import { createRequire } from 'node:module';
import { fileURLToPath } from 'node:url';

const here = path.dirname(fileURLToPath(import.meta.url));
const root = path.resolve(here, '../..');
const require = createRequire(import.meta.url);
const { chromium } = require(process.env.PLAYWRIGHT_MODULE || '/opt/node22/lib/node_modules/playwright');

const arg = (name, fallback) => {
  const i = process.argv.indexOf(name);
  return i > 0 ? process.argv[i + 1] : fallback;
};
const SIZE = Number(arg('--size', 144));
const only = arg('--groups', '') ? new Set(arg('--groups', '').split(',')) : null;
const design = path.join(root, 'art/design/diorama');
const out = path.join(root, 'client/ui/icons');

const icons = fs.readFileSync(path.join(design, 'icons.js'), 'utf8')
  .replace('const norm=x=>', 'window.__RBI_GROUPS=GROUPS;const norm=x=>');
if (!icons.includes('window.__RBI_GROUPS')) throw new Error('icons.js changed shape: no group table found');
const marks = fs.readFileSync(path.join(design, 'school-marks.js'), 'utf8');
// The RBIcons block only: the rest of realm-diorama.js is the 3D element.
const diorama = fs.readFileSync(path.join(design, 'realm-diorama.js'), 'utf8');
const start = diorama.indexOf('if(!window.RBIcons){');
const end = diorama.indexOf('const IC=window.RBIcons;', start);
if (start < 0 || end < 0) throw new Error('realm-diorama.js changed shape: no RBIcons block');
const rbicons = diorama.slice(start, end);

const browser = await chromium.launch({ executablePath: process.env.CHROMIUM || undefined });
const page = await browser.newPage();
await page.setContent('<!doctype html><html><body></body></html>');
await page.addScriptTag({ content: icons });
await page.addScriptTag({ content: marks });
await page.addScriptTag({ content: rbicons });
await page.waitForFunction(() => window.RBI && window.RBI.__law);

// The tab bar's icons, inline in the screens' markup.
const meta = fs.readFileSync(path.join(root, 'art/design/screens/RulebornMeta.dc.html'), 'utf8');
const tabs = [];
for (const id of ['islands', 'codex', 'heist', 'crew', 'friends']) {
  const at = meta.indexOf(`tabs.${id}I }}">`);
  if (at < 0) throw new Error(`RulebornMeta.dc.html changed shape: no ${id} tab icon`);
  const a = meta.indexOf('<svg', at);
  let svg = meta.slice(a, meta.indexOf('</svg>', a) + 6);
  if (!svg.includes('xmlns=')) svg = svg.replace('<svg', '<svg xmlns="http://www.w3.org/2000/svg"');
  tabs.push(['tabs', id, 'data:image/svg+xml;charset=utf-8,' + encodeURIComponent(svg)]);
}

// Every icon as [group, name, data URL].
const found = await page.evaluate(() => {
  const all = [];
  const G = window.__RBI_GROUPS;
  for (const g of Object.keys(G).sort()) {
    for (const n of Object.keys(G[g]).sort()) all.push([g, n, window.RBI(g, n)]);
  }
  for (const id of window.RBLaw.ids) all.push(['laws', id, window.RBLaw.url(id)]);
  const I = window.RBIcons;
  for (const s of ['Motion', 'Matter', 'Time', 'Energy', 'Life', 'Spirit']) all.push(['schools', s.toLowerCase(), I.school(s)]);
  for (const k of ['starlight', 'aether', 'essence', 'renown', 'Starlight', 'Aether', 'Essence', 'Renown']) {
    try { const u = I.res(k); if (u) all.push(['resources', k.toLowerCase(), u]); } catch (e) { /* not this spelling */ }
  }
  return all.filter((x) => typeof x[2] === 'string' && x[2].startsWith('data:image/svg+xml'));
});
const list = found.concat(tabs).filter((x) => !only || only.has(x[0]));

// Rasterise each in the page: an <img> of the SVG drawn into a canvas.
const pngs = await page.evaluate(async ([items, size]) => {
  const res = [];
  for (const [g, n, url] of items) {
    const img = new Image();
    img.src = url;
    await img.decode();
    const c = document.createElement('canvas');
    c.width = size; c.height = size;
    const x = c.getContext('2d');
    x.drawImage(img, 0, 0, size, size);
    res.push([g, n, c.toDataURL('image/png')]);
  }
  return res;
}, [list, SIZE]);
await browser.close();

const manifest = { _what: 'Written by tools/ui/export_icons.mjs from art/design/diorama/: every interface icon, by group/name.', size: SIZE, icons: {} };
if (only) {
  // Only the groups asked for are written; the rest stay as they are.
  Object.assign(manifest.icons, JSON.parse(fs.readFileSync(path.join(out, 'manifest.json'), 'utf8')).icons);
  for (const g of only) {
    fs.rmSync(path.join(out, 'svg', g), { recursive: true, force: true });
    fs.rmSync(path.join(out, 'png', g), { recursive: true, force: true });
  }
} else {
  fs.rmSync(path.join(out, 'svg'), { recursive: true, force: true });
  fs.rmSync(path.join(out, 'png'), { recursive: true, force: true });
}
fs.mkdirSync(path.join(out, 'svg'), { recursive: true });
fs.writeFileSync(path.join(out, 'svg', '.gdignore'), '');
const seen = new Set();
for (let i = 0; i < list.length; i++) {
  const [g, n, url] = list[i];
  const key = `${g}/${n}`;
  if (seen.has(key)) continue;
  seen.add(key);
  const svg = decodeURIComponent(url.slice(url.indexOf(',') + 1));
  fs.mkdirSync(path.join(out, 'svg', g), { recursive: true });
  fs.writeFileSync(path.join(out, 'svg', g, `${n}.svg`), svg);
  fs.mkdirSync(path.join(out, 'png', g), { recursive: true });
  const png = Buffer.from(pngs[i][2].split(',')[1], 'base64');
  fs.writeFileSync(path.join(out, 'png', g, `${n}.png`), png);
  manifest.icons[key] = `res://ui/icons/png/${g}/${n}.png`;
}
fs.writeFileSync(path.join(out, 'manifest.json'), JSON.stringify(manifest, null, 1) + '\n');
const folders = only ? [...only].map((g) => path.join(out, 'png', g)) : [path.join(out, 'png')];
const packed = folders.map((f) => spawnSync('python3', [path.join(here, 'pack_icons.py'), f], { stdio: 'inherit' }))
  .find((r) => r.status !== 0) || { status: 0 };
if (packed.status !== 0) throw new Error('pack_icons.py failed');
console.log(`wrote ${seen.size} icons at ${SIZE} px to ${path.relative(root, out)}`);
