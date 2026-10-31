// Bakes the style board's rendered art from studio.html: the four hero
// icons in the normal and the high-contrast form, the finish of one icon
// step by step, and the studio's three spheres. Writes art/ui/board/art/.
//
//   (cd tools/ui_research && npm ci)     # three.js 0.184, once
//   node art/ui/board/bake_art.mjs
//
// studio.html runs in headless Chromium (WebGL through SwiftShader); module
// scripts do not load from file://, so this serves the repository to it.
import { createServer } from 'node:http';
import { createReadStream, existsSync, mkdirSync, statSync, writeFileSync } from 'node:fs';
import { dirname, extname, join, relative } from 'node:path';
import { fileURLToPath } from 'node:url';
import { createRequire } from 'node:module';

const require = createRequire(import.meta.url);
const { chromium } = require('playwright');
const here = dirname(fileURLToPath(import.meta.url));
const root = join(here, '..', '..', '..');
const out = join(here, 'art');
const TYPES = { '.html': 'text/html', '.js': 'text/javascript', '.json': 'application/json' };

const server = createServer((req, res) => {
  const file = join(root, decodeURIComponent(req.url.split('?')[0]));
  if (!file.startsWith(root) || !existsSync(file) || statSync(file).isDirectory()) {
    res.writeHead(404);
    res.end();
    return;
  }
  res.writeHead(200, { 'Content-Type': TYPES[extname(file)] || 'application/octet-stream' });
  createReadStream(file).pipe(res);
});

await new Promise((done) => server.listen(0, '127.0.0.1', done));
const browser = await chromium.launch({ args: ['--use-angle=swiftshader', '--enable-unsafe-swiftshader', '--ignore-gpu-blocklist'] });
try {
  const tab = await browser.newPage({ viewport: { width: 1000, height: 700 } });
  const errors = [];
  tab.on('pageerror', (e) => errors.push(e.message));
  await tab.goto(`http://127.0.0.1:${server.address().port}/art/ui/board/studio.html`);
  await tab.waitForFunction(() => window.ready === true || false, null, { timeout: 60000 }).catch(() => {});
  if (errors.length) throw new Error(errors.join('\n'));
  mkdirSync(out, { recursive: true });
  const write = (name, url) => writeFileSync(join(out, name + '.png'), Buffer.from(url.split(',')[1], 'base64'));
  const names = await tab.evaluate(() => window.NAMES);
  for (const name of names) {
    for (const form of ['normal', 'hc']) {
      const [url] = await tab.evaluate(([n, f]) => window.bake(n, f), [name, form]);
      write(form === 'hc' ? `${name}_hc` : name, url);
    }
  }
  const stages = await tab.evaluate(() => window.bake('starlight', 'normal', true));
  stages.forEach((url, i) => write(`finish_${i + 1}`, url));
  write('studio', (await tab.evaluate(() => window.bake('studio')))[0]);
  console.log(`baked ${names.length} icons in two forms, ${stages.length} finish steps and the studio into ${relative(root, out)}`);
} finally {
  await browser.close();
  server.close();
}
