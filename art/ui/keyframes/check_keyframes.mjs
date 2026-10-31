// The key frames' scripted checks. For home, heist, result and character, as
// written, with text at 200% and in high contrast, each in English and
// Brazilian Portuguese (shoot_keyframes.mjs's 24 stills), it checks that:
//
//   1. the pages and kit.css name no colour of their own: no colour literal,
//      and color-mix only fades one variable toward transparent (the board's
//      own file check, check_board.mjs);
//   2. words.js is what build_words.mjs writes from the game's strings, so
//      every word shown is the game's word;
//   3. every colour the page computes is a token colour, and every word
//      marked data-check meets §21.8 (face, 13 points or more, weight 800 or
//      less, no opacity, tabular figures, 4.5:1 and APCA): check_board.mjs's
//      checkMode, at the phone's 390 x 845 points;
//   4. every word is 13 points times the text scale or more, so at 200% the
//      words have grown with it;
//   5. every control's touch area (the control, with its .hit where it has
//      one) is 48 x 48 points or more;
//   6. every control stands in the safe area, y 44 to 811 and x 0 to 390,
//      so the notch, the home bar and the corners stay clear;
//   7. no two controls' faces meet, no two words' em boxes meet, and no
//      word is cut off by a box that hides its overflow or by the screen's
//      edge;
//   8. the heist has no more than eight things to tap (§21.8);
//   9. every control stands two value steps (ΔL* 20) off what it sits on:
//      tools/ui_gate/checks.py value-steps on the 24 shots;
//  10. every still is there at 1080 x 2340.
//
//   node art/ui/keyframes/check_keyframes.mjs [--out report.json]
//   node art/ui/keyframes/check_keyframes.mjs --self-test   plants faults; each must fail
import { readFileSync, writeFileSync, mkdtempSync, existsSync } from 'node:fs';
import { tmpdir } from 'node:os';
import { dirname, join } from 'node:path';
import { fileURLToPath, pathToFileURL } from 'node:url';
import { createRequire } from 'node:module';
import { checkFiles, checkSteps, checkMode, allowedColours } from '../board/check_board.mjs';
import { build } from './build_words.mjs';
import { FRAME, STILLS, href, ready } from './shoot_keyframes.mjs';

const require = createRequire(import.meta.url);
const { chromium } = require('playwright');
const here = dirname(fileURLToPath(import.meta.url));
const PAGES = ['01-home.html', '02-heist.html', '03-result.html', '04-character.html'];
const SAFE = [44, 811];
const MOST_IN_HEIST = 8;
const PX = [1080, 2340];

// The size of a PNG, from its IHDR.
function pngSize(file) {
  const b = readFileSync(file);
  if (b.toString('latin1', 1, 4) !== 'PNG') return null;
  return [b.readUInt32BE(16), b.readUInt32BE(20)];
}

