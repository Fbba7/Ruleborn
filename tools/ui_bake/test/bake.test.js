// Tests for tools/ui_bake/bake.js on the fixture family in test/fixture/.
//
//   node --test tools/ui_bake/test/bake.test.js
//
// They bake into scratch folders (never client/ui/art/) and need headless
// Chromium, Playwright and Pillow, as the bake does.
'use strict';
const test = require('node:test');
const assert = require('node:assert/strict');
const fs = require('fs');
const os = require('os');
const path = require('path');
const { spawnSync, execFileSync } = require('child_process');
const { manifestText, layout, webpSize } = require('../bake.js');

const BAKE = path.join(__dirname, '..', 'bake.js');
const FIXTURE = path.join(__dirname, 'fixture');

function scratch() {
  return fs.mkdtempSync(path.join(os.tmpdir(), 'ui-bake-test-'));
}

// A copy of the fixture's art and families file, so a test can change them.
function copyFixture() {
  const dir = scratch();
  fs.cpSync(FIXTURE, dir, { recursive: true });
  return { art: path.join(dir, 'art'), config: path.join(dir, 'families.json'), out: path.join(dir, 'out') };
}

function run(args, where) {
  const r = spawnSync('node', [BAKE, ...args, '--config', where.config, '--art', where.art, '--out', where.out], {
    encoding: 'utf8',
  });
  return { code: r.status, out: r.stdout + r.stderr };
}

function readOut(where) {
  const files = {};
  for (const f of ['fixture.json', 'fixture.webp', 'fixture_hc.webp']) files[f] = fs.readFileSync(path.join(where.out, f));
  return files;
}

// RGBA of one atlas pixel, read by Pillow.
function pixel(file, x, y) {
  const py = `from PIL import Image; import sys; print(*Image.open(sys.argv[1]).convert('RGBA').getpixel((int(sys.argv[2]), int(sys.argv[3]))))`;
  return execFileSync('python3', ['-c', py, file, String(x), String(y)], { encoding: 'utf8' }).trim().split(' ').map(Number);
}

const baked = copyFixture();
const first = run(['fixture'], baked);

test('bakes the fixture family into an atlas pair and a manifest', () => {
  assert.equal(first.code, 0, first.out);
  const m = JSON.parse(fs.readFileSync(path.join(baked.out, 'fixture.json'), 'utf8'));
  assert.equal(m.format, 1);
  assert.equal(m.family, 'fixture');
  assert.equal(m.px_per_point, 2);
  assert.match(m.sources_hash, /^sha256:[0-9a-f]{64}$/);
  assert.deepEqual(Object.keys(m.pieces).sort(), [
    'button_test__capsule__normal',
    'button_test__capsule__pressed',
    'disc_test__16__normal',
    'num_test_7',
  ]);
  const normal = m.pieces.button_test__capsule__normal;
  assert.deepEqual([normal.w, normal.h], [40, 20]);
  assert.deepEqual(normal.slice, { l: 8, t: 6, r: 8, b: 6 }, 'the root data-slice, in pixels');
  assert.deepEqual(m.pieces.button_test__capsule__pressed.slice, { l: 8, t: 8, r: 8, b: 4 }, "the state's own data-slice");
  assert.equal(m.pieces.disc_test__16__normal.slice, null);
  assert.equal(m.pieces.disc_test__16__normal.tint, true);
  assert.equal(normal.tint, false);
  assert.equal(m.pieces.num_test_7.advance, 18);
  assert.ok(!('advance' in normal), 'advance is on numerals only');
  for (const f of ['fixture.webp', 'fixture_hc.webp']) {
    assert.deepEqual(webpSize(path.join(baked.out, f)), { width: m.atlas.width, height: m.atlas.height });
  }
  assert.deepEqual(m.atlas, { normal: 'fixture.webp', high_contrast: 'fixture_hc.webp', width: 64, height: 128 });
  assert.equal(fs.readFileSync(path.join(baked.out, 'fixture.json'), 'utf8'), manifestText(m), 'sorted keys, final newline');
});

test('draws each face in its own form in both atlases, in the same place', () => {
  const m = JSON.parse(fs.readFileSync(path.join(baked.out, 'fixture.json'), 'utf8'));
  const at = (piece) => [piece.x + piece.w / 2, piece.y + piece.h / 2];
  const normal = m.pieces.button_test__capsule__normal;
  const pressed = m.pieces.button_test__capsule__pressed;
  const n = pixel(path.join(baked.out, 'fixture.webp'), ...at(normal));
  const p = pixel(path.join(baked.out, 'fixture.webp'), ...at(pressed));
  const hc = pixel(path.join(baked.out, 'fixture_hc.webp'), ...at(normal));
  assert.equal(n[3], 255);
  assert.notDeepEqual(n, p, 'pressed is its own face');
  assert.deepEqual(hc, [0, 0, 0, 255], 'the high-contrast twin of the normal face is black');
  const disc = m.pieces.disc_test__16__normal;
  assert.deepEqual(pixel(path.join(baked.out, 'fixture.webp'), ...at(disc)), [216, 216, 216, 255]);
  assert.deepEqual(pixel(path.join(baked.out, 'fixture_hc.webp'), ...at(disc)), [255, 255, 255, 255], 'data-hc="class"');
  assert.equal(pixel(path.join(baked.out, 'fixture.webp'), disc.x, disc.y)[3], 0, 'transparent around the disc');
});

