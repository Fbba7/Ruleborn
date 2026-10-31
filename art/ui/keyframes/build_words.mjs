// Writes words.js: the game's own words for the key frames, in English and
// Brazilian Portuguese, from client/i18n/strings.csv and content.csv. The
// pages name each word by its key (data-key, data-label, or k: in data-args) and kit.js
// fills it in, so a key frame shows what the game would say. Only the keys
// the pages use go in, with the number format's own. check_keyframes.mjs
// fails when words.js is not what this writes.
//
//   node art/ui/keyframes/build_words.mjs
import { readFileSync, writeFileSync } from 'node:fs';
import { dirname, join } from 'node:path';
import { fileURLToPath, pathToFileURL } from 'node:url';

const here = dirname(fileURLToPath(import.meta.url));
const root = join(here, '..', '..', '..');
export const LANGS = ['en', 'pt_BR'];
export const PAGES = ['01-home.html', '02-heist.html', '03-result.html'];
const ALWAYS = ['NUMBER_GROUP', 'NUMBER_DECIMAL', 'HOME_AMOUNT_THOUSANDS', 'HOME_AMOUNT_MILLIONS'];

// One CSV row per line, fields optionally quoted with "" for a quote.
export function parseCsv(text) {
  const rows = [];
  let row = [], field = '', quoted = false;
  for (let i = 0; i < text.length; i++) {
    const c = text[i];
    if (quoted) {
      if (c === '"' && text[i + 1] === '"') { field += '"'; i++; }
      else if (c === '"') quoted = false;
      else field += c;
    } else if (c === '"') quoted = true;
    else if (c === ',') { row.push(field); field = ''; }
    else if (c === '\n') { row.push(field.replace(/\r$/, '')); rows.push(row); row = []; field = ''; }
    else field += c;
  }
  if (field || row.length) { row.push(field); rows.push(row); }
  return rows;
}

export function table() {
  const out = new Map();
  for (const file of ['strings.csv', 'content.csv']) {
    const [head, ...rows] = parseCsv(readFileSync(join(root, 'client/i18n', file), 'utf8'));
    for (const r of rows) {
      if (!r[0]) continue;
      out.set(r[0], Object.fromEntries(LANGS.map((l) => [l, r[head.indexOf(l)]])));
    }
  }
  return out;
}

export function keysUsed(pages = PAGES.map((p) => readFileSync(join(here, p), 'utf8'))) {
  const keys = new Set(ALWAYS);
  for (const html of pages) {
    for (const m of html.matchAll(/data-(?:key|label)="([A-Z0-9_]+)"/g)) keys.add(m[1]);
    for (const m of html.matchAll(/data-args="([^"]*)"/g)) for (const a of m[1].matchAll(/\bk:([A-Z0-9_]+)/g)) keys.add(a[1]);
  }
  return [...keys].sort();
}

export function build(pages) {
  const t = table();
  const words = Object.fromEntries(LANGS.map((l) => [l, {}]));
  const missing = [];
  for (const k of keysUsed(pages)) {
    if (!t.has(k)) { missing.push(k); continue; }
    for (const l of LANGS) words[l][k] = t.get(k)[l];
  }
  if (missing.length) throw new Error(`keys not in the strings tables: ${missing.join(', ')}`);
  return '// Written by build_words.mjs from client/i18n/strings.csv and content.csv; do not edit.\n'
    + `window.WORDS = ${JSON.stringify(words, null, 1)};\n`;
}

if (import.meta.url === pathToFileURL(process.argv[1]).href) {
  writeFileSync(join(here, 'words.js'), build());
  console.log('wrote words.js');
}