// 4 to 8: what the page lays out, read after it is ready.
async function checkLayout(page, still, inject, script) {
  const [file, name, query, ts] = still;
  await page.goto(href(name, query));
  await ready(page);
  if (inject) await page.addStyleTag({ content: inject });
  if (script) await page.evaluate(script);
  await page.waitForTimeout(50);
  const m = await page.evaluate(() => {
    const box = (r) => [r.left, r.top, r.right, r.bottom];
    const shown = (el) => el.getClientRects().length > 0 && getComputedStyle(el).visibility !== 'hidden';
    const label = (el) => (el.getAttribute('aria-label') || el.textContent || el.className).trim().replace(/\s+/g, ' ').slice(0, 40);
    const ctls = [...document.querySelectorAll('.ctl')].filter(shown).map((el) => {
      const face = el.querySelector('.face') ?? el;
      const hit = el.querySelector(':scope > .hit');
      const own = box(el.getBoundingClientRect());
      const h = hit ? box(hit.getBoundingClientRect()) : own;
      const touch = [Math.min(own[0], h[0]), Math.min(own[1], h[1]), Math.max(own[2], h[2]), Math.max(own[3], h[3])];
      return { name: label(el), face: box(face.getBoundingClientRect()), touch };
    });
    const words = [...document.querySelectorAll('[data-check]')].filter(shown).map((el) => {
      const range = document.createRange();
      range.selectNodeContents(el);
      const rects = [...range.getClientRects()].filter((r) => r.width > 0 && r.height > 0).map(box);
      const clips = [];
      for (let n = el.parentElement; n && n !== document.body; n = n.parentElement) {
        const cs = getComputedStyle(n);
        if (cs.overflowX !== 'visible' || cs.overflowY !== 'visible') clips.push({ what: n.className, box: box(n.getBoundingClientRect()) });
      }
      const cs = getComputedStyle(el);
      return { text: el.textContent.trim().slice(0, 40), size: parseFloat(cs.fontSize), rects, clips,
        cut: el.scrollWidth > el.clientWidth + 1 && cs.overflowX !== 'visible' };
    });
    return { ctls, words, heist: !!document.querySelector('.screen.heist') };
  });

  const fails = [];
  const at = `${file.replace('.png', '')}`;
  const meets = (a, b) => a[0] < b[2] - 0.5 && b[0] < a[2] - 0.5 && a[1] < b[3] - 0.5 && b[1] < a[3] - 0.5;
  const within = (a, b) => a[0] >= b[0] - 0.5 && a[1] >= b[1] - 0.5 && a[2] <= b[2] + 0.5 && a[3] <= b[3] + 0.5;
  const f = (n) => Math.round(n * 10) / 10;

  // A word's letters stand in its em box: its line's rectangle cut to one
  // em about its middle, without the leading above and below.
  for (const w of m.words) {
    w.rects = w.rects.map(([l, t, r, b]) => { const mid = (t + b) / 2; return [l, mid - w.size / 2, r, mid + w.size / 2]; });
  }
  for (const w of m.words) {
    if (w.size < 13 * ts - 0.01) fails.push({ kind: 'type', what: `${at}: "${w.text}" at ${f(w.size)} points, under 13 x ${ts}` });
    const screen = [0, 0, FRAME[0], FRAME[1]];
    const out = w.rects.some((r) => !within(r, screen)) || w.rects.some((r) => w.clips.some((c) => !within(r, c.box))) || w.cut;
    if (out) fails.push({ kind: 'clip', what: `${at}: "${w.text}" is cut off` });
  }
  for (let i = 0; i < m.words.length; i++) {
    for (let j = i + 1; j < m.words.length; j++) {
      const a = m.words[i], b = m.words[j];
      if (a.rects.some((r) => b.rects.some((s) => meets(r, s)))) fails.push({ kind: 'overlap', what: `${at}: the words "${a.text}" and "${b.text}" meet` });
    }
  }
  for (const c of m.ctls) {
    const w = c.touch[2] - c.touch[0], h = c.touch[3] - c.touch[1];
    if (w < 48 - 0.01 || h < 48 - 0.01) fails.push({ kind: 'hit', what: `${at}: ${c.name}'s touch area is ${f(w)} x ${f(h)}, under 48 x 48` });
    if (!within(c.face, [0, SAFE[0], FRAME[0], SAFE[1]])) fails.push({ kind: 'safe', what: `${at}: ${c.name} [${c.face.map(f)}] leaves the safe area y ${SAFE[0]} to ${SAFE[1]}` });
  }
  for (let i = 0; i < m.ctls.length; i++) {
    for (let j = i + 1; j < m.ctls.length; j++) {
      if (meets(m.ctls[i].face, m.ctls[j].face)) fails.push({ kind: 'overlap', what: `${at}: the controls ${m.ctls[i].name} and ${m.ctls[j].name} meet` });
    }
  }
  if (m.heist && m.ctls.length > MOST_IN_HEIST) fails.push({ kind: 'count', what: `${at}: ${m.ctls.length} things to tap, over §21.8's ${MOST_IN_HEIST}` });
  const row = { still: file, controls: m.ctls.length, words: m.words.length,
    smallest_touch: f(Math.min(...m.ctls.map((c) => Math.min(c.touch[2] - c.touch[0], c.touch[3] - c.touch[1])))),
    smallest_word: f(Math.min(...m.words.map((w) => w.size))) };
  return { fails, row };
}

export async function run({ inject = null, script = null, pages = null, kitCss = null, words = null, shots = null, stills = STILLS, pngs = null } = {}) {
  const allowed = allowedColours();
  const tokensCss = readFileSync(join(here, '..', 'board', 'tokens.css'), 'utf8');
  const fails = [];
  const htmls = pages ?? PAGES.map((p) => readFileSync(join(here, p), 'utf8'));
  htmls.forEach((h, i) => fails.push(...checkFiles(h, tokensCss, PAGES[i] ?? `page ${i + 1}`)));
  fails.push(...checkFiles(`<style>${kitCss ?? readFileSync(join(here, 'kit.css'), 'utf8')}</style>`, tokensCss, 'kit.css').filter((x) => x.kind !== 'tokens'));
  if ((words ?? readFileSync(join(here, 'words.js'), 'utf8')) !== build()) {
    fails.push({ kind: 'words', what: 'words.js is not the game\'s words: run node art/ui/keyframes/build_words.mjs' });
  }
  fails.push(...checkSteps(shots ?? STILLS.map(([file]) => join(here, file.replace('.png', '.shot.json')))));
  for (const file of pngs ?? STILLS.map(([file]) => join(here, file))) {
    const size = existsSync(file) ? pngSize(file) : null;
    if (!size || size[0] !== PX[0] || size[1] !== PX[1]) fails.push({ kind: 'png', what: `${file.split('/').pop()} is ${size ? size.join(' x ') : 'missing'}, not ${PX.join(' x ')}` });
  }

  const rows = [];
  const browser = await chromium.launch();
  try {
    const context = await browser.newContext({ viewport: { width: FRAME[0], height: FRAME[1] }, deviceScaleFactor: 1 });
    const page = await context.newPage();
    const errors = [];
    page.on('pageerror', (e) => errors.push(e.message));
    page.on('requestfailed', (r) => errors.push(`failed to load ${r.url()}`));
    for (const still of stills) {
      const [file, name, query] = still;
      const lay = await checkLayout(page, still, inject, script);
      fails.push(...lay.fails);
      const r = await checkMode(page, file, allowed, inject, href(name, query));
      fails.push(...r.fails.map((x) => ({ ...x, what: x.what.includes(`(${file})`) ? x.what : `[${file}] ${x.what}` })));
      rows.push({ ...lay.row, words_pass: r.rows.filter((w) => w.ok).length, worst_ratio: Math.min(...r.rows.map((w) => w.ratio)) });
    }
    for (const e of errors) fails.push({ kind: 'page', what: e });
  } finally {
    await browser.close();
  }
  return { fails, rows };
}

