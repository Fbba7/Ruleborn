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
const { manifestText, layout, paginate, palette, webpSize } = require('../bake.js');

const BAKE = path.join(__dirname, '..', 'bake.js');
const ROOT = path.join(__dirname, '..', '..', '..');
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
  const extra = where.tokens ? ['--tokens', where.tokens] : [];
  const r = spawnSync('node', [BAKE, ...args, ...extra, '--config', where.config, '--art', where.art, '--out', where.out], {
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

test('splits pieces that outgrow one atlas into pages, tallest first', () => {
  const pieces = [
    { name: 'big_a', w: 1500, h: 1500 },
    { name: 'big_b', w: 1500, h: 1400 },
    { name: 'small', w: 100, h: 50 },
  ];
  const pages = paginate(pieces, 1024);
  assert.equal(pages.length, 2);
  assert.deepEqual(pages[0], { width: 2048, height: 2048, places: { big_a: { x: 2, y: 2, page: 1 } } });
  assert.deepEqual(pages[1].places, { big_b: { x: 2, y: 2, page: 2 }, small: { x: 1504, y: 2, page: 2 } });
  assert.deepEqual([pages[1].width, pages[1].height], [2048, 2048]);
  const one = paginate([{ name: 'a', w: 30, h: 10 }], 64);
  assert.deepEqual(one, [{ width: 64, height: 16, places: { a: { x: 2, y: 2, page: 1 } } }], 'a family that fits keeps one atlas');
  assert.throws(() => paginate([{ name: 'huge', w: 2100, h: 10 }], 64), /do not fit a 2048x2048 atlas.*huge is larger than a page/);
});

// Two pieces of 520 points (1040 px at the fixture's 2 px a point): one a page.
const BIG = (fill) =>
  `<svg xmlns="http://www.w3.org/2000/svg" width="520" height="520" data-hc="class"><style>.hc rect { fill: #fff; }</style><rect width="520" height="520" fill="${fill}"/></svg>`;

test('bakes a family that outgrows one atlas into pages with their twins', () => {
  const where = copyFixture();
  fs.mkdirSync(path.join(where.art, 'fixture/plain'));
  fs.writeFileSync(path.join(where.art, 'fixture/plain/big.svg'), BIG('#ff0000'));
  fs.writeFileSync(path.join(where.art, 'fixture/plain/bigger.svg'), BIG('#00ff00'));
  const r = run(['fixture'], where);
  assert.equal(r.code, 0, r.out);
  assert.match(r.out, /6 pieces twice into 2 pages/);
  const text = fs.readFileSync(path.join(where.out, 'fixture.json'), 'utf8');
  const m = JSON.parse(text);
  assert.equal(text, manifestText(m));
  const page = (n, w, h) => ({ normal: n === 1 ? 'fixture.webp' : `fixture_${n}.webp`, high_contrast: n === 1 ? 'fixture_hc.webp' : `fixture_${n}_hc.webp`, width: w, height: h });
  assert.deepEqual(m.atlas, { ...page(1, 2048, 2048), pages: [page(1, 2048, 2048), page(2, 2048, 2048)] });
  assert.equal(m.pieces.plain__big__normal.page, undefined, 'page 1 is the default');
  assert.equal(m.pieces.plain__bigger__normal.page, 2);
  for (const f of ['fixture.webp', 'fixture_hc.webp', 'fixture_2.webp', 'fixture_2_hc.webp']) {
    assert.deepEqual(webpSize(path.join(where.out, f)), { width: 2048, height: 2048 }, f);
  }
  // Tallest first, then by name: big on page 1, bigger and the rest on page 2.
  const on2 = m.pieces.plain__bigger__normal;
  assert.deepEqual(pixel(path.join(where.out, 'fixture_2.webp'), on2.x + 10, on2.y + 10), [0, 255, 0, 255]);
  assert.deepEqual(pixel(path.join(where.out, 'fixture_2_hc.webp'), on2.x + 10, on2.y + 10), [255, 255, 255, 255]);
  assert.equal(m.pieces.button_test__capsule__normal.page, 2);
  const ok = run(['--check'], where);
  assert.equal(ok.code, 0, ok.out);
  assert.match(ok.out, /ok {3}fixture: 6 pieces, 2 pages/);

  // Rebaked byte for byte, every page.
  const again = { ...where, out: path.join(scratch(), 'out') };
  assert.equal(run(['fixture'], again).code, 0);
  for (const f of ['fixture.json', 'fixture.webp', 'fixture_hc.webp', 'fixture_2.webp', 'fixture_2_hc.webp']) {
    assert.ok(fs.readFileSync(path.join(where.out, f)).equals(fs.readFileSync(path.join(again.out, f))), `${f} differs`);
  }

  // A page that loses its twin, or a piece pointed off its pages, fails the check.
  fs.rmSync(path.join(again.out, 'fixture_2_hc.webp'));
  const lost = run(['--check'], again);
  assert.equal(lost.code, 1);
  assert.match(lost.out, /fixture_2_hc\.webp is missing/);

  // Back to one atlas: the second page goes with the bake that no longer needs it.
  fs.rmSync(path.join(where.art, 'fixture/plain/bigger.svg'));
  assert.equal(run(['fixture'], where).code, 0);
  assert.ok(!fs.existsSync(path.join(where.out, 'fixture_2.webp')));
  assert.ok(!fs.existsSync(path.join(where.out, 'fixture_2_hc.webp')));
  const one = JSON.parse(fs.readFileSync(path.join(where.out, 'fixture.json'), 'utf8'));
  assert.equal(one.atlas.pages, undefined);
  assert.equal(run(['--check'], where).code, 0);
  fs.copyFileSync(path.join(again.out, 'fixture_2.webp'), path.join(where.out, 'fixture_2.webp'));
  const stray = run(['--check'], where);
  assert.equal(stray.code, 1);
  assert.match(stray.out, /fixture_2\.webp is a page the manifest does not list/);
});

test('--check refuses a piece on a page the atlas does not have', () => {
  const where = copyFixture();
  assert.equal(run(['fixture'], where).code, 0);
  const mfile = path.join(where.out, 'fixture.json');
  const m = JSON.parse(fs.readFileSync(mfile, 'utf8'));
  m.pieces.disc_test__16__normal.page = 2;
  fs.writeFileSync(mfile, manifestText(m));
  const r = run(['--check'], where);
  assert.equal(r.code, 1);
  assert.match(r.out, /disc_test__16__normal is on page 2, which the atlas does not have/);
});

test('--palette writes palette.json from tokens.json, keeping its kit colours', () => {
  const where = copyFixture();
  where.tokens = path.join(path.dirname(where.art), 'tokens.json');
  const tokens = {
    color: { _what: 'x', gold: { value: '#E9B65C', from: 'a' }, ink: { value: '#221C3A', from: 'b' } },
    color_high_contrast: { ink: { value: '#000000', from: 'c' } },
    gradient: { _what: 'y', gold: { value: [[0, 'gold'], [1, '#C88A35']], from: 'd' } },
  };
  fs.writeFileSync(where.tokens, JSON.stringify(tokens));
  fs.writeFileSync(path.join(where.art, 'palette.json'), JSON.stringify({ kit: { gold_hc: { value: '#F2C14E', from: 'gold, flat' } } }));
  const r = run(['--palette'], where);
  assert.equal(r.code, 0, r.out);
  const p = JSON.parse(fs.readFileSync(path.join(where.art, 'palette.json'), 'utf8'));
  assert.deepEqual(p.color, { gold: '#E9B65C', ink: '#221C3A' });
  assert.deepEqual(p.color_high_contrast, { ink: '#000000' });
  assert.deepEqual(p.gradient, { gold: [[0, '#E9B65C'], [1, '#C88A35']] });
  assert.deepEqual(p.kit, { gold_hc: { value: '#F2C14E', from: 'gold, flat' } });
  assert.match(p._what, /generated from client\/ui\/tokens\.json by tools\/ui_bake\/bake\.js/);
  assert.deepEqual(palette(tokens, null).kit, {});
  assert.equal(run(['fixture'], where).code, 0);
  const ok = run(['--check'], where);
  assert.equal(ok.code, 0, ok.out);
  assert.match(ok.out, /ok {3}palette\.json/);
  tokens.color.gold.value = '#000001';
  fs.writeFileSync(where.tokens, JSON.stringify(tokens));
  const stale = run(['--check'], where);
  assert.equal(stale.code, 1);
  assert.match(stale.out, /palette\.json's color is not tokens\.json's/);
  assert.match(stale.out, /palette\.json's gradient is not tokens\.json's/);
});

test('bakes kind "scene" through the icon studio, from the real art only', () => {
  const where = copyFixture();
  const cfg = JSON.parse(fs.readFileSync(where.config, 'utf8'));
  cfg.families.icons = { dir: 'icons', kind: 'scene', px: 64, width: 256 };
  fs.writeFileSync(where.config, JSON.stringify(cfg));
  const r = run(['icons'], where);
  assert.equal(r.code, 2, r.out);
  assert.match(r.out, /a scene family bakes from art\/ui and tools\/ui_bake\/families\.json only/);
});

test("the Godot kit tests' fixture (client/tests/fixtures/ui_kit) is baked from its sources", () => {
  const dir = path.join(ROOT, 'client/tests/fixtures/ui_kit');
  const where = { config: path.join(dir, 'families.json'), art: path.join(dir, 'art'), out: dir };
  const r = run(['--check'], where);
  assert.equal(r.code, 0, `${r.out}\nrebake: node tools/ui_bake/bake.js kit --config ${where.config} --art ${where.art} --out ${dir}`);
  assert.match(r.out, /ok {3}kit: 6 pieces/);
});
