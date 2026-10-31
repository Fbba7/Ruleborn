// Photographs the style board at phone size for the owner's review at O2:
// 390 points wide (a 1170 x 2532 phone) at 2 pixels a point, whole page, in
// the normal and the high-contrast mode. Writes board.png and board_hc.png,
// and beside each a shot (docs/art/ui-quality/gate/shots.md) with the
// rectangle of every control on the board, which check_board.mjs hands to
// tools/ui_gate/checks.py value-steps.
//
//   node art/ui/board/shoot_board.mjs [--scale 2]
import { writeFileSync } from 'node:fs';
import { dirname, join } from 'node:path';
import { fileURLToPath, pathToFileURL } from 'node:url';
import { createRequire } from 'node:module';

const require = createRequire(import.meta.url);
const { chromium } = require('playwright');
const here = dirname(fileURLToPath(import.meta.url));
const at = process.argv.indexOf('--scale');
const scale = at > 0 ? Number(process.argv[at + 1]) : 2;

// What a hand presses on the board: every button, the round gold button and
// the selected card. Glass pills are information, not controls (O2, B6),
// as are status words on their fills; they are listed as such, so the ring
// around a control leaves them out.
export const CONTROLS = '.button-type, .gold-round, .enamel.selected';
export const INFO = '.glass, .status';

export async function controls(page) {
  return page.evaluate(([sel, info]) => {
    const out = [];
    const add = (el, i, interactive) => {
      const r = el.getBoundingClientRect();
      const words = (el.innerText || el.getAttribute('aria-label') || '').trim().replace(/\s+/g, ' ');
      out.push({ name: `${el.className.split(' ')[0]} ${i + 1}: ${words}`.trim(),
        rect: [r.left + scrollX, r.top + scrollY, r.width, r.height].map((v) => Math.round(v * 100) / 100),
        ...(interactive ? {} : { interactive: false }) });
    };
    document.querySelectorAll(sel).forEach((el, i) => add(el, i, true));
    document.querySelectorAll(info).forEach((el, i) => add(el, i, false));
    return out;
  }, [CONTROLS, INFO]);
}

if (import.meta.url !== pathToFileURL(process.argv[1]).href) {
  // Imported for CONTROLS and controls(); nothing to shoot.
} else {
const browser = await chromium.launch();
try {
  const page = await browser.newPage({ viewport: { width: 390, height: 844 }, deviceScaleFactor: scale });
  for (const [mode, file] of [['', 'board.png'], ['?hc=1', 'board_hc.png']]) {
    await page.goto(pathToFileURL(join(here, 'board.html')).href + mode);
    await page.evaluate(() => document.fonts.ready);
    await page.waitForTimeout(200);
    await page.screenshot({ path: join(here, file), fullPage: true });
    const h = await page.evaluate(() => document.documentElement.scrollHeight);
    const shot = { image: file, frame_pt: [390, h], text_scale: 1.0, controls: await controls(page) };
    writeFileSync(join(here, file.replace('.png', '.shot.json')), JSON.stringify(shot, null, 1) + '\n');
    console.log(`${file}: 390 x ${h} points at ${scale}x, ${shot.controls.length} controls`);
  }
} finally {
  await browser.close();
}
}
