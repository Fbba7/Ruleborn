// Photographs the key frames at the phone's size: 390 x 845 points at 1080 /
// 390 pixels a point, so each still is 1080 x 2340. Each page in three forms
// (as written, text at 200%, high contrast), each in English and Brazilian
// Portuguese:
//
//   01-home.png  01-home_text200.png  01-home_hc.png  and each _pt_BR
//
// Beside each still goes a shot (docs/art/ui-quality/gate/shots.md) with the
// rectangle of every control, which check_keyframes.mjs hands to
// tools/ui_gate/checks.py value-steps.
//
//   node art/ui/keyframes/shoot_keyframes.mjs
import { writeFileSync } from 'node:fs';
import { dirname, join } from 'node:path';
import { fileURLToPath, pathToFileURL } from 'node:url';
import { createRequire } from 'node:module';

const require = createRequire(import.meta.url);
const { chromium } = require('playwright');
const here = dirname(fileURLToPath(import.meta.url));

export const FRAME = [390, 845];
export const SCALE = 1080 / 390;
export const PAGES = ['01-home', '02-heist'];
export const FORMS = [['', ''], ['_text200', 'text=200'], ['_hc', 'hc=1']];
export const LANGS = [['', 'en'], ['_pt_BR', 'pt_BR']];

// Every still: [file, page, query, text_scale].
export const STILLS = PAGES.flatMap((p) => FORMS.flatMap(([f, fq]) => LANGS.map(([l, lang]) =>
  [`${p}${f}${l}.png`, p, [fq, lang === 'en' ? '' : `lang=${lang}`].filter(Boolean).join('&'), f === '_text200' ? 2 : 1])));

export const href = (page, query) => pathToFileURL(join(here, `${page}.html`)).href + (query ? `?${query}` : '');

// What a hand presses (.ctl, and a .ctl-group such as the tab bar, whose
// tabs are its parts) and what only informs (.info). A control's rectangle
// is what is drawn: its .face where it has one. The heist's interface stays
// on screen through the heist, so it is persistent.
export async function controls(page) {
  return page.evaluate(() => {
    const out = [];
    const heist = !!document.querySelector('.heist');
    const r2 = (r) => [r.left, r.top, r.width, r.height].map((v) => Math.round(v * 100) / 100);
    const words = (el) => (el.getAttribute('aria-label') || el.innerText || '').trim().replace(/\s+/g, ' ');
    document.querySelectorAll('.ctl, .ctl-group, .info').forEach((el, i) => {
      if (getComputedStyle(el).display === 'none') return;
      const info = el.classList.contains('info');
      const face = el.querySelector('.face') ?? el;
      out.push({ name: `${el.className.split(' ')[0]} ${i + 1}: ${words(el)}`.slice(0, 80),
        rect: r2(face.getBoundingClientRect()),
        ...(info ? { interactive: false } : {}), ...(heist ? { persistent: true } : {}) });
    });
    return out;
  });
}

export async function ready(page) {
  await page.waitForSelector('html[data-ready]');
  await page.evaluate(() => document.fonts.ready);
  await page.waitForTimeout(150);
}

if (import.meta.url === pathToFileURL(process.argv[1]).href) {
  const browser = await chromium.launch();
  try {
    const page = await browser.newPage({ viewport: { width: FRAME[0], height: FRAME[1] }, deviceScaleFactor: SCALE });
    const errors = [];
    page.on('pageerror', (e) => errors.push(e.message));
    page.on('requestfailed', (r) => errors.push(`failed to load ${r.url()}`));
    for (const [file, name, query, ts] of STILLS) {
      await page.goto(href(name, query));
      await ready(page);
      await page.screenshot({ path: join(here, file) });
      const shot = { image: file, frame_pt: FRAME, text_scale: ts, controls: await controls(page) };
      writeFileSync(join(here, file.replace('.png', '.shot.json')), JSON.stringify(shot, null, 1) + '\n');
      console.log(`${file}: ${shot.controls.length} controls`);
    }
    if (errors.length) { console.error(errors.join('\n')); process.exit(1); }
  } finally {
    await browser.close();
  }
}
