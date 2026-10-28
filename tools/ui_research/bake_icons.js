// The AI UI artist's reward icons (T14, docs/art/ui-quality/report.md
// section 9): modelled and lit in three.js, finished in 2D (glow, ink drop,
// ink outline, glints), at 256 px.
//
//   (cd tools/ui_research && npm ci)   # three.js, once
//   node tools/ui_research/bake_icons.js
//
// icons.html does the work in headless Chromium (WebGL through SwiftShader);
// this serves the repository to it, since module scripts do not load from
// file://, and writes client/prototypes/ui_quality/icons/<name>.png.
'use strict';
const fs = require('fs');
const http = require('http');
const path = require('path');
const { chromium } = require('playwright');

const root = path.resolve(__dirname, '../..');
const out = path.join(root, 'client/prototypes/ui_quality/icons');
const NAMES = ['starlight', 'essence', 'renown', 'chest', 'pip'];
const TYPES = { '.html': 'text/html', '.js': 'text/javascript', '.json': 'application/json', '.jpg': 'image/jpeg',
  '.png': 'image/png', '.glb': 'model/gltf-binary' };

const server = http.createServer((req, res) => {
  const file = path.join(root, decodeURIComponent(req.url.split('?')[0]));
  if (!file.startsWith(root) || !fs.existsSync(file) || fs.statSync(file).isDirectory()) {
    res.writeHead(404);
    res.end();
    return;
  }
  res.writeHead(200, { 'Content-Type': TYPES[path.extname(file)] || 'application/octet-stream' });
  fs.createReadStream(file).pipe(res);
});

(async () => {
  await new Promise((done) => server.listen(0, '127.0.0.1', done));
  const port = server.address().port;
  const browser = await chromium.launch({ args: ['--use-angle=swiftshader', '--enable-unsafe-swiftshader',
    '--ignore-gpu-blocklist'] });
  const tab = await browser.newPage({ viewport: { width: 700, height: 700 } });
  tab.on('pageerror', (e) => console.error('page:', e.message));
  await tab.goto(`http://127.0.0.1:${port}/tools/ui_research/icons.html`);
  await tab.waitForFunction(() => window.ready === true, null, { timeout: 60000 });
  fs.mkdirSync(out, { recursive: true });
  for (const name of NAMES) {
    const url = await tab.evaluate((n) => window.bake(n), name);
    fs.writeFileSync(path.join(out, name + '.png'), Buffer.from(url.split(',')[1], 'base64'));
  }
  await browser.close();
  server.close();
  console.log(`baked ${NAMES.length} icons into ${path.relative(root, out)}`);
})();