test('rebakes byte for byte', () => {
  const again = { ...baked, out: path.join(scratch(), 'out') };
  const r = run(['fixture'], again);
  assert.equal(r.code, 0, r.out);
  const a = readOut(baked);
  const b = readOut(again);
  for (const f of Object.keys(a)) assert.ok(a[f].equals(b[f]), `${f} differs between two bakes`);
});

test('--check passes on a fresh bake and fails when a source changes', () => {
  const where = copyFixture();
  assert.equal(run(['fixture'], where).code, 0);
  const ok = run(['--check'], where);
  assert.equal(ok.code, 0, ok.out);
  assert.match(ok.out, /ok {3}fixture: 4 pieces, 64x128/);
  fs.appendFileSync(path.join(where.art, 'fixture/disc_test/16.svg'), '\n');
  const stale = run(['--check'], where);
  assert.equal(stale.code, 1);
  assert.match(stale.out, /stale/);
});

test('--check fails on sources never baked, a missing atlas and a hand-edited manifest', () => {
  const where = copyFixture();
  const unbaked = run(['--check'], where);
  assert.equal(unbaked.code, 1);
  assert.match(unbaked.out, /no fixture\.json: bake it/);

  assert.equal(run(['fixture'], where).code, 0);
  const mfile = path.join(where.out, 'fixture.json');
  fs.writeFileSync(mfile, JSON.stringify(JSON.parse(fs.readFileSync(mfile, 'utf8'))));
  const edited = run(['--check'], where);
  assert.equal(edited.code, 1);
  assert.match(edited.out, /not as the bake writes it/);

  assert.equal(run(['fixture'], where).code, 0);
  fs.rmSync(path.join(where.out, 'fixture_hc.webp'));
  const missing = run(['--check'], where);
  assert.equal(missing.code, 1);
  assert.match(missing.out, /fixture_hc\.webp is missing/);
});

test('--check finds no fault with a family that has neither sources nor bake', () => {
  const where = copyFixture();
  fs.rmSync(path.join(where.art, 'fixture'), { recursive: true });
  const r = run(['--check'], where);
  assert.equal(r.code, 0, r.out);
  assert.match(r.out, /no sources yet/);
});

function refusal(file, text, pattern) {
  const where = copyFixture();
  fs.mkdirSync(path.dirname(path.join(where.art, 'fixture', file)), { recursive: true });
  fs.writeFileSync(path.join(where.art, 'fixture', file), text);
  const r = run(['fixture'], where);
  assert.equal(r.code, 2, r.out);
  assert.match(r.out, pattern);
  assert.ok(!fs.existsSync(path.join(where.out, 'fixture.json')), 'a refused bake writes nothing');
}

test('refuses a face without its high-contrast twin', () => {
  refusal('plain/box.svg', '<svg xmlns="http://www.w3.org/2000/svg" width="8" height="8"><rect width="8" height="8"/></svg>', /no high-contrast twin/);
  refusal(
    'plain/box.svg',
    `<svg xmlns="http://www.w3.org/2000/svg" width="8" height="8">
      <g data-state="normal"><rect width="8" height="8"/></g><g data-state="normal" data-mode="hc"><rect width="8" height="8"/></g>
      <g data-state="locked"><rect width="8" height="8"/></g></svg>`,
    /state locked has no high-contrast twin/,
  );
});

test('refuses unknown states, odd sizes, bad names and stray advances', () => {
  const twin = (inner) => `<g data-state="normal">${inner}</g><g data-state="normal" data-mode="hc">${inner}</g>`;
  refusal('plain/box.svg', `<svg xmlns="http://www.w3.org/2000/svg" width="8" height="8" data-hc="class"><g data-state="hover"/></svg>`, /state "hover"/);
  refusal('plain/box.svg', `<svg xmlns="http://www.w3.org/2000/svg" width="8.25" height="8">${twin('<rect/>')}</svg>`, /not a whole number of pixels/);
  refusal('plain/box.svg', `<svg xmlns="http://www.w3.org/2000/svg" width="8" height="8" data-slice="5 1 5 1">${twin('<rect/>')}</svg>`, /exceed the piece/);
  refusal('Plain/box.svg', `<svg xmlns="http://www.w3.org/2000/svg" width="8" height="8" data-hc="class"/>`, /lower-case words/);
  refusal('box.svg', `<svg xmlns="http://www.w3.org/2000/svg" width="8" height="8" data-hc="class"/>`, /<skin>\/<shape>\.svg/);
  refusal('plain/box.svg', `<svg xmlns="http://www.w3.org/2000/svg" width="8" height="8" data-hc="class" data-advance="4"/>`, /numerals only/);
  refusal('num_test/8.svg', `<svg xmlns="http://www.w3.org/2000/svg" width="8" height="8" data-hc="class"/>`, /needs data-advance/);
});

test('refuses an atlas larger than 2048 on a side', () => {
  const big = '<svg xmlns="http://www.w3.org/2000/svg" width="1100" height="1100" data-hc="class"><rect width="1100" height="1100"/></svg>';
  refusal('plain/big.svg', big, /do not fit a 2048x2048 atlas/);
});

test('packs in shelves, tallest first, and widens before refusing', () => {
  const lay = layout(
    [
      { name: 'a', w: 30, h: 10 },
      { name: 'b', w: 30, h: 20 },
      { name: 'c', w: 30, h: 10 },
    ],
    64,
  );
  assert.deepEqual(lay, { width: 64, height: 64, places: { b: { x: 2, y: 2 }, a: { x: 2, y: 24 }, c: { x: 2, y: 36 } } });
  assert.equal(layout([{ name: 'wide', w: 100, h: 4 }], 64).width, 128);
});
