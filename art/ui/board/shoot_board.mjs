// Photographs the style board at phone size for the owner's review at O2:
// 390 points wide (a 1170 x 2532 phone) at 2 pixels a point, whole page, in
// the normal and the high-contrast mode. Writes board.png and board_hc.png.
//
//   node art/ui/board/shoot_board.mjs [--scale 2]
import { dirname, join } from 'node:path';
import { fileURLToPath, pathToFileURL } from 'node:url';
import { createRequire } from 'node:module';

const require = createRequire(import.meta.url);
const { chromium } = require('playwright');
const here = dirname(fileURLToPath(import.meta.url));
const at = process.argv.indexOf('--scale');
const scale = at > 0 ? Number(process.argv[at + 1]) : 2;

const browser = await chromium.launch();
try {
  const page = await browser.newPage({ viewport: { width: 390, height: 844 }, deviceScaleFactor: scale });
  for (const [mode, file] of [['', 'board.png'], ['?hc=1', 'board_hc.png']]) {
    await page.goto(pathToFileURL(join(here, 'board.html')).href + mode);
    await page.evaluate(() => document.fonts.ready);
    await page.waitForTimeout(200);
    await page.screenshot({ path: join(here, file), fullPage: true });
    const h = await page.evaluate(() => document.documentElement.scrollHeight);
    console.log(`${file}: 390 x ${h} points at ${scale}x`);
  }
} finally {
  await browser.close();
}