// A shot whose one control is a patch of sky with the sky around it.
function flatShot() {
  const shot = JSON.parse(readFileSync(join(here, '02-heist.shot.json'), 'utf8'));
  const at = join(mkdtempSync(join(tmpdir(), 'keyframes-')), 'flat.shot.json');
  writeFileSync(at, JSON.stringify({ ...shot, image: join(here, shot.image), controls: [{ name: 'a patch of sky', rect: [180, 300, 30, 10] }] }));
  return at;
}

async function selfTest() {
  const pages = PAGES.map((p) => readFileSync(join(here, p), 'utf8'));
  const kitCss = readFileSync(join(here, 'kit.css'), 'utf8');
  const words = readFileSync(join(here, 'words.js'), 'utf8');
  const one = (file) => STILLS.filter(([f]) => f === file);
  const home = one('01-home.png'), heist = one('02-heist.png'), large = one('01-home_text200_pt_BR.png');
  const cases = [
    ['clean key frames pass', {}, null],
    ['a hue of its own fails', { stills: home, inject: '.keeper .label{color:#123456!important}' }, 'colour'],
    ['a colour literal in kit.css fails', { stills: [], kitCss: kitCss.replace('.tab > .well {', '.tab > .well { color: #FF00FF;') }, 'literal'],
    ['a colour literal in a page fails', { stills: [], pages: [pages[0].replace('<style>', '<style>\n.x { background: rgb(1, 2, 3); }'), ...pages.slice(1)] }, 'literal'],
    ['a word that is not the game\'s fails', { stills: [], words: words.replace('"Cast"', '"Fire"') }, 'words'],
    ['a word under 13 points fails', { stills: heist, inject: '.law-name{font-size:12px!important}' }, 'type'],
    ['a word that does not grow with the text fails', { stills: large, inject: '.keeper .label{font-size:16px!important}' }, 'type'],
    ['a touch area under 48 points fails', { stills: heist, inject: '.getout{min-height:0!important;min-width:0!important;height:40px!important;width:40px!important;padding:0!important;overflow:hidden}' }, 'hit'],
    ['a control in the notch fails', { stills: home, inject: '.avatar{top:-30px!important}' }, 'safe'],
    ['controls that meet fail', { stills: heist, inject: '.getout{transform:translateY(-30px)!important}' }, 'overlap'],
    ['a word cut off fails', { stills: heist, inject: '.law-chip{overflow:hidden!important;max-width:40px!important}' }, 'clip'],
    ['a ninth thing to tap in the heist fails', { stills: heist, script: () => { const b = document.createElement('button'); b.className = 'ctl'; b.style.cssText = 'position:absolute;left:150px;top:400px;width:48px;height:48px'; document.querySelector('.screen').append(b); } }, 'count'],
    ['a control without its value step fails', { stills: [], shots: [flatShot()] }, 'value-steps'],
    ['a still of the wrong size fails', { stills: [], pngs: [join(here, 'art', 'archivist.png')] }, 'png'],
  ];
  let bad = 0;
  for (const [what, opts, kind] of cases) {
    const { fails } = await run(opts);
    const ok = kind === null ? fails.length === 0 : fails.some((x) => x.kind === kind);
    console.log(`${ok ? 'ok  ' : 'FAIL'} ${what}${ok ? '' : `: got ${fails.map((x) => x.kind + ': ' + x.what).slice(0, 3).join('; ') || 'no failure'}`}`);
    if (!ok) bad++;
  }
  if (bad) { console.error(`${bad} self-test case(s) failed`); process.exit(1); }
  console.log('check_keyframes self-test passed');
}

if (import.meta.url === pathToFileURL(process.argv[1]).href) {
  if (process.argv.includes('--self-test')) {
    await selfTest();
  } else {
    const { fails, rows } = await run();
    const outAt = process.argv.indexOf('--out');
    if (outAt > 0) writeFileSync(process.argv[outAt + 1], JSON.stringify({ rows, fails }, null, 1) + '\n');
    for (const r of rows) console.log(`${r.still}: ${r.controls} controls (smallest touch ${r.smallest_touch}), ${r.words} words (smallest ${r.smallest_word} pt, ${r.words_pass} pass, worst ${r.worst_ratio}:1)`);
    for (const x of fails) console.log(`FAIL ${x.kind}: ${x.what}`);
    if (fails.length) process.exit(1);
    console.log('key frame checks passed');
  }
}
